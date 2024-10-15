namespace Microsoft.Sales.Pricing;

/// <summary>
/// The purpose of the table is to setup access to UX and logic of the sales price calculation.
/// TableType is not set to Temporary only because the ReadPermission() method always returns true.
/// </summary>
table 7015 "Sales Price Access"
{
    DataClassification = CustomerContent;

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