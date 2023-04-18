page 1177 "User Task Groups"
{
    ApplicationArea = Basic, Suite;
    Caption = 'User Task Groups';
    CardPageID = "User Task Group";
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "User Task Group";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the unique ID for the group.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the group.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action(UserTaskGroupMembers)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'User Task Group Members';
                Image = Users;
                RunObject = Page "User Task Group Members";
                RunPageLink = "User Task Group Code" = FIELD(Code);
                Scope = Repeater;
                ToolTip = 'View or edit the members of the user task group.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(UserTaskGroupMembers_Promoted; UserTaskGroupMembers)
                {
                }
            }
        }
    }
}

