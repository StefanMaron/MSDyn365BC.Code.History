namespace Microsoft.Inventory.Tracking;

tableextension 14955 "Item Tracing Buffer RU" extends "Item Tracing Buffer"
{
    fields
    {
        field(14900; "CD No."; Code[50])
        {
            Caption = 'CD No.';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Replaced by field Package No.';
            ObsoleteState = Removed;
            ObsoleteTag = '21.0';
        }
    }
}