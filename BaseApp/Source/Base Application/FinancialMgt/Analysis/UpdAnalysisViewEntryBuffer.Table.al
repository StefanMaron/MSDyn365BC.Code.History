namespace Microsoft.Finance.Analysis;

table 2151 "Upd Analysis View Entry Buffer"
{
    TableType = Temporary;

    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Integer)
        {
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }
        field(2; AccNo; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(3; BusUnitCode; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(4; CashFlowForecastNo; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(5; DimValue1; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(6; DimValue2; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(7; DimValue3; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(8; DimValue4; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(9; PostingDate; Date)
        {
            DataClassification = CustomerContent;
        }
        field(10; Amount; Decimal)
        {
            DataClassification = CustomerContent;
        }
        field(11; DebitAmount; Decimal)
        {
            DataClassification = CustomerContent;
        }
        field(12; CreditAmount; Decimal)
        {
            DataClassification = CustomerContent;
        }
        field(13; AmountACY; Decimal)
        {
            DataClassification = CustomerContent;
        }
        field(14; DebitAmountACY; Decimal)
        {
            DataClassification = CustomerContent;
        }
        field(15; CreditAmountACY; Decimal)
        {
            DataClassification = CustomerContent;
        }
        field(16; EntryNo; Integer)
        {
            DataClassification = CustomerContent;
        }
        field(17; "Account Source"; Enum "Analysis Account Source")
        {
            Caption = 'Account Source';
        }
    }
    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }
}