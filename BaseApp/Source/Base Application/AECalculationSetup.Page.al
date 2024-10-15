page 17485 "AE Calculation Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'AE Calculation Setup';
    PageType = List;
    SourceTable = "AE Calculation Setup";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the record.';
                }
                field("AE Calc Type"; "AE Calc Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how the average earnings is calculated. ';
                }
                field("Bonus Type"; "Bonus Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Period Code"; "Period Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Setup Code"; "Setup Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("AE Bonus Calc Type"; "AE Bonus Calc Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how average-earnings bonusses are calculated. ';
                }
                field("AE Bonus Calc Method"; "AE Bonus Calc Method")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how average-earnings bonusses are calculated. ';
                }
                field("Time Bonus Calc Method"; "Time Bonus Calc Method")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Month Days Calc Method"; "Month Days Calc Method")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Days for Calc Type"; "Days for Calc Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("AE Calc Months"; "AE Calc Months")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which months the average-earnings calculation covers.';
                }
                field("Average Month Days"; "Average Month Days")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Recalc for Bonus Amount"; "Recalc for Bonus Amount")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Use FSI Limits"; "Use FSI Limits")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Exclude Current Period"; "Exclude Current Period")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Use Excluded Days"; "Use Excluded Days")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        CurrPage.Editable := not CurrPage.LookupMode;
    end;
}

