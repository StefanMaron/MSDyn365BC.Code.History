codeunit 99000832 "Sales Line-Reserve"
{
    Permissions = TableData "Reservation Entry" = rimd,
                  TableData "Planning Assignment" = rimd;

    trigger OnRun()
    begin
    end;

    var
        ReservedQtyTooLargeErr: Label 'Reserved quantity cannot be greater than %1.', Comment = '%1: not reserved quantity on Sales Line';
        ValueIsEmptyErr: Label 'must be filled in when a quantity is reserved';
        ValueNotEmptyErr: Label 'must not be filled in when a quantity is reserved';
        ValueChangedErr: Label 'must not be changed when a quantity is reserved';
        CodeunitInitErr: Label 'Codeunit is not initialized correctly.';
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
        ReservMgt: Codeunit "Reservation Management";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        UOMMgt: Codeunit "Unit of Measure Management";
        Blocked: Boolean;
        SetFromType: Option " ",Sales,"Requisition Line",Purchase,"Item Journal","BOM Journal","Item Ledger Entry",Service,Job;
        SetFromSubtype: Integer;
        SetFromID: Code[20];
        SetFromBatchName: Code[10];
        SetFromProdOrderLine: Integer;
        SetFromRefNo: Integer;
        SetFromVariantCode: Code[10];
        SetFromLocationCode: Code[10];
        SetFromSerialNo: Code[50];
        SetFromLotNo: Code[50];
        SetFromQtyPerUOM: Decimal;
        ApplySpecificItemTracking: Boolean;
        OverruleItemTracking: Boolean;
        DeleteItemTracking: Boolean;
        ItemTrkgAlreadyOverruled: Boolean;

    procedure CreateReservation(SalesLine: Record "Sales Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForSerialNo: Code[50]; ForLotNo: Code[50])
    var
        ShipmentDate: Date;
        SignFactor: Integer;
    begin
        if SetFromType = 0 then
            Error(CodeunitInitErr);

        SalesLine.TestField(Type, SalesLine.Type::Item);
        SalesLine.TestField("No.");
        SalesLine.TestField("Shipment Date");
        SalesLine.CalcFields("Reserved Qty. (Base)");
        if Abs(SalesLine."Outstanding Qty. (Base)") < Abs(SalesLine."Reserved Qty. (Base)") + QuantityBase then
            Error(
              ReservedQtyTooLargeErr,
              Abs(SalesLine."Outstanding Qty. (Base)") - Abs(SalesLine."Reserved Qty. (Base)"));

        SalesLine.TestField("Variant Code", SetFromVariantCode);
        SalesLine.TestField("Location Code", SetFromLocationCode);

        if SalesLine."Document Type" = SalesLine."Document Type"::"Return Order" then
            SignFactor := 1
        else
            SignFactor := -1;

        if QuantityBase * SignFactor < 0 then
            ShipmentDate := SalesLine."Shipment Date"
        else begin
            ShipmentDate := ExpectedReceiptDate;
            ExpectedReceiptDate := SalesLine."Shipment Date";
        end;

        CreateReservEntry.CreateReservEntryFor(
          DATABASE::"Sales Line", SalesLine."Document Type",
          SalesLine."Document No.", '', 0, SalesLine."Line No.", SalesLine."Qty. per Unit of Measure",
          Quantity, QuantityBase, ForSerialNo, ForLotNo);
        CreateReservEntry.CreateReservEntryFrom(
          SetFromType, SetFromSubtype, SetFromID, SetFromBatchName, SetFromProdOrderLine, SetFromRefNo,
          SetFromQtyPerUOM, SetFromSerialNo, SetFromLotNo);
        CreateReservEntry.CreateReservEntry(
          SalesLine."No.", SalesLine."Variant Code", SalesLine."Location Code",
          Description, ExpectedReceiptDate, ShipmentDate);

        SetFromType := 0;
    end;

    local procedure CreateBindingReservation(SalesLine: Record "Sales Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal)
    begin
        CreateReservation(SalesLine, Description, ExpectedReceiptDate, Quantity, QuantityBase, '', '');
    end;

    procedure CreateReservationSetFrom(TrackingSpecificationFrom: Record "Tracking Specification")
    begin
        with TrackingSpecificationFrom do begin
            SetFromType := "Source Type";
            SetFromSubtype := "Source Subtype";
            SetFromID := "Source ID";
            SetFromBatchName := "Source Batch Name";
            SetFromProdOrderLine := "Source Prod. Order Line";
            SetFromRefNo := "Source Ref. No.";
            SetFromVariantCode := "Variant Code";
            SetFromLocationCode := "Location Code";
            SetFromSerialNo := "Serial No.";
            SetFromLotNo := "Lot No.";
            SetFromQtyPerUOM := "Qty. per Unit of Measure";
        end;
    end;

    procedure SetBinding(Binding: Option " ","Order-to-Order")
    begin
        CreateReservEntry.SetBinding(Binding);
    end;

    procedure SetDisallowCancellation(DisallowCancellation: Boolean)
    begin
        CreateReservEntry.SetDisallowCancellation(DisallowCancellation);
    end;

    procedure FilterReservFor(var FilterReservEntry: Record "Reservation Entry"; SalesLine: Record "Sales Line")
    begin
        FilterReservEntry.SetSourceFilter(
          DATABASE::"Sales Line", SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.", false);
        FilterReservEntry.SetSourceFilter('', 0);
    end;

    procedure ReservQuantity(SalesLine: Record "Sales Line"; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal)
    begin
        case SalesLine."Document Type" of
            SalesLine."Document Type"::Quote,
            SalesLine."Document Type"::Order,
            SalesLine."Document Type"::Invoice,
            SalesLine."Document Type"::"Blanket Order":
                begin
                    QtyToReserve := SalesLine."Outstanding Quantity";
                    QtyToReserveBase := SalesLine."Outstanding Qty. (Base)";
                end;
            SalesLine."Document Type"::"Return Order",
            SalesLine."Document Type"::"Credit Memo":
                begin
                    QtyToReserve := -SalesLine."Outstanding Quantity";
                    QtyToReserveBase := -SalesLine."Outstanding Qty. (Base)"
                end;
        end;

        OnAfterReservQuantity(SalesLine, QtyToReserve, QtyToReserveBase);
    end;

    procedure Caption(SalesLine: Record "Sales Line") CaptionText: Text
    begin
        CaptionText :=
          StrSubstNo('%1 %2 %3', SalesLine."Document Type", SalesLine."Document No.", SalesLine."No.");
    end;

    procedure FindReservEntry(SalesLine: Record "Sales Line"; var ReservEntry: Record "Reservation Entry"): Boolean
    begin
        ReservEngineMgt.InitFilterAndSortingLookupFor(ReservEntry, false);
        FilterReservFor(ReservEntry, SalesLine);
        exit(ReservEntry.FindLast);
    end;

    procedure ReservEntryExist(SalesLine: Record "Sales Line"): Boolean
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEngineMgt.InitFilterAndSortingLookupFor(ReservEntry, false);
        FilterReservFor(ReservEntry, SalesLine);
        exit(not ReservEntry.IsEmpty);
    end;

    procedure VerifyChange(var NewSalesLine: Record "Sales Line"; var OldSalesLine: Record "Sales Line")
    var
        SalesLine: Record "Sales Line";
        ShowError: Boolean;
        HasError: Boolean;
    begin
        if (NewSalesLine.Type <> NewSalesLine.Type::Item) and (OldSalesLine.Type <> OldSalesLine.Type::Item) then
            exit;
        if Blocked then
            exit;
        if NewSalesLine."Line No." = 0 then
            if not SalesLine.Get(
                 NewSalesLine."Document Type", NewSalesLine."Document No.", NewSalesLine."Line No.")
            then
                exit;

        NewSalesLine.CalcFields("Reserved Qty. (Base)");
        ShowError := NewSalesLine."Reserved Qty. (Base)" <> 0;

        HasError := TestSalesLineModification(OldSalesLine, NewSalesLine, ShowError);

        OnVerifyChangeOnBeforeHasError(NewSalesLine, OldSalesLine, HasError, ShowError);

        if HasError then
            ClearReservation(OldSalesLine, NewSalesLine);

        if HasError or (NewSalesLine."Shipment Date" <> OldSalesLine."Shipment Date") then begin
            AssignForPlanning(NewSalesLine);
            if (NewSalesLine."No." <> OldSalesLine."No.") or
               (NewSalesLine."Variant Code" <> OldSalesLine."Variant Code") or
               (NewSalesLine."Location Code" <> OldSalesLine."Location Code")
            then
                AssignForPlanning(OldSalesLine);
        end;
    end;

    procedure VerifyQuantity(var NewSalesLine: Record "Sales Line"; var OldSalesLine: Record "Sales Line")
    var
        SalesLine: Record "Sales Line";
    begin
        if Blocked then
            exit;

        with NewSalesLine do begin
            if Type <> Type::Item then
                exit;
            if "Document Type" = OldSalesLine."Document Type" then
                if "Line No." = OldSalesLine."Line No." then
                    if "Quantity (Base)" = OldSalesLine."Quantity (Base)" then
                        exit;
            if "Line No." = 0 then
                if not SalesLine.Get("Document Type", "Document No.", "Line No.") then
                    exit;
            ReservMgt.SetSalesLine(NewSalesLine);
            if "Qty. per Unit of Measure" <> OldSalesLine."Qty. per Unit of Measure" then
                ReservMgt.ModifyUnitOfMeasure;
            if "Outstanding Qty. (Base)" * OldSalesLine."Outstanding Qty. (Base)" < 0 then
                ReservMgt.DeleteReservEntries(true, 0)
            else
                ReservMgt.DeleteReservEntries(false, "Outstanding Qty. (Base)");
            ReservMgt.ClearSurplus;
            ReservMgt.AutoTrack("Outstanding Qty. (Base)");
            AssignForPlanning(NewSalesLine);
        end;
    end;

    procedure TransferSalesLineToItemJnlLine(var SalesLine: Record "Sales Line"; var ItemJnlLine: Record "Item Journal Line"; TransferQty: Decimal; var CheckApplFromItemEntry: Boolean; OnlyILEReservations: Boolean): Decimal
    var
        OldReservEntry: Record "Reservation Entry";
        OppositeReservEntry: Record "Reservation Entry";
        NotFullyReserved: Boolean;
    begin
        if not FindReservEntry(SalesLine, OldReservEntry) then
            exit(TransferQty);
        OldReservEntry.Lock;
        // Handle Item Tracking on drop shipment:
        Clear(CreateReservEntry);

        if OverruleItemTracking then
            if ItemJnlLine.TrackingExists then begin
                CreateReservEntry.SetNewSerialLotNo(ItemJnlLine."Serial No.", ItemJnlLine."Lot No.");
                CreateReservEntry.SetOverruleItemTracking(not ItemTrkgAlreadyOverruled);
                // Try to match against Item Tracking on the sales order line:
                OldReservEntry.SetTrackingFilterFromItemJnlLine(ItemJnlLine);
                if OldReservEntry.IsEmpty then
                    exit(TransferQty);
            end;

        ItemJnlLine.TestItemFields(SalesLine."No.", SalesLine."Variant Code", SalesLine."Location Code");

        if TransferQty = 0 then
            exit;

        if ItemJnlLine."Invoiced Quantity" <> 0 then
            CreateReservEntry.SetUseQtyToInvoice(true);

        if ReservEngineMgt.InitRecordSet(OldReservEntry) then begin
            repeat
                OldReservEntry.TestItemFields(SalesLine."No.", SalesLine."Variant Code", SalesLine."Location Code");

                if ApplySpecificItemTracking and (ItemJnlLine."Applies-to Entry" <> 0) then begin
                    CreateReservEntry.SetItemLedgEntryNo(ItemJnlLine."Applies-to Entry");
                    CheckApplFromItemEntry := false;
                end;

                if ItemJnlLine."Assemble to Order" then
                    OldReservEntry."Appl.-to Item Entry" :=
                      SalesLine.FindOpenATOEntry(OldReservEntry."Lot No.", OldReservEntry."Serial No.");

                if CheckApplFromItemEntry then begin
                    if OldReservEntry."Reservation Status" = OldReservEntry."Reservation Status"::Reservation then begin
                        OppositeReservEntry.Get(OldReservEntry."Entry No.", not OldReservEntry.Positive);
                        if OppositeReservEntry."Source Type" <> DATABASE::"Item Ledger Entry" then
                            NotFullyReserved := true;
                    end else
                        NotFullyReserved := true;

                    if OldReservEntry."Item Tracking" <> OldReservEntry."Item Tracking"::None then begin
                        OldReservEntry.TestField("Appl.-from Item Entry");
                        CreateReservEntry.SetApplyFromEntryNo(OldReservEntry."Appl.-from Item Entry");
                        CheckApplFromItemEntry := false;
                    end;
                end;

                if not (ItemJnlLine."Assemble to Order" xor OldReservEntry."Disallow Cancellation") then
                    if not VerifyPickedQtyReservToInventory(OldReservEntry, SalesLine, TransferQty) then
                        if OnlyILEReservations and OppositeReservEntry.Get(OldReservEntry."Entry No.", not OldReservEntry.Positive) then begin
                            if OppositeReservEntry."Source Type" = DATABASE::"Item Ledger Entry" then
                                TransferQty := CreateReservEntry.TransferReservEntry(
                                    DATABASE::"Item Journal Line", ItemJnlLine."Entry Type", ItemJnlLine."Journal Template Name",
                                    ItemJnlLine."Journal Batch Name", 0, ItemJnlLine."Line No.",
                                    ItemJnlLine."Qty. per Unit of Measure", OldReservEntry, TransferQty);
                        end else
                            TransferQty := CreateReservEntry.TransferReservEntry(
                                DATABASE::"Item Journal Line", ItemJnlLine."Entry Type", ItemJnlLine."Journal Template Name",
                                ItemJnlLine."Journal Batch Name", 0, ItemJnlLine."Line No.",
                                ItemJnlLine."Qty. per Unit of Measure", OldReservEntry, TransferQty);
            until (ReservEngineMgt.NEXTRecord(OldReservEntry) = 0) or (TransferQty = 0);
            CheckApplFromItemEntry := CheckApplFromItemEntry and NotFullyReserved;
        end;
        exit(TransferQty);
    end;

    procedure TransferSaleLineToSalesLine(var OldSalesLine: Record "Sales Line"; var NewSalesLine: Record "Sales Line"; TransferQty: Decimal)
    var
        OldReservEntry: Record "Reservation Entry";
        Status: Option Reservation,Tracking,Surplus,Prospect;
    begin
        // Used for sales quote and blanket order when transferred to order
        if not FindReservEntry(OldSalesLine, OldReservEntry) then
            exit;

        OldReservEntry.Lock;

        NewSalesLine.TestItemFields(OldSalesLine."No.", OldSalesLine."Variant Code", OldSalesLine."Location Code");

        for Status := Status::Reservation to Status::Prospect do begin
            if TransferQty = 0 then
                exit;
            OldReservEntry.SetRange("Reservation Status", Status);
            if OldReservEntry.FindSet then
                repeat
                    OldReservEntry.TestItemFields(OldSalesLine."No.", OldSalesLine."Variant Code", OldSalesLine."Location Code");
                    if (OldReservEntry."Reservation Status" = OldReservEntry."Reservation Status"::Prospect) and
                       (OldSalesLine."Document Type" in [OldSalesLine."Document Type"::Quote,
                                                         OldSalesLine."Document Type"::"Blanket Order"])
                    then
                        OldReservEntry."Reservation Status" := OldReservEntry."Reservation Status"::Surplus;

                    TransferQty := CreateReservEntry.TransferReservEntry(DATABASE::"Sales Line",
                        NewSalesLine."Document Type", NewSalesLine."Document No.", '', 0,
                        NewSalesLine."Line No.", NewSalesLine."Qty. per Unit of Measure", OldReservEntry, TransferQty);

                until (OldReservEntry.Next = 0) or (TransferQty = 0);
        end;
    end;

    procedure DeleteLineConfirm(var SalesLine: Record "Sales Line"): Boolean
    begin
        with SalesLine do begin
            if not ReservEntryExist(SalesLine) then
                exit(true);

            ReservMgt.SetSalesLine(SalesLine);
            if ReservMgt.DeleteItemTrackingConfirm then
                DeleteItemTracking := true;
        end;

        exit(DeleteItemTracking);
    end;

    procedure DeleteLine(var SalesLine: Record "Sales Line")
    begin
        with SalesLine do begin
            ReservMgt.SetSalesLine(SalesLine);
            if DeleteItemTracking then
                ReservMgt.SetItemTrackingHandling(1); // Allow Deletion
            ReservMgt.DeleteReservEntries(true, 0);
            DeleteInvoiceSpecFromLine(SalesLine);
            CalcFields("Reserved Qty. (Base)");
            AssignForPlanning(SalesLine);
        end;
    end;

    procedure AssignForPlanning(var SalesLine: Record "Sales Line")
    var
        PlanningAssignment: Record "Planning Assignment";
    begin
        with SalesLine do begin
            if "Document Type" <> "Document Type"::Order then
                exit;
            if Type <> Type::Item then
                exit;
            if "No." <> '' then
                PlanningAssignment.ChkAssignOne("No.", "Variant Code", "Location Code", "Shipment Date");
        end;
    end;

    procedure CallItemTracking(var SalesLine: Record "Sales Line")
    var
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        TrackingSpecification.InitFromSalesLine(SalesLine);
        if ((SalesLine."Document Type" = SalesLine."Document Type"::Invoice) and
            (SalesLine."Shipment No." <> '')) or
           ((SalesLine."Document Type" = SalesLine."Document Type"::"Credit Memo") and
            (SalesLine."Return Receipt No." <> ''))
        then
            ItemTrackingLines.SetFormRunMode(2); // Combined shipment/receipt
        if SalesLine."Drop Shipment" then begin
            ItemTrackingLines.SetFormRunMode(3); // Drop Shipment
            if SalesLine."Purchase Order No." <> '' then
                ItemTrackingLines.SetSecondSourceRowID(ItemTrackingMgt.ComposeRowID(DATABASE::"Purchase Line",
                    1, SalesLine."Purchase Order No.", '', 0, SalesLine."Purch. Order Line No."));
        end;
        ItemTrackingLines.SetSourceSpec(TrackingSpecification, SalesLine."Shipment Date");
        ItemTrackingLines.SetInbound(SalesLine.IsInbound);
        ItemTrackingLines.RunModal;
    end;

    procedure CallItemTracking(var SalesLine: Record "Sales Line"; SecondSourceQuantityArray: array[3] of Decimal)
    begin
        CallItemTrackingSecondSource(SalesLine, SecondSourceQuantityArray, false);
    end;

    procedure CallItemTrackingSecondSource(var SalesLine: Record "Sales Line"; SecondSourceQuantityArray: array[3] of Decimal; AsmToOrder: Boolean)
    var
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        if SecondSourceQuantityArray[1] = DATABASE::"Warehouse Shipment Line" then
            ItemTrackingLines.SetSecondSourceID(DATABASE::"Warehouse Shipment Line", AsmToOrder);

        TrackingSpecification.InitFromSalesLine(SalesLine);
        ItemTrackingLines.SetSourceSpec(TrackingSpecification, SalesLine."Shipment Date");
        ItemTrackingLines.SetSecondSourceQuantity(SecondSourceQuantityArray);
        ItemTrackingLines.RunModal;
    end;

    procedure RetrieveInvoiceSpecification(var SalesLine: Record "Sales Line"; var TempInvoicingSpecification: Record "Tracking Specification" temporary) OK: Boolean
    var
        SourceSpecification: Record "Tracking Specification";
    begin
        Clear(TempInvoicingSpecification);
        if SalesLine.Type <> SalesLine.Type::Item then
            exit;
        if ((SalesLine."Document Type" = SalesLine."Document Type"::Invoice) and
            (SalesLine."Shipment No." <> '')) or
           ((SalesLine."Document Type" = SalesLine."Document Type"::"Credit Memo") and
            (SalesLine."Return Receipt No." <> ''))
        then
            OK := RetrieveInvoiceSpecification2(SalesLine, TempInvoicingSpecification)
        else begin
            SourceSpecification.InitFromSalesLine(SalesLine);
            OK := ItemTrackingMgt.RetrieveInvoiceSpecification(SourceSpecification, TempInvoicingSpecification);
        end;
    end;

    local procedure RetrieveInvoiceSpecification2(var SalesLine: Record "Sales Line"; var TempInvoicingSpecification: Record "Tracking Specification" temporary) OK: Boolean
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservEntry: Record "Reservation Entry";
    begin
        // Used for combined shipment/return:
        if SalesLine.Type <> SalesLine.Type::Item then
            exit;
        if not FindReservEntry(SalesLine, ReservEntry) then
            exit;
        ReservEntry.FindSet;
        repeat
            ReservEntry.TestField("Reservation Status", ReservEntry."Reservation Status"::Prospect);
            ReservEntry.TestField("Item Ledger Entry No.");
            TrackingSpecification.Get(ReservEntry."Item Ledger Entry No.");
            TempInvoicingSpecification := TrackingSpecification;
            TempInvoicingSpecification."Qty. to Invoice (Base)" :=
              ReservEntry."Qty. to Invoice (Base)";
            TempInvoicingSpecification."Qty. to Invoice" :=
              Round(ReservEntry."Qty. to Invoice (Base)" / ReservEntry."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision);
            TempInvoicingSpecification."Buffer Status" := TempInvoicingSpecification."Buffer Status"::MODIFY;
            TempInvoicingSpecification.Insert;
            ReservEntry.Delete;
        until ReservEntry.Next = 0;

        OK := TempInvoicingSpecification.FindFirst;
    end;

    procedure DeleteInvoiceSpecFromHeader(var SalesHeader: Record "Sales Header")
    begin
        ItemTrackingMgt.DeleteInvoiceSpecFromHeader(
          DATABASE::"Sales Line", SalesHeader."Document Type", SalesHeader."No.");
    end;

    local procedure DeleteInvoiceSpecFromLine(SalesLine: Record "Sales Line")
    begin
        ItemTrackingMgt.DeleteInvoiceSpecFromLine(
          DATABASE::"Sales Line", SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
    end;

    procedure UpdateItemTrackingAfterPosting(SalesHeader: Record "Sales Header")
    var
        ReservEntry: Record "Reservation Entry";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
    begin
        // Used for updating Quantity to Handle and Quantity to Invoice after posting
        ReservEntry.Reset;
        ReservEntry.SetSourceFilter(DATABASE::"Sales Line", SalesHeader."Document Type", SalesHeader."No.", -1, true);
        ReservEntry.SetSourceFilter('', 0);
        CreateReservEntry.UpdateItemTrackingAfterPosting(ReservEntry);
    end;

    procedure SetApplySpecificItemTracking(ApplySpecific: Boolean)
    begin
        ApplySpecificItemTracking := ApplySpecific;
    end;

    procedure SetOverruleItemTracking(Overrule: Boolean)
    begin
        OverruleItemTracking := Overrule;
    end;

    procedure Block(SetBlocked: Boolean)
    begin
        Blocked := SetBlocked;
    end;

    procedure SetItemTrkgAlreadyOverruled(HasBeenOverruled: Boolean)
    begin
        ItemTrkgAlreadyOverruled := HasBeenOverruled;
    end;

    local procedure VerifyPickedQtyReservToInventory(OldReservEntry: Record "Reservation Entry"; SalesLine: Record "Sales Line"; TransferQty: Decimal): Boolean
    var
        WhseShptLine: Record "Warehouse Shipment Line";
        NewReservEntry: Record "Reservation Entry";
    begin
        with WhseShptLine do begin
            if not ReadPermission then
                exit(false);

            SetSourceFilter(DATABASE::"Sales Line", SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.", false);
            SetRange(Status, Status::"Partially Picked");
            exit(FindFirst and NewReservEntry.Get(OldReservEntry."Entry No.", not OldReservEntry.Positive) and
              (OldReservEntry."Reservation Status" = OldReservEntry."Reservation Status"::Reservation) and
              (NewReservEntry."Source Type" <> DATABASE::"Item Ledger Entry") and ("Qty. Picked (Base)" >= TransferQty));
        end;
    end;

    procedure BindToPurchase(SalesLine: Record "Sales Line"; PurchLine: Record "Purchase Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Purchase Line", PurchLine."Document Type", PurchLine."Document No.", '', 0, PurchLine."Line No.",
          PurchLine."Variant Code", PurchLine."Location Code", PurchLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(SalesLine, PurchLine.Description, PurchLine."Expected Receipt Date", ReservQty, ReservQtyBase);
    end;

    procedure BindToProdOrder(SalesLine: Record "Sales Line"; ProdOrderLine: Record "Prod. Order Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Prod. Order Line", ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", '', ProdOrderLine."Line No.", 0,
          ProdOrderLine."Variant Code", ProdOrderLine."Location Code", ProdOrderLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(SalesLine, ProdOrderLine.Description, ProdOrderLine."Ending Date", ReservQty, ReservQtyBase);
    end;

    procedure BindToRequisition(SalesLine: Record "Sales Line"; ReqLine: Record "Requisition Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        if SalesLine.Reserve = SalesLine.Reserve::Never then
            exit;
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Requisition Line",
          0, ReqLine."Worksheet Template Name", ReqLine."Journal Batch Name", 0, ReqLine."Line No.",
          ReqLine."Variant Code", ReqLine."Location Code", ReqLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(SalesLine, ReqLine.Description, ReqLine."Due Date", ReservQty, ReservQtyBase);
    end;

    procedure BindToAssembly(SalesLine: Record "Sales Line"; AsmHeader: Record "Assembly Header"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Assembly Header", AsmHeader."Document Type", AsmHeader."No.", '', 0, 0,
          AsmHeader."Variant Code", AsmHeader."Location Code", AsmHeader."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(SalesLine, AsmHeader.Description, AsmHeader."Due Date", ReservQty, ReservQtyBase);
    end;

    procedure BindToTransfer(SalesLine: Record "Sales Line"; TransLine: Record "Transfer Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Transfer Line", 1, TransLine."Document No.", '', 0, TransLine."Line No.",
          TransLine."Variant Code", TransLine."Transfer-to Code", TransLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(SalesLine, TransLine.Description, TransLine."Receipt Date", ReservQty, ReservQtyBase);
    end;

    local procedure CheckItemNo(var SalesLine: Record "Sales Line"): Boolean
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetFilter("Item No.", '<>%1', SalesLine."No.");
        ReservationEntry.SetRange("Source Type", DATABASE::"Sales Line");
        ReservationEntry.SetRange("Source Subtype", SalesLine."Document Type");
        ReservationEntry.SetRange("Source ID", SalesLine."Document No.");
        ReservationEntry.SetRange("Source Ref. No.", SalesLine."Line No.");
        exit(ReservationEntry.IsEmpty);
    end;

    local procedure ClearReservation(OldSalesLine: Record "Sales Line"; NewSalesLine: Record "Sales Line")
    var
        DummyReservEntry: Record "Reservation Entry";
    begin
        if (NewSalesLine."No." <> OldSalesLine."No.") or FindReservEntry(NewSalesLine, DummyReservEntry) then begin
            if (NewSalesLine."No." <> OldSalesLine."No.") or (NewSalesLine.Type <> OldSalesLine.Type) then begin
                ReservMgt.SetSalesLine(OldSalesLine);
                ReservMgt.DeleteReservEntries(true, 0);
                ReservMgt.SetSalesLine(NewSalesLine);
            end else begin
                ReservMgt.SetSalesLine(NewSalesLine);
                ReservMgt.DeleteReservEntries(true, 0);
            end;
            ReservMgt.AutoTrack(NewSalesLine."Outstanding Qty. (Base)");
        end;
    end;

    local procedure TestSalesLineModification(OldSalesLine: Record "Sales Line"; NewSalesLine: Record "Sales Line"; ThrowError: Boolean) HasError: Boolean
    var
        IsHandled: Boolean;
    begin
        if (NewSalesLine."Shipment Date" = 0D) and (OldSalesLine."Shipment Date" <> 0D) then begin
            if ThrowError then
                NewSalesLine.FieldError("Shipment Date", ValueIsEmptyErr);
            HasError := true;
        end;

        OnTestSalesLineModificationOnBeforeTestJobNo(NewSalesLine, IsHandled);
        if not IsHandled then
            if NewSalesLine."Job No." <> '' then begin
                if ThrowError then
                    NewSalesLine.FieldError("Job No.", ValueNotEmptyErr);
                HasError := true;
            end;

        if NewSalesLine."Purchase Order No." <> '' then begin
            if ThrowError then
                NewSalesLine.FieldError("Purchase Order No.", ValueNotEmptyErr);
            HasError := NewSalesLine."Purchase Order No." <> OldSalesLine."Purchase Order No.";
        end;

        if NewSalesLine."Purch. Order Line No." <> 0 then begin
            if ThrowError then
                NewSalesLine.FieldError("Purch. Order Line No.", ValueNotEmptyErr);
            HasError := NewSalesLine."Purch. Order Line No." <> OldSalesLine."Purch. Order Line No.";
        end;

        if NewSalesLine."Drop Shipment" and not OldSalesLine."Drop Shipment" then begin
            if ThrowError then
                NewSalesLine.FieldError("Drop Shipment", ValueNotEmptyErr);
            HasError := true;
        end;

        if NewSalesLine."Special Order" and not OldSalesLine."Special Order" then begin
            if ThrowError then
                NewSalesLine.FieldError("Special Order", ValueNotEmptyErr);
            HasError := true;
        end;

        if (NewSalesLine."No." <> OldSalesLine."No.") and not CheckItemNo(NewSalesLine) then begin
            if ThrowError then
                NewSalesLine.FieldError("No.", ValueChangedErr);
            HasError := true;
        end;

        if NewSalesLine."Variant Code" <> OldSalesLine."Variant Code" then begin
            if ThrowError then
                NewSalesLine.FieldError("Variant Code", ValueChangedErr);
            HasError := true;
        end;

        if NewSalesLine."Location Code" <> OldSalesLine."Location Code" then begin
            if ThrowError then
                NewSalesLine.FieldError("Location Code", ValueChangedErr);
            HasError := true;
        end;

        if (OldSalesLine.Type = OldSalesLine.Type::Item) and (NewSalesLine.Type = NewSalesLine.Type::Item) then
            if (NewSalesLine."Bin Code" <> OldSalesLine."Bin Code") and
               (not ReservMgt.CalcIsAvailTrackedQtyInBin(
                  NewSalesLine."No.", NewSalesLine."Bin Code",
                  NewSalesLine."Location Code", NewSalesLine."Variant Code",
                  DATABASE::"Sales Line", NewSalesLine."Document Type",
                  NewSalesLine."Document No.", '', 0, NewSalesLine."Line No."))
            then begin
                if ThrowError then
                    NewSalesLine.FieldError("Bin Code", ValueChangedErr);
                HasError := true;
            end;

        if NewSalesLine."Line No." <> OldSalesLine."Line No." then
            HasError := true;

        if NewSalesLine.Type <> OldSalesLine.Type then
            HasError := true;
    end;

    procedure SetDeleteItemTracking(NewDeleteItemTracking: Boolean)
    begin
        DeleteItemTracking := NewDeleteItemTracking
    end;

    [Scope('OnPrem')]
    procedure CopyReservEntryToTemp(var TempReservationEntry: Record "Reservation Entry" temporary; OldSalesLine: Record "Sales Line")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.Reset;
        ReservationEntry.SetSourceFilter(
          DATABASE::"Sales Line", OldSalesLine."Document Type", OldSalesLine."Document No.", OldSalesLine."Line No.", true);
        if ReservationEntry.FindSet then
            repeat
                TempReservationEntry := ReservationEntry;
                TempReservationEntry.Insert;
            until ReservationEntry.Next = 0;
        ReservationEntry.DeleteAll;
    end;

    [Scope('OnPrem')]
    procedure CopyReservEntryFromTemp(var TempReservationEntry: Record "Reservation Entry" temporary; OldSalesLine: Record "Sales Line"; NewSourceRefNo: Integer)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        TempReservationEntry.Reset;
        TempReservationEntry.SetSourceFilter(
          DATABASE::"Sales Line", OldSalesLine."Document Type", OldSalesLine."Document No.", OldSalesLine."Line No.", true);
        if TempReservationEntry.FindSet then
            repeat
                ReservationEntry := TempReservationEntry;
                ReservationEntry."Source Ref. No." := NewSourceRefNo;
                ReservationEntry.Insert;
            until TempReservationEntry.Next = 0;
        TempReservationEntry.DeleteAll;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReservQuantity(SalesLine: Record "Sales Line"; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTestSalesLineModificationOnBeforeTestJobNo(SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVerifyChangeOnBeforeHasError(NewSalesLine: Record "Sales Line"; OldSalesLine: Record "Sales Line"; var HasError: Boolean; var ShowError: Boolean)
    begin
    end;
}

