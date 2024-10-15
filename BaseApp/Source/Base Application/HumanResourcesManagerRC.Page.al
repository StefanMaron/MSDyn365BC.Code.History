page 8902 "Human Resources Manager RC"
{
    Caption = 'Human Resources Manager RC';
    PageType = RoleCenter;
    actions
    {
        area(Sections)
        {
            group("Group")
            {
                Caption = 'Human Resources';
                action("Employees")
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Employees';
                    RunObject = page "Employee List";
                    Tooltip = 'Open the Employees page.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This action will be removed from this page';
                    ObsoleteTag = '15.3';
                }
                action("Absence Registration")
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Absence Registration';
                    RunObject = page "Absence Registration";
                    Tooltip = 'Open the Absence Registration page.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This action will be removed from this page';
                    ObsoleteTag = '15.3';
                }
                group("Group3")
                {
                    Caption = 'Vacation Planning';
                    action("Vacation Requests")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vacation Requests';
                        RunObject = page "Vacation Requests";
                        Tooltip = 'Open the Vacation Requests page.';
                    }
                    action("Vacation Schedule")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vacation Schedule';
                        RunObject = page "Vacation Schedule Names";
                        Tooltip = 'Open the Vacation Schedule page.';
                    }
                }
                group("Group4")
                {
                    Caption = 'Absence Orders';
                    action("Vacation Orders")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vacation Orders';
                        RunObject = page "Vacation Orders";
                        Tooltip = 'Open the Vacation Orders page.';
                    }
                    action("Sick Leave Orders")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sick Leave Orders';
                        RunObject = page "Sick Leave Orders";
                        Tooltip = 'Open the Sick Leave Orders page.';
                    }
                    action("Travel Orders")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Travel Orders';
                        RunObject = page "Travel Orders";
                        Tooltip = 'Open the Travel Orders page.';
                    }
                    action("Other Absence Orders")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Other Absence Orders';
                        RunObject = page "Other Absence Orders";
                        Tooltip = 'Open the Other Absence Orders page.';
                    }
                }
                group("Group5")
                {
                    Caption = 'Periodic Activities';
                    action("Import Elements")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Import Elements';
                        RunObject = report "Import Payroll Elements";
                        Tooltip = 'Run the Import Elements report.';
                    }
                    action("Import Calc. Functions")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Import Calc. Functions';
                        RunObject = report "Import Payroll Calc. Functions";
                        Tooltip = 'Run the Import Calc. Functions report.';
                    }
                    action("Import Calc. Groups")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Import Calc. Groups';
                        RunObject = report "Import Payroll Calc. Groups";
                        Tooltip = 'Run the Import Calc. Groups report.';
                    }
                    action("Import Payroll Analysis Rep.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Import Payroll Analysis Rep.';
                        RunObject = report "Import Payroll Analysis Rep.";
                        Tooltip = 'Run the Import Payroll Analysis Rep. report.';
                    }
                    action("Future Period Vacation Posting")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Future Period Vacation Posting';
                        RunObject = report "Future Period Vacation Posting";
                        Tooltip = 'Run the Future Period Vacation Posting report.';
                    }
                    action("Create Salary Indexation Docs.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Create Salary Indexation Docs.';
                        RunObject = report "Create Salary Indexation Docs.";
                        Tooltip = 'Run the Create Salary Indexation Docs. report.';
                    }
                    action("Calculate Person Income")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Calculate Person Income';
                        RunObject = report "Calculate Person Income";
                        Tooltip = 'Run the Calculate Person Income report.';
                    }
                    action("Apply Employee Payments")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Apply Employee Payments';
                        RunObject = report "Apply Employee Payments";
                        Tooltip = 'Run the Apply Employee Payments report.';
                    }
                    action("Apply Budget Tax Payments")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Apply Budget Tax Payments';
                        RunObject = report "Apply Budget Tax Payments";
                        Tooltip = 'Run the Apply Budget Tax Payments report.';
                    }
                    group("Group6")
                    {
                        Caption = 'Personified Reporting';
                        action("Export ADV-1 form")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Export ADV-1 form';
                            RunObject = report "Export ADV-1 form";
                            Tooltip = 'Run the Export ADV-1 form report.';
                        }
                        action("Export SPV-1 form")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Export SPV-1 form';
                            RunObject = report "Export SPV-1 form";
                            Tooltip = 'Run the Export SPV-1 form report.';
                        }
                        action("Export SZV form")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Export SZV form';
                            RunObject = report "Export SZV form";
                            Tooltip = 'Run the Export SZV form report.';
                        }
                        action("Export SZV-6-3 form")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Export SZV-6-3 form';
                            RunObject = report "Export SZV-6-3 form";
                            Tooltip = 'Run the Export SZV-6-3 form report.';
                        }
                        action("Export SZV-6-4 form")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Export SZV-6-4 form';
                            RunObject = report "Export SZV-6-4 form";
                            Tooltip = 'Run the Export SZV-6-4 form report.';
                        }
                        action("Export RSV form")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Export RSV form';
                            RunObject = report "Export RSV form";
                            Tooltip = 'Run the Export RSV form report.';
                        }
                    }
                }
                group("Group7")
                {
                    Caption = 'Analysis & Reporting';
                    action("Payroll Analysis Reports")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payroll Analysis Reports';
                        RunObject = page "Payroll Analysis Report Names";
                        Tooltip = 'Open the Payroll Analysis Reports page.';
                    }
                    action("Payroll Analysis by Dimensions")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payroll Analysis by Dimensions';
                        RunObject = page "Payroll Analysis by Dimensions";
                        Tooltip = 'Open the Payroll Analysis by Dimensions page.';
                    }
                    group("Group8")
                    {
                        Caption = 'Setup';
                        action("Pay. Analysis Line Templates")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Pay. Analysis Line Templates';
                            RunObject = page "Pay. Analysis Line Templates";
                            Tooltip = 'Open the Pay. Analysis Line Templates page.';
                        }
                        action("Pay. Analysis Column Templates")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Pay. Analysis Column Templates';
                            RunObject = page "Pay. Analysis Column Templates";
                            Tooltip = 'Open the Pay. Analysis Column Templates page.';
                        }
                        action("Payroll Analysis View Card")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Payroll Analysis Views';
                            RunObject = page "Payroll Analysis View List";
                            Tooltip = 'Open the Payroll Analysis Views page.';
                        }
                    }
                }
                group("Group1")
                {
                    Caption = 'Reports';
                    action("Employee - Absences by Causes")
                    {
                        ApplicationArea = BasicHR;
                        Caption = 'Employee Absences by Causes';
                        RunObject = report "Employee - Absences by Causes";
                        Tooltip = 'Run the Employee Absences by Causes report.';
                    }
                    action("Employee - Addresses")
                    {
                        ApplicationArea = BasicHR;
                        Caption = 'Employee Addresses';
                        RunObject = report "Employee - Addresses";
                        Tooltip = 'Run the Employee Addresses report.';
                    }
                    action("Employee - Alt. Addresses")
                    {
                        ApplicationArea = BasicHR;
                        Caption = 'Employee Alt. Addresses';
                        RunObject = report "Employee - Alt. Addresses";
                        Tooltip = 'Run the Employee Alt. Addresses report.';
                    }
                    action("Employee - Birthdays")
                    {
                        ApplicationArea = BasicHR;
                        Caption = 'Employee Birthdays';
                        RunObject = report "Employee - Birthdays";
                        Tooltip = 'Run the Employee Birthdays report.';
                    }
                    action("Employee - Confidential Info.")
                    {
                        ApplicationArea = BasicHR;
                        Caption = 'Employee Confidential Info.';
                        RunObject = report "Employee - Confidential Info.";
                        Tooltip = 'Run the Employee Confidential Info. report.';
                    }
                    action("Employee - Contracts")
                    {
                        ApplicationArea = BasicHR;
                        Caption = 'Employee Contracts';
                        RunObject = report "Employee - Contracts";
                        Tooltip = 'Run the Employee Contracts report.';
                    }
                    action("Employee - Labels")
                    {
                        ApplicationArea = BasicHR;
                        Caption = 'Employee Labels';
                        RunObject = report "Employee - Labels";
                        Tooltip = 'Run the Employee Labels report.';
                    }
                    action("Employee - List")
                    {
                        ApplicationArea = BasicHR;
                        Caption = 'Employee List';
                        RunObject = report "Employee - List";
                        Tooltip = 'Run the Employee List report.';
                    }
                    action("Employee - Misc. Article Info.")
                    {
                        ApplicationArea = BasicHR;
                        Caption = 'Employee Misc. Article Info.';
                        RunObject = report "Employee - Misc. Article Info.";
                        Tooltip = 'Run the Employee Misc. Article Info. report.';
                    }
                    action("Employee - Qualifications")
                    {
                        ApplicationArea = BasicHR;
                        Caption = 'Employee Qualifications';
                        RunObject = report "Employee - Qualifications";
                        Tooltip = 'Run the Employee Qualifications report.';
                    }
                    action("Employee - Relatives")
                    {
                        ApplicationArea = BasicHR;
                        Caption = 'Employee Relatives';
                        RunObject = report "Employee - Relatives";
                        Tooltip = 'Run the Employee Relatives report.';
                    }
                    action("Employee - Staff Absences")
                    {
                        ApplicationArea = BasicHR;
                        Caption = 'Staff Absences';
                        RunObject = report "Employee - Staff Absences";
                        Tooltip = 'Run the Staff Absences report.';
                    }
                    action("Employee - Unions")
                    {
                        ApplicationArea = BasicHR;
                        Caption = 'Employee Unions';
                        RunObject = report "Employee - Unions";
                        Tooltip = 'Run the Employee Unions report.';
                    }
                    group("Group9")
                    {
                        Caption = 'Payroll';
                        action("Form 1-NDFL")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Form 1-NDFL';
                            RunObject = report "Form 1-NDFL";
                            Tooltip = 'Run the Form 1-NDFL report.';
                        }
                        action("Form 2-NDFL")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Form 2-NDFL';
                            RunObject = report "Form 2-NDFL";
                            Tooltip = 'Run the Form 2-NDFL report.';
                        }
                        action("XML Employee Income")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'XML Employee Income';
                            RunObject = report "Export Form 2-NDFL to XML";
                            Tooltip = 'Run the XML Employee Income report.';
                        }
                        action("Paysheet T-51")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Paysheet T-51';
                            RunObject = report "Paysheet T-51";
                            Tooltip = 'Run the Paysheet T-51 report.';
                        }
                        action("Pay Sheet T-53")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Pay Sheet T-53';
                            RunObject = report "Pay Sheet T-53";
                            Tooltip = 'Run the Pay Sheet T-53 report.';
                        }
                        action("Personal Account T-54a")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Personal Account T-54a';
                            RunObject = report "Personal Account T-54a";
                            Tooltip = 'Run the Personal Account T-54a report.';
                        }
                        action("Statistic Form P-4")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Statistic Form P-4';
                            RunObject = report "Statistic Form P-4";
                            Tooltip = 'Run the Statistic Form P-4 report.';
                        }
                        action("Statistic Form FNS-1")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Statistic Form FNS-1';
                            RunObject = report "Statistic Form FNS-1";
                            Tooltip = 'Run the Statistic Form FNS-1 report.';
                        }
                        action("Payroll Calculation - Setup")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Payroll Calculation - Setup';
                            RunObject = report "Payroll Calculation - Setup";
                            Tooltip = 'Run the Payroll Calculation - Setup report.';
                        }
                        action("Employee Paysheet")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Employee Paysheet';
                            RunObject = report "Employee Paysheet";
                            Tooltip = 'Run the Employee Paysheet report.';
                        }
                    }
                    group("Group10")
                    {
                        Caption = 'Human Resources';
                        action("Employee Card T-2")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Employee Card T-2';
                            RunObject = report "Employee Card T-2";
                            Tooltip = 'Run the Employee Card T-2 report.';
                        }
                        action("HR Generic Report")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'HR Generic Report';
                            RunObject = report "HR Generic Report";
                            Tooltip = 'Run the HR Generic Report report.';
                        }
                        action("Staffing List - Vacancies")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Staffing List - Vacancies';
                            RunObject = report "Staff List Vacant Positions";
                            Tooltip = 'Run the Staffing List - Vacancies report.';
                        }
                        action("Staffing List T-3")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Staffing List T-3';
                            RunObject = report "Staffing List T-3";
                            Tooltip = 'Run the Staffing List T-3 report.';
                        }
                        action("Timesheet T-13")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Timesheet T-13';
                            RunObject = report "Timesheet T-13";
                            Tooltip = 'Run the Timesheet T-13 report.';
                        }
                        action("Average Headcount by Employees")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Average HC by Employees';
                            RunObject = report "Average Headcount by Employees";
                            Tooltip = 'Run the Average HC by Employees report.';
                        }
                        action("Average Headcount by Org. Unit")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Average HC by Org. Unit';
                            RunObject = report "Average Headcount by Org. Unit";
                            Tooltip = 'Run the Average HC by Org. Unit report.';
                        }
                        action("Average Employee Count")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Average Employee Count';
                            RunObject = report "Average Employee Count";
                            Tooltip = 'Run the Average Employee Count report.';
                        }
                        action("Vacation Schedule T-7")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Vacation Schedule T-7';
                            RunObject = report "Vacation Schedule T-7";
                            Tooltip = 'Run the Vacation Schedule T-7 report.';
                        }
                        action("Employee Vacation Balance")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Employee Vacation Balance';
                            RunObject = report "Employee Vacation Balance";
                            Tooltip = 'Run the Employee Vacation Balance report.';
                        }
                    }
                }
                group("Group11")
                {
                    Caption = 'History';
                    action("G/L Registers")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'G/L Registers';
                        RunObject = page "G/L Registers";
                        Tooltip = 'Open the G/L Registers page.';
                    }
                    action("Payroll Registers")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payroll Registers';
                        RunObject = page "Payroll Registers";
                        Tooltip = 'Open the Payroll Registers page.';
                    }
                    action("Staff List Change Orders")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Staff List Orders';
                        RunObject = page "Posted Staff List Orders";
                        Tooltip = 'Open the Posted Staff List Orders page.';
                    }
                    action("Posted Vacation Orders")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Vacation Orders';
                        RunObject = page "Posted Vacation Orders";
                        Tooltip = 'Open the Posted Vacation Orders page.';
                    }
                    action("Posted Sick Leave Orders")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Sick Leave Orders';
                        RunObject = page "Posted Sick Leave Orders";
                        Tooltip = 'Open the Posted Sick Leave Orders page.';
                    }
                    action("Posted Travel Orders")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Travel Orders';
                        RunObject = page "Posted Travel Orders";
                        Tooltip = 'Open the Posted Travel Orders page.';
                    }
                    action("Posted Other Absence Orders")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Other Absence Orders';
                        RunObject = page "Posted Other Absence Orders";
                        Tooltip = 'Open the Posted Other Absence Orders page.';
                    }
                    action("Posted Payroll Documents")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Payroll Documents';
                        RunObject = page "Posted Payroll Documents";
                        Tooltip = 'Open the Posted Payroll Documents page.';
                    }
                    action("Navigate")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Find entries...';
                        RunObject = page "Navigate";
                        Tooltip = 'Open the Navigate page.';
                    }
                    action("Archived Staff Lists")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Archived Staff Lists';
                        RunObject = page "Staff List Archives";
                        Tooltip = 'Open the Archived Staff Lists page.';
                    }
                }
            }
            group("Group12")
            {
                Caption = 'Staff';
                action("Employees1")
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Employees';
                    RunObject = page "Employee List";
                    Tooltip = 'Open the Employees page.';
                }
                action("Persons")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Persons';
                    RunObject = page "Person List";
                    Tooltip = 'Open the Persons page.';
                }
                action("Labor Contracts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Labor Contracts';
                    RunObject = page "Labor Contracts";
                    Tooltip = 'Open the Labor Contracts page.';
                }
                action("Group Orders")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Group Orders';
                    RunObject = page "Group Order";
                    Tooltip = 'Open the Group Orders page.';
                }
                action("Employee Journal")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Employee Journal';
                    RunObject = page "Employee Journal";
                    Tooltip = 'Open the Employee Journal page.';
                }
            }
            group("Group13")
            {
                Caption = 'Organization';
                action("Actual Positions")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Actual Positions';
                    RunObject = page "Actual Positions";
                    Tooltip = 'Open the Actual Positions page.';
                }
                action("Budgeted Positions")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Budgeted Positions';
                    RunObject = page "Budgeted Positions";
                    Tooltip = 'Open the Budgeted Positions page.';
                }
                action("Staff List")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Staff List';
                    RunObject = page "Staff List";
                    Tooltip = 'Open the Staff List page.';
                }
                action("Staff List Orders")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Staff List Orders';
                    RunObject = page "Staff List Orders";
                    Tooltip = 'Open the Staff List Orders page.';
                }
                action("Organisation Structure")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Organization Structure';
                    RunObject = page "Organization Structure";
                    Tooltip = 'Open the Organization Structure page.';
                }
                action("Timesheet Status")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Timesheet Status';
                    RunObject = page "Timesheet Status";
                    Tooltip = 'Open the Timesheet Status page.';
                }
            }
            group("Group14")
            {
                Caption = 'Payroll';
                action("Person Vendors")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Person Vendors';
                    RunObject = page "Person Vendors";
                    Tooltip = 'Open the Person Vendors page.';
                }
                action("Payroll Elements")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payroll Elements';
                    RunObject = page "Payroll Element List";
                    Tooltip = 'Open the Payroll Elements page.';
                }
                action("Payroll Status")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payroll Status';
                    RunObject = page "Payroll Status";
                    Tooltip = 'Open the Payroll Status page.';
                }
                action("Payroll Document List")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payroll Documents';
                    RunObject = page "Payroll Document List";
                    Tooltip = 'Open the Payroll Documents page.';
                }
                action("Payment Journal")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payment Journal';
                    RunObject = page "Payment Journal";
                    Tooltip = 'Open the Payment Journal page.';
                }
            }
            group("Group2")
            {
                Caption = 'Setup';
                action("Human Resources Setup")
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Human Resources Setup';
                    RunObject = page "Human Resources Setup";
                    Tooltip = 'Open the Human Resources Setup page.';
                }
                action("Human Resources Units of Measu")
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Human Resources Units of Measure';
                    RunObject = page "Human Res. Units of Measure";
                    Tooltip = 'Open the Human Resources Units of Measure page.';
                }
                action("Causes of Inactivity")
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Causes of Inactivity';
                    RunObject = page "Causes of Inactivity";
                    Tooltip = 'Open the Causes of Inactivity page.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This action will be removed from this page';
                    ObsoleteTag = '15.3';
                }
                action("Grounds for Termination")
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Grounds for Termination';
                    RunObject = page "Grounds for Termination";
                    Tooltip = 'Open the Grounds for Termination page.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This action will be removed from this page';
                    ObsoleteTag = '15.3';
                }
                action("Unions")
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Unions';
                    RunObject = page "Unions";
                    Tooltip = 'Open the Unions page.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This action will be removed from this page';
                    ObsoleteTag = '15.3';
                }
                action("Employment Contracts")
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Employment Contracts';
                    RunObject = page "Employment Contracts";
                    Tooltip = 'Open the Employment Contracts page.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This action will be removed from this page';
                    ObsoleteTag = '15.3';
                }
                action("Relatives")
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Relatives';
                    RunObject = page "Relatives";
                    Tooltip = 'Open the Relatives page.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This action will be removed from this page';
                    ObsoleteTag = '15.3';
                }
                action("Misc. Articles")
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Employee Misc. Articles';
                    RunObject = page "Misc. Articles";
                    Tooltip = 'Open the Employee Misc. Articles page.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This action will be removed from this page';
                    ObsoleteTag = '15.3';
                }
                action("Confidential")
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Confidential';
                    RunObject = page "Confidential";
                    Tooltip = 'Open the Confidential page.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This action will be removed from this page';
                    ObsoleteTag = '15.3';
                }
                action("Qualifications")
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Qualifications';
                    RunObject = page "Qualifications";
                    Tooltip = 'Open the Qualifications page.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This action will be removed from this page';
                    ObsoleteTag = '15.3';
                }
                action("Payroll Periods")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payroll Periods';
                    RunObject = page "Payroll Periods";
                    Tooltip = 'Open the Payroll Periods page.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This action will be removed from this page';
                    ObsoleteTag = '15.3';
                }
                action("Payroll Calendars")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payroll Calendars';
                    RunObject = page "Payroll Calendar List";
                    Tooltip = 'Open the Payroll Calendars page.';
                }
                group("Group15")
                {
                    Caption = 'Labor Contracts';
                    action("Organizational Units")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Organizational Units';
                        RunObject = page "Organizational Units";
                        Tooltip = 'Open the Organizational Units page.';
                    }
                    action("Job Titles")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Job Titles';
                        RunObject = page "Job Titles";
                        Tooltip = 'Open the Job Titles page.';
                    }
                    action("Employee Statistics Groups")
                    {
                        ApplicationArea = BasicHR;
                        Caption = 'Employee Statistics Groups';
                        RunObject = page "Employee Statistics Groups";
                        Tooltip = 'Open the Employee Statistics Groups page.';
                    }
                    action("Employee Category")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Employee Category';
                        RunObject = page "Employee Category";
                        Tooltip = 'Open the Employee Category page.';
                    }
                    action("Default Labor Contract Terms")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Default Labor Contract Terms';
                        RunObject = page "Default Labor Contract Terms";
                        Tooltip = 'Open the Default Labor Contract Terms page.';
                    }
                    action("Employee Journal Templates")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Employee Journal Templates';
                        RunObject = page "Employee Journal Templates";
                        Tooltip = 'Open the Employee Journal Templates page.';
                    }
                }
                group("Group16")
                {
                    Caption = 'Timesheet';
                    action("Timesheet Codes")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Timesheet Codes';
                        RunObject = page "Timesheet Codes";
                        Tooltip = 'Open the Timesheet Codes page.';
                    }
                    // action("Time Activity Codes")
                    // {
                    //     ApplicationArea =;
                    //     Caption = 'Time Activity Codes';
                    //     RunObject = page "Causes of Absence";
                    // }
                    action("Time Activity Groups")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Time Activity Groups';
                        RunObject = page "Time Activity Groups";
                        Tooltip = 'Open the Time Activity Groups page.';
                    }
                    action("Worktime Norms")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Worktime Norms';
                        RunObject = page "Worktime Norms";
                        Tooltip = 'Open the Worktime Norms page.';
                    }
                }
                group("Group17")
                {
                    Caption = 'Personal';
                    action("HR Field Groups")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'HR Field Groups';
                        RunObject = page "HR Field Group";
                        Tooltip = 'Open the HR Field Groups page.';
                    }
                    action("Taxpayer Document Types")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Taxpayer Document Types';
                        RunObject = page "Taxpayer Document Types";
                        Tooltip = 'Open the Taxpayer Document Types page.';
                    }
                }
                group("Group18")
                {
                    Caption = 'Payroll';
                    action("Payroll Elements1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payroll Elements';
                        RunObject = page "Payroll Element List";
                        Tooltip = 'Open the Payroll Elements page.';
                    }
                    action("Payroll Element Groups")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payroll Element Groups';
                        RunObject = page "Payroll Element Groups";
                        Tooltip = 'Open the Payroll Element Groups page.';
                    }
                    action("Posting Group")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Group';
                        RunObject = page "Payroll Posting Groups";
                        Tooltip = 'Open the Posting Group page.';
                    }
                    action("Payroll Directory")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payroll Directory';
                        RunObject = page "Payroll Directory";
                        Tooltip = 'Open the Payroll Directory page.';
                    }
                    action("Sick Leave Setup")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sick Leave Setup';
                        RunObject = page "Sick Leave Setup";
                        Tooltip = 'Open the Sick Leave Setup page.';
                    }
                    action("AE Calculation Setup")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'AE Calculation Setup';
                        RunObject = page "AE Calculation Setup";
                        Tooltip = 'Open the AE Calculation Setup page.';
                    }
                    action("Element Inclusion")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Element Inclusion';
                        RunObject = page "Payroll Element Inclusion";
                        Tooltip = 'Open the Element Inclusion page.';
                    }
                    action("Payroll Limits")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payroll Limits';
                        RunObject = page "Payroll Limits";
                        Tooltip = 'Open the Payroll Limits page.';
                    }
                    group("Group19")
                    {
                        Caption = 'Calculation Setup';
                        action("Payroll Calc Types")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Calculation Types';
                            RunObject = page "Payroll Calc Types";
                            Tooltip = 'Open the Calculation Types page.';
                        }
                        action("Payroll Calc Groups")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Calculation Groups';
                            RunObject = page "Payroll Calc Groups";
                            Tooltip = 'Open the Calculation Groups page.';
                        }
                        action("Calculation Functions")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Calculation Functions';
                            RunObject = page "Payroll Calculation Functions";
                            Tooltip = 'Open the Calculation Functions page.';
                        }
                    }
                }
                group("Group20")
                {
                    Caption = 'General';
                    action("General Directory")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'General Directory';
                        RunObject = page "General Directory";
                        Tooltip = 'Open the General Directory page.';
                    }
                    action("KLADR Addresses")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'KLADR Addresses';
                        RunObject = page "KLADR Addresses";
                        Tooltip = 'Open the KLADR Addresses page.';
                    }
                    action("OKIN Codes")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'OKIN Codes';
                        RunObject = page "OKIN Codes";
                        Tooltip = 'Open the OKIN Codes page.';
                    }
                }
            }
        }
    }
}