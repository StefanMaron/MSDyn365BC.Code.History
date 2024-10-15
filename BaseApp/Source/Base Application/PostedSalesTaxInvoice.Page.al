page 28071 "Posted Sales Tax Invoice"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Posted Sales Tax Invoice';
    InsertAllowed = false;
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = "Sales Tax Invoice Header";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the number of the document.';
                }
                field("Sell-to Customer No."; "Sell-to Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the customer.';
                }
                field("Sell-to Contact No."; "Sell-to Contact No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies your contact at the customer.';
                }
                field("Sell-to Customer Name"; "Sell-to Customer Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the customer.';
                }
                field("Sell-to Address"; "Sell-to Address")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the address of the customer.';
                }
                field("Sell-to Address 2"; "Sell-to Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the address of the customer.';
                }
                field("Sell-to Post Code"; "Sell-to Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sell-to Post Code/City';
                    Editable = false;
                    ToolTip = 'Specifies the value on the original document.';
                }
                field("Sell-to City"; "Sell-to City")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the city of the address.';
                }
                field("Sell-to Contact"; "Sell-to Contact")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies your contact at the customer.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date when the invoice was posted.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date when the document was created.';
                }
                field("Order No."; "Order No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the sales order from which this invoice was posted.';
                }
                field("Pre-Assigned No."; "Pre-Assigned No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the value on the original document.';
                }
                field("External Document No."; "External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the external document number for this entry.';
                }
                field("Salesperson Code"; "Salesperson Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies which salesperson is associated with the invoice.';
                }
                field("Responsibility Center"; "Responsibility Center")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the value on the original document.';
                }
                field("No. Printed"; "No. Printed")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies how many times the document has been printed.';
                }
            }
            part(SalesInvLines; "Posted Sales Tax Inv. Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Document No." = FIELD("No.");
            }
            group(Invoicing)
            {
                Caption = 'Invoicing';
                field("Bill-to Customer No."; "Bill-to Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the customer that the tax invoice was sent to.';
                }
                field("Bill-to Contact No."; "Bill-to Contact No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies your contact at the customer.';
                }
                field("Bill-to Name"; "Bill-to Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the name of the customer that the tax invoice was sent to.';
                }
                field("Bill-to Address"; "Bill-to Address")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the address of the customer to whom the tax invoice was sent.';
                }
                field("Bill-to Address 2"; "Bill-to Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies an additional part of the address.';
                }
                field("Bill-to Post Code"; "Bill-to Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bill-to Post Code/City';
                    Editable = false;
                    ToolTip = 'Specifies the value on the original document.';
                }
                field("Bill-to City"; "Bill-to City")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the city of the address.';
                }
                field("Bill-to Contact"; "Bill-to Contact")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the name of the person you regularly contact when you communicate with the customer to whom the tax invoice was sent.';
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the dimension value code with which the document is associated.';
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the dimension value code with which the document is associated.';
                }
                field("Payment Terms Code"; "Payment Terms Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the payment terms of the original document.';
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date when the invoice is due for payment.';
                }
                field("Payment Discount %"; "Payment Discount %")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the payment discount percentage granted if payment is made by the date entered in the Payment Discount Date field.';
                }
                field("Pmt. Discount Date"; "Pmt. Discount Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date by which the invoice must be paid to obtain a payment discount.';
                }
                field("Payment Method Code"; "Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the payment method of the original document.';
                }
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field("Ship-to Code"; "Ship-to Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies a code for the address if the customer has multiple ship-to addresses.';
                }
                field("Ship-to Name"; "Ship-to Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the name of the customer to whom the items on the invoice were shipped.';
                }
                field("Ship-to Address"; "Ship-to Address")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the address to which the items on the tax invoice were shipped.';
                }
                field("Ship-to Address 2"; "Ship-to Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies an additional part of the address.';
                }
                field("Ship-to Post Code"; "Ship-to Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ship-to Post Code/City';
                    Editable = false;
                    ToolTip = 'Specifies the value on the original document.';
                }
                field("Ship-to City"; "Ship-to City")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the city name for the address.';
                }
                field("Ship-to Contact"; "Ship-to Contact")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the person you regularly contact at the address to which the items were shipped.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the code for the location from which the items were shipped.';
                }
                field("Shipment Method Code"; "Shipment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the shipment method for the document.';
                }
                field("Shipment Date"; "Shipment Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies that the program copies the date for from the Shipment Date field on the sales header.';
                }
            }
            group("Foreign Trade")
            {
                Caption = 'Foreign Trade';
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code of the invoice.';

                    trigger OnAssistEdit()
                    begin
                        ChangeExchangeRate.SetParameter("Currency Code", "Currency Factor", "Posting Date");
                        ChangeExchangeRate.Editable(false);
                        if ChangeExchangeRate.RunModal = ACTION::OK then begin
                            "Currency Factor" := ChangeExchangeRate.GetParameter;
                            Modify;
                        end;
                        Clear(ChangeExchangeRate);
                    end;
                }
                field("EU 3-Party Trade"; "EU 3-Party Trade")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies if the document is for EU third-party trade.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("&Print")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                begin
                    CurrPage.SetSelectionFilter(SalesTaxInvHeader);
                    SalesTaxInvHeader.PrintRecords(true);
                end;
            }
        }
    }

    var
        SalesTaxInvHeader: Record "Sales Tax Invoice Header";
        ChangeExchangeRate: Page "Change Exchange Rate";
}

