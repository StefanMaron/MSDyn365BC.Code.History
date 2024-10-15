table 11779 "VAT Attribute Code"
{
    Caption = 'VAT Attribute Code';
    ObsoleteState = Removed;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '20.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(3; "XML Code"; Code[20])
        {
            Caption = 'XML Code';
        }
        field(4; "VAT Statement Template Name"; Code[10])
        {
            Caption = 'VAT Statement Template Name';
        }
        field(5; Coefficient; Boolean)
        {
            Caption = 'Coefficient';
        }
    }

    keys
    {
        key(Key1; "VAT Statement Template Name", "Code")
        {
            Clustered = true;
        }
        key(Key2; "XML Code")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Description)
        {
        }
    }
}
