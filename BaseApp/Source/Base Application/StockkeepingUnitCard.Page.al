page 5700 "Stockkeeping Unit Card"
{
    Caption = 'Stockkeeping Unit Card';
    PageType = Card;
    PromotedActionCategories = 'New,Process,Report,Item,Navigate';
    SourceTable = "Stockkeeping Unit";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Planning;
                    Importance = Promoted;
                    ToolTip = 'Specifies the item number to which the SKU applies.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the description from the Item Card.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    Importance = Promoted;
                    ToolTip = 'Specifies the location code (for example, the warehouse or distribution center) to which the SKU applies.';
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    Importance = Promoted;
                    ToolTip = 'Specifies the variant of the item on the line.';
                }
                field("Assembly BOM"; "Assembly BOM")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies if the item is an assembly BOM.';
                }
                field("Shelf No."; "Shelf No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies where to find the SKU in the warehouse.';
                }
                field("Last Date Modified"; "Last Date Modified")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies when the SKU card was last modified.';
                }
                field("Qty. on Purch. Order"; "Qty. on Purch. Order")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies for the SKU, the same as the field does on the item card.';
                }
                field("Qty. on Prod. Order"; "Qty. on Prod. Order")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies how many item units have been planned for production, which is how many units are on outstanding production order lines.';
                }
                field("Qty. in Transit"; "Qty. in Transit")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the quantity of the SKUs in transit. These items have been shipped, but not yet received.';
                }
                field("Qty. on Component Lines"; "Qty. on Component Lines")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies how many item units are needed for production, which is how many units remain on outstanding production order component lists.';
                }
                field("Qty. on Sales Order"; "Qty. on Sales Order")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies for the SKU, the same as the field does on the item card.';
                }
                field("Qty. on Service Order"; "Qty. on Service Order")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies how many item units are reserved for service orders, which is how many units are listed on outstanding service order lines.';
                }
                field(Inventory; Inventory)
                {
                    ApplicationArea = Planning;
                    Importance = Promoted;
                    ToolTip = 'Specifies for the SKU, the same as the field does on the item card.';
                }
                field("Qty. on Job Order"; "Qty. on Job Order")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies how many units of the item are allocated to jobs, meaning listed on outstanding job planning lines.';
                }
                field("Qty. on Assembly Order"; "Qty. on Assembly Order")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies how many units of the SKU are allocated to assembly orders, which is how many are listed on outstanding assembly order headers.';
                }
                field("Qty. on Asm. Component"; "Qty. on Asm. Component")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies how many item units are allocated as assembly components, which is how many units are on outstanding assembly order lines.';
                }
            }
            group(Invoicing)
            {
                Caption = 'Invoicing';
                field("Standard Cost"; "Standard Cost")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = StandardCostEnable;
                    ToolTip = 'Specifies the unit cost that is used as an estimation to be adjusted with variances later. It is typically used in assembly and production where costs can vary. Warning: If the SKU is supplied through production, then this field is not used when invoicing and adjusting the actual cost of the produced item. Instead, the Standard Cost field on the underlying item card is used, and any variances are calculated against the cost shares of that item.';

                    trigger OnDrillDown()
                    var
                        ShowAvgCalcItem: Codeunit "Show Avg. Calc. - Item";
                    begin
                        ShowAvgCalcItem.DrillDownAvgCostAdjmtPoint(Item);
                    end;
                }
                field("Unit Cost"; "Unit Cost")
                {
                    ApplicationArea = Planning;
                    Enabled = UnitCostEnable;
                    Importance = Promoted;
                    ToolTip = 'Specifies the cost of one unit of the item or resource on the line.';

                    trigger OnDrillDown()
                    var
                        ShowAvgCalcItem: Codeunit "Show Avg. Calc. - Item";
                    begin
                        ShowAvgCalcItem.DrillDownAvgCostAdjmtPoint(Item);
                    end;
                }
                field("Last Direct Cost"; "Last Direct Cost")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the most recent direct unit cost that was paid for the SKU.';
                }
            }
            group(Replenishment)
            {
                Caption = 'Replenishment';
                field("Replenishment System"; "Replenishment System")
                {
                    ApplicationArea = Planning;
                    Importance = Promoted;
                    ToolTip = 'Specifies the type of supply order that is created by the planning system when the SKU needs to be replenished.';
                }
                field("Lead Time Calculation"; "Lead Time Calculation")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies a date formula for the amount of time it takes to replenish the item.';
                }
                group(Purchase)
                {
                    Caption = 'Purchase';
                    field("Vendor No."; "Vendor No.")
                    {
                        ApplicationArea = Planning;
                        ToolTip = 'Specifies for the SKU, the same as the field does on the item card.';
                    }
                    field("Vendor Item No."; "Vendor Item No.")
                    {
                        ApplicationArea = Planning;
                        ToolTip = 'Specifies the number that the vendor uses for this item.';
                    }
                }
                group(Transfer)
                {
                    Caption = 'Transfer';
                    field("Transfer-from Code"; "Transfer-from Code")
                    {
                        ApplicationArea = Planning;
                        ToolTip = 'Specifies the code of the location that items are transferred from.';
                    }
                }
                group(Production)
                {
                    Caption = 'Production';
                    field("Manufacturing Policy"; "Manufacturing Policy")
                    {
                        ApplicationArea = Manufacturing;
                        ToolTip = 'Specifies if additional orders for any related components are calculated.';
                    }
                    field("Flushing Method"; "Flushing Method")
                    {
                        ApplicationArea = Manufacturing;
                        ToolTip = 'Specifies how consumption of the item (component) is calculated and handled in production processes. Manual: Enter and post consumption in the consumption journal manually. Forward: Automatically posts consumption according to the production order component lines when the first operation starts. Backward: Automatically calculates and posts consumption according to the production order component lines when the production order is finished. Pick + Forward / Pick + Backward: Variations with warehousing.';
                    }
                    field("Components at Location"; "Components at Location")
                    {
                        ApplicationArea = Manufacturing;
                        ToolTip = 'Specifies the inventory location from where the production order components are to be taken when producing this SKU.';
                    }
                    field("Lot Size"; "Lot Size")
                    {
                        ApplicationArea = Manufacturing;
                        ToolTip = 'Specifies for the SKU, the same as the field does on the item card.';
                    }
                }
                group(Assembly)
                {
                    Caption = 'Assembly';
                    field("Assembly Policy"; "Assembly Policy")
                    {
                        ApplicationArea = Assembly;
                        ToolTip = 'Specifies which default order flow is used to supply this SKU by assembly.';
                    }
                }
            }
            group(Planning)
            {
                Caption = 'Planning';
                field("Reordering Policy"; "Reordering Policy")
                {
                    ApplicationArea = Planning;
                    Importance = Promoted;
                    ToolTip = 'Specifies for the SKU, the same as the field does on the item card.';

                    trigger OnValidate()
                    begin
                        EnablePlanningControls;
                    end;
                }
                field("Dampener Period"; "Dampener Period")
                {
                    ApplicationArea = Planning;
                    Enabled = DampenerPeriodEnable;
                    ToolTip = 'Specifies a period of time during which you do not want the planning system to propose to reschedule existing supply orders forward.';
                }
                field("Dampener Quantity"; "Dampener Quantity")
                {
                    ApplicationArea = Planning;
                    Enabled = DampenerQtyEnable;
                    ToolTip = 'Specifies a dampener quantity to block insignificant change suggestions, if the quantity by which the supply would change is lower than the dampener quantity.';
                }
                field("Safety Lead Time"; "Safety Lead Time")
                {
                    ApplicationArea = Planning;
                    Enabled = SafetyLeadTimeEnable;
                    ToolTip = 'Specifies for the SKU, the same as the field does on the item card.';
                }
                field("Safety Stock Quantity"; "Safety Stock Quantity")
                {
                    ApplicationArea = Planning;
                    Enabled = SafetyStockQtyEnable;
                    ToolTip = 'Specifies for the SKU, the same as the field does on the item card.';
                }
                group("Lot-for-Lot Parameters")
                {
                    Caption = 'Lot-for-Lot Parameters';
                    field("Include Inventory"; "Include Inventory")
                    {
                        ApplicationArea = Planning;
                        Enabled = IncludeInventoryEnable;
                        ToolTip = 'Specifies for the SKU, the same as the field does on the item card.';

                        trigger OnValidate()
                        begin
                            EnablePlanningControls;
                        end;
                    }
                    field("Lot Accumulation Period"; "Lot Accumulation Period")
                    {
                        ApplicationArea = Planning;
                        Enabled = LotAccumulationPeriodEnable;
                        ToolTip = 'Specifies a period in which multiple demands are accumulated into one supply order when you use the Lot-for-Lot reordering policy.';
                    }
                    field("Rescheduling Period"; "Rescheduling Period")
                    {
                        ApplicationArea = Planning;
                        Enabled = ReschedulingPeriodEnable;
                        ToolTip = 'Specifies a period within which any suggestion to change a supply date always consists of a Reschedule action and never a Cancel + New action.';
                    }
                }
                group("Reorder-Point Parameters")
                {
                    Caption = 'Reorder-Point Parameters';
                    grid(Control39)
                    {
                        GridLayout = Rows;
                        ShowCaption = false;
                        group(Control41)
                        {
                            ShowCaption = false;
                            field("Reorder Point"; "Reorder Point")
                            {
                                ApplicationArea = Planning;
                                Enabled = ReorderPointEnable;
                                ToolTip = 'Specifies for the SKU, the same as the field does on the item card.';
                            }
                            field("Reorder Quantity"; "Reorder Quantity")
                            {
                                ApplicationArea = Planning;
                                Enabled = ReorderQtyEnable;
                                ToolTip = 'Specifies for the SKU, the same as the field does on the item card.';
                            }
                            field("Maximum Inventory"; "Maximum Inventory")
                            {
                                ApplicationArea = Planning;
                                Enabled = MaximumInventoryEnable;
                                ToolTip = 'Specifies for the SKU, the same as the field does on the item card.';
                            }
                        }
                    }
                    field("Overflow Level"; "Overflow Level")
                    {
                        ApplicationArea = Planning;
                        Enabled = OverflowLevelEnable;
                        Importance = Additional;
                        ToolTip = 'Specifies a quantity you allow projected inventory to exceed the reorder point before the system suggests to decrease existing supply orders.';
                    }
                    field("Time Bucket"; "Time Bucket")
                    {
                        ApplicationArea = Planning;
                        Enabled = TimeBucketEnable;
                        Importance = Additional;
                        ToolTip = 'Specifies a time period for the recurring planning horizon of the SKU when you use Fixed Reorder Qty. or Maximum Qty. reordering policies.';
                    }
                }
                group("Order Modifiers")
                {
                    Caption = 'Order Modifiers';
                    Enabled = MinimumOrderQtyEnable;
                    grid(Control21)
                    {
                        GridLayout = Rows;
                        ShowCaption = false;
                        group(Control23)
                        {
                            ShowCaption = false;
                            field("Minimum Order Quantity"; "Minimum Order Quantity")
                            {
                                ApplicationArea = Planning;
                                Enabled = MinimumOrderQtyEnable;
                                ToolTip = 'Specifies for the SKU, the same as the field does on the item card.';
                            }
                            field("Maximum Order Quantity"; "Maximum Order Quantity")
                            {
                                ApplicationArea = Planning;
                                Enabled = MaximumOrderQtyEnable;
                                ToolTip = 'Specifies for the SKU, the same as the field does on the item card.';
                            }
                            field("Order Multiple"; "Order Multiple")
                            {
                                ApplicationArea = Planning;
                                Enabled = OrderMultipleEnable;
                                ToolTip = 'Specifies for the SKU, the same as the field does on the item card.';
                            }
                        }
                    }
                }
            }
            group(Control1907509201)
            {
                Caption = 'Warehouse';
                field("Special Equipment Code"; "Special Equipment Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the code of the equipment that you need to use when working with the SKU.';
                }
                field("Put-away Template Code"; "Put-away Template Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the put-away template that the program uses when it performs a put-away for the SKU.';
                }
                field("Put-away Unit of Measure Code"; "Put-away Unit of Measure Code")
                {
                    ApplicationArea = Warehouse;
                    Importance = Promoted;
                    ToolTip = 'Specifies the code of the unit of measure that the program uses when it performs a put-away for the SKU.';
                }
                field("Phys Invt Counting Period Code"; "Phys Invt Counting Period Code")
                {
                    ApplicationArea = Warehouse;
                    Importance = Promoted;
                    ToolTip = 'Specifies the code of the counting period that indicates how often you want to count the SKU in a physical inventory.';
                }
                field("Last Phys. Invt. Date"; "Last Phys. Invt. Date")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the date on which you last posted the results of a physical inventory for the SKU to the item ledger.';
                }
                field("Last Counting Period Update"; "Last Counting Period Update")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the last date on which you calculated the counting period.';
                }
                field("Next Counting Start Date"; "Next Counting Start Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the starting date of the next counting period.';
                }
                field("Next Counting End Date"; "Next Counting End Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the ending date of the next counting period.';
                }
                field("Use Cross-Docking"; "Use Cross-Docking")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies if the SKU can be cross-docked.';
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
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Item")
            {
                Caption = '&Item';
                Image = Item;
                action(Card)
                {
                    ApplicationArea = Planning;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Item Card";
                    RunPageLink = "No." = FIELD("Item No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';
                }
                group(Statistics)
                {
                    Caption = 'Statistics';
                    Image = Statistics;
                    action(Action89)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Statistics';
                        Image = Statistics;
                        Promoted = true;
                        PromotedCategory = Category4;
                        PromotedIsBig = true;
                        ShortCutKey = 'F7';
                        ToolTip = 'View statistical information, such as the value of posted entries, for the record.';

                        trigger OnAction()
                        var
                            ItemStatistics: Page "Item Statistics";
                        begin
                            ItemStatistics.SetItem(Item);
                            ItemStatistics.RunModal;
                        end;
                    }
                }
                action("Co&mments")
                {
                    ApplicationArea = Planning;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    Promoted = true;
                    PromotedCategory = Category4;
                    RunObject = Page "Comment Sheet";
                    RunPageLink = "Table Name" = CONST(Item),
                                  "No." = FIELD("Item No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action(Dimensions)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    RunObject = Page "Default Dimensions";
                    RunPageLink = "Table ID" = CONST(27),
                                  "No." = FIELD("Item No.");
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
                }
                action("&Picture")
                {
                    ApplicationArea = Warehouse;
                    Caption = '&Picture';
                    Image = Picture;
                    Promoted = true;
                    PromotedCategory = Category5;
                    RunObject = Page "Item Picture";
                    RunPageLink = "No." = FIELD("Item No."),
                                  "Date Filter" = FIELD("Date Filter"),
                                  "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter"),
                                  "Location Filter" = FIELD("Location Code"),
                                  "Drop Shipment Filter" = FIELD("Drop Shipment Filter"),
                                  "Variant Filter" = FIELD("Variant Code");
                    ToolTip = 'View or add a picture of the item or, for example, the company''s logo.';
                }
                separator(Action103)
                {
                }
                action("&Units of Measure")
                {
                    ApplicationArea = Planning;
                    Caption = '&Units of Measure';
                    Image = UnitOfMeasure;
                    RunObject = Page "Item Units of Measure";
                    RunPageLink = "Item No." = FIELD("Item No.");
                    ToolTip = 'Set up the different units that the item can be traded in, such as piece, box, or hour.';
                }
                action("Va&riants")
                {
                    ApplicationArea = Planning;
                    Caption = 'Va&riants';
                    Image = ItemVariant;
                    RunObject = Page "Item Variants";
                    RunPageLink = "Item No." = FIELD("Item No.");
                    ToolTip = 'View how the inventory level of an item will develop over time according to the variant that you select.';
                }
                separator(Action106)
                {
                }
                action(Translations)
                {
                    ApplicationArea = Planning;
                    Caption = 'Translations';
                    Image = Translations;
                    RunObject = Page "Item Translations";
                    RunPageLink = "Item No." = FIELD("Item No."),
                                  "Variant Code" = FIELD(FILTER("Variant Code"));
                    ToolTip = 'View or edit translated item descriptions. Translated item descriptions are automatically inserted on documents according to the language code.';
                }
                action("E&xtended Texts")
                {
                    ApplicationArea = Planning;
                    Caption = 'E&xtended Texts';
                    Image = Text;
                    RunObject = Page "Extended Text List";
                    RunPageLink = "Table Name" = CONST(Item),
                                  "No." = FIELD("Item No.");
                    RunPageView = SORTING("Table Name", "No.", "Language Code", "All Language Codes", "Starting Date", "Ending Date");
                    ToolTip = 'Select or set up additional text for the description of the item. Extended text can be inserted under the Description field on document lines for the item.';
                }
            }
            group("&SKU")
            {
                Caption = '&SKU';
                Image = SKU;
                group(Action92)
                {
                    Caption = 'Statistics';
                    Image = Statistics;
                    action("Entry Statistics")
                    {
                        ApplicationArea = Planning;
                        Caption = 'Entry Statistics';
                        Image = EntryStatistics;
                        RunObject = Page "Item Entry Statistics";
                        RunPageLink = "No." = FIELD("Item No."),
                                      "Date Filter" = FIELD("Date Filter"),
                                      "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                                      "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter"),
                                      "Location Filter" = FIELD("Location Code"),
                                      "Drop Shipment Filter" = FIELD("Drop Shipment Filter"),
                                      "Variant Filter" = FIELD("Variant Code");
                        ToolTip = 'View entry statistics for the record.';
                    }
                    action("T&urnover")
                    {
                        ApplicationArea = Planning;
                        Caption = 'T&urnover';
                        Image = Turnover;
                        RunObject = Page "Item Turnover";
                        RunPageLink = "No." = FIELD("Item No."),
                                      "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                                      "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter"),
                                      "Location Filter" = FIELD("Location Code"),
                                      "Drop Shipment Filter" = FIELD("Drop Shipment Filter"),
                                      "Variant Filter" = FIELD("Variant Code");
                        ToolTip = 'View a detailed account of item turnover by periods after you have set the relevant filters for location and variant.';
                    }
                }
                group("&Item Availability by")
                {
                    Caption = '&Item Availability by';
                    Image = ItemAvailability;
                    action("Event")
                    {
                        ApplicationArea = Planning;
                        Caption = 'Event';
                        Image = "Event";
                        ToolTip = 'View how the actual and the projected available balance of an item will develop over time according to supply and demand events.';

                        trigger OnAction()
                        var
                            Item: Record Item;
                        begin
                            Item.Get("Item No.");
                            Item.SetRange("Location Filter", "Location Code");
                            Item.SetRange("Variant Filter", "Variant Code");
                            CopyFilter("Date Filter", Item."Date Filter");
                            CopyFilter("Global Dimension 1 Filter", Item."Global Dimension 1 Filter");
                            CopyFilter("Global Dimension 2 Filter", Item."Global Dimension 2 Filter");
                            CopyFilter("Drop Shipment Filter", Item."Drop Shipment Filter");
                            ItemAvailFormsMgt.ShowItemAvailFromItem(Item, ItemAvailFormsMgt.ByEvent);
                        end;
                    }
                    action(Period)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Period';
                        Image = Period;
                        RunObject = Page "Item Availability by Periods";
                        RunPageLink = "No." = FIELD("Item No."),
                                      "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                                      "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter"),
                                      "Location Filter" = FIELD("Location Code"),
                                      "Drop Shipment Filter" = FIELD("Drop Shipment Filter"),
                                      "Variant Filter" = FIELD("Variant Code");
                        ToolTip = 'View the projected quantity of the item over time according to time periods, such as day, week, or month.';
                    }
                    action("BOM Level")
                    {
                        ApplicationArea = Assembly;
                        Caption = 'BOM Level';
                        Image = BOMLevel;
                        ToolTip = 'View availability figures for items on bills of materials that show how many units of a parent item you can make based on the availability of child items.';

                        trigger OnAction()
                        var
                            Item: Record Item;
                        begin
                            Item.Get("Item No.");
                            Item.SetRange("Location Filter", "Location Code");
                            Item.SetRange("Variant Filter", "Variant Code");
                            ItemAvailFormsMgt.ShowItemAvailFromItem(Item, ItemAvailFormsMgt.ByBOM);
                        end;
                    }
                    action(Timeline)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Timeline';
                        Image = Timeline;
                        ToolTip = 'Get a graphical view of an item''s projected inventory based on future supply and demand events, with or without planning suggestions. The result is a graphical representation of the inventory profile.';

                        trigger OnAction()
                        begin
                            ShowTimeline(Rec);
                        end;
                    }
                }
                action(Action124)
                {
                    ApplicationArea = All;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    Promoted = true;
                    PromotedCategory = Category4;
                    RunObject = Page "Stock. Unit Comment Sheet";
                    RunPageLink = "Item No." = FIELD("Item No."),
                                  "Variant Code" = FIELD("Variant Code"),
                                  "Location Code" = FIELD("Location Code");
                    ToolTip = 'View or add comments for the record.';
                }
            }
            group(History)
            {
                Caption = 'History';
                Image = History;
                group("E&ntries")
                {
                    Caption = 'E&ntries';
                    Image = Entries;
                    action("Ledger E&ntries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ledger E&ntries';
                        Image = ItemLedger;
                        Promoted = true;
                        PromotedCategory = Category4;
                        PromotedIsBig = true;
                        RunObject = Page "Item Ledger Entries";
                        RunPageLink = "Item No." = FIELD("Item No."),
                                      "Location Code" = FIELD("Location Code"),
                                      "Variant Code" = FIELD("Variant Code");
                        RunPageView = SORTING("Item No.", Open, "Variant Code");
                        ShortCutKey = 'Ctrl+F7';
                        ToolTip = 'View the history of transactions that have been posted for the selected record.';
                    }
                    action("&Reservation Entries")
                    {
                        ApplicationArea = Reservation;
                        Caption = '&Reservation Entries';
                        Image = ReservationLedger;
                        RunObject = Page "Reservation Entries";
                        RunPageLink = "Item No." = FIELD("Item No."),
                                      "Location Code" = FIELD("Location Code"),
                                      "Variant Code" = FIELD("Variant Code"),
                                      "Reservation Status" = CONST(Reservation);
                        RunPageView = SORTING("Item No.", "Variant Code", "Location Code", "Reservation Status");
                        ToolTip = 'View all reservations that are made for the item, either manually or automatically.';
                    }
                    action("&Phys. Inventory Ledger Entries")
                    {
                        ApplicationArea = Warehouse;
                        Caption = '&Phys. Inventory Ledger Entries';
                        Image = PhysicalInventoryLedger;
                        RunObject = Page "Phys. Inventory Ledger Entries";
                        RunPageLink = "Item No." = FIELD("Item No."),
                                      "Location Code" = FIELD("Location Code"),
                                      "Variant Code" = FIELD("Variant Code");
                        RunPageView = SORTING("Item No.", "Variant Code");
                        ToolTip = 'View how many units of the item you had in stock at the last physical count.';
                    }
                    action("&Value Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = '&Value Entries';
                        Image = ValueLedger;
                        RunObject = Page "Value Entries";
                        RunPageLink = "Item No." = FIELD("Item No."),
                                      "Location Code" = FIELD("Location Code"),
                                      "Variant Code" = FIELD("Variant Code");
                        RunPageView = SORTING("Item No.", "Valuation Date", "Location Code", "Variant Code");
                        ToolTip = 'View the history of posted amounts that affect the value of the item. Value entries are created for every transaction with the item.';
                    }
                    action("Item &Tracking Entries")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Item &Tracking Entries';
                        Image = ItemTrackingLedger;
                        ToolTip = 'View serial or lot numbers that are assigned to items.';

                        trigger OnAction()
                        var
                            ItemTrackingDocMgt: Codeunit "Item Tracking Doc. Management";
                        begin
                            ItemTrackingDocMgt.ShowItemTrackingForMasterData(0, '', "Item No.", "Variant Code", '', '', "Location Code");
                        end;
                    }
                }
            }
            group(Warehouse)
            {
                Caption = 'Warehouse';
                Image = Warehouse;
                action("&Bin Contents")
                {
                    ApplicationArea = Warehouse;
                    Caption = '&Bin Contents';
                    Image = BinContent;
                    RunObject = Page "Bin Contents List";
                    RunPageLink = "Location Code" = FIELD("Location Code"),
                                  "Item No." = FIELD("Item No."),
                                  "Variant Code" = FIELD("Variant Code");
                    RunPageView = SORTING("Location Code", "Item No.", "Variant Code");
                    ToolTip = 'View the quantities of the item in each bin where it exists. You can see all the important parameters relating to bin content, and you can modify certain bin content parameters in this window.';
                }
            }
        }
        area(processing)
        {
            group(New)
            {
                Caption = 'New';
                Image = NewItem;
                action(NewItem)
                {
                    ApplicationArea = Planning;
                    Caption = 'New Item';
                    Image = NewItem;
                    Promoted = true;
                    PromotedCategory = New;
                    RunObject = Page "Item Card";
                    RunPageMode = Create;
                    ToolTip = 'Create an item card based on the stockkeeping unit.';
                }
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("C&alculate Counting Period")
                {
                    AccessByPermission = TableData "Phys. Invt. Item Selection" = R;
                    ApplicationArea = Warehouse;
                    Caption = 'C&alculate Counting Period';
                    Image = CalculateCalendar;
                    ToolTip = 'Prepare for a physical inventory by calculating which items or SKUs need to be counted in the current period.';

                    trigger OnAction()
                    var
                        PhysInvtCountMgt: Codeunit "Phys. Invt. Count.-Management";
                    begin
                        PhysInvtCountMgt.UpdateSKUPhysInvtCount(Rec);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        InvtSetup.Get();
        Item.Reset();
        if Item.Get("Item No.") then begin
            if InvtSetup."Average Cost Calc. Type" = InvtSetup."Average Cost Calc. Type"::"Item & Location & Variant" then begin
                Item.SetRange("Location Filter", "Location Code");
                Item.SetRange("Variant Filter", "Variant Code");
            end;
            Item.SetFilter("Date Filter", GetFilter("Date Filter"));
        end;
        EnablePlanningControls;
        EnableCostingControls;
    end;

    trigger OnInit()
    begin
        UnitCostEnable := true;
        StandardCostEnable := true;
        OverflowLevelEnable := true;
        DampenerQtyEnable := true;
        DampenerPeriodEnable := true;
        LotAccumulationPeriodEnable := true;
        ReschedulingPeriodEnable := true;
        IncludeInventoryEnable := true;
        OrderMultipleEnable := true;
        MaximumOrderQtyEnable := true;
        MinimumOrderQtyEnable := true;
        MaximumInventoryEnable := true;
        ReorderQtyEnable := true;
        ReorderPointEnable := true;
        SafetyStockQtyEnable := true;
        SafetyLeadTimeEnable := true;
        TimeBucketEnable := true;
    end;

    var
        InvtSetup: Record "Inventory Setup";
        Item: Record Item;
        ItemAvailFormsMgt: Codeunit "Item Availability Forms Mgt";
        [InDataSet]
        TimeBucketEnable: Boolean;
        [InDataSet]
        SafetyLeadTimeEnable: Boolean;
        [InDataSet]
        SafetyStockQtyEnable: Boolean;
        [InDataSet]
        ReorderPointEnable: Boolean;
        [InDataSet]
        ReorderQtyEnable: Boolean;
        [InDataSet]
        MaximumInventoryEnable: Boolean;
        [InDataSet]
        MinimumOrderQtyEnable: Boolean;
        [InDataSet]
        MaximumOrderQtyEnable: Boolean;
        [InDataSet]
        OrderMultipleEnable: Boolean;
        [InDataSet]
        IncludeInventoryEnable: Boolean;
        [InDataSet]
        ReschedulingPeriodEnable: Boolean;
        [InDataSet]
        LotAccumulationPeriodEnable: Boolean;
        [InDataSet]
        DampenerPeriodEnable: Boolean;
        [InDataSet]
        DampenerQtyEnable: Boolean;
        [InDataSet]
        OverflowLevelEnable: Boolean;
        [InDataSet]
        StandardCostEnable: Boolean;
        [InDataSet]
        UnitCostEnable: Boolean;

    local procedure EnablePlanningControls()
    var
        PlanningGetParam: Codeunit "Planning-Get Parameters";
        TimeBucketEnabled: Boolean;
        SafetyLeadTimeEnabled: Boolean;
        SafetyStockQtyEnabled: Boolean;
        ReorderPointEnabled: Boolean;
        ReorderQtyEnabled: Boolean;
        MaximumInventoryEnabled: Boolean;
        MinimumOrderQtyEnabled: Boolean;
        MaximumOrderQtyEnabled: Boolean;
        OrderMultipleEnabled: Boolean;
        IncludeInventoryEnabled: Boolean;
        ReschedulingPeriodEnabled: Boolean;
        LotAccumulationPeriodEnabled: Boolean;
        DampenerPeriodEnabled: Boolean;
        DampenerQtyEnabled: Boolean;
        OverflowLevelEnabled: Boolean;
    begin
        PlanningGetParam.SetUpPlanningControls("Reordering Policy", "Include Inventory",
          TimeBucketEnabled, SafetyLeadTimeEnabled, SafetyStockQtyEnabled,
          ReorderPointEnabled, ReorderQtyEnabled, MaximumInventoryEnabled,
          MinimumOrderQtyEnabled, MaximumOrderQtyEnabled, OrderMultipleEnabled, IncludeInventoryEnabled,
          ReschedulingPeriodEnabled, LotAccumulationPeriodEnabled,
          DampenerPeriodEnabled, DampenerQtyEnabled, OverflowLevelEnabled);

        TimeBucketEnable := TimeBucketEnabled;
        SafetyLeadTimeEnable := SafetyLeadTimeEnabled;
        SafetyStockQtyEnable := SafetyStockQtyEnabled;
        ReorderPointEnable := ReorderPointEnabled;
        ReorderQtyEnable := ReorderQtyEnabled;
        MaximumInventoryEnable := MaximumInventoryEnabled;
        MinimumOrderQtyEnable := MinimumOrderQtyEnabled;
        MaximumOrderQtyEnable := MaximumOrderQtyEnabled;
        OrderMultipleEnable := OrderMultipleEnabled;
        IncludeInventoryEnable := IncludeInventoryEnabled;
        ReschedulingPeriodEnable := ReschedulingPeriodEnabled;
        LotAccumulationPeriodEnable := LotAccumulationPeriodEnabled;
        DampenerPeriodEnable := DampenerPeriodEnabled;
        DampenerQtyEnable := DampenerQtyEnabled;
        OverflowLevelEnable := OverflowLevelEnabled;
    end;

    local procedure EnableCostingControls()
    begin
        StandardCostEnable := Item."Costing Method" = Item."Costing Method"::Standard;
        UnitCostEnable := Item."Costing Method" <> Item."Costing Method"::Standard;
    end;
}

