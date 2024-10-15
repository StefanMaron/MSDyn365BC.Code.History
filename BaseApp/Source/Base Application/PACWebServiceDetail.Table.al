table 10001 "PAC Web Service Detail"
{
    Caption = 'PAC Web Service Detail';

    fields
    {
        field(1; "PAC Code"; Code[10])
        {
            Caption = 'PAC Code';
            TableRelation = "PAC Web Service".Code;
        }
        field(2; Environment; Option)
        {
            Caption = 'Environment';
            OptionCaption = ' ,Test,Production';
            OptionMembers = " ",Test,Production;
        }
        field(3; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Request Stamp,Cancel,Cancel Request';
            OptionMembers = "Request Stamp",Cancel,CancelRequest;
        }
        field(21; "Method Name"; Text[50])
        {
            Caption = 'Method Name';
        }
        field(22; Address; Text[250])
        {
            Caption = 'Address';
        }
    }

    keys
    {
        key(Key1; "PAC Code", Environment, Type)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

