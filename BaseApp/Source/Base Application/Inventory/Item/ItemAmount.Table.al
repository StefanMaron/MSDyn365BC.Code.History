namespace Microsoft.Inventory.Item;

table 268 "Item Amount"
{
    Caption = 'Item Amount';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
        }
        field(2; Amount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        field(3; "Amount 2"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount 2';
        }
    }

    keys
    {
        key(Key1; Amount, "Amount 2", "Item No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

