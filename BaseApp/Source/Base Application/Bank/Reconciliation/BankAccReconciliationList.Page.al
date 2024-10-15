namespace Microsoft.Bank.Reconciliation;

page 388 "Bank Acc. Reconciliation List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Bank Account Reconciliations';
    CardPageID = "Bank Acc. Reconciliation";
    Editable = false;
    PageType = List;
    SourceTable = "Bank Acc. Reconciliation";
#if not CLEAN24
    SourceTableTemporary = true;
#else
    SourceTableView = where("Statement Type" = const("Bank Reconciliation"));
#endif
    UsageCategory = Lists;
    RefreshOnActivate = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(BankAccountNo; Rec."Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the bank account that you want to reconcile with the bank''s statement.';
                }
                field("Bank Account Name"; Rec."Bank Account Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the bank account that you want to reconcile.';
                }
                field(StatementNo; Rec."Statement No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the bank account statement.';
                }
                field(StatementDate; Rec."Statement Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date on the bank account statement.';
                }
                field(BalanceLastStatement; Rec."Balance Last Statement")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ending balance shown on the last bank statement, which was used in the last posted bank reconciliation for this bank account.';
                }
                field(StatementEndingBalance; Rec."Statement Ending Balance")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ending balance shown on the bank''s statement that you want to reconcile with the bank account.';
                }
                field(AllowDuplicatedTransactions; Rec."Allow Duplicated Transactions")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to allow bank account reconciliation lines to have the same transaction ID. Although it’s rare, this is useful when your bank statement file contains transactions with duplicate IDs. Most businesses leave this toggle turned off.';
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
#if not CLEAN24
            group("&Document")
            {
                Caption = '&Document';
                ObsoleteReason = 'Document group in Bank Reconciliation Mgt. is no longer needed and therefore obsoleted.';
                ObsoleteState = Pending;
                ObsoleteTag = '24.0';

                action(NewRec)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'New';
                    Image = NewDocument;
                    ToolTip = 'Create a new bank account reconciliation.';
                    ObsoleteReason = 'Custom NewRec action in Bank Reconciliation Mgt. is no longer supported.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '24.0';

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
                    ObsoleteReason = 'Custom NewRecProcess action in Bank Reconciliation Mgt. is no longer supported.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '24.0';

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
                    ObsoleteReason = 'Custom edit action in Bank Reconciliation Mgt. is no longer supported.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '24.0';

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
                    ObsoleteReason = 'Refresh action in Bank Reconciliation Mgt. is no longer supported.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '24.0';

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
                    ObsoleteReason = 'Custom delete action in Bank Reconciliation Mgt. is no longer supported.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '24.0';

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
#endif
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
#if not CLEAN24
                action(Post)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'P&ost';
                    Image = PostOrder;
                    ShortCutKey = 'F9';
                    ToolTip = 'Finalize the document or journal by posting the amounts and quantities to the related accounts in your company books.';
                    ObsoleteReason = 'Custom post action in Bank Reconciliation Mgt. is no longer supported.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '24.0';

                    trigger OnAction()
                    var
                        BankReconciliationMgt: Codeunit "Bank Reconciliation Mgt.";
                    begin
                        BankReconciliationMgt.Post(
                            Rec,
                            CODEUNIT::"Bank Acc. Recon. Post (Yes/No)",
                            CODEUNIT::"Bank Acc. Recon. Post (Yes/No)"
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
                    ObsoleteReason = 'Custom PostAndPrint action in Bank Reconciliation Mgt. is no longer supported.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '24.0';

                    trigger OnAction()
                    var
                        BankReconciliationMgt: Codeunit "Bank Reconciliation Mgt.";
                    begin
                        BankReconciliationMgt.Post(
                            Rec,
                            CODEUNIT::"Bank Acc. Recon. Post+Print",
                            CODEUNIT::"Bank Acc. Recon. Post+Print"
                        );
                        Refresh();
                    end;
                }
#else
                action(Post)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'P&ost';
                    Image = PostOrder;
                    RunObject = Codeunit "Bank Acc. Recon. Post (Yes/No)";
                    ShortCutKey = 'F9';
                    ToolTip = 'Finalize the document or journal by posting the amounts and quantities to the related accounts in your company books.';
                }
                action(PostAndPrint)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post and &Print';
                    Image = PostPrint;
                    RunObject = Codeunit "Bank Acc. Recon. Post+Print";
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Finalize and prepare to print the document or journal. The values and quantities are posted to the related accounts. A report request window where you can specify what to include on the print-out.';
                }
