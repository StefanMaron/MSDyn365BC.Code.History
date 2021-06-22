page 401 "Purch. Credit Memo Statistics"
{
    Caption = 'Purch. Credit Memo Statistics';
    Editable = false;
    LinksAllowed = false;
    PageType = ListPlus;
    SourceTable = "Purch. Cr. Memo Hdr.";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("VendAmount + InvDiscAmount"; VendAmount + InvDiscAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Amount';
                    ToolTip = 'Specifies the net amount of all the lines in the purchase document.';
                }
                field(InvDiscAmount; InvDiscAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Inv. Discount Amount';
                    ToolTip = 'Specifies the invoice discount amount for the purchase document.';
                }
                field(VendAmount; VendAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Total';
                    ToolTip = 'Specifies the total amount, less any invoice discount amount, and excluding VAT for the purchase document.';
                }
                field(VATAmount; VATAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = Format(VATAmountText);
                    Caption = 'VAT Amount';
                    ToolTip = 'Specifies the total VAT amount that has been calculated for all the lines in the purchase document.';
                }
                field(AmountInclVAT; AmountInclVAT)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Total Incl. VAT';
                    ToolTip = 'Specifies the total amount, including VAT, that will be posted to the vendor''s account for all the lines in the purchase document.';
                }
                field(AmountLCY; AmountLCY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Purchase (LCY)';
                    ToolTip = 'Specifies your total purchases.';
                }
                field(LineQty; LineQty)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total quantity of G/L account entries, items and/or resources in the purchase document.';
                }
                field(TotalParcels; TotalParcels)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Parcels';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total number of parcels in the purchase document.';
                }
                field(TotalNetWeight; TotalNetWeight)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Net Weight';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total net weight of the items in the purchase document.';
                }
                field(TotalGrossWeight; TotalGrossWeight)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Gross Weight';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total gross weight of the items in the purchase document.';
                }
                field(TotalVolume; TotalVolume)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Volume';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total volume of the items in the purchase document.';
                }
            }
            part(SubForm; "VAT Specification Subform")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
            }
            group(Vendor)
            {
                Caption = 'Vendor';
                field("Vend.""Balance (LCY)"""; Vend."Balance (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Balance (LCY)';
                    ToolTip = 'Specifies the balance in LCY on the vendor''s account.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        ClearAll;

        if "Currency Code" = '' then
            Currency.InitRoundingPrecision
        else
            Currency.Get("Currency Code");

        PurchCrMemoLine.SetRange("Document No.", "No.");

        if PurchCrMemoLine.Find('-') then
            repeat
                VendAmount := VendAmount + PurchCrMemoLine.Amount;
                AmountInclVAT := AmountInclVAT + PurchCrMemoLine."Amount Including VAT";
                if "Prices Including VAT" then
                    InvDiscAmount := InvDiscAmount + PurchCrMemoLine."Inv. Discount Amount" / (1 + PurchCrMemoLine."VAT %" / 100)
                else
                    InvDiscAmount := InvDiscAmount + PurchCrMemoLine."Inv. Discount Amount";
                LineQty := LineQty + PurchCrMemoLine.Quantity;
                TotalNetWeight := TotalNetWeight + (PurchCrMemoLine.Quantity * PurchCrMemoLine."Net Weight");
                TotalGrossWeight := TotalGrossWeight + (PurchCrMemoLine.Quantity * PurchCrMemoLine."Gross Weight");
                TotalVolume := TotalVolume + (PurchCrMemoLine.Quantity * PurchCrMemoLine."Unit Volume");
                if PurchCrMemoLine."Units per Parcel" > 0 then
                    TotalParcels := TotalParcels + Round(PurchCrMemoLine.Quantity / PurchCrMemoLine."Units per Parcel", 1, '>');
                if PurchCrMemoLine."VAT %" <> VATPercentage then
                    if VATPercentage = 0 then
                        VATPercentage := PurchCrMemoLine."VAT %"
                    else
                        VATPercentage := -1;
            until PurchCrMemoLine.Next = 0;
        VATAmount := AmountInclVAT - VendAmount;
        InvDiscAmount := Round(InvDiscAmount, Currency."Amount Rounding Precision");

        if VATPercentage <= 0 then
            VATAmountText := Text000
        else
            VATAmountText := StrSubstNo(Text001, VATPercentage);

        if "Currency Code" = '' then
            AmountLCY := VendAmount
        else
            AmountLCY :=
              CurrExchRate.ExchangeAmtFCYToLCY(
                WorkDate, "Currency Code", VendAmount, "Currency Factor");

        VendLedgEntry.SetCurrentKey("Document No.");
        VendLedgEntry.SetRange("Document No.", "No.");
        VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::"Credit Memo");
        VendLedgEntry.SetRange("Vendor No.", "Pay-to Vendor No.");
        if VendLedgEntry.FindFirst then
            AmountLCY := VendLedgEntry."Purchase (LCY)";

        if not Vend.Get("Pay-to Vendor No.") then
            Clear(Vend);
        Vend.CalcFields("Balance (LCY)");

        PurchCrMemoLine.CalcVATAmountLines(Rec, TempVATAmountLine);
        CurrPage.SubForm.PAGE.SetTempVATAmountLine(TempVATAmountLine);
        CurrPage.SubForm.PAGE.InitGlobals("Currency Code", false, false, false, false, "VAT Base Discount %");
    end;

    var
        Text000: Label 'VAT Amount';
        Text001: Label '%1% VAT';
        CurrExchRate: Record "Currency Exchange Rate";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        Vend: Record Vendor;
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        Currency: Record Currency;
        VendAmount: Decimal;
        AmountInclVAT: Decimal;
        InvDiscAmount: Decimal;
        AmountLCY: Decimal;
        LineQty: Decimal;
        TotalNetWeight: Decimal;
        TotalGrossWeight: Decimal;
        TotalVolume: Decimal;
        TotalParcels: Decimal;
        VATAmount: Decimal;
        VATPercentage: Decimal;
        VATAmountText: Text[30];
}

