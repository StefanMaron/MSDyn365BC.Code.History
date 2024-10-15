#if not CLEAN22
namespace System.Security.AccessControl;

page 9828 "User Group Plan FactBox"
{
    Caption = 'User Groups in Plan';
    Editable = false;
    PageType = ListPart;
    SourceTable = "User Group Plan";
    ObsoleteState = Pending;
    ObsoleteReason = '[220_UserGroups] The user groups functionality is deprecated. Default permission sets per plan are defined using the Plan Configuration codeunit. To learn more, go to https://go.microsoft.com/fwlink/?linkid=2245709.';
    ObsoleteTag = '22.0';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Plan Name"; Rec."Plan Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the subscription plan.';
                }
                field("User Group Code"; Rec."User Group Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a user group.';
                }
                field("User Group Name"; Rec."User Group Name")
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

#endif