page 9840 "Tenant Permissions FactBox"
{
    Caption = 'Tenant Permissions';
    Editable = false;
    PageType = ListPart;
    SourceTable = "Tenant Permission";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Object Type"; "Object Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the object.';
                }
                field("Object ID"; "Object ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the object.';
                }
                field("Object Name"; "Object Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the object.';
                }
            }
        }
    }

    actions
    {
    }
}

