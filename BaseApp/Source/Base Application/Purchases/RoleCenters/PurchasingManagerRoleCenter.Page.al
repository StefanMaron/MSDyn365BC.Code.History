﻿namespace Microsoft.Purchases.RoleCenters;

using Microsoft.Assembly.Document;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Team;
using Microsoft.Finance.Deferral;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.Shipping;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Reports;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Forecast;
using Microsoft.Manufacturing.Journal;
using Microsoft.Manufacturing.Reports;
using Microsoft.Manufacturing.StandardCost;
using Microsoft.Projects.Project.Job;
using Microsoft.Purchases.Analysis;
using Microsoft.Purchases.Archive;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Reports;
using Microsoft.Purchases.Setup;
using Microsoft.Sales.Document;
using Microsoft.Service.Document;
using Microsoft.Utilities;

page 8905 "Purchasing Manager Role Center"
{
    Caption = 'Purchasing Manager Role Center';
    PageType = RoleCenter;
    actions
    {
        area(Sections)
        {
            group("Group")
            {
                Caption = 'Purchasing';
                action("Vendors")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendors';
                    RunObject = page Vendors;
                }
                action("Contacts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Contacts';
                    RunObject = page "Contact List";
                    Tooltip = 'Open the Contacts page.';
                }
                action("Quotes")
                {
                    ApplicationArea = Suite;
                    Caption = 'Purchase Quotes';
                    RunObject = page "Purchase Quotes";
                    Tooltip = 'Open the Purchase Quotes page.';
                }
                action("Orders")
                {
                    ApplicationArea = Suite;
                    Caption = 'Purchase Orders';
                    RunObject = page "Purchase Order List";
                    Tooltip = 'Open the Purchase Orders page.';
                }
                action("Blanket Orders")
                {
                    ApplicationArea = Suite;
                    Caption = 'Blanket Purchase Orders';
                    RunObject = page "Blanket Purchase Orders";
                    Tooltip = 'Open the Blanket Purchase Orders page.';
                }
                action("Return Orders")
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Purchase Return Orders';
                    RunObject = page "Purchase Return Order List";
                    Tooltip = 'Open the Purchase Return Orders page.';
                }
                action("Transfer Orders")
                {
                    ApplicationArea = Location;
                    Caption = 'Transfer Orders';
                    RunObject = page "Transfer Orders";
                    Tooltip = 'Open the Transfer Orders page.';
                }
                action("Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Purchase Invoices';
                    RunObject = page "Purchase Invoices";
                    Tooltip = 'Open the Purchase Invoices page.';
                }
                action("Credit Memos")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Purchase Credit Memos';
                    RunObject = page "Purchase Credit Memos";
                    Tooltip = 'Open the Purchase Credit Memos page.';
                }
                action("Certificates of Supply")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Certificates of Supply';
                    RunObject = page "Certificates of Supply";
                    Tooltip = 'Open the Certificates of Supply page.';
                }
                action("Subcontracting Worksheet")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Subcontracting Worksheets';
                    RunObject = page "Subcontracting Worksheet";
                    Tooltip = 'Open the Subcontracting Worksheets page.';
                }
                action("Purchase Journals")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Purchase Journals';
                    RunObject = page "Purchase Journal";
                    Tooltip = 'Open the Purchase Journals page.';
                }
                action("Letters of Attorney")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Letters of Attorney';
                    RunObject = page "Letter of Attorney List";
                    Tooltip = 'Open the Letters of Attorney page.';
                }
                group("Group1")
                {
                    Caption = 'Budgets & Analysis';
                    action("Purchase Budgets")
                    {
                        ApplicationArea = PurchaseBudget;
                        Caption = 'Purchase Budgets';
                        RunObject = page "Budget Names Purchase";
                        Tooltip = 'Open the Purchase Budgets page.';
                    }
                    action("Purchase Analysis Reports")
                    {
                        ApplicationArea = PurchaseAnalysis;
                        Caption = 'Purchase Analysis Reports';
                        RunObject = page "Analysis Report Purchase";
                        Tooltip = 'Open the Purchase Analysis Reports page.';
                    }
                    action("Analysis by Dimensions")
                    {
                        ApplicationArea = Dimensions, PurchaseAnalysis;
                        Caption = 'Purchase Analysis by Dimensions';
                        RunObject = page "Analysis View List Purchase";
                        Tooltip = 'Open the Purchase Analysis by Dimensions page.';
                    }
                    action("Item Dimensions - Detail")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Item Dimensions - Detail';
                        RunObject = report "Item Dimensions - Detail";
                        Tooltip = 'Run the Item Dimensions - Detail report.';
                    }
                    action("Item Dimensions - Total")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Item Dimensions - Total';
                        RunObject = report "Item Dimensions - Total";
                        Tooltip = 'Run the Item Dimensions - Total report.';
                    }
                }
                group("Group2")
                {
                    Caption = 'Registers/Entries';
                    action("Purchase Quote Archives")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Purchase Quote Archives';
                        RunObject = page "Purchase Quote Archives";
                        Tooltip = 'Open the Purchase Quote Archives page.';
                    }
                    action("Purchase Order Archives")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Purchase Order Archives';
                        RunObject = page "Purchase Order Archives";
                        Tooltip = 'Open the Purchase Order Archives page.';
                    }
                    action("Posted Purchase Invoices")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Purchase Invoices';
                        RunObject = page "Posted Purchase Invoices";
                        Tooltip = 'Open the Posted Purchase Invoices page.';
                    }
                    action("Posted Return Shipments")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Posted Purchase Return Shipments';
                        RunObject = page "Posted Return Shipments";
                        Tooltip = 'Open the Posted Purchase Return Shipments page.';
                    }
                    action("Posted Credit Memos")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Purchase Credit Memos';
                        RunObject = page "Posted Purchase Credit Memos";
                        Tooltip = 'Open the Posted Purchase Credit Memos page.';
                    }
                    action("Posted Purchase Receipts")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Posted Purchase Receipts';
                        RunObject = page "Posted Purchase Receipts";
                        Tooltip = 'Open the Posted Purchase Receipts page.';
                    }
                    action("G/L Registers")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'G/L Registers';
                        RunObject = page "G/L Registers";
                        Tooltip = 'Open the G/L Registers page.';
                    }
                    action("Item Tracing")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Item Tracing';
                        RunObject = page "Item Tracing";
                        Tooltip = 'Open the Item Tracing page.';
                    }
                    action("Purchase Return Order Archives")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Purchase Return Order Archives';
                        RunObject = page "Purchase Return List Archive";
                        Tooltip = 'Open the Purchase Return Order Archives page.';
                    }
                    action("Vendor Ledger Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor Ledger Entries';
                        RunObject = page "Vendor Ledger Entries";
                        Tooltip = 'Open the Vendor Ledger Entries page.';
                    }
                    action("Detailed Cust. Ledg. Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Detailed Vendor Ledger Entries';
                        RunObject = page "Detailed Vendor Ledg. Entries";
                        Tooltip = 'Open the Detailed Vendor Ledger Entries page.';
                    }
                    action("Value Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Value Entries';
                        RunObject = page "Value Entries";
                        Tooltip = 'Open the Value Entries page.';
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
                }
                group("Group3")
                {
                    Caption = 'Reports';
                    action("Inventory Purchase Orders")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Inventory Purchase Orders';
                        RunObject = report "Inventory Purchase Orders";
                        Tooltip = 'Run the Inventory Purchase Orders report.';
                    }
                    action("Inventory - Transaction Detail")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory Transaction Detail';
                        RunObject = report "Inventory - Transaction Detail";
                        Tooltip = 'Run the Inventory Transaction Detail report.';
                    }
                    action("Inventory - Reorders")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory Reorders';
                        RunObject = report "Inventory - Reorders";
                        Tooltip = 'Run the Inventory Reorders report.';
                    }
                    action("Item/Vendor Catalog")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item/Vendor Catalog';
                        RunObject = report "Item/Vendor Catalog";
                        Tooltip = 'Run the Item/Vendor Catalog report.';
                    }
                    action("Vendor/Item Purchases")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor/Item Purchases';
                        RunObject = report "Vendor/Item Purchases";
                        Tooltip = 'Run the Vendor/Item Purchases report.';
                    }
                    action("Inventory Cost and Price List")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory Cost and Price List';
                        RunObject = report "Inventory Cost and Price List";
                        Tooltip = 'Run the Inventory Cost and Price List report.';
                    }
                    action("Inventory - List")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory - List';
                        RunObject = report "Inventory - List";
                        Tooltip = 'Run the Inventory - List report.';
                    }
                    action("Inventory Availability")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory Availability';
                        RunObject = report "Inventory Availability";
                        Tooltip = 'Run the Inventory Availability report.';
                    }
                    action("Item Charges - Specification")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Charges - Specification';
                        RunObject = report "Item Charges - Specification";
                        Tooltip = 'Run the Item Charges - Specification report.';
                    }
                    action("Inventory - Vendor Purchases")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory - Vendor Purchases';
                        RunObject = report "Inventory - Vendor Purchases";
                        Tooltip = 'Run the Inventory - Vendor Purchases report.';
                    }
                    action("Item Substitutions")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Item Substitutions';
                        RunObject = report "Item Substitutions";
                        Tooltip = 'Run the Item Substitutions report.';
                    }
                    // action("Order")
                    // {
                    //     ApplicationArea = Suite;
                    //     Caption = 'Order';
                    //     RunObject = codeunit 8815;
                    // }
                    action("Purchasing Deferral Summary")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Purchasing Deferral Summary';
                        RunObject = report "Deferral Summary - Purchasing";
                        Tooltip = 'Run the Purchasing Deferral Summary report.';
                    }
                }
            }
            group("Group4")
            {
                Caption = 'Planning';
                action("Items")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Items';
                    RunObject = page "Item List";
                    Tooltip = 'Open the Items page.';
                }
                action("Vendors1")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendors';
                    RunObject = page Vendors;
                }
                action("Production Forecasts")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Production Forecasts';
                    RunObject = page "Demand Forecast Names";
                    Tooltip = 'Open the Production Forecasts page.';
                }
                action("Orders1")
                {
                    ApplicationArea = Suite;
                    Caption = 'Purchase Orders';
                    RunObject = page "Purchase Order List";
                    Tooltip = 'Open the Purchase Orders page.';
                }
                action("Orders2")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Orders';
                    RunObject = page "Sales Order List";
                    Tooltip = 'Open the Sales Orders page.';
                }
                action("Blanket Orders1")
                {
                    ApplicationArea = Suite;
                    Caption = 'Blanket Sales Orders';
                    RunObject = page "Blanket Sales Orders";
                    Tooltip = 'Open the Blanket Sales Orders page.';
                }
                action("Assembly Orders")
                {
                    ApplicationArea = Assembly;
                    Caption = 'Assembly Orders';
                    RunObject = page "Assembly Orders";
                    Tooltip = 'Open the Assembly Orders page.';
                }
                action("Orders3")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Orders';
                    RunObject = page "Service Orders";
                    Tooltip = 'Open the Service Orders page.';
                }
                action("Jobs")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Projects';
                    RunObject = page "Job List";
                    Tooltip = 'Open the Jobs page.';
                }
                action("Planned Prod. Orders")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Planned Production Orders';
                    RunObject = page "Planned Production Orders";
                    Tooltip = 'Open the Planned Production Orders page.';
                }
                action("Firm Planned Prod. Orders")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Firm Planned Prod. Orders';
                    RunObject = page "Firm Planned Prod. Orders";
                    Tooltip = 'Open the Firm Planned Prod. Orders page.';
                }
                action("Transfer Orders1")
                {
                    ApplicationArea = Location;
                    Caption = 'Transfer Orders';
                    RunObject = page "Transfer Orders";
                    Tooltip = 'Open the Transfer Orders page.';
                }
                action("Requisition Worksheets")
                {
                    ApplicationArea = Planning;
                    Caption = 'Requisition Worksheets';
                    RunObject = page "Req. Worksheet";
                    Tooltip = 'Open the Requisition Worksheets page.';
                }
                action("Recurring Req. Worksheet")
                {
                    ApplicationArea = Planning;
                    Caption = 'Recurring Requisition Worksheets';
                    RunObject = page "Recurring Req. Worksheet";
                    Tooltip = 'Open the Recurring Requisition Worksheets page.';
                }
                action("Order Planning")
                {
                    ApplicationArea = Planning;
                    Caption = 'Order Planning';
                    RunObject = page "Order Planning";
                    Tooltip = 'Open the Order Planning page.';
                }
                group("Group5")
                {
                    Caption = 'Reports';
                    action("Purchase Reservation Avail.")
                    {
                        ApplicationArea = Reservation;
                        Caption = 'Purchase Reservation Avail.';
                        RunObject = report "Purchase Reservation Avail.";
                        Tooltip = 'Run the Purchase Reservation Avail. report.';
                    }
                    action("Nonstock Item Sales")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Nonstock Item Sales';
                        RunObject = report "Catalog Item Sales";
                        Tooltip = 'Run the Nonstock Item Sales report.';
                    }
                    action("Item/Vendor Catalog1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item/Vendor Catalog';
                        RunObject = report "Item/Vendor Catalog";
                        Tooltip = 'Run the Item/Vendor Catalog report.';
                    }
                    action("Prod. Order - Shortage List")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Prod. Order - Shortage List';
                        RunObject = report "Prod. Order - Shortage List";
                        Tooltip = 'Run the Prod. Order - Shortage List report.';
                    }
                    action("Prod. Order - Mat. Requisition")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Prod. Order - Mat. Requisition';
                        RunObject = report "Prod. Order - Mat. Requisition";
                        Tooltip = 'Run the Prod. Order - Mat. Requisition report.';
                    }
                    action("Purchase Statistics")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Purchase Statistics';
                        RunObject = report "Purchase Statistics";
                        Tooltip = 'Run the Purchase Statistics report.';
                    }
                    action("Item Substitutions1")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Item Substitutions';
                        RunObject = report "Item Substitutions";
                        Tooltip = 'Run the Item Substitutions report.';
                    }
                    group("Group6")
                    {
                        Caption = 'Vendor';
                        action("Vendor - Balance to Date")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Vendor - Balance to Date';
                            RunObject = report "Vendor - Balance to Date";
                            Tooltip = 'Run the Vendor - Balance to Date report.';
                        }
                        action("Vendor/Item Purchases1")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Vendor/Item Purchases';
                            RunObject = report "Vendor/Item Purchases";
                            Tooltip = 'Run the Vendor/Item Purchases report.';
                        }
                        action("Vendor - Purchase List")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Vendor - Purchase List';
                            RunObject = report "Vendor - Purchase List";
                            Tooltip = 'Run the Vendor - Purchase List report.';
                        }
                        action("Vendor - Trial Balance")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Vendor - Trial Balance';
                            RunObject = report "Vendor - Trial Balance";
                            Tooltip = 'Run the Vendor - Trial Balance report.';
                        }
                        action("Vendor - Detail Trial Balance")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Vendor - Detail Trial Balance';
                            RunObject = report "Vendor - Detail Trial Balance";
                            Tooltip = 'Run the Vendor - Detail Trial Balance report.';
                        }
                        action("Vendor - Top 10 List")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Vendor - Top 10 List';
                            RunObject = report "Vendor - Top 10 List";
                            Tooltip = 'Run the Vendor - Top 10 List report.';
                        }
                        action("Vendor - List")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Vendor - List';
                            RunObject = report "Vendor - List";
                            Tooltip = 'Run the Vendor - List report.';
                        }
                        action("Vendor - Summary Aging")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Vendor - Summary Aging';
                            RunObject = report "Vendor - Summary Aging";
                            Tooltip = 'Run the Vendor - Summary Aging report.';
                        }
                        action("Vendor Item Catalog")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Vendor Item Catalog';
                            RunObject = report "Vendor Item Catalog";
                            Tooltip = 'Run the Vendor Item Catalog report.';
                        }
                    }
                    group("Group7")
                    {
                        Caption = 'Inventory';
                        action("Inventory - Cost Variance")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Inventory - Cost Variance';
                            RunObject = report "Inventory - Cost Variance";
                            Tooltip = 'Run the Inventory - Cost Variance report.';
                        }
                        action("Inventory - Vendor Purchases1")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Inventory - Vendor Purchases';
                            RunObject = report "Inventory - Vendor Purchases";
                            Tooltip = 'Run the Inventory - Vendor Purchases report.';
                        }
                        action("Inventory - Availability Plan")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Inventory - Availability Plan';
                            RunObject = report "Inventory - Availability Plan";
                            Tooltip = 'Run the Inventory - Availability Plan report.';
                        }
                        action("Inventory Purchase Orders1")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Inventory Purchase Orders';
                            RunObject = report "Inventory Purchase Orders";
                            Tooltip = 'Run the Inventory Purchase Orders report.';
                        }
                        action("Inventory - List1")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Inventory - List';
                            RunObject = report "Inventory - List";
                            Tooltip = 'Run the Inventory - List report.';
                        }
                        action("Inventory - Inbound Transfer")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Inventory - Inbound Transfer';
                            RunObject = report "Inventory - Inbound Transfer";
                            Tooltip = 'Run the Inventory - Inbound Transfer report.';
                        }
                        action("Inventory Cost and Price List1")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Inventory Cost and Price List';
                            RunObject = report "Inventory Cost and Price List";
                            Tooltip = 'Run the Inventory Cost and Price List report.';
                        }
                    }
                }
            }
            group("Group8")
            {
                Caption = 'Inventory & Costing';
                action("Items1")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Items';
                    RunObject = page "Item List";
                    Tooltip = 'Open the Items page.';
                }
                action("Nonstock Items")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Nonstock Items';
                    RunObject = page "Catalog Item List";
                    Tooltip = 'Open the Nonstock Items page.';
                }
                action("Stock keeping Units")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Stockkeeping Units';
                    RunObject = page "Stockkeeping Unit List";
                    Tooltip = 'Open the Stockkeeping Units page.';
                }
                action("Adjust Cost - Item Entries...")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Adjust Cost Item Entries';
                    RunObject = report "Adjust Cost - Item Entries";
                    Tooltip = 'Run the Adjust Cost Item Entries report.';
                }
                action("Standard Costs Worksheet")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Standard Costs Worksheet';
                    RunObject = page "Standard Cost Worksheet";
                    Tooltip = 'Open the Standard Costs Worksheet page.';
                }
                action("Adjust Item Costs/Prices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Adjust Item Costs/Prices';
                    RunObject = report "Adjust Item Costs/Prices";
                    Tooltip = 'Run the Adjust Item Costs/Prices report.';
                }
                group("Group9")
                {
                    Caption = 'Journals';
                    action("Item Journal")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Journals';
                        RunObject = page "Item Journal";
                        Tooltip = 'Open the Item Journals page.';
                    }
                    action("Item Reclass. Journals")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Reclassification Journals';
                        RunObject = page "Item Reclass. Journal";
                        Tooltip = 'Open the Item Reclassification Journals page.';
                    }
                    action("Recurring Item Journals")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Recurring Item Journals';
                        RunObject = page "Recurring Item Jnl.";
                        Tooltip = 'Open the Recurring Item Journals page.';
                    }
                }
                group("Group10")
                {
                    Caption = 'Reports';
                    action("Inventory - List2")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory - List';
                        RunObject = report "Inventory - List";
                        Tooltip = 'Run the Inventory - List report.';
                    }
                    action("Item Age Composition - Qty.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Age Composition - Qty.';
                        RunObject = report "Item Age Composition - Qty.";
                        Tooltip = 'Run the Item Age Composition - Qty. report.';
                    }
                    action("Inventory - Cost Variance1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory - Cost Variance';
                        RunObject = report "Inventory - Cost Variance";
                        Tooltip = 'Run the Inventory - Cost Variance report.';
                    }
                    action("Item Charges - Specification1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Charges - Specification';
                        RunObject = report "Item Charges - Specification";
                        Tooltip = 'Run the Item Charges - Specification report.';
                    }
                    action("Inventory - Inbound Transfer1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory - Inbound Transfer';
                        RunObject = report "Inventory - Inbound Transfer";
                        Tooltip = 'Run the Inventory - Inbound Transfer report.';
                    }
                    action("Invt. Valuation - Cost Spec.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Invt. Valuation - Cost Spec.';
                        RunObject = report "Invt. Valuation - Cost Spec.";
                        Tooltip = 'Run the Invt. Valuation - Cost Spec. report.';
                    }
                    action("Item Age Composition - Value")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Age Composition - Value';
                        RunObject = report "Item Age Composition - Value";
                        Tooltip = 'Run the Item Age Composition - Value report.';
                    }
                    action("Inventory Availability1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory Availability';
                        RunObject = report "Inventory Availability";
                        Tooltip = 'Run the Inventory Availability report.';
                    }
                    action("Item Register - Quantity")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Register - Quantity';
                        RunObject = report "Item Register - Quantity";
                        Tooltip = 'Run the Item Register - Quantity report.';
                    }
                    action("Item Register - Value")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Register - Value';
                        RunObject = report "Item Register - Value";
                        Tooltip = 'Run the Item Register - Value report.';
                    }
                    action("Item Expiration - Quantity")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Item Expiration - Quantity';
                        RunObject = report "Item Expiration - Quantity";
                        Tooltip = 'Run the Item Expiration - Quantity report.';
                    }
                }
            }
            group("Group11")
            {
                Caption = 'Setup';
                action("Purchases & Payables Setup")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Purchases & Payables Setup';
                    RunObject = page "Purchases & Payables Setup";
                    Tooltip = 'Open the Purchases & Payables Setup page.';
                }
                action("Standard Purchase Codes")
                {
                    ApplicationArea = Suite;
                    Caption = 'Standard Purchase Codes';
                    RunObject = page "Standard Purchase Codes";
                    Tooltip = 'Open the Standard Purchase Codes page.';
                }
                action("Purchasing Codes")
                {
                    ApplicationArea = Suite;
                    Caption = 'Purchasing Codes';
                    RunObject = page "Purchasing Codes";
                    Tooltip = 'Open the Purchasing Codes page.';
                }
                action("Shipment Methods")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Shipment Methods';
                    RunObject = page "Shipment Methods";
                    Tooltip = 'Open the Shipment Methods page.';
                }
                action("Return Reasons")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Return Reasons';
                    RunObject = page "Return Reasons";
                    Tooltip = 'Open the Return Reasons page.';
                }
                action("Report Selection Purchase")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Report Selections Purchase';
                    RunObject = page "Report Selection - Purchase";
                    Tooltip = 'Open the Report Selections Purchase page.';
                }
                action("Req. Worksheet")
                {
                    ApplicationArea = Planning;
                    Caption = 'Requisition Worksheet Templates';
                    RunObject = page "Req. Worksheet Templates";
                    Tooltip = 'Open the Requisition Worksheet Templates page.';
                }
                action("Units of Measure")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Units of Measure';
                    RunObject = page "Units of Measure";
                    Tooltip = 'Open the Units of Measure page.';
                }
                action("Manufacturers")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Manufacturers';
                    RunObject = page "Manufacturers";
                    Tooltip = 'Open the Manufacturers page.';
                }
                action("Nonstock Item Setup")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Nonstock Item Setup';
                    RunObject = page "Catalog Item Setup";
                    Tooltip = 'Open the Nonstock Item Setup page.';
                }
                action("Item Journal Templates")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item Journal Templates';
                    RunObject = page "Item Journal Templates";
                    Tooltip = 'Open the Item Journal Templates page.';
                }
                action("Salespeople")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Salespeople/Purchasers';
                    RunObject = page "Salespersons/Purchasers";
                    Tooltip = 'Open the Salespeople/Purchasers page.';
                }
                action("Item Disc. Groups")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item Discount Groups';
                    RunObject = page "Item Disc. Groups";
                    Tooltip = 'Open the Item Discount Groups page.';
                }
                action("Item Tracking Codes")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item Tracking Codes';
                    RunObject = page "Item Tracking Codes";
                    Tooltip = 'Open the Item Tracking Codes page.';
                }
                action("Inventory Setup")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Inventory Setup';
                    RunObject = page "Inventory Setup";
                    Tooltip = 'Open the Inventory Setup page.';
                }
                action("Requisition Worksheets1")
                {
                    ApplicationArea = Planning;
                    Caption = 'Requisition Worksheets';
                    RunObject = page "Req. Worksheet";
                    Tooltip = 'Open the Requisition Worksheets page.';
                }
                group("Group12")
                {
                    Caption = 'Purchase Analysis';
                    action("Analysis Types")
                    {
                        ApplicationArea = SalesAnalysis, PurchaseAnalysis, InventoryAnalysis;
                        Caption = 'Analysis Types';
                        RunObject = page "Analysis Types";
                        Tooltip = 'Open the Analysis Types page.';
                    }
                    action("Analysis by Dimensions1")
                    {
                        ApplicationArea = Dimensions, PurchaseAnalysis;
                        Caption = 'Purchase Analysis by Dimensions';
                        RunObject = page "Analysis View List Purchase";
                        Tooltip = 'Open the Purchase Analysis by Dimensions page.';
                    }
                    action("Analysis Column Templates")
                    {
                        ApplicationArea = PurchaseAnalysis;
                        Caption = 'Purch. Analysis Column Templates';
                        RunObject = report "Run Purch. Analysis Col. Temp.";
                        Tooltip = 'Run the Purch. Analysis Column Templates report.';
                    }
                    action("Analysis Line Templates")
                    {
                        ApplicationArea = PurchaseAnalysis;
                        Caption = 'Purch. Analysis Line Templates';
                        RunObject = report "Run Purch. Analysis Line Temp.";
                        Tooltip = 'Run the Purch. Analysis Line Templates report.';
                    }
                }
            }
        }
    }
}