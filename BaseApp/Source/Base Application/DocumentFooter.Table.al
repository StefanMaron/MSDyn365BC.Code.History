table 31097 "Document Footer"
{
    Caption = 'Document Footer';
    DrillDownPageID = "Document Footers";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.0';

    fields
    {
        field(1; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(2; "Footer Text"; Text[250])
        {
            Caption = 'Footer Text';
        }
    }

    keys
    {
        key(Key1; "Language Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

