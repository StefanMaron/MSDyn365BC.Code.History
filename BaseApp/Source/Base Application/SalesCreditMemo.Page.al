#if not CLEAN20
page 44 "Sales Credit Memo"
{
    Caption = 'Sales Credit Memo';
    PageType = Document;
    PromotedActionCategories = 'New,Process,Report,Approve,Release,Posting,Prepare,Credit Memo,Request Approval,Navigate';
    RefreshOnActivate = true;
    SourceTable = "Sales Header";
    SourceTableView = WHERE("Document Type" = FILTER("Credit Memo"));

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
                    ApplicationArea = Basic, Suite;
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
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer Name';
                    Importance = Promoted;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the name of the customer who will receive the products and be billed by default.';

                    trigger OnValidate()
                    begin
                        if "No." = '' then
                            InitRecord;

                        SelltoCustomerNoOnAfterValidate(Rec, xRec);
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
                        ApplicationArea = Basic, Suite;
                        Caption = 'Address';
                        Importance = Additional;
                        QuickEntry = false;
                        ToolTip = 'Specifies the address where the customer is located.';
                    }
                    field("Sell-to Address 2"; "Sell-to Address 2")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Address 2';
                        Importance = Additional;
                        QuickEntry = false;
                        ToolTip = 'Specifies additional address information.';
                    }
                    field("Sell-to City"; "Sell-to City")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'City';
                        Importance = Additional;
                        QuickEntry = false;
                        ToolTip = 'Specifies the city of the customer on the sales document.';
                    }
                    group(Control36)
                    {
                        ShowCaption = false;
                        Visible = IsSellToCountyVisible;
                        field("Sell-to County"; "Sell-to County")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'County';
                            Importance = Additional;
                            QuickEntry = false;
                            ToolTip = 'Specifies the state, province or county of the address.';
                        }
                    }
                    field("Sell-to Post Code"; "Sell-to Post Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Post Code';
                        Importance = Additional;
                        QuickEntry = false;
                        ToolTip = 'Specifies the postal code.';
                    }
                    field("Sell-to Country/Region Code"; "Sell-to Country/Region Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Country/Region';
                        Importance = Additional;
                        QuickEntry = false;
                        ToolTip = 'Specifies the country or region of the address.';

                        trigger OnValidate()
                        begin
                            IsSellToCountyVisible := FormatAddress.UseCounty("Sell-to Country/Region Code");
                        end;
                    }
                    field("Sell-to Contact No."; "Sell-to Contact No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Contact No.';
                        Importance = Additional;
                        ToolTip = 'Specifies the number of the contact person that the sales document will be sent to.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            if not SelltoContactLookup() then
                                exit(false);
                            Text := Rec."Sell-to Contact No.";
                            CurrPage.Update();
                            exit(true);
                        end;

                        trigger OnValidate()
                        begin
                            if GetFilter("Sell-to Contact No.") = xRec."Sell-to Contact No." then
                                if "Sell-to Contact No." <> xRec."Sell-to Contact No." then
                                    SetRange("Sell-to Contact No.");
                            if "Sell-to Contact No." <> xRec."Sell-to Contact No." then
                                CurrPage.Update();
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
                    ApplicationArea = Basic, Suite;
                    Caption = 'Contact';
                    Editable = "Sell-to Customer No." <> '';
                    ToolTip = 'Specifies the name of the person to contact at the customer.';
                }
                field("Posting Description"; "Posting Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the document. The posting description also appers on customer and G/L entries.';
                }
                field("Your Reference"; "Your Reference")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the customer''s reference. The contents will be printed on sales documents.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date when the posting of the sales document will be recorded.';

                    trigger OnValidate()
                    begin
                        SaveInvoiceDiscountAmount;
                    end;
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies when the related sales invoice must be paid.';
                }
                field("Incoming Document Entry No."; "Incoming Document Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the number of the incoming document that this sales document is created for.';
                    Visible = false;
                }
                field(Correction; Correction)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you need to post a corrective entry to an account.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '20.0';
                    Visible = false;
                }
                field("External Document No."; "External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ShowMandatory = ExternalDocNoMandatory;
                    ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
                }
                field("Salesperson Code"; "Salesperson Code")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the name of the salesperson who is assigned to the customer.';

                    trigger OnValidate()
                    begin
                        SalespersonCodeOnAfterValidate;
                    end;
                }
                field("Campaign No."; "Campaign No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    Importance = Additional;
                    ToolTip = 'Specifies the number of the campaign that the document is linked to.';
                }
                field("Responsibility Center"; "Responsibility Center")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the code of the responsibility center, such as a distribution hub, that is associated with the involved user, company, customer, or vendor.';
                }
                field("Assigned User ID"; "Assigned User ID")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the ID of the user who is responsible for the document.';
                }
                field("Job Queue Status"; "Job Queue Status")
                {
                    ApplicationArea = All;
                    Importance = Additional;
                    ToolTip = 'Specifies the status of a job queue entry or task that handles the posting of sales credit memos.';
                    Visible = JobQueueUsed;
                }
                field(Status; Status)
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                    StyleExpr = StatusStyleTxt;
                    ToolTip = 'Specifies whether the document is open, waiting to be approved, has been invoiced for prepayment, or has been released to the next stage of processing.';
                }
                field("Applies-to Doc. Type"; "Applies-to Doc. Type")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the type of the posted document that this document or journal line will be applied to when you post, for example to register payment.';
                }
                field("Applies-to Doc. No."; "Applies-to Doc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the number of the posted document that this document or journal line will be applied to when you post, for example to register payment.';
                }
                field("Applies-to ID"; "Applies-to ID")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the ID of entries that will be applied to when you choose the Apply Entries action.';
                }
                group("Work Description")
                {
                    Caption = 'Work Description';
                    field(WorkDescription; WorkDescription)
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        MultiLine = true;
                        ShowCaption = false;
                        ToolTip = 'Specifies the products or services being offered.';

                        trigger OnValidate()
                        begin
                            SetWorkDescription(WorkDescription);
                        end;
                    }
                }
            }
