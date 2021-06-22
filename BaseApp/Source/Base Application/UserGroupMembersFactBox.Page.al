page 9832 "User Group Members FactBox"
{
    Caption = 'Members';
    Editable = false;
    PageType = ListPart;
    SourceTable = "User Group Member";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("User Name"; "User Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the user.';
                }
                field("User Full Name"; "User Full Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Full Name';
                    ToolTip = 'Specifies the full name of the user.';
                    Visible = false;
                }
                field("Company Name"; "Company Name")
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

