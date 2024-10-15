tableextension 13667 "Country/Region DK" extends "Country/Region"
{
    fields
    {
        field(13600; "OIOUBL Country/Region Code"; Code[10])
        {
            Caption = 'OIOUBL Country/Region Code';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Moved to OIOUBL extension, the same table, same field name prefixed with OIOUBL-.';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
        }
    }
} 