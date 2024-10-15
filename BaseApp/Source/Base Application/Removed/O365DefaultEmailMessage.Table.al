table 2170 "O365 Default Email Message"
{
    Caption = 'O365 Default Email Message';
    ReplicateData = false;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Removed;
    ObsoleteTag = '24.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = 'Quote,Invoice';
            OptionMembers = Quote,Invoice;
        }
        field(10; Value; BLOB)
        {
            Caption = 'Value';
        }
    }

    keys
    {
        key(Key1; "Document Type")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

