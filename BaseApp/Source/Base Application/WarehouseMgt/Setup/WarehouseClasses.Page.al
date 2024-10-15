namespace Microsoft.Warehouse.Setup;

page 7308 "Warehouse Classes"
{
    ApplicationArea = Warehouse;
    Caption = 'Warehouse Classes';
    PageType = List;
    SourceTable = "Warehouse Class";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the warehouse class.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the description of the warehouse class.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }
}

