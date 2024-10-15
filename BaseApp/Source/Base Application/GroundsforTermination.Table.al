table 5217 "Grounds for Termination"
{
    Caption = 'Grounds for Termination';
    DrillDownPageID = "Grounds for Termination";
    LookupPageID = "Grounds for Termination";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(17400; Introduction; Text[30])
        {
            Caption = 'Introduction';
        }
        field(17401; "Dismissal Type"; Option)
        {
            Caption = 'Dismissal Type';
            OptionCaption = ' ,Good Reason,Inadequate';
            OptionMembers = " ","Good Reason",Inadequate;
        }
        field(17402; "Dismissal Article"; Text[100])
        {
            Caption = 'Dismissal Article';
        }
        field(17403; "Reporting Type"; Option)
        {
            Caption = 'Reporting Type';
            OptionCaption = ' ,Employee Decision,Staff Reduction,Mass Dismissal';
            OptionMembers = " ","Employee Decision","Staff Reduction","Mass Dismissal";
        }
        field(17404; "Element Code"; Code[20])
        {
            Caption = 'Element Code';
            TableRelation = "Payroll Element";
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
}

