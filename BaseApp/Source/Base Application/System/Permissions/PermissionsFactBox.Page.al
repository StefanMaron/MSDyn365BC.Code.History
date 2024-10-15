#if not CLEAN22
namespace System.Security.AccessControl;

page 9804 "Permissions FactBox"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced with Expanded Permissions Factbox in System Application';
    ObsoleteTag = '22.0';
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
                field("Object Type"; Rec."Object Type")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the type of the object that the permissions apply to.';
                }
                field("Object ID"; Rec."Object ID")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the ID of the object to which the permissions apply to.';
                }
                field("Object Name"; Rec."Object Name")
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
#endif