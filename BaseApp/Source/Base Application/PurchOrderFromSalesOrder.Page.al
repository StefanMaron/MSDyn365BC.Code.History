page 1328 "Purch. Order From Sales Order"
{
    Caption = 'Create Purchase Orders';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Worksheet;
    PromotedActionCategories = 'New,Process,Report,Item Availability';
    SourceTable = "Requisition Line";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("No."; "No.")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    Style = Subordinate;
                    StyleExpr = Quantity = 0;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    Style = Subordinate;
                    StyleExpr = Quantity = 0;
                    ToolTip = 'Specifies a description of the purchase order.';
                }
                field("Demand Quantity"; "Demand Quantity")
                {
                    ApplicationArea = Suite;
                    Caption = 'Sales Order Quantity';
                    Style = Subordinate;
                    StyleExpr = Quantity = 0;
                    ToolTip = 'Specifies the sales order quantity relating to the purchase order line item.';
                }
                field(Vendor; VendorName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Vendor';
                    ShowMandatory = true;
                    Style = Subordinate;
                    StyleExpr = Quantity = 0;
                    ToolTip = 'Specifies the vendor who will ship the items in the purchase order.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Vendor: Record Vendor;
                    begin
                        TestField("Replenishment System", "Replenishment System"::Purchase);
                        if not LookupVendor(Vendor, false) then
                            exit;

                        Validate("Supply From", Vendor."No.");
                        VendorName := Vendor.Name;
                    end;

                    trigger OnValidate()
                    var
                        Vendor: Record Vendor;
                    begin
                        TestField("Replenishment System", "Replenishment System"::Purchase);
                        Validate("Supply From", Vendor.GetVendorNo(VendorName));
                        if Vendor.Get("Supply From") then
                            VendorName := Vendor.Name
                        else
                            VendorName := "Supply From";
                    end;
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Suite;
                    Caption = 'Quantity to Purchase';
                    Style = Strong;
                    ToolTip = 'Specifies the quantity to be purchased.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("Set View")
            {
                Caption = 'Set View';
                action(ShowAll)
                {
                    ApplicationArea = Suite;
                    Caption = 'Show All';
                    Enabled = ShowAllDocsIsEnable;
                    Image = AllLines;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Show lines both for items that are fully available and for items where a sales quantity is unavailable and must be purchased.';

                    trigger OnAction()
                    begin
                        SetProcessedDocumentsVisibility(true);
                    end;
                }
                action(ShowUnavailable)
                {
                    ApplicationArea = Suite;
                    Caption = 'Show Unavailable';
                    Enabled = NOT ShowAllDocsIsEnable;
                    Image = Document;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Show lines only for items where a sales quantity is unavailable and must be purchased.';

                    trigger OnAction()
                    begin
                        SetProcessedDocumentsVisibility(false);
                    end;
                }
            }
        }
        area(navigation)
        {
            group("Item Availability by")
            {
                Caption = 'Item Availability by';
                Image = ItemAvailability;
                action("Event")
                {
                    ApplicationArea = Suite;
                    Caption = 'Event';
                    Image = "Event";
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedOnly = true;
                    Scope = Repeater;
                    ToolTip = 'View how the actual and the projected available balance of an item will develop over time according to supply and demand events.';

                    trigger OnAction()
                    begin
                        ItemAvailFormsMgt.ShowItemAvailFromReqLine(Rec, ItemAvailFormsMgt.ByEvent)
                    end;
                }
                action(Period)
                {
                    ApplicationArea = Suite;
                    Caption = 'Period';
                    Image = Period;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedOnly = true;
                    Scope = Repeater;
                    ToolTip = 'Show the projected quantity of the item over time according to time periods, such as day, week, or month.';

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
                    PromotedCategory = Category4;
                    PromotedOnly = true;
                    Scope = Repeater;
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
                    PromotedCategory = Category4;
                    PromotedOnly = true;
                    Scope = Repeater;
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
                    PromotedCategory = Category4;
                    PromotedOnly = true;
                    Scope = Repeater;
                    ToolTip = 'View availability figures for items on bills of materials that show how many units of a parent item you can make based on the availability of child items.';

                    trigger OnAction()
                    begin
                        ItemAvailFormsMgt.ShowItemAvailFromReqLine(Rec, ItemAvailFormsMgt.ByBOM)
                    end;
                }
                action(Timeline)
                {
                    ApplicationArea = Suite;
                    Caption = 'Timeline';
                    Image = Timeline;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedOnly = true;
                    Scope = Repeater;
                    ToolTip = 'Get a graphical view of an item''s projected inventory based on future supply and demand events, with or without planning suggestions. The result is a graphical representation of the inventory profile.';
                    Visible = false;

                    trigger OnAction()
                    begin
                        ShowTimeline(Rec);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Vendor: Record Vendor;
    begin
        if Vendor.Get("Supply From") then
            VendorName := Vendor.Name
        else
            VendorName := '';
    end;

    trigger OnOpenPage()
    begin
        PlanForOrder;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::LookupOK then
            ValidateSupplyFromVendor;
    end;

    var
        ItemAvailFormsMgt: Codeunit "Item Availability Forms Mgt";
        OrderNo: Code[20];
        EntireOrderIsAvailableTxt: Label 'All items on the sales order are available.';
        ShowAllDocsIsEnable: Boolean;
        VendorName: Text[100];
        CannotCreatePurchaseOrderWithoutVendorErr: Label 'You cannot create purchase orders without specifying a vendor for all lines.';

    procedure SetSalesOrderNo(SalesOrderNo: Code[20])
    begin
        OrderNo := SalesOrderNo;
    end;

    local procedure PlanForOrder()
    var
        OrderPlanningMgt: Codeunit "Order Planning Mgt.";
        AllItemsAreAvailableNotification: Notification;
    begin
        OrderPlanningMgt.PlanSpecificSalesOrder(Rec, OrderNo);
        SetRange(Level, 1);

        SetFilter("Replenishment System", '<>%1', "Replenishment System"::Purchase);
        if FindSet then
            repeat
                Validate("Replenishment System", "Replenishment System"::Purchase);
                Modify(true);
            until Next = 0;
        SetRange("Replenishment System");

        SetFilter(Quantity, '>%1', 0);
        if IsEmpty then begin
            AllItemsAreAvailableNotification.Message := EntireOrderIsAvailableTxt;
            AllItemsAreAvailableNotification.Scope := NOTIFICATIONSCOPE::LocalScope;
            AllItemsAreAvailableNotification.Send;
        end;
        SetRange(Quantity);
    end;

    local procedure SetProcessedDocumentsVisibility(ShowAll: Boolean)
    begin
        FilterGroup(0);
        if ShowAll then begin
            SetRange("Needed Quantity");
            ShowAllDocsIsEnable := false;
        end else begin
            SetFilter("Needed Quantity", '>%1', 0);
            ShowAllDocsIsEnable := true;
        end;
    end;

    local procedure ValidateSupplyFromVendor()
    var
        RecordsWithoutSupplyFromVendor: Boolean;
    begin
        SetRange("Supply From", '');
        SetFilter(Quantity, '>%1', 0);
        RecordsWithoutSupplyFromVendor := not IsEmpty;
        SetRange("Supply From");
        SetRange(Quantity);
        if RecordsWithoutSupplyFromVendor then
            Error(CannotCreatePurchaseOrderWithoutVendorErr);
    end;
}

