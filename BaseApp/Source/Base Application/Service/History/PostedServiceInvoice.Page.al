﻿namespace Microsoft.Service.History;

using Microsoft.CRM.Contact;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Foundation.Address;
using Microsoft.Service.Comment;
using Microsoft.Service.Document;

page 5978 "Posted Service Invoice"
{
    Caption = 'Posted Service Invoice';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = "Service Invoice Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the customer who owns the items on the invoice.';
                }
                field("Contact No."; Rec."Contact No.")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the number of the contact at the customer to whom you shipped the service.';
                }
                group("Sell-to")
                {
                    Caption = 'Sell-to';
                    field(Name; Rec.Name)
                    {
                        ApplicationArea = Service;
                        Editable = false;
                        ToolTip = 'Specifies the name of the customer on the service invoice.';
                    }
                    field(Address; Rec.Address)
                    {
                        ApplicationArea = Service;
                        Editable = false;
                        ToolTip = 'Specifies the address of the customer on the invoice.';
                    }
                    field("Address 2"; Rec."Address 2")
                    {
                        ApplicationArea = Service;
                        Editable = false;
                        ToolTip = 'Specifies additional address information.';
                    }
                    field(City; Rec.City)
                    {
                        ApplicationArea = Service;
                        Editable = false;
                        ToolTip = 'Specifies the city of the address.';
                    }
                    group(Control19)
                    {
                        ShowCaption = false;
                        Visible = IsSellToCountyVisible;
                        field(County; Rec.County)
                        {
                            ApplicationArea = Service;
                            Editable = false;
                            ToolTip = 'Specifies the county in the customer''s address.';
                        }
                    }
                    field("Post Code"; Rec."Post Code")
                    {
                        ApplicationArea = Service;
                        Editable = false;
                        ToolTip = 'Specifies the postal code.';
                    }
                    field("Country/Region Code"; Rec."Country/Region Code")
                    {
                        ApplicationArea = Service;
                        Editable = false;
                        ToolTip = 'Specifies the country/region of the address.';
                    }
                    field("Contact Name"; Rec."Contact Name")
                    {
                        ApplicationArea = Service;
                        Editable = false;
                        ToolTip = 'Specifies the name of the contact person at the customer company.';
                    }
                    field(SellToPhoneNo; SellToContact."Phone No.")
                    {
                        ApplicationArea = Service;
                        Caption = 'Phone No.';
                        Importance = Additional;
                        Editable = false;
                        ExtendedDatatype = PhoneNo;
                        ToolTip = 'Specifies the telephone number of the contact person at the customer company.';
                    }
                    field(SellToMobilePhoneNo; SellToContact."Mobile Phone No.")
                    {
                        ApplicationArea = Service;
                        Caption = 'Mobile Phone No.';
                        Importance = Additional;
                        Editable = false;
                        ExtendedDatatype = PhoneNo;
                        ToolTip = 'Specifies the mobile telephone number of the contact person at the customer company.';
                    }
                    field(SellToEmail; SellToContact."E-Mail")
                    {
                        ApplicationArea = Service;
                        Caption = 'Email';
                        Importance = Additional;
                        Editable = false;
                        ExtendedDatatype = EMail;
                        ToolTip = 'Specifies the email address of the contact person at the customer company.';
                    }
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the date when the invoice was posted.';
                }
                field("VAT Reporting Date"; Rec."VAT Reporting Date")
                {
                    ApplicationArea = VAT;
                    Editable = VATDateEnabled;
                    Visible = VATDateEnabled;
                    ToolTip = 'Specifies the VAT date on the invoice.';
                }
                group(Control11)
                {
                    ShowCaption = false;
                    Visible = DocExchStatusVisible;
                    field("Document Exchange Status"; Rec."Document Exchange Status")
                    {
                        ApplicationArea = Service;
                        Editable = false;
                        StyleExpr = DocExchStatusStyle;
                        ToolTip = 'Specifies the status of the document if you are using a document exchange service to send it as an electronic document. The status values are reported by the document exchange service.';

                        trigger OnDrillDown()
                        var
                            DocExchServDocStatus: Codeunit "Doc. Exch. Serv.- Doc. Status";
                        begin
                            DocExchServDocStatus.DocExchStatusDrillDown(Rec);
                        end;
                    }
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field("Order No."; Rec."Order No.")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the service order from which this invoice was posted.';
                }
                field("Pre-Assigned No."; Rec."Pre-Assigned No.")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the number of the service document from which the posted invoice was created.';
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the code of the salesperson associated with the invoice.';
                }
                field("Responsibility Center"; Rec."Responsibility Center")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the code of the responsibility center, such as a distribution hub, that is associated with the involved user, company, customer, or vendor.';
                }
                field("No. Printed"; Rec."No. Printed")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies how many times the document has been printed.';
                }
            }
            part(ServInvLines; "Posted Service Invoice Subform")
            {
                ApplicationArea = Service;
                SubPageLink = "Document No." = field("No.");
            }
            group(Invoicing)
            {
                Caption = 'Invoicing';
                field("Bill-to Customer No."; Rec."Bill-to Customer No.")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the customer that you send or sent the invoice or credit memo to.';
                }
                field("Bill-to Contact No."; Rec."Bill-to Contact No.")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the number of the contact person at the customer''s billing address.';
                }
                group("Bill-to")
                {
                    Caption = 'Bill-to';
                    field("Bill-to Name"; Rec."Bill-to Name")
                    {
                        ApplicationArea = Service;
                        Caption = 'Name';
                        Editable = false;
                        ToolTip = 'Specifies the name of the customer that you send or sent the invoice or credit memo to.';
                    }
                    field("Bill-to Address"; Rec."Bill-to Address")
                    {
                        ApplicationArea = Service;
                        Caption = 'Address';
                        Editable = false;
                        ToolTip = 'Specifies the address of the customer to whom you sent the invoice.';
                    }
                    field("Bill-to Address 2"; Rec."Bill-to Address 2")
                    {
                        ApplicationArea = Service;
                        Caption = 'Address 2';
                        Editable = false;
                        ToolTip = 'Specifies an additional line of the address.';
                    }
                    field("Bill-to City"; Rec."Bill-to City")
                    {
                        ApplicationArea = Service;
                        Caption = 'City';
                        Editable = false;
                        ToolTip = 'Specifies the city of the address.';
                    }
                    group(Control28)
                    {
                        ShowCaption = false;
                        Visible = IsBillToCountyVisible;
                        field("Bill-to County"; Rec."Bill-to County")
                        {
                            ApplicationArea = Service;
                            Caption = 'County';
                            Editable = false;
                            ToolTip = 'Specifies the county in the customer''s address.';
                        }
                    }
                    field("Bill-to Post Code"; Rec."Bill-to Post Code")
                    {
                        ApplicationArea = Service;
                        Caption = 'Post Code';
                        Editable = false;
                        ToolTip = 'Specifies the postal code of the customer''s billing address.';
                    }
                    field("Bill-to Country/Region Code"; Rec."Bill-to Country/Region Code")
                    {
                        ApplicationArea = Service;
                        Editable = false;
                        Caption = 'Country/Region';
                        ToolTip = 'Specifies the country/region in the customer''s address.';
                    }
                    field("Bill-to Contact"; Rec."Bill-to Contact")
                    {
                        ApplicationArea = Service;
                        Caption = 'Contact';
                        Editable = false;
                        ToolTip = 'Specifies the name of the contact person at the customer''s billing address.';
                    }
                    field(BillToContactPhoneNo; BillToContact."Phone No.")
                    {
                        ApplicationArea = Service;
                        Caption = 'Phone No.';
                        Editable = false;
                        Importance = Additional;
                        ExtendedDatatype = PhoneNo;
                        ToolTip = 'Specifies the telephone number of the contact person at the customer''s billing address.';
                    }
                    field(BillToContactMobilePhoneNo; BillToContact."Mobile Phone No.")
                    {
                        ApplicationArea = Service;
                        Caption = 'Mobile Phone No.';
                        Editable = false;
                        Importance = Additional;
                        ExtendedDatatype = PhoneNo;
                        ToolTip = 'Specifies the mobile telephone number of the contact person at the customer''s billing address.';
                    }
                    field(BillToContactEmail; BillToContact."E-Mail")
                    {
                        ApplicationArea = Service;
                        Caption = 'Email';
                        Editable = false;
                        Importance = Additional;
                        ExtendedDatatype = EMail;
                        ToolTip = 'Specifies the email address of the contact person at the customer''s billing address.';
                    }
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
                field("Customer Posting Group"; Rec."Customer Posting Group")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the customer''s market type to link business transactions to.';
                    Visible = false;
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies when the related invoice must be paid.';
                }
                field("Tax Liable"; Rec."Tax Liable")
                {
                    ApplicationArea = SalesTax;
                    Editable = false;
                    ToolTip = 'Specifies if the customer is liable for sales tax.';
                }
                field("Tax Area Code"; Rec."Tax Area Code")
                {
                    ApplicationArea = SalesTax;
                    Editable = false;
                    ToolTip = 'Specifies the code of the tax area where the customer is located.';
                }
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';
                }
                group("Ship-to")
                {
                    Caption = 'Ship-to';
                    field("Ship-to Name"; Rec."Ship-to Name")
                    {
                        ApplicationArea = Service;
                        Caption = 'Name';
                        Editable = false;
                        ToolTip = 'Specifies the name of the customer at the address that the items are shipped to.';
                    }
                    field("Ship-to Address"; Rec."Ship-to Address")
                    {
                        ApplicationArea = Service;
                        Caption = 'Address';
                        Editable = false;
                        ToolTip = 'Specifies the address that the items are shipped to.';
                    }
                    field("Ship-to Address 2"; Rec."Ship-to Address 2")
                    {
                        ApplicationArea = Service;
                        Caption = 'Address 2';
                        Editable = false;
                        ToolTip = 'Specifies an additional part of the ship-to address, in case it is a long address.';
                    }
                    field("Ship-to City"; Rec."Ship-to City")
                    {
                        ApplicationArea = Service;
                        Caption = 'City';
                        Editable = false;
                        ToolTip = 'Specifies the city of the address that the items are shipped to.';
                    }
                    group(Control31)
                    {
                        ShowCaption = false;
                        Visible = IsShipToCountyVisible;
                        field("Ship-to County"; Rec."Ship-to County")
                        {
                            ApplicationArea = Service;
                            Caption = 'County';
                            Editable = false;
                            ToolTip = 'Specifies the county in the customer''s address.';
                        }
                    }
                    field("Ship-to Post Code"; Rec."Ship-to Post Code")
                    {
                        ApplicationArea = Service;
                        Caption = 'Post Code';
                        Editable = false;
                        Importance = Promoted;
                        ToolTip = 'Specifies the postal code of the address that the items are shipped to.';
                    }
                    field("Ship-to Country/Region Code"; Rec."Ship-to Country/Region Code")
                    {
                        ApplicationArea = Service;
                        Editable = false;
                        Caption = 'Country/Region';
                        ToolTip = 'Specifies the country/region in the customer''s address.';
                    }
                    field("Ship-to Contact"; Rec."Ship-to Contact")
                    {
                        ApplicationArea = Service;
                        Caption = 'Contact';
                        Editable = false;
                        ToolTip = 'Specifies the name of the contact person at the address that the items are shipped to.';
                    }
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies the location, such as warehouse or distribution center, from which the service was shipped.';
                }
                group("Shipping Details")
                {
                    Caption = 'Shipping Details';
                    field("Shipment Method Code"; Rec."Shipment Method Code")
                    {
                        ApplicationArea = Service;
                        Caption = 'Method';
                        Editable = false;
                        Importance = Additional;
                        ToolTip = 'Specifies the code that represents the shipment method for the invoice.';
                    }
                    field("Shipping Agent Code"; Rec."Shipping Agent Code")
                    {
                        ApplicationArea = Service;
                        Caption = 'Agent';
                        Editable = false;
                        Importance = Additional;
                        ToolTip = 'Specifies which shipping agent is used to transport the items on the service document to the customer.';
                    }
                    field("Shipping Agent Service Code"; Rec."Shipping Agent Service Code")
                    {
                        ApplicationArea = Service;
                        Caption = 'Agent Service';
                        Editable = false;
                        Importance = Additional;
                        ToolTip = 'Specifies which shipping agent service is used to transport the items on the service document to the customer.';
                    }
                }
            }
            group("Foreign Trade")
            {
                Caption = 'Foreign Trade';
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies the currency code for the amounts on the invoice.';

                    trigger OnAssistEdit()
                    begin
                        ChangeExchangeRate.SetParameter(Rec."Currency Code", Rec."Currency Factor", Rec."Posting Date");
                        ChangeExchangeRate.Editable(false);
                        if ChangeExchangeRate.RunModal() = ACTION::OK then begin
                            Rec."Currency Factor" := ChangeExchangeRate.GetParameter();
                            Rec.Modify();
                        end;
                        Clear(ChangeExchangeRate);
                    end;
                }
                field("Company Bank Account Code"; Rec."Company Bank Account Code")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the bank account to use for bank information when the document is printed.';
                }
                field("EU 3-Party Trade"; Rec."EU 3-Party Trade")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies if the transaction is related to trade with a third party within the EU.';
                }
            }
            group("Electronic Invoice")
            {
                Caption = 'Electronic Invoice';
                field("CFDI Purpose"; Rec."CFDI Purpose")
                {
                    ApplicationArea = BasicMX;
                    Importance = Additional;
                    ToolTip = 'Specifies the CFDI purpose required for reporting to the Mexican tax authorities (SAT).';
                }
                field("CFDI Relation"; Rec."CFDI Relation")
                {
                    ApplicationArea = BasicMX;
                    Importance = Additional;
                    ToolTip = 'Specifies the relation of the CFDI document. ';
                }
                field("CFDI Period"; Rec."CFDI Period")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the period to use when reporting for general public customers';
                }
                field("SAT Address ID"; Rec."SAT Address ID")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the SAT address that the goods or merchandise are moved to.';
                    BlankZero = true;
                }
                field("CFDI Export Code"; Rec."CFDI Export Code")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies a code to indicate if the document is used for exports to other countries.';
                }
                field(Control1310005; Rec."Foreign Trade")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies whether the goods or merchandise that are transported enter or leave the national territory.';
                }
                field("SAT International Trade Term"; Rec."SAT International Trade Term")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies an international commercial terms code that are used in international sale contracts according to the SAT internatoinal trade terms definition.';
                }
                field("Exchange Rate USD"; Rec."Exchange Rate USD")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the USD to MXN exchange rate that is used to report foreign trade documents to Mexican SAT authorities. This rate must match the rate used by the Mexican National Bank.';
                }
                field("Electronic Document Status"; Rec."Electronic Document Status")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the status of the document.';
                }
                field("Date/Time Stamped"; Rec."Date/Time Stamped")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the date and time that the document received a digital stamp from the authorized service provider.';
                }
                field("Date/Time Sent"; Rec."Date/Time Sent")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the date and time that the document was sent to the customer.';
                }
                field("Date/Time Canceled"; Rec."Date/Time Canceled")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the date and time that the document was canceled.';
                }
                field("Error Code"; Rec."Error Code")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the error code that the authorized service provider, PAC, has returned to Business Central.';
                }
                field("Error Description"; Rec."Error Description")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the error message that the authorized service provider, PAC, has returned to Business Central.';
                }
                field("PAC Web Service Name"; Rec."PAC Web Service Name")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the name of the authorized service provider, PAC, which has processed the electronic document.';
                }
                field("Fiscal Invoice Number PAC"; Rec."Fiscal Invoice Number PAC")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the official invoice number for the electronic document.';
                }
                field("No. of E-Documents Sent"; Rec."No. of E-Documents Sent")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the number of times that this document has been sent electronically.';
                }
                field("CFDI Cancellation Reason Code"; Rec."CFDI Cancellation Reason Code")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the reason for the cancellation as a code.';
                }
                field("Substitution Document No."; Rec."Substitution Document No.")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the document number that replaces the canceled one. It is required when the cancellation reason is 01.';
                }
            }
        }
        area(factboxes)
        {
            part(IncomingDocAttachFactBox; "Incoming Doc. Attach. FactBox")
            {
                ApplicationArea = Service;
                ShowFilter = false;
                Visible = false;
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
            group("&Invoice")
            {
                Caption = '&Invoice';
                Image = Invoice;
                action(Statistics)
                {
                    ApplicationArea = Service;
                    Caption = 'Statistics';
                    Image = Statistics;
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';

                    trigger OnAction()
                    begin
                        OnBeforeCalculateSalesTaxStatistics(Rec);
                        if Rec."Tax Area Code" = '' then
                            PAGE.RunModal(PAGE::"Service Invoice Statistics", Rec, Rec."No.")
                        else
                            PAGE.RunModal(PAGE::"Service Invoice Stats.", Rec, Rec."No.");
                    end;
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Service Comment Sheet";
                    RunPageLink = Type = const(General),
                                  "Table Name" = const("Service Invoice Header"),
                                  "No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
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
                        Rec.ShowDimensions();
                        CurrPage.SaveRecord();
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
                        TempServDocLog: Record "Service Document Log" temporary;
                    begin
                        TempServDocLog.Reset();
                        TempServDocLog.DeleteAll();
                        TempServDocLog.CopyServLog(TempServDocLog."Document Type"::"Posted Invoice".AsInteger(), Rec."No.");
                        TempServDocLog.CopyServLog(TempServDocLog."Document Type"::Order.AsInteger(), Rec."Order No.");
                        TempServDocLog.CopyServLog(TempServDocLog."Document Type"::Invoice.AsInteger(), Rec."Pre-Assigned No.");

                        TempServDocLog.Reset();
                        TempServDocLog.SetCurrentKey("Change Date", "Change Time");
                        TempServDocLog.Ascending(false);

                        PAGE.Run(0, TempServDocLog);
                    end;
                }
            }
        }
        area(processing)
        {
            group("&Electronic Document")
            {
                Caption = '&Electronic Document';
                action("S&end")
                {
                    ApplicationArea = BasicMX;
                    Caption = 'S&end';
                    Ellipsis = true;
                    Image = SendTo;
                    ToolTip = 'Send an email to the customer with the electronic service invoice attached as an XML file.';

                    trigger OnAction()
                    begin
                        Rec.RequestStampEDocument();
                    end;
                }
                action("Export E-Document as &XML")
                {
                    ApplicationArea = BasicMX;
                    Caption = 'Export E-Document as &XML';
                    Image = ExportElectronicDocument;
                    ToolTip = 'Export the posted service invoice as an electronic service invoice, an XML file, and save it to a specified location.';

                    trigger OnAction()
                    begin
                        Rec.ExportEDocument();
                    end;
                }
                action(ExportEDocumentPDF)
                {
                    ApplicationArea = BasicMX;
                    Caption = 'Export E-Document as PDF';
                    Image = ExportToBank;
                    ToolTip = 'Export the posted service invoice as an electronic service invoice, a PDF document, when the stamp is received.';

                    trigger OnAction()
                    begin
                        Rec.ExportEDocumentPDF();
                    end;
                }
                action(CFDIRelationDocuments)
                {
                    ApplicationArea = BasicMX;
                    Caption = 'CFDI Relation Documents';
                    Image = Allocations;
                    RunObject = Page "CFDI Relation Documents";
                    RunPageLink = "Document Table ID" = const(5992),
                                  "Document No." = field("No."),
                                  "Customer No." = field("Bill-to Customer No.");
                    RunPageMode = View;
                    ToolTip = 'View or add CFDI relation documents for the record.';
                }
                action("&Cancel")
                {
                    ApplicationArea = BasicMX;
                    Caption = '&Cancel';
                    Image = Cancel;
                    ToolTip = 'Cancel the sending of the electronic service invoice.';

                    trigger OnAction()
                    begin
                        Rec.CancelEDocument();
                    end;
                }
            }
            action(SendCustom)
            {
                ApplicationArea = Service;
                Caption = 'Send';
                Ellipsis = true;
                Image = SendToMultiple;
                ToolTip = 'Prepare to send the document according to the customer''s sending profile, such as attached to an email. The Send document to window opens first so you can confirm or select a sending profile.';

                trigger OnAction()
                begin
                    ServiceInvHeader := Rec;
                    CurrPage.SetSelectionFilter(ServiceInvHeader);
                    ServiceInvHeader.SendRecords();
                end;
            }
            action("&Print")
            {
                ApplicationArea = Service;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                begin
                    CurrPage.SetSelectionFilter(ServiceInvHeader);
                    ServiceInvHeader.PrintRecords(true);
                end;
            }
            action("&Navigate")
            {
                ApplicationArea = Service;
                Caption = 'Find entries...';
                Image = Navigate;
                ShortCutKey = 'Ctrl+Alt+Q';
                ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';

                trigger OnAction()
                begin
                    Rec.Navigate();
                end;
            }
            action(ActivityLog)
            {
                ApplicationArea = Service;
                Caption = 'Activity Log';
                Image = Log;
                ToolTip = 'View the status and any errors if the document was sent as an electronic document or OCR file through the document exchange service.';

                trigger OnAction()
                begin
                    Rec.ShowActivityLog();
                end;
            }
            action("Update Document")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Update Document';
                Image = Edit;
                ToolTip = 'Add new information that is relevant to the document, such as a payment reference. You can only edit a few fields because the document has already been posted.';

                trigger OnAction()
                var
                    PostedServiceInvUpdate: Page "Posted Service Inv. - Update";
                begin
                    PostedServiceInvUpdate.LookupMode := true;
                    PostedServiceInvUpdate.SetRec(Rec);
                    PostedServiceInvUpdate.RunModal();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("Update Document_Promoted"; "Update Document")
                {
                }
                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Print/Send', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref("&Print_Promoted"; "&Print")
                {
                }
                actionref(SendCustom_Promoted; SendCustom)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Invoice', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref(Statistics_Promoted; Statistics)
                {
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
                actionref("Service Document Lo&g_Promoted"; "Service Document Lo&g")
                {
                }
                actionref(ActivityLog_Promoted; ActivityLog)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        DocExchStatusStyle := Rec.GetDocExchStatusStyle();
        DocExchStatusVisible := Rec."Document Exchange Status" <> Rec."Document Exchange Status"::"Not Sent";
        CurrPage.IncomingDocAttachFactBox.PAGE.LoadDataFromRecord(Rec);
    end;

    trigger OnAfterGetRecord()
    begin
        DocExchStatusStyle := Rec.GetDocExchStatusStyle();
        SellToContact.GetOrClear(Rec."Contact No.");
        BillToContact.GetOrClear(Rec."Bill-to Contact No.");
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        if Rec.Find(Which) then
            exit(true);
        Rec.SetRange("No.");
        exit(Rec.Find(Which));
    end;

    trigger OnOpenPage()
    begin
        Rec.SetSecurityFilterOnRespCenter();

        ActivateFields();
    end;

    var
        ServiceInvHeader: Record "Service Invoice Header";
        SellToContact: Record Contact;
        BillToContact: Record Contact;
        FormatAddress: Codeunit "Format Address";
        ChangeExchangeRate: Page "Change Exchange Rate";
        DocExchStatusStyle: Text;
        DocExchStatusVisible: Boolean;
        IsSellToCountyVisible: Boolean;
        IsShipToCountyVisible: Boolean;
        IsBillToCountyVisible: Boolean;
        VATDateEnabled: Boolean;

    local procedure ActivateFields()
    var
        VATReportingDateMgt: Codeunit "VAT Reporting Date Mgt";
    begin
        IsSellToCountyVisible := FormatAddress.UseCounty(Rec."Country/Region Code");
        IsShipToCountyVisible := FormatAddress.UseCounty(Rec."Ship-to Country/Region Code");
        IsBillToCountyVisible := FormatAddress.UseCounty(Rec."Bill-to Country/Region Code");
        VATDateEnabled := VATReportingDateMgt.IsVATDateEnabled();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateSalesTaxStatistics(var ServiceInvoiceHeader: Record "Service Invoice Header")
    begin
    end;
}

