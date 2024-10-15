namespace Microsoft.Finance.Analysis;

table 922 "G/L Acc. Balance/Budget Buffer"
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
        field(10; "Debit Amount"; Decimal)
        {
            Caption = 'Debit Amount';
            DataClassification = SystemMetadata;
        }
        field(11; "Credit Amount"; Decimal)
        {
            Caption = 'Credit Amount';
            DataClassification = SystemMetadata;
        }
        field(12; "Net Change"; Decimal)
        {
            Caption = 'Net Change';
            DataClassification = SystemMetadata;
        }
        field(13; "Budgeted Debit Amount"; Decimal)
        {
            Caption = 'Budgeted Debit Amount';
            DataClassification = SystemMetadata;
        }
        field(14; "Budgeted Credit Amount"; Decimal)
        {
            Caption = 'Budgeted Credit Amount';
            DataClassification = SystemMetadata;
        }
        field(15; "Budgeted Amount"; Decimal)
        {
            Caption = 'Budgeted Amount';
            DataClassification = SystemMetadata;
        }
        field(16; "Balance/Budget Pct."; Decimal)
        {
            Caption = 'Balance/Budget (%)';
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