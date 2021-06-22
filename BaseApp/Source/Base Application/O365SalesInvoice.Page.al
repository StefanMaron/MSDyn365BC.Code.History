page 2110 "O365 Sales Invoice"
{
    Caption = 'Draft Invoice';
    DeleteAllowed = false;
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = "Sales Header";
    SourceTableView = WHERE("Document Type" = CONST(Invoice));

    layout
    {
        area(content)
        {
            group(Control25)
            {
                ShowCaption = false;
                group("Sell to")
                {
                    Caption = 'Sell to';
                    field("Sell-to Customer Name"; "Sell-to Customer Name")
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'Customer Name';
                        Editable = CurrPageEditable;
                        Importance = Promoted;
                        Lookup = true;
                        LookupPageID = "O365 Customer Lookup";
                        QuickEntry = false;
                        ShowCaption = false;
                        ToolTip = 'Specifies the customer''s name.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            if O365SalesInvoiceMgmt.LookupContactFromSalesHeader(Rec) then
                                CurrPage.Update(true);
                        end;

                        trigger OnValidate()
                        var
                            DummyCountryCode: Code[10];
                        begin
                            O365SalesInvoiceMgmt.ValidateCustomerName(Rec, CustomerName, CustomerEmail);
                            O365SalesInvoiceMgmt.UpdateAddress(Rec, FullAddress, DummyCountryCode);
                            CurrPage.Update(true);
                        end;
                    }
                    field(CustomerEmail; CustomerEmail)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'Email Address';
                        Editable = CurrPageEditable AND (CustomerName <> '');
                        ExtendedDatatype = EMail;
                        ShowCaption = false;
                        ToolTip = 'Specifies the customer''s email address.';

                        trigger OnValidate()
                        begin
                            O365SalesInvoiceMgmt.ValidateCustomerEmail(Rec, CustomerEmail);
                        end;
                    }
                }
            }
            group(Invoice)
            {
                Caption = 'Invoice Details';
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Editable = CustomerName <> '';
                    Importance = Additional;
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
                    Importance = Additional;
                    ToolTip = 'Specifies when the sales invoice was created.';

                    trigger OnValidate()
                    var
                        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
                        PastNotification: Notification;
                    begin
                        Validate("Posting Date", "Document Date");

                        if "Document Date" < WorkDate then begin
                            PastNotification.Id := CreateGuid;
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
                    Importance = Additional;
                    ToolTip = 'Specifies if the sales invoice contains sales tax.';
                    Visible = NOT IsUsingVAT;

                    trigger OnValidate()
                    begin
                        CurrPage.Update;
                    end;
                }
                field(TaxAreaDescription; TaxAreaDescription)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Customer tax rate';
                    Editable = CustomerName <> '';
                    Importance = Additional;
                    NotBlank = true;
                    ToolTip = 'Specifies the customer''s tax area.';
                    Visible = NOT IsUsingVAT;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        TaxArea: Record "Tax Area";
                    begin
                        if PAGE.RunModal(PAGE::"O365 Tax Area List", TaxArea) = ACTION::LookupOK then begin
                            Validate("Tax Area Code", TaxArea.Code);
                            TaxAreaDescription := TaxArea.GetDescriptionInCurrentLanguage;
                            CurrPage.Update;
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        CurrPage.Update;
                    end;
                }
                field("VAT Registration No."; "VAT Registration No.")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Editable = (IsUsingVAT AND IsCompanyContact);
                    Importance = Additional;
                    Visible = IsUsingVAT;
                }
                field(FullAddress; FullAddress)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Address';
                    Editable = CurrPageEditable AND (CustomerName <> '');
                    Importance = Additional;
                    QuickEntry = false;

                    trigger OnAssistEdit()
                    var
                        TempStandardAddress: Record "Standard Address" temporary;
                        DummyCountryCode: Code[10];
                    begin
                        CurrPage.SaveRecord;
                        Commit();
                        TempStandardAddress.CopyFromSalesHeaderSellTo(Rec);
                        if PAGE.RunModal(PAGE::"O365 Address", TempStandardAddress) = ACTION::LookupOK then begin
                            Find;
                            O365SalesInvoiceMgmt.UpdateAddress(Rec, FullAddress, DummyCountryCode);
                            CurrPage.Update(true);
                        end;
                    end;
                }
            }
            part(DummyLines; "O365 Sales Invoice Line Dummy")
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Line Items';
                Editable = CustomerName <> '';
                SubPageLink = "Document Type" = FIELD("Document Type"),
                              "Document No." = FIELD("No.");
                UpdatePropagation = Both;
                Visible = CustomerName = '';
            }
            part(Lines; "O365 Sales Invoice Line Subp.")
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Line Items';
                Editable = false;
                SubPageLink = "Document Type" = FIELD("Document Type"),
                              "Document No." = FIELD("No.");
                UpdatePropagation = Both;
                Visible = CustomerName <> '';
            }
            group(Control15)
            {
                ShowCaption = false;
                Visible = InvDiscAmountVisible;
                field(SubTotalAmount; SubTotalAmount)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    AutoFormatExpression = CurrencyFormat;
                    AutoFormatType = 11;
                    Caption = 'Subtotal';
                    Editable = false;
                }
                field("Invoice Discount Percent"; "Invoice Discount Value")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Discount %';
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies a discount amount that is deducted from the value in the Total Incl. VAT field. You can enter or change the amount manually.';
                }
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
                field("Amount Including VAT"; "Amount Including VAT")
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
            group(Control32)
            {
                ShowCaption = false;
                Visible = NOT InvDiscAmountVisible;
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
                field(AmountIncludingVAT2; "Amount Including VAT")
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
            group(Control12)
            {
                ShowCaption = false;
                Visible = CustomerName <> '';
                field(DiscountLink; DiscountTxt)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    DrillDown = true;
                    Editable = false;
                    Enabled = CustomerName <> '';
                    ShowCaption = false;

                    trigger OnDrillDown()
                    begin
                        if PAGE.RunModal(PAGE::"O365 Sales Invoice Discount", Rec) = ACTION::LookupOK then
                            CurrPage.Update(false);
                    end;
                }
                field(NoOfAttachments; NoOfAttachmentsValueTxt)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    DrillDown = true;
                    Editable = false;
                    Enabled = CustomerName <> '';
                    ShowCaption = false;

                    trigger OnDrillDown()
                    begin
                        O365SalesInvoiceMgmt.UpdateNoOfAttachmentsLabel(O365SalesAttachmentMgt.EditAttachments(Rec), NoOfAttachmentsValueTxt);
                        CurrPage.Update(false);
                    end;
                }
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
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Post)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Send invoice';
                Enabled = CustomerName <> '';
                Image = "Invoicing-Send";
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ShortCutKey = 'Ctrl+Right';
                ToolTip = 'Finalize and send the invoice.';

                trigger OnAction()
                var
                    O365SendResendInvoice: Codeunit "O365 Send + Resend Invoice";
                begin
                    if O365SendResendInvoice.SendSalesInvoiceOrQuote(Rec) then
                        ForceExit := true;
                end;
            }
            action(ViewPdf)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Preview invoice';
                Enabled = CustomerName <> '';
                Image = "Invoicing-View";
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'View the preview of the invoice before sending.';

                trigger OnAction()
                var
                    ReportSelections: Record "Report Selections";
                    DocumentPath: Text[250];
                begin
                    SetRecFilter;
                    LockTable();
                    Find;
                    ReportSelections.GetPdfReport(DocumentPath, ReportSelections.Usage::"S.Invoice Draft", Rec, "Sell-to Customer No.");
                    Download(DocumentPath, '', '', '', DocumentPath);
                    Find;
                end;
            }
            action(SaveForLater)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Save for later';
                Enabled = CustomerName <> '';
                Image = "Invoicing-Save";
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Close the invoice and save it for later.';

                trigger OnAction()
                begin
                    ForceExit := true;
                    CurrPage.Close;
                end;
            }
            action(DeleteAction)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Discard draft';
                Enabled = CustomerName <> '';
                Image = "Invoicing-Delete";
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Discards the draft invoice';

                trigger OnAction()
                var
                    CustInvoiceDisc: Record "Cust. Invoice Disc.";
                begin
                    if not Confirm(DeleteQst) then
                        exit;

                    ForceExit := true;

                    if CustInvoiceDisc.Get("Invoice Disc. Code", "Currency Code", 0) then
                        CustInvoiceDisc.Delete();
                    Delete(true);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        O365SalesInvoiceMgmt.UpdateCustomerFields(Rec, CustomerName, CustomerEmail, IsCompanyContact);
        CurrPageEditable := CurrPage.Editable;
        O365SalesInvoiceMgmt.OnAfterGetSalesHeaderRecord(Rec, CurrencyFormat, TaxAreaDescription, NoOfAttachmentsValueTxt, WorkDescription);
        UpdateFieldsOnAfterGetCurrRec;
    end;

    trigger OnDeleteRecord(): Boolean
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        ForceExit := true;

        if CustInvoiceDisc.Get("Invoice Disc. Code", "Currency Code", 0) then
            CustInvoiceDisc.Delete();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        "Document Type" := "Document Type"::Invoice;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        CustomerName := '';
        CustomerEmail := '';
        WorkDescription := '';
        SetDefaultPaymentServices;
    end;

    trigger OnOpenPage()
    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
        IntegrationRecord: Record "Integration Record";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        BlankRecordId: RecordID;
        IdFilter: Text;
    begin
        IsUsingVAT := O365SalesInitialSetup.IsUsingVAT;

        IdFilter := GetFilter(Id);

        if IdFilter <> '' then begin
            if not IntegrationRecord.Get(IdFilter) then
                Error(CannotFindRecordErr);

            if Format(IntegrationRecord."Record ID") = Format(BlankRecordId) then
                Error(InvoiceWasDeletedErr);

            case IntegrationRecord."Table ID" of
                DATABASE::"Sales Header":
                    ;
                DATABASE::"Sales Invoice Header":
                    begin
                        if not SalesInvoiceHeader.Get(IntegrationRecord."Record ID") then
                            Error(CannotFindRecordErr);
                        PAGE.Run(PAGE::"O365 Posted Sales Invoice", SalesInvoiceHeader);
                        Error(''); // Close the page
                    end
                else
                    Error(CannotFindRecordErr);
            end;
        end;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        exit(O365SalesInvoiceMgmt.OnQueryCloseForSalesHeader(Rec, ForceExit, CustomerName));
    end;

    var
        O365SalesAttachmentMgt: Codeunit "O365 Sales Attachment Mgt";
        O365SalesInvoiceMgmt: Codeunit "O365 Sales Invoice Mgmt";
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
        DeleteQst: Label 'Are you sure that you want to discard the invoice?';
        TaxAreaDescription: Text[50];
        CannotFindRecordErr: Label 'Cannot find that invoice.';
        InvoiceWasDeletedErr: Label 'The invoice was deleted.';
        DocumentDatePastMsg: Label 'Invoice date is in the past.';

    procedure SuppressExitPrompt()
    begin
        ForceExit := true;
    end;

    local procedure UpdateFieldsOnAfterGetCurrRec()
    var
        DummyCountryCode: Code[10];
    begin
        O365SalesInvoiceMgmt.UpdateAddress(Rec, FullAddress, DummyCountryCode);
        O365SalesInvoiceMgmt.CalcInvoiceDiscountAmount(Rec, SubTotalAmount, DiscountTxt, InvoiceDiscountAmount, InvDiscAmountVisible);
    end;
}

