namespace Microsoft.Inventory.Ledger;

table 6508 "Value Entry Relation"
{
    Caption = 'Value Entry Relation';

    fields
    {
        field(1; "Value Entry No."; Integer)
        {
            Caption = 'Value Entry No.';
            TableRelation = "Value Entry";
        }
        field(11; "Source RowId"; Text[250])
        {
            Caption = 'Source RowId';
        }
    }

    keys
    {
        key(Key1; "Value Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Source RowId")
        {
        }
    }

    fieldgroups
    {
    }
}

