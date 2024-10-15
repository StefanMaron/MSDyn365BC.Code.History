#if not CLEAN19
page 31011 "Sales Advanced Paym. Selection"
{
    Caption = 'Sales Advanced Paym. Selection (Obsolete)';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Sales Adv. Payment Template";
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
                    ToolTip = 'Specifies the sales advanced payment templates.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies description for sales advance.';
                }
            }
        }
    }

    actions
    {
    }
}
#endif
