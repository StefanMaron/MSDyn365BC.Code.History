page 6630 "Sales Return Order"
{
    Caption = 'Sales Return Order';
    PageType = Document;
    PromotedActionCategories = 'New,Process,Report,Approve,Release,Posting,Prepare,Invoice,Request Approval,Print/Send,Return Order,Navigate';
    RefreshOnActivate = true;
    SourceTable = "Sales Header";
    SourceTableView = WHERE("Document Type" = FILTER("Return Order"));

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
                    Visible = DocNoVisible;

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field("Sell-to Customer No."; "Sell-to Customer No.")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Customer No.';
                    Importance = Additional;
                    NotBlank = true;
                    ToolTip = 'Specifies the number of the customer associated with the sales return.';

                    trigger OnValidate()
                    begin
                        SelltoCustomerNoOnAfterValidate(Rec, xRec);
                        CurrPage.Update();
                    end;
                }
                field("Sell-to Customer Name"; "Sell-to Customer Name")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Customer Name';
                    Importance = Promoted;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the name of the customer.';

                    trigger OnValidate()
                    begin
                        SelltoCustomerNoOnAfterValidate(Rec, xRec);

                        if ApplicationAreaMgmtFacade.IsFoundationEnabled then
                            SalesCalcDiscByType.ApplyDefaultInvoiceDiscount(0, Rec);

                        CurrPage.Update();
                    end;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(Rec.LookupSellToCustomerName(Text));
                    end;
                }
                group("Sell-to")
                {
                    Caption = 'Sell-to';
                    field("Sell-to Address"; "Sell-to Address")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Address';
                        Importance = Additional;
                        ToolTip = 'Specifies the customer''s address.';
                    }
                    field("Sell-to Address 2"; "Sell-to Address 2")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Address 2';
                        Importance = Additional;
                        ToolTip = 'Specifies an additional part of the customer''s address.';
                    }
                    group(Control170)
                    {
                        ShowCaption = false;
                        Visible = IsSellToCountyVisible;
                        field("Sell-to County"; "Sell-to County")
                        {
                            ApplicationArea = SalesReturnOrder;
                            Caption = 'County';
                            Importance = Additional;
                            ToolTip = 'Specifies the county of the address.';
                        }
                    }
                    field("Sell-to City"; "Sell-to City")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'City';
                        Importance = Additional;
                        ToolTip = 'Specifies the city of the customer''s address.';
                    }
                    field("Sell-to Post Code"; "Sell-to Post Code")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Post Code';
                        Importance = Additional;
                        ToolTip = 'Specifies the postal code of the customer''s address.';
                    }
                    field("Sell-to Country/Region Code"; "Sell-to Country/Region Code")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Country/Region';
                        ToolTip = 'Specifies the country or region of the address.';

                        trigger OnValidate()
                        begin
                            IsSellToCountyVisible := FormatAddress.UseCounty("Sell-to Country/Region Code");
                        end;
                    }
                    field("Sell-to Contact No."; "Sell-to Contact No.")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Contact No.';
                        Importance = Additional;
                        ToolTip = 'Specifies the number of the contact person at the customer.';

                        trigger OnValidate()
                        begin
                            if GetFilter("Sell-to Contact No.") = xRec."Sell-to Contact No." then
                                if "Sell-to Contact No." <> xRec."Sell-to Contact No." then
                                    SetRange("Sell-to Contact No.");
                        end;
                    }
                    field(SellToPhoneNo; SellToContact."Phone No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Phone No.';
                        Importance = Additional;
                        Editable = false;
                        ExtendedDatatype = PhoneNo;
                        ToolTip = 'Specifies the telephone number of the contact person that the sales document will be sent to.';
                    }
                    field(SellToMobilePhoneNo; SellToContact."Mobile Phone No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Mobile Phone No.';
                        Importance = Additional;
                        Editable = false;
                        ExtendedDatatype = PhoneNo;
                        ToolTip = 'Specifies the mobile telephone number of the contact person that the sales document will be sent to.';
                    }
                    field(SellToEmail; SellToContact."E-Mail")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Email';
                        Importance = Additional;
                        Editable = false;
                        ExtendedDatatype = EMail;
                        ToolTip = 'Specifies the email address of the contact person that the sales document will be sent to.';
                    }
                }
                field("Sell-to Contact"; "Sell-to Contact")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Contact';
                    Editable = "Sell-to Customer No." <> '';
                    ToolTip = 'Specifies the name of the contact person at the customer.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = SalesReturnOrder;
                    Importance = Additional;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = SalesReturnOrder;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date when the sales document was posted.';

                    trigger OnValidate()
                    begin
                        SaveInvoiceDiscountAmount;
                    end;
                }
                field("Order Date"; "Order Date")
                {
                    ApplicationArea = SalesReturnOrder;
                    Importance = Promoted;
                    QuickEntry = false;
                    ToolTip = 'Specifies the date when the order was created.';
                }
                field("External Document No."; "External Document No.")
                {
                    ApplicationArea = SalesReturnOrder;
                    Importance = Promoted;
                    ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
                }
                field("Your Reference"; "Your Reference")
                {
                    ApplicationArea = SalesReturnOrder;
                    Importance = Additional;
                    ToolTip = 'Specifies the customer''s reference. The content will be printed on sales documents.';
                }
                field("No. of Archived Versions"; "No. of Archived Versions")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the number of archived versions for this document.';
                }
                field("Salesperson Code"; "Salesperson Code")
                {
                    ApplicationArea = SalesReturnOrder;
                    Importance = Additional;
                    QuickEntry = false;
                    ToolTip = 'Specifies the name of the salesperson who is assigned to the customer.';

                    trigger OnValidate()
                    begin
                        SalespersonCodeOnAfterValidate;
                    end;
                }
                field("Campaign No."; "Campaign No.")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the campaign number the document is linked to.';
                }
                field("Responsibility Center"; "Responsibility Center")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code of the responsibility center, such as a distribution hub, that is associated with the involved user, company, customer, or vendor.';
                }
                field("Assigned User ID"; "Assigned User ID")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the ID of the user who is responsible for the document.';
                }
                field("Job Queue Status"; "Job Queue Status")
                {
                    ApplicationArea = All;
                    Importance = Additional;
                    ToolTip = 'Specifies the status of a job queue entry or task that handles the posting of sales return orders.';
                    Visible = JobQueueUsed;
                }
                field(Status; Status)
                {
                    ApplicationArea = SalesReturnOrder;
                    Importance = Promoted;
                    StyleExpr = StatusStyleTxt;
                    QuickEntry = false;
                    ToolTip = 'Specifies whether the document is open, waiting to be approved, has been invoiced for prepayment, or has been released to the next stage of processing.';
                }
            }
            part(SalesLines; "Sales Return Order Subform")
            {
                ApplicationArea = SalesReturnOrder;
                Editable = "Sell-to Customer No." <> '';
                Enabled = "Sell-to Customer No." <> '';
                SubPageLink = "Document No." = FIELD("No.");
                UpdatePropagation = Both;
            }
            group("Invoice Details")
            {
                Caption = 'Invoice Details';
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = SalesReturnOrder;
                    Importance = Promoted;
                    ToolTip = 'Specifies the currency that is used on the entry.';

                    trigger OnAssistEdit()
                    begin
                        if "Posting Date" <> 0D then
                            ChangeExchangeRate.SetParameter("Currency Code", "Currency Factor", "Posting Date")
                        else
                            ChangeExchangeRate.SetParameter("Currency Code", "Currency Factor", WorkDate);
                        if ChangeExchangeRate.RunModal = ACTION::OK then begin
                            Validate("Currency Factor", ChangeExchangeRate.GetParameter);
                            SaveInvoiceDiscountAmount;
                        end;
                        Clear(ChangeExchangeRate);
                    end;

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord;
                        SalesCalcDiscByType.ApplyDefaultInvoiceDiscount(0, Rec);
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
                field("Payment Terms Code"; "Payment Terms Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies a formula that calculates the payment due date, payment discount date, and payment discount amount.';
                }
                field("EU 3-Party Trade"; "EU 3-Party Trade")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies if the transaction is related to trade with a third party within the EU.';
                }
                field("Payment Method Code"; "Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies how to make payment, such as with bank transfer, cash, or check.';
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';

                    trigger OnValidate()
                    begin
                        ShortcutDimension1CodeOnAfterV;
                    end;
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';

                    trigger OnValidate()
                    begin
                        ShortcutDimension2CodeOnAfterV;
                    end;
                }
                field("Shipment Date"; "Shipment Date")
                {
                    ApplicationArea = SalesReturnOrder;
                    Importance = Promoted;
                    ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';
                }
                field("Applies-to Doc. Type"; "Applies-to Doc. Type")
                {
                    ApplicationArea = SalesReturnOrder;
                    Importance = Promoted;
                    ToolTip = 'Specifies the type of the posted document that this document or journal line will be applied to when you post, for example to register payment.';
                }
                field("Applies-to Doc. No."; "Applies-to Doc. No.")
                {
                    ApplicationArea = SalesReturnOrder;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the posted document that this document or journal line will be applied to when you post, for example to register payment.';
                }
                field("Applies-to ID"; "Applies-to ID")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the ID of entries that will be applied to when you choose the Apply Entries action.';
                }
                field("Tax Liable"; "Tax Liable")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies if the customer or vendor is liable for sales tax.';
                }
                field("Tax Area Code"; "Tax Area Code")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies the tax area code for the customer.';

                    trigger OnValidate()
                    begin
                        CurrPage.SalesLines.PAGE.RedistributeTotalsOnAfterValidate;
                    end;
                }
            }
            group("Shipping and Billing")
            {
                Caption = 'Shipping and Billing';
                group("Shipment Method")
                {
                    Caption = 'Shipment Method';
                    field("Shipping Agent Code"; "Shipping Agent Code")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Agent';
                        Importance = Additional;
                        ToolTip = 'Specifies which shipping agent is used to transport the items on the sales document to the customer.';
                    }
                    field("Shipping Agent Service Code"; "Shipping Agent Service Code")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Agent Service';
                        Importance = Additional;
                        ToolTip = 'Specifies which shipping agent service is used to transport the items on the sales document to the customer.';
                    }
                    field("Package Tracking No."; "Package Tracking No.")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Importance = Additional;
                        ToolTip = 'Specifies the shipping agent''s package number.';
                    }
                }
                group("Ship-to")
                {
                    Caption = 'Ship-to';
                    field("Location Code"; "Location Code")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Location';
                        Importance = Promoted;
                        ToolTip = 'Specifies the location from where inventory items to the customer on the sales document are to be shipped by default.';
                    }
                    field("Ship-to Name"; "Ship-to Name")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Name';
                        ToolTip = 'Specifies the name that products on the sales document will be shipped to.';
                    }
                    field("Ship-to Address"; "Ship-to Address")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Address';
                        ToolTip = 'Specifies the address that products on the sales document will be shipped to.';
                    }
                    field("Ship-to Address 2"; "Ship-to Address 2")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Address 2';
                        ToolTip = 'Specifies an additional part of the shipping address.';
                    }
                    group(Control76)
                    {
                        ShowCaption = false;
                        Visible = IsShipToCountyVisible;
                        field("Ship-to County"; "Ship-to County")
                        {
                            ApplicationArea = SalesReturnOrder;
                            Caption = 'County';
                            ToolTip = 'Specifies the county of the address.';
                        }
                    }
                    field("Ship-to City"; "Ship-to City")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'City';
                        ToolTip = 'Specifies the city of the shipping address.';
                    }
                    field("Ship-to Post Code"; "Ship-to Post Code")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Post Code';
                        ToolTip = 'Specifies the postal code of the shipping address.';
                    }
                    field("Ship-to Country/Region Code"; "Ship-to Country/Region Code")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Country/Region';
                        ToolTip = 'Specifies the country or region of the address.';

                        trigger OnValidate()
                        begin
                            IsShipToCountyVisible := FormatAddress.UseCounty("Ship-to Country/Region Code");
                        end;
                    }
                    field("Ship-to Contact"; "Ship-to Contact")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Contact';
                        ToolTip = 'Specifies the name of the contact person at the shipping address.';
                    }
                }
                group("Bill-to")
                {
                    Caption = 'Bill-to';
                    field("Bill-to Name"; "Bill-to Name")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Name';
                        Importance = Promoted;
                        ToolTip = 'Specifies the customer to whom you will send the sales invoice, when different from the customer that you are selling to.';

                        trigger OnValidate()
                        begin
                            if GetFilter("Bill-to Customer No.") = xRec."Bill-to Customer No." then
                                if "Bill-to Customer No." <> xRec."Bill-to Customer No." then
                                    SetRange("Bill-to Customer No.");

                            CurrPage.SaveRecord;
                            if ApplicationAreaMgmtFacade.IsFoundationEnabled then
                                SalesCalcDiscByType.ApplyDefaultInvoiceDiscount(0, Rec);

                            CurrPage.Update(false);
                        end;
                    }
                    field("Bill-to Address"; "Bill-to Address")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Address';
                        Editable = "Bill-to Customer No." <> "Sell-to Customer No.";
                        Enabled = "Bill-to Customer No." <> "Sell-to Customer No.";
                        Importance = Additional;
                        ToolTip = 'Specifies the address of the customer that you will send the invoice to.';
                    }
                    field("Bill-to Address 2"; "Bill-to Address 2")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Address 2';
                        Editable = "Bill-to Customer No." <> "Sell-to Customer No.";
                        Enabled = "Bill-to Customer No." <> "Sell-to Customer No.";
                        Importance = Additional;
                        ToolTip = 'Specifies an additional part of the billing address.';
                    }
                    group(Control80)
                    {
                        ShowCaption = false;
                        Visible = IsBillToCountyVisible;
                        field("Bill-to County"; "Bill-to County")
                        {
                            ApplicationArea = SalesReturnOrder;
                            Caption = 'County';
                            Editable = "Bill-to Customer No." <> "Sell-to Customer No.";
                            Enabled = "Bill-to Customer No." <> "Sell-to Customer No.";
                            Importance = Additional;
                            ToolTip = 'Specifies the county of the address.';
                        }
                    }
                    field("Bill-to City"; "Bill-to City")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'City';
                        Editable = "Bill-to Customer No." <> "Sell-to Customer No.";
                        Enabled = "Bill-to Customer No." <> "Sell-to Customer No.";
                        Importance = Additional;
                        ToolTip = 'Specifies the city of the billing address.';
                    }
                    field("Bill-to Post Code"; "Bill-to Post Code")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Post Code';
                        Editable = "Bill-to Customer No." <> "Sell-to Customer No.";
                        Enabled = "Bill-to Customer No." <> "Sell-to Customer No.";
                        Importance = Additional;
                        ToolTip = 'Specifies the postal code of the billing address.';
                    }
                    field("Bill-to Country/Region Code"; "Bill-to Country/Region Code")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Country/Region';
                        Editable = "Bill-to Customer No." <> "Sell-to Customer No.";
                        Enabled = "Bill-to Customer No." <> "Sell-to Customer No.";
                        Importance = Additional;
                        ToolTip = 'Specifies the country or region of the address.';

                        trigger OnValidate()
                        begin
                            IsBillToCountyVisible := FormatAddress.UseCounty("Bill-to Country/Region Code");
                        end;
                    }
                    field("Bill-to Contact No."; "Bill-to Contact No.")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Contact No.';
                        Editable = "Bill-to Customer No." <> "Sell-to Customer No.";
                        Enabled = "Bill-to Customer No." <> "Sell-to Customer No.";
                        Importance = Additional;
                        ToolTip = 'Specifies the number of the contact person at the billing address.';
                    }
                    field("Bill-to Contact"; "Bill-to Contact")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Contact';
                        ToolTip = 'Specifies the name of the contact person at the billing address.';
                    }
                    field(BillToContactPhoneNo; BillToContact."Phone No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Phone No.';
                        Editable = false;
                        Importance = Additional;
                        ExtendedDatatype = PhoneNo;
                        ToolTip = 'Specifies the telephone number of the person you should contact at the customer you are sending the invoice to.';
                    }
                    field(BillToContactMobilePhoneNo; BillToContact."Mobile Phone No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Mobile Phone No.';
                        Editable = false;
                        Importance = Additional;
                        ExtendedDatatype = PhoneNo;
                        ToolTip = 'Specifies the mobile telephone number of the person you should contact at the customer you are sending the invoice to.';
                    }
                    field(BillToContactEmail; BillToContact."E-Mail")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Email';
                        Editable = false;
                        Importance = Additional;
                        ExtendedDatatype = EMail;
                        ToolTip = 'Specifies the email address of the person you should contact at the customer you are sending the invoice to.';
                    }
                }
            }
            group("Foreign Trade")
            {
                Caption = 'Foreign Trade';
                field("Transaction Specification"; "Transaction Specification")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies a specification of the document''s transaction, for the purpose of reporting to INTRASTAT.';
                }
                field("Transaction Type"; "Transaction Type")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the type of transaction that the document represents, for the purpose of reporting to INTRASTAT.';
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
            part("Attached Documents"; "Document Attachment Factbox")
            {
                ApplicationArea = All;
                Caption = 'Attachments';
                SubPageLink = "Table ID" = CONST(36),
                              "No." = FIELD("No."),
                              "Document Type" = FIELD("Document Type");
            }
            part(Control19; "Pending Approval FactBox")
            {
                ApplicationArea = SalesReturnOrder;
                SubPageLink = "Table ID" = CONST(36),
                              "Document Type" = FIELD("Document Type"),
                              "Document No." = FIELD("No.");
                Visible = OpenApprovalEntriesExistForCurrUser;
            }
            part(Control1903720907; "Sales Hist. Sell-to FactBox")
            {
                ApplicationArea = SalesReturnOrder;
                SubPageLink = "No." = FIELD("Sell-to Customer No."),
                              "Date Filter" = field("Date Filter");
            }
            part(Control1907234507; "Sales Hist. Bill-to FactBox")
            {
                ApplicationArea = SalesReturnOrder;
                SubPageLink = "No." = FIELD("Sell-to Customer No."),
                              "Date Filter" = field("Date Filter");
                Visible = false;
            }
            part(Control1902018507; "Customer Statistics FactBox")
            {
                ApplicationArea = SalesReturnOrder;
                SubPageLink = "No." = FIELD("Bill-to Customer No."),
                              "Date Filter" = field("Date Filter");
                Visible = false;
            }
            part(Control1900316107; "Customer Details FactBox")
            {
                ApplicationArea = SalesReturnOrder;
                SubPageLink = "No." = FIELD("Sell-to Customer No."),
                              "Date Filter" = field("Date Filter");
            }
            part(Control1906127307; "Sales Line FactBox")
            {
                ApplicationArea = SalesReturnOrder;
                Provider = SalesLines;
                SubPageLink = "Document Type" = FIELD("Document Type"),
                              "Document No." = FIELD("Document No."),
                              "Line No." = FIELD("Line No.");
                Visible = false;
            }
            part(ApprovalFactBox; "Approval FactBox")
            {
                ApplicationArea = SalesReturnOrder;
                Visible = false;
            }
            part(Control1907012907; "Resource Details FactBox")
            {
                ApplicationArea = SalesReturnOrder;
                Provider = SalesLines;
                SubPageLink = "No." = FIELD("No.");
                Visible = false;
            }
            part(WorkflowStatus; "Workflow Status FactBox")
            {
                ApplicationArea = SalesReturnOrder;
                Editable = false;
                Enabled = false;
                ShowFilter = false;
                Visible = ShowWorkflowStatus;
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Return Order")
            {
                Caption = '&Return Order';
                Image = Return;
                action(Statistics)
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Category11;
                    PromotedIsBig = true;
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';

                    trigger OnAction()
                    var
                        Handled: Boolean;
                    begin
                        OnBeforeStatisticsAction(Rec, Handled);
                        if not Handled then begin
                            OpenSalesOrderStatistics;
                            SalesCalcDiscByType.ResetRecalculateInvoiceDisc(Rec);
                        end
                    end;
                }
                action(Customer)
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Customer';
                    Enabled = IsCustomerOrContactNotEmpty;
                    Image = EditLines;
                    Promoted = true;
                    PromotedCategory = Category12;
                    PromotedIsBig = false;
                    RunObject = Page "Customer Card";
                    RunPageLink = "No." = FIELD("Sell-to Customer No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or edit detailed information about the customer on the sales document.';
                }
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Enabled = "No." <> '';
                    Image = Dimensions;
                    Promoted = true;
                    PromotedCategory = Category11;
                    PromotedIsBig = true;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDocDim;
                        CurrPage.SaveRecord;
                    end;
                }
                action(Approvals)
                {
                    AccessByPermission = TableData "Approval Entry" = R;
                    ApplicationArea = Suite;
                    Caption = 'Approvals';
                    Image = Approvals;
                    Promoted = true;
                    PromotedCategory = Category11;
                    ToolTip = 'View a list of the records that are waiting to be approved. For example, you can see who requested the record to be approved, when it was sent, and when it is due to be approved.';

                    trigger OnAction()
                    var
                        WorkflowsEntriesBuffer: Record "Workflows Entries Buffer";
                    begin
                        WorkflowsEntriesBuffer.RunWorkflowEntriesPage(RecordId, DATABASE::"Sales Header", "Document Type".AsInteger(), "No.");
                    end;
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    Promoted = true;
                    PromotedCategory = Category11;
                    RunObject = Page "Sales Comment Sheet";
                    RunPageLink = "Document Type" = CONST("Return Order"),
                                  "No." = FIELD("No."),
                                  "Document Line No." = CONST(0);
                    ToolTip = 'View or add comments for the record.';
                }
            }
            group(Documents)
            {
                Caption = 'Documents';
                Image = Documents;
                action("Return Receipts")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Return Receipts';
                    Image = ReturnReceipt;
                    Promoted = true;
                    PromotedCategory = Category12;
                    RunObject = Page "Posted Return Receipts";
                    RunPageLink = "Return Order No." = FIELD("No.");
                    RunPageView = SORTING("Return Order No.");
                    ToolTip = 'View a list of posted return receipts for the order.';
                }
                action("Cred&it Memos")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Cred&it Memos';
                    Image = CreditMemo;
                    Promoted = true;
                    PromotedCategory = Category12;
                    RunObject = Page "Posted Sales Credit Memos";
                    RunPageLink = "Return Order No." = FIELD("No.");
                    RunPageView = SORTING("Return Order No.");
                    ToolTip = 'View a list of ongoing credit memos for the order.';
                }
                separator(Action131)
                {
                }
            }
            group(Warehouse)
            {
                Caption = 'Warehouse';
                Image = Warehouse;
                action("In&vt. Put-away/Pick Lines")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'In&vt. Put-away/Pick Lines';
                    Image = PickLines;
                    RunObject = Page "Warehouse Activity List";
                    RunPageLink = "Source Document" = CONST("Sales Return Order"),
                                  "Source No." = FIELD("No.");
                    RunPageView = SORTING("Source Document", "Source No.", "Location Code");
                    ToolTip = 'View items that are inbound or outbound on inventory put-away or inventory pick documents for the transfer order.';
                }
                action("Whse. Receipt Lines")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Whse. Receipt Lines';
                    Image = ReceiptLines;
                    RunObject = Page "Whse. Receipt Lines";
                    RunPageLink = "Source Type" = CONST(37),
                                  "Source Subtype" = FIELD("Document Type"),
                                  "Source No." = FIELD("No.");
                    RunPageView = SORTING("Source Type", "Source Subtype", "Source No.", "Source Line No.");
                    ToolTip = 'View ongoing warehouse receipts for the document, in advanced warehouse configurations.';
                }
            }
        }
        area(processing)
        {
            group(Approval)
            {
                Caption = 'Approval';
                action(Approve)
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Approve';
                    Image = Approve;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Approve the requested changes.';
                    Visible = OpenApprovalEntriesExistForCurrUser;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.ApproveRecordApprovalRequest(RecordId);
                    end;
                }
                action(Reject)
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Reject';
                    Image = Reject;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Reject the approval request.';
                    Visible = OpenApprovalEntriesExistForCurrUser;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.RejectRecordApprovalRequest(RecordId);
                    end;
                }
                action(Delegate)
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Delegate';
                    Image = Delegate;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedOnly = true;
                    ToolTip = 'Delegate the approval to a substitute approver.';
                    Visible = OpenApprovalEntriesExistForCurrUser;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.DelegateRecordApprovalRequest(RecordId);
                    end;
                }
                action(Comment)
                {
                    ApplicationArea = All;
                    Caption = 'Comments';
                    Image = ViewComments;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedOnly = true;
                    ToolTip = 'View or add comments for the record.';
                    Visible = OpenApprovalEntriesExistForCurrUser;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.GetApprovalComment(Rec);
                    end;
                }
            }
            action("&Print")
            {
                ApplicationArea = SalesReturnOrder;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                Promoted = true;
                PromotedCategory = Category10;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                begin
                    DocPrint.PrintSalesHeader(Rec);
                end;
            }
            action(AttachAsPDF)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Attach as PDF';
                Image = PrintAttachment;
                Promoted = true;
                PromotedCategory = Category10;
                ToolTip = 'Create a PDF file and attach it to the document.';

                trigger OnAction()
                var
                    SalesHeader: Record "Sales Header";
                begin
                    SalesHeader := Rec;
                    SalesHeader.SetRecFilter();
                    DocPrint.PrintSalesHeaderToDocumentAttachment(SalesHeader);
                end;
            }
            group(Action7)
            {
                Caption = 'Release';
                Image = ReleaseDoc;
                action(Release)
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Re&lease';
                    Image = ReleaseDoc;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Release the document to the next stage of processing. When a document is released, it will be included in all availability calculations from the expected receipt date of the items. You must reopen the document before you can make changes to it.';

                    trigger OnAction()
                    var
                        ReleaseSalesDoc: Codeunit "Release Sales Document";
                    begin
                        ReleaseSalesDoc.PerformManualRelease(Rec);
                    end;
                }
                action(Reopen)
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Re&open';
                    Enabled = Status <> Status::Open;
                    Image = ReOpen;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedOnly = true;
                    ToolTip = 'Reopen the document to change it after it has been approved. Approved documents have the Released status and must be opened before they can be changed';

                    trigger OnAction()
                    var
                        ReleaseSalesDoc: Codeunit "Release Sales Document";
                    begin
                        ReleaseSalesDoc.PerformManualReopen(Rec);
                    end;
                }
                separator(Action600)
                {
                }
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(CalculateInvoiceDiscount)
                {
                    AccessByPermission = TableData "Cust. Invoice Disc." = R;
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Calculate &Invoice Discount';
                    Image = CalculateInvoiceDiscount;
                    ToolTip = 'Calculate the invoice discount that applies to the sales return order.';

                    trigger OnAction()
                    begin
                        ApproveCalcInvDisc;
                        SalesCalcDiscByType.ResetRecalculateInvoiceDisc(Rec);
                    end;
                }
                separator(Action132)
                {
                }
                action("Apply Entries")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Apply Entries';
                    Ellipsis = true;
                    Image = ApplyEntries;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedOnly = true;
                    ShortCutKey = 'Shift+F11';
                    ToolTip = 'Select one or more ledger entries that you want to apply this record to so that the related posted documents are closed as paid or refunded.';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Sales Header Apply", Rec);
                    end;
                }
                action("Create Return-Related &Documents")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Create Return-Related &Documents';
                    Ellipsis = true;
                    Image = ApplyEntries;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedOnly = true;
                    ToolTip = 'Prepare to automatically create related documents, such as a replacement sales order, a purchase return order, or a replacement purchase order.';

                    trigger OnAction()
                    begin
                        Clear(CreateRetRelDocs);
                        CreateRetRelDocs.SetSalesHeader(Rec);
                        CreateRetRelDocs.RunModal;
                        CreateRetRelDocs.ShowDocuments;
                    end;
                }
                separator(Action133)
                {
                }
                action(CopyDocument)
                {
                    ApplicationArea = Suite;
                    Caption = 'Copy Document';
                    Ellipsis = true;
                    Enabled = "No." <> '';
                    Image = CopyDocument;
                    ToolTip = 'Copy document lines and header information from another sales document to this document. You can copy a posted sales invoice into a new sales invoice to quickly create a similar document.';

                    trigger OnAction()
                    begin
                        CopyDocument();
                        if Get("Document Type", "No.") then;
                    end;
                }
                action(MoveNegativeLines)
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Move Negative Lines';
                    Ellipsis = true;
                    Image = MoveNegativeLines;
                    ToolTip = 'Prepare to create a replacement sales order in a sales return process.';

                    trigger OnAction()
                    begin
                        Clear(MoveNegSalesLines);
                        MoveNegSalesLines.SetSalesHeader(Rec);
                        MoveNegSalesLines.RunModal;
                        MoveNegSalesLines.ShowDocument;
                    end;
                }
                action("Post and &Print")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Post and &Print';
                    Ellipsis = true;
                    Image = PostPrint;
                    Promoted = true;
                    PromotedCategory = Category6;
                    PromotedIsBig = true;
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Finalize and prepare to print the document or journal. The values and quantities are posted to the related accounts. A report request window where you can specify what to include on the print-out.';

                    trigger OnAction()
                    begin
                        PostDocument(CODEUNIT::"Sales-Post + Print");
                    end;
                }
                action(GetPostedDocumentLinesToReverse)
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Get Posted Doc&ument Lines to Reverse';
                    Ellipsis = true;
                    Image = ReverseLines;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Copy one or more posted sales document lines in order to reverse the original order.';

                    trigger OnAction()
                    begin
                        GetPstdDocLinesToReverse();
                        CurrPage.SalesLines.Page.SalesDocTotalsNotUpToDate();
                        CurrPage.SalesLines.Page.Update(false);
                    end;
                }
                action("Archive Document")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Archive Document';
                    Image = Archive;
                    ToolTip = 'Send the document to the archive, for example because it is too soon to delete it. Later, you delete or reprocess the archived document.';

                    trigger OnAction()
                    begin
                        ArchiveManagement.ArchiveSalesDocument(Rec);
                        CurrPage.Update(false);
                    end;
                }
                action("Send IC Return Order Cnfmn.")
                {
                    AccessByPermission = TableData "IC G/L Account" = R;
                    ApplicationArea = Intercompany;
                    Caption = 'Send IC Return Order Cnfmn.';
                    Image = IntercompanyOrder;
                    ToolTip = 'Prepare to send the return order confirmation to an intercompany partner.';

                    trigger OnAction()
                    var
                        ICInOutboxMgt: Codeunit ICInboxOutboxMgt;
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        if ApprovalsMgmt.PrePostApprovalCheckSales(Rec) then
                            ICInOutboxMgt.SendSalesDoc(Rec, false);
                    end;
                }
                separator(Action135)
                {
                }
                action(Post)
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'P&ost';
                    Ellipsis = true;
                    Image = PostOrder;
                    Promoted = true;
                    PromotedCategory = Category6;
                    PromotedIsBig = true;
                    ShortCutKey = 'F9';
                    ToolTip = 'Finalize the document or journal by posting the amounts and quantities to the related accounts in your company books.';

                    trigger OnAction()
                    begin
                        PostDocument(CODEUNIT::"Sales-Post (Yes/No)");
                    end;
                }
                action("Preview Posting")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Preview Posting';
                    Image = ViewPostedOrder;
                    Promoted = true;
                    PromotedCategory = Category6;
                    ToolTip = 'Review the different types of entries that will be created when you post the document or journal.';

                    trigger OnAction()
                    begin
                        ShowPreview;
                    end;
                }
                action(DocAttach)
                {
                    ApplicationArea = All;
                    Caption = 'Attachments';
                    Image = Attach;
                    Promoted = true;
                    PromotedCategory = Category11;
                    ToolTip = 'Add a file as an attachment. You can attach images as well as documents.';

                    trigger OnAction()
                    var
                        DocumentAttachmentDetails: Page "Document Attachment Details";
                        RecRef: RecordRef;
                    begin
                        RecRef.GetTable(Rec);
                        DocumentAttachmentDetails.OpenForRecRef(RecRef);
                        DocumentAttachmentDetails.RunModal;
                    end;
                }
            }
            group(Action13)
            {
                Caption = 'Warehouse';
                Image = Warehouse;
                separator(Action136)
                {
                }
                action("Create &Whse. Receipt")
                {
                    AccessByPermission = TableData "Warehouse Receipt Header" = R;
                    ApplicationArea = Warehouse;
                    Caption = 'Create &Whse. Receipt';
                    Image = NewReceipt;
                    ToolTip = 'Create a warehouse receipt to start a receive and put-away process according to an advanced warehouse configuration.';

                    trigger OnAction()
                    var
                        GetSourceDocInbound: Codeunit "Get Source Doc. Inbound";
                    begin
                        GetSourceDocInbound.CreateFromSalesReturnOrder(Rec);
                    end;
                }
                action("Create Inventor&y Put-away/Pick")
                {
                    AccessByPermission = TableData "Posted Invt. Put-away Header" = R;
                    ApplicationArea = Warehouse;
                    Caption = 'Create Inventor&y Put-away/Pick';
                    Ellipsis = true;
                    Image = CreateInventoryPickup;
                    ToolTip = 'Create an inventory put-away or inventory pick to handle items on the document according to a basic warehouse configuration that does not require warehouse receipt or shipment documents.';

                    trigger OnAction()
                    begin
                        CreateInvtPutAwayPick;
                    end;
                }
                separator(Action30)
                {
                }
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action("Test Report")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'View a test report so that you can find and correct any errors before you perform the actual posting of the journal or document.';

                    trigger OnAction()
                    begin
                        ReportPrint.PrintSalesHeader(Rec);
                    end;
                }
                action("Post &Batch")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Post &Batch';
                    Ellipsis = true;
                    Image = PostBatch;
                    Promoted = false;
                    //The property 'PromotedOnly' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedOnly = false;
                    ToolTip = 'Post several documents at once. A report request window opens where you can specify which documents to post.';

                    trigger OnAction()
                    begin
                        REPORT.RunModal(REPORT::"Batch Post Sales Return Orders", true, true, Rec);
                        CurrPage.Update(false);
                    end;
                }
                action("Remove From Job Queue")
                {
                    ApplicationArea = All;
                    Caption = 'Remove From Job Queue';
                    Image = RemoveLine;
                    ToolTip = 'Remove the scheduled processing of this record from the job queue.';
                    Visible = JobQueueVisible;

                    trigger OnAction()
                    begin
                        CancelBackgroundPosting;
                    end;
                }
            }
            group("Request Approval")
            {
                Caption = 'Request Approval';
                action(SendApprovalRequest)
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Send A&pproval Request';
                    Enabled = NOT OpenApprovalEntriesExist;
                    Image = SendApprovalRequest;
                    Promoted = true;
                    PromotedCategory = Category9;
                    PromotedIsBig = true;
                    ToolTip = 'Request approval of the document.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        if ApprovalsMgmt.CheckSalesApprovalPossible(Rec) then
                            ApprovalsMgmt.OnSendSalesDocForApproval(Rec);
                    end;
                }
                action(CancelApprovalRequest)
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Cancel Approval Re&quest';
                    Enabled = CanCancelApprovalForRecord;
                    Image = CancelApprovalRequest;
                    Promoted = true;
                    PromotedCategory = Category9;
                    ToolTip = 'Cancel the approval request.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.OnCancelSalesApprovalRequest(Rec);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        ShowWorkflowStatus := CurrPage.WorkflowStatus.PAGE.SetFilterOnWorkflowRecord(RecordId);
        CurrPage.ApprovalFactBox.PAGE.UpdateApprovalEntriesFromSourceRecord(RecordId);
        StatusStyleTxt := GetStatusStyleText();
    end;

    trigger OnAfterGetRecord()
    begin
        SetControlAppearance;
        if SellToContact.Get("Sell-to Contact No.") then;
        if BillToContact.Get("Bill-to Contact No.") then;
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        CurrPage.SaveRecord;
        exit(ConfirmDeletion);
    end;

    trigger OnInit()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        JobQueueUsed := SalesReceivablesSetup.JobQueueActive;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if DocNoVisible then
            CheckCreditMaxBeforeInsert;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        "Responsibility Center" := UserMgt.GetSalesFilter;
        if (not DocNoVisible) and ("No." = '') then
            SetSellToCustomerFromFilter;
    end;

    trigger OnOpenPage()
    begin
        if UserMgt.GetSalesFilter <> '' then begin
            FilterGroup(2);
            SetRange("Responsibility Center", UserMgt.GetSalesFilter);
            FilterGroup(0);
        end;

        ActivateFields;

        SetDocNoVisible;
        if ("No." <> '') and ("Sell-to Customer No." = '') then
            DocumentIsPosted := (not Get("Document Type", "No."));
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if not DocumentIsPosted then
            exit(ConfirmCloseUnposted);
    end;

    var
        SellToContact: Record Contact;
        BillToContact: Record Contact;
        MoveNegSalesLines: Report "Move Negative Sales Lines";
        CreateRetRelDocs: Report "Create Ret.-Related Documents";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        ReportPrint: Codeunit "Test Report-Print";
        DocPrint: Codeunit "Document-Print";
        UserMgt: Codeunit "User Setup Management";
        ArchiveManagement: Codeunit ArchiveManagement;
        SalesCalcDiscByType: Codeunit "Sales - Calc Discount By Type";
        FormatAddress: Codeunit "Format Address";
        ChangeExchangeRate: Page "Change Exchange Rate";
        [InDataSet]
        JobQueueVisible: Boolean;
        [InDataSet]
        JobQueueUsed: Boolean;
        [InDataSet]
        StatusStyleTxt: Text;
        DocNoVisible: Boolean;
        OpenApprovalEntriesExistForCurrUser: Boolean;
        OpenApprovalEntriesExist: Boolean;
        ShowWorkflowStatus: Boolean;
        CanCancelApprovalForRecord: Boolean;
        DocumentIsPosted: Boolean;
        OpenPostedSalesReturnOrderQst: Label 'The return order is posted as number %1 and moved to the Posted Sales Credit Memos window.\\Do you want to open the posted credit memo?', Comment = '%1 = posted document number';
        IsCustomerOrContactNotEmpty: Boolean;
        IsBillToCountyVisible: Boolean;
        IsSellToCountyVisible: Boolean;
        IsShipToCountyVisible: Boolean;

    local procedure ActivateFields()
    begin
        IsBillToCountyVisible := FormatAddress.UseCounty("Bill-to Country/Region Code");
        IsSellToCountyVisible := FormatAddress.UseCounty("Sell-to Country/Region Code");
        IsShipToCountyVisible := FormatAddress.UseCounty("Ship-to Country/Region Code");
    end;

    procedure CallPostDocument(PostingCodeunitID: Integer)
    begin
        PostDocument(PostingCodeunitID);
    end;

    local procedure PostDocument(PostingCodeunitID: Integer)
    var
        SalesHeader: Record "Sales Header";
        InstructionMgt: Codeunit "Instruction Mgt.";
        IsHandled: Boolean;
    begin
        SendToPosting(PostingCodeunitID);

        DocumentIsPosted := not SalesHeader.Get("Document Type", "No.");

        if "Job Queue Status" = "Job Queue Status"::"Scheduled for Posting" then
            CurrPage.Close;
        CurrPage.Update(false);

        IsHandled := false;
        OnPostDocumentBeforeNavigateAfterPosting(Rec, PostingCodeunitID, DocumentIsPosted, IsHandled);
        if IsHandled then
            exit;

        if PostingCodeunitID <> CODEUNIT::"Sales-Post (Yes/No)" then
            exit;

        if InstructionMgt.IsEnabled(InstructionMgt.ShowPostedConfirmationMessageCode) then
            ShowPostedConfirmationMessage;
    end;

    local procedure ApproveCalcInvDisc()
    begin
        CurrPage.SalesLines.PAGE.ApproveCalcInvDisc;
    end;

    local procedure SaveInvoiceDiscountAmount()
    var
        DocumentTotals: Codeunit "Document Totals";
    begin
        CurrPage.SaveRecord;
        DocumentTotals.SalesRedistributeInvoiceDiscountAmountsOnDocument(Rec);
        CurrPage.Update(false);
    end;

    local procedure SalespersonCodeOnAfterValidate()
    begin
        CurrPage.SalesLines.PAGE.UpdateForm(true);
    end;

    local procedure ShortcutDimension1CodeOnAfterV()
    begin
        CurrPage.SalesLines.PAGE.UpdateForm(true);
    end;

    local procedure ShortcutDimension2CodeOnAfterV()
    begin
        CurrPage.SalesLines.PAGE.UpdateForm(true);
    end;

    local procedure PricesIncludingVATOnAfterValid()
    begin
        CurrPage.SalesLines.Page.ForceTotalsCalculation();
        CurrPage.Update();
    end;

    local procedure SetDocNoVisible()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
        DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order",Reminder,FinChMemo;
    begin
        DocNoVisible := DocumentNoVisibility.SalesDocumentNoIsVisible(DocType::"Return Order", "No.");
    end;

    procedure ShowPreview()
    var
        SalesPostYesNo: Codeunit "Sales-Post (Yes/No)";
    begin
        SalesPostYesNo.Preview(Rec);
    end;

    local procedure SetControlAppearance()
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        JobQueueVisible := "Job Queue Status" = "Job Queue Status"::"Scheduled for Posting";

        OpenApprovalEntriesExistForCurrUser := ApprovalsMgmt.HasOpenApprovalEntriesForCurrentUser(RecordId);
        OpenApprovalEntriesExist := ApprovalsMgmt.HasOpenApprovalEntries(RecordId);
        CanCancelApprovalForRecord := ApprovalsMgmt.CanCancelApprovalForRecord(RecordId);
        IsCustomerOrContactNotEmpty := ("Sell-to Customer No." <> '') or ("Sell-to Contact No." <> '');
    end;

    local procedure ShowPostedConfirmationMessage()
    var
        ReturnOrderSalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        if not ReturnOrderSalesHeader.Get("Document Type", "No.") then begin
            SalesCrMemoHeader.SetRange("No.", "Last Posting No.");
            if SalesCrMemoHeader.FindFirst then
                if InstructionMgt.ShowConfirm(StrSubstNo(OpenPostedSalesReturnOrderQst, SalesCrMemoHeader."No."),
                     InstructionMgt.ShowPostedConfirmationMessageCode)
                then
                    PAGE.Run(PAGE::"Posted Sales Credit Memo", SalesCrMemoHeader);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeStatisticsAction(var SalesHeader: Record "Sales Header"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostDocumentBeforeNavigateAfterPosting(var SalesHeader: Record "Sales Header"; var PostingCodeunitID: Integer; DocumentIsPosted: Boolean; var IsHandled: Boolean)
    begin
    end;
}