#if not CLEAN18
            group(Payments)
            {
                Caption = 'Payments';
                ObsoleteState = Pending;
                ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                ObsoleteTag = '18.0';
                Visible = false;

                field("Bank Account Code"; "Bank Account Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code to idenfity customer bank account.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Bank Name"; "Bank Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the name of the bank.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Bank Branch No."; "Bank Branch No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the bank branch.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Bank Account No."; "Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number used by the bank for the bank account.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Transit No."; "Transit No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a bank identification number of your own choice.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("SWIFT Code"; "SWIFT Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the international bank identifier code (SWIFT) of the bank where you have the account.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field(IBAN; IBAN)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account''s international bank account number.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Specific Symbol"; "Specific Symbol")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the additional symbol of bank payments.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Variable Symbol"; "Variable Symbol")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the detail information for payment.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Constant Symbol"; "Constant Symbol")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the additional symbol of bank payments.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
            }
#endif
            part(SalesLines; "Sales Cr. Memo Subform")
            {
                ApplicationArea = Basic, Suite;
                Editable = "Sell-to Customer No." <> '';
                Enabled = "Sell-to Customer No." <> '';
                SubPageLink = "Document No." = FIELD("No.");
                UpdatePropagation = Both;
            }
            group("Credit Memo Details")
            {
                Caption = 'Credit Memo Details';
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the currency of amounts on the sales document.';

                    trigger OnAssistEdit()
                    begin
                        Clear(ChangeExchangeRate);
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
                        CurrencyCodeOnAfterValidate; // NAVCZ
                        CurrPage.Update();
                    end;
                }
                field("Company Bank Account Code"; "Company Bank Account Code")
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the bank account to use for bank information when the document is printed.';
                }
#if not CLEAN18
                field(IsIntrastatTransaction; IsIntrastatTransaction)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Intrastat Transaction';
                    Editable = false;
                    ToolTip = 'Specifies if the entry an Intrastat transaction is.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
