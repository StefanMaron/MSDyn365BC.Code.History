﻿namespace Microsoft.Inventory.Tracking;

using Microsoft.Assembly.Document;
using Microsoft.Assembly.History;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.HumanResources.Employee;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Item;
using Microsoft.Service.Loaner;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Activity.History;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.InventoryDocument;
using Microsoft.Warehouse.Ledger;
using System.Reflection;
using System.IO;

codeunit 6529 "Item Tracking Navigate Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        GlobalItemFilters: Record Item;
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemTrackingSetup: Record "Item Tracking Setup";
        ReservEntry: Record "Reservation Entry";
        MiscArticleInfo: Record "Misc. Article Information";
        FixedAsset: Record "Fixed Asset";
        WhseActivLine: Record "Warehouse Activity Line";
        RgstrdWhseActivLine: Record "Registered Whse. Activity Line";
        ServItemLine: Record "Service Item Line";
        Loaner: Record Loaner;
        ServiceItem: Record "Service Item";
        ServiceItemComponent: Record "Service Item Component";
        ServContractLine: Record "Service Contract Line";
        FiledContractLine: Record "Filed Contract Line";
        SerialNoInfo: Record "Serial No. Information";
        LotNoInfo: Record "Lot No. Information";
        PackageNoInfo: Record "Package No. Information";
        WhseEntry: Record "Warehouse Entry";
        PostedInvtPutAwayLine: Record "Posted Invt. Put-away Line";
        PostedInvtPickLine: Record "Posted Invt. Pick Line";
        JobLedgEntry: Record "Job Ledger Entry";
        TempPostedWhseRcptLine: Record "Posted Whse. Receipt Line" temporary;
        TempPostedWhseShptLine: Record "Posted Whse. Shipment Line" temporary;
        TempPurchRcptHeader: Record "Purch. Rcpt. Header" temporary;
        TempPurchInvHeader: Record "Purch. Inv. Header" temporary;
        TempAssemblyLine: Record "Assembly Line" temporary;
        TempAssemblyHeader: Record "Assembly Header" temporary;
        TempPostedAssemblyLine: Record "Posted Assembly Line" temporary;
        TempPostedAssemblyHeader: Record "Posted Assembly Header" temporary;
        TempPurchCrMemoHeader: Record "Purch. Cr. Memo Hdr." temporary;
        TempSalesShptHeader: Record "Sales Shipment Header" temporary;
        TempSalesInvHeader: Record "Sales Invoice Header" temporary;
        TempSalesCrMemoHeader: Record "Sales Cr.Memo Header" temporary;
        TempServShptHeader: Record "Service Shipment Header" temporary;
        TempServInvHeader: Record "Service Invoice Header" temporary;
        TempServCrMemoHeader: Record "Service Cr.Memo Header" temporary;
        TempReturnShipHeader: Record "Return Shipment Header" temporary;
        TempReturnRcptHeader: Record "Return Receipt Header" temporary;
        TempTransShipHeader: Record "Transfer Shipment Header" temporary;
        TempTransRcptHeader: Record "Transfer Receipt Header" temporary;
        TempProdOrder: Record "Production Order" temporary;
        TempSalesLine: Record "Sales Line" temporary;
        TempServLine: Record "Service Line" temporary;
        TempReqLine: Record "Requisition Line" temporary;
        TempPurchLine: Record "Purchase Line" temporary;
        TempItemJnlLine: Record "Item Journal Line" temporary;
        TempProdOrderLine: Record "Prod. Order Line" temporary;
        TempProdOrderComp: Record "Prod. Order Component" temporary;
        TempPlanningComponent: Record "Planning Component" temporary;
        TempTransLine: Record "Transfer Line" temporary;
        TempRecordBuffer: Record "Record Buffer" temporary;
        TempField: Record "Field" temporary;
        TempJobLedgEntry: Record "Job Ledger Entry" temporary;
        RecRef: RecordRef;
        LastEntryNo: Integer;

#if not CLEAN24
    [Obsolete('Replaced by same procedure with PackageNoFilter parameter', '24.0')]
    procedure FindTrackingRecords(SerialNoFilter: Text; LotNoFilter: Text; ItemNoFilter: Text; VariantFilter: Text)
    begin
        GlobalItemFilters.SetFilter("No.", ItemNoFilter);
        GlobalItemFilters.SetFilter("Variant Filter", VariantFilter);
        GlobalItemFilters.SetFilter("Serial No. Filter", SerialNoFilter);
        GlobalItemFilters.SetFilter("Lot No. Filter", LotNoFilter);
        FindTrackingRecords(GlobalItemFilters);
    end;
