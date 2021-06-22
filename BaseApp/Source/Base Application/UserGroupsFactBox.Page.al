page 9829 "User Groups FactBox"
{
    Caption = 'User Groups';
    PageType = ListPart;
    SourceTable = "User Group";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'specifies a code for the user group.';
                }
                field(Name; Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the user group.';
                }
                field("Default Profile ID"; "Default Profile ID")
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

