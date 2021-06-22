table 921 "Item Turnover Buffer"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(5; "Period Type"; Option)
        {
            Caption = 'Period Type';
            OptionMembers = Day,Week,Month,Quarter,Year,Period;
            DataClassification = SystemMetadata;
        }
        field(6; "Period Name"; Text[50])
        {
            Caption = 'Period Name';
            DataClassification = SystemMetadata;
        }
        field(7; "Period Start"; Date)
        {
            Caption = 'Period Start';
            DataClassification = SystemMetadata;
        }
        field(8; "Period End"; Date)
        {
            Caption = 'Period End';
            DataClassification = SystemMetadata;
        }
        field(10; "Purchases (Qty.)"; Decimal)
        {
            Caption = 'Purchases (Qty.)';
            DataClassification = SystemMetadata;
        }
        field(11; "Purchases (LCY)"; Decimal)
        {
            Caption = 'Purchases (LCY)';
            DataClassification = SystemMetadata;
        }
        field(12; "Sales (Qty.)"; Decimal)
        {
            Caption = 'Sales (Qty.)';
            DataClassification = SystemMetadata;
        }
        field(13; "Sales (LCY)"; Decimal)
        {
            Caption = 'Sales (LCY)';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Period Type", "Period Start")
        {
            Clustered = true;
        }
    }
}