table 17390 "Sick Leave Setup"
{
    Caption = 'Sick Leave Setup';

    fields
    {
        field(1; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Payment Percent,Salary Limits,Sick Leave Care,Payment Source';
            OptionMembers = "Payment Percent","Salary Limits","Sick Leave Care","Payment Source";
        }
        field(2; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
        }
        field(3; "Sick Leave Type"; Option)
        {
            Caption = 'Sick Leave Type';
            OptionCaption = 'All,Common Disease,Common Injury,Professional Disease,Work Injury,Family Member Care,Post Vaccination,Quarantine,Sanatory Cure,Pregnancy Leave,Child Care 1.5 years,Child Care 3 years';
            OptionMembers = All,"Common Disease","Common Injury","Professional Disease","Work Injury","Family Member Care","Post Vaccination",Quarantine,"Sanatory Cure","Pregnancy Leave","Child Care 1.5 years","Child Care 3 years";
        }
        field(4; "Insured Service (Years)"; Decimal)
        {
            Caption = 'Insured Service (Years)';
        }
        field(5; "Payment %"; Decimal)
        {
            Caption = 'Payment %';
        }
        field(6; "Payment Benefit Liable"; Boolean)
        {
            Caption = 'Payment Benefit Liable';
        }
        field(7; "Minimal Wage Amount"; Decimal)
        {
            Caption = 'Minimal Wage Amount';
        }
        field(8; "Maximal Average Earning"; Decimal)
        {
            Caption = 'Maximal Average Earning';
        }
        field(9; Age; Decimal)
        {
            Caption = 'Age';
        }
        field(10; "Treatment Type"; Option)
        {
            Caption = 'Treatment Type';
            OptionCaption = ' ,Out-Patient,In-Patient';
            OptionMembers = " ","Out-Patient","In-Patient";
        }
        field(11; "Max. Days per Year"; Decimal)
        {
            Caption = 'Max. Days per Year';
        }
        field(12; "Max. Days per Document"; Decimal)
        {
            Caption = 'Max. Days per Document';
        }
        field(13; "Max. Paid Days by FSI"; Decimal)
        {
            Caption = 'Max. Paid Days by FSI';
        }
        field(14; "Other Days Payment %"; Decimal)
        {
            Caption = 'Other Days Payment %';
        }
        field(15; "Max. Days per Month"; Decimal)
        {
            Caption = 'Max. Days per Month';
        }
        field(16; "First Payment Days"; Decimal)
        {
            Caption = 'First Payment Days';
        }
        field(17; "Days after Dismissal"; Decimal)
        {
            Caption = 'Days after Dismissal';
        }
        field(18; Dismissed; Boolean)
        {
            Caption = 'Dismissed';
        }
        field(19; "Disabled Person"; Boolean)
        {
            Caption = 'Disabled Person';
        }
        field(20; "Element Code"; Code[20])
        {
            Caption = 'Element Code';
            TableRelation = "Payroll Element";
        }
        field(21; "Payment Source"; Option)
        {
            Caption = 'Payment Source';
            OptionCaption = 'Employeer,FSI';
            OptionMembers = Employeer,FSI;
        }
        field(22; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            TableRelation = "Payroll Posting Group";
        }
        field(23; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
    }

    keys
    {
        key(Key1; Type, "Line No.")
        {
            Clustered = true;
        }
        key(Key2; Type, "Starting Date", "Sick Leave Type", "Element Code")
        {
        }
    }

    fieldgroups
    {
    }

    var
        Employee: Record Employee;
        Person: Record Person;
        SickLeaveSetup: Record "Sick Leave Setup";
        EmployeeJobEntry: Record "Employee Job Entry";
        RecordMgt: Codeunit "Record of Service Management";
        CalendarMgt: Codeunit "Payroll Calendar Management";
        ServiceRecord: array[3] of Integer;
        ServiceYears: Decimal;

    [Scope('OnPrem')]
    procedure GetPaymentPercent(var AbsenceLine: Record "Absence Line")
    var
        PrevPostedAbsenceLine: Record "Posted Absence Line";
        StartingDate: Date;
        EndingDate: Date;
    begin
        if AbsenceLine.FindPreviousAbsenceHeader(PrevPostedAbsenceLine) then begin
            AbsenceLine."Payment Percent" := PrevPostedAbsenceLine."Payment Percent"
        end else begin
            Employee.Get(AbsenceLine."Employee No.");
            Person.Get(Employee."Person No.");
            Employee.GetJobEntry(AbsenceLine."Employee No.", AbsenceLine."Start Date", EmployeeJobEntry);

            RecordMgt.CalcEmplInsuredService(Employee, AbsenceLine."Start Date", ServiceRecord);
            if ServiceRecord[3] = 0 then
                ServiceYears := ServiceRecord[2] / 12
            else
                ServiceYears := ServiceRecord[3];

            SickLeaveSetup.Reset();
            SickLeaveSetup.SetCurrentKey(Type, "Starting Date");
            SickLeaveSetup.SetRange(Type, SickLeaveSetup.Type::"Payment Percent");
            SickLeaveSetup.SetRange("Payment Benefit Liable", Person."Sick Leave Payment Benefit");
            SickLeaveSetup.SetRange("Starting Date", 0D, AbsenceLine."Start Date");
            if not
               (AbsenceLine."Sick Leave Type" = AbsenceLine."Sick Leave Type"::"Pregnancy Leave") or
               (AbsenceLine."Sick Leave Type" = AbsenceLine."Sick Leave Type"::"Child Care 1.5 years")
            then
                SickLeaveSetup.SetRange("Insured Service (Years)", 0, ServiceYears);
            if Employee."Termination Date" <> 0D then begin
                if Employee."Termination Date" > AbsenceLine."Start Date" then begin
                    StartingDate := AbsenceLine."Start Date";
                    EndingDate := Employee."Termination Date";
                end else begin
                    StartingDate := Employee."Termination Date";
                    EndingDate := AbsenceLine."Start Date";
                end;
                SickLeaveSetup.SetRange(Dismissed, true);
                SickLeaveSetup.SetFilter("Days after Dismissal", '%1..',
                  CalendarMgt.GetPeriodInfo(
                    Employee."Calendar Code", StartingDate, EndingDate, 1));
            end else
                SickLeaveSetup.SetRange(Dismissed, false);
            SickLeaveSetup.SetRange("Sick Leave Type", AbsenceLine."Sick Leave Type");
            if SickLeaveSetup.FindLast then
                AbsenceLine."Payment Percent" := SickLeaveSetup."Payment %"
            else begin
                SickLeaveSetup.SetRange("Sick Leave Type", SickLeaveSetup."Sick Leave Type"::All);
                if SickLeaveSetup.FindLast then
                    AbsenceLine."Payment Percent" := SickLeaveSetup."Payment %"
                else
                    AbsenceLine."Payment Percent" := 0;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetCarePaymentPercent(var AbsenceLine: Record "Absence Line")
    begin
        AbsenceLine.TestField("Relative Person No.");
        AbsenceLine.TestField("Start Date");
        Person.Get(AbsenceLine."Relative Person No.");
        Person.GetEntireAge(Person."Birth Date", AbsenceLine."Start Date");
        // check previous sick leave if any

        SickLeaveSetup.Reset();
        SickLeaveSetup.SetCurrentKey(Type, "Starting Date");
        SickLeaveSetup.SetRange(Type, SickLeaveSetup.Type::"Sick Leave Care");
        SickLeaveSetup.SetRange("Element Code", AbsenceLine."Element Code");
        SickLeaveSetup.SetRange("Sick Leave Type", AbsenceLine."Sick Leave Type");
        SickLeaveSetup.SetRange("Starting Date", 0D, AbsenceLine."Start Date");
        SickLeaveSetup.SetRange("Treatment Type", AbsenceLine."Treatment Type");
        SickLeaveSetup.SetRange(Age, 0,
          Person.GetEntireAge(Person."Birth Date", AbsenceLine."Start Date"));
        if Person.IsDisabled(AbsenceLine."Start Date") then
            SickLeaveSetup.SetRange("Disabled Person", true);
        if SickLeaveSetup.FindLast then
            AbsenceLine."Special Payment Percent" := SickLeaveSetup."Other Days Payment %";
    end;

    [Scope('OnPrem')]
    procedure FindFirstAbsenceHeader(var AbsenceLine: Record "Absence Line"; var FirstAbsenceLine: Record "Absence Line") Exist: Boolean
    var
        AbsenceHeader: Record "Absence Header";
    begin
        Exist := false;
        AbsenceHeader.Reset();
        AbsenceHeader.SetRange("Document Type", AbsenceLine."Document Type");
        AbsenceHeader.SetRange("No.", AbsenceLine."Document No.");
        if AbsenceHeader.FindFirst then
            if AbsenceLine."Previous Document No." <> '' then begin
                FirstAbsenceLine.Reset();
                FirstAbsenceLine.SetRange("Document Type", AbsenceHeader."Document Type");
                FirstAbsenceLine.SetRange("Document No.", AbsenceLine."Previous Document No.");
                if FirstAbsenceLine.FindFirst then
                    Exist := true;
            end;
    end;

    [Scope('OnPrem')]
    procedure GetEmployerPaymentDay(var AbsenceLine: Record "Absence Line")
    var
        FirstPostedAbsenceLine: Record "Posted Absence Line";
        Days: Decimal;
    begin
        SickLeaveSetup.Reset();
        SickLeaveSetup.SetCurrentKey(Type, "Starting Date", "Sick Leave Type", "Element Code");
        SickLeaveSetup.SetRange(Type, SickLeaveSetup.Type::"Payment Source");
        SickLeaveSetup.SetRange("Starting Date", 0D, AbsenceLine."Start Date");
        SickLeaveSetup.SetRange("Element Code", AbsenceLine."Element Code");
        if SickLeaveSetup.FindLast then
            Days := SickLeaveSetup."First Payment Days"
        else
            Days := 0;
        if AbsenceLine.FindPreviousAbsenceHeader(FirstPostedAbsenceLine) then begin
            if FirstPostedAbsenceLine."Days Paid by Employer" >= SickLeaveSetup."First Payment Days" then
                Days := 0
            else
                Days := SickLeaveSetup."First Payment Days" - FirstPostedAbsenceLine."Days Paid by Employer";
        end;
        if (Days <> 0) and (Days >= AbsenceLine."Calendar Days") then
            Days := AbsenceLine."Calendar Days";

        AbsenceLine."Days Paid by Employer" := Days;
        AbsenceLine."Payment Days" := AbsenceLine."Calendar Days" - AbsenceLine."Days Paid by Employer";
    end;

    [Scope('OnPrem')]
    procedure GetFSIPaymentDays(var AbsenceLine: Record "Absence Line")
    var
        FirstPostedAbsenceLine: Record "Posted Absence Line";
        StartSpecPaymentDate: Date;
        PaymentDaysPerYear: Decimal;
    begin
        if AbsenceLine."Sick Leave Type" in
           [AbsenceLine."Sick Leave Type"::"Family Member Care",
            AbsenceLine."Sick Leave Type"::"Post Vaccination",
            AbsenceLine."Sick Leave Type"::Quarantine]
        then begin
            Employee.GetJobEntry(AbsenceLine."Employee No.", AbsenceLine."Start Date", EmployeeJobEntry);
            AbsenceLine.TestField("Relative Person No.");
            Person.Get(AbsenceLine."Relative Person No.");
            Person.GetEntireAge(Person."Birth Date", AbsenceLine."Start Date");
            SickLeaveSetup.Reset();
            SickLeaveSetup.SetCurrentKey(Type, "Starting Date", "Sick Leave Type", "Element Code");
            SickLeaveSetup.SetRange(Type, SickLeaveSetup.Type::"Sick Leave Care");
            SickLeaveSetup.SetRange("Starting Date", 0D, AbsenceLine."Start Date");
            SickLeaveSetup.SetRange("Sick Leave Type", AbsenceLine."Sick Leave Type");
            SickLeaveSetup.SetRange(Age, 0,
              Person.GetEntireAge(Person."Birth Date", AbsenceLine."Start Date"));
            if Person.IsDisabled(AbsenceLine."Start Date") then
                SickLeaveSetup.SetRange("Disabled Person", true)
            else
                SickLeaveSetup.SetRange("Treatment Type", AbsenceLine."Treatment Type");

            if SickLeaveSetup.FindLast then begin
                if SickLeaveSetup."Max. Paid Days by FSI" <> 0 then begin
                    if AbsenceLine.FindPreviousAbsenceHeader(FirstPostedAbsenceLine) then
                        StartSpecPaymentDate :=
                          CalcDate('<' + Format(SickLeaveSetup."Max. Paid Days by FSI") + 'D>', FirstPostedAbsenceLine."Start Date")
                    else
                        StartSpecPaymentDate := CalcDate('<' + Format(SickLeaveSetup."Max. Paid Days by FSI") + 'D>', AbsenceLine."Start Date");
                    if StartSpecPaymentDate <= AbsenceLine."End Date" then begin
                        AbsenceLine."Special Payment Days" := CalendarMgt.GetPeriodInfo(
                            EmployeeJobEntry."Calendar Code", StartSpecPaymentDate, AbsenceLine."End Date", 1);
                        AbsenceLine."Payment Days" :=
                          AbsenceLine."Calendar Days" - AbsenceLine."Days Paid by Employer" -
                          AbsenceLine."Special Payment Days";
                    end else
                        AbsenceLine."Payment Days" := AbsenceLine."Calendar Days" - AbsenceLine."Days Paid by Employer";
                end else
                    AbsenceLine."Payment Days" := AbsenceLine."Calendar Days" - AbsenceLine."Days Paid by Employer";
                if AbsenceLine."Days Paid by Employer" >= SickLeaveSetup."Max. Days per Document" then begin
                    AbsenceLine."Days Paid by Employer" := SickLeaveSetup."Max. Days per Document";
                    AbsenceLine."Payment Days" := 0;
                    AbsenceLine."Special Payment Days" := 0;
                    AbsenceLine."Days Not Paid" := AbsenceLine."Calendar Days" - AbsenceLine."Days Paid by Employer";
                end else
                    if AbsenceLine."Days Paid by Employer" + AbsenceLine."Payment Days" >= SickLeaveSetup."Max. Days per Document" then begin
                        AbsenceLine."Payment Days" := SickLeaveSetup."Max. Days per Document" - AbsenceLine."Days Paid by Employer";
                        AbsenceLine."Special Payment Days" := 0;
                        AbsenceLine."Days Not Paid" :=
                          AbsenceLine."Calendar Days" - AbsenceLine."Payment Days" - AbsenceLine."Days Paid by Employer";
                    end else
                        if AbsenceLine."Days Paid by Employer" + AbsenceLine."Payment Days" + AbsenceLine."Special Payment Days" >=
                           SickLeaveSetup."Max. Days per Document"
                        then begin
                            AbsenceLine."Special Payment Days" :=
                              SickLeaveSetup."Max. Days per Document" - AbsenceLine."Payment Days" - AbsenceLine."Days Paid by Employer";
                            AbsenceLine."Days Not Paid" :=
                              AbsenceLine."Calendar Days" - AbsenceLine."Payment Days" -
                              AbsenceLine."Special Payment Days" - AbsenceLine."Days Paid by Employer";
                        end;
                if SickLeaveSetup."Max. Days per Year" <> 0 then begin
                    PaymentDaysPerYear := AbsenceLine.GetPaymentDaysPerYear;
                    if PaymentDaysPerYear >= SickLeaveSetup."Max. Days per Year" then begin
                        AbsenceLine."Payment Days" := 0;
                        AbsenceLine."Special Payment Days" := 0;
                    end;
                    if PaymentDaysPerYear + AbsenceLine."Payment Days" >= SickLeaveSetup."Max. Days per Year" then begin
                        AbsenceLine."Payment Days" := SickLeaveSetup."Max. Days per Year" - PaymentDaysPerYear;
                        AbsenceLine."Special Payment Days" := 0;
                    end else begin
                        if PaymentDaysPerYear + AbsenceLine."Payment Days" + AbsenceLine."Special Payment Days" >=
                           SickLeaveSetup."Max. Days per Year"
                        then
                            AbsenceLine."Special Payment Days" :=
                              SickLeaveSetup."Max. Days per Year" - PaymentDaysPerYear - AbsenceLine."Payment Days";
                    end;
                end;
            end;
            AbsenceLine."Days Not Paid" :=
              AbsenceLine."Calendar Days" - AbsenceLine."Payment Days" -
              AbsenceLine."Special Payment Days" - AbsenceLine."Days Paid by Employer";
        end;
    end;

    [Scope('OnPrem')]
    procedure GetMaxDailyPayment(PayrollDocLine: Record "Payroll Document Line"): Decimal
    var
        EmployeeLedgEntry: Record "Employee Ledger Entry";
    begin
        EmployeeLedgEntry.Get(PayrollDocLine."Employee Ledger Entry No.");

        SickLeaveSetup.Reset();
        SickLeaveSetup.SetRange(Type, SickLeaveSetup.Type::"Salary Limits");
        SickLeaveSetup.SetRange("Sick Leave Type", EmployeeLedgEntry."Sick Leave Type");
        SickLeaveSetup.SetRange("Starting Date", 0D, EmployeeLedgEntry."Action Starting Date");
        if SickLeaveSetup.FindLast then
            exit(SickLeaveSetup."Maximal Average Earning");

        SickLeaveSetup.SetRange("Sick Leave Type", SickLeaveSetup."Sick Leave Type"::All);
        if SickLeaveSetup.FindLast then
            exit(SickLeaveSetup."Maximal Average Earning");

        exit(0);
    end;

    [Scope('OnPrem')]
    procedure GetMinWageAmount(PayrollDocLine: Record "Payroll Document Line"): Decimal
    var
        EmployeeLedgEntry: Record "Employee Ledger Entry";
    begin
        EmployeeLedgEntry.Get(PayrollDocLine."Employee Ledger Entry No.");

        SickLeaveSetup.Reset();
        SickLeaveSetup.SetRange(Type, SickLeaveSetup.Type::"Salary Limits");
        SickLeaveSetup.SetRange("Sick Leave Type", EmployeeLedgEntry."Sick Leave Type");
        SickLeaveSetup.SetRange("Starting Date", 0D, EmployeeLedgEntry."Action Starting Date");

        Employee.Get(PayrollDocLine."Employee No.");
        Employee.GetJobEntry(PayrollDocLine."Employee No.", EmployeeLedgEntry."Action Starting Date", EmployeeJobEntry);

        RecordMgt.CalcEmplInsuredService(Employee, EmployeeLedgEntry."Action Starting Date", ServiceRecord);
        if ServiceRecord[3] = 0 then
            ServiceYears := ServiceRecord[2] / 12
        else
            ServiceYears := ServiceRecord[3];

        SickLeaveSetup.SetRange("Insured Service (Years)", 0, ServiceYears);
        if SickLeaveSetup.FindLast then
            exit(SickLeaveSetup."Minimal Wage Amount");

        SickLeaveSetup.SetRange("Sick Leave Type", SickLeaveSetup."Sick Leave Type"::All);
        if SickLeaveSetup.FindLast then
            exit(SickLeaveSetup."Minimal Wage Amount");

        exit(0);
    end;
}

