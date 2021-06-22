page 7605 "Customized Cal. Entries Subfm"
{
    Caption = 'Lines';
    DeleteAllowed = false;
    Editable = true;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Customized Calendar Change";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(CurrSourceType; "Source Type")
                {
                    ApplicationArea = Suite;
                    Caption = 'Current Source Type';
                    ToolTip = 'Specifies the source type for the calendar entry.';
                    Visible = false;
                }
                field(CurrSourceCode; "Source Code")
                {
                    ApplicationArea = Suite;
                    Caption = 'Current Source Code';
                    ToolTip = 'Specifies the source code for the calendar entry.';
                    Visible = false;
                }
                field(CurrAdditionalSourceCode; "Additional Source Code")
                {
                    ApplicationArea = Suite;
                    Caption = 'Current Additional Source Code';
                    ToolTip = 'Specifies the calendar entry.';
                    Visible = false;
                }
                field(CurrCalendarCode; "Base Calendar Code")
                {
                    ApplicationArea = Suite;
                    Caption = 'Current Calendar Code';
                    Editable = false;
                    ToolTip = 'Specifies the calendar code.';
                    Visible = false;
                }
                field("Period Start"; Date)
                {
                    ApplicationArea = Suite;
                    Caption = 'Date';
                    Editable = false;
                    ToolTip = 'Specifies the date.';
                }
                field("Period Name"; Day)
                {
                    ApplicationArea = Suite;
                    Caption = 'Day';
                    Editable = false;
                    ToolTip = 'Specifies the day of the week.';
                }
                field(WeekNo; Date2DWY(Date, 2))
                {
                    ApplicationArea = Suite;
                    Caption = 'Week No.';
                    Editable = false;
                    ToolTip = 'Specifies the week number for the calendar entries.';
                    Visible = false;
                }
                field(Nonworking; Nonworking)
                {
                    ApplicationArea = Suite;
                    Caption = 'Nonworking';
                    Editable = true;
                    ToolTip = 'Specifies the date entry as a nonworking day. You can also remove the check mark to return the status to working day.';

                    trigger OnValidate()
                    begin
                        UpdateCusomizedCalendarChanges;
                    end;
                }
                field(Description; Description)
                {
                    ApplicationArea = Suite;
                    Caption = 'Description';
                    ToolTip = 'Specifies the description of the entry to be applied.';

                    trigger OnValidate()
                    begin
                        UpdateCusomizedCalendarChanges;
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        if DateRec.Get(DateRec."Period Type"::Date, Date) then;
    end;

    trigger OnFindRecord(Which: Text): Boolean
    var
        FoundDate: Boolean;
        FoundLine: Boolean;
    begin
        FoundDate := PeriodFormMgt.FindDate(Which, DateRec, 0);
        if not FoundDate then
            exit(false);

        if not FindLine(DateRec."Period Start") then
            exit(InsertLine());
        exit(true);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        FoundLine: Boolean;
        ResultSteps: Integer;
    begin
        ResultSteps := PeriodFormMgt.NextDate(Steps, DateRec, 0);
        if ResultSteps = 0 then
            exit(0);

        if not FindLine(DateRec."Period Start") then
            if not InsertLine() then
                exit(0);
        exit(ResultSteps);
    end;

    trigger OnOpenPage()
    begin
        DateRec.Reset();
        DateRec.SetFilter("Period Start", '>=%1', 00000101D);
    end;

    var
        CurrCalendarChange: Record "Customized Calendar Change";
        CalendarMgmt: Codeunit "Calendar Management";
        PeriodFormMgt: Codeunit PeriodFormManagement;
        DateRec: Record Date;

    local procedure FindLine(TargetDate: Date) FoundLine: Boolean;
    begin
        Reset;
        SetRange(Date, TargetDate);
        FoundLine := FindFirst();
        Reset;
    end;

    local procedure InsertLine(): Boolean;
    begin
        Rec := CurrCalendarChange;
        Date := DateRec."Period Start";
        Day := DateRec."Period No.";
        CalendarMgmt.CheckDateStatus(Rec);
        exit(Insert());
    end;

    procedure SetCalendarSource(CustomizedCalendarEntry: record "Customized Calendar Entry")
    begin
        CalendarMgmt.SetSource(CustomizedCalendarEntry, CurrCalendarChange);

        CurrPage.Update;
    end;

    local procedure UpdateCusomizedCalendarChanges()
    var
        CustomizedCalendarChange: Record "Customized Calendar Change";
    begin
        CustomizedCalendarChange.Reset();
        CustomizedCalendarChange.SetRange("Source Type", "Source Type");
        CustomizedCalendarChange.SetRange("Source Code", "Source Code");
        CustomizedCalendarChange.SetRange("Additional Source Code", "Additional Source Code");
        CustomizedCalendarChange.SetRange("Base Calendar Code", "Base Calendar Code");
        CustomizedCalendarChange.SetRange("Recurring System", CustomizedCalendarChange."Recurring System"::" ");
        CustomizedCalendarChange.SetRange(Date, Date);
        if CustomizedCalendarChange.FindFirst then
            CustomizedCalendarChange.Delete();

        if not IsInBaseCalendar then begin
            CustomizedCalendarChange := Rec;
            OnUpdateCusomizedCalendarChanges(CustomizedCalendarChange);
            CustomizedCalendarChange.Insert();
        end;
    end;

    local procedure IsInBaseCalendar(): Boolean
    var
        BaseCalendarChange: Record "Base Calendar Change";
    begin
        if BaseCalendarChange.get("Base Calendar Code", "Recurring System"::" ", Date, Day) then
            exit(BaseCalendarChange.Nonworking = Nonworking);

        if BaseCalendarChange.get("Base Calendar Code", "Recurring System"::"Weekly Recurring", 0D, Day) then
            exit(BaseCalendarChange.Nonworking = Nonworking);

        BaseCalendarChange.SetRange("Base Calendar Code", "Base Calendar Code");
        BaseCalendarChange.SetRange(Day, BaseCalendarChange.Day::" ");
        BaseCalendarChange.SetRange("Recurring System", "Recurring System"::"Annual Recurring");
        if BaseCalendarChange.Find('-') then
            repeat
                if (Date2DMY(BaseCalendarChange.Date, 2) = Date2DMY(Date, 2)) and
                   (Date2DMY(BaseCalendarChange.Date, 1) = Date2DMY(Date, 1))
                then
                    exit(BaseCalendarChange.Nonworking = Nonworking);
            until BaseCalendarChange.Next = 0;

        exit(not CurrCalendarChange.Nonworking);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateCusomizedCalendarChanges(var CustomizedCalendarChange: Record "Customized Calendar Change")
    begin
    end;
}

