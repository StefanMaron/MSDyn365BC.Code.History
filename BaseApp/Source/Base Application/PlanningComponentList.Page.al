page 99000861 "Planning Component List"
{
    Caption = 'Planning Component List';
    DataCaptionExpression = Caption;
    Editable = false;
    PageType = List;
    SourceTable = "Planning Component";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the item number of the component.';
                    Visible = false;
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the date when this planning component must be finished.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the description of the component.';
                }
                field("Scrap %"; "Scrap %")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the percentage of the item that you expect to be scrapped in the production process.';
                    Visible = false;
                }
                field("Calculation Formula"; "Calculation Formula")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies how to calculate the Quantity field.';
                }
                field(Length; Length)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the length of one item unit when measured in the specified unit of measure.';
                }
                field(Width; Width)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the width of one item unit when measured in the specified unit of measure.';
                }
                field(Weight; Weight)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the weight of one item unit when measured in the specified unit of measure.';
                }
                field(Depth; Depth)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the depth of one item unit when measured in the specified unit of measure.';
                }
                field("Quantity per"; "Quantity per")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies how many units of the component are required to produce the parent item.';
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                    Visible = false;
                }
                field("Expected Quantity"; "Expected Quantity")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the expected quantity of this planning component line.';
                }
                field("Expected Quantity (Base)"; "Expected Quantity (Base)")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the contents of the Expected Quantity field on the line, in base units of measure.';
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the code for the inventory location, where the item on the planning component line will be registered.';
                    Visible = false;
                }
                field("Routing Link Code"; "Routing Link Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies a routing link code to link a planning component with a specific operation.';
                }
                field("Unit Cost"; "Unit Cost")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the cost of one unit of the item or resource on the line.';
                    Visible = false;
                }
                field("Cost Amount"; "Cost Amount")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the total cost for this planning component line.';
                    Visible = false;
                }
                field(Position; Position)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the position of the component on the bill of material.';
                    Visible = false;
                }
                field("Position 2"; "Position 2")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the second reference number for the component position, such as the alternate position number of a component on a circuit board.';
                    Visible = false;
                }
                field("Position 3"; "Position 3")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the third reference number for the component position on a bill of material, such as the alternate position number of a component on a print card.';
                    Visible = false;
                }
                field("Lead-Time Offset"; "Lead-Time Offset")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the lead-time offset for the planning component.';
                    Visible = false;
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
        area(navigation)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action("Item &Tracking Lines")
                {
                    ApplicationArea = Planning;
                    Caption = 'Item &Tracking Lines';
                    Image = ItemTrackingLines;
                    ShortCutKey = 'Shift+Ctrl+I';
                    ToolTip = 'View or edit serial numbers and lot numbers that are assigned to the item on the document or journal line.';

                    trigger OnAction()
                    begin
                        OpenItemTrackingLines;
                    end;
                }
            }
        }
    }
}

