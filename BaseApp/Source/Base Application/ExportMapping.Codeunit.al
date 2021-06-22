codeunit 1269 "Export Mapping"
{
    Permissions = TableData "Data Exch." = rimd;
    TableNo = "Data Exch.";

    trigger OnRun()
    var
        DataExchMapping: Record "Data Exch. Mapping";
        PaymentExportMgt: Codeunit "Payment Export Mgt";
        SourceRecRef: RecordRef;
        Window: Dialog;
        LineNo: Integer;
    begin
        FindMapping(DataExchMapping, "Data Exch. Def Code", "Data Exch. Line Def Code");

        SetTableFilters(SourceRecRef, DataExchMapping."Table ID", ReadTableFilters(Rec));

        Window.Open(ProgressMsg);

        repeat
            LineNo += 1;
            Window.Update(1, LineNo);

            PaymentExportMgt.ProcessColumnMapping(Rec, SourceRecRef, LineNo, "Data Exch. Line Def Code", SourceRecRef.Number);
        until SourceRecRef.Next = 0;

        Window.Close;
    end;

    var
        ProgressMsg: Label 'Processing line no. #1######.';
        MappingNotFoundErr: Label 'No mapping was found for format definition %1 and line definition %2.';
        RecordsNotFoundErr: Label 'No records were found for source table %1 using the filters: %2.';

    local procedure FindMapping(var DataExchMapping: Record "Data Exch. Mapping"; DataExchDefCode: Code[20]; DataExchLineDefCode: Code[20])
    begin
        DataExchMapping.SetRange("Data Exch. Def Code", DataExchDefCode);
        DataExchMapping.SetRange("Data Exch. Line Def Code", DataExchLineDefCode);

        if not DataExchMapping.FindFirst then
            Error(MappingNotFoundErr, DataExchDefCode, DataExchLineDefCode);
    end;

    local procedure SetTableFilters(RecRef: RecordRef; TableID: Integer; Filters: Text)
    begin
        RecRef.Open(TableID);
        RecRef.SetView(Filters);

        if not RecRef.FindSet then
            Error(RecordsNotFoundErr, TableID, RecRef.GetView);
    end;

    local procedure ReadTableFilters(DataExch: Record "Data Exch.") TableFilters: Text
    var
        TableFiltersInStream: InStream;
    begin
        if not DataExch."Table Filters".HasValue then
            exit('');

        DataExch.CalcFields("Table Filters");
        DataExch."Table Filters".CreateInStream(TableFiltersInStream);
        TableFiltersInStream.ReadText(TableFilters);
    end;
}

