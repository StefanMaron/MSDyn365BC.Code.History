#if not CLEAN22
page 9836 "User Group Memberships FactBox"
{
    Caption = 'User Group Memberships';
    Editable = false;
    PageType = ListPart;
    SourceTable = "User Group Member";
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by the User Security Groups Part page in the security groups system.';
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