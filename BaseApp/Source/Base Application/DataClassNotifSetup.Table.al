table 1751 "Data Class. Notif. Setup"
{
    Caption = 'Data Class. Notif. Setup';
    ObsoleteReason = 'Functionality moved on My Notifications.';
    ObsoleteState = Pending;
    ObsoleteTag = '15.0';

    fields
    {
        field(1; "USER ID"; Guid)
        {
            Caption = 'USER ID';
            DataClassification = EndUserPseudonymousIdentifiers;
            ObsoleteReason = 'Functionality moved on My Notifications.';
            ObsoleteState = Pending;
            ObsoleteTag = '15.0';
        }
        field(2; "Show Notifications"; Boolean)
        {
            Caption = 'Show Notifications';
            ObsoleteReason = 'Functionality moved on My Notifications.';
            ObsoleteState = Pending;
            ObsoleteTag = '15.0';
        }
    }

    keys
    {
        key(Key1; "USER ID")
        {
            Clustered = true;
            ObsoleteReason = 'Functionality moved on My Notifications.';
            ObsoleteState = Pending;
            ObsoleteTag = '15.0';
        }
    }

    fieldgroups
    {
    }
}

