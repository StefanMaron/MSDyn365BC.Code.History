namespace Microsoft.Sales.Setup;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Payment;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Integration.Dataverse;
using Microsoft.Pricing.Calculation;
using Microsoft.Sales.Customer;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.Pricing;
using Microsoft.Sales.Reminder;
using Microsoft.Utilities;

page 459 "Sales & Receivables Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Sales & Receivables Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Sales & Receivables Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Discount Posting"; Rec."Discount Posting")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of sales discounts to post separately. No Discounts: Discounts are not posted separately but instead will subtract the discount before posting. Invoice Discounts: The invoice discount and invoice amount are posted simultaneously, based on the Sales Inv. Disc. Account field in the General Posting Setup window. Line Discounts: The line discount and the invoice amount will be posted simultaneously, based on Sales Line Disc. Account field in the General Posting Setup window. All Discounts: The invoice and line discounts and the invoice amount will be posted simultaneously, based on the Sales Inv. Disc. Account field and Sales Line. Disc. Account fields in the General Posting Setup window.';
                }
                field("Credit Warnings"; Rec."Credit Warnings")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to warn about the customer''s status when you create a sales order or invoice.';
                }
                field("Stockout Warning"; Rec."Stockout Warning")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if a warning is displayed when you enter a quantity on a sales document that brings the item''s inventory level below zero.';
                }
                field("Shipment on Invoice"; Rec."Shipment on Invoice")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies if a posted shipment and a posted invoice are automatically created when you post an invoice.';
                }
                field("Return Receipt on Credit Memo"; Rec."Return Receipt on Credit Memo")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies that a posted return receipt and a posted sales credit memo are automatically created when you post a credit memo.';
                }
                field("Invoice Rounding"; Rec."Invoice Rounding")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if amounts are rounded for sales invoices. Rounding is applied as specified in the Inv. Rounding Precision (LCY) field in the General Ledger Setup window. ';
                }
                field(DefaultItemQuantity; Rec."Default Item Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Default Item Quantity';
                    ToolTip = 'Specifies that the Quantity field is set to 1 when you fill in the Item No. field.';
                }
                field(DefaultGLAccountQuantity; Rec."Default G/L Account Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that Quantity is set to 1 on lines of type G/L Account.';
                }
                field("Create Item from Item No."; Rec."Create Item from Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the system will suggest to create a new item when no item matches the number that you enter in the No. Field on sales lines.';
                }
                field("Create Item from Description"; Rec."Create Item from Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the system will suggest to create a new item when no item matches the description that you enter in the Description field on sales lines.';
                }
                field("Copy Customer Name to Entries"; Rec."Copy Customer Name to Entries")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want the name on customer cards to be copied to customer ledger entries during posting.';
                }
                field("Ext. Doc. No. Mandatory"; Rec."Ext. Doc. No. Mandatory")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies if it is mandatory to enter an external document number in the External Document No. field on a sales header or the External Document No. field on a general journal line.';
                }
                field("Appln. between Currencies"; Rec."Appln. between Currencies")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies whether it is allowed to apply customer payments in different currencies. None: All entries involved in one application must be in the same currency. EMU: You can apply entries in euro and one of the old national currencies (for EMU countries/regions) to one another. All: You can apply entries in different currencies to one another. The entries can be in any currency.';
                }
                field("Logo Position on Documents"; Rec."Logo Position on Documents")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the position of your company logo on business letters and documents.';
                }
                field("Default Posting Date"; Rec."Default Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which date must be used as the default posting date on sales documents. If you select Work Date, the Posting Date field will be populated with the work date at the time of creating a new sales document. If you select No Date, the Posting Date field will be empty by default and you must manually enter a posting date before posting.';
                }
                field("Default Quantity to Ship"; Rec."Default Quantity to Ship")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the default value for the Qty. to Ship field on sales order lines and the Return Qty. to Receive field on sales return order lines. If you choose Blank, the quantity to invoice is not automatically calculated.';
                }
                field("Auto Post Non-Invt. via Whse."; Rec."Auto Post Non-Invt. via Whse.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies if non-inventory item lines in a sales document will be posted automatically when the document is posted via warehouse. None: Do not automatically post non-inventory item lines. Attached/Assigned: Post item charges and other non-inventory item lines assigned or attached to regular items. All: Post all non-inventory item lines.';
                }
                field("Copy Comments Blanket to Order"; Rec."Copy Comments Blanket to Order")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies whether to copy comments from blanket sales orders to sales orders.';
                }
                field("Copy Comments Order to Invoice"; Rec."Copy Comments Order to Invoice")
                {
                    ApplicationArea = Comments;
                    Importance = Additional;
                    ToolTip = 'Specifies whether to copy comments from sales orders to sales invoices.';
                }
                field("Copy Comments Order to Shpt."; Rec."Copy Comments Order to Shpt.")
                {
                    ApplicationArea = Comments;
                    Importance = Additional;
                    ToolTip = 'Specifies whether to copy comments from sales orders to shipments.';
                }
                field("Copy Cmts Ret.Ord. to Cr. Memo"; Rec."Copy Cmts Ret.Ord. to Cr. Memo")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies whether to copy comments from sales return orders to sales credit memos.';
                }
                field("Copy Cmts Ret.Ord. to Ret.Rcpt"; Rec."Copy Cmts Ret.Ord. to Ret.Rcpt")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies that comments are copied from the sales return order to the posted return receipt.';
                }
                field("Allow VAT Difference"; Rec."Allow VAT Difference")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to allow the manual adjustment of VAT amounts in sales documents.';
                }
                field("Calc. Inv. Discount"; Rec."Calc. Inv. Discount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the invoice discount amount is automatically calculated with sales documents. If this check box is selected, then the invoice discount amount is calculated automatically, based on sales lines where the Allow Invoice Disc. field is selected.';
                }
                field("Calc. Inv. Disc. per VAT ID"; Rec."Calc. Inv. Disc. per VAT ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the invoice discount is calculated according to the VAT identifier that is defined in the VAT posting setup. If you choose not to select this check box, the invoice discount will be calculated based on the invoice total.';
                    Visible = false;
                }
                field("VAT Bus. Posting Gr. (Price)"; Rec."VAT Bus. Posting Gr. (Price)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a VAT business posting group for customers for whom you want the item price including VAT to apply.';
                }
                field("Exact Cost Reversing Mandatory"; Rec."Exact Cost Reversing Mandatory")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies that a return transaction cannot be posted unless the Appl.-from Item Entry field on the sales order line specifies an entry.';
                }
                field("Check Prepmt. when Posting"; Rec."Check Prepmt. when Posting")
                {
                    ApplicationArea = Prepayments;
                    Importance = Additional;
                    ToolTip = 'Specifies that you cannot ship or invoice an order that has an unpaid prepayment amount.';
                }
                field("Prepmt. Auto Update Frequency"; Rec."Prepmt. Auto Update Frequency")
                {
                    ApplicationArea = Prepayments;
                    ToolTip = 'Specifies how often the job must run that automatically updates the status of orders that are pending prepayment.';
                }
                field("Allow Document Deletion Before"; Rec."Allow Document Deletion Before")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies if and when posted sales invoices and credit memos can be deleted. If you enter a date, posted sales documents with a posting date on or after this date cannot be deleted.';
                }
                field("Allow Multiple Posting Groups"; Rec."Allow Multiple Posting Groups")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies if multiple posting groups can be used for the same customer in sales documents.';
                }
                field("Check Multiple Posting Groups"; Rec."Check Multiple Posting Groups")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies implementation method of checking which posting groups can be used for the customer.';
                }
                field("Ignore Updated Addresses"; Rec."Ignore Updated Addresses")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if changes to addresses made on sales documents are copied to the customer card. By default, changes are copied to the customer card.';
                }
                field("Skip Manual Reservation"; Rec."Skip Manual Reservation")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the reservation confirmation message is not shown on sales lines. This is useful to avoid noise when you are processing many lines.';
                }
                field("Quote Validity Calculation"; Rec."Quote Validity Calculation")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies a formula that determines how to calculate the quote expiration date based on the document date.';
                }
                field("Copy Line Descr. to G/L Entry"; Rec."Copy Line Descr. to G/L Entry")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies that the description on document lines of type G/L Account will be carried to the resulting general ledger entries.';
                }
                field("Document Default Line Type"; Rec."Document Default Line Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the default value for the Type field on the first line in new sales documents. If needed, you can change the value on the line.';
                }
                field("Disable Search by Name"; Rec."Disable Search by Name")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies that you can change the names of customers on open sales documents. The change applies only to the documents.';
                }
                field("Update Document Date When Posting Date Is Modified"; Rec."Link Doc. Date To Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the document date changes when the posting date is modified.';
                    Importance = Additional;
                }
            }
            group(Prices)
            {
                Caption = 'Prices';
                Visible = ExtendedPriceEnabled;
                field("Price Calculation Method"; Rec."Price Calculation Method")
                {
                    Visible = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the price calculation method that will be default for sales transactions.';
                }
                field("Allow Editing Active Price"; Rec."Allow Editing Active Price")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies it the existing active sales price line can be modified or removed, or a new price line can be added to the active price list.';
                }
                field("Default Price List Code"; Rec."Default Price List Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the existing sales price list that stores all new price lines created in the price worksheet page.';
                }
                field("Use Customized Lookup"; Rec."Use Customized Lookup")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the Assign-to Parent No., Assign-to No., and Product No. fields on price list pages use standard lookups to find records. If you have customized these fields and prefer your implementation, turn on this toggle.';
                }
            }
            group(Dimensions)
            {
                Caption = 'Dimensions';
                field("Customer Group Dimension Code"; Rec."Customer Group Dimension Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the dimension code for customer groups in your analysis report.';
                }
                field("Salesperson Dimension Code"; Rec."Salesperson Dimension Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the dimension code for salespeople in your analysis report';
                }
            }
            group("Number Series")
            {
                Caption = 'Number Series';
                field("Customer Nos."; Rec."Customer Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to customers.';
                }
                field("Quote Nos."; Rec."Quote Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to sales quotes.';
                }
                field("Blanket Order Nos."; Rec."Blanket Order Nos.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to blanket sales orders.';
                }
                field("Order Nos."; Rec."Order Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to sales orders.';
                }
                field("Return Order Nos."; Rec."Return Order Nos.")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to new sales return orders.';
                }
                field("Invoice Nos."; Rec."Invoice Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to sales invoices.';
                }
                field("Posted Invoice Nos."; Rec."Posted Invoice Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to posted sales invoices.';
                }
                field("Credit Memo Nos."; Rec."Credit Memo Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to sales credit memos.';
                }
                field("Posted Credit Memo Nos."; Rec."Posted Credit Memo Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to posted sales credit memos.';
                }
                field("Posted Shipment Nos."; Rec."Posted Shipment Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to posted shipments.';
                }
                field("Posted Return Receipt Nos."; Rec."Posted Return Receipt Nos.")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to posted return receipts.';
                }
                field("Reminder Nos."; Rec."Reminder Nos.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to reminders.';
                }
                field("Issued Reminder Nos."; Rec."Issued Reminder Nos.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to issued reminders.';
                }
                field("Canceled Issued Reminder Nos."; Rec."Canceled Issued Reminder Nos.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to canceled issued reminders.';
                }
                field("Fin. Chrg. Memo Nos."; Rec."Fin. Chrg. Memo Nos.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to finance charge memos.';
                }
                field("Issued Fin. Chrg. M. Nos."; Rec."Issued Fin. Chrg. M. Nos.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to issued finance charge memos.';
                }
                field("Canc. Iss. Fin. Ch. Mem. Nos."; Rec."Canc. Iss. Fin. Ch. Mem. Nos.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to canceled issued finance charge memos.';
                }
                field("Posted Prepmt. Inv. Nos."; Rec."Posted Prepmt. Inv. Nos.")
                {
                    ApplicationArea = Prepayments;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to posted sales prepayment invoices.';
                }
                field("Posted Prepmt. Cr. Memo Nos."; Rec."Posted Prepmt. Cr. Memo Nos.")
                {
                    ApplicationArea = Prepayments;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to posted sales prepayment credit memos.';
                }
                field("Direct Debit Mandate Nos."; Rec."Direct Debit Mandate Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to direct-debit mandates.';
                }
                field("Price List Nos."; Rec."Price List Nos.")
                {
                    Visible = ExtendedPriceEnabled;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to sales price lists.';
                }
            }
            group("Background Posting")
            {
                Caption = 'Background Posting';
                field("Post with Job Queue"; Rec."Post with Job Queue")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you use job queues to post sales documents in the background.';
                }
                field("Post & Print with Job Queue"; Rec."Post & Print with Job Queue")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you use job queues to post and print sales documents in the background.';
                    Visible = false;
                }
                field("Job Queue Category Code"; Rec."Job Queue Category Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the category of the job queue that you want to associate with background posting.';
                }
                field("Notify On Success"; Rec."Notify On Success")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a setting that has no effect. Legacy field.';
                    Visible = false;
                }
                field("Report Output Type"; Rec."Report Output Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the output of the report that will be scheduled with a job queue entry when the Post and Print with Job Queue check box is selected.';
                }
            }
            group(Archiving)
            {
                Caption = 'Archiving';
                field("Archive Quotes"; Rec."Archive Quotes")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want to archive sales quotes when they are deleted.';
                }
                field("Archive Blanket Orders"; Rec."Archive Blanket Orders")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want to archive sales blanket orders when they are deleted.';
                }
                field("Archive Orders"; Rec."Archive Orders")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want to archive sales orders when they are deleted.';
                }
                field("Archive Return Orders"; Rec."Archive Return Orders")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies if you want to archive sales return orders when they are deleted.';
                }
            }
            group("Journal Templates")
            {
                Caption = 'Journal Templates';
                Visible = JnlTemplateNameVisible;

                field("S. Invoice Template Name"; Rec."S. Invoice Template Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the journal template to use for posting sales invoices.';
                }
                field("S. Cr. Memo Template Name"; Rec."S. Cr. Memo Template Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the journal template to use for posting sales credit memos.';
                }
                field("S. Prep. Inv. Template Name"; Rec."S. Prep. Inv. Template Name")
                {
                    ApplicationArea = Prepayments;
                    ToolTip = 'Specifies which general journal template to use for sales invoices.';
                }
                field("S. Prep. Cr.Memo Template Name"; Rec."S. Prep. Cr.Memo Template Name")
                {
                    ApplicationArea = Prepayments;
                    ToolTip = 'Specifies which general journal template to use for sales credit memos.';
                }
                field("IC Sales Invoice Template Name"; Rec."IC Sales Invoice Template Name")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the intercompany journal template to use for sales invoices.';
                }
                field("IC Sales Cr. Memo Templ. Name"; Rec."IC Sales Cr. Memo Templ. Name")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the intercompany journal template to use for sales credit memos.';
                }
                field("Fin. Charge Jnl. Template Name"; Rec."Fin. Charge Jnl. Template Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which general journal template to use for finance charges.';
                }
                field("Fin. Charge Jnl. Batch Name"; Rec."Fin. Charge Jnl. Batch Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which general journal batch to use for finance charges.';
                }
                field("Reminder Journal Template Name"; Rec."Reminder Journal Template Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which general journal template to use for reminders.';
                }
                field("Reminder Journal Batch Name"; Rec."Reminder Journal Batch Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which general journal batch to use for reminders.';
                }
            }
            group("Dynamics 365 Sales")
            {
                Caption = 'Dynamics 365 Sales';
                Visible = CRMIntegrationEnabled;
                field("Write-in Product Type"; Rec."Write-in Product Type")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the sales line type that will be used for write-in products in Dynamics 365 Sales.';
                }
                field("Write-in Product No."; Rec."Write-in Product No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the item or resource depending on the write-in product type that will be used for Dynamics 365 Sales.';
                }
                field("Freight G/L Acc. No."; Rec."Freight G/L Acc. No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the general ledger account that must be used to handle freight charges from Dynamics 365 Sales.';
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
        area(navigation)
        {
            action("Customer Posting Groups")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Customer Posting Groups';
                Image = CustomerGroup;
                RunObject = Page "Customer Posting Groups";
                ToolTip = 'Set up the posting groups to select from when you set up customer cards to link business transactions made for the customer with the appropriate account in the general ledger.';
            }
            action("Customer Price Groups")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Customer Price Groups';
                Image = Price;
                RunObject = Page "Customer Price Groups";
                ToolTip = 'Set up the posting groups to select from when you set up customer cards to link business transactions made for the customer with the appropriate account in the general ledger.';
            }
            action("Customer Disc. Groups")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Customer Disc. Groups';
                Image = Discount;
                RunObject = Page "Customer Disc. Groups";
                ToolTip = 'Set up discount group codes that you can use as criteria when you define special discounts on a customer, vendor, or item card.';
            }
            group(Payment)
            {
                Caption = 'Payment';
                action("Payment Registration Setup")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payment Registration Setup';
                    Image = PaymentJournal;
                    RunObject = Page "Payment Registration Setup";
                    ToolTip = 'Set up the payment journal template and the balancing account that is used to post received customer payments. Define how you prefer to process customer payments in the Payment Registration window.';
                }
                action("Payment Methods")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payment Methods';
                    Image = Payment;
                    RunObject = Page "Payment Methods";
                    ToolTip = 'Set up the payment methods that you select from the customer card to define how the customer must pay, for example by bank transfer.';
                }
                action("Payment Terms")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payment Terms';
                    Image = Payment;
                    RunObject = Page "Payment Terms";
                    ToolTip = 'Set up the payment terms that you select from on customer cards to define when the customer must pay, such as within 14 days.';
                }
                action("Finance Charge Terms")
                {
                    ApplicationArea = Suite;
                    Caption = 'Finance Charge Terms';
                    Image = FinChargeMemo;
                    RunObject = Page "Finance Charge Terms";
                    ToolTip = 'Set up the finance charge terms that you select from on customer cards to define how to calculate interest in case the customer''s payment is late.';
                }
                action("Reminder Terms")
                {
                    ApplicationArea = Suite;
                    Caption = 'Reminder Terms';
                    Image = ReminderTerms;
                    RunObject = Page "Reminder Terms";
                    ToolTip = 'Set up reminder terms that you select from on customer cards to define when and how to remind the customer of late payments.';
                }
                action("Rounding Methods")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Rounding Methods';
                    Image = Calculate;
                    RunObject = Page "Rounding Methods";
                    ToolTip = 'Define how amounts are rounded when you use functions to adjust or suggest item prices or standard costs.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Customer Groups', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref("Customer Posting Groups_Promoted"; "Customer Posting Groups")
                {
                }
                actionref("Customer Price Groups_Promoted"; "Customer Price Groups")
                {
                }
                actionref("Customer Disc. Groups_Promoted"; "Customer Disc. Groups")
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Payments', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref("Payment Registration Setup_Promoted"; "Payment Registration Setup")
                {
                }
                actionref("Payment Methods_Promoted"; "Payment Methods")
                {
                }
                actionref("Payment Terms_Promoted"; "Payment Terms")
                {
                }
                actionref("Finance Charge Terms_Promoted"; "Finance Charge Terms")
                {
                }
                actionref("Reminder Terms_Promoted"; "Reminder Terms")
                {
                }
                actionref("Rounding Methods_Promoted"; "Rounding Methods")
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
        ExtendedPriceEnabled := PriceCalculationMgt.IsExtendedPriceCalculationEnabled();
        if ExtendedPriceEnabled then
            PriceCalculationMgt.FeatureCustomizedLookupDiscovered();
        CRMIntegrationEnabled := CRMIntegrationManagement.IsCRMIntegrationEnabled();
        GeneralLedgerSetup.Get();
        JnlTemplateNameVisible := GeneralLedgerSetup."Journal Templ. Name Mandatory";
    end;

    var
        ExtendedPriceEnabled: Boolean;
        CRMIntegrationEnabled: Boolean;
        JnlTemplateNameVisible: Boolean;
}

