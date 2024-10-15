namespace Microsoft.Finance.Analysis;

table 927 "Receivables-Payables Buffer"
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
        field(10; "Cust. Balances Due"; Decimal)
        {
            Caption = 'Cust. Balances Due';
            DataClassification = SystemMetadata;
        }
        field(11; "Vendor Balances Due"; Decimal)
        {
            Caption = 'Vendor Balances Due';
            DataClassification = SystemMetadata;
        }
        field(12; "Receivables-Payables"; Decimal)
        {
            Caption = 'Receivables-Payables';
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