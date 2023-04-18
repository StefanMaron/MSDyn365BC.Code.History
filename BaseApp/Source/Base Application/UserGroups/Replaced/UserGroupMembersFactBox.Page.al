#if not CLEAN22
page 9832 "User Group Members FactBox"
{
    Caption = 'Members';
    Editable = false;
    PageType = ListPart;
    SourceTable = "User Group Member";
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by the Security Group Members Part page in the security groups system.';
    ObsoleteTag = '22.0';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("User Name"; Rec."User Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the user.';
                }
                field("User Full Name"; Rec."User Full Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Full Name';
                    ToolTip = 'Specifies the full name of the user.';
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