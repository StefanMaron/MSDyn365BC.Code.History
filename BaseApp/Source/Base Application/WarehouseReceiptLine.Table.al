table 7317 "Warehouse Receipt Line"
{
    Caption = 'Warehouse Receipt Line';
    DrillDownPageID = "Whse. Receipt Lines";
    LookupPageID = "Whse. Receipt Lines";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            Editable = false;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
        }
        field(3; "Source Type"; Integer)
        {
            Caption = 'Source Type';
            Editable = false;
        }
        field(4; "Source Subtype"; Option)
        {
            Caption = 'Source Subtype';
            Editable = false;
            OptionCaption = '0,1,2,3,4,5,6,7,8,9,10';
            OptionMembers = "0","1","2","3","4","5","6","7","8","9","10";
        }
        field(6; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            Editable = false;
        }
        field(7; "Source Line No."; Integer)
        {
            Caption = 'Source Line No.';
            Editable = false;
        }
        field(9; "Source Document"; Option)
        {
            Caption = 'Source Document';
            Editable = false;
            OptionCaption = ',Sales Order,,,Sales Return Order,Purchase Order,,,Purchase Return Order,Inbound Transfer';
            OptionMembers = ,"Sales Order",,,"Sales Return Order","Purchase Order",,,"Purchase Return Order","Inbound Transfer";
        }
        field(10; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            Editable = false;
            TableRelation = Location;
        }
        field(11; "Shelf No."; Code[10])
        {
            Caption = 'Shelf No.';
        }
        field(12; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = IF ("Zone Code" = FILTER('')) Bin.Code WHERE("Location Code" = FIELD("Location Code"))
            ELSE
            IF ("Zone Code" = FILTER(<> '')) Bin.Code WHERE("Location Code" = FIELD("Location Code"),
                                                                               "Zone Code" = FIELD("Zone Code"));

            trigger OnValidate()
            var
                Bin: Record Bin;
                WhseIntegrationMgt: Codeunit "Whse. Integration Management";
            begin
                if xRec."Bin Code" <> "Bin Code" then
                    if "Bin Code" <> '' then begin
                        GetLocation("Location Code");
                        WhseIntegrationMgt.CheckBinTypeCode(DATABASE::"Warehouse Receipt Line",
                          FieldCaption("Bin Code"),
                          "Location Code",
                          "Bin Code", 0);
                        if Location."Directed Put-away and Pick" then begin
                            Bin.Get("Location Code", "Bin Code");
                            "Zone Code" := Bin."Zone Code";
                            CheckBin(false);
                        end;
                    end;
            end;
        }
        field(13; "Zone Code"; Code[10])
        {
            Caption = 'Zone Code';
            TableRelation = Zone.Code WHERE("Location Code" = FIELD("Location Code"));

            trigger OnValidate()
            begin
                if xRec."Zone Code" <> "Zone Code" then begin
                    if "Zone Code" <> '' then begin
                        GetLocation("Location Code");
                        Location.TestField("Directed Put-away and Pick");
                    end;
                    "Bin Code" := '';
                end;
            end;
        }
        field(14; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            Editable = false;
            TableRelation = Item;
        }
        field(15; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            begin
                "Qty. (Base)" :=
                    UOMMgt.CalcBaseQty("Item No.", "Variant Code", "Unit of Measure Code", Quantity, "Qty. per Unit of Measure");
                InitOutstandingQtys;
            end;
        }
        field(16; "Qty. (Base)"; Decimal)
        {
            Caption = 'Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(19; "Qty. Outstanding"; Decimal)
        {
            Caption = 'Qty. Outstanding';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            begin
                "Qty. Outstanding (Base)" :=
                    UOMMgt.CalcBaseQty("Item No.", "Variant Code", "Unit of Measure Code", "Qty. Outstanding", "Qty. per Unit of Measure");
                Validate("Qty. to Receive", "Qty. Outstanding");
            end;
        }
        field(20; "Qty. Outstanding (Base)"; Decimal)
        {
            Caption = 'Qty. Outstanding (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(21; "Qty. to Receive"; Decimal)
        {
            Caption = 'Qty. to Receive';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            var
                WMSMgt: Codeunit "WMS Management";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateQtyToReceive(Rec, IsHandled);
                if not IsHandled then
                    if "Qty. to Receive" > "Qty. Outstanding" then
                        Error(Text002, "Qty. Outstanding");

                GetLocation("Location Code");
                if Location."Directed Put-away and Pick" then begin
                    WMSMgt.CalcCubageAndWeight(
                      "Item No.", "Unit of Measure Code", "Qty. to Receive", Cubage, Weight);

                    if (CurrFieldNo <> 0) and ("Qty. to Receive" > 0) then
                        CheckBin(true);
                end;

                "Qty. to Cross-Dock" := 0;
                "Qty. to Cross-Dock (Base)" := 0;
                "Qty. to Receive (Base)" :=
                    UOMMgt.CalcBaseQty("Item No.", "Variant Code", "Unit of Measure Code", "Qty. to Receive", "Qty. per Unit of Measure");

                Item.CheckSerialNoQty("Item No.", FieldCaption("Qty. to Receive (Base)"), "Qty. to Receive (Base)");
            end;
        }
        field(22; "Qty. to Receive (Base)"; Decimal)
        {
            Caption = 'Qty. to Receive (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                TestField("Qty. per Unit of Measure", 1);
                Validate("Qty. to Receive", "Qty. to Receive (Base)");
            end;
        }
        field(23; "Qty. Received"; Decimal)
        {
            Caption = 'Qty. Received';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            begin
                "Qty. Received (Base)" :=
                    UOMMgt.CalcBaseQty("Item No.", "Variant Code", "Unit of Measure Code", "Qty. Received", "Qty. per Unit of Measure");
            end;
        }
        field(24; "Qty. Received (Base)"; Decimal)
        {
            Caption = 'Qty. Received (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(29; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            Editable = false;
            TableRelation = "Item Unit of Measure".Code WHERE("Item No." = FIELD("Item No."));
        }
        field(30; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
        }
        field(31; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            Editable = false;
            TableRelation = "Item Variant".Code WHERE("Item No." = FIELD("Item No."));
        }
        field(32; Description; Text[100])
        {
            Caption = 'Description';
            Editable = false;
        }
        field(33; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
            Editable = false;
        }
        field(34; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = ' ,Partially Received,Completely Received';
            OptionMembers = " ","Partially Received","Completely Received";
        }
        field(35; "Sorting Sequence No."; Integer)
        {
            Caption = 'Sorting Sequence No.';
            Editable = false;
        }
        field(36; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(37; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
        }
        field(38; Cubage; Decimal)
        {
            Caption = 'Cubage';
            DecimalPlaces = 0 : 5;
        }
        field(39; Weight; Decimal)
        {
            Caption = 'Weight';
            DecimalPlaces = 0 : 5;
        }
        field(48; "Not upd. by Src. Doc. Post."; Boolean)
        {
            Caption = 'Not upd. by Src. Doc. Post.';
            Editable = false;
        }
        field(49; "Posting from Whse. Ref."; Integer)
        {
            Caption = 'Posting from Whse. Ref.';
            Editable = false;
        }
        field(50; "Qty. to Cross-Dock"; Decimal)
        {
            Caption = 'Qty. to Cross-Dock';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                CrossDockMgt.GetUseCrossDock(UseCrossDock, "Location Code", "Item No.");
                if not UseCrossDock then
                    Error(Text006, Item.TableCaption, Location.TableCaption);
                if "Qty. to Cross-Dock" > "Qty. to Receive" then
                    Error(
                      Text005,
                      "Qty. to Receive");

                "Qty. to Cross-Dock (Base)" :=
                    UOMMgt.CalcBaseQty("Item No.", "Variant Code", "Unit of Measure Code", "Qty. to Cross-Dock", "Qty. per Unit of Measure");
            end;
        }
        field(51; "Qty. to Cross-Dock (Base)"; Decimal)
        {
            Caption = 'Qty. to Cross-Dock (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                TestField("Qty. per Unit of Measure", 1);
                Validate("Qty. to Cross-Dock", "Qty. to Cross-Dock (Base)");
            end;
        }
        field(52; "Cross-Dock Zone Code"; Code[10])
        {
            Caption = 'Cross-Dock Zone Code';
            TableRelation = Zone.Code WHERE("Location Code" = FIELD("Location Code"),
                                             "Cross-Dock Bin Zone" = CONST(true));
        }
        field(53; "Cross-Dock Bin Code"; Code[20])
        {
            Caption = 'Cross-Dock Bin Code';
            TableRelation = IF ("Cross-Dock Zone Code" = FILTER('')) Bin.Code WHERE("Location Code" = FIELD("Location Code"),
                                                                                   "Cross-Dock Bin" = CONST(true))
            ELSE
            IF ("Cross-Dock Zone Code" = FILTER(<> '')) Bin.Code WHERE("Location Code" = FIELD("Location Code"),
                                                                                                                                                 "Zone Code" = FIELD("Cross-Dock Zone Code"),
                                                                                                                                                 "Cross-Dock Bin" = CONST(true));
        }
        field(8509; "Over-Receipt Quantity"; Decimal)
        {
            Caption = 'Over-Receipt Quantity';
            DecimalPlaces = 0 : 5;
            BlankZero = false;
            MinValue = 0;

            trigger OnValidate()
            var
                PurchaseLine: Record "Purchase Line";
                OverReceiptMgt: Codeunit "Over-Receipt Mgt.";
                Handled: Boolean;
            begin
                OnValidateOverReceiptQuantity(Rec, xRec, CurrFieldNo, Handled);
                if Handled then
                    exit;
                if not OverReceiptMgt.IsOverReceiptAllowed() then begin
                    "Over-Receipt Quantity" := 0;
                    exit;
                end;
                if xRec."Over-Receipt Quantity" = "Over-Receipt Quantity" then
                    exit;
                TestField("Over-Receipt Code");
                Validate(Quantity, Quantity - xRec."Over-Receipt Quantity" + "Over-Receipt Quantity");
                Modify();
                OverReceiptMgt.UpdatePurchaseLineOverReceiptQuantityFromWarehouseReceiptLine(Rec);
            end;
        }
        field(8510; "Over-Receipt Code"; Code[20])
        {
            Caption = 'Over-Receipt Code';
            TableRelation = "Over-Receipt Code";
        }
    }

    keys
    {
        key(Key1; "No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Source Type", "Source Subtype", "Source No.", "Source Line No.")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = "Qty. Outstanding (Base)";
        }
        key(Key3; "No.", "Source Type", "Source Subtype", "Source No.", "Source Line No.")
        {
            MaintainSQLIndex = false;
        }
        key(Key4; "No.", "Sorting Sequence No.")
        {
            MaintainSQLIndex = false;
        }
        key(Key5; "No.", "Shelf No.")
        {
            MaintainSQLIndex = false;
        }
        key(Key6; "No.", "Item No.")
        {
            MaintainSQLIndex = false;
        }
        key(Key7; "No.", "Source Document", "Source No.")
        {
            MaintainSQLIndex = false;
        }
        key(Key8; "No.", "Due Date")
        {
            MaintainSQLIndex = false;
        }
        key(Key9; "No.", "Bin Code")
        {
            MaintainSQLIndex = false;
        }
        key(Key10; "Item No.", "Location Code", "Variant Code")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = "Qty. Outstanding (Base)";
        }
        key(Key11; "Bin Code", "Location Code")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = Cubage, Weight;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        WhseRcptHeader: Record "Warehouse Receipt Header";
        OrderStatus: Option;
        SkipConfirm: Boolean;
    begin
        OnBeforeConfirmDelete(Rec, SkipConfirm);

        if (Quantity <> "Qty. Outstanding") and ("Qty. Outstanding" <> 0) and not SkipConfirm then
            if not Confirm(Text004, false, TableCaption, "Line No.") then
                Error(Text003);

        WhseRcptHeader.Get("No.");
        OrderStatus := WhseRcptHeader.GetHeaderStatus("Line No.");
        if OrderStatus <> WhseRcptHeader."Document Status" then begin
            WhseRcptHeader.Validate("Document Status", OrderStatus);
            WhseRcptHeader.Modify();
        end;
    end;

    trigger OnRename()
    begin
        Error(Text001, TableCaption);
    end;

    var
        Location: Record Location;
        Item: Record Item;
        Bin: Record Bin;
        CrossDockMgt: Codeunit "Whse. Cross-Dock Management";
        UOMMgt: Codeunit "Unit of Measure Management";
        UseCrossDock: Boolean;
        Text001: Label 'You cannot rename a %1.';
        Text002: Label 'You cannot handle more than the outstanding %1 units.';
        Text003: Label 'Cancelled.';
        Text004: Label '%1 %2 is not completely received.\Do you really want to delete the %1?';
        Text005: Label 'You cannot Cross-Dock  more than the %1 units to be received.';
        Text006: Label 'Cross-Docking is disabled for this %1 and/or %2';
        IgnoreErrors: Boolean;
        ErrorOccured: Boolean;

    procedure InitNewLine(DocNo: Code[20])
    begin
        Reset;
        "No." := DocNo;
        SetRange("No.", "No.");
        LockTable();
        if FindLast then;

        Init;
        SetIgnoreErrors;
        "Line No." := "Line No." + 10000;
    end;

    procedure AutofillQtyToReceive(var WhseReceiptLine: Record "Warehouse Receipt Line")
    begin
        with WhseReceiptLine do begin
            if Find('-') then
                repeat
                    Validate("Qty. to Receive", "Qty. Outstanding");
                    OnAutoFillQtyToReceiveOnBeforeModify(WhseReceiptLine);
                    Modify;
                until Next = 0;
        end;
    end;

    procedure DeleteQtyToReceive(var WhseReceiptLine: Record "Warehouse Receipt Line")
    begin
        with WhseReceiptLine do begin
            if Find('-') then
                repeat
                    Validate("Qty. to Receive", 0);
                    Modify;
                until Next = 0;
        end;
    end;

    local procedure GetItem()
    begin
        if Item."No." <> "Item No." then
            Item.Get("Item No.");
    end;

    procedure GetLineStatus(): Integer
    begin
        if "Qty. Outstanding" = 0 then
            Status := Status::"Completely Received"
        else
            if Quantity = "Qty. Outstanding" then
                Status := Status::" "
            else
                Status := Status::"Partially Received";

        exit(Status);
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Location.GetLocationSetup(LocationCode, Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    local procedure GetBin(LocationCode: Code[10]; BinCode: Code[20])
    begin
        GetLocation(LocationCode);
        if not Location."Bin Mandatory" then
            Clear(Bin)
        else
            if (Bin."Location Code" <> LocationCode) or
               (Bin.Code <> BinCode)
            then
                Bin.Get(LocationCode, BinCode);
    end;

    local procedure CheckBin(CalledFromQtytoReceive: Boolean)
    var
        BinContent: Record "Bin Content";
        DeductCubage: Decimal;
        DeductWeight: Decimal;
    begin
        if CalledFromQtytoReceive then begin
            DeductCubage := xRec.Cubage;
            DeductWeight := xRec.Weight;
        end;

        if BinContent.Get(
             "Location Code", "Bin Code",
             "Item No.", "Variant Code", "Unit of Measure Code")
        then begin
            if not BinContent.CheckIncreaseBinContent(
                 "Qty. to Receive", xRec."Qty. to Receive",
                 DeductCubage, DeductWeight, Cubage, Weight, false, IgnoreErrors)
            then
                ErrorOccured := true;
        end else begin
            GetBin("Location Code", "Bin Code");
            if not Bin.CheckIncreaseBin(
                 "Bin Code", "Item No.", "Qty. to Receive",
                 DeductCubage, DeductWeight, Cubage, Weight, false, IgnoreErrors)
            then
                ErrorOccured := true;
        end;
        if ErrorOccured then
            "Bin Code" := '';
    end;

    procedure OpenItemTrackingLines()
    var
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        TransferLine: Record "Transfer Line";
        ReservePurchLine: Codeunit "Purch. Line-Reserve";
        ReserveSalesLine: Codeunit "Sales Line-Reserve";
        ReserveTransferLine: Codeunit "Transfer Line-Reserve";
        SecondSourceQtyArray: array[3] of Decimal;
        Direction: Enum "Transfer Direction";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOpenItemTrackingLines(Rec, IsHandled);
        if IsHandled then
            exit;

        TestField("No.");
        TestField("Qty. (Base)");

        GetItem;
        Item.TestField("Item Tracking Code");

        SecondSourceQtyArray[1] := DATABASE::"Warehouse Receipt Line";
        SecondSourceQtyArray[2] := "Qty. to Receive (Base)";
        SecondSourceQtyArray[3] := 0;

        case "Source Type" of
            DATABASE::"Purchase Line":
                begin
                    if PurchaseLine.Get("Source Subtype", "Source No.", "Source Line No.") then
                        ReservePurchLine.CallItemTracking(PurchaseLine, SecondSourceQtyArray);
                end;
            DATABASE::"Sales Line":
                begin
                    if SalesLine.Get("Source Subtype", "Source No.", "Source Line No.") then
                        ReserveSalesLine.CallItemTracking(SalesLine, SecondSourceQtyArray);
                end;
            DATABASE::"Transfer Line":
                begin
                    Direction := Direction::Inbound;
                    if TransferLine.Get("Source No.", "Source Line No.") then
                        ReserveTransferLine.CallItemTracking(TransferLine, Direction, SecondSourceQtyArray);
                end
        end;

        OnAfterOpenItemTrackingLines(Rec, SecondSourceQtyArray);
    end;

    procedure SetIgnoreErrors()
    begin
        IgnoreErrors := true;
    end;

    procedure HasErrorOccured(): Boolean
    begin
        exit(ErrorOccured);
    end;

    procedure InitOutstandingQtys()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitOutstandingQtys(Rec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        Validate("Qty. Outstanding", Quantity - "Qty. Received");
        "Qty. Outstanding (Base)" := "Qty. (Base)" - "Qty. Received (Base)";
    end;

    procedure GetWhseRcptLine(ReceiptNo: Code[20]; SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer): Boolean
    begin
        SetRange("No.", ReceiptNo);
        SetSourceFilter(SourceType, SourceSubType, SourceNo, SourceLineNo, false);
        if FindFirst then
            exit(true);
    end;

    procedure SetItemData(ItemNo: Code[20]; ItemDescription: Text[100]; ItemDescription2: Text[50]; LocationCode: Code[10]; VariantCode: Code[10]; UoMCode: Code[10]; QtyPerUoM: Decimal)
    begin
        "Item No." := ItemNo;
        Description := ItemDescription;
        "Description 2" := ItemDescription2;
        "Location Code" := LocationCode;
        "Variant Code" := VariantCode;
        "Unit of Measure Code" := UoMCode;
        "Qty. per Unit of Measure" := QtyPerUoM;
    end;

    procedure SetSource(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer)
    var
        WhseMgt: Codeunit "Whse. Management";
    begin
        "Source Type" := SourceType;
        "Source Subtype" := SourceSubType;
        "Source No." := SourceNo;
        "Source Line No." := SourceLineNo;
        "Source Document" := WhseMgt.GetSourceDocument("Source Type", "Source Subtype");
    end;

    procedure SetSourceFilter(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SetKey: Boolean)
    var
        WhseManagement: Codeunit "Whse. Management";
    begin
        WhseManagement.SetSourceFilterForWhseRcptLine(Rec, SourceType, SourceSubType, SourceNo, SourceLineNo, SetKey);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOpenItemTrackingLines(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SecondSourceQtyArray: array[3] of Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAutoFillQtyToReceiveOnBeforeModify(var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmDelete(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; var SkipConfirm: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitOutstandingQtys(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenItemTrackingLines(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQtyToReceive(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateOverReceiptQuantity(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; xWarehouseReceiptLine: Record "Warehouse Receipt Line"; CalledByFieldNo: Integer; var Handled: Boolean)
    begin
    end;
}

