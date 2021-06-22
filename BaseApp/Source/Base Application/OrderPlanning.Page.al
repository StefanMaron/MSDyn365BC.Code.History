page 5522 "Order Planning"
{
    AdditionalSearchTerms = 'supply planning,mrp,material requirements planning,mps,master production schedule';
    ApplicationArea = Planning;
    Caption = 'Order Planning';
    InsertAllowed = false;
    PageType = Worksheet;
    PromotedActionCategories = 'New,Process,Report,Line,Item,Item Availability by';
    SourceTable = "Requisition Line";
    SourceTableTemporary = true;
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(DemandOrderFilterCtrl; DemandOrderFilter)
                {
                    ApplicationArea = Planning;
                    Caption = 'Show Demand as';
                    Enabled = DemandOrderFilterCtrlEnable;
                    OptionCaption = 'All Demand,Production Demand,Sales Demand,Service Demand,Job Demand,Assembly Demand';
                    ToolTip = 'Specifies a filter to define which demand types you want to display in the Order Planning window.';

                    trigger OnValidate()
                    begin
                        DemandOrderFilterOnAfterValida;
                    end;
                }
            }
            repeater(Control1)
            {
                IndentationColumn = DescriptionIndent;
                IndentationControls = Description;
                ShowAsTree = true;
                ShowCaption = false;
                field("Demand Date"; "Demand Date")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the demanded date of the demand that the planning line represents.';
                }
                field(StatusText; StatusText)
                {
                    ApplicationArea = Planning;
                    CaptionClass = FieldCaption(Status);
                    Editable = false;
                    HideValue = StatusHideValue;
                }
                field(DemandTypeText; DemandTypeText)
                {
                    ApplicationArea = Planning;
                    CaptionClass = FieldCaption("Demand Type");
                    Editable = false;
                    HideValue = DemandTypeHideValue;
                    Lookup = false;
                    Style = Strong;
                    StyleExpr = DemandTypeEmphasize;
                }
                field(DemandSubtypeText; DemandSubtypeText)
                {
                    ApplicationArea = Planning;
                    CaptionClass = FieldCaption("Demand Subtype");
                    Editable = false;
                    Visible = false;
                }
                field("Demand Order No."; "Demand Order No.")
                {
                    ApplicationArea = Planning;
                    Caption = 'Order No.';
                    HideValue = DemandOrderNoHideValue;
                    Style = Strong;
                    StyleExpr = DemandOrderNoEmphasize;
                    ToolTip = 'Specifies the number of the demanded order that represents the planning line.';
                }
                field("Demand Line No."; "Demand Line No.")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the line number of the demand, such as a sales order line.';
                    Visible = false;
                }
                field("No."; "No.")
                {
                    ApplicationArea = Planning;
                    Caption = 'Item No.';
                    Editable = false;
                    ToolTip = 'Specifies the number of the item with insufficient availability and must be planned.';
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    Editable = false;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies a code for an inventory location where the items that are being ordered will be registered.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = Planning;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = DescriptionEmphasize;
                    ToolTip = 'Specifies text that describes the entry.';
                }
                field("Demand Quantity"; "Demand Quantity")
                {
                    ApplicationArea = Planning;
                    HideValue = DemandQuantityHideValue;
                    ToolTip = 'Specifies the quantity on the demand that the planning line represents.';
                    Visible = false;
                }
                field("Demand Qty. Available"; "Demand Qty. Available")
                {
                    ApplicationArea = Planning;
                    HideValue = DemandQtyAvailableHideValue;
                    ToolTip = 'Specifies how many of the demand quantity are available.';
                    Visible = false;
                }
                field("Needed Quantity"; "Needed Quantity")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the demand quantity that is not available and must be ordered to meet the demand represented on the planning line.';
                    Visible = true;
                }
                field("Replenishment System"; "Replenishment System")
                {
                    ApplicationArea = Planning;
                    HideValue = ReplenishmentSystemHideValue;
                    ToolTip = 'Specifies which kind of order to use to create replenishment orders and order proposals.';

                    trigger OnValidate()
                    begin
                        ReplenishmentSystemOnAfterVali;
                    end;
                }
                field("Supply From"; "Supply From")
                {
                    ApplicationArea = Planning;
                    Editable = SupplyFromEditable;
                    ToolTip = 'Specifies a value, according to the selected replenishment system, before a supply order can be created for the line.';
                }
                field(Reserve; Reserve)
                {
                    ApplicationArea = Reservation;
                    Editable = ReserveEditable;
                    ToolTip = 'Specifies whether the item on the planning line has a setting of Always in the Reserve field on its item card.';
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Assembly;
                    Caption = 'Qty. to Order';
                    HideValue = QuantityHideValue;
                    ToolTip = 'Specifies the quantity that will be ordered on the supply order, such as purchase or assembly, that you can create from the planning line.';
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                    Visible = false;
                }
                field("Order Date"; "Order Date")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the date when the related order was created.';
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the starting date of the manufacturing process, if the planned supply is a production order.';
                    Visible = false;
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the date when you can expect to receive the items.';
                }
                field("Unit Cost"; "Unit Cost")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the cost of one unit of the item or resource on the line.';
                    Visible = false;
                }
                field("Direct Unit Cost"; "Direct Unit Cost")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the cost of one unit of the selected item or resource.';
                    Visible = false;
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the currency code for the requisition lines.';
                    Visible = false;
                }
                field("Purchasing Code"; "Purchasing Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies which purchaser is assigned to the vendor.';
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
            }
            group(Control38)
            {
                ShowCaption = false;
                fixed(Control1902204901)
                {
                    ShowCaption = false;
                    group("Available for Transfer")
                    {
                        Caption = 'Available for Transfer';
                        field(AvailableForTransfer; QtyOnOtherLocations)
                        {
                            ApplicationArea = Location;
                            Caption = 'Available For Transfer';
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ToolTip = 'Specifies the quantity of the item on the active planning line, that is available on another location than the one defined.';

                            trigger OnAssistEdit()
                            begin
                                OrderPlanningMgt.InsertAltSupplyLocation(Rec);
                            end;
                        }
                    }
                    group("Substitutes Exist")
                    {
                        Caption = 'Substitutes Exist';
                        field(SubstitionAvailable; SubstitionAvailable)
                        {
                            ApplicationArea = Planning;
                            Caption = 'Substitutes Exist';
                            DrillDown = false;
                            Editable = false;
                            Lookup = false;
                            ToolTip = 'Specifies if a substitute item exists for the component on the planning line.';

                            trigger OnAssistEdit()
                            var
                                ReqLine2: Record "Requisition Line";
                                xReqLine: Record "Requisition Line";
                                ReqLine3: Record "Requisition Line";
                            begin
                                ReqLine3 := Rec;
                                OrderPlanningMgt.InsertAltSupplySubstitution(ReqLine3);
                                Rec := ReqLine3;
                                Modify;

                                if OrderPlanningMgt.DeleteLine then begin
                                    xReqLine := Rec;
                                    ReqLine2.SetCurrentKey("User ID", "Demand Type", "Demand Subtype", "Demand Order No.");
                                    ReqLine2.SetRange("User ID", UserId);
                                    ReqLine2.SetRange("Demand Type", "Demand Type");
                                    ReqLine2.SetRange("Demand Subtype", "Demand Subtype");
                                    ReqLine2.SetRange("Demand Order No.", "Demand Order No.");
                                    ReqLine2.SetRange(Level, Level, Level + 1);
                                    ReqLine2.SetFilter("Line No.", '<>%1', "Line No.");
                                    if not ReqLine2.FindFirst then begin // No other children
                                        ReqLine2.SetRange("Line No.");
                                        ReqLine2.SetRange(Level, 0);
                                        if ReqLine2.FindFirst then begin // Find and delete parent
                                            Rec := ReqLine2;
                                            Delete;
                                        end;
                                    end;

                                    Rec := xReqLine;
                                    Delete;
                                    CurrPage.Update(false);
                                end else
                                    CurrPage.Update(true);
                            end;
                        }
                    }
                    group("Quantity Available")
                    {
                        Caption = 'Quantity Available';
                        field(QuantityAvailable; QtyATP)
                        {
                            ApplicationArea = Planning;
                            Caption = 'Quantity Available';
                            DecimalPlaces = 0 : 5;
                            DrillDown = false;
                            Editable = false;
                            Lookup = false;
                            ToolTip = 'Specifies the total availability of the item on the active planning line, irrespective of quantities calculated for the line.';
                        }
                    }
                    group("Earliest Date Available")
                    {
                        Caption = 'Earliest Date Available';
                        field(EarliestShptDateAvailable; EarliestShptDateAvailable)
                        {
                            ApplicationArea = Planning;
                            Caption = 'Earliest Date Available';
                            DrillDown = false;
                            Editable = false;
                            Lookup = false;
                            ToolTip = 'Specifies the arrival date of an inbound supply order that can cover the needed quantity on a date later than the demand date.';
                        }
                    }
                }
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
                action("Show Document")
                {
                    ApplicationArea = Planning;
                    Caption = 'Show Document';
                    Image = View;
                    Promoted = true;
                    PromotedCategory = Category4;
                    ToolTip = 'Open the document that the selected line exists on.';

                    trigger OnAction()
                    begin
                        ShowDemandOrder;
                    end;
                }
                separator(Action63)
                {
                }
                action(Components)
                {
                    ApplicationArea = Planning;
                    Caption = 'Components';
                    Image = Components;
                    Promoted = true;
                    PromotedCategory = Category4;
                    RunObject = Page "Planning Components";
                    RunPageLink = "Worksheet Template Name" = FIELD("Worksheet Template Name"),
                                  "Worksheet Batch Name" = FIELD("Journal Batch Name"),
                                  "Worksheet Line No." = FIELD("Line No.");
                    ToolTip = 'View or edit the production order components of the parent item on the line.';
                }
                action("Ro&uting")
                {
                    ApplicationArea = Planning;
                    Caption = 'Ro&uting';
                    Image = Route;
                    Promoted = true;
                    PromotedCategory = Category4;
                    RunObject = Page "Planning Routing";
                    RunPageLink = "Worksheet Template Name" = FIELD("Worksheet Template Name"),
                                  "Worksheet Batch Name" = FIELD("Journal Batch Name"),
                                  "Worksheet Line No." = FIELD("Line No.");
                    ToolTip = 'View or edit the operations list of the parent item on the line.';
                }
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    Promoted = true;
                    PromotedCategory = Category4;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDimensions;
                        CurrPage.SaveRecord;
                    end;
                }
            }
            group("&Item")
            {
                Caption = '&Item';
                Image = Item;
                action(Card)
                {
                    ApplicationArea = Planning;
                    Caption = 'Card';
                    Image = EditLines;
                    Promoted = true;
                    PromotedCategory = Category5;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';

                    trigger OnAction()
                    var
                        Item: Record Item;
                    begin
                        TestField(Type, Type::Item);
                        TestField("No.");
                        Item."No." := "No.";
                        PAGE.RunModal(PAGE::"Item Card", Item);
                    end;
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
                        PromotedCategory = Category6;
                        ToolTip = 'View how the actual and the projected available balance of an item will develop over time according to supply and demand events.';

                        trigger OnAction()
                        begin
                            ItemAvailFormsMgt.ShowItemAvailFromReqLine(Rec, ItemAvailFormsMgt.ByEvent);
                        end;
                    }
                    action(Period)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Period';
                        Image = Period;
                        Promoted = true;
                        PromotedCategory = Category6;
                        ToolTip = 'View the projected quantity of the item over time according to time periods, such as day, week, or month.';

                        trigger OnAction()
                        begin
                            ItemAvailFormsMgt.ShowItemAvailFromReqLine(Rec, ItemAvailFormsMgt.ByPeriod);
                        end;
                    }
                    action(Variant)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Variant';
                        Image = ItemVariant;
                        Promoted = true;
                        PromotedCategory = Category6;
                        ToolTip = 'View or edit the item''s variants. Instead of setting up each color of an item as a separate item, you can set up the various colors as variants of the item.';

                        trigger OnAction()
                        begin
                            ItemAvailFormsMgt.ShowItemAvailFromReqLine(Rec, ItemAvailFormsMgt.ByVariant);
                        end;
                    }
                    action(Location)
                    {
                        AccessByPermission = TableData Location = R;
                        ApplicationArea = Location;
                        Caption = 'Location';
                        Image = Warehouse;
                        Promoted = true;
                        PromotedCategory = Category6;
                        ToolTip = 'View the actual and projected quantity of the item per location.';

                        trigger OnAction()
                        begin
                            ItemAvailFormsMgt.ShowItemAvailFromReqLine(Rec, ItemAvailFormsMgt.ByLocation);
                        end;
                    }
                    action("BOM Level")
                    {
                        ApplicationArea = Assembly;
                        Caption = 'BOM Level';
                        Image = BOMLevel;
                        Promoted = true;
                        PromotedCategory = Category6;
                        ToolTip = 'View availability figures for items on bills of materials that show how many units of a parent item you can make based on the availability of child items.';

                        trigger OnAction()
                        begin
                            ItemAvailFormsMgt.ShowItemAvailFromReqLine(Rec, ItemAvailFormsMgt.ByBOM);
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
                action(CalculatePlan)
                {
                    ApplicationArea = Planning;
                    Caption = '&Calculate Plan';
                    Image = CalculatePlan;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Start the calculation of supply orders needed to fulfill the specified demand. Remember that each time, you choose the Calculate Plan action, only one product level is planned.';

                    trigger OnAction()
                    begin
                        CalcPlan;
                        CurrPage.Update(false);
                    end;
                }
                separator(Action48)
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
                    ToolTip = 'Tracks the connection of a supply to its corresponding demand. This can help you find the original demand that created a specific production order or purchase order.';

                    trigger OnAction()
                    var
                        TrackingForm: Page "Order Tracking";
                    begin
                        TrackingForm.SetReqLine(Rec);
                        TrackingForm.RunModal;
                    end;
                }
                action("Refresh &Planning Line")
                {
                    ApplicationArea = Planning;
                    Caption = 'Refresh &Planning Line';
                    Ellipsis = true;
                    Image = RefreshPlanningLine;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Update the planning components and the routing lines for the selected planning line with any changes.';

                    trigger OnAction()
                    var
                        ReqLine2: Record "Requisition Line";
                    begin
                        ReqLine2.SetRange("Worksheet Template Name", "Worksheet Template Name");
                        ReqLine2.SetRange("Journal Batch Name", "Journal Batch Name");
                        ReqLine2.SetRange("Line No.", "Line No.");

                        REPORT.RunModal(REPORT::"Refresh Planning Demand", true, false, ReqLine2);
                    end;
                }
                separator(Action36)
                {
                }
            }
            action("Make &Orders")
            {
                ApplicationArea = Planning;
                Caption = 'Make &Orders';
                Ellipsis = true;
                Image = NewOrder;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Create the suggested supply orders according to options that you specify in a new window.';

                trigger OnAction()
                var
                    MakeSupplyOrders: Codeunit "Make Supply Orders (Yes/No)";
                begin
                    MakeSupplyOrders.SetManufUserTemplate(MfgUserTempl);
                    MakeSupplyOrders.Run(Rec);

                    if MakeSupplyOrders.ActionMsgCarriedOut then begin
                        RefreshTempTable;
                        SetRecFilters;
                        CurrPage.Update(false);
                    end;
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        if ReqLine.Get("Worksheet Template Name", "Journal Batch Name", "Line No.") then begin
            Rec := ReqLine;
            Modify
        end else
            if Get("Worksheet Template Name", "Journal Batch Name", "Line No.") then
                Delete;

        UpdateSupplyFrom;
        CalcItemAvail;
    end;

    trigger OnAfterGetRecord()
    begin
        DescriptionIndent := 0;
        StatusText := Format(Status);
        StatusTextOnFormat(StatusText);
        DemandTypeText := Format("Demand Type");
        DemandTypeTextOnFormat(DemandTypeText);
        DemandSubtypeText := Format("Demand Subtype");
        DemandSubtypeTextOnFormat(DemandSubtypeText);
        DemandOrderNoOnFormat;
        DescriptionOnFormat;
        DemandQuantityOnFormat;
        DemandQtyAvailableOnFormat;
        ReplenishmentSystemOnFormat;
        QuantityOnFormat;
        ReserveOnFormat;
    end;

    trigger OnDeleteRecord(): Boolean
    var
        xReqLine: Record "Requisition Line";
    begin
        xReqLine := Rec;
        while (Next <> 0) and (Level > xReqLine.Level) do
            Delete(true);
        Rec := xReqLine;
        xReqLine.Delete(true);
        Delete;
        exit(false);
    end;

    trigger OnInit()
    begin
        DemandOrderFilterCtrlEnable := true;
        SupplyFromEditable := true;
        ReserveEditable := true;
    end;

    trigger OnModifyRecord(): Boolean
    var
        ReqLine: Record "Requisition Line";
    begin
        ReqLine.Get("Worksheet Template Name", "Journal Batch Name", "Line No.");
        ReqLine.TransferFields(Rec, false);
        ReqLine.Modify(true);
    end;

    trigger OnOpenPage()
    begin
        if not MfgUserTempl.Get(UserId) then begin
            MfgUserTempl.Init();
            MfgUserTempl."User ID" := UserId;
            MfgUserTempl."Make Orders" := MfgUserTempl."Make Orders"::"The Active Order";
            MfgUserTempl."Create Purchase Order" := MfgUserTempl."Create Purchase Order"::"Make Purch. Orders";
            MfgUserTempl."Create Production Order" := MfgUserTempl."Create Production Order"::"Firm Planned";
            MfgUserTempl."Create Transfer Order" := MfgUserTempl."Create Transfer Order"::"Make Trans. Orders";
            MfgUserTempl."Create Assembly Order" := MfgUserTempl."Create Assembly Order"::"Make Assembly Orders";
            MfgUserTempl.Insert();
        end;

        InitTempRec;
    end;

    var
        ReqLine: Record "Requisition Line";
        SalesHeader: Record "Sales Header";
        ProdOrder: Record "Production Order";
        AsmHeader: Record "Assembly Header";
        ServHeader: Record "Service Header";
        Job: Record Job;
        MfgUserTempl: Record "Manufacturing User Template";
        OrderPlanningMgt: Codeunit "Order Planning Mgt.";
        ItemAvailFormsMgt: Codeunit "Item Availability Forms Mgt";
        UOMMgt: Codeunit "Unit of Measure Management";
        DemandOrderFilter: Option "All Demands","Production Demand","Sales Demand","Service Demand","Job Demand","Assembly Demand";
        Text001: Label 'Sales';
        Text002: Label 'Production';
        Text003: Label 'Service';
        Text004: Label 'Jobs';
        [InDataSet]
        StatusHideValue: Boolean;
        [InDataSet]
        StatusText: Text[1024];
        [InDataSet]
        DemandTypeHideValue: Boolean;
        [InDataSet]
        DemandTypeEmphasize: Boolean;
        [InDataSet]
        DemandTypeText: Text[1024];
        [InDataSet]
        DemandSubtypeText: Text[1024];
        [InDataSet]
        DemandOrderNoHideValue: Boolean;
        [InDataSet]
        DemandOrderNoEmphasize: Boolean;
        [InDataSet]
        DescriptionEmphasize: Boolean;
        [InDataSet]
        DescriptionIndent: Integer;
        [InDataSet]
        DemandQuantityHideValue: Boolean;
        [InDataSet]
        DemandQtyAvailableHideValue: Boolean;
        [InDataSet]
        ReplenishmentSystemHideValue: Boolean;
        [InDataSet]
        QuantityHideValue: Boolean;
        [InDataSet]
        SupplyFromEditable: Boolean;
        [InDataSet]
        ReserveEditable: Boolean;
        [InDataSet]
        DemandOrderFilterCtrlEnable: Boolean;
        Text005: Label 'Assembly';
        QtyOnOtherLocations: Decimal;
        SubstitionAvailable: Boolean;
        QtyATP: Decimal;
        EarliestShptDateAvailable: Date;

    procedure SetSalesOrder(SalesHeader2: Record "Sales Header")
    begin
        SalesHeader := SalesHeader2;
        DemandOrderFilter := DemandOrderFilter::"Sales Demand";
        DemandOrderFilterCtrlEnable := false;
    end;

    procedure SetProdOrder(ProdOrder2: Record "Production Order")
    begin
        ProdOrder := ProdOrder2;
        DemandOrderFilter := DemandOrderFilter::"Production Demand";
        DemandOrderFilterCtrlEnable := false;
    end;

    procedure SetAsmOrder(AsmHeader2: Record "Assembly Header")
    begin
        AsmHeader := AsmHeader2;
        DemandOrderFilter := DemandOrderFilter::"Assembly Demand";
        DemandOrderFilterCtrlEnable := false;
    end;

    procedure SetServOrder(ServHeader2: Record "Service Header")
    begin
        ServHeader := ServHeader2;
        DemandOrderFilter := DemandOrderFilter::"Service Demand";
        DemandOrderFilterCtrlEnable := false;
    end;

    procedure SetJobOrder(Job2: Record Job)
    begin
        Job := Job2;
        DemandOrderFilter := DemandOrderFilter::"Job Demand";
        DemandOrderFilterCtrlEnable := false;
    end;

    local procedure InitTempRec()
    var
        ReqLine: Record "Requisition Line";
        ReqLineWithCursor: Record "Requisition Line";
    begin
        DeleteAll();

        ReqLine.Reset();
        ReqLine.CopyFilters(Rec);
        ReqLine.SetRange("User ID", UserId);
        ReqLine.SetRange("Worksheet Template Name", '');
        if ReqLine.FindSet then
            repeat
                Rec := ReqLine;
                Insert;
                if ReqLine.Level = 0 then
                    FindReqLineForCursor(ReqLineWithCursor, ReqLine);
            until ReqLine.Next = 0;

        if FindFirst then
            if ReqLineWithCursor."Line No." > 0 then
                Rec := ReqLineWithCursor;

        SetRecFilters;
    end;

    local procedure FindReqLineForCursor(var ReqLineWithCursor: Record "Requisition Line"; ActualReqLine: Record "Requisition Line")
    begin
        if ProdOrder."No." = '' then
            exit;

        if (ActualReqLine."Demand Type" = DATABASE::"Prod. Order Component") and
           (ActualReqLine."Demand Subtype" = ProdOrder.Status) and
           (ActualReqLine."Demand Order No." = ProdOrder."No.")
        then
            ReqLineWithCursor := ActualReqLine;
    end;

    local procedure RefreshTempTable()
    var
        TempReqLine2: Record "Requisition Line";
        ReqLine: Record "Requisition Line";
    begin
        TempReqLine2.Copy(Rec);

        Reset;
        if Find('-') then
            repeat
                ReqLine := Rec;
                if not ReqLine.Find or
                   ((Level = 0) and ((ReqLine.Next = 0) or (ReqLine.Level = 0)))
                then begin
                    if Level = 0 then begin
                        ReqLine := Rec;
                        ReqLine.Find;
                        ReqLine.Delete(true);
                    end;
                    Delete
                end;
            until Next = 0;

        Copy(TempReqLine2);
    end;

    procedure SetRecFilters()
    begin
        Reset;
        FilterGroup(2);
        SetRange("User ID", UserId);
        SetRange("Worksheet Template Name", '');

        case DemandOrderFilter of
            DemandOrderFilter::"All Demands":
                begin
                    SetRange("Demand Type");
                    SetCurrentKey("User ID", "Worksheet Template Name", "Journal Batch Name", "Line No.");
                end;
            DemandOrderFilter::"Sales Demand":
                begin
                    SetRange("Demand Type", DATABASE::"Sales Line");
                    SetCurrentKey("User ID", "Demand Type", "Worksheet Template Name", "Journal Batch Name", "Line No.");
                end;
            DemandOrderFilter::"Production Demand":
                begin
                    SetRange("Demand Type", DATABASE::"Prod. Order Component");
                    SetCurrentKey("User ID", "Demand Type", "Worksheet Template Name", "Journal Batch Name", "Line No.");
                end;
            DemandOrderFilter::"Assembly Demand":
                begin
                    SetRange("Demand Type", DATABASE::"Assembly Line");
                    SetCurrentKey("User ID", "Demand Type", "Worksheet Template Name", "Journal Batch Name", "Line No.");
                end;
            DemandOrderFilter::"Service Demand":
                begin
                    SetRange("Demand Type", DATABASE::"Service Line");
                    SetCurrentKey("User ID", "Demand Type", "Worksheet Template Name", "Journal Batch Name", "Line No.");
                end;
            DemandOrderFilter::"Job Demand":
                begin
                    SetRange("Demand Type", DATABASE::"Job Planning Line");
                    SetCurrentKey("User ID", "Demand Type", "Worksheet Template Name", "Journal Batch Name", "Line No.");
                end;
        end;
        FilterGroup(0);

        CurrPage.Update(false);
    end;

    local procedure ShowDemandOrder()
    var
        SalesHeader: Record "Sales Header";
        ProdOrder: Record "Production Order";
        ServHeader: Record "Service Header";
        Job: Record Job;
        AsmHeader: Record "Assembly Header";
    begin
        case "Demand Type" of
            DATABASE::"Sales Line":
                begin
                    SalesHeader.Get("Demand Subtype", "Demand Order No.");
                    case SalesHeader."Document Type" of
                        SalesHeader."Document Type"::Order:
                            PAGE.Run(PAGE::"Sales Order", SalesHeader);
                        SalesHeader."Document Type"::"Return Order":
                            PAGE.Run(PAGE::"Sales Return Order", SalesHeader);
                    end;
                end;
            DATABASE::"Prod. Order Component":
                begin
                    ProdOrder.Get("Demand Subtype", "Demand Order No.");
                    case ProdOrder.Status of
                        ProdOrder.Status::Planned:
                            PAGE.Run(PAGE::"Planned Production Order", ProdOrder);
                        ProdOrder.Status::"Firm Planned":
                            PAGE.Run(PAGE::"Firm Planned Prod. Order", ProdOrder);
                        ProdOrder.Status::Released:
                            PAGE.Run(PAGE::"Released Production Order", ProdOrder);
                    end;
                end;
            DATABASE::"Assembly Line":
                begin
                    AsmHeader.Get("Demand Subtype", "Demand Order No.");
                    case AsmHeader."Document Type" of
                        AsmHeader."Document Type"::Order:
                            PAGE.Run(PAGE::"Assembly Order", AsmHeader);
                    end;
                end;
            DATABASE::"Service Line":
                begin
                    ServHeader.Get("Demand Subtype", "Demand Order No.");
                    case ServHeader."Document Type" of
                        ServHeader."Document Type"::Order:
                            PAGE.Run(PAGE::"Service Order", ServHeader);
                    end;
                end;
            DATABASE::"Job Planning Line":
                begin
                    Job.Get("Demand Order No.");
                    case Job.Status of
                        Job.Status::Open:
                            PAGE.Run(PAGE::"Job Card", Job);
                    end;
                end;
        end;

        OnAfterShowDemandOrder(Rec);
    end;

    local procedure CalcItemAvail()
    begin
        QtyOnOtherLocations := CalcQtyOnOtherLocations;
        SubstitionAvailable := CalcSubstitionAvailable;
        QtyATP := CalcQtyATP;
        EarliestShptDateAvailable := CalcEarliestShptDateAvailable;
    end;

    local procedure CalcQtyOnOtherLocations(): Decimal
    var
        QtyOnOtherLocation: Decimal;
    begin
        if "No." = '' then
            exit;

        QtyOnOtherLocation := OrderPlanningMgt.AvailQtyOnOtherLocations(Rec); // Base Unit
        if "Qty. per Unit of Measure" = 0 then
            "Qty. per Unit of Measure" := 1;
        QtyOnOtherLocation := Round(QtyOnOtherLocation / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision);

        exit(QtyOnOtherLocation);
    end;

    local procedure CalcQtyATP(): Decimal
    var
        QtyATP: Decimal;
    begin
        if "No." = '' then
            exit;

        QtyATP := OrderPlanningMgt.CalcATPQty("No.", "Variant Code", "Location Code", "Demand Date"); // Base Unit
        if "Qty. per Unit of Measure" = 0 then
            "Qty. per Unit of Measure" := 1;
        QtyATP := Round(QtyATP / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision);

        exit(QtyATP);
    end;

    local procedure CalcEarliestShptDateAvailable(): Date
    var
        Item: Record Item;
    begin
        if "No." = '' then
            exit;

        Item.Get("No.");
        if Item."Order Tracking Policy" = Item."Order Tracking Policy"::"Tracking & Action Msg." then
            exit;

        exit(OrderPlanningMgt.CalcATPEarliestDate("No.", "Variant Code", "Location Code", "Demand Date", "Quantity (Base)"));
    end;

    local procedure CalcSubstitionAvailable(): Boolean
    begin
        if "No." = '' then
            exit;

        exit(OrderPlanningMgt.SubstitutionPossible(Rec));
    end;

    local procedure CalcPlan()
    var
        ReqLine: Record "Requisition Line";
    begin
        Reset;
        DeleteAll();

        Clear(OrderPlanningMgt);
        case DemandOrderFilter of
            DemandOrderFilter::"Sales Demand":
                OrderPlanningMgt.SetSalesOrder;
            DemandOrderFilter::"Assembly Demand":
                OrderPlanningMgt.SetAsmOrder;
            DemandOrderFilter::"Production Demand":
                OrderPlanningMgt.SetProdOrder;
            DemandOrderFilter::"Service Demand":
                OrderPlanningMgt.SetServOrder;
            DemandOrderFilter::"Job Demand":
                OrderPlanningMgt.SetJobOrder;
        end;
        OrderPlanningMgt.GetOrdersToPlan(ReqLine);

        InitTempRec;
    end;

    local procedure UpdateSupplyFrom()
    begin
        SupplyFromEditable := not ("Replenishment System" in ["Replenishment System"::"Prod. Order",
                                                              "Replenishment System"::Assembly]);
    end;

    local procedure DemandOrderFilterOnAfterValida()
    begin
        CurrPage.SaveRecord;
        SetRecFilters;
    end;

    local procedure ReplenishmentSystemOnAfterVali()
    begin
        UpdateSupplyFrom;
    end;

    local procedure StatusTextOnFormat(var Text: Text[1024])
    begin
        if "Demand Line No." = 0 then
            case "Demand Type" of
                DATABASE::"Prod. Order Component":
                    begin
                        ProdOrder.Status := Status;
                        Text := Format(ProdOrder.Status);
                    end;
                DATABASE::"Sales Line":
                    begin
                        SalesHeader.Status := Status;
                        Text := Format(SalesHeader.Status);
                    end;
                DATABASE::"Service Line":
                    begin
                        ServHeader.Init();
                        ServHeader.Status := Status;
                        Text := Format(ServHeader.Status);
                    end;
                DATABASE::"Job Planning Line":
                    begin
                        Job.Init();
                        Job.Status := Status;
                        Text := Format(Job.Status);
                    end;
                DATABASE::"Assembly Line":
                    begin
                        AsmHeader.Status := Status;
                        Text := Format(AsmHeader.Status);
                    end;
            end;

        OnAfterStatusTextOnFormat(Rec, Text);

        StatusHideValue := "Demand Line No." <> 0;
    end;

    local procedure DemandTypeTextOnFormat(var Text: Text[1024])
    begin
        if "Demand Line No." = 0 then
            case "Demand Type" of
                DATABASE::"Sales Line":
                    Text := Text001;
                DATABASE::"Prod. Order Component":
                    Text := Text002;
                DATABASE::"Service Line":
                    Text := Text003;
                DATABASE::"Job Planning Line":
                    Text := Text004;
                DATABASE::"Assembly Line":
                    Text := Text005;
            end;

        OnAfterDemandTypeTextOnFormat(Rec, Text);

        DemandTypeHideValue := "Demand Line No." <> 0;
        DemandTypeEmphasize := Level = 0;
    end;

    local procedure DemandSubtypeTextOnFormat(var Text: Text[1024])
    begin
        case "Demand Type" of
            DATABASE::"Prod. Order Component":
                begin
                    ProdOrder.Status := Status;
                    Text := Format(ProdOrder.Status);
                end;
            DATABASE::"Sales Line":
                begin
                    SalesHeader."Document Type" := "Demand Subtype";
                    Text := Format(SalesHeader."Document Type");
                end;
            DATABASE::"Service Line":
                begin
                    ServHeader."Document Type" := "Demand Subtype";
                    Text := Format(ServHeader."Document Type");
                end;
            DATABASE::"Job Planning Line":
                begin
                    Job.Status := Status;
                    Text := Format(Job.Status);
                end;
            DATABASE::"Assembly Line":
                begin
                    AsmHeader."Document Type" := "Demand Subtype";
                    Text := Format(AsmHeader."Document Type");
                end;
        end
    end;

    local procedure DemandOrderNoOnFormat()
    begin
        DemandOrderNoHideValue := "Demand Line No." <> 0;
        DemandOrderNoEmphasize := Level = 0;
    end;

    local procedure DescriptionOnFormat()
    begin
        DescriptionIndent := Level + "Planning Level";
        DescriptionEmphasize := Level = 0;
    end;

    local procedure DemandQuantityOnFormat()
    begin
        DemandQuantityHideValue := Level = 0;
    end;

    local procedure DemandQtyAvailableOnFormat()
    begin
        DemandQtyAvailableHideValue := Level = 0;
    end;

    local procedure ReplenishmentSystemOnFormat()
    begin
        ReplenishmentSystemHideValue := "Replenishment System" = "Replenishment System"::" ";
    end;

    local procedure QuantityOnFormat()
    begin
        QuantityHideValue := Level = 0;
    end;

    local procedure ReserveOnFormat()
    begin
        ReserveEditable := Level <> 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowDemandOrder(var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterStatusTextOnFormat(var RequisitionLine: Record "Requisition Line"; var Text: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDemandTypeTextOnFormat(var RequisitionLine: Record "Requisition Line"; var Text: Text)
    begin
    end;
}

