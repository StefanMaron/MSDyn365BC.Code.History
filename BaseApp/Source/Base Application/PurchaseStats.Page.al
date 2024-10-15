page 10043 "Purchase Stats."
{
    Caption = 'Purchase Statistics';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Document;
    SourceTable = "Purchase Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("TotalPurchLine.""Line Amount"""; TotalPurchLine."Line Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text001, false);
                    Caption = 'Amount';
                    Editable = false;
                    ToolTip = 'Specifies the transaction amount.';
                }
                field("TotalPurchLine.""Inv. Discount Amount"""; TotalPurchLine."Inv. Discount Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Inv. Discount Amount';
                    Editable = false;
                    ToolTip = 'Specifies the invoice discount amount for the entire sales document. If the Calc. Inv. Discount field in the Purchases & Payables Setup window is selected, the discount is automatically calculated.';

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
                    Editable = false;
                    ToolTip = 'Specifies the total amount less any invoice discount amount and exclusive of VAT for the posted document.';

                    trigger OnValidate()
                    begin
                        UpdateTotalAmount;
                    end;
                }
                field(TaxAmount; TaxAmount)
                {
                    ApplicationArea = SalesTax;
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Tax Amount';
                    Editable = false;
                    ToolTip = 'Specifies the tax amount.';
                }
                field(TotalAmount2; TotalAmount2)
                {
                    ApplicationArea = SalesTax;
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text002, true);
                    Caption = 'Total Incl. Tax';
                    Editable = false;
                    ToolTip = 'Specifies the total amount, including tax, that has been posted as invoiced.';
                }
                field("TotalPurchLineLCY.Amount"; TotalPurchLineLCY.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Purchase ($)';
                    Editable = false;
                    ToolTip = 'Specifies the purchase amount.';
                }
                field("TotalPurchLine.Quantity"; TotalPurchLine.Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the item quantity.';
                }
                field("TotalPurchLine.""Units per Parcel"""; TotalPurchLine."Units per Parcel")
                {
                    Caption = 'Parcels';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the number of parcels on the document.';
                }
                field("TotalPurchLine.""Net Weight"""; TotalPurchLine."Net Weight")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Net Weight';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the net weight of items on the sales order.';
                }
                field("TotalPurchLine.""Gross Weight"""; TotalPurchLine."Gross Weight")
                {
                    Caption = 'Gross Weight';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the gross weight of items on the document.';
                }
                field("TotalPurchLine.""Unit Volume"""; TotalPurchLine."Unit Volume")
                {
                    Caption = 'Volume';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the volume of the invoiced items.';
                }
                label(BreakdownTitle)
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = Format(BreakdownTitle);
                    Editable = false;
                }
                field("BreakdownAmt[1]"; BreakdownAmt[1])
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    CaptionClass = Format(BreakdownLabel[1]);
                    Editable = false;
                    ShowCaption = false;
                }
                field("BreakdownAmt[2]"; BreakdownAmt[2])
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    CaptionClass = Format(BreakdownLabel[2]);
                    Editable = false;
                    ShowCaption = false;
                }
                field("BreakdownAmt[3]"; BreakdownAmt[3])
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    CaptionClass = Format(BreakdownLabel[3]);
                    Editable = false;
                    ShowCaption = false;
                }
                field("BreakdownAmt[4]"; BreakdownAmt[4])
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    CaptionClass = Format(BreakdownLabel[4]);
                    Editable = false;
                    ShowCaption = false;
                }
            }
            part(SubForm; "Sales Tax Lines Subform")
            {
                ApplicationArea = Basic, Suite;
            }
            group(Vendor)
            {
                Caption = 'Vendor';
                field("Vend.""Balance (LCY)"""; Vend."Balance (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Balance ($)';
                    ToolTip = 'Specifies the customer''s balance. ';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        PurchLine: Record "Purchase Line";
        TempPurchLine: Record "Purchase Line" temporary;
        TempSalesTaxAmtLine: Record "Sales Tax Amount Line" temporary;
    begin
        CurrPage.Caption(StrSubstNo(Text000, "Document Type"));
        if PrevNo = "No." then
            exit;
        PrevNo := "No.";
        FilterGroup(2);
        SetRange("No.", PrevNo);
        FilterGroup(0);
        Clear(PurchLine);
        Clear(TotalPurchLine);
        Clear(TotalPurchLineLCY);
        Clear(PurchPost);
        Clear(TaxAmount);

        SalesTaxCalculate.StartSalesTaxCalculation;
        PurchLine.SetRange("Document Type", "Document Type");
        PurchLine.SetRange("Document No.", "No.");
        PurchLine.SetFilter(Type, '>0');
        PurchLine.SetFilter(Quantity, '<>0');
        if PurchLine.Find('-') then
            repeat
                TempPurchLine.Copy(PurchLine);
                TempPurchLine.Insert;
                if not TaxArea."Use External Tax Engine" then
                    SalesTaxCalculate.AddPurchLine(TempPurchLine);
            until PurchLine.Next = 0;
        TempSalesTaxLine.DeleteAll;
        if TaxArea."Use External Tax Engine" then
            SalesTaxCalculate.CallExternalTaxEngineForPurch(Rec, true)
        else
            SalesTaxCalculate.EndSalesTaxCalculation("Posting Date");
        SalesTaxCalculate.GetSalesTaxAmountLineTable(TempSalesTaxLine);

        SalesTaxCalculate.DistTaxOverPurchLines(TempPurchLine);
        PurchPost.SumPurchLinesTemp(
          Rec, TempPurchLine, 0, TotalPurchLine, TotalPurchLineLCY, TaxAmount, TaxAmountText);

        if "Prices Including VAT" then begin
            TotalAmount2 := TotalPurchLine.Amount;
            TotalAmount1 := TotalPurchLine."Line Amount" - TotalPurchLine."Inv. Discount Amount";
        end else begin
            TotalAmount1 := TotalPurchLine.Amount;
            TotalAmount2 := TotalPurchLine."Amount Including VAT";
        end;

        SalesTaxCalculate.GetSummarizedSalesTaxTable(TempSalesTaxAmtLine);
        UpdateTaxBreakdown(TempSalesTaxAmtLine, true);

        if Vend.Get("Pay-to Vendor No.") then
            Vend.CalcFields("Balance (LCY)")
        else
            Clear(Vend);

        TempSalesTaxLine.ModifyAll(Modified, false);
        SetVATSpecification;

        GetVATSpecification;
    end;

    trigger OnOpenPage()
    begin
        PurchSetup.Get;
        AllowInvDisc :=
          not (PurchSetup."Calc. Inv. Discount" and VendInvDiscRecExists("Invoice Disc. Code"));
        AllowVATDifference :=
          PurchSetup."Allow VAT Difference" and
          not ("Document Type" in ["Document Type"::Quote, "Document Type"::"Blanket Order"]);
        CurrPage.Editable := AllowVATDifference or AllowInvDisc;
        TaxArea.Get("Tax Area Code");
        SetVATSpecification;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        GetVATSpecification;
        if TempSalesTaxLine.GetAnyLineModified then
            UpdateVATOnPurchLines;
        exit(true);
    end;

    var
        Text000: Label 'Purchase %1 Statistics';
        Text001: Label 'Amount';
        Text002: Label 'Total';
        Text003: Label '%1 must not be 0.';
        Text004: Label '%1 must not be greater than %2.';
        Text005: Label 'You cannot change the invoice discount because there is a %1 record for %2 %3.';
        TotalPurchLine: Record "Purchase Line";
        TotalPurchLineLCY: Record "Purchase Line";
        Vend: Record Vendor;
        TempSalesTaxLine: Record "Sales Tax Amount Line" temporary;
        PurchSetup: Record "Purchases & Payables Setup";
        TaxArea: Record "Tax Area";
        SalesTaxDifference: Record "Sales Tax Amount Difference";
        PurchPost: Codeunit "Purch.-Post";
        SalesTaxCalculate: Codeunit "Sales Tax Calculate";
        TotalAmount1: Decimal;
        TotalAmount2: Decimal;
        TaxAmount: Decimal;
        TaxAmountText: Text[30];
        PrevNo: Code[20];
        AllowInvDisc: Boolean;
        AllowVATDifference: Boolean;
        BreakdownTitle: Text[35];
        BreakdownLabel: array[4] of Text[30];
        BreakdownAmt: array[4] of Decimal;
        BrkIdx: Integer;
        Text006: Label 'Tax Breakdown:';
        Text007: Label 'Sales Tax Breakdown:';
        Text008: Label 'Other Taxes';

    local procedure UpdateHeaderInfo()
    var
        CurrExchRate: Record "Currency Exchange Rate";
        UseDate: Date;
    begin
        TotalAmount1 :=
          TotalPurchLine."Line Amount" - TotalPurchLine."Inv. Discount Amount";
        TaxAmount := TempSalesTaxLine.GetTotalTaxAmountFCY;
        if "Prices Including VAT" then
            TotalAmount2 := TotalPurchLine.Amount
        else
            TotalAmount2 := TotalAmount1 + TaxAmount;

        if "Prices Including VAT" then
            TotalPurchLineLCY.Amount := TotalAmount2
        else
            TotalPurchLineLCY.Amount := TotalAmount1;
        if "Currency Code" <> '' then begin
            if "Document Type" = "Document Type"::Quote then
                UseDate := WorkDate
            else
                UseDate := "Posting Date";
            TotalPurchLineLCY.Amount :=
              CurrExchRate.ExchangeAmtFCYToLCY(
                UseDate, "Currency Code", TotalPurchLineLCY.Amount, "Currency Factor");
        end;
    end;

    local procedure GetVATSpecification()
    begin
        CurrPage.SubForm.PAGE.GetTempTaxAmountLine(TempSalesTaxLine);
        UpdateHeaderInfo;
    end;

    local procedure SetVATSpecification()
    begin
        CurrPage.SubForm.PAGE.SetTempTaxAmountLine(TempSalesTaxLine);
        CurrPage.SubForm.PAGE.InitGlobals(
          "Currency Code", AllowVATDifference, AllowVATDifference,
          "Prices Including VAT", AllowInvDisc, "VAT Base Discount %");
    end;

    local procedure UpdateTotalAmount()
    begin
        CheckAllowInvDisc;
        with TotalPurchLine do
            "Inv. Discount Amount" := "Line Amount" - TotalAmount1;
        UpdateInvDiscAmount;
    end;

    local procedure UpdateInvDiscAmount()
    var
        InvDiscBaseAmount: Decimal;
    begin
        CheckAllowInvDisc;
        InvDiscBaseAmount := TempSalesTaxLine.GetTotalInvDiscBaseAmount(false, "Currency Code");
        if InvDiscBaseAmount = 0 then
            Error(Text003, TempSalesTaxLine.FieldCaption("Inv. Disc. Base Amount"));

        if TotalPurchLine."Inv. Discount Amount" / InvDiscBaseAmount > 1 then
            Error(
              Text004,
              TotalPurchLine.FieldCaption("Inv. Discount Amount"),
              TempSalesTaxLine.FieldCaption("Inv. Disc. Base Amount"));

        TempSalesTaxLine.SetInvoiceDiscountAmount(
          TotalPurchLine."Inv. Discount Amount", "Currency Code", "Prices Including VAT", "VAT Base Discount %");
        CurrPage.SubForm.PAGE.SetTempTaxAmountLine(TempSalesTaxLine);
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

    local procedure UpdateVATOnPurchLines()
    var
        PurchLine: Record "Purchase Line";
    begin
        GetVATSpecification;

        PurchLine.Reset;
        PurchLine.SetRange("Document Type", "Document Type");
        PurchLine.SetRange("Document No.", "No.");
        PurchLine.FindFirst;

        if TempSalesTaxLine.GetAnyLineModified then begin
            SalesTaxCalculate.StartSalesTaxCalculation;
            SalesTaxCalculate.PutSalesTaxAmountLineTable(
              TempSalesTaxLine,
              SalesTaxDifference."Document Product Area"::Purchase,
              "Document Type", "No.");
            SalesTaxCalculate.DistTaxOverPurchLines(PurchLine);
            SalesTaxCalculate.SaveTaxDifferences;
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
    var
        VendInvDisc: Record "Vendor Invoice Disc.";
    begin
        if not AllowInvDisc then
            Error(
              Text005,
              VendInvDisc.TableCaption, FieldCaption("Invoice Disc. Code"), "Invoice Disc. Code");
    end;

    local procedure UpdateTaxBreakdown(var TempSalesTaxAmtLine: Record "Sales Tax Amount Line" temporary; UpdateTaxAmount: Boolean)
    var
        PrevPrintOrder: Integer;
        PrevTaxPercent: Decimal;
    begin
        Clear(BreakdownLabel);
        Clear(BreakdownAmt);
        BrkIdx := 0;
        PrevPrintOrder := 0;
        PrevTaxPercent := 0;
        if TaxArea."Country/Region" = TaxArea."Country/Region"::CA then
            BreakdownTitle := Text006
        else
            BreakdownTitle := Text007;
        with TempSalesTaxAmtLine do begin
            Reset;
            SetCurrentKey("Print Order", "Tax Area Code for Key", "Tax Jurisdiction Code");
            if Find('-') then
                repeat
                    if ("Print Order" = 0) or
                       ("Print Order" <> PrevPrintOrder) or
                       ("Tax %" <> PrevTaxPercent)
                    then begin
                        BrkIdx := BrkIdx + 1;
                        if BrkIdx > ArrayLen(BreakdownAmt) then begin
                            BrkIdx := BrkIdx - 1;
                            BreakdownLabel[BrkIdx] := Text008;
                        end else
                            BreakdownLabel[BrkIdx] := StrSubstNo("Print Description", "Tax %");
                    end;
                    BreakdownAmt[BrkIdx] := BreakdownAmt[BrkIdx] + "Tax Amount";
                    if UpdateTaxAmount then
                        TaxAmount := TaxAmount + "Tax Amount"
                    else
                        BreakdownAmt[BrkIdx] := BreakdownAmt[BrkIdx] + "Tax Difference";
                until Next = 0;
        end;
    end;
}

