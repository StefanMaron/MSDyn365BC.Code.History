table 17391 "HRP Cue"
{
    Caption = 'HRP Cue';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Approved Positions"; Integer)
        {
            CalcFormula = Count (Position WHERE(Status = CONST(Approved),
                                                "Budgeted Position" = CONST(false)));
            Caption = 'Approved Positions';
            Editable = false;
            FieldClass = FlowField;
        }
        field(3; "Planned Positions"; Integer)
        {
            CalcFormula = Count (Position WHERE(Status = CONST(Planned),
                                                "Budgeted Position" = CONST(false)));
            Caption = 'Planned Positions';
            Editable = false;
            FieldClass = FlowField;
        }
        field(4; "Active Employees"; Integer)
        {
            CalcFormula = Count (Employee WHERE(Status = CONST(Active)));
            Caption = 'Active Employees';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "Inactive Employees"; Integer)
        {
            CalcFormula = Count (Employee WHERE(Status = CONST(Inactive)));
            Caption = 'Inactive Employees';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "Open Labor Contracts"; Integer)
        {
            CalcFormula = Count ("Labor Contract" WHERE(Status = CONST(Open)));
            Caption = 'Open Labor Contracts';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; "Approved Labor Contracts"; Integer)
        {
            CalcFormula = Count ("Labor Contract" WHERE(Status = CONST(Approved)));
            Caption = 'Approved Labor Contracts';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8; "Closed Labor Contracts"; Integer)
        {
            CalcFormula = Count ("Labor Contract" WHERE(Status = CONST(Closed)));
            Caption = 'Closed Labor Contracts';
            Editable = false;
            FieldClass = FlowField;
        }
        field(10; "Open Vacation Orders"; Integer)
        {
            CalcFormula = Count ("Absence Header" WHERE("Document Type" = CONST(Vacation),
                                                        Status = CONST(Open),
                                                        "Posting Date" = FIELD("Date Filter")));
            Caption = 'Open Vacation Orders';
            Editable = false;
            FieldClass = FlowField;
        }
        field(11; "Open Sick Leave Orders"; Integer)
        {
            CalcFormula = Count ("Absence Header" WHERE("Document Type" = CONST("Sick Leave"),
                                                        Status = CONST(Open),
                                                        "Posting Date" = FIELD("Date Filter")));
            Caption = 'Open Sick Leave Orders';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12; "Open Travel Orders"; Integer)
        {
            CalcFormula = Count ("Absence Header" WHERE("Document Type" = CONST(Travel),
                                                        Status = CONST(Open),
                                                        "Posting Date" = FIELD("Date Filter")));
            Caption = 'Open Travel Orders';
            Editable = false;
            FieldClass = FlowField;
        }
        field(13; "Open Other Absence Orders"; Integer)
        {
            CalcFormula = Count ("Absence Header" WHERE("Document Type" = CONST("Other Absence"),
                                                        Status = CONST(Open),
                                                        "Posting Date" = FIELD("Date Filter")));
            Caption = 'Open Other Absence Orders';
            Editable = false;
            FieldClass = FlowField;
        }
        field(15; "Released Vacation Orders"; Integer)
        {
            CalcFormula = Count ("Absence Header" WHERE("Document Type" = CONST(Vacation),
                                                        Status = CONST(Released),
                                                        "Posting Date" = FIELD("Date Filter")));
            Caption = 'Released Vacation Orders';
            Editable = false;
            FieldClass = FlowField;
        }
        field(16; "Released Sick Leave Orders"; Integer)
        {
            CalcFormula = Count ("Absence Header" WHERE("Document Type" = CONST("Sick Leave"),
                                                        Status = CONST(Released),
                                                        "Posting Date" = FIELD("Date Filter")));
            Caption = 'Released Sick Leave Orders';
            Editable = false;
            FieldClass = FlowField;
        }
        field(17; "Released Travel Orders"; Integer)
        {
            CalcFormula = Count ("Absence Header" WHERE("Document Type" = CONST(Travel),
                                                        Status = CONST(Released),
                                                        "Posting Date" = FIELD("Date Filter")));
            Caption = 'Released Travel Orders';
            Editable = false;
            FieldClass = FlowField;
        }
        field(18; "Released Other Absence Orders"; Integer)
        {
            CalcFormula = Count ("Absence Header" WHERE("Document Type" = CONST("Other Absence"),
                                                        Status = CONST(Released),
                                                        "Posting Date" = FIELD("Date Filter")));
            Caption = 'Released Other Absence Orders';
            Editable = false;
            FieldClass = FlowField;
        }
        field(20; "Released Timesheets"; Integer)
        {
            CalcFormula = Count ("Timesheet Status" WHERE(Status = CONST(Released),
                                                          "Period Code" = FIELD("Period Filter")));
            Caption = 'Released Timesheets';
            Editable = false;
            FieldClass = FlowField;
        }
        field(21; "Open Timesheets"; Integer)
        {
            CalcFormula = Count ("Timesheet Status" WHERE(Status = CONST(Open),
                                                          "Period Code" = FIELD("Period Filter")));
            Caption = 'Open Timesheets';
            Editable = false;
            FieldClass = FlowField;
        }
        field(22; "Approved Budget Positions"; Integer)
        {
            CalcFormula = Count (Position WHERE(Status = CONST(Approved),
                                                "Budgeted Position" = CONST(true)));
            Caption = 'Approved Budget Positions';
            Editable = false;
            FieldClass = FlowField;
        }
        field(23; "Planned Budget Positions"; Integer)
        {
            CalcFormula = Count (Position WHERE(Status = CONST(Planned),
                                                "Budgeted Position" = CONST(true)));
            Caption = 'Planned Budget Positions';
            Editable = false;
            FieldClass = FlowField;
        }
        field(25; "Open Vacation Requests"; Integer)
        {
            CalcFormula = Count ("Vacation Request" WHERE(Status = CONST(Open),
                                                          "Request Date" = FIELD("Date Filter")));
            Caption = 'Open Vacation Requests';
            Editable = false;
            FieldClass = FlowField;
        }
        field(26; "Approved Vacation Requests"; Integer)
        {
            CalcFormula = Count ("Vacation Request" WHERE(Status = CONST(Approved),
                                                          "Request Date" = FIELD("Date Filter")));
            Caption = 'Approved Vacation Requests';
            Editable = false;
            FieldClass = FlowField;
        }
        field(30; "Payroll Documents"; Integer)
        {
            CalcFormula = Count ("Payroll Document" WHERE("Posting Date" = FIELD("Date Filter")));
            Caption = 'Payroll Documents';
            Editable = false;
            FieldClass = FlowField;
        }
        field(50; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(51; "Period Filter"; Code[10])
        {
            Caption = 'Period Filter';
            FieldClass = FlowFilter;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

