page 17434 "Payroll Calendar by Per. Lines"
{
    Caption = 'Lines';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = ListPart;
    SaveValues = true;
    SourceTable = Date;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Period Start"; "Period Start")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Period Start';
                    Editable = false;
                }
                field("Period Name"; "Period Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Period Name';
                    Editable = false;
                }
                field("Calendar.""Working Hours"""; Calendar."Working Hours")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    BlankNumbers = BlankZero;
                    Caption = 'Work Hours';
                    DrillDown = true;
                    Editable = false;
                }
                field("Calendar.""Working Days"""; Calendar."Working Days")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    BlankNumbers = BlankZero;
                    Caption = 'Work Days';
                    DrillDown = true;
                    Editable = false;
                }
                field("Calendar.""Weekend Days"""; Calendar."Weekend Days")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    BlankZero = true;
                    Caption = 'Weekend Days';
                    DrillDown = true;
                    Editable = false;
                }
                field("Calendar.Holidays"; Calendar.Holidays)
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Caption = 'Holidays';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        SetDateFilter;
        Calendar.CalcFields("Working Hours", "Working Days", "Weekend Days", Holidays);
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        exit(PeriodFormMgt.FindDate(Which, Rec, GLPeriodLength));
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        exit(PeriodFormMgt.NextDate(Steps, Rec, GLPeriodLength));
    end;

    trigger OnOpenPage()
    begin
        Reset;
    end;

    var
        Calendar: Record "Payroll Calendar";
        PeriodFormMgt: Codeunit PeriodFormManagement;
        GLPeriodLength: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        AmountType: Option "Net Change","Balance at Date";

    [Scope('OnPrem')]
    procedure Set(var NewCalendar: Record "Payroll Calendar"; NewGLPeriodLength: Integer; NewAmountType: Option "Net Change",Balance)
    begin
        Calendar.Copy(NewCalendar);
        GLPeriodLength := NewGLPeriodLength;
        AmountType := NewAmountType;
        CurrPage.Update(false);
    end;

    local procedure SetDateFilter()
    begin
        if AmountType = AmountType::"Net Change" then
            Calendar.SetRange("Date Filter", "Period Start", "Period End")
        else
            Calendar.SetRange("Date Filter", 0D, "Period End");
    end;
}

