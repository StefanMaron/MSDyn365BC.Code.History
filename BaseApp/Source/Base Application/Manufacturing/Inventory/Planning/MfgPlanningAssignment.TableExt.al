namespace Microsoft.Inventory.Planning;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Document;

tableextension 99000850 "Mfg. Planning Assignment" extends "Planning Assignment"
{
    procedure RoutingReplace(var Item: Record Item; OldRoutingNo: Code[20])
    begin
        if OldRoutingNo <> Item."Routing No." then
            if Item."Reordering Policy" <> Item."Reordering Policy"::" " then
                AssignPlannedOrders(Item."No.", false);
    end;

    procedure BomReplace(var Item: Record Item; OldProductionBOMNo: Code[20])
    begin
        if OldProductionBOMNo <> Item."Production BOM No." then begin
            if Item."Reordering Policy" <> Item."Reordering Policy"::" " then
                AssignPlannedOrders(Item."No.", false);
            if OldProductionBOMNo <> '' then
                OldBom(OldProductionBOMNo);
        end;
    end;

    procedure OldBom(ProductionBOMNo: Code[20])
    var
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMVersion: Record "Production BOM Version";
        ProductionBOMLine: Record "Production BOM Line";
        UseVersions: Boolean;
        EndLoop: Boolean;
    begin
        ProductionBOMVersion.SetRange("Production BOM No.", ProductionBOMNo);
        ProductionBOMVersion.SetRange(Status, ProductionBOMVersion.Status::Certified);
        UseVersions := ProductionBOMVersion.FindSet();

        if ProductionBOMHeader.Get(ProductionBOMNo) and
           (ProductionBOMHeader.Status = ProductionBOMHeader.Status::Certified)
        then begin
            ProductionBOMVersion."Production BOM No." := ProductionBOMHeader."No.";
            ProductionBOMVersion."Version Code" := '';
        end else
            if not ProductionBOMVersion.FindSet() then
                exit;

        repeat
            ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMVersion."Production BOM No.");
            ProductionBOMLine.SetRange("Version Code", ProductionBOMVersion."Version Code");
            if ProductionBOMLine.FindSet() then
                repeat
                    if ProductionBOMLine.Type = ProductionBOMLine.Type::Item then begin
                        if Item.Get(ProductionBOMLine."No.") then
                            if Item."Reordering Policy" <> Item."Reordering Policy"::" " then
                                AssignPlannedOrders(ProductionBOMLine."No.", false);
                    end else
                        if ProductionBOMLine.Type = ProductionBOMLine.Type::"Production BOM" then
                            OldBom(ProductionBOMLine."No.");
                until ProductionBOMLine.Next() = 0;
            if UseVersions then
                EndLoop := ProductionBOMVersion.Next() = 0
            else
                EndLoop := true;
        until EndLoop;
    end;

    procedure NewBOM(ProductionBOMNo: Code[20])
    var
        Item: Record Item;
    begin
        Item.SetCurrentKey("Production BOM No.");
        Item.SetRange("Production BOM No.", ProductionBOMNo);
        if Item.FindSet() then
            repeat
                if Item."Reordering Policy" <> Item."Reordering Policy"::" " then
                    AssignPlannedOrders(Item."No.", false);
            until Item.Next() = 0;
    end;

    procedure AssignPlannedOrders(ItemNo: Code[20]; CheckSKU: Boolean)
    var
        ProdOrderLine: Record "Prod. Order Line";
        ReqLine: Record "Requisition Line";
        AssignThis: Boolean;
    begin
        ProdOrderLine.SetCurrentKey(Status, "Item No.", "Variant Code", "Location Code");
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Planned);
        ProdOrderLine.SetRange("Item No.", ItemNo);
        if ProdOrderLine.FindSet(true) then
            repeat
                if CheckSKU then
                    AssignThis := not SKUExists(ProdOrderLine."Item No.", ProdOrderLine."Variant Code", ProdOrderLine."Location Code")
                else
                    AssignThis := true;
                if AssignThis then
                    AssignOne(ProdOrderLine."Item No.", ProdOrderLine."Variant Code", ProdOrderLine."Location Code", WorkDate());
                ProdOrderLine.SetRange("Variant Code", ProdOrderLine."Variant Code");
                ProdOrderLine.SetRange("Location Code", ProdOrderLine."Location Code");
                ProdOrderLine.FindLast();
                ProdOrderLine.SetRange("Variant Code");
                ProdOrderLine.SetRange("Location Code");
            until ProdOrderLine.Next() = 0;

        ReqLine.SetCurrentKey(Type, "No.", "Variant Code", "Location Code");
        ReqLine.SetRange(Type, ReqLine.Type::Item);
        ReqLine.SetRange("No.", ItemNo);
        if ReqLine.FindSet(true) then
            repeat
                if CheckSKU then
                    AssignThis := not SKUExists(ReqLine."No.", ReqLine."Variant Code", ReqLine."Location Code")
                else
                    AssignThis := true;
                if AssignThis then
                    AssignOne(ReqLine."No.", ReqLine."Variant Code", ReqLine."Location Code", WorkDate());
                ReqLine.SetRange("Variant Code", ReqLine."Variant Code");
                ReqLine.SetRange("Location Code", ReqLine."Location Code");
                ReqLine.FindLast();
                ReqLine.SetRange("Variant Code");
                ReqLine.SetRange("Location Code");
            until ReqLine.Next() = 0;
    end;


}