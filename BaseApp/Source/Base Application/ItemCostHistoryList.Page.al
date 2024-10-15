page 12118 "Item Cost History List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Item Cost History';
    Editable = false;
    PageType = List;
    SourceTable = "Item Cost History";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1130000)
            {
                ShowCaption = false;
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item number that is assigned to the item in inventory.';
                }
                field("Competence Year"; "Competence Year")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date that is used to determine the LIFO valuation period.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the item that was entered in the Item Card window.';
                }
                field("Base Unit of Measure"; "Base Unit of Measure")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the standard unit of measure that is used to track the item in inventory.';
                }
                field("Inventory Valuation"; "Inventory Valuation")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the method of inventory valuation that is used to calculate item cost.';
                }
                field("Start Year Inventory"; "Start Year Inventory")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity of the item that is in inventory at the beginning of the year.';
                }
                field("End Year Inventory"; "End Year Inventory")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity of the item that is in inventory at the end of the year.';
                }
                field("Year Average Cost"; "Year Average Cost")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the average cost of the item during the year.';
                }
                field("Weighted Average Cost"; "Weighted Average Cost")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the year-end inventory valuation of the item using the weighted average cost method.';
                }
                field("FIFO Cost"; "FIFO Cost")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the year-end inventory First In, First Out (FIFO) valuation of the item.';
                }
                field("LIFO Cost"; "LIFO Cost")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the year-end inventory Last In, First Out (LIFO) valuation of the item.';
                }
                field("Discrete LIFO Cost"; "Discrete LIFO Cost")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the year-end inventory Last In, First Out (LIFO) valuation of the discrete manufacturing item.';
                }
                field("Expected Cost Exist"; "Expected Cost Exist")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if an expected item cost was used during the period for the item.';
                }
                field(Definitive; Definitive)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the year-end cost associated with this item is final.';
                }
                field("Purchase Quantity"; "Purchase Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity of the item that was purchased.';
                    Visible = false;
                }
                field("Purchase Amount"; "Purchase Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the monetary valuation of the items purchased.';
                    Visible = false;
                }
                field("Production Quantity"; "Production Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity of the item that is in production.';
                    Visible = false;
                }
                field("Production Amount"; "Production Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the monetary valuation of the item that is in production.';
                    Visible = false;
                }
                field("Direct Components Amount"; "Direct Components Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the direct cost of the item, based on the component costs directly attributable to the manufacture of the item.';
                    Visible = false;
                }
                field("Direct Routing Amount"; "Direct Routing Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the direct cost associated with the routing of an item.';
                    Visible = false;
                }
                field("Overhead Routing Amount"; "Overhead Routing Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the overhead cost associated with the routing of an item.';
                    Visible = false;
                }
                field("Subcontracted Amount"; "Subcontracted Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the cost of outsourcing operations to a subcontractor.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Print")
            {
                Caption = '&Print';
                Image = Print;
                action("Detail Data")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Detail Data';
                    ToolTip = 'View the related details.';

                    trigger OnAction()
                    var
                        ItemCostHistory: Record "Item Cost History";
                        DetailLedgEntries: Report "Ledger Entry Details";
                    begin
                        ItemCostHistory.Reset();
                        ItemCostHistory.SetRange("Item No.", "Item No.");
                        ItemCostHistory.SetRange("Competence Year", "Competence Year");
                        DetailLedgEntries.SetTableView(ItemCostHistory);
                        DetailLedgEntries.Run;
                    end;
                }
            }
        }
    }
}

