table 13600 "OIOUBL Profile"
{
    Caption = 'OIOUBL Profile';
    ObsoleteReason = 'Moved to OIOUBL extension, new table OIOUBL-Profile.';
    ObsoleteState = Removed;
    ObsoleteTag = '15.0';
    ReplicateData = false;
    
    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Moved to OIOUBL extension, new table OIOUBL-Profile.';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
        }
        field(2; "Profile ID"; Text[50])
        {
            Caption = 'Profile ID';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Moved to OIOUBL extension, new table OIOUBL-Profile.';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
            ObsoleteReason = 'Moved to OIOUBL extension, new table OIOUBL-Profile.';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
        }
    }

    fieldgroups
    {
        fieldgroup(AllFields; "Code", "Profile ID")
        {
        }
    }
}

