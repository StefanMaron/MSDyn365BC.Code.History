page 6640 "Purchase Return Order"
{
    Caption = 'Purchase Return Order';
    PageType = Document;
    PromotedActionCategories = 'New,Process,Report,Approve,Release,Posting,Prepare,Invoice,Request Approval,Print/Send,Return Order,Navigate';
    RefreshOnActivate = true;
    SourceTable = "Purchase Header";
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
                    ApplicationArea = PurchReturnOrder;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                    Visible = DocNoVisible;

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field("Buy-from Vendor No."; "Buy-from Vendor No.")
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Vendor No.';
                    Importance = Additional;
                    NotBlank = true;
                    ToolTip = 'Specifies the number of the vendor who returns the products.';

                    trigger OnValidate()
                    begin
                        OnAfterValidateBuyFromVendorNo(Rec, xRec);
                        CurrPage.Update();
                    end;
                }
                field("Buy-from Vendor Name"; "Buy-from Vendor Name")
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Vendor Name';
                    Importance = Promoted;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the name of the vendor who returns the products.';

                    trigger OnValidate()
                    begin
                        OnAfterValidateBuyFromVendorNo(Rec, xRec);

                        CurrPage.Update();
                    end;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(Rec.LookupBuyFromVendorName(Text));
                    end;
                }
                group("Buy-from")
                {
                    Caption = 'Buy-from';
                    field("Buy-from Address"; "Buy-from Address")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Address';
                        Importance = Additional;
                        ToolTip = 'Specifies the vendor''s buy-from address.';
                    }
                    field("Buy-from Address 2"; "Buy-from Address 2")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Address 2';
                        Importance = Additional;
                        ToolTip = 'Specifies an additional part of the vendor''s buy-from address.';
                    }
                    group(Control69)
                    {
                        ShowCaption = false;
                        Visible = IsBuyFromCountyVisible;
                        field("Buy-from County"; "Buy-from County")
                        {
                            ApplicationArea = PurchReturnOrder;
                            Caption = 'County';
                            Importance = Additional;
                            ToolTip = 'Specifies the county of the address.';
                        }
                    }
                    field("Buy-from Post Code"; "Buy-from Post Code")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Post Code';
                        Importance = Additional;
                        ToolTip = 'Specifies the postal code.';
                    }
                    field("Buy-from City"; "Buy-from City")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'City';
                        Importance = Additional;
                        ToolTip = 'Specifies the city of the vendor on the purchase document.';
                    }
                    field("Buy-from Country/Region Code"; "Buy-from Country/Region Code")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Country/Region';
                        Importance = Additional;
                        ToolTip = 'Specifies the country or region of the address.';

                        trigger OnValidate()
                        begin
                            IsBuyFromCountyVisible := FormatAddress.UseCounty("Buy-from Country/Region Code");
                        end;
                    }
                    field("Buy-from Contact No."; "Buy-from Contact No.")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Contact No.';
                        Importance = Additional;
                        ToolTip = 'Specifies the number of your contact at the vendor.';
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
                field("Buy-from Contact"; "Buy-from Contact")
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Contact';
                    Editable = "Buy-from Vendor No." <> '';
                    ToolTip = 'Specifies the name of the vendor contact person.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = PurchReturnOrder;
                    Importance = Additional;
                    ToolTip = 'Specifies the posting date of the record.';

                    trigger OnValidate()
                    begin
                        SaveInvoiceDiscountAmount;
                    end;
                }
                field("No. of Archived Versions"; "No. of Archived Versions")
                {
                    ApplicationArea = PurchReturnOrder;
                    Importance = Additional;
                    ToolTip = 'Specifies the number of archived versions for this document.';
                }
                field("Order Date"; "Order Date")
                {
                    ApplicationArea = PurchReturnOrder;
                    Importance = Additional;
                    ToolTip = 'Specifies the date when the order was created.';
                }
                field("Vendor Authorization No."; "Vendor Authorization No.")
                {
                    ApplicationArea = PurchReturnOrder;
                    Importance = Additional;
                    ToolTip = 'Specifies the identification number of a compensation agreement. This number is sometimes referred to as the RMA No.(Returns Materials Authorization).';
                }
                field("Vendor Cr. Memo No."; "Vendor Cr. Memo No.")
                {
                    ApplicationArea = PurchReturnOrder;
                    Importance = Promoted;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the number that the vendor uses for the credit memo you are creating in this purchase return order.';
                }
                field("Purchaser Code"; "Purchaser Code")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies which purchaser is assigned to the vendor.';

                    trigger OnValidate()
                    begin
                        PurchaserCodeOnAfterValidate;
                    end;
                }
                field("Campaign No."; "Campaign No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the campaign number the document is linked to.';
                }
                field("Responsibility Center"; "Responsibility Center")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the code of the responsibility center, such as a distribution hub, that is associated with the involved user, company, customer, or vendor.';
                }
                field("Assigned User ID"; "Assigned User ID")
                {
                    ApplicationArea = PurchReturnOrder;
                    Importance = Additional;
                    ToolTip = 'Specifies the ID of the user who is responsible for the document.';
                }
                field("Job Queue Status"; "Job Queue Status")
                {
                    ApplicationArea = All;
                    Importance = Additional;
                    ToolTip = 'Specifies the status of a job queue entry that handles the posting of purchase return orders.';
                    Visible = JobQueueUsed;
                }
                field(Status; Status)
                {
                    ApplicationArea = PurchReturnOrder;
                    Importance = Promoted;
                    StyleExpr = StatusStyleTxt;
                    ToolTip = 'Specifies whether the document is open, released, pending approval, or pending prepayment.';
                }
            }
            part(PurchLines; "Purchase Return Order Subform")
            {
                ApplicationArea = PurchReturnOrder;
                Editable = "Buy-from Vendor No." <> '';
                Enabled = "Buy-from Vendor No." <> '';
                SubPageLink = "Document No." = FIELD("No.");
                UpdatePropagation = Both;
            }
            group("Invoice Details")
            {
                Caption = 'Invoice Details';
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = PurchReturnOrder;
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
                        PurchCalcDiscByType.ApplyDefaultInvoiceDiscount(0, Rec);
                    end;
                }
                field("Expected Receipt Date"; "Expected Receipt Date")
                {
                    ApplicationArea = PurchReturnOrder;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date you expect the items to be available in your warehouse. If you leave the field blank, it will be calculated as follows: Planned Receipt Date + Safety Lead Time + Inbound Warehouse Handling Time = Expected Receipt Date.';
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
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    Importance = Promoted;
                    ToolTip = 'Specifies a code for the location where you want the items to be placed when they are received.';
                }
                field("Applies-to Doc. Type"; "Applies-to Doc. Type")
                {
                    ApplicationArea = PurchReturnOrder;
                    Importance = Promoted;
                    ToolTip = 'Specifies the type of the posted document that this document or journal line will be applied to when you post, for example to register payment.';
                }
                field("Applies-to Doc. No."; "Applies-to Doc. No.")
                {
                    ApplicationArea = PurchReturnOrder;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the posted document that this document or journal line will be applied to when you post, for example to register payment.';
                }
                field("Applies-to ID"; "Applies-to ID")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies the ID of entries that will be applied to when you choose the Apply Entries action.';
                }
                field("Tax Liable"; "Tax Liable")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies that purchases from the vendor on the purchase header are liable for sales tax.';
                }
                field("Tax Area Code"; "Tax Area Code")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies the tax area code used for this purchase to calculate and post sales tax.';

                    trigger OnValidate()
                    begin
                        CurrPage.PurchLines.PAGE.RedistributeTotalsOnAfterValidate;
                    end;
                }
            }
            group("Shipping and Payment")
            {
                Caption = 'Shipping and Payment';
                group(Control45)
                {
                    ShowCaption = false;
                    field(ShipToOptions; ShipToOptions)
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Ship-to';
                        OptionCaption = 'Default (Vendor Address),Alternate Vendor Address,Custom Address';
                        ToolTip = 'Specifies the address that the products on the purchase document are shipped to. Default (Company Address): The same as the company address specified in the Company Information window. Location: One of the company''s location addresses. Custom Address: Any ship-to address that you specify in the fields below.';

                        trigger OnValidate()
                        begin
                            ValidateShippingOption;
                        end;
                    }
                }
                group(Control48)
                {
                    ShowCaption = false;
                    Visible = ShipToOptions = ShipToOptions::"Alternate Vendor Address";
                    field("Order Address Code"; "Order Address Code")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Alternate Vendor Address Code';
                        ToolTip = 'Specifies the order address of the related vendor.';
                    }
                }
                group(Control62)
                {
                    ShowCaption = false;
                    field("Ship-to Name"; "Ship-to Name")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Name';
                        Editable = ShipToOptions = ShipToOptions::"Custom Address";
                        Importance = Additional;
                        ToolTip = 'Specifies the name of the vendor sending the order.';
                    }
                    field("Ship-to Address"; "Ship-to Address")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Address';
                        Editable = ShipToOptions = ShipToOptions::"Custom Address";
                        Importance = Additional;
                        ToolTip = 'Specifies the vendor''s buy-from address.';
                    }
                    field("Ship-to Address 2"; "Ship-to Address 2")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Address 2';
                        Editable = ShipToOptions = ShipToOptions::"Custom Address";
                        Importance = Additional;
                        ToolTip = 'Specifies an additional part of the vendor''s buy-from address.';
                    }
                    group(Control174)
                    {
                        ShowCaption = false;
                        Visible = IsShipToCountyVisible;
                        field("Ship-to County"; "Ship-to County")
                        {
                            ApplicationArea = PurchReturnOrder;
                            Caption = 'County';
                            Editable = ShipToOptions = ShipToOptions::"Custom Address";
                            Importance = Additional;
                            ToolTip = 'Specifies the county of the address.';
                        }
                    }
                    field("Ship-to Post Code"; "Ship-to Post Code")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Post Code';
                        Editable = ShipToOptions = ShipToOptions::"Custom Address";
                        Importance = Additional;
                        ToolTip = 'Specifies the postal code.';
                    }
                    field("Ship-to City"; "Ship-to City")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'City';
                        Editable = ShipToOptions = ShipToOptions::"Custom Address";
                        Importance = Additional;
                        ToolTip = 'Specifies the city of the vendor on the purchase document.';
                    }
                    field("Ship-to Country/Region Code"; "Ship-to Country/Region Code")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Country/Region Code';
                        Editable = ShipToOptions = ShipToOptions::"Custom Address";
                        Importance = Additional;
                        ToolTip = 'Specifies the country or region of the address.';

                        trigger OnValidate()
                        begin
                            IsShipToCountyVisible := FormatAddress.UseCounty("Ship-to Country/Region Code");
                        end;
                    }
                    field("Ship-to Contact"; "Ship-to Contact")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Contact';
                        Editable = ShipToOptions = ShipToOptions::"Custom Address";
                        Importance = Additional;
                        ToolTip = 'Specifies the name of the vendor contact person.';
                    }
                }
                group("Pay-to")
                {
                    Caption = 'Pay-to';
                    field("Pay-to Name"; "Pay-to Name")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Name';
                        Importance = Promoted;
                        ToolTip = 'Specifies the name of the vendor sending the order.';

                        trigger OnValidate()
                        begin
                            if GetFilter("Pay-to Vendor No.") = xRec."Pay-to Vendor No." then
                                if "Pay-to Vendor No." <> xRec."Pay-to Vendor No." then
                                    SetRange("Pay-to Vendor No.");

                            CurrPage.Update();
                        end;
                    }
                    field("Pay-to Address"; "Pay-to Address")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Address';
                        Editable = "Buy-from Vendor No." <> "Pay-to Vendor No.";
                        Enabled = "Buy-from Vendor No." <> "Pay-to Vendor No.";
                        Importance = Additional;
                        ToolTip = 'Specifies the vendor''s buy-from address.';
                    }
                    field("Pay-to Address 2"; "Pay-to Address 2")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Address 2';
                        Editable = "Buy-from Vendor No." <> "Pay-to Vendor No.";
                        Enabled = "Buy-from Vendor No." <> "Pay-to Vendor No.";
                        Importance = Additional;
                        ToolTip = 'Specifies an additional part of the vendor''s buy-from address.';
                    }
                    group(Control79)
                    {
                        ShowCaption = false;
                        Visible = IsPayToCountyVisible;
                        field("Pay-to County"; "Pay-to County")
                        {
                            ApplicationArea = PurchReturnOrder;
                            Caption = 'County';
                            Editable = "Buy-from Vendor No." <> "Pay-to Vendor No.";
                            Enabled = "Buy-from Vendor No." <> "Pay-to Vendor No.";
                            Importance = Additional;
                            ToolTip = 'Specifies the county of the address.';
                        }
                    }
                    field("Pay-to Post Code"; "Pay-to Post Code")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Post Code';
                        Editable = "Buy-from Vendor No." <> "Pay-to Vendor No.";
                        Enabled = "Buy-from Vendor No." <> "Pay-to Vendor No.";
                        Importance = Additional;
                        ToolTip = 'Specifies the postal code.';
                    }
                    field("Pay-to City"; "Pay-to City")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'City';
                        Editable = "Buy-from Vendor No." <> "Pay-to Vendor No.";
                        Enabled = "Buy-from Vendor No." <> "Pay-to Vendor No.";
                        Importance = Additional;
                        ToolTip = 'Specifies the city of the vendor on the purchase document.';
                    }
                    field("Pay-to Country/Region Code"; "Pay-to Country/Region Code")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Country/Region';
                        Editable = "Buy-from Vendor No." <> "Pay-to Vendor No.";
                        Enabled = "Buy-from Vendor No." <> "Pay-to Vendor No.";
                        Importance = Additional;
                        ToolTip = 'Specifies the country or region of the address.';

                        trigger OnValidate()
                        begin
                            IsPayToCountyVisible := FormatAddress.UseCounty("Pay-to Country/Region Code");
                        end;
                    }
                    field("Pay-to Contact No."; "Pay-to Contact No.")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Contact No.';
                        Enabled = "Buy-from Vendor No." <> "Pay-to Vendor No.";
                        Importance = Additional;
                        ToolTip = 'Specifies the number of the contact who sends the invoice.';
                        Visible = "Buy-from Vendor No." <> "Pay-to Vendor No.";
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
                    field("Pay-to Contact"; "Pay-to Contact")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Contact';
                        Editable = "Buy-from Vendor No." <> "Pay-to Vendor No.";
                        Enabled = "Buy-from Vendor No." <> "Pay-to Vendor No.";
                        Importance = Additional;
                        ToolTip = 'Specifies the name of the vendor contact person.';
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
        }
        area(factboxes)
        {
            part("Attached Documents"; "Document Attachment Factbox")
            {
                ApplicationArea = All;
                Caption = 'Attachments';
                SubPageLink = "Table ID" = CONST(38),
                              "No." = FIELD("No."),
                              "Document Type" = FIELD("Document Type");
            }
            part(Control21; "Pending Approval FactBox")
            {
                ApplicationArea = PurchReturnOrder;
                SubPageLink = "Table ID" = CONST(38),
                              "Document Type" = FIELD("Document Type"),
                              "Document No." = FIELD("No.");
                Visible = OpenApprovalEntriesExistForCurrUser;
            }
            part(ApprovalFactBox; "Approval FactBox")
            {
                ApplicationArea = PurchReturnOrder;
                Visible = false;
            }
            part(Control1901138007; "Vendor Details FactBox")
            {
                ApplicationArea = PurchReturnOrder;
                SubPageLink = "No." = FIELD("Buy-from Vendor No."),
                              "Date Filter" = field("Date Filter");
                Visible = false;
            }
            part(Control1904651607; "Vendor Statistics FactBox")
            {
                ApplicationArea = PurchReturnOrder;
                SubPageLink = "No." = FIELD("Pay-to Vendor No."),
                              "Date Filter" = field("Date Filter");
            }
            part(Control1903435607; "Vendor Hist. Buy-from FactBox")
            {
                ApplicationArea = PurchReturnOrder;
                SubPageLink = "No." = FIELD("Buy-from Vendor No."),
                              "Date Filter" = field("Date Filter");
            }
            part(Control1906949207; "Vendor Hist. Pay-to FactBox")
            {
                ApplicationArea = PurchReturnOrder;
                SubPageLink = "No." = FIELD("Pay-to Vendor No."),
                              "Date Filter" = field("Date Filter");
                Visible = false;
            }
            part(Control3; "Purchase Line FactBox")
            {
                ApplicationArea = PurchReturnOrder;
                Provider = PurchLines;
                SubPageLink = "Document Type" = FIELD("Document Type"),
                              "Document No." = FIELD("Document No."),
                              "Line No." = FIELD("Line No.");
            }
            part(WorkflowStatus; "Workflow Status FactBox")
            {
                ApplicationArea = PurchReturnOrder;
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
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Category11;
                    PromotedIsBig = true;
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';

                    trigger OnAction()
                    begin
                        OpenPurchaseOrderStatistics;
                        PurchCalcDiscByType.ResetRecalculateInvoiceDisc(Rec);
                    end;
                }
                action(Vendor)
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Vendor';
                    Enabled = "Buy-from Vendor No." <> '';
                    Image = Vendor;
                    Promoted = true;
                    PromotedCategory = Category12;
                    RunObject = Page "Vendor Card";
                    RunPageLink = "No." = FIELD("Buy-from Vendor No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or edit detailed information about the vendor on the purchase document.';
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
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Approvals';
                    Image = Approvals;
                    Promoted = true;
                    PromotedCategory = Category11;
                    ToolTip = 'View a list of the records that are waiting to be approved. For example, you can see who requested the record to be approved, when it was sent, and when it is due to be approved.';

                    trigger OnAction()
                    var
                        WorkflowsEntriesBuffer: Record "Workflows Entries Buffer";
                    begin
                        WorkflowsEntriesBuffer.RunWorkflowEntriesPage(
                            RecordId, DATABASE::"Purchase Header", "Document Type".AsInteger(), "No.");
                    end;
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    Promoted = true;
                    PromotedCategory = Category11;
                    RunObject = Page "Purch. Comment Sheet";
                    RunPageLink = "Document Type" = FIELD("Document Type"),
                                  "No." = FIELD("No."),
                                  "Document Line No." = CONST(0);
                    ToolTip = 'View or add comments for the record.';
                }
            }
            group(Documents)
            {
                Caption = 'Documents';
                Image = Documents;
                action("Return Shipments")
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Return Shipments';
                    Image = Shipment;
                    Promoted = true;
                    PromotedCategory = Category12;
                    RunObject = Page "Posted Return Shipments";
                    RunPageLink = "Return Order No." = FIELD("No.");
                    RunPageView = SORTING("Return Order No.");
                    ToolTip = 'Open the posted return shipments related to this order.';
                }
                action("Cred&it Memos")
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Cred&it Memos';
                    Image = CreditMemo;
                    Promoted = true;
                    PromotedCategory = Category12;
                    RunObject = Page "Posted Purchase Credit Memos";
                    RunPageLink = "Return Order No." = FIELD("No.");
                    RunPageView = SORTING("Return Order No.");
                    ToolTip = 'View a list of ongoing credit memos for the order.';
                }
                separator(Action136)
                {
                }
            }
            group(Warehouse)
            {
                Caption = 'Warehouse';
                Image = Warehouse;
                action("Warehouse Shipment Lines")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Warehouse Shipment Lines';
                    Image = ShipmentLines;
                    RunObject = Page "Whse. Shipment Lines";
                    RunPageLink = "Source Type" = CONST(39),
                                  "Source Subtype" = FIELD("Document Type"),
                                  "Source No." = FIELD("No.");
                    RunPageView = SORTING("Source Type", "Source Subtype", "Source No.", "Source Line No.");
                    ToolTip = 'View ongoing warehouse shipments for the document, in advanced warehouse configurations.';
                }
                action("In&vt. Put-away/Pick Lines")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'In&vt. Put-away/Pick Lines';
                    Image = PickLines;
                    RunObject = Page "Warehouse Activity List";
                    RunPageLink = "Source Document" = CONST("Purchase Return Order"),
                                  "Source No." = FIELD("No.");
                    RunPageView = SORTING("Source Document", "Source No.", "Location Code");
                    ToolTip = 'View items that are inbound or outbound on inventory put-away or inventory pick documents for the transfer order.';
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
                    ApplicationArea = PurchReturnOrder;
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
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Reject';
                    Image = Reject;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Reject the requested changes.';
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
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Delegate';
                    Image = Delegate;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedOnly = true;
                    ToolTip = 'Delegate the requested changes to the substitute approver.';
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
                    ApplicationArea = PurchReturnOrder;
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
                ApplicationArea = PurchReturnOrder;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                Promoted = true;
                PromotedCategory = Category10;
                ToolTip = 'Prepare to print the document. The report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                begin
                    DocPrint.PrintPurchHeader(Rec);
                end;
            }
            action(AttachAsPDF)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Attach as PDF';
                Image = PrintAttachment;
                Promoted = true;
                PromotedCategory = Category10;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Create a PDF file and attach it to the document.';

                trigger OnAction()
                var
                    PurchaseHeader: Record "Purchase Header";
                begin
                    PurchaseHeader := Rec;
                    PurchaseHeader.SetRecFilter();
                    DocPrint.PrintPurchaseHeaderToDocumentAttachment(PurchaseHeader);
                end;
            }
            group(Release)
            {
                Caption = 'Release';
                Image = ReleaseDoc;
                action("Re&lease")
                {
                    ApplicationArea = PurchReturnOrder;
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
                        ReleasePurchDoc: Codeunit "Release Purchase Document";
                    begin
                        ReleasePurchDoc.PerformManualRelease(Rec);
                    end;
                }
                action(Reopen)
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Re&open';
                    Enabled = Status <> Status::Open;
                    Image = ReOpen;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedOnly = true;
                    ToolTip = 'Reopen the document to change it after it has been approved. Approved documents have the Released status and must be opened before they can be changed';

                    trigger OnAction()
                    var
                        ReleasePurchDoc: Codeunit "Release Purchase Document";
                    begin
                        ReleasePurchDoc.PerformManualReopen(Rec);
                    end;
                }
                separator(Action690)
                {
                }
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(GetPostedDocumentLinesToReverse)
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Get Posted Doc&ument Lines to Reverse';
                    Ellipsis = true;
                    Image = ReverseLines;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Copy one or more posted purchase document lines in order to reverse the original order.';

                    trigger OnAction()
                    begin
                        GetPstdDocLinesToReverse();
                        CurrPage.PurchLines.Page.PurchaseDocTotalsNotUpToDate();
                        CurrPage.PurchLines.Page.Update(false);
                    end;
                }
                action("Apply Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Apply Entries';
                    Image = ApplyEntries;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedOnly = true;
                    ShortCutKey = 'Shift+F11';
                    ToolTip = 'Apply open entries for the relevant account type.';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Purchase Header Apply", Rec);
                    end;
                }
                separator(Action130)
                {
                }
                action(CalculateInvoiceDiscount)
                {
                    AccessByPermission = TableData "Vendor Invoice Disc." = R;
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Calculate &Invoice Discount';
                    Image = CalculateInvoiceDiscount;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedOnly = true;
                    ToolTip = 'Calculate the discount that can be granted based on all lines in the purchase document.';

                    trigger OnAction()
                    begin
                        ApproveCalcInvDisc;
                        PurchCalcDiscByType.ResetRecalculateInvoiceDisc(Rec);
                    end;
                }
                separator(Action132)
                {
                }
                action(CopyDocument)
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Copy Document';
                    Ellipsis = true;
                    Enabled = "No." <> '';
                    Image = CopyDocument;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Process;
                    ToolTip = 'Copy document lines and header information from another purchase document to this document. You can copy a posted purchase invoice into a new purchase invoice to quickly create a similar document.';

                    trigger OnAction()
                    begin
                        CopyDocument();
                        if Get("Document Type", "No.") then;
                    end;
                }
                action("Move Negative Lines")
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Move Negative Lines';
                    Ellipsis = true;
                    Image = MoveNegativeLines;
                    ToolTip = 'Prepare to create a replacement sales order in a sales return process.';

                    trigger OnAction()
                    begin
                        Clear(MoveNegPurchLines);
                        MoveNegPurchLines.SetPurchHeader(Rec);
                        MoveNegPurchLines.RunModal;
                        MoveNegPurchLines.ShowDocument;
                    end;
                }
                action("Archive Document")
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Archive Document';
                    Image = Archive;
                    ToolTip = 'Send the document to the archive, for example because it is too soon to delete it. Later, you delete or reprocess the archived document.';

                    trigger OnAction()
                    begin
                        ArchiveManagement.ArchivePurchDocument(Rec);
                        CurrPage.Update(false);
                    end;
                }
                action("Send IC Return Order")
                {
                    AccessByPermission = TableData "IC G/L Account" = R;
                    ApplicationArea = Intercompany;
                    Caption = 'Send IC Return Order';
                    Image = IntercompanyOrder;
                    ToolTip = 'Prepare to send the return order to an intercompany partner.';

                    trigger OnAction()
                    var
                        ICInOutMgt: Codeunit ICInboxOutboxMgt;
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        if ApprovalsMgmt.PrePostApprovalCheckPurch(Rec) then
                            ICInOutMgt.SendPurchDoc(Rec, false);
                    end;
                }
                separator(Action134)
                {
                }
            }
            group("Request Approval")
            {
                Caption = 'Request Approval';
                Image = Approval;
                action(SendApprovalRequest)
                {
                    ApplicationArea = PurchReturnOrder;
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
                        if ApprovalsMgmt.CheckPurchaseApprovalPossible(Rec) then
                            ApprovalsMgmt.OnSendPurchaseDocForApproval(Rec);
                    end;
                }
                action(CancelApprovalRequest)
                {
                    ApplicationArea = PurchReturnOrder;
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
                        ApprovalsMgmt.OnCancelPurchaseApprovalRequest(Rec);
                    end;
                }
                separator(Action137)
                {
                }
            }
            group(Action19)
            {
                Caption = 'Warehouse';
                Image = Warehouse;
                action("Create &Warehouse Shipment")
                {
                    AccessByPermission = TableData "Warehouse Shipment Header" = R;
                    ApplicationArea = Warehouse;
                    Caption = 'Create &Warehouse Shipment';
                    Image = NewShipment;
                    ToolTip = 'Create a warehouse shipment to start a pick a ship process according to an advanced warehouse configuration.';

                    trigger OnAction()
                    var
                        GetSourceDocOutbound: Codeunit "Get Source Doc. Outbound";
                    begin
                        GetSourceDocOutbound.CreateFromPurchaseReturnOrder(Rec);
                    end;
                }
                action("Create Inventor&y Put-away/Pick")
                {
                    AccessByPermission = TableData "Posted Invt. Pick Header" = R;
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
                separator(Action135)
                {
                }
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action(Post)
                {
                    ApplicationArea = PurchReturnOrder;
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
                        PostDocument(CODEUNIT::"Purch.-Post (Yes/No)");
                    end;
                }
                action(Preview)
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Preview Posting';
                    Image = ViewPostedOrder;
                    Promoted = true;
                    PromotedCategory = Category6;
                    ToolTip = 'Review the different types of entries that will be created when you post the document or journal.';

                    trigger OnAction()
                    var
                        PurchPostYesNo: Codeunit "Purch.-Post (Yes/No)";
                    begin
                        PurchPostYesNo.Preview(Rec);
                    end;
                }
                action(TestReport)
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'View a test report so that you can find and correct any errors before you perform the actual posting of the journal or document.';

                    trigger OnAction()
                    begin
                        ReportPrint.PrintPurchHeader(Rec);
                    end;
                }
                action(PostAndPrint)
                {
                    ApplicationArea = PurchReturnOrder;
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
                        PostDocument(CODEUNIT::"Purch.-Post + Print");
                    end;
                }
                action(PostBatch)
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Post &Batch';
                    Ellipsis = true;
                    Image = PostBatch;
                    Promoted = true;
                    PromotedCategory = Category6;
                    PromotedOnly = true;
                    ToolTip = 'Post several documents at once. A report request window opens where you can specify which documents to post.';

                    trigger OnAction()
                    begin
                        REPORT.RunModal(REPORT::"Batch Post Purch. Ret. Orders", true, true, Rec);
                        CurrPage.Update(false);
                    end;
                }
                action(RemoveFromJobQueue)
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
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        SetControlAppearance;
        CurrPage.ApprovalFactBox.PAGE.UpdateApprovalEntriesFromSourceRecord(RecordId);
        ShowWorkflowStatus := CurrPage.WorkflowStatus.PAGE.SetFilterOnWorkflowRecord(RecordId);
        StatusStyleTxt := GetStatusStyleText();
    end;

    trigger OnAfterGetRecord()
    begin
        CalculateCurrentShippingOption;
        if BuyFromContact.Get("Buy-from Contact No.") then;
        if PayToContact.Get("Pay-to Contact No.") then;
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        CurrPage.SaveRecord;
        exit(ConfirmDeletion);
    end;

    trigger OnInit()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        JobQueueUsed := PurchasesPayablesSetup.JobQueueActive;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        "Responsibility Center" := UserMgt.GetPurchasesFilter;
        if (not DocNoVisible) and ("No." = '') then
            SetBuyFromVendorFromFilter;
    end;

    trigger OnOpenPage()
    begin
        SetDocNoVisible;

        if UserMgt.GetPurchasesFilter <> '' then begin
            FilterGroup(2);
            SetRange("Responsibility Center", UserMgt.GetPurchasesFilter);
            FilterGroup(0);
        end;
        if ("No." <> '') and ("Buy-from Vendor No." = '') then
            DocumentIsPosted := (not Get("Document Type", "No."));

        ActivateFields;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if not DocumentIsPosted then
            exit(ConfirmCloseUnposted);
    end;

    var
        BuyFromContact: Record Contact;
        PayToContact: Record Contact;
        MoveNegPurchLines: Report "Move Negative Purchase Lines";
        DocPrint: Codeunit "Document-Print";
        ReportPrint: Codeunit "Test Report-Print";
        UserMgt: Codeunit "User Setup Management";
        ArchiveManagement: Codeunit ArchiveManagement;
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        FormatAddress: Codeunit "Format Address";
        ChangeExchangeRate: Page "Change Exchange Rate";
        [InDataSet]
        JobQueueVisible: Boolean;
        [InDataSet]
        JobQueueUsed: Boolean;
        [InDataSet]
        StatusStyleTxt: Text;
        DocNoVisible: Boolean;
        OpenApprovalEntriesExist: Boolean;
        OpenApprovalEntriesExistForCurrUser: Boolean;
        ShowWorkflowStatus: Boolean;
        CanCancelApprovalForRecord: Boolean;
        DocumentIsPosted: Boolean;
        OpenPostedPurchaseReturnOrderQst: Label 'The return order is posted as number %1 and moved to the Posted Purchase Credit Memos window.\\Do you want to open the posted credit memo?', Comment = '%1 = posted document number';
        IsBuyFromCountyVisible: Boolean;
        IsPayToCountyVisible: Boolean;
        IsShipToCountyVisible: Boolean;

    protected var
        ShipToOptions: Option "Default (Vendor Address)","Alternate Vendor Address","Custom Address";

    local procedure ActivateFields()
    begin
        IsBuyFromCountyVisible := FormatAddress.UseCounty("Buy-from Country/Region Code");
        IsPayToCountyVisible := FormatAddress.UseCounty("Pay-to Country/Region Code");
        IsShipToCountyVisible := FormatAddress.UseCounty("Ship-to Country/Region Code");
    end;

    procedure CallPostDocument(PostingCodeunitID: Integer)
    begin
        PostDocument(PostingCodeunitID);
    end;

    local procedure PostDocument(PostingCodeunitID: Integer)
    var
        PurchaseHeader: Record "Purchase Header";
        InstructionMgt: Codeunit "Instruction Mgt.";
        IsHandled: Boolean;
    begin
        SendToPosting(PostingCodeunitID);

        DocumentIsPosted := not PurchaseHeader.Get("Document Type", "No.");

        if "Job Queue Status" = "Job Queue Status"::"Scheduled for Posting" then
            CurrPage.Close;
        CurrPage.Update(false);

        IsHandled := false;
        OnPostDocumentBeforeNavigateAfterPosting(Rec, PostingCodeunitID, DocumentIsPosted, IsHandled);
        if IsHandled then
            exit;

        if PostingCodeunitID <> CODEUNIT::"Purch.-Post (Yes/No)" then
            exit;

        if InstructionMgt.IsEnabled(InstructionMgt.ShowPostedConfirmationMessageCode) then
            ShowPostedConfirmationMessage;
    end;

    local procedure ApproveCalcInvDisc()
    begin
        CurrPage.PurchLines.PAGE.ApproveCalcInvDisc;
    end;

    local procedure SaveInvoiceDiscountAmount()
    var
        DocumentTotals: Codeunit "Document Totals";
    begin
        CurrPage.SaveRecord;
        DocumentTotals.PurchaseRedistributeInvoiceDiscountAmountsOnDocument(Rec);
        CurrPage.Update(false);
    end;

    local procedure PurchaserCodeOnAfterValidate()
    begin
        CurrPage.PurchLines.PAGE.UpdateForm(true);
    end;

    local procedure ShortcutDimension1CodeOnAfterV()
    begin
        CurrPage.PurchLines.PAGE.UpdateForm(true);
    end;

    local procedure ShortcutDimension2CodeOnAfterV()
    begin
        CurrPage.PurchLines.PAGE.UpdateForm(true);
    end;

    local procedure PricesIncludingVATOnAfterValid()
    begin
        CurrPage.PurchLines.Page.ForceTotalsCalculation();
        CurrPage.Update();
    end;

    local procedure SetDocNoVisible()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
        DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order",Reminder,FinChMemo;
    begin
        DocNoVisible := DocumentNoVisibility.PurchaseDocumentNoIsVisible(DocType::"Return Order", "No.");
    end;

    local procedure SetControlAppearance()
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        JobQueueVisible := "Job Queue Status" = "Job Queue Status"::"Scheduled for Posting";

        OpenApprovalEntriesExistForCurrUser := ApprovalsMgmt.HasOpenApprovalEntriesForCurrentUser(RecordId);
        OpenApprovalEntriesExist := ApprovalsMgmt.HasOpenApprovalEntries(RecordId);
        CanCancelApprovalForRecord := ApprovalsMgmt.CanCancelApprovalForRecord(RecordId);
    end;

    local procedure ShowPostedConfirmationMessage()
    var
        ReturnOrderPurchaseHeader: Record "Purchase Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        if not ReturnOrderPurchaseHeader.Get("Document Type", "No.") then begin
            PurchCrMemoHdr.SetRange("No.", "Last Posting No.");
            if PurchCrMemoHdr.FindFirst then
                if InstructionMgt.ShowConfirm(StrSubstNo(OpenPostedPurchaseReturnOrderQst, PurchCrMemoHdr."No."),
                     InstructionMgt.ShowPostedConfirmationMessageCode)
                then
                    PAGE.Run(PAGE::"Posted Purchase Credit Memo", PurchCrMemoHdr);
        end;
    end;

    local procedure ValidateShippingOption()
    begin
        OnBeforeValidateShipToOptions(Rec, ShipToOptions);

        case ShipToOptions of
            ShipToOptions::"Default (Vendor Address)":
                begin
                    Validate("Order Address Code", '');
                    Validate("Buy-from Vendor No.");
                end;
            ShipToOptions::"Alternate Vendor Address":
                Validate("Order Address Code", '');
        end;

        OnAfterValidateShipToOptions(Rec, ShipToOptions);
    end;

    local procedure CalculateCurrentShippingOption()
    begin
        case true of
            "Order Address Code" <> '':
                ShipToOptions := ShipToOptions::"Alternate Vendor Address";
            BuyFromAddressEqualsShipToAddress:
                ShipToOptions := ShipToOptions::"Default (Vendor Address)";
            else
                ShipToOptions := ShipToOptions::"Custom Address";
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShipToOptions(var PurchaseHeader: Record "Purchase Header"; ShipToOptions: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShipToOptions(var PurchaseHeader: Record "Purchase Header"; ShipToOptions: Option)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostDocumentBeforeNavigateAfterPosting(var PurchaseHeader: Record "Purchase Header"; var PostingCodeunitID: Integer; DocumentIsPosted: Boolean; var IsHandled: Boolean)
    begin
    end;
}

