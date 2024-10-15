table 12423 "Job Title"
{
    Caption = 'Job Title';
    DrillDownPageID = "Job Titles";
    LookupPageID = "Job Titles";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Name; Text[50])
        {
            Caption = 'Name';
        }
        field(4; "Code OKPDTR"; Text[20])
        {
            Caption = 'Code OKPDTR';
        }
        field(6; "Category Type"; Option)
        {
            Caption = 'Category Type';
            OptionCaption = ' ,Manager,Specialist,Worker';
            OptionMembers = " ",Manager,Specialist,Worker;
        }
        field(7; Level; Integer)
        {
            Caption = 'Level';
        }
        field(8; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Job Title,Header ';
            OptionMembers = "Job Title","Header ";
        }
        field(10; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        field(11; "Alternative Name"; Text[50])
        {
            Caption = 'Alternative Name';
        }
        field(14; "Base Salary Element Code"; Code[20])
        {
            Caption = 'Base Salary Element Code';
            TableRelation = "Payroll Element";
        }
        field(15; "Base Salary Amount"; Decimal)
        {
            Caption = 'Base Salary Amount';
        }
        field(20; "Category Code"; Code[10])
        {
            Caption = 'Category Code';
            TableRelation = "Employee Category";
        }
        field(22; "Calendar Code"; Code[10])
        {
            Caption = 'Calendar Code';
            TableRelation = "Payroll Calendar";
        }
        field(24; "Worktime Norm"; Code[10])
        {
            Caption = 'Worktime Norm';
            TableRelation = "Worktime Norm";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(30; "Kind of Work"; Option)
        {
            Caption = 'Kind of Work';
            OptionCaption = ' ,Permanent,Temporary,Seasonal';
            OptionMembers = " ",Permanent,"Temporary",Seasonal;
        }
        field(32; "Conditions of Work"; Option)
        {
            Caption = 'Conditions of Work';
            OptionCaption = ' ,Regular,Heavy,Unhealthy,Very Heavy,Other';
            OptionMembers = " ",Regular,Heavy,Unhealthy,"Very Heavy",Other;
        }
        field(33; "Calc Group Code"; Code[10])
        {
            Caption = 'Calc Group Code';
            TableRelation = "Payroll Calc Group";
        }
        field(34; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            TableRelation = "Payroll Posting Group";
        }
        field(35; "Statistics Group Code"; Code[10])
        {
            Caption = 'Statistics Group Code';
            TableRelation = "Employee Statistics Group";
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Key2; Name)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        Position.Reset();
        Position.SetRange("Job Title Code", Code);
        if not Position.IsEmpty() then
            Error(Text14700, Code);
    end;

    var
        Position: Record Position;
        Text14700: Label '%1 cannot be deleted because there are positions using this code.';
}

