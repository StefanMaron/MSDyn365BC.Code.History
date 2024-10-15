namespace System.Privacy;

table 9190 "Terms And Conditions"
{
    Caption = 'Terms And Conditions';
    DataPerCompany = false;
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(2; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(3; "Valid From"; Date)
        {
            Caption = 'Valid From';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

