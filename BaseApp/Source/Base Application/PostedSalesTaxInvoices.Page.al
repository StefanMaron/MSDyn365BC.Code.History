page 28081 "Posted Sales Tax Invoices"
{
    Caption = 'Posted Sales Tax Invoices';
    Editable = false;
    PageType = List;
    SourceTable = "Sales Tax Invoice Header";

    layout
    {
        area(content)
        {
            repeater(Control1500000)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the document.';
                }
                field("Sell-to Customer No."; "Sell-to Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer.';
                }
                field("Sell-to Customer Name"; "Sell-to Customer Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the location from which the items were shipped.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code of the document.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sales tax invoice line amount that is on the sales tax invoice.';
                }
                field("Amount Including VAT"; "Amount Including VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sales tax invoice line amount including VAT.';
                }
                field("No. Printed"; "No. Printed")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how many times the document has been printed.';
                }
            }
        }
    }

    actions
    {
    }
}

