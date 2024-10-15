table 14960 "Payroll Analysis Report Name"
{
    Caption = 'Payroll Analysis Report Name';
    LookupPageID = "Payroll Analysis Report Names";

    fields
    {
        field(1; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(2; Description; Text[30])
        {
            Caption = 'Description';
        }
        field(3; "Analysis Line Template Name"; Code[10])
        {
            Caption = 'Analysis Line Template Name';
            TableRelation = "Payroll Analysis Line Template";
        }
        field(4; "Analysis Column Template Name"; Code[10])
        {
            Caption = 'Analysis Column Template Name';
            TableRelation = "Payroll Analysis Column Tmpl.";
        }
    }

    keys
    {
        key(Key1; Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

