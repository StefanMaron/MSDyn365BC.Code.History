table 26573 "Format Version"
{
    Caption = 'Format Version';
    LookupPageID = "Format Versions";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; "KND Code"; Code[10])
        {
            Caption = 'KND Code';

            trigger OnValidate()
            begin
                CheckLinkedReports;
            end;
        }
        field(3; "Report Description"; Text[250])
        {
            Caption = 'Report Description';
        }
        field(4; "Part No."; Code[10])
        {
            Caption = 'Part No.';
        }
        field(5; "Version No."; Code[10])
        {
            Caption = 'Version No.';
        }
        field(6; "Report Type"; Option)
        {
            Caption = 'Report Type';
            OptionCaption = ' ,Tax,Accounting';
            OptionMembers = " ",Tax,Accounting;

            trigger OnValidate()
            begin
                CheckLinkedReports;
            end;
        }
        field(8; "Usage Starting Date"; Date)
        {
            Caption = 'Usage Starting Date';
        }
        field(9; "Usage First Reporting Period"; Text[30])
        {
            Caption = 'Usage First Reporting Period';
        }
        field(10; "Usage Ending Date"; Date)
        {
            Caption = 'Usage Ending Date';
        }
        field(11; "Register No."; Code[20])
        {
            Caption = 'Register No.';
        }
        field(15; "Excel File Name"; Text[250])
        {
            Caption = 'Excel File Name';

            trigger OnValidate()
            begin
                CheckLinkedReports;
            end;
        }
        field(16; "Report Template"; BLOB)
        {
            Caption = 'Report Template';
        }
        field(17; "XML Schema File Name"; Text[250])
        {
            Caption = 'XML Schema File Name';

            trigger OnValidate()
            begin
                CheckLinkedReports;
            end;
        }
        field(18; "XML Schema"; BLOB)
        {
            Caption = 'XML Schema';
        }
        field(19; "Form Order No. & Appr. Date"; Text[250])
        {
            Caption = 'Form Order No. and Appr. Date';

            trigger OnValidate()
            begin
                CheckLinkedReports;
            end;
        }
        field(20; "Format Order No. & Appr. Date"; Text[250])
        {
            Caption = 'Format Order No. and Appr. Date';

            trigger OnValidate()
            begin
                CheckLinkedReports;
            end;
        }
        field(21; Comment; Text[250])
        {
            Caption = 'Comment';
        }
        field(22; "XML File Name Element Name"; Text[100])
        {
            Caption = 'XML File Name Element Name';

            trigger OnValidate()
            begin
                CheckLinkedReports;
            end;
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

    trigger OnDelete()
    begin
        if HasLinkedReports then
            Error(Text004, GetRecDescription);
    end;

    trigger OnInsert()
    begin
        StatutoryReportSetup.Get;
        if StatutoryReportSetup."Dflt. XML File Name Elem. Name" <> '' then
            "XML File Name Element Name" := StatutoryReportSetup."Dflt. XML File Name Elem. Name";
    end;

    var
        StatutoryReport: Record "Statutory Report";
        Text003: Label 'You cannot modify %1 because there are linked reports.';
        Text004: Label 'You cannot delete %1 because there are linked reports.';
        StatutoryReportSetup: Record "Statutory Report Setup";
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
        ExcelMngt: Codeunit "Excel Management";

    [Scope('OnPrem')]
    procedure ImportExcelTemplate(FileName: Text[250])
    var
        RecordRef: RecordRef;
    begin
        CheckLinkedReports;

        Clear(TempBlob);
        if FileName = '' then
            FileName := FileMgt.BLOBImport(TempBlob, '*.xls')
        else
            ExcelMngt.BLOBImportSilent(TempBlob, FileName);

        if FileName <> '' then begin
            "Excel File Name" := ParseFileName(FileName);
            RecordRef.GetTable(Rec);
            TempBlob.ToRecordRef(RecordRef, FieldNo("Report Template"));
            RecordRef.SetTable(Rec);
        end;
    end;

    [Scope('OnPrem')]
    procedure ImportXMLSchema(FileName: Text[250])
    var
        RecordRef: RecordRef;
    begin
        CheckLinkedReports;

        Clear(TempBlob);
        if FileName = '' then
            FileName := FileMgt.BLOBImport(TempBlob, '*.xsd')
        else
            ExcelMngt.BLOBImportSilent(TempBlob, FileName);

        if FileName <> '' then begin
            "XML Schema File Name" := ParseFileName(FileName);
            RecordRef.GetTable(Rec);
            TempBlob.ToRecordRef(RecordRef, FieldNo("XML Schema"));
            RecordRef.SetTable(Rec);
        end;
    end;

    [Scope('OnPrem')]
    procedure ExportExcelTemplate(FileName: Text[250])
    begin
        CalcFields("Report Template");
        if "Report Template".HasValue then begin
            TempBlob.FromRecord(Rec, FieldNo("Report Template"));
            FileMgt.BLOBExport(TempBlob, FileName, true);
        end;
    end;

    [Scope('OnPrem')]
    procedure ExportXMLSchema(FileName: Text[250])
    begin
        CalcFields("XML Schema");
        if "XML Schema".HasValue then begin
            TempBlob.FromRecord(Rec, FieldNo("XML Schema"));
            FileMgt.BLOBExport(TempBlob, FileName, true);
        end;
    end;

    [Scope('OnPrem')]
    procedure GetRecDescription(): Text[250]
    begin
        exit(StrSubstNo('%1 %2=''%3''', TableCaption,
            FieldCaption(Code), Code));
    end;

    [Scope('OnPrem')]
    procedure HasLinkedReports(): Boolean
    begin
        StatutoryReport.SetRange("Format Version Code", Code);
        exit(not StatutoryReport.IsEmpty);
    end;

    [Scope('OnPrem')]
    procedure ParseFileName(FileName: Text[250]): Text[250]
    begin
        while StrPos(FileName, '\') <> 0 do
            FileName := CopyStr(FileName, StrPos(FileName, '\') + 1);
        exit(FileName);
    end;

    [Scope('OnPrem')]
    procedure CheckLinkedReports()
    begin
        if HasLinkedReports then
            Error(Text003, GetRecDescription);
    end;
}

