page 2313 "BC O365 Posted Sales Invoice"
{
    Caption = 'Sent Invoice';
    DataCaptionExpression = '';
    Editable = false;
    PageType = Document;
    PromotedActionCategories = 'New,Process,Report,Manage';
    RefreshOnActivate = true;
    SourceTable = "Sales Invoice Header";

    layout
    {
        area(content)
        {
            group("Sell to")
            {
                Caption = 'Sell to';
                field("Sell-to Customer Name"; "Sell-to Customer Name")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Customer Name';
                    ToolTip = 'Specifies the customer''s name.';
                }
                field(CustomerEmail; CustomerEmail)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Email Address';
                    ExtendedDatatype = EMail;
                }
                field("Remaining Amount"; "Remaining Amount")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    AutoFormatExpression = CurrencyFormat;
                    Caption = 'Outstanding Amount';
                    Enabled = false;
                    Importance = Promoted;
                }
                group(Control18)
                {
                    ShowCaption = false;
                    field(Status; Status)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        AutoFormatExpression = CurrencyFormat;
                        Caption = 'Status';
                        Enabled = false;
                        Importance = Promoted;
                        StyleExpr = OutStandingStatusStyle;
                    }
                }
                group(Control69)
                {
                    ShowCaption = false;
                    Visible = IsDevice;
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
                            TempStandardAddress.CopyFromSalesInvoiceHeaderSellTo(Rec);
                            if PAGE.RunModal(PAGE::"O365 Address", TempStandardAddress) = ACTION::LookupOK then;
                        end;
                    }
                }
                field(ViewContactCard; ViewContactDetailsLbl)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Editable = false;
                    ShowCaption = false;

                    trigger OnDrillDown()
                    var
                        Customer: Record Customer;
                    begin
                        if Customer.Get("Sell-to Customer No.") then
                            PAGE.RunModal(PAGE::"BC O365 Sales Customer Card", Customer);
                    end;
                }
                group(Control16)
                {
                    ShowCaption = false;
                    Visible = NOT IsDevice;
                    field("Sell-to Address"; "Sell-to Address")
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'Address';
                        ToolTip = 'Specifies the address where the customer is located.';
                    }
                    field("Sell-to Address 2"; "Sell-to Address 2")
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'Address 2';
                        ToolTip = 'Specifies additional address information.';
                    }
                    field("Sell-to City"; "Sell-to City")
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'City';
                        ToolTip = 'Specifies the address city.';
                    }
                    field("Sell-to Post Code"; "Sell-to Post Code")
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'Post Code';
                        ToolTip = 'Specifies the postal code.';
                    }
                    field("Sell-to County"; "Sell-to County")
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'County';
                        ToolTip = 'Specifies the address county.';
                    }
                    field("Sell-to Country/Region Code"; "Sell-to Country/Region Code")
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'Country/Region Code';
                        ToolTip = 'Specifies the address country/region.';
                    }
                }
            }
            group("Invoice Details")
            {
                Caption = 'Invoice Details';
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Invoice No.';
                    ToolTip = 'Specifies the number of the record.';
                }
                field("Payment Terms Code"; "Payment Terms Code")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Payment Terms';
                }
                field("Payment Instructions Name"; "Payment Instructions Name")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Payment Instructions';
                    ToolTip = 'Specifies how you want your customers to pay you.';
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Due Date';
                    Importance = Promoted;
                    ToolTip = 'Specifies when the posted sales invoice must be paid.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Invoice Date';
                    ToolTip = 'Specifies when the posted sales invoice was created.';
                }
                field("Tax Liable"; "Tax Liable")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Customer is tax liable';
                    ToolTip = 'Specifies if the sales invoice contains sales tax.';
                    Visible = NOT IsUsingVAT;
                }
                field(TaxAreaDescription; TaxAreaDescription)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Customer tax rate';
                    ToolTip = 'Specifies the tax area code that is used to calculate and post sales tax.';
                    Visible = NOT IsUsingVAT;
                }
                field("VAT Registration No."; "VAT Registration No.")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Visible = IsUsingVAT;
                }
            }
            part(Lines; "BC O365 Posted Sale Inv. Lines")
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Line Items';
                Editable = false;
                SubPageLink = "Document No." = FIELD("No.");
            }
            group(Totals)
            {
                Caption = 'Totals';
                Visible = NOT DiscountVisible;
                group(Control49)
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
                }
            }
            group(Control30)
            {
                Caption = 'Totals';
                Visible = DiscountVisible;
                group(Control36)
                {
                    ShowCaption = false;
                    field(SubTotalAmount; SubTotalAmount)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        AutoFormatExpression = CurrencyFormat;
                        AutoFormatType = 11;
                        Caption = 'Subtotal';
                    }
                    field(InvoiceDiscountAmount; -InvoiceDiscountAmount)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        AutoFormatExpression = CurrencyFormat;
                        AutoFormatType = 11;
                        CaptionClass = GetInvDiscountCaption;
                        Caption = 'Invoice Discount';
                        Enabled = false;
                        Importance = Promoted;
                        ToolTip = 'Specifies a discount amount that is deducted from the value in the Total Incl. VAT field. You can enter or change the amount manually.';
                    }
                    field(Amount2; Amount)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        AutoFormatExpression = CurrencyFormat;
                        AutoFormatType = 11;
                        Caption = 'Net Total';
                        Enabled = false;
                        Importance = Promoted;
                        ToolTip = 'Specifies the total amount on the sales invoice excluding VAT.';
                    }
                    field("Amount Including VAT2"; "Amount Including VAT")
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        AutoFormatExpression = CurrencyFormat;
                        AutoFormatType = 11;
                        Caption = 'Total Including VAT';
                        Enabled = false;
                        Importance = Promoted;
                        Style = Strong;
                        StyleExpr = TRUE;
                        ToolTip = 'Specifies the total amount on the sales invoice including VAT.';
                    }
                }
            }
            group("Note and attachments")
            {
                Caption = 'Note and attachments';
                group(Control42)
                {
                    ShowCaption = false;
                    field(WorkDescription; WorkDescription)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'Note for customer';
                        Editable = false;
                        MultiLine = true;
                        ToolTip = 'Specifies the products or service being offered';
                    }
                    field(NoOfAttachments; NoOfAttachmentsValueTxt)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        DrillDown = true;
                        Editable = false;
                        ShowCaption = false;

                        trigger OnDrillDown()
                        begin
                            UpdateNoOfAttachmentsLabel(O365SalesAttachmentMgt.EditAttachments(Rec));
                        end;
                    }
                }
            }
        }
        area(factboxes)
        {
            part(PaymentHistory; "O365 Payment History ListPart")
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Visible = NOT Cancelled;
            }
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
            action(MarkAsPaid)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Register payment';
                Image = ApplyEntries;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Pay the invoice as specified in the default Payment Registration Setup.';
                Visible = NOT IsFullyPaid AND NOT InvoiceCancelled AND (Amount <> 0) AND NOT IsCustomerBlocked;

                trigger OnAction()
                begin
                    if O365SalesInvoicePayment.MarkAsPaid("No.") then
                        CurrPage.Close;
                end;
            }
            action(ShowPayments)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'View Payments';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Show a list of payments made for this invoice.';
                Visible = NOT InvoiceCancelled AND (Amount <> 0);

                trigger OnAction()
                begin
                    O365SalesInvoicePayment.ShowHistory("No.");
                end;
            }
            action(MarkAsUnpaid)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Cancel payment';
                Image = ReverseRegister;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Cancel payment registrations for this invoice.';
                Visible = IsFullyPaid AND NOT InvoiceCancelled AND (Amount <> 0) AND NOT IsCustomerBlocked;

                trigger OnAction()
                begin
                    if O365SalesInvoicePayment.CancelSalesInvoicePayment("No.") then
                        CurrPage.Close;
                end;
            }
            action(ViewPdf)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'View PDF';
                Image = Document;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'View the final invoice as a PDF file.';

                trigger OnAction()
                var
                    ReportSelections: Record "Report Selections";
                    DocumentPath: Text[250];
                begin
                    SetRecFilter;
                    LockTable();
                    Find;
                    ReportSelections.GetPdfReport(DocumentPath, ReportSelections.Usage::"S.Invoice", Rec, "Sell-to Customer No.");
                    Download(DocumentPath, '', '', '', DocumentPath);
                    Find;
                end;
            }
            action(Send)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Resend';
                Image = Email;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Resend the invoice.';
                Visible = NOT InvoiceCancelled AND NOT IsCustomerBlocked;

                trigger OnAction()
                var
                    O365SendResendInvoice: Codeunit "O365 Send + Resend Invoice";
                begin
                    O365SendResendInvoice.ResendSalesInvoice(Rec);
                end;
            }
            action(CancelInvoice)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Cancel invoice';
                Image = Cancel;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Cancels the invoice.';
                Visible = NOT InvoiceCancelled AND NOT IsCustomerBlocked;

                trigger OnAction()
                var
                    SalesInvoiceHeader: Record "Sales Invoice Header";
                    O365SalesCancelInvoice: Codeunit "O365 Sales Cancel Invoice";
                    O365DocumentSendMgt: Codeunit "O365 Document Send Mgt";
                begin
                    if SalesInvoiceHeader.Get("No.") then begin
                        SalesInvoiceHeader.SetRecFilter;
                        O365SalesCancelInvoice.CancelInvoice(SalesInvoiceHeader);
                    end;

                    SalesInvoiceHeader.CalcFields(Cancelled);
                    if SalesInvoiceHeader.Cancelled then
                        O365DocumentSendMgt.RecallEmailFailedNotification;
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        DummyCustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        TaxArea: Record "Tax Area";
        TempStandardAddress: Record "Standard Address" temporary;
        O365SalesInvoicePayment: Codeunit "O365 Sales Invoice Payment";
        O365DocumentSendMgt: Codeunit "O365 Document Send Mgt";
    begin
        IsFullyPaid := O365SalesInvoicePayment.GetPaymentCustLedgerEntry(DummyCustLedgerEntry, "No.");
        FullAddress := GetFullAddress;
        WorkDescription := GetWorkDescription;
        UpdateNoOfAttachmentsLabel(O365SalesAttachmentMgt.GetNoOfAttachments(Rec));
        InvoiceCancelled := O365SalesCancelInvoice.IsInvoiceCanceled(Rec);
        if Customer.Get("Sell-to Customer No.") then begin
            CustomerEmail := Customer."E-Mail";
            IsCustomerBlocked := Customer.IsBlocked;
        end;
        UpdateCurrencyFormat;
        if TaxArea.Get("Tax Area Code") then
            TaxAreaDescription := TaxArea.GetDescriptionInCurrentLanguage;
        TempStandardAddress.CopyFromSalesInvoiceHeaderSellTo(Rec);
        CalcInvoiceDiscount;
        DiscountVisible := InvoiceDiscountAmount <> 0;
        O365DocumentSendMgt.ShowSalesInvoiceHeaderFailedNotification(Rec);
        if IsCustomerBlocked then
            O365SalesInvoiceMgmt.SendCustomerHasBeenBlockedNotification("Sell-to Customer Name");
        CurrPage.PaymentHistory.PAGE.ShowHistoryFactbox("No.");
        // CurrPage.PaymentHistory.PAGE.ACTIVATE(TRUE);
    end;

    trigger OnAfterGetRecord()
    begin
        O365SalesManagement.GetSalesInvoiceBrickStyleAndStatus(Rec, OutStandingStatusStyle, Status);
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        SetAutoCalcFields(Cancelled);
        exit(Find(Which));
    end;

    trigger OnInit()
    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
    begin
        IsUsingVAT := O365SalesInitialSetup.IsUsingVAT;
        IsDevice := ClientTypeManagement.GetCurrentClientType in [CLIENTTYPE::Tablet, CLIENTTYPE::Phone];
    end;

    var
        O365SalesInvoiceMgmt: Codeunit "O365 Sales Invoice Mgmt";
        O365SalesInvoicePayment: Codeunit "O365 Sales Invoice Payment";
        O365SalesCancelInvoice: Codeunit "O365 Sales Cancel Invoice";
        NoOfAttachmentsTxt: Label 'Attachments (%1)', Comment = '%1=an integer number, starting at 0';
        ClientTypeManagement: Codeunit "Client Type Management";
        O365SalesAttachmentMgt: Codeunit "O365 Sales Attachment Mgt";
        O365SalesManagement: Codeunit "O365 Sales Management";
        WorkDescription: Text;
        NoOfAttachmentsValueTxt: Text;
        CustomerEmail: Text;
        InvoiceCancelled: Boolean;
        IsFullyPaid: Boolean;
        IsUsingVAT: Boolean;
        CurrencyFormat: Text;
        InvoiceDiscountAmount: Decimal;
        AddAttachmentTxt: Label 'Add attachment';
        SubTotalAmount: Decimal;
        DiscountVisible: Boolean;
        TaxAreaDescription: Text[50];
        Status: Text;
        OutStandingStatusStyle: Text[30];
        ViewContactDetailsLbl: Label 'Open contact details';
        IsCustomerBlocked: Boolean;
        IsDevice: Boolean;
        FullAddress: Text;

    local procedure CalcInvoiceDiscount()
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", "No.");
        SalesInvoiceLine.CalcSums("Inv. Discount Amount", "Line Amount");
        InvoiceDiscountAmount := SalesInvoiceLine."Inv. Discount Amount";
        SubTotalAmount := SalesInvoiceLine."Line Amount";
    end;

    local procedure UpdateNoOfAttachmentsLabel(NoOfAttachments: Integer)
    begin
        if NoOfAttachments = 0 then
            NoOfAttachmentsValueTxt := AddAttachmentTxt
        else
            NoOfAttachmentsValueTxt := StrSubstNo(NoOfAttachmentsTxt, NoOfAttachments);
    end;

    local procedure UpdateCurrencyFormat()
    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        CurrencySymbol: Text[10];
    begin
        if "Currency Code" = '' then begin
            GLSetup.Get();
            CurrencySymbol := GLSetup.GetCurrencySymbol;
        end else begin
            if Currency.Get("Currency Code") then;
            CurrencySymbol := Currency.GetCurrencySymbol;
        end;
        CurrencyFormat := StrSubstNo('%1<precision, 2:2><standard format, 0>', CurrencySymbol);
    end;

    local procedure GetFullAddress(): Text
    var
        TempStandardAddress: Record "Standard Address" temporary;
    begin
        TempStandardAddress.CopyFromSalesInvoiceHeaderSellTo(Rec);
        exit(TempStandardAddress.ToString);
    end;

    local procedure GetInvDiscountCaption(): Text
    var
        O365SalesInvoiceMgmt: Codeunit "O365 Sales Invoice Mgmt";
        DiscountPercentage: Decimal;
    begin
        CalcInvoiceDiscount;

        if SubTotalAmount = 0 then
            DiscountPercentage := 0
        else
            DiscountPercentage := (100 * InvoiceDiscountAmount) / SubTotalAmount;

        exit(O365SalesInvoiceMgmt.GetInvoiceDiscountCaption(DiscountPercentage));
    end;
}

