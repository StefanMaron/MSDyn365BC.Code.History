#if not CLEAN19
page 9096 "Vendor Hist. Pay-to FactBox"
{
    Caption = 'Pay-to Vendor History';
    PageType = CardPart;
    SourceTable = Vendor;

    layout
    {
        area(content)
        {
            field("No."; Rec."No.")
            {
                ApplicationArea = All;
                Caption = 'Vendor No.';
                ToolTip = 'Specifies the number of the vendor. The field is either filled automatically from a defined number series, or you enter the number manually because you have enabled manual number entry in the number-series setup.';

                trigger OnDrillDown()
                begin
                    ShowDetails();
                end;
            }
            group(Control1)
            {
                ShowCaption = false;
                Visible = false;
                field("Pay-to No. of Quotes"; Rec."Pay-to No. of Quotes")
                {
                    ApplicationArea = Suite;
                    Caption = 'Quotes';
                    DrillDownPageID = "Purchase Quotes";
                    ToolTip = 'Specifies the number of quotes that exist for the vendor.';
                }
                field("Pay-to No. of Blanket Orders"; Rec."Pay-to No. of Blanket Orders")
                {
                    ApplicationArea = Suite;
                    Caption = 'Blanket Orders';
                    DrillDownPageID = "Blanket Purchase Orders";
                    ToolTip = 'Specifies the number of blanket orders.';
                }
                field("Pay-to No. of Orders"; Rec."Pay-to No. of Orders")
                {
                    ApplicationArea = Suite;
                    Caption = 'Orders';
                    DrillDownPageID = "Purchase Order List";
                    ToolTip = 'Specifies the number of posted orders that exist for the vendor.';
                }
                field("Pay-to No. of Invoices"; Rec."Pay-to No. of Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Invoices';
                    DrillDownPageID = "Purchase Invoices";
                    ToolTip = 'Specifies the amount that relates to invoices.';
                }
                field("Pay-to No. of Return Orders"; Rec."Pay-to No. of Return Orders")
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Return Orders';
                    DrillDownPageID = "Purchase Return Order List";
                    ToolTip = 'Specifies how many return orders have been registered for the customer when the customer acts as the pay-to customer.';
                }
                field("Pay-to No. of Credit Memos"; Rec."Pay-to No. of Credit Memos")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Credit Memos';
                    DrillDownPageID = "Purchase Credit Memos";
                    ToolTip = 'Specifies the amount that relates to credit memos.';
                }
                field("Pay-to No. of Pstd. Return S."; Rec."Pay-to No. of Pstd. Return S.")
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Pstd. Return Shipments';
                    ToolTip = 'Specifies the number of posted return shipments that exist for the vendor.';
                }
                field("Pay-to No. of Pstd. Receipts"; Rec."Pay-to No. of Pstd. Receipts")
                {
                    ApplicationArea = Suite;
                    Caption = 'Pstd. Receipts';
                    ToolTip = 'Specifies the number of posted receipts that exist for the vendor.';
                }
                field("Pay-to No. of Pstd. Invoices"; Rec."Pay-to No. of Pstd. Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Pstd. Invoices';
                    ToolTip = 'Specifies the amount that relates to posted invoices.';
                }
                field("Pay-to No. of Pstd. Cr. Memos"; Rec."Pay-to No. of Pstd. Cr. Memos")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Pstd. Credit Memos';
                    ToolTip = 'Specifies the amount that relates to credit memos.';
                }
                field("Pay-to No. of Out. Adv. L."; Rec."Pay-to No. of Out. Adv. L.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Outstanding Adv. Letters (Obsolete';
                    DrillDownPageID = "Purchase Adv. Letters";
                    ToolTip = 'Specifies how many outstanding advance letters have been registered for the vendor.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
                    ObsoleteTag = '19.0';
                }
                field("Pay-to No. of Closed Adv. L."; Rec."Pay-to No. of Closed Adv. L.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Closed Adv. Letters (Obsolete)';
                    DrillDownPageID = "Purchase Adv. Letters";
                    ToolTip = 'Specifies how many closed advance letters have been registered for the vendor.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
                    ObsoleteTag = '19.0';
                }
            }
            cuegroup(Control23)
            {
                ShowCaption = false;
                field(NoOfQuotesTile; "Pay-to No. of Quotes")
                {
                    ApplicationArea = Suite;
                    Caption = 'Quotes';
                    DrillDownPageID = "Purchase Quotes";
                    ToolTip = 'Specifies the number of quotes that exist for the vendor.';
                }
                field(NoOfBlanketOrdersTile; "Pay-to No. of Blanket Orders")
                {
                    ApplicationArea = Suite;
                    Caption = 'Blanket Orders';
                    DrillDownPageID = "Blanket Purchase Orders";
                    ToolTip = 'Specifies the number of blanket orders.';
                }
                field(NoOfOrdersTile; "Pay-to No. of Orders")
                {
                    ApplicationArea = Suite;
                    Caption = 'Orders';
                    DrillDownPageID = "Purchase Order List";
                    ToolTip = 'Specifies the number of posted orders that exist for the customer.';
                }
                field(NoOfInvoicesTile; "Pay-to No. of Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Invoices';
                    DrillDownPageID = "Purchase Invoices";
                    ToolTip = 'Specifies the amount that relates to invoices.';
                }
                field(NoOfReturnOrdersTile; "Pay-to No. of Return Orders")
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Return Orders';
                    DrillDownPageID = "Purchase Return Order List";
                    ToolTip = 'Specifies how many return orders have been registered for the customer when the customer acts as the pay-to customer.';
                }
                field(NoOfCreditMemosTile; "Pay-to No. of Credit Memos")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Credit Memos';
                    DrillDownPageID = "Purchase Credit Memos";
                    ToolTip = 'Specifies the amount that relates to credit memos.';
                }
                field(NoOfPostedReturnShipmentsTile; "Pay-to No. of Pstd. Return S.")
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Pstd. Return Shipments';
                    ToolTip = 'Specifies the number of posted return shipments that exist for the vendor.';
                }
                field(NoOfPostedReceiptsTile; "Pay-to No. of Pstd. Receipts")
                {
                    ApplicationArea = Suite;
                    Caption = 'Pstd. Receipts';
                    ToolTip = 'Specifies the number of posted receipts that exist for the vendor.';
                }
                field(NoOfPostedInvoicesTile; "Pay-to No. of Pstd. Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Pstd. Invoices';
                    ToolTip = 'Specifies the amount that relates to posted invoices.';
                }
                field(NoOfPostedCreditMemosTile; "Pay-to No. of Pstd. Cr. Memos")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Pstd. Credit Memos';
                    ToolTip = 'Specifies the amount that relates to credit memos.';
                }
                field(PayToNoOfOutAdvLettersTile; "Pay-to No. of Out. Adv. L.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Outstanding Adv. Letters (Obsolete)';
                    DrillDownPageID = "Purchase Adv. Letters";
                    ToolTip = 'Specifies how many outstanding advance letters have been registered for the vendor.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
                    ObsoleteTag = '19.0';
                }
                field(PayToNoOfClosedAdvLettersTile; "Pay-to No. of Closed Adv. L.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Closed Adv. Letters (Obsolete)';
                    DrillDownPageID = "Purchase Adv. Letters";
                    ToolTip = 'Specifies how many closed advance letters have been registered for the vendor.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
                    ObsoleteTag = '19.0';
                }
            }
        }
    }

    actions
    {
    }

    local procedure ShowDetails()
    begin
        PAGE.Run(PAGE::"Vendor Card", Rec);
    end;
}

#endif