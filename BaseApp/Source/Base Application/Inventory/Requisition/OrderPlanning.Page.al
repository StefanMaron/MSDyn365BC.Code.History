﻿namespace Microsoft.Inventory.Requisition;

using Microsoft.Assembly.Document;
using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Routing;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;
using Microsoft.Sales.Document;
using Microsoft.Service.Document;

page 5522 "Order Planning"
{
    AdditionalSearchTerms = 'supply planning,mrp,material requirements planning,mps,master production schedule';
    ApplicationArea = Planning;
    Caption = 'Order Planning';
    InsertAllowed = false;
    PageType = Worksheet;
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
                        DemandOrderFilterOnAfterValida();
                    end;
                }
            }
            repeater(Control1)
            {
                IndentationColumn = DescriptionIndent;
                IndentationControls = Description;
                ShowAsTree = true;
                ShowCaption = false;
                field("Demand Date"; Rec."Demand Date")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the demanded date of the demand that the planning line represents.';
                }
                field(StatusText; StatusText)
                {
                    ApplicationArea = Planning;
                    CaptionClass = Rec.FieldCaption(Status);
                    Editable = false;
                    HideValue = StatusHideValue;
                }
                field(DemandTypeText; DemandTypeText)
                {
                    ApplicationArea = Planning;
                    CaptionClass = Rec.FieldCaption("Demand Type");
                    Editable = false;
                    HideValue = DemandTypeHideValue;
                    Lookup = false;
                    Style = Strong;
                    StyleExpr = DemandTypeEmphasize;
                }
                field(DemandSubtypeText; DemandSubtypeText)
                {
                    ApplicationArea = Planning;
                    CaptionClass = Rec.FieldCaption("Demand Subtype");
                    Editable = false;
                    Visible = false;
                }
                field("Demand Order No."; Rec."Demand Order No.")
                {
                    ApplicationArea = Planning;
                    Caption = 'Order No.';
                    HideValue = DemandOrderNoHideValue;
                    Style = Strong;
                    StyleExpr = DemandOrderNoEmphasize;
                    ToolTip = 'Specifies the number of the demanded order that represents the planning line.';
                }
                field("Demand Line No."; Rec."Demand Line No.")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the line number of the demand, such as a sales order line.';
                    Visible = false;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Planning;
                    Caption = 'Item No.';
                    Editable = false;
                    ToolTip = 'Specifies the number of the item with insufficient availability and must be planned.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    Editable = false;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the bin of the item on the line.';
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies a code for an inventory location where the items that are being ordered will be registered.';
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Planning;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = DescriptionEmphasize;
                    ToolTip = 'Specifies text that describes the entry.';
                }
                field("Demand Quantity"; Rec."Demand Quantity")
                {
                    ApplicationArea = Planning;
                    HideValue = DemandQuantityHideValue;
                    ToolTip = 'Specifies the quantity on the demand that the planning line represents.';
                    Visible = false;
                }
                field("Demand Qty. Available"; Rec."Demand Qty. Available")
                {
                    ApplicationArea = Planning;
                    HideValue = DemandQtyAvailableHideValue;
                    ToolTip = 'Specifies how many of the demand quantity are available.';
                    Visible = false;
                }
                field("Needed Quantity"; Rec."Needed Quantity")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the demand quantity that is not available and must be ordered to meet the demand represented on the planning line.';
                    Visible = true;
                }
                field("Replenishment System"; Rec."Replenishment System")
                {
                    ApplicationArea = Planning;
                    HideValue = ReplenishmentSystemHideValue;
                    ToolTip = 'Specifies which kind of order to use to create replenishment orders and order proposals.';

                    trigger OnValidate()
                    begin
                        ReplenishmentSystemOnAfterVali();
                    end;
                }
                field("Supply From"; Rec."Supply From")
                {
                    ApplicationArea = Planning;
                    Editable = SupplyFromEditable;
                    ToolTip = 'Specifies a value, according to the selected replenishment system, before a supply order can be created for the line.';
                }
                field(Reserve; Rec.Reserve)
                {
                    ApplicationArea = Reservation;
                    Editable = ReserveEditable;
                    ToolTip = 'Specifies whether the item on the planning line has a setting of Always in the Reserve field on its item card.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Assembly;
                    Caption = 'Qty. to Order';
                    HideValue = QuantityHideValue;
                    ToolTip = 'Specifies the quantity that will be ordered on the supply order, such as purchase or assembly, that you can create from the planning line.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                    Visible = false;
                }
                field("Order Date"; Rec."Order Date")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the date when the related order was created.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the starting date of the manufacturing process, if the planned supply is a production order.';
                    Visible = false;
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the date when you can expect to receive the items.';
                }
                field("Unit Cost"; Rec."Unit Cost")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the cost of one unit of the item or resource on the line.';
                    Visible = false;
                }
                field("Direct Unit Cost"; Rec."Direct Unit Cost")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the cost of one unit of the selected item or resource.';
                    Visible = false;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the currency code for the requisition lines.';
                    Visible = false;
                }
                field("Purchasing Code"; Rec."Purchasing Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the code for a special procurement method, such as drop shipment.';
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
            }
            group(Control38)
            {
                ShowCaption = false;
                group("Available for Transfer")
                {
                    ShowCaption = false;

                    field(AvailableForTransfer; QtyOnOtherLocations)
                    {
                        ApplicationArea = Location;
                        Caption = 'Available For Transfer';
                        DecimalPlaces = 0 : 5;
                        Editable = false;
                        ToolTip = 'Specifies the quantity of the item on the active planning line, that is available on another location than the one defined.';
                    }
                }
                group("Substitutes Exist")
                {
                    ShowCaption = false;

                    field(SubstitionAvailable; format(SubstitionAvailable))
                    {
                        ApplicationArea = Planning;
                        Caption = 'Substitutes Exist';
                        DrillDown = false;
                        Editable = false;
                        Lookup = false;
                        ToolTip = 'Specifies if a substitute item exists for the component on the planning line.';
                    }
                }
                group("Quantity Available")
                {
                    ShowCaption = false;

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
                    ShowCaption = false;

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
                    ToolTip = 'Open the document that the selected line exists on.';

                    trigger OnAction()
                    begin
                        ShowDemandOrder();
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
                    RunObject = Page "Planning Components";
                    RunPageLink = "Worksheet Template Name" = field("Worksheet Template Name"),
                                  "Worksheet Batch Name" = field("Journal Batch Name"),
                                  "Worksheet Line No." = field("Line No.");
                    ToolTip = 'View or edit the production order components of the parent item on the line.';
                    ShortCutKey = 'Ctrl+Alt+C';
                }
                action("Ro&uting")
                {
                    ApplicationArea = Planning;
                    Caption = 'Ro&uting';
                    Image = Route;
                    RunObject = Page "Planning Routing";
                    RunPageLink = "Worksheet Template Name" = field("Worksheet Template Name"),
                                  "Worksheet Batch Name" = field("Journal Batch Name"),
                                  "Worksheet Line No." = field("Line No.");
                    ToolTip = 'View or edit the operations list of the parent item on the line.';
                    ShortCutKey = 'Ctrl+Alt+R';
                }
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
                        Rec.ShowDimensions();
                        CurrPage.SaveRecord();
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
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';

                    trigger OnAction()
                    var
                        Item: Record Item;
                    begin
                        Rec.TestField(Type, Rec.Type::Item);
                        Rec.TestField("No.");
                        Item."No." := Rec."No.";
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
                        ToolTip = 'View how the actual and the projected available balance of an item will develop over time according to supply and demand events.';

                        trigger OnAction()
                        begin
                            ItemAvailFormsMgt.ShowItemAvailFromReqLine(Rec, ItemAvailFormsMgt.ByEvent());
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
                            ItemAvailFormsMgt.ShowItemAvailFromReqLine(Rec, ItemAvailFormsMgt.ByPeriod());
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
                            ItemAvailFormsMgt.ShowItemAvailFromReqLine(Rec, ItemAvailFormsMgt.ByVariant());
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
                            ItemAvailFormsMgt.ShowItemAvailFromReqLine(Rec, ItemAvailFormsMgt.ByLocation());
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
                            ItemAvailFormsMgt.ShowItemAvailFromReqLine(Rec, ItemAvailFormsMgt.ByBOM());
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
                    ToolTip = 'Start the calculation of supply orders needed to fulfill the specified demand. Remember that each time, you choose the Calculate Plan action, only one product level is planned.';

                    trigger OnAction()
                    begin
                        CalcPlan();
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
                        CurrPage.SaveRecord();
                        Rec.ShowReservation();
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
                action("Refresh &Planning Line")
                {
                    ApplicationArea = Planning;
                    Caption = 'Refresh &Planning Line';
                    Ellipsis = true;
                    Image = RefreshPlanningLine;
                    ToolTip = 'Update the planning components and the routing lines for the selected planning line with any changes.';

                    trigger OnAction()
                    var
                        ReqLine2: Record "Requisition Line";
                    begin
                        ReqLine2.SetRange("Worksheet Template Name", Rec."Worksheet Template Name");
                        ReqLine2.SetRange("Journal Batch Name", Rec."Journal Batch Name");
                        ReqLine2.SetRange("Line No.", Rec."Line No.");

                        REPORT.RunModal(REPORT::"Refresh Planning Demand", true, false, ReqLine2);
                    end;
                }
                separator(Action36)
                {
                }
                action("Alternative Supply")
                {
                    ApplicationArea = Planning;
                    Caption = 'Alternative Supply';
                    Image = TransferToLines;
                    ToolTip = 'Get alternative supply locations for the selected line.';

                    trigger OnAction()
                    begin
                        OrderPlanningMgt.InsertAltSupplyLocation(Rec);
                    end;
                }

                action(Substitutes)
                {
                    ApplicationArea = Planning;
                    Caption = 'Select Item Substitutes';
                    Image = SelectItemSubstitution;
                    ToolTip = 'Get substitutes for the selected line.';

                    trigger OnAction()
                    var
                        ReqLine2: Record "Requisition Line";
                        xReqLine: Record "Requisition Line";
                        ReqLine3: Record "Requisition Line";
                    begin
                        ReqLine3 := Rec;
                        OrderPlanningMgt.InsertAltSupplySubstitution(ReqLine3);
                        Rec := ReqLine3;
                        Rec.Modify();

                        if OrderPlanningMgt.DeleteLine() then begin
                            xReqLine := Rec;
                            ReqLine2.SetCurrentKey("User ID", "Demand Type", "Demand Subtype", "Demand Order No.");
                            ReqLine2.SetRange("User ID", UserId);
                            ReqLine2.SetRange("Demand Type", Rec."Demand Type");
                            ReqLine2.SetRange("Demand Subtype", Rec."Demand Subtype");
                            ReqLine2.SetRange("Demand Order No.", Rec."Demand Order No.");
                            ReqLine2.SetRange(Level, Rec.Level, Rec.Level + 1);
                            ReqLine2.SetFilter("Line No.", '<>%1', Rec."Line No.");
                            if not ReqLine2.FindFirst() then begin // No other children
                                ReqLine2.SetRange("Line No.");
                                ReqLine2.SetRange(Level, 0);
                                if ReqLine2.FindFirst() then begin // Find and delete parent
                                    Rec := ReqLine2;
                                    Rec.Delete();
                                end;
                            end;

                            Rec := xReqLine;
                            Rec.Delete();
                            CurrPage.Update(false);
                        end else
                            CurrPage.Update(true);
                    end;
                }
            }
            action("Make &Orders")
            {
                ApplicationArea = Planning;
                Caption = 'Make &Orders';
                Ellipsis = true;
                Image = NewOrder;
                ToolTip = 'Create the suggested supply orders according to options that you specify in a new window.';

                trigger OnAction()
                var
                    ActionMsgCarriedOut: Boolean;
                begin
                    ActionMsgCarriedOut := MakeSupplyOrders();

                    if ActionMsgCarriedOut then begin
                        RefreshTempTable();
                        SetRecFilters();
                        CurrPage.Update(false);
                    end;
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(CalculatePlan_Promoted; CalculatePlan)
                {
                }
                actionref("Make &Orders_Promoted"; "Make &Orders")
                {
                }
                actionref("Refresh &Planning Line_Promoted"; "Refresh &Planning Line")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Line', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref("Show Document_Promoted"; "Show Document")
                {
                }
                actionref(Card_Promoted; Card)
                {
                }
                actionref("Alternative Supply_Promoted"; "Alternative Supply")
                {
                }
                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref(Substitutes_Promoted; Substitutes)
                {
                }
                actionref(Components_Promoted; Components)
                {
                }
                actionref("Ro&uting_Promoted"; "Ro&uting")
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Item', Comment = 'Generated from the PromotedActionCategories property index 4.';

            }
            group(Category_Category6)
            {
                Caption = 'Item Availability by', Comment = 'Generated from the PromotedActionCategories property index 5.';

                actionref(Event_Promoted; "Event")
                {
                }
                actionref(Location_Promoted; Location)
                {
                }
                actionref("BOM Level_Promoted"; "BOM Level")
                {
                }
                actionref(Period_Promoted; Period)
                {
                }
                actionref(Variant_Promoted; Variant)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        if ReqLine.Get(Rec."Worksheet Template Name", Rec."Journal Batch Name", Rec."Line No.") then begin
            Rec := ReqLine;
            Rec.Modify();
            OnUpdateReqLineOnAfterGetCurrRecord(Rec);
        end else
            if Rec.Get(Rec."Worksheet Template Name", Rec."Journal Batch Name", Rec."Line No.") then
                Rec.Delete();

        UpdateSupplyFrom();
        CalcItemAvail();
    end;

    trigger OnAfterGetRecord()
    begin
        DescriptionIndent := 0;
        StatusText := Format(Rec.Status);
        StatusTextOnFormat(StatusText);
        DemandTypeText := Format(Rec."Demand Type");
        DemandTypeTextOnFormat(DemandTypeText);
        DemandSubtypeText := Format(Rec."Demand Subtype");
        DemandSubtypeTextOnFormat(DemandSubtypeText);
        DemandOrderNoOnFormat();
        DescriptionOnFormat();
        DemandQuantityOnFormat();
        DemandQtyAvailableOnFormat();
        ReplenishmentSystemOnFormat();
        QuantityOnFormat();
        ReserveOnFormat();
    end;

    trigger OnDeleteRecord(): Boolean
    var
        xReqLine: Record "Requisition Line";
    begin
        xReqLine := Rec;
        while (Rec.Next() <> 0) and (Rec.Level > xReqLine.Level) do
            Rec.Delete(true);
        Rec := xReqLine;
        xReqLine.Delete(true);
        Rec.Delete();
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
        ReqLine.Get(Rec."Worksheet Template Name", Rec."Journal Batch Name", Rec."Line No.");
        ReqLine.TransferFields(Rec, false);
        ReqLine.Modify(true);

        CurrPage.Update(false);
    end;

    trigger OnOpenPage()
    begin
        if not MfgUserTempl.Get(UserId) then begin
            MfgUserTempl.Init();
            MfgUserTempl."User ID" := CopyStr(UserId(), 1, MaxStrLen(Rec."User ID"));
            MfgUserTempl."Make Orders" := MfgUserTempl."Make Orders"::"The Active Order";
            MfgUserTempl."Create Purchase Order" := MfgUserTempl."Create Purchase Order"::"Make Purch. Orders";
            MfgUserTempl."Create Production Order" := MfgUserTempl."Create Production Order"::"Firm Planned";
            MfgUserTempl."Create Transfer Order" := MfgUserTempl."Create Transfer Order"::"Make Trans. Orders";
            MfgUserTempl."Create Assembly Order" := MfgUserTempl."Create Assembly Order"::"Make Assembly Orders";
            MfgUserTempl.Insert();
        end;

        InitTempRec();
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
        StatusHideValue: Boolean;
        StatusText: Text[1024];
        DemandTypeHideValue: Boolean;
        DemandTypeEmphasize: Boolean;
        DemandTypeText: Text[1024];
        DemandSubtypeText: Text[1024];
        DemandOrderNoHideValue: Boolean;
        DemandOrderNoEmphasize: Boolean;
        DescriptionEmphasize: Boolean;
        DescriptionIndent: Integer;
        SupplyFromEditable: Boolean;
        ReserveEditable: Boolean;
        DemandOrderFilterCtrlEnable: Boolean;
        Text005: Label 'Assembly';
        QtyOnOtherLocations: Decimal;
        SubstitionAvailable: Boolean;
        QtyATP: Decimal;
        EarliestShptDateAvailable: Date;

    protected var
        DemandQuantityHideValue: Boolean;
        DemandQtyAvailableHideValue: Boolean;
        ReplenishmentSystemHideValue: Boolean;
        QuantityHideValue: Boolean;

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
        Rec.DeleteAll();

        ReqLine.Reset();
        ReqLine.CopyFilters(Rec);
        ReqLine.SetRange("User ID", UserId);
        ReqLine.SetRange("Worksheet Template Name", '');
        if ReqLine.FindSet() then
            repeat
                Rec := ReqLine;
                Rec.Insert();
                if ReqLine.Level = 0 then
                    FindReqLineForCursor(ReqLineWithCursor, ReqLine);
            until ReqLine.Next() = 0;

        if Rec.FindFirst() then
            if ReqLineWithCursor."Line No." > 0 then
                Rec := ReqLineWithCursor;

        SetRecFilters();
    end;

    protected procedure FindReqLineForCursor(var ReqLineWithCursor: Record "Requisition Line"; ActualReqLine: Record "Requisition Line")
    begin
        if ProdOrder."No." = '' then
            exit;

        if (ActualReqLine."Demand Type" = Database::"Prod. Order Component") and
           (ActualReqLine."Demand Subtype" = ProdOrder.Status.AsInteger()) and
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

        Rec.Reset();
        if Rec.Find('-') then
            repeat
                ReqLine := Rec;
                if not ReqLine.Find() or
                   ((Rec.Level = 0) and ((ReqLine.Next() = 0) or (ReqLine.Level = 0)))
                then begin
                    if Rec.Level = 0 then begin
                        ReqLine := Rec;
                        ReqLine.Find();
                        ReqLine.Delete(true);
                    end;
                    Rec.Delete();
                end;
            until Rec.Next() = 0;

        Rec.Copy(TempReqLine2);
    end;

    procedure SetRecFilters()
    begin
        Rec.Reset();
        Rec.FilterGroup(2);
        Rec.SetRange("User ID", UserId);
        Rec.SetRange("Worksheet Template Name", '');

        case DemandOrderFilter of
            DemandOrderFilter::"All Demands":
                begin
                    Rec.SetRange("Demand Type");
                    Rec.SetCurrentKey("User ID", "Worksheet Template Name", "Journal Batch Name", "Line No.");
                end;
            DemandOrderFilter::"Sales Demand":
                begin
                    Rec.SetRange("Demand Type", Database::"Sales Line");
                    Rec.SetCurrentKey("User ID", "Demand Type", "Worksheet Template Name", "Journal Batch Name", "Line No.");
                end;
            DemandOrderFilter::"Production Demand":
                begin
                    Rec.SetRange("Demand Type", Database::"Prod. Order Component");
                    Rec.SetCurrentKey("User ID", "Demand Type", "Worksheet Template Name", "Journal Batch Name", "Line No.");
                end;
            DemandOrderFilter::"Assembly Demand":
                begin
                    Rec.SetRange("Demand Type", Database::"Assembly Line");
                    Rec.SetCurrentKey("User ID", "Demand Type", "Worksheet Template Name", "Journal Batch Name", "Line No.");
                end;
            DemandOrderFilter::"Service Demand":
                begin
                    Rec.SetRange("Demand Type", Database::"Service Line");
                    Rec.SetCurrentKey("User ID", "Demand Type", "Worksheet Template Name", "Journal Batch Name", "Line No.");
                end;
            DemandOrderFilter::"Job Demand":
                begin
                    Rec.SetRange("Demand Type", Database::"Job Planning Line");
                    Rec.SetCurrentKey("User ID", "Demand Type", "Worksheet Template Name", "Journal Batch Name", "Line No.");
                end;
        end;
        Rec.FilterGroup(0);

        CurrPage.Update(false);
    end;

    local procedure ShowDemandOrder()
    var
        SalesHeader: Record "Sales Header";
        ProdOrder: Record "Production Order";
        ServHeader: Record "Service Header";
        Job: Record Job;
        AsmHeader: Record "Assembly Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowDemandOrder(Rec, IsHandled);
        if not IsHandled then
            case Rec."Demand Type" of
                Database::"Sales Line":
                    begin
                        SalesHeader.Get(Rec."Demand Subtype", Rec."Demand Order No.");
                        case SalesHeader."Document Type" of
                            SalesHeader."Document Type"::Order:
                                PAGE.Run(PAGE::"Sales Order", SalesHeader);
                            SalesHeader."Document Type"::"Return Order":
                                PAGE.Run(PAGE::"Sales Return Order", SalesHeader);
                        end;
                    end;
                Database::"Prod. Order Component":
                    begin
                        ProdOrder.Get(Rec."Demand Subtype", Rec."Demand Order No.");
                        case ProdOrder.Status of
                            ProdOrder.Status::Planned:
                                PAGE.Run(PAGE::"Planned Production Order", ProdOrder);
                            ProdOrder.Status::"Firm Planned":
                                PAGE.Run(PAGE::"Firm Planned Prod. Order", ProdOrder);
                            ProdOrder.Status::Released:
                                PAGE.Run(PAGE::"Released Production Order", ProdOrder);
                        end;
                    end;
                Database::"Assembly Line":
                    begin
                        AsmHeader.Get(Rec."Demand Subtype", Rec."Demand Order No.");
                        case AsmHeader."Document Type" of
                            AsmHeader."Document Type"::Order:
                                PAGE.Run(PAGE::"Assembly Order", AsmHeader);
                        end;
                    end;
                Database::"Service Line":
                    begin
                        ServHeader.Get(Rec."Demand Subtype", Rec."Demand Order No.");
                        case ServHeader."Document Type" of
                            ServHeader."Document Type"::Order:
                                PAGE.Run(PAGE::"Service Order", ServHeader);
                        end;
                    end;
                Database::"Job Planning Line":
                    begin
                        Job.Get(Rec."Demand Order No.");
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
        QtyOnOtherLocations := CalcQtyOnOtherLocations();
        SubstitionAvailable := CalcSubstitionAvailable();
        QtyATP := CalcQtyATP();
        EarliestShptDateAvailable := CalcEarliestShptDateAvailable();
    end;

    local procedure CalcQtyOnOtherLocations(): Decimal
    var
        QtyOnOtherLocation: Decimal;
    begin
        if Rec."No." = '' then
            exit;

        QtyOnOtherLocation := OrderPlanningMgt.AvailQtyOnOtherLocations(Rec); // Base Unit
        if Rec."Qty. per Unit of Measure" = 0 then
            Rec."Qty. per Unit of Measure" := 1;
        QtyOnOtherLocation := Round(QtyOnOtherLocation / Rec."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());

        exit(QtyOnOtherLocation);
    end;

    local procedure CalcQtyATP(): Decimal
    var
        QtyATP: Decimal;
    begin
        if Rec."No." = '' then
            exit;

        QtyATP := OrderPlanningMgt.CalcATPQty(Rec."No.", Rec."Variant Code", Rec."Location Code", Rec."Demand Date"); // Base Unit
        if Rec."Qty. per Unit of Measure" = 0 then
            Rec."Qty. per Unit of Measure" := 1;
        QtyATP := Round(QtyATP / Rec."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());

        exit(QtyATP);
    end;

    local procedure CalcEarliestShptDateAvailable(): Date
    var
        Item: Record Item;
    begin
        if Rec."No." = '' then
            exit;

        Item.Get(Rec."No.");
        if Item."Order Tracking Policy" = Item."Order Tracking Policy"::"Tracking & Action Msg." then
            exit;

        exit(OrderPlanningMgt.CalcATPEarliestDate(Rec."No.", Rec."Variant Code", Rec."Location Code", Rec."Demand Date", Rec."Quantity (Base)"));
    end;

    local procedure CalcSubstitionAvailable(): Boolean
    begin
        if Rec."No." = '' then
            exit;

        exit(OrderPlanningMgt.SubstitutionPossible(Rec));
    end;

    protected procedure CalcPlan()
    var
        ReqLine: Record "Requisition Line";
    begin
        Rec.Reset();
        Rec.DeleteAll();

        Clear(OrderPlanningMgt);
        case DemandOrderFilter of
            DemandOrderFilter::"Sales Demand":
                OrderPlanningMgt.SetSalesOrder();
            DemandOrderFilter::"Assembly Demand":
                OrderPlanningMgt.SetAsmOrder();
            DemandOrderFilter::"Production Demand":
                OrderPlanningMgt.SetProdOrder();
            DemandOrderFilter::"Service Demand":
                OrderPlanningMgt.SetServOrder();
            DemandOrderFilter::"Job Demand":
                OrderPlanningMgt.SetJobOrder();
        end;
        OnCalcPlanOnBeforeGetOrdersToPlan(ReqLine);
        OrderPlanningMgt.GetOrdersToPlan(ReqLine);

        InitTempRec();
    end;

    local procedure UpdateSupplyFrom()
    begin
        SupplyFromEditable := not (Rec."Replenishment System" in [Enum::"Replenishment System"::"Prod. Order",
                                                                  Enum::"Replenishment System"::Assembly]);
    end;

    local procedure DemandOrderFilterOnAfterValida()
    begin
        CurrPage.SaveRecord();
        SetRecFilters();
    end;

    local procedure ReplenishmentSystemOnAfterVali()
    begin
        UpdateSupplyFrom();
    end;

    local procedure StatusTextOnFormat(var Text: Text[1024])
    begin
        if Rec."Demand Line No." = 0 then
            case Rec."Demand Type" of
                Database::"Prod. Order Component":
                    Text := Format(Enum::"Production Order Status".FromInteger(Rec.Status));
                Database::"Sales Line":
                    Text := Format(Enum::"Sales Document Status".FromInteger(Rec.Status));
                Database::"Service Line":
                    Text := Format(Enum::"Service Document Status".FromInteger(Rec.Status));
                Database::"Job Planning Line":
                    Text := Format("Job Status".FromInteger(Rec.Status));
                Database::"Assembly Line":
                    begin
                        AsmHeader.Status := Rec.Status;
                        Text := Format(AsmHeader.Status);
                    end;
            end;

        OnAfterStatusTextOnFormat(Rec, Text);

        StatusHideValue := Rec."Demand Line No." <> 0;
    end;

    local procedure DemandTypeTextOnFormat(var Text: Text[1024])
    begin
        if Rec."Demand Line No." = 0 then
            case Rec."Demand Type" of
                Database::"Sales Line":
                    Text := Text001;
                Database::"Prod. Order Component":
                    Text := Text002;
                Database::"Service Line":
                    Text := Text003;
                Database::"Job Planning Line":
                    Text := Text004;
                Database::"Assembly Line":
                    Text := Text005;
            end;

        OnAfterDemandTypeTextOnFormat(Rec, Text);

        DemandTypeHideValue := Rec."Demand Line No." <> 0;
        DemandTypeEmphasize := Rec.Level = 0;
    end;

    local procedure DemandSubtypeTextOnFormat(var Text: Text[1024])
    begin
        case Rec."Demand Type" of
            Database::"Prod. Order Component":
                Text := Format(Enum::"Production Order Status".FromInteger(Rec.Status));
            Database::"Sales Line":
                Text := Format(Enum::"Sales Document Type".FromInteger(Rec."Demand Subtype"));
            Database::"Service Line":
                Text := Format(Enum::"Service Document Type".FromInteger(Rec."Demand Subtype"));
            Database::"Job Planning Line":
                Text := Format("Job Status".FromInteger(Rec.Status));
            Database::"Assembly Line":
                Text := Format(Enum::"Assembly Document Type".FromInteger(Rec."Demand Subtype"));
        end
    end;

    local procedure DemandOrderNoOnFormat()
    begin
        DemandOrderNoHideValue := Rec."Demand Line No." <> 0;
        DemandOrderNoEmphasize := Rec.Level = 0;
    end;

    local procedure DescriptionOnFormat()
    begin
        DescriptionIndent := Rec.Level + Rec."Planning Level";
        DescriptionEmphasize := Rec.Level = 0;
    end;

    local procedure DemandQuantityOnFormat()
    begin
        DemandQuantityHideValue := Rec.Level = 0;
    end;

    local procedure DemandQtyAvailableOnFormat()
    begin
        DemandQtyAvailableHideValue := Rec.Level = 0;
    end;

    local procedure ReplenishmentSystemOnFormat()
    begin
        ReplenishmentSystemHideValue := Rec."Replenishment System" = Rec."Replenishment System"::" ";
    end;

    local procedure QuantityOnFormat()
    begin
        QuantityHideValue := Rec.Level = 0;
    end;

    local procedure ReserveOnFormat()
    begin
        ReserveEditable := Rec.Level <> 0;
    end;

    local procedure MakeSupplyOrders() ActionMsgCarriedOut: Boolean
    var
        MakeSupplyOrdersYesNo: Codeunit "Make Supply Orders (Yes/No)";
        IsHandled: Boolean;
    begin
        OnBeforeMakeSupplyOrders(Rec, MfgUserTempl, ActionMsgCarriedOut, IsHandled);
        if IsHandled then
            exit;

        MakeSupplyOrdersYesNo.SetManufUserTemplate(MfgUserTempl);
        MakeSupplyOrdersYesNo.Run(Rec);
        ActionMsgCarriedOut := MakeSupplyOrdersYesNo.ActionMsgCarriedOut();
    end;

    procedure SetDemandOrderFilter(NewDemandOrderFilter: Option)
    begin
        DemandOrderFilter := NewDemandOrderFilter;
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

    [IntegrationEvent(false, false)]
    local procedure OnUpdateReqLineOnAfterGetCurrRecord(var TempRequisitionLine: Record "Requisition Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMakeSupplyOrders(var RequisitionLine: Record "Requisition Line"; ManufacturingUserTemplate: Record "Manufacturing User Template"; var ActionMsgCarriedOut: Boolean; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcPlanOnBeforeGetOrdersToPlan(var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowDemandOrder(var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;
}

