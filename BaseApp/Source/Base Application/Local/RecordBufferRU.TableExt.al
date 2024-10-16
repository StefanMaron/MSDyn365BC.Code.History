tableextension 12400 "Record Buffer RU" extends "Record Buffer"
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