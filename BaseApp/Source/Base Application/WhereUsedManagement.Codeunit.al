codeunit 99000770 "Where-Used Management"
{
    Permissions = TableData "Production BOM Header" = r,
                  TableData "Production BOM Version" = r,
                  TableData "Where-Used Line" = imd;

    trigger OnRun()
    begin
    end;

    var
        WhereUsedList: Record "Where-Used Line" temporary;
        UOMMgt: Codeunit "Unit of Measure Management";
        VersionMgt: Codeunit VersionManagement;
        CostCalcMgt: Codeunit "Cost Calculation Management";
        MultiLevel: Boolean;
        NextWhereUsedEntryNo: Integer;

    procedure FindRecord(Which: Text[30]; var WhereUsedList2: Record "Where-Used Line"): Boolean
    begin
        WhereUsedList.Copy(WhereUsedList2);
        if not WhereUsedList.Find(Which) then
            exit(false);
        WhereUsedList2 := WhereUsedList;

        exit(true);
    end;

    procedure NextRecord(Steps: Integer; var WhereUsedList2: Record "Where-Used Line"): Integer
    var
        CurrentSteps: Integer;
    begin
        WhereUsedList.Copy(WhereUsedList2);
        CurrentSteps := WhereUsedList.Next(Steps);
        if CurrentSteps <> 0 then
            WhereUsedList2 := WhereUsedList;

        exit(CurrentSteps);
    end;

    procedure WhereUsedFromItem(Item: Record Item; CalcDate: Date; NewMultiLevel: Boolean)
    begin
        WhereUsedList.DeleteAll();
        NextWhereUsedEntryNo := 1;
        MultiLevel := NewMultiLevel;

        BuildWhereUsedList(1, Item."No.", CalcDate, 1, 1);
    end;

    procedure WhereUsedFromProdBOM(ProdBOM: Record "Production BOM Header"; CalcDate: Date; NewMultiLevel: Boolean)
    begin
        WhereUsedList.DeleteAll();
        NextWhereUsedEntryNo := 1;
        MultiLevel := NewMultiLevel;

        BuildWhereUsedList(2, ProdBOM."No.", CalcDate, 1, 1);
    end;

    local procedure BuildWhereUsedList(Type: Option " ",Item,"Production BOM"; No: Code[20]; CalcDate: Date; Level: Integer; Quantity: Decimal)
    var
        ItemAssembly: Record Item;
        ProdBOMComponent: Record "Production BOM Line";
    begin
        if Level > 30 then
            exit;

        if Type = Type::"Production BOM" then begin
            ItemAssembly.SetCurrentKey("Production BOM No.");
            ItemAssembly.SetRange("Production BOM No.", No);
            if ItemAssembly.FindSet then
                repeat
                    WhereUsedList."Entry No." := NextWhereUsedEntryNo;
                    WhereUsedList."Item No." := ItemAssembly."No.";
                    WhereUsedList.Description := ItemAssembly.Description;
                    WhereUsedList."Level Code" := Level;
                    WhereUsedList."Quantity Needed" :=
                      Quantity *
                      (1 + ItemAssembly."Scrap %" / 100) *
                      UOMMgt.GetQtyPerUnitOfMeasure(ItemAssembly, ItemAssembly."Base Unit of Measure") /
                      UOMMgt.GetQtyPerUnitOfMeasure(
                        ItemAssembly,
                        VersionMgt.GetBOMUnitOfMeasure(
                          ItemAssembly."Production BOM No.",
                          VersionMgt.GetBOMVersion(ItemAssembly."Production BOM No.", CalcDate, false)));
                    WhereUsedList."Version Code" := VersionMgt.GetBOMVersion(No, CalcDate, true);
                    OnBeforeWhereUsedListInsert(WhereUsedList, ItemAssembly, CalcDate, Quantity);
                    WhereUsedList.Insert();
                    NextWhereUsedEntryNo := NextWhereUsedEntryNo + 1;
                    if MultiLevel then
                        BuildWhereUsedList(
                          1,
                          ItemAssembly."No.",
                          CalcDate,
                          Level + 1,
                          WhereUsedList."Quantity Needed");
                until ItemAssembly.Next = 0;
        end;

        ProdBOMComponent.SetCurrentKey(Type, "No.");
        ProdBOMComponent.SetRange(Type, Type);
        ProdBOMComponent.SetRange("No.", No);
        if CalcDate <> 0D then begin
            ProdBOMComponent.SetFilter("Starting Date", '%1|..%2', 0D, CalcDate);
            ProdBOMComponent.SetFilter("Ending Date", '%1|%2..', 0D, CalcDate);
        end;

        if ProdBOMComponent.FindSet then
            repeat
                if VersionMgt.GetBOMVersion(
                     ProdBOMComponent."Production BOM No.", CalcDate, true) =
                   ProdBOMComponent."Version Code"
                then begin
                    OnBuildWhereUsedListOnLoopProdBomComponent(ProdBOMComponent);
                    if IsActiveProductionBOM(ProdBOMComponent) then
                        BuildWhereUsedList(
                          2,
                          ProdBOMComponent."Production BOM No.",
                          CalcDate,
                          Level,
                          CostCalcMgt.CalcCompItemQtyBase(ProdBOMComponent, CalcDate, Quantity, '', false));
                end;
            until ProdBOMComponent.Next = 0;
    end;

    local procedure IsActiveProductionBOM(ProductionBOMLine: Record "Production BOM Line"): Boolean
    begin
        if ProductionBOMLine."Version Code" = '' then
            exit(not IsProductionBOMClosed(ProductionBOMLine));

        exit(not IsProdBOMVersionClosed(ProductionBOMLine));
    end;

    local procedure IsProductionBOMClosed(ProductionBOMLine: Record "Production BOM Line"): Boolean
    var
        ProdBOMHeader: Record "Production BOM Header";
    begin
        ProdBOMHeader.Get(ProductionBOMLine."Production BOM No.");
        exit(ProdBOMHeader.Status = ProdBOMHeader.Status::Closed);
    end;

    local procedure IsProdBOMVersionClosed(ProductionBOMLine: Record "Production BOM Line"): Boolean
    var
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        ProductionBOMVersion.Get(ProductionBOMLine."Production BOM No.", ProductionBOMLine."Version Code");
        exit(ProductionBOMVersion.Status = ProductionBOMVersion.Status::Closed);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhereUsedListInsert(var WhereUsedLine: Record "Where-Used Line"; var ItemAssembly: Record Item; var CalcDate: Date; var Quantity: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBuildWhereUsedListOnLoopProdBomComponent(var ProductionBOMLine: Record "Production BOM Line")
    begin
    end;
}

