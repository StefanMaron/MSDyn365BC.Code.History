report 11015 "Export Business Data"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Export Business Data';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Data Export Record Definition"; "Data Export Record Definition")
        {
            DataItemTableView = SORTING("Data Export Code", "Data Exp. Rec. Type Code");
            RequestFilterFields = "Data Export Code", "Data Exp. Rec. Type Code";

            trigger OnAfterGetRecord()
            var
                DataExportManagement: Codeunit "Data Export Management";
                ServerPath: Text;
                StartDateTime: DateTime;
                LastStreamNo: Integer;
            begin
                TestField(Description);
                if "DTD File Name" = '' then
                    Error(DTDFileNotExistsErr);

                ServerPath := GetTempFilePath;

                CheckRecordDefinition("Data Export Code", "Data Exp. Rec. Type Code");
                StartDateTime := CurrentDateTime;
                LastStreamNo := OpenFiles("Data Export Record Definition", ServerPath);

                if GuiAllowed then
                    Window.Update(1, CreatingXMLFileMsg);
                DataExportManagement.CreateIndexXML(TempDataExportRecordSource, ServerPath, Description, StartDate, EndDate, "DTD File Name");
                ExportDTDFile("Data Export Record Definition", ServerPath);

                WriteData("Data Export Record Definition");
                CloseStreams(LastStreamNo);

                if GuiAllowed then
                    Window.Update(1, CreatingLogFileMsg);
                CreateLogFile(ServerPath, CurrentDateTime - StartDateTime);

                DownloadFiles("Data Export Record Definition", ServerPath);
            end;

            trigger OnPreDataItem()
            begin
                if StartDate = 0D then
                    Error(StartDateErr);

                if EndDate = 0D then
                    Error(EndDateErr);

                if GuiAllowed then
                    Window.Open(TableNameMsg + ProgressBarMsg);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(StartDate; StartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the date from which the report or batch job processes information.';
                    }
                    field(EndDate; EndDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the last date that the report includes data for.';
                    }
                    field(CloseDate; CloseDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include Closing Date';
                        ToolTip = 'Specifies if the data export must include the closing date for the period.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnInitReport()
    var
        AccPeriod: Record "Accounting Period";
    begin
        FillCharsToDelete;

        StartDate := AccPeriod.GetFiscalYearStartDate(WorkDate);
        EndDate := AccPeriod.GetFiscalYearEndDate(WorkDate);
    end;

    trigger OnPreReport()
    begin
        GLSetup.Get;
    end;

    var
        GLSetup: Record "General Ledger Setup";
        TempDataExportRecordSource: Record "Data Export Record Source" temporary;
        DataCompression: Codeunit "Data Compression";
        FileMgt: Codeunit "File Management";
        PathHelper: DotNet Path;
        StreamArr: array[100] of DotNet StreamWriter;
        StartDate: Date;
        EndDate: Date;
        Window: Dialog;
        TotalNoOfRecords: Integer;
        NoOfRecords: Integer;
        NoOfRecordsArr: array[100] of Integer;
        StepValue: Integer;
        NextStep: Integer;
        CloseDate: Boolean;
        ValueWithQuotesMsg: Label '"%1"';
        CreatingXMLFileMsg: Label 'Creating XML File...';
        StartDateErr: Label 'You must enter a starting date.';
        EndDateErr: Label 'You must enter an ending date.';
        DateFilterMsg: Label '%1 to %2.', Comment = '<01.01.2014> to <31.01.2014>';
        DefineTableRelationErr: Label 'You must define a %1 for table %2.';
        DTDFileNotExistsErr: Label 'The DTD file does not exist.';
        NoticeMsg: Label 'Important Notice:';
        PrimaryKeyField1Msg: Label 'The %1 for table %2 that you defined contains primary key fields that are not specified at the top of the list.', Comment = 'The <Data Export Record Field> for table <G/L Entry> that you defined.';
        PrimaryKeyField2Msg: Label 'In this case, the order of the fields that you want to export will not match the order that is stated in the .xml file.';
        PrimaryKeyField3Msg: Label 'If you want to use the exported data for digital audit purposes, make sure that primary key fields are specified first, followed by ordinary fields.';
        PrimaryKeyField4Msg: Label 'Do you want to continue?';
        TableNameMsg: Label 'Table Name:       #1#################\';
        CreatingLogFileMsg: Label 'Creating Log File...';
        DurationMsg: Label 'Duration: %1.';
        LogEntryMsg: Label 'For table %1, %2 data records were exported, and file %3 was created.', Comment = 'For table <G/L Entry>, <9491> data records were exported, and file <GL_Entry.txt> was created.';
        LogFileNameTxt: Label 'Log.txt';
        IndexFileNameTxt: Label 'index.xml';
        NoOfDefinedTablesMsg: Label 'Number of defined tables: %1.';
        NoOfEmptyTablesMsg: Label 'Number of empty tables: %1.';
        ProgressBarMsg: Label 'Progress:         @5@@@@@@@@@@@@@@@@@\';
        NoExportFieldsErr: Label 'Data cannot be exported because no fields have been defined for one or more tables in the %1 data export.';
        CharsToDelete: Text;
        NewLine: Text[2];
        ExceedNoOfStreamsErr: Label '%2 cannot write to more than %1 files.', Comment = '%2 - product name';
        ClientFileName: Text;

    [Scope('OnPrem')]
    procedure InitializeRequest(FromDate: Date; ToDate: Date)
    begin
        StartDate := FromDate;
        EndDate := ToDate;
        CloseDate := false;
    end;

    local procedure OpenFiles(DataExportRecordDefinition: Record "Data Export Record Definition"; ServerPath: Text) LastStreamNo: Integer
    var
        DataExportRecordSource: Record "Data Export Record Source";
        OutServerFile: DotNet File;
        MaxNumOfStreams: Integer;
    begin
        Clear(NoOfRecordsArr);
        Clear(StreamArr);

        with DataExportRecordSource do begin
            Reset;
            SetCurrentKey("Data Export Code", "Data Exp. Rec. Type Code", "Line No.");
            SetRange("Data Export Code", DataExportRecordDefinition."Data Export Code");
            SetRange("Data Exp. Rec. Type Code", DataExportRecordDefinition."Data Exp. Rec. Type Code");
            MaxNumOfStreams := ArrayLen(StreamArr);
            if Count > MaxNumOfStreams then
                Error(ExceedNoOfStreamsErr, MaxNumOfStreams, PRODUCTNAME.Full);
            LastStreamNo := 0;
            if FindSet then
                repeat
                    TestField("Export File Name");
                    Validate("Table Filter");

                    CalcFields("Table Name");
                    if GuiAllowed then
                        Window.Update(1, "Table Name");

                    LastStreamNo += 1;
                    StreamArr[LastStreamNo] := OutServerFile.CreateText(ServerPath + '\' + "Export File Name");

                    InsertFilesExportBuffer(DataExportRecordSource, LastStreamNo);

                    TotalNoOfRecords += CountRecords(TempDataExportRecordSource);
                until Next = 0;
            StepValue := TotalNoOfRecords div 100;
            if GuiAllowed then
                Window.Update(1, '');
        end;
    end;

    local procedure CountRecords(DataExportRecordSource: Record "Data Export Record Source") TotalRecords: Integer
    var
        RecordRef: RecordRef;
    begin
        with DataExportRecordSource do begin
            RecordRef.Open("Table No.");
            RecordRef.CurrentKeyIndex("Key No.");
            SetPeriodFilter("Period Field No.", RecordRef);
            TotalRecords := RecordRef.Count;
            RecordRef.Close;
        end;
    end;

    local procedure InsertFilesExportBuffer(DataExportRecordSource: Record "Data Export Record Source"; StreamNo: Integer)
    begin
        with TempDataExportRecordSource do begin
            TempDataExportRecordSource := DataExportRecordSource;
            Indentation := StreamNo;
            if "Key No." = 0 then
                "Key No." := 1;
            Insert;
        end;
    end;

    local procedure ExportDTDFile(DataExportRecordDefinition: Record "Data Export Record Definition"; ServerPath: Text)
    var
        DTDFileOnServer: File;
        InStr: InStream;
        OutStr: OutStream;
    begin
        with DataExportRecordDefinition do begin
            CalcFields("DTD File");
            "DTD File".CreateInStream(InStr);
            DTDFileOnServer.Create(ServerPath + '\' + "DTD File Name");
            DTDFileOnServer.CreateOutStream(OutStr);
            CopyStream(OutStr, InStr);
            DTDFileOnServer.Close;
        end;
    end;

    local procedure CreateLogFile(ExportPath: Text; Duration: Duration)
    var
        LogFile: File;
        NoOfDefinedTables: Integer;
        NoOfEmptyTables: Integer;
    begin
        LogFile.TextMode(true);
        LogFile.Create(ExportPath + '\' + LogFileNameTxt);

        LogFile.Write(StrSubstNo(DateFilterMsg, Format(StartDate), Format(CalcEndDate(EndDate))));
        LogFile.Write(Format(Today));
        with TempDataExportRecordSource do begin
            Reset;
            if FindSet then begin
                NoOfDefinedTables := 0;
                NoOfEmptyTables := 0;
                LogFile.Write("Data Export Code" + ';' + "Data Exp. Rec. Type Code");
                repeat
                    if NoOfRecordsArr[Indentation] = 0 then
                        NoOfEmptyTables += 1
                    else
                        NoOfDefinedTables += 1;
                    CalcFields("Table Name");
                    LogFile.Write(StrSubstNo(LogEntryMsg, "Table Name", NoOfRecordsArr[Indentation], "Export File Name"));
                until Next = 0;
            end;
        end;
        LogFile.Write(StrSubstNo(NoOfDefinedTablesMsg, NoOfDefinedTables));
        LogFile.Write(StrSubstNo(NoOfEmptyTablesMsg, NoOfEmptyTables));
        LogFile.Write(StrSubstNo(DurationMsg, Duration));
        LogFile.Close;
    end;

    local procedure WriteData(DataExportRecordDefinition: Record "Data Export Record Definition")
    var
        CurrTempDataExportRecordSource: Record "Data Export Record Source";
        RecRef: RecordRef;
    begin
        with TempDataExportRecordSource do begin
            Reset;
            SetRange("Data Export Code", DataExportRecordDefinition."Data Export Code");
            SetRange("Data Exp. Rec. Type Code", DataExportRecordDefinition."Data Exp. Rec. Type Code");
            SetRange("Relation To Line No.", 0);
            if FindSet then
                repeat
                    CurrTempDataExportRecordSource.Copy(TempDataExportRecordSource);
                    RecRef.Open("Table No.");
                    ApplyTableFilter(TempDataExportRecordSource, RecRef);
                    WriteTable(TempDataExportRecordSource, RecRef);
                    RecRef.Close;
                    Copy(CurrTempDataExportRecordSource);
                until Next = 0;
        end;
    end;

    local procedure WriteTable(DataExportRecordSource: Record "Data Export Record Source"; var RecRef: RecordRef)
    var
        RecRefToExport: RecordRef;
    begin
        with DataExportRecordSource do
            if RecRef.FindSet then begin
                NoOfRecordsArr[Indentation] += RecRef.Count;
                if GuiAllowed then
                    Window.Update(1, RecRef.Caption);
                repeat
                    RecRefToExport := RecRef.Duplicate;
                    WriteRecord(DataExportRecordSource, RecRefToExport);
                    UpdateProgressBar;
                    WriteRelatedRecords(DataExportRecordSource, RecRefToExport);
                until RecRef.Next = 0;
            end;
    end;

    local procedure UpdateProgressBar()
    begin
        NoOfRecords := NoOfRecords + 1;
        if NoOfRecords >= NextStep then begin
            if TotalNoOfRecords <> 0 then
                if GuiAllowed then
                    Window.Update(5, Round(NoOfRecords / TotalNoOfRecords * 10000, 1));
            NextStep := NextStep + StepValue;
        end;
    end;

    local procedure ApplyTableFilter(DataExportRecordSource: Record "Data Export Record Source"; var RecRef: RecordRef)
    var
        TableFilterPage: Page "Table Filter";
        TableFilterText: Text;
    begin
        with DataExportRecordSource do begin
            TableFilterText := Format("Table Filter");
            if TableFilterText <> '' then begin
                TableFilterPage.SetSourceTable(TableFilterText, "Table No.", "Table Name");
                RecRef.SetView(TableFilterPage.GetViewFilter);
                SetFlowFilterDateFields(DataExportRecordSource, RecRef);
            end;
            RecRef.CurrentKeyIndex("Key No.");
            SetPeriodFilter("Period Field No.", RecRef);
        end;
    end;

    local procedure WriteRelatedRecords(var ParentDataExportRecordSource: Record "Data Export Record Source"; ParentRecRef: RecordRef)
    var
        DataExportTableRelation: Record "Data Export Table Relation";
        RelatedRecRef: RecordRef;
        RelatedFieldRef: FieldRef;
        ParentFieldRef: FieldRef;
    begin
        with TempDataExportRecordSource do begin
            Reset;
            SetRange("Data Export Code", ParentDataExportRecordSource."Data Export Code");
            SetRange("Data Exp. Rec. Type Code", ParentDataExportRecordSource."Data Exp. Rec. Type Code");
            SetRange("Relation To Line No.", ParentDataExportRecordSource."Line No.");
            if FindSet then begin
                DataExportTableRelation.Reset;
                DataExportTableRelation.SetRange("Data Export Code", "Data Export Code");
                DataExportTableRelation.SetRange("Data Exp. Rec. Type Code", "Data Exp. Rec. Type Code");
                DataExportTableRelation.SetRange("From Table No.", ParentDataExportRecordSource."Table No.");
                repeat
                    DataExportTableRelation.SetRange("To Table No.", "Table No.");
                    if DataExportTableRelation.FindSet then begin
                        RelatedRecRef.Open("Table No.");
                        ApplyTableFilter(TempDataExportRecordSource, RelatedRecRef);
                        repeat
                            ParentFieldRef := ParentRecRef.Field(DataExportTableRelation."From Field No.");
                            RelatedFieldRef := RelatedRecRef.Field(DataExportTableRelation."To Field No.");
                            RelatedFieldRef.SetRange(ParentFieldRef.Value);
                        until DataExportTableRelation.Next = 0;

                        WriteTable(TempDataExportRecordSource, RelatedRecRef);

                        SetRange("Relation To Line No.", ParentDataExportRecordSource."Line No.");

                        RelatedRecRef.Close;
                    end else begin
                        CalcFields("Table Name");
                        Error(DefineTableRelationErr, DataExportTableRelation.TableCaption, "Table Name");
                    end;
                until Next = 0;
            end;
        end;
    end;

    local procedure SetPeriodFilter(PeriodFieldNo: Integer; var RecRef: RecordRef)
    var
        FieldRef: FieldRef;
    begin
        if PeriodFieldNo <> 0 then begin
            FieldRef := RecRef.Field(PeriodFieldNo);
            FieldRef.SetRange(StartDate, CalcEndDate(EndDate));
        end;
    end;

    local procedure WriteRecord(var DataExportRecordSource: Record "Data Export Record Source"; var RecRef: RecordRef)
    var
        DataExportRecordField: Record "Data Export Record Field";
        RecordText: Text;
        FieldValue: Text;
    begin
        if FindFields(DataExportRecordField, DataExportRecordSource) then begin
            repeat
                FieldValue :=
                  GetDataExportRecFieldValue(
                    DataExportRecordField, DataExportRecordSource."Date Filter Field No.", RecRef);
                RecordText += FieldValue + ';';
            until DataExportRecordField.Next = 0;
            RecordText := CopyStr(RecordText, 1, StrLen(RecordText) - 1);
            StreamArr[DataExportRecordSource.Indentation].WriteLine(RecordText);
        end else
            Error(NoExportFieldsErr, DataExportRecordSource."Data Export Code");
    end;

    local procedure FormatField2String(var FieldRef: FieldRef; DataExportRecordField: Record "Data Export Record Field") FieldValueText: Text
    var
        OptionNo: Integer;
    begin
        with DataExportRecordField do begin
            case "Field Type" of
                "Field Type"::Option:
                    begin
                        OptionNo := FieldRef.Value;
                        if OptionNo <= GetMaxOptionIndex(FieldRef.OptionCaption) then
                            FieldValueText := SelectStr(OptionNo + 1, Format(FieldRef.OptionCaption))
                        else
                            FieldValueText := Format(OptionNo);
                    end;
                "Field Type"::Decimal:
                    FieldValueText := Format(FieldRef.Value, 0, '<Precision,' + GLSetup."Amount Decimal Places" + '><Standard Format,0>');
                "Field Type"::Date:
                    FieldValueText := Format(FieldRef.Value, 10, '<day,2>.<month,2>.<year4>');
                else
                    FieldValueText := Format(FieldRef.Value);
            end;
            if "Field Type" in ["Field Type"::Boolean, "Field Type"::Code, "Field Type"::Option, "Field Type"::Text] then
                FieldValueText := StrSubstNo(ValueWithQuotesMsg, ConvertString(FieldValueText));
        end;
    end;

    local procedure ConvertString(String: Text) NewString: Text
    begin
        NewString := DelChr(String, '=', CharsToDelete);
    end;

    local procedure GetTempFilePath(): Text[1024]
    var
        TempFile: File;
        TempFileName: Text[1024];
    begin
        TempFile.CreateTempFile;
        TempFileName := TempFile.Name;
        TempFile.Close;
        exit(
          PathHelper.GetFullPath(
            PathHelper.Combine(
              PathHelper.GetDirectoryName(TempFileName),
              '..')));
    end;

    local procedure CheckRecordDefinition(ExportCode: Code[10]; RecordCode: Code[10])
    var
        DataExportRecordSource: Record "Data Export Record Source";
        DataExportRecordField: Record "Data Export Record Field";
        RecRef: RecordRef;
        KeyRef: KeyRef;
        FieldRef: FieldRef;
        ActiveKeyFound: Boolean;
        KeyFieldFound: Boolean;
        NonKeyFieldFound: Boolean;
        FieldMismatch: Boolean;
        i: Integer;
        j: Integer;
    begin
        DataExportRecordSource.Reset;
        DataExportRecordSource.SetRange("Data Export Code", ExportCode);
        DataExportRecordSource.SetRange("Data Exp. Rec. Type Code", RecordCode);
        if DataExportRecordSource.FindSet then
            repeat
                RecRef.Open(DataExportRecordSource."Table No.");
                i := 0;
                ActiveKeyFound := false;
                NonKeyFieldFound := false;
                FieldMismatch := false;
                repeat
                    i := i + 1;
                    KeyRef := RecRef.KeyIndex(i);
                    if KeyRef.Active then
                        ActiveKeyFound := true;
                until (i >= RecRef.KeyCount) or ActiveKeyFound;
                if ActiveKeyFound then
                    if FindFields(DataExportRecordField, DataExportRecordSource) then
                        repeat
                            KeyFieldFound := false;
                            for j := 1 to KeyRef.FieldCount do begin
                                FieldRef := KeyRef.FieldIndex(j);
                                if DataExportRecordField."Field No." = FieldRef.Number then
                                    KeyFieldFound := true;
                            end;
                            if not KeyFieldFound then
                                NonKeyFieldFound := true;
                            if NonKeyFieldFound and KeyFieldFound then begin
                                FieldMismatch := true;
                                DataExportRecordField.CalcFields("Table Name");
                                if GuiAllowed then
                                    if not Confirm(NoticeMsg + '\' + '\' +
                                         PrimaryKeyField1Msg + ' ' +
                                         PrimaryKeyField2Msg + ' ' +
                                         PrimaryKeyField3Msg + '\' + '\' +
                                         PrimaryKeyField4Msg,
                                         true,
                                         DataExportRecordField.TableCaption,
                                         DataExportRecordField."Table Name")
                                    then
                                        Error('');
                            end;
                        until FieldMismatch or (DataExportRecordField.Next = 0);
                RecRef.Close;
            until FieldMismatch or (DataExportRecordSource.Next = 0);
    end;

    [Scope('OnPrem')]
    procedure FindFields(var DataExportRecordField: Record "Data Export Record Field"; var DataExportRecordSource: Record "Data Export Record Source"): Boolean
    begin
        with DataExportRecordField do begin
            SetRange("Data Export Code", DataExportRecordSource."Data Export Code");
            SetRange("Data Exp. Rec. Type Code", DataExportRecordSource."Data Exp. Rec. Type Code");
            SetRange("Source Line No.", DataExportRecordSource."Line No.");
            exit(FindSet);
        end;
    end;

    local procedure SetFlowFilterDateFields(DataExportRecordSource: Record "Data Export Record Source"; var RecRef: RecordRef)
    var
        DataExportRecordField: Record "Data Export Record Field";
    begin
        if DataExportRecordSource."Date Filter Handling" <> DataExportRecordSource."Date Filter Handling"::" " then begin
            DataExportRecordField.Init;
            DataExportRecordField."Table No." := DataExportRecordSource."Table No.";
            DataExportRecordField."Date Filter Handling" := DataExportRecordSource."Date Filter Handling";
            SetFlowFilterDateField(DataExportRecordField, DataExportRecordSource."Date Filter Field No.", RecRef);
        end;
    end;

    local procedure SetFlowFilterDateField(var DataExportRecordField: Record "Data Export Record Field"; DateFilterFieldNo: Integer; var RecRef: RecordRef)
    var
        "Field": Record "Field";
    begin
        if DateFilterFieldNo > 0 then
            SetFlowFilter(DateFilterFieldNo, DataExportRecordField."Date Filter Handling", RecRef)
        else begin
            Field.Reset;
            Field.SetRange(TableNo, DataExportRecordField."Table No.");
            Field.SetRange(Type, Field.Type::Date);
            Field.SetRange(Class, Field.Class::FlowFilter);
            Field.SetRange(Enabled, true);
            Field.SetFilter(ObsoleteState, '<>%1', Field.ObsoleteState::Removed);
            if Field.FindSet then
                repeat
                    SetFlowFilter(Field."No.", DataExportRecordField."Date Filter Handling", RecRef)
                until Field.Next = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetDataExportRecFieldValue(var DataExportRecordField: Record "Data Export Record Field"; FlowFilterFieldNo: Integer; RecRef: RecordRef) FieldValueText: Text
    var
        FieldRef: FieldRef;
    begin
        FieldRef := RecRef.Field(DataExportRecordField."Field No.");
        if DataExportRecordField."Field Class" = DataExportRecordField."Field Class"::FlowField then begin
            SetFlowFilterDateField(DataExportRecordField, FlowFilterFieldNo, RecRef);
            FieldRef := RecRef.Field(DataExportRecordField."Field No.");
            FieldRef.CalcField;
        end;
        FieldValueText := FormatField2String(FieldRef, DataExportRecordField);
    end;

    [Scope('OnPrem')]
    procedure SetFlowFilter(FlowFilterFieldNo: Integer; DateFilterHandling: Option; var RecRef: RecordRef)
    var
        DataExportRecField: Record "Data Export Record Field";
        FieldRef: FieldRef;
    begin
        FieldRef := RecRef.Field(FlowFilterFieldNo);
        case DateFilterHandling of
            DataExportRecField."Date Filter Handling"::" ":
                FieldRef.SetRange; // remove filter
            DataExportRecField."Date Filter Handling"::Period:
                FieldRef.SetRange(StartDate, CalcEndDate(EndDate));
            DataExportRecField."Date Filter Handling"::"End Date Only":
                FieldRef.SetRange(0D, CalcEndDate(EndDate));
            DataExportRecField."Date Filter Handling"::"Start Date Only":
                FieldRef.SetRange(0D, ClosingDate(StartDate - 1));
        end;
    end;

    [Scope('OnPrem')]
    procedure SetClientFileName(NewClientFileName: Text)
    begin
        ClientFileName := NewClientFileName;
    end;

    local procedure CalcEndDate(Date: Date): Date
    begin
        if CloseDate then
            exit(ClosingDate(Date));
        exit(Date);
    end;

    local procedure FillCharsToDelete()
    var
        i: Integer;
        S: Text;
    begin
        NewLine[1] := 13;
        NewLine[2] := 10;

        CharsToDelete := NewLine;
        CharsToDelete[3] := 34;
        CharsToDelete[4] := 39;
        for i := 128 to 255 do begin
            S[1] := i;
            if not (S in ['Ä', 'ä', 'Ö', 'ö', 'Ü', 'ü', 'ß']) then
                CharsToDelete := CharsToDelete + S;
        end;
    end;

    local procedure CloseStreams(LastStreamNo: Integer)
    var
        i: Integer;
    begin
        for i := 1 to LastStreamNo do
            StreamArr[i].Close;
    end;

    local procedure DownloadFiles(DataExportRecordDefinition: Record "Data Export Record Definition"; ServerPath: Text)
    var
        ZipFileNameOnServer: Text;
        ZipFileName: Text;
    begin
        ZipFileNameOnServer := ZipFilesOnServer(ServerPath, DataExportRecordDefinition."DTD File Name");
        ZipFileName := DataExportRecordDefinition."Data Exp. Rec. Type Code" + '.zip';
        if ClientFileName <> '' then
            FileMgt.DownloadToFile(ZipFileNameOnServer, ClientFileName)
        else
            Download(ZipFileNameOnServer, '', '', '', ZipFileName);
    end;

    local procedure ZipFilesOnServer(ServerPath: Text; DTDFileName: Text) ZipFileNameOnServer: Text
    var
        ZipFile: File;
        ZipFileOutStream: OutStream;
    begin
        ZipFileNameOnServer := FileMgt.ServerTempFileName('zip');
        ZipFile.Create(ZipFileNameOnServer);
        ZipFile.CreateOutStream(ZipFileOutStream);
        DataCompression.CreateZipArchive;
        with TempDataExportRecordSource do begin
            Reset;
            if FindSet then
                repeat
                    MoveToZipFile(ServerPath, "Export File Name");
                until Next = 0;
            DeleteAll;
        end;
        MoveToZipFile(ServerPath, IndexFileNameTxt);
        MoveToZipFile(ServerPath, LogFileNameTxt);
        MoveToZipFile(ServerPath, DTDFileName);
        DataCompression.SaveZipArchive(ZipFileOutStream);
        DataCompression.CloseZipArchive;
        ZipFile.Close;
    end;

    local procedure MoveToZipFile(ServerPath: Text; FileName: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        ServerFileInStream: InStream;
    begin
        if Exists(PathHelper.GetFullPath(ServerPath + '\' + FileName)) then begin
            FileMgt.BLOBImportFromServerFile(TempBlob, PathHelper.GetFullPath(ServerPath + '\' + FileName));
            TempBlob.CreateInStream(ServerFileInStream);
            DataCompression.AddEntry(ServerFileInStream, FileName);
            Erase(ServerPath + '\' + FileName);
        end;
    end;

    [Scope('OnPrem')]
    procedure GetMaxOptionIndex(InputString: Text): Integer
    begin
        exit(StrLen(DelChr(InputString, '=', DelChr(InputString, '=', ','))));
    end;
}

