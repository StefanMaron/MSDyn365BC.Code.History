page 28080 "Posted Purch. Tax Cr. Memos"
{
    Caption = 'Posted Purch. Tax Cr. Memos';
    Editable = false;
    PageType = List;
    SourceTable = "Purch. Tax Cr. Memo Hdr.";

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
                field("Pay-to Vendor No."; "Pay-to Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor.';
                }
                field("Pay-to Name"; "Pay-to Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the vendor.';
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
                    ToolTip = 'Specifies the value on the original document.';
                }
                field("Amount Including VAT"; "Amount Including VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value on the original document.';
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

