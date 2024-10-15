page 31031 "Purchase Adv. Paym. Selection"
{
    Caption = 'Purchase Adv. Paym. Selection';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Purchase Adv. Payment Template";

    layout
    {
        area(content)
        {
            repeater(Control1220002)
            {
                Editable = false;
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the purchase advanced payment templates.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies description for purchase advance.';
                }
            }
        }
    }

    actions
    {
    }
}

