report 17355 "Statistic Form P-4"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Statistic Form P-4';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Company Information"; "Company Information")
        {
            DataItemTableView = SORTING("Primary Key");

            trigger OnPreDataItem()
            var
                EmployeeQty: array[3] of Decimal;
                GroundsOfTermination: Record "Grounds for Termination";
                LaborContract: Record "Labor Contract";
                Employee: Record Employee;
                LocMgt: Codeunit "Localisation Management";
                SalaryStartDate: Date;
                SalaryEndDate: Date;
                LocRepMgt: Codeunit "Local Report Management";
                PrimarySalary: Decimal;
                ExternalSalary: Decimal;
                CivilSalary: Decimal;
                AllBonuses: Decimal;
            begin
                ExcelMgt.OpenBookForUpdate(FileName);
                ExcelMgt.OpenSheet('Sheet1');

                ExcelMgt.FillCell('BQ10', LocMgt.GetMonthName(StartDate, false));
                ExcelMgt.FillCell('CI10', Format(Date2DMY(StartDate, 3) mod 100));

                ExcelMgt.FillCell('AV26', CompanyInfo.Name + CompanyInfo."Name 2");
                ExcelMgt.FillCell('S29', LocRepMgt.GetCompanyAddress);
                ExcelMgt.FillCell('AC34', CompanyInfo."OKPO Code");

                ExcelMgt.OpenSheet('Sheet2_3');
                // ExcelMgt.FillCell('AN9',CompanyInfo."OKVED Code");
                ExcelMgt.FillCell('AN10', CompanyInfo."OKVED Code");

                CalcAverageEmployeeQty(EmployeeQty);
                ExcelMgt.FillCell('BD9', Format(EmployeeQty[1] + EmployeeQty[2] + EmployeeQty[3]));
                ExcelMgt.FillCell('CB9', Format(EmployeeQty[1]));
                ExcelMgt.FillCell('CY9', Format(EmployeeQty[2]));
                ExcelMgt.FillCell('DV9', Format(EmployeeQty[3]));

                ExcelMgt.FillCell('BD10', Format(EmployeeQty[1] + EmployeeQty[2] + EmployeeQty[3]));
                ExcelMgt.FillCell('CB10', Format(EmployeeQty[1]));
                ExcelMgt.FillCell('CY10', Format(EmployeeQty[2]));
                ExcelMgt.FillCell('DV10', Format(EmployeeQty[3]));

                ExcelMgt.FillCell('T31', Format(CalcWorkHours(StartDate, EndDate, false)));
                ExcelMgt.FillCell('AI31', Format(CalcWorkHours(StartDate, EndDate, true)));

                SalaryEndDate := EndDate;
                if CalcMode = CalcMode::YTD then
                    SalaryStartDate := CalcDate('<-CY>', StartDate)
                else
                    SalaryStartDate := StartDate;

                PrimarySalary := CalcSalaryAmount(SalaryStartDate, SalaryEndDate, LaborContract."Work Mode"::"Primary Job", false) +
                  CalcSalaryAmount(SalaryStartDate, SalaryEndDate, LaborContract."Work Mode"::"Internal Co-work", false);
                ExternalSalary := CalcSalaryAmount(SalaryStartDate, SalaryEndDate, LaborContract."Work Mode"::"External Co-work", false);
                CivilSalary := CalcSalaryAmount(SalaryStartDate, SalaryEndDate, -1, true);
                ExcelMgt.FillCell('AY31', FormatToThousands(PrimarySalary + ExternalSalary + CivilSalary));
                ExcelMgt.FillCell('BQ31', FormatToThousands(PrimarySalary));
                ExcelMgt.FillCell('CH31', FormatToThousands(ExternalSalary));
                ExcelMgt.FillCell('CW31', FormatToThousands(CivilSalary));

                AllBonuses := CalcBonusAmount(SalaryStartDate, SalaryEndDate);
                ExcelMgt.FillCell('DW31', FormatToThousands(AllBonuses));

                ExcelMgt.OpenSheet('Sheet4');
                ExcelMgt.FillCell('CW8', Format(GetHiresCount(DMY2Date(1, 1, Date2DMY(StartDate, 3)), EndDate, false)));
                ExcelMgt.FillCell('CW10', Format(GetHiresCount(DMY2Date(1, 1, Date2DMY(StartDate, 3)), EndDate, true)));
                ExcelMgt.FillCell('CW11', Format(GetDismissalCount(DMY2Date(1, 1, Date2DMY(StartDate, 3)), EndDate, -1)));
                ExcelMgt.FillCell('CW12', Format(GetDismissalCount(DMY2Date(1, 1, Date2DMY(StartDate, 3)), EndDate,
                      GroundsOfTermination."Reporting Type"::"Staff Reduction")));
                ExcelMgt.FillCell('CW14', Format(GetDismissalCount(DMY2Date(1, 1, Date2DMY(StartDate, 3)), EndDate,
                      GroundsOfTermination."Reporting Type"::"Employee Decision")));

                ExcelMgt.FillCell('CW15', Format(GetPrimaryJobsCount(DMY2Date(1, 1, Date2DMY(StartDate, 3) + 1))));
                ExcelMgt.FillCell('CW17', Format(GetOpenPositions(DMY2Date(1, 1, Date2DMY(StartDate, 3) + 1))));

                if Employee.Get(RespEmployeeNo) then begin
                    ExcelMgt.FillCell('AV26', Employee.GetJobTitleName);
                    ExcelMgt.FillCell('CE26', Employee.GetFullName);
                    ExcelMgt.FillCell('AV29', Employee."Phone No.");
                end;

                if CreationDate <> 0D then begin
                    ExcelMgt.FillCell('CG29', Format(Date2DMY(CreationDate, 1)));
                    ExcelMgt.FillCell('CN29', LocMgt.Month2Text(CreationDate));
                    ExcelMgt.FillCell('DD29', Format(Date2DMY(CreationDate, 3) mod 100));
                end;
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
                        Caption = 'Period Starting Date';
                    }
                    field(EndDate; EndDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period Ending Date';
                        Enabled = true;
                    }
                    field(CalcMode; CalcMode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Calc Mode';
                        OptionCaption = 'Period,YTD';
                    }
                    field(RespEmployeeNo; RespEmployeeNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Responsible Employee';
                        Enabled = true;
                        TableRelation = Employee."No.";
                        ToolTip = 'Specifies the employee who is responsible for the validity of the data in the report.';
                    }
                    field(CreationDate; CreationDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Creation Date';
                        ToolTip = 'Specifies when the report data was created.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            StartDate := CalcDate('<-CM>', Today);
            EndDate := CalcDate('<CM>', Today);

            CreationDate := Today;
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        ExcelMgt.DownloadBook(ExcelTemplate.GetTemplateFileName(HumResSetup."P-4 Template Code"));
    end;

    trigger OnPreReport()
    begin
        if StartDate = 0D then
            Error(Text14700);
        if EndDate = 0D then
            Error(Text14701);
        Period := Format(StartDate, 0, '<Month Text>') + ' ' + Format(Date2DMY(StartDate, 3)) + Text14703;

        HumResSetup.Get();
        HumResSetup.TestField("P-4 Template Code");

        FileName := ExcelTemplate.OpenTemplate(HumResSetup."P-4 Template Code");

        CompanyInfo.Get();
    end;

    var
        CompanyInfo: Record "Company Information";
        HumResSetup: Record "Human Resources Setup";
        ExcelTemplate: Record "Excel Template";
        ExcelMgt: Codeunit "Excel Management";
        Period: Text[100];
        StartDate: Date;
        EndDate: Date;
        Text14700: Label 'Please enter Period Start Date';
        Text14701: Label 'Please enter Period End Date';
        Text14703: Label ' year';
        CalcMode: Option Period,YTD;
        FileName: Text[1024];
        RespEmployeeNo: Code[20];
        CreationDate: Date;

    [Scope('OnPrem')]
    procedure CalcAverageEmployeeQty(var AvgEmplCount: array[3] of Decimal)
    var
        AverageHeadcountCalculation: Codeunit "Average Headcount Calculation";
        Employee: Record Employee;
        LaborContract: Record "Labor Contract";
    begin
        Employee.SetRange("Skip for Avg. HC Calculation", false);
        if Employee.FindSet then
            repeat
                if LaborContract.Get(Employee."Contract No.") then
                    if LaborContract."Contract Type" = LaborContract."Contract Type"::"Civil Contract" then
                        AvgEmplCount[3] += AverageHeadcountCalculation.CalcAvgCount(Employee."No.", EndDate)
                    else
                        case LaborContract."Work Mode" of
                            LaborContract."Work Mode"::"Primary Job":
                                AvgEmplCount[1] += AverageHeadcountCalculation.CalcAvgCount(Employee."No.", EndDate);
                            LaborContract."Work Mode"::"External Co-work":
                                AvgEmplCount[2] += AverageHeadcountCalculation.CalcAvgCount(Employee."No.", EndDate);
                        end;
            until Employee.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure GetHiresCount(StartingDate: Date; EndingDate: Date; IsCurrentYear: Boolean): Integer
    var
        LaborContract: Record "Labor Contract";
    begin
        with LaborContract do begin
            SetRange("Starting Date", StartingDate, EndingDate);
            if IsCurrentYear then
                SetRange("Ending Date", 0D, DMY2Date(31, 12, Date2DMY(StartDate, 3)));

            SetFilter(Status, '<>%1', Status::Open);
            SetRange("Contract Type", "Contract Type"::"Labor Contract");
            SetFilter("Work Mode", '<>%1', "Work Mode"::"External Co-work");

            exit(Count);
        end;
    end;

    [Scope('OnPrem')]
    procedure GetDismissalCount(StartingDate: Date; EndingDate: Date; DismissalType: Integer) "Count": Integer
    var
        LaborContractLines: Record "Labor Contract Line";
        GroundsOfTermination: Record "Grounds for Termination";
        LaborContract: Record "Labor Contract";
    begin
        LaborContractLines.SetRange("Operation Type", LaborContractLines."Operation Type"::Dismissal);
        LaborContractLines.SetRange("Starting Date", StartingDate, EndingDate);

        if LaborContractLines.FindSet then
            repeat
                if LaborContract.Get(LaborContractLines."Contract No.") then
                    if (LaborContract."Contract Type" <> LaborContract."Contract Type"::"Labor Contract") and
                       (LaborContract."Work Mode" <> LaborContract."Work Mode"::"External Co-work")
                    then
                        if DismissalType <> -1 then begin
                            if GroundsOfTermination.Get(LaborContractLines."Dismissal Reason") then
                                if GroundsOfTermination."Reporting Type" = DismissalType then
                                    Count += 1;
                        end else
                            Count += 1;
            until LaborContractLines.Next() = 0;

        exit(Count);
    end;

    [Scope('OnPrem')]
    procedure GetPrimaryJobsCount(StartingDate: Date): Integer
    var
        LaborContracts: Record "Labor Contract";
    begin
        LaborContracts.SetFilter("Ending Date", '%1|>%2', 0D, StartingDate);
        LaborContracts.SetFilter(Status, '<>%1', LaborContracts.Status::Open);
        LaborContracts.SetRange("Contract Type", LaborContracts."Contract Type"::"Labor Contract");
        LaborContracts.SetFilter("Work Mode", '<>%1', LaborContracts."Work Mode"::"External Co-work");

        exit(LaborContracts.Count);
    end;

    [Scope('OnPrem')]
    procedure GetOpenPositions(StartingDate: Date): Integer
    var
        Position: Record Position;
    begin
        Position.SetRange(Status, Position.Status::Approved);
        Position.SetRange("Filled Rate", 0);
        Position.SetFilter("Ending Date", '%1|>%2', 0D, StartingDate);

        exit(Position.Count);
    end;

    [Scope('OnPrem')]
    procedure CalcWorkHours(StartingDate: Date; EndingDate: Date; IsExternal: Boolean) Hours: Decimal
    var
        LaborContracts: Record "Labor Contract";
        HumResSetup: Record "Human Resources Setup";
        TimesheetMgt: Codeunit "Timesheet Management RU";
    begin
        HumResSetup.Get();

        with LaborContracts do begin
            SetFilter(Status, '<>%1', Status::Open);
            SetRange("Contract Type", "Contract Type"::"Labor Contract");
            if IsExternal then
                SetRange("Work Mode", "Work Mode"::"External Co-work")
            else
                SetFilter("Work Mode", '<>%1', "Work Mode"::"External Co-work");

            if FindSet then
                repeat
                    Hours += TimesheetMgt.GetTimesheetInfo("Employee No.", HumResSetup."P-4 Work Time Group Code",
                        StartingDate, EndingDate, 4);
                until Next() = 0;
        end;

        exit(Hours);
    end;

    [Scope('OnPrem')]
    procedure CalcSalaryAmount(StartingDate: Date; EndingDate: Date; WorkMode: Integer; IsCivilContract: Boolean) Salary: Decimal
    var
        PayrollDocCalc: Codeunit "Payroll Document - Calculate";
        LaborContracts: Record "Labor Contract";
        HumResSetup: Record "Human Resources Setup";
    begin
        HumResSetup.Get();

        with LaborContracts do begin
            SetFilter(Status, '<>%1', Status::Open);

            if IsCivilContract then
                SetRange("Contract Type", "Contract Type"::"Civil Contract")
            else
                SetRange("Contract Type", "Contract Type"::"Labor Contract");

            if WorkMode >= 0 then
                SetRange("Work Mode", WorkMode);

            if FindSet then
                repeat
                    Salary += PayrollDocCalc.CalcElementByPostedEntries(HumResSetup."P-4 Salary Element Code", "Employee No.",
                        StartingDate, EndingDate, '');
                    Salary += PayrollDocCalc.CalcElementByPostedEntries(HumResSetup."P-4 Benefits Element Code", "Employee No.",
                        StartingDate, EndingDate, '');
                until Next() = 0;
        end;

        exit(Salary);
    end;

    [Scope('OnPrem')]
    procedure CalcBonusAmount(StartingDate: Date; EndingDate: Date) Salary: Decimal
    var
        PayrollDocCalc: Codeunit "Payroll Document - Calculate";
        LaborContracts: Record "Labor Contract";
        HumResSetup: Record "Human Resources Setup";
    begin
        HumResSetup.Get();

        with LaborContracts do begin
            SetFilter(Status, '<>%1', Status::Open);

            if FindSet then
                repeat
                    Salary += PayrollDocCalc.CalcElementByPostedEntries(HumResSetup."P-4 Benefits Element Code", "Employee No.",
                        StartingDate, EndingDate, '');
                until Next() = 0;
        end;

        exit(Salary);
    end;

    [Scope('OnPrem')]
    procedure FormatToThousands(Value: Decimal): Text[1024]
    begin
        exit(Format(Round(Value, 100) / 1000));
    end;
}

