#if not CLEAN21
codeunit 2104 "O365 Send + Resend Invoice"
{
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    trigger OnRun()
    begin
    end;

    var
        ThereIsNothingToSellInvoiceErr: Label 'Please add at least one line item to the invoice.';
        ThereIsNothingToSellQuoteErr: Label 'Please add at least one line item to the estimate.';
        ModifyFailedBeforePostingTelemetryMsg: Label 'Unable to set Sales Header parameters before posting.', Locked = true;
        InvoiceSendingMsg: Label 'Your invoice is being sent.';
        EstimateSendingMsg: Label 'Your estimate is being sent.';
        CannotSendCanceledDocErr: Label 'You can''t resend a canceled invoice.';
        O365SalesEmailManagement: Codeunit "O365 Sales Email Management";
        DocumentTypeNotSupportedErr: Label 'You cannot send documents of this type.';
        CustomerDoesNotExistInvoiceErr: Label 'Customer %1 cannot be found.\\To send the invoice, you must recreate the customer.', Comment = '%1 = Customer Name';
        CustomerDoesNotExistQuoteErr: Label 'Customer %1 cannot be found.\\To send the estimate, you must recreate the customer.', Comment = '%1 = Customer Name';
        ConfirmPostingZeroAmountInvoiceQst: Label 'You''re about to send an invoice that will not result in any payment. Continue?';
        ConfirmSendingZeroAmountEstimateQst: Label 'You''re about to send an estimate that will not result in any payment. Continue?';
        ConfirmConvertToInvoiceQst: Label 'Do you want to turn the estimate into a draft invoice?';
        CouponsNotValidMsg: Label 'One or more coupons are no longer valid. Remove them, and then try again.';
        NextNoSeriesUsedInvoiceErr: Label 'The next number for invoices has already been used. \ Please consult with your accountant, and then update the number sequence in settings.';
        NextNoSeriesUsedEstimateErr: Label 'The next number for estimates has already been used. \ Please consult with your accountant, and then update the number sequence in settings.';
        DraftInvoiceCategoryLbl: Label 'AL Draft Invoice', Locked = true;
        SentInvoiceCategoryLbl: Label 'AL Sent Invoice', Locked = true;
        EstimateCategoryLbl: Label 'AL Estimate', Locked = true;
        InvoiceSentTelemetryTxt: Label 'Invoice re-sent.', Locked = true;
        QuoteSentTelemetryTxt: Label 'Estimate sent.', Locked = true;
        DraftInvoiceSentTelemetryTxt: Label 'Invoice sent.', Locked = true;
        PostingAndSendingDialogMsg: Label 'We are finalizing and sending your document. This will take just a few seconds.';

    [Scope('OnPrem')]
    procedure SendOrResendSalesDocument(O365SalesDocument: Record "O365 Sales Document"): Boolean
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
    begin
        with O365SalesDocument do begin
            if Canceled then
                Error(CannotSendCanceledDocErr);

            if Posted then begin
                if not SalesInvoiceHeader.Get("No.") then
                    exit(false);
                exit(ResendSalesInvoice(SalesInvoiceHeader));
            end;

            if not SalesHeader.Get("Document Type", "No.") then
                exit(false);
            exit(SendSalesInvoiceOrOpenPage(SalesHeader, true, O365SalesDocument, true));
        end;
    end;

    [Scope('OnPrem')]
    procedure ResendSalesInvoice(SalesInvoiceHeader: Record "Sales Invoice Header"): Boolean
    begin
        with SalesInvoiceHeader do begin
            SetRecFilter();
            CODEUNIT.Run(CODEUNIT::"O365 Setup Email");

            if not O365SalesEmailManagement.ShowEmailDialog("No.") then
                exit(false);

            EmailRecords(false);
            Session.LogMessage('0000243', InvoiceSentTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SentInvoiceCategoryLbl);
            Message(InvoiceSendingMsg);
        end;

        exit(true);
    end;

    local procedure SendSalesInvoiceOrOpenPage(SalesHeader: Record "Sales Header"; OpenInvoiceIfNoItems: Boolean; O365SalesDocument: Record "O365 Sales Document"; ShowMessage: Boolean): Boolean
    var
        EmailParameter: Record "Email Parameter";
        O365SalesInvoiceMgmt: Codeunit "O365 Sales Invoice Mgmt";
        PostingProgressWindow: Dialog;
    begin
        with SalesHeader do begin
            SetRecFilter();
            if not CheckDocumentCanBeSent(SalesHeader, OpenInvoiceIfNoItems, O365SalesDocument) then
                exit(false);

            if not O365SalesEmailManagement.ShowEmailDialog("No.") then
                exit(false);

            Find();

            if EmailParameter.Get("No.", "Document Type", EmailParameter."Parameter Type"::Address) then
                O365SalesInvoiceMgmt.ValidateCustomerEmail(SalesHeader, CopyStr(EmailParameter.GetParameterValue(), 1, 80));

            case "Document Type" of
                "Document Type"::Quote:
                    begin
                        EmailRecords(false);
                        Session.LogMessage('0000244', QuoteSentTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EstimateCategoryLbl);
                        if ShowMessage then
                            Message(EstimateSendingMsg);
                    end;
                "Document Type"::Invoice:
                    begin
                        // Ensure the Invoice is marked as such in the SalesHeader, so the taxes and amounts checks are effective
                        if not (Ship and Invoice) then begin
                            Invoice := true;
                            Ship := true;
                            if not Modify(true) then
                                Session.LogMessage('000079U', ModifyFailedBeforePostingTelemetryMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SentInvoiceCategoryLbl);
                        end;

                        if GuiAllowed then begin
                            PostingProgressWindow.HideSubsequentDialogs(true);
                            PostingProgressWindow.Open('#1#################################');
                            PostingProgressWindow.Update(1, PostingAndSendingDialogMsg);
                        end;

                        SendToPosting(CODEUNIT::"Sales-Post + Email");
                        Session.LogMessage('0000245', DraftInvoiceSentTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DraftInvoiceCategoryLbl);
                        if ShowMessage then
                            Message(InvoiceSendingMsg);
                    end;
                else
                    Error(DocumentTypeNotSupportedErr);
            end;
        end;

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure SendSalesInvoiceOrQuote(SalesHeader: Record "Sales Header"): Boolean
    var
        O365SalesDocument: Record "O365 Sales Document";
    begin
        exit(SendSalesInvoiceOrOpenPage(SalesHeader, false, O365SalesDocument, true));
    end;

    [Scope('OnPrem')]
    procedure SendSalesInvoiceOrQuoteFromBC(SalesHeader: Record "Sales Header"): Boolean
    var
        O365SalesDocument: Record "O365 Sales Document";
    begin
        exit(SendSalesInvoiceOrOpenPage(SalesHeader, false, O365SalesDocument, false));
    end;

    [Scope('OnPrem')]
    procedure SendInvoiceFromQuote(SalesHeaderQuote: Record "Sales Header"; OpenInvoiceIfNoItems: Boolean): Boolean
    var
        O365SalesDocument: Record "O365 Sales Document";
        SalesHeaderInvoice: Record "Sales Header";
    begin
        if not CheckDocumentCanBeSent(SalesHeaderQuote, OpenInvoiceIfNoItems, O365SalesDocument) then
            exit(false);

        MakeInvoiceFromQuote(SalesHeaderInvoice, SalesHeaderQuote, false);

        SendSalesInvoiceOrOpenPage(SalesHeaderInvoice, false, O365SalesDocument, true);
    end;

    procedure MakeInvoiceFromQuote(var SalesHeaderInvoice: Record "Sales Header"; SalesHeaderQuote: Record "Sales Header"; ShowConfirmDialog: Boolean): Boolean
    var
        SalesQuoteToInvoice: Codeunit "Sales-Quote to Invoice";
    begin
        if ShowConfirmDialog then
            if not Confirm(ConfirmConvertToInvoiceQst, false) then
                exit(false);

        SalesHeaderQuote.LockTable();
        SalesHeaderQuote.Find();
        SalesQuoteToInvoice.Run(SalesHeaderQuote);
        SalesQuoteToInvoice.GetSalesInvoiceHeader(SalesHeaderInvoice);
        exit(true);
    end;

    local procedure CheckDocumentCanBeSent(SalesHeader: Record "Sales Header"; OpenInvoiceIfNoItems: Boolean; O365SalesDocument: Record "O365 Sales Document"): Boolean
    var
        O365CouponClaim: Record "O365 Coupon Claim";
        Customer: Record Customer;
        Confirmed: Boolean;
        ShouldConfirm: Boolean;
    begin
        with SalesHeader do begin
            CheckDocumentIfNoItemsExists(SalesHeader, OpenInvoiceIfNoItems, O365SalesDocument);
            if not Customer.Get("Sell-to Customer No.") then
                case "Document Type" of
                    "Document Type"::Invoice:
                        Error(CustomerDoesNotExistInvoiceErr, "Sell-to Customer Name");
                    else
                        Error(CustomerDoesNotExistQuoteErr, "Sell-to Customer Name");
                end;

            CheckNextNoSeriesIsAvailable("Document Type"::Invoice.AsInteger());

            // Verify all coupons are still valid
            O365CouponClaim.SetRange("Document Type Filter", "Document Type");
            O365CouponClaim.SetRange("Document No. Filter", "No.");
            O365CouponClaim.SetRange("Is applied", true);
            O365CouponClaim.SetRange("Is Valid", false);
            if not O365CouponClaim.IsEmpty() then begin
                Message(CouponsNotValidMsg);
                exit(false);
            end;

            CalcFields("Amount Including VAT");
            ShouldConfirm := "Amount Including VAT" = 0;
            OnCheckDocumentCanBeSentOnAfterCalcShouldConfirm(SalesHeader, ShouldConfirm);
            if ShouldConfirm then begin
                case "Document Type" of
                    "Document Type"::Invoice:
                        Confirmed := Confirm(ConfirmPostingZeroAmountInvoiceQst);
                    else
                        Confirmed := Confirm(ConfirmSendingZeroAmountEstimateQst);
                end;
                if not Confirmed then
                    exit(false);
            end;

            CODEUNIT.Run(CODEUNIT::"O365 Setup Email");
        end;

        exit(true);
    end;

    procedure CheckDocumentIfNoItemsExists(SalesHeader: Record "Sales Header"; OpenInvoiceIfNoItems: Boolean; O365SalesDocument: Record "O365 Sales Document")
    begin
        with SalesHeader do
            if not SalesLinesExist() then begin
                if OpenInvoiceIfNoItems and (O365SalesDocument."No." <> '') then
                    O365SalesDocument.OpenDocument();
                case "Document Type" of
                    "Document Type"::Invoice:
                        Error(ThereIsNothingToSellInvoiceErr);
                    else
                        Error(ThereIsNothingToSellQuoteErr);
                end;
            end;
    end;

    [Scope('OnPrem')]
    procedure SendTestInvoiceFromBC(SalesHeader: Record "Sales Header"): Boolean
    var
        O365SalesDocument: Record "O365 Sales Document";
    begin
        with SalesHeader do begin
            SetRecFilter();

            if "Document Type" <> "Document Type"::Invoice then
                exit(false);

            CheckDocumentIfNoItemsExists(SalesHeader, false, O365SalesDocument);
            CODEUNIT.Run(CODEUNIT::"O365 Setup Email");

            if not O365SalesEmailManagement.ShowEmailDialog("No.") then
                exit(false);

            EmailRecords(false);
        end;
        exit(true);
    end;

    procedure CheckNextNoSeriesIsAvailable(DocumentType: Option)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DummyO365SalesDocument: Record "O365 Sales Document";
        SalesHeader: Record "Sales Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        NoSeriesManagement: Codeunit NoSeriesManagement;
        NextNoSeries: Code[20];
    begin
        SalesReceivablesSetup.Get();

        case DocumentType of
            DummyO365SalesDocument."Document Type"::Quote:
                begin
                    NextNoSeries := NoSeriesManagement.ClearStateAndGetNextNo(SalesReceivablesSetup."Quote Nos.");
                    if SalesHeader.Get(SalesHeader."Document Type"::Quote, NextNoSeries) then
                        Error(NextNoSeriesUsedEstimateErr);
                end;
            DummyO365SalesDocument."Document Type"::Invoice:
                begin
                    NextNoSeries := NoSeriesManagement.ClearStateAndGetNextNo(SalesReceivablesSetup."Posted Invoice Nos.");
                    if SalesInvoiceHeader.Get(NextNoSeries) then
                        Error(NextNoSeriesUsedInvoiceErr);
                end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckDocumentCanBeSentOnAfterCalcShouldConfirm(SalesHeader: Record "Sales Header"; var ShouldConfirm: Boolean)
    begin
    end;
}
#endif

