table 5099 "Saved Segment Criteria Line"
{
    Caption = 'Saved Segment Criteria Line';

    fields
    {
        field(1; "Segment Criteria Code"; Code[10])
        {
            Caption = 'Segment Criteria Code';
            TableRelation = "Saved Segment Criteria";
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
        field(6; "Table View"; Text[2048])
        {
            Caption = 'Table View';
        }
        field(7; View; Text[250])
        {
            Caption = 'View';
            ObsoleteReason = 'Replaced by field "Table View": Text[2048]';
#if not CLEAN22
            ObsoleteState = Pending;
            ObsoleteTag = '22.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
#endif
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
            CalcFormula = Lookup(AllObjWithCaption."Object Caption" WHERE("Object Type" = CONST(Table),
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
        key(Key1; "Segment Criteria Code", "Line No.", "Action")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure ActionTable(): Text[250]
    begin
        case Type of
            Type::Action:
                exit(Format(Action));
            Type::Filter:
                begin
                    CalcFields("Table Caption");
                    exit("Table Caption");
                end;
        end;
    end;

#if not CLEAN22
    [Obsolete('Replaced by procedure GetSegmentCriteriaFilters()', '22.0')]
    procedure "Filter"(): Text[250]
    var
        SegCriteriaManagement: Codeunit SegCriteriaManagement;
    begin
        exit(SegCriteriaManagement.SegCriteriaFilter("Table No.", View));
    end;
#endif
}

