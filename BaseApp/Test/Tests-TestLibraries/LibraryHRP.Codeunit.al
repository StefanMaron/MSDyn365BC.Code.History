codeunit 143012 "Library - HRP"
{

    trigger OnRun()
    begin
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";

    [Scope('OnPrem')]
    procedure CalcPayrollPeriodCodeByDate(Date: Date): Code[10]
    begin
        exit(Format(Date, 0, '<Year><Month,2>'));
    end;

    [Scope('OnPrem')]
    procedure CancelLaborContractLine(var LaborContractLine: Record "Labor Contract Line")
    var
        LaborContractMgt: Codeunit "Labor Contract Management";
    begin
        LaborContractMgt.UndoApproval(LaborContractLine);
    end;

    [Scope('OnPrem')]
    procedure ChangeOrgUnitStatus(OrgUnitCode: Code[10]; NewStatus: Option Open,Approved,Closed; IsChangeOrder: Boolean)
    var
        OrgUnit: Record "Organizational Unit";
    begin
        with OrgUnit do begin
            Get(OrgUnitCode);
            case NewStatus of
                NewStatus::Open:
                    Reopen(IsChangeOrder);
                NewStatus::Approved:
                    Approve(IsChangeOrder);
                NewStatus::Closed:
                    Close(IsChangeOrder);
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure ClearupJournal(TemplateName: Code[10]; BatchName: Code[10])
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.SetRange("Journal Template Name", TemplateName);
        GenJnlLine.SetRange("Journal Batch Name", BatchName);
        if not GenJnlLine.IsEmpty() then
            GenJnlLine.DeleteAll(true);
    end;

    [Scope('OnPrem')]
    procedure CopyPosition(var Position: Record Position; StartDate: Date; PositionNoCopyFrom: Code[20]; BaseSalary: Decimal)
    var
        PositionNo: Code[20];
    begin
        Position.Get(PositionNoCopyFrom);
        PositionNo := Position.CopyPosition(StartDate);
        Position.Get(PositionNo);
        Position.Validate("Base Salary", BaseSalary);
        Position.Approve(true);
    end;

    [Scope('OnPrem')]
    procedure CreateAbsenceHeader(var AbsenceHeader: Record "Absence Header"; DocumentType: Option; DocumentDate: Date; EmployeeNo: Code[20])
    var
        PayrollPeriod: Record "Payroll Period";
    begin
        with AbsenceHeader do begin
            Init;
            "Document Type" := DocumentType;
            Insert(true);
            Validate("Document Date", DocumentDate);
            Validate("Posting Date", "Document Date");
            "Period Code" :=
              PayrollPeriod.PeriodByDate("Posting Date");
            Validate("Employee No.", EmployeeNo);
            "HR Order No." := "No.";
            "HR Order Date" := "Document Date";
            Modify(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateAbsenceLine(var AbsenceLine: Record "Absence Line"; AbsenceHeader: Record "Absence Header"; TimeActivityCode: Code[10]; ElementCode: Code[20]; StartDate: Date; EndDate: Date)
    begin
        with AbsenceLine do begin
            Init;
            "Document Type" := AbsenceHeader."Document Type";
            "Document No." := AbsenceHeader."No.";
            "Line No." := 10000;
            Insert(true);
            Validate("Time Activity Code", TimeActivityCode);
            if ElementCode <> '' then
                Validate("Element Code", ElementCode);
            Validate("Start Date", StartDate);
            Validate("End Date", EndDate);
            Modify(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateAlternativeAddress(var AlternativeAddress: Record "Alternative Address"; PersonNo: Code[20]; StartingDate: Date; AddressType: Option)
    var
        PostCode: Record "Post Code";
    begin
        with AlternativeAddress do begin
            Init;
            Validate("Person No.", PersonNo);
            Validate("Address Type", AddressType);
            Validate("Valid from Date", StartingDate);
            Validate(Code, LibraryUtility.GenerateGUID);
            LibraryERM.CreatePostCode(PostCode);
            Validate("Country/Region Code", PostCode."Country/Region Code");
            Validate("Post Code", PostCode.Code);
            Validate(City, PostCode.City);
            "KLADR Code" := '770000000001';
            "Region Code" := '77';
            Insert(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateAndPostPayrollDoc(EmployeeNo: Code[20]; PayrollPeriodCode: Code[10]; CalcGroupCode: Code[10]; CalcDate: Date)
    begin
        CreatePayrollDoc(EmployeeNo, PayrollPeriodCode, CalcGroupCode, CalcDate);
        PostPayrollDoc(EmployeeNo, CalcDate);
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure CreateEmplJnlLineExtended(var EmplJnlLine: Record "Employee Journal Line"; HROrderDate: Date; HROrderNo: Code[20]; DocumentNo: Code[20]; EmployeeNo: Code[20]; ElementCode: Code[20]; StartDate: Date; EndDate: Date; JnlAmount: Decimal; WagePeriodFrom: Code[10]; WagePeriodTo: Code[10]; Post: Boolean)
    var
        EmplJournalTemplate: Record "Employee Journal Template";
        EmplJournalBatch: Record "Employee Journal Batch";
        EmployeeJournalPostLine: Codeunit "Employee Journal - Post Line";
        LineNo: Integer;
    begin
        FindEmplJnlTemplate(EmplJournalTemplate);
        FindEmplJnlBatch(EmplJournalBatch, EmplJournalTemplate.Name);
        with EmplJnlLine do begin
            SetRange("Journal Template Name", EmplJournalTemplate.Name);
            SetRange("Journal Batch Name", EmplJournalBatch.Name);
            if FindLast then;
            LineNo := "Line No." + 10000;

            Init;
            Validate("Journal Template Name", EmplJournalTemplate.Name);
            Validate("Journal Batch Name", EmplJournalBatch.Name);
            "Line No." := LineNo;
            Validate("Document No.", DocumentNo);
            Validate("Employee No.", EmployeeNo);
            Validate("Element Code", ElementCode);
            Validate("Posting Date", HROrderDate);
            Validate("Starting Date", StartDate);
            Validate("Ending Date", EndDate);
            Validate("HR Order No.", HROrderNo);
            Validate("HR Order Date", HROrderDate);
            Validate("Wage Period From", WagePeriodFrom);
            Validate("Wage Period To", WagePeriodTo);
            Validate(Amount, JnlAmount);

            if Post then
                EmployeeJournalPostLine.RunWithCheck(EmplJnlLine)
            else
                Insert(true);
        end;
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure CreateEmplJnlLine(var EmplJnlLine: Record "Employee Journal Line"; PayrollPeriod: Record "Payroll Period"; EmployeeNo: Code[20]; ElementCode: Code[20]; Amount: Decimal; PostingDate: Date; Post: Boolean)
    begin
        CreateEmplJnlLineExtended(
          EmplJnlLine,
          PostingDate,
          LibraryUtility.GenerateGUID,
          LibraryUtility.GenerateGUID,
          EmployeeNo,
          ElementCode,
          PayrollPeriod."Starting Date",
          PayrollPeriod."Ending Date",
          Amount,
          PayrollPeriod.Code,
          PayrollPeriod.Code,
          Post);
    end;

    [Scope('OnPrem')]
    procedure CreateIdentityDoc(PersonNo: Code[20]; DocType: Code[2]; ValidFromDate: Date)
    var
        PersonDoc: Record "Person Document";
    begin
        with PersonDoc do begin
            Init;
            "Person No." := PersonNo;
            "Document Type" := DocType;
            "Valid from Date" := ValidFromDate;
            "Document No." :=
              LibraryUtility.GenerateRandomCode(FieldNo("Document No."), DATABASE::"Person Document");
            "Issue Authority" :=
              LibraryUtility.GenerateRandomCode(FieldNo("Issue Authority"), DATABASE::"Person Document");
            "Issue Date" := CalcDate('<-10Y>', WorkDate);
            Insert;
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateLaborContractHire(var LaborContract: Record "Labor Contract"; PersonNo: Code[20]; StartDate: Date; PositionNo: Code[20]; UninterruptedService: Boolean; InsuredService: Boolean)
    var
        LaborContractLine: Record "Labor Contract Line";
        LaborContractMgt: Codeunit "Labor Contract Management";
    begin
        LaborContract.Init();
        LaborContract.Insert(true);
        LaborContract.Validate("Person No.", PersonNo);
        LaborContract.Validate("Starting Date", StartDate);
        LaborContract.Validate("Uninterrupted Service", UninterruptedService);
        LaborContract.Validate("Insured Service", InsuredService);
        LaborContract.Modify();

        LaborContractLine.Init();
        LaborContractLine."Contract No." := LaborContract."No.";
        LaborContractLine."Operation Type" := LaborContractLine."Operation Type"::Hire;
        LaborContractLine.Validate("Starting Date", StartDate);
        LaborContractLine.Validate("Position No.", PositionNo);
        LaborContractLine.Insert(true);

        LaborContractMgt.CreateContractTerms(LaborContractLine, true);
        LaborContractMgt.DoApprove(LaborContractLine);

        LaborContract.Find;
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure CreateNewEmployee(StartDate: Date; BaseSalary: Decimal): Code[20]
    var
        PositionCopyFrom: Record Position;
        Position: Record Position;
        Person: Record Person;
        LaborContract: Record "Labor Contract";
    begin
        PositionCopyFrom.FindFirst;
        // copy position
        CopyPosition(Position, StartDate, PositionCopyFrom."No.", BaseSalary);

        // create new person
        CreatePerson(Person);

        // create hire labor contract
        CreateLaborContractHire(LaborContract, Person."No.", StartDate, Position."No.", false, false);

        exit(LaborContract."Employee No.");
    end;

    local procedure CreateOKINCode(GroupCode: Code[10]): Code[10]
    var
        ClassificatorOKIN: Record "Classificator OKIN";
    begin
        ClassificatorOKIN.Init();
        ClassificatorOKIN.Validate(Group, GroupCode);
        ClassificatorOKIN.Code := LibraryUtility.GenerateRandomCode(ClassificatorOKIN.FieldNo(Code), DATABASE::"Classificator OKIN");
        ClassificatorOKIN.Name := ClassificatorOKIN.Code;
        ClassificatorOKIN.Insert(true);
        exit(ClassificatorOKIN.Code);
    end;

    [Scope('OnPrem')]
    procedure CreateOrgUnit(StartingDate: Date; OrgUnitType: Option): Code[10]
    var
        OrgUnit: Record "Organizational Unit";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        with OrgUnit do begin
            Init;
            Validate(Code, LibraryUtility.GenerateRandomCode(FieldNo(Code), DATABASE::"Organizational Unit"));
            Validate(Name, LibraryUtility.GenerateRandomCode(FieldNo(Name), DATABASE::"Organizational Unit"));
            Validate("Starting Date", StartingDate);
            Validate(Type, OrgUnitType);
            Insert(true);
        end;
        exit(OrgUnit.Code);
    end;

    [Scope('OnPrem')]
    procedure CreateOtherAbsenceOrder(EmployeeNo: Code[20]; OrderDate: Date; StartDate: Date; EndDate: Date; TimeActivityCode: Code[10]; ElementCode: Code[20]; Post: Boolean)
    var
        AbsenceHeader: Record "Absence Header";
        AbsenceLine: Record "Absence Line";
    begin
        CreateAbsenceHeader(AbsenceHeader, AbsenceHeader."Document Type"::"Other Absence", OrderDate, EmployeeNo);
        CreateAbsenceLine(AbsenceLine, AbsenceHeader, TimeActivityCode, ElementCode, StartDate, EndDate);

        if Post then
            CODEUNIT.Run(CODEUNIT::"Absence Order-Post", AbsenceHeader);
    end;

    [Scope('OnPrem')]
    procedure CreatePerson(var Person: Record Person)
    var
        AlternativeAddress: Record "Alternative Address";
        PersonVendorUpdate: Codeunit "Person\Vendor Update";
    begin
        with Person do begin
            Insert(true);
            Validate("First Name", "No.");
            Validate("Middle Name", "No.");
            Validate("Last Name", "No.");
            Validate("Birth Date", 19700101D);
            Validate(Citizenship, CreateOKINCode('02'));
            Validate("Identity Document Type", FindIdentityDocType);
            CreateIdentityDoc("No.", "Identity Document Type", "Birth Date");
            CreateAlternativeAddress(AlternativeAddress, "No.", "Birth Date", AlternativeAddress."Address Type"::Birthplace);
            CreateAlternativeAddress(AlternativeAddress, "No.", "Birth Date", AlternativeAddress."Address Type"::Registration);
            Gender := Gender::Female;
            "VAT Registration No." := LibraryERM.GenerateVATRegistrationNo(AlternativeAddress."Country/Region Code");
            "Citizenship Country/Region" := AlternativeAddress."Country/Region Code";
            Modify;
            PersonVendorUpdate.CreateVendor(Person);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreatePersonIncomeFSI(PersonNo: Code[20]; PeriodCode: Code[10]; IncomeAmount: Decimal)
    var
        PersonIncomeFSI: Record "Person Income FSI";
    begin
        with PersonIncomeFSI do begin
            Init;
            "Person No." := PersonNo;
            Validate("Period Code", PeriodCode);
            Validate(Amount, IncomeAmount);
            Insert;
        end;
    end;

    [Scope('OnPrem')]
    procedure CreatePersonMedicalInfo(var PersonMedicalInfo: Record "Person Medical Info"; PersonNo: Code[20]; MedicalType: Option; MedicalPrivilege: Option; DisabilityGroup: Option; StartDate: Date)
    begin
        with PersonMedicalInfo do begin
            Init;
            "Person No." := PersonNo;
            Type := MedicalType;
            Privilege := MedicalPrivilege;
            "Starting Date" := StartDate;
            "Disability Group" := DisabilityGroup;
            Insert(true);
        end;
    end;

    local procedure CreatePayrollCalendar(CalendarCode: Code[10]; PeriodEndDate: Date)
    var
        PayrollCalendarLine: Record "Payroll Calendar Line";
        CreateCalendarLine: Report "Create Calendar Line";
        YearStartDate: Date;
        YearEndDate: Date;
    begin
        if not PayrollCalendarLine.Get(CalendarCode, PeriodEndDate) then begin
            YearStartDate := CalcDate('<-CY>', PeriodEndDate);
            YearEndDate := CalcDate('<CY>', PeriodEndDate);
            CreateCalendarLine.SetCalendar(CalendarCode, YearStartDate, YearEndDate, false);
            CreateCalendarLine.Run;
            PayrollCalendarLine.SetRange("Calendar Code", CalendarCode);
            PayrollCalendarLine.SetRange(Date, YearStartDate, YearEndDate);
            PayrollCalendarLine.ModifyAll(Status, PayrollCalendarLine.Status::Released);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreatePayrollCalendarHeader(): Code[10]
    var
        PayrollCalendarHeader: Record "Payroll Calendar";
        CalendarCode: Code[10];
    begin
        with PayrollCalendarHeader do begin
            CalendarCode := LibraryUtility.GenerateRandomCode(FieldNo(Code), DATABASE::"Payroll Calendar");
            Init;
            Code := CalendarCode;
            Name := CalendarCode;
            Insert(true);
            exit(CalendarCode);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreatePayrollCalcType(ElementCode: Text; UseInCalc: Option; var PayrollCalcType: Record "Payroll Calc Type"): Code[20]
    var
        PayrollCalcTypeLine: Record "Payroll Calc Type Line";
        RecRef: RecordRef;
        MaxPriority: Integer;
    begin
        with PayrollCalcType do begin
            SetCurrentKey(Priority);
            FindLast;
            MaxPriority := Priority;
            Init;
            Code := LibraryUtility.GenerateGUID;
            "Use in Calc" := UseInCalc;
            Priority := MaxPriority + 1;
            Insert;
        end;

        with PayrollCalcTypeLine do begin
            Init;
            "Calc Type Code" := PayrollCalcType.Code;
            Validate("Element Code", ElementCode);
            Activity := true;
            RecRef.GetTable(PayrollCalcTypeLine);
            "Line No." := LibraryUtility.GetNewLineNo(RecRef, FieldNo("Line No."));
            Calculate := true;
            Insert;
        end;

        exit(PayrollCalcType.Code);
    end;

    [Scope('OnPrem')]
    procedure CreatePayrollDoc(EmployeeNo: Code[20]; PayrollPeriodCode: Code[10]; CalcGroupCode: Code[10]; CalcDate: Date)
    var
        Employee: Record Employee;
        SuggestPayrollDocuments: Report "Suggest Payroll Documents";
    begin
        SuggestPayrollDocuments.Set(PayrollPeriodCode, CalcGroupCode, CalcDate, true);
        Employee.SetRange("No.", EmployeeNo);
        SuggestPayrollDocuments.SetTableView(Employee);
        SuggestPayrollDocuments.UseRequestPage(false);
        SuggestPayrollDocuments.Run;
    end;

    [Scope('OnPrem')]
    procedure CreatePayrollPeriodsUntil(UntilDate: Date)
    var
        PayrollPeriod: Record "Payroll Period";
    begin
        PayrollPeriod.FindLast;
        if UntilDate > PayrollPeriod."Ending Date" then
            CreatePayrollPeriods(PayrollPeriod."Ending Date" + 1, UntilDate);
    end;

    [Scope('OnPrem')]
    procedure CreatePayrollPeriods(StartDate: Date; EndDate: Date)
    var
        PayrollPeriod: Record "Payroll Period";
        Date: Record Date;
        PeriodCode: Code[10];
    begin
        Date.SetRange("Period Type", Date."Period Type"::Month);
        Date.SetRange("Period Start", StartDate, EndDate);
        Date.FindSet();
        repeat
            PeriodCode := Format(Date."Period Start", 0, '<Year><Month,2>');
            if not PayrollPeriod.Get(PeriodCode) then
                InsertPayrollPeriod(PeriodCode, Date."Period Start");
        until Date.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure CreateRelativePerson(PersonNo: Code[20]; RelativeCode: Code[10]; BirthDate: Date; RelationStartDate: Date): Code[20]
    var
        Person: Record Person;
        EmployeeRelative: Record "Employee Relative";
        LineNo: Integer;
    begin
        EmployeeRelative.SetRange("Person No.", PersonNo);
        if EmployeeRelative.FindLast then;
        LineNo := EmployeeRelative."Line No." + 10000;

        Person.Init();
        Person.Insert(true);
        Person.Validate("First Name", RelativeCode);
        Person.Validate("Last Name", Person."No.");
        Person.Validate("Birth Date", BirthDate);
        Person.Gender := Person.Gender::Female;
        Person.Modify();

        EmployeeRelative.Init();
        EmployeeRelative."Person No." := PersonNo;
        EmployeeRelative."Line No." := LineNo;
        EmployeeRelative."Relative Code" := RelativeCode;
        EmployeeRelative."Birth Date" := BirthDate;
        EmployeeRelative."Relation Start Date" := RelationStartDate;
        EmployeeRelative."Relative Person No." := Person."No.";
        EmployeeRelative.Insert();

        exit(EmployeeRelative."Relative Person No.");
    end;

    [Scope('OnPrem')]
    procedure CreateSickLeaveOrder(EmployeeNo: Code[20]; OrderDate: Date; StartDate: Date; EndDate: Date; TimeActivityCode: Code[10]; RelativePersonNo: Code[20]; PaymentPercent: Decimal; TreatmentType: Option " ","Out-Patient","In-Patient"; Post: Boolean)
    var
        PayrollPeriod: Record "Payroll Period";
        AbsenceHeader: Record "Absence Header";
        AbsenceLine: Record "Absence Line";
    begin
        with AbsenceHeader do begin
            Init;
            "Document Type" := "Document Type"::"Sick Leave";
            Insert(true);
            Validate("Document Date", OrderDate);
            Validate("Posting Date", "Document Date");
            "Period Code" :=
              PayrollPeriod.PeriodByDate("Posting Date");
            Validate("Employee No.", EmployeeNo);
            "HR Order No." := "No.";
            "HR Order Date" := "Document Date";
            Modify(true);
        end;
        with AbsenceLine do begin
            Init;
            "Document Type" := AbsenceHeader."Document Type";
            "Document No." := AbsenceHeader."No.";
            "Line No." := 10000;
            Insert(true);
            Validate("Time Activity Code", TimeActivityCode);
            "Relative Person No." := RelativePersonNo;
            Validate("Payment Percent", PaymentPercent);
            Validate("Treatment Type", TreatmentType);
            Validate("Start Date", StartDate);
            Validate("End Date", EndDate);
            Modify(true);
        end;

        if Post then
            CODEUNIT.Run(CODEUNIT::"Absence Order-Post", AbsenceHeader);
    end;

    [Scope('OnPrem')]
    procedure CreateTimeActivityGroup(var TimeActivityGroup: Record "Time Activity Group")
    begin
        TimeActivityGroup.Code := LibraryUtility.GenerateRandomCode(TimeActivityGroup.FieldNo(Code), DATABASE::"Time Activity Group");
        TimeActivityGroup.Insert();
    end;

    [Scope('OnPrem')]
    procedure CreateTravelOrder(EmployeeNo: Code[20]; OrderDate: Date; StartDate: Date; EndDate: Date; TimeActivityCode: Code[10]; Post: Boolean)
    var
        AbsenceHeader: Record "Absence Header";
        AbsenceLine: Record "Absence Line";
    begin
        CreateAbsenceHeader(AbsenceHeader, AbsenceHeader."Document Type"::Travel, OrderDate, EmployeeNo);
        AbsenceHeader."Travel Destination" := '-';
        AbsenceHeader."Travel Purpose" := '-';
        AbsenceHeader."Travel Reason Document" := '-';
        AbsenceHeader.Modify(true);

        CreateAbsenceLine(AbsenceLine, AbsenceHeader, TimeActivityCode, '', StartDate, EndDate);

        if Post then
            CODEUNIT.Run(CODEUNIT::"Absence Order-Post", AbsenceHeader);
    end;

    [Scope('OnPrem')]
    procedure CreateVacationRequest(EmployeeNo: Code[20]; TimeActivityCode: Code[10]; RequestDate: Date; StartDate: Date; EndDate: Date; Approve: Boolean): Code[20]
    var
        VacationRequest: Record "Vacation Request";
    begin
        with VacationRequest do begin
            Insert(true);
            Validate("Employee No.", EmployeeNo);
            Validate("Request Date", RequestDate);
            Validate("Start Date", StartDate);
            Validate("End Date", EndDate);
            Validate("Time Activity Code", TimeActivityCode);
            "Scheduled Year" := Date2DMY("Start Date", 3);
            "Scheduled Start Date" := "Start Date";
            Modify;
        end;

        if Approve then
            VacationRequest.Approve;

        exit(VacationRequest."No.");
    end;

    [Scope('OnPrem')]
    procedure CreateVacationOrder(EmployeeNo: Code[20]; OrderDate: Date; StartDate: Date; EndDate: Date; TimeActivityCode: Code[10]; VacationRequestNo: Code[20]; PaymentPercent: Decimal; Post: Boolean)
    var
        TimeActivity: Record "Time Activity";
        AbsenceHeader: Record "Absence Header";
        AbsenceLine: Record "Absence Line";
    begin
        CreateAbsenceHeader(AbsenceHeader, AbsenceHeader."Document Type"::Vacation, OrderDate, EmployeeNo);
        CreateAbsenceLine(AbsenceLine, AbsenceHeader, TimeActivityCode, '', StartDate, EndDate);

        TimeActivity.Get(TimeActivityCode);
        if (AbsenceLine."Document Type" = AbsenceLine."Document Type"::Vacation) and TimeActivity."Use Accruals" then
            AbsenceLine.Validate("Vacation Request No.", VacationRequestNo);
        if PaymentPercent <> 0 then
            AbsenceLine.Validate("Payment Percent", PaymentPercent);
        AbsenceLine.Modify(true);

        if Post then
            CODEUNIT.Run(CODEUNIT::"Absence Order-Post", AbsenceHeader);
    end;

    [Scope('OnPrem')]
    procedure CreateVacation(EmployeeNo: Code[20]; TimeActivityCode: Code[10]; RequestDate: Date; StartDate: Date; EndDate: Date)
    var
        VacationRequestNo: Code[20];
    begin
        // function creates and posts vacation request and vacation order
        VacationRequestNo := CreateVacationRequest(EmployeeNo, TimeActivityCode, RequestDate, StartDate, EndDate, true);
        CreateVacationOrder(EmployeeNo, RequestDate, StartDate, EndDate, TimeActivityCode, VacationRequestNo, 0, true);
    end;

    [Scope('OnPrem')]
    procedure DismissEmployee(EmployeeNo: Code[20]; DismissalDate: Date; DismissalReason: Code[10]; Approve: Boolean)
    var
        Employee: Record Employee;
        LaborContract: Record "Labor Contract";
        LaborContractLine: Record "Labor Contract Line";
        LaborContractMgt: Codeunit "Labor Contract Management";
    begin
        Employee.Get(EmployeeNo);
        LaborContract.Get(Employee."Contract No.");
        LaborContract.Validate("Ending Date", DismissalDate);
        LaborContract.Modify();

        LaborContractLine."Contract No." := LaborContract."No.";
        LaborContractLine.Validate("Operation Type", LaborContractLine."Operation Type"::Dismissal);
        LaborContractLine.Validate("Dismissal Reason", DismissalReason);
        LaborContractLine.Insert(true);

        if Approve then
            LaborContractMgt.DoApprove(LaborContractLine);
    end;

    [Scope('OnPrem')]
    procedure FillEmployeeTimeSheet(EmployeeNo: Code[20]; StartDate: Date; EndDate: Date; TimeActivityCode: Code[10]; Hours: Decimal)
    var
        TimesheetDetail: Record "Timesheet Detail";
        TimesheetLine: Record "Timesheet Line";
    begin
        TimesheetLine.SetRange("Calendar Code", GetDefaultCalendarCode);
        TimesheetLine.SetRange("Employee No.", EmployeeNo);
        TimesheetLine.SetRange(Date, StartDate, EndDate);
        if TimesheetLine.FindSet then begin
            TimesheetDetail.SetRange("Employee No.", EmployeeNo);
            TimesheetDetail.SetRange(Date, StartDate, EndDate);
            TimesheetDetail.DeleteAll();

            repeat
                TimesheetDetail."Employee No." := EmployeeNo;
                TimesheetDetail.Date := TimesheetLine.Date;
                TimesheetDetail."Calendar Code" := GetDefaultCalendarCode;
                TimesheetDetail.Validate("Time Activity Code", TimeActivityCode);
                TimesheetDetail.Validate("Actual Hours", Hours);
                TimesheetDetail.Insert(true);
            until TimesheetLine.Next = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure FindAdvancePayrollCalcGroupCode(): Code[10]
    var
        PayrollCalcGroup: Record "Payroll Calc Group";
    begin
        with PayrollCalcGroup do begin
            SetRange("Disabled Persons", false);
            SetRange(Type, Type::Between);
            FindFirst;
            exit(Code);
        end;
    end;

    [Scope('OnPrem')]
    procedure FindBusTravelTimeActivityCode(): Code[10]
    var
        TimeActivity: Record "Time Activity";
    begin
        with TimeActivity do begin
            SetRange("Time Activity Type", "Time Activity Type"::Travel);
            SetFilter("Element Code", '<>%1', '');
            FindFirst;
            exit(Code);
        end;
    end;

    local procedure FindCalendarDay(PayrollPeriod: Record "Payroll Period"; NonWorkingDay: Boolean): Date
    var
        PayrollCalendarLine: Record "Payroll Calendar Line";
    begin
        with PayrollCalendarLine do begin
            SetRange("Calendar Code", GetDefaultCalendarCode);
            SetRange(Nonworking, NonWorkingDay);
            SetRange(Date, PayrollPeriod."Starting Date", PayrollPeriod."Ending Date");
            FindFirst;
            exit(Date);
        end;
    end;

    [Scope('OnPrem')]
    procedure FindChildCare1_5YearsTimeActivityCode(): Code[10]
    var
        TimeActivity: Record "Time Activity";
    begin
        exit(FindSickLeaveTimeActivityCode(TimeActivity."Sick Leave Type"::"Child Care 1.5 years"));
    end;

    [Scope('OnPrem')]
    procedure FindCommonDiseaseTimeActivityCode(): Code[10]
    var
        TimeActivity: Record "Time Activity";
    begin
        exit(FindSickLeaveTimeActivityCode(TimeActivity."Sick Leave Type"::"Common Disease"));
    end;

    [Scope('OnPrem')]
    procedure FindEducationVacationTimeActivityCode(): Code[10]
    var
        TimeActivity: Record "Time Activity";
    begin
        exit(FindVacationTimeActivityCode(TimeActivity."Vacation Type"::Education));
    end;

    [Scope('OnPrem')]
    procedure FindEmployeeCategoryCode(): Code[10]
    var
        EmployeeCategory: Record "Employee Category";
    begin
        EmployeeCategory.FindFirst;
        exit(EmployeeCategory.Code);
    end;

    [Scope('OnPrem')]
    procedure FindEmplJnlBatch(var EmplJournalBatch: Record "Employee Journal Batch"; JournalTemplateName: Code[10])
    begin
        EmplJournalBatch.SetRange("Journal Template Name", JournalTemplateName);
        EmplJournalBatch.FindFirst;
    end;

    [Scope('OnPrem')]
    procedure FindEmplJnlTemplate(var EmplJournalTemplate: Record "Employee Journal Template")
    begin
        EmplJournalTemplate.FindFirst;
    end;

    [Scope('OnPrem')]
    procedure FindFamilyMemberCareSickLeaveTimeActivityCode(): Code[10]
    var
        TimeActivity: Record "Time Activity";
    begin
        exit(FindSickLeaveTimeActivityCode(TimeActivity."Sick Leave Type"::"Family Member Care"));
    end;

    [Scope('OnPrem')]
    procedure FindFirstWorkingDate(PayrollPeriod: Record "Payroll Period"): Date
    begin
        exit(FindCalendarDay(PayrollPeriod, false));
    end;

    [Scope('OnPrem')]
    procedure FindFirstNonWorkingDate(PayrollPeriod: Record "Payroll Period"): Date
    begin
        exit(FindCalendarDay(PayrollPeriod, true));
    end;

    [Scope('OnPrem')]
    procedure FindGroundOfTerminationCode(): Code[10]
    var
        GroundsForTermination: Record "Grounds for Termination";
    begin
        GroundsForTermination.SetFilter("Element Code", '<>%1', '');
        GroundsForTermination.FindFirst;
        exit(GroundsForTermination.Code);
    end;

    [Scope('OnPrem')]
    procedure FindIdentityDocType(): Code[2]
    var
        TaxpayerDocumentType: Record "Taxpayer Document Type";
    begin
        TaxpayerDocumentType.FindFirst;
        exit(TaxpayerDocumentType.Code);
    end;

    [Scope('OnPrem')]
    procedure FindNonPaidAbsenceTimeActivityCode(): Code[10]
    var
        TimeActivity: Record "Time Activity";
    begin
        with TimeActivity do begin
            SetRange("Time Activity Type", "Time Activity Type"::Other);
            SetRange("Paid Activity", false);
            SetRange("Allow Override", true);
            FindFirst;
            exit(Code);
        end;
    end;

    [Scope('OnPrem')]
    procedure FindOrgUnitCode(): Code[10]
    var
        OrganizationalUnit: Record "Organizational Unit";
    begin
        OrganizationalUnit.SetRange(Type, OrganizationalUnit.Type::Unit);
        OrganizationalUnit.FindFirst;
        exit(OrganizationalUnit.Code)
    end;

    [Scope('OnPrem')]
    procedure FindOtherAbsenceTimeActivityCode(): Code[10]
    var
        TimeActivity: Record "Time Activity";
    begin
        with TimeActivity do begin
            SetRange("Time Activity Type", "Time Activity Type"::Other);
            SetFilter("Element Code", '<>%1', '');
            FindFirst;
            exit(Code);
        end;
    end;

    [Scope('OnPrem')]
    procedure FindPayrollPeriod(var PayrollPeriod: Record "Payroll Period")
    begin
        with PayrollPeriod do begin
            SetRange(Closed, true);
            if FindLast then begin
                Reset;
                SetFilter("Starting Date", '>%1', "Starting Date");
            end;
            SetRange(Closed, false);
            FindFirst;
        end;
    end;

    [Scope('OnPrem')]
    procedure FindPayrollPeriodCodeByDate(Date: Date): Code[10]
    var
        PayrollPeriod: Record "Payroll Period";
    begin
        with PayrollPeriod do begin
            SetFilter("Starting Date", '..%1', Date);
            SetFilter("Ending Date", '%1..', Date);
            FindFirst;
            exit(Code);
        end;
    end;

    [Scope('OnPrem')]
    procedure FindPayrollCalcGroupCode(): Code[10]
    var
        PayrollCalcGroup: Record "Payroll Calc Group";
    begin
        with PayrollCalcGroup do begin
            SetRange("Disabled Persons", false);
            SetRange(Type, Type::" ");
            FindFirst;
            exit(Code);
        end;
    end;

    [Scope('OnPrem')]
    procedure FindPayrollPostingGroupCodeWithTaxAllocation(): Code[20]
    var
        TaxAllocationPostingSetup: Record "Tax Allocation Posting Setup";
    begin
        TaxAllocationPostingSetup.FindFirst;
        exit(TaxAllocationPostingSetup."Main Posting Group");
    end;

    [Scope('OnPrem')]
    procedure FindPersonPaymentJnlLine(var GenJnlLine: Record "Gen. Journal Line"; PersonNo: Code[20])
    var
        Person: Record Person;
    begin
        Person.Get(PersonNo);
        with GenJnlLine do begin
            SetRange("Account Type", "Account Type"::Vendor);
            SetRange("Account No.", Person."Vendor No.");
            FindFirst;
        end;
    end;

    [Scope('OnPrem')]
    procedure FindPregnancyTimeActivityCode(): Code[10]
    var
        TimeActivity: Record "Time Activity";
    begin
        exit(FindSickLeaveTimeActivityCode(TimeActivity."Sick Leave Type"::"Pregnancy Leave"));
    end;

    [Scope('OnPrem')]
    procedure FindRegularVacationTimeActivityCode(): Code[10]
    var
        TimeActivity: Record "Time Activity";
    begin
        exit(FindVacationTimeActivityCode(TimeActivity."Vacation Type"::Regular));
    end;

    [Scope('OnPrem')]
    procedure FindSickLeaveTimeActivityCode(SickLeaveType: Option): Code[10]
    var
        TimeActivity: Record "Time Activity";
    begin
        with TimeActivity do begin
            SetRange("Time Activity Type", "Time Activity Type"::"Sick Leave");
            SetRange("Sick Leave Type", SickLeaveType);
            FindFirst;
            exit(Code);
        end;
    end;

    [Scope('OnPrem')]
    procedure FindVacationTimeActivityCode(VacationType: Option): Code[10]
    var
        TimeActivity: Record "Time Activity";
    begin
        with TimeActivity do begin
            SetRange("Time Activity Type", "Time Activity Type"::Vacation);
            SetRange("Vacation Type", VacationType);
            FindFirst;
            exit(Code);
        end;
    end;

    [Scope('OnPrem')]
    procedure GetBankAccountCode(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        with BankAccount do begin
            SetFilter("Currency Code", '%1', '');
            SetRange("Account Type", "Account Type"::"Bank Account");
            LibraryERM.FindBankAccount(BankAccount);
            exit("No.");
        end;
    end;

    local procedure GetEndPeriodDateFromPeriodCode(PeriodCode: Code[10]): Date
    var
        Year: Integer;
        Month: Integer;
    begin
        Evaluate(Year, CopyStr(PeriodCode, 1, 2));
        Evaluate(Month, CopyStr(PeriodCode, 3, 2));
        exit(CalcDate('<CM>', DMY2Date(1, Month, Year + 2000)));
    end;

    local procedure GetStartPeriodDateFromPeriodCode(PeriodCode: Code[10]): Date
    var
        Year: Integer;
        Month: Integer;
    begin
        Evaluate(Year, CopyStr(PeriodCode, 1, 2));
        Evaluate(Month, CopyStr(PeriodCode, 3, 2));
        exit(CalcDate('<-CM>', DMY2Date(1, Month, Year + 2000)));
    end;

    [Scope('OnPrem')]
    procedure GetDefaultCalendarCode(): Code[10]
    var
        HRSetup: Record "Human Resources Setup";
    begin
        with HRSetup do begin
            Get;
            TestField("Default Calendar Code");
            exit("Default Calendar Code");
        end;
    end;

    [Scope('OnPrem')]
    procedure GetOfficialCalendarCode(): Code[10]
    var
        HRSetup: Record "Human Resources Setup";
    begin
        with HRSetup do begin
            Get;
            TestField("Official Calendar Code");
            exit("Official Calendar Code");
        end;
    end;

    [Scope('OnPrem')]
    procedure GetMROT(PeriodCode: Code[10]): Decimal
    var
        PayrollLimit: Record "Payroll Limit";
    begin
        exit(GetPayrollLimit(PeriodCode, PayrollLimit.Type::MROT));
    end;

    [Scope('OnPrem')]
    procedure GetFSILimit(PeriodCode: Code[10]): Decimal
    var
        PayrollLimit: Record "Payroll Limit";
    begin
        exit(GetPayrollLimit(PeriodCode, PayrollLimit.Type::"FSI Limit"));
    end;

    local procedure GetPayrollLimit(PeriodCode: Code[10]; LimitType: Option): Decimal
    var
        PayrollLimit: Record "Payroll Limit";
    begin
        with PayrollLimit do begin
            SetRange(Type, LimitType);
            SetFilter("Payroll Period", '..%1', PeriodCode);
            if FindLast then
                exit(Amount);

            exit(0);
        end;
    end;

    local procedure InitGenJnlLine(var GenJnlLine: Record "Gen. Journal Line")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.FindGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJnlLine.Init();
        GenJnlLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJnlLine."Journal Batch Name" := GenJournalBatch.Name;
    end;

    local procedure InsertPayrollPeriod(PeriodCode: Code[10]; StartingDate: Date)
    var
        PayrollPeriod: Record "Payroll Period";
    begin
        with PayrollPeriod do begin
            Code := PeriodCode;
            "Starting Date" := StartingDate;
            "Ending Date" := CalcDate('<CM>', StartingDate);
            Name := Format(StartingDate, 0, '<Month Text> <Year4>');
            if Date2DMY(StartingDate, 2) = 1 then
                "New Payroll Year" := true;
            Insert(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure PostPayrollDoc(EmployeeNo: Code[20]; PostingDate: Date)
    var
        PayrollDocument: Record "Payroll Document";
    begin
        PayrollDocument.SetRange("Employee No.", EmployeeNo);
        PayrollDocument.SetRange("Posting Date", PostingDate);
        PayrollDocument.FindFirst;
        CODEUNIT.Run(CODEUNIT::"Payroll Document - Post", PayrollDocument);
    end;

    [Scope('OnPrem')]
    procedure PostEmplJnlLine(EmplJnlLine: Record "Employee Journal Line")
    begin
        CODEUNIT.Run(CODEUNIT::"Employee Journal - Post Batch", EmplJnlLine);
    end;

    [Scope('OnPrem')]
    procedure PreparePayrollPeriods(var PayrollPeriod: Record "Payroll Period"; StartPeriodCode: Code[10]; EndPeriodCode: Code[10])
    var
        PeriodStartDate: Date;
        PeriodEndDate: Date;
    begin
        // create periods if last one is not found
        PayrollPeriod.Reset();
        if not PayrollPeriod.Get(EndPeriodCode) then begin
            PeriodStartDate := GetStartPeriodDateFromPeriodCode(StartPeriodCode);
            PeriodEndDate := GetEndPeriodDateFromPeriodCode(EndPeriodCode);
            CreatePayrollCalendar(GetDefaultCalendarCode, PeriodEndDate);
            CreatePayrollCalendar(GetOfficialCalendarCode, PeriodEndDate);
            CreatePayrollPeriods(PeriodStartDate, PeriodEndDate);
        end;
    end;

    [Scope('OnPrem')]
    procedure ReleaseTimeSheet(PayrollPeriodCode: Code[10]; EmployeeNo: Code[20])
    var
        TimesheetStatus: Record "Timesheet Status";
    begin
        TimesheetStatus.Get(PayrollPeriodCode, EmployeeNo);
        TimesheetStatus.Release;
    end;

    [Scope('OnPrem')]
    procedure SuggestPersonPayments(var GenJnlLine: Record "Gen. Journal Line"; EmployeeNo: Code[20]; StartingDate: Date; EndingDate: Date; PostingDate: Date; PaymentsBetweenPeriod: Boolean; Post: Boolean)
    var
        Employee: Record Employee;
        Person: Record Person;
        SuggestPersonPayments: Report "Suggest Person Payments";
    begin
        Employee.Get(EmployeeNo);
        InitGenJnlLine(GenJnlLine);
        Person.SetFilter("No.", Employee."Person No.");
        SuggestPersonPayments.SetTableView(Person);
        SuggestPersonPayments.SetParameters(
          GenJnlLine,
          StartingDate,
          EndingDate,
          PostingDate,
          GetBankAccountCode,
          PaymentsBetweenPeriod);
        SuggestPersonPayments.UseRequestPage(false);
        SuggestPersonPayments.Run;

        FindPersonPaymentJnlLine(GenJnlLine, Employee."Person No.");

        if Post then
            LibraryERM.PostGeneralJnlLine(GenJnlLine);
    end;

    [Scope('OnPrem')]
    procedure TransferEmployee(EmployeeNo: Code[20]; TransferDate: Date; ToPosition: Code[20]; Approve: Boolean)
    var
        Employee: Record Employee;
        LaborContractLine: Record "Labor Contract Line";
        LaborContractMgt: Codeunit "Labor Contract Management";
    begin
        Employee.Get(EmployeeNo);
        with LaborContractLine do begin
            "Contract No." := Employee."Contract No.";
            Validate("Starting Date", TransferDate);
            Validate("Operation Type", "Operation Type"::Transfer);
            Validate("Position No.", ToPosition);
            Insert(true);
        end;

        if Approve then
            LaborContractMgt.DoApprove(LaborContractLine);
    end;
}

