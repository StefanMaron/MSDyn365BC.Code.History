table 7825 "MS-QBO Synchronization Error"
{
    Caption = 'MS-QBO Synchronization Error';
    ObsoleteReason = 'replacing burntIn Extension tables with V2 Extension';
    ObsoleteState = Removed;
    ObsoleteTag = '18.0';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; ID; Integer)
        {
            AutoIncrement = true;
            Caption = 'ID';
        }
        field(2; "Log Time"; DateTime)
        {
            Caption = 'Log Time';
        }
        field(21; "Error Message"; Text[250])
        {
            Caption = 'Error Message';
        }
        field(22; "Error Message 2"; Text[250])
        {
            Caption = 'Error Message 2';
        }
        field(23; "Error Message 3"; Text[250])
        {
            Caption = 'Error Message 3';
        }
        field(24; "Error Message 4"; Text[250])
        {
            Caption = 'Error Message 4';
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
        key(Key2; "Log Time")
        {
        }
    }

    fieldgroups
    {
    }
}

