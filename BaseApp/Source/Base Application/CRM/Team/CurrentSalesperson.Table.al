namespace Microsoft.CRM.Team;

table 5124 "Current Salesperson"
{
    Caption = 'Current Salesperson';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
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

