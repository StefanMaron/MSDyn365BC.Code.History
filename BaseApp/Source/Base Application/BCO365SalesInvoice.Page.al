page 2310 "BC O365 Sales Invoice"
{
    Caption = 'Draft Invoice';
    DataCaptionExpression = '';
    PageType = Document;
    PromotedActionCategories = 'New,Process,Report,Manage';
    RefreshOnActivate = true;
    SourceTable = "Sales Header";
    SourceTableView = WHERE("Document Type" = CONST(Invoice));

    layout
    {
        area(content)
        {
            group(SellToWeb)
            {
                Caption = 'Sell to';
                Visible = NOT IsDevice;
                field("Sell-to Customer Name"; "Sell-to Customer Name")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Customer Name';
                    Importance = Promoted;
                    LookupPageID = "BC O365 Contact Lookup";
                    QuickEntry = false;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the customer''s name.';

                    trigger OnValidate()
                    begin
                        O365SalesInvoiceMgmt.ValidateCustomerName(Rec, CustomerName, CustomerEmail);
                        O365SalesInvoiceMgmt.UpdateAddress(Rec, FullAddress, CountryRegionCode);

                        CurrPage.Update(true);
                    end;
                }
                field(CustomerEmail; CustomerEmail)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Email Address';
                    Editable = CurrPageEditable AND (CustomerName <> '');
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the customer''s email address.';

                    trigger OnValidate()
                    begin
                        O365SalesInvoiceMgmt.ValidateCustomerEmail(Rec, CustomerEmail);
                    end;
                }
                group(Control24)
                {
                    ShowCaption = false;
                    field(ViewContactCard; ViewContactDetailsLbl)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Editable = false;
                        Enabled = CustomerName <> '';
                        ShowCaption = false;

                        trigger OnDrillDown()
                        begin
                            O365SalesInvoiceMgmt.EditCustomerCardFromSalesHeader(Rec, FullAddress, CountryRegionCode);
                        end;
                    }
                }
                group(Control11)
                {
                    ShowCaption = false;
                    field("Sell-to Address"; "Sell-to Address")
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'Address';
                        Editable = CustomerName <> '';
                        ToolTip = 'Specifies the address where the customer is located.';

                        trigger OnValidate()
                        begin
                            O365SalesInvoiceMgmt.ValidateCustomerAddress("Sell-to Address", "Sell-to Customer No.");
                            O365SalesInvoiceMgmt.UpdateAddress(Rec, FullAddress, CountryRegionCode);
                        end;
                    }
                    field("Sell-to Address 2"; "Sell-to Address 2")
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'Address 2';
                        Editable = CustomerName <> '';
                        ToolTip = 'Specifies additional address information.';

                        trigger OnValidate()
                        begin
                            O365SalesInvoiceMgmt.ValidateCustomerAddress2("Sell-to Address 2", "Sell-to Customer No.");
                            O365SalesInvoiceMgmt.UpdateAddress(Rec, FullAddress, CountryRegionCode);
                        end;
                    }
                    field("Sell-to City"; "Sell-to City")
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'City';
                        Editable = CustomerName <> '';
                        Lookup = false;
                        ToolTip = 'Specifies the address city.';

                        trigger OnValidate()
                        begin
                            O365SalesInvoiceMgmt.ValidateCustomerCity("Sell-to City", "Sell-to Customer No.");
                            O365SalesInvoiceMgmt.UpdateAddress(Rec, FullAddress, CountryRegionCode);
                        end;
                    }
                    field("Sell-to Post Code"; "Sell-to Post Code")
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'Post Code';
                        Editable = CustomerName <> '';
                        Lookup = false;
                        ToolTip = 'Specifies the postal code.';

                        trigger OnValidate()
                        begin
                            O365SalesInvoiceMgmt.ValidateCustomerPostCode("Sell-to Post Code", "Sell-to Customer No.");
                            O365SalesInvoiceMgmt.UpdateAddress(Rec, FullAddress, CountryRegionCode);
                        end;
                    }
                    field("Sell-to County"; "Sell-to County")
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'County';
                        Editable = CustomerName <> '';
                        Lookup = false;
                        ToolTip = 'Specifies the address county.';

                        trigger OnValidate()
                        begin
                            O365SalesInvoiceMgmt.ValidateCustomerCounty("Sell-to County", "Sell-to Customer No.");
                            O365SalesInvoiceMgmt.UpdateAddress(Rec, FullAddress, CountryRegionCode);
                        end;
                    }
                    field(CountryRegionCode; CountryRegionCode)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'Country/Region Code';
                        Editable = CurrPageEditable AND (CustomerName <> '');
                        Lookup = true;
                        LookupPageID = "BC O365 Country/Region List";
                        TableRelation = "Country/Region";
                        ToolTip = 'Specifies the address country/region.';

                        trigger OnValidate()
                        begin
                            CountryRegionCode := O365SalesInvoiceMgmt.FindCountryCodeFromInput(CountryRegionCode);
                            "Sell-to Country/Region Code" := CountryRegionCode;

                            O365SalesInvoiceMgmt.ValidateCustomerCountryRegion("Sell-to Country/Region Code", "Sell-to Customer No.");
                            O365SalesInvoiceMgmt.UpdateAddress(Rec, FullAddress, CountryRegionCode);
                        end;
                    }
                }
            }
            group(SellToDevice)
            {
                Caption = 'Sell to';
                Visible = IsDevice AND NOT FieldsVisible;
                field(EnterNewSellToCustomerName; "Sell-to Customer Name")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Add new customer';
                    Importance = Promoted;
                    Lookup = false;
                    QuickEntry = false;
                    ToolTip = 'Specifies the customer''s name.';

                    trigger OnValidate()
                    var
                        Customer: Record Customer;
                    begin
                        O365SalesInvoiceMgmt.CreateCustomer(Rec, Customer, CustomerName, CustomerEmail);
                        O365SalesInvoiceMgmt.UpdateAddress(Rec, FullAddress, CountryRegionCode);

                        CurrPage.Update(true);
                    end;
                }
                group("Or")
                {
                    Caption = 'Or';
                    field(PickExistingCustomer; PickExistingCustomerLbl)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Editable = false;
                        LookupPageID = "BC O365 Contact Lookup";
                        QuickEntry = false;
                        ShowCaption = false;

                        trigger OnDrillDown()
                        begin
                            if O365SalesInvoiceMgmt.LookupContactFromSalesHeader(Rec) then
                                CurrPage.Update(true);
                        end;
                    }
                }
            }
            group(SellToDeviceWithCustomerName)
            {
                Caption = 'Sell to';
                Visible = IsDevice AND FieldsVisible;
                field(PhoneSellToCustomerName; "Sell-to Customer Name")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Customer Name';
                    Importance = Promoted;
                    LookupPageID = "BC O365 Contact Lookup";
                    QuickEntry = false;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the customer''s name.';
                    Visible = IsDevice;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        if O365SalesInvoiceMgmt.LookupContactFromSalesHeader(Rec) then
                            CurrPage.Update(true);
                    end;

                    trigger OnValidate()
                    begin
                        O365SalesInvoiceMgmt.ValidateCustomerName(Rec, CustomerName, CustomerEmail);
                        O365SalesInvoiceMgmt.UpdateAddress(Rec, FullAddress, CountryRegionCode);

                        CurrPage.Update(true);
                    end;
                }
                field(PhoneCustomerEmail; CustomerEmail)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Email Address';
                    Editable = CurrPageEditable AND (CustomerName <> '');
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the customer''s email address.';

                    trigger OnValidate()
                    begin
                        O365SalesInvoiceMgmt.ValidateCustomerEmail(Rec, CustomerEmail);
                    end;
                }
                field(FullAddress; FullAddress)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Address';
                    Editable = false;
                    ToolTip = 'Specifies the address of the customer.';

                    trigger OnAssistEdit()
                    var
                        TempStandardAddress: Record "Standard Address" temporary;
                    begin
                        if not CurrPageEditable then
                            exit;
                        if CustomerName = '' then
                            exit;

                        CurrPage.SaveRecord;
                        Commit();
                        TempStandardAddress.CopyFromSalesHeaderSellTo(Rec);
                        if PAGE.RunModal(PAGE::"O365 Address", TempStandardAddress) = ACTION::LookupOK then begin
                            Find;
                            O365SalesInvoiceMgmt.UpdateAddress(Rec, FullAddress, CountryRegionCode);
                            // UpdateAddress changes Bill-To address without MODIFYing: make sure the next line is either MODIFY or CurrPage.UPDATE(TRUE);
                            CurrPage.Update(true);
                        end;
                    end;
                }
            }
            group("Invoice Details")
            {
                Caption = 'Invoice Details';
                Visible = FieldsVisible;
                field(NextInvoiceNo; NextInvoiceNo)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Expected Invoice No.';
                    Editable = false;
                    ToolTip = 'Specifies the number that your next sent invoice will get.';
                }
                field("Payment Terms Code"; "Payment Terms Code")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Payment Terms';
                    Editable = false;
                    Enabled = CustomerName <> '';

                    trigger OnAssistEdit()
                    var
                        TempO365PaymentTerms: Record "O365 Payment Terms" temporary;
                    begin
                        TempO365PaymentTerms.RefreshRecords;
                        if TempO365PaymentTerms.Get("Payment Terms Code") then;
                        if PAGE.RunModal(PAGE::"O365 Payment Terms List", TempO365PaymentTerms) = ACTION::LookupOK then
                            Validate("Payment Terms Code", TempO365PaymentTerms.Code);
                    end;
                }
                field(PaymentInstructionsName; PaymentInstructionsName)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Payment Instructions';
                    Editable = false;
                    Enabled = CustomerName <> '';

