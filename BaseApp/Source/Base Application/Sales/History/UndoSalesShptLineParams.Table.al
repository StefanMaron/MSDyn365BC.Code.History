namespace Microsoft.Sales.History;

table 5825 "Undo Sales Shpt. Line Params"
{
    TableType = Temporary;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(2; "Hide Dialog"; Boolean)
        {
            Caption = 'Hide Dialog';
            DataClassification = SystemMetadata;
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