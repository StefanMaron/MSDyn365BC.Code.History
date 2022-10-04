table 132583 "Amount Auto Format Test Table"
{
    ReplicateData = false;

    fields
    {
        field(1; Case10GLSetup1; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(2; Case10GLSetup2; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(3; Case10Currency1; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(4; Case10Currency2; Decimal)
        {
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(Case10GLSetup1; Case10GLSetup1)
        {
            Clustered = true;
        }
    }
}