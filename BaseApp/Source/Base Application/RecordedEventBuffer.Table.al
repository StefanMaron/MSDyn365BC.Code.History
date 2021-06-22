table 9804 "Recorded Event Buffer"
{
    Caption = 'Recorded Event Buffer';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Session ID"; Integer)
        {
            Caption = 'Session ID';
            DataClassification = SystemMetadata;
        }
        field(2; "Object Type"; Option)
        {
            Caption = 'Object Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'Table Data,Table,,Report,,Codeunit,XMLport,MenuSuite,Page,Query,System';
            OptionMembers = "Table Data","Table",,"Report",,"Codeunit","XMLport",MenuSuite,"Page","Query",System;
        }
        field(3; "Object ID"; Integer)
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
        field(4; "Object Name"; Text[30])
        {
            CalcFormula = Lookup (AllObjWithCaption."Object Name" WHERE("Object Type" = FIELD("Object Type"),
                                                                        "Object ID" = FIELD("Object ID")));
            Caption = 'Object Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "Event Name"; Text[129])
        {
            Caption = 'Event Name';
            DataClassification = SystemMetadata;
        }
        field(6; "Event Type"; Option)
        {
            Caption = 'Event Type';
            DataClassification = SystemMetadata;
            OptionCaption = ',Custom Event,Trigger Event';
            OptionMembers = ,"Custom Event","Trigger Event";
        }
        field(7; "Call Order"; Integer)
        {
            Caption = 'Call Order';
            DataClassification = SystemMetadata;
        }
        field(8; "Element Name"; Text[120])
        {
            Caption = 'Element Name';
            DataClassification = SystemMetadata;
        }
        field(9; "Calling Object Type"; Option)
        {
            Caption = 'Calling Object Type';
            DataClassification = SystemMetadata;
            OptionCaption = ',Table,,Report,,Codeunit,XMLport,MenuSuite,Page,Query,System';
            OptionMembers = ,"Table",,"Report",,"Codeunit","XMLport",MenuSuite,"Page","Query",System;
        }
        field(10; "Calling Object ID"; Integer)
        {
            Caption = 'Calling Object ID';
            DataClassification = SystemMetadata;
        }
        field(11; "Calling Object Name"; Text[30])
        {
            CalcFormula = Lookup (AllObjWithCaption."Object Name" WHERE("Object Type" = FIELD("Calling Object Type"),
                                                                        "Object ID" = FIELD("Calling Object ID")));
            Caption = 'Calling Object Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12; "Calling Method"; Text[129])
        {
            Caption = 'Calling Method';
            DataClassification = SystemMetadata;
        }
        field(13; "Hit Count"; Integer)
        {
            Caption = 'Hit Count';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Object Type", "Object ID", "Event Name", "Element Name", "Event Type", "Calling Object Type", "Calling Object ID", "Calling Method", "Call Order")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

