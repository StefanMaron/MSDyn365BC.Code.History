codeunit 5520 "Get Unplanned Demand"
{
    Permissions = TableData "Production Order" = r,
                  TableData "Prod. Order Component" = r,
                  TableData "Prod. Order Capacity Need" = r,
                  TableData "Service Header" = r;
    TableNo = "Unplanned Demand";

    trigger OnRun()
    begin
        DeleteAll();
        SalesLine.SetFilter("Document Type", '%1|%2', SalesLine."Document Type"::Order, SalesLine."Document Type"::"Return Order");
        ProdOrderComp.SetFilter(
          Status, '%1|%2|%3', ProdOrderComp.Status::Planned, ProdOrderComp.Status::"Firm Planned", ProdOrderComp.Status::Released);
        ServLine.SetRange("Document Type", ServLine."Document Type"::Order);
        AsmLine.SetRange("Document Type", AsmLine."Document Type"::Order);
        JobPlanningLine.SetRange(Status, JobPlanningLine.Status::Order);

        RecordCounter := SalesLine.Count + ProdOrderComp.Count + ServLine.Count + JobPlanningLine.Count;
        OnBeforeOpenPlanningWindow(RecordCounter);
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

    procedure SetIncludeMetDemandForSpecificSalesOrderNo(SalesOrderNo: Code[20])
    begin
        IncludeMetDemandForSpecificSalesOrderNo := SalesOrderNo;
    end;

    local procedure GetUnplannedSalesLine(var UnplannedDemand: Record "Unplanned Demand")
    var
        SalesHeader: Record "Sales Header";
    begin
        with UnplannedDemand do
            if SalesLine.Find('-') then
                repeat
                    UpdateWindow;
                    DemandQtyBase := GetSalesLineNeededQty(SalesLine);
                    if DemandQtyBase > 0 then begin
                        if not ((SalesLine."Document Type" = "Demand SubType") and
                                (SalesLine."Document No." = "Demand Order No."))
                        then begin
                            SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
                            InsertUnplannedDemand(
                              UnplannedDemand, "Demand Type"::Sales, SalesLine."Document Type", SalesLine."Document No.", SalesHeader.Status);
                        end;
                        InsertSalesLine(UnplannedDemand);
                    end;
                until SalesLine.Next = 0;
    end;

    local procedure GetUnplannedProdOrderComp(var UnplannedDemand: Record "Unplanned Demand")
    begin
        with UnplannedDemand do
            if ProdOrderComp.Find('-') then
                repeat
                    UpdateWindow;
                    DemandQtyBase := GetProdOrderCompNeededQty(ProdOrderComp);
                    if DemandQtyBase > 0 then begin
                        if not ((ProdOrderComp.Status = "Demand SubType") and
                                (ProdOrderComp."Prod. Order No." = "Demand Order No."))
                        then
                            InsertUnplannedDemand(
                              UnplannedDemand, "Demand Type"::Production, ProdOrderComp.Status, ProdOrderComp."Prod. Order No.", ProdOrderComp.Status);
                        InsertProdOrderCompLine(UnplannedDemand);
                    end;
                until ProdOrderComp.Next = 0;
    end;

    local procedure GetUnplannedAsmLine(var UnplannedDemand: Record "Unplanned Demand")
    var
        AsmHeader: Record "Assembly Header";
    begin
        with UnplannedDemand do
            if AsmLine.Find('-') then
                repeat
                    UpdateWindow;
                    DemandQtyBase := GetAsmLineNeededQty(AsmLine);
                    if DemandQtyBase > 0 then begin
                        if not ((AsmLine."Document Type" = "Demand SubType") and
                                (AsmLine."Document No." = "Demand Order No."))
                        then begin
                            AsmHeader.Get(AsmLine."Document Type", AsmLine."Document No.");
                            InsertUnplannedDemand(
                              UnplannedDemand, "Demand Type"::Assembly, AsmLine."Document Type", AsmLine."Document No.", AsmHeader.Status);
                        end;
                        InsertAsmLine(UnplannedDemand);
                    end;
                until AsmLine.Next = 0;
    end;

    local procedure GetUnplannedServLine(var UnplannedDemand: Record "Unplanned Demand")
    var
        ServHeader: Record "Service Header";
    begin
        with UnplannedDemand do
            if ServLine.Find('-') then
                repeat
                    UpdateWindow;
                    DemandQtyBase := GetServLineNeededQty(ServLine);
                    if DemandQtyBase > 0 then begin
                        if not ((ServLine."Document Type" = "Demand SubType") and
                                (ServLine."Document No." = "Demand Order No."))
                        then begin
                            ServHeader.Get(ServLine."Document Type", ServLine."Document No.");
                            InsertUnplannedDemand(
                              UnplannedDemand, "Demand Type"::Service, ServLine."Document Type", ServLine."Document No.", ServHeader.Status);
                        end;
                        InsertServLine(UnplannedDemand);
                    end;
                until ServLine.Next = 0;
    end;

    local procedure GetUnplannedJobPlanningLine(var UnplannedDemand: Record "Unplanned Demand")
    var
        Job: Record Job;
    begin
        with UnplannedDemand do
            if JobPlanningLine.Find('-') then
                repeat
                    UpdateWindow;
                    DemandQtyBase := GetJobPlanningLineNeededQty(JobPlanningLine);
                    if DemandQtyBase > 0 then begin
                        if not ((JobPlanningLine.Status = "Demand SubType") and
                                (JobPlanningLine."Job No." = "Demand Order No."))
                        then begin
                            Job.Get(JobPlanningLine."Job No.");
                            InsertUnplannedDemand(
                              UnplannedDemand, "Demand Type"::Job, JobPlanningLine.Status, JobPlanningLine."Job No.", Job.Status);
                        end;
                        InsertJobPlanningLine(UnplannedDemand);
                    end;
                until JobPlanningLine.Next = 0;
    end;

    local procedure GetSalesLineNeededQty(SalesLine: Record "Sales Line") NeededQty: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetSalesLineNeededQty(SalesLine, NeededQty, IsHandled);

        with SalesLine do begin
            if Planned or ("No." = '') or (Type <> Type::Item) or "Drop Shipment" or "Special Order"
            then
                exit(0);

            CalcFields("Reserved Qty. (Base)");
            exit(-SignedXX("Outstanding Qty. (Base)" - "Reserved Qty. (Base)"));
        end;
    end;

    local procedure GetProdOrderCompNeededQty(ProdOrderComp: Record "Prod. Order Component"): Decimal
    begin
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
            Reserve := SalesLine.Reserve = SalesLine.Reserve::Always;
            "Special Order" := SalesLine."Special Order";
            "Purchasing Code" := SalesLine."Purchasing Code";
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
                   ("Demand SubType" = ProdOrderComp.Status::Planned));
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
            Insert;
            Copy(UnplannedDemand2);
        end;
    end;

    local procedure InsertUnplannedDemand(var UnplannedDemand: Record "Unplanned Demand"; DemandType: Integer; DemandSubtype: Integer; DemandOrderNo: Code[20]; DemandStatus: Integer)
    begin
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
                      (UnplannedDemand."Demand SubType" = SalesLine."Document Type"::Order);

                    if ForceIncludeDemand or
                       (IncludeMetDemandForSpecificSalesOrderNo = '') and (UnplannedDemand."Needed Qty. (Base)" > 0)
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
                until Next = 0;
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
                until Next = 0;
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
    local procedure OnBeforeOpenPlanningWindow(var RecordCounter: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeClosePlanningWindow(UnplannedDemand: Record "Unplanned Demand"; var Window: Dialog; NoOfRecords: Integer)
    begin
    end;
}

