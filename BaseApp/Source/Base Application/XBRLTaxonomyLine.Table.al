table 395 "XBRL Taxonomy Line"
{
    Caption = 'XBRL Taxonomy Line';
    LookupPageID = "XBRL Taxonomy Lines";

    fields
    {
        field(1; "XBRL Taxonomy Name"; Code[20])
        {
            Caption = 'XBRL Taxonomy Name';
            NotBlank = true;
            TableRelation = "XBRL Taxonomy";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
        }
        field(3; Name; Text[220])
        {
            Caption = 'Name';
            Editable = false;
        }
        field(4; Level; Integer)
        {
            Caption = 'Level';
            Editable = false;
        }
        field(5; Label; Text[250])
        {
            CalcFormula = Lookup ("XBRL Taxonomy Label".Label WHERE("XBRL Taxonomy Name" = FIELD("XBRL Taxonomy Name"),
                                                                    "XBRL Taxonomy Line No." = FIELD("Line No."),
                                                                    "XML Language Identifier" = FIELD("Label Language Filter")));
            Caption = 'Label';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "Source Type"; Option)
        {
            Caption = 'Source Type';
            OptionCaption = 'Not Applicable,Rollup,Constant,General Ledger,Notes,Description,Tuple';
            OptionMembers = "Not Applicable",Rollup,Constant,"General Ledger",Notes,Description,Tuple;
        }
        field(7; "Constant Amount"; Decimal)
        {
            Caption = 'Constant Amount';
            DecimalPlaces = 0 : 5;
        }
        field(8; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(9; "XBRL Item Type"; Text[250])
        {
            Caption = 'XBRL Item Type';
        }
        field(10; "Parent Line No."; Integer)
        {
            Caption = 'Parent Line No.';
        }
        field(11; Information; Boolean)
        {
            CalcFormula = Exist ("XBRL Comment Line" WHERE("XBRL Taxonomy Name" = FIELD("XBRL Taxonomy Name"),
                                                           "XBRL Taxonomy Line No." = FIELD("Line No."),
                                                           "Comment Type" = CONST(Information)));
            Caption = 'Information';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12; Rollup; Boolean)
        {
            CalcFormula = Exist ("XBRL Rollup Line" WHERE("XBRL Taxonomy Name" = FIELD("XBRL Taxonomy Name"),
                                                          "XBRL Taxonomy Line No." = FIELD("Line No.")));
            Caption = 'Rollup';
            Editable = false;
            FieldClass = FlowField;
        }
        field(13; "G/L Map Lines"; Boolean)
        {
            CalcFormula = Exist ("XBRL G/L Map Line" WHERE("XBRL Taxonomy Name" = FIELD("XBRL Taxonomy Name"),
                                                           "XBRL Taxonomy Line No." = FIELD("Line No.")));
            Caption = 'G/L Map Lines';
            Editable = false;
            FieldClass = FlowField;
        }
        field(14; Notes; Boolean)
        {
            CalcFormula = Exist ("XBRL Comment Line" WHERE("XBRL Taxonomy Name" = FIELD("XBRL Taxonomy Name"),
                                                           "XBRL Taxonomy Line No." = FIELD("Line No."),
                                                           "Comment Type" = CONST(Notes)));
            Caption = 'Notes';
            Editable = false;
            FieldClass = FlowField;
        }
        field(15; "Business Unit Filter"; Code[20])
        {
            Caption = 'Business Unit Filter';
            FieldClass = FlowFilter;
            TableRelation = "Business Unit";
        }
        field(16; "Global Dimension 1 Filter"; Code[20])
        {
            CaptionClass = '1,3,1';
            Caption = 'Global Dimension 1 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
        }
        field(17; "Global Dimension 2 Filter"; Code[20])
        {
            CaptionClass = '1,3,2';
            Caption = 'Global Dimension 2 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
        }
        field(18; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(19; "XBRL Schema Line No."; Integer)
        {
            Caption = 'XBRL Schema Line No.';
            TableRelation = "XBRL Schema"."Line No." WHERE("XBRL Taxonomy Name" = FIELD("XBRL Taxonomy Name"));
        }
        field(20; "Label Language Filter"; Text[10])
        {
            Caption = 'Label Language Filter';
            FieldClass = FlowFilter;
        }
        field(21; "Presentation Order"; Text[100])
        {
            Caption = 'Presentation Order';
        }
        field(22; "Presentation Order No."; Integer)
        {
            Caption = 'Presentation Order No.';
        }
        field(23; Reference; Boolean)
        {
            CalcFormula = Exist ("XBRL Comment Line" WHERE("XBRL Taxonomy Name" = FIELD("XBRL Taxonomy Name"),
                                                           "XBRL Taxonomy Line No." = FIELD("Line No."),
                                                           "Comment Type" = CONST(Reference)));
            Caption = 'Reference';
            Editable = false;
            FieldClass = FlowField;
        }
        field(24; "Element ID"; Text[220])
        {
            Caption = 'Element ID';
        }
        field(25; "Numeric Context Period Type"; Option)
        {
            Caption = 'Numeric Context Period Type';
            OptionCaption = ',Instant,Duration';
            OptionMembers = ,Instant,Duration;
        }
        field(26; "Presentation Linkbase Line No."; Integer)
        {
            Caption = 'Presentation Linkbase Line No.';
        }
        field(27; "Type Description Element"; Boolean)
        {
            Caption = 'Type Description Element';
        }
    }

    keys
    {
        key(Key1; "XBRL Taxonomy Name", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; Name)
        {
        }
        key(Key3; "XBRL Taxonomy Name", "Presentation Order")
        {
        }
        key(Key4; "Parent Line No.")
        {
        }
        key(Key5; "XBRL Taxonomy Name", "Element ID")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        with XBRLCommentLine do begin
            Reset;
            SetRange("XBRL Taxonomy Name", Rec."XBRL Taxonomy Name");
            SetRange("XBRL Taxonomy Line No.", Rec."Line No.");
            DeleteAll();
        end;
        with XBRLGLMapLine do begin
            Reset;
            SetRange("XBRL Taxonomy Name", Rec."XBRL Taxonomy Name");
            SetRange("XBRL Taxonomy Line No.", Rec."Line No.");
            DeleteAll();
        end;
        with XBRLRollupLine do begin
            Reset;
            SetRange("XBRL Taxonomy Name", Rec."XBRL Taxonomy Name");
            SetRange("XBRL Taxonomy Line No.", Rec."Line No.");
            DeleteAll();
        end;
        with XBRLTaxonomyLabel do begin
            Reset;
            SetRange("XBRL Taxonomy Name", Rec."XBRL Taxonomy Name");
            SetRange("XBRL Taxonomy Line No.", Rec."Line No.");
            DeleteAll();
        end;
    end;

    var
        XBRLCommentLine: Record "XBRL Comment Line";
        XBRLGLMapLine: Record "XBRL G/L Map Line";
        XBRLRollupLine: Record "XBRL Rollup Line";
        XBRLTaxonomyLabel: Record "XBRL Taxonomy Label";
}

