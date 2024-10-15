namespace Microsoft.Sales.Customer;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Address;

page 1382 "Customer Templ. Card"
{
    Caption = 'Customer Template';
    PageType = Card;
    SourceTable = "Customer Templ.";

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the template.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the template.';
                }
                field("Contact Type"; Rec."Contact Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of contact that will be used to create a customer with the template.';
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which transactions with the customer that cannot be processed, for example, because the customer is insolvent.';
                }
                field("No. Series"; Rec."No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series that will be used to assign numbers to customers.';
                }
                field("Privacy Blocked"; Rec."Privacy Blocked")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies whether to limit access to data for the data subject during daily operations. This is useful, for example, when protecting data from changes while it is under privacy review.';
                    Visible = false;
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a code for the salesperson who normally handles this customer''s account.';
                    Visible = false;
                }
                field("IC Partner Code"; Rec."IC Partner Code")
                {
                    ApplicationArea = Intercompany;
                    Importance = Additional;
                    ToolTip = 'Specifies the customer''s intercompany partner code.';
                    Visible = false;
                }
                field("Disable Search by Name"; Rec."Disable Search by Name")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies that you can change customer name in the document, because the name is not used in search.';
                    Visible = false;
                }
                field("Responsibility Center"; Rec."Responsibility Center")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the code for the responsibility center that will administer this customer by default.';
                    Visible = false;
                }
                field("Service Zone Code"; Rec."Service Zone Code")
                {
                    ApplicationArea = Service;
                    Importance = Additional;
                    ToolTip = 'Specifies the code for the service zone that is assigned to the customer.';
                    Visible = false;
                }
                field("Credit Limit (LCY)"; Rec."Credit Limit (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the maximum amount you allow the customer to exceed the payment balance before warnings are issued.';
                    Visible = false;
                }
            }
            group(Registration)
            {
                Caption = 'Registration';
                group("APAC Requirements")
                {
                    Caption = 'APAC Requirements';
                }
                field("IRD No."; Rec."IRD No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Australian Company Number for Australia or the Inland Revenue Department Number for New Zealand.';
                }
                field(ABN; Rec.ABN)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Australian Business Number.';
                }
                field("ABN Division Part No."; Rec."ABN Division Part No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Australian Business Number Division Part Number.';
                }
                field(Registered; Rec.Registered)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the vendor is registered for VAT with the ATO.';
                }
            }
            group("Address & Contact")
            {
                Caption = 'Address & Contact';
                group(AddressDetails)
                {
                    Caption = 'Address';
                    field(Address; Rec.Address)
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the customer''s address. This address will appear on all sales documents for the customer.';
                        Visible = false;
                    }
                    field("Address 2"; Rec."Address 2")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies additional address information.';
                        Visible = false;
                    }
                    field("Country/Region Code"; Rec."Country/Region Code")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the country/region of the address.';

                        trigger OnValidate()
                        begin
                            IsCountyVisible := FormatAddress.UseCounty(Rec."Country/Region Code");
                        end;
                    }
                    field(City; Rec.City)
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the customer''s city.';
                    }
                    group(CountyGroup)
                    {
                        ShowCaption = false;
                        Visible = IsCountyVisible;
                        field(County; Rec.County)
                        {
                            ApplicationArea = Basic, Suite;
                            ToolTip = 'Specifies the state, province or county as a part of the address.';
                        }
                    }
                    field("Post Code"; Rec."Post Code")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the postal code.';
                    }
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer''s telephone number.';
                    Visible = false;
                }
                field(MobilePhoneNo; Rec."Mobile Phone No.")
                {
                    Caption = 'Mobile Phone No.';
                    ApplicationArea = Basic, Suite;
                    ExtendedDatatype = PhoneNo;
                    ToolTip = 'Specifies the customer''s mobile telephone number.';
                    Visible = false;
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the customer''s email address.';
                    Visible = false;
                }
                field("Fax No."; Rec."Fax No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer''s fax number.';
                    Visible = false;
                }
                field("Home Page"; Rec."Home Page")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer''s home page address.';
                    Visible = false;
                }
                group(ContactDetails)
                {
                    Caption = 'Contact';
                    field("Language Code"; Rec."Language Code")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the language to be used on printouts for this customer.';
                    }
                    field("Format Region"; Rec."Format Region")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the region format to be used on printouts for this customer.';
                    }
                    field("Document Sending Profile"; Rec."Document Sending Profile")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the preferred method of sending documents to this customer.';
                    }
                }
            }
            group(Invoicing)
            {
                Caption = 'Invoicing';
                field("Bill-to Customer No."; Rec."Bill-to Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies a different customer who will be invoiced for products that you sell to the customer in the Name field on the customer card.';
                }
                field("Validate EU Vat Reg. No."; Rec."Validate EU Vat Reg. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the VAT registration number will be specified in the EU VAT Registration No. Check page so that it is validated against the VAT registration number validation service.';
                }
                field("VAT Registration No."; Rec."VAT Registration No.")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the customer''s VAT registration number for customers in EU countries/regions.';
                    Visible = false;
                }
                field("EORI Number"; Rec."EORI Number")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Economic Operators Registration and Identification number that is used when you exchange information with the customs authorities due to trade into or out of the European Union.';
                    Visible = false;
                }
                field(GLN; Rec.GLN)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer in connection with electronic document sending.';
                    Visible = false;
                }
                field("Use GLN in Electronic Document"; Rec."Use GLN in Electronic Document")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the GLN is used in electronic documents as a party identification number.';
                    Visible = false;
                }
                field("Copy Sell-to Addr. to Qte From"; Rec."Copy Sell-to Addr. to Qte From")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which customer address is inserted on sales quotes that you create for the customer.';
                    Visible = false;
                }
                field("Tax Document Type"; Rec."Tax Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the tax document type for how the tax document should be generated.';
                }
                field("Tax Liable"; Rec."Tax Liable")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies if the customer or vendor is liable for sales tax.';
                    Visible = false;
                }
                field("Tax Area Code"; Rec."Tax Area Code")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies the tax area that is used to calculate and post sales tax.';
                    Visible = false;
                }
                group(PostingDetails)
                {
                    Caption = 'Posting Details';
                    field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Promoted;
                        ShowMandatory = true;
                        ToolTip = 'Specifies the customer''s trade type to link transactions made for this customer with the appropriate general ledger account according to the general posting setup.';
                    }
                    field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the customer''s VAT specification to link transactions made for this customer to.';
                    }
                    field("WHT Business Posting Group"; Rec."WHT Business Posting Group")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies a WHT business posting group.';
                    }
                    field("Customer Posting Group"; Rec."Customer Posting Group")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Promoted;
                        ShowMandatory = true;
                        ToolTip = 'Specifies the customer''s market type to link business transactions to.';
                    }
                }
                group(PricesandDiscounts)
                {
                    Caption = 'Prices and Discounts';
                    field("Currency Code"; Rec."Currency Code")
                    {
                        ApplicationArea = Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the default currency for the customer.';
                    }
                    field("Customer Price Group"; Rec."Customer Price Group")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Promoted;
                        ToolTip = 'Specifies the customer price group code, which you can use to set up special sales prices in the Sales Prices page.';
                    }
                    field("Customer Disc. Group"; Rec."Customer Disc. Group")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Promoted;
                        ToolTip = 'Specifies the customer discount group code, which you can use as a criterion to set up special discounts in the Sales Line Discounts page.';
                    }
                    field("Allow Line Disc."; Rec."Allow Line Disc.")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies whether to calculate a sales line discount when a special sales price is offered, according to setup in the Sales Prices page.';
                    }
                    field("Invoice Disc. Code"; Rec."Invoice Disc. Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies a code for the invoice discount terms that you have defined for the customer.';
                    }
                    field("Prices Including VAT"; Rec."Prices Including VAT")
                    {
                        ApplicationArea = VAT;
                        Importance = Additional;
                        ToolTip = 'Specifies whether to show VAT in the Unit Price and Line Amount fields on document lines.';
                    }
                }
            }
            group(Payments)
            {
                Caption = 'Payments';
                field("Prepayment %"; Rec."Prepayment %")
                {
                    ApplicationArea = Prepayments;
                    Importance = Additional;
                    ToolTip = 'Specifies a prepayment percentage that applies to all orders for this customer, regardless of the items or services on the order lines.';
                    Visible = false;
                }
                field("Application Method"; Rec."Application Method")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies how to apply payments to entries for this customer.';
                }
                field("Partner Type"; Rec."Partner Type")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies for direct debit collections if the customer that the payment is collected from is a person or a company.';
                }
                field("Intrastat Partner Type"; Rec."Intrastat Partner Type")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies for Intrastat reporting if the customer is a person or a company.';
                }
                field("Payment Terms Code"; Rec."Payment Terms Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ShowMandatory = true;
                    ToolTip = 'Specifies a code that indicates the payment terms that you require of the customer.';
                }
                field("Payment Method Code"; Rec."Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies how the customer usually submits payment, such as bank transfer or check.';
                }
                field("Reminder Terms Code"; Rec."Reminder Terms Code")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies how reminders about late payments are handled for this customer.';
                }
                field("Fin. Charge Terms Code"; Rec."Fin. Charge Terms Code")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies whether to calculate finance charges for the customer.';
                }
                field("Cash Flow Payment Terms Code"; Rec."Cash Flow Payment Terms Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies a payment term that will be used to calculate cash flow for the customer.';
                    Visible = false;
                }
                field("Print Statements"; Rec."Print Statements")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies whether to include this customer when you print the Statement report.';
                }
                field("Block Payment Tolerance"; Rec."Block Payment Tolerance")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies that the customer is not allowed a payment tolerance.';
                }
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    Importance = Promoted;
                    ToolTip = 'Specifies from which location sales to this customer will be processed by default.';
                }
                field("Combine Shipments"; Rec."Combine Shipments")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if several orders delivered to the customer can appear on the same sales invoice.';
                    Visible = false;
                }
                field(Reserve; Rec.Reserve)
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies whether items will never, automatically (Always), or optionally be reserved for this customer.';
                    Visible = false;
                }
                field("Shipping Advice"; Rec."Shipping Advice")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies if the customer accepts partial shipment of orders.';
                    Visible = false;
                }
                group("Shipment Method")
                {
                    Caption = 'Shipment Method';
                    field("Shipment Method Code"; Rec."Shipment Method Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Code';
                        Importance = Promoted;
                        ToolTip = 'Specifies which shipment method to use when you ship items to the customer.';
                    }
                    field("Shipping Agent Code"; Rec."Shipping Agent Code")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Agent';
                        ToolTip = 'Specifies which shipping company is used when you ship items to the customer.';
                        Visible = false;
                    }
                    field("Shipping Agent Service Code"; Rec."Shipping Agent Service Code")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Agent Service';
                        Importance = Additional;
                        ToolTip = 'Specifies the code for the shipping agent service to use for this customer.';
                        Visible = false;
                    }
                }
                field("Shipping Time"; Rec."Shipping Time")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies how long it takes from when the items are shipped from the warehouse to when they are delivered.';
                    Visible = false;
                }
                field("Base Calendar Code"; Rec."Base Calendar Code")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies a customizable calendar for shipment planning that holds the customer''s working days and holidays.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(Dimensions)
            {
                ApplicationArea = Dimensions;
                Caption = 'Dimensions';
                Image = Dimensions;
                RunObject = Page "Default Dimensions";
                RunPageLink = "Table ID" = const(1381),
                              "No." = field(Code);
                ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
            }
            action(CopyTemplate)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Copy Template';
                Image = Copy;
                ToolTip = 'Copies all information to the current template from the selected one.';

                trigger OnAction()
                var
                    CustomerTempl: Record "Customer Templ.";
                    CustomerTemplList: Page "Select Customer Templ. List";
                begin
                    Rec.TestField(Code);
                    CustomerTempl.SetFilter(Code, '<>%1', Rec.Code);
                    CustomerTemplList.LookupMode(true);
                    CustomerTemplList.SetTableView(CustomerTempl);
                    if CustomerTemplList.RunModal() = Action::LookupOK then begin
                        CustomerTemplList.GetRecord(CustomerTempl);
                        Rec.CopyFromTemplate(CustomerTempl);
                    end;
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(CopyTemplate_Promoted; CopyTemplate)
                {
                }
                actionref(Dimensions_Promoted; Dimensions)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        IsCountyVisible := FormatAddress.UseCounty(Rec."Country/Region Code");
    end;

    var
        FormatAddress: Codeunit "Format Address";
        IsCountyVisible: Boolean;
}