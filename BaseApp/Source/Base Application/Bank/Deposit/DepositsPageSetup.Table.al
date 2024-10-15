namespace Microsoft.Bank.Deposit;

table 500 "Deposits Page Setup"
{
    DataClassification = SystemMetadata;
    ObsoleteReason = 'Pages used are the ones from the Bank Deposits extension. No other pages are provided, this table was needed when NA had it''s own pages. Open directly the required pages or run the required reports in the Bank Deposits extension.';
#if not CLEAN24
    ObsoleteState = Pending;
    ObsoleteTag = '24.0';
#else
    ObsoleteState = Removed;
    ObsoleteTag = '27.0';
#endif

    fields
    {
        field(1; Id; Enum "Deposits Page Setup Key")
        {
            DataClassification = SystemMetadata;
        }
        field(2; ObjectId; Integer)
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; Id)
        {
            Clustered = true;
        }
    }
}