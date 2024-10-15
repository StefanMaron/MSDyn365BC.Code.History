namespace System.Reflection;

table 7800 "MS-Event Emitter Event Codes"
{
    Caption = 'MS-Event Emitter Event Codes';
    DataPerCompany = false;
    ObsoleteReason = 'Deprecated';
    ObsoleteState = Removed;
    ObsoleteTag = '18.0';
    ReplicateData = false;
    DataClassification = CustomerContent;

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

