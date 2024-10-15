namespace Microsoft.Inventory.Item.Catalog;

page 5729 "Purchasing Code List"
{
    Caption = 'Purchasing Code List';
    Editable = false;
    PageType = List;
    SourceTable = Purchasing;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a code for a purchasing activity.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a description of the purchasing activity specified by the code.';
                }
                field("Drop Shipment"; Rec."Drop Shipment")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies if your vendor ships the items directly to your customer.';
                }
                field("Special Order"; Rec."Special Order")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies that this purchase activity includes arranging for a special order.';
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

