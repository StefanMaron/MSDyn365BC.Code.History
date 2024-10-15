page 507 "Blanket Sales Order"
{
    Caption = 'Blanket Sales Order';
    PageType = Document;
    PromotedActionCategories = 'New,Process,Report,Approve,Request Approval,Print/Send,Release,Order';
    RefreshOnActivate = true;
    SourceTable = "Sales Header";
    SourceTableView = WHERE("Document Type" = FILTER("Blanket Order"));

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = Suite;
                    Importance = Standard;
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
                    ApplicationArea = Suite;
                    Caption = 'Customer No.';
                    Importance = Additional;
                    NotBlank = true;
                    ToolTip = 'Specifies the number of the customer who will receive the products and be billed by default.';

                    trigger OnValidate()
                    begin
                        SelltoCustomerNoOnAfterValidate(Rec, xRec);
                        CurrPage.Update();
                    end;
                }
                field("Sell-to Customer Name"; "Sell-to Customer Name")
                {
                    ApplicationArea = Suite;
                    Caption = 'Customer Name';
                    Importance = Promoted;
                    ToolTip = 'Specifies the name of the customer who will receive the products and be billed by default.';

                    trigger OnValidate()
                    begin
                        SelltoCustomerNoOnAfterValidate(Rec, xRec);

                        CurrPage.Update();
                    end;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        if LookupSellToCustomerName() then
                            CurrPage.Update();
                    end;
                }
                group("Sell-to")
                {
                    Caption = 'Sell-to';
                    field("Sell-to Address"; "Sell-to Address")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Address';
                        Importance = Additional;
                        QuickEntry = false;
                        ToolTip = 'Specifies the customer''s address.';
                    }
                    field("Sell-to Address 2"; "Sell-to Address 2")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Address 2';
                        Importance = Additional;
                        QuickEntry = false;
                        ToolTip = 'Specifies an additional part of the customer''s address.';
                    }
                    field("Sell-to Post Code"; "Sell-to Post Code")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Post Code';
                        Importance = Additional;
                        QuickEntry = false;
                        ToolTip = 'Specifies the postal code of the customer''s address.';
                    }
                    field("Sell-to City"; "Sell-to City")
                    {
                        ApplicationArea = Suite;
                        Caption = 'City';
                        Importance = Additional;
                        QuickEntry = false;
                        ToolTip = 'Specifies the city of the customer''s address.';
                    }
                    field("Sell-to Contact No."; "Sell-to Contact No.")
                    {
                        ApplicationArea = Suite;
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
                    ApplicationArea = Suite;
                    Caption = 'Contact';
                    Editable = "Sell-to Customer No." <> '';
                    ToolTip = 'Specifies the name of the contact person at the customer.';
                }
                field("No. of Archived Versions"; "No. of Archived Versions")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of archived versions for this document.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies when the related sales invoice must be paid.';
                }
                field("Order Date"; "Order Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date when the order was created.';
                }
                field("External Document No."; "External Document No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
                }
                field("Your Reference"; "Your Reference")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the customer''s reference. The content will be printed on sales documents.';
                }
                field("Salesperson Code"; "Salesperson Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the name of the salesperson who is assigned to the customer.';

                    trigger OnValidate()
                    begin
                        SalespersonCodeOnAfterValidate;
                    end;
                }
                field("Campaign No."; "Campaign No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the campaign that the document is linked to.';
                }
                field("Responsibility Center"; "Responsibility Center")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code of the responsibility center, such as a distribution hub, that is associated with the involved user, company, customer, or vendor.';
                }
                field("Assigned User ID"; "Assigned User ID")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the ID of the user who is responsible for the document.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                    StyleExpr = StatusStyleTxt;
                    ToolTip = 'Specifies whether the document is open, waiting to be approved, has been invoiced for prepayment, or has been released to the next stage of processing.';
                }
            }
            part(SalesLines; "Blanket Sales Order Subform")
            {
                ApplicationArea = Suite;
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
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the currency that is used on the entry.';

                    trigger OnAssistEdit()
                    begin
                        Clear(ChangeExchangeRate);
                        ChangeExchangeRate.SetParameter("Currency Code", "Currency Factor", WorkDate);
                        if ChangeExchangeRate.RunModal = ACTION::OK then begin
                            Validate("Currency Factor", ChangeExchangeRate.GetParameter);
                            SaveInvoiceDiscountAmount;
                        end;
                        Clear(ChangeExchangeRate);
                    end;

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                        SalesCalcDiscByType.ApplyDefaultInvoiceDiscount(0, Rec);
                    end;
                }
                field("Shipment Date"; "Shipment Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';
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
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a formula that calculates the payment due date, payment discount date, and payment discount amount.';
                }
                field("Payment Method Code"; "Payment Method Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how to make payment, such as with bank transfer, cash, or check.';
                }
                field("Transaction Type"; "Transaction Type")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the type of transaction that the document represents, for the purpose of reporting to INTRASTAT.';
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
                field("Pmt. Discount Date"; "Pmt. Discount Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date on which the amount in the entry must be paid for a payment discount to be granted.';
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

                    trigger OnValidate()
                    begin
                        CurrPage.SalesLines.PAGE.RedistributeTotalsOnAfterValidate;
                    end;
                }
                field("Payment Discount %"; "Payment Discount %")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the payment discount percentage that is granted if the customer pays on or before the date entered in the Pmt. Discount Date field. The discount percentage is specified in the Payment Terms Code field.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the location from where inventory items to the customer on the sales document are to be shipped by default.';
                }
            }
            group("Shipping and Billing")
            {
                Caption = 'Shipping and Billing';
                Enabled = "Sell-to Customer No." <> '';
                group(Control25)
                {
                    ShowCaption = false;
                    group(Control21)
                    {
                        ShowCaption = false;
                        field(ShippingOptions; ShipToOptions)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Ship-to';
                            OptionCaption = 'Default (Sell-to Address),Alternate Shipping Address,Custom Address';
                            ToolTip = 'Specifies the address that the products on the sales document are shipped to. Default (Sell-to Address): The same as the customer''s sell-to address. Alternate Ship-to Address: One of the customer''s alternate ship-to addresses. Custom Address: Any ship-to address that you specify in the fields below.';

                            trigger OnValidate()
                            var
                                ShipToAddress: Record "Ship-to Address";
                                ShipToAddressList: Page "Ship-to Address List";
                            begin
                                OnBeforeValidateShipToOptions(Rec, ShipToOptions);

                                case ShipToOptions of
                                    ShipToOptions::"Default (Sell-to Address)":
                                        begin
                                            Validate("Ship-to Code", '');
                                            CopySellToAddressToShipToAddress;
                                        end;
                                    ShipToOptions::"Alternate Shipping Address":
                                        begin
                                            ShipToAddress.SetRange("Customer No.", "Sell-to Customer No.");
                                            ShipToAddressList.LookupMode := true;
                                            ShipToAddressList.SetTableView(ShipToAddress);

                                            if ShipToAddressList.RunModal = ACTION::LookupOK then begin
                                                ShipToAddressList.GetRecord(ShipToAddress);
                                                Validate("Ship-to Code", ShipToAddress.Code);
                                            end else
                                                ShipToOptions := ShipToOptions::"Custom Address";
                                        end;
                                    ShipToOptions::"Custom Address":
                                        Validate("Ship-to Code", '');
                                end;

                                OnAfterValidateShipToOptions(Rec, ShipToOptions);
                            end;
                        }
                        group(Control4)
                        {
                            ShowCaption = false;
                            Visible = NOT (ShipToOptions = ShipToOptions::"Default (Sell-to Address)");
                            field("Ship-to Code"; "Ship-to Code")
                            {
                                ApplicationArea = Suite;
                                Caption = 'Code';
                                Editable = ShipToOptions = ShipToOptions::"Alternate Shipping Address";
                                Importance = Promoted;
                                ToolTip = 'Specifies the code for another shipment address than the customer''s own address, which is entered by default.';

                                trigger OnValidate()
                                begin
                                    if (xRec."Ship-to Code" <> '') and ("Ship-to Code" = '') then
                                        Error(EmptyShipToCodeErr);
                                end;
                            }
                            field("Ship-to Name"; "Ship-to Name")
                            {
                                ApplicationArea = Suite;
                                Caption = 'Name';
                                Editable = ShipToOptions = ShipToOptions::"Custom Address";
                                ToolTip = 'Specifies the name that products on the sales document will be shipped to.';
                            }
                            field("Ship-to Address"; "Ship-to Address")
                            {
                                ApplicationArea = Suite;
                                Caption = 'Address';
                                Editable = ShipToOptions = ShipToOptions::"Custom Address";
                                QuickEntry = false;
                                ToolTip = 'Specifies the address that products on the sales document will be shipped to. By default, the field is filled with the value in the Address field on the customer card or with the value in the Address field in the Ship-to Address window.';
                            }
                            field("Ship-to Address 2"; "Ship-to Address 2")
                            {
                                ApplicationArea = Suite;
                                Caption = 'Address 2';
                                Editable = ShipToOptions = ShipToOptions::"Custom Address";
                                QuickEntry = false;
                                ToolTip = 'Specifies an additional part of the shipping address.';
                            }
                            field("Ship-to Post Code"; "Ship-to Post Code")
                            {
                                ApplicationArea = Suite;
                                Caption = 'Post Code';
                                Editable = ShipToOptions = ShipToOptions::"Custom Address";
                                QuickEntry = false;
                                ToolTip = 'Specifies the postal code of the shipping address.';
                            }
                            field("Ship-to City"; "Ship-to City")
                            {
                                ApplicationArea = Suite;
                                Caption = 'City';
                                Editable = ShipToOptions = ShipToOptions::"Custom Address";
                                QuickEntry = false;
                                ToolTip = 'Specifies the city of the shipping address.';
                            }
                            field("Ship-to Country/Region Code"; "Ship-to Country/Region Code")
                            {
                                ApplicationArea = Suite;
                                Caption = 'Country/Region';
                                Editable = ShipToOptions = ShipToOptions::"Custom Address";
                                Importance = Additional;
                                QuickEntry = false;
                                ToolTip = 'Specifies the country/region of the shipping address.';
                            }
                        }
                        field("Ship-to Contact"; "Ship-to Contact")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Contact';
                            ToolTip = 'Specifies the name of the contact person at the address that products on the sales document will be shipped to.';
                        }
                    }
                    group("Shipment Method")
                    {
                        Caption = 'Shipment Method';
                        field("Shipment Method Code"; "Shipment Method Code")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Code';
                            Importance = Additional;
                            ToolTip = 'Specifies how items on the sales document are shipped to the customer.';
                        }
                        field("Shipping Agent Code"; "Shipping Agent Code")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Agent';
                            Importance = Additional;
                            ToolTip = 'Specifies which shipping agent is used to transport the items on the sales document to the customer.';
                        }
                        field("Shipping Agent Service Code"; "Shipping Agent Service Code")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Agent service';
                            Importance = Additional;
                            ToolTip = 'Specifies which shipping agent service is used to transport the items on the sales document to the customer.';
                        }
                        field("Package Tracking No."; "Package Tracking No.")
                        {
                            ApplicationArea = Suite;
                            Importance = Additional;
                            ToolTip = 'Specifies the shipping agent''s package number.';
                        }
                    }
                }
                group(Control41)
                {
                    ShowCaption = false;
                    field(BillToOptions; BillToOptions)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Bill-to';
                        OptionCaption = 'Default (Customer),Another Customer,Custom Address';
                        ToolTip = 'Specifies the customer that the sales invoice will be sent to. Default (Customer): The same as the customer on the sales invoice. Another Customer: Any customer that you specify in the fields below.';

                        trigger OnValidate()
                        begin
                            if BillToOptions = BillToOptions::"Default (Customer)" then begin
                                Validate("Bill-to Customer No.", "Sell-to Customer No.");
                                RecallModifyAddressNotification(GetModifyBillToCustomerAddressNotificationId);
                            end;

                            CopySellToAddressToBillToAddress;
                        end;
                    }
                    group(Control43)
                    {
                        ShowCaption = false;
                        Visible = NOT (BillToOptions = BillToOptions::"Default (Customer)");
                        field("Bill-to Name"; "Bill-to Name")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Name';
                            Editable = BillToOptions = BillToOptions::"Another Customer";
                            Enabled = BillToOptions = BillToOptions::"Another Customer";
                            Importance = Promoted;
                            ToolTip = 'Specifies the customer to whom you will send the invoice, when different from the customer that you are selling to.';

                            trigger OnValidate()
                            var
                                ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
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
                            ApplicationArea = Suite;
                            Caption = 'Address';
                            Editable = (BillToOptions = BillToOptions::"Custom Address") OR ("Bill-to Customer No." <> "Sell-to Customer No.");
                            Enabled = (BillToOptions = BillToOptions::"Custom Address") OR ("Bill-to Customer No." <> "Sell-to Customer No.");
                            Importance = Additional;
                            QuickEntry = false;
                            ToolTip = 'Specifies the address of the customer that you will send the invoice to.';
                        }
                        field("Bill-to Address 2"; "Bill-to Address 2")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Address 2';
                            Editable = (BillToOptions = BillToOptions::"Custom Address") OR ("Bill-to Customer No." <> "Sell-to Customer No.");
                            Enabled = (BillToOptions = BillToOptions::"Custom Address") OR ("Bill-to Customer No." <> "Sell-to Customer No.");
                            Importance = Additional;
                            QuickEntry = false;
                            ToolTip = 'Specifies an additional part of the billing address.';
                        }
                        field("Bill-to Post Code"; "Bill-to Post Code")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Post Code';
                            Editable = (BillToOptions = BillToOptions::"Custom Address") OR ("Bill-to Customer No." <> "Sell-to Customer No.");
                            Enabled = (BillToOptions = BillToOptions::"Custom Address") OR ("Bill-to Customer No." <> "Sell-to Customer No.");
                            Importance = Additional;
                            QuickEntry = false;
                            ToolTip = 'Specifies the postal code of the billing address.';
                        }
                        field("Bill-to City"; "Bill-to City")
                        {
                            ApplicationArea = Suite;
                            Caption = 'City';
                            Editable = (BillToOptions = BillToOptions::"Custom Address") OR ("Bill-to Customer No." <> "Sell-to Customer No.");
                            Enabled = (BillToOptions = BillToOptions::"Custom Address") OR ("Bill-to Customer No." <> "Sell-to Customer No.");
                            Importance = Additional;
                            QuickEntry = false;
                            ToolTip = 'Specifies the city of the billing address.';
                        }
                        field("Bill-to Contact No."; "Bill-to Contact No.")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Contact No.';
                            Editable = (BillToOptions = BillToOptions::"Custom Address") OR ("Bill-to Customer No." <> "Sell-to Customer No.");
                            Enabled = (BillToOptions = BillToOptions::"Custom Address") OR ("Bill-to Customer No." <> "Sell-to Customer No.");
                            Importance = Additional;
                            ToolTip = 'Specifies the number of the contact person at the billing address.';
                        }
                        field("Bill-to Contact"; "Bill-to Contact")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Contact';
                            Editable = (BillToOptions = BillToOptions::"Custom Address") OR ("Bill-to Customer No." <> "Sell-to Customer No.");
                            Enabled = (BillToOptions = BillToOptions::"Custom Address") OR ("Bill-to Customer No." <> "Sell-to Customer No.");
                            ToolTip = 'Specifies the name of the contact person at the billing address';
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
            }
            group("Foreign Trade")
            {
                Caption = 'Foreign Trade';
                field("EU 3-Party Trade"; "EU 3-Party Trade")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies if the transaction is related to trade with a third party within the EU.';
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
            group(Payments)
            {
                Caption = 'Payments';
                ObsoleteState = Pending;
                ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                ObsoleteTag = '18.0';
                Visible = false;

                field("Bank Account Code"; "Bank Account Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a code to idenfity bank account of my company.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Bank Name"; "Bank Name")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the name of the bank.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Bank Branch No."; "Bank Branch No.")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the bank branch.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Bank Account No."; "Bank Account No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number used by the bank for the bank account.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Transit No."; "Transit No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a bank identification number of your own choice.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("SWIFT Code"; "SWIFT Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the international bank identifier code (SWIFT) of the bank where you have the account.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field(IBAN; IBAN)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the bank account''s international bank account number.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Specific Symbol"; "Specific Symbol")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the additional symbol of bank payments.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Variable Symbol"; "Variable Symbol")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the detail information for payment.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Constant Symbol"; "Constant Symbol")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the additional symbol of bank payments.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
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
            part(Control13; "Pending Approval FactBox")
            {
                ApplicationArea = Suite;
                SubPageLink = "Table ID" = CONST(36),
                              "Document Type" = FIELD("Document Type"),
                              "Document No." = FIELD("No.");
                Visible = OpenApprovalEntriesExistForCurrUser;
            }
            part(Control1902018507; "Customer Statistics FactBox")
            {
                ApplicationArea = Suite;
                SubPageLink = "No." = FIELD("Bill-to Customer No."),
                              "Date Filter" = field("Date Filter");
            }
            part(Control1900316107; "Customer Details FactBox")
            {
                ApplicationArea = Suite;
                SubPageLink = "No." = FIELD("Sell-to Customer No."),
                              "Date Filter" = field("Date Filter");
            }
            part(Control1906127307; "Sales Line FactBox")
            {
                ApplicationArea = Suite;
                Provider = SalesLines;
                SubPageLink = "Document Type" = FIELD("Document Type"),
                              "Document No." = FIELD("Document No."),
                              "Line No." = FIELD("Line No.");
                Visible = false;
            }
            part(ApprovalFactBox; "Approval FactBox")
            {
                ApplicationArea = Suite;
                Visible = false;
            }
            part(Control1907012907; "Resource Details FactBox")
            {
                ApplicationArea = Suite;
                Provider = SalesLines;
                SubPageLink = "No." = FIELD("No.");
                Visible = false;
            }
            part(WorkflowStatus; "Workflow Status FactBox")
            {
                ApplicationArea = Suite;
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
            group("O&rder")
            {
                Caption = 'O&rder';
                Image = "Order";
                action(Statistics)
                {
                    ApplicationArea = Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Category8;
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
                action(Card)
                {
                    ApplicationArea = Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    Promoted = true;
                    PromotedCategory = Category8;
                    RunObject = Page "Customer Card";
                    RunPageLink = "No." = FIELD("Sell-to Customer No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or edit detailed information about the customer on the sales document.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Suite;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    Promoted = true;
                    PromotedCategory = Category8;
                    RunObject = Page "Sales Comment Sheet";
                    RunPageLink = "Document Type" = CONST("Blanket Order"),
                                  "No." = FIELD("No."),
                                  "Document Line No." = CONST(0);
                    ToolTip = 'View or add comments for the record.';
                }
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Enabled = "No." <> '';
                    Image = Dimensions;
                    Promoted = true;
                    PromotedCategory = Category8;
                    PromotedIsBig = true;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDocDim;
                    end;
                }
                action(Approvals)
                {
                    AccessByPermission = TableData "Approval Entry" = R;
                    ApplicationArea = Suite;
                    Caption = 'Approvals';
                    Image = Approvals;
                    Promoted = true;
                    PromotedCategory = Category8;
                    ToolTip = 'View a list of the records that are waiting to be approved. For example, you can see who requested the record to be approved, when it was sent, and when it is due to be approved.';

                    trigger OnAction()
                    var
                        WorkflowsEntriesBuffer: Record "Workflows Entries Buffer";
                    begin
                        WorkflowsEntriesBuffer.RunWorkflowEntriesPage(RecordId, DATABASE::"Sales Header", "Document Type".AsInteger(), "No.");
                    end;
                }
                action(DocAttach)
                {
                    ApplicationArea = All;
                    Caption = 'Attachments';
                    Image = Attach;
                    Promoted = true;
                    PromotedCategory = Category8;
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
        area(processing)
        {
            group(Approval)
            {
                Caption = 'Approval';
                action(Approve)
                {
                    ApplicationArea = Suite;
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
                    ApplicationArea = Suite;
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
                    ApplicationArea = Suite;
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
                    ApplicationArea = Suite;
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
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(CalculateInvoiceDiscount)
                {
                    AccessByPermission = TableData "Cust. Invoice Disc." = R;
                    ApplicationArea = Suite;
                    Caption = 'Calculate &Invoice Discount';
                    Image = CalculateInvoiceDiscount;
                    ToolTip = 'Calculate the invoice discount that applies to the sales order.';

                    trigger OnAction()
                    begin
                        ApproveCalcInvDisc;
                        SalesCalcDiscByType.ResetRecalculateInvoiceDisc(Rec);
                    end;
                }
                separator(Action134)
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
                    end;
                }
                action("Archi&ve Document")
                {
                    ApplicationArea = Suite;
                    Caption = 'Archi&ve Document';
                    Image = Archive;
                    ToolTip = 'Archive document.';

                    trigger OnAction()
                    begin
                        ArchiveManagement.ArchiveSalesDocument(Rec);
                        CurrPage.Update(false);
                    end;
                }
                separator(Action138)
                {
                }
                action(Release)
                {
                    ApplicationArea = Suite;
                    Caption = 'Re&lease';
                    Image = ReleaseDoc;
                    Promoted = true;
                    PromotedCategory = Category7;
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
                    ApplicationArea = Suite;
                    Caption = 'Re&open';
                    Enabled = Status <> Status::Open;
                    Image = ReOpen;
                    Promoted = true;
                    PromotedCategory = Category7;
                    PromotedOnly = true;
                    ToolTip = 'Reopen the document to change it after it has been approved. Approved documents have the Released status and must be opened before they can be changed';

                    trigger OnAction()
                    var
                        ReleaseSalesDoc: Codeunit "Release Sales Document";
                    begin
                        ReleaseSalesDoc.PerformManualReopen(Rec);
                    end;
                }
            }
            action(MakeOrder)
            {
                ApplicationArea = Suite;
                Caption = 'Make &Order';
                Image = MakeOrder;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Convert the blanket sales order to a sales order.';

                trigger OnAction()
                var
                    ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                begin
                    if ApprovalsMgmt.PrePostApprovalCheckSales(Rec) then
                        CODEUNIT.Run(CODEUNIT::"Blnkt Sales Ord. to Ord. (Y/N)", Rec);
                end;
            }
            action(Print)
            {
                ApplicationArea = Suite;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                Promoted = true;
                PromotedCategory = Category6;
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
                PromotedCategory = Category6;
                PromotedIsBig = true;
                PromotedOnly = true;
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
            group("Request Approval")
            {
                Caption = 'Request Approval';
                action(SendApprovalRequest)
                {
                    ApplicationArea = Suite;
                    Caption = 'Send A&pproval Request';
                    Enabled = NOT OpenApprovalEntriesExist;
                    Image = SendApprovalRequest;
                    Promoted = true;
                    PromotedCategory = Category5;
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
                    ApplicationArea = Suite;
                    Caption = 'Cancel Approval Re&quest';
                    Enabled = CanCancelApprovalForRecord;
                    Image = CancelApprovalRequest;
                    Promoted = true;
                    PromotedCategory = Category5;
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
        UpdateShipToBillToGroupVisibility();
        if SellToContact.Get("Sell-to Contact No.") then;
        if BillToContact.Get("Bill-to Contact No.") then;
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        CurrPage.SaveRecord;
        exit(ConfirmDeletion);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if DocNoVisible then
            CheckCreditMaxBeforeInsert;

        if ("Sell-to Customer No." = '') and (GetFilter("Sell-to Customer No.") <> '') then
            CurrPage.Update(false);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        xRec.Init();
        "Responsibility Center" := UserMgt.GetSalesFilter;
        if (not DocNoVisible) and ("No." = '') then
            SetSellToCustomerFromFilter;
        UpdateShipToBillToGroupVisibility;
    end;

    trigger OnOpenPage()
    begin
        if UserMgt.GetSalesFilter <> '' then begin
            FilterGroup(2);
            SetRange("Responsibility Center", UserMgt.GetSalesFilter);
            FilterGroup(0);
        end;

        SetDocNoVisible;
    end;

    var
        SellToContact: Record Contact;
        BillToContact: Record Contact;
        DocPrint: Codeunit "Document-Print";
        UserMgt: Codeunit "User Setup Management";
        ArchiveManagement: Codeunit ArchiveManagement;
        SalesCalcDiscByType: Codeunit "Sales - Calc Discount By Type";
        CustomerMgt: Codeunit "Customer Mgt.";
        ChangeExchangeRate: Page "Change Exchange Rate";
        DocNoVisible: Boolean;
        OpenApprovalEntriesExistForCurrUser: Boolean;
        OpenApprovalEntriesExist: Boolean;
        ShowWorkflowStatus: Boolean;
        CanCancelApprovalForRecord: Boolean;
        [InDataSet]
        StatusStyleTxt: Text;
        EmptyShipToCodeErr: Label 'The Code field can only be empty if you select Custom Address in the Ship-to field.';

    protected var
        ShipToOptions: Option "Default (Sell-to Address)","Alternate Shipping Address","Custom Address";
        BillToOptions: Option "Default (Customer)","Another Customer","Custom Address";

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
        CurrPage.Update();
    end;

    local procedure SetDocNoVisible()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
        DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order",Reminder,FinChMemo;
    begin
        DocNoVisible := DocumentNoVisibility.SalesDocumentNoIsVisible(DocType::"Blanket Order", "No.");
    end;

    local procedure SetControlAppearance()
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        OpenApprovalEntriesExistForCurrUser := ApprovalsMgmt.HasOpenApprovalEntriesForCurrentUser(RecordId);
        OpenApprovalEntriesExist := ApprovalsMgmt.HasOpenApprovalEntries(RecordId);
        CanCancelApprovalForRecord := ApprovalsMgmt.CanCancelApprovalForRecord(RecordId);
    end;

    local procedure UpdateShipToBillToGroupVisibility()
    begin
        CustomerMgt.CalculateShipToBillToOptions(ShipToOptions, BillToOptions, Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeStatisticsAction(var SalesHeader: Record "Sales Header"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShipToOptions(var SalesHeader: Record "Sales Header"; ShipToOptions: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShipToOptions(var SalesHeader: Record "Sales Header"; ShipToOptions: Option)
    begin
    end;
}

