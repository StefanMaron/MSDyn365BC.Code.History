table 6670 "Returns-Related Document"
{
    Caption = 'Returns-Related Document';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = 'Sales Order,Sales Invoice,Sales Return Order,Sales Credit Memo,Purchase Order,Purchase Invoice,Purchase Return Order,Purchase Credit Memo';
            OptionMembers = "Sales Order","Sales Invoice","Sales Return Order","Sales Credit Memo","Purchase Order","Purchase Invoice","Purchase Return Order","Purchase Credit Memo";
        }
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