#endif
                field("Shipment Date"; "Shipment Date")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';
                }
                field("Shipment Method Code"; "Shipment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how items on the sales document are shipped to the customer.';
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
                field("Customer Posting Group"; "Customer Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = IsPostingGroupEditable;
                    Importance = Additional;
                    ToolTip = 'Specifies the customer s market type to link business transactions to.';
                }
                field("Reason Code"; "Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason code on the entry.';
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
                    Visible = IsPaymentMethodCodeVisible;
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
                field("Payment Discount %"; "Payment Discount %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment discount percentage granted if the customer pays on or before the date entered in the Pmt. Discount Date field.';
                }
                field("Pmt. Discount Date"; "Pmt. Discount Date")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the date on which the amount in the entry must be paid for a payment discount to be granted.';
                }
                field("Journal Templ. Name"; Rec."Journal Templ. Name")
                {
                    ApplicationArea = BasicBE;
                    ToolTip = 'Specifies the name of the journal template in which the sales header is to be posted.';
                    Visible = IsJournalTemplNameVisible;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    Importance = Additional;
                    ToolTip = 'Specifies the location from where inventory items to the customer on the sales document are to be shipped by default.';
                }
            }
            group(Billing)
            {
                Caption = 'Billing';
                group("Bill-to")
                {
                    Caption = 'Bill-to';
                    field("Bill-to Name"; "Bill-to Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Name';
                        Importance = Promoted;
                        ToolTip = 'Specifies the customer to whom you will send the sales invoice, when different from the customer that you are selling to.';

                        trigger OnValidate()
                        begin
                            if GetFilter("Bill-to Customer No.") = xRec."Bill-to Customer No." then
                                if "Bill-to Customer No." <> xRec."Bill-to Customer No." then
                                    SetRange("Bill-to Customer No.");

                            CurrPage.Update();
                        end;
                    }
                    field("Bill-to Address"; "Bill-to Address")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Address';
                        Importance = Additional;
                        QuickEntry = false;
                        ToolTip = 'Specifies the address of the customer that you will send the invoice to.';
                    }
                    field("Bill-to Address 2"; "Bill-to Address 2")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Address 2';
                        Importance = Additional;
                        QuickEntry = false;
                        ToolTip = 'Specifies additional address information.';
                    }
                    field("Bill-to City"; "Bill-to City")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'City';
                        Importance = Additional;
                        QuickEntry = false;
                        ToolTip = 'Specifies the city of the customer on the sales document.';
                    }
                    group(Control55)
                    {
                        ShowCaption = false;
                        Visible = IsBillToCountyVisible;
                        field("Bill-to County"; "Bill-to County")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'County';
                            Importance = Additional;
                            QuickEntry = false;
                            ToolTip = 'Specifies the state, province or county of the address.';
                        }
                    }
                    field("Bill-to Post Code"; "Bill-to Post Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Post Code';
                        Importance = Additional;
                        QuickEntry = false;
                        ToolTip = 'Specifies the postal code.';
                    }
                    field("Bill-to Country/Region Code"; "Bill-to Country/Region Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Country/Region';
                        Importance = Additional;
                        QuickEntry = false;
                        ToolTip = 'Specifies the country or region of the address.';

                        trigger OnValidate()
                        begin
                            IsBillToCountyVisible := FormatAddress.UseCounty("Bill-to Country/Region Code");
                        end;
                    }
                    field("Bill-to Contact No."; "Bill-to Contact No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Contact No';
                        Importance = Additional;
                        ToolTip = 'Specifies the number of the contact the invoice will be sent to.';
                    }
                    field("Bill-to Contact"; "Bill-to Contact")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Contact';
                        ToolTip = 'Specifies the name of the person you should contact at the customer who you are sending the invoice to.';
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
                    ToolTip = 'Specifies the country or region of origin for the purpose of Intrastat reporting.';
                }
#if not CLEAN18
                field("Intrastat Exclude"; "Intrastat Exclude")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that entry will be excluded from intrastat.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
