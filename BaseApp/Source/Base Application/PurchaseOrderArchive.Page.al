page 5167 "Purchase Order Archive"
{
    Caption = 'Purchase Order Archive';
    DeleteAllowed = false;
    Editable = false;
    PageType = Document;
    SourceTable = "Purchase Header Archive";
    SourceTableView = WHERE("Document Type" = CONST(Order));

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
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Buy-from Vendor No."; "Buy-from Vendor No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the name of the vendor who delivered the items.';
                }
                field("Buy-from Contact No."; "Buy-from Contact No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the contact person at the vendor who delivered the items.';
                }
                group("Buy-from")
                {
                    Caption = 'Buy-from';
                    field("Buy-from Vendor Name"; "Buy-from Vendor Name")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Name';
                        ToolTip = 'Specifies the name of the vendor who delivered the items.';
                    }
                    field("Buy-from Address"; "Buy-from Address")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Address';
                        ToolTip = 'Specifies the address of the vendor who delivered the items.';
                    }
                    field("Buy-from Address 2"; "Buy-from Address 2")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Address 2';
                        ToolTip = 'Specifies an additional part of the address of the vendor who delivered the items.';
                    }
                    field("Buy-from City"; "Buy-from City")
                    {
                        ApplicationArea = Suite;
                        Caption = 'City';
                        ToolTip = 'Specifies the city of the vendor who delivered the items.';
                    }
                    group(Control23)
                    {
                        ShowCaption = false;
                        Visible = IsBuyFromCountyVisible;
                        field("Buy-from County"; "Buy-from County")
                        {
                            ApplicationArea = Suite;
                            Caption = 'County';
                            ToolTip = 'Specifies the county of your vendor.';
                        }
                    }
                    field("Buy-from Post Code"; "Buy-from Post Code")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Post Code';
                        ToolTip = 'Specifies the post code of the vendor who delivered the items.';
                    }
                    field("Buy-from Country/Region Code"; "Buy-from Country/Region Code")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Country/Region';
                        ToolTip = 'Specifies the country or region of your vendor.';
                    }
                    field("Buy-from Contact"; "Buy-from Contact")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Contact';
                        ToolTip = 'Specifies the name of the contact person at the vendor who delivered the items.';
                    }
                    field(BuyFromContactPhoneNo; BuyFromContact."Phone No.")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Phone No.';
                        Importance = Additional;
                        Editable = false;
                        ExtendedDatatype = PhoneNo;
                        ToolTip = 'Specifies the telephone number of the vendor contact person.';
                    }
                    field(BuyFromContactMobilePhoneNo; BuyFromContact."Mobile Phone No.")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Mobile Phone No.';
                        Importance = Additional;
                        Editable = false;
                        ExtendedDatatype = PhoneNo;
                        ToolTip = 'Specifies the mobile telephone number of the vendor contact person.';
                    }
                    field(BuyFromContactEmail; BuyFromContact."E-Mail")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Email';
                        Importance = Additional;
                        Editable = false;
                        ExtendedDatatype = EMail;
                        ToolTip = 'Specifies the email address of the vendor contact person.';
                    }
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Order Date"; "Order Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date the order was created. The order date is also used to determine the prices and discounts on the document.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field("Vendor Order No."; "Vendor Order No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the vendor''s order number.';
                }
                field("Vendor Shipment No."; "Vendor Shipment No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the vendor''s shipment number. It is inserted in the corresponding field on the source document during posting.';
                }
                field("Vendor Invoice No."; "Vendor Invoice No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the document number of the original document you received from the vendor. You can require the document number for posting, or let it be optional. By default, it''s required, so that this document references the original. Making document numbers optional removes a step from the posting process. For example, if you attach the original invoice as a PDF, you might not need to enter the document number. To specify whether document numbers are required, in the Purchases & Payables Setup window, select or clear the Ext. Doc. No. Mandatory field.';
                }
                field("Order Address Code"; "Order Address Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the order address of the related vendor.';
                }
                field("Purchaser Code"; "Purchaser Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies which purchaser is assigned to the vendor.';
                }
                field("Responsibility Center"; "Responsibility Center")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code of the responsibility center, such as a distribution hub, that is associated with the involved user, company, customer, or vendor.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies whether the record is open, waiting to be approved, invoiced for prepayment, or released to the next stage of processing.';
                }
            }
            part(PurchLinesArchive; "Purchase Order Archive Subform")
            {
                ApplicationArea = Suite;
                SubPageLink = "Document No." = FIELD("No."),
                              "Doc. No. Occurrence" = FIELD("Doc. No. Occurrence"),
                              "Version No." = FIELD("Version No.");
            }
            group(Invoicing)
            {
                Caption = 'Invoicing';
                field("Pay-to Vendor No."; "Pay-to Vendor No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the vendor that you received the invoice from.';
                }
                field("Pay-to Contact No."; "Pay-to Contact No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the person to contact about an invoice from this vendor.';
                }
                group("Pay-to")
                {
                    Caption = 'Pay-to';
                    field("Pay-to Name"; "Pay-to Name")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Name';
                        ToolTip = 'Specifies the name of the vendor who you received the invoice from.';
                    }
                    field("Pay-to Address"; "Pay-to Address")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Address';
                        ToolTip = 'Specifies the address of the vendor that you received the invoice from.';
                    }
                    field("Pay-to Address 2"; "Pay-to Address 2")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Address 2';
                        ToolTip = 'Specifies an additional part of the address of the vendor that the invoice was received from.';
                    }
                    field("Pay-to City"; "Pay-to City")
                    {
                        ApplicationArea = Suite;
                        Caption = 'City';
                        ToolTip = 'Specifies the city of the vendor that you received the invoice from.';
                    }
                    group(Control27)
                    {
                        ShowCaption = false;
                        Visible = IsPayToCountyVisible;
                        field("Pay-to County"; "Pay-to County")
                        {
                            ApplicationArea = Suite;
                            Caption = 'County';
                            ToolTip = 'Specifies the county of the vendor on the purchase document.';
                        }
                    }
                    field("Pay-to Post Code"; "Pay-to Post Code")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Post Code';
                        ToolTip = 'Specifies the post code of the vendor that you received the invoice from.';
                    }
                    field("Pay-to Country/Region Code"; "Pay-to Country/Region Code")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Country/Region';
                        ToolTip = 'Specifies the country or region of the vendor on the purchase document.';
                    }
                    field("Pay-to Contact"; "Pay-to Contact")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Contact';
                        ToolTip = 'Specifies the name of the person to contact about an invoice from this vendor.';
                    }
                    field(PayToContactPhoneNo; PayToContact."Phone No.")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Phone No.';
                        Editable = false;
                        Importance = Additional;
                        ExtendedDatatype = PhoneNo;
                        ToolTip = 'Specifies the telephone number of the person to contact about an order from this vendor.';
                    }
                    field(PayToContactMobilePhoneNo; PayToContact."Mobile Phone No.")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Mobile Phone No.';
                        Editable = false;
                        Importance = Additional;
                        ExtendedDatatype = PhoneNo;
                        ToolTip = 'Specifies the mobile telephone number of the person to contact about an order from this vendor.';
                    }
                    field(PayToContactEmail; PayToContact."E-Mail")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Email';
                        Editable = false;
                        Importance = Additional;
                        ExtendedDatatype = Email;
                        ToolTip = 'Specifies the email address of the person to contact about an order from this vendor.';
                    }
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
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a formula that calculates the payment due date, payment discount date, and payment discount amount.';
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies when the related purchase invoice must be paid.';
                }
                field("Payment Discount %"; "Payment Discount %")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the payment discount percent granted if payment is made on or before the date in the Pmt. Discount Date field.';
                }
                field("Payment Method Code"; "Payment Method Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how to make payment, such as with bank transfer, cash, or check.';
                }
                field("On Hold"; "On Hold")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies that the related entry represents an unpaid invoice for which either a payment suggestion, a reminder, or a finance charge memo exists.';
                }
                field("Prices Including VAT"; "Prices Including VAT")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies if the Unit Price and Line Amount fields on document lines should be shown with or without VAT.';
                }
                field("Tax Liable"; "Tax Liable")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies if this vendor charges you sales tax for purchases.';
                }
                field("Tax Area Code"; "Tax Area Code")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies the tax area that is used to calculate and post sales tax.';
                }
                field("Provincial Tax Area Code"; "Provincial Tax Area Code")
                {
                    ApplicationArea = BasicCA;
                    ToolTip = 'Specifies the Canadian provincial tax area code for the purchase header archive. This code is used to calculate sales tax charges defined by the Provincial Sales Tax (PST) rate.';
                }
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                group("Ship-to")
                {
                    Caption = 'Ship-to';
                    field("Ship-to Name"; "Ship-to Name")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Name';
                        ToolTip = 'Specifies the name of the customer at the address that the items are shipped to.';
                    }
                    field("Ship-to Address"; "Ship-to Address")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Address';
                        ToolTip = 'Specifies the address that the items are shipped to.';
                    }
                    field("Ship-to Address 2"; "Ship-to Address 2")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Address 2';
                        ToolTip = 'Specifies an additional part of the ship-to address, in case it is a long address.';
                    }
                    field("Ship-to City"; "Ship-to City")
                    {
                        ApplicationArea = Suite;
                        Caption = 'City';
                        ToolTip = 'Specifies the city of the address that the items are shipped to.';
                    }
                    group(Control31)
                    {
                        ShowCaption = false;
                        Visible = IsShipToCountyVisible;
                        field("Ship-to County"; "Ship-to County")
                        {
                            ApplicationArea = Suite;
                            Caption = 'County';
                            ToolTip = 'Specifies the county of the ship-to address.';
                        }
                    }
                    field("Ship-to Post Code"; "Ship-to Post Code")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Post Code';
                        ToolTip = 'Specifies the postal code of the address that the items are shipped to.';
                    }
                    field("Ship-to Country/Region Code"; "Ship-to Country/Region Code")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Country/Region';
                        ToolTip = 'Specifies the country or region of the ship-to address.';
                    }
                    field("Ship-to Contact"; "Ship-to Contact")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Contact';
                        ToolTip = 'Specifies the name of the contact person at the address that the items are shipped to.';
                    }
                }
                field("Ship-to UPS Zone"; "Ship-to UPS Zone")
                {
                    ToolTip = 'Specifies the UPS Zone code used by the vendor for this document.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies a code for the location where you want the items to be placed when they are received.';
                }
                field("Inbound Whse. Handling Time"; "Inbound Whse. Handling Time")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the time it takes to make items part of available inventory, after the items have been posted as received.';
                }
                field("Shipment Method Code"; "Shipment Method Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the delivery conditions of the related shipment, such as free on board (FOB).';
                }
                field("Lead Time Calculation"; "Lead Time Calculation")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a date formula for the amount of time it takes to replenish the item.';
                }
                field("Requested Receipt Date"; "Requested Receipt Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date you want the vendor to deliver your order. ';
                }
                field("Promised Receipt Date"; "Promised Receipt Date")
                {
                    ApplicationArea = OrderPromising;
                    ToolTip = 'Specifies the date that the vendor has promised to deliver the order.';
                }
                field("Expected Receipt Date"; "Expected Receipt Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date on which the invoiced items were expected.';
                }
                field("Sell-to Customer No."; "Sell-to Customer No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the customer.';
                }
                field("Ship-to Code"; "Ship-to Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';
                }
            }
            group("Foreign Trade")
            {
                Caption = 'Foreign Trade';
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the currency that is used on the entry.';
                }
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
                field("Entry Point"; "Entry Point")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the code of the port of entry where the items pass into your country/region, for reporting to Intrastat.';
                }
                field("Area"; Area)
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the area of the customer or vendor, for the purpose of reporting to INTRASTAT.';
                }
            }
            group(Version)
            {
                Caption = 'Version';
                field("Version No."; "Version No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the version number of the archived document.';
                }
                field("Archived By"; "Archived By")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the user ID of the person who archived this document.';

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation("Archived By");
                    end;
                }
                field("Date Archived"; "Date Archived")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date when the document was archived.';
                }
                field("Time Archived"; "Time Archived")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies what time the document was archived.';
                }
                field("Interaction Exist"; "Interaction Exist")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies that the archived document is linked to an interaction log entry.';
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
            group("Ver&sion")
            {
                Caption = 'Ver&sion';
                Image = Versions;
                action(Card)
                {
                    ApplicationArea = Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Vendor Card";
                    RunPageLink = "No." = FIELD("Buy-from Vendor No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';
                }
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDimensions();
                        CurrPage.SaveRecord;
                    end;
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Purch. Archive Comment Sheet";
                    RunPageLink = "Document Type" = FIELD("Document Type"),
                                  "No." = FIELD("No."),
                                  "Document Line No." = CONST(0),
                                  "Doc. No. Occurrence" = FIELD("Doc. No. Occurrence"),
                                  "Version No." = FIELD("Version No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action(Print)
                {
                    ApplicationArea = Suite;
                    Caption = 'Print';
                    Image = Print;
                    ToolTip = 'Print the information in the window. A print request window opens where you can specify what to include on the print-out.';

                    trigger OnAction()
                    begin
                        DocPrint.PrintPurchHeaderArch(Rec);
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        IsBuyFromCountyVisible := FormatAddress.UseCounty("Buy-from Country/Region Code");
        IsPayToCountyVisible := FormatAddress.UseCounty("Pay-to Country/Region Code");
        IsShipToCountyVisible := FormatAddress.UseCounty("Ship-to Country/Region Code");
    end;

    trigger OnAfterGetRecord()
    begin
        BuyFromContact.GetOrClear("Buy-from Contact No.");
        PayToContact.GetOrClear("Pay-to Contact No.");
    end;

    var
        BuyFromContact: Record Contact;
        PayToContact: Record Contact;
        DocPrint: Codeunit "Document-Print";
        FormatAddress: Codeunit "Format Address";
        IsBuyFromCountyVisible: Boolean;
        IsPayToCountyVisible: Boolean;
        IsShipToCountyVisible: Boolean;
}