#endif

    procedure FindTrackingRecords(SerialNoFilter: Text; LotNoFilter: Text; PackageNoFilter: Text; ItemNoFilter: Text; VariantFilter: Text)
    begin
        GlobalItemFilters.SetFilter("No.", ItemNoFilter);
        GlobalItemFilters.SetFilter("Variant Filter", VariantFilter);
        GlobalItemFilters.SetFilter("Serial No. Filter", SerialNoFilter);
        GlobalItemFilters.SetFilter("Lot No. Filter", LotNoFilter);
        GlobalItemFilters.SetFilter("Package No. Filter", PackageNoFilter);
        FindTrackingRecords(GlobalItemFilters);
    end;

    procedure FindTrackingRecords(var ItemFilters: Record Item)
    var
        FiltersAreEmpty: Boolean;
    begin
        FiltersAreEmpty := (ItemFilters.GetFilter("Serial No. Filter") = '') and (ItemFilters.GetFilter("Lot No. Filter") = '') and (ItemFilters.GetFilter("Package No. Filter") = '');
        OnFindTrackingRecordsOnAfterCalcFiltersAreEmpty(ItemFilters, FiltersAreEmpty);
        if FiltersAreEmpty then
            exit;

        FindItemLedgerEntry(ItemFilters);
        FindReservEntry(ItemFilters);
        FindWhseActivLine(ItemFilters);
        FindRegWhseActivLine(ItemFilters);
        FindWhseEntry(ItemFilters);
        FindPostedInvtPutAwayLine(ItemFilters);
        FindPostedInvtPickLine(ItemFilters);

        // Only LotNos
        if ItemFilters.GetFilter("Lot No. Filter") <> '' then
            FindLotNoInfo(ItemFilters);

        // Only SerialNos
        if ItemFilters.GetFilter("Serial No. Filter") <> '' then begin
            FindSerialNoInfo(ItemFilters);
            FindSerialNoMisc(ItemFilters);
            FindSerialNoFixedAsset(ItemFilters);
            FindSerialNoServItemLine(ItemFilters);
            FindSerialNoLoaner(ItemFilters);
            FindSerialNoServiceItem(ItemFilters);
            FindSerialNoServiceItemComponent(ItemFilters);
            FindSerialNoServContractLine(ItemFilters);
            FindSerialNoFiledContractLine(ItemFilters);

            OnFindTrackingRecordsOnAfterFindSerialNo(TempRecordBuffer, ItemFilters);
        end;

        // Only PackageNos
        if ItemFilters.GetFilter("Package No. Filter") <> '' then
            FindPackageNoInfo(ItemFilters);

        FindJobLedgEntry(ItemFilters);

        OnAfterFindTrackingRecords(TempRecordBuffer, ItemFilters);
    end;

    local procedure FindLotNoInfo(var ItemFilters: Record Item)
    begin
        if not LotNoInfo.ReadPermission then
            exit;

        LotNoInfo.Reset();
        if LotNoInfo.SetCurrentKey("Lot No.") then;
        LotNoInfo.SetFilter("Lot No.", ItemFilters.GetFilter("Lot No. Filter"));
        LotNoInfo.SetFilter("Item No.", ItemFilters.GetFilter("No."));
        LotNoInfo.SetFilter("Variant Code", ItemFilters.GetFilter("Variant Filter"));
        if LotNoInfo.FindSet() then
            repeat
                RecRef.GetTable(LotNoInfo);
                Clear(ItemTrackingSetup);
                ItemTrackingSetup."Lot No." := LotNoInfo."Lot No.";
                InsertBufferRec(RecRef, ItemTrackingSetup, LotNoInfo."Item No.", LotNoInfo."Variant Code");
            until LotNoInfo.Next() = 0;
    end;

    local procedure FindSerialNoInfo(var ItemFilters: Record Item)
    begin
        if not SerialNoInfo.ReadPermission then
            exit;

        SerialNoInfo.Reset();
        if SerialNoInfo.SetCurrentKey("Serial No.") then;
        SerialNoInfo.SetFilter("Serial No.", ItemFilters.GetFilter("Serial No. Filter"));
        SerialNoInfo.SetFilter("Item No.", ItemFilters.GetFilter("No."));
        SerialNoInfo.SetFilter("Variant Code", ItemFilters.GetFilter("Variant Filter"));
        if SerialNoInfo.FindSet() then
            repeat
                RecRef.GetTable(SerialNoInfo);
                Clear(ItemTrackingSetup);
                ItemTrackingSetup."Serial No." := SerialNoInfo."Serial No.";
                InsertBufferRec(RecRef, ItemTrackingSetup, SerialNoInfo."Item No.", SerialNoInfo."Variant Code");
            until SerialNoInfo.Next() = 0;
    end;

    local procedure FindSerialNoMisc(var ItemFilters: Record Item)
    begin
        if not MiscArticleInfo.ReadPermission then
            exit;

        MiscArticleInfo.Reset();
        if MiscArticleInfo.SetCurrentKey("Serial No.") then;
        MiscArticleInfo.SetFilter("Serial No.", ItemFilters.GetFilter("Serial No. Filter"));
        if MiscArticleInfo.FindSet() then
            repeat
                RecRef.GetTable(MiscArticleInfo);
                Clear(ItemTrackingSetup);
                ItemTrackingSetup."Serial No." := MiscArticleInfo."Serial No.";
                InsertBufferRec(RecRef, ItemTrackingSetup, '', '');
            until MiscArticleInfo.Next() = 0;
    end;

    local procedure FindSerialNoFixedAsset(var ItemFilters: Record Item)
    begin
        if not FixedAsset.ReadPermission then
            exit;

        FixedAsset.Reset();
        if FixedAsset.SetCurrentKey("Serial No.") then;
        FixedAsset.SetFilter("Serial No.", ItemFilters.GetFilter("Serial No. Filter"));
        if FixedAsset.FindSet() then
            repeat
                RecRef.GetTable(FixedAsset);
                Clear(ItemTrackingSetup);
                ItemTrackingSetup."Serial No." := FixedAsset."Serial No.";
                InsertBufferRec(RecRef, ItemTrackingSetup, '', '');
            until FixedAsset.Next() = 0;
    end;

    local procedure FindSerialNoServItemLine(var ItemFilters: Record Item)
    begin
        if not ServItemLine.ReadPermission then
            exit;

        ServItemLine.Reset();
        if ServItemLine.SetCurrentKey("Serial No.") then;
        ServItemLine.SetFilter("Serial No.", ItemFilters.GetFilter("Serial No. Filter"));
        ServItemLine.SetFilter("Item No.", ItemFilters.GetFilter("No."));
        ServItemLine.SetFilter("Variant Code", ItemFilters.GetFilter("Variant Filter"));
        if ServItemLine.FindSet() then
            repeat
                RecRef.GetTable(ServItemLine);
                Clear(ItemTrackingSetup);
                ItemTrackingSetup."Serial No." := ServItemLine."Serial No.";
                InsertBufferRec(RecRef, ItemTrackingSetup, ServItemLine."Item No.", ServItemLine."Variant Code");
            until ServItemLine.Next() = 0;
    end;

    local procedure FindSerialNoServiceItem(var ItemFilters: Record Item)
    begin
        if not ServiceItem.ReadPermission then
            exit;

        ServiceItem.Reset();
        if ServiceItem.SetCurrentKey("Serial No.") then;
        ServiceItem.SetFilter("Serial No.", ItemFilters.GetFilter("Serial No. Filter"));
        ServiceItem.SetFilter("Item No.", ItemFilters.GetFilter("No."));
        ServiceItem.SetFilter("Variant Code", ItemFilters.GetFilter("Variant Filter"));
        if ServiceItem.FindSet() then
            repeat
                RecRef.GetTable(ServiceItem);
                Clear(ItemTrackingSetup);
                ItemTrackingSetup."Serial No." := ServiceItem."Serial No.";
                InsertBufferRec(RecRef, ItemTrackingSetup, ServiceItem."Item No.", ServiceItem."Variant Code");
            until ServiceItem.Next() = 0;
    end;

    local procedure FindSerialNoServiceItemComponent(var ItemFilters: Record Item)
    begin
        if not ServiceItemComponent.ReadPermission then
            exit;

        ServiceItemComponent.Reset();
        if ServiceItemComponent.SetCurrentKey("Serial No.") then;
        ServiceItemComponent.SetFilter("Serial No.", ItemFilters.GetFilter("Serial No. Filter"));
        ServiceItemComponent.SetFilter("Parent Service Item No.", ItemFilters.GetFilter("No."));
        ServiceItemComponent.SetFilter("Variant Code", ItemFilters.GetFilter("Variant Filter"));
        if ServiceItemComponent.FindSet() then
            repeat
                RecRef.GetTable(ServiceItemComponent);
                Clear(ItemTrackingSetup);
                ItemTrackingSetup."Serial No." := ServiceItemComponent."Serial No.";
                InsertBufferRec(RecRef, ItemTrackingSetup, ServiceItemComponent."Parent Service Item No.", ServiceItemComponent."Variant Code");
            until ServiceItemComponent.Next() = 0;
    end;

    local procedure FindSerialNoServContractLine(var ItemFilters: Record Item)
    begin
        if not ServContractLine.ReadPermission then
            exit;

        ServContractLine.Reset();
        if ServContractLine.SetCurrentKey("Serial No.") then;
        ServContractLine.SetFilter("Serial No.", ItemFilters.GetFilter("Serial No. Filter"));
        ServContractLine.SetFilter("Item No.", ItemFilters.GetFilter("No."));
        ServContractLine.SetFilter("Variant Code", ItemFilters.GetFilter("Variant Filter"));
        if ServContractLine.FindSet() then
            repeat
                RecRef.GetTable(ServContractLine);
                Clear(ItemTrackingSetup);
                ItemTrackingSetup."Serial No." := ServContractLine."Serial No.";
                InsertBufferRec(RecRef, ItemTrackingSetup, ServContractLine."Item No.", ServContractLine."Variant Code");
            until ServContractLine.Next() = 0;
    end;

    local procedure FindSerialNoLoaner(var ItemFilters: Record Item)
    begin
        if not Loaner.ReadPermission then
            exit;

        Loaner.Reset();
        if Loaner.SetCurrentKey("Serial No.") then;
        Loaner.SetFilter("Serial No.", ItemFilters.GetFilter("Serial No. Filter"));
        Loaner.SetFilter("Item No.", ItemFilters.GetFilter("No."));
        if Loaner.FindSet() then
            repeat
                RecRef.GetTable(Loaner);
                Clear(ItemTrackingSetup);
                ItemTrackingSetup."Serial No." := Loaner."Serial No.";
                InsertBufferRec(RecRef, ItemTrackingSetup, Loaner."Item No.", '');
            until Loaner.Next() = 0;
    end;

    local procedure FindSerialNoFiledContractLine(var ItemFilters: Record Item)
    begin
        if not FiledContractLine.ReadPermission then
            exit;

        FiledContractLine.Reset();
        if FiledContractLine.SetCurrentKey("Serial No.") then;
        FiledContractLine.SetFilter("Serial No.", ItemFilters.GetFilter("Serial No. Filter"));
        FiledContractLine.SetFilter("Item No.", ItemFilters.GetFilter("No."));
        FiledContractLine.SetFilter("Variant Code", ItemFilters.GetFilter("Variant Filter"));
        if FiledContractLine.FindSet() then
            repeat
                RecRef.GetTable(FiledContractLine);
                Clear(ItemTrackingSetup);
                ItemTrackingSetup."Serial No." := FiledContractLine."Serial No.";
                InsertBufferRec(RecRef, ItemTrackingSetup, FiledContractLine."Item No.", FiledContractLine."Variant Code");
            until FiledContractLine.Next() = 0;
    end;

    local procedure FindPackageNoInfo(var ItemFilters: Record Item)
    begin
        if not PackageNoInfo.ReadPermission then
            exit;

        PackageNoInfo.Reset();
        PackageNoInfo.SetFilter("Package No.", ItemFilters.GetFilter("Package No. Filter"));
        PackageNoInfo.SetFilter("Item No.", ItemFilters.GetFilter("No."));
        PackageNoInfo.SetFilter("Variant Code", ItemFilters.GetFilter("Variant Filter"));
        if PackageNoInfo.FindSet() then
            repeat
                RecRef.GetTable(PackageNoInfo);
                Clear(ItemTrackingSetup);
                ItemTrackingSetup."Package No." := PackageNoInfo."Package No.";
                InsertBufferRec(RecRef, ItemTrackingSetup, PackageNoInfo."Item No.", PackageNoInfo."Variant Code");
            until PackageNoInfo.Next() = 0;
    end;

    procedure SearchValueEntries()
    var
        ValueEntry: Record "Value Entry";
    begin
        if not ValueEntry.ReadPermission then
            exit;

        ValueEntry.Reset();
        ValueEntry.SetCurrentKey("Item Ledger Entry No.");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntry."Entry No.");
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Direct Cost");
        ValueEntry.SetFilter("Document Type", '<>%1', ItemLedgEntry."Document Type");
        if ValueEntry.FindSet() then
            repeat
                case ValueEntry."Document Type" of
                    ValueEntry."Document Type"::"Sales Invoice":
                        FindSalesInvoice(ValueEntry."Document No.");
                    ValueEntry."Document Type"::"Sales Credit Memo":
                        FindSalesCrMemo(ValueEntry."Document No.");
                    ValueEntry."Document Type"::"Service Invoice":
                        FindServInvoice(ValueEntry."Document No.");
                    ValueEntry."Document Type"::"Service Credit Memo":
                        FindServCrMemo(ValueEntry."Document No.");
                    ValueEntry."Document Type"::"Purchase Invoice":
                        FindPurchInvoice(ValueEntry."Document No.");
                    ValueEntry."Document Type"::"Purchase Credit Memo":
                        FindPurchCrMemo(ValueEntry."Document No.");
                end;
            until ValueEntry.Next() = 0;
    end;

    local procedure FindSalesInvoice(DocumentNo: Code[20])
    var
        SalesInvHeader: Record "Sales Invoice Header";
    begin
        if SalesInvHeader.ReadPermission then
            if SalesInvHeader.Get(DocumentNo) then begin
                RecRef.GetTable(SalesInvHeader);
                InsertBufferRecFromItemLedgEntry();
                TempSalesInvHeader := SalesInvHeader;
                if TempSalesInvHeader.Insert() then;
            end;
    end;

    local procedure FindSalesCrMemo(DocumentNo: Code[20])
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        if SalesCrMemoHeader.ReadPermission then
            if SalesCrMemoHeader.Get(DocumentNo) then begin
                RecRef.GetTable(SalesCrMemoHeader);
                InsertBufferRecFromItemLedgEntry();
                TempSalesCrMemoHeader := SalesCrMemoHeader;
                if TempSalesCrMemoHeader.Insert() then;
            end;
    end;

    local procedure FindSalesShptHeader(DocumentNo: Code[20])
    var
        SalesShptHeader: Record "Sales Shipment Header";
    begin
        if not SalesShptHeader.ReadPermission then
            exit;

        if SalesShptHeader.Get(DocumentNo) then begin
            RecRef.GetTable(SalesShptHeader);
            InsertBufferRecFromItemLedgEntry();
            TempSalesShptHeader := SalesShptHeader;
            if TempSalesShptHeader.Insert() then;
            FindPostedWhseShptLine();
            // Find Invoice if it exists
            SearchValueEntries();
        end;
    end;

    local procedure FindSalesLines()
    var
        SalesLine: Record "Sales Line";
    begin
        if not SalesLine.ReadPermission then
            exit;

        if SalesLine.Get(ReservEntry."Source Subtype", ReservEntry."Source ID", ReservEntry."Source Ref. No.") then begin
            RecRef.GetTable(SalesLine);
            InsertBufferRecFromReservEntry();
            TempSalesLine := SalesLine;
            if TempSalesLine.Insert() then;
        end;
    end;

    local procedure FindServiceLines()
    var
        ServLine: Record "Service Line";
    begin
        if not ServLine.ReadPermission then
            exit;

        if ServLine.Get(ReservEntry."Source Subtype", ReservEntry."Source ID", ReservEntry."Source Ref. No.") then begin
            RecRef.GetTable(ServLine);
            InsertBufferRecFromReservEntry();
            TempServLine := ServLine;
            if TempServLine.Insert() then;
        end;
    end;

    local procedure FindPurchaseLines()
    var
        PurchLine: Record "Purchase Line";
    begin
        if not PurchLine.ReadPermission then
            exit;

        if PurchLine.Get(ReservEntry."Source Subtype", ReservEntry."Source ID", ReservEntry."Source Ref. No.") then begin
            RecRef.GetTable(PurchLine);
            InsertBufferRecFromReservEntry();
            TempPurchLine := PurchLine;
            if TempPurchLine.Insert() then;
        end;
    end;

    local procedure FindRequisitionLines()
    var
        ReqLine: Record "Requisition Line";
    begin
        if not ReqLine.ReadPermission then
            exit;

        if ReqLine.Get(ReservEntry."Source ID", ReservEntry."Source Batch Name", ReservEntry."Source Ref. No.") then begin
            RecRef.GetTable(ReqLine);
            InsertBufferRecFromReservEntry();
            TempReqLine := ReqLine;
            if TempReqLine.Insert() then;
        end;
    end;

    local procedure FindPlanningComponent()
    var
        PlanningComponent: Record "Planning Component";
    begin
        if not PlanningComponent.ReadPermission then
            exit;

        if PlanningComponent.Get(ReservEntry."Source ID", ReservEntry."Source Batch Name", ReservEntry."Source Prod. Order Line", ReservEntry."Source Ref. No.") then begin
            RecRef.GetTable(PlanningComponent);
            InsertBufferRecFromReservEntry();
            TempPlanningComponent := PlanningComponent;
            if TempPlanningComponent.Insert() then;
        end;
    end;

    local procedure FindItemJournalLines()
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        if not ItemJnlLine.ReadPermission then
            exit;

        if ItemJnlLine.Get(ReservEntry."Source ID", ReservEntry."Source Batch Name", ReservEntry."Source Ref. No.") then begin
            RecRef.GetTable(ItemJnlLine);
            InsertBufferRecFromReservEntry();
            TempItemJnlLine := ItemJnlLine;
            if TempItemJnlLine.Insert() then;
        end;
    end;

    local procedure FindAssemblyHeaders()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        if not AssemblyHeader.ReadPermission then
            exit;

        if AssemblyHeader.Get(ReservEntry."Source Subtype", ReservEntry."Source ID") then begin
            RecRef.GetTable(AssemblyHeader);
            InsertBufferRecFromReservEntry();
            TempAssemblyHeader := AssemblyHeader;
            if TempAssemblyHeader.Insert() then;
        end;
    end;

    local procedure FindAssemblyLines()
    var
        AssemblyLine: Record "Assembly Line";
    begin
        if not AssemblyLine.ReadPermission then
            exit;

        if AssemblyLine.Get(ReservEntry."Source Subtype", ReservEntry."Source ID", ReservEntry."Source Ref. No.") then begin
            RecRef.GetTable(AssemblyLine);
            InsertBufferRecFromReservEntry();
            TempAssemblyLine := AssemblyLine;
            if TempAssemblyLine.Insert() then;
        end;
    end;

    local procedure FindProdOrderLines()
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        if not ProdOrderLine.ReadPermission then
            exit;

        if ProdOrderLine.Get(ReservEntry."Source Subtype", ReservEntry."Source ID", ReservEntry."Source Prod. Order Line") then begin
            RecRef.GetTable(ProdOrderLine);
            InsertBufferRecFromReservEntry();
            TempProdOrderLine := ProdOrderLine;
            if TempProdOrderLine.Insert() then;
        end;
    end;

    local procedure FindProdOrderComponents()
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        if not ProdOrderComp.ReadPermission then
            exit;

        if ProdOrderComp.Get(ReservEntry."Source Subtype", ReservEntry."Source ID", ReservEntry."Source Prod. Order Line", ReservEntry."Source Ref. No.") then begin
            RecRef.GetTable(ProdOrderComp);
            InsertBufferRecFromReservEntry();
            TempProdOrderComp := ProdOrderComp;
            if TempProdOrderComp.Insert() then;
        end;
    end;

    local procedure FindTransferLines()
    var
        TransLine: Record "Transfer Line";
    begin
        if not TransLine.ReadPermission then
            exit;

        if TransLine.Get(ReservEntry."Source ID", ReservEntry."Source Ref. No.") then begin
            RecRef.GetTable(TransLine);
            InsertBufferRecFromReservEntry();
            TempTransLine := TransLine;
            if TempTransLine.Insert() then;
        end;
    end;

    local procedure FindServInvoice(DocumentNo: Code[20])
    var
        ServInvHeader: Record "Service Invoice Header";
    begin
        if not ServInvHeader.ReadPermission then
            exit;

        if ServInvHeader.Get(DocumentNo) then begin
            RecRef.GetTable(ServInvHeader);
            InsertBufferRecFromItemLedgEntry();
            TempServInvHeader := ServInvHeader;
            if TempServInvHeader.Insert() then;
        end;
    end;

    local procedure FindServCrMemo(DocumentNo: Code[20])
    var
        ServCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        if not ServCrMemoHeader.ReadPermission then
            exit;

        if ServCrMemoHeader.Get(DocumentNo) then begin
            RecRef.GetTable(ServCrMemoHeader);
            InsertBufferRecFromItemLedgEntry();
            TempServCrMemoHeader := ServCrMemoHeader;
            if TempServCrMemoHeader.Insert() then;
        end;
    end;

    local procedure FindServShptHeader(DocumentNo: Code[20])
    var
        ServShptHeader: Record "Service Shipment Header";
    begin
        if not ServShptHeader.ReadPermission then
            exit;

        if ServShptHeader.Get(DocumentNo) then begin
            RecRef.GetTable(ServShptHeader);
            InsertBufferRecFromItemLedgEntry();
            TempServShptHeader := ServShptHeader;
            if TempServShptHeader.Insert() then;
            // Find Invoice if it exists
            SearchValueEntries();
        end;
    end;

    local procedure FindPurchInvoice(DocumentNo: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        if not PurchInvHeader.ReadPermission then
            exit;

        if PurchInvHeader.Get(DocumentNo) then begin
            RecRef.GetTable(PurchInvHeader);
            InsertBufferRecFromItemLedgEntry();
            TempPurchInvHeader := PurchInvHeader;
            if TempPurchInvHeader.Insert() then;
        end;
    end;

    local procedure FindPurchCrMemo(DocumentNo: Code[20])
    var
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
    begin
        if not PurchCrMemoHeader.ReadPermission then
            exit;

        if PurchCrMemoHeader.Get(DocumentNo) then begin
            RecRef.GetTable(PurchCrMemoHeader);
            InsertBufferRecFromItemLedgEntry();
            TempPurchCrMemoHeader := PurchCrMemoHeader;
            if TempPurchCrMemoHeader.Insert() then;
        end;
    end;

    local procedure FindPurchRcptHeader(DocumentNo: Code[20])
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
    begin
        if not PurchRcptHeader.ReadPermission then
            exit;

        if PurchRcptHeader.Get(DocumentNo) then begin
            RecRef.GetTable(PurchRcptHeader);
            InsertBufferRecFromItemLedgEntry();
            TempPurchRcptHeader := PurchRcptHeader;
            if TempPurchRcptHeader.Insert() then;
            FindPostedWhseRcptLine();
            // Find Invoice if it exists
            SearchValueEntries();
        end;
    end;

    local procedure FindPostedAssembly(DocumentNo: Code[20])
    var
        PostedAssemblyHeader: Record "Posted Assembly Header";
    begin
        if not PostedAssemblyHeader.ReadPermission then
            exit;

        if PostedAssemblyHeader.Get(DocumentNo) then begin
            RecRef.GetTable(PostedAssemblyHeader);
            InsertBufferRecFromItemLedgEntry();
            TempPostedAssemblyHeader := PostedAssemblyHeader;
            if TempPostedAssemblyHeader.Insert() then;
        end;
    end;

    procedure FindPostedWhseShptLine()
    var
        PostedWhseShptLine: Record "Posted Whse. Shipment Line";
    begin
        if not PostedWhseShptLine.ReadPermission then
            exit;

        PostedWhseShptLine.Reset();
        PostedWhseShptLine.SetCurrentKey("Posted Source No.", "Posting Date");
        PostedWhseShptLine.SetRange("Posted Source No.", ItemLedgEntry."Document No.");
        PostedWhseShptLine.SetRange("Posting Date", ItemLedgEntry."Posting Date");
        PostedWhseShptLine.SetRange("Item No.", ItemLedgEntry."Item No.");
        PostedWhseShptLine.SetRange("Variant Code", ItemLedgEntry."Variant Code");
        PostedWhseShptLine.SetRange("Source Line No.", ItemLedgEntry."Document Line No.");
        if PostedWhseShptLine.FindFirst() then begin
            RecRef.GetTable(PostedWhseShptLine);
            InsertBufferRecFromItemLedgEntry();
            TempPostedWhseShptLine := PostedWhseShptLine;
            if TempPostedWhseShptLine.Insert() then;
        end;
    end;

    local procedure FindPostedWhseRcptLine()
    var
        PostedWhseRcptLine: Record "Posted Whse. Receipt Line";
    begin
        if not PostedWhseRcptLine.ReadPermission then
            exit;

        PostedWhseRcptLine.Reset();
        PostedWhseRcptLine.SetCurrentKey("Posted Source No.", PostedWhseRcptLine."Posting Date");
        PostedWhseRcptLine.SetRange("Posted Source No.", ItemLedgEntry."Document No.");
        PostedWhseRcptLine.SetRange("Posting Date", ItemLedgEntry."Posting Date");
        PostedWhseRcptLine.SetRange("Item No.", ItemLedgEntry."Item No.");
        PostedWhseRcptLine.SetRange("Variant Code", ItemLedgEntry."Variant Code");
        PostedWhseRcptLine.SetRange("Source Line No.", ItemLedgEntry."Document Line No.");
        if PostedWhseRcptLine.FindFirst() then begin
            RecRef.GetTable(PostedWhseRcptLine);
            InsertBufferRecFromItemLedgEntry();
            TempPostedWhseRcptLine := PostedWhseRcptLine;
            if TempPostedWhseRcptLine.Insert() then;
        end;
    end;

    local procedure FindPostedInvtPickLine(var ItemFilters: Record Item)
    begin
        if not PostedInvtPickLine.ReadPermission then
            exit;

        PostedInvtPickLine.Reset();
        if ItemFilters.GetFilter("Lot No. Filter") <> '' then
            if PostedInvtPickLine.SetCurrentKey("Lot No.") then;
        if ItemFilters.GetFilter("Package No. Filter") <> '' then
            if PostedInvtPickLine.SetCurrentKey("Package No.") then;
        if ItemFilters.GetFilter("Serial No. Filter") <> '' then
            if PostedInvtPickLine.SetCurrentKey("Serial No.") then;
        PostedInvtPickLine.SetFilter("Lot No.", ItemFilters.GetFilter("Lot No. Filter"));
        PostedInvtPickLine.SetFilter("Serial No.", ItemFilters.GetFilter("Serial No. Filter"));
        PostedInvtPickLine.SetFilter("Package No.", ItemFilters.GetFilter("Package No. Filter"));
        PostedInvtPickLine.SetFilter("Item No.", ItemFilters.GetFilter("No."));
        PostedInvtPickLine.SetFilter("Variant Code", ItemFilters.GetFilter("Variant Filter"));
        if PostedInvtPickLine.FindSet() then
            repeat
                RecRef.GetTable(PostedInvtPickLine);
                Clear(ItemTrackingSetup);
                ItemTrackingSetup.CopyTrackingFromPostedInvtPickLine(PostedInvtPickLine);
                InsertBufferRec(RecRef, ItemTrackingSetup, PostedInvtPickLine."Item No.", PostedInvtPickLine."Variant Code");
            until PostedInvtPickLine.Next() = 0;
    end;

    local procedure FindPostedInvtPutAwayLine(var ItemFilters: Record Item)
    begin
        if not PostedInvtPutAwayLine.ReadPermission then
            exit;

        PostedInvtPutAwayLine.Reset();
        if ItemFilters.GetFilter("Lot No. Filter") <> '' then
            if PostedInvtPutAwayLine.SetCurrentKey("Lot No.") then;
        if ItemFilters.GetFilter("Package No. Filter") <> '' then
            if PostedInvtPutAwayLine.SetCurrentKey("Package No.") then;
        if ItemFilters.GetFilter("Serial No. Filter") <> '' then
            if PostedInvtPutAwayLine.SetCurrentKey("Serial No.") then;
        PostedInvtPutAwayLine.SetFilter("Lot No.", ItemFilters.GetFilter("Lot No. Filter"));
        PostedInvtPutAwayLine.SetFilter("Serial No.", ItemFilters.GetFilter("Serial No. Filter"));
        PostedInvtPutAwayLine.SetFilter("Package No.", ItemFilters.GetFilter("Package No. Filter"));
        PostedInvtPutAwayLine.SetFilter("Item No.", ItemFilters.GetFilter("No."));
        PostedInvtPutAwayLine.SetFilter("Variant Code", ItemFilters.GetFilter("Variant Filter"));
        if PostedInvtPutAwayLine.FindSet() then
            repeat
                RecRef.GetTable(PostedInvtPutAwayLine);
                Clear(ItemTrackingSetup);
                ItemTrackingSetup.CopyTrackingFromPostedInvtPutAwayLine(PostedInvtPutAwayLine);
                InsertBufferRec(RecRef, ItemTrackingSetup, PostedInvtPutAwayLine."Item No.", PostedInvtPutAwayLine."Variant Code");
            until PostedInvtPutAwayLine.Next() = 0;
    end;

    local procedure FindProductionOrder(DocumentNo: Code[20])
    var
        ProdOrder: Record "Production Order";
    begin
        if not ProdOrder.ReadPermission then
            exit;

        ProdOrder.SetRange(Status, ProdOrder.Status::Released, ProdOrder.Status::Finished);
        ProdOrder.SetRange("No.", DocumentNo);
        if ProdOrder.FindFirst() then begin
            RecRef.GetTable(ProdOrder);
            InsertBufferRecFromItemLedgEntry();
            TempProdOrder := ProdOrder;
            if TempProdOrder.Insert() then;
        end;
    end;

    local procedure FindRegWhseActivLine(var ItemFilters: Record Item)
    begin
        if not RgstrdWhseActivLine.ReadPermission then
            exit;

        RgstrdWhseActivLine.Reset();
        if ItemFilters.GetFilter("Lot No. Filter") <> '' then
            if RgstrdWhseActivLine.SetCurrentKey("Lot No.") then;
        if ItemFilters.GetFilter("Package No. Filter") <> '' then
            if RgstrdWhseActivLine.SetCurrentKey("Package No.") then;
        if ItemFilters.GetFilter("Serial No. Filter") <> '' then
            if RgstrdWhseActivLine.SetCurrentKey("Serial No.") then;
        RgstrdWhseActivLine.SetFilter("Lot No.", ItemFilters.GetFilter("Lot No. Filter"));
        RgstrdWhseActivLine.SetFilter("Serial No.", ItemFilters.GetFilter("Serial No. Filter"));
        RgstrdWhseActivLine.SetFilter("Package No.", ItemFilters.GetFilter("Package No. Filter"));
        RgstrdWhseActivLine.SetFilter("Item No.", ItemFilters.GetFilter("No."));
        RgstrdWhseActivLine.SetFilter("Variant Code", ItemFilters.GetFilter("Variant Filter"));
        if RgstrdWhseActivLine.FindSet() then
            repeat
                RecRef.GetTable(RgstrdWhseActivLine);
                Clear(ItemTrackingSetup);
                ItemTrackingSetup.CopyTrackingFromRegisteredWhseActivityLine(RgstrdWhseActivLine);
                InsertBufferRec(RecRef, ItemTrackingSetup, RgstrdWhseActivLine."Item No.", RgstrdWhseActivLine."Variant Code");
            until RgstrdWhseActivLine.Next() = 0;
    end;

    local procedure FindItemLedgerEntry(var ItemFilters: Record Item)
    var
        IsHandled: Boolean;
    begin
        if not ItemLedgEntry.ReadPermission then
            exit;

        ItemLedgEntry.Reset();
        if ItemFilters.GetFilter("Lot No. Filter") <> '' then
            if ItemLedgEntry.SetCurrentKey("Lot No.") then;
        if ItemFilters.GetFilter("Package No. Filter") <> '' then
            if ItemLedgEntry.SetCurrentKey("Package No.") then;
        if ItemFilters.GetFilter("Serial No. Filter") <> '' then
            if ItemLedgEntry.SetCurrentKey("Serial No.") then;
        ItemLedgEntry.SetFilter("Lot No.", ItemFilters.GetFilter("Lot No. Filter"));
        ItemLedgEntry.SetFilter("Serial No.", ItemFilters.GetFilter("Serial No. Filter"));
        ItemLedgEntry.SetFilter("Package No.", ItemFilters.GetFilter("Package No. Filter"));
        ItemLedgEntry.SetFilter("Item No.", ItemFilters.GetFilter("No."));
        ItemLedgEntry.SetFilter("Variant Code", ItemFilters.GetFilter("Variant Filter"));
        if ItemLedgEntry.FindSet() then
            repeat
                RecRef.GetTable(ItemLedgEntry);
                Clear(ItemTrackingSetup);
                ItemTrackingSetup.CopyTrackingFromItemLedgerEntry(ItemLedgEntry);
                InsertBufferRec(RecRef, ItemTrackingSetup, ItemLedgEntry."Item No.", ItemLedgEntry."Variant Code");
                IsHandled := false;
                OnFindItemLedgerEntryOnBeforeCaseDocumentType(ItemLedgEntry, RecRef, IsHandled);
                if not IsHandled then
                    case ItemLedgEntry."Document Type" of
                        ItemLedgEntry."Document Type"::"Sales Shipment":
                            FindSalesShptHeader(ItemLedgEntry."Document No.");
                        ItemLedgEntry."Document Type"::"Sales Invoice":
                            FindSalesInvoice(ItemLedgEntry."Document No.");
                        ItemLedgEntry."Document Type"::"Service Shipment":
                            FindServShptHeader(ItemLedgEntry."Document No.");
                        ItemLedgEntry."Document Type"::"Service Invoice":
                            FindServInvoice(ItemLedgEntry."Document No.");
                        ItemLedgEntry."Document Type"::"Service Credit Memo":
                            FindServCrMemo(ItemLedgEntry."Document No.");
                        ItemLedgEntry."Document Type"::"Sales Return Receipt":
                            FindReturnRcptHeader(ItemLedgEntry."Document No.");
                        ItemLedgEntry."Document Type"::"Sales Credit Memo":
                            FindSalesCrMemo(ItemLedgEntry."Document No.");
                        ItemLedgEntry."Document Type"::"Purchase Receipt":
                            FindPurchRcptHeader(ItemLedgEntry."Document No.");
                        ItemLedgEntry."Document Type"::"Purchase Invoice":
                            FindPurchInvoice(ItemLedgEntry."Document No.");
                        ItemLedgEntry."Document Type"::"Purchase Return Shipment":
                            FindReturnShptHeader(ItemLedgEntry."Document No.");
                        ItemLedgEntry."Document Type"::"Purchase Credit Memo":
                            FindPurchCrMemo(ItemLedgEntry."Document No.");
                        ItemLedgEntry."Document Type"::"Transfer Shipment":
                            FindTransShptHeader(ItemLedgEntry."Document No.");
                        ItemLedgEntry."Document Type"::"Transfer Receipt":
                            FindTransRcptHeader(ItemLedgEntry."Document No.");
                        ItemLedgEntry."Document Type"::"Posted Assembly":
                            FindPostedAssembly(ItemLedgEntry."Document No.");
                        else
                            if ItemLedgEntry."Entry Type" in [ItemLedgEntry."Entry Type"::Consumption, ItemLedgEntry."Entry Type"::Output] then
                                FindProductionOrder(ItemLedgEntry."Document No.");
                    end;
                OnFindTrackingRecordsForItemLedgerEntry(ItemLedgEntry);
            until ItemLedgEntry.Next() = 0;
    end;

    local procedure FindReturnRcptHeader(DocumentNo: Code[20])
    var
        ReturnRcptHeader: Record "Return Receipt Header";
    begin
        if not ReturnRcptHeader.ReadPermission then
            exit;

        if ReturnRcptHeader.Get(DocumentNo) then begin
            RecRef.GetTable(ReturnRcptHeader);
            InsertBufferRecFromItemLedgEntry();
            TempReturnRcptHeader := ReturnRcptHeader;
            if TempReturnRcptHeader.Insert() then;
            FindPostedWhseRcptLine();
            // Find CreditMemo if it exists
            SearchValueEntries();
        end;
    end;

    local procedure FindReturnShptHeader(DocumentNo: Code[20])
    var
        ReturnShptHeader: Record "Return Shipment Header";
    begin
        if not ReturnShptHeader.ReadPermission then
            exit;

        if ReturnShptHeader.Get(DocumentNo) then begin
            RecRef.GetTable(ReturnShptHeader);
            InsertBufferRecFromItemLedgEntry();
            TempReturnShipHeader := ReturnShptHeader;
            if TempReturnShipHeader.Insert() then;
            FindPostedWhseShptLine();
            // Find CreditMemo if it exists
            SearchValueEntries();
        end;
    end;

    local procedure FindTransShptHeader(DocumentNo: Code[20])
    var
        TransShptHeader: Record "Transfer Shipment Header";
    begin
        if not TransShptHeader.ReadPermission then
            exit;

        if TransShptHeader.Get(DocumentNo) then begin
            RecRef.GetTable(TransShptHeader);
            InsertBufferRecFromItemLedgEntry();
            TempTransShipHeader := TransShptHeader;
            if TempTransShipHeader.Insert() then;
            FindPostedWhseShptLine();
        end;
    end;

    local procedure FindTransRcptHeader(DocumentNo: Code[20])
    var
        TransRcptHeader: Record "Transfer Receipt Header";
    begin
        if not TransRcptHeader.ReadPermission then
            exit;

        if TransRcptHeader.Get(DocumentNo) then begin
            RecRef.GetTable(TransRcptHeader);
            InsertBufferRecFromItemLedgEntry();
            TempTransRcptHeader := TransRcptHeader;
            if TempTransRcptHeader.Insert() then;
            FindPostedWhseRcptLine();
        end;
    end;

    local procedure FindJobLedgEntry(var ItemFilters: Record Item)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindJobLedgEntry(TempJobLedgEntry, ItemFilters, IsHandled);
        if IsHandled then
            exit;

        if not JobLedgEntry.ReadPermission then
            exit;

        JobLedgEntry.Reset();
        if ItemFilters.GetFilter("Lot No. Filter") <> '' then
            if JobLedgEntry.SetCurrentKey("Lot No.") then;
        if ItemFilters.GetFilter("Package No. Filter") <> '' then
            if JobLedgEntry.SetCurrentKey("Package No.") then;
        if ItemFilters.GetFilter("Serial No. Filter") <> '' then
            if JobLedgEntry.SetCurrentKey("Serial No.") then;
        JobLedgEntry.SetFilter("Lot No.", ItemFilters.GetFilter("Lot No. Filter"));
        JobLedgEntry.SetFilter("Serial No.", ItemFilters.GetFilter("Serial No. Filter"));
        JobLedgEntry.SetFilter("Package No.", ItemFilters.GetFilter("Package No. Filter"));
        JobLedgEntry.SetFilter("Variant Code", ItemFilters.GetFilter("Variant Filter"));
        if JobLedgEntry.FindSet() then
            repeat
                RecRef.GetTable(JobLedgEntry);
                Clear(ItemTrackingSetup);
                ItemTrackingSetup.CopyTrackingFromJobLedgerEntry(JobLedgEntry);
                InsertBufferRec(RecRef, ItemTrackingSetup, '', JobLedgEntry."Variant Code");
                TempJobLedgEntry := JobLedgEntry;
                if TempJobLedgEntry.Insert() then;
            until JobLedgEntry.Next() = 0;
    end;

    local procedure FindReservEntry(var ItemFilters: Record Item)
    var
        IsHandled: Boolean;
    begin
        if not ReservEntry.ReadPermission then
            exit;

        ReservEntry.Reset();
        if ItemFilters.GetFilter("Lot No. Filter") <> '' then
            if ReservEntry.SetCurrentKey("Lot No.") then;
        if ItemFilters.GetFilter("Package No. Filter") <> '' then
            if ReservEntry.SetCurrentKey("Package No.") then;
        if ItemFilters.GetFilter("Serial No. Filter") <> '' then
            if ReservEntry.SetCurrentKey("Serial No.") then;
        ReservEntry.SetFilter("Lot No.", ItemFilters.GetFilter("Lot No. Filter"));
        ReservEntry.SetFilter("Serial No.", ItemFilters.GetFilter("Serial No. Filter"));
        ReservEntry.SetFilter("Package No.", ItemFilters.GetFilter("Package No. Filter"));
        ReservEntry.SetFilter("Item No.", ItemFilters.GetFilter("No."));
        ReservEntry.SetFilter("Variant Code", ItemFilters.GetFilter("Variant Filter"));
        if ReservEntry.FindSet() then
            repeat
                RecRef.GetTable(ReservEntry);
                Clear(ItemTrackingSetup);
                ItemTrackingSetup.CopyTrackingFromReservEntry(ReservEntry);
                InsertBufferRec(RecRef, ItemTrackingSetup, ReservEntry."Item No.", ReservEntry."Variant Code");
                IsHandled := false;
                OnFindReservEntryOnBeforeCaseDocumentType(ReservEntry, RecRef, IsHandled);
                if not IsHandled then
                    case ReservEntry."Source Type" of
                        Database::"Sales Line":
                            FindSalesLines();
                        Database::"Service Line":
                            FindServiceLines();
                        Database::"Purchase Line":
                            FindPurchaseLines();
                        Database::"Requisition Line":
                            FindRequisitionLines();
                        Database::"Planning Component":
                            FindPlanningComponent();
                        Database::"Item Journal Line":
                            FindItemJournalLines();
                        Database::"Assembly Line":
                            FindAssemblyLines();
                        Database::"Assembly Header":
                            FindAssemblyHeaders();
                        Database::"Prod. Order Line":
                            FindProdOrderLines();
                        Database::"Prod. Order Component":
                            FindProdOrderComponents();
                        Database::"Transfer Line":
                            FindTransferLines();
                    end;
            until ReservEntry.Next() = 0;
    end;

    local procedure FindWhseActivLine(var ItemFilters: Record Item)
    begin
        if not WhseActivLine.ReadPermission then
            exit;

        WhseActivLine.Reset();
        if ItemFilters.GetFilter("Lot No. Filter") <> '' then
            if WhseActivLine.SetCurrentKey("Lot No.") then;
        if ItemFilters.GetFilter("Package No. Filter") <> '' then
            if WhseActivLine.SetCurrentKey("Package No.") then;
        if ItemFilters.GetFilter("Serial No. Filter") <> '' then
            if WhseActivLine.SetCurrentKey("Serial No.") then;
        WhseActivLine.SetFilter("Lot No.", ItemFilters.GetFilter("Lot No. Filter"));
        WhseActivLine.SetFilter("Serial No.", ItemFilters.GetFilter("Serial No. Filter"));
        WhseActivLine.SetFilter("Package No.", ItemFilters.GetFilter("Package No. Filter"));
        WhseActivLine.SetFilter("Item No.", ItemFilters.GetFilter("No."));
        WhseActivLine.SetFilter("Variant Code", ItemFilters.GetFilter("Variant Filter"));
        if WhseActivLine.FindSet() then
            repeat
                RecRef.GetTable(WhseActivLine);
                Clear(ItemTrackingSetup);
                ItemTrackingSetup.CopyTrackingFromWhseActivityLine(WhseActivLine);
                InsertBufferRec(RecRef, ItemTrackingSetup, WhseActivLine."Item No.", WhseActivLine."Variant Code");
            until WhseActivLine.Next() = 0;
    end;

    local procedure FindWhseEntry(var ItemFilters: Record Item)
    begin
        if not WhseEntry.ReadPermission then
            exit;

        WhseEntry.Reset();
        if ItemFilters.GetFilter("Lot No. Filter") <> '' then
            if WhseEntry.SetCurrentKey("Lot No.") then;
        if ItemFilters.GetFilter("Package No. Filter") <> '' then
            if WhseEntry.SetCurrentKey("Package No.") then;
        if ItemFilters.GetFilter("Serial No. Filter") <> '' then
            if WhseEntry.SetCurrentKey("Serial No.") then;
        WhseEntry.SetFilter("Lot No.", ItemFilters.GetFilter("Lot No. Filter"));
        WhseEntry.SetFilter("Serial No.", ItemFilters.GetFilter("Serial No. Filter"));
        WhseEntry.SetFilter("Package No.", ItemFilters.GetFilter("Package No. Filter"));
        WhseEntry.SetFilter("Item No.", ItemFilters.GetFilter("No."));
        WhseEntry.SetFilter("Variant Code", ItemFilters.GetFilter("Variant Filter"));
        if WhseEntry.FindSet() then
            repeat
                RecRef.GetTable(WhseEntry);
                Clear(ItemTrackingSetup);
                ItemTrackingSetup.CopyTrackingFromWhseEntry(WhseEntry);
                InsertBufferRec(RecRef, ItemTrackingSetup, WhseEntry."Item No.", WhseEntry."Variant Code");
            until WhseEntry.Next() = 0;
    end;

    procedure Show(TableNo: Integer)
    begin
        case TableNo of
            Database::"Item Ledger Entry":
                PAGE.Run(0, ItemLedgEntry);
            Database::"Reservation Entry":
                PAGE.Run(0, ReservEntry);
            Database::"Misc. Article Information":
                PAGE.Run(0, MiscArticleInfo);
            Database::"Fixed Asset":
                PAGE.Run(0, FixedAsset);
            Database::"Warehouse Activity Line":
                PAGE.Run(0, WhseActivLine);
            Database::"Registered Whse. Activity Line":
                PAGE.Run(0, RgstrdWhseActivLine);
            Database::"Service Item Line":
                PAGE.Run(0, ServItemLine);
            Database::Loaner:
                PAGE.Run(0, Loaner);
            Database::"Service Item":
                PAGE.Run(0, ServiceItem);
            Database::"Service Item Component":
                PAGE.Run(0, ServiceItemComponent);
            Database::"Service Contract Line":
                PAGE.Run(0, ServContractLine);
            Database::"Filed Contract Line":
                PAGE.Run(0, FiledContractLine);
            Database::"Serial No. Information":
                PAGE.Run(0, SerialNoInfo);
            Database::"Lot No. Information":
                PAGE.Run(0, LotNoInfo);
            Database::"Package No. Information":
                PAGE.Run(0, PackageNoInfo);
            Database::"Warehouse Entry":
                PAGE.Run(0, WhseEntry);
            Database::"Posted Whse. Shipment Line":
                PAGE.Run(0, TempPostedWhseShptLine);
            Database::"Posted Whse. Receipt Line":
                PAGE.Run(0, TempPostedWhseRcptLine);
            Database::"Posted Invt. Put-away Line":
                PAGE.Run(0, PostedInvtPutAwayLine);
            Database::"Posted Invt. Pick Line":
                PAGE.Run(0, PostedInvtPickLine);
            Database::"Purch. Rcpt. Header":
                PAGE.Run(0, TempPurchRcptHeader);
            Database::"Purch. Inv. Header":
                PAGE.Run(0, TempPurchInvHeader);
            Database::"Purch. Cr. Memo Hdr.":
                PAGE.Run(0, TempPurchCrMemoHeader);
            Database::"Sales Shipment Header":
                PAGE.Run(0, TempSalesShptHeader);
            Database::"Sales Invoice Header":
                PAGE.Run(0, TempSalesInvHeader);
            Database::"Sales Cr.Memo Header":
                PAGE.Run(0, TempSalesCrMemoHeader);
            Database::"Service Shipment Header":
                PAGE.Run(0, TempServShptHeader);
            Database::"Service Invoice Header":
                PAGE.Run(0, TempServInvHeader);
            Database::"Service Cr.Memo Header":
                PAGE.Run(0, TempServCrMemoHeader);
            Database::"Transfer Shipment Header":
                PAGE.Run(0, TempTransShipHeader);
            Database::"Return Shipment Header":
                PAGE.Run(0, TempReturnShipHeader);
            Database::"Return Receipt Header":
                PAGE.Run(0, TempReturnRcptHeader);
            Database::"Transfer Receipt Header":
                PAGE.Run(0, TempTransRcptHeader);
            Database::"Production Order":
                PAGE.Run(0, TempProdOrder);
            Database::"Sales Line":
                PAGE.Run(0, TempSalesLine);
            Database::"Service Line":
                PAGE.Run(0, TempServLine);
            Database::"Purchase Line":
                PAGE.Run(0, TempPurchLine);
            Database::"Requisition Line":
                PAGE.Run(0, TempReqLine);
            Database::"Item Journal Line":
                PAGE.Run(0, TempItemJnlLine);
            Database::"Prod. Order Line":
                PAGE.Run(0, TempProdOrderLine);
            Database::"Prod. Order Component":
                PAGE.Run(0, TempProdOrderComp);
            Database::"Planning Component":
                PAGE.Run(0, TempPlanningComponent);
            Database::"Transfer Line":
                PAGE.Run(0, TempTransLine);
            Database::"Job Ledger Entry":
                PAGE.Run(0, TempJobLedgEntry);
            Database::"Assembly Line":
                PAGE.Run(0, TempAssemblyLine);
            Database::"Assembly Header":
                PAGE.Run(0, TempAssemblyHeader);
            Database::"Posted Assembly Line":
                PAGE.Run(0, TempPostedAssemblyLine);
            Database::"Posted Assembly Header":
                PAGE.Run(0, TempPostedAssemblyHeader);
        end;

        OnAfterShow(TableNo, TempRecordBuffer);
    end;

    local procedure InsertBufferRecFromItemLedgEntry()
    var
        TrackingRecRef: RecordRef;
    begin
        TrackingRecRef.GetTable(ItemLedgEntry);
        Clear(ItemTrackingSetup);
        ItemTrackingSetup.CopyTrackingFromItemLedgerEntry(ItemLedgEntry);
        InsertBufferRec(RecRef, ItemTrackingSetup, ItemLedgEntry."Item No.", ItemLedgEntry."Variant Code", TrackingRecRef);
    end;

    local procedure InsertBufferRecFromReservEntry()
    begin
        Clear(ItemTrackingSetup);
        ItemTrackingSetup.CopyTrackingFromReservEntry(ReservEntry);
        InsertBufferRec(RecRef, ItemTrackingSetup, ReservEntry."Item No.", ReservEntry."Variant Code");
    end;

    procedure InsertBufferRec(RecRef: RecordRef; ItemTrackingSetup: Record "Item Tracking Setup"; ItemNo: Code[20]; VariantCode: Code[10])
    var
        DummyTrackingRecRef: RecordRef;
    begin
        InsertBufferRec(RecRef, ItemTrackingSetup, ItemNo, VariantCode, DummyTrackingRecRef);
    end;

    local procedure InsertBufferRec(RecRef: RecordRef; ItemTrackingSetup: Record "Item Tracking Setup"; ItemNo: Code[20]; VariantCode: Code[10]; TrackingRecRef: RecordRef)
    var
        KeyFldRef: FieldRef;
        KeyRef1: KeyRef;
        i: Integer;
        SkipProcedure: Boolean;
    begin
        SkipProcedure := not ItemTrackingSetup.TrackingExists();
        OnInsertBufferRecOnAfterCalcSkipProcedure(VariantCode, SkipProcedure);
        if SkipProcedure then
            exit;

        TempRecordBuffer.SetRange("Record Identifier", RecRef.RecordId);
        TempRecordBuffer.SetTrackingFilterFromItemTrackingSetup(ItemTrackingSetup);
        TempRecordBuffer.SetRange("Item No.", ItemNo);
        TempRecordBuffer.SetRange("Variant Code", VariantCode);
        if not TempRecordBuffer.Find('-') then begin
            TempRecordBuffer.Init();
            TempRecordBuffer."Entry No." := LastEntryNo + 10;
            LastEntryNo := TempRecordBuffer."Entry No.";

            TempRecordBuffer."Table No." := RecRef.Number;
            TempRecordBuffer."Table Name" := GetTableCaption(RecRef.Number);
            TempRecordBuffer."Record Identifier" := RecRef.RecordId;
            TempRecordBuffer."Search Record ID" :=
                CopyStr(Format(TempRecordBuffer."Record Identifier"), 1, MaxStrLen(TempRecordBuffer."Search Record ID"));

            KeyRef1 := RecRef.KeyIndex(1);
            for i := 1 to KeyRef1.FieldCount do begin
                KeyFldRef := KeyRef1.FieldIndex(i);
                if i = 1 then
                    TempRecordBuffer."Primary Key" :=
                        CopyStr(
                            StrSubstNo('%1=%2', KeyFldRef.Caption, FormatValue(KeyFldRef, RecRef.Number)),
                            1, MaxStrLen(TempRecordBuffer."Primary Key"))
                else
                    if MaxStrLen(TempRecordBuffer."Primary Key") >
                       StrLen(TempRecordBuffer."Primary Key") +
                       StrLen(StrSubstNo(', %1=%2', KeyFldRef.Caption, FormatValue(KeyFldRef, RecRef.Number)))
                    then
                        TempRecordBuffer."Primary Key" :=
                            CopyStr(
                                TempRecordBuffer."Primary Key" +
                                StrSubstNo(', %1=%2', KeyFldRef.Caption, FormatValue(KeyFldRef, RecRef.Number)),
                                1, MaxStrLen(TempRecordBuffer."Primary Key"));
                case i of
                    1:
                        begin
                            TempRecordBuffer."Primary Key Field 1 No." := KeyFldRef.Number;
                            TempRecordBuffer."Primary Key Field 1 Value" :=
                                CopyStr(
                                    FormatValue(KeyFldRef, RecRef.Number), 1, MaxStrLen(TempRecordBuffer."Primary Key Field 1 Value"));
                        end;
                    2:
                        begin
                            TempRecordBuffer."Primary Key Field 2 No." := KeyFldRef.Number;
                            TempRecordBuffer."Primary Key Field 2 Value" :=
                                CopyStr(
                                    FormatValue(KeyFldRef, RecRef.Number), 1, MaxStrLen(TempRecordBuffer."Primary Key Field 2 Value"));
                        end;
                    3:
                        begin
                            TempRecordBuffer."Primary Key Field 3 No." := KeyFldRef.Number;
                            TempRecordBuffer."Primary Key Field 3 Value" :=
                                CopyStr(
                                    FormatValue(KeyFldRef, RecRef.Number), 1, MaxStrLen(TempRecordBuffer."Primary Key Field 3 Value"));
                        end;
                end;
            end;

            TempRecordBuffer."Item No." := ItemNo;
            TempRecordBuffer."Variant Code" := VariantCode;
            TempRecordBuffer.CopyTrackingFromItemTrackingSetup(ItemTrackingSetup);

            OnBeforeTempRecordBufferInsert(TempRecordBuffer, RecRef, TrackingRecRef);
            TempRecordBuffer.Insert();
        end;
    end;

    procedure Collect(var RecordBuffer: Record "Record Buffer" temporary)
    begin
        RecordBuffer.Reset();
        RecordBuffer.DeleteAll();

        TempRecordBuffer.Reset();
        if TempRecordBuffer.Find('-') then
            repeat
                RecordBuffer := TempRecordBuffer;
                RecordBuffer.Insert();
            until TempRecordBuffer.Next() = 0;
    end;

    local procedure GetTableCaption(TableNumber: Integer): Text[250]
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        AllObjWithCaption.Reset();
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::TableData);
        AllObjWithCaption.SetRange("Object ID", TableNumber);
        if AllObjWithCaption.FindFirst() then
            exit(AllObjWithCaption."Object Caption");

        exit('');
    end;

    local procedure FormatValue(var FldRef: FieldRef; TableNumber: Integer): Text[250]
    var
        "Field": Record "Field";
        OptionNo: Integer;
        OptionStr: Text[1024];
        i: Integer;
    begin
        GetField(TableNumber, FldRef.Number, Field);
        if Field.Type = Field.Type::Option then begin
            OptionNo := FldRef.Value();
            OptionStr := Format(FldRef.OptionCaption);
            for i := 1 to OptionNo do
                OptionStr := CopyStr(OptionStr, StrPos(OptionStr, ',') + 1);
            if StrPos(OptionStr, ',') > 0 then
                if StrPos(OptionStr, ',') = 1 then
                    OptionStr := ''
                else
                    OptionStr := CopyStr(OptionStr, 1, StrPos(OptionStr, ',') - 1);
            exit(OptionStr);
        end;
        exit(Format(FldRef.Value));
    end;

    local procedure GetField(TableNumber: Integer; FieldNumber: Integer; var Field2: Record "Field")
    var
        "Field": Record "Field";
    begin
        if not TempField.Get(TableNumber, FieldNumber) then begin
            Field.Get(TableNumber, FieldNumber);
            TempField := Field;
            TempField.Insert();
        end;
        Field2 := TempField;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShow(TableID: Integer; var TempRecordBuffer: Record "Record Buffer" temporary)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterFindTrackingRecords(var TempRecordBuffer: Record "Record Buffer" temporary; var ItemFilters: Record Item)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeFindJobLedgEntry(var TempJobLedgerEntry: Record "Job Ledger Entry" temporary; var ItemFilters: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempRecordBufferInsert(var TempRecordBuffer: Record "Record Buffer" temporary; RecRef: RecordRef; TrackingRecRef: RecordRef);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindTrackingRecordsOnAfterCalcFiltersAreEmpty(var ItemFilters: Record Item; var FiltersAreEmpty: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindTrackingRecordsForItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindTrackingRecordsOnAfterFindSerialNo(var TempRecordBuffer: Record "Record Buffer" temporary; var ItemFilters: Record Item)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnFindItemLedgerEntryOnBeforeCaseDocumentType(var ItemLedgerEntry: Record "Item Ledger Entry"; RecRef: RecordRef; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnFindReservEntryOnBeforeCaseDocumentType(var ReservationEntry: Record "Reservation Entry"; RecRef: RecordRef; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertBufferRecOnAfterCalcSkipProcedure(VariantCode: Code[10]; var SkipProcedure: Boolean)
    begin
    end;
}

