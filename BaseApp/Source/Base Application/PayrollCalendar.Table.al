table 17428 "Payroll Calendar"
{
    Caption = 'Payroll Calendar';
    DataCaptionFields = "Code", Name;
    LookupPageID = "Payroll Calendar List";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Name; Text[30])
        {
            Caption = 'Name';
        }
        field(6; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(7; "Working Hours"; Decimal)
        {
            CalcFormula = Sum ("Payroll Calendar Line"."Work Hours" WHERE("Calendar Code" = FIELD(Code),
                                                                          Date = FIELD("Date Filter")));
            Caption = 'Working Hours';
            DecimalPlaces = 2 : 2;
            Editable = false;
            FieldClass = FlowField;
        }
        field(8; "Working Days"; Integer)
        {
            CalcFormula = Count ("Payroll Calendar Line" WHERE("Calendar Code" = FIELD(Code),
                                                               Nonworking = CONST(false),
                                                               Date = FIELD("Date Filter")));
            Caption = 'Working Days';
            Editable = false;
            FieldClass = FlowField;
        }
        field(9; "Weekend Days"; Integer)
        {
            CalcFormula = Count ("Payroll Calendar Line" WHERE("Calendar Code" = FIELD(Code),
                                                               Nonworking = CONST(true),
                                                               "Day Status" = CONST(Weekend),
                                                               Date = FIELD("Date Filter")));
            Caption = 'Weekend Days';
            Editable = false;
            FieldClass = FlowField;
        }
        field(10; "Start Date"; Date)
        {
            CalcFormula = Min ("Payroll Calendar Line".Date WHERE("Calendar Code" = FIELD(Code)));
            Caption = 'Start Date';
            Editable = false;
            FieldClass = FlowField;
        }
        field(11; "End Date"; Date)
        {
            CalcFormula = Max ("Payroll Calendar Line".Date WHERE("Calendar Code" = FIELD(Code)));
            Caption = 'End Date';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12; Holidays; Integer)
        {
            CalcFormula = Count ("Payroll Calendar Line" WHERE("Calendar Code" = FIELD(Code),
                                                               Nonworking = CONST(true),
                                                               "Day Status" = CONST(Holiday),
                                                               Date = FIELD("Date Filter")));
            Caption = 'Holidays';
            Editable = false;
            FieldClass = FlowField;
        }
        field(13; "Shift Days"; Integer)
        {
            Caption = 'Shift Days';
        }
        field(14; "Calendar Days"; Integer)
        {
            CalcFormula = Count ("Payroll Calendar Line" WHERE("Calendar Code" = FIELD(Code),
                                                               Date = FIELD("Date Filter")));
            Caption = 'Calendar Days';
            Editable = false;
            FieldClass = FlowField;
        }
        field(15; "Shift Start Date"; Date)
        {
            Caption = 'Shift Start Date';
        }
        field(16; "Night Hours"; Decimal)
        {
            CalcFormula = Sum ("Payroll Calendar Line"."Night Hours" WHERE("Calendar Code" = FIELD(Code),
                                                                           Date = FIELD("Date Filter")));
            Caption = 'Night Hours';
            DecimalPlaces = 2 : 2;
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        Employee.Reset();
        Employee.SetRange("Calendar Code", Code);
        if not Employee.IsEmpty then
            Error(Text001, Code, Employee.TableCaption);

        EmployeeJobEntry.Reset();
        EmployeeJobEntry.SetRange("Calendar Code", Code);
        if not EmployeeJobEntry.IsEmpty then
            Error(Text001, Code, EmployeeJobEntry.TableCaption);

        PayrollCalendarLine.Reset();
        PayrollCalendarLine.SetRange("Calendar Code", Code);
        PayrollCalendarLine.DeleteAll();

        PayrollCalendarSetup.Reset();
        PayrollCalendarSetup.SetRange("Calendar Code", Code);
        PayrollCalendarSetup.DeleteAll();
    end;

    var
        PayrollCalendarLine: Record "Payroll Calendar Line";
        Text001: Label 'You cannot delete payroll calendar %1 because it is used in table %2.';
        PayrollCalendarSetup: Record "Payroll Calendar Setup";
        Employee: Record Employee;
        EmployeeJobEntry: Record "Employee Job Entry";
}

