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
                group("SII Information")
                {
                    Caption = 'SII Information';
                    field(OperationDescription; OperationDescription)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Operation Description';
                        Editable = false;
                        MultiLine = true;
                        ToolTip = 'Specifies the Operation Description.';

                        trigger OnValidate()
                        var
                            SIIManagement: Codeunit "SII Management";
                        begin
                            SIIManagement.SplitOperationDescription(OperationDescription, Rec."Operation Description", Rec."Operation Description 2");
                            Rec.Validate("Operation Description");
                            Rec.Validate("Operation Description 2");
                            Rec.Modify(true);
                        end;
                    }
                    group(Control1100013)
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
                    field("Special Scheme Code"; Rec."Special Scheme Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ToolTip = 'Specifies the Special Scheme Code.';
                    }
                    field("Invoice Type"; Rec."Invoice Type")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ToolTip = 'Specifies the Invoice Type.';
                    }
                    field("ID Type"; Rec."ID Type")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ToolTip = 'Specifies the ID Type.';
                    }
                    field("Succeeded Company Name"; Rec."Succeeded Company Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ToolTip = 'Specifies the name of the company sucessor in connection with corporate restructuring.';
                    }
                    field("Succeeded VAT Registration No."; Rec."Succeeded VAT Registration No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ToolTip = 'Specifies the VAT registration number of the company sucessor in connection with corporate restructuring.';
                    }
                    field("Issued By Third Party"; Rec."Issued By Third Party")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies that the credit memo was issued by a third party.';
                    }
                    field("SII First Summary Doc. No."; Rec.GetSIIFirstSummaryDocNo())
                    {
                        Caption = 'First Summary Doc. No.';
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ToolTip = 'Specifies the first number in the series of the summary entry. This field applies to F4-type invoices only.';
                    }
                    field("SII Last Summary Doc. No."; Rec.GetSIILastSummaryDocNo())
                    {
                        Caption = 'Last Summary Doc. No.';
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ToolTip = 'Specifies the last number in the series of the summary entry. This field applies to F4-type invoices only.';
                    }
                    field("Do Not Send To SII"; Rec."Do Not Send To SII")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies if the document must not be sent to SII.';
                    }
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
                    RunObject = Page "Service Invoice Statistics";
                    RunPageLink = "No." = field("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
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
                action(SpecialSchemeCodes)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Special Scheme Codes';
                    Image = Allocations;
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
        }
        area(processing)
        {
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
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(FindCorrectiveInvoices)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Find Corrective Invoices';
                    Image = FindCreditMemo;
                    RunObject = Page "Posted Service Credit Memos";
                    RunPageLink = "Corrected Invoice No." = field("No.");
                    ToolTip = 'View related corrective invoices. You can send a corrective invoice when there is an error or dispute that affects a VAT amount or fiscal data. This invoice includes all legally required data and refers to the original invoice or invoices.';
                }
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
                ApplicationArea = Service;
                Caption = 'Update Document';
                Image = Edit;
                ToolTip = 'Add new information that is relevant to the document. You can only edit a few fields because the document has already been posted.';

                trigger OnAction()
                var
                    PostedServInvoiceUpdate: Page "Posted Serv. Invoice - Update";
                begin
                    PostedServInvoiceUpdate.LookupMode := true;
                    PostedServInvoiceUpdate.SetRec(Rec);
                    PostedServInvoiceUpdate.RunModal();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

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
                Caption = 'Invoice';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref(Statistics_Promoted; Statistics)
                {
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
                actionref(SpecialSchemeCodes_Promoted; SpecialSchemeCodes)
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
    var
        SIIManagement: Codeunit "SII Management";
    begin
        DocExchStatusStyle := Rec.GetDocExchStatusStyle();
        DocExchStatusVisible := Rec."Document Exchange Status" <> Rec."Document Exchange Status"::"Not Sent";
        CurrPage.IncomingDocAttachFactBox.PAGE.LoadDataFromRecord(Rec);
        SIIManagement.CombineOperationDescription(Rec."Operation Description", Rec."Operation Description 2", OperationDescription);
        UpdateDocHasRegimeCode();
    end;

    trigger OnAfterGetRecord()
    begin
        DocExchStatusStyle := Rec.GetDocExchStatusStyle();
        SellToContact.GetOrClear(Rec."Contact No.");
        BillToContact.GetOrClear(Rec."Bill-to Contact No.");
        UpdateDocHasRegimeCode();
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        if Rec.Find(Which) then
            exit(true);
        Rec.SetRange("No.");
        exit(Rec.Find(Which));
    end;

    trigger OnOpenPage()
    var
        SIIManagement: Codeunit "SII Management";
    begin
        Rec.SetSecurityFilterOnRespCenter();

        SIIManagement.CombineOperationDescription(Rec."Operation Description", Rec."Operation Description 2", OperationDescription);
        UpdateDocHasRegimeCode();
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
        DocHasMultipleRegimeCode: Boolean;
        OperationDescription: Text[500];
        MultipleSchemeCodesLbl: Label 'Multiple scheme codes';
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

    local procedure UpdateDocHasRegimeCode()
    var
        SIISchemeCodeMgt: Codeunit "SII Scheme Code Mgt.";
    begin
        DocHasMultipleRegimeCode := SIISchemeCodeMgt.SalesDocHasRegimeCodes(Rec);
    end;
}

