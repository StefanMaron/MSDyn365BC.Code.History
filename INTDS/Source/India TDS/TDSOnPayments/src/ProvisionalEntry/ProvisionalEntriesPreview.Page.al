page 18771 "Provisional Entries Preview"
{
    Caption = 'Provisional Entries Preview';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    UsageCategory = Lists;
    PageType = List;
    SourceTable = "Provisional Entry";
    SourceTableView = WHERE(Open = CONST(true));

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Journal Batch Name"; "Journal Batch Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the journal batch name on the ledger entry.';
                }
                field("Journal Template Name"; "Journal Template Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the journal template name on the ledger entry.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document type on the ledger entry.';
                }
                field("Posted Document No."; "Posted Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number which identifies the posted transaction.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the creation date of the ledger entry.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Party Type"; "Party Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the party type of the transaction.';
                }
                field("Party Code"; "Party Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the relevant party code of the transaction.';
                }
                field("Account Type"; "Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of account where the entry will be posted.';
                }
                field("Account No."; "Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account number where the entry will be posted.';
                }
                field("TDS Section Code"; "TDS Section Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the TDS Section code.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount of the transaction.';
                }
                field("Debit Amount"; "Debit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the debit amount of the transaction.';
                }
                field("Credit Amount"; "Credit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the credit amount of the transaction.';
                }
                field("Bal. Account Type"; "Bal. Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of account where the balancing entry will be posted.';
                }
                field("Bal. Account No."; "Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account number where the balancing entry will be posted.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of location where the entry is posted to.';
                }
                field("Externl Document No."; "Externl Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the external document no. of the transaction.';
                }
                field(Reversed; Reversed)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the posted entry is reversed.';
                }
                field("Original Invoice Posted"; "Original Invoice Posted")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the original invoice number.';
                }
                field("Applied Invoice No."; "Applied Invoice No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the applied invoice number.';
                }
                field("Original Invoice Reversed"; "Original Invoice Reversed")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the original invoice is reversed.';
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the user who created the document.';
                }
                field("Applied by Vendor Ledger Entry"; "Applied by Vendor Ledger Entry")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the applied vendor ledger entry number.';
                }
                field("Reversed After TDS Paid"; "Reversed After TDS Paid")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the entry is reversed after TDS payment.';
                }
                field(Open; Open)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether this is an open entry or not.';
                }
            }
        }
    }
}

