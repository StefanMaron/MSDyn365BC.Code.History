report 5880 "Calc. Phys. Invt. Order Lines"
{
    Caption = 'Calc. Phys. Invt. Order Lines';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Item; Item)
        {
            RequestFilterFields = "No.", "Inventory Posting Group", "Gen. Prod. Posting Group", "Variant Filter", "Location Filter", "Bin Filter", "Date Filter";

            trigger OnAfterGetRecord()
            begin
                if not HideValidationDialog then
                    Window.Update(1, "No.");

                Clear(LastItemLedgEntry);

                if not Blocked then
                    CalcItemPhysInvtOrderLines()
                else
                    ItemsBlocked := true;
            end;

            trigger OnPostDataItem()
            begin
                OnAfterCreatePhysInvtOrderLines(PhysInvtOrderHeader, Item, ItemsBlocked, LineCount, NextLineNo);
                if not HideValidationDialog then begin
                    Window.Close();
                    if ItemsBlocked then
                        Message(BlockedItemMsg);
                    Message(
                      StrSubstNo(LinesCreatedMsg, LineCount));
                end;
            end;

            trigger OnPreDataItem()
            begin
                PhysInvtOrderHeader.TestField("No.");
                PhysInvtOrderHeader.TestField(Status, PhysInvtOrderHeader.Status::Open);

                OnBeforeOnPreDataItemItem(PhysInvtOrderHeader, Item);

                PhysInvtOrderHeader.LockTable();
                PhysInvtOrderLine.LockTable();

                PhysInvtOrderLine.Reset();
                PhysInvtOrderLine.SetRange("Document No.", PhysInvtOrderHeader."No.");
                if PhysInvtOrderLine.FindLast() then
                    NextLineNo := PhysInvtOrderLine."Line No." + 10000
                else
                    NextLineNo := 10000;

                if not HideValidationDialog then
                    Window.Open(CalculatingLinesMsg + ItemNoMsg);

                LineCount := 0;
                ItemsBlocked := false;

                if PhysInvtOrderHeader."Location Code" <> '' then
                    SetRange("Location Filter", PhysInvtOrderHeader."Location Code");
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(CalcQtyExpected; CalcQtyExpected)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Calculate Qty. Expected';
                        ToolTip = 'Specifies if you want the program to calculate and insert the contents of the field quantity expected for new created physical inventory order lines.';
                    }
                    field(ZeroQty; ZeroQty)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Items Not on Inventory';
                        ToolTip = 'Specifies if journal lines should be created for items that are not on inventory, that is, items where the value in the Qty. (Calculated) field is 0.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            OnAfterOpenPage(PhysInvtOrderHeader, Item);
        end;
    }

    labels
    {
    }

    var
        CalculatingLinesMsg: Label 'Calculating the order lines...\\';
        ItemNoMsg: Label 'Item No.  #1##################', Comment = '%1 = Item No.';
        LinesCreatedMsg: Label '%1 new lines have been created.', Comment = '%1 = counter';
        BlockedItemMsg: Label 'There is at least one blocked item that was skipped.';

    protected var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        ItemLedgEntry: Record "Item Ledger Entry";
        LastItemLedgEntry: Record "Item Ledger Entry";
        WhseEntry: Record "Warehouse Entry";
        LastWhseEntry: Record "Warehouse Entry";
        PhysInvtTrackingMgt: Codeunit "Phys. Invt. Tracking Mgt.";
        Window: Dialog;
        ErrorText: Text[250];
        CycleSourceType: Option " ",Item,SKU;
        InvtCountCode: Code[10];
        QtyExp: Decimal;
        LastItemLedgEntryNo: Integer;
        NextLineNo: Integer;
        LineCount: Integer;
        ItemsBlocked: Boolean;
        CalcQtyExpected: Boolean;
        HideValidationDialog: Boolean;
        ZeroQty: Boolean;

    procedure SetPhysInvtOrderHeader(NewPhysInvtOrderHeader: Record "Phys. Invt. Order Header")
    begin
        PhysInvtOrderHeader := NewPhysInvtOrderHeader;

        OnAfterSetPhysInvtOrderHeader(PhysInvtOrderHeader, Item);
    end;

    procedure InitializeRequest(ZeroQty2: Boolean; CalcQtyExpected2: Boolean)
    begin
        ZeroQty := ZeroQty2;
        CalcQtyExpected := CalcQtyExpected2;
    end;

    procedure InitializeInvtCount(InvtCountCode2: Code[10]; CycleSourceType2: Option " ",Item,SKU)
    begin
        InvtCountCode := InvtCountCode2;
        CycleSourceType := CycleSourceType2;
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    local procedure CalcItemPhysInvtOrderLines()
    var
        Bin: Record Bin;
        BlankWhseEntry: Record "Warehouse Entry";
        PhysInvtOrderLineArgs: Record "Phys. Invt. Order Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcItemPhysInvtOrderLines(Item, IsHandled);
        if IsHandled then
            exit;

        SetItemLedgEntryFilters();
        if ItemLedgEntry.Find('-') then
            repeat
                if IsNewItemLedgEntryGroup() then begin
                    LastItemLedgEntry := ItemLedgEntry;

                    if PhysInvtTrackingMgt.LocationIsBinMandatory(ItemLedgEntry."Location Code") then begin
                        Clear(LastWhseEntry);
                        SetWhseEntryFilters();
                        if WhseEntry.Find('-') then
                            repeat
                                if IsNewWhseEntryGroup() then begin
                                    LastWhseEntry := WhseEntry;
                                    Bin.SetRange("Location Code", WhseEntry."Location Code");
                                    Bin.SetRange(Code, WhseEntry."Bin Code");
                                    IsHandled := false;
                                    OnBeforeCreateNewPhysInvtOrderLineForWhseEntry(
                                      Item, WhseEntry, ItemLedgEntry, PhysInvtOrderHeader, PhysInvtOrderLine, ErrorText,
                                      NextLineNo, InvtCountCode, CycleSourceType, CalcQtyExpected, LastItemLedgEntryNo, LineCount, IsHandled);
                                    if not IsHandled then begin
                                        PhysInvtOrderLineArgs.PrepareLineArgs(WhseEntry, ItemLedgEntry);
                                        if (not Bin.IsEmpty) and
                                           (PhysInvtOrderHeader.GetSamePhysInvtOrderLine(
                                              PhysInvtOrderLineArgs,
                                              ErrorText,
                                              PhysInvtOrderLine) = 0)
                                        then
                                            CreateNewPhysInvtOrderLine();
                                    end;
                                end;
                            until WhseEntry.Next() = 0;
                    end else begin
                        PhysInvtOrderLineArgs.PrepareLineArgs(BlankWhseEntry, ItemLedgEntry);
                        if PhysInvtOrderHeader.GetSamePhysInvtOrderLine(
                             PhysInvtOrderLineArgs,
                             ErrorText,
                             PhysInvtOrderLine) = 0
                        then begin
                            WhseEntry.Init();
                            CreateNewPhysInvtOrderLine();
                        end;
                    end;
                end;
            until ItemLedgEntry.Next() = 0;
    end;

    local procedure SetItemLedgEntryFilters()
    begin
        ItemLedgEntry.Reset();
        ItemLedgEntry.SetCurrentKey(
          "Item No.", "Entry Type", "Variant Code", "Drop Shipment", "Location Code", "Posting Date");
        ItemLedgEntry.SetRange("Item No.", Item."No.");
        if Item.GetFilter("Variant Filter") <> '' then
            Item.CopyFilter("Variant Filter", ItemLedgEntry."Variant Code");
        if Item.GetFilter("Location Filter") <> '' then
            Item.CopyFilter("Location Filter", ItemLedgEntry."Location Code");
        if Item.GetFilter("Date Filter") <> '' then
            Item.CopyFilter("Date Filter", ItemLedgEntry."Posting Date");
        OnAfterSetItemLedgEntryFilters(ItemLedgEntry, Item);
    end;

    local procedure IsNewItemLedgEntryGroup() Result: Boolean
    begin
        Result :=
            (LastItemLedgEntry."Item No." <> ItemLedgEntry."Item No.") or
            (LastItemLedgEntry."Variant Code" <> ItemLedgEntry."Variant Code") or
            (LastItemLedgEntry."Location Code" <> ItemLedgEntry."Location Code");
        OnAfterIsNewItemLedgEntryGroup(ItemLedgEntry, LastItemLedgEntry, Result, Item);
    end;

    local procedure SetWhseEntryFilters()
    begin
        WhseEntry.Reset();
        WhseEntry.SetCurrentKey("Item No.", "Variant Code", "Location Code", "Bin Code");
        WhseEntry.SetRange("Item No.", ItemLedgEntry."Item No.");
        WhseEntry.SetRange("Variant Code", ItemLedgEntry."Variant Code");
        WhseEntry.SetRange("Location Code", ItemLedgEntry."Location Code");
        if Item.GetFilter("Bin Filter") <> '' then
            Item.CopyFilter("Bin Filter", WhseEntry."Bin Code");
        OnAfterSetWhseEntryFilters(WhseEntry, ItemLedgEntry, Item);
    end;

    local procedure IsNewWhseEntryGroup() Result: Boolean
    begin
        Result := LastWhseEntry."Bin Code" <> WhseEntry."Bin Code";
        OnAfterIsNewWhseEntryGroup(WhseEntry, LastWhseEntry, Result);
    end;

    procedure CreateNewPhysInvtOrderLine()
    var
        PhysInvtOrderLineArgs: Record "Phys. Invt. Order Line";
        InsertLine: Boolean;
    begin
        PhysInvtOrderLineArgs.PrepareLineArgs(WhseEntry, ItemLedgEntry);
        PhysInvtOrderLine.PrepareLine(
            PhysInvtOrderHeader."No.", NextLineNo, PhysInvtOrderLineArgs, InvtCountCode, CycleSourceType);
        PhysInvtOrderLine.CalcQtyAndLastItemLedgExpected(QtyExp, LastItemLedgEntryNo);
        InsertLine := false;
        OnCreateNewPhysInvtOrderLineOnAfterCalcQtyAndLastItemLedgExpected(QtyExp, LastItemLedgEntryNo, ItemLedgEntry, PhysInvtOrderLine, InsertLine, WhseEntry);
        if (QtyExp <> 0) or ZeroQty or InsertLine then begin
            PhysInvtOrderLine.Insert(true);
            PhysInvtOrderLine.CreateDimFromDefaultDim();
            if CalcQtyExpected then
                PhysInvtOrderLine.CalcQtyAndTrackLinesExpected();
            OnBeforePhysInvtOrderLineModify(PhysInvtOrderLine, CalcQtyExpected);
            PhysInvtOrderLine.Modify();
            NextLineNo := NextLineNo + 10000;
            LineCount := LineCount + 1;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateNewPhysInvtOrderLineForWhseEntry(Item: Record Item; WarehouseEntry: Record "Warehouse Entry"; ItemLedgerEntry: Record "Item Ledger Entry"; PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; var ErrorText: Text[250]; var NextLineNo: Integer; InvtCountCode: Code[10]; CycleSourceType: Option " ",Item,SKU; CalcQtyExpected: Boolean; var LastItemLedgEntryNo: Integer; var LineCount: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcItemPhysInvtOrderLines(var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePhysInvtOrderLineModify(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; CalcQtyExpected: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCreateNewPhysInvtOrderLineOnAfterCalcQtyAndLastItemLedgExpected(QtyExpected: Decimal; LastItemLedgEntryNo: Integer; ItemLedgerEntry: Record "Item Ledger Entry"; PhysInvtOrderLine: Record "Phys. Invt. Order Line"; var InsertLine: Boolean; WarehouseEntry: Record "Warehouse Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetPhysInvtOrderHeader(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnPreDataItemItem(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOpenPage(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetItemLedgEntryFilters(var ItemLedgEntry: Record "Item Ledger Entry"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterIsNewItemLedgEntryGroup(ItemLedgEntry: Record "Item Ledger Entry"; LastItemLedgEntry: Record "Item Ledger Entry"; var Result: Boolean; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsNewWhseEntryGroup(WhseEntry: Record "Warehouse Entry"; LastWhseEntry: Record "Warehouse Entry"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetWhseEntryFilters(var WhseEntry: Record "Warehouse Entry"; ItemLedgEntry: Record "Item Ledger Entry"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreatePhysInvtOrderLines(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; var Item: Record Item; var ItemBlocked: Boolean; var LineCount: Integer; var NextLineNo: Integer)
    begin
    end;
}

