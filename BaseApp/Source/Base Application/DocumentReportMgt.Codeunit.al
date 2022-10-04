codeunit 9651 "Document Report Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        ClientTypeMgt: Codeunit "Client Type Management";

#if not CLEAN20
        NotImplementedErr: Label 'This option is not available.';
        UnexpectedHexCharacterRegexErr: Label 'hexadecimal value 0x[0-9a-fA-F]*, is an invalid character', Locked = true;
        UnexpectedCharInDataErr: Label 'The report contains characters or spaces that aren''t allowed.';
        UnexpectedCharInDataDetailedErr: Label 'For example, if you copied the company address from your website, you might have included an extra space. To find the problem, export the report data to an XML file and look for the invalid characters. Original error: %1', Comment = '%1 = the original error that contains the invalid character';
        FileTypeHtmlTxt: Label 'html', Locked = true;
        FileTypeWordTxt: Label 'docx', Locked = true;
        FileTypePdfTxt: Label 'pdf', Locked = true;
        UnableToRenderPdfDocument: Label 'The Word document cannot be converted to a PDF document.';
        LayoutEmptyErr: Label 'The custom report layout for ''%1'' is empty.', Comment = '%1 = Code of the Custom report layout';
        EnableLegacyPrint: Boolean;
#else
        UpgradeNotSupportedErr: Label 'Upgrade is not supported after version 20.';
#endif
        TemplateValidationQst: Label 'The Word layout does not comply with the current report design (for example, fields are missing or the report ID is wrong).\The following errors were detected during the layout validation:\%1\Do you want to continue?';
        TemplateValidationErr: Label 'The Word layout does not comply with the current report design (for example, fields are missing or the report ID is wrong).\The following errors were detected during the document validation:\%1\You must update the layout to match the current report design.';
        AbortWithValidationErr: Label 'The Word layout action has been canceled because of validation errors.';
        TemplateValidationUpdateQst: Label 'The Word layout does not comply with the current report design (for example, fields are missing or the report ID is wrong).\The following errors were detected during the layout validation:\%1\Do you want to run an automatic update?';
        TemplateAfterUpdateValidationErr: Label 'The automatic update could not resolve all the conflicts in the current Word layout. For example, the layout uses fields that are missing in the report design or the report ID is wrong.\The following errors were detected:\%1\You must manually update the layout to match the current report design.';
        UpgradeMessageMsg: Label 'The report upgrade process returned the following log messages:\%1.';
        NoReportLayoutUpgradeRequiredMsg: Label 'The layout upgrade process completed without detecting any required changes in the current application.';
        CompanyInformationPicErr: Label 'The document contains elements that cannot be converted to PDF. This may be caused by missing image data in the document.';

