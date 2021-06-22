page 7355 "Internal Put-away Subform"
{
    Caption = 'Lines';
    DelayedInsert = true;
    InsertAllowed = true;
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = ListPart;
    SourceTable = "Whse. Internal Put-away Line";

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
                    ToolTip = 'Specifies the number of the item that you want to put away and have entered on the line.';

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
                    ToolTip = 'Specifies the description of the item on the line.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code for the location of the internal put-away line.';
                    Visible = false;
                }
                field("From Zone Code"; "From Zone Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the zone from which the items to be put away should be taken.';
                    Visible = false;
                }
                field("From Bin Code"; "From Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin from which the items to be put away should be taken.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        FromBinCodeOnAfterValidate;
                    end;
                }
                field("Shelf No."; "Shelf No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the shelf number that is recorded on the item card or the stockkeeping unit card of the item being moved.';
                    Visible = false;
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity that should be put away.';
                }
                field("Qty. (Base)"; "Qty. (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity that should be put away, in the base unit of measure.';
                    Visible = false;
                }
                field("Qty. Outstanding"; "Qty. Outstanding")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity that still needs to be handled.';
                    Visible = true;
                }
                field("Qty. Put Away"; "Qty. Put Away")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity of the line that is registered as put away.';
                }
                field("Qty. Put Away (Base)"; "Qty. Put Away (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity of the line that is registered as put away, in the base unit of measure.';
                    Visible = false;
                }
                field("Put-away Qty."; "Put-away Qty.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity in the put-away instructions that is assigned to be put away.';
                }
                field("Put-away Qty. (Base)"; "Put-away Qty. (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity in the put-away instructions assigned to be put away, in the base unit of measure.';
                    Visible = false;
                }
                field("Qty. Outstanding (Base)"; "Qty. Outstanding (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity that still needs to be handled, expressed in the base unit of measure.';
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
                    Visible = false;
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
        SortMethod: Option " ",Item,"Shelf/Bin No.","Due Date";

    local procedure ShowBinContents()
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.ShowBinContents("Location Code", "Item No.", "Variant Code", "From Bin Code");
    end;

    procedure PutAwayCreate()
    var
        WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header";
        WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line";
        ReleaseWhseInternalPutAway: Codeunit "Whse. Int. Put-away Release";
    begin
        WhseInternalPutAwayLine.Copy(Rec);
        WhseInternalPutAwayHeader.Get("No.");
        if WhseInternalPutAwayHeader.Status = WhseInternalPutAwayHeader.Status::Open then
            ReleaseWhseInternalPutAway.Release(WhseInternalPutAwayHeader);
        CreatePutAwayDoc(WhseInternalPutAwayLine);
    end;

    local procedure GetActualSortMethod(): Enum "Warehouse Internal Sorting Method"
    var
        WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header";
    begin
        if WhseInternalPutAwayHeader.Get("No.") then
            exit(WhseInternalPutAwayHeader."Sorting Method");

        exit(0);
    end;

    local procedure ItemNoOnAfterValidate()
    begin
        if GetActualSortMethod = SortMethod::Item then
            CurrPage.Update;
    end;

    local procedure FromBinCodeOnAfterValidate()
    begin
        if GetActualSortMethod = SortMethod::"Shelf/Bin No." then
            CurrPage.Update;
    end;

    local procedure DueDateOnAfterValidate()
    begin
        if GetActualSortMethod = SortMethod::"Due Date" then
            CurrPage.Update;
    end;
}

