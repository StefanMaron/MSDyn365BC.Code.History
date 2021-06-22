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
            group(Numbering)
            {
                Caption = 'Numbering';
                field("Employee Nos."; "Employee Nos.")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the number series code to use when assigning numbers to employees.';
                }
                field("Base Unit of Measure"; "Base Unit of Measure")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the base unit of measure, such as hour or day.';
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
                RunObject = Page "Causes of Absence";
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

