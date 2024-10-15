table 7826 "MS-QBO Start Sync. Service"
{
    Caption = 'MS-QBO Start Sync. Service';
    ObsoleteReason = 'replacing burntIn Extension tables with V2 Extension';
    ObsoleteState = Removed;
    ObsoleteTag = '18.0';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "OAuth Token Key"; Text[250])
        {
            Caption = 'OAuth Token Key';
        }
        field(2; "OAuth Token Secret"; BLOB)
        {
            Caption = 'OAuth Token Secret';
        }
        field(3; "Authorization URL"; Text[250])
        {
            Caption = 'Authorization URL';
        }
        field(4; Verifier; Text[250])
        {
            Caption = 'Verifier';
        }
        field(5; "Realm ID"; Text[250])
        {
            Caption = 'Realm ID';
        }
        field(6; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = 'Initialized,SetupComplete,Error';
            OptionMembers = Initialized,SetupComplete,Error;
        }
        field(7; "Target Application"; Option)
        {
            Caption = 'Target Application';
            OptionCaption = 'InvoicingApp,BusinessCenter,NativeInvoicingApp';
            OptionMembers = InvoicingApp,BusinessCenter,NativeInvoicingApp;
        }
    }

    keys
    {
        key(Key1; "OAuth Token Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

