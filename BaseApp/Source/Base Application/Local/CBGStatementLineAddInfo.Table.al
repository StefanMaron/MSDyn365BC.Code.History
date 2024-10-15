table 11000006 "CBG Statement Line Add. Info."
{
    Caption = 'CBG Statement Line Add. Info.';

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            TableRelation = "Gen. Journal Template".Name;
        }
        field(2; "CBG Statement No."; Integer)
        {
            Caption = 'CBG Statement No.';
            NotBlank = true;
            TableRelation = "CBG Statement"."No." WHERE("Journal Template Name" = FIELD("Journal Template Name"));
        }
        field(3; "CBG Statement Line No."; Integer)
        {
            Caption = 'CBG Statement Line No.';
            TableRelation = "CBG Statement Line"."Line No." WHERE("Journal Template Name" = FIELD("Journal Template Name"),
                                                                   "No." = FIELD("CBG Statement No."));
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; Description; Text[80])
        {
            Caption = 'Description';
        }
        field(6; "Information Type"; Enum "CBG Statement Information Type")
        {
            Caption = 'Information Type';
        }
    }

    keys
    {
        key(Key1; "Journal Template Name", "CBG Statement No.", "CBG Statement Line No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

