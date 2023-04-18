page 9971 "Posted Purchase Invoice API"
{
    APIVersion = 'v1.0';
    APIGroup = 'automate';
    APIPublisher = 'microsoft';
    EntityCaption = 'Posted Purchase Invoice';
    EntitySetCaption = 'Posted Purchase Invoices';
    ChangeTrackingAllowed = true;
    EntityName = 'postedPurchaseInvoice';
    EntitySetName = 'postedPurchaseInvoices';
    ODataKeyFields = SystemId;
    PageType = API;
    SourceTable = "Purch. Inv. Header";
    Extensible = false;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    DataAccessIntent = ReadOnly;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; SystemId)
                {
                    Caption = 'Id';
                }
                field(number; "No.")
                {
                    Caption = 'No.';
                }
                field(apiId; APIId)
                {
                    Caption = 'API Id';
                }
                field(invoiceDate; "Document Date")
                {
                    Caption = 'Invoice Date';
                }
                field(postingDate; "Posting Date")
                {
                    Caption = 'Posting Date';
                }
                field(dueDate; "Due Date")
                {
                    Caption = 'Due Date';
                }
                field(vendorInvoiceNumber; "Vendor Invoice No.")
                {
                    Caption = 'Vendor Invoice No.';
                }
                field(customerPurchaseOrderReference; "Your Reference")
                {
                    Caption = 'Customer Purchase Order Reference';
                }
                field(vendorNumber; "Buy-from Vendor No.")
                {
                    Caption = 'Vendor No.';
                }
                field(vendorName; "Buy-from Vendor Name")
                {
                    Caption = 'Vendor Name';
                }
                field(payToName; "Pay-to Name")
                {
                    Caption = 'Pay-To Name';
                }
                field(payToContact; "Pay-to Contact")
                {
                    Caption = 'Pay-To Contact';
                }
                field(payToVendorNumber; "Pay-to Vendor No.")
                {
                    Caption = 'Pay-To Vendor No.';
                }
                field(shipToName; "Ship-to Name")
                {
                    Caption = 'Ship-To Name';
                }
                field(shipToContact; "Ship-to Contact")
                {
                    Caption = 'Ship-To Contact';
                }
                field(buyFromAddressLine1; "Buy-from Address")
                {
                    Caption = 'Buy-from Address Line 1';
                }
                field(buyFromAddressLine2; "Buy-from Address 2")
                {
                    Caption = 'Buy-from Address Line 2';
                }
                field(buyFromCity; "Buy-from City")
                {
                    Caption = 'Buy-from City';
                }
                field(buyFromCountry; "Buy-from Country/Region Code")
                {
                    Caption = 'Buy-from Country/Region Code';
                }
                field(buyFromState; "Buy-from County")
                {
                    Caption = 'Buy-from State';
                }
                field(buyFromPostCode; "Buy-from Post Code")
                {
                    Caption = 'Buy-from Post Code';
                }
                field(shipToAddressLine1; "Ship-to Address")
                {
                    Caption = 'Ship-to Address Line 1';
                }
                field(shipToAddressLine2; "Ship-to Address 2")
                {
                    Caption = 'Ship-to Address Line 2';
                }
                field(shipToCity; "Ship-to City")
                {
                    Caption = 'Ship-to City';
                }
                field(shipToCountry; "Ship-to Country/Region Code")
                {
                    Caption = 'Ship-to Country/Region Code';
                }
                field(shipToState; "Ship-to County")
                {
                    Caption = 'Ship-to State';
                }
                field(shipToPostCode; "Ship-to Post Code")
                {
                    Caption = 'Ship-to Post Code';
                }
                field(payToAddressLine1; "Pay-to Address")
                {
                    Caption = 'Pay To Address Line 1';
                }
                field(payToAddressLine2; "Pay-to Address 2")
                {
                    Caption = 'Pay To Address Line 2';
                }
                field(payToCity; "Pay-to City")
                {
                    Caption = 'Pay To City';
                }
                field(payToCountry; "Pay-to Country/Region Code")
                {
                    Caption = 'Pay To Country/Region Code';
                }
                field(payToState; "Pay-to County")
                {
                    Caption = 'Pay To State';
                }
                field(payToPostCode; "Pay-to Post Code")
                {
                    Caption = 'Pay To Post Code';
                }
                field(shortcutDimension1Code; "Shortcut Dimension 1 Code")
                {
                    Caption = 'Shortcut Dimension 1 Code';
                }
                field(shortcutDimension2Code; "Shortcut Dimension 2 Code")
                {
                    Caption = 'Shortcut Dimension 2 Code';
                }
                field(currencyCode; "Currency Code")
                {
                    Caption = 'Currency Code';
                }
                field(orderNumber; "Order No.")
                {
                    Caption = 'Order No.';
                }
                field(paymentTermsCode; "Payment Terms Code")
                {
                    Caption = 'Payment Terms Code';
                }
                field(shipmentMethodCode; "Shipment Method Code")
                {
                    Caption = 'Shipment Method Code';
                }
                field(pricesIncludeTax; "Prices Including VAT")
                {
                    Caption = 'Prices Include Tax';
                }
                field(discountAmount; "Invoice Discount Amount")
                {
                    Caption = 'Discount Amount';
                }
                field(totalAmountExcludingTax; Amount)
                {
                    Caption = 'Total Amount Excluding Tax';
                }
                field(totalAmountIncludingTax; "Amount Including VAT")
                {
                    Caption = 'Total Amount Including Tax';
                }
            }
        }
    }

    var
        APIId: Guid;

    trigger OnAfterGetRecord()
    begin
        if IsNullGuid(Rec."Draft Invoice SystemId") then
            APIId := Rec.SystemId
        else
            APIId := Rec."Draft Invoice SystemId";
    end;
}