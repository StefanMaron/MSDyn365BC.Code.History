﻿page 9030 "Account Manager Activities"
{
    Caption = 'Activities';
    PageType = CardPart;
    RefreshOnActivate = true;
    SourceTable = "Finance Cue";

    layout
    {
        area(content)
        {
            cuegroup(Payments)
            {
                Caption = 'Payments';
                field("Overdue Sales Documents"; Rec."Overdue Sales Documents")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Customer Ledger Entries";
                    ToolTip = 'Specifies the number of invoices where the customer is late with payment.';
                }
                field("Purchase Documents Due Today"; Rec."Purchase Documents Due Today")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Vendor Ledger Entries";
                    ToolTip = 'Specifies the number of purchase invoices where you are late with payment.';
                }

                actions
                {
                    action("Edit Cash Receipt Journal")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Edit Cash Receipt Journal';
                        RunObject = Page "Cash Receipt Journal";
                        ToolTip = 'Register received payments in a cash receipt journal that may already contain journal lines.';
                    }
                    action("New Sales Credit Memo")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Sales Credit Memo';
                        RunObject = Page "Sales Credit Memo";
                        RunPageMode = Create;
                        ToolTip = 'Process a return or refund by creating a new sales credit memo.';
                    }
                    action("Edit Payment Journal")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Edit Payment Journal';
                        RunObject = Page "Payment Journal";
                        ToolTip = 'Pay your vendors by filling the payment journal automatically according to payments due, and potentially export all payment to your bank for automatic processing.';
                    }
                    action("New Purchase Credit Memo")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Purchase Credit Memo';
                        RunObject = Page "Purchase Credit Memo";
                        RunPageMode = Create;
                        ToolTip = 'Specifies a new purchase credit memo so you can manage returned items to a vendor.';
                    }
                }
            }
            cuegroup("Document Approvals")
            {
                Caption = 'Document Approvals';
                field("POs Pending Approval"; Rec."POs Pending Approval")
                {
                    ApplicationArea = Suite;
                    DrillDownPageID = "Purchase Order List";
                    ToolTip = 'Specifies the number of purchase orders that are pending approval.';
                }
                field("SOs Pending Approval"; Rec."SOs Pending Approval")
                {
                    ApplicationArea = Suite;
                    DrillDownPageID = "Sales Order List";
                    ToolTip = 'Specifies the number of sales orders that are pending approval.';
                }

                actions
                {
                    action("Create Reminders...")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Create Reminders...';
                        RunObject = Report "Create Reminders";
                        ToolTip = 'Remind your customers of late payments.';
                    }
                    action("Create Finance Charge Memos...")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Create Finance Charge Memos...';
                        RunObject = Report "Create Finance Charge Memos";
                        ToolTip = 'Issue finance charge memos to your customers as a consequence of late payment.';
                    }
                    action("Edit Purchase Journal")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Edit Purchase Journal';
                        RunObject = Page "Purchase Journal";
                        ToolTip = 'Post purchase invoices in a purchase journal that may already contain journal lines. ';
                    }
                }
            }
            cuegroup("Cash Management")
            {
                Caption = 'Cash Management';
                field("Non-Applied Payments"; Rec."Non-Applied Payments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payment Reconciliation Journals';
                    DrillDownPageID = "Pmt. Reconciliation Journals";
                    Image = Cash;
                    ToolTip = 'Specifies a window to reconcile unpaid documents automatically with their related bank transactions by importing a bank statement feed or file. In the payment reconciliation journal, incoming or outgoing payments on your bank are automatically, or semi-automatically, applied to their related open customer or vendor ledger entries. Any open bank account ledger entries related to the applied customer or vendor ledger entries will be closed when you choose the Post Payments and Reconcile Bank Account action. This means that the bank account is automatically reconciled for payments that you post with the journal.';
                }
                field("Bank Acc. Reconciliations"; Rec."Bank Acc. Reconciliations")
                {
                    ApplicationArea = All;
                    Caption = 'Bank Acc. Reconciliations to Post';
                    DrillDownPageID = "Bank Acc. Reconciliation List";
                    ToolTip = 'Specifies bank account reconciliations that are ready to post. ';
                    Visible = BankReconWithAutoMatch;
                }
                field("Bank Reconciliations to Post"; Rec."Bank Reconciliations to Post")
                {
                    ApplicationArea = All;
                    DrillDownPageID = "Bank Acc. Reconciliation List";
                    ToolTip = 'Specifies that the bank reconciliations are ready to post.';
                    Visible = NOT BankReconWithAutoMatch;
                }
#pragma warning disable AS0074
#if not CLEAN21
                field("Deposits to Post"; Rec."Deposits to Post")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = Deposits;
                    ToolTip = 'Specifies deposits that are ready to be posted.';
                    Visible = not BankDepositFeatureEnabled;
                    ObsoleteReason = 'Replaced by Bank Deposits';
                    ObsoleteState = Pending;
                    ObsoleteTag = '21.0';
                }
