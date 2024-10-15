page 397 "Sales Invoice Statistics"
{
    Caption = 'Sales Invoice Statistics';
    Editable = false;
    LinksAllowed = false;
    PageType = ListPlus;
    SourceTable = "Sales Invoice Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("CustAmount + InvDiscAmount + PmtDiscAmount"; CustAmount + InvDiscAmount + PmtDiscAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Amount';
                    ToolTip = 'Specifies the net amount of all the lines in the sales document.';
                }
                field(InvDiscAmount; InvDiscAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Inv. Discount Amount';
                    ToolTip = 'Specifies the invoice discount amount for the sales document.';
                }
                field(PmtDiscAmount; PmtDiscAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Pmt. Discount Amount';
                    Editable = true;
                    ToolTip = 'Specifies the payment discount amount that you have granted to customers. ';
                }
                field(CustAmount; CustAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Total';
                    ToolTip = 'Specifies the total amount, less any invoice discount amount, and excluding VAT for the sales document.';
                }
                field(VATAmount; VATAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = Format(VATAmountText);
                    Caption = 'VAT Amount';
                    ToolTip = 'Specifies the total VAT amount that has been calculated for all the lines in the sales document.';
                }
                field(AmountInclVAT; AmountInclVAT)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Total Incl. VAT';
                    ToolTip = 'Specifies the total amount, including VAT, that will be posted to the customer''s account for all the lines in the sales document.';
                }
                field(AmountLCY; AmountLCY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Sales (LCY)';
                    ToolTip = 'Specifies your total sales turnover in the fiscal year.';
                }
                field(ProfitLCY; ProfitLCY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Original Profit (LCY)';
                    ToolTip = 'Specifies the original profit that was associated with the sales when they were originally posted.';
                }
                field(AdjustedProfitLCY; AdjProfitLCY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Adjusted Profit (LCY)';
                    ToolTip = 'Specifies the profit, taking into consideration changes in the purchase prices of the goods.';
                }
                field(ProfitPct; ProfitPct)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Original Profit %';
                    DecimalPlaces = 1 : 1;
                    ToolTip = 'Specifies the original percentage of profit that was associated with the sales when they were originally posted.';
                }
                field(AdjProfitPct; AdjProfitPct)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Adjusted Profit %';
                    DecimalPlaces = 1 : 1;
                    ToolTip = 'Specifies the percentage of profit for all sales, including changes that occurred in the purchase prices of the goods.';
                }
                field(LineQty; LineQty)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total quantity of G/L account entries, items and/or resources in the sales document.';
                }
                field(TotalParcels; TotalParcels)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Parcels';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total number of parcels in the sales document.';
                }
                field(TotalNetWeight; TotalNetWeight)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Net Weight';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total net weight of the items in the sales document.';
                }
                field(TotalGrossWeight; TotalGrossWeight)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Gross Weight';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total gross weight of the items in the sales document.';
                }
                field(TotalVolume; TotalVolume)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Volume';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total volume of the items in the sales document.';
                }
                field(CostLCY; CostLCY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Original Cost (LCY)';
                    ToolTip = 'Specifies the total cost, in LCY, of the G/L account entries, items and/or resources in the sales document.';
                }
                field(AdjustedCostLCY; TotalAdjCostLCY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Adjusted Cost (LCY)';
                    ToolTip = 'Specifies the total cost, in LCY, of the items in the posted sales invoice, adjusted for any changes in the original costs of these items.';
                }
                field("TotalAdjCostLCY - CostLCY"; TotalAdjCostLCY - CostLCY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Cost Adjmt. Amount (LCY)';
                    ToolTip = 'Specifies the difference between the original cost and the total adjusted cost of the items in the posted sales invoice.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        LookupAdjmtValueEntries;
                    end;
                }
            }
            part(Subform; "VAT Specification Subform")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
            }
            group(Customer)
            {
                Caption = 'Customer';
                field("Cust.""Balance (LCY)"""; Cust."Balance (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Balance (LCY)';
                    ToolTip = 'Specifies the balance in LCY on the customer''s account.';
                }
                field("Cust.""Credit Limit (LCY)"""; Cust."Credit Limit (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Credit Limit (LCY)';
                    ToolTip = 'Specifies information about the credit limit in LCY, for the customer who you created and posted this sales invoice for. ';
                }
                field(CreditLimitLCYExpendedPct; CreditLimitLCYExpendedPct)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Expended % of Credit Limit (LCY)';
                    ExtendedDatatype = Ratio;
                    ToolTip = 'Specifies the expended percentage of the credit limit in (LCY).';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        CostCalcMgt: Codeunit "Cost Calculation Management";
    begin
        ClearAll;

        if "Currency Code" = '' then
            currency.InitRoundingPrecision
        else
            currency.Get("Currency Code");

        SalesInvLine.SetRange("Document No.", "No.");
        if SalesInvLine.Find('-') then
            repeat
                CustAmount := CustAmount + SalesInvLine.Amount;
                AmountInclVAT := AmountInclVAT + SalesInvLine."Amount Including VAT";
                if "Prices Including VAT" then begin
                    InvDiscAmount := InvDiscAmount + SalesInvLine."Inv. Discount Amount" /
                      (1 + (SalesInvLine."VAT %" + SalesInvLine."EC %") / 100);
                    PmtDiscAmount := PmtDiscAmount + SalesInvLine."Pmt. Discount Amount" /
                      (1 + (SalesInvLine."VAT %" + SalesInvLine."EC %") / 100)
                end else begin
                    InvDiscAmount := InvDiscAmount + SalesInvLine."Inv. Discount Amount";
                    PmtDiscAmount := PmtDiscAmount + SalesInvLine."Pmt. Discount Amount";
                end;
                CostLCY := CostLCY + (SalesInvLine.Quantity * SalesInvLine."Unit Cost (LCY)");
                LineQty := LineQty + SalesInvLine.Quantity;
                TotalNetWeight := TotalNetWeight + (SalesInvLine.Quantity * SalesInvLine."Net Weight");
                TotalGrossWeight := TotalGrossWeight + (SalesInvLine.Quantity * SalesInvLine."Gross Weight");
                TotalVolume := TotalVolume + (SalesInvLine.Quantity * SalesInvLine."Unit Volume");
                if SalesInvLine."Units per Parcel" > 0 then
                    TotalParcels := TotalParcels + Round(SalesInvLine.Quantity / SalesInvLine."Units per Parcel", 1, '>');
                if SalesInvLine."VAT %" <> VATPercentage then
                    if VATPercentage = 0 then
                        VATPercentage := SalesInvLine."VAT %" + SalesInvLine."EC %"
                    else
                        VATPercentage := -1;
                TotalAdjCostLCY :=
                  TotalAdjCostLCY + CostCalcMgt.CalcSalesInvLineCostLCY(SalesInvLine) +
                  CostCalcMgt.CalcSalesInvLineNonInvtblCostAmt(SalesInvLine);
            until SalesInvLine.Next = 0;
        VATAmount := AmountInclVAT - CustAmount;
        InvDiscAmount := Round(InvDiscAmount, currency."Amount Rounding Precision");

        if VATPercentage <= 0 then
            VATAmountText := Text000
        else
            VATAmountText := StrSubstNo(Text001, VATPercentage);

        if "Currency Code" = '' then
            AmountLCY := CustAmount
        else
            AmountLCY :=
              CurrExchRate.ExchangeAmtFCYToLCY(
                WorkDate, "Currency Code", CustAmount, "Currency Factor");

        CustLedgEntry.SetCurrentKey("Document No.");
        CustLedgEntry.SetRange("Document No.", "No.");
        CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice);
        CustLedgEntry.SetRange("Customer No.", "Bill-to Customer No.");
        if CustLedgEntry.FindFirst then
            AmountLCY := CustLedgEntry."Sales (LCY)";

        ProfitLCY := AmountLCY - CostLCY;
        if AmountLCY <> 0 then
            ProfitPct := Round(100 * ProfitLCY / AmountLCY, 0.1);

        AdjProfitLCY := AmountLCY - TotalAdjCostLCY;
        if AmountLCY <> 0 then
            AdjProfitPct := Round(100 * AdjProfitLCY / AmountLCY, 0.1);

        if Cust.Get("Bill-to Customer No.") then
            Cust.CalcFields("Balance (LCY)")
        else
            Clear(Cust);

        if Cust."Credit Limit (LCY)" = 0 then
            CreditLimitLCYExpendedPct := 0
        else
            CreditLimitLCYExpendedPct := Round(Cust."Balance (LCY)" / Cust."Credit Limit (LCY)" * 10000, 1);

        SalesInvLine.CalcVATAmountLines(Rec, TempVATAmountLine);
        CurrPage.Subform.PAGE.SetTempVATAmountLine(TempVATAmountLine);
        CurrPage.Subform.PAGE.InitGlobals("Currency Code", false, false, false, false, "VAT Base Discount %");
    end;

    var
        Text000: Label 'VAT Amount';
        Text001: Label '%1% VAT';
        CurrExchRate: Record "Currency Exchange Rate";
        SalesInvLine: Record "Sales Invoice Line";
        Cust: Record Customer;
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        currency: Record Currency;
        TotalAdjCostLCY: Decimal;
        CustAmount: Decimal;
        AmountInclVAT: Decimal;
        InvDiscAmount: Decimal;
        VATAmount: Decimal;
        CostLCY: Decimal;
        ProfitLCY: Decimal;
        ProfitPct: Decimal;
        AdjProfitLCY: Decimal;
        AdjProfitPct: Decimal;
        LineQty: Decimal;
        TotalNetWeight: Decimal;
        TotalGrossWeight: Decimal;
        TotalVolume: Decimal;
        TotalParcels: Decimal;
        AmountLCY: Decimal;
        CreditLimitLCYExpendedPct: Decimal;
        VATPercentage: Decimal;
        VATAmountText: Text[30];
        PmtDiscAmount: Decimal;
}