#endif
            }
            action(ChangeStatementNo)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Change Statement No.';
                Ellipsis = true;
                Image = ChangeTo;
                ToolTip = 'Change the statement number of the bank account reconciliation. Typically, this is used when you have created a new reconciliation to correct a mistake, and you want to use the same statement number.';

                trigger OnAction()
                var
                    BankAccReconciliation: Record "Bank Acc. Reconciliation";
                begin
                    BankAccReconciliation := Rec;
                    Codeunit.Run(Codeunit::"Change Bank Rec. Statement No.", BankAccReconciliation);
                    Rec := BankAccReconciliation;
#if not CLEAN24
                    Refresh();
#endif
                end;
            }
        }
        area(Prompting)
        {
        }
        area(Promoted)
        {
            group(Category_New)
            {
                Caption = 'New', Comment = 'Generated from the PromotedActionCategories property index 0.';
#if not CLEAN24
                actionref(NewRec_Promoted; NewRec)
                {
                    ObsoleteReason = 'Custom NewRec action in Bank Reconciliation Mgt. is no longer supported.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '24.0';
                }
#endif
            }
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                group(Category_Posting)
                {
                    Caption = 'Posting';
                    ShowAs = SplitButton;

                    actionref(Post_Promoted; Post)
                    {
                    }
                    actionref(PostAndPrint_Promoted; PostAndPrint)
                    {
                    }
                }
                actionref(ChangeStatementNo_Promoted; ChangeStatementNo)
                {
                }
#if not CLEAN24
                actionref(NewRecProcess_Promoted; NewRecProcess)
                {
                    ObsoleteReason = 'Custom NewRecProcess action in Bank Reconciliation Mgt. is no longer supported.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '24.0';
                }
                actionref(EditRec_Promoted; EditRec)
                {
                    ObsoleteReason = 'Custom edit action in Bank Reconciliation Mgt. is no longer supported.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '24.0';
                }
                actionref(RefreshList_Promoted; RefreshList)
                {
                    ObsoleteReason = 'Refresh action in Bank Reconciliation Mgt. is no longer supported.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '24.0';
                }
                actionref(DeleteRec_Promoted; DeleteRec)
                {
                    ObsoleteReason = 'Custom delete action in Bank Reconciliation Mgt. is no longer supported.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '24.0';
                }
#endif
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
#if not CLEAN22
            group(Category_Category4)
            {
                Caption = 'Posting', Comment = 'Generated from the PromotedActionCategories property index 3.';
                ObsoleteState = Pending;
                ObsoleteReason = 'Category_Category4 has been replaced by Category_Posting.';
                ObsoleteTag = '22.0';
            }
#endif
        }
    }

#if not CLEAN24
    trigger OnInit()
    begin
        UseSharedTable := true;
    end;

    trigger OnOpenPage()
    begin
        Refresh();
    end;

    var
        UseSharedTable: Boolean;
        DeleteConfirmQst: Label 'Do you want to delete the Reconciliation?';

    local procedure Refresh()
    var
        BankReconciliationMgt: Codeunit "Bank Reconciliation Mgt.";
    begin
        Rec.DeleteAll();
        BankReconciliationMgt.Refresh(Rec);
    end;
#endif
}

