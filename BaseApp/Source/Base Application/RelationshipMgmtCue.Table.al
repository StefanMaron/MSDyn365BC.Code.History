table 9063 "Relationship Mgmt. Cue"
{
    Caption = 'Relationship Mgmt. Cue';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; Contacts; Integer)
        {
            CalcFormula = Count (Contact);
            Caption = 'Contacts';
            FieldClass = FlowField;
        }
        field(3; Segments; Integer)
        {
            CalcFormula = Count ("Segment Header");
            Caption = 'Segments';
            FieldClass = FlowField;
        }
        field(4; "Logged Segments"; Integer)
        {
            CalcFormula = Count ("Logged Segment");
            Caption = 'Logged Segments';
            FieldClass = FlowField;
        }
        field(5; "Open Opportunities"; Integer)
        {
            CalcFormula = Count (Opportunity WHERE(Closed = FILTER(false)));
            Caption = 'Open Opportunities';
            FieldClass = FlowField;
        }
        field(6; "Closed Opportunities"; Integer)
        {
            CalcFormula = Count (Opportunity WHERE(Closed = FILTER(true)));
            Caption = 'Closed Opportunities';
            FieldClass = FlowField;
        }
        field(7; "Opportunities Due in 7 Days"; Integer)
        {
            CalcFormula = Count ("Opportunity Entry" WHERE(Active = FILTER(true),
                                                           "Date Closed" = FILTER(0D),
                                                           "Estimated Close Date" = FIELD("Due Date Filter")));
            Caption = 'Opportunities Due in 7 Days';
            FieldClass = FlowField;
        }
        field(8; "Overdue Opportunities"; Integer)
        {
            CalcFormula = Count ("Opportunity Entry" WHERE(Active = FILTER(true),
                                                           "Date Closed" = FILTER(0D),
                                                           "Estimated Close Date" = FIELD("Overdue Date Filter")));
            Caption = 'Overdue Opportunities';
            FieldClass = FlowField;
        }
        field(9; "Sales Cycles"; Integer)
        {
            CalcFormula = Count ("Sales Cycle");
            Caption = 'Sales Cycles';
            FieldClass = FlowField;
        }
        field(10; "Sales Persons"; Integer)
        {
            CalcFormula = Count ("Salesperson/Purchaser");
            Caption = 'Sales Persons';
            FieldClass = FlowField;
        }
        field(11; "Contacts - Open Opportunities"; Integer)
        {
            CalcFormula = Count (Contact WHERE("No. of Opportunities" = FILTER(<> 0)));
            Caption = 'Contacts - Open Opportunities';
            FieldClass = FlowField;
        }
        field(12; "Contacts - Companies"; Integer)
        {
            CalcFormula = Count (Contact WHERE(Type = CONST(Company)));
            Caption = 'Contacts - Companies';
            FieldClass = FlowField;
        }
        field(13; "Contacts - Persons"; Integer)
        {
            CalcFormula = Count (Contact WHERE(Type = CONST(Person)));
            Caption = 'Contacts - Persons';
            FieldClass = FlowField;
        }
        field(14; "Contacts - Duplicates"; Integer)
        {
            CalcFormula = Count ("Contact Duplicate");
            Caption = 'Contacts - Duplicates';
            FieldClass = FlowField;
        }
        field(18; "Due Date Filter"; Date)
        {
            Caption = 'Due Date Filter';
            FieldClass = FlowFilter;
        }
        field(19; "Overdue Date Filter"; Date)
        {
            Caption = 'Overdue Date Filter';
            FieldClass = FlowFilter;
        }
        field(20; "Open Sales Quotes"; Integer)
        {
            CalcFormula = Count ("Sales Header" WHERE("Document Type" = FILTER(Quote),
                                                      Status = FILTER(Open)));
            Caption = 'Open Sales Quotes';
            FieldClass = FlowField;
        }
        field(21; "Open Sales Orders"; Integer)
        {
            CalcFormula = Count ("Sales Header" WHERE("Document Type" = FILTER(Order),
                                                      Status = FILTER(Open)));
            Caption = 'Open Sales Orders';
            FieldClass = FlowField;
        }
        field(22; "Active Campaigns"; Integer)
        {
            CalcFormula = Count (Campaign WHERE(Activated = FILTER(true)));
            Caption = 'Active Campaigns';
            FieldClass = FlowField;
        }
        field(23; "Uninvoiced Bookings"; Integer)
        {
            Caption = 'Uninvoiced Bookings';
            Editable = false;
        }
        field(24; "Coupled Data Synch Errors"; Integer)
        {
            CalcFormula = Count ("CRM Integration Record" WHERE(Skipped = CONST(true)));
            Caption = 'Coupled Data Synch Errors';
            FieldClass = FlowField;
        }
        field(25; "CDS Integration Errors"; Integer)
        {
            CalcFormula = Count ("Integration Synch. Job Errors");
            Caption = 'Common Data Service Integration Errors';
            FieldClass = FlowField;
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

