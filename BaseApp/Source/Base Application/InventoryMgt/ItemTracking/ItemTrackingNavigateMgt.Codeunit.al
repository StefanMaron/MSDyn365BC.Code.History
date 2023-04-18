codeunit 6529 "Item Tracking Navigate Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        ItemFilters: Record Item;
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

    procedure FindTrackingRecords(SerialNoFilter: Text; LotNoFilter: Text; ItemNoFilter: Text; VariantFilter: Text)
    begin
        ItemFilters.SetFilter("No.", ItemNoFilter);
        ItemFilters.SetFilter("Variant Filter", VariantFilter);
        ItemFilters.SetFilter("Serial No. Filter", SerialNoFilter);
        ItemFilters.SetFilter("Lot No. Filter", LotNoFilter);
        FindTrackingRecords(ItemFilters);
    end;

    procedure FindTrackingRecords(SerialNoFilter: Text; LotNoFilter: Text; PackageNoFilter: Text; ItemNoFilter: Text; VariantFilter: Text)
    begin
        ItemFilters.SetFilter("No.", ItemNoFilter);
        ItemFilters.SetFilter("Variant Filter", VariantFilter);
        ItemFilters.SetFilter("Serial No. Filter", SerialNoFilter);
        ItemFilters.SetFilter("Lot No. Filter", LotNoFilter);
        ItemFilters.SetFilter("Package No. Filter", PackageNoFilter);
        FindTrackingRecords(ItemFilters);
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

        with LotNoInfo do begin
            Reset();
            if SetCurrentKey("Lot No.") then;
            SetFilter("Lot No.", ItemFilters.GetFilter("Lot No. Filter"));
            SetFilter("Item No.", ItemFilters.GetFilter("No."));
            SetFilter("Variant Code", ItemFilters.GetFilter("Variant Filter"));
            if FindSet() then
                repeat
                    RecRef.GetTable(LotNoInfo);
                    Clear(ItemTrackingSetup);
                    ItemTrackingSetup."Lot No." := "Lot No.";
                    InsertBufferRec(RecRef, ItemTrackingSetup, "Item No.", "Variant Code");
                until Next() = 0;
        end;
    end;

    local procedure FindSerialNoInfo(var ItemFilters: Record Item)
    begin
        if not SerialNoInfo.ReadPermission then
            exit;

        with SerialNoInfo do begin
            Reset();
            if SetCurrentKey("Serial No.") then;
            SetFilter("Serial No.", ItemFilters.GetFilter("Serial No. Filter"));
            SetFilter("Item No.", ItemFilters.GetFilter("No."));
            SetFilter("Variant Code", ItemFilters.GetFilter("Variant Filter"));
            if FindSet() then
                repeat
                    RecRef.GetTable(SerialNoInfo);
                    Clear(ItemTrackingSetup);
                    ItemTrackingSetup."Serial No." := "Serial No.";
                    InsertBufferRec(RecRef, ItemTrackingSetup, "Item No.", "Variant Code");
                until Next() = 0;
        end;
    end;

    local procedure FindSerialNoMisc(var ItemFilters: Record Item)
    begin
        if not MiscArticleInfo.ReadPermission then
            exit;

        with MiscArticleInfo do begin
            Reset();
            if SetCurrentKey("Serial No.") then;
            SetFilter("Serial No.", ItemFilters.GetFilter("Serial No. Filter"));
            if FindSet() then
                repeat
                    RecRef.GetTable(MiscArticleInfo);
                    Clear(ItemTrackingSetup);
                    ItemTrackingSetup."Serial No." := "Serial No.";
                    InsertBufferRec(RecRef, ItemTrackingSetup, '', '');
                until Next() = 0;
        end;
    end;

    local procedure FindSerialNoFixedAsset(var ItemFilters: Record Item)
    begin
        if not FixedAsset.ReadPermission then
            exit;

        with FixedAsset do begin
            Reset();
            if SetCurrentKey("Serial No.") then;
            SetFilter("Serial No.", ItemFilters.GetFilter("Serial No. Filter"));
            if FindSet() then
                repeat
                    RecRef.GetTable(FixedAsset);
                    Clear(ItemTrackingSetup);
                    ItemTrackingSetup."Serial No." := "Serial No.";
                    InsertBufferRec(RecRef, ItemTrackingSetup, '', '');
                until Next() = 0;
        end;
    end;

    local procedure FindSerialNoServItemLine(var ItemFilters: Record Item)
    begin
        if not ServItemLine.ReadPermission then
            exit;

        with ServItemLine do begin
            Reset();
            if SetCurrentKey("Serial No.") then;
            SetFilter("Serial No.", ItemFilters.GetFilter("Serial No. Filter"));
            SetFilter("Item No.", ItemFilters.GetFilter("No."));
            SetFilter("Variant Code", ItemFilters.GetFilter("Variant Filter"));
            if FindSet() then
                repeat
                    RecRef.GetTable(ServItemLine);
                    Clear(ItemTrackingSetup);
                    ItemTrackingSetup."Serial No." := "Serial No.";
                    InsertBufferRec(RecRef, ItemTrackingSetup, "Item No.", "Variant Code");
                until Next() = 0;
        end;
    end;

    local procedure FindSerialNoServiceItem(var ItemFilters: Record Item)
    begin
        if not ServiceItem.ReadPermission then
            exit;

        with ServiceItem do begin
            Reset();
            if SetCurrentKey("Serial No.") then;
            SetFilter("Serial No.", ItemFilters.GetFilter("Serial No. Filter"));
            SetFilter("Item No.", ItemFilters.GetFilter("No."));
            SetFilter("Variant Code", ItemFilters.GetFilter("Variant Filter"));
            if FindSet() then
                repeat
                    RecRef.GetTable(ServiceItem);
                    Clear(ItemTrackingSetup);
                    ItemTrackingSetup."Serial No." := "Serial No.";
                    InsertBufferRec(RecRef, ItemTrackingSetup, "Item No.", "Variant Code");
                until Next() = 0;
        end;
    end;

    local procedure FindSerialNoServiceItemComponent(var ItemFilters: Record Item)
    begin
        if not ServiceItemComponent.ReadPermission then
            exit;

        with ServiceItemComponent do begin
            Reset();
            if SetCurrentKey("Serial No.") then;
            SetFilter("Serial No.", ItemFilters.GetFilter("Serial No. Filter"));
            SetFilter("Parent Service Item No.", ItemFilters.GetFilter("No."));
            SetFilter("Variant Code", ItemFilters.GetFilter("Variant Filter"));
            if FindSet() then
                repeat
                    RecRef.GetTable(ServiceItemComponent);
                    Clear(ItemTrackingSetup);
                    ItemTrackingSetup."Serial No." := "Serial No.";
                    InsertBufferRec(RecRef, ItemTrackingSetup, "Parent Service Item No.", "Variant Code");
                until Next() = 0;
        end;
    end;

    local procedure FindSerialNoServContractLine(var ItemFilters: Record Item)
    begin
        if not ServContractLine.ReadPermission then
            exit;

        with ServContractLine do begin
            Reset();
            if SetCurrentKey("Serial No.") then;
            SetFilter("Serial No.", ItemFilters.GetFilter("Serial No. Filter"));
            SetFilter("Item No.", ItemFilters.GetFilter("No."));
            SetFilter("Variant Code", ItemFilters.GetFilter("Variant Filter"));
            if FindSet() then
                repeat
                    RecRef.GetTable(ServContractLine);
                    Clear(ItemTrackingSetup);
                    ItemTrackingSetup."Serial No." := "Serial No.";
                    InsertBufferRec(RecRef, ItemTrackingSetup, "Item No.", "Variant Code");
                until Next() = 0;
        end;
    end;

    local procedure FindSerialNoLoaner(var ItemFilters: Record Item)
    begin
        if not Loaner.ReadPermission then
            exit;

        with Loaner do begin
            Reset();
            if SetCurrentKey("Serial No.") then;
            SetFilter("Serial No.", ItemFilters.GetFilter("Serial No. Filter"));
            SetFilter("Item No.", ItemFilters.GetFilter("No."));
            if FindSet() then
                repeat
                    RecRef.GetTable(Loaner);
                    Clear(ItemTrackingSetup);
                    ItemTrackingSetup."Serial No." := "Serial No.";
                    InsertBufferRec(RecRef, ItemTrackingSetup, "Item No.", '');
                until Next() = 0;
        end;
    end;

    local procedure FindSerialNoFiledContractLine(var ItemFilters: Record Item)
    begin
        if not FiledContractLine.ReadPermission then
            exit;

        with FiledContractLine do begin
            Reset();
            if SetCurrentKey("Serial No.") then;
            SetFilter("Serial No.", ItemFilters.GetFilter("Serial No. Filter"));
            SetFilter("Item No.", ItemFilters.GetFilter("No."));
            SetFilter("Variant Code", ItemFilters.GetFilter("Variant Filter"));
            if FindSet() then
                repeat
                    RecRef.GetTable(FiledContractLine);
                    Clear(ItemTrackingSetup);
                    ItemTrackingSetup."Serial No." := "Serial No.";
                    InsertBufferRec(RecRef, ItemTrackingSetup, "Item No.", "Variant Code");
                until Next() = 0;
        end;
    end;

    local procedure FindPackageNoInfo(var ItemFilters: Record Item)
    begin
        if not PackageNoInfo.ReadPermission then
            exit;

        with PackageNoInfo do begin
            Reset();
            SetFilter("Package No.", ItemFilters.GetFilter("Package No. Filter"));
            SetFilter("Item No.", ItemFilters.GetFilter("No."));
            SetFilter("Variant Code", ItemFilters.GetFilter("Variant Filter"));
            if FindSet() then
                repeat
                    RecRef.GetTable(PackageNoInfo);
                    Clear(ItemTrackingSetup);
                    ItemTrackingSetup."Package No." := "Package No.";
                    InsertBufferRec(RecRef, ItemTrackingSetup, "Item No.", "Variant Code");
                until Next() = 0;
        end;
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

        with ReservEntry do
            if SalesLine.Get("Source Subtype", "Source ID", "Source Ref. No.") then begin
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

        with ReservEntry do
            if ServLine.Get("Source Subtype", "Source ID", "Source Ref. No.") then begin
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

        with ReservEntry do
            if PurchLine.Get("Source Subtype", "Source ID", "Source Ref. No.") then begin
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

        with ReservEntry do
            if ReqLine.Get("Source ID", "Source Batch Name", "Source Ref. No.") then begin
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

        with ReservEntry do
            if PlanningComponent.Get("Source ID", "Source Batch Name", "Source Prod. Order Line", "Source Ref. No.") then begin
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

        with ReservEntry do
            if ItemJnlLine.Get("Source ID", "Source Batch Name", "Source Ref. No.") then begin
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

        with ReservEntry do
            if AssemblyHeader.Get("Source Subtype", "Source ID") then begin
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

        with ReservEntry do
            if AssemblyLine.Get("Source Subtype", "Source ID", "Source Ref. No.") then begin
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

        with ReservEntry do
            if ProdOrderLine.Get("Source Subtype", "Source ID", "Source Prod. Order Line") then begin
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

        with ReservEntry do
            if ProdOrderComp.Get("Source Subtype", "Source ID", "Source Prod. Order Line", "Source Ref. No.") then begin
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

        with ReservEntry do
            if TransLine.Get("Source ID", "Source Ref. No.") then begin
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

        with PostedWhseShptLine do begin
            Reset();
            SetCurrentKey("Posted Source No.", "Posting Date");
            SetRange("Posted Source No.", ItemLedgEntry."Document No.");
            SetRange("Posting Date", ItemLedgEntry."Posting Date");
            SetRange("Item No.", ItemLedgEntry."Item No.");
            SetRange("Variant Code", ItemLedgEntry."Variant Code");
            SetRange("Source Line No.", ItemLedgEntry."Document Line No.");
            if FindFirst() then begin
                RecRef.GetTable(PostedWhseShptLine);
                InsertBufferRecFromItemLedgEntry();
                TempPostedWhseShptLine := PostedWhseShptLine;
                if TempPostedWhseShptLine.Insert() then;
            end;
        end;
    end;

    local procedure FindPostedWhseRcptLine()
    var
        PostedWhseRcptLine: Record "Posted Whse. Receipt Line";
    begin
        if not PostedWhseRcptLine.ReadPermission then
            exit;

        with PostedWhseRcptLine do begin
            Reset();
            SetCurrentKey("Posted Source No.", "Posting Date");
            SetRange("Posted Source No.", ItemLedgEntry."Document No.");
            SetRange("Posting Date", ItemLedgEntry."Posting Date");
            SetRange("Item No.", ItemLedgEntry."Item No.");
            SetRange("Variant Code", ItemLedgEntry."Variant Code");
            SetRange("Source Line No.", ItemLedgEntry."Document Line No.");
            if FindFirst() then begin
                RecRef.GetTable(PostedWhseRcptLine);
                InsertBufferRecFromItemLedgEntry();
                TempPostedWhseRcptLine := PostedWhseRcptLine;
                if TempPostedWhseRcptLine.Insert() then;
            end;
        end;
    end;

    local procedure FindPostedInvtPickLine(var ItemFilters: Record Item)
    begin
        if not PostedInvtPickLine.ReadPermission then
            exit;

        with PostedInvtPickLine do begin
            Reset();
            if ItemFilters.GetFilter("Lot No. Filter") <> '' then
                if SetCurrentKey("Lot No.") then;
            if ItemFilters.GetFilter("Package No. Filter") <> '' then
                if SetCurrentKey("Package No.") then;
            if ItemFilters.GetFilter("Serial No. Filter") <> '' then
                if SetCurrentKey("Serial No.") then;
            SetFilter("Lot No.", ItemFilters.GetFilter("Lot No. Filter"));
            SetFilter("Serial No.", ItemFilters.GetFilter("Serial No. Filter"));
            SetFilter("Package No.", ItemFilters.GetFilter("Package No. Filter"));
            SetFilter("Item No.", ItemFilters.GetFilter("No."));
            SetFilter("Variant Code", ItemFilters.GetFilter("Variant Filter"));
            if FindSet() then
                repeat
                    RecRef.GetTable(PostedInvtPickLine);
                    Clear(ItemTrackingSetup);
                    ItemTrackingSetup.CopyTrackingFromPostedInvtPickLine(PostedInvtPickLine);
                    InsertBufferRec(RecRef, ItemTrackingSetup, "Item No.", "Variant Code");
                until Next() = 0;
        end;
    end;

    local procedure FindPostedInvtPutAwayLine(var ItemFilters: Record Item)
    begin
        if not PostedInvtPutAwayLine.ReadPermission then
            exit;

        with PostedInvtPutAwayLine do begin
            Reset();
            if ItemFilters.GetFilter("Lot No. Filter") <> '' then
                if SetCurrentKey("Lot No.") then;
            if ItemFilters.GetFilter("Package No. Filter") <> '' then
                if SetCurrentKey("Package No.") then;
            if ItemFilters.GetFilter("Serial No. Filter") <> '' then
                if SetCurrentKey("Serial No.") then;
            SetFilter("Lot No.", ItemFilters.GetFilter("Lot No. Filter"));
            SetFilter("Serial No.", ItemFilters.GetFilter("Serial No. Filter"));
            SetFilter("Package No.", ItemFilters.GetFilter("Package No. Filter"));
            SetFilter("Item No.", ItemFilters.GetFilter("No."));
            SetFilter("Variant Code", ItemFilters.GetFilter("Variant Filter"));
            if FindSet() then
                repeat
                    RecRef.GetTable(PostedInvtPutAwayLine);
                    Clear(ItemTrackingSetup);
                    ItemTrackingSetup.CopyTrackingFromPostedInvtPutAwayLine(PostedInvtPutAwayLine);
                    InsertBufferRec(RecRef, ItemTrackingSetup, "Item No.", "Variant Code");
                until Next() = 0;
        end;
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

        with RgstrdWhseActivLine do begin
            Reset();
            if ItemFilters.GetFilter("Lot No. Filter") <> '' then
                if SetCurrentKey("Lot No.") then;
            if ItemFilters.GetFilter("Package No. Filter") <> '' then
                if SetCurrentKey("Package No.") then;
            if ItemFilters.GetFilter("Serial No. Filter") <> '' then
                if SetCurrentKey("Serial No.") then;
            SetFilter("Lot No.", ItemFilters.GetFilter("Lot No. Filter"));
            SetFilter("Serial No.", ItemFilters.GetFilter("Serial No. Filter"));
            SetFilter("Package No.", ItemFilters.GetFilter("Package No. Filter"));
            SetFilter("Item No.", ItemFilters.GetFilter("No."));
            SetFilter("Variant Code", ItemFilters.GetFilter("Variant Filter"));
            if FindSet() then
                repeat
                    RecRef.GetTable(RgstrdWhseActivLine);
                    Clear(ItemTrackingSetup);
                    ItemTrackingSetup.CopyTrackingFromRegisteredWhseActivityLine(RgstrdWhseActivLine);
                    InsertBufferRec(RecRef, ItemTrackingSetup, "Item No.", "Variant Code");
                until Next() = 0;
        end;
    end;

    local procedure FindItemLedgerEntry(var ItemFilters: Record Item)
    var
        IsHandled: Boolean;
    begin
        if not ItemLedgEntry.ReadPermission then
            exit;

        with ItemLedgEntry do begin
            Reset();
            if ItemFilters.GetFilter("Lot No. Filter") <> '' then
                if SetCurrentKey("Lot No.") then;
            if ItemFilters.GetFilter("Package No. Filter") <> '' then
                if SetCurrentKey("Package No.") then;
            if ItemFilters.GetFilter("Serial No. Filter") <> '' then
                if SetCurrentKey("Serial No.") then;
            SetFilter("Lot No.", ItemFilters.GetFilter("Lot No. Filter"));
            SetFilter("Serial No.", ItemFilters.GetFilter("Serial No. Filter"));
            SetFilter("Package No.", ItemFilters.GetFilter("Package No. Filter"));
            SetFilter("Item No.", ItemFilters.GetFilter("No."));
            SetFilter("Variant Code", ItemFilters.GetFilter("Variant Filter"));
            if FindSet() then
                repeat
                    RecRef.GetTable(ItemLedgEntry);
                    Clear(ItemTrackingSetup);
                    ItemTrackingSetup.CopyTrackingFromItemLedgerEntry(ItemLedgEntry);
                    InsertBufferRec(RecRef, ItemTrackingSetup, "Item No.", "Variant Code");
                    IsHandled := false;
                    OnFindItemLedgerEntryOnBeforeCaseDocumentType(ItemLedgEntry, RecRef, IsHandled);
                    if not IsHandled then
                        case "Document Type" of
                            "Document Type"::"Sales Shipment":
                                FindSalesShptHeader("Document No.");
                            "Document Type"::"Sales Invoice":
                                FindSalesInvoice("Document No.");
                            "Document Type"::"Service Shipment":
                                FindServShptHeader("Document No.");
                            "Document Type"::"Service Invoice":
                                FindServInvoice("Document No.");
                            "Document Type"::"Service Credit Memo":
                                FindServCrMemo("Document No.");
                            "Document Type"::"Sales Return Receipt":
                                FindReturnRcptHeader("Document No.");
                            "Document Type"::"Sales Credit Memo":
                                FindSalesCrMemo("Document No.");
                            "Document Type"::"Purchase Receipt":
                                FindPurchRcptHeader("Document No.");
                            "Document Type"::"Purchase Invoice":
                                FindPurchInvoice("Document No.");
                            "Document Type"::"Purchase Return Shipment":
                                FindReturnShptHeader("Document No.");
                            "Document Type"::"Purchase Credit Memo":
                                FindPurchCrMemo("Document No.");
                            "Document Type"::"Transfer Shipment":
                                FindTransShptHeader("Document No.");
                            "Document Type"::"Transfer Receipt":
                                FindTransRcptHeader("Document No.");
                            "Document Type"::"Posted Assembly":
                                FindPostedAssembly("Document No.");
                            else
                                if "Entry Type" in ["Entry Type"::Consumption, "Entry Type"::Output] then
                                    FindProductionOrder("Document No.");
                        end;
                    OnFindTrackingRecordsForItemLedgerEntry(ItemLedgEntry);
                until Next() = 0;
        end;
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

        with JobLedgEntry do begin
            Reset();
            if ItemFilters.GetFilter("Lot No. Filter") <> '' then
                if SetCurrentKey("Lot No.") then;
            if ItemFilters.GetFilter("Package No. Filter") <> '' then
                if SetCurrentKey("Package No.") then;
            if ItemFilters.GetFilter("Serial No. Filter") <> '' then
                if SetCurrentKey("Serial No.") then;
            SetFilter("Lot No.", ItemFilters.GetFilter("Lot No. Filter"));
            SetFilter("Serial No.", ItemFilters.GetFilter("Serial No. Filter"));
            SetFilter("Package No.", ItemFilters.GetFilter("Package No. Filter"));
            SetFilter("Variant Code", ItemFilters.GetFilter("Variant Filter"));
            if FindSet() then
                repeat
                    RecRef.GetTable(JobLedgEntry);
                    Clear(ItemTrackingSetup);
                    ItemTrackingSetup.CopyTrackingFromJobLedgerEntry(JobLedgEntry);
                    InsertBufferRec(RecRef, ItemTrackingSetup, '', "Variant Code");
                    TempJobLedgEntry := JobLedgEntry;
                    if TempJobLedgEntry.Insert() then;
                until Next() = 0;
        end;
    end;

    local procedure FindReservEntry(var ItemFilters: Record Item)
    var
        IsHandled: Boolean;
    begin
        if not ReservEntry.ReadPermission then
            exit;

        with ReservEntry do begin
            Reset();
            if ItemFilters.GetFilter("Lot No. Filter") <> '' then
                if SetCurrentKey("Lot No.") then;
            if ItemFilters.GetFilter("Package No. Filter") <> '' then
                if SetCurrentKey("Package No.") then;
            if ItemFilters.GetFilter("Serial No. Filter") <> '' then
                if SetCurrentKey("Serial No.") then;
            SetFilter("Lot No.", ItemFilters.GetFilter("Lot No. Filter"));
            SetFilter("Serial No.", ItemFilters.GetFilter("Serial No. Filter"));
            SetFilter("Package No.", ItemFilters.GetFilter("Package No. Filter"));
            SetFilter("Item No.", ItemFilters.GetFilter("No."));
            SetFilter("Variant Code", ItemFilters.GetFilter("Variant Filter"));
            if FindSet() then
                repeat
                    RecRef.GetTable(ReservEntry);
                    Clear(ItemTrackingSetup);
                    ItemTrackingSetup.CopyTrackingFromReservEntry(ReservEntry);
                    InsertBufferRec(RecRef, ItemTrackingSetup, "Item No.", "Variant Code");
                    IsHandled := false;
                    OnFindReservEntryOnBeforeCaseDocumentType(ReservEntry, RecRef, IsHandled);
                    if not IsHandled then
                        case "Source Type" of
                            DATABASE::"Sales Line":
                                FindSalesLines();
                            DATABASE::"Service Line":
                                FindServiceLines();
                            DATABASE::"Purchase Line":
                                FindPurchaseLines();
                            DATABASE::"Requisition Line":
                                FindRequisitionLines();
                            DATABASE::"Planning Component":
                                FindPlanningComponent();
                            DATABASE::"Item Journal Line":
                                FindItemJournalLines();
                            DATABASE::"Assembly Line":
                                FindAssemblyLines();
                            DATABASE::"Assembly Header":
                                FindAssemblyHeaders();
                            DATABASE::"Prod. Order Line":
                                FindProdOrderLines();
                            DATABASE::"Prod. Order Component":
                                FindProdOrderComponents();
                            DATABASE::"Transfer Line":
                                FindTransferLines();
                        end;
                until Next() = 0;
        end;
    end;

    local procedure FindWhseActivLine(var ItemFilters: Record Item)
    begin
        if not WhseActivLine.ReadPermission then
            exit;

        with WhseActivLine do begin
            Reset();
            if ItemFilters.GetFilter("Lot No. Filter") <> '' then
                if SetCurrentKey("Lot No.") then;
            if ItemFilters.GetFilter("Package No. Filter") <> '' then
                if SetCurrentKey("Package No.") then;
            if ItemFilters.GetFilter("Serial No. Filter") <> '' then
                if SetCurrentKey("Serial No.") then;
            SetFilter("Lot No.", ItemFilters.GetFilter("Lot No. Filter"));
            SetFilter("Serial No.", ItemFilters.GetFilter("Serial No. Filter"));
            SetFilter("Package No.", ItemFilters.GetFilter("Package No. Filter"));
            SetFilter("Item No.", ItemFilters.GetFilter("No."));
            SetFilter("Variant Code", ItemFilters.GetFilter("Variant Filter"));
            if FindSet() then
                repeat
                    RecRef.GetTable(WhseActivLine);
                    Clear(ItemTrackingSetup);
                    ItemTrackingSetup.CopyTrackingFromWhseActivityLine(WhseActivLine);
                    InsertBufferRec(RecRef, ItemTrackingSetup, "Item No.", "Variant Code");
                until Next() = 0;
        end;
    end;

    local procedure FindWhseEntry(var ItemFilters: Record Item)
    begin
        if not WhseEntry.ReadPermission then
            exit;

        with WhseEntry do begin
            Reset();
            if ItemFilters.GetFilter("Lot No. Filter") <> '' then
                if SetCurrentKey("Lot No.") then;
            if ItemFilters.GetFilter("Package No. Filter") <> '' then
                if SetCurrentKey("Package No.") then;
            if ItemFilters.GetFilter("Serial No. Filter") <> '' then
                if SetCurrentKey("Serial No.") then;
            SetFilter("Lot No.", ItemFilters.GetFilter("Lot No. Filter"));
            SetFilter("Serial No.", ItemFilters.GetFilter("Serial No. Filter"));
            SetFilter("Package No.", ItemFilters.GetFilter("Package No. Filter"));
            SetFilter("Item No.", ItemFilters.GetFilter("No."));
            SetFilter("Variant Code", ItemFilters.GetFilter("Variant Filter"));
            if FindSet() then
                repeat
                    RecRef.GetTable(WhseEntry);
                    Clear(ItemTrackingSetup);
                    ItemTrackingSetup.CopyTrackingFromWhseEntry(WhseEntry);
                    InsertBufferRec(RecRef, ItemTrackingSetup, "Item No.", "Variant Code");
                until Next() = 0;
        end;
    end;

    procedure Show(TableNo: Integer)
    begin
        case TableNo of
            DATABASE::"Item Ledger Entry":
                PAGE.Run(0, ItemLedgEntry);
            DATABASE::"Reservation Entry":
                PAGE.Run(0, ReservEntry);
            DATABASE::"Misc. Article Information":
                PAGE.Run(0, MiscArticleInfo);
            DATABASE::"Fixed Asset":
                PAGE.Run(0, FixedAsset);
            DATABASE::"Warehouse Activity Line":
                PAGE.Run(0, WhseActivLine);
            DATABASE::"Registered Whse. Activity Line":
                PAGE.Run(0, RgstrdWhseActivLine);
            DATABASE::"Service Item Line":
                PAGE.Run(0, ServItemLine);
            DATABASE::Loaner:
                PAGE.Run(0, Loaner);
            DATABASE::"Service Item":
                PAGE.Run(0, ServiceItem);
            DATABASE::"Service Item Component":
                PAGE.Run(0, ServiceItemComponent);
            DATABASE::"Service Contract Line":
                PAGE.Run(0, ServContractLine);
            DATABASE::"Filed Contract Line":
                PAGE.Run(0, FiledContractLine);
            DATABASE::"Serial No. Information":
                PAGE.Run(0, SerialNoInfo);
            DATABASE::"Lot No. Information":
                PAGE.Run(0, LotNoInfo);
            DATABASE::"Package No. Information":
                PAGE.Run(0, PackageNoInfo);
            DATABASE::"Warehouse Entry":
                PAGE.Run(0, WhseEntry);
            DATABASE::"Posted Whse. Shipment Line":
                PAGE.Run(0, TempPostedWhseShptLine);
            DATABASE::"Posted Whse. Receipt Line":
                PAGE.Run(0, TempPostedWhseRcptLine);
            DATABASE::"Posted Invt. Put-away Line":
                PAGE.Run(0, PostedInvtPutAwayLine);
            DATABASE::"Posted Invt. Pick Line":
                PAGE.Run(0, PostedInvtPickLine);
            DATABASE::"Purch. Rcpt. Header":
                PAGE.Run(0, TempPurchRcptHeader);
            DATABASE::"Purch. Inv. Header":
                PAGE.Run(0, TempPurchInvHeader);
            DATABASE::"Purch. Cr. Memo Hdr.":
                PAGE.Run(0, TempPurchCrMemoHeader);
            DATABASE::"Sales Shipment Header":
                PAGE.Run(0, TempSalesShptHeader);
            DATABASE::"Sales Invoice Header":
                PAGE.Run(0, TempSalesInvHeader);
            DATABASE::"Sales Cr.Memo Header":
                PAGE.Run(0, TempSalesCrMemoHeader);
            DATABASE::"Service Shipment Header":
                PAGE.Run(0, TempServShptHeader);
            DATABASE::"Service Invoice Header":
                PAGE.Run(0, TempServInvHeader);
            DATABASE::"Service Cr.Memo Header":
                PAGE.Run(0, TempServCrMemoHeader);
            DATABASE::"Transfer Shipment Header":
                PAGE.Run(0, TempTransShipHeader);
            DATABASE::"Return Shipment Header":
                PAGE.Run(0, TempReturnShipHeader);
            DATABASE::"Return Receipt Header":
                PAGE.Run(0, TempReturnRcptHeader);
            DATABASE::"Transfer Receipt Header":
                PAGE.Run(0, TempTransRcptHeader);
            DATABASE::"Production Order":
                PAGE.Run(0, TempProdOrder);
            DATABASE::"Sales Line":
                PAGE.Run(0, TempSalesLine);
            DATABASE::"Service Line":
                PAGE.Run(0, TempServLine);
            DATABASE::"Purchase Line":
                PAGE.Run(0, TempPurchLine);
            DATABASE::"Requisition Line":
                PAGE.Run(0, TempReqLine);
            DATABASE::"Item Journal Line":
                PAGE.Run(0, TempItemJnlLine);
            DATABASE::"Prod. Order Line":
                PAGE.Run(0, TempProdOrderLine);
            DATABASE::"Prod. Order Component":
                PAGE.Run(0, TempProdOrderComp);
            DATABASE::"Planning Component":
                PAGE.Run(0, TempPlanningComponent);
            DATABASE::"Transfer Line":
                PAGE.Run(0, TempTransLine);
            DATABASE::"Job Ledger Entry":
                PAGE.Run(0, TempJobLedgEntry);
            DATABASE::"Assembly Line":
                PAGE.Run(0, TempAssemblyLine);
            DATABASE::"Assembly Header":
                PAGE.Run(0, TempAssemblyHeader);
            DATABASE::"Posted Assembly Line":
                PAGE.Run(0, TempPostedAssemblyLine);
            DATABASE::"Posted Assembly Header":
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
            OptionNo := FldRef.Value;
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

