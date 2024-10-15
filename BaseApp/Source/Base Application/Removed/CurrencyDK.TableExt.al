tableextension 13668 "Currency DK" extends Currency
{
    fields
    {
        field(13600; "OIOUBL Currency Code"; Code[10])
        {
            Caption = 'OIOUBL Currency Code';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Moved to OIOUBL extension, the same table, same field name prefixed with OIOUBL-.';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
        }
    }
}