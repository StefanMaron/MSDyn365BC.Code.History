table 31102 "VAT Control Report Section"
{
    Caption = 'VAT Control Report Section';
    DrillDownPageID = "VAT Control Report Sections";
    LookupPageID = "VAT Control Report Sections";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.0';

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(3; "Group By"; Option)
        {
            Caption = 'Group By';
            OptionCaption = 'Document No.,External Document No.,Section Code';
            OptionMembers = "Document No.","External Document No.","Section Code";
        }
        field(10; "Simplified Tax Doc. Sect. Code"; Code[20])
        {
            Caption = 'Simplified Tax Doc. Sect. Code';
            TableRelation = "VAT Control Report Section".Code;
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

