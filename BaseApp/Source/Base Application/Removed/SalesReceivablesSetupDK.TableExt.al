tableextension 13691 "Sales & Receivables Setup DK" extends "Sales & Receivables Setup"
{
    fields
    {
        field(13600; "OIOUBL Invoice Path"; Text[250])
        {
            Caption = 'OIOUBL Invoice Path';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Moved to OIOUBL extension, the same table, same field name prefixed with OIOUBL-.';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
        }
        field(13601; "OIOUBL Cr. Memo Path"; Text[250])
        {
            Caption = 'OIOUBL Cr. Memo Path';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Moved to OIOUBL extension, the same table, same field name prefixed with OIOUBL-.';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
        }
        field(13602; "OIOUBL Reminder Path"; Text[250])
        {
            Caption = 'OIOUBL Reminder Path';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Moved to OIOUBL extension, the same table, same field name prefixed with OIOUBL-.';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
        }
        field(13603; "OIOUBL Fin. Chrg. Memo Path"; Text[250])
        {
            Caption = 'OIOUBL Fin. Chrg. Memo Path';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Moved to OIOUBL extension, the same table, same field name prefixed with OIOUBL-.';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
        }
        field(13604; "Default OIOUBL Profile Code"; Code[10])
        {
            Caption = 'Default OIOUBL Profile Code';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Moved to OIOUBL extension, the same table, same field name prefixed with OIOUBL-.';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
        }
    }
}