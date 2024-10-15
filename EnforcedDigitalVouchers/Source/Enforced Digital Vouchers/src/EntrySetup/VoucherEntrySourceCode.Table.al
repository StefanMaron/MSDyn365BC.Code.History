table 5580 "Voucher Entry Source Code"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry Type"; Enum "Digital Voucher Entry Type")
        {
        }
        field(2; "Source Code"; Code[10])
        {
            TableRelation = "Source Code";
        }
    }

    keys
    {
        key(PK; "Entry Type", "Source Code")
        {
            Clustered = true;
        }
    }
}
