namespace Microsoft.Inventory.Item.Substitution;

using Microsoft.Assembly.Document;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Manufacturing.Document;
using Microsoft.Sales.Document;

codeunit 5701 "Item Subst."
{

    Permissions = TableData "Item Substitution" = rimd;

    trigger OnRun()
    begin
    end;

    var
        Item: Record Item;
        ItemSubstitution: Record "Item Substitution";
        TempItemSubstitution: Record "Item Substitution" temporary;
        SalesHeader: Record "Sales Header";
        NonStockItem: Record "Nonstock Item";
        TempSalesLine: Record "Sales Line" temporary;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        CompanyInfo: Record "Company Information";
        ProdOrderCompSubst: Record "Prod. Order Component";
        CatalogItemMgt: Codeunit "Catalog Item Management";
        AvailToPromise: Codeunit "Available to Promise";
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        UOMMgt: Codeunit "Unit of Measure Management";
        SaveDropShip: Boolean;
        SetupDataIsPresent: Boolean;
        GrossReq: Decimal;
        SchedRcpt: Decimal;
        SaveQty: Decimal;
        SaveItemNo: Code[20];
        SaveVariantCode: Code[10];
        SaveLocation: Code[10];
        OldSalesUOM: Code[10];

#pragma warning disable AA0470
#pragma warning disable AA0074
        Text001: Label 'An Item Substitution with the specified variant does not exist for Item No. ''%1''.';
        Text002: Label 'An Item Substitution does not exist for Item No. ''%1''';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure ItemSubstGet(var SalesLine: Record "Sales Line") Found: Boolean
    var
        SalesLineReserve: Codeunit "Sales Line-Reserve";
        IsHandled: Boolean;
    begin
        TempSalesLine := SalesLine;
        if (TempSalesLine.Type <> TempSalesLine.Type::Item) or
           (TempSalesLine."Document Type" in
            [TempSalesLine."Document Type"::"Return Order", TempSalesLine."Document Type"::"Credit Memo"])
        then
            exit;

        SaveItemNo := TempSalesLine."No.";
        SaveVariantCode := TempSalesLine."Variant Code";

        Item.Get(TempSalesLine."No.");
        Item.SetFilter("Location Filter", TempSalesLine."Location Code");
        Item.SetFilter("Variant Filter", TempSalesLine."Variant Code");
        Item.SetRange("Date Filter", 0D, TempSalesLine."Shipment Date");
        Item.CalcFields(Inventory);
        Item.CalcFields("Qty. on Sales Order");
        SaveItemSalesUOM(Item);

        ItemSubstitution.Reset();
        ItemSubstitution.SetRange(Type, ItemSubstitution.Type::Item);
        ItemSubstitution.SetRange("No.", TempSalesLine."No.");
        ItemSubstitution.SetRange("Variant Code", TempSalesLine."Variant Code");
        ItemSubstitution.SetRange("Location Filter", TempSalesLine."Location Code");
        OnItemSubstGetOnAfterItemSubstitutionSetFilters(ItemSubstitution);
        if ItemSubstitution.Find('-') then begin
            CalcCustPrice(TempItemSubstitution, ItemSubstitution, TempSalesLine);
            TempItemSubstitution.Reset();
            TempItemSubstitution.SetRange("No.", TempSalesLine."No.");
            TempItemSubstitution.SetRange("Variant Code", TempSalesLine."Variant Code");
            TempItemSubstitution.SetRange("Location Filter", TempSalesLine."Location Code");
            IsHandled := false;
            OnItemSubstGetOnAfterTempItemSubstitutionSetFilters(TempItemSubstitution, SalesLine, TempSalesLine, OldSalesUOM, IsHandled);
            if not IsHandled then
                if PAGE.RunModal(PAGE::"Item Substitution Entries", TempItemSubstitution) =
                ACTION::LookupOK
                then begin
                    if TempItemSubstitution."Substitute Type" =
                    TempItemSubstitution."Substitute Type"::"Nonstock Item"
                    then begin
                        NonStockItem.Get(TempItemSubstitution."Substitute No.");
                        if NonStockItem."Item No." = '' then begin
                            CatalogItemMgt.CreateItemFromNonstock(NonStockItem);
                            NonStockItem.Get(TempItemSubstitution."Substitute No.");
                        end;
                        TempItemSubstitution."Substitute No." := NonStockItem."Item No."
                    end;
                    ItemSubstGetPopulateTempSalesLine(SalesLine);

                    Commit();
                    if ItemCheckAvail.SalesLineCheck(TempSalesLine) then
                        TempSalesLine := SalesLine;
                end;
        end else
            Error(Text001, TempSalesLine."No.");

        Found := (SalesLine."No." <> TempSalesLine."No.") or (SalesLine."Variant Code" <> TempSalesLine."Variant Code");
        if Found then
            SalesLineReserve.DeleteLine(SalesLine);

        SalesLine := TempSalesLine;
        OnAfterItemSubstGet(SalesLine, TempSalesLine);
    end;

    local procedure ItemSubstGetPopulateTempSalesLine(var SalesLine: Record "Sales Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeItemSubstGetPopulateTempSalesLine(TempSalesLine, TempItemSubstitution, IsHandled, SaveItemNo, SaveVariantCode);
        if IsHandled then
            exit;

        TempSalesLine."No." := TempItemSubstitution."Substitute No.";
        TempSalesLine."Variant Code" := TempItemSubstitution."Substitute Variant Code";
        SaveQty := TempSalesLine.Quantity;
        SaveLocation := TempSalesLine."Location Code";
        SaveDropShip := TempSalesLine."Drop Shipment";
        TempSalesLine.Quantity := 0;
        TempSalesLine.Validate("No.", TempItemSubstitution."Substitute No.");
        TempSalesLine.Validate("Variant Code", TempItemSubstitution."Substitute Variant Code");
        TempSalesLine."Originally Ordered No." := SaveItemNo;
        TempSalesLine."Originally Ordered Var. Code" := SaveVariantCode;
        TempSalesLine."Location Code" := SaveLocation;
        TempSalesLine."Drop Shipment" := SaveDropShip;
        TempSalesLine.Validate(Quantity, SaveQty);
        TempSalesLine.Validate("Unit of Measure Code", OldSalesUOM);

        TempSalesLine.CreateDimFromDefaultDim(0);

        OnItemSubstGetOnAfterSubstSalesLineItem(TempSalesLine, SalesLine, TempItemSubstitution);
    end;

    procedure CalcCustPrice(var TempItemSubstitution: Record "Item Substitution" temporary; var ItemSubstitution: Record "Item Substitution"; var TempSalesLine: Record "Sales Line" temporary)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcCustPrice(TempItemSubstitution, TempSalesLine, IsHandled, Item);
        if IsHandled then
            exit;

        TempItemSubstitution.Reset();
        TempItemSubstitution.DeleteAll();
        SalesHeader.Get(TempSalesLine."Document Type", TempSalesLine."Document No.");
        if ItemSubstitution.Find('-') then
            repeat
                TempItemSubstitution."No." := ItemSubstitution."No.";
                TempItemSubstitution."Variant Code" := ItemSubstitution."Variant Code";
                TempItemSubstitution."Substitute No." := ItemSubstitution."Substitute No.";
                TempItemSubstitution."Substitute Variant Code" := ItemSubstitution."Substitute Variant Code";
                TempItemSubstitution.Description := ItemSubstitution.Description;
                TempItemSubstitution.Interchangeable := ItemSubstitution.Interchangeable;
                TempItemSubstitution."Location Filter" := ItemSubstitution."Location Filter";
                TempItemSubstitution.Condition := ItemSubstitution.Condition;
                TempItemSubstitution."Shipment Date" := TempSalesLine."Shipment Date";
                if ItemSubstitution."Substitute Type" = ItemSubstitution."Substitute Type"::Item then begin
                    Item.Get(ItemSubstitution."Substitute No.");
                    if not SetupDataIsPresent then
                        GetSetupData();
                    OnCalcCustPriceOnBeforeCalcQtyAvail(Item, TempSalesLine, TempItemSubstitution, ItemSubstitution);
                    TempItemSubstitution."Quantity Avail. on Shpt. Date" :=
                      AvailToPromise.CalcQtyAvailabletoPromise(
                        Item, GrossReq, SchedRcpt,
                        Item.GetRangeMax("Date Filter"), CompanyInfo."Check-Avail. Time Bucket",
                        CompanyInfo."Check-Avail. Period Calc.");
                    Item.CalcFields(Inventory);
                    OnCalcCustPriceOnAfterCalcQtyAvail(Item, TempSalesLine, TempItemSubstitution);
                    TempItemSubstitution.Inventory := Item.Inventory;
                end else begin
                    TempItemSubstitution."Substitute Type" := TempItemSubstitution."Substitute Type"::"Nonstock Item";
                    TempItemSubstitution."Quantity Avail. on Shpt. Date" := 0;
                    TempItemSubstitution.Inventory := 0;
                end;
                OnCalcCustPriceOnBeforeTempItemSubstitutionInsert(TempItemSubstitution, ItemSubstitution);
                TempItemSubstitution.Insert();
            until ItemSubstitution.Next() = 0;
    end;

    local procedure AssemblyCalcCustPrice(AssemblyLine: Record "Assembly Line")
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        TempItemSubstitution.Reset();
        TempItemSubstitution.DeleteAll();
        AssemblyHeader.Get(AssemblyLine."Document Type", AssemblyLine."Document No.");
        if ItemSubstitution.Find('-') then
            repeat
                TempItemSubstitution."No." := ItemSubstitution."No.";
                TempItemSubstitution."Variant Code" := ItemSubstitution."Variant Code";
                TempItemSubstitution."Substitute No." := ItemSubstitution."Substitute No.";
                TempItemSubstitution."Substitute Variant Code" := ItemSubstitution."Substitute Variant Code";
                TempItemSubstitution.Description := ItemSubstitution.Description;
                TempItemSubstitution.Interchangeable := ItemSubstitution.Interchangeable;
                TempItemSubstitution."Location Filter" := ItemSubstitution."Location Filter";
                TempItemSubstitution.Condition := ItemSubstitution.Condition;
                TempItemSubstitution."Shipment Date" := TempSalesLine."Shipment Date";
                if ItemSubstitution."Substitute Type" = ItemSubstitution."Substitute Type"::Item then begin
                    Item.Get(ItemSubstitution."Substitute No.");
                    if not SetupDataIsPresent then
                        GetSetupData();
                    OnAssemblyCalcCustPriceOnBeforeCalcQtyAvail(Item, AssemblyLine, TempItemSubstitution);
                    TempItemSubstitution."Quantity Avail. on Shpt. Date" :=
                      AvailToPromise.CalcQtyAvailabletoPromise(
                        Item, GrossReq, SchedRcpt,
                        Item.GetRangeMax("Date Filter"), CompanyInfo."Check-Avail. Time Bucket",
                        CompanyInfo."Check-Avail. Period Calc.");
                    Item.CalcFields(Inventory);
                    OnAssemblyCalcCustPriceOnAfterCalcQtyAvail(Item, AssemblyLine, TempItemSubstitution);
                    TempItemSubstitution.Inventory := Item.Inventory;
                end else begin
                    TempItemSubstitution."Substitute Type" := TempItemSubstitution."Substitute Type"::"Nonstock Item";
                    TempItemSubstitution."Quantity Avail. on Shpt. Date" := 0;
                    TempItemSubstitution.Inventory := 0;
                end;
                TempItemSubstitution.Insert();
            until ItemSubstitution.Next() = 0;
    end;

#if not CLEAN25
    [Obsolete('Moved to codeunit ServItemSubstitution', '25.0')]
    procedure ItemServiceSubstGet(var ServiceLine2: Record Microsoft.Service.Document."Service Line")
    var
        ServItemSubstitution: Codeunit Microsoft.Service.Item."Serv. Item Substitution";
    begin
        ServItemSubstitution.ItemServiceSubstGet(ServiceLine2);
    end;
#endif

    local procedure GetSetupData()
    begin
        CompanyInfo.Get();
        SetupDataIsPresent := true;
    end;

    procedure GetCompSubst(var ProdOrderComp: Record "Prod. Order Component")
    begin
        ProdOrderCompSubst := ProdOrderComp;

        if not PrepareSubstList(
             ProdOrderComp."Item No.",
             ProdOrderComp."Variant Code",
             ProdOrderComp."Location Code",
             ProdOrderComp."Due Date",
             true)
        then
            ErrorMessage(ProdOrderComp."Item No.", ProdOrderComp."Variant Code");

        OnGetCompSubstOnAfterCheckPrepareSubstList(ProdOrderComp, TempItemSubstitution, Item, GrossReq, SchedRcpt);

        TempItemSubstitution.Reset();
        TempItemSubstitution.SetRange("Variant Code", ProdOrderComp."Variant Code");
        TempItemSubstitution.SetRange("Location Filter", ProdOrderComp."Location Code");
        if TempItemSubstitution.Find('-') then;
        if PAGE.RunModal(PAGE::"Item Substitution Entries", TempItemSubstitution) = ACTION::LookupOK then
            UpdateComponent(ProdOrderComp, TempItemSubstitution."Substitute No.", TempItemSubstitution."Substitute Variant Code");

        OnAfterGetCompSubst(ProdOrderComp, TempItemSubstitution);
    end;

    procedure UpdateComponent(var ProdOrderComp: Record "Prod. Order Component"; SubstItemNo: Code[20]; SubstVariantCode: Code[10])
    var
        TempProdOrderComp: Record "Prod. Order Component" temporary;
        ProdOrderCompReserve: Codeunit "Prod. Order Comp.-Reserve";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateComponent(ProdOrderComp, SubstItemNo, SubstVariantCode, IsHandled);
        if IsHandled then
            exit;

        if (ProdOrderComp."Item No." <> SubstItemNo) or (ProdOrderComp."Variant Code" <> SubstVariantCode) then
            ProdOrderCompReserve.DeleteLine(ProdOrderComp);

        TempProdOrderComp := ProdOrderComp;

        SaveQty := TempProdOrderComp."Quantity per";

        TempProdOrderComp."Item No." := SubstItemNo;
        TempProdOrderComp."Variant Code" := SubstVariantCode;
        TempProdOrderComp."Location Code" := ProdOrderComp."Location Code";
        TempProdOrderComp."Quantity per" := 0;
        TempProdOrderComp.Validate("Item No.");
        TempProdOrderComp.Validate("Variant Code");

        TempProdOrderComp."Original Item No." := ProdOrderComp."Item No.";
        TempProdOrderComp."Original Variant Code" := ProdOrderComp."Variant Code";

        if ProdOrderComp."Qty. per Unit of Measure" <> 1 then
            if ItemUnitOfMeasure.Get(Item."No.", ProdOrderComp."Unit of Measure Code") and
               (ItemUnitOfMeasure."Qty. per Unit of Measure" = ProdOrderComp."Qty. per Unit of Measure")
            then
                TempProdOrderComp.Validate("Unit of Measure Code", ProdOrderComp."Unit of Measure Code")
            else
                SaveQty :=
                  Round(ProdOrderComp."Quantity per" * ProdOrderComp."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
        TempProdOrderComp.Validate("Quantity per", SaveQty);

        OnAfterUpdateComponentBeforeAssign(ProdOrderComp, TempProdOrderComp);

        ProdOrderComp := TempProdOrderComp;
    end;

    procedure PrepareSubstList(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; DemandDate: Date; CalcATP: Boolean): Boolean
    begin
        Item.Get(ItemNo);
        Item.SetFilter("Location Filter", LocationCode);
        Item.SetFilter("Variant Filter", VariantCode);
        Item.SetRange("Date Filter", 0D, DemandDate);

        ItemSubstitution.Reset();
        ItemSubstitution.SetRange(Type, ItemSubstitution.Type::Item);
        ItemSubstitution.SetRange("No.", ItemNo);
        ItemSubstitution.SetRange("Variant Code", VariantCode);
        ItemSubstitution.SetRange("Location Filter", LocationCode);
        if ItemSubstitution.Find('-') then begin
            TempItemSubstitution.DeleteAll();
            CreateSubstList(ItemNo, ItemSubstitution, 1, DemandDate, CalcATP);
            exit(true);
        end;

        exit(false);
    end;

    local procedure CreateSubstList(OrgNo: Code[20]; var ItemSubstitution3: Record "Item Substitution"; RelationsLevel: Integer; DemandDate: Date; CalcATP: Boolean)
    var
        ItemSubstitution: Record "Item Substitution";
        ItemSubstitution2: Record "Item Substitution";
        ODF: DateFormula;
        RelationsLevel2: Integer;
    begin
        ItemSubstitution.Copy(ItemSubstitution3);
        RelationsLevel2 := RelationsLevel;

        if ItemSubstitution.Find('-') then
            repeat
                Clear(TempItemSubstitution);
                TempItemSubstitution.Type := ItemSubstitution.Type;
                TempItemSubstitution."No." := ItemSubstitution."No.";
                TempItemSubstitution."Variant Code" := ItemSubstitution."Variant Code";
                TempItemSubstitution."Substitute Type" := ItemSubstitution."Substitute Type";
                TempItemSubstitution."Substitute No." := ItemSubstitution."Substitute No.";
                TempItemSubstitution."Substitute Variant Code" := ItemSubstitution."Substitute Variant Code";
                TempItemSubstitution.Description := ItemSubstitution.Description;
                TempItemSubstitution.Interchangeable := ItemSubstitution.Interchangeable;
                TempItemSubstitution."Location Filter" := ItemSubstitution."Location Filter";
                TempItemSubstitution."Relations Level" := RelationsLevel2;
                TempItemSubstitution."Shipment Date" := DemandDate;

                if CalcATP then begin
                    Item.Get(ItemSubstitution."Substitute No.");
                    OnCreateSubstListOnBeforeCalcQtyAvail(Item, ProdOrderCompSubst, TempItemSubstitution);
                    TempItemSubstitution."Quantity Avail. on Shpt. Date" :=
                      AvailToPromise.CalcQtyAvailabletoPromise(
                        Item, GrossReq, SchedRcpt,
                        Item.GetRangeMax("Date Filter"), "Analysis Period Type"::Month, ODF);
                    Item.CalcFields(Inventory);
                    OnCreateSubstListOnAfterCalcQtyAvail(Item, ProdOrderCompSubst, TempItemSubstitution);
                    TempItemSubstitution.Inventory := Item.Inventory;
                end;

                if IsSubstitutionInserted(TempItemSubstitution, ItemSubstitution) then begin
                    ItemSubstitution2.SetRange(Type, ItemSubstitution.Type);
                    ItemSubstitution2.SetRange("No.", ItemSubstitution."Substitute No.");
                    ItemSubstitution2.SetFilter("Substitute No.", '<>%1&<>%2', ItemSubstitution."No.", OrgNo);
                    ItemSubstitution.CopyFilter("Variant Code", ItemSubstitution2."Variant Code");
                    ItemSubstitution.CopyFilter("Location Filter", ItemSubstitution2."Location Filter");
                    if ItemSubstitution2.FindFirst() then
                        CreateSubstList(OrgNo, ItemSubstitution2, RelationsLevel2 + 1, DemandDate, CalcATP);
                end else begin
                    TempItemSubstitution.Reset();
                    if TempItemSubstitution.Find() then
                        if RelationsLevel2 < TempItemSubstitution."Relations Level" then begin
                            TempItemSubstitution."Relations Level" := RelationsLevel2;
                            TempItemSubstitution.Modify();
                        end;
                end;
            until ItemSubstitution.Next() = 0;
    end;

    procedure GetTempItemSubstList(var TempItemSubstitutionList: Record "Item Substitution" temporary)
    begin
        TempItemSubstitutionList.DeleteAll();

        TempItemSubstitution.Reset();
        if TempItemSubstitution.Find('-') then
            repeat
                TempItemSubstitutionList := TempItemSubstitution;
                TempItemSubstitutionList.Insert();
            until TempItemSubstitution.Next() = 0;
    end;

    procedure ErrorMessage(ItemNo: Code[20]; VariantCode: Code[10])
    begin
        if VariantCode <> '' then
            Error(Text001, ItemNo);

        Error(Text002, ItemNo);
    end;

    procedure ItemAssemblySubstGet(var AssemblyLine: Record "Assembly Line")
    var
        TempAssemblyLine: Record "Assembly Line" temporary;
        AssemblyLineReserve: Codeunit "Assembly Line-Reserve";
    begin
        TempAssemblyLine := AssemblyLine;
        if TempAssemblyLine.Type <> TempAssemblyLine.Type::Item then
            exit;

        SaveItemNo := TempAssemblyLine."No.";
        SaveVariantCode := TempAssemblyLine."Variant Code";

        Item.Get(TempAssemblyLine."No.");
        Item.SetFilter("Location Filter", TempAssemblyLine."Location Code");
        Item.SetFilter("Variant Filter", TempAssemblyLine."Variant Code");
        Item.SetRange("Date Filter", 0D, TempAssemblyLine."Due Date");
        Item.CalcFields(Inventory);
        Item.CalcFields("Qty. on Sales Order");
        SaveItemSalesUOM(Item);

        ItemSubstitution.Reset();
        ItemSubstitution.SetRange(Type, ItemSubstitution.Type::Item);
        ItemSubstitution.SetRange("No.", TempAssemblyLine."No.");
        ItemSubstitution.SetRange("Variant Code", TempAssemblyLine."Variant Code");
        ItemSubstitution.SetRange("Location Filter", TempAssemblyLine."Location Code");
        if ItemSubstitution.Find('-') then begin
            AssemblyCalcCustPrice(TempAssemblyLine);
            TempItemSubstitution.Reset();
            TempItemSubstitution.SetRange(Type, TempItemSubstitution.Type::Item);
            TempItemSubstitution.SetRange("No.", TempAssemblyLine."No.");
            TempItemSubstitution.SetRange("Variant Code", TempAssemblyLine."Variant Code");
            TempItemSubstitution.SetRange("Location Filter", TempAssemblyLine."Location Code");
            if PAGE.RunModal(PAGE::"Item Substitution Entries", TempItemSubstitution) =
               ACTION::LookupOK
            then begin
                TempAssemblyLine."No." := TempItemSubstitution."Substitute No.";
                TempAssemblyLine."Variant Code" := TempItemSubstitution."Substitute Variant Code";
                SaveQty := TempAssemblyLine.Quantity;
                SaveLocation := TempAssemblyLine."Location Code";
                TempAssemblyLine.Quantity := 0;
                TempAssemblyLine.Validate("No.", TempItemSubstitution."Substitute No.");
                TempAssemblyLine.Validate("Variant Code", TempItemSubstitution."Substitute Variant Code");
                TempAssemblyLine."Location Code" := SaveLocation;
                TempAssemblyLine.Validate(Quantity, SaveQty);
                TempAssemblyLine.Validate("Unit of Measure Code", OldSalesUOM);
                Commit();
                if ItemCheckAvail.AssemblyLineCheck(TempAssemblyLine) then
                    TempAssemblyLine := AssemblyLine;
            end;
        end else
            Error(Text001, TempAssemblyLine."No.");

        if (AssemblyLine."No." <> TempAssemblyLine."No.") or (AssemblyLine."Variant Code" <> TempAssemblyLine."Variant Code") then
            AssemblyLineReserve.DeleteLine(AssemblyLine);

        AssemblyLine := TempAssemblyLine;
    end;

    local procedure IsSubstitutionInserted(var ItemSubstitutionToCheck: Record "Item Substitution"; ItemSubstitution: Record "Item Substitution"): Boolean
    begin
        if ItemSubstitution."Substitute No." <> '' then begin
            ItemSubstitutionToCheck.Reset();
            ItemSubstitutionToCheck.SetRange("Substitute Type", ItemSubstitution."Substitute Type");
            ItemSubstitutionToCheck.SetRange("Substitute No.", ItemSubstitution."Substitute No.");
            ItemSubstitutionToCheck.SetRange("Substitute Variant Code", ItemSubstitution."Substitute Variant Code");
            if ItemSubstitutionToCheck.IsEmpty() then
                exit(ItemSubstitutionToCheck.Insert());
        end;
        exit(false);
    end;

    local procedure SaveItemSalesUOM(Item: Record Item)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSaveItemSalesUOM(OldSalesUOM, Item, IsHandled);
        if IsHandled then
            exit;

        OldSalesUOM := Item."Sales Unit of Measure";
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetCompSubst(var ProdOrderComp: Record "Prod. Order Component"; var TempItemSubstitution: Record "Item Substitution" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterItemSubstGet(var SalesLine: Record "Sales Line"; TempSalesLine: Record "Sales Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateComponentBeforeAssign(var ProdOrderComp: Record "Prod. Order Component"; var TempProdOrderComp: Record "Prod. Order Component" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSaveItemSalesUOM(var OldSalesUOM: Code[10]; Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateComponent(var ProdOrderComp: Record "Prod. Order Component"; SubstItemNo: Code[20]; SubstVariantCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcCustPriceOnAfterCalcQtyAvail(var Item: Record Item; SalesLine: Record "Sales Line"; var TempItemSubstitution: Record "Item Substitution" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcCustPriceOnBeforeCalcQtyAvail(var Item: Record Item; SalesLine: Record "Sales Line"; var TempItemSubstitution: Record "Item Substitution" temporary; ItemSubstitution: Record "Item Substitution")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssemblyCalcCustPriceOnAfterCalcQtyAvail(var Item: Record Item; AssemblyLine: Record "Assembly Line"; var TempItemSubstitution: Record "Item Substitution" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssemblyCalcCustPriceOnBeforeCalcQtyAvail(var Item: Record Item; AssemblyLine: Record "Assembly Line"; var TempItemSubstitution: Record "Item Substitution" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcCustPrice(var TempItemSubstitution: Record "Item Substitution" temporary; TempSalesLine: Record "Sales Line" temporary; var IsHandled: Boolean; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeItemSubstGetPopulateTempSalesLine(var TempSalesline: Record "Sales Line" temporary; var TempItemSubstitution: Record "Item Substitution" temporary; var IsHandled: Boolean; SaveItemNo: Code[20]; SaveVariantCode: Code[10])
    begin
    end;

#if not CLEAN25
    internal procedure RunOnInsertInSubstServiceListOnAfterCalcQtyAvail(var Item: Record Item; ServiceLine: Record Microsoft.Service.Document."Service Line"; var TempItemSubstitution: Record "Item Substitution" temporary)
    begin
        OnInsertInSubstServiceListOnAfterCalcQtyAvail(Item, ServiceLine, TempItemSubstitution);
    end;

    [Obsolete('Moved to codeunit ServItemSubstitution', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnInsertInSubstServiceListOnAfterCalcQtyAvail(var Item: Record Item; ServiceLine: Record Microsoft.Service.Document."Service Line"; var TempItemSubstitution: Record "Item Substitution" temporary)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnInsertInSubstServiceListOnBeforeCalcQtyAvail(var Item: Record Item; ServiceLine: Record Microsoft.Service.Document."Service Line"; var TempItemSubstitution: Record "Item Substitution" temporary)
    begin
        OnInsertInSubstServiceListOnBeforeCalcQtyAvail(Item, ServiceLine, TempItemSubstitution);
    end;

    [Obsolete('Moved to codeunit ServItemSubstitution', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnInsertInSubstServiceListOnBeforeCalcQtyAvail(var Item: Record Item; ServiceLine: Record Microsoft.Service.Document."Service Line"; var TempItemSubstitution: Record "Item Substitution" temporary)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnCreateSubstListOnAfterCalcQtyAvail(var Item: Record Item; ProdOrderComp: Record "Prod. Order Component"; var TempItemSubstitution: Record "Item Substitution" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSubstListOnBeforeCalcQtyAvail(var Item: Record Item; ProdOrderComp: Record "Prod. Order Component"; var TempItemSubstitution: Record "Item Substitution" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCompSubstOnAfterCheckPrepareSubstList(var ProdOrderComp: Record "Prod. Order Component"; var TempItemSubstitution: Record "Item Substitution" temporary; var Item: Record Item; var GrossReq: Decimal; var SchedRcpt: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemSubstGetOnAfterSubstSalesLineItem(var SalesLine: Record "Sales Line"; var SourceSalesLine: Record "Sales Line"; var TempItemSubstitution: Record "Item Substitution" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemSubstGetOnAfterItemSubstitutionSetFilters(var ItemSubstitution: Record "Item Substitution")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemSubstGetOnAfterTempItemSubstitutionSetFilters(var TempItemSubstitution: Record "Item Substitution" temporary; var SalesLine: Record "Sales Line"; var TempSalesLine: Record "Sales Line" temporary; OldSalesUOM: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcCustPriceOnBeforeTempItemSubstitutionInsert(var TempItemSubstitution: Record "Item Substitution" temporary; ItemSubstitution: Record "Item Substitution")
    begin
    end;
}