#if not CLEAN20
    [Scope('OnPrem')]
    [Obsolete('This procedure will be replaced by the report event CustomDocumentMerger. Subscribe to it to override the merging behavior.', '20.0')]
    procedure MergeWordLayout(ReportID: Integer; ReportAction: Option SaveAsPdf,SaveAsWord,SaveAsExcel,Preview,Print,SaveAsHtml; InStrXmlData: InStream; FileName: Text; var DocumentStream: OutStream)
    var
        ReportLayoutSelection: Record "Report Layout Selection";
        CustomReportLayout: Record "Custom Report Layout";
        TempBlobIn: Codeunit "Temp Blob";
        TempBlobOut: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
        Regex: Codeunit Regex;
        File: File;
        InStrWordDoc: InStream;
        OutStrWordDoc: OutStream;
        Instream: InStream;
        OutStream: OutStream;
        CustomLayoutCode: Code[20];
        CurrentFileType: Text;
        PrinterName: Text;
        IsHandled: Boolean;
        UnsupportedCharactersErr: ErrorInfo;
    begin
        if ReportAction = ReportAction::Print then
            PrinterName := FileName;
        TempBlobOut.CreateOutStream(OutStrWordDoc);

        FileName := FileMgt.GetPathWithSafeFileName(FileName);

        OnBeforeMergeDocument(ReportID, ReportAction, InStrXmlData, PrinterName, OutStrWordDoc, IsHandled, FileName = '');
        if IsHandled then begin
            if (FileName <> '') and TempBlobOut.HasValue() then begin
                File.WriteMode(true);
                if not File.Open(FileName) then begin
                    File.Create(FileName);
                    ClearLastError();
                end;
                File.CreateOutStream(OutStream);
                TempBlobOut.CreateInStream(Instream);
                CopyStream(OutStream, Instream);
                File.Close();
            end;
            exit;
        end;

        // Temporarily selected layout for Design-time report execution?
        if ReportLayoutSelection.GetTempLayoutSelected() <> '' then
            CustomLayoutCode := ReportLayoutSelection.GetTempLayoutSelected()
        else  // Normal selection
            if ReportLayoutSelection.Get(ReportID, CompanyName) and
               (ReportLayoutSelection.Type = ReportLayoutSelection.Type::"Custom Layout")
            then
                CustomLayoutCode := ReportLayoutSelection."Custom Report Layout Code";

        OnAfterGetCustomLayoutCode(ReportID, CustomLayoutCode);

        if CustomLayoutCode <> '' then
            if not CustomReportLayout.Get(CustomLayoutCode) then
                CustomLayoutCode := '';

        if CustomLayoutCode = '' then
            REPORT.WordLayout(ReportID, InStrWordDoc)
        else begin
            ValidateAndUpdateWordLayoutOnRecord(CustomReportLayout);
            CustomReportLayout.GetLayoutBlob(TempBlobIn);
            TempBlobIn.CreateInStream(InStrWordDoc);
            ValidateWordLayoutCheckOnly(ReportID, InStrWordDoc);
        end;

        OnBeforeMergeWordDocument();

        if not TryXmlMergeWordDocument(InStrWordDoc, InStrXmlData, OutStrWordDoc) then begin
            if Regex.IsMatch(GetLastErrorText(), UnexpectedHexCharacterRegexErr) then begin
                UnsupportedCharactersErr.ErrorType := UnsupportedCharactersErr.ErrorType::Client;
                UnsupportedCharactersErr.Message := UnexpectedCharInDataErr;
                UnsupportedCharactersErr.DetailedMessage := StrSubstNo(UnexpectedCharInDataDetailedErr, GetLastErrorText());
                UnsupportedCharactersErr.Verbosity := UnsupportedCharactersErr.Verbosity::Error;
                UnsupportedCharactersErr.DataClassification := UnsupportedCharactersErr.DataClassification::SystemMetadata;

                Error(UnsupportedCharactersErr);
            end;

            Error(GetLastErrorText());
        end;

        IsHandled := false;
        OnMergeReportLayoutOnSuppressCommit(ReportID, IsHandled);
        if not IsHandled then
            Commit();
        OnAfterMergeWordDocument(ReportID, InStrXmlData, TempBlobOut);

        CurrentFileType := '';
        case ReportAction of
            ReportAction::SaveAsWord:
                CurrentFileType := FileTypeWordTxt;
            ReportAction::SaveAsPdf, ReportAction::Preview:
                begin
                    CurrentFileType := FileTypePdfTxt;
                    ConvertWordToPdf(TempBlobOut, ReportID);
                end;
            ReportAction::SaveAsHtml:
                begin
                    CurrentFileType := FileTypeHtmlTxt;
                    ConvertWordToHtml(TempBlobOut);
                end;
            ReportAction::SaveAsExcel:
                Error(NotImplementedErr);
            ReportAction::Print:
                if IsStreamHasDataset(InStrXmlData) then
                    PrintWordDoc(ReportID, TempBlobOut, PrinterName, true, DocumentStream);
        end;

        // Export the file to the client of the action generates an output object in which case currentFileType is non-empty.
        if CurrentFileType <> '' then
            if FileName = '' then
                FileMgt.BLOBExport(TempBlobOut, UserFileName(ReportID, CurrentFileType), true)
            else begin
                // Dont' use FileMgt.BLOBExportToServerFile. It will fail if run through
                // CodeUnit 8800, as the filename will exist in a temp folder.
                File.WriteMode(true);
                if not File.Open(FileName) then begin
                    File.Create(FileName);
                    ClearLastError();
                end;
                File.CreateOutStream(OutStream);
                TempBlobOut.CreateInStream(Instream);
                CopyStream(OutStream, Instream);
                File.Close();
            end;
    end;

    [Scope('OnPrem')]
    [Obsolete('This procedure will be eventually replaced by platform functionality. Subscribe to the event FetchReportLayoutByCode instead.', '20.0')]
    procedure GetWordLayoutStream(ReportID: Integer; var LayoutStream: OutStream; var Success: Boolean)
    var
        ReportLayoutSelection: Record "Report Layout Selection";
        CustomReportLayout: Record "Custom Report Layout";
        TempBlobIn: Codeunit "Temp Blob";
        CustomLayoutCode: Code[20];
        InStrWordDoc: InStream;
    begin
        Success := false;
        // Temporarily selected layout for Design-time report execution?
        if ReportLayoutSelection.GetTempLayoutSelected() <> '' then
            CustomLayoutCode := ReportLayoutSelection.GetTempLayoutSelected()
        else  // Normal selection
            if ReportLayoutSelection.Get(ReportID, CompanyName) and
               (ReportLayoutSelection.Type = ReportLayoutSelection.Type::"Custom Layout")
            then
                CustomLayoutCode := ReportLayoutSelection."Custom Report Layout Code";

        OnAfterGetCustomLayoutCode(ReportID, CustomLayoutCode);

        if CustomLayoutCode <> '' then
            if not CustomReportLayout.Get(CustomLayoutCode) then
                CustomLayoutCode := '';

        if CustomLayoutCode <> '' then begin
            ValidateAndUpdateWordLayoutOnRecord(CustomReportLayout);
            CustomReportLayout.GetLayoutBlob(TempBlobIn);
            TempBlobIn.CreateInStream(InStrWordDoc);
            ValidateWordLayoutCheckOnly(ReportID, InStrWordDoc);
            CopyStream(LayoutStream, InStrWordDoc);
            Success := true;
        end;
    end;


    [TryFunction]
    [Obsolete('The rendering of Word documents will be handled on the Platform. To override the behavior, subscribe on the report event CustomDocumentMerger.', '20.0')]
    procedure TryXmlMergeWordDocument(var InStrWordDoc: InStream; var InStrXmlData: InStream; var OutStrWordDoc: OutStream)
    var
        NAVWordXMLMerger: DotNet WordReportManager;
    begin
        OutStrWordDoc := NAVWordXMLMerger.MergeWordDocument(InStrWordDoc, InStrXmlData, OutStrWordDoc);
        OnAfterTryXmlMergeWordDocument(OutStrWordDoc);
    end;