#endif
                field("VAT Registration No."; "VAT Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT registration number. The field will be used when you do business with partners from EU countries/regions.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '20.0';
                    Visible = false;
                }
                field("Language Code"; "Language Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the language to be used on printouts for this document.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '20.0';
                    Visible = false;
                }
                field("VAT Country/Region Code"; "VAT Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT country/region code of customer.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '20.0';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            part(SalesDocCheckFactbox; "Sales Doc. Check Factbox")
            {
                ApplicationArea = All;
                Caption = 'Document Check';
                Visible = SalesDocCheckFactboxVisible;
                SubPageLink = "No." = FIELD("No."),
                              "Document Type" = FIELD("Document Type");
            }
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
                ApplicationArea = All;
                SubPageLink = "Table ID" = CONST(36),
                              "Document Type" = FIELD("Document Type"),
                              "Document No." = FIELD("No."),
                              Status = const(Open);
                Visible = OpenApprovalEntriesExistForCurrUser;
            }
            part(Control1903720907; "Sales Hist. Sell-to FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = FIELD("Sell-to Customer No."),
                              "Date Filter" = field("Date Filter");
                Visible = false;
            }
            part(Control1907234507; "Sales Hist. Bill-to FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = FIELD("Sell-to Customer No."),
                              "Date Filter" = field("Date Filter");
                Visible = false;
            }
            part(Control1902018507; "Customer Statistics FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = FIELD("Bill-to Customer No."),
                              "Date Filter" = field("Date Filter");
            }
            part(Control1900316107; "Customer Details FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = FIELD("Sell-to Customer No."),
                              "Date Filter" = field("Date Filter");
            }
            part(Control1906127307; "Sales Line FactBox")
            {
                ApplicationArea = Basic, Suite;
                Provider = SalesLines;
                SubPageLink = "Document Type" = FIELD("Document Type"),
                              "Document No." = FIELD("Document No."),
                              "Line No." = FIELD("Line No.");
                Visible = false;
            }
            part(ApprovalFactBox; "Approval FactBox")
            {
                ApplicationArea = Basic, Suite;
                Visible = false;
            }
            part(IncomingDocAttachFactBox; "Incoming Doc. Attach. FactBox")
            {
                ApplicationArea = Basic, Suite;
                ShowFilter = false;
                Visible = false;
            }
            part(Control1907012907; "Resource Details FactBox")
            {
                ApplicationArea = Basic, Suite;
                Provider = SalesLines;
                SubPageLink = "No." = FIELD("No.");
                Visible = false;
            }
            part(WorkflowStatus; "Workflow Status FactBox")
            {
                ApplicationArea = All;
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
            group("&Credit Memo")
            {
                Caption = '&Credit Memo';
                Image = CreditMemo;
                action(Statistics)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statistics';
                    Enabled = "No." <> '';
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
                        Handled := false;
                        OnBeforeStatisticsAction(Rec, Handled);
                        if Handled then
                            exit;

                        OpenDocumentStatistics();
                        CurrPage.SalesLines.Page.ForceTotalsCalculation();
                    end;
                }
                action(CreditMemo_CustomerCard)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer';
                    Enabled = IsCustomerOrContactNotEmpty;
                    Image = EditLines;
                    Promoted = true;
                    PromotedCategory = Category10;
                    RunObject = Page "Customer Card";
                    RunPageLink = "No." = FIELD("Sell-to Customer No."),
                                  "Date Filter" = FIELD("Date Filter");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or edit detailed information about the customer on the sales document.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    Promoted = true;
                    PromotedCategory = Category8;
                    RunObject = Page "Sales Comment Sheet";
                    RunPageLink = "Document Type" = FIELD("Document Type"),
                                  "No." = FIELD("No."),
                                  "Document Line No." = CONST(0);
                    ToolTip = 'View or add comments for the record.';
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
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.OpenApprovalsSales(Rec);
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
                        DocumentAttachmentDetails.RunModal();
                    end;
                }
            }
        }
        area(processing)
        {
            group("Credit Memo")
            {
                Caption = '&Credit Memo';
                Image = CreditMemo;
                action(Customer)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer';
                    Enabled = IsCustomerOrContactNotEmpty;
                    Image = Customer;
                    RunObject = Page "Customer Card";
                    RunPageLink = "No." = FIELD("Sell-to Customer No."),
                                  "Date Filter" = FIELD("Date Filter");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or edit detailed information about the customer.';
                }
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    Promoted = true;
                    PromotedCategory = Category8;
                    PromotedIsBig = true;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDocDim;
                        CurrPage.SaveRecord;
                    end;
                }
            }
            group(Approval)
            {
                Caption = 'Approval';
                action(Approve)
                {
                    ApplicationArea = All;
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
                    ApplicationArea = All;
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
                    ApplicationArea = All;
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
            group(Action7)
            {
                Caption = 'Release';
                Image = ReleaseDoc;
                action(Release)
                {
                    ApplicationArea = Suite;
                    Caption = 'Re&lease';
                    Enabled = IsCustomerOrContactNotEmpty;
                    Image = ReleaseDoc;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Release the document to the next stage of processing. You must reopen the document before you can make changes to it.';

                    trigger OnAction()
                    var
                        ReleaseSalesDoc: Codeunit "Release Sales Document";
                    begin
                        ReleaseSalesDoc.PerformManualRelease(Rec);
                        CurrPage.SalesLines.PAGE.ClearTotalSalesHeader();
                    end;
                }
                action(Reopen)
                {
                    ApplicationArea = Suite;
                    Caption = 'Re&open';
                    Enabled = Status <> Status::Open;
                    Image = ReOpen;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedOnly = true;
                    ToolTip = 'Reopen the document to change it after it has been approved. Approved documents have the Released status and must be opened before they can be changed.';

                    trigger OnAction()
                    var
                        ReleaseSalesDoc: Codeunit "Release Sales Document";
                    begin
                        ReleaseSalesDoc.PerformManualReopen(Rec);
                        CurrPage.SalesLines.PAGE.ClearTotalSalesHeader();
                    end;
                }
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(GetPostedDocumentLinesToReverse)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Get Posted Doc&ument Lines to Reverse';
                    Ellipsis = true;
                    Image = ReverseLines;
                    Promoted = true;
                    PromotedCategory = Category7;
                    ToolTip = 'Copy one or more posted sales document lines in order to reverse the original order.';

                    trigger OnAction()
                    begin
                        GetPstdDocLinesToReverse();
                    end;
                }
                action(CalculateInvoiceDiscount)
                {
                    AccessByPermission = TableData "Cust. Invoice Disc." = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Calculate &Invoice Discount';
                    Enabled = IsCustomerOrContactNotEmpty;
                    Image = CalculateInvoiceDiscount;
                    ToolTip = 'Calculate the invoice discount that applies to the sales credit memo.';

                    trigger OnAction()
                    begin
                        ApproveCalcInvDisc;
                        SalesCalcDiscByType.ResetRecalculateInvoiceDisc(Rec);
                    end;
                }
                action(ApplyEntries)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Apply Entries';
                    Ellipsis = true;
                    Enabled = "No." <> '';
                    Image = ApplyEntries;
                    Promoted = true;
                    PromotedCategory = Category7;
                    ShortCutKey = 'Shift+F11';
                    ToolTip = 'Select one or more ledger entries that you want to apply this record to so that the related posted documents are closed as paid or refunded.';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Sales Header Apply", Rec);
                    end;
                }
                action(GetStdCustSalesCodes)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Get Recurring Sales Lines';
                    Ellipsis = true;
                    Enabled = IsCustomerOrContactNotEmpty;
                    Image = CustomerCode;
                    Promoted = true;
                    PromotedCategory = Category7;
                    ToolTip = 'View a list of the standard sales lines that have been assigned to the customer to be used for recurring sales.';

                    trigger OnAction()
                    var
                        StdCustSalesCode: Record "Standard Customer Sales Code";
                    begin
                        StdCustSalesCode.InsertSalesLines(Rec);
                    end;
                }
                action(CopyDocument)
                {
                    ApplicationArea = Suite;
                    Caption = 'Copy Document';
                    Ellipsis = true;
                    Enabled = "No." <> '';
                    Image = CopyDocument;
                    Promoted = true;
                    PromotedCategory = Category7;
                    ToolTip = 'Copy document lines and header information from another sales document to this document. You can copy a posted sales invoice into a new sales invoice to quickly create a similar document.';

                    trigger OnAction()
                    begin
                        CopyDocument();
                        if Get("Document Type", "No.") then;
                        CurrPage.SalesLines.Page.ForceTotalsCalculation();
                        CurrPage.Update();
                    end;
                }
                action("Move Negative Lines")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Move Negative Lines';
                    Ellipsis = true;
                    Image = MoveNegativeLines;
                    ToolTip = 'Prepare to create a replacement sales order in a sales return process.';

                    trigger OnAction()
                    begin
                        Clear(MoveNegSalesLines);
                        MoveNegSalesLines.SetSalesHeader(Rec);
                        MoveNegSalesLines.RunModal();
                        MoveNegSalesLines.ShowDocument;
                    end;
                }
                group(IncomingDocument)
                {
                    Caption = 'Incoming Document';
                    Image = Documents;
                    action(IncomingDocCard)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'View Incoming Document';
                        Enabled = HasIncomingDocument;
                        Image = ViewOrder;
                        ToolTip = 'View any incoming document records and file attachments that exist for the entry or document.';

                        trigger OnAction()
                        var
                            IncomingDocument: Record "Incoming Document";
                        begin
                            IncomingDocument.ShowCardFromEntryNo("Incoming Document Entry No.");
                        end;
                    }
                    action(SelectIncomingDoc)
                    {
                        AccessByPermission = TableData "Incoming Document" = R;
                        ApplicationArea = Basic, Suite;
                        Caption = 'Select Incoming Document';
                        Image = SelectLineToApply;
                        ToolTip = 'Select an incoming document record and file attachment that you want to link to the entry or document.';

                        trigger OnAction()
                        var
                            IncomingDocument: Record "Incoming Document";
                        begin
                            Validate("Incoming Document Entry No.", IncomingDocument.SelectIncomingDocument("Incoming Document Entry No.", RecordId));
                        end;
                    }
                    action(IncomingDocAttachFile)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Create Incoming Document from File';
                        Ellipsis = true;
                        Enabled = NOT HasIncomingDocument;
                        Image = Attach;
                        ToolTip = 'Create an incoming document record by selecting a file to attach, and then link the incoming document record to the entry or document.';

                        trigger OnAction()
                        var
                            IncomingDocumentAttachment: Record "Incoming Document Attachment";
                        begin
                            IncomingDocumentAttachment.NewAttachmentFromSalesDocument(Rec);
                        end;
                    }
                    action(RemoveIncomingDoc)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Remove Incoming Document';
                        Enabled = HasIncomingDocument;
                        Image = RemoveLine;
                        ToolTip = 'Remove any incoming document records and file attachments.';

                        trigger OnAction()
                        var
                            IncomingDocument: Record "Incoming Document";
                        begin
                            if IncomingDocument.Get("Incoming Document Entry No.") then
                                IncomingDocument.RemoveLinkToRelatedRecord;
                            "Incoming Document Entry No." := 0;
                            Modify(true);
                        end;
                    }
                }
            }
            group("Request Approval")
            {
                Caption = 'Request Approval';
                Image = Approval;
                action(SendApprovalRequest)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Send A&pproval Request';
                    Enabled = NOT OpenApprovalEntriesExist AND CanRequestApprovalForFlow;
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
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cancel Approval Re&quest';
                    Enabled = CanCancelApprovalForRecord OR CanCancelApprovalForFlow;
                    Image = CancelApprovalRequest;
                    Promoted = true;
                    PromotedCategory = Category9;
                    ToolTip = 'Cancel the approval request.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                        WorkflowWebhookMgt: Codeunit "Workflow Webhook Management";
                    begin
                        ApprovalsMgmt.OnCancelSalesApprovalRequest(Rec);
                        WorkflowWebhookMgt.FindAndCancel(RecordId);
                    end;
                }
                group(Flow)
                {
                    Caption = 'Power Automate';
                    Image = Flow;
                    action(CreateFlow)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Create a flow';
                        Image = Flow;
                        Promoted = true;
                        PromotedCategory = Category9;
                        ToolTip = 'Create a new flow in Power Automate from a list of relevant flow templates.';
                        Visible = IsSaaS;

                        trigger OnAction()
                        var
                            FlowServiceManagement: Codeunit "Flow Service Management";
                            FlowTemplateSelector: Page "Flow Template Selector";
                        begin
                            // Opens page 6400 where the user can use filtered templates to create new flows.
                            FlowTemplateSelector.SetSearchText(FlowServiceManagement.GetSalesTemplateFilter);
                            FlowTemplateSelector.Run();
                        end;
                    }
                    action(SeeFlows)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'See my flows';
                        Image = Flow;
                        Promoted = true;
                        PromotedCategory = Category9;
                        RunObject = Page "Flow Selector";
                        ToolTip = 'View and configure Power Automate flows that you created.';
                    }
                }
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action(Post)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'P&ost';
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
                action(TestReport)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Enabled = "No." <> '';
                    Image = TestReport;
                    ToolTip = 'View a test report so that you can find and correct any errors before you perform the actual posting of the journal or document.';

                    trigger OnAction()
                    begin
                        ReportPrint.PrintSalesHeader(Rec);
                    end;
                }
                action(PostAndSend)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post and &Send';
                    Ellipsis = true;
                    Image = PostSendTo;
                    Promoted = true;
                    PromotedCategory = Category6;
                    PromotedIsBig = true;
                    ToolTip = 'Finalize and prepare to send the document according to the customer''s sending profile, such as attached to an email. The Send document to window opens first so you can confirm or select a sending profile.';

                    trigger OnAction()
                    begin
                        PostDocument(CODEUNIT::"Sales-Post and Send");
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
                action("Preview Posting")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Preview Posting';
                    Image = ViewPostedOrder;
                    Promoted = true;
                    PromotedCategory = Category6;
                    ShortCutKey = 'Ctrl+Alt+F9';
                    ToolTip = 'Review the different types of entries that will be created when you post the document or journal.';

                    trigger OnAction()
                    begin
                        ShowPreview;
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.IncomingDocAttachFactBox.PAGE.LoadDataFromRecord(Rec);
        CurrPage.ApprovalFactBox.PAGE.UpdateApprovalEntriesFromSourceRecord(RecordId);
        ShowWorkflowStatus := CurrPage.WorkflowStatus.PAGE.SetFilterOnWorkflowRecord(RecordId);
        SetControlAppearance;
        StatusStyleTxt := GetStatusStyleText();
    end;

    trigger OnAfterGetRecord()
    begin
        SetControlAppearance;
        WorkDescription := GetWorkDescription;
        SellToContact.GetOrClear("Sell-to Contact No.");
        BillToContact.GetOrClear("Bill-to Contact No.");

        OnAfterOnAfterGetRecord(Rec);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        CurrPage.SaveRecord;
        exit(ConfirmDeletion);
    end;

    trigger OnInit()
    begin
        JobQueueUsed := SalesSetup.JobQueueActive();
        SetExtDocNoMandatoryCondition();
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
        SetControlAppearance;
    end;

    trigger OnOpenPage()
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        Rec.SetSecurityFilterOnRespCenter();

        SetRange("Date Filter", 0D, WorkDate());

        ActivateFields;

        IsSaaS := EnvironmentInfo.IsSaaS;
        SetDocNoVisible();
        SetControlAppearance();
        if ("No." <> '') and ("Sell-to Customer No." = '') then
            DocumentIsPosted := (not Get("Document Type", "No."));

        SetPostingGroupEditable();
        CheckShowBackgrValidationNotification();
    end;

