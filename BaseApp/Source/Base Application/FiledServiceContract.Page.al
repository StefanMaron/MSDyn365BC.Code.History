page 6072 "Filed Service Contract"
{
    Caption = 'Filed Service Contract';
    DataCaptionExpression = Format("Contract Type") + ' ' + "Contract No.";
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Document;
    SourceTable = "Filed Service Contract Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Contract No."; "Contract No.")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the number of the filed service contract or service contract quote.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a description of the filed service contract or contract quote.';
                }
                field("Customer No."; "Customer No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the customer who owns the items in the filed service contract or contract quote.';
                }
                field("Contact No."; "Contact No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the contact who will receive the service contract delivery.';
                }
                group("Sell-to")
                {
                    Caption = 'Sell-to';
                    field(Name; Name)
                    {
                        ApplicationArea = Service;
                        ToolTip = 'Specifies the name of the customer in the filed service contract or contract quote.';
                    }
                    field(Address; Address)
                    {
                        ApplicationArea = Service;
                        ToolTip = 'Specifies the address of the customer in the filed service contract or contract quote.';
                    }
                    field("Address 2"; "Address 2")
                    {
                        ApplicationArea = Service;
                        ToolTip = 'Specifies additional address information.';
                    }
                    field("Post Code"; "Post Code")
                    {
                        ApplicationArea = Service;
                        ToolTip = 'Specifies the postal code.';
                    }
                    field(City; City)
                    {
                        ApplicationArea = Service;
                        ToolTip = 'Specifies the city of the address.';
                    }
                    group(Control9)
                    {
                        ShowCaption = false;
                        Visible = IsSellToCountyVisible;
                        field(County; County)
                        {
                            ApplicationArea = Service;
                        }
                    }
                    field("Country/Region Code"; "Country/Region Code")
                    {
                        ApplicationArea = Service;
                        ToolTip = 'Specifies the country/region of the address.';
                    }
                    field("Contact Name"; "Contact Name")
                    {
                        ApplicationArea = Service;
                        ToolTip = 'Specifies the name of the person you regularly contact when you do business with the customer in the filed service contract or contract quote.';
                    }
                }
                field("Phone No."; "Phone No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the customer phone number.';
                }
                field("E-Mail"; "E-Mail")
                {
                    ApplicationArea = Service;
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the customer''s email address.';
                }
                field("Contract Group Code"; "Contract Group Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the contract group code of the filed service contract or contract quote.';
                }
                field("Salesperson Code"; "Salesperson Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the salesperson assigned to the filed service contract or contract quote.';
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the starting date of the filed service contract or contract quote.';
                }
                field("Expiration Date"; "Expiration Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the filed service contract expires.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the status of the filed service contract or contract quote.';
                }
                field("Responsibility Center"; "Responsibility Center")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the responsibility center, such as a distribution hub, that is associated with the involved user, company, customer, or vendor.';
                }
                field("Change Status"; "Change Status")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies if the service contract or the service contract quote was open or locked for changes at the moment of filing.';
                }
            }
            part(Control93; "Filed Service Contract Subform")
            {
                ApplicationArea = Service;
                Editable = false;
                SubPageLink = "Entry No." = FIELD("Entry No.");
                SubPageView = SORTING("Entry No.", "Line No.");
            }
            group(Invoicing)
            {
                Caption = 'Invoicing';
                field("Bill-to Customer No."; "Bill-to Customer No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the customer that you send or sent the invoice or credit memo to.';
                }
                field("Bill-to Contact No."; "Bill-to Contact No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the contact person at the customer''s billing address.';
                }
                group("Bill-to")
                {
                    Caption = 'Bill-to';
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
                        ToolTip = 'Specifies the address of the customer to whom you will send the invoice.';
                    }
                    field("Bill-to Address 2"; "Bill-to Address 2")
                    {
                        ApplicationArea = Service;
                        Caption = 'Address 2';
                        ToolTip = 'Specifies an additional line of the address.';
                    }
                    field("Bill-to City"; "Bill-to City")
                    {
                        ApplicationArea = Service;
                        Caption = 'City';
                        ToolTip = 'Specifies the city of the address.';
                    }
                    group(Control20)
                    {
                        ShowCaption = false;
                        Visible = IsBillToCountyVisible;
                        field("Bill-to County"; "Bill-to County")
                        {
                            ApplicationArea = Service;
                            Caption = 'County';
                        }
                    }
                    field("Bill-to Post Code"; "Bill-to Post Code")
                    {
                        ApplicationArea = Service;
                        Caption = 'Post Code';
                        ToolTip = 'Specifies the postal code of the customer''s billing address.';
                    }
                    field("Bill-to Country/Region Code"; "Bill-to Country/Region Code")
                    {
                        ApplicationArea = Service;
                        Caption = 'Country/Region';
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
                    ToolTip = 'Specifies the customer''s reference number.';
                }
                field("Serv. Contract Acc. Gr. Code"; "Serv. Contract Acc. Gr. Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the service contract account group that the filed service contract is associated with.';
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
                    ToolTip = 'Specifies a formula that calculates the payment due date, payment discount date, and payment discount amount.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the currency code of the amounts in the filed service contract or contract quote.';
                }
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field("Ship-to Code"; "Ship-to Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';
                }
                group("Ship-to")
                {
                    Caption = 'Ship-to';
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
                        ToolTip = 'Specifies the address that the items are shipped to.';
                    }
                    field("Ship-to Address 2"; "Ship-to Address 2")
                    {
                        ApplicationArea = Service;
                        Caption = 'Address 2';
                        ToolTip = 'Specifies an additional part of the ship-to address, in case it is a long address.';
                    }
                    field("Ship-to City"; "Ship-to City")
                    {
                        ApplicationArea = Service;
                        Caption = 'City';
                        ToolTip = 'Specifies the city of the address that the items are shipped to.';
                    }
                    group(Control29)
                    {
                        ShowCaption = false;
                        Visible = IsShipToCountyVisible;
                        field("Ship-to County"; "Ship-to County")
                        {
                            ApplicationArea = Service;
                            Caption = 'County';
                        }
                    }
                    field("Ship-to Post Code"; "Ship-to Post Code")
                    {
                        ApplicationArea = Service;
                        Caption = 'Post Code';
                        ToolTip = 'Specifies the postal code of the address that the items are shipped to.';
                    }
                    field("Ship-to Country/Region Code"; "Ship-to Country/Region Code")
                    {
                        ApplicationArea = Service;
                        Caption = 'Country/Region';
                    }
                }
            }
            group(Service)
            {
                Caption = 'Service';
                field("Service Zone Code"; "Service Zone Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the service zone of the customer''s ship-to address.';
                }
                field("Service Period"; "Service Period")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the default service period for the service items in the filed service contract or contract quote.';
                }
                field("First Service Date"; "First Service Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date of the first expected service for the service items in the filed service contract or contract quote.';
                }
                field("Response Time (Hours)"; "Response Time (Hours)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the default response time for the service items in the filed service contract or contract quote.';
                }
                field("Service Order Type"; "Service Order Type")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the service order type assigned to service orders linked to this filed service contract or contract quote.';
                }
            }
            group("Invoice Details")
            {
                Caption = 'Invoice Details';
                field("Annual Amount"; "Annual Amount")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the amount that was invoiced annually before the service contract or contract quote was filed.';
                }
                field("Allow Unbalanced Amounts"; "Allow Unbalanced Amounts")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies whether the Annual Amount field on the contract or quote is modified automatically or manually.';
                }
                field("Calcd. Annual Amount"; "Calcd. Annual Amount")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the sum of the Line Amount field values on all contract lines associated with the filed service contract or contract quote.';
                }
                field("Invoice Period"; "Invoice Period")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the invoice period for the filed service contract or contract quote.';
                }
                field("Next Invoice Date"; "Next Invoice Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the next invoice date for this filed service contract or contract quote.';
                }
                field("Amount per Period"; "Amount per Period")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the amount that will be invoiced for each invoice period for the filed service contract or contract quote.';
                }
                field(NextInvoicePeriod; NextInvoicePeriod)
                {
                    ApplicationArea = Service;
                    Caption = 'Next Invoice Period';
                    ToolTip = 'Specifies the next invoice period for the filed service contract agreements between your customers and your company.';
                }
                field("Last Invoice Date"; "Last Invoice Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the invoice date when this filed service contract was last invoiced.';
                }
                field(Prepaid; Prepaid)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that this filed service contract or contract quote is prepaid.';
                }
                field("Automatic Credit Memos"; "Automatic Credit Memos")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that you want a credit memo created when you remove a contract line from the filed service contract.';
                }
                field("Invoice after Service"; "Invoice after Service")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies you can only invoice the contract if you have posted a service order since last time you invoiced the contract.';
                }
                field("Combine Invoices"; "Combine Invoices")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies you want to combine invoices for this filed service contract with invoices for other service contracts with the same bill-to customer.';
                }
                field("Contract Lines on Invoice"; "Contract Lines on Invoice")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that you want the contract lines for this service contract to appear as text on the invoice created when you invoice the contract.';
                }
            }
            group("Price Update")
            {
                Caption = 'Price Update';
                field("Price Update Period"; "Price Update Period")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the price update period for this filed service contract or contract quote.';
                }
                field("Next Price Update Date"; "Next Price Update Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the next date when you want contract prices to be updated.';
                }
                field("Last Price Update %"; "Last Price Update %")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the price update percentage you used when you last updated the contract prices.';
                }
                field("Last Price Update Date"; "Last Price Update Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when you last updated the service contract prices.';
                }
                field("Print Increase Text"; "Print Increase Text")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that the price increase text is printed on invoices for this contract, informing the customer which prices have been updated.';
                }
                field("Price Inv. Increase Code"; "Price Inv. Increase Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the standard text code to print on service invoices for this filed service contract, informing the customer which prices have been updated.';
                }
            }
            group(Detail)
            {
                Caption = 'Detail';
                field("Cancel Reason Code"; "Cancel Reason Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the cancel reason code specified in a service contract or a contract quote at the moment of filing.';
                }
                field("Max. Labor Unit Price"; "Max. Labor Unit Price")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the maximum unit price that can be set for a resource on all service order lines for to the filed service contract or contract quote.';
                }
            }
            group("Filed Detail")
            {
                Caption = 'Filed Detail';
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }
                field("File Date"; "File Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when service contract or contract quote is filed.';
                }
                field("File Time"; "File Time")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the time when the service contract or contract quote is filed.';
                }
                field("Reason for Filing"; "Reason for Filing")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the reason for filing the service contract or contract quote.';
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
    }

    trigger OnOpenPage()
    begin
        ActivateFields;
    end;

    var
        FormatAddress: Codeunit "Format Address";
        IsShipToCountyVisible: Boolean;
        IsSellToCountyVisible: Boolean;
        IsBillToCountyVisible: Boolean;

    local procedure ActivateFields()
    begin
        IsBillToCountyVisible := FormatAddress.UseCounty("Bill-to Country/Region Code");
        IsShipToCountyVisible := FormatAddress.UseCounty("Ship-to Country/Region Code");
        IsSellToCountyVisible := FormatAddress.UseCounty("Country/Region Code");
    end;
}

