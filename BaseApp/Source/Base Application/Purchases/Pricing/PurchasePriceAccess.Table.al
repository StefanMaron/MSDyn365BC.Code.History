namespace Microsoft.Purchases.Pricing;

/// <summary>
/// The purpose of the table is to setup access to UX and logic of the purchase price calculation.
/// TableType is not set to Temporary only because the ReadPermission() method always returns true.
/// </summary>
table 7017 "Purchase Price Access"
{
    fields
    {
        field(1; Code; Code[20])
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; Code)
        {
            Clustered = true;
        }
    }
}