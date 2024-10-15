#if not CLEAN20
page 6650 "Posted Return Shipment"
{
    Caption = 'Posted Return Shipment';
    InsertAllowed = false;
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = "Return Shipment Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Buy-from Vendor No."; "Buy-from Vendor No.")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the name of the vendor who delivered the items.';
                }
                field("Buy-from Contact No."; "Buy-from Contact No.")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = false;
                    ToolTip = 'Specifies the number of the contact person at the vendor who delivered the items.';
                }
                group("Buy-from")
                {
                    Caption = 'Buy-from';
                    field("Buy-from Vendor Name"; "Buy-from Vendor Name")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Name';
                        Editable = false;
                        ToolTip = 'Specifies the name of the vendor who delivered the items.';
                    }
                    field("Buy-from Address"; "Buy-from Address")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Address';
                        Editable = false;
                        ToolTip = 'Specifies the address of the vendor who delivered the items.';
                    }
                    field("Buy-from Address 2"; "Buy-from Address 2")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Address 2';
                        Editable = false;
                        ToolTip = 'Specifies an additional part of the address of the vendor who delivered the items.';
                    }
                    field("Buy-from City"; "Buy-from City")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'City';
                        Editable = false;
                        ToolTip = 'Specifies the city of the vendor who delivered the items.';
                    }
                    group(Control13)
                    {
                        ShowCaption = false;
                        Visible = IsBuyFromCountyVisible;
                        field("Buy-from County"; "Buy-from County")
                        {
                            ApplicationArea = PurchReturnOrder;
                            Caption = 'County';
                            Editable = false;
                        }
                    }
                    field("Buy-from Post Code"; "Buy-from Post Code")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Post Code';
                        Editable = false;
                        ToolTip = 'Specifies the post code of the vendor who delivered the items.';
                    }
                    field("Buy-from Country/Region Code"; "Buy-from Country/Region Code")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Country/Region';
                        Editable = false;
                    }
                    field("Buy-from Contact"; "Buy-from Contact")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Contact';
                        Editable = false;
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
                field("Posting Description"; "Posting Description")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = false;
                    ToolTip = 'Specifies a description of the document. The posting description also appers on customer and G/L entries.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '20.0';
                    Visible = false;
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = false;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field("Return Order No."; "Return Order No.")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the return order that will post a return shipment.';
                }
                field("Vendor Authorization No."; "Vendor Authorization No.")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the identification number of a compensation agreement.';
                }
                field("Order Address Code"; "Order Address Code")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = false;
                    ToolTip = 'Specifies the order address of the related customer.';
                }
                field("Purchaser Code"; "Purchaser Code")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = false;
                    ToolTip = 'Specifies which purchaser is assigned to the vendor.';
                }
                field("Responsibility Center"; "Responsibility Center")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the code of the responsibility center, such as a distribution hub, that is associated with the involved user, company, customer, or vendor.';
                }
                field(Correction; Correction)
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = false;
                    ToolTip = 'Specifies the entry as a corrective entry.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '20.0';
                    Visible = false;
                }
                field("No. Printed"; "No. Printed")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = false;
                    ToolTip = 'Specifies how many times the document has been printed.';
                }
            }
            part(ReturnShptLines; "Posted Return Shipment Subform")
            {
                ApplicationArea = PurchReturnOrder;
                SubPageLink = "Document No." = FIELD("No.");
            }
            group(Invoicing)
            {
                Caption = 'Invoicing';
                field("Pay-to Vendor No."; "Pay-to Vendor No.")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the vendor that you received the invoice from.';
                }
                field("Pay-to Contact No."; "Pay-to Contact No.")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = false;
                    ToolTip = 'Specifies the number of the person to contact about an invoice from this customer.';
                }
                group(Control15)
                {
                    ShowCaption = false;
                    field("Pay-to Name"; "Pay-to Name")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Name';
                        Editable = false;
                        ToolTip = 'Specifies the name of the customer who you received the invoice from.';
                    }
                    field("Pay-to Address"; "Pay-to Address")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Address';
                        Editable = false;
                        ToolTip = 'Specifies the address of the vendor that you received the invoice from.';
                    }
                    field("Pay-to Address 2"; "Pay-to Address 2")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Address 2';
                        Editable = false;
                        ToolTip = 'Specifies an additional part of the address of the customer that the invoice was shipped to.';
                    }
                    field("Pay-to City"; "Pay-to City")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'City';
                        Editable = false;
                        ToolTip = 'Specifies the city of the customer that you shipped the invoice to.';
                    }
                    group(Control23)
                    {
                        ShowCaption = false;
                        Visible = IsPayFromCountyVisible;
                        field("Pay-to County"; "Pay-to County")
                        {
                            ApplicationArea = PurchReturnOrder;
                            Caption = 'County';
                            Editable = false;
                        }
                    }
                    field("Pay-to Post Code"; "Pay-to Post Code")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Post Code';
                        Editable = false;
                        ToolTip = 'Specifies the post code of the customer that you received the invoice from.';
                    }
                    field("Pay-to Country/Region Code"; "Pay-to Country/Region Code")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Country/Region';
                        Editable = false;
                    }
                    field("Pay-to Contact"; "Pay-to Contact")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Contact';
                        Editable = false;
                        ToolTip = 'Specifies the name of the person to contact about an invoice from this customer.';
                    }
                    field(PayToContactPhoneNo; PayToContact."Phone No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Phone No.';
                        Editable = false;
                        Importance = Additional;
                        ExtendedDatatype = PhoneNo;
                        ToolTip = 'Specifies the telephone number of the vendor contact person.';
                    }
                    field(PayToContactMobilePhoneNo; PayToContact."Mobile Phone No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Mobile Phone No.';
                        Editable = false;
                        Importance = Additional;
                        ExtendedDatatype = PhoneNo;
                        ToolTip = 'Specifies the mobile telephone number of the vendor contact person.';
                    }
                    field(PayToContactEmail; PayToContact."E-Mail")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Email';
                        Editable = false;
                        Importance = Additional;
                        ExtendedDatatype = Email;
                        ToolTip = 'Specifies the email address of the vendor contact person.';
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
                field("Applies-to Doc. Type"; "Applies-to Doc. Type")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the type of the posted document that this document or journal line will be applied to when you post, for example to register payment.';
                }
                field("Applies-to Doc. No."; "Applies-to Doc. No.")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the posted document that this document or journal line will be applied to when you post, for example to register payment.';
                }
                field("VAT Bus. Posting Group"; "VAT Bus. Posting Group")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = false;
                    ToolTip = 'Specifies a VAT business posting group code.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '20.0';
                    Visible = false;
                }
                field("Vendor Posting Group"; "Vendor Posting Group")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = false;
                    ToolTip = 'Specifies the vendor''s market type to link business transactions made for the vendor with the appropriate account in the general ledger.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '20.0';
                    Visible = false;
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
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Name';
                        Editable = false;
                        ToolTip = 'Specifies the name of the customer at the address that the items are shipped to.';
                    }
                    field("Ship-to Address"; "Ship-to Address")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Address';
                        Editable = false;
                        ToolTip = 'Specifies the address that the items are shipped to.';
                    }
                    field("Ship-to Address 2"; "Ship-to Address 2")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Address 2';
                        Editable = false;
                        ToolTip = 'Specifies an additional part of the ship-to address, in case it is a long address.';
                    }
                    field("Ship-to City"; "Ship-to City")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'City';
                        Editable = false;
                        ToolTip = 'Specifies the city of the address that the items are shipped to.';
                    }
                    group(Control35)
                    {
                        ShowCaption = false;
                        Visible = IsShipToCountyVisible;
                        field("Ship-to County"; "Ship-to County")
                        {
                            ApplicationArea = PurchReturnOrder;
                            Caption = 'County';
                            Editable = false;
                        }
                    }
                    field("Ship-to Post Code"; "Ship-to Post Code")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Post Code';
                        Editable = false;
                        ToolTip = 'Specifies the postal code of the address that the items are shipped to.';
                    }
                    field("Ship-to Country/Region Code"; "Ship-to Country/Region Code")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Country/Region';
                        Editable = false;
                    }
                    field("Ship-to Contact"; "Ship-to Contact")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Contact';
                        Editable = false;
                        ToolTip = 'Specifies the name of the contact person at the address that the items are shipped to.';
                    }
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the location from where inventory items to the customer on the sales document are to be shipped by default.';
                }
            }
            group("Foreign Trade")
            {
                Caption = 'Foreign Trade';
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = PurchReturnOrder;
                    Importance = Promoted;
                    ToolTip = 'Specifies the currency that is used on the entry.';

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
                field("Transaction Type"; "Transaction Type")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = false;
                    ToolTip = 'Specifies the transaction type for the partner record. This information is used for Intrastat reporting.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '20.0';
                    Visible = false;
                }
                field("Transaction Specification"; "Transaction Specification")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = false;
                    ToolTip = 'Specifies a code for the transaction specification, for the purpose of reporting to INTRASTAT.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '20.0';
                    Visible = false;
                }
                field("Transport Method"; "Transport Method")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = false;
                    ToolTip = 'Specifies the transport method, for the purpose of reporting to INTRASTAT.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '20.0';
                    Visible = false;
                }
                field("Entry Point"; "Entry Point")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = false;
                    ToolTip = 'Specifies the code of the port of entry where the items pass into your country/region.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '20.0';
                    Visible = false;
                }
                field("Area"; Area)
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = false;
                    ToolTip = 'Specifies the area code used in the return shipment.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '20.0';
                    Visible = false;
                }
                field("VAT Registration No."; "VAT Registration No.")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = false;
                    ToolTip = 'Specifies the VAT registration number. The field will be used when you do business with partners from EU countries/regions.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '20.0';
                    Visible = false;
                }
                field("Language Code"; "Language Code")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = false;
                    ToolTip = 'Specifies the language to be used on printouts for this document.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '20.0';
                    Visible = false;
                }
                field("VAT Country/Region Code"; "VAT Country/Region Code")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = false;
                    ToolTip = 'Specifies the VAT country/region code of vendor.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '20.0';
                    Visible = false;
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
            group("&Return Shpt.")
            {
                Caption = '&Return Shpt.';
                Image = Shipment;
                action(Statistics)
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Return Shipment Statistics";
                    RunPageLink = "No." = FIELD("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
                action("Co&mments")
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Purch. Comment Sheet";
                    RunPageLink = "Document Type" = CONST("Posted Return Shipment"),
                                  "No." = FIELD("No."),
                                  "Document Line No." = CONST(0);
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
                        ShowDimensions();
                    end;
                }
                action(Approvals)
                {
                    AccessByPermission = TableData "Posted Approval Entry" = R;
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Approvals';
                    Image = Approvals;
                    ToolTip = 'View a list of the records that are waiting to be approved. For example, you can see who requested the record to be approved, when it was sent, and when it is due to be approved.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.ShowPostedApprovalEntries(RecordId);
                    end;
                }
            }
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(DocumentLineTracking)
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Document &Line Tracking';
                    Image = Navigate;
                    ToolTip = 'View related open, posted, or archived documents or document lines.';

                    trigger OnAction()
                    begin
                        CurrPage.ReturnShptLines.PAGE.ShowDocumentLineTracking();
                    end;
                }
                action(CertificateOfSupplyDetails)
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Certificate of Supply Details';
                    Image = Certificate;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Process;
                    RunObject = Page "Certificates of Supply";
                    RunPageLink = "Document Type" = FILTER("Return Shipment"),
                                  "Document No." = FIELD("No.");
                    ToolTip = 'View the certificate of supply that you must send to your customer for signature as confirmation of receipt. You must print a certificate of supply if the shipment uses a combination of VAT business posting group and VAT product posting group that have been marked to require a certificate of supply in the VAT Posting Setup window.';
                }
                action(PrintCertificateofSupply)
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Print Certificate of Supply';
                    Image = PrintReport;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Process;
                    ToolTip = 'Print the certificate of supply that you must send to your customer for signature as confirmation of receipt.';

                    trigger OnAction()
                    var
                        CertificateOfSupply: Record "Certificate of Supply";
                    begin
                        CertificateOfSupply.SetRange("Document Type", CertificateOfSupply."Document Type"::"Return Shipment");
                        CertificateOfSupply.SetRange("Document No.", "No.");
                        CertificateOfSupply.Print;
                    end;
                }
            }
        }
        area(processing)
        {
            action("&Print")
            {
                ApplicationArea = PurchReturnOrder;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                begin
                    ReturnShptHeader := Rec;
                    OnBeforePrintRecords(Rec, ReturnShptHeader);
                    CurrPage.SetSelectionFilter(ReturnShptHeader);
                    ReturnShptHeader.PrintRecords(true);
                end;
            }
            action("&Navigate")
            {
                ApplicationArea = PurchReturnOrder;
                Caption = 'Find entries...';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Process;
                ShortCutKey = 'Ctrl+Alt+Q';
                ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';

                trigger OnAction()
                begin
                    Navigate;
                end;
            }
            action("Update Document")
            {
                ApplicationArea = PurchReturnOrder;
                Caption = 'Update Document';
                Image = Edit;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Add new information that is relevant to the document, such as the country or region. You can only edit a few fields because the document has already been posted.';

                trigger OnAction()
                var
                    PostedReturnShptUpdate: Page "Posted Return Shpt. - Update";
                begin
                    PostedReturnShptUpdate.LookupMode := true;
                    PostedReturnShptUpdate.SetRec(Rec);
                    PostedReturnShptUpdate.RunModal();
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnOpenPage(Rec, IsHandled);
        if IsHandled then
            exit;

        SetSecurityFilterOnRespCenter;

        ActivateFields;
    end;

    trigger OnAfterGetRecord()
    begin
        BuyFromContact.GetOrClear("Buy-from Contact No.");
        PayToContact.GetOrClear("Pay-to Contact No.");
    end;

    var
        ReturnShptHeader: Record "Return Shipment Header";
        BuyFromContact: Record Contact;
        PayToContact: Record Contact;
        FormatAddress: Codeunit "Format Address";
        ChangeExchangeRate: Page "Change Exchange Rate";
        IsShipToCountyVisible: Boolean;
        IsPayFromCountyVisible: Boolean;
        IsBuyFromCountyVisible: Boolean;

    local procedure ActivateFields()
    begin
        IsBuyFromCountyVisible := FormatAddress.UseCounty("Buy-from Country/Region Code");
        IsPayFromCountyVisible := FormatAddress.UseCounty("Pay-to Country/Region Code");
        IsShipToCountyVisible := FormatAddress.UseCounty("Ship-to Country/Region Code");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintRecords(var ReturnShipmentHeaderRec: Record "Return Shipment Header"; var ReturnShipmentHeaderToPrint: Record "Return Shipment Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeOnOpenPage(var ReturnShipmentHeader: Record "Return Shipment Header"; var IsHandled: Boolean)
    begin
    end;
}
#endif
