table 5204 Relative
{
    Caption = 'Relative';
    DrillDownPageID = Relatives;
    LookupPageID = Relatives;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(17400; "Relative Type"; Option)
        {
            Caption = 'Relative Type';
            OptionCaption = ' ,Child,Wife,Husband,Mother,Father';
            OptionMembers = " ",Child,Wife,Husband,Mother,Father;
        }
        field(17401; "OKIN Code"; Code[10])
        {
            Caption = 'OKIN Code';
            TableRelation = "Classificator OKIN".Code WHERE(Group = CONST('11'));
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

