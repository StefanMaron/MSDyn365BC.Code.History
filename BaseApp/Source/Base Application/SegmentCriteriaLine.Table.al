table 5097 "Segment Criteria Line"
{
    Caption = 'Segment Criteria Line';
    DrillDownPageID = "Segment Criteria";

    fields
    {
        field(1; "Segment No."; Code[20])
        {
            Caption = 'Segment No.';
            TableRelation = "Segment Header";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Action,Filter';
            OptionMembers = "Action","Filter";
        }
        field(4; "Action"; Enum "Segment Criteria Line Action")
        {
            Caption = 'Action';
        }
        field(5; "Table No."; Integer)
        {
            Caption = 'Table No.';
        }
        field(7; View; Text[250])
        {
            Caption = 'View';
        }
        field(8; "Allow Existing Contacts"; Boolean)
        {
            Caption = 'Allow Existing Contacts';
        }
        field(9; "Expand Contact"; Boolean)
        {
            Caption = 'Expand Contact';
        }
        field(10; "Allow Company with Persons"; Boolean)
        {
            Caption = 'Allow Company with Persons';
        }
        field(11; "Ignore Exclusion"; Boolean)
        {
            Caption = 'Ignore Exclusion';
        }
        field(12; "Entire Companies"; Boolean)
        {
            Caption = 'Entire Companies';
        }
        field(13; "Table Caption"; Text[250])
        {
            CalcFormula = Lookup (AllObjWithCaption."Object Caption" WHERE("Object Type" = CONST(Table),
                                                                           "Object ID" = FIELD("Table No.")));
            Caption = 'Table Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(14; "No. of Filters"; Integer)
        {
            Caption = 'No. of Filters';
        }
    }

    keys
    {
        key(Key1; "Segment No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Segment No.", Type)
        {
        }
    }

    fieldgroups
    {
    }

    procedure ActionTable(): Text[250]
    var
        ObjTransl: Record "Object Translation";
    begin
        case Type of
            Type::Action:
                exit(Format(Action));
            Type::Filter:
                exit(ObjTransl.TranslateObject(Type, "Table No."));
        end;
    end;

    procedure "Filter"(): Text[250]
    var
        SegCriteriaManagement: Codeunit SegCriteriaManagement;
    begin
        exit(SegCriteriaManagement.SegCriteriaFilter("Table No.", View));
    end;
}

