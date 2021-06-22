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
            var
                Bin: Record Bin;
                IsHandled: Boolean;
            begin
                if not HideValidationDialog then
                    Window.Update(1, "No.");

                LastItemNo := '';
                LastVariantCode := '';
                LastLocationCode := '';

                if not Blocked then begin
                    ItemLedgEntry.Reset();
                    ItemLedgEntry.SetCurrentKey(
                      "Item No.", "Entry Type", "Variant Code", "Drop Shipment", "Location Code", "Posting Date");
                    ItemLedgEntry.SetRange("Item No.", "No.");
                    if GetFilter("Variant Filter") <> '' then
                        CopyFilter("Variant Filter", ItemLedgEntry."Variant Code");
                    if GetFilter("Location Filter") <> '' then
                        CopyFilter("Location Filter", ItemLedgEntry."Location Code");
                    if GetFilter("Date Filter") <> '' then
                        CopyFilter("Date Filter", ItemLedgEntry."Posting Date");
                    if ItemLedgEntry.Find('-') then
                        repeat
                            if (LastItemNo <> ItemLedgEntry."Item No.") or
                               (LastVariantCode <> ItemLedgEntry."Variant Code") or
                               (LastLocationCode <> ItemLedgEntry."Location Code")
                            then begin
                                LastItemNo := ItemLedgEntry."Item No.";
                                LastVariantCode := ItemLedgEntry."Variant Code";
                                LastLocationCode := ItemLedgEntry."Location Code";

                                if PhysInvtTrackingMgt.LocationIsBinMandatory(ItemLedgEntry."Location Code") then begin
                                    LastBinCode := '';
                                    WhseEntry.Reset();
                                    WhseEntry.SetCurrentKey("Item No.", "Variant Code", "Location Code", "Bin Code");
                                    WhseEntry.SetRange("Item No.", ItemLedgEntry."Item No.");
                                    WhseEntry.SetRange("Variant Code", ItemLedgEntry."Variant Code");
                                    WhseEntry.SetRange("Location Code", ItemLedgEntry."Location Code");
                                    if GetFilter("Bin Filter") <> '' then
                                        CopyFilter("Bin Filter", WhseEntry."Bin Code");
                                    if WhseEntry.Find('-') then
                                        repeat
                                            if LastBinCode <> WhseEntry."Bin Code" then begin
                                                LastBinCode := WhseEntry."Bin Code";
                                                Bin.SetRange("Location Code", WhseEntry."Location Code");
                                                Bin.SetRange(Code, WhseEntry."Bin Code");
                                                IsHandled := false;
                                                OnBeforeCreateNewPhysInvtOrderLineForWhseEntry(
                                                  Item, WhseEntry, ItemLedgEntry, PhysInvtOrderHeader, PhysInvtOrderLine, ErrorText,
                                                  NextLineNo, InvtCountCode, CycleSourceType, CalcQtyExpected, LastItemLedgEntryNo, LineCount, IsHandled);
                                                if not IsHandled then
                                                    if (not Bin.IsEmpty) and
                                                       (PhysInvtOrderHeader.GetSamePhysInvtOrderLine(
                                                          ItemLedgEntry."Item No.", ItemLedgEntry."Variant Code",
                                                          ItemLedgEntry."Location Code",
                                                          WhseEntry."Bin Code",
                                                          ErrorText,
                                                          PhysInvtOrderLine) = 0)
                                                    then
                                                        CreateNewPhysInvtOrderLine;
                                            end;
                                        until WhseEntry.Next = 0;
                                end else
                                    if PhysInvtOrderHeader.GetSamePhysInvtOrderLine(
                                         ItemLedgEntry."Item No.", ItemLedgEntry."Variant Code",
                                         ItemLedgEntry."Location Code",
                                         '',// without BIN Code
                                         ErrorText,
                                         PhysInvtOrderLine) = 0
                                    then begin
                                        WhseEntry.Init();
                                        CreateNewPhysInvtOrderLine;
                                    end;
                            end;
                        until ItemLedgEntry.Next = 0;
                end else
                    ItemsBlocked := true;
            end;

            trigger OnPostDataItem()
            begin
                if not HideValidationDialog then begin
                    Window.Close;
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

                PhysInvtOrderHeader.LockTable();
                PhysInvtOrderLine.LockTable();

                PhysInvtOrderLine.Reset();
                PhysInvtOrderLine.SetRange("Document No.", PhysInvtOrderHeader."No.");
                if PhysInvtOrderLine.FindLast then
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
    }

    labels
    {
    }

    var
        CalculatingLinesMsg: Label 'Calculating the order lines...\\';
        ItemNoMsg: Label 'Item No.  #1##################', Comment = '%1 = Item No.';
        LinesCreatedMsg: Label '%1 new lines have been created.', Comment = '%1 = counter';
        BlockedItemMsg: Label 'There is at least one blocked item that was skipped.';
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        ItemLedgEntry: Record "Item Ledger Entry";
        WhseEntry: Record "Warehouse Entry";
        PhysInvtTrackingMgt: Codeunit "Phys. Invt. Tracking Mgt.";
        Window: Dialog;
        ErrorText: Text[250];
        CycleSourceType: Option " ",Item,SKU;
        InvtCountCode: Code[10];
        LastItemNo: Code[20];
        LastVariantCode: Code[10];
        LastLocationCode: Code[10];
        LastBinCode: Code[20];
        QtyExp: Decimal;
        LastItemLedgEntryNo: Integer;
        NextLineNo: Integer;
        LineCount: Integer;
        HideValidationDialog: Boolean;
        ZeroQty: Boolean;
        CalcQtyExpected: Boolean;
        ItemsBlocked: Boolean;

    procedure SetPhysInvtOrderHeader(NewPhysInvtOrderHeader: Record "Phys. Invt. Order Header")
    begin
        PhysInvtOrderHeader := NewPhysInvtOrderHeader;
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

    procedure CreateNewPhysInvtOrderLine()
    begin
        PhysInvtOrderLine.PrepareLine(
          PhysInvtOrderHeader."No.", NextLineNo,
          ItemLedgEntry."Item No.", ItemLedgEntry."Variant Code", ItemLedgEntry."Location Code", WhseEntry."Bin Code",
          InvtCountCode, CycleSourceType);
        PhysInvtOrderLine.CalcQtyAndLastItemLedgExpected(QtyExp, LastItemLedgEntryNo);
        if (QtyExp <> 0) or ZeroQty then begin
            PhysInvtOrderLine.Insert(true);
            PhysInvtOrderLine.CreateDim(DATABASE::Item, PhysInvtOrderLine."Item No.");
            if CalcQtyExpected then
                PhysInvtOrderLine.CalcQtyAndTrackLinesExpected;
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
    local procedure OnBeforePhysInvtOrderLineModify(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; CalcQtyExpected: Boolean)
    begin
    end;
}

