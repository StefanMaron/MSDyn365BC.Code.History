table 99000832 "Item Availability Line"
{
    Caption = 'Item Availability Line';

    fields
    {
        field(1; "Table No."; Integer)
        {
            Caption = 'Table No.';
        }
        field(2; Name; Text[50])
        {
            Caption = 'Name';
        }
        field(3; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(5; QuerySource; Integer)
        {
            Caption = 'QuerySource';
        }
    }

    keys
    {
        key(Key1; Name, QuerySource)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

