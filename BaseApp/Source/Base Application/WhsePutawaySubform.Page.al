page 5771 "Whse. Put-away Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    InsertAllowed = false;
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = ListPart;
    SourceTable = "Warehouse Activity Line";
    SourceTableView = WHERE("Activity Type" = CONST("Put-away"));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Action Type"; "Action Type")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the action type for the warehouse activity line.';
                    Visible = false;
                }
                field("Source Document"; "Source Document")
                {
                    ApplicationArea = Warehouse;
                    OptionCaption = ',Sales Order,,,Sales Return Order,Purchase Order,,,Purchase Return Order,Inbound Transfer,,Prod. Consumption';
                    ToolTip = 'Specifies the type of document that the line relates to.';
                }
                field("Source No."; "Source No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the source document that the entry originates from.';
                }
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the item number of the item to be handled, such as picked or put away.';
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies a description of the item on the line.';
                }
                field("Serial No."; "Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    Editable = false;
                    Lookup = false;
                    ToolTip = 'Specifies the serial number to handle in the document.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        SerialNoOnAfterValidate;
                    end;
                }
                field("Lot No."; "Lot No.")
                {
                    ApplicationArea = ItemTracking;
                    Editable = false;
                    Lookup = false;
                    ToolTip = 'Specifies the lot number to handle in the document.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        LotNoOnAfterValidate;
                    end;
                }
                field("Expiration Date"; "Expiration Date")
                {
                    ApplicationArea = ItemTracking;
                    Editable = false;
                    ToolTip = 'Specifies the expiration date of the serial/lot numbers if you are putting items away.';
                    Visible = false;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code for the location where the activity occurs.';
                    Visible = false;
                }
                field("Zone Code"; "Zone Code")
                {
                    ApplicationArea = Warehouse;
                    Editable = ZoneCodeEditable;
                    ToolTip = 'Specifies the zone code where the bin on this line is located.';
                    Visible = false;
                }
                field("Bin Code"; "Bin Code")
                {
                    ApplicationArea = Warehouse;
                    Editable = BinCodeEditable;
                    ToolTip = 'Specifies the bin where the items are picked or put away.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        BinCodeOnAfterValidate;
                    end;
                }
                field("Shelf No."; "Shelf No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the shelf number of the item for informational use.';
                    Visible = false;
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity of the item to be handled, such as received, put-away, or assigned.';
                }
                field("Qty. (Base)"; "Qty. (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity of the item to be handled, in the base unit of measure.';
                    Visible = false;
                }
                field("Qty. to Handle"; "Qty. to Handle")
                {
                    ApplicationArea = Warehouse;
                    Editable = QtyToHandleEditable;
                    ToolTip = 'Specifies how many units to handle in this warehouse activity.';

                    trigger OnValidate()
                    begin
                        QtytoHandleOnAfterValidate;
                    end;
                }
                field("Qty. Handled"; "Qty. Handled")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of items on the line that have been handled in this warehouse activity.';
                }
                field("Qty. to Handle (Base)"; "Qty. to Handle (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity of items to be handled in this warehouse activity.';
                    Visible = false;
                }
                field("Qty. Handled (Base)"; "Qty. Handled (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of items on the line that have been handled in this warehouse activity.';
                    Visible = false;
                }
                field("Qty. Outstanding"; "Qty. Outstanding")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of items that have not yet been handled for this warehouse activity line.';
                }
                field("Qty. Outstanding (Base)"; "Qty. Outstanding (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of items, expressed in the base unit of measure, that have not yet been handled for this warehouse activity line.';
                    Visible = false;
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the date when the warehouse activity must be completed.';
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Qty. per Unit of Measure"; "Qty. per Unit of Measure")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity per unit of measure of the item on the line.';
                }
                field("Destination Type"; "Destination Type")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies information about the type of destination, such as customer or vendor, associated with the warehouse activity line.';
                    Visible = false;
                }
                field("Destination No."; "Destination No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number or code of the customer, vendor or location related to the activity line.';
                    Visible = false;
                }
                field("Whse. Document Type"; "Whse. Document Type")
                {
                    ApplicationArea = Warehouse;
                    OptionCaption = ' ,Receipt,,Internal Put-away';
                    ToolTip = 'Specifies the type of warehouse document from which the line originated.';
                    Visible = false;
                }
                field("Whse. Document No."; "Whse. Document No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the warehouse document that is the basis for the action on the line.';
                    Visible = false;
                }
                field("Whse. Document Line No."; "Whse. Document Line No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the line in the warehouse document that is the basis for the action on the line.';
                    Visible = false;
                }
                field("Special Equipment Code"; "Special Equipment Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the equipment required when you perform the action on the line.';
                    Visible = false;
                }
                field("Cross-Dock Information"; "Cross-Dock Information")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies an option for specific information regarding the cross-dock activity.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(SplitWhseActivityLine)
                {
                    ApplicationArea = Warehouse;
                    Caption = '&Split Line';
                    Image = Split;
                    ShortCutKey = 'Ctrl+F11';
                    ToolTip = 'Enable that the items can be taken or placed in more than one bin, for example, because the quantity in the suggested bin is insufficient to pick or move or there is not enough room to put away the required quantity.';

                    trigger OnAction()
                    var
                        WhseActivLine: Record "Warehouse Activity Line";
                    begin
                        WhseActivLine.Copy(Rec);
                        SplitLine(WhseActivLine);
                        Copy(WhseActivLine);
                        CurrPage.Update(false);
                    end;
                }
                action(ChangeUnitOfMeasure)
                {
                    ApplicationArea = Suite;
                    Caption = '&Change Unit Of Measure';
                    Ellipsis = true;
                    Image = UnitConversions;
                    ToolTip = 'Specify which unit of measure you want to change during the warehouse activity, for example, because you want to ship an item in boxes although you store it in pallets.';

                    trigger OnAction()
                    begin
                        ChangeUOM;
                    end;
                }
            }
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action("Source Document Line")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Source Document Line';
                    Image = SourceDocLine;
                    ToolTip = 'View the line on the source document that the put away is for.';

                    trigger OnAction()
                    begin
                        ShowSourceLine;
                    end;
                }
                action("Whse. Document Line")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Whse. Document Line';
                    Image = Line;
                    ToolTip = 'View the line on another warehouse document that the warehouse activity is for.';

                    trigger OnAction()
                    begin
                        ShowWhseLine;
                    end;
                }
                action("Bin Contents List")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Bin Contents List';
                    Image = BinContent;
                    ToolTip = 'View the contents of the selected bin and the parameters that define how items are routed through the bin.';

                    trigger OnAction()
                    begin
                        ShowBinContents;
                    end;
                }
                group("Item Availability by")
                {
                    Caption = 'Item Availability by';
                    Image = ItemAvailability;
                    action("Event")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Event';
                        Image = "Event";
                        ToolTip = 'View how the actual and the projected available balance of an item will develop over time according to supply and demand events.';

                        trigger OnAction()
                        begin
                            ItemAvailability(ItemAvailFormsMgt.ByEvent);
                        end;
                    }
                    action(Period)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Period';
                        Image = Period;
                        ToolTip = 'View the projected quantity of the item over time according to time periods, such as day, week, or month.';

                        trigger OnAction()
                        begin
                            ItemAvailability(ItemAvailFormsMgt.ByPeriod);
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
                            ItemAvailability(ItemAvailFormsMgt.ByVariant);
                        end;
                    }
                    action(Location)
                    {
                        AccessByPermission = TableData Location = R;
                        ApplicationArea = Warehouse;
                        Caption = 'Location';
                        Image = Warehouse;
                        ToolTip = 'View the actual and projected quantity of the item per location.';

                        trigger OnAction()
                        begin
                            ItemAvailability(ItemAvailFormsMgt.ByLocation);
                        end;
                    }
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        EnableZoneBin;
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        CurrPage.Update(false);
    end;

    trigger OnInit()
    begin
        QtyToHandleEditable := true;
        BinCodeEditable := true;
        ZoneCodeEditable := true;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        "Activity Type" := xRec."Activity Type";
    end;

    var
        ItemAvailFormsMgt: Codeunit "Item Availability Forms Mgt";
        WMSMgt: Codeunit "WMS Management";
        [InDataSet]
        ZoneCodeEditable: Boolean;
        [InDataSet]
        BinCodeEditable: Boolean;
        [InDataSet]
        QtyToHandleEditable: Boolean;

    local procedure ShowSourceLine()
    begin
        WMSMgt.ShowSourceDocLine(
          "Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.");
    end;

    local procedure ItemAvailability(AvailabilityType: Option Date,Variant,Location,Bin,"Event",BOM)
    begin
        ItemAvailFormsMgt.ShowItemAvailFromWhseActivLine(Rec, AvailabilityType);
    end;

    local procedure ChangeUOM()
    var
        WhseActLine: Record "Warehouse Activity Line";
        WhseChangeOUM: Report "Whse. Change Unit of Measure";
    begin
        TestField("Action Type");
        TestField("Breakbulk No.", 0);
        TestField("Action Type", 2);
        WhseChangeOUM.DefWhseActLine(Rec);
        WhseChangeOUM.RunModal;
        if WhseChangeOUM.ChangeUOMCode(WhseActLine) = true then
            ChangeUOMCode(Rec, WhseActLine);
        Clear(WhseChangeOUM);
        CurrPage.Update(false);
    end;

    procedure RegisterPutAwayYesNo()
    var
        WhseActivLine: Record "Warehouse Activity Line";
    begin
        WhseActivLine.Copy(Rec);
        WhseActivLine.FilterGroup(3);
        WhseActivLine.SetRange(Breakbulk);
        WhseActivLine.FilterGroup(0);
        CODEUNIT.Run(CODEUNIT::"Whse.-Act.-Register (Yes/No)", WhseActivLine);
        Reset;
        SetCurrentKey("Activity Type", "No.", "Sorting Sequence No.");
        FilterGroup(4);
        SetRange("Activity Type", "Activity Type");
        SetRange("No.", "No.");
        FilterGroup(3);
        SetRange(Breakbulk, false);
        FilterGroup(0);
        CurrPage.Update(false);
    end;

    procedure AutofillQtyToHandle()
    var
        WhseActivLine: Record "Warehouse Activity Line";
    begin
        WhseActivLine.Copy(Rec);
        WhseActivLine.SetRange("Activity Type", "Activity Type");
        WhseActivLine.SetRange("No.", "No.");
        AutofillQtyToHandle(WhseActivLine);
    end;

    procedure DeleteQtyToHandle()
    var
        WhseActivLine: Record "Warehouse Activity Line";
    begin
        WhseActivLine.Copy(Rec);
        WhseActivLine.SetRange("Activity Type", "Activity Type");
        WhseActivLine.SetRange("No.", "No.");
        DeleteQtyToHandle(WhseActivLine);
    end;

    local procedure ShowBinContents()
    var
        BinContent: Record "Bin Content";
    begin
        if "Action Type" = "Action Type"::Place then
            BinContent.ShowBinContents("Location Code", "Item No.", "Variant Code", '')
        else
            BinContent.ShowBinContents("Location Code", "Item No.", "Variant Code", "Bin Code");
    end;

    local procedure ShowWhseLine()
    begin
        WMSMgt.ShowWhseDocLine(
          "Whse. Document Type", "Whse. Document No.", "Whse. Document Line No.");
    end;

    local procedure EnableZoneBin()
    begin
        ZoneCodeEditable :=
          ("Action Type" = "Action Type"::Place) and ("Breakbulk No." = 0);
        BinCodeEditable :=
          ("Action Type" = "Action Type"::Place) and ("Breakbulk No." = 0);
        QtyToHandleEditable :=
          ("Action Type" = "Action Type"::Take) or ("Breakbulk No." = 0);
    end;

    local procedure SerialNoOnAfterValidate()
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        ExpDate: Date;
        EntriesExist: Boolean;
    begin
        if "Serial No." <> '' then
            ExpDate := ItemTrackingMgt.ExistingExpirationDate("Item No.", "Variant Code",
                "Lot No.", "Serial No.", false, EntriesExist);

        if ExpDate <> 0D then
            "Expiration Date" := ExpDate;
    end;

    local procedure LotNoOnAfterValidate()
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        ExpDate: Date;
        EntriesExist: Boolean;
    begin
        if "Lot No." <> '' then
            ExpDate := ItemTrackingMgt.ExistingExpirationDate("Item No.", "Variant Code",
                "Lot No.", "Serial No.", false, EntriesExist);

        if ExpDate <> 0D then
            "Expiration Date" := ExpDate;
    end;

    local procedure BinCodeOnAfterValidate()
    begin
        CurrPage.Update;
    end;

    local procedure QtytoHandleOnAfterValidate()
    begin
        CurrPage.Update(true);
    end;
}

