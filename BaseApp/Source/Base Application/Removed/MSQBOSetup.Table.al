table 7824 "MS-QBO Setup"
{
    Caption = 'MS-QBO Setup';
    ObsoleteReason = 'replacing burntIn Extension tables with V2 Extension';
    ObsoleteState = Removed;
    ObsoleteTag = '18.0';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Realm Id"; Text[250])
        {
            Caption = 'Realm Id';
        }
        field(3; "Token Key"; Text[250])
        {
            Caption = 'Token Key';
        }
        field(4; "Token Secret"; Text[250])
        {
            Caption = 'Token Secret';
        }
        field(5; Enabled; Boolean)
        {
            Caption = 'Enabled';
        }
        field(6; "Default Tax Code"; Text[250])
        {
            Caption = 'Default Tax Code';
        }
        field(7; "Default Country"; Code[10])
        {
            Caption = 'Default Country';
        }
        field(8; "Default Country As Option"; Option)
        {
            Caption = 'Default Country As Option';
            OptionCaption = 'Unknown,Canada,UK,USA', Locked = true;
            OptionMembers = Unknown,Canada,UK,USA;
        }
        field(9; "Default Tax Rate"; Text[250])
        {
            Caption = 'Default Tax Rate';
        }
        field(10; "Default Discount Account Id"; Text[250])
        {
            Caption = 'Default Discount Account Id';
        }
        field(11; "Default Discount Account Code"; Text[250])
        {
            Caption = 'Default Discount Account Code';
        }
        field(12; "Target Application"; Option)
        {
            Caption = 'Target Application';
            OptionCaption = 'InvoicingApp,BusinessCenter,NativeInvoicingApp';
            OptionMembers = InvoicingApp,BusinessCenter,NativeInvoicingApp;
        }
        field(13; "Access Tokens Last Fetched On"; DateTime)
        {
            Caption = 'Access Tokens Last Fetched On';
        }
        field(14; "Last Configuration Error"; Text[250])
        {
            Caption = 'Last Configuration Error';
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

