page 35650 "HR Manager Role Center"
{
    Caption = 'HR Manager', Comment = 'Use same translation as ''Profile Description'' ';
    PageType = RoleCenter;

    layout
    {
        area(rolecenter)
        {
            group(Control1900724808)
            {
                ShowCaption = false;
                part(Control1903089308; "HR Manager Activities")
                {
                    ApplicationArea = Basic, Suite;
                }
                systempart(Control1901420308; Outlook)
                {
                }
            }
            group(Control1900724708)
            {
                ShowCaption = false;
                part(Control1903089808; "My Employees")
                {
                    ApplicationArea = Basic, Suite;
                }
                systempart(Control1901377608; MyNotes)
                {
                }
            }
        }
    }

    actions
    {
        area(reporting)
        {
            action("Personal Card T-54a")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Personal Card T-54a';
                Image = "Report";
                RunObject = Report "Personal Account T-54a";
            }
            action("Employee Card T-2")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Employee Card T-2';
                Image = "Report";
                RunObject = Report "Employee Card T-2";
            }
            action("Timesheet T-13")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Timesheet T-13';
                Image = "Report";
                RunObject = Report "Timesheet T-13";
            }
            action("Note-Calculation T-61")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Note-Calculation T-61';
                Image = "Report";
                RunObject = Report "Note-Calculation T-61";
            }
            action("Employee - Birthdays")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Employee - Birthdays';
                Image = "Report";
                RunObject = Report "Employee - Birthdays";
            }
            action("Employee - Phone Nos.")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Employee - Phone Nos.';
                Image = "Report";
                RunObject = Report "Employee - Phone Nos.";
            }
            action("Employee - Qualifications")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Employee - Qualifications';
                Image = "Report";
                RunObject = Report "Employee - Qualifications";
            }
            action("Employee - Relatives")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Employee - Relatives';
                Image = "Report";
                RunObject = Report "Employee - Relatives";
            }
        }
        area(embedding)
        {
            action(Persons)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Persons';
                RunObject = Page "Person List";
            }
            action(Employees)
            {
                Caption = 'Employees';
                RunObject = Page "Employee List";
            }
            action("Active Employees")
            {
                Caption = 'Active Employees';
                RunObject = Page "Employee List";
                RunPageView = WHERE(Status = CONST(Active));
            }
            action("Inactive Employees")
            {
                Caption = 'Inactive Employees';
                RunObject = Page "Employee List";
                RunPageView = WHERE(Status = CONST(Inactive));
            }
            action(Positions)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Positions';
                RunObject = Page "Actual Positions";
            }
            action("Approved Positions")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Approved Positions';
                RunObject = Page "Actual Positions";
                RunPageView = WHERE(Status = CONST(Approved));
            }
            action("Budget Positions")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Budget Positions';
                RunObject = Page "Budgeted Positions";
            }
            action("Approved Budget Positions")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Approved Budget Positions';
                RunObject = Page "Budgeted Positions";
                RunPageView = WHERE(Status = CONST(Approved));
            }
            action("Labor Contracts")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Labor Contracts';
                RunObject = Page "Labor Contracts";
            }
            action("Approved Labor Contracts")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Approved Labor Contracts';
                RunObject = Page "Labor Contracts";
                RunPageView = WHERE(Status = CONST(Approved));
            }
            action("Vacation Requests")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Vacation Requests';
                RunObject = Page "Vacation Requests";
            }
            action("Approved Vacation Requests")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Approved Vacation Requests';
                RunObject = Page "Vacation Requests";
                RunPageView = WHERE(Status = CONST(Approved));
            }
            action("Vacation Orders")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Vacation Orders';
                RunObject = Page "Vacation Orders";
            }
            action("Sick Leave Orders")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Sick Leave Orders';
                RunObject = Page "Sick Leave Orders";
            }
            action("Travel Orders")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Travel Orders';
                RunObject = Page "Travel Orders";
            }
            action("Other Absence Orders")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Other Absence Orders';
                RunObject = Page "Other Absence Orders";
            }
        }
        area(sections)
        {
            group("Posted Documents")
            {
                Caption = 'Posted Documents';
                Image = FiledPosted;
                action(Action1210029)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vacation Orders';
                    RunObject = Page "Posted Vacation Orders";
                }
                action(Action1210030)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sick Leave Orders';
                    RunObject = Page "Posted Sick Leave Orders";
                }
                action(Action1210031)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Travel Orders';
                    RunObject = Page "Posted Travel Orders";
                }
                action(Action1210008)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Other Absence Orders';
                    RunObject = Page "Posted Other Absence Orders";
                }
                action("Staff List Orders")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Staff List Orders';
                    RunObject = Page "Posted Staff List Orders";
                }
            }
            group(Archive)
            {
                Caption = 'Archive';
                action("Closed Positions")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Closed Positions';
                    RunObject = Page "Position List";
                    RunPageView = WHERE(Status = CONST(Closed));
                }
                action("Closed Labor Contracts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Closed Labor Contracts';
                    RunObject = Page "Labor Contracts";
                    RunPageView = WHERE(Status = CONST(Closed));
                }
                action("Archived Staff Lists")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Archived Staff Lists';
                    RunObject = Page "Staff List Archives";
                }
            }
            group(Administration)
            {
                Caption = 'Administration';
                Image = Administration;
                action("Organizational Units")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Organizational Units';
                    RunObject = Page "Organizational Units";
                    ToolTip = 'View the list of company departments that exist.';
                }
                action("Job Titles")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Job Titles';
                    RunObject = Page "Job Titles";
                }
                action("Employment Contracts")
                {
                    Caption = 'Employment Contracts';
                    RunObject = Page "Employment Contracts";
                }
                action("Employee Categories")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Employee Categories';
                    RunObject = Page "Employee Category";
                }
                action("Misc. Articles")
                {
                    Caption = 'Misc. Articles';
                    RunObject = Page "Misc. Articles";
                }
                action(Qualifications)
                {
                    Caption = 'Qualifications';
                    Image = Certificate;
                    RunObject = Page Qualifications;
                }
                action("Payroll Calendars")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payroll Calendars';
                    RunObject = Page "Payroll Calendar List";
                }
            }
        }
        area(processing)
        {
            separator(Tasks)
            {
                Caption = 'Tasks';
                IsHeader = true;
            }
            action("Vacation Schedule")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Vacation Schedule';
                Image = CalendarChanged;
                RunObject = Page "Vacation Schedule Worksheet";
            }
            action("Staff List")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Staff List';
                Image = CustomerList;
                RunObject = Page "Staff List";
            }
            action("Staff List Order")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Staff List Order';
                Image = "Order";
                RunObject = Page "Staff List Order";
            }
            action("Organisation Structure")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Organisation Structure';
                Image = Hierarchy;
                RunObject = Page "Organization Structure";
            }
            action("Timesheet Status")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Timesheet Status';
                Image = Timesheet;
                RunObject = Page "Timesheet Status";
            }
            action("Employee Journal")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Employee Journal';
                Image = Journal;
                RunObject = Page "Employee Journal";
            }
        }
    }
}

