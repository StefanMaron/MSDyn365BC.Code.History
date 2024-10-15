report 7391 "Whse. Get Bin Content"
{
    Caption = 'Whse. Get Bin Content';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Bin Content"; "Bin Content")
        {
            RequestFilterFields = "Location Code", "Zone Code", "Bin Code", "Item No.", "Variant Code", "Unit of Measure Code";

            trigger OnAfterGetRecord()
            begin
                if BinType.Code <> "Bin Type Code" then
                    BinType.Get("Bin Type Code");
                if BinType.Receive and not "Cross-Dock Bin" then
                    CurrReport.Skip();

                QtyToEmptyBase := GetQtyToEmptyBase('', '');
                if QtyToEmptyBase <= 0 then
                    CurrReport.Skip();

                case DestinationType2 of
                    DestinationType2::MovementWorksheet:
                        InsertWWL;
                    DestinationType2::WhseInternalPutawayHeader:
                        InsertWIPL;
                    DestinationType2::ItemJournalLine:
                        InsertItemJournalLine;
                    DestinationType2::TransferHeader:
                        begin
                            TransferHeader.TestField("Transfer-from Code", "Location Code");
                            InsertTransferLine;
                        end;
                    DestinationType2::InternalMovementHeader:
                        InsertIntMovementLine;
                end;

                GetSerialNoAndLotNo;
            end;

            trigger OnPreDataItem()
            begin
                if not ReportInitialized then
                    Error(Text001);

                Location.Init();
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(PostingDate; PostingDate)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Posting Date';
                        Editable = PostingDateEditable;
                        ToolTip = 'Specifies the posting date that will appear on the journal lines generated by the report.';
                    }
                    field(DocNo; DocNo)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Document No.';
                        Editable = DocNoEditable;
                        ToolTip = 'Specifies the document number that will appear on the journal lines generated by the report.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            DocNoEditable := true;
            PostingDateEditable := true;
        end;

        trigger OnOpenPage()
        begin
            case DestinationType2 of
                DestinationType2::ItemJournalLine:
                    begin
                        PostingDateEditable := true;
                        DocNoEditable := true;
                    end;
                else begin
                        PostingDateEditable := false;
                        DocNoEditable := false;
                    end;
            end;
        end;
    }

    labels
    {
    }

    var
        WWLine: Record "Whse. Worksheet Line";
        WIPLine: Record "Whse. Internal Put-away Line";
        ItemJournalLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        BinType: Record "Bin Type";
        Location: Record Location;
        InternalMovementHeader: Record "Internal Movement Header";
        InternalMovementLine: Record "Internal Movement Line";
        UOMMgt: Codeunit "Unit of Measure Management";
        QtyToEmptyBase: Decimal;
        ReportInitialized: Boolean;
        Text001: Label 'Report must be initialized.';
        DestinationType2: Option MovementWorksheet,WhseInternalPutawayHeader,ItemJournalLine,TransferHeader,InternalMovementHeader;
        PostingDate: Date;
        DocNo: Code[20];
        [InDataSet]
        PostingDateEditable: Boolean;
        [InDataSet]
        DocNoEditable: Boolean;

    procedure InitializeReport(WWL: Record "Whse. Worksheet Line"; WIPH: Record "Whse. Internal Put-away Header"; DestinationType: Option)
    begin
        DestinationType2 := DestinationType;
        case DestinationType2 of
            DestinationType2::MovementWorksheet:
                begin
                    WWLine := WWL;
                    WWLine.SetCurrentKey("Worksheet Template Name", Name, "Location Code", "Line No.");
                    WWLine.SetRange("Worksheet Template Name", WWLine."Worksheet Template Name");
                    WWLine.SetRange(Name, WWLine.Name);
                    WWLine.SetRange("Location Code", WWLine."Location Code");
                    if WWLine.FindLast then;
                end;
            DestinationType2::WhseInternalPutawayHeader:
                begin
                    WIPLine."No." := WIPH."No.";
                    WIPLine.SetRange("No.", WIPLine."No.");
                    if WIPLine.FindLast then;
                end;
        end;
        ReportInitialized := true;
    end;

    procedure InitializeItemJournalLine(ItemJournalLine2: Record "Item Journal Line")
    begin
        ItemJournalLine := ItemJournalLine2;
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalLine2."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalLine2."Journal Batch Name");
        if ItemJournalLine.FindLast then;

        PostingDate := ItemJournalLine2."Posting Date";
        DocNo := ItemJournalLine2."Document No.";

        DestinationType2 := DestinationType2::ItemJournalLine;
        ReportInitialized := true;
    end;

    procedure InitializeTransferHeader(TransferHeader2: Record "Transfer Header")
    begin
        TransferLine.Reset();
        TransferLine.SetRange("Document No.", TransferHeader2."No.");
        if not TransferLine.FindLast then begin
            TransferLine.Init();
            TransferLine."Document No." := TransferHeader2."No.";
        end;

        TransferHeader := TransferHeader2;

        DestinationType2 := DestinationType2::TransferHeader;
        ReportInitialized := true;
    end;

    procedure InitializeInternalMovement(InternalMovementHeader2: Record "Internal Movement Header")
    begin
        InternalMovementLine.Reset();
        InternalMovementLine.SetRange("No.", InternalMovementHeader2."No.");
        if not InternalMovementLine.FindLast then begin
            InternalMovementLine.Init();
            InternalMovementLine."No." := InternalMovementHeader2."No.";
        end;
        InternalMovementHeader := InternalMovementHeader2;

        DestinationType2 := DestinationType2::InternalMovementHeader;
        ReportInitialized := true;
    end;

    procedure InsertWWL()
    begin
        with WWLine do begin
            Init;
            "Line No." := "Line No." + 10000;
            Validate("Location Code", "Bin Content"."Location Code");
            Validate("Item No.", "Bin Content"."Item No.");
            Validate("Variant Code", "Bin Content"."Variant Code");
            Validate("Unit of Measure Code", "Bin Content"."Unit of Measure Code");
            Validate("From Bin Code", "Bin Content"."Bin Code");
            "From Zone Code" := "Bin Content"."Zone Code";
            Validate("From Unit of Measure Code", "Bin Content"."Unit of Measure Code");
            Validate(Quantity, CalcQtyUOM(QtyToEmptyBase, "Qty. per From Unit of Measure"));
            if QtyToEmptyBase <> (Quantity * "Qty. per From Unit of Measure") then begin
                "Qty. (Base)" := QtyToEmptyBase;
                "Qty. Outstanding (Base)" := QtyToEmptyBase;
                "Qty. to Handle (Base)" := QtyToEmptyBase;
            end;
            "Whse. Document Type" := "Whse. Document Type"::"Whse. Mov.-Worksheet";
            "Whse. Document No." := Name;
            "Whse. Document Line No." := "Line No.";
            OnBeforeInsertWWLine(WWLine, "Bin Content");
            Insert;
        end;
    end;

    procedure InsertWIPL()
    begin
        with WIPLine do begin
            Init;
            "Line No." := "Line No." + 10000;
            Validate("Location Code", "Bin Content"."Location Code");
            Validate("Item No.", "Bin Content"."Item No.");
            Validate("Variant Code", "Bin Content"."Variant Code");
            Validate("Unit of Measure Code", "Bin Content"."Unit of Measure Code");
            Validate("From Bin Code", "Bin Content"."Bin Code");
            "From Zone Code" := "Bin Content"."Zone Code";
            Validate("Unit of Measure Code", "Bin Content"."Unit of Measure Code");
            Validate(Quantity, CalcQtyUOM(QtyToEmptyBase, "Qty. per Unit of Measure"));
            if QtyToEmptyBase <> (Quantity * "Qty. per Unit of Measure") then begin
                "Qty. (Base)" := QtyToEmptyBase;
                "Qty. Outstanding (Base)" := QtyToEmptyBase;
            end;
            OnBeforeInsertWIPLine(WIPLine, "Bin Content");
            Insert;
        end;
    end;

    procedure InsertItemJournalLine()
    var
        ItemJournalTempl: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        with ItemJournalLine do begin
            Init;
            "Line No." := "Line No." + 10000;
            Validate("Entry Type", "Entry Type"::Transfer);
            Validate("Item No.", "Bin Content"."Item No.");
            Validate("Posting Date", PostingDate);
            Validate("Document No.", DocNo);
            Validate("Location Code", "Bin Content"."Location Code");
            Validate("New Location Code", "Bin Content"."Location Code");
            Validate("Variant Code", "Bin Content"."Variant Code");
            Validate("Unit of Measure Code", "Bin Content"."Unit of Measure Code");
            Validate("Bin Code", "Bin Content"."Bin Code");
            Validate("New Bin Code", '');
            Validate("Unit of Measure Code", "Bin Content"."Unit of Measure Code");
            Validate(Quantity, CalcQtyUOM(QtyToEmptyBase, "Qty. per Unit of Measure"));
            ItemJournalTempl.Get("Journal Template Name");
            ItemJournalBatch.Get("Journal Template Name", "Journal Batch Name");
            "Source Code" := ItemJournalTempl."Source Code";
            "Posting No. Series" := ItemJournalBatch."Posting No. Series";
            OnInsertItemJournalLineOnBeforeInsert(ItemJournalLine);
            Insert;
            OnAfterInsertItemJnlLine(ItemJournalLine);
        end;
    end;

    procedure InsertTransferLine()
    begin
        with TransferLine do begin
            Init;
            "Line No." := "Line No." + 10000;
            Validate("Item No.", "Bin Content"."Item No.");
            Validate("Variant Code", "Bin Content"."Variant Code");
            Validate("Unit of Measure Code", "Bin Content"."Unit of Measure Code");
            Validate("Transfer-from Bin Code", "Bin Content"."Bin Code");
            Validate("Unit of Measure Code", "Bin Content"."Unit of Measure Code");
            Validate(Quantity, CalcQtyUOM(QtyToEmptyBase, "Qty. per Unit of Measure"));
            OnBeforeInsertTransferLine(TransferLine, "Bin Content");
            Insert;
        end;
    end;

    procedure InsertIntMovementLine()
    begin
        with InternalMovementLine do begin
            Init;
            "Line No." := "Line No." + 10000;
            Validate("Location Code", "Bin Content"."Location Code");
            Validate("Item No.", "Bin Content"."Item No.");
            Validate("Variant Code", "Bin Content"."Variant Code");
            Validate("Unit of Measure Code", "Bin Content"."Unit of Measure Code");
            Validate("From Bin Code", "Bin Content"."Bin Code");
            Validate("To Bin Code", InternalMovementHeader."To Bin Code");
            Validate("Unit of Measure Code", "Bin Content"."Unit of Measure Code");
            Validate(Quantity, CalcQtyUOM(QtyToEmptyBase, "Qty. per Unit of Measure"));
            OnBeforeInsertInternalMovementLine(InternalMovementLine, "Bin Content");
            Insert;
        end;
    end;

    procedure GetSerialNoAndLotNo()
    var
        WarehouseEntry: Record "Warehouse Entry";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        ReserveItemJnlLine: Codeunit "Item Jnl. Line-Reserve";
        ReserveTransferLine: Codeunit "Transfer Line-Reserve";
        Direction: Enum "Transfer Direction";
        TrackedQtyToEmptyBase: Decimal;
        TotalTrackedQtyBase: Decimal;
    begin
        Clear(ItemTrackingMgt);
        if not ItemTrackingMgt.GetWhseItemTrkgSetup("Bin Content"."Item No.") then
            exit;

        with WarehouseEntry do begin
            Reset;
            SetCurrentKey(
              "Item No.", "Bin Code", "Location Code", "Variant Code", "Unit of Measure Code", "Lot No.", "Serial No.");
            SetRange("Item No.", "Bin Content"."Item No.");
            SetRange("Bin Code", "Bin Content"."Bin Code");
            SetRange("Location Code", "Bin Content"."Location Code");
            SetRange("Variant Code", "Bin Content"."Variant Code");
            SetRange("Unit of Measure Code", "Bin Content"."Unit of Measure Code");
            if FindSet then
                repeat
                    if TrackingExists then begin
                        if "Lot No." <> '' then
                            SetRange("Lot No.", "Lot No.");
                        if "Serial No." <> '' then
                            SetRange("Serial No.", "Serial No.");

                        TrackedQtyToEmptyBase := GetQtyToEmptyBase("Lot No.", "Serial No.");
                        TotalTrackedQtyBase += TrackedQtyToEmptyBase;

                        if TrackedQtyToEmptyBase > 0 then begin
                            GetLocation("Location Code", Location);
                            ItemTrackingMgt.GetWhseExpirationDate("Item No.", "Variant Code", Location, "Lot No.", "Serial No.", "Expiration Date");

                            case DestinationType2 of
                                DestinationType2::MovementWorksheet:
                                    WWLine.SetItemTrackingLines(WarehouseEntry, TrackedQtyToEmptyBase);
                                DestinationType2::WhseInternalPutawayHeader:
                                    WIPLine.SetItemTrackingLines(WarehouseEntry, TrackedQtyToEmptyBase);
                                DestinationType2::ItemJournalLine:
                                    TempTrackingSpecification.InitFromItemJnlLine(ItemJournalLine);
                                DestinationType2::TransferHeader:
                                    TempTrackingSpecification.InitFromTransLine(
                                      TransferLine, TransferLine."Shipment Date", Direction::Outbound);
                                DestinationType2::InternalMovementHeader:
                                    InternalMovementLine.SetItemTrackingLines(WarehouseEntry, TrackedQtyToEmptyBase);
                            end;
                        end;
                        Find('+');
                        SetRange("Lot No.");
                        SetRange("Serial No.");
                    end;
                    if DestinationType2 in [DestinationType2::ItemJournalLine, DestinationType2::TransferHeader] then
                        InsertTempTrackingSpec(WarehouseEntry, TrackedQtyToEmptyBase, TempTrackingSpecification);
                until Next = 0;
            if TotalTrackedQtyBase > QtyToEmptyBase then
                exit;
            case DestinationType2 of
                DestinationType2::ItemJournalLine:
                    ReserveItemJnlLine.RegisterBinContentItemTracking(ItemJournalLine, TempTrackingSpecification);
                DestinationType2::TransferHeader:
                    ReserveTransferLine.RegisterBinContentItemTracking(TransferLine, TempTrackingSpecification);
            end;
        end;
    end;

    local procedure GetLocation(LocationCode: Code[10]; var Location: Record Location)
    begin
        if LocationCode = Location.Code then
            exit;

        if LocationCode = '' then
            Location.Init
        else
            Location.Get(LocationCode);
    end;

    procedure InsertTempTrackingSpec(WarehouseEntry: Record "Warehouse Entry"; QtyOnBin: Decimal; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
        with WarehouseEntry do begin
            TempTrackingSpecification.Init();
            TempTrackingSpecification.SetSkipSerialNoQtyValidation(true);
            TempTrackingSpecification.Validate("Serial No.", "Serial No.");
            TempTrackingSpecification.SetSkipSerialNoQtyValidation(false);
            TempTrackingSpecification."New Serial No." := "Serial No.";
            TempTrackingSpecification.Validate("Lot No.", "Lot No.");
            TempTrackingSpecification."New Lot No." := "Lot No.";
            TempTrackingSpecification."Quantity Handled (Base)" := 0;
            TempTrackingSpecification."Expiration Date" := "Expiration Date";
            TempTrackingSpecification."New Expiration Date" := "Expiration Date";
            TempTrackingSpecification.Validate("Quantity (Base)", QtyOnBin);
            TempTrackingSpecification."Entry No." += 1;
            TempTrackingSpecification.Insert();
            OnAfterInsertTempTrackingSpec(TempTrackingSpecification, WarehouseEntry);
        end;
    end;

    local procedure CalcQtyUOM(QtyBase: Decimal; QtyPerUOM: Decimal): Decimal
    begin
        if QtyPerUOM = 0 then
            exit(0);

        exit(Round(QtyBase / QtyPerUOM, UOMMgt.QtyRndPrecision));
    end;

    local procedure GetQtyToEmptyBase(LotNo: Code[50]; SerialNo: Code[50]): Decimal
    var
        BinContent: Record "Bin Content";
    begin
        with BinContent do begin
            Init;
            Copy("Bin Content");
            FilterGroup(8);
            if LotNo <> '' then
                SetRange("Lot No. Filter", LotNo);
            if SerialNo <> '' then
                SetRange("Serial No. Filter", SerialNo);
            if DestinationType2 = DestinationType2::TransferHeader then
                exit(CalcQtyAvailToPick(0));
            exit(CalcQtyAvailToTake(0));
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertItemJnlLine(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertTempTrackingSpec(var TempTrackingSpecification: Record "Tracking Specification" temporary; WarehouseEntry: Record "Warehouse Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertInternalMovementLine(var InternalMovementLine: Record "Internal Movement Line"; BinContent: Record "Bin Content")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertTransferLine(var TransferLine: Record "Transfer Line"; BinContent: Record "Bin Content")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertWIPLine(var WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line"; BinContent: Record "Bin Content")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertWWLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; BinContent: Record "Bin Content")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertItemJournalLineOnBeforeInsert(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;
}

