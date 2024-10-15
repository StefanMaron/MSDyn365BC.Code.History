table 27010 "SAT Classification"
{
    Caption = 'SAT Classification';
    DataPerCompany = false;
    DrillDownPageID = "SAT Classifications";
    LookupPageID = "SAT Classifications";

    fields
    {
        field(1; "SAT Classification"; Code[10])
        {
            Caption = 'SAT Classification';
            Description = '  Identifies the classification of product or service';
        }
        field(2; Description; Text[150])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "SAT Classification")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

