namespace Microsoft.Inventory.Planning;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Setup;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Setup;

table 99000850 "Planning Assignment"
{
    Caption = 'Planning Assignment';
    Permissions = TableData "Planning Assignment" = rimd;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item."No.";
        }
        field(2; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(3; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(10; "Latest Date"; Date)
        {
            Caption = 'Latest Date';
        }
        field(12; Inactive; Boolean)
        {
            Caption = 'Inactive';
        }
        field(13; "Action Msg. Response Planning"; Boolean)
        {
            Caption = 'Action Msg. Response Planning';

            trigger OnValidate()
            begin
                if "Action Msg. Response Planning" then
                    Inactive := false;
            end;
        }
        field(14; "Net Change Planning"; Boolean)
        {
            Caption = 'Net Change Planning';

            trigger OnValidate()
            begin
                if "Net Change Planning" then
                    Inactive := false;
            end;
        }
    }

    keys
    {
        key(Key1; "Item No.", "Variant Code", "Location Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        ManufacturingSetup: Record "Manufacturing Setup";
        InvtSetup: Record "Inventory Setup";

    procedure ItemChange(var NewItem: Record Item; var OldItem: Record Item)
    begin
        if NewItem."Reordering Policy" = NewItem."Reordering Policy"::" " then
            if OldItem."Reordering Policy" <> OldItem."Reordering Policy"::" " then
                AnnulAllAssignment(NewItem."No.")
            else
                exit
        else
            if PlanningParametersChanged(NewItem, OldItem) then begin
                ManufacturingSetup.Get();
                InvtSetup.Get();
                if (ManufacturingSetup."Components at Location" <> '') or
                   not InvtSetup."Location Mandatory"
                then
                    AssignOne(NewItem."No.", '', ManufacturingSetup."Components at Location", WorkDate());
            end;

    end;

    local procedure PlanningParametersChanged(NewItem: Record Item; OldItem: Record Item) Result: Boolean
    begin
        Result := (NewItem."Safety Stock Quantity" <> OldItem."Safety Stock Quantity") or
               (NewItem."Safety Lead Time" <> OldItem."Safety Lead Time") or
               (NewItem."Lead Time Calculation" <> OldItem."Lead Time Calculation") or
               (NewItem."Reorder Point" <> OldItem."Reorder Point") or
               (NewItem."Reordering Policy" <> OldItem."Reordering Policy") or
               (NewItem."Replenishment System" <> OldItem."Replenishment System") or
               (NewItem."Include Inventory" <> OldItem."Include Inventory");
        OnAfterPlanningParametersChanged(NewItem, OldItem, Result);
    end;

    procedure SKUChange(var NewSKU: Record "Stockkeeping Unit"; var OldSKU: Record "Stockkeeping Unit")
    begin
        if NewSKU."Reordering Policy" = NewSKU."Reordering Policy"::" " then
            if OldSKU."Reordering Policy" <> OldSKU."Reordering Policy"::" " then begin
                SetRange("Item No.", NewSKU."Item No.");
                SetRange("Variant Code", NewSKU."Variant Code");
                SetRange("Location Code", NewSKU."Location Code");
                if Find() then begin
                    "Net Change Planning" := false;
                    Modify();
                end;
            end else
                exit
        else
            if PlanningSKUParametersChanged(NewSKU, OldSKU) then
                AssignOne(NewSKU."Item No.", NewSKU."Variant Code", NewSKU."Location Code", WorkDate());
    end;

    local procedure PlanningSKUParametersChanged(NewSKU: Record "Stockkeeping Unit"; OldSKU: Record "Stockkeeping Unit") Result: Boolean
    begin
        Result := (NewSKU."Safety Stock Quantity" <> OldSKU."Safety Stock Quantity") or
                (NewSKU."Safety Lead Time" <> OldSKU."Safety Lead Time") or
                (NewSKU."Lead Time Calculation" <> OldSKU."Lead Time Calculation") or
                (NewSKU."Reorder Point" <> OldSKU."Reorder Point") or
                (NewSKU."Reordering Policy" <> OldSKU."Reordering Policy") or
                (NewSKU."Replenishment System" <> OldSKU."Replenishment System") or
                (NewSKU."Include Inventory" <> OldSKU."Include Inventory");

        OnAfterPlanningSKUParametersChanged(NewSKU, OldSKU, Result);
    end;

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
                    AssignThis := not SKUexists(ProdOrderLine."Item No.", ProdOrderLine."Variant Code", ProdOrderLine."Location Code")
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
                    AssignThis := not SKUexists(ReqLine."No.", ReqLine."Variant Code", ReqLine."Location Code")
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

    procedure AssignOne(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; UpdateDate: Date)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAssignOne(IsHandled);
        if IsHandled then
            exit;

        LockTable();
        "Item No." := ItemNo;
        "Variant Code" := VariantCode;
        "Location Code" := LocationCode;
        if Find() then begin
            Validate("Net Change Planning", true);
            if UpdateDate > "Latest Date" then
                "Latest Date" := UpdateDate;
            Modify();
        end else begin
            Init();
            Validate("Net Change Planning", true);
            "Latest Date" := UpdateDate;
            Insert();
        end
    end;

    procedure ChkAssignOne(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; UpdateDate: Date)
    var
        Item: Record Item;
        SKU: Record "Stockkeeping Unit";
        ReorderingPolicy: Enum "Reordering Policy";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeChkAssignOne(ItemNo, VariantCode, LocationCode, UpdateDate, IsHandled);
        if IsHandled then
            exit;

        ReorderingPolicy := Item."Reordering Policy"::" ";

        if SKU.Get(LocationCode, ItemNo, VariantCode) then
            ReorderingPolicy := SKU."Reordering Policy"
        else
            if Item.Get(ItemNo) then
                ReorderingPolicy := Item."Reordering Policy";

        if ReorderingPolicy <> Item."Reordering Policy"::" " then
            AssignOne(ItemNo, VariantCode, LocationCode, UpdateDate);
    end;

    local procedure AnnulAllAssignment(ItemNo: Code[20])
    begin
        SetRange("Item No.", ItemNo);
        ModifyAll("Net Change Planning", false);
    end;

    local procedure SKUexists(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]): Boolean
    var
        SKU: Record "Stockkeeping Unit";
    begin
        SKU.SetRange("Item No.", ItemNo);
        SKU.SetRange("Variant Code", VariantCode);
        SKU.SetRange("Location Code", LocationCode);
        exit(not SKU.IsEmpty);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPlanningParametersChanged(NewItem: Record Item; OldItem: Record Item; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPlanningSKUParametersChanged(NewSKU: Record "Stockkeeping Unit"; OldSKU: Record "Stockkeeping Unit"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeChkAssignOne(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; UpdateDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssignOne(var IsHandled: Boolean)
    begin
    end;
}

