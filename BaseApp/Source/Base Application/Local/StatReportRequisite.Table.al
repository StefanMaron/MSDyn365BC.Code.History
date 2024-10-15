table 26559 "Stat. Report Requisite"
{
    Caption = 'Stat. Report Requisite';
    ObsoleteReason = 'Obsolete functionality';
    ObsoleteState = Removed;
    ObsoleteTag = '19.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Report Code"; Code[20])
        {
            Caption = 'Report Code';
            TableRelation = "Statutory Report";
        }
        field(3; "Requisites Group Name"; Text[30])
        {
            Caption = 'Requisites Group Name';
        }
        field(5; Name; Text[30])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(6; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(7; "Data Type"; Option)
        {
            Caption = 'Data Type';
            OptionCaption = 'Text,Code,Integer,Decimal,Date';
            OptionMembers = Text,"Code","Integer",Decimal,Date;
        }
        field(10; "Source Type"; Option)
        {
            Caption = 'Source Type';
            OptionCaption = 'Expression,Constant,Table Data,Individual Requisite,Inserted Requisite,Compound Requisite';
            OptionMembers = Expression,Constant,"Table Data","Individual Requisite","Inserted Requisite","Compound Requisite";
        }
        field(12; "Sequence No."; Integer)
        {
            Caption = 'Sequence No.';
        }
        field(15; "Excel Only"; Boolean)
        {
            Caption = 'Excel Only';
        }
        field(20; Value; Text[250])
        {
            Caption = 'Value';
        }
        field(23; "Empty Value"; Text[10])
        {
            Caption = 'Empty Value';
        }
        field(24; "Table Code"; Code[20])
        {
            Caption = 'Table Code';
            TableRelation = "Statutory Report Table".Code where("Report Code" = field("Report Code"));
        }
        field(25; "Row Link No."; Integer)
        {
            Caption = 'Row Link No.';
        }
        field(26; "Column Link No."; Integer)
        {
            Caption = 'Column Link No.';
        }
        field(30; "Excel Mapping Type"; Option)
        {
            Caption = 'Excel Mapping Type';
            OptionCaption = 'Cell,Several Cells,Option';
            OptionMembers = Cell,"Several Cells",Option;
        }
        field(31; "Excel Cell Name"; Code[10])
        {
            Caption = 'Excel Cell Name';
        }
        field(32; "Excel Second Cell Name"; Code[10])
        {
            Caption = 'Excel Second Cell Name';
        }
        field(33; "Cells Quantity"; Integer)
        {
            Caption = 'Cells Quantity';
        }
        field(34; "Export Type"; Option)
        {
            Caption = 'Export Type';
            OptionCaption = 'Required,Non-required,Conditionally Required,Set';
            OptionMembers = Required,"Non-required","Conditionally Required",Set;
        }
        field(35; "Scalable Table Row Template"; Boolean)
        {
            Caption = 'Scalable Table Row Template';
        }
        field(41; "OKEI Scaling"; Boolean)
        {
            Caption = 'OKEI Scaling';
        }
    }

    keys
    {
        key(Key1; "Report Code", "Requisites Group Name", Name)
        {
            Clustered = true;
        }
        key(Key2; "Report Code", "Requisites Group Name", "Table Code", "Sequence No.")
        {
        }
        key(Key3; "Report Code", "Table Code", "Row Link No.", "Column Link No.")
        {
        }
        key(Key4; "Sequence No.")
        {
        }
    }

    fieldgroups
    {
    }
}

