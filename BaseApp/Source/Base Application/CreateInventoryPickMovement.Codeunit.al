codeunit 7322 "Create Inventory Pick/Movement"
{
    Permissions = TableData "Whse. Item Tracking Line" = rimd;
    TableNo = "Warehouse Activity Header";

    trigger OnRun()
    begin
        WhseActivHeader := Rec;
        Code;
        Rec := WhseActivHeader;
    end;

    var
        WhseRequest: Record "Warehouse Request";
        WhseActivHeader: Record "Warehouse Activity Header";
        Text000: Label 'There is nothing to handle.';
        TempHandlingSpecification: Record "Tracking Specification" temporary;
        TempInternalMovementLine: Record "Internal Movement Line" temporary;
        Location: Record Location;
        Item: Record Item;
        TempReservEntry: Record "Reservation Entry" temporary;
        PurchHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        TransferHeader: Record "Transfer Header";
        ProdHeader: Record "Production Order";
        AssemblyHeader: Record "Assembly Header";
        WMSMgt: Codeunit "WMS Management";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        SourceDocRecRef: RecordRef;
        PostingDate: Date;
        VendorDocNo: Code[35];
        NextLineNo: Integer;
        LastTempHandlingSpecNo: Integer;
        HideDialog: Boolean;
        Text001: Label 'Quantity available to pick is not sufficient to fulfill shipping advise %1 for sales line with Document Type %2, Document No. %3, Line No. %4.';
        CheckLineExist: Boolean;
        AutoCreation: Boolean;
        LineCreated: Boolean;
        CompleteShipment: Boolean;
        PrintDocument: Boolean;
        ShowError: Boolean;
        Text002: Label 'Quantity available to pick is not sufficient to fulfill shipping advise %1 for transfer line with Document No. %2, Line No. %3.';
        IsInvtMovement: Boolean;
        IsBlankInvtMovement: Boolean;
        ActivityCreatedMsg: Label '%1 activity number %2 has been created.', Comment = '%1=Warehouse Activity Type,%2=Warehouse Activity number';
        TrackingNotFullyAppliedMsg: Label '%1 activity number %2 has been created.\\Item tracking lines cannot be fully applied.', Comment = '%1=Warehouse Activity Type,%2=Warehouse Activity No.';
        Text004: Label 'Do you want to create Inventory Movement?';
        FromBinCode: Code[20];
        HasExpiredItems: Boolean;
        ExpiredItemMessageText: Text[100];
        ATOInvtMovementsCreated: Integer;
        TotalATOInvtMovementsToBeCreated: Integer;

    local procedure "Code"()
    var
        IsHandled: Boolean;
    begin
        WhseActivHeader.TestField("No.");
        WhseActivHeader.TestField("Location Code");

        if not HideDialog then
            if not GetWhseRequest(WhseRequest) then
                exit;

        IsHandled := false;
        OnBeforeCreatePickOrMoveLines(WhseRequest, WhseActivHeader, LineCreated, IsHandled);
        if IsHandled then
            exit;

        GetSourceDocHeader();
        UpdateWhseActivHeader(WhseRequest);

        case WhseRequest."Source Document" of
            WhseRequest."Source Document"::"Purchase Order":
                CreatePickOrMoveFromPurchase(PurchHeader);
            WhseRequest."Source Document"::"Purchase Return Order":
                CreatePickOrMoveFromPurchase(PurchHeader);
            WhseRequest."Source Document"::"Sales Order":
                CreatePickOrMoveFromSales(SalesHeader);
            WhseRequest."Source Document"::"Sales Return Order":
                CreatePickOrMoveFromSales(SalesHeader);
            WhseRequest."Source Document"::"Outbound Transfer":
                CreatePickOrMoveFromTransfer(TransferHeader);
            WhseRequest."Source Document"::"Prod. Consumption":
                CreatePickOrMoveFromProduction(ProdHeader);
            WhseRequest."Source Document"::"Assembly Consumption":
                CreatePickOrMoveFromAssembly(AssemblyHeader);
            else
                OnCreatePickOrMoveFromWhseRequest(
                    WhseRequest, SourceDocRecRef, LineCreated, WhseActivHeader, Location, HideDialog, CompleteShipment, CheckLineExist);
        end;

        if LineCreated then
            WhseActivHeader.Modify()
        else
            if not AutoCreation then
                Message(Text000 + ExpiredItemMessageText);

        OnAfterCreateInventoryPickMovement(WhseRequest, LineCreated, WhseActivHeader);
    end;

    local procedure GetWhseRequest(var WhseRequest: Record "Warehouse Request"): Boolean
    begin
        with WhseRequest do begin
            FilterGroup := 2;
            SetRange(Type, Type::Outbound);
            SetRange("Location Code", WhseActivHeader."Location Code");
            SetRange("Document Status", "Document Status"::Released);
            if WhseActivHeader."Source Document" <> 0 then
                SetRange("Source Document", WhseActivHeader."Source Document")
            else
                if WhseActivHeader.Type = WhseActivHeader.Type::"Invt. Movement" then
                    SetFilter("Source Document", '%1|%2|%3',
                      WhseActivHeader."Source Document"::"Prod. Consumption",
                      WhseActivHeader."Source Document"::"Prod. Output",
                      WhseActivHeader."Source Document"::"Assembly Consumption");
            if WhseActivHeader."Source No." <> '' then
                SetRange("Source No.", WhseActivHeader."Source No.");
            SetRange("Completely Handled", false);
            FilterGroup := 0;
            if PAGE.RunModal(PAGE::"Source Documents", WhseRequest, "Source No.") = ACTION::LookupOK then
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
            WhseRequest."Source Document"::"Outbound Transfer":
                begin
                    TransferHeader.Get(WhseRequest."Source No.");
                    PostingDate := TransferHeader."Posting Date";
                end;
            WhseRequest."Source Document"::"Prod. Consumption":
                begin
                    ProdHeader.Get(WhseRequest."Source Subtype", WhseRequest."Source No.");
                    PostingDate := WorkDate;
                end;
            WhseRequest."Source Document"::"Assembly Consumption":
                begin
                    AssemblyHeader.Get(WhseRequest."Source Subtype", WhseRequest."Source No.");
                    PostingDate := AssemblyHeader."Posting Date";
                end;
            else
                OnGetSourceDocHeaderFromWhseRequest(WhseRequest, SourceDocRecRef, PostingDate, VendorDocNo);
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
            if WhseActivHeader."Source No." = '' then
                WhseActivHeader."Source No." := "Source No."
            else
                WhseActivHeader.TestField("Source No.", "Source No.");

            WhseActivHeader."Destination Type" := "Destination Type";
            WhseActivHeader."Destination No." := "Destination No.";
            WhseActivHeader."External Document No." := "External Document No.";
            WhseActivHeader."Shipment Date" := "Shipment Date";
            WhseActivHeader."Posting Date" := PostingDate;
            WhseActivHeader."External Document No.2" := VendorDocNo;
            GetLocation("Location Code");
        end;

        OnAfterUpdateWhseActivHeader(WhseActivHeader, WhseRequest);
    end;

    local procedure CreatePickOrMoveFromPurchase(PurchHeader: Record "Purchase Header")
    var
        PurchLine: Record "Purchase Line";
        NewWhseActivLine: Record "Warehouse Activity Line";
        RemQtyToPickBase: Decimal;
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
                OnBeforeCreatePickOrMoveLineFromPurchaseLoop(WhseActivHeader, PurchHeader, IsHandled, PurchLine);
                if not IsHandled then
                    if not NewWhseActivLine.ActivityExists(DATABASE::"Purchase Line", "Document Type", "Document No.", "Line No.", 0, 0) then begin
                        NewWhseActivLine.Init();
                        NewWhseActivLine."Activity Type" := WhseActivHeader.Type;
                        NewWhseActivLine."No." := WhseActivHeader."No.";
                        if Location."Bin Mandatory" then
                            NewWhseActivLine."Action Type" := NewWhseActivLine."Action Type"::Take;
                        NewWhseActivLine.SetSource(DATABASE::"Purchase Line", "Document Type", "Document No.", "Line No.", 0);
                        NewWhseActivLine."Location Code" := "Location Code";
                        NewWhseActivLine."Bin Code" := "Bin Code";
                        NewWhseActivLine."Item No." := "No.";
                        NewWhseActivLine."Variant Code" := "Variant Code";
                        NewWhseActivLine."Unit of Measure Code" := "Unit of Measure Code";
                        NewWhseActivLine."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
                        NewWhseActivLine.Description := Description;
                        NewWhseActivLine."Description 2" := "Description 2";
                        NewWhseActivLine."Due Date" := "Expected Receipt Date";
                        NewWhseActivLine."Destination Type" := NewWhseActivLine."Destination Type"::Vendor;
                        NewWhseActivLine."Destination No." := PurchHeader."Buy-from Vendor No.";
                        if "Document Type" = "Document Type"::Order then begin
                            NewWhseActivLine."Source Document" := NewWhseActivLine."Source Document"::"Purchase Order";
                            RemQtyToPickBase := -"Qty. to Receive (Base)";
                        end else begin
                            NewWhseActivLine."Source Document" :=
                              NewWhseActivLine."Source Document"::"Purchase Return Order";
                            RemQtyToPickBase := "Return Qty. to Ship (Base)";
                        end;
                        OnBeforeNewWhseActivLineInsertFromPurchase(NewWhseActivLine, PurchLine, WhseActivHeader, RemQtyToPickBase);
                        CalcFields("Reserved Quantity");
                        CreatePickOrMoveLine(
                          NewWhseActivLine, RemQtyToPickBase, "Outstanding Qty. (Base)", "Reserved Quantity" <> 0);
                    end;
            until Next = 0;
        end;
    end;

    local procedure SetFilterPurchLine(var PurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header"): Boolean
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
                SetFilter("Qty. to Receive", '<%1', 0)
            else
                SetFilter("Return Qty. to Ship", '>%1', 0);
            OnBeforeFindPurchLine(PurchLine, PurchHeader, WhseActivHeader);
            exit(Find('-'));
        end;
    end;

    local procedure CreatePickOrMoveFromSales(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        NewWhseActivLine: Record "Warehouse Activity Line";
        RemQtyToPickBase: Decimal;
        IsHandled: Boolean;
    begin
        with SalesLine do begin
            if not SetFilterSalesLine(SalesLine, SalesHeader) then begin
                if not HideDialog then
                    Message(Text000);
                exit;
            end;
            CompleteShipment := true;

            FindNextLineNo;

            repeat
                IsHandled := false;
                OnBeforeCreatePickOrMoveLineFromSalesLoop(WhseActivHeader, SalesHeader, IsHandled, SalesLine);
                if not IsHandled then
                    if not NewWhseActivLine.ActivityExists(DATABASE::"Sales Line", "Document Type", "Document No.", "Line No.", 0, 0) then begin
                        NewWhseActivLine.Init();
                        NewWhseActivLine."Activity Type" := WhseActivHeader.Type;
                        NewWhseActivLine."No." := WhseActivHeader."No.";
                        if Location."Bin Mandatory" then
                            NewWhseActivLine."Action Type" := NewWhseActivLine."Action Type"::Take;
                        NewWhseActivLine.SetSource(DATABASE::"Sales Line", "Document Type", "Document No.", "Line No.", 0);
                        NewWhseActivLine."Location Code" := "Location Code";
                        NewWhseActivLine."Bin Code" := "Bin Code";
                        NewWhseActivLine."Item No." := "No.";
                        NewWhseActivLine."Variant Code" := "Variant Code";
                        NewWhseActivLine."Unit of Measure Code" := "Unit of Measure Code";
                        NewWhseActivLine."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
                        NewWhseActivLine.Description := Description;
                        NewWhseActivLine."Description 2" := "Description 2";
                        NewWhseActivLine."Due Date" := "Planned Shipment Date";
                        NewWhseActivLine."Shipping Advice" := SalesHeader."Shipping Advice";
                        NewWhseActivLine."Shipping Agent Code" := "Shipping Agent Code";
                        NewWhseActivLine."Shipping Agent Service Code" := "Shipping Agent Service Code";
                        NewWhseActivLine."Shipment Method Code" := SalesHeader."Shipment Method Code";
                        NewWhseActivLine."Destination Type" := NewWhseActivLine."Destination Type"::Customer;
                        NewWhseActivLine."Destination No." := SalesHeader."Sell-to Customer No.";

                        if "Document Type" = "Document Type"::Order then begin
                            NewWhseActivLine."Source Document" := NewWhseActivLine."Source Document"::"Sales Order";
                            RemQtyToPickBase := "Qty. to Ship (Base)";
                        end else begin
                            NewWhseActivLine."Source Document" := NewWhseActivLine."Source Document"::"Sales Return Order";
                            RemQtyToPickBase := -"Return Qty. to Receive (Base)";
                        end;
                        OnBeforeNewWhseActivLineInsertFromSales(NewWhseActivLine, SalesLine, WhseActivHeader, RemQtyToPickBase);
                        CalcFields("Reserved Quantity");
                        CreatePickOrMoveLine(
                          NewWhseActivLine, RemQtyToPickBase, "Outstanding Qty. (Base)", "Reserved Quantity" <> 0);

                        if SalesHeader."Shipping Advice" = SalesHeader."Shipping Advice"::Complete then begin
                            if RemQtyToPickBase < 0 then begin
                                if AutoCreation then begin
                                    if WhseActivHeader.Delete(true) then
                                        LineCreated := false;
                                    exit;
                                end;
                                Error(Text001, SalesHeader."Shipping Advice", "Document Type", "Document No.", "Line No.");
                            end;
                            if (RemQtyToPickBase = 0) and not CompleteShipment then begin
                                if ShowError then
                                    Error(Text001, SalesHeader."Shipping Advice", "Document Type", "Document No.", "Line No.");
                                if WhseActivHeader.Delete(true) then;
                                LineCreated := false;
                                exit;
                            end;
                        end;
                    end;
            until Next = 0;
        end;
    end;

    local procedure SetFilterSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"): Boolean
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
                SetFilter("Qty. to Ship", '>%1', 0)
            else
                SetFilter("Return Qty. to Receive", '<%1', 0);
            OnBeforeFindSalesLine(SalesLine, SalesHeader, WhseActivHeader);
            exit(Find('-'));
        end;
    end;

    local procedure CreatePickOrMoveFromTransfer(TransferHeader: Record "Transfer Header")
    var
        TransferLine: Record "Transfer Line";
        NewWhseActivLine: Record "Warehouse Activity Line";
        RemQtyToPickBase: Decimal;
        IsHandled: Boolean;
    begin
        with TransferLine do begin
            if not SetFilterTransferLine(TransferLine, TransferHeader) then begin
                if not HideDialog then
                    Message(Text000);
                exit;
            end;
            CompleteShipment := true;

            FindNextLineNo;

            repeat
                IsHandled := false;
                OnBeforeCreatePickOrMoveLineFromTransferLoop(WhseActivHeader, TransferHeader, IsHandled, TransferLine);
                if not IsHandled then
                    if not NewWhseActivLine.ActivityExists(DATABASE::"Transfer Line", 0, "Document No.", "Line No.", 0, 0) then begin
                        NewWhseActivLine.Init();
                        NewWhseActivLine."Activity Type" := WhseActivHeader.Type;
                        NewWhseActivLine."No." := WhseActivHeader."No.";
                        if Location."Bin Mandatory" then
                            NewWhseActivLine."Action Type" := NewWhseActivLine."Action Type"::Take;
                        NewWhseActivLine.SetSource(DATABASE::"Transfer Line", 0, "Document No.", "Line No.", 0);
                        NewWhseActivLine."Source Document" := NewWhseActivLine."Source Document"::"Outbound Transfer";
                        NewWhseActivLine."Location Code" := "Transfer-from Code";
                        NewWhseActivLine."Bin Code" := "Transfer-from Bin Code";
                        NewWhseActivLine."Item No." := "Item No.";
                        NewWhseActivLine."Variant Code" := "Variant Code";
                        NewWhseActivLine."Unit of Measure Code" := "Unit of Measure Code";
                        NewWhseActivLine."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
                        NewWhseActivLine.Description := Description;
                        NewWhseActivLine."Description 2" := "Description 2";
                        NewWhseActivLine."Due Date" := "Shipment Date";
                        NewWhseActivLine."Shipping Advice" := TransferHeader."Shipping Advice";
                        NewWhseActivLine."Shipping Agent Code" := "Shipping Agent Code";
                        NewWhseActivLine."Shipping Agent Service Code" := "Shipping Agent Service Code";
                        NewWhseActivLine."Shipment Method Code" := TransferHeader."Shipment Method Code";
                        NewWhseActivLine."Destination Type" := NewWhseActivLine."Destination Type"::Location;
                        NewWhseActivLine."Destination No." := TransferHeader."Transfer-to Code";
                        RemQtyToPickBase := "Qty. to Ship (Base)";
                        OnBeforeNewWhseActivLineInsertFromTransfer(NewWhseActivLine, TransferLine, WhseActivHeader, RemQtyToPickBase);
                        CalcFields("Reserved Quantity Outbnd.");
                        CreatePickOrMoveLine(
                          NewWhseActivLine, RemQtyToPickBase,
                          "Outstanding Qty. (Base)", "Reserved Quantity Outbnd." <> 0);

                        if TransferHeader."Shipping Advice" = TransferHeader."Shipping Advice"::Complete then begin
                            if RemQtyToPickBase > 0 then begin
                                if AutoCreation then begin
                                    WhseActivHeader.Delete(true);
                                    LineCreated := false;
                                    exit;
                                end;
                                Error(Text002, TransferHeader."Shipping Advice", "Document No.", "Line No.");
                            end;
                            if (RemQtyToPickBase = 0) and not CompleteShipment then begin
                                if ShowError then
                                    Error(Text002, TransferHeader."Shipping Advice", "Document No.", "Line No.");
                                if WhseActivHeader.Delete(true) then;
                                LineCreated := false;
                                exit;
                            end;
                        end;
                    end;
            until Next = 0;
        end;
    end;

    local procedure SetFilterTransferLine(var TransferLine: Record "Transfer Line"; TransferHeader: Record "Transfer Header"): Boolean
    begin
        with TransferLine do begin
            SetRange("Document No.", TransferHeader."No.");
            SetRange("Derived From Line No.", 0);
            if not CheckLineExist then
                SetRange("Transfer-from Code", WhseActivHeader."Location Code");
            SetFilter("Qty. to Ship", '>%1', 0);
            OnBeforeFindTransLine(TransferLine, TransferHeader, WhseActivHeader);
            exit(Find('-'));
        end;
    end;

    local procedure CreatePickOrMoveFromProduction(ProdOrder: Record "Production Order")
    var
        ProdOrderComp: Record "Prod. Order Component";
        NewWhseActivLine: Record "Warehouse Activity Line";
        RemQtyToPickBase: Decimal;
        IsHandled: Boolean;
    begin
        with ProdOrderComp do begin
            if not SetFilterProductionLine(ProdOrderComp, ProdOrder) then begin
                if not HideDialog then
                    Message(Text000);
                exit;
            end;

            FindNextLineNo;

            repeat
                IsHandled := false;
                OnBeforeCreatePickOrMoveLineFromProductionLoop(WhseActivHeader, ProdOrder, IsHandled, ProdOrderComp);
                if not IsHandled then
                    if not
                       NewWhseActivLine.ActivityExists(
                         DATABASE::"Prod. Order Component", Status, "Prod. Order No.", "Prod. Order Line No.", "Line No.", 0)
                    then begin
                        NewWhseActivLine.Init();
                        NewWhseActivLine."Activity Type" := WhseActivHeader.Type;
                        NewWhseActivLine."No." := WhseActivHeader."No.";
                        if Location."Bin Mandatory" then
                            NewWhseActivLine."Action Type" := NewWhseActivLine."Action Type"::Take;
                        NewWhseActivLine.SetSource(DATABASE::"Prod. Order Component", Status, "Prod. Order No.", "Prod. Order Line No.", "Line No.");
                        NewWhseActivLine."Location Code" := "Location Code";
                        NewWhseActivLine."Bin Code" := "Bin Code";
                        NewWhseActivLine."Item No." := "Item No.";
                        NewWhseActivLine."Variant Code" := "Variant Code";
                        NewWhseActivLine."Unit of Measure Code" := "Unit of Measure Code";
                        NewWhseActivLine."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
                        NewWhseActivLine.Description := Description;
                        NewWhseActivLine."Source Document" := NewWhseActivLine."Source Document"::"Prod. Consumption";
                        NewWhseActivLine."Due Date" := "Due Date";
                        if WhseActivHeader.Type = WhseActivHeader.Type::"Invt. Pick" then
                            RemQtyToPickBase := "Remaining Qty. (Base)"
                        else
                            RemQtyToPickBase := "Expected Qty. (Base)" - "Qty. Picked (Base)";
                        OnBeforeNewWhseActivLineInsertFromComp(NewWhseActivLine, ProdOrderComp, WhseActivHeader, RemQtyToPickBase);
                        CalcFields("Reserved Quantity");
                        CreatePickOrMoveLine(
                          NewWhseActivLine, RemQtyToPickBase, RemQtyToPickBase, "Reserved Quantity" <> 0);
                    end;
            until Next = 0;
        end;
    end;

    local procedure CreatePickOrMoveFromAssembly(AsmHeader: Record "Assembly Header")
    var
        AssemblyLine: Record "Assembly Line";
        NewWhseActivLine: Record "Warehouse Activity Line";
        RemQtyToPickBase: Decimal;
        IsHandled: Boolean;
    begin
        with AssemblyLine do begin
            if not SetFilterAssemblyLine(AssemblyLine, AsmHeader) then begin
                if not HideDialog then
                    Message(Text000);
                exit;
            end;

            if WhseActivHeader.Type = WhseActivHeader.Type::"Invt. Pick" then // no support for inventory pick on assembly
                exit;

            FindNextLineNo;

            repeat
                IsHandled := false;
                OnBeforeCreatePickOrMoveLineFromAssemblyLoop(WhseActivHeader, AsmHeader, IsHandled, AssemblyLine);
                if not IsHandled then
                    if not
                       NewWhseActivLine.ActivityExists(DATABASE::"Assembly Line", "Document Type", "Document No.", "Line No.", 0, 0)
                    then begin
                        NewWhseActivLine.Init();
                        NewWhseActivLine."Activity Type" := WhseActivHeader.Type;
                        NewWhseActivLine."No." := WhseActivHeader."No.";
                        if Location."Bin Mandatory" then
                            NewWhseActivLine."Action Type" := NewWhseActivLine."Action Type"::Take;
                        NewWhseActivLine.SetSource(DATABASE::"Assembly Line", "Document Type", "Document No.", "Line No.", 0);
                        NewWhseActivLine."Location Code" := "Location Code";
                        NewWhseActivLine."Bin Code" := "Bin Code";
                        NewWhseActivLine."Item No." := "No.";
                        NewWhseActivLine."Variant Code" := "Variant Code";
                        NewWhseActivLine."Unit of Measure Code" := "Unit of Measure Code";
                        NewWhseActivLine."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
                        NewWhseActivLine.Description := Description;
                        NewWhseActivLine."Source Document" := NewWhseActivLine."Source Document"::"Assembly Consumption";
                        NewWhseActivLine."Due Date" := "Due Date";
                        NewWhseActivLine."Destination Type" := NewWhseActivLine."Destination Type"::Item;
                        NewWhseActivLine."Destination No." := AssemblyHeader."Item No.";
                        RemQtyToPickBase := "Quantity (Base)" - "Remaining Quantity (Base)" +
                          "Quantity to Consume (Base)" - "Qty. Picked (Base)";
                        OnBeforeNewWhseActivLineInsertFromAssembly(NewWhseActivLine, AssemblyLine, WhseActivHeader, RemQtyToPickBase);
                        CalcFields("Reserved Quantity");
                        CreatePickOrMoveLine(
                          NewWhseActivLine, RemQtyToPickBase, RemQtyToPickBase, "Reserved Quantity" <> 0);
                    end;
            until Next = 0;
        end;
    end;

    local procedure SetFilterProductionLine(var ProdOrderComp: Record "Prod. Order Component"; ProdOrder: Record "Production Order"): Boolean
    begin
        with ProdOrderComp do begin
            SetRange(Status, ProdOrder.Status);
            SetRange("Prod. Order No.", ProdOrder."No.");
            if not CheckLineExist then
                SetRange("Location Code", WhseActivHeader."Location Code");
            SetRange("Planning Level Code", 0);
            if IsInvtMovement then begin
                SetFilter("Bin Code", '<>%1', '');
                SetFilter("Flushing Method", '%1|%2|%3',
                  "Flushing Method"::Manual,
                  "Flushing Method"::"Pick + Forward",
                  "Flushing Method"::"Pick + Backward");
            end else
                SetRange("Flushing Method", "Flushing Method"::Manual);
            SetFilter("Remaining Quantity", '>0');
            OnBeforeFindProdOrderComp(ProdOrderComp, ProdOrder, WhseActivHeader);
            exit(Find('-'));
        end;
    end;

    local procedure SetFilterAssemblyLine(var AssemblyLine: Record "Assembly Line"; AsmHeader: Record "Assembly Header"): Boolean
    begin
        with AssemblyLine do begin
            SetRange("Document Type", AsmHeader."Document Type");
            SetRange("Document No.", AsmHeader."No.");
            SetRange(Type, Type::Item);
            if not CheckLineExist then
                SetRange("Location Code", WhseActivHeader."Location Code");
            if IsInvtMovement then
                SetFilter("Bin Code", '<>%1', '');
            SetFilter("Remaining Quantity", '>0');
            OnBeforeFindAssemblyLine(AssemblyLine, AssemblyHeader, WhseActivHeader);
            exit(Find('-'));
        end;
    end;

    local procedure FindNextLineNo()
    var
        WhseActivLine: Record "Warehouse Activity Line";
    begin
        with WhseActivHeader do begin
            if IsInvtMovement then
                WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::"Invt. Movement")
            else
                WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::"Invt. Pick");
            WhseActivLine.SetRange("No.", "No.");
            if WhseActivLine.FindLast then
                NextLineNo := WhseActivLine."Line No." + 10000
            else
                NextLineNo := 10000;
        end;
    end;

    local procedure CreatePickOrMoveLine(NewWhseActivLine: Record "Warehouse Activity Line"; var RemQtyToPickBase: Decimal; OutstandingQtyBase: Decimal; ReservationExists: Boolean)
    var
        ReservationEntry: Record "Reservation Entry";
        ATOSalesLine: Record "Sales Line";
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        QtyAvailToPickBase: Decimal;
        OriginalRemQtyToPickBase: Decimal;
        ITQtyToPickBase: Decimal;
        TotalITQtyToPickBase: Decimal;
        QtyToTrackBase: Decimal;
        EntriesExist: Boolean;
    begin
        if ReservationExists then
            CalcRemQtyToPickOrMoveBase(NewWhseActivLine, OutstandingQtyBase, RemQtyToPickBase);
        if RemQtyToPickBase <= 0 then
            exit;

        OriginalRemQtyToPickBase := RemQtyToPickBase;

        QtyAvailToPickBase := CalcInvtAvailability(NewWhseActivLine, '', '');
        if WMSMgt.GetATOSalesLine(
             NewWhseActivLine."Source Type", NewWhseActivLine."Source Subtype", NewWhseActivLine."Source No.",
             NewWhseActivLine."Source Line No.", ATOSalesLine)
        then
            QtyAvailToPickBase += ATOSalesLine.QtyToAsmBaseOnATO;

        if RemQtyToPickBase > QtyAvailToPickBase then begin
            RemQtyToPickBase := QtyAvailToPickBase;
            CompleteShipment := false;
        end;

        if RemQtyToPickBase > 0 then begin
            ItemTrackingMgt.GetWhseItemTrkgSetup(NewWhseActivLine."Item No.", WhseItemTrackingSetup);
            if WhseItemTrackingSetup.TrackingRequired() then begin
                if IsBlankInvtMovement then
                    ItemTrackingMgt.SumUpItemTrackingOnlyInventoryOrATO(TempReservEntry, TempHandlingSpecification, true, true)
                else begin
                    SetFilterReservEntry(ReservationEntry, NewWhseActivLine);
                    ItemTrackingMgt.SumUpItemTrackingOnlyInventoryOrATO(ReservationEntry, TempHandlingSpecification, true, true);
                end;
                if (PickOrMoveAccordingToFEFO(NewWhseActivLine."Location Code", WhseItemTrackingSetup)) or
                   PickStrictExpirationPosting(NewWhseActivLine."Item No.", WhseItemTrackingSetup)
                then begin
                    QtyToTrackBase := RemQtyToPickBase;
                    if UndefinedItemTrkg(QtyToTrackBase) then
                        CreateTempHandlingSpec(NewWhseActivLine, QtyToTrackBase);
                end;

                TempHandlingSpecification.Reset();
                if TempHandlingSpecification.Find('-') then
                    repeat
                        ITQtyToPickBase := Abs(TempHandlingSpecification."Qty. to Handle (Base)");
                        TotalITQtyToPickBase += ITQtyToPickBase;
                        if ITQtyToPickBase > 0 then begin
                            NewWhseActivLine.CopyTrackingFromSpec(TempHandlingSpecification);
                            if NewWhseActivLine.TrackingExists then
                                NewWhseActivLine."Expiration Date" :=
                                  ItemTrackingMgt.ExistingExpirationDate(NewWhseActivLine."Item No.",
                                    NewWhseActivLine."Variant Code", NewWhseActivLine."Lot No.", NewWhseActivLine."Serial No.",
                                    false, EntriesExist);

                            OnCreatePickOrMoveLineFromHandlingSpec(NewWhseActivLine, TempHandlingSpecification, EntriesExist);

                            if Location."Bin Mandatory" then begin
                                // find Take qty. for bin code of source line
                                if (NewWhseActivLine."Bin Code" <> '') and (not IsInvtMovement or IsBlankInvtMovement) then
                                    InsertPickOrMoveBinWhseActLine(
                                      NewWhseActivLine, NewWhseActivLine."Bin Code", false, ITQtyToPickBase, WhseItemTrackingSetup);

                                // Invt. movement without document has to be created
                                if IsBlankInvtMovement then
                                    ITQtyToPickBase := 0;

                                // find Take qty. for default bin
                                if ITQtyToPickBase > 0 then
                                    InsertPickOrMoveBinWhseActLine(NewWhseActivLine, '', true, ITQtyToPickBase, WhseItemTrackingSetup);

                                // find Take qty. for other bins
                                if ITQtyToPickBase > 0 then
                                    InsertPickOrMoveBinWhseActLine(NewWhseActivLine, '', false, ITQtyToPickBase, WhseItemTrackingSetup);
                                if (ITQtyToPickBase = 0) and IsInvtMovement and not IsBlankInvtMovement then
                                    SynchronizeWhseItemTracking(TempHandlingSpecification);
                            end else
                                if ITQtyToPickBase > 0 then
                                    InsertShelfWhseActivLine(NewWhseActivLine, ITQtyToPickBase, WhseItemTrackingSetup);

                            RemQtyToPickBase :=
                              RemQtyToPickBase + ITQtyToPickBase +
                              TempHandlingSpecification."Qty. to Handle (Base)";
                        end;
                        NewWhseActivLine.ClearTracking;
                    until (TempHandlingSpecification.Next = 0) or (RemQtyToPickBase <= 0);

                RemQtyToPickBase := Minimum(RemQtyToPickBase, OriginalRemQtyToPickBase - TotalITQtyToPickBase);
            end;

            if Location."Bin Mandatory" then begin
                // find Take qty. for bin code of source line
                if (RemQtyToPickBase > 0) and
                   (NewWhseActivLine."Bin Code" <> '') and
                   (not IsInvtMovement or IsBlankInvtMovement) and
                   (not HasExpiredItems)
                then
                    InsertPickOrMoveBinWhseActLine(
                      NewWhseActivLine, NewWhseActivLine."Bin Code", false, RemQtyToPickBase, WhseItemTrackingSetup);

                // Invt. movement without document has to be created
                if IsBlankInvtMovement then
                    RemQtyToPickBase := 0;

                // find Take qty. for default bin
                if (RemQtyToPickBase > 0) and (not HasExpiredItems) then
                    InsertPickOrMoveBinWhseActLine(NewWhseActivLine, '', true, RemQtyToPickBase, WhseItemTrackingSetup);

                // find Take qty. for other bins
                if (RemQtyToPickBase > 0) and (not HasExpiredItems) then
                    InsertPickOrMoveBinWhseActLine(NewWhseActivLine, '', false, RemQtyToPickBase, WhseItemTrackingSetup)
            end else
                if (RemQtyToPickBase > 0) and (not HasExpiredItems) then
                    InsertShelfWhseActivLine(NewWhseActivLine, RemQtyToPickBase, WhseItemTrackingSetup);
        end;

        OnAfterInsertWhseActivLine(
            NewWhseActivLine, WhseItemTrackingSetup."Serial No. Required", WhseItemTrackingSetup."Lot No. Required",
            RemQtyToPickBase, CompleteShipment, ReservationExists, WhseItemTrackingSetup);
    end;

    local procedure CalcRemQtyToPickOrMoveBase(NewWhseActivLine: Record "Warehouse Activity Line"; OutstandingQtyBase: Decimal; var RemQtyToPickBase: Decimal)
    var
        ATOSalesLine: Record "Sales Line";
        MaxQtyToPickBase: Decimal;
    begin
        with NewWhseActivLine do begin
            MaxQtyToPickBase :=
              OutstandingQtyBase -
              WMSMgt.CalcLineReservedQtyNotonInvt(
                "Source Type", "Source Subtype", "Source No.",
                "Source Line No.", "Source Subline No.");

            if WMSMgt.GetATOSalesLine("Source Type", "Source Subtype", "Source No.", "Source Line No.", ATOSalesLine) then
                MaxQtyToPickBase += ATOSalesLine.QtyAsmRemainingBaseOnATO;

            if RemQtyToPickBase > MaxQtyToPickBase then begin
                RemQtyToPickBase := MaxQtyToPickBase;
                if "Shipping Advice" = "Shipping Advice"::Complete then
                    CompleteShipment := false;
            end;
        end;
    end;

    local procedure InsertPickOrMoveBinWhseActLine(NewWhseActivLine: Record "Warehouse Activity Line"; BinCode: Code[20]; DefaultBin: Boolean; var RemQtyToPickBase: Decimal; WhseItemTrackingSetup: Record "Item Tracking Setup")
    var
        FromBinContent: Record "Bin Content";
        QtyToPickBase: Decimal;
        QtyAvailToPickBase: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertPickOrMoveBinWhseActLine(
            NewWhseActivLine, BinCode, DefaultBin, RemQtyToPickBase, IsHandled, WhseRequest, WhseActivHeader,
            IsInvtMovement, AutoCreation, PostingDate, VendorDocNo, LineCreated, NextLineNo);
        if IsHandled then
            exit;

        CreateATOPickLine(NewWhseActivLine, BinCode, RemQtyToPickBase);
        if RemQtyToPickBase = 0 then
            exit;

        with FromBinContent do begin
            SetCurrentKey(Default, "Location Code", "Item No.", "Variant Code", "Bin Code");
            SetRange(Default, DefaultBin);
            SetRange("Location Code", NewWhseActivLine."Location Code");
            SetRange("Item No.", NewWhseActivLine."Item No.");
            SetRange("Variant Code", NewWhseActivLine."Variant Code");

            if (BinCode <> '') and not IsInvtMovement then
                SetRange("Bin Code", BinCode);

            if (NewWhseActivLine."Bin Code" <> '') and IsInvtMovement then
                // not movement within the same bin
                SetFilter("Bin Code", '<>%1', NewWhseActivLine."Bin Code");

            if IsBlankInvtMovement then begin
                // inventory movement without source document, created from Internal Movement
                SetRange("Bin Code", FromBinCode);
                SetRange(Default);
            end;

            SetTrackingFilterFromWhseActivityLineIfNotBlank(NewWhseActivLine);

            OnBeforeFindFromBinContent(FromBinContent, NewWhseActivLine);
            if Find('-') then
                repeat
                    if NewWhseActivLine."Activity Type" = NewWhseActivLine."Activity Type"::"Invt. Movement" then
                        QtyAvailToPickBase := CalcQtyAvailToPickIncludingDedicated(0)
                    else
                        QtyAvailToPickBase := CalcQtyAvailToPick(0);
                    if RemQtyToPickBase < QtyAvailToPickBase then
                        QtyAvailToPickBase := RemQtyToPickBase;
                    if QtyAvailToPickBase > 0 then begin
                        if WhseItemTrackingSetup."Serial No. Required" then begin
                            QtyAvailToPickBase := Round(QtyAvailToPickBase, 1, '<');
                            QtyToPickBase := 1;
                        end else
                            QtyToPickBase := QtyAvailToPickBase;

                        MakeHeader();

                        repeat
                            MakeLine(NewWhseActivLine, "Bin Code", QtyToPickBase, RemQtyToPickBase);
                            QtyAvailToPickBase := QtyAvailToPickBase - QtyToPickBase;
                        until QtyAvailToPickBase <= 0;
                    end;
                until (Next = 0) or (RemQtyToPickBase = 0);
        end;
    end;

    local procedure InsertShelfWhseActivLine(NewWhseActivLine: Record "Warehouse Activity Line"; var RemQtyToPickBase: Decimal; WhseItemTrackingSetup: Record "Item Tracking Setup")
    var
        QtyToPickBase: Decimal;
    begin
        CreateATOPickLine(NewWhseActivLine, '', RemQtyToPickBase);
        if RemQtyToPickBase = 0 then
            exit;

        if WhseItemTrackingSetup."Serial No. Required" then begin
            RemQtyToPickBase := Round(RemQtyToPickBase, 1, '<');
            QtyToPickBase := 1;
        end else
            QtyToPickBase := RemQtyToPickBase;

        MakeHeader();

        repeat
            MakeLine(NewWhseActivLine, '', QtyToPickBase, RemQtyToPickBase);
        until RemQtyToPickBase = 0;
    end;

    local procedure CalcInvtAvailability(WhseActivLine: Record "Warehouse Activity Line"; LotNo: Code[50]; SerialNo: Code[50]): Decimal
    var
        Item2: Record Item;
        TempWhseActivLine2: Record "Warehouse Activity Line" temporary;
        WhseAvailMgt: Codeunit "Warehouse Availability Mgt.";
        QtyAssgndtoPick: Decimal;
        LineReservedQty: Decimal;
        QtyReservedOnPickShip: Decimal;
        QtyOnDedicatedBins: Decimal;
        QtyBlocked: Decimal;
    begin
        with WhseActivLine do begin
            GetItem("Item No.");
            Item2 := Item;
            Item2.SetRange("Location Filter", "Location Code");
            Item2.SetRange("Variant Filter", "Variant Code");
            if SerialNo <> '' then
                Item2.SetRange("Serial No. Filter", SerialNo);
            if LotNo <> '' then
                Item2.SetRange("Lot No. Filter", LotNo);
            Item2.CalcFields(Inventory);
            if not IsBlankInvtMovement then
                Item2.CalcFields("Reserved Qty. on Inventory");

            QtyAssgndtoPick := WhseAvailMgt.CalcQtyAssgndtoPick(Location, "Item No.", "Variant Code", '');
            if "Activity Type" <> "Activity Type"::"Invt. Movement" then // Invt. Movement from Dedicated Bin is allowed
                QtyOnDedicatedBins := WhseAvailMgt.CalcQtyOnDedicatedBins("Location Code", "Item No.", "Variant Code", LotNo, SerialNo);
            QtyBlocked :=
              WhseAvailMgt.CalcQtyOnBlockedITOrOnBlockedOutbndBins("Location Code", "Item No.", "Variant Code", LotNo, SerialNo, false, false);
            LineReservedQty :=
              WhseAvailMgt.CalcLineReservedQtyOnInvt(
                "Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.", true, LotNo, SerialNo, TempWhseActivLine2);
            QtyReservedOnPickShip :=
              WhseAvailMgt.CalcReservQtyOnPicksShips("Location Code", "Item No.", "Variant Code", TempWhseActivLine2);
        end;
        exit(
          Item2.Inventory - Abs(Item2."Reserved Qty. on Inventory") - QtyAssgndtoPick - QtyOnDedicatedBins - QtyBlocked +
          LineReservedQty + QtyReservedOnPickShip);
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode <> Location.Code then begin
            if LocationCode = '' then
                Location.GetLocationSetup('', Location)
            else
                Location.Get(LocationCode);
        end;
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
        ProdOrderComp: Record "Prod. Order Component";
        AssemblyLine: Record "Assembly Line";
        IsHandled: Boolean;
        Result: Boolean;
    begin
        WhseRequest := NewWhseRequest;
        if Location.RequireShipment(WhseRequest."Location Code") then
            exit(false);

        IsHandled := false;
        OnBeforeCheckSourceDoc(NewWhseRequest, Result, IsHandled);
        if IsHandled then
            exit(Result);

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
            WhseRequest."Source Document"::"Outbound Transfer":
                exit(SetFilterTransferLine(TransferLine, TransferHeader));
            WhseRequest."Source Document"::"Prod. Consumption":
                exit(SetFilterProductionLine(ProdOrderComp, ProdHeader));
            WhseRequest."Source Document"::"Assembly Consumption":
                exit(SetFilterAssemblyLine(AssemblyLine, AssemblyHeader));
            else begin
                    IsHandled := false;
                    OnCheckSourceDocForWhseRequest(WhseRequest, SourceDocRecRef, WhseActivHeader, CheckLineExist, Result, IsHandled);
                    if IsHandled then
                        exit(Result);
                end;
        end;
    end;

    procedure AutoCreatePickOrMove(var WhseActivHeaderNew: Record "Warehouse Activity Header")
    var
        IsHandled: Boolean;
    begin
        WhseActivHeader := WhseActivHeaderNew;
        CheckLineExist := false;
        AutoCreation := true;
        GetLocation(WhseRequest."Location Code");

        IsHandled := false;
        OnBeforeAutoCreatePickOrMove(WhseRequest, WhseActivHeader, LineCreated, IsHandled);
        if IsHandled then
            exit;

        case WhseRequest."Source Document" of
            WhseRequest."Source Document"::"Purchase Order":
                CreatePickOrMoveFromPurchase(PurchHeader);
            WhseRequest."Source Document"::"Purchase Return Order":
                CreatePickOrMoveFromPurchase(PurchHeader);
            WhseRequest."Source Document"::"Sales Order":
                CreatePickOrMoveFromSales(SalesHeader);
            WhseRequest."Source Document"::"Sales Return Order":
                CreatePickOrMoveFromSales(SalesHeader);
            WhseRequest."Source Document"::"Outbound Transfer":
                CreatePickOrMoveFromTransfer(TransferHeader);
            WhseRequest."Source Document"::"Prod. Consumption":
                CreatePickOrMoveFromProduction(ProdHeader);
            WhseRequest."Source Document"::"Assembly Consumption":
                CreatePickOrMoveFromAssembly(AssemblyHeader);
            else
                OnAutoCreatePickOrMoveFromWhseRequest(
                    WhseRequest, SourceDocRecRef, LineCreated, WhseActivHeader, Location, HideDialog, CompleteShipment, CheckLineExist);
        end;

        if LineCreated then begin
            WhseActivHeader.Modify();
            WhseActivHeaderNew := WhseActivHeader;
        end;

        OnAfterAutoCreatePickOrMove(WhseRequest, LineCreated, WhseActivHeaderNew);
    end;

    procedure SetReportGlobals(PrintDocument2: Boolean; ShowError2: Boolean)
    begin
        PrintDocument := PrintDocument2;
        ShowError := ShowError2;
    end;

    local procedure SetFilterReservEntry(var ReservationEntry: Record "Reservation Entry"; WhseActivLine: Record "Warehouse Activity Line")
    begin
        with ReservationEntry do begin
            Reset;
            SetCurrentKey("Source ID", "Source Ref. No.", "Source Type", "Source Subtype", "Source Batch Name", "Source Prod. Order Line");
            SetRange("Source ID", WhseActivLine."Source No.");
            if WhseActivLine."Source Type" = DATABASE::"Prod. Order Component" then
                SetRange("Source Ref. No.", WhseActivLine."Source Subline No.")
            else
                SetRange("Source Ref. No.", WhseActivLine."Source Line No.");
            SetRange("Source Type", WhseActivLine."Source Type");
            SetRange("Source Subtype", WhseActivLine."Source Subtype");
            if WhseActivLine."Source Type" = DATABASE::"Prod. Order Component" then
                SetRange("Source Prod. Order Line", WhseActivLine."Source Line No.");
            SetRange(Positive, false);
        end;
    end;

    procedure SetInvtMovement(InvtMovement: Boolean)
    begin
        IsInvtMovement := InvtMovement;
    end;

    local procedure PickOrMoveAccordingToFEFO(LocationCode: Code[10]; WhseItemTrackingSetup: Record "Item Tracking Setup"): Boolean
    begin
        GetLocation(LocationCode);

        exit(Location."Pick According to FEFO" and WhseItemTrackingSetup.TrackingRequired());
    end;

    local procedure UndefinedItemTrkg(var QtyToTrackBase: Decimal): Boolean
    begin
        QtyToTrackBase := QtyToTrackBase + ItemTrackedQuantity('', '');

        exit(QtyToTrackBase > 0);
    end;

    local procedure ItemTrackedQuantity(LotNo: Code[50]; SerialNo: Code[50]): Decimal
    begin
        with TempHandlingSpecification do begin
            Reset;
            if (LotNo = '') and (SerialNo = '') then
                if IsEmpty then
                    exit(0);

            if SerialNo <> '' then begin
                SetCurrentKey("Lot No.", "Serial No.");
                SetRange("Serial No.", SerialNo);
                if IsEmpty then
                    exit(0);

                exit(1);
            end;

            if LotNo <> '' then begin
                SetCurrentKey("Lot No.", "Serial No.");
                SetRange("Lot No.", LotNo);
                if IsEmpty then
                    exit(0);
            end;

            SetCurrentKey(
              "Source ID", "Source Type", "Source Subtype", "Source Batch Name",
              "Source Prod. Order Line", "Source Ref. No.");
            if LotNo <> '' then
                SetRange("Lot No.", LotNo);
            CalcSums("Qty. to Handle (Base)");
            exit("Qty. to Handle (Base)");
        end;
    end;

    local procedure CreateTempHandlingSpec(WhseActivLine: Record "Warehouse Activity Line"; TotalQtyToPickBase: Decimal)
    var
        EntrySummary: Record "Entry Summary";
        WhseItemTrackingFEFO: Codeunit "Whse. Item Tracking FEFO";
        TotalAvailQtyToPickBase: Decimal;
        RemQtyToPickBase: Decimal;
        QtyToPickBase: Decimal;
        QtyTracked: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateTempHandlingSpec(WhseActivLine, TotalQtyToPickBase, IsHandled);
        if IsHandled then
            exit;

        if Location."Bin Mandatory" then
            if not IsItemOnBins(WhseActivLine) then
                exit;

        WhseItemTrackingFEFO.SetSource(
          WhseActivLine."Source Type", WhseActivLine."Source Subtype", WhseActivLine."Source No.",
          WhseActivLine."Source Line No.", WhseActivLine."Source Subline No.");
        WhseItemTrackingFEFO.CreateEntrySummaryFEFO(Location, WhseActivLine."Item No.", WhseActivLine."Variant Code", true);
        if WhseItemTrackingFEFO.FindFirstEntrySummaryFEFO(EntrySummary) then begin
            InitTempHandlingSpec;
            RemQtyToPickBase := TotalQtyToPickBase;

            repeat
                if EntrySummary."Expiration Date" <> 0D then begin
                    QtyTracked := ItemTrackedQuantity(EntrySummary."Lot No.", EntrySummary."Serial No.");
                    if not ((EntrySummary."Serial No." <> '') and (QtyTracked > 0)) then begin
                        if Location."Bin Mandatory" then
                            TotalAvailQtyToPickBase :=
                              CalcQtyAvailToPickOnBins(WhseActivLine, EntrySummary."Lot No.", EntrySummary."Serial No.", RemQtyToPickBase)
                        else
                            TotalAvailQtyToPickBase := CalcInvtAvailability(WhseActivLine, EntrySummary."Lot No.", EntrySummary."Serial No.");

                        TotalAvailQtyToPickBase := TotalAvailQtyToPickBase - QtyTracked;
                        QtyToPickBase := 0;

                        OnAfterCalcTotalAvailQtyToPickBase(
                          WhseActivLine."Item No.", WhseActivLine."Variant Code", EntrySummary."Lot No.", EntrySummary."Serial No.",
                          Location.Code, '', WhseActivLine."Source Type", WhseActivLine."Source Subtype", WhseActivLine."Source No.",
                          WhseActivLine."Source Line No.", WhseActivLine."Source Subline No.", RemQtyToPickBase, TotalAvailQtyToPickBase);

                        if TotalAvailQtyToPickBase > 0 then
                            if TotalAvailQtyToPickBase >= RemQtyToPickBase then begin
                                QtyToPickBase := RemQtyToPickBase;
                                RemQtyToPickBase := 0
                            end else begin
                                QtyToPickBase := TotalAvailQtyToPickBase;
                                RemQtyToPickBase := RemQtyToPickBase - QtyToPickBase;
                            end;

                        if QtyToPickBase > 0 then
                            InsertTempHandlingSpec(
                              Location.Code, WhseActivLine."Item No.", WhseActivLine."Variant Code", EntrySummary, QtyToPickBase);
                    end;
                end;
            until not WhseItemTrackingFEFO.FindNextEntrySummaryFEFO(EntrySummary) or (RemQtyToPickBase = 0);
        end;
        HasExpiredItems := WhseItemTrackingFEFO.GetHasExpiredItems;
        ExpiredItemMessageText := WhseItemTrackingFEFO.GetResultMessageForExpiredItem;
    end;

    local procedure InitTempHandlingSpec()
    begin
        with TempHandlingSpecification do begin
            Reset;
            if FindLast then
                LastTempHandlingSpecNo := "Entry No."
            else
                LastTempHandlingSpecNo := 0;
        end;
    end;

    local procedure InsertTempHandlingSpec(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; EntrySummary: Record "Entry Summary"; QuantityBase: Decimal)
    begin
        with TempHandlingSpecification do begin
            Init;
            "Entry No." := LastTempHandlingSpecNo + 1;
            "Location Code" := LocationCode;
            "Item No." := ItemNo;
            "Variant Code" := VariantCode;
            CopyTrackingFromEntrySummary(EntrySummary);
            "Expiration Date" := EntrySummary."Expiration Date";
            OnInsertTempHandlingSpecOnBeforeValidateQtyBase(TempHandlingSpecification, EntrySummary);
            Validate("Quantity (Base)", -QuantityBase);
            Insert;
            LastTempHandlingSpecNo := "Entry No.";
        end;
    end;

    local procedure SetFilterInternalMomement(var InternalMovementLine: Record "Internal Movement Line"; InternalMovementHeader: Record "Internal Movement Header"): Boolean
    begin
        with InternalMovementLine do begin
            SetRange("No.", InternalMovementHeader."No.");
            SetFilter("Qty. (Base)", '>0');
            exit(Find('-'));
        end;
    end;

    procedure CreateInvtMvntWithoutSource(var InternalMovementHeader: Record "Internal Movement Header")
    var
        InternalMovementLine: Record "Internal Movement Line";
        NewWhseActivLine: Record "Warehouse Activity Line";
        RemQtyToPickBase: Decimal;
    begin
        if not Confirm(Text004, false) then
            exit;

        IsInvtMovement := true;
        IsBlankInvtMovement := true;

        InternalMovementHeader.TestField("Location Code");

        with InternalMovementLine do begin
            if not SetFilterInternalMomement(InternalMovementLine, InternalMovementHeader) then begin
                if not HideDialog then
                    Message(Text000);
                exit;
            end;

            // creating Inventory Movement Header
            Clear(WhseActivHeader);
            WhseActivHeader.Type := WhseActivHeader.Type::"Invt. Movement";
            WhseActivHeader.Insert(true);
            WhseActivHeader.Validate("Location Code", InternalMovementHeader."Location Code");
            WhseActivHeader.Validate("Posting Date", InternalMovementHeader."Due Date");
            WhseActivHeader.Validate("Assigned User ID", InternalMovementHeader."Assigned User ID");
            WhseActivHeader.Validate("Assignment Date", InternalMovementHeader."Assignment Date");
            WhseActivHeader.Validate("Assignment Time", InternalMovementHeader."Assignment Time");
            OnInvtMvntWithoutSourceOnBeforeWhseActivHeaderModify(WhseActivHeader, InternalMovementHeader);
            WhseActivHeader.Modify();

            FindNextLineNo;

            repeat
                NewWhseActivLine.Init();
                NewWhseActivLine."Activity Type" := WhseActivHeader.Type;
                NewWhseActivLine."No." := WhseActivHeader."No.";
                TestField("Location Code");
                GetLocation("Location Code");
                if Location."Bin Mandatory" then
                    NewWhseActivLine."Action Type" := NewWhseActivLine."Action Type"::Take;
                NewWhseActivLine."Location Code" := "Location Code";
                TestField("From Bin Code");
                FromBinCode := "From Bin Code";
                TestField("To Bin Code");
                NewWhseActivLine."Bin Code" := "To Bin Code";
                NewWhseActivLine."Item No." := "Item No.";
                NewWhseActivLine."Variant Code" := "Variant Code";
                NewWhseActivLine."Unit of Measure Code" := "Unit of Measure Code";
                NewWhseActivLine."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
                NewWhseActivLine.Description := Description;
                NewWhseActivLine."Due Date" := "Due Date";
                RemQtyToPickBase := "Qty. (Base)";
                OnCreateInvtMvntWithoutSourceOnAfterTransferFields(NewWhseActivLine, InternalMovementLine);
                PrepareItemTrackingFromWhseIT(InternalMovementLine);
                CreatePickOrMoveLine(NewWhseActivLine, RemQtyToPickBase, RemQtyToPickBase, false);
            until Next = 0;
        end;

        if NextLineNo = 10000 then
            Error(Text000);

        MoveWhseComments(InternalMovementHeader, WhseActivHeader."No.");

        if DeleteHandledInternalMovementLines(InternalMovementHeader."No.") then begin
            InternalMovementHeader.Delete(true);
            Message(ActivityCreatedMsg, WhseActivHeader.Type, WhseActivHeader."No.");
        end else
            Message(TrackingNotFullyAppliedMsg, WhseActivHeader.Type, WhseActivHeader."No.");
    end;

    local procedure DeleteHandledInternalMovementLines(InternalMovementHeaderNo: Code[20]): Boolean
    var
        InternalMovementLine: Record "Internal Movement Line";
    begin
        if TempInternalMovementLine.IsEmpty then
            exit(false);

        with InternalMovementLine do begin
            SetRange("No.", InternalMovementHeaderNo);
            FindSet;
            repeat
                TempInternalMovementLine.SetRange("Item No.", "Item No.");
                TempInternalMovementLine.SetRange("Variant Code", "Variant Code");
                TempInternalMovementLine.SetRange("Location Code", "Location Code");
                TempInternalMovementLine.SetRange("Unit of Measure Code", "Unit of Measure Code");
                TempInternalMovementLine.SetRange("From Bin Code", "From Bin Code");
                TempInternalMovementLine.SetRange("To Bin Code", "To Bin Code");
                if TempInternalMovementLine.FindFirst then
                    if Quantity <= TempInternalMovementLine.Quantity then begin
                        TempInternalMovementLine.Quantity -= Quantity;
                        TempInternalMovementLine."Qty. (Base)" -= "Qty. (Base)";
                        OnDeleteHandledInternalMovementLinesOnBeforeModifyTempInternalMovementLine(
                          TempInternalMovementLine, InternalMovementLine);
                        if TempInternalMovementLine.Quantity = 0 then
                            TempInternalMovementLine.Delete
                        else
                            TempInternalMovementLine.Modify();
                        Delete(true);
                    end else begin
                        Quantity -= TempInternalMovementLine.Quantity;
                        "Qty. (Base)" -= TempInternalMovementLine."Qty. (Base)";
                        ItemTrackingMgt.DeleteWhseItemTrkgLines(
                          DATABASE::"Internal Movement Line", 0, "No.", '', 0, "Line No.", "Location Code", true);
                        OnDeleteHandledInternalMovementLinesOnBeforeInternalMovementLineModify(
                          InternalMovementLine, TempInternalMovementLine);
                        Modify(true);
                        TempInternalMovementLine.Delete();
                    end;
            until Next = 0;
            exit(IsEmpty);
        end;
    end;

    local procedure PrepareItemTrackingFromWhseIT(InternalMovementLine: Record "Internal Movement Line")
    var
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        EntryNo: Integer;
    begin
        // function recopies warehouse item tracking into temporary item tracking table
        // when Invt. Movement is created from Internal Movement
        TempReservEntry.Reset();
        TempReservEntry.DeleteAll();

        WhseItemTrackingLine.SetCurrentKey("Source ID", "Source Type", "Source Subtype", "Source Batch Name");
        WhseItemTrackingLine.SetRange("Source Type", DATABASE::"Internal Movement Line");
        WhseItemTrackingLine.SetRange("Source ID", InternalMovementLine."No.");
        WhseItemTrackingLine.SetRange("Source Ref. No.", InternalMovementLine."Line No.");

        if WhseItemTrackingLine.Find('-') then
            repeat
                TempReservEntry.TransferFields(WhseItemTrackingLine);
                EntryNo += 1;
                TempReservEntry."Entry No." := EntryNo;
                TempReservEntry.Positive := false;
                TempReservEntry."Reservation Status" := TempReservEntry."Reservation Status"::Surplus;
                TempReservEntry.Validate("Quantity (Base)", -TempReservEntry."Quantity (Base)");
                TempReservEntry.UpdateItemTracking;
                OnBeforeTempReservEntryInsert(TempReservEntry, WhseItemTrackingLine);
                TempReservEntry.Insert();
            until WhseItemTrackingLine.Next = 0;
    end;

    local procedure SynchronizeWhseItemTracking(var TrackingSpecification: Record "Tracking Specification")
    var
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        EntryNo: Integer;
    begin
        // documents which have defined item tracking - table 337 will have to synchronize these records with 6550 table for invt. movement
        if WhseItemTrackingLine.FindLast then
            EntryNo := WhseItemTrackingLine."Entry No.";
        EntryNo += 1;
        Clear(WhseItemTrackingLine);
        WhseItemTrackingLine.TransferFields(TrackingSpecification);
        WhseItemTrackingLine.Validate("Quantity (Base)", Abs(WhseItemTrackingLine."Quantity (Base)"));
        WhseItemTrackingLine.Validate("Qty. to Invoice (Base)", Abs(WhseItemTrackingLine."Qty. to Invoice (Base)"));
        WhseItemTrackingLine."Entry No." := EntryNo;
        OnBeforeWhseItemTrackingLineInsert(WhseItemTrackingLine, TrackingSpecification);
        WhseItemTrackingLine.Insert();
    end;

    local procedure MoveWhseComments(InternalMovementHeader: Record "Internal Movement Header"; InvtMovementNo: Code[20])
    var
        WhseCommentLine: Record "Warehouse Comment Line";
        WhseCommentLine2: Record "Warehouse Comment Line";
    begin
        WhseCommentLine.SetRange("Table Name", WhseCommentLine."Table Name"::"Internal Movement");
        WhseCommentLine.SetRange("No.", InternalMovementHeader."No.");
        WhseCommentLine.LockTable();

        if WhseCommentLine.Find('-') then begin
            repeat
                WhseCommentLine2.Init();
                WhseCommentLine2 := WhseCommentLine;
                WhseCommentLine2."Table Name" := WhseCommentLine2."Table Name"::"Whse. Activity Header";
                WhseCommentLine2.Type := WhseCommentLine.Type::"Invt. Movement";
                WhseCommentLine2."No." := InvtMovementNo;
                WhseCommentLine2.Insert();
            until WhseCommentLine.Next = 0;
            WhseCommentLine.DeleteAll();
        end;
    end;

    procedure GetExpiredItemMessage(): Text[100]
    begin
        exit(ExpiredItemMessageText);
    end;

    local procedure PickStrictExpirationPosting(ItemNo: Code[20]; WhseItemTrackingSetup: Record "Item Tracking Setup"): Boolean
    var
        StrictExpirationPosting: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePickStrictExpirationPosting(
            ItemNo, WhseItemTrackingSetup."Serial No. Required", WhseItemTrackingSetup."Lot No. Required", StrictExpirationPosting, IsHandled);
        if IsHandled then
            exit(StrictExpirationPosting);

        exit(ItemTrackingMgt.StrictExpirationPosting(ItemNo) and WhseItemTrackingSetup.TrackingRequired());
    end;

    local procedure MakeHeader()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeMakeHeader(WhseActivHeader, AutoCreation, IsHandled);
        if IsHandled then
            exit;

        if AutoCreation and not LineCreated then begin
            WhseActivHeader."No." := '';
            WhseActivHeader.Insert(true);
            UpdateWhseActivHeader(WhseRequest);
            NextLineNo := 10000;
            Commit();
        end;
    end;

    local procedure MakeLine(var NewWhseActivLine: Record "Warehouse Activity Line"; TakeBinCode: Code[20]; QtyToPickBase: Decimal; var RemQtyToPickBase: Decimal)
    var
        PlaceBinCode: Code[20];
    begin
        PlaceBinCode := NewWhseActivLine."Bin Code";

        NewWhseActivLine."No." := WhseActivHeader."No.";
        NewWhseActivLine."Line No." := NextLineNo;
        if Location."Bin Mandatory" then begin
            NewWhseActivLine."Action Type" := NewWhseActivLine."Action Type"::Take;
            NewWhseActivLine."Bin Code" := TakeBinCode;
        end else
            NewWhseActivLine."Shelf No." := GetShelfNo(NewWhseActivLine."Item No.");
        NewWhseActivLine.Quantity := NewWhseActivLine.CalcQty(QtyToPickBase);
        NewWhseActivLine."Qty. (Base)" := QtyToPickBase;
        NewWhseActivLine."Qty. Outstanding" := NewWhseActivLine.Quantity;
        NewWhseActivLine."Qty. Outstanding (Base)" := NewWhseActivLine."Qty. (Base)";
        NewWhseActivLine."Qty. to Handle" := 0;
        NewWhseActivLine."Qty. to Handle (Base)" := 0;
        RemQtyToPickBase := RemQtyToPickBase - QtyToPickBase;
        OnBeforeNewWhseActivLineInsert(NewWhseActivLine);
        NewWhseActivLine.Insert();

        if Location."Bin Mandatory" and IsInvtMovement then begin
            // Place Action for inventory movement
            OnMakeLineOnBeforeUpdatePlaceLine(NewWhseActivLine, PlaceBinCode);
            NextLineNo := NextLineNo + 10000;
            NewWhseActivLine."Line No." := NextLineNo;
            NewWhseActivLine."Action Type" := NewWhseActivLine."Action Type"::Place;
            NewWhseActivLine."Bin Code" := PlaceBinCode;
            NewWhseActivLine.Insert();
            UpdateHandledWhseActivityLineBuffer(NewWhseActivLine, TakeBinCode);
        end;

        LineCreated := true;
        NextLineNo := NextLineNo + 10000;
    end;

    local procedure UpdateHandledWhseActivityLineBuffer(WarehouseActivityLine: Record "Warehouse Activity Line"; TakeBinCode: Code[20])
    begin
        with TempInternalMovementLine do begin
            SetRange("Item No.", WarehouseActivityLine."Item No.");
            SetRange("Variant Code", WarehouseActivityLine."Variant Code");
            SetRange("Location Code", WarehouseActivityLine."Location Code");
            SetRange("To Bin Code", WarehouseActivityLine."Bin Code");
            SetRange("From Bin Code", TakeBinCode);
            SetRange("Unit of Measure Code", WarehouseActivityLine."Unit of Measure Code");
            if FindFirst then begin
                Quantity += WarehouseActivityLine.Quantity;
                "Qty. (Base)" += WarehouseActivityLine."Qty. (Base)";
                OnUpdateHandledWhseActivityLineBufferOnBeforeTempInternalMovementLineModify(
                  TempInternalMovementLine, WarehouseActivityLine);
                Modify;
            end else begin
                "No." := WarehouseActivityLine."No.";
                "Line No." := WarehouseActivityLine."Line No.";
                "Item No." := WarehouseActivityLine."Item No.";
                "Variant Code" := WarehouseActivityLine."Variant Code";
                "Location Code" := WarehouseActivityLine."Location Code";
                "To Bin Code" := WarehouseActivityLine."Bin Code";
                "From Bin Code" := TakeBinCode;
                Quantity := WarehouseActivityLine.Quantity;
                "Qty. (Base)" := WarehouseActivityLine."Qty. (Base)";
                "Unit of Measure Code" := WarehouseActivityLine."Unit of Measure Code";
                OnUpdateHandledWhseActivityLineBufferOnBeforeTempInternalMovementLineInsert(
                  TempInternalMovementLine, WarehouseActivityLine);
                Insert;
            end;
        end;
    end;

    local procedure CreateATOPickLine(NewWhseActivLine: Record "Warehouse Activity Line"; BinCode: Code[20]; var RemQtyToPickBase: Decimal)
    var
        ATOSalesLine: Record "Sales Line";
        AsmHeader: Record "Assembly Header";
        AssemblySetup: Record "Assembly Setup";
        ReservationEntry: Record "Reservation Entry";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        QtyToAsmBase: Decimal;
        QtyToPickBase: Decimal;
        MovementsCreated: Integer;
        TotalMovementsCreated: Integer;
    begin
        if (not IsInvtMovement) and
           WMSMgt.GetATOSalesLine(NewWhseActivLine."Source Type",
             NewWhseActivLine."Source Subtype",
             NewWhseActivLine."Source No.",
             NewWhseActivLine."Source Line No.",
             ATOSalesLine)
        then begin
            ATOSalesLine.AsmToOrderExists(AsmHeader);
            if NewWhseActivLine.TrackingExists then begin
                AsmHeader.SetReservationFilters(ReservationEntry);
                ReservationEntry.SetTrackingFilterFromWhseActivityLine(NewWhseActivLine);
                ReservationEntry.SetRange(Positive, true);
                if ItemTrackingMgt.SumUpItemTracking(ReservationEntry, TempTrackingSpecification, true, true) then
                    QtyToAsmBase := Abs(TempTrackingSpecification."Qty. to Handle (Base)");
            end else
                QtyToAsmBase := ATOSalesLine.QtyToAsmBaseOnATO;
            QtyToPickBase := QtyToAsmBase -
              WMSMgt.CalcQtyBaseOnATOInvtPick(ATOSalesLine, NewWhseActivLine."Serial No.", NewWhseActivLine."Lot No.");
            if QtyToPickBase > 0 then begin
                MakeHeader;
                if Location."Bin Mandatory" and (BinCode = '') then
                    ATOSalesLine.GetATOBin(Location, BinCode);
                NewWhseActivLine."Assemble to Order" := true;
                MakeLine(NewWhseActivLine, BinCode, QtyToPickBase, RemQtyToPickBase);

                AssemblySetup.Get();
                if AssemblySetup."Create Movements Automatically" then begin
                    AsmHeader.CreateInvtMovement(true, PrintDocument, ShowError, MovementsCreated, TotalMovementsCreated);
                    ATOInvtMovementsCreated += MovementsCreated;
                    TotalATOInvtMovementsToBeCreated += TotalMovementsCreated;
                end;
            end;
        end;
    end;

    procedure GetATOMovementsCounters(var MovementsCreated: Integer; var TotalMovementsCreated: Integer)
    begin
        MovementsCreated := ATOInvtMovementsCreated;
        TotalMovementsCreated := TotalATOInvtMovementsToBeCreated;
    end;

    local procedure Minimum(a: Decimal; b: Decimal): Decimal
    begin
        if a < b then
            exit(a);

        exit(b);
    end;

    local procedure CalcQtyAvailToPickOnBins(WhseActivLine: Record "Warehouse Activity Line"; LotNo: Code[50]; SerialNo: Code[50]; RemQtyToPickBase: Decimal): Decimal
    var
        BinContent: Record "Bin Content";
        TotalAvailQtyToPickBase: Decimal;
    begin
        TotalAvailQtyToPickBase := 0;

        with BinContent do begin
            SetRange("Location Code", WhseActivLine."Location Code");
            SetRange("Item No.", WhseActivLine."Item No.");
            SetRange("Variant Code", WhseActivLine."Variant Code");
            SetRange("Serial No. Filter", SerialNo);
            SetRange("Lot No. Filter", LotNo);
            if Find('-') then
                repeat
                    TotalAvailQtyToPickBase += CalcQtyAvailToPick(0);
                until (Next = 0) or (TotalAvailQtyToPickBase >= RemQtyToPickBase);
        end;

        exit(TotalAvailQtyToPickBase);
    end;

    local procedure IsItemOnBins(WhseActivLine: Record "Warehouse Activity Line"): Boolean
    var
        BinContent: Record "Bin Content";
    begin
        with BinContent do begin
            SetRange("Location Code", WhseActivLine."Location Code");
            SetRange("Item No.", WhseActivLine."Item No.");
            SetRange("Variant Code", WhseActivLine."Variant Code");
            exit(not IsEmpty);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAutoCreatePickOrMove(var WarehouseRequest: Record "Warehouse Request"; LineCreated: Boolean; var WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateInventoryPickMovement(var WarehouseRequest: Record "Warehouse Request"; LineCreated: Boolean; var WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterInsertWhseActivLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SNRequired: Boolean; LNRequired: Boolean; var RemQtyToPickBase: Decimal; var CompleteShipment: Boolean; var ReservationExists: Boolean; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcTotalAvailQtyToPickBase(ItemNo: Code[20]; VariantNo: Code[10]; SerialNo: Code[50]; LotNo: Code[50]; LocationCode: Code[10]; BinCode: Code[20]; SourceType: Integer; SourceSubtype: Integer; SourceNo: Code[20]; SourceLineNo: Integer; SourceSublineNo: Integer; RemQtyToPickBase: Decimal; var TotalAvailQtyToPickBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateWhseActivHeader(var WarehouseActivityHeader: Record "Warehouse Activity Header"; var WarehouseRequest: Record "Warehouse Request")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoCreatePickOrMove(WarehouseRequest: Record "Warehouse Request"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var LineCreated: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSourceDoc(WarehouseRequest: Record "Warehouse Request"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePickOrMoveLines(WarehouseRequest: Record "Warehouse Request"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var LinesCreated: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePickOrMoveLineFromSalesLoop(var WarehouseActivityHeader: Record "Warehouse Activity Header"; SalesHeader: Record "Sales Header"; var IsHandled: Boolean; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePickOrMoveLineFromProductionLoop(var WarehouseActivityHeader: Record "Warehouse Activity Header"; ProductionOrder: Record "Production Order"; var IsHandled: Boolean; ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePickOrMoveLineFromPurchaseLoop(var WarehouseActivityHeader: Record "Warehouse Activity Header"; PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePickOrMoveLineFromTransferLoop(var WarehouseActivityHeader: Record "Warehouse Activity Header"; TransferHeader: Record "Transfer Header"; var IsHandled: Boolean; TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePickOrMoveLineFromAssemblyLoop(var WarehouseActivityHeader: Record "Warehouse Activity Header"; AssemblyHeader: Record "Assembly Header"; var IsHandled: Boolean; AssemblyLine: Record "Assembly Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateTempHandlingSpec(WarehouseActivityLine: Record "Warehouse Activity Line"; var TotalQtyToPickBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertPickOrMoveBinWhseActLine(NewWhseActivLine: Record "Warehouse Activity Line"; BinCode: Code[20]; DefaultBin: Boolean; var RemQtyToPickBase: Decimal; var IsHandled: Boolean; var WhseRequest: Record "Warehouse Request"; var WhseActivHeader: Record "Warehouse Activity Header"; IsInvtMovement: Boolean; AutoCreation: Boolean; PostingDate: Date; VendorDocNo: Code[35]; var LineCreated: Boolean; var NextLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNewWhseActivLineInsert(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNewWhseActivLineInsertFromPurchase(var WarehouseActivityLine: Record "Warehouse Activity Line"; var PurchaseLine: Record "Purchase Line"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var RemQtyToPickBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNewWhseActivLineInsertFromSales(var WarehouseActivityLine: Record "Warehouse Activity Line"; var SalesLine: Record "Sales Line"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var RemQtyToPickBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNewWhseActivLineInsertFromTransfer(var WarehouseActivityLine: Record "Warehouse Activity Line"; var TransferLine: Record "Transfer Line"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var RemQtyToPickBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNewWhseActivLineInsertFromAssembly(var WarehouseActivityLine: Record "Warehouse Activity Line"; var AssemblyLine: Record "Assembly Line"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var RemQtyToPickBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNewWhseActivLineInsertFromComp(var WarehouseActivityLine: Record "Warehouse Activity Line"; var ProdOrderComp: Record "Prod. Order Component"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var RemQtyToPickBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindPurchLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindTransLine(var TransferLine: Record "Transfer Line"; TransferHeader: Record "Transfer Header"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindAssemblyLine(var AssemblyLine: Record "Assembly Line"; AssemblyHeader: Record "Assembly Header"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindProdOrderComp(var ProdOrderComp: Record "Prod. Order Component"; ProductionOrder: Record "Production Order"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSourceDocHeader(var WhseRequest: Record "Warehouse Request"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePickStrictExpirationPosting(ItemNo: Code[20]; SNRequired: Boolean; LNRequired: Boolean; var StrictExpirationPosting: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindFromBinContent(var FromBinContent: Record "Bin Content"; var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMakeHeader(WhseActivHeader: Record "Warehouse Activity Header"; var AutoCreation: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempReservEntryInsert(var ReservationEntry: Record "Reservation Entry"; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseItemTrackingLineInsert(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckSourceDocForWhseRequest(var WarehouseRequest: Record "Warehouse Request"; SourceDocRecRef: RecordRef; WhseActivHeader: Record "Warehouse Activity Header"; CheckLineExist: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateInvtMvntWithoutSourceOnAfterTransferFields(var WarehouseActivityLine: Record "Warehouse Activity Line"; InternalMovementLine: Record "Internal Movement Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePickOrMoveLineFromHandlingSpec(var WarehouseActivityLine: Record "Warehouse Activity Line"; TrackingSpecification: Record "Tracking Specification"; EntriesExist: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAutoCreatePickOrMoveFromWhseRequest(var WarehouseRequest: Record "Warehouse Request"; SourceDocRecRef: RecordRef; var LineCreated: Boolean; WhseActivityHeader: Record "Warehouse Activity Header"; Location: Record Location; HideDialog: Boolean; var CompleteShipment: Boolean; CheckLineExist: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePickOrMoveFromWhseRequest(var WarehouseRequest: Record "Warehouse Request"; SourceDocRecRef: RecordRef; var LineCreated: Boolean; WhseActivityHeader: Record "Warehouse Activity Header"; Location: Record Location; HideDialog: Boolean; var CompleteShipment: Boolean; CheckLineExist: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteHandledInternalMovementLinesOnBeforeInternalMovementLineModify(var InternalMovementLine: Record "Internal Movement Line"; TempInternalMovementLine: Record "Internal Movement Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteHandledInternalMovementLinesOnBeforeModifyTempInternalMovementLine(var TempInternalMovementLine: Record "Internal Movement Line" temporary; InternalMovementLine: Record "Internal Movement Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSourceDocHeaderFromWhseRequest(var WarehouseRequest: Record "Warehouse Request"; var SourceDocRecRef: RecordRef; var PostingDate: Date; VendorDocNo: Code[35])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTempHandlingSpecOnBeforeValidateQtyBase(var TempTrackingSpecification: Record "Tracking Specification" temporary; EntrySummary: Record "Entry Summary")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInvtMvntWithoutSourceOnBeforeWhseActivHeaderModify(var WarehouseActivityHeader: Record "Warehouse Activity Header"; InternalMovementHeader: Record "Internal Movement Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMakeLineOnBeforeUpdatePlaceLine(var NewWhseActivLine: Record "Warehouse Activity Line"; var PlaceBinCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateHandledWhseActivityLineBufferOnBeforeTempInternalMovementLineInsert(var TempInternalMovementLine: Record "Internal Movement Line" temporary; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateHandledWhseActivityLineBufferOnBeforeTempInternalMovementLineModify(var TempInternalMovementLine: Record "Internal Movement Line" temporary; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;
}

