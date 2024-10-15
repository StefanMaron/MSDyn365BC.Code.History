#if not CLEAN21
page 10120 "Bank Rec. Worksheet"
{
    Caption = 'Bank Rec. Worksheet';
    PageType = Card;
    RefreshOnActivate = true;
    SourceTable = "Bank Rec. Header";
    ObsoleteReason = 'Deprecated in favor of W1 Bank Reconciliation';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the code for the bank account the reconciliation applies to.';
                }
                field("Statement No."; Rec."Statement No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    Editable = false;
                    ToolTip = 'Specifies the statement number to be reconciled.';
                }
                field("Statement Date"; Rec."Statement Date")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the as-of date of the statement. All G/L balances will be calculated based upon this date.';
                }
                field("G/L Balance (LCY)"; Rec."G/L Balance (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the general ledger balance for the assigned account number.';
                }
                field("G/L Balance"; Rec."G/L Balance")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the general ledger balance for the assigned account number.';
                }
                field("""Positive Adjustments"" - ""Negative Bal. Adjustments"""; Rec."Positive Adjustments" - "Negative Bal. Adjustments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '+ Positive Adjustments';
                    Editable = false;
                    ToolTip = 'Specifies the total amount of positive adjustments for the bank statement.';
                }
                field("""G/L Balance"" + (""Positive Adjustments"" - ""Negative Bal. Adjustments"")"; Rec."G/L Balance" + ("Positive Adjustments" - "Negative Bal. Adjustments"))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Subtotal';
                    Editable = false;
                    ToolTip = 'Specifies a subtotal amount for the posted worksheet. The subtotal is calculated by using the general ledger balance and any positive or negative adjustments.';
                }
                field("""Negative Adjustments"" - ""Positive Bal. Adjustments"""; Rec."Negative Adjustments" - "Positive Bal. Adjustments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '- Negative Adjustments';
                    Editable = false;
                    ToolTip = 'Specifies the total of the negative adjustment lines for the bank statement.';
                }
                field("Ending G/L Balance"; Rec."G/L Balance" + ("Positive Adjustments" - "Negative Bal. Adjustments") + ("Negative Adjustments" - "Positive Bal. Adjustments"))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ending G/L Balance';
                    Editable = false;
                    ToolTip = 'Specifies the sum of values in the G/L Balance field, plus the Positive Adjustments field, minus the Negative Adjustments field. This is what the G/L balance will be after the bank reconciliation worksheet is posted and the adjustments are posted to the general ledger.';
                }
                field(Difference; ("G/L Balance" + ("Positive Adjustments" - "Negative Bal. Adjustments") + ("Negative Adjustments" - "Positive Bal. Adjustments")) - (("Statement Balance" + "Outstanding Deposits") - "Outstanding Checks"))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Difference';
                    Editable = false;
                    ToolTip = 'Specifies the difference between the Amount field and the Cleared Amount field.';
                }
                field("Cleared With./Chks. Per Stmnt."; Rec."Cleared With./Chks. Per Stmnt.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of withdrawals or checks that cleared the bank for this statement.';
                }
                field("Cleared Inc./Dpsts. Per Stmnt."; Rec."Cleared Inc./Dpsts. Per Stmnt.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of increases or deposits that cleared the bank for this statement.';
                }
                field(BalanceOnStatement; "Statement Balance")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Balance on Statement';
                    ToolTip = 'Specifies the amount entered by the operator from the balance found on the bank statement.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Outstanding Deposits"; Rec."Outstanding Deposits")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '+ Outstanding Deposits';
                    Editable = false;
                    ToolTip = 'Specifies the total of outstanding deposits of type Increase for the bank statement.';
                }
                field("""Statement Balance"" + ""Outstanding Deposits"""; Rec."Statement Balance" + "Outstanding Deposits")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Subtotal';
                    Editable = false;
                    ToolTip = 'Specifies a subtotal amount for the posted worksheet. The subtotal is calculated by using the general ledger balance and any positive or negative adjustments.';
                }
                field("Outstanding Checks"; Rec."Outstanding Checks")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '- Outstanding Checks';
                    Editable = false;
                    ToolTip = 'Specifies the total of outstanding check withdrawals for the bank statement.';
                }
                field(CalculateEndingBalance; CalculateEndingBalance())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ending Balance';
                    Editable = false;
                    ToolTip = 'Specifies the sum of values in the Balance on Statement field, plus the Outstanding Deposits field, minus the Outstanding Checks field.';
                }
            }
            part(ChecksSubForm; "Bank Rec. Check Lines Subform")
            {
                Caption = 'Checks';
                ApplicationArea = Basic, Suite;
                SubPageLink = "Bank Account No." = FIELD("Bank Account No."),
                                  "Statement No." = FIELD("Statement No.");
            }
            group(Checks)
            {
                // the subpage above is moved out of this group to enable focus mode for the part
            }
            part(DepositsSubForm; "Bank Rec. Dep. Lines Subform")
            {
                Caption = 'Deposits/Transfers';
                ApplicationArea = Basic, Suite;
                SubPageLink = "Bank Account No." = FIELD("Bank Account No."),
                                  "Statement No." = FIELD("Statement No.");
            }
            group("Deposits/Transfers")
            {
                // the subpage above is moved out of this group to enable focus mode for the part
            }
            part(AdjustmentsSubForm; "Bank Rec. Adj. Lines Subform")
            {
                Caption = 'Adjustments';
                ApplicationArea = Basic, Suite;
                SubPageLink = "Bank Account No." = FIELD("Bank Account No."),
                                  "Statement No." = FIELD("Statement No.");
            }
            group(Adjustments)
            {
                // the subpage above is moved out of this group to enable focus mode for the part
            }
            group("Control Info")
            {
                Caption = 'Control Info';
                field("Bank Account No.2"; Rec."Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Lookup = false;
                    Visible = false;
                    ToolTip = 'Specifies the code for the bank account the reconciliation applies to.';
                }
                field("Statement No.2"; Rec."Statement No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Visible = false;
                    ToolTip = 'Specifies the statement number to be reconciled.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the currency code assigned to the bank account.';
                }
                field("Currency Factor"; Rec."Currency Factor")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies currency conversions when posting adjustments for bank accounts with a foreign currency code assigned.';
                }
                field("Statement Date2"; Rec."Statement Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Visible = false;
                    ToolTip = 'Specifies the as-of date of the statement. All G/L balances will be calculated based upon this date.';
                }
                field("Date Created"; Rec."Date Created")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies a date automatically populated when the record is created.';
                }
                field("Time Created"; Rec."Time Created")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the time created, which is automatically populated when the record is created.';
                }
                field("Created By"; Rec."Created By")
                {
                    ApplicationArea = Basic, Suite;
                    AssistEdit = false;
                    DrillDown = false;
                    Editable = false;
                    Lookup = false;
                    ToolTip = 'Specifies the User ID of the person who created the record.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Editable = false;
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Bank Rec.")
            {
                Caption = '&Bank Rec.';
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Bank Comment Sheet";
                    RunPageLink = "Bank Account No." = FIELD("Bank Account No."),
                                  "No." = FIELD("Statement No.");
                    RunPageView = WHERE("Table Name" = CONST("Bank Rec."));
                    ToolTip = 'View comments that apply.';
                }
                action("C&ard")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'C&ard';
                    Image = EditLines;
                    RunObject = Page "Bank Account Card";
                    RunPageLink = "No." = FIELD("Bank Account No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the card for the bank account that is being reconciled. ';
                }
            }
        }
        area(reporting)
        {
            action(BankRecTestReport)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bank Rec. Test Report';
                Image = "Report";
                ToolTip = 'View a preliminary draft of the bank reconciliation statement. You can preview, print, or save the bank reconciliation test statement in several file formats. This step in the bank reconciliation process allows you to test the bank reconciliation statement entries for accuracy prior to posting the bank reconciliation statement.';

                trigger OnAction()
                var
                    BankRecHdr: Record "Bank Rec. Header";
                begin
                    BankRecHdr := Rec;
                    BankRecHdr.SetRecFilter();
                    REPORT.Run(REPORT::"Bank Rec. Test Report", true, false, BankRecHdr);
                end;
            }
            action("Bank Account - Reconcile")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bank Account - Reconcile';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Bank Account - Reconcile";
                ToolTip = 'Reconcile bank transactions with bank account ledger entries to ensure that your bank account in Dynamics NAV reflects your actual liquidity.';
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
                    Image = SuggestReconciliationLines;
                    ToolTip = 'Add deposit lines to the worksheet that have identical external document numbers.';

                    trigger OnAction()
                    begin
                        RunProcessLines(0);
                    end;
                }
                action(MarkLines)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Mark Lines';
                    Ellipsis = true;
                    ToolTip = 'Mark transactions that you want to reconcile.';

                    trigger OnAction()
                    begin
                        RunProcessLines(1);
                    end;
                }
                action(ClearLines)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Clear Lines';
                    Ellipsis = true;
                    ToolTip = 'Delete the selected worksheet lines.';

                    trigger OnAction()
                    begin
                        RunProcessLines(3);
                    end;
                }
                action(RecordAdjustments)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Record Adjustments';
                    Ellipsis = true;
                    Image = AdjustEntries;
                    ToolTip = 'Create adjustments because company and bank values differ.';

                    trigger OnAction()
                    begin
                        RunProcessLines(2);
                    end;
                }
                separator(Action1020070)
                {
                }
                action(RecalculateGLBalance)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Recalc &G/L Balance';
                    ToolTip = 'Calculate the G/L balance again.';

                    trigger OnAction()
                    begin
                        RecalcGLBalance();
                    end;
                }
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action(TestReport)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'View a test report so that you can find and correct any errors before you perform the actual posting of the journal or document.';

                    trigger OnAction()
                    begin
                        ReportPrint.PrintBankRec(Rec);
                    end;
                }
                action(Post)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'P&ost';
                    Image = Post;
                    ShortCutKey = 'F9';
                    ToolTip = 'Finalize the document or journal by posting the amounts and quantities to the related accounts in your company books.';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Bank Rec.-Post (Yes/No)", Rec);
                        CurrPage.Update(false);
                        RefreshSharedTempTable();
                    end;
                }
                action(PostAndPrint)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post and &Print';
                    Image = PostPrint;
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Finalize and prepare to print the document or journal. The values and quantities are posted to the related accounts. A report request window where you can specify what to include on the print-out.';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Bank Rec.-Post + Print", Rec);
                        CurrPage.Update(false);
                        RefreshSharedTempTable();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(SuggestLines_Promoted; SuggestLines)
                {
                }
                actionref(MarkLines_Promoted; MarkLines)
                {
                }
                actionref(ClearLines_Promoted; ClearLines)
                {
                }
                actionref(RecordAdjustments_Promoted; RecordAdjustments)
                {
                }
                actionref(RecalculateGLBalance_Promoted; RecalculateGLBalance)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';

                actionref(BankRecTestReport_Promoted; BankRecTestReport)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Posting', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(Post_Promoted; Post)
                {
                }
                actionref(PostAndPrint_Promoted; PostAndPrint)
                {
                }
                actionref(TestReport_Promoted; TestReport)
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Bank Rec.', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        AfterGetCurrentRecord();
    end;

    trigger OnClosePage()
    begin
        RefreshSharedTempTable();
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        RefreshSharedTempTable();
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Modify(true);
        RefreshSharedTempTable();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        AfterGetCurrentRecord();
        RefreshSharedTempTable();
    end;

    trigger OnOpenPage()
    begin
        RefreshSharedTempTable();
        BankRecWkshNotification.ShowBankRecWorksheetUIImprovementNotification();
#if not CLEAN21
        BankDepositFeatureMgt.LaunchDeprecationNotification();
#endif
    end;

    var
        TempBankAccReconciliationDataset: Record "Bank Acc. Reconciliation" temporary;
#if not CLEAN21
        BankDepositFeatureMgt: Codeunit "Bank Deposit Feature Mgt.";
#endif
        ReportPrint: Codeunit "Test Report-Print";
        BankRecWkshNotification: Codeunit "Bank Rec. Wksh. Notification";
        Text001: Label 'Do you want to recalculate the G/L Balance from the General Ledger?';

    procedure SetupRecord()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetupRecord(Rec, IsHandled);
        if IsHandled then
            exit;

        SetRange("Date Filter", "Statement Date");
        CalcFields("Positive Adjustments",
          "Negative Adjustments",
          "Positive Bal. Adjustments",
          "Negative Bal. Adjustments");
    end;

    procedure RunProcessLines(ActionToTake: Option "Suggest Lines","Mark Lines","Record Adjustments","Clear Lines")
    var
        ProcessLines: Report "Bank Rec. Process Lines";
    begin
        case ActionToTake of
            ActionToTake::"Suggest Lines":
                ProcessLines.SetDoSuggestLines(true, "Bank Account No.", "Statement No.");
            ActionToTake::"Mark Lines":
                ProcessLines.SetDoMarkLines(true, "Bank Account No.", "Statement No.");
            ActionToTake::"Record Adjustments":
                ProcessLines.SetDoAdjLines(true, "Bank Account No.", "Statement No.");
            ActionToTake::"Clear Lines":
                ProcessLines.SetDoClearLines(true, "Bank Account No.", "Statement No.");
        end;
        ProcessLines.SetTableView(Rec);
        ProcessLines.RunModal();
        DoRecalc();
    end;

    procedure RecalcGLBalance()
    begin
        if Confirm(Text001, true) then
            DoRecalc();
    end;

    procedure DoRecalc()
    begin
        CalculateBalance();
        CurrPage.Update();
    end;

    local procedure AfterGetCurrentRecord()
    begin
        xRec := Rec;
        SetupRecord();
    end;

    procedure SetSharedTempTable(var TempBankAccReconciliationOnList: Record "Bank Acc. Reconciliation" temporary)
    begin
        TempBankAccReconciliationDataset.Copy(TempBankAccReconciliationOnList, true);
    end;

    local procedure RefreshSharedTempTable()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
    begin
        TempBankAccReconciliationDataset.DeleteAll();
        BankAccReconciliation.GetTempCopyFromBankRecHeader(TempBankAccReconciliationDataset);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetupRecord(var BankRecHeader: Record "Bank Rec. Header"; var IsHandled: Boolean)
    begin
    end;
}

#endif