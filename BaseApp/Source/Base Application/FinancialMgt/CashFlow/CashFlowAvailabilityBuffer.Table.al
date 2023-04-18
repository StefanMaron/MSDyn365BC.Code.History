table 930 "Cash Flow Availability Buffer"
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
        field(10; Receivables; Decimal)
        {
            Caption = 'Receivables';
            DataClassification = SystemMetadata;
        }
        field(11; "Sales Orders"; Decimal)
        {
            Caption = 'Sales Orders';
            DataClassification = SystemMetadata;
        }
        field(12; "Service Orders"; Decimal)
        {
            Caption = 'Service Orders';
            DataClassification = SystemMetadata;
        }
        field(13; "Fixed Assets Disposal"; Decimal)
        {
            Caption = 'Fixed Assets Disposal';
            DataClassification = SystemMetadata;
        }
        field(14; "Cash Flow Manual Revenues"; Decimal)
        {
            Caption = 'Cash Flow Manual Revenues';
            DataClassification = SystemMetadata;
        }
        field(15; Payables; Decimal)
        {
            Caption = 'Payables';
            DataClassification = SystemMetadata;
        }
        field(16; "Purchase Orders"; Decimal)
        {
            Caption = 'Purchase Orders';
            DataClassification = SystemMetadata;
        }
        field(17; "Fixed Assets Budget"; Decimal)
        {
            Caption = 'Fixed Assets Budget';
            DataClassification = SystemMetadata;
        }
        field(18; "Cash Flow Manual Expenses"; Decimal)
        {
            Caption = 'Cash Flow Manual Expenses';
            DataClassification = SystemMetadata;
        }
        field(19; "G/L Budget"; Decimal)
        {
            Caption = 'G/L Budget';
            DataClassification = SystemMetadata;
        }
        field(20; Job; Decimal)
        {
            Caption = 'Job';
            DataClassification = SystemMetadata;
        }
        field(21; Tax; Decimal)
        {
            Caption = 'Tax';
            DataClassification = SystemMetadata;
        }
        field(22; Total; Decimal)
        {
            Caption = 'Total';
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