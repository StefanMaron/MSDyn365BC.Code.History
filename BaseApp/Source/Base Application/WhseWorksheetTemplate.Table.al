table 7328 "Whse. Worksheet Template"
{
    Caption = 'Whse. Worksheet Template';
    LookupPageID = "Whse. Worksheet Template List";
    ReplicateData = true;

    fields
    {
        field(1; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(2; Description; Text[80])
        {
            Caption = 'Description';
        }
        field(3; Type; Enum "Warehouse Worksheet Template Type")
        {
            Caption = 'Type';

            trigger OnValidate()
            begin
                case Type of
                    Type::"Put-away":
                        "Page ID" := PAGE::"Put-away Worksheet";
                    Type::Pick:
                        "Page ID" := PAGE::"Pick Worksheet";
                    Type::Movement:
                        "Page ID" := PAGE::"Movement Worksheet";
                end;
            end;
        }
        field(4; "Page ID"; Integer)
        {
            Caption = 'Page ID';
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = CONST(Page));

            trigger OnValidate()
            begin
                if "Page ID" = 0 then
                    Validate(Type);
            end;
        }
        field(5; "Page Caption"; Text[250])
        {
            CalcFormula = Lookup(AllObjWithCaption."Object Caption" WHERE("Object Type" = CONST(Page),
                                                                           "Object ID" = FIELD("Page ID")));
            Caption = 'Page Caption';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        WhseWkshLine.SetRange("Worksheet Template Name", Name);
        WhseWkshLine.DeleteAll(true);

        WhseWkshName.SetRange("Worksheet Template Name", Name);
        WhseWkshName.DeleteAll();
    end;

    trigger OnInsert()
    begin
        Validate("Page ID");
    end;

    var
        WhseWkshName: Record "Whse. Worksheet Name";
        WhseWkshLine: Record "Whse. Worksheet Line";
}

