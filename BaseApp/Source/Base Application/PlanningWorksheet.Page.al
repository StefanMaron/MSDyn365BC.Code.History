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
    PromotedActionCategories = 'New,Process,Report,Prepare,Line,Item,Item Availability by';
    SaveValues = true;
    SourceTable = "Requisition Line";
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
                    CurrPage.SaveRecord;
                    ReqJnlManagement.LookupName(CurrentWkshBatchName, Rec);
                    CurrPage.Update(false);
                end;

                trigger OnValidate()
                begin
                    ReqJnlManagement.CheckName(CurrentWkshBatchName, Rec);
                    CurrentWkshBatchNameOnAfterVal;
                end;
            }
            repeater(Control1)
            {
                IndentationColumn = DescriptionIndent;
                IndentationControls = Description;
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
                field(Type; Type)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the type of requisition worksheet line you are creating.';
                    Visible = false;
                }
                field("No."; "No.")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnValidate()
                    begin
                        PlanningWkshManagement.GetDescriptionAndRcptName(Rec, ItemDescription, RoutingDescription);
                    end;
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field("Action Message"; "Action Message")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies an action to take to rebalance the demand-supply situation.';
                }
                field("Accept Action Message"; "Accept Action Message")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies whether to accept the action message proposed for the line.';
                }
                field("Original Due Date"; "Original Due Date")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the due date stated on the production or purchase order, when an action message proposes to reschedule an order.';
                }
                field("Order Date"; "Order Date")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the date when the related order was created.';
                    Visible = false;
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the date when you can expect to receive the items.';
                }
                field("Transfer Shipment Date"; "Transfer Shipment Date")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the shipment date of the transfer order proposal.';
                    Visible = false;
                }
                field("Starting Date-Time"; "Starting Date-Time")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the starting date and the starting time, which are combined in a format called "starting date-time".';
                }
                field("Starting Time"; "Starting Time")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the starting time of the manufacturing process.';
                    Visible = false;
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the starting date of the manufacturing process, if the planned supply is a production order.';
                    Visible = false;
                }
                field("Ending Date-Time"; "Ending Date-Time")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the ending date and the ending time, which are combined in a format called "ending date-time".';
                }
                field("Ending Time"; "Ending Time")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the ending time for the manufacturing process.';
                    Visible = false;
                }
                field("Ending Date"; "Ending Date")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the ending date of the manufacturing process, if the planned supply is a production order.';
                    Visible = false;
                }
                field("Low-Level Code"; "Low-Level Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the planning level of this item entry in the planning worksheet.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies text that describes the entry.';
                }
                field("Description 2"; "Description 2")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies additional text describing the entry, or a remark about the requisition worksheet line.';
                    Visible = false;
                }
                field("Production BOM No."; "Production BOM No.")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the production BOM number for this production order.';
                    Visible = false;
                }
                field("Production BOM Version Code"; "Production BOM Version Code")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the version code of the BOM.';
                    Visible = false;
                }
                field("Routing No."; "Routing No.")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the routing number.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        PlanningWkshManagement.GetDescriptionAndRcptName(Rec, ItemDescription, RoutingDescription);
                    end;
                }
                field("Routing Version Code"; "Routing Version Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the version code of the routing.';
                    Visible = false;
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Transfer-from Code"; "Transfer-from Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code of the location that items are transferred from.';
                    Visible = false;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies a code for an inventory location where the items that are being ordered will be registered.';
                    Visible = false;
                }
                field("Original Quantity"; "Original Quantity")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the quantity stated on the production or purchase order, when an action message proposes to change the quantity on an order.';
                }
                field("MPS Order"; "MPS Order")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies whether the requisition worksheet line is an MPS order, that is, whether it is linked to a demand forecast or a sales order.';
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the number of units of the item.';
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                    Visible = false;
                }
                field("Replenishment System"; "Replenishment System")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies which kind of order to use to create replenishment orders and order proposals.';
                    Visible = false;
                }
                field("Ref. Order Type"; "Ref. Order Type")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies whether the order is a purchase order, a production order, or a transfer order.';
                }
                field("Ref. Order No."; "Ref. Order No.")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the number of the relevant production or purchase order.';
                }
                field("Ref. Order Status"; "Ref. Order Status")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the status of the production order.';
                }
                field("Ref. Line No."; "Ref. Line No.")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the number of the purchase or production order line.';
                    Visible = false;
                }
                field("Planning Flexibility"; "Planning Flexibility")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies whether the supply, represented by the requisition worksheet line, is considered by the planning system, when calculating action messages.';
                    Visible = false;
                }
                field("Reserved Quantity"; "Reserved Quantity")
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies how many units of this item have been reserved.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        ShowReservationEntries(true);
                    end;
                }
                field("Gen. Prod. Posting Group"; "Gen. Prod. Posting Group")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
                    Visible = false;
                }
                field("Unit Cost"; "Unit Cost")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the cost of one unit of the item or resource on the line.';
                    Visible = false;
                }
                field("Gen. Business Posting Group"; "Gen. Business Posting Group")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the code of the general business posting group to be used for the item when you post the planning worksheet.';
                    Visible = false;
                }
                field("Cost Amount"; "Cost Amount")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the total costs for the requisition worksheet line.';
                    Visible = false;
                }
                field("Vendor No."; "Vendor No.")
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
                    Promoted = true;
                    PromotedCategory = Category5;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDimensions;
                        CurrPage.SaveRecord;
                    end;
                }
                action("Item &Tracking Lines")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Item &Tracking Lines';
                    Image = ItemTrackingLines;
                    Promoted = true;
                    PromotedCategory = Category5;
                    ShortCutKey = 'Shift+Ctrl+I';
                    ToolTip = 'View or edit serial numbers and lot numbers that are assigned to the item on the document or journal line.';

                    trigger OnAction()
                    begin
                        OpenItemTrackingLines;
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
                    Promoted = true;
                    PromotedCategory = Category6;
                    RunObject = Page "Planning Components";
                    RunPageLink = "Worksheet Template Name" = FIELD("Worksheet Template Name"),
                                  "Worksheet Batch Name" = FIELD("Journal Batch Name"),
                                  "Worksheet Line No." = FIELD("Line No.");
                    ToolTip = 'View or edit the production order components of the parent item on the line.';
                }
                action("Ro&uting")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Ro&uting';
                    Image = Route;
                    Promoted = true;
                    PromotedCategory = Category6;
                    RunObject = Page "Planning Routing";
                    RunPageLink = "Worksheet Template Name" = FIELD("Worksheet Template Name"),
                                  "Worksheet Batch Name" = FIELD("Journal Batch Name"),
                                  "Worksheet Line No." = FIELD("Line No.");
                    ToolTip = 'View or edit the operations list of the parent item on the line.';
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
                        Promoted = true;
                        PromotedCategory = Category7;
                        ToolTip = 'View how the actual and the projected available balance of an item will develop over time according to supply and demand events.';

                        trigger OnAction()
                        begin
                            ItemAvailFormsMgt.ShowItemAvailFromReqLine(Rec, ItemAvailFormsMgt.ByEvent)
                        end;
                    }
                    action(Period)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Period';
                        Image = Period;
                        Promoted = true;
                        PromotedCategory = Category7;
                        ToolTip = 'View the projected quantity of the item over time according to time periods, such as day, week, or month.';

                        trigger OnAction()
                        begin
                            ItemAvailFormsMgt.ShowItemAvailFromReqLine(Rec, ItemAvailFormsMgt.ByPeriod)
                        end;
                    }
                    action(Variant)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Variant';
                        Image = ItemVariant;
                        Promoted = true;
                        PromotedCategory = Category7;
                        ToolTip = 'View or edit the item''s variants. Instead of setting up each color of an item as a separate item, you can set up the various colors as variants of the item.';

                        trigger OnAction()
                        begin
                            ItemAvailFormsMgt.ShowItemAvailFromReqLine(Rec, ItemAvailFormsMgt.ByVariant)
                        end;
                    }
                    action(Location)
                    {
                        AccessByPermission = TableData Location = R;
                        ApplicationArea = Location;
                        Caption = 'Location';
                        Image = Warehouse;
                        Promoted = true;
                        PromotedCategory = Category7;
                        ToolTip = 'View the actual and projected quantity of the item per location.';

                        trigger OnAction()
                        begin
                            ItemAvailFormsMgt.ShowItemAvailFromReqLine(Rec, ItemAvailFormsMgt.ByLocation)
                        end;
                    }
                    action("BOM Level")
                    {
                        ApplicationArea = Assembly;
                        Caption = 'BOM Level';
                        Image = BOMLevel;
                        Promoted = true;
                        PromotedCategory = Category7;
                        ToolTip = 'View availability figures for items on bills of materials that show how many units of a parent item you can make based on the availability of child items.';

                        trigger OnAction()
                        begin
                            ItemAvailFormsMgt.ShowItemAvailFromReqLine(Rec, ItemAvailFormsMgt.ByBOM)
                        end;
                    }
                    action(Timeline)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Timeline';
                        Image = Timeline;
                        Promoted = true;
                        PromotedCategory = Category7;
                        ToolTip = 'Get a graphical view of an item''s projected inventory based on future supply and demand events, with or without planning suggestions. The result is a graphical representation of the inventory profile.';

                        trigger OnAction()
                        begin
                            ShowTimeline(Rec);
                        end;
                    }
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Get &Action Messages")
                {
                    ApplicationArea = Planning;
                    Caption = 'Get &Action Messages';
                    Ellipsis = true;
                    Image = GetActionMessages;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Obtain an immediate view of the effect of schedule changes, without running a regenerative or net change planning process. This function serves as a short-term planning tool by issuing action messages to alert the user of any modifications made since the last regenerative or net change plan was calculated.';

                    trigger OnAction()
                    begin
                        GetActionMessages;

                        if not Find('-') then
                            SetUpNewLine(Rec);
                    end;
                }
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
                        CalcPlan.RunModal;

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
                    Promoted = true;
                    PromotedCategory = Category4;
                    ToolTip = 'Plan for all items, regardless of changes since the previous planning run. You calculate a regenerative plan when there are changes to master data or capacity, such as shop calendars, that affect all items and therefore the whole supply plan.';

                    trigger OnAction()
                    var
                        CalcPlan: Report "Calculate Plan - Plan. Wksh.";
                    begin
                        CalcPlan.SetTemplAndWorksheet("Worksheet Template Name", "Journal Batch Name", true);
                        CalcPlan.RunModal;

                        if not Find('-') then
                            SetUpNewLine(Rec);

                        Clear(CalcPlan);
                    end;
                }
                separator(Action32)
                {
                }
                action("Re&fresh Planning Line")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Re&fresh Planning Line';
                    Ellipsis = true;
                    Image = RefreshPlanningLine;
                    Promoted = true;
                    PromotedCategory = Process;
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
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Use a batch job to help you create actual supply orders from the order proposals.';

                    trigger OnAction()
                    begin
                        PerformAction.SetReqWkshLine(Rec);
                        PerformAction.RunModal;
                        Clear(PerformAction);
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
                        CurrPage.SaveRecord;
                        ShowReservation;
                    end;
                }
                action(OrderTracking)
                {
                    ApplicationArea = Planning;
                    Caption = 'Order &Tracking';
                    Image = OrderTracking;
                    Promoted = true;
                    PromotedCategory = Category5;
                    ToolTip = 'Tracks the connection of a supply to its corresponding demand. This can help you find the original demand that created a specific production order or purchase order.';

                    trigger OnAction()
                    var
                        TrackingForm: Page "Order Tracking";
                    begin
                        TrackingForm.SetReqLine(Rec);
                        TrackingForm.RunModal;
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        PlanningWkshManagement.GetDescriptionAndRcptName(Rec, ItemDescription, RoutingDescription);
    end;

    trigger OnAfterGetRecord()
    begin
        DescriptionIndent := 0;
        ShowShortcutDimCode(ShortcutDimCode);
        StartingDateTimeOnFormat;
        StartingDateOnFormat;
        DescriptionOnFormat;
        RefOrderNoOnFormat;
        PlanningWarningLevel1OnFormat;
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        "Accept Action Message" := false;
        DeleteMultiLevel;
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
        ReqJnlManagement.TemplateSelection(PAGE::"Planning Worksheet", false, 2, Rec, JnlSelected);
        if not JnlSelected then
            Error('');
        ReqJnlManagement.OpenJnl(CurrentWkshBatchName, Rec);
    end;

    var
        PerformAction: Report "Carry Out Action Msg. - Plan.";
        PlanningTransparency: Codeunit "Planning Transparency";
        ReqJnlManagement: Codeunit ReqJnlManagement;
        PlanningWkshManagement: Codeunit PlanningWkshManagement;
        ItemAvailFormsMgt: Codeunit "Item Availability Forms Mgt";
        CurrentWkshBatchName: Code[10];
        ItemDescription: Text[100];
        RoutingDescription: Text[50];
        ShortcutDimCode: array[8] of Code[20];
        OpenedFromBatch: Boolean;
        [InDataSet]
        DescriptionIndent: Integer;
        Warning: Option " ",Emergency,Exception,Attention;

    local procedure PlanningWarningLevel()
    var
        Transparency: Codeunit "Planning Transparency";
    begin
        Warning := Transparency.ReqLineWarningLevel(Rec);
    end;

    local procedure CurrentWkshBatchNameOnAfterVal()
    begin
        CurrPage.SaveRecord;
        ReqJnlManagement.SetName(CurrentWkshBatchName, Rec);
        CurrPage.Update(false);
    end;

    local procedure StartingDateTimeOnFormat()
    begin
        if ("Starting Date" < WorkDate) and
           ("Action Message" in ["Action Message"::New, "Action Message"::Reschedule, "Action Message"::"Resched. & Chg. Qty."])
        then
            ;
    end;

    local procedure StartingDateOnFormat()
    begin
        if "Starting Date" < WorkDate then;
    end;

    local procedure DescriptionOnFormat()
    begin
        DescriptionIndent := "Planning Level";
    end;

    local procedure RefOrderNoOnFormat()
    var
        PurchHeader: Record "Purchase Header";
        TransfHeader: Record "Transfer Header";
    begin
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
        PlanningWarningLevel;
    end;

    procedure OpenPlanningComponent(var PlanningComponent: Record "Planning Component")
    begin
        PlanningComponent.SetRange("Worksheet Template Name", PlanningComponent."Worksheet Template Name");
        PlanningComponent.SetRange("Worksheet Batch Name", PlanningComponent."Worksheet Batch Name");
        PlanningComponent.SetRange("Worksheet Line No.", PlanningComponent."Worksheet Line No.");
        PAGE.RunModal(PAGE::"Planning Components", PlanningComponent);
    end;
}

