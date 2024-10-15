﻿#if not CLEAN19
codeunit 260 "Document-Mailing"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        ReportSelections: Record "Report Selections";
        O365DocumentSentHistory: Record "O365 Document Sent History";
    begin
        O365DocumentSentHistory.NewInProgressFromJobQueue(Rec);

        ReportSelections.SendEmailInBackground(Rec);
    end;

    var
        TempBlob: Codeunit "Temp Blob";
        EmailSubjectCapTxt: Label '%1 - %2 %3', Comment = '%1 = Customer Name. %2 = Document Type %3 = Invoice No.';
        ReportAsPdfFileNameMsg: Label '%1 %2.pdf', Comment = '%1 = Document Type %2 = Invoice No. or Job Number';
        SalesAdvLetterTxt: Label 'Advance Letter';
        EmailSubjectPluralCapTxt: Label '%1 - %2', Comment = '%1 = Customer Name. %2 = Document Type in plural form';
        ReportAsPdfFileNamePluralMsg: Label 'Sales %1.pdf', Comment = '%1 = Document Type in plural form';
        PdfFileNamePluralMsg: Label '%1.pdf', Comment = '%1 = Document Type in plural form';
        TestInvoiceEmailSubjectTxt: Label 'Test invoice from %1', Comment = '%1 = name of the company';
        CustomerLbl: Label '<Customer>';

    procedure EmailFile(AttachmentStream: Instream; AttachmentName: Text; HtmlBodyFilePath: Text; EmailSubject: Text; ToEmailAddress: Text; HideDialog: Boolean; EmailScenario: Enum "Email Scenario"): Boolean
    var
        TempEmailItem: Record "Email Item" temporary;
    begin
        TempEmailItem.AddAttachment(AttachmentStream, AttachmentName);
        exit(EmailFileInternal(
            TempEmailItem,
            CopyStr(HtmlBodyFilePath, 1, MaxStrLen(TempEmailItem."Body File Path")),
            CopyStr(EmailSubject, 1, MaxStrLen(TempEmailItem.Subject)),
            CopyStr(ToEmailAddress, 1, MaxStrLen(TempEmailItem."Send to")),
            '',
            '',
            HideDialog,
            -1,
            false,
            '',
            EmailScenario));
    end;

    procedure EmailFile(AttachmentStream: Instream; AttachmentName: Text; HtmlBodyFilePath: Text[250]; PostedDocNo: Code[20]; ToEmailAddress: Text[250]; EmailDocName: Text[250]; HideDialog: Boolean; ReportUsage: Integer): Boolean
    var
        TempEmailItem: Record "Email Item" temporary;
    begin
        TempEmailItem.AddAttachment(AttachmentStream, AttachmentName);
        exit(EmailFileInternal(
            TempEmailItem,
            HtmlBodyFilePath,
            '',
            ToEmailAddress,
            PostedDocNo,
            EmailDocName,
            HideDialog,
            ReportUsage,
            true,
            '',
            Enum::"Email Scenario"::Default));
    end;

    [Obsolete('Replaced by Advance Payments Localization for Czech.', '19.0')]
    procedure EmailFileFromSalesAdvLetterHeader(SalesAdvanceLetterHeader: Record "Sales Advance Letter Header"; AttachmentFilePath: Text[250])
    begin
        // NAVCZ
        with SalesAdvanceLetterHeader do
            EmailFile(AttachmentFilePath, '', '', "No.", GetToAddressFromCustomer("Bill-to Customer No."), SalesAdvLetterTxt, false, 0);
    end;

    procedure EmailFile(AttachmentStream: Instream; AttachmentName: Text; HtmlBodyFilePath: Text; EmailSubject: Text; ToEmailAddress: Text; HideDialog: Boolean; EmailScenario: Enum "Email Scenario"; SourceReference: RecordRef): Boolean
    var
        TempEmailItem: Record "Email Item" temporary;
    begin
        repeat
            TempEmailItem.AddSourceDocument(SourceReference.Number(), SourceReference.Field(SourceReference.SystemIdNo()).Value());
        until SourceReference.Next() = 0;

        TempEmailItem.AddAttachment(AttachmentStream, AttachmentName);
        exit(EmailFileInternal(
            TempEmailItem,
            CopyStr(HtmlBodyFilePath, 1, MaxStrLen(TempEmailItem."Body File Path")),
            CopyStr(EmailSubject, 1, MaxStrLen(TempEmailItem.Subject)),
            CopyStr(ToEmailAddress, 1, MaxStrLen(TempEmailItem."Send to")),
            '',
            '',
            HideDialog,
            -1,
            false,
            '',
            EmailScenario));
    end;

    procedure EmailFile(AttachmentStream: Instream; AttachmentName: Text; HtmlBodyFilePath: Text; EmailSubject: Text; ToEmailAddress: Text; HideDialog: Boolean; EmailScenario: Enum "Email Scenario"; SourceTables: List of [Integer]; SourceIDs: List of [Guid]; SourceRelationTypes: List of [Integer]): Boolean
    var
        TempEmailItem: Record "Email Item" temporary;
    begin
        TempEmailItem.SetSourceDocuments(SourceTables, SourceIDs, SourceRelationTypes);
        TempEmailItem.AddAttachment(AttachmentStream, AttachmentName);

        exit(EmailFileInternal(
            TempEmailItem,
            CopyStr(HtmlBodyFilePath, 1, MaxStrLen(TempEmailItem."Body File Path")),
            CopyStr(EmailSubject, 1, MaxStrLen(TempEmailItem.Subject)),
            CopyStr(ToEmailAddress, 1, MaxStrLen(TempEmailItem."Send to")),
            '',
            '',
            HideDialog,
            -1,
            false,
            '',
            EmailScenario));
    end;

    procedure EmailFile(AttachmentStream: Instream; AttachmentName: Text; HtmlBodyFilePath: Text[250]; PostedDocNo: Code[20]; ToEmailAddress: Text[250]; EmailDocName: Text[250]; HideDialog: Boolean; ReportUsage: Integer; SourceReference: RecordRef): Boolean
    var
        TempEmailItem: Record "Email Item" temporary;
    begin
        repeat
            TempEmailItem.AddSourceDocument(SourceReference.Number(), SourceReference.Field(SourceReference.SystemIdNo()).Value());
        until SourceReference.Next() = 0;

        TempEmailItem.AddAttachment(AttachmentStream, AttachmentName);
        exit(EmailFileInternal(
            TempEmailItem,
            HtmlBodyFilePath,
            '',
            ToEmailAddress,
            PostedDocNo,
            EmailDocName,
            HideDialog,
            ReportUsage,
            true,
            '',
            Enum::"Email Scenario"::Default));
    end;

    procedure EmailFile(AttachmentStream: Instream; AttachmentName: Text; HtmlBodyInstream: InStream; EmailSubject: Text; ToEmailAddress: Text; HideDialog: Boolean; EmailScenario: Enum "Email Scenario"; SourceTables: List of [Integer]; SourceIDs: List of [Guid]; SourceRelationTypes: List of [Integer]): Boolean
    var
        TempEmailItem: Record "Email Item" temporary;
        FileManagement: Codeunit "File Management";
        HtmlBodyFilePath: Text;
    begin
        TempEmailItem.SetSourceDocuments(SourceTables, SourceIDs, SourceRelationTypes);
        TempEmailItem.AddAttachment(AttachmentStream, AttachmentName);

        HtmlBodyFilePath := FileManagement.InstreamExportToServerFile(HtmlBodyInstream, 'html');

        exit(EmailFileInternal(
            TempEmailItem,
            CopyStr(HtmlBodyFilePath, 1, MaxStrLen(TempEmailItem."Body File Path")),
            CopyStr(EmailSubject, 1, MaxStrLen(TempEmailItem.Subject)),
            CopyStr(ToEmailAddress, 1, MaxStrLen(TempEmailItem."Send to")),
            '',
            '',
            HideDialog,
            -1,
            false,
            '',
            EmailScenario));
    end;

    procedure EmailFile(AttachmentStream: Instream; AttachmentName: Text; HtmlBodyFilePath: Text[250]; PostedDocNo: Code[20]; ToEmailAddress: Text[250]; EmailDocName: Text[250]; HideDialog: Boolean; ReportUsage: Integer; SourceTables: List of [Integer]; SourceIDs: List of [Guid]; SourceRelationTypes: List of [Integer]): Boolean
    var
        TempEmailItem: Record "Email Item" temporary;
    begin
        TempEmailItem.SetSourceDocuments(SourceTables, SourceIDs, SourceRelationTypes);
        TempEmailItem.AddAttachment(AttachmentStream, AttachmentName);

        exit(EmailFileInternal(
            TempEmailItem,
            HtmlBodyFilePath,
            '',
            ToEmailAddress,
            PostedDocNo,
            EmailDocName,
            HideDialog,
            ReportUsage,
            true,
            '',
            Enum::"Email Scenario"::Default));
    end;

    procedure EmailFile(AttachmentStream: Instream; AttachmentName: Text; HtmlBodyInstream: Instream; PostedDocNo: Code[20]; ToEmailAddress: Text[250]; EmailDocName: Text[250]; HideDialog: Boolean; ReportUsage: Integer; SourceTables: List of [Integer]; SourceIDs: List of [Guid]; SourceRelationTypes: List of [Integer]): Boolean
    var
        TempEmailItem: Record "Email Item" temporary;
        FileManagement: Codeunit "File Management";
        HtmlBodyFilePath: Text;
    begin
        TempEmailItem.SetSourceDocuments(SourceTables, SourceIDs, SourceRelationTypes);
        TempEmailItem.AddAttachment(AttachmentStream, AttachmentName);

        HtmlBodyFilePath := FileManagement.InstreamExportToServerFile(HtmlBodyInstream, 'html');

        exit(EmailFileInternal(
            TempEmailItem,
            CopyStr(HtmlBodyFilePath, 1, MaxStrLen(TempEmailItem."Body File Path")),
            '',
            ToEmailAddress,
            PostedDocNo,
            EmailDocName,
            HideDialog,
            ReportUsage,
            true,
            '',
            Enum::"Email Scenario"::Default));
    end;

    [Scope('OnPrem')]
    [Obsolete('Replaced by an overload that supports streams.', '17.2')]
    procedure EmailFile(AttachmentFilePath: Text[250]; AttachmentFileName: Text[250]; HtmlBodyFilePath: Text[250]; PostedDocNo: Code[20]; ToEmailAddress: Text[250]; EmailDocName: Text[250]; HideDialog: Boolean; ReportUsage: Integer): Boolean
    var
        TempEmailItem: Record "Email Item" temporary;
        FileManagement: Codeunit "File Management";
        AttachmentStream: Instream;
    begin
        if AttachmentFilePath <> '' then begin
            Clear(TempBlob);
            FileManagement.BLOBImportFromServerFile(TempBlob, AttachmentFilePath);
            TempBlob.CreateInStream(AttachmentStream);
            TempEmailItem.AddAttachment(AttachmentStream, AttachmentFileName);
        end;
        exit(EmailFileInternal(
            TempEmailItem,
            HtmlBodyFilePath,
            '',
            ToEmailAddress,
            PostedDocNo,
            EmailDocName,
            HideDialog,
            ReportUsage,
            true,
            '',
            Enum::"Email Scenario"::Default));
    end;

    [Scope('OnPrem')]
    [Obsolete('Replaced by an overload that supports streams.', '17.2')]
    procedure EmailFile(AttachmentFilePath: Text; AttachmentFileName: Text; HtmlBodyFilePath: Text; EmailSubject: Text; ToEmailAddress: Text; HideDialog: Boolean; EmailScenario: Enum "Email Scenario"): Boolean
    var
        TempEmailItem: Record "Email Item" temporary;
        FileManagement: Codeunit "File Management";
        AttachmentStream: Instream;
    begin
        if AttachmentFilePath <> '' then begin
            Clear(TempBlob);
            FileManagement.BLOBImportFromServerFile(TempBlob, AttachmentFilePath);
            TempBlob.CreateInStream(AttachmentStream);
            TempEmailItem.AddAttachment(AttachmentStream, AttachmentFileName);
        end;
        exit(EmailFileInternal(
            TempEmailItem,
            CopyStr(HtmlBodyFilePath, 1, MaxStrLen(TempEmailItem."Body File Path")),
            CopyStr(EmailSubject, 1, MaxStrLen(TempEmailItem.Subject)),
            CopyStr(ToEmailAddress, 1, MaxStrLen(TempEmailItem."Send to")),
            '',
            '',
            HideDialog,
            -1,
            false,
            '',
            EmailScenario));
    end;

    [Scope('OnPrem')]
    [Obsolete('Replaced with the EmailFile function accepting Email Scenario', '17.0')]
    procedure EmailFileWithSubject(AttachmentFilePath: Text; AttachmentFileName: Text; HtmlBodyFilePath: Text; EmailSubject: Text; ToEmailAddress: Text; HideDialog: Boolean): Boolean
    var
        TempEmailItem: Record "Email Item" temporary;
    begin
