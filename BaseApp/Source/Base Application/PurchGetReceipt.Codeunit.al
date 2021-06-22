codeunit 74 "Purch.-Get Receipt"
{
    TableNo = "Purchase Line";

    trigger OnRun()
    begin
        PurchHeader.Get("Document Type", "Document No.");
        PurchHeader.TestField("Document Type", PurchHeader."Document Type"::Invoice);
        PurchHeader.TestField(Status, PurchHeader.Status::Open);

        PurchRcptLine.SetCurrentKey("Pay-to Vendor No.");
        PurchRcptLine.SetRange("Pay-to Vendor No.", PurchHeader."Pay-to Vendor No.");
        PurchRcptLine.SetRange("Buy-from Vendor No.", PurchHeader."Buy-from Vendor No.");
        PurchRcptLine.SetFilter("Qty. Rcd. Not Invoiced", '<>0');
        PurchRcptLine.SetRange("Currency Code", PurchHeader."Currency Code");

        OnAfterPurchRcptLineSetFilters(PurchRcptLine, PurchHeader);

        GetReceipts.SetTableView(PurchRcptLine);
        GetReceipts.LookupMode := true;
        GetReceipts.SetPurchHeader(PurchHeader);
        GetReceipts.RunModal;
    end;

    var
        Text000: Label 'The %1 on the %2 %3 and the %4 %5 must be the same.';
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        UOMMgt: Codeunit "Unit of Measure Management";
        GetReceipts: Page "Get Receipt Lines";

    procedure CreateInvLines(var PurchRcptLine2: Record "Purch. Rcpt. Line")
    var
        TransferLine: Boolean;
        PrepmtAmtToDeductRounding: Decimal;
    begin
        OnBeforeCreateInvLines(PurchRcptLine2, TransferLine);

        with PurchRcptLine2 do begin
            SetFilter("Qty. Rcd. Not Invoiced", '<>0');
            OnCreateInvLinesOnBeforeFind(PurchRcptLine2);
            if Find('-') then begin
                PurchLine.LockTable();
                PurchLine.SetRange("Document Type", PurchHeader."Document Type");
                PurchLine.SetRange("Document No.", PurchHeader."No.");
                PurchLine."Document Type" := PurchHeader."Document Type";
                PurchLine."Document No." := PurchHeader."No.";

                OnBeforeInsertLines(PurchHeader);

                repeat
                    if PurchRcptHeader."No." <> "Document No." then begin
                        PurchRcptHeader.Get("Document No.");
                        TransferLine := true;
                        if PurchRcptHeader."Currency Code" <> PurchHeader."Currency Code" then begin
                            Message(
                              Text000,
                              PurchHeader.FieldCaption("Currency Code"),
                              PurchHeader.TableCaption, PurchHeader."No.",
                              PurchRcptHeader.TableCaption, PurchRcptHeader."No.");
                            TransferLine := false;
                        end;
                        if PurchRcptHeader."Pay-to Vendor No." <> PurchHeader."Pay-to Vendor No." then begin
                            Message(
                              Text000,
                              PurchHeader.FieldCaption("Pay-to Vendor No."),
                              PurchHeader.TableCaption, PurchHeader."No.",
                              PurchRcptHeader.TableCaption, PurchRcptHeader."No.");
                            TransferLine := false;
                        end;
                        OnBeforeTransferLineToPurchaseDoc(PurchRcptHeader, PurchRcptLine2, PurchHeader, TransferLine);
                    end;
                    if TransferLine then begin
                        PurchRcptLine := PurchRcptLine2;
                        PurchRcptLine.InsertInvLineFromRcptLine(PurchLine);
                        CalcUpdatePrepmtAmtToDeductRounding(PurchRcptLine, PurchLine, PrepmtAmtToDeductRounding);
                        if Type = Type::"Charge (Item)" then
                            GetItemChargeAssgnt(PurchRcptLine2, PurchLine."Qty. to Invoice");
                    end;
                until Next = 0;
                OnAfterInsertLines(PurchHeader);

                CalcInvoiceDiscount(PurchLine);
                OnAfterCalcInvoiceDiscount(PurchHeader);

                if TransferLine then
                    AdjustPrepmtAmtToDeductRounding(PurchLine, PrepmtAmtToDeductRounding);
            end;
        end;
    end;

    procedure SetPurchHeader(var PurchHeader2: Record "Purchase Header")
    begin
        PurchHeader.Get(PurchHeader2."Document Type", PurchHeader2."No.");
        PurchHeader.TestField("Document Type", PurchHeader."Document Type"::Invoice);
    end;

    procedure GetItemChargeAssgnt(var PurchRcptLine: Record "Purch. Rcpt. Line"; QtyToInvoice: Decimal)
    var
        PurchOrderLine: Record "Purchase Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetItemChargeAssgnt(PurchRcptLine, QtyToInvoice, IsHandled);
        if IsHandled then
            exit;

        if not PurchOrderLine.Get(PurchOrderLine."Document Type"::Order, PurchRcptLine."Order No.", PurchRcptLine."Order Line No.") then
            exit;

        ItemChargeAssgntPurch.LockTable();
        ItemChargeAssgntPurch.Reset();
        ItemChargeAssgntPurch.SetRange("Document Type", PurchOrderLine."Document Type");
        ItemChargeAssgntPurch.SetRange("Document No.", PurchOrderLine."Document No.");
        ItemChargeAssgntPurch.SetRange("Document Line No.", PurchOrderLine."Line No.");
        if ItemChargeAssgntPurch.FindFirst then begin
            ItemChargeAssgntPurch.CalcSums("Qty. to Assign");
            if ItemChargeAssgntPurch."Qty. to Assign" <> 0 then
                CopyItemChargeAssgnt(
                  PurchOrderLine, PurchRcptLine, ItemChargeAssgntPurch."Qty. to Assign", QtyToInvoice / ItemChargeAssgntPurch."Qty. to Assign");
        end;
    end;

    local procedure CopyItemChargeAssgnt(PurchOrderLine: Record "Purchase Line"; PurchRcptLine: Record "Purch. Rcpt. Line"; QtyToAssign: Decimal; QtyFactor: Decimal)
    var
        PurchRcptLine2: Record "Purch. Rcpt. Line";
        PurchLine2: Record "Purchase Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        ItemChargeAssgntPurch2: Record "Item Charge Assignment (Purch)";
        InsertChargeAssgnt: Boolean;
        LineQtyToAssign: Decimal;
    begin
        with PurchOrderLine do begin
            ItemChargeAssgntPurch.SetRange("Document Type", "Document Type");
            ItemChargeAssgntPurch.SetRange("Document No.", "Document No.");
            ItemChargeAssgntPurch.SetRange("Document Line No.", "Line No.");
            if ItemChargeAssgntPurch.Find('-') then
                repeat
                    if ItemChargeAssgntPurch."Qty. to Assign" <> 0 then begin
                        ItemChargeAssgntPurch2 := ItemChargeAssgntPurch;
                        ItemChargeAssgntPurch2."Qty. to Assign" :=
                          Round(QtyFactor * ItemChargeAssgntPurch2."Qty. to Assign", UOMMgt.QtyRndPrecision);
                        PurchLine2.SetRange("Receipt No.", PurchRcptLine."Document No.");
                        PurchLine2.SetRange("Receipt Line No.", PurchRcptLine."Line No.");
                        if PurchLine2.Find('-') then
                            repeat
                                PurchLine2.CalcFields("Qty. to Assign");
                                InsertChargeAssgnt := PurchLine2."Qty. to Assign" <> PurchLine2.Quantity;
                            until (PurchLine2.Next = 0) or InsertChargeAssgnt;

                        if InsertChargeAssgnt then begin
                            ItemChargeAssgntPurch2."Document Type" := PurchLine2."Document Type";
                            ItemChargeAssgntPurch2."Document No." := PurchLine2."Document No.";
                            ItemChargeAssgntPurch2."Document Line No." := PurchLine2."Line No.";
                            ItemChargeAssgntPurch2."Qty. Assigned" := 0;
                            LineQtyToAssign :=
                              ItemChargeAssgntPurch2."Qty. to Assign" - GetQtyAssignedInNewLine(ItemChargeAssgntPurch2);
                            InsertChargeAssgnt := LineQtyToAssign <> 0;
                            if InsertChargeAssgnt then begin
                                if Abs(QtyToAssign) < Abs(LineQtyToAssign) then
                                    ItemChargeAssgntPurch2."Qty. to Assign" := QtyToAssign;
                                if Abs(PurchLine2.Quantity - PurchLine2."Qty. to Assign") <
                                   Abs(LineQtyToAssign)
                                then
                                    ItemChargeAssgntPurch2."Qty. to Assign" :=
                                      PurchLine2.Quantity - PurchLine2."Qty. to Assign";
                                ItemChargeAssgntPurch2.Validate("Unit Cost");

                                if ItemChargeAssgntPurch2."Applies-to Doc. Type" = "Document Type" then begin
                                    ItemChargeAssgntPurch2."Applies-to Doc. Type" := PurchLine2."Document Type";
                                    ItemChargeAssgntPurch2."Applies-to Doc. No." := PurchLine2."Document No.";
                                    PurchRcptLine2.SetCurrentKey("Order No.", "Order Line No.");
                                    PurchRcptLine2.SetRange("Order No.", ItemChargeAssgntPurch."Applies-to Doc. No.");
                                    PurchRcptLine2.SetRange("Order Line No.", ItemChargeAssgntPurch."Applies-to Doc. Line No.");
                                    PurchRcptLine2.SetFilter(Quantity, '<>0');
                                    if PurchRcptLine2.FindFirst then begin
                                        PurchLine2.SetCurrentKey("Document Type", "Receipt No.", "Receipt Line No.");
                                        PurchLine2.SetRange("Document Type", PurchLine2."Document Type"::Invoice);
                                        PurchLine2.SetRange("Receipt No.", PurchRcptLine2."Document No.");
                                        PurchLine2.SetRange("Receipt Line No.", PurchRcptLine2."Line No.");
                                        if PurchLine2.Find('-') and (PurchLine2.Quantity <> 0) then
                                            ItemChargeAssgntPurch2."Applies-to Doc. Line No." := PurchLine2."Line No."
                                        else
                                            InsertChargeAssgnt := false;
                                    end else
                                        InsertChargeAssgnt := false;
                                end;
                            end;
                        end;

                        if InsertChargeAssgnt and (ItemChargeAssgntPurch2."Qty. to Assign" <> 0) then begin
                            ItemChargeAssgntPurch2.Insert();
                            QtyToAssign := QtyToAssign - ItemChargeAssgntPurch2."Qty. to Assign";
                        end;
                    end;
                until ItemChargeAssgntPurch.Next = 0;
        end;
    end;

    local procedure GetQtyAssignedInNewLine(ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)"): Decimal
    begin
        with ItemChargeAssgntPurch do begin
            SetRange("Document Type", "Document Type");
            SetRange("Document No.", "Document No.");
            SetRange("Document Line No.", "Document Line No.");
            SetRange("Applies-to Doc. Type", "Applies-to Doc. Type");
            SetRange("Applies-to Doc. No.", "Applies-to Doc. No.");
            SetRange("Applies-to Doc. Line No.", "Applies-to Doc. Line No.");
            CalcSums("Qty. to Assign");
            exit("Qty. to Assign");
        end;
    end;

    local procedure CalcInvoiceDiscount(var PurchLine: Record "Purchase Line")
    var
        PurchSetup: Record "Purchases & Payables Setup";
        PurchCalcDiscount: Codeunit "Purch.-Calc.Discount";
    begin
        PurchSetup.Get();
        if PurchSetup."Calc. Inv. Discount" then
            PurchCalcDiscount.CalculateInvoiceDiscountOnLine(PurchLine);
    end;

    local procedure CalcUpdatePrepmtAmtToDeductRounding(PurchRcptLine: Record "Purch. Rcpt. Line"; PurchaseLine: Record "Purchase Line"; var RoundingAmount: Decimal)
    var
        PurchOrderLine: Record "Purchase Line";
        Fraction: Decimal;
        FractionAmount: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcUpdatePrepmtAmtToDeductRounding(PurchRcptLine, PurchaseLine, RoundingAmount, IsHandled);
        if IsHandled then
            exit;

        if (PurchaseLine."Prepayment %" > 0) and (PurchaseLine."Prepayment %" < 100) and
           (PurchaseLine."Document Type" = PurchaseLine."Document Type"::Invoice)
        then begin
            PurchOrderLine.Get(PurchOrderLine."Document Type"::Order, PurchRcptLine."Order No.", PurchRcptLine."Order Line No.");
            Fraction := PurchRcptLine.Quantity / PurchOrderLine.Quantity;
            FractionAmount := Fraction * PurchOrderLine."Prepmt Amt to Deduct";
            RoundingAmount += PurchaseLine."Prepmt Amt to Deduct" - FractionAmount;
        end;
    end;

    local procedure AdjustPrepmtAmtToDeductRounding(var PurchaseLine: Record "Purchase Line"; RoundingAmount: Decimal)
    begin
        if Round(RoundingAmount) <> 0 then begin
            PurchaseLine."Prepmt Amt to Deduct" -= Round(RoundingAmount);
            PurchaseLine.Modify();
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcInvoiceDiscount(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertLines(var PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchRcptLineSetFilters(var PurchRcptLine: Record "Purch. Rcpt. Line"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcUpdatePrepmtAmtToDeductRounding(PurchRcptLine: Record "Purch. Rcpt. Line"; PurchaseLine: Record "Purchase Line"; var RoundingAmount: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateInvLines(var PurchRcptLine: Record "Purch. Rcpt. Line"; var TransferLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertLines(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetItemChargeAssgnt(var PurchRcptLine: Record "Purch. Rcpt. Line"; QtyToInvoice: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferLineToPurchaseDoc(var PurchRcptHeader: Record "Purch. Rcpt. Header"; var PurchRcptLine: Record "Purch. Rcpt. Line"; var PurchaseHeader: Record "Purchase Header"; var TransferLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateInvLinesOnBeforeFind(var PurchRcptLine: Record "Purch. Rcpt. Line")
    begin
    end;
}

