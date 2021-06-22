page 389 "Bank Account Statement List"
{
    Caption = 'Bank Account Statement List';
    CardPageID = "Bank Account Statement";
    Editable = false;
    PageType = List;
    SourceTable = "Bank Account Statement";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Bank Account No."; "Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the bank account that has been reconciled with this Bank Account Statement.';
                }
                field("Statement No."; "Statement No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the bank''s statement that has been reconciled with the bank account.';
                }
                field("Statement Date"; "Statement Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date on the bank''s statement that has been reconciled with the bank account.';
                }
                field("Balance Last Statement"; "Balance Last Statement")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ending balance on the bank account statement from the last posted bank account reconciliation.';
                }
                field("Statement Ending Balance"; "Statement Ending Balance")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ending balance on the bank''s statement that has been reconciled with the bank account.';
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
        area(processing)
        {
            group(Functions)
            {
                Caption = 'Functions';
                action(Undo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Undo';
                    Image = Undo;
                    Promoted = true;
                    PromotedOnly = true;
                    PromotedCategory = Process;
                    ToolTip = 'Reverse this bank statement and automatically create a new bank reconciliation with the same information so you can correct it before posting. This bank statement will be deleted.';

                    trigger OnAction()
                    var
                        UndoBankStatementYesNo: Codeunit "Undo Bank Statement (Yes/No)";
                    begin
                        UndoBankStatementYesNo.Run(Rec);
                    end;
                }
            }
        }
        area(reporting)
        {
            action(Print)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Scope = Repeater;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                var
                    DocPrint: Codeunit "Document-Print";
                begin
                    DocPrint.PrintBankAccStmt(Rec);
                end;
            }
        }
    }
}

