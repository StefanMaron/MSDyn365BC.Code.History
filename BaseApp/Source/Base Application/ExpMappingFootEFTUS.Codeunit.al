codeunit 10330 "Exp. Mapping Foot EFT US"
{
    TableNo = "Data Exch.";

    trigger OnRun()
    var
        ACHUSFooter: Record "ACH US Footer";
        DataExch: Record "Data Exch.";
        DataExchLineDef: Record "Data Exch. Line Def";
        EFTExportMgt: Codeunit "EFT Export Mgt";
        RecordRef: RecordRef;
        LineNo: Integer;
    begin
        // Range through the Footer record
        LineNo := 1;
        DataExchLineDef.Init();
        DataExchLineDef.SetRange("Data Exch. Def Code", "Data Exch. Def Code");
        DataExchLineDef.SetRange("Line Type", DataExchLineDef."Line Type"::Footer);
        if DataExchLineDef.FindFirst() then begin
            DataExch.SetRange("Entry No.", "Entry No.");
            if DataExch.FindFirst() then
                if ACHUSFooter.Get("Entry No.") then begin
                    RecordRef.GetTable(ACHUSFooter);
                    EFTExportMgt.InsertDataExchLineForFlatFile(
                      DataExch,
                      LineNo,
                      RecordRef);
                end;
        end;
    end;
}

