namespace Microsoft.Inventory.Tracking;

tableextension 14952 "Item Tracking Setup RU" extends "Item Tracking Setup"
{
    fields
    {
        field(12400; "CD No. Required"; Boolean)
        {
            Caption = 'CD No. Required';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Replaced by field Package No. Required';
            ObsoleteState = Removed;
            ObsoleteTag = '21.0';
        }
        field(12410; "CD No."; Code[50])
        {
            Caption = 'CD No.';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Replaced by field Package No.';
            ObsoleteState = Removed;
            ObsoleteTag = '21.0';
        }
        field(12420; "CD No. Info Required"; Boolean)
        {
            Caption = 'CD No. Info Required';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Replaced by field Package No. Info Required.';
            ObsoleteState = Removed;
            ObsoleteTag = '21.0';
        }
        field(12430; "CD No. Mismatch"; Boolean)
        {
            Caption = 'CD No. Mismatch';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Replaced by field Package No. Mismatch';
            ObsoleteState = Removed;
            ObsoleteTag = '21.0';
        }
    }
}