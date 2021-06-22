codeunit 9652 "Edit RDLC Report Layout"
{
    TableNo = "Custom Report Layout";

    trigger OnRun()
    begin
        EditReportLayout(Rec);
    end;

    var
        LoadDocQst: Label 'The report layout has been opened in SQL Report Builder.\\Edit the report layout in SQL Report Builder and save the changes. Then return to this message and choose Yes to import the changes or No to cancel the changes.\Do you want to import the changes?';
        NoReportBuilderPresentErr: Label 'Microsoft Report Builder is not installed on this computer.';

    local procedure EditReportLayout(var CustomReportLayout: Record "Custom Report Layout")
    var
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
        [RunOnClient]
        Process: DotNet Process;
        FileName: Text;
        RBFileName: Text;
        LoadModifiedDoc: Boolean;
    begin
        CustomReportLayout.TestLayout;

        RBFileName := GetReportBuilderExe;
        if RBFileName = '' then
            Error(NoReportBuilderPresentErr);

        CustomReportLayout.GetLayoutBlob(TempBlob);
        FileName := FileMgt.BLOBExport(TempBlob, 'report.rdl', false);

        Process := Process.Start(RBFileName, '"' + FileName + '"');

        LoadModifiedDoc := Confirm(LoadDocQst);

        if LoadModifiedDoc then begin
            FileMgt.BLOBImport(TempBlob, FileName);
            CustomReportLayout.ImportLayoutBlob(TempBlob, '');
        end;

        if not Process.HasExited then
            Process.CloseMainWindow;

        FileMgt.DeleteClientFile(FileName);
    end;

    local procedure GetReportBuilderExe(): Text
    var
        [RunOnClient]
        Registry: DotNet Registry;
        [RunOnClient]
        FileVersion: DotNet FileVersionInfo;
        FileName: Text;
        length: Integer;
        offset: Integer;
        FileVersionMajor: Integer;
    begin
        FileName := Registry.GetValue('HKEY_CLASSES_ROOT\MSReportBuilder_ReportFile_32\shell\Open\command', '', '');
        if (FileName = '') or (FileName = 'null') then
            Error(NoReportBuilderPresentErr);
        length := StrPos(UpperCase(FileName), '.EXE');
        // Strip leading quotes if any

        if length > 0 then begin
            length += 3;
            if FileName[1] = '"' then begin
                offset := 1;
                length -= 1;
            end;
            FileName := CopyStr(FileName, offset + 1, length);
        end else
            FileName := '';

        if FileName <> '' then begin
            FileVersion := FileVersion.GetVersionInfo(FileName);
            FileVersionMajor := FileVersion.ProductMajorPart;
        end else
            FileVersionMajor := 0;

        // Report Builder 2016 (File version 14.*)
        if FileVersionMajor <> 14 then begin
            FileName :=
              Registry.GetValue('HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Microsoft SQL Server\Report Builder', 'location', '');
            if (FileName <> '') or (FileName <> 'null') then begin
                FileName := FileName + '\MSReportBuilder.exe';
                FileVersion := FileVersion.GetVersionInfo(FileName);
                if FileVersion.ProductMajorPart < 14 then
                    FileName := '';
            end else
                FileName := '';
        end;
        exit(FileName);
    end;
}

