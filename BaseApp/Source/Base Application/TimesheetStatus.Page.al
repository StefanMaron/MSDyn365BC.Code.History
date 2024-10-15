page 17440 "Timesheet Status"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Timesheet Status';
    PageType = Worksheet;
    SourceTable = "Timesheet Status";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                Editable = false;
                ShowCaption = false;
                field("Period Code"; "Period Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the period.';
                }
                field("Employee No."; "Employee No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved employee.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the timesheet is released or open.';
                }
                field("Calendar Days"; "Calendar Days")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of calendar days.';
                }
                field("Actual Calendar Days"; "Actual Calendar Days")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how many of the available days the employee actually worked. ';
                }
                field("Planned Work Days"; "Planned Work Days")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee''s planned work days.';
                }
                field("Actual Work Days"; "Actual Work Days")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how many of the employee''s planned work days the employee actually worked. ';
                }
                field("Planned Work Hours"; "Planned Work Hours")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee''s planned work hours.';
                }
                field("Actual Work Hours"; "Actual Work Hours")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how many of the employee''s planned work hours the employee actually worked. ';
                }
                field("Absence Calendar Days"; "Absence Calendar Days")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how many of the available days the employee was absent.';
                }
                field("Planned Night Hours"; "Planned Night Hours")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how many of the planned work hours are in the night time.';
                }
                field("Absence Work Days"; "Absence Work Days")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how many of the employee''s planned work days the employee was absent.';
                }
                field("Absence Hours"; "Absence Hours")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how many hours the employee was absent.';
                }
                field("Overtime Hours"; "Overtime Hours")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how many hours the employee worked overtime.';
                }
                field("Holiday Work Days"; "Holiday Work Days")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how many of the employee''s planned work days were changed to holidays.';
                }
                field("Holiday Work Hours"; "Holiday Work Hours")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how many of the employee''s planned work hours were changed to holiday hours.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Ti&mesheet")
            {
                Caption = 'Ti&mesheet';
                action("Employee Timesheet")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Employee Timesheet';
                    Image = Period;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ShortCutKey = 'Ctrl+F7';

                    trigger OnAction()
                    var
                        EmployeeTimesheet: Page "Employee Timesheet";
                    begin
                        Clear(EmployeeTimesheet);
                        PayrollPeriod.Get("Period Code");
                        EmployeeTimesheet.Set("Employee No.", PayrollPeriod."Ending Date");
                        EmployeeTimesheet.RunModal;
                    end;
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(Create)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create';
                    Image = New;

                    trigger OnAction()
                    begin
                        PayrollPeriod.Reset();
                        if PayrollPeriod.FindSet then
                            repeat
                                CopyFilter("Employee No.", Employee2."No.");
                                if Employee2.FindSet then
                                    repeat
                                        if not TimesheetStatus.Get(PayrollPeriod.Code, Employee2."No.") then
                                            TimesheetMgt.CreateTimesheet(Employee2, PayrollPeriod);
                                    until Employee2.Next = 0;
                            until PayrollPeriod.Next = 0;
                    end;
                }
                action(Update)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Update';
                    Image = Refresh;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Update the timesheet with any changes made by other users since you opened the window.';

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(TimesheetStatus);
                        if TimesheetStatus.FindSet then
                            repeat
                                TimesheetStatus.Calculate;
                                TimesheetStatus.Modify();
                            until TimesheetStatus.Next = 0;
                    end;
                }
                separator(Action1210044)
                {
                }
                action(Release)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Release';
                    Image = ReleaseDoc;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ShortCutKey = 'F9';
                    ToolTip = 'Enable the record for the next stage of processing. ';

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(TimesheetStatus);
                        if TimesheetStatus.FindSet then
                            repeat
                                TimesheetStatus.Release;
                            until TimesheetStatus.Next = 0;
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
                        CurrPage.SetSelectionFilter(TimesheetStatus);
                        if TimesheetStatus.FindSet then
                            repeat
                                TimesheetStatus.Reopen;
                            until TimesheetStatus.Next = 0;
                    end;
                }
            }
        }
    }

    var
        Employee2: Record Employee;
        PayrollPeriod: Record "Payroll Period";
        TimesheetStatus: Record "Timesheet Status";
        TimesheetMgt: Codeunit "Timesheet Management RU";
}

