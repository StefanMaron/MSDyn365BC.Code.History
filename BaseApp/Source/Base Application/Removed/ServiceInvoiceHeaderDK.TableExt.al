tableextension 13695 "Service Invoice Header DK" extends "Service Invoice Header"
{
    fields
    {
        field(13600; "EAN No."; Code[13])
        {
            Caption = 'EAN No.';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Moved to OIOUBL extension, the same table, same field name prefixed with OIOUBL-.';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
        }
        field(13601; "Account Code"; Text[30])
        {
            Caption = 'Account Code';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Moved to OIOUBL extension, the same table, same field name prefixed with OIOUBL-.';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
        }
        field(13602; "Electronic Invoice Created"; Boolean)
        {
            Caption = 'Electronic Invoice Created';
            DataClassification = SystemMetadata;
            Editable = false;
            ObsoleteReason = 'Moved to OIOUBL extension, the same table, same field name prefixed with OIOUBL-.';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
        }
        field(13604; "OIOUBL Profile Code"; Code[10])
        {
            Caption = 'OIOUBL Profile Code';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Moved to OIOUBL extension, the same table, same field name prefixed with OIOUBL-.';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
        }
        field(13608; "Contact Role"; Option)
        {
            Caption = 'Contact Role';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Moved to OIOUBL extension, the same table, same field name prefixed with OIOUBL-.';
            ObsoleteState = Removed;
            OptionCaption = ' ,,,Purchase Responsible,,,Accountant,,,Budget Responsible,,,Requisitioner';
            OptionMembers = " ",,,"Purchase Responsible",,,Accountant,,,"Budget Responsible",,,Requisitioner;
            ObsoleteTag = '15.0';
        }
        field(13620; "Payment Channel"; Option)
        {
            Caption = 'Payment Channel';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Deprecated.';
            ObsoleteState = Removed;
            OptionCaption = ' ,Payment Slip,Account Transfer,National Clearing,Direct Debit';
            OptionMembers = " ","Payment Slip","Account Transfer","National Clearing","Direct Debit";
            ObsoleteTag = '15.0';
        }
    }
}