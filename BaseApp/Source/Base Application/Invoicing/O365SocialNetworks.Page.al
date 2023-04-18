#if not CLEAN21
page 2162 "O365 Social Networks"
{
    Caption = 'Company Social Networks';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "O365 Social Network";
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Name; Rec.Name)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the name.';
                }
                field(URL; URL)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                }
            }
        }
    }

    actions
    {
    }
}
#endif
