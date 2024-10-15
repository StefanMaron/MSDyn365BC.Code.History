﻿namespace Microsoft.Manufacturing.RoleCenters;

using Microsoft.Assembly.Document;
using Microsoft.Foundation.Navigate;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Reports;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Family;
using Microsoft.Manufacturing.Forecast;
using Microsoft.Manufacturing.Journal;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Reports;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.StandardCost;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Service.Document;

page 8903 "Manufacturing Manager RC"
{
    Caption = 'Manufacturing Manager RC';
    PageType = RoleCenter;
    actions
    {
        area(Sections)
        {
            group("Group")
            {
                Caption = 'Product Design';
                action("Items")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Items';
                    RunObject = page "Item List";
                }
                action("Production BOM")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Production BOM';
                    RunObject = page "Production BOM List";
                    AccessByPermission = TableData "Production Order" = R;
                }
                action("Routings")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Routings';
                    RunObject = page "Routing List";
                }
                action("Families")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Families';
                    RunObject = page "Family List";
                }
                action("Calcuate Low Level code")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Calculate Low-Level Code';
                    RunObject = report "Calculate Low Level Code";
                }
                group("Group1")
                {
                    Caption = 'Reports';
                    action("Quantity Explosion of BOM")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Quantity Explosion of BOM';
                        RunObject = report "Quantity Explosion of BOM";
                        AccessByPermission = TableData "Production Order" = R;
                    }
                    action("Where-Used (Top Level)")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Where-Used (Top Level)';
                        RunObject = report "Where-Used (Top Level)";
                        AccessByPermission = TableData "Production Order" = R;
                    }
                    action("Routing Sheet")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Routing Sheet';
                        RunObject = report "Routing Sheet";
                    }
                    action("Compare List")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Item BOM Compare List';
                        RunObject = report "Compare List";
                    }
                }
            }
            group("Group2")
            {
                Caption = 'Capacities';
                action("Machine Centers")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Machine Centers';
                    RunObject = page "Machine Center List";
                }
                action("Work Centers")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Work Centers';
                    RunObject = page "Work Center List";
                }
                group("Group3")
                {
                    Caption = 'Absence';
                    action("Registered Absences")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Registered Absences';
                        RunObject = page "Registered Absences";
                    }
                    action("Implement Registered Absence..")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Implement Registered Absence';
                        RunObject = report "Implement Registered Absence";
                    }
                    action("Reg. Abs (from Machine Ctr)")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Reg. Abs. (from Machine Ctr.)';
                        RunObject = report "Reg. Abs. (from Machine Ctr.)";
                    }
                    action("Reg. Absence (from Work Ctr)")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Reg. Abs. (from Work Center)';
                        RunObject = report "Reg. Abs. (from Work Center)";
                    }
                }
                group("Group4")
                {
                    Caption = 'Entries/Registers';
                    action("Item Registers")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Registers';
                        RunObject = page "Item Registers";
                    }
                    action("Resource Capacity Entries")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Resource Capacity Entries';
                        RunObject = page "Res. Capacity Entries";
                    }
                    action("Capacity Ledger Entries")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Capacity Ledger Entries';
                        RunObject = page "Capacity Ledger Entries";
                    }
                }
                group("Group5")
                {
                    Caption = 'Journals';
                    action("Capacity Journals")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Capacity Journals';
                        RunObject = page "Capacity Journal";
                    }
                    action("Recurring Capacity Journals")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Recurring Capacity Journals';
                        RunObject = page "Recurring Capacity Journal";
                    }
                }
                group("Group6")
                {
                    Caption = 'Reports';
                    action("Machine Center List")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Machine Center List';
                        RunObject = report "Machine Center List";
                    }
                    action("Work Center List")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Work Center List';
                        RunObject = report "Work Center List";
                    }
                    action("Capacity Task List")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Capacity Task List';
                        RunObject = report "Capacity Task List";
                    }
                }
            }
            group("Group7")
            {
                Caption = 'Planning';
                action("Items1")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Items';
                    RunObject = page "Item List";
                }
                action("Production Forecasts")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Production Forecasts';
                    RunObject = page "Demand Forecast Names";
                }
                action("Simulated Prod. Order")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Simulated Prod. Orders';
                    RunObject = page "Simulated Production Orders";
                }
                action("Jobs")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Projects';
                    RunObject = page "Job List";
                }
                group("Group8")
                {
                    Caption = 'Orders';
                    action("Orders")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Sales Orders';
                        RunObject = page "Sales Order List";
                    }
                    action("Orders1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Purchase Orders';
                        RunObject = page "Purchase Order List";
                    }
                    action("Transfer Orders")
                    {
                        ApplicationArea = Location;
                        Caption = 'Transfer Orders';
                        RunObject = page "Transfer Orders";
                    }
                    action("Assembly Orders")
                    {
                        ApplicationArea = Assembly;
                        Caption = 'Assembly Orders';
                        RunObject = page "Assembly Orders";
                    }
                    action("Orders2")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Orders';
                        RunObject = page "Service Orders";
                    }
                }
                group("Group9")
                {
                    Caption = 'Worksheets';
                    action("Planning Worksheets")
                    {
                        ApplicationArea = Planning;
                        Caption = 'Planning Worksheets';
                        RunObject = page "Planning Worksheet";
                    }
                    action("Order Planning")
                    {
                        ApplicationArea = Planning;
                        Caption = 'Order Planning';
                        RunObject = page "Order Planning";
                    }
                    action("Requisition Worksheets")
                    {
                        ApplicationArea = Planning;
                        Caption = 'Requisition Worksheets';
                        RunObject = page "Req. Worksheet";
                    }
                    action("Subcontracting Worksheet")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Subcontracting Worksheets';
                        RunObject = page "Subcontracting Worksheet";
                    }
                    action("Recurring Req. Worksheet")
                    {
                        ApplicationArea = Planning;
                        Caption = 'Recurring Requisition Worksheets';
                        RunObject = page "Recurring Req. Worksheet";
                    }
                }
                group("Group10")
                {
                    Caption = 'Reports';
                    action("Planning Availability")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Planning Availability';
                        RunObject = report "Planning Availability";
                    }
                    action("Production Forecast")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Production Forecast';
                        RunObject = report "Demand Forecast";
                    }
                    action("Item Substitutions")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Item Substitutions';
                        RunObject = report "Item Substitutions";
                    }
                }
            }
            group("Group11")
            {
                Caption = 'Operations';
                action("Planned Prod. Orders")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Planned Prod. Orders';
                    RunObject = page "Planned Production Orders";
                }
                action("Firm Planned Prod. Orders")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Firm Planned Prod. Orders';
                    RunObject = page "Firm Planned Prod. Orders";
                }
                action("Released Prod. Orders")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Released Prod. Orders';
                    RunObject = page "Released Production Orders";
                }
                action("Finished Prod. Orders")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Finished Prod. Orders';
                    RunObject = page "Finished Production Orders";
                }
                action("Item Registers1")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item Registers';
                    RunObject = page "Item Registers";
                }
                action("Item Tracing")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Item Tracing';
                    RunObject = page "Item Tracing";
                }
                action("Change Production Order Status")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Change Production Order Status';
                    RunObject = page "Change Production Order Status";
                }
                action("Navi&gate")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Find entries...';
                    Image = Navigate;
                    RunObject = Page Navigate;
                    ShortCutKey = 'Ctrl+Alt+Q';
                    ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';
                }
                group("Group12")
                {
                    Caption = 'Journals';
                    action("Consumption Journals")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Consumption Journals';
                        RunObject = page "Consumption Journal";
                    }
                    action("Output Journals")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Output Journals';
                        RunObject = page "Output Journal";
                    }
                    action("Recurring Consumption Journals")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Recurring Consumption Journals';
                        RunObject = page "Recurring Consumption Journal";
                    }
                    action("Recurring Output Journals")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Recurring Output Journals';
                        RunObject = page "Recurring Output Journal";
                    }
                }
                group("Group13")
                {
                    Caption = 'Reports';
                    action("Subcontractor - Dispatch List")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Subcontractor Dispatch List';
                        RunObject = report "Subcontractor - Dispatch List";
                    }
                    action("Capacity Task List1")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Capacity Task List';
                        RunObject = report "Capacity Task List";
                    }
                    action("Machine Center Load/Bar")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Machine Center Load/Bar';
                        RunObject = report "Machine Center Load/Bar";
                    }
                    action("Work Center Load/Bar")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Work Center Load/Bar';
                        RunObject = report "Work Center Load/Bar";
                    }
                    action("Machine Center Load")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Machine Center Load';
                        RunObject = report "Machine Center Load";
                    }
                    action("Work Center Load")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Work Center Load';
                        RunObject = report "Work Center Load";
                    }
                    group("Group14")
                    {
                        Caption = 'Prod.Order';
                        action("Prod. Order - Routing List")
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Prod. Order - Routing List';
                            RunObject = report "Prod. Order - Routing List";
                        }
                        action("Prod. Order - Mat. Requisition")
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Prod. Order - Mat. Requisition';
                            RunObject = report "Prod. Order - Mat. Requisition";
                        }
                        action("Prod. Order - List")
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Prod. Order - List';
                            RunObject = report "Prod. Order - List";
                        }
                        action("Prod. Order - Job Card")
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Prod. Order - Job Card';
                            RunObject = report "Prod. Order - Job Card";
                        }
                        action("Prod. Order - Picking List")
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Prod. Order Picking List';
                            RunObject = report "Prod. Order - Picking List";
                        }
                        action("Prod. Order - Shortage List")
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Prod. Order - Shortage List';
                            RunObject = report "Prod. Order - Shortage List";
                        }
                        action("Prod. Order Comp. and Routing")
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Prod. Order Comp. and Routing';
                            RunObject = report "Prod. Order Comp. and Routing";
                        }
                        action("Prod. Order - Precalc. Time")
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Prod. Order - Precalc. Time';
                            RunObject = report "Prod. Order - Precalc. Time";
                        }
                    }
                }
            }
            group("Group15")
            {
                Caption = 'Costing';
                action("Items2")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Items';
                    RunObject = page "Item List";
                }
                action("Update Unit Cost...")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Update Unit Costs...';
                    RunObject = report "Update Unit Cost";
                }
                action("Standard Cost Worksheet")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Standard Cost Worksheets';
                    RunObject = page "Standard Cost Worksheet";
                }
                action("Revaluation Journals")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Revaluation Journals';
                    RunObject = page "Revaluation Journal";
                }
                group("Group16")
                {
                    Caption = 'Reports';
                    action("Detailed Calculation")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Detailed Calculation';
                        RunObject = report "Detailed Calculation";
                    }
                    action("Inventory - Transaction Detail")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory Transaction Detail';
                        RunObject = report "Inventory - Transaction Detail";
                    }
                    action("Rolled-up Cost Shares")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Rolled-up Cost Shares';
                        RunObject = report "Rolled-up Cost Shares";
                    }
                    action("Prod. Order - Precalc. Time1")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Prod. Order - Precalc. Time';
                        RunObject = report "Prod. Order - Precalc. Time";
                    }
                    action("Status")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Status';
                        RunObject = report "Status";
                    }
                    action("Item Register - Quantity")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Register - Quantity';
                        RunObject = report "Item Register - Quantity";
                    }
                    action("Prod. Order - Detailed Calc.")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Prod. Order - Detailed Calc.';
                        RunObject = report "Prod. Order - Detailed Calc.";
                    }
                    action("Single-Level Cost Shares")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Single-Level Cost Shares';
                        RunObject = report "Single-level Cost Shares";
                    }
                    action("Prod. Order - Calculation")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Prod. Order - Calculation';
                        RunObject = report "Prod. Order - Calculation";
                    }
                    action("Compare List1")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Compare List';
                        RunObject = report "Compare List";
                    }
                    action("Inventory Valuation - WIP")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Production Order - WIP';
                        RunObject = report "Inventory Valuation - WIP";
                    }
                    action("Production Order Statistics")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Production Order Statistics';
                        RunObject = report "Production Order Statistics";
                    }
                }
            }
            group("Group17")
            {
                Caption = 'Setup';
                action("Manufacturing Setup")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Manufacturing Setup';
                    RunObject = page "Manufacturing Setup";
                }
                action("Report Selections Prod. Order")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Report Selections Prod. Order';
                    RunObject = page "Report Selection - Prod. Order";
                }
                action("Scrap Codes")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Scrap Codes';
                    RunObject = page "Scrap Codes";
                }
                action("Work Shifts")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Work Shifts';
                    RunObject = page "Work Shifts";
                }
                action("Capacity Constrained Resources")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Capacity Constrained Resources';
                    RunObject = page "Capacity Constrained Resources";
                }
                action("Routing Links")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Routing Links';
                    RunObject = page "Routing Links";
                }
                action("Capacity Units of Measure")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Capacity Units of Measure';
                    RunObject = page "Capacity Units of Measure";
                }
                action("Shop Calendars")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Shop Calendars';
                    RunObject = page "Shop Calendars";
                }
                action("Standard Tasks")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Standard Tasks';
                    RunObject = page "Standard Tasks";
                }
                action("Stop Codes")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Stop Codes';
                    RunObject = page "Stop Codes";
                }
                action("Work Center Groups")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Work Center Groups';
                    RunObject = page "Work Center Groups";
                }
            }
        }
    }
}
