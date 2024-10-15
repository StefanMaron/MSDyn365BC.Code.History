namespace Microsoft.Finance.GeneralLedger.Account;

table 8460 "G/L Acc. Cat. Buffer"
{
    DataClassification = SystemMetadata;
    TableType = Temporary;

    fields
    {
        field(1; "Entry No."; Integer)
        {
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }
}