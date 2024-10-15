table 11765 "Excel Template"
{
    Caption = 'Excel Template';
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.0';

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[80])
        {
            Caption = 'Description';
        }
        field(3; Template; BLOB)
        {
            Caption = 'Template';
        }
        field(4; Sheet; Text[250])
        {
            Caption = 'Sheet';

            trigger OnLookup()
            var
                TempExcelBuffer: Record "Excel Buffer" temporary;
                Sheet2: Text[250];
            begin
                CalcFields(Template);
                if Template.HasValue then begin
                    FileName := FileMgt.ServerTempFileName(ExtensionTxt);
                    if Exists(FileName) then
                        Erase(FileName);
                    Template.Export(FileName);
                    Sheet2 := TempExcelBuffer.SelectSheetsName(FileName);
                    if Sheet2 <> '' then
                        Sheet := Sheet2;
                    if Erase(FileName) then;
                end;
            end;
        }
        field(10; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
        FileName: Text;
        ImportQst: Label 'Do you want import Template?';
        DeleteQst: Label 'Do you want delete %1?';
        DefaultTxt: Label 'Default';
        ExtensionTxt: Label 'xlsx', Comment = 'xlsx';
        NotSupportedErr: Label 'Function not supported in the Web Client. Please use the Windows Client.';

    [Scope('OnPrem')]
    procedure ExportToServerFile(): Text[250]
    begin
        CalcFields(Template);
        TestField(Template);

        FileName := FileMgt.ServerTempFileName(ExtensionTxt);
        if Exists(FileName) then
            Erase(FileName);
        Template.Export(FileName);
        exit(FileName);
    end;

    [Scope('OnPrem')]
    procedure ShowFile(IsTemporary: Boolean)
    var
        FileName: Text;
    begin
        if not FileMgt.IsLocalFileSystemAccessible then
            Error(NotSupportedErr);

        FileName := ConstFilename;
        CalcFields(Template);
        ExportToClientFile(FileName);
        HyperLink(FileName);
        if Confirm(ImportQst, true) then
            ImportFile(FileName, IsTemporary);
        DeleteFile(FileName);
    end;

    [Scope('OnPrem')]
    procedure ExportToClientFile(var ExportToFile: Text): Boolean
    var
        FileName: Text;
    begin
        CalcFields(Template);
        if Template.HasValue then begin
            TempBlob.FromRecord(Rec, FieldNo(Template));
            if ExportToFile = '' then begin
                FileName := StrSubstNo('%1.%2', DefaultTxt, ExtensionTxt);
                ExportToFile := FileMgt.BLOBExport(TempBlob, FileName, true);
            end else
                ExportToFile := FileMgt.BLOBExport(TempBlob, ExportToFile, false);

            exit(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure ImportFile(ImportFromFile: Text; IsTemporary: Boolean): Boolean
    var
        RecordRef: RecordRef;
        FileName: Text;
    begin
        if IsTemporary then begin
            FileName := FileMgt.BLOBImport(TempBlob, ImportFromFile);
            if FileName <> '' then begin
                RecordRef.GetTable(Rec);
                TempBlob.ToRecordRef(RecordRef, FieldNo(Template));
                RecordRef.SetTable(Rec);
                exit(true);
            end;
            exit(false);
        end;

        FileName := ImportFromFile;
        if FileName = '' then
            FileName := StrSubstNo('*.%1', ExtensionTxt);
        FileName := FileMgt.BLOBImportWithFileType(TempBlob, FileName);
        if FileName = '' then
            exit(false);

        RecordRef.GetTable(Rec);
        TempBlob.ToRecordRef(RecordRef, FieldNo(Template));
        RecordRef.SetTable(Rec);
        if Modify(true) then;
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure RemoveTemplate(Prompt: Boolean) DeleteOK: Boolean
    var
        DeleteYesNo: Boolean;
    begin
        DeleteOK := false;
        DeleteYesNo := true;
        if Prompt then
            if not Confirm(
                 DeleteQst, false, FieldCaption(Template))
            then
                DeleteYesNo := false;

        if DeleteYesNo then begin
            Clear(Template);
            Clear(Sheet);
            if Modify(true) then;
            DeleteOK := true;
        end;
    end;

    [Scope('OnPrem')]
    procedure DeleteFile(FileName: Text): Boolean
    var
        i: Integer;
    begin
        if FileName = '' then
            exit(false);

        if not FileMgt.ClientFileExists(FileName) then
            exit(true);

        repeat
            Sleep(100);
            i := i + 1;
        until FileMgt.DeleteClientFile(FileName) or (i = 25);
        exit(not FileMgt.ClientFileExists(FileName));
    end;

    [Scope('OnPrem')]
    procedure ConstFilename() FileName: Text
    begin
        FileName := FileMgt.ClientTempFileName(ExtensionTxt);
    end;
}

