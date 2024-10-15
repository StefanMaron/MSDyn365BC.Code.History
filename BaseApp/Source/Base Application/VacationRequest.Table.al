table 17434 "Vacation Request"
{
    Caption = 'Vacation Request';
    LookupPageID = "Vacation Requests";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    HumanResSetup.Get();
                    NoSeriesMgt.TestManual(GetNoSeriesCode);
                    "No. Series" := '';
                end;
            end;
        }
        field(2; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            TableRelation = Employee;

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);

                GetEmployee("Employee No.");
                Employee.TestField("Termination Date", 0D);
                Employee.TestField(Blocked, false);
                "Employee Name" := Employee.GetFullNameOnDate("Request Date");
                Validate("Org. Unit Code", Employee."Org. Unit Code");
                Validate("Job Title Code", Employee."Job Title Code");
            end;
        }
        field(3; "Request Date"; Date)
        {
            Caption = 'Request Date';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);

                if "Request Date" <> 0D then begin
                    GetEmployee("Employee No.");
                    if "Request Date" < Employee."Employment Date" then
                        LocMgt.DateMustBeLater(FieldCaption("Request Date"), Employee."Employment Date");
                end;
            end;
        }
        field(4; "Start Date"; Date)
        {
            Caption = 'Start Date';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);

                if "Start Date" <> 0D then begin
                    GetEmployee("Employee No.");
                    if "Start Date" < Employee."Employment Date" then
                        LocMgt.DateMustBeLater(FieldCaption("Start Date"), Employee."Employment Date");
                end;

                LocMgt.CheckPeriodDates("Start Date", xRec."End Date");

                if ("Start Date" <> 0D) and ("End Date" <> 0D) then begin
                    Employee.GetJobEntry("Employee No.", "Start Date", EmployeeJobEntry);
                    "Calendar Days" :=
                      CalendarMgt.GetPeriodInfo(
                        EmployeeJobEntry."Calendar Code", "Start Date", "End Date", 1) -
                      CalendarMgt.GetPeriodInfo(
                        EmployeeJobEntry."Calendar Code", "Start Date", "End Date", 4);
                end;
            end;
        }
        field(5; "End Date"; Date)
        {
            Caption = 'End Date';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
                TestField("Start Date");

                LocMgt.CheckPeriodDates("Start Date", xRec."End Date");

                if ("Start Date" <> 0D) and ("End Date" <> 0D) then begin
                    HRSetup.Get();
                    HRSetup.TestField("Official Calendar Code");
                    "Calendar Days" :=
                      CalendarMgt.GetPeriodInfo(
                        HRSetup."Official Calendar Code", "Start Date", "End Date", 1) -
                      CalendarMgt.GetPeriodInfo(
                        HRSetup."Official Calendar Code", "Start Date", "End Date", 4);
                end;
            end;
        }
        field(6; "Time Activity Code"; Code[10])
        {
            Caption = 'Time Activity Code';
            TableRelation = "Time Activity" WHERE("Time Activity Type" = CONST(Vacation));

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);

                TimeActivity.Get("Time Activity Code");
                TimeActivity.TestField("Time Activity Type", TimeActivity."Time Activity Type"::Vacation);
                Description := CopyStr(TimeActivity.Description, 1, MaxStrLen(Description));
            end;
        }
        field(7; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(8; "Calendar Days"; Decimal)
        {
            Caption = 'Calendar Days';
            MinValue = 0;

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
                TestField("Start Date");
                if "Calendar Days" > 0 then
                    "End Date" := CalcDate(StrSubstNo('<%1D>', "Calendar Days" - 1), "Start Date");
            end;
        }
        field(10; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(11; "Org. Unit Code"; Code[10])
        {
            Caption = 'Org. Unit Code';
            Editable = false;
            TableRelation = "Organizational Unit";

            trigger OnValidate()
            begin
                OrganizationalUnit.Get("Org. Unit Code");
                OrganizationalUnit.TestField(Blocked, false);
                "Org. Unit Name" := OrganizationalUnit.Name;
            end;
        }
        field(12; "Job Title Code"; Code[10])
        {
            Caption = 'Job Title Code';
            Editable = false;
            TableRelation = "Job Title";

            trigger OnValidate()
            begin
                JobTitle.Get("Job Title Code");
                JobTitle.TestField(Blocked, false);
                "Job Title Name" := JobTitle.Name;
            end;
        }
        field(13; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Open,Approved,Closed';
            OptionMembers = Open,Approved,Closed;
        }
        field(15; Comment; Boolean)
        {
            CalcFormula = Exist ("HR Order Comment Line" WHERE("Table Name" = CONST("Vacation Request"),
                                                               "No." = FIELD("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(16; "Scheduled Year"; Integer)
        {
            Caption = 'Scheduled Year';
            TableRelation = "Vacation Schedule Name";
        }
        field(17; "Scheduled Start Date"; Date)
        {
            Caption = 'Scheduled Start Date';

            trigger OnLookup()
            var
                VacationScheduleLines: Page "Vacation Schedule Lines";
            begin
                VacationScheduleLine.Reset();
                VacationScheduleLine.SetRange(Year, "Scheduled Year");
                VacationScheduleLine.SetRange("Employee No.", "Employee No.");

                Clear(VacationScheduleLines);
                VacationScheduleLines.SetTableView(VacationScheduleLine);
                VacationScheduleLines.LookupMode(true);
                if VacationScheduleLines.RunModal = ACTION::LookupOK then begin
                    VacationScheduleLines.GetRecord(VacationScheduleLine);
                    "Scheduled Start Date" := VacationScheduleLine."Start Date";
                    Validate("Start Date", VacationScheduleLine."Start Date");
                    Validate("End Date", VacationScheduleLine."End Date");
                end;
            end;
        }
        field(18; "Vacation Used"; Boolean)
        {
            Caption = 'Vacation Used';
            Editable = false;
        }
        field(20; "Employee Name"; Text[100])
        {
            Caption = 'Employee Name';
            Editable = false;
        }
        field(21; "Org. Unit Name"; Text[50])
        {
            Caption = 'Org. Unit Name';
            Editable = false;
        }
        field(22; "Job Title Name"; Text[50])
        {
            Caption = 'Job Title Name';
        }
        field(33; "Submit Date"; Date)
        {
            Caption = 'Submit Date';
            Editable = false;
        }
        field(34; "Created By User"; Code[50])
        {
            Caption = 'Created By User';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(35; "Creation Date"; Date)
        {
            Caption = 'Creation Date';
            Editable = false;
        }
        field(36; "Approved By User"; Code[50])
        {
            Caption = 'Approved By User';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(37; "Approval Date"; Date)
        {
            Caption = 'Approval Date';
            Editable = false;
        }
        field(38; "Closed By User"; Code[50])
        {
            Caption = 'Closed By User';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(39; "Closing Date"; Date)
        {
            Caption = 'Closing Date';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Employee No.", "Time Activity Code", Status, "Start Date")
        {
            SumIndexFields = "Calendar Days";
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        HumanResSetup.Get();
        if "No." = '' then begin
            TestNoSeries;
            NoSeriesMgt.InitSeries(GetNoSeriesCode, xRec."No. Series", "Request Date", "No.", "No. Series");
        end;

        InitRecord;

        "Created By User" := UserId;
        "Creation Date" := Today;
    end;

    var
        HumanResSetup: Record "Human Resources Setup";
        Employee: Record Employee;
        EmployeeJobEntry: Record "Employee Job Entry";
        TimeActivity: Record "Time Activity";
        AbsenceLine: Record "Absence Line";
        HRSetup: Record "Human Resources Setup";
        OrganizationalUnit: Record "Organizational Unit";
        JobTitle: Record "Job Title";
        VacationScheduleLine: Record "Vacation Schedule Line";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        Text000: Label 'Request will be closed and you will not be able to reopen it again. Close request?';
        Text001: Label 'Request is already used in vacation order.';
        LocMgt: Codeunit "Localisation Management";
        CalendarMgt: Codeunit "Payroll Calendar Management";

    [Scope('OnPrem')]
    procedure InitRecord()
    begin
        "Request Date" := Today;
    end;

    [Scope('OnPrem')]
    procedure AssistEdit(OldVacationRequest: Record "Vacation Request"): Boolean
    var
        VacationRequest: Record "Vacation Request";
    begin
        with VacationRequest do begin
            Copy(Rec);
            HumanResSetup.Get();
            TestNoSeries;
            if NoSeriesMgt.SelectSeries(GetNoSeriesCode, OldVacationRequest."No. Series", "No. Series") then begin
                NoSeriesMgt.SetSeries("No.");
                Rec := VacationRequest;
                exit(true);
            end;
        end;
    end;

    local procedure TestNoSeries()
    begin
        HumanResSetup.TestField("Vacation Request Nos.");
    end;

    local procedure GetNoSeriesCode(): Code[20]
    begin
        exit(HumanResSetup."Vacation Request Nos.");
    end;

    [Scope('OnPrem')]
    procedure GetEmployee(EmployeeNo: Code[20])
    begin
        if (Employee."No." = '') and (EmployeeNo <> '') then
            Employee.Get(EmployeeNo);
    end;

    [Scope('OnPrem')]
    procedure Approve()
    begin
        TestField(Status, Status::Open);
        TestField("Employee No.");
        TestField("Request Date");
        TestField("Start Date");
        TestField("End Date");
        TestField("Time Activity Code");
        TestField("Calendar Days");
        TestField("Org. Unit Code");
        TestField("Job Title Code");

        TimeActivity.Get("Time Activity Code");
        if TimeActivity."Use Accruals" then begin
            TestField("Scheduled Year");
            TestField("Scheduled Start Date");
        end;

        Status := Status::Approved;
        "Approved By User" := UserId;
        "Approval Date" := Today;
        Modify;
    end;

    [Scope('OnPrem')]
    procedure Reopen()
    begin
        TestField(Status, Status::Approved);

        AbsenceLine.Reset();
        AbsenceLine.SetRange("Vacation Request No.", "No.");
        if not AbsenceLine.IsEmpty then
            Error(Text001);

        Status := Status::Open;
        Modify;
    end;

    [Scope('OnPrem')]
    procedure Close()
    begin
        TestField(Status, Status::Approved);

        if not Confirm(Text000, true) then
            exit;

        Status := Status::Closed;
        "Closed By User" := UserId;
        "Closing Date" := Today;
        Modify;
    end;

    [Scope('OnPrem')]
    procedure MarkUsed()
    begin
        if not "Vacation Used" then begin
            "Vacation Used" := true;
            TimeActivity.Get("Time Activity Code");
            if TimeActivity."Use Accruals" then begin
                TestField("Scheduled Year");
                TestField("Scheduled Start Date");
                VacationScheduleLine.Reset();
                VacationScheduleLine.SetRange(Year, "Scheduled Year");
                VacationScheduleLine.SetRange("Employee No.", "Employee No.");
                VacationScheduleLine.SetRange("Start Date", "Scheduled Start Date");
                if VacationScheduleLine.FindFirst then begin
                    VacationScheduleLine."Actual Start Date" := "Start Date";
                    if VacationScheduleLine."Actual Start Date" <> VacationScheduleLine."Start Date" then
                        VacationScheduleLine."Carry Over Reason" := TableCaption + ' ' + "No.";
                    VacationScheduleLine.Modify();
                end;
            end;
            Modify;
        end;
    end;

    [Scope('OnPrem')]
    procedure MarkUnused()
    begin
        if "Vacation Used" then begin
            "Vacation Used" := false;
            Modify;
        end;
    end;
}

