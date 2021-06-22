page 9804 "Permissions FactBox"
{
    Caption = 'Permissions';
    Editable = false;
    PageType = ListPart;
    SourceTable = Permission;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Object Type"; "Object Type")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the type of the object that the permissions apply to.';
                }
                field("Object ID"; "Object ID")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the ID of the object to which the permissions apply to.';
                }
                field("Object Name"; "Object Name")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the object to which the permissions apply to.';
                }
            }
        }
    }

    actions
    {
    }
}

