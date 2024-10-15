page 5978 "Posted Service Invoice"
{
    Caption = 'Posted Service Invoice';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Document;
    PromotedActionCategories = 'New,Process,Report,Invoice,Print/Send';
    RefreshOnActivate = true;
    SourceTable = "Service Invoice Header";

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
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Customer No."; "Customer No.")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the customer who owns the items on the invoice.';
                }
                field("Contact No."; "Contact No.")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the number of the contact at the customer to whom you shipped the service.';
                }
                group("Sell-to")
                {
                    Caption = 'Sell-to';
                    field(Name; Name)
                    {
                        ApplicationArea = Service;
                        Editable = false;
                        ToolTip = 'Specifies the name of the customer on the service invoice.';
                    }
                    field(Address; Address)
                    {
                        ApplicationArea = Service;
                        Editable = false;
                        ToolTip = 'Specifies the address of the customer on the invoice.';
                    }
                    field("Address 2"; "Address 2")
                    {
                        ApplicationArea = Service;
                        Editable = false;
                        ToolTip = 'Specifies additional address information.';
                    }
                    field(City; City)
                    {
                        ApplicationArea = Service;
                        Editable = false;
                        ToolTip = 'Specifies the city of the address.';
                    }
                    group(Control19)
                    {
                        ShowCaption = false;
                        Visible = IsSellToCountyVisible;
                        field(County; County)
                        {
                            ApplicationArea = Service;
                            Editable = false;
                            ToolTip = 'Specifies the county in the customer''s address.';
                        }
                    }
                    field("Post Code"; "Post Code")
                    {
                        ApplicationArea = Service;
                        Editable = false;
                        ToolTip = 'Specifies the postal code.';
                    }
                    field("Country/Region Code"; "Country/Region Code")
                    {
                        ApplicationArea = Service;
                        ToolTip = 'Specifies the country/region of the address.';
                    }
                    field("Contact Name"; "Contact Name")
                    {
                        ApplicationArea = Service;
                        Editable = false;
                        ToolTip = 'Specifies the name of the contact person at the customer company.';
                    }
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the date when the invoice was posted.';
                }
                group(Control11)
                {
                    ShowCaption = false;
                    Visible = DocExchStatusVisible;
                    field("Document Exchange Status"; "Document Exchange Status")
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
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field("Order No."; "Order No.")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the service order from which this invoice was posted.';
                }
                field("Pre-Assigned No."; "Pre-Assigned No.")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the number of the service document from which the posted invoice was created.';
                }
                field("Salesperson Code"; "Salesperson Code")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the code of the salesperson associated with the invoice.';
                }
                field("Responsibility Center"; "Responsibility Center")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the code of the responsibility center, such as a distribution hub, that is associated with the involved user, company, customer, or vendor.';
                }
                field("No. Printed"; "No. Printed")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies how many times the document has been printed.';
                }
            }
            part(ServInvLines; "Posted Service Invoice Subform")
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
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the customer that you send or sent the invoice or credit memo to.';
                }
                field("Bill-to Contact No."; "Bill-to Contact No.")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the number of the contact person at the customer''s billing address.';
                }
                group("Bill-to")
                {
                    Caption = 'Bill-to';
                    field("Bill-to Name"; "Bill-to Name")
                    {
                        ApplicationArea = Service;
                        Caption = 'Name';
                        Editable = false;
                        ToolTip = 'Specifies the name of the customer that you send or sent the invoice or credit memo to.';
                    }
                    field("Bill-to Address"; "Bill-to Address")
                    {
                        ApplicationArea = Service;
                        Caption = 'Address';
                        Editable = false;
                        ToolTip = 'Specifies the address of the customer to whom you sent the invoice.';
                    }
                    field("Bill-to Address 2"; "Bill-to Address 2")
                    {
                        ApplicationArea = Service;
                        Caption = 'Address 2';
                        Editable = false;
                        ToolTip = 'Specifies an additional line of the address.';
                    }
                    field("Bill-to City"; "Bill-to City")
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
                        field("Bill-to County"; "Bill-to County")
                        {
                            ApplicationArea = Service;
                            Caption = 'County';
                            Editable = false;
                            ToolTip = 'Specifies the county in the customer''s address.';
                        }
                    }
                    field("Bill-to Post Code"; "Bill-to Post Code")
                    {
                        ApplicationArea = Service;
                        Caption = 'Post Code';
                        Editable = false;
                        ToolTip = 'Specifies the postal code of the customer''s billing address.';
                    }
                    field("Bill-to Country/Region Code"; "Bill-to Country/Region Code")
                    {
                        ApplicationArea = Service;
                        Caption = 'Country/Region';
                        ToolTip = 'Specifies the country/region in the customer''s address.';
                    }
                    field("Bill-to Contact"; "Bill-to Contact")
                    {
                        ApplicationArea = Service;
                        Caption = 'Contact';
                        Editable = false;
                        ToolTip = 'Specifies the name of the contact person at the customer''s billing address.';
                    }
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies when the related invoice must be paid.';
                }
                field("Tax Liable"; "Tax Liable")
                {
                    ApplicationArea = SalesTax;
                    Editable = false;
                    ToolTip = 'Specifies if the customer is liable for sales tax.';
                }
                field("Tax Area Code"; "Tax Area Code")
                {
                    ApplicationArea = SalesTax;
                    Editable = false;
                    ToolTip = 'Specifies the code of the tax area where the customer is located.';
                }
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field("Ship-to Code"; "Ship-to Code")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';
                }
                group("Ship-to")
                {
                    Caption = 'Ship-to';
                    field("Ship-to Name"; "Ship-to Name")
                    {
                        ApplicationArea = Service;
                        Caption = 'Name';
                        Editable = false;
                        ToolTip = 'Specifies the name of the customer at the address that the items are shipped to.';
                    }
                    field("Ship-to Address"; "Ship-to Address")
                    {
                        ApplicationArea = Service;
                        Caption = 'Address';
                        Editable = false;
                        ToolTip = 'Specifies the address that the items are shipped to.';
                    }
                    field("Ship-to Address 2"; "Ship-to Address 2")
                    {
                        ApplicationArea = Service;
                        Caption = 'Address 2';
                        Editable = false;
                        ToolTip = 'Specifies an additional part of the ship-to address, in case it is a long address.';
                    }
                    field("Ship-to City"; "Ship-to City")
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
                        field("Ship-to County"; "Ship-to County")
                        {
                            ApplicationArea = Service;
                            Caption = 'County';
                            Editable = false;
                            ToolTip = 'Specifies the county in the customer''s address.';
                        }
                    }
                    field("Ship-to Post Code"; "Ship-to Post Code")
                    {
                        ApplicationArea = Service;
                        Caption = 'Post Code';
                        Editable = false;
                        Importance = Promoted;
                        ToolTip = 'Specifies the postal code of the address that the items are shipped to.';
                    }
                    field("Ship-to Country/Region Code"; "Ship-to Country/Region Code")
                    {
                        ApplicationArea = Service;
                        Caption = 'Country/Region';
                        ToolTip = 'Specifies the country/region in the customer''s address.';
                    }
                    field("Ship-to Contact"; "Ship-to Contact")
                    {
                        ApplicationArea = Service;
                        Caption = 'Contact';
                        Editable = false;
                        ToolTip = 'Specifies the name of the contact person at the address that the items are shipped to.';
                    }
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies the location, such as warehouse or distribution center, from which the service was shipped.';
                }
            }
            group("Foreign Trade")
            {
                Caption = 'Foreign Trade';
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies the currency code for the amounts on the invoice.';

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
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies if the transaction is related to trade with a third party within the EU.';
                }
            }
            group("Electronic Invoice")
            {
                Caption = 'Electronic Invoice';
                field("Electronic Document Status"; "Electronic Document Status")
                {
                    ToolTip = 'Specifies the status of the document.';
                }
                field("Date/Time Stamped"; "Date/Time Stamped")
                {
                    ToolTip = 'Specifies the date and time that the document received a digital stamp from the authorized service provider.';
                }
                field("Date/Time Sent"; "Date/Time Sent")
                {
                    ToolTip = 'Specifies the date and time that the document was sent to the customer.';
                }
                field("Date/Time Canceled"; "Date/Time Canceled")
                {
                    ToolTip = 'Specifies the date and time that the document was canceled.';
                }
                field("Error Code"; "Error Code")
                {
                    ToolTip = 'Specifies the error code that the authorized service provider, PAC, has returned to Business Central.';
                }
                field("Error Description"; "Error Description")
                {
                    ToolTip = 'Specifies the error message that the authorized service provider, PAC, has returned to Business Central.';
                }
                field("PAC Web Service Name"; "PAC Web Service Name")
                {
                    ToolTip = 'Specifies the name of the authorized service provider, PAC, which has processed the electronic document.';
                }
                field("Fiscal Invoice Number PAC"; "Fiscal Invoice Number PAC")
                {
                    ToolTip = 'Specifies the official invoice number for the electronic document.';
                }
                field("No. of E-Documents Sent"; "No. of E-Documents Sent")
                {
                    ToolTip = 'Specifies the number of times that this document has been sent electronically.';
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
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';

                    trigger OnAction()
                    begin
                        OnBeforeCalculateSalesTaxStatistics(Rec);
                        if "Tax Area Code" = '' then
                            PAGE.RunModal(PAGE::"Service Invoice Statistics", Rec, "No.")
                        else
                            PAGE.RunModal(PAGE::"Service Invoice Stats.", Rec, "No.");
                    end;
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    Promoted = true;
                    PromotedCategory = Category4;
                    RunObject = Page "Service Comment Sheet";
                    RunPageLink = Type = CONST(General),
                                  "Table Name" = CONST("Service Invoice Header"),
                                  "No." = FIELD("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDimensions;
                        CurrPage.SaveRecord;
                    end;
                }
                action("Service Document Lo&g")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Document Lo&g';
                    Image = Log;
                    Promoted = true;
                    PromotedCategory = Category4;
                    ToolTip = 'View a list of the service document changes that have been logged. The program creates entries in the window when, for example, the response time or service order status changed, a resource was allocated, a service order was shipped or invoiced, and so on. Each line in this window identifies the event that occurred to the service document. The line contains the information about the field that was changed, its old and new value, the date and time when the change took place, and the ID of the user who actually made the changes.';

                    trigger OnAction()
                    var
                        TempServDocLog: Record "Service Document Log" temporary;
                    begin
                        TempServDocLog.Reset();
                        TempServDocLog.DeleteAll();
                        TempServDocLog.CopyServLog(TempServDocLog."Document Type"::"Posted Invoice", "No.");
                        TempServDocLog.CopyServLog(TempServDocLog."Document Type"::Order, "Order No.");
                        TempServDocLog.CopyServLog(TempServDocLog."Document Type"::Invoice, "Pre-Assigned No.");

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
                    Caption = 'S&end';
                    Ellipsis = true;
                    Image = SendTo;
                    ToolTip = 'Send an email to the customer with the electronic service invoice attached as an XML file.';

                    trigger OnAction()
                    begin
                        RequestStampEDocument;
                    end;
                }
                action("Export E-Document as &XML")
                {
                    Caption = 'Export E-Document as &XML';
                    Image = ExportElectronicDocument;
                    ToolTip = 'Export the posted sales service invoice as an electronic service invoice, an XML file, and save it to a specified location.';

                    trigger OnAction()
                    begin
                        ExportEDocument;
                    end;
                }
                action(ExportEDocumentPDF)
                {
                    Caption = 'Export E-Document as PDF';
                    Image = ExportToBank;
                    ToolTip = 'Export the posted sales service invoice as an electronic service invoice, a PDF document, when the stamp is received.';

                    trigger OnAction()
                    begin
                        ExportEDocumentPDF();
                    end;
                }
                action(CFDIRelationDocuments)
                {
                    ApplicationArea = BasicMX;
                    Caption = 'CFDI Relation Documents';
                    Image = Allocations;
                    RunObject = Page "CFDI Relation Documents";
                    RunPageLink = "Document Table ID" = CONST(5992),
                                  "Document No." = FIELD("No."),
                                  "Customer No." = FIELD("Bill-to Customer No.");
                    RunPageMode = View;
                    ToolTip = 'View or add CFDI relation documents for the record.';
                }
                action("&Cancel")
                {
                    Caption = '&Cancel';
                    Image = Cancel;
                    ToolTip = 'Cancel the sending of the electronic service invoice.';

                    trigger OnAction()
                    begin
                        CancelEDocument;
                    end;
                }
            }
            action(SendCustom)
            {
                ApplicationArea = Service;
                Caption = 'Send';
                Ellipsis = true;
                Image = SendToMultiple;
                Promoted = true;
                PromotedCategory = Category5;
                PromotedIsBig = true;
                ToolTip = 'Prepare to send the document according to the customer''s sending profile, such as attached to an email. The Send document to window opens first so you can confirm or select a sending profile.';

                trigger OnAction()
                begin
                    ServiceInvHeader := Rec;
                    CurrPage.SetSelectionFilter(ServiceInvHeader);
                    ServiceInvHeader.SendRecords;
                end;
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
                begin
                    CurrPage.SetSelectionFilter(ServiceInvHeader);
                    ServiceInvHeader.PrintRecords(true);
                end;
            }
            action("&Navigate")
            {
                ApplicationArea = Service;
                Caption = '&Navigate';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Category4;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                begin
                    Navigate;
                end;
            }
            action(ActivityLog)
            {
                ApplicationArea = Service;
                Caption = 'Activity Log';
                Image = Log;
                Promoted = true;
                PromotedCategory = Category4;
                ToolTip = 'View the status and any errors if the document was sent as an electronic document or OCR file through the document exchange service.';

                trigger OnAction()
                begin
                    ShowActivityLog;
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        DocExchStatusStyle := GetDocExchStatusStyle;
        DocExchStatusVisible := "Document Exchange Status" <> "Document Exchange Status"::"Not Sent";
    end;

    trigger OnAfterGetRecord()
    begin
        DocExchStatusStyle := GetDocExchStatusStyle;
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        if Find(Which) then
            exit(true);
        SetRange("No.");
        exit(Find(Which));
    end;

    trigger OnOpenPage()
    begin
        SetSecurityFilterOnRespCenter;

        ActivateFields;
    end;

    var
        ServiceInvHeader: Record "Service Invoice Header";
        FormatAddress: Codeunit "Format Address";
        ChangeExchangeRate: Page "Change Exchange Rate";
        DocExchStatusStyle: Text;
        DocExchStatusVisible: Boolean;
        IsSellToCountyVisible: Boolean;
        IsShipToCountyVisible: Boolean;
        IsBillToCountyVisible: Boolean;

    local procedure ActivateFields()
    begin
        IsSellToCountyVisible := FormatAddress.UseCounty("Country/Region Code");
        IsShipToCountyVisible := FormatAddress.UseCounty("Ship-to Country/Region Code");
        IsBillToCountyVisible := FormatAddress.UseCounty("Bill-to Country/Region Code");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateSalesTaxStatistics(var ServiceInvoiceHeader: Record "Service Invoice Header")
    begin
    end;
}

