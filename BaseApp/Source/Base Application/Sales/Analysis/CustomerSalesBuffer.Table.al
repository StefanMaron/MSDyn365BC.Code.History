namespace Microsoft.Sales.Analysis;

table 923 "Customer Sales Buffer"
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
        field(10; "Balance Due (LCY)"; Decimal)
        {
            Caption = 'Balance Due (LCY)';
            DataClassification = SystemMetadata;
        }
        field(11; "Sales (LCY)"; Decimal)
        {
            Caption = 'Sales (LCY)';
            DataClassification = SystemMetadata;
        }
        field(12; "Profit (LCY)"; Decimal)
        {
            Caption = 'Profit (LCY)';
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