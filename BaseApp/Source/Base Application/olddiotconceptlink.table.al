table 27041 "DIOT-Concept Link"
{
    Caption = 'DIOT Concept Link';
    ObsoleteReason = 'Moved to extension';
    ObsoleteState = Removed;
    ObsoleteTag = '15.0';

    fields
    {
        field(1; "DIOT Concept No."; Integer)
        {
        }
        field(2; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Product Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        field(3; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Business Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
    }

    keys
    {
        key(Key1; "DIOT Concept No.", "VAT Prod. Posting Group", "VAT Bus. Posting Group")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