#endif

    procedure ValidateWordLayout(ReportID: Integer; DocumentStream: InStream; useConfirm: Boolean; updateContext: Boolean): Boolean
    var
        NAVWordXMLMerger: DotNet WordReportManager;
        ValidationErrors: Text;
        ValidationErrorFormat: Text;
    begin
        ValidationErrors := NAVWordXMLMerger.ValidateWordDocumentTemplate(DocumentStream, REPORT.WordXmlPart(ReportID, true));
        if ValidationErrors <> '' then begin
            if useConfirm then begin
                if not Confirm(TemplateValidationQst, false, ValidationErrors) then
                    Error(AbortWithValidationErr);
            end else begin
                if updateContext then
                    ValidationErrorFormat := TemplateAfterUpdateValidationErr
                else
                    ValidationErrorFormat := TemplateValidationErr;

                Error(ValidationErrorFormat, ValidationErrors);
            end;

            exit(false);
        end;
        exit(true);
    end;

#if not CLEAN20
    local procedure ValidateWordLayoutCheckOnly(ReportID: Integer; DocumentStream: InStream)
    var
        NAVWordXMLMerger: DotNet WordReportManager;
        ValidationErrors: Text;
        ValidationErrorFormat: Text;
    begin
        ValidationErrors := NAVWordXMLMerger.ValidateWordDocumentTemplate(DocumentStream, REPORT.WordXmlPart(ReportID, true));
        if ValidationErrors <> '' then begin
            ValidationErrorFormat := TemplateAfterUpdateValidationErr;
            Message(ValidationErrorFormat, ValidationErrors);
        end;
    end;

    local procedure ValidateAndUpdateWordLayoutOnRecord(CustomReportLayout: Record "Custom Report Layout"): Boolean
    var
        TempBlob: Codeunit "Temp Blob";
        NAVWordXMLMerger: DotNet WordReportManager;
        DocumentStream: InStream;
        ValidationErrors: Text;
    begin
        CustomReportLayout.TestField(Type, CustomReportLayout.Type::Word);
        CustomReportLayout.GetLayoutBlob(TempBlob);
        if not TempBlob.HasValue() then
            Error(LayoutEmptyErr, CustomReportLayout.Code);
        TempBlob.CreateInStream(DocumentStream);
        NAVWordXMLMerger := NAVWordXMLMerger.WordReportManager();

        ValidationErrors :=
          NAVWordXMLMerger.ValidateWordDocumentTemplate(DocumentStream, REPORT.WordXmlPart(CustomReportLayout."Report ID", true));
        if ValidationErrors <> '' then begin
            if Confirm(TemplateValidationUpdateQst, false, ValidationErrors) then begin
                ValidationErrors := CustomReportLayout.TryUpdateLayout(false);
                Commit();
                exit(true);
            end;
            Error(TemplateValidationErr, ValidationErrors);
        end;
        exit(false);
    end;
