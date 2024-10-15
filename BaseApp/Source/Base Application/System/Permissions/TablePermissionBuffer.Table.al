namespace System.Security.AccessControl;

using System.Reflection;

table 9800 "Table Permission Buffer"
{
    Caption = 'Table Permission Buffer';
    ReplicateData = false;
    ObsoleteState = Removed;
    ObsoleteTag = '24.0';
    ObsoleteReason = 'Replaced with using temporary table Tenant Permission.';
    DataClassification = CustomerContent;

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
            TableRelation = if ("Object Type" = const("Table Data")) AllObj."Object ID" where("Object Type" = const(Table))
            else
            if ("Object Type" = const(Table)) AllObj."Object ID" where("Object Type" = const(Table))
            else
            if ("Object Type" = const(Report)) AllObj."Object ID" where("Object Type" = const(Report))
            else
            if ("Object Type" = const(Codeunit)) AllObj."Object ID" where("Object Type" = const(Codeunit))
            else
            if ("Object Type" = const(XMLport)) AllObj."Object ID" where("Object Type" = const(XMLport))
            else
            if ("Object Type" = const(MenuSuite)) AllObj."Object ID" where("Object Type" = const(MenuSuite))
            else
            if ("Object Type" = const(Page)) AllObj."Object ID" where("Object Type" = const(Page))
            else
            if ("Object Type" = const(Query)) AllObj."Object ID" where("Object Type" = const(Query))
            else
            if ("Object Type" = const(System)) AllObj."Object ID" where("Object Type" = const(System));
        }
        field(5; "Object Name"; Text[249])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = field("Object Type"),
                                                                           "Object ID" = field("Object ID")));
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

