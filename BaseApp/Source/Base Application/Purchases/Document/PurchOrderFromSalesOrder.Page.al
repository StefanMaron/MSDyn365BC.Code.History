namespace Microsoft.Purchases.Document;

using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;
using Microsoft.Purchases.Vendor;

page 1328 "Purch. Order From Sales Order"
{
    Caption = 'Create Purchase Orders';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Worksheet;
    SourceTable = "Requisition Line";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    Style = Subordinate;
                    StyleExpr = Rec.Quantity = 0;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    Style = Subordinate;
                    StyleExpr = Rec.Quantity = 0;
                    ToolTip = 'Specifies a description of the purchase order.';
                }
                field("Demand Quantity"; Rec."Demand Quantity")
                {
                    ApplicationArea = Suite;
                    Caption = 'Sales Order Quantity';
                    Style = Subordinate;
                    StyleExpr = Rec.Quantity = 0;
                    ToolTip = 'Specifies the sales order quantity relating to the purchase order line item.';
                }
                field(Vendor; VendorName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Vendor';
                    ShowMandatory = true;
                    Style = Subordinate;
                    StyleExpr = Rec.Quantity = 0;
                    ToolTip = 'Specifies the vendor who will ship the items in the purchase order.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Vendor: Record Vendor;
                    begin
                        Rec.TestField("Replenishment System", Rec."Replenishment System"::Purchase);
                        if not Rec.LookupVendor(Vendor, false) then
                            exit;

                        Rec.SetCurrFieldNo(Rec.FieldNo("Supply From"));
                        Rec.Validate(Rec."Supply From", Vendor."No.");
                        VendorName := Vendor.Name;
                    end;

                    trigger OnValidate()
                    var
                        Vendor: Record Vendor;
                    begin
                        Rec.TestField("Replenishment System", Rec."Replenishment System"::Purchase);

                        Rec.SetCurrFieldNo(Rec.FieldNo("Supply From"));
                        Rec.Validate(Rec."Supply From", Vendor.GetVendorNo(VendorName));
                        if Vendor.Get(Rec."Supply From") then
                            VendorName := Vendor.Name
                        else
                            VendorName := Rec."Supply From";
                    end;
                }
                field(Quantity; Rec.Quantity)
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
                    Enabled = not ShowAllDocsIsEnable;
                    Image = Document;
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
                Enabled = Rec.Type = Rec.Type::Item;
                action("Event")
                {
                    ApplicationArea = Suite;
                    Caption = 'Event';
                    Image = "Event";
                    Scope = Repeater;
                    ToolTip = 'View how the actual and the projected available balance of an item will develop over time according to supply and demand events.';

                    trigger OnAction()
                    begin
                        ItemAvailFormsMgt.ShowItemAvailFromReqLine(Rec, ItemAvailFormsMgt.ByEvent())
                    end;
                }
                action(Period)
                {
                    ApplicationArea = Suite;
                    Caption = 'Period';
                    Image = Period;
                    Scope = Repeater;
                    ToolTip = 'Show the projected quantity of the item over time according to time periods, such as day, week, or month.';

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
                    Scope = Repeater;
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
                    Scope = Repeater;
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
                    Scope = Repeater;
                    ToolTip = 'View availability figures for items on bills of materials that show how many units of a parent item you can make based on the availability of child items.';

                    trigger OnAction()
                    begin
                        ItemAvailFormsMgt.ShowItemAvailFromReqLine(Rec, ItemAvailFormsMgt.ByBOM())
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(ShowAll_Promoted; ShowAll)
                {
                }
                actionref(ShowUnavailable_Promoted; ShowUnavailable)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Item Availability', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(Event_Promoted; "Event")
                {
                }
                actionref(Period_Promoted; Period)
                {
                }
                actionref(Variant_Promoted; Variant)
                {
                }
                actionref(Location_Promoted; Location)
                {
                }
                actionref("BOM Level_Promoted"; "BOM Level")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Vendor: Record Vendor;
    begin
        if Vendor.Get(Rec."Supply From") then
            VendorName := Vendor.Name
        else
            VendorName := '';
    end;

    trigger OnOpenPage()
    begin
        PlanForOrder();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::LookupOK then
            ValidateSupplyFromVendor();
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

        Rec.SetRange(Level, 1);

        Rec.SetRange("Replenishment System", Rec."Replenishment System"::Purchase);
        Rec.SetFilter(Quantity, '>%1', 0);
        if OrderNo <> '' then
            Rec.SetFilter("Demand Order No.", OrderNo);

        if Rec.IsEmpty() then begin
            AllItemsAreAvailableNotification.Message := EntireOrderIsAvailableTxt;
            AllItemsAreAvailableNotification.Scope := NOTIFICATIONSCOPE::LocalScope;
            AllItemsAreAvailableNotification.Send();
        end;
        Rec.SetRange(Quantity);
    end;

    local procedure SetProcessedDocumentsVisibility(ShowAll: Boolean)
    begin
        Rec.FilterGroup(0);
        if ShowAll then begin
            Rec.SetRange("Needed Quantity");
            ShowAllDocsIsEnable := false;
        end else begin
            Rec.SetFilter("Needed Quantity", '>%1', 0);
            ShowAllDocsIsEnable := true;
        end;
    end;

    local procedure ValidateSupplyFromVendor()
    var
        RecordsWithoutSupplyFromVendor: Boolean;
    begin
        Rec.SetRange("Supply From", '');
        Rec.SetFilter(Quantity, '>%1', 0);
        RecordsWithoutSupplyFromVendor := not Rec.IsEmpty();
        Rec.SetRange("Supply From");
        Rec.SetRange(Quantity);
        if RecordsWithoutSupplyFromVendor then
            Error(CannotCreatePurchaseOrderWithoutVendorErr);
    end;
}

