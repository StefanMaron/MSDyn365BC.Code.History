table 27048 "SAT Customs Document Type"
{
    DataPerCompany = false;
    DrillDownPageID = "SAT Customs Document Types";
    LookupPageID = "SAT Customs Document Types";

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