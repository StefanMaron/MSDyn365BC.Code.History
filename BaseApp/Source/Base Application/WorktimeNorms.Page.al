page 17427 "Worktime Norms"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Worktime Norms';
    PageType = List;
    SourceTable = "Worktime Norm";
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
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field("Hours per Week"; "Hours per Week")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Hours per Year"; "Hours per Year")
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

