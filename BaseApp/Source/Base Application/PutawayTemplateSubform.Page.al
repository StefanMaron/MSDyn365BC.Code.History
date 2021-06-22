page 7313 "Put-away Template Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Put-away Template Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Find Fixed Bin"; "Find Fixed Bin")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies that a bin must be used in the put-away process, if the Fixed field is selected on the line for the item in the bin contents window.';
                }
                field("Find Floating Bin"; "Find Floating Bin")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies that a floating bin must be used in the put-away process.';
                }
                field("Find Same Item"; "Find Same Item")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies that a bin, which Specifies the same item that is being put away, is used in the put-away process.';
                }
                field("Find Unit of Measure Match"; "Find Unit of Measure Match")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies that a bin, which Specifies the item in the same unit of measure as the item that is being put away, must be used.';
                }
                field("Find Bin w. Less than Min. Qty"; "Find Bin w. Less than Min. Qty")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies that a fixed bin, with a quantity of item below the specified minimum quantity, must be used.';
                }
                field("Find Empty Bin"; "Find Empty Bin")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies that an empty bin must be used in the put-away process.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the description of the set of criteria that is on the put-away template line.';
                }
            }
        }
    }

    actions
    {
    }
}

