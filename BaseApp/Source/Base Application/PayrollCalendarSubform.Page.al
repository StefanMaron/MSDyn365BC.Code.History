page 17430 "Payroll Calendar Subform"
{
    Caption = 'Lines';
    PageType = ListPart;
    SourceTable = "Payroll Calendar Line";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field(Date; Date)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the record.';
                }
                field(Nonworking; Nonworking)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Starting Time"; "Starting Time")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Work Hours"; "Work Hours")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Night Hours"; "Night Hours")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Week Day"; "Week Day")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Day Status"; "Day Status")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Time Activity Code"; "Time Activity Code")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("L&ine")
            {
                Caption = 'L&ine';
                Image = Line;
                action(Release)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Release';
                    Image = ReleaseDoc;
                    ToolTip = 'Enable the record for the next stage of processing. ';

                    trigger OnAction()
                    begin
                        ReleaseLines;
                    end;
                }
                action(Reopen)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reopen';
                    Image = ReOpen;
                    ToolTip = 'Open the closed or released record.';

                    trigger OnAction()
                    begin
                        ReopenLines;
                    end;
                }
            }
        }
    }

    [Scope('OnPrem')]
    procedure GetSelectionFilter(var CalendarLine: Record "Payroll Calendar Line")
    begin
        CurrPage.SetSelectionFilter(CalendarLine);
    end;

    [Scope('OnPrem')]
    procedure ReleaseLines()
    var
        CalendarLine: Record "Payroll Calendar Line";
    begin
        GetSelectionFilter(CalendarLine);
        if CalendarLine.FindSet then
            repeat
                if CalendarLine.Status = CalendarLine.Status::Open then begin
                    CalendarLine.Release;
                    CalendarLine.Modify();
                end;
            until CalendarLine.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure ReopenLines()
    var
        CalendarLine: Record "Payroll Calendar Line";
    begin
        GetSelectionFilter(CalendarLine);
        if CalendarLine.FindSet then
            repeat
                if CalendarLine.Status = CalendarLine.Status::Released then begin
                    CalendarLine.Reopen;
                    CalendarLine.Modify();
                end;
            until CalendarLine.Next = 0;
    end;
}

