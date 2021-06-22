page 9008 "Whse. Basic Role Center"
{
    Caption = 'Shipping and Receiving - Order-by-Order', Comment = '{Dependency=Match,"ProfileDescription_SHIPPINGANDRECEIVING"}';
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
            part(Control1907692008; "My Customers")
            {
                ApplicationArea = Warehouse;
            }
            part(Control52; "Team Member Activities No Msgs")
            {
                ApplicationArea = Suite;
            }
            part(Control4; "Trailing Sales Orders Chart")
            {
                ApplicationArea = Warehouse;
                Visible = false;
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
                RunPageView = WHERE("Template Type" = CONST(Transfer),
                                    Recurring = CONST(false));
                ToolTip = 'Change information recorded on item ledger entries. Typical inventory information to reclassify includes dimensions and sales campaign codes, but you can also perform basic inventory transfers by reclassifying location and bin codes. Serial or lot numbers and their expiration dates must be reclassified with the Item Tracking Reclassification journal.';
            }
            action(PhysInventoryJournals)
            {
                ApplicationArea = Warehouse;
                Caption = 'Phys. Inventory Journals';
                RunObject = Page "Item Journal Batches";
                RunPageView = WHERE("Template Type" = CONST("Phys. Inventory"),
                                    Recurring = CONST(false));
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
                    RunPageView = WHERE(Status = FILTER(Released));
                    ToolTip = 'View the list of released source documents that are ready for warehouse activities.';
                }
                action(SalesOrdersPartShipped)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Partially Shipped';
                    RunObject = Page "Sales Order List";
                    RunPageView = WHERE(Status = FILTER(Released),
                                        "Completely Shipped" = FILTER(false));
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
                    RunPageView = WHERE(Status = FILTER(Released));
                    ToolTip = 'View the list of released source documents that are ready for warehouse activities.';
                }
                action(PurchaseOrdersPartReceived)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Partially Received';
                    RunObject = Page "Purchase Order List";
                    RunPageView = WHERE(Status = FILTER(Released),
                                        "Completely Received" = FILTER(false));
                    ToolTip = 'View the list of ongoing warehouse receipts that are partially completed.';
                }
                action(PurchaseReturnOrders)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Purchase Return Orders';
                    RunObject = Page "Purchase Return Order List";
                    RunPageView = WHERE("Document Type" = FILTER("Return Order"));
                    ToolTip = 'Create purchase return orders to mirror sales return documents that vendors send to you for incorrect or damaged items that you have paid for and then returned to the vendor. Purchase return orders enable you to ship back items from multiple purchase documents with one purchase return and support warehouse documents for the item handling. Purchase return orders can be created automatically from PDF or image files from your vendors by using the Incoming Documents feature. Note: If you have not yet paid for an erroneous purchase, you can simply cancel the posted purchase invoice to automatically revert the financial transaction.';
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
                    Promoted = true;
                    PromotedCategory = Process;
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
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Posted Invt. Put-away List";
                    ToolTip = 'View the list of completed inventory put-aways. ';
                }
                action("Registered Invt. Movements")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Registered Invt. Movements';
                    Promoted = true;
                    PromotedCategory = Process;
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
            }
            group(SetupAndExtensions)
            {
                Caption = 'Setup & Extensions';
                Image = Setup;
                ToolTip = 'Overview and change system and application settings, and manage extensions and services';
                action("Assisted Setup")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Assisted Setup';
                    Image = QuestionaireSetup;
                    RunObject = Page "Assisted Setup";
                    ToolTip = 'Set up core functionality such as sales tax, sending documents as email, and approval workflow by running through a few pages that guide you through the information.';
                }
                action("Manual Setup")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Manual Setup';
                    RunObject = Page "Manual Setup";
                    ToolTip = 'Define your company policies for business departments and for general activities by filling setup windows manually.';
                }
                action("Service Connections")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Service Connections';
                    Image = ServiceTasks;
                    RunObject = Page "Service Connections";
                    ToolTip = 'Enable and configure external services, such as exchange rate updates, Microsoft Social Engagement, and electronic bank integration.';
                }
                action(Extensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Extensions';
                    Image = NonStockItemSetup;
                    RunObject = Page "Extension Management";
                    ToolTip = 'Install Extensions for greater functionality of the system.';
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
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = Process;
                RunObject = Page "Transfer Order";
                RunPageMode = Create;
                ToolTip = 'Move items from one warehouse location to another.';
            }
            action("&Purchase Order")
            {
                ApplicationArea = Warehouse;
                Caption = '&Purchase Order';
                Image = Document;
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = Process;
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
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = Process;
                RunObject = Page "Inventory Pick";
                RunPageMode = Create;
                ToolTip = 'Create a pick according to a basic warehouse configuration, for example to pick components for a sales order. ';
            }
            action("Inventory P&ut-away")
            {
                ApplicationArea = Warehouse;
                Caption = 'Inventory P&ut-away';
                Image = CreatePutAway;
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = Process;
                RunObject = Page "Inventory Put-away";
                RunPageMode = Create;
                ToolTip = 'Create a put-away according to a basic warehouse configuration, for example to put a produced item away. ';
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
        }
    }
}

