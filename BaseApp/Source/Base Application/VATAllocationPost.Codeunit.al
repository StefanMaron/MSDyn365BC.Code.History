codeunit 12417 "VAT Allocation-Post"
{
    Permissions = TableData "Purchase Header" = r,
                  TableData "Purchase Line" = r,
                  TableData "Purch. Rcpt. Line" = r,
                  TableData "Item Charge Assignment (Purch)" = imd,
                  TableData "Return Shipment Line" = r;

    trigger OnRun()
    begin
    end;

    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesInvLine: Record "Sales Invoice Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        VATPostingSetup: Record "VAT Posting Setup";
        TempItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)" temporary;
        TempItemChargeAssgntSales: Record "Item Charge Assignment (Sales)" temporary;
        GLSetup: Record "General Ledger Setup";
        Text000: Label 'Related item ledger entries cannot be found.';
        TempValueEntry: Record "Value Entry" temporary;
        SourceCodeSetup: Record "Source Code Setup";
        ItemReg: Record "Item Register";
        TotalChargeAmt: Decimal;
        TotalChargeAmtLCY: Decimal;
        Text001: Label 'Fixed Asset %1 should be on inventory or released.';
        Text005: Label 'You cannot reverse the transaction, because it has already been reversed.';
        Text006: Label 'The combination of dimensions used in %1 %2 is blocked. %3';
        NextReverseEntryNo: Integer;
        RoundingPrecision: Decimal;

    [Scope('OnPrem')]
    procedure PostItem(GenJnlLine: Record "Gen. Journal Line"; VATAllocLine: Record "VAT Allocation Line")
    var
        TotalAmount: Decimal;
        QtyRemainder: Decimal;
        AmountRemainder: Decimal;
        NextLineNo: Integer;
    begin
        GLSetup.Get();
        NextLineNo := 0;

        SourceCodeSetup.Get();

        VATPostingSetup.Get(VATAllocLine."VAT Bus. Posting Group", VATAllocLine."VAT Prod. Posting Group");

        InitiItemChargeAssgntBuffer(TempItemChargeAssgntPurch, TempItemChargeAssgntSales);
        RoundingPrecision := GLSetup."Amount Rounding Precision";

        // initialize
        TotalAmount := 0;
        case GenJnlLine."Account Type" of
            GenJnlLine."Account Type"::Vendor:
                begin
                    FillItemChargeAssgntPurch(GenJnlLine, VATAllocLine, TotalAmount, NextLineNo);
                    AllocateItemChargeAssgntPurch(VATAllocLine, TotalAmount, QtyRemainder, AmountRemainder);
                    PostItemChargeAssgntPurch(GenJnlLine);
                end;
            GenJnlLine."Account Type"::Customer:
                begin
                    FillItemChargeAssgntSales(GenJnlLine, VATAllocLine, TotalAmount, NextLineNo);
                    AllocateItemChargeAssgntSales(VATAllocLine, TotalAmount, QtyRemainder, AmountRemainder);
                    PostItemChargeAssgntSales(GenJnlLine);
                end;
            else
                GenJnlLine.FieldError("Account Type");
        end;
    end;

    local procedure PostItemChargePerPurchInvLine(GenJnlLine: Record "Gen. Journal Line"; PurchInvHeader: Record "Purch. Inv. Header"; PurchInvLine: Record "Purch. Inv. Line")
    var
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        Factor: Decimal;
        NonDistrQuantity: Decimal;
        NonDistrQtyToAssign: Decimal;
        NonDistrAmountToAssign: Decimal;
        QtyToAssign: Decimal;
        AmountToAssign: Decimal;
        Sign: Decimal;
        DistributeCharge: Boolean;
    begin
        PurchInvLine.TestField("Job No.", '');
        Sign := GetEntrySign(PurchInvLine."Quantity (Base)");

        DistributeCharge := false;
        PurchInvLine.GetItemLedgEntries(TempItemLedgEntry, false);
        if TempItemLedgEntry.Count > 1 then begin
            DistributeCharge := true;
            ItemTrackingMgt.CollectItemEntryRelation(TempItemLedgEntry,
              DATABASE::"Purch. Inv. Line", 0, PurchInvLine."Document No.",
              '', 0, PurchInvLine."Line No.", PurchInvLine."Quantity (Base)");
        end else
            TempItemLedgEntry.FindSet();

        if DistributeCharge then
            if TempItemLedgEntry.FindSet then begin
                NonDistrQuantity := PurchInvLine."Quantity (Base)";
                NonDistrQtyToAssign := TempItemChargeAssgntPurch."Qty. to Assign";
                NonDistrAmountToAssign := TempItemChargeAssgntPurch."Amount to Assign";
                repeat
                    Factor := TempItemLedgEntry.Quantity / NonDistrQuantity;
                    QtyToAssign := NonDistrQtyToAssign * Factor;
                    AmountToAssign := Round(NonDistrAmountToAssign * Factor, GLSetup."Amount Rounding Precision");
                    if Factor < 1 then begin
                        PostPurchInvItemCharge(GenJnlLine, PurchInvHeader, PurchInvLine,
                          TempItemLedgEntry."Entry No.", TempItemLedgEntry.Quantity,
                          AmountToAssign * Sign, QtyToAssign, PurchInvLine."Indirect Cost %",
                          TempItemLedgEntry."Serial No.", TempItemLedgEntry."Lot No.");
                        NonDistrQuantity := NonDistrQuantity - TempItemLedgEntry.Quantity;
                        NonDistrQtyToAssign := NonDistrQtyToAssign - QtyToAssign;
                        NonDistrAmountToAssign := NonDistrAmountToAssign - AmountToAssign;
                    end else // the last time
                        PostPurchInvItemCharge(GenJnlLine, PurchInvHeader, PurchInvLine,
                          TempItemLedgEntry."Entry No.", TempItemLedgEntry.Quantity,
                          NonDistrAmountToAssign * Sign, NonDistrQtyToAssign, PurchInvLine."Indirect Cost %",
                          TempItemLedgEntry."Serial No.", TempItemLedgEntry."Lot No.");
                until TempItemLedgEntry.Next() = 0;
            end else
                Error(Text000)
        else
            PostPurchInvItemCharge(GenJnlLine, PurchInvHeader, PurchInvLine,
              TempItemLedgEntry."Entry No.", PurchInvLine."Quantity (Base)",
              TempItemChargeAssgntPurch."Amount to Assign" * Sign,
              TempItemChargeAssgntPurch."Qty. to Assign",
              PurchInvLine."Indirect Cost %",
              TempItemLedgEntry."Serial No.", TempItemLedgEntry."Lot No.");
    end;

    local procedure PostItemChargePerPurchCrMLine(GenJnlLine: Record "Gen. Journal Line"; PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr."; PurchCrMemoLine: Record "Purch. Cr. Memo Line")
    var
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        Factor: Decimal;
        NonDistrQuantity: Decimal;
        NonDistrQtyToAssign: Decimal;
        NonDistrAmountToAssign: Decimal;
        QtyToAssign: Decimal;
        AmountToAssign: Decimal;
        Sign: Decimal;
        DistributeCharge: Boolean;
    begin
        PurchCrMemoLine.TestField("Job No.", '');
        Sign := GetEntrySign(PurchCrMemoLine."Quantity (Base)");

        DistributeCharge := false;
        PurchCrMemoLine.GetItemLedgEntries(TempItemLedgEntry, false);
        if TempItemLedgEntry.Count > 1 then begin
            DistributeCharge := true;
            ItemTrackingMgt.CollectItemEntryRelation(TempItemLedgEntry,
              DATABASE::"Purch. Inv. Line", 0, PurchCrMemoLine."Document No.",
              '', 0, PurchCrMemoLine."Line No.", PurchInvLine."Quantity (Base)");
        end else
            TempItemLedgEntry.FindSet();

        if DistributeCharge then
            if TempItemLedgEntry.FindSet then begin
                NonDistrQuantity := PurchCrMemoLine."Quantity (Base)";
                NonDistrQtyToAssign := TempItemChargeAssgntPurch."Qty. to Assign";
                NonDistrAmountToAssign := TempItemChargeAssgntPurch."Amount to Assign";
                repeat
                    Factor := TempItemLedgEntry.Quantity / NonDistrQuantity;
                    QtyToAssign := NonDistrQtyToAssign * Factor;
                    AmountToAssign := Round(NonDistrAmountToAssign * Factor, GLSetup."Amount Rounding Precision");
                    if Factor < 1 then begin
                        PostPurchCrMemoItemCharge(GenJnlLine, PurchCrMemoHeader, PurchCrMemoLine,
                          TempItemLedgEntry."Entry No.", TempItemLedgEntry.Quantity,
                          AmountToAssign * Sign, QtyToAssign, PurchCrMemoLine."Indirect Cost %",
                          TempItemLedgEntry."Serial No.", TempItemLedgEntry."Lot No.");
                        NonDistrQuantity := NonDistrQuantity - TempItemLedgEntry.Quantity;
                        NonDistrQtyToAssign := NonDistrQtyToAssign - QtyToAssign;
                        NonDistrAmountToAssign := NonDistrAmountToAssign - AmountToAssign;
                    end else // the last time
                        PostPurchCrMemoItemCharge(GenJnlLine, PurchCrMemoHeader, PurchCrMemoLine,
                          TempItemLedgEntry."Entry No.", TempItemLedgEntry.Quantity,
                          NonDistrAmountToAssign * Sign, NonDistrQtyToAssign, PurchCrMemoLine."Indirect Cost %",
                          TempItemLedgEntry."Serial No.", TempItemLedgEntry."Lot No.");
                until TempItemLedgEntry.Next() = 0;
            end else
                Error(Text000)
        else
            PostPurchCrMemoItemCharge(GenJnlLine, PurchCrMemoHeader, PurchCrMemoLine,
              TempItemLedgEntry."Entry No.", PurchCrMemoLine."Quantity (Base)",
              TempItemChargeAssgntPurch."Amount to Assign" * Sign,
              TempItemChargeAssgntPurch."Qty. to Assign",
              PurchCrMemoLine."Indirect Cost %",
              TempItemLedgEntry."Serial No.", TempItemLedgEntry."Lot No.");
    end;

    local procedure PostItemChargePerSalesInvLine(GenJnlLine: Record "Gen. Journal Line"; SalesInvHeader: Record "Sales Invoice Header"; SalesInvLine: Record "Sales Invoice Line")
    var
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        Factor: Decimal;
        NonDistrQuantity: Decimal;
        NonDistrQtyToAssign: Decimal;
        NonDistrAmountToAssign: Decimal;
        QtyToAssign: Decimal;
        AmountToAssign: Decimal;
        Sign: Decimal;
        DistributeCharge: Boolean;
    begin
        SalesInvLine.TestField("Job No.", '');
        Sign := GetEntrySign(SalesInvLine."Quantity (Base)");

        DistributeCharge := false;
        SalesInvLine.GetItemLedgEntries(TempItemLedgEntry, false);
        if TempItemLedgEntry.Count > 1 then begin
            DistributeCharge := true;
            ItemTrackingMgt.CollectItemEntryRelation(TempItemLedgEntry,
              DATABASE::"Sales Invoice Line", 0, SalesInvLine."Document No.",
              '', 0, SalesInvLine."Line No.", SalesInvLine."Quantity (Base)");
        end else
            TempItemLedgEntry.FindSet();

        if DistributeCharge then
            if TempItemLedgEntry.FindSet then begin
                NonDistrQuantity := SalesInvLine."Quantity (Base)";
                NonDistrQtyToAssign := TempItemChargeAssgntSales."Qty. to Assign";
                NonDistrAmountToAssign := TempItemChargeAssgntSales."Amount to Assign";
                repeat
                    Factor := TempItemLedgEntry.Quantity / NonDistrQuantity;
                    QtyToAssign := NonDistrQtyToAssign * Factor;
                    AmountToAssign := Round(NonDistrAmountToAssign * Factor, GLSetup."Amount Rounding Precision");
                    if Factor < 1 then begin
                        PostSalesInvItemCharge(GenJnlLine, SalesInvHeader, SalesInvLine,
                          TempItemLedgEntry."Entry No.", TempItemLedgEntry.Quantity,
                          AmountToAssign * Sign, QtyToAssign,
                          TempItemLedgEntry."Serial No.", TempItemLedgEntry."Lot No.");
                        NonDistrQuantity := NonDistrQuantity - TempItemLedgEntry.Quantity;
                        NonDistrQtyToAssign := NonDistrQtyToAssign - QtyToAssign;
                        NonDistrAmountToAssign := NonDistrAmountToAssign - AmountToAssign;
                    end else // the last time
                        PostSalesInvItemCharge(GenJnlLine, SalesInvHeader, SalesInvLine,
                          TempItemLedgEntry."Entry No.", TempItemLedgEntry.Quantity,
                          NonDistrAmountToAssign * Sign, NonDistrQtyToAssign,
                          TempItemLedgEntry."Serial No.", TempItemLedgEntry."Lot No.");
                until TempItemLedgEntry.Next() = 0;
            end else
                Error(Text000)
        else
            PostSalesInvItemCharge(GenJnlLine, SalesInvHeader, SalesInvLine,
              TempItemLedgEntry."Entry No.", SalesInvLine."Quantity (Base)",
              TempItemChargeAssgntSales."Amount to Assign" * Sign,
              TempItemChargeAssgntSales."Qty. to Assign",
              TempItemLedgEntry."Serial No.", TempItemLedgEntry."Lot No.");
    end;

    local procedure PostItemChargePerSalesCrMLine(GenJnlLine: Record "Gen. Journal Line"; SalesCrMemoHeader: Record "Sales Cr.Memo Header"; SalesCrMemoLine: Record "Sales Cr.Memo Line")
    var
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        Factor: Decimal;
        NonDistrQuantity: Decimal;
        NonDistrQtyToAssign: Decimal;
        NonDistrAmountToAssign: Decimal;
        QtyToAssign: Decimal;
        AmountToAssign: Decimal;
        Sign: Decimal;
        DistributeCharge: Boolean;
    begin
        SalesCrMemoLine.TestField("Job No.", '');
        Sign := GetEntrySign(SalesCrMemoLine."Quantity (Base)");

        DistributeCharge := false;
        SalesCrMemoLine.GetItemLedgEntries(TempItemLedgEntry, false);
        if TempItemLedgEntry.Count > 1 then begin
            DistributeCharge := true;
            ItemTrackingMgt.CollectItemEntryRelation(TempItemLedgEntry,
              DATABASE::"Purch. Inv. Line", 0, SalesCrMemoLine."Document No.",
              '', 0, SalesCrMemoLine."Line No.", SalesInvLine."Quantity (Base)");
        end else
            TempItemLedgEntry.FindSet();

        if DistributeCharge then
            if TempItemLedgEntry.FindSet then begin
                NonDistrQuantity := SalesCrMemoLine."Quantity (Base)";
                NonDistrQtyToAssign := TempItemChargeAssgntSales."Qty. to Assign";
                NonDistrAmountToAssign := TempItemChargeAssgntSales."Amount to Assign";
                repeat
                    Factor := TempItemLedgEntry.Quantity / NonDistrQuantity;
                    QtyToAssign := NonDistrQtyToAssign * Factor;
                    AmountToAssign := Round(NonDistrAmountToAssign * Factor, GLSetup."Amount Rounding Precision");
                    if Factor < 1 then begin
                        PostSalesCrMemoItemCharge(GenJnlLine, SalesCrMemoHeader, SalesCrMemoLine,
                          TempItemLedgEntry."Entry No.", TempItemLedgEntry.Quantity,
                          AmountToAssign * Sign, QtyToAssign,
                          TempItemLedgEntry."Serial No.", TempItemLedgEntry."Lot No.");
                        NonDistrQuantity := NonDistrQuantity - TempItemLedgEntry.Quantity;
                        NonDistrQtyToAssign := NonDistrQtyToAssign - QtyToAssign;
                        NonDistrAmountToAssign := NonDistrAmountToAssign - AmountToAssign;
                    end else // the last time
                        PostSalesCrMemoItemCharge(GenJnlLine, SalesCrMemoHeader, SalesCrMemoLine,
                          TempItemLedgEntry."Entry No.", TempItemLedgEntry.Quantity,
                          NonDistrAmountToAssign * Sign, NonDistrQtyToAssign,
                          TempItemLedgEntry."Serial No.", TempItemLedgEntry."Lot No.");
                until TempItemLedgEntry.Next() = 0;
            end else
                Error(Text000)
        else
            PostSalesCrMemoItemCharge(GenJnlLine, SalesCrMemoHeader, SalesCrMemoLine,
              TempItemLedgEntry."Entry No.", SalesCrMemoLine."Quantity (Base)",
              TempItemChargeAssgntSales."Amount to Assign" * Sign,
              TempItemChargeAssgntSales."Qty. to Assign",
              TempItemLedgEntry."Serial No.", TempItemLedgEntry."Lot No.");
    end;

    local procedure PostPurchInvItemCharge(GenJnlLine: Record "Gen. Journal Line"; PurchInvHeader: Record "Purch. Inv. Header"; PurchInvLine: Record "Purch. Inv. Line"; ItemEntryNo: Integer; QuantityBase: Decimal; AmountToAssign: Decimal; QtyToAssign: Decimal; IndirectCostPct: Decimal; SerialNo: Code[50]; LotNo: Code[50])
    var
        ItemJnlLine: Record "Item Journal Line";
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        Usedate: Date;
    begin
        with TempItemChargeAssgntPurch do begin
            PrepareGenJnlLinePurch(ItemJnlLine, GenJnlLine, SerialNo, LotNo, AmountToAssign, ItemEntryNo,
              IndirectCostPct, ItemJnlLine."Document Type"::"Purchase Invoice");

            ItemJnlLine.CopyFromPurchInvHeader(PurchInvHeader);
            ItemJnlLine.CopyFromPurchInvLine(PurchInvLine);
            ItemJnlLine.Quantity := 0;
            ItemJnlLine."Quantity (Base)" := 0;

            if PurchInvHeader."Currency Code" <> '' then begin
                Currency.Get(PurchInvHeader."Currency Code");
                ItemJnlLine."Unit Cost" := Round(
                    ItemJnlLine.Amount / QuantityBase, Currency."Unit-Amount Rounding Precision");
                TotalChargeAmt := TotalChargeAmt + ItemJnlLine.Amount;
                if PurchInvHeader."Currency Code" <> '' then
                    ItemJnlLine.Amount := CurrExchRate.ExchangeAmtFCYToLCY(
                        Usedate, PurchInvHeader."Currency Code", TotalChargeAmt, PurchInvHeader."Currency Factor");
            end else
                ItemJnlLine."Unit Cost" := Round(
                    ItemJnlLine.Amount / QuantityBase, GLSetup."Unit-Amount Rounding Precision");

            ItemJnlLine.Amount := Round(ItemJnlLine.Amount, GLSetup."Amount Rounding Precision") - TotalChargeAmtLCY;
            if PurchInvHeader."Currency Code" <> '' then
                TotalChargeAmtLCY := TotalChargeAmtLCY + ItemJnlLine.Amount;

            ItemJnlPostLine.RunWithCheck(ItemJnlLine);
        end;
    end;

    local procedure PostPurchCrMemoItemCharge(GenJnlLine: Record "Gen. Journal Line"; PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr."; PurchCrMemoLine: Record "Purch. Cr. Memo Line"; ItemEntryNo: Integer; QuantityBase: Decimal; AmountToAssign: Decimal; QtyToAssign: Decimal; IndirectCostPct: Decimal; SerialNo: Code[50]; LotNo: Code[50])
    var
        ItemJnlLine: Record "Item Journal Line";
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        Usedate: Date;
    begin
        with TempItemChargeAssgntPurch do begin
            PrepareGenJnlLinePurch(ItemJnlLine, GenJnlLine, SerialNo, LotNo, AmountToAssign, ItemEntryNo,
              IndirectCostPct, ItemJnlLine."Document Type"::"Purchase Credit Memo");

            ItemJnlLine.CopyFromPurchCrMemoHeader(PurchCrMemoHeader);
            ItemJnlLine.CopyFromPurchCrMemoLine(PurchCrMemoLine);
            ItemJnlLine.Quantity := 0;
            ItemJnlLine."Quantity (Base)" := 0;

            if PurchCrMemoHeader."Currency Code" <> '' then begin
                Currency.Get(PurchCrMemoHeader."Currency Code");
                ItemJnlLine."Unit Cost" := Round(
                    ItemJnlLine.Amount / QuantityBase, Currency."Unit-Amount Rounding Precision");
                TotalChargeAmt := TotalChargeAmt + ItemJnlLine.Amount;
                if PurchCrMemoHeader."Currency Code" <> '' then
                    ItemJnlLine.Amount := CurrExchRate.ExchangeAmtFCYToLCY(
                        Usedate, PurchCrMemoHeader."Currency Code", TotalChargeAmt, PurchCrMemoHeader."Currency Factor");
            end else
                ItemJnlLine."Unit Cost" := Round(
                    ItemJnlLine.Amount / QuantityBase, GLSetup."Unit-Amount Rounding Precision");

            ItemJnlLine.Amount := Round(ItemJnlLine.Amount, GLSetup."Amount Rounding Precision") - TotalChargeAmtLCY;
            if PurchCrMemoHeader."Currency Code" <> '' then
                TotalChargeAmtLCY := TotalChargeAmtLCY + ItemJnlLine.Amount;

            ItemJnlPostLine.RunWithCheck(ItemJnlLine);
        end;
    end;

    local procedure PostSalesInvItemCharge(GenJnlLine: Record "Gen. Journal Line"; SalesInvHeader: Record "Sales Invoice Header"; SalesInvLine: Record "Sales Invoice Line"; ItemEntryNo: Integer; QuantityBase: Decimal; AmountToAssign: Decimal; QtyToAssign: Decimal; SerialNo: Code[50]; LotNo: Code[50])
    var
        ItemJnlLine: Record "Item Journal Line";
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        Usedate: Date;
    begin
        with TempItemChargeAssgntSales do begin
            PrepareGenJnlLineSales(ItemJnlLine, GenJnlLine, SerialNo, LotNo, AmountToAssign, ItemEntryNo,
              ItemJnlLine."Document Type"::"Sales Invoice");

            ItemJnlLine.CopyFromSalesInvHeader(SalesInvHeader);
            ItemJnlLine.CopyFromSalesInvLine(SalesInvLine);
            ItemJnlLine.Quantity := 0;
            ItemJnlLine."Quantity (Base)" := 0;

            if SalesInvHeader."Currency Code" <> '' then begin
                Currency.Get(SalesInvHeader."Currency Code");
                ItemJnlLine."Unit Cost" := Round(
                    ItemJnlLine.Amount / QuantityBase, Currency."Unit-Amount Rounding Precision");
                TotalChargeAmt := TotalChargeAmt + ItemJnlLine.Amount;
                if SalesInvHeader."Currency Code" <> '' then
                    ItemJnlLine.Amount := CurrExchRate.ExchangeAmtFCYToLCY(
                        Usedate, SalesInvHeader."Currency Code", TotalChargeAmt, SalesInvHeader."Currency Factor");
            end else
                ItemJnlLine."Unit Cost" := Round(
                    ItemJnlLine.Amount / QuantityBase, GLSetup."Unit-Amount Rounding Precision");

            ItemJnlLine.Amount := Round(ItemJnlLine.Amount, GLSetup."Amount Rounding Precision") - TotalChargeAmtLCY;
            if SalesInvHeader."Currency Code" <> '' then
                TotalChargeAmtLCY := TotalChargeAmtLCY + ItemJnlLine.Amount;

            ItemJnlPostLine.RunWithCheck(ItemJnlLine);
        end;
    end;

    local procedure PostSalesCrMemoItemCharge(GenJnlLine: Record "Gen. Journal Line"; SalesCrMemoHeader: Record "Sales Cr.Memo Header"; SalesCrMemoLine: Record "Sales Cr.Memo Line"; ItemEntryNo: Integer; QuantityBase: Decimal; AmountToAssign: Decimal; QtyToAssign: Decimal; SerialNo: Code[50]; LotNo: Code[50])
    var
        ItemJnlLine: Record "Item Journal Line";
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        Usedate: Date;
    begin
        with TempItemChargeAssgntSales do begin
            PrepareGenJnlLineSales(ItemJnlLine, GenJnlLine, SerialNo, LotNo, AmountToAssign, ItemEntryNo,
              ItemJnlLine."Document Type"::"Sales Credit Memo");

            ItemJnlLine.CopyFromSalesCrMemoHeader(SalesCrMemoHeader);
            ItemJnlLine.CopyFromSalesCrMemoLine(SalesCrMemoLine);
            ItemJnlLine.Quantity := 0;
            ItemJnlLine."Quantity (Base)" := 0;

            if SalesCrMemoHeader."Currency Code" <> '' then begin
                Currency.Get(SalesCrMemoHeader."Currency Code");
                ItemJnlLine."Unit Cost" := Round(
                    ItemJnlLine.Amount / QuantityBase, Currency."Unit-Amount Rounding Precision");
                TotalChargeAmt := TotalChargeAmt + ItemJnlLine.Amount;
                if SalesCrMemoHeader."Currency Code" <> '' then
                    ItemJnlLine.Amount := CurrExchRate.ExchangeAmtFCYToLCY(
                        Usedate, SalesCrMemoHeader."Currency Code", TotalChargeAmt, SalesCrMemoHeader."Currency Factor");
            end else
                ItemJnlLine."Unit Cost" := Round(
                    ItemJnlLine.Amount / QuantityBase, GLSetup."Unit-Amount Rounding Precision");

            ItemJnlLine.Amount := Round(ItemJnlLine.Amount, GLSetup."Amount Rounding Precision") - TotalChargeAmtLCY;
            if PurchCrMemoHeader."Currency Code" <> '' then
                TotalChargeAmtLCY := TotalChargeAmtLCY + ItemJnlLine.Amount;

            ItemJnlPostLine.RunWithCheck(ItemJnlLine);
        end;
    end;

    [Scope('OnPrem')]
    procedure PostFAAllocation(GenJnlLine: Record "Gen. Journal Line"; VATAllocation: Record "VAT Allocation Line"; var DeprAmount: Decimal; var DeprBookCode: Code[10])
    var
        FA: Record "Fixed Asset";
        FASetup: Record "FA Setup";
        FADeprBook: Record "FA Depreciation Book";
        FAJnlLine: Record "FA Journal Line";
        FALedgEntry: Record "FA Ledger Entry";
        FAJnlPostLine: Codeunit "FA Jnl.-Post Line";
    begin
        FASetup.Get();
        FASetup.TestField("Default Depr. Book");
        FASetup.TestField("Release Depr. Book");

        SourceCodeSetup.Get();

        GenJnlLine.TestField("Object Type", GenJnlLine."Object Type"::"Fixed Asset");

        PurchInvLine.Reset();
        PurchInvLine.SetRange("Document No.", GenJnlLine."Document No.");
        PurchInvLine.SetRange(Type, PurchInvLine.Type::"Fixed Asset");
        PurchInvLine.SetRange("No.", GenJnlLine."Object No.");
        PurchInvLine.SetRange("VAT Bus. Posting Group", VATAllocation."VAT Bus. Posting Group");
        PurchInvLine.SetRange("VAT Prod. Posting Group", VATAllocation."VAT Prod. Posting Group");
        if PurchInvLine.FindFirst then begin
            FA.Get(PurchInvLine."No.");
            FADeprBook.Get(FA."No.", FA.GetDefDeprBook);
            FADeprBook.CalcFields("Book Value");
            if FADeprBook."Book Value" <> 0 then // not released to operation
                DeprBookCode := FA.GetDefDeprBook
            else begin
                FADeprBook.Get(FA."No.", FASetup."Release Depr. Book");
                FADeprBook.CalcFields("Book Value");
                if (FADeprBook."Book Value" <> 0) or FA."Undepreciable FA" then // in operation
                    DeprBookCode := FASetup."Release Depr. Book"
                else
                    Error(Text001, FA."No.");
            end;

            FAJnlLine.Init();
            FAJnlLine.Validate("Depreciation Book Code", DeprBookCode);
            FAJnlLine.Validate("FA Posting Type", FAJnlLine."FA Posting Type"::"Acquisition Cost");
            FAJnlLine.Validate("FA No.", FA."No.");
            FAJnlLine."Posting Date" := GenJnlLine."Posting Date";
            if FADeprBook."Last Depreciation Date" <> 0D then begin
                FAJnlLine."FA Posting Date" := FADeprBook."Last Depreciation Date";
                FAJnlLine."Depr. Acquisition Cost" := true;
                FAJnlLine."Depr. until FA Posting Date" := true;
            end else
                FAJnlLine."FA Posting Date" := FAJnlLine."Posting Date";
            FAJnlLine."Document Type" := GenJnlLine."Document Type";
            FAJnlLine."Document No." := GenJnlLine."Document No.";
            FAJnlLine.Description := PurchInvLine.Description;
            FAJnlLine.Quantity := 0;
            FAJnlLine.Validate(Amount, VATAllocation.Amount);
            FAJnlLine."Shortcut Dimension 1 Code" := PurchInvLine."Shortcut Dimension 1 Code";
            FAJnlLine."Shortcut Dimension 2 Code" := PurchInvLine."Shortcut Dimension 2 Code";
            FAJnlLine."Dimension Set ID" := PurchInvLine."Dimension Set ID";
            FAJnlLine."Source Code" := SourceCodeSetup."VAT Allocation on Cost";
            FAJnlLine."Reason Code" := GenJnlLine."Reason Code";
            FAJnlPostLine.FAJnlPostLine(FAJnlLine, false);

            FALedgEntry.Reset();
            FALedgEntry.SetCurrentKey("FA No.", "Depreciation Book Code", "FA Posting Date");
            FALedgEntry.SetRange("FA No.", FA."No.");
            FALedgEntry.SetRange("Depreciation Book Code", DeprBookCode);
            FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::Depreciation);
            if FALedgEntry.FindLast then
                DeprAmount := FALedgEntry.Amount;
        end;
    end;

    [Scope('OnPrem')]
    procedure InsertItemReverseEntry(ValueEntryNo: Integer; var ReversalEntry: Record "Reversal Entry"): Integer
    var
        SourceCodeSetup: Record "Source Code Setup";
        ValueEntry: Record "Value Entry";
        ValueEntry3: Record "Value Entry";
        InvtSetup: Record "Inventory Setup";
        DimMgt: Codeunit DimensionManagement;
        TableID: array[10] of Integer;
        AccNo: array[10] of Code[20];
    begin
        ValueEntry3.Get(ValueEntryNo);
        ValueEntry3.TestField("Reversed by Entry No.", 0);

        if not DimMgt.CheckDimIDComb(ValueEntry3."Dimension Set ID") then
            Error(Text006, ValueEntry3.TableCaption, ValueEntry3."Entry No.", DimMgt.GetDimCombErr);
        Clear(TableID);
        Clear(AccNo);
        TableID[1] := DATABASE::Item;
        AccNo[1] := ValueEntry3."Item No.";
        if not DimMgt.CheckDimValuePosting(TableID, AccNo, ValueEntry3."Dimension Set ID") then
            Error(DimMgt.GetDimValuePostingErr);
        if NextReverseEntryNo = 0 then begin
            ValueEntry.LockTable();
            if ValueEntry.FindLast then
                NextReverseEntryNo := ValueEntry."Entry No.";
            SourceCodeSetup.Get();
            InvtSetup.Get();
        end;
        NextReverseEntryNo := NextReverseEntryNo + 1;
        TempValueEntry := ValueEntry3;
        TempValueEntry.Insert();
        SetItemReversalMark(ReversalEntry, ValueEntry3, NextReverseEntryNo);
        ValueEntry3."Entry No." := NextReverseEntryNo;
        ValueEntry3."Cost Amount (Actual)" := -ValueEntry3."Cost Amount (Actual)";
        ValueEntry3."Cost Posted to G/L" := -ValueEntry3."Cost Posted to G/L";
        ValueEntry3."Cost Amount (Actual) (ACY)" := -ValueEntry3."Cost Amount (Actual) (ACY)";
        ValueEntry3."Cost Posted to G/L (ACY)" := -ValueEntry3."Cost Posted to G/L (ACY)";
        ValueEntry3."Valued Quantity" := -ValueEntry3."Valued Quantity";
        ValueEntry3."User ID" := UserId;
        ValueEntry3."Source Code" := SourceCodeSetup.Reversal;
        ValueEntry3."Journal Batch Name" := '';
        ValueEntry3."Red Storno" := InvtSetup."Enable Red Storno";
        ValueEntry3."Dimension Set ID" := TempValueEntry."Dimension Set ID";
        ValueEntry3.Insert();
        InsertItemReg(NextReverseEntryNo, ValueEntry3."Source Code");
        exit(NextReverseEntryNo);
    end;

    local procedure SetItemReversalMark(var ReversalEntry: Record "Reversal Entry"; var ValueEntry: Record "Value Entry"; NextEntryNo: Integer)
    var
        ValueEntry2: Record "FA Ledger Entry";
        CloseReversal: Boolean;
    begin
        if ValueEntry."Reversed Entry No." <> 0 then begin
            ValueEntry2.Get(ValueEntry."Reversed Entry No.");
            if ValueEntry2."Reversed Entry No." <> 0 then
                Error(Text005);
            CloseReversal := true;
            ValueEntry2."Reversed by Entry No." := 0;
            ValueEntry2.Reversed := false;
            ValueEntry2.Modify();
        end;
        ValueEntry."Reversed by Entry No." := NextEntryNo;
        if CloseReversal then
            ValueEntry."Reversed Entry No." := NextEntryNo;
        ValueEntry.Reversed := true;
        ValueEntry.Modify();
        ValueEntry."Reversed by Entry No." := 0;
        ValueEntry."Reversed Entry No." := ValueEntry."Entry No.";
        if CloseReversal then
            ValueEntry."Reversed by Entry No." := ValueEntry."Entry No.";
        ReversalEntry.SetCurrentKey("Entry Type");
        ReversalEntry.SetRange("Entry Type", ReversalEntry."Entry Type"::"Fixed Asset");
        if ReversalEntry.FindFirst then
            repeat
                if ReversalEntry."Entry No." = ValueEntry."Entry No." then
                    ValueEntry.Description := ReversalEntry.Description;
            until ReversalEntry.Next() = 0;
    end;

    local procedure InsertItemReg(ValueEntryNo: Integer; SourceCode: Code[10])
    begin
        if ItemReg."No." = 0 then begin
            ItemReg.LockTable();
            if ItemReg.FindLast then
                ItemReg."No." := ItemReg."No." + 1
            else
                ItemReg."No." := 1;
            ItemReg.Init();
            ItemReg."From Value Entry No." := ValueEntryNo;
            ItemReg."To Value Entry No." := ValueEntryNo;
            ItemReg."Creation Date" := Today;
            ItemReg."Source Code" := SourceCode;
            ItemReg."User ID" := UserId;
            ItemReg.Insert();
        end else begin
            if ((ValueEntryNo < ItemReg."From Value Entry No.") and (ValueEntryNo <> 0)) or
               ((ItemReg."From Value Entry No." = 0) and (ValueEntryNo > 0))
            then
                ItemReg."From Value Entry No." := ValueEntryNo;
            if ValueEntryNo > ItemReg."To Value Entry No." then
                ItemReg."To Value Entry No." := ValueEntryNo;

            ItemReg.Modify();
        end;
    end;

    local procedure InsertItemChargeAssgntPurch(var NextLineNo: Integer; var TotalAmount: Decimal; DocumentNo: Code[20]; LineNo: Integer; ItemNo: Code[20]; Description: Text[100]; UnitCostLCY: Decimal; LineAmount: Decimal): Decimal
    begin
        with TempItemChargeAssgntPurch do begin
            Init;
            "Line No." := NextLineNo;
            NextLineNo := NextLineNo + 10000;
            VATPostingSetup.TestField("VAT Charge No.");
            "Item Charge No." := VATPostingSetup."VAT Charge No.";
            "Applies-to Doc. Type" := "Applies-to Doc. Type"::Invoice;
            "Applies-to Doc. No." := DocumentNo;
            "Applies-to Doc. Line No." := LineNo;
            "Item No." := ItemNo;
            Description := Description;
            "Unit Cost" := UnitCostLCY;
            "Applies-to Doc. Line Amount" := LineAmount;
            Insert;
            exit("Applies-to Doc. Line Amount");
        end;
    end;

    local procedure InsertItemChargeAssgntSales(NextLineNo: Integer; var TotalAmount: Decimal; DocumentNo: Code[20]; LineNo: Integer; ItemNo: Code[20]; Description: Text[100]; UnitCostLCY: Decimal; LineAmount: Decimal): Decimal
    begin
        with TempItemChargeAssgntSales do begin
            Init;
            "Document Line No." := LineNo;
            "Line No." := NextLineNo;
            NextLineNo := NextLineNo + 10000;
            VATPostingSetup.TestField("VAT Charge No.");
            "Item Charge No." := VATPostingSetup."VAT Charge No.";
            "Applies-to Doc. Type" := "Applies-to Doc. Type"::Invoice;
            "Applies-to Doc. No." := DocumentNo;
            "Applies-to Doc. Line No." := LineNo;
            "Item No." := ItemNo;
            Description := Description;
            "Unit Cost" := UnitCostLCY;
            "Applies-to Doc. Line Amount" := LineAmount;
            Insert;
            exit("Applies-to Doc. Line Amount");
        end;
    end;

    local procedure PrepareGenJnlLinePurch(var ItemJnlLine: Record "Item Journal Line"; GenJnlLine: Record "Gen. Journal Line"; SerialNo: Code[50]; LotNo: Code[50]; AmountToAssign: Decimal; ItemEntryNo: Integer; IndirectCostPct: Decimal; DocumentType: Enum "Item Ledger Document Type")
    begin
        with ItemJnlLine do begin
            Init;
            "Posting Date" := GenJnlLine."Posting Date";
            "Document Date" := GenJnlLine."Document Date";
            Description := TempItemChargeAssgntPurch.Description;
            "Item No." := TempItemChargeAssgntPurch."Item No.";
            "Serial No." := SerialNo;
            "Lot No." := LotNo;
            "Job Purchase" := "Job No." <> '';
            "Drop Shipment" := false;
            "Entry Type" := "Entry Type"::Purchase;
            "Document Type" := DocumentType;
            "Invoice No." := GenJnlLine."Document No.";
            "External Document No." := GenJnlLine."External Document No.";
            "Invoiced Quantity" := TempItemChargeAssgntPurch."Qty. to Assign";
            "Invoiced Qty. (Base)" := TempItemChargeAssgntPurch."Qty. to Assign";
            "Value Entry Type" := "Value Entry Type"::"Direct Cost";
            "Item Charge No." := TempItemChargeAssgntPurch."Item Charge No.";
            Amount := AmountToAssign;
            "Source Type" := "Source Type"::Vendor;
            "Source Code" := SourceCodeSetup."VAT Allocation on Cost";
            "Applies-to Entry" := ItemEntryNo;
            "Item Shpt. Entry No." := ItemEntryNo;
            "Indirect Cost %" := IndirectCostPct;
        end;
    end;

    [Scope('OnPrem')]
    procedure PrepareGenJnlLineSales(var ItemJnlLine: Record "Item Journal Line"; GenJnlLine: Record "Gen. Journal Line"; SerialNo: Code[50]; LotNo: Code[50]; AmountToAssign: Decimal; ItemEntryNo: Integer; DocumentType: Enum "Item Ledger Document Type")
    begin
        with ItemJnlLine do begin
            Init;
            "Posting Date" := GenJnlLine."Posting Date";
            "Document Date" := GenJnlLine."Document Date";
            Description := TempItemChargeAssgntSales.Description;
            "Item No." := TempItemChargeAssgntSales."Item No.";
            "Serial No." := SerialNo;
            "Lot No." := LotNo;
            "Job Purchase" := "Job No." <> '';
            "Drop Shipment" := false;
            "Entry Type" := "Entry Type"::Purchase;
            "Document Type" := DocumentType;
            "Invoice No." := GenJnlLine."Document No.";
            "External Document No." := GenJnlLine."External Document No.";
            "Invoiced Quantity" := TempItemChargeAssgntSales."Qty. to Assign";
            "Invoiced Qty. (Base)" := TempItemChargeAssgntSales."Qty. to Assign";
            "Value Entry Type" := "Value Entry Type"::"Direct Cost";
            "Item Charge No." := TempItemChargeAssgntSales."Item Charge No.";
            Amount := AmountToAssign;
            "Source Type" := "Source Type"::Vendor;
            "Source Code" := SourceCodeSetup."VAT Allocation on Cost";
            "Applies-to Entry" := ItemEntryNo;
            "Item Shpt. Entry No." := ItemEntryNo;
        end;
    end;

    [Scope('OnPrem')]
    procedure InitiItemChargeAssgntBuffer(var TempItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)"; var TempItemChargeAssgntSales: Record "Item Charge Assignment (Sales)")
    begin
        TempItemChargeAssgntPurch.Reset();
        TempItemChargeAssgntPurch.DeleteAll();
        TempItemChargeAssgntSales.Reset();
        TempItemChargeAssgntSales.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure GetEntrySign(Quantity: Decimal): Integer
    begin
        if Quantity > 0 then
            exit(1);
        exit(-1);
    end;

    [Scope('OnPrem')]
    procedure FillItemChargeAssgntPurch(GenJnlLine: Record "Gen. Journal Line"; VATAllocLine: Record "VAT Allocation Line"; var TotalAmount: Decimal; var NextLineNo: Integer)
    begin
        case GenJnlLine."Document Type" of
            GenJnlLine."Document Type"::Invoice:
                with PurchInvLine do begin
                    Reset;
                    SetRange("Document No.", GenJnlLine."Document No.");
                    SetRange(Type, Type::Item);
                    SetRange("VAT Bus. Posting Group", VATAllocLine."VAT Bus. Posting Group");
                    SetRange("VAT Prod. Posting Group", VATAllocLine."VAT Prod. Posting Group");
                    if FindSet then
                        repeat
                            TotalAmount := TotalAmount + InsertItemChargeAssgntPurch(NextLineNo, TotalAmount, "Document No.", "Line No.",
                                "No.", Description, "Unit Cost (LCY)", "Line Amount");
                        until Next() = 0;
                end;
            GenJnlLine."Document Type"::"Credit Memo":
                with PurchCrMemoLine do begin
                    Reset;
                    SetRange("Document No.", GenJnlLine."Document No.");
                    SetRange(Type, Type::Item);
                    SetRange("VAT Bus. Posting Group", VATAllocLine."VAT Bus. Posting Group");
                    SetRange("VAT Prod. Posting Group", VATAllocLine."VAT Prod. Posting Group");
                    if FindSet then
                        repeat
                            TotalAmount := TotalAmount + InsertItemChargeAssgntPurch(NextLineNo, TotalAmount, "Document No.", "Line No.",
                                "No.", Description, "Unit Cost (LCY)", "Line Amount");
                        until Next() = 0;
                end;
            else
                GenJnlLine.FieldError("Document Type");
        end;
    end;

    [Scope('OnPrem')]
    procedure AllocateItemChargeAssgntPurch(VATAllocLine: Record "VAT Allocation Line"; TotalAmount: Decimal; QtyRemainder: Decimal; AmountRemainder: Decimal)
    var
        TempItemChargeAssgntPurch2: Record "Item Charge Assignment (Purch)" temporary;
    begin
        TempItemChargeAssgntPurch.Reset();
        if TempItemChargeAssgntPurch.FindSet then
            repeat
                if TempItemChargeAssgntPurch."Applies-to Doc. Line Amount" <> 0 then
                    TempItemChargeAssgntPurch2."Qty. to Assign" :=
                      TempItemChargeAssgntPurch."Applies-to Doc. Line Amount" / TotalAmount + QtyRemainder
                else
                    TempItemChargeAssgntPurch2."Qty. to Assign" := 0;

                TempItemChargeAssgntPurch."Qty. to Assign" :=
                  Round(TempItemChargeAssgntPurch2."Qty. to Assign", 0.00001);
                TempItemChargeAssgntPurch."Amount to Assign" :=
                  TempItemChargeAssgntPurch."Qty. to Assign" * VATAllocLine.Amount + AmountRemainder;
                AmountRemainder :=
                  TempItemChargeAssgntPurch."Amount to Assign" -
                  Round(TempItemChargeAssgntPurch."Amount to Assign", RoundingPrecision);
                QtyRemainder :=
                  TempItemChargeAssgntPurch."Qty. to Assign" - TempItemChargeAssgntPurch2."Qty. to Assign";
                TempItemChargeAssgntPurch."Amount to Assign" :=
                  Round(TempItemChargeAssgntPurch."Amount to Assign", RoundingPrecision);
                TempItemChargeAssgntPurch.Modify();
            until TempItemChargeAssgntPurch.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure PostItemChargeAssgntPurch(GenJnlLine: Record "Gen. Journal Line")
    begin
        case GenJnlLine."Document Type" of
            GenJnlLine."Document Type"::Invoice:
                begin
                    PurchInvHeader.Get(GenJnlLine."Document No.");
                    TempItemChargeAssgntPurch.Reset();
                    if TempItemChargeAssgntPurch.FindSet then
                        repeat
                            PurchInvLine.Get(
                              TempItemChargeAssgntPurch."Applies-to Doc. No.", TempItemChargeAssgntPurch."Applies-to Doc. Line No.");
                            PostItemChargePerPurchInvLine(GenJnlLine, PurchInvHeader, PurchInvLine);
                        until TempItemChargeAssgntPurch.Next() = 0;
                end;
            GenJnlLine."Document Type"::"Credit Memo":
                begin
                    PurchCrMemoHeader.Get(GenJnlLine."Document No.");
                    TempItemChargeAssgntPurch.Reset();
                    if TempItemChargeAssgntPurch.FindSet then
                        repeat
                            PurchCrMemoLine.Get(
                              TempItemChargeAssgntPurch."Applies-to Doc. No.", TempItemChargeAssgntPurch."Applies-to Doc. Line No.");
                            PostItemChargePerPurchCrMLine(GenJnlLine, PurchCrMemoHeader, PurchCrMemoLine);
                        until TempItemChargeAssgntPurch.Next() = 0;
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure FillItemChargeAssgntSales(GenJnlLine: Record "Gen. Journal Line"; VATAllocLine: Record "VAT Allocation Line"; var TotalAmount: Decimal; NextLineNo: Integer)
    begin
        case GenJnlLine."Document Type" of
            GenJnlLine."Document Type"::Invoice:
                with SalesInvLine do begin
                    Reset;
                    SetRange("Document No.", GenJnlLine."Document No.");
                    SetRange(Type, Type::Item);
                    SetRange("VAT Bus. Posting Group", VATAllocLine."VAT Bus. Posting Group");
                    SetRange("VAT Prod. Posting Group", VATAllocLine."VAT Prod. Posting Group");
                    if FindSet then
                        repeat
                            TotalAmount :=
                              TotalAmount +
                              InsertItemChargeAssgntSales(
                                NextLineNo, TotalAmount, "Document No.", "Line No.",
                                "No.", Description, "Unit Cost (LCY)", "Line Amount");
                        until Next() = 0;
                end;
            GenJnlLine."Document Type"::"Credit Memo":
                with SalesCrMemoLine do begin
                    Reset;
                    SetRange("Document No.", GenJnlLine."Document No.");
                    SetRange(Type, Type::Item);
                    SetRange("VAT Bus. Posting Group", VATAllocLine."VAT Bus. Posting Group");
                    SetRange("VAT Prod. Posting Group", VATAllocLine."VAT Prod. Posting Group");
                    if FindSet then
                        repeat
                            TotalAmount := TotalAmount + InsertItemChargeAssgntSales(NextLineNo, TotalAmount, "Document No.", "Line No.",
                                "No.", Description, "Unit Cost (LCY)", "Line Amount");
                        until Next() = 0;
                end;
            else
                GenJnlLine.FieldError("Document Type");
        end;
    end;

    [Scope('OnPrem')]
    procedure AllocateItemChargeAssgntSales(VATAllocLine: Record "VAT Allocation Line"; TotalAmount: Decimal; QtyRemainder: Decimal; AmountRemainder: Decimal)
    var
        TempItemChargeAssgntSales2: Record "Item Charge Assignment (Sales)" temporary;
    begin
        TempItemChargeAssgntSales.Reset();
        if TempItemChargeAssgntSales.FindSet then
            repeat
                if TempItemChargeAssgntSales."Applies-to Doc. Line Amount" <> 0 then
                    TempItemChargeAssgntSales2."Qty. to Assign" :=
                      TempItemChargeAssgntSales."Applies-to Doc. Line Amount" / TotalAmount + QtyRemainder
                else
                    TempItemChargeAssgntSales2."Qty. to Assign" := 0;

                TempItemChargeAssgntSales."Qty. to Assign" :=
                  Round(TempItemChargeAssgntSales2."Qty. to Assign", 0.00001);
                TempItemChargeAssgntSales."Amount to Assign" :=
                  TempItemChargeAssgntSales."Qty. to Assign" * VATAllocLine.Amount + AmountRemainder;
                AmountRemainder :=
                  TempItemChargeAssgntSales."Amount to Assign" -
                  Round(TempItemChargeAssgntSales."Amount to Assign", RoundingPrecision);
                QtyRemainder :=
                  TempItemChargeAssgntSales."Qty. to Assign" - TempItemChargeAssgntSales2."Qty. to Assign";
                TempItemChargeAssgntSales."Amount to Assign" :=
                  Round(TempItemChargeAssgntSales."Amount to Assign", RoundingPrecision);
                TempItemChargeAssgntSales.Modify();
            until TempItemChargeAssgntSales.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure PostItemChargeAssgntSales(GenJnlLine: Record "Gen. Journal Line")
    begin
        case GenJnlLine."Document Type" of
            GenJnlLine."Document Type"::Invoice:
                begin
                    SalesInvHeader.Get(GenJnlLine."Document No.");
                    TempItemChargeAssgntSales.Reset();
                    if TempItemChargeAssgntSales.FindSet then
                        repeat
                            SalesInvLine.Get(
                              TempItemChargeAssgntSales."Applies-to Doc. No.", TempItemChargeAssgntSales."Applies-to Doc. Line No.");
                            PostItemChargePerSalesInvLine(GenJnlLine, SalesInvHeader, SalesInvLine);
                        until TempItemChargeAssgntSales.Next() = 0;
                end;
            GenJnlLine."Document Type"::"Credit Memo":
                begin
                    SalesCrMemoHeader.Get(GenJnlLine."Document No.");
                    TempItemChargeAssgntPurch.Reset();
                    if TempItemChargeAssgntSales.FindSet then
                        repeat
                            SalesCrMemoLine.Get(
                              TempItemChargeAssgntSales."Applies-to Doc. No.", TempItemChargeAssgntSales."Applies-to Doc. Line No.");
                            PostItemChargePerSalesCrMLine(GenJnlLine, SalesCrMemoHeader, SalesCrMemoLine);
                        until TempItemChargeAssgntSales.Next() = 0;
                end;
        end;
    end;
}

