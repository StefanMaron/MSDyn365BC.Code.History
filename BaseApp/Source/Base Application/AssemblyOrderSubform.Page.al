#if not CLEAN18
page 901 "Assembly Order Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    PageType = ListPart;
    PopulateAllFields = true;
    SourceTable = "Assembly Line";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Avail. Warning"; "Avail. Warning")
                {
                    ApplicationArea = Assembly;
                    BlankZero = true;
                    DrillDown = true;
                    ToolTip = 'Specifies Yes if the assembly component is not available in the quantity and on the due date of the assembly order line.';

                    trigger OnDrillDown()
                    begin
                        ShowAvailabilityWarningPage();
                    end;
                }
                field(Type; Type)
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies if the assembly order line is of type Item or Resource.';
                }
                field("No."; "No.")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnValidate()
                    begin
                        ReserveItem;
                    end;
                }
                field(Description; Description)
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the description of the assembly component.';
                }
                field("Description 2"; "Description 2")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the second description of the assembly component.';
                    Visible = false;
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';

                    trigger OnValidate()
                    begin
                        ReserveItem;
                    end;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the location from which you want to post consumption of the assembly component.';

                    trigger OnValidate()
                    begin
                        ReserveItem;
                    end;
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';

                    trigger OnValidate()
                    begin
                        ReserveItem;
                    end;
                }
                field("Quantity per"; "Quantity per")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies how many units of the assembly component are required to assemble one assembly item.';

                    trigger OnValidate()
                    begin
                        ReserveItem;
                    end;
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies how many units of the assembly component are expected to be consumed.';

                    trigger OnValidate()
                    begin
                        ReserveItem;
                    end;
                }
                field("Quantity to Consume"; "Quantity to Consume")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies how many units of the assembly component you want to post as consumed when you post the assembly order.';
                }
                field("Consumed Quantity"; "Consumed Quantity")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies how many units of the assembly component have been posted as consumed during the assembly.';
                }
                field("Remaining Quantity"; "Remaining Quantity")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies how many units of the assembly component remain to be consumed during assembly.';
                }
                field("Qty. Picked"; "Qty. Picked")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how many units of the assembly component have been moved or picked for the assembly order line.';
                    Visible = false;
                }
                field("Pick Qty."; "Pick Qty.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how many units of the assembly component are currently on warehouse pick lines.';
                    Visible = false;
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the date when the assembly component must be available for consumption by the assembly order.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ReserveItem;
                    end;
                }
                field("Lead-Time Offset"; "Lead-Time Offset")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the lead-time offset that is defined for the assembly component on the assembly BOM.';
                    Visible = false;
                }
                field("Bin Code"; "Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the bin where assembly components must be placed prior to assembly and from where they are posted as consumed.';
                    Visible = false;
                }
                field("Inventory Posting Group"; "Inventory Posting Group")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies links between business transactions made for the item and an inventory account in the general ledger, to group amounts for that item type.';
                    Visible = false;
                }
                field("Unit Cost"; "Unit Cost")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the cost of one unit of the item or resource on the line.';
                }
                field("Cost Amount"; "Cost Amount")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the cost of the assembly order line.';
                }
                field("Reserved Quantity"; "Reserved Quantity")
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies how many units of the assembly component have been reserved for this assembly order line.';
                }
                field(Reserve; Reserve)
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies the reserve option for the assembly order line.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ReserveItem;
                    end;
                }
                field(ReservationStatusField; ReservationStatusField)
                {
                    ApplicationArea = Reservation;
                    Caption = 'Reservation Status';
                    Editable = false;
                    OptionCaption = ' ,Partial,Full';
                    ToolTip = 'Specifies if the value in the Quantity field on the assembly order line is fully or partially reserved.';
                    Visible = false;
                }
                field("Qty. per Unit of Measure"; "Qty. per Unit of Measure")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the quantity per unit of measure of the component item on the assembly order line.';
                }
                field("Resource Usage Type"; "Resource Usage Type")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies how the cost of the resource on the assembly order line is allocated to the assembly item.';
                }
                field("Appl.-to Item Entry"; "Appl.-to Item Entry")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the number of the item ledger entry that the document or journal line is applied to.';
                }
                field("Appl.-from Item Entry"; "Appl.-from Item Entry")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the number of the item ledger entry that the document or journal line is applied from.';
                }
                field("Gen. Bus. Posting Group"; "Gen. Bus. Posting Group")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the code for the Gen. Bus. Posting Group that applies to the entry.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Advanced Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
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
                    Visible = DimVisible3;

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
                    Visible = DimVisible4;

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
                    Visible = DimVisible5;

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
                    Visible = DimVisible6;

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
                    Visible = DimVisible7;

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
                    Visible = DimVisible8;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(8, ShortcutDimCode[8]);
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
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
                        ApplicationArea = Assembly;
                        Caption = 'Event';
                        Image = "Event";
                        ToolTip = 'View how the actual and the projected available balance of an item will develop over time according to supply and demand events.';

                        trigger OnAction()
                        begin
                            ItemAvailFormsMgt.ShowItemAvailFromAsmLine(Rec, ItemAvailFormsMgt.ByEvent);
                        end;
                    }
                    action(Period)
                    {
                        ApplicationArea = Assembly;
                        Caption = 'Period';
                        Image = Period;
                        ToolTip = 'View the projected quantity of the item over time according to time periods, such as day, week, or month.';

                        trigger OnAction()
                        begin
                            ItemAvailFormsMgt.ShowItemAvailFromAsmLine(Rec, ItemAvailFormsMgt.ByPeriod);
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
                            ItemAvailFormsMgt.ShowItemAvailFromAsmLine(Rec, ItemAvailFormsMgt.ByVariant);
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
                            ItemAvailFormsMgt.ShowItemAvailFromAsmLine(Rec, ItemAvailFormsMgt.ByLocation);
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
                            ItemAvailFormsMgt.ShowItemAvailFromAsmLine(Rec, ItemAvailFormsMgt.ByBOM);
                        end;
                    }
                }
                action("Reservation Entries")
                {
                    AccessByPermission = TableData Item = R;
                    ApplicationArea = Reservation;
                    Caption = 'Reservation Entries';
                    Image = ReservationLedger;
                    ToolTip = 'View the entries for every reservation that is made, either manually or automatically.';

                    trigger OnAction()
                    begin
                        ShowReservationEntries(true);
                    end;
                }
                action("Item Tracking Lines")
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
                action("Show Warning")
                {
                    ApplicationArea = Assembly;
                    Caption = 'Show Warning';
                    Image = ShowWarning;
                    ToolTip = 'View details about availability issues.';

                    trigger OnAction()
                    begin
                        ShowAvailabilityWarning;
                    end;
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
                        ShowDimensions();
                    end;
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Assembly Comment Sheet";
                    RunPageLink = "Document Type" = FIELD("Document Type"),
                                  "Document No." = FIELD("Document No."),
                                  "Document Line No." = FIELD("Line No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action(AssemblyBOM)
                {
                    ApplicationArea = Assembly;
                    Caption = 'Assembly BOM';
                    Image = AssemblyBOM;
                    ToolTip = 'View or edit the bill of material that specifies which items and resources are required to assemble the assembly item.';

                    trigger OnAction()
                    begin
                        ShowAssemblyList;
                    end;
                }
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(SelectItemSubstitution)
                {
                    ApplicationArea = Assembly;
                    Caption = 'Select Item Substitution';
                    Image = SelectItemSubstitution;
                    ToolTip = 'Select another item that has been set up to be traded instead of the original item if it is unavailable.';

                    trigger OnAction()
                    begin
                        CurrPage.SaveRecord;
                        ShowItemSub;
                        CurrPage.Update(true);
                        if (Reserve = Reserve::Always) and ("No." <> xRec."No.") then begin
                            AutoReserve();
                            CurrPage.Update(false);
                        end;
                    end;
                }
                action(ExplodeBOM)
                {
                    ApplicationArea = Assembly;
                    Caption = 'E&xplode BOM';
                    Image = ExplodeBOM;
                    ToolTip = 'Insert new lines for the components on the bill of materials, for example to sell the parent item as a kit. CAUTION: The line for the parent item will be deleted and represented by a description only. To undo, you must delete the component lines and add a line the parent item again.';

                    trigger OnAction()
                    begin
                        ExplodeAssemblyList;
                        CurrPage.Update();
                    end;
                }
                action("Reserve Item")
                {
                    ApplicationArea = Reservation;
                    Caption = '&Reserve';
                    Ellipsis = true;
                    Image = Reserve;
                    ToolTip = 'Reserve the quantity that is required on the document line that you opened this window for.';

                    trigger OnAction()
                    begin
                        ShowReservation();
                    end;
                }
                action("Order &Tracking")
                {
                    ApplicationArea = Planning;
                    Caption = 'Order &Tracking';
                    Image = OrderTracking;
                    ToolTip = 'Tracks the connection of a supply to its corresponding demand. This can help you find the original demand that created a specific production order or purchase order.';

                    trigger OnAction()
                    begin
                        ShowTracking();
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        ShowShortcutDimCode(ShortcutDimCode);
        ReservationStatusField := ReservationStatus;
    end;

    trigger OnDeleteRecord(): Boolean
    var
        AssemblyLineReserve: Codeunit "Assembly Line-Reserve";
    begin
        if (Quantity <> 0) and ItemExists("No.") then begin
            Commit();
            if not AssemblyLineReserve.DeleteLineConfirm(Rec) then
                exit(false);
            AssemblyLineReserve.DeleteLine(Rec);
        end;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(ShortcutDimCode);
    end;

    trigger OnOpenPage()
    begin
        SetDimensionsVisibility;
    end;

    var
        ItemAvailFormsMgt: Codeunit "Item Availability Forms Mgt";
        ReservationStatusField: Option " ",Partial,Full;

    protected var
        ShortcutDimCode: array[8] of Code[20];
        DimVisible1: Boolean;
        DimVisible2: Boolean;
        DimVisible3: Boolean;
        DimVisible4: Boolean;
        DimVisible5: Boolean;
        DimVisible6: Boolean;
        DimVisible7: Boolean;
        DimVisible8: Boolean;

    protected procedure ReserveItem()
    begin
        if Type <> Type::Item then
            exit;

        if ("Remaining Quantity (Base)" <> xRec."Remaining Quantity (Base)") or
           ("No." <> xRec."No.") or
           ("Location Code" <> xRec."Location Code") or
           ("Variant Code" <> xRec."Variant Code") or
           ("Due Date" <> xRec."Due Date") or
           ((Reserve <> xRec.Reserve) and ("Remaining Quantity (Base)" <> 0))
        then
            if Reserve = Reserve::Always then begin
                CurrPage.SaveRecord;
                AutoReserve();
                CurrPage.Update(false);
            end;

        ReservationStatusField := ReservationStatus;
    end;

    local procedure SetDimensionsVisibility()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimVisible1 := false;
        DimVisible2 := false;
        DimVisible3 := false;
        DimVisible4 := false;
        DimVisible5 := false;
        DimVisible6 := false;
        DimVisible7 := false;
        DimVisible8 := false;

        DimMgt.UseShortcutDims(
          DimVisible1, DimVisible2, DimVisible3, DimVisible4, DimVisible5, DimVisible6, DimVisible7, DimVisible8);

        Clear(DimMgt);
    end;
}

#endif