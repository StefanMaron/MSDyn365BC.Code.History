codeunit 260 "Document-Mailing"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        ReportSelections: Record "Report Selections";
#if not CLEAN21
        O365DocumentSentHistory: Record "O365 Document Sent History";
#endif
    begin
#if not CLEAN21
        O365DocumentSentHistory.NewInProgressFromJobQueue(Rec);
#endif
        ReportSelections.SendEmailInBackground(Rec);
    end;

    var
        TempBlob: Codeunit "Temp Blob";
        EmailSubjectCapTxt: Label '%1 - %2 %3', Comment = '%1 = Customer Name. %2 = Document Type %3 = Invoice No.';
        ReportAsPdfFileNameMsg: Label '%1 %2.pdf', Comment = '%1 = Document Type %2 = Invoice No. or Job Number';
        EmailSubjectPluralCapTxt: Label '%1 - %2', Comment = '%1 = Customer Name. %2 = Document Type in plural form';
        PdfFileNamePluralPurchaseTxt: Label '%1 (Purchase).pdf', Comment = '%1 = Document Type in plural form';
        PdfFileNamePluralSalesTxt: Label '%1 (Sales).pdf', Comment = '%1 = Document Type in plural form';
        PdfFileNamePluralTxt: Label '%1.pdf', Comment = '%1 = Document Type in plural form';
#if not CLEAN21 
        TestInvoiceEmailSubjectTxt: Label 'Test invoice from %1', Comment = '%1 = name of the company';
#endif
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
        OnBeforeEmailFile(HideDialog);
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
        Clear(TempBlob);
        if AttachmentFilePath <> '' then begin
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
        Clear(TempBlob);
        if AttachmentFilePath <> '' then begin
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
        Clear(TempBlob);
        if AttachmentFilePath <> '' then begin
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
        Clear(TempBlob);
        if AttachmentFilePath <> '' then begin
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

    procedure GetAttachmentFileName(var AttachmentFileName: Text[250]; PostedDocNo: Code[20]; EmailDocumentName: Text[250]; ReportUsage: Integer)
    begin
        OnBeforeGetAttachmentFileName(AttachmentFileName, PostedDocNo, EmailDocumentName, ReportUsage);

        if AttachmentFileName = '' then
            if PostedDocNo = '' then begin
                if IsPurchaseReportUsage(ReportUsage) then
                    AttachmentFileName := StrSubstNo(PdfFileNamePluralPurchaseTxt, EmailDocumentName)
                else
                    if IsSalesReportUsage(ReportUsage) then
                        AttachmentFileName := StrSubstNo(PdfFileNamePluralSalesTxt, EmailDocumentName)
                    else
                        AttachmentFileName := StrSubstNo(PdfFileNamePluralTxt, EmailDocumentName);
            end else
                AttachmentFileName := StrSubstNo(ReportAsPdfFileNameMsg, EmailDocumentName, PostedDocNo);
    end;

    local procedure IsPurchaseReportUsage(ReportUsage: Integer): Boolean
    var
        ReportSelectionUsage: Enum "Report Selection Usage";
    begin
        case ReportUsage of
            ReportSelectionUsage::"P.Quote".AsInteger(),
            ReportSelectionUsage::"P.Blanket".AsInteger(),
            ReportSelectionUsage::"P.Order".AsInteger(),
            ReportSelectionUsage::"P.Invoice".AsInteger(),
            ReportSelectionUsage::"P.Return".AsInteger(),
            ReportSelectionUsage::"P.Cr.Memo".AsInteger(),
            ReportSelectionUsage::"P.Receipt".AsInteger(),
            ReportSelectionUsage::"P.Ret.Shpt.".AsInteger(),
            ReportSelectionUsage::"P.Test".AsInteger(),
            ReportSelectionUsage::"P.Test Prepmt.".AsInteger(),
            ReportSelectionUsage::"P.Arch.Quote".AsInteger(),
            ReportSelectionUsage::"P.Arch.Order".AsInteger(),
            ReportSelectionUsage::"P.Arch.Return".AsInteger(),
            ReportSelectionUsage::"P.Arch.Blanket".AsInteger(),
            ReportSelectionUsage::"V.Remittance".AsInteger(),
            ReportSelectionUsage::"P.V.Remit.".AsInteger():
                exit(true);
        end;

        exit(false);
    end;

    local procedure IsSalesReportUsage(ReportUsage: Integer): Boolean
    var
        ReportSelectionUsage: Enum "Report Selection Usage";
    begin
        case ReportUsage of
            ReportSelectionUsage::"S.Quote".AsInteger(),
            ReportSelectionUsage::"S.Blanket".AsInteger(),
            ReportSelectionUsage::"S.Order".AsInteger(),
            ReportSelectionUsage::"S.Work Order".AsInteger(),
            ReportSelectionUsage::"S.Order Pick Instruction".AsInteger(),
            ReportSelectionUsage::"S.Invoice".AsInteger(),
            ReportSelectionUsage::"S.Invoice Draft".AsInteger(),
            ReportSelectionUsage::"S.Return".AsInteger(),
            ReportSelectionUsage::"S.Cr.Memo".AsInteger(),
            ReportSelectionUsage::"S.Shipment".AsInteger(),
            ReportSelectionUsage::"S.Ret.Rcpt.".AsInteger(),
            ReportSelectionUsage::"S.Test".AsInteger(),
            ReportSelectionUsage::"S.Test Prepmt.".AsInteger(),
            ReportSelectionUsage::"S.Arch.Quote".AsInteger(),
            ReportSelectionUsage::"S.Arch.Order".AsInteger(),
            ReportSelectionUsage::"S.Arch.Return".AsInteger(),
            ReportSelectionUsage::"C.Statement".AsInteger(),
            ReportSelectionUsage::"Pro Forma S. Invoice".AsInteger(),
            ReportSelectionUsage::"S.Arch.Blanket".AsInteger():
                exit(true);
        end;

        exit(false);
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
#if not CLEAN21 
    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
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

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure GetTestInvoiceEmailSubject(): Text[250]
    var
        CompanyInformation: Record "Company Information";
    begin
        if CompanyInformation.Get() then;
        exit(StrSubstNo(TestInvoiceEmailSubjectTxt, CompanyInformation.Name));
    end;

    [Scope('OnPrem')]
    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
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
    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
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
#endif
    // Email Item needs to be passed by var so the attachments are available
    local procedure EmailFileInternal(var TempEmailItem: Record "Email Item" temporary; HtmlBodyFilePath: Text[250]; EmailSubject: Text[250]; ToEmailAddress: Text[250]; PostedDocNo: Code[20]; EmailDocName: Text[250]; HideDialog: Boolean; ReportUsage: Integer; IsFromPostedDoc: Boolean; SenderUserID: Code[50]; EmailScenario: Enum "Email Scenario"): Boolean
    var
        OfficeMgt: Codeunit "Office Management";
        EmailScenarioMapping: Codeunit "Email Scenario Mapping";
        Attachments: Codeunit "Temp Blob List";
        Attachment: Codeunit "Temp Blob";
        EmailSentSuccesfully: Boolean;
        IsHandled: Boolean;
        AttachmentStream: Instream;
        AttachmentNames: List of [Text];
        Name: Text[250];
    begin
        IsHandled := false;
        OnBeforeEmailFileInternal(TempEmailItem, HtmlBodyFilePath, EmailSubject, ToEmailAddress, PostedDocNo, EmailDocName, HideDialog, ReportUsage, IsFromPostedDoc, SenderUserID, EmailScenario, EmailSentSuccesfully, IsHandled);
        if IsHandled then
            exit(EmailSentSuccesfully);

        TempEmailItem."Send to" := ToEmailAddress;
