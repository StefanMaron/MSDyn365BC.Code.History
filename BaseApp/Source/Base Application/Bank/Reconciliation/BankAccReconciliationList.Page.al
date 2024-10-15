﻿namespace Microsoft.Bank.Reconciliation;

page 388 "Bank Acc. Reconciliation List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Bank Account Reconciliations';
    CardPageID = "Bank Acc. Reconciliation";
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
}