#endif

    procedure TryUpdateWordLayout(DocumentStream: InStream; var UpdateStream: OutStream; CachedCustomPart: Text; CurrentCustomPart: Text): Text
    var
        NAVWordXMLMerger: DotNet WordReportManager;
    begin
        NAVWordXMLMerger := NAVWordXMLMerger.WordReportManager();
        NAVWordXMLMerger.UpdateWordDocumentLayout(DocumentStream, UpdateStream, CachedCustomPart, CurrentCustomPart, true);
        exit(NAVWordXMLMerger.LastUpdateError);
    end;

    procedure TryUpdateRdlcLayout(reportId: Integer; RdlcStream: InStream; RdlcUpdatedStream: OutStream; CachedCustomPart: Text; CurrentCustomPart: Text; IgnoreDelete: Boolean): Text
    var
        NAVWordXMLMerger: DotNet RdlcReportManager;
    begin
        exit(NAVWordXMLMerger.TryUpdateRdlcLayout(reportId, RdlcStream, RdlcUpdatedStream,
            CachedCustomPart, CurrentCustomPart, IgnoreDelete));
    end;

    procedure NewWordLayout(ReportId: Integer; var DocumentStream: OutStream)
    var
        NAVWordXmlMerger: DotNet WordReportManager;
    begin
        NAVWordXmlMerger.NewWordDocumentLayout(DocumentStream, REPORT.WordXmlPart(ReportId));
    end;

    procedure ConvertWordToPdf(var TempBlob: Codeunit "Temp Blob"; ReportID: Integer)
    begin
        if not TryConvertWordBlobToPdf(TempBlob) then
            Error(CompanyInformationPicErr);
#if not CLEAN20
        OnAfterConvertToPdf(TempBlob, ReportID);
#endif
    end;

    [TryFunction]
    local procedure TryConvertWordBlobToPdf(var TempBlobWord: Codeunit "Temp Blob")
    var
        TempBlobPdf: Codeunit "Temp Blob";
        InStreamWordDoc: InStream;
        OutStreamPdfDoc: OutStream;
        WordTransformation: DotNet WordTransformation;
    begin
        TempBlobWord.CreateInStream(InStreamWordDoc);
        TempBlobPdf.CreateOutStream(OutStreamPdfDoc);
        WordTransformation.ConvertToPdf(InStreamWordDoc, OutStreamPdfDoc);
        TempBlobWord := TempBlobPdf;
    end;

#if not CLEAN20
    [TryFunction]
    local procedure TryConvertWordBlobToPdfOnStream(var TempBlobWord: Codeunit "Temp Blob"; var OutStreamPdfDoc: OutStream)
    var
        InStreamWordDoc: InStream;
        WordTransformation: DotNet WordTransformation;
    begin
        TempBlobWord.CreateInStream(InStreamWordDoc);
        WordTransformation.ConvertToPdf(InStreamWordDoc, OutStreamPdfDoc);
    end;
#endif

    procedure ConvertWordToHtml(var TempBlob: Codeunit "Temp Blob")
    var
        TempBlobHtml: Codeunit "Temp Blob";
        TempBlobWord: Codeunit "Temp Blob";
        InStreamWordDoc: InStream;
        OutStreamHtmlDoc: OutStream;
        WordTransformation: DotNet WordTransformation;
    begin
        TempBlobWord := TempBlob;
        TempBlobWord.CreateInStream(InStreamWordDoc);
        TempBlobHtml.CreateOutStream(OutStreamHtmlDoc);
        WordTransformation.ConvertToHtml(InStreamWordDoc, OutStreamHtmlDoc);
        TempBlob := TempBlobHtml
    end;

