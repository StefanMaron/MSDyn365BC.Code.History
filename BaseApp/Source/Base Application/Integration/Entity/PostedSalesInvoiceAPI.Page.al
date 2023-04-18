page 9970 "Posted Sales Invoice API"
{
    APIVersion = 'v1.0';
    APIGroup = 'automate';
    APIPublisher = 'microsoft';
    EntityCaption = 'Posted Sales Invoice';
    EntitySetCaption = 'Posted Sales Invoices';
    ChangeTrackingAllowed = true;
    EntityName = 'postedSalesInvoice';
    EntitySetName = 'postedSalesInvoices';
    ODataKeyFields = SystemId;
    PageType = API;
    SourceTable = "Sales Invoice Header";
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
                field(externalDocumentNumber; "External Document No.")
                {
                    Caption = 'External Document No.';
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
                field(customerPurchaseOrderReference; "Your Reference")
                {
                    Caption = 'Customer Purchase Order Reference';
                }
                field(customerNumber; "Sell-to Customer No.")
                {
                    Caption = 'Customer No.';
                }
                field(customerName; "Sell-to Customer Name")
                {
                    Caption = 'Customer Name';
                }
                field(billToName; "Bill-to Name")
                {
                    Caption = 'Bill-To Name';
                }
                field(billToCustomerNumber; "Bill-to Customer No.")
                {
                    Caption = 'Bill-To Customer No.';
                }
                field(shipToName; "Ship-to Name")
                {
                    Caption = 'Ship-to Name';
                }
                field(shipToContact; "Ship-to Contact")
                {
                    Caption = 'Ship-to Contact';
                }
                field(sellToAddressLine1; "Sell-to Address")
                {
                    Caption = 'Sell-to Address Line 1';
                }
                field(sellToAddressLine2; "Sell-to Address 2")
                {
                    Caption = 'Sell-to Address Line 2';
                }
                field(sellToCity; "Sell-to City")
                {
                    Caption = 'Sell-to City';
                }
                field(sellToCountry; "Sell-to Country/Region Code")
                {
                    Caption = 'Sell-to Country/Region Code';
                }
                field(sellToState; "Sell-to County")
                {
                    Caption = 'Sell-to State';
                }
                field(sellToPostCode; "Sell-to Post Code")
                {
                    Caption = 'Sell-to Post Code';
                }
                field(billToAddressLine1; "Bill-To Address")
                {
                    Caption = 'Bill-to Address Line 1';
                }
                field(billToAddressLine2; "Bill-To Address 2")
                {
                    Caption = 'Bill-to Address Line 2';
                }
                field(billToCity; "Bill-To City")
                {
                    Caption = 'Bill-to City';
                }
                field(billToCountry; "Bill-To Country/Region Code")
                {
                    Caption = 'Bill-to Country/Region Code';
                }
                field(billToState; "Bill-To County")
                {
                    Caption = 'Bill-to State';
                }
                field(billToPostCode; "Bill-To Post Code")
                {
                    Caption = 'Bill-to Post Code';
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
                field(salesperson; "Salesperson Code")
                {
                    Caption = 'Salesperson';
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
                field(phoneNumber; "Sell-to Phone No.")
                {
                    Caption = 'Phone No.';
                }
                field(email; "Sell-to E-Mail")
                {
                    Caption = 'Email';
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