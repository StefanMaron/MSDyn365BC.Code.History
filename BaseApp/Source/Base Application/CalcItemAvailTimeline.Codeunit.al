#pragma warning disable AS0018
#pragma warning disable AS0088
#if not CLEAN21
codeunit 5540 "Calc. Item Avail. Timeline"
{
    ObsoleteReason = 'This codeunit is obsolete as the TimeLineVisualizer is not available on the web client.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';
    
    trigger OnRun()
    begin
    end;

    var
        TempInventoryEventBuffer: Record "Inventory Event Buffer" temporary;
        CalcItemAvailEventBuf: Codeunit "Calc. Item Availability";

        TXT002: Label '%1 not supported: %2.';
        TXT004: Label 'One or more lines in the planning or requisition worksheet have been changed by another user. Click Reload, make the changes again, and then click Save Changes.';
        TXT010: Label 'Inventory';
        TXT011: Label 'Sales';
        TXT012: Label 'Purchase';
        TXT013: Label 'Transfer';
        TXT014: Label 'Service';
        TXT015: Label 'One or more lines in the planning or requisition worksheet have been deleted by another user. Click Reload, make the changes again, and then click Save Changes.';
        TXT016: Label 'Assembly';
        TXT017: Label 'Assembly Component';
        TXT018: Label 'Planning Component';

    procedure Initialize(var Item: Record Item; ForecastName: Code[10]; IncludeBlanketOrders: Boolean; ExcludeForecastBefore: Date; IncludePlan: Boolean)
    begin
        TempInventoryEventBuffer.Reset();
        TempInventoryEventBuffer.DeleteAll();

        CalcItemAvailEventBuf.CalcNewInvtEventBuf(Item, ForecastName, IncludeBlanketOrders, ExcludeForecastBefore, IncludePlan);
        CalcItemAvailEventBuf.GetInvEventBuffer(TempInventoryEventBuffer);
    end;

    procedure CreateTimelineEvents(var TempTimelineEvent: Record "Timeline Event" temporary)
    var
        TempInventoryEventBuffer2: Record "Inventory Event Buffer" temporary;
        InitialDate: Date;
        FinalDate: Date;
    begin
        InitialDate := WorkDate();
        FinalDate := WorkDate();

        with TempInventoryEventBuffer do begin
            SetCurrentKey("Availability Date", Type);
            SetFilter("Availability Date", '<> %1', 0D);
            if FindFirst() then
                InitialDate := "Availability Date";
            if FindLast() then
                FinalDate := "Availability Date";

            // Initial Inventory
            SetRange("Availability Date");
            SetRange(Type, Type::Inventory);
            if not FindSet() then
                InsertInitialEvent(TempTimelineEvent, InitialDate)
            else begin // Sum up inventory
                TempInventoryEventBuffer2 := TempInventoryEventBuffer;
                TempInventoryEventBuffer2."Remaining Quantity (Base)" := 0;
                TempInventoryEventBuffer2."Availability Date" := InitialDate;
                repeat
                    TempInventoryEventBuffer2."Remaining Quantity (Base)" += "Remaining Quantity (Base)";
                until Next() = 0;
                InsertTimelineEvent(TempTimelineEvent, TempInventoryEventBuffer2)
            end;

            // Supply and Demand Events
            SetFilter("Availability Date", '<> %1', 0D);
            SetFilter(Type,
              '%1..%2|%3|%4',
              Type::Purchase, Type::"Blanket Sales Order", Type::"Assembly Order", Type::"Assembly Component");
            if FindSet() then
                repeat
                    InsertTimelineEvent(TempTimelineEvent, TempInventoryEventBuffer);
                until Next() = 0;

            OnCreateTimelineEventsBeforePlanning(TempTimelineEvent, TempInventoryEventBuffer);

            // Planning Events - New supplies already planned
            SetFilter("Availability Date", '<> %1', 0D);
            SetRange(Type, Type::Plan);
            SetRange("Action Message", "Action Message"::New);
            if FindSet() then
                repeat
                    InsertTimelineEvent(TempTimelineEvent, TempInventoryEventBuffer);
                until Next() = 0;

            // Final Inventory
            Reset();
            if FindLast() then
                InsertFinalEvent(TempTimelineEvent, "Entry No." + 1, FinalDate);
        end;
    end;

    procedure InsertTimelineEvent(var TempToTimelineEvent: Record "Timeline Event" temporary; TempFromInventoryEventBuffer: Record "Inventory Event Buffer" temporary)
    begin
        TempToTimelineEvent.Init();
        TempToTimelineEvent.ID := TempFromInventoryEventBuffer."Entry No.";
        TempToTimelineEvent."Source Line ID" := TempFromInventoryEventBuffer."Source Line ID";
        TempToTimelineEvent."Original Date" := TempFromInventoryEventBuffer."Availability Date";
        TempToTimelineEvent."New Date" := TempToTimelineEvent."Original Date";
        TempToTimelineEvent."Original Quantity" := TempFromInventoryEventBuffer."Remaining Quantity (Base)";
        TempToTimelineEvent."New Quantity" := TempToTimelineEvent."Original Quantity";

        UpdateTimelineEventDetails(TempToTimelineEvent, TempFromInventoryEventBuffer);
        MapToTimelineTransactionType(TempToTimelineEvent, TempFromInventoryEventBuffer);

        if TempToTimelineEvent."Transaction Type" = TempToTimelineEvent."Transaction Type"::"Adjustable Supply" then
            UpdateEventFromPlanning(TempToTimelineEvent, TempFromInventoryEventBuffer);

        if TempToTimelineEvent."Transaction Type" = TempToTimelineEvent."Transaction Type"::"New Supply" then begin
            TempToTimelineEvent.ChangeRefNo := Format(TempFromInventoryEventBuffer."Source Line ID");
            TempToTimelineEvent."Original Date" := 0D;
            TempToTimelineEvent."Original Quantity" := 0;
        end;

        TempToTimelineEvent.Insert();
    end;

    local procedure MapToTimelineTransactionType(var TempToTimelineEvent: Record "Timeline Event" temporary; TempInventoryEventBuffer: Record "Inventory Event Buffer" temporary)
    var
        IsHandled: Boolean;
    begin
        with TempInventoryEventBuffer do begin
            if Type = Type::Inventory then begin
                TempToTimelineEvent."Transaction Type" := TempToTimelineEvent."Transaction Type"::Initial;
                exit;
            end;

            if ("Remaining Quantity (Base)" < 0) and
               (Type <> Type::Forecast) and
               (Type <> Type::"Blanket Sales Order")
            then begin
                TempToTimelineEvent."Transaction Type" := TempToTimelineEvent."Transaction Type"::"Fixed Demand";
                exit;
            end;

            case Type of
                Type::Purchase, Type::Production, Type::Transfer, Type::"Assembly Order":
                    TempToTimelineEvent."Transaction Type" := TempToTimelineEvent."Transaction Type"::"Adjustable Supply";
                Type::Sale, Type::Service, Type::Job, Type::Component, Type::"Assembly Component":
                    TempToTimelineEvent."Transaction Type" := TempToTimelineEvent."Transaction Type"::"Fixed Supply";
                Type::Forecast, Type::"Blanket Sales Order":
                    TempToTimelineEvent."Transaction Type" := TempToTimelineEvent."Transaction Type"::"Expected Demand";
                Type::Plan:
                    if "Action Message" = "Action Message"::New then
                        TempToTimelineEvent."Transaction Type" := TempToTimelineEvent."Transaction Type"::"New Supply";
                else begin
                        OnMapToTimelineTransactionTypeOnBeforeError(TempToTimelineEvent, TempInventoryEventBuffer, IsHandled);
                        if not IsHandled then
                            Error(TXT002, TempToTimelineEvent.FieldCaption("Transaction Type"), Type);
                    end;
            end;
        end;
    end;

    local procedure UpdateTimelineEventDetails(var TempToTimelineEvent: Record "Timeline Event" temporary; TempFromInventoryEventBuffer: Record "Inventory Event Buffer" temporary)
    var
        SalesHeader: Record "Sales Header";
        PurchHeader: Record "Purchase Header";
        ReqLine: Record "Requisition Line";
        TransHeader: Record "Transfer Header";
        ServHeader: Record "Service Header";
        Job: Record Job;
        ProdOrder: Record "Production Order";
        ProdForecastName: Record "Production Forecast Name";
        ProdForecastEntry: Record "Production Forecast Entry";
        AsmHeader: Record "Assembly Header";
        RecRef: RecordRef;
        SourceType: Integer;
        SourceSubtype: Integer;
        SourceID: Code[20];
        SourceBatchName: Code[10];
        SourceProdOrderLine: Integer;
        SourceRefNo: Integer;
    begin
        with TempFromInventoryEventBuffer do begin
            CalcItemAvailEventBuf.GetSourceReferences("Source Line ID", "Transfer Direction",
              SourceType, SourceSubtype, SourceID, SourceBatchName, SourceProdOrderLine, SourceRefNo);
            case SourceType of
                DATABASE::"Item Ledger Entry":
                    TempToTimelineEvent.Description := TXT010;
                DATABASE::"Sales Line":
                    begin
                        SalesHeader.Get(SourceSubtype, SourceID);
                        RecRef.GetTable(SalesHeader);
                        TempToTimelineEvent."Source Document ID" := RecRef.RecordId;
                        TempToTimelineEvent.Description :=
                          StrSubstNo('%1 %2 %3 %4', TXT011, SalesHeader."Document Type", SalesHeader."No.", SalesHeader."Sell-to Customer Name");
                    end;
                DATABASE::"Purchase Line":
                    begin
                        PurchHeader.Get(SourceSubtype, SourceID);
                        RecRef.GetTable(PurchHeader);
                        TempToTimelineEvent."Source Document ID" := RecRef.RecordId;
                        TempToTimelineEvent.Description :=
                          StrSubstNo('%1 %2 %3 %4', TXT012, PurchHeader."Document Type", PurchHeader."No.", PurchHeader."Buy-from Vendor Name");
                    end;
                DATABASE::"Transfer Line":
                    begin
                        TransHeader.Get(SourceID);
                        RecRef.GetTable(TransHeader);
                        TempToTimelineEvent."Source Document ID" := RecRef.RecordId;
                        TempToTimelineEvent.Description :=
                          StrSubstNo('%1 %2', TXT013, TransHeader."No.");
                    end;
                DATABASE::"Prod. Order Line":
                    begin
                        ProdOrder.Get(SourceSubtype, SourceID);
                        RecRef.GetTable(ProdOrder);
                        TempToTimelineEvent."Source Document ID" := RecRef.RecordId;
                        TempToTimelineEvent.Description :=
                          StrSubstNo('%1 %2 %3', ProdOrder.TableCaption(), ProdOrder."No.", ProdOrder.Description);
                    end;
                DATABASE::"Prod. Order Component":
                    begin
                        ProdOrder.Get(SourceSubtype, SourceID);
                        RecRef.GetTable(ProdOrder);
                        TempToTimelineEvent."Source Document ID" := RecRef.RecordId;
                        TempToTimelineEvent.Description :=
                          StrSubstNo('%1 %2 %3', ProdOrder.TableCaption(), ProdOrder."No.", ProdOrder.Description);
                    end;
                DATABASE::"Service Line":
                    begin
                        ServHeader.Get(SourceSubtype, SourceID);
                        RecRef.GetTable(ServHeader);
                        TempToTimelineEvent."Source Document ID" := RecRef.RecordId;
                        TempToTimelineEvent.Description :=
                          StrSubstNo('%1 %2 %3', TXT014, ServHeader."No.", ServHeader."Ship-to Name");
                    end;
                DATABASE::"Job Planning Line":
                    begin
                        Job.Get(SourceID);
                        RecRef.GetTable(Job);
                        TempToTimelineEvent."Source Document ID" := RecRef.RecordId;
                        TempToTimelineEvent.Description :=
                          StrSubstNo('%1 %2 %3', Job.TableCaption(), Job."No.", Job."Bill-to Customer No.");
                    end;
                DATABASE::"Requisition Line":
                    begin
                        ReqLine.Get(SourceID, SourceBatchName, SourceRefNo);
                        RecRef.GetTable(ReqLine);
                        TempToTimelineEvent."Source Document ID" := RecRef.RecordId;
                        TempToTimelineEvent.Description :=
                          StrSubstNo(
                            '%1 %2 %3 %4', ReqLine.TableCaption(), ReqLine."Worksheet Template Name",
                            ReqLine."Journal Batch Name", ReqLine.Description);
                    end;
                DATABASE::"Planning Component":
                    begin
                        ReqLine.Get(SourceID, SourceBatchName, SourceProdOrderLine);
                        RecRef.GetTable(ReqLine);
                        TempToTimelineEvent."Source Document ID" := "Source Line ID";
                        TempToTimelineEvent.Description :=
                          StrSubstNo(
                            '%1 - %2 %3 %4 %5', TXT018, RecRef.Name, ReqLine."Worksheet Template Name",
                            ReqLine."Journal Batch Name", ReqLine.Description);
                    end;
                DATABASE::"Production Forecast Entry":
                    begin
                        ProdForecastEntry.Get(SourceRefNo);
                        ProdForecastName.Get(ProdForecastEntry."Production Forecast Name");
                        RecRef.GetTable(ProdForecastName);
                        TempToTimelineEvent."Source Document ID" := RecRef.RecordId;
                        TempToTimelineEvent.Description :=
                          StrSubstNo(
                            '%1 %2 %3',
                            ProdForecastName.TableCaption(), ProdForecastName.Name,
                            ProdForecastName.Description);
                    end;
                DATABASE::"Assembly Header":
                    begin
                        AsmHeader.Get(SourceSubtype, SourceID);
                        RecRef.GetTable(AsmHeader);
                        TempToTimelineEvent."Source Document ID" := RecRef.RecordId;
                        TempToTimelineEvent.Description :=
                          StrSubstNo('%1 %2 %3 %4', TXT016, AsmHeader."Document Type", AsmHeader."No.", AsmHeader.Description);
                    end;
                DATABASE::"Assembly Line":
                    begin
                        AsmHeader.Get(SourceSubtype, SourceID);
                        RecRef.GetTable(AsmHeader);
                        TempToTimelineEvent."Source Document ID" := RecRef.RecordId;
                        TempToTimelineEvent.Description :=
                          StrSubstNo('%1 %2 %3 %4', TXT017, AsmHeader."Document Type", AsmHeader."No.", AsmHeader.Description);
                    end;
            end;
        end;

        OnAfterUpdateTimelineEventDetails(TempToTimelineEvent, TempFromInventoryEventBuffer);
    end;

    local procedure UpdateEventFromPlanning(var TempToTimelineEvent: Record "Timeline Event" temporary; TempFromInventoryEventBuffer: Record "Inventory Event Buffer" temporary)
    var
        ReqLine: Record "Requisition Line";
        RecRef: RecordRef;
        SourceType: Integer;
        SourceSubtype: Integer;
        SourceID: Code[20];
        SourceBatchName: Code[10];
        SourceProdOrderLine: Integer;
        SourceRefNo: Integer;
    begin
        CalcItemAvailEventBuf.GetSourceReferences(
          TempFromInventoryEventBuffer."Source Line ID", "Transfer Direction"::Outbound,
          SourceType, SourceSubtype, SourceID, SourceBatchName, SourceProdOrderLine, SourceRefNo);

        ReqLine.Reset();
        ReqLine.SetCurrentKey("Ref. Order Type", "Ref. Order Status", "Ref. Order No.", "Ref. Line No.");
        ReqLine.SetRange("Ref. Order Type", MapToRefOrderType(SourceType));
        ReqLine.SetRange("Ref. Order No.", SourceID);
        if SourceProdOrderLine > 0 then
            ReqLine.SetRange("Ref. Line No.", SourceProdOrderLine)
        else
            ReqLine.SetRange("Ref. Line No.", SourceRefNo);

        if not ReqLine.FindFirst() then
            // An existing supply can only be changed if it's linked to an existing planning line
            TempToTimelineEvent."Transaction Type" := TempToTimelineEvent."Transaction Type"::"Fixed Supply"
        else begin
            RecRef.GetTable(ReqLine);
            TempToTimelineEvent.ChangeRefNo := Format(RecRef.RecordId);

            case ReqLine."Action Message" of
                ReqLine."Action Message"::"Change Qty.":
                    TempToTimelineEvent."New Quantity" := ReqLine."Quantity (Base)";
                ReqLine."Action Message"::Reschedule:
                    TempToTimelineEvent."New Date" := ReqLine."Due Date";
                ReqLine."Action Message"::"Resched. & Chg. Qty.":
                    begin
                        TempToTimelineEvent."New Quantity" := ReqLine."Quantity (Base)";
                        TempToTimelineEvent."New Date" := ReqLine."Due Date";
                    end;
                ReqLine."Action Message"::Cancel:
                    TempToTimelineEvent."New Quantity" := 0;
            end;
        end;
    end;

    local procedure MapToRefOrderType(SourceType: Integer): Integer
    var
        ReqLine: Record "Requisition Line";
    begin
        case SourceType of
            DATABASE::"Purchase Line":
                exit(ReqLine."Ref. Order Type"::Purchase);
            DATABASE::"Prod. Order Line":
                exit(ReqLine."Ref. Order Type"::"Prod. Order");
            DATABASE::"Transfer Line":
                exit(ReqLine."Ref. Order Type"::Transfer);
            DATABASE::"Assembly Header":
                exit(ReqLine."Ref. Order Type"::Assembly);
            else
                exit(0);
        end;
    end;

    local procedure TransferChangeToPlanningLine(TempTimelineEventChange: Record "Timeline Event Change" temporary; ItemNo: Code[20]; var CurrTemplateName: Code[10]; var CurrWorksheetName: Code[10]; CurrLocationCode: Code[10]; CurrVariantCode: Code[10])
    var
        ReqLine: Record "Requisition Line";
        xReqLine: Record "Requisition Line";
        UOMMgt: Codeunit "Unit of Measure Management";
        RecRef: RecordRef;
        TemplateNameFieldRef: FieldRef;
        WorksheetNameFieldRef: FieldRef;
        LineNoFieldRef: FieldRef;
        Qty: Decimal;
        LineNo: Integer;
    begin
        RecRef.Open(DATABASE::"Requisition Line");

        if not GetSourcePlanningLine(TempTimelineEventChange, RecRef) then begin
            if TempTimelineEventChange.NewSupply() then
                InsertNewPlanningLine(
                  TempTimelineEventChange, ItemNo, CurrTemplateName, CurrWorksheetName, CurrLocationCode, CurrVariantCode)
            else
                Error(TXT015) // New Supply is the only type that can be inserted in a planning line
        end else begin
            TemplateNameFieldRef := RecRef.Field(1);
            WorksheetNameFieldRef := RecRef.Field(2);
            LineNoFieldRef := RecRef.Field(3);

            with ReqLine do begin
                LineNo := LineNoFieldRef.Value();
                Get(Format(TemplateNameFieldRef.Value()), Format(WorksheetNameFieldRef.Value()), LineNo);

                if SourcePlanningLineChanged(ReqLine, ItemNo) then
                    Error(TXT004);

                xReqLine := ReqLine;

                if TempTimelineEventChange."Due Date" <> "Due Date" then begin
                    SetCurrFieldNo(FieldNo("Due Date"));
                    Validate("Due Date", TempTimelineEventChange."Due Date");
                end;

                if TempTimelineEventChange.Quantity <> "Quantity (Base)" then begin
                    Qty := UOMMgt.CalcQtyFromBase(TempTimelineEventChange.Quantity, "Qty. per Unit of Measure");
                    SetCurrFieldNo(FieldNo(Quantity));
                    Validate(Quantity, Qty);
                end;

                if ("Due Date" <> xReqLine."Due Date") or (Quantity <> xReqLine.Quantity) then
                    Modify(true);
            end;
        end;
    end;

    local procedure SourcePlanningLineChanged(ReqLine: Record "Requisition Line"; ItemNo: Code[20]): Boolean
    begin
        with ReqLine do
            exit((Type <> Type::Item) or ("No." <> ItemNo));
    end;

    local procedure InsertNewPlanningLine(TempTimelineEventChange: Record "Timeline Event Change" temporary; ItemNo: Code[20]; var CurrTemplateName: Code[10]; var CurrWorksheetName: Code[10]; CurrLocationCode: Code[10]; CurrVariantCode: Code[10])
    var
        ReqLine: Record "Requisition Line";
        LicensePermission: Record "License Permission";
        UOMMgt: Codeunit "Unit of Measure Management";
    begin
        with ReqLine do begin
            if (CurrTemplateName = '') or (CurrWorksheetName = '') then
                GetPlanningWorksheetName(ItemNo, CurrTemplateName, CurrWorksheetName);

            Init();
            "Worksheet Template Name" := CurrTemplateName;
            "Journal Batch Name" := CurrWorksheetName;
            "Line No." := GetNextLineNo("Worksheet Template Name", "Journal Batch Name");
            Type := Type::Item;
            SetCurrFieldNo(FieldNo("No."));
            Validate("No.", ItemNo);
            SetCurrFieldNo(FieldNo("Action Message"));
            Validate("Action Message", "Action Message"::New);
            if CurrVariantCode <> '' then begin
                SetCurrFieldNo(FieldNo("Variant Code"));
                Validate("Variant Code", CurrVariantCode);
            end;
            if CurrLocationCode <> '' then begin
                SetCurrFieldNo(FieldNo("Location Code"));
                Validate("Location Code", CurrLocationCode);
            end;
            SetCurrFieldNo(FieldNo("Due Date"));
            Validate("Due Date", TempTimelineEventChange."Due Date");
            SetCurrFieldNo(FieldNo(Quantity));
            Validate(Quantity, UOMMgt.CalcQtyFromBase(TempTimelineEventChange.Quantity, "Qty. per Unit of Measure"));
            if "Ref. Order Type" = "Ref. Order Type"::"Prod. Order" then
                Validate("Ref. Order Status", "Ref. Order Status"::"Firm Planned");
            Insert(true);

            if HasLicensePermission(LicensePermission."Object Type"::Report, REPORT::"Refresh Planning Demand") then
                RefreshReqLine(ReqLine);
        end;
    end;

    local procedure GetPlanningWorksheetName(ItemNo: Code[20]; var CurrTemplateName: Code[10]; var CurrWorksheetName: Code[10])
    var
        ReqLine: Record "Requisition Line";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        ReqWkshName: Record "Requisition Wksh. Name";
        LicensePermission: Record "License Permission";
    begin
        with ReqLine do begin
            SetCurrentKey(Type, "No.", "Variant Code", "Location Code");
            SetRange(Type, Type::Item);
            SetRange("No.", ItemNo);
            if FindFirst() then begin
                CurrTemplateName := "Worksheet Template Name";
                CurrWorksheetName := "Journal Batch Name";
            end else begin
                ReqWkshTemplate.Reset();
                if HasLicensePermission(LicensePermission."Object Type"::Page, PAGE::"Planning Worksheet") then
                    ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::Planning)
                else
                    ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::"Req.");
                ReqWkshTemplate.SetRange(Recurring, false);
                if ReqWkshTemplate.Count = 1 then begin
                    ReqWkshTemplate.FindFirst();
                    CurrTemplateName := ReqWkshTemplate.Name
                end else
                    if PAGE.RunModal(0, ReqWkshTemplate) = ACTION::LookupOK then
                        CurrTemplateName := ReqWkshTemplate.Name
                    else
                        Error('');

                ReqWkshName.FilterGroup(2);
                ReqWkshName.SetRange("Worksheet Template Name", CurrTemplateName);
                ReqWkshName.FilterGroup(0);
                if ReqWkshName.Count = 1 then begin
                    ReqWkshName.FindFirst();
                    CurrWorksheetName := ReqWkshName.Name
                end else
                    if PAGE.RunModal(0, ReqWkshName) = ACTION::LookupOK then
                        CurrWorksheetName := ReqWkshName.Name
                    else
                        Error('');
            end;
        end;
    end;

    local procedure GetNextLineNo(CurrTemplateName: Code[10]; CurrWorksheetName: Code[10]) NextLineNo: Integer
    var
        ReqLine: Record "Requisition Line";
    begin
        with ReqLine do begin
            Reset();
            SetRange("Worksheet Template Name", CurrTemplateName);
            SetRange("Journal Batch Name", CurrWorksheetName);
            if FindLast() then
                NextLineNo := "Line No." + 10000
            else
                NextLineNo := 10000;
        end;
    end;

    local procedure RefreshReqLine(ReqLine: Record "Requisition Line")
    var
        ReqLine2: Record "Requisition Line";
        RefreshPlanningDemand: Report "Refresh Planning Demand";
    begin
        with ReqLine do begin
            ReqLine2.SetRange("Worksheet Template Name", "Worksheet Template Name");
            ReqLine2.SetRange("Journal Batch Name", "Journal Batch Name");
            ReqLine2.SetRange("Line No.", "Line No.");

            RefreshPlanningDemand.UseRequestPage := false;
            RefreshPlanningDemand.InitializeRequest(1, true, true); // Refresh Backward from Due Date
            RefreshPlanningDemand.SetTableView(ReqLine2);
            RefreshPlanningDemand.Run();
        end;
    end;

    procedure FindLocationWithinFilter(LocationFilter: Text): Code[10]
    var
        Location: Record Location;
        TempEmptyLocation: Record Location temporary;
    begin
        TempEmptyLocation.Init();
        TempEmptyLocation.Insert();
        TempEmptyLocation.SetFilter(Code, LocationFilter);
        if not TempEmptyLocation.IsEmpty() then
            exit('');

        if BlankFilterStr(LocationFilter) then
            exit('');

        Location.SetFilter(Code, LocationFilter);
        Location.FindFirst();
        exit(Location.Code);
    end;

    procedure FindVariantWithinFilter(ItemNo: Code[20]; VariantFilter: Text): Code[10]
    var
        ItemVariant: Record "Item Variant";
        TempEmptyItemVariant: Record "Item Variant" temporary;
    begin
        TempEmptyItemVariant.Init();
        TempEmptyItemVariant."Item No." := ItemNo;
        TempEmptyItemVariant.Insert();
        TempEmptyItemVariant.SetRange("Item No.", ItemNo);
        TempEmptyItemVariant.SetFilter(Code, VariantFilter);
        if not TempEmptyItemVariant.IsEmpty() then
            exit('');

        if BlankFilterStr(VariantFilter) then
            exit('');

        ItemVariant.SetRange("Item No.", ItemNo);
        ItemVariant.SetFilter(Code, VariantFilter);
        ItemVariant.FindFirst();
        exit(ItemVariant.Code);
    end;

    local procedure BlankFilterStr(FilterStr: Text): Boolean
    begin
        exit((FilterStr = '') or (DelChr(FilterStr, '=') = BlankValue()))
    end;

    procedure BlankValue(): Text[2]
    begin
        exit('''''');
    end;

    procedure ShowDocument(RecordID: RecordID)
    begin
        CalcItemAvailEventBuf.ShowDocument(RecordID);
    end;

    local procedure InsertInitialEvent(var TempTimelineEvent: Record "Timeline Event" temporary; InitialDate: Date)
    begin
        InsertInventoryEvent(TempTimelineEvent, 0, TempTimelineEvent."Transaction Type"::Initial, InitialDate);
    end;

    procedure InitialTimespanDays(): Integer
    begin
        exit(2);
    end;

    local procedure InsertFinalEvent(var TempTimelineEvent: Record "Timeline Event" temporary; ID: Integer; FinalDate: Date)
    begin
        InsertInventoryEvent(TempTimelineEvent, ID, FinalTransactionType(), FinalDate);
    end;

    procedure FinalTimespanDays(): Integer
    begin
        exit(7);
    end;

    procedure FinalTransactionType(): Integer
    begin
        exit(99);
    end;

    local procedure InsertInventoryEvent(var TempTimelineEvent: Record "Timeline Event" temporary; ID: Integer; TransactionType: Integer; InventoryDate: Date)
    begin
        TempTimelineEvent.Init();
        TempTimelineEvent.ID := ID;
        TempTimelineEvent."Transaction Type" := TransactionType;
        TempTimelineEvent."Original Date" := InventoryDate;
        TempTimelineEvent."New Date" := TempTimelineEvent."Original Date";
        TempTimelineEvent.Description := TXT010;
        TempTimelineEvent.Insert();
    end;

    local procedure GetSourcePlanningLine(TempTimelineEventChange: Record "Timeline Event Change" temporary; var RecRef: RecordRef): Boolean
    var
        RecID: RecordID;
    begin
        if TempTimelineEventChange.NewSupply() then
            exit(false);

        Evaluate(RecID, TempTimelineEventChange.ChangeRefNo);
        exit(RecRef.Get(RecID));
    end;

    procedure TransferChangesToPlanningWksh(var TimelineEventChange: Record "Timeline Event Change"; ItemNo: Code[20]; LocationFilter: Text; VariantFilter: Text; TemplateNameNewSupply: Code[10]; WorksheetNameNewSupply: Code[10]) NewSupplyTransfer: Boolean
    var
        LocationCodeNewSupply: Code[10];
        VariantCodeNewSupply: Code[10];
    begin
        LocationCodeNewSupply := FindLocationWithinFilter(LocationFilter);
        VariantCodeNewSupply := FindVariantWithinFilter(ItemNo, VariantFilter);
        NewSupplyTransfer := false;

        if TimelineEventChange.FindSet() then
            repeat
                TransferChangeToPlanningLine(
                  TimelineEventChange, ItemNo, TemplateNameNewSupply, WorksheetNameNewSupply, LocationCodeNewSupply, VariantCodeNewSupply);

                if not NewSupplyTransfer then
                    NewSupplyTransfer := TimelineEventChange.NewSupply();

            until TimelineEventChange.Next() = 0;
    end;

    local procedure HasLicensePermission(ObjectType: Option; ObjectID: Integer): Boolean
    var
        LicensePermission: Record "License Permission";
    begin
        if LicensePermission.Get(ObjectType, ObjectID) then
            exit(LicensePermission."Execute Permission" = LicensePermission."Execute Permission"::Yes);

        exit(false);
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnCreateTimelineEventsBeforePlanning(var TempTimelineEvent: Record "Timeline Event" temporary; var TempInventoryEventBuffer: Record "Inventory Event Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateTimelineEventDetails(var TempToTimelineEvent: Record "Timeline Event" temporary; TempFromInventoryEventBuffer: Record "Inventory Event Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMapToTimelineTransactionTypeOnBeforeError(var TempToTimelineEvent: Record "Timeline Event" temporary; TempInventoryEventBuffer: Record "Inventory Event Buffer" temporary; var IsHandled: Boolean)
    begin
    end;
}
#endif
#pragma warning restore AS0018
#pragma warning restore AS0088
