page 35653 "Payroll Activities"
{
    Caption = 'Activities';
    PageType = CardPart;
    SourceTable = "HRP Cue";

    layout
    {
        area(content)
        {
            cuegroup(Timesheets)
            {
                Caption = 'Timesheets';
                field("Open Timesheets"; "Open Timesheets")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Timesheet Status";
                }
                field("Released Timesheets"; "Released Timesheets")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Timesheet Status";
                }
            }
            cuegroup("Absence Orders")
            {
                Caption = 'Absence Orders';
                field("Released Vacation Orders"; "Released Vacation Orders")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Vacation Orders";
                }
                field("Released Sick Leave Orders"; "Released Sick Leave Orders")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Sick Leave Orders";
                }
                field("Released Travel Orders"; "Released Travel Orders")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Travel Orders";
                }
                field("Released Other Absence Orders"; "Released Other Absence Orders")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Other Absence Orders";
                }
            }
            cuegroup(Calculation)
            {
                Caption = 'Calculation';
                field("Payroll Documents"; "Payroll Documents")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Payroll Documents";
                }

                actions
                {
                    action("New Payroll Documents")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Payroll Documents';
                        RunObject = Report "Suggest Payroll Documents";
                        RunPageMode = Create;
                    }
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        Reset;
        if not Get then begin
            Init;
            Insert;
        end;

        if PayrollPeriod.Get(PayrollPeriod.PeriodByDate(WorkDate)) then
            SetRange("Date Filter", PayrollPeriod."Starting Date", PayrollPeriod."Ending Date")
        else
            SetRange("Date Filter", 0D, WorkDate);
    end;

    var
        PayrollPeriod: Record "Payroll Period";
}

