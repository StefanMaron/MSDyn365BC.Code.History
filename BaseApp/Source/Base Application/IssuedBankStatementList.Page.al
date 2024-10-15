#if not CLEAN19
page 11714 "Issued Bank Statement List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Issued Bank Statements (Obsolete)';
    CardPageID = "Issued Bank Statement";
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Issued Bank Statement Header";
    UsageCategory = History;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
    ObsoleteTag = '19.0';

    layout
    {
        area(content)
        {
            repeater(Control1220008)
            {
                Editable = false;
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the bank statement.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date on which you created the document.';
                }
                field("Bank Account No."; "Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of bank account.';
                    Visible = false;
                }
                field("Bank Account Name"; "Bank Account Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of bank account.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount for bank statement lines. The program calculates this amount from the sum of line amount fields on bank statement lines.';
                }
                field("Amount (LCY)"; "Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount that the line consists of. The amount is in the local currency.';
                }
                field("No. of Lines"; "No. of Lines")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of lines in the bank statement.';
                }
                field("File Name"; "File Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name and address of bank statement file uploaded from bank.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1220020; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1220019; Notes)
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
                    Promoted = true;
                    PromotedCategory = Process;
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
                        OpenPmtReconOrPostedPmtRecon;
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
                        CreatePaymentReconJournal;
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
                        TestPrintBankStatement;
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
                        PrintBankStatement;
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        BankStatementMgt: Codeunit "Bank Statement Management";
        StatSelected: Boolean;
    begin
        BankStatementMgt.IssuedBankStatementSelection(Rec, StatSelected);
        if not StatSelected then
            Error('');
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
        OnBeforeCreatePaymentReconJournal(Rec, IssuedBankStmtHdr);

        CurrPage.SetSelectionFilter(IssuedBankStmtHdr);
        IssuedBankStmtHdr.CreatePmtReconJnl(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePaymentReconJournal(IssuedBankStmtHdrOrig: record "Issued Bank Statement Header"; var IssuedBankStmtHdr: record "Issued Bank Statement Header")
    begin
    end;
}
#endif
