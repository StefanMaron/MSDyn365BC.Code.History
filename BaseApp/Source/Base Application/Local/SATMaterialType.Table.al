table 27037 "SAT Material Type"
{
    DataPerCompany = false;
    DrillDownPageID = "SAT Material Types";
    LookupPageID = "SAT Material Types";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
			DataClassification = CustomerContent;
        }
        field(2; Description; Text[250])
        {
            Caption = 'Description';
			DataClassification = CustomerContent;
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