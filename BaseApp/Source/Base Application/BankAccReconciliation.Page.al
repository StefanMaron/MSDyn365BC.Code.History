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
                    begin
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
                                  "Statement Status" = FILTER(Open | "Bank Acc. Entry Applied" | "Check Entry Applied"),
                                  Reversed = FILTER(false);
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
                    Promoted = true;
                    PromotedCategory = Category4;
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
                    var
                        TempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary;
                    begin
                        CurrPage.StmtLine.PAGE.GetSelectedRecords(TempBankAccReconciliationLine);
                        TempBankAccReconciliationLine.Setrange(Difference, 0);
                        TempBankAccReconciliationLine.DeleteAll();
                        TempBankAccReconciliationLine.Setrange(Difference);
                        if TempBankAccReconciliationLine.IsEmpty then
                            error(NoBankAccReconcilliationLineWithDiffSellectedErr);
                        TransferToGLJnl.SetBankAccReconLine(TempBankAccReconciliationLine);
                        TransferToGLJnl.SetBankAccRecon(Rec);
                        TransferToGLJnl.Run;
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
                    ShortCutKey = 'F9';
                    ToolTip = 'Finalize the document or journal by posting the amounts and quantities to the related accounts in your company books.';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Bank Acc. Recon. Post (Yes/No)", Rec);
                        RefreshSharedTempTable;
                    end;
                }
                action(PostAndPrint)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post and &Print';
                    Image = PostPrint;
                    Promoted = true;
                    PromotedCategory = Category6;
                    PromotedIsBig = true;
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Finalize and prepare to print the document or journal. The values and quantities are posted to the related accounts. A report request window where you can specify what to include on the print-out.';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Bank Acc. Recon. Post+Print", Rec);
                        CurrPage.Update(false);
                        RefreshSharedTempTable;
                    end;
                }
            }
        }
    }

    trigger OnClosePage()
    begin
        RefreshSharedTempTable;
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        RefreshSharedTempTable;
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Modify(true);
        RefreshSharedTempTable;
    end;

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

    procedure SetSharedTempTable(var TempBankAccReconciliationOnList: Record "Bank Acc. Reconciliation" temporary)
    begin
        TempBankAccReconciliationDataset.Copy(TempBankAccReconciliationOnList, true);
    end;

    local procedure RefreshSharedTempTable()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        TempBankAccReconciliationDataset.DeleteAll();
        BankAccReconciliation.GetTempCopy(TempBankAccReconciliationDataset);
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
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        FilterDate: Date;
    begin
        BankAccountLedgerEntry.SetRange("Bank Account No.", "Bank Account No.");
        BankAccountLedgerEntry.SetRange(Open, true);
        BankAccountLedgerEntry.SetRange(Reversed, false);
        BankAccountLedgerEntry.SetFilter("Statement Status", StrSubstNo('%1|%2|%3', Format(BankAccountLedgerEntry."Statement Status"::Open), Format(BankAccountLedgerEntry."Statement Status"::"Bank Acc. Entry Applied"), Format(BankAccountLedgerEntry."Statement Status"::"Check Entry Applied")));
        FilterDate := MatchCandidateFilterDate();
        if StatementDate > FilterDate then
            FilterDate := StatementDate;
        if FilterDate <> 0D then
            BankAccountLedgerEntry.SetFilter("Posting Date", StrSubstNo('<=%1', FilterDate));
        if BankAccountLedgerEntry.FindSet() then;
        CurrPage.ApplyBankLedgerEntries.Page.SetTableView(BankAccountLedgerEntry);
        CurrPage.ApplyBankLedgerEntries.Page.Update();
    end;

    var
        SuggestBankAccStatement: Report "Suggest Bank Acc. Recon. Lines";
        TransferToGLJnl: Report "Trans. Bank Rec. to Gen. Jnl.";
        TempBankAccReconciliationDataset: Record "Bank Acc. Reconciliation" temporary;
        ReportPrint: Codeunit "Test Report-Print";
        ListEmptyMsg: Label 'No bank statement lines exist. Choose the Import Bank Statement action to fill in the lines from a file, or enter lines manually.';
        ImportedLinesAfterStatementDateMsg: Label 'Imported bank statement has lines dated after the statement date.';
        StatementDateEmptyMsg: Label 'Statement date is empty. The latest bank statement line is %1. Do you want to set the statement date to this date?', Comment = '%1 - statement date';
        NoBankAccReconcilliationLineWithDiffSellectedErr: Label 'Select the bank statement lines that have differences to transfer to the general journal.';
        UpdatedBankAccountLESubpageStementDate: Date;
        UpdatedBankAccountLESystemId: Guid;
}