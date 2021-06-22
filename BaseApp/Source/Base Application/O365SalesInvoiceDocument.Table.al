table 2200 "O365 Sales Invoice Document"
{
    Caption = 'O365 Sales Invoice Document';
    ReplicateData = false;

    fields
    {
        field(1; InvoiceId; Guid)
        {
            Caption = 'InvoiceId';
        }
        field(2; Base64; BLOB)
        {
            Caption = 'Base64';
        }
        field(3; Message; Text[250])
        {
            Caption = 'Message';
        }
        field(4; Binary; BLOB)
        {
            Caption = 'Binary';
        }
    }

    keys
    {
        key(Key1; InvoiceId)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

