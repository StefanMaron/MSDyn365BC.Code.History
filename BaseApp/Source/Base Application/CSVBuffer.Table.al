table 1234 "CSV Buffer"
{
    Caption = 'CSV Buffer';
    ReplicateData = false;

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = SystemMetadata;
        }
        field(2; "Field No."; Integer)
        {
            Caption = 'Field No.';
            DataClassification = SystemMetadata;
        }
        field(3; Value; Text[250])
        {
            Caption = 'Value';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Line No.", "Field No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        IndexDoesNotExistErr: Label 'The field in line %1 with index %2 does not exist. The data could not be retrieved.', Comment = '%1 = line no, %2 = index of the field';
        CSVFile: DotNet File;
        StreamReader: DotNet StreamReader;
        Separator: Text[1];

    procedure InsertEntry(LineNo: Integer; FieldNo: Integer; FieldValue: Text[250])
    begin
        Init;
        "Line No." := LineNo;
        "Field No." := FieldNo;
        Value := FieldValue;
        Insert;
    end;

    [Scope('OnPrem')]
    procedure LoadData(CSVFileName: Text; CSVFieldSeparator: Text[1])
    begin
        InitializeReader(CSVFileName, CSVFieldSeparator);
        ReadLines(0);
        StreamReader.Close;
    end;

    procedure LoadDataFromStream(CSVInStream: InStream; CSVFieldSeparator: Text[1])
    begin
        InitializeReaderFromStream(CSVInStream, CSVFieldSeparator);
        ReadLines(0);
        StreamReader.Close;
    end;

    [Scope('OnPrem')]
    procedure SaveData(CSVFileName: Text; CSVFieldSeparator: Text[1])
    var
        FileMode: DotNet FileMode;
        StreamWriter: DotNet StreamWriter;
    begin
        StreamWriter := StreamWriter.StreamWriter(CSVFile.Open(CSVFileName, FileMode.Create));
        WriteToStream(StreamWriter, CSVFieldSeparator);
        StreamWriter.Close;
    end;

    procedure SaveDataToBlob(var TempBlob: Codeunit "Temp Blob"; CSVFieldSeparator: Text[1])
    var
        CSVOutStream: OutStream;
        StreamWriter: DotNet StreamWriter;
    begin
        TempBlob.CreateOutStream(CSVOutStream);
        StreamWriter := StreamWriter.StreamWriter(CSVOutStream);
        WriteToStream(StreamWriter, CSVFieldSeparator);
        StreamWriter.Close;
    end;

    local procedure WriteToStream(var StreamWriter: DotNet StreamWriter; CSVFieldSeparator: Text[1])
    var
        NumberOfColumns: Integer;
    begin
        NumberOfColumns := GetNumberOfColumns;
        if FindSet then
            repeat
                StreamWriter.Write(Value);
                if "Field No." < NumberOfColumns then
                    StreamWriter.Write(CSVFieldSeparator)
                else
                    StreamWriter.WriteLine;
            until Next = 0;
    end;

    [Scope('OnPrem')]
    procedure InitializeReader(CSVFileName: Text; CSVFieldSeparator: Text[1])
    var
        FileManagement: Codeunit "File Management";
        Encoding: DotNet Encoding;
    begin
        FileManagement.IsAllowedPath(CSVFileName, false);
        StreamReader := StreamReader.StreamReader(CSVFile.OpenRead(CSVFileName), Encoding.Default);
        Separator := CSVFieldSeparator;
    end;

    procedure InitializeReaderFromStream(CSVInStream: InStream; CSVFieldSeparator: Text[1])
    begin
        StreamReader := StreamReader.StreamReader(CSVInStream);
        Separator := CSVFieldSeparator;
    end;

    [Scope('OnPrem')]
    procedure ReadLines(NumberOfLines: Integer): Boolean
    var
        String: DotNet String;
        CurrentLineNo: Integer;
        CurrentFieldNo: Integer;
        CurrentIndex: Integer;
        NextIndex: Integer;
        Length: Integer;
    begin
        if StreamReader.EndOfStream then
            exit(false);
        repeat
            String := StreamReader.ReadLine;
            CurrentLineNo += 1;
            CurrentIndex := 0;
            repeat
                CurrentFieldNo += 1;
                Init;
                "Line No." := CurrentLineNo;
                "Field No." := CurrentFieldNo;
                NextIndex := String.IndexOf(Separator, CurrentIndex);
                if NextIndex = -1 then
                    Length := String.Length - CurrentIndex
                else
                    Length := NextIndex - CurrentIndex;
                if Length > 250 then
                    Length := 250;
                Value := String.Substring(CurrentIndex, Length);
                CurrentIndex := NextIndex + 1;
                Insert;
            until NextIndex = -1;
            CurrentFieldNo := 0;
        until StreamReader.EndOfStream or (CurrentLineNo = NumberOfLines);
        exit(true);
    end;

    procedure ResetFilters()
    begin
        SetRange("Line No.");
        SetRange("Field No.");
        SetRange(Value);
    end;

    procedure GetValue(LineNo: Integer; FieldNo: Integer): Text[250]
    var
        TempCSVBuffer: Record "CSV Buffer" temporary;
    begin
        TempCSVBuffer.Copy(Rec, true);
        if not TempCSVBuffer.Get(LineNo, FieldNo) then
            Error(IndexDoesNotExistErr, LineNo, FieldNo);
        exit(TempCSVBuffer.Value);
    end;

    procedure GetCSVLinesWhere(FilterFieldNo: Integer; FilterValue: Text; var TempResultCSVBuffer: Record "CSV Buffer" temporary)
    var
        TempCSVBuffer: Record "CSV Buffer" temporary;
    begin
        TempResultCSVBuffer.Reset();
        TempResultCSVBuffer.DeleteAll();
        TempCSVBuffer.Copy(Rec, true);
        SetRange("Field No.", FilterFieldNo);
        SetRange(Value, FilterValue);
        if FindSet then
            repeat
                TempCSVBuffer.SetRange("Line No.", "Line No.");
                TempCSVBuffer.FindSet;
                repeat
                    TempResultCSVBuffer := TempCSVBuffer;
                    TempResultCSVBuffer.Insert();
                until TempCSVBuffer.Next = 0;
            until Next = 0;
        TempResultCSVBuffer.SetRange("Field No.", 1);
    end;

    procedure GetValueOfLineAt(FieldNo: Integer): Text[250]
    var
        TempCSVBuffer: Record "CSV Buffer" temporary;
    begin
        TempCSVBuffer.Copy(Rec, true);
        if not TempCSVBuffer.Get("Line No.", FieldNo) then
            Error(IndexDoesNotExistErr, "Line No.", FieldNo);
        exit(TempCSVBuffer.Value);
    end;

    procedure GetNumberOfColumns(): Integer
    var
        TempCSVBuffer: Record "CSV Buffer" temporary;
    begin
        TempCSVBuffer.Copy(Rec, true);
        TempCSVBuffer.ResetFilters;
        TempCSVBuffer.SetRange("Line No.", "Line No.");
        if TempCSVBuffer.FindLast then
            exit(TempCSVBuffer."Field No.");

        exit(0);
    end;

    procedure GetNumberOfLines(): Integer
    begin
        if FindLast then
            exit("Line No.");

        exit(0);
    end;
}

