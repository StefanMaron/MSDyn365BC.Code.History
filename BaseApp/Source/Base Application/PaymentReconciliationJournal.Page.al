page 1290 "Payment Reconciliation Journal"
{
    AutoSplitKey = true;
    Caption = 'Payment Reconciliation Journal';
    DataCaptionExpression = "Bank Account No.";
    DelayedInsert = true;
    LinksAllowed = false;
    PageType = Worksheet;
    PromotedActionCategories = 'New,Process,Report,Manual Application,Review,Details,View,Page,Posting,Line';
    SourceTable = "Bank Acc. Reconciliation Line";
    SourceTableView = WHERE("Statement Type" = CONST("Payment Application"));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                FreezeColumn = "Statement Amount";
                ShowCaption = false;
                field("Match Confidence"; "Match Confidence")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the quality of the automatic payment application on the journal line.';

                    trigger OnDrillDown()
                    begin
                        DisplayApplication;
                    end;
                }
                field("Transaction Date"; "Transaction Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the payment represented by the journal line was recorded in the bank account.';
                }
                field("Transaction Text"; "Transaction Text")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the text that the customer or vendor entered on that payment transaction that is represented by the journal line.';
                    Width = 40;
                }
                field("Transaction ID"; "Transaction ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the imported bank transaction.';
                    Visible = false;
                }
                field("Statement Amount"; "Statement Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Transaction Amount';
                    ToolTip = 'Specifies the amount that was paid into the bank account and then imported as a bank statement line represented by the journal line.';

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord;
                        CurrPage.Update(false)
                    end;
                }
                field("Applied Amount"; "Applied Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount that has been applied to one or more open entries.';
                }
                field(Difference; Difference)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Style = Unfavorable;
                    ToolTip = 'Specifies the difference between the amount in the Statement Amount field and the amount in the Applied Amount field.';
                }
                field(StatementToRemAmtDifference; StatementToRemAmtDifference)
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Caption = 'Difference from Remaining Amount';
                    Enabled = false;
                    ToolTip = 'Specifies the difference between the values in the Statement Amount and the Remaining Amount After Posting fields.';
                    Visible = false;
                }
                field(GetAppliedToDocumentNo; GetAppliedToDocumentNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document No.';
                    ToolTip = 'Specifies the document number of the open entry that the payment is applied to.';
                }
                field(DescAppliedEntry; AppliedPmtEntry.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description';
                    Editable = false;
                    ToolTip = 'Specifies the description on the open entry that the payment is applied to.';
                }
                field(DueDateAppliedEntry; AppliedPmtEntry."Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Due Date';
                    ToolTip = 'Specifies the due date on the open entry that the payment is applied to.';
                }
                field(AccountName; GetAppliedToName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Account Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the customer or vendor that the payment is applied to.';

                    trigger OnDrillDown()
                    begin
                        AppliedToDrillDown;
                    end;
                }
                field("Account Type"; "Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of account that the payment application will be posted to when you post the worksheet.';
                }
                field("Account No."; "Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account number that the payment application will be posted to when you post the worksheet.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update;
                        if Difference <> 0 then
                            TransferRemainingAmountToAccount;
                    end;
                }
                field(PostingDateAppliedEntry; AppliedPmtEntry."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posting Date';
                    Editable = false;
                    ToolTip = 'Specifies the posting date on the open entry that the payment is applied to.';
                    Visible = false;
                }
                field("AppliedPmtEntry.""Currency Code"""; AppliedPmtEntry."Currency Code")
                {
                    ApplicationArea = Suite;
                    Caption = 'Entry Currency Code';
                    ToolTip = 'Specifies the currency code on the open entry that the payment is applied to.';
                    Visible = false;
                }
                field("Match Details"; MatchDetails)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Match Details';
                    Editable = false;
                    ToolTip = 'Specifies details about the payment application on the journal line.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        DisplayApplication;
                    end;
                }
                field("Applied Entries"; "Applied Entries")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies for a journal line where the payment has been applied, how many entries the payment has been applied to.';
                    Visible = false;
                }
                field(RemainingAmount; RemainingAmountAfterPosting)
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Caption = 'Remaining Amount After Posting';
                    Editable = false;
                    ToolTip = 'Specifies the amount that remains to be paid on the open entry that the payment is applied to.';
                    Visible = false;
                }
                field("Additional Transaction Info"; "Additional Transaction Info")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies additional information on the bank statement line for the payment.';
                    Visible = false;
                    Width = 40;
                }
                field("Related-Party Address"; "Related-Party Address")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the address of the customer or vendor who made the payment that is represented by the journal line.';
                    Visible = false;
                    Width = 30;
                }
                field("Related-Party Bank Acc. No."; "Related-Party Bank Acc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the bank account number of the customer or vendor who made the payment.';
                    Visible = false;
                    Width = 20;
                }
                field("Related-Party City"; "Related-Party City")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the city name of the customer or vendor.';
                    Visible = false;
                    Width = 10;
                }
                field("Related-Party Name"; "Related-Party Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the name of the customer or vendor who made the payment that is represented by the journal line.';
                    Visible = false;
                    Width = 30;
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = DimVisible1;
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = DimVisible2;
                }
                field(ShortcutDimCode3; ShortcutDimCode[3])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,3';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(3),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    ToolTip = 'Specifies the dimension value code linked to the journal line.';
                    Visible = DimVisible3;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(3, ShortcutDimCode[3]);

                        OnAfterValidateShortcutDimCode(Rec, ShortcutDimCode, 3);
                    end;
                }
                field(ShortcutDimCode4; ShortcutDimCode[4])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,4';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(4),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    ToolTip = 'Specifies the dimension value code linked to the journal line.';
                    Visible = DimVisible4;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(4, ShortcutDimCode[4]);

                        OnAfterValidateShortcutDimCode(Rec, ShortcutDimCode, 4);
                    end;
                }
                field(ShortcutDimCode5; ShortcutDimCode[5])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,5';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(5),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    ToolTip = 'Specifies the dimension value code linked to the journal line.';
                    Visible = DimVisible5;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(5, ShortcutDimCode[5]);

                        OnAfterValidateShortcutDimCode(Rec, ShortcutDimCode, 5);
                    end;
                }
                field(ShortcutDimCode6; ShortcutDimCode[6])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,6';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(6),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    ToolTip = 'Specifies the dimension value code linked to the journal line.';
                    Visible = DimVisible6;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(6, ShortcutDimCode[6]);

                        OnAfterValidateShortcutDimCode(Rec, ShortcutDimCode, 6);
                    end;
                }
                field(ShortcutDimCode7; ShortcutDimCode[7])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,7';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(7),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    ToolTip = 'Specifies the dimension value code linked to the journal line.';
                    Visible = DimVisible7;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(7, ShortcutDimCode[7]);

                        OnAfterValidateShortcutDimCode(Rec, ShortcutDimCode, 7);
                    end;
                }
                field(ShortcutDimCode8; ShortcutDimCode[8])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,8';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(8),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    ToolTip = 'Specifies the dimension value code linked to the journal line.';
                    Visible = DimVisible8;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(8, ShortcutDimCode[8]);

                        OnAfterValidateShortcutDimCode(Rec, ShortcutDimCode, 8);
                    end;
                }
            }
            group(Control28)
            {
                ShowCaption = false;
                group(Control33)
                {
                    Editable = false;
                    ShowCaption = false;
                    field(BalanceOnBankAccount; BankAccReconciliation."Total Balance on Bank Account")
                    {
                        ApplicationArea = Basic, Suite;
                        AutoFormatType = 1;
                        Caption = 'Balance on Bank Account';
                        ToolTip = 'Specifies the balance of the bank account per the last time you reconciled the bank account.';

                        trigger OnDrillDown()
                        begin
                            BankAccReconciliation.DrillDownOnBalanceOnBankAccount;
                        end;
                    }
                    field(TotalTransactionAmount; BankAccReconciliation."Total Transaction Amount")
                    {
                        ApplicationArea = Basic, Suite;
                        AutoFormatType = 1;
                        Caption = 'Total Transaction Amount';
                        ToolTip = 'Specifies the sum of values in the Statement Amount field on all the lines in the Payment Reconciliation Journal window.';
                    }
                    field(BalanceOnBankAccountAfterPosting; BankAccReconciliation."Total Balance on Bank Account" + BankAccReconciliation."Total Unposted Applied Amount")
                    {
                        ApplicationArea = Basic, Suite;
                        AutoFormatType = 1;
                        Caption = 'Balance on Bank Account After Posting';
                        StyleExpr = BalanceAfterPostingStyleExpr;
                        ToolTip = 'Specifies the total amount that will exist on the bank account as a result of payment applications that you post in the Payment Reconciliation Journal window.';
                    }
                }
                group(Control3)
                {
                    ShowCaption = false;
                    field(OutstandingTransactions; OutstandingTransactions)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Outstanding Transactions';
                        Editable = false;
                        ToolTip = 'Specifies the outstanding bank transactions that have not been applied.';

                        trigger OnDrillDown()
                        var
                            DummyOutstandingBankTransaction: Record "Outstanding Bank Transaction";
                        begin
                            DummyOutstandingBankTransaction.DrillDown("Bank Account No.",
                              DummyOutstandingBankTransaction.Type::"Bank Account Ledger Entry", "Statement Type", "Statement No.");
                        end;
                    }
                    field(OutstandingPayments; OutstandingPayments)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Outstanding Payments';
                        Editable = false;
                        ToolTip = 'Specifies the outstanding check transactions that have not been applied.';

                        trigger OnDrillDown()
                        var
                            DummyOutstandingBankTransaction: Record "Outstanding Bank Transaction";
                        begin
                            DummyOutstandingBankTransaction.DrillDown("Bank Account No.",
                              DummyOutstandingBankTransaction.Type::"Check Ledger Entry", "Statement Type", "Statement No.");
                        end;
                    }
                    field(StatementEndingBalance; BankAccReconciliation."Statement Ending Balance")
                    {
                        ApplicationArea = Basic, Suite;
                        AutoFormatType = 1;
                        Caption = 'Statement Ending Balance';
                        Editable = false;
                        ToolTip = 'Specifies the balance on your actual bank account after the bank has processed the payments that you have imported with the bank statement file.';
                    }
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(Process)
            {
                Caption = 'Process';
                action(ImportBankTransactions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Import Bank Transactions';
                    Ellipsis = true;
                    Image = Import;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Import a file for transaction payments that was made from your bank account and apply the payments to the entry. The file name must end in .csv, .txt, asc, or .xml.';

                    trigger OnAction()
                    var
                        SubscriberInvoked: Boolean;
                    begin
                        OnAfterImportBankTransactions(SubscriberInvoked, Rec);
                        if not SubscriberInvoked then begin
                            BankAccReconciliation.Get("Statement Type", "Bank Account No.", "Statement No.");
                            BankAccReconciliation.ImportBankStatement;
                            if BankAccReconciliation.Find then;
                        end;
                    end;
                }
                action(ApplyAutomatically)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Apply Automatically';
                    Image = MapAccounts;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    RunPageOnRec = true;
                    ToolTip = 'Apply payments to their related open entries based on data matches between bank transaction text and entry information.';

                    trigger OnAction()
                    var
                        BankAccReconciliation: Record "Bank Acc. Reconciliation";
                        AppliedPaymentEntry: Record "Applied Payment Entry";
                        SubscriberInvoked: Boolean;
                    begin
                        AppliedPaymentEntry.SetRange("Statement Type", "Statement Type");
                        AppliedPaymentEntry.SetRange("Bank Account No.", "Bank Account No.");
                        AppliedPaymentEntry.SetRange("Statement No.", "Statement No.");

                        if AppliedPaymentEntry.Count > 0 then
                            if not Confirm(RemoveExistingApplicationsQst) then
                                exit;

                        BankAccReconciliation.Get("Statement Type", "Bank Account No.", "Statement No.");
                        OnAtActionApplyAutomatically(BankAccReconciliation, SubscriberInvoked);
                        if not SubscriberInvoked then
                            CODEUNIT.Run(CODEUNIT::"Match Bank Pmt. Appl.", BankAccReconciliation);
                        CurrPage.Update(false);
                    end;
                }
                group(Action58)
                {
                    Caption = 'Post';
                    Image = Post;
                    action(TestReport)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = '&Test Report';
                        Image = TestReport;
                        ToolTip = 'Preview the resulting payment reconciliations to see the consequences before you perform the actual posting.';

                        trigger OnAction()
                        var
                            TestReportPrint: Codeunit "Test Report-Print";
                        begin
                            BankAccReconciliation.Get("Statement Type", "Bank Account No.", "Statement No.");
                            TestReportPrint.PrintBankAccRecon(BankAccReconciliation);
                        end;
                    }
                    action(Post)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Post Payments and Reconcile Bank Account';
                        Ellipsis = true;
                        Image = PostApplication;
                        Promoted = true;
                        PromotedCategory = Category9;
                        PromotedIsBig = true;
                        ShortCutKey = 'F9';
                        ToolTip = 'Reconcile the bank account for payments that you post with the journal and close related ledger entries.';

                        trigger OnAction()
                        begin
                            InvokePost(false)
                        end;
                    }
                    action(PostPaymentsOnly)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Post Payments Only';
                        Ellipsis = true;
                        Image = PaymentJournal;
                        Promoted = true;
                        PromotedCategory = Category9;
                        PromotedIsBig = true;
                        ToolTip = 'Post payments but do not close related bank account ledger entries or reconcile the bank account.';

                        trigger OnAction()
                        begin
                            InvokePost(true)
                        end;
                    }
                }
            }
            group("New Documents")
            {
                Caption = 'New Documents';
                action(FinanceChargeMemo)
                {
                    ApplicationArea = Suite;
                    Caption = 'New Finance Charge Memo';
                    Enabled = FinanceChargeMemoEnabled;
                    Image = FinChargeMemo;
                    //The property 'PromotedIsBig' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedIsBig = true;
                    RunObject = Page "Finance Charge Memo";
                    RunPageLink = "Customer No." = FIELD("Account No.");
                    RunPageMode = Create;
                    ToolTip = 'Define a memo that includes information about the calculated interest on outstanding balances of an account. You can then send the memo in an email to the customer.';
                }
                action(OpenGenJnl)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'General Journal';
                    Image = GLRegisters;
                    //The property 'PromotedIsBig' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedIsBig = true;
                    RunObject = Page "General Journal";
                    ToolTip = 'Open the general journal, for example, to record or post a payment that has no related document.';
                }
                action("Payment Journal")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payment Journal';
                    Image = PaymentJournal;
                    //The property 'PromotedIsBig' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedIsBig = true;
                    RunObject = Page "Payment Journal";
                    ToolTip = 'View or edit the payment journal where you can register payments to vendors.';
                }
            }
            group("Manual Application")
            {
                Caption = 'Manual Application';
                action(TransferDiffToAccount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Transfer Difference to Account';
                    Image = TransferToGeneralJournal;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    ToolTip = 'Specify the balancing account to which you want a non-applicable payment amount on a payment reconciliation journal line to be posted when you post the journal.';

                    trigger OnAction()
                    var
                        MatchBankPayments: Codeunit "Match Bank Payments";
                    begin
                        MatchBankPayments.TransferDiffToAccount(Rec, TempGenJournalLine)
                    end;
                }
                action(AddMappingRule)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Map Text to Account';
                    Image = Add;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    ToolTip = 'Associate text on payments with debit, credit, and balancing accounts, so payments are posted to the accounts when you post payments. The payments are not applied to invoices or credit memos, and are suited for recurring cash receipts or expenses.';

                    trigger OnAction()
                    var
                        TextToAccMapping: Record "Text-to-Account Mapping";
                        MatchBankPayments: Codeunit "Match Bank Payments";
                    begin
                        TextToAccMapping.InsertRecFromBankAccReconciliationLine(Rec);
                        MatchBankPayments.RerunTextMapper(Rec);
                    end;
                }
                action(ApplyEntries)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Apply Manually';
                    Ellipsis = true;
                    Image = ApplyEntries;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    ToolTip = 'Review and apply payments that were applied automatically to wrong open entries or not applied at all.';

                    trigger OnAction()
                    begin
                        DisplayApplication;
                        GetAppliedPmtData(AppliedPmtEntry, RemainingAmountAfterPosting, StatementToRemAmtDifference, PmtAppliedToTxt);
                    end;
                }
            }
            group(Review)
            {
                Caption = 'Review';
                action(Accept)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Accept Applications';
                    Image = Approve;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    ToolTip = 'Accept a payment application after reviewing it or manually applying it to entries. This closes the payment application and sets the Match Confidence to Accepted.';

                    trigger OnAction()
                    var
                        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
                    begin
                        CurrPage.SetSelectionFilter(BankAccReconciliationLine);
                        BankAccReconciliationLine.AcceptAppliedPaymentEntriesSelectedLines;
                    end;
                }
                action(Reject)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Remove Applications';
                    Image = Reject;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    ToolTip = 'Remove a payment application from an entry. This unapplies the payment.';

                    trigger OnAction()
                    var
                        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
                    begin
                        CurrPage.SetSelectionFilter(BankAccReconciliationLine);
                        BankAccReconciliationLine.RejectAppliedPaymentEntriesSelectedLines;
                    end;
                }
            }
            group("Custom Sorting")
            {
                Caption = 'Custom Sorting';
                action(ShowNonAppliedLines)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Non-Applied Lines';
                    Image = FilterLines;
                    Promoted = true;
                    PromotedCategory = Category7;
                    PromotedIsBig = true;
                    ToolTip = 'Display only payments in the list that have not been applied.';

                    trigger OnAction()
                    begin
                        SetFilter(Difference, '<>0');
                        CurrPage.Update;
                    end;
                }
                action(ShowAllLines)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show All Lines';
                    Image = AllLines;
                    Promoted = true;
                    PromotedCategory = Category7;
                    PromotedIsBig = true;
                    ToolTip = 'Show all payments in the list no matter what their status is.';

                    trigger OnAction()
                    begin
                        SetRange(Difference);
                        CurrPage.Update;
                    end;
                }
                action(SortForReviewDescending)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sort for Review Descending';
                    Image = MoveDown;
                    Promoted = true;
                    PromotedCategory = Category7;
                    PromotedIsBig = true;
                    ToolTip = 'Sort the lines in ascending order.';

                    trigger OnAction()
                    begin
                        UpdateSorting(false);
                    end;
                }
                action(SortForReviewAscending)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sort for Review Ascending';
                    Image = MoveUp;
                    Promoted = true;
                    PromotedCategory = Category7;
                    PromotedIsBig = true;
                    ToolTip = 'Sort the lines in descending order.';

                    trigger OnAction()
                    begin
                        UpdateSorting(true);
                    end;
                }
            }
        }
        area(navigation)
        {
            action(Dimensions)
            {
                ApplicationArea = Dimensions;
                Caption = 'Dimensions';
                Image = Dimensions;
                ShortCutKey = 'Alt+D';
                ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                trigger OnAction()
                begin
                    BankAccReconciliation.Get("Statement Type", "Bank Account No.", "Statement No.");
                    BankAccReconciliation.ShowDocDim;
                    CurrPage.SaveRecord;
                end;
            }
            action(LineDimensions)
            {
                ApplicationArea = Dimensions;
                Caption = 'Line Dimensions';
                Image = Dimensions;
                Promoted = true;
                PromotedCategory = Category10;
                ToolTip = 'View or edit the line dimensions sets that are set up for the current line.';

                trigger OnAction()
                begin
                    ShowDimensions;
                end;
            }
            action("Bank Account Card")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bank Account Card';
                Image = BankAccount;
                RunObject = Page "Payment Bank Account Card";
                RunPageLink = "No." = FIELD("Bank Account No.");
                ToolTip = 'View or edit information about the bank account that is related to the payment reconciliation journal.';
            }
            group(Details)
            {
                Caption = 'Details';
                action(ShowBankTransactionDetails)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Transaction Details';
                    Image = ExternalDocument;
                    Promoted = true;
                    PromotedCategory = Category10;
                    PromotedIsBig = true;
                    RunObject = Page "Bank Statement Line Details";
                    RunPageLink = "Data Exch. No." = FIELD("Data Exch. Entry No."),
                                  "Line No." = FIELD("Data Exch. Line No.");
                    ToolTip = 'View the values that exist in an imported bank statement file for the selected line.';
                }
            }
            group("Page")
            {
                Caption = 'Page';
                action(EditInExcel)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Edit in Excel';
                    Image = Excel;
                    Promoted = true;
                    PromotedCategory = Category8;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Send the data in the journal to an Excel file for analysis or editing.';
                    Visible = IsSaaSExcelAddinEnabled;
                    AccessByPermission = System "Allow Action Export To Excel" = X;

                    trigger OnAction()
                    var
                        ODataUtility: Codeunit ODataUtility;
                    begin
                        ODataUtility.EditWorksheetInExcel(CurrPage.Caption, CurrPage.ObjectId(false), '');
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        if not IsBankAccReconInitialized then begin
            BankAccReconciliation.Get("Statement Type", "Bank Account No.", "Statement No.");
            IsBankAccReconInitialized := true;
        end;

        FinanceChargeMemoEnabled := "Account Type" = "Account Type"::Customer;
        BankAccReconciliation.CalcFields("Total Balance on Bank Account", "Total Unposted Applied Amount", "Total Transaction Amount",
          "Total Applied Amount", "Total Outstd Bank Transactions", "Total Outstd Payments", "Total Applied Amount Payments");

        OutstandingTransactions := BankAccReconciliation."Total Outstd Bank Transactions" -
          (BankAccReconciliation."Total Applied Amount" - BankAccReconciliation."Total Unposted Applied Amount") +
          BankAccReconciliation."Total Applied Amount Payments";
        OutstandingPayments := BankAccReconciliation."Total Outstd Payments" - BankAccReconciliation."Total Applied Amount Payments";

        UpdateBalanceAfterPostingStyleExpr;

        TestIfFiltershaveBeenRemovedWithRefreshAndClose;
    end;

    trigger OnAfterGetRecord()
    var
        PaymentMatchingDetails: Record "Payment Matching Details";
    begin
        MatchDetails := PaymentMatchingDetails.MergeMessages(Rec);

        GetAppliedPmtData(AppliedPmtEntry, RemainingAmountAfterPosting, StatementToRemAmtDifference, PmtAppliedToTxt);
        ShowShortcutDimCode(ShortcutDimCode);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        SetUpNewLine;
        AppliedPmtEntry.Init();
        StatementToRemAmtDifference := 0;
        RemainingAmountAfterPosting := 0;
    end;

    trigger OnOpenPage()
    var
        ServerSetting: Codeunit "Server Setting";
    begin
        IsSaaSExcelAddinEnabled := ServerSetting.GetIsSaasExcelAddinEnabled();
        PageClosedByPosting := false;

        SetDimensionsVisibility;

        if BankStatementLinesListIsEmpty("Statement No.", "Statement Type", "Bank Account No.") then
            CreateEmptyListNotification();
    end;

    local procedure CreateEmptyListNotification()
    var
        Notification: Notification;
    begin
        Notification.Id := CreateGuid();
        Notification.Message := ListEmptyMsg;
        Notification.Scope := NotificationScope::LocalScope;
        Notification.Send;
    end;

    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        AppliedPmtEntry: Record "Applied Payment Entry";
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        MatchDetails: Text;
        PmtAppliedToTxt: Label 'The payment has been applied to %1 entries.', Comment = '%1=integer value for number of entries';
        IsBankAccReconInitialized: Boolean;
        StatementToRemAmtDifference: Decimal;
        FinanceChargeMemoEnabled: Boolean;
        RemainingAmountAfterPosting: Decimal;
        RemoveExistingApplicationsQst: Label 'When you run the Apply Automatically action, it will undo all previous applications.\\Do you want to continue?';
        BalanceAfterPostingStyleExpr: Text;
        PageMustCloseMsg: Label 'The Payment Reconciliation Journal window has been closed because the connection was suspended.';
        PageClosedByPosting: Boolean;
        OutstandingTransactions: Decimal;
        OutstandingPayments: Decimal;
        ShortcutDimCode: array[8] of Code[20];
        IsSaaSExcelAddinEnabled: Boolean;
        DimVisible1: Boolean;
        DimVisible2: Boolean;
        DimVisible3: Boolean;
        DimVisible4: Boolean;
        DimVisible5: Boolean;
        DimVisible6: Boolean;
        DimVisible7: Boolean;
        DimVisible8: Boolean;
        ListEmptyMsg: Label 'No bank transaction lines exist. Choose the Import Bank Transactions action to fill in the lines from a file, or enter lines manually.';

    local procedure UpdateSorting(IsAscending: Boolean)
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        PaymentMatchingDetails: Record "Payment Matching Details";
        AppliedPaymentEntry2: Record "Applied Payment Entry";
        AmountDifference: Decimal;
        ScoreRange: Integer;
        SubscriberInvoked: Boolean;
    begin
        BankAccReconciliationLine.SetRange("Statement Type", "Statement Type");
        BankAccReconciliationLine.SetRange("Bank Account No.", "Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement No.", "Statement No.");
        BankAccReconciliationLine.SetAutoCalcFields("Match Confidence");

        if BankAccReconciliationLine.FindSet then begin
            repeat
                ScoreRange := 10000;
                BankAccReconciliationLine."Sorting Order" := BankAccReconciliationLine."Match Confidence" * ScoreRange;

                // Update sorting for same match confidence based onother criteria
                GetAppliedPmtData(AppliedPaymentEntry2, RemainingAmountAfterPosting, AmountDifference, PmtAppliedToTxt);

                ScoreRange := ScoreRange / 10;
                if AmountDifference <> 0 then
                    BankAccReconciliationLine."Sorting Order" -= ScoreRange;

                ScoreRange := ScoreRange / 10;
                if Difference <> 0 then
                    BankAccReconciliationLine."Sorting Order" -= ScoreRange;

                ScoreRange := ScoreRange / 10;
                if PaymentMatchingDetails.MergeMessages(Rec) <> '' then
                    BankAccReconciliationLine."Sorting Order" -= ScoreRange;

                BankAccReconciliationLine.Modify();
            until BankAccReconciliationLine.Next = 0;

            OnUpdateSorting(BankAccReconciliation, SubscriberInvoked);
            if not SubscriberInvoked then
                SetCurrentKey("Sorting Order");
            Ascending(IsAscending);

            CurrPage.Update(false);
            FindFirst;
        end;
    end;

    local procedure InvokePost(OnlyPayments: Boolean)
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconPostYesNo: Codeunit "Bank Acc. Recon. Post (Yes/No)";
    begin
        BankAccReconciliation.Get("Statement Type", "Bank Account No.", "Statement No.");
        BankAccReconciliation."Post Payments Only" := OnlyPayments;

        OnBeforeInvokePost(BankAccReconciliation);
        if BankAccReconPostYesNo.BankAccReconPostYesNo(BankAccReconciliation) then begin
            Reset;
            PageClosedByPosting := true;
            CurrPage.Close;
        end;
    end;

    local procedure UpdateBalanceAfterPostingStyleExpr()
    begin
        with BankAccReconciliation do
            if "Total Balance on Bank Account" + "Total Unposted Applied Amount" <> "Statement Ending Balance" then
                BalanceAfterPostingStyleExpr := 'Unfavorable'
            else
                BalanceAfterPostingStyleExpr := 'Favorable';
    end;

    local procedure TestIfFiltershaveBeenRemovedWithRefreshAndClose()
    begin
        FilterGroup := 2;
        if not PageClosedByPosting then
            if GetFilter("Bank Account No.") + GetFilter("Statement Type") + GetFilter("Statement No.") = '' then begin
                Message(PageMustCloseMsg);
                CurrPage.Close;
            end;
        FilterGroup := 0;
    end;

    local procedure SetDimensionsVisibility()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimVisible1 := false;
        DimVisible2 := false;
        DimVisible3 := false;
        DimVisible4 := false;
        DimVisible5 := false;
        DimVisible6 := false;
        DimVisible7 := false;
        DimVisible8 := false;

        DimMgt.UseShortcutDims(
          DimVisible1, DimVisible2, DimVisible3, DimVisible4, DimVisible5, DimVisible6, DimVisible7, DimVisible8);

        Clear(DimMgt);
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnAtActionApplyAutomatically(BankAccReconciliation: Record "Bank Acc. Reconciliation"; var SubscriberInvoked: Boolean)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    [Scope('OnPrem')]
    procedure OnUpdateSorting(BankAccReconciliation: Record "Bank Acc. Reconciliation"; var SubscriberInvoked: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnAfterImportBankTransactions(var SubscriberInvoked: Boolean; var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var ShortcutDimCode: array[8] of Code[20]; DimIndex: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInvokePost(BankAccReconciliation: Record "Bank Acc. Reconciliation")
    begin
    end;
}

