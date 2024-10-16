namespace Microsoft.Inventory.Tracking;

tableextension 14951 "Tracking Specification RU" extends "Tracking Specification"
{
    fields
    {
        field(14900; "CD No."; Code[50])
        {
            Caption = 'CD No.';
            DataClassification = CustomerContent;
            ObsoleteReason = 'Replaced by field Package No.';
            ObsoleteState = Removed;
            ObsoleteTag = '21.0';
        }
        field(14901; "New CD No."; Code[30])
        {
            Caption = 'New CD No.';
            DataClassification = CustomerContent;
            ObsoleteReason = 'Replaced by field New Package No.';
            ObsoleteState = Removed;
            ObsoleteTag = '21.0';
        }
    }
}