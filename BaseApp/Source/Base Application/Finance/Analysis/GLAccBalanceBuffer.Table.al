namespace Microsoft.Finance.Analysis;

table 926 "G/L Acc. Balance Buffer"
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
        field(11762; "Net Change (VAT Date)"; Decimal)
        {
            Caption = 'Net Change (VAT Date)';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'The functionality will be removed and this field should not be used.';
            ObsoleteState = Removed;
            ObsoleteTag = '23.0';
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