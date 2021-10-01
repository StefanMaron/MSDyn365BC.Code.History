table 8615 "Config. Package Data"
{
    Caption = 'Config. Package Data';
    ReplicateData = false;

    fields
    {
        field(1; "Package Code"; Code[20])
        {
            Caption = 'Package Code';
            NotBlank = true;
            TableRelation = "Config. Package";
        }
        field(2; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            NotBlank = true;
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = CONST(Table));
        }
        field(3; "No."; Integer)
        {
            Caption = 'No.';
            TableRelation = "Config. Package Record"."No." WHERE("Package Code" = FIELD("Package Code"),
                                                                 "Table ID" = FIELD("Table ID"));
        }
        field(4; "Field ID"; Integer)
        {
            Caption = 'Field ID';
            TableRelation = "Config. Package Field"."Field ID" WHERE("Package Code" = FIELD("Package Code"),
                                                                     "Table ID" = FIELD("Table ID"));
        }
#pragma warning disable AS0086
        field(5; Value; Text[2048])
#pragma warning restore AS0086
        {
            Caption = 'Value';
        }
        field(6; Invalid; Boolean)
        {
            Caption = 'Invalid';
        }
        field(7; "BLOB Value"; BLOB)
        {
            Caption = 'BLOB Value';
        }
    }

    keys
    {
        key(Key1; "Package Code", "Table ID", "No.", "Field ID")
        {
            Clustered = true;
        }
        key(Key2; "Package Code", "Table ID", "Field ID")
        {
        }
    }

    fieldgroups
    {
    }
}

