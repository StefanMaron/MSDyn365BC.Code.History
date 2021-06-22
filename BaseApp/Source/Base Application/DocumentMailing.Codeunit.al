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
        EmailSubjectCapTxt: Label '%1 - %2 %3', Comment = '%1 = Customer Name. %2 = Document Type %3 = Invoice No.';
        ReportAsPdfFileNameMsg: Label 'Sales %1 %2.pdf', Comment = '%1 = Document Type %2 = Invoice No.';
        EmailSubjectPluralCapTxt: Label '%1 - %2', Comment = '%1 = Customer Name. %2 = Document Type in plural form';
        ReportAsPdfFileNamePluralMsg: Label 'Sales %1.pdf', Comment = '%1 = Document Type in plural form';
        JobsReportAsPdfFileNameMsg: Label '%1 %2.pdf', Comment = '%1 = Document Type %2 = Job Number';
        PdfFileNamePluralMsg: Label '%1.pdf', Comment = '%1 = Document Type in plural form';
        InvoiceEmailSubjectTxt: Label 'Invoice from %1', Comment = '%1 = name of the company';
        TestInvoiceEmailSubjectTxt: Label 'Test invoice from %1', Comment = '%1 = name of the company';
        QuoteEmailSubjectTxt: Label 'Estimate from %1', Comment = '%1 = name of the company';
        CustomerLbl: Label '<Customer>';

    [Scope('OnPrem')]
    procedure EmailFile(AttachmentFilePath: Text[250]; AttachmentFileName: Text[250]; HtmlBodyFilePath: Text[250]; PostedDocNo: Code[20]; ToEmailAddress: Text[250]; EmailDocName: Text[250]; HideDialog: Boolean; ReportUsage: Integer): Boolean
    var
        TempEmailItem: Record "Email Item" temporary;
    begin
        exit(EmailFileInternal(
            TempEmailItem,
            AttachmentFilePath,
            AttachmentFileName,
            HtmlBodyFilePath,
            '',
            ToEmailAddress,
            PostedDocNo,
            EmailDocName,
            HideDialog,
            ReportUsage,
            true,
            ''));
    end;

    [Scope('OnPrem')]
    procedure EmailFileWithSubject(AttachmentFilePath: Text; AttachmentFileName: Text; HtmlBodyFilePath: Text; EmailSubject: Text; ToEmailAddress: Text; HideDialog: Boolean): Boolean
    var
        TempEmailItem: Record "Email Item" temporary;
    begin
        exit(EmailFileInternal(
            TempEmailItem,
            CopyStr(AttachmentFilePath, 1, MaxStrLen(TempEmailItem."Attachment File Path")),
            CopyStr(AttachmentFileName, 1, MaxStrLen(TempEmailItem."Attachment Name")),
            CopyStr(HtmlBodyFilePath, 1, MaxStrLen(TempEmailItem."Body File Path")),
            CopyStr(EmailSubject, 1, MaxStrLen(TempEmailItem.Subject)),
            CopyStr(ToEmailAddress, 1, MaxStrLen(TempEmailItem."Send to")),
            '',
            '',
            HideDialog,
            0,
            false,
            ''));
    end;

    [Scope('OnPrem')]
    procedure EmailFileWithSubjectAndSender(AttachmentFilePath: Text; AttachmentFileName: Text; HtmlBodyFilePath: Text; EmailSubject: Text; ToEmailAddress: Text; HideDialog: Boolean; SenderUserID: Code[50]): Boolean
    var
        TempEmailItem: Record "Email Item" temporary;
    begin
        exit(EmailFileInternal(
            TempEmailItem,
            CopyStr(AttachmentFilePath, 1, MaxStrLen(TempEmailItem."Attachment File Path")),
            CopyStr(AttachmentFileName, 1, MaxStrLen(TempEmailItem."Attachment Name")),
            CopyStr(HtmlBodyFilePath, 1, MaxStrLen(TempEmailItem."Body File Path")),
            CopyStr(EmailSubject, 1, MaxStrLen(TempEmailItem.Subject)),
            CopyStr(ToEmailAddress, 1, MaxStrLen(TempEmailItem."Send to")),
            '',
            '',
            HideDialog,
            0,
            false,
            SenderUserID));
    end;

    [Scope('OnPrem')]
    procedure EmailFileWithSubjectAndReportUsage(AttachmentFilePath: Text[250]; AttachmentFileName: Text[250]; HtmlBodyFilePath: Text[250]; EmailSubject: Text[250]; PostedDocNo: Code[20]; ToEmailAddress: Text[250]; EmailDocName: Text[250]; HideDialog: Boolean; ReportUsage: Integer): Boolean
    var
        TempEmailItem: Record "Email Item" temporary;
    begin
        exit(EmailFileInternal(
            TempEmailItem,
            AttachmentFilePath,
            AttachmentFileName,
            HtmlBodyFilePath,
            EmailSubject,
            ToEmailAddress,
            PostedDocNo,
            EmailDocName,
            HideDialog,
            ReportUsage,
            false,
            ''));
    end;

    procedure GetToAddressFromCustomer(BillToCustomerNo: Code[20]): Text[250]
    var
        Customer: Record Customer;
        ToAddress: Text;
    begin
        if Customer.Get(BillToCustomerNo) then
            ToAddress := Customer."E-Mail";

        exit(ToAddress);
    end;

    procedure GetToAddressFromVendor(BuyFromVendorNo: Code[20]): Text[250]
    var
        Vendor: Record Vendor;
        ToAddress: Text;
    begin
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
                if ReportUsage = ReportSelections.Usage::"P.Order" then
                    AttachmentFileName := StrSubstNo(PdfFileNamePluralMsg, EmailDocumentName)
                else
                    AttachmentFileName := StrSubstNo(ReportAsPdfFileNamePluralMsg, EmailDocumentName);
            end else
                case ReportUsage of
                    ReportSelections.Usage::JQ,
                    ReportSelections.Usage::"P.Order",
                    ReportSelections.Usage::"V.Remittance",
                    ReportSelections.Usage::"P.V.Remit.",
                    ReportSelections.Usage::"P.Invoice":
                        AttachmentFileName := StrSubstNo(JobsReportAsPdfFileNameMsg, EmailDocumentName, PostedDocNo);
                    else
                        AttachmentFileName := StrSubstNo(ReportAsPdfFileNameMsg, EmailDocumentName, PostedDocNo)
                end;
    end;

    procedure GetEmailBody(PostedDocNo: Code[20]; ReportUsage: Integer; CustomerNo: Code[20]): Text
    var
        O365DefaultEmailMessage: Record "O365 Default Email Message";
        EmailParameter: Record "Email Parameter";
        Customer: Record Customer;
        EnvInfoProxy: Codeunit "Env. Info Proxy";
        String: DotNet String;
        DocumentType: Option;
    begin
        if Customer.Get(CustomerNo) then;

        if EmailParameter.GetEntryWithReportUsage(PostedDocNo, ReportUsage, EmailParameter."Parameter Type"::Body) then begin
            String := EmailParameter.GetParameterValue;
            exit(String.Replace(CustomerLbl, Customer.Name));
        end;

        if EnvInfoProxy.IsInvoicing then begin
            O365DefaultEmailMessage.ReportUsageToDocumentType(DocumentType, ReportUsage);
            String := O365DefaultEmailMessage.GetMessage(DocumentType);
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
        ReportSelections: Record "Report Selections";
        SalesHeader: Record "Sales Header";
        EnvInfoProxy: Codeunit "Env. Info Proxy";
        DocumentType: Option;
    begin
        if EmailParameter.GetEntryWithReportUsage(PostedDocNo, ReportUsage, EmailParameter."Parameter Type"::Subject) then
            exit(EmailParameter.GetParameterValue);
        CompanyInformation.Get();
        if EnvInfoProxy.IsInvoicing then begin
            ReportSelections.ReportUsageToDocumentType(DocumentType, ReportUsage);
            case DocumentType of
                SalesHeader."Document Type"::Invoice:
                    exit(StrSubstNo(InvoiceEmailSubjectTxt, CompanyInformation.Name));
                SalesHeader."Document Type"::Quote:
                    exit(StrSubstNo(QuoteEmailSubjectTxt, CompanyInformation.Name));
            end;
        end;
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
        String := O365DefaultEmailMessage.GetTestInvoiceMessage;
        exit(String.Replace(CustomerLbl, Customer.Name));
    end;

    procedure GetTestInvoiceEmailSubject(): Text[250]
    var
        CompanyInformation: Record "Company Information";
    begin
        if CompanyInformation.Get then;
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
        O365DocumentSentHistory.SetStatusAsFailed; // In case the code below throws an error, we want to default to failed.

        if ReportSelections.SendEmailInForeground(
             SalesHeader.RecordId, SalesHeader."No.", SalesHeader.GetDocTypeTxt, ReportSelections.Usage::"S.Quote",
             true, SalesHeader."Bill-to Customer No.")
        then begin
            O365DocumentSentHistory.SetStatusAsSuccessfullyFinished;
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
        O365DocumentSentHistory.SetStatusAsFailed; // In case the code below throws an error, we want to default to failed.

        if ReportSelections.SendEmailInForeground(
             SalesInvoiceHeader.RecordId, SalesInvoiceHeader."No.", 'Invoice', ReportSelections.Usage::"S.Invoice",
             true, SalesInvoiceHeader."Bill-to Customer No.")
        then begin
            O365DocumentSentHistory.SetStatusAsSuccessfullyFinished;
            exit(true);
        end;

        exit(false);
    end;

    local procedure EmailFileInternal(var TempEmailItem: Record "Email Item" temporary; AttachmentFilePath: Text[250]; AttachmentFileName: Text[250]; HtmlBodyFilePath: Text[250]; EmailSubject: Text[250]; ToEmailAddress: Text[250]; PostedDocNo: Code[20]; EmailDocName: Text[250]; HideDialog: Boolean; ReportUsage: Integer; IsFromPostedDoc: Boolean; SenderUserID: Code[50]): Boolean
    var
        OfficeMgt: Codeunit "Office Management";
        EmailSentSuccesfully: Boolean;
        IsHandled: Boolean;
    begin
        with TempEmailItem do begin
            if IsAllowedToChangeSender(SenderUserID) then begin
                "From Address" := GetSenderEmail(SenderUserID);
                "From Name" := GetSenderName(SenderUserID);
            end;

            "Send to" := ToEmailAddress;
            AddCcBcc;

            // If true, that means we came from "EmailFile" call and need to get data from the document
            if IsFromPostedDoc then begin
                GetAttachmentFileName(AttachmentFileName, PostedDocNo, EmailDocName, ReportUsage);
                EmailSubject := GetEmailSubject(PostedDocNo, EmailDocName, ReportUsage);
                AttachIncomingDocuments(PostedDocNo);
            end;
            "Attachment File Path" := AttachmentFilePath;
            "Attachment Name" := AttachmentFileName;
            Subject := EmailSubject;

            if HtmlBodyFilePath <> '' then begin
                Validate("Plaintext Formatted", false);
                Validate("Body File Path", HtmlBodyFilePath);
                Validate("Message Type", "Message Type"::"From Email Body Template");
            end;

            IsHandled := false;
            OnBeforeSendEmail(TempEmailItem, IsFromPostedDoc, PostedDocNo, HideDialog, ReportUsage, EmailSentSuccesfully, IsHandled);
            if IsHandled then
                exit(EmailSentSuccesfully);

            if OfficeMgt.AttachAvailable then
                OfficeMgt.AttachDocument(AttachmentFilePath, AttachmentFileName, GetBodyText, Subject)
            else begin
                EmailSentSuccesfully := Send(HideDialog);
                if EmailSentSuccesfully then
                    OnAfterEmailSentSuccesfully(TempEmailItem, PostedDocNo, ReportUsage);
                exit(EmailSentSuccesfully);
            end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendEmail(var TempEmailItem: Record "Email Item" temporary; var IsFromPostedDoc: Boolean; var PostedDocNo: Code[20]; var HideDialog: Boolean; var ReportUsage: Integer; var EmailSentSuccesfully: Boolean; var IsHandled: Boolean)
    begin
    end;

    procedure EmailFileFromStream(AttachmentStream: InStream; AttachmentName: Text; Body: Text; Subject: Text; MailTo: Text; HideDialog: Boolean; ReportUsage: Integer): Boolean
    var
        TempEmailItem: Record "Email Item" temporary;
        FileManagement: Codeunit "File Management";
        TempFile: File;
        OutStream: OutStream;
        TempFileName: Text;
    begin
        TempFileName := FileManagement.ServerTempFileName('');
        TempFile.Create(TempFileName);

        TempFile.CreateOutStream(OutStream);
        CopyStream(OutStream, AttachmentStream);
        TempFile.Close;

        TempEmailItem.Validate("Plaintext Formatted", true);
        TempEmailItem.SetBodyText(Body);

        exit(EmailFileInternal(
            TempEmailItem,
            CopyStr(TempFileName, 1, MaxStrLen(TempEmailItem."Attachment File Path")),
            CopyStr(AttachmentName, 1, MaxStrLen(TempEmailItem."Attachment Name")),
            '',
            CopyStr(Subject, 1, MaxStrLen(TempEmailItem.Subject)),
            CopyStr(MailTo, 1, MaxStrLen(TempEmailItem."Send to")),
            '',
            '',
            HideDialog,
            ReportUsage,
            false,
            ''));
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
            '',
            '',
            CopyStr(FileName, 1, MaxStrLen(TempEmailItem."Body File Path")),
            CopyStr(Subject, 1, MaxStrLen(TempEmailItem.Subject)),
            CopyStr(ToEmailAddress, 1, MaxStrLen(TempEmailItem."Send to")),
            '',
            '',
            HideDialog,
            ReportUsage,
            false,
            ''));
    end;

    procedure EmailFileAndHtmlFromStream(AttachmentStream: InStream; AttachmentName: Text; MailInStream: InStream; ToEmailAddress: Text[250]; Subject: Text; HideDialog: Boolean; ReportUsage: Integer): Boolean
    begin
        EmailFileAndHtmlFromStream(AttachmentStream, AttachmentName, MailInStream, ToEmailAddress, Subject, HideDialog, ReportUsage, '', false);
    end;

    procedure EmailFileAndHtmlFromStream(AttachmentStream: InStream; AttachmentName: Text; MailInStream: InStream; ToEmailAddress: Text[250]; Subject: Text; HideDialog: Boolean; ReportUsage: Integer; PostedDocNo: Code[20]; IsFromPostedDoc: Boolean): Boolean
    var
        TempEmailItem: Record "Email Item" temporary;
        FileManagement: Codeunit "File Management";
        TempFile: File;
        OutStream: OutStream;
        TempFileName: Text;
        BodyFileName: Text;
    begin
        TempFileName := FileManagement.ServerTempFileName('');
        TempFile.Create(TempFileName);
        TempFile.CreateOutStream(OutStream);
        CopyStream(OutStream, AttachmentStream);
        TempFile.Close;
        BodyFileName := FileManagement.InstreamExportToServerFile(MailInStream, 'html');
        exit(EmailFileInternal(
            TempEmailItem,
            CopyStr(TempFileName, 1, MaxStrLen(TempEmailItem."Attachment File Path")),
            CopyStr(AttachmentName, 1, MaxStrLen(TempEmailItem."Attachment Name")),
            CopyStr(BodyFileName, 1, MaxStrLen(TempEmailItem."Body File Path")),
            CopyStr(Subject, 1, MaxStrLen(TempEmailItem.Subject)),
            CopyStr(ToEmailAddress, 1, MaxStrLen(TempEmailItem."Send to")),
            PostedDocNo,
            '',
            HideDialog,
            ReportUsage,
            IsFromPostedDoc,
            ''));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterEmailSentSuccesfully(var TempEmailItem: Record "Email Item" temporary; PostedDocNo: Code[20]; ReportUsage: Integer)
    begin
    end;

    local procedure IsAllowedToChangeSender(SenderUserID: Code[50]): Boolean
    var
        SMTPMailSetup: Record "SMTP Mail Setup";
        SMTPMail: Codeunit "SMTP Mail";
    begin
        if SenderUserID = '' then
            exit(false);

        if not SMTPMail.IsEnabled then
            exit(false);

        SMTPMailSetup.GetSetup;
        exit(SMTPMailSetup."Allow Sender Substitution");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetAttachmentFileName(var AttachmentFileName: Text[250]; PostedDocNo: Code[20]; EmailDocumentName: Text[250]; ReportUsage: Integer)
    begin
    end;
}

