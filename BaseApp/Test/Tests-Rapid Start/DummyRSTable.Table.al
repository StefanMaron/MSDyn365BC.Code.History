table 136607 DummyRSTable
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {

        }
        field(2; "Decimal Field"; Decimal)
        {

        }
        field(3; "Date Field"; Date)
        {

        }
        field(4; "Code Field"; Code[20])
        {

        }
        field(5; "Text Field"; Text[50])
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