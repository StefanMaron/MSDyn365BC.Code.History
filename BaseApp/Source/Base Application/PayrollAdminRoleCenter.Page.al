page 35651 "Payroll Admin Role Center"
{
    Caption = 'Payroll Admin', Comment = 'Use same translation as ''Profile Description'' ';
    PageType = RoleCenter;

    layout
    {
        area(rolecenter)
        {
            group(Control1900724808)
            {
                ShowCaption = false;
                part(Control1903089408; "Payroll Activities")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
            group(Control1900724708)
            {
                ShowCaption = false;
                systempart(Control1901420308; Outlook)
                {
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
            action("Employee PaySheet")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Employee PaySheet';
                Image = "Report";
                RunObject = Report "Employee Paysheet";
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
            action(Vendors)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Vendors';
                Image = Vendor;
                RunObject = Page "Vendor List";
                ToolTip = 'View or edit detailed information for the vendors that you trade with. From each vendor card, you can open related information, such as purchase statistics and ongoing orders, and you can define special prices and line discounts that the vendor grants you if certain conditions are met.';
            }
            action(Balance)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Balance';
                Image = Balance;
                RunObject = Page "Vendor List";
                RunPageView = WHERE("Balance (LCY)" = FILTER(<> 0));
                ToolTip = 'View a summary of the balance at date or the net change for different time periods for the cost types that you select. You can select different time intervals and set filters on the cost centers and cost objects that you want to see.';
            }
            action("Payroll Documents")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Payroll Documents';
                RunObject = Page "Payroll Documents";
            }
            action("Payroll Journal")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Payroll Journal';
                RunObject = Page "Purchase Order List";
            }
        }
        area(sections)
        {
            group("Posted Documents")
            {
                Caption = 'Posted Documents';
                Image = FiledPosted;
                action("Payroll Registers")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payroll Registers';
                    RunObject = Page "Payroll Registers";
                }
                action("Staff List Orders")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Staff List Orders';
                    RunObject = Page "Posted Staff List Orders";
                }
                action("Vacation Orders")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vacation Orders';
                    RunObject = Page "Posted Vacation Orders";
                }
                action("Sick Leave Orders")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sick Leave Orders';
                    RunObject = Page "Posted Sick Leave Orders";
                }
                action("Travel Orders")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Travel Orders';
                    RunObject = Page "Posted Travel Orders";
                }
                action("Other Absence Orders")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Other Absence Orders';
                    RunObject = Page "Posted Other Absence Orders";
                }
                action(Action1210015)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payroll Documents';
                    RunObject = Page "Posted Payroll Documents";
                }
            }
            group(Administration)
            {
                Caption = 'Administration';
                Image = Administration;
                action("Sick Leave Setup")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sick Leave Setup';
                    RunObject = Page "Sick Leave Setup";
                }
                action(Action1210017)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payroll Documents';
                    RunObject = Page "Payroll Documents";
                }
                action("Payroll Element List")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payroll Element List';
                    RunObject = Page "Payroll Element List";
                }
                action("Payroll Calc Types")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payroll Calc Types';
                    RunObject = Page "Payroll Calc Types";
                }
                action(Action1210020)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payroll Calc Types';
                    RunObject = Page "Payroll Calc Types";
                }
                action("Payroll Calculation Function")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payroll Calculation Function';
                    RunObject = Page "Payroll Calculation Functions";
                }
                action("AE Calculation Setup")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'AE Calculation Setup';
                    RunObject = Page "AE Calculation Setup";
                    ToolTip = 'View or edit calculations for average earning (AE).';
                }
                action("Payroll Periods")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payroll Periods';
                    RunObject = Page "Payroll Periods";
                }
                action("Payroll Calendar List")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payroll Calendar List';
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
            action("Staff List")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Staff List';
                Image = CustomerList;
                RunObject = Page "Staff List";
            }
            action("Organisation Structure")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Organisation Structure';
                Image = Hierarchy;
                RunObject = Page "Organization Structure";
            }
            action(Timesheet)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Timesheet';
                Image = Timesheet;
                RunObject = Page "Timesheet Status";
            }
            separator(Action80)
            {
            }
            action("G/L Account Turnover")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'G/L Account Turnover';
                Image = Turnover;
                RunObject = Page "G/L Account Turnover";
                ToolTip = 'View the general ledger account summary. You can use this information to verify if the entries are correct on general ledger accounts.';
            }
            action("Vendor G/L Turnover")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Vendor G/L Turnover';
                Image = Turnover;
                RunObject = Page "Vendor G/L Turnover";
                ToolTip = 'Analyze vendors'' turnover and account balances.';
            }
            separator(Action84)
            {
                Caption = 'Administration';
                IsHeader = true;
            }
            action("Payroll Directory")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Payroll Directory';
                Image = FileContract;
                RunObject = Page "Payroll Directory";
            }
            action("Human Resources Setup")
            {
                Caption = 'Human Resources Setup';
                Image = HRSetup;
                RunObject = Page "Human Resources Setup";
            }
            separator(History)
            {
                Caption = 'History';
                IsHeader = true;
            }
            action("Navi&gate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Navi&gate';
                Image = Navigate;
                RunObject = Page Navigate;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';
            }
        }
    }
}

