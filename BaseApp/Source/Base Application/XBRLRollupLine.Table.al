table 398 "XBRL Rollup Line"
{
    Caption = 'XBRL Rollup Line';

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
        field(4; "From XBRL Taxonomy Line No."; Integer)
        {
            Caption = 'From XBRL Taxonomy Line No.';
            TableRelation = "XBRL Taxonomy Line"."Line No." WHERE("XBRL Taxonomy Name" = FIELD("XBRL Taxonomy Name"));
        }
        field(5; "From XBRL Taxonomy Line Name"; Text[250])
        {
            CalcFormula = Lookup ("XBRL Taxonomy Line".Name WHERE("XBRL Taxonomy Name" = FIELD("XBRL Taxonomy Name"),
                                                                  "Line No." = FIELD("From XBRL Taxonomy Line No.")));
            Caption = 'From XBRL Taxonomy Line Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "From XBRL Taxonomy Line Label"; Text[250])
        {
            CalcFormula = Lookup ("XBRL Taxonomy Label".Label WHERE("XBRL Taxonomy Name" = FIELD("XBRL Taxonomy Name"),
                                                                    "XBRL Taxonomy Line No." = FIELD("From XBRL Taxonomy Line No."),
                                                                    "XML Language Identifier" = FIELD("Label Language Filter")));
            Caption = 'From XBRL Taxonomy Line Label';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8; Weight; Decimal)
        {
            Caption = 'Weight';
            DecimalPlaces = 0 : 0;
            MaxValue = 1;
            MinValue = -1;
        }
        field(9; "Label Language Filter"; Text[10])
        {
            Caption = 'Label Language Filter';
            FieldClass = FlowFilter;
        }
    }

    keys
    {
        key(Key1; "XBRL Taxonomy Name", "XBRL Taxonomy Line No.", "From XBRL Taxonomy Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

