table 9889 "SmartList Import Results"
{
    DataClassification = SystemMetadata;
    Extensible = false;
    Scope = OnPrem;
    Access = Public;
    ObsoleteState = Removed;
    ObsoleteTag = '22.0';
    ObsoleteReason = 'The SmartList Designer is not supported in Business Central.';
    ReplicateData = false;

    fields
    {
        field(1; Name; Text[30])
        {
            DataClassification = SystemMetadata;
        }
        field(2; Success; Boolean)
        {
            DataClassification = SystemMetadata;
        }
        field(3; Errors; Text[2048])
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; Name)
        {
        }
        key(ForListSorting; Success)
        {
            MaintainSqlIndex = false;
        }
    }
}