page 99000852 "Planning Worksheet"
{
    AdditionalSearchTerms = 'supply planning,mrp,mps';
    ApplicationArea = Planning;
    AutoSplitKey = true;
    Caption = 'Planning Worksheets';
    DataCaptionFields = "Journal Batch Name";
    DelayedInsert = true;
    MultipleNewLines = true;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Requisition Line";
    SourceTableView = where(Type = const(Item));
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            field(CurrentWkshBatchName; CurrentWkshBatchName)
            {
                ApplicationArea = Planning;
                Caption = 'Name';
                ToolTip = 'Specifies the name of the journal batch of the planning worksheet.';

                trigger OnLookup(var Text: Text): Boolean
                begin
                    CurrPage.SaveRecord();
                    ReqJnlManagement.LookupName(CurrentWkshBatchName, Rec);
                    CurrPage.Update(false);

                    OnAfterLookupCurrentJnlBatchName(Rec, CurrentWkshBatchName);
                end;

                trigger OnValidate()
                begin
                    ReqJnlManagement.CheckName(CurrentWkshBatchName, Rec);
                    CurrentWkshBatchNameOnAfterVal();
                end;
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field(Warning; Warning)
                {
                    ApplicationArea = Planning;
                    Caption = 'Warning';
                    Editable = false;
                    OptionCaption = ' ,Emergency,Exception,Attention';
                    ToolTip = 'Specifies a warning text for any planning line that is created for an unusual situation.';

                    trigger OnDrillDown()
                    begin
                        PlanningTransparency.SetCurrReqLine(Rec);
                        PlanningTransparency.DrillDownUntrackedQty('');
                    end;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the type of requisition worksheet line you are creating.';
                    Visible = false;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnValidate()
                    var
                        Item: Record "Item";
                    begin
                        PlanningWkshManagement.GetDescriptionAndRcptName(Rec, ItemDescription, RoutingDescription);
                        if "Variant Code" = '' then
                            VariantCodeMandatory := Item.IsVariantMandatory(Type = Type::Item, "No.");
                    end;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                    ShowMandatory = VariantCodeMandatory;

                    trigger OnValidate()
                    var
                        Item: Record "Item";
                    begin
                        if "Variant Code" = '' then
                            VariantCodeMandatory := Item.IsVariantMandatory(Type = Type::Item, "No.");
                    end;
                }
                field("Planning Level"; "Planning Level")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Indicates the planning level of the item in multi-level production orders. The planning level is calculated only for items that have Make-to-Order specified in the Manufacturing Policy field.';
                    Visible = false;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the bin of the item on the line.';
                    Visible = false;
                }
                field("Action Message"; Rec."Action Message")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies an action to take to rebalance the demand-supply situation.';
                }
                field("Accept Action Message"; Rec."Accept Action Message")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies whether to accept the action message proposed for the line.';
                }
                field("Original Due Date"; Rec."Original Due Date")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the due date stated on the production or purchase order, when an action message proposes to reschedule an order.';
                }
                field("Order Date"; Rec."Order Date")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the date when the related order was created.';
                    Visible = false;
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the date when you can expect to receive the items.';
                }
                field("Transfer Shipment Date"; Rec."Transfer Shipment Date")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the shipment date of the transfer order proposal.';
                    Visible = false;
                }
                field("Starting Date-Time"; Rec."Starting Date-Time")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the starting date and the starting time, which are combined in a format called "starting date-time".';
                }
                field("Starting Time"; Rec."Starting Time")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the starting time of the manufacturing process.';
                    Visible = false;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the starting date of the manufacturing process, if the planned supply is a production order.';
                    Visible = false;
                }
                field("Ending Date-Time"; Rec."Ending Date-Time")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the ending date and the ending time, which are combined in a format called "ending date-time".';
                }
                field("Ending Time"; Rec."Ending Time")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the ending time for the manufacturing process.';
                    Visible = false;
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the ending date of the manufacturing process, if the planned supply is a production order.';
                    Visible = false;
                }
                field("Low-Level Code"; Rec."Low-Level Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the planning level of this item entry in the planning worksheet.';
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies text that describes the entry.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies additional text describing the entry, or a remark about the requisition worksheet line.';
                    Visible = false;
                }
                field("Production BOM No."; Rec."Production BOM No.")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the production BOM number for this production order.';
                    Visible = false;
                }
                field("Production BOM Version Code"; Rec."Production BOM Version Code")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the version code of the BOM.';
                    Visible = false;
                }
                field("Routing No."; Rec."Routing No.")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the routing number.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        PlanningWkshManagement.GetDescriptionAndRcptName(Rec, ItemDescription, RoutingDescription);
                    end;
                }
                field("Routing Version Code"; Rec."Routing Version Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the version code of the routing.';
                    Visible = false;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("ShortcutDimCode[3]"; ShortcutDimCode[3])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,3';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(3),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    ToolTip = 'Specifies the code for Shortcut Dimension 3.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(3, ShortcutDimCode[3]);
                    end;
                }
                field("ShortcutDimCode[4]"; ShortcutDimCode[4])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,4';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(4),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    ToolTip = 'Specifies the code for Shortcut Dimension 4.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(4, ShortcutDimCode[4]);
                    end;
                }
                field("ShortcutDimCode[5]"; ShortcutDimCode[5])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,5';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(5),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    ToolTip = 'Specifies the code for Shortcut Dimension 5.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(5, ShortcutDimCode[5]);
                    end;
                }
                field("ShortcutDimCode[6]"; ShortcutDimCode[6])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,6';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(6),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    ToolTip = 'Specifies the code for Shortcut Dimension 6.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(6, ShortcutDimCode[6]);
                    end;
                }
                field("ShortcutDimCode[7]"; ShortcutDimCode[7])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,7';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(7),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    ToolTip = 'Specifies the code for Shortcut Dimension 7.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(7, ShortcutDimCode[7]);
                    end;
                }
                field("ShortcutDimCode[8]"; ShortcutDimCode[8])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,8';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(8),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    ToolTip = 'Specifies the code for Shortcut Dimension 8.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(8, ShortcutDimCode[8]);
                    end;
                }
                field("Transfer-from Code"; Rec."Transfer-from Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code of the location that items are transferred from.';
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies a code for an inventory location where the items that are being ordered will be registered.';
                    Visible = false;
                }
                field("Original Quantity"; Rec."Original Quantity")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the quantity stated on the production or purchase order, when an action message proposes to change the quantity on an order.';
                }
                field("MPS Order"; Rec."MPS Order")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies whether the requisition worksheet line is an MPS order, that is, whether it is linked to a demand forecast or a sales order.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the number of units of the item.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                    Visible = false;
                }
                field("Replenishment System"; Rec."Replenishment System")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies which kind of order to use to create replenishment orders and order proposals.';
                    Visible = false;
                }
                field("Supply From"; Rec."Supply From")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                    ToolTip = 'Specifies a value, according to the selected replenishment system, before a supply order can be created for the line.';
                }
                field("Ref. Order Type"; Rec."Ref. Order Type")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies whether the order is a purchase order, a production order, or a transfer order.';
                }
                field("Ref. Order No."; Rec."Ref. Order No.")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the number of the relevant production or purchase order.';
                }
                field("Ref. Order Status"; Rec."Ref. Order Status")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the status of the production order.';
                }
                field("Ref. Line No."; Rec."Ref. Line No.")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the number of the purchase or production order line.';
                    Visible = false;
                }
                field("Planning Flexibility"; Rec."Planning Flexibility")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies whether the supply, represented by the requisition worksheet line, is considered by the planning system, when calculating action messages.';
                    Visible = false;
                }
                field("Blanket Purch. Order Exists"; Rec."Blanket Purch. Order Exists")
                {
                    ApplicationArea = Planning;
                    BlankZero = true;
                    ToolTip = 'Specifies if a blanket purchase order exists for the item on the requisition line.';
                    Visible = false;
                }
                field("Reserved Quantity"; Rec."Reserved Quantity")
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies how many units of this item have been reserved.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        ShowReservationEntries(true);
                    end;
                }
                field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
                    Visible = false;
                }
                field("Unit Cost"; Rec."Unit Cost")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the cost of one unit of the item or resource on the line.';
                    Visible = false;
                }
                field("Gen. Business Posting Group"; Rec."Gen. Business Posting Group")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the code of the general business posting group to be used for the item when you post the planning worksheet.';
                    Visible = false;
                }
                field("Cost Amount"; Rec."Cost Amount")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the total costs for the requisition worksheet line.';
                    Visible = false;
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the number of the vendor who will ship the items in the purchase order.';
                    Visible = false;
                }
            }
            group(Control56)
            {
                ShowCaption = false;
                fixed(Control1902454301)
                {
                    ShowCaption = false;
                    group("Item Description")
                    {
                        Caption = 'Item Description';
                        field(ItemDescription; ItemDescription)
                        {
                            ApplicationArea = Planning;
                            Editable = false;
                            ShowCaption = false;
                        }
                    }
                    group("Routing Description")
                    {
                        Caption = 'Routing Description';
                        field(RoutingDescription; RoutingDescription)
                        {
                            ApplicationArea = Planning;
                            Caption = 'Routing Description';
                            Editable = false;
                            ToolTip = 'Specifies a description of the routing for the item that is entered on the line.';
                        }
                    }
                }
            }
        }
        area(factboxes)
        {
            part(Control9; "Item Replenishment FactBox")
            {
                ApplicationArea = Planning;
                SubPageLink = "No." = FIELD("No.");
                Visible = false;
            }
            part(Control11; "Item Planning FactBox")
            {
                ApplicationArea = Planning;
                SubPageLink = "No." = FIELD("No.");
            }
            part(Control15; "Untracked Plng. Elements Part")
            {
                ApplicationArea = Planning;
                SubPageLink = "Worksheet Template Name" = FIELD("Worksheet Template Name"),
                              "Worksheet Batch Name" = FIELD("Journal Batch Name"),
                              "Worksheet Line No." = FIELD("Line No.");
            }
            part(Control13; "Item Warehouse FactBox")
            {
                ApplicationArea = Planning;
                SubPageLink = "No." = FIELD("No.");
                Visible = false;
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDimensions();
                        CurrPage.SaveRecord();
                    end;
                }
                action("Item &Tracking Lines")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Item &Tracking Lines';
                    Image = ItemTrackingLines;
                    ShortCutKey = 'Ctrl+Alt+I';
                    ToolTip = 'View or edit serial numbers and lot numbers that are assigned to the item on the document or journal line.';

                    trigger OnAction()
                    begin
                        OpenItemTrackingLines();
                    end;
                }
            }
            group("&Item")
            {
                Caption = '&Item';
                Image = Item;
                action(Components)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Components';
                    Image = Components;
                    RunObject = Page "Planning Components";
                    RunPageLink = "Worksheet Template Name" = FIELD("Worksheet Template Name"),
                                  "Worksheet Batch Name" = FIELD("Journal Batch Name"),
                                  "Worksheet Line No." = FIELD("Line No.");
                    ToolTip = 'View or edit the production order components of the parent item on the line.';
                    ShortCutKey = 'Ctrl+Alt+C';
                }
                action("Ro&uting")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Ro&uting';
                    Image = Route;
                    RunObject = Page "Planning Routing";
                    RunPageLink = "Worksheet Template Name" = FIELD("Worksheet Template Name"),
                                  "Worksheet Batch Name" = FIELD("Journal Batch Name"),
                                  "Worksheet Line No." = FIELD("Line No.");
                    ToolTip = 'View or edit the operations list of the parent item on the line.';
                    ShortCutKey = 'Ctrl+Alt+R';
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
                        begin
                            ItemAvailFormsMgt.ShowItemAvailFromReqLine(Rec, ItemAvailFormsMgt.ByEvent())
                        end;
                    }
                    action(Period)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Period';
                        Image = Period;
                        ToolTip = 'View the projected quantity of the item over time according to time periods, such as day, week, or month.';

                        trigger OnAction()
                        begin
                            ItemAvailFormsMgt.ShowItemAvailFromReqLine(Rec, ItemAvailFormsMgt.ByPeriod())
                        end;
                    }
                    action(Variant)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Variant';
                        Image = ItemVariant;
                        ToolTip = 'View or edit the item''s variants. Instead of setting up each color of an item as a separate item, you can set up the various colors as variants of the item.';

                        trigger OnAction()
                        begin
                            ItemAvailFormsMgt.ShowItemAvailFromReqLine(Rec, ItemAvailFormsMgt.ByVariant())
                        end;
                    }
                    action(Location)
                    {
                        AccessByPermission = TableData Location = R;
                        ApplicationArea = Location;
                        Caption = 'Location';
                        Image = Warehouse;
                        ToolTip = 'View the actual and projected quantity of the item per location.';

                        trigger OnAction()
                        begin
                            ItemAvailFormsMgt.ShowItemAvailFromReqLine(Rec, ItemAvailFormsMgt.ByLocation())
                        end;
                    }
                    action(Lot)
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Lot';
                        Image = LotInfo;
                        RunObject = Page "Item Availability by Lot No.";
                        RunPageLink = "No." = field("No."),
                            "Location Filter" = field("Location Code"),
                            "Variant Filter" = field("Variant Code");
                        ToolTip = 'View the current and projected quantity of the item in each lot.';
                    }
                    action("BOM Level")
                    {
                        ApplicationArea = Assembly;
                        Caption = 'BOM Level';
                        Image = BOMLevel;
                        ToolTip = 'View availability figures for items on bills of materials that show how many units of a parent item you can make based on the availability of child items.';

                        trigger OnAction()
                        begin
                            ItemAvailFormsMgt.ShowItemAvailFromReqLine(Rec, ItemAvailFormsMgt.ByBOM())
                        end;
                    }
