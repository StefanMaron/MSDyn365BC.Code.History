table 17441 "Timesheet Line"
{
    Caption = 'Timesheet Line';

    fields
    {
        field(1; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            TableRelation = Employee;
        }
        field(2; Date; Date)
        {
            Caption = 'Date';
        }
        field(4; "Calendar Code"; Code[10])
        {
            Caption = 'Calendar Code';
            TableRelation = "Payroll Calendar";
        }
        field(5; "Planned Hours"; Decimal)
        {
            Caption = 'Planned Hours';
        }
        field(6; "Actual Hours"; Decimal)
        {
            CalcFormula = Sum ("Timesheet Detail"."Actual Hours" WHERE("Employee No." = FIELD("Employee No."),
                                                                       Date = FIELD(Date)));
            Caption = 'Actual Hours';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; Nonworking; Boolean)
        {
            Caption = 'Nonworking';
        }
        field(8; Description; Text[30])
        {
            Caption = 'Description';
        }
        field(9; Day; Text[30])
        {
            Caption = 'Day';
        }
        field(10; "Org. Unit Code"; Code[10])
        {
            Caption = 'Org. Unit Code';
            TableRelation = "Organizational Unit";
        }
        field(11; "Time Activity Code"; Code[10])
        {
            Caption = 'Time Activity Code';
            TableRelation = "Time Activity";
        }
        field(12; "Planned Night Hours"; Decimal)
        {
            Caption = 'Planned Night Hours';
        }
    }

    keys
    {
        key(Key1; "Employee No.", Date)
        {
            Clustered = true;
        }
        key(Key2; "Employee No.", "Org. Unit Code", Date)
        {
            SumIndexFields = "Planned Hours";
        }
        key(Key3; "Calendar Code", Date)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        TimesheetDetail.Reset();
        TimesheetDetail.SetRange("Employee No.", "Employee No.");
        TimesheetDetail.SetRange(Date, Date);
        TimesheetDetail.DeleteAll(true);
    end;

    var
        TimesheetDetail: Record "Timesheet Detail";

    [Scope('OnPrem')]
    procedure ActualAssistEdit()
    var
        TimesheetDetail: Record "Timesheet Detail";
        TimesheetDetails: Page "Timesheet Details";
    begin
        TimesheetDetail.Reset();
        TimesheetDetail.SetRange("Employee No.", "Employee No.");
        TimesheetDetail.SetRange(Date, Date);
        TimesheetDetail.SetRange("Calendar Code", "Calendar Code");

        TimesheetDetails.SetTableView(TimesheetDetail);
        TimesheetDetails.RunModal;
        Clear(TimesheetDetails);
    end;
}

