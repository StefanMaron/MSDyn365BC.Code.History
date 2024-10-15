#if not CLEAN19
page 31031 "Purchase Adv. Paym. Selection"
{
    Caption = 'Purchase Adv. Paym. Selection (Obsolete)';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Purchase Adv. Payment Template";
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
    ObsoleteTag = '19.0';

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
#endif