#endif
#pragma warning restore AS0074

                actions
                {
                    action("New Payment Reconciliation Journal")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Payment Reconciliation Journal';
                        ToolTip = 'Reconcile unpaid documents automatically with their related bank transactions by importing bank a bank statement feed or file.';

                        trigger OnAction()
                        var
                            BankAccReconciliation: Record "Bank Acc. Reconciliation";
                        begin
                            BankAccReconciliation.OpenNewWorksheet();
                        end;
                    }
                    action("New Deposit")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Deposit';
                        RunObject = codeunit "Open Deposit Page";
                        RunPageMode = Create;
                        ToolTip = 'Create a new deposit. ';
                    }
                    action("New Bank Reconciliation")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Bank Reconciliation';
                        RunPageMode = Create;
                        ToolTip = 'Create a new bank account reconciliation.';

                        trigger OnAction()
                        var
                            BankAccReconciliation: Record "Bank Acc. Reconciliation";
                            BankReconciliationMgt: Codeunit "Bank Reconciliation Mgt.";
                        begin
                            BankReconciliationMgt.New(BankAccReconciliation, UseSharedTable);
                        end;
                    }
                }
            }
            cuegroup("Incoming Documents")
            {
                Caption = 'Incoming Documents';
                field("New Incoming Documents"; Rec."New Incoming Documents")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Incoming Documents";
                    ToolTip = 'Specifies the number of new incoming documents in the company. The documents are filtered by today''s date.';
                }
                field("Approved Incoming Documents"; Rec."Approved Incoming Documents")
                {
                    ApplicationArea = Suite;
                    DrillDownPageID = "Incoming Documents";
                    ToolTip = 'Specifies the number of approved incoming documents in the company. The documents are filtered by today''s date.';
                }
                field("OCR Completed"; Rec."OCR Completed")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Incoming Documents";
                    ToolTip = 'Specifies that incoming document records that have been created by the OCR service.';
                }

                actions
                {
                    action(CheckForOCR)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Receive from OCR Service';
                        RunObject = Codeunit "OCR - Receive from Service";
                        RunPageMode = View;
                        ToolTip = 'Process new incoming electronic documents that have been created by the OCR service and that you can convert to, for example, purchase invoices.';
                        Visible = ShowCheckForOCR;
                    }
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        UseSharedTable := false;

        GeneralLedgerSetup.Get();
        BankReconWithAutoMatch := GeneralLedgerSetup."Bank Recon. with Auto. Match";
    end;

    trigger OnOpenPage()
#if not CLEAN21
    var
        BankDepositFeatureMgt: Codeunit "Bank Deposit Feature Mgt.";
#endif
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;

        Rec.SetFilter("Due Date Filter", '<=%1', WorkDate());
        Rec.SetFilter("Overdue Date Filter", '<%1', WorkDate());
        ShowCheckForOCR := OCRServiceMgt.OcrServiceIsEnable();
        BankDepositFeatureEnabled := true;
#if not CLEAN21
        BankDepositFeatureEnabled := BankDepositFeatureMgt.IsEnabled();
#endif
    end;

    var
        OCRServiceMgt: Codeunit "OCR Service Mgt.";
        BankReconWithAutoMatch: Boolean;
        UseSharedTable: Boolean;
        ShowCheckForOCR: Boolean;
        BankDepositFeatureEnabled: Boolean;
}

