﻿codeunit 5703 "Catalog Item Management"
{

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'Item %1 already exists.';
        Text001: Label 'Item %1 is created.';
        Text002: Label 'You cannot enter a catalog item on %1.', Comment = '%1=Sales Line document type';
        Text003: Label 'Creating item card for catalog item\';
        Text004: Label 'Manufacturer Code    #1####\';
        Text005: Label 'Vendor               #2##################\';
        Text006: Label 'Vendor Item          #3##################\';
        Text007: Label 'Item No.             #4##################';
        NewItem: Record Item;
        ItemLedgEntry: Record "Item Ledger Entry";
        NonStock: Record "Nonstock Item";
        PurchLine: Record "Purchase Line";
        ItemVend: Record "Item Vendor";
        ServInvLine: Record "Service Line";
        SalesLine: Record "Sales Line";
        BOMComp: Record "BOM Component";
        ProdBOMLine: Record "Production BOM Line";
        ProdBOMHeader: Record "Production BOM Header";
        ItemReferenceMgt: Codeunit "Item Reference Management";
        ProgWindow: Dialog;

    procedure NonstockAutoItem(NonStock2: Record "Nonstock Item")
    begin
        OnBeforeNonstockAutoItem(NonStock2);
        if NewItem.Get(NonStock2."Item No.") then
            Error(Text000, NonStock2."Item No.");

        NonStock2."Item No." :=
          GetNewItemNo(
            NonStock2, StrLen(NonStock2."Vendor Item No."), StrLen(NonStock2."Manufacturer Code"));
        NonStock2.Modify();
        OnNonstockAutoItemOnBeforeInsertItemUnitOfMeasure(NonStock2);
        InsertItemUnitOfMeasure(NonStock2."Unit of Measure", NonStock2."Item No.");

        CheckNonStockItem(NonStock2);

        if NewItem.Get(NonStock2."Item No.") then
            Error(Text000, NonStock2."Item No.");

        CreateNewItem(NonStock2."Item No.", NonStock2);
        OnNonstockAutoItemOnAfterCreateNewItem(NewItem);
        Message(Text001, NonStock2."Item No.");

        if CheckLicensePermission(DATABASE::"Item Vendor") then
            NonstockItemVend(NonStock2);
        if CheckLicensePermission(DATABASE::"Item Reference") and ItemReferenceMgt.IsEnabled() then
            NonstockItemReference(NonStock2);
        if CheckLicensePermission(DATABASE::"Item Cross Reference") and not ItemReferenceMgt.IsEnabled() then
            NonstockItemCrossRef(NonStock2);

        OnAfterNonstockAutoItem(NonStock2, NewItem);
    end;

    local procedure CheckNonStockItem(NonStock2: Record "Nonstock Item")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckNonStockItem(NonStock2, IsHandled);
        if IsHandled then
            exit;

        NonStock2.TestField("Vendor No.");
        NonStock2.TestField("Vendor Item No.");
        NonStock2.TestField("Item Template Code");
    end;

    procedure NonstockItemVend(NonStock2: Record "Nonstock Item")
    begin
        ItemVend.SetRange("Item No.", NonStock2."Item No.");
        ItemVend.SetRange("Vendor No.", NonStock2."Vendor No.");
        if ItemVend.FindFirst() then
            exit;

        ItemVend."Item No." := NonStock2."Item No.";
        ItemVend."Vendor No." := NonStock2."Vendor No.";
        ItemVend."Vendor Item No." := NonStock2."Vendor Item No.";
        OnNonstockItemVendOnBeforeItemVendInsert(ItemVend, NonStock2);
        ItemVend.Insert(true);
    end;

    [Obsolete('Replaced by NonstockItemReference().', '17.0')]
    local procedure NonstockItemCrossRef(var NonStock2: Record "Nonstock Item")
    var
        ItemCrossReference: Record "Item Cross Reference";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeNonstockItemCrossRef(NonStock2, IsHandled);
        if not IsHandled then begin
            ItemCrossReference.SetRange("Item No.", NonStock2."Item No.");
            ItemCrossReference.SetRange("Unit of Measure", NonStock2."Unit of Measure");
            ItemCrossReference.SetRange("Cross-Reference Type", ItemCrossReference."Cross-Reference Type"::Vendor);
            ItemCrossReference.SetRange("Cross-Reference Type No.", NonStock2."Vendor No.");
            ItemCrossReference.SetRange("Cross-Reference No.", NonStock2."Vendor Item No.");
            OnAfterItemCrossReferenceFilter(ItemCrossReference, NonStock2);
            if not ItemCrossReference.FindFirst() then begin
                ItemCrossReference.Init();
                ItemCrossReference.Validate("Item No.", NonStock2."Item No.");
                ItemCrossReference.Validate("Unit of Measure", NonStock2."Unit of Measure");
                ItemCrossReference.Validate("Cross-Reference Type", ItemCrossReference."Cross-Reference Type"::Vendor);
                ItemCrossReference.Validate("Cross-Reference Type No.", NonStock2."Vendor No.");
                ItemCrossReference.Validate("Cross-Reference No.", NonStock2."Vendor Item No.");
                ItemCrossReference.Insert();
                OnAfterItemCrossReferenceInsert(ItemCrossReference, NonStock2);
            end;
        end;
        if NonStock2."Bar Code" <> '' then begin
            ItemCrossReference.Reset();
            ItemCrossReference.SetRange("Item No.", NonStock2."Item No.");
            ItemCrossReference.SetRange("Unit of Measure", NonStock2."Unit of Measure");
            ItemCrossReference.SetRange("Cross-Reference Type", ItemCrossReference."Cross-Reference Type"::"Bar Code");
            ItemCrossReference.SetRange("Cross-Reference No.", NonStock2."Bar Code");
            OnAfterItemCrossReferenceFilter(ItemCrossReference, NonStock2);
            if not ItemCrossReference.FindFirst() then begin
                ItemCrossReference.Init();
                ItemCrossReference.Validate("Item No.", NonStock2."Item No.");
                ItemCrossReference.Validate("Unit of Measure", NonStock2."Unit of Measure");
                ItemCrossReference.Validate("Cross-Reference Type", ItemCrossReference."Cross-Reference Type"::"Bar Code");
                ItemCrossReference.Validate("Cross-Reference No.", NonStock2."Bar Code");
                ItemCrossReference.Insert();
                OnAfterItemCrossReferenceInsert(ItemCrossReference, NonStock2);
            end;
        end;

        OnAfterNonstockItemCrossRef(NonStock2);
    end;

    procedure NonstockItemReference(var NonStock2: Record "Nonstock Item")
    var
        ItemReference: Record "Item Reference";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeNonstockItemCrossRef(NonStock2, IsHandled);
        if IsHandled then
            exit;

        ItemReference.SetRange("Item No.", NonStock2."Item No.");
        ItemReference.SetRange("Unit of Measure", NonStock2."Unit of Measure");
        ItemReference.SetRange("Reference Type", ItemReference."Reference Type"::Vendor);
        ItemReference.SetRange("Reference Type No.", NonStock2."Vendor No.");
        ItemReference.SetRange("Reference No.", NonStock2."Vendor Item No.");
        OnNonstockItemReferenceOnAfterSetVendorItemNoFilters(ItemReference, NonStock2);
        if not ItemReference.FindFirst() then begin
            ItemReference.Init();
            ItemReference.Validate("Item No.", NonStock2."Item No.");
            ItemReference.Validate("Unit of Measure", NonStock2."Unit of Measure");
            ItemReference.Validate("Reference Type", ItemReference."Reference Type"::Vendor);
            ItemReference.Validate("Reference Type No.", NonStock2."Vendor No.");
            ItemReference.Validate("Reference No.", NonStock2."Vendor Item No.");
            ItemReference.Insert();
            OnAfterItemReferenceInsert(ItemReference, NonStock2);
        end;
        if NonStock2."Bar Code" <> '' then begin
            ItemReference.Reset();
            ItemReference.SetRange("Item No.", NonStock2."Item No.");
            ItemReference.SetRange("Unit of Measure", NonStock2."Unit of Measure");
            ItemReference.SetRange("Reference Type", ItemReference."Reference Type"::"Bar Code");
            ItemReference.SetRange("Reference No.", NonStock2."Bar Code");
            OnNonstockItemReferenceOnAfterSetBarCodeFilters(ItemReference, NonStock2);
            if not ItemReference.FindFirst() then begin
                ItemReference.Init();
                ItemReference.Validate("Item No.", NonStock2."Item No.");
                ItemReference.Validate("Unit of Measure", NonStock2."Unit of Measure");
                ItemReference.Validate("Reference Type", ItemReference."Reference Type"::"Bar Code");
                ItemReference.Validate("Reference No.", NonStock2."Bar Code");
                ItemReference.Insert();
                OnAfterItemReferenceInsert(ItemReference, NonStock2);
            end;
        end;
    end;

    procedure NonstockItemDel(var Item: Record Item)
    var
        ItemCrossReference: Record "Item Cross Reference";
        ItemReference: Record "Item Reference";
    begin
        ItemVend.SetRange("Item No.", Item."No.");
        ItemVend.SetRange("Vendor No.", Item."Vendor No.");
        ItemVend.DeleteAll();

        if not ItemReferenceMgt.IsEnabled() then begin
            ItemCrossReference.SetRange("Item No.", Item."No.");
            ItemCrossReference.SetRange("Variant Code", Item."Variant Filter");
            ItemCrossReference.DeleteAll();
        end else begin
            ItemReference.SetRange("Item No.", Item."No.");
            ItemReference.SetRange("Variant Code", Item."Variant Filter");
            ItemReference.DeleteAll();
        end;

        NonStock.SetCurrentKey("Item No.");
        NonStock.SetRange("Item No.", Item."No.");
        if NonStock.Find('-') then
            NonStock.ModifyAll("Item No.", '');

        OnAfterNonstockItemDel(Item);
    end;

    procedure NonStockSales(var SalesLine2: Record "Sales Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeNonStockSales(NonStock, SalesLine2, IsHandled);
        If IsHandled then
            exit;
        if (SalesLine2."Document Type" in
            [SalesLine2."Document Type"::"Return Order", SalesLine2."Document Type"::"Credit Memo"])
        then
            Error(Text002, SalesLine2."Document Type");

        NonStock.Get(SalesLine2."No.");
        if NonStock."Item No." <> '' then begin
            SalesLine2."No." := NonStock."Item No.";
            exit;
        end;

        SalesLine2."No." :=
          GetNewItemNo(
            NonStock, StrLen(NonStock."Vendor Item No."), StrLen(NonStock."Manufacturer Code"));
        NonStock."Item No." := SalesLine2."No.";
        NonStock.Modify();
        OnNonStockSalesOnBeforeInsertItemUnitOfMeasure(NonStock);
        InsertItemUnitOfMeasure(NonStock."Unit of Measure", SalesLine2."No.");

        NewItem.SetRange("No.", SalesLine2."No.");
        if NewItem.FindFirst() then
            exit;

        ProgWindow.Open(Text003 +
          Text004 +
          Text005 +
          Text006 +
          Text007);
        ProgWindow.Update(1, NonStock."Manufacturer Code");
        ProgWindow.Update(2, NonStock."Vendor No.");
        ProgWindow.Update(3, NonStock."Vendor Item No.");
        ProgWindow.Update(4, SalesLine2."No.");

        CreateNewItem(SalesLine2."No.", NonStock);
        OnNonStockSalesOnAfterCreateNewItem(NewItem);

        if CheckLicensePermission(DATABASE::"Item Vendor") then
            NonstockItemVend(NonStock);
        if CheckLicensePermission(DATABASE::"Item Reference") and ItemReferenceMgt.IsEnabled() then
            NonstockItemReference(NonStock);
        if CheckLicensePermission(DATABASE::"Item Cross Reference") and not ItemReferenceMgt.IsEnabled() then
            NonstockItemCrossRef(NonStock);

        OnNonStockSalesOnBeforeProgWindowClose(NonStock, NewItem);
        ProgWindow.Close();
    end;

    procedure DelNonStockSales(var SalesLine2: Record "Sales Line")
    begin
        if SalesLine2.Nonstock = false then
            exit;

        NewItem.Get(SalesLine2."No.");
        SalesLine2."No." := '';
        SalesLine2.Modify();

        DelNonStockItem(NewItem);
    end;

    procedure DelNonStockPurch(var PurchLine2: Record "Purchase Line")
    begin
        if PurchLine2.Nonstock = false then
            exit;

        NewItem.Get(PurchLine2."No.");
        PurchLine2."No." := '';
        PurchLine2.Modify();

        DelNonStockItem(NewItem);
    end;

    procedure DelNonStockFSM(var ServInvLine2: Record "Service Line")
    begin
        if ServInvLine2.Nonstock = false then
            exit;

        NewItem.Get(ServInvLine2."No.");
        ServInvLine2."No." := '';
        ServInvLine2.Modify();

        DelNonStockItem(NewItem);
    end;

    procedure DelNonStockSalesArch(var SalesLineArchive2: Record "Sales Line Archive")
    begin
        if NewItem.Get(SalesLineArchive2."No.") then begin
            SalesLineArchive2."No." := '';
            SalesLineArchive2.Modify();

            DelNonStockItem(NewItem);
        end;
    end;

    procedure NonStockFSM(var ServInvLine2: Record "Service Line")
    begin
        NonStock.Get(ServInvLine2."No.");
        if NonStock."Item No." <> '' then begin
            ServInvLine2."No." := NonStock."Item No.";
            exit;
        end;

        ServInvLine2."No." :=
          GetNewItemNo(
            NonStock, StrLen(NonStock."Vendor Item No."), StrLen(NonStock."Manufacturer Code"));
        NonStock."Item No." := ServInvLine2."No.";
        NonStock.Modify();
        OnNonStockFSMOnBeforeInsertItemUnitOfMeasure(NonStock);
        InsertItemUnitOfMeasure(NonStock."Unit of Measure", ServInvLine2."No.");

        NewItem.SetRange("No.", ServInvLine2."No.");
        if NewItem.FindFirst() then
            exit;

        ProgWindow.Open(Text003 +
          Text004 +
          Text005 +
          Text006 +
          Text007);
        ProgWindow.Update(1, NonStock."Manufacturer Code");
        ProgWindow.Update(2, NonStock."Vendor No.");
        ProgWindow.Update(3, NonStock."Vendor Item No.");
        ProgWindow.Update(4, ServInvLine2."No.");

        CreateNewItem(ServInvLine2."No.", NonStock);
        OnNonStockFSMOnAfterCreateNewItem(NewItem);

        if CheckLicensePermission(DATABASE::"Item Vendor") then
            NonstockItemVend(NonStock);
        if CheckLicensePermission(DATABASE::"Item Reference") and ItemReferenceMgt.IsEnabled() then
            NonstockItemReference(NonStock);
        if CheckLicensePermission(DATABASE::"Item Cross Reference") and not ItemReferenceMgt.IsEnabled() then
            NonstockItemCrossRef(NonStock);

        ProgWindow.Close();
    end;

    procedure CreateItemFromNonstock(Nonstock2: Record "Nonstock Item")
    begin
        OnBeforeCreateItemFromNonstock(Nonstock2);
        if NewItem.Get(Nonstock2."Item No.") then
            Error(Text000, Nonstock2."Item No.");

        Nonstock2."Item No." :=
          GetNewItemNo(
            Nonstock2, StrLen(Nonstock2."Vendor Item No."), StrLen(Nonstock2."Manufacturer Code"));
        Nonstock2.Modify();
        OnCreateItemFromNonstockOnBeforeInsertItemUnitOfMeasure(NonStock2);
        InsertItemUnitOfMeasure(Nonstock2."Unit of Measure", Nonstock2."Item No.");

        CheckNonStockItem(NonStock2);

        if NewItem.Get(Nonstock2."Item No.") then
            Error(Text000, Nonstock2."Item No.");

        CreateNewItem(Nonstock2."Item No.", Nonstock2);

        if CheckLicensePermission(DATABASE::"Item Vendor") then
            NonstockItemVend(Nonstock2);
        if CheckLicensePermission(DATABASE::"Item Reference") and ItemReferenceMgt.IsEnabled() then
            NonstockItemReference(Nonstock2);
        if CheckLicensePermission(DATABASE::"Item Cross Reference") and not ItemReferenceMgt.IsEnabled() then
            NonstockItemCrossRef(Nonstock2);
    end;

    local procedure CheckLicensePermission(TableID: Integer): Boolean
    var
        LicensePermission: Record "License Permission";
    begin
        LicensePermission.SetRange("Object Type", LicensePermission."Object Type"::TableData);
        LicensePermission.SetRange("Object Number", TableID);
        LicensePermission.SetFilter("Insert Permission", '<>%1', LicensePermission."Insert Permission"::" ");
        exit(LicensePermission.FindFirst);
    end;

    local procedure DelNonStockItem(var Item: Record Item)
    var
        SalesLineArch: Record "Sales Line Archive";
    begin
        OnBeforeDelNonStockItem(Item);

        ItemLedgEntry.SetCurrentKey("Item No.");
        ItemLedgEntry.SetRange("Item No.", Item."No.");
        if ItemLedgEntry.FindFirst() then
            exit;

        SalesLine.SetCurrentKey(Type, "No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetRange("No.", Item."No.");
        if SalesLine.FindFirst() then
            exit;

        PurchLine.SetCurrentKey(Type, "No.");
        PurchLine.SetRange(Type, PurchLine.Type::Item);
        PurchLine.SetRange("No.", Item."No.");
        if PurchLine.FindFirst() then
            exit;

        ServInvLine.SetCurrentKey(Type, "No.");
        ServInvLine.SetRange(Type, ServInvLine.Type::Item);
        ServInvLine.SetRange("No.", Item."No.");
        if ServInvLine.FindFirst() then
            exit;

        BOMComp.SetCurrentKey(Type, "No.");
        BOMComp.SetRange(Type, BOMComp.Type::Item);
        BOMComp.SetRange("No.", Item."No.");
        if BOMComp.FindFirst() then
            exit;

        SalesLineArch.SetCurrentKey(Type, "No.");
        SalesLineArch.SetRange(Type, SalesLineArch.Type::Item);
        SalesLineArch.SetRange("No.", Item."No.");
        if not SalesLineArch.IsEmpty then
            exit;

        ProdBOMLine.Reset();
        ProdBOMLine.SetCurrentKey(Type, "No.");
        ProdBOMLine.SetRange(Type, ProdBOMLine.Type::Item);
        ProdBOMLine.SetRange("No.", Item."No.");
        if ProdBOMLine.Find('-') then
            repeat
                if ProdBOMHeader.Get(ProdBOMLine."Production BOM No.") and
                   (ProdBOMHeader.Status = ProdBOMHeader.Status::Certified)
                then
                    exit;
            until ProdBOMLine.Next = 0;

        NewItem.Get(Item."No.");
        DeleteCreatedFromNonstockItem();
    end;

    local procedure DeleteCreatedFromNonstockItem()
    var
        ItemNo: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteCreatedFromNonstockItem(NewItem, NonStock, IsHandled);
        if IsHandled then
            exit;

        ItemNo := NewItem."No.";
        if NewItem."Created From Nonstock Item" then
            if NewItem.Delete(true) then begin
                NonStock.SetRange("Item No.", ItemNo);
                if NonStock.Find('-') then
                    repeat
                        NonStock."Item No." := '';
                        NonStock.Modify();
                    until NonStock.Next() = 0;
            end;
    end;

    local procedure InsertItemUnitOfMeasure(UnitOfMeasureCode: Code[10]; ItemNo: Code[20])
    var
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        if not UnitOfMeasure.Get(UnitOfMeasureCode) then begin
            UnitOfMeasure.Code := UnitOfMeasureCode;
            UnitOfMeasure.Insert();
        end;
        if not ItemUnitOfMeasure.Get(ItemNo, UnitOfMeasureCode) then begin
            ItemUnitOfMeasure."Item No." := ItemNo;
            ItemUnitOfMeasure.Code := UnitOfMeasureCode;
            ItemUnitOfMeasure."Qty. per Unit of Measure" := 1;
            ItemUnitOfMeasure.Insert();
        end;
    end;

    local procedure GetNewItemNo(NonstockItem: Record "Nonstock Item"; Length1: Integer; Length2: Integer) NewItemNo: Code[20]
    var
        NonstockItemSetupMy: Record "Nonstock Item Setup";
        IsHandled: Boolean;
    begin
        OnBeforeGetNewItemNo(NonstockItem, Length1, Length2, NewItemNo, IsHandled);
        if IsHandled then
            exit(NewItemNo);

        NonstockItemSetupMy.Get();
        // NAVCZ
        if NonstockItemSetupMy."No. From No. Series" then begin
            NewItem.Init();
            if not NewItem.AssistEdit() then
                Error(Text002, NewItemNo);
            NewItemNo := NewItem."No.";
            Clear(NewItem);
            exit;
        end;
        // NAVCZ
        case NonstockItemSetupMy."No. Format" of
            NonstockItemSetupMy."No. Format"::"Vendor Item No.":
                NewItemNo := NonstockItem."Vendor Item No.";
            NonstockItemSetupMy."No. Format"::"Mfr. + Vendor Item No.":
                if NonstockItemSetupMy."No. Format Separator" = '' then begin
                    if Length1 + Length2 <= 20 then
                        Evaluate(NewItemNo, NonstockItem."Manufacturer Code" + NonstockItem."Vendor Item No.")
                    else
                        Evaluate(NewItemNo, NonstockItem."Manufacturer Code" + NonstockItem."Entry No.");
                end else begin
                    if Length1 + Length2 < 20 then
                        Evaluate(
                          NewItemNo,
                          NonstockItem."Manufacturer Code" + NonstockItemSetupMy."No. Format Separator" + NonstockItem."Vendor Item No.")
                    else
                        Evaluate(
                          NewItemNo,
                          NonstockItem."Manufacturer Code" + NonstockItemSetupMy."No. Format Separator" + NonstockItem."Entry No.");
                end;
            NonstockItemSetupMy."No. Format"::"Vendor Item No. + Mfr.":
                if NonstockItemSetupMy."No. Format Separator" = '' then begin
                    if Length1 + Length2 <= 20 then
                        Evaluate(NewItemNo, NonstockItem."Vendor Item No." + NonstockItem."Manufacturer Code")
                    else
                        Evaluate(NewItemNo, NonstockItem."Entry No." + NonstockItem."Manufacturer Code");
                end else begin
                    if Length1 + Length2 < 20 then
                        Evaluate(
                          NewItemNo,
                          NonstockItem."Vendor Item No." + NonstockItemSetupMy."No. Format Separator" + NonstockItem."Manufacturer Code")
                    else
                        Evaluate(
                          NewItemNo,
                          NonstockItem."Entry No." + NonstockItemSetupMy."No. Format Separator" + NonstockItem."Manufacturer Code");
                end;
            NonstockItemSetupMy."No. Format"::"Entry No.":
                NewItemNo := NonstockItem."Entry No.";
        end;
    end;

    local procedure CreateNewItem(ItemNo: Code[20]; NonstockItem: Record "Nonstock Item")
    var
        Item: Record Item;
        DummyItemTemplate: Record "Item Template";
        ConfigTemplateHeader: Record "Config. Template Header";
    begin
        Item.Init();

        ConfigTemplateHeader.SetRange(Code, NonstockItem."Item Template Code");
        ConfigTemplateHeader.FindFirst;
        DummyItemTemplate.InitializeTempRecordFromConfigTemplate(DummyItemTemplate, ConfigTemplateHeader);
        Item."Inventory Posting Group" := DummyItemTemplate."Inventory Posting Group";
        Item."Costing Method" := DummyItemTemplate."Costing Method";
        Item."Gen. Prod. Posting Group" := DummyItemTemplate."Gen. Prod. Posting Group";
        Item."Tax Group Code" := DummyItemTemplate."Tax Group Code";
        Item."VAT Prod. Posting Group" := DummyItemTemplate."VAT Prod. Posting Group";
        Item."Item Disc. Group" := DummyItemTemplate."Item Disc. Group";

        OnBeforeCreateNewItem(Item, DummyItemTemplate, NonstockItem);

        Item."No." := ItemNo;
        Item.Description := NonstockItem.Description;
        Item.Validate(Description, Item.Description);
        Item.Validate("Base Unit of Measure", NonstockItem."Unit of Measure");
        Item."Unit Price" := NonstockItem."Unit Price";
        Item."Unit Cost" := NonstockItem."Negotiated Cost";
        Item."Last Direct Cost" := NonstockItem."Negotiated Cost";
        if Item."Costing Method" = Item."Costing Method"::Standard then
            Item."Standard Cost" := NonstockItem."Negotiated Cost";
        Item."Automatic Ext. Texts" := false;
        Item."Vendor No." := NonstockItem."Vendor No.";
        Item."Vendor Item No." := NonstockItem."Vendor Item No.";
        Item."Net Weight" := NonstockItem."Net Weight";
        Item."Gross Weight" := NonstockItem."Gross Weight";
        Item."Manufacturer Code" := NonstockItem."Manufacturer Code";
        Item."Item Category Code" := DummyItemTemplate."Item Category Code";
        Item."Created From Nonstock Item" := true;
        Item.Insert();

        OnAfterCreateNewItem(Item);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateNewItem(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterItemCrossReferenceFilter(var ItemCrossReference: Record "Item Cross Reference"; NonstockItem: Record "Nonstock Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterItemCrossReferenceInsert(var ItemCrossReference: Record "Item Cross Reference"; NonstockItem: Record "Nonstock Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnNonstockItemReferenceOnAfterSetBarCodeFilters(var ItemReference: Record "Item Reference"; NonstockItem: Record "Nonstock Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnNonstockItemReferenceOnAfterSetVendorItemNoFilters(var ItemReference: Record "Item Reference"; NonstockItem: Record "Nonstock Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterItemReferenceInsert(var ItemReference: Record "Item Reference"; NonstockItem: Record "Nonstock Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterNonstockItemDel(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterNonstockAutoItem(var NonStock: Record "Nonstock Item"; var NewItem: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeCreateItemFromNonstock(var NonstockItem: Record "Nonstock Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeCheckNonStockItem(var NonstockItem: Record "Nonstock Item"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateNewItem(var Item: Record Item; ItemTemplate: Record "Item Template"; NonstockItem: Record "Nonstock Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDelNonStockItem(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteCreatedFromNonstockItem(var NewItem: Record Item; var NonStock: Record "Nonstock Item"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetNewItemNo(NonstockItem: Record "Nonstock Item"; Length1: Integer; Length2: Integer; var NewItemNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNonstockAutoItem(var NonStock2: Record "Nonstock Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNonstockItemCrossRef(var NonstockItem: Record "Nonstock Item"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNonStockSales(var NonStockItem: Record "Nonstock Item"; var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateItemFromNonstockOnBeforeInsertItemUnitOfMeasure(var NonStockItem: Record "Nonstock Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnNonstockItemVendOnBeforeItemVendInsert(var ItemVend: Record "Item Vendor"; NonStockItem: Record "Nonstock Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnNonstockAutoItemOnAfterCreateNewItem(var NewItem: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnNonstockAutoItemOnBeforeInsertItemUnitOfMeasure(var NonStockItem: Record "Nonstock Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnNonStockSalesOnAfterCreateNewItem(var NewItem: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnNonStockSalesOnBeforeInsertItemUnitOfMeasure(var NonStockItem: Record "Nonstock Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnNonStockSalesOnBeforeProgWindowClose(var NonStockItem: Record "Nonstock Item"; var NewItem: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnNonStockFSMOnAfterCreateNewItem(var NewItem: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnNonStockFSMOnBeforeInsertItemUnitOfMeasure(var NonStockItem: Record "Nonstock Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterNonstockItemCrossRef(var NonStock2: Record "Nonstock Item")
    begin
    end;
}

