page 9828 "User Group Plan FactBox"
{
    Caption = 'User Groups in Plan';
    Editable = false;
    PageType = ListPart;
    SourceTable = "User Group Plan";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Plan Name"; "Plan Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the subscription plan.';
                }
                field("User Group Code"; "User Group Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a user group.';
                }
                field("User Group Name"; "User Group Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the user group.';
                }
            }
        }
    }

    actions
    {
    }
}

