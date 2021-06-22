page 2141 "O365 Sales Quote"
{
    Caption = 'Estimate';
    DeleteAllowed = false;
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = "Sales Header";
    SourceTableView = WHERE("Document Type" = CONST(Quote));

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
                        ShowMandatory = true;
                        ToolTip = 'Specifies the customer''s name.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            CurrPage.SaveRecord;
                            O365SalesInvoiceMgmt.LookupContactFromSalesHeader(Rec);
                            CurrPage.Update;
                        end;

                        trigger OnValidate()
                        var
                            Customer: Record Customer;
                            DummyCountryCode: Code[10];
                        begin
                            if not Customer.Get(Customer.GetCustNoOpenCard("Sell-to Customer Name", false, true)) then begin
                                if Customer.IsLookupRequested then
                                    if LookupCustomerName("Sell-to Customer Name") then
                                        exit;
                                Error('');
                            end;

                            Validate("Sell-to Customer No.", Customer."No.");
                            CustomerName := Customer.Name;
                            CustomerEmail := GetCustomerEmail;
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
                    field("Quote Accepted"; "Quote Accepted")
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'Customer accepted';
                        Editable = CurrPageEditable AND (CustomerName <> '');
                        ToolTip = 'Specifies whether the customer has accepted the quote or not.';
                    }
                }
            }
            group(Quote)
            {
                Caption = 'Details';
                field("Quote Valid Until Date"; "Quote Valid Until Date")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Valid until';
                    Editable = CustomerName <> '';
                    Importance = Additional;
                    ToolTip = 'Specifies how long the quote is valid.';
                }
                field("Quote Sent to Customer"; "Quote Sent to Customer")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Sent';
                    Importance = Additional;
                    ToolTip = 'Specifies date and time of when the quote was sent to the customer.';
                }
                field("Quote Accepted Date"; "Quote Accepted Date")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Accepted on';
                    Importance = Additional;
                    ToolTip = 'Specifies when the client accepted the quote.';
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
            group(Control16)
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
                    ToolTip = 'Specifies the total amount on the sales invoice excluding tax.';
                }
                field("Amount Including VAT"; "Amount Including VAT")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    AutoFormatExpression = CurrencyFormat;
                    AutoFormatType = 11;
                    Caption = 'Total Including Tax';
                    DrillDown = false;
                    Importance = Promoted;
                    Lookup = false;
                    Style = Strong;
                    StyleExpr = TRUE;
                    ToolTip = 'Specifies the total amount on the sales invoice including tax.';
                }
            }
            group(Control10)
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
                    ToolTip = 'Specifies the total amount on the sales invoice excluding tax.';
                }
                field(AmountIncludingVAT2; "Amount Including VAT")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    AutoFormatExpression = CurrencyFormat;
                    AutoFormatType = 11;
                    Caption = 'Total Including Tax';
                    DrillDown = false;
                    Importance = Promoted;
                    Lookup = false;
                    Style = Strong;
                    StyleExpr = TRUE;
                    ToolTip = 'Specifies the total amount on the sales invoice including tax.';
                }
            }
            group(Control31)
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
                field(NoOfAttachmentsValueTxt; NoOfAttachmentsValueTxt)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    DrillDown = true;
                    Editable = false;
                    Enabled = CustomerName <> '';
                    ShowCaption = false;

                    trigger OnDrillDown()
                    begin
                        UpdateNoOfAttachmentsLabel(O365SalesAttachmentMgt.EditAttachments(Rec));
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
            action(EmailQuote)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Send estimate';
                Enabled = "Sell-to Customer Name" <> '';
                Gesture = LeftSwipe;
                Image = "Invoicing-Send";
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                begin
                    SetRecFilter;

                    if not O365SendResendInvoice.SendSalesInvoiceOrQuote(Rec) then
                        exit;

                    Find;
                    CurrPage.Update;
                    ForceExit := true;
                    CurrPage.Close;
                end;
            }
            action(Post)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Send final invoice';
                Enabled = "Sell-to Customer Name" <> '';
                Image = PostSendTo;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Finalize and send the invoice.';
                Visible = false;

                trigger OnAction()
                begin
                    ForceExit := true;
                    Commit();
                    if not O365SendResendInvoice.SendInvoiceFromQuote(Rec, false) then
                        ForceExit := false;
                end;
            }
            action(MakeToInvoice)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Turn estimate into an invoice';
                Enabled = "Sell-to Customer Name" <> '';
                Image = "Invoicing-Document";
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    SalesHeader: Record "Sales Header";
                begin
                    if not O365SendResendInvoice.MakeInvoiceFromQuote(SalesHeader, Rec, true) then
                        exit;

                    ForceExit := true;

                    SalesHeader.SetRecFilter;
                    PAGE.Run(PAGE::"O365 Sales Invoice", SalesHeader);
                    CurrPage.Close;
                end;
            }
            action(ViewPdf)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Preview estimate';
                Enabled = "Sell-to Customer Name" <> '';
                Image = "Invoicing-View";
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'View the preview of the estimate before sending.';

                trigger OnAction()
                var
                    ReportSelections: Record "Report Selections";
                    DocumentPath: Text[250];
                begin
                    SetRecFilter;
                    LockTable();
                    Find;
                    ReportSelections.GetPdfReport(DocumentPath, ReportSelections.Usage::"S.Quote", Rec, "Sell-to Customer No.");
                    Download(DocumentPath, '', '', '', DocumentPath);
                    Find;
                end;
            }
            action(SaveForLater)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Save for later';
                Enabled = "Sell-to Customer Name" <> '';
                Image = "Invoicing-Save";
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Close the estimate and save it for later.';

                trigger OnAction()
                begin
                    ForceExit := true;
                    CurrPage.Close;
                end;
            }
            action(DeleteAction)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Discard estimate';
                Enabled = CustomerName <> '';
                Image = "Invoicing-Delete";
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Discards the estimate';

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
    var
        Currency: Record Currency;
        GLSetup: Record "General Ledger Setup";
        TaxArea: Record "Tax Area";
        O365DocumentSendMgt: Codeunit "O365 Document Send Mgt";
        CurrencySymbol: Text[10];
        DummyCountryCode: Code[10];
    begin
        CustomerName := "Sell-to Customer Name";
        CustomerEmail := GetCustomerEmail;
        IsCompanyContact := O365SalesInvoiceMgmt.IsCustomerCompanyContact("Sell-to Customer No.");
        WorkDescription := GetWorkDescription;
        CurrPageEditable := CurrPage.Editable;
        UpdateNoOfAttachmentsLabel(O365SalesAttachmentMgt.GetNoOfAttachments(Rec));
        SetDefaultPaymentServices;
        if "Currency Code" = '' then begin
            GLSetup.Get();
            CurrencySymbol := GLSetup.GetCurrencySymbol;
        end else begin
            if Currency.Get("Currency Code") then;
            CurrencySymbol := Currency.GetCurrencySymbol;
        end;
        CurrencyFormat := StrSubstNo('%1<precision, 2:2><standard format, 0>', CurrencySymbol);
        O365SalesInvoiceMgmt.UpdateAddress(Rec, FullAddress, DummyCountryCode);
        if ("Sell-to Customer No." = '') and ("Quote Valid Until Date" < WorkDate) then
            "Quote Valid Until Date" := WorkDate + 30;
        CalcInvoiceDiscountAmount;

        O365DocumentSendMgt.ShowSalesHeaderFailedNotification(Rec);

        TaxAreaDescription := '';
        if "Tax Area Code" <> '' then
            if TaxArea.Get("Tax Area Code") then
                TaxAreaDescription := TaxArea.GetDescriptionInCurrentLanguage;
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
        "Document Type" := "Document Type"::Quote;
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
    begin
        IsUsingVAT := O365SalesInitialSetup.IsUsingVAT;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        exit(O365SalesInvoiceMgmt.OnQueryCloseForSalesHeader(Rec, ForceExit, CustomerName));
    end;

    var
        O365SalesAttachmentMgt: Codeunit "O365 Sales Attachment Mgt";
        O365SendResendInvoice: Codeunit "O365 Send + Resend Invoice";
        O365SalesInvoiceMgmt: Codeunit "O365 Sales Invoice Mgmt";
        CustomerName: Text[100];
        CustomerEmail: Text[80];
        WorkDescription: Text;
        FullAddress: Text;
        CurrPageEditable: Boolean;
        IsUsingVAT: Boolean;
        IsCompanyContact: Boolean;
        ForceExit: Boolean;
        NoOfAttachmentsTxt: Label 'Attachments (%1)', Comment = '%1=an integer number, starting at 0';
        InvDiscAmountVisible: Boolean;
        SubTotalAmount: Decimal;
        DiscountTxt: Text;
        NoOfAttachmentsValueTxt: Text;
        CurrencyFormat: Text;
        AddDiscountTxt: Label 'Add discount';
        ChangeDiscountTxt: Label 'Change discount';
        DeleteQst: Label 'Are you sure that you want to discard the estimate?';
        AddAttachmentTxt: Label 'Add attachment';
        TaxAreaDescription: Text[50];

    local procedure LookupCustomerName(Text: Text): Boolean
    var
        Customer: Record Customer;
        O365CustomerLookup: Page "O365 Customer Lookup";
    begin
        if Text <> '' then begin
            Customer.SetRange(Name, Text);
            if Customer.FindFirst then;
            Customer.SetRange(Name);
        end;

        O365CustomerLookup.LookupMode(true);
        O365CustomerLookup.SetRecord(Customer);

        if O365CustomerLookup.RunModal = ACTION::LookupOK then begin
            O365CustomerLookup.GetRecord(Customer);
            SetHideValidationDialog(true);
            CustomerName := Customer.Name;
            Validate("Sell-to Customer No.", Customer."No.");
            CustomerEmail := GetCustomerEmail;
            exit(true);
        end;

        exit(false);
    end;

    local procedure GetCustomerEmail(): Text[80]
    var
        Customer: Record Customer;
    begin
        if "Sell-to Customer No." <> '' then
            if Customer.Get("Sell-to Customer No.") then
                exit(Customer."E-Mail");
        exit('');
    end;

    local procedure CalcInvoiceDiscountAmount()
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", "Document Type");
        SalesLine.SetRange("Document No.", "No.");
        SalesLine.CalcSums("Inv. Discount Amount", "Line Amount");
        SubTotalAmount := SalesLine."Line Amount";
        if "Invoice Discount Value" <> 0 then
            DiscountTxt := ChangeDiscountTxt
        else
            DiscountTxt := AddDiscountTxt;

        InvDiscAmountVisible := "Invoice Discount Value" <> 0;
    end;

    procedure SuppressExitPrompt()
    begin
        ForceExit := true;
    end;

    local procedure UpdateNoOfAttachmentsLabel(NoOfAttachments: Integer)
    begin
        if NoOfAttachments = 0 then
            NoOfAttachmentsValueTxt := AddAttachmentTxt
        else
            NoOfAttachmentsValueTxt := StrSubstNo(NoOfAttachmentsTxt, NoOfAttachments);
    end;
}

