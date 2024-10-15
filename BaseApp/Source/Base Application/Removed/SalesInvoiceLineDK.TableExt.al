tableextension 13688 "Sales Invoice Line DK" extends "Sales Invoice Line"
{
    fields
    {
        field(13600; "Account Code"; Text[30])
        {
            Caption = 'Account Code';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Moved to OIOUBL extension, the same table, same field name prefixed with OIOUBL-.';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
        }
    }
}