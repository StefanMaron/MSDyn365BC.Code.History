page 12158 "Goods Appearance"
{
    Caption = 'Goods Appearance';
    PageType = List;
    SourceTable = "Goods Appearance";

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
                    ToolTip = 'Specifies a goods appearance that you want the program to attach to the entry.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description for the goods appearance.';
                }
            }
        }
    }

    actions
    {
    }
}

