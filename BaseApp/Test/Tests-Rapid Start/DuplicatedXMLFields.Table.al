table 136606 DuplicatedXMLFields
{
    DataClassification = SystemMetadata;
    ReplicateData = false;

    fields
    {
        field(1; "Entry No."; Integer)
        {

        }
        field(2; "Indirect Amount %"; Decimal)
        {

        }
        field(3; "Indirect (Amount) %"; Decimal)
        {

        }
        field(4; "Indirect Amount"; Decimal)
        {

        }
        field(5; "<Indirect %> Amount"; Decimal)
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