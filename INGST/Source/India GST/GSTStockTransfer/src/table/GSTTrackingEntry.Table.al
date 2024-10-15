table 18390 "GST Tracking Entry"
{
    fields
    {
        field(18390; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18391; "From Entry No."; Integer)
        {
            Caption = 'From Entry No.';
            TableRelation = "Detailed GST Ledger Entry";
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18392; "From To No."; Integer)
        {
            Caption = 'From To No.';
            TableRelation = "Detailed GST Ledger Entry";
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18393; "Item Ledger Entry No."; Integer)
        {
            Caption = 'Item Ledger Entry No.';
            TableRelation = "Item Ledger Entry";
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18394; "Quantity"; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18395; "Remaining Quantity"; Decimal)
        {
            Caption = 'Remaining Quantity';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
    }
    keys
    {
        Key(PK; "Entry No.")
        {
        }
    }
}