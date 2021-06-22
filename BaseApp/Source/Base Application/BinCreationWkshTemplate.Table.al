table 7336 "Bin Creation Wksh. Template"
{
    Caption = 'Bin Creation Wksh. Template';
    LookupPageID = "Bin Creation Wksh. Templ. List";
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
        field(6; "Page ID"; Integer)
        {
            Caption = 'Page ID';
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = CONST(Page));

            trigger OnValidate()
            begin
                if "Page ID" = 0 then
                    Validate(Type);
            end;
        }
        field(9; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Bin,Bin Content';
            OptionMembers = Bin,"Bin Content";

            trigger OnValidate()
            begin
                case Type of
                    Type::Bin:
                        "Page ID" := PAGE::"Bin Creation Worksheet";
                    Type::"Bin Content":
                        "Page ID" := PAGE::"Bin Content Creation Worksheet";
                end;
            end;
        }
        field(16; "Page Caption"; Text[250])
        {
            CalcFormula = Lookup (AllObjWithCaption."Object Caption" WHERE("Object Type" = CONST(Page),
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
        BinCreateWkshLine.SetRange("Worksheet Template Name", Name);
        BinCreateWkshLine.DeleteAll(true);
        BinCreateWkshName.SetRange("Worksheet Template Name", Name);
        BinCreateWkshName.DeleteAll();
    end;

    trigger OnInsert()
    begin
        Validate("Page ID");
    end;

    var
        BinCreateWkshName: Record "Bin Creation Wksh. Name";
        BinCreateWkshLine: Record "Bin Creation Worksheet Line";
}

