table 2156 "O365 Payment Instr. Transl."
{
    Caption = 'O365 Payment Instr. Transl.';
    ReplicateData = false;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Removed;
    ObsoleteTag = '24.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer)
        {
            Caption = 'Id';
            DataClassification = SystemMetadata;
        }
        field(3; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            DataClassification = SystemMetadata;
        }
        field(5; "Transl. Name"; Text[20])
        {
            Caption = 'Transl. Name';
        }
        field(6; "Transl. Payment Instructions"; Text[250])
        {
            Caption = 'Transl. Payment Instructions';
        }
        field(7; "Transl. Payment Instr. Blob"; BLOB)
        {
            Caption = 'Transl. Payment Instr. Blob';
        }
    }

    keys
    {
        key(Key1; Id, "Language Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

