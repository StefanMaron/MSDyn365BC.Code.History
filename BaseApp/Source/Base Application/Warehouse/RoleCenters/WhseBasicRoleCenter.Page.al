﻿namespace Microsoft.Warehouse.RoleCenters;

using Microsoft.Assembly.Document;
using Microsoft.Assembly.History;
using Microsoft.EServices.EDocument;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.Shipping;
using Microsoft.Inventory.Counting.Document;
using Microsoft.Inventory.Counting.History;
using Microsoft.Inventory.Counting.Recording;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Reports;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Purchases.Archive;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.RoleCenters;
using Microsoft.Sales.Analysis;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Reports;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Activity.History;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.InternalDocument;
using Microsoft.Warehouse.InventoryDocument;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Reports;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Worksheet;
using System.Automation;
using System.Email;
using System.Integration.PowerBI;
using System.Threading;
using System.Visualization;
using Microsoft.Foundation.Task;

page 9008 "Whse. Basic Role Center"
{
    Caption = 'Inventory Manager';
    PageType = RoleCenter;

    layout
    {
        area(rolecenter)
        {
            part(Control51; "Headline RC Whse. Basic")
            {
                ApplicationArea = Warehouse;
            }
            part(Control1906245608; "Whse Ship & Receive Activities")
            {
                ApplicationArea = Warehouse;
            }
            part("WMS Ship and Receive Activities"; "WMS Ship & Receive Activities")
            {
                ApplicationArea = Warehouse;
            }
            part("User Tasks Activities"; "User Tasks Activities")
            {
                ApplicationArea = Suite;
            }
            part("Emails"; "Email Activities")
            {
                ApplicationArea = Basic, Suite;
            }
            part(ApprovalsActivities; "Approvals Activities")
            {
                ApplicationArea = Suite;
            }
            part(Control52; "Team Member Activities No Msgs")
            {
                ApplicationArea = Suite;
            }
            part(Control1907692008; "My Customers")
            {
                ApplicationArea = Warehouse;
            }
            part(Control4; "Trailing Sales Orders Chart")
            {
                ApplicationArea = Warehouse;
                Visible = false;
            }
            part(PowerBIEmbeddedReportPart; "Power BI Embedded Report Part")
            {
                AccessByPermission = TableData "Power BI Context Settings" = I;
                ApplicationArea = Basic, Suite;
            }
            part(Control18; "My Job Queue")
            {
                ApplicationArea = Warehouse;
                Visible = false;
            }
            part(Control19; "Report Inbox Part")
            {
                ApplicationArea = Warehouse;
            }
            systempart(Control1901377608; MyNotes)
            {
                ApplicationArea = Warehouse;
            }
        }
    }

    actions
    {
        area(reporting)
        {
            action("Warehouse &Bin List")
            {
                ApplicationArea = Warehouse;
                Caption = 'Warehouse &Bin List';
                Image = "Report";
                RunObject = Report "Warehouse Bin List";
                ToolTip = 'Get an overview of warehouse bins, their setup, and the quantity of items within the bins.';
            }
            action("Physical &Inventory List")
            {
                ApplicationArea = Warehouse;
                Caption = 'Physical &Inventory List';
                Image = "Report";
                RunObject = Report "Phys. Inventory List";
                ToolTip = 'View a physical list of the lines that you have calculated in the Phys. Inventory Journal window. You can use this report during the physical inventory count to mark down actual quantities on hand in the warehouse and compare them to what is recorded in the program.';
            }
            action("Customer &Labels")
            {
                ApplicationArea = Warehouse;
                Caption = 'Customer &Labels';
                Image = "Report";
                RunObject = Report "Customer - Labels";
                ToolTip = 'View, save, or print mailing labels with the customers'' names and addresses. The report can be used to send sales letters, for example.';
            }
            separator(Action1130001)
            {
            }
            action("Subcontract. Transfer Shipment")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Subcontract. Transfer Shipment';
                Image = "Report";
                RunObject = Report "Subcontract. Transfer Shipment";
                ToolTip = 'Create a subcontracting transfer shipment.';
            }
        }
        area(embedding)
        {
            action(TransferOrders)
            {
                ApplicationArea = Warehouse;
                Caption = 'Transfer Orders';
                Image = Document;
                RunObject = Page "Transfer Orders";
                ToolTip = 'Move inventory items between company locations. With transfer orders, you ship the outbound transfer from one location and receive the inbound transfer at the other location. This allows you to manage the involved warehouse activities and provides more certainty that inventory quantities are updated correctly.';
            }
            action("Subcontracting Transfers")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Subcontracting Transfers';
                RunObject = Page "Subcontracting Transfer List";
                ToolTip = 'View the list of subcontracting transfers.';
            }
            action(ReleasedProductionOrders)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Released Production Orders';
                RunObject = Page "Released Production Orders";
                ToolTip = 'View the list of released production order that are ready for warehouse activities.';
            }
            action(AssemblyOrders)
            {
                ApplicationArea = Assembly;
                Caption = 'Assembly Orders';
                RunObject = Page "Assembly Orders";
                ToolTip = 'View ongoing assembly orders.';
            }
            action(InventoryPicks)
            {
                ApplicationArea = Warehouse;
                Caption = 'Inventory Picks';
                RunObject = Page "Inventory Picks";
                ToolTip = 'View ongoing picks of items from bins according to a basic warehouse configuration. ';
            }
            action(InventoryPutaways)
            {
                ApplicationArea = Warehouse;
                Caption = 'Inventory Put-aways';
                RunObject = Page "Inventory Put-aways";
                ToolTip = 'View ongoing put-aways of items to bins according to a basic warehouse configuration. ';
            }
            action(InventoryMovements)
            {
                ApplicationArea = Warehouse;
                Caption = 'Inventory Movements';
                RunObject = Page "Inventory Movements";
                ToolTip = 'View ongoing movements of items between bins according to a basic warehouse configuration. ';
            }
            action("Internal Movements")
            {
                ApplicationArea = Warehouse;
                Caption = 'Internal Movements';
                RunObject = Page "Internal Movement List";
                ToolTip = 'View the list of ongoing movements between bins.';
            }
            action(PhysInventoryOrders)
            {
                ApplicationArea = Warehouse;
                Caption = 'Physical Inventory Orders';
                RunObject = Page "Physical Inventory Orders";
                ToolTip = 'Plan to count inventory by calculating existing quantities and generating the recording documents.';
            }
            action(PhysInventoryRecordings)
            {
                ApplicationArea = Warehouse;
                Caption = 'Physical Inventory Recordings';
                RunObject = Page "Phys. Inventory Recording List";
                ToolTip = 'Prepare to count inventory by creating a recording document to capture the quantities.';
            }
            action(BinContents)
            {
                ApplicationArea = Warehouse;
                Caption = 'Bin Contents';
                Image = BinContent;
                RunObject = Page "Bin Contents List";
                ToolTip = 'View items in the bin if the selected line contains a bin code.';
            }
            action(Items)
            {
                ApplicationArea = Warehouse;
                Caption = 'Items';
                Image = Item;
                RunObject = Page "Item List";
                ToolTip = 'View or edit detailed information for the products that you trade in. The item card can be of type Inventory or Service to specify if the item is a physical unit or a labor time unit. Here you also define if items in inventory or on incoming orders are automatically reserved for outbound documents and whether order tracking links are created between demand and supply to reflect planning actions.';
            }
            action(ShippingAgents)
            {
                ApplicationArea = Warehouse;
                Caption = 'Shipping Agents';
                RunObject = Page "Shipping Agents";
                ToolTip = 'View the list of shipping companies that you use to transport goods.';
            }
            action(ItemReclassificationJournals)
            {
                ApplicationArea = Warehouse;
                Caption = 'Item Reclassification Journals';
                RunObject = Page "Item Journal Batches";
                RunPageView = where("Template Type" = const(Transfer),
                                    Recurring = const(false));
                ToolTip = 'Change information recorded on item ledger entries. Typical inventory information to reclassify includes dimensions and sales campaign codes, but you can also perform basic inventory transfers by reclassifying location and bin codes. Serial or lot numbers and their expiration dates must be reclassified with the Item Tracking Reclassification journal.';
            }
            action(PhysInventoryJournals)
            {
                ApplicationArea = Warehouse;
                Caption = 'Phys. Inventory Journals';
                RunObject = Page "Item Journal Batches";
                RunPageView = where("Template Type" = const("Phys. Inventory"),
                                    Recurring = const(false));
                ToolTip = 'Prepare to count the actual items in inventory to check if the quantity registered in the system is the same as the physical quantity. If there are differences, post them to the item ledger with the physical inventory journal before you do the inventory valuation.';
            }
        }
        area(sections)
        {
            group("Sales & Purchases")
            {
                Caption = 'Sales & Purchases';
                action(Customers)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Customers';
                    Image = Customer;
                    RunObject = Page "Customer List";
                    ToolTip = 'View or edit detailed information for the customers that you trade with. From each customer card, you can open related information, such as sales statistics and ongoing orders, and you can define special prices and line discounts that you grant if certain conditions are met.';
                }
                action(SalesOrders)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Sales Orders';
                    Image = "Order";
                    RunObject = Page "Sales Order List";
                    ToolTip = 'Record your agreements with customers to sell certain products on certain delivery and payment terms. Sales orders, unlike sales invoices, allow you to ship partially, deliver directly from your vendor to your customer, initiate warehouse handling, and print various customer-facing documents. Sales invoicing is integrated in the sales order process.';
                }
                action(SalesOrdersReleased)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Released';
                    RunObject = Page "Sales Order List";
                    RunPageView = where(Status = filter(Released));
                    ToolTip = 'View the list of released source documents that are ready for warehouse activities.';
                }
                action(SalesOrdersPartShipped)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Partially Shipped';
                    RunObject = Page "Sales Order List";
                    RunPageView = where(Status = filter(Released),
                                        "Completely Shipped" = filter(false));
                    ToolTip = 'View the list of ongoing warehouse shipments that are partially completed.';
                }
                action(SalesReturnOrders)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Sales Return Orders';
                    Image = ReturnOrder;
                    RunObject = Page "Sales Return Order List";
                    ToolTip = 'Compensate your customers for incorrect or damaged items that you sent to them and received payment for. Sales return orders enable you to receive items from multiple sales documents with one sales return, automatically create related sales credit memos or other return-related documents, such as a replacement sales order, and support warehouse documents for the item handling. Note: If an erroneous sale has not been paid yet, you can simply cancel the posted sales invoice to automatically revert the financial transaction.';
                }
                action(Vendors)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Vendors';
                    Image = Vendor;
                    RunObject = Page "Vendor List";
                    ToolTip = 'View or edit detailed information for the vendors that you trade with. From each vendor card, you can open related information, such as purchase statistics and ongoing orders, and you can define special prices and line discounts that the vendor grants you if certain conditions are met.';
                }
                action(PurchaseOrders)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Purchase Orders';
                    RunObject = Page "Purchase Order List";
                    ToolTip = 'Create purchase orders to mirror sales documents that vendors send to you. This enables you to record the cost of purchases and to track accounts payable. Posting purchase orders dynamically updates inventory levels so that you can minimize inventory costs and provide better customer service. Purchase orders allow partial receipts, unlike with purchase invoices, and enable drop shipment directly from your vendor to your customer. Purchase orders can be created automatically from PDF or image files from your vendors by using the Incoming Documents feature.';
                }
                action(PurchaseOrdersReleased)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Released';
                    RunObject = Page "Purchase Order List";
                    RunPageView = where(Status = filter(Released));
                    ToolTip = 'View the list of released source documents that are ready for warehouse activities.';
                }
                action(PurchaseOrdersPartReceived)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Partially Received';
                    RunObject = Page "Purchase Order List";
                    RunPageView = where(Status = filter(Released),
                                        "Completely Received" = filter(false));
                    ToolTip = 'View the list of ongoing warehouse receipts that are partially completed.';
                }
                action(PurchaseReturnOrders)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Purchase Return Orders';
                    RunObject = Page "Purchase Return Order List";
                    RunPageView = where("Document Type" = filter("Return Order"));
                    ToolTip = 'Create purchase return orders to mirror sales return documents that vendors send to you for incorrect or damaged items that you have paid for and then returned to the vendor. Purchase return orders enable you to ship back items from multiple purchase documents with one purchase return and support warehouse documents for the item handling. Purchase return orders can be created automatically from PDF or image files from your vendors by using the Incoming Documents feature. Note: If you have not yet paid for an erroneous purchase, you can simply cancel the posted purchase invoice to automatically revert the financial transaction.';
                }
            }
            group("Reference Data")
            {
                Caption = 'Reference Data';
                Image = ReferenceData;
                action(Items02)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Items';
                    Image = Item;
                    RunObject = Page "Item List";
                    ToolTip = 'View or edit detailed information for the products that you trade in. The item card can be of type Inventory or Service to specify if the item is a physical unit or a labor time unit. Here you also define if items in inventory or on incoming orders are automatically reserved for outbound documents and whether order tracking links are created between demand and supply to reflect planning actions.';
                }
                action(Locations)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Locations';
                    Image = Warehouse;
                    RunObject = Page "Location List";
                    ToolTip = 'View the list of warehouse locations.';
                }
                action("Shipping Agents02")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Shipping Agent';
                    RunObject = Page "Shipping Agents";
                    ToolTip = 'View the list of shipping companies that you use to transport goods.';
                }
                action("Catalog Items")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Catalog Items';
                    Image = NonStockItem;
                    RunObject = Page "Catalog Item List";
                    ToolTip = 'View the list of items that you do not carry in inventory. ';
                }
                action("Stockkeeping Units")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Stockkeeping Units';
                    Image = SKU;
                    RunObject = Page "Stockkeeping Unit List";
                    ToolTip = 'Open the list of item SKUs to view or edit instances of item at different locations or with different variants. ';
                }
                action(BinContents02)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Bin Contents';
                    Image = BinContent;
                    RunObject = Page "Bin Contents List";
                    ToolTip = 'View items in the bin if the selected line contains a bin code.';
                }
            }
            group(Journals)
            {
                Caption = 'Journals';
                Image = Journals;
                action(WhseItemJournals)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Warehouse Item Journals';
                    RunObject = Page "Whse. Journal Batches List";
                    RunPageView = where("Template Type" = const(Item));
                    ToolTip = 'Adjust the quantity of an item in a particular bin or bins. For instance, you might find some items in a bin that are not registered in the system, or you might not be able to pick the quantity needed because there are fewer items in a bin than was calculated by the program. The bin is then updated to correspond to the actual quantity in the bin. In addition, it creates a balancing quantity in the adjustment bin, for synchronization with item ledger entries, which you can then post with an item journal.';
                }
                action(WhseReclassJournals)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Warehouse Reclassification Journals';
                    RunObject = Page "Whse. Journal Batches List";
                    RunPageView = where("Template Type" = const(Reclassification));
                    ToolTip = 'Change information on warehouse entries, such as zone codes and bin codes.';
                }
                action(WhsePhysInvtJournals)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Warehouse Physical Inventory Journals';
                    RunObject = Page "Whse. Journal Batches List";
                    RunPageView = where("Template Type" = const("Physical Inventory"));
                    ToolTip = 'Prepare to count inventories by preparing the documents that warehouse employees use when they perform a physical inventory of selected items or of all the inventory. When the physical count has been made, you enter the number of items that are in the bins in this window, and then you register the physical inventory.';
                }
                action(ItemJournals)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Item Journals';
                    RunObject = Page "Item Journal Batches";
                    RunPageView = where("Template Type" = const(Item),
                                        Recurring = const(false));
                    ToolTip = 'Post item transactions directly to the item ledger to adjust inventory in connection with purchases, sales, and positive or negative adjustments without using documents. You can save sets of item journal lines as standard journals so that you can perform recurring postings quickly. A condensed version of the item journal function exists on item cards for quick adjustment of an items inventory quantity.';
                }
                action(ItemReclassificationJournals02)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Item Reclassification Journals';
                    RunObject = Page "Item Journal Batches";
                    RunPageView = where("Template Type" = const(Transfer),
                                        Recurring = const(false));
                    ToolTip = 'Change information recorded on item ledger entries. Typical inventory information to reclassify includes dimensions and sales campaign codes, but you can also perform basic inventory transfers by reclassifying location and bin codes. Serial or lot numbers and their expiration dates must be reclassified with the Item Tracking Reclassification journal.';
                }
                action(PhysInventoryJournals02)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Phys. Inventory Journals';
                    RunObject = Page "Item Journal Batches";
                    RunPageView = where("Template Type" = const("Phys. Inventory"),
                                        Recurring = const(false));
                    ToolTip = 'Prepare to count the actual items in inventory to check if the quantity registered in the system is the same as the physical quantity. If there are differences, post them to the item ledger with the physical inventory journal before you do the inventory valuation.';
                }
            }
            group(Worksheet)
            {
                Caption = 'Worksheet';
                Image = Worksheets;
                action(PutawayWorksheets)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Put-away Worksheets';
                    RunObject = Page "Worksheet Names List";
                    RunPageView = where("Template Type" = const("Put-away"));
                    ToolTip = 'Plan and initialize item put-aways.';
                }
                action(PickWorksheets)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Pick Worksheets';
                    RunObject = Page "Worksheet Names List";
                    RunPageView = where("Template Type" = const(Pick));
                    ToolTip = 'Plan and initialize picks of items. ';
                }
                action(MovementWorksheets)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Movement Worksheets';
                    RunObject = Page "Worksheet Names List";
                    RunPageView = where("Template Type" = const(Movement));
                    ToolTip = 'Plan and initiate movements of items between bins according to an advanced warehouse configuration.';
                }
                action("Internal Put-aways")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Internal Put-aways';
                    RunObject = Page "Whse. Internal Put-away List";
                    ToolTip = 'View the list of ongoing put-aways for internal activities, such as production.';
                }
                action("Internal Picks")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Internal Picks';
                    RunObject = Page "Whse. Internal Pick List";
                    ToolTip = 'View the list of ongoing picks for internal activities, such as production.';
                }
            }
            group("Posted Documents")
            {
                Caption = 'Posted Documents';
                Image = FiledPosted;
                action("Posted Invt. Picks")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Posted Invt. Picks';
                    RunObject = Page "Posted Invt. Pick List";
                    ToolTip = 'View the list of completed inventory picks. ';
                }
                action("Posted Sales Shipment")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Posted Sales Shipment';
                    RunObject = Page "Posted Sales Shipments";
                    ToolTip = 'Open the list of posted sales shipments.';
                }
                action("Posted Transfer Shipments")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Posted Transfer Shipments';
                    RunObject = Page "Posted Transfer Shipments";
                    ToolTip = 'Open the list of posted transfer shipments.';
                }
                action("Posted Return Shipments")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Posted Return Shipments';
                    RunObject = Page "Posted Return Shipments";
                    ToolTip = 'Open the list of posted return shipments.';
                }
                action("Posted Invt. Put-aways")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Posted Invt. Put-aways';
                    RunObject = Page "Posted Invt. Put-away List";
                    ToolTip = 'View the list of completed inventory put-aways. ';
                }
                action("Registered Invt. Movements")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Registered Invt. Movements';
                    RunObject = Page "Registered Invt. Movement List";
                    ToolTip = 'View the list of completed inventory movements.';
                }
                action("Posted Transfer Receipts")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Posted Transfer Receipts';
                    RunObject = Page "Posted Transfer Receipts";
                    ToolTip = 'Open the list of posted transfer receipts.';
                }
                action("Posted Purchase Receipts")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Posted Purchase Receipts';
                    RunObject = Page "Posted Purchase Receipts";
                    ToolTip = 'Open the list of posted purchase receipts.';
                }
                action("Posted Return Receipts")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Posted Return Receipts';
                    Image = PostedReturnReceipt;
                    RunObject = Page "Posted Return Receipts";
                    ToolTip = 'Open the list of posted return receipts.';
                }
                action("Posted Phys. Invt. Orders")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Posted Phys. Invt. Orders';
                    RunObject = Page "Posted Phys. Invt. Order List";
                    ToolTip = 'View the list of posted inventory counts.';
                }
                action("Posted Phys. Invt. Recordings")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Posted Phys. Invt. Recordings';
                    RunObject = Page "Posted Phys. Invt. Rec. List";
                    ToolTip = 'View the list of finished inventory counts, ready for posting.';
                }
                action("Posted Assembly Orders")
                {
                    ApplicationArea = Assembly;
                    Caption = 'Posted Assembly Orders';
                    RunObject = Page "Posted Assembly Orders";
                    ToolTip = 'View completed assembly orders.';
                }
                action("Posted Whse Shipments")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Posted Whse Shipments';
                    RunObject = Page "Posted Whse. Shipment List";
                    ToolTip = 'Open the list of posted warehouse shipments.';
                }
                action("Posted Whse Receipts")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Posted Whse Receipts';
                    RunObject = Page "Posted Whse. Receipt List";
                    ToolTip = 'Open the list of posted warehouse receipts.';
                }
                action("Registered Picks")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Registered Picks';
                    Image = RegisteredDocs;
                    RunObject = Page "Registered Whse. Picks";
                    ToolTip = 'View warehouse picks that have been performed.';
                }
                action("Registered Put-aways")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Registered Put-aways';
                    Image = RegisteredDocs;
                    RunObject = Page "Registered Whse. Put-aways";
                    ToolTip = 'View the list of completed put-away activities.';
                }
                action("Registered Movements")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Registered Movements';
                    Image = RegisteredDocs;
                    RunObject = Page "Registered Whse. Movements";
                    ToolTip = 'View the list of completed warehouse movements.';
                }
                action("Purchase Quote Archives")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Purchase Quote Archives';
                    RunObject = page "Purchase Quote Archives";
                }
                action("Purchase Order Archives")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Purchase Order Archives';
                    RunObject = page "Purchase Order Archives";
                }
                action("Purchase Return Order Archives")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Purchase Return Order Archives';
                    RunObject = page "Purchase Return List Archive";
                }
                action("Blanket Purchase Order Archives")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Blanket Purchase Order Archives';
                    RunObject = page "Blanket Purch. Order Archives";
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
        }
        area(creation)
        {
            action("T&ransfer Order")
            {
                ApplicationArea = Warehouse;
                Caption = 'T&ransfer Order';
                Image = Document;
                RunObject = Page "Transfer Order";
                RunPageMode = Create;
                ToolTip = 'Move items from one warehouse location to another.';
            }
            action("&Purchase Order")
            {
                ApplicationArea = Warehouse;
                Caption = '&Purchase Order';
                Image = Document;
                RunObject = Page "Purchase Order";
                RunPageMode = Create;
                ToolTip = 'Purchase goods or services from a vendor.';
            }
            action("Phys. Inv. Order")
            {
                ApplicationArea = Warehouse;
                Caption = 'Phys. Inv. Order';
                RunObject = Page "Physical Inventory Order";
                ToolTip = 'Plan to count inventory by calculating existing quantities and generating the recording documents.';
            }
            action("Phys. Inv. Recording")
            {
                ApplicationArea = Warehouse;
                Caption = 'Phys. Inv. Recording';
                RunObject = Page "Phys. Inventory Recording";
                ToolTip = 'Prepare to count inventory by creating a recording document to capture the quantities.';
            }
            action("Inventory Pi&ck")
            {
                ApplicationArea = Warehouse;
                Caption = 'Inventory Pi&ck';
                Image = CreateInventoryPickup;
                RunObject = Page "Inventory Pick";
                RunPageMode = Create;
                ToolTip = 'Create a pick according to a basic warehouse configuration, for example to pick components for a sales order. ';
            }
            action("Inventory P&ut-away")
            {
                ApplicationArea = Warehouse;
                Caption = 'Inventory P&ut-away';
                Image = CreatePutAway;
                RunObject = Page "Inventory Put-away";
                RunPageMode = Create;
                ToolTip = 'Create a put-away according to a basic warehouse configuration, for example to put a produced item away. ';
            }
            action("Whse. &Shipment")
            {
                ApplicationArea = Warehouse;
                Caption = 'Whse. &Shipment';
                Image = Shipment;
                RunObject = Page "Warehouse Shipment";
                RunPageMode = Create;
                ToolTip = 'Create a new warehouse shipment.';
            }
            action("&Whse. Receipt")
            {
                ApplicationArea = Warehouse;
                Caption = '&Whse. Receipt';
                Image = Receipt;
                RunObject = Page "Warehouse Receipt";
                RunPageMode = Create;
                ToolTip = 'Record the receipt of items according to an advanced warehouse configuration. ';
            }
        }
        area(processing)
        {
            action("Edit Item Reclassification &Journal")
            {
                ApplicationArea = Warehouse;
                Caption = 'Edit Item Reclassification &Journal';
                Image = OpenWorksheet;
                RunObject = Page "Item Reclass. Journal";
                ToolTip = 'Change data for an item, such as its location, dimension, or lot number.';
            }
            action("Item &Tracing")
            {
                ApplicationArea = Warehouse;
                Caption = 'Item &Tracing';
                Image = ItemTracing;
                RunObject = Page "Item Tracing";
                ToolTip = 'Trace where a lot or serial number assigned to the item was used, for example, to find which lot a defective component came from or to find all the customers that have received items containing the defective component.';
            }
            action("P&ut-away Worksheet")
            {
                ApplicationArea = Warehouse;
                Caption = 'P&ut-away Worksheet';
                Image = PutAwayWorksheet;
                RunObject = Page "Put-away Worksheet";
                ToolTip = 'Prepare and initialize item put-aways.';
            }
            action("Pi&ck Worksheet")
            {
                ApplicationArea = Warehouse;
                Caption = 'Pi&ck Worksheet';
                Image = PickWorksheet;
                RunObject = Page "Pick Worksheet";
                ToolTip = 'Plan and initialize picks of items. ';
            }
            action("M&ovement Worksheet")
            {
                ApplicationArea = Warehouse;
                Caption = 'M&ovement Worksheet';
                Image = MovementWorksheet;
                RunObject = Page "Movement Worksheet";
                ToolTip = 'Prepare to move items between bins within the warehouse.';
            }
            action("Order Plan&ning")
            {
                ApplicationArea = Planning;
                Caption = 'Order Plan&ning';
                Image = Planning;
                RunObject = Page "Order Planning";
                ToolTip = 'Plan supply orders order by order to fulfill new demand.';
            }
            action("Requisition &Worksheet")
            {
                ApplicationArea = Planning;
                Caption = 'Requisition &Worksheet';
                Image = Worksheet;
                RunObject = Page "Req. Wksh. Names";
                RunPageView = where("Template Type" = const("Req."),
                                    Recurring = const(false));
                ToolTip = 'Calculate a supply plan to fulfill item demand with purchases or transfers.';
            }
            action(PlanningWorksheets)
            {
                ApplicationArea = Planning;
                Caption = 'Planning Worksheets';
                RunObject = Page "Req. Wksh. Names";
                RunPageView = where("Template Type" = const(Planning),
                                        Recurring = const(false));
                ToolTip = 'Plan supply orders automatically to fulfill new demand.';
            }
        }
    }
}

