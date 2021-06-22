page 487 "Vend. Stats. by Curr. Lines"
{
    Caption = 'Lines';
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = Currency;
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a currency code that you can select. The code must comply with ISO 4217.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a text to describe the currency code.';
                }
                field("Vendor Balance"; "Vendor Balance")
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = Code;
                    AutoFormatType = 1;
                    Caption = 'Balance';
                    ToolTip = 'Specifies the payment amount that you owe the vendor for completed purchases.';
                }
                field("Vendor Outstanding Orders"; "Vendor Outstanding Orders")
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = Code;
                    AutoFormatType = 1;
                    Caption = 'Outstanding Orders';
                    ToolTip = 'Specifies the number of orders for which payment has not been made.';
                }
                field("Vendor Amt. Rcd. Not Invoiced"; "Vendor Amt. Rcd. Not Invoiced")
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = Code;
                    AutoFormatType = 1;
                    Caption = 'Shipped Not Invoiced';
                    ToolTip = 'Specifies the number of orders that are shipped but not invoiced.';
                }
                field(TotalAmount; TotalAmount)
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = Code;
                    AutoFormatType = 1;
                    Caption = 'Total';
                    ToolTip = 'Specifies the total amount less any invoice discount amount and excluding VAT for the purchase document.';
                }
                field("Vendor Balance Due"; "Vendor Balance Due")
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = Code;
                    AutoFormatType = 1;
                    Caption = 'Balance Due';
                    ToolTip = 'Specifies the payment amount that you owe the vendor for completed purchases where the payment date is exceeded.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        CalcFields(
          "Vendor Balance", "Vendor Balance Due",
          "Vendor Outstanding Orders", "Vendor Amt. Rcd. Not Invoiced");
        TotalAmount := "Vendor Balance" + "Vendor Outstanding Orders" + "Vendor Amt. Rcd. Not Invoiced";
    end;

    trigger OnOpenPage()
    begin
        Code := '';
        Insert;
        if Currency.FindSet then
            repeat
                Rec := Currency;
                Insert;
            until Currency.Next = 0;

        SetRange("Vendor Ledg. Entries in Filter", true);
    end;

    var
        Currency: Record Currency;
        TotalAmount: Decimal;
}

