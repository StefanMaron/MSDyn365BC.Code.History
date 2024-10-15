report 17441 "Timesheet T-13"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Timesheet T-13';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(OrgUnitSheets; "Organizational Unit")
        {
            DataItemTableView = SORTING(Code) WHERE(Type = CONST(Unit));
            RequestFilterFields = "Code";

            trigger OnAfterGetRecord()
            begin
                ExcelMgt.CopySheet('1', '1', Code + ' ' + Name);
                OrgUnitName := Code + ' ' + Name;
            end;

            trigger OnPreDataItem()
            begin
                ExcelMgt.OpenBookForUpdate(FileName);
            end;
        }
        dataitem("Organizational Unit"; "Organizational Unit")
        {
            DataItemTableView = SORTING(Code) WHERE(Type = CONST(Unit));
            PrintOnlyIfDetail = true;
            dataitem("Employee Job Entry"; "Employee Job Entry")
            {
                DataItemLink = "Org. Unit Code" = FIELD(Code);
                DataItemTableView = SORTING("Org. Unit Code", "Job Title Code", "Starting Date");
                dataitem("Timesheet Detail"; "Timesheet Detail")
                {
                    DataItemLink = "Employee No." = FIELD("Employee No.");
                    DataItemTableView = SORTING("Employee No.", Date, "Time Activity Code");
                    RequestFilterFields = "Time Activity Code", "Timesheet Code";

                    trigger OnAfterGetRecord()
                    var
                        ActivityCode: Code[10];
                    begin
                        if (DayNo <> Date2DMY(Date, 1)) and (DayNo <> 0) then begin
                            FillDayCells(DayNo, ActivityCellText, HoursCellText);
                            ActivityCellText := '';
                            HoursCellText := '';
                            IsFirstEntry := true;
                        end;

                        if UseTimesheetCodes then
                            ActivityCode := "Timesheet Code"
                        else
                            ActivityCode := "Time Activity Code";

                        if not IsWorkingActivity("Time Activity Code") then
                            InsertAbsenceActivity("Timesheet Detail", 1, ActivityCode);

                        if IsFirstEntry then begin
                            ActivityCellText := ActivityCode;
                            if IsWorkingActivity("Time Activity Code") then
                                HoursCellText := Format("Actual Hours");
                        end else begin
                            ActivityCellText := ActivityCellText + '/' + ActivityCode;
                            if IsWorkingActivity("Time Activity Code") then
                                HoursCellText := HoursCellText + '/' + Format("Actual Hours");
                        end;

                        if IsWorkingActivity("Time Activity Code") then
                            if Date2DMY(Date, 1) < HalfMonthDayConst then begin
                                HoursFirstHalf += "Actual Hours";
                                WorkingDaysFirstHalfMonth += 1;
                            end else begin
                                HoursSecondHalf += "Actual Hours";
                                WorkingDaysSecondHalfMonth += 1;
                            end;
                        IsFirstEntry := false;

                        DayNo := Date2DMY(Date, 1);
                    end;

                    trigger OnPostDataItem()
                    begin
                        if DayNo <> 0 then
                            FillDayCells(DayNo, ActivityCellText, HoursCellText);

                        ExcelMgt.FillCell('DI' + Format(RowNo), Format(WorkingDaysFirstHalfMonth));
                        ExcelMgt.FillCell('DI' + Format(RowNo + 1), Format(HoursFirstHalf));
                        ExcelMgt.FillCell('DI' + Format(RowNo + 2), Format(WorkingDaysSecondHalfMonth));
                        ExcelMgt.FillCell('DI' + Format(RowNo + 3), Format(HoursSecondHalf));

                        ExcelMgt.FillCell('DT' + Format(RowNo), Format(WorkingDaysFirstHalfMonth + WorkingDaysSecondHalfMonth));
                        ExcelMgt.FillCell('DT' + Format(RowNo + 2), Format(HoursSecondHalf + HoursFirstHalf));

                        ExcelMgt.FillCell('EZ' + Format(RowNo), Format(DaysFirstHalf + DaysSecondHalf));

                        FillAbsenceActivities;

                        RowNo += 4;
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetFilter(Date, '>=%1&<=%2', FirstDay, LastDay);

                        HoursFirstHalf := 0;
                        DaysFirstHalf := 0;
                        HoursSecondHalf := 0;
                        DaysSecondHalf := 0;
                        WorkingDaysFirstHalfMonth := 0;
                        WorkingDaysSecondHalfMonth := 0;

                        AbsenceBuffer.Reset();
                        AbsenceBuffer.DeleteAll();

                        IsFirstEntry := true;
                        DayNo := 0;

                        ActivityCellText := '';
                        HoursCellText := '';
                    end;
                }

                trigger OnAfterGetRecord()
                var
                    Employee: Record Employee;
                    Position: Record Position;
                begin
                    ExcelMgt.CopyRowsTo(RowNo, RowNo + 3, RowNo + 4);

                    if not (("Starting Date" <= LastDay) and
                            (("Ending Date" >= FirstDay) or ("Ending Date" = 0D)))
                    then
                        CurrReport.Break();

                    ExcelMgt.FillCell('A' + Format(RowNo), Format(EmployeeReportNumber));

                    Employee.Get("Employee No.");
                    ExcelMgt.FillCell('I' + Format(RowNo), Employee.GetNameInitials + ' ' + Employee.GetJobTitleName);

                    ExcelMgt.FillCell('AJ' + Format(RowNo), "Employee No.");

                    Position.Get("Position No.");
                    ExcelMgt.FillCell('EA' + Format(RowNo), Position."Job Title Code");
                    ExcelMgt.FillCell('EK' + Format(RowNo), Position."Posting Group");

                    EmployeeReportNumber += 1;
                end;

                trigger OnPreDataItem()
                begin
                    EmployeeReportNumber := 0;
                end;
            }

            trigger OnAfterGetRecord()
            var
                Employee: Record Employee;
                LocalRepMgt: Codeunit "Local Report Management";
            begin
                ExcelMgt.OpenSheet(Code + ' ' + Name);

                // header
                ExcelMgt.FillCell('A7', LocalRepMgt.GetCompanyName);
                ExcelMgt.FillCell('II7', CompanyInfo."OKPO Code");
                ExcelMgt.FillCell('A9', Name);
                ExcelMgt.FillCell('EA13', NumDocument);
                ExcelMgt.FillCell('ES13', Format(LastDay));
                ExcelMgt.FillCell('FT13', Format(FirstDay));
                ExcelMgt.FillCell('GG13', Format(LastDay));

                // footer
                if Employee.Get("Timesheet Owner") then begin
                    ExcelMgt.FillCell('X30', Employee.GetJobTitleName);
                    ExcelMgt.FillCell('BO30', Employee.GetNameInitials);
                end;

                if Employee.Get("Manager No.") then begin
                    ExcelMgt.FillCell('FG30', Employee.GetJobTitleName);
                    ExcelMgt.FillCell('GW30', Employee.GetNameInitials);
                end;

                if Employee.Get(CompanyInfo."HR Manager No.") then begin
                    ExcelMgt.FillCell('FG33', Employee.GetJobTitleName);
                    ExcelMgt.FillCell('GW33', Employee.GetNameInitials);
                end;
                RowNo := 24;
            end;

            trigger OnPreDataItem()
            begin
                "Organizational Unit".CopyFilters(OrgUnitSheets);

                LastDay := CalcDate('<CM>', DMY2Date(1, Month + 1, Year));
                FirstDay := CalcDate('<-CM>', DMY2Date(1, Month + 1, Year));
                MaxDayNo := LastDay - FirstDay + 1;
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(Year; Year)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Year';
                        MaxValue = 9999;
                        MinValue = 1;
                        ToolTip = 'Specifies the year that the Excel timesheet will be for.';

                        trigger OnDrillDown()
                        begin
                            if Year > 1 then
                                Year := Year - 1;
                            RequestOptionsPage.Update;
                        end;

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            if Year < 9999 then
                                Year := Year + 1;
                            RequestOptionsPage.Update;
                        end;
                    }
                    field(Month; Month)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Month';
                        OptionCaption = 'January,February,March,April,May,June,July,August,September,October,November,December';
                        ToolTip = 'Specifies the month that the Excel timesheet will be for.';
                    }
                    field(NumDocument; NumDocument)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document No.';
                        ToolTip = 'Specifies which related document(s) the Excel timesheet will be created for.';
                    }
                    field(UseTimesheetCodes; UseTimesheetCodes)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Use Timesheet Codes';
                        ToolTip = 'Specifies if the Excel timesheet will respect any specified timesheet codes.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            Year := Date2DMY(Today, 3);
            Month := Date2DMY(Today, 2) - 1;
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        Clear(MarkExcelMap);
        MarkExcelMap[1] := 'AW';
        MarkExcelMap[2] := 'BA';
        MarkExcelMap[3] := 'BE';
        MarkExcelMap[4] := 'BI';
        MarkExcelMap[5] := 'BM';
        MarkExcelMap[6] := 'BQ';
        MarkExcelMap[7] := 'BU';
        MarkExcelMap[8] := 'BY';
        MarkExcelMap[9] := 'CC';
        MarkExcelMap[10] := 'CG';
        MarkExcelMap[11] := 'CK';
        MarkExcelMap[12] := 'CO';
        MarkExcelMap[13] := 'CS';
        MarkExcelMap[14] := 'CW';
        MarkExcelMap[15] := 'DA';
        MarkExcelMap[16] := 'DE';

        HalfMonthDayConst := 16;
    end;

    trigger OnPostReport()
    begin
        ExcelMgt.DeleteSheet('1');
        if not TestMode then
          ExcelMgt.DownloadBook(ExcelTemplate.GetTemplateFileName(HumResSetup."T-13 Template Code"))
        else
          ExcelMgt.CloseBook;
    end;

    trigger OnPreReport()
    begin
        CompanyInfo.Get();

        HumResSetup.Get();
        HumResSetup.TestField("T-13 Template Code");
        FileName := ExcelTemplate.OpenTemplate(HumResSetup."T-13 Template Code");

        CompanyInfo.Get();
    end;

    var
        HumResSetup: Record "Human Resources Setup";
        CompanyInfo: Record "Company Information";
        AbsenceBuffer: Record "Aging Band Buffer" temporary;
        ExcelTemplate: Record "Excel Template";
        ExcelMgt: Codeunit "Excel Management";
        Month: Option "ƒ¡óáÓý","öÑóÓá½ý","îáÓÔ","Ç»ÓÑ½ý","îá®","ê¯¡ý","ê¯½ý","ÇóúÒßÔ","æÑ¡Ô´íÓý","Ä¬Ô´íÓý","ì«´íÓý","äÑ¬áíÓý";
        Year: Integer;
        LastDay: Date;
        FirstDay: Date;
        NumDocument: Text[30];
        OrgUnitName: Text[60];
        RowNo: Integer;
        MarkExcelMap: array[16] of Text[30];
        MaxDayNo: Integer;
        FileName: Text[1024];
        HoursFirstHalf: Decimal;
        HoursSecondHalf: Decimal;
        DaysFirstHalf: Decimal;
        DaysSecondHalf: Decimal;
        WorkingDaysFirstHalfMonth: Decimal;
        WorkingDaysSecondHalfMonth: Decimal;
        IsFirstEntry: Boolean;
        ActivityCellText: Text[250];
        HoursCellText: Text[250];
        DayNo: Integer;
        HalfMonthDayConst: Integer;
        EmployeeReportNumber: Integer;
        UseTimesheetCodes: Boolean;
        TestMode: Boolean;

    [Scope('OnPrem')]
    procedure FillAbsenceActivities()
    var
        AbsenceRowNo: Integer;
    begin
        AbsenceBuffer.Reset();
        if not AbsenceBuffer.FindSet then
            exit;

        repeat
            if AbsenceRowNo <= 3 then begin
                ExcelMgt.FillCell('GO' + Format(RowNo + AbsenceRowNo), AbsenceBuffer."Currency Code");
                ExcelMgt.FillCell('HD' + Format(RowNo + AbsenceRowNo), Format(AbsenceBuffer."Column 1 Amt."));
            end else begin
                ExcelMgt.FillCell('HS' + Format(RowNo + AbsenceRowNo - 4), AbsenceBuffer."Currency Code");
                ExcelMgt.FillCell('IH' + Format(RowNo + AbsenceRowNo - 4), Format(AbsenceBuffer."Column 1 Amt."));
            end;

            AbsenceRowNo += 1;
        until (AbsenceBuffer.Next = 0) or (AbsenceRowNo >= 8);
    end;

    [Scope('OnPrem')]
    procedure InsertAbsenceActivity(var TimesheetDetail: Record "Timesheet Detail"; Days: Integer; ActivityCode: Code[10]) IsAbsenceActivity: Boolean
    var
        TimeActivity: Record "Time Activity";
    begin
        if not CheckActivityCode(ActivityCode, TimesheetDetail.Date) then
            exit(false);

        TimeActivity.Get(TimesheetDetail."Time Activity Code");

        AbsenceBuffer.Reset();
        IsAbsenceActivity := true;

        if TimeActivity."Time Activity Type" > 0 then
            if AbsenceBuffer.Get(ActivityCode) then begin
                AbsenceBuffer."Column 1 Amt." += Days;
                AbsenceBuffer.Modify();
            end else begin
                AbsenceBuffer.Init();
                AbsenceBuffer."Currency Code" := ActivityCode;
                AbsenceBuffer."Column 1 Amt." := Days;
                AbsenceBuffer.Insert();
            end
        else
            IsAbsenceActivity := false;

        exit(IsAbsenceActivity);
    end;

    [Scope('OnPrem')]
    procedure FillDayCells(DayNo: Integer; ActivityCellText: Text[250]; HoursCellText: Text[250])
    begin
        if DayNo < HalfMonthDayConst then begin
            ExcelMgt.FillCell(MarkExcelMap[DayNo] + Format(RowNo), ActivityCellText);
            ExcelMgt.FillCell(MarkExcelMap[DayNo] + Format(RowNo + 1), HoursCellText);

            DaysFirstHalf += 1;
        end else begin
            ExcelMgt.FillCell(MarkExcelMap[DayNo - (HalfMonthDayConst - 1)] + Format(RowNo + 2), ActivityCellText);
            ExcelMgt.FillCell(MarkExcelMap[DayNo - (HalfMonthDayConst - 1)] + Format(RowNo + 3), HoursCellText);

            DaysSecondHalf += 1;
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckActivityCode(ActivityCode: Code[10]; ActivityDate: Date): Boolean
    var
        HumResSetup: Record "Human Resources Setup";
        TimeActivityGroup: Record "Time Activity Group";
    begin
        HumResSetup.Get();

        if TimeActivityGroup.Get(HumResSetup."T-13 Weekend Work Group code") then
            exit(not TimeActivityGroup.TimeActivityInGroup(ActivityCode, ActivityDate));

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure IsWorkingActivity(ActivityCode: Code[10]): Boolean
    var
        TimeActivity: Record "Time Activity";
    begin
        if TimeActivity.Get(ActivityCode) then
            exit((TimeActivity."Time Activity Type" = TimeActivity."Time Activity Type"::Presence) or
              (TimeActivity."Time Activity Type" = TimeActivity."Time Activity Type"::Travel));

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure SetTestMode(NewTestMode: Boolean)
    begin
        TestMode := NewTestMode;
        Year := Date2DMY(WorkDate, 3) - 1;
        Month := 11;
    end;
}

