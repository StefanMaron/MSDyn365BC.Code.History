page 11709 "Bank Statement List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Bank Statements';
    CardPageID = "Bank Statement";
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Bank Statement Header";
    UsageCategory = Lists;

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
                }
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
                    RunObject = Page "Bank Statement Statistics";
                    RunPageLink = "No." = FIELD("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View the statistics on the selected bank statement.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                action("Bank Stetement Import")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Stetement Import';
                    Ellipsis = true;
                    Image = Import;
                    ToolTip = 'Allows import bank statement in the system.';

                    trigger OnAction()
                    begin
                        ImportBankStatement;
                    end;
                }
                action("Copy Payment Order")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Copy Payment Order';
                    Ellipsis = true;
                    Image = CopyDocument;
                    ToolTip = 'Allows copy payment order in the bank statement.';

                    trigger OnAction()
                    begin
                        CopyPaymentOrder;
                    end;
                }
            }
            group("&Release")
            {
                Caption = '&Release';
                action("Test Report")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'Report Specifies how the bank statement entries will be applied.';

                    trigger OnAction()
                    begin
                        TestPrintBankStatement;
                    end;
                }
                action(Release)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Release';
                    Image = ReleaseDoc;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Codeunit "Issue Bank Statement (Yes/No)";
                    ShortCutKey = 'F9';
                    ToolTip = 'Release the bank statement to indicate that it has been printed or exported. The status then changes to Released.';
                }
                action("Release and &Print")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Release and &Print';
                    Image = ConfirmAndPrint;
                    RunObject = Codeunit "Issue Bank Statement + Print";
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Release and print the bank statement. The status then changes to Released.';
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        BankStatementMgt: Codeunit "Bank Statement Management";
        StatSelected: Boolean;
    begin
        BankStatementMgt.BankStatementSelection(Rec, StatSelected);
        if not StatSelected then
            Error('');
    end;

    local procedure CopyPaymentOrder()
    var
        BankStmtHdr: Record "Bank Statement Header";
        CopyPaymentOrder: Report "Copy Payment Order";
    begin
        BankStmtHdr.Get("No.");
        BankStmtHdr.SetRecFilter;
        CopyPaymentOrder.SetBankStmtHdr(BankStmtHdr);
        CopyPaymentOrder.RunModal;
        CurrPage.Update(false);
    end;

    local procedure TestPrintBankStatement()
    var
        BankStmtHdr: Record "Bank Statement Header";
    begin
        CurrPage.SetSelectionFilter(BankStmtHdr);
        BankStmtHdr.TestPrintRecords(true);
    end;
}