#if not CLEAN21
        TempEmailItem.AddCcBcc();
#endif

        TempEmailItem.GetAttachments(Attachments, AttachmentNames);
        // If true, that means we came from "EmailFile" call and need to get data from the document
        if IsFromPostedDoc then begin
            if Attachments.Count() > 0 then begin
                Name := CopyStr(AttachmentNames.Get(1), 1, 250);
                GetAttachmentFileName(Name, PostedDocNo, EmailDocName, ReportUsage);
                if Name <> AttachmentNames.Get(1) then
                    AttachmentNames.Set(1, Name);
            end;
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
            if Enum::"Report Selection Usage".Ordinals().Contains(ReportUsage) then
                EmailScenario := EmailScenarioMapping.FromReportSelectionUsage(Enum::"Report Selection Usage".FromInteger(ReportUsage));
            EmailSentSuccesfully := TempEmailItem.Send(HideDialog, EmailScenario);
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

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEmailFileInternal(var TempEmailItem: Record "Email Item" temporary; var HtmlBodyFilePath: Text[250]; var EmailSubject: Text[250]; var ToEmailAddress: Text[250]; var PostedDocNo: Code[20]; var EmailDocName: Text[250]; var HideDialog: Boolean; var ReportUsage: Integer; var IsFromPostedDoc: Boolean; var SenderUserID: Code[50]; var EmailScenario: Enum "Email Scenario"; var EmailSentSuccessfully: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEmailFile(var HideDialog: Boolean)
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

