page 26551 "Statutory Report Groups"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Statutory Report Groups';
    PageType = List;
    SourceTable = "Statutory Report Group";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the statutory report group code.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the statutory report group description.';
                }
            }
        }
    }

    actions
    {
    }
}

