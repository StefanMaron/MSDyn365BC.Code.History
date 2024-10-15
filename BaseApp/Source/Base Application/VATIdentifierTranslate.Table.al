table 11768 "VAT Identifier Translate"
{
    Caption = 'VAT Identifier Translate';
    DataCaptionFields = "VAT Identifier Code";
    ObsoleteState = Removed;
    ObsoleteReason = 'The enhanced functionality of VAT Identifier will be removed and this table should not be used. (Obsolete::Removed in release 01.2021)';
    ObsoleteTag = '18.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "VAT Identifier Code"; Code[20])
        {
            Caption = 'VAT Identifier Code';
            NotBlank = true;
        }
        field(2; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            NotBlank = true;
            TableRelation = Language;
        }
        field(10; Description; Text[80])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "VAT Identifier Code", "Language Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

