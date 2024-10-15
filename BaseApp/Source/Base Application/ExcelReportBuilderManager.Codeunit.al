codeunit 14930 "Excel Report Builder Manager"
{

    trigger OnRun()
    begin
    end;

    var
        TempExcelTemplateSheetBuffer: Record "Excel Template Sheet Buffer" temporary;
        FileMgt: Codeunit "File Management";
        ReportBuilder: DotNet ReportBuilder;
        TemplateCode: Code[10];
        SheetNameExceedsMaxLengthErr: Label 'Sheet Name exceeds max length = %1.';
        SaveFileTitleMsg: Label 'Save excel report';

    [Scope('OnPrem')]
    procedure SetSheet(SheetName: Text)
    var
        ExcelTemplateSheet: Record "Excel Template Sheet";
    begin
        if StrLen(SheetName) > MaxStrLen(TempExcelTemplateSheetBuffer."Sheet Name") then
            Error(SheetNameExceedsMaxLengthErr, Format(MaxStrLen(TempExcelTemplateSheetBuffer."Sheet Name")));

        ReportBuilder.SetSheet(SheetName);

        // Buffer that store sheet size info
        with TempExcelTemplateSheetBuffer do begin
            // Save current values
            if "Sheet Name" <> '' then
                Modify;

            if not Get(SheetName) then begin
                ExcelTemplateSheet.Get(TemplateCode, SheetName);

                Init;
                "Sheet Name" := CopyStr(SheetName, 1, MaxStrLen("Sheet Name"));
                "Paper Height" := ExcelTemplateSheet."Paper Height";
                "Current Paper Height" := ExcelTemplateSheet."Paper Height";
                "Last Page No." := 1;
                Insert;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure InitTemplate(InitTemplateCode: Code[10])
    begin
        TemplateCode := InitTemplateCode;
        ReportBuilder := ReportBuilder.ReportBuilder();
    end;

    [Scope('OnPrem')]
    procedure AddSection(NewSectionName: Text)
    var
        ExcelTemplateSection: Record "Excel Template Section";
        SectionHeight: Decimal;
    begin
        ExcelTemplateSection.Get(
          TemplateCode, TempExcelTemplateSheetBuffer."Sheet Name", NewSectionName);
        SectionHeight := ExcelTemplateSection.Height;

        if ExcelTemplateSection.Height > TempExcelTemplateSheetBuffer."Current Paper Height" then
            AddPagebreak;

        TempExcelTemplateSheetBuffer."Current Paper Height" -= SectionHeight;

        ReportBuilder.AddSection(NewSectionName);
    end;

    [Scope('OnPrem')]
    procedure TryAddSection(NewSectionName: Text): Boolean
    var
        ExcelTemplateSection: Record "Excel Template Section";
        SectionHeight: Decimal;
    begin
        ExcelTemplateSection.Get(
          TemplateCode, TempExcelTemplateSheetBuffer."Sheet Name", NewSectionName);
        SectionHeight := ExcelTemplateSection.Height;

        if ExcelTemplateSection.Height > TempExcelTemplateSheetBuffer."Current Paper Height" then
            exit(false);

        TempExcelTemplateSheetBuffer."Current Paper Height" -= SectionHeight;
        ReportBuilder.AddSection(NewSectionName);
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure TryAddSectionWithPlaceForFooter(NewSectionName: Text; FooterSectionNames: Text): Boolean
    var
        ExcelTemplateSection: Record "Excel Template Section";
        SectionHeight: Decimal;
    begin
        if FooterSectionNames = '' then begin
            AddSection(NewSectionName);
            exit(true);
        end;

        if IsPageBreakRequired(NewSectionName, FooterSectionNames) then
            exit(false);

        ExcelTemplateSection.Get(
          TemplateCode, TempExcelTemplateSheetBuffer."Sheet Name", NewSectionName);
        SectionHeight := ExcelTemplateSection.Height;

        TempExcelTemplateSheetBuffer."Current Paper Height" -= SectionHeight;
        ReportBuilder.AddSection(NewSectionName);

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure IsPageBreakRequired(NewSectionName: Text; FooterSectionNames: Text): Boolean
    var
        ExcelTemplateSection: Record "Excel Template Section";
        SectionHeight: Decimal;
        FooterHeight: Decimal;
    begin
        FooterHeight := GetFooterTotalHeight(FooterSectionNames);
        ExcelTemplateSection.Get(
          TemplateCode, TempExcelTemplateSheetBuffer."Sheet Name", NewSectionName);
        SectionHeight := ExcelTemplateSection.Height;

        exit(SectionHeight + FooterHeight > TempExcelTemplateSheetBuffer."Current Paper Height");
    end;

    [Scope('OnPrem')]
    procedure GetFooterTotalHeight(FooterSectionNames: Text) TotalSectionHeight: Decimal
    var
        ExcelTemplateSection: Record "Excel Template Section";
    begin
        if FooterSectionNames = '' then
            exit(0);

        TotalSectionHeight := 0;

        while StrPos(FooterSectionNames, ',') <> 0 do begin
            ExcelTemplateSection.Get(
              TemplateCode, TempExcelTemplateSheetBuffer."Sheet Name",
              CopyStr(FooterSectionNames, 1, StrPos(FooterSectionNames, ',') - 1));
            TotalSectionHeight += ExcelTemplateSection.Height;
            FooterSectionNames := DelStr(FooterSectionNames, 1, StrPos(FooterSectionNames, ','))
        end;

        ExcelTemplateSection.Get(
          TemplateCode, TempExcelTemplateSheetBuffer."Sheet Name", FooterSectionNames);
        TotalSectionHeight += ExcelTemplateSection.Height;
    end;

    [Scope('OnPrem')]
    procedure AddDataToSection(CellName: Text; Value: Text)
    begin
        ReportBuilder.AddData(CellName, Value);
    end;

    [Scope('OnPrem')]
    procedure AddDataToPreviousSection(SectionId: Integer; CellName: Text; Value: Text)
    begin
        ReportBuilder.AddDataToPreviousSection(SectionId, CellName, Value);
    end;

    [Scope('OnPrem')]
    procedure AddPagebreak()
    begin
        ReportBuilder.AddPageBreak;

        TempExcelTemplateSheetBuffer."Current Paper Height" := TempExcelTemplateSheetBuffer."Paper Height";
        TempExcelTemplateSheetBuffer."Last Page No." += 1;
    end;

    local procedure ExportDataToServerFile() ServerFileName: Text
    var
        ExcelTemplate: Record "Excel Template";
        TempBlob: Codeunit "Temp Blob";
    begin
        ExcelTemplate.Get(TemplateCode);
        ExcelTemplate.CalcFields(BLOB);
        TempBlob.FromRecord(ExcelTemplate, ExcelTemplate.FieldNo(BLOB));

        ServerFileName := FileMgt.ServerTempFileName('');
        FileMgt.BLOBExportToServerFile(TempBlob, ServerFileName);
        ReportBuilder.BuildReport(ServerFileName);
    end;

    [Scope('OnPrem')]
    procedure ExportData()
    var
        ServerFileName: Text;
        ExportToFile: Text;
    begin
        ServerFileName := ExportDataToServerFile;

        ExportToFile := TemplateCode + '.xlsx';
        Download(ServerFileName, SaveFileTitleMsg, '', '(*.xlsx)|*.xlsx', ExportToFile);
    end;

    [Scope('OnPrem')]
    procedure ExportDataToClientFile(ClientFileName: Text)
    begin
        FileMgt.DownloadToFile(ExportDataToServerFile, ClientFileName);
    end;

    [Scope('OnPrem')]
    procedure GetLastPageNo(): Integer
    begin
        exit(TempExcelTemplateSheetBuffer."Last Page No.");
    end;

    [Scope('OnPrem')]
    procedure GetCurrentSectionId(): Integer
    begin
        exit(ReportBuilder.GetCurrentSectionId)
    end;
}

