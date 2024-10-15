report 17356 "Statistic Form FNS-1"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Statistic Form FNS-1';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
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
                    field(ReportDate; ReportDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Report Date';
                        ToolTip = 'Specifies when the report was created.';
                    }
                    field(StartDate; StartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Start Date';
                        ToolTip = 'Specifies the beginning of the period for which entries are adjusted. This field is usually left blank, but you can enter a date.';
                    }
                    field(EndDate; EndDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'End Date';
                        ToolTip = 'Specifies the date to which the report or batch job processes information.';
                    }
                    field(EmployeeFullName; EmployeeFullName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Responsible Employee';
                        ToolTip = 'Specifies the employee who is responsible for the validity of the data in the report.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            ResponsibleEmployee.Reset();
                            if PAGE.RunModal(PAGE::"Employee List", ResponsibleEmployee) = ACTION::LookupOK then
                                EmployeeFullName := ResponsibleEmployee.FullName;
                        end;
                    }
                    group("Employees to strike off")
                    {
                        Caption = 'Employees to strike off';
                        field(HiredDate; HiredDate)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Hired After';
                        }
                        field(FiredDate; FiredDate)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Dismissed Before';
                        }
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
    begin
        ReportDate := WorkDate;

        StartDate := 20150401D;
        EndDate := 20150430D;

        HiredDate := 20150401D;
        FiredDate := 20150501D;
    end;

    trigger OnPostReport()
    var
        FileName: Text[250];
        ExcelMgt: Codeunit "Excel Management";
        LocalisationMgt: Codeunit "Localisation Management";
        HumanResourcesSetup: Record "Human Resources Setup";
        CompanyInformation: Record "Company Information";
        ExcelTemplate: Record "Excel Template";
        LocRepMgt: Codeunit "Local Report Management";
    begin
        CompanyInformation.Get();
        HumanResourcesSetup.Get();
        HumanResourcesSetup.TestField("FSN-1 Template Code");

        if not IsSilentEmpStatisticalBuffer then
            FillStatisticalBuffer;

        FileName := ExcelTemplate.OpenTemplate(HumanResourcesSetup."FSN-1 Template Code");

        ExcelMgt.OpenBookForUpdate(FileName);
        //Sheet1
        ExcelMgt.OpenSheet('Sheet1');

        ExcelMgt.FillCell('AV24', LocRepMgt.GetCompanyName);

        ExcelMgt.FillCell('S26', CompanyInformation."Post Code" + ', ' + CompanyInformation.City + ', ' +
          CompanyInformation.Address + ' ' + CompanyInformation."Address 2");

        ExcelMgt.FillCell('S31', CompanyInformation."OKPO Code");

        //Sheet2
        ExcelMgt.OpenSheet('Sheet2');

        FillExcelStatisticalSheet(ExcelMgt, EmployeeStatisticalBuffer, StatisticalLines);

        if EmployeeStatisticalBuffer.Get(StatisticalLines + 1) then
            ExcelMgt.FillCell('BC28', Format(EmployeeStatisticalBuffer.Quantity));

        // Avg. Amount for all employees
        ExcelMgt.FillCell('BC29', Format(Round(AverageListQuantity, 1)));

        // Total Salary Amount (excluding external workers)
        ExcelMgt.FillCell('BC30', Format(GetTotalSalaryAmount));

        // ReportDate
        ExcelMgt.FillCell('DC40', Format(ReportDate, 0, '<Day,2>'));
        ExcelMgt.FillCell('DJ40', Format(LocalisationMgt.Month2Text(ReportDate)));
        ExcelMgt.FillCell('DZ40', Format(ReportDate, 0, '<Year,2>'));

        // ResponsibleEmployee
        ExcelMgt.FillCell('AV37', ResponsibleEmployee."Job Title");
        ExcelMgt.FillCell('CE37', EmployeeFullName);
        ExcelMgt.FillCell('AV40', ResponsibleEmployee."Phone No.");
        ExcelMgt.FillCell('CD40', ResponsibleEmployee."E-Mail");

        if FileNameSilent <> '' then begin
            ExcelMgt.SaveWrkBook(FileNameSilent);
            ExcelMgt.CloseBook;
        end else
          ExcelMgt.DownloadBook(ExcelTemplate.GetTemplateFileName(HumanResourcesSetup."FSN-1 Template Code"));
    end;

    trigger OnPreReport()
    var
        Text001: Label 'All fields must be filled.';
    begin
        if (ReportDate = 0D) or (StartDate = 0D) or (EndDate = 0D) or (EmployeeFullName = '') then
            Error(Text001);

        WageAmount := GetLatestMinimumWageAmount(EndDate);

        StatisticalLines := 21;

        if not IsSilentEmpStatisticalBuffer then
            InitialiseStatisticalBuffer(EmployeeStatisticalBuffer, StatisticalLines);
    end;

    var
        ReportDate: Date;
        StartDate: Date;
        EndDate: Date;
        EmployeeFullName: Text[100];
        ResponsibleEmployee: Record Employee;
        HiredDate: Date;
        FiredDate: Date;
        EmployeeStatisticalBuffer: Record "Item Journal Buffer" temporary;
        StatisticalLines: Integer;
        WageAmount: Decimal;
        FileNameSilent: Text;
        IsSilentEmpStatisticalBuffer: Boolean;

    [Scope('OnPrem')]
    procedure FillStatisticalBuffer()
    var
        Employee: Record Employee;
    begin
        Employee.Reset();

        if Employee.FindSet then
            repeat
                if ValidEmployee(Employee, StartDate, EndDate, HiredDate, FiredDate) then
                    SaveSummaryAmountInfo(Round(GetEmployeeSalaryAmount(StartDate, Employee."No."), 0.1), EmployeeStatisticalBuffer);
            until Employee.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure ValidEmployee(Employee: Record Employee; StartDate: Date; EndDate: Date; HireDate: Date; DismissalDate: Date) Result: Boolean
    var
        Limit: Integer;
        LaborContract: Record "Labor Contract";
    begin
        with Employee do begin
            if not IsEmployed(HireDate) then
                exit(false);
            if IsTerminated(DismissalDate) then
                exit(false);

            if not LaborContract.Get("Contract No.") then
                exit(false);
            if (LaborContract."Work Mode" = LaborContract."Work Mode"::"Internal Co-work") or // internal - ?
               (LaborContract."Work Mode" = LaborContract."Work Mode"::"External Co-work")
            then
                exit(false);

            if LaborContract."Contract Type" = LaborContract."Contract Type"::"Civil Contract" then
                exit(false);

            if SickLeave("No.", StartDate, EndDate) then
                exit(false);

            // Exlude empl. with >40h absence
            Limit := 40;
            Limit := Limit - (GetPlannedHours("No.", StartDate, EndDate) - GetActualHours("No.", StartDate, EndDate));

            exit(Limit >= 0);
        end;

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure SickLeave(EmployeeNo: Code[20]; StartDate: Date; EndDate: Date): Boolean
    var
        PostedAbsenceHeader: Record "Posted Absence Header";
    begin
        with PostedAbsenceHeader do begin
            // Exclude sick entries
            SetRange("Employee No.", EmployeeNo);
            SetFilter("Start Date", '<=%1', EndDate);
            SetFilter("End Date", '>=%1', StartDate);
            SetRange("Document Type", "Document Type"::"Sick Leave");
            if FindFirst then
                exit(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure SaveSummaryAmountInfo(SummaryAmount: Decimal; var EmployeeStatisticalBuffer: Record "Item Journal Buffer" temporary)
    begin
        FillSalaryRange(SummaryAmount, EmployeeStatisticalBuffer);

        UpdateStatisticalLine(21, SummaryAmount, EmployeeStatisticalBuffer);

        if SummaryAmount < WageAmount then
            UpdateStatisticalLine(22, SummaryAmount, EmployeeStatisticalBuffer);
    end;

    [Scope('OnPrem')]
    procedure GetEmployeeSalaryAmount(AtDate: Date; EmployeeNo: Code[20]) SalaryAmount: Decimal
    var
        PayrollPeriod: Record "Payroll Period";
        Employee: Record Employee;
        DetailedPayrollLedgerEntry: Record "Detailed Payroll Ledger Entry";
    begin
        PayrollPeriod.Get(PayrollPeriod.PeriodByDate(AtDate));

        Employee.SetRange("Employee No. Filter", EmployeeNo);
        Employee.SetFilter("Element Type Filter", '%1', DetailedPayrollLedgerEntry."Element Type"::Wage);
        Employee.SetRange("Wage Period Filter", PayrollPeriod.Code);
        Employee.CalcFields("Payroll Amount");

        SalaryAmount := Employee."Payroll Amount";
        Employee.SetFilter("Element Type Filter", '%1', DetailedPayrollLedgerEntry."Element Type"::Bonus);
        Employee.CalcFields("Payroll Amount");
        SalaryAmount += Employee."Payroll Amount";
    end;

    [Scope('OnPrem')]
    procedure FillExcelStatisticalSheet(ExcelMgt: Codeunit "Excel Management"; var EmployeeStatisticalBuffer: Record "Item Journal Buffer" temporary; StatisticalLines: Integer)
    var
        StartLine: Integer;
        PeopleQtyColumn: Text[2];
        SummColumn: Text[2];
        I: Integer;
    begin
        StartLine := 4;
        PeopleQtyColumn := 'AV';
        SummColumn := 'CB';

        for I := StartLine to StatisticalLines + StartLine do begin
            EmployeeStatisticalBuffer.Get(I - StartLine);
            ExcelMgt.FillCell(PeopleQtyColumn + Format(I), Format(EmployeeStatisticalBuffer.Quantity));
            ExcelMgt.FillCell(SummColumn + Format(I), Format(EmployeeStatisticalBuffer."Inventory Value (Calculated)"));
        end;
    end;

    [Scope('OnPrem')]
    procedure InitialiseStatisticalBuffer(var EmployeeStatisticalBuffer: Record "Item Journal Buffer" temporary; Lines: Integer)
    var
        I: Integer;
    begin
        EmployeeStatisticalBuffer.Reset();
        EmployeeStatisticalBuffer.DeleteAll();

        // Line No. | Range
        // 0     | Salary < 5965
        // 1     | 5965 < Salary < 7400
        // 2     | 7400 < Salary < 9000
        // 3     | 9000 < Salary < 10600
        // 4     | 10600 < Salary < 12200
        // 5     | 12200 < Salary < 13800
        // 6     | 13800 < Salary < 15400
        // 7     | 15400 < Salary < 17000
        // 8     | 17000 < Salary < 18600
        // 9     | 18600 < Salary < 21800
        // 10    | 21800 < Salary < 25000
        // 11    | 25000 < Salary < 30000
        // 12    | 30000 < Salary < 35000
        // 13    | 35000 < Salary < 40000
        // 14    | 40000 < Salary < 50000
        // 15    | 50000 < Salary < 75000
        // 16    | 75000 < Salary < 100000
        // 17    | 100000 < Salary < 250000
        // 18    | 250000 < Salary < 500000
        // 19    | 500000 < Salary < 1000000
        // 20    | 1000000 < Salary
        // 21    | employee total
        // 22    | EXCEPTION: Qty of employee with salary less then minimum

        for I := 0 to Lines + 1 do begin
            EmployeeStatisticalBuffer.Init();
            EmployeeStatisticalBuffer."Line No." := I;
            EmployeeStatisticalBuffer.Insert();
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateStatisticalLine(LineId: Integer; Amount: Decimal; var EmployeeStatisticalBuffer: Record "Item Journal Buffer" temporary)
    begin
        with EmployeeStatisticalBuffer do begin
            Get(LineId);
            "Inventory Value (Calculated)" := "Inventory Value (Calculated)" + Amount;
            Quantity := Quantity + 1;
            Modify;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetLatestMinimumWageAmount(ToDate: Date): Decimal
    var
        PayrollLimit: Record "Payroll Limit";
        PayrollPeriod: Record "Payroll Period";
        PayrollDocumentCalculate: Codeunit "Payroll Document - Calculate";
    begin
        exit(PayrollDocumentCalculate.GetFSILimit(PayrollPeriod.PeriodByDate(ToDate), PayrollLimit.Type::MROT));
    end;

    [Scope('OnPrem')]
    procedure AverageListQuantity() AverageList: Decimal
    var
        LaborContract: Record "Labor Contract";
        Employee: Record Employee;
        AverageHeadcountCalculation: Codeunit "Average Headcount Calculation";
    begin
        if Employee.FindSet then
            repeat
                if LaborContract.Get(Employee."Contract No.") then
                    if (LaborContract."Work Mode" <> LaborContract."Work Mode"::"External Co-work") and
                       (LaborContract."Contract Type" = LaborContract."Contract Type"::"Labor Contract")
                    then
                        AverageList += AverageHeadcountCalculation.CalcAvgCount(Employee."No.", EndDate);
            until Employee.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure GetTotalSalaryAmount() TotalSalaryAmount: Decimal
    begin
        TotalSalaryAmount := CalcSalaryAmount(StartDate, EndDate, 0, false);
        TotalSalaryAmount += CalcBonusAmount(StartDate, EndDate);
    end;

    [Scope('OnPrem')]
    procedure MinDate(Date1: Date; Date2: Date) ResDate: Date
    begin
        if Date1 < Date2 then
            exit(Date1);

        exit(Date2);
    end;

    [Scope('OnPrem')]
    procedure MaxDate(Date1: Date; Date2: Date) ResDate: Date
    begin
        if Date1 > Date2 then
            exit(Date1);

        exit(Date2);
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
                    Salary += PayrollDocCalc.CalcElementByPostedEntries(HumResSetup."FSN-1 Salary Element Code", "Employee No.",
                        StartingDate, EndingDate, '');
                until Next = 0;
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
                    Salary += PayrollDocCalc.CalcElementByPostedEntries(HumResSetup."FSN-1 Bonus Element Code", "Employee No.",
                        StartingDate, EndingDate, '');
                until Next = 0;
        end;

        exit(Salary);
    end;

    [Scope('OnPrem')]
    procedure GetSalaryRange(RangeNo: Integer): Decimal
    begin
        case RangeNo of
            0:
                exit(5965.1);
            1:
                exit(7400.1);
            2:
                exit(9000.1);
            3:
                exit(10600.1);
            4:
                exit(12200.1);
            5:
                exit(13800.1);
            6:
                exit(15400.1);
            7:
                exit(17000.1);
            8:
                exit(18600.1);
            9:
                exit(21800.1);
            10:
                exit(25000.1);
            11:
                exit(30000.1);
            12:
                exit(35000.1);
            13:
                exit(40000.1);
            14:
                exit(50000.1);
            15:
                exit(75000.1);
            16:
                exit(100000.1);
            17:
                exit(250000.1);
            18:
                exit(500000.1);
            19:
                exit(1000000.1);
        end;
    end;

    [Scope('OnPrem')]
    procedure FillSalaryRange(SummaryAmount: Decimal; var EmployeeStatisticalBuffer: Record "Item Journal Buffer" temporary)
    var
        I: Integer;
    begin
        I := 0;
        repeat
            if SummaryAmount < GetSalaryRange(I) then begin
                UpdateStatisticalLine(I, SummaryAmount, EmployeeStatisticalBuffer);
                exit;
            end;

            I += 1;
        until I > 19;

        UpdateStatisticalLine(20, SummaryAmount, EmployeeStatisticalBuffer);
    end;

    [Scope('OnPrem')]
    procedure GetPlannedHours(EmployeeNo: Code[20]; StartDate: Date; EndDate: Date): Decimal
    var
        TimesheetMgt: Codeunit "Timesheet Management RU";
        HRSetup: Record "Human Resources Setup";
    begin
        HRSetup.Get();
        exit(
          TimesheetMgt.GetTimesheetInfo(
            EmployeeNo, HRSetup."FSN-1 Work Time Group Code", StartDate, EndDate, 1));
    end;

    [Scope('OnPrem')]
    procedure GetActualHours(EmployeeNo: Code[20]; StartDate: Date; EndDate: Date): Decimal
    var
        TimesheetMgt: Codeunit "Timesheet Management RU";
        HRSetup: Record "Human Resources Setup";
    begin
        HRSetup.Get();
        exit(
          TimesheetMgt.GetTimesheetInfo(
            EmployeeNo, HRSetup."FSN-1 Work Time Group Code", StartDate, EndDate, 3));
    end;

    [Scope('OnPrem')]
    procedure SetSilentResponsibleEmployee(Employee: Record Employee)
    begin
        // Function used for testing purposes

        ResponsibleEmployee := Employee;
        EmployeeFullName := ResponsibleEmployee."First Name" + ' ' + ResponsibleEmployee."Middle Name" + ' ' +
          ResponsibleEmployee."Last Name";
    end;

    [Scope('OnPrem')]
    procedure SetSilentFilename(Filename: Text)
    begin
        // Function used for testing purposes

        FileNameSilent := Filename;
    end;

    [Scope('OnPrem')]
    procedure SetSilentEmployeeStatisticalBuffer(var TempItemJournalBufferValue: Record "Item Journal Buffer" temporary)
    var
        I: Integer;
        StatisticalLines: Integer;
    begin
        // Function used for testing purposes

        IsSilentEmpStatisticalBuffer := true;
        StatisticalLines := 21;

        EmployeeStatisticalBuffer.Reset();
        EmployeeStatisticalBuffer.DeleteAll();
        for I := 0 to StatisticalLines + 1 do begin
            TempItemJournalBufferValue.Get(I);
            EmployeeStatisticalBuffer.Init();
            EmployeeStatisticalBuffer.TransferFields(TempItemJournalBufferValue);
            EmployeeStatisticalBuffer.Insert();
        end;
    end;
}

