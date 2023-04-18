page 9081 "Sales Hist. Bill-to FactBox"
{
    Caption = 'Bill-to Customer Sales History';
    PageType = CardPart;
    SourceTable = Customer;

    layout
    {
        area(content)
        {
            field("No."; Rec."No.")
            {
                ApplicationArea = All;
                Caption = 'Customer No.';
                ToolTip = 'Specifies the number of the customer. The field is either filled automatically from a defined number series, or you enter the number manually because you have enabled manual number entry in the number-series setup.';

                trigger OnDrillDown()
                begin
                    ShowDetails();
                end;
            }
            group(Control2)
            {
                ShowCaption = false;
                Visible = false;
                field("Bill-To No. of Quotes"; Rec."Bill-To No. of Quotes")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Quotes';
                    DrillDownPageID = "Sales Quotes";
                    ToolTip = 'Specifies how many quotes have been registered for the customer when the customer acts as the bill-to customer.';
                }
                field("Bill-To No. of Blanket Orders"; Rec."Bill-To No. of Blanket Orders")
                {
                    ApplicationArea = Suite;
                    Caption = 'Blanket Orders';
                    DrillDownPageID = "Blanket Sales Orders";
                    ToolTip = 'Specifies how many blanket orders have been registered for the customer when the customer acts as the bill-to customer.';
                }
                field("Bill-To No. of Orders"; Rec."Bill-To No. of Orders")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Orders';
                    DrillDownPageID = "Sales Order List";
                    ToolTip = 'Specifies how many sales orders have been registered for the customer when the customer acts as the bill-to customer.';
                }
                field("Bill-To No. of Invoices"; Rec."Bill-To No. of Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Invoices';
                    DrillDownPageID = "Sales Invoice List";
                    ToolTip = 'Specifies how many invoices have been registered for the customer when the customer acts as the bill-to customer.';
                }
                field("Bill-To No. of Return Orders"; Rec."Bill-To No. of Return Orders")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Return Orders';
                    DrillDownPageID = "Sales Return Order List";
                    ToolTip = 'Specifies how many return orders have been registered for the customer when the customer acts as the bill-to customer.';
                }
                field("Bill-To No. of Credit Memos"; Rec."Bill-To No. of Credit Memos")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Credit Memos';
                    DrillDownPageID = "Sales Credit Memos";
                    ToolTip = 'Specifies how many credit memos have been registered for the customer when the customer acts as the bill-to customer.';
                }
                field("Bill-To No. of Pstd. Shipments"; Rec."Bill-To No. of Pstd. Shipments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Pstd. Shipments';
                    DrillDownPageID = "Posted Sales Shipments";
                    ToolTip = 'Specifies how many posted shipments have been registered for the customer when the customer acts as the bill-to customer.';
                }
                field("Bill-To No. of Pstd. Invoices"; Rec."Bill-To No. of Pstd. Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Pstd. Invoices';
                    DrillDownPageID = "Posted Sales Invoices";
                    ToolTip = 'Specifies how many posted invoices have been registered for the customer when the customer acts as the bill-to customer.';
                }
                field("Bill-To No. of Pstd. Return R."; Rec."Bill-To No. of Pstd. Return R.")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Pstd. Return Receipts';
                    DrillDownPageID = "Posted Return Receipts";
                    ToolTip = 'Specifies how many posted return receipts have been registered for the customer when the customer acts as the bill-to customer.';
                }
                field("Bill-To No. of Pstd. Cr. Memos"; Rec."Bill-To No. of Pstd. Cr. Memos")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Pstd. Credit Memos';
                    DrillDownPageID = "Posted Sales Credit Memos";
                    ToolTip = 'Specifies how many posted credit memos have been registered for the customer when the customer acts as the bill-to customer.';
                }
            }
            cuegroup(Control23)
            {
                ShowCaption = false;
                field(NoOfQuotesTile; "Bill-To No. of Quotes")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Quotes';
                    DrillDownPageID = "Sales Quotes";
                    ToolTip = 'Specifies how many quotes have been registered for the customer when the customer acts as the bill-to customer.';
                }
                field(NoOfBlanketOrdersTile; "Bill-To No. of Blanket Orders")
                {
                    ApplicationArea = Suite;
                    Caption = 'Blanket Orders';
                    DrillDownPageID = "Blanket Sales Orders";
                    ToolTip = 'Specifies how many blanket orders have been registered for the customer when the customer acts as the bill-to customer.';
                }
                field(NorOfOrdersTile; "Bill-To No. of Orders")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Orders';
                    DrillDownPageID = "Sales Order List";
                    ToolTip = 'Specifies how many sales orders have been registered for the customer when the customer acts as the bill-to customer.';
                }
                field(NoOfInvoicesTile; "Bill-To No. of Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Invoices';
                    DrillDownPageID = "Sales Invoice List";
                    ToolTip = 'Specifies how many invoices have been registered for the customer when the customer acts as the bill-to customer.';
                }
                field(NoOfReturnOrdersTile; "Bill-To No. of Return Orders")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Return Orders';
                    DrillDownPageID = "Sales Return Order List";
                    ToolTip = 'Specifies how many return orders have been registered for the customer when the customer acts as the bill-to customer.';
                }
                field(NoOfCreditMemosTile; "Bill-To No. of Credit Memos")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Credit Memos';
                    DrillDownPageID = "Sales Credit Memos";
                    ToolTip = 'Specifies how many credit memos have been registered for the customer when the customer acts as the bill-to customer.';
                }
                field(NoOfPostedShipmentsTile; "Bill-To No. of Pstd. Shipments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Pstd. Shipments';
                    DrillDownPageID = "Posted Sales Shipments";
                    ToolTip = 'Specifies how many posted shipments have been registered for the customer when the customer acts as the bill-to customer.';
                }
                field(NoOfPostedInvoicesTile; "Bill-To No. of Pstd. Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Pstd. Invoices';
                    DrillDownPageID = "Posted Sales Invoices";
                    ToolTip = 'Specifies how many posted invoices have been registered for the customer when the customer acts as the bill-to customer.';
                }
                field(NoOfPostedReturnOrdersTile; "Bill-To No. of Pstd. Return R.")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Pstd. Return Receipts';
                    DrillDownPageID = "Posted Return Receipts";
                    ToolTip = 'Specifies how many posted return receipts have been registered for the customer when the customer acts as the bill-to customer.';
                }
                field(NoOfPostedCrMemosTile; "Bill-To No. of Pstd. Cr. Memos")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Pstd. Credit Memos';
                    DrillDownPageID = "Posted Sales Credit Memos";
                    ToolTip = 'Specifies how many posted credit memos have been registered for the customer when the customer acts as the bill-to customer.';
                }
            }
        }
    }

    actions
    {
    }

    local procedure ShowDetails()
    begin
        PAGE.Run(PAGE::"Customer Card", Rec);
    end;
}

