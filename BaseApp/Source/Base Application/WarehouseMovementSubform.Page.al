page 7316 "Warehouse Movement Subform"
{
    Caption = 'Lines';
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Warehouse Activity Line";
    SourceTableView = SORTING("Activity Type", "No.", "Sorting Sequence No.")
                      WHERE("Activity Type" = CONST(Movement));

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
                field("Zone Code"; "Zone Code")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Zone Code';
                    ToolTip = 'Specifies the zone code where the bin on this line is located.';
                }
                field("Bin Code"; "Bin Code")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Bin Code';
                    ToolTip = 'Specifies the bin where items on the line are handled.';

                    trigger OnValidate()
                    begin
                        BinCodeOnAfterValidate;
                    end;
                }
                field("Special Equipment Code"; "Special Equipment Code")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Special Equipment Code';
                    ToolTip = 'Specifies the code of the equipment required when you perform the action on the line.';
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
                    ToolTip = 'Specifies how many units to handle in this warehouse activity.';

                    trigger OnValidate()
                    begin
                        QtytoHandleOnAfterValidate;
                    end;
                }
                field("Qty. to Handle (Base)"; "Qty. to Handle (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity of items to be handled in this warehouse activity.';
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
                field(Weight; Weight)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the weight of one item unit when measured in the specified unit of measure.';
                    Visible = false;
                }
                field(Cubage; Cubage)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the total cubage of items on the line, calculated based on the Quantity field.';
                    Visible = false;
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
                    begin
                        CallSplitLine;
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
            }
        }
    }

    trigger OnDeleteRecord(): Boolean
    begin
        CurrPage.Update(false);
    end;

    procedure AutofillQtyToHandle()
    var
        WhseActivLine: Record "Warehouse Activity Line";
    begin
        WhseActivLine.Copy(Rec);
        AutofillQtyToHandle(WhseActivLine);
    end;

    procedure DeleteQtyToHandle()
    var
        WhseActivLine: Record "Warehouse Activity Line";
    begin
        WhseActivLine.Copy(Rec);
        DeleteQtyToHandle(WhseActivLine);
    end;

    local procedure CallSplitLine()
    var
        WhseActivLine: Record "Warehouse Activity Line";
    begin
        WhseActivLine.Copy(Rec);
        SplitLine(WhseActivLine);
        Copy(WhseActivLine);
        CurrPage.Update(false);
    end;

    local procedure ChangeUOM()
    var
        WhseActLine: Record "Warehouse Activity Line";
        WhseChangeOUM: Report "Whse. Change Unit of Measure";
    begin
        TestField("Action Type");
        TestField("Breakbulk No.", 0);
        TestField("Qty. to Handle");
        WhseChangeOUM.DefWhseActLine(Rec);
        WhseChangeOUM.RunModal;
        if WhseChangeOUM.ChangeUOMCode(WhseActLine) = true then
            ChangeUOMCode(Rec, WhseActLine);
        Clear(WhseChangeOUM);
        CurrPage.Update(false);
    end;

    procedure RegisterActivityYesNo()
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

    local procedure ShowBinContents()
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.ShowBinContents("Location Code", "Item No.", "Variant Code", '');
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
        CurrPage.SaveRecord;
    end;
}

