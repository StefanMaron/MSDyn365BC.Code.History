table 401 "XBRL Taxonomy Label"
{
    Caption = 'XBRL Taxonomy Label';

    fields
    {
        field(1; "XBRL Taxonomy Name"; Code[20])
        {
            Caption = 'XBRL Taxonomy Name';
            TableRelation = "XBRL Taxonomy";
        }
        field(2; "XBRL Taxonomy Line No."; Integer)
        {
            Caption = 'XBRL Taxonomy Line No.';
            TableRelation = "XBRL Taxonomy Line"."Line No." WHERE("XBRL Taxonomy Name" = FIELD("XBRL Taxonomy Name"));
        }
        field(3; "XML Language Identifier"; Text[10])
        {
            Caption = 'XML Language Identifier';
        }
        field(4; "Windows Language ID"; Integer)
        {
            Caption = 'Windows Language ID';
        }
        field(5; "Windows Language Name"; Text[80])
        {
            CalcFormula = Lookup ("Windows Language".Name WHERE("Language ID" = FIELD("Windows Language ID")));
            Caption = 'Windows Language Name';
            FieldClass = FlowField;
        }
        field(6; Label; Text[250])
        {
            Caption = 'Label';
        }
    }

    keys
    {
        key(Key1; "XBRL Taxonomy Name", "XBRL Taxonomy Line No.", "XML Language Identifier")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

