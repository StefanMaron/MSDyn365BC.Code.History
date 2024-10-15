report 17362 "Salary Reference"
{
    Caption = 'Salary Reference';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Person; Person)
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.";

            trigger OnAfterGetRecord()
            var
                PersonDocument: Record "Person Document";
                CompanyAddr: Record "Company Address";
                LocalReportMgt: Codeunit "Local Report Management";
                CompanyName: Text[100];
                RowNo: Integer;
                StartYear: Integer;
                EndYear: Integer;
            begin
                Employee.SetRange("Person No.", "No.");
                if not Employee.FindFirst then
                    ExcelMgt.ErrorExcelProcessing(StrSubstNo(Text026, "No."));

                EndYear := Date2DMY(DocumentDate, 3);
                StartYear := FindPeriodStartYear("No.", EndYear);

                ExcelMgt.FillCell('C9', Format(DocumentDate));

                ExcelMgt.FillCell('F13', LocalReportMgt.GetCompanyName);
                CompanyAddr.Reset();
                CompanyAddr.SetRange("Address Type", CompanyAddr."Address Type"::"Medical Fund");
                if CompanyAddr.FindFirst then begin
                    CompanyName := CompanyAddr.Name;
                    if CompanyAddr."Name 2" <> '' then
                        CompanyName := CompanyName + ' ' + DelChr(CompanyAddr."Name 2", '<');
                    ExcelMgt.FillCell('A14', CompanyName);
                end;

                ExcelMgt.FillCell('F19', CompanyInfo."FSI Registration No.");
                ExcelMgt.FillCell('E21', CompanyInfo."Social Insurance Code");
                ExcelMgt.FillCell('J21', CompanyInfo."VAT Registration No." + '/' + CompanyInfo."KPP Code");
                ExcelMgt.FillCell('A24', LocalReportMgt.GetLegalAddress);
                ExcelMgt.FillCell('D25', CompanyInfo."Phone No.");
                ExcelMgt.FillCell('E28', Employee.GetFullNameOnDate(DocumentDate));
                Person.GetIdentityDoc(CalcDate('<CY>', DocumentDate), PersonDocument);
                ExcelMgt.FillCell('B30', PersonDocument."Document Series");
                ExcelMgt.FillCell('F30', PersonDocument."Document No.");
                ExcelMgt.FillCell('A31', PersonDocument."Issue Authority" + ' ' + Format(PersonDocument."Issue Date"));
                FillPersonAddrInfo("No.");
                ExcelMgt.FillCell('B38', "Social Security No.");

                RowNo := 40;
                FillPersonJobHistoryInfo("No.", StartYear, EndYear, RowNo);

                RowNo += 2;
                FillSalaryInfo("No.", StartYear, EndYear, RowNo);

                RowNo += 1;
                FillAbsenceInfo("No.", StartYear, EndYear, RowNo);

                RowNo += 3;
                ExcelMgt.FillCell('J' + Format(RowNo), CompanyInfo."Director Name");
                RowNo += 3;
                ExcelMgt.FillCell('J' + Format(RowNo), CompanyInfo."Accountant Name");
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
                    field(DocumentDate; DocumentDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document Date';
                        ToolTip = 'Specifies the creation date of the related document.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            DocumentDate := Today;
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        if not TestMode then
          ExcelMgt.DownloadBook(ExcelTemplate.GetTemplateFileName(HumanResSetup."Salary Reference Template Code"))
        else
          ExcelMgt.CloseBook;
    end;

    trigger OnPreReport()
    begin
        if DocumentDate = 0D then
            Error(Text000);

        HumanResSetup.Get();
        CompanyInfo.Get();

        HumanResSetup.TestField("Salary Reference Template Code");
        FileName := ExcelTemplate.OpenTemplate(HumanResSetup."Salary Reference Template Code");

        ExcelMgt.OpenBookForUpdate(FileName);
        ExcelMgt.OpenSheet('TDSheet');
    end;

    var
        Text000: Label 'Enter Create Date.';
        Text016: Label 'Registration address is missing for employee %1.';
        Text017: Label 'Registration post code is missing for employee %1.';
        Text026: Label 'There is no Employee No. associated with Person No. %1.';
        HumanResSetup: Record "Human Resources Setup";
        CompanyInfo: Record "Company Information";
        ExcelTemplate: Record "Excel Template";
        Employee: Record Employee;
        ExcelMgt: Codeunit "Excel Management";
        DocumentDate: Date;
        FileName: Text[250];
        SalaryRefFormatTxt: Label '%1 (%2)';
        TestMode: Boolean;

    local procedure ChildCareLeaveInPeriodExists(PersonNo: Code[20]; YearNo: Integer): Boolean
    var
        AbsenceEntry: Record "Employee Absence Entry";
    begin
        with AbsenceEntry do begin
            SetCurrentKey("Employee No.", "Time Activity Code", "Entry Type", "Start Date");
            SetRange("Person No.", PersonNo);
            SetRange("Entry Type", "Entry Type"::Usage);
            SetFilter(
              "Sick Leave Type",
              '%1|%2|%3',
              "Sick Leave Type"::"Pregnancy Leave", "Sick Leave Type"::"Child Care 1.5 years", "Sick Leave Type"::"Child Care 3 years");
            SetFilter("Start Date", '<=%1', LastDayOfYear(YearNo));
            SetFilter("End Date", '>=%1', FirstDayOfYear(YearNo));

            exit(not IsEmpty)
        end;
    end;

    local procedure GetEmployeWorkStartYear(PersonNo: Code[20]): Integer
    var
        PersonLabContractDate: Date;
        PersonPreviousJobDate: Date;
    begin
        PersonLabContractDate := GetLaborContractStartDate(PersonNo);
        PersonPreviousJobDate := GetPreviousJobStartDate(PersonNo);

        if PersonPreviousJobDate = 0D then
            exit(Date2DMY(PersonLabContractDate, 3));

        exit(Date2DMY(MinOfTwoDates(PersonLabContractDate, PersonPreviousJobDate), 3));
    end;

    local procedure GetLaborContractStartDate(PersonNo: Code[20]): Date
    var
        LaborContract: Record "Labor Contract";
    begin
        with LaborContract do begin
            SetCurrentKey("Contract Type", "Person No.", "Starting Date");
            SetRange("Contract Type", "Contract Type"::"Labor Contract");
            SetRange("Person No.", PersonNo);
            SetFilter(Status, '%1|%2', Status::Approved, Status::Closed);
            FindFirst;

            exit("Starting Date");
        end;
    end;

    local procedure GetPreviousJobStartDate(PersonNo: Code[20]): Date
    var
        PersonJobHistory: Record "Person Job History";
    begin
        with PersonJobHistory do begin
            SetRange("Person No.", PersonNo);
            if FindFirst then
                exit("Starting Date");

            exit(0D);
        end;
    end;

    local procedure DuplicateExcelLines(FirstRowNo: Integer; LastRowNo: Integer; LineCount: Integer)
    var
        i: Integer;
    begin
        for i := 1 to LineCount do
            ExcelMgt.CopyRowsTo(FirstRowNo, LastRowNo, LastRowNo + 1);
    end;

    local procedure FillAbsenceInfo(PersonNo: Code[20]; StartYear: Integer; EndYear: Integer; var RowNo: Integer)
    var
        PayrollPeriod: Record "Payroll Period";
        PersonExcludedDays: Record "Person Excluded Days";
        DateRec: Record Date;
        ExcludedDaysPerYear: Integer;
        AbsenceLineNo: Integer;
    begin
        DateRec.SetRange("Period Type", DateRec."Period Type"::Year);
        DateRec.SetRange("Period No.", StartYear, EndYear);
        if DateRec.FindSet then begin
            DuplicateExcelLines(RowNo, RowNo + 3, DateRec.Count - 1);

            repeat
                ExcelMgt.FillCell('A' + Format(RowNo), Format(DateRec."Period No."));
                ExcludedDaysPerYear := 0;
                AbsenceLineNo := 0;

                PersonExcludedDays.SetRange("Person No.", PersonNo);
                PersonExcludedDays.SetFilter(
                  "Period Code", '%1..%2',
                  PayrollPeriod.PeriodByDate(DateRec."Period Start"), PayrollPeriod.PeriodByDate(NormalDate(DateRec."Period End")));
                if PersonExcludedDays.Find('+') then
                    repeat
                        AbsenceLineNo += 1;
                        if AbsenceLineNo > 1 then
                            DuplicateExcelLines(RowNo + 2, RowNo + 3, 1);

                        ExcludedDaysPerYear += PersonExcludedDays."Calendar Days";
                        ExcelMgt.FillCell('B' + Format(RowNo + 2), Format(PersonExcludedDays."Absence Starting Date"));
                        ExcelMgt.FillCell('F' + Format(RowNo + 2), Format(PersonExcludedDays."Absence Ending Date"));
                        ExcelMgt.FillCell('J' + Format(RowNo + 2), Format(PersonExcludedDays."Calendar Days"));
                        ExcelMgt.FillCell('M' + Format(RowNo + 2), PersonExcludedDays.Description);
                    until PersonExcludedDays.Next(-1) = 0;

                ExcelMgt.FillCell('E' + Format(RowNo), Format(ExcludedDaysPerYear));
                // Template always contains one line for absence. Need to take take it into account for correct shift calculation.
                if AbsenceLineNo = 0 then
                    AbsenceLineNo := 1;
                RowNo += (AbsenceLineNo + 1) * 2;
            until DateRec.Next = 0;
        end;
    end;

    local procedure FillPersonJobHistoryInfo(PersonNo: Code[20]; StartYear: Integer; EndYear: Integer; var RowNo: Integer)
    var
        JobHistoryBuff: Record "Person Job History" temporary;
    begin
        FillPersonPreviousJobInfo(PersonNo, StartYear, EndYear, JobHistoryBuff);
        FillLaborContractInfo(PersonNo, StartYear, EndYear, JobHistoryBuff);

        JobHistoryBuff.FindSet;
        DuplicateExcelLines(RowNo, RowNo, JobHistoryBuff.Count - 1);
        if JobHistoryBuff.FindSet then
            repeat
                FillJobHistoryDates(RowNo, JobHistoryBuff."Starting Date", JobHistoryBuff."Ending Date");
            until JobHistoryBuff.Next = 0;
    end;

    local procedure FillLaborContractInfo(PersonNo: Code[20]; StartYear: Integer; EndYear: Integer; var JobHistoryBuff: Record "Person Job History" temporary)
    var
        LaborContract: Record "Labor Contract";
        LaborContractLine: Record "Labor Contract Line";
    begin
        LaborContractSetFilter(LaborContract, PersonNo, StartYear, EndYear);
        if LaborContract.FindSet then
            repeat
                LaborContractLine.Reset();
                LaborContractLine.SetRange("Contract No.", LaborContract."No.");
                LaborContractLine.SetRange("Operation Type", LaborContractLine."Operation Type"::Dismissal);
                if LaborContractLine.FindSet then
                    ExcelMgt.FillCell('N9', LaborContract."No.");
                FillJobHistoryBuff(JobHistoryBuff, PersonNo, LaborContract."Starting Date", LaborContract."Ending Date");
            until LaborContract.Next = 0;
    end;

    local procedure FillPersonPreviousJobInfo(PersonNo: Code[20]; StartYear: Integer; EndYear: Integer; var JobHistoryBuff: Record "Person Job History" temporary)
    var
        PersonJobHistory: Record "Person Job History";
    begin
        PersonJobHistory.SetRange("Person No.", PersonNo);
        PersonJobHistory.SetFilter("Starting Date", '<=%1', LastDayOfYear(EndYear));
        PersonJobHistory.SetFilter("Ending Date", '>=%1|=%2', FirstDayOfYear(StartYear), 0D);

        if PersonJobHistory.FindSet then
            repeat
                FillJobHistoryBuff(
                  JobHistoryBuff, PersonNo, PersonJobHistory."Starting Date", PersonJobHistory."Ending Date");
            until PersonJobHistory.Next = 0;
    end;

    local procedure FillJobHistoryBuff(var JobHistoryBuff: Record "Person Job History" temporary; PersonNo: Code[20]; StartingDate: Date; EndingDate: Date)
    begin
        with JobHistoryBuff do begin
            Init;
            "Person No." := PersonNo;
            "Starting Date" := StartingDate;
            "Ending Date" := EndingDate;
            Insert;
        end;
    end;

    local procedure FillJobHistoryDates(var RowNo: Integer; StartingDate: Date; EndingDate: Date)
    begin
        ExcelMgt.FillCell('B' + Format(RowNo), Format(StartingDate));
        ExcelMgt.FillCell('G' + Format(RowNo), Format(EndingDate));
        RowNo += 1;
    end;

    [Scope('OnPrem')]
    procedure FillPersonAddrInfo(PersonNo: Code[20])
    var
        AltAddr: Record "Alternative Address";
    begin
        AltAddr.Reset();
        AltAddr.SetRange("Person No.", PersonNo);
        AltAddr.SetRange("Address Type", AltAddr."Address Type"::Registration);
        if AltAddr.FindLast then begin
            if AltAddr."Post Code" <> '' then
                ExcelMgt.FillCell('D34', AltAddr."Post Code")
            else
                ExcelMgt.ErrorExcelProcessing(StrSubstNo(Text017, GetEmployeeByPersonNo(PersonNo)));
            if AltAddr."KLADR Code" <> '' then begin
                ExcelMgt.FillCell('A35', AltAddr.Region);
                ExcelMgt.FillCell('F35', AltAddr.City);
                ExcelMgt.FillCell('A36', AltAddr.Street);
                ExcelMgt.FillCell('H36', AltAddr.House);
                ExcelMgt.FillCell('K36', AltAddr.Building);
                ExcelMgt.FillCell('N36', AltAddr.Apartment);
            end;
        end else
            ExcelMgt.ErrorExcelProcessing(StrSubstNo(Text016, GetEmployeeByPersonNo(PersonNo)));
    end;

    [Scope('OnPrem')]
    procedure FillSalaryInfo(PersonNo: Code[20]; StartYear: Integer; EndYear: Integer; var RowNo: Integer)
    var
        PersonIncomeFSI: Record "Person Income FSI";
        DateRec: Record Date;
        LocMgt: Codeunit "Localisation Management";
        AddShift: Integer;
    begin
        DateRec.SetRange("Period Type", DateRec."Period Type"::Year);
        DateRec.SetRange("Period No.", StartYear, EndYear);
        if DateRec.FindSet then begin
            if DateRec.Count > 3 then
                DuplicateExcelLines(RowNo, RowNo + 1, DateRec.Count - 3)
            else
                AddShift := (3 - DateRec.Count) * 2;

            repeat
                PersonIncomeFSI.Reset();
                PersonIncomeFSI.SetCurrentKey("Person No.", Year);
                PersonIncomeFSI.SetRange("Person No.", PersonNo);
                PersonIncomeFSI.SetRange(Year, DateRec."Period No.");
                PersonIncomeFSI.CalcSums(Amount);
                ExcelMgt.FillCell('A' + Format(RowNo), Format(DateRec."Period No."));
                ExcelMgt.FillCell(
                  'E' + Format(RowNo),
                  StrSubstNo(SalaryRefFormatTxt, Format(PersonIncomeFSI.Amount), LocMgt.Amount2Text('', PersonIncomeFSI.Amount)));
                RowNo += 2;
            until DateRec.Next = 0;

            RowNo += AddShift;
        end;
    end;

    local procedure FindPeriodStartYear(PersonNo: Code[20]; EndYear: Integer): Integer
    var
        FullYearsCount: Integer;
        Year: Integer;
        WorkStartYear: Integer;
        PeriodFound: Boolean;
    begin
        WorkStartYear := GetEmployeWorkStartYear(PersonNo);

        Year := EndYear;
        repeat
            if WorkYearWithoutChildCareLeave(PersonNo, Year) then
                FullYearsCount += 1;

            PeriodFound := (FullYearsCount = 3) or (Year = WorkStartYear);
            if not PeriodFound then
                Year -= 1;
        until PeriodFound;

        exit(Year);
    end;

    local procedure FirstDayOfYear(YearNo: Integer): Date
    var
        DateRec: Record Date;
    begin
        DateRec.SetRange("Period Type", DateRec."Period Type"::Year);
        DateRec.SetRange("Period No.", YearNo);
        DateRec.FindFirst;
        exit(DateRec."Period Start");
    end;

    local procedure GetEmployeeByPersonNo(PersonNo: Code[20]): Code[20]
    var
        Employee: Record Employee;
    begin
        Employee.SetRange("Person No.", PersonNo);
        Employee.FindFirst;
        exit(Employee."No.");
    end;

    local procedure LastDayOfYear(YearNo: Integer): Date
    var
        DateRec: Record Date;
    begin
        DateRec.SetRange("Period Type", DateRec."Period Type"::Year);
        DateRec.SetRange("Period No.", YearNo);
        DateRec.FindFirst;
        exit(NormalDate(DateRec."Period End"));
    end;

    local procedure MinOfTwoDates(Date1: Date; Date2: Date): Date
    begin
        if Date1 < Date2 then
            exit(Date1);

        exit(Date2);
    end;

    local procedure WorkYearWithoutChildCareLeave(PersonNo: Code[20]; YearNo: Integer): Boolean
    begin
        exit(not ChildCareLeaveInPeriodExists(PersonNo, YearNo));
    end;

    local procedure LaborContractSetFilter(var LaborContract: Record "Labor Contract"; PersonNo: Code[20]; StartYear: Integer; EndYear: Integer)
    begin
        with LaborContract do begin
            SetCurrentKey("Contract Type", "Person No.", "Starting Date");
            SetRange("Contract Type", "Contract Type"::"Labor Contract");
            SetRange("Person No.", PersonNo);
            SetFilter("Starting Date", '<=%1', LastDayOfYear(EndYear));
            SetFilter("Ending Date", '>=%1|=%2', FirstDayOfYear(StartYear), 0D);
        end;
    end;

    [Scope('OnPrem')]
    procedure SetTestMode(NewTestMode: Boolean)
    begin
        TestMode := NewTestMode;
    end;
}

