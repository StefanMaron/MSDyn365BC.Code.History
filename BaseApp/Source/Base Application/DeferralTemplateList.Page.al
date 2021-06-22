page 1701 "Deferral Template List"
{
    ApplicationArea = Suite;
    Caption = 'Deferral Templates';
    CardPageID = "Deferral Template Card";
    Editable = false;
    PageType = List;
    SourceTable = "Deferral Template";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control6)
            {
                ShowCaption = false;
                field("Deferral Code"; "Deferral Code")
                {
                    ApplicationArea = Suite;
                    Caption = 'Deferral Code';
                    ToolTip = 'Specifies the code for the deferral template.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a description of the record.';
                }
                field("Deferral Account"; "Deferral Account")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the G/L account that the deferred expenses are posted to.';
                }
                field("Deferral %"; "Deferral %")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how much of the total amount will be deferred.';
                }
                field("Calc. Method"; "Calc. Method")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how the Amount field for each period is calculated. Straight-Line: Calculated per the number of periods, distributed by period length. Equal Per Period: Calculated per the number of periods, distributed evenly on periods. Days Per Period: Calculated per the number of days in the period. User-Defined: Not calculated. You must manually fill the Amount field for each period.';
                }
                field("Start Date"; "Start Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies when to start calculating deferral amounts.';
                }
                field("No. of Periods"; "No. of Periods")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how many accounting periods the total amounts will be deferred to.';
                }
                field("Period Description"; "Period Description")
                {
                    ApplicationArea = Suite;
                    Caption = 'Period Desc.';
                    ToolTip = 'Specifies a description that will be shown on entries for the deferral posting.';
                }
            }
        }
    }

    actions
    {
    }
}

