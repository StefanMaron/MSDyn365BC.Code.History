codeunit 5703 "Catalog Item Management"
{

    trigger OnRun()
    begin
    end;

    var
        NewItem: Record Item;
        NonStock: Record "Nonstock Item";
        ItemVend: Record "Item Vendor";
        ProgWindow: Dialog;

        Text000: Label 'Item %1 already exists.';
        Text001: Label 'Item %1 is created.';
        Text002: Label 'You cannot enter a catalog item on %1.', Comment = '%1=Sales Line document type';
        Text003: Label 'Creating item card for catalog item\';
        Text004: Label 'Manufacturer Code    #1####\';
        Text005: Label 'Vendor               #2##################\';
        Text006: Label 'Vendor Item          #3##################\';
        Text007: Label 'Item No.             #4##################';

    procedure NonstockAutoItem(NonStock2: Record "Nonstock Item")
    var
        IsHandled: Boolean;
    begin
        OnBeforeNonstockAutoItem(NonStock2);
        CheckItemAlreadyExists(NonStock2);

        DetermineItemNoAndItemNoSeries(NonStock2);
        NonStock2.Modify();
        OnNonstockAutoItemOnBeforeInsertItemUnitOfMeasure(NonStock2);
        InsertItemUnitOfMeasure(NonStock2."Unit of Measure", NonStock2."Item No.");

        CheckNonStockItem(NonStock2);

        CheckItemAlreadyExists(NonStock2);

        CreateNewItem(NonStock2);

        IsHandled := false;
        OnNonstockAutoItemOnAfterCreateNewItem(NewItem, IsHandled);
        if not IsHandled then
            ShowItemCreatedMessage(NonStock2);

        if CheckLicensePermission(DATABASE::"Item Vendor") then
            NonstockItemVend(NonStock2);
        if CheckLicensePermission(DATABASE::"Item Reference") then
            NonstockItemReference(NonStock2);

        OnAfterNonstockAutoItem(NonStock2, NewItem);
    end;

    local procedure CheckItemAlreadyExists(NonStock2: Record "Nonstock Item")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckItemAlreadyExists(NonStock2, IsHandled);
        if IsHandled then
            exit;

        if NewItem.Get(NonStock2."Item No.") then
            Error(Text000, NonStock2."Item No.");
    end;

    local procedure ShowItemCreatedMessage(NonStock2: Record "Nonstock Item")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowItemCreatedMessage(NewItem, NonStock2, IsHandled);
        if not IsHandled then
            Message(Text001, NonStock2."Item No.");
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
        CheckItemTemplateCode(NonStock2);
    end;

    procedure NonstockItemVend(NonStock2: Record "Nonstock Item")
    begin
        OnBeforeNonstockItemVend(NonStock2);

        ItemVend.SetRange("Item No.", NonStock2."Item No.");
        ItemVend.SetRange("Vendor No.", NonStock2."Vendor No.");
        if ItemVend.FindFirst() then
            exit;

        ItemVend."Item No." := NonStock2."Item No.";
        ItemVend."Vendor No." := NonStock2."Vendor No.";
        ItemVend."Vendor Item No." := NonStock2."Vendor Item No.";
        OnNonstockItemVendOnBeforeItemVendInsert(ItemVend, NonStock2);
        ItemVend.Insert(true);

        OnAfterNonstockItemVend(NonStock2, ItemVend);
    end;

    procedure NonstockItemReference(var NonStock2: Record "Nonstock Item")
    var
        ItemReference: Record "Item Reference";
        IsHandled: Boolean;
    begin
#if not CLEAN20
        IsHandled := false;
        OnBeforeNonstockItemCrossRef(NonStock2, IsHandled);
        if IsHandled then
            exit;
#endif
        IsHandled := false;
        OnBeforeNonstockItemReference(NonStock2, IsHandled);
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

        OnAfterNonstockItemCrossRef(NonStock2);
    end;

    procedure NonstockItemDel(var Item: Record Item)
    var
        ItemReference: Record "Item Reference";
    begin
        ItemVend.SetRange("Item No.", Item."No.");
        ItemVend.SetRange("Vendor No.", Item."Vendor No.");
        ItemVend.DeleteAll();

        ItemReference.SetRange("Item No.", Item."No.");
        ItemReference.SetRange("Variant Code", Item."Variant Filter");
        ItemReference.DeleteAll();

        NonStock.SetCurrentKey("Item No.");
        NonStock.SetRange("Item No.", Item."No.");
        if NonStock.FindSet() then
            repeat
                NonStock."Item No." := '';
                NonStock."Item No. Series" := '';
                NonStock.Modify();
            until NonStock.Next() = 0;

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

        DetermineItemNoAndItemNoSeries(NonStock);
        NonStock.Modify();
        SalesLine2."No." := NonStock."Item No.";
        OnNonStockSalesOnBeforeInsertItemUnitOfMeasure(NonStock);
        InsertItemUnitOfMeasure(NonStock."Unit of Measure", SalesLine2."No.");

        NewItem.SetRange("No.", SalesLine2."No.");
        if NewItem.FindFirst() then
            exit;

        if GuiAllowed() then begin
            ProgWindow.Open(Text003 +
              Text004 +
              Text005 +
              Text006 +
              Text007);
            ProgWindow.Update(1, NonStock."Manufacturer Code");
            ProgWindow.Update(2, NonStock."Vendor No.");
            ProgWindow.Update(3, NonStock."Vendor Item No.");
            ProgWindow.Update(4, SalesLine2."No.");
        end;

        CreateNewItem(NonStock);
        OnNonStockSalesOnAfterCreateNewItem(NewItem);

        if CheckLicensePermission(DATABASE::"Item Vendor") then
            NonstockItemVend(NonStock);
        if CheckLicensePermission(DATABASE::"Item Reference") then
            NonstockItemReference(NonStock);

        IsHandled := false;
        OnNonStockSalesOnBeforeProgWindowClose(NonStock, NewItem, SalesLine2, IsHandled);
        if not IsHandled then
            if GuiAllowed() then
                ProgWindow.Close();
    end;

    procedure DelNonStockSales(var SalesLine2: Record "Sales Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDelNonStockSales(SalesLine2, IsHandled);
        if IsHandled then
            exit;

        if SalesLine2.Nonstock = false then
            exit;

        NewItem.Get(SalesLine2."No.");
        SalesLine2."No." := '';
        SalesLine2.Modify();

        DelNonStockItem(NewItem);
    end;

    procedure DelNonStockPurch(var PurchLine2: Record "Purchase Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDelNonStockPurch(PurchLine2, IsHandled);
        if IsHandled then
            exit;

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
    var
        IsHandled: Boolean;
    begin
        NonStock.Get(ServInvLine2."No.");
        if NonStock."Item No." <> '' then begin
            ServInvLine2."No." := NonStock."Item No.";
            exit;
        end;

        DetermineItemNoAndItemNoSeries(NonStock);
        NonStock.Modify();
        ServInvLine2."No." := NonStock."Item No.";
        OnNonStockFSMOnBeforeInsertItemUnitOfMeasure(NonStock);
        InsertItemUnitOfMeasure(NonStock."Unit of Measure", ServInvLine2."No.");

        NewItem.SetRange("No.", ServInvLine2."No.");
        if NewItem.FindFirst() then
            exit;

        IsHandled := false;
        OnNonStockFSMOnBeforeProgWindowOpen(ServInvLine2, IsHandled);
        if not IsHandled and GuiAllowed() then begin
            ProgWindow.Open(Text003 +
              Text004 +
              Text005 +
              Text006 +
              Text007);
            ProgWindow.Update(1, NonStock."Manufacturer Code");
            ProgWindow.Update(2, NonStock."Vendor No.");
            ProgWindow.Update(3, NonStock."Vendor Item No.");
            ProgWindow.Update(4, ServInvLine2."No.");
        end;

        CreateNewItem(NonStock);
        OnNonStockFSMOnAfterCreateNewItem(NewItem);

        if CheckLicensePermission(DATABASE::"Item Vendor") then
            NonstockItemVend(NonStock);
        if CheckLicensePermission(DATABASE::"Item Reference") then
            NonstockItemReference(NonStock);

        if GuiAllowed() then
            ProgWindow.Close();
    end;

    procedure CreateItemFromNonstock(Nonstock2: Record "Nonstock Item")
    begin
        OnBeforeCreateItemFromNonstock(Nonstock2);
        if NewItem.Get(Nonstock2."Item No.") then
            Error(Text000, Nonstock2."Item No.");

        DetermineItemNoAndItemNoSeries(Nonstock2);
        Nonstock2.Modify();
        OnCreateItemFromNonstockOnBeforeInsertItemUnitOfMeasure(NonStock2);
        InsertItemUnitOfMeasure(Nonstock2."Unit of Measure", Nonstock2."Item No.");

        CheckNonStockItem(NonStock2);

        if NewItem.Get(Nonstock2."Item No.") then
            Error(Text000, Nonstock2."Item No.");

        CreateNewItem(Nonstock2);

        if CheckLicensePermission(DATABASE::"Item Vendor") then
            NonstockItemVend(Nonstock2);
        if CheckLicensePermission(DATABASE::"Item Reference") then
            NonstockItemReference(Nonstock2);
    end;

    local procedure CheckLicensePermission(TableID: Integer): Boolean
    var
        LicensePermission: Record "License Permission";
    begin
        LicensePermission.SetRange("Object Type", LicensePermission."Object Type"::TableData);
        LicensePermission.SetRange("Object Number", TableID);
        LicensePermission.SetFilter("Insert Permission", '<>%1', LicensePermission."Insert Permission"::" ");
        exit(LicensePermission.FindFirst());
    end;

    local procedure DelNonStockItem(var Item: Record Item)
    var
        BOMComp: Record "BOM Component";
        ItemLedgEntry: Record "Item Ledger Entry";
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMLine: Record "Production BOM Line";
        PurchLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        SalesLineArch: Record "Sales Line Archive";
        ServInvLine: Record "Service Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDelNonStockItem(Item, IsHandled);
        if IsHandled then
            exit;

        ItemLedgEntry.SetCurrentKey("Item No.");
        ItemLedgEntry.SetRange("Item No.", Item."No.");
        if not ItemLedgEntry.IsEmpty() then
            exit;

        SalesLine.SetCurrentKey(Type, "No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetRange("No.", Item."No.");
        if not SalesLine.IsEmpty() then
            exit;

        PurchLine.SetCurrentKey(Type, "No.");
        PurchLine.SetRange(Type, PurchLine.Type::Item);
        PurchLine.SetRange("No.", Item."No.");
        if not PurchLine.IsEmpty() then
            exit;

        ServInvLine.SetCurrentKey(Type, "No.");
        ServInvLine.SetRange(Type, ServInvLine.Type::Item);
        ServInvLine.SetRange("No.", Item."No.");
        if not ServInvLine.IsEmpty() then
            exit;

        BOMComp.SetCurrentKey(Type, "No.");
        BOMComp.SetRange(Type, BOMComp.Type::Item);
        BOMComp.SetRange("No.", Item."No.");
        if not BOMComp.IsEmpty() then
            exit;

        SalesLineArch.SetCurrentKey(Type, "No.");
        SalesLineArch.SetRange(Type, SalesLineArch.Type::Item);
        SalesLineArch.SetRange("No.", Item."No.");
        if not SalesLineArch.IsEmpty() then
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
            until ProdBOMLine.Next() = 0;

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
                        NonStock."Item No. Series" := '';
                        NonStock.Modify();
                    until NonStock.Next() = 0;
            end;
    end;

    procedure InsertItemUnitOfMeasure(UnitOfMeasureCode: Code[10]; ItemNo: Code[20])
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        IsHandled: Boolean;
    begin
        OnBeforeInsertItemUnitOfMeasure(UnitOfMeasureCode, ItemNo);
        InsertUnitOfMeasure(UnitOfMeasureCode, ItemNo);

        IsHandled := false;
        OnInsertItemUnitOfMeasuresOnBeforeItemUnitOfMeasureGet(UnitOfMeasureCode, IsHandled);
        If not IsHandled then
            if not ItemUnitOfMeasure.Get(ItemNo, UnitOfMeasureCode) then begin
                ItemUnitOfMeasure."Item No." := ItemNo;
                ItemUnitOfMeasure.Code := UnitOfMeasureCode;
                ItemUnitOfMeasure."Qty. per Unit of Measure" := 1;
                ItemUnitOfMeasure.Insert();
            end;
    end;

    local procedure InsertUnitOfMeasure(UnitOfMeasureCode: Code[10]; ItemNo: Code[20])
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        if not UnitOfMeasure.Get(UnitOfMeasureCode) then begin
            UnitOfMeasure.Code := UnitOfMeasureCode;
            UnitOfMeasure.Insert();
        end;
        OnAfterInsertUnitOfMeasure(UnitOfMeasureCode, ItemNo);
    end;

    [Obsolete('Replaced by GetNewItemNo(NonstockItem)', '22.0')]
    procedure GetNewItemNo(NonstockItem: Record "Nonstock Item"; Length1: Integer; Length2: Integer) NewItemNo: Code[20]
    var
        IsHandled: Boolean;
    begin
        OnBeforeGetNewItemNo(NonstockItem, Length1, Length2, NewItemNo, IsHandled);
        if IsHandled then
            exit(NewItemNo);
        DetermineItemNoAndItemNoSeries(NonstockItem);
        NewItemNo := NonstockItem."Item No.";
        OnAfterGetNewItemNo(NonstockItem, NewItemNo);
    end;

    procedure DetermineItemNoAndItemNoSeries(var NonstockItem: Record "Nonstock Item")
    var
        NonstockItemSetupMy: Record "Nonstock Item Setup";
        Length1: Integer;
        Length2: Integer;
        IsHandled: Boolean;
    begin
        OnBeforeDetermineItemNoAndItemNoSeries(NonstockItem, IsHandled);
        if IsHandled then
            exit;

        Length1 := StrLen(NonstockItem."Vendor Item No.");
        Length2 := StrLen(NonstockItem."Manufacturer Code");
        NonstockItemSetupMy.Get();
        case NonstockItemSetupMy."No. Format" of
            NonstockItemSetupMy."No. Format"::"Vendor Item No.":
                NonstockItem."Item No." := NonstockItem."Vendor Item No.";
            NonstockItemSetupMy."No. Format"::"Mfr. + Vendor Item No.":
                if NonstockItemSetupMy."No. Format Separator" = '' then begin
                    if Length1 + Length2 <= 20 then
                        Evaluate(NonstockItem."Item No.", NonstockItem."Manufacturer Code" + NonstockItem."Vendor Item No.")
                    else
                        Evaluate(NonstockItem."Item No.", NonstockItem."Manufacturer Code" + NonstockItem."Entry No.");
                end else
                    if Length1 + Length2 < 20 then
                        Evaluate(
                            NonstockItem."Item No.",
                            NonstockItem."Manufacturer Code" + NonstockItemSetupMy."No. Format Separator" + NonstockItem."Vendor Item No.")
                    else
                        Evaluate(
                            NonstockItem."Item No.",
                            NonstockItem."Manufacturer Code" + NonstockItemSetupMy."No. Format Separator" + NonstockItem."Entry No.");
            NonstockItemSetupMy."No. Format"::"Vendor Item No. + Mfr.":
                if NonstockItemSetupMy."No. Format Separator" = '' then begin
                    if Length1 + Length2 <= 20 then
                        Evaluate(NonstockItem."Item No.", NonstockItem."Vendor Item No." + NonstockItem."Manufacturer Code")
                    else
                        Evaluate(NonstockItem."Item No.", NonstockItem."Entry No." + NonstockItem."Manufacturer Code");
                end else
                    if Length1 + Length2 < 20 then
                        Evaluate(
                            NonstockItem."Item No.",
                            NonstockItem."Vendor Item No." + NonstockItemSetupMy."No. Format Separator" + NonstockItem."Manufacturer Code")
                    else
                        Evaluate(
                            NonstockItem."Item No.",
                            NonstockItem."Entry No." + NonstockItemSetupMy."No. Format Separator" + NonstockItem."Manufacturer Code");
            NonstockItemSetupMy."No. Format"::"Entry No.":
                NonstockItem."Item No." := NonstockItem."Entry No.";
            NonstockItemSetupMy."No. Format"::"Item No. Series":
                GetItemNoFromNoSeries(NonstockItem);
        end;

        OnAfterDetermineItemNoAndItemNoSeries(NonstockItem);
    end;

    local procedure GetItemNoFromNoSeries(var NonstockItem: Record "Nonstock Item")
    var
        InvtSetup: Record "Inventory Setup";
        ItemTempl: Record "Item Templ.";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        IsHandled: Boolean;
    begin
        OnBeforeGetItemNoFromNoSeries(NonstockItem, IsHandled);
        if IsHandled then
            exit;

        ItemTempl.SetLoadFields("No. Series");
        ItemTempl.Get(NonstockItem."Item Templ. Code");
        NonstockItem."Item No. Series" := ItemTempl."No. Series";

        if NonstockItem."Item No. Series" = '' then begin
            InvtSetup.Get();
            InvtSetup.TestField("Item Nos.");
            NonstockItem."Item No. Series" := InvtSetup."Item Nos.";
        end;

        NoSeriesMgt.InitSeries(NonstockItem."Item No. Series", '', 0D, NonstockItem."Item No.", NonstockItem."Item No. Series");

        OnAfterGetItemNoFromNoSeries(NonstockItem);
    end;

    [Obsolete('Replaced by CreateNewItem(NonstockItem)', '22.0')]
    procedure CreateNewItem(ItemNo: Code[20]; NonstockItem: Record "Nonstock Item")
    begin
        CreateNewItem(NonstockItem);
    end;

    procedure CreateNewItem(NonstockItem: Record "Nonstock Item")
    var
        Item: Record Item;
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
    begin
        Item.Init();

        InitItemFromTemplate(Item, NonstockItem);

        Item."No." := NonstockItem."Item No.";
        Item."No. Series" := NonstockItem."Item No. Series";
        Item.Description := NonstockItem.Description;
        Item.Validate(Description, Item.Description);
        Item.Validate("Base Unit of Measure", NonstockItem."Unit of Measure");
        Item."Unit Price" := NonstockItem."Unit Price";
        Item."Unit Cost" := NonstockItem."Negotiated Cost";
        Item."Last Direct Cost" := NonstockItem."Negotiated Cost";
        if Item."Costing Method" = Item."Costing Method"::Standard then
            Item."Standard Cost" := NonstockItem."Negotiated Cost";
        Item."Automatic Ext. Texts" := false;
        Item.Validate("Vendor No.", NonstockItem."Vendor No.");
        Item."Vendor Item No." := NonstockItem."Vendor Item No.";
        Item."Net Weight" := NonstockItem."Net Weight";
        Item."Gross Weight" := NonstockItem."Gross Weight";
        Item."Manufacturer Code" := NonstockItem."Manufacturer Code";
        Item."Created From Nonstock Item" := true;
        OnCreateNewItemOnBeforeItemInsert(Item, NonstockItem);
        Item.Insert();
        ItemTemplMgt.InsertDimensions(Item."No.", NonstockItem."Item Templ. Code", Database::Item, Database::"Item Templ.");
        Item.Get(NonstockItem."Item No.");

        OnAfterCreateNewItem(Item, NonstockItem, NewItem);
    end;

    local procedure InitItemFromTemplate(var Item: Record Item; NonstockItem: Record "Nonstock Item")
    var
        ItemTempl: Record "Item Templ.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitItemFromTemplate(Item, NonstockItem, IsHandled);
        if not IsHandled then begin
            ItemTempl.Get(NonstockItem."Item Templ. Code");
            Item.Type := ItemTempl.Type;
            Item."Inventory Posting Group" := ItemTempl."Inventory Posting Group";
            Item."Costing Method" := ItemTempl."Costing Method";
            Item."Gen. Prod. Posting Group" := ItemTempl."Gen. Prod. Posting Group";
            Item."Tax Group Code" := ItemTempl."Tax Group Code";
            Item."VAT Prod. Posting Group" := ItemTempl."VAT Prod. Posting Group";
            Item."Item Disc. Group" := ItemTempl."Item Disc. Group";
            Item."Item Category Code" := ItemTempl."Item Category Code";
            Item."Reordering Policy" := ItemTempl."Reordering Policy";
            Item."Tariff No." := ItemTempl."Tariff No.";
            Item."Country/Region of Origin Code" := ItemTempl."Country/Region of Origin Code";
            Item."Safety Lead Time" := ItemTempl."Safety Lead Time";
            Item."Flushing Method" := ItemTempl."Flushing Method";
            Item."Reorder Point" := ItemTempl."Reorder Point";
            Item."Reorder Quantity" := ItemTempl."Reorder Quantity";
            Item."Maximum Inventory" := ItemTempl."Maximum Inventory";
            Item."Order Tracking Policy" := ItemTempl."Order Tracking Policy";
            Item."Order Multiple" := ItemTempl."Order Multiple";
            Item."Time Bucket" := ItemTempl."Time Bucket";
            Item.Reserve := ItemTempl.Reserve;
            Item."Minimum Order Quantity" := ItemTempl."Minimum Order Quantity";
            Item."Maximum Order Quantity" := ItemTempl."Maximum Order Quantity";
            Item."Scrap %" := ItemTempl."Scrap %";
            Item."Lot Size" := ItemTempl."Lot Size";
            Item."Item Tracking Code" := ItemTempl."Item Tracking Code";
            Item."Serial Nos." := ItemTempl."Serial Nos.";
            Item."Lot Nos." := ItemTempl."Lot Nos.";
            Item."Warehouse Class Code" := ItemTempl."Warehouse Class Code";
            Item."Put-away Template Code" := ItemTempl."Put-away Template Code";
            Item."Special Equipment Code" := ItemTempl."Special Equipment Code";
            Item."Expiration Calculation" := ItemTempl."Expiration Calculation";
            Item.Blocked := ItemTempl.Blocked;
            Item."Block Reason" := ItemTempl."Block Reason";
            Item."Sales Blocked" := ItemTempl."Sales Blocked";
            Item."Purchasing Blocked" := ItemTempl."Purchasing Blocked";
            Item."Purchasing Code" := ItemTempl."Purchasing Code";
            Item."Country/Region Purchased Code" := ItemTempl."Country/Region Purchased Code";
            Item."Variant Mandatory if Exists" := ItemTempl."Variant Mandatory if Exists";
            Item."Over-Receipt Code" := ItemTempl."Over-Receipt Code";
            Item."Overhead Rate" := ItemTempl."Overhead Rate";
            Item."Overflow Level" := ItemTempl."Overflow Level";
            Item."Dampener Period" := ItemTempl."Dampener Period";
            Item."Dampener Quantity" := ItemTempl."Dampener Quantity";
            Item."Common Item No." := ItemTempl."Common Item No.";
            Item.GTIN := ItemTempl.GTIN;
            Item."Unit Volume" := ItemTempl."Unit Volume";
            Item."Service Item Group" := ItemTempl."Service Item Group";
            Item."Shelf No." := ItemTempl."Shelf No.";
            Item."Freight Type" := ItemTempl."Freight Type";
            Item."Replenishment System" := ItemTempl."Replenishment System";
            Item."Lead Time Calculation" := ItemTempl."Lead Time Calculation";
            Item."Manufacturing Policy" := ItemTempl."Manufacturing Policy";
            Item."Assembly Policy" := ItemTempl."Assembly Policy";
            Item."Routing No." := ItemTempl."Routing No.";
            Item."Production BOM No." := ItemTempl."Production BOM No.";
            Item."Rounding Precision" := ItemTempl."Rounding Precision";

            OnAfterInitItemFromTemplate(Item, ItemTempl, NonstockItem);
        end;
    end;

    procedure CheckItemTemplateCode(NonstockItem: Record "Nonstock Item")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckItemTemplateCode(NonstockItem, IsHandled);
        If IsHandled then
            exit;

        NonstockItem.TestField("Item Templ. Code");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateNewItem(var Item: Record Item; NonstockItem: Record "Nonstock Item"; var NewItem: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertUnitOfMeasure(UnitOfMeasureCode: Code[10]; ItemNo: Code[20])
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

    [Obsolete('Replaced by OnAfterDetermineItemNoAndItemNoSeries(NonstockItem)', '22.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetNewItemNo(NonstockItem: Record "Nonstock Item"; var NewItemNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDetermineItemNoAndItemNoSeries(var NonstockItem: Record "Nonstock Item")
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
    local procedure OnBeforeInsertItemUnitOfMeasure(UnitOfMeasureCode: Code[10]; ItemNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterNonstockItemVend(NonStockItem: Record "Nonstock Item"; var ItemVendor: Record "Item Vendor")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNonstockItemVend(NonStockItem: Record "Nonstock Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeCheckNonStockItem(var NonstockItem: Record "Nonstock Item"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeCheckItemAlreadyExists(var NonstockItem: Record "Nonstock Item"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDelNonStockItem(var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDelNonStockSales(var SalesLine2: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDelNonStockPurch(var PurchaseLine2: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteCreatedFromNonstockItem(var NewItem: Record Item; var NonStock: Record "Nonstock Item"; var IsHandled: Boolean)
    begin
    end;

    [Obsolete('Replaced by OnBeforeDetermineItemNoAndItemNoSeries(NonstockItem, IsHandled)', '21.4')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetNewItemNo(NonstockItem: Record "Nonstock Item"; Length1: Integer; Length2: Integer; var NewItemNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDetermineItemNoAndItemNoSeries(var NonstockItem: Record "Nonstock Item"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNonstockAutoItem(var NonStock2: Record "Nonstock Item")
    begin
    end;

#if not CLEAN20
    [Obsolete('Replaced by event OnBeforeNonstockItemReference', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeNonstockItemCrossRef(var NonstockItem: Record "Nonstock Item"; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNonstockItemReference(var NonstockItem: Record "Nonstock Item"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNonStockSales(var NonStockItem: Record "Nonstock Item"; var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemCreatedMessage(var NewItem: Record Item; NonStockItem: Record "Nonstock Item"; var IsHandled: Boolean)
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
    local procedure OnNonstockAutoItemOnAfterCreateNewItem(var NewItem: Record Item; var IsHandled: Boolean)
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
    local procedure OnNonStockSalesOnBeforeProgWindowClose(var NonStockItem: Record "Nonstock Item"; var NewItem: Record Item; SalesLine2: Record "Sales Line"; var IsHandled: Boolean)
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

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitItemFromTemplate(var Item: Record Item; ItemTempl: Record "Item Templ."; NonstockItem: Record "Nonstock Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateNewItemOnBeforeItemInsert(var Item: Record Item; NonstockItem: Record "Nonstock Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertItemUnitOfMeasuresOnBeforeItemUnitOfMeasureGet(UnitOfMeasureCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemTemplateCode(var NonstockItem: Record "Nonstock Item"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitItemFromTemplate(var Item: Record Item; NonstockItem: Record "Nonstock Item"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetItemNoFromNoSeries(var NonstockItem: Record "Nonstock Item"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetItemNoFromNoSeries(var NonstockItem: Record "Nonstock Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnNonStockFSMOnBeforeProgWindowOpen(var ServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;
}
