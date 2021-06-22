page 9096 "Vendor Hist. Pay-to FactBox"
{
    Caption = 'Pay-to Vendor History';
    PageType = CardPart;
    SourceTable = Vendor;

    layout
    {
        area(content)
        {
            field("No."; "No.")
            {
                ApplicationArea = All;
                Caption = 'Vendor No.';
                ToolTip = 'Specifies the number of the vendor. The field is either filled automatically from a defined number series, or you enter the number manually because you have enabled manual number entry in the number-series setup.';
                Visible = ShowVendorNo;

                trigger OnDrillDown()
                begin
                    ShowDetails;
                end;
            }
            group(Control1)
            {
                ShowCaption = false;
                Visible = RegularFastTabVisible;
                field("Pay-to No. of Quotes"; "Pay-to No. of Quotes")
                {
                    ApplicationArea = Suite;
                    Caption = 'Quotes';
                    DrillDownPageID = "Purchase Quotes";
                    ToolTip = 'Specifies the number of quotes that exist for the vendor.';
                }
                field("Pay-to No. of Blanket Orders"; "Pay-to No. of Blanket Orders")
                {
                    ApplicationArea = Suite;
                    Caption = 'Blanket Orders';
                    DrillDownPageID = "Blanket Purchase Orders";
                    ToolTip = 'Specifies the number of blanket orders.';
                }
                field("Pay-to No. of Orders"; "Pay-to No. of Orders")
                {
                    ApplicationArea = Suite;
                    Caption = 'Orders';
                    DrillDownPageID = "Purchase Order List";
                    ToolTip = 'Specifies the number of posted orders that exist for the vendor.';
                }
                field("Pay-to No. of Invoices"; "Pay-to No. of Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Invoices';
                    DrillDownPageID = "Purchase Invoices";
                    ToolTip = 'Specifies the amount that relates to invoices.';
                }
                field("Pay-to No. of Return Orders"; "Pay-to No. of Return Orders")
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Return Orders';
                    DrillDownPageID = "Purchase Return Order List";
                    ToolTip = 'Specifies how many return orders have been registered for the customer when the customer acts as the pay-to customer.';
                }
                field("Pay-to No. of Credit Memos"; "Pay-to No. of Credit Memos")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Credit Memos';
                    DrillDownPageID = "Purchase Credit Memos";
                    ToolTip = 'Specifies the amount that relates to credit memos.';
                }
                field("Pay-to No. of Pstd. Return S."; "Pay-to No. of Pstd. Return S.")
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Pstd. Return Shipments';
                    ToolTip = 'Specifies the number of posted return shipments that exist for the vendor.';
                }
                field("Pay-to No. of Pstd. Receipts"; "Pay-to No. of Pstd. Receipts")
                {
                    ApplicationArea = Suite;
                    Caption = 'Pstd. Receipts';
                    ToolTip = 'Specifies the number of posted receipts that exist for the vendor.';
                }
                field("Pay-to No. of Pstd. Invoices"; "Pay-to No. of Pstd. Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Pstd. Invoices';
                    ToolTip = 'Specifies the amount that relates to posted invoices.';
                }
                field("Pay-to No. of Pstd. Cr. Memos"; "Pay-to No. of Pstd. Cr. Memos")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Pstd. Credit Memos';
                    ToolTip = 'Specifies the amount that relates to credit memos.';
                }
            }
            cuegroup(Control23)
            {
                ShowCaption = false;
                Visible = CuesVisible;
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
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    begin
        ShowVendorNo := true;
    end;

    trigger OnOpenPage()
    var
        OfficeManagement: Codeunit "Office Management";
    begin
        RegularFastTabVisible := ClientTypeManagement.GetCurrentClientType = CLIENTTYPE::Windows;
        CuesVisible := (not RegularFastTabVisible) or OfficeManagement.IsAvailable;
    end;

    var
        ClientTypeManagement: Codeunit "Client Type Management";
        RegularFastTabVisible: Boolean;
        CuesVisible: Boolean;
        ShowVendorNo: Boolean;

    local procedure ShowDetails()
    begin
        PAGE.Run(PAGE::"Vendor Card", Rec);
    end;

    procedure SetVendorNoVisibility(Visible: Boolean)
    begin
        ShowVendorNo := Visible;
    end;
}

