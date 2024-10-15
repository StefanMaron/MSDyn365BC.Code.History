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
                    RunObject = Page "Vendor List";
                }
                action("Contacts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Contacts';
                    RunObject = Page "Contact List";
                }
                action("Quotes")
                {
                    ApplicationArea = Suite;
                    Caption = 'Purchase Quotes';
                    RunObject = Page "Purchase Quotes";
                }
                action("Orders")
                {
                    ApplicationArea = Suite;
                    Caption = 'Purchase Orders';
                    RunObject = Page "Purchase Order List";
                }
                action("Blanket Orders")
                {
                    ApplicationArea = Suite;
                    Caption = 'Blanket Purchase Orders';
                    RunObject = Page "Blanket Purchase Orders";
                }
                action("Return Orders")
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Purchase Return Orders';
                    RunObject = Page "Purchase Return Order List";
                }
                action("Transfer Orders")
                {
                    ApplicationArea = Location;
                    Caption = 'Transfer Orders';
                    RunObject = Page "Transfer Orders";
                }
                action("Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Purchase Invoices';
                    RunObject = Page "Purchase Invoices";
                }
                action("Credit Memos")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Purchase Credit Memos';
                    RunObject = Page "Purchase Credit Memos";
                }
                action("Certificates of Supply")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Certificates of Supply';
                    RunObject = Page "Certificates of Supply";
                }
                action("Subcontracting Worksheet")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Subcontracting Worksheets';
                    RunObject = Page "Subcontracting Worksheet";
                }
                action("Purchase Journals")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Purchase Journals';
                    RunObject = Page "Purchase Journal";
                }
                group("Group1")
                {
                    Caption = 'Budgets & Analysis';
                    action("Purchase Budgets")
                    {
                        ApplicationArea = PurchaseBudget;
                        Caption = 'Purchase Budgets';
                        RunObject = Page "Budget Names Purchase";
                    }
                    action("Purchase Analysis Reports")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Purchase Analysis Reports';
                        RunObject = Page "Analysis Report Purchase";
                    }
                    action("Analysis by Dimensions")
                    {
                        ApplicationArea = Dimensions, PurchaseAnalysis;
                        Caption = 'Purchase Analysis by Dimensions';
                        RunObject = Page "Analysis View List Purchase";
                    }
                    action("Item Dimensions - Detail")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Item Dimensions - Detail';
                        RunObject = Report "Item Dimensions - Detail";
                    }
                    action("Item Dimensions - Total")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Item Dimensions - Total';
                        RunObject = Report "Item Dimensions - Total";
                    }
                }
                group("Group2")
                {
                    Caption = 'Registers/Entries';
                    action("Purchase Quote Archives")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Purchase Quote Archives';
                        RunObject = Page "Purchase Quote Archives";
                    }
                    action("Purchase Order Archives")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Purchase Order Archives';
                        RunObject = Page "Purchase Order Archives";
                    }
                    action("Posted Purchase Invoices")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Purchase Invoices';
                        RunObject = Page "Posted Purchase Invoices";
                    }
                    action("Posted Return Shipments")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Posted Purchase Return Shipments';
                        RunObject = Page "Posted Return Shipments";
                    }
                    action("Posted Credit Memos")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Purchase Credit Memos';
                        RunObject = Page "Posted Purchase Credit Memos";
                    }
                    action("Posted Purchase Receipts")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Posted Purchase Receipts';
                        RunObject = Page "Posted Purchase Receipts";
                    }
                    action("G/L Registers")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'G/L Registers';
                        RunObject = Page "G/L Registers";
                    }
                    action("Item Tracing")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Item Tracing';
                        RunObject = Page "Item Tracing";
                    }
                    action("Purchase Return Order Archives")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Purchase Return Order Archives';
                        RunObject = Page "Purchase Return List Archive";
                    }
                    action("Vendor Ledger Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor Ledger Entries';
                        RunObject = Page "Vendor Ledger Entries";
                    }
                    action("Detailed Cust. Ledg. Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Detailed Vendor Ledger Entries';
                        RunObject = Page "Detailed Vendor Ledg. Entries";
                    }
                    action("Value Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Value Entries';
                        RunObject = Page "Value Entries";
                    }
                }
                group("Group3")
                {
                    Caption = 'Reports';
                    action("Inventory Purchase Orders")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Inventory Purchase Orders';
                        RunObject = Report "Inventory Purchase Orders";
                    }
                    action("Inventory - Transaction Detail")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory Transaction Detail';
                        RunObject = Report "Inventory - Transaction Detail";
                    }
                    action("Inventory - Reorders")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory Reorders';
                        RunObject = Report "Inventory - Reorders";
                    }
                    action("Item/Vendor Catalog")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item/Vendor Catalog';
                        RunObject = Report "Item/Vendor Catalog";
                    }
                    action("Vendor/Item Purchases")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor/Item Purchases';
                        RunObject = Report "Vendor/Item Purchases";
                    }
                    action("Inventory Cost and Price List")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory Cost and Price List';
                        RunObject = Report "Inventory Cost and Price List";
                    }
                    action("Inventory - List")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory - List';
                        RunObject = Report "Inventory - List";
                    }
                    action("Inventory Availability")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory Availability';
                        RunObject = Report "Inventory Availability";
                    }
                    action("Item Charges - Specification")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Charges - Specification';
                        RunObject = Report "Item Charges - Specification";
                    }
                    action("Inventory - Vendor Purchases")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory - Vendor Purchases';
                        RunObject = Report "Inventory - Vendor Purchases";
                    }
                    action("Item Substitutions")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Item Substitutions';
                        RunObject = Report "Item Substitutions";
                    }
                    // action("Order")
                    // {
                    //     ApplicationArea = Suite;
                    //     Caption = 'Order';
                    //     RunObject = Codeunit 8815;
                    // }
                    action("Purchasing Deferral Summary")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Purchasing Deferral Summary';
                        RunObject = Report "Deferral Summary - Purchasing";
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
                    RunObject = Page "Item List";
                }
                action("Vendors1")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendors';
                    RunObject = Page "Vendor List";
                }
                action("Production Forecasts")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Production Forecasts';
                    RunObject = Page "Demand Forecast Names";
                }
                action("Orders1")
                {
                    ApplicationArea = Suite;
                    Caption = 'Purchase Orders';
                    RunObject = Page "Purchase Order List";
                }
                action("Orders2")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Orders';
                    RunObject = Page "Sales Order List";
                }
                action("Blanket Orders1")
                {
                    ApplicationArea = Suite;
                    Caption = 'Blanket Sales Orders';
                    RunObject = Page "Blanket Sales Orders";
                }
                action("Assembly Orders")
                {
                    ApplicationArea = Assembly;
                    Caption = 'Assembly Orders';
                    RunObject = Page "Assembly Orders";
                }
                action("Orders3")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Orders';
                    RunObject = Page "Service Orders";
                }
                action("Jobs")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Jobs';
                    RunObject = Page "Job List";
                }
                action("Planned Prod. Orders")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Planned Production Orders';
                    RunObject = Page "Planned Production Orders";
                }
                action("Firm Planned Prod. Orders")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Firm Planned Prod. Orders';
                    RunObject = Page "Firm Planned Prod. Orders";
                }
                action("Transfer Orders1")
                {
                    ApplicationArea = Location;
                    Caption = 'Transfer Orders';
                    RunObject = Page "Transfer Orders";
                }
                action("Requisition Worksheets")
                {
                    ApplicationArea = Planning;
                    Caption = 'Requisition Worksheets';
                    RunObject = Page "Req. Worksheet";
                }
                action("Recurring Req. Worksheet")
                {
                    ApplicationArea = Planning;
                    Caption = 'Recurring Requisition Worksheets';
                    RunObject = Page "Recurring Req. Worksheet";
                }
                action("Order Planning")
                {
                    ApplicationArea = Planning;
                    Caption = 'Order Planning';
                    RunObject = Page "Order Planning";
                }
                group("Group5")
                {
                    Caption = 'Reports';
                    action("Purchase Reservation Avail.")
                    {
                        ApplicationArea = Reservation;
                        Caption = 'Purchase Reservation Avail.';
                        RunObject = Report "Purchase Reservation Avail.";
                    }
                    action("Nonstock Item Sales")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Nonstock Item Sales';
                        RunObject = Report "Catalog Item Sales";
                    }
                    action("Item/Vendor Catalog1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item/Vendor Catalog';
                        RunObject = Report "Item/Vendor Catalog";
                    }
                    action("Prod. Order - Shortage List")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Prod. Order - Shortage List';
                        RunObject = Report "Prod. Order - Shortage List";
                    }
                    action("Prod. Order - Mat. Requisition")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Prod. Order - Mat. Requisition';
                        RunObject = Report "Prod. Order - Mat. Requisition";
                    }
                    action("Purchase Statistics")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Purchase Statistics';
                        RunObject = Report "Purchase Statistics";
                    }
                    action("Item Substitutions1")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Item Substitutions';
                        RunObject = Report "Item Substitutions";
                    }
                    group("Group6")
                    {
                        Caption = 'Vendor';
                        action("Vendor - Balance to Date")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Vendor - Balance to Date';
                            RunObject = Report "Vendor - Balance to Date";
                        }
                        action("Vendor/Item Purchases1")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Vendor/Item Purchases';
                            RunObject = Report "Vendor/Item Purchases";
                        }
                        action("Vendor - Purchase List")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Vendor - Purchase List';
                            RunObject = Report "Vendor - Purchase List";
                        }
                        action("Vendor - Trial Balance")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Vendor - Trial Balance';
                            RunObject = Report "Vendor - Trial Balance";
                        }
                        action("Vendor - Detail Trial Balance")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Vendor - Detail Trial Balance';
                            RunObject = Report "Vendor - Detail Trial Balance";
                        }
                        action("Vendor - Top 10 List")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Vendor - Top 10 List';
                            RunObject = Report "Vendor - Top 10 List";
                        }
                        action("Vendor - List")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Vendor - List';
                            RunObject = Report "Vendor - List";
                        }
                        action("Vendor - Summary Aging")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Vendor - Summary Aging';
                            RunObject = Report "Vendor - Summary Aging";
                        }
                        action("Vendor Item Catalog")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Vendor Item Catalog';
                            RunObject = Report "Vendor Item Catalog";
                        }
                    }
                    group("Group7")
                    {
                        Caption = 'Inventory';
                        action("Inventory - Cost Variance")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Inventory - Cost Variance';
                            RunObject = Report "Inventory - Cost Variance";
                        }
                        action("Inventory - Vendor Purchases1")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Inventory - Vendor Purchases';
                            RunObject = Report "Inventory - Vendor Purchases";
                        }
                        action("Inventory - Availability Plan")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Inventory - Availability Plan';
                            RunObject = Report "Inventory - Availability Plan";
                        }
                        action("Inventory Purchase Orders1")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Inventory Purchase Orders';
                            RunObject = Report "Inventory Purchase Orders";
                        }
                        action("Inventory - List1")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Inventory - List';
                            RunObject = Report "Inventory - List";
                        }
                        action("Inventory - Inbound Transfer")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Inventory - Inbound Transfer';
                            RunObject = Report "Inventory - Inbound Transfer";
                        }
                        action("Inventory Cost and Price List1")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Inventory Cost and Price List';
                            RunObject = Report "Inventory Cost and Price List";
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
                    RunObject = Page "Item List";
                }
                action("Nonstock Items")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Nonstock Items';
                    RunObject = Page "Catalog Item List";
                }
                action("Stock keeping Units")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Stockkeeping Units';
                    RunObject = Page "Stockkeeping Unit List";
                }
                action("Adjust Cost - Item Entries...")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Adjust Cost Item Entries';
                    RunObject = Report "Adjust Cost - Item Entries";
                }
                action("Standard Costs Worksheet")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Standard Costs Worksheet';
                    RunObject = Page "Standard Cost Worksheet";
                }
                action("Adjust Item Costs/Prices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Adjust Item Costs/Prices';
                    RunObject = Report "Adjust Item Costs/Prices";
                }
                group("Group9")
                {
                    Caption = 'Journals';
                    action("Item Journal")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Journals';
                        RunObject = Page "Item Journal";
                    }
                    action("Item Reclass. Journals")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Reclassification Journals';
                        RunObject = Page "Item Reclass. Journal";
                    }
                    action("Recurring Item Journals")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Recurring Item Journals';
                        RunObject = Page "Recurring Item Jnl.";
                    }
                }
                group("Group10")
                {
                    Caption = 'Reports';
                    action("Inventory - List2")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory - List';
                        RunObject = Report "Inventory - List";
                    }
                    action("Item Age Composition - Qty.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Age Composition - Qty.';
                        RunObject = Report "Item Age Composition - Qty.";
                    }
                    action("Inventory - Cost Variance1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory - Cost Variance';
                        RunObject = Report "Inventory - Cost Variance";
                    }
                    action("Item Charges - Specification1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Charges - Specification';
                        RunObject = Report "Item Charges - Specification";
                    }
                    action("Inventory - Inbound Transfer1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory - Inbound Transfer';
                        RunObject = Report "Inventory - Inbound Transfer";
                    }
                    action("Invt. Valuation - Cost Spec.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Invt. Valuation - Cost Spec.';
                        RunObject = Report "Invt. Valuation - Cost Spec.";
                    }
                    action("Item Age Composition - Value")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Age Composition - Value';
                        RunObject = Report "Item Age Composition - Value";
                    }
                    action("Inventory Availability1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory Availability';
                        RunObject = Report "Inventory Availability";
                    }
                    action("Item Register - Quantity")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Register - Quantity';
                        RunObject = Report "Item Register - Quantity";
                    }
                    action("Item Register - Value")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Register - Value';
                        RunObject = Report "Item Register - Value";
                    }
                    action("Item Expiration - Quantity")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Item Expiration - Quantity';
                        RunObject = Report "Item Expiration - Quantity";
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
                    RunObject = Page "Purchases & Payables Setup";
                }
                action("Standard Purchase Codes")
                {
                    ApplicationArea = Suite;
                    Caption = 'Standard Purchase Codes';
                    RunObject = Page "Standard Purchase Codes";
                }
                action("Purchasing Codes")
                {
                    ApplicationArea = Suite;
                    Caption = 'Purchasing Codes';
                    RunObject = Page "Purchasing Codes";
                }
                action("Shipment Methods")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Shipment Methods';
                    RunObject = Page "Shipment Methods";
                }
                action("Return Reasons")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Return Reasons';
                    RunObject = Page "Return Reasons";
                }
                action("Report Selection Purchase")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Report Selections Purchase';
                    RunObject = Page "Report Selection - Purchase";
                }
                action("Req. Worksheet")
                {
                    ApplicationArea = Planning;
                    Caption = 'Requisition Worksheet Templates';
                    RunObject = Page "Req. Worksheet Templates";
                }
                action("Units of Measure")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Units of Measure';
                    RunObject = Page "Units of Measure";
                }
                action("Manufacturers")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Manufacturers';
                    RunObject = Page "Manufacturers";
                }
                action("Nonstock Item Setup")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Nonstock Item Setup';
                    RunObject = Page "Catalog Item Setup";
                }
                action("Item Journal Templates")
                {
                    Caption = 'Item Journal Templates';
                    RunObject = Page "Item Journal Templates";
                }
                action("Salespeople")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Salespeople/Purchasers';
                    RunObject = Page "Salespersons/Purchasers";
                }
                action("Item Disc. Groups")
                {
                    Caption = 'Item Discount Groups';
                    RunObject = Page "Item Disc. Groups";
                }
                action("Item Tracking Codes")
                {
                    Caption = 'Item Tracking Codes';
                    RunObject = Page "Item Tracking Codes";
                }
                action("Inventory Setup")
                {
                    Caption = 'Inventory Setup';
                    RunObject = Page "Inventory Setup";
                }
                action("Requisition Worksheets1")
                {
                    ApplicationArea = Planning;
                    Caption = 'Requisition Worksheets';
                    RunObject = Page "Req. Worksheet";
                }
                group("Group12")
                {
                    Caption = 'Purchase Analysis';
                    action("Analysis Types")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Analysis Types';
                        RunObject = Page "Analysis Types";
                    }
                    action("Analysis by Dimensions1")
                    {
                        ApplicationArea = Dimensions, PurchaseAnalysis;
                        Caption = 'Purchase Analysis by Dimensions';
                        RunObject = Page "Analysis View List Purchase";
                    }
                    action("Analysis Column Templates")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Purch. Analysis Column Templates';
                        RunObject = Report "Run Purch. Analysis Col. Temp.";
                    }
                    action("Analysis Line Templates")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Purch. Analysis Line Templates';
                        RunObject = Report "Run Purch. Analysis Line Temp.";
                    }
                }
            }
        }
    }
}