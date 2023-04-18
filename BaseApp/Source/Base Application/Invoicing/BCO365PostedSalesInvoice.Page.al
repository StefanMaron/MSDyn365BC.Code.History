#if not CLEAN21
page 2313 "BC O365 Posted Sales Invoice"
{
    Caption = 'Sent Invoice';
    DataCaptionExpression = '';
    Editable = false;
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = "Sales Invoice Header";
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            group("Sell to")
            {
                Caption = 'Sell to';
                field("Sell-to Customer Name"; Rec."Sell-to Customer Name")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Customer Name';
                    ToolTip = 'Specifies the customer''s name.';
                }
                field(CustomerEmail; CustomerEmail)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Email Address';
                    ExtendedDatatype = EMail;
                }
                field("Remaining Amount"; Rec."Remaining Amount")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
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
                        ApplicationArea = Invoicing, Basic, Suite;
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
                        ApplicationArea = Invoicing, Basic, Suite;
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
                    ApplicationArea = Invoicing, Basic, Suite;
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
                    field("Sell-to Address"; Rec."Sell-to Address")
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Caption = 'Address';
                        ToolTip = 'Specifies the address where the customer is located.';
                    }
                    field("Sell-to Address 2"; Rec."Sell-to Address 2")
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Caption = 'Address 2';
                        ToolTip = 'Specifies additional address information.';
                    }
                    field("Sell-to City"; Rec."Sell-to City")
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Caption = 'City';
                        ToolTip = 'Specifies the address city.';
                    }
                    field("Sell-to Post Code"; Rec."Sell-to Post Code")
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Caption = 'Post Code';
                        ToolTip = 'Specifies the postal code.';
                    }
                    field("Sell-to County"; Rec."Sell-to County")
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Caption = 'County';
                        ToolTip = 'Specifies the address county.';
                    }
                    field("Sell-to Country/Region Code"; Rec."Sell-to Country/Region Code")
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Caption = 'Country/Region Code';
                        ToolTip = 'Specifies the address country/region.';
                    }
                }
            }
            group("Invoice Details")
            {
                Caption = 'Invoice Details';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Invoice No.';
                    ToolTip = 'Specifies the number of the record.';
                }
                field("Payment Terms Code"; Rec."Payment Terms Code")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Payment Terms';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Due Date';
                    Importance = Promoted;
                    ToolTip = 'Specifies when the posted sales invoice must be paid.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Invoice Date';
                    ToolTip = 'Specifies when the posted sales invoice was created.';
                }
                field("Tax Liable"; Rec."Tax Liable")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Customer is tax liable';
                    ToolTip = 'Specifies if the sales invoice contains sales tax.';
                    Visible = NOT IsUsingVAT;
                }
                field(TaxAreaDescription; TaxAreaDescription)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Customer tax rate';
                    ToolTip = 'Specifies the tax area code that is used to calculate and post sales tax.';
                    Visible = NOT IsUsingVAT;
                }
                field("VAT Registration No."; Rec."VAT Registration No.")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Visible = IsUsingVAT;
                }
            }
            part(Lines; "BC O365 Posted Sale Inv. Lines")
            {
                ApplicationArea = Invoicing, Basic, Suite;
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
                    field(AmountInclVAT; "Amount Including VAT")
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
            group(Control30)
            {
                Caption = 'Totals';
                Visible = DiscountVisible;
                group(Control36)
                {
                    ShowCaption = false;
                    field(SubTotalAmount; SubTotalAmount)
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        AutoFormatExpression = CurrencyFormat;
                        AutoFormatType = 11;
                        Caption = 'Subtotal';
                    }
                    field(InvoiceDiscountAmount; -InvoiceDiscountAmount)
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        AutoFormatExpression = CurrencyFormat;
                        AutoFormatType = 11;
                        CaptionClass = GetInvDiscountCaption();
                        Caption = 'Invoice Discount';
                        Enabled = false;
                        Importance = Promoted;
                        ToolTip = 'Specifies a discount amount that is deducted from the value of the Total Incl. VAT field, based on sales lines where the Allow Invoice Disc. field is selected.';
                    }
                    field(Amount2; Amount)
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        AutoFormatExpression = CurrencyFormat;
                        AutoFormatType = 11;
                        Caption = 'Net Total';
                        Enabled = false;
                        Importance = Promoted;
                        ToolTip = 'Specifies the total amount on the sales invoice excluding VAT.';
                    }
                    field("Amount Including VAT2"; Rec."Amount Including VAT")
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
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
                        ApplicationArea = Invoicing, Basic, Suite;
                        Caption = 'Note for customer';
                        Editable = false;
                        MultiLine = true;
                        ToolTip = 'Specifies the products or service being offered';
                    }
                    field(NoOfAttachments; NoOfAttachmentsValueTxt)
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
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
                ApplicationArea = Invoicing, Basic, Suite;
                Visible = NOT Cancelled;
            }
            part(CustomerStatisticsFactBox; "BC O365 Cust. Stats FactBox")
            {
                ApplicationArea = Invoicing, Basic, Suite;
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
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Register payment';
                Image = ApplyEntries;
                ToolTip = 'Pay the invoice as specified in the default Payment Registration Setup.';
                Visible = NOT IsFullyPaid AND NOT InvoiceCancelled AND (Amount <> 0) AND NOT IsCustomerBlocked;

                trigger OnAction()
                begin
                    if O365SalesInvoicePayment.MarkAsPaid("No.") then
                        CurrPage.Close();
                end;
            }
            action(ShowPayments)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'View Payments';
                Image = Navigate;
                ToolTip = 'Show a list of payments made for this invoice.';
                Visible = NOT InvoiceCancelled AND (Amount <> 0);

                trigger OnAction()
                begin
                    O365SalesInvoicePayment.ShowHistory("No.");
                end;
            }
            action(MarkAsUnpaid)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Cancel payment';
                Image = ReverseRegister;
                ToolTip = 'Cancel payment registrations for this invoice.';
                Visible = IsFullyPaid AND NOT InvoiceCancelled AND (Amount <> 0) AND NOT IsCustomerBlocked;

                trigger OnAction()
                begin
                    if O365SalesInvoicePayment.CancelSalesInvoicePayment("No.") then
                        CurrPage.Close();
                end;
            }
            action(ViewPdf)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'View PDF';
                Image = Document;
                ToolTip = 'View the final invoice as a PDF file.';

                trigger OnAction()
                var
                    ReportSelections: Record "Report Selections";
                    DocumentPath: Text[250];
                begin
                    SetRecFilter();
                    LockTable();
                    Find();
                    ReportSelections.GetPdfReportForCust(DocumentPath, ReportSelections.Usage::"S.Invoice", Rec, "Sell-to Customer No.");
                    Download(DocumentPath, '', '', '', DocumentPath);
                    Find();
                end;
            }
            action(Send)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Resend';
                Image = Email;
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
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Cancel invoice';
                Image = Cancel;
                ToolTip = 'Cancels the invoice.';
                Visible = NOT InvoiceCancelled AND NOT IsCustomerBlocked;

                trigger OnAction()
                var
                    SalesInvoiceHeader: Record "Sales Invoice Header";
                    O365SalesCancelInvoice: Codeunit "O365 Sales Cancel Invoice";
                    O365DocumentSendMgt: Codeunit "O365 Document Send Mgt";
                begin
                    if SalesInvoiceHeader.Get("No.") then begin
                        SalesInvoiceHeader.SetRecFilter();
                        O365SalesCancelInvoice.CancelInvoice(SalesInvoiceHeader);
                    end;

                    SalesInvoiceHeader.CalcFields(Cancelled);
                    if SalesInvoiceHeader.Cancelled then
                        O365DocumentSendMgt.RecallEmailFailedNotification();
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

                actionref(MarkAsPaid_Promoted; MarkAsPaid)
                {
                }
                actionref(ShowPayments_Promoted; ShowPayments)
                {
                }
                actionref(MarkAsUnpaid_Promoted; MarkAsUnpaid)
                {
                }
                actionref(ViewPdf_Promoted; ViewPdf)
                {
                }
                actionref(Send_Promoted; Send)
                {
                }
                actionref(CancelInvoice_Promoted; CancelInvoice)
                {
                }
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
        FullAddress := GetFullAddress();
        WorkDescription := GetWorkDescription();
        UpdateNoOfAttachmentsLabel(O365SalesAttachmentMgt.GetNoOfAttachments(Rec));
        InvoiceCancelled := O365SalesCancelInvoice.IsInvoiceCanceled(Rec);
        if Customer.Get("Sell-to Customer No.") then begin
            CustomerEmail := Customer."E-Mail";
            IsCustomerBlocked := Customer.IsBlocked();
        end;
        UpdateCurrencyFormat();
        if TaxArea.Get("Tax Area Code") then
            TaxAreaDescription := TaxArea.GetDescriptionInCurrentLanguageFullLength();
        TempStandardAddress.CopyFromSalesInvoiceHeaderSellTo(Rec);
        CalcInvoiceDiscount();
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
        IsUsingVAT := O365SalesInitialSetup.IsUsingVAT();
        IsDevice := ClientTypeManagement.GetCurrentClientType() in [CLIENTTYPE::Tablet, CLIENTTYPE::Phone];
    end;

    var
        O365SalesInvoiceMgmt: Codeunit "O365 Sales Invoice Mgmt";
        O365SalesInvoicePayment: Codeunit "O365 Sales Invoice Payment";
        O365SalesCancelInvoice: Codeunit "O365 Sales Cancel Invoice";
        ClientTypeManagement: Codeunit "Client Type Management";
        O365SalesAttachmentMgt: Codeunit "O365 Sales Attachment Mgt";
        O365SalesManagement: Codeunit "O365 Sales Management";
        WorkDescription: Text;
        NoOfAttachmentsValueTxt: Text;
        CustomerEmail: Text;
        CurrencyFormat: Text;
        InvoiceDiscountAmount: Decimal;
        AddAttachmentTxt: Label 'Add attachment';
        SubTotalAmount: Decimal;
        DiscountVisible: Boolean;
        TaxAreaDescription: Text[100];
        Status: Text;
        OutStandingStatusStyle: Text[30];
        IsDevice: Boolean;
        FullAddress: Text;

        NoOfAttachmentsTxt: Label 'Attachments (%1)', Comment = '%1=an integer number, starting at 0';
        ViewContactDetailsLbl: Label 'Open contact details';

    protected var
        InvoiceCancelled: Boolean;
        IsCustomerBlocked: Boolean;
        IsFullyPaid: Boolean;
        IsUsingVAT: Boolean;

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
            CurrencySymbol := GLSetup.GetCurrencySymbol();
        end else begin
            if Currency.Get("Currency Code") then;
            CurrencySymbol := Currency.GetCurrencySymbol();
        end;
        CurrencyFormat := StrSubstNo('%1<precision, 2:2><standard format, 0>', CurrencySymbol);
    end;

    local procedure GetFullAddress(): Text
    var
        TempStandardAddress: Record "Standard Address" temporary;
    begin
        TempStandardAddress.CopyFromSalesInvoiceHeaderSellTo(Rec);
        exit(TempStandardAddress.ToString());
    end;

    local procedure GetInvDiscountCaption(): Text
    var
        O365SalesInvoiceMgmt: Codeunit "O365 Sales Invoice Mgmt";
        DiscountPercentage: Decimal;
    begin
        CalcInvoiceDiscount();

        if SubTotalAmount = 0 then
            DiscountPercentage := 0
        else
            DiscountPercentage := (100 * InvoiceDiscountAmount) / SubTotalAmount;

        exit(O365SalesInvoiceMgmt.GetInvoiceDiscountCaption(DiscountPercentage));
    end;
}
#endif
