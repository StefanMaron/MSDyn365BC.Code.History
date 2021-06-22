codeunit 7321 "Create Inventory Put-away"
{
    TableNo = "Warehouse Activity Header";

    trigger OnRun()
    begin
        WhseActivHeader := Rec;
        Code;
        Rec := WhseActivHeader;
    end;

    var
        WhseActivHeader: Record "Warehouse Activity Header";
        WhseRequest: Record "Warehouse Request";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        Location: Record Location;
        Item: Record Item;
        PurchHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        TransferHeader: Record "Transfer Header";
        ProdOrder: Record "Production Order";
        SourceDocRecRef: RecordRef;
        PostingDate: Date;
        VendorDocNo: Code[35];
        RemQtyToPutAway: Decimal;
        NextLineNo: Integer;
        LineCreated: Boolean;
        SNRequired: Boolean;
        LNRequired: Boolean;
        ReservationFound: Boolean;
        HideDialog: Boolean;
        CheckLineExist: Boolean;
        AutoCreation: Boolean;
        Text000: Label 'Nothing to handle.';

    local procedure "Code"()
    var
        IsHandled: Boolean;
    begin
        WhseActivHeader.TestField("No.");
        WhseActivHeader.TestField("Location Code");

        if not HideDialog then
            if not GetWhseRequest(WhseRequest) then
                exit;

        GetSourceDocHeader;
        UpdateWhseActivHeader(WhseRequest);

        IsHandled := false;
        OnBeforeCreatePutAwayLines(WhseRequest, WhseActivHeader, LineCreated, IsHandled);
        if IsHandled then
            exit;

        case WhseRequest."Source Document" of
            WhseRequest."Source Document"::"Purchase Order":
                CreatePutAwayLinesFromPurchase(PurchHeader);
            WhseRequest."Source Document"::"Purchase Return Order":
                CreatePutAwayLinesFromPurchase(PurchHeader);
            WhseRequest."Source Document"::"Sales Order":
                CreatePutAwayLinesFromSales(SalesHeader);
            WhseRequest."Source Document"::"Sales Return Order":
                CreatePutAwayLinesFromSales(SalesHeader);
            WhseRequest."Source Document"::"Inbound Transfer":
                CreatePutAwayLinesFromTransfer(TransferHeader);
            WhseRequest."Source Document"::"Prod. Output":
                CreatePutAwayLinesFromProd(ProdOrder);
            WhseRequest."Source Document"::"Prod. Consumption":
                CreatePutAwayLinesFromComp(ProdOrder);
            else
                OnCreatePutAwayFromWhseRequest(WhseRequest, SourceDocRecRef, LineCreated)
        end;

        if LineCreated then
            WhseActivHeader.Modify
        else
            if not AutoCreation then
                Error(Text000);

        OnAfterCreateInventoryPutaway(WhseRequest, LineCreated, WhseActivHeader);
    end;

    local procedure GetWhseRequest(var WhseRequest: Record "Warehouse Request"): Boolean
    begin
        with WhseRequest do begin
            FilterGroup := 2;
            SetRange(Type, Type::Inbound);
            SetRange("Location Code", WhseActivHeader."Location Code");
            SetRange("Document Status", "Document Status"::Released);
            if WhseActivHeader."Source Document" <> 0 then
                SetRange("Source Document", WhseActivHeader."Source Document");
            if WhseActivHeader."Source No." <> '' then
                SetRange("Source No.", WhseActivHeader."Source No.");
            SetRange("Completely Handled", false);
            FilterGroup := 0;
            if PAGE.RunModal(
                 PAGE::"Source Documents", WhseRequest, "Source No.") = ACTION::LookupOK
            then
                exit(true);
        end;
    end;

    local procedure GetSourceDocHeader()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetSourceDocHeader(WhseRequest, IsHandled);
        if IsHandled then
            exit;

        case WhseRequest."Source Document" of
            WhseRequest."Source Document"::"Purchase Order":
                begin
                    PurchHeader.Get(PurchHeader."Document Type"::Order, WhseRequest."Source No.");
                    PostingDate := PurchHeader."Posting Date";
                    VendorDocNo := PurchHeader."Vendor Invoice No.";
                end;
            WhseRequest."Source Document"::"Purchase Return Order":
                begin
                    PurchHeader.Get(PurchHeader."Document Type"::"Return Order", WhseRequest."Source No.");
                    PostingDate := PurchHeader."Posting Date";
                    VendorDocNo := PurchHeader."Vendor Cr. Memo No.";
                end;
            WhseRequest."Source Document"::"Sales Order":
                begin
                    SalesHeader.Get(SalesHeader."Document Type"::Order, WhseRequest."Source No.");
                    PostingDate := SalesHeader."Posting Date";
                end;
            WhseRequest."Source Document"::"Sales Return Order":
                begin
                    SalesHeader.Get(SalesHeader."Document Type"::"Return Order", WhseRequest."Source No.");
                    PostingDate := SalesHeader."Posting Date";
                end;
            WhseRequest."Source Document"::"Inbound Transfer":
                begin
                    TransferHeader.Get(WhseRequest."Source No.");
                    PostingDate := TransferHeader."Posting Date";
                end;
            WhseRequest."Source Document"::"Prod. Output":
                begin
                    ProdOrder.Get(ProdOrder.Status::Released, WhseRequest."Source No.");
                    PostingDate := WorkDate;
                end;
            WhseRequest."Source Document"::"Prod. Consumption":
                begin
                    ProdOrder.Get(WhseRequest."Source Subtype", WhseRequest."Source No.");
                    PostingDate := WorkDate;
                end;
            else
                OnGetSourceDocHeaderForWhseRequest(WhseRequest, SourceDocRecRef, PostingDate, VendorDocNo);
        end;
    end;

    local procedure UpdateWhseActivHeader(WhseRequest: Record "Warehouse Request")
    begin
        with WhseRequest do begin
            if WhseActivHeader."Source Document" = 0 then begin
                WhseActivHeader."Source Document" := "Source Document";
                WhseActivHeader."Source Type" := "Source Type";
                WhseActivHeader."Source Subtype" := "Source Subtype";
            end else
                WhseActivHeader.TestField("Source Document", "Source Document");
            if WhseActivHeader."Source No." = '' then begin
                WhseActivHeader."Source No." := "Source No.";
            end else
                WhseActivHeader.TestField("Source No.", "Source No.");

            WhseActivHeader."Destination Type" := "Destination Type";
            WhseActivHeader."Destination No." := "Destination No.";
            WhseActivHeader."External Document No." := "External Document No.";
            WhseActivHeader."Expected Receipt Date" := "Expected Receipt Date";
            WhseActivHeader."Posting Date" := PostingDate;
            WhseActivHeader."External Document No.2" := VendorDocNo;
            GetLocation("Location Code");
        end;

        OnAfterUpdateWhseActivHeader(WhseActivHeader, WhseRequest);
    end;

    local procedure CreatePutAwayLinesFromPurchase(PurchHeader: Record "Purchase Header")
    var
        PurchLine: Record "Purchase Line";
        NewWhseActivLine: Record "Warehouse Activity Line";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        IsHandled: Boolean;
    begin
        with PurchLine do begin
            if not SetFilterPurchLine(PurchLine, PurchHeader) then begin
                if not HideDialog then
                    Message(Text000);
                exit;
            end;

            FindNextLineNo;

            repeat
                IsHandled := false;
                OnBeforeCreatePutAwayLinesFromPurchaseLoop(WhseActivHeader, PurchHeader, IsHandled, PurchLine);
                if not IsHandled then
                    if not NewWhseActivLine.ActivityExists(DATABASE::"Purchase Line", "Document Type", "Document No.", "Line No.", 0, 0) then begin
                        if "Document Type" = "Document Type"::Order then
                            RemQtyToPutAway := "Qty. to Receive"
                        else
                            RemQtyToPutAway := -"Return Qty. to Ship";

                        ItemTrackingMgt.CheckWhseItemTrkgSetup("No.", SNRequired, LNRequired, false);
                        if SNRequired or LNRequired then
                            ReservationFound :=
                              FindReservationEntry(DATABASE::"Purchase Line", "Document Type", "Document No.", "Line No.", SNRequired, LNRequired);

                        repeat
                            NewWhseActivLine.Init();
                            NewWhseActivLine."Activity Type" := WhseActivHeader.Type;
                            NewWhseActivLine."No." := WhseActivHeader."No.";
                            NewWhseActivLine."Line No." := NextLineNo;
                            NewWhseActivLine.SetSource(DATABASE::"Purchase Line", "Document Type", "Document No.", "Line No.", 0);
                            NewWhseActivLine."Location Code" := "Location Code";
                            if "Bin Code" = '' then
                                NewWhseActivLine."Bin Code" := GetDefaultBinCode("No.", "Variant Code", "Location Code")
                            else
                                NewWhseActivLine."Bin Code" := "Bin Code";
                            if not Location."Bin Mandatory" then
                                NewWhseActivLine."Shelf No." := GetShelfNo("No.");
                            NewWhseActivLine."Item No." := "No.";
                            NewWhseActivLine."Variant Code" := "Variant Code";
                            NewWhseActivLine."Unit of Measure Code" := "Unit of Measure Code";
                            NewWhseActivLine."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
                            NewWhseActivLine.Description := Description;
                            NewWhseActivLine."Description 2" := "Description 2";
                            NewWhseActivLine."Due Date" := "Expected Receipt Date";
                            if "Document Type" = "Document Type"::Order then
                                NewWhseActivLine."Source Document" := NewWhseActivLine."Source Document"::"Purchase Order"
                            else
                                NewWhseActivLine."Source Document" := NewWhseActivLine."Source Document"::"Purchase Return Order";
                            OnBeforeNewWhseActivLineInsertFromPurchase(NewWhseActivLine, PurchLine);
                            if not ReservationFound and SNRequired then
                                repeat
                                    NewWhseActivLine."Line No." := NextLineNo;
                                    InsertWhseActivLine(NewWhseActivLine, 1);
                                until RemQtyToPutAway <= 0
                            else
                                InsertWhseActivLine(NewWhseActivLine, RemQtyToPutAway);
                        until RemQtyToPutAway <= 0;
                    end;
            until Next = 0;
        end;
    end;

    procedure SetFilterPurchLine(var PurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header"): Boolean
    begin
        with PurchLine do begin
            SetCurrentKey("Document Type", "Document No.", "Location Code");
            SetRange("Document Type", PurchHeader."Document Type");
            SetRange("Document No.", PurchHeader."No.");
            SetRange("Drop Shipment", false);
            if not CheckLineExist then
                SetRange("Location Code", WhseActivHeader."Location Code");
            SetRange(Type, Type::Item);
            if PurchHeader."Document Type" = PurchHeader."Document Type"::Order then
                SetFilter("Qty. to Receive", '>%1', 0)
            else
                SetFilter("Return Qty. to Ship", '<%1', 0);
            OnBeforeFindPurchLine(PurchLine, WhseActivHeader);
            exit(Find('-'));
        end;
    end;

    local procedure CreatePutAwayLinesFromSales(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        NewWhseActivLine: Record "Warehouse Activity Line";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        IsHandled: Boolean;
    begin
        with SalesLine do begin
            if not SetFilterSalesLine(SalesLine, SalesHeader) then begin
                if not HideDialog then
                    Message(Text000);
                exit;
            end;

            FindNextLineNo;

            repeat
                IsHandled := false;
                OnBeforeCreatePutAwayLinesFromSalesLoop(WhseActivHeader, SalesHeader, IsHandled, SalesLine);
                if not IsHandled then
                    if not NewWhseActivLine.ActivityExists(DATABASE::"Sales Line", "Document Type", "Document No.", "Line No.", 0, 0) then begin
                        if "Document Type" = "Document Type"::Order then
                            RemQtyToPutAway := -"Qty. to Ship"
                        else
                            RemQtyToPutAway := "Return Qty. to Receive";

                        ItemTrackingMgt.CheckWhseItemTrkgSetup("No.", SNRequired, LNRequired, false);
                        if SNRequired or LNRequired then
                            ReservationFound :=
                              FindReservationEntry(DATABASE::"Sales Line", "Document Type", "Document No.", "Line No.", SNRequired, LNRequired);

                        repeat
                            NewWhseActivLine.Init();
                            NewWhseActivLine."Activity Type" := WhseActivHeader.Type;
                            NewWhseActivLine."No." := WhseActivHeader."No.";
                            NewWhseActivLine."Line No." := NextLineNo;
                            NewWhseActivLine.SetSource(DATABASE::"Sales Line", "Document Type", "Document No.", "Line No.", 0);
                            NewWhseActivLine."Location Code" := "Location Code";
                            if "Bin Code" = '' then
                                NewWhseActivLine."Bin Code" := GetDefaultBinCode("No.", "Variant Code", "Location Code")
                            else
                                NewWhseActivLine."Bin Code" := "Bin Code";
                            if not Location."Bin Mandatory" then
                                NewWhseActivLine."Shelf No." := GetShelfNo("No.");
                            NewWhseActivLine."Item No." := "No.";
                            NewWhseActivLine."Variant Code" := "Variant Code";
                            NewWhseActivLine."Unit of Measure Code" := "Unit of Measure Code";
                            NewWhseActivLine."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
                            NewWhseActivLine.Description := Description;
                            NewWhseActivLine."Description 2" := "Description 2";
                            NewWhseActivLine."Due Date" := "Planned Shipment Date";
                            if "Document Type" = "Document Type"::Order then
                                NewWhseActivLine."Source Document" := NewWhseActivLine."Source Document"::"Sales Order"
                            else
                                NewWhseActivLine."Source Document" := NewWhseActivLine."Source Document"::"Sales Return Order";
                            OnBeforeNewWhseActivLineInsertFromSales(NewWhseActivLine, SalesLine);
                            if not ReservationFound and SNRequired then
                                repeat
                                    NewWhseActivLine."Line No." := NextLineNo;
                                    InsertWhseActivLine(NewWhseActivLine, 1);
                                until RemQtyToPutAway <= 0
                            else
                                InsertWhseActivLine(NewWhseActivLine, RemQtyToPutAway);
                        until RemQtyToPutAway <= 0;
                    end;
            until Next = 0;
        end;
    end;

    procedure SetFilterSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"): Boolean
    begin
        with SalesLine do begin
            SetCurrentKey("Document Type", "Document No.", "Location Code");
            SetRange("Document Type", SalesHeader."Document Type");
            SetRange("Document No.", SalesHeader."No.");
            SetRange("Drop Shipment", false);
            if not CheckLineExist then
                SetRange("Location Code", WhseActivHeader."Location Code");
            SetRange(Type, Type::Item);
            if SalesHeader."Document Type" = SalesHeader."Document Type"::Order then
                SetFilter("Qty. to Ship", '<%1', 0)
            else
                SetFilter("Return Qty. to Receive", '>%1', 0);
            OnBeforeFindSalesLine(SalesLine, WhseActivHeader);
            exit(Find('-'));
        end;
    end;

    local procedure CreatePutAwayLinesFromTransfer(TransferHeader: Record "Transfer Header")
    var
        TransferLine: Record "Transfer Line";
        NewWhseActivLine: Record "Warehouse Activity Line";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        IsHandled: Boolean;
    begin
        with TransferLine do begin
            if not SetFilterTransferLine(TransferLine, TransferHeader) then begin
                if not HideDialog then
                    Message(Text000);
                exit;
            end;

            FindNextLineNo;

            repeat
                IsHandled := false;
                OnBeforeCreatePutAwayLinesFromTransferLoop(WhseActivHeader, TransferHeader, IsHandled, TransferLine);
                if not IsHandled then
                    if not NewWhseActivLine.ActivityExists(DATABASE::"Transfer Line", 1, "Document No.", "Line No.", 0, 0) then begin
                        RemQtyToPutAway := "Qty. to Receive";

                        ItemTrackingMgt.CheckWhseItemTrkgSetup("Item No.", SNRequired, LNRequired, false);
                        if SNRequired or LNRequired then
                            ReservationFound :=
                              FindReservationEntry(DATABASE::"Transfer Line", 1, "Document No.", "Line No.", SNRequired, LNRequired);

                        repeat
                            NewWhseActivLine.Init();
                            NewWhseActivLine."Activity Type" := WhseActivHeader.Type;
                            NewWhseActivLine."No." := WhseActivHeader."No.";
                            NewWhseActivLine."Line No." := NextLineNo;
                            NewWhseActivLine.SetSource(DATABASE::"Transfer Line", 1, "Document No.", "Line No.", 0);
                            NewWhseActivLine."Source Document" := NewWhseActivLine."Source Document"::"Inbound Transfer";
                            NewWhseActivLine."Location Code" := "Transfer-to Code";
                            if "Transfer-To Bin Code" = '' then
                                NewWhseActivLine."Bin Code" := GetDefaultBinCode("Item No.", "Variant Code", "Transfer-to Code")
                            else
                                NewWhseActivLine."Bin Code" := "Transfer-To Bin Code";
                            if not Location."Bin Mandatory" then
                                NewWhseActivLine."Shelf No." := GetShelfNo("Item No.");
                            NewWhseActivLine."Item No." := "Item No.";
                            NewWhseActivLine."Variant Code" := "Variant Code";
                            NewWhseActivLine."Unit of Measure Code" := "Unit of Measure Code";
                            NewWhseActivLine."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
                            NewWhseActivLine.Description := Description;
                            NewWhseActivLine."Description 2" := "Description 2";
                            NewWhseActivLine."Due Date" := "Receipt Date";
                            OnBeforeNewWhseActivLineInsertFromTransfer(NewWhseActivLine, TransferLine);
                            if not ReservationFound and SNRequired then
                                repeat
                                    NewWhseActivLine."Line No." := NextLineNo;
                                    InsertWhseActivLine(NewWhseActivLine, 1);
                                until RemQtyToPutAway <= 0
                            else
                                InsertWhseActivLine(NewWhseActivLine, RemQtyToPutAway);
                        until RemQtyToPutAway <= 0;
                    end;
            until Next = 0;
        end;
    end;

    procedure SetFilterTransferLine(var TransferLine: Record "Transfer Line"; TransferHeader: Record "Transfer Header"): Boolean
    begin
        with TransferLine do begin
            SetRange("Document No.", TransferHeader."No.");
            SetRange("Derived From Line No.", 0);
            if not CheckLineExist then
                SetRange("Transfer-to Code", WhseActivHeader."Location Code");
            SetFilter("Qty. to Receive", '>%1', 0);
            OnBeforeFindTransLine(TransferLine, WhseActivHeader);
            exit(Find('-'));
        end;
    end;

    local procedure CreatePutAwayLinesFromProd(ProdOrder: Record "Production Order")
    var
        ProdOrderLine: Record "Prod. Order Line";
        NewWhseActivLine: Record "Warehouse Activity Line";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        IsHandled: Boolean;
    begin
        with ProdOrderLine do begin
            if not SetFilterProdOrderLine(ProdOrderLine, ProdOrder) then begin
                if not HideDialog then
                    Message(Text000);
                exit;
            end;

            FindNextLineNo;

            repeat
                IsHandled := false;
                OnBeforeCreatePutAwayLinesFromProdLoop(WhseActivHeader, ProdOrder, IsHandled, ProdOrderLine);
                if not IsHandled then
                    if not NewWhseActivLine.ActivityExists(DATABASE::"Prod. Order Line", Status, "Prod. Order No.", "Line No.", 0, 0) then begin
                        RemQtyToPutAway := "Remaining Quantity";

                        ItemTrackingMgt.CheckWhseItemTrkgSetup("Item No.", SNRequired, LNRequired, false);
                        if SNRequired or LNRequired then
                            ReservationFound :=
                              FindReservationEntry(DATABASE::"Prod. Order Line", Status, "Prod. Order No.", "Line No.", SNRequired, LNRequired);

                        repeat
                            NewWhseActivLine.Init();
                            NewWhseActivLine."Activity Type" := WhseActivHeader.Type;
                            NewWhseActivLine."No." := WhseActivHeader."No.";
                            NewWhseActivLine."Line No." := NextLineNo;
                            NewWhseActivLine.SetSource(DATABASE::"Prod. Order Line", Status, "Prod. Order No.", "Line No.", 0);
                            NewWhseActivLine."Location Code" := "Location Code";
                            if "Bin Code" = '' then
                                NewWhseActivLine."Bin Code" := GetDefaultBinCode("Item No.", "Variant Code", "Location Code")
                            else
                                NewWhseActivLine."Bin Code" := "Bin Code";
                            if not Location."Bin Mandatory" then
                                NewWhseActivLine."Shelf No." := GetShelfNo("Item No.");
                            NewWhseActivLine."Item No." := "Item No.";
                            NewWhseActivLine."Variant Code" := "Variant Code";
                            NewWhseActivLine."Unit of Measure Code" := "Unit of Measure Code";
                            NewWhseActivLine."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
                            NewWhseActivLine.Description := Description;
                            NewWhseActivLine."Description 2" := "Description 2";
                            NewWhseActivLine."Due Date" := "Due Date";
                            NewWhseActivLine."Source Document" := NewWhseActivLine."Source Document"::"Prod. Output";
                            OnBeforeNewWhseActivLineInsertFromProd(NewWhseActivLine, ProdOrderLine);
                            if not ReservationFound and SNRequired then
                                repeat
                                    NewWhseActivLine."Line No." := NextLineNo;
                                    InsertWhseActivLine(NewWhseActivLine, 1);
                                until RemQtyToPutAway <= 0
                            else
                                InsertWhseActivLine(NewWhseActivLine, RemQtyToPutAway);
                        until RemQtyToPutAway <= 0;
                    end;
            until Next = 0;
        end;
    end;

    procedure SetFilterProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProdOrder: Record "Production Order"): Boolean
    begin
        with ProdOrderLine do begin
            SetRange(Status, ProdOrder.Status);
            SetRange("Prod. Order No.", ProdOrder."No.");
            if not CheckLineExist then
                SetRange("Location Code", WhseActivHeader."Location Code");
            SetFilter("Remaining Quantity", '>%1', 0);
            OnBeforeFindProdOrderLine(ProdOrderLine, WhseActivHeader);
            exit(Find('-'));
        end;
    end;

    local procedure CreatePutAwayLinesFromComp(ProdOrder: Record "Production Order")
    var
        ProdOrderComp: Record "Prod. Order Component";
        NewWhseActivLine: Record "Warehouse Activity Line";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        IsHandled: Boolean;
    begin
        with ProdOrderComp do begin
            if not SetFilterProdCompLine(ProdOrderComp, ProdOrder) then begin
                if not HideDialog then
                    Message(Text000);
                exit;
            end;

            FindNextLineNo;

            repeat
                IsHandled := false;
                OnBeforeCreatePutAwayLinesFromCompLoop(WhseActivHeader, ProdOrder, IsHandled, ProdOrderComp);
                if not IsHandled then
                    if not
                       NewWhseActivLine.ActivityExists(
                         DATABASE::"Prod. Order Component", Status, "Prod. Order No.", "Prod. Order Line No.", "Line No.", 0)
                    then begin
                        RemQtyToPutAway := -"Remaining Quantity";

                        ItemTrackingMgt.CheckWhseItemTrkgSetup("Item No.", SNRequired, LNRequired, false);
                        if SNRequired or LNRequired then
                            ReservationFound :=
                              FindReservationEntry(DATABASE::"Prod. Order Component", Status, "Prod. Order No.", "Line No.", SNRequired, LNRequired);

                        repeat
                            NewWhseActivLine.Init();
                            NewWhseActivLine."Activity Type" := WhseActivHeader.Type;
                            NewWhseActivLine."No." := WhseActivHeader."No.";
                            NewWhseActivLine.SetSource(
                              DATABASE::"Prod. Order Component", Status, "Prod. Order No.", "Prod. Order Line No.", "Line No.");
                            NewWhseActivLine."Location Code" := "Location Code";
                            NewWhseActivLine."Item No." := "Item No.";
                            NewWhseActivLine."Variant Code" := "Variant Code";
                            if "Bin Code" = '' then
                                NewWhseActivLine."Bin Code" := GetDefaultBinCode("Item No.", "Variant Code", "Location Code")
                            else
                                NewWhseActivLine."Bin Code" := "Bin Code";
                            if not Location."Bin Mandatory" then
                                NewWhseActivLine."Shelf No." := GetShelfNo("Item No.");
                            NewWhseActivLine."Unit of Measure Code" := "Unit of Measure Code";
                            NewWhseActivLine."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
                            NewWhseActivLine.Description := Description;
                            NewWhseActivLine."Due Date" := "Due Date";
                            NewWhseActivLine."Source Document" := NewWhseActivLine."Source Document"::"Prod. Consumption";
                            OnBeforeNewWhseActivLineInsertFromComp(NewWhseActivLine, ProdOrderComp);
                            if not ReservationFound and SNRequired then
                                repeat
                                    NewWhseActivLine."Line No." := NextLineNo;
                                    InsertWhseActivLine(NewWhseActivLine, 1);
                                until RemQtyToPutAway <= 0
                            else
                                InsertWhseActivLine(NewWhseActivLine, RemQtyToPutAway);
                        until RemQtyToPutAway <= 0;
                    end;
            until Next = 0;
        end;
    end;

    local procedure SetFilterProdCompLine(var ProdOrderComp: Record "Prod. Order Component"; ProdOrder: Record "Production Order"): Boolean
    begin
        with ProdOrderComp do begin
            SetRange(Status, ProdOrder.Status);
            SetRange("Prod. Order No.", ProdOrder."No.");
            if not CheckLineExist then
                SetRange("Location Code", WhseActivHeader."Location Code");
            SetRange("Flushing Method", "Flushing Method"::Manual);
            SetRange("Planning Level Code", 0);
            SetFilter("Remaining Quantity", '<0');
            OnBeforeFindProdOrderComp(ProdOrderComp, WhseActivHeader);
            exit(Find('-'));
        end;
    end;

    local procedure FindNextLineNo()
    var
        WhseActivLine: Record "Warehouse Activity Line";
    begin
        with WhseActivHeader do begin
            WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::"Invt. Put-away");
            WhseActivLine.SetRange("No.", "No.");
            if WhseActivLine.FindLast then
                NextLineNo := WhseActivLine."Line No." + 10000
            else
                NextLineNo := 10000;
        end;
    end;

    local procedure FindReservationEntry(SourceType: Integer; DocType: Integer; DocNo: Code[20]; DocLineNo: Integer; SNRequired: Boolean; LNRequired: Boolean): Boolean
    var
        ReservEntry: Record "Reservation Entry";
        ItemTrackMgt: Codeunit "Item Tracking Management";
    begin
        with ReservEntry do begin
            if SourceType in [DATABASE::"Prod. Order Line", DATABASE::"Transfer Line"] then begin
                SetSourceFilter(SourceType, DocType, DocNo, -1, true);
                SetRange("Source Prod. Order Line", DocLineNo)
            end else
                SetSourceFilter(SourceType, DocType, DocNo, DocLineNo, true);
            if SNRequired then
                SetFilter("Serial No.", '<>%1', '');
            if LNRequired then
                SetFilter("Lot No.", '<>%1', '');
            if FindFirst then
                if ItemTrackMgt.SumUpItemTracking(ReservEntry, TempTrackingSpecification, true, true) then
                    exit(true);
        end;
    end;

    local procedure InsertWhseActivLine(var NewWhseActivLine: Record "Warehouse Activity Line"; PutAwayQty: Decimal)
    begin
        with NewWhseActivLine do begin
            if Location."Bin Mandatory" then
                "Action Type" := "Action Type"::Place;

            "Serial No." := '';
            "Expiration Date" := 0D;
            if ReservationFound then begin
                CopyTrackingFromSpec(TempTrackingSpecification);
                Validate(Quantity, CalcQty(TempTrackingSpecification."Qty. to Handle (Base)"));
                ReservationFound := false;
            end else
                if (SNRequired or LNRequired) and (TempTrackingSpecification.Next <> 0) then begin
                    CopyTrackingFromSpec(TempTrackingSpecification);
                    Validate(Quantity, CalcQty(TempTrackingSpecification."Qty. to Handle (Base)"));
                end else
                    Validate(Quantity, PutAwayQty);
            Validate("Qty. to Handle", 0);
            OnInsertWhseActivLineOnBeforeAutoCreation(NewWhseActivLine, TempTrackingSpecification, ReservationFound, SNRequired, LNRequired);
        end;

        if AutoCreation and not LineCreated then begin
            WhseActivHeader."No." := '';
            WhseActivHeader.Insert(true);
            UpdateWhseActivHeader(WhseRequest);
            NextLineNo := 10000;
            Commit();
        end;
        NewWhseActivLine."No." := WhseActivHeader."No.";
        NewWhseActivLine."Line No." := NextLineNo;
        OnBeforeInsertWhseActivLine(NewWhseActivLine);
        NewWhseActivLine.Insert();
        OnAfterInsertWhseActivLine(NewWhseActivLine, SNRequired, LNRequired);

        LineCreated := true;
        NextLineNo := NextLineNo + 10000;
        RemQtyToPutAway -= NewWhseActivLine.Quantity;
    end;

    local procedure GetDefaultBinCode(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]): Code[20]
    var
        WMSMgt: Codeunit "WMS Management";
        BinCode: Code[20];
    begin
        GetLocation(LocationCode);
        if Location."Bin Mandatory" then
            if WMSMgt.GetDefaultBin(ItemNo, VariantCode, LocationCode, BinCode) then
                exit(BinCode);
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if LocationCode <> Location.Code then
                Location.Get(LocationCode);
    end;

    local procedure GetShelfNo(ItemNo: Code[20]): Code[10]
    begin
        GetItem(ItemNo);
        exit(Item."Shelf No.");
    end;

    local procedure GetItem(ItemNo: Code[20])
    begin
        if ItemNo <> Item."No." then
            Item.Get(ItemNo);
    end;

    procedure SetWhseRequest(NewWhseRequest: Record "Warehouse Request"; SetHideDialog: Boolean)
    begin
        WhseRequest := NewWhseRequest;
        HideDialog := SetHideDialog;
        LineCreated := false;
    end;

    procedure CheckSourceDoc(NewWhseRequest: Record "Warehouse Request"): Boolean
    var
        PurchLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        TransferLine: Record "Transfer Line";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComp: Record "Prod. Order Component";
        IsFound: Boolean;
        IsHandled: Boolean;
    begin
        WhseRequest := NewWhseRequest;
        if Location.RequireReceive(WhseRequest."Location Code") and
           (WhseRequest."Source Document" <> WhseRequest."Source Document"::"Prod. Output")
        then
            exit(false);

        IsHandled := false;
        IsFound := false;
        OnBeforeCheckSourceDoc(NewWhseRequest, IsFound, IsHandled);
        if IsHandled then
            exit(IsFound);

        GetSourceDocHeader;
        CheckLineExist := true;
        case WhseRequest."Source Document" of
            WhseRequest."Source Document"::"Purchase Order":
                exit(SetFilterPurchLine(PurchLine, PurchHeader));
            WhseRequest."Source Document"::"Purchase Return Order":
                exit(SetFilterPurchLine(PurchLine, PurchHeader));
            WhseRequest."Source Document"::"Sales Order":
                exit(SetFilterSalesLine(SalesLine, SalesHeader));
            WhseRequest."Source Document"::"Sales Return Order":
                exit(SetFilterSalesLine(SalesLine, SalesHeader));
            WhseRequest."Source Document"::"Inbound Transfer":
                exit(SetFilterTransferLine(TransferLine, TransferHeader));
            WhseRequest."Source Document"::"Prod. Output":
                exit(SetFilterProdOrderLine(ProdOrderLine, ProdOrder));
            WhseRequest."Source Document"::"Prod. Consumption":
                exit(SetFilterProdCompLine(ProdOrderComp, ProdOrder));
            else
                OnCheckSourceDocForWhseRequest(WhseRequest, SourceDocRecRef);
        end;
    end;

    procedure AutoCreatePutAway(var WhseActivHeaderNew: Record "Warehouse Activity Header")
    var
        IsHandled: Boolean;
    begin
        WhseActivHeader := WhseActivHeaderNew;
        CheckLineExist := false;
        AutoCreation := true;
        GetLocation(WhseRequest."Location Code");

        IsHandled := false;
        OnBeforeAutoCreatePutAwayLines(WhseRequest, WhseActivHeader, LineCreated, IsHandled);
        if IsHandled then
            exit;

        case WhseRequest."Source Document" of
            WhseRequest."Source Document"::"Purchase Order":
                CreatePutAwayLinesFromPurchase(PurchHeader);
            WhseRequest."Source Document"::"Purchase Return Order":
                CreatePutAwayLinesFromPurchase(PurchHeader);
            WhseRequest."Source Document"::"Sales Order":
                CreatePutAwayLinesFromSales(SalesHeader);
            WhseRequest."Source Document"::"Sales Return Order":
                CreatePutAwayLinesFromSales(SalesHeader);
            WhseRequest."Source Document"::"Inbound Transfer":
                CreatePutAwayLinesFromTransfer(TransferHeader);
            WhseRequest."Source Document"::"Prod. Output":
                CreatePutAwayLinesFromProd(ProdOrder);
            WhseRequest."Source Document"::"Prod. Consumption":
                CreatePutAwayLinesFromComp(ProdOrder);
            else
                OnAutoCreatePutAwayLinesFromWhseRequest(WhseRequest, SourceDocRecRef, LineCreated);
        end;
        if LineCreated then begin
            WhseActivHeader.Modify();
            WhseActivHeaderNew := WhseActivHeader;
        end;

        OnAfterAutoCreatePutAway(WhseRequest, LineCreated, WhseActivHeaderNew);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAutoCreatePutAway(var WarehouseRequest: Record "Warehouse Request"; LineCreated: Boolean; var WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateInventoryPutaway(var WarehouseRequest: Record "Warehouse Request"; LineCreated: Boolean; var WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertWhseActivLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SNRequired: Boolean; LNRequired: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateWhseActivHeader(var WarehouseActivityHeader: Record "Warehouse Activity Header"; var WarehouseRequest: Record "Warehouse Request")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoCreatePutAwayLines(WarehouseRequest: Record "Warehouse Request"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var LineCreated: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNewWhseActivLineInsertFromPurchase(var WarehouseActivityLine: Record "Warehouse Activity Line"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNewWhseActivLineInsertFromSales(var WarehouseActivityLine: Record "Warehouse Activity Line"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNewWhseActivLineInsertFromTransfer(var WarehouseActivityLine: Record "Warehouse Activity Line"; TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNewWhseActivLineInsertFromProd(var WarehouseActivityLine: Record "Warehouse Activity Line"; ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNewWhseActivLineInsertFromComp(var WarehouseActivityLine: Record "Warehouse Activity Line"; ProdOrderComp: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindPurchLine(var PurchaseLine: Record "Purchase Line"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindSalesLine(var SalesLine: Record "Sales Line"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindTransLine(var TransferLine: Record "Transfer Line"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindProdOrderComp(var ProdOrderComp: Record "Prod. Order Component"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSourceDocHeader(var WarehouseRequest: Record "Warehouse Request"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertWhseActivLine(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSourceDoc(WarehouseRequest: Record "Warehouse Request"; var IsFound: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePutAwayLines(WarehouseRequest: Record "Warehouse Request"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var LineCreated: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePutAwayLinesFromCompLoop(var WarehouseActivityHeader: Record "Warehouse Activity Header"; ProductionOrder: Record "Production Order"; var IsHandled: Boolean; ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePutAwayLinesFromProdLoop(var WarehouseActivityHeader: Record "Warehouse Activity Header"; ProductionOrder: Record "Production Order"; var IsHandled: Boolean; ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePutAwayLinesFromPurchaseLoop(var WarehouseActivityHeader: Record "Warehouse Activity Header"; PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePutAwayLinesFromSalesLoop(var WarehouseActivityHeader: Record "Warehouse Activity Header"; SalesHeader: Record "Sales Header"; var IsHandled: Boolean; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePutAwayLinesFromTransferLoop(var WarehouseActivityHeader: Record "Warehouse Activity Header"; TransferHeader: Record "Transfer Header"; var IsHandled: Boolean; TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAutoCreatePutAwayLinesFromWhseRequest(var WarehouseRequest: Record "Warehouse Request"; SourceDocRecRef: RecordRef; var LineCreated: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckSourceDocForWhseRequest(var WarehouseRequest: Record "Warehouse Request"; SourceDocRecRef: RecordRef);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePutAwayFromWhseRequest(var WarehouseRequest: Record "Warehouse Request"; SourceDocRecRef: RecordRef; var LineCreated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSourceDocHeaderForWhseRequest(var WarehouseRequest: Record "Warehouse Request"; var SourceDocRecRef: RecordRef; var PostingDate: Date; var VendorDocNo: Code[35]);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertWhseActivLineOnBeforeAutoCreation(var WarehouseActivityLine: Record "Warehouse Activity Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; ReservationFound: Boolean; SNRequired: Boolean; LNRequired: Boolean)
    begin
    end;
}

