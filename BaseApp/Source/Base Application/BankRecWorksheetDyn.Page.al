#if not CLEAN21
page 36720 "Bank Rec. Worksheet Dyn"
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
                    ToolTip = 'Specifies the code for the bank account the reconciliation applies to.';
                }
                field("Statement No."; Rec."Statement No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the statement number to be reconciled.';
                }
                field("Statement Date"; Rec."Statement Date")
                {
                    ApplicationArea = Basic, Suite;
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
                field("Statement Balance"; Rec."Statement Balance")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Balance on Statement';
                    ToolTip = 'Specifies the amount entered by the operator from the balance found on the bank statement.';
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
                field("(""Statement Balance"" + ""Outstanding Deposits"") - ""Outstanding Checks"""; ("Statement Balance" + "Outstanding Deposits") - "Outstanding Checks")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ending Balance';
                    Editable = false;
                    ToolTip = 'Specifies the sum of values in the Balance on Statement field, plus the Outstanding Deposits field, minus the Outstanding Checks field.';
                }
                field("Currency Factor"; Rec."Currency Factor")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies currency conversions when posting adjustments for bank accounts with a foreign currency code assigned.';
                }
            }
            group(Checks)
            {
                Caption = 'Checks';
                part(ChecksSubForm; "Bank Rec. Check Lines Subform")
                {
                    ApplicationArea = Basic, Suite;
                    SubPageLink = "Bank Account No." = FIELD("Bank Account No."),
                                  "Statement No." = FIELD("Statement No.");
                }
            }
            group("Deposits/Transfers")
            {
                Caption = 'Deposits/Transfers';
                part(DepositsSubForm; "Bank Rec. Dep. Lines Subform")
                {
                    ApplicationArea = Basic, Suite;
                    SubPageLink = "Bank Account No." = FIELD("Bank Account No."),
                                  "Statement No." = FIELD("Statement No.");
                }
            }
            group(Adjustments)
            {
                Caption = 'Adjustments';
                part(AdjustmentsSubForm; "Bank Rec. Adj. Lines Subform")
                {
                    ApplicationArea = Basic, Suite;
                    SubPageLink = "Bank Account No." = FIELD("Bank Account No."),
                                  "Statement No." = FIELD("Statement No.");
                }
            }
        }
        area(factboxes)
        {
            part(Control1905344207; "Bank Rec Worksheet FactBox")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                SubPageLink = "Bank Account No." = FIELD("Bank Account No."),
                              "Statement No." = FIELD("Statement No.");
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
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Suggest Lines")
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
                action("Mark Lines")
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
                action("Recalc &G/L Balance")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Recalc &G/L Balance';
                    ToolTip = 'Calculate the G/L balance again.';

                    trigger OnAction()
                    begin
                        RecalcGLBalance();
                    end;
                }
                separator(Action1480000)
                {
                }
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action("Test Report")
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
                action("P&ost")
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
                    end;
                }
                action("Post and &Print")
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
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("P&ost_Promoted"; "P&ost")
                {
                }
                actionref("Post and &Print_Promoted"; "Post and &Print")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        AfterGetCurrentRecord();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        AfterGetCurrentRecord();
    end;

    var
        ReportPrint: Codeunit "Test Report-Print";
        Text001: Label 'Do you want to recalculate the G/L Balance from the General Ledger?';

    procedure SetupRecord()
    begin
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
}

#endif