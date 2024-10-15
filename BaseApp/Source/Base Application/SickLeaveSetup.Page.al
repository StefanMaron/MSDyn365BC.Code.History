page 17477 "Sick Leave Setup"
{
    ApplicationArea = Basic, Suite;
    AutoSplitKey = true;
    Caption = 'Sick Leave Setup';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Sick Leave Setup";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the record.';
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first day of the activity in question. ';
                }
                field("Sick Leave Type"; "Sick Leave Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Insured Service (Years)"; "Insured Service (Years)")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Payment %"; "Payment %")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Payment Benefit Liable"; "Payment Benefit Liable")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Minimal Wage Amount"; "Minimal Wage Amount")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Maximal Average Earning"; "Maximal Average Earning")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Age; Age)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Treatment Type"; "Treatment Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Max. Days per Year"; "Max. Days per Year")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Max. Days per Document"; "Max. Days per Document")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Max. Paid Days by FSI"; "Max. Paid Days by FSI")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Other Days Payment %"; "Other Days Payment %")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Max. Days per Month"; "Max. Days per Month")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("First Payment Days"; "First Payment Days")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Days after Dismissal"; "Days after Dismissal")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Dismissed; Dismissed)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Disabled Person"; "Disabled Person")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Element Code"; "Element Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the related payroll element for tax registration purposes.';
                }
                field("Payment Source"; "Payment Source")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Posting Group"; "Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
    }
}

