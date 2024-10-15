page 17378 "Job Title Card"
{
    Caption = 'Job Title Card';
    PageType = Card;
    SourceTable = "Job Title";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
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
                field("Alternative Name"; "Alternative Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the record.';
                }
                field("Category Type"; "Category Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Level; Level)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Blocked; Blocked)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
            }
            group(Administration)
            {
                Caption = 'Administration';
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
                field("Kind of Work"; "Kind of Work")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Conditions of Work"; "Conditions of Work")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
            group(Payroll)
            {
                Caption = 'Payroll';
                field("Base Salary Element Code"; "Base Salary Element Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Base Salary Amount"; "Base Salary Amount")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Job Title")
            {
                Caption = '&Job Title';
                action("Default Contract Terms")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Default Contract Terms';
                    Image = Default;
                    RunObject = Page "Default Labor Contract Terms";
                    RunPageLink = "Job Title Code" = FIELD(Code);
                }
            }
        }
    }
}

