page 28003 Counties
{
    Caption = 'Counties';
    PageType = List;
    SourceTable = County;

    layout
    {
        area(content)
        {
            repeater(Control1500003)
            {
                ShowCaption = false;
                field(Name; Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the county.';
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description.';
                }
            }
        }
    }

    actions
    {
    }
}

