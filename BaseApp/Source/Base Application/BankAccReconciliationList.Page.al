page 388 "Bank Acc. Reconciliation List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Bank Account Reconciliations';
    Editable = false;
    PageType = List;
    SourceTable = "Bank Acc. Reconciliation";
    SourceTableTemporary = true;
    UsageCategory = Lists;
    RefreshOnActivate = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(BankAccountNo; "Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the bank account that you want to reconcile with the bank''s statement.';
                }
                field("Bank Account Name"; "Bank Account Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the bank account that you want to reconcile.';
                }
                field(StatementNo; "Statement No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the bank account statement.';
                }
                field(StatementDate; "Statement Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date on the bank account statement.';
                }
                field(BalanceLastStatement; "Balance Last Statement")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ending balance shown on the last bank statement, which was used in the last posted bank reconciliation for this bank account.';
                }
                field(StatementEndingBalance; "Statement Ending Balance")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ending balance shown on the bank''s statement that you want to reconcile with the bank account.';
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
            group("&Document")
            {
                Caption = '&Document';
                action(NewRec)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'New';
                    Image = NewDocument;
                    ToolTip = 'Create a new bank account reconciliation.';
                    Visible = false;

                    trigger OnAction()
                    var
                        BankReconciliationMgt: Codeunit "Bank Reconciliation Mgt.";
                    begin
                        BankReconciliationMgt.New(Rec, UseSharedTable);
                    end;
                }

                action(NewRecProcess)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'New';
                    Image = NewDocument;
                    ToolTip = 'Create a new bank account reconciliation.';

                    trigger OnAction()
                    var
                        BankReconciliationMgt: Codeunit "Bank Reconciliation Mgt.";
                    begin
                        BankReconciliationMgt.New(Rec, UseSharedTable);
                    end;
                }
                action(EditRec)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Edit';
                    Image = EditLines;
                    ShortCutKey = 'Return';
                    ToolTip = 'Edit the bank account reconciliation list.';

                    trigger OnAction()
                    var
                        BankReconciliationMgt: Codeunit "Bank Reconciliation Mgt.";
                    begin
                        BankReconciliationMgt.Edit(Rec, UseSharedTable);
                    end;
                }
                action(RefreshList)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Refresh';
                    Image = RefreshLines;
                    ToolTip = 'Update the data with any changes made by other users since you opened the window.';

                    trigger OnAction()
                    begin
                        Refresh();
                    end;
                }
                action(DeleteRec)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Delete';
                    Image = Delete;
                    ToolTip = 'Delete the bank account reconciliation.';

                    trigger OnAction()
                    var
                        BankReconciliationMgt: Codeunit "Bank Reconciliation Mgt.";
                    begin
                        if not Confirm(DeleteConfirmQst) then
                            exit;

                        BankReconciliationMgt.Delete(Rec);
                        Refresh();
                    end;
                }
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action(Post)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'P&ost';
                    Image = PostOrder;
                    ShortCutKey = 'F9';
                    ToolTip = 'Finalize the document or journal by posting the amounts and quantities to the related accounts in your company books.';
                    trigger OnAction()
                    var
                        BankReconciliationMgt: Codeunit "Bank Reconciliation Mgt.";
                    begin
                        BankReconciliationMgt.Post(
                            Rec,
                            CODEUNIT::"Bank Acc. Recon. Post (Yes/No)",
#if not CLEAN21
                            CODEUNIT::"Bank Rec.-Post (Yes/No)"
#else
                            CODEUNIT::"Bank Acc. Recon. Post (Yes/No)"
#endif
                        );
                        Refresh();
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
                    var
                        BankReconciliationMgt: Codeunit "Bank Reconciliation Mgt.";
                    begin
                        BankReconciliationMgt.Post(
                            Rec,
                            CODEUNIT::"Bank Acc. Recon. Post+Print",
#if not CLEAN21
                            CODEUNIT::"Bank Rec.-Post + Print"
#else
                            CODEUNIT::"Bank Acc. Recon. Post+Print"
#endif
                        );
                        Refresh();
                    end;
                }
            }
            action(ChangeStatementNo)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Change Statement No.';
                Ellipsis = true;
                Image = ChangeTo;
#if not CLEAN20
                Visible = ChangeStatementNoVisible;
#endif                
                ToolTip = 'Change the statement number of the bank account reconciliation. Typically, this is used when you have created a new reconciliation to correct a mistake, and you want to use the same statement number.';

                trigger OnAction()
                var
                    BankAccReconciliation: Record "Bank Acc. Reconciliation";
                begin
                    BankAccReconciliation := Rec;
                    Codeunit.Run(Codeunit::"Change Bank Rec. Statement No.", BankAccReconciliation);
                    Rec := BankAccReconciliation;
                    Refresh();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_New)
            {
                Caption = 'New', Comment = 'Generated from the PromotedActionCategories property index 0.';

                actionref(NewRec_Promoted; NewRec)
                {
                }
            }
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(NewRecProcess_Promoted; NewRecProcess)
                {
                }
                actionref(EditRec_Promoted; EditRec)
                {
                }
                actionref(RefreshList_Promoted; RefreshList)
                {
                }
                actionref(DeleteRec_Promoted; DeleteRec)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
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
            }
        }
    }

    trigger OnInit()
    begin
        UseSharedTable := true;
    end;

    trigger OnOpenPage()
    begin
        Refresh();
#if not CLEAN20
        SetChangeStatementNoVisible();
#endif                
    end;

    var
        UseSharedTable: Boolean;
#if not CLEAN20
        ChangeStatementNoVisible: Boolean;
#endif                
        DeleteConfirmQst: Label 'Do you want to delete the Reconciliation?';

#if not CLEAN20
    local procedure SetChangeStatementNoVisible()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        ChangeStatementNoVisible := GLSetup."Bank Recon. with Auto. Match";
    end;
#endif                

    local procedure Refresh()
    var
        BankReconciliationMgt: Codeunit "Bank Reconciliation Mgt.";
    begin
        DeleteAll();
        BankReconciliationMgt.Refresh(Rec);
    end;
}