#pragma warning disable AL0432
        exit(EmailFileWithSubjectAndSender(AttachmentFilePath, AttachmentFileName, HtmlBodyFilePath, EmailSubject, ToEmailAddress, HideDialog, ''));
#pragma warning restore AL0432
    end;

    [Scope('OnPrem')]
    [Obsolete('Replaced with the EmailFile function accepting Email Scenario', '17.0')]
    procedure EmailFileWithSubjectAndSender(AttachmentFilePath: Text; AttachmentFileName: Text; HtmlBodyFilePath: Text; EmailSubject: Text; ToEmailAddress: Text; HideDialog: Boolean; SenderUserID: Code[50]): Boolean
    var
        TempEmailItem: Record "Email Item" temporary;
        FileManagement: Codeunit "File Management";
        AttachmentStream: Instream;
    begin
        if AttachmentFilePath <> '' then begin
            Clear(TempBlob);
            FileManagement.BLOBImportFromServerFile(TempBlob, AttachmentFilePath);
            TempBlob.CreateInStream(AttachmentStream);
            TempEmailItem.AddAttachment(AttachmentStream, AttachmentFileName);
        end;
        exit(EmailFileInternal(
            TempEmailItem,
            CopyStr(HtmlBodyFilePath, 1, MaxStrLen(TempEmailItem."Body File Path")),
            CopyStr(EmailSubject, 1, MaxStrLen(TempEmailItem.Subject)),
            CopyStr(ToEmailAddress, 1, MaxStrLen(TempEmailItem."Send to")),
            '',
            '',
            HideDialog,
            0, // 0 is a possible value of the Report Selection Usage, it's not recommended to run this function when the feature switch is on
            false,
            SenderUserID,
            Enum::"Email Scenario"::Default));
    end;

    [Scope('OnPrem')]
    [Obsolete('Replaced by an overload that supports streams.', '17.2')]
    procedure EmailFileWithSubjectAndReportUsage(AttachmentFilePath: Text[250]; AttachmentFileName: Text[250]; HtmlBodyFilePath: Text[250]; EmailSubject: Text[250]; PostedDocNo: Code[20]; ToEmailAddress: Text[250]; EmailDocName: Text[250]; HideDialog: Boolean; ReportUsage: Integer): Boolean
    var
        TempEmailItem: Record "Email Item" temporary;
        FileManagement: Codeunit "File Management";
        AttachmentStream: Instream;
    begin
        if AttachmentFilePath <> '' then begin
            Clear(TempBlob);
            FileManagement.BLOBImportFromServerFile(TempBlob, AttachmentFilePath);
            TempBlob.CreateInStream(AttachmentStream);
            TempEmailItem.AddAttachment(AttachmentStream, AttachmentFileName);
        end;
        exit(EmailFileInternal(
            TempEmailItem,
            HtmlBodyFilePath,
            EmailSubject,
            ToEmailAddress,
            PostedDocNo,
            EmailDocName,
            HideDialog,
            ReportUsage,
            false,
            '',
            Enum::"Email Scenario"::Default));
    end;

    procedure EmailFileWithSubjectAndReportUsage(AttachmentStream: InStream; AttachmentName: Text; HtmlBodyFilePath: Text[250]; EmailSubject: Text[250]; PostedDocNo: Code[20]; ToEmailAddress: Text[250]; EmailDocName: Text[250]; HideDialog: Boolean; ReportUsage: Integer): Boolean
    var
        TempEmailItem: Record "Email Item" temporary;
    begin
        TempEmailItem.AddAttachment(AttachmentStream, AttachmentName);
        exit(EmailFileInternal(
            TempEmailItem,
            HtmlBodyFilePath,
            EmailSubject,
            ToEmailAddress,
            PostedDocNo,
            EmailDocName,
            HideDialog,
            ReportUsage,
            false,
            '',
            Enum::"Email Scenario"::Default));
    end;

    procedure EmailFileWithSubjectAndReportUsage(AttachmentStream: InStream; AttachmentName: Text; HtmlBodyFilePath: Text[250]; EmailSubject: Text[250]; PostedDocNo: Code[20]; ToEmailAddress: Text[250]; EmailDocName: Text[250]; HideDialog: Boolean; ReportUsage: Integer; SourceReference: RecordRef): Boolean
    var
        TempEmailItem: Record "Email Item" temporary;
    begin
        TempEmailItem.AddAttachment(AttachmentStream, AttachmentName);

        repeat
            TempEmailItem.AddSourceDocument(SourceReference.Number(), SourceReference.Field(SourceReference.SystemIdNo()).Value());
        until SourceReference.Next() = 0;

        exit(EmailFileInternal(
            TempEmailItem,
            HtmlBodyFilePath,
            EmailSubject,
            ToEmailAddress,
            PostedDocNo,
            EmailDocName,
            HideDialog,
            ReportUsage,
            false,
            '',
            Enum::"Email Scenario"::Default));
    end;

    procedure EmailFileWithSubjectAndReportUsage(AttachmentStream: InStream; AttachmentName: Text; HtmlBodyFilePath: Text[250]; EmailSubject: Text[250]; PostedDocNo: Code[20]; ToEmailAddress: Text[250]; EmailDocName: Text[250]; HideDialog: Boolean; ReportUsage: Integer; SourceTables: List of [Integer]; SourceIDs: List of [Guid]; SourceRelationTypes: List of [Integer]): Boolean
    var
        TempEmailItem: Record "Email Item" temporary;
    begin
        TempEmailItem.AddAttachment(AttachmentStream, AttachmentName);
        TempEmailItem.SetSourceDocuments(SourceTables, SourceIDs, SourceRelationTypes);

        exit(EmailFileInternal(
            TempEmailItem,
            HtmlBodyFilePath,
            EmailSubject,
            ToEmailAddress,
            PostedDocNo,
            EmailDocName,
            HideDialog,
            ReportUsage,
            false,
            '',
            Enum::"Email Scenario"::Default));
    end;

    procedure GetToAddressFromCustomer(BillToCustomerNo: Code[20]): Text[250]
    var
        Customer: Record Customer;
        ToAddress: Text[250];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetToAddressFromCustomer(BillToCustomerNo, ToAddress, IsHandled);
        if IsHandled then
            exit(ToAddress);

        if Customer.Get(BillToCustomerNo) then
            ToAddress := Customer."E-Mail";

        exit(ToAddress);
    end;

    procedure GetToAddressFromVendor(BuyFromVendorNo: Code[20]): Text[250]
    var
        Vendor: Record Vendor;
        ToAddress: Text[250];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetToAddressFromVendor(BuyFromVendorNo, ToAddress, IsHandled);
        if IsHandled then
            exit(ToAddress);

        if Vendor.Get(BuyFromVendorNo) then
            ToAddress := Vendor."E-Mail";

        exit(ToAddress);
    end;

    local procedure GetSenderEmail(SenderUserID: Code[50]): Text[250]
    var
        UserSetup: Record "User Setup";
    begin
        if UserSetup.Get(SenderUserID) then
            exit(UserSetup."E-Mail");
    end;

    local procedure GetSenderName(SenderUserID: Code[50]): Text[100]
    var
        User: Record User;
    begin
        User.SetRange("User Name", SenderUserID);
        if User.FindFirst and (User."Full Name" <> '') then
            exit(User."Full Name");

        exit('');
    end;

    procedure GetAttachmentFileName(var AttachmentFileName: Text[250]; PostedDocNo: Code[20]; EmailDocumentName: Text[250]; ReportUsage: Integer)
    var
        ReportSelections: Record "Report Selections";
    begin
        OnBeforeGetAttachmentFileName(AttachmentFileName, PostedDocNo, EmailDocumentName, ReportUsage);

        if AttachmentFileName = '' then
            if PostedDocNo = '' then begin
                if ReportUsage = ReportSelections.Usage::"P.Order".AsInteger() then
                    AttachmentFileName := StrSubstNo(PdfFileNamePluralMsg, EmailDocumentName)
                else
                    AttachmentFileName := StrSubstNo(ReportAsPdfFileNamePluralMsg, EmailDocumentName);
            end else
                AttachmentFileName := StrSubstNo(ReportAsPdfFileNameMsg, EmailDocumentName, PostedDocNo)
    end;

    procedure GetEmailBody(PostedDocNo: Code[20]; ReportUsage: Integer; CustomerNo: Code[20]): Text
    var
        EmailParameter: Record "Email Parameter";
        Customer: Record Customer;
        String: DotNet String;
    begin
        if Customer.Get(CustomerNo) then;

        if EmailParameter.GetParameterWithReportUsage(
            PostedDocNo, "Report Selection Usage".FromInteger(ReportUsage), EmailParameter."Parameter Type"::Body)
        then begin
            String := EmailParameter.GetParameterValue();
            exit(String.Replace(CustomerLbl, Customer.Name));
        end;
    end;

    procedure ReplaceCustomerNameWithPlaceholder(CustomerNo: Code[20]; BodyText: Text): Text
    var
        Customer: Record Customer;
        BodyTextString: DotNet String;
    begin
        BodyTextString := BodyText;
        if not Customer.Get(CustomerNo) then
            exit(BodyText);

        exit(BodyTextString.Replace(Customer.Name, CustomerLbl));
    end;

    procedure GetEmailSubject(PostedDocNo: Code[20]; EmailDocumentName: Text[250]; ReportUsage: Integer) Subject: Text[250]
    var
        EmailParameter: Record "Email Parameter";
        CompanyInformation: Record "Company Information";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetEmailSubject(PostedDocNo, EmailDocumentName, ReportUsage, Subject, IsHandled);
        if IsHandled then
            exit(Subject);

        if EmailParameter.GetParameterWithReportUsage(PostedDocNo, "Report Selection Usage".FromInteger(ReportUsage), EmailParameter."Parameter Type"::Subject) then
            exit(CopyStr(EmailParameter.GetParameterValue(), 1, 250));
        CompanyInformation.Get();
        if PostedDocNo = '' then
            Subject := CopyStr(
                StrSubstNo(EmailSubjectPluralCapTxt, CompanyInformation.Name, EmailDocumentName), 1, MaxStrLen(Subject))
        else
            Subject := CopyStr(
                StrSubstNo(EmailSubjectCapTxt, CompanyInformation.Name, EmailDocumentName, PostedDocNo), 1, MaxStrLen(Subject))
    end;

    procedure GetTestInvoiceEmailBody(CustomerNo: Code[20]): Text
    var
        O365DefaultEmailMessage: Record "O365 Default Email Message";
        Customer: Record Customer;
        String: DotNet String;
    begin
        if Customer.Get(CustomerNo) then;
        String := O365DefaultEmailMessage.GetTestInvoiceMessage();
        exit(String.Replace(CustomerLbl, Customer.Name));
    end;

    procedure GetTestInvoiceEmailSubject(): Text[250]
    var
        CompanyInformation: Record "Company Information";
    begin
        if CompanyInformation.Get() then;
        exit(StrSubstNo(TestInvoiceEmailSubjectTxt, CompanyInformation.Name));
    end;

    [Scope('OnPrem')]
    procedure SendQuoteInForeground(SalesHeader: Record "Sales Header"): Boolean
    var
        O365DocumentSentHistory: Record "O365 Document Sent History";
        ReportSelections: Record "Report Selections";
        O365SalesEmailManagement: Codeunit "O365 Sales Email Management";
    begin
        if not O365SalesEmailManagement.ShowEmailDialog(SalesHeader."No.") then
            exit;

        O365DocumentSentHistory.NewInProgressFromSalesHeader(SalesHeader);
        O365DocumentSentHistory.SetStatusAsFailed(); // In case the code below throws an error, we want to default to failed.

        if ReportSelections.SendEmailInForeground(
             SalesHeader.RecordId, SalesHeader."No.", SalesHeader.GetDocTypeTxt(), ReportSelections.Usage::"S.Quote".AsInteger(),
             true, SalesHeader."Bill-to Customer No.")
        then begin
            O365DocumentSentHistory.SetStatusAsSuccessfullyFinished();
            exit(true);
        end;

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure SendPostedInvoiceInForeground(SalesInvoiceHeader: Record "Sales Invoice Header"): Boolean
    var
        O365DocumentSentHistory: Record "O365 Document Sent History";
        ReportSelections: Record "Report Selections";
        O365SalesEmailManagement: Codeunit "O365 Sales Email Management";
    begin
        if not O365SalesEmailManagement.ShowEmailDialog(SalesInvoiceHeader."No.") then
            exit;

        O365DocumentSentHistory.NewInProgressFromSalesInvoiceHeader(SalesInvoiceHeader);
        O365DocumentSentHistory.SetStatusAsFailed(); // In case the code below throws an error, we want to default to failed.

        if ReportSelections.SendEmailInForeground(
             SalesInvoiceHeader.RecordId, SalesInvoiceHeader."No.", 'Invoice', ReportSelections.Usage::"S.Invoice".AsInteger(),
             true, SalesInvoiceHeader."Bill-to Customer No.")
        then begin
            O365DocumentSentHistory.SetStatusAsSuccessfullyFinished();
            exit(true);
        end;

        exit(false);
    end;

    // Email Item needs to be passed by var so the attachments are available
    local procedure EmailFileInternal(var TempEmailItem: Record "Email Item" temporary; HtmlBodyFilePath: Text[250]; EmailSubject: Text[250]; ToEmailAddress: Text[250]; PostedDocNo: Code[20]; EmailDocName: Text[250]; HideDialog: Boolean; ReportUsage: Integer; IsFromPostedDoc: Boolean; SenderUserID: Code[50]; EmailScenario: Enum "Email Scenario"): Boolean
    var
        OfficeMgt: Codeunit "Office Management";
        EmailScenarioMapping: Codeunit "Email Scenario Mapping";
        EmailFeature: Codeunit "Email Feature";
        Attachments: Codeunit "Temp Blob List";
        Attachment: Codeunit "Temp Blob";
        EmailSentSuccesfully: Boolean;
        IsHandled: Boolean;
        AttachmentStream: Instream;
        AttachmentNames: List of [Text];
        Name: Text[250];
    begin
        OnBeforeEmailFileInternal(TempEmailItem, HtmlBodyFilePath, EmailSubject, ToEmailAddress, PostedDocNo, EmailDocName, HideDialog, ReportUsage, IsFromPostedDoc, SenderUserID, EmailScenario);
        if not EmailFeature.IsEnabled() then
            if IsAllowedToChangeSender(SenderUserID) then begin
                TempEmailItem."From Address" := GetSenderEmail(SenderUserID);
                TempEmailItem."From Name" := GetSenderName(SenderUserID);
            end;

        TempEmailItem."Send to" := ToEmailAddress;
        TempEmailItem.AddCcBcc();

        TempEmailItem.GetAttachments(Attachments, AttachmentNames);
        // If true, that means we came from "EmailFile" call and need to get data from the document
        if IsFromPostedDoc and (Attachments.Count() > 0) then begin
            Name := CopyStr(AttachmentNames.Get(1), 1, 250);
            GetAttachmentFileName(Name, PostedDocNo, EmailDocName, ReportUsage);
            if Name <> AttachmentNames.Get(1) then
                AttachmentNames.Set(1, Name);
            EmailSubject := GetEmailSubject(PostedDocNo, EmailDocName, ReportUsage);
            TempEmailItem.AttachIncomingDocuments(PostedDocNo);
        end;

        TempEmailItem.Subject := EmailSubject;

        if HtmlBodyFilePath <> '' then begin
            TempEmailItem.Validate("Plaintext Formatted", false);
            TempEmailItem.Validate("Body File Path", HtmlBodyFilePath);
            TempEmailItem.Validate("Message Type", TempEmailItem."Message Type"::"From Email Body Template");
        end;

        IsHandled := false;
        OnBeforeSendEmail(TempEmailItem, IsFromPostedDoc, PostedDocNo, HideDialog, ReportUsage, EmailSentSuccesfully, IsHandled, EmailDocName, SenderUserID, EmailScenario);
        if IsHandled then
            exit(EmailSentSuccesfully);

        if OfficeMgt.AttachAvailable() and (Attachments.Count() > 0) then begin
            Attachments.Get(1, Attachment);
            Attachment.CreateInStream(AttachmentStream);
            OfficeMgt.AttachDocument(AttachmentStream, AttachmentNames.Get(1), TempEmailItem.GetBodyText(), TempEmailItem.Subject);
        end else
            if OfficeMgt.AttachAvailable() then
                OfficeMgt.AttachDocument(TempEmailItem.GetBodyText(), TempEmailItem.Subject);

        if not OfficeMgt.AttachAvailable() then begin
            if EmailFeature.IsEnabled() then begin
                if Enum::"Report Selection Usage".Ordinals().Contains(ReportUsage) then
                    EmailScenario := EmailScenarioMapping.FromReportSelectionUsage(Enum::"Report Selection Usage".FromInteger(ReportUsage));
                EmailSentSuccesfully := TempEmailItem.Send(HideDialog, EmailScenario)
            end else
                EmailSentSuccesfully := TempEmailItem.Send(HideDialog);
            if EmailSentSuccesfully then
                OnAfterEmailSentSuccesfully(TempEmailItem, PostedDocNo, ReportUsage);
            exit(EmailSentSuccesfully);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendEmail(var TempEmailItem: Record "Email Item" temporary; var IsFromPostedDoc: Boolean; var PostedDocNo: Code[20]; var HideDialog: Boolean; var ReportUsage: Integer; var EmailSentSuccesfully: Boolean; var IsHandled: Boolean; EmailDocName: Text[250]; SenderUserID: Code[50]; EmailScenario: Enum "Email Scenario")
    begin
    end;

    procedure EmailFileFromStream(AttachmentStream: InStream; AttachmentName: Text; Body: Text; Subject: Text; MailTo: Text; HideDialog: Boolean; ReportUsage: Integer): Boolean
    var
        TempEmailItem: Record "Email Item" temporary;
    begin
        TempEmailItem.AddAttachment(AttachmentStream, AttachmentName);
        TempEmailItem.Validate("Plaintext Formatted", true);
        TempEmailItem.SetBodyText(Body);

        exit(EmailFileInternal(
            TempEmailItem,
            '',
            CopyStr(Subject, 1, MaxStrLen(TempEmailItem.Subject)),
            CopyStr(MailTo, 1, MaxStrLen(TempEmailItem."Send to")),
            '',
            '',
            HideDialog,
            ReportUsage,
            false,
            '',
            Enum::"Email Scenario"::Default));
    end;

    procedure EmailHtmlFromStream(MailInStream: InStream; ToEmailAddress: Text[250]; Subject: Text; HideDialog: Boolean; ReportUsage: Integer): Boolean
    var
        TempEmailItem: Record "Email Item" temporary;
        FileManagement: Codeunit "File Management";
        FileName: Text;
    begin
        FileName := FileManagement.InstreamExportToServerFile(MailInStream, 'html');
        exit(EmailFileInternal(
            TempEmailItem,
            CopyStr(FileName, 1, MaxStrLen(TempEmailItem."Body File Path")),
            CopyStr(Subject, 1, MaxStrLen(TempEmailItem.Subject)),
            CopyStr(ToEmailAddress, 1, MaxStrLen(TempEmailItem."Send to")),
            '',
            '',
            HideDialog,
            ReportUsage,
            false,
            '',
            Enum::"Email Scenario"::Default));
    end;

    procedure EmailFileAndHtmlFromStream(AttachmentStream: InStream; AttachmentName: Text; MailInStream: InStream; ToEmailAddress: Text[250]; Subject: Text; HideDialog: Boolean; ReportUsage: Integer): Boolean
    begin
        EmailFileAndHtmlFromStream(AttachmentStream, AttachmentName, MailInStream, ToEmailAddress, Subject, HideDialog, ReportUsage, '', false);
    end;

    procedure EmailFileAndHtmlFromStream(AttachmentStream: InStream; AttachmentName: Text; MailInStream: InStream; ToEmailAddress: Text[250]; Subject: Text; HideDialog: Boolean; ReportUsage: Integer; PostedDocNo: Code[20]; IsFromPostedDoc: Boolean): Boolean
    var
        TempEmailItem: Record "Email Item" temporary;
        FileManagement: Codeunit "File Management";
        BodyFileName: Text;
    begin
        TempEmailItem.AddAttachment(AttachmentStream, AttachmentName);
        BodyFileName := FileManagement.InstreamExportToServerFile(MailInStream, 'html');
        exit(EmailFileInternal(
            TempEmailItem,
            CopyStr(BodyFileName, 1, MaxStrLen(TempEmailItem."Body File Path")),
            CopyStr(Subject, 1, MaxStrLen(TempEmailItem.Subject)),
            CopyStr(ToEmailAddress, 1, MaxStrLen(TempEmailItem."Send to")),
            PostedDocNo,
            '',
            HideDialog,
            ReportUsage,
            IsFromPostedDoc,
            '',
            Enum::"Email Scenario"::Default));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterEmailSentSuccesfully(var TempEmailItem: Record "Email Item" temporary; PostedDocNo: Code[20]; ReportUsage: Integer)
    begin
    end;

    // Sender is chosen based on the scenario to the Send function when using the email feature is enabled, so this function will not be needed anymore
    [Obsolete('Sender is changed via changing the account for a specified scenario. Use SetScenario from codeunit "Email Scenario".', '17.0')]
    local procedure IsAllowedToChangeSender(SenderUserID: Code[50]): Boolean
    var
        SMTPMailSetup: Record "SMTP Mail Setup";
        SMTPMail: Codeunit "SMTP Mail";
    begin
        if SenderUserID = '' then
            exit(false);

        if not SMTPMail.IsEnabled() then
            exit(false);

        SMTPMailSetup.GetSetup();
        exit(SMTPMailSetup."Allow Sender Substitution");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEmailFileInternal(var TempEmailItem: Record "Email Item" temporary; var HtmlBodyFilePath: Text[250]; var EmailSubject: Text[250]; var ToEmailAddress: Text[250]; var PostedDocNo: Code[20]; var EmailDocName: Text[250]; var HideDialog: Boolean; var ReportUsage: Integer; var IsFromPostedDoc: Boolean; var SenderUserID: Code[50]; var EmailScenario: Enum "Email Scenario")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetAttachmentFileName(var AttachmentFileName: Text[250]; PostedDocNo: Code[20]; EmailDocumentName: Text[250]; ReportUsage: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetEmailSubject(PostedDocNo: Code[20]; EmailDocumentName: Text[250]; ReportUsage: Integer; var EmailSubject: Text[250]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetToAddressFromCustomer(BillToCustomerNo: Code[20]; var ToAddress: Text[250]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetToAddressFromVendor(BuyFromVendorNo: Code[20]; var ToAddress: Text[250]; var IsHandled: Boolean)
    begin
    end;
}

#endif