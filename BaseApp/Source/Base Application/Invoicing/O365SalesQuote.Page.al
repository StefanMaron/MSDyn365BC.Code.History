#if not CLEAN21
page 2141 "O365 Sales Quote"
{
    Caption = 'Estimate';
    DeleteAllowed = false;
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = "Sales Header";
    SourceTableView = WHERE("Document Type" = CONST(Quote));
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
                        ShowMandatory = true;
                        ToolTip = 'Specifies the customer''s name.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            CurrPage.SaveRecord();
                            O365SalesInvoiceMgmt.LookupContactFromSalesHeader(Rec);
                            CurrPage.Update();
                        end;

                        trigger OnValidate()
                        var
                            Customer: Record Customer;
                            DummyCountryCode: Code[10];
                        begin
                            if not Customer.Get(Customer.GetCustNoOpenCard("Sell-to Customer Name", false, true)) then begin
                                if Customer.IsLookupRequested() then
                                    if LookupCustomerName("Sell-to Customer Name") then
                                        exit;
                                Error('');
                            end;

                            Validate("Sell-to Customer No.", Customer."No.");
                            CustomerName := Customer.Name;
                            CustomerEmail := GetCustomerEmail();
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
                    field("Quote Accepted"; Rec."Quote Accepted")
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Caption = 'Customer accepted';
                        Editable = CurrPageEditable AND (CustomerName <> '');
                        ToolTip = 'Specifies whether the customer has accepted the quote or not.';
                    }
                }
            }
            group(Quote)
            {
                Caption = 'Details';
                field("Quote Valid Until Date"; Rec."Quote Valid Until Date")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Valid until';
                    Editable = CustomerName <> '';
                    Importance = Additional;
                    ToolTip = 'Specifies how long the quote is valid.';
                }
                field("Quote Sent to Customer"; Rec."Quote Sent to Customer")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Sent';
                    Importance = Additional;
                    ToolTip = 'Specifies date and time of when the quote was sent to the customer.';
                }
                field("Quote Accepted Date"; Rec."Quote Accepted Date")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Accepted on';
                    Importance = Additional;
                    ToolTip = 'Specifies when the client accepted the quote.';
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
            group(Control16)
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
            group(Control10)
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
                    ToolTip = 'Specifies the total amount on the sales invoice excluding tax.';
                }
                field(AmountIncludingVAT2; "Amount Including VAT")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
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
                field(NoOfAttachmentsValueTxt; NoOfAttachmentsValueTxt)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
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
            action(EmailQuote)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Send estimate';
                Enabled = "Sell-to Customer Name" <> '';
                Gesture = LeftSwipe;
                Image = "Invoicing-Send";

                trigger OnAction()
                begin
                    SetRecFilter();

                    if not O365SendResendInvoice.SendSalesInvoiceOrQuote(Rec) then
                        exit;

                    Find();
                    CurrPage.Update();
                    ForceExit := true;
                    CurrPage.Close();
                end;
            }
            action(Post)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Send final invoice';
                Enabled = "Sell-to Customer Name" <> '';
                Image = PostSendTo;
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
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Turn estimate into an invoice';
                Enabled = "Sell-to Customer Name" <> '';
                Image = "Invoicing-Document";

                trigger OnAction()
                var
                    SalesHeader: Record "Sales Header";
                begin
                    if not O365SendResendInvoice.MakeInvoiceFromQuote(SalesHeader, Rec, true) then
                        exit;

                    ForceExit := true;

                    SalesHeader.SetRecFilter();
                    PAGE.Run(PAGE::"O365 Sales Invoice", SalesHeader);
                    CurrPage.Close();
                end;
            }
            action(ViewPdf)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Preview estimate';
                Enabled = "Sell-to Customer Name" <> '';
                Image = "Invoicing-View";
                ToolTip = 'View the preview of the estimate before sending.';

                trigger OnAction()
                var
                    ReportSelections: Record "Report Selections";
                    DocumentPath: Text[250];
                begin
                    SetRecFilter();
                    LockTable();
                    Find();
                    ReportSelections.GetPdfReportForCust(DocumentPath, ReportSelections.Usage::"S.Quote", Rec, "Sell-to Customer No.");
                    Download(DocumentPath, '', '', '', DocumentPath);
                    Find();
                end;
            }
            action(SaveForLater)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Save for later';
                Enabled = "Sell-to Customer Name" <> '';
                Image = "Invoicing-Save";
                ToolTip = 'Close the estimate and save it for later.';

                trigger OnAction()
                begin
                    ForceExit := true;
                    CurrPage.Close();
                end;
            }
            action(DeleteAction)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Discard estimate';
                Enabled = CustomerName <> '';
                Image = "Invoicing-Delete";
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
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(EmailQuote_Promoted; EmailQuote)
                {
                }
                actionref(Post_Promoted; Post)
                {
                }
                actionref(MakeToInvoice_Promoted; MakeToInvoice)
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
    var
        Currency: Record Currency;
        GLSetup: Record "General Ledger Setup";
        TaxArea: Record "Tax Area";
        O365DocumentSendMgt: Codeunit "O365 Document Send Mgt";
        CurrencySymbol: Text[10];
        DummyCountryCode: Code[10];
    begin
        CustomerName := "Sell-to Customer Name";
        CustomerEmail := GetCustomerEmail();
        IsCompanyContact := O365SalesInvoiceMgmt.IsCustomerCompanyContact("Sell-to Customer No.");
        WorkDescription := GetWorkDescription();
        CurrPageEditable := CurrPage.Editable;
        UpdateNoOfAttachmentsLabel(O365SalesAttachmentMgt.GetNoOfAttachments(Rec));
        SetDefaultPaymentServices();
        if "Currency Code" = '' then begin
            GLSetup.Get();
            CurrencySymbol := GLSetup.GetCurrencySymbol();
        end else begin
            if Currency.Get("Currency Code") then;
            CurrencySymbol := Currency.GetCurrencySymbol();
        end;
        CurrencyFormat := StrSubstNo('%1<precision, 2:2><standard format, 0>', CurrencySymbol);
        O365SalesInvoiceMgmt.UpdateAddress(Rec, FullAddress, DummyCountryCode);
        if ("Sell-to Customer No." = '') and ("Quote Valid Until Date" < WorkDate()) then
            "Quote Valid Until Date" := WorkDate() + 30;
        CalcInvoiceDiscountAmount();

        O365DocumentSendMgt.ShowSalesHeaderFailedNotification(Rec);

        TaxAreaDescription := '';
        if "Tax Area Code" <> '' then
            if TaxArea.Get("Tax Area Code") then
                TaxAreaDescription := TaxArea.GetDescriptionInCurrentLanguageFullLength();
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
        SetDefaultPaymentServices();
    end;

    trigger OnOpenPage()
    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
    begin
        IsUsingVAT := O365SalesInitialSetup.IsUsingVAT();
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
        TaxAreaDescription: Text[100];

    local procedure LookupCustomerName(Text: Text): Boolean
    var
        Customer: Record Customer;
        O365CustomerLookup: Page "O365 Customer Lookup";
    begin
        if Text <> '' then begin
            Customer.SetRange(Name, Text);
            if Customer.FindFirst() then;
            Customer.SetRange(Name);
        end;

        O365CustomerLookup.LookupMode(true);
        O365CustomerLookup.SetRecord(Customer);

        if O365CustomerLookup.RunModal() = ACTION::LookupOK then begin
            O365CustomerLookup.GetRecord(Customer);
            SetHideValidationDialog(true);
            CustomerName := Customer.Name;
            Validate("Sell-to Customer No.", Customer."No.");
            CustomerEmail := GetCustomerEmail();
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
#endif
