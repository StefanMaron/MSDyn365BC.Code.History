page 17365 "HR Field Groups"
{
    ApplicationArea = Basic, Suite;
    Caption = 'HR Field Groups';
    CardPageID = "HR Field Group";
    Editable = false;
    PageType = List;
    SourceTable = "HR Field Group";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field("Print Order"; "Print Order")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("No. of Fields"; "No. of Fields")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
    }
}

