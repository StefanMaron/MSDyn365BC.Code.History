report 17428 "Create Calendar Line"
{
    Caption = 'Create Calendar Line';
    ProcessingOnly = true;

    dataset
    {
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(StartDate; StartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Start Date';
                        ToolTip = 'Specifies the beginning of the period for which entries are adjusted. This field is usually left blank, but you can enter a date.';
                    }
                    field(EndDate; EndDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'End Date';
                        ToolTip = 'Specifies the date to which the report or batch job processes information.';
                    }
                    field(ClearLines; ClearLines)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Clear Lines';
                        MultiLine = true;
                        ToolTip = 'Specifies if the lines that are associated with the VAT ledger are deleted.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        PayrollCalendarSetup: Record "Payroll Calendar Setup";
    begin
        if StartDate = 0D then
            Error(Text14800);
        if EndDate = 0D then
            Error(Text14801);
        if StartDate > EndDate then
            Error(Text14802);

        CalendarLine.Reset;
        CalendarLine.SetRange("Calendar Code", Calendar.Code);

        if not ClearLines then begin
            if CalendarLine.FindLast then
                if StartDate > CalcDate('<+1D>', CalendarLine.Date) then
                    Error(Text14803, StartDate, CalcDate('<1D>', CalendarLine.Date));
            if CalendarLine.FindFirst then
                if EndDate < CalcDate('<-1D>', CalendarLine.Date) then
                    Error(Text14804, EndDate, CalcDate('<-1D>', CalendarLine.Date));
            CalendarLine.SetRange(Date, StartDate, EndDate);
            if CalendarLine.FindFirst then
                if not Confirm(Text14805, false, StartDate, EndDate) then
                    exit;
        end;

        if Calendar."Shift Start Date" <> 0D then
            if Calendar."Shift Days" < PayrollCalendarSetup.GetMaxShiftDay(Calendar.Code) then
                Error(Text14807, PayrollCalendarSetup.GetMaxShiftDay(Calendar.Code));

        CalendarLine.SetRange(Date);

        with CalendarLine do begin
            if ClearLines then
                DeleteAll(true)
            else begin
                SetRange(Date, StartDate, EndDate);
                DeleteAll(true);
            end;
            Window.Open(Text14806);

            "Calendar Code" := Calendar.Code;
            Date := StartDate;
            repeat
                Init;
                Validate(Date);
                Insert;
                Window.Update(1, Date);
                Date := Date + 1;
            until Date > EndDate;
            Window.Close;
        end;
    end;

    var
        Calendar: Record "Payroll Calendar";
        CalendarLine: Record "Payroll Calendar Line";
        Window: Dialog;
        StartDate: Date;
        EndDate: Date;
        ClearLines: Boolean;
        Text14800: Label 'Please enter Start Date.';
        Text14801: Label 'Please enter End Date.';
        Text14802: Label 'Start Date cannot be later than End Date.';
        Text14803: Label 'Start Date %1 cannot be later than %2.';
        Text14804: Label 'End Date %1 cannot be earlier than %2.';
        Text14805: Label 'Calendar lines for period from %1 to %2 already exists. Do you want to replace these lines?';
        Text14806: Label 'Create calendar lines  #1########';
        Text14807: Label 'Shift Days must be greater or equal than %1';

    [Scope('OnPrem')]
    procedure GetCalendar(NewCalendar: Record "Payroll Calendar")
    begin
        Calendar := NewCalendar;
    end;

    [Scope('OnPrem')]
    procedure SetCalendar(CalendarCode: Code[20]; NewStartDate: Date; NewEndDate: Date; NewClearLines: Boolean)
    begin
        StartDate := NewStartDate;
        EndDate := NewEndDate;
        ClearLines := NewClearLines;
        CurrReport.UseRequestPage := false;
        Calendar.Get(CalendarCode);
    end;
}

