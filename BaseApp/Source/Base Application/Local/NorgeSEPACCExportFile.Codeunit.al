codeunit 10638 "Norge SEPA CC-Export File"
{
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    var
        SEPACTExportFile: Codeunit "SEPA CT-Export File";
    begin
        if ExportToServerFile then
            SEPACTExportFile.EnableExportToServerFile();
        SEPACTExportFile.Run(Rec);
    end;

    var
        ExportToServerFile: Boolean;

    [Scope('OnPrem')]
    procedure EnableExportToServerFile()
    begin
        ExportToServerFile := true;
    end;
}

