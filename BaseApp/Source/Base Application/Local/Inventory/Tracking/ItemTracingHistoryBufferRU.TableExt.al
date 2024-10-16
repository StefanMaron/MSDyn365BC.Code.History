namespace Microsoft.Inventory.Tracking;

tableextension 14956 "Item Tracing History Buffer RU" extends "Item Tracing History Buffer"
{
    fields
    {
        field(14900; "CD No. Filter"; Code[250])
        {
            Caption = 'CD No. Filter';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Replaced by W1 field Package No. Filter.';
            ObsoleteState = Removed;
            ObsoleteTag = '21.0';
        }
    }
}