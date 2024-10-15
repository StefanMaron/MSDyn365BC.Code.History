﻿namespace Microsoft.Finance.RoleCenters;


using Microsoft.Bank.Reconciliation;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Document;
using Microsoft.Sales.Receivables;
using Microsoft.Bank.Payment;

page 9036 "Bookkeeper Activities"
{
    Caption = 'Activities';
    PageType = CardPart;
    RefreshOnActivate = true;
    SourceTable = "Finance Cue";

    layout
    {
        area(content)
        {
            cuegroup(Payables)
            {
                Caption = 'Payables';
                field("Purchase Documents Due Today"; Rec."Purchase Documents Due Today")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Vendor Ledger Entries";
                    ToolTip = 'Specifies the number of purchase invoices where you are late with payment.';
                }
                field("Vendors - Payment on Hold"; Rec."Vendors - Payment on Hold")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Vendor List";
                    ToolTip = 'Specifies the number of vendor to whom your payment is on hold.';
                }
                field("Approved Purchase Orders"; Rec."Approved Purchase Orders")
                {
                    ApplicationArea = Suite;
                    DrillDownPageID = "Purchase Order List";
                    ToolTip = 'Specifies the number of approved purchase orders.';
                }

                actions
                {
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
                        ToolTip = 'Create a new purchase credit memo so you can manage returned items to a vendor.';
                    }
                }
            }
            cuegroup(Bills)
            {
                Caption = 'Bills';
                field("Vendor Bills - Open"; Rec."Vendor Bills - Open")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "List of Open Vendor Bills";
                    ToolTip = 'Specifies if the vendor bill remains open.';
                }
                field("Vendor Bills - Sent"; Rec."Vendor Bills - Sent")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "List of Sent Vendor Bills";
                    ToolTip = 'Specifies if the vendor bill has been sent to the bank.';
                }

                actions
                {
                    action("New Vendor Bill")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Vendor Bill';
                        RunObject = Page "Vendor Bill Card";
                        RunPageMode = Create;
                        ToolTip = 'Specifies if this is a new vendor bill.';
                    }
                }
            }
            cuegroup(Receivables)
            {
                Caption = 'Receivables';
                field("SOs Pending Approval"; Rec."SOs Pending Approval")
                {
                    ApplicationArea = Suite;
                    DrillDownPageID = "Sales Order List";
                    ToolTip = 'Specifies the number of sales orders that are pending approval.';
                }
                field("Overdue Sales Documents"; Rec."Overdue Sales Documents")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Customer Ledger Entries";
                    ToolTip = 'Specifies the number of sales invoices where the customer is late with payment.';
                }
                field("Approved Sales Orders"; Rec."Approved Sales Orders")
                {
                    ApplicationArea = Suite;
                    DrillDownPageID = "Sales Order List";
                    ToolTip = 'Specifies the number of approved sales orders.';
                }
                field("Customer Bills"; Rec."Customer Bills")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "List of Customer Bills";
                    ToolTip = 'Specifies the bill number of the issued customer bill.';
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
                    action("New Customer Bill")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Customer Bill';
                        RunObject = Page "List of Customer Bills";
                        RunPageMode = Create;
                        ToolTip = 'Create a new customer bill.';
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
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;

        Rec.SetFilter("Due Date Filter", '<=%1', WorkDate());
        Rec.SetFilter("Overdue Date Filter", '<%1', WorkDate());
    end;
}