#if not CLEAN21
                    action(Timeline)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Timeline';
                        Image = Timeline;
                        ToolTip = 'Get a graphical view of an item''s projected inventory based on future supply and demand events, with or without planning suggestions. The result is a graphical representation of the inventory profile.';
                        Visible = false;
                        ObsoleteState = Pending;
                        ObsoleteReason = 'TimelineVisualizer control has been deprecated.';
                        ObsoleteTag = '21.0';

                        trigger OnAction()
                        begin
                            ShowTimeline(Rec);
                        end;
                    }
#endif
                }
            }
        }
        area(processing)
        {
            action("Delete All")
            {
                ApplicationArea = Planning;
                Caption = 'Delete all lines in worksheet';
                Image = Delete;
                Tooltip = 'Delete all lines in the current worksheet, disregarding any filters.';

                trigger OnAction()
                begin
                    Rec.ClearPlanningWorksheet(false);
                end;
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";

                separator(Action109)
                {
                }
                action("Calculate &Net Change Plan")
                {
                    ApplicationArea = Planning;
                    Caption = 'Calculate &Net Change Plan';
                    Ellipsis = true;
                    Image = CalculatePlanChange;
                    ToolTip = 'Plan only for items that had the following types of changes to their demand-supply pattern since the last planning run: 1) Change in demand for the item, such as forecast, sales, or component lines. 2) Change in the master data or in the planned supply for the item, such as changes to the BOM or routing, changes to planning parameters, or unplanned inventory differences.';

                    trigger OnAction()
                    var
                        CalcPlan: Report "Calculate Plan - Plan. Wksh.";
                    begin
                        CalcPlan.SetTemplAndWorksheet("Worksheet Template Name", "Journal Batch Name", false);
                        CalcPlan.RunModal();

                        if not Find('-') then
                            SetUpNewLine(Rec);

                        Clear(CalcPlan);
                    end;
                }
                action(CalculateRegenerativePlan)
                {
                    ApplicationArea = Planning;
                    Caption = 'Calculate Regenerative Plan';
                    Ellipsis = true;
                    Image = CalculateRegenerativePlan;
                    ToolTip = 'Plan for all items, regardless of changes since the previous planning run. You calculate a regenerative plan when there are changes to master data or capacity, such as shop calendars, that affect all items and therefore the whole supply plan.';

                    trigger OnAction()
                    var
                        CalcPlan: Report "Calculate Plan - Plan. Wksh.";
                    begin
                        CalcPlan.SetTemplAndWorksheet("Worksheet Template Name", "Journal Batch Name", true);
                        CalcPlan.RunModal();

                        if not Find('-') then
                            SetUpNewLine(Rec);

                        Clear(CalcPlan);
                    end;
                }
                action("Get &Action Messages")
                {
                    ApplicationArea = Planning;
                    Caption = 'Get &Action Messages';
                    Ellipsis = true;
                    Image = GetActionMessages;
                    ToolTip = 'Obtain an immediate view of the effect of schedule changes, without running a regenerative or net change planning process. This function serves as a short-term planning tool by issuing action messages to alert the user of any modifications made since the last regenerative or net change plan was calculated.';

                    trigger OnAction()
                    begin
                        GetActionMessages();

                        if not Find('-') then
                            SetUpNewLine(Rec);
                    end;
                }
                separator(Action32)
                {
                }
                action("Re&fresh Planning Line")
                {
                    ApplicationArea = Planning;
                    Caption = 'Re&fresh Planning Line';
                    Ellipsis = true;
                    Image = RefreshPlanningLine;
                    ToolTip = 'Update the selected planning line with any changes that are made to planning components and routing lines since the planning line was created.';

                    trigger OnAction()
                    var
                        ReqLine: Record "Requisition Line";
                    begin
                        ReqLine.SetRange("Worksheet Template Name", "Worksheet Template Name");
                        ReqLine.SetRange("Journal Batch Name", "Journal Batch Name");
                        ReqLine.SetRange("Line No.", "Line No.");

                        REPORT.RunModal(REPORT::"Refresh Planning Demand", true, false, ReqLine);
                    end;
                }
                separator(Action42)
                {
                }
                action("&Get Error Log")
                {
                    ApplicationArea = Planning;
                    Caption = '&Get Error Log';
                    Image = ErrorLog;
                    RunObject = Page "Planning Error Log";
                    RunPageLink = "Worksheet Template Name" = FIELD("Worksheet Template Name"),
                                  "Journal Batch Name" = FIELD("Journal Batch Name");
                    ToolTip = 'View detailed information for planning lines with a value in the Warning field.';
                }
                separator(Action113)
                {
                }
                action(CarryOutActionMessage)
                {
                    ApplicationArea = Planning;
                    Caption = 'Carry &Out Action Message';
                    Ellipsis = true;
                    Image = CarryOutActionMessage;
                    ToolTip = 'Use a batch job to help you create actual supply orders from the order proposals.';

                    trigger OnAction()
                    begin
                        CarryOutActionMsg();
                        CurrPage.Update(true);
                    end;
                }
                separator(Action19)
                {
                }
                action("&Reserve")
                {
                    ApplicationArea = Reservation;
                    Caption = '&Reserve';
                    Image = Reserve;
                    ToolTip = 'Reserve the quantity that is required on the document line that you opened this window for.';

                    trigger OnAction()
                    begin
                        CurrPage.SaveRecord();
                        ShowReservation();
                    end;
                }
                action(OrderTracking)
                {
                    ApplicationArea = Planning;
                    Caption = 'Order &Tracking';
                    Image = OrderTracking;
                    ToolTip = 'Tracks the connection of a supply to its corresponding demand. This can help you find the original demand that created a specific production order or purchase order.';

                    trigger OnAction()
                    var
                        TrackingForm: Page "Order Tracking";
                    begin
                        TrackingForm.SetReqLine(Rec);
                        TrackingForm.RunModal();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(CarryOutActionMessage_Promoted; CarryOutActionMessage)
                {
                }
                actionref("Re&fresh Planning Line_Promoted"; "Re&fresh Planning Line")
                {
                }
                actionref("&Reserve_Promoted"; "&Reserve")
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Prepare', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(CalculateRegenerativePlan_Promoted; CalculateRegenerativePlan)
                {
                }
                actionref("Get &Action Messages_Promoted"; "Get &Action Messages")
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Line', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref(OrderTracking_Promoted; OrderTracking)
                {
                }
                actionref("Item &Tracking Lines_Promoted"; "Item &Tracking Lines")
                {
                }
                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref(Components_Promoted; Components)
                {
                }
                actionref("Ro&uting_Promoted"; "Ro&uting")
                {
                }
            }
            group(Category_Category6)
            {
                Caption = 'Item', Comment = 'Generated from the PromotedActionCategories property index 5.';
            }
            group(Category_Category7)
            {
                Caption = 'Item Availability by', Comment = 'Generated from the PromotedActionCategories property index 6.';

                actionref(Event_Promoted; "Event")
                {
                }
                actionref(Period_Promoted; Period)
                {
                }
                actionref("BOM Level_Promoted"; "BOM Level")
                {
                }
                actionref(Location_Promoted; Location)
                {
                }
                actionref(Variant_Promoted; Variant)
                {
                }
                actionref(Lot_Promoted; Lot)
                {
                }
#if not CLEAN21
                actionref(Timeline_Promoted; Timeline)
                {
                    ObsoleteState = Pending;
                    ObsoleteReason = 'TimelineVisualizer control has been deprecated.';
                    ObsoleteTag = '21.0';
                }
#endif
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        PlanningWkshManagement.GetDescriptionAndRcptName(Rec, ItemDescription, RoutingDescription);
    end;

    trigger OnAfterGetRecord()
    var
        Item: Record "Item";
    begin
        ShowShortcutDimCode(ShortcutDimCode);
        StartingDateTimeOnFormat();
        StartingDateOnFormat();
        RefOrderNoOnFormat();
        PlanningWarningLevel1OnFormat();
        if "Variant Code" = '' then
            VariantCodeMandatory := Item.IsVariantMandatory(Type = Type::Item, "No.");
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        "Accept Action Message" := false;
        DeleteMultiLevel();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        SetUpNewLine(Rec);
        Type := Type::Item;
        Clear(ShortcutDimCode);
    end;

    trigger OnOpenPage()
    var
        JnlSelected: Boolean;
    begin
        OpenedFromBatch := ("Journal Batch Name" <> '') and ("Worksheet Template Name" = '');
        if OpenedFromBatch then begin
            CurrentWkshBatchName := "Journal Batch Name";
            ReqJnlManagement.OpenJnl(CurrentWkshBatchName, Rec);
            exit;
        end;
        ReqJnlManagement.WkshTemplateSelection(
            PAGE::"Planning Worksheet", false, "Req. Worksheet Template Type"::Planning, Rec, JnlSelected);
        if not JnlSelected then
            Error('');
        ReqJnlManagement.OpenJnl(CurrentWkshBatchName, Rec);
    end;

    var
        PlanningTransparency: Codeunit "Planning Transparency";
        ReqJnlManagement: Codeunit ReqJnlManagement;
        PlanningWkshManagement: Codeunit PlanningWkshManagement;
        ItemAvailFormsMgt: Codeunit "Item Availability Forms Mgt";
        CurrentWkshBatchName: Code[10];
        OpenedFromBatch: Boolean;
        VariantCodeMandatory: Boolean;
        [InDataSet]
        Warning: Option " ",Emergency,Exception,Attention;

    protected var
        ItemDescription: Text[100];
        RoutingDescription: Text[100];
        ShortcutDimCode: array[8] of Code[20];

    local procedure PlanningWarningLevel()
    var
        Transparency: Codeunit "Planning Transparency";
    begin
        Warning := Transparency.ReqLineWarningLevel(Rec);
    end;

    local procedure CurrentWkshBatchNameOnAfterVal()
    begin
        CurrPage.SaveRecord();
        ReqJnlManagement.SetName(CurrentWkshBatchName, Rec);
        CurrPage.Update(false);
    end;

    local procedure StartingDateTimeOnFormat()
    begin
        if ("Starting Date" < WorkDate()) and
           ("Action Message" in ["Action Message"::New, "Action Message"::Reschedule, "Action Message"::"Resched. & Chg. Qty."])
        then
            ;
    end;

    local procedure StartingDateOnFormat()
    begin
        if "Starting Date" < WorkDate() then;
    end;

    local procedure RefOrderNoOnFormat()
    var
        PurchHeader: Record "Purchase Header";
        TransfHeader: Record "Transfer Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRefOrderNoOnFormat(Rec, IsHandled);
        if IsHandled then
            exit;

        case "Ref. Order Type" of
            "Ref. Order Type"::Purchase:
                if PurchHeader.Get(PurchHeader."Document Type"::Order, "Ref. Order No.") and
                   (PurchHeader.Status = PurchHeader.Status::Released)
                then
                    ;
            "Ref. Order Type"::"Prod. Order":
                ;
            "Ref. Order Type"::Transfer:
                if TransfHeader.Get("Ref. Order No.") and
                   (TransfHeader.Status = TransfHeader.Status::Released)
                then
                    ;
        end;
    end;

    local procedure PlanningWarningLevel1OnFormat()
    begin
        PlanningWarningLevel();
    end;

    procedure OpenPlanningComponent(var PlanningComponent: Record "Planning Component")
    begin
        PlanningComponent.SetRange("Worksheet Template Name", PlanningComponent."Worksheet Template Name");
        PlanningComponent.SetRange("Worksheet Batch Name", PlanningComponent."Worksheet Batch Name");
        PlanningComponent.SetRange("Worksheet Line No.", PlanningComponent."Worksheet Line No.");
        PAGE.RunModal(PAGE::"Planning Components", PlanningComponent);
    end;

    local procedure CarryOutActionMsg()
    var
        CarryOutActionMsgPlan: Report "Carry Out Action Msg. - Plan.";
        Ishandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCarryOutActionMsg(Rec, IsHandled);
        if IsHandled then
            exit;

        CarryOutActionMsgPlan.SetReqWkshLine(Rec);
        CarryOutActionMsgPlan.RunModal();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLookupCurrentJnlBatchName(var RequisitionLine: Record "Requisition Line"; var CurrJnlBatchName: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCarryOutActionMsg(var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRefOrderNoOnFormat(var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;
}

