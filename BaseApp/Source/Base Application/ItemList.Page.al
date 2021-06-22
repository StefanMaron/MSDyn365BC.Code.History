page 31 "Item List"
{
    AdditionalSearchTerms = 'product,finished good,component,raw material,assembly item';
    ApplicationArea = Basic, Suite, Assembly, Service;
    Caption = 'Items';
    CardPageID = "Item Card";
    Editable = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Item,History,Special Prices & Discounts,Request Approval,Periodic Activities,Inventory,Attributes';
    QueryCategory = 'Item List';
    RefreshOnActivate = true;
    SourceTable = Item;
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                Caption = 'Item';
                field("No."; "No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the item.';
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of the item.';
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the item card represents a physical inventory unit (Inventory), a labor time unit (Service), or a physical unit that is not tracked in inventory (Non-Inventory).';
                    Visible = IsFoundationEnabled;
                }
                field(InventoryField; Inventory)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    HideValue = IsNonInventoriable;
                    ToolTip = 'Specifies how many units, such as pieces, boxes, or cans, of the item are in inventory.';
                }
                field("Created From Nonstock Item"; "Created From Nonstock Item")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the item was created from a catalog item.';
                    Visible = false;
                }
                field("Substitutes Exist"; "Substitutes Exist")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies that a substitute exists for this item.';
                }
                field("Stockkeeping Unit Exists"; "Stockkeeping Unit Exists")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies that a stockkeeping unit exists for this item.';
                    Visible = false;
                }
                field("Assembly BOM"; "Assembly BOM")
                {
                    AccessByPermission = TableData "BOM Component" = R;
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies if the item is an assembly BOM.';
                }
                field("Production BOM No."; "Production BOM No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the production BOM that the item represents.';
                }
                field("Routing No."; "Routing No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the production routing that the item is used in.';
                }
                field("Base Unit of Measure"; "Base Unit of Measure")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies the base unit used to measure the item, such as piece, box, or pallet. The base unit of measure also serves as the conversion basis for alternate units of measure.';
                }
                field("Shelf No."; "Shelf No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies where to find the item in the warehouse. This is informational only.';
                    Visible = false;
                }
                field("Costing Method"; "Costing Method")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how the item''s cost flow is recorded and whether an actual or budgeted value is capitalized and used in the cost calculation.';
                    Visible = false;
                }
                field("Cost is Adjusted"; "Cost is Adjusted")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the item''s unit cost has been adjusted, either automatically or manually.';
                }
                field("Standard Cost"; "Standard Cost")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the unit cost that is used as an estimation to be adjusted with variances later. It is typically used in assembly and production where costs can vary.';
                    Visible = false;
                }
                field("Unit Cost"; "Unit Cost")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the cost per unit of the item.';
                }
                field("Last Direct Cost"; "Last Direct Cost")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the most recent direct unit cost that was paid for the item.';
                    Visible = false;
                }
                field("Price/Profit Calculation"; "Price/Profit Calculation")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the relationship between the Unit Cost, Unit Price, and Profit Percentage fields associated with this item.';
                    Visible = false;
                }
                field("Profit %"; "Profit %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the profit margin that you want to sell the item at. You can enter a profit percentage manually or have it entered according to the Price/Profit Calculation field';
                    Visible = false;
                }
                field("Unit Price"; "Unit Price")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies the price for one unit of the item, in LCY.';
                }
                field("Inventory Posting Group"; "Inventory Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies links between business transactions made for the item and an inventory account in the general ledger, to group amounts for that item type.';
                    Visible = false;
                }
                field("Gen. Prod. Posting Group"; "Gen. Prod. Posting Group")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
                    Visible = false;
                }
                field("VAT Prod. Posting Group"; "VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT product posting group. Links business transactions made for the item, resource, or G/L account with the general ledger, to account for VAT amounts resulting from trade with that record.';
                    Visible = false;
                }
                field("Item Disc. Group"; "Item Disc. Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an item group code that can be used as a criterion to grant a discount when the item is sold to a certain customer.';
                    Visible = false;
                }
                field("Vendor No."; "Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor code of who supplies this item by default.';
                }
                field("Vendor Item No."; "Vendor Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number that the vendor uses for this item.';
                    Visible = false;
                }
                field("Tariff No."; "Tariff No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for the item''s tariff number.';
                    Visible = false;
                }
                field("Search Description"; "Search Description")
                {
                    ApplicationArea = Advanced;
                    ToolTip = 'Specifies a search description that you use to find the item in lists.';
                }
                field("Overhead Rate"; "Overhead Rate")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the item''s indirect cost as an absolute amount.';
                    Visible = false;
                }
                field("Indirect Cost %"; "Indirect Cost %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the percentage of the item''s last purchase cost that includes indirect costs, such as freight that is associated with the purchase of the item.';
                    Visible = false;
                }
                field("Item Category Code"; "Item Category Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the category that the item belongs to. Item categories also contain any assigned item attributes.';
                    Visible = false;
                }
                field(Blocked; Blocked)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that transactions with the item cannot be posted, for example, because the item is in quarantine.';
                    Visible = false;
                }
                field("Last Date Modified"; "Last Date Modified")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the item card was last modified.';
                    Visible = false;
                }
                field("Sales Unit of Measure"; "Sales Unit of Measure")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the unit of measure code used when you sell the item.';
                    Visible = false;
                }
                field("Replenishment System"; "Replenishment System")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of supply order created by the planning system when the item needs to be replenished.';
                    Visible = false;
                }
                field("Purch. Unit of Measure"; "Purch. Unit of Measure")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the unit of measure code used when you purchase the item.';
                    Visible = false;
                }
                field("Lead Time Calculation"; "Lead Time Calculation")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a date formula for the amount of time it takes to replenish the item.';
                    Visible = false;
                }
                field("Manufacturing Policy"; "Manufacturing Policy")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies if additional orders for any related components are calculated.';
                    Visible = false;
                }
                field("Flushing Method"; "Flushing Method")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies how consumption of the item (component) is calculated and handled in production processes. Manual: Enter and post consumption in the consumption journal manually. Forward: Automatically posts consumption according to the production order component lines when the first operation starts. Backward: Automatically calculates and posts consumption according to the production order component lines when the production order is finished. Pick + Forward / Pick + Backward: Variations with warehousing.';
                    Visible = false;
                }
                field("Assembly Policy"; "Assembly Policy")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies which default order flow is used to supply this assembly item.';
                    Visible = false;
                }
                field("Item Tracking Code"; "Item Tracking Code")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies how items are tracked in the supply chain.';
                    Visible = false;
                }
                field("Default Deferral Template Code"; "Default Deferral Template Code")
                {
                    ApplicationArea = Suite;
                    Caption = 'Default Deferral Template';
                    Importance = Additional;
                    ToolTip = 'Specifies the default template that governs how to defer revenues and expenses to the periods when they occurred.';
                }
            }
        }
        area(factboxes)
        {
            part("Power BI Report FactBox"; "Power BI Report FactBox")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Power BI Reports';
                Visible = PowerBIVisible;
            }
            part(Control3; "Social Listening FactBox")
            {
                ApplicationArea = All;
                SubPageLink = "Source Type" = CONST(Item),
                              "Source No." = FIELD("No.");
                Visible = SocialListeningVisible;
            }
            part(Control26; "Social Listening Setup FactBox")
            {
                ApplicationArea = All;
                SubPageLink = "Source Type" = CONST(Item),
                              "Source No." = FIELD("No.");
                UpdatePropagation = Both;
                Visible = SocialListeningSetupVisible;
            }
            part(Control1901314507; "Item Invoicing FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = FIELD("No."),
                              "Date Filter" = FIELD("Date Filter"),
                              "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                              "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter"),
                              "Location Filter" = FIELD("Location Filter"),
                              "Drop Shipment Filter" = FIELD("Drop Shipment Filter"),
                              "Bin Filter" = FIELD("Bin Filter"),
                              "Variant Filter" = FIELD("Variant Filter"),
                              "Lot No. Filter" = FIELD("Lot No. Filter"),
                              "Serial No. Filter" = FIELD("Serial No. Filter");
            }
            part(Control1903326807; "Item Replenishment FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = FIELD("No."),
                              "Date Filter" = FIELD("Date Filter"),
                              "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                              "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter"),
                              "Location Filter" = FIELD("Location Filter"),
                              "Drop Shipment Filter" = FIELD("Drop Shipment Filter"),
                              "Bin Filter" = FIELD("Bin Filter"),
                              "Variant Filter" = FIELD("Variant Filter"),
                              "Lot No. Filter" = FIELD("Lot No. Filter"),
                              "Serial No. Filter" = FIELD("Serial No. Filter");
                Visible = false;
            }
            part(Control1906840407; "Item Planning FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = FIELD("No."),
                              "Date Filter" = FIELD("Date Filter"),
                              "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                              "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter"),
                              "Location Filter" = FIELD("Location Filter"),
                              "Drop Shipment Filter" = FIELD("Drop Shipment Filter"),
                              "Bin Filter" = FIELD("Bin Filter"),
                              "Variant Filter" = FIELD("Variant Filter"),
                              "Lot No. Filter" = FIELD("Lot No. Filter"),
                              "Serial No. Filter" = FIELD("Serial No. Filter");
            }
            part(Control1901796907; "Item Warehouse FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = FIELD("No."),
                              "Date Filter" = FIELD("Date Filter"),
                              "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                              "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter"),
                              "Location Filter" = FIELD("Location Filter"),
                              "Drop Shipment Filter" = FIELD("Drop Shipment Filter"),
                              "Bin Filter" = FIELD("Bin Filter"),
                              "Variant Filter" = FIELD("Variant Filter"),
                              "Lot No. Filter" = FIELD("Lot No. Filter"),
                              "Serial No. Filter" = FIELD("Serial No. Filter");
                Visible = false;
            }
            part(ItemAttributesFactBox; "Item Attributes Factbox")
            {
                ApplicationArea = Basic, Suite;
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(Item)
            {
                Caption = 'Item';
                Image = DataEntry;
                action("&Units of Measure")
                {
                    ApplicationArea = Advanced;
                    Caption = '&Units of Measure';
                    Image = UnitOfMeasure;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Category4;
                    RunObject = Page "Item Units of Measure";
                    RunPageLink = "Item No." = FIELD("No.");
                    Scope = Repeater;
                    ToolTip = 'Set up the different units that the item can be traded in, such as piece, box, or hour.';
                }
                action(Attributes)
                {
                    AccessByPermission = TableData "Item Attribute" = R;
                    ApplicationArea = Advanced;
                    Caption = 'Attributes';
                    Image = Category;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Category4;
                    Scope = Repeater;
                    ToolTip = 'View or edit the item''s attributes, such as color, size, or other characteristics that help to describe the item.';

                    trigger OnAction()
                    begin
                        PAGE.RunModal(PAGE::"Item Attribute Value Editor", Rec);
                        CurrPage.SaveRecord;
                        CurrPage.ItemAttributesFactBox.PAGE.LoadItemAttributesData("No.");
                    end;
                }
                action(FilterByAttributes)
                {
                    AccessByPermission = TableData "Item Attribute" = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Filter by Attributes';
                    Image = EditFilter;
                    Promoted = true;
                    PromotedCategory = Category10;
                    PromotedOnly = true;
                    ToolTip = 'Find items that match specific attributes. To make sure you include recent changes made by other users, clear the filter and then reset it.';

                    trigger OnAction()
                    var
                        ItemAttributeManagement: Codeunit "Item Attribute Management";
                        TypeHelper: Codeunit "Type Helper";
                        CloseAction: Action;
                        FilterText: Text;
                        FilterPageID: Integer;
                        ParameterCount: Integer;
                    begin
                        FilterPageID := PAGE::"Filter Items by Attribute";
                        if ClientTypeManagement.GetCurrentClientType = CLIENTTYPE::Phone then
                            FilterPageID := PAGE::"Filter Items by Att. Phone";

                        CloseAction := PAGE.RunModal(FilterPageID, TempFilterItemAttributesBuffer);
                        if (ClientTypeManagement.GetCurrentClientType <> CLIENTTYPE::Phone) and (CloseAction <> ACTION::LookupOK) then
                            exit;

                        if TempFilterItemAttributesBuffer.IsEmpty then begin
                            ClearAttributesFilter;
                            exit;
                        end;
                        TempItemFilteredFromAttributes.Reset();
                        TempItemFilteredFromAttributes.DeleteAll();
                        ItemAttributeManagement.FindItemsByAttributes(TempFilterItemAttributesBuffer, TempItemFilteredFromAttributes);
                        FilterText := ItemAttributeManagement.GetItemNoFilterText(TempItemFilteredFromAttributes, ParameterCount);

                        if ParameterCount < TypeHelper.GetMaxNumberOfParametersInSQLQuery - 100 then begin
                            FilterGroup(0);
                            MarkedOnly(false);
                            SetFilter("No.", FilterText);
                        end else begin
                            RunOnTempRec := true;
                            ClearMarks;
                            Reset;
                        end;
                    end;
                }
                action(ClearAttributes)
                {
                    AccessByPermission = TableData "Item Attribute" = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Clear Attributes Filter';
                    Image = RemoveFilterLines;
                    Promoted = true;
                    PromotedCategory = Category10;
                    PromotedOnly = true;
                    ToolTip = 'Remove the filter for specific item attributes.';

                    trigger OnAction()
                    begin
                        ClearAttributesFilter;
                        TempItemFilteredFromAttributes.Reset();
                        TempItemFilteredFromAttributes.DeleteAll();
                        RunOnTempRec := false;

                        RestoreTempItemFilteredFromAttributes;
                    end;
                }
                action("Va&riants")
                {
                    ApplicationArea = Planning;
                    Caption = 'Va&riants';
                    Image = ItemVariant;
                    RunObject = Page "Item Variants";
                    RunPageLink = "Item No." = FIELD("No.");
                    ToolTip = 'View how the inventory level of an item will develop over time according to the variant that you select.';
                }
                action("Substituti&ons")
                {
                    ApplicationArea = Suite;
                    Caption = 'Substituti&ons';
                    Image = ItemSubstitution;
                    RunObject = Page "Item Substitution Entry";
                    RunPageLink = Type = CONST(Item),
                                  "No." = FIELD("No.");
                    ToolTip = 'View substitute items that are set up to be sold instead of the item.';
                }
                action(Identifiers)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Identifiers';
                    Image = BarCode;
                    RunObject = Page "Item Identifiers";
                    RunPageLink = "Item No." = FIELD("No.");
                    RunPageView = SORTING("Item No.", "Variant Code", "Unit of Measure Code");
                    ToolTip = 'View a unique identifier for each item that you want warehouse employees to keep track of within the warehouse when using handheld devices. The item identifier can include the item number, the variant code and the unit of measure.';
                }
                action("Cross Re&ferences")
                {
                    ApplicationArea = Advanced;
                    Caption = 'Cross Re&ferences';
                    Image = Change;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedOnly = true;
                    RunObject = Page "Item Cross Reference Entries";
                    RunPageLink = "Item No." = FIELD("No.");
                    Scope = Repeater;
                    ToolTip = 'Set up a customer''s or vendor''s own identification of the selected item. Cross-references to the customer''s item number means that the item number is automatically shown on sales documents instead of the number that you use.';
                }
                action("E&xtended Texts")
                {
                    ApplicationArea = Advanced;
                    Caption = 'E&xtended Texts';
                    Image = Text;
                    RunObject = Page "Extended Text List";
                    RunPageLink = "Table Name" = CONST(Item),
                                  "No." = FIELD("No.");
                    RunPageView = SORTING("Table Name", "No.", "Language Code", "All Language Codes", "Starting Date", "Ending Date");
                    Scope = Repeater;
                    ToolTip = 'Select or set up additional text for the description of the item. Extended text can be inserted under the Description field on document lines for the item.';
                }
                action(Translations)
                {
                    ApplicationArea = Advanced;
                    Caption = 'Translations';
                    Image = Translations;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Category4;
                    RunObject = Page "Item Translations";
                    RunPageLink = "Item No." = FIELD("No."),
                                  "Variant Code" = CONST('');
                    Scope = Repeater;
                    ToolTip = 'Set up translated item descriptions for the selected item. Translated item descriptions are automatically inserted on documents according to the language code.';
                }
                group(Action145)
                {
                    Visible = false;
                    action(AdjustInventory)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Adjust Inventory';
                        Enabled = IsInventoriable;
                        Image = InventoryCalculation;
                        Promoted = true;
                        PromotedCategory = Category4;
                        PromotedOnly = true;
                        Scope = Repeater;
                        ToolTip = 'Increase or decrease the item''s inventory quantity manually by entering a new quantity. Adjusting the inventory quantity manually may be relevant after a physical count or if you do not record purchased quantities.';
                        Visible = IsFoundationEnabled;

                        trigger OnAction()
                        var
                            AdjustInventory: Page "Adjust Inventory";
                        begin
                            Commit();
                            AdjustInventory.SetItem("No.");
                            AdjustInventory.RunModal;
                        end;
                    }
                }
                group(Dimensions)
                {
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    action(DimensionsSingle)
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Dimensions-Single';
                        Image = Dimensions;
                        RunObject = Page "Default Dimensions";
                        RunPageLink = "Table ID" = CONST(27),
                                      "No." = FIELD("No.");
                        Scope = Repeater;
                        ShortCutKey = 'Alt+D';
                        ToolTip = 'View or edit the single set of dimensions that are set up for the selected record.';
                    }
                    action(DimensionsMultiple)
                    {
                        AccessByPermission = TableData Dimension = R;
                        ApplicationArea = Dimensions;
                        Caption = 'Dimensions-&Multiple';
                        Image = DimensionSets;
                        ToolTip = 'View or edit dimensions for a group of records. You can assign dimension codes to transactions to distribute costs and analyze historical information.';

                        trigger OnAction()
                        var
                            Item: Record Item;
                            DefaultDimMultiple: Page "Default Dimensions-Multiple";
                        begin
                            CurrPage.SetSelectionFilter(Item);
                            DefaultDimMultiple.SetMultiRecord(Item, FieldNo("No."));
                            DefaultDimMultiple.RunModal;
                        end;
                    }
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
                        ApplicationArea = Advanced;
                        Caption = 'Ledger E&ntries';
                        Image = ItemLedger;
                        //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                        //PromotedCategory = Category5;
                        RunObject = Page "Item Ledger Entries";
                        RunPageLink = "Item No." = FIELD("No.");
                        RunPageView = SORTING("Item No.")
                                      ORDER(Descending);
                        Scope = Repeater;
                        ShortCutKey = 'Ctrl+F7';
                        ToolTip = 'View the history of transactions that have been posted for the selected record.';
                    }
                    action("&Phys. Inventory Ledger Entries")
                    {
                        ApplicationArea = Warehouse;
                        Caption = '&Phys. Inventory Ledger Entries';
                        Image = PhysicalInventoryLedger;
                        //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                        //PromotedCategory = Category5;
                        RunObject = Page "Phys. Inventory Ledger Entries";
                        RunPageLink = "Item No." = FIELD("No.");
                        RunPageView = SORTING("Item No.");
                        Scope = Repeater;
                        ToolTip = 'View how many units of the item you had in stock at the last physical count.';
                    }
                    action("&Reservation Entries")
                    {
                        ApplicationArea = Reservation;
                        Caption = '&Reservation Entries';
                        Image = ReservationLedger;
                        RunObject = Page "Reservation Entries";
                        RunPageLink = "Reservation Status" = CONST(Reservation),
                                      "Item No." = FIELD("No.");
                        RunPageView = SORTING("Item No.", "Variant Code", "Location Code", "Reservation Status");
                        ToolTip = 'View all reservations that are made for the item, either manually or automatically.';
                    }
                    action("&Value Entries")
                    {
                        ApplicationArea = Advanced;
                        Caption = '&Value Entries';
                        Image = ValueLedger;
                        RunObject = Page "Value Entries";
                        RunPageLink = "Item No." = FIELD("No.");
                        RunPageView = SORTING("Item No.");
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
                            ItemTrackingDocMgt.ShowItemTrackingForMasterData(3, '', "No.", '', '', '', '');
                        end;
                    }
                    action("&Warehouse Entries")
                    {
                        ApplicationArea = Warehouse;
                        Caption = '&Warehouse Entries';
                        Image = BinLedger;
                        RunObject = Page "Warehouse Entries";
                        RunPageLink = "Item No." = FIELD("No.");
                        RunPageView = SORTING("Item No.", "Bin Code", "Location Code", "Variant Code", "Unit of Measure Code", "Lot No.", "Serial No.", "Entry Type", Dedicated);
                        ToolTip = 'View the history of quantities that are registered for the item in warehouse activities. ';
                    }
                }
            }
            group(PricesandDiscounts)
            {
                Caption = 'Prices and Discounts';
                action(Prices_Prices)
                {
                    ApplicationArea = Advanced;
                    Caption = 'Special Prices';
                    Image = Price;
                    Scope = Repeater;
                    ToolTip = 'Set up different prices for the selected item. An item price is automatically used on invoice lines when the specified criteria are met, such as customer, quantity, or ending date.';

                    trigger OnAction()
                    begin
                        ShowPrices();
                    end;
                }
                action(Prices_LineDiscounts)
                {
                    ApplicationArea = Advanced;
                    Caption = 'Special Discounts';
                    Image = LineDiscount;
                    Scope = Repeater;
                    ToolTip = 'Set up different discounts for the selected item. An item discount is automatically granted on invoice lines when the specified criteria are met, such as customer, quantity, or ending date.';

                    trigger OnAction()
                    begin
                        ShowLineDiscounts();
                    end;
                }
                action(PricesDiscountsOverview)
                {
                    ApplicationArea = Suite;
                    Caption = 'Special Prices & Discounts Overview';
                    Image = PriceWorksheet;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Category6;
                    ToolTip = 'View the special prices and line discounts that you grant for this item when certain criteria are met, such as vendor, quantity, or ending date.';

                    trigger OnAction()
                    var
                        SalesPriceAndLineDiscounts: Page "Sales Price and Line Discounts";
                    begin
                        SalesPriceAndLineDiscounts.InitPage(true);
                        SalesPriceAndLineDiscounts.LoadItem(Rec);
                        SalesPriceAndLineDiscounts.RunModal;
                    end;
                }
                action("Sales Price Worksheet")
                {
                    ApplicationArea = Advanced;
                    Caption = 'Sales Price Worksheet';
                    Image = PriceWorksheet;
                    Promoted = true;
                    PromotedCategory = Category6;
                    RunObject = Page "Sales Price Worksheet";
                    ToolTip = 'Change to the unit price for the item or specify how you want to enter changes in the price agreement for one customer, a group of customers, or all customers.';
                    Visible = NOT IsOnPhone;
                }
            }
            group(PeriodicActivities)
            {
                Caption = 'Periodic Activities';
                action("Adjust Cost - Item Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Adjust Cost - Item Entries';
                    Image = AdjustEntries;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Category8;
                    RunObject = Report "Adjust Cost - Item Entries";
                    ToolTip = 'Adjust inventory values in value entries so that you use the correct adjusted cost for updating the general ledger and so that sales and profit statistics are up to date.';
                }
                action("Post Inventory Cost to G/L")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post Inventory Cost to G/L';
                    Image = PostInventoryToGL;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Category8;
                    RunObject = Report "Post Inventory Cost to G/L";
                    ToolTip = 'Post the quantity and value changes to the inventory in the item ledger entries and the value entries when you post inventory transactions, such as sales shipments or purchase receipts.';
                }
                action("Physical Inventory Journal")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Physical Inventory Journal';
                    Image = PhysicalInventory;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Category8;
                    RunObject = Page "Phys. Inventory Journal";
                    ToolTip = 'Select how you want to maintain an up-to-date record of your inventory at different locations.';
                }
                action("Revaluation Journal")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Revaluation Journal';
                    Image = Journal;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Category8;
                    RunObject = Page "Revaluation Journal";
                    ToolTip = 'View or edit the inventory value of items, which you can change, such as after doing a physical inventory.';
                }
            }
            group(RequestApproval)
            {
                Caption = 'Request Approval';
                Image = SendApprovalRequest;
                action(SendApprovalRequest)
                {
                    ApplicationArea = Suite;
                    Caption = 'Send A&pproval Request';
                    Enabled = (NOT OpenApprovalEntriesExist) AND EnabledApprovalWorkflowsExist AND CanRequestApprovalForFlow;
                    Image = SendApprovalRequest;
                    Promoted = true;
                    PromotedCategory = Category7;
                    ToolTip = 'Request approval to change the record.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        if ApprovalsMgmt.CheckItemApprovalsWorkflowEnabled(Rec) then
                            ApprovalsMgmt.OnSendItemForApproval(Rec);
                    end;
                }
                action(CancelApprovalRequest)
                {
                    ApplicationArea = Suite;
                    Caption = 'Cancel Approval Re&quest';
                    Enabled = CanCancelApprovalForRecord OR CanCancelApprovalForFlow;
                    Image = CancelApprovalRequest;
                    Promoted = true;
                    PromotedCategory = Category7;
                    ToolTip = 'Cancel the approval request.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
                    begin
                        ApprovalsMgmt.OnCancelItemApprovalRequest(Rec);
                        WorkflowWebhookManagement.FindAndCancel(RecordId);
                    end;
                }
            }
            group(Workflow)
            {
                Caption = 'Workflow';
                action(CreateApprovalWorkflow)
                {
                    ApplicationArea = Suite;
                    Caption = 'Create Approval Workflow';
                    Enabled = NOT EnabledApprovalWorkflowsExist;
                    Image = CreateWorkflow;
                    ToolTip = 'Set up an approval workflow for creating or changing items, by going through a few pages that will guide you.';

                    trigger OnAction()
                    begin
                        PAGE.RunModal(PAGE::"Item Approval WF Setup Wizard");
                    end;
                }
                action(ManageApprovalWorkflow)
                {
                    ApplicationArea = Suite;
                    Caption = 'Manage Approval Workflow';
                    Enabled = EnabledApprovalWorkflowsExist;
                    Image = WorkflowSetup;
                    ToolTip = 'View or edit existing approval workflows for creating or changing items.';

                    trigger OnAction()
                    var
                        WorkflowManagement: Codeunit "Workflow Management";
                    begin
                        WorkflowManagement.NavigateToWorkflows(DATABASE::Item, EventFilter);
                    end;
                }
            }
            group(Functions)
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("&Create Stockkeeping Unit")
                {
                    AccessByPermission = TableData "Stockkeeping Unit" = R;
                    ApplicationArea = Warehouse;
                    Caption = '&Create Stockkeeping Unit';
                    Image = CreateSKU;
                    ToolTip = 'Create an instance of the item at each location that is set up.';

                    trigger OnAction()
                    var
                        Item: Record Item;
                    begin
                        Item.SetRange("No.", "No.");
                        REPORT.RunModal(REPORT::"Create Stockkeeping Unit", true, false, Item);
                    end;
                }
                action("C&alculate Counting Period")
                {
                    AccessByPermission = TableData "Phys. Invt. Item Selection" = R;
                    ApplicationArea = Warehouse;
                    Caption = 'C&alculate Counting Period';
                    Image = CalculateCalendar;
                    ToolTip = 'Prepare for a physical inventory by calculating which items or SKUs need to be counted in the current period.';

                    trigger OnAction()
                    var
                        Item: Record Item;
                        PhysInvtCountMgt: Codeunit "Phys. Invt. Count.-Management";
                    begin
                        CurrPage.SetSelectionFilter(Item);
                        PhysInvtCountMgt.UpdateItemPhysInvtCount(Item);
                    end;
                }
                action(CopyItem)
                {
                    AccessByPermission = TableData Item = I;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Copy Item';
                    Image = Copy;
                    ToolTip = 'Create a copy of the current item.';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Copy Item", Rec);
                    end;
                }
            }
            action("Requisition Worksheet")
            {
                ApplicationArea = Planning;
                Caption = 'Requisition Worksheet';
                Image = Worksheet;
                RunObject = Page "Req. Worksheet";
                ToolTip = 'Calculate a supply plan to fulfill item demand with purchases or transfers.';
            }
            action("Item Journal")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Item Journal';
                Image = Journals;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "Item Journal";
                ToolTip = 'Open a list of journals where you can adjust the physical quantity of items on inventory.';
            }
            action("Item Reclassification Journal")
            {
                ApplicationArea = Warehouse;
                Caption = 'Item Reclassification Journal';
                Image = Journals;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "Item Reclass. Journal";
                ToolTip = 'Change information on item ledger entries, such as dimensions, location codes, bin codes, and serial or lot numbers.';
            }
            action("Item Tracing")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Item Tracing';
                Image = ItemTracing;
                RunObject = Page "Item Tracing";
                ToolTip = 'Trace where a lot or serial number assigned to the item was used, for example, to find which lot a defective component came from or to find all the customers that have received items containing the defective component.';
            }
            action("Adjust Item Cost/Price")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Adjust Item Cost/Price';
                Image = AdjustItemCost;
                RunObject = Report "Adjust Item Costs/Prices";
                ToolTip = 'Adjusts the Last Direct Cost, Standard Cost, Unit Price, Profit %, or Indirect Cost % fields on selected item or stockkeeping unit cards and for selected filters. For example, you can change the last direct cost by 5% on all items from a specific vendor.';
            }
            action(ApplyTemplate)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Apply Template';
                Ellipsis = true;
                Image = ApplyTemplate;
                ToolTip = 'Apply a template to update one or more entities with your standard settings for a certain type of entity.';
                ObsoleteState = Pending;
                ObsoleteReason = 'This functionality will be replaced by other templates.';
                ObsoleteTag = '16.0';

                trigger OnAction()
                var
                    Item: Record Item;
                    ItemTemplate: Record "Item Template";
                begin
                    CurrPage.SetSelectionFilter(Item);
                    ItemTemplate.UpdateItemsFromTemplate(Item);
                end;
            }
            group(Display)
            {
                Caption = 'Display';
                action(ReportFactBoxVisibility)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show/Hide Power BI Reports';
                    Image = "Report";
                    ToolTip = 'Select if the Power BI FactBox is visible or not.';

                    trigger OnAction()
                    begin
                        // save visibility value into the table
                        CurrPage."Power BI Report FactBox".PAGE.SetFactBoxVisibility(PowerBIVisible);
                    end;
                }
            }
        }
        area(reporting)
        {
            group(AssemblyProduction)
            {
                Caption = 'Assembly/Production';
                action("Assemble to Order - Sales")
                {
                    ApplicationArea = Assembly;
                    Caption = 'Assemble to Order - Sales';
                    Image = "Report";
                    RunObject = Report "Assemble to Order - Sales";
                    ToolTip = 'View key sales figures for assembly components that may be sold either as part of assembly items in assemble-to-order sales or as separate items directly from inventory. Use this report to analyze the quantity, cost, sales, and profit figures of assembly components to support decisions, such as whether to price a kit differently or to stop or start using a particular item in assemblies.';
                }
                action("Where-Used (Top Level)")
                {
                    ApplicationArea = Assembly;
                    Caption = 'Where-Used (Top Level)';
                    Image = "Report";
                    RunObject = Report "Where-Used (Top Level)";
                    ToolTip = 'View where and in what quantities the item is used in the product structure. The report only shows information for the top-level item. For example, if item "A" is used to produce item "B", and item "B" is used to produce item "C", the report will show item B if you run this report for item A. If you run this report for item B, then item C will be shown as where-used.';
                }
                action("Quantity Explosion of BOM")
                {
                    ApplicationArea = Assembly;
                    Caption = 'Quantity Explosion of BOM';
                    Image = "Report";
                    RunObject = Report "Quantity Explosion of BOM";
                    ToolTip = 'View an indented BOM listing for the item or items that you specify in the filters. The production BOM is completely exploded for all levels.';
                }
                group(Costing)
                {
                    Caption = 'Costing';
                    Image = ItemCosts;
                    action("Inventory Valuation - WIP")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory Valuation - WIP';
                        Image = "Report";
                        RunObject = Report "Inventory Valuation - WIP";
                        ToolTip = 'View inventory valuation for selected production orders in your WIP inventory. The report also shows information about the value of consumption, capacity usage and output in WIP. The printed report only shows invoiced amounts, that is, the cost of entries that have been posted as invoiced.';
                    }
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
            }
            group(Inventory)
            {
                Caption = 'Inventory';
                action("Inventory - List")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Inventory - List';
                    Image = "Report";
                    RunObject = Report "Inventory - List";
                    ToolTip = 'View various information about the item, such as name, unit of measure, posting group, shelf number, vendor''s item number, lead time calculation, minimum inventory, and alternate item number. You can also see if the item is blocked.';
                }
                action("Inventory - Availability Plan")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Inventory - Availability Plan';
                    Image = ItemAvailability;
                    RunObject = Report "Inventory - Availability Plan";
                    ToolTip = 'View a list of the quantity of each item in customer, purchase, and transfer orders and the quantity available in inventory. The list is divided into columns that cover six periods with starting and ending dates as well as the periods before and after those periods. The list is useful when you are planning your inventory purchases.';
                }
                action("Item/Vendor Catalog")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item/Vendor Catalog';
                    Image = "Report";
                    RunObject = Report "Item/Vendor Catalog";
                    ToolTip = 'View a list of the vendors for the selected items. For each combination of item and vendor, it shows direct unit cost, lead time calculation and the vendor''s item number.';
                }
                action("Phys. Inventory List")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Phys. Inventory List';
                    Image = "Report";
                    RunObject = Report "Phys. Inventory List";
                    ToolTip = 'View a list of the lines that you have calculated in the Phys. Inventory Journal window. You can use this report during the physical inventory count to mark down actual quantities on hand in the warehouse and compare them to what is recorded in the program.';
                }
                action("Catalog Item Sales")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Catalog Item Sales';
                    Image = "Report";
                    RunObject = Report "Catalog Item Sales";
                    ToolTip = 'View a list of item sales for each catalog item during a selected time period. It can be used to review a company''s sale of catalog items.';
                }
                action("Item Substitutions")
                {
                    ApplicationArea = Suite;
                    Caption = 'Item Substitutions';
                    Image = "Report";
                    RunObject = Report "Item Substitutions";
                    ToolTip = 'View or edit any substitute items that are set up to be traded instead of the item in case it is not available.';
                }
                action("Price List")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Price List';
                    Image = "Report";
                    Promoted = true;
                    PromotedCategory = Category9;
                    RunObject = Report "Price List";
                    ToolTip = 'View, print, or save a list of your items and their prices, for example, to send to customers. You can create the list for specific customers, campaigns, currencies, or other criteria.';
                }
                action("Inventory Cost and Price List")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Inventory Cost and Price List';
                    Image = "Report";
                    RunObject = Report "Inventory Cost and Price List";
                    ToolTip = 'View, print, or save a list of your items and their price and cost information. The report specifies direct unit cost, last direct cost, unit price, profit percentage, and profit.';
                }
                action("Inventory Availability")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Inventory Availability';
                    Image = "Report";
                    RunObject = Report "Inventory Availability";
                    ToolTip = 'View, print, or save a summary of historical inventory transactions with selected items, for example, to decide when to purchase the items. The report specifies quantity on sales order, quantity on purchase order, back orders from vendors, minimum inventory, and whether there are reorders.';
                }
                group("Item Register")
                {
                    Caption = 'Item Register';
                    Image = ItemRegisters;
                    action("Item Register - Quantity")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Register - Quantity';
                        Image = "Report";
                        RunObject = Report "Item Register - Quantity";
                        ToolTip = 'View one or more selected item registers showing quantity. The report can be used to document a register''s contents for internal or external audits.';
                    }
                    action("Item Register - Value")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Register - Value';
                        Image = "Report";
                        RunObject = Report "Item Register - Value";
                        ToolTip = 'View one or more selected item registers showing value. The report can be used to document the contents of a register for internal or external audits.';
                    }
                }
                group(Action130)
                {
                    Caption = 'Costing';
                    Image = ItemCosts;
                    action("Inventory - Cost Variance")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory - Cost Variance';
                        Image = ItemCosts;
                        RunObject = Report "Inventory - Cost Variance";
                        ToolTip = 'View information about selected items, unit of measure, standard cost, and costing method, as well as additional information about item entries: unit amount, direct unit cost, unit cost variance (the difference between the unit amount and unit cost), invoiced quantity, and total variance amount (quantity * unit cost variance). The report can be used primarily if you have chosen the Standard costing method on the item card.';
                    }
                    action("Invt. Valuation - Cost Spec.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Invt. Valuation - Cost Spec.';
                        Image = "Report";
                        RunObject = Report "Invt. Valuation - Cost Spec.";
                        ToolTip = 'View an overview of the current inventory value of selected items and specifies the cost of these items as of the date specified in the Valuation Date field. The report includes all costs, both those posted as invoiced and those posted as expected. For each of the items that you specify when setting up the report, the printed report shows quantity on stock, the cost per unit and the total amount. For each of these columns, the report specifies the cost as the various value entry types.';
                    }
                    action("Compare List")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Compare List';
                        Image = "Report";
                        RunObject = Report "Compare List";
                        ToolTip = 'View a comparison of components for two items. The printout compares the components, their unit cost, cost share and cost per component.';
                    }
                }
                group("Inventory Details")
                {
                    Caption = 'Inventory Details';
                    Image = "Report";
                    action("Inventory - Transaction Detail")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory - Transaction Detail';
                        Image = "Report";
                        RunObject = Report "Inventory - Transaction Detail";
                        ToolTip = 'View transaction details with entries for the selected items for a selected period. The report shows the inventory at the beginning of the period, all of the increase and decrease entries during the period with a running update of the inventory, and the inventory at the close of the period. The report can be used at the close of an accounting period, for example, or for an audit.';
                    }
                    action("Item Charges - Specification")
                    {
                        ApplicationArea = ItemCharges;
                        Caption = 'Item Charges - Specification';
                        Image = "Report";
                        RunObject = Report "Item Charges - Specification";
                        ToolTip = 'View a specification of the direct costs that your company has assigned and posted as item charges. The report shows the various value entries that have been posted as item charges. It includes all costs, both those posted as invoiced and those posted as expected.';
                    }
                    action("Item Age Composition - Quantity")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Age Composition - Quantity';
                        Image = "Report";
                        RunObject = Report "Item Age Composition - Qty.";
                        ToolTip = 'View, print, or save an overview of the current age composition of selected items in your inventory.';
                    }
                    action("Item Expiration - Quantity")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Item Expiration - Quantity';
                        Image = "Report";
                        RunObject = Report "Item Expiration - Quantity";
                        ToolTip = 'View an overview of the quantities of selected items in your inventory whose expiration dates fall within a certain period. The list shows the number of units of the selected item that will expire in a given time period. For each of the items that you specify when setting up the report, the printed document shows the number of units that will expire during each of three periods of equal length and the total inventory quantity of the selected item.';
                    }
                }
                group(Reports)
                {
                    Caption = 'Inventory Statistics';
                    Image = "Report";
                    action("Inventory - Sales Statistics")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Inventory - Sales Statistics';
                        Image = "Report";
                        RunObject = Report "Inventory - Sales Statistics";
                        ToolTip = 'View, print, or save a summary of selected items'' sales per customer, for example, to analyze the profit on individual items or trends in revenues and profit. The report specifies direct unit cost, unit price, sales quantity, sales in LCY, profit percentage, and profit.';
                    }
                    action("Inventory - Customer Sales")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Inventory - Customer Sales';
                        Image = "Report";
                        RunObject = Report "Inventory - Customer Sales";
                        ToolTip = 'View, print, or save a list of customers that have purchased selected items within a selected period, for example, to analyze customers'' purchasing patterns. The report specifies quantity, amount, discount, profit percentage, and profit.';
                    }
                    action("Inventory - Top 10 List")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory - Top 10 List';
                        Image = "Report";
                        RunObject = Report "Inventory - Top 10 List";
                        ToolTip = 'View information about the items with the highest or lowest sales within a selected period. You can also choose that items that are not on hand or have not been sold are not included in the report. The items are sorted by order size within the selected period. The list gives a quick overview of the items that have sold either best or worst, or the items that have the most or fewest units on inventory.';
                    }
                }
                group("Finance Reports")
                {
                    Caption = 'Finance Reports';
                    Image = "Report";
                    action("Inventory Valuation")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory Valuation';
                        Image = "Report";
                        RunObject = Report "Inventory Valuation";
                        ToolTip = 'View, print, or save a list of the values of the on-hand quantity of each inventory item.';
                    }
                    action(Status)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Status';
                        Image = "Report";
                        RunObject = Report Status;
                        ToolTip = 'View, print, or save the status of partially filled or unfilled orders so you can determine what effect filling these orders may have on your inventory.';
                    }
                    action("Item Age Composition - Value")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Age Composition - Value';
                        Image = "Report";
                        RunObject = Report "Item Age Composition - Value";
                        ToolTip = 'View, print, or save an overview of the current age composition of selected items in your inventory.';
                    }
                }
            }
            group(Orders)
            {
                Caption = 'Orders';
                action("Inventory Order Details")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Inventory Order Details';
                    Image = "Report";
                    RunObject = Report "Inventory Order Details";
                    ToolTip = 'View a list of the orders that have not yet been shipped or received and the items in the orders. It shows the order number, customer''s name, shipment date, order quantity, quantity on back order, outstanding quantity and unit price, as well as possible discount percentage and amount. The quantity on back order and outstanding quantity and amount are totaled for each item. The report can be used to find out whether there are currently shipment problems or any can be expected.';
                }
                action("Inventory Purchase Orders")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Inventory Purchase Orders';
                    Image = "Report";
                    RunObject = Report "Inventory Purchase Orders";
                    ToolTip = 'View a list of items on order from vendors. It also shows the expected receipt date and the quantity and amount on back orders. The report can be used, for example, to see when items should be received and whether a reminder of a back order should be issued.';
                }
                action("Inventory - Vendor Purchases")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Inventory - Vendor Purchases';
                    Image = "Report";
                    RunObject = Report "Inventory - Vendor Purchases";
                    ToolTip = 'View a list of the vendors that your company has purchased items from within a selected period. It shows invoiced quantity, amount and discount. The report can be used to analyze a company''s item purchases.';
                }
                action("Inventory - Reorders")
                {
                    ApplicationArea = Planning;
                    Caption = 'Inventory - Reorders';
                    Image = "Report";
                    Promoted = true;
                    PromotedCategory = "Report";
                    RunObject = Report "Inventory - Reorders";
                    ToolTip = 'View a list of items with negative inventory that is sorted by vendor. You can use this report to help decide which items have to be reordered. The report shows how many items are inbound on purchase orders or transfer orders and how many items are in inventory. Based on this information and any defined reorder quantity for the item, a suggested value is inserted in the Qty. to Order field.';
                }
                action("Inventory - Sales Back Orders")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Inventory - Sales Back Orders';
                    Image = "Report";
                    Promoted = true;
                    PromotedCategory = "Report";
                    RunObject = Report "Inventory - Sales Back Orders";
                    ToolTip = 'Shows a list of order lines with shipment dates that are exceeded. The report also shows if there are other items for the customer on back order.';
                }
            }
        }
        area(navigation)
        {
            group(Action126)
            {
                Caption = 'Item';
                action(ApprovalEntries)
                {
                    AccessByPermission = TableData "Approval Entry" = R;
                    ApplicationArea = Suite;
                    Caption = 'Approvals';
                    Image = Approvals;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedOnly = true;
                    ToolTip = 'View a list of the records that are waiting to be approved. For example, you can see who requested the record to be approved, when it was sent, and when it is due to be approved.';

                    trigger OnAction()
                    begin
                        ApprovalsMgmt.OpenApprovalEntriesPage(RecordId);
                    end;
                }
            }
            group(Availability)
            {
                Caption = 'Availability';
                Image = Item;
                action("Items b&y Location")
                {
                    AccessByPermission = TableData Location = R;
                    ApplicationArea = Location;
                    Caption = 'Items b&y Location';
                    Image = ItemAvailbyLoc;
                    ToolTip = 'Show a list of items grouped by location.';

                    trigger OnAction()
                    begin
                        PAGE.Run(PAGE::"Items by Location", Rec);
                    end;
                }
                group("&Item Availability by")
                {
                    Caption = '&Item Availability by';
                    Image = ItemAvailability;
                    action("<Action5>")
                    {
                        ApplicationArea = Advanced;
                        Caption = 'Event';
                        Image = "Event";
                        ToolTip = 'View how the actual and the projected available balance of an item will develop over time according to supply and demand events.';

                        trigger OnAction()
                        begin
                            ItemAvailFormsMgt.ShowItemAvailFromItem(Rec, ItemAvailFormsMgt.ByEvent);
                        end;
                    }
                    action(Period)
                    {
                        ApplicationArea = Advanced;
                        Caption = 'Period';
                        Image = Period;
                        RunObject = Page "Item Availability by Periods";
                        RunPageLink = "No." = FIELD("No."),
                                      "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                                      "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter"),
                                      "Location Filter" = FIELD("Location Filter"),
                                      "Drop Shipment Filter" = FIELD("Drop Shipment Filter"),
                                      "Variant Filter" = FIELD("Variant Filter");
                        ToolTip = 'Show the projected quantity of the item over time according to time periods, such as day, week, or month.';
                    }
                    action(Variant)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Variant';
                        Image = ItemVariant;
                        RunObject = Page "Item Availability by Variant";
                        RunPageLink = "No." = FIELD("No."),
                                      "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                                      "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter"),
                                      "Location Filter" = FIELD("Location Filter"),
                                      "Drop Shipment Filter" = FIELD("Drop Shipment Filter"),
                                      "Variant Filter" = FIELD("Variant Filter");
                        ToolTip = 'View or edit the item''s variants. Instead of setting up each color of an item as a separate item, you can set up the various colors as variants of the item.';
                    }
                    action(Location)
                    {
                        ApplicationArea = Advanced;
                        Caption = 'Location';
                        Image = Warehouse;
                        RunObject = Page "Item Availability by Location";
                        RunPageLink = "No." = FIELD("No."),
                                      "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                                      "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter"),
                                      "Location Filter" = FIELD("Location Filter"),
                                      "Drop Shipment Filter" = FIELD("Drop Shipment Filter"),
                                      "Variant Filter" = FIELD("Variant Filter");
                        ToolTip = 'View the actual and projected quantity of the item per location.';
                    }
                    action("BOM Level")
                    {
                        ApplicationArea = Assembly;
                        Caption = 'BOM Level';
                        Image = BOMLevel;
                        ToolTip = 'View availability figures for items on bills of materials that show how many units of a parent item you can make based on the availability of child items.';

                        trigger OnAction()
                        begin
                            ItemAvailFormsMgt.ShowItemAvailFromItem(Rec, ItemAvailFormsMgt.ByBOM);
                        end;
                    }
                    action("Unit of Measure")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Unit of Measure';
                        Image = UnitOfMeasure;
                        RunObject = Page "Item Availability by UOM";
                        RunPageLink = "No." = FIELD("No."),
                                      "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                                      "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter"),
                                      "Location Filter" = FIELD("Location Filter"),
                                      "Drop Shipment Filter" = FIELD("Drop Shipment Filter"),
                                      "Variant Filter" = FIELD("Variant Filter");
                        ToolTip = 'View the item''s availability by a unit of measure.';
                    }
                }
            }
            group(ActionGroupCRM)
            {
                Caption = 'Dynamics 365 Sales';
                Visible = CRMIntegrationEnabled;
                action(CRMGoToProduct)
                {
                    ApplicationArea = Suite;
                    Caption = 'Product';
                    Image = CoupledItem;
                    ToolTip = 'Open the coupled Dynamics 365 Sales product.';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.ShowCRMEntityFromRecordID(RecordId);
                    end;
                }
                action(CRMSynchronizeNow)
                {
                    AccessByPermission = TableData "CRM Integration Record" = IM;
                    ApplicationArea = Suite;
                    Caption = 'Synchronize';
                    Image = Refresh;
                    ToolTip = 'Send updated data to Dynamics 365 Sales.';

                    trigger OnAction()
                    var
                        Item: Record Item;
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        ItemRecordRef: RecordRef;
                    begin
                        CurrPage.SetSelectionFilter(Item);
                        Item.Next;

                        if Item.Count = 1 then
                            CRMIntegrationManagement.UpdateOneNow(Item.RecordId)
                        else begin
                            ItemRecordRef.GetTable(Item);
                            CRMIntegrationManagement.UpdateMultipleNow(ItemRecordRef);
                        end
                    end;
                }
                group(Coupling)
                {
                    Caption = 'Coupling', Comment = 'Coupling is a noun';
                    Image = LinkAccount;
                    ToolTip = 'Create, change, or delete a coupling between the Business Central record and a Dynamics 365 Sales record.';
                    action(ManageCRMCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = IM;
                        ApplicationArea = Suite;
                        Caption = 'Set Up Coupling';
                        Image = LinkAccount;
                        ToolTip = 'Create or modify the coupling to a Dynamics 365 Sales product.';

                        trigger OnAction()
                        var
                            CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        begin
                            CRMIntegrationManagement.DefineCoupling(RecordId);
                        end;
                    }
                    action(DeleteCRMCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = IM;
                        ApplicationArea = Suite;
                        Caption = 'Delete Coupling';
                        Enabled = CRMIsCoupledToRecord;
                        Image = UnLinkAccount;
                        ToolTip = 'Delete the coupling to a Dynamics 365 Sales product.';

                        trigger OnAction()
                        var
                            CRMCouplingManagement: Codeunit "CRM Coupling Management";
                        begin
                            CRMCouplingManagement.RemoveCoupling(RecordId);
                        end;
                    }
                }
                action(ShowLog)
                {
                    ApplicationArea = Suite;
                    Caption = 'Synchronization Log';
                    Image = Log;
                    ToolTip = 'View integration synchronization jobs for the item table.';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.ShowLog(RecordId);
                    end;
                }
            }
            group("Assembly/Production")
            {
                Caption = 'Assembly/Production';
                Image = Production;
                action(Structure)
                {
                    ApplicationArea = Assembly;
                    Caption = 'Structure';
                    Image = Hierarchy;
                    ToolTip = 'View which child items are used in an item''s assembly BOM or production BOM. Each item level can be collapsed or expanded to obtain an overview or detailed view.';

                    trigger OnAction()
                    var
                        BOMStructure: Page "BOM Structure";
                    begin
                        BOMStructure.InitItem(Rec);
                        BOMStructure.Run;
                    end;
                }
                action("Cost Shares")
                {
                    ApplicationArea = Advanced;
                    Caption = 'Cost Shares';
                    Image = CostBudget;
                    ToolTip = 'View how the costs of underlying items in the BOM roll up to the parent item. The information is organized according to the BOM structure to reflect at which levels the individual costs apply. Each item level can be collapsed or expanded to obtain an overview or detailed view.';

                    trigger OnAction()
                    var
                        BOMCostShares: Page "BOM Cost Shares";
                    begin
                        BOMCostShares.InitItem(Rec);
                        BOMCostShares.Run;
                    end;
                }
                group(Assembly)
                {
                    Caption = 'Assemb&ly';
                    Image = AssemblyBOM;
                    action("<Action32>")
                    {
                        ApplicationArea = Assembly;
                        Caption = 'Assembly BOM';
                        Image = BOM;
                        RunObject = Page "Assembly BOM";
                        RunPageLink = "Parent Item No." = FIELD("No.");
                        ToolTip = 'View or edit the bill of material that specifies which items and resources are required to assemble the assembly item.';
                    }
                    action("Where-Used")
                    {
                        ApplicationArea = Assembly;
                        Caption = 'Where-Used';
                        Image = Track;
                        RunObject = Page "Where-Used List";
                        RunPageLink = Type = CONST(Item),
                                      "No." = FIELD("No.");
                        RunPageView = SORTING(Type, "No.");
                        ToolTip = 'View a list of BOMs in which the item is used.';
                    }
                    action("Calc. Stan&dard Cost")
                    {
                        AccessByPermission = TableData "BOM Component" = R;
                        ApplicationArea = Assembly;
                        Caption = 'Calc. Stan&dard Cost';
                        Image = CalculateCost;
                        ToolTip = 'Calculate the unit cost of the item by rolling up the unit cost of each component and resource in the item''s assembly BOM or production BOM. The unit cost of a parent item must always equals the total of the unit costs of its components, subassemblies, and any resources.';

                        trigger OnAction()
                        begin
                            CalculateStdCost.CalcItem("No.", true);
                        end;
                    }
                    action("Calc. Unit Price")
                    {
                        AccessByPermission = TableData "BOM Component" = R;
                        ApplicationArea = Assembly;
                        Caption = 'Calc. Unit Price';
                        Image = SuggestItemPrice;
                        ToolTip = 'Calculate the unit price based on the unit cost and the profit percentage.';

                        trigger OnAction()
                        begin
                            CalculateStdCost.CalcAssemblyItemPrice("No.");
                        end;
                    }
                }
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
                        RunPageLink = "No." = FIELD("Production BOM No.");
                        ToolTip = 'Open the item''s production bill of material to view or edit its components.';
                    }
                    action(Action29)
                    {
                        AccessByPermission = TableData "BOM Component" = R;
                        ApplicationArea = Manufacturing;
                        Caption = 'Where-Used';
                        Image = "Where-Used";
                        ToolTip = 'View a list of BOMs in which the item is used.';

                        trigger OnAction()
                        var
                            ProdBOMWhereUsed: Page "Prod. BOM Where-Used";
                        begin
                            ProdBOMWhereUsed.SetItem(Rec, WorkDate);
                            ProdBOMWhereUsed.RunModal;
                        end;
                    }
                    action(Action24)
                    {
                        AccessByPermission = TableData "Production BOM Header" = R;
                        ApplicationArea = Manufacturing;
                        Caption = 'Calc. Stan&dard Cost';
                        Image = CalculateCost;
                        ToolTip = 'Calculate the unit cost of the item by rolling up the unit cost of each component and resource in the item''s assembly BOM or production BOM. The unit cost of a parent item must always equals the total of the unit costs of its components, subassemblies, and any resources.';

                        trigger OnAction()
                        begin
                            CalculateStdCost.CalcItem("No.", false);
                        end;
                    }
                }
                group(Statistics)
                {
                    Caption = 'Statistics';
                    Image = Statistics;
                    action(Action16)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Statistics';
                        Image = Statistics;
                        ShortCutKey = 'F7';
                        ToolTip = 'View statistical information, such as the value of posted entries, for the record.';

                        trigger OnAction()
                        var
                            ItemStatistics: Page "Item Statistics";
                        begin
                            ItemStatistics.SetItem(Rec);
                            ItemStatistics.RunModal;
                        end;
                    }
                    action("Entry Statistics")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Entry Statistics';
                        Image = EntryStatistics;
                        RunObject = Page "Item Entry Statistics";
                        RunPageLink = "No." = FIELD("No."),
                                      "Date Filter" = FIELD("Date Filter"),
                                      "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                                      "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter"),
                                      "Location Filter" = FIELD("Location Filter"),
                                      "Drop Shipment Filter" = FIELD("Drop Shipment Filter"),
                                      "Variant Filter" = FIELD("Variant Filter");
                        ToolTip = 'View statistics for item ledger entries.';
                    }
                    action("T&urnover")
                    {
                        ApplicationArea = Suite;
                        Caption = 'T&urnover';
                        Image = Turnover;
                        RunObject = Page "Item Turnover";
                        RunPageLink = "No." = FIELD("No."),
                                      "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                                      "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter"),
                                      "Location Filter" = FIELD("Location Filter"),
                                      "Drop Shipment Filter" = FIELD("Drop Shipment Filter"),
                                      "Variant Filter" = FIELD("Variant Filter");
                        ToolTip = 'View a detailed account of item turnover by periods after you have set the relevant filters for location and variant.';
                    }
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Comment Sheet";
                    RunPageLink = "Table Name" = CONST(Item),
                                  "No." = FIELD("No.");
                    ToolTip = 'View or add comments for the record.';
                }
            }
            group(Sales)
            {
                Caption = 'S&ales';
                Image = Sales;
                action(Sales_Prices)
                {
                    ApplicationArea = Suite;
                    Caption = 'Prices';
                    Image = Price;
                    ToolTip = 'View or set up different prices for the item. An item price is automatically granted on invoice lines when the specified criteria are met, such as vendor, quantity, or ending date.';

                    trigger OnAction()
                    begin
                        ShowPrices();
                    end;
                }
                action(Sales_LineDiscounts)
                {
                    ApplicationArea = Suite;
                    Caption = 'Line Discounts';
                    Image = LineDiscount;
                    ToolTip = 'View or set up different discounts for the item. An item discount is automatically granted on invoice lines when the specified criteria are met, such as vendor, quantity, or ending date.';

                    trigger OnAction()
                    begin
                        ShowLineDiscounts();
                    end;
                }
                action("Prepa&yment Percentages")
                {
                    ApplicationArea = Prepayments;
                    Caption = 'Prepa&yment Percentages';
                    Image = PrepaymentPercentages;
                    RunObject = Page "Sales Prepayment Percentages";
                    RunPageLink = "Item No." = FIELD("No.");
                    ToolTip = 'View or edit the percentages of the price that can be paid as a prepayment. ';
                }
                action(Action37)
                {
                    ApplicationArea = Advanced;
                    Caption = 'Orders';
                    Image = Document;
                    RunObject = Page "Sales Orders";
                    RunPageLink = Type = CONST(Item),
                                  "No." = FIELD("No.");
                    RunPageView = SORTING("Document Type", Type, "No.");
                    ToolTip = 'View a list of ongoing orders for the item.';
                }
                action("Returns Orders")
                {
                    ApplicationArea = Advanced;
                    Caption = 'Returns Orders';
                    Image = ReturnOrder;
                    RunObject = Page "Sales Return Orders";
                    RunPageLink = Type = CONST(Item),
                                  "No." = FIELD("No.");
                    RunPageView = SORTING("Document Type", Type, "No.");
                    ToolTip = 'View ongoing sales or purchase return orders for the item.';
                }
            }
            group(Purchases)
            {
                Caption = '&Purchases';
                Image = Purchasing;
                action("Ven&dors")
                {
                    ApplicationArea = Planning;
                    Caption = 'Ven&dors';
                    Image = Vendor;
                    RunObject = Page "Item Vendor Catalog";
                    RunPageLink = "Item No." = FIELD("No.");
                    RunPageView = SORTING("Item No.");
                    ToolTip = 'View the list of vendors who can supply the item, and at which lead time.';
                }
                action(Prices)
                {
                    ApplicationArea = Advanced;
                    Caption = 'Prices';
                    Image = Price;
                    RunObject = Page "Purchase Prices";
                    RunPageLink = "Item No." = FIELD("No.");
                    RunPageView = SORTING("Item No.");
                    ToolTip = 'View or set up different prices for the item. An item price is automatically granted on invoice lines when the specified criteria are met, such as vendor, quantity, or ending date.';
                }
                action("Line Discounts")
                {
                    ApplicationArea = Advanced;
                    Caption = 'Line Discounts';
                    Image = LineDiscount;
                    RunObject = Page "Purchase Line Discounts";
                    RunPageLink = "Item No." = FIELD("No.");
                    RunPageView = SORTING("Item No.");
                    ToolTip = 'View or set up different discounts for the item. An item discount is automatically granted on invoice lines when the specified criteria are met, such as vendor, quantity, or ending date.';
                }
                action(Action125)
                {
                    ApplicationArea = Prepayments;
                    Caption = 'Prepa&yment Percentages';
                    Image = PrepaymentPercentages;
                    RunObject = Page "Purchase Prepmt. Percentages";
                    RunPageLink = "Item No." = FIELD("No.");
                    ToolTip = 'View or edit the percentages of the price that can be paid as a prepayment. ';
                }
                action(Action40)
                {
                    ApplicationArea = Suite;
                    Caption = 'Orders';
                    Image = Document;
                    RunObject = Page "Purchase Orders";
                    RunPageLink = Type = CONST(Item),
                                  "No." = FIELD("No.");
                    RunPageView = SORTING("Document Type", Type, "No.");
                    ToolTip = 'View a list of ongoing orders for the item.';
                }
                action("Return Orders")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Return Orders';
                    Image = ReturnOrder;
                    RunObject = Page "Purchase Return Orders";
                    RunPageLink = Type = CONST(Item),
                                  "No." = FIELD("No.");
                    RunPageView = SORTING("Document Type", Type, "No.");
                    ToolTip = 'Open the list of ongoing return orders for the item.';
                }
                action("Ca&talog Items")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ca&talog Items';
                    Image = NonStockItem;
                    RunObject = Page "Catalog Item List";
                    ToolTip = 'View the list of items that you do not carry in inventory. ';
                }
            }
            group(PurchPricesandDiscounts)
            {
                Caption = 'Special Purchase Prices & Discounts';
                action("Set Special Prices")
                {
                    ApplicationArea = Suite;
                    Caption = 'Set Special Prices';
                    Image = Price;
                    RunObject = Page "Purchase Prices";
                    RunPageLink = "Item No." = FIELD("No.");
                    RunPageView = SORTING("Item No.");
                    ToolTip = 'Set up different prices for the item. An item price is automatically granted on invoice lines when the specified criteria are met, such as vendor, quantity, or ending date.';
                }
                action("Set Special Discounts")
                {
                    ApplicationArea = Suite;
                    Caption = 'Set Special Discounts';
                    Image = LineDiscount;
                    RunObject = Page "Purchase Line Discounts";
                    RunPageLink = "Item No." = FIELD("No.");
                    ToolTip = 'Set up different discounts for the item. An item discount is automatically granted on invoice lines when the specified criteria are met, such as vendor, quantity, or ending date.';
                }
                action(PurchPricesDiscountsOverview)
                {
                    ApplicationArea = Suite;
                    Caption = 'Special Prices & Discounts Overview';
                    Image = PriceWorksheet;
                    ToolTip = 'View the special prices and line discounts that you grant for this item when certain criteria are met, such as vendor, quantity, or ending date.';

                    trigger OnAction()
                    var
                        PurchasesPriceAndLineDisc: Page "Purchases Price and Line Disc.";
                    begin
                        PurchasesPriceAndLineDisc.LoadItem(Rec);
                        PurchasesPriceAndLineDisc.RunModal;
                    end;
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
                    RunObject = Page "Item Bin Contents";
                    RunPageLink = "Item No." = FIELD("No.");
                    RunPageView = SORTING("Item No.");
                    ToolTip = 'View the quantities of the item in each bin where it exists. You can see all the important parameters relating to bin content, and you can modify certain bin content parameters in this window.';
                }
                action("Stockkeepin&g Units")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Stockkeepin&g Units';
                    Image = SKU;
                    RunObject = Page "Stockkeeping Unit List";
                    RunPageLink = "Item No." = FIELD("No.");
                    RunPageView = SORTING("Item No.");
                    ToolTip = 'Open the item''s SKUs to view or edit instances of the item at different locations or with different variants. ';
                }
            }
            group(Service)
            {
                Caption = 'Service';
                Image = ServiceItem;
                action("Ser&vice Items")
                {
                    ApplicationArea = Service;
                    Caption = 'Ser&vice Items';
                    Image = ServiceItem;
                    RunObject = Page "Service Items";
                    RunPageLink = "Item No." = FIELD("No.");
                    RunPageView = SORTING("Item No.");
                    ToolTip = 'View instances of the item as service items, such as machines that you maintain or repair for customers through service orders. ';
                }
                action(Troubleshooting)
                {
                    AccessByPermission = TableData "Service Header" = R;
                    ApplicationArea = Service;
                    Caption = 'Troubleshooting';
                    Image = Troubleshoot;
                    ToolTip = 'View or edit information about technical problems with a service item.';

                    trigger OnAction()
                    var
                        TroubleshootingHeader: Record "Troubleshooting Header";
                    begin
                        TroubleshootingHeader.ShowForItem(Rec);
                    end;
                }
                action("Troubleshooting Setup")
                {
                    ApplicationArea = Service;
                    Caption = 'Troubleshooting Setup';
                    Image = Troubleshoot;
                    RunObject = Page "Troubleshooting Setup";
                    RunPageLink = Type = CONST(Item),
                                  "No." = FIELD("No.");
                    ToolTip = 'View or edit your settings for troubleshooting service items.';
                }
            }
            group(Resources)
            {
                Caption = 'Resources';
                Image = Resource;
                action("Resource &Skills")
                {
                    ApplicationArea = Service;
                    Caption = 'Resource &Skills';
                    Image = ResourceSkills;
                    RunObject = Page "Resource Skills";
                    RunPageLink = Type = CONST(Item),
                                  "No." = FIELD("No.");
                    ToolTip = 'View the assignment of skills to resources, items, service item groups, and service items. You can use skill codes to allocate skilled resources to service items or items that need special skills for servicing.';
                }
                action("Skilled R&esources")
                {
                    AccessByPermission = TableData "Service Header" = R;
                    ApplicationArea = Service;
                    Caption = 'Skilled R&esources';
                    Image = ResourceSkills;
                    ToolTip = 'View a list of all registered resources with information about whether they have the skills required to service the particular service item group, item, or service item.';

                    trigger OnAction()
                    var
                        ResourceSkill: Record "Resource Skill";
                    begin
                        Clear(SkilledResourceList);
                        SkilledResourceList.Initialize(ResourceSkill.Type::Item, "No.", Description);
                        SkilledResourceList.RunModal;
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
        SocialListeningMgt: Codeunit "Social Listening Management";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        if SocialListeningSetupVisible then
            SocialListeningMgt.GetItemFactboxVisibility(Rec, SocialListeningSetupVisible, SocialListeningVisible);

        if CRMIntegrationEnabled then
            CRMIsCoupledToRecord := CRMCouplingManagement.IsRecordCoupledToCRM(RecordId);

        OpenApprovalEntriesExist := ApprovalsMgmt.HasOpenApprovalEntries(RecordId);

        CanCancelApprovalForRecord := ApprovalsMgmt.CanCancelApprovalForRecord(RecordId);
        CurrPage.ItemAttributesFactBox.PAGE.LoadItemAttributesData("No.");

        WorkflowWebhookManagement.GetCanRequestAndCanCancel(RecordId, CanRequestApprovalForFlow, CanCancelApprovalForFlow);

        SetWorkflowManagementEnabledState;

        // Contextual Power BI FactBox: send data to filter the report in the FactBox
        CurrPage."Power BI Report FactBox".PAGE.SetCurrentListSelection("No.", false, PowerBIVisible);
    end;

    trigger OnAfterGetRecord()
    begin
        EnableControls;
    end;

    trigger OnFindRecord(Which: Text): Boolean
    var
        Found: Boolean;
    begin
        if RunOnTempRec then begin
            TempItemFilteredFromAttributes.Copy(Rec);
            Found := TempItemFilteredFromAttributes.Find(Which);
            if Found then
                Rec := TempItemFilteredFromAttributes;
            exit(Found);
        end;
        exit(Find(Which));
    end;

    trigger OnInit()
    begin
        CurrPage."Power BI Report FactBox".PAGE.InitFactBox(CurrPage.ObjectId(false), CurrPage.Caption, PowerBIVisible);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        ResultSteps: Integer;
    begin
        if RunOnTempRec then begin
            TempItemFilteredFromAttributes.Copy(Rec);
            ResultSteps := TempItemFilteredFromAttributes.Next(Steps);
            if ResultSteps <> 0 then
                Rec := TempItemFilteredFromAttributes;
            exit(ResultSteps);
        end;
        exit(Next(Steps));
    end;

    trigger OnOpenPage()
    var
        SocialListeningSetup: Record "Social Listening Setup";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        ClientTypeManagement: Codeunit "Client Type Management";
    begin
        CRMIntegrationEnabled := CRMIntegrationManagement.IsCRMIntegrationEnabled;
        with SocialListeningSetup do
            SocialListeningSetupVisible := Get and "Show on Customers" and "Accept License Agreement" and ("Solution ID" <> '');
        IsFoundationEnabled := ApplicationAreaMgmtFacade.IsFoundationEnabled;
        SetWorkflowManagementEnabledState;
        IsOnPhone := ClientTypeManagement.GetCurrentClientType = CLIENTTYPE::Phone;
    end;

    var
        TempFilterItemAttributesBuffer: Record "Filter Item Attributes Buffer" temporary;
        TempItemFilteredFromAttributes: Record Item temporary;
        TempItemFilteredFromPickItem: Record Item temporary;
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        CalculateStdCost: Codeunit "Calculate Standard Cost";
        ItemAvailFormsMgt: Codeunit "Item Availability Forms Mgt";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        ClientTypeManagement: Codeunit "Client Type Management";
        SkilledResourceList: Page "Skilled Resource List";
        IsFoundationEnabled: Boolean;
        [InDataSet]
        SocialListeningSetupVisible: Boolean;
        [InDataSet]
        SocialListeningVisible: Boolean;
        CRMIntegrationEnabled: Boolean;
        CRMIsCoupledToRecord: Boolean;
        OpenApprovalEntriesExist: Boolean;
        EnabledApprovalWorkflowsExist: Boolean;
        CanCancelApprovalForRecord: Boolean;
        IsOnPhone: Boolean;
        RunOnTempRec: Boolean;
        EventFilter: Text;
        PowerBIVisible: Boolean;
        CanRequestApprovalForFlow: Boolean;
        CanCancelApprovalForFlow: Boolean;
        [InDataSet]
        IsNonInventoriable: Boolean;
        [InDataSet]
        IsInventoriable: Boolean;
        RunOnPickItem: Boolean;

    procedure SelectActiveItems(): Text
    var
        Item: Record Item;
    begin
        exit(SelectInItemList(Item));
    end;

    procedure SelectActiveItemsForSale(): Text
    var
        Item: Record Item;
    begin
        Item.SetRange("Sales Blocked", false);
        exit(SelectInItemList(Item));
    end;

    procedure SelectActiveItemsForPurchase(): Text
    var
        Item: Record Item;
    begin
        Item.SetRange("Purchasing Blocked", false);
        exit(SelectInItemList(Item));
    end;

    procedure SelectInItemList(var Item: Record Item): Text
    var
        ItemListPage: Page "Item List";
    begin
        Item.SetRange(Blocked, false);
        ItemListPage.SetTableView(Item);
        ItemListPage.LookupMode(true);
        if ItemListPage.RunModal = ACTION::LookupOK then
            exit(ItemListPage.GetSelectionFilter);
    end;

    procedure GetSelectionFilter(): Text
    var
        Item: Record Item;
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        CurrPage.SetSelectionFilter(Item);
        exit(SelectionFilterManagement.GetSelectionFilterForItem(Item));
    end;

    procedure SetSelection(var Item: Record Item)
    begin
        CurrPage.SetSelectionFilter(Item);
    end;

    local procedure EnableControls()
    begin
        IsNonInventoriable := IsNonInventoriableType;
        IsInventoriable := IsInventoriableType;
    end;

    local procedure SetWorkflowManagementEnabledState()
    var
        WorkflowManagement: Codeunit "Workflow Management";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        EventFilter := WorkflowEventHandling.RunWorkflowOnSendItemForApprovalCode + '|' +
          WorkflowEventHandling.RunWorkflowOnItemChangedCode;

        EnabledApprovalWorkflowsExist := WorkflowManagement.EnabledWorkflowExist(DATABASE::Item, EventFilter);
    end;

    local procedure ClearAttributesFilter()
    begin
        ClearMarks;
        MarkedOnly(false);
        TempFilterItemAttributesBuffer.Reset();
        TempFilterItemAttributesBuffer.DeleteAll();
        FilterGroup(0);
        SetRange("No.");
    end;

    procedure SetTempFilteredItemRec(var Item: Record Item)
    begin
        TempItemFilteredFromAttributes.Reset();
        TempItemFilteredFromAttributes.DeleteAll();

        TempItemFilteredFromPickItem.Reset();
        TempItemFilteredFromPickItem.DeleteAll();

        RunOnTempRec := true;
        RunOnPickItem := true;

        if Item.FindSet then
            repeat
                TempItemFilteredFromAttributes := Item;
                TempItemFilteredFromAttributes.Insert();
                TempItemFilteredFromPickItem := Item;
                TempItemFilteredFromPickItem.Insert();
            until Item.Next = 0;
    end;

    local procedure RestoreTempItemFilteredFromAttributes()
    begin
        if not RunOnPickItem then
            exit;

        TempItemFilteredFromAttributes.Reset();
        TempItemFilteredFromAttributes.DeleteAll();
        RunOnTempRec := true;

        if TempItemFilteredFromPickItem.FindSet then
            repeat
                TempItemFilteredFromAttributes := TempItemFilteredFromPickItem;
                TempItemFilteredFromAttributes.Insert();
            until TempItemFilteredFromPickItem.Next = 0;
    end;

    local procedure ShowLineDiscounts()
    var
        SalesLineDiscount: Record "Sales Line Discount";
    begin
        SalesLineDiscount.SetCurrentKey(Type, Code);
        SalesLineDiscount.SetRange(Type, SalesLineDiscount.Type::Item);
        SalesLineDiscount.SetRange(Code, "No.");
        Page.Run(Page::"Sales Line Discounts", SalesLineDiscount);
    end;

    local procedure ShowPrices()
    var
        SalesPrice: Record "Sales Price";
    begin
        SalesPrice.SetCurrentKey("Item No.");
        SalesPrice.SetRange("Item No.", "No.");
        Page.Run(Page::"Sales Prices", SalesPrice);
    end;
}

