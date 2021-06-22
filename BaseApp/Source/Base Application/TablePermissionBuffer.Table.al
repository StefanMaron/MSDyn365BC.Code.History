table 9800 "Table Permission Buffer"
{
    Caption = 'Table Permission Buffer';
    ReplicateData = false;

    fields
    {
        field(1; "Session ID"; Integer)
        {
            Caption = 'Session ID';
            DataClassification = SystemMetadata;
        }
        field(3; "Object Type"; Option)
        {
            Caption = 'Object Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'Table Data,Table,,Report,,Codeunit,XMLport,MenuSuite,Page,Query,System';
            OptionMembers = "Table Data","Table",,"Report",,"Codeunit","XMLport",MenuSuite,"Page","Query",System;
        }
        field(4; "Object ID"; Integer)
        {
            Caption = 'Object ID';
            DataClassification = SystemMetadata;
            TableRelation = IF ("Object Type" = CONST("Table Data")) AllObj."Object ID" WHERE("Object Type" = CONST(Table))
            ELSE
            IF ("Object Type" = CONST(Table)) AllObj."Object ID" WHERE("Object Type" = CONST(Table))
            ELSE
            IF ("Object Type" = CONST(Report)) AllObj."Object ID" WHERE("Object Type" = CONST(Report))
            ELSE
            IF ("Object Type" = CONST(Codeunit)) AllObj."Object ID" WHERE("Object Type" = CONST(Codeunit))
            ELSE
            IF ("Object Type" = CONST(XMLport)) AllObj."Object ID" WHERE("Object Type" = CONST(XMLport))
            ELSE
            IF ("Object Type" = CONST(MenuSuite)) AllObj."Object ID" WHERE("Object Type" = CONST(MenuSuite))
            ELSE
            IF ("Object Type" = CONST(Page)) AllObj."Object ID" WHERE("Object Type" = CONST(Page))
            ELSE
            IF ("Object Type" = CONST(Query)) AllObj."Object ID" WHERE("Object Type" = CONST(Query))
            ELSE
            IF ("Object Type" = CONST(System)) AllObj."Object ID" WHERE("Object Type" = CONST(System));
        }
        field(5; "Object Name"; Text[249])
        {
            CalcFormula = Lookup (AllObjWithCaption."Object Caption" WHERE("Object Type" = FIELD("Object Type"),
                                                                           "Object ID" = FIELD("Object ID")));
            Caption = 'Object Name';
            FieldClass = FlowField;
        }
        field(6; "Read Permission"; Option)
        {
            Caption = 'Read Permission';
            DataClassification = SystemMetadata;
            InitValue = Yes;
            OptionCaption = ' ,Yes,Indirect';
            OptionMembers = " ",Yes,Indirect;
        }
        field(7; "Insert Permission"; Option)
        {
            Caption = 'Insert Permission';
            DataClassification = SystemMetadata;
            InitValue = Yes;
            OptionCaption = ' ,Yes,Indirect';
            OptionMembers = " ",Yes,Indirect;
        }
        field(8; "Modify Permission"; Option)
        {
            Caption = 'Modify Permission';
            DataClassification = SystemMetadata;
            InitValue = Yes;
            OptionCaption = ' ,Yes,Indirect';
            OptionMembers = " ",Yes,Indirect;
        }
        field(9; "Delete Permission"; Option)
        {
            Caption = 'Delete Permission';
            DataClassification = SystemMetadata;
            InitValue = Yes;
            OptionCaption = ' ,Yes,Indirect';
            OptionMembers = " ",Yes,Indirect;
        }
        field(10; "Execute Permission"; Option)
        {
            Caption = 'Execute Permission';
            DataClassification = SystemMetadata;
            InitValue = Yes;
            OptionCaption = ' ,Yes,Indirect';
            OptionMembers = " ",Yes,Indirect;
        }
    }

    keys
    {
        key(Key1; "Session ID", "Object Type", "Object ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

