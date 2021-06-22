table 9889 "SmartList Import Results"
{
    DataClassification = SystemMetadata;
    Extensible = false;
    Scope = OnPrem;

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