codeunit 5520 "Get Unplanned Demand"
{
    Permissions = TableData "Production Order" = r,
                  TableData "Prod. Order Component" = r,
                  TableData "Prod. Order Capacity Need" = r,
                  TableData "Service Header" = r;
    TableNo = "Unplanned Demand";

    trigger OnRun()
    begin
        if IncludeMetDemandForSpecificSalesOrderNo <> '' then
            SetFilterToSpecificSalesOrder();

        DeleteAll();
        SalesLine.SetFilter("Document Type", '%1|%2', SalesLine."Document Type"::Order, SalesLine."Document Type"::"Return Order");
        ProdOrderComp.SetFilter(
            Status, '%1|%2|%3', ProdOrderComp.Status::Planned, ProdOrderComp.Status::"Firm Planned", ProdOrderComp.Status::Released);
        ServLine.SetRange("Document Type", ServLine."Document Type"::Order);
        AsmLine.SetRange("Document Type", AsmLine."Document Type"::Order);
        JobPlanningLine.SetRange(Status, JobPlanningLine.Status::Order);

        RecordCounter := SalesLine.Count + ProdOrderComp.Count + ServLine.Count + JobPlanningLine.Count;
        OnBeforeOpenPlanningWindow(RecordCounter, ProdOrderComp);
        OpenWindow(ProgressMsg, RecordCounter);

        GetUnplannedSalesLine(Rec);
        GetUnplannedProdOrderComp(Rec);
        GetUnplannedAsmLine(Rec);
        GetUnplannedServLine(Rec);
        GetUnplannedJobPlanningLine(Rec);

        OnAfterGetUnplanned(Rec);

        OnBeforeClosePlanningWindow(Rec, Window, NoOfRecords);
        Window.Close();

        Reset();
        SetCurrentKey("Demand Date", Level);
        SetRange(Level, 1);
        OpenWindow(ProgressMsg, Count);
        CalcNeededDemands(Rec);
        Window.Close();
    end;

    var
        SalesLine: Record "Sales Line";
        ProdOrderComp: Record "Prod. Order Component";
        ProgressMsg: Label 'Determining Unplanned Orders @1@@@@@@@';
        ServLine: Record "Service Line";
        JobPlanningLine: Record "Job Planning Line";
        AsmLine: Record "Assembly Line";
        Window: Dialog;
        WindowUpdateDateTime: DateTime;
        NoOfRecords: Integer;
        i: Integer;
        DemandQtyBase: Decimal;
        IncludeMetDemandForSpecificSalesOrderNo: Code[20];
        RecordCounter: Integer;
        FilterStringBuilderLbl: Label '%1|', Locked = true;
        SendTraceCategoryLbl: Label 'Planning', Locked = true;
        FilterTooLongMsg: Label 'Item filter is too long.', Locked = true;

    procedure SetIncludeMetDemandForSpecificSalesOrderNo(SalesOrderNo: Code[20])
    begin
        IncludeMetDemandForSpecificSalesOrderNo := SalesOrderNo;
    end;

    local procedure SetFilterToSpecificSalesOrder()
    var
        SalesOrderLine: Record "Sales Line";
        TempItem: Record Item temporary;
        Item: Record Item;
        TypeHelper: Codeunit "Type Helper";
        SelectionFilterMgt: Codeunit SelectionFilterManagement;
        ItemFilter: Text;
    begin
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        AsmLine.SetRange(Type, AsmLine.Type::Item);
        JobPlanningLine.SetRange(Type, JobPlanningLine.Type::Item);

        SalesOrderLine.SetRange("Document No.", IncludeMetDemandForSpecificSalesOrderNo);
        SalesOrderLine.SetRange("Document Type", SalesOrderLine."Document Type"::Order);
        SalesOrderLine.SetRange(Type, SalesOrderLine.Type::Item);

        if SalesOrderLine.FindSet() then begin
            repeat
                // Find all the items needed to be planned and add it to a temp item bufffer
                if not TempItem.Get(SalesOrderLine."No.") then
                    if Item.Get(SalesOrderLine."No.") then begin
                        TempItem := Item;
                        TempItem.Insert();
                    end;
            until SalesOrderLine.Next() = 0;

            if TempItem.Count() >= (TypeHelper.GetMaxNumberOfParametersInSQLQuery() - 100) then
                exit;

            // Build a filter string from the temporary item buffer
            if not TempItem.FindSet() then
                exit;

            repeat
                if (StrLen(ItemFilter) + StrLen(TempItem."No.") + 1) > MaxStrLen(ItemFilter) then begin
                    Session.LogMessage('0000CG7', FilterTooLongMsg, Verbosity::Warning, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', SendTraceCategoryLbl);
                    exit;
                end;

                ItemFilter += StrSubstNo(FilterStringBuilderLbl, SelectionFilterMgt.AddQuotes(TempItem."No."));
            Until TempItem.Next() = 0;

            ItemFilter := CopyStr(ItemFilter, 1, StrLen(ItemFilter) - 1);

            SalesLine.SetFilter("No.", ItemFilter);
            ProdOrderComp.SetFilter("Item No.", ItemFilter);
            AsmLine.SetFilter("No.", ItemFilter);
            JobPlanningLine.SetFilter("No.", ItemFilter);
            OnAfterSetFilterToSpecificSalesOrder(ItemFilter)
        end;
    end;

    local procedure GetUnplannedSalesLine(var UnplannedDemand: Record "Unplanned Demand")
    var
        SalesHeader: Record "Sales Header";
        IsHandled: Boolean;
    begin
        OnBeforeGetUnplannedSalesLine(UnplannedDemand, SalesLine);

        with UnplannedDemand do
            if SalesLine.FindSet() then
                repeat
                    UpdateWindow;
                    DemandQtyBase := GetSalesLineNeededQty(SalesLine);
                    OnGetUnplannedSalesLineOnBeforeCheckDemandQtyBase(SalesLine, IsHandled);
                    if not IsHandled then
                        if DemandQtyBase > 0 then begin
                            if not ((SalesLine."Document Type".AsInteger() = "Demand SubType") and
                                    (SalesLine."Document No." = "Demand Order No."))
                            then begin
                                SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
                                InsertUnplannedDemand(
                                UnplannedDemand, "Demand Type"::Sales, SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesHeader.Status.AsInteger());
                                OnGetUnplannedSalesLineOnAfterInsertUnplannedDemand(SalesLine, UnplannedDemand);
                            end;
                            InsertSalesLine(UnplannedDemand);
                        end;
                until SalesLine.Next() = 0;
    end;

    local procedure GetUnplannedProdOrderComp(var UnplannedDemand: Record "Unplanned Demand")
    var
        NeedInsertUnplannedDemand: Boolean;
    begin
        OnBeforeGetUnplannedProdOrderComp(UnplannedDemand, ProdOrderComp);

        with UnplannedDemand do
            if ProdOrderComp.FindSet() then
                repeat
                    UpdateWindow;
                    DemandQtyBase := GetProdOrderCompNeededQty(ProdOrderComp);
                    if DemandQtyBase > 0 then begin
                        NeedInsertUnplannedDemand :=
                            not ((ProdOrderComp.Status.AsInteger() = "Demand SubType") and
                            (ProdOrderComp."Prod. Order No." = "Demand Order No."));
                        OnGetUnplannedProdOrderCompOnAfterCalcNeedInsertUnplannedDemand(UnplannedDemand, ProdOrderComp, NeedInsertUnplannedDemand);
                        if NeedInsertUnplannedDemand then
                            InsertUnplannedDemand(
                                UnplannedDemand, "Demand Type"::Production,
                                ProdOrderComp.Status.AsInteger(), ProdOrderComp."Prod. Order No.", ProdOrderComp.Status.AsInteger());
                        InsertProdOrderCompLine(UnplannedDemand);
                    end;
                until ProdOrderComp.Next() = 0;
    end;

    local procedure GetUnplannedAsmLine(var UnplannedDemand: Record "Unplanned Demand")
    var
        AsmHeader: Record "Assembly Header";
    begin
        OnBeforeGetUnplannedAsmLine(UnplannedDemand, AsmLine);

        with UnplannedDemand do
            if AsmLine.FindSet() then
                repeat
                    UpdateWindow;
                    DemandQtyBase := GetAsmLineNeededQty(AsmLine);
                    if DemandQtyBase > 0 then begin
                        if not ((AsmLine."Document Type".AsInteger() = "Demand SubType") and
                                (AsmLine."Document No." = "Demand Order No."))
                        then begin
                            AsmHeader.Get(AsmLine."Document Type", AsmLine."Document No.");
                            InsertUnplannedDemand(
                              UnplannedDemand, "Demand Type"::Assembly, AsmLine."Document Type".AsInteger(), AsmLine."Document No.", AsmHeader.Status);
                            OnGetUnplannedAsmLineOnAfterInsertUnplannedDemand(UnplannedDemand);
                        end;
                        InsertAsmLine(UnplannedDemand);
                    end;
                until AsmLine.Next() = 0;
    end;

    local procedure GetUnplannedServLine(var UnplannedDemand: Record "Unplanned Demand")
    var
        ServHeader: Record "Service Header";
    begin
        OnBeforeGetUnplannedServLine(UnplannedDemand, ServLine);

        with UnplannedDemand do
            if ServLine.FindSet() then
                repeat
                    UpdateWindow;
                    DemandQtyBase := GetServLineNeededQty(ServLine);
                    if DemandQtyBase > 0 then begin
                        if not ((ServLine."Document Type".AsInteger() = "Demand SubType") and
                                (ServLine."Document No." = "Demand Order No."))
                        then begin
                            ServHeader.Get(ServLine."Document Type", ServLine."Document No.");
                            InsertUnplannedDemand(
                              UnplannedDemand, "Demand Type"::Service, ServLine."Document Type".AsInteger(), ServLine."Document No.", ServHeader.Status.AsInteger());
                            OnGetUnplannedServLineOnAfterInsertUnplannedDemand(UnplannedDemand);
                        end;
                        InsertServLine(UnplannedDemand);
                    end;
                until ServLine.Next() = 0;
    end;

    local procedure GetUnplannedJobPlanningLine(var UnplannedDemand: Record "Unplanned Demand")
    var
        Job: Record Job;
    begin
        OnBeforeGetUnplannedJobPlanningLine(UnplannedDemand, JobPlanningLine);

        with UnplannedDemand do
            if JobPlanningLine.FindSet() then
                repeat
                    UpdateWindow;
                    DemandQtyBase := GetJobPlanningLineNeededQty(JobPlanningLine);
                    if DemandQtyBase > 0 then begin
                        if not ((JobPlanningLine.Status = "Demand SubType") and
                                (JobPlanningLine."Job No." = "Demand Order No."))
                        then begin
                            Job.Get(JobPlanningLine."Job No.");
                            InsertUnplannedDemand(
                              UnplannedDemand, "Demand Type"::Job, JobPlanningLine.Status, JobPlanningLine."Job No.", Job.Status.AsInteger());
                            OnGetUnplannedJobPlanningLineOnAfterInsertUnplannedDemand(UnplannedDemand);
                        end;
                        InsertJobPlanningLine(UnplannedDemand);
                    end;
                until JobPlanningLine.Next() = 0;
    end;

    local procedure GetSalesLineNeededQty(SalesLine: Record "Sales Line") NeededQty: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetSalesLineNeededQty(SalesLine, NeededQty, IsHandled);
        if IsHandled then
            exit(NeededQty);

        with SalesLine do begin
            if Planned or ("No." = '') or (Type <> Type::Item) or "Drop Shipment" or "Special Order"
            then
                exit(0);

            CalcFields("Reserved Qty. (Base)");
            exit(-SignedXX("Outstanding Qty. (Base)" - "Reserved Qty. (Base)"));
        end;
    end;

    local procedure GetProdOrderCompNeededQty(ProdOrderComp: Record "Prod. Order Component"): Decimal
    var
        NeededQty: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetProdOrderCompNeededQty(ProdOrderComp, NeededQty, IsHandled);
        if IsHandled then
            exit(NeededQty);

        with ProdOrderComp do begin
            if "Item No." = '' then
                exit(0);

            CalcFields("Reserved Qty. (Base)");
            exit("Remaining Qty. (Base)" - "Reserved Qty. (Base)");
        end;
    end;

    local procedure GetAsmLineNeededQty(AsmLine: Record "Assembly Line"): Decimal
    begin
        with AsmLine do begin
            if ("No." = '') or (Type <> Type::Item) then
                exit(0);

            CalcFields("Reserved Qty. (Base)");
            exit(-SignedXX("Remaining Quantity (Base)" - "Reserved Qty. (Base)"));
        end;
    end;

    local procedure GetServLineNeededQty(ServLine: Record "Service Line"): Decimal
    begin
        with ServLine do begin
            if Planned or ("No." = '') or (Type <> Type::Item) then
                exit(0);

            CalcFields("Reserved Qty. (Base)");
            exit(-SignedXX("Outstanding Qty. (Base)" - "Reserved Qty. (Base)"));
        end;
    end;

    local procedure GetJobPlanningLineNeededQty(JobPlanningLine: Record "Job Planning Line"): Decimal
    begin
        with JobPlanningLine do begin
            if Planned or ("No." = '') or (Type <> Type::Item) or IsNonInventoriableItem then
                exit(0);

            CalcFields("Reserved Qty. (Base)");
            exit("Remaining Qty. (Base)" - "Reserved Qty. (Base)");
        end;
    end;

    local procedure InsertSalesLine(var UnplannedDemand: Record "Unplanned Demand")
    var
        UnplannedDemand2: Record "Unplanned Demand";
    begin
        with UnplannedDemand do begin
            UnplannedDemand2.Copy(UnplannedDemand);
            InitRecord(
              SalesLine."Line No.", 0, SalesLine."No.", SalesLine.Description, SalesLine."Variant Code", SalesLine."Location Code",
              SalesLine."Bin Code", SalesLine."Unit of Measure Code", SalesLine."Qty. per Unit of Measure",
              DemandQtyBase, SalesLine."Shipment Date");
            OnInsertSalesLineOnAfterInitRecord(UnplannedDemand, SalesLine);
            Reserve := SalesLine.Reserve = SalesLine.Reserve::Always;
            "Special Order" := SalesLine."Special Order";
            "Purchasing Code" := SalesLine."Purchasing Code";
            OnInsertSalesLineOnBeforeInsert(UnplannedDemand, SalesLine);
            Insert;
            Copy(UnplannedDemand2);
        end;
    end;

    local procedure InsertProdOrderCompLine(var UnplannedDemand: Record "Unplanned Demand")
    var
        UnplannedDemand2: Record "Unplanned Demand";
        Item: Record Item;
    begin
        with UnplannedDemand do begin
            UnplannedDemand2.Copy(UnplannedDemand);
            InitRecord(
              ProdOrderComp."Prod. Order Line No.", ProdOrderComp."Line No.", ProdOrderComp."Item No.", ProdOrderComp.Description,
              ProdOrderComp."Variant Code", ProdOrderComp."Location Code", ProdOrderComp."Bin Code", ProdOrderComp."Unit of Measure Code",
              ProdOrderComp."Qty. per Unit of Measure", DemandQtyBase, ProdOrderComp."Due Date");
            Item.Get("Item No.");
            Reserve :=
              (Item.Reserve = Item.Reserve::Always) and
              not (("Demand Type" = "Demand Type"::Production) and
                   ("Demand SubType" = ProdOrderComp.Status::Planned.AsInteger()));
            OnInsertProdOrderCompLineOnBeforeInsert(UnplannedDemand, ProdOrderComp);
            Insert;
            Copy(UnplannedDemand2);
        end;
    end;

    local procedure InsertAsmLine(var UnplannedDemand: Record "Unplanned Demand")
    var
        UnplannedDemand2: Record "Unplanned Demand";
    begin
        with UnplannedDemand do begin
            UnplannedDemand2.Copy(UnplannedDemand);
            InitRecord(
              AsmLine."Line No.", 0, AsmLine."No.", AsmLine.Description, AsmLine."Variant Code", AsmLine."Location Code",
              AsmLine."Bin Code", AsmLine."Unit of Measure Code", AsmLine."Qty. per Unit of Measure",
              DemandQtyBase, AsmLine."Due Date");
            Reserve := AsmLine.Reserve = AsmLine.Reserve::Always;
            OnInsertAsmLineOnBeforeInsert(UnplannedDemand, AsmLine);
            Insert;
            Copy(UnplannedDemand2);
        end;
    end;

    local procedure InsertServLine(var UnplannedDemand: Record "Unplanned Demand")
    var
        UnplannedDemand2: Record "Unplanned Demand";
    begin
        with UnplannedDemand do begin
            UnplannedDemand2.Copy(UnplannedDemand);
            InitRecord(
              ServLine."Line No.", 0, ServLine."No.", ServLine.Description, ServLine."Variant Code", ServLine."Location Code",
              ServLine."Bin Code", ServLine."Unit of Measure Code", ServLine."Qty. per Unit of Measure",
              DemandQtyBase, ServLine."Needed by Date");
            Reserve := ServLine.Reserve = ServLine.Reserve::Always;
            OnInsertServLineOnBeforeInsert(UnplannedDemand, ServLine);
            Insert;
            Copy(UnplannedDemand2);
        end;
    end;

    local procedure InsertJobPlanningLine(var UnplannedDemand: Record "Unplanned Demand")
    var
        UnplannedDemand2: Record "Unplanned Demand";
    begin
        with UnplannedDemand do begin
            UnplannedDemand2.Copy(UnplannedDemand);
            InitRecord(
              JobPlanningLine."Job Contract Entry No.", 0, JobPlanningLine."No.", JobPlanningLine.Description, JobPlanningLine."Variant Code",
              JobPlanningLine."Location Code", JobPlanningLine."Bin Code", JobPlanningLine."Unit of Measure Code",
              JobPlanningLine."Qty. per Unit of Measure", DemandQtyBase, JobPlanningLine."Planning Date");
            Reserve := JobPlanningLine.Reserve = JobPlanningLine.Reserve::Always;
            OnInsertJobPlanningLineOnBeforeInsert(UnplannedDemand, JobPlanningLine);
            Insert;
            Copy(UnplannedDemand2);
        end;
    end;

    local procedure InsertUnplannedDemand(var UnplannedDemand: Record "Unplanned Demand"; DemandType: Enum "Unplanned Demand Type"; DemandSubtype: Integer; DemandOrderNo: Code[20]; DemandStatus: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertUnplannedDemand(UnplannedDemand, DemandType, DemandSubtype, DemandOrderNo, DemandStatus, IsHandled);
        if IsHandled then
            exit;

        with UnplannedDemand do begin
            Init;
            "Demand Type" := DemandType;
            "Demand SubType" := DemandSubtype;
            Validate("Demand Order No.", DemandOrderNo);
            Status := DemandStatus;
            Level := 0;
            Insert;
        end;
    end;

    local procedure CalcNeededDemands(var UnplannedDemand: Record "Unplanned Demand")
    var
        TempUnplannedDemand: Record "Unplanned Demand" temporary;
        OrderPlanningMgt: Codeunit "Order Planning Mgt.";
        HeaderExists: Boolean;
        ForceIncludeDemand: Boolean;
    begin
        with TempUnplannedDemand do begin
            UnplannedDemand.Reset();
            MoveUnplannedDemand(UnplannedDemand, TempUnplannedDemand);

            SetCurrentKey("Demand Date", Level);
            SetRange(Level, 1);
            while Find('-') do begin
                HeaderExists := false;
                repeat
                    UpdateWindow;
                    UnplannedDemand := TempUnplannedDemand;
                    if UnplannedDemand."Special Order" then
                        UnplannedDemand."Needed Qty. (Base)" := "Quantity (Base)"
                    else
                        UnplannedDemand."Needed Qty. (Base)" :=
                          OrderPlanningMgt.CalcNeededQty(
                            OrderPlanningMgt.CalcATPQty("Item No.", "Variant Code", "Location Code", "Demand Date") +
                            CalcDemand(TempUnplannedDemand, false) + CalcDemand(UnplannedDemand, true),
                            "Quantity (Base)");

                    ForceIncludeDemand :=
                      (UnplannedDemand."Demand Order No." = IncludeMetDemandForSpecificSalesOrderNo) and
                      (UnplannedDemand."Demand Type" = UnplannedDemand."Demand Type"::Sales) and
                      (UnplannedDemand."Demand SubType" = SalesLine."Document Type"::Order.AsInteger());

                    OnCalcNeededDemandsOnAfterCalcForceIncludeDemand(UnplannedDemand, ForceIncludeDemand);
                    if ForceIncludeDemand or (UnplannedDemand."Needed Qty. (Base)" > 0)
                    then begin
                        UnplannedDemand.Insert();
                        if not HeaderExists then begin
                            InsertUnplannedDemandHeader(TempUnplannedDemand, UnplannedDemand);
                            HeaderExists := true;
                            SetRange("Demand Type", "Demand Type");
                            SetRange("Demand SubType", "Demand SubType");
                            SetRange("Demand Order No.", "Demand Order No.");
                        end;
                    end;
                    Delete;
                until Next() = 0;
                SetRange("Demand Type");
                SetRange("Demand SubType");
                SetRange("Demand Order No.");
            end;
        end;
    end;

    local procedure CalcDemand(var UnplannedDemand: Record "Unplanned Demand"; Planned: Boolean) DemandQty: Decimal
    var
        UnplannedDemand2: Record "Unplanned Demand";
    begin
        with UnplannedDemand do begin
            UnplannedDemand2.Copy(UnplannedDemand);
            Reset;
            SetCurrentKey("Item No.", "Variant Code", "Location Code", "Demand Date");
            SetRange("Item No.", "Item No.");
            SetRange("Variant Code", "Variant Code");
            SetRange("Location Code", "Location Code");

            if Planned then begin
                SetRange("Demand Date", 0D, "Demand Date");
                CalcSums("Needed Qty. (Base)");
                DemandQty := "Needed Qty. (Base)";
            end else begin
                SetRange("Demand Date", "Demand Date");
                CalcSums("Quantity (Base)");
                DemandQty := "Quantity (Base)";
            end;
            Copy(UnplannedDemand2);
        end;
    end;

    local procedure MoveUnplannedDemand(var FromUnplannedDemand: Record "Unplanned Demand"; var ToUnplannedDemand: Record "Unplanned Demand")
    begin
        with FromUnplannedDemand do begin
            ToUnplannedDemand.DeleteAll();
            if Find('-') then
                repeat
                    ToUnplannedDemand := FromUnplannedDemand;
                    ToUnplannedDemand.Insert();
                    Delete;
                until Next() = 0;
        end;
    end;

    local procedure InsertUnplannedDemandHeader(var FromUnplannedDemand: Record "Unplanned Demand"; var ToUnplannedDemand: Record "Unplanned Demand")
    var
        UnplannedDemand2: Record "Unplanned Demand";
    begin
        UnplannedDemand2.Copy(FromUnplannedDemand);

        with FromUnplannedDemand do begin
            Reset;
            SetRange("Demand Type", "Demand Type");
            SetRange("Demand SubType", "Demand SubType");
            SetRange("Demand Order No.", "Demand Order No.");
            SetRange(Level, 0);
            Find('-');
            ToUnplannedDemand := FromUnplannedDemand;
            ToUnplannedDemand."Demand Date" := UnplannedDemand2."Demand Date";
            ToUnplannedDemand.Insert();
        end;

        FromUnplannedDemand.Copy(UnplannedDemand2);
    end;

    local procedure OpenWindow(DisplayText: Text[250]; NoOfRecords2: Integer)
    begin
        i := 0;
        NoOfRecords := NoOfRecords2;
        WindowUpdateDateTime := CurrentDateTime;
        Window.Open(DisplayText);
    end;

    local procedure UpdateWindow()
    begin
        i := i + 1;
        if CurrentDateTime - WindowUpdateDateTime >= 300 then begin
            WindowUpdateDateTime := CurrentDateTime;
            Window.Update(1, Round(i / NoOfRecords * 10000, 1));
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetUnplanned(var UnplannedDemand: Record "Unplanned Demand");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSalesLineNeededQty(SalesLine: Record "Sales Line"; var NeededQty: Decimal; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenPlanningWindow(var RecordCounter: Integer; var ProdOrderComp: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeClosePlanningWindow(UnplannedDemand: Record "Unplanned Demand"; var Window: Dialog; NoOfRecords: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetUnplannedSalesLine(var UnplannedDemand: Record "Unplanned Demand"; var SalesLine: Record "Sales Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetUnplannedProdOrderComp(var UnplannedDemand: Record "Unplanned Demand"; var ProdOrderComponent: Record "Prod. Order Component");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetUnplannedAsmLine(var UnplannedDemand: Record "Unplanned Demand"; var AssemblyLine: Record "Assembly Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetUnplannedServLine(var UnplannedDemand: Record "Unplanned Demand"; var ServiceLine: Record "Service Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetUnplannedJobPlanningLine(var UnplannedDemand: Record "Unplanned Demand"; var JobPlanningLine: Record "Job Planning Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertUnplannedDemand(var UnplannedDemand: Record "Unplanned Demand"; DemandType: Enum "Unplanned Demand Type"; DemandSubtype: Integer; DemandOrderNo: Code[20]; DemandStatus: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetProdOrderCompNeededQty(ProdOrderComponent: Record "Prod. Order Component"; var NeededQty: Decimal; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcNeededDemandsOnAfterCalcForceIncludeDemand(var UnplannedDemand: Record "Unplanned Demand"; var ForceIncludeDemand: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetUnplannedAsmLineOnAfterInsertUnplannedDemand(var UnplannedDemand: Record "Unplanned Demand")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetUnplannedSalesLineOnBeforeCheckDemandQtyBase(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetUnplannedJobPlanningLineOnAfterInsertUnplannedDemand(var UnplannedDemand: Record "Unplanned Demand")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetUnplannedServLineOnAfterInsertUnplannedDemand(var UnplannedDemand: Record "Unplanned Demand")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetUnplannedSalesLineOnAfterInsertUnplannedDemand(var SalesLine: Record "Sales Line"; var UnplannedDemand: Record "Unplanned Demand")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetUnplannedProdOrderCompOnAfterCalcNeedInsertUnplannedDemand(var UnplannedDemand: Record "Unplanned Demand"; var ProdOrderComp: Record "Prod. Order Component"; var NeedInsertUnplannedDemand: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetFilterToSpecificSalesOrder(ItemFilter: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertAsmLineOnBeforeInsert(var UnplannedDemand: Record "Unplanned Demand"; AssemblyLine: Record "Assembly Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertProdOrderCompLineOnBeforeInsert(var UnplannedDemand: Record "Unplanned Demand"; ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertSalesLineOnBeforeInsert(var UnplannedDemand: Record "Unplanned Demand"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertServLineOnBeforeInsert(var UnplannedDemand: Record "Unplanned Demand"; ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertJobPlanningLineOnBeforeInsert(var UnplannedDemand: Record "Unplanned Demand"; JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertSalesLineOnAfterInitRecord(var UnplannedDemand: Record "Unplanned Demand"; var SalesLine: Record "Sales Line")
    begin
    end;
}

