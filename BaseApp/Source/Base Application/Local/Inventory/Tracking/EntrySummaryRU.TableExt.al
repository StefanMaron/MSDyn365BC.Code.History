namespace Microsoft.Inventory.Tracking;

tableextension 14953 "Entry Summary RU" extends "Entry Summary"
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
        field(14901; "Lot/CD Exists"; Boolean)
        {
            Caption = 'Lot/CD Exists';
            DataClassification = SystemMetadata;
            Editable = false;
            ObsoleteReason = 'Replaced by W1 field Non Serial Tracking.';
            ObsoleteState = Removed;
            ObsoleteTag = '21.0';
        }
    }
}