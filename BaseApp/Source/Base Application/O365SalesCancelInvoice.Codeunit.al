codeunit 2103 "O365 Sales Cancel Invoice"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    begin
        SendInvoiceCancelationEmailFromJobQueue(Rec);
    end;

    var
#if not CLEAN21
        CancelPostedInvoiceQst: Label 'The invoice will be canceled and a cancelation email will be sent to the customer.\ \Do you want to continue?';
        CancelPostedInvoiceMsg: Label 'The invoice has been canceled and an email has been sent to the customer.';
        CancelingInvoiceDialogMsg: Label 'We are canceling your invoice and sending an email to your customer. We''ll be done in a moment.';
        OpenPaymentsQst: Label 'You cannot cancel an invoice that is partially or fully paid. Do you want to see payments for this invoice so you can remove them?';
        EmailNotSentErr: Label 'Customer Email does not exist. Invoice has been canceled but a cancelation email has not been sent to the customer.';
#endif
        EmailSubjectTxt: Label 'Your invoice has been canceled.';
#if not CLEAN21
        AlreadyCanceledErr: Label 'You cannot cancel this invoice because it has already been canceled.';
#endif
        GreetingTxt: Label 'Hello %1,', Comment = '%1 - customer name';
        CanceletionEmailBodyTxt: Label 'Thank you for your business. Your invoice has been canceled.';
        CancelationEmailSubjectTxt: Label 'Invoice %1 of amount %2%3, that was due on %4 has been canceled. ', Comment = '%1 = Invoice No,%2 = Currency code, %3 = Total amount including tax , %4 = Due date';
#if not CLEAN21
        SentInvoiceCategoryLbl: Label 'AL Sent Invoice', Locked = true;
        InvoiceCancelledTelemetryTxt: Label 'Invoice cancelled.', Locked = true;
#endif

#if not CLEAN21
    [Scope('OnPrem')]
    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure CancelInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        O365SalesInvoicePayment: Codeunit "O365 Sales Invoice Payment";
        GraphMail: Codeunit "Graph Mail";
        CancelingProgressWindow: Dialog;
        InvoiceWasCanceled: Boolean;
    begin
        if IsInvoiceCanceled(SalesInvoiceHeader) then
            Error(AlreadyCanceledErr);

        if IsInvoiceFullyOrPartiallyPaid(SalesInvoiceHeader) then begin
            if Confirm(OpenPaymentsQst) then
                O365SalesInvoicePayment.ShowHistory(SalesInvoiceHeader."No.");
            exit;
        end;

        CorrectPostedSalesInvoice.TestCorrectInvoiceIsAllowed(SalesInvoiceHeader, true);
        if Confirm(CancelPostedInvoiceQst) then begin
            CODEUNIT.Run(CODEUNIT::"O365 Setup Email");
            Commit();

            if GuiAllowed then begin
                CancelingProgressWindow.HideSubsequentDialogs(true);
                CancelingProgressWindow.Open('#1#################################');
                CancelingProgressWindow.Update(1, CancelingInvoiceDialogMsg);
            end;
            InvoiceWasCanceled := CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);
            CancelingProgressWindow.Close();

            if InvoiceWasCanceled then begin
                Session.LogMessage('0000242', InvoiceCancelledTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SentInvoiceCategoryLbl);

                VerifyEmailAddress(SalesInvoiceHeader);
                if GraphMail.IsEnabled() and GraphMail.HasConfiguration() then
                    SendInvoiceCancelationEmail(SalesInvoiceHeader)
                else
                    SendEmailInBackground(SalesInvoiceHeader);

                Message(CancelPostedInvoiceMsg);
            end;
        end;
    end;


    local procedure SendEmailInBackground(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.Init();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CODEUNIT::"O365 Sales Cancel Invoice";
        JobQueueEntry."Maximum No. of Attempts to Run" := 3;
        JobQueueEntry."Record ID to Process" := SalesInvoiceHeader.RecordId;
        CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry);
    end;
