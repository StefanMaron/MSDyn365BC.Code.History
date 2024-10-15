table 26566 "Stat. Report Requisite Value"
{
    Caption = 'Stat. Report Requisite Value';
    ObsoleteReason = 'Obsolete functionality';
    ObsoleteState = Pending;
    ObsoleteTag = '15.0';

    fields
    {
        field(1; "Report Data No."; Code[20])
        {
            Caption = 'Report Data No.';
            TableRelation = "Statutory Report Data Header";
        }
        field(2; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(3; "Report Code"; Code[20])
        {
            Caption = 'Report Code';
            TableRelation = "Statutory Report";
        }
        field(4; "Table Code"; Code[20])
        {
            Caption = 'Table Code';
            TableRelation = "Statutory Report Table".Code WHERE("Report Code" = FIELD("Report Code"));
        }
        field(5; "Requisites Group Name"; Text[30])
        {
            Caption = 'Requisites Group Name';
            TableRelation = "Stat. Report Requisites Group".Name WHERE("Report Code" = FIELD("Report Code"));
        }
        field(7; Name; Text[30])
        {
            Caption = 'Name';
        }
        field(8; "Data Type"; Option)
        {
            Caption = 'Data Type';
            OptionCaption = 'Text,Code,Integer,Decimal,Date';
            OptionMembers = Text,"Code","Integer",Decimal,Date;
        }
        field(9; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(10; "Excel Cell Name"; Code[10])
        {
            Caption = 'Excel Cell Name';
        }
        field(11; "Excel Sheet Name"; Text[30])
        {
            Caption = 'Excel Sheet Name';
            TableRelation = "Stat. Report Excel Sheet"."Sheet Name" WHERE("Report Code" = FIELD("Report Code"),
                                                                           "Table Code" = FIELD("Table Code"),
                                                                           "Report Data No." = FIELD("Report Data No."));
        }
        field(12; Value; Text[250])
        {
            Caption = 'Value';
        }
        field(15; "Excel Only"; Boolean)
        {
            Caption = 'Excel Only';
        }
        field(16; Separator; Boolean)
        {
            Caption = 'Separator';
        }
        field(30; "Excel Mapping Type"; Option)
        {
            Caption = 'Excel Mapping Type';
            OptionCaption = 'Cell,Several Cells,Option';
            OptionMembers = Cell,"Several Cells",Option;
        }
        field(34; "Export Type"; Option)
        {
            Caption = 'Export Type';
            OptionCaption = 'Required,Non-required,Conditionally Required,Set';
            OptionMembers = Required,"Non-required","Conditionally Required",Set;
        }
        field(35; Recalculate; Boolean)
        {
            Caption = 'Recalculate';
        }
    }

    keys
    {
        key(Key1; "Report Data No.", "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

