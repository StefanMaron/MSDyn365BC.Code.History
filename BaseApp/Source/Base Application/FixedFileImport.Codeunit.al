codeunit 1241 "Fixed File Import"
{
    Permissions = TableData "Data Exch. Field" = rimd;
    TableNo = "Data Exch.";

    trigger OnRun()
    var
        ReadStream: InStream;
        ReadText: Text;
        ReadLen: Integer;
        LineNo: Integer;
        SkippedLineNo: Integer;
    begin
        "File Content".CreateInStream(ReadStream);
        DataExchDef.Get("Data Exch. Def Code");
        LineNo := 1;
        repeat
            ReadLen := ReadStream.ReadText(ReadText);
            if ReadLen > 0 then
                ParseLine(ReadText, Rec, LineNo, SkippedLineNo);
        until ReadLen = 0;
    end;

    var
        DataExchDef: Record "Data Exch. Def";

    local procedure ParseLine(Line: Text; DataExch: Record "Data Exch."; var LineNo: Integer; var SkippedLineNo: Integer)
    var
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchField: Record "Data Exch. Field";
        StartPosition: Integer;
    begin
        DataExchLineDef.SetRange("Data Exch. Def Code", DataExch."Data Exch. Def Code");
        DataExchLineDef.FindFirst;

        if ((LineNo + SkippedLineNo) <= DataExchDef."Header Lines") or
           ((DataExchLineDef."Data Line Tag" <> '') and (StrPos(Line, DataExchLineDef."Data Line Tag") <> 1))
        then begin
            SkippedLineNo += 1;
            exit;
        end;

        DataExchColumnDef.SetRange("Data Exch. Def Code", DataExch."Data Exch. Def Code");
        DataExchColumnDef.SetRange("Data Exch. Line Def Code", DataExchLineDef.Code);
        DataExchColumnDef.FindSet;

        StartPosition := 1;
        repeat
            DataExchField.InsertRecXMLField(DataExch."Entry No.", LineNo, DataExchColumnDef."Column No.", '',
              CopyStr(Line, StartPosition, DataExchColumnDef.Length), DataExchLineDef.Code);
            StartPosition += DataExchColumnDef.Length;
        until DataExchColumnDef.Next = 0;
        LineNo += 1;
    end;
}

