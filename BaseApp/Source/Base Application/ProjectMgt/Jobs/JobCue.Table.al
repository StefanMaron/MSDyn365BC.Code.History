table 9057 "Job Cue"
{
    Caption = 'Job Cue';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Jobs w/o Resource"; Integer)
        {
            CalcFormula = Count (Job WHERE("Scheduled Res. Qty." = FILTER(0)));
            Caption = 'Jobs w/o Resource';
            Editable = false;
            FieldClass = FlowField;
        }
        field(3; "Upcoming Invoices"; Integer)
        {
            CalcFormula = Count (Job WHERE(Status = FILTER(Planning | Quote | Open),
                                           "Next Invoice Date" = FIELD("Date Filter")));
            Caption = 'Upcoming Invoices';
            Editable = false;
            FieldClass = FlowField;
        }
        field(4; "Invoices Due - Not Created"; Integer)
        {
            CalcFormula = Count (Job WHERE(Status = CONST(Open),
                                           "Next Invoice Date" = FIELD("Date Filter2")));
            Caption = 'Invoices Due - Not Created';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "WIP Not Posted"; Integer)
        {
            CalcFormula = Count (Job WHERE("WIP Entries Exist" = CONST(true)));
            Caption = 'WIP Not Posted';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "Completed - WIP Not Calculated"; Integer)
        {
            CalcFormula = Count (Job WHERE(Status = FILTER(Completed),
                                           "WIP Completion Calculated" = CONST(false),
                                           "WIP Completion Posted" = CONST(false)));
            Caption = 'Completed - WIP Not Calculated';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; "Available Resources"; Integer)
        {
            CalcFormula = Count (Resource WHERE("Qty. on Order (Job)" = FILTER(0),
                                                "Qty. Quoted (Job)" = FILTER(0),
                                                "Qty. on Service Order" = FILTER(0),
                                                "Date Filter" = FIELD("Date Filter")));
            Caption = 'Available Resources';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8; "Unassigned Resource Groups"; Integer)
        {
            CalcFormula = Count ("Resource Group" WHERE("No. of Resources Assigned" = FILTER(0)));
            Caption = 'Unassigned Resource Groups';
            Editable = false;
            FieldClass = FlowField;
        }
        field(9; "Jobs Over Budget"; Integer)
        {
            CalcFormula = Count (Job WHERE("Over Budget" = FILTER(= true)));
            Caption = 'Jobs Over Budget';
            Editable = false;
            FieldClass = FlowField;
        }
        field(20; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            Editable = false;
            FieldClass = FlowFilter;
        }
        field(21; "Date Filter2"; Date)
        {
            Caption = 'Date Filter2';
            Editable = false;
            FieldClass = FlowFilter;
        }
        field(22; "User ID Filter"; Code[50])
        {
            Caption = 'User ID Filter';
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