#endif

    [Scope('OnPrem')]
    procedure SendInvoiceCancelationEmail(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        ReportSelections: Record "Report Selections";
        Customer: Record "Customer";
        DocumentMailing: Codeunit "Document-Mailing";
        TempBlob: Codeunit "Temp Blob";
        SourceReference: RecordRef;
        RecordVariant: Variant;
        CustomerAddress: Text[250];
        ServerEmailBodyFilePath: Text[250];
        EmailBodyTxt: Text;
        AttachmentStream: InStream;
        SourceTableIDs, SourceRelationTypes : List of [Integer];
        SourceIDs: List of [Guid];
    begin
        if not IsInvoiceCanceled(SalesInvoiceHeader) then
            exit;

        RecordVariant := SalesInvoiceHeader;
        CustomerAddress := GetEmailAddress(SalesInvoiceHeader);
        EmailBodyTxt := GetEmailBody(SalesInvoiceHeader);
        ReportSelections.GetEmailBodyTextForCust(
          ServerEmailBodyFilePath, "Report Selection Usage"::"S.Invoice", RecordVariant, SalesInvoiceHeader."Bill-to Customer No.",
          CustomerAddress, EmailBodyTxt);

        TempBlob.CreateInStream(AttachmentStream);
        SourceReference := RecordVariant;

        SourceTableIDs.Add(SourceReference.Number());
        SourceIDs.Add(SourceReference.Field(SourceReference.SystemIdNo).Value());
        SourceRelationTypes.Add(Enum::"Email Relation Type"::"Primary Source".AsInteger());

        if Customer.Get(SalesInvoiceHeader."Sell-to Customer No.") then begin
            SourceTableIDs.Add(Database::Customer);
            SourceIDs.Add(Customer.SystemId);
            SourceRelationTypes.Add(Enum::"Email Relation Type"::"Related Entity".AsInteger());
        end;

        DocumentMailing.EmailFileWithSubjectAndReportUsage(
          AttachmentStream, '', ServerEmailBodyFilePath, EmailSubjectTxt, SalesInvoiceHeader."No.", CustomerAddress,
          SalesInvoiceHeader.GetDocTypeTxt(), true, 2, SourceTableIDs, SourceIDs, SourceRelationTypes);
    end;

    local procedure SendInvoiceCancelationEmailFromJobQueue(JobQueueEntry: Record "Job Queue Entry")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        if not SalesInvoiceHeader.Get(JobQueueEntry."Record ID to Process") then
            exit;

        SendInvoiceCancelationEmail(SalesInvoiceHeader);
    end;

    local procedure GetCustomerEmailAddress(SalesInvoiceHeader: Record "Sales Invoice Header"): Text[80]
    var
        Customer: Record Customer;
    begin
        if Customer.Get(SalesInvoiceHeader."Sell-to Customer No.") then
            exit(Customer."E-Mail");
    end;

    local procedure GetDocumentEmailAddress(var SalesInvoiceHeader: Record "Sales Invoice Header"): Text[250]
    var
        EmailParameter: Record "Email Parameter";
    begin
        if EmailParameter.Get(
             SalesInvoiceHeader."No.", EmailParameter."Document Type"::Invoice, EmailParameter."Parameter Type"::Address)
        then
            exit(EmailParameter."Parameter Value");
        exit('');
    end;

    procedure GetEmailAddress(var SalesInvoiceHeader: Record "Sales Invoice Header"): Text[250]
    var
        EmailAddress: Text[250];
    begin
        EmailAddress := GetDocumentEmailAddress(SalesInvoiceHeader);
        if EmailAddress <> '' then
            exit(EmailAddress);

        EmailAddress := GetCustomerEmailAddress(SalesInvoiceHeader);
        exit(EmailAddress);
    end;

    procedure GetEmailSubject(var SalesInvoiceHeader: Record "Sales Invoice Header"): Text[250]
    var
        EmailSubject: Text[250];
    begin
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        EmailSubject := StrSubstNo(
            CancelationEmailSubjectTxt, SalesInvoiceHeader."No.", ResolveCurrency(SalesInvoiceHeader."Currency Code"),
            SalesInvoiceHeader."Amount Including VAT", SalesInvoiceHeader."Due Date");
        exit(EmailSubject);
    end;

#if not CLEAN21
    local procedure IsInvoiceFullyOrPartiallyPaid(SalesInvoiceHeader: Record "Sales Invoice Header") IsPaid: Boolean
    begin
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        SalesInvoiceHeader.CalcFields("Remaining Amount");
        IsPaid := SalesInvoiceHeader."Amount Including VAT" <> SalesInvoiceHeader."Remaining Amount";
    end;
#endif

    procedure IsInvoiceCanceled(SalesInvoiceHeader: Record "Sales Invoice Header"): Boolean
    var
        CancelledDocument: Record "Cancelled Document";
    begin
        exit(CancelledDocument.FindSalesCancelledInvoice(SalesInvoiceHeader."No."));
    end;

#if not CLEAN21
    local procedure VerifyEmailAddress(SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        if GetEmailAddress(SalesInvoiceHeader) = '' then
            Error(EmailNotSentErr);
    end;
#endif

    local procedure ResolveCurrency(CurrencyCode: Code[10]): Text
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if CurrencyCode = '' then begin
            GeneralLedgerSetup.Get();
            exit(GeneralLedgerSetup."LCY Code" + ' ');
        end;
        exit(CurrencyCode + ' ');
    end;

    local procedure GetEmailBody(SalesInvoiceHeader: Record "Sales Invoice Header"): Text
    var
        CR: Text[1];
        EmailBodyTxt: Text;
    begin
        CR[1] := 10;

        // Create cancel invoice body message
        EmailBodyTxt := StrSubstNo(GreetingTxt, SalesInvoiceHeader."Sell-to Customer Name") + CR + CR + CanceletionEmailBodyTxt;

        exit(EmailBodyTxt)
    end;
}

