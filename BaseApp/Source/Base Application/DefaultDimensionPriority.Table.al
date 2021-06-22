table 354 "Default Dimension Priority"
{
    Caption = 'Default Dimension Priority';

    fields
    {
        field(1; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
        field(2; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            NotBlank = true;
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = CONST(Table));

            trigger OnLookup()
            var
                TempAllObjWithCaption: Record AllObjWithCaption temporary;
            begin
                GetDefaultDimTableList(TempAllObjWithCaption);
                if PAGE.RunModal(PAGE::Objects, TempAllObjWithCaption) = ACTION::LookupOK then begin
                    "Table ID" := TempAllObjWithCaption."Object ID";
                    Validate("Table ID");
                end;
            end;

            trigger OnValidate()
            var
                TempAllObjWithCaption: Record AllObjWithCaption temporary;
            begin
                CalcFields("Table Caption");
                GetDefaultDimTableList(TempAllObjWithCaption);
                if not TempAllObjWithCaption.Get(TempAllObjWithCaption."Object Type"::Table, "Table ID") then
                    FieldError("Table ID");
            end;
        }
        field(3; "Table Caption"; Text[250])
        {
            CalcFormula = Lookup (AllObjWithCaption."Object Caption" WHERE("Object Type" = CONST(Table),
                                                                           "Object ID" = FIELD("Table ID")));
            Caption = 'Table Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(4; Priority; Integer)
        {
            Caption = 'Priority';
            MinValue = 1;
        }
    }

    keys
    {
        key(Key1; "Source Code", "Table ID")
        {
            Clustered = true;
        }
        key(Key2; "Source Code", Priority)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        if Priority = 0 then
            Priority := xRec.Priority + 1;
    end;

    var
        DimMgt: Codeunit DimensionManagement;

    local procedure GetDefaultDimTableList(var TempAllObjWithCaption: Record AllObjWithCaption temporary)
    begin
        DimMgt.DefaultDimObjectNoList(TempAllObjWithCaption);
        DimMgt.InsertObject(TempAllObjWithCaption, DATABASE::"Service Contract Header");
    end;
}

