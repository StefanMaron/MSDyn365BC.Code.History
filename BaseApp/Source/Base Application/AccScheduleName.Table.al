table 84 "Acc. Schedule Name"
{
    Caption = 'Acc. Schedule Name';
    DataCaptionFields = Name, Description;
    LookupPageID = "Account Schedule Names";

    fields
    {
        field(1; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(2; Description; Text[80])
        {
            Caption = 'Description';
        }
        field(3; "Default Column Layout"; Code[10])
        {
            Caption = 'Default Column Layout';
            TableRelation = "Column Layout Name";
        }
        field(4; "Analysis View Name"; Code[10])
        {
            Caption = 'Analysis View Name';
            TableRelation = "Analysis View";
        }
        field(12400; "Used in Statutory Report"; Boolean)
        {
            CalcFormula = Exist ("Stat. Report Table Mapping" WHERE("Int. Source Type" = CONST("Acc. Schedule"),
                                                                    "Int. Source No." = FIELD(Name)));
            Caption = 'Used in Statutory Report';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        AccSchedLine.SetRange("Schedule Name", Name);
        AccSchedLine.DeleteAll;
    end;

    var
        AccSchedLine: Record "Acc. Schedule Line";
        Text26550: Label 'Select a filename to import File Settings.';
        Text26551: Label 'Select a filename to export File Settings to.';
        FileMgt: Codeunit "File Management";
        Text12400: Label 'File Name';

    [Scope('OnPrem')]
    procedure ExportSettings(var AccScheduleName: Record "Acc. Schedule Name")
    var
        StatutoryReport: Record "Statutory Report";
        AccountSchedules: XMLport "Account Schedules";
        OutputFile: File;
        OutStr: OutStream;
        ClientFileName: Text;
        ServerFileName: Text;
    begin
        ClientFileName := 'AccSchedule.xml';
        ServerFileName := FileMgt.ServerTempFileName('.xml');

        OutputFile.Create(ServerFileName);
        OutputFile.CreateOutStream(OutStr);

        AccountSchedules.SetDestination(OutStr);
        AccountSchedules.SetData(AccScheduleName);
        AccountSchedules.Export;
        OutputFile.Close;
        Clear(OutStr);

        if not FileMgt.IsLocalFileSystemAccessible then
            Download(ServerFileName, '', '', '', ClientFileName)
        else begin
            ClientFileName := FileMgt.SaveFileDialog(Text26551, ClientFileName, FileMgt.GetToFilterText('', '.xml'));
            FileMgt.DownloadToFile(ServerFileName, ClientFileName);
        end;
    end;

    [Scope('OnPrem')]
    procedure ImportSettings(ServerFileName: Text)
    var
        AccountSchedules: XMLport "Account Schedules";
        InputFile: File;
        InStr: InStream;
    begin
        if ServerFileName = '' then
            ServerFileName := FileMgt.UploadFile('', '.xml');

        InputFile.Open(ServerFileName);
        InputFile.CreateInStream(InStr);

        AccountSchedules.SetSource(InStr);
        AccountSchedules.Import;
        AccountSchedules.ImportData;

        Clear(InStr);
        InputFile.Close;
    end;

    procedure Print()
    var
        AccountSchedule: Report "Account Schedule";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrint(Rec, IsHandled);
        if IsHandled then
            exit;

        AccountSchedule.SetAccSchedName(Name);
        AccountSchedule.SetColumnLayoutName("Default Column Layout");
        AccountSchedule.Run;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrint(var AccScheduleName: Record "Acc. Schedule Name"; var IsHandled: Boolean)
    begin
    end;
}

