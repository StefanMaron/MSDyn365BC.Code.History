table 17445 "Time Activity Filter"
{
    Caption = 'Time Activity Filter';

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
        }
        field(3; "Activity Code Filter"; Text[250])
        {
            Caption = 'Activity Code Filter';

            trigger OnLookup()
            begin
                ShowCodes(0);
                ComposeFilter(0);
            end;
        }
        field(4; "Timesheet Code Filter"; Text[250])
        {
            Caption = 'Timesheet Code Filter';

            trigger OnLookup()
            begin
                ShowCodes(1);
                ComposeFilter(1);
            end;
        }
    }

    keys
    {
        key(Key1; "Code", "Starting Date")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure ShowCodes(CodeType: Option)
    var
        TimeActivityFilterCode: Record "Time Activity Filter Code";
        TimeActivityFilterCodes: Page "Time Activity Filter Codes";
    begin
        TimeActivityFilterCode.SetRange(Code, Code);
        TimeActivityFilterCode.SetRange("Starting Date", "Starting Date");
        TimeActivityFilterCode.SetRange(Type, CodeType);
        TimeActivityFilterCodes.SetTableView(TimeActivityFilterCode);
        TimeActivityFilterCodes.RunModal;
    end;

    [Scope('OnPrem')]
    procedure ComposeFilter(CodeType: Option)
    var
        TimeActivityFilterCode: Record "Time Activity Filter Code";
    begin
        TimeActivityFilterCode.SetRange(Code, Code);
        TimeActivityFilterCode.SetRange("Starting Date", "Starting Date");
        TimeActivityFilterCode.SetRange(Type, CodeType);
        case CodeType of
            TimeActivityFilterCode.Type::"Activity Code":
                begin
                    "Activity Code Filter" := '';
                    if TimeActivityFilterCode.FindSet then
                        repeat
                            "Activity Code Filter" := "Activity Code Filter" + TimeActivityFilterCode."Activity Code" + '|';
                        until TimeActivityFilterCode.Next = 0;
                    "Activity Code Filter" := DelChr("Activity Code Filter", '>', '|');
                end;
            TimeActivityFilterCode.Type::"Timesheet Code":
                begin
                    "Timesheet Code Filter" := '';
                    if TimeActivityFilterCode.FindSet then
                        repeat
                            "Timesheet Code Filter" := "Timesheet Code Filter" + TimeActivityFilterCode."Activity Code" + '|';
                        until TimeActivityFilterCode.Next = 0;
                    "Timesheet Code Filter" := DelChr("Timesheet Code Filter", '>', '|');
                end;
        end;
    end;
}

