namespace Microsoft.Manufacturing.ProductionBOM;

using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;

codeunit 99000769 "Production BOM-Check"
{
    Permissions = TableData Item = r,
                  TableData "Routing Line" = r,
                  TableData "Manufacturing Setup" = r;
    TableNo = "Production BOM Header";

    trigger OnRun()
    begin
        Code(Rec, '');
    end;

    var
        Text000: Label 'Checking Item           #1########## @2@@@@@@@@@@@@@';
        Text001: Label 'The maximum number of BOM levels, %1, was exceeded. The process stopped at item number %2, BOM header number %3, BOM level %4.';
        Text003: Label '%1 with %2 %3 cannot be found. Check %4 %5 %6 %7.';
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        RtngLine: Record "Routing Line";
        MfgSetup: Record "Manufacturing Setup";
        VersionMgt: Codeunit VersionManagement;
        Window: Dialog;
        NoOfItems: Integer;
        ItemCounter: Integer;
        CircularRefInBOMErr: Label 'The production BOM %1 has a circular reference. Pay attention to the production BOM %2 that closes the loop.', Comment = '%1 = Production BOM No., %2 = Production BOM No.';

    procedure "Code"(var ProdBOMHeader: Record "Production BOM Header"; VersionCode: Code[20])
    var
        CalcLowLevel: Codeunit "Calculate Low-Level Code";
    begin
        ProdBOMHeader.TestField("Unit of Measure Code");
        MfgSetup.Get();
        if MfgSetup."Dynamic Low-Level Code" then begin
            CalcLowLevel.SetActualProdBOM(ProdBOMHeader);
            ProdBOMHeader."Low-Level Code" := CalcLowLevel.CalcLevels(2, ProdBOMHeader."No.", ProdBOMHeader."Low-Level Code", 1);
            CalcLowLevel.RecalcLowerLevels(ProdBOMHeader."No.", ProdBOMHeader."Low-Level Code", false);
            ProdBOMHeader.Modify();
        end else
            CheckBOM(ProdBOMHeader."No.", VersionCode);

        ProcessItems(ProdBOMHeader, VersionCode, CalcLowLevel);

        OnAfterCode(ProdBOMHeader, VersionCode);
    end;

    local procedure ProcessItems(var ProdBOMHeader: Record "Production BOM Header"; VersionCode: Code[20]; var CalcLowLevel: Codeunit "Calculate Low-Level Code")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeProcessItems(ProdBOMHeader, VersionCode, IsHandled);
        if IsHandled then
            exit;

        Item.SetCurrentKey("Production BOM No.");
        Item.SetRange("Production BOM No.", ProdBOMHeader."No.");

        OnProcessItemsOnAfterItemSetFilters(Item, ProdBOMHeader);
        if Item.Find('-') then begin
            OpenDialogWindow();
            NoOfItems := Item.Count();
            ItemCounter := 0;
            repeat
                ItemCounter := ItemCounter + 1;

                UpdateDialogWindow();
                if MfgSetup."Dynamic Low-Level Code" then
                    CalcLowLevel.Run(Item);
                if Item."Routing No." <> '' then
                    CheckBOMStructure(ProdBOMHeader."No.", VersionCode, 1);
                ItemUnitOfMeasure.Get(Item."No.", ProdBOMHeader."Unit of Measure Code");
            until Item.Next() = 0;
        end;
    end;

    local procedure OpenDialogWindow()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOpenDialogWindow(Window, IsHandled);
        if IsHandled then
            exit;

        if GuiAllowed() then
            Window.Open(Text000);
    end;

    local procedure UpdateDialogWindow()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateDialogWindow(Item, ItemCounter, NoOfItems, Window, IsHandled);
        if IsHandled then
            exit;

        if GuiAllowed() then begin
            Window.Update(1, Item."No.");
            Window.Update(2, Round(ItemCounter / NoOfItems * 10000, 1));
        end;
    end;

    procedure CheckBOMStructure(BOMHeaderNo: Code[20]; VersionCode: Code[20]; Level: Integer)
    var
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMComponent: Record "Production BOM Line";
    begin
        if Level > 99 then
            Error(
              Text001,
              99, BOMHeaderNo, Item."Production BOM No.", Level);

        ProdBOMHeader.Get(BOMHeaderNo);
        OnCheckBOMStructureOnAfterGetProdBOMHeader(ProdBOMHeader, VersionCode, Item);

        ProdBOMComponent.SetRange("Production BOM No.", BOMHeaderNo);
        ProdBOMComponent.SetRange("Version Code", VersionCode);
        ProdBOMComponent.SetFilter("No.", '<>%1', '');

        if ProdBOMComponent.Find('-') then
            repeat
                case ProdBOMComponent.Type of
                    ProdBOMComponent.Type::Item:
                        if ProdBOMComponent."Routing Link Code" <> '' then begin
                            Item.TestField("Routing No.");
                            RtngLine.SetRange("Routing No.", Item."Routing No.");
                            RtngLine.SetRange("Routing Link Code", ProdBOMComponent."Routing Link Code");
                            if not RtngLine.FindFirst() then
                                Error(
                                  Text003,
                                  RtngLine.TableCaption(),
                                  RtngLine.FieldCaption("Routing Link Code"),
                                  ProdBOMComponent."Routing Link Code",
                                  ProdBOMComponent.FieldCaption("Production BOM No."),
                                  ProdBOMComponent."Production BOM No.",
                                  ProdBOMComponent.FieldCaption("Line No."),
                                  ProdBOMComponent."Line No.");
                        end;
                    ProdBOMComponent.Type::"Production BOM":
                        CheckBOMStructure(
                          ProdBOMComponent."No.",
                          VersionMgt.GetBOMVersion(ProdBOMComponent."No.", WorkDate(), true), Level + 1);
                end;
            until ProdBOMComponent.Next() = 0;
    end;

    procedure ProdBOMLineCheck(ProdBOMNo: Code[20]; VersionCode: Code[20])
    var
        ProdBOMLine: Record "Production BOM Line";
    begin
        ProdBOMLine.SetRange("Production BOM No.", ProdBOMNo);
        ProdBOMLine.SetRange("Version Code", VersionCode);
        ProdBOMLine.SetFilter(Type, '<>%1', ProdBOMLine.Type::" ");
        ProdBOMLine.SetRange("No.", '');
        if ProdBOMLine.FindFirst() then
            ProdBOMLine.FieldError("No.");

        OnAfterProdBomLineCheck(ProdBOMLine, VersionCode);
    end;

    procedure CheckBOM(ProductionBOMNo: Code[20]; VersionCode: Code[20])
    var
        TempProductionBOMHeader: Record "Production BOM Header" temporary;
    begin
        TempProductionBOMHeader."No." := ProductionBOMNo;
        TempProductionBOMHeader.Insert();
        CheckCircularReferencesInProductionBOM(TempProductionBOMHeader, VersionCode);
    end;

    local procedure CheckCircularReferencesInProductionBOM(var TempProductionBOMHeader: Record "Production BOM Header" temporary; VersionCode: Code[20])
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProdItem: Record Item;
        ProductionBOMNo: Code[20];
        NextVersionCode: Code[20];
        CheckNextLevel: Boolean;
        IsHandled: Boolean;
    begin
        ProductionBOMLine.SetRange("Production BOM No.", TempProductionBOMHeader."No.");
        ProductionBOMLine.SetRange("Version Code", VersionCode);
        ProductionBOMLine.SetFilter("No.", '<>%1', '');
        OnCheckCircularReferencesInProductionBOMOnAfterProdBOMLineSetFilters(ProductionBOMLine, TempProductionBOMHeader, VersionCode);
        if ProductionBOMLine.FindSet() then
            repeat
                IsHandled := false;
                OnCheckCircularReferencesInProductionBOMOnBeforeProdBOMLineCheck(ProductionBOMLine, IsHandled);
                if not IsHandled then begin
                    if ProductionBOMLine.Type = ProductionBOMLine.Type::Item then begin
                        ProdItem.SetLoadFields("Production BOM No.");
                        ProdItem.Get(ProductionBOMLine."No.");
                        ProductionBOMNo := ProdItem."Production BOM No.";
                    end else
                        ProductionBOMNo := ProductionBOMLine."No.";

                    if ProductionBOMNo <> '' then begin
                        TempProductionBOMHeader."No." := ProductionBOMNo;
                        if not TempProductionBOMHeader.Insert() then
                            Error(CircularRefInBOMErr, ProductionBOMNo, ProductionBOMLine."Production BOM No.");

                        NextVersionCode := VersionMgt.GetBOMVersion(ProductionBOMNo, WorkDate(), true);
                        if NextVersionCode <> '' then
                            CheckNextLevel := true
                        else begin
                            ProductionBOMHeader.Get(ProductionBOMNo);
                            CheckNextLevel := ProductionBOMHeader.Status = ProductionBOMHeader.Status::Certified;
                        end;

                        if CheckNextLevel then
                            CheckCircularReferencesInProductionBOM(TempProductionBOMHeader, NextVersionCode);

                        TempProductionBOMHeader.Get(ProductionBOMNo);
                        TempProductionBOMHeader.Delete();
                    end;
                end;
            until ProductionBOMLine.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCode(var ProductionBOMHeader: Record "Production BOM Header"; VersionCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProdBomLineCheck(ProductionBOMLine: Record "Production BOM Line"; VersionCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenDialogWindow(var Window: Dialog; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessItems(var ProdBOMHeader: Record "Production BOM Header"; VersionCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateDialogWindow(var Item: Record Item; ItemCounter: Integer; NoOfItems: Integer; var Window: Dialog; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessItemsOnAfterItemSetFilters(var Item: Record Item; var ProductionBOMHeader: Record "Production BOM Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckCircularReferencesInProductionBOMOnAfterProdBOMLineSetFilters(var ProductionBOMLine: Record "Production BOM Line"; TempProductionBOMHeader: Record "Production BOM Header" temporary; VersionCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckCircularReferencesInProductionBOMOnBeforeProdBOMLineCheck(var ProductionBOMLine: Record "Production BOM Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckBOMStructureOnAfterGetProdBOMHeader(ProductionBOMHeader: Record "Production BOM Header"; var VersionCode: Code[20]; var Item: Record Item)
    begin
    end;
}

