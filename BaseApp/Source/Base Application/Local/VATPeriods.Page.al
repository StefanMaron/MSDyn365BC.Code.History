page 10604 "VAT Periods"
{
    ApplicationArea = Basic, Suite;
    Caption = 'VAT Periods';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "VAT Period";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1080000)
            {
                ShowCaption = false;
                field("Period No."; Rec."Period No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the period number for a VAT period.';
                }
                field("Start Day"; Rec."Start Day")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the start day for the current VAT period.';
                }
                field("Start Month"; Rec."Start Month")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the start month for the current VAT period.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the current VAT period.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&VAT Period")
            {
                Caption = '&VAT Period';
                action("Create VAT Periods")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create VAT Periods';
                    Ellipsis = true;
                    Image = Period;
                    ToolTip = 'Use a function to create VAT periods.';

                    trigger OnAction()
                    begin
                        VATTools.CreateStdVATPeriods(true);
                        CurrPage.Update();
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        CheckPeriods();
    end;

    var
        VATTools: Codeunit "Norwegian VAT Tools";
}

