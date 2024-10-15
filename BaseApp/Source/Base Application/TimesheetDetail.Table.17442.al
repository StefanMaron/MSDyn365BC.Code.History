table 17442 "Timesheet Detail"
{
    Caption = 'Timesheet Detail';
    LookupPageID = "Timesheet Details";

    fields
    {
        field(1; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            Editable = false;
            TableRelation = Employee;
        }
        field(2; Date; Date)
        {
            Caption = 'Date';
            ClosingDates = true;
            Editable = false;
        }
        field(3; "Time Activity Code"; Code[10])
        {
            Caption = 'Time Activity Code';
            NotBlank = true;
            TableRelation = "Time Activity";

            trigger OnValidate()
            begin
                if "Time Activity Code" <> '' then begin
                    TimeActivity.Get("Time Activity Code");
                    "Timesheet Code" := TimeActivity."Timesheet Code";
                    Overtime := TimeActivity."Allow Overtime";

                    TimesheetDetail.Reset();
                    TimesheetDetail.SetRange("Employee No.", "Employee No.");
                    TimesheetDetail.SetRange(Date, Date);
                    TimesheetDetail.SetFilter("Time Activity Code", '<>%1&<>%2', '', "Time Activity Code");
                    if not TimeActivity."Allow Combination" then begin
                        if not TimesheetDetail.IsEmpty() then
                            Error(Text002, "Time Activity Code")
                    end
                end else
                    "Timesheet Code" := '';
            end;
        }
        field(4; "Time Activity Name"; Text[50])
        {
            CalcFormula = Lookup ("Time Activity".Description WHERE(Code = FIELD("Time Activity Code")));
            Caption = 'Time Activity Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "Calendar Code"; Code[10])
        {
            Caption = 'Calendar Code';
            Editable = false;
            TableRelation = "Payroll Calendar";
        }
        field(7; "Actual Hours"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Actual Hours';
            DecimalPlaces = 0 : 1;
            NotBlank = true;

            trigger OnValidate()
            var
                PlannedActivityCode: Code[10];
                DayStatus: Option " ",Weekend,Holiday;
            begin
                TimeActivity.Get("Time Activity Code");

                Employee.Reset();
                Employee.SetRange("Employee No. Filter", "Employee No.");
                Employee.SetRange("Date Filter", Date);
                Employee.CalcFields("Actual Hours", "Overtime Hours");

                PlannedHours := CalendarMgt.GetDateInfo("Calendar Code", Date, PlannedActivityCode, DayStatus);

                if Overtime then begin
                    if ("Actual Hours" - xRec."Actual Hours") > 24 - Employee."Actual Hours" - Employee."Overtime Hours" then
                        FieldError("Actual Hours", StrSubstNo(Text000, 24))
                end else
                    if "Actual Hours" > PlannedHours then
                        FieldError("Actual Hours", StrSubstNo(Text000, PlannedHours));
            end;
        }
        field(8; Overtime; Boolean)
        {
            Caption = 'Overtime';
            Editable = false;
        }
        field(9; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(10; "Org. Unit Code"; Code[10])
        {
            Caption = 'Org. Unit Code';
            Editable = false;
            TableRelation = "Organizational Unit";
        }
        field(11; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
            //This property is currently not supported 
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(15; "Timesheet Code"; Code[10])
        {
            Caption = 'Timesheet Code';
            TableRelation = "Timesheet Code";
        }
        field(25; "Document Type"; Option)
        {
            Caption = 'Document Type';
            Editable = false;
            OptionCaption = ' ,Vacation,Sick Leave,Travel,Other Absence';
            OptionMembers = " ",Vacation,"Sick Leave",Travel,"Other Absence";
        }
        field(27; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Editable = false;
        }
        field(28; "Document Date"; Date)
        {
            Caption = 'Document Date';
            Editable = false;
        }
        field(29; "Previous Time Activity Code"; Code[10])
        {
            Caption = 'Previous Time Activity Code';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Employee No.", Date, "Time Activity Code")
        {
            Clustered = true;
            SumIndexFields = "Actual Hours";
        }
        key(Key2; "Employee No.", "Org. Unit Code", "Timesheet Code", Date, Overtime)
        {
            SumIndexFields = "Actual Hours";
        }
        key(Key3; "Document No.", "Document Date")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        TestField("Document No.", '');
        TimesheetMgt.CheckTimesheetStatus("Employee No.", "Calendar Code", Date);

        "User ID" := UserId;
    end;

    trigger OnInsert()
    begin
        TestField("Document No.", '');
        TimeActivity.Get("Time Activity Code");
        if not TimeActivity."Allow Override" then
            TimesheetMgt.CheckTimesheetStatus("Employee No.", "Calendar Code", Date);

        "User ID" := UserId;
    end;

    trigger OnModify()
    begin
        TestField("Document No.", '');
        TimesheetMgt.CheckTimesheetStatus("Employee No.", "Calendar Code", Date);

        "User ID" := UserId;
    end;

    trigger OnRename()
    begin
        Error(Text003, TableCaption);
    end;

    var
        TimeActivity: Record "Time Activity";
        TimesheetDetail: Record "Timesheet Detail";
        Employee: Record Employee;
        CalendarMgt: Codeunit "Payroll Calendar Management";
        TimesheetMgt: Codeunit "Timesheet Management RU";
        PlannedHours: Decimal;
        Text000: Label 'per day cannot exceed %1.';
        Text002: Label '%1 cannot be entered together with other codes.';
        Text003: Label 'You cannot rename a %1.';
}

