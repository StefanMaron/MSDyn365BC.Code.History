table 7800 "MS-Event Emitter Event Codes"
{
    Caption = 'MS-Event Emitter Event Codes';
    DataPerCompany = false;
    ObsoleteReason = 'Deprecated';
    ObsoleteState = Pending;
    ObsoleteTag = '15.0';

    fields
    {
        field(1; "Event Name"; Text[250])
        {
            Caption = 'Event Name';
        }
        field(2; "No of Required Triggers"; Integer)
        {
            Caption = 'No of Required Triggers';
        }
    }

    keys
    {
        key(Key1; "Event Name")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

