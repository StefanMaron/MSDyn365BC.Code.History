table 12197 "Document Relation"
{
    Caption = 'Document Relation';

    fields
    {
        field(1; "Credit Memo No."; Code[20])
        {
            Caption = 'Credit Memo No.';
        }
        field(2; "Invoice No."; Code[20])
        {
            Caption = 'Invoice No.';
        }
        field(3; "VAT Report Line No."; Integer)
        {
            Caption = 'VAT Report Line No.';
        }
        field(6; "Invoice Date"; Date)
        {
            Caption = 'Invoice Date';
        }
        field(7; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = ' ,Purchase,Sale';
            OptionMembers = " ",Purchase,Sale;
        }
    }

    keys
    {
        key(Key1; Type, "Credit Memo No.", "Invoice No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

