#if not CLEAN22
page 9840 "Tenant Permissions FactBox"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced with Expanded Permissions Factbox in System Application';
    ObsoleteTag = '22.0';
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
                field("Object Type"; Rec."Object Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the object.';
                }
                field("Object ID"; Rec."Object ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the object.';
                }
                field("Object Name"; Rec."Object Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the object.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Include/Exclude';
                    ToolTip = 'Specifies whether the permission is effective for this permission set. If you create a hierarchy of permission sets, the setting for the permission in the highest set in the hierarchy is used.';
                }
            }
        }
    }

    actions
    {
    }
}
#endif