page 161 "Purchase Statistics"
{
    Caption = 'Purchase Statistics';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = ListPlus;
    SourceTable = "Purchase Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(Amount; TotalPurchLine."Line Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text001, false);
                    Caption = 'Amount';
                    Editable = false;
                    ToolTip = 'Specifies the net amount of all the lines in the purchase document.';
                }
                field(InvDiscountAmount; TotalPurchLine."Inv. Discount Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Inv. Discount Amount';
                    ToolTip = 'Specifies the invoice discount amount for the purchase document.';

                    trigger OnValidate()
                    begin
                        UpdateInvDiscAmount;
                    end;
                }
                field(TotalAmount1; TotalAmount1)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text002, false);
                    Caption = 'Total';
                    ToolTip = 'Specifies the total amount less any invoice discount amount and excluding VAT for the purchase document.';

                    trigger OnValidate()
                    begin
                        UpdateTotalAmount;
                    end;
                }
                field(VATAmount; VATAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = Format(VATAmountText);
                    Caption = 'VAT Amount';
                    Editable = false;
                    ToolTip = 'Specifies the total VAT amount that has been calculated for all the lines in the purchase document.';
                }
                field(TotalAmount2; TotalAmount2)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text002, true);
                    Caption = 'Total Incl. VAT';
                    Editable = false;
                    ToolTip = 'Specifies the total amount including VAT that will be posted to the vendor''s account for all the lines in the purchase document. This is the amount that you owe the vendor based on this purchase document. If the document is a credit memo, it is the amount that the vendor owes you.';
                }
                field("TotalPurchLineLCY.Amount"; TotalPurchLineLCY.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Purchase (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies your total purchases. It is calculated from amounts excluding VAT on all completed and open purchase invoices and credit memos.';
                }
                field(Quantity; TotalPurchLine.Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the total quantity of G/L account entries, items, and/or resources in the purchase document.';
                }
                field("TotalPurchLine.""Units per Parcel"""; TotalPurchLine."Units per Parcel")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Parcels';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the total number of parcels in the purchase document.';
                }
                field("TotalPurchLine.""Net Weight"""; TotalPurchLine."Net Weight")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Net Weight';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the total net weight of the items in the purchase document.';
                }
                field("TotalPurchLine.""Gross Weight"""; TotalPurchLine."Gross Weight")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Gross Weight';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the total gross weight of the items in the purchase document.';
                }
                field("TotalPurchLine.""Unit Volume"""; TotalPurchLine."Unit Volume")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Volume';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the total volume of the items in the purchase document.';
                }
            }
            part(SubForm; "VAT Specification Subform")
            {
                ApplicationArea = Basic, Suite;
            }
            group("Prepayment (Deduct)")
            {
                Caption = 'Prepayment (Deduct)';
                field("-""Adv.Letter Link.Amt. to Deduct"""; -"Adv.Letter Link.Amt. to Deduct")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount Including VAT';
                    Editable = false;
                    ToolTip = 'Specifies the total prepayment amount for the order, for all lines and all prepayment invoices.';
                }
                field("TempTotVATAmountLinePrep.""VAT Amount"""; TempTotVATAmountLinePrep."VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'VAT Amount';
                    Editable = false;
                    ToolTip = 'Specifies the vat amount';
                }
                field("TempTotVATAmountLinePrep.""VAT Base"""; TempTotVATAmountLinePrep."VAT Base")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'VAT Base';
                    Editable = false;
                    ToolTip = 'Specifies vat base of purchase quote';
                }
                field("TempVATAmountLinePrep.COUNT"; TempVATAmountLinePrep.Count)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'No. of VAT Lines';
                    DrillDown = true;
                    ToolTip = 'Specifies the number of VAT lines.';

                    trigger OnDrillDown()
                    begin
                        VATLinesDrillDown(TempVATAmountLinePrep, false); // NAVCZ
                    end;
                }
            }
            group("Invoicing (Final)")
            {
                Caption = 'Invoicing (Final)';
                field("TotalPurchLine.""Amount Including VAT""-""Adv.Letter Link.Amt. to Deduct"""; TotalPurchLine."Amount Including VAT" - "Adv.Letter Link.Amt. to Deduct")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount Including VAT';
                    Editable = false;
                    ToolTip = 'Specifies the total prepayment amount for the order, for all lines and all prepayment invoices.';
                }
                field("TempTotVATAmountLineTot.""VAT Amount"""; TempTotVATAmountLineTot."VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'VAT Amount';
                    Editable = false;
                    ToolTip = 'Specifies the vat amount';
                }
                field("TempTotVATAmountLineTot.""VAT Base"""; TempTotVATAmountLineTot."VAT Base")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'VAT Base';
                    Editable = false;
                    ToolTip = 'Specifies vat base of purchase quote';
                }
                field("TempVATAmountLineTot.COUNT"; TempVATAmountLineTot.Count)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'No. of VAT Lines';
                    DrillDown = true;
                    ToolTip = 'Specifies the number of VAT lines.';

                    trigger OnDrillDown()
                    begin
                        VATLinesDrillDown(TempVATAmountLineTot, false); // NAVCZ
                    end;
                }
            }
            group(Vendor)
            {
                Caption = 'Vendor';
                field("Vend.""Balance (LCY)"""; Vend."Balance (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Balance (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the balance on the vendor''s account.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        PurchPostAdv: Codeunit "Purchase-Post Advances";
    begin
        CalcFields("Adv.Letter Link.Amt. to Deduct"); // NAVCZ
        CurrPage.Caption(StrSubstNo(Text000, "Document Type"));
        if PrevNo = "No." then begin
            GetVATSpecification;
            exit;
        end;

        PrevNo := "No.";
        FilterGroup(2);
        SetRange("No.", PrevNo);
        FilterGroup(0);

        // NAVCZ
        TempVATAmountLinePrep.Reset();
        TempVATAmountLinePrep.DeleteAll();
        Clear(TempVATAmountLinePrep);
        TempVATAmountLineTot.Reset();
        TempVATAmountLineTot.DeleteAll();
        Clear(TempVATAmountLineTot);
        Clear(TempTotVATAmountLinePrep);
        Clear(TempTotVATAmountLineTot);
        // NAVCZ

        CalculateTotals;

        // NAVCZ
        if ("Document Type" = "Document Type"::Invoice) and ("Prepayment Type" = "Prepayment Type"::Advance) then begin
            TempVATAmountLinePrep.Reset();
            TempVATAmountLinePrep.DeleteAll();
            Clear(TempVATAmountLinePrep);

            PurchPostAdv.CalcVATCorrection(Rec, TempVATAmountLinePrep);
        end;
        SumVATLinesAll;
        SumTotalVATLines(
          TempVATAmountLinePrep, TempTotVATAmountLinePrep."Amount Including VAT",
          TempTotVATAmountLinePrep."VAT Amount", TempTotVATAmountLinePrep."VAT Base");
        SumTotalVATLines(
          TempVATAmountLineTot, TempTotVATAmountLineTot."Amount Including VAT", TempTotVATAmountLineTot."VAT Amount",
          TempTotVATAmountLineTot."VAT Base");
        // NAVCZ
    end;

    trigger OnOpenPage()
    begin
        PurchSetup.Get();
        AllowInvDisc :=
          not (PurchSetup."Calc. Inv. Discount" and VendInvDiscRecExists("Invoice Disc. Code"));
        AllowVATDifference :=
          PurchSetup."Allow VAT Difference" and
          not ("Document Type" in ["Document Type"::Quote, "Document Type"::"Blanket Order"]);
        OnOpenPageOnBeforeSetEditable(AllowInvDisc, AllowVATDifference, Rec);
        CurrPage.Editable := AllowVATDifference or AllowInvDisc;
        SetVATSpecification;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        GetVATSpecification;
        if TempVATAmountLine.GetAnyLineModified then
            UpdateVATOnPurchLines;
        exit(true);
    end;

    var
        Text000: Label 'Purchase %1 Statistics';
        Text001: Label 'Amount';
        Text002: Label 'Total';
        Text003: Label '%1 must not be 0.';
        Text004: Label '%1 must not be greater than %2.';
        Text005: Label 'You cannot change the invoice discount because a vendor invoice discount with the code %1 exists.';
        TempVATAmountLinePrep: Record "VAT Amount Line" temporary;
        TempVATAmountLineTot: Record "VAT Amount Line" temporary;
        TempTotVATAmountLinePrep: Record "VAT Amount Line" temporary;
        TempTotVATAmountLineTot: Record "VAT Amount Line" temporary;
        VATAmountLines: Page "VAT Amount Lines";
        TotalPurchLine: Record "Purchase Line";
        TotalPurchLineLCY: Record "Purchase Line";
        Vend: Record Vendor;
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        PurchSetup: Record "Purchases & Payables Setup";
        PurchPost: Codeunit "Purch.-Post";
        TotalAmount1: Decimal;
        TotalAmount2: Decimal;
        VATAmount: Decimal;
        VATAmountText: Text[30];
        PrevNo: Code[20];
        AllowInvDisc: Boolean;
        AllowVATDifference: Boolean;

    local procedure UpdateHeaderInfo()
    var
        CurrExchRate: Record "Currency Exchange Rate";
        Currency: Record Currency;
        GLSetup: Record "General Ledger Setup";
        UseDate: Date;
        RoundingPrecisionLCY: Decimal;
        RoundingDirectionLCY: Text[1];
    begin
        TotalPurchLine."Inv. Discount Amount" := TempVATAmountLine.GetTotalInvDiscAmount;
        TotalAmount1 :=
          TotalPurchLine."Line Amount" - TotalPurchLine."Inv. Discount Amount";
        VATAmount := TempVATAmountLine.GetTotalVATAmount;
        if "Prices Including VAT" then begin
            TotalAmount1 := TempVATAmountLine.GetTotalAmountInclVAT;
            TotalAmount2 := TotalAmount1 - VATAmount;
            TotalPurchLine."Line Amount" := TotalAmount1 + TotalPurchLine."Inv. Discount Amount";
        end else
            TotalAmount2 := TotalAmount1 + VATAmount;

        if "Prices Including VAT" then
            TotalPurchLineLCY.Amount := TotalAmount2
        else
            TotalPurchLineLCY.Amount := TotalAmount1;
        if "Currency Code" <> '' then begin
            if ("Document Type" in ["Document Type"::"Blanket Order", "Document Type"::Quote]) and
               ("Posting Date" = 0D)
            then
                UseDate := WorkDate
            else
                UseDate := "Posting Date";

            TotalPurchLineLCY.Amount :=
              CurrExchRate.ExchangeAmtFCYToLCY(
                UseDate, "Currency Code", TotalPurchLineLCY.Amount, "Currency Factor");
            // NAVCZ
            if (TotalPurchLineLCY."VAT Calculation Type" = TotalPurchLineLCY."VAT Calculation Type"::"Normal VAT") or
               (TotalPurchLineLCY."VAT Calculation Type" = TotalPurchLineLCY."VAT Calculation Type"::"Reverse Charge VAT")
            then begin
                GLSetup.Get();
                Currency.Get("Currency Code");
                GLSetup.GetRoundingParamentersLCY(Currency, RoundingPrecisionLCY, RoundingDirectionLCY);

                if "Prices Including VAT" then
                    if GLSetup."Round VAT Coeff." then begin
                        TotalPurchLineLCY.Amount :=
                          Round(
                            (TotalPurchLineLCY."Line Amount" - TempVATAmountLine."Invoice Discount Amount") *
                            Round(
                              TempVATAmountLine."VAT %" / (100 + TempVATAmountLine."VAT %"),
                              GLSetup."VAT Coeff. Rounding Precision") *
                            (1 - "VAT Base Discount %" / 100),
                            Currency."Amount Rounding Precision",
                            Currency.VATRoundingDirection);

                        TotalPurchLineLCY.Amount := TotalPurchLineLCY."Line Amount" - TotalPurchLineLCY.Amount;
                    end else
                        TotalPurchLineLCY.Amount :=
                          Round(
                            (TotalPurchLineLCY."Line Amount" - TempVATAmountLine."Invoice Discount Amount") /
                            (1 + TempVATAmountLine."VAT %" / 100),
                            RoundingPrecisionLCY) - TempVATAmountLine."VAT Difference";
            end;
            // NAVCZ
        end;

        OnAfterUpdateHeaderInfo();
    end;

    local procedure GetVATSpecification()
    begin
        CurrPage.SubForm.PAGE.GetTempVATAmountLine(TempVATAmountLine);
        if TempVATAmountLine.GetAnyLineModified then
            UpdateHeaderInfo;
    end;

    local procedure SetVATSpecification()
    begin
        CurrPage.SubForm.PAGE.SetTempVATAmountLine(TempVATAmountLine);
        CurrPage.SubForm.PAGE.InitGlobals(
          "Currency Code", AllowVATDifference, AllowVATDifference,
          "Prices Including VAT", AllowInvDisc, "VAT Base Discount %");
        // NAVCZ
        CurrPage.SubForm.PAGE.SetCurrencyFactor("Currency Factor");
        if "Currency Factor" <> "VAT Currency Factor" then
            CurrPage.SubForm.PAGE.SetVATCurrencyFactor("VAT Currency Factor");
        // NAVCZ
    end;

    local procedure UpdateTotalAmount()
    var
        SaveTotalAmount: Decimal;
    begin
        CheckAllowInvDisc;
        if "Prices Including VAT" then begin
            SaveTotalAmount := TotalAmount1;
            UpdateInvDiscAmount;
            TotalAmount1 := SaveTotalAmount;
        end;

        with TotalPurchLine do
            "Inv. Discount Amount" := "Line Amount" - TotalAmount1;
        UpdateInvDiscAmount;
    end;

    local procedure UpdateInvDiscAmount()
    var
        InvDiscBaseAmount: Decimal;
    begin
        CheckAllowInvDisc;
        InvDiscBaseAmount := TempVATAmountLine.GetTotalInvDiscBaseAmount(false, "Currency Code");
        if InvDiscBaseAmount = 0 then
            Error(Text003, TempVATAmountLine.FieldCaption("Inv. Disc. Base Amount"));

        if TotalPurchLine."Inv. Discount Amount" / InvDiscBaseAmount > 1 then
            Error(
              Text004,
              TotalPurchLine.FieldCaption("Inv. Discount Amount"),
              TempVATAmountLine.FieldCaption("Inv. Disc. Base Amount"));

        TempVATAmountLine.SetInvoiceDiscountAmount(
          TotalPurchLine."Inv. Discount Amount", "Currency Code", "Prices Including VAT", "VAT Base Discount %");
        TempVATAmountLine.ModifyAll("Modified (LCY)", false); // NAVCZ
        CurrPage.SubForm.PAGE.SetTempVATAmountLine(TempVATAmountLine);
        UpdateHeaderInfo;

        "Invoice Discount Calculation" := "Invoice Discount Calculation"::Amount;
        "Invoice Discount Value" := TotalPurchLine."Inv. Discount Amount";
        Modify;
        UpdateVATOnPurchLines;
    end;

    local procedure GetCaptionClass(FieldCaption: Text[100]; ReverseCaption: Boolean): Text[80]
    begin
        if "Prices Including VAT" xor ReverseCaption then
            exit('2,1,' + FieldCaption);

        exit('2,0,' + FieldCaption);
    end;

    procedure UpdateVATOnPurchLines()
    var
        PurchLine: Record "Purchase Line";
    begin
        GetVATSpecification;
        if TempVATAmountLine.GetAnyLineModified then begin
            PurchLine.SetPurchHeader(Rec); // NAVCZ
            PurchLine.UpdateVATOnLines(0, Rec, PurchLine, TempVATAmountLine);
            PurchLine.UpdateVATOnLines(1, Rec, PurchLine, TempVATAmountLine);
        end;
        PrevNo := '';
    end;

    local procedure VendInvDiscRecExists(InvDiscCode: Code[20]): Boolean
    var
        VendInvDisc: Record "Vendor Invoice Disc.";
    begin
        VendInvDisc.SetRange(Code, InvDiscCode);
        exit(VendInvDisc.FindFirst);
    end;

    local procedure CheckAllowInvDisc()
    begin
        if not AllowInvDisc then
            Error(Text005, "Invoice Disc. Code");
    end;

    local procedure CalculateTotals()
    var
        PurchLine: Record "Purchase Line";
        TempPurchLine: Record "Purchase Line" temporary;
    begin
        Clear(PurchLine);
        Clear(TotalPurchLine);
        Clear(TotalPurchLineLCY);
        Clear(PurchPost);

        PurchPost.GetPurchLines(Rec, TempPurchLine, 0);
        Clear(PurchPost);
        PurchPost.SumPurchLinesTemp(
          Rec, TempPurchLine, 0, TotalPurchLine, TotalPurchLineLCY, VATAmount, VATAmountText);

        if "Prices Including VAT" then begin
            TotalAmount2 := TotalPurchLine.Amount;
            TotalAmount1 := TotalAmount2 + VATAmount;
            TotalPurchLine."Line Amount" := TotalAmount1 + TotalPurchLine."Inv. Discount Amount";
        end else begin
            TotalAmount1 := TotalPurchLine.Amount;
            TotalAmount2 := TotalPurchLine."Amount Including VAT";
        end;

        if Vend.Get("Pay-to Vendor No.") then
            Vend.CalcFields("Balance (LCY)")
        else
            Clear(Vend);

        PurchLine.CalcVATAmountLines(0, Rec, TempPurchLine, TempVATAmountLine);
        TempVATAmountLine.ModifyAll(Modified, false);
        SetVATSpecification;

        OnAfterCalculateTotals(Rec, TotalPurchLine, TotalPurchLineLCY, TempVATAmountLine, TotalAmount1, TotalAmount2);
    end;

    local procedure VATLinesDrillDown(var VATAmountLine: Record "VAT Amount Line"; ThisTabAllowsVATEditing: Boolean)
    begin
        // NAVCZ
        Clear(VATAmountLines);
        VATAmountLines.SetTempVATAmountLine(VATAmountLine);
        VATAmountLines.InitGlobals(
          "Currency Code", AllowVATDifference, AllowVATDifference and ThisTabAllowsVATEditing,
          "Prices Including VAT", AllowInvDisc, "VAT Base Discount %");
        VATAmountLines.SetCurrencyFactor("Currency Factor");
        if "Currency Factor" <> "VAT Currency Factor" then
            VATAmountLines.SetVATCurrencyFactor("VAT Currency Factor");
        VATAmountLines.RunModal;
        VATAmountLines.GetTempVATAmountLine(VATAmountLine);
        // NAVCZ
    end;

    local procedure SumVATLinesAll()
    begin
        // NAVCZ
        TempVATAmountLineTot.Reset();
        TempVATAmountLineTot.DeleteAll();
        Clear(TempVATAmountLineTot);

        SumVATLinesTo(TempVATAmountLine);
        SumVATLinesTo(TempVATAmountLinePrep);
        // NAVCZ
    end;

    local procedure SumVATLinesTo(var VATAmountLine: Record "VAT Amount Line")
    begin
        // NAVCZ
        with VATAmountLine do begin
            if FindSet then
                repeat
                    TempVATAmountLineTot := VATAmountLine;
                    TempVATAmountLineTot.Positive := true;
                    if not TempVATAmountLineTot.Find then begin
                        TempVATAmountLineTot := VATAmountLine;
                        TempVATAmountLineTot.Positive := true;
                        TempVATAmountLineTot."Line Amount" := 0;
                        TempVATAmountLineTot.Insert();
                    end else begin
                        TempVATAmountLineTot."VAT Base" += "VAT Base";
                        TempVATAmountLineTot."VAT Amount" += "VAT Amount";
                        TempVATAmountLineTot."Amount Including VAT" += "Amount Including VAT";
                        TempVATAmountLineTot."Calculated VAT Amount" += "Calculated VAT Amount";
                        TempVATAmountLineTot."VAT Difference" += "VAT Difference";
                        TempVATAmountLineTot."Ext. VAT Base (LCY)" += "Ext. VAT Base (LCY)";
                        TempVATAmountLineTot."Ext. VAT Amount (LCY)" += "Ext. VAT Amount (LCY)";
                        TempVATAmountLineTot."Ext.Amount Including VAT (LCY)" += "Ext.Amount Including VAT (LCY)";
                        TempVATAmountLineTot."Ext. VAT Difference (LCY)" += "Ext. VAT Difference (LCY)";
                        TempVATAmountLineTot."Ext. Calc. VAT Amount (LCY)" += "Ext. Calc. VAT Amount (LCY)";
                        TempVATAmountLineTot."VAT Base (LCY)" += "VAT Base (LCY)";
                        TempVATAmountLineTot."VAT Amount (LCY)" += "VAT Amount (LCY)";
                        TempVATAmountLineTot."Amount Including VAT (LCY)" += "Amount Including VAT (LCY)";
                        TempVATAmountLineTot."Calculated VAT Amount (LCY)" += "Calculated VAT Amount (LCY)";
                        TempVATAmountLineTot.Modify();
                    end;
                until Next = 0;
        end;
        // NAVCZ
    end;

    local procedure SumTotalVATLines(var VATAmountLine: Record "VAT Amount Line"; var AmountIncVAT: Decimal; var VATAmount: Decimal; var VATBaseAmount: Decimal)
    begin
        // NAVCZ
        Clear(AmountIncVAT);
        Clear(VATAmount);
        Clear(VATBaseAmount);

        if VATAmountLine.FindSet then
            repeat
                AmountIncVAT += VATAmountLine."Amount Including VAT";
                VATAmount += VATAmountLine."VAT Amount";
                VATBaseAmount += VATAmountLine."VAT Base";
            until VATAmountLine.Next = 0;
        // NAVCZ
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateTotals(var PurchHeader: Record "Purchase Header"; var TotalPurchLine: Record "Purchase Line"; var TotalPurchLineLCY: Record "Purchase Line"; var TempVATAmountLine: Record "VAT Amount Line" temporary; var TotalAmt1: Decimal; var TotalAmt2: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterUpdateHeaderInfo()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenPageOnBeforeSetEditable(var AllowInvDisc: Boolean; var AllowVATDifference: Boolean; PurchaseHeader: Record "Purchase Header")
    begin
    end;
}

