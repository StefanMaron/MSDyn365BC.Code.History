codeunit 10335 "Exp. Mapping Det EFT MX"
{
    TableNo = "Data Exch.";

    trigger OnRun()
    var
        ACHCecobanDetail: Record "ACH Cecoban Detail";
        DataExch: Record "Data Exch.";
        EFTExportMgt: Codeunit "EFT Export Mgt";
        RecordRef: RecordRef;
        LineNo: Integer;
    begin
        if NoDataExchLineDef("Data Exch. Def Code") then
            exit;

        LineNo := 1;

        if ACHCecobanDetail.Find('-') then
            repeat
                DataExch.SetRange("Entry No.", "Entry No.");
                if DataExch.FindFirst then begin
                    RecordRef.GetTable(ACHCecobanDetail);
                    EFTExportMgt.InsertDataExchLineForFlatFile(
                      DataExch,
                      LineNo,
                      RecordRef);
                    LineNo := LineNo + 1;
                end;
            until ACHCecobanDetail.Next() = 0;
        ACHCecobanDetail.DeleteAll();
    end;

    local procedure NoDataExchLineDef(DataExchDefCode: Code[20]): Boolean
    var
        DataExchLineDef: Record "Data Exch. Line Def";
    begin
        with DataExchLineDef do begin
            Init;
            SetRange("Data Exch. Def Code", DataExchDefCode);
            SetRange("Line Type", "Line Type"::Detail);
            exit(IsEmpty);
        end;
    end;
}

