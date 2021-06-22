table 244 "Req. Wksh. Template"
{
    Caption = 'Req. Wksh. Template';
    LookupPageID = "Req. Worksheet Template List";
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
                    Validate(Recurring);
            end;
        }
        field(12; Recurring; Boolean)
        {
            Caption = 'Recurring';

            trigger OnValidate()
            begin
                if Recurring then
                    "Page ID" := PAGE::"Recurring Req. Worksheet"
                else
                    case Type of
                        Type::"Req.":
                            "Page ID" := PAGE::"Req. Worksheet";
                        Type::"For. Labor":
                            "Page ID" := PAGE::"Subcontracting Worksheet";
                        Type::Planning:
                            "Page ID" := PAGE::"Planning Worksheet";
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
        field(99000750; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Req.,For. Labor,Planning';
            OptionMembers = "Req.","For. Labor",Planning;
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
        fieldgroup(DropDown; Name, Description, Recurring, Type)
        {
        }
    }

    trigger OnDelete()
    begin
        ReqLine.SetRange("Worksheet Template Name", Name);
        ReqLine.DeleteAll(true);
        ReqWkshName.SetRange("Worksheet Template Name", Name);
        ReqWkshName.DeleteAll();
    end;

    trigger OnInsert()
    begin
        Validate("Page ID");
    end;

    var
        ReqWkshName: Record "Requisition Wksh. Name";
        ReqLine: Record "Requisition Line";
}

