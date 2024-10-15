page 11400 "Bank/Giro Journal"
{
    Caption = 'Bank/Giro Journal';
    PageType = Document;
    PopulateAllFields = true;
    SourceTable = "CBG Statement";
    SourceTableView = SORTING(Type)
                      WHERE(Type = CONST("Bank/Giro"));

    layout
    {
        area(content)
        {
            group(Control1)
            {
                ShowCaption = false;
                field("Account No."; "Account No.")
                {
                    ApplicationArea = All;
                    CaptionClass = Format(StrSubstNo(Text1000001, "Account Type"));
                    Editable = false;
                    Lookup = false;
                    ToolTip = 'Specifies the number of the account the CBG Statement is linked to.';
                    Visible = "Account No.Visible";
                }
                field(GetName; GetName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Account Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the account the CBG Statement is linked to.';
                }
                field(Currency; Currency)
                {
                    ApplicationArea = All;
                    Caption = 'Currency';
                    Editable = false;
                    ToolTip = 'Specifies the currency code for the amounts on the statement lines.';
                    Visible = CurrencyVisible;
                }
                field("Account No.2"; CLAccountNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Account No.';
                    Editable = false;
                    ToolTip = 'Specifies the number of the G/L account the CBG Statement is linked to.';
                }
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the statement.';
                }
                field("Document Date"; Date)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when you create the CBG statement.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    AssistEdit = true;
                    ToolTip = 'Specifies a document number for the CBG statement of type Bank/Giro.';

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update;
                    end;
                }
                field("Opening Balance"; "Opening Balance")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Currency;
                    AutoFormatType = 1;
                    ToolTip = 'Specifies the current balance (LCY) of the bank/giro or cash account.';
                }
                field("Closing Balance"; "Closing Balance")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Currency;
                    AutoFormatType = 1;
                    ToolTip = 'Specifies the new closing balance, after you have entered all statements in the Bank/Giro journal or all payment/receipt entries.';
                }
            }
            part(Subform; "Bank/Giro Journal Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Journal Template Name" = FIELD("Journal Template Name"),
                              "No." = FIELD("No.");
                SubPageView = SORTING("Journal Template Name", "No.", "Line No.");
            }
        }
        area(factboxes)
        {
            part(Control1903886207; "Bank/Giro Jnl. Subf. Info")
            {
                ApplicationArea = Basic, Suite;
                Provider = Subform;
                SubPageLink = "Journal Template Name" = FIELD("Journal Template Name"),
                              "No." = FIELD("No."),
                              "Line No." = FIELD("Line No.");
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Telebank")
            {
                Caption = '&Telebank';
                Image = ElectronicBanking;
                action("Bank Account List")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Account List';
                    Image = BankAccount;
                    RunObject = Page "Telebank - Bank Overview";
                    RunPageView = SORTING("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View general information about bank accounts, such as posting group, currency code, minimum balance, and balance. You can choose to see all the balances in the report in local currency (LCY). For example, the information in the different bank accounts from this report can also be accumulated in the Bank Account window.';
                }
                action(Proposal)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Proposal';
                    Image = SuggestElectronicDocument;
                    RunObject = Page "Telebank Proposal";
                    RunPageLink = "Our Bank No." = FIELD("Account No.");
                    RunPageView = SORTING("Our Bank No.", "Line No.");
                    ShortCutKey = 'Shift+F11';
                    ToolTip = 'Create a new payment or collection proposal for the selected bank.';
                }
                action(InsertPaymentHistory)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Insert Payment History';
                    Image = PaymentHistory;
                    ShortCutKey = 'Ctrl+F11';
                    ToolTip = 'Select the payment history that you want to process in the journal.';

                    trigger OnAction()
                    var
                        TelebankInterface: Codeunit "CBG Journal Telebank Interface";
                    begin
                        TestField("No.");
                        TelebankInterface.InsertPaymentHistory(Rec);
                    end;
                }
                action(Reconciliation)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reconciliation';
                    Image = Reconcile;
                    ToolTip = 'Reconcile entries in your bank account ledger entries with the actual transactions in your bank account, according to the latest bank statement.';

                    trigger OnAction()
                    begin
                        "CGB Statement reconciliation".MatchCBGStatement(Rec);
                    end;
                }
            }
            group("A&ccount")
            {
                Caption = 'A&ccount';
                Image = ChartOfAccounts;
                action(Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to journal lines to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDimensions;
                        CurrPage.SaveRecord;
                    end;
                }
            }
        }
        area(processing)
        {
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action(Overview)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Overview';
                    Image = ViewDetails;
                    RunObject = Page "Bank/Giro Journal List";
                    RunPageLink = "Journal Template Name" = FIELD("Journal Template Name");
                    ShortCutKey = 'Shift+Ctrl+L';
                    ToolTip = 'View all payment history entries for the bank accounts.';
                }
                action("Test Report")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'Preview the results of posting the journal.';

                    trigger OnAction()
                    var
                        GenJournalTemplate: Record "Gen. Journal Template";
                        CBGStatement: Record "CBG Statement";
                    begin
                        CBGStatement := Rec;
                        CBGStatement.SetRecFilter;
                        GenJournalTemplate.Get("Journal Template Name");
                        GenJournalTemplate.TestField("Test Report ID");
                        REPORT.Run(GenJournalTemplate."Test Report ID", true, false, CBGStatement);
                    end;
                }
                action(Post)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post';
                    Image = Post;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ShortCutKey = 'F9';
                    ToolTip = 'Finalize the document or journal. The values and quantities are posted to the related accounts. A report request window where you can specify what to include on the print-out.';

                    trigger OnAction()
                    var
                        GenJournalTemplate: Record "Gen. Journal Template";
                    begin
                        if not Confirm(StrSubstNo(Text1000002, Type), false) then
                            exit;

                        GenJournalTemplate.Get("Journal Template Name");
                        GenJournalTemplate.TestField("Force Posting Report", false);
                        ProcessStatementASGenJournal;
                        CurrPage.Update(false);
                    end;
                }
                action("Post and &Print")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post and &Print';
                    Image = PostPrint;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Finalize and prepare to print the document or journal. The values and quantities are posted to the related accounts. A report request window where you can specify what to include on the print-out.';

                    trigger OnAction()
                    var
                        GenJournalTemplate: Record "Gen. Journal Template";
                        CBGStatement: Record "CBG Statement";
                    begin
                        if not Confirm(StrSubstNo(Text1000003, Type), false) then
                            exit;

                        CheckBalance;
                        CBGStatement := Rec;
                        CBGStatement.SetRecFilter;
                        GenJournalTemplate.Get("Journal Template Name");
                        GenJournalTemplate.TestField("Posting Report ID");
                        REPORT.RunModal(GenJournalTemplate."Posting Report ID", false, false, CBGStatement);
                        ProcessStatementASGenJournal;
                        CurrPage.Update(false);
                    end;
                }
            }
        }
    }

    trigger OnInit()
    begin
        "Account No.Visible" := true;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        CurrPage.Update(false);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        CurrPage.Subform.PAGE.ChangedHeader(Rec);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        FilterGroup(2);
        InitRecord(GetFilter("Journal Template Name"));
        FilterGroup(0);

        CurrPage.Subform.PAGE.ChangedHeader(Rec);
        "Account No.Visible" := "Account Type" = "Account Type"::"Bank Account";
        CurrencyVisible := "Account Type" = "Account Type"::"Bank Account";
    end;

    trigger OnOpenPage()
    var
        JnlSelected: Boolean;
    begin
        if ("Journal Template Name" <> '') and ("No." <> 0) then begin
            FilterGroup(2);
            SetRange("Journal Template Name", "Journal Template Name");
            FilterGroup(0);
        end else begin
            FilterGroup(2);
            JnlSelected := (GetFilter("Journal Template Name") <> '');
            FilterGroup(0);
            if not JnlSelected then begin
                GenJnlManagement.TemplateSelectionCBG(PAGE::"Bank/Giro Journal", 12, Rec, JnlSelected);
                if not JnlSelected then
                    Error('');
                GenJnlManagement.CheckTemplateNameCBG(GetRangeMax("Journal Template Name"));
            end;
        end;

        "Account No.Visible" := "Account Type" = "Account Type"::"Bank Account";
        CurrencyVisible := "Account Type" = "Account Type"::"Bank Account";
    end;

    var
        Text1000001: Label '%1 No.';
        Text1000002: Label 'Do you want to post the %1 Journal?';
        Text1000003: Label 'Do you want to post and print the %1 Journal?';
        "CGB Statement reconciliation": Codeunit "CBG Statement Reconciliation";
        GenJnlManagement: Codeunit GenJnlManagement;
        [InDataSet]
        "Account No.Visible": Boolean;
        [InDataSet]
        CurrencyVisible: Boolean;
}