#if not CLEAN19
                    trigger OnAssistEdit()
                    var
                        O365PaymentInstructions: Record "O365 Payment Instructions";
                    begin
                        if O365PaymentInstructions.Get("Payment Instructions Id") then;

                        if PAGE.RunModal(PAGE::"BC O365 Payment Instr. List", O365PaymentInstructions) = ACTION::LookupOK then begin
                            Validate("Payment Instructions Id", O365PaymentInstructions.Id);
                            Session.LogMessage('00001SB', PaymentInstrChangedTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PaymentInstrCategoryLbl);
                            O365SalesInvoiceMgmt.GetPaymentInstructionsName("Payment Instructions Id", PaymentInstructionsName);
                        end;
                    end;
#endif
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Editable = CustomerName <> '';
                    ToolTip = 'Specifies when the sales invoice must be paid.';

                    trigger OnValidate()
                    begin
                        if "Due Date" < "Document Date" then
                            Validate("Due Date", "Document Date");
                    end;
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Invoice Date';
                    Editable = CustomerName <> '';
                    ToolTip = 'Specifies when the sales invoice was created.';

                    trigger OnValidate()
                    var
                        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
                        PastNotification: Notification;
                    begin
                        Validate("Posting Date", "Document Date");

                        if "Document Date" < WorkDate then begin
                            PastNotification.Id := DocumentDatePastWorkdateNotificationGuidTok;
                            PastNotification.Message(DocumentDatePastMsg);
                            PastNotification.Scope(NOTIFICATIONSCOPE::LocalScope);
                            NotificationLifecycleMgt.SendNotification(PastNotification, RecordId);
                        end;
                    end;
                }
                field("Tax Liable"; "Tax Liable")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Customer is tax liable';
                    Editable = CustomerName <> '';
                    ToolTip = 'Specifies if the sales invoice contains sales tax.';
                    Visible = NOT IsUsingVAT;

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field(TaxAreaDescription; TaxAreaDescription)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Customer tax rate';
                    Editable = false;
                    Enabled = CustomerName <> '';
                    NotBlank = true;
                    QuickEntry = false;
                    ToolTip = 'Specifies the customer''s tax area.';
                    Visible = NOT IsUsingVAT;

                    trigger OnAssistEdit()
                    var
                        TaxArea: Record "Tax Area";
                    begin
                        if TaxArea.Get("Tax Area Code") then;
                        if PAGE.RunModal(PAGE::"O365 Tax Area List", TaxArea) = ACTION::LookupOK then begin
                            Validate("Tax Area Code", TaxArea.Code);
                            TaxAreaDescription := TaxArea.GetDescriptionInCurrentLanguage;
                            CurrPage.Update();
                        end;
                    end;
                }
                field("VAT Registration No."; "VAT Registration No.")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Editable = (IsUsingVAT AND IsCompanyContact);
                    Visible = IsUsingVAT;
                }
            }
            part(Lines; "BC O365 Sales Inv. Line Subp.")
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Line Items';
                Editable = CustomerName <> '';
                Enabled = CustomerName <> '';
                SubPageLink = "Document Type" = FIELD("Document Type"),
                              "Document No." = FIELD("No.");
                Visible = FieldsVisible;
            }
            group(Totals)
            {
                Caption = 'Totals';
                Visible = FieldsVisible AND NOT InvDiscAmountVisible;
                group(Control39)
                {
                    ShowCaption = false;
                    field(Amount; Amount)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        AutoFormatExpression = CurrencyFormat;
                        AutoFormatType = 11;
                        Caption = 'Net Total';
                        DrillDown = false;
                        Lookup = false;
                        ToolTip = 'Specifies the total amount on the sales invoice excluding VAT.';
                    }
                    field(AmountInclVAT; "Amount Including VAT")
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        AutoFormatExpression = CurrencyFormat;
                        AutoFormatType = 11;
                        Caption = 'Total Including VAT';
                        DrillDown = false;
                        Importance = Promoted;
                        Lookup = false;
                        Style = Strong;
                        StyleExpr = TRUE;
                        ToolTip = 'Specifies the total amount on the sales invoice including VAT.';
                    }
                    field(DiscountLink; DiscountTxt)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        DrillDown = true;
                        Editable = false;
                        Enabled = CustomerName <> '';
                        Importance = Promoted;
                        ShowCaption = false;

                        trigger OnDrillDown()
                        begin
                            if PAGE.RunModal(PAGE::"O365 Sales Invoice Discount", Rec) = ACTION::LookupOK then
                                CurrPage.Update();
                        end;
                    }
                }
            }
            group(Control30)
            {
                Caption = 'Totals';
                Visible = FieldsVisible AND InvDiscAmountVisible;
                group(Control32)
                {
                    ShowCaption = false;
                    field(SubTotalAmount; SubTotalAmount)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        AutoFormatExpression = CurrencyFormat;
                        AutoFormatType = 11;
                        Caption = 'Subtotal';
                        Editable = false;
                        Importance = Promoted;
                    }
                    field(InvoiceDiscount; -InvoiceDiscountAmount)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        AutoFormatExpression = CurrencyFormat;
                        AutoFormatType = 11;
                        CaptionClass = GetInvDiscountCaption;
                        Caption = 'Invoice Discount';
                        Editable = false;
                        Importance = Promoted;
                        ToolTip = 'Specifies the invoice discount amount. To edit the invoice discount, click on the amount.';

                        trigger OnDrillDown()
                        begin
                            if PAGE.RunModal(PAGE::"O365 Sales Invoice Discount", Rec) = ACTION::LookupOK then
                                CurrPage.Update();
                        end;
                    }
                    field(Amount2; Amount)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        AutoFormatExpression = CurrencyFormat;
                        AutoFormatType = 11;
                        Caption = 'Net Total';
                        DrillDown = false;
                        Lookup = false;
                        ToolTip = 'Specifies the total amount on the sales invoice excluding VAT.';
                    }
                    field(AmountInclVAT2; "Amount Including VAT")
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        AutoFormatExpression = CurrencyFormat;
                        AutoFormatType = 11;
                        Caption = 'Total Including VAT';
                        DrillDown = false;
                        Importance = Promoted;
                        Lookup = false;
                        Style = Strong;
                        StyleExpr = TRUE;
                        ToolTip = 'Specifies the total amount on the sales invoice including VAT.';
                    }
                }
            }
            group("Note and attachments")
            {
                Caption = 'Note and attachments';
                Visible = FieldsVisible;
                group(Control10)
                {
                    ShowCaption = false;
                    field(WorkDescription; WorkDescription)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'Note for customer';
                        Editable = CurrPageEditable AND (CustomerName <> '');
                        MultiLine = true;
                        ToolTip = 'Specifies the products or service being offered';

                        trigger OnValidate()
                        begin
                            SetWorkDescription(WorkDescription);
                        end;
                    }
                    field(NoOfAttachments; NoOfAttachmentsValueTxt)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        DrillDown = true;
                        Editable = false;
                        Enabled = CustomerName <> '';
                        Importance = Promoted;
                        ShowCaption = false;

                        trigger OnDrillDown()
                        begin
                            O365SalesInvoiceMgmt.UpdateNoOfAttachmentsLabel(O365SalesAttachmentMgt.EditAttachments(Rec), NoOfAttachmentsValueTxt);
                            CurrPage.Update(false);
                        end;
                    }
                }
            }
        }
        area(factboxes)
        {
            part(CustomerStatisticsFactBox; "BC O365 Cust. Stats FactBox")
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Customer statistics';
                SubPageLink = "No." = FIELD("Sell-to Customer No.");
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ViewPdf)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Preview';
                Enabled = CustomerName <> '';
                Image = Document;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Show a preview of the invoice before you send it.';
                Visible = NOT IsCustomerBlocked;

                trigger OnAction()
                var
                    ReportSelections: Record "Report Selections";
                    DocumentPath: Text[250];
                begin
                    SetRecFilter;
                    LockTable();
                    Find;
                    ReportSelections.GetPdfReportForCust(DocumentPath, ReportSelections.Usage::"S.Invoice Draft", Rec, "Sell-to Customer No.");
                    Download(DocumentPath, '', '', '', DocumentPath);
                    Find;
                end;
            }
            action(SendTest)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Send test invoice';
                Enabled = CustomerName <> '';
                Image = Email;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Send the test invoice.';
                Visible = TestInvoiceVisible AND NOT IsCustomerBlocked;

                trigger OnAction()
                var
                    O365SendResendInvoice: Codeunit "O365 Send + Resend Invoice";
                begin
                    if O365SendResendInvoice.SendTestInvoiceFromBC(Rec) then begin
                        ForceExit := true;
                        CurrPage.Close;
                    end;
                end;
            }
            action(Post)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Send';
                Enabled = CustomerName <> '';
                Image = Email;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                ShortCutKey = 'Ctrl+Right';
                ToolTip = 'Finalize and send the invoice.';
                Visible = NOT TestInvoiceVisible AND NOT IsCustomerBlocked;

                trigger OnAction()
                var
                    O365SendResendInvoice: Codeunit "O365 Send + Resend Invoice";
                begin
                    if O365SendResendInvoice.SendSalesInvoiceOrQuoteFromBC(Rec) then begin
                        ForceExit := true;
                        CurrPage.Close;
                    end;
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        // Tasks shared with estimates (PAG2341)
        O365SalesInvoiceMgmt.OnAfterGetSalesHeaderRecord(Rec, CurrencyFormat, TaxAreaDescription, NoOfAttachmentsValueTxt, WorkDescription);
        CurrPageEditable := CurrPage.Editable;

        O365SalesInvoiceMgmt.UpdateCustomerFields(Rec, CustomerName, CustomerEmail, IsCompanyContact);
        O365SalesInvoiceMgmt.UpdateAddress(Rec, FullAddress, CountryRegionCode);

        O365SalesInvoiceMgmt.CalcInvoiceDiscountAmount(Rec, SubTotalAmount, DiscountTxt, InvoiceDiscountAmount, InvDiscAmountVisible);

        if ClientTypeManagement.GetCurrentClientType = CLIENTTYPE::Phone then
            FieldsVisible := CustomerName <> '';

        IsCustomerBlocked := O365SalesInvoiceMgmt.IsCustomerBlocked("Sell-to Customer No.");
        if IsCustomerBlocked then
            O365SalesInvoiceMgmt.SendCustomerHasBeenBlockedNotification("Sell-to Customer Name");

        // Invoice specific tasks
        if IsNew and TestInvoiceVisible then
            Validate(IsTest, true);
        TestInvoiceVisible := IsTest;

        CurrPage.Caption := GetInvTypeCaption;

        if TestInvoiceVisible then
            NextInvoiceNo := "No."
        else
            if SalesReceivablesSetup.Get then
                if SalesReceivablesSetup."Posted Invoice Nos." <> '' then
                    NextInvoiceNo := NoSeriesManagement.ClearStateAndGetNextNo(SalesReceivablesSetup."Posted Invoice Nos.");
