tableextension 13698 "Service Mgt. Setup DK" extends "Service Mgt. Setup"
{
    fields
    {
        field(13600; "OIOUBL Service Invoice Path"; Text[250])
        {
            Caption = 'OIOUBL Service Invoice Path';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Moved to OIOUBL extension, the same table, same field name prefixed with OIOUBL-.';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
        }
        field(13601; "OIOUBL Service Cr. Memo Path"; Text[250])
        {
            Caption = 'OIOUBL Service Cr. Memo Path';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Moved to OIOUBL extension, the same table, same field name prefixed with OIOUBL-.';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
        }
    }
}