#if not CLEAN22
namespace System.Security.AccessControl;

page 9829 "User Groups FactBox"
{
    Caption = 'User Groups';
    PageType = ListPart;
    SourceTable = "User Group";
    ObsoleteState = Pending;
    ObsoleteReason = '[220_UserGroups] The user groups functionality is deprecated. Use the Security Groups page or Permission Sets page directly instead. To learn more, go to https://go.microsoft.com/fwlink/?linkid=2245709.';
    ObsoleteTag = '22.0';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'specifies a code for the user group.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the user group.';
                }
                field("Default Profile ID"; Rec."Default Profile ID")
                {
                    ApplicationArea = All;
                    Caption = 'Default Profile';
                    ToolTip = 'Specifies the profile that is assigned to the user group by default.';
                }
            }
        }
    }

    actions
    {
    }
}

#endif