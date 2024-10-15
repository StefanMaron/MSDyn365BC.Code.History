table 1751 "Data Class. Notif. Setup"
{
    Caption = 'Data Class. Notif. Setup';
    ObsoleteReason = 'Functionality moved on My Notifications.';
    ObsoleteState = Removed;
    ObsoleteTag = '18.0';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "USER ID"; Guid)
        {
            Caption = 'USER ID';
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(2; "Show Notifications"; Boolean)
        {
            Caption = 'Show Notifications';
        }
    }

    keys
    {
        key(Key1; "USER ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

