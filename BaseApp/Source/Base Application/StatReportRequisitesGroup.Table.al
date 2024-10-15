table 26557 "Stat. Report Requisites Group"
{
    Caption = 'Stat. Report Requisites Group';
    ObsoleteReason = 'Obsolete functionality';
    ObsoleteState = Pending;

    fields
    {
        field(1; "Report Code"; Code[20])
        {
            Caption = 'Report Code';
            TableRelation = "Statutory Report";
        }
        field(3; Name; Text[30])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(4; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(8; "Section No."; Code[10])
        {
            Caption = 'Section No.';
        }
        field(9; "Requisites Quantity"; Integer)
        {
            CalcFormula = Count ("Stat. Report Requisite" WHERE("Report Code" = FIELD("Report Code"),
                                                                "Requisites Group Name" = FIELD(Name)));
            Caption = 'Requisites Quantity';
            Editable = false;
            FieldClass = FlowField;
        }
        field(10; "Sequence No."; Integer)
        {
            Caption = 'Sequence No.';
        }
        field(11; "Excel Sheet Name"; Text[30])
        {
            Caption = 'Excel Sheet Name';
            TableRelation = "Stat. Report Excel Sheet"."Sheet Name" WHERE("Report Code" = FIELD("Report Code"),
                                                                           "Report Data No." = CONST(''));
        }
        field(12; "Group End"; Boolean)
        {
            Caption = 'Group End';
            InitValue = true;
        }
        field(13; "Fragment End"; Boolean)
        {
            Caption = 'Fragment End';
        }
    }

    keys
    {
        key(Key1; "Report Code", Name)
        {
            Clustered = true;
        }
        key(Key2; "Report Code", "Sequence No.")
        {
        }
        key(Key3; "Report Code", "Excel Sheet Name")
        {
        }
    }

    fieldgroups
    {
    }
}