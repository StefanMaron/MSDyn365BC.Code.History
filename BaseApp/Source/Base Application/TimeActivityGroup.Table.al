table 17444 "Time Activity Group"
{
    Caption = 'Time Activity Group';
    LookupPageID = "Time Activity Groups";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        TimesheetMgt: Codeunit "Timesheet Management RU";

    [Scope('OnPrem')]
    procedure TimeActivityInGroup(TimeActivityCode: Code[20]; StartDate: Date): Boolean
    var
        TempTimeActivity: Record "Time Activity" temporary;
        TimeActivityFilter: Record "Time Activity Filter";
    begin
        TempTimeActivity.Code := TimeActivityCode;
        TempTimeActivity.Insert();

        TimesheetMgt.GetTimeGroupFilter(
          Code,
          StartDate,
          TimeActivityFilter);
        TempTimeActivity.SetFilter(Code, TimeActivityFilter."Activity Code Filter");
        exit(TempTimeActivity.FindFirst);
    end;
}

