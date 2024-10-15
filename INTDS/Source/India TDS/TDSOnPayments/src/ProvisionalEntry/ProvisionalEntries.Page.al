page 18769 "Provisional Entries"
{
    Caption = 'Provisional Entries';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Provisional Entry";
    UsageCategory = Lists;
    ApplicationArea = Basic, Suite;
    layout
    {
        area(content)
        {
            repeater(Group)
            {
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
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code for the entry.';
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

    actions
    {
        area(Creation)
        {
            action(ReverseTransaction)
            {
                Caption = 'Reverse Transaction';
                Ellipsis = true;
                Image = ReverseRegister;
                Promoted = true;
                PromotedCategory = Process;
                ApplicationArea = Basic, Suite;
                ToolTip = 'Reverse a posted provisional ledger entry.';
                Scope = Repeater;

                trigger OnAction()
                var
                    ReversalEntry: Record "Reversal Entry";
                    ProvisionalEntry: Record "Provisional Entry";
                    MultiLinesErr: Label 'You cannot select multiple lines.';
                begin
                    CurrPage.SETSELECTIONFILTER(ProvisionalEntry);
                    IF ProvisionalEntry.COUNT > 1 THEN
                        ERROR(MultiLinesErr);
                    CLEAR(ReversalEntry);
                    IF Reversed THEN
                        ReversalEntry.AlreadyReversedEntry(CopyStr(TableCaption, 1, 50), "Entry No.");
                    IF "Journal Batch Name" = '' THEN
                        ReversalEntry.TestFieldError();
                    TESTFIELD("Transaction No.");
                    ReversalEntry.ReverseTransaction("Transaction No.");
                end;
            }
            action("Reverse Without TDS")
            {
                Caption = 'Reverse Without TDS';
                Image = Undo;
                Promoted = true;
                PromotedCategory = Process;
                ApplicationArea = Basic, Suite;
                ToolTip = 'Reverse a posted provisional ledger entry without TDS entry.';

                trigger OnAction()
                var
                    ReversalEntry: Record "Reversal Entry";
                    ProvisionalEntry: Record "Provisional Entry";
                    ProvisionalEntryHandler: Codeunit "Provisional Entry Handler";
                    MultiLinesErr: Label 'You cannot select multiple lines.';
                begin
                    CurrPage.SETSELECTIONFILTER(ProvisionalEntry);
                    IF ProvisionalEntry.COUNT > 1 THEN
                        ERROR(MultiLinesErr);
                    IF Reversed THEN
                        ReversalEntry.AlreadyReversedEntry(CopyStr(TableCaption, 1, 50), "Entry No.");
                    ProvisionalEntryHandler.ReverseProvisionalEntries("Transaction No.");
                end;
            }
            action(Navigate)
            {
                Caption = '&Navigate';
                Image = Navigate;
                ApplicationArea = Basic, Suite;
                ToolTip = 'Find all entries and documents that exist for the document and posting date on the selected entry or document.';

                Scope = Repeater;
                trigger OnAction()
                var
                    Navigate: Page Navigate;
                begin
                    Navigate.SetDoc("Posting Date", "Posted Document No.");
                    Navigate.Run();
                end;
            }
        }
    }
}