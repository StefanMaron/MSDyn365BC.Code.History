codeunit 44 ReportManagement
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        NotSupportedErr: Label 'The value is not supported.';
        NoWritePermissionsErr: Label 'Unable to set the default printer. You need the Write permission for the Printer Selection table.';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'GetPrinterName', '', false, false)]
    local procedure GetPrinterNameSubscriber(ReportID: Integer; var PrinterName: Text[250])
    begin
        GetPrinterName(ReportID, PrinterName);
    end;

    procedure GetPrinterName(ReportID: Integer; var PrinterName: Text[250])
    var
        PrinterSelection: Record "Printer Selection";
    begin
        Clear(PrinterSelection);

        if PrinterSelection.ReadPermission then
            if not PrinterSelection.Get(UserId, ReportID) then
                if not PrinterSelection.Get('', ReportID) then
                    if not PrinterSelection.Get(UserId, 0) then
                        if PrinterSelection.Get('', 0) then;
        PrinterName := PrinterSelection."Printer Name";

        OnAfterGetPrinterName(ReportID, PrinterName, PrinterSelection);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Printer Setup", 'OnSetAsDefaultPrinter', '', false, false)]
    local procedure OnSetAsDefaultPrinterForCurrentUser(PrinterID: Text; UserID: Text; var IsHandled: Boolean)
    var
        PrinterSelection: Record "Printer Selection";
    begin
        if IsHandled then
            exit;

        Clear(PrinterSelection);
        if not PrinterSelection.WritePermission then
            Error(NoWritePermissionsErr);

        if PrinterSelection.Get(UserID, 0) then begin
            PrinterSelection."Printer Name" := CopyStr(PrinterID, 1, MaxStrLen((PrinterSelection."Printer Name")));
            PrinterSelection.Modify(true);
        end else begin
            PrinterSelection.Validate("User ID", UserID);
            PrinterSelection.Validate("Report ID", 0);
            PrinterSelection."Printer Name" := CopyStr(PrinterID, 1, MaxStrLen((PrinterSelection."Printer Name")));
            PrinterSelection.Insert(true);
        end;

        IsHandled := true;
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Printer Setup", 'GetPrinterSelectionsPage', '', false, false)]
    procedure GetPrinterSelectionsPage(var PageID: Integer; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;
        PageID := Page::"Printer Selections";
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'GetPaperTrayForReport', '', false, false)]
    local procedure GetPaperTrayForReport(ReportID: Integer; var FirstPage: Integer; var DefaultPage: Integer; var LastPage: Integer)
    begin
        OnAfterGetPaperTrayForReport(ReportID, FirstPage, DefaultPage, LastPage)
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'HasCustomLayout', '', false, false)]
    local procedure HasCustomLayout(ObjectType: Option "Report","Page"; ObjectID: Integer; var LayoutType: Option "None",RDLC,Word,Excel,Custom)
    var
        ReportLayoutSelection: Record "Report Layout Selection";
    begin
        if ObjectType <> ObjectType::Report then
            Error(NotSupportedErr);

        LayoutType := ReportLayoutSelection.HasCustomLayout(ObjectID);
        OnAfterHasCustomLayout(ObjectType, ObjectID, LayoutType);
    end;

