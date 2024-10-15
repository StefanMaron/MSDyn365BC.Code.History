page 12492 "Job Titles"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Positions';
    CardPageID = "Job Title Card";
    Editable = false;
    PageType = List;
    SourceTable = "Job Title";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code associated with the job title.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with the job title.';
                }
                field("Code OKPDTR"; "Code OKPDTR")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Base Salary Amount"; "Base Salary Amount")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Base Salary Element Code"; "Base Salary Element Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Category Code"; "Category Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the category.';
                }
                field("Calendar Code"; "Calendar Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the related work calendar. ';
                }
                field("Worktime Norm"; "Worktime Norm")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Kind of Work"; "Kind of Work")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Conditions of Work"; "Conditions of Work")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Calc Group Code"; "Calc Group Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Posting Group"; "Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Statistics Group Code"; "Statistics Group Code")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Jo&b Title")
            {
                Caption = 'Jo&b Title';
                separator(Action1210035)
                {
                }
                action("Default Contract Terms")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Default Contract Terms';
                    Image = EmployeeAgreement;
                    RunObject = Page "Default Labor Contract Terms";
                    RunPageLink = "Job Title Code" = FIELD(Code);
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        CurrPage.Editable := not CurrPage.LookupMode;
    end;
}