#if not CLEAN20
    local procedure PrintWordDoc(ReportID: Integer; var TempBlob: Codeunit "Temp Blob"; PrinterName: Text; Collate: Boolean; var pdfStream: OutStream)
    var
        PrinterTable: Record "Printer";
        FileMgt: Codeunit "File Management";
        LocalPrinter: Boolean;
    begin
        // We cannot check the state of the pdfStream (not possible to detect that it's uninitialized from AL)
        // Get the printer table record and check if the Payload column is empty or not. Empty means a local Windows printer, not empty is an
        // extension based printer
        if (PrinterTable.Get(PrinterName)) then
            if (strlen(PrinterTable.Payload) = 0) then
                LocalPrinter := True;

        if EnableLegacyPrint or LocalPrinter then begin
            if ClientTypeMgt.GetCurrentClientType() in [CLIENTTYPE::Web, CLIENTTYPE::Phone, CLIENTTYPE::Tablet, CLIENTTYPE::Desktop] then begin
                ConvertWordToPdf(TempBlob, ReportID);
                FileMgt.BLOBExport(TempBlob, UserFileName(ReportID, FileTypePdfTxt), true);
            end else
                PrintWordDocOnServer(TempBlob, PrinterName, Collate);
            // Don't clear the pdfStream as it might have an empty implementation (uninitialized) which can cause an runtime exception to be throw.
            // Reinsert the clear call when compiler is fixed and emit code like this.pdfStream.Value?.Clear();
            // clear(pdfStream); // Nothing is written to the stream when called using the legacy signature
        end else
            if not TryConvertWordBlobToPdfOnStream(TempBlob, pdfStream) then
                Error(UnableToRenderPdfDocument);
    end;
#endif

    [Scope('OnPrem')]
    procedure IsStreamHasDataset(InStrXmlData: InStream): Boolean
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        XmlNode: DotNet XmlNode;
        XmlHasDataset: Boolean;
    begin
        XmlHasDataset := XMLDOMManagement.LoadXMLNodeFromInStream(InStrXmlData, XmlNode);

        if XmlHasDataset then
            XmlHasDataset := XMLDOMManagement.FindNode(XmlNode, 'DataItems', XmlNode);

        if XmlHasDataset then
            XmlHasDataset := XmlNode.ChildNodes.Count > 0;

        exit(XmlHasDataset);
    end;

#if not CLEAN20
    local procedure PrintWordDocOnServer(TempBlob: Codeunit "Temp Blob"; PrinterName: Text; Collate: Boolean)
    var
        WordTransformation: DotNet WordTransformation;
        InStreamWordDoc: InStream;
    begin
        TempBlob.CreateInStream(InStreamWordDoc);
        WordTransformation.PrintWordDoc(InStreamWordDoc, PrinterName, Collate);
    end;

    local procedure UserFileName(ReportID: Integer; fileExtension: Text): Text
    var
        ReportMetadata: Record "Report Metadata";
        FileManagement: Codeunit "File Management";
    begin
        ReportMetadata.Get(ReportID);
        if fileExtension = '' then
            fileExtension := FileTypeWordTxt;

        exit(FileManagement.GetSafeFileName(ReportMetadata.Caption) + '.' + fileExtension);
    end;
#endif

    [Scope('OnPrem')]
    procedure ApplyUpgradeToReports(var ReportUpgradeCollection: DotNet ReportUpgradeCollection; testOnly: Boolean): Boolean
    var
        CustomReportLayout: Record "Custom Report Layout";
        ReportUpgrade: DotNet ReportUpgradeSet;
        ReportChangeLogCollection: DotNet IReportChangeLogCollection;
    begin
        foreach ReportUpgrade in ReportUpgradeCollection do begin
            CustomReportLayout.SetFilter("Report ID", Format(ReportUpgrade.ReportId));
            if CustomReportLayout.Find('-') then
                repeat
                    CustomReportLayout.ApplyUpgrade(ReportUpgrade, ReportChangeLogCollection, testOnly);
                until CustomReportLayout.Next() = 0;
        end;

        if IsNull(ReportChangeLogCollection) then begin // Don't break upgrade process with user information
            if (ClientTypeMgt.GetCurrentClientType() <> CLIENTTYPE::Background) and
               (ClientTypeMgt.GetCurrentClientType() <> CLIENTTYPE::Management)
            then
                Message(NoReportLayoutUpgradeRequiredMsg);

            exit(false);
        end;

        ProcessUpgradeLog(ReportChangeLogCollection);
        exit(ReportChangeLogCollection.Count > 0);
    end;