#if not CLEAN19
        O365SalesInvoiceMgmt.GetPaymentInstructionsName("Payment Instructions Id", PaymentInstructionsName);
#endif
    end;

    trigger OnDeleteRecord(): Boolean
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        ForceExit := true;
        if not Find then begin
            CurrPage.Close;
            exit(false);
        end;

        if CustInvoiceDisc.Get("Invoice Disc. Code", "Currency Code", 0) then
            CustInvoiceDisc.Delete();
    end;

    trigger OnInit()
    begin
        IsDevice := ClientTypeManagement.GetCurrentClientType in [CLIENTTYPE::Tablet, CLIENTTYPE::Phone];
        FieldsVisible := true;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        CustomerName := '';
        CustomerEmail := '';
        WorkDescription := '';
        "Document Type" := "Document Type"::Invoice;
        IsNew := true;

        SetDefaultPaymentServices;
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        if not IsNew then
            ForceExit := true;

        O365SalesInvoiceMgmt.OnQueryCloseForSalesHeader(Rec, ForceExit, CustomerName);
        IsNew := false;

        exit(Next(Steps));
    end;

    trigger OnOpenPage()
    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
        NoFilter: Text;
    begin
        IsUsingVAT := O365SalesInitialSetup.IsUsingVAT;
        NoFilter := GetFilter("No.");
        if StrPos(UpperCase(NoFilter), 'TESTINVOICE') <> 0 then begin
            TestInvoiceVisible := true;
            SetFilter("No.", '');
        end;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if not IsNew then
            ForceExit := true;

        exit(O365SalesInvoiceMgmt.OnQueryCloseForSalesHeader(Rec, ForceExit, CustomerName));
    end;

    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        O365SalesAttachmentMgt: Codeunit "O365 Sales Attachment Mgt";
        ClientTypeManagement: Codeunit "Client Type Management";
        O365SalesInvoiceMgmt: Codeunit "O365 Sales Invoice Mgmt";
        NoSeriesManagement: Codeunit NoSeriesManagement;
        CustomerName: Text[100];
        CustomerEmail: Text[80];
        WorkDescription: Text;
        FullAddress: Text;
        CurrPageEditable: Boolean;
        IsUsingVAT: Boolean;
        ForceExit: Boolean;
        NoOfAttachmentsValueTxt: Text;
        CurrencyFormat: Text;
        IsCompanyContact: Boolean;
        InvDiscAmountVisible: Boolean;
        InvoiceDiscountAmount: Decimal;
        SubTotalAmount: Decimal;
        DiscountTxt: Text;
        TaxAreaDescription: Text[50];
        DocumentDatePastMsg: Label 'Invoice date is in the past.';
        ViewContactDetailsLbl: Label 'Open customer details';
        TestInvoiceVisible: Boolean;
        IsNew: Boolean;
        IsDevice: Boolean;
        CountryRegionCode: Code[10];
        PaymentInstructionsName: Text[20];
        NextInvoiceNo: Code[20];
        PickExistingCustomerLbl: Label 'Choose existing customer';
        TestInvTypeTxt: Label 'Test Invoice';
        DraftInvTypeTxt: Label 'Draft Invoice';
        IsCustomerBlocked: Boolean;
        PaymentInstrCategoryLbl: Label 'AL Payment Instructions', Locked = true;
        PaymentInstrChangedTelemetryTxt: Label 'Payment instructions were changed for an invoice.', Locked = true;
        DocumentDatePastWorkdateNotificationGuidTok: Label 'cfa9edd9-03d7-4bbb-ba07-a90660c28772', Locked = true;
        FieldsVisible: Boolean;

    procedure SuppressExitPrompt()
    begin
        ForceExit := true;
    end;

    local procedure GetInvDiscountCaption(): Text
    begin
        exit(O365SalesInvoiceMgmt.GetInvoiceDiscountCaption(Round("Invoice Discount Value", 0.1)));
    end;

    local procedure GetInvTypeCaption(): Text
    begin
        if IsTest then
            exit(TestInvTypeTxt);
        exit(DraftInvTypeTxt);
    end;
}

