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
        CalcLowLevel: Codeunit "Calculate Low-Level Code";
        Window: Dialog;
        NoOfItems: Integer;
        ItemCounter: Integer;

    procedure "Code"(var ProdBOMHeader: Record "Production BOM Header"; VersionCode: Code[20])
    begin
        ProdBOMHeader.TestField("Unit of Measure Code");
        MfgSetup.Get();
        if MfgSetup."Dynamic Low-Level Code" then begin
            CalcLowLevel.SetActualProdBOM(ProdBOMHeader);
            ProdBOMHeader."Low-Level Code" := CalcLowLevel.CalcLevels(2, ProdBOMHeader."No.", ProdBOMHeader."Low-Level Code", 1);
            CalcLowLevel.RecalcLowerLevels(ProdBOMHeader."No.", ProdBOMHeader."Low-Level Code", false);
            ProdBOMHeader.Modify();
        end;

        Item.SetCurrentKey("Production BOM No.");
        Item.SetRange("Production BOM No.", ProdBOMHeader."No.");

        if Item.Find('-') then begin
            if GuiAllowed then
                Window.Open(Text000);
            NoOfItems := Item.Count();
            ItemCounter := 0;
            repeat
                ItemCounter := ItemCounter + 1;

                if GuiAllowed then begin
                    Window.Update(1, Item."No.");
                    Window.Update(2, Round(ItemCounter / NoOfItems * 10000, 1));
                end;
                if MfgSetup."Dynamic Low-Level Code" then
                    CalcLowLevel.Run(Item);
                if Item."Routing No." <> '' then
                    CheckBOMStructure(ProdBOMHeader."No.", VersionCode, 1);
                ItemUnitOfMeasure.Get(Item."No.", ProdBOMHeader."Unit of Measure Code");
            until Item.Next = 0;
        end;

        OnAfterCode(ProdBOMHeader, VersionCode);
    end;

    local procedure CheckBOMStructure(BOMHeaderNo: Code[20]; VersionCode: Code[20]; Level: Integer)
    var
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMComponent: Record "Production BOM Line";
    begin
        if Level > 99 then
            Error(
              Text001,
              99, BOMHeaderNo, Item."Production BOM No.", Level);

        ProdBOMHeader.Get(BOMHeaderNo);

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
                            if not RtngLine.FindFirst then
                                Error(
                                  Text003,
                                  RtngLine.TableCaption,
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
                          VersionMgt.GetBOMVersion(ProdBOMComponent."No.", WorkDate, true), Level + 1);
                end;
            until ProdBOMComponent.Next = 0;
    end;

    procedure ProdBOMLineCheck(ProdBOMNo: Code[20]; VersionCode: Code[20])
    var
        ProdBOMLine: Record "Production BOM Line";
    begin
        ProdBOMLine.SetRange("Production BOM No.", ProdBOMNo);
        ProdBOMLine.SetRange("Version Code", VersionCode);
        ProdBOMLine.SetFilter(Type, '<>%1', ProdBOMLine.Type::" ");
        ProdBOMLine.SetRange("No.", '');
        if ProdBOMLine.FindFirst then
            ProdBOMLine.FieldError("No.");

        OnAfterProdBomLineCheck(ProdBOMLine, VersionCode);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCode(var ProductionBOMHeader: Record "Production BOM Header"; VersionCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProdBomLineCheck(ProductionBOMLine: Record "Production BOM Line"; VersionCode: Code[20])
    begin
    end;
}

