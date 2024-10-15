// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AuditFileExport;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Period;
using System.IO;
using System.Reflection;
using System.Telemetry;
using System.Text;
using System.Utilities;

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
            DataItemTableView = sorting("Data Export Code", "Data Exp. Rec. Type Code");
            RequestFilterFields = "Data Export Code", "Data Exp. Rec. Type Code";

            trigger OnAfterGetRecord()
            var
                StartDateTime: DateTime;
                LastStreamNo: Integer;
            begin
                TestField(Description);
                if "DTD File Name" = '' then
                    Error(DTDFileNotExistsErr);

                CheckRecordDefinition("Data Export Code", "Data Exp. Rec. Type Code");
                StartDateTime := CurrentDateTime;
                LastStreamNo := OpenStreams("Data Export Record Definition");

                if GuiAllowed then
                    Window.Update(1, CreatingXMLFileMsg);
                DataCompression.CreateZipArchive();
                CreateIndexFile("Data Export Record Definition");

                ExportDTDFile("Data Export Record Definition");

                WriteData("Data Export Record Definition");
                CloseStreams(LastStreamNo);

                if GuiAllowed then
                    Window.Update(1, CreatingLogFileMsg);
                CreateLogFile(CurrentDateTime - StartDateTime);

                DownloadFiles("Data Export Record Definition");
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
        FillCharsToDelete();

        StartDate := AccPeriod.GetFiscalYearStartDate(WorkDate());
        EndDate := AccPeriod.GetFiscalYearEndDate(WorkDate());
    end;

    trigger OnPreReport()
    begin
        GLSetup.Get();
    end;

    trigger OnPostReport()
    begin
        FeatureTelemetry.LogUptake('0001Q0O', DataTok, Enum::"Feature Uptake Status"::"Used");
        FeatureTelemetry.LogUsage('0001Q0P', DataTok, 'DACH data export');
    end;

    var
        GLSetup: Record "General Ledger Setup";
        TempDataExportRecordSource: Record "Data Export Record Source" temporary;
        TempBlobArray: array[100] of Codeunit "Temp Blob";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        DataCompression: Codeunit "Data Compression";
        DotNet_StreamWriterArr: array[100] of Codeunit DotNet_StreamWriter;
        StartDate: Date;
        EndDate: Date;
        Window: Dialog;
        TotalNoOfRecords: Integer;
        NoOfRecords: Integer;
        NoOfRecordsArr: array[100] of Integer;
        StepValue: Integer;
        NextStep: Integer;
        CloseDate: Boolean;
        DataTok: Label 'DACH Data Export', Locked = true;
        ValueWithQuotesTxt: Label '"%1"', Locked = true;
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

    local procedure OpenStreams(DataExportRecordDefinition: Record "Data Export Record Definition") LastStreamNo: Integer
    var
        DataExportRecordSource: Record "Data Export Record Source";
        DotNet_Encoding: Codeunit DotNet_Encoding;
        DotNet_StreamWriter: Codeunit DotNet_StreamWriter;
        FileWriteStream: OutStream;
        MaxNumOfStreams: Integer;
    begin
        Clear(NoOfRecordsArr);
        Clear(DotNet_StreamWriterArr);
        DotNet_Encoding.Encoding(GetCodePageByEncodingName(Format(DataExportRecordDefinition."File Encoding")));

        with DataExportRecordSource do begin
            Reset();
            SetCurrentKey("Data Export Code", "Data Exp. Rec. Type Code", "Line No.");
            SetRange("Data Export Code", DataExportRecordDefinition."Data Export Code");
            SetRange("Data Exp. Rec. Type Code", DataExportRecordDefinition."Data Exp. Rec. Type Code");
            MaxNumOfStreams := ArrayLen(DotNet_StreamWriterArr);
            if Count > MaxNumOfStreams then
                Error(ExceedNoOfStreamsErr, MaxNumOfStreams, PRODUCTNAME.Full());
            LastStreamNo := 0;
            if FindSet() then
                repeat
                    TestField("Export File Name");
                    Validate("Table Filter");

                    CalcFields("Table Name");
                    if GuiAllowed then
                        Window.Update(1, "Table Name");

                    LastStreamNo += 1;

                    Clear(FileWriteStream);
                    Clear(DotNet_StreamWriter);

                    TempBlobArray[LastStreamNo].CreateOutStream(FileWriteStream);
                    FileWriteStream.Write("Export File Name");
                    DotNet_StreamWriter.StreamWriter(FileWriteStream, DotNet_Encoding);

                    DotNet_StreamWriterArr[LastStreamNo] := DotNet_StreamWriter;

                    InsertFilesExportBuffer(DataExportRecordSource, LastStreamNo);

                    TotalNoOfRecords += CountRecords(TempDataExportRecordSource);
                until Next() = 0;
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
            TotalRecords := RecordRef.Count();
            RecordRef.Close();
        end;
    end;

    local procedure InsertFilesExportBuffer(DataExportRecordSource: Record "Data Export Record Source"; StreamNo: Integer)
    begin
        with TempDataExportRecordSource do begin
            TempDataExportRecordSource := DataExportRecordSource;
            Indentation := StreamNo;
            if "Key No." = 0 then
                "Key No." := 1;
            Insert();
        end;
    end;

    local procedure CreateIndexFile(DataExportRecordDefinition: Record "Data Export Record Definition")
    var
        TempBlob: Codeunit "Temp Blob";
        DataExportManagement: Codeunit "Data Export Management";
        FileReadStream: InStream;
        FileWriteStream: OutStream;
    begin
        TempBlob.CreateOutStream(FileWriteStream);
        with DataExportRecordDefinition do
            DataExportManagement.CreateIndexXmlStream(
              TempDataExportRecordSource, FileWriteStream, Description, StartDate, EndDate, "DTD File Name", Format("File Encoding"));
        TempBlob.CreateInStream(FileReadStream);
        DataCompression.AddEntry(FileReadStream, IndexFileNameTxt);
    end;

    local procedure ExportDTDFile(DataExportRecordDefinition: Record "Data Export Record Definition")
    var
        InStr: InStream;
    begin
        with DataExportRecordDefinition do begin
            CalcFields("DTD File");
            "DTD File".CreateInStream(InStr);
            DataCompression.AddEntry(InStr, "DTD File Name");
        end;
    end;

    local procedure CreateLogFile(Duration: Duration)
    var
        TempBlob: Codeunit "Temp Blob";
        FileReadStream: InStream;
        FileWriteStream: OutStream;
        NoOfDefinedTables: Integer;
        NoOfEmptyTables: Integer;
    begin
        TempBlob.CreateOutStream(FileWriteStream);
        WriteLineToOutStream(FileWriteStream, StrSubstNo(DateFilterMsg, Format(StartDate), Format(CalcEndDate(EndDate))));
        WriteLineToOutStream(FileWriteStream, Format(Today));
        with TempDataExportRecordSource do begin
            Reset();
            if FindSet() then begin
                NoOfDefinedTables := 0;
                NoOfEmptyTables := 0;
                WriteLineToOutStream(FileWriteStream, "Data Export Code" + ';' + "Data Exp. Rec. Type Code");
                repeat
                    if NoOfRecordsArr[Indentation] = 0 then
                        NoOfEmptyTables += 1
                    else
                        NoOfDefinedTables += 1;
                    CalcFields("Table Name");
                    WriteLineToOutStream(FileWriteStream, StrSubstNo(LogEntryMsg, "Table Name", NoOfRecordsArr[Indentation], "Export File Name"));
                until Next() = 0;
            end;
        end;
        WriteLineToOutStream(FileWriteStream, StrSubstNo(NoOfDefinedTablesMsg, NoOfDefinedTables));
        WriteLineToOutStream(FileWriteStream, StrSubstNo(NoOfEmptyTablesMsg, NoOfEmptyTables));
        WriteLineToOutStream(FileWriteStream, StrSubstNo(DurationMsg, Duration));
        TempBlob.CreateInStream(FileReadStream);
        DataCompression.AddEntry(FileReadStream, LogFileNameTxt);
    end;

    local procedure WriteData(DataExportRecordDefinition: Record "Data Export Record Definition")
    var
        CurrTempDataExportRecordSource: Record "Data Export Record Source";
        RecRef: RecordRef;
    begin
        with TempDataExportRecordSource do begin
            Reset();
            SetRange("Data Export Code", DataExportRecordDefinition."Data Export Code");
            SetRange("Data Exp. Rec. Type Code", DataExportRecordDefinition."Data Exp. Rec. Type Code");
            SetRange("Relation To Line No.", 0);
            if FindSet() then
                repeat
                    CurrTempDataExportRecordSource.Copy(TempDataExportRecordSource);
                    RecRef.Open("Table No.");
                    ApplyTableFilter(TempDataExportRecordSource, RecRef);
                    WriteTable(TempDataExportRecordSource, RecRef);
                    RecRef.Close();
                    Copy(CurrTempDataExportRecordSource);
                until Next() = 0;
        end;
    end;

    local procedure WriteTable(DataExportRecordSource: Record "Data Export Record Source"; var RecRef: RecordRef)
    var
        RecRefToExport: RecordRef;
    begin
        with DataExportRecordSource do
            if RecRef.FindSet() then begin
                NoOfRecordsArr[Indentation] += RecRef.Count();
                if GuiAllowed then
                    Window.Update(1, RecRef.Caption);
                repeat
                    RecRefToExport := RecRef.Duplicate();
                    WriteRecord(DataExportRecordSource, RecRefToExport);
                    UpdateProgressBar();
                    WriteRelatedRecords(DataExportRecordSource, RecRefToExport);
                until RecRef.Next() = 0;
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
                RecRef.SetView(TableFilterPage.GetViewFilter());
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
            Reset();
            SetRange("Data Export Code", ParentDataExportRecordSource."Data Export Code");
            SetRange("Data Exp. Rec. Type Code", ParentDataExportRecordSource."Data Exp. Rec. Type Code");
            SetRange("Relation To Line No.", ParentDataExportRecordSource."Line No.");
            if FindSet() then begin
                DataExportTableRelation.Reset();
                DataExportTableRelation.SetRange("Data Export Code", "Data Export Code");
                DataExportTableRelation.SetRange("Data Exp. Rec. Type Code", "Data Exp. Rec. Type Code");
                DataExportTableRelation.SetRange("From Table No.", ParentDataExportRecordSource."Table No.");
                repeat
                    DataExportTableRelation.SetRange("To Table No.", "Table No.");
                    if DataExportTableRelation.FindSet() then begin
                        RelatedRecRef.Open("Table No.");
                        ApplyTableFilter(TempDataExportRecordSource, RelatedRecRef);
                        repeat
                            ParentFieldRef := ParentRecRef.Field(DataExportTableRelation."From Field No.");
                            RelatedFieldRef := RelatedRecRef.Field(DataExportTableRelation."To Field No.");
                            RelatedFieldRef.SetRange(ParentFieldRef.Value);
                        until DataExportTableRelation.Next() = 0;

                        WriteTable(TempDataExportRecordSource, RelatedRecRef);

                        SetRange("Relation To Line No.", ParentDataExportRecordSource."Line No.");

                        RelatedRecRef.Close();
                    end else begin
                        CalcFields("Table Name");
                        Error(DefineTableRelationErr, DataExportTableRelation.TableCaption(), "Table Name");
                    end;
                until Next() = 0;
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
            until DataExportRecordField.Next() = 0;
            RecordText := CopyStr(RecordText, 1, StrLen(RecordText) - 1);
            DotNet_StreamWriterArr[DataExportRecordSource.Indentation].WriteLine(RecordText);
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
                FieldValueText := StrSubstNo(ValueWithQuotesTxt, ConvertString(FieldValueText));
        end;
    end;

    local procedure ConvertString(String: Text) NewString: Text
    begin
        NewString := DelChr(String, '=', CharsToDelete);
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
        DataExportRecordSource.Reset();
        DataExportRecordSource.SetRange("Data Export Code", ExportCode);
        DataExportRecordSource.SetRange("Data Exp. Rec. Type Code", RecordCode);
        if DataExportRecordSource.FindSet() then
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
                                         DataExportRecordField.TableCaption(),
                                         DataExportRecordField."Table Name")
                                    then
                                        Error('');
                            end;
                        until FieldMismatch or (DataExportRecordField.Next() = 0);
                RecRef.Close();
            until FieldMismatch or (DataExportRecordSource.Next() = 0);
    end;

    [Scope('OnPrem')]
    procedure FindFields(var DataExportRecordField: Record "Data Export Record Field"; var DataExportRecordSource: Record "Data Export Record Source"): Boolean
    begin
        with DataExportRecordField do begin
            SetRange("Data Export Code", DataExportRecordSource."Data Export Code");
            SetRange("Data Exp. Rec. Type Code", DataExportRecordSource."Data Exp. Rec. Type Code");
            SetRange("Source Line No.", DataExportRecordSource."Line No.");
            exit(FindSet());
        end;
    end;

    local procedure SetFlowFilterDateFields(DataExportRecordSource: Record "Data Export Record Source"; var RecRef: RecordRef)
    var
        DataExportRecordField: Record "Data Export Record Field";
    begin
        if DataExportRecordSource."Date Filter Handling" <> DataExportRecordSource."Date Filter Handling"::" " then begin
            DataExportRecordField.Init();
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
            Field.Reset();
            Field.SetRange(TableNo, DataExportRecordField."Table No.");
            Field.SetRange(Type, Field.Type::Date);
            Field.SetRange(Class, Field.Class::FlowFilter);
            Field.SetRange(Enabled, true);
            Field.SetFilter(ObsoleteState, '<>%1', Field.ObsoleteState::Removed);
            if Field.FindSet() then
                repeat
                    SetFlowFilter(Field."No.", DataExportRecordField."Date Filter Handling", RecRef)
                until Field.Next() = 0;
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
            FieldRef.CalcField();
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
                FieldRef.SetRange(); // remove filter
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
        FileReadStream: InStream;
        FileName: Text;
        i: Integer;
    begin
        for i := 1 to LastStreamNo do begin
            DotNet_StreamWriterArr[i].Dispose();
            TempBlobArray[i].CreateInStream(FileReadStream);
            FileReadStream.ReadText(FileName);
            DataCompression.AddEntry(FileReadStream, FileName);
        end;
    end;

    local procedure DownloadFiles(DataExportRecordDefinition: Record "Data Export Record Definition")
    var
        FileMgt: Codeunit "File Management";
        TempBlob: Codeunit "Temp Blob";
        ZipReadStream: InStream;
        ZipFileNameOnServer: Text;
        ZipFileName: Text;
    begin
        DataCompression.SaveZipArchive(TempBlob);
        DataCompression.CloseZipArchive();
        TempBlob.CreateInStream(ZipReadStream);
        ZipFileName := DataExportRecordDefinition."Data Exp. Rec. Type Code" + '.zip';
        if ClientFileName <> '' then begin
            ZipFileNameOnServer := FileMgt.InstreamExportToServerFile(ZipReadStream, '.zip');
            FileMgt.DownloadHandler(ZipFileNameOnServer, '', '', '', ClientFileName);
        end else
            FileMgt.DownloadFromStreamHandler(ZipReadStream, '', '', '', ZipFileName);
    end;

    [Scope('OnPrem')]
    procedure GetMaxOptionIndex(InputString: Text): Integer
    begin
        exit(StrLen(DelChr(InputString, '=', DelChr(InputString, '=', ','))));
    end;


    local procedure GetCodePageByEncodingName(EncodingName: Text): Integer
    begin
        case EncodingName of
            'UTF8':
                exit(65001);
            'UTF7':
                exit(65000);
            'UTF16':
                exit(1200);
            'ANSI':
                exit(1252); // Western European (Windows)
            'Macintosh':
                exit(10000);
            'OEM':
                exit(437); // OEM United States
        end;
    end;

    local procedure WriteLineToOutStream(OutStr: OutStream; TextLine: Text)
    begin
        OutStr.WriteText(TextLine);
        OutStr.WriteText();
    end;
}

