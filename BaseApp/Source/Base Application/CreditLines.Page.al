page 31053 "Credit Lines"
{
    Caption = 'Credit Lines';
    PageType = List;
    SourceTable = "Credit Line";

    layout
    {
        area(content)
        {
            repeater(Control1220012)
            {
                Editable = false;
                ShowCaption = false;
                field("Credit No."; "Credit No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies number of credit ccard.';
                }
                field("Source Type"; "Source Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of source (customer or vendor).';
                }
                field("Source No."; "Source No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of customer or vendor.';
                }
                field("Source Entry No."; "Source Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of customer''s or vendor''s entries.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the posting of the credit card will be recorded.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document type of the customer or vendor ledger entry.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of customer''s or vendor''s document.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies description for credit.';
                }
                field("Variable Symbol"; "Variable Symbol")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the detail information for advance payment.';
                }
                field("Ledg. Entry Original Amount"; "Ledg. Entry Original Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the original amount of document.';
                }
                field("Ledg. Entry Remaining Amount"; "Ledg. Entry Remaining Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount which can be counted.';
                }
                field("Ledg. Entry Original Amt.(LCY)"; "Ledg. Entry Original Amt.(LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the original amount of document. The amount is in the local currency.';
                }
            }
        }
    }

    actions
    {
    }
}