#if not CLEAN20
    [Scope('OnPrem')]
    [Obsolete('The upgrade will be handled by the platform.', '20.0')]
    procedure CalculateUpgradeChangeSet(var ReportUpgradeCollection: DotNet ReportUpgradeCollection)
    var
        CustomReportLayout: Record "Custom Report Layout";
        ReportUpgradeSet: DotNet IReportUpgradeSet;
    begin
        OnBeforeCalculateUpgradeChangeSetSetCustomReportLayoutFilters(CustomReportLayout);
        if CustomReportLayout.Find('-') then
            repeat
                ReportUpgradeSet := ReportUpgradeCollection.AddReport(CustomReportLayout."Report ID"); // runtime will load the current XmlPart from metadata
                if not IsNull(ReportUpgradeSet) then
                    ReportUpgradeSet.CalculateAutoChangeSet(CustomReportLayout.GetCustomXmlPart());
            until CustomReportLayout.Next() <> 1;
    end;
#endif

    local procedure ProcessUpgradeLog(var ReportChangeLogCollection: DotNet IReportChangeLogCollection)
    var
        ReportLayoutUpdateLog: Codeunit "Report Layout Update Log";
    begin
        if IsNull(ReportChangeLogCollection) then
            exit;

        if (ClientTypeMgt.GetCurrentClientType() <> CLIENTTYPE::Background) and
           (ClientTypeMgt.GetCurrentClientType() <> CLIENTTYPE::Management)
        then
            ReportLayoutUpdateLog.ViewLog(ReportChangeLogCollection)
        else
            Message(UpgradeMessageMsg, Format(ReportChangeLogCollection));
    end;

#if not CLEAN20
    [Obsolete('The layouts will be moved to a system table where they will be handled by the platform in the future. Avoid using this functionality explicitly.', '20.0')]
    local procedure BulkUpgradeImplementation(testMode: Boolean)
    var
        ReportUpgradeCollection: DotNet ReportUpgradeCollection;
    begin
        ReportUpgradeCollection := ReportUpgradeCollection.ReportUpgradeCollection();

        CalculateUpgradeChangeSet(ReportUpgradeCollection);
        ApplyUpgradeToReports(ReportUpgradeCollection, testMode);
    end;
#endif

    [Scope('OnPrem')]
    procedure BulkUpgrade(testMode: Boolean)
    begin
#if not CLEAN20
        BulkUpgradeImplementation(testMode);
#else
        Message(UpgradeNotSupportedErr);
#endif
    end;

#if not CLEAN20
    [IntegrationEvent(false, false)]
    [Obsolete('The rendering of Word documents will be handled on the Platform. To override the behavior, subscribe on the report event CustomDocumentMerger.', '20.0')]
    local procedure OnAfterConvertToPdf(var TempBlob: Codeunit "Temp Blob"; ReportID: Integer);
    begin
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('The rendering of Word documents will be handled on the Platform. To override the behavior, subscribe on the report event CustomDocumentMerger.', '20.0')]
    local procedure OnAfterGetCustomLayoutCode(ReportID: Integer; var CustomLayoutCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('The rendering of Word documents will be handled on the Platform. To override the behavior, subscribe on the report event CustomDocumentMerger.', '20.0')]
    local procedure OnAfterMergeWordDocument(ReportID: Integer; InStrXmlData: InStream; var TempBlob: Codeunit "Temp Blob")
    begin
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('The rendering of Word documents will be handled on the Platform. To override the behavior, subscribe on the report event CustomDocumentMerger.', '20.0')]
    local procedure OnAfterTryXmlMergeWordDocument(var OutStrWordDoc: OutStream)
    begin
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('The rendering of Word documents will be handled on the Platform. To override the behavior, subscribe on the report event CustomDocumentMerger.', '20.0')]
    local procedure OnBeforeMergeDocument(ReportID: Integer; ReportAction: Option SaveAsPdf,SaveAsWord,SaveAsExcel,Preview,Print,SaveAsHtml; var InStrXmlData: InStream; PrinterName: Text; OutStream: OutStream; var Handled: Boolean; IsFileNameBlank: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('The rendering of Word documents will be handled on the Platform. To override the behavior, subscribe on the report event CustomDocumentMerger.', '20.0')]
    local procedure OnBeforeMergeWordDocument()
    begin
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('The rendering of Word documents will be handled on the Platform. To override the behavior, subscribe on the report event CustomDocumentMerger.', '20.0')]
    local procedure OnBeforeCalculateUpgradeChangeSetSetCustomReportLayoutFilters(var CustomReportLayout: Record "Custom Report Layout")
    begin
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('The rendering of Word documents will be handled on the Platform. To override the behavior, subscribe on the report event CustomDocumentMerger.', '20.0')]
    local procedure OnMergeReportLayoutOnSuppressCommit(ReportID: Integer; var IsHandled: Boolean)
    begin
    end;
#endif
}

