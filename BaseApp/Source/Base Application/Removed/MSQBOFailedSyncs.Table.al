table 7827 "MS-QBO Failed Syncs"
{
    Caption = 'MS-QBO Failed Syncs';
    ObsoleteReason = 'replacing burntIn Extension tables with V2 Extension';
    ObsoleteState = Removed;
    ObsoleteTag = '18.0';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Customer,Item,SalesInvoice';
            OptionMembers = Customer,Item,SalesInvoice;
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(3; "Short Error"; Text[250])
        {
            Caption = 'Short Error';
        }
        field(4; "Detailed Error"; BLOB)
        {
            Caption = 'Detailed Error';
        }
    }

    keys
    {
        key(Key1; Type, "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

