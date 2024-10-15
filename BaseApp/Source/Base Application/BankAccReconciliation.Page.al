page 379 "Bank Acc. Reconciliation"
{
    Caption = 'Bank Acc. Reconciliation';
    PageType = ListPlus;
    PromotedActionCategories = 'New,Process,Report,Bank,Matching,Posting';
    SaveValues = false;
    SourceTable = "Bank Acc. Reconciliation";
    SourceTableView = WHERE("Statement Type" = CONST("Bank Reconciliation"));

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(BankAccountNo; "Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Account No.';
                    ToolTip = 'Specifies the number of the bank account that you want to reconcile with the bank''s statement.';
                    trigger OnValidate()
                    var
                        BankAccReconciliationLine: record "Bank Acc. Reconciliation Line";
                    begin
                        if BankAccReconciliationLine.BankStatementLinesListIsEmpty("Statement No.", "Statement Type", "Bank Account No.") then
                            CreateEmptyListNotification();
                    end;
                }
                field(StatementNo; "Statement No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statement No.';
                    ToolTip = 'Specifies the number of the bank account statement.';
                }
                field(StatementDate; "Statement Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statement Date';
                    ToolTip = 'Specifies the date on the bank account statement.';
                    trigger OnValidate()
                    begin
                        UpdateBankAccountLedgerEntrySubPage("Statement Date");
                    end;
                }
                field(BalanceLastStatement; "Balance Last Statement")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Balance Last Statement';
                    ToolTip = 'Specifies the ending balance shown on the last bank statement, which was used in the last posted bank reconciliation for this bank account.';
                }
                field(StatementEndingBalance; "Statement Ending Balance")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statement Ending Balance';
                    ToolTip = 'Specifies the ending balance shown on the bank''s statement that you want to reconcile with the bank account.';
                }
            }
            group(Control8)
            {
                ShowCaption = false;
                part(StmtLine; "Bank Acc. Reconciliation Lines")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Statement Lines';
                    SubPageLink = "Bank Account No." = FIELD("Bank Account No."),
                                  "Statement No." = FIELD("Statement No.");
                }
                part(ApplyBankLedgerEntries; "Apply Bank Acc. Ledger Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Account Ledger Entries';
                    SubPageLink = "Bank Account No." = FIELD("Bank Account No."),
                                  Open = CONST(true),
                                  "Statement Status" = FILTER(Open | "Bank Acc. Entry Applied" | "Check Entry Applied");
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Recon.")
            {
                Caption = '&Recon.';
                Image = BankAccountRec;
                action("&Card")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Card';
                    Image = EditLines;
                    RunObject = Page "Bank Account Card";
                    RunPageLink = "No." = FIELD("Bank Account No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record that is being processed on the journal line.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(SuggestLines)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Suggest Lines';
                    Ellipsis = true;
                    Image = SuggestLines;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Create bank account ledger entries suggestions and enter them automatically.';

                    trigger OnAction()
                    begin
                        RecallEmptyListNotification();
                        SuggestBankAccStatement.SetStmt(Rec);
                        SuggestBankAccStatement.RunModal;
                        Clear(SuggestBankAccStatement);
                    end;
                }
                action(ShowReversedEntries)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Reversed Entries';
                    Ellipsis = true;
                    Image = ReverseLines;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Include reversed bank account ledger entries in the list of suggestions.';

                    trigger OnAction()
                    begin
                        RecallEmptyListNotification();
                        UpdateBankAccountLedgerEntrySubpage(Rec."Statement Date", false);
                    end;
                }
                action(HideReversedEntries)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Hide Reversed Entries';
                    Ellipsis = true;
                    Promoted = true;
                    Image = FilterLines;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Hide unmatched reversed bank account ledger entries up to the statement date.';

                    trigger OnAction()
                    begin
                        RecallEmptyListNotification();
                        UpdateBankAccountLedgerEntrySubpage(Rec."Statement Date", true);
                    end;
                }
                action("Transfer to General Journal")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Transfer to General Journal';
                    Ellipsis = true;
                    Image = TransferToGeneralJournal;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Transfer the lines from the current window to the general journal.';

                    trigger OnAction()
                    begin
                        TransferToGLJnl.SetBankAccRecon(Rec);
                        TransferToGLJnl.Run;
                    end;
                }
                action(ChangeStatementNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Change Statement No.';
                    Ellipsis = true;
                    Image = ChangeTo;
                    ToolTip = 'Change the statement number of the bank account reconciliation. Typically, this is used when you have created a new reconciliation to correct a mistake, and you want to use the same statement number.';

                    trigger OnAction()
                    var
                        BankAccReconciliation: Record "Bank Acc. Reconciliation";
                        BankAccReconciliationCard: Page "Bank Acc. Reconciliation";
                    begin
                        BankAccReconciliation := Rec;
                        Codeunit.Run(Codeunit::"Change Bank Rec. Statement No.", BankAccReconciliation);
                        if "Statement No." <> BankAccReconciliation."Statement No." then begin
                            BankAccReconciliationCard.SetRecord(BankAccReconciliation);
                            BankAccReconciliationCard.Run();
                            CurrPage.Close();
                        end;
                    end;
                }
            }
            group("Ba&nk")
            {
                Caption = 'Ba&nk';
                action(ImportBankStatement)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Import Bank Statement';
                    Image = Import;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    ToolTip = 'Import electronic bank statements from your bank to populate with data about actual bank transactions.';

                    trigger OnAction()
                    begin
                        CurrPage.Update();
                        ImportBankStatement;
                        CheckStatementDate();
                        UpdateBankAccountLedgerEntrySubpage("Statement Date");
                        RecallEmptyListNotification();
                    end;
                }
            }
            group("M&atching")
            {
                Caption = 'M&atching';
                action(MatchAutomatically)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Match Automatically';
                    Image = MapAccounts;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    ToolTip = 'Automatically search for and match bank statement lines.';

                    trigger OnAction()
                    begin
                        SetRange("Statement Type", "Statement Type");
                        SetRange("Bank Account No.", "Bank Account No.");
                        SetRange("Statement No.", "Statement No.");
                        REPORT.Run(REPORT::"Match Bank Entries", true, true, Rec);
                    end;
                }
                action(MatchManually)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Match Manually';
                    Image = CheckRulesSyntax;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    ToolTip = 'Manually match selected lines in both panes to link each bank statement line to one or more related bank account ledger entries.';

                    trigger OnAction()
                    var
                        TempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary;
                        TempBankAccountLedgerEntry: Record "Bank Account Ledger Entry" temporary;
                        MatchBankRecLines: Codeunit "Match Bank Rec. Lines";
                    begin
                        CurrPage.StmtLine.PAGE.GetSelectedRecords(TempBankAccReconciliationLine);
                        CurrPage.ApplyBankLedgerEntries.PAGE.GetSelectedRecords(TempBankAccountLedgerEntry);
                        MatchBankRecLines.MatchManually(TempBankAccReconciliationLine, TempBankAccountLedgerEntry);
                    end;
                }
                action(RemoveMatch)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Remove Match';
                    Image = RemoveContacts;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    ToolTip = 'Remove selection of matched bank statement lines.';

                    trigger OnAction()
                    var
                        TempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary;
                        TempBankAccountLedgerEntry: Record "Bank Account Ledger Entry" temporary;
                        MatchBankRecLines: Codeunit "Match Bank Rec. Lines";
                    begin
                        CurrPage.StmtLine.PAGE.GetSelectedRecords(TempBankAccReconciliationLine);
                        CurrPage.ApplyBankLedgerEntries.PAGE.GetSelectedRecords(TempBankAccountLedgerEntry);
                        MatchBankRecLines.RemoveMatch(TempBankAccReconciliationLine, TempBankAccountLedgerEntry);
                    end;
                }
                action(MatchDetails)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Match Details';
                    Image = ViewDetails;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    ToolTip = 'Show matching details about the selected bank statement line.';

                    trigger OnAction()
                    var
                        TempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary;
                    begin
                        CurrPage.StmtLine.PAGE.GetSelectedRecords(TempBankAccReconciliationLine);
                        if TempBankAccReconciliationLine."Applied Entries" > 0 then
                            Page.Run(Page::"Bank Rec. Line Match Details", TempBankAccReconciliationLine);
                    end;
                }
                action(All)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show All';
                    Image = AddWatch;
                    ToolTip = 'Show all bank statement lines.';

                    trigger OnAction()
                    begin
                        CurrPage.StmtLine.PAGE.ToggleMatchedFilter(false);
                        CurrPage.ApplyBankLedgerEntries.PAGE.ToggleMatchedFilter(false);
                    end;
                }
                action(NotMatched)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Nonmatched';
                    Image = AddWatch;
                    ToolTip = 'Show all bank statement lines that have not yet been matched.';

                    trigger OnAction()
                    begin
                        CurrPage.StmtLine.PAGE.ToggleMatchedFilter(true);
                        CurrPage.ApplyBankLedgerEntries.PAGE.ToggleMatchedFilter(true);
                    end;
                }
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action("&Test Report")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'Preview the resulting bank account reconciliations to see the consequences before you perform the actual posting.';

                    trigger OnAction()
                    begin
                        ReportPrint.PrintBankAccRecon(Rec);
                    end;
                }
                action(Post)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'P&ost';
                    Image = PostOrder;
                    Promoted = true;
                    PromotedCategory = Category6;
                    PromotedIsBig = true;
                    RunObject = Codeunit "Bank Acc. Recon. Post (Yes/No)";
                    ShortCutKey = 'F9';
                    ToolTip = 'Finalize the document or journal by posting the amounts and quantities to the related accounts in your company books.';
                }
                action(PostAndPrint)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post and &Print';
                    Image = PostPrint;
                    Promoted = true;
                    PromotedCategory = Category6;
                    PromotedIsBig = true;
                    RunObject = Codeunit "Bank Acc. Recon. Post+Print";
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Finalize and prepare to print the document or journal. The values and quantities are posted to the related accounts. A report request window where you can specify what to include on the print-out.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        CreateEmptyListNotification();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        RecallEmptyListNotification();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        if UpdatedBankAccountLESystemId <> Rec.SystemId then begin
            UpdateBankAccountLedgerEntrySubpage(Rec."Statement Date");
            UpdatedBankAccountLESubpageStementDate := Rec."Statement Date";
            UpdatedBankAccountLESystemId := Rec.SystemId;
        end;
    end;

    local procedure GetImportBankStatementNotificatoinId(): Guid
    begin
        exit('aa54bf06-b8b9-420d-a4a8-1f55a3da3e2a');
    end;

    local procedure CreateEmptyListNotification()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        ImportBankStatementNotification: Notification;
    begin
        ImportBankStatementNotification.Id := GetImportBankStatementNotificatoinId();
        if ImportBankStatementNotification.Recall then;
        if not BankAccReconciliationLine.BankStatementLinesListIsEmpty("Statement No.", "Statement Type", "Bank Account No.") then
            exit;

        ImportBankStatementNotification.Message := ListEmptyMsg;
        ImportBankStatementNotification.Scope := NotificationScope::LocalScope;
        ImportBankStatementNotification.Send();
    end;

    local procedure RecallEmptyListNotification()
    var
        ImportBankStatementNotification: Notification;
    begin
        ImportBankStatementNotification.Id := GetImportBankStatementNotificatoinId();
        if ImportBankStatementNotification.Recall then;
    end;

    local procedure CheckStatementDate()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        BankAccReconciliationLine.SetFilter("Bank Account No.", Rec."Bank Account No.");
        BankAccReconciliationLine.SetFilter("Statement No.", Rec."Statement No.");
        BankAccReconciliationLine.SetCurrentKey("Transaction Date");
        BankAccReconciliationLine.Ascending := false;
        if BankAccReconciliationLine.FindFirst() then begin
            BankAccReconciliation.GetBySystemId(Rec.SystemId);
            if BankAccReconciliation."Statement Date" = 0D then begin
                if Confirm(StrSubstNo(StatementDateEmptyMsg, Format(BankAccReconciliationLine."Transaction Date"))) then begin
                    Rec."Statement Date" := BankAccReconciliationLine."Transaction Date";
                    Rec.Modify();
                end;
            end else
                if BankAccReconciliation."Statement Date" < BankAccReconciliationLine."Transaction Date" then
                    Message(ImportedLinesAfterStatementDateMsg);
        end;
    end;

    local procedure UpdateBankAccountLedgerEntrySubpage(StatementDate: Date)
    begin
        UpdateBankAccountLedgerEntrySubpage(StatementDate, true);
    end;

    local procedure UpdateBankAccountLedgerEntrySubpage(StatementDate: Date; ExcludeReversedEntries: Boolean)
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        FilterDate: Date;
    begin
        BankAccountLedgerEntry.SetRange("Bank Account No.", "Bank Account No.");
        BankAccountLedgerEntry.SetRange(Open, true);
        BankAccountLedgerEntry.SetFilter("Statement Status", Format(BankAccountLedgerEntry."Statement Status"::Open) + '|' + Format(BankAccountLedgerEntry."Statement Status"::"Bank Acc. Entry Applied") + '|' + Format(BankAccountLedgerEntry."Statement Status"::"Check Entry Applied"));
        FilterDate := MatchCandidateFilterDate();
        if StatementDate > FilterDate then
            FilterDate := StatementDate;
        if FilterDate <> 0D then
            BankAccountLedgerEntry.SetFilter("Posting Date", '<=' + Format(FilterDate));
        if BankAccountLedgerEntry.FindSet() then
            if ExcludeReversedEntries then begin
                repeat
                    if (BankAccountLedgerEntry."Statement Status" = BankAccountLedgerEntry."Statement Status"::Open) and (BankAccountLedgerEntry.Reversed = true) then
                        BankAccountLedgerEntry.Mark(false)
                    else
                        BankAccountLedgerEntry.Mark(true);
                until BankAccountLedgerEntry.Next() = 0;
                BankAccountLedgerEntry.MarkedOnly(true);
            end;
        CurrPage.ApplyBankLedgerEntries.Page.SetTableView(BankAccountLedgerEntry);
        CurrPage.ApplyBankLedgerEntries.Page.Update();
    end;

    var
        SuggestBankAccStatement: Report "Suggest Bank Acc. Recon. Lines";
        TransferToGLJnl: Report "Trans. Bank Rec. to Gen. Jnl.";
        ReportPrint: Codeunit "Test Report-Print";
        ListEmptyMsg: Label 'No bank statement lines exist. Choose the Import Bank Statement action to fill in the lines from a file, or enter lines manually.';
        ImportedLinesAfterStatementDateMsg: Label 'There are lines on the imported bank statement with dates that are after the statement date.';
        StatementDateEmptyMsg: Label 'The bank account reconciliation does not have a statement date. %1 is the latest date on a line. Do you want to use that date for the statement?', Comment = '%1 - statement date';
        UpdatedBankAccountLESubpageStementDate: Date;
        UpdatedBankAccountLESystemId: Guid;
}