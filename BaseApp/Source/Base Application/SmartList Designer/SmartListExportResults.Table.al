table 9888 "SmartList Export Results"
{
    DataClassification = SystemMetadata;
    Extensible = false;
    Scope = OnPrem;
    Access = Public;
#if not CLEAN19
    ObsoleteState = Pending;
    ObsoleteTag = '19.0';
#else
    ObsoleteState = Removed;
    ObsoleteTag = '22.0';
#endif
    ObsoleteReason = 'The SmartList Designer is not supported in Business Central.';

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
