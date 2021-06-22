page 5769 "Whse. Receipt Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    InsertAllowed = false;
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = ListPart;
    SourceTable = "Warehouse Receipt Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Source Document"; "Source Document")
                {
                    ApplicationArea = Warehouse;
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
                    ToolTip = 'Specifies the number of the item that is expected to be received.';
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
                    ToolTip = 'Specifies the code of the location where the items should be received.';
                    Visible = false;
                }
                field("Zone Code"; "Zone Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the zone in which the items are being received.';
                    Visible = false;
                }
                field("Bin Code"; "Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin where the items are picked or put away.';
                    Visible = true;

                    trigger OnValidate()
                    begin
                        BinCodeOnAfterValidate;
                    end;
                }
                field("Cross-Dock Zone Code"; "Cross-Dock Zone Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the zone code that will be used for the quantity of items to be cross-docked.';
                    Visible = false;
                }
                field("Cross-Dock Bin Code"; "Cross-Dock Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin code that will be used for the quantity of items to be cross-docked.';
                    Visible = false;
                }
                field("Shelf No."; "Shelf No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the shelf number of the item for information use.';
                    Visible = false;
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity that should be received.';
                }
                field("Qty. (Base)"; "Qty. (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity to be received, in the base unit of measure.';
                    Visible = false;
                }
                field("Qty. to Receive"; "Qty. to Receive")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity of items that remains to be received.';

                    trigger OnValidate()
                    begin
                        QtytoReceiveOnAfterValidate;
                    end;
                }
                field("Qty. to Cross-Dock"; "Qty. to Cross-Dock")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the suggested quantity to put into the cross-dock bin on the put-away document when the receipt is posted.';
                    Visible = true;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        ShowCrossDockOpp(CrossDockOpp2);
                        CurrPage.Update;
                    end;
                }
                field("Qty. Received"; "Qty. Received")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity for this line that has been posted as received.';
                    Visible = true;
                }
                field("Qty. to Receive (Base)"; "Qty. to Receive (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the Qty. to Receive in the base unit of measure.';
                    Visible = false;
                }
                field("Qty. to Cross-Dock (Base)"; "Qty. to Cross-Dock (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the suggested base quantity to put into the cross-dock bin on the put-away document hen the receipt is posted.';
                    Visible = false;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        ShowCrossDockOpp(CrossDockOpp2);
                        CurrPage.Update;
                    end;
                }
                field("Qty. Received (Base)"; "Qty. Received (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity received, in the base unit of measure.';
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
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the date on which you expect to receive the items on the line.';
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Qty. per Unit of Measure"; "Qty. per Unit of Measure")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of base units of measure, that are in the unit of measure specified for the item on the line.';
                }
                field("Over-Receipt Quantity"; "Over-Receipt Quantity")
                {
                    ApplicationArea = Warehouse;
                    Visible = OverReceiptAllowed;
                    ToolTip = 'Specifies over-receipt quantity.';
                }
                field("Over-Receipt Code"; "Over-Receipt Code")
                {
                    ApplicationArea = Warehouse;
                    Visible = OverReceiptAllowed;
                    ToolTip = 'Specifies over-receip code.';
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
                action("Source &Document Line")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Source &Document Line';
                    Image = SourceDocLine;
                    ToolTip = 'View the line on a released source document that the warehouse activity is for. ';

                    trigger OnAction()
                    begin
                        ShowSourceLine;
                    end;
                }
                action("&Bin Contents List")
                {
                    AccessByPermission = TableData "Bin Content" = R;
                    ApplicationArea = Warehouse;
                    Caption = '&Bin Contents List';
                    Image = BinContent;
                    ToolTip = 'View the contents of each bin and the parameters that define how items are routed through the bin.';

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
                action(ItemTrackingLines)
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

    var
        CrossDockOpp2: Record "Whse. Cross-Dock Opportunity";
        ItemAvailFormsMgt: Codeunit "Item Availability Forms Mgt";
        Text001: Label 'Cross-docking has been disabled for item %1 or location %2.';
        OverReceiptAllowed: Boolean;

    trigger OnOpenPage()
    begin
        SetOverReceiptControlsVisibility();
    end;

    local procedure ShowSourceLine()
    var
        WMSMgt: Codeunit "WMS Management";
    begin
        WMSMgt.ShowSourceDocLine(
          "Source Type", "Source Subtype", "Source No.", "Source Line No.", 0);
    end;

    local procedure ShowBinContents()
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.ShowBinContents("Location Code", "Item No.", "Variant Code", "Bin Code");
    end;

    local procedure ItemAvailability(AvailabilityType: Option Date,Variant,Location,Bin,"Event",BOM)
    begin
        ItemAvailFormsMgt.ShowItemAvailFromWhseRcptLine(Rec, AvailabilityType);
    end;

    procedure WhsePostRcptYesNo()
    var
        WhseRcptLine: Record "Warehouse Receipt Line";
    begin
        WhseRcptLine.Copy(Rec);
        CODEUNIT.Run(CODEUNIT::"Whse.-Post Receipt (Yes/No)", WhseRcptLine);
        Reset;
        SetCurrentKey("No.", "Sorting Sequence No.");
        CurrPage.Update(false);
    end;

    procedure WhsePostRcptPrint()
    var
        WhseRcptLine: Record "Warehouse Receipt Line";
    begin
        WhseRcptLine.Copy(Rec);
        CODEUNIT.Run(CODEUNIT::"Whse.-Post Receipt + Print", WhseRcptLine);
        Reset;
        SetCurrentKey("No.", "Sorting Sequence No.");
        CurrPage.Update(false);
    end;

    procedure WhsePostRcptPrintPostedRcpt()
    var
        WhseRcptLine: Record "Warehouse Receipt Line";
    begin
        WhseRcptLine.Copy(Rec);
        CODEUNIT.Run(CODEUNIT::"Whse.-Post Receipt + Pr. Pos.", WhseRcptLine);
        Reset;
        CurrPage.Update(false);
    end;

    procedure AutofillQtyToReceive()
    var
        WhseRcptLine: Record "Warehouse Receipt Line";
    begin
        WhseRcptLine.Copy(Rec);
        WhseRcptLine.SetRange("No.", "No.");
        AutofillQtyToReceive(WhseRcptLine);
    end;

    procedure DeleteQtyToReceive()
    var
        WhseRcptLine: Record "Warehouse Receipt Line";
    begin
        WhseRcptLine.Copy(Rec);
        WhseRcptLine.SetRange("No.", "No.");
        DeleteQtyToReceive(WhseRcptLine);
    end;

    local procedure OpenItemTrackingLines()
    begin
        OpenItemTrackingLines;
    end;

    local procedure ShowCrossDockOpp(var CrossDockOpp: Record "Whse. Cross-Dock Opportunity" temporary)
    var
        CrossDockMgt: Codeunit "Whse. Cross-Dock Management";
        UseCrossDock: Boolean;
    begin
        CrossDockMgt.GetUseCrossDock(UseCrossDock, "Location Code", "Item No.");
        if not UseCrossDock then
            Error(Text001, "Item No.", "Location Code");
        CrossDockMgt.ShowCrossDock(CrossDockOpp, '', "No.", "Line No.", "Location Code", "Item No.", "Variant Code");
    end;

    local procedure BinCodeOnAfterValidate()
    begin
        CurrPage.Update;
    end;

    local procedure QtytoReceiveOnAfterValidate()
    begin
        CurrPage.SaveRecord;
    end;

    local procedure SetOverReceiptControlsVisibility()
    var
        OverReceiptMgt: Codeunit "Over-Receipt Mgt.";
    begin
        OverReceiptAllowed := OverReceiptMgt.IsOverReceiptAllowed();
    end;
}

