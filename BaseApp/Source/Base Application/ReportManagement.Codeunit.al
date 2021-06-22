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
    local procedure GetPrinterName(ReportID: Integer; var PrinterName: Text[250])
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
    local procedure HasCustomLayout(ObjectType: Option "Report","Page"; ObjectID: Integer; var LayoutType: Option "None",RDLC,Word)
    var
        ReportLayoutSelection: Record "Report Layout Selection";
    begin
        if ObjectType <> ObjectType::Report then
            Error(NotSupportedErr);

        LayoutType := ReportLayoutSelection.HasCustomLayout(ObjectID);
        OnAfterHasCustomLayout(ObjectType, ObjectID, LayoutType);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'MergeDocument', '', false, false)]
    local procedure MergeDocument(ObjectType: Option "Report","Page"; ObjectID: Integer; ReportAction: Option SaveAsPdf,SaveAsWord,SaveAsExcel,Preview,Print,SaveAsHtml; XmlData: InStream; FileName: Text; var DocumentStream: OutStream)
    var
        DocumentReportMgt: Codeunit "Document Report Mgt.";
    begin
        if ObjectType <> ObjectType::Report then
            Error(NotSupportedErr);

        DocumentReportMgt.MergeWordLayout(ObjectID, ReportAction, XmlData, FileName, DocumentStream);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'ReportGetCustomRdlc', '', false, false)]
    local procedure ReportGetCustomRdlc(ReportId: Integer; var RdlcText: Text)
    var
        CustomReportLayout: Record "Custom Report Layout";
    begin
        RdlcText := CustomReportLayout.GetCustomRdlc(ReportId);
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

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPrinterName(ReportID: Integer; var PrinterName: Text[250]; PrinterSelection: Record "Printer Selection")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterHasCustomLayout(ObjectType: Option "Report","Page"; ObjectID: Integer; var LayoutType: Option "None",RDLC,Word)
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
}

