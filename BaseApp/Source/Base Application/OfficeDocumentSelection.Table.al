table 1620 "Office Document Selection"
{
    Caption = 'Office Document Selection';

    fields
    {
        field(1; Series; Option)
        {
            Caption = 'Series';
            OptionCaption = 'Sales,Purchase';
            OptionMembers = Sales,Purchase;
        }
        field(2; "Document Type"; Option)
        {
            Caption = 'Document Type';
            Description = 'Type of the referenced document.';
            OptionCaption = 'Quote,Order,Invoice,Credit Memo,Blanket Order,Return Order';
            OptionMembers = Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order";
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Description = 'No. of the referenced document.';
        }
        field(4; Posted; Boolean)
        {
            Caption = 'Posted';
        }
        field(5; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
    }

    keys
    {
        key(Key1; Series, "Document Type", "Document No.", Posted)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

