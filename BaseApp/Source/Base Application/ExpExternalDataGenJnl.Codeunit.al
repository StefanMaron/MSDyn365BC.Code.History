codeunit 1277 "Exp. External Data Gen. Jnl."
{
    Permissions = TableData "Data Exch." = rimd;
    TableNo = "Data Exch.";

    trigger OnRun()
    var
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
    begin
        CalcFields("File Content");
        if not "File Content".HasValue then
            Error(ExternalContentErr, FieldCaption("File Content"));

        TempBlob.FromRecord(Rec, FieldNo("File Content"));
        if FileMgt.BLOBExport(TempBlob, "Data Exch. Def Code" + ' ' + "Data Exch. Line Def Code" + TxtExtTok, true) = '' then
            Error(DownloadFromStreamErr);
    end;

    var
        ExternalContentErr: Label '%1 is empty.';
        DownloadFromStreamErr: Label 'The file has not been saved.';
        TxtExtTok: Label '.txt', Locked = true;
}

