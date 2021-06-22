table 463 "Shipment Method Translation"
{
    Caption = 'Shipment Method Translation';

    fields
    {
        field(1; "Shipment Method"; Code[10])
        {
            Caption = 'Shipment Method';
            TableRelation = "Shipment Method";
        }
        field(2; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Shipment Method", "Language Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

