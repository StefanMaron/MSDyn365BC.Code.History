page 9835 "User Group Permissions FactBox"
{
    Caption = 'Permission Sets';
    Editable = false;
    PageType = ListPart;
    SourceTable = "User Group Permission Set";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Role ID"; Rec."Role ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of a permission set.';
                }
                field("Role Name"; Rec."Role Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the permission set.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }
}

