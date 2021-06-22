page 99000818 "Prod. Order Components"
{
    AutoSplitKey = true;
    Caption = 'Prod. Order Components';
    DataCaptionExpression = Caption;
    DelayedInsert = true;
    MultipleNewLines = true;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Print/Send,Line';
    SourceTable = "Prod. Order Component";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the item that is a component in the production order component list.';

                    trigger OnValidate()
                    begin
                        ItemNoOnAfterValidate;
                    end;
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field("Due Date-Time"; "Due Date-Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the due date and the due time, which are combined in a format called "due date-time".';
                    Visible = false;
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the date when the produced item must be available. The date is copied from the header of the production order.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a description of the item on the line.';
                }
                field("Scrap %"; "Scrap %")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the percentage of the item that you expect to be scrapped in the production process.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Scrap37OnAfterValidate;
                    end;
                }
                field("Calculation Formula"; "Calculation Formula")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies how to calculate the Quantity field.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        CalculationFormulaOnAfterValid;
                    end;
                }
                field(Length; Length)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the length of one item unit when measured in the specified unit of measure.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        LengthOnAfterValidate;
                    end;
                }
                field(Width; Width)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the width of one item unit when measured in the specified unit of measure.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        WidthOnAfterValidate;
                    end;
                }
                field(Weight; Weight)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the weight of one item unit when measured in the specified unit of measure.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        WeightOnAfterValidate;
                    end;
                }
                field(Depth; Depth)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the depth of one item unit when measured in the specified unit of measure.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        DepthOnAfterValidate;
                    end;
                }
                field("Quantity per"; "Quantity per")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies how many units of the component are required to produce the parent item.';

                    trigger OnValidate()
                    begin
                        QuantityperOnAfterValidate;
                    end;
                }
                field("Reserved Quantity"; "Reserved Quantity")
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies how many units of this item have been reserved.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        ShowReservationEntries(true);
                        CurrPage.Update(false);
                    end;
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';

                    trigger OnValidate()
                    begin
                        UnitofMeasureCodeOnAfterValida;
                    end;
                }
                field("Flushing Method"; "Flushing Method")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies how consumption of the item (component) is calculated and handled in production processes. Manual: Enter and post consumption in the consumption journal manually. Forward: Automatically posts consumption according to the production order component lines when the first operation starts. Backward: Automatically calculates and posts consumption according to the production order component lines when the production order is finished. Pick + Forward / Pick + Backward: Variations with warehousing.';
                }
                field("Expected Quantity"; "Expected Quantity")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the quantity of the component expected to be consumed during the production of the quantity on this line.';
                }
                field("Remaining Quantity"; "Remaining Quantity")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the difference between the finished and planned quantities, or zero if the finished quantity is greater than the remaining quantity.';
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
                field("ShortcutDimCode[3]"; ShortcutDimCode[3])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,3';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(3),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(3, ShortcutDimCode[3]);
                    end;
                }
                field("ShortcutDimCode[4]"; ShortcutDimCode[4])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,4';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(4),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(4, ShortcutDimCode[4]);
                    end;
                }
                field("ShortcutDimCode[5]"; ShortcutDimCode[5])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,5';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(5),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(5, ShortcutDimCode[5]);
                    end;
                }
                field("ShortcutDimCode[6]"; ShortcutDimCode[6])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,6';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(6),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(6, ShortcutDimCode[6]);
                    end;
                }
                field("ShortcutDimCode[7]"; ShortcutDimCode[7])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,7';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(7),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(7, ShortcutDimCode[7]);
                    end;
                }
                field("ShortcutDimCode[8]"; ShortcutDimCode[8])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,8';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(8),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(8, ShortcutDimCode[8]);
                    end;
                }
                field("Routing Link Code"; "Routing Link Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the routing link code when you calculate the production order.';
                    Visible = false;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the location where the component is stored. Copies the location code from the corresponding field on the production order line.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        LocationCodeOnAfterValidate;
                    end;
                }
                field("Bin Code"; "Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin in which the component is to be placed before it is consumed.';
                }
                field("Unit Cost"; "Unit Cost")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the cost of one unit of the item or resource on the line.';
                    Visible = false;
                }
                field("Cost Amount"; "Cost Amount")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the total cost on the line by multiplying the unit cost by the quantity.';
                    Visible = false;
                }
                field(Position; Position)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the position of the component on the bill of material.';
                    Visible = false;
                }
                field("Position 2"; "Position 2")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the components position in the BOM. It is copied from the production BOM when you calculate the production order.';
                    Visible = false;
                }
                field("Position 3"; "Position 3")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the third reference number for the component position on a bill of material, such as the alternate position number of a component on a print card.';
                    Visible = false;
                }
                field("Lead-Time Offset"; "Lead-Time Offset")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the lead-time offset for the component line. It is copied from the corresponding field in the production BOM when you calculate the production order.';
                    Visible = false;
                }
                field("Qty. Picked"; "Qty. Picked")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the quantity of the item you have picked for the component line.';
                    Visible = false;
                }
                field("Qty. Picked (Base)"; "Qty. Picked (Base)")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the quantity of the item you have picked for the component line.';
                    Visible = false;
                }
                field("Substitution Available"; "Substitution Available")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies if an item substitute is available for the production order component.';
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
                group("Item Availability by")
                {
                    Caption = 'Item Availability by';
                    Image = ItemAvailability;
                    action("Event")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Event';
                        Image = "Event";
                        ToolTip = 'View how the actual and the projected available balance of an item will develop over time according to supply and demand events.';

                        trigger OnAction()
                        begin
                            ItemAvailFormsMgt.ShowItemAvailFromProdOrderComp(Rec, ItemAvailFormsMgt.ByEvent);
                        end;
                    }
                    action(Period)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Period';
                        Image = Period;
                        ToolTip = 'View the projected quantity of the item over time according to time periods, such as day, week, or month.';

                        trigger OnAction()
                        begin
                            ItemAvailFormsMgt.ShowItemAvailFromProdOrderComp(Rec, ItemAvailFormsMgt.ByPeriod);
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
                            ItemAvailFormsMgt.ShowItemAvailFromProdOrderComp(Rec, ItemAvailFormsMgt.ByVariant);
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
                            ItemAvailFormsMgt.ShowItemAvailFromProdOrderComp(Rec, ItemAvailFormsMgt.ByLocation);
                        end;
                    }
                    action("BOM Level")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'BOM Level';
                        Image = BOMLevel;
                        ToolTip = 'View availability figures for items on bills of materials that show how many units of a parent item you can make based on the availability of child items.';

                        trigger OnAction()
                        begin
                            ItemAvailFormsMgt.ShowItemAvailFromProdOrderComp(Rec, ItemAvailFormsMgt.ByBOM);
                        end;
                    }
                }
                action("Co&mments")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    Promoted = true;
                    PromotedCategory = Category5;
                    RunObject = Page "Prod. Order Comp. Cmt. Sheet";
                    RunPageLink = Status = FIELD(Status),
                                  "Prod. Order No." = FIELD("Prod. Order No."),
                                  "Prod. Order Line No." = FIELD("Prod. Order Line No."),
                                  "Prod. Order BOM Line No." = FIELD("Line No.");
                    ToolTip = 'View or add comments for the record.';
                }
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
                action(ItemTrackingLines)
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
                action("Bin Contents")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Bin Contents';
                    Image = BinContent;
                    Promoted = true;
                    PromotedCategory = Category5;
                    RunObject = Page "Bin Contents List";
                    RunPageLink = "Location Code" = FIELD("Location Code"),
                                  "Item No." = FIELD("Item No."),
                                  "Variant Code" = FIELD("Variant Code");
                    RunPageView = SORTING("Location Code", "Bin Code", "Item No.", "Variant Code");
                    ToolTip = 'View items in the bin if the selected line contains a bin code.';
                }
                action(SelectItemSubstitution)
                {
                    AccessByPermission = TableData "Item Substitution" = R;
                    ApplicationArea = Manufacturing;
                    Caption = '&Select Item Substitution';
                    Image = SelectItemSubstitution;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Select another item that has been set up to be traded instead of the original item if it is unavailable.';

                    trigger OnAction()
                    begin
                        CurrPage.SaveRecord;
                        ShowItemSub;
                        CurrPage.Update(true);
                        ReserveComp;
                    end;
                }
                action("Put-away/Pick Lines/Movement Lines")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Put-away/Pick Lines/Movement Lines';
                    Image = PutawayLines;
                    Promoted = true;
                    PromotedCategory = Category5;
                    RunObject = Page "Warehouse Activity Lines";
                    RunPageLink = "Source Type" = CONST(5407),
                                  "Source Subtype" = CONST("3"),
                                  "Source No." = FIELD("Prod. Order No."),
                                  "Source Line No." = FIELD("Prod. Order Line No."),
                                  "Source Subline No." = FIELD("Line No.");
                    RunPageView = SORTING("Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.", "Unit of Measure Code", "Action Type", "Breakbulk No.", "Original Breakbulk");
                    ToolTip = 'View the list of ongoing inventory put-aways, picks, or movements for the order.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(Reserve)
                {
                    ApplicationArea = Reservation;
                    Caption = '&Reserve';
                    Image = Reserve;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Reserve the quantity that is required on the document line that you opened this window for.';

                    trigger OnAction()
                    begin
                        if Status in [Status::Simulated, Status::Planned] then
                            Error(Text000, Status);

                        CurrPage.SaveRecord;
                        ShowReservation;
                    end;
                }
                action(OrderTracking)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Order &Tracking';
                    Image = OrderTracking;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Tracks the connection of a supply to its corresponding demand. This can help you find the original demand that created a specific production order or purchase order.';

                    trigger OnAction()
                    var
                        TrackingForm: Page "Order Tracking";
                    begin
                        TrackingForm.SetProdOrderComponent(Rec);
                        TrackingForm.RunModal;
                    end;
                }
            }
            action("&Print")
            {
                ApplicationArea = Manufacturing;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                Promoted = true;
                PromotedCategory = Category4;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                var
                    ProdOrderComp: Record "Prod. Order Component";
                begin
                    ProdOrderComp.Copy(Rec);
                    REPORT.RunModal(REPORT::"Prod. Order - Picking List", true, true, ProdOrderComp);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        ShowShortcutDimCode(ShortcutDimCode);
    end;

    trigger OnDeleteRecord(): Boolean
    var
        ReserveProdOrderComp: Codeunit "Prod. Order Comp.-Reserve";
    begin
        Commit();
        if not ReserveProdOrderComp.DeleteLineConfirm(Rec) then
            exit(false);
        ReserveProdOrderComp.DeleteLine(Rec);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(ShortcutDimCode);
    end;

    var
        Text000: Label 'You cannot reserve components with status %1.';
        ItemAvailFormsMgt: Codeunit "Item Availability Forms Mgt";
        ShortcutDimCode: array[8] of Code[20];

    procedure ReserveComp()
    var
        Item: Record Item;
    begin
        OnBeforeReserveComp(Rec, xRec);

        if (xRec."Remaining Qty. (Base)" <> "Remaining Qty. (Base)") or
           (xRec."Item No." <> "Item No.") or
           (xRec."Location Code" <> "Location Code")
        then
            if Item.Get("Item No.") then
                if Item.Reserve = Item.Reserve::Always then begin
                    CurrPage.SaveRecord;
                    AutoReserve;
                    CurrPage.Update(false);
                end;
    end;

    local procedure ItemNoOnAfterValidate()
    begin
        ReserveComp;
    end;

    local procedure Scrap37OnAfterValidate()
    begin
        ReserveComp;
    end;

    local procedure CalculationFormulaOnAfterValid()
    begin
        ReserveComp;
    end;

    local procedure LengthOnAfterValidate()
    begin
        ReserveComp;
    end;

    local procedure WidthOnAfterValidate()
    begin
        ReserveComp;
    end;

    local procedure WeightOnAfterValidate()
    begin
        ReserveComp;
    end;

    local procedure DepthOnAfterValidate()
    begin
        ReserveComp;
    end;

    local procedure QuantityperOnAfterValidate()
    begin
        ReserveComp;
    end;

    local procedure UnitofMeasureCodeOnAfterValida()
    begin
        ReserveComp;
    end;

    local procedure LocationCodeOnAfterValidate()
    begin
        ReserveComp;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReserveComp(var ProdOrderComp: Record "Prod. Order Component"; xProdOrderComp: Record "Prod. Order Component")
    begin
    end;
}

