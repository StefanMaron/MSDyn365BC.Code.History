codeunit 5870 "Calculate BOM Tree"
{

    trigger OnRun()
    begin
    end;

    var
        TempItemAvailByDate: Record "Item Availability by Date" temporary;
        TempMemoizedResult: Record "Memoized Result" temporary;
        ItemFilter: Record Item;
        TempItem: Record Item temporary;
        AvailableToPromise: Codeunit "Available to Promise";
        UOMMgt: Codeunit "Unit of Measure Management";
        Window: Dialog;
        WindowUpdateDateTime: DateTime;
        LocationSpecific: Boolean;
        EntryNo: Integer;
        ZeroDF: DateFormula;
        AvailToUse: Option UpdatedQtyOnItemAvail,QtyOnItemAvail,QtyAvail;
        MarkBottleneck: Boolean;
        Text000: Label 'Generating Tree @1@@@@@@@';
        ShowTotalAvailability: Boolean;
        TreeType: Option " ",Availability,Cost;

    local procedure OpenWindow()
    begin
        Window.Open(Text000);
        WindowUpdateDateTime := CurrentDateTime;
    end;

    local procedure UpdateWindow(ProgressValue: Integer)
    begin
        if CurrentDateTime - WindowUpdateDateTime >= 300 then begin
            WindowUpdateDateTime := CurrentDateTime;
            Window.Update(1, ProgressValue);
        end;
    end;

    local procedure InitVars()
    begin
        TempItemAvailByDate.Reset();
        TempItemAvailByDate.DeleteAll();
        TempMemoizedResult.Reset();
        TempMemoizedResult.DeleteAll();
        TempItem.Reset();
        TempItem.DeleteAll();
    end;

    local procedure InitBOMBuffer(var BOMBuffer: Record "BOM Buffer")
    begin
        BOMBuffer.Reset();
        BOMBuffer.DeleteAll();
    end;

    local procedure InitTreeType(NewTreeType: Option)
    begin
        TreeType := NewTreeType;
    end;

    procedure GenerateTreeForItems(var ParentItem: Record Item; var BOMBuffer: Record "BOM Buffer"; TreeType: Option " ",Availability,Cost)
    var
        i: Integer;
        NoOfRecords: Integer;
        DemandDate: Date;
    begin
        OpenWindow;

        InitBOMBuffer(BOMBuffer);
        InitTreeType(TreeType);
        ItemFilter.Copy(ParentItem);

        with ParentItem do begin
            if GetFilter("Date Filter") <> '' then
                DemandDate := GetRangeMax("Date Filter")
            else
                DemandDate := 99981231D;
            NoOfRecords := Count;
            if FindSet then
                repeat
                    i += 1;
                    UpdateWindow(Round(i / NoOfRecords * 10000, 1));
                    GenerateTreeForItemLocal(ParentItem, BOMBuffer, DemandDate, TreeType);
                until Next = 0;
        end;

        ParentItem.Copy(ItemFilter);

        Window.Close;
    end;

    procedure GenerateTreeForItem(var ParentItem: Record Item; var BOMBuffer: Record "BOM Buffer"; DemandDate: Date; TreeType: Option)
    begin
        with ParentItem do begin
            ItemFilter.Copy(ParentItem);

            Get("No.");
            InitBOMBuffer(BOMBuffer);
            InitTreeType(TreeType);
            GenerateTreeForItemLocal(ParentItem, BOMBuffer, DemandDate, TreeType);
            Copy(ItemFilter);
        end;
    end;

    local procedure GenerateTreeForItemLocal(var ParentItem: Record Item; var BOMBuffer: Record "BOM Buffer"; DemandDate: Date; TreeType: Option)
    var
        BOMComp: Record "BOM Component";
        ProdBOMLine: Record "Production BOM Line";
        IsHandled: Boolean;
    begin
        with ParentItem do begin
            InitVars;

            BOMComp.SetRange(Type, BOMComp.Type::Item);
            BOMComp.SetRange("No.", "No.");

            ProdBOMLine.SetRange(Type, ProdBOMLine.Type::Item);
            ProdBOMLine.SetRange("No.", "No.");

            if HasBOM or ("Routing No." <> '') then begin
                IsHandled := false;
                OnBeforeFilterBOMBuffer(ParentItem, BOMBuffer, DemandDate, TreeType, IsHandled);
                if not IsHandled then begin
                    BOMBuffer.SetLocationVariantFiltersFrom(ItemFilter);
                    BOMBuffer.TransferFromItem(EntryNo, ParentItem, DemandDate);
                    GenerateItemSubTree("No.", BOMBuffer);
                    CalculateTreeType(BOMBuffer, ShowTotalAvailability, TreeType);
                    OnAfterFilterBOMBuffer(ParentItem, BOMBuffer, DemandDate, TreeType);
                end;
            end;
        end;
    end;

    procedure GenerateTreeForAsm(AsmHeader: Record "Assembly Header"; var BOMBuffer: Record "BOM Buffer"; TreeType: Option)
    begin
        InitBOMBuffer(BOMBuffer);
        InitTreeType(TreeType);
        InitVars;

        LocationSpecific := true;

        BOMBuffer.SetLocationVariantFiltersFrom(ItemFilter);
        BOMBuffer.TransferFromAsmHeader(EntryNo, AsmHeader);

        if not GenerateAsmHeaderSubTree(AsmHeader, BOMBuffer) then
            GenerateItemSubTree(AsmHeader."Item No.", BOMBuffer);

        CalculateTreeType(BOMBuffer, ShowTotalAvailability, TreeType);
    end;

    procedure GenerateTreeForProdLine(ProdOrderLine: Record "Prod. Order Line"; var BOMBuffer: Record "BOM Buffer"; TreeType: Option)
    begin
        InitBOMBuffer(BOMBuffer);
        InitTreeType(TreeType);
        InitVars;

        LocationSpecific := true;
        BOMBuffer.SetLocationVariantFiltersFrom(ItemFilter);
        BOMBuffer.TransferFromProdOrderLine(EntryNo, ProdOrderLine);
        if not GenerateProdOrderLineSubTree(ProdOrderLine, BOMBuffer) then
            GenerateItemSubTree(ProdOrderLine."Item No.", BOMBuffer);

        CalculateTreeType(BOMBuffer, ShowTotalAvailability, TreeType);
    end;

    local procedure CalculateTreeType(var BOMBuffer: Record "BOM Buffer"; ShowTotalAvailability: Boolean; TreeType: Option " ",Availability,Cost)
    begin
        case TreeType of
            TreeType::Availability:
                UpdateAvailability(BOMBuffer, ShowTotalAvailability);
            TreeType::Cost:
                UpdateCost(BOMBuffer);
        end;
    end;

    local procedure GenerateItemSubTree(ItemNo: Code[20]; var BOMBuffer: Record "BOM Buffer"): Boolean
    var
        ParentItem: Record Item;
    begin
        with BOMBuffer do begin
            ParentItem.Get(ItemNo);
            if TempItem.Get(ItemNo) then begin
                "Is Leaf" := false;
                Modify(true);
                exit(false);
            end;
            TempItem := ParentItem;
            TempItem.Insert();

            if ParentItem."Replenishment System" = ParentItem."Replenishment System"::"Prod. Order" then begin
                "Is Leaf" := not GenerateProdCompSubTree(ParentItem, BOMBuffer);
                if "Is Leaf" then
                    "Is Leaf" := not GenerateBOMCompSubTree(ParentItem, BOMBuffer);
            end else begin
                "Is Leaf" := not GenerateBOMCompSubTree(ParentItem, BOMBuffer);
                if "Is Leaf" then
                    "Is Leaf" := not GenerateProdCompSubTree(ParentItem, BOMBuffer);
            end;
            Modify(true);

            TempItem.Get(ItemNo);
            TempItem.Delete();
            exit(not "Is Leaf");
        end;
    end;

    local procedure GenerateBOMCompSubTree(ParentItem: Record Item; var BOMBuffer: Record "BOM Buffer"): Boolean
    var
        BOMComp: Record "BOM Component";
        ParentBOMBuffer: Record "BOM Buffer";
        UOMMgt: Codeunit "Unit of Measure Management";
    begin
        ParentBOMBuffer := BOMBuffer;
        with BOMComp do begin
            SetRange("Parent Item No.", ParentItem."No.");
            if FindSet then begin
                if ParentItem."Replenishment System" <> ParentItem."Replenishment System"::Assembly then
                    exit(true);
                repeat
                    if ("No." <> '') and ((Type = Type::Item) or (TreeType in [TreeType::" ", TreeType::Cost])) then begin
                        BOMBuffer.SetLocationVariantFiltersFrom(ItemFilter);
                        BOMBuffer.TransferFromBOMComp(
                          EntryNo, BOMComp, ParentBOMBuffer.Indentation + 1,
                          Round(
                            ParentBOMBuffer."Qty. per Top Item" *
                            UOMMgt.GetQtyPerUnitOfMeasure(ParentItem, ParentBOMBuffer."Unit of Measure Code"), UOMMgt.QtyRndPrecision),
                          Round(
                            ParentBOMBuffer."Scrap Qty. per Top Item" *
                            UOMMgt.GetQtyPerUnitOfMeasure(ParentItem, ParentBOMBuffer."Unit of Measure Code"), UOMMgt.QtyRndPrecision),
                          CalcCompDueDate(ParentBOMBuffer."Needed by Date", ParentItem, "Lead-Time Offset"),
                          ParentBOMBuffer."Location Code");
                        if Type = Type::Item then
                            GenerateItemSubTree("No.", BOMBuffer);
                    end;
                until Next = 0;
                BOMBuffer := ParentBOMBuffer;

                exit(true);
            end;
        end;
    end;

    local procedure GenerateProdCompSubTree(ParentItem: Record Item; var BOMBuffer: Record "BOM Buffer") FoundSubTree: Boolean
    var
        CopyOfParentItem: Record Item;
        ProdBOMLine: Record "Production BOM Line";
        RoutingLine: Record "Routing Line";
        ParentBOMBuffer: Record "BOM Buffer";
        UOMMgt: Codeunit "Unit of Measure Management";
        VersionMgt: Codeunit VersionManagement;
        CostCalculationMgt: Codeunit "Cost Calculation Management";
        LotSize: Decimal;
        BomQtyPerUom: Decimal;
        IsHandled: Boolean;
    begin
        ParentBOMBuffer := BOMBuffer;
        if not ProdBOMLine.ReadPermission then
            exit;
        with ProdBOMLine do begin
            SetRange("Production BOM No.", ParentItem."Production BOM No.");
            SetRange("Version Code", VersionMgt.GetBOMVersion(ParentItem."Production BOM No.", WorkDate, true));
            SetFilter("Starting Date", '%1|..%2', 0D, ParentBOMBuffer."Needed by Date");
            SetFilter("Ending Date", '%1|%2..', 0D, ParentBOMBuffer."Needed by Date");
            IsHandled := false;
            OnBeforeFilterByQuantityPer(ProdBOMLine, IsHandled);
            if not IsHandled then
                SetFilter("Quantity per", '>%1', 0);
            if FindSet then begin
                if ParentItem."Replenishment System" <> ParentItem."Replenishment System"::"Prod. Order" then
                    exit(true);
                repeat
                    IsHandled := FALSE;
                    OnBeforeTransferProdBOMLine(BOMBuffer, ProdBOMLine, ParentItem, ParentBOMBuffer, EntryNo, TreeType, IsHandled);
                    if not IsHandled then
                        if "No." <> '' then
                            case Type of
                                Type::Item:
                                    begin
                                        BOMBuffer.SetLocationVariantFiltersFrom(ItemFilter);
                                        BomQtyPerUom :=
                                        GetQtyPerBOMHeaderUnitOfMeasure(
                                            ParentItem, ParentBOMBuffer."Production BOM No.",
                                            VersionMgt.GetBOMVersion(ParentBOMBuffer."Production BOM No.", WorkDate, true));
                                        BOMBuffer.TransferFromProdComp(
                                        EntryNo, ProdBOMLine, ParentBOMBuffer.Indentation + 1,
                                        Round(
                                            ParentBOMBuffer."Qty. per Top Item" *
                                            UOMMgt.GetQtyPerUnitOfMeasure(ParentItem, ParentBOMBuffer."Unit of Measure Code"), UOMMgt.QtyRndPrecision),
                                        Round(
                                            ParentBOMBuffer."Scrap Qty. per Top Item" *
                                            UOMMgt.GetQtyPerUnitOfMeasure(ParentItem, ParentBOMBuffer."Unit of Measure Code"), UOMMgt.QtyRndPrecision),
                                        ParentBOMBuffer."Scrap %",
                                        CalcCompDueDate(ParentBOMBuffer."Needed by Date", ParentItem, "Lead-Time Offset"),
                                        ParentBOMBuffer."Location Code",
                                        ParentItem, BomQtyPerUom);

                                        if ParentItem."Production BOM No." <> ParentBOMBuffer."Production BOM No." then begin
                                            BOMBuffer."Qty. per Parent" := BOMBuffer."Qty. per Parent" * ParentBOMBuffer."Qty. per Parent";
                                            BOMBuffer."Scrap Qty. per Parent" := BOMBuffer."Scrap Qty. per Parent" * ParentBOMBuffer."Qty. per Parent";
                                            BOMBuffer."Qty. per BOM Line" := BOMBuffer."Qty. per BOM Line" * ParentBOMBuffer."Qty. per Parent";
                                        end;
                                        OnAfterTransferFromProdItem(BOMBuffer, ProdBOMLine);
                                        GenerateItemSubTree("No.", BOMBuffer);
                                    end;
                                Type::"Production BOM":
                                    begin
                                        OnBeforeTransferFromProdBOM(BOMBuffer, ProdBOMLine, ParentItem, ParentBOMBuffer, EntryNo, TreeType);

                                        BOMBuffer := ParentBOMBuffer;
                                        BOMBuffer."Qty. per Top Item" := Round(BOMBuffer."Qty. per Top Item" * "Quantity per", UOMMgt.QtyRndPrecision);
                                        if ParentItem."Production BOM No." <> ParentBOMBuffer."Production BOM No." then
                                            BOMBuffer."Qty. per Parent" := ParentBOMBuffer."Qty. per Parent" * "Quantity per"
                                        else
                                            BOMBuffer."Qty. per Parent" := "Quantity per";

                                        BOMBuffer."Scrap %" := CombineScrapFactors(BOMBuffer."Scrap %", "Scrap %");
                                        if CostCalculationMgt.FindRountingLine(RoutingLine, ProdBOMLine, WorkDate, ParentItem."Routing No.") then
                                            BOMBuffer."Scrap %" := CombineScrapFactors(BOMBuffer."Scrap %", RoutingLine."Scrap Factor % (Accumulated)" * 100);
                                        BOMBuffer."Scrap %" := Round(BOMBuffer."Scrap %", 0.00001);

                                        OnAfterTransferFromProdBOM(BOMBuffer, ProdBOMLine);

                                        CopyOfParentItem := ParentItem;
                                        ParentItem."Routing No." := '';
                                        ParentItem."Production BOM No." := "No.";
                                        GenerateProdCompSubTree(ParentItem, BOMBuffer);
                                        ParentItem := CopyOfParentItem;

                                        OnAfterGenerateProdCompSubTree(ParentItem, BOMBuffer);
                                    end;
                            end;
                until Next = 0;
                FoundSubTree := true;
            end;
        end;

        if RoutingLine.ReadPermission then
            with RoutingLine do
                if (TreeType in [TreeType::" ", TreeType::Cost]) and
                   CertifiedRoutingVersionExists(ParentItem."Routing No.", WorkDate)
                then begin
                    repeat
                        if "No." <> '' then begin
                            BOMBuffer.SetLocationVariantFiltersFrom(ItemFilter);
                            BOMBuffer.TransferFromProdRouting(
                              EntryNo, RoutingLine, ParentBOMBuffer.Indentation + 1,
                              ParentBOMBuffer."Qty. per Top Item" *
                              UOMMgt.GetQtyPerUnitOfMeasure(ParentItem, ParentBOMBuffer."Unit of Measure Code"),
                              ParentBOMBuffer."Needed by Date",
                              ParentBOMBuffer."Location Code");
                            OnAfterTransferFromProdRouting(BOMBuffer, RoutingLine);
                            if TreeType = TreeType::Cost then begin
                                LotSize := ParentBOMBuffer."Lot Size";
                                if LotSize = 0 then
                                    LotSize := 1;
                                CalcRoutingLineCosts(RoutingLine, LotSize, ParentBOMBuffer."Scrap %", BOMBuffer, ParentItem);
                                BOMBuffer.RoundCosts(
                                  ParentBOMBuffer."Qty. per Top Item" *
                                  UOMMgt.GetQtyPerUnitOfMeasure(ParentItem, ParentBOMBuffer."Unit of Measure Code") / LotSize);
                                BOMBuffer.Modify();
                            end;
                        end;
                    until Next = 0;
                    FoundSubTree := true;
                end;

        BOMBuffer := ParentBOMBuffer;
    end;

    local procedure GenerateAsmHeaderSubTree(AsmHeader: Record "Assembly Header"; var BOMBuffer: Record "BOM Buffer"): Boolean
    var
        AsmLine: Record "Assembly Line";
        OldAsmHeader: Record "Assembly Header";
        ParentBOMBuffer: Record "BOM Buffer";
    begin
        ParentBOMBuffer := BOMBuffer;
        with AsmLine do begin
            SetRange("Document Type", AsmHeader."Document Type");
            SetRange("Document No.", AsmHeader."No.");
            if FindSet then begin
                repeat
                    if (Type = Type::Item) and ("No." <> '') then begin
                        OldAsmHeader.Get("Document Type", "Document No.");
                        if AsmHeader."Due Date" <> OldAsmHeader."Due Date" then
                            "Due Date" := "Due Date" - (OldAsmHeader."Due Date" - AsmHeader."Due Date");

                        BOMBuffer.SetLocationVariantFiltersFrom(ItemFilter);
                        BOMBuffer.TransferFromAsmLine(EntryNo, AsmLine);
                        GenerateItemSubTree("No.", BOMBuffer);
                    end;
                until Next = 0;
                BOMBuffer := ParentBOMBuffer;

                exit(true);
            end;
        end;
    end;

    local procedure GenerateProdOrderLineSubTree(ProdOrderLine: Record "Prod. Order Line"; var BOMBuffer: Record "BOM Buffer"): Boolean
    var
        OldProdOrderLine: Record "Prod. Order Line";
        ProdOrderComp: Record "Prod. Order Component";
        ParentBOMBuffer: Record "BOM Buffer";
    begin
        ParentBOMBuffer := BOMBuffer;
        with ProdOrderComp do begin
            SetRange(Status, ProdOrderLine.Status);
            SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
            SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
            if FindSet then begin
                repeat
                    if "Item No." <> '' then begin
                        OldProdOrderLine.Get(Status, "Prod. Order No.", "Prod. Order Line No.");
                        if ProdOrderLine."Due Date" <> OldProdOrderLine."Due Date" then
                            "Due Date" := "Due Date" - (OldProdOrderLine."Due Date" - ProdOrderLine."Due Date");

                        BOMBuffer.SetLocationVariantFiltersFrom(ItemFilter);
                        BOMBuffer.TransferFromProdOrderComp(EntryNo, ProdOrderComp);
                        GenerateItemSubTree("Item No.", BOMBuffer);
                    end;
                until Next = 0;
                BOMBuffer := ParentBOMBuffer;

                exit(true);
            end;
        end;
    end;

    local procedure UpdateMinAbleToMake(var BOMBuffer: Record "BOM Buffer"; AvailToUse: Option UpdatedQtyOnItemAvail,QtyOnItemAvail,QtyAvail)
    var
        AvailQty: Decimal;
    begin
        with TempItemAvailByDate do begin
            SetRange("Item No.", BOMBuffer."No.");
            SetRange("Variant Code", BOMBuffer."Variant Code");
            if LocationSpecific then
                SetRange("Location Code", BOMBuffer."Location Code");
            SetRange(Date, BOMBuffer."Needed by Date");
            FindFirst;

            case AvailToUse of
                AvailToUse::UpdatedQtyOnItemAvail:
                    AvailQty := "Updated Available Qty";
                AvailToUse::QtyOnItemAvail:
                    AvailQty := "Available Qty";
                AvailToUse::QtyAvail:
                    AvailQty := BOMBuffer."Available Quantity";
            end;
        end;

        with BOMBuffer do begin
            UpdateAbleToMake(AvailQty);
            Modify;
        end;
    end;

    local procedure CalcMinAbleToMake(IsFirst: Boolean; OldMin: Decimal; NewMin: Decimal): Decimal
    begin
        if NewMin <= 0 then
            exit(0);
        if IsFirst then
            exit(NewMin);
        if NewMin < OldMin then
            exit(NewMin);
        exit(OldMin);
    end;

    local procedure InitItemAvailDates(var BOMBuffer: Record "BOM Buffer")
    var
        BOMItem: Record Item;
        ParentBOMBuffer: Record "BOM Buffer";
    begin
        ParentBOMBuffer := BOMBuffer;
        TempItemAvailByDate.Reset();
        TempItemAvailByDate.DeleteAll();

        with BOMBuffer do
            repeat
                if not AvailByDateExists(BOMBuffer) then begin
                    BOMItem.CopyFilters(ItemFilter);
                    BOMItem.Get("No.");
                    BOMItem.SetRange("Date Filter", 0D, "Needed by Date");
                    if Indentation = 0 then begin
                        BOMItem.SetFilter("Variant Filter", ItemFilter.GetFilter("Variant Filter"));
                        BOMItem.SetFilter("Location Filter", ItemFilter.GetFilter("Location Filter"));
                    end else
                        BOMItem.SetRange("Variant Filter", "Variant Code");

                    TempItemAvailByDate.Init();
                    TempItemAvailByDate."Item No." := "No.";
                    TempItemAvailByDate.Date := "Needed by Date";
                    TempItemAvailByDate."Variant Code" := "Variant Code";
                    if LocationSpecific then
                        TempItemAvailByDate."Location Code" := "Location Code";

                    Clear(AvailableToPromise);
                    TempItemAvailByDate."Available Qty" :=
                      AvailableToPromise.QtyAvailabletoPromise(BOMItem, "Gross Requirement", "Scheduled Receipts", "Needed by Date", 0, ZeroDF);
                    TempItemAvailByDate."Updated Available Qty" := TempItemAvailByDate."Available Qty";
                    TempItemAvailByDate.Insert();

                    Modify;
                end;
            until (Next = 0) or (Indentation <= ParentBOMBuffer.Indentation);
        BOMBuffer := ParentBOMBuffer;
        BOMBuffer.Find;
    end;

    local procedure UpdateAvailability(var BOMBuffer: Record "BOM Buffer"; ShowTotalAvailability: Boolean)
    var
        CopyOfBOMBuffer: Record "BOM Buffer";
        SubOptimalQty: Decimal;
        OptimalQty: Decimal;
    begin
        with BOMBuffer do begin
            CopyOfBOMBuffer.Copy(BOMBuffer);
            if Find then
                repeat
                    if Indentation = 0 then begin
                        InitItemAvailDates(BOMBuffer);
                        SubOptimalQty := TraverseTree(BOMBuffer, AvailToUse::QtyOnItemAvail);
                        TempMemoizedResult.DeleteAll();
                        OptimalQty := BinarySearchOptimal(BOMBuffer, UOMMgt.QtyRndPrecision, SubOptimalQty);
                        MarkBottlenecks(BOMBuffer, OptimalQty);
                        CalcAvailability(BOMBuffer, OptimalQty, false);
                        if ShowTotalAvailability then
                            DistributeRemainingAvail(BOMBuffer);
                        TraverseTree(BOMBuffer, AvailToUse::QtyAvail);
                    end;
                until Next = 0;
            Copy(CopyOfBOMBuffer);
        end;
    end;

    local procedure TraverseTree(var BOMBuffer: Record "BOM Buffer"; AvailToUse: Option UpdatedQtyOnItemAvail,QtyOnItemAvail,QtyAvail): Decimal
    var
        ParentBOMBuffer: Record "BOM Buffer";
        IsFirst: Boolean;
    begin
        ParentBOMBuffer := BOMBuffer;
        IsFirst := true;
        with BOMBuffer do begin
            while (Next <> 0) and (ParentBOMBuffer.Indentation < Indentation) do
                if ParentBOMBuffer.Indentation + 1 = Indentation then begin
                    if not "Is Leaf" then
                        TraverseTree(BOMBuffer, AvailToUse)
                    else
                        UpdateMinAbleToMake(BOMBuffer, AvailToUse);

                    ParentBOMBuffer."Able to Make Parent" :=
                      CalcMinAbleToMake(IsFirst, ParentBOMBuffer."Able to Make Parent", "Able to Make Parent");
                    ParentBOMBuffer."Able to Make Top Item" :=
                      CalcMinAbleToMake(IsFirst, ParentBOMBuffer."Able to Make Top Item", "Able to Make Top Item");

                    IsFirst := false;
                end;

            BOMBuffer := ParentBOMBuffer;
            UpdateMinAbleToMake(BOMBuffer, AvailToUse);
            exit("Able to Make Top Item");
        end;
    end;

    local procedure UpdateCost(var BOMBuffer: Record "BOM Buffer")
    var
        CopyOfBOMBuffer: Record "BOM Buffer";
    begin
        with BOMBuffer do begin
            CopyOfBOMBuffer.Copy(BOMBuffer);
            if Find then
                repeat
                    if Indentation = 0 then
                        TraverseCostTree(BOMBuffer);
                until Next = 0;
            Copy(CopyOfBOMBuffer);
        end;
    end;

    local procedure TraverseCostTree(var BOMBuffer: Record "BOM Buffer"): Decimal
    var
        ParentBOMBuffer: Record "BOM Buffer";
    begin
        ParentBOMBuffer := BOMBuffer;
        with BOMBuffer do begin
            while (Next <> 0) and (ParentBOMBuffer.Indentation < Indentation) do
                if (ParentBOMBuffer.Indentation + 1 = Indentation) and
                   (("Qty. per Top Item" <> 0) or (Type in [Type::"Machine Center", Type::"Work Center"]))
                then begin
                    if not "Is Leaf" then
                        TraverseCostTree(BOMBuffer)
                    else
                        if (Type = Type::Resource) and ("Resource Usage Type" = "Resource Usage Type"::Fixed) then
                            UpdateNodeCosts(BOMBuffer, ParentBOMBuffer."Lot Size" / ParentBOMBuffer."Qty. per Top Item")
                        else
                            UpdateNodeCosts(BOMBuffer, 1);

                    if "Is Leaf" then begin
                        ParentBOMBuffer.AddMaterialCost("Single-Level Material Cost", "Rolled-up Material Cost");
                        ParentBOMBuffer.AddCapacityCost("Single-Level Capacity Cost", "Rolled-up Capacity Cost");
                        ParentBOMBuffer.AddSubcontrdCost("Single-Level Subcontrd. Cost", "Rolled-up Subcontracted Cost");
                        ParentBOMBuffer.AddCapOvhdCost("Single-Level Cap. Ovhd Cost", "Rolled-up Capacity Ovhd. Cost");
                        ParentBOMBuffer.AddMfgOvhdCost("Single-Level Mfg. Ovhd Cost", "Rolled-up Mfg. Ovhd Cost");
                        ParentBOMBuffer.AddScrapCost("Single-Level Scrap Cost", "Rolled-up Scrap Cost");
                        OnTraverseCostTreeOnAfterAddCost(ParentBOMBuffer, BOMBuffer);
                    end else begin
                        ParentBOMBuffer.AddMaterialCost(
                          "Single-Level Material Cost" +
                          "Single-Level Capacity Cost" +
                          "Single-Level Subcontrd. Cost" +
                          "Single-Level Cap. Ovhd Cost" +
                          "Single-Level Mfg. Ovhd Cost",
                          "Rolled-up Material Cost");
                        ParentBOMBuffer.AddCapacityCost(0, "Rolled-up Capacity Cost");
                        ParentBOMBuffer.AddSubcontrdCost(0, "Rolled-up Subcontracted Cost");
                        ParentBOMBuffer.AddCapOvhdCost(0, "Rolled-up Capacity Ovhd. Cost");
                        ParentBOMBuffer.AddMfgOvhdCost(0, "Rolled-up Mfg. Ovhd Cost");
                        ParentBOMBuffer.AddScrapCost(0, "Rolled-up Scrap Cost");
                    end;
                end;

            BOMBuffer := ParentBOMBuffer;
            UpdateNodeCosts(BOMBuffer, ParentBOMBuffer."Lot Size");
            exit("Able to Make Top Item");
        end;
    end;

    local procedure UpdateNodeCosts(var BOMBuffer: Record "BOM Buffer"; LotSize: Decimal)
    begin
        with BOMBuffer do begin
            if LotSize = 0 then
                LotSize := 1;
            RoundCosts(LotSize);

            if "Is Leaf" then begin
                case Type of
                    Type::Item:
                        GetItemCosts;
                    Type::Resource:
                        GetResCosts;
                end;
                RoundCosts(1 / LotSize);
            end else
                if HasBomStructure("No.") then begin
                    CalcOvhdCost;
                    RoundCosts(1 / LotSize);
                end else
                    if Type = Type::Item then begin
                        RoundCosts(1 / LotSize);
                        GetItemCosts;
                    end;

            CalcUnitCost;
            Modify;
        end;
    end;

    local procedure BinarySearchOptimal(var BOMBuffer: Record "BOM Buffer"; InputLow: Decimal; InputHigh: Decimal): Decimal
    var
        InputMid: Decimal;
    begin
        if InputHigh <= 0 then
            exit(0);
        if CalcAvailability(BOMBuffer, InputHigh, true) then begin
            TempMemoizedResult.DeleteAll();
            exit(InputHigh);
        end;
        if InputHigh - InputLow = UOMMgt.QtyRndPrecision then begin
            TempMemoizedResult.DeleteAll();
            exit(InputLow);
        end;
        InputMid := Round((InputLow + InputHigh) / 2, UOMMgt.QtyRndPrecision);
        if not CalcAvailability(BOMBuffer, InputMid, true) then
            exit(BinarySearchOptimal(BOMBuffer, InputLow, InputMid));
        exit(BinarySearchOptimal(BOMBuffer, InputMid, InputHigh));
    end;

    local procedure CalcAvailability(var BOMBuffer: Record "BOM Buffer"; Input: Decimal; IsTest: Boolean): Boolean
    var
        ParentBOMBuffer: Record "BOM Buffer";
        ExpectedQty: Decimal;
        AvailQty: Decimal;
        MaxTime: Integer;
    begin
        if BOMBuffer.Indentation = 0 then begin
            if IsTest then
                if TempMemoizedResult.Get(Input) then
                    exit(TempMemoizedResult.Output);

            ResetUpdatedAvailability;
        end;

        ParentBOMBuffer := BOMBuffer;
        with BOMBuffer do begin
            while (Next <> 0) and (ParentBOMBuffer.Indentation < Indentation) do
                if ParentBOMBuffer.Indentation + 1 = Indentation then begin
                    TempItemAvailByDate.SetRange("Item No.", "No.");
                    TempItemAvailByDate.SetRange(Date, "Needed by Date");
                    TempItemAvailByDate.SetRange("Variant Code", "Variant Code");
                    if LocationSpecific then
                        TempItemAvailByDate.SetRange("Location Code", "Location Code");
                    TempItemAvailByDate.FindFirst;
                    ExpectedQty := Round("Qty. per Parent" * Input, UOMMgt.QtyRndPrecision);
                    AvailQty := TempItemAvailByDate."Updated Available Qty";
                    if AvailQty < ExpectedQty then begin
                        if "Is Leaf" then begin
                            if MarkBottleneck then begin
                                Bottleneck := true;
                                Modify(true);
                            end;
                            BOMBuffer := ParentBOMBuffer;
                            if (Indentation = 0) and IsTest then
                                AddMemoizedResult(Input, false);
                            exit(false);
                        end;
                        if AvailQty <> 0 then
                            ReduceAvailability("No.", "Variant Code", "Location Code", "Needed by Date", AvailQty);
                        if not IsTest then begin
                            "Available Quantity" := AvailQty;
                            Modify;
                        end;
                        if not CalcAvailability(BOMBuffer, ExpectedQty - AvailQty, IsTest) then begin
                            if MarkBottleneck then begin
                                Bottleneck := true;
                                Modify(true);
                            end;
                            BOMBuffer := ParentBOMBuffer;
                            if (Indentation = 0) and IsTest then
                                AddMemoizedResult(Input, false);
                            exit(false);
                        end;
                        if not IsTest then
                            if MaxTime < (ParentBOMBuffer."Needed by Date" - "Needed by Date") + "Rolled-up Lead-Time Offset" then
                                MaxTime := (ParentBOMBuffer."Needed by Date" - "Needed by Date") + "Rolled-up Lead-Time Offset";
                    end else begin
                        if not IsTest then begin
                            "Available Quantity" := ExpectedQty;
                            Modify;
                            if MaxTime < (ParentBOMBuffer."Needed by Date" - "Needed by Date") + "Rolled-up Lead-Time Offset" then
                                MaxTime := (ParentBOMBuffer."Needed by Date" - "Needed by Date") + "Rolled-up Lead-Time Offset";
                        end;
                        ReduceAvailability("No.", "Variant Code", "Location Code", "Needed by Date", ExpectedQty);
                    end;
                end;
            BOMBuffer := ParentBOMBuffer;
            "Rolled-up Lead-Time Offset" := MaxTime;
            Modify(true);
            if (Indentation = 0) and IsTest then
                AddMemoizedResult(Input, true);
            exit(true);
        end;
    end;

    local procedure AddMemoizedResult(NewInput: Decimal; NewOutput: Boolean)
    begin
        with TempMemoizedResult do begin
            Input := NewInput;
            Output := NewOutput;
            Insert;
        end;
    end;

    local procedure ResetUpdatedAvailability()
    begin
        with TempItemAvailByDate do begin
            Reset;
            if Find('-') then
                repeat
                    if "Updated Available Qty" <> "Available Qty" then begin
                        "Updated Available Qty" := "Available Qty";
                        Modify;
                    end;
                until Next = 0;
        end;
    end;

    local procedure ReduceAvailability(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; ToDate: Date; Qty: Decimal)
    begin
        with TempItemAvailByDate do begin
            Reset;
            SetRange("Item No.", ItemNo);
            SetRange("Variant Code", VariantCode);
            if LocationSpecific then
                SetRange("Location Code", LocationCode);
            SetRange(Date, 0D, ToDate);
            if FindSet then
                repeat
                    if "Updated Available Qty" <> 0 then begin
                        if "Updated Available Qty" > Qty then
                            "Updated Available Qty" := "Updated Available Qty" - Qty
                        else
                            "Updated Available Qty" := 0;
                        Modify;
                    end;
                until Next = 0;
            SetRange("Item No.");
            SetRange("Variant Code");
            SetRange("Location Code");
            SetRange(Date);
        end;
    end;

    local procedure DistributeRemainingAvail(var BOMBuffer: Record "BOM Buffer")
    var
        CurrItemAvailByDate: Record "Item Availability by Date";
        CopyOfBOMBuffer: Record "BOM Buffer";
    begin
        with BOMBuffer do begin
            CopyOfBOMBuffer.Copy(BOMBuffer);
            Reset;
            SetCurrentKey(Type, "No.", Indentation);
            SetFilter("Entry No.", '>=%1', "Entry No.");
            TempItemAvailByDate.Reset();
            if TempItemAvailByDate.FindSet then
                repeat
                    if TempItemAvailByDate."Updated Available Qty" <> 0 then begin
                        CurrItemAvailByDate := TempItemAvailByDate;

                        SetRange(Type, Type);
                        SetRange("No.", TempItemAvailByDate."Item No.");
                        SetRange("Variant Code", TempItemAvailByDate."Variant Code");
                        if LocationSpecific then
                            SetRange("Location Code", TempItemAvailByDate."Location Code");
                        SetRange("Needed by Date", TempItemAvailByDate.Date);
                        FindFirst;
                        "Available Quantity" += TempItemAvailByDate."Updated Available Qty";
                        "Unused Quantity" += TempItemAvailByDate."Updated Available Qty";
                        Modify;

                        ReduceAvailability("No.", "Variant Code", "Location Code",
                          "Needed by Date",
                          TempItemAvailByDate."Updated Available Qty");
                        TempItemAvailByDate := CurrItemAvailByDate;
                    end;
                until TempItemAvailByDate.Next = 0;
            Copy(CopyOfBOMBuffer);
            Find;
        end;
    end;

    local procedure MarkBottlenecks(var BOMBuffer: Record "BOM Buffer"; Input: Decimal)
    begin
        MarkBottleneck := true;
        CalcAvailability(BOMBuffer, Input + UOMMgt.QtyRndPrecision, true);
        MarkBottleneck := false;
    end;

    local procedure CalcCompDueDate(DemandDate: Date; ParentItem: Record Item; LeadTimeOffset: DateFormula) DueDate: Date
    var
        MfgSetup: Record "Manufacturing Setup";
        EndDate: Date;
        StartDate: Date;
    begin
        if DemandDate = 0D then
            exit;

        EndDate := DemandDate;
        if Format(ParentItem."Safety Lead Time") <> '' then
            EndDate := DemandDate - (CalcDate(ParentItem."Safety Lead Time", DemandDate) - DemandDate)
        else
            if MfgSetup.Get and (Format(MfgSetup."Default Safety Lead Time") <> '') then
                EndDate := DemandDate - (CalcDate(MfgSetup."Default Safety Lead Time", DemandDate) - DemandDate);

        if Format(ParentItem."Lead Time Calculation") = '' then
            StartDate := EndDate
        else
            StartDate := EndDate - (CalcDate(ParentItem."Lead Time Calculation", EndDate) - EndDate);

        if Format(LeadTimeOffset) = '' then
            DueDate := StartDate
        else
            DueDate := StartDate - (CalcDate(LeadTimeOffset, StartDate) - StartDate);
    end;

    local procedure AvailByDateExists(BOMBuffer: Record "BOM Buffer"): Boolean
    begin
        if LocationSpecific then
            exit(TempItemAvailByDate.Get(BOMBuffer."No.", BOMBuffer."Variant Code", BOMBuffer."Location Code", BOMBuffer."Needed by Date"));
        exit(TempItemAvailByDate.Get(BOMBuffer."No.", BOMBuffer."Variant Code", '', BOMBuffer."Needed by Date"));
    end;

    procedure SetShowTotalAvailability(NewShowTotalAvailability: Boolean)
    begin
        ShowTotalAvailability := NewShowTotalAvailability;
    end;

    local procedure CalcRoutingLineCosts(RoutingLine: Record "Routing Line"; LotSize: Decimal; ScrapPct: Decimal; var BOMBuffer: Record "BOM Buffer"; ParentItem: Record Item)
    var
        CalcStdCost: Codeunit "Calculate Standard Cost";
        CostCalculationMgt: Codeunit "Cost Calculation Management";
        CapCost: Decimal;
        SubcontractedCapCost: Decimal;
        CapOverhead: Decimal;
    begin
        OnBeforeCalcRoutingLineCosts(RoutingLine, LotSize, ScrapPct, ParentItem);

        CalcStdCost.SetProperties(WorkDate, false, false, false, '', false);
        CalcStdCost.CalcRtngLineCost(
          RoutingLine, CostCalculationMgt.CalcQtyAdjdForBOMScrap(LotSize, ScrapPct), CapCost, SubcontractedCapCost, CapOverhead);

        BOMBuffer.AddCapacityCost(CapCost, CapCost);
        BOMBuffer.AddSubcontrdCost(SubcontractedCapCost, SubcontractedCapCost);
        BOMBuffer.AddCapOvhdCost(CapOverhead, CapOverhead);
    end;

    local procedure HasBomStructure(ItemNo: Code[20]): Boolean
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        case Item."Replenishment System" of
            Item."Replenishment System"::Assembly:
                begin
                    Item.CalcFields("Assembly BOM");
                    if Item."Assembly BOM" then
                        exit(true);
                end;
            Item."Replenishment System"::"Prod. Order":
                if Item."Production BOM No." <> '' then
                    exit(true);
        end;
    end;

    procedure SetItemFilter(var Item: Record Item)
    begin
        ItemFilter.CopyFilters(Item);
    end;

    local procedure GetBOMUnitOfMeasure(ProdBOMNo: Code[20]; ProdBOMVersionNo: Code[20]): Code[10]
    var
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMVersion: Record "Production BOM Version";
    begin
        if ProdBOMVersionNo <> '' then begin
            ProdBOMVersion.Get(ProdBOMNo, ProdBOMVersionNo);
            exit(ProdBOMVersion."Unit of Measure Code");
        end;

        ProdBOMHeader.Get(ProdBOMNo);
        exit(ProdBOMHeader."Unit of Measure Code");
    end;

    local procedure GetQtyPerBOMHeaderUnitOfMeasure(Item: Record Item; ProdBOMNo: Code[20]; ProdBOMVersionNo: Code[20]): Decimal
    var
        UOMMgt: Codeunit "Unit of Measure Management";
    begin
        if ProdBOMNo = '' then
            exit(1);

        exit(UOMMgt.GetQtyPerUnitOfMeasure(Item, GetBOMUnitOfMeasure(ProdBOMNo, ProdBOMVersionNo)));
    end;

    local procedure CombineScrapFactors(LowLevelScrapPct: Decimal; HighLevelScrapPct: Decimal): Decimal
    begin
        exit(LowLevelScrapPct + HighLevelScrapPct + LowLevelScrapPct * HighLevelScrapPct / 100);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterBOMBuffer(var ParentItem: Record Item; var BOMBuffer: Record "BOM Buffer"; DemandDate: Date; TreeType: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGenerateProdCompSubTree(var ParentItem: Record Item; var BOMBuffer: Record "BOM Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromProdItem(var BOMBuffer: Record "BOM Buffer"; ProdBOMLine: Record "Production BOM Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromProdBOM(var BOMBuffer: Record "BOM Buffer"; ProdBOMLine: Record "Production BOM Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromProdRouting(var BOMBuffer: Record "BOM Buffer"; RoutingLine: Record "Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcRoutingLineCosts(var RoutingLine: Record "Routing Line"; var LotSize: Decimal; var ScrapPct: Decimal; ParentItem: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFilterBOMBuffer(var ParentItem: Record Item; var BOMBuffer: Record "BOM Buffer"; DemandDate: Date; TreeType: Option; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFilterByQuantityPer(var ProductionBOMLine: Record "Production BOM Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferFromProdBOM(var BOMBuffer: Record "BOM Buffer"; var ProdBOMLine: Record "Production BOM Line"; var ParentItem: Record Item; var ParentBOMBuffer: Record "BOM Buffer"; var EntryNo: Integer; TreeType: Option " ",Availability,Cost)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferProdBOMLine(var BOMBuffer: Record "BOM Buffer"; var ProdBOMLine: Record "Production BOM Line"; var ParentItem: Record Item; var ParentBOMBuffer: Record "BOM Buffer"; var EntryNo: Integer; TreeType: Option " ",Availability,Cost; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTraverseCostTreeOnAfterAddCost(var ParentBOMBuffer: Record "BOM Buffer"; var BOMBuffer: Record "BOM Buffer")
    begin
    end;
}

