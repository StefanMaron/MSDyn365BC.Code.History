page 7604 "Base Calendar Entries Subform"
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
                field(CurrentCalendarCode; "Base Calendar Code")
                {
                    ApplicationArea = Suite;
                    Caption = 'Base Calendar Code';
                    Editable = false;
                    ToolTip = 'Specifies which base calendar was used as the basis.';
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
                        UpdateBaseCalendarChanges();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
                    Caption = 'Description';
                    ToolTip = 'Specifies the description of the entry to be applied.';

                    trigger OnValidate()
                    begin
                        UpdateBaseCalendarChanges();
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
    begin
        FoundDate := PeriodPageMgt.FindDate(Which, DateRec, "Analysis Period Type"::Day);
        if not FoundDate then
            exit(false);

        if not FindLine(DateRec."Period Start") then
            exit(InsertLine());
        exit(true);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        ResultSteps: Integer;
    begin
        ResultSteps := PeriodPageMgt.NextDate(Steps, DateRec, "Analysis Period Type"::Day);
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
        DateRec: Record Date;
        CurrCalendarChange: Record "Customized Calendar Change";
        PeriodPageMgt: Codeunit PeriodPageManagement;
        CalendarMgmt: Codeunit "Calendar Management";

    local procedure FindLine(TargetDate: Date) FoundLine: Boolean;
    begin
        Reset();
        SetRange(Date, TargetDate);
        FoundLine := FindFirst();
        Reset();
    end;

    local procedure InsertLine(): Boolean;
    begin
        if CurrCalendarChange.IsBlankSource() then
            exit;
        Rec := CurrCalendarChange;
        Date := DateRec."Period Start";
        Day := DateRec."Period No.";
        CalendarMgmt.CheckDateStatus(Rec);
        exit(Insert());
    end;

    procedure SetCalendarSource(BaseCalendar: Record "Base Calendar")
    begin
        Rec.DeleteAll();
        CalendarMgmt.SetSource(BaseCalendar, CurrCalendarChange);
        CurrPage.Update();
    end;

    local procedure UpdateBaseCalendarChanges()
    var
        BaseCalendarChange: Record "Base Calendar Change";
    begin
        BaseCalendarChange.Reset();
        BaseCalendarChange.SetRange("Base Calendar Code", "Base Calendar Code");
        BaseCalendarChange.SetRange(Date, Date);
        if BaseCalendarChange.FindFirst() then
            BaseCalendarChange.Delete();
        BaseCalendarChange.Init();
        BaseCalendarChange."Base Calendar Code" := "Base Calendar Code";
        BaseCalendarChange.Date := Date;
        BaseCalendarChange.Description := Description;
        BaseCalendarChange.Nonworking := Nonworking;
        BaseCalendarChange.Day := Day;
        OnUpdateBaseCalendarChanges(BaseCalendarChange, Rec);
        BaseCalendarChange.Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateBaseCalendarChanges(var BaseCalendarChange: Record "Base Calendar Change"; var CustCalendarChange: Record "Customized Calendar Change")
    begin
    end;
}

