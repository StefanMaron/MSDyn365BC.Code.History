table 17446 "Time Activity Filter Code"
{
    Caption = 'Time Activity Filter Code';

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            TableRelation = "Time Activity Group";
        }
        field(2; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            TableRelation = "Time Activity Filter"."Starting Date" WHERE(Code = FIELD(Code));
        }
        field(3; "Activity Code"; Code[10])
        {
            Caption = 'Activity Code';
            TableRelation = IF (Type = CONST("Activity Code")) "Time Activity"
            ELSE
            IF (Type = CONST("Timesheet Code")) "Timesheet Code";

            trigger OnValidate()
            begin
                "Activity Description" := '';
                if "Activity Code" <> '' then
                    case Type of
                        Type::"Activity Code":
                            begin
                                AbsenceCause.Get("Activity Code");
                                "Activity Description" := AbsenceCause.Description;
                            end;
                        Type::"Timesheet Code":
                            begin
                                TimesheetCode.Get("Activity Code");
                                "Activity Description" := TimesheetCode.Description;
                            end;
                    end;
            end;
        }
        field(4; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Activity Code,Timesheet Code';
            OptionMembers = "Activity Code","Timesheet Code";
        }
        field(5; "Activity Description"; Text[100])
        {
            Caption = 'Activity Description';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Code", "Starting Date", Type, "Activity Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        AbsenceCause: Record "Time Activity";
        TimesheetCode: Record "Timesheet Code";
}

