page 7358 "Whse. Internal Pick Line"
{
    Caption = 'Lines';
    DelayedInsert = true;
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = ListPart;
    SourceTable = "Whse. Internal Pick Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the item that should be picked.';

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
                field(Description; Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the description of the item in the line.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies the code of the location of the internal pick line.';
                    Visible = false;
                }
                field("To Zone Code"; "To Zone Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the To Zone Code of the zone where items should be placed once they are picked.';
                    Visible = false;
                }
                field("To Bin Code"; "To Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the bin into which the items should be placed when they are picked.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ToBinCodeOnAfterValidate;
                    end;
                }
                field("Shelf No."; "Shelf No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the shelf number of the item for informational use.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ShelfNoOnAfterValidate;
                    end;
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity that should be picked.';
                }
                field("Qty. (Base)"; "Qty. (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity that should be picked, in the base unit of measure.';
                    Visible = false;
                }
                field("Qty. Outstanding"; "Qty. Outstanding")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity that still needs to be handled.';
                    Visible = true;
                }
                field("Qty. Outstanding (Base)"; "Qty. Outstanding (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity that still needs to be handled, in the base unit of measure.';
                    Visible = false;
                }
                field("Pick Qty."; "Pick Qty.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity of the item in pick instructions that are assigned to be picked for the line.';
                    Visible = false;
                }
                field("Pick Qty. (Base)"; "Pick Qty. (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity of the item in pick instructions assigned to be picked for the line, in the base unit of measure.';
                    Visible = false;
                }
                field("Qty. Picked"; "Qty. Picked")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity of the line that is registered as picked.';
                    Visible = false;
                }
                field("Qty. Picked (Base)"; "Qty. Picked (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity of the line that is registered as picked, in the base unit of measure.';
                    Visible = false;
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the date when the warehouse activity must be completed.';

                    trigger OnValidate()
                    begin
                        DueDateOnAfterValidate;
                    end;
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Qty. per Unit of Measure"; "Qty. per Unit of Measure")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of base units of measure, that are in the unit of measure, specified for the item on the line.';
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
                action("Item &Tracking Lines")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Item &Tracking Lines';
                    Image = ItemTrackingLines;
                    ShortCutKey = 'Shift+Ctrl+I';
                    ToolTip = 'View or edit serial numbers and lot numbers that are assigned to the item on the document or journal line.';

                    trigger OnAction()
                    begin
                        OpenItemTrackingLines;
                    end;
                }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        SetUpNewLine(xRec);
    end;

    var
        SortMethod: Option " ",Item,"Bin Code","Due Date";

    local procedure ShowBinContents()
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.ShowBinContents("Location Code", "Item No.", "Variant Code", '');
    end;

    procedure PickCreate()
    var
        WhseInternalPickHeader: Record "Whse. Internal Pick Header";
        WhseInternalPickLine: Record "Whse. Internal Pick Line";
        ReleaseWhseInternalPick: Codeunit "Whse. Internal Pick Release";
    begin
        WhseInternalPickLine.Copy(Rec);
        WhseInternalPickHeader.Get(WhseInternalPickLine."No.");
        if WhseInternalPickHeader.Status = WhseInternalPickHeader.Status::Open then
            ReleaseWhseInternalPick.Release(WhseInternalPickHeader);
        CreatePickDoc(WhseInternalPickLine, WhseInternalPickHeader);
    end;

    local procedure OpenItemTrackingLines()
    begin
        OpenItemTrackingLines;
    end;

    local procedure GetActualSortMethod(): Enum "Warehouse Internal Sorting Method"
    var
        WhseInternalPickHeader: Record "Whse. Internal Pick Header";
    begin
        if WhseInternalPickHeader.Get("No.") then
            exit(WhseInternalPickHeader."Sorting Method");

        exit(WhseInternalPickHeader."Sorting Method"::None);
    end;

    local procedure ItemNoOnAfterValidate()
    begin
        if GetActualSortMethod = SortMethod::Item then
            CurrPage.Update;
    end;

    local procedure ToBinCodeOnAfterValidate()
    begin
        if GetActualSortMethod = SortMethod::"Bin Code" then
            CurrPage.Update;
    end;

    local procedure ShelfNoOnAfterValidate()
    begin
        if GetActualSortMethod = SortMethod::"Bin Code" then
            CurrPage.Update;
    end;

    local procedure DueDateOnAfterValidate()
    begin
        if GetActualSortMethod = SortMethod::"Due Date" then
            CurrPage.Update;
    end;
}

