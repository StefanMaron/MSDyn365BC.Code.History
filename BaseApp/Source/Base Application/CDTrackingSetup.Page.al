page 14957 "CD Tracking Setup"
{
    Caption = 'CD Tracking Setup';
    PageType = List;
    SourceTable = "CD Tracking Setup";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Item Tracking Code"; "Item Tracking Code")
                {
                    ToolTip = 'Specifies how serial or lot numbers assigned to the item are tracked in the supply chain.';
                    Visible = false;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the warehouse or other place where the involved items are handled or stored.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field("CD Info. Must Exist"; "CD Info. Must Exist")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that information about customs declarations must exist.';
                }
                field("CD Sales Check on Release"; "CD Sales Check on Release")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that a sales document cannot be released if the customs declaration is missing.';
                }
                field("CD Purchase Check on Release"; "CD Purchase Check on Release")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that a purchase document cannot be released if the customs declaration is missing.';
                }
                field("Allow Temporary CD No."; "Allow Temporary CD No.")
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

