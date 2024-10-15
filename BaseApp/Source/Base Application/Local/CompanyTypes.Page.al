page 12169 "Company Types"
{
    Caption = 'Company Types';
    PageType = List;
    SourceTable = "Company Types";

    layout
    {
        area(content)
        {
            repeater(Control1130000)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code that defines the company type.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the company type.';
                }
            }
        }
    }

    actions
    {
    }
}

