namespace Microsoft.Inventory.Tracking;

tableextension 14957 "Item Tracking Code RU" extends "Item Tracking Code"
{
    fields
    {
        field(14910; "CD Specific Tracking"; Boolean)
        {
            Caption = 'CD Specific Tracking';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Replaced by field Package Specific Tracking.';
            ObsoleteState = Removed;
            ObsoleteTag = '21.0';
        }
        field(14913; "CD Warehouse Tracking"; Boolean)
        {
            Caption = 'CD Warehouse Tracking';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Replaced by field Package Warehouse Tracking.';
            ObsoleteState = Removed;
            ObsoleteTag = '21.0';
        }
    }
}