#if not CLEAN19
    [Obsolete('Replaced by procedure SetSecurityFilterOnRespCenter() from Sales Header table.', '19.0')]
    local procedure SetFilterByResponsibilityCenter()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetFilterByResponsibilityCenter(Rec, IsHandled);
        if IsHandled then
            exit;

        Rec.SetSecurityFilterOnRespCenter();
    end;
#endif

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if not DocumentIsPosted then
            exit(ConfirmCloseUnposted);
    end;

    var
        SellToContact: Record Contact;
        BillToContact: Record Contact;
        SalesSetup: Record "Sales & Receivables Setup";
        GLSetup: Record "General Ledger Setup";
        MoveNegSalesLines: Report "Move Negative Sales Lines";
        ReportPrint: Codeunit "Test Report-Print";
        UserMgt: Codeunit "User Setup Management";
        SalesCalcDiscByType: Codeunit "Sales - Calc Discount By Type";
        LinesInstructionMgt: Codeunit "Lines Instruction Mgt.";
        FormatAddress: Codeunit "Format Address";
        ChangeExchangeRate: Page "Change Exchange Rate";
        WorkDescription: Text;
        [InDataSet]
        StatusStyleTxt: Text;
        [InDataSet]
        JobQueueVisible: Boolean;
        [InDataSet]
        JobQueueUsed: Boolean;
        HasIncomingDocument: Boolean;
        DocNoVisible: Boolean;
        ExternalDocNoMandatory: Boolean;
        OpenApprovalEntriesExistForCurrUser: Boolean;
        OpenApprovalEntriesExist: Boolean;
        ShowWorkflowStatus: Boolean;
        OpenPostedSalesCrMemoQst: Label 'The credit memo is posted as number %1 and moved to the Posted Sales Credit Memos window.\\Do you want to open the posted credit memo?', Comment = '%1 = posted document number';
        CanCancelApprovalForRecord: Boolean;
        DocumentIsPosted: Boolean;
        IsCustomerOrContactNotEmpty: Boolean;
        CanRequestApprovalForFlow: Boolean;
        CanCancelApprovalForFlow: Boolean;
        IsPostingGroupEditable: Boolean;
        IsSaaS: Boolean;
        IsBillToCountyVisible: Boolean;
        IsSellToCountyVisible: Boolean;
        SalesDocCheckFactboxVisible: Boolean;
        [InDataSet]
        IsJournalTemplNameVisible: Boolean;
        [InDataSet]
        IsPaymentMethodCodeVisible: Boolean;

    local procedure ActivateFields()
    begin
        IsBillToCountyVisible := FormatAddress.UseCounty("Bill-to Country/Region Code");
        IsSellToCountyVisible := FormatAddress.UseCounty("Sell-to Country/Region Code");
        GLSetup.Get();
        IsJournalTemplNameVisible := GLSetup."Journal Templ. Name Mandatory";
        IsPaymentMethodCodeVisible := not GLSetup."Hide Payment Method Code";
    end;

    procedure CallPostDocument(PostingCodeunitID: Integer)
    begin
        PostDocument(PostingCodeunitID);
    end;

    local procedure PostDocument(PostingCodeunitID: Integer)
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        OfficeMgt: Codeunit "Office Management";
        InstructionMgt: Codeunit "Instruction Mgt.";
        PreAssignedNo: Code[20];
        IsScheduledPosting: Boolean;
        IsHandled: Boolean;
    begin
        CheckSalesCheckAllLinesHaveQuantityAssigned;
        PreAssignedNo := "No.";

        SendToPosting(PostingCodeunitID);

        IsScheduledPosting := "Job Queue Status" = "Job Queue Status"::"Scheduled for Posting";
        DocumentIsPosted := (not SalesHeader.Get("Document Type", "No.")) or IsScheduledPosting;
        OnPostOnAfterSetDocumentIsPosted(SalesHeader, IsScheduledPosting, DocumentIsPosted);

        if IsScheduledPosting then
            CurrPage.Close;
        CurrPage.Update(false);

        IsHandled := false;
        OnPostDocumentBeforeNavigateAfterPosting(Rec, PostingCodeunitID, DocumentIsPosted, IsHandled);
        if IsHandled then
            exit;

        if PostingCodeunitID <> CODEUNIT::"Sales-Post (Yes/No)" then
            exit;

        if OfficeMgt.IsAvailable then begin
            SalesCrMemoHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
            if SalesCrMemoHeader.FindFirst() then
                PAGE.Run(PAGE::"Posted Sales Credit Memo", SalesCrMemoHeader);
        end else
            if InstructionMgt.IsEnabled(InstructionMgt.ShowPostedConfirmationMessageCode) then
                ShowPostedConfirmationMessage(PreAssignedNo);
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
        CurrPage.Update();
    end;

    local procedure ShortcutDimension2CodeOnAfterV()
    begin
        CurrPage.Update();
    end;

    local procedure PricesIncludingVATOnAfterValid()
    begin
        CurrPage.SalesLines.Page.ForceTotalsCalculation();
        CurrPage.Update();
    end;

    [Obsolete('This procedure will be removed and should not be used.', '20.0')]
    local procedure CurrencyCodeOnAfterValidate()
    begin
        CurrPage.SalesLines.PAGE.UpdateForm(true); // NAVCZ
    end;

    local procedure SetDocNoVisible()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
        DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order",Reminder,FinChMemo;
    begin
        DocNoVisible := DocumentNoVisibility.SalesDocumentNoIsVisible(DocType::"Credit Memo", "No.");
    end;

    local procedure SetExtDocNoMandatoryCondition()
    begin
        SalesSetup.GetRecordOnce();
        ExternalDocNoMandatory := SalesSetup."Ext. Doc. No. Mandatory";
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
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        WorkflowWebhookMgt: Codeunit "Workflow Webhook Management";
    begin
        JobQueueVisible := "Job Queue Status" = "Job Queue Status"::"Scheduled for Posting";
        HasIncomingDocument := "Incoming Document Entry No." <> 0;
        SetExtDocNoMandatoryCondition;

        OpenApprovalEntriesExistForCurrUser := ApprovalsMgmt.HasOpenApprovalEntriesForCurrentUser(RecordId);
        OpenApprovalEntriesExist := ApprovalsMgmt.HasOpenApprovalEntries(RecordId);
        CanCancelApprovalForRecord := ApprovalsMgmt.CanCancelApprovalForRecord(RecordId);
        IsCustomerOrContactNotEmpty := ("Sell-to Customer No." <> '') or ("Sell-to Contact No." <> '');

        SalesDocCheckFactboxVisible := DocumentErrorsMgt.BackgroundValidationEnabled();
        WorkflowWebhookMgt.GetCanRequestAndCanCancel(RecordId, CanRequestApprovalForFlow, CanCancelApprovalForFlow);

        OnAfterSetControlAppearance(Rec);
    end;

    procedure RunBackgroundCheck()
    begin
        CurrPage.SalesDocCheckFactbox.Page.CheckErrorsInBackground(Rec);
    end;

    local procedure CheckShowBackgrValidationNotification()
    var
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
    begin
        if DocumentErrorsMgt.CheckShowEnableBackgrValidationNotification() then
            SetControlAppearance();
    end;

    local procedure CheckSalesCheckAllLinesHaveQuantityAssigned()
    begin
        LinesInstructionMgt.SalesCheckAllLinesHaveQuantityAssigned(Rec);
    end;

    local procedure ShowPostedConfirmationMessage(PreAssignedNo: Code[20])
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        SalesCrMemoHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        if SalesCrMemoHeader.FindFirst() then
            if InstructionMgt.ShowConfirm(StrSubstNo(OpenPostedSalesCrMemoQst, SalesCrMemoHeader."No."),
                 InstructionMgt.ShowPostedConfirmationMessageCode)
            then
                InstructionMgt.ShowPostedDocument(SalesCrMemoHeader, Page::"Sales Credit Memo");
    end;

    procedure SetPostingGroupEditable()
    begin
        SalesSetup.GetRecordOnce();
        IsPostingGroupEditable := SalesSetup."Allow Multiple Posting Groups";
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterOnAfterGetRecord(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterSetControlAppearance(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeStatisticsAction(var SalesHeader: Record "Sales Header"; var Handled: Boolean)
    begin
    end;

#if not CLEAN19
    [Obsolete('Replaced by same event in Sales Header table.', '19.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetFilterByResponsibilityCenter(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnPostOnAfterSetDocumentIsPosted(SalesHeader: Record "Sales Header"; var IsScheduledPosting: Boolean; var DocumentIsPosted: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostDocumentBeforeNavigateAfterPosting(var SalesHeader: Record "Sales Header"; var PostingCodeunitID: Integer; DocumentIsPosted: Boolean; var IsHandled: Boolean)
    begin
    end;
}
#endif