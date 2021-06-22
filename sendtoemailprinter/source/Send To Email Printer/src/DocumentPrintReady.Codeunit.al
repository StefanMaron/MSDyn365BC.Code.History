// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

/// <summary>
///  Handels the OnDocumentPrintReady event for Email Printers
/// </summary>
codeunit 2651 "Document Print Ready"
{
    EventSubscriberInstance = StaticAutomatic;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'OnDocumentPrintReady', '', true, true)]
    procedure OnDocumentPrintReady(ObjectType: Option "Report","Page"; ObjectId: Integer; ObjectPayload: JsonObject; DocumentStream: InStream; var Success: Boolean);
    var
        EmailPrinterSettings: Record "Email Printer Settings";
        SMTPMail: Codeunit "SMTP Mail";
        MailManagement: Codeunit "Mail Management";
        SendFrom: Text[250];
        ObjectName: JsonToken;
        DocumentType: JsonToken;
        PrinterNameToken: JsonToken;
        FileName: Text;
        PrinterName: Text[250];
        DocumentTypeParts: List of [Text];
        FileExtension: Text;
        Recipients: List of [Text];
    begin
        if Success then
            exit;

        if ObjectType <> ObjectType::Report then
            exit;

        if ObjectPayload.Get('printername', PrinterNameToken) then
            PrinterName := CopyStr(PrinterNameToken.AsValue().AsText(), 1, MaxStrLen(PrinterName));
        if not EmailPrinterSettings.Get(PrinterName) then
            exit;

        // Not thowing Error to allow fallback to browser printing
        if not SetupPrinters.IsSMTPSetup() then begin
            if GuiAllowed() then
                Message(SetupSMTPErr, PrinterName);
            SENDTRACETAG('0000BGH', EmailPrinterTelemetryCategoryTok, Verbosity::Normal, SMTPNotSetupTelemetryTxt, DataClassification::SystemMetadata);
            exit;
        end;

        if MailManagement.TryGetSenderEmailAddress(SendFrom) then
            if SendFrom = '' then begin
                if GuiAllowed() then
                    Message(FromAddressWasNotFoundErr);
                SENDTRACETAG('0000BGI', EmailPrinterTelemetryCategoryTok, Verbosity::Normal, FromAddressNotSetupTelemetryTxt, DataClassification::SystemMetadata);
                exit;
            end;

        if EmailPrinterSettings."Email Address" = '' then begin
            if GuiAllowed() then
                Message(PrinterEmailNotSetupErr, PrinterName);
            SENDTRACETAG('0000BGJ', EmailPrinterTelemetryCategoryTok, Verbosity::Normal, PrinterEmailNotSetupTelemetryTxt, DataClassification::SystemMetadata);
            exit;
        end;

        MailManagement.CheckValidEmailAddress(EmailPrinterSettings."Email Address");
        Recipients.Add(EmailPrinterSettings."Email Address");

        If ObjectPayload.Get('objectname', ObjectName) then
            FileName := ObjectName.AsValue().AsText();

        If ObjectPayload.Get('documenttype', DocumentType) then begin
            DocumentTypeParts := DocumentType.AsValue().AsText().Split('/');
            FileExtension := DocumentTypeParts.Get(DocumentTypeParts.Count());
        end;

        SMTPMail.CreateMessage('', SendFrom, Recipients, EmailPrinterSettings."Email Subject", EmailPrinterSettings."Email Body");
        SMTPMail.AddAttachmentStream(DocumentStream, FileName + '.' + FileExtension);
        if not SMTPMail.Send() then begin
            if GuiAllowed() then
                Message(SendErr, SMTPMail.GetLastSendMailErrorText());
            SENDTRACETAG('0000BGK', EmailPrinterTelemetryCategoryTok, Verbosity::Normal, NotSentTelemetryTxt, DataClassification::SystemMetadata);
            exit;
        end;

        Success := true;
        exit;
    end;

    var
        SetupPrinters: Codeunit "Setup Printers";
        SendErr: Label 'The email couldn''t be sent. %1', Comment = '%1 = a more detailed error message';
        PrinterEmailNotSetupErr: Label 'The email address of %1 printer is not configured. Please add the printer''s email address.', Comment = '%1 = Printer name.';
        FromAddressWasNotFoundErr: Label 'An email from address was not found.';
        SetupSMTPErr: Label 'To send print job to the %1 printer, you must set up SMTP.', Comment = '%1 = Printer name.';
        EmailPrinterTelemetryCategoryTok: Label 'AL Email Printer', Locked = true;
        SMTPNotSetupTelemetryTxt: Label 'SMTP is not set up.', Locked = true;
        PrinterEmailNotSetupTelemetryTxt: Label 'The email address of the printer is missing', Locked = true;
        FromAddressNotSetupTelemetryTxt: Label 'The email address of the sender is missing.', Locked = true;
        NotSentTelemetryTxt: Label 'The email has not been sent to the printer.', Locked = true;
}