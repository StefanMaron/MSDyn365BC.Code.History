namespace Microsoft.Iventory.Item;

using Microsoft.Manufacturing.Reports;
using Microsoft.Manufacturing.StandardCost;
using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Inventory.BOM;

pageextension 99000751 "Mfg. Item List" extends "Item List"
{
    actions
    {
        addafter(Assembly)
        {
            group(Production)
            {
                Caption = 'Production';
                Image = Production;
                action("Production BOM")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Production BOM';
                    Image = BOM;
                    RunObject = Page "Production BOM";
                    RunPageLink = "No." = field("Production BOM No.");
                    ToolTip = 'Open the item''s production bill of material to view or edit its components.';
                }
                action("Prod. Active BOM Version")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Prod. Active BOM Version';
                    Image = BOMVersions;
                    ToolTip = 'Open the item''s active production bill of material to view or edit the components.';

                    trigger OnAction()
                    begin
                        Rec.OpenActiveProdBOMForItem(Rec."Production BOM No.", Rec."No.");
                    end;
                }
                action(Action29)
                {
                    AccessByPermission = TableData "BOM Component" = R;
                    ApplicationArea = Manufacturing;
                    Caption = 'Where-Used';
                    Image = "Where-Used";
                    ToolTip = 'View a list of production BOMs in which the item is used.';

                    trigger OnAction()
                    var
                        ProdBOMWhereUsed: Page "Prod. BOM Where-Used";
                    begin
                        ProdBOMWhereUsed.SetItem(Rec, WorkDate());
                        ProdBOMWhereUsed.RunModal();
                    end;
                }
                action(Action24)
                {
                    AccessByPermission = TableData "Production BOM Header" = R;
                    ApplicationArea = Manufacturing;
                    Caption = 'Calc. Production Std. Cost';
                    Image = CalculateCost;
                    ToolTip = 'Calculate the unit cost of the item by rolling up the unit cost of each component and resource in the item''s production BOM. The unit cost of a parent item must equal the total of the unit costs of its components, subassemblies, and any resources.';

                    trigger OnAction()
                    var
                        CalculateStandardCost: Codeunit "Calculate Standard Cost";
                    begin
                        CalculateStandardCost.CalcItem(Rec."No.", false);
                    end;
                }
            }
        }
        addafter("Inventory Valuation - WIP")
        {
            action("Cost Shares Breakdown")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Cost Shares Breakdown';
                Image = "Report";
                RunObject = Report "Cost Shares Breakdown";
                ToolTip = 'View the item''s cost broken down in inventory, WIP, or COGS, according to purchase and material cost, capacity cost, capacity overhead cost, manufacturing overhead cost, subcontracted cost, variance, indirect cost, revaluation, and rounding. The report breaks down cost at a single BOM level and does not roll up the costs from lower BOM levels. The report does not calculate the cost share from items that use the Average costing method.';
            }
            action("Detailed Calculation")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Detailed Calculation';
                Image = "Report";
                RunObject = Report "Detailed Calculation";
                ToolTip = 'View the list of all costs for the item taking into account any scrap during production.';
            }
            action("Rolled-up Cost Shares")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Rolled-up Cost Shares';
                Image = "Report";
                RunObject = Report "Rolled-up Cost Shares";
                ToolTip = 'View the cost shares of all items in the parent item''s product structure, their quantity and their cost shares specified in material, capacity, overhead, and total cost. Material cost is calculated as the cost of all items in the parent item''s product structure. Capacity and subcontractor costs are calculated as the costs related to produce all of the items in the parent item''s product structure. Material cost is calculated as the cost of all items in the item''s product structure. Capacity and subcontractor costs are the cost related to the parent item only.';
            }
            action("Single-Level Cost Shares")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Single-Level Cost Shares';
                Image = "Report";
                RunObject = Report "Single-level Cost Shares";
                ToolTip = 'View the cost shares of all items in the item''s product structure, their quantity and their cost shares specified in material, capacity, overhead, and total cost. Material cost is calculated as the cost of all items in the parent item''s product structure. Capacity and subcontractor costs are calculated as the costs related to produce all of the items in the parent item''s product structure.';
            }
        }
        addafter("Invt. Valuation - Cost Spec.")
        {
            action("Compare List")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Compare List';
                Image = "Report";
                RunObject = Report "Compare List";
                ToolTip = 'View a comparison of components for two items. The printout compares the components, their unit cost, cost share and cost per component.';
            }
        }
    }

    procedure SelectActiveItemsForProductionBOM(): Text
    var
        Item: Record Item;
    begin
        Item.SetFilter(Type, '<>%1', Item.Type::Service);
        exit(SelectInItemList(Item));
    end;
}