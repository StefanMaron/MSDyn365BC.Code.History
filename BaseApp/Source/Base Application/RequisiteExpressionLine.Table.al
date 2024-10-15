table 26560 "Requisite Expression Line"
{
    Caption = 'Requisite Expression Line';
    ObsoleteReason = 'Obsolete functionality';
    ObsoleteState = Pending;
    ObsoleteTag = '15.0';

    fields
    {
        field(1; "Report Code"; Code[20])
        {
            Caption = 'Report Code';
            TableRelation = "Statutory Report";
        }
        field(2; "Requisites Group Name"; Text[30])
        {
            Caption = 'Requisites Group Name';
            TableRelation = "Stat. Report Requisites Group".Name WHERE("Report Code" = FIELD("Report Code"));
        }
        field(3; "Base Requisite Name"; Text[30])
        {
            Caption = 'Base Requisite Name';
            TableRelation = "Stat. Report Requisite".Name WHERE("Report Code" = FIELD("Report Code"),
                                                                 "Requisites Group Name" = FIELD("Requisites Group Name"));
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; "Requisite Name"; Text[30])
        {
            Caption = 'Requisite Name';
            NotBlank = true;
            TableRelation = "Stat. Report Requisite".Name WHERE("Report Code" = FIELD("Report Code"),
                                                                 "Requisites Group Name" = FIELD("Requisites Group Name"),
                                                                 "Source Type" = FILTER(<> "Compound Requisite"));
        }
        field(6; "Requisite Description"; Text[250])
        {
            CalcFormula = Lookup ("Stat. Report Requisite".Description WHERE("Report Code" = FIELD("Report Code"),
                                                                             "Requisites Group Name" = FIELD("Requisites Group Name"),
                                                                             Name = FIELD("Requisite Name")));
            Caption = 'Requisite Description';
            FieldClass = FlowField;
        }
        field(20; Value; Text[250])
        {
            Caption = 'Value';
            Editable = false;
        }
        field(21; Source; Option)
        {
            Caption = 'Source';
            OptionCaption = 'Company Information,Director,Accountant,Sender,Export Log,Data Header';
            OptionMembers = "Company Information",Director,Accountant,Sender,"Export Log","Data Header";
        }
        field(25; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            TableRelation = AllObj."Object ID" WHERE("Object Type" = CONST(Table));
        }
        field(27; "Field ID"; Integer)
        {
            Caption = 'Field ID';
            TableRelation = Field."No." WHERE(TableNo = FIELD("Table ID"));
        }
        field(28; "Field Name"; Text[30])
        {
            CalcFormula = Lookup (Field.FieldName WHERE(TableNo = FIELD("Table ID"),
                                                        "No." = FIELD("Field ID")));
            Caption = 'Field Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(29; "String Before"; Text[10])
        {
            Caption = 'String Before';
        }
        field(30; "String After"; Text[10])
        {
            Caption = 'String After';
        }
    }

    keys
    {
        key(Key1; "Report Code", "Requisites Group Name", "Base Requisite Name", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
