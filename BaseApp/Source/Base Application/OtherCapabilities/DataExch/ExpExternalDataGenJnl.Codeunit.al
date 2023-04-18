codeunit 1277 "Exp. External Data Gen. Jnl."
{
    Permissions = TableData "Data Exch." = rimd;
    TableNo = "Data Exch.";

    trigger OnRun()
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        CalcFields("File Content");
        if not "File Content".HasValue() then
            Error(ExternalContentErr, FieldCaption("File Content"));

        TempBlob.FromRecord(Rec, FieldNo("File Content"));
        ExportToFile(Rec, TempBlob, "Data Exch. Def Code" + ' ' + "Data Exch. Line Def Code" + TxtExtTok);
    end;

    var
        ExternalContentErr: Label '%1 is empty.';
        DownloadFromStreamErr: Label 'The file has not been saved.';
        TxtExtTok: Label '.txt', Locked = true;

    local procedure ExportToFile(DataExch: Record "Data Exch."; var TempBlob: Codeunit "Temp Blob"; FileName: Text)
    var
        FileMgt: Codeunit "File Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeExportToFile(DataExch, FileName, IsHandled);
        if IsHandled then
            exit;

        if FileMgt.BLOBExport(TempBlob, FileName, true) = '' then
            Error(DownloadFromStreamErr);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeExportToFile(DataExch: Record "Data Exch."; var FileName: Text; var Handled: Boolean)
    begin
    end;
}

