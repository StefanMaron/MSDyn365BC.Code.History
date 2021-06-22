table 6304 "Power BI User Configuration"
{
    Caption = 'Power BI User Configuration';
    ReplicateData = false;

    fields
    {
        field(1; "Page ID"; Text[50])
        {
            Caption = 'Page ID';
        }
        field(2; "User Security ID"; Guid)
        {
            Caption = 'User Security ID';
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(3; "Profile ID"; Code[30])
        {
            Caption = 'Profile ID';
        }
        field(4; "Report Visibility"; Boolean)
        {
            Caption = 'Report Visibility';
        }
        field(5; "Selected Report ID"; Guid)
        {
            Caption = 'Selected Report ID';
        }
    }

    keys
    {
        key(Key1; "Page ID", "User Security ID", "Profile ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