#if not CLEAN20
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'MergeDocument', '', false, false)]
    [Obsolete('Replaced by CustomDocumentMergerEx for support of AL driver report renders.', '20.0')]
    local procedure MergeDocument(ObjectType: Option "Report","Page"; ObjectID: Integer; ReportAction: Option SaveAsPdf,SaveAsWord,SaveAsExcel,Preview,Print,SaveAsHtml; XmlData: InStream; FileName: Text; var DocumentStream: OutStream)
    var
        DocumentReportMgt: Codeunit "Document Report Mgt.";
        IsHandled: Boolean;
    begin
        // IMPORTANT: This codepath is only reachable if the platform feature switch EnableReportLegacyWordRender is active. The default is to render Word driven reports in the platform.
        if ObjectType <> ObjectType::Report then
            Error(NotSupportedErr);

        IsHandled := false;
        OnMergeDocumentReport(ObjectType, ObjectID, ReportAction, XmlData, FileName, DocumentStream, IsHandled);
        if (IsHandled) then
            exit;

        DocumentReportMgt.MergeWordLayout(ObjectID, ReportAction, XmlData, FileName, DocumentStream);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'CustomDocumentMerger', '', false, false)]
    [Obsolete('Replaced by CustomDocumentMergerEx for support of AL driver report renders.', '20.0')]
    local procedure CustomDocumentMerger(ObjectID: Integer; ReportAction: Option SaveAsPdf,SaveAsWord,SaveAsExcel,Preview,Print,SaveAsHtml; XmlData: InStream; LayoutData: InStream; var DocumentStream: OutStream)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnCustomDocumentMerger(ObjectID, ReportAction, XmlData, LayoutData, DocumentStream, IsHandled);
        if (IsHandled) then
            exit;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'ReportGetCustomRdlc', '', false, false)]
    [Obsolete('This procedure will be replaced with platform functionality. Subscribe to the event FetchReportLayoutByCode instead to retrieve a layout.', '20.0')]
    local procedure ReportGetCustomRdlc(ReportId: Integer; var RdlcText: Text)
    var
        CustomReportLayout: Record "Custom Report Layout";
    begin
        RdlcText := CustomReportLayout.GetCustomRdlc(ReportId);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'ReportGetCustomWord', '', false, false)]
    [Obsolete('This procedure will be replaced with platform functionality. Subscribe to the event FetchReportLayoutByCode instead to retrieve a layout.', '20.0')]
    local procedure ReportGetCustomWord(ReportId: Integer; var LayoutStream: OutStream; var Success: Boolean)
    var
        DocumentReportManagement: Codeunit "Document Report Mgt.";
    begin
        DocumentReportManagement.GetWordLayoutStream(ReportId, LayoutStream, Success);
    end;
