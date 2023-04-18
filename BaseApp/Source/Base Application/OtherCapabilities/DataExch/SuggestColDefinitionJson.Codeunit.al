codeunit 1238 "Suggest Col. Definition - Json"
{

    trigger OnRun()
    begin
    end;

    [Scope('OnPrem')]
    procedure GenerateDataExchColDef(URLPath: Text; DataExchLineDef: Record "Data Exch. Line Def")
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
        TempXMLBuffer: Record "XML Buffer" temporary;
        GetJsonStructure: Codeunit "Get Json Structure";
        ColumnNo: Integer;
    begin
        GetJsonStructure.GenerateStructure(URLPath, TempXMLBuffer);

        with DataExchColumnDef do begin
            SetRange("Data Exch. Def Code", DataExchLineDef."Data Exch. Def Code");
            SetRange("Data Exch. Line Def Code", DataExchLineDef.Code);
            DeleteAll();
            ColumnNo := 0;

            TempXMLBuffer.Reset();
            if TempXMLBuffer.FindSet() then
                repeat
                    ColumnNo += 10000;

                    Init();
                    Validate("Data Exch. Def Code", DataExchLineDef."Data Exch. Def Code");
                    Validate("Data Exch. Line Def Code", DataExchLineDef.Code);
                    Validate("Column No.", ColumnNo);

                    Validate(Name, TempXMLBuffer.Name);
                    Validate(Path, TempXMLBuffer.Path);
                    Insert(true);
                until TempXMLBuffer.Next() = 0;
        end;
    end;
}

