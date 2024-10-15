#if not CLEAN20
page 9844 "Plan Permission Set"
{
    Caption = 'Plan Permission Set';
    Editable = false;
    PageType = ListPart;
    SourceTable = "Plan Permission Set";
    ObsoleteState = Pending;
    ObsoleteTag = '20.0';
    ObsoleteReason = 'No longer used.';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Plan Name"; Rec."Plan Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Plan';
                    ToolTip = 'Specifies the name of the subscription plan.';
                }
                field("Permission Set ID"; Rec."Permission Set ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Permission Set';
                    ToolTip = 'Specifies the ID of the permission set.';
                }
            }
        }
    }

    actions
    {
    }
}
#endif