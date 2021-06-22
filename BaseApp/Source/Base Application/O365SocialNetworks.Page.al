page 2162 "O365 Social Networks"
{
    Caption = 'Company Social Networks';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "O365 Social Network";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Editable = false;
                    ToolTip = 'Specifies the name.';
                }
                field(URL; URL)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                }
            }
        }
    }

    actions
    {
    }
}

