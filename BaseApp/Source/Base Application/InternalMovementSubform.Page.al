page 7398 "Internal Movement Subform"
{
    Caption = 'Lines';
    DelayedInsert = true;
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = ListPart;
    SourceTable = "Internal Movement Line";

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
                    ToolTip = 'Specifies the number of the item that is available to move from the bin.';

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
                    ToolTip = 'Specifies the same as the field with the same name in the Whse. Internal Put-away Line table.';
                }
                field("Description 2"; "Description 2")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the second description of the item.';
                    Visible = false;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code of the location where the internal movement is being performed.';
                }
                field("Shelf No."; "Shelf No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the shelf number that is recorded on the item card or on the stockkeeping unit card of the item that is being moved.';
                    Visible = false;
                }
                field("From Bin Code"; "From Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the bin that the items on the internal movement are picked from.';

                    trigger OnValidate()
                    begin
                        FromBinCodeOnAfterValidate;
                    end;
                }
                field("To Bin Code"; "To Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin where you want items on this internal movement to be placed when they are picked.';
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity of items to be moved. The quantity must be lower than or equal to the bin content.';
                }
                field("Qty. (Base)"; "Qty. (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity of units to be moved.';
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
                    ToolTip = 'Specifies the same as the field with the same name in the Whse. Internal Put-away Line table.';
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
                        ShowBinContent;
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
                        OpenItemTrackingLinesForm;
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

    local procedure GetActualSortMethod(): Integer
    var
        InternalMovementHeader: Record "Internal Movement Header";
    begin
        if InternalMovementHeader.Get("No.") then
            exit(InternalMovementHeader."Sorting Method");
    end;

    local procedure ShowBinContent()
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.ShowBinContents("Location Code", "Item No.", "Variant Code", "From Bin Code");
    end;

    local procedure OpenItemTrackingLinesForm()
    begin
        OpenItemTrackingLines;
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

