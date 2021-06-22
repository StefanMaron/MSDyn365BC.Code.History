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
        ComponentList: Record "Production Matrix BOM Line" temporary;
        ComponentEntry: Record "Production Matrix  BOM Entry" temporary;
        ComponentEntry2: Record "Production Matrix  BOM Entry";
        UOMMgt: Codeunit "Unit of Measure Management";
        VersionMgt: Codeunit VersionManagement;
        GlobalCalcDate: Date;
        MatrixType: Option Version,Item;
        MultiLevel: Boolean;

    procedure FindRecord(Which: Text[30]; var ComponentList2: Record "Production Matrix BOM Line"): Boolean
    begin
        ComponentList := ComponentList2;
        if not ComponentList.Find(Which) then
            exit(false);
        ComponentList2 := ComponentList;
        exit(true);
    end;

    procedure NextRecord(Steps: Integer; var ComponentList2: Record "Production Matrix BOM Line"): Integer
    var
        CurrentSteps: Integer;
    begin
        ComponentList := ComponentList2;
        CurrentSteps := ComponentList.Next(Steps);
        if CurrentSteps <> 0 then
            ComponentList2 := ComponentList;
        exit(CurrentSteps);
    end;

    procedure GetComponentNeed(No: Code[20]; VariantCode: Code[10]; ID: Code[20]): Decimal
    begin
        ComponentEntry.SetRange("Item No.", No);
        ComponentEntry.SetRange("Variant Code", VariantCode);
        ComponentEntry.SetRange(ID, ID);
        if not ComponentEntry.FindFirst then
            Clear(ComponentEntry);

        exit(ComponentEntry.Quantity);
    end;

    procedure CompareTwoItems(Item1: Record Item; Item2: Record Item; CalcDate: Date; NewMultiLevel: Boolean; var VersionCode1: Code[20]; var VersionCode2: Code[20]; var UnitOfMeasure1: Code[10]; var UnitOfMeasure2: Code[10])
    begin
        GlobalCalcDate := CalcDate;

        ComponentList.DeleteAll();
        ComponentEntry.Reset();
        ComponentEntry.DeleteAll();

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
        ComponentList.DeleteAll();
        ComponentEntry.Reset();
        ComponentEntry.DeleteAll();

        MultiLevel := NewMultiLevel;
        MatrixType := MatrixType::Version;
        BuildMatrix(ProdBOM."No.", '', 1, 1);
        ProdBOMVersion.SetRange("Production BOM No.", ProdBOM."No.");

        if ProdBOMVersion.Find('-') then
            repeat
                GlobalCalcDate := ProdBOMVersion."Starting Date";
                BuildMatrix(ProdBOM."No.", ProdBOMVersion."Version Code", 1, 1);
            until ProdBOMVersion.Next = 0;
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
                                ComponentList."Item No." := ProdBOMComponent."No.";
                                ComponentList."Variant Code" := ProdBOMComponent."Variant Code";
                                ComponentList.Description := ProdBOMComponent.Description;
                                ComponentList."Unit of Measure Code" := Item."Base Unit of Measure";
                                OnBuildMatrixForItemOnBeforeComponentListFind(ProdBOMComponent, ComponentList);
                                if not ComponentList.Find then
                                    ComponentList.Insert();
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
                                ComponentEntry := ComponentEntry2;
                                ComponentEntry.SetRange("Item No.", ComponentEntry2."Item No.");
                                ComponentEntry.SetRange("Variant Code", ComponentEntry2."Variant Code");
                                ComponentEntry.SetRange(ID, ComponentEntry2.ID);
                                if ComponentEntry.FindFirst then begin
                                    ComponentEntry.Quantity :=
                                      ComponentEntry.Quantity + ComponentEntry2.Quantity;
                                    ComponentEntry.Modify();
                                end else
                                    ComponentEntry.Insert();
                            end;
                        end;
                    ProdBOMComponent.Type::"Production BOM":
                        begin
                            if ProdBOMHeader.Get(ProdBOMComponent."No.") then
                                BuildMatrix(
                                  ProdBOMHeader."No.",
                                  GetVersion(ProdBOMHeader."No."),
                                  Level + 1,
                                  Quantity * ProdBOMComponent.Quantity);
                        end;
                end;
            until ProdBOMComponent.Next = 0;
    end;

    local procedure GetVersion(ProdBOMNo: Code[20]): Code[20]
    begin
        ProdBOMVersion2.SetRange("Production BOM No.", ProdBOMNo);
        ProdBOMVersion2.SetFilter("Starting Date", '%1|..%2', 0D, GlobalCalcDate);
        if ProdBOMVersion2.FindLast then
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

