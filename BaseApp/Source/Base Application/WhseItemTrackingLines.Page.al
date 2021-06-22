page 6550 "Whse. Item Tracking Lines"
{
    // Function button Line exist in two overlayed versions to make dynamic show/hide/enable of
    // individual menu items possible.

    Caption = 'Whse. Item Tracking Lines';
    DataCaptionFields = "Item No.", "Variant Code", Description;
    DelayedInsert = true;
    PageType = Worksheet;
    Permissions = TableData "Whse. Item Tracking Line" = rimd;
    PopulateAllFields = true;
    SourceTable = "Whse. Item Tracking Line";

    layout
    {
        area(content)
        {
            group(Control59)
            {
                ShowCaption = false;
                fixed(Control1903651101)
                {
                    ShowCaption = false;
                    group(Source)
                    {
                        Caption = 'Source';
                        field(TextCaption; GetTextCaption)
                        {
                            ApplicationArea = ItemTracking;
                            Editable = false;
                            ShowCaption = false;
                        }
                        field("SourceQuantityArray[1]"; SourceQuantityArray[1])
                        {
                            ApplicationArea = ItemTracking;
                            Caption = 'Quantity';
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ToolTip = 'Specifies the quantity of the item that corresponds to the warehouse tracking line.';
                        }
                        field(Handle1; SourceQuantityArray[2])
                        {
                            ApplicationArea = ItemTracking;
                            Caption = 'Qty. to Handle';
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ToolTip = 'Specifies the item-tracked quantity to be handled. The quantities must correspond to those of the document line.';
                            Visible = Handle1Visible;
                        }
                    }
                    group("Item Tracking")
                    {
                        Caption = 'Item Tracking';
                        field(Text003; Text003)
                        {
                            ApplicationArea = ItemTracking;
                            Visible = false;
                        }
                        field("TotalWhseItemTrackingLine.""Quantity (Base)"""; TotalWhseItemTrackingLine."Quantity (Base)")
                        {
                            ApplicationArea = ItemTracking;
                            Caption = 'Quantity';
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ToolTip = 'Specifies the quantity of the item that corresponds to the warehouse tracking line.';
                        }
                        field(Handle2; TotalWhseItemTrackingLine."Qty. to Handle (Base)")
                        {
                            ApplicationArea = ItemTracking;
                            Caption = 'Qty. to Ship/Receive';
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ToolTip = 'Specifies the quantities handled in warehouse activity lines.';
                            Visible = Handle2Visible;
                        }
                    }
                    group(Undefined)
                    {
                        Caption = 'Undefined';
                        field(Control52; Text003)
                        {
                            ApplicationArea = ItemTracking;
                            Visible = false;
                        }
                        field(Quantity3; UndefinedQtyArray[1])
                        {
                            ApplicationArea = ItemTracking;
                            BlankZero = true;
                            Editable = false;
                            ShowCaption = false;
                        }
                        field(Handle3; UndefinedQtyArray[2])
                        {
                            ApplicationArea = ItemTracking;
                            BlankZero = true;
                            Editable = false;
                            ShowCaption = false;
                            Visible = Handle3Visible;
                        }
                    }
                }
            }
            group(Control43)
            {
                ShowCaption = false;
                field("ItemTrackingCode.Code"; ItemTrackingCode.Code)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Item Tracking Code';
                    Editable = false;
                    Lookup = true;
                    ToolTip = 'Specifies the code for the warehouse item to be tracked.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        PAGE.RunModal(0, ItemTrackingCode);
                    end;
                }
                field("ItemTrackingCode.Description"; ItemTrackingCode.Description)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Description';
                    Editable = false;
                    ToolTip = 'Specifies the description of the warehouse item.';
                }
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Serial No."; "Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the same as the field in the Item Tracking Lines window.';

                    trigger OnAssistEdit()
                    var
                        MaxQuantity: Decimal;
                    begin
                        if ColorOfQuantityArray[1] = 0 then
                            MaxQuantity := UndefinedQtyArray[1] + ("Quantity (Base)" - "Quantity Handled (Base)");

                        LookUpTrackingSummary(Rec, 0, MaxQuantity, -1, true);
                        CurrPage.Update;
                        CalculateSums;
                    end;

                    trigger OnValidate()
                    begin
                        SerialNoOnAfterValidate;
                    end;
                }
                field("New Serial No."; "New Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    Editable = NewSerialNoEditable;
                    ToolTip = 'Specifies a new serial number that replaces the number in the Serial No. field, when you post the warehouse item reclassification journal.';
                    Visible = NewSerialNoVisible;
                }
                field("Lot No."; "Lot No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the same as the field in the Item Tracking Lines window.';

                    trigger OnAssistEdit()
                    var
                        MaxQuantity: Decimal;
                    begin
                        if ColorOfQuantityArray[1] = 0 then
                            MaxQuantity := UndefinedQtyArray[1] + ("Quantity (Base)" - "Quantity Handled (Base)");

                        LookUpTrackingSummary(Rec, 1, MaxQuantity, -1, true);
                        CurrPage.Update;
                        CalculateSums;
                    end;

                    trigger OnValidate()
                    begin
                        LotNoOnAfterValidate;
                    end;
                }
                field("New Lot No."; "New Lot No.")
                {
                    ApplicationArea = ItemTracking;
                    Editable = NewLotNoEditable;
                    ToolTip = 'Specifies a new lot number that replaces the number in the Lot No. field, when you post the warehouse item reclassification journal.';
                    Visible = NewLotNoVisible;
                }
                field("Expiration Date"; "Expiration Date")
                {
                    ApplicationArea = ItemTracking;
                    Editable = ExpirationDateEditable;
                    ToolTip = 'Specifies the same as the field in the Item Tracking Lines window.';
                    Visible = false;
                }
                field("New Expiration Date"; "New Expiration Date")
                {
                    ApplicationArea = ItemTracking;
                    Editable = NewExpirationDateEditable;
                    ToolTip = 'Specifies the same as the field in the Item Tracking Lines window.';
                    Visible = NewExpirationDateVisible;
                }
                field("Warranty Date"; "Warranty Date")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the same as the field in the Item Tracking Lines window.';
                    Visible = false;
                }
                field("Item No."; "Item No.")
                {
                    ApplicationArea = ItemTracking;
                    Editable = false;
                    ToolTip = 'Specifies the same as the field in the Item Tracking Lines window.';
                    Visible = false;
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    Editable = false;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = ItemTracking;
                    Editable = false;
                    ToolTip = 'Specifies the same as the field with the same name in the Item Tracking Lines window.';
                    Visible = false;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = ItemTracking;
                    Editable = false;
                    ToolTip = 'Specifies the same as the field in the Item Tracking Lines window.';
                    Visible = false;
                }
                field(Quantity; "Quantity (Base)")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the same as the field in the Item Tracking Lines window.';

                    trigger OnValidate()
                    begin
                        QuantityBaseOnAfterValidate;
                    end;
                }
                field("Qty. to Handle (Base)"; "Qty. to Handle (Base)")
                {
                    ApplicationArea = ItemTracking;
                    Editable = QtyToHandleBaseEditable;
                    ToolTip = 'Specifies the same as the field in the Item Tracking Lines window.';
                    Visible = QtyToHandleBaseVisible;

                    trigger OnValidate()
                    begin
                        QtytoHandleBaseOnAfterValidate;
                    end;
                }
                field("Quantity Handled (Base)"; "Quantity Handled (Base)")
                {
                    ApplicationArea = ItemTracking;
                    Editable = false;
                    ToolTip = 'Specifies the same as the field in the Item Tracking Lines window.';
                    Visible = false;
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
            group(ButtonLineReclass)
            {
                Caption = '&Line';
                Image = Line;
                Visible = ButtonLineReclassVisible;
                action(Reclass_SerialNoInfoCard)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Serial No. Information Card';
                    Image = SNInfo;
                    RunObject = Page "Serial No. Information List";
                    RunPageLink = "Item No." = FIELD("Item No."),
                                  "Variant Code" = FIELD("Variant Code"),
                                  "Serial No." = FIELD("Serial No.");
                    ToolTip = 'View or edit detailed information about the serial number.';

                    trigger OnAction()
                    begin
                        TestField("Serial No.");
                    end;
                }
                action(Reclass_LotNoInfoCard)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Lot No. Information Card';
                    Image = LotInfo;
                    RunObject = Page "Lot No. Information List";
                    RunPageLink = "Item No." = FIELD("Item No."),
                                  "Variant Code" = FIELD("Variant Code"),
                                  "Lot No." = FIELD("Lot No.");
                    ToolTip = 'View or edit detailed information about the lot number.';

                    trigger OnAction()
                    begin
                        TestField("Lot No.");
                    end;
                }
                separator(Action44)
                {
                }
                action("New S&erial No. Information")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'New S&erial No. Information';
                    Image = NewSerialNoProperties;
                    ToolTip = 'Create a record with detailed information about the serial number.';

                    trigger OnAction()
                    var
                        SerialNoInfoNew: Record "Serial No. Information";
                        SerialNoInfoForm: Page "Serial No. Information Card";
                    begin
                        TestField("New Serial No.");

                        Clear(SerialNoInfoForm);
                        SerialNoInfoForm.InitWhse(Rec);

                        SerialNoInfoNew.SetRange("Item No.", "Item No.");
                        SerialNoInfoNew.SetRange("Variant Code", "Variant Code");
                        SerialNoInfoNew.SetRange("Serial No.", "New Serial No.");

                        SerialNoInfoForm.SetTableView(SerialNoInfoNew);
                        SerialNoInfoForm.Run;
                    end;
                }
                action("New L&ot No. Information")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'New L&ot No. Information';
                    Image = NewLotProperties;
                    RunPageOnRec = false;
                    ToolTip = 'Create a record with detailed information about the lot number.';

                    trigger OnAction()
                    var
                        LotNoInfoNew: Record "Lot No. Information";
                        LotNoInfoForm: Page "Lot No. Information Card";
                    begin
                        TestField("New Lot No.");

                        Clear(LotNoInfoForm);
                        LotNoInfoForm.InitWhse(Rec);

                        LotNoInfoNew.SetRange("Item No.", "Item No.");
                        LotNoInfoNew.SetRange("Variant Code", "Variant Code");
                        LotNoInfoNew.SetRange("Lot No.", "New Lot No.");

                        LotNoInfoForm.SetTableView(LotNoInfoNew);
                        LotNoInfoForm.Run;
                    end;
                }
            }
            group(ButtonLine)
            {
                Caption = '&Line';
                Image = Line;
                Visible = ButtonLineVisible;
                action(Line_SerialNoInfoCard)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Serial No. Information Card';
                    Image = SNInfo;
                    RunObject = Page "Serial No. Information List";
                    RunPageLink = "Item No." = FIELD("Item No."),
                                  "Variant Code" = FIELD("Variant Code"),
                                  "Serial No." = FIELD("Serial No.");
                    ToolTip = 'View or edit detailed information about the serial number.';

                    trigger OnAction()
                    begin
                        TestField("Serial No.");
                    end;
                }
                action(Line_LotNoInforCard)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Lot No. Information Card';
                    Image = LotInfo;
                    RunObject = Page "Lot No. Information List";
                    RunPageLink = "Item No." = FIELD("Item No."),
                                  "Variant Code" = FIELD("Variant Code"),
                                  "Lot No." = FIELD("Lot No.");
                    ToolTip = 'View or edit detailed information about the lot number.';

                    trigger OnAction()
                    begin
                        TestField("Lot No.");
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateExpDateEditable;
        CalculateSums;
    end;

    trigger OnAfterGetRecord()
    begin
        ExpirationDateOnFormat;
    end;

    trigger OnClosePage()
    begin
        if FormUpdated then
            if not UpdateUndefinedQty then
                RestoreInitialTrkgLine
            else
                if not CopyToReservEntry then
                    RestoreInitialTrkgLine;
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        FormUpdated := true;
        Delete; // to ensure correct recalculation
        CalculateSums;
    end;

    trigger OnInit()
    begin
        ExpirationDateEditable := true;
        NewExpirationDateEditable := true;
        NewLotNoEditable := true;
        NewSerialNoEditable := true;
        QtyToHandleBaseEditable := true;
        ButtonLineVisible := true;
        QtyToHandleBaseVisible := true;
        Handle3Visible := true;
        Handle2Visible := true;
        Handle1Visible := true;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        WhseItemTrackingLine2: Record "Whse. Item Tracking Line";
    begin
        FormUpdated := true;
        if ("Serial No." = '') and ("Lot No." = '') then
            exit(false);
        if WhseItemTrackingLine2.FindLast then;
        "Entry No." := WhseItemTrackingLine2."Entry No." + 1;
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        FormUpdated := true;
    end;

    trigger OnOpenPage()
    begin
        UpdateUndefinedQty;
        SaveItemTrkgLine(TempInitialTrkgLine);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if FormUpdated then
            if not UpdateUndefinedQty then
                exit(Confirm(Text002));
    end;

    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        TotalWhseItemTrackingLine: Record "Whse. Item Tracking Line";
        TempInitialTrkgLine: Record "Whse. Item Tracking Line" temporary;
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        UndefinedQtyArray: array[2] of Decimal;
        SourceQuantityArray: array[2] of Decimal;
        ColorOfQuantityArray: array[2] of Integer;
        Text001: Label 'Line';
        Text002: Label 'The corrections cannot be saved as excess quantity has been defined.\Close the form anyway?';
        FormSourceType: Integer;
        FormUpdated: Boolean;
        Reclass: Boolean;
        Text003: Label 'Placeholder';
        [InDataSet]
        Handle1Visible: Boolean;
        [InDataSet]
        Handle2Visible: Boolean;
        [InDataSet]
        Handle3Visible: Boolean;
        [InDataSet]
        QtyToHandleBaseVisible: Boolean;
        [InDataSet]
        NewSerialNoVisible: Boolean;
        [InDataSet]
        NewLotNoVisible: Boolean;
        [InDataSet]
        NewExpirationDateVisible: Boolean;
        [InDataSet]
        ButtonLineReclassVisible: Boolean;
        [InDataSet]
        ButtonLineVisible: Boolean;
        [InDataSet]
        QtyToHandleBaseEditable: Boolean;
        [InDataSet]
        NewSerialNoEditable: Boolean;
        [InDataSet]
        NewLotNoEditable: Boolean;
        [InDataSet]
        NewExpirationDateEditable: Boolean;
        [InDataSet]
        ExpirationDateEditable: Boolean;

    local procedure GetTextCaption(): Text[30]
    var
        PostedWhseRcptLine: Record "Posted Whse. Receipt Line";
        WhseShipmentLine: Record "Warehouse Shipment Line";
    begin
        case "Source Type" of
            DATABASE::"Posted Whse. Receipt Line":
                exit(PostedWhseRcptLine.TableCaption);
            DATABASE::"Warehouse Shipment Line":
                exit(WhseShipmentLine.TableCaption);
            else
                exit(Text001);
        end;
    end;

    procedure SetSource(WhseWrkshLine: Record "Whse. Worksheet Line"; SourceType: Integer)
    begin
        FormUpdated := false;
        FormSourceType := SourceType;
        WhseWorksheetLine := WhseWrkshLine;
        GetItem(WhseWorksheetLine."Item No.");
        ItemTrackingMgt.CheckWhseItemTrkgSetup(WhseWorksheetLine."Item No.");

        SetControlsAsHandle;
        Reclass := IsReclass(FormSourceType, WhseWorksheetLine."Worksheet Template Name");
        SetControlsAsReclass;

        SetFilters(Rec, FormSourceType);
        ItemTrackingMgt.UpdateQuantities(
          WhseWorksheetLine, TotalWhseItemTrackingLine, SourceQuantityArray, UndefinedQtyArray, FormSourceType);
        OnAfterSetSource(WhseWorksheetLine, WhseWrkshLine, SourceType);
        UpdateColorOfQty;
    end;

    local procedure SetControlsAsHandle()
    var
        SetAccess: Boolean;
    begin
        SetAccess := FormSourceType <> DATABASE::"Warehouse Journal Line";
        Handle1Visible := SetAccess;
        Handle2Visible := SetAccess;
        Handle3Visible := SetAccess;
        QtyToHandleBaseVisible := SetAccess;
        QtyToHandleBaseEditable := SetAccess;
    end;

    local procedure SetControlsAsReclass()
    begin
        NewSerialNoVisible := Reclass;
        NewSerialNoEditable := Reclass;
        NewLotNoVisible := Reclass;
        NewLotNoEditable := Reclass;
        NewExpirationDateVisible := Reclass;
        NewExpirationDateEditable := Reclass;
        ButtonLineReclassVisible := Reclass;
        ButtonLineVisible := not Reclass;
    end;

    procedure SetFilters(var WhseItemTrkgLine2: Record "Whse. Item Tracking Line"; SourceType: Integer)
    begin
        with WhseItemTrkgLine2 do begin
            FilterGroup := 2;
            SetRange("Source Type", SourceType);
            SetRange("Location Code", WhseWorksheetLine."Location Code");
            SetRange("Item No.", WhseWorksheetLine."Item No.");
            SetRange("Variant Code", WhseWorksheetLine."Variant Code");
            SetRange("Qty. per Unit of Measure", WhseWorksheetLine."Qty. per Unit of Measure");

            case SourceType of
                DATABASE::"Posted Whse. Receipt Line",
                DATABASE::"Warehouse Shipment Line",
                DATABASE::"Whse. Internal Put-away Line",
                DATABASE::"Whse. Internal Pick Line",
                DATABASE::"Assembly Line",
                DATABASE::"Internal Movement Line":
                    begin
                        SetRange("Source ID", WhseWorksheetLine."Whse. Document No.");
                        SetRange("Source Ref. No.", WhseWorksheetLine."Whse. Document Line No.");
                    end;
                DATABASE::"Prod. Order Component":
                    begin
                        SetRange("Source Subtype", WhseWorksheetLine."Source Subtype");
                        SetRange("Source ID", WhseWorksheetLine."Source No.");
                        SetRange("Source Prod. Order Line", WhseWorksheetLine."Source Line No.");
                        SetRange("Source Ref. No.", WhseWorksheetLine."Source Subline No.");
                    end;
                DATABASE::"Whse. Worksheet Line",
                DATABASE::"Warehouse Journal Line":
                    begin
                        SetRange("Source Batch Name", WhseWorksheetLine."Worksheet Template Name");
                        SetRange("Source ID", WhseWorksheetLine.Name);
                        SetRange("Source Ref. No.", WhseWorksheetLine."Line No.");
                    end;
            end;
            FilterGroup := 0;
        end;
    end;

    local procedure UpdateExpDateColor()
    begin
        if BlockExpDate then;
    end;

    local procedure UpdateExpDateEditable()
    begin
        ExpirationDateEditable := not BlockExpDate;
    end;

    local procedure BlockExpDate(): Boolean
    begin
        exit(
          ("Buffer Status2" = "Buffer Status2"::"ExpDate blocked") or
          (WhseWorksheetLine."Qty. (Base)" < 0) or
          Reclass or
          (FormSourceType in
           [DATABASE::"Whse. Worksheet Line",
            DATABASE::"Posted Whse. Receipt Line",
            DATABASE::"Whse. Internal Put-away Line"]));
    end;

    procedure CalculateSums()
    begin
        ItemTrackingMgt.CalculateSums(
          WhseWorksheetLine, TotalWhseItemTrackingLine,
          SourceQuantityArray, UndefinedQtyArray, FormSourceType);
        UpdateColorOfQty;
    end;

    local procedure UpdateUndefinedQty() QtyIsValid: Boolean
    begin
        QtyIsValid := ItemTrackingMgt.UpdateUndefinedQty(TotalWhseItemTrackingLine, SourceQuantityArray, UndefinedQtyArray);
        UpdateColorOfQty;
    end;

    local procedure UpdateColorOfQty()
    begin
        ColorOfQuantityArray[1] := GetQtyColor(SourceQuantityArray[1], TotalWhseItemTrackingLine."Quantity (Base)");
        ColorOfQuantityArray[2] := GetQtyColor(SourceQuantityArray[2], TotalWhseItemTrackingLine."Qty. to Handle (Base)");
    end;

    local procedure GetQtyColor(SourceQty: Decimal; TrackingQty: Decimal): Integer
    begin
        if Abs(SourceQty) < Abs(TrackingQty) then
            exit(255);
        exit(0);
    end;

    local procedure GetItem(ItemNo: Code[20])
    begin
        if Item."No." <> ItemNo then begin
            Item.Get(ItemNo);
            Item.TestField("Item Tracking Code");
            if ItemTrackingCode.Code <> Item."Item Tracking Code" then
                ItemTrackingCode.Get(Item."Item Tracking Code");
        end;
    end;

    local procedure SaveItemTrkgLine(var TempWhseItemTrkgLine: Record "Whse. Item Tracking Line" temporary)
    var
        WhseItemTrkgLine2: Record "Whse. Item Tracking Line";
    begin
        SetFilters(WhseItemTrkgLine2, FormSourceType);
        TempWhseItemTrkgLine.Reset();
        TempWhseItemTrkgLine.DeleteAll();
        if WhseItemTrkgLine2.Find('-') then
            repeat
                TempWhseItemTrkgLine := WhseItemTrkgLine2;
                TempWhseItemTrkgLine.Insert();
            until WhseItemTrkgLine2.Next = 0;
    end;

    local procedure RestoreInitialTrkgLine()
    var
        WhseItemTrkgLine2: Record "Whse. Item Tracking Line";
    begin
        SetFilters(WhseItemTrkgLine2, FormSourceType);
        WhseItemTrkgLine2.DeleteAll();
        if TempInitialTrkgLine.Find('-') then
            repeat
                WhseItemTrkgLine2 := TempInitialTrkgLine;
                WhseItemTrkgLine2.Insert();
            until TempInitialTrkgLine.Next = 0;
    end;

    local procedure CopyToReservEntry(): Boolean
    var
        WhseItemTrkgLine2: Record "Whse. Item Tracking Line";
        SourceWhseItemTrkgLine: Record "Whse. Item Tracking Line" temporary;
        WhseShptLine: Record "Warehouse Shipment Line";
        ProdOrderComp: Record "Prod. Order Component";
        QuantityBase: Decimal;
        DueDate: Date;
        Updated: Boolean;
    begin
        SetFilters(WhseItemTrkgLine2, FormSourceType);

        if WhseItemTrkgLine2.Find('-') then
            SourceWhseItemTrkgLine := WhseItemTrkgLine2
        else
            if TempInitialTrkgLine.Find('-') then
                SourceWhseItemTrkgLine := TempInitialTrkgLine
            else
                exit(true);

        case FormSourceType of
            DATABASE::"Prod. Order Component":
                begin
                    ProdOrderComp.Get(SourceWhseItemTrkgLine."Source Subtype", SourceWhseItemTrkgLine."Source ID",
                      SourceWhseItemTrkgLine."Source Prod. Order Line", SourceWhseItemTrkgLine."Source Ref. No.");
                    QuantityBase := ProdOrderComp."Expected Qty. (Base)";
                    DueDate := ProdOrderComp."Due Date";
                    Updated := UpdateReservEntry(
                        SourceWhseItemTrkgLine."Source Type",
                        SourceWhseItemTrkgLine."Source Subtype",
                        SourceWhseItemTrkgLine."Source ID",
                        SourceWhseItemTrkgLine."Source Prod. Order Line",
                        SourceWhseItemTrkgLine."Source Ref. No.",
                        SourceWhseItemTrkgLine, QuantityBase, DueDate);
                end;
            DATABASE::"Warehouse Shipment Line":
                begin
                    WhseShptLine.Get(SourceWhseItemTrkgLine."Source ID", SourceWhseItemTrkgLine."Source Ref. No.");
                    QuantityBase := WhseShptLine."Qty. (Base)";
                    DueDate := WhseShptLine."Due Date";
                    Updated := UpdateReservEntry(
                        WhseShptLine."Source Type",
                        WhseShptLine."Source Subtype",
                        WhseShptLine."Source No.",
                        0,
                        WhseShptLine."Source Line No.",
                        SourceWhseItemTrkgLine, QuantityBase, DueDate);
                end;
            else
                exit(true);
        end;
        exit(Updated)
    end;

    local procedure UpdateReservEntry(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceProdOrderLine: Integer; SourceRefNo: Integer; SourceWhseItemTrkgLine: Record "Whse. Item Tracking Line" temporary; QuantityBase: Decimal; DueDate: Date): Boolean
    var
        TempTrkgSpec: Record "Tracking Specification" temporary;
        SourceSpecification: Record "Tracking Specification";
        WhseItemTrkgLine2: Record "Whse. Item Tracking Line";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        LastEntryNo: Integer;
    begin
        if TempInitialTrkgLine.Find('-') then
            repeat
                TempTrkgSpec.TransferFields(TempInitialTrkgLine);
                TempTrkgSpec."Quantity (Base)" *= -1;
                TempTrkgSpec."Entry No." := LastEntryNo + 1;
                TempTrkgSpec.Insert();
                LastEntryNo := TempTrkgSpec."Entry No.";
            until TempInitialTrkgLine.Next = 0;

        SetFilters(WhseItemTrkgLine2, FormSourceType);
        if WhseItemTrkgLine2.Find('-') then
            repeat
                TempTrkgSpec.TransferFields(WhseItemTrkgLine2);
                TempTrkgSpec."Entry No." := LastEntryNo + 1;
                TempTrkgSpec.Insert();
                LastEntryNo := TempTrkgSpec."Entry No.";
            until WhseItemTrkgLine2.Next = 0;

        SourceSpecification."Source Type" := SourceType;
        SourceSpecification."Source Subtype" := SourceSubtype;
        SourceSpecification."Source ID" := SourceID;
        SourceSpecification."Source Batch Name" := '';
        SourceSpecification."Source Prod. Order Line" := SourceProdOrderLine;
        SourceSpecification."Source Ref. No." := SourceRefNo;
        SourceSpecification."Quantity (Base)" := QuantityBase;
        SourceSpecification."Item No." := SourceWhseItemTrkgLine."Item No.";
        SourceSpecification."Variant Code" := SourceWhseItemTrkgLine."Variant Code";
        SourceSpecification."Location Code" := SourceWhseItemTrkgLine."Location Code";
        SourceSpecification.Description := SourceWhseItemTrkgLine.Description;
        SourceSpecification."Qty. per Unit of Measure" := SourceWhseItemTrkgLine."Qty. per Unit of Measure";
        ItemTrackingMgt.SetGlobalParameters(SourceSpecification, TempTrkgSpec, DueDate);
        exit(ItemTrackingMgt.Run);
    end;

    procedure InsertItemTrackingLine(WhseWrkshLine: Record "Whse. Worksheet Line"; WhseEntry: Record 7312; QtyToEmpty: Decimal)
    var
        WhseItemTrackingLine2: Record "Whse. Item Tracking Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertItemTrackingLine(Rec, WhseWrkshLine, WhseEntry, QtyToEmpty, IsHandled);
        if IsHandled then
            exit;

        UpdateUndefinedQty();
        SaveItemTrkgLine(TempInitialTrkgLine);
        "Lot No." := WhseEntry."Lot No.";
        "Serial No." := WhseEntry."Serial No.";
        "Expiration Date" := WhseEntry."Expiration Date";
        "Qty. per Unit of Measure" := WhseWrkshLine."Qty. per Unit of Measure";
        Validate("Quantity (Base)", QtyToEmpty);
        "Source Type" := FormSourceType;
        "Source ID" := WhseWorksheetLine."Whse. Document No.";
        "Source Ref. No." := WhseWorksheetLine."Whse. Document Line No.";
        "Source Batch Name" := WhseWrkshLine."Worksheet Template Name";
        "Location Code" := WhseWorksheetLine."Location Code";
        "Item No." := WhseWorksheetLine."Item No.";
        "Variant Code" := WhseWrkshLine."Variant Code";
        if ("Expiration Date" <> 0D) and (FormSourceType = DATABASE::"Internal Movement Line") then
            InitExpirationDate();
        if WhseItemTrackingLine2.FindLast then;
        "Entry No." := WhseItemTrackingLine2."Entry No." + 1;
        OnBeforeItemTrackingLineInsert(Rec, WhseWrkshLine);
        Insert();
    end;

    local procedure SerialNoOnAfterValidate()
    begin
        UpdateExpDateEditable();
        CurrPage.Update();
    end;

    local procedure LotNoOnAfterValidate()
    begin
        UpdateExpDateEditable();
        CurrPage.Update();
    end;

    local procedure QuantityBaseOnAfterValidate()
    begin
        CurrPage.Update();
        CalculateSums();
    end;

    local procedure QtytoHandleBaseOnAfterValidate()
    begin
        CurrPage.Update();
        CalculateSums();
    end;

    local procedure ExpirationDateOnFormat()
    begin
        UpdateExpDateColor();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSource(var GlobalWhseWorksheetLine: Record "Whse. Worksheet Line"; SourceWhseWorksheetLine: Record "Whse. Worksheet Line"; SourceType: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeItemTrackingLineInsert(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; WhseWorksheetLine: Record "Whse. Worksheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertItemTrackingLine(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; WhseWorksheetLine: Record "Whse. Worksheet Line"; WarehouseEntry: Record "Warehouse Entry"; QtyToEmpty: Decimal; var IsHandled: Boolean)
    begin
    end;
}

