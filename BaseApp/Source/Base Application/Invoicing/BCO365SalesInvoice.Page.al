#if not CLEAN21
page 2310 "BC O365 Sales Invoice"
{
    Caption = 'Draft Invoice';
    DataCaptionExpression = '';
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = "Sales Header";
    SourceTableView = where("Document Type" = const(Invoice));
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            group(SellToWeb)
            {
                Caption = 'Sell to';
                Visible = NOT IsDevice;
                field("Sell-to Customer Name"; Rec."Sell-to Customer Name")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
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
                    ApplicationArea = Invoicing, Basic, Suite;
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
                        ApplicationArea = Invoicing, Basic, Suite;
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
                    field("Sell-to Address"; Rec."Sell-to Address")
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Caption = 'Address';
                        Editable = CustomerName <> '';
                        ToolTip = 'Specifies the address where the customer is located.';

                        trigger OnValidate()
                        begin
                            O365SalesInvoiceMgmt.ValidateCustomerAddress(Rec."Sell-to Address", Rec."Sell-to Customer No.");
                            O365SalesInvoiceMgmt.UpdateAddress(Rec, FullAddress, CountryRegionCode);
                        end;
                    }
                    field("Sell-to Address 2"; Rec."Sell-to Address 2")
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Caption = 'Address 2';
                        Editable = CustomerName <> '';
                        ToolTip = 'Specifies additional address information.';

                        trigger OnValidate()
                        begin
                            O365SalesInvoiceMgmt.ValidateCustomerAddress2(Rec."Sell-to Address 2", Rec."Sell-to Customer No.");
                            O365SalesInvoiceMgmt.UpdateAddress(Rec, FullAddress, CountryRegionCode);
                        end;
                    }
                    field("Sell-to City"; Rec."Sell-to City")
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Caption = 'City';
                        Editable = CustomerName <> '';
                        Lookup = false;
                        ToolTip = 'Specifies the address city.';

                        trigger OnValidate()
                        begin
                            O365SalesInvoiceMgmt.ValidateCustomerCity(Rec."Sell-to City", Rec."Sell-to Customer No.");
                            O365SalesInvoiceMgmt.UpdateAddress(Rec, FullAddress, CountryRegionCode);
                        end;
                    }
                    field("Sell-to Post Code"; Rec."Sell-to Post Code")
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Caption = 'Post Code';
                        Editable = CustomerName <> '';
                        Lookup = false;
                        ToolTip = 'Specifies the postal code.';

                        trigger OnValidate()
                        begin
                            O365SalesInvoiceMgmt.ValidateCustomerPostCode(Rec."Sell-to Post Code", Rec."Sell-to Customer No.");
                            O365SalesInvoiceMgmt.UpdateAddress(Rec, FullAddress, CountryRegionCode);
                        end;
                    }
                    field("Sell-to County"; Rec."Sell-to County")
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Caption = 'County';
                        Editable = CustomerName <> '';
                        Lookup = false;
                        ToolTip = 'Specifies the address county.';

                        trigger OnValidate()
                        begin
                            O365SalesInvoiceMgmt.ValidateCustomerCounty(Rec."Sell-to County", Rec."Sell-to Customer No.");
                            O365SalesInvoiceMgmt.UpdateAddress(Rec, FullAddress, CountryRegionCode);
                        end;
                    }
                    field(CountryRegionCode; CountryRegionCode)
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Caption = 'Country/Region Code';
                        Editable = CurrPageEditable AND (CustomerName <> '');
                        Lookup = true;
                        LookupPageID = "BC O365 Country/Region List";
                        TableRelation = "Country/Region";
                        ToolTip = 'Specifies the address country/region.';

                        trigger OnValidate()
                        begin
                            CountryRegionCode := O365SalesInvoiceMgmt.FindCountryCodeFromInput(CountryRegionCode);
                            Rec."Sell-to Country/Region Code" := CountryRegionCode;

                            O365SalesInvoiceMgmt.ValidateCustomerCountryRegion(Rec."Sell-to Country/Region Code", Rec."Sell-to Customer No.");
                            O365SalesInvoiceMgmt.UpdateAddress(Rec, FullAddress, CountryRegionCode);
                        end;
                    }
                }
            }
            group(SellToDevice)
            {
                Caption = 'Sell to';
                Visible = IsDevice AND NOT FieldsVisible;
                field(EnterNewSellToCustomerName; Rec."Sell-to Customer Name")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
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
                        ApplicationArea = Invoicing, Basic, Suite;
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
                field(PhoneSellToCustomerName; Rec."Sell-to Customer Name")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
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
                    ApplicationArea = Invoicing, Basic, Suite;
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
                    ApplicationArea = Invoicing, Basic, Suite;
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

                        CurrPage.SaveRecord();
                        Commit();
                        TempStandardAddress.CopyFromSalesHeaderSellTo(Rec);
                        if PAGE.RunModal(PAGE::"O365 Address", TempStandardAddress) = ACTION::LookupOK then begin
                            Rec.Find();
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
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Expected Invoice No.';
                    Editable = false;
                    ToolTip = 'Specifies the number that your next sent invoice will get.';
                }
                field("Payment Terms Code"; Rec."Payment Terms Code")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Payment Terms';
                    Editable = false;
                    Enabled = CustomerName <> '';

                    trigger OnAssistEdit()
                    var
                        TempO365PaymentTerms: Record "O365 Payment Terms" temporary;
                    begin
                        TempO365PaymentTerms.RefreshRecords();
                        if TempO365PaymentTerms.Get(Rec."Payment Terms Code") then;
                        if PAGE.RunModal(PAGE::"O365 Payment Terms List", TempO365PaymentTerms) = ACTION::LookupOK then
                            Rec.Validate("Payment Terms Code", TempO365PaymentTerms.Code);
                    end;
                }
                field(PaymentInstructionsName; PaymentInstructionsName)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Payment Instructions';
                    Editable = false;
                    Enabled = CustomerName <> '';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Editable = CustomerName <> '';
                    ToolTip = 'Specifies when the sales invoice must be paid.';

                    trigger OnValidate()
                    begin
                        if Rec."Due Date" < Rec."Document Date" then
                            Rec.Validate("Due Date", Rec."Document Date");
                    end;
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Invoice Date';
                    Editable = CustomerName <> '';
                    ToolTip = 'Specifies when the sales invoice was created.';

                    trigger OnValidate()
                    var
                        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
                        PastNotification: Notification;
                    begin
                        Rec.Validate("Posting Date", Rec."Document Date");

                        if Rec."Document Date" < WorkDate() then begin
                            PastNotification.Id := DocumentDatePastWorkdateNotificationGuidTok;
                            PastNotification.Message(DocumentDatePastMsg);
                            PastNotification.Scope(NOTIFICATIONSCOPE::LocalScope);
                            NotificationLifecycleMgt.SendNotification(PastNotification, Rec.RecordId);
                        end;
                    end;
                }
                field("Tax Liable"; Rec."Tax Liable")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
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
                    ApplicationArea = Invoicing, Basic, Suite;
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
                        if TaxArea.Get(Rec."Tax Area Code") then;
                        if PAGE.RunModal(PAGE::"O365 Tax Area List", TaxArea) = ACTION::LookupOK then begin
                            Rec.Validate("Tax Area Code", TaxArea.Code);
                            TaxAreaDescription := TaxArea.GetDescriptionInCurrentLanguageFullLength();
                            CurrPage.Update();
                        end;
                    end;
                }
                field("VAT Registration No."; Rec."VAT Registration No.")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Editable = (IsUsingVAT AND IsCompanyContact);
                    Visible = IsUsingVAT;
                }
            }
            part(Lines; "BC O365 Sales Inv. Line Subp.")
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Line Items';
                Editable = CustomerName <> '';
                Enabled = CustomerName <> '';
                SubPageLink = "Document Type" = field("Document Type"),
                              "Document No." = field("No.");
                Visible = FieldsVisible;
            }
            group(Totals)
            {
                Caption = 'Totals';
                Visible = FieldsVisible AND NOT InvDiscAmountVisible;
                group(Control39)
                {
                    ShowCaption = false;
                    field(Amount; Rec.Amount)
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        AutoFormatExpression = CurrencyFormat;
                        AutoFormatType = 11;
                        Caption = 'Net Total';
                        DrillDown = false;
                        Lookup = false;
                        ToolTip = 'Specifies the total amount on the sales invoice excluding VAT.';
                    }
                    field(AmountInclVAT; Rec."Amount Including VAT")
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
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
                        ApplicationArea = Invoicing, Basic, Suite;
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
                        ApplicationArea = Invoicing, Basic, Suite;
                        AutoFormatExpression = CurrencyFormat;
                        AutoFormatType = 11;
                        Caption = 'Subtotal';
                        Editable = false;
                        Importance = Promoted;
                    }
                    field(InvoiceDiscount; -InvoiceDiscountAmount)
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        AutoFormatExpression = CurrencyFormat;
                        AutoFormatType = 11;
                        CaptionClass = GetInvDiscountCaption();
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
                    field(Amount2; Rec.Amount)
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        AutoFormatExpression = CurrencyFormat;
                        AutoFormatType = 11;
                        Caption = 'Net Total';
                        DrillDown = false;
                        Lookup = false;
                        ToolTip = 'Specifies the total amount on the sales invoice excluding VAT.';
                    }
                    field(AmountInclVAT2; Rec."Amount Including VAT")
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
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
                        ApplicationArea = Invoicing, Basic, Suite;
                        Caption = 'Note for customer';
                        Editable = CurrPageEditable AND (CustomerName <> '');
                        MultiLine = true;
                        ToolTip = 'Specifies the products or service being offered';

                        trigger OnValidate()
                        begin
                            Rec.SetWorkDescription(WorkDescription);
                        end;
                    }
                    field(NoOfAttachments; NoOfAttachmentsValueTxt)
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
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
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Customer statistics';
                SubPageLink = "No." = field("Sell-to Customer No.");
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ViewPdf)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Preview';
                Enabled = CustomerName <> '';
                Image = Document;
                ToolTip = 'Show a preview of the invoice before you send it.';
                Visible = NOT IsCustomerBlocked;

                trigger OnAction()
                var
                    ReportSelections: Record "Report Selections";
                    DocumentPath: Text[250];
                begin
                    Rec.SetRecFilter();
                    Rec.LockTable();
                    Rec.Find();
                    ReportSelections.GetPdfReportForCust(DocumentPath, ReportSelections.Usage::"S.Invoice Draft", Rec, Rec."Sell-to Customer No.");
                    Download(DocumentPath, '', '', '', DocumentPath);
                    Rec.Find();
                end;
            }
            action(SendTest)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Send test invoice';
                Enabled = CustomerName <> '';
                Image = Email;
                ToolTip = 'Send the test invoice.';
                Visible = TestInvoiceVisible AND NOT IsCustomerBlocked;

                trigger OnAction()
                var
                    O365SendResendInvoice: Codeunit "O365 Send + Resend Invoice";
                begin
                    if O365SendResendInvoice.SendTestInvoiceFromBC(Rec) then begin
                        ForceExit := true;
                        CurrPage.Close();
                    end;
                end;
            }
            action(Post)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Send';
                Enabled = CustomerName <> '';
                Image = Email;
                ShortCutKey = 'Ctrl+Right';
                ToolTip = 'Finalize and send the invoice.';
                Visible = NOT TestInvoiceVisible AND NOT IsCustomerBlocked;

                trigger OnAction()
                var
                    O365SendResendInvoice: Codeunit "O365 Send + Resend Invoice";
                begin
                    if O365SendResendInvoice.SendSalesInvoiceOrQuoteFromBC(Rec) then begin
                        ForceExit := true;
                        CurrPage.Close();
                    end;
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Manage', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(ViewPdf_Promoted; ViewPdf)
                {
                }
                actionref(SendTest_Promoted; SendTest)
                {
                }
                actionref(Post_Promoted; Post)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        // Tasks shared with estimates (PAG2341)
        O365SalesInvoiceMgmt.OnAfterGetSalesHeaderRecordFullLengthTaxAreaDesc(Rec, CurrencyFormat, TaxAreaDescription, NoOfAttachmentsValueTxt, WorkDescription);
        CurrPageEditable := CurrPage.Editable;

        O365SalesInvoiceMgmt.UpdateCustomerFields(Rec, CustomerName, CustomerEmail, IsCompanyContact);
        O365SalesInvoiceMgmt.UpdateAddress(Rec, FullAddress, CountryRegionCode);

        O365SalesInvoiceMgmt.CalcInvoiceDiscountAmount(Rec, SubTotalAmount, DiscountTxt, InvoiceDiscountAmount, InvDiscAmountVisible);

        if ClientTypeManagement.GetCurrentClientType() = CLIENTTYPE::Phone then
            FieldsVisible := CustomerName <> '';

        IsCustomerBlocked := O365SalesInvoiceMgmt.IsCustomerBlocked(Rec."Sell-to Customer No.");
        if IsCustomerBlocked then
            O365SalesInvoiceMgmt.SendCustomerHasBeenBlockedNotification(Rec."Sell-to Customer Name");

        // Invoice specific tasks
        if IsNew and TestInvoiceVisible then
            Rec.Validate(IsTest, true);
        TestInvoiceVisible := Rec.IsTest;

        CurrPage.Caption := GetInvTypeCaption();

        if TestInvoiceVisible then
            NextInvoiceNo := Rec."No."
        else
            if SalesReceivablesSetup.Get() then
                if SalesReceivablesSetup."Posted Invoice Nos." <> '' then
                    NextInvoiceNo := NoSeriesManagement.ClearStateAndGetNextNo(SalesReceivablesSetup."Posted Invoice Nos.");
    end;

    trigger OnDeleteRecord(): Boolean
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        ForceExit := true;
        if not Rec.Find() then begin
            CurrPage.Close();
            exit(false);
        end;

        if CustInvoiceDisc.Get(Rec."Invoice Disc. Code", Rec."Currency Code", 0) then
            CustInvoiceDisc.Delete();
    end;

    trigger OnInit()
    begin
        IsDevice := ClientTypeManagement.GetCurrentClientType() in [CLIENTTYPE::Tablet, CLIENTTYPE::Phone];
        FieldsVisible := true;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        CustomerName := '';
        CustomerEmail := '';
        WorkDescription := '';
        Rec."Document Type" := Rec."Document Type"::Invoice;
        IsNew := true;

        Rec.SetDefaultPaymentServices();
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        if not IsNew then
            ForceExit := true;

        O365SalesInvoiceMgmt.OnQueryCloseForSalesHeader(Rec, ForceExit, CustomerName);
        IsNew := false;

        exit(Rec.Next(Steps));
    end;

    trigger OnOpenPage()
    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
        NoFilter: Text;
    begin
        IsUsingVAT := O365SalesInitialSetup.IsUsingVAT();
        NoFilter := Rec.GetFilter("No.");
        if StrPos(UpperCase(NoFilter), 'TESTINVOICE') <> 0 then begin
            TestInvoiceVisible := true;
            Rec.SetFilter("No.", '');
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
        TaxAreaDescription: Text[100];
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
        DocumentDatePastWorkdateNotificationGuidTok: Label 'cfa9edd9-03d7-4bbb-ba07-a90660c28772', Locked = true;
        FieldsVisible: Boolean;

    procedure SuppressExitPrompt()
    begin
        ForceExit := true;
    end;

    local procedure GetInvDiscountCaption(): Text
    begin
        exit(O365SalesInvoiceMgmt.GetInvoiceDiscountCaption(Round(Rec."Invoice Discount Value", 0.1)));
    end;

    local procedure GetInvTypeCaption(): Text
    begin
        if Rec.IsTest then
            exit(TestInvTypeTxt);
        exit(DraftInvTypeTxt);
    end;
}
#endif
