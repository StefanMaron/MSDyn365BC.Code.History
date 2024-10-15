namespace Microsoft.Manufacturing.ProductionBOM;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;

codeunit 99000771 "BOM Matrix Management"
{
    Permissions = TableData Item = r,
                  TableData "Production BOM Header" = r,
                  TableData "Production BOM Version" = r,
                  TableData "Production Matrix BOM Line" = rimd,
                  TableData "Production Matrix  BOM Entry" = rimd;

    trigger OnRun()
    begin
    end;

    var
        Item: Record Item;
        ItemAssembly: Record Item;
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMVersion: Record "Production BOM Version";
        ProdBOMVersion2: Record "Production BOM Version";
        TempComponentList: Record "Production Matrix BOM Line" temporary;
        TempComponentEntry: Record "Production Matrix  BOM Entry" temporary;
        ComponentEntry2: Record "Production Matrix  BOM Entry";
        UOMMgt: Codeunit "Unit of Measure Management";
        VersionMgt: Codeunit VersionManagement;
        GlobalCalcDate: Date;
        MatrixType: Option Version,Item;
        MultiLevel: Boolean;

    procedure FindRecord(Which: Text[30]; var ComponentList2: Record "Production Matrix BOM Line"): Boolean
    begin
        TempComponentList := ComponentList2;
        if not TempComponentList.Find(Which) then
            exit(false);
        ComponentList2 := TempComponentList;
        exit(true);
    end;

    procedure NextRecord(Steps: Integer; var ComponentList2: Record "Production Matrix BOM Line"): Integer
    var
        CurrentSteps: Integer;
    begin
        TempComponentList := ComponentList2;
        CurrentSteps := TempComponentList.Next(Steps);
        if CurrentSteps <> 0 then
            ComponentList2 := TempComponentList;
        exit(CurrentSteps);
    end;

    procedure GetComponentNeed(No: Code[20]; VariantCode: Code[10]; ID: Code[20]): Decimal
    begin
        TempComponentEntry.SetRange("Item No.", No);
        TempComponentEntry.SetRange("Variant Code", VariantCode);
        TempComponentEntry.SetRange(ID, ID);
        if not TempComponentEntry.FindFirst() then
            Clear(TempComponentEntry);

        exit(TempComponentEntry.Quantity);
    end;

    procedure CompareTwoItems(Item1: Record Item; Item2: Record Item; CalcDate: Date; NewMultiLevel: Boolean; var VersionCode1: Code[20]; var VersionCode2: Code[20]; var UnitOfMeasure1: Code[10]; var UnitOfMeasure2: Code[10])
    begin
        GlobalCalcDate := CalcDate;

        TempComponentList.DeleteAll();
        TempComponentEntry.Reset();
        TempComponentEntry.DeleteAll();

        MultiLevel := NewMultiLevel;
        MatrixType := MatrixType::Item;

        VersionCode1 :=
          VersionMgt.GetBOMVersion(
            Item1."Production BOM No.",
            GlobalCalcDate, false);
        UnitOfMeasure1 :=
          VersionMgt.GetBOMUnitOfMeasure(
            Item1."Production BOM No.", VersionCode1);

        ItemAssembly := Item1;
        BuildMatrix(
          Item1."Production BOM No.",
          VersionCode1, 1,
          UOMMgt.GetQtyPerUnitOfMeasure(
            Item1, UnitOfMeasure1) /
          UOMMgt.GetQtyPerUnitOfMeasure(
            Item1, Item1."Base Unit of Measure"));

        VersionCode2 :=
          VersionMgt.GetBOMVersion(
            Item2."Production BOM No.",
            GlobalCalcDate, false);
        UnitOfMeasure2 :=
          VersionMgt.GetBOMUnitOfMeasure(
            Item2."Production BOM No.", VersionCode2);

        ItemAssembly := Item2;
        BuildMatrix(
          Item2."Production BOM No.",
          VersionCode2, 1,
          UOMMgt.GetQtyPerUnitOfMeasure(
            Item2, UnitOfMeasure2) /
          UOMMgt.GetQtyPerUnitOfMeasure(
            Item2, Item2."Base Unit of Measure"));
    end;

    procedure BOMMatrixFromBOM(ProdBOM: Record "Production BOM Header"; NewMultiLevel: Boolean)
    begin
        TempComponentList.DeleteAll();
        TempComponentEntry.Reset();
        TempComponentEntry.DeleteAll();

        MultiLevel := NewMultiLevel;
        MatrixType := MatrixType::Version;
        BuildMatrix(ProdBOM."No.", '', 1, 1);
        ProdBOMVersion.SetRange("Production BOM No.", ProdBOM."No.");

        if ProdBOMVersion.Find('-') then
            repeat
                GlobalCalcDate := ProdBOMVersion."Starting Date";
                BuildMatrix(ProdBOM."No.", ProdBOMVersion."Version Code", 1, 1);
            until ProdBOMVersion.Next() = 0;
    end;

    local procedure BuildMatrix(ProdBOMNo: Code[20]; VersionCode: Code[20]; Level: Integer; Quantity: Decimal)
    var
        ProdBOMComponent: Record "Production BOM Line";
    begin
        if Level > 20 then
            exit;

        ProdBOMComponent.SetRange("Production BOM No.", ProdBOMNo);
        ProdBOMComponent.SetRange("Version Code", VersionCode);
        if GlobalCalcDate <> 0D then begin
            ProdBOMComponent.SetFilter("Starting Date", '%1|..%2', 0D, GlobalCalcDate);
            ProdBOMComponent.SetFilter("Ending Date", '%1|%2..', 0D, GlobalCalcDate);
        end;

        if ProdBOMComponent.Find('-') then
            repeat
                case ProdBOMComponent.Type of
                    ProdBOMComponent.Type::Item:
                        if Item.Get(ProdBOMComponent."No.") then begin
                            OnBuildMatrixForItemOnAfterGetItem(ProdBOMComponent);
                            if MultiLevel and (Item."Production BOM No." <> '') then begin
                                VersionCode :=
                                  VersionMgt.GetBOMVersion(Item."Production BOM No.", GlobalCalcDate, false);
                                OnBuildMatrixForItemOnBeforeRecursion(ProdBOMComponent);
                                BuildMatrix(
                                  Item."Production BOM No.", VersionCode, Level + 1,
                                  Quantity *
                                  UOMMgt.GetQtyPerUnitOfMeasure(Item, ProdBOMComponent."Unit of Measure Code") /
                                  UOMMgt.GetQtyPerUnitOfMeasure(Item, Item."Base Unit of Measure") /
                                  UOMMgt.GetQtyPerUnitOfMeasure(
                                    Item, VersionMgt.GetBOMUnitOfMeasure(Item."Production BOM No.", VersionCode)) *
                                  ProdBOMComponent.Quantity);
                            end else begin
                                TempComponentList."Item No." := ProdBOMComponent."No.";
                                TempComponentList."Variant Code" := ProdBOMComponent."Variant Code";
                                TempComponentList.Description := ProdBOMComponent.Description;
                                TempComponentList."Unit of Measure Code" := Item."Base Unit of Measure";
                                OnBuildMatrixForItemOnBeforeComponentListFind(ProdBOMComponent, TempComponentList);
                                if not TempComponentList.Find() then
                                    TempComponentList.Insert();
                                ComponentEntry2.Init();
                                ComponentEntry2."Item No." := ProdBOMComponent."No.";
                                ComponentEntry2."Variant Code" := ProdBOMComponent."Variant Code";
                                case MatrixType of
                                    MatrixType::Version:
                                        ComponentEntry2.ID := ProdBOMVersion."Version Code";
                                    MatrixType::Item:
                                        ComponentEntry2.ID := ItemAssembly."No.";
                                end;
                                ComponentEntry2.Quantity :=
                                  ProdBOMComponent.Quantity *
                                  UOMMgt.GetQtyPerUnitOfMeasure(Item, ProdBOMComponent."Unit of Measure Code") /
                                  UOMMgt.GetQtyPerUnitOfMeasure(Item, Item."Base Unit of Measure") *
                                  Quantity;
                                TempComponentEntry := ComponentEntry2;
                                TempComponentEntry.SetRange("Item No.", ComponentEntry2."Item No.");
                                TempComponentEntry.SetRange("Variant Code", ComponentEntry2."Variant Code");
                                TempComponentEntry.SetRange(ID, ComponentEntry2.ID);
                                if TempComponentEntry.FindFirst() then begin
                                    TempComponentEntry.Quantity :=
                                      TempComponentEntry.Quantity + ComponentEntry2.Quantity;
                                    TempComponentEntry.Modify();
                                end else
                                    TempComponentEntry.Insert();
                            end;
                        end;
                    ProdBOMComponent.Type::"Production BOM":
                        if ProdBOMHeader.Get(ProdBOMComponent."No.") then
                            BuildMatrix(
                                ProdBOMHeader."No.",
                                GetVersion(ProdBOMHeader."No."),
                                Level + 1,
                                Quantity * ProdBOMComponent.Quantity);
                end;
            until ProdBOMComponent.Next() = 0;
    end;

    local procedure GetVersion(ProdBOMNo: Code[20]): Code[20]
    begin
        ProdBOMVersion2.SetRange("Production BOM No.", ProdBOMNo);
        ProdBOMVersion2.SetFilter("Starting Date", '%1|..%2', 0D, GlobalCalcDate);
        if ProdBOMVersion2.FindLast() then
            exit(ProdBOMVersion2."Version Code");

        exit('');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBuildMatrixForItemOnAfterGetItem(var ProductionBOMLine: Record "Production BOM Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBuildMatrixForItemOnBeforeRecursion(var ProductionBOMLine: Record "Production BOM Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBuildMatrixForItemOnBeforeComponentListFind(var ProductionBOMLine: Record "Production BOM Line"; var ProductionMatrixBOMLine: Record "Production Matrix BOM Line")
    begin
    end;
}

