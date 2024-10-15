#if not CLEAN22
namespace System.Security.AccessControl;

page 9836 "User Group Memberships FactBox"
{
    Caption = 'User Group Memberships';
    Editable = false;
    PageType = ListPart;
    SourceTable = "User Group Member";
    ObsoleteState = Pending;
    ObsoleteReason = '[220_UserGroups] Replaced by the User Security Groups Part page in the security groups system; by Permission Sets FactBox page in the permission sets system. To learn more, go to https://go.microsoft.com/fwlink/?linkid=2245709.';
    ObsoleteTag = '22.0';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("User Group Code"; Rec."User Group Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a user group.';
                }
                field("User Group Name"; Rec."User Group Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the user group.';
                    Visible = false;
                }
                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the company.';
                }
            }
        }
    }

    actions
    {
    }
}

#endif