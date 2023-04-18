#if not CLEAN21
page 2113 "O365 Posted Sales Invoice"
{
    Caption = 'Sent Invoice';
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
                        ShowCaption = false;
                        ToolTip = 'Specifies the customer''s name.';
                    }
                    field(CustomerEmail; CustomerEmail)
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Caption = 'Email';
                        ExtendedDatatype = EMail;
                        ShowCaption = false;
                    }
                }
            }
            group("Invoice Details")
            {
                Caption = 'Invoice Details';
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Due Date';
                    ToolTip = 'Specifies when the posted sales invoice must be paid.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Invoice Date';
                    Importance = Additional;
                    ToolTip = 'Specifies when the posted sales invoice was created.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Invoice No.';
                    ToolTip = 'Specifies the number of the record.';
                }
                field("Tax Liable"; Rec."Tax Liable")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Customer is tax liable';
                    Importance = Additional;
                    ToolTip = 'Specifies if the sales invoice contains sales tax.';
                    Visible = NOT IsUsingVAT;
                }
                field(TaxAreaDescription; TaxAreaDescription)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Customer tax rate';
                    Importance = Additional;
                    ToolTip = 'Specifies the tax area code that is used to calculate and post sales tax.';
                    Visible = NOT IsUsingVAT;
                }
                field("VAT Registration No."; Rec."VAT Registration No.")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Importance = Additional;
                    Visible = IsUsingVAT;
                }
                field(FullAddress; FullAddress)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Address';
                    Importance = Additional;
                    QuickEntry = false;
                }
            }
            part(Lines; "O365 Posted Sales Inv. Lines")
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Line Items';
                SubPageLink = "Document No." = FIELD("No.");
            }
            group(Control11)
            {
                ShowCaption = false;
                Visible = DiscountVisible;
                field(SubTotalAmount; SubTotalAmount)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    AutoFormatExpression = CurrencyFormat;
                    AutoFormatType = 11;
                    Caption = 'Subtotal';
                }
                field(InvoiceDiscountAmount; InvoiceDiscountAmount)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    AutoFormatExpression = CurrencyFormat;
                    AutoFormatType = 11;
                    Caption = 'Discount';
                    Enabled = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies a discount amount that is deducted from the value of the Total Incl. VAT field, based on sales lines where the Allow Invoice Disc. field is selected.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    AutoFormatExpression = CurrencyFormat;
                    AutoFormatType = 11;
                    Caption = 'Net Total';
                    Enabled = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the total amount on the sales invoice excluding tax.';
                }
                field("Amount Including VAT"; Rec."Amount Including VAT")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    AutoFormatExpression = CurrencyFormat;
                    AutoFormatType = 11;
                    Caption = 'Total Including VAT';
                    Enabled = false;
                    Importance = Promoted;
                    Style = Strong;
                    StyleExpr = TRUE;
                    ToolTip = 'Specifies the total amount on the sales invoice including tax.';
                }
            }
            group(Control16)
            {
                ShowCaption = false;
                Visible = NOT DiscountVisible;
                field(Amount2; Amount)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    AutoFormatExpression = CurrencyFormat;
                    AutoFormatType = 11;
                    Caption = 'Net Total';
                    Enabled = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the total amount on the sales invoice excluding tax.';
                }
                field(AmountIncludingVAT2; "Amount Including VAT")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    AutoFormatExpression = CurrencyFormat;
                    AutoFormatType = 11;
                    Caption = 'Total Including VAT';
                    Enabled = false;
                    Importance = Promoted;
                    Style = Strong;
                    StyleExpr = TRUE;
                    ToolTip = 'Specifies the total amount on the sales invoice including tax.';
                }
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
            field(CouponCodes; CouponCodes)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Coupons';
                QuickEntry = false;
                ToolTip = 'Specifies the coupon codes used on this invoice.';
            }
            field(WorkDescription; WorkDescription)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Note for customer';
                Editable = false;
                Importance = Additional;
                MultiLine = true;
                ToolTip = 'Specifies the products or service being offered';
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
                Image = "Invoicing-Payment";
                ToolTip = 'Pay the invoice as specified in the default Payment Registration Setup.';
                Visible = NOT IsFullyPaid AND NOT InvoiceCancelled AND (Amount <> 0);

                trigger OnAction()
                begin
                    if O365SalesInvoicePayment.MarkAsPaid("No.") then
                        CurrPage.Close();
                end;
            }
            action(MarkAsUnpaid)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Cancel payment registration';
                Image = "Invoicing-Payment";
                ToolTip = 'Cancel payment registrations for this invoice.';
                Visible = IsFullyPaid AND NOT InvoiceCancelled AND (Amount <> 0);

                trigger OnAction()
                begin
                    if O365SalesInvoicePayment.CancelSalesInvoicePayment("No.") then
                        CurrPage.Close();
                end;
            }
            action(ShowPayments)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Show payments';
                Image = "Invoicing-ViewPayment";
                ToolTip = 'Show a list of payments made for this invoice.';
                Visible = NOT InvoiceCancelled AND (Amount <> 0);

                trigger OnAction()
                begin
                    O365SalesInvoicePayment.ShowHistory("No.");
                end;
            }
            action(CancelInvoice)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Cancel invoice';
                Image = "Invoicing-Cancel";
                ToolTip = 'Cancels the invoice.';
                Visible = NOT InvoiceCancelled;

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
            action(Send)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Resend by email';
                Image = "Invoicing-Send";
                ToolTip = 'Sends the invoice as pdf by email.';
                Visible = NOT InvoiceCancelled;

                trigger OnAction()
                var
                    O365SendResendInvoice: Codeunit "O365 Send + Resend Invoice";
                begin
                    O365SendResendInvoice.ResendSalesInvoice(Rec);
                end;
            }
            action(ViewPdf)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'View invoice';
                Image = "Invoicing-View";
                ToolTip = 'View the final invoice as pdf.';

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
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(MarkAsPaid_Promoted; MarkAsPaid)
                {
                }
                actionref(MarkAsUnpaid_Promoted; MarkAsUnpaid)
                {
                }
                actionref(ShowPayments_Promoted; ShowPayments)
                {
                }
                actionref(CancelInvoice_Promoted; CancelInvoice)
                {
                }
                actionref(Send_Promoted; Send)
                {
                }
                actionref(ViewPdf_Promoted; ViewPdf)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        DummyCustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        Currency: Record Currency;
        O365PostedCouponClaim: Record "O365 Posted Coupon Claim";
        GLSetup: Record "General Ledger Setup";
        TaxArea: Record "Tax Area";
        TempStandardAddress: Record "Standard Address" temporary;
        O365SalesInvoicePayment: Codeunit "O365 Sales Invoice Payment";
        O365DocumentSendMgt: Codeunit "O365 Document Send Mgt";
        CurrencySymbol: Text[10];
    begin
        IsFullyPaid := O365SalesInvoicePayment.GetPaymentCustLedgerEntry(DummyCustLedgerEntry, "No.");
        WorkDescription := GetWorkDescription();
        UpdateNoOfAttachmentsLabel(O365SalesAttachmentMgt.GetNoOfAttachments(Rec));
        InvoiceCancelled := O365SalesCancelInvoice.IsInvoiceCanceled(Rec);

        if Customer.Get("Sell-to Customer No.") then
            CustomerEmail := Customer."E-Mail";

        if "Currency Code" = '' then begin
            GLSetup.Get();
            CurrencySymbol := GLSetup.GetCurrencySymbol();
        end else begin
            if Currency.Get("Currency Code") then;
            CurrencySymbol := Currency.GetCurrencySymbol();
        end;
        CurrencyFormat := StrSubstNo('%1<precision, 2:2><standard format, 0>', CurrencySymbol);

        if TaxArea.Get("Tax Area Code") then
            TaxAreaDescription := TaxArea.GetDescriptionInCurrentLanguageFullLength();

        TempStandardAddress.CopyFromSalesInvoiceHeaderSellTo(Rec);
        FullAddress := TempStandardAddress.ToString();
        CalcInvoiceDiscount();
        DiscountVisible := InvoiceDiscountAmount <> 0;
        CouponCodes := O365PostedCouponClaim.GetAppliedClaimsForSalesInvoice(Rec);

        O365DocumentSendMgt.ShowSalesInvoiceHeaderFailedNotification(Rec);
    end;

    trigger OnInit()
    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
    begin
        IsUsingVAT := O365SalesInitialSetup.IsUsingVAT();
    end;

    var
        O365SalesInvoicePayment: Codeunit "O365 Sales Invoice Payment";
        O365SalesCancelInvoice: Codeunit "O365 Sales Cancel Invoice";
        NoOfAttachmentsTxt: Label 'Attachments (%1)', Comment = '%1=an integer number, starting at 0';
        O365SalesAttachmentMgt: Codeunit "O365 Sales Attachment Mgt";
        WorkDescription: Text;
        NoOfAttachmentsValueTxt: Text;
        CustomerEmail: Text;
        FullAddress: Text;
        IsFullyPaid: Boolean;
        IsUsingVAT: Boolean;
        CurrencyFormat: Text;
        InvoiceDiscountAmount: Decimal;
        AddAttachmentTxt: Label 'Add attachment';
        SubTotalAmount: Decimal;
        DiscountVisible: Boolean;
        TaxAreaDescription: Text[100];
        CouponCodes: Text;

    protected var
        InvoiceCancelled: Boolean;

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
}
#endif

