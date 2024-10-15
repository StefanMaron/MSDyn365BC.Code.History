page 5900 "Service Order"
{
    Caption = 'Service Order';
    PageType = Document;
    PromotedActionCategories = 'New,Process,Report,Warehouse,Print/Send,Release,Posting,Order,Navigate';
    RefreshOnActivate = true;
    SourceTable = "Service Header";
    SourceTableView = WHERE("Document Type" = FILTER(Order));

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update;
                    end;
                }
                field(Description; Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a short description of the service document, such as Order 2001.';
                }
                field("Customer No."; "Customer No.")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the customer who owns the items in the service document.';

                    trigger OnValidate()
                    begin
                        CustomerNoOnAfterValidate;
                    end;
                }
                field("Contact No."; "Contact No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the contact to whom you will deliver the service.';

                    trigger OnValidate()
                    begin
                        if GetFilter("Contact No.") = xRec."Contact No." then
                            if "Contact No." <> xRec."Contact No." then
                                SetRange("Contact No.");
                    end;
                }
                group("Sell-To")
                {
                    Caption = 'Sell-To';
                    field(Name; Name)
                    {
                        ApplicationArea = Service;
                        ToolTip = 'Specifies the name of the customer to whom the items on the document will be shipped.';
                    }
                    field(Address; Address)
                    {
                        ApplicationArea = Service;
                        QuickEntry = false;
                        ToolTip = 'Specifies the address of the customer to whom the service will be shipped.';
                    }
                    field("Address 2"; "Address 2")
                    {
                        ApplicationArea = Service;
                        Importance = Additional;
                        QuickEntry = false;
                        ToolTip = 'Specifies additional address information.';
                    }
                    field(City; City)
                    {
                        ApplicationArea = Service;
                        QuickEntry = false;
                        ToolTip = 'Specifies the city of the address.';
                    }
                    group(Control45)
                    {
                        ShowCaption = false;
                        Visible = IsSellToCountyVisible;
                        field(County; County)
                        {
                            ApplicationArea = Service;
                            QuickEntry = false;
                            ToolTip = 'Specifies the state, province or county related to the service order.';
                        }
                    }
                    field("Post Code"; "Post Code")
                    {
                        ApplicationArea = Service;
                        QuickEntry = false;
                        ToolTip = 'Specifies the postal code.';
                    }
                    field("Country/Region Code"; "Country/Region Code")
                    {
                        ApplicationArea = Service;
                        QuickEntry = false;
                        ToolTip = 'Specifies the country/region of the address.';

                        trigger OnValidate()
                        begin
                            IsSellToCountyVisible := FormatAddress.UseCounty("Country/Region Code");
                        end;
                    }
                    field("Contact Name"; "Contact Name")
                    {
                        ApplicationArea = Service;
                        ToolTip = 'Specifies the name of the contact who will receive the service.';
                    }
                }
                field("Phone No."; "Phone No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the phone number of the customer in this service order.';
                }
                field("Phone No. 2"; "Phone No. 2")
                {
                    ApplicationArea = Service;
                    Importance = Additional;
                    ToolTip = 'Specifies your customer''s alternate phone number.';
                }
                field("E-Mail"; "E-Mail")
                {
                    ApplicationArea = Service;
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the email address of the customer in this service order.';
                }
                field("Notify Customer"; "Notify Customer")
                {
                    ApplicationArea = Service;
                    Importance = Additional;
                    ToolTip = 'Specifies how the customer wants to receive notifications about service completion.';
                }
                field("Service Order Type"; "Service Order Type")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the type of this service order.';
                }
                field("Contract No."; "Contract No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the contract associated with the order.';
                }
                field("Response Date"; "Response Date")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies the estimated date when work on the order should start, that is, when the service order status changes from Pending, to In Process.';
                }
                field("Response Time"; "Response Time")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the estimated time when work on the order starts, that is, when the service order status changes from Pending, to In Process.';
                }
                field(Priority; Priority)
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies the priority of the service order.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the service order status, which reflects the repair or maintenance status of all service items on the service order.';
                }
                field("Responsibility Center"; "Responsibility Center")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the code of the responsibility center, such as a distribution hub, that is associated with the involved user, company, customer, or vendor.';
                }
                field("Assigned User ID"; "Assigned User ID")
                {
                    ApplicationArea = Service;
                    Importance = Additional;
                    ToolTip = 'Specifies the ID of the user who is responsible for the document.';
                }
                field("Release Status"; "Release Status")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies if items in the Service Lines window are ready to be handled in warehouse activities.';
                }
            }
            part(ServItemLines; "Service Order Subform")
            {
                ApplicationArea = Service;
                SubPageLink = "Document No." = FIELD("No.");
            }
            group(Invoicing)
            {
                Caption = 'Invoicing';
                field("Bill-to Customer No."; "Bill-to Customer No.")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the customer that you send or sent the invoice or credit memo to.';

                    trigger OnValidate()
                    begin
                        BilltoCustomerNoOnAfterValidat;
                    end;
                }
                field("Bill-to Contact No."; "Bill-to Contact No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the contact person at the customer''s billing address.';
                }
                group("Bill-To")
                {
                    Caption = 'Bill-To';
                    field("Bill-to Name"; "Bill-to Name")
                    {
                        ApplicationArea = Service;
                        Caption = 'Name';
                        ToolTip = 'Specifies the name of the customer that you send or sent the invoice or credit memo to.';
                    }
                    field("Bill-to Address"; "Bill-to Address")
                    {
                        ApplicationArea = Service;
                        Caption = 'Address';
                        QuickEntry = false;
                        ToolTip = 'Specifies the address of the customer to whom you will send the invoice.';
                    }
                    field("Bill-to Address 2"; "Bill-to Address 2")
                    {
                        ApplicationArea = Service;
                        Caption = 'Address 2';
                        Importance = Additional;
                        QuickEntry = false;
                        ToolTip = 'Specifies an additional line of the address.';
                    }
                    field("Bill-to City"; "Bill-to City")
                    {
                        ApplicationArea = Service;
                        Caption = 'City';
                        QuickEntry = false;
                        ToolTip = 'Specifies the city of the address.';
                    }
                    group(Control48)
                    {
                        ShowCaption = false;
                        Visible = IsBillToCountyVisible;
                        field("Bill-to County"; "Bill-to County")
                        {
                            ApplicationArea = Service;
                            Caption = 'County';
                            QuickEntry = false;
                            ToolTip = 'Specifies the state, province or county of the bill-to customer related to the service order.';
                        }
                    }
                    field("Bill-to Post Code"; "Bill-to Post Code")
                    {
                        ApplicationArea = Service;
                        Caption = 'Post Code';
                        QuickEntry = false;
                        ToolTip = 'Specifies the post code of the customer''s billing address.';
                    }
                    field("Bill-to Country/Region Code"; "Bill-to Country/Region Code")
                    {
                        ApplicationArea = Service;
                        Caption = 'Country/Region Code';
                        QuickEntry = false;
                        ToolTip = 'Specifies the customer''s country/region.';

                        trigger OnValidate()
                        begin
                            IsBillToCountyVisible := FormatAddress.UseCounty("Bill-to Country/Region Code");
                        end;
                    }
                    field("Bill-to Contact"; "Bill-to Contact")
                    {
                        ApplicationArea = Service;
                        Caption = 'Contact';
                        ToolTip = 'Specifies the name of the contact person at the customer''s billing address.';
                    }
                }
                field("Your Reference"; "Your Reference")
                {
                    ApplicationArea = Service;
                    Importance = Additional;
                    ToolTip = 'Specifies a customer reference, which will be used when printing service documents.';
                }
                field("Salesperson Code"; "Salesperson Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the salesperson assigned to this service document.';
                }
                field("Max. Labor Unit Price"; "Max. Labor Unit Price")
                {
                    ApplicationArea = Service;
                    Importance = Additional;
                    ToolTip = 'Specifies the maximum unit price that can be set for a resource (for example, a technician) on all service lines linked to this order.';

                    trigger OnValidate()
                    begin
                        MaxLaborUnitPriceOnAfterValida;
                    end;
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the service document should be posted.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
                field("Payment Terms Code"; "Payment Terms Code")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies a formula that calculates the payment due date, payment discount date, and payment discount amount.';
                }
                field("EU 3-Party Trade"; "EU 3-Party Trade")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies if the transaction is related to trade with a third party within the EU.';
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies when the related invoice must be paid.';
                }
                field("Payment Discount %"; "Payment Discount %")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the percentage of payment discount given, if the customer pays by the date entered in the Pmt. Discount Date field.';
                }
                field("Pmt. Discount Date"; "Pmt. Discount Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date on which the amount in the entry must be paid for a payment discount to be granted.';
                }
                field("Payment Method Code"; "Payment Method Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies how to make payment, such as with bank transfer, cash, or check.';
                }
                field("Direct Debit Mandate ID"; "Direct Debit Mandate ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the direct-debit mandate that the customer has signed to allow direct debit collection of payments.';
                }
                field("Tax Liable"; "Tax Liable")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies if the customer or vendor is liable for sales tax.';
                }
                field("Tax Area Code"; "Tax Area Code")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies the tax area that is used to calculate and post sales tax.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies the currency code for various amounts on the service lines.';

                    trigger OnAssistEdit()
                    begin
                        Clear(ChangeExchangeRate);
                        ChangeExchangeRate.SetParameter("Currency Code", "Currency Factor", "Posting Date");
                        if ChangeExchangeRate.RunModal = ACTION::OK then begin
                            Validate("Currency Factor", ChangeExchangeRate.GetParameter);
                            CurrPage.Update;
                        end;
                        Clear(ChangeExchangeRate);
                    end;
                }
                field("Prices Including VAT"; "Prices Including VAT")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies if the Unit Price and Line Amount fields on document lines should be shown with or without VAT.';

                    trigger OnValidate()
                    begin
                        PricesIncludingVATOnAfterValid;
                    end;
                }
                field("VAT Bus. Posting Group"; "VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                }
                group("SII Information")
                {
                    Caption = 'SII Information';
                    field(OperationDescription; OperationDescription)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Operation Description';
                        MultiLine = true;
                        ToolTip = 'Specifies the Operation Description.';

                        trigger OnValidate()
                        var
                            SIIManagement: Codeunit "SII Management";
                        begin
                            SIIManagement.SplitOperationDescription(OperationDescription, "Operation Description", "Operation Description 2");
                            Validate("Operation Description");
                            Validate("Operation Description 2");
                            Modify(true);
                        end;
                    }
                    group(Control1100009)
                    {
                        ShowCaption = false;
                        Visible = DocHasMultipleRegimeCode;
                        field(MultipleSchemeCodesControl; MultipleSchemeCodesLbl)
                        {
                            ApplicationArea = Basic, Suite;
                            Editable = false;
                            ShowCaption = false;
                            Style = StandardAccent;
                            StyleExpr = TRUE;

                            trigger OnDrillDown()
                            var
                                SIISchemeCodeMgt: Codeunit "SII Scheme Code Mgt.";
                            begin
                                SIISchemeCodeMgt.SalesDrillDownRegimeCodes(Rec);
                            end;
                        }
                    }
                    field("Special Scheme Code"; "Special Scheme Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = NOT DocHasMultipleRegimeCode;
                        ToolTip = 'Specifies the Special Scheme Code.';
                    }
                    field("Invoice Type"; "Invoice Type")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the Special Scheme Code.';
                    }
                    field("ID Type"; "ID Type")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the ID Type.';
                    }
                    field("Succeeded Company Name"; "Succeeded Company Name")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the name of the company sucessor in connection with corporate restructuring.';
                    }
                    field("Succeeded VAT Registration No."; "Succeeded VAT Registration No.")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the VAT registration number of the company sucessor in connection with corporate restructuring.';
                    }
                }
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field("Ship-to Code"; "Ship-to Code")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';

                    trigger OnValidate()
                    begin
                        ShiptoCodeOnAfterValidate;
                    end;
                }
                group("Ship-To")
                {
                    Caption = 'Ship-To';
                    field("Ship-to Name"; "Ship-to Name")
                    {
                        ApplicationArea = Service;
                        Caption = 'Name';
                        ToolTip = 'Specifies the name of the customer at the address that the items are shipped to.';
                    }
                    field("Ship-to Address"; "Ship-to Address")
                    {
                        ApplicationArea = Service;
                        Caption = 'Address';
                        QuickEntry = false;
                        ToolTip = 'Specifies the address that the items are shipped to.';
                    }
                    field("Ship-to Address 2"; "Ship-to Address 2")
                    {
                        ApplicationArea = Service;
                        Caption = 'Address 2';
                        Importance = Additional;
                        QuickEntry = false;
                        ToolTip = 'Specifies an additional part of the ship-to address, in case it is a long address.';
                    }
                    field("Ship-to City"; "Ship-to City")
                    {
                        ApplicationArea = Service;
                        Caption = 'City';
                        QuickEntry = false;
                        ToolTip = 'Specifies the city of the address that the items are shipped to.';
                    }
                    group(Control49)
                    {
                        ShowCaption = false;
                        Visible = IsShipToCountyVisible;
                        field("Ship-to County"; "Ship-to County")
                        {
                            ApplicationArea = Service;
                            Caption = 'County';
                            QuickEntry = false;
                            ToolTip = 'Specifies the state, province or county related to the service order.';
                        }
                    }
                    field("Ship-to Post Code"; "Ship-to Post Code")
                    {
                        ApplicationArea = Service;
                        Caption = 'Post Code';
                        Importance = Promoted;
                        QuickEntry = false;
                        ToolTip = 'Specifies the postal code of the address that the items are shipped to.';
                    }
                    field("Ship-to Country/Region Code"; "Ship-to Country/Region Code")
                    {
                        ApplicationArea = Service;
                        Caption = 'Country/Region';
                        QuickEntry = false;
                        ToolTip = 'Specifies the customer''s country/region.';

                        trigger OnValidate()
                        begin
                            IsShipToCountyVisible := FormatAddress.UseCounty("Ship-to Country/Region Code");
                        end;
                    }
                    field("Ship-to Contact"; "Ship-to Contact")
                    {
                        ApplicationArea = Service;
                        Caption = 'Contact';
                        Importance = Promoted;
                        ToolTip = 'Specifies the name of the contact person at the address that the items are shipped to.';
                    }
                }
                field("Ship-to Phone"; "Ship-to Phone")
                {
                    ApplicationArea = Service;
                    Caption = 'Ship-to Phone';
                    ToolTip = 'Specifies the phone number of the address where the service items in the order are located.';
                }
                field("Ship-to Phone 2"; "Ship-to Phone 2")
                {
                    ApplicationArea = Service;
                    Importance = Additional;
                    ToolTip = 'Specifies an additional phone number at address that the items are shipped to.';
                }
                field("Ship-to E-Mail"; "Ship-to E-Mail")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the email address at the address that the items are shipped to.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code of the location (for example, warehouse or distribution center) of the items specified on the service item lines.';
                }
                field("Shipping Advice"; "Shipping Advice")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies information about whether the customer will accept a partial shipment of the order.';
                }
                field("Shipment Method Code"; "Shipment Method Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the delivery conditions of the related shipment, such as free on board (FOB).';
                }
                field("Shipping Agent Code"; "Shipping Agent Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code for the shipping agent who is transporting the items.';
                }
                field("Shipping Agent Service Code"; "Shipping Agent Service Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code for the service, such as a one-day delivery, that is offered by the shipping agent.';
                }
                field("Shipping Time"; "Shipping Time")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies how long it takes from when the items are shipped from the warehouse to when they are delivered.';
                }
            }
            group(Details)
            {
                Caption = 'Details';
                field("Warning Status"; "Warning Status")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies the response time warning status for the order.';
                }
                field("Link Service to Service Item"; "Link Service to Service Item")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that service lines for items and resources must be linked to a service item line.';
                }
                field("Allocated Hours"; "Allocated Hours")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of hours allocated to the items in this service order.';
                }
                field("No. of Allocations"; "No. of Allocations")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of resource allocations to service items in this order.';
                }
                field("No. of Unallocated Items"; "No. of Unallocated Items")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of service items in this order that are not allocated to resources.';
                }
                field("Service Zone Code"; "Service Zone Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the service zone code of the customer''s ship-to address in the service order.';
                }
                field("Order Date"; "Order Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the order was created.';

                    trigger OnValidate()
                    begin
                        OrderDateOnAfterValidate;
                    end;
                }
                field("Order Time"; "Order Time")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the time when the service order was created.';

                    trigger OnValidate()
                    begin
                        OrderTimeOnAfterValidate;
                    end;
                }
                field("Expected Finishing Date"; "Expected Finishing Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when service on the order is expected to be finished.';
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies the starting date of the service, that is, the date when the order status changes from Pending, to In Process for the first time.';
                }
                field("Starting Time"; "Starting Time")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the starting time of the service, that is, the time when the order status changes from Pending, to In Process for the first time.';
                }
                field("Actual Response Time (Hours)"; "Actual Response Time (Hours)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of hours from order creation, to when the service order status changes from Pending, to In Process.';
                }
                field("Finishing Date"; "Finishing Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the finishing date of the service, that is, the date when the Status field changes to Finished.';
                }
                field("Finishing Time"; "Finishing Time")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the finishing time of the service, that is, the time when the Status field changes to Finished.';

                    trigger OnValidate()
                    begin
                        FinishingTimeOnAfterValidate;
                    end;
                }
                field("Service Time (Hours)"; "Service Time (Hours)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the total time in hours that the service specified in the order has taken.';
                }
            }
            group(" Foreign Trade")
            {
                Caption = ' Foreign Trade';
                field("Transaction Type"; "Transaction Type")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the type of transaction that the document represents, for the purpose of reporting to INTRASTAT.';
                }
                field("Transaction Specification"; "Transaction Specification")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies a specification of the document''s transaction, for the purpose of reporting to INTRASTAT.';
                }
                field("Transport Method"; "Transport Method")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the transport method, for the purpose of reporting to INTRASTAT.';
                }
                field("Exit Point"; "Exit Point")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the point of exit through which you ship the items out of your country/region, for reporting to Intrastat.';
                }
                field("Area"; Area)
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the area of the customer or vendor, for the purpose of reporting to INTRASTAT.';
                }
            }
        }
        area(factboxes)
        {
            part(Control1902018507; "Customer Statistics FactBox")
            {
                ApplicationArea = Service;
                SubPageLink = "No." = FIELD("Bill-to Customer No.");
                Visible = false;
            }
            part(Control1900316107; "Customer Details FactBox")
            {
                ApplicationArea = Service;
                SubPageLink = "No." = FIELD("Customer No.");
                Visible = false;
            }
            part(Control1907829707; "Service Hist. Sell-to FactBox")
            {
                ApplicationArea = Service;
                SubPageLink = "No." = FIELD("Customer No.");
                Visible = true;
            }
            part(Control1902613707; "Service Hist. Bill-to FactBox")
            {
                ApplicationArea = Service;
                SubPageLink = "No." = FIELD("Bill-to Customer No.");
                Visible = false;
            }
            part(Control1906530507; "Service Item Line FactBox")
            {
                ApplicationArea = Service;
                Provider = ServItemLines;
                SubPageLink = "Document Type" = FIELD("Document Type"),
                              "Document No." = FIELD("Document No."),
                              "Line No." = FIELD("Line No.");
                Visible = true;
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("O&rder")
            {
                Caption = 'O&rder';
                Image = "Order";
                action("Demand Overview")
                {
                    ApplicationArea = Planning;
                    Caption = 'Demand Overview';
                    Image = Forecast;
                    ToolTip = 'Get an overview of demand for your items when planning sales, production, jobs, or service management and when they will be available.';

                    trigger OnAction()
                    var
                        DemandOverview: Page "Demand Overview";
                    begin
                        DemandOverview.SetCalculationParameter(true);
                        DemandOverview.Initialize(0D, 4, "No.", '', '');
                        DemandOverview.RunModal;
                    end;
                }
                action("<Action7>")
                {
                    AccessByPermission = TableData "Order Promising Line" = R;
                    ApplicationArea = OrderPromising;
                    Caption = 'Order Promising';
                    Image = OrderPromising;
                    ToolTip = 'Calculate the shipment and delivery dates based on the item''s known and expected availability dates, and then promise the dates to the customer.';

                    trigger OnAction()
                    var
                        OrderPromisingLine: Record "Order Promising Line";
                        OrderPromisingLines: Page "Order Promising Lines";
                    begin
                        Clear(OrderPromisingLines);
                        OrderPromisingLines.SetSourceType(12); // Service order
                        Clear(OrderPromisingLine);
                        OrderPromisingLine.SetRange("Source Type", OrderPromisingLine."Source Type"::"Service Order");
                        OrderPromisingLine.SetRange("Source ID", "No.");
                        OrderPromisingLines.SetTableView(OrderPromisingLine);
                        OrderPromisingLines.RunModal;
                    end;
                }
                action("&Customer Card")
                {
                    ApplicationArea = Service;
                    Caption = '&Customer Card';
                    Image = Customer;
                    RunObject = Page "Customer Card";
                    RunPageLink = "No." = FIELD("Customer No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View detailed information about the customer.';
                }
                action("&Dimensions")
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = '&Dimensions';
                    Enabled = "No." <> '';
                    Image = Dimensions;
                    Promoted = true;
                    PromotedCategory = Category8;
                    PromotedIsBig = true;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to journal lines to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDocDim;
                    end;
                }
                action("Service Document Lo&g")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Document Lo&g';
                    Image = Log;
                    ToolTip = 'View a list of the service document changes that have been logged. The program creates entries in the window when, for example, the response time or service order status changed, a resource was allocated, a service order was shipped or invoiced, and so on. Each line in this window identifies the event that occurred to the service document. The line contains the information about the field that was changed, its old and new value, the date and time when the change took place, and the ID of the user who actually made the changes.';

                    trigger OnAction()
                    var
                        ServDocLog: Record "Service Document Log";
                    begin
                        ServDocLog.ShowServDocLog(Rec);
                    end;
                }
                action("Email &Queue")
                {
                    ApplicationArea = Service;
                    Caption = 'Email &Queue';
                    Image = Email;
                    RunObject = Page "Service Email Queue";
                    RunPageLink = "Document Type" = CONST("Service Order"),
                                  "Document No." = FIELD("No.");
                    RunPageView = SORTING("Document Type", "Document No.");
                    ToolTip = 'View the list of emails that are waiting to be sent automatically to notify customers about their service item.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    Promoted = true;
                    PromotedCategory = Category8;
                    RunObject = Page "Service Comment Sheet";
                    RunPageLink = "Table Name" = CONST("Service Header"),
                                  "Table Subtype" = FIELD("Document Type"),
                                  "No." = FIELD("No."),
                                  Type = CONST(General);
                    ToolTip = 'View or add comments for the record.';
                }
                action(SpecialSchemeCodes)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Special Scheme Codes';
                    Image = Allocations;
                    Promoted = true;
                    PromotedCategory = Category8;
                    PromotedIsBig = true;
                    ToolTip = 'View or edit the list of special scheme codes that related to the current document for VAT reporting.';

                    trigger OnAction()
                    var
                        SIISchemeCodeMgt: Codeunit "SII Scheme Code Mgt.";
                    begin
                        SIISchemeCodeMgt.SalesDrillDownRegimeCodes(Rec);
                        CurrPage.Update(false);
                    end;
                }
            }
            group("<Action36>")
            {
                Caption = 'Statistics';
                Image = Statistics;
                action(Statistics)
                {
                    ApplicationArea = Service;
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Category8;
                    PromotedIsBig = true;
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';

                    trigger OnAction()
                    var
                        SalesSetup: Record "Sales & Receivables Setup";
                        ServLine: Record "Service Line";
                        ServLines: Page "Service Lines";
                    begin
                        SalesSetup.Get();
                        if SalesSetup."Calc. Inv. Discount" then begin
                            ServLine.Reset();
                            ServLine.SetRange("Document Type", "Document Type");
                            ServLine.SetRange("Document No.", "No.");
                            if ServLine.FindFirst then begin
                                ServLines.SetTableView(ServLine);
                                ServLines.CalcInvDisc(ServLine);
                                Commit
                            end;
                        end;
                        PAGE.RunModal(PAGE::"Service Order Statistics", Rec);
                    end;
                }
            }
            group(Documents)
            {
                Caption = 'Documents';
                Image = Documents;
                action("S&hipments")
                {
                    ApplicationArea = Service;
                    Caption = 'S&hipments';
                    Image = Shipment;
                    Promoted = true;
                    PromotedCategory = Category9;
                    RunObject = Page "Posted Service Shipments";
                    RunPageLink = "Order No." = FIELD("No.");
                    RunPageView = SORTING("Order No.");
                    ToolTip = 'View related posted service shipments.';
                }
                action(Invoices)
                {
                    ApplicationArea = Service;
                    Caption = 'Invoices';
                    Image = Invoice;
                    Promoted = true;
                    PromotedCategory = Category9;
                    RunObject = Page "Posted Service Invoices";
                    RunPageLink = "Order No." = FIELD("No.");
                    RunPageView = SORTING("Order No.");
                    ToolTip = 'View a list of ongoing sales invoices for the order.';
                }
            }
            group("W&arehouse")
            {
                Caption = 'W&arehouse';
                Image = Warehouse;
                action("Warehouse Shipment Lines")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Warehouse Shipment Lines';
                    Image = ShipmentLines;
                    Promoted = true;
                    PromotedCategory = Category4;
                    RunObject = Page "Whse. Shipment Lines";
                    RunPageLink = "Source Type" = CONST(5902),
                                  "Source Subtype" = FIELD("Document Type"),
                                  "Source No." = FIELD("No.");
                    RunPageView = SORTING("Source Type", "Source Subtype", "Source No.", "Source Line No.");
                    ToolTip = 'View ongoing warehouse shipments for the document, in advanced warehouse configurations.';
                }
            }
            group(History)
            {
                Caption = 'History';
                Image = History;
                action("Service Ledger E&ntries")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Ledger E&ntries';
                    Image = ServiceLedger;
                    RunObject = Page "Service Ledger Entries";
                    RunPageLink = "Service Order No." = FIELD("No.");
                    RunPageView = SORTING("Service Order No.", "Service Item No. (Serviced)", "Entry Type", "Moved from Prepaid Acc.", "Posting Date", Open, Type);
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View all the ledger entries for the service item or service order that result from posting transactions in service documents.';
                }
                action("&Warranty Ledger Entries")
                {
                    ApplicationArea = Service;
                    Caption = '&Warranty Ledger Entries';
                    Image = WarrantyLedger;
                    RunObject = Page "Warranty Ledger Entries";
                    RunPageLink = "Service Order No." = FIELD("No.");
                    RunPageView = SORTING("Service Order No.", "Posting Date", "Document No.");
                    ToolTip = 'View all the ledger entries for the service item or service order that result from posting transactions in service documents that contain warranty agreements.';
                }
                action("&Job Ledger Entries")
                {
                    ApplicationArea = Service;
                    Caption = '&Job Ledger Entries';
                    Image = JobLedger;
                    RunObject = Page "Job Ledger Entries";
                    RunPageLink = "Service Order No." = FIELD("No.");
                    RunPageView = SORTING("Service Order No.", "Posting Date")
                                  WHERE("Entry Type" = CONST(Usage));
                    ToolTip = 'View all the job ledger entries that result from posting transactions in the service document that involve a job.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Create Customer")
                {
                    ApplicationArea = Service;
                    Caption = '&Create Customer';
                    Image = NewCustomer;
                    ToolTip = 'Create a new customer card for the customer on the service document.';

                    trigger OnAction()
                    begin
                        Clear(ServOrderMgt);
                        ServOrderMgt.CreateNewCustomer(Rec);
                        CurrPage.Update(true);
                    end;
                }
            }
            group(Action27)
            {
                Caption = 'W&arehouse';
                Image = Warehouse;
                action("Release to Ship")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Release to Ship';
                    Image = ReleaseShipment;
                    Promoted = true;
                    PromotedCategory = Category6;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Signal to warehouse workers that the service item is ready to be picked and shipped to the customer''s address.';

                    trigger OnAction()
                    var
                        ReleaseServiceDocument: Codeunit "Release Service Document";
                    begin
                        ReleaseServiceDocument.PerformManualRelease(Rec);
                    end;
                }
                action(Reopen)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Reopen';
                    Image = ReOpen;
                    Promoted = true;
                    PromotedCategory = Category6;
                    PromotedOnly = true;
                    ToolTip = 'Reactivate the service order after it has been released for warehouse handling.';

                    trigger OnAction()
                    var
                        ReleaseServiceDocument: Codeunit "Release Service Document";
                    begin
                        ReleaseServiceDocument.PerformManualReopen(Rec);
                    end;
                }
                action("Create Whse Shipment")
                {
                    AccessByPermission = TableData "Warehouse Shipment Header" = R;
                    ApplicationArea = Warehouse;
                    Caption = 'Create Warehouse Shipment';
                    Image = NewShipment;
                    Promoted = true;
                    PromotedCategory = Category4;
                    ToolTip = 'Prepare to pick and ship the service item. ';

                    trigger OnAction()
                    var
                        GetSourceDocOutbound: Codeunit "Get Source Doc. Outbound";
                    begin
                        GetSourceDocOutbound.CreateFromServiceOrder(Rec);
                        if not Find('=><') then
                            Init;
                    end;
                }
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action(TestReport)
                {
                    ApplicationArea = Service;
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'View a test report so that you can find and correct any errors before you perform the actual posting of the journal or document.';

                    trigger OnAction()
                    var
                        ReportPrint: Codeunit "Test Report-Print";
                    begin
                        ReportPrint.PrintServiceHeader(Rec);
                    end;
                }
                action(Post)
                {
                    ApplicationArea = Service;
                    Caption = 'P&ost';
                    Ellipsis = true;
                    Image = PostOrder;
                    Promoted = true;
                    PromotedCategory = Category7;
                    PromotedIsBig = true;
                    ShortCutKey = 'F9';
                    ToolTip = 'Finalize the document or journal by posting the amounts and quantities to the related accounts in your company books.';

                    trigger OnAction()
                    var
                        ServPostYesNo: Codeunit "Service-Post (Yes/No)";
                        InstructionMgt: Codeunit "Instruction Mgt.";
                    begin
                        ServHeader.Get("Document Type", "No.");
                        ServPostYesNo.PostDocument(ServHeader);
                        DocumentIsPosted := not ServHeader.Get("Document Type", "No.");
                        if InstructionMgt.IsEnabled(InstructionMgt.ShowPostedConfirmationMessageCode) then
                            ShowPostedConfirmationMessage;
                        CurrPage.Update(false);
                    end;
                }
                action(Preview)
                {
                    ApplicationArea = Service;
                    Caption = 'Preview Posting';
                    Image = ViewPostedOrder;
                    Promoted = true;
                    PromotedCategory = Category7;
                    ToolTip = 'Review the different types of entries that will be created when you post the document or journal.';

                    trigger OnAction()
                    var
                        ServPostYesNo: Codeunit "Service-Post (Yes/No)";
                    begin
                        ServHeader.Get("Document Type", "No.");
                        ServPostYesNo.PreviewDocument(ServHeader);
                        DocumentIsPosted := not ServHeader.Get("Document Type", "No.");
                    end;
                }
                action("Post and &Print")
                {
                    ApplicationArea = Service;
                    Caption = 'Post and &Print';
                    Ellipsis = true;
                    Image = PostPrint;
                    Promoted = true;
                    PromotedCategory = Category7;
                    PromotedIsBig = true;
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Finalize and prepare to print the document or journal. The values and quantities are posted to the related accounts. A report request window where you can specify what to include on the print-out.';

                    trigger OnAction()
                    var
                        ServPostPrint: Codeunit "Service-Post+Print";
                    begin
                        ServHeader.Get("Document Type", "No.");
                        ServPostPrint.PostDocument(ServHeader);
                        DocumentIsPosted := not ServHeader.Get("Document Type", "No.");
                    end;
                }
                action(PostBatch)
                {
                    ApplicationArea = Service;
                    Caption = 'Post &Batch';
                    Ellipsis = true;
                    Image = PostBatch;
                    ToolTip = 'Post several documents at once. A report request window opens where you can specify which documents to post.';

                    trigger OnAction()
                    begin
                        Clear(ServHeader);
                        ServHeader.CopyFilters(Rec);
                        ServHeader.SetRange(Status, ServHeader.Status::Finished);
                        REPORT.RunModal(REPORT::"Batch Post Service Orders", true, true, ServHeader);
                        CurrPage.Update(false);
                    end;
                }
            }
            action("&Print")
            {
                ApplicationArea = Service;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                Promoted = true;
                PromotedCategory = Category5;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                var
                    DocPrint: Codeunit "Document-Print";
                begin
                    CurrPage.Update(true);
                    DocPrint.PrintServiceHeader(Rec);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        SIIManagement: Codeunit "SII Management";
    begin
        SIIManagement.CombineOperationDescription("Operation Description", "Operation Description 2", OperationDescription);
        UpdateDocHasRegimeCode();
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        CurrPage.SaveRecord;
        Clear(ServLogMgt);
        ServLogMgt.ServHeaderManualDelete(Rec);
        exit(ConfirmDeletion);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        "Document Type" := "Document Type"::Order;
        "Responsibility Center" := UserMgt.GetServiceFilter;
        if "No." = '' then
            SetCustomerFromFilter;
    end;

    trigger OnOpenPage()
    var
        SIIManagement: Codeunit "SII Management";
    begin
        if UserMgt.GetServiceFilter <> '' then begin
            FilterGroup(2);
            SetRange("Responsibility Center", UserMgt.GetServiceFilter);
            FilterGroup(0);
        end;
        if ("No." <> '') and ("Customer No." = '') then
            DocumentIsPosted := (not Get("Document Type", "No."));

        SIIManagement.CombineOperationDescription("Operation Description", "Operation Description 2", OperationDescription);
        UpdateDocHasRegimeCode();
        ActivateFields;
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateDocHasRegimeCode();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if not DocumentIsPosted then
            exit(ConfirmCloseUnposted);
    end;

    var
        ServHeader: Record "Service Header";
        ServOrderMgt: Codeunit ServOrderManagement;
        ServLogMgt: Codeunit ServLogManagement;
        UserMgt: Codeunit "User Setup Management";
        FormatAddress: Codeunit "Format Address";
        ChangeExchangeRate: Page "Change Exchange Rate";
        DocumentIsPosted: Boolean;
        OpenPostedServiceOrderQst: Label 'The order is posted as number %1 and moved to the Posted Service Invoices window.\\Do you want to open the posted invoice?', Comment = '%1 = posted document number';
        IsBillToCountyVisible: Boolean;
        IsSellToCountyVisible: Boolean;
        IsShipToCountyVisible: Boolean;
        DocHasMultipleRegimeCode: Boolean;
        OperationDescription: Text[500];
        MultipleSchemeCodesLbl: Label 'Multiple scheme codes';

    local procedure ActivateFields()
    begin
        IsBillToCountyVisible := FormatAddress.UseCounty("Bill-to Country/Region Code");
        IsSellToCountyVisible := FormatAddress.UseCounty("Country/Region Code");
        IsShipToCountyVisible := FormatAddress.UseCounty("Ship-to Country/Region Code");
    end;

    local procedure CustomerNoOnAfterValidate()
    begin
        if GetFilter("Customer No.") = xRec."Customer No." then
            if "Customer No." <> xRec."Customer No." then
                SetRange("Customer No.");
        CurrPage.Update;
    end;

    local procedure BilltoCustomerNoOnAfterValidat()
    begin
        CurrPage.Update;
    end;

    local procedure MaxLaborUnitPriceOnAfterValida()
    begin
        CurrPage.SaveRecord;
    end;

    local procedure PricesIncludingVATOnAfterValid()
    begin
        CurrPage.Update;
    end;

    local procedure ShiptoCodeOnAfterValidate()
    begin
        CurrPage.Update;
    end;

    local procedure OrderTimeOnAfterValidate()
    begin
        UpdateResponseDateTime;
        CurrPage.Update;
    end;

    local procedure OrderDateOnAfterValidate()
    begin
        UpdateResponseDateTime;
        CurrPage.Update;
    end;

    local procedure FinishingTimeOnAfterValidate()
    begin
        CurrPage.Update(true);
    end;

    local procedure ShowPostedConfirmationMessage()
    var
        OrderServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        if not OrderServiceHeader.Get("Document Type", "No.") then begin
            ServiceInvoiceHeader.SetRange("No.", ServHeader."Last Posting No.");
            if ServiceInvoiceHeader.FindFirst then
                if InstructionMgt.ShowConfirm(StrSubstNo(OpenPostedServiceOrderQst, ServiceInvoiceHeader."No."),
                     InstructionMgt.ShowPostedConfirmationMessageCode)
                then
                    PAGE.Run(PAGE::"Posted Service Invoice", ServiceInvoiceHeader);
        end;
    end;

    local procedure UpdateDocHasRegimeCode()
    var
        SIISchemeCodeMgt: Codeunit "SII Scheme Code Mgt.";
    begin
        DocHasMultipleRegimeCode := SIISchemeCodeMgt.SalesDocHasRegimeCodes(Rec);
    end;
}

