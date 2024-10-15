page 10040 "Sales Tax Lines Subform"
{
    Caption = 'Sales Tax Lines Subform';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPart;
    SourceTable = "Sales Tax Amount Line";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Tax Area Code"; "Tax Area Code")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies the tax area code used on the sales or purchase lines with this Tax Group Code.';
                }
                field("Tax Group Code"; "Tax Group Code")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies the tax group that is used to calculate and post sales tax.';
                }
                field("Tax Jurisdiction Code"; "Tax Jurisdiction Code")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies the tax jurisdiction that is used for the Tax Area Code field on the purchase or sales lines.';
                }
                field("Tax Type"; "Tax Type")
                {
                    ToolTip = 'Specifies the type of sales tax.';
                    Visible = false;
                }
                field("Tax %"; "Tax %")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies the tax percentage that was used on the sales tax amount lines with this combination of tax area code and tax group code.';
                }
                field("Line Amount"; "Line Amount")
                {
                    ApplicationArea = SalesTax;
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                    ToolTip = 'Specifies the net amount (excluding tax) for sales or purchase lines matching the combination of tax area code and tax group code.';
                }
                field("Tax Base Amount"; "Tax Base Amount")
                {
                    ApplicationArea = SalesTax;
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                    ToolTip = 'Specifies the net amount (excluding tax) for sales or purchase lines.';
                }
                field(Quantity; Quantity)
                {
                    ToolTip = 'Specifies the sum of quantities from sales or purchase lines matching the combination of Tax Area Code and Tax Group Code found on this line.';
                    Visible = false;
                }
                field("Tax Amount"; "Tax Amount")
                {
                    ApplicationArea = SalesTax;
                    DecimalPlaces = 2 : 5;
                    Editable = "Tax AmountEditable";
                    ToolTip = 'Specifies the sales tax calculated for this Sales Tax Amount Line.';

                    trigger OnValidate()
                    begin
                        if AllowVATDifference and not AllowVATDifferenceOnThisTab then
                            Error(Text000, FieldCaption("Tax Amount"));
                        "Amount Including Tax" := "Tax Amount" + "Tax Base Amount";

                        FormCheckVATDifference;
                        Modified := true;
                        Modify;
                    end;
                }
                field("Tax Difference"; "Tax Difference")
                {
                    DecimalPlaces = 2 : 5;
                    ToolTip = 'Specifies the difference for the sales tax amount that is used for tax calculations.';
                    Visible = false;
                }
                field("Amount Including Tax"; "Amount Including Tax")
                {
                    ApplicationArea = SalesTax;
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                    ToolTip = 'Specifies the sum of the Tax Base Amount field and the Tax Amount field.';

                    trigger OnValidate()
                    begin
                        FormCheckVATDifference;
                    end;
                }
                field("Expense/Capitalize"; "Expense/Capitalize")
                {
                    ApplicationArea = SalesTax;
                    Editable = false;
                    ToolTip = 'Specifies if the Tax Amount will be debited to an Expense or Capital account, rather than to a Payable or Receivable account.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        if FindFirst then
            exit(true);
    end;

    trigger OnInit()
    begin
        "Tax AmountEditable" := true;
    end;

    var
        Text000: Label '%1 can only be modified on the Invoicing tab.';
        Text001: Label 'The total %1 for a document must not exceed %2 = %3.';
        Currency: Record Currency;
        CurrencyCode: Code[10];
        AllowVATDifference: Boolean;
        AllowVATDifferenceOnThisTab: Boolean;
        PricesIncludingVAT: Boolean;
        AllowInvDisc: Boolean;
        VATBaseDiscPct: Decimal;
        [InDataSet]
        "Tax AmountEditable": Boolean;

    procedure SetTempTaxAmountLine(var NewSalesTaxLine: Record "Sales Tax Amount Line" temporary)
    begin
        DeleteAll;
        if NewSalesTaxLine.FindFirst then
            repeat
                Copy(NewSalesTaxLine);
                Insert;
            until NewSalesTaxLine.Next = 0;
        CurrPage.Update;
    end;

    procedure GetTempTaxAmountLine(var NewSalesTaxLine: Record "Sales Tax Amount Line" temporary)
    begin
        NewSalesTaxLine.DeleteAll;
        if FindFirst then
            repeat
                NewSalesTaxLine.Copy(Rec);
                NewSalesTaxLine.Insert;
            until Next = 0;
    end;

    procedure InitGlobals(NewCurrencyCode: Code[10]; NewAllowVATDifference: Boolean; NewAllowVATDifferenceOnThisTab: Boolean; NewPricesIncludingVAT: Boolean; NewAllowInvDisc: Boolean; NewVATBaseDiscPct: Decimal)
    begin
        CurrencyCode := NewCurrencyCode;
        AllowVATDifference := NewAllowVATDifference;
        AllowVATDifferenceOnThisTab := NewAllowVATDifferenceOnThisTab;
        PricesIncludingVAT := NewPricesIncludingVAT;
        AllowInvDisc := NewAllowInvDisc;
        VATBaseDiscPct := NewVATBaseDiscPct;
        "Tax AmountEditable" := AllowVATDifference;
        if CurrencyCode = '' then
            Currency.InitRoundingPrecision
        else
            Currency.Get(CurrencyCode);
        CurrPage.Update;
    end;

    procedure FormCheckVATDifference()
    var
        TaxAmountLine2: Record "Sales Tax Amount Line";
        TotalVATDifference: Decimal;
    begin
        CheckTaxDifference(CurrencyCode, AllowVATDifference, PricesIncludingVAT);
        TaxAmountLine2 := Rec;
        TotalVATDifference := Abs("Tax Difference") - Abs(xRec."Tax Difference");
        if Find('-') then
            repeat
                TotalVATDifference := TotalVATDifference + Abs("Tax Difference");
            until Next = 0;
        Rec := TaxAmountLine2;
        if TotalVATDifference > Currency."Max. VAT Difference Allowed" then
            Error(
              Text001, FieldCaption("Tax Difference"),
              Currency.FieldCaption("Max. VAT Difference Allowed"), Currency."Max. VAT Difference Allowed");
    end;
}

