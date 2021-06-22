table 143 "ECSL VAT Report Line Relation"
{
    Caption = 'ECSL VAT Report Line Relation';

    fields
    {
        field(1; "VAT Entry No."; Integer)
        {
            Caption = 'VAT Entry No.';
        }
        field(2; "ECSL Line No."; Integer)
        {
            Caption = 'ECSL Line No.';
        }
        field(3; "ECSL Report No."; Code[20])
        {
            Caption = 'ECSL Report No.';
        }
    }

    keys
    {
        key(Key1; "VAT Entry No.", "ECSL Line No.", "ECSL Report No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

