page 8909 "Warehouse Manager Role Center"
{
    Caption = 'Warehouse Manager Role Center';
    PageType = RoleCenter;
    actions
    {
        area(Sections)
        {
            group("Group")
            {
                Caption = 'Orders & Contacts';
                action("Vendors")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendors';
                    RunObject = page Vendors;
                }
                action("Orders")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Purchase Orders';
                    RunObject = page "Purchase Order List";
                    Tooltip = 'Open the Purchase Orders page.';
                }
                action("Return Orders")
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Purchase Return Orders';
                    RunObject = page "Purchase Return Order List";
                    Tooltip = 'Open the Purchase Return Orders page.';
                }
                action("Customers")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Customers';
                    RunObject = page "Customer List";
                    Tooltip = 'Open the Customers page.';
                }
                action("Orders1")
                {
                    ApplicationArea = Warehouse, Assembly;
                    Caption = 'Sales Orders';
                    RunObject = page "Sales Order List";
                    Tooltip = 'Open the Sales Orders page.';
                }
                action("Return Orders1")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Sales Return Orders';
                    RunObject = page "Sales Return Order List";
                    Tooltip = 'Open the Sales Return Orders page.';
                }
                action("Transfer Orders")
                {
                    ApplicationArea = Location;
                    Caption = 'Transfer Orders';
                    RunObject = page "Transfer Orders";
                    Tooltip = 'Open the Transfer Orders page.';
                }
                action("Assembly Orders")
                {
                    ApplicationArea = Assembly;
                    Caption = 'Assembly Orders';
                    RunObject = page "Assembly Orders";
                    Tooltip = 'Open the Assembly Orders page.';
                }
                action("Released Prod. Orders")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Released Prod. Orders';
                    RunObject = page "Released Production Orders";
                    Tooltip = 'Open the Released Prod. Orders page.';
                }
                action("Orders2")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Orders';
                    RunObject = page "Service Orders";
                    Tooltip = 'Open the Service Orders page.';
                }
                group("Group1")
                {
                    Caption = 'Posted Documents';
                    action("Posted Purchase Invoices")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Purchase Invoices';
                        RunObject = page "Posted Purchase Invoices";
                        Tooltip = 'Open the Posted Purchase Invoices page.';
                    }
                    action("Posted Credit Memos")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Purchase Credit Memos';
                        RunObject = page "Posted Purchase Credit Memos";
                        Tooltip = 'Open the Posted Purchase Credit Memos page.';
                    }
                    action("Posted Invoices")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Sales Invoices';
                        RunObject = page "Posted Sales Invoices";
                        Tooltip = 'Open the Posted Sales Invoices page.';
                    }
                    action("Posted Credit Memos1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Sales Credit Memos';
                        RunObject = page "Posted Sales Credit Memos";
                        Tooltip = 'Open the Posted Sales Credit Memos page.';
                    }
                }
                group("Group2")
                {
                    Caption = 'Reports';
                    action("Return Order Confirmation")
                    {
                        ApplicationArea = SalesReturnOrder, PurchReturnOrder;
                        Caption = 'Return Order Confirmation';
                        RunObject = report "Return Order Confirmation";
                        Tooltip = 'Run the Return Order Confirmation report.';
                    }
                }
            }
            group("Group3")
            {
                Caption = 'Planning & Operations';
                action("Items")
                {
                    ApplicationArea = Warehouse, Assembly;
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
                action("Bin Contents")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Bin Contents';
                    RunObject = page "Bin Contents";
                    Tooltip = 'Open the Bin Contents page.';
                    AccessByPermission = tabledata 7354 = R;
                }
                action("Create Invt. Put-away/Pick")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Create Invt. Put-away/Pick';
                    RunObject = report "Create Invt Put-away/Pick/Mvmt";
                    Tooltip = 'Run the Create Invt. Put-away/Pick report.';
                    AccessByPermission = tabledata 14 = R;
                }
                action("Pick Worksheets")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Pick Worksheets';
                    RunObject = page "Pick Worksheet";
                    Tooltip = 'Open the Pick Worksheets page.';
                }
                action("Put-away Worksheets")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Put-away Worksheets';
                    RunObject = page "Put-away Worksheet";
                    Tooltip = 'Open the Put-away Worksheets page.';
                }
                action("Movement Worksheets")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Movement Worksheets';
                    RunObject = page "Movement Worksheet";
                    Tooltip = 'Open the Movement Worksheets page.';
                }
                action("Internal Movement List")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Internal Movements';
                    RunObject = page "Internal Movement List";
                    Tooltip = 'Open the Internal Movements page.';
                }
                action("Item Reclass. Journals")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item Reclassification Journals';
                    RunObject = page "Item Reclass. Journal";
                    Tooltip = 'Open the Item Reclassification Journals page.';
                }
                action("Item Tracing")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Item Tracing';
                    RunObject = page "Item Tracing";
                    Tooltip = 'Open the Item Tracing page.';
                }
                action("Item Receipts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item Receipts';
                    RunObject = page "Item Receipts";
                    Tooltip = 'Open the Item Receipts page.';
                }
                action("Item Shipments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item Shipments';
                    RunObject = page "Item Shipments";
                    Tooltip = 'Open the Item Shipments page.';
                }
                action("Direct Transfers")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Direct Transfers';
                    RunObject = page "Direct Transfer List";
                    Tooltip = 'Open the Direct Transfers page.';
                }
                group("Group4")
                {
                    Caption = 'Warehouse Documents';
                    action("Transfer Orders1")
                    {
                        ApplicationArea = Location;
                        Caption = 'Transfer Orders';
                        RunObject = page "Transfer Orders";
                        Tooltip = 'Open the Transfer Orders page.';
                    }
                    action("Receipts")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Warehouse Receipts';
                        RunObject = page "Warehouse Receipts";
                        Tooltip = 'Open the Warehouse Receipts page.';
                    }
                    action("Shipments")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Warehouse Shipments';
                        RunObject = page "Warehouse Shipment List";
                        Tooltip = 'Open the Warehouse Shipments page.';
                    }
                    action("Assembly Orders1")
                    {
                        ApplicationArea = Assembly;
                        Caption = 'Assembly Orders';
                        RunObject = page "Assembly Orders";
                        Tooltip = 'Open the Assembly Orders page.';
                    }
                    action("Released Prod. Orders1")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Released Prod. Orders';
                        RunObject = page "Released Production Orders";
                        Tooltip = 'Open the Released Prod. Orders page.';
                    }
                }
                group("Group5")
                {
                    Caption = 'Posted Documents';
                    action("Posted Purchase Receipts")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Purchase Receipts';
                        RunObject = page "Posted Purchase Receipts";
                        Tooltip = 'Open the Posted Purchase Receipts page.';
                    }
                    action("Posted Return Shipments")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Posted Purchase Return Shipments';
                        RunObject = page "Posted Return Shipments";
                        Tooltip = 'Open the Posted Purchase Return Shipments page.';
                    }
                    action("Posted Sales Shipments")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Sales Shipments';
                        RunObject = page "Posted Sales Shipments";
                        Tooltip = 'Open the Posted Sales Shipments page.';
                    }
                    action("Posted Return Receipts")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Posted Return Receipts';
                        RunObject = page "Posted Return Receipts";
                        Tooltip = 'Open the Posted Return Receipts page.';
                    }
                    action("Posted Assembly Orders")
                    {
                        ApplicationArea = Assembly;
                        Caption = 'Posted Assembly Orders';
                        RunObject = page "Posted Assembly Orders";
                        Tooltip = 'Open the Posted Assembly Orders page.';
                    }
                    action("Posted Transfer Receipts")
                    {
                        ApplicationArea = Location;
                        Caption = 'Posted Transfer Receipts';
                        RunObject = page "Posted Transfer Receipts";
                        Tooltip = 'Open the Posted Transfer Receipts page.';
                    }
                    action("Posted Transfer Shipments")
                    {
                        ApplicationArea = Location;
                        Caption = 'Posted Transfer Shipments';
                        RunObject = page "Posted Transfer Shipments";
                        Tooltip = 'Open the Posted Transfer Shipments page.';
                    }
                    action("Posted Receipts")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Posted Whse. Receipts';
                        RunObject = page "Posted Whse. Receipt List";
                        Tooltip = 'Open the Posted Whse. Receipts page.';
                    }
                    action("Posted Shipments")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Posted Whse. Shipments';
                        RunObject = page "Posted Whse. Shipment List";
                        Tooltip = 'Open the Posted Whse. Shipments page.';
                    }
                    action("Posted Invt. Put-away")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Posted Invt. Put-away';
                        RunObject = page "Posted Invt. Put-away List";
                        Tooltip = 'Open the Posted Invt. Put-away page.';
                    }
                    action("Posted Invt. Pick")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Posted Invt. Pick';
                        RunObject = page "Posted Invt. Pick List";
                        Tooltip = 'Open the Posted Invt. Pick page.';
                    }
                    action("Posted Item Receipts")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Item Receipts';
                        RunObject = page "Posted Item Receipts";
                        Tooltip = 'Open the Posted Item Receipts page.';
                    }
                    action("Posted Item Shipments")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Item Shipments';
                        RunObject = page "Posted Item Shipments";
                        Tooltip = 'Open the Posted Item Shipments page.';
                    }
                }
                group("Group6")
                {
                    Caption = 'Registers/Entries';
                    action("Registered Put-aways")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Registered Put-aways';
                        RunObject = page "Registered Whse. Put-aways";
                        Tooltip = 'Open the Registered Put-aways page.';
                    }
                    action("Registered Picks")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Registered Picks';
                        RunObject = page "Registered Whse. Picks";
                        Tooltip = 'Open the Registered Picks page.';
                    }
                    action("Registered Movement")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Registered Movements';
                        RunObject = page "Registered Whse. Movements";
                        Tooltip = 'Open the Registered Movements page.';
                    }
                    action("Registered Invt. Movement")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Registered Invt. Movement';
                        RunObject = page "Registered Invt. Movement List";
                        Tooltip = 'Open the Registered Invt. Movement page.';
                    }
                    action("Registers")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Warehouse Registers';
                        RunObject = page "Warehouse Registers";
                        Tooltip = 'Open the Warehouse Registers page.';
                    }
                    action("Item Registers")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Registers';
                        RunObject = page "Item Registers";
                        Tooltip = 'Open the Item Registers page.';
                    }
                    action("Item Ledger Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Ledger Entries';
                        RunObject = page "Item Ledger Entries";
                        Tooltip = 'Open the Item Ledger Entries page.';
                    }
                    action("Phys. Inventory Ledger Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Physical Inventory Ledger Entries';
                        RunObject = page "Phys. Inventory Ledger Entries";
                        Tooltip = 'Open the Physical Inventory Ledger Entries page.';
                    }
                    action("Value Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Value Entries';
                        RunObject = page "Value Entries";
                        Tooltip = 'Open the Value Entries page.';
                    }
                    action("Warehouse Entries")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Warehouse Entries';
                        RunObject = page "Warehouse Entries";
                        Tooltip = 'Open the Warehouse Entries page.';
                    }
                }
                group("Group7")
                {
                    Caption = 'Reports';
                    action("Whse. Shipment Status")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Whse. Shipment Status';
                        RunObject = report "Whse. Shipment Status";
                        Tooltip = 'Run the Whse. Shipment Status report.';
                    }
                    action("Prod. Order - Mat. Requisition")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Prod. Order - Mat. Requisition';
                        RunObject = report "Prod. Order - Mat. Requisition";
                        Tooltip = 'Run the Prod. Order - Mat. Requisition report.';
                    }
                    action("Prod. Order - Picking List")
                    {
                        ApplicationArea = Manufacturing, Warehouse;
                        Caption = 'Prod. Order Picking List';
                        RunObject = report "Prod. Order - Picking List";
                        Tooltip = 'Run the Prod. Order Picking List report.';
                    }
                    action("Customer - List")
                    {
                        ApplicationArea = Basic, Suite, Warehouse;
                        Caption = 'Customer - List';
                        RunObject = report "Customer - List";
                        Tooltip = 'Run the Customer - List report.';
                    }
                    action("Subcontractor - Dispatch List")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Subcontractor Dispatch List';
                        RunObject = report "Subcontractor - Dispatch List";
                        Tooltip = 'Run the Subcontractor Dispatch List report.';
                    }
                    action("Inventory Picking List")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Inventory Picking List';
                        RunObject = report "Inventory Picking List";
                        Tooltip = 'Run the Inventory Picking List report.';
                        AccessByPermission = tabledata 14 = R;
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
            group("Group8")
            {
                Caption = 'Goods Handling';
                group("Group9")
                {
                    Caption = 'Order by Order';
                    action("Inventory Put-aways")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Inventory Put-aways';
                        RunObject = page "Inventory Put-aways";
                        Tooltip = 'Open the Inventory Put-aways page.';
                    }
                    action("Inventory Picks")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Inventory Picks';
                        RunObject = page "Inventory Picks";
                        Tooltip = 'Open the Inventory Picks page.';
                    }
                    action("Page9330")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Inventory Movements';
                        RunObject = page "Inventory Movements";
                        Tooltip = 'Open the Inventory Movements page.';
                    }
                }
                group("Group10")
                {
                    Caption = 'Multiple Orders';
                    action("Put-aways")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Put-aways';
                        RunObject = page "Warehouse Put-aways";
                        Tooltip = 'Open the Put-aways page.';
                    }
                    action("Picks")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Picks';
                        RunObject = page "Warehouse Picks";
                        Tooltip = 'Open the Picks page.';
                    }
                    action("Movements")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Movements';
                        RunObject = page "Warehouse Movements";
                        Tooltip = 'Open the Movements page.';
                    }
                    action("Internal Picks")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Whse. Internal Picks';
                        RunObject = page "Whse. Internal Pick List";
                        Tooltip = 'Open the Whse. Internal Picks page.';
                    }
                    action("Internal Put-aways")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Whse. Internal Put-aways';
                        RunObject = page "Whse. Internal Put-away List";
                        Tooltip = 'Open the Whse. Internal Put-aways page.';
                    }
                }
                group("Group11")
                {
                    Caption = 'Bins';
                    action("Bin Contents1")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Bin Contents';
                        RunObject = page "Bin Contents";
                        Tooltip = 'Open the Bin Contents page.';
                        AccessByPermission = tabledata 7354 = R;
                    }
                    action("Bin Creation Worksheet")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Bin Creation Worksheet';
                        RunObject = page "Bin Creation Worksheet";
                        Tooltip = 'Open the Bin Creation Worksheet page.';
                        AccessByPermission = tabledata 7354 = R;
                    }
                    action("Bin Content Creation Worksheet")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Bin Content Creation Worksheet';
                        RunObject = page "Bin Content Creation Worksheet";
                        Tooltip = 'Open the Bin Content Creation Worksheet page.';
                        AccessByPermission = tabledata 7354 = R;
                    }
                }
                group("Group12")
                {
                    Caption = 'Journals';
                    action("Whse. Item Journals")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Whse. Item Journals';
                        RunObject = page "Whse. Item Journal";
                        Tooltip = 'Open the Whse. Item Journals page.';
                    }
                    action("Item Reclass. Journals1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Reclassification Journals';
                        RunObject = page "Item Reclass. Journal";
                        Tooltip = 'Open the Item Reclassification Journals page.';
                    }
                    action("Whse. Reclass. Journals")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Whse. Reclass. Journals';
                        RunObject = page "Whse. Reclassification Journal";
                        Tooltip = 'Open the Whse. Reclass. Journals page.';
                    }
                    action("Whse. Phys. Invt. Journals")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Whse. Phys. Invt. Journals';
                        RunObject = page "Whse. Phys. Invt. Journal";
                        Tooltip = 'Open the Whse. Phys. Invt. Journals page.';
                    }
                }
                group("Group13")
                {
                    Caption = 'Reports';
                    action("Whse. Shipment Status1")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Whse. Shipment Status';
                        RunObject = report "Whse. Shipment Status";
                        Tooltip = 'Run the Whse. Shipment Status report.';
                    }
                    action("Customer - List1")
                    {
                        ApplicationArea = Basic, Suite, Warehouse;
                        Caption = 'Customer - List';
                        RunObject = report "Customer - List";
                        Tooltip = 'Run the Customer - List report.';
                    }
                    action("Prod. Order - Picking List1")
                    {
                        ApplicationArea = Manufacturing, Warehouse;
                        Caption = 'Prod. Order Picking List';
                        RunObject = report "Prod. Order - Picking List";
                        Tooltip = 'Run the Prod. Order Picking List report.';
                    }
                    action("Customer - Labels")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Customer Labels';
                        RunObject = report "Customer - Labels";
                        Tooltip = 'Run the Customer Labels report.';
                    }
                    action("Whse. Phys. Inventory List")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Whse. Phys. Inventory List';
                        RunObject = report "Whse. Phys. Inventory List";
                        Tooltip = 'Run the Whse. Phys. Inventory List report.';
                    }
                    action("Warehouse Register - Quantity")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Warehouse Register - Quantity';
                        RunObject = report "Warehouse Register - Quantity";
                        Tooltip = 'Run the Warehouse Register - Quantity report.';
                        AccessByPermission = tabledata 14 = R;
                    }
                    action("Warehouse Bin List")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Warehouse Bin List';
                        RunObject = report "Warehouse Bin List";
                        Tooltip = 'Run the Warehouse Bin List report.';
                    }
                    action("Whse. Adjustment Bin")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Whse. Adjustment Bin';
                        RunObject = report "Whse. Adjustment Bin";
                        Tooltip = 'Run the Whse. Adjustment Bin report.';
                        AccessByPermission = tabledata 7354 = R;
                    }
                    action("Inventory Put-away List")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Inventory Put-away List';
                        RunObject = report "Inventory Put-away List";
                        Tooltip = 'Run the Inventory Put-away List report.';
                        AccessByPermission = tabledata 14 = R;
                    }
                    action("Warehouse Movement")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Warehouse Movement';
                        RunObject = report "Movement List";
                        Tooltip = 'Run the Warehouse Movement report.';
                        AccessByPermission = tabledata 14 = R;
                    }
                    action("Whse. - Posted Receipt")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Whse. Posted Receipt';
                        RunObject = report "Whse. - Posted Receipt";
                        Tooltip = 'Run the Whse. Posted Receipt report.';
                    }
                    action("Whse. - Posted Shipment")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Whse. Posted Shipment';
                        RunObject = report "Whse. - Posted Shipment";
                        Tooltip = 'Run the Whse. Posted Shipment report.';
                    }
                    action("Whse. - Receipt")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Whse. Receipt';
                        RunObject = report "Whse. - Receipt";
                        Tooltip = 'Run the Whse. Receipt report.';
                    }
                    action("Whse. - Shipment")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Whse. Shipment';
                        RunObject = report "Whse. - Shipment";
                        Tooltip = 'Run the Whse. Shipment report.';
                    }
                }
            }
            group("Group14")
            {
                Caption = 'Inventory';
                action("Phys. Invt. Counting Periods")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Physical Inventory Counting Periods';
                    RunObject = page "Phys. Invt. Counting Periods";
                    Tooltip = 'Open the Physical Invtory Counting Periods page.';
                }
                action("Item Journal")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Item Journals';
                    RunObject = page "Item Journal";
                    Tooltip = 'Open the Item Journals page.';
                }
                action("Item Reclass. Journals2")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item Reclassification Journals';
                    RunObject = page "Item Reclass. Journal";
                    Tooltip = 'Open the Item Reclassification Journals page.';
                }
                action("Phys. Inventory Journals")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Physical Inventory Journals';
                    RunObject = page "Phys. Inventory Journal";
                    Tooltip = 'Open the Physical Inventory Journals page.';
                }
                action("Revaluation Journals")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Revaluation Journals';
                    RunObject = page "Revaluation Journal";
                    Tooltip = 'Open the Revaluation Journals page.';
                }
                group("Group15")
                {
                    Caption = 'Setup';
                    action("Inventory Setup")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Inventory Setup';
                        RunObject = page "Inventory Setup";
                        Tooltip = 'Open the Inventory Setup page.';
                    }
                    action("Assembly Setup")
                    {
                        ApplicationArea = Assembly;
                        Caption = 'Assembly Setup';
                        RunObject = page "Assembly Setup";
                        Tooltip = 'Open the Assembly Setup page.';
                    }
                    action("Locations")
                    {
                        ApplicationArea = Location;
                        Caption = 'Locations';
                        RunObject = page "Location List";
                        Tooltip = 'Open the Locations page.';
                    }
                    action("Item Tracking Codes")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Item Tracking Codes';
                        RunObject = page "Item Tracking Codes";
                        Tooltip = 'Open the Item Tracking Codes page.';
                    }
                    action("Item Journal Templates")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Journal Templates';
                        RunObject = page "Item Journal Templates";
                        Tooltip = 'Open the Item Journal Templates page.';
                    }
                    action("Nonstock Item Setup")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Nonstock Item Setup';
                        RunObject = page "Catalog Item Setup";
                        Tooltip = 'Open the Nonstock Item Setup page.';
                    }
                    action("Transfer Routes")
                    {
                        ApplicationArea = Location;
                        Caption = 'Transfer Routes';
                        RunObject = page "Transfer Routes";
                        Tooltip = 'Open the Transfer Routes page.';
                    }
                    action("CD No. Format")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'CD No. Format';
                        RunObject = page "CD No. Format";
                        Tooltip = 'Open the CD No. Format page.';
                    }
                    action("Create Stockkeeping Unit")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Create Stockkeeping Unit';
                        RunObject = report "Create Stockkeeping Unit";
                        Tooltip = 'Run the Create Stockkeeping Unit report.';
                    }
                    action("Report Selections Inventory")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Report Selections Inventory';
                        RunObject = page "Report Selection - Inventory";
                        Tooltip = 'Open the Report Selections Inventory page.';
                    }
                }
            }
            group("Group16")
            {
                Caption = 'Assembly';
                action("Items1")
                {
                    ApplicationArea = Warehouse, Assembly;
                    Caption = 'Items';
                    RunObject = page "Item List";
                    Tooltip = 'Open the Items page.';
                }
                action("Resources")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Resources';
                    RunObject = page "Resource List";
                    Tooltip = 'Open the Resources page.';
                }
                action("Assembly Orders2")
                {
                    ApplicationArea = Assembly;
                    Caption = 'Assembly Orders';
                    RunObject = page "Assembly Orders";
                    Tooltip = 'Open the Assembly Orders page.';
                }
                action("Orders3")
                {
                    ApplicationArea = Warehouse, Assembly;
                    Caption = 'Sales Orders';
                    RunObject = page "Sales Order List";
                    Tooltip = 'Open the Sales Orders page.';
                }
                action("Order Planning")
                {
                    ApplicationArea = Planning;
                    Caption = 'Order Planning';
                    RunObject = page "Order Planning";
                    Tooltip = 'Open the Order Planning page.';
                }
                action("Planning Worksheets")
                {
                    ApplicationArea = Planning;
                    Caption = 'Planning Worksheets';
                    RunObject = page "Planning Worksheet";
                    Tooltip = 'Open the Planning Worksheets page.';
                }
                action("Assembly Setup1")
                {
                    ApplicationArea = Assembly;
                    Caption = 'Assembly Setup';
                    RunObject = page "Assembly Setup";
                    Tooltip = 'Open the Assembly Setup page.';
                }
                group("Group17")
                {
                    Caption = 'Posted Documents';
                    action("Posted Assembly Orders1")
                    {
                        ApplicationArea = Assembly;
                        Caption = 'Posted Assembly Orders';
                        RunObject = page "Posted Assembly Orders";
                        Tooltip = 'Open the Posted Assembly Orders page.';
                    }
                }
                group("Group18")
                {
                    Caption = 'Reports';
                    action("Assemble to Order - Sales")
                    {
                        ApplicationArea = Assembly;
                        Caption = 'Assemble to Order - Sales';
                        RunObject = report "Assemble to Order - Sales";
                        Tooltip = 'Run the Assemble to Order - Sales report.';
                    }
                    action("Item - Able to Make (Timeline)")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Item - Able to Make (Timeline)';
                        RunObject = report "Item - Able to Make (Timeline)";
                        Tooltip = 'Run the Item - Able to Make (Timeline) report.';
                    }
                    action("BOM Cost Share Distribution")
                    {
                        ApplicationArea = Assembly;
                        Caption = 'BOM Cost Share Distribution';
                        RunObject = report "BOM Cost Share Distribution";
                        Tooltip = 'Run the BOM Cost Share Distribution report.';
                    }
                    group("Group19")
                    {
                        Caption = 'Assembly BOM';
                        action("Where-Used List")
                        {
                            ApplicationArea = Assembly;
                            Caption = 'Where-Used List';
                            RunObject = report "Where-Used List";
                            Tooltip = 'Run the Where-Used List report.';
                        }
                        action("Assembly BOMs")
                        {
                            ApplicationArea = Assembly;
                            Caption = 'Assembly BOMs';
                            RunObject = report "Assembly BOMs";
                            Tooltip = 'Run the Assembly BOMs report.';
                        }
                        action("Assembly BOM - Raw Materials")
                        {
                            ApplicationArea = Assembly;
                            Caption = 'Assembly BOM - Raw Materials';
                            RunObject = report "Assembly BOM - Raw Materials";
                            Tooltip = 'Run the Assembly BOM - Raw Materials report.';
                        }
                        action("Assembly BOM - Sub-Assemblies")
                        {
                            ApplicationArea = Assembly;
                            Caption = 'Assembly BOM - Subassemblies';
                            RunObject = report "Assembly BOM - Subassemblies";
                            Tooltip = 'Run the Assembly BOM - Subassemblies report.';
                        }
                        action("Assembly BOM - Finished Goods")
                        {
                            ApplicationArea = Assembly;
                            Caption = 'Assembly BOM - End Items';
                            RunObject = report "Assembly BOM - End Items";
                            Tooltip = 'Run the Assembly BOM - End Items report.';
                        }
                    }
                }
            }
            group("Group20")
            {
                Caption = 'Warehouse';
                action("Bin Types")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Bin Types';
                    RunObject = page "Bin Types";
                    Tooltip = 'Open the Bin Types page.';
                    AccessByPermission = tabledata 7354 = R;
                }
                action("Warehouse Classes")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Warehouse Classes';
                    RunObject = page "Warehouse Classes";
                    Tooltip = 'Open the Warehouse Classes page.';
                }
                action("Special Equipment")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Special Equipment';
                    RunObject = page "Special Equipment";
                    Tooltip = 'Open the Special Equipment page.';
                }
                action("Warehouse Employees")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Warehouse Employees';
                    RunObject = page "Warehouse Employees";
                    Tooltip = 'Open the Warehouse Employees page.';
                }
                action("Warehouse Setup")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Warehouse Setup';
                    RunObject = page "Warehouse Setup";
                    Tooltip = 'Open the Warehouse Setup page.';
                }
                action("Locations1")
                {
                    ApplicationArea = Location;
                    Caption = 'Locations';
                    RunObject = page "Location List";
                    Tooltip = 'Open the Locations page.';
                }
                action("Report Selections - Item. Docs")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Report Selections - Item. Docs';
                    RunObject = page "Report Selection - Item. Docs";
                    Tooltip = 'Open the Report Selections - Item. Docs page.';
                }
                group("Group21")
                {
                    Caption = 'Templates';
                    action("Bin Templates")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Bin Templates';
                        RunObject = page "Bin Templates";
                        Tooltip = 'Open the Bin Templates page.';
                        AccessByPermission = tabledata 7354 = R;
                    }
                    action("Put-away Templates")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Put-away Templates';
                        RunObject = page "Put-away Template List";
                        Tooltip = 'Open the Put-away Templates page.';
                    }
                    action("Bin Creation Worksheet Templat")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Bin Creation Worksheet Templates';
                        RunObject = page "Bin Creation Wksh. Templates";
                        Tooltip = 'Open the Bin Creation Worksheet Templates page.';
                        AccessByPermission = tabledata 7354 = R;
                    }
                    action("Whse. Journal Templates")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Whse. Journal Templates';
                        RunObject = page "Whse. Journal Templates";
                        Tooltip = 'Open the Whse. Journal Templates page.';
                    }
                    action("Whse. Worksheet Templates")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Whse. Worksheet Templates';
                        RunObject = page "Whse. Worksheet Templates";
                        Tooltip = 'Open the Whse. Worksheet Templates page.';
                    }
                }
                group("Group22")
                {
                    Caption = 'ADCS';
                    action("ADCS Users")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'ADCS Users';
                        RunObject = page "ADCS Users";
                        Tooltip = 'Open the ADCS Users page.';
                    }
                    action("Miniforms")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Miniforms';
                        RunObject = page "Miniforms";
                        Tooltip = 'Open the Miniforms page.';
                    }
                    action("Miniform Functions Group")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Miniform Functions Group';
                        RunObject = page "Functions";
                        Tooltip = 'Open the Miniform Functions Group page.';
                    }
                }
            }
        }
    }
}