table 17371 "Position View Buffer"
{
    Caption = 'Position View Buffer';

    fields
    {
        field(1; ID; Integer)
        {
            Caption = 'ID';
            DataClassification = SystemMetadata;
        }
        field(2; "Position No."; Code[20])
        {
            Caption = 'Position No.';
            DataClassification = SystemMetadata;
            TableRelation = Position;
        }
        field(3; "Manager No."; Code[20])
        {
            Caption = 'Manager No.';
            DataClassification = SystemMetadata;
            TableRelation = Position;
        }
        field(10; Hide; Boolean)
        {
            Caption = 'Hide';
            DataClassification = SystemMetadata;
        }
        field(11; Expanded; Boolean)
        {
            Caption = 'Expanded';
            DataClassification = SystemMetadata;
        }
        field(12; Level; Integer)
        {
            Caption = 'Level';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
        key(Key2; "Manager No.", ID)
        {
        }
    }

    fieldgroups
    {
    }
}

