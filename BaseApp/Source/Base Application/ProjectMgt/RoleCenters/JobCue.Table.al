namespace Microsoft.Projects.RoleCenters;

using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Resources.Resource;

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
            CalcFormula = Count(Job where("Scheduled Res. Qty." = filter(0)));
            Caption = 'Jobs w/o Resource';
            Editable = false;
            FieldClass = FlowField;
        }
        field(3; "Upcoming Invoices"; Integer)
        {
            CalcFormula = Count(Job where(Status = filter(Planning | Quote | Open),
                                           "Next Invoice Date" = field("Date Filter")));
            Caption = 'Upcoming Invoices';
            Editable = false;
            FieldClass = FlowField;
        }
        field(4; "Invoices Due - Not Created"; Integer)
        {
            CalcFormula = Count(Job where(Status = const(Open),
                                           "Next Invoice Date" = field("Date Filter2")));
            Caption = 'Invoices Due - Not Created';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "WIP Not Posted"; Integer)
        {
            CalcFormula = Count(Job where("WIP Entries Exist" = const(true)));
            Caption = 'WIP Not Posted';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "Completed - WIP Not Calculated"; Integer)
        {
            CalcFormula = Count(Job where(Status = filter(Completed),
                                           "WIP Completion Calculated" = const(false),
                                           "WIP Completion Posted" = const(false)));
            Caption = 'Completed - WIP Not Calculated';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; "Available Resources"; Integer)
        {
            CalcFormula = Count(Resource where("Qty. on Order (Job)" = filter(0),
                                                "Qty. Quoted (Job)" = filter(0),
                                                "Qty. on Service Order" = filter(0),
                                                "Date Filter" = field("Date Filter")));
            Caption = 'Available Resources';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8; "Unassigned Resource Groups"; Integer)
        {
            CalcFormula = Count("Resource Group" where("No. of Resources Assigned" = filter(0)));
            Caption = 'Unassigned Resource Groups';
            Editable = false;
            FieldClass = FlowField;
        }
        field(9; "Jobs Over Budget"; Integer)
        {
            CalcFormula = Count(Job where("Over Budget" = filter(= true)));
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