#endif

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'CustomDocumentMergerEx', '', false, false)]
    local procedure CustomDocumentMergerEx(ObjectID: Integer; ReportAction: Option SaveAsPdf,SaveAsWord,SaveAsExcel,Preview,Print,SaveAsHtml; ObjectPayload: JsonObject; XmlData: InStream; LayoutData: InStream; var DocumentStream: OutStream; var Success: Boolean)
    begin
        if (Success) then
            exit;

        OnCustomDocumentMergerEx(ObjectID, ReportAction, ObjectPayload, XmlData, LayoutData, DocumentStream, Success);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'SelectedBuiltinLayoutType', '', false, false)]
    local procedure SelectedBuiltinLayoutType(ObjectID: Integer; var LayoutType: Option "None",RDLC,Word,Excel,Custom)
    var
        ReportLayoutSelection: Record "Report Layout Selection";
    begin
        LayoutType := ReportLayoutSelection.SelectedBuiltinLayoutType(ObjectID);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'SubstituteReport', '', false, false)]
    local procedure SubstituteReport(ReportId: Integer; RunMode: Option Normal,ParametersOnly,Execute,Print,SaveAs,RunModal; RequestPageXml: Text; RecordRef: RecordRef; var NewReportId: Integer)
    begin
        OnAfterSubstituteReport(ReportId, RunMode, RequestPageXml, RecordRef, NewReportId);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'OnDocumentPrintReady', '', false, false)]
    local procedure OnDocumentPrintReady(ObjectType: Option "Report","Page"; ObjectID: Integer; ObjectPayload: JsonObject; DocumentStream: InStream; var Success: Boolean);
    begin
        if ObjectType <> ObjectType::Report then
            Error(NotSupportedErr);

        OnAfterDocumentPrintReady(ObjectType, ObjectId, ObjectPayload, DocumentStream, Success);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'SetupPrinters', '', true, true)]
    procedure SetupPrinters(var Printers: Dictionary of [Text[250], JsonObject]);
    begin
        OnAfterSetupPrinters(Printers);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'OnIntermediateDocumentReady', '', false, false)]
    local procedure OnIntermediateDocumentReady(ObjectId: Integer; ObjectPayload: JsonObject; DocumentStream: InStream; var TargetStream: OutStream; var Success: Boolean)
    begin
        OnAfterIntermediateDocumentReady(ObjectId, ObjectPayload, DocumentStream, TargetStream, Success);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'OnDocumentReady', '', false, false)]
    local procedure OnDocumentReady(ObjectId: Integer; ObjectPayload: JsonObject; DocumentStream: InStream; var TargetStream: OutStream; var Success: Boolean)
    begin
        OnAfterDocumentReady(ObjectId, ObjectPayload, DocumentStream, TargetStream, Success);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'OnDocumentDownload', '', false, false)]
    local procedure OnDocumentDownload(ObjectId: Integer; ObjectPayload: JsonObject; DocumentStream: InStream; var Success: Boolean)
    begin
        OnAfterDocumentDownload(ObjectId, ObjectPayload, DocumentStream, Success);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'SelectReportLayoutCode', '', false, false)]
    local procedure SelectReportLayoutCode(ObjectId: Integer; var LayoutCode: Text; var LayoutType: Option "None",RDLC,Word,Excel,Custom; var Success: Boolean)
    var
        CustomReportLayout: Record "Custom Report Layout";
        FeatureKey: Record "Feature Key";
        ReportLayoutSelection: Record "Report Layout Selection";
        DesignTimeReportSelection: Codeunit "Design-time Report Selection";
        AppLayoutType: Enum "Custom Report Layout Type";
        SelectedLayoutName: Text[250];
        SelectedAppID: Guid;
        PlatformRenderingInPlatformTxt: Label 'RenderWordReportsInPlatform', Locked = true;
    begin
        OnSelectReportLayoutCode(ObjectId, LayoutCode, LayoutType, Success);
        if Success then
            exit;

        LayoutType := LayoutType::None; // Unknown layout type
        SelectedLayoutName := DesignTimeReportSelection.GetSelectedLayout();
        SelectedAppID := DesignTimeReportSelection.GetSelectedAppID();

        // Temporarily selected layout for Design-time report execution or for looping in batch report scenarios?
        if SelectedLayoutName = '' then
            // look in the app layout selection table for a selected layout for this report id.
            if ReportLayoutSelection.Get(ObjectId, CompanyName) and
               (ReportLayoutSelection.Type = ReportLayoutSelection.Type::"Custom Layout")
            then
                SelectedLayoutName := ReportLayoutSelection."Custom Report Layout Code";

        if (SelectedLayoutName <> '') and (StrLen(SelectedLayoutName) <= MaxStrLen(CustomReportLayout."Code")) then
            // The code field in Custom Report Layout table can have a maximum size of 20 characters.
            if CustomReportLayout.Get(SelectedLayoutName.ToUpper()) then begin
                LayoutCode := CustomReportLayout.Code;
                AppLayoutType := CustomReportLayout.Type;
                case AppLayoutType of
                    AppLayoutType::RDLC:
                        LayoutType := LayoutType::RDLC;
                    AppLayoutType::Word:
                        LayoutType := LayoutType::Word;
                    else
                        // Layout Type extensions
                        if (FeatureKey.Get(PlatformRenderingInPlatformTxt) and (FeatureKey.Enabled = FeatureKey.Enabled::"All Users")) then
                            // Platform rendering - The OnCustomDocumentMerger event will handle the rendering logic
                            LayoutType := LayoutType::Custom
                        else
                            // App rendering - The type will be treated like a word file and rendered by the app.
                            LayoutType := LayoutType::Word;
                end;
                Success := true;
                exit;
            end;

        if SelectedLayoutName <> '' then begin
            // A layout code is defined, but not found in application table. The layout type is not known and it's expected that the code refers to a layout in the platform. 
            // Return the layout code to platform for further processing.
            if IsNullGuid(SelectedAppID) then
                LayoutCode := SelectedLayoutName
            else
                LayoutCode := SelectedLayoutName + '::' + Format(SelectedAppID);

            Success := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'FetchReportLayoutByCode', '', false, false)]
    local procedure FetchReportLayoutByCode(ObjectId: Integer; LayoutCode: Text; var TargetStream: OutStream; var Success: Boolean)
    var
        CustomReportLayout: Record "Custom Report Layout";
        TempBlobIn: codeunit "Temp Blob";
        TempInStream: InStream;
    begin
        OnFetchReportLayoutByCode(ObjectId, LayoutCode, TargetStream, Success);
        if Success then
            exit;

        if not CustomReportLayout.Get(LayoutCode) then
            LayoutCode := '';

        if LayoutCode <> '' then begin
            CustomReportLayout.GetLayoutBlob(TempBlobIn);
            TempBlobIn.CreateInStream(TempInStream);
            CopyStream(TargetStream, TempInStream);
            Success := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'ApplicationReportMergeStrategy', '', false, false)]
    local procedure ApplicationReportMergeStrategy(ObjectId: Integer; LayoutCode: Text; var InApplication: boolean)
    var
        IsHandled: Boolean;
    begin
        if InApplication = true then // Handled in another subscriber
            exit;
        IsHandled := false;
        OnApplicationReportMergeStrategy(ObjectId, LayoutCode, InApplication, IsHandled);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'WordDocumentMergerAppMode', '', false, false)]
    local procedure WordDocumentMergerAppMode(ObjectId: Integer; LayoutCode: Text; var InApplication: boolean)
    var
        IsHandled: Boolean;
    begin
        if InApplication = true then // Handled in another subscriber
            exit;
        IsHandled := false;
        OnWordDocumentMergerAppMode(ObjectId, LayoutCode, InApplication, IsHandled);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'SelectReportLayoutUI', '', false, false)]
    local procedure SelectReportLayoutUI(ObjectID: Integer; var LayoutName: Text; var LayoutAppID: Guid; var Success: Boolean)
    var
        ReportLayoutList: Record "Report Layout List";
        IsSelectionHandled: Boolean;
    begin
        ReportLayoutList.SetRange(ReportLayoutList."Report ID", ObjectID);
        OnSelectReportLayout(ReportLayoutList, IsSelectionHandled);

        if IsSelectionHandled and (ReportLayoutList."Report ID" = ObjectID) then begin
            LayoutName := ReportLayoutList."Name";
            LayoutAppID := ReportLayoutList."Application ID";
            Success := true;
        end;
    end;

    [IntegrationEvent(false, false)]
    procedure OnSelectReportLayout(var ReportLayoutList: Record "Report Layout List"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPrinterName(ReportID: Integer; var PrinterName: Text[250]; PrinterSelection: Record "Printer Selection")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterHasCustomLayout(ObjectType: Option "Report","Page"; ObjectID: Integer; var LayoutType: Option "None",RDLC,Word,Excel,Custom)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPaperTrayForReport(ReportID: Integer; var FirstPage: Integer; var DefaultPage: Integer; var LastPage: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSubstituteReport(ReportId: Integer; RunMode: Option Normal,ParametersOnly,Execute,Print,SaveAs,RunModal; RequestPageXml: Text; RecordRef: RecordRef; var NewReportId: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDocumentPrintReady(ObjectType: Option "Report","Page"; ObjectID: Integer; ObjectPayload: JsonObject; DocumentStream: InStream; var Success: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetupPrinters(var Printers: Dictionary of [Text[250], JsonObject]);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIntermediateDocumentReady(ObjectId: Integer; ObjectPayload: JsonObject; DocumentStream: InStream; var TargetStream: OutStream; var Success: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDocumentReady(ObjectId: Integer; ObjectPayload: JsonObject; DocumentStream: InStream; var TargetStream: OutStream; var Success: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDocumentDownload(ObjectId: Integer; ObjectPayload: JsonObject; DocumentStream: InStream; var Success: Boolean)
    begin
    end;

#if not CLEAN20
    /// <summary>
    /// Invoke the MergeDocument trigger.
    /// </summary>
    /// <param name="ObjectType">The object type for which the document will be rendered (Report).</param>
    /// <param name="ObjectId">The object id.</param>
    /// <param name="ReportAction">The report action, which can be one of SaveAsPdf, SaveAsWord, SaveAsExcel, Preview, Print or SaveAsHtml.</param>
    /// <param name="XmlData">The xml data set in an input stream</param>
    /// <param name="FileName">The file path where the output is to be stored. This parameter will contain the printer name if the print action is chosen.</param>
    /// <param name="printDocumentStream">Output stream that will contain printed documents for cloud printers</param>
    /// <param name="IsHandled">Will be set to true if the procedure call handled the merge.</param>
    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by the report event OnCustomDocumentMergerEx. Subscribe to it to change the merging behavior.', '20.0')]
    local procedure OnMergeDocumentReport(ObjectType: Option "Report","Page"; ObjectID: Integer; ReportAction: Option SaveAsPdf,SaveAsWord,SaveAsExcel,Preview,Print,SaveAsHtml; XmlData: InStream; FileName: Text; var printDocumentStream: OutStream; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by OnCustomDocumentMergerEx.', '21.0')]
    local procedure OnCustomDocumentMerger(ObjectID: Integer; ReportAction: Option SaveAsPdf,SaveAsWord,SaveAsExcel,Preview,Print,SaveAsHtml; XmlData: InStream; LayoutData: InStream; var printDocumentStream: OutStream; var IsHandled: Boolean)
    begin
    end;
#endif

    /// <summary>
    /// Invoke the OnCustomDocumentMergeEx trigger, which handled user defiend report renders given a dataset and a layout. The Render must be implemented in AL and return the output stream as defined by the format given in ReportAction.
    /// </summary>
    /// <param name="ObjectId">The report object id.</param>
    /// <param name="ReportAction">The report action, which can be one of SaveAsPdf, SaveAsWord, SaveAsExcel, Preview, Print or SaveAsHtml.</param>
    /// <param name="ObjectPayload">The JSON payload that defines metadata for the present report run.</param>
    /// <param name="XmlData">The xml data set in an input stream</param>
    /// <param name="LayoutData">The layout input stream. The actual format stored in the stream is defined by the layoutmodel json property (custom formats by the layoutmimetype property in the payload).</param>
    /// <param name="DocumentStream">Output stream that will contain the rendered output documents.</param>
    /// <param name="IsHandled">Will be set to true if the procedure call handled the merge.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCustomDocumentMergerEx(ObjectID: Integer; ReportAction: Option SaveAsPdf,SaveAsWord,SaveAsExcel,Preview,Print,SaveAsHtml; ObjectPayload: JsonObject; XmlData: InStream; LayoutData: InStream; var DocumentStream: OutStream; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Fetch the currently selected layout code and layout type from application.
    /// </summary>
    /// <param name="ObjectId">The object id.</param>
    /// <param name="LayoutCode">The report layout code if an application override has been set for the current run.</param>
    /// <param name="LayoutType">The Layout type contained in the target stream.</param>
    /// <param name="IsHandled">Will be set to true if the subscriber handled the action.</param>
    /// <remarks>Internal event that will be removed when the report runtime API has been updated</remarks>
    [IntegrationEvent(false, false)]
    local procedure OnSelectReportLayoutCode(ObjectId: Integer; var LayoutCode: Text; var LayoutType: Option "None",RDLC,Word,Excel,Custom; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Fetch the currently selected layout code from application.
    /// </summary>
    /// <param name="ObjectId">The object id.</param>
    /// <param name="LayoutCode">The report layout code if an application override has been set for the current run.</param>
    /// <param name="TargetStream">The layout will be written to this stream.</param>
    /// <param name="IsHandled">Will be set to true if the layout was found in the application database.</param>
    /// <remarks>Internal event that will be removed when the report runtime API has been updated.</remarks>
    [IntegrationEvent(false, false)]
    local procedure OnFetchReportLayoutByCode(ObjectId: Integer; LayoutCode: Text; var TargetStream: OutStream; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Select between platform or application report rendering. 
    /// If this trigger return InApplication = true, then run the report and layout in a custom report render using the OnCustomDocumentMergerEx event.
    /// </summary>
    /// <param name="ObjectId">The object id.</param>
    /// <param name="LayoutCode">The report layout code if an application override has been set for the current run.</param>
    /// <param name="InApplication">True if the applicaction should render the report.</param>
    /// <param name="IsHandled">Will be set to true if the subscriber handled the action.</param>
    [IntegrationEvent(false, false)]
    local procedure OnApplicationReportMergeStrategy(ObjectId: Integer; LayoutCode: Text; var InApplication: boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Select between platform or application report rendering for Word reports only. 
    /// If this trigger return InApplication = true, then run the report and layout in the legacy OnMergeDocumentReport event.
    /// </summary>
    /// <param name="ObjectId">The object id.</param>
    /// <param name="LayoutCode">The report layout code if an application override has been set for the current run.</param>
    /// <param name="InApplication">True if the applicaction should render the report.</param>
    /// <param name="IsHandled">Will be set to true if the subscriber handled the action.</param>
    /// <remarks>This event is for backward compatibility only and will be depricated.</remarks>
    [IntegrationEvent(false, false)]
    local procedure OnWordDocumentMergerAppMode(ObjectId: Integer; LayoutCode: Text; var InApplication: boolean; var IsHandled: Boolean)
    begin
    end;
}

