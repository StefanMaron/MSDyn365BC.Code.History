page 18770 "Apply Provisional Entries"
{
    Caption = 'Apply Provisional Entries';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Provisional Entry";
    SourceTableView = WHERE(Open = CONST(true));
    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Posted Document No."; "Posted Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number which identifies the posted transaction.';
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
                field("User ID"; "User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the user who created the document.';
                }
                field(Open; Open)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether this is an open entry or not.';
                }
                field("Purchase Invoice No."; "Purchase Invoice No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the invoice number to be applied.';
                }
                field("Applied User ID"; "Applied User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the user to be applied.';
                }
            }
        }
    }

    actions
    {
        area(creation)
        {
            action(Apply)
            {
                Caption = 'Apply';
                Image = ApplyEntries;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specify the entries for application.';
                trigger OnAction()
                begin
                    CheckMultiLineEntry(ProvisionalEntry);
                    Apply(GenJournalLine);
                end;
            }
            action(Unapply)
            {
                Caption = 'Unapply';
                Image = Undo;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specify the applied entries to be unapply';
                trigger OnAction()
                begin
                    CheckMultiLineEntry(ProvisionalEntry);
                    Unapply(GenJournalLine);
                end;
            }
            action(Navigate)
            {
                Caption = '&Navigate';
                Image = Navigate;
                ToolTip = 'View and navigate posted transactions.';
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                Scope = Repeater;
                ApplicationArea = Basic, Suite;
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
    procedure SetGenJnlLine(GenJournalLine1: Record "Gen. Journal Line")
    begin
        GenJournalLine := GenJournalLine1;
    end;

    local procedure CheckMultiLineEntry(ProvisionalEntry: Record "Provisional Entry")
    begin
        CurrPage.SetSelectionFilter(ProvisionalEntry);
        if ProvisionalEntry.Count > 1 then
            Error(MultiLinesErr);
    end;

    var
        GenJournalLine: Record "Gen. Journal Line";
        ProvisionalEntry: Record "Provisional Entry";
        MultiLinesErr: Label 'You cannot select multiple lines.';
}