page 10706 "Statistical Codes"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Statistical Codes';
    PageType = List;
    SourceTable = "Statistical Code";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1100001)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the statistical code for the payment.';
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of the statistical code.';
                }
            }
        }
    }

    actions
    {
    }
}

