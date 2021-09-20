codeunit 333 "Req. Wksh.-Make Order"
{
    Permissions = TableData "Sales Line" = m;
    TableNo = "Requisition Line";

    trigger OnRun()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(Rec, IsHandled);
        if IsHandled then
            exit;

        if PlanningResiliency then
            LockTable();

        CarryOutReqLineAction(Rec);
    end;

    var
        Text000: Label 'Worksheet Name                     #1##########\\';
        Text001: Label 'Checking worksheet lines           #2######\';
        Text002: Label 'Creating purchase orders           #3######\';
        Text003: Label 'Creating purchase lines            #4######\';
        Text004: Label 'Updating worksheet lines           #5######';
        Text005: Label 'Deleting worksheet lines           #5######';
        Text006: Label '%1 on sales order %2 is already associated with purchase order %3.';
        Text007: Label '<Month Text>', Locked = true;
        Text008: Label 'The combination of dimensions used in %1 %2, %3, %4 is blocked. %5';
        Text009: Label 'A dimension used in %1 %2, %3, %4 has caused an error. %5';
        ReservEntry: Record "Reservation Entry";
        PurchSetup: Record "Purchases & Payables Setup";
        ReqTemplate: Record "Req. Wksh. Template";
        ReqWkshName: Record "Requisition Wksh. Name";
        PurchOrderHeader: Record "Purchase Header";
        PurchOrderLine: Record "Purchase Line";
        SalesOrderHeader: Record "Sales Header";
        SalesOrderLine: Record "Sales Line";
        TransHeader: Record "Transfer Header";
        TempTransHeader: Record "Transfer Header" temporary;
        AccountingPeriod: Record "Accounting Period";
        TempFailedReqLine: Record "Requisition Line" temporary;
        PurchasingCode: Record Purchasing;
        TempDocumentEntry: Record "Document Entry" temporary;
        TempPurchaseOrderToPrint: Record "Purchase Header" temporary;
        ReqWkshMakeOrders: Codeunit "Req. Wksh.-Make Order";
        TransferExtendedText: Codeunit "Transfer Extended Text";
        ReqLineReserve: Codeunit "Req. Line-Reserve";
        UOMMgt: Codeunit "Unit of Measure Management";
        DimMgt: Codeunit DimensionManagement;
        Window: Dialog;
        OrderDateReq: Date;
        PostingDateReq: Date;
        ReceiveDateReq: Date;
        EndOrderDate: Date;
        PrintPurchOrders: Boolean;
        ReferenceReq: Text[35];
        MonthText: Text[30];
        OrderCounter: Integer;
        LineCount: Integer;
        OrderLineCounter: Integer;
        StartLineNo: Integer;
        NextLineNo: Integer;
        Day: Integer;
        Week: Integer;
        Month: Integer;
        CounterFailed: Integer;
        PrevPurchCode: Code[10];
        PrevShipToCode: Code[10];
        Text010: Label 'must match %1 on Sales Order %2, Line %3';
        PrevChangedDocOrderType: Option;
        PrevChangedDocOrderNo: Code[20];
        PrevLocationCode: Code[10];
        NameAddressDetails: Text;
        SuppressCommit: Boolean;
        HideProgressWindow: Boolean;

    protected var
        PlanningResiliency: Boolean;

    procedure CarryOutBatchAction(var ReqLine2: Record "Requisition Line")
    var
        ReqLine: Record "Requisition Line";
        IsHandled: Boolean;
    begin
        ReqLine.Copy(ReqLine2);
        ReqLine.SetRange("Accept Action Message", true);
        IsHandled := false;
        OnBeforeCarryOutBatchActionCode(ReqLine, ReqLine2, IsHandled);
        if IsHandled then
            exit;
        Code(ReqLine);
        ReqLine2 := ReqLine;
    end;

    procedure Set(NewPurchOrderHeader: Record "Purchase Header"; NewEndingOrderDate: Date; NewPrintPurchOrder: Boolean)
    begin
        PurchOrderHeader := NewPurchOrderHeader;
        EndOrderDate := NewEndingOrderDate;
        PrintPurchOrders := NewPrintPurchOrder;
        OrderDateReq := PurchOrderHeader."Order Date";
        PostingDateReq := PurchOrderHeader."Posting Date";
        ReceiveDateReq := PurchOrderHeader."Expected Receipt Date";
        ReferenceReq := PurchOrderHeader."Your Reference";
        OnAfterSet(PurchOrderHeader, SuppressCommit, EndOrderDate, PrintPurchOrders);
    end;

    local procedure "Code"(var ReqLine: Record "Requisition Line")
    var
        ReqLine2: Record "Requisition Line";
        ReqLine3: Record "Requisition Line";
        NewReqWkshName: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeCode(ReqLine, PlanningResiliency, SuppressCommit, PrintPurchOrders);

        InitShipReceiveDetails;
        with ReqLine do begin
            Clear(PurchOrderHeader);

            SetRange("Worksheet Template Name", "Worksheet Template Name");
            SetRange("Journal Batch Name", "Journal Batch Name");
            if not PlanningResiliency then
                LockTable();

            if "Planning Line Origin" <> "Planning Line Origin"::"Order Planning" then
                GetReqTemplate(ReqLine, ReqTemplate);

            if ReqTemplate.Recurring then begin
                SetRange("Order Date", 0D, EndOrderDate);
                SetFilter("Expiration Date", '%1 | %2..', 0D, WorkDate);
            end;

            if not Find('=><') then begin
                "Line No." := 0;
                if not SuppressCommit then
                    Commit();
                exit;
            end;

            OnCodeOnBeforeInitProgressWindow(ReqTemplate, HideProgressWindow);
            if not HideProgressWindow then
                InitProgressWindow();

            if not HideProgressWindow then
                Window.Update(1, "Journal Batch Name");

            // Check lines
            CheckRequisitionLines(ReqLine);

            // Create lines
            LineCount := 0;
            OrderCounter := 0;
            OrderLineCounter := 0;
            Clear(PurchOrderHeader);
            SetPurchOrderHeader;
            SetReqLineSortingKey(ReqLine);

            ProcessReqLineActions(ReqLine);

            IsHandled := false;
            OnCodeOnBeforeFinalizeOrderHeader(PurchOrderHeader, ReqLine, IsHandled);
            if not IsHandled then
                if PurchOrderHeader."Buy-from Vendor No." <> '' then
                    FinalizeOrderHeader(PurchOrderHeader, ReqLine);

            if PrintPurchOrders then begin
                PrintTransOrder(TransHeader);
                PrintMultiplePurchaseOrders();
            end;

            if PrevChangedDocOrderNo <> '' then
                PrintChangedDocument(PrevChangedDocOrderType, PrevChangedDocOrderNo);

            // Copy number of created orders and current journal batch name to requisition worksheet
            Init;
            "Line No." := OrderCounter;

            if OrderCounter <> 0 then
                if not ReqTemplate.Recurring then begin
                    // Not a recurring journal
                    ReqLine2.Copy(ReqLine);
                    ReqLine2.SetFilter("Vendor No.", '<>%1', '');
                    if ReqLine2.FindFirst then; // Remember the last line

                    IsHandled := false;
                    OnBeforeDeleteReqLines(ReqLine, TempFailedReqLine, IsHandled, ReqLine2);
                    if not IsHandled then
                        if Find('-') then
                            repeat
                                TempFailedReqLine := ReqLine;
                                if not TempFailedReqLine.Find then
                                    Delete(true);
                            until Next() = 0;

                    ReqLine3.SetRange("Worksheet Template Name", "Worksheet Template Name");
                    ReqLine3.SetRange("Journal Batch Name", "Journal Batch Name");
                    OnCodeOnAfterReqLine3SetFilters(ReqLine, ReqLine3);
                    if not ReqLine3.FindLast then
                        if IncStr("Journal Batch Name") <> '' then begin
                            ReqWkshName.Get("Worksheet Template Name", "Journal Batch Name");
                            NewReqWkshName := true;
                            OnCheckNewNameNeccessary(ReqWkshName, NewReqWkshName);
                            if NewReqWkshName then begin
                                ReqWkshName.Delete();
                                ReqWkshName.Name := IncStr("Journal Batch Name");
                                if ReqWkshName.Insert() then;
                                "Journal Batch Name" := ReqWkshName.Name;
                            end;
                        end;
                end;
        end;

        OnAfterCode(ReqLine, OrderLineCounter, OrderCounter);
    end;

    local procedure CheckRequisitionLines(var ReqLine: Record "Requisition Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckRequisitionLines(ReqLine, StartLineNo, IsHandled);
        if IsHandled then
            exit;

        LineCount := 0;
        StartLineNo := ReqLine."Line No.";
        repeat
            LineCount := LineCount + 1;
            if not HideProgressWindow then
                Window.Update(2, LineCount);
            CheckRecurringReqLine(ReqLine);
            CheckRequisitionLine(ReqLine);
            if ReqLine.Next() = 0 then
                ReqLine.FindSet();
        until ReqLine."Line No." = StartLineNo;
    end;

    local procedure GetReqTemplate(RequisitionLine: Record "Requisition Line"; var ReqWkshTemplate: Record "Req. Wksh. Template")
    var
        IsHandled: Boolean;
    begin
        OnBeforeGetReqTemplate(RequisitionLine, ReqWkshTemplate, IsHandled);
        if not IsHandled then
            ReqTemplate.Get(RequisitionLine."Worksheet Template Name");
    end;

    procedure SetCreatedDocumentBuffer(var TempDocumentEntryNew: Record "Document Entry" temporary)
    begin
        TempDocumentEntry.Copy(TempDocumentEntryNew, true);
    end;

    procedure CheckRequisitionLine(var ReqLine2: Record "Requisition Line")
    var
        SalesLine: Record "Sales Line";
        Purchasing: Record Purchasing;
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckRequisitionLine(ReqLine2, SuppressCommit, IsHandled);
        if IsHandled then
            exit;

        with ReqLine2 do begin
            if ("No." <> '') or ("Vendor No." <> '') or (Quantity <> 0) then begin
                TestField("No.");
                IsHandled := false;
                OnCheckRequisitionLineOnNonCancelActionMessageOnBeforeCheckQuantity(ReqLine2, IsHandled);
                if not IsHandled then
                    if "Action Message" <> "Action Message"::Cancel then
                        TestField(Quantity);
                IsHandled := false;
                OnCheckRequisitionLineOnEmptyNewActionMessageOnBeforeOtherCheck(ReqLine2, IsHandled);
                if not IsHandled then
                    if ("Action Message" = "Action Message"::" ") or
                       ("Action Message" = "Action Message"::New)
                    then
                        if "Replenishment System" = "Replenishment System"::Purchase then
                            TestFieldsForPurchase(ReqLine2)
                        else
                            if "Replenishment System" = "Replenishment System"::Transfer then begin
                                TestField("Location Code");
                                if "Planning Line Origin" = "Planning Line Origin"::"Order Planning" then
                                    TestField("Supply From");
                                TestField("Transfer-from Code");
                            end else
                                OnCheckFurtherReplenishmentSystems(ReqLine2);
            end;

            if not DimMgt.CheckDimIDComb("Dimension Set ID") then
                Error(
                  Text008,
                  TableCaption, "Worksheet Template Name", "Journal Batch Name", "Line No.",
                  DimMgt.GetDimCombErr);

            TableID[1] := DimMgt.TypeToTableID3(Type.AsInteger());
            No[1] := "No.";
            if not DimMgt.CheckDimValuePosting(TableID, No, "Dimension Set ID") then
                if "Line No." <> 0 then
                    Error(
                      Text009,
                      TableCaption, "Worksheet Template Name", "Journal Batch Name", "Line No.",
                      DimMgt.GetDimValuePostingErr)
                else
                    Error(DimMgt.GetDimValuePostingErr);

            if SalesLine.Get(SalesLine."Document Type"::Order, "Sales Order No.", "Sales Order Line No.") and
               (SalesLine."Unit of Measure Code" <> "Unit of Measure Code")
            then
                if SalesLine."Drop Shipment" or
                   (PurchasingCode.Get("Purchasing Code") and PurchasingCode."Drop Shipment")
                then
                    FieldError(
                      "Unit of Measure Code",
                      StrSubstNo(
                        Text010,
                        SalesLine.FieldCaption("Unit of Measure Code"),
                        SalesLine."Document No.",
                        SalesLine."Line No."));

            if IsDropShipment() then
                CheckLocation(ReqLine2);

            if Purchasing.Get("Purchasing Code") then
                if Purchasing."Drop Shipment" or Purchasing."Special Order" then begin
                    SalesLine.Get(SalesLine."Document Type"::Order, "Sales Order No.", "Sales Order Line No.");
                    CheckLocation(ReqLine2);
                    if (Purchasing."Drop Shipment" <> SalesLine."Drop Shipment") or
                       (Purchasing."Special Order" <> SalesLine."Special Order")
                    then
                        FieldError(
                          "Purchasing Code",
                          StrSubstNo(
                            Text010,
                            SalesLine.FieldCaption("Purchasing Code"),
                            SalesLine."Document No.",
                            SalesLine."Line No."));
                end;
        end;

        OnAfterCheckReqWkshLine(ReqLine2, SuppressCommit);
    end;

    local procedure TestFieldsForPurchase(var RequisitionLine: Record "Requisition Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestFieldsForPurchase(RequisitionLine, IsHandled);
        if IsHandled then
            exit;
        if RequisitionLine."Planning Line Origin" = RequisitionLine."Planning Line Origin"::"Order Planning" then
            RequisitionLine.TestField("Supply From");
        RequisitionLine.TestField("Vendor No.")
    end;

    local procedure CarryOutReqLineAction(var ReqLine: Record "Requisition Line")
    var
        CarryOutAction: Codeunit "Carry Out Action";
        Failed: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCarryOutReqLineAction(ReqLine, Failed, IsHandled);
        if Failed then begin
            SetFailedReqLine(ReqLine);
            exit;
        end;

        if IsHandled then
            exit;

        with ReqLine do
            case "Replenishment System" of
                "Replenishment System"::Transfer:
                    case "Action Message" of
                        "Action Message"::Cancel:
                            begin
                                CarryOutAction.DeleteOrderLines(ReqLine);
                                OrderCounter := OrderCounter + 1;
                            end;
                        "Action Message"::"Change Qty.", "Action Message"::Reschedule, "Action Message"::"Resched. & Chg. Qty.":
                            begin
                                if (PrevChangedDocOrderNo <> '') and
                                   (("Ref. Order Type" <> PrevChangedDocOrderType) or ("Ref. Order No." <> PrevChangedDocOrderNo))
                                then
                                    PrintChangedDocument(PrevChangedDocOrderType, PrevChangedDocOrderNo);
                                CarryOutAction.SetPrintOrder(false);
                                CarryOutAction.TransOrderChgAndReshedule(ReqLine);
                                PrevChangedDocOrderType := "Ref. Order Type";
                                PrevChangedDocOrderNo := "Ref. Order No.";
                                OrderCounter := OrderCounter + 1;
                            end;
                        "Action Message"::New, "Action Message"::" ":
                            begin
                                CarryOutAction.SetPrintOrder(PrintPurchOrders);
                                GetTransferHeader(TransHeader, ReqLine);
                                CarryOutAction.InsertTransLine(ReqLine, TransHeader);
                                SetTransferHeader(TransHeader);
                                OnCarryOutReqLineActionOnAfterInsertTransLine(TransHeader);
                                OrderCounter := OrderCounter + 1;
                            end;
                    end;
                "Replenishment System"::Purchase, "Replenishment System"::"Prod. Order":
                    case "Action Message" of
                        "Action Message"::Cancel:
                            begin
                                CarryOutAction.DeleteOrderLines(ReqLine);
                                OrderCounter := OrderCounter + 1;
                            end;
                        "Action Message"::"Change Qty.", "Action Message"::Reschedule, "Action Message"::"Resched. & Chg. Qty.":
                            begin
                                if (PrevChangedDocOrderNo <> '') and
                                   (("Ref. Order Type" <> PrevChangedDocOrderType) or ("Ref. Order No." <> PrevChangedDocOrderNo))
                                then
                                    PrintChangedDocument(PrevChangedDocOrderType, PrevChangedDocOrderNo);
                                CarryOutAction.SetPrintOrder(false);
                                CarryOutAction.PurchOrderChgAndReshedule(ReqLine);
                                PrevChangedDocOrderType := "Ref. Order Type";
                                PrevChangedDocOrderNo := "Ref. Order No.";
                                OrderCounter := OrderCounter + 1;
                            end;
                        "Action Message"::New, "Action Message"::" ":
                            begin
                                if (PurchOrderHeader."Buy-from Vendor No." <> '') and
                                   CheckInsertFinalizePurchaseOrderHeader(ReqLine, PurchOrderHeader, false)
                                then begin
                                    FinalizeOrderHeader(PurchOrderHeader, ReqLine);
                                    PurchOrderLine.Reset();
                                    PurchOrderLine.SetRange("Document Type", PurchOrderHeader."Document Type");
                                    PurchOrderLine.SetRange("Document No.", PurchOrderHeader."No.");
                                    PurchOrderLine.SetFilter("Special Order Sales Line No.", '<> 0');
                                    if PurchOrderLine.Find('-') then
                                        repeat
                                            SalesOrderLine.Get(SalesOrderLine."Document Type"::Order, PurchOrderLine."Special Order Sales No.",
                                              PurchOrderLine."Special Order Sales Line No.");
                                        until PurchOrderLine.Next() = 0;
                                end;
                                MakeRecurringTexts(ReqLine);
                                InsertPurchOrderLine(ReqLine, PurchOrderHeader);
                            end;
                    end;
                else
                    OnCarryOutReqLineActionOnCaseReplenishmentSystemElse(ReqLine);
            end;

        OnAfterCarryOutReqLineAction(ReqLine, PurchOrderHeader, SuppressCommit, OrderCounter);
    end;

    local procedure TryCarryOutReqLineAction(var ReqLine: Record "Requisition Line"): Boolean
    begin
        with ReqLine do begin
            ReqWkshMakeOrders.Set(PurchOrderHeader, EndOrderDate, PrintPurchOrders);
            ReqWkshMakeOrders.SetTryParam(
              ReqTemplate,
              LineCount,
              NextLineNo,
              PrevPurchCode,
              PrevShipToCode,
              PrevLocationCode,
              OrderCounter,
              OrderLineCounter,
              TempFailedReqLine,
              TempDocumentEntry);
            ReqWkshMakeOrders.SetSuppressCommit(SuppressCommit);
            if ReqWkshMakeOrders.Run(ReqLine) then begin
                ReqWkshMakeOrders.GetTryParam(
                  PurchOrderHeader,
                  LineCount,
                  NextLineNo,
                  PrevPurchCode,
                  PrevShipToCode,
                  PrevLocationCode,
                  OrderCounter,
                  OrderLineCounter);

                if not HideProgressWindow then begin
                    Window.Update(3, OrderCounter);
                    Window.Update(4, LineCount);
                    Window.Update(5, OrderLineCounter);
                end;
                exit(true);
            end;
            exit(false)
        end;
    end;

    procedure InitPurchOrderLine(var PurchOrderLine: Record "Purchase Line"; PurchOrderHeader: Record "Purchase Header"; RequisitionLine: Record "Requisition Line")
    begin
        with RequisitionLine do begin
            PurchOrderLine.Init();
            PurchOrderLine.BlockDynamicTracking(true);
            PurchOrderLine."Document Type" := PurchOrderLine."Document Type"::Order;
            PurchOrderLine."Buy-from Vendor No." := "Vendor No.";
            PurchOrderLine."Document No." := PurchOrderHeader."No.";
            NextLineNo := NextLineNo + 10000;
            PurchOrderLine."Line No." := NextLineNo;
            OnBeforePurchOrderLineValidateType(PurchOrderLine, RequisitionLine);
            PurchOrderLine.Validate(Type, Type);
            OnBeforePurchOrderLineValidateNo(PurchOrderLine, RequisitionLine);
            PurchOrderLine.Validate("No.", "No.");
            OnAfterPurchOrderLineValidateNo(PurchOrderLine, RequisitionLine);
            PurchOrderLine."Variant Code" := "Variant Code";
            OnInitPurchOrderLineOnAfterPurchOrderLineAssignVariantCode(PurchOrderLine, RequisitionLine);
            PurchOrderLine.Validate("Location Code", "Location Code");
            PurchOrderLine.Validate("Unit of Measure Code", "Unit of Measure Code");
            PurchOrderLine."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
            PurchOrderLine."Prod. Order No." := "Prod. Order No.";
            PurchOrderLine."Prod. Order Line No." := "Prod. Order Line No.";
            InitPurchOrderLineUpdateQuantity(RequisitionLine);
            if PurchOrderHeader."Prices Including VAT" then
                PurchOrderLine.Validate("Direct Unit Cost", "Direct Unit Cost" * (1 + PurchOrderLine."VAT %" / 100))
            else
                PurchOrderLine.Validate("Direct Unit Cost", "Direct Unit Cost");
            OnInitPurchOrderLineOnBeforeValidateLineDiscount(PurchOrderLine, PurchOrderHeader, RequisitionLine);
            PurchOrderLine.Validate("Line Discount %", "Line Discount %");
            OnInitPurchOrderLineOnAfterValidateLineDiscount(PurchOrderLine, PurchOrderHeader, RequisitionLine);
            PurchOrderLine."Vendor Item No." := "Vendor Item No.";
            PurchOrderLine.Description := Description;
            PurchOrderLine."Description 2" := "Description 2";
            PurchOrderLine."Sales Order No." := "Sales Order No.";
            PurchOrderLine."Sales Order Line No." := "Sales Order Line No.";
            PurchOrderLine."Prod. Order No." := "Prod. Order No.";
            PurchOrderLine."Bin Code" := "Bin Code";
            PurchOrderLine."Item Category Code" := "Item Category Code";
            PurchOrderLine.Nonstock := Nonstock;
            PurchOrderLine.Validate("Planning Flexibility", "Planning Flexibility");
            PurchOrderLine.Validate("Purchasing Code", "Purchasing Code");
            if "Due Date" <> 0D then begin
                PurchOrderLine.Validate("Expected Receipt Date", "Due Date");
                PurchOrderLine."Requested Receipt Date" := PurchOrderLine."Planned Receipt Date";
            end;
        end;

        OnAfterInitPurchOrderLine(PurchOrderLine, RequisitionLine);
    end;

    local procedure InitPurchOrderLineUpdateQuantity(var RequisitionLine: Record "Requisition Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitPurchOrderLineUpdateQuantity(PurchOrderLine, RequisitionLine, IsHandled);
        if IsHandled then
            exit;

        PurchOrderLine.Validate(Quantity, RequisitionLine.Quantity);
    end;

    procedure InsertPurchOrderLine(var ReqLine2: Record "Requisition Line"; var PurchOrderHeader: Record "Purchase Header")
    var
        PurchOrderLine2: Record "Purchase Line";
        AddOnIntegrMgt: Codeunit AddOnIntegrManagement;
        DimensionSetIDArr: array[10] of Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertPurchOrderLine(ReqLine2, PurchOrderHeader, NextLineNo, IsHandled);
        if IsHandled then
            exit;

        with ReqLine2 do begin
            if ("No." = '') or ("Vendor No." = '') or (Quantity = 0) then
                exit;

            if CheckInsertFinalizePurchaseOrderHeader(ReqLine2, PurchOrderHeader, true) then begin
                IsHandled := false;
                OnInsertPurchOrderLineOnBeforeInsertHeader(ReqLine2, PurchOrderHeader, PurchOrderLine, LineCount, NextLineNo, IsHandled);
                if not IsHandled then begin
                    InsertHeader(ReqLine2);
                    LineCount := 0;
                    NextLineNo := 0;
                end;
                PrevPurchCode := "Purchasing Code";
                PrevShipToCode := "Ship-to Code";
                PrevLocationCode := "Location Code";
            end;

            OnInsertPurchOrderLineOnAfterCheckInsertFinalizePurchaseOrderHeader(ReqLine2, PurchOrderHeader, NextLineNo);

            LineCount := LineCount + 1;
            if not PlanningResiliency then
                if not HideProgressWindow then
                    Window.Update(4, LineCount);

            TestField("Currency Code", PurchOrderHeader."Currency Code");

            InitPurchOrderLine(PurchOrderLine, PurchOrderHeader, ReqLine2);

            AddOnIntegrMgt.TransferFromReqLineToPurchLine(PurchOrderLine, ReqLine2);
            OnInsertPurchOrderLineOnAfterTransferFromReqLineToPurchLine(PurchOrderLine, ReqLine2);

            PurchOrderLine."Drop Shipment" := "Sales Order Line No." <> 0;

            if PurchasingCode.Get("Purchasing Code") then
                if PurchasingCode."Special Order" then begin
                    PurchOrderLine."Special Order Sales No." := "Sales Order No.";
                    PurchOrderLine."Special Order Sales Line No." := "Sales Order Line No.";
                    PurchOrderLine."Special Order" := true;
                    PurchOrderLine."Drop Shipment" := false;
                    PurchOrderLine."Sales Order No." := '';
                    PurchOrderLine."Sales Order Line No." := 0;
                    PurchOrderLine."Special Order" := true;
                    PurchOrderLine.UpdateUnitCost;
                end;

            ReqLineReserve.TransferReqLineToPurchLine(ReqLine2, PurchOrderLine, "Quantity (Base)", false);

            DimensionSetIDArr[1] := PurchOrderLine."Dimension Set ID";
            DimensionSetIDArr[2] := "Dimension Set ID";
            PurchOrderLine."Dimension Set ID" :=
              DimMgt.GetCombinedDimensionSetID(
                DimensionSetIDArr, PurchOrderLine."Shortcut Dimension 1 Code", PurchOrderLine."Shortcut Dimension 2 Code");

            OnBeforePurchOrderLineInsert(PurchOrderHeader, PurchOrderLine, ReqLine2, SuppressCommit);
            PurchOrderLine.Insert();
            OnAfterPurchOrderLineInsert(PurchOrderLine, ReqLine2, NextLineNo);

            if Reserve then
                ReserveBindingOrderToPurch(PurchOrderLine, ReqLine2);

            if PurchOrderLine."Drop Shipment" or PurchOrderLine."Special Order" then begin
                SalesOrderLine.LockTable();
                SalesOrderHeader.LockTable();
                SalesOrderHeader.Get(SalesOrderHeader."Document Type"::Order, "Sales Order No.");
                CheckPurchOrderLineShipToCode(ReqLine2);
                SalesOrderLine.Get(SalesOrderLine."Document Type"::Order, "Sales Order No.", "Sales Order Line No.");
                SalesOrderLine.TestField(Type, SalesOrderLine.Type::Item);
                if SalesOrderLine."Purch. Order Line No." <> 0 then
                    Error(Text006, SalesOrderLine."No.", SalesOrderLine."Document No.", SalesOrderLine."Purchase Order No.");
                if SalesOrderLine."Special Order Purchase No." <> '' then
                    Error(Text006, SalesOrderLine."No.", SalesOrderLine."Document No.", SalesOrderLine."Special Order Purchase No.");
                if not PurchOrderLine."Special Order" then
                    TestField("Sell-to Customer No.", SalesOrderLine."Sell-to Customer No.");
                TestField(Type, SalesOrderLine.Type);

                CheckRequsitionLineQuantity(ReqLine2);
                TestField("No.", SalesOrderLine."No.");
                TestField("Location Code", SalesOrderLine."Location Code");
                TestField("Variant Code", SalesOrderLine."Variant Code");
                TestField("Bin Code", SalesOrderLine."Bin Code");
                TestField("Prod. Order No.", '');
                TestField("Qty. per Unit of Measure", "Qty. per Unit of Measure");
                OnInsertPurchOrderLineOnBeforeSalesOrderLineValidateUnitCostLCY(PurchOrderLine, SalesOrderLine);
                SalesOrderLine.Validate("Unit Cost (LCY)");

                if SalesOrderLine."Special Order" then begin
                    SalesOrderLine."Special Order Purchase No." := PurchOrderLine."Document No.";
                    SalesOrderLine."Special Order Purch. Line No." := PurchOrderLine."Line No.";
                end else begin
                    SalesOrderLine."Purchase Order No." := PurchOrderLine."Document No.";
                    SalesOrderLine."Purch. Order Line No." := PurchOrderLine."Line No.";
                end;
                SalesOrderLine.Modify();
            end;

            if TransferExtendedText.PurchCheckIfAnyExtText(PurchOrderLine, false) then begin
                TransferExtendedText.InsertPurchExtText(PurchOrderLine);
                PurchOrderLine2.SetRange("Document Type", PurchOrderHeader."Document Type");
                PurchOrderLine2.SetRange("Document No.", PurchOrderHeader."No.");
                if PurchOrderLine2.FindLast then
                    NextLineNo := PurchOrderLine2."Line No.";
            end;
        end;

        OnAfterInsertPurchOrderLine(PurchOrderLine, NextLineNo, ReqLine2, PurchOrderHeader);
    end;

    local procedure CheckRequsitionLineQuantity(var RequisitionLine: Record "Requisition Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckRequsitionLineQuantity(RequisitionLine, PurchOrderLine, SalesOrderLine, IsHandled);
        if IsHandled then
            exit;

        RequisitionLine.TestField(
            Quantity,
            Round(
                SalesOrderLine."Outstanding Quantity" * SalesOrderLine."Qty. per Unit of Measure" / RequisitionLine."Qty. per Unit of Measure",
                UOMMgt.QtyRndPrecision()));
    end;

    local procedure CheckPurchOrderLineShipToCode(var RequisitionLine: Record "Requisition Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPurchOrderLineShipToCode(RequisitionLine, PurchOrderLine, SalesOrderHeader, IsHandled);
        if IsHandled then
            exit;

        if not PurchOrderLine."Special Order" then
            RequisitionLine.TestField("Ship-to Code", SalesOrderHeader."Ship-to Code");
    end;

    local procedure InsertHeader(var ReqLine2: Record "Requisition Line")
    var
        SalesHeader: Record "Sales Header";
        Vendor: Record Vendor;
        SpecialOrder: Boolean;
    begin
        OnBeforeInsertHeader(ReqLine2, PurchOrderHeader, OrderDateReq, PostingDateReq, ReceiveDateReq, ReferenceReq);

        with ReqLine2 do begin
            OrderCounter := OrderCounter + 1;
            if not PlanningResiliency then
                if not HideProgressWindow then
                    Window.Update(3, OrderCounter);

            PurchSetup.Get();
            PurchSetup.TestField("Order Nos.");
            Clear(PurchOrderHeader);
            PurchOrderHeader.Init();
            PurchOrderHeader."Document Type" := PurchOrderHeader."Document Type"::Order;
            PurchOrderHeader."No." := '';
            PurchOrderHeader."Posting Date" := PostingDateReq;
            OnBeforePurchOrderHeaderInsert(PurchOrderHeader, ReqLine2);
            PurchOrderHeader.Insert(true);
            PurchOrderHeader."Your Reference" := ReferenceReq;
            PurchOrderHeader."Order Date" := OrderDateReq;
            PurchOrderHeader."Expected Receipt Date" := ReceiveDateReq;
            ValidateBuyFromVendorNo(PurchOrderHeader, ReqLine2);
            if "Order Address Code" <> '' then
                PurchOrderHeader.Validate("Order Address Code", "Order Address Code");

            if "Sell-to Customer No." <> '' then
                PurchOrderHeader.Validate("Sell-to Customer No.", "Sell-to Customer No.");

            PurchOrderHeader.Validate("Currency Code", "Currency Code");

            if PurchasingCode.Get("Purchasing Code") then
                if PurchasingCode."Special Order" then
                    SpecialOrder := true;

            if not SpecialOrder then
                UpdateShipToOrLocationCode(ReqLine2, PurchOrderHeader)
            else begin
                PurchOrderHeader.Validate("Location Code", "Location Code");
                PurchOrderHeader.SetShipToForSpecOrder;
                if Vendor.Get(PurchOrderHeader."Buy-from Vendor No.") then
                    PurchOrderHeader.Validate("Shipment Method Code", Vendor."Shipment Method Code");
            end;
            if not SpecialOrder then
                if SalesHeader.Get(SalesHeader."Document Type"::Order, "Sales Order No.") then begin
                    PurchOrderHeader."Ship-to Name" := SalesHeader."Ship-to Name";
                    PurchOrderHeader."Ship-to Name 2" := SalesHeader."Ship-to Name 2";
                    PurchOrderHeader."Ship-to Address" := SalesHeader."Ship-to Address";
                    PurchOrderHeader."Ship-to Address 2" := SalesHeader."Ship-to Address 2";
                    PurchOrderHeader."Ship-to Post Code" := SalesHeader."Ship-to Post Code";
                    PurchOrderHeader."Ship-to City" := SalesHeader."Ship-to City";
                    PurchOrderHeader."Ship-to Contact" := SalesHeader."Ship-to Contact";
                    PurchOrderHeader."Ship-to County" := SalesHeader."Ship-to County";
                    PurchOrderHeader."Ship-to Country/Region Code" := SalesHeader."Ship-to Country/Region Code";
                end;
            if SpecialOrder then
                if Vendor.Get(PurchOrderHeader."Buy-from Vendor No.") then
                    PurchOrderHeader."Shipment Method Code" := Vendor."Shipment Method Code";
            OnAfterInsertPurchOrderHeader(ReqLine2, PurchOrderHeader, SuppressCommit, SpecialOrder);
            PurchOrderHeader.Modify();
            PurchOrderHeader.Mark(true);
            TempDocumentEntry.Init();
            TempDocumentEntry."Table ID" := DATABASE::"Purchase Header";
            TempDocumentEntry."Document Type" := PurchOrderHeader."Document Type"::Order;
            TempDocumentEntry."Document No." := PurchOrderHeader."No.";
            TempDocumentEntry."Entry No." := TempDocumentEntry.Count + 1;
            TempDocumentEntry.Insert();
        end;
    end;

    local procedure ValidateBuyFromVendorNo(var PurchOrderHeader: Record "Purchase Header"; var RequisitionLine: Record "Requisition Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateBuyFromVendorNo(PurchOrderHeader, RequisitionLine, IsHandled);
        if not IsHandled then
            PurchOrderHeader.Validate("Buy-from Vendor No.", RequisitionLine."Vendor No.");
    end;

    local procedure UpdateShipToOrLocationCode(var RequisitionLine: Record "Requisition Line"; var PurchaseHeader: Record "Purchase Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateShipToOrLocationCode(PurchaseHeader, RequisitionLine, IsHandled);
        if IsHandled then
            exit;

        if RequisitionLine."Ship-to Code" <> '' then
            PurchaseHeader.Validate("Ship-to Code", RequisitionLine."Ship-to Code")
        else
            PurchaseHeader.Validate("Location Code", RequisitionLine."Location Code");
    end;

    procedure RunFinalizeOrderHeader(PurchOrderHeader: Record "Purchase Header"; var ReqLine: Record "Requisition Line")
    begin
        FinalizeOrderHeader(PurchOrderHeader, ReqLine);
    end;

    procedure FinalizeOrderHeader(PurchOrderHeader: Record "Purchase Header"; var ReqLine: Record "Requisition Line")
    var
        ReqLine2: Record "Requisition Line";
        IsHandled: Boolean;
    begin
        if ReqTemplate.Recurring then begin
            // Recurring journal
            ReqLine2.Copy(ReqLine);
            ReqLine2.SetRange("Vendor No.", PurchOrderHeader."Buy-from Vendor No.");
            ReqLine2.SetRange("Sell-to Customer No.", PurchOrderHeader."Sell-to Customer No.");
            ReqLine2.SetRange("Ship-to Code", PurchOrderHeader."Ship-to Code");
            ReqLine2.SetRange("Order Address Code", PurchOrderHeader."Order Address Code");
            ReqLine2.SetRange("Currency Code", PurchOrderHeader."Currency Code");
            IsHandled := false;
            OnFinalizeOrderHeaderOnAfterSetFiltersForRecurringReqLine(ReqLine2, PurchOrderHeader, IsHandled);
            if not IsHandled then begin
                ReqLine2.Find('-');
                repeat
                    OrderLineCounter := OrderLineCounter + 1;
                    if not PlanningResiliency then
                        if not HideProgressWindow then
                            Window.Update(5, OrderLineCounter);
                    if ReqLine2."Order Date" <> 0D then begin
                        ReqLine2.Validate(
                        "Order Date",
                        CalcDate(ReqLine2."Recurring Frequency", ReqLine2."Order Date"));
                        ReqLine2.Validate("Currency Code", PurchOrderHeader."Currency Code");
                    end;
                    if (ReqLine2."Recurring Method" = ReqLine2."Recurring Method"::Variable) and
                    (ReqLine2."No." <> '')
                    then begin
                        ReqLine2.Quantity := 0;
                        ReqLine2."Line Discount %" := 0;
                    end;
                    ReqLine2.Modify();
                until ReqLine2.Next() = 0;
            end;
        end else begin
            // Not a recurring journal
            OrderLineCounter := OrderLineCounter + LineCount;
            if not PlanningResiliency then
                if not HideProgressWindow then
                    Window.Update(5, OrderLineCounter);

            ReqLine2.Copy(ReqLine);
            ReqLine2.SetRange("Vendor No.", PurchOrderHeader."Buy-from Vendor No.");
            ReqLine2.SetRange("Sell-to Customer No.", PurchOrderHeader."Sell-to Customer No.");
            ReqLine2.SetRange("Ship-to Code", PurchOrderHeader."Ship-to Code");
            ReqLine2.SetRange("Order Address Code", PurchOrderHeader."Order Address Code");
            ReqLine2.SetRange("Currency Code", PurchOrderHeader."Currency Code");
            ReqLine2.SetRange("Purchasing Code", PrevPurchCode);
            IsHandled := false;
            OnFinalizeOrderHeaderOnAfterSetFiltersForNonRecurringReqLine(ReqLine2, PurchOrderHeader, IsHandled);
            if not IsHandled then
                if ReqLine2.FindSet then begin
                    ReqLine2.BlockDynamicTracking(true);
                    ReservEntry.SetCurrentKey(
                        "Source ID", "Source Ref. No.", "Source Type", "Source Subtype", "Source Batch Name", "Source Prod. Order Line");
                    repeat
                        if PurchaseOrderLineMatchReqLine(ReqLine2) then begin
                            TempFailedReqLine := ReqLine2;
                            if not TempFailedReqLine.Find then begin
                                ReqLine2.SetReservationFilters(ReservEntry);
                                ReservEntry.DeleteAll(true);
                                ReqLine2.Delete(true);
                            end;
                        end;
                    until ReqLine2.Next() = 0;
                end;
        end;
        OnAfterFinalizeOrderHeader(PurchOrderHeader, ReqLine);
        if not SuppressCommit then
            Commit();

        if PrintPurchOrders then
            if PurchOrderHeader.Get(PurchOrderHeader."Document Type", PurchOrderHeader."No.") then begin
                TempPurchaseOrderToPrint := PurchOrderHeader;
                TempPurchaseOrderToPrint.Insert();
            end;

        OnAfterFinalizeOrderHeaderProcedure(PurchOrderHeader, ReqLine);
    end;

    procedure CheckRecurringReqLine(var ReqLine2: Record "Requisition Line")
    var
        DummyDateFormula: DateFormula;
    begin
        with ReqLine2 do
            if "No." <> '' then
                if ReqTemplate.Recurring then begin
                    TestField("Recurring Method");
                    TestField("Recurring Frequency");
                    if "Recurring Method" = "Recurring Method"::Variable then
                        TestField(Quantity);
                end else begin
                    TestField("Recurring Method", 0);
                    TestField("Recurring Frequency", DummyDateFormula);
                end;
    end;

    local procedure MakeRecurringTexts(var ReqLine2: Record "Requisition Line")
    begin
        with ReqLine2 do
            if ("No." <> '') and ("Recurring Method" <> 0) and ("Order Date" <> 0D) then begin
                Day := Date2DMY("Order Date", 1);
                Week := Date2DWY("Order Date", 2);
                Month := Date2DMY("Order Date", 2);
                MonthText := Format("Order Date", 0, Text007);
                AccountingPeriod.SetRange("Starting Date", 0D, "Order Date");
                if not AccountingPeriod.FindLast then
                    AccountingPeriod.Name := '';
                Description :=
                  DelChr(
                    PadStr(
                      StrSubstNo(Description, Day, Week, Month, MonthText, AccountingPeriod.Name),
                      MaxStrLen(Description)),
                    '>');
                Modify;
            end;
    end;

    local procedure ReserveBindingOrderToPurch(var PurchLine: Record "Purchase Line"; var ReqLine: Record "Requisition Line")
    var
        ProdOrderComp: Record "Prod. Order Component";
        SalesLine: Record "Sales Line";
        ServLine: Record "Service Line";
        JobPlanningLine: Record "Job Planning Line";
        AsmLine: Record "Assembly Line";
        ProdOrderCompReserve: Codeunit "Prod. Order Comp.-Reserve";
        SalesLineReserve: Codeunit "Sales Line-Reserve";
        ServLineReserve: Codeunit "Service Line-Reserve";
        JobPlanningLineReserve: Codeunit "Job Planning Line-Reserve";
        AsmLineReserve: Codeunit "Assembly Line-Reserve";
        ReservQty: Decimal;
        ReservQtyBase: Decimal;
    begin
        PurchLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        if (PurchLine."Quantity (Base)" - PurchLine."Reserved Qty. (Base)") > ReqLine."Demand Quantity (Base)" then begin
            ReservQty := ReqLine."Demand Quantity";
            ReservQtyBase := ReqLine."Demand Quantity (Base)";
        end else begin
            ReservQty := PurchLine.Quantity - PurchLine."Reserved Quantity";
            ReservQtyBase := PurchLine."Quantity (Base)" - PurchLine."Reserved Qty. (Base)";
        end;

        case ReqLine."Demand Type" of
            DATABASE::"Prod. Order Component":
                begin
                    ProdOrderComp.Get(
                      ReqLine."Demand Subtype", ReqLine."Demand Order No.", ReqLine."Demand Line No.", ReqLine."Demand Ref. No.");
                    ProdOrderCompReserve.BindToPurchase(ProdOrderComp, PurchLine, ReservQty, ReservQtyBase);
                end;
            DATABASE::"Sales Line":
                begin
                    SalesLine.Get(ReqLine."Demand Subtype", ReqLine."Demand Order No.", ReqLine."Demand Line No.");
                    SalesLineReserve.BindToPurchase(SalesLine, PurchLine, ReservQty, ReservQtyBase);
                    if SalesLine.Reserve = SalesLine.Reserve::Never then begin
                        SalesLine.Reserve := SalesLine.Reserve::Optional;
                        SalesLine.Modify();
                    end;
                end;
            DATABASE::"Service Line":
                begin
                    ServLine.Get(ReqLine."Demand Subtype", ReqLine."Demand Order No.", ReqLine."Demand Line No.");
                    ServLineReserve.BindToPurchase(ServLine, PurchLine, ReservQty, ReservQtyBase);
                    if ServLine.Reserve = ServLine.Reserve::Never then begin
                        ServLine.Reserve := ServLine.Reserve::Optional;
                        ServLine.Modify();
                    end;
                end;
            DATABASE::"Job Planning Line":
                begin
                    JobPlanningLine.SetRange("Job Contract Entry No.", ReqLine."Demand Line No.");
                    JobPlanningLine.FindFirst;
                    JobPlanningLineReserve.BindToPurchase(JobPlanningLine, PurchLine, ReservQty, ReservQtyBase);
                    if JobPlanningLine.Reserve = JobPlanningLine.Reserve::Never then begin
                        JobPlanningLine.Reserve := JobPlanningLine.Reserve::Optional;
                        JobPlanningLine.Modify();
                    end;
                end;
            DATABASE::"Assembly Line":
                begin
                    AsmLine.Get(ReqLine."Demand Subtype", ReqLine."Demand Order No.", ReqLine."Demand Line No.");
                    AsmLineReserve.BindToPurchase(AsmLine, PurchLine, ReservQty, ReservQtyBase);
                    if AsmLine.Reserve = AsmLine.Reserve::Never then begin
                        AsmLine.Reserve := AsmLine.Reserve::Optional;
                        AsmLine.Modify();
                    end;
                end;
        end;
        PurchLine.Modify();

        OnAfterReserveBindingOrderToPurch(PurchLine, ReqLine, ReservQty, ReservQtyBase, SuppressCommit);
    end;

    procedure SetTryParam(TryReqTemplate: Record "Req. Wksh. Template"; TryLineCount: Integer; TryNextLineNo: Integer; TryPrevPurchCode: Code[10]; TryPrevShipToCode: Code[10]; TryPrevLocationCode: Code[10]; TryOrderCounter: Integer; TryOrderLineCounter: Integer; var TryFailedReqLine: Record "Requisition Line"; var TempDocumentEntryNew: Record "Document Entry" temporary)
    begin
        SetPlanningResiliency;
        ReqTemplate := TryReqTemplate;
        LineCount := TryLineCount;
        NextLineNo := TryNextLineNo;
        PrevPurchCode := TryPrevPurchCode;
        PrevShipToCode := TryPrevShipToCode;
        PrevLocationCode := TryPrevLocationCode;
        OrderCounter := TryOrderCounter;
        OrderLineCounter := TryOrderLineCounter;
        TempDocumentEntry.Copy(TempDocumentEntryNew, true);
        if TryFailedReqLine.Find('-') then
            repeat
                TempFailedReqLine := TryFailedReqLine;
                if TempFailedReqLine.Insert() then;
            until TryFailedReqLine.Next() = 0;
    end;

    procedure GetTryParam(var TryPurchOrderHeader: Record "Purchase Header"; var TryLineCount: Integer; var TryNextLineNo: Integer; var TryPrevPurchCode: Code[10]; var TryPrevShipToCode: Code[10]; var TryPrevLocationCode: Code[10]; var TryOrderCounter: Integer; var TryOrderLineCounter: Integer)
    begin
        TryPurchOrderHeader.Copy(PurchOrderHeader);
        TryLineCount := LineCount;
        TryNextLineNo := NextLineNo;
        TryPrevPurchCode := PrevPurchCode;
        TryPrevShipToCode := PrevShipToCode;
        TryPrevLocationCode := PrevLocationCode;
        TryOrderCounter := OrderCounter;
        TryOrderLineCounter := OrderLineCounter;
    end;

    procedure SetFailedReqLine(var TryFailedReqLine: Record "Requisition Line")
    begin
        TempFailedReqLine := TryFailedReqLine;
        TempFailedReqLine.Insert();
    end;

    procedure SetPlanningResiliency()
    begin
        PlanningResiliency := true;
    end;

    procedure GetFailedCounter(): Integer
    begin
        exit(CounterFailed);
    end;

    local procedure PrintTransOrder(TransferHeader: Record "Transfer Header")
    var
        CarryOutAction: Codeunit "Carry Out Action";
    begin
        if TransferHeader."No." <> '' then begin
            CarryOutAction.SetPrintOrder(PrintPurchOrders);
            CarryOutAction.PrintTransferOrder(TransferHeader);
        end;
    end;

    local procedure PrintChangedDocument(OrderType: Option; var OrderNo: Code[20])
    var
        DummyReqLine: Record "Requisition Line";
        TransferHeader: Record "Transfer Header";
        PurchaseHeader: Record "Purchase Header";
        CarryOutAction: Codeunit "Carry Out Action";
    begin
        CarryOutAction.SetPrintOrder(PrintPurchOrders);
        case OrderType of
            DummyReqLine."Ref. Order Type"::Transfer:
                begin
                    TransferHeader.Get(OrderNo);
                    PrintTransOrder(TransferHeader);
                end;
            DummyReqLine."Ref. Order Type"::Purchase:
                begin
                    PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, OrderNo);
                    PrintPurchOrder(PurchaseHeader);
                end;
        end;
        OrderNo := '';
    end;

    local procedure PrintPurchOrder(PurchHeader: Record "Purchase Header")
    var
        CarryOutAction: Codeunit "Carry Out Action";
    begin
        if PurchHeader."No." <> '' then begin
            CarryOutAction.SetPrintOrder(PrintPurchOrders);
            CarryOutAction.PrintPurchaseOrder(PurchHeader);
        end;
    end;

    local procedure PrintMultiplePurchaseOrders()
    var
        PurchaseHeader: Record "Purchase Header";
        CarryOutAction: Codeunit "Carry Out Action";
    begin
        if TempPurchaseOrderToPrint.Count() = 1 then begin
            TempPurchaseOrderToPrint.FindFirst();
            PurchaseHeader.Get(TempPurchaseOrderToPrint."Document Type", TempPurchaseOrderToPrint."No.");
            PrintPurchOrder(PurchaseHeader);
        end else begin
            CarryOutAction.SetPrintOrder(PrintPurchOrders);
            CarryOutAction.PrintMultiplePurchaseOrders(TempPurchaseOrderToPrint);
        end;
    end;

    local procedure ProcessReqLineActions(var ReqLine: Record "Requisition Line")
    begin
        OnBeforeProcessReqLineActions(ReqLine, SuppressCommit, PlanningResiliency);

        with ReqLine do
            if Find('-') then
                repeat
                    if not PlanningResiliency then
                        CarryOutReqLineAction(ReqLine)
                    else
                        if not TryCarryOutReqLineAction(ReqLine) then begin
                            SetFailedReqLine(ReqLine);
                            OnProcessReqLineActionsOnAfterSetFailedReqLine(ReqLine);
                            CounterFailed := CounterFailed + 1;
                        end;
                until Next() = 0;
    end;

    local procedure SetPurchOrderHeader()
    begin
        PurchOrderHeader."Order Date" := OrderDateReq;
        PurchOrderHeader."Posting Date" := PostingDateReq;
        PurchOrderHeader."Expected Receipt Date" := ReceiveDateReq;
        PurchOrderHeader."Your Reference" := ReferenceReq;
        OnAfterSetPurchOrderHeader(PurchOrderHeader);
    end;

    local procedure SetReqLineSortingKey(var RequisitionLine: Record "Requisition Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetReqLineSortingKey(RequisitionLine, IsHandled);
        if IsHandled then
            exit;

        with RequisitionLine do
            SetCurrentKey(
              "Worksheet Template Name", "Journal Batch Name", "Vendor No.",
              "Sell-to Customer No.", "Ship-to Code", "Order Address Code", "Currency Code",
              "Ref. Order Type", "Ref. Order Status", "Ref. Order No.",
              "Transfer-from Code", "Purchasing Code");
    end;

    procedure CheckAddressDetails(SalesOrderNo: Code[20]; SalesLineNo: Integer; UpdateAddressDetails: Boolean) Result: Boolean
    var
        SalesLine: Record "Sales Line";
        Purchasing: Record Purchasing;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckAddressDetails(SalesOrderNo, SalesLineNo, UpdateAddressDetails, Result, IsHandled);
        if IsHandled then
            exit;

        if SalesLine.Get(SalesLine."Document Type"::Order, SalesOrderNo, SalesLineNo) then
            if Purchasing.Get(SalesLine."Purchasing Code") then
                case true of
                    Purchasing."Drop Shipment":
                        Result :=
                          not CheckDropShptAddressDetails(SalesOrderNo, UpdateAddressDetails);
                    Purchasing."Special Order":
                        Result :=
                          not CheckSpecOrderAddressDetails(SalesLine."Location Code", UpdateAddressDetails);
                end;
    end;

    local procedure CheckLocation(RequisitionLine: Record "Requisition Line")
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        if InventorySetup."Location Mandatory" then
            RequisitionLine.TestField("Location Code");
    end;

    local procedure CheckInsertFinalizePurchaseOrderHeader(RequisitionLine: Record "Requisition Line"; var PurchOrderHeader: Record "Purchase Header"; UpdateAddressDetails: Boolean): Boolean
    var
        CheckInsert: Boolean;
        CheckAddressDetailsResult: Boolean;
    begin
        CheckAddressDetailsResult := CheckAddressDetails(RequisitionLine."Sales Order No.", RequisitionLine."Sales Order Line No.", UpdateAddressDetails);
        with RequisitionLine do
            CheckInsert :=
              (PurchOrderHeader."Buy-from Vendor No." <> "Vendor No.") or
              (PurchOrderHeader."Sell-to Customer No." <> "Sell-to Customer No.") or
              (PrevShipToCode <> "Ship-to Code") or
              (PurchOrderHeader."Order Address Code" <> "Order Address Code") or
              (PurchOrderHeader."Currency Code" <> "Currency Code") or
              (PrevPurchCode <> "Purchasing Code") or
              CheckAddressDetailsResult;

        OnBeforeCheckInsertFinalizePurchaseOrderHeader(RequisitionLine, PurchOrderHeader, CheckInsert, OrderCounter, PrevPurchCode, PrevLocationCode, PrevShipToCode, UpdateAddressDetails, CheckAddressDetailsResult);
        exit(CheckInsert);
    end;

    local procedure CheckDropShptAddressDetails(SalesNo: Code[20]; UpdateAddressDetails: Boolean): Boolean
    var
        SalesHeader: Record "Sales Header";
        DropShptNameAddressDetails: Text;
    begin
        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesNo);
        DropShptNameAddressDetails :=
          SalesHeader."Ship-to Name" + SalesHeader."Ship-to Name 2" +
          SalesHeader."Ship-to Address" + SalesHeader."Ship-to Address 2" +
          SalesHeader."Ship-to Post Code" + SalesHeader."Ship-to City" +
          SalesHeader."Ship-to Contact";
        if NameAddressDetails = '' then
            NameAddressDetails := DropShptNameAddressDetails;
        if NameAddressDetails = DropShptNameAddressDetails then
            exit(true);

        if UpdateAddressDetails then
            NameAddressDetails := DropShptNameAddressDetails;
        exit(false);
    end;

    local procedure CheckSpecOrderAddressDetails(LocationCode: Code[10]; UpdateAddressDetails: Boolean): Boolean
    var
        Location: Record Location;
        CompanyInfo: Record "Company Information";
        SpecOrderNameAddressDetails: Text;
    begin
        if Location.Get(LocationCode) then
            SpecOrderNameAddressDetails :=
              Location.Name + Location."Name 2" +
              Location.Address + Location."Address 2" +
              Location."Post Code" + Location.City +
              Location.Contact
        else begin
            CompanyInfo.Get();
            SpecOrderNameAddressDetails :=
              CompanyInfo."Ship-to Name" + CompanyInfo."Ship-to Name 2" +
              CompanyInfo."Ship-to Address" + CompanyInfo."Ship-to Address 2" +
              CompanyInfo."Ship-to Post Code" + CompanyInfo."Ship-to City" +
              CompanyInfo."Ship-to Contact";
        end;
        if NameAddressDetails = '' then
            NameAddressDetails := SpecOrderNameAddressDetails;
        if NameAddressDetails = SpecOrderNameAddressDetails then
            exit(true);

        if UpdateAddressDetails then
            NameAddressDetails := SpecOrderNameAddressDetails;
        exit(false);
    end;

    local procedure InitShipReceiveDetails()
    begin
        PrevShipToCode := '';
        PrevPurchCode := '';
        PrevLocationCode := '';
        NameAddressDetails := '';
    end;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    procedure PurchaseOrderLineMatchReqLine(ReqLine: Record "Requisition Line"): Boolean
    begin
        if PurchOrderLine."Drop Shipment" then
            exit(
              (ReqLine."Sales Order No." = PurchOrderLine."Sales Order No.") and
              (ReqLine."Sales Order Line No." = PurchOrderLine."Sales Order Line No."));

        if PurchOrderLine."Special Order" then
            exit(
              (ReqLine."Sales Order No." = PurchOrderLine."Special Order Sales No.") and
              (ReqLine."Sales Order Line No." = PurchOrderLine."Special Order Sales Line No."));

        exit(true);
    end;

    local procedure GetTransferHeader(var TransferHeader: Record "Transfer Header"; RequisitionLine: Record "Requisition Line")
    begin
        TempTransHeader.SetRange("Transfer-from Code", RequisitionLine."Transfer-from Code");
        TempTransHeader.SetRange("Transfer-to Code", RequisitionLine."Location Code");
        if TempTransHeader.FindFirst() then
            TransferHeader.Get(TempTransHeader."No.");
    end;

    local procedure SetTransferHeader(TransferHeader: Record "Transfer Header")
    begin
        TempTransHeader := TransferHeader;
        if TempTransHeader.Insert() then;
    end;

    local procedure InitProgressWindow()
    begin
        if ReqTemplate.Recurring then
            Window.Open(
              Text000 +
              Text001 +
              Text002 +
              Text003 +
              Text004)
        else
            Window.Open(
              Text000 +
              Text001 +
              Text002 +
              Text003 +
              Text005);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCode(var ReqLine: Record "Requisition Line"; PlanningResiliency: Boolean; SuppressCommit: Boolean; PrintPurchOrders: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCarryOutBatchActionCode(var RequisitionLine: Record "Requisition Line"; var ReqLine2: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCarryOutReqLineAction(var RequisitionLine: Record "Requisition Line"; var Failed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPurchOrderLineShipToCode(var RequisitionLine: Record "Requisition Line"; PurchOrderLine: Record "Purchase Line"; SalesOrderHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteReqLines(var ReqLine: Record "Requisition Line"; var TempFailedReqLine: Record "Requisition Line" temporary; var IsHandled: Boolean; var ReqLine2: Record "Requisition Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetReqTemplate(RequisitionLine: Record "Requisition Line"; var ReqWkshTemplate: Record "Req. Wksh. Template"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertHeader(RequisitionLine: Record "Requisition Line"; PurchaseHeader: Record "Purchase Header"; var OrderDateReq: Date; var PostingDateReq: Date; var ReceiveDateReq: Date; var ReferenceReq: Text[35])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertPurchOrderLine(var RequisitionLine: Record "Requisition Line"; var PurchaseHeader: Record "Purchase Header"; var NextLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessReqLineActions(var RequisitionLine: Record "Requisition Line"; CommitIsSuppressed: Boolean; PlanningResiliency: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchOrderLineInsert(var PurchOrderHeader: Record "Purchase Header"; var PurchOrderLine: Record "Purchase Line"; var ReqLine: Record "Requisition Line"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchOrderHeaderInsert(var PurchaseHeader: Record "Purchase Header"; RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchOrderLineValidateNo(var PurchOrderLine: Record "Purchase Line"; var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchOrderLineValidateType(var PurchOrderLine: Record "Purchase Line"; var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckInsertFinalizePurchaseOrderHeader(RequisitionLine: Record "Requisition Line"; var PurchaseHeader: Record "Purchase Header"; var CheckInsert: Boolean; var OrderCounter: Integer; var PrevPurchCode: Code[10]; PrevLocationCode: Code[10]; var PrevShipToCode: Code[10]; var UpdateAddressDetails: Boolean; var CheckAddressDetailsResult: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetReqLineSortingKey(var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestFieldsForPurchase(var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCode(var RequisitionLine: Record "Requisition Line"; OrderLineCounter: Integer; OrderCounter: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchOrderLineInsert(var PurchOrderLine: Record "Purchase Line"; var RequisitionLine: Record "Requisition Line"; var NextLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCarryOutReqLineAction(var RequisitionLine: Record "Requisition Line"; var PurchaseHeader: Record "Purchase Header"; CommitIsSuppressed: Boolean; var OrderCounter: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReserveBindingOrderToPurch(var PurchaseLine: Record "Purchase Line"; var ReqLine: Record "Requisition Line"; ReservQty: Decimal; ReservQtyBase: Decimal; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSet(NewPurchOrderHeader: Record "Purchase Header"; CommitIsSuppressed: Boolean; EndingOrderDate: Date; PrintPurchOrder: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckReqWkshLine(var RequisitionLine: Record "Requisition Line"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitPurchOrderLine(var PurchaseLine: Record "Purchase Line"; RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertPurchOrderHeader(var RequisitionLine: Record "Requisition Line"; var PurchaseOrderHeader: Record "Purchase Header"; CommitIsSuppressed: Boolean; SpecialOrder: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertPurchOrderLine(var PurchOrderLine: Record "Purchase Line"; var NextLineNo: Integer; var RequisitionLine: Record "Requisition Line"; var PurchOrderHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFinalizeOrderHeader(var PurchHeader: Record "Purchase Header"; var ReqLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFinalizeOrderHeaderProcedure(var PurchHeader: Record "Purchase Header"; var ReqLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchOrderLineValidateNo(var PurchOrderLine: Record "Purchase Line"; var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetPurchOrderHeader(var PurchOrderHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateShipToOrLocationCode(var PurchOrderHeader: Record "Purchase Header"; var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckRequisitionLines(var RequisitionLine: Record "Requisition Line"; var StartLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitPurchOrderLineUpdateQuantity(var PurchOrderLine: Record "Purchase Line"; var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeOnRun(var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateBuyFromVendorNo(var PurchOrderHeader: Record "Purchase Header"; var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCarryOutReqLineActionOnCaseReplenishmentSystemElse(var ReqLine: Record "Requisition Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCarryOutReqLineActionOnAfterInsertTransLine(TransHeader: Record "Transfer Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckNewNameNeccessary(RequisitionWkshName: Record "Requisition Wksh. Name"; var NewReqWkshName: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckFurtherReplenishmentSystems(var RequisitionLine2: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterReqLine3SetFilters(ReqLine: Record "Requisition Line"; var ReqLine3: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCodeOnBeforeFinalizeOrderHeader(PurchOrderHeader: Record "Purchase Header"; var ReqLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinalizeOrderHeaderOnAfterSetFiltersForRecurringReqLine(var RequisitionLine: Record "Requisition Line"; PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnFinalizeOrderHeaderOnAfterSetFiltersForNonRecurringReqLine(var RequisitionLine: Record "Requisition Line"; PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitPurchOrderLineOnAfterPurchOrderLineAssignVariantCode(var PurchOrderLine: Record "Purchase Line"; var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitPurchOrderLineOnAfterValidateLineDiscount(var PurchOrderLine: Record "Purchase Line"; PurchOrderHeader: Record "Purchase Header"; RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitPurchOrderLineOnBeforeValidateLineDiscount(var PurchOrderLine: Record "Purchase Line"; PurchOrderHeader: Record "Purchase Header"; RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertPurchOrderLineOnAfterCheckInsertFinalizePurchaseOrderHeader(var RequisitionLine: Record "Requisition Line"; var PurchaseHeader: Record "Purchase Header"; var NextLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertPurchOrderLineOnAfterTransferFromReqLineToPurchLine(var PurchOrderLine: Record "Purchase Line"; RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertPurchOrderLineOnBeforeInsertHeader(var RequisitionLine: Record "Requisition Line"; var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var LineCount: Integer; var NextLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertPurchOrderLineOnBeforeSalesOrderLineValidateUnitCostLCY(var PurchOrderLine: Record "Purchase Line"; var SalesOrderLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessReqLineActionsOnAfterSetFailedReqLine(var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeInitProgressWindow(ReqTemplate: Record "Req. Wksh. Template"; var HideProgressWindow: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckAddressDetails(SalesOrderNo: Code[20]; SalesLineNo: Integer; UpdateAddressDetails: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckRequisitionLine(var ReqLine2: Record "Requisition Line"; SuppressCommit: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckRequsitionLineQuantity(var RequisitionLine: Record "Requisition Line"; var PurchOrderLine: Record "Purchase Line"; var SalesOrderLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckRequisitionLineOnNonCancelActionMessageOnBeforeCheckQuantity(var ReqLine2: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckRequisitionLineOnEmptyNewActionMessageOnBeforeOtherCheck(var ReqLine2: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;
}

