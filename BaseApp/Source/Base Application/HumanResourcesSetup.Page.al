page 5233 "Human Resources Setup"
{
    AdditionalSearchTerms = 'personnel people employee staff hr setup';
    ApplicationArea = BasicHR;
    Caption = 'Human Resources Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    PromotedActionCategories = 'New,Process,Report,Employee,Documents';
    SourceTable = "Human Resources Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Base Unit of Measure"; "Base Unit of Measure")
                {
                    ToolTip = 'Specifies the base unit of measure, such as hour or day.';
                }
                field("Official Calendar Code"; "Official Calendar Code")
                {
                }
                field("Default Calendar Code"; "Default Calendar Code")
                {
                }
                field("Tax Allowance Code for Child"; "Tax Allowance Code for Child")
                {
                }
                field("Tax Allowance Code for Taxpay"; "Tax Allowance Code for Taxpay")
                {
                }
                field("Person Vendor Posting Group"; "Person Vendor Posting Group")
                {
                }
                field("Pers. Vend.Gen.Bus. Posting Gr"; "Pers. Vend.Gen.Bus. Posting Gr")
                {
                }
                field("Pers. Vend.VAT Bus. Posting Gr"; "Pers. Vend.VAT Bus. Posting Gr")
                {
                }
                field("Amt. to Pay Rounding Precision"; "Amt. to Pay Rounding Precision")
                {
                }
                field("Amt. to Pay Rounding Type"; "Amt. to Pay Rounding Type")
                {
                }
                field("Use Staff List Change Orders"; "Use Staff List Change Orders")
                {
                }
                field("Local Country/Region Code"; "Local Country/Region Code")
                {
                    ToolTip = 'Specifies the local country/region code.';
                }
                field("Element Code Salary Days"; "Element Code Salary Days")
                {
                }
                field("Element Code Salary Hours"; "Element Code Salary Hours")
                {
                }
                field("Element Code Salary Amount"; "Element Code Salary Amount")
                {
                }
                field("Income Tax 13%"; "Income Tax 13%")
                {
                }
                field("Income Tax 30%"; "Income Tax 30%")
                {
                }
                field("Income Tax 35%"; "Income Tax 35%")
                {
                }
                field("Income Tax 9%"; "Income Tax 9%")
                {
                }
                field("Employee Address Type"; "Employee Address Type")
                {
                    ToolTip = 'Specifies the address type, such as Permanent.';
                }
                field("AE Calculation Function Code"; "AE Calculation Function Code")
                {
                    ToolTip = 'Specifies the function that is used in the average-earnings calculation. ';
                }
            }
            group(Numbering)
            {
                Caption = 'Numbering';
                field("Employee Nos."; "Employee Nos.")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the number series code to use when assigning numbers to employees.';
                }
                field("Position Nos."; "Position Nos.")
                {
                    ToolTip = 'Specifies the number series from which numbers are assigned to new records.';
                }
                field("Budgeted Position Nos."; "Budgeted Position Nos.")
                {
                    ToolTip = 'Specifies the number series from which numbers are assigned to new records.';
                }
                field("Person Nos."; "Person Nos.")
                {
                    ToolTip = 'Specifies the number series from which numbers are assigned to new records.';
                }
                field("Labor Contract Nos."; "Labor Contract Nos.")
                {
                    ToolTip = 'Specifies the number series from which numbers are assigned to new records.';
                }
                field("Person Vendor No. Series"; "Person Vendor No. Series")
                {
                }
                field("Staff List Change Nos."; "Staff List Change Nos.")
                {
                    ToolTip = 'Specifies the number series from which numbers are assigned to new records.';
                }
                field("HR Order Nos."; "HR Order Nos.")
                {
                    ToolTip = 'Specifies the number series from which numbers are assigned to new records.';
                }
                field("Calculation Sheet Nos."; "Calculation Sheet Nos.")
                {
                    ToolTip = 'Specifies the number series from which numbers are assigned to new records.';
                }
                field("Personal Information Nos."; "Personal Information Nos.")
                {
                    ToolTip = 'Specifies the number series from which numbers are assigned to new records.';
                }
                field("Person Income Document Nos."; "Person Income Document Nos.")
                {
                    ToolTip = 'Specifies the number series from which numbers are assigned to new records.';
                }
                field("Sick Leave Order Nos."; "Sick Leave Order Nos.")
                {
                    ToolTip = 'Specifies the number series from which numbers are assigned to new records.';
                }
                field("Vacation Request Nos."; "Vacation Request Nos.")
                {
                }
                field("Vacation Order Nos."; "Vacation Order Nos.")
                {
                    ToolTip = 'Specifies the number series from which numbers are assigned to new records.';
                }
                field("Vacation Schedule Nos."; "Vacation Schedule Nos.")
                {
                }
                field("Travel Order Nos."; "Travel Order Nos.")
                {
                    ToolTip = 'Specifies the number series from which numbers are assigned to new records.';
                }
                field("Other Absence Order Nos."; "Other Absence Order Nos.")
                {
                    ToolTip = 'Specifies the number series from which numbers are assigned to new records.';
                }
                field("Group Hire Order Nos."; "Group Hire Order Nos.")
                {
                }
                field("Group Transfer Order Nos."; "Group Transfer Order Nos.")
                {
                }
                field("Group Dismissal Order Nos."; "Group Dismissal Order Nos.")
                {
                    ToolTip = 'Specifies the number series from which numbers are assigned to new records.';
                }
                field("Payroll Document Nos."; "Payroll Document Nos.")
                {
                    ToolTip = 'Specifies the number series from which numbers are assigned to new records.';
                }
                field("Posted Payroll Document Nos."; "Posted Payroll Document Nos.")
                {
                    ToolTip = 'Specifies the number series from which numbers are assigned to new records.';
                }
            }
            group("T-Forms")
            {
                Caption = 'T-Forms';
                field("T-1 Template Code"; "T-1 Template Code")
                {
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("T-1a Template Code"; "T-1a Template Code")
                {
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("T-5 Template Code"; "T-5 Template Code")
                {
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("T-5a Template Code"; "T-5a Template Code")
                {
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("T-6 Template Code"; "T-6 Template Code")
                {
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("T-6a Template Code"; "T-6a Template Code")
                {
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("T-8 Template Code"; "T-8 Template Code")
                {
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("T-8a Template Code"; "T-8a Template Code")
                {
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("T-9 Template Code"; "T-9 Template Code")
                {
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("T-9a Template Code"; "T-9a Template Code")
                {
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("T-10 Template Code"; "T-10 Template Code")
                {
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("T-10a Template Code"; "T-10a Template Code")
                {
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("T-11 Template Code"; "T-11 Template Code")
                {
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("T-11a Template Code"; "T-11a Template Code")
                {
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("T-2 Template Code"; "T-2 Template Code")
                {
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("T-3 Template Code"; "T-3 Template Code")
                {
                }
                field("T-3a Template Code"; "T-3a Template Code")
                {
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("T-7 Template Code"; "T-7 Template Code")
                {
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("T-12 Template Code"; "T-12 Template Code")
                {
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("T-13 Template Code"; "T-13 Template Code")
                {
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("T-51 Template Code"; "T-51 Template Code")
                {
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("T-53 Template Code"; "T-53 Template Code")
                {
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("T-54 Template Code"; "T-54 Template Code")
                {
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("T-54a Template Code"; "T-54a Template Code")
                {
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("T-60 Template Code"; "T-60 Template Code")
                {
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("T-61 Template Code"; "T-61 Template Code")
                {
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("T-73 Template Code"; "T-73 Template Code")
                {
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
            }
            group("Other Forms")
            {
                Caption = 'Other Forms';
                field("NDFL-1 Template Code"; "NDFL-1 Template Code")
                {
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("NDFL-2 Template Code"; "NDFL-2 Template Code")
                {
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("NDFL Register Template Code"; "NDFL Register Template Code")
                {
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("Form 4-FSI Template Code"; "Form 4-FSI Template Code")
                {
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("Report 1-T Template Code"; "Report 1-T Template Code")
                {
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("P-4 Template Code"; "P-4 Template Code")
                {
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("Avg. Headcount Template Code"; "Avg. Headcount Template Code")
                {
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("FSN-1 Template Code"; "FSN-1 Template Code")
                {
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("ADV-1 Template Code"; "ADV-1 Template Code")
                {
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("SPV-1 Template Code"; "SPV-1 Template Code")
                {
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("SZV-6-1 Template Code"; "SZV-6-1 Template Code")
                {
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("SZV-6-2 Template Code"; "SZV-6-2 Template Code")
                {
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("SZV-6-3 Template Code"; "SZV-6-3 Template Code")
                {
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("SZV-6-4 Template Code"; "SZV-6-4 Template Code")
                {
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("RSV Template Code"; "RSV Template Code")
                {
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("PF Report Template Code"; "PF Report Template Code")
                {
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("PF Pers. Card Template Code"; "PF Pers. Card Template Code")
                {
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("PF Summ. Card Template Code"; "PF Summ. Card Template Code")
                {
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("Sick Leave Abs. Template Code"; "Sick Leave Abs. Template Code")
                {
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("Salary Reference Template Code"; "Salary Reference Template Code")
                {
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("Employee Paysheet Templ. Code"; "Employee Paysheet Templ. Code")
                {
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
            }
            group("Time Activities")
            {
                Caption = 'Time Activities';
                field("Work Time Group Code"; "Work Time Group Code")
                {
                }
                field("Tariff Work Group Code"; "Tariff Work Group Code")
                {
                }
                field("Task Work Group Code"; "Task Work Group Code")
                {
                }
                field("Night Work Group Code"; "Night Work Group Code")
                {
                }
                field("Overtime 1.5 Group Code"; "Overtime 1.5 Group Code")
                {
                }
                field("Overtime 2.0 Group Code"; "Overtime 2.0 Group Code")
                {
                }
                field("Weekend Work Group"; "Weekend Work Group")
                {
                }
                field("Holiday Work Group"; "Holiday Work Group")
                {
                }
                field("Average Headcount Group Code"; "Average Headcount Group Code")
                {
                }
                field("Absence Group Code"; "Absence Group Code")
                {
                    ToolTip = 'Specifies the absence group.';
                }
                field("Change Vacation Accr. By Doc"; "Change Vacation Accr. By Doc")
                {
                }
                field("Change Vacation Accr. Periodic"; "Change Vacation Accr. Periodic")
                {
                }
                field("Annual Vacation Group Code"; "Annual Vacation Group Code")
                {
                }
                field("P-4 Work Time Group Code"; "P-4 Work Time Group Code")
                {
                }
                field("FSN-1 Work Time Group Code"; "FSN-1 Work Time Group Code")
                {
                }
                field("Default Timesheet Code"; "Default Timesheet Code")
                {
                }
                field("Default Night Hours Code"; "Default Night Hours Code")
                {
                }
                field("T-13 Weekend Work Group code"; "T-13 Weekend Work Group code")
                {
                }
                field("Excl. Days Group Code"; "Excl. Days Group Code")
                {
                }
            }
            group(Reporting)
            {
                Caption = 'Reporting';
                field("Wages Element Code"; "Wages Element Code")
                {
                }
                field("Bonus Element Code"; "Bonus Element Code")
                {
                }
                field("Deductions Element Code"; "Deductions Element Code")
                {
                }
                field("Tax Deductions Element Code"; "Tax Deductions Element Code")
                {
                }
                field("Income Tax Element Code"; "Income Tax Element Code")
                {
                }
                field("P-4 Salary Element Code"; "P-4 Salary Element Code")
                {
                }
                field("P-4 Benefits Element Code"; "P-4 Benefits Element Code")
                {
                }
                field("TAX PF INS Element Code"; "TAX PF INS Element Code")
                {
                }
                field("TAX PF SAV Element Code"; "TAX PF SAV Element Code")
                {
                }
                field("FSN-1 Salary Element Code"; "FSN-1 Salary Element Code")
                {
                }
                field("FSN-1 Bonus Element Code"; "FSN-1 Bonus Element Code")
                {
                }
                field("PF Accum. Part Element Code"; "PF Accum. Part Element Code")
                {
                }
                field("PF Insur. Part Element Code"; "PF Insur. Part Element Code")
                {
                }
                field("Territorial FMI Element Code"; "Territorial FMI Element Code")
                {
                }
                field("Federal FMI Element Code"; "Federal FMI Element Code")
                {
                }
                field("FSI Element Code"; "FSI Element Code")
                {
                }
                field("FSI Injury Element Code"; "FSI Injury Element Code")
                {
                }
                field("PF BASE Element Code"; "PF BASE Element Code")
                {
                }
                field("PF OVER Limit Element Code"; "PF OVER Limit Element Code")
                {
                }
                field("PF INS Limit Element Code"; "PF INS Limit Element Code")
                {
                }
                field("PF SPECIAL 1 Element Code"; "PF SPECIAL 1 Element Code")
                {
                }
                field("PF SPECIAL 2 Element Code"; "PF SPECIAL 2 Element Code")
                {
                }
                field("PF MI NO TAX Element Code"; "PF MI NO TAX Element Code")
                {
                }
                field("TAX FED FMI Element Code"; "TAX FED FMI Element Code")
                {
                }
                field("Automatically Create Resource"; "Automatically Create Resource")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies if a resource card is automatically created for an employee that is added to a job, service, or assembly activity.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action("Human Res. Units of Measure")
            {
                ApplicationArea = BasicHR;
                Caption = 'Human Res. Units of Measure';
                Image = UnitOfMeasure;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                RunObject = Page "Human Res. Units of Measure";
                ToolTip = 'Set up the units of measure, such as DAY or HOUR, that you can select from in the Human Resources Setup window to define how employment time is recorded.';
            }
            action("Causes of Absence")
            {
                ApplicationArea = BasicHR;
                Caption = 'Causes of Absence';
                Image = AbsenceCategory;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                RunObject = Page "Time Activity Codes";
                ToolTip = 'Set up reasons why an employee can be absent.';
            }
            action("Causes of Inactivity")
            {
                ApplicationArea = BasicHR;
                Caption = 'Causes of Inactivity';
                Image = InactivityDescription;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                RunObject = Page "Causes of Inactivity";
                ToolTip = 'Set up reasons why an employee can be inactive.';
            }
            action("Grounds for Termination")
            {
                ApplicationArea = BasicHR;
                Caption = 'Grounds for Termination';
                Image = TerminationDescription;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                RunObject = Page "Grounds for Termination";
                ToolTip = 'Set up reasons why an employment can be terminated.';
            }
            action(Unions)
            {
                ApplicationArea = BasicHR;
                Caption = 'Unions';
                Image = Union;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                RunObject = Page Unions;
                ToolTip = 'Set up different worker unions that employees may be members of, so that you can select it on the employee card.';
            }
            action("Employment Contracts")
            {
                ApplicationArea = BasicHR;
                Caption = 'Employment Contracts';
                Image = EmployeeAgreement;
                Promoted = true;
                PromotedCategory = Category5;
                PromotedIsBig = true;
                RunObject = Page "Employment Contracts";
                ToolTip = 'Set up the different types of contracts that employees can be employed under, such as Administration or Production.';
            }
            action(Relatives)
            {
                ApplicationArea = BasicHR;
                Caption = 'Relatives';
                Image = Relatives;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                RunObject = Page Relatives;
                ToolTip = 'Set up the types of relatives that you can select from on employee cards.';
            }
            action("Misc. Articles")
            {
                ApplicationArea = BasicHR;
                Caption = 'Misc. Articles';
                Image = Archive;
                Promoted = true;
                PromotedCategory = Category5;
                PromotedIsBig = true;
                RunObject = Page "Misc. Articles";
                ToolTip = 'Set up types of company assets that employees use, such as CAR or COMPUTER, that you can select from on employee cards.';
            }
            action(Confidential)
            {
                ApplicationArea = BasicHR;
                Caption = 'Confidential';
                Image = ConfidentialOverview;
                Promoted = true;
                PromotedCategory = Category5;
                PromotedIsBig = true;
                RunObject = Page Confidential;
                ToolTip = 'Set up types of confidential information, such as SALARY or INSURANCE, that you can select from on employee cards.';
            }
            action(Qualifications)
            {
                ApplicationArea = BasicHR;
                Caption = 'Qualifications';
                Image = QualificationOverview;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                RunObject = Page Qualifications;
                ToolTip = 'Set up types of qualifications, such as DESIGN or ACCOUNTANT, that you can select from on employee cards.';
            }
            action("Employee Statistics Groups")
            {
                ApplicationArea = BasicHR;
                Caption = 'Employee Statistics Groups';
                Image = StatisticsGroup;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                RunObject = Page "Employee Statistics Groups";
                ToolTip = 'Set up salary types, such as HOURLY or MONTHLY, that you use for statistical purposes.';
            }
        }
    }

    trigger OnOpenPage()
    begin
        Reset;
        if not Get then begin
            Init;
            Insert;
        end;
    end;
}

