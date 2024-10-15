table 27038 "SAT Transfer Reason"
{
    DataPerCompany = false;
    DrillDownPageID = "SAT Transfer Reasons";
    LookupPageID = "SAT Transfer Reasons";

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