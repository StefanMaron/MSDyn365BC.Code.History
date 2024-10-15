namespace Microsoft.Warehouse.Activity;

using Microsoft.Assembly.Document;
using Microsoft.Assembly.Setup;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Availability;
using Microsoft.Warehouse.Comment;
using Microsoft.Warehouse.InternalDocument;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Tracking;
using Microsoft.Warehouse.Worksheet;
using System.Telemetry;

codeunit 7322 "Create Inventory Pick/Movement"
{
    Permissions = TableData "Whse. Item Tracking Line" = rimd;
    TableNo = "Warehouse Activity Header";

    trigger OnRun()
    begin
        OnBeforeOnRun(Rec);
        CurrWarehouseActivityHeader := Rec;
        Code();
        Rec := CurrWarehouseActivityHeader;
    end;

    var
        CurrWarehouseRequest: Record "Warehouse Request";
        CurrWarehouseActivityHeader: Record "Warehouse Activity Header";
        CurrLocation: Record Location;
        CurrItem: Record Item;
        CurrBin: Record Bin;
        CurrStockKeepingUnit: Record "Stockkeeping Unit";
        CurrPurchaseHeader: Record "Purchase Header";
        CurrSalesHeader: Record "Sales Header";
        CurrTransferHeader: Record "Transfer Header";
        CurrProductionOrder: Record "Production Order";
        CurrAssemblyHeader: Record "Assembly Header";
        CurrJob: Record Job;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        TempInternalMovementLine: Record "Internal Movement Line" temporary;
        TempReservationEntry: Record "Reservation Entry" temporary;
        WarehouseSourceFilter: Record "Warehouse Source Filter";
        WMSManagement: Codeunit "WMS Management";
        ItemTrackingManagement: Codeunit "Item Tracking Management";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        SourceDocRecordRef: RecordRef;
        ReservedFromStock: Enum "Reservation From Stock";
        WarehouseClassCode: Code[10];
        VendorDocNo: Code[35];
        FromBinCode: Code[20];
        ExpiredItemMessageText: Text[100];
        PostingDate: Date;
        NextLineNo: Integer;
        LastTempHandlingSpecNo: Integer;
        ATOInvtMovementsCreated: Integer;
        TotalATOInvtMovementsToBeCreated: Integer;
        HideDialog: Boolean;
        CheckLineExist: Boolean;
        AutoCreation: Boolean;
        LineCreated: Boolean;
        CompleteShipment: Boolean;
        PrintDocument: Boolean;
        ShowError: Boolean;
        IsInvtMovement: Boolean;
        IsBlankInvtMovement: Boolean;
        ApplyAdditionalSourceDocFilters: Boolean;
        HasExpiredItems: Boolean;
        SuppressCommit: Boolean;
        NothingToHandleErr: Label 'There is nothing to handle.';
        QtyNotSufficientOnSalesErr: Label 'Quantity available to pick is not sufficient to fulfill shipping advise %1 for sales line with Document Type %2, Document No. %3, Line No. %4.', Comment = '%1=Shipping advise no., %2=Document Type, %3=Document No., %4=Line No.';
        QtyNotSufficientOnTransferErr: Label 'Quantity available to pick is not sufficient to fulfill shipping advise %1 for transfer line with Document No. %2, Line No. %3.', Comment = '%1=Shipping advise no., %2=Document No., %3=Line No.';
        ActivityCreatedMsg: Label '%1 activity number %2 has been created.', Comment = '%1=Warehouse Activity Type,%2=Warehouse Activity number';
        TrackingNotFullyAppliedMsg: Label '%1 activity number %2 has been created.\\Item tracking lines cannot be fully applied.', Comment = '%1=Warehouse Activity Type,%2=Warehouse Activity No.';
        CreateInvtMvmtQst: Label 'Do you want to create Inventory Movement?';
        BinPolicyTelemetryCategoryTok: Label 'Bin Policy', Locked = true;
        DefaultBinPickPolicyTelemetryTok: Label 'Default Bin Pick Policy in used for inventory pick.', Locked = true;
        RankingBinPickPolicyTelemetryTok: Label 'Bin Ranking Bin Pick Policy in used for inventory pick.', Locked = true;
        ProdAsmJobWhseHandlingTelemetryCategoryTok: Label 'Prod/Asm/Job Whse. Handling', Locked = true;
        ProdAsmJobWhseHandlingTelemetryTok: Label 'Prod/Asm/Job Whse. Handling in used for warehouse pick.', Locked = true;

    local procedure "Code"()
    var
        IsHandled: Boolean;
        SuppressMessage: Boolean;
    begin
        CurrWarehouseActivityHeader.TestField("No.");
        CurrWarehouseActivityHeader.TestField("Location Code");

        if not HideDialog then
            if not GetWhseRequest(CurrWarehouseRequest) then
                exit;

        IsHandled := false;
        OnBeforeCreatePickOrMoveLines(CurrWarehouseRequest, CurrWarehouseActivityHeader, LineCreated, IsHandled, HideDialog, IsInvtMovement, IsBlankInvtMovement, CompleteShipment);
        if IsHandled then
            exit;

        if not GetSourceDocHeader() then
            exit;

        UpdateWhseActivHeader(CurrWarehouseRequest);

        case CurrWarehouseRequest."Source Document" of
            CurrWarehouseRequest."Source Document"::"Purchase Order":
                CreatePickOrMoveFromPurchase(CurrPurchaseHeader);
            CurrWarehouseRequest."Source Document"::"Purchase Return Order":
                CreatePickOrMoveFromPurchase(CurrPurchaseHeader);
            CurrWarehouseRequest."Source Document"::"Sales Order":
                CreatePickOrMoveFromSales(CurrSalesHeader);
            CurrWarehouseRequest."Source Document"::"Sales Return Order":
                CreatePickOrMoveFromSales(CurrSalesHeader);
            CurrWarehouseRequest."Source Document"::"Outbound Transfer":
                CreatePickOrMoveFromTransfer(CurrTransferHeader);
            CurrWarehouseRequest."Source Document"::"Prod. Consumption":
                CreatePickOrMoveFromProduction(CurrProductionOrder);
            CurrWarehouseRequest."Source Document"::"Assembly Consumption":
                CreatePickOrMoveFromAssembly(CurrAssemblyHeader);
            CurrWarehouseRequest."Source Document"::"Job Usage":
                CreatePickOrMoveFromJobPlanning(CurrJob);
            else
                OnCreatePickOrMoveFromWhseRequest(
                    CurrWarehouseRequest, SourceDocRecordRef, LineCreated, CurrWarehouseActivityHeader, CurrLocation, HideDialog, CompleteShipment, CheckLineExist);
        end;

        SuppressMessage := false;
        IsHandled := false;
        OnCodeOnAfterCreatePickOrMoveLines(CurrWarehouseRequest, CurrWarehouseActivityHeader, LineCreated, AutoCreation, SuppressMessage, IsHandled);
        if IsHandled then
            exit;

        if LineCreated then
            ModifyWarehouseActivityHeader(CurrWarehouseActivityHeader, CurrWarehouseRequest)
        else
            if not AutoCreation then
                if not SuppressMessage then
                    Message(NothingToHandleErr + ExpiredItemMessageText);

        OnAfterCreateInventoryPickMovement(CurrWarehouseRequest, LineCreated, CurrWarehouseActivityHeader);
    end;

    local procedure ModifyWarehouseActivityHeader(var WarehouseActivityHeader: Record "Warehouse Activity Header"; WarehouseRequest: Record "Warehouse Request")
    begin
        OnBeforeModifyWarehouseActivityHeader(WarehouseActivityHeader, WarehouseRequest, CurrLocation);
        WarehouseActivityHeader.Modify();
    end;

    local procedure GetWhseRequest(var WarehouseRequest: Record "Warehouse Request") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        with WarehouseRequest do begin
            FilterGroup := 2;
            SetRange(Type, Type::Outbound);
            SetRange("Location Code", CurrWarehouseActivityHeader."Location Code");
            SetRange("Document Status", "Document Status"::Released);
            if CurrWarehouseActivityHeader."Source Document" <> CurrWarehouseActivityHeader."Source Document"::" " then
                SetRange("Source Document", CurrWarehouseActivityHeader."Source Document")
            else
                if CurrWarehouseActivityHeader.Type = CurrWarehouseActivityHeader.Type::"Invt. Movement" then
                    SetFilter("Source Document", '%1|%2|%3|%4',
                      CurrWarehouseActivityHeader."Source Document"::"Prod. Consumption",
                      CurrWarehouseActivityHeader."Source Document"::"Prod. Output",
                      CurrWarehouseActivityHeader."Source Document"::"Assembly Consumption",
                      CurrWarehouseActivityHeader."Source Document"::"Job Usage");
            if CurrWarehouseActivityHeader."Source No." <> '' then
                SetRange("Source No.", CurrWarehouseActivityHeader."Source No.");
            SetRange("Completely Handled", false);
            FilterGroup := 0;

            IsHandled := false;
            OnGetWhseRequestOnBeforeSourceDocumentsRun(WarehouseRequest, CurrWarehouseActivityHeader, Result, IsHandled);
            if IsHandled then
                exit(Result);

            if PAGE.RunModal(PAGE::"Source Documents", WarehouseRequest, "Source No.") = ACTION::LookupOK then
                exit(true);
        end;
    end;

    local procedure GetSourceDocHeader(): Boolean
    var
        IsHandled: Boolean;
        RecordExists: Boolean;
    begin
        IsHandled := false;
        RecordExists := true;
        OnBeforeGetSourceDocHeader(CurrWarehouseRequest, IsHandled, RecordExists);
        if IsHandled then
            exit(RecordExists);

        case CurrWarehouseRequest."Source Document" of
            CurrWarehouseRequest."Source Document"::"Purchase Order":
                begin
                    RecordExists := CurrPurchaseHeader.Get(CurrPurchaseHeader."Document Type"::Order, CurrWarehouseRequest."Source No.");
                    PostingDate := CurrPurchaseHeader."Posting Date";
                    VendorDocNo := CurrPurchaseHeader."Vendor Invoice No.";
                end;
            CurrWarehouseRequest."Source Document"::"Purchase Return Order":
                begin
                    RecordExists := CurrPurchaseHeader.Get(CurrPurchaseHeader."Document Type"::"Return Order", CurrWarehouseRequest."Source No.");
                    PostingDate := CurrPurchaseHeader."Posting Date";
                    VendorDocNo := CurrPurchaseHeader."Vendor Cr. Memo No.";
                end;
            CurrWarehouseRequest."Source Document"::"Sales Order":
                begin
                    RecordExists := CurrSalesHeader.Get(CurrSalesHeader."Document Type"::Order, CurrWarehouseRequest."Source No.");
                    PostingDate := CurrSalesHeader."Posting Date";
                end;
            CurrWarehouseRequest."Source Document"::"Sales Return Order":
                begin
                    RecordExists := CurrSalesHeader.Get(CurrSalesHeader."Document Type"::"Return Order", CurrWarehouseRequest."Source No.");
                    PostingDate := CurrSalesHeader."Posting Date";
                end;
            CurrWarehouseRequest."Source Document"::"Outbound Transfer":
                begin
                    RecordExists := CurrTransferHeader.Get(CurrWarehouseRequest."Source No.");
                    PostingDate := CurrTransferHeader."Posting Date";
                end;
            CurrWarehouseRequest."Source Document"::"Prod. Consumption":
                begin
                    RecordExists := CurrProductionOrder.Get(CurrWarehouseRequest."Source Subtype", CurrWarehouseRequest."Source No.");
                    PostingDate := WorkDate();
                end;
            CurrWarehouseRequest."Source Document"::"Assembly Consumption":
                begin
                    RecordExists := CurrAssemblyHeader.Get(CurrWarehouseRequest."Source Subtype", CurrWarehouseRequest."Source No.");
                    PostingDate := CurrAssemblyHeader."Posting Date";
                end;
            CurrWarehouseRequest."Source Document"::"Job Usage":
                RecordExists := CurrJob.Get(CurrWarehouseRequest."Source No.");
            else
                OnGetSourceDocHeaderFromWhseRequest(CurrWarehouseRequest, SourceDocRecordRef, PostingDate, VendorDocNo, RecordExists);
        end;
        OnAfterGetSourceDocHeader(CurrWarehouseRequest, PostingDate, VendorDocNo);

        exit(RecordExists);
    end;

    local procedure UpdateWhseActivHeader(WarehouseRequest: Record "Warehouse Request")
    begin
        with WarehouseRequest do begin
            if CurrWarehouseActivityHeader."Source Document" = CurrWarehouseActivityHeader."Source Document"::" " then begin
                CurrWarehouseActivityHeader."Source Document" := "Source Document";
                CurrWarehouseActivityHeader."Source Type" := "Source Type";
                CurrWarehouseActivityHeader."Source Subtype" := "Source Subtype";
            end else
                CurrWarehouseActivityHeader.TestField("Source Document", "Source Document");
            if CurrWarehouseActivityHeader."Source No." = '' then
                CurrWarehouseActivityHeader."Source No." := "Source No."
            else
                CurrWarehouseActivityHeader.TestField("Source No.", "Source No.");

            CurrWarehouseActivityHeader."Destination Type" := "Destination Type";
            CurrWarehouseActivityHeader."Destination No." := "Destination No.";
            CurrWarehouseActivityHeader."External Document No." := "External Document No.";
            CurrWarehouseActivityHeader."Shipment Date" := "Shipment Date";
            CurrWarehouseActivityHeader."Posting Date" := PostingDate;
            CurrWarehouseActivityHeader."External Document No.2" := VendorDocNo;
            GetLocation("Location Code");
        end;

        OnAfterUpdateWhseActivHeader(CurrWarehouseActivityHeader, WarehouseRequest, CurrLocation);
    end;

    procedure SetSourceDocDetailsFilter(var WarehouseSourceFilter2: Record "Warehouse Source Filter")
    begin
        if WarehouseSourceFilter2.GetFilters() <> '' then begin
            ApplyAdditionalSourceDocFilters := true;
            WarehouseSourceFilter.Reset();
            WarehouseSourceFilter.CopyFilters(WarehouseSourceFilter2);
        end;
    end;

    local procedure CreatePickOrMoveFromPurchase(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        NewWarehouseActivityLine: Record "Warehouse Activity Line";
        RemQtyToPickBase: Decimal;
        IsHandled: Boolean;
    begin
        with PurchaseLine do begin
            if not SetFilterPurchLine(PurchaseLine, PurchaseHeader) then begin
                if not HideDialog then
                    Message(NothingToHandleErr);
                exit;
            end;

            FindNextLineNo();

            repeat
                IsHandled := false;
                OnBeforeCreatePickOrMoveLineFromPurchaseLoop(CurrWarehouseActivityHeader, PurchaseHeader, IsHandled, PurchaseLine);

                if not IsHandled and IsInventoriableItem() and CanPickPurchaseLine(PurchaseLine) then
                    if not NewWarehouseActivityLine.ActivityExists(Database::"Purchase Line", "Document Type", "Document No.", "Line No.", 0, 0) then begin
                        NewWarehouseActivityLine.Init();
                        NewWarehouseActivityLine."Activity Type" := CurrWarehouseActivityHeader.Type;
                        NewWarehouseActivityLine."No." := CurrWarehouseActivityHeader."No.";
                        if CurrLocation."Bin Mandatory" then
                            NewWarehouseActivityLine."Action Type" := NewWarehouseActivityLine."Action Type"::Take;
                        NewWarehouseActivityLine.SetSource(Database::"Purchase Line", "Document Type", "Document No.", "Line No.", 0);
                        NewWarehouseActivityLine."Location Code" := "Location Code";
                        NewWarehouseActivityLine."Bin Code" := "Bin Code";
                        NewWarehouseActivityLine."Item No." := "No.";
                        NewWarehouseActivityLine."Variant Code" := "Variant Code";
                        NewWarehouseActivityLine."Unit of Measure Code" := "Unit of Measure Code";
                        NewWarehouseActivityLine."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
                        NewWarehouseActivityLine."Qty. Rounding Precision" := "Qty. Rounding Precision";
                        NewWarehouseActivityLine."Qty. Rounding Precision (Base)" := "Qty. Rounding Precision (Base)";
                        NewWarehouseActivityLine.Description := Description;
                        NewWarehouseActivityLine."Description 2" := "Description 2";
                        NewWarehouseActivityLine."Due Date" := "Expected Receipt Date";
                        NewWarehouseActivityLine."Destination Type" := NewWarehouseActivityLine."Destination Type"::Vendor;
                        NewWarehouseActivityLine."Destination No." := PurchaseHeader."Buy-from Vendor No.";
                        if "Document Type" = "Document Type"::Order then begin
                            NewWarehouseActivityLine."Source Document" := NewWarehouseActivityLine."Source Document"::"Purchase Order";
                            RemQtyToPickBase := -"Qty. to Receive (Base)";
                        end else begin
                            NewWarehouseActivityLine."Source Document" :=
                              NewWarehouseActivityLine."Source Document"::"Purchase Return Order";
                            RemQtyToPickBase := "Return Qty. to Ship (Base)";
                        end;
                        OnBeforeNewWhseActivLineInsertFromPurchase(NewWarehouseActivityLine, PurchaseLine, CurrWarehouseActivityHeader, RemQtyToPickBase);
                        CalcFields("Reserved Quantity");
                        CreatePickOrMoveLine(
                          NewWarehouseActivityLine, RemQtyToPickBase, "Outstanding Qty. (Base)", "Reserved Quantity" <> 0);
                    end;
            until Next() = 0;
        end;
    end;

    local procedure SetFilterPurchLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"): Boolean
    begin
        if CurrLocation.RequireShipment(CurrWarehouseRequest."Location Code") then
            exit(false);

        PurchaseLine.SetCurrentKey("Document Type", "Document No.", "Location Code");
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Drop Shipment", false);
        if not CheckLineExist then
            PurchaseLine.SetRange("Location Code", CurrWarehouseActivityHeader."Location Code");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Order then
            PurchaseLine.SetFilter("Qty. to Receive", '<%1', 0)
        else
            PurchaseLine.SetFilter("Return Qty. to Ship", '>%1', 0);

        if ApplyAdditionalSourceDocFilters then begin
            PurchaseLine.SetFilter("No.", WarehouseSourceFilter.GetFilter("Item No. Filter"));
            PurchaseLine.SetFilter("Variant Code", WarehouseSourceFilter.GetFilter("Variant Code Filter"));
            PurchaseLine.SetFilter("Planned Receipt Date", WarehouseSourceFilter.GetFilter("Shipment Date Filter"));
        end;

        OnBeforeFindPurchLine(PurchaseLine, PurchaseHeader, CurrWarehouseActivityHeader);
        exit(PurchaseLine.Find('-'));
    end;

    local procedure CreatePickOrMoveFromSales(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        NewWarehouseActivityLine: Record "Warehouse Activity Line";
        RemQtyToPickBase: Decimal;
        IsHandled: Boolean;
    begin
        OnBeforeCreatePickOrMoveFromSales(CurrWarehouseActivityHeader, SalesHeader, AutoCreation, HideDialog, SalesLine);
        with SalesLine do begin
            if not SetFilterSalesLine(SalesLine, SalesHeader) then begin
                if not HideDialog then
                    Message(NothingToHandleErr);
                exit;
            end;
            CompleteShipment := true;

            FindNextLineNo();

            repeat
                IsHandled := false;
                OnBeforeCreatePickOrMoveLineFromSalesLoop(CurrWarehouseActivityHeader, SalesHeader, IsHandled, SalesLine);
                if not IsHandled and CanPickSalesLine(SalesLine) then
                    if not NewWarehouseActivityLine.ActivityExists(Database::"Sales Line", "Document Type", "Document No.", "Line No.", 0, 0) then begin
                        NewWarehouseActivityLine.Init();
                        NewWarehouseActivityLine."Activity Type" := CurrWarehouseActivityHeader.Type;
                        NewWarehouseActivityLine."No." := CurrWarehouseActivityHeader."No.";
                        if CurrLocation."Bin Mandatory" then
                            NewWarehouseActivityLine."Action Type" := NewWarehouseActivityLine."Action Type"::Take;
                        NewWarehouseActivityLine.SetSource(Database::"Sales Line", "Document Type", "Document No.", "Line No.", 0);
                        NewWarehouseActivityLine."Location Code" := "Location Code";
                        NewWarehouseActivityLine."Bin Code" := "Bin Code";
                        NewWarehouseActivityLine."Item No." := "No.";
                        NewWarehouseActivityLine."Variant Code" := "Variant Code";
                        NewWarehouseActivityLine."Unit of Measure Code" := "Unit of Measure Code";
                        NewWarehouseActivityLine."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
                        NewWarehouseActivityLine."Qty. Rounding Precision" := "Qty. Rounding Precision";
                        NewWarehouseActivityLine."Qty. Rounding Precision (Base)" := "Qty. Rounding Precision (Base)";
                        NewWarehouseActivityLine.Description := Description;
                        NewWarehouseActivityLine."Description 2" := "Description 2";
                        NewWarehouseActivityLine."Due Date" := "Planned Shipment Date";
                        NewWarehouseActivityLine."Shipping Advice" := SalesHeader."Shipping Advice";
                        NewWarehouseActivityLine."Shipping Agent Code" := "Shipping Agent Code";
                        NewWarehouseActivityLine."Shipping Agent Service Code" := "Shipping Agent Service Code";
                        NewWarehouseActivityLine."Shipment Method Code" := SalesHeader."Shipment Method Code";
                        NewWarehouseActivityLine."Destination Type" := NewWarehouseActivityLine."Destination Type"::Customer;
                        NewWarehouseActivityLine."Destination No." := SalesHeader."Sell-to Customer No.";

                        if "Document Type" = "Document Type"::Order then begin
                            NewWarehouseActivityLine."Source Document" := NewWarehouseActivityLine."Source Document"::"Sales Order";
                            RemQtyToPickBase := "Qty. to Ship (Base)";
                        end else begin
                            NewWarehouseActivityLine."Source Document" := NewWarehouseActivityLine."Source Document"::"Sales Return Order";
                            RemQtyToPickBase := -"Return Qty. to Receive (Base)";
                        end;
                        OnBeforeNewWhseActivLineInsertFromSales(NewWarehouseActivityLine, SalesLine, CurrWarehouseActivityHeader, RemQtyToPickBase);
                        CalcFields("Reserved Quantity");
                        CreatePickOrMoveLine(
                          NewWarehouseActivityLine, RemQtyToPickBase, "Outstanding Qty. (Base)", "Reserved Quantity" <> 0);
                        OnCreatePickOrMoveFromSalesOnAfterCreatePickOrMoveLine(NewWarehouseActivityLine, SalesLine, CurrWarehouseActivityHeader, ShowError, AutoCreation, LineCreated);

                        if SalesHeader."Shipping Advice" = SalesHeader."Shipping Advice"::Complete then begin
                            if RemQtyToPickBase < 0 then begin
                                if AutoCreation then begin
                                    if CurrWarehouseActivityHeader.Delete(true) then
                                        LineCreated := false;
                                    exit;
                                end;
                                Error(QtyNotSufficientOnSalesErr, SalesHeader."Shipping Advice", "Document Type", "Document No.", "Line No.");
                            end;
                            if (RemQtyToPickBase = 0) and not CompleteShipment then begin
                                if ShowError then
                                    Error(QtyNotSufficientOnSalesErr, SalesHeader."Shipping Advice", "Document Type", "Document No.", "Line No.");
                                if CurrWarehouseActivityHeader.Delete(true) then;
                                LineCreated := false;
                                exit;
                            end;
                        end;
                    end;
            until Next() = 0;
        end;
        OnAfterCreatePickOrMoveFromSales(CurrWarehouseActivityHeader, AutoCreation, HideDialog, LineCreated, IsInvtMovement, IsBlankInvtMovement);
    end;

    local procedure CanPickSalesLine(var SalesLine: Record "Sales Line"): Boolean
    begin
        exit(
          SalesLine.CheckIfSalesLineMeetsReservedFromStockSetting(Abs(SalesLine."Outstanding Qty. (Base)"), ReservedFromStock));
    end;

    local procedure CanPickPurchaseLine(var PurchaseLine: Record "Purchase Line"): Boolean
    begin
        exit(
          PurchaseLine.CheckIfPurchaseLineMeetsReservedFromStockSetting(Abs(PurchaseLine."Outstanding Qty. (Base)"), ReservedFromStock));
    end;

    local procedure CanPickTransferLine(var TransferLine: Record "Transfer Line"): Boolean
    begin
        exit(
          TransferLine.CheckIfTransferLineMeetsReservedFromStockSetting(TransferLine."Outstanding Qty. (Base)", ReservedFromStock));
    end;

    local procedure CanPickProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"): Boolean
    begin
        exit(
          ProdOrderComponent.CheckIfProdOrderCompMeetsReservedFromStockSetting(Abs(ProdOrderComponent."Remaining Qty. (Base)"), ReservedFromStock));
    end;

    local procedure CanPickAssemblyLine(var AssemblyLine: Record "Assembly Line"): Boolean
    begin
        exit(
          AssemblyLine.CheckIfAssemblyLineMeetsReservedFromStockSetting(AssemblyLine."Remaining Quantity (Base)", ReservedFromStock));
    end;

    local procedure CanPickJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"): Boolean
    begin
        exit(
          JobPlanningLine.CheckIfJobPlngLineMeetsReservedFromStockSetting(JobPlanningLine."Remaining Qty. (Base)", ReservedFromStock));
    end;

    local procedure SetFilterSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header") Result: Boolean
    begin
        if CurrLocation.RequireShipment(CurrWarehouseRequest."Location Code") then
            exit(false);

        with SalesLine do begin
            SetCurrentKey("Document Type", "Document No.", "Location Code");
            SetRange("Document Type", SalesHeader."Document Type");
            SetRange("Document No.", SalesHeader."No.");
            SetRange("Drop Shipment", false);

            if not CheckLineExist then
                SetRange("Location Code", CurrWarehouseActivityHeader."Location Code");
            SetRange(Type, Type::Item);
            if SalesHeader."Document Type" = SalesHeader."Document Type"::Order then
                SetFilter("Qty. to Ship", '>%1', 0)
            else
                SetFilter("Return Qty. to Receive", '<%1', 0);

            if ApplyAdditionalSourceDocFilters then begin
                SetFilter("No.", WarehouseSourceFilter.GetFilter("Item No. Filter"));
                SetFilter("Variant Code", WarehouseSourceFilter.GetFilter("Variant Code Filter"));
                SetFilter("Shipment Date", WarehouseSourceFilter.GetFilter("Shipment Date Filter"));
            end;

            OnBeforeFindSalesLine(SalesLine, SalesHeader, CurrWarehouseActivityHeader, CurrWarehouseRequest, CheckLineExist);
            Result := Find('-');
        end;
        OnAfterSetFilterSalesLine(SalesLine, SalesHeader, CurrWarehouseActivityHeader, CurrWarehouseRequest, ShowError, Result);
    end;

    local procedure CreatePickOrMoveFromTransfer(TransferHeader: Record "Transfer Header")
    var
        TransferLine: Record "Transfer Line";
        NewWarehouseActivityLine: Record "Warehouse Activity Line";
        RemQtyToPickBase: Decimal;
        IsHandled: Boolean;
    begin
        with TransferLine do begin
            if not SetFilterTransferLine(TransferLine, TransferHeader) then begin
                if not HideDialog then
                    Message(NothingToHandleErr);
                exit;
            end;
            CompleteShipment := true;

            FindNextLineNo();

            repeat
                IsHandled := false;
                OnBeforeCreatePickOrMoveLineFromTransferLoop(CurrWarehouseActivityHeader, TransferHeader, IsHandled, TransferLine);
                if not IsHandled and CanPickTransferLine(TransferLine) then
                    if not NewWarehouseActivityLine.ActivityExists(Database::"Transfer Line", 0, "Document No.", "Line No.", 0, 0) then begin
                        NewWarehouseActivityLine.Init();
                        NewWarehouseActivityLine."Activity Type" := CurrWarehouseActivityHeader.Type;
                        NewWarehouseActivityLine."No." := CurrWarehouseActivityHeader."No.";
                        if CurrLocation."Bin Mandatory" then
                            NewWarehouseActivityLine."Action Type" := NewWarehouseActivityLine."Action Type"::Take;
                        NewWarehouseActivityLine.SetSource(Database::"Transfer Line", 0, "Document No.", "Line No.", 0);
                        NewWarehouseActivityLine."Source Document" := NewWarehouseActivityLine."Source Document"::"Outbound Transfer";
                        NewWarehouseActivityLine."Location Code" := "Transfer-from Code";
                        NewWarehouseActivityLine."Bin Code" := "Transfer-from Bin Code";
                        NewWarehouseActivityLine."Item No." := "Item No.";
                        NewWarehouseActivityLine."Variant Code" := "Variant Code";
                        NewWarehouseActivityLine."Unit of Measure Code" := "Unit of Measure Code";
                        NewWarehouseActivityLine."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
                        NewWarehouseActivityLine."Qty. Rounding Precision" := "Qty. Rounding Precision";
                        NewWarehouseActivityLine."Qty. Rounding Precision (Base)" := "Qty. Rounding Precision (Base)";
                        NewWarehouseActivityLine.Description := Description;
                        NewWarehouseActivityLine."Description 2" := "Description 2";
                        NewWarehouseActivityLine."Due Date" := "Shipment Date";
                        NewWarehouseActivityLine."Shipping Advice" := TransferHeader."Shipping Advice";
                        NewWarehouseActivityLine."Shipping Agent Code" := "Shipping Agent Code";
                        NewWarehouseActivityLine."Shipping Agent Service Code" := "Shipping Agent Service Code";
                        NewWarehouseActivityLine."Shipment Method Code" := TransferHeader."Shipment Method Code";
                        NewWarehouseActivityLine."Destination Type" := NewWarehouseActivityLine."Destination Type"::Location;
                        NewWarehouseActivityLine."Destination No." := TransferHeader."Transfer-to Code";
                        RemQtyToPickBase := "Qty. to Ship (Base)";
                        OnBeforeNewWhseActivLineInsertFromTransfer(NewWarehouseActivityLine, TransferLine, CurrWarehouseActivityHeader, RemQtyToPickBase);
                        CalcFields("Reserved Quantity Outbnd.");
                        CreatePickOrMoveLine(
                          NewWarehouseActivityLine, RemQtyToPickBase, "Outstanding Qty. (Base)", "Reserved Quantity Outbnd." <> 0);
                        OnCreatePickOrMoveFromTransferOnAfterCreatePickOrMoveLine(NewWarehouseActivityLine, TransferLine, CurrWarehouseActivityHeader, ShowError, AutoCreation, LineCreated);

                        if TransferHeader."Shipping Advice" = TransferHeader."Shipping Advice"::Complete then begin
                            if RemQtyToPickBase > 0 then begin
                                if AutoCreation then begin
                                    CurrWarehouseActivityHeader.Delete(true);
                                    LineCreated := false;
                                    exit;
                                end;
                                Error(QtyNotSufficientOnTransferErr, TransferHeader."Shipping Advice", "Document No.", "Line No.");
                            end;
                            if (RemQtyToPickBase = 0) and not CompleteShipment then begin
                                if ShowError then
                                    Error(QtyNotSufficientOnTransferErr, TransferHeader."Shipping Advice", "Document No.", "Line No.");
                                if CurrWarehouseActivityHeader.Delete(true) then;
                                LineCreated := false;
                                exit;
                            end;
                        end;
                    end;
            until Next() = 0;
        end;
        OnAfterCreatePickOrMoveFromTransfer(CurrWarehouseActivityHeader, TransferHeader, TransferLine);
    end;

    local procedure SetFilterTransferLine(var TransferLine: Record "Transfer Line"; TransferHeader: Record "Transfer Header"): Boolean
    begin
        if CurrLocation.RequireShipment(CurrWarehouseRequest."Location Code") then
            exit(false);

        with TransferLine do begin
            SetRange("Document No.", TransferHeader."No.");
            SetRange("Derived From Line No.", 0);
            if not CheckLineExist then
                SetRange("Transfer-from Code", CurrWarehouseActivityHeader."Location Code");
            SetFilter("Qty. to Ship", '>%1', 0);

            if ApplyAdditionalSourceDocFilters then begin
                SetFilter("Item No.", WarehouseSourceFilter.GetFilter("Item No. Filter"));
                SetFilter("Variant Code", WarehouseSourceFilter.GetFilter("Variant Code Filter"));
                SetFilter("Shipment Date", WarehouseSourceFilter.GetFilter("Shipment Date Filter"));
            end;

            OnBeforeFindTransLine(TransferLine, TransferHeader, CurrWarehouseActivityHeader);
            exit(Find('-'));
        end;
    end;

    local procedure CreatePickOrMoveFromProduction(ProductionOrder: Record "Production Order")
    var
        ProdOrderComponent: Record "Prod. Order Component";
        NewWarehouseActivityLine: Record "Warehouse Activity Line";
        RemQtyToPickBase: Decimal;
        IsHandled: Boolean;
    begin
        with ProdOrderComponent do begin
            if not SetFilterProductionLine(ProdOrderComponent, ProductionOrder) then begin
                if not HideDialog then
                    Message(NothingToHandleErr);
                exit;
            end;

            FindNextLineNo();

            repeat
                if (ProdOrderComponent."Location Code" = '') or (CurrLocation."Prod. Consump. Whse. Handling" = CurrLocation."Prod. Consump. Whse. Handling"::"Inventory Pick/Movement") then begin
                    if CurrLocation."Prod. Consump. Whse. Handling" = CurrLocation."Prod. Consump. Whse. Handling"::"Inventory Pick/Movement" then
                        FeatureTelemetry.LogUsage('0000KT2', ProdAsmJobWhseHandlingTelemetryCategoryTok, ProdAsmJobWhseHandlingTelemetryTok);

                    IsHandled := false;
                    OnBeforeCreatePickOrMoveLineFromProductionLoop(CurrWarehouseActivityHeader, ProductionOrder, IsHandled, ProdOrderComponent);
                    if not IsHandled and CanPickProdOrderComponent(ProdOrderComponent) then
                        if not
                           NewWarehouseActivityLine.ActivityExists(
                            Database::"Prod. Order Component", Status, "Prod. Order No.", "Prod. Order Line No.", "Line No.", 0)
                        then begin
                            NewWarehouseActivityLine.Init();
                            NewWarehouseActivityLine."Activity Type" := CurrWarehouseActivityHeader.Type;
                            NewWarehouseActivityLine."No." := CurrWarehouseActivityHeader."No.";
                            if CurrLocation."Bin Mandatory" then
                                NewWarehouseActivityLine."Action Type" := NewWarehouseActivityLine."Action Type"::Take;
                            NewWarehouseActivityLine.SetSource(Database::"Prod. Order Component", Status, "Prod. Order No.", "Prod. Order Line No.", "Line No.");
                            NewWarehouseActivityLine."Location Code" := "Location Code";
                            NewWarehouseActivityLine."Bin Code" := "Bin Code";
                            NewWarehouseActivityLine."Item No." := "Item No.";
                            NewWarehouseActivityLine."Variant Code" := "Variant Code";
                            NewWarehouseActivityLine."Unit of Measure Code" := "Unit of Measure Code";
                            NewWarehouseActivityLine."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
                            NewWarehouseActivityLine."Qty. Rounding Precision" := "Qty. Rounding Precision";
                            NewWarehouseActivityLine."Qty. Rounding Precision (Base)" := "Qty. Rounding Precision (Base)";
                            NewWarehouseActivityLine.Description := Description;
                            NewWarehouseActivityLine."Source Document" := NewWarehouseActivityLine."Source Document"::"Prod. Consumption";
                            NewWarehouseActivityLine."Due Date" := "Due Date";
                            if CurrWarehouseActivityHeader.Type = CurrWarehouseActivityHeader.Type::"Invt. Pick" then
                                RemQtyToPickBase := "Remaining Qty. (Base)"
                            else
                                RemQtyToPickBase := "Expected Qty. (Base)" - "Qty. Picked (Base)";
                            OnBeforeNewWhseActivLineInsertFromComp(NewWarehouseActivityLine, ProdOrderComponent, CurrWarehouseActivityHeader, RemQtyToPickBase);
                            CalcFields("Reserved Quantity");
                            CreatePickOrMoveLine(
                                NewWarehouseActivityLine, RemQtyToPickBase, RemQtyToPickBase, "Reserved Quantity" <> 0);
                        end;
                end;
            until Next() = 0;
        end;
    end;

    local procedure CreatePickOrMoveFromAssembly(AssemblyHeader: Record "Assembly Header")
    var
        AssemblyLine: Record "Assembly Line";
        NewWarehouseActivityLine: Record "Warehouse Activity Line";
        RemQtyToPickBase: Decimal;
        IsHandled: Boolean;
    begin
        with AssemblyLine do begin
            if not SetFilterAssemblyLine(AssemblyLine, AssemblyHeader) then begin
                if not HideDialog then
                    Message(NothingToHandleErr);
                exit;
            end;

            if CurrWarehouseActivityHeader.Type <> CurrWarehouseActivityHeader.Type::"Invt. Movement" then // no support for inventory pick on assembly
                exit;

            FindNextLineNo();

            repeat
                if (AssemblyLine."Location Code" = '') or (CurrLocation."Asm. Consump. Whse. Handling" = CurrLocation."Asm. Consump. Whse. Handling"::"Inventory Movement") then begin
                    if CurrLocation."Asm. Consump. Whse. Handling" = CurrLocation."Asm. Consump. Whse. Handling"::"Inventory Movement" then
                        FeatureTelemetry.LogUsage('0000KT3', ProdAsmJobWhseHandlingTelemetryCategoryTok, ProdAsmJobWhseHandlingTelemetryTok);
                    IsHandled := false;
                    OnBeforeCreatePickOrMoveLineFromAssemblyLoop(CurrWarehouseActivityHeader, AssemblyHeader, IsHandled, AssemblyLine);
                    if not IsHandled and CanPickAssemblyLine(AssemblyLine) then
                        if not
                           NewWarehouseActivityLine.ActivityExists(Database::"Assembly Line", "Document Type", "Document No.", "Line No.", 0, 0)
                        then begin
                            NewWarehouseActivityLine.Init();
                            NewWarehouseActivityLine."Activity Type" := CurrWarehouseActivityHeader.Type;
                            NewWarehouseActivityLine."No." := CurrWarehouseActivityHeader."No.";
                            if CurrLocation."Bin Mandatory" then
                                NewWarehouseActivityLine."Action Type" := NewWarehouseActivityLine."Action Type"::Take;
                            NewWarehouseActivityLine.SetSource(Database::"Assembly Line", "Document Type", "Document No.", "Line No.", 0);
                            NewWarehouseActivityLine."Location Code" := "Location Code";
                            NewWarehouseActivityLine."Bin Code" := "Bin Code";
                            NewWarehouseActivityLine."Item No." := "No.";
                            NewWarehouseActivityLine."Variant Code" := "Variant Code";
                            NewWarehouseActivityLine."Unit of Measure Code" := "Unit of Measure Code";
                            NewWarehouseActivityLine."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
                            NewWarehouseActivityLine."Qty. Rounding Precision" := "Qty. Rounding Precision";
                            NewWarehouseActivityLine."Qty. Rounding Precision (Base)" := "Qty. Rounding Precision (Base)";
                            NewWarehouseActivityLine.Description := Description;
                            NewWarehouseActivityLine."Source Document" := NewWarehouseActivityLine."Source Document"::"Assembly Consumption";
                            NewWarehouseActivityLine."Due Date" := "Due Date";
                            NewWarehouseActivityLine."Destination Type" := NewWarehouseActivityLine."Destination Type"::Item;
                            NewWarehouseActivityLine."Destination No." := CurrAssemblyHeader."Item No.";
                            RemQtyToPickBase := "Quantity (Base)" - "Remaining Quantity (Base)" +
                            "Quantity to Consume (Base)" - "Qty. Picked (Base)";
                            OnBeforeNewWhseActivLineInsertFromAssembly(NewWarehouseActivityLine, AssemblyLine, CurrWarehouseActivityHeader, RemQtyToPickBase);
                            CalcFields("Reserved Quantity");
                            CreatePickOrMoveLine(NewWarehouseActivityLine, RemQtyToPickBase, RemQtyToPickBase, "Reserved Quantity" <> 0);
                        end;
                end;
            until Next() = 0;
        end;
    end;

    local procedure CreatePickOrMoveFromJobPlanning(Job: Record Job)
    var
        JobPlanningLine: Record "Job Planning Line";
        NewWarehouseActivityLine: Record "Warehouse Activity Line";
        PickItem: Record Item;
        RemQtyToPickBase: Decimal;
    begin
        if not SetFilterJobPlanningLine(JobPlanningLine, Job) then begin
            if not HideDialog then
                Message(NothingToHandleErr);
            exit;
        end;

        FindNextLineNo();

        repeat
            if (JobPlanningLine."Location Code" = '') or (CurrLocation."Job Consump. Whse. Handling" = CurrLocation."Job Consump. Whse. Handling"::"Inventory Pick") then begin
                if CurrLocation."Job Consump. Whse. Handling" = CurrLocation."Job Consump. Whse. Handling"::"Inventory Pick" then
                    FeatureTelemetry.LogUsage('0000KT4', ProdAsmJobWhseHandlingTelemetryCategoryTok, ProdAsmJobWhseHandlingTelemetryTok);
                if PickItem.Get(JobPlanningLine."No.") then
                    if PickItem.IsInventoriableType() and CanPickJobPlanningLine(JobPlanningLine) then
                        if not
                           NewWarehouseActivityLine.ActivityExists(Database::Job, 0, JobPlanningLine."Job No.", JobPlanningLine."Job Contract Entry No.", JobPlanningLine."Line No.", 0)
                        then begin
                            NewWarehouseActivityLine.Init();
                            NewWarehouseActivityLine."Activity Type" := CurrWarehouseActivityHeader.Type;
                            NewWarehouseActivityLine."No." := CurrWarehouseActivityHeader."No.";
                            if CurrLocation."Bin Mandatory" then
                                NewWarehouseActivityLine."Action Type" := NewWarehouseActivityLine."Action Type"::Take;
                            NewWarehouseActivityLine.SetSource(Database::Job, 0, JobPlanningLine."Job No.", JobPlanningLine."Job Contract Entry No.", JobPlanningLine."Line No.");
                            NewWarehouseActivityLine."Location Code" := JobPlanningLine."Location Code";
                            NewWarehouseActivityLine."Bin Code" := JobPlanningLine."Bin Code";
                            NewWarehouseActivityLine."Item No." := JobPlanningLine."No.";
                            NewWarehouseActivityLine."Variant Code" := JobPlanningLine."Variant Code";
                            NewWarehouseActivityLine."Unit of Measure Code" := JobPlanningLine."Unit of Measure Code";
                            NewWarehouseActivityLine."Qty. per Unit of Measure" := JobPlanningLine."Qty. per Unit of Measure";
                            NewWarehouseActivityLine."Qty. Rounding Precision" := JobPlanningLine."Qty. Rounding Precision";
                            NewWarehouseActivityLine."Qty. Rounding Precision (Base)" := JobPlanningLine."Qty. Rounding Precision (Base)";
                            NewWarehouseActivityLine.Description := JobPlanningLine.Description;
                            NewWarehouseActivityLine."Description 2" := JobPlanningLine."Description 2";
                            NewWarehouseActivityLine."Source Document" := NewWarehouseActivityLine."Source Document"::"Job Usage";
                            NewWarehouseActivityLine."Due Date" := JobPlanningLine."Planning Due Date";
                            NewWarehouseActivityLine."Destination Type" := NewWarehouseActivityLine."Destination Type"::Customer;
                            Job.Get(JobPlanningLine."Job No.");
                            NewWarehouseActivityLine."Destination No." := Job."Sell-to Customer No.";
                            JobPlanningLine.CalcFields("Reserved Quantity");
                            RemQtyToPickBase := JobPlanningLine."Remaining Qty. (Base)";
                            CreatePickOrMoveLine(NewWarehouseActivityLine, RemQtyToPickBase, JobPlanningLine."Remaining Qty. (Base)", JobPlanningLine."Reserved Quantity" <> 0);
                        end;
            end;
        until JobPlanningLine.Next() = 0;
    end;

    local procedure SetFilterProductionLine(var ProdOrderComponent: Record "Prod. Order Component"; ProductionOrder: Record "Production Order"): Boolean
    begin
        ProdOrderComponent.SetRange(ProdOrderComponent.Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange(ProdOrderComponent."Prod. Order No.", ProductionOrder."No.");
        if not CheckLineExist then
            ProdOrderComponent.SetRange(ProdOrderComponent."Location Code", CurrWarehouseActivityHeader."Location Code");
        ProdOrderComponent.SetRange(ProdOrderComponent."Planning Level Code", 0);
        if IsInvtMovement then begin
            ProdOrderComponent.SetFilter(ProdOrderComponent."Bin Code", '<>%1', '');
            ProdOrderComponent.SetFilter(ProdOrderComponent."Flushing Method", '%1|%2|%3',
              ProdOrderComponent."Flushing Method"::Manual,
              ProdOrderComponent."Flushing Method"::"Pick + Forward",
              ProdOrderComponent."Flushing Method"::"Pick + Backward");
        end else
            ProdOrderComponent.SetRange(ProdOrderComponent."Flushing Method", ProdOrderComponent."Flushing Method"::Manual);
        ProdOrderComponent.SetFilter(ProdOrderComponent."Remaining Quantity", '>0');

        if ApplyAdditionalSourceDocFilters then begin
            ProdOrderComponent.SetFilter(ProdOrderComponent."Item No.", WarehouseSourceFilter.GetFilter("Item No. Filter"));
            ProdOrderComponent.SetFilter(ProdOrderComponent."Variant Code", WarehouseSourceFilter.GetFilter("Variant Code Filter"));
            ProdOrderComponent.SetFilter(ProdOrderComponent."Due Date", WarehouseSourceFilter.GetFilter("Shipment Date Filter"));
            ProdOrderComponent.SetFilter(ProdOrderComponent."Prod. Order Line No.", WarehouseSourceFilter.GetFilter("Prod. Order Line No. Filter"));
        end;

        OnBeforeFindProdOrderComp(ProdOrderComponent, ProductionOrder, CurrWarehouseActivityHeader);
        exit(ProdOrderComponent.Find('-'));
    end;

    local procedure SetFilterAssemblyLine(var AssemblyLine: Record "Assembly Line"; AssemblyHeader: Record "Assembly Header"): Boolean
    begin
        AssemblyLine.SetRange(AssemblyLine."Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange(AssemblyLine."Document No.", AssemblyHeader."No.");
        AssemblyLine.SetRange(AssemblyLine.Type, AssemblyLine.Type::Item);
        if not CheckLineExist then
            AssemblyLine.SetRange(AssemblyLine."Location Code", CurrWarehouseActivityHeader."Location Code");
        if IsInvtMovement then
            AssemblyLine.SetFilter(AssemblyLine."Bin Code", '<>%1', '');
        AssemblyLine.SetFilter(AssemblyLine."Remaining Quantity", '>0');

        if ApplyAdditionalSourceDocFilters then begin
            AssemblyLine.SetFilter(AssemblyLine."No.", WarehouseSourceFilter.GetFilter("Item No. Filter"));
            AssemblyLine.SetFilter(AssemblyLine."Variant Code", WarehouseSourceFilter.GetFilter("Variant Code Filter"));
            AssemblyLine.SetFilter(AssemblyLine."Due Date", WarehouseSourceFilter.GetFilter("Shipment Date Filter"));
        end;

        OnBeforeFindAssemblyLine(AssemblyLine, CurrAssemblyHeader, CurrWarehouseActivityHeader);
        exit(AssemblyLine.Find('-'));
    end;

    local procedure SetFilterJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; Job: Record Job): Boolean
    begin
        JobPlanningLine.SetLoadFields(
            "Job No.",
            "Job Contract Entry No.",
            "Line No.",
            "Document No.",
            "Location Code",
            "Bin Code",
            "No.",
            "Variant Code",
            "Unit of Measure Code",
            "Qty. per Unit of Measure",
            "Qty. Rounding Precision",
            "Qty. Rounding Precision (Base)",
            Description,
            "Planning Due Date",
            "Job Task No.",
            "Reserved Quantity",
            "Remaining Qty. (Base)",
            "Reserved Quantity"
        );
        JobPlanningLine.SetRange("Job No.", Job."No.");
        JobPlanningLine.SetRange(Type, JobPlanningLine.Type::Item);


        if not CheckLineExist then
            JobPlanningLine.SetRange("Location Code", CurrWarehouseActivityHeader."Location Code");
        if IsInvtMovement then
            JobPlanningLine.SetFilter("Bin Code", '<>%1', '');
        JobPlanningLine.SetFilter("Remaining Qty.", '>0');

        if ApplyAdditionalSourceDocFilters then begin
            JobPlanningLine.SetFilter("Job Task No.", WarehouseSourceFilter.GetFilter("Job Task No. Filter"));
            JobPlanningLine.SetFilter("No.", WarehouseSourceFilter.GetFilter("Item No. Filter"));
            JobPlanningLine.SetFilter("Variant Code", WarehouseSourceFilter.GetFilter("Variant Code Filter"));
            JobPlanningLine.SetFilter("Planning Date", WarehouseSourceFilter.GetFilter("Shipment Date Filter"));
        end;

        OnSetFilterJobPlanningLineOnBeforeJobPlanningLineFind(JobPlanningLine, Job, CurrWarehouseActivityHeader);
        exit(JobPlanningLine.Find('-'));
    end;

    procedure FindNextLineNo()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        if IsInvtMovement then
            WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Invt. Movement")
        else
            WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Invt. Pick");
        WarehouseActivityLine.SetRange("No.", CurrWarehouseActivityHeader."No.");
        if WarehouseActivityLine.FindLast() then
            NextLineNo := WarehouseActivityLine."Line No." + 10000
        else
            NextLineNo := 10000;
    end;

    procedure RunCreatePickOrMoveLine(NewWarehouseActivityLine: Record "Warehouse Activity Line"; var RemQtyToPickBase: Decimal; OutstandingQtyBase: Decimal; ReservationExists: Boolean)
    begin
        OnBeforeRunCreatePickOrMoveLine(CurrWarehouseActivityHeader, CurrWarehouseRequest);
        CreatePickOrMoveLine(NewWarehouseActivityLine, RemQtyToPickBase, OutstandingQtyBase, ReservationExists);
        OnAfterRunCreatePickOrMoveLine(CurrWarehouseActivityHeader, CurrWarehouseRequest);
    end;

    local procedure CreatePickOrMoveLine(NewWarehouseActivityLine: Record "Warehouse Activity Line"; var RemQtyToPickBase: Decimal; OutstandingQtyBase: Decimal; ReservationExists: Boolean)
    var
        ReservationEntry: Record "Reservation Entry";
        ATOSalesLine: Record "Sales Line";
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        ItemTrackingManagement: Codeunit "Item Tracking Management";
        QtyAvailToPickBase: Decimal;
        OriginalRemQtyToPickBase: Decimal;
        QtyRemToPickBase: Decimal;
        ITQtyToPickBase: Decimal;
        TotalITQtyToPickBase: Decimal;
        QtyToTrackBase: Decimal;
        EntriesExist: Boolean;
        ShouldInsertPickOrMoveDefaultBin: Boolean;
        IsHandled: Boolean;
    begin
        if ReservationExists then
            CalcRemQtyToPickOrMoveBase(NewWarehouseActivityLine, OutstandingQtyBase, RemQtyToPickBase);
        if RemQtyToPickBase <= 0 then
            exit;

        HasExpiredItems := false;
        OriginalRemQtyToPickBase := RemQtyToPickBase;

        QtyAvailToPickBase := CalcInvtAvailability(NewWarehouseActivityLine, WhseItemTrackingSetup);
        if WMSManagement.GetATOSalesLine(
             NewWarehouseActivityLine."Source Type", NewWarehouseActivityLine."Source Subtype", NewWarehouseActivityLine."Source No.",
             NewWarehouseActivityLine."Source Line No.", ATOSalesLine)
        then
            QtyAvailToPickBase += ATOSalesLine.QtyToAsmBaseOnATO();

        IsHandled := false;
        OnCreatePickOrMoveLineOnAfterCalcQtyAvailToPickBase(
            NewWarehouseActivityLine, WhseItemTrackingSetup."Serial No. Required", WhseItemTrackingSetup."Lot No. Required",
            ReservationExists, RemQtyToPickBase, QtyAvailToPickBase, IsHandled);
        if not IsHandled then
            if RemQtyToPickBase > QtyAvailToPickBase then begin
                IsHandled := false;
                OnCreatePickOrMoveLineOnAfterCheckForCompleteShipment(CurrWarehouseActivityHeader, WhseItemTrackingSetup, ReservationExists, RemQtyToPickBase, QtyAvailToPickBase, IsHandled);
                if not IsHandled then
                    RemQtyToPickBase := QtyAvailToPickBase;
                CompleteShipment := false;
            end;

        if RemQtyToPickBase > 0 then begin
            if ItemTrackingManagement.GetWhseItemTrkgSetup(NewWarehouseActivityLine."Item No.", WhseItemTrackingSetup) then begin
                OnCreatePickOrMoveLineOnAfterGetWhseItemTrkgSetup(NewWarehouseActivityLine, WhseItemTrackingSetup);
                if IsBlankInvtMovement then
                    ItemTrackingManagement.SumUpItemTrackingOnlyInventoryOrATO(TempReservationEntry, TempTrackingSpecification, true, true)
                else begin
                    SetFilterReservEntry(ReservationEntry, NewWarehouseActivityLine);
                    CopyReservEntriesToTemp(TempReservationEntry, ReservationEntry);
                    if IsInvtMovement then
                        PrepareItemTrackingFromWhse(
                          NewWarehouseActivityLine."Source Type", NewWarehouseActivityLine."Source Subtype", NewWarehouseActivityLine."Source No.",
                          '', NewWarehouseActivityLine."Source Line No.", 1, false);
                    ItemTrackingManagement.SumUpItemTrackingOnlyInventoryOrATO(TempReservationEntry, TempTrackingSpecification, true, true);
                end;

                if PickOrMoveAccordingToFEFO(NewWarehouseActivityLine."Location Code", WhseItemTrackingSetup) or
                   PickStrictExpirationPosting(NewWarehouseActivityLine."Item No.", WhseItemTrackingSetup)
                then begin
                    QtyToTrackBase := RemQtyToPickBase;
                    if UndefinedItemTracking(QtyToTrackBase) then
                        CreateTempHandlingSpec(NewWarehouseActivityLine, QtyToTrackBase);
                end;

                TempTrackingSpecification.Reset();
                if TempTrackingSpecification.Find('-') then
                    repeat
                        ITQtyToPickBase := Abs(TempTrackingSpecification."Qty. to Handle (Base)");
                        TotalITQtyToPickBase += ITQtyToPickBase;
                        if ITQtyToPickBase > 0 then begin
                            NewWarehouseActivityLine.CopyTrackingFromSpec(TempTrackingSpecification);
                            if NewWarehouseActivityLine.TrackingExists() then
                                NewWarehouseActivityLine."Expiration Date" :=
                                    ItemTrackingManagement.ExistingExpirationDate(NewWarehouseActivityLine, false, EntriesExist);

                            OnCreatePickOrMoveLineFromHandlingSpec(NewWarehouseActivityLine, TempTrackingSpecification, EntriesExist);

                            if CurrLocation."Bin Mandatory" then begin
                                // find Take qty. for bin code of source line
                                if (NewWarehouseActivityLine."Bin Code" <> '') and (not IsInvtMovement or IsBlankInvtMovement) then
                                    InsertPickOrMoveBinWhseActLine(
                                      NewWarehouseActivityLine, NewWarehouseActivityLine."Bin Code", false, ITQtyToPickBase, WhseItemTrackingSetup);

                                OnCreatePickOrMoveLineOnAfterFindTakeQtyForBinCodeOfSourceLineHandlingSpec(NewWarehouseActivityLine, TempTrackingSpecification, WhseItemTrackingSetup, ITQtyToPickBase, CurrWarehouseActivityHeader);

                                // Invt. movement without document has to be created
                                if IsBlankInvtMovement then
                                    ITQtyToPickBase := 0;

                                // find Take qty. for default bin
                                ShouldInsertPickOrMoveDefaultBin := ITQtyToPickBase > 0;
                                OnCreatePickOrMoveLineOnAfterCalcShouldInsertPickOrMoveDefaultBin(NewWarehouseActivityLine, RemQtyToPickBase, OutstandingQtyBase, ReservationExists, ShouldInsertPickOrMoveDefaultBin);

                                case CurrLocation."Pick Bin Policy" of
                                    CurrLocation."Pick Bin Policy"::"Default Bin":
                                        begin
                                            FeatureTelemetry.LogUsage('0000KP7', BinPolicyTelemetryCategoryTok, DefaultBinPickPolicyTelemetryTok);

                                            if ShouldInsertPickOrMoveDefaultBin then
                                                InsertPickOrMoveBinWhseActLine(NewWarehouseActivityLine, '', true, ITQtyToPickBase, WhseItemTrackingSetup);

                                            // find Take qty. for other bins
                                            if ITQtyToPickBase > 0 then
                                                InsertPickOrMoveBinWhseActLine(NewWarehouseActivityLine, '', false, ITQtyToPickBase, WhseItemTrackingSetup);
                                        end;
                                    CurrLocation."Pick Bin Policy"::"Bin Ranking":
                                        begin
                                            FeatureTelemetry.LogUsage('0000KP8', BinPolicyTelemetryCategoryTok, RankingBinPickPolicyTelemetryTok);

                                            // find Take qty. for other bins
                                            if ITQtyToPickBase > 0 then
                                                InsertPickOrMoveBinWhseActLine(NewWarehouseActivityLine, '', false, ITQtyToPickBase, WhseItemTrackingSetup);
                                        end;
                                    else
                                        OnInsertPickOrMoveBinWhseActivityLine(NewWarehouseActivityLine, ITQtyToPickBase);
                                end;

                                if (ITQtyToPickBase = 0) and IsInvtMovement and not IsBlankInvtMovement and
                                   not TempTrackingSpecification.Correction
                                then
                                    SynchronizeWhseItemTracking(TempTrackingSpecification);
                            end else
                                if ITQtyToPickBase > 0 then
                                    InsertShelfWhseActivLine(NewWarehouseActivityLine, ITQtyToPickBase, WhseItemTrackingSetup);

                            RemQtyToPickBase :=
                              RemQtyToPickBase + ITQtyToPickBase +
                              TempTrackingSpecification."Qty. to Handle (Base)";
                        end;
                        NewWarehouseActivityLine.ClearTracking();
                    until (TempTrackingSpecification.Next() = 0) or (RemQtyToPickBase <= 0);

                RemQtyToPickBase := Minimum(RemQtyToPickBase, OriginalRemQtyToPickBase - TotalITQtyToPickBase);
            end;

            if CurrLocation."Bin Mandatory" then begin
                // find Take qty. for bin code of source line
                OnCreatePickOrMoveLineOnBeforeCheckIfInsertPickOrMoveBinWhseActLine(NewWarehouseActivityLine, RemQtyToPickBase);
                if (RemQtyToPickBase > 0) and
                   (NewWarehouseActivityLine."Bin Code" <> '') and
                   (not IsInvtMovement or IsBlankInvtMovement) and
                   (not HasExpiredItems)
                then
                    InsertPickOrMoveBinWhseActLine(
                      NewWarehouseActivityLine, NewWarehouseActivityLine."Bin Code", false, RemQtyToPickBase, WhseItemTrackingSetup);

#if not CLEAN21
                OnCreatePickOrMoveLineOnAfterFindTakeQtyForBinCodeOfSourceLine(NewWarehouseActivityLine, WhseItemTrackingSetup, RemQtyToPickBase);
#endif
                OnCreatePickOrMoveLineOnAfterFindTakeQtyForBinCodeSourceLine(NewWarehouseActivityLine, WhseItemTrackingSetup, RemQtyToPickBase, CurrWarehouseActivityHeader);
                // Invt. movement without document has to be created
                if IsBlankInvtMovement then
                    RemQtyToPickBase := 0;

                // find Take qty. for default bin
                if (RemQtyToPickBase > 0) and (not HasExpiredItems) and (CurrLocation."Pick Bin Policy" = CurrLocation."Pick Bin Policy"::"Default Bin") then
                    InsertPickOrMoveBinWhseActLine(NewWarehouseActivityLine, '', true, RemQtyToPickBase, WhseItemTrackingSetup);

                // find Take qty. for other bins
                if (RemQtyToPickBase > 0) and (not HasExpiredItems) then
                    InsertPickOrMoveBinWhseActLine(NewWarehouseActivityLine, '', false, RemQtyToPickBase, WhseItemTrackingSetup)
            end else
                if (RemQtyToPickBase > 0) and (not HasExpiredItems) then
                    InsertShelfWhseActivLine(NewWarehouseActivityLine, RemQtyToPickBase, WhseItemTrackingSetup);
        end;

        QtyRemToPickBase := OriginalRemQtyToPickBase - QtyAvailToPickBase + RemQtyToPickBase;
        if CurrLocation."Always Create Pick Line" and (QtyRemToPickBase > 0) then begin
            MakeWarehouseActivityHeader();
            MakeWarehouseActivityLine(NewWarehouseActivityLine, '', QtyRemToPickBase, QtyRemToPickBase);
        end;

        OnAfterInsertWhseActivLine(
            NewWarehouseActivityLine, WhseItemTrackingSetup."Serial No. Required", WhseItemTrackingSetup."Lot No. Required",
            RemQtyToPickBase, CompleteShipment, ReservationExists, WhseItemTrackingSetup);
    end;

    local procedure CalcRemQtyToPickOrMoveBase(NewWarehouseActivityLine: Record "Warehouse Activity Line"; OutstandingQtyBase: Decimal; var RemQtyToPickBase: Decimal)
    var
        ATOSalesLine: Record "Sales Line";
        MaxQtyToPickBase: Decimal;
    begin
        with NewWarehouseActivityLine do begin
            MaxQtyToPickBase :=
              OutstandingQtyBase -
              WMSManagement.CalcLineReservedQtyNotonInvt(
                "Source Type", "Source Subtype", "Source No.",
                "Source Line No.", "Source Subline No.");

            if WMSManagement.GetATOSalesLine("Source Type", "Source Subtype", "Source No.", "Source Line No.", ATOSalesLine) then
                MaxQtyToPickBase += ATOSalesLine.QtyAsmRemainingBaseOnATO();

            if RemQtyToPickBase > MaxQtyToPickBase then begin
                RemQtyToPickBase := MaxQtyToPickBase;
                if "Shipping Advice" = "Shipping Advice"::Complete then
                    CompleteShipment := false;
            end;
        end;
    end;

    procedure InsertPickOrMoveBinWhseActLine(NewWarehouseActivityLine: Record "Warehouse Activity Line"; BinCode: Code[20]; DefaultBin: Boolean; var RemQtyToPickBase: Decimal; WhseItemTrackingSetup: Record "Item Tracking Setup")
    var
        FromBinContent: Record "Bin Content";
        QtyToPickBase: Decimal;
        QtyAvailToPickBase: Decimal;
        IsHandled: Boolean;
        RemQtyToPick: Decimal;
    begin
        IsHandled := false;
        OnBeforeInsertPickOrMoveBinWhseActLine(
            NewWarehouseActivityLine, BinCode, DefaultBin, RemQtyToPickBase, IsHandled, CurrWarehouseRequest, CurrWarehouseActivityHeader,
            IsInvtMovement, AutoCreation, PostingDate, VendorDocNo, LineCreated, NextLineNo);
        if IsHandled then
            exit;

        CreateATOPickLine(NewWarehouseActivityLine, BinCode, RemQtyToPickBase);
        if RemQtyToPickBase = 0 then
            exit;

        with FromBinContent do begin
            if DefaultBin then begin
                SetCurrentKey(Default, "Bin Ranking", "Location Code", "Item No.", "Variant Code", "Bin Code");
                SetRange(Default, DefaultBin)
            end else begin
                SetCurrentKey("Bin Ranking");
                SetAscending("Bin Ranking", false);
            end;

            SetRange("Location Code", NewWarehouseActivityLine."Location Code");
            SetRange("Item No.", NewWarehouseActivityLine."Item No.");
            SetRange("Variant Code", NewWarehouseActivityLine."Variant Code");

            if (BinCode <> '') and not IsInvtMovement then
                SetRange("Bin Code", BinCode);

            if (NewWarehouseActivityLine."Bin Code" <> '') and IsInvtMovement then
                // not movement within the same bin
                SetFilter("Bin Code", '<>%1', NewWarehouseActivityLine."Bin Code");

            if IsBlankInvtMovement then begin
                // inventory movement without source document, created from Internal Movement
                SetRange("Bin Code", FromBinCode);
                SetRange(Default);
            end;

            SetTrackingFilterFromWhseActivityLineIfNotBlank(NewWarehouseActivityLine);

            OnBeforeFindFromBinContent(FromBinContent, NewWarehouseActivityLine, FromBinCode, BinCode, IsInvtMovement, IsBlankInvtMovement, DefaultBin, WhseItemTrackingSetup, CurrWarehouseActivityHeader, CurrWarehouseRequest);
            if Find('-') then
                repeat
                    IsHandled := false;
                    OnInsertPickOrMoveBinWhseActLineOnBeforeLoopIteration(FromBinContent, NewWarehouseActivityLine, BinCode, DefaultBin, RemQtyToPickBase, IsHandled, QtyAvailToPickBase);
                    if not IsHandled then begin
                        if NewWarehouseActivityLine."Activity Type" = NewWarehouseActivityLine."Activity Type"::"Invt. Movement" then
                            QtyAvailToPickBase := CalcQtyAvailToPickIncludingDedicated(0)
                        else
                            QtyAvailToPickBase := CalcQtyAvailToPick(0);
                        OnInsertPickOrMoveBinWhseActLineOnAfterCalcQtyAvailToPick(QtyAvailToPickBase, FromBinContent);
                        if RemQtyToPickBase < QtyAvailToPickBase then
                            QtyAvailToPickBase := RemQtyToPickBase;

                        OnInsertPickOrMoveBinWhseActLineOnBeforeMakeHeader(RemQtyToPickBase, QtyAvailToPickBase, DefaultBin, FromBinContent);
                        if QtyAvailToPickBase > 0 then begin
                            MakeWarehouseActivityHeader();
                            if WhseItemTrackingSetup."Serial No. Required" then begin
                                QtyAvailToPickBase := Round(QtyAvailToPickBase, 1, '<');
                                QtyToPickBase := 1;
                                OnInsertPickOrMoveBinWhseActLineOnBeforeLoopMakeLine(CurrWarehouseActivityHeader, CurrWarehouseRequest, NewWarehouseActivityLine, FromBinContent, AutoCreation, QtyToPickBase);
                                RemQtyToPick := NewWarehouseActivityLine.CalcQty(RemQtyToPickBase);
                                IsHandled := false;
                                OnInsertPickOrMoveBinWhseActLineOnBeforeMakeLineWhenSNoReq(NewWarehouseActivityLine, WhseItemTrackingSetup, FromBinContent."Bin Code", QtyToPickBase, RemQtyToPickBase, QtyAvailToPickBase, IsHandled);
                                if not IsHandled then
                                    repeat
                                        MakeLineWhenSNoReq(NewWarehouseActivityLine, "Bin Code", QtyToPickBase, RemQtyToPickBase, RemQtyToPick);
                                        QtyAvailToPickBase := QtyAvailToPickBase - QtyToPickBase;
                                    until QtyAvailToPickBase <= 0;
                            end else begin
                                QtyToPickBase := QtyAvailToPickBase;
                                OnInsertPickOrMoveBinWhseActLineOnBeforeLoopMakeLine(CurrWarehouseActivityHeader, CurrWarehouseRequest, NewWarehouseActivityLine, FromBinContent, AutoCreation, QtyToPickBase);
                                repeat
                                    MakeWarehouseActivityLine(NewWarehouseActivityLine, "Bin Code", QtyToPickBase, RemQtyToPickBase);
                                    OnInsertPickOrMoveBinWhseActLineOnAfterMakeLine(QtyToPickBase, DefaultBin);
                                    QtyAvailToPickBase := QtyAvailToPickBase - QtyToPickBase;
                                until QtyAvailToPickBase <= 0;
                            end;
                        end;
                    end;
                until (Next() = 0) or (RemQtyToPickBase = 0);
        end;
        OnAfterInsertPickOrMoveBinWhseActLine(NewWarehouseActivityLine, CurrWarehouseActivityHeader, RemQtyToPickBase)
    end;

    procedure InsertShelfWhseActivLine(NewWarehouseActivityLine: Record "Warehouse Activity Line"; var RemQtyToPickBase: Decimal; WhseItemTrackingSetup: Record "Item Tracking Setup")
    var
        QtyToPickBase: Decimal;
        RemQtyToPick: Decimal;
        IsHandled: Boolean;
    begin
        CreateATOPickLine(NewWarehouseActivityLine, '', RemQtyToPickBase);
        if RemQtyToPickBase = 0 then
            exit;

        MakeWarehouseActivityHeader();
        OnInsertShelfWhseActivLineOnAfterMakeHeader(NewWarehouseActivityLine);

        if WhseItemTrackingSetup."Serial No. Required" then begin
            IsHandled := false;
            OnInsertShelfWhseActivLineOnBeforeMakeShelfLineWhenSNoReq(NewWarehouseActivityLine, WhseItemTrackingSetup, QtyToPickBase, RemQtyToPickBase, IsHandled);
            if IsHandled then
                exit;

            RemQtyToPickBase := Round(RemQtyToPickBase, 1, '<');
            QtyToPickBase := 1;
            RemQtyToPick := NewWarehouseActivityLine.CalcQty(RemQtyToPickBase);
            repeat
                MakeLineWhenSNoReq(NewWarehouseActivityLine, '', QtyToPickBase, RemQtyToPickBase, RemQtyToPick);
            until RemQtyToPickBase = 0;
        end else begin
            QtyToPickBase := RemQtyToPickBase;
            repeat
                MakeWarehouseActivityLine(NewWarehouseActivityLine, '', QtyToPickBase, RemQtyToPickBase);
                OnInsertShelfWhseActivLineOnAfterMakeWarehouseActivityLine(NewWarehouseActivityLine);
            until RemQtyToPickBase = 0;
        end;
    end;

    procedure CalcInvtAvailability(WarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup") Result: Decimal
    var
        Item2: Record Item;
        TempWarehouseActivityLine2: Record "Warehouse Activity Line" temporary;
        BlockedItemTrackingSetup: Record "Item Tracking Setup";
        WhseActivLineItemTrackingSetup: Record "Item Tracking Setup";
        WarehouseAvailabilityMgt: Codeunit "Warehouse Availability Mgt.";
        QtyAssgndtoPick: Decimal;
        LineReservedQty: Decimal;
        QtyReservedOnPickShip: Decimal;
        QtyOnDedicatedBins: Decimal;
        QtyBlocked: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcInvtAvailability(WarehouseActivityLine, CurrLocation, Result, IsHandled, WhseItemTrackingSetup, IsBlankInvtMovement);
        if IsHandled then
            exit(Result);

        GetItem(WarehouseActivityLine."Item No.");
        Item2 := CurrItem;
        Item2.SetRange("Location Filter", WarehouseActivityLine."Location Code");
        Item2.SetRange("Variant Filter", WarehouseActivityLine."Variant Code");
        WhseItemTrackingSetup.SetTrackingFilterForItem(Item2);
        Item2.CalcFields(Inventory);
        if not IsBlankInvtMovement then
            Item2.CalcFields("Reserved Qty. on Inventory");

        QtyAssgndtoPick := WarehouseAvailabilityMgt.CalcQtyAssgndtoPick(CurrLocation, WarehouseActivityLine."Item No.", WarehouseActivityLine."Variant Code", '');

        if WarehouseActivityLine."Activity Type" <> WarehouseActivityLine."Activity Type"::"Invt. Movement" then begin // Invt. Movement from Dedicated Bin is allowed
            WhseActivLineItemTrackingSetup.CopyTrackingFromWhseActivityLine(WarehouseActivityLine);
            QtyOnDedicatedBins :=
                WarehouseAvailabilityMgt.CalcQtyOnDedicatedBins(
                    WarehouseActivityLine."Location Code", WarehouseActivityLine."Item No.", WarehouseActivityLine."Variant Code", WhseActivLineItemTrackingSetup);
        end;

        LineReservedQty :=
            WarehouseAvailabilityMgt.CalcLineReservedQtyOnInvt(
                WarehouseActivityLine."Source Type", WarehouseActivityLine."Source Subtype", WarehouseActivityLine."Source No.",
                WarehouseActivityLine."Source Line No.", WarehouseActivityLine."Source Subline No.", true, WhseItemTrackingSetup, TempWarehouseActivityLine2);

        QtyReservedOnPickShip :=
            WarehouseAvailabilityMgt.CalcReservQtyOnPicksShips(
                WarehouseActivityLine."Location Code", WarehouseActivityLine."Item No.", WarehouseActivityLine."Variant Code", TempWarehouseActivityLine2);

        BlockedItemTrackingSetup.CopyTrackingFromItemTrackingSetup(WhseItemTrackingSetup);
        if CurrLocation."Bin Mandatory" then
            QtyBlocked :=
                WarehouseAvailabilityMgt.CalcQtyOnBlockedITOrOnBlockedOutbndBins(
                    WarehouseActivityLine."Location Code", WarehouseActivityLine."Item No.", WarehouseActivityLine."Variant Code", WhseItemTrackingSetup)
        else
            QtyBlocked :=
                WarehouseAvailabilityMgt.CalcQtyOnBlockedItemTracking(
                    WarehouseActivityLine."Location Code", WarehouseActivityLine."Item No.", WarehouseActivityLine."Variant Code");
        OnCalcInvtAvailabilityOnAfterCalcQtyBlocked(WarehouseActivityLine, WhseItemTrackingSetup, QtyBlocked);
        exit(
          Item2.Inventory - Abs(Item2."Reserved Qty. on Inventory") - QtyAssgndtoPick - QtyOnDedicatedBins - QtyBlocked +
          LineReservedQty + QtyReservedOnPickShip);
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode <> CurrLocation.Code then
            if LocationCode = '' then
                CurrLocation.GetLocationSetup('', CurrLocation)
            else
                CurrLocation.Get(LocationCode);
    end;

    local procedure GetBin(LocationCode: Code[10]; BinCode: Code[20])
    begin
        if (CurrBin."Location Code" <> LocationCode) or
           (CurrBin.Code <> BinCode)
        then
            CurrBin.Get(LocationCode, BinCode)
    end;

    local procedure GetShelfNo(ItemNo: Code[20]): Code[10]
    begin
        GetItem(ItemNo);
        exit(CurrItem."Shelf No.");
    end;

    local procedure GetItem(ItemNo: Code[20])
    begin
        if ItemNo <> CurrItem."No." then
            CurrItem.Get(ItemNo);
    end;

    local procedure GetItemAndSKU(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10])
    begin
        if CurrItem."No." <> ItemNo then begin
            CurrItem.Get(ItemNo);
            GetWarehouseClassCode();
        end;
        if (ItemNo <> CurrStockKeepingUnit."Item No.") or
           (LocationCode <> CurrStockKeepingUnit."Location Code") or
           (VariantCode <> CurrStockKeepingUnit."Variant Code")
        then
            if not CurrStockKeepingUnit.Get(LocationCode, ItemNo, VariantCode) then
                Clear(CurrStockKeepingUnit);
    end;

    local procedure GetWarehouseClassCode()
    begin
        WarehouseClassCode := CurrItem."Warehouse Class Code";
    end;

    procedure SetWhseRequest(NewWarehouseRequest: Record "Warehouse Request"; SetHideDialog: Boolean)
    begin
        CurrWarehouseRequest := NewWarehouseRequest;
        HideDialog := SetHideDialog;
        LineCreated := false;
    end;

    procedure CheckSourceDoc(NewWarehouseRequest: Record "Warehouse Request"): Boolean
    var
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        TransferLine: Record "Transfer Line";
        ProdOrderComponent: Record "Prod. Order Component";
        AssemblyLine: Record "Assembly Line";
        JobPlanningLine: Record "Job Planning Line";
        IsHandled: Boolean;
        Result: Boolean;
    begin
        CurrWarehouseRequest := NewWarehouseRequest;

        IsHandled := false;
        OnBeforeCheckSourceDoc(NewWarehouseRequest, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if not GetSourceDocHeader() then
            exit(false);

        CheckLineExist := true;
        case CurrWarehouseRequest."Source Document" of
            CurrWarehouseRequest."Source Document"::"Purchase Order":
                exit(SetFilterPurchLine(PurchaseLine, CurrPurchaseHeader));
            CurrWarehouseRequest."Source Document"::"Purchase Return Order":
                exit(SetFilterPurchLine(PurchaseLine, CurrPurchaseHeader));
            CurrWarehouseRequest."Source Document"::"Sales Order":
                exit(SetFilterSalesLine(SalesLine, CurrSalesHeader));
            CurrWarehouseRequest."Source Document"::"Sales Return Order":
                exit(SetFilterSalesLine(SalesLine, CurrSalesHeader));
            CurrWarehouseRequest."Source Document"::"Outbound Transfer":
                exit(SetFilterTransferLine(TransferLine, CurrTransferHeader));
            CurrWarehouseRequest."Source Document"::"Prod. Consumption":
                exit(SetFilterProductionLine(ProdOrderComponent, CurrProductionOrder));
            CurrWarehouseRequest."Source Document"::"Assembly Consumption":
                exit(SetFilterAssemblyLine(AssemblyLine, CurrAssemblyHeader));
            CurrWarehouseRequest."Source Document"::"Job Usage":
                exit(SetFilterJobPlanningLine(JobPlanningLine, CurrJob));
            else begin
                IsHandled := false;
                OnCheckSourceDocForWhseRequest(CurrWarehouseRequest, SourceDocRecordRef, CurrWarehouseActivityHeader, CheckLineExist, Result, IsHandled);
                if IsHandled then
                    exit(Result);
            end;
        end;
    end;

    procedure AutoCreatePickOrMove(var NewWarehouseActivityHeader: Record "Warehouse Activity Header")
    var
        IsHandled: Boolean;
    begin
        CurrWarehouseActivityHeader := NewWarehouseActivityHeader;
        CheckLineExist := false;
        AutoCreation := true;
        GetLocation(CurrWarehouseRequest."Location Code");

        IsHandled := false;
        OnBeforeAutoCreatePickOrMove(CurrWarehouseRequest, CurrWarehouseActivityHeader, LineCreated, IsHandled, HideDialog, IsInvtMovement, IsBlankInvtMovement, CompleteShipment);
        if IsHandled then
            exit;

        case CurrWarehouseRequest."Source Document" of
            CurrWarehouseRequest."Source Document"::"Purchase Order":
                CreatePickOrMoveFromPurchase(CurrPurchaseHeader);
            CurrWarehouseRequest."Source Document"::"Purchase Return Order":
                CreatePickOrMoveFromPurchase(CurrPurchaseHeader);
            CurrWarehouseRequest."Source Document"::"Sales Order":
                CreatePickOrMoveFromSales(CurrSalesHeader);
            CurrWarehouseRequest."Source Document"::"Sales Return Order":
                CreatePickOrMoveFromSales(CurrSalesHeader);
            CurrWarehouseRequest."Source Document"::"Outbound Transfer":
                CreatePickOrMoveFromTransfer(CurrTransferHeader);
            CurrWarehouseRequest."Source Document"::"Prod. Consumption":
                CreatePickOrMoveFromProduction(CurrProductionOrder);
            CurrWarehouseRequest."Source Document"::"Assembly Consumption":
                CreatePickOrMoveFromAssembly(CurrAssemblyHeader);
            CurrWarehouseRequest."Source Document"::"Job Usage":
                CreatePickOrMoveFromJobPlanning(CurrJob);
            else
                OnAutoCreatePickOrMoveFromWhseRequest(
                    CurrWarehouseRequest, SourceDocRecordRef, LineCreated, CurrWarehouseActivityHeader, CurrLocation, HideDialog, CompleteShipment, CheckLineExist);
        end;

        if LineCreated then begin
            OnAutoCreatePickOrMoveOnBeforeWarehouseActivityHeaderModify(CurrWarehouseActivityHeader, CurrWarehouseRequest, CurrLocation);
            CurrWarehouseActivityHeader.Modify();
            NewWarehouseActivityHeader := CurrWarehouseActivityHeader;
        end;

        OnAfterAutoCreatePickOrMove(CurrWarehouseRequest, LineCreated, NewWarehouseActivityHeader, CurrLocation, HideDialog);
    end;

    procedure SetReportGlobals(PrintDocument2: Boolean; ShowError2: Boolean)
    begin
        PrintDocument := PrintDocument2;
        ShowError := ShowError2;
    end;

    procedure SetReportGlobals(PrintDocument2: Boolean; ShowError2: Boolean; ReservedFromStock2: Enum "Reservation From Stock")
    begin
        PrintDocument := PrintDocument2;
        ShowError := ShowError2;
        ReservedFromStock := ReservedFromStock2;
    end;

    local procedure SetFilterReservEntry(var ReservationEntry: Record "Reservation Entry"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        with ReservationEntry do begin
            Reset();
            SetCurrentKey("Source ID", "Source Ref. No.", "Source Type", "Source Subtype", "Source Batch Name", "Source Prod. Order Line");
            SetRange("Source ID", WarehouseActivityLine."Source No.");
            if WarehouseActivityLine."Source Type" = Database::"Prod. Order Component" then
                SetRange("Source Ref. No.", WarehouseActivityLine."Source Subline No.")
            else
                SetRange("Source Ref. No.", WarehouseActivityLine."Source Line No.");

            if WarehouseActivityLine."Source Type" = Database::Job then begin
                SetRange("Source Type", Database::"Job Planning Line");
                SetRange("Source Subtype", 2);
            end else begin
                SetRange("Source Type", WarehouseActivityLine."Source Type");
                SetRange("Source Subtype", WarehouseActivityLine."Source Subtype");
            end;

            if WarehouseActivityLine."Source Type" = Database::"Prod. Order Component" then
                SetRange("Source Prod. Order Line", WarehouseActivityLine."Source Line No.");
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

        exit(CurrLocation."Pick According to FEFO" and WhseItemTrackingSetup.TrackingRequired());
    end;

    procedure UndefinedItemTracking(var QtyToTrackBase: Decimal): Boolean
    var
        DummyItemTrackingSetup: Record "Item Tracking Setup";
    begin
        QtyToTrackBase := QtyToTrackBase + ItemTrackedQuantity(DummyItemTrackingSetup);

        exit(QtyToTrackBase > 0);
    end;

    local procedure ItemTrackedQuantity(WhseItemTrackingSetup: Record "Item Tracking Setup"): Decimal
    var
        IsTrackingEmpty: Boolean;
    begin
        with TempTrackingSpecification do begin
            Reset();
            if not WhseItemTrackingSetup.TrackingExists() then
                if IsEmpty() then
                    exit(0);

            if WhseItemTrackingSetup."Serial No." <> '' then begin
                SetTrackingKey();
                SetRange("Serial No.", WhseItemTrackingSetup."Serial No.");
                if IsEmpty() then
                    exit(0);

                exit(1);
            end;

            if WhseItemTrackingSetup."Lot No." <> '' then begin
                SetTrackingKey();
                SetRange("Lot No.", WhseItemTrackingSetup."Lot No.");
                if IsEmpty() then
                    exit(0);
            end;

            IsTrackingEmpty := false;
            OnItemTrackedQuantityOnAfterCheckTracking(TempTrackingSpecification, WhseItemTrackingSetup, IsTrackingEmpty);
            if IsTrackingEmpty then
                exit(0);

            SetCurrentKey(
              "Source ID", "Source Type", "Source Subtype", "Source Batch Name",
              "Source Prod. Order Line", "Source Ref. No.");
            if WhseItemTrackingSetup."Lot No." <> '' then
                SetRange("Lot No.", WhseItemTrackingSetup."Lot No.");
            CalcSums("Qty. to Handle (Base)");
            exit("Qty. to Handle (Base)");
        end;
    end;

    procedure CreateTempHandlingSpec(WarehouseActivityLine: Record "Warehouse Activity Line"; TotalQtyToPickBase: Decimal)
    var
        EntrySummary: Record "Entry Summary";
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        WhseItemTrackingFEFO: Codeunit "Whse. Item Tracking FEFO";
        TotalAvailQtyToPickBase: Decimal;
        RemQtyToPickBase: Decimal;
        QtyToPickBase: Decimal;
        QtyTracked: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateTempHandlingSpec(WarehouseActivityLine, TotalQtyToPickBase, IsHandled);
        if IsHandled then
            exit;

        if CurrLocation."Bin Mandatory" then
            if not IsItemOnBins(WarehouseActivityLine) then
                exit;

        WhseItemTrackingFEFO.SetSource(
          WarehouseActivityLine."Source Type", WarehouseActivityLine."Source Subtype", WarehouseActivityLine."Source No.",
          WarehouseActivityLine."Source Line No.", WarehouseActivityLine."Source Subline No.");
        OnCreateTempHandlingSpecOnAfterWhseItemTrackingFEFOSetSource(WhseItemTrackingFEFO, WarehouseActivityLine, CurrWarehouseRequest);
        WhseItemTrackingFEFO.CreateEntrySummaryFEFO(CurrLocation, WarehouseActivityLine."Item No.", WarehouseActivityLine."Variant Code", true);
        if WhseItemTrackingFEFO.FindFirstEntrySummaryFEFO(EntrySummary) then begin
            InitTempHandlingSpec();
            RemQtyToPickBase := TotalQtyToPickBase;
            repeat
                WhseItemTrackingSetup.CopyTrackingFromEntrySummary(EntrySummary);
                if EntrySummary."Expiration Date" <> 0D then begin
                    QtyTracked := ItemTrackedQuantity(WhseItemTrackingSetup);
                    OnCreateTempHandlingSpecOnAfterCalcQtyTracked(EntrySummary, QtyTracked, TempTrackingSpecification);
                    if not ((EntrySummary."Serial No." <> '') and (QtyTracked > 0)) then begin
                        if CurrLocation."Bin Mandatory" then
                            TotalAvailQtyToPickBase :=
                              CalcQtyAvailToPickOnBins(WarehouseActivityLine, WhseItemTrackingSetup, RemQtyToPickBase)
                        else
                            TotalAvailQtyToPickBase := CalcInvtAvailability(WarehouseActivityLine, WhseItemTrackingSetup);
                        OnCreateTempHandlingSpecOnAfterCalcTotalAvailQtyToPickBase(WarehouseActivityLine, EntrySummary, TotalAvailQtyToPickBase);

                        TotalAvailQtyToPickBase := TotalAvailQtyToPickBase - QtyTracked;
                        QtyToPickBase := 0;

                        OnAfterCalcTotalAvailQtyToPickBase(
                          WarehouseActivityLine."Item No.", WarehouseActivityLine."Variant Code", EntrySummary."Serial No.", EntrySummary."Lot No.",
                          CurrLocation.Code, '', WarehouseActivityLine."Source Type", WarehouseActivityLine."Source Subtype", WarehouseActivityLine."Source No.",
                          WarehouseActivityLine."Source Line No.", WarehouseActivityLine."Source Subline No.", RemQtyToPickBase, TotalAvailQtyToPickBase);

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
                              EntrySummary, WarehouseActivityLine, QtyToPickBase);
                    end;
                end;
            until not WhseItemTrackingFEFO.FindNextEntrySummaryFEFO(EntrySummary) or (RemQtyToPickBase = 0);
        end;
        HasExpiredItems := WhseItemTrackingFEFO.GetHasExpiredItems();
        ExpiredItemMessageText := WhseItemTrackingFEFO.GetResultMessageForExpiredItem();
    end;

    local procedure InitTempHandlingSpec()
    begin
        with TempTrackingSpecification do begin
            Reset();
            if FindLast() then
                LastTempHandlingSpecNo := "Entry No."
            else
                LastTempHandlingSpecNo := 0;
        end;
    end;

    local procedure InsertTempHandlingSpec(EntrySummary: Record "Entry Summary"; WarehouseActivityLine: Record "Warehouse Activity Line"; QuantityBase: Decimal)
    begin
        with TempTrackingSpecification do begin
            Init();
            "Entry No." := LastTempHandlingSpecNo + 1;
            if WarehouseActivityLine."Source Type" = Database::"Prod. Order Component" then
                SetSource(
                  WarehouseActivityLine."Source Type", WarehouseActivityLine."Source Subtype", WarehouseActivityLine."Source No.",
                  WarehouseActivityLine."Source Subline No.", '', WarehouseActivityLine."Source Line No.")
            else
                SetSource(
                  WarehouseActivityLine."Source Type", WarehouseActivityLine."Source Subtype", WarehouseActivityLine."Source No.",
                  WarehouseActivityLine."Source Line No.", '', 0);
            "Location Code" := WarehouseActivityLine."Location Code";
            "Item No." := WarehouseActivityLine."Item No.";
            "Variant Code" := WarehouseActivityLine."Variant Code";
            CopyTrackingFromEntrySummary(EntrySummary);
            "Expiration Date" := EntrySummary."Expiration Date";
            Correction := true;
            OnInsertTempHandlingSpecOnBeforeValidateQtyBase(TempTrackingSpecification, EntrySummary);
            Validate("Quantity (Base)", -QuantityBase);
            Insert();
            LastTempHandlingSpecNo := "Entry No.";
        end;
    end;

    local procedure SetFilterInternalMovement(var InternalMovementLine: Record "Internal Movement Line"; InternalMovementHeader: Record "Internal Movement Header"): Boolean
    begin
        with InternalMovementLine do begin
            SetRange("No.", InternalMovementHeader."No.");
            SetFilter("Qty. (Base)", '>0');
            OnSetFilterInternalMomementOnAfterSetFilters(InternalMovementLine, InternalMovementHeader);
            exit(Find('-'));
        end;
    end;

    local procedure SetFilterWhseWorksheetLine(var WhseWorksheetLine2: Record "Whse. Worksheet Line"; WhseWorksheetLine: Record "Whse. Worksheet Line"): Boolean
    begin
        Clear(WhseWorksheetLine2);
        WhseWorksheetLine2.SetRange("Worksheet Template Name", WhseWorksheetLine."Worksheet Template Name");
        WhseWorksheetLine2.SetRange(Name, WhseWorksheetLine.Name);
        WhseWorksheetLine2.SetRange("Location Code", WhseWorksheetLine."Location Code");
        WhseWorksheetLine2.SetFilter("Qty. (Base)", '>0');
        exit(WhseWorksheetLine2.FindSet());
    end;

    procedure CreateInvtMvntWithoutSource(var InternalMovementHeader: Record "Internal Movement Header")
    var
        InternalMovementLine: Record "Internal Movement Line";
        NewWarehouseActivityLine: Record "Warehouse Activity Line";
        RemQtyToPickBase: Decimal;
    begin
        if not HideDialog then
            if not Confirm(CreateInvtMvmtQst, false) then
                exit;

        IsInvtMovement := true;
        IsBlankInvtMovement := true;

        InternalMovementHeader.TestField("Location Code");

        with InternalMovementLine do begin
            if not SetFilterInternalMovement(InternalMovementLine, InternalMovementHeader) then begin
                if not HideDialog then
                    Message(NothingToHandleErr);
                exit;
            end;

            // creating Inventory Movement Header
            Clear(CurrWarehouseActivityHeader);
            CurrWarehouseActivityHeader.Type := CurrWarehouseActivityHeader.Type::"Invt. Movement";
            CurrWarehouseActivityHeader.Insert(true);
            CurrWarehouseActivityHeader.Validate("Location Code", InternalMovementHeader."Location Code");
            CurrWarehouseActivityHeader.Validate("Posting Date", InternalMovementHeader."Due Date");
            CurrWarehouseActivityHeader.Validate("Assigned User ID", InternalMovementHeader."Assigned User ID");
            CurrWarehouseActivityHeader.Validate("Assignment Date", InternalMovementHeader."Assignment Date");
            CurrWarehouseActivityHeader.Validate("Assignment Time", InternalMovementHeader."Assignment Time");
            OnInvtMvntWithoutSourceOnBeforeWhseActivHeaderModify(CurrWarehouseActivityHeader, InternalMovementHeader);
            CurrWarehouseActivityHeader.Modify();

            FindNextLineNo();

            repeat
                NewWarehouseActivityLine.Init();
                NewWarehouseActivityLine."Activity Type" := CurrWarehouseActivityHeader.Type;
                NewWarehouseActivityLine."No." := CurrWarehouseActivityHeader."No.";
                TestField("Location Code");
                GetLocation("Location Code");
                if CurrLocation."Bin Mandatory" then
                    NewWarehouseActivityLine."Action Type" := NewWarehouseActivityLine."Action Type"::Take;
                NewWarehouseActivityLine."Location Code" := "Location Code";
                TestField("From Bin Code");
                FromBinCode := "From Bin Code";
                TestField("To Bin Code");
                CheckBin("Location Code", "From Bin Code", false);
                CheckBin("Location Code", "To Bin Code", true);

                NewWarehouseActivityLine."Bin Code" := "To Bin Code";
                NewWarehouseActivityLine."Item No." := "Item No.";
                NewWarehouseActivityLine."Variant Code" := "Variant Code";
                NewWarehouseActivityLine."Unit of Measure Code" := "Unit of Measure Code";
                NewWarehouseActivityLine."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
                NewWarehouseActivityLine.Description := Description;
                NewWarehouseActivityLine."Due Date" := "Due Date";
                RemQtyToPickBase := "Qty. (Base)";
                OnCreateInvtMvntWithoutSourceOnAfterTransferFields(NewWarehouseActivityLine, InternalMovementLine);
                PrepareItemTrackingForInternalMovement(InternalMovementLine);
                CreatePickOrMoveLine(NewWarehouseActivityLine, RemQtyToPickBase, RemQtyToPickBase, false);
            until Next() = 0;
        end;

        if NextLineNo = 10000 then
            Error(NothingToHandleErr);

        MoveWhseComments(InternalMovementHeader."No.", CurrWarehouseActivityHeader."No.");

        if DeleteHandledInternalMovementLines(InternalMovementHeader."No.") then begin
            InternalMovementHeader.Delete(true);
            if not HideDialog then
                Message(ActivityCreatedMsg, CurrWarehouseActivityHeader.Type, CurrWarehouseActivityHeader."No.");
        end else
            if not HideDialog then
                Message(TrackingNotFullyAppliedMsg, CurrWarehouseActivityHeader.Type, CurrWarehouseActivityHeader."No.");

        OnAfterCreateInvtMvntWithoutSource(CurrWarehouseActivityHeader, InternalMovementHeader);
    end;

    procedure CreateInvtMvntWithoutSource(var WhseWorksheetLine: Record "Whse. Worksheet Line")
    var
        WhseWorksheetLine2: Record "Whse. Worksheet Line";
        NewWarehouseActivityLine: Record "Warehouse Activity Line";
        RelatedBin: Record Bin;
        RemQtyToPickBase: Decimal;
    begin
        if not HideDialog then
            if not Confirm(CreateInvtMvmtQst, false) then
                exit;

        IsInvtMovement := true;
        IsBlankInvtMovement := true;

        WhseWorksheetLine.TestField("Location Code");

        with WhseWorksheetLine2 do begin
            if not SetFilterWhseWorksheetLine(WhseWorksheetLine2, WhseWorksheetLine) then begin
                if not HideDialog then
                    Message(NothingToHandleErr);
                exit;
            end;

            // creating Inventory Movement Header
            Clear(CurrWarehouseActivityHeader);
            CurrWarehouseActivityHeader.Type := CurrWarehouseActivityHeader.Type::"Invt. Movement";
            CurrWarehouseActivityHeader.Insert(true);
            CurrWarehouseActivityHeader.Validate("Location Code", WhseWorksheetLine."Location Code");
            CurrWarehouseActivityHeader.Validate("Posting Date", WhseWorksheetLine."Due Date");
            CurrWarehouseActivityHeader.Modify();

            FindNextLineNo();

            repeat
                NewWarehouseActivityLine.Init();
                NewWarehouseActivityLine."Activity Type" := CurrWarehouseActivityHeader.Type;
                NewWarehouseActivityLine."No." := CurrWarehouseActivityHeader."No.";
                TestField("Location Code");
                GetLocation("Location Code");
                if CurrLocation."Bin Mandatory" then
                    NewWarehouseActivityLine."Action Type" := NewWarehouseActivityLine."Action Type"::Take;
                NewWarehouseActivityLine."Location Code" := "Location Code";
                TestField("From Bin Code");
                FromBinCode := "From Bin Code";
                TestField("To Bin Code");
                CheckBin("Location Code", "From Bin Code", false);
                CheckBin("Location Code", "To Bin Code", true);

                NewWarehouseActivityLine."Bin Code" := "To Bin Code";
                if "To Bin Code" <> '' then begin
                    RelatedBin.Get(CurrLocation.Code, "To Bin Code");
                    NewWarehouseActivityLine."Zone Code" := RelatedBin."Zone Code";
                end;
                NewWarehouseActivityLine."Item No." := "Item No.";
                NewWarehouseActivityLine."Variant Code" := "Variant Code";
                NewWarehouseActivityLine."Unit of Measure Code" := "Unit of Measure Code";
                NewWarehouseActivityLine."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
                NewWarehouseActivityLine.Description := Description;
                NewWarehouseActivityLine."Due Date" := "Due Date";
                RemQtyToPickBase := "Qty. (Base)";
                PrepareItemTrackingForWhseMovement(WhseWorksheetLine2);
                CreatePickOrMoveLine(NewWarehouseActivityLine, RemQtyToPickBase, RemQtyToPickBase, false);
            until Next() = 0;
        end;

        if NextLineNo = 10000 then
            Error(NothingToHandleErr);

        MoveWhseComments(WhseWorksheetLine."Whse. Document No.", CurrWarehouseActivityHeader."No.");

        if DeleteHandledWhseWorksheetLines(WhseWorksheetLine.Name, WhseWorksheetLine."Worksheet Template Name") then begin
            if not HideDialog then
                Message(ActivityCreatedMsg, CurrWarehouseActivityHeader.Type, CurrWarehouseActivityHeader."No.");
        end else
            if not HideDialog then
                Message(TrackingNotFullyAppliedMsg, CurrWarehouseActivityHeader.Type, CurrWarehouseActivityHeader."No.");
    end;

    local procedure DeleteHandledWhseWorksheetLines(WhseWorksheetName: Code[20]; WhseWorksheetTemplateName: Code[20]): Boolean
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        if TempInternalMovementLine.IsEmpty() then
            exit(false);

        with WhseWorksheetLine do begin
            SetRange(Name, WhseWorksheetName);
            SetRange("Worksheet Template Name", WhseWorksheetTemplateName);
            FindSet();
            repeat
                TempInternalMovementLine.SetRange("Item No.", "Item No.");
                TempInternalMovementLine.SetRange("Variant Code", "Variant Code");
                TempInternalMovementLine.SetRange("Location Code", "Location Code");
                TempInternalMovementLine.SetRange("Unit of Measure Code", "Unit of Measure Code");
                TempInternalMovementLine.SetRange("From Bin Code", "From Bin Code");
                TempInternalMovementLine.SetRange("To Bin Code", "To Bin Code");
                if TempInternalMovementLine.FindFirst() then
                    if Quantity <= TempInternalMovementLine.Quantity then begin
                        TempInternalMovementLine.Quantity -= Quantity;
                        TempInternalMovementLine."Qty. (Base)" -= "Qty. (Base)";
                        if TempInternalMovementLine.Quantity = 0 then
                            TempInternalMovementLine.Delete()
                        else
                            TempInternalMovementLine.Modify();
                        Delete(true);
                    end else begin
                        Quantity -= TempInternalMovementLine.Quantity;
                        "Qty. (Base)" -= TempInternalMovementLine."Qty. (Base)";
                        ItemTrackingManagement.DeleteWhseItemTrkgLines(
                          Database::"Whse. Worksheet Line", 0, Name, "Worksheet Template Name", 0, "Line No.", "Location Code", true);
                        Modify(true);
                        TempInternalMovementLine.Delete();
                    end;
            until Next() = 0;
            exit(IsEmpty);
        end;
    end;

    local procedure DeleteHandledInternalMovementLines(InternalMovementHeaderNo: Code[20]): Boolean
    var
        InternalMovementLine: Record "Internal Movement Line";
    begin
        if TempInternalMovementLine.IsEmpty() then
            exit(false);

        with InternalMovementLine do begin
            SetRange("No.", InternalMovementHeaderNo);
            OnDeleteHandledInternalMovementLinesOnAfterInternalMovementLineSetFilters(InternalMovementLine, InternalMovementHeaderNo);
            FindSet();
            repeat
                TempInternalMovementLine.SetRange("Item No.", "Item No.");
                TempInternalMovementLine.SetRange("Variant Code", "Variant Code");
                TempInternalMovementLine.SetRange("Location Code", "Location Code");
                TempInternalMovementLine.SetRange("Unit of Measure Code", "Unit of Measure Code");
                TempInternalMovementLine.SetRange("From Bin Code", "From Bin Code");
                TempInternalMovementLine.SetRange("To Bin Code", "To Bin Code");
                if TempInternalMovementLine.FindFirst() then
                    if Quantity <= TempInternalMovementLine.Quantity then begin
                        TempInternalMovementLine.Quantity -= Quantity;
                        TempInternalMovementLine."Qty. (Base)" -= "Qty. (Base)";
                        OnDeleteHandledInternalMovementLinesOnBeforeModifyTempInternalMovementLine(
                          TempInternalMovementLine, InternalMovementLine);
                        if TempInternalMovementLine.Quantity = 0 then
                            TempInternalMovementLine.Delete()
                        else
                            TempInternalMovementLine.Modify();
                        Delete(true);
                    end else begin
                        Quantity -= TempInternalMovementLine.Quantity;
                        "Qty. (Base)" -= TempInternalMovementLine."Qty. (Base)";
                        ItemTrackingManagement.DeleteWhseItemTrkgLines(
                          Database::"Internal Movement Line", 0, "No.", '', 0, "Line No.", "Location Code", true);
                        OnDeleteHandledInternalMovementLinesOnBeforeInternalMovementLineModify(
                          InternalMovementLine, TempInternalMovementLine);
                        Modify(true);
                        TempInternalMovementLine.Delete();
                    end;
            until Next() = 0;
            exit(IsEmpty);
        end;
    end;

    local procedure PrepareItemTrackingForInternalMovement(InternalMovementLine: Record "Internal Movement Line")
    begin
        // function recopies warehouse item tracking into temporary item tracking table
        // when Invt. Movement is created from Internal Movement
        TempReservationEntry.Reset();
        TempReservationEntry.DeleteAll();

        PrepareItemTrackingFromWhse(
          Database::"Internal Movement Line", 0, InternalMovementLine."No.", '', InternalMovementLine."Line No.", -1, false);

        OnAfterPrepareItemTrackingForInternalMovement(InternalMovementLine, TempReservationEntry);
    end;

    local procedure PrepareItemTrackingForWhseMovement(WhseWorksheetLine: Record "Whse. Worksheet Line")
    begin
        // function recopies warehouse item tracking into temporary item tracking table
        // when Invt. Movement is created from Whse. Worksheet Line
        TempReservationEntry.Reset();
        TempReservationEntry.DeleteAll();

        PrepareItemTrackingFromWhse(
          Database::"Whse. Worksheet Line", 0, WhseWorksheetLine.Name, WhseWorksheetLine."Worksheet Template Name", WhseWorksheetLine."Line No.", -1, true);
    end;

    local procedure PrepareItemTrackingFromWhse(SourceType: Integer; SourceSubtype: Integer; SourceNo: Code[20]; SourceBatchName: Code[20]; SourceLineNo: Integer; SignFactor: Integer; FromWhseWorksheet: Boolean)
    var
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        EntryNo: Integer;
    begin
        if TempReservationEntry.FindLast() then
            EntryNo := TempReservationEntry."Entry No.";

        WhseItemTrackingLine.SetSourceFilter(SourceType, SourceSubtype, SourceNo, SourceLineNo, true);
        if FromWhseWorksheet then
            WhseItemTrackingLine.SetRange("Source Batch Name", SourceBatchName);
        if WhseItemTrackingLine.Find('-') then
            repeat
                TempReservationEntry.TransferFields(WhseItemTrackingLine);
                EntryNo += 1;
                TempReservationEntry."Entry No." := EntryNo;
                TempReservationEntry."Reservation Status" := TempReservationEntry."Reservation Status"::Surplus;
                TempReservationEntry.Validate("Quantity (Base)", TempReservationEntry."Quantity (Base)" * SignFactor);
                TempReservationEntry.Positive := (TempReservationEntry."Quantity (Base)" > 0);
                TempReservationEntry.UpdateItemTracking();
                OnBeforeTempReservEntryInsert(TempReservationEntry, WhseItemTrackingLine);
                TempReservationEntry.Insert();
            until WhseItemTrackingLine.Next() = 0;
        OnAfterPrepareItemTrackingFromWhseIT(TempReservationEntry, EntryNo);
    end;

    procedure SynchronizeWhseItemTracking(var TrackingSpecification: Record "Tracking Specification")
    var
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        EntryNo: Integer;
    begin
        // documents which have defined item tracking - table 337 will have to synchronize these records with 6550 table for invt. movement
        if WhseItemTrackingLine.FindLast() then
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

    local procedure MoveWhseComments(DocumentNo: Code[20]; InvtMovementNo: Code[20])
    var
        WarehouseCommentLine1: Record "Warehouse Comment Line";
        WarehouseCommentLine2: Record "Warehouse Comment Line";
    begin
        WarehouseCommentLine1.SetRange("Table Name", WarehouseCommentLine1."Table Name"::"Internal Movement");
        WarehouseCommentLine1.SetRange("No.", DocumentNo);
        WarehouseCommentLine1.LockTable();

        if WarehouseCommentLine1.Find('-') then begin
            repeat
                WarehouseCommentLine2.Init();
                WarehouseCommentLine2 := WarehouseCommentLine1;
                WarehouseCommentLine2."Table Name" := WarehouseCommentLine2."Table Name"::"Whse. Activity Header";
                WarehouseCommentLine2.Type := WarehouseCommentLine1.Type::"Invt. Movement";
                WarehouseCommentLine2."No." := InvtMovementNo;
                WarehouseCommentLine2.Insert();
            until WarehouseCommentLine1.Next() = 0;
            WarehouseCommentLine1.DeleteAll();
        end;
    end;

    procedure GetExpiredItemMessage(): Text[100]
    begin
        exit(ExpiredItemMessageText);
    end;

    procedure PickStrictExpirationPosting(ItemNo: Code[20]; WhseItemTrackingSetup: Record "Item Tracking Setup"): Boolean
    var
        StrictExpirationPosting: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePickStrictExpirationPosting(
            ItemNo, WhseItemTrackingSetup."Serial No. Required", WhseItemTrackingSetup."Lot No. Required", StrictExpirationPosting, IsHandled);
        if IsHandled then
            exit(StrictExpirationPosting);

        exit(ItemTrackingManagement.StrictExpirationPosting(ItemNo) and WhseItemTrackingSetup.TrackingRequired());
    end;

    procedure MakeWarehouseActivityHeader()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeMakeHeader(CurrWarehouseActivityHeader, AutoCreation, IsHandled);
        if IsHandled then
            exit;

        if AutoCreation and not LineCreated then begin
            CurrWarehouseActivityHeader."No." := '';
            CurrWarehouseActivityHeader.Insert(true);
            UpdateWhseActivHeader(CurrWarehouseRequest);
            NextLineNo := 10000;
            if not SuppressCommit then
                Commit();
        end;
    end;

    procedure MakeWarehouseActivityLine(var NewWarehouseActivityLine: Record "Warehouse Activity Line"; TakeBinCode: Code[20]; QtyToPickBase: Decimal; var RemQtyToPickBase: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeMakeWarehouseActivityLine(NewWarehouseActivityLine, RemQtyToPickBase, NextLineNo, TakeBinCode, QtyToPickBase, IsInvtMovement, LineCreated, CompleteShipment, IsHandled);
        if IsHandled then
            exit;

        NewWarehouseActivityLine.Quantity := NewWarehouseActivityLine.CalcQty(QtyToPickBase);
        NewWarehouseActivityLine."Qty. (Base)" := QtyToPickBase;
        NewWarehouseActivityLine."Qty. Outstanding" := NewWarehouseActivityLine.Quantity;
        NewWarehouseActivityLine."Qty. Outstanding (Base)" := NewWarehouseActivityLine."Qty. (Base)";
        SetLineData(NewWarehouseActivityLine, TakeBinCode);
        RemQtyToPickBase := RemQtyToPickBase - QtyToPickBase;
    end;

    procedure MakeLineWhenSNoReq(var NewWarehouseActivityLine: Record "Warehouse Activity Line"; TakeBinCode: Code[20]; QtyToPickBase: Decimal; var RemQtyToPickBase: Decimal; var RemQtyToPick: Decimal)
    var
        UnitOfMeasureManagement: Codeunit "Unit of Measure Management";
        CalculatedPickQty: Decimal;
    begin
        CalculatedPickQty := NewWarehouseActivityLine.CalcQty(QtyToPickBase);
        if UnitOfMeasureManagement.RoundQty(UnitOfMeasureManagement.CalcBaseQty(RemQtyToPick - CalculatedPickQty, NewWarehouseActivityLine."Qty. per Unit of Measure"), 1) = 0 then
            NewWarehouseActivityLine.Quantity := RemQtyToPick
        else
            NewWarehouseActivityLine.Quantity := CalculatedPickQty;
        NewWarehouseActivityLine."Qty. (Base)" := QtyToPickBase;
        NewWarehouseActivityLine."Qty. Outstanding" := NewWarehouseActivityLine.Quantity;
        NewWarehouseActivityLine."Qty. Outstanding (Base)" := NewWarehouseActivityLine."Qty. (Base)";
        SetLineData(NewWarehouseActivityLine, TakeBinCode);
        RemQtyToPickBase -= QtyToPickBase;
        RemQtyToPick -= NewWarehouseActivityLine.Quantity;
    end;


    local procedure SetLineData(var NewWarehouseActivityLine: Record "Warehouse Activity Line"; TakeBinCode: Code[20])
    var
        RelatedBin: Record Bin;
        PlaceBinCode: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetLineData(NewWarehouseActivityLine, CurrWarehouseActivityHeader, TakeBinCode, NextLineNo, CurrLocation, LineCreated, IsHandled);
        if IsHandled then
            exit;

        PlaceBinCode := NewWarehouseActivityLine."Bin Code";
        NewWarehouseActivityLine."No." := CurrWarehouseActivityHeader."No.";
        NewWarehouseActivityLine."Line No." := NextLineNo;
        if CurrLocation."Bin Mandatory" then begin
            NewWarehouseActivityLine."Action Type" := NewWarehouseActivityLine."Action Type"::Take;
            NewWarehouseActivityLine."Bin Code" := TakeBinCode;
            if TakeBinCode <> '' then begin
                RelatedBin.SetLoadFields("Zone Code");
                RelatedBin.Get(NewWarehouseActivityLine."Location Code", NewWarehouseActivityLine."Bin Code");
                NewWarehouseActivityLine."Zone Code" := RelatedBin."Zone Code";
            end;
            NewWarehouseActivityLine."Special Equipment Code" := GetSpecEquipmentCode(NewWarehouseActivityLine."Item No.", NewWarehouseActivityLine."Variant Code", NewWarehouseActivityLine."Location Code", TakeBinCode);
        end else
            NewWarehouseActivityLine."Shelf No." := GetShelfNo(NewWarehouseActivityLine."Item No.");
        NewWarehouseActivityLine."Qty. to Handle" := 0;
        NewWarehouseActivityLine."Qty. to Handle (Base)" := 0;
        NewWarehouseActivityLine."Qty. Rounding Precision" := 0;
        OnBeforeNewWhseActivLineInsert(NewWarehouseActivityLine, CurrWarehouseActivityHeader);
        NewWarehouseActivityLine.Insert();
        if CurrLocation."Bin Mandatory" and IsInvtMovement then begin
            // Place Action for inventory movement
            OnMakeLineOnBeforeUpdatePlaceLine(NewWarehouseActivityLine, PlaceBinCode);
            NextLineNo := NextLineNo + 10000;
            NewWarehouseActivityLine."Line No." := NextLineNo;
            NewWarehouseActivityLine."Action Type" := NewWarehouseActivityLine."Action Type"::Place;
            NewWarehouseActivityLine."Bin Code" := PlaceBinCode;
            if PlaceBinCode <> '' then begin
                RelatedBin.SetLoadFields("Zone Code");
                RelatedBin.Get(NewWarehouseActivityLine."Location Code", NewWarehouseActivityLine."Bin Code");
                NewWarehouseActivityLine."Zone Code" := RelatedBin."Zone Code";
            end;
            NewWarehouseActivityLine."Special Equipment Code" := GetSpecEquipmentCode(NewWarehouseActivityLine."Item No.", NewWarehouseActivityLine."Variant Code", NewWarehouseActivityLine."Location Code", PlaceBinCode);
            NewWarehouseActivityLine.Insert();
            UpdateHandledWhseActivityLineBuffer(NewWarehouseActivityLine, TakeBinCode);
        end;
        LineCreated := true;
        NextLineNo := NextLineNo + 10000;

        OnAfterSetLineData(CurrWarehouseActivityHeader, CurrLocation, NewWarehouseActivityLine);
    end;

    procedure GetSpecEquipmentCode(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; BinCode: Code[20]): Code[10]
    begin
        GetLocation(LocationCode);
        case CurrLocation."Special Equipment" of
            CurrLocation."Special Equipment"::"According to Bin":
                begin
                    GetBin(CurrLocation.Code, BinCode);
                    if CurrBin."Special Equipment Code" <> '' then
                        exit(CurrBin."Special Equipment Code");

                    GetItemAndSKU(ItemNo, LocationCode, VariantCode);
                    if CurrStockKeepingUnit."Special Equipment Code" <> '' then
                        exit(CurrStockKeepingUnit."Special Equipment Code");

                    exit(CurrItem."Special Equipment Code")
                end;
            CurrLocation."Special Equipment"::"According to SKU/Item":
                begin
                    GetItemAndSKU(ItemNo, LocationCode, VariantCode);
                    if CurrStockKeepingUnit."Special Equipment Code" <> '' then
                        exit(CurrStockKeepingUnit."Special Equipment Code");

                    if CurrItem."Special Equipment Code" <> '' then
                        exit(CurrItem."Special Equipment Code");

                    GetBin(CurrLocation.Code, BinCode);
                    exit(CurrBin."Special Equipment Code")
                end
        end
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
            if FindFirst() then begin
                Quantity += WarehouseActivityLine.Quantity;
                "Qty. (Base)" += WarehouseActivityLine."Qty. (Base)";
                OnUpdateHandledWhseActivityLineBufferOnBeforeTempInternalMovementLineModify(
                  TempInternalMovementLine, WarehouseActivityLine);
                Modify();
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
                Insert();
            end;
        end;
    end;

    procedure CreateATOPickLine(NewWarehouseActivityLine: Record "Warehouse Activity Line"; BinCode: Code[20]; var RemQtyToPickBase: Decimal)
    var
        ATOSalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
        AssemblySetup: Record "Assembly Setup";
        ReservationEntry: Record "Reservation Entry";
        TempTrackingSpecification1: Record "Tracking Specification" temporary;
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        QtyToAsmBase: Decimal;
        QtyToPickBase: Decimal;
    begin
        if (not IsInvtMovement) and
           WMSManagement.GetATOSalesLine(NewWarehouseActivityLine."Source Type",
             NewWarehouseActivityLine."Source Subtype",
             NewWarehouseActivityLine."Source No.",
             NewWarehouseActivityLine."Source Line No.",
             ATOSalesLine)
        then begin
            ATOSalesLine.AsmToOrderExists(AssemblyHeader);
            if NewWarehouseActivityLine.TrackingExists() then begin
                AssemblyHeader.SetReservationFilters(ReservationEntry);
                ReservationEntry.SetTrackingFilterFromWhseActivityLine(NewWarehouseActivityLine);
                ReservationEntry.SetRange(Positive, true);
                if ItemTrackingManagement.SumUpItemTracking(ReservationEntry, TempTrackingSpecification1, true, true) then
                    QtyToAsmBase := Abs(TempTrackingSpecification1."Qty. to Handle (Base)");
            end else
                QtyToAsmBase := ATOSalesLine.QtyToAsmBaseOnATO();
            WhseItemTrackingSetup.CopyTrackingFromWhseActivityLine(NewWarehouseActivityLine);
            QtyToPickBase := QtyToAsmBase - WMSManagement.CalcQtyBaseOnATOInvtPick(ATOSalesLine, WhseItemTrackingSetup);
            OnCreateATOPickLineOnAfterCalcQtyToPickBase(RemQtyToPickBase, QtyToPickBase, ATOSalesLine);
            if QtyToPickBase > 0 then begin
                MakeWarehouseActivityHeader();
                if CurrLocation."Bin Mandatory" and (BinCode = '') then
                    ATOSalesLine.GetATOBin(CurrLocation, BinCode);
                NewWarehouseActivityLine."Assemble to Order" := true;
                MakeWarehouseActivityLine(NewWarehouseActivityLine, BinCode, QtyToPickBase, RemQtyToPickBase);

                AssemblySetup.Get();
                if AssemblySetup."Create Movements Automatically" then
                    CreateATOInventoryMovementsAutomatically(AssemblyHeader, ATOInvtMovementsCreated, TotalATOInvtMovementsToBeCreated);
            end;
        end;
        OnAfterCreateATOPickLine(QtyToPickBase, AssemblyHeader, NewWarehouseActivityLine, CurrWarehouseActivityHeader, RemQtyToPickBase);
    end;

    local procedure CreateATOInventoryMovementsAutomatically(var AssemblyHeader: Record "Assembly Header"; var AssemToOrdInvtMovementsCreated: Integer; var TotalAssemToOrdInvtMovementsToBeCreated: Integer)
    var
        MovementsCreated: Integer;
        TotalMovementsCreated: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateATOInventoryMovementsAutomatically(AssemblyHeader, PrintDocument, ShowError, IsHandled);
        if IsHandled then
            exit;

        AssemblyHeader.CreateInvtMovement(true, PrintDocument, ShowError, MovementsCreated, TotalMovementsCreated);
        AssemToOrdInvtMovementsCreated += MovementsCreated;
        TotalAssemToOrdInvtMovementsToBeCreated += TotalMovementsCreated;
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

    local procedure CalcQtyAvailToPickOnBins(WarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup"; RemQtyToPickBase: Decimal) Result: Decimal
    var
        BinContent: Record "Bin Content";
        TotalAvailQtyToPickBase: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcQtyAvailToPickOnBins(WarehouseActivityLine, WhseItemTrackingSetup."Lot No.", WhseItemTrackingSetup."Serial No.", RemQtyToPickBase, Result, IsHandled);
        if IsHandled then
            exit(Result);

        TotalAvailQtyToPickBase := 0;

        with BinContent do begin
            SetRange("Location Code", WarehouseActivityLine."Location Code");
            if FromBinCode <> '' then
                SetRange("Bin Code", FromBinCode);
            SetRange("Item No.", WarehouseActivityLine."Item No.");
            SetRange("Variant Code", WarehouseActivityLine."Variant Code");
            SetTrackingFilterFromWhseItemTrackingSetup(WhseItemTrackingSetup);
            if Find('-') then
                repeat
                    TotalAvailQtyToPickBase += CalcQtyAvailToPick(0);
                until (Next() = 0) or (TotalAvailQtyToPickBase >= RemQtyToPickBase);
        end;

        exit(TotalAvailQtyToPickBase);
    end;

    local procedure IsItemOnBins(WarehouseActivityLine: Record "Warehouse Activity Line"): Boolean
    var
        BinContent: Record "Bin Content";
    begin
        with BinContent do begin
            SetRange("Location Code", WarehouseActivityLine."Location Code");
            SetRange("Item No.", WarehouseActivityLine."Item No.");
            SetRange("Variant Code", WarehouseActivityLine."Variant Code");
            exit(not IsEmpty);
        end;
    end;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    local procedure CopyReservEntriesToTemp(var TempReservationEntry1: Record "Reservation Entry" temporary; var ReservationEntry: Record "Reservation Entry")
    begin
        TempReservationEntry1.Reset();
        TempReservationEntry1.DeleteAll();

        if ReservationEntry.FindSet() then
            repeat
                TempReservationEntry1 := ReservationEntry;
                TempReservationEntry1.Insert();
            until ReservationEntry.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAutoCreatePickOrMove(var WarehouseRequest: Record "Warehouse Request"; LineCreated: Boolean; var WarehouseActivityHeader: Record "Warehouse Activity Header"; Location: Record Location; HideDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateATOPickLine(QtyToPickBase: Decimal; AssemblyHeader: Record "Assembly Header"; NewWarehouseActivityLine: Record "Warehouse Activity Line"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var RemQtyToPickBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateInventoryPickMovement(var WarehouseRequest: Record "Warehouse Request"; LineCreated: Boolean; var WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateInvtMvntWithoutSource(WhseActivHeader: Record "Warehouse Activity Header"; var InternalMovementHeader: Record "Internal Movement Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreatePickOrMoveFromTransfer(var WarehouseActivityHeader: Record "Warehouse Activity Header"; TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreatePickOrMoveFromSales(var WarehouseActivityHeader: Record "Warehouse Activity Header"; AutoCreation: Boolean; HideDialog: Boolean; var LineCreated: Boolean; IsInvtMovement: Boolean; IsBlankInvtMovement: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSourceDocHeader(var WarehouseRequest: Record "Warehouse Request"; var PostingDate: Date; var VendorDocNo: Code[35])
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterInsertWhseActivLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SNRequired: Boolean; LNRequired: Boolean; var RemQtyToPickBase: Decimal; var CompleteShipment: Boolean; var ReservationExists: Boolean; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertPickOrMoveBinWhseActLine(WarehouseActivityLine: Record "Warehouse Activity Line"; WarehouseActivityHeader: Record "Warehouse Activity Header"; var RemQtyToPickBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcTotalAvailQtyToPickBase(ItemNo: Code[20]; VariantNo: Code[10]; SerialNo: Code[50]; LotNo: Code[50]; LocationCode: Code[10]; BinCode: Code[20]; SourceType: Integer; SourceSubtype: Integer; SourceNo: Code[20]; SourceLineNo: Integer; SourceSublineNo: Integer; RemQtyToPickBase: Decimal; var TotalAvailQtyToPickBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrepareItemTrackingFromWhseIT(var ReservationEntry: Record "Reservation Entry"; EntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrepareItemTrackingForInternalMovement(InternalMovementLine: Record "Internal Movement Line"; var ReservationEntryBuffer: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetFilterSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; WarehouseActivityHeader: Record "Warehouse Activity Header"; WarehouseRequest: Record "Warehouse Request"; ShowError: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetLineData(WarehouseActivityHeader: Record "Warehouse Activity Header"; Location: Record Location; var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateWhseActivHeader(var WarehouseActivityHeader: Record "Warehouse Activity Header"; var WarehouseRequest: Record "Warehouse Request"; Location: Record Location)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoCreatePickOrMove(WarehouseRequest: Record "Warehouse Request"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var LineCreated: Boolean; var IsHandled: Boolean; var HideDialog: Boolean; IsInvtMovement: Boolean; IsBlankInvtMovement: Boolean; var CompleteShipment: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSourceDoc(WarehouseRequest: Record "Warehouse Request"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePickOrMoveLines(WarehouseRequest: Record "Warehouse Request"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var LinesCreated: Boolean; var IsHandled: Boolean; var HideDialog: Boolean; IsInvtMovement: Boolean; IsBlankInvtMovement: Boolean; var CompleteShipment: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePickOrMoveFromSales(var WarehouseActivityHeader: Record "Warehouse Activity Header"; SalesHeader: Record "Sales Header"; AutoCreation: Boolean; HideDialog: Boolean; var SalesLine: Record "Sales Line")
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
    local procedure OnBeforeCreateATOInventoryMovementsAutomatically(AssemblyHeader: Record "Assembly Header"; PrintDocumentForATOMvmt: Boolean; ShowErrorForATOMvmt: Boolean; var IsHandled: Boolean)
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
    local procedure OnBeforeNewWhseActivLineInsert(var WarehouseActivityLine: Record "Warehouse Activity Line"; WarehouseActivityHeader: Record "Warehouse Activity Header")
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
    local procedure OnBeforeOnRun(var WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindPurchLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; WarehouseActivityHeader: Record "Warehouse Activity Header"; WarehouseRequest: Record "Warehouse Request"; CheckLineExist: Boolean)
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
    local procedure OnBeforeGetSourceDocHeader(var WhseRequest: Record "Warehouse Request"; var IsHandled: Boolean; var RecordExists: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePickStrictExpirationPosting(ItemNo: Code[20]; SNRequired: Boolean; LNRequired: Boolean; var StrictExpirationPosting: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindFromBinContent(var FromBinContent: Record "Bin Content"; var WarehouseActivityLine: Record "Warehouse Activity Line"; FromBinCode: Code[20]; BinCode: Code[20]; IsInvtMovement: Boolean; IsBlankInvtMovement: Boolean; DefaultBin: Boolean; WhseItemTrackingSetup: Record "Item Tracking Setup"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var WarehouseRequest: Record "Warehouse Request")
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
    local procedure OnBeforeModifyWarehouseActivityHeader(var WarehouseActivityHeader: Record "Warehouse Activity Header"; WarehouseRequest: Record "Warehouse Request"; Location: Record Location)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseItemTrackingLineInsert(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRunCreatePickOrMoveLine(var WhseActivHeader: Record "Warehouse Activity Header"; var WhseRequest: Record "Warehouse Request")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunCreatePickOrMoveLine(var WhseActivHeader: Record "Warehouse Activity Header"; var WhseRequest: Record "Warehouse Request")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcInvtAvailabilityOnAfterCalcQtyBlocked(WarehouseActivityLine: Record "Warehouse Activity Line"; ItemTrackingSetup: Record "Item Tracking Setup"; var QtyBlocked: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateATOPickLineOnAfterCalcQtyToPickBase(var RemQtyToPickBase: Decimal; var QtyToPickBase: Decimal; ATOSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePickOrMoveLineOnAfterCheckForCompleteShipment(WarehouseActivityHeader: Record "Warehouse Activity Header"; WhseItemTrackingSetup: Record "Item Tracking Setup"; ReservationExists: Boolean; var RemQtyToPickBase: Decimal; var QtyAvailToPickBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCreatePickOrMoveLineOnAfterCalcQtyAvailToPickBase(var WarehouseActivityLine: Record "Warehouse Activity Line"; SNRequired: Boolean; LNRequired: Boolean; ReservationExists: Boolean; var RemQtyToPickBase: Decimal; var QtyAvailToPickBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePickOrMoveLineOnAfterFindTakeQtyForBinCodeOfSourceLineHandlingSpec(var NewWarehouseActivityLine: Record "Warehouse Activity Line"; TempHandlingSpecification: Record "Tracking Specification"; WhseItemTrackingSetup: Record "Item Tracking Setup"; var ITQtyToPickBase: Decimal; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

#if not CLEAN21
    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by OnCreatePickOrMoveLineOnAfterFindTakeQtyForBinCodeSourceLine with correct param name', '21.0')]
    local procedure OnCreatePickOrMoveLineOnAfterFindTakeQtyForBinCodeOfSourceLine(var NewWarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup"; var ITQtyToPickBase: Decimal)
    begin
    end;
#endif
    [IntegrationEvent(true, false)]
    local procedure OnCreatePickOrMoveLineOnAfterFindTakeQtyForBinCodeSourceLine(var NewWarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup"; var RemQtyToPickBase: Decimal; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePickOrMoveLineOnAfterGetWhseItemTrkgSetup(NewWarehouseActivityLine: Record "Warehouse Activity Line"; var WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePickOrMoveFromSalesOnAfterCreatePickOrMoveLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; var SalesLine: Record "Sales Line"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; ShowError: Boolean; AutoCreation: Boolean; var LineCreated: Boolean)
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
    local procedure OnCreateTempHandlingSpecOnAfterCalcTotalAvailQtyToPickBase(WhseActivLine: Record "Warehouse Activity Line"; EntrySummary: Record "Entry Summary"; var TotalAvailQtyToPickBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempHandlingSpecOnAfterWhseItemTrackingFEFOSetSource(var WhseItemTrackingFEFO: Codeunit "Whse. Item Tracking FEFO"; WarehouseActivityLine: Record "Warehouse Activity Line"; WarehouseRequest: Record "Warehouse Request")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempHandlingSpecOnAfterCalcQtyTracked(EntrySummary: Record "Entry Summary"; var QuantityTracked: Decimal; var TempHandlingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterCreatePickOrMoveLines(WarehouseRequest: Record "Warehouse Request"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var LinesCreated: Boolean; AutoCreation: Boolean; var SuppressMessage: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteHandledInternalMovementLinesOnAfterInternalMovementLineSetFilters(var InternalMovementLine: Record "Internal Movement Line"; InternalMovementHeaderNo: Code[20])
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
    local procedure OnGetSourceDocHeaderFromWhseRequest(var WarehouseRequest: Record "Warehouse Request"; var SourceDocRecRef: RecordRef; var PostingDate: Date; VendorDocNo: Code[35]; var RecordExists: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetWhseRequestOnBeforeSourceDocumentsRun(var WarehouseRequest: Record "Warehouse Request"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var Result: Boolean; var IsHandled: Boolean);
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
    local procedure OnItemTrackedQuantityOnAfterCheckTracking(var TempHandlingSpecification: Record "Tracking Specification" temporary; WhseItemTrackingSetup: Record "Item Tracking Setup"; var IsTrackingEmpty: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMakeLineOnBeforeUpdatePlaceLine(var NewWhseActivLine: Record "Warehouse Activity Line"; var PlaceBinCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetFilterInternalMomementOnAfterSetFilters(var InternalMovementLine: Record "Internal Movement Line"; InternalMovementHeader: Record "Internal Movement Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetFilterJobPlanningLineOnBeforeJobPlanningLineFind(var JobPlanningLine: Record "Job Planning Line"; Job: Record Job; var WhseActivHeader: Record "Warehouse Activity Header")
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

    [IntegrationEvent(false, false)]
    local procedure OnInsertPickOrMoveBinWhseActLineOnBeforeLoopMakeLine(var WhseActivHeader: Record "Warehouse Activity Header"; WhseRequest: Record "Warehouse Request"; var NewWhseActivLine: Record "Warehouse Activity Line"; FromBinContent: Record "Bin Content"; AutoCreation: Boolean; var QtyToPickBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertPickOrMoveBinWhseActLineOnBeforeLoopIteration(var FromBinContent: Record "Bin Content"; NewWarehouseActivityLine: Record "Warehouse Activity Line"; BinCode: Code[20]; DefaultBin: Boolean; var RemQtyToPickBase: Decimal; var IsHandled: Boolean; var QtyAvailToPickBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePickOrMoveLineOnAfterCalcShouldInsertPickOrMoveDefaultBin(NewWarehouseActivityLine: Record "Warehouse Activity Line"; var RemQtyToPickBase: Decimal; OutstandingQtyBase: Decimal; ReservationExists: Boolean; var ShouldInsertPickOrMoveDefaultBin: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertPickOrMoveBinWhseActLineOnAfterCalcQtyAvailToPick(var QtyAvailToPickBase: Decimal; var FromBinContent: Record "Bin Content")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcInvtAvailability(WhseActivLine: Record "Warehouse Activity Line"; Location: Record Location; var Result: Decimal; var IsHandled: Boolean; WhseItemTrackingSetup: Record "Item Tracking Setup"; IsBlankInvtMovement: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcQtyAvailToPickOnBins(WhseActivLine: Record "Warehouse Activity Line"; LotNo: Code[50]; SerialNo: Code[50]; RemQtyToPickBase: Decimal; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertShelfWhseActivLineOnAfterMakeHeader(var NewWhseActivLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePickOrMoveFromTransferOnAfterCreatePickOrMoveLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; var TransferLine: Record "Transfer Line"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; ShowError: Boolean; AutoCreation: Boolean; var LineCreated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAutoCreatePickOrMoveOnBeforeWarehouseActivityHeaderModify(var WarehouseActivityHeader: Record "Warehouse Activity Header"; WarehouseRequest: Record "Warehouse Request"; Location: Record Location)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertPickOrMoveBinWhseActLineOnBeforeMakeHeader(var RemQtyToPickBase: Decimal; var QtyAvailToPickBase: Decimal; var DefaultBin: Boolean; var FromBinContent: Record "Bin Content")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertPickOrMoveBinWhseActLineOnAfterMakeLine(var QtyToPickBase: Decimal; var DefaultBin: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePickOrMoveLineOnBeforeCheckIfInsertPickOrMoveBinWhseActLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; var RemQtyToPickBase: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnInsertPickOrMoveBinWhseActLineOnBeforeMakeLineWhenSNoReq(var NewWarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup"; TakeBinCode: Code[20]; QtyToPickBase: Decimal; var RemQtyToPickBase: Decimal; var QtyAvailToPickBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnInsertShelfWhseActivLineOnBeforeMakeShelfLineWhenSNoReq(var NewWarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup"; QtyToPickBase: Decimal; var RemQtyToPickBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertPickOrMoveBinWhseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; var RemQtyToPickBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMakeWarehouseActivityLine(var NewWarehouseActivityLine: Record "Warehouse Activity Line"; var RemQtyToPickBase: Decimal; var NextLineNo: Integer; TakeBinCode: Code[20]; var QtyToPickBase: Decimal; IsInvtMovement: Boolean; var LineCreated: Boolean; CompleteShipment: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertShelfWhseActivLineOnAfterMakeWarehouseActivityLine(var NewWhseActivLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetLineData(var WarehouseActivityLine: Record "Warehouse Activity Line"; WarehouseActivityHeader: Record "Warehouse Activity Header"; TakeBinCode: Code[20]; var NextLineNo: Integer; Location: Record Location; var LineCreated: Boolean; var IsHandled: Boolean)
    begin
    end;
}

