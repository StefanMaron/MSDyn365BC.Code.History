table 31043 "SKP Code"
{
    Caption = 'SKP Code';
    ObsoleteState = Removed;
    ObsoleteReason = 'The functionality of Fixed Assets Clasification by SKP codes will be removed and this table should not be used. (Obsolete::Removed in release 01.2021)';
    ObsoleteTag = '18.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[200])
        {
            Caption = 'Description';
        }
        field(3; "Depreciation Group"; Text[10])
        {
            Caption = 'Depreciation Group';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

