#if not CLEAN19
page 11711 "Issued Bank Statement"
{
    Caption = 'Issued Bank Statement (Obsolete)';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = "Issued Bank Statement Header";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
    ObsoleteTag = '19.0';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the bank statement.';
                }
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the name of bank account.';
                }
                field("Bank Account Name"; Rec."Bank Account Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of bank account.';
                }
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number used by the bank for the bank account.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date on which you created the document.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the currency of amounts on the document.';
                }
                field("Bank Statement Currency Code"; Rec."Bank Statement Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the bank statement currency code which is setup in the bank card.';
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the external document number received from bank.';
                }
                field("No. of Lines"; Rec."No. of Lines")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of lines in the bank statement.';
                }
                field("Payment Reconciliation Status"; Rec."Payment Reconciliation Status")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies payment reconciliation status';
                }
            }
            part(Lines; "Issued Bank Statement Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Bank Statement No." = FIELD("No.");
            }
            group("Debit/Credit")
            {
                Caption = 'Debit/Credit';
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount for bank statement lines. The program calculates this amount from the sum of line amount fields on bank statement lines.';
                }
                field(Debit; Debit)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount that the line consists of, if it is a debit amount.';
                }
                field(Credit; Credit)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount that the line consists of, if it is a credit amount.';
                }
                field("Amount (LCY)"; Rec."Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount that the line consists of. The amount is in the local currency.';
                }
                field("Debit (LCY)"; Rec."Debit (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount that the line consists of, if it is a debit amount. The amount is in the local currency.';
                }
                field("Credit (LCY)"; Rec."Credit (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount that the line consists of, if it is a credit amount. The amount is in the local currency.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1220033; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1220032; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Bank statement")
            {
                Caption = '&Bank statement';
                action(Statistics)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Issued Bank Statement Stat.";
                    RunPageLink = "No." = FIELD("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View the statistics on the selected bank statement.';
                }
                action("Payment Reconciliation Journal")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payment Reconciliation Journal';
                    Image = OpenJournal;
                    ToolTip = 'Open the payment reconciliation journal.';

                    trigger OnAction()
                    begin
                        OpenPmtReconOrPostedPmtRecon();
                    end;
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                action("Create Payment Recon. Journal")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create Payment Recon. Journal';
                    Ellipsis = true;
                    Image = PaymentJournal;
                    ToolTip = 'The batch job create payment reconciliation journal.';

                    trigger OnAction()
                    begin
                        CreatePaymentReconJournal();
                    end;
                }
            }
            group("&Print")
            {
                Caption = '&Print';
                action("Test Report")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'Specifies test report';

                    trigger OnAction()
                    begin
                        TestPrintBankStatement();
                    end;
                }
                action("Bank Statement")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Statement';
                    Ellipsis = true;
                    Image = PrintReport;
                    ToolTip = 'Open the report for issued bank statement line.';

                    trigger OnAction()
                    begin
                        PrintBankStatement();
                    end;
                }
            }
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                begin
                    Navigate();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
                actionref(Statistics_Promoted; Statistics)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        FilterGroup(2);
        if not (GetFilter("Bank Account No.") <> '') then begin
            if "Bank Account No." <> '' then
                SetRange("Bank Account No.", "Bank Account No.");
        end;
        FilterGroup(0);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        FilterGroup := 2;
        Validate("Bank Account No.", GetFilter("Bank Account No."));
        FilterGroup := 0;
    end;

    local procedure PrintBankStatement()
    var
        IssuedBankStmtHdr: Record "Issued Bank Statement Header";
    begin
        CurrPage.SetSelectionFilter(IssuedBankStmtHdr);
        IssuedBankStmtHdr.PrintRecords(true);
    end;

    local procedure TestPrintBankStatement()
    var
        IssuedBankStmtHdr: Record "Issued Bank Statement Header";
    begin
        CurrPage.SetSelectionFilter(IssuedBankStmtHdr);
        IssuedBankStmtHdr.TestPrintRecords(true);
    end;

    local procedure CreatePaymentReconJournal()
    var
        IssuedBankStmtHdr: Record "Issued Bank Statement Header";
    begin
        CurrPage.SetSelectionFilter(IssuedBankStmtHdr);
        IssuedBankStmtHdr.CreatePmtReconJnl(true);
    end;
}
#endif
