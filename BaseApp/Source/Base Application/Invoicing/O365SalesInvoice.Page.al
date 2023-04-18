#if not CLEAN21
page 2110 "O365 Sales Invoice"
{
    Caption = 'Draft Invoice';
    DeleteAllowed = false;
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = "Sales Header";
    SourceTableView = WHERE("Document Type" = CONST(Invoice));
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

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
                    field("Sell-to Customer Name"; Rec."Sell-to Customer Name")
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
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
                        ApplicationArea = Invoicing, Basic, Suite;
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
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Editable = CustomerName <> '';
                    Importance = Additional;
                    ToolTip = 'Specifies when the sales invoice must be paid.';

                    trigger OnValidate()
                    begin
                        if "Due Date" < "Document Date" then
                            Validate("Due Date", "Document Date");
                    end;
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
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

                        if "Document Date" < WorkDate() then begin
                            PastNotification.Id := CreateGuid();
                            PastNotification.Message(DocumentDatePastMsg);
                            PastNotification.Scope(NOTIFICATIONSCOPE::LocalScope);
                            NotificationLifecycleMgt.SendNotification(PastNotification, RecordId);
                        end;
                    end;
                }
                field("Tax Liable"; Rec."Tax Liable")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Customer is tax liable';
                    Editable = CustomerName <> '';
                    Importance = Additional;
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
                            TaxAreaDescription := TaxArea.GetDescriptionInCurrentLanguageFullLength();
                            CurrPage.Update();
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("VAT Registration No."; Rec."VAT Registration No.")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Editable = (IsUsingVAT AND IsCompanyContact);
                    Importance = Additional;
                    Visible = IsUsingVAT;
                }
                field(FullAddress; FullAddress)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Address';
                    Editable = CurrPageEditable AND (CustomerName <> '');
                    Importance = Additional;
                    QuickEntry = false;

                    trigger OnAssistEdit()
                    var
                        TempStandardAddress: Record "Standard Address" temporary;
                        DummyCountryCode: Code[10];
                    begin
                        CurrPage.SaveRecord();
                        Commit();
                        TempStandardAddress.CopyFromSalesHeaderSellTo(Rec);
                        if PAGE.RunModal(PAGE::"O365 Address", TempStandardAddress) = ACTION::LookupOK then begin
                            Find();
                            O365SalesInvoiceMgmt.UpdateAddress(Rec, FullAddress, DummyCountryCode);
                            CurrPage.Update(true);
                        end;
                    end;
                }
            }
            part(DummyLines; "O365 Sales Invoice Line Dummy")
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Line Items';
                Editable = CustomerName <> '';
                SubPageLink = "Document Type" = FIELD("Document Type"),
                              "Document No." = FIELD("No.");
                UpdatePropagation = Both;
                Visible = CustomerName = '';
            }
            part(Lines; "O365 Sales Invoice Line Subp.")
            {
                ApplicationArea = Invoicing, Basic, Suite;
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
                    ApplicationArea = Invoicing, Basic, Suite;
                    AutoFormatExpression = CurrencyFormat;
                    AutoFormatType = 11;
                    Caption = 'Subtotal';
                    Editable = false;
                }
                field("Invoice Discount Percent"; Rec."Invoice Discount Value")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Discount %';
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies a discount amount that is deducted from the value of the Total Incl. VAT field, based on sales lines where the Allow Invoice Disc. field is selected. You can enter or change the amount manually.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    AutoFormatExpression = CurrencyFormat;
                    AutoFormatType = 11;
                    Caption = 'Net Total';
                    DrillDown = false;
                    Lookup = false;
                    ToolTip = 'Specifies the sum of amounts on all the lines in the document. This will include invoice discounts.';
                }
                field("Amount Including VAT"; Rec."Amount Including VAT")
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
                    ToolTip = 'Specifies the sum of amounts, including VAT, on all the lines in the document. This will include invoice discounts.';
                }
            }
            group(Control32)
            {
                ShowCaption = false;
                Visible = NOT InvDiscAmountVisible;
                field(Amount2; Amount)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    AutoFormatExpression = CurrencyFormat;
                    AutoFormatType = 11;
                    Caption = 'Net Total';
                    DrillDown = false;
                    Lookup = false;
                    ToolTip = 'Specifies the total amount on the sales invoice excluding VAT.';
                }
                field(AmountIncludingVAT2; "Amount Including VAT")
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
            group(Control12)
            {
                ShowCaption = false;
                Visible = CustomerName <> '';
                field(DiscountLink; DiscountTxt)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
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
                    ApplicationArea = Invoicing, Basic, Suite;
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
                    ApplicationArea = Invoicing, Basic, Suite;
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
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Send invoice';
                Enabled = CustomerName <> '';
                Image = "Invoicing-Send";
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
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Preview invoice';
                Enabled = CustomerName <> '';
                Image = "Invoicing-View";
                ToolTip = 'View the preview of the invoice before sending.';

                trigger OnAction()
                var
                    ReportSelections: Record "Report Selections";
                    DocumentPath: Text[250];
                begin
                    SetRecFilter();
                    LockTable();
                    Find();
                    ReportSelections.GetPdfReportForCust(DocumentPath, ReportSelections.Usage::"S.Invoice Draft", Rec, "Sell-to Customer No.");
                    Download(DocumentPath, '', '', '', DocumentPath);
                    Find();
                end;
            }
            action(SaveForLater)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Save for later';
                Enabled = CustomerName <> '';
                Image = "Invoicing-Save";
                ToolTip = 'Close the invoice and save it for later.';

                trigger OnAction()
                begin
                    ForceExit := true;
                    CurrPage.Close();
                end;
            }
            action(DeleteAction)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Discard draft';
                Enabled = CustomerName <> '';
                Image = "Invoicing-Delete";
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
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Post_Promoted; Post)
                {
                }
                actionref(ViewPdf_Promoted; ViewPdf)
                {
                }
                actionref(SaveForLater_Promoted; SaveForLater)
                {
                }
                actionref(DeleteAction_Promoted; DeleteAction)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        O365SalesInvoiceMgmt.UpdateCustomerFields(Rec, CustomerName, CustomerEmail, IsCompanyContact);
        CurrPageEditable := CurrPage.Editable;
        O365SalesInvoiceMgmt.OnAfterGetSalesHeaderRecordFullLengthTaxAreaDesc(Rec, CurrencyFormat, TaxAreaDescription, NoOfAttachmentsValueTxt, WorkDescription);
        UpdateFieldsOnAfterGetCurrRec();
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
        SetDefaultPaymentServices();
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
        IsCompanyContact: Boolean;
        InvDiscAmountVisible: Boolean;
        InvoiceDiscountAmount: Decimal;
        SubTotalAmount: Decimal;
        DiscountTxt: Text;
        DeleteQst: Label 'Are you sure that you want to discard the invoice?';
        TaxAreaDescription: Text[100];
        DocumentDatePastMsg: Label 'Invoice date is in the past.';

    protected var
        CurrencyFormat: Text;

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
#endif
