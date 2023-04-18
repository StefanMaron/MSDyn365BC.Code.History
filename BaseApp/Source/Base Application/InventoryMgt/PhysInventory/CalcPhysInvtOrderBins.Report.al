report 5885 "Calc. Phys. Invt. Order (Bins)"
{
    Caption = 'Calc. Phys. Invt. Order (Bins)';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Bin; Bin)
        {
            DataItemTableView = SORTING("Location Code", Code);
            RequestFilterFields = "Location Code", "Code";

            trigger OnAfterGetRecord()
            var
                Item: Record Item;
                PhysInvtOrderLineArgs: Record "Phys. Invt. Order Line";
                IsHandled: Boolean;
            begin
                Location.Get("Location Code");
                Location.TestField("Bin Mandatory");

                OnAfterGetRecordBinOnAfterCheckLocation(PhysInvtOrderHeader, Bin);

                if not HideValidationDialog then begin
                    Window.Update(1, "Location Code");
                    Window.Update(2, Code);
                end;

                Clear(LastWhseEntry);

                WhseEntry.Reset();
                WhseEntry.SetCurrentKey("Location Code", "Bin Code", "Item No.", "Variant Code");
                WhseEntry.SetRange("Location Code", "Location Code");
                WhseEntry.SetRange("Bin Code", Code);
                if WhseEntry.Find('-') then
                    repeat
                        if Item.Get(WhseEntry."Item No.") then 
                            if not Item.Blocked then begin
                                if IsNewWhseEntryGroup() then begin
                                    LastWhseEntry := WhseEntry;
                                    IsHandled := false;
                                    OnBeforeCreateNewPhysInvtOrderLineForWhseEntry(
                                      Item, WhseEntry, PhysInvtOrderHeader, PhysInvtOrderLine, ErrorText, NextLineNo,
                                      CalcQtyExpected, LastItemLedgEntryNo, LineCount, IsHandled);
                                    if not IsHandled then begin
                                        PhysInvtOrderLineArgs.PrepareLineArgs(WhseEntry);
                                        if PhysInvtOrderHeader.GetSamePhysInvtOrderLine(
                                             PhysInvtOrderLineArgs,
                                             ErrorText,
                                             PhysInvtOrderLine) = 0
                                        then
                                            CreateNewPhysInvtOrderLine();
                                    end;
                                end;
                            end else
                                ItemsBlocked := true;
                    until WhseEntry.Next() = 0;
            end;

            trigger OnPostDataItem()
            begin
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

                PhysInvtOrderHeader.LockTable();
                PhysInvtOrderLine.LockTable();

                PhysInvtOrderLine.Reset();
                PhysInvtOrderLine.SetRange("Document No.", PhysInvtOrderHeader."No.");
                if PhysInvtOrderLine.FindLast() then
                    NextLineNo := PhysInvtOrderLine."Line No." + 10000
                else
                    NextLineNo := 10000;

                if not HideValidationDialog then
                    Window.Open(CalculatingLinesMsg + LocationAndBinMsg);

                LineCount := 0;
                ItemsBlocked := false;
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
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        Location: Record Location;
        WhseEntry: Record "Warehouse Entry";
        LastWhseEntry: Record "Warehouse Entry";
        Window: Dialog;
        ErrorText: Text[250];
        QtyExp: Decimal;
        LastItemLedgEntryNo: Integer;
        NextLineNo: Integer;
        LineCount: Integer;
        ZeroQty: Boolean;
        CalcQtyExpected: Boolean;
        ItemsBlocked: Boolean;

        CalculatingLinesMsg: Label 'Calculating the order lines...\\';
        LocationAndBinMsg: Label 'Location #1########   Bin #2############', Comment = '%1,%2 = counters';
        LinesCreatedMsg: Label '%1 new lines have been created.', Comment = '%1 = counter';
        BlockedItemMsg: Label 'There is at least one blocked item that was skipped.';

    protected var
        HideValidationDialog: Boolean;

    procedure SetPhysInvtOrderHeader(NewPhysInvtOrderHeader: Record "Phys. Invt. Order Header")
    begin
        PhysInvtOrderHeader := NewPhysInvtOrderHeader;

        OnAfterSetPhysInvtOrderHeader(PhysInvtOrderHeader, Location, Bin);
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    procedure CreateNewPhysInvtOrderLine()
    var
        PhysInvtOrderLineArgs: Record "Phys. Invt. Order Line";
        InsertLine: Boolean;
    begin
        PhysInvtOrderLineArgs.PrepareLineArgs(WhseEntry);
        PhysInvtOrderLine.PrepareLine(
            PhysInvtOrderHeader."No.", NextLineNo, PhysInvtOrderLineArgs, '', 0);
        PhysInvtOrderLine.CalcQtyAndLastItemLedgExpected(QtyExp, LastItemLedgEntryNo);
        InsertLine := false;
        OnCreateNewPhysInvtOrderLineOnAfterCalcQtyAndLastItemLedgExpected(QtyExp, LastItemLedgEntryNo, WhseEntry, PhysInvtOrderLine, InsertLine);
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

    local procedure IsNewWhseEntryGroup() Result: Boolean
    begin
        Result :=
            (LastWhseEntry."Location Code" <> WhseEntry."Location Code") or
            (LastWhseEntry."Bin Code" <> WhseEntry."Bin Code") or
            (LastWhseEntry."Item No." <> WhseEntry."Item No.") or
            (LastWhseEntry."Variant Code" <> WhseEntry."Variant Code");
        OnAfterIsNewWhseEntryGroup(WhseEntry, LastWhseEntry, Result);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateNewPhysInvtOrderLineForWhseEntry(Item: Record Item; WarehouseEntry: Record "Warehouse Entry"; PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; var ErrorText: Text; var NextLineNo: Integer; CalcQtyExpected: Boolean; var LastItemLedgEntryNo: Integer; var LineCount: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePhysInvtOrderLineModify(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; CalcQtyExpected: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCreateNewPhysInvtOrderLineOnAfterCalcQtyAndLastItemLedgExpected(QtyExpected: Decimal; LastItemLedgEntryNo: Integer; WarehouseEntry: Record "Warehouse Entry"; PhysInvtOrderLine: Record "Phys. Invt. Order Line"; var InsertLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordBinOnAfterCheckLocation(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; var Bin: Record Bin)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetPhysInvtOrderHeader(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; var Location: Record Location; var Bin: Record Bin)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsNewWhseEntryGroup(WhseEntry: Record "Warehouse Entry"; LastWhseEntry: Record "Warehouse Entry"; var Result: Boolean)
    begin
    end;
}
