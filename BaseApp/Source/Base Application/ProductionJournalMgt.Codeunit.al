codeunit 5510 "Production Journal Mgt"
{

    trigger OnRun()
    begin
    end;

    var
        MfgSetup: Record "Manufacturing Setup";
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlBatch: Record "Item Journal Batch";
        UOMMgt: Codeunit "Unit of Measure Management";
        PostingDate: Date;
        CalcBasedOn: Option "Actual Output","Expected Output";
        PresetOutputQuantity: Option "Expected Quantity","Zero on All Operations","Zero on Last Operation";
        ToTemplateName: Code[10];
        ToBatchName: Code[10];
        NextLineNo: Integer;
        Text000: Label '%1 journal';
        Text001: Label 'Do you want to leave the Production Journal?';
        Text002: Label 'Item %1 is blocked and therefore, no journal line is created for this item.';
        Text003: Label 'DEFAULT';
        Text004: Label 'Production Journal';
        Text005: Label '%1 %2 for operation %3 is blocked and therefore, no journal line is created for this operation.';

    procedure Handling(ProdOrder: Record "Production Order"; ActualLineNo: Integer)
    var
        ProductionJnl: Page "Production Journal";
        LeaveForm: Boolean;
        IsHandled: Boolean;
    begin
        MfgSetup.Get();

        SetTemplateAndBatchName;

        InitSetupValues;

        DeleteJnlLines(ToTemplateName, ToBatchName, ProdOrder."No.", ActualLineNo);

        CreateJnlLines(ProdOrder, ActualLineNo);

        IsHandled := false;
        OnBeforeRunProductionJnl(ToTemplateName, ToBatchName, ProdOrder, ActualLineNo, PostingDate, IsHandled);
        if not IsHandled then begin
            repeat
                LeaveForm := true;
                Clear(ProductionJnl);
                ProductionJnl.Setup(ToTemplateName, ToBatchName, ProdOrder, ActualLineNo, PostingDate);
                ProductionJnl.RunModal;
                if DataHasChanged(ToTemplateName, ToBatchName, ProdOrder."No.", ActualLineNo) then
                    LeaveForm := Confirm(Text001, true);
            until LeaveForm;

            DeleteJnlLines(ToTemplateName, ToBatchName, ProdOrder."No.", ActualLineNo);
        end;
    end;

    procedure CreateJnlLines(ProdOrder: Record "Production Order"; ProdOrderLineNo: Integer)
    var
        ItemJnlLine: Record "Item Journal Line";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        ProdOrderComp: Record "Prod. Order Component";
        IsHandled: Boolean;
    begin
        ItemJnlLine.LockTable();
        ItemJnlLine.Reset();
        ItemJnlLine.SetRange("Journal Template Name", ToTemplateName);
        ItemJnlLine.SetRange("Journal Batch Name", ToBatchName);
        if ItemJnlLine.FindLast then
            NextLineNo := ItemJnlLine."Line No." + 10000
        else
            NextLineNo := 10000;

        ProdOrderLine.Reset();
        ProdOrderLine.SetRange(Status, ProdOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrder."No.");
        if ProdOrderLineNo <> 0 then
            ProdOrderLine.SetRange("Line No.", ProdOrderLineNo);
        if ProdOrderLine.Find('-') then
            repeat
                OnCreateJnlLinesOnBeforeCheckProdOrderLine(ProdOrderLine);

                ProdOrderRtngLine.Reset();
                ProdOrderRtngLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
                ProdOrderRtngLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
                ProdOrderRtngLine.SetRange(Status, ProdOrderLine.Status);
                ProdOrderRtngLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
                if ProdOrderRtngLine.Find('-') then begin
                    InsertComponents(ProdOrderLine, true, 0); // With no Routing Link or illegal Routing Link
                    repeat
                        IsHandled := false;
                        OnCreateJnlLinesOnAfterFindProdOrderRtngLine(ProdOrderRtngLine, IsHandled);
                        if not IsHandled then begin
                            InsertOutputJnlLine(ProdOrderRtngLine, ProdOrderLine);
                            if ProdOrderRtngLine."Routing Link Code" <> '' then begin
                                ProdOrderComp.Reset();
                                ProdOrderComp.SetCurrentKey(Status, "Prod. Order No.", "Routing Link Code");
                                ProdOrderComp.SetRange(Status, ProdOrder.Status);
                                ProdOrderComp.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
                                ProdOrderComp.SetRange("Routing Link Code", ProdOrderRtngLine."Routing Link Code");
                                ProdOrderComp.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
                                ProdOrderComp.SetFilter("Item No.", '<>%1', '');
                                if ProdOrderComp.FindSet then
                                    repeat
                                        InsertConsumptionJnlLine(ProdOrderComp, ProdOrderLine, 1);
                                    until ProdOrderComp.Next = 0;
                            end;
                        end;
                    until ProdOrderRtngLine.Next = 0;
                end else begin
                    // Insert All Components - No Routing Link Check
                    InsertComponents(ProdOrderLine, false, 0);

                    // Create line for Output Qty
                    Clear(ProdOrderRtngLine);
                    InsertOutputJnlLine(ProdOrderRtngLine, ProdOrderLine);
                end;
            until ProdOrderLine.Next = 0;

        Commit();
    end;

    local procedure InsertComponents(ProdOrderLine: Record "Prod. Order Line"; CheckRoutingLink: Boolean; Level: Integer)
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        // Components with no Routing Link or illegal Routing Link
        ProdOrderComp.Reset();
        ProdOrderComp.SetRange(Status, ProdOrderLine.Status);
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderComp.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
        ProdOrderComp.SetFilter("Item No.", '<>%1', '');
        if ProdOrderComp.Find('-') then
            repeat
                if not CheckRoutingLink then
                    InsertConsumptionJnlLine(ProdOrderComp, ProdOrderLine, Level)
                else
                    if not RoutingLinkValid(ProdOrderComp, ProdOrderLine) then
                        InsertConsumptionJnlLine(ProdOrderComp, ProdOrderLine, Level);
            until ProdOrderComp.Next = 0;
    end;

    procedure RoutingLinkValid(ProdOrderComp: Record "Prod. Order Component"; ProdOrderLine: Record "Prod. Order Line"): Boolean
    var
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
    begin
        if ProdOrderComp."Routing Link Code" = '' then
            exit(false);

        with ProdOrderRtngLine do begin
            Reset;
            SetRange(Status, ProdOrderLine.Status);
            SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
            SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
            SetRange("Routing No.", ProdOrderLine."Routing No.");
            SetRange("Routing Link Code", ProdOrderComp."Routing Link Code");
            exit(FindFirst);
        end;
    end;

    local procedure InsertConsumptionJnlLine(ProdOrderComp: Record "Prod. Order Component"; ProdOrderLine: Record "Prod. Order Line"; Level: Integer)
    var
        Item: Record Item;
        Location: Record Location;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        NeededQty: Decimal;
        IsHandled: Boolean;
    begin
        with ProdOrderComp do begin
            Item.Get("Item No.");
            if Item.Blocked then begin
                Message(Text002, "Item No.");
                exit;
            end;

            IsHandled := false;
            OnInsertConsumptionJnlLineOnBeforeCheck(ProdOrderComp, ProdOrderLine, Item, IsHandled);
            if IsHandled then
                exit;

            if "Flushing Method" <> "Flushing Method"::Manual then
                NeededQty := 0
            else begin
                NeededQty := GetNeededQty(CalcBasedOn, true);
                if "Location Code" <> Location.Code then
                    if not Location.Get("Location Code") then
                        Clear(Location);
                if Location."Require Shipment" and Location."Require Pick" then
                    AdjustQtyToQtyPicked(NeededQty);
            end;

            ItemJnlLine.Init();
            OnInsertConsumptionJnlLineOnAfterItemJnlLineInit(ItemJnlLine);
            ItemJnlLine."Journal Template Name" := ToTemplateName;
            ItemJnlLine."Journal Batch Name" := ToBatchName;
            ItemJnlLine."Line No." := NextLineNo;
            ItemJnlLine.Validate("Posting Date", PostingDate);
            ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Consumption);
            ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
            ItemJnlLine.Validate("Order No.", "Prod. Order No.");
            ItemJnlLine.Validate("Source No.", ProdOrderLine."Item No.");
            ItemJnlLine.Validate("Item No.", "Item No.");
            ItemJnlLine.Validate("Unit of Measure Code", "Unit of Measure Code");
            ItemJnlLine.Description := Description;
            if NeededQty <> 0 then
                if Item."Rounding Precision" > 0 then
                    ItemJnlLine.Validate(Quantity, UOMMgt.RoundToItemRndPrecision(NeededQty, Item."Rounding Precision"))
                else
                    ItemJnlLine.Validate(Quantity, Round(NeededQty, UOMMgt.QtyRndPrecision));

            ItemJnlLine.Validate("Location Code", "Location Code");
            if "Bin Code" <> '' then
                ItemJnlLine."Bin Code" := "Bin Code";

            ItemJnlLine."Variant Code" := "Variant Code";
            ItemJnlLine.Validate("Order Line No.", "Prod. Order Line No.");
            ItemJnlLine.Validate("Prod. Order Comp. Line No.", "Line No.");

            ItemJnlLine.Level := Level;
            ItemJnlLine."Flushing Method" := "Flushing Method";
            ItemJnlLine."Source Code" := ItemJnlTemplate."Source Code";
            ItemJnlLine."Reason Code" := ItemJnlBatch."Reason Code";
            ItemJnlLine."Posting No. Series" := ItemJnlBatch."Posting No. Series";

            OnBeforeInsertConsumptionJnlLine(ItemJnlLine, ProdOrderComp, ProdOrderLine, Level);
            ItemJnlLine.Insert();
            OnAfterInsertConsumptionJnlLine(ItemJnlLine);

            if Item."Item Tracking Code" <> '' then
                ItemTrackingMgt.CopyItemTracking(RowID1, ItemJnlLine.RowID1, false);
        end;

        NextLineNo += 10000;

        OnAfterInsertConsumptionJnlLine(ItemJnlLine);
    end;

    local procedure InsertOutputJnlLine(ProdOrderRtngLine: Record "Prod. Order Routing Line"; ProdOrderLine: Record "Prod. Order Line")
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        CostCalcMgt: Codeunit "Cost Calculation Management";
        QtyToPost: Decimal;
    begin
        with ProdOrderLine do begin
            if ProdOrderRtngLine."Prod. Order No." <> '' then // Operation exist
                case ProdOrderRtngLine.Type of
                    ProdOrderRtngLine.Type::"Work Center":
                        begin
                            WorkCenter.Get(ProdOrderRtngLine."No.");
                            if WorkCenter.Blocked then begin
                                Message(Text005, WorkCenter.TableCaption, WorkCenter."No.", ProdOrderRtngLine."Operation No.");
                                exit;
                            end;
                        end;
                    ProdOrderRtngLine.Type::"Machine Center":
                        begin
                            MachineCenter.Get(ProdOrderRtngLine."No.");
                            if MachineCenter.Blocked then begin
                                Message(Text005, MachineCenter.TableCaption, MachineCenter."No.", ProdOrderRtngLine."Operation No.");
                                exit;
                            end;

                            WorkCenter.Get(ProdOrderRtngLine."Work Center No.");
                            if WorkCenter.Blocked then begin
                                Message(Text005, WorkCenter.TableCaption, WorkCenter."No.", ProdOrderRtngLine."Operation No.");
                                exit;
                            end;
                        end;
                end;

            if (ProdOrderRtngLine."Flushing Method" <> ProdOrderRtngLine."Flushing Method"::Manual) or
               (PresetOutputQuantity = PresetOutputQuantity::"Zero on All Operations") or
               ((PresetOutputQuantity = PresetOutputQuantity::"Zero on Last Operation") and
                IsLastOperation(ProdOrderRtngLine)) or
               ((ProdOrderRtngLine."Prod. Order No." = '') and
                (PresetOutputQuantity <> PresetOutputQuantity::"Expected Quantity")) or
               (ProdOrderRtngLine."Routing Status" = ProdOrderRtngLine."Routing Status"::Finished)
            then
                QtyToPost := 0
            else
                if ProdOrderRtngLine."Prod. Order No." <> '' then begin
                    QtyToPost :=
                      CostCalcMgt.CalcQtyAdjdForRoutingScrap(
                        "Quantity (Base)",
                        ProdOrderRtngLine."Scrap Factor % (Accumulated)",
                        ProdOrderRtngLine."Fixed Scrap Qty. (Accum.)") -
                      CostCalcMgt.CalcActOutputQtyBase(ProdOrderLine, ProdOrderRtngLine);
                    QtyToPost := QtyToPost / "Qty. per Unit of Measure";
                end else // No Routing Line
                    QtyToPost := "Remaining Quantity";

            if QtyToPost < 0 then
                QtyToPost := 0;

            ItemJnlLine.Init();
            ItemJnlLine."Journal Template Name" := ToTemplateName;
            ItemJnlLine."Journal Batch Name" := ToBatchName;
            ItemJnlLine."Line No." := NextLineNo;
            ItemJnlLine.Validate("Posting Date", PostingDate);
            ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Output);
            ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
            ItemJnlLine.Validate("Order No.", "Prod. Order No.");
            ItemJnlLine.Validate("Order Line No.", "Line No.");
            ItemJnlLine.Validate("Item No.", "Item No.");
            ItemJnlLine.Validate("Variant Code", "Variant Code");
            ItemJnlLine.Validate("Location Code", "Location Code");
            if "Bin Code" <> '' then
                ItemJnlLine.Validate("Bin Code", "Bin Code");
            ItemJnlLine.Validate("Routing No.", "Routing No.");
            ItemJnlLine.Validate("Routing Reference No.", "Routing Reference No.");
            if ProdOrderRtngLine."Prod. Order No." <> '' then
                ItemJnlLine.Validate("Operation No.", ProdOrderRtngLine."Operation No.");
            ItemJnlLine.Validate("Unit of Measure Code", "Unit of Measure Code");
            ItemJnlLine.Validate("Setup Time", 0);
            ItemJnlLine.Validate("Run Time", 0);
            if ("Location Code" <> '') and IsLastOperation(ProdOrderRtngLine) then
                ItemJnlLine.CheckWhse("Location Code", QtyToPost);
            if ItemJnlLine.SubcontractingWorkCenterUsed then
                ItemJnlLine.Validate("Output Quantity", 0)
            else
                ItemJnlLine.Validate("Output Quantity", QtyToPost);

            if ProdOrderRtngLine."Routing Status" = ProdOrderRtngLine."Routing Status"::Finished then
                ItemJnlLine.Finished := true;
            ItemJnlLine."Flushing Method" := ProdOrderRtngLine."Flushing Method";
            ItemJnlLine."Source Code" := ItemJnlTemplate."Source Code";
            ItemJnlLine."Reason Code" := ItemJnlBatch."Reason Code";
            ItemJnlLine."Posting No. Series" := ItemJnlBatch."Posting No. Series";

            OnBeforeInsertOutputJnlLine(ItemJnlLine, ProdOrderRtngLine, ProdOrderLine);
            ItemJnlLine.Insert();
            OnAfterInsertOutputJnlLine(ItemJnlLine);

            if IsLastOperation(ProdOrderRtngLine) then
                ItemTrackingMgt.CopyItemTracking(RowID1, ItemJnlLine.RowID1, false);
        end;

        NextLineNo += 10000;

        RecursiveInsertOutputJnlLine(ProdOrderRtngLine, ProdOrderLine);
    end;

    local procedure RecursiveInsertOutputJnlLine(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProdOrderLine: Record "Prod. Order Line")
    var
        AdditionalProdOrderLine: Record "Prod. Order Line";
        DoRecursion: Boolean;
    begin
        DoRecursion := false;
        OnBeforeRecursiveInsertOutputJnlLine(ProdOrderRoutingLine, ProdOrderLine, DoRecursion, AdditionalProdOrderLine);
        if DoRecursion and AdditionalProdOrderLine.HasFilter then
            if AdditionalProdOrderLine.FindSet then begin
                repeat
                    InsertOutputJnlLine(ProdOrderRoutingLine, AdditionalProdOrderLine);
                until AdditionalProdOrderLine.Next = 0;
            end;
    end;

    procedure InitSetupValues()
    begin
        MfgSetup.Get();
        PostingDate := WorkDate;
        CalcBasedOn := CalcBasedOn::"Expected Output";
        PresetOutputQuantity := MfgSetup."Preset Output Quantity";
    end;

    local procedure IsLastOperation(ProdOrderRoutingLine: Record "Prod. Order Routing Line") Result: Boolean
    begin
        Result := ProdOrderRoutingLine."Next Operation No." = '';
        OnAfterIsLastOperation(ProdOrderRoutingLine, Result);
    end;

    procedure SetTemplateAndBatchName()
    var
        PageTemplate: Option Item,Transfer,"Phys. Inventory",Revaluation,Consumption,Output,Capacity,"Prod. Order";
        User: Text;
    begin
        ItemJnlTemplate.Reset();
        ItemJnlTemplate.SetRange("Page ID", PAGE::"Production Journal");
        ItemJnlTemplate.SetRange(Recurring, false);
        ItemJnlTemplate.SetRange(Type, PageTemplate::"Prod. Order");
        if not ItemJnlTemplate.FindFirst then begin
            ItemJnlTemplate.Init();
            ItemJnlTemplate.Recurring := false;
            ItemJnlTemplate.Validate(Type, PageTemplate::"Prod. Order");
            ItemJnlTemplate.Validate("Page ID");

            ItemJnlTemplate.Name := Format(ItemJnlTemplate.Type, MaxStrLen(ItemJnlTemplate.Name));
            ItemJnlTemplate.Description := StrSubstNo(Text000, ItemJnlTemplate.Type);
            ItemJnlTemplate.Insert();
        end;

        ToTemplateName := ItemJnlTemplate.Name;

        ToBatchName := '';
        User := UpperCase(UserId); // Uppercase in case of Windows Login

        OnAfterSetTemplateAndBatchName(ItemJnlTemplate, User);

        if User <> '' then
            if (StrLen(User) < MaxStrLen(ItemJnlLine."Journal Batch Name")) and (ItemJnlLine."Journal Batch Name" <> '') then
                ToBatchName := CopyStr(ItemJnlLine."Journal Batch Name", 1, MaxStrLen(ItemJnlLine."Journal Batch Name") - 1) + 'A'
            else
                ToBatchName := DelChr(CopyStr(User, 1, MaxStrLen(ItemJnlLine."Journal Batch Name")), '>', '0123456789');

        if ToBatchName = '' then
            ToBatchName := Text003;

        if not ItemJnlBatch.Get(ToTemplateName, ToBatchName) then begin
            ItemJnlBatch.Init();
            ItemJnlBatch."Journal Template Name" := ItemJnlTemplate.Name;
            ItemJnlBatch.SetupNewBatch;
            ItemJnlBatch.Name := ToBatchName;
            ItemJnlBatch.Description := Text004;
            ItemJnlBatch.Insert(true);
        end;

        Commit();
    end;

    procedure DeleteJnlLines(TemplateName: Code[10]; BatchName: Code[10]; ProdOrderNo: Code[20]; ProdOrderLineNo: Integer)
    var
        ItemJnlLine2: Record "Item Journal Line";
        ReservEntry: Record "Reservation Entry";
    begin
        ItemJnlLine2.Reset();
        ItemJnlLine2.SetRange("Journal Template Name", TemplateName);
        ItemJnlLine2.SetRange("Journal Batch Name", BatchName);
        ItemJnlLine2.SetRange("Order Type", ItemJnlLine2."Order Type"::Production);
        ItemJnlLine2.SetRange("Order No.", ProdOrderNo);
        if ProdOrderLineNo <> 0 then
            ItemJnlLine2.SetRange("Order Line No.", ProdOrderLineNo);
        if ItemJnlLine2.Find('-') then begin
            repeat
                if ReservEntryExist(ItemJnlLine2, ReservEntry) then
                    ReservEntry.DeleteAll(true);
            until ItemJnlLine2.Next = 0;

            OnBeforeDeleteAllItemJnlLine(ItemJnlLine2);
            ItemJnlLine2.DeleteAll(true);
        end;
    end;

    local procedure DataHasChanged(TemplateName: Code[10]; BatchName: Code[10]; ProdOrderNo: Code[20]; ProdOrderLineNo: Integer): Boolean
    var
        ItemJnlLine2: Record "Item Journal Line";
        ReservEntry: Record "Reservation Entry";
        HasChanged: Boolean;
    begin
        ItemJnlLine2.Reset();
        ItemJnlLine2.SetRange("Journal Template Name", TemplateName);
        ItemJnlLine2.SetRange("Journal Batch Name", BatchName);
        ItemJnlLine2.SetRange("Order Type", ItemJnlLine2."Order Type"::Production);
        ItemJnlLine2.SetRange("Order No.", ProdOrderNo);
        if ProdOrderLineNo <> 0 then
            ItemJnlLine2.SetRange("Order Line No.", ProdOrderLineNo);
        if ItemJnlLine2.Find('-') then
            repeat
                if ItemJnlLine2."Changed by User" then
                    exit(true);
                if ReservEntryExist(ItemJnlLine2, ReservEntry) then
                    exit(true);
            until ItemJnlLine2.Next = 0;

        HasChanged := false;
        OnAfterDataHasChanged(ItemJnlLine2, ProdOrderLineNo, HasChanged);
        exit(HasChanged);
    end;

    procedure ReservEntryExist(ItemJnlLine2: Record "Item Journal Line"; var ReservEntry: Record "Reservation Entry"): Boolean
    begin
        with ItemJnlLine2 do begin
            ReservEntry.Reset();
            ReservEntry.SetCurrentKey(
              "Source ID", "Source Ref. No.", "Source Type", "Source Subtype", "Source Batch Name", "Source Prod. Order Line");
            ReservEntry.SetRange("Source ID", "Journal Template Name");
            ReservEntry.SetRange("Source Ref. No.", "Line No.");
            ReservEntry.SetRange("Source Type", DATABASE::"Item Journal Line");
            ReservEntry.SetRange("Source Subtype", "Entry Type");
            ReservEntry.SetRange("Source Batch Name", "Journal Batch Name");
            ReservEntry.SetRange("Source Prod. Order Line", 0);
            if not ReservEntry.IsEmpty then
                exit(true);

            exit(false);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDataHasChanged(var ItemJournalLine: Record "Item Journal Line"; ProdOrderLineNo: Integer; var HasChanged: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertConsumptionJnlLine(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertOutputJnlLine(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsLastOperation(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var IsLastOperation: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTemplateAndBatchName(var ItemJournalTemplate: Record "Item Journal Template"; var User: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertConsumptionJnlLine(var ItemJournalLine: Record "Item Journal Line"; ProdOrderComp: Record "Prod. Order Component"; ProdOrderLine: Record "Prod. Order Line"; Level: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertOutputJnlLine(var ItemJournalLine: Record "Item Journal Line"; ProdOrderRtngLine: Record "Prod. Order Routing Line"; ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteAllItemJnlLine(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRecursiveInsertOutputJnlLine(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProdOrderLine: Record "Prod. Order Line"; var DoRecursion: Boolean; var AdditionalProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunProductionJnl(ToTemplateName: Code[10]; ToBatchName: Code[10]; ProdOrder: Record "Production Order"; ActualLineNo: Integer; PostingDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateJnlLinesOnAfterFindProdOrderRtngLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateJnlLinesOnBeforeCheckProdOrderLine(var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertConsumptionJnlLineOnBeforeCheck(ProdOrderComponent: Record "Prod. Order Component"; ProdOrderLine: Record "Prod. Order Line"; Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertConsumptionJnlLineOnAfterItemJnlLineInit(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;
}

