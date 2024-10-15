page 3010835 "LSV Journal Line List"
{
    Caption = 'LSV Journal Line List';
    Editable = false;
    PageType = List;
    SourceTable = "LSV Journal Line";

    layout
    {
        area(content)
        {
            repeater(Control1150000)
            {
                ShowCaption = false;
                field("LSV Journal No."; "LSV Journal No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the journal number that identifies the collection uniquely.';
                }
                field("Line No."; "Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the line number of the LSV journal line.';
                }
                field("Customer No."; "Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer that the LSV journal line applies to.';
                }
                field("Collection Amount"; "Collection Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount for the entries for the collection.';
                }
                field(Name; Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the customer that the LSV journal line applies to.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code for the collection entries.';
                }
                field("Applies-to Doc. No."; "Applies-to Doc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Document No. of the customer ledger entry the LSV journal line is related to.';
                }
                field("Cust. Ledg. Entry No."; "Cust. Ledg. Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Entry No. of the customer ledger entry the LSV journal line is related to.';
                }
                field("LSV Status"; "LSV Status")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the LSV journal line.';
                }
                field("Remaining Amount"; "Remaining Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the remaining amount for the current LSV journal line.';
                }
                field("Pmt. Discount"; "Pmt. Discount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sum of the payment discount amounts granted on the selected LSV journal line.';
                }
                field("Last Modified By"; "Last Modified By")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the user that changed an entry in the LSV journal.';
                }
            }
        }
    }

    actions
    {
    }
}

