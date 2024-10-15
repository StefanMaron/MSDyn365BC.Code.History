page 10882 "Payment Step Ledger List"
{
    Caption = 'Payment Step Ledger List';
    CardPageID = "Payment Step Ledger";
    Editable = false;
    PageType = List;
    SourceTable = "Payment Step Ledger";

    layout
    {
        area(content)
        {
            repeater(Control1120000)
            {
                ShowCaption = false;
                field("Payment Class"; "Payment Class")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment class.';
                }
                field(Line; Line)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ledger line''s entry number.';
                }
                field(Sign; Sign)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = ' Specifies if the posting will result in a debit or credit entry.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description to be used on the general ledger entry.';
                }
                field("Accounting Type"; "Accounting Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of account to post the entry to.';
                }
                field("Account Type"; "Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of account to post the entry to.';
                }
                field("Account No."; "Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account number to post the entry to.';
                }
                field("Customer Posting Group"; "Customer Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for the customer posting group used when the entry is posted.';
                }
                field("Vendor Posting Group"; "Vendor Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for the vendor posting group used when the entry is posted.';
                }
                field(Root; Root)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the root for the G/L accounts group used, when you have selected either G/L Account / Month, or G/L Account / Week.';
                }
                field("Detail Level"; "Detail Level")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how payment lines will be posted.';
                }
                field(Application; Application)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how to apply entries.';
                }
                field("Memorize Entry"; "Memorize Entry")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that entries created in this step will be memorized, so the next application can be performed against newly posted entries.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of document that will be assigned to the ledger entry.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the method to assign a document number to the ledger entry.';
                }
            }
        }
    }

    actions
    {
    }
}

