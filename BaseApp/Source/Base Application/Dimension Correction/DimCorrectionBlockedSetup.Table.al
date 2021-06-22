table 2580 "Dim Correction Blocked Setup"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Dimension Code"; Code[20])
        {
            DataClassification = CustomerContent;
            TableRelation = Dimension.Code;
        }
    }

    keys
    {
        key(Key1; "Dimension Code")
        {
            Clustered = true;
        }
    }
}