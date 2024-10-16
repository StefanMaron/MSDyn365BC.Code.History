namespace Microsoft.Inventory.Tracking;

tableextension 14958 "Package No. Information RU" extends "Package No. Information"
{
    fields
    {
#pragma warning disable AS0072
        field(9; "CD Header No."; Code[30])
        {
            Caption = 'CD Header No.';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Moved to CD Tracking extension field.';
            ObsoleteState = Removed;
            ObsoleteTag = '18.0';
        }
        field(11; "Temporary CD No."; Boolean)
        {
            Caption = 'Temporary CD No.';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Moved to CD Tracking extension field.';
            ObsoleteState = Removed;
            ObsoleteTag = '18.0';
        }
#pragma warning restore AS0072
        field(40; "Current No."; Code[6])
        {
            Caption = 'Current No.';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Not used.';
#if not CLEAN25
            ObsoleteState = Pending;
            ObsoleteTag = '25.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '28.0';
#endif            
        }
    }
}