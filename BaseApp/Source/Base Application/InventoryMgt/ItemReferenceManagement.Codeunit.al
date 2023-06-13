codeunit 5720 "Item Reference Management"
{

    trigger OnRun()
    begin
    end;

    var
        Item: Record Item;
        ItemReference: Record "Item Reference";
        ItemVariant: Record "Item Variant";
        SalesLine: Record "Sales Line";
        PurchLine: Record "Purchase Line";
        Found: Boolean;
        ItemRefNotExistErr: Label 'There are no items with reference %1.', Comment = '%1=Reference No.';
        ItemRefWrongTypeErr: Label 'The reference type must be Customer or Vendor.';

    procedure EnterSalesItemReference(var SalesLine2: Record "Sales Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeEnterSalesItemReference(SalesLine2, ItemReference, Found, IsHandled);
        if IsHandled then
            exit;

        with SalesLine2 do
            if Type = Type::Item then begin
                FindItemReferenceForSalesLine(SalesLine2);

                if Found then begin
                    "Item Reference No." := ItemReference."Reference No.";
                    "Item Reference Unit of Measure" := ItemReference."Unit of Measure";
                    "Item Reference Type" := ItemReference."Reference Type";
                    if ItemReference.Description <> '' then begin
                        Description := ItemReference.Description;
                        "Description 2" := ItemReference."Description 2";
                    end;
                    "Item Reference Type No." := ItemReference."Reference Type No.";
                    OnAfterSalesItemReferenceFound(SalesLine2, ItemReference);
                end else begin
                    "Item Reference No." := '';
                    "Item Reference Type" := "Item Reference Type"::" ";
                    "Item Reference Type No." := '';
                    if "Variant Code" <> '' then begin
                        ItemVariant.Get("No.", "Variant Code");
                        Description := ItemVariant.Description;
                        "Description 2" := ItemVariant."Description 2";
                    end else begin
                        Item.Get("No.");
                        Description := Item.Description;
                        "Description 2" := Item."Description 2";
                    end;
                    GetItemTranslation();
                    OnAfterSalesItemItemRefNotFound(SalesLine2, ItemVariant);
                end;
            end;
    end;

    local procedure FindItemReferenceForSalesLine(SalesLine: Record "Sales Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindItemReferenceForSalesLine(SalesLine, ItemReference, Found, IsHandled);
        if IsHandled then
            exit;

        ItemReference.Reset();
        ItemReference.SetRange("Item No.", SalesLine."No.");
        ItemReference.SetRange("Variant Code", SalesLine."Variant Code");
        ItemReference.SetRange("Unit of Measure", SalesLine."Unit of Measure Code");
        ItemReference.SetRange("Reference Type", SalesLine."Item Reference Type"::Customer);
        ItemReference.SetRange("Reference Type No.", SalesLine."Sell-to Customer No.");
        ItemReference.SetRange("Reference No.", SalesLine."Item Reference No.");
        if ItemReference.FindFirst() then
            Found := true
        else begin
            ItemReference.SetRange("Reference No.");
            Found := ItemReference.FindFirst();
        end;
    end;

    procedure ReferenceLookupSalesItem(var SalesLine2: Record "Sales Line"; var ReturnedItemReference: Record "Item Reference"; ShowDialog: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReferenceLookupSalesItem(SalesLine2, ReturnedItemReference, ShowDialog, IsHandled);
        if IsHandled then
            exit;

        SalesLine.Copy(SalesLine2);
        if SalesLine.Type = SalesLine.Type::Item then
            FindOrSelectFromItemReferenceList(
                ReturnedItemReference, ShowDialog, SalesLine."No.", SalesLine."Item Reference No.", SalesLine."Sell-to Customer No.",
                ReturnedItemReference."Reference Type"::Customer);
    end;

    procedure EnterPurchaseItemReference(var PurchLine2: Record "Purchase Line")
    var
        ShouldAssignDescription: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeEnterPurchaseItemReference(PurchLine2, ItemReference, Found, IsHandled);
        if IsHandled then
            exit;

        with PurchLine2 do
            if Type = Type::Item then begin
                ItemReference.Reset();
                ItemReference.SetRange("Item No.", "No.");
                ItemReference.SetRange("Variant Code", "Variant Code");
                ItemReference.SetRange("Unit of Measure", "Unit of Measure Code");
                ItemReference.SetRange("Reference Type", "Item Reference Type"::Vendor);
                ItemReference.SetRange("Reference Type No.", "Buy-from Vendor No.");
                ItemReference.SetRange("Reference No.", "Item Reference No.");
                if ItemReference.FindFirst() then
                    Found := true
                else begin
                    ItemReference.SetRange("Reference No.");
                    Found := ItemReference.FindFirst();
                end;

                if Found then begin
                    "Item Reference No." := ItemReference."Reference No.";
                    "Item Reference Unit of Measure" := ItemReference."Unit of Measure";
                    "Item Reference Type" := ItemReference."Reference Type";
                    "Item Reference Type No." := ItemReference."Reference Type No.";
                    ShouldAssignDescription := ItemReference.Description <> '';
                    OnEnterPurchaseItemReferenceOnAfterCalcShouldAssignDescription(PurchLine2, ItemReference, ShouldAssignDescription);
                    if ShouldAssignDescription then begin
                        Description := ItemReference.Description;
                        "Description 2" := ItemReference."Description 2";
                    end;
                    OnAfterPurchItemReferenceFound(PurchLine2, ItemReference);
                end else begin
                    "Item Reference No." := '';
                    "Item Reference Type" := "Item Reference Type"::" ";
                    "Item Reference Type No." := '';
                    FillDescription(PurchLine2);
                    GetItemTranslation();
                    OnAfterPurchItemItemRefNotFound(PurchLine2, ItemVariant);
                end;
            end;
    end;

    local procedure FillDescription(var PurchaseLine: Record "Purchase Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFillDescription(PurchaseLine, IsHandled);
        if IsHandled then
            exit;

        if PurchaseLine."Variant Code" <> '' then begin
            ItemVariant.Get(PurchaseLine."No.", PurchaseLine."Variant Code");
            PurchaseLine.Description := ItemVariant.Description;
            PurchaseLine."Description 2" := ItemVariant."Description 2";
        end else begin
            Item.Get(PurchaseLine."No.");
            PurchaseLine.Description := Item.Description;
            PurchaseLine."Description 2" := Item."Description 2";
        end;
    end;

    procedure ReferenceLookupPurchaseItem(var PurchLine2: Record "Purchase Line"; var ReturnedItemReference: Record "Item Reference"; ShowDialog: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReferenceLookupPurchaseItem(PurchLine2, ReturnedItemReference, ShowDialog, IsHandled);
        if IsHandled then
            exit;

        PurchLine.Copy(PurchLine2);
        if PurchLine.Type = PurchLine.Type::Item then
            FindOrSelectFromItemReferenceList(
                ReturnedItemReference, ShowDialog, PurchLine."No.", PurchLine."Item Reference No.", PurchLine."Buy-from Vendor No.",
                ReturnedItemReference."Reference Type"::Vendor);
    end;

    local procedure FilterItemReferenceByItemVendor(var ItemReference: Record "Item Reference"; ItemVendor: Record "Item Vendor")
    begin
        ItemReference.Reset();
        ItemReference.SetRange("Item No.", ItemVendor."Item No.");
        ItemReference.SetRange("Variant Code", ItemVendor."Variant Code");
        ItemReference.SetRange("Reference Type", ItemReference."Reference Type"::Vendor);
        ItemReference.SetRange("Reference Type No.", ItemVendor."Vendor No.");
        ItemReference.SetRange("Reference No.", ItemVendor."Vendor Item No.");
    end;

    local procedure FillItemReferenceFromItemVendor(var ItemReference: Record "Item Reference"; ItemVend: Record "Item Vendor")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFillItemReferenceFromItemVendor(ItemReference, ItemVend, IsHandled);
        if IsHandled then
            exit;

        ItemReference.Init();
        ItemReference.Validate("Item No.", ItemVend."Item No.");
        ItemReference.Validate("Variant Code", ItemVend."Variant Code");
        ItemReference.Validate("Reference Type", ItemReference."Reference Type"::Vendor);
        ItemReference.Validate("Reference Type No.", ItemVend."Vendor No.");
        ItemReference."Reference No." := ItemVend."Vendor Item No.";
        if ItemReference."Unit of Measure" = '' then begin
            Item.Get(ItemVend."Item No.");
            ItemReference.Validate("Unit of Measure", Item."Base Unit of Measure");
        end;
    end;

    local procedure CreateItemReference(ItemVend: Record "Item Vendor")
    var
        ItemReference2: Record "Item Reference";
    begin
        FillItemReferenceFromItemVendor(ItemReference2, ItemVend);

        OnCreateItemReferenceOnBeforeInsert(ItemReference2, ItemVend);
        ItemReference2.Insert();
    end;

    procedure InsertItemReference(ItemVend: Record "Item Vendor")
    var
        ItemReference2: Record "Item Reference";
    begin
        FilterItemReferenceByItemVendor(ItemReference2, ItemVend);
        if ItemReference2.IsEmpty() then
            CreateItemReference(ItemVend);
    end;

    procedure DeleteItemReference(ItemVend: Record "Item Vendor")
    var
        ItemReference2: Record "Item Reference";
    begin
        FilterItemReferenceByItemVendor(ItemReference2, ItemVend);
        ItemReference2.DeleteAll();
    end;

    procedure UpdateItemReference(ItemVend: Record "Item Vendor"; xItemVend: Record "Item Vendor")
    begin
        // delete the item cross references
        DeleteItemReference(xItemVend);

        // insert the updated item cross references - faster then RENAME
        CreateItemReference(ItemVend);
    end;

    procedure FindOrSelectFromItemReferenceList(var ItemReferenceToReturn: Record "Item Reference"; ShowDialog: Boolean; ItemNo: Code[20]; ItemRefNo: Code[50]; ItemRefTypeNo: Code[30]; ItemRefType: Enum "Item Reference Type")
    var
        TempRecRequired: Boolean;
        MultipleItemsToChoose: Boolean;
        QtyCustOrVendCR: Integer;
        QtyBarCodeAndBlankCR: Integer;
    begin
        InitItemReferenceFilters(ItemReference, ItemNo, ItemRefNo, ItemRefType);
        CountItemReference(ItemReference, QtyCustOrVendCR, QtyBarCodeAndBlankCR, ItemRefType, ItemRefTypeNo);
        MultipleItemsToChoose := true;

        ProcessDecisionTree(QtyCustOrVendCR, QtyBarCodeAndBlankCR, ItemRefNo, ItemRefType, ItemRefTypeNo, TempRecRequired, MultipleItemsToChoose);

        SelectOrFindReference(ItemRefNo, ItemRefType, ItemRefTypeNo, TempRecRequired, MultipleItemsToChoose, ShowDialog);

        ItemReferenceToReturn.Copy(ItemReference);
    end;

    local procedure ProcessDecisionTree(QtyCustOrVendCR: Integer; QtyBarCodeAndBlankCR: Integer; ItemRefNo: Code[50]; ItemRefType: Enum "Item Reference Type"; ItemRefTypeNo: Code[30]; var TempRecRequired: Boolean; var MultipleItemsToChoose: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeProcessDecisionTree(ItemReference, QtyCustOrVendCR, QtyBarCodeAndBlankCR, ItemRefNo, ItemRefType, ItemRefTypeNo, TempRecRequired, MultipleItemsToChoose, IsHandled);
        if IsHandled then
            exit;

        case true of
            (QtyCustOrVendCR = 0) and (QtyBarCodeAndBlankCR = 0):
                Error(ItemRefNotExistErr, ItemRefNo);
            (QtyCustOrVendCR = 0) and (QtyBarCodeAndBlankCR = 1):
                MultipleItemsToChoose := false;
            (QtyCustOrVendCR = 0) and (QtyBarCodeAndBlankCR > 1):
                MultipleItemsToChoose := BarCodeCRAreMappedToDifferentItems(ItemReference);
            (QtyCustOrVendCR = 1) and (QtyBarCodeAndBlankCR = 0):
                MultipleItemsToChoose := false;
            (QtyCustOrVendCR = 1) and (QtyBarCodeAndBlankCR > 0):
                MultipleItemsToChoose := CustVendAndBarCodeCRAreMappedToDifferentItems(ItemReference, ItemRefType, ItemRefTypeNo);
            (QtyCustOrVendCR > 1) and (QtyBarCodeAndBlankCR = 0):
                SetFiltersTypeAndTypeNoItemRef(ItemReference, ItemRefType, ItemRefTypeNo);
            (QtyCustOrVendCR > 1) and (QtyBarCodeAndBlankCR > 0):
                TempRecRequired := true;
        end;
    end;

    local procedure SelectOrFindReference(ItemRefNo: Code[50]; ItemRefType: Enum "Item Reference Type"; ItemRefTypeNo: Code[30]; TempRecRequired: Boolean; MultipleItemsToChoose: Boolean; ShowDialog: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSelectOrFindReference(ItemReference, ItemRefNo, ItemRefType, ItemRefTypeNo, TempRecRequired, MultipleItemsToChoose, ShowDialog, IsHandled);
        if IsHandled then
            exit;

        if ShowDialog and MultipleItemsToChoose then begin
            if not RunPageReferenceListOnRealOrTempRec(ItemReference, TempRecRequired, ItemRefType, ItemRefTypeNo) then
                Error(ItemRefNotExistErr, ItemRefNo);
        end else
            if not FindFirstCustVendItemReference(ItemReference, ItemRefType, ItemRefTypeNo) then
                FindFirstBarCodeOrBlankTypeItemReference(ItemReference);
    end;

    local procedure InitItemReferenceFilters(var ItemReference: Record "Item Reference"; ItemNo: Code[20]; ItemRefNo: Code[50]; ItemRefType: Enum "Item Reference Type")
    begin
        ItemReference.Reset();
        ItemReference.SetCurrentKey("Reference No.", "Reference Type", "Reference Type No.");
        ItemReference.SetRange("Reference No.", ItemRefNo);
        ItemReference.SetRange("Item No.", ItemNo);
        ExcludeOtherReferenceTypes(ItemReference, ItemRefType);
        OnInitItemReferenceFiltersOnBeforeCheckIsEmpty(ItemReference, ItemRefType);
        if ItemReference.IsEmpty() then
            ItemReference.SetRange("Item No.");
    end;

    local procedure ExcludeOtherReferenceTypes(var ItemReference: Record "Item Reference"; ItemRefType: Enum "Item Reference Type")
    begin
        case ItemRefType of
            ItemReference."Reference Type"::" ":
                ItemReference.SetFilter("Reference Type", '<>%1&<>%2', ItemReference."Reference Type"::Customer, ItemReference."Reference Type"::Vendor);
            ItemReference."Reference Type"::Vendor:
                ItemReference.SetFilter("Reference Type", '<>%1', ItemReference."Reference Type"::Customer);
            ItemReference."Reference Type"::Customer:
                ItemReference.SetFilter("Reference Type", '<>%1', ItemReference."Reference Type"::Vendor);
            else
                Error(ItemRefWrongTypeErr);
        end;
    end;

    local procedure CountItemReference(var ItemReference: Record "Item Reference"; var QtyCustOrVendCR: Integer; var QtyBarCodeAndBlankCR: Integer; ItemRefType: Enum "Item Reference Type"; ItemRefTypeNo: Code[30])
    var
        ItemReferenceToCheck: Record "Item Reference";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCountItemReference(ItemReference, QtyCustOrVendCR, QtyBarCodeAndBlankCR, ItemRefType, ItemRefTypeNo, IsHandled);
        if IsHandled then
            exit;

        ItemReferenceToCheck.CopyFilters(ItemReference);
        SetFiltersTypeAndTypeNoItemRef(ItemReferenceToCheck, ItemRefType, ItemRefTypeNo);
        QtyCustOrVendCR := ItemReferenceToCheck.Count();
        SetFiltersBlankTypeItemRef(ItemReferenceToCheck);
        QtyBarCodeAndBlankCR := ItemReferenceToCheck.Count();
    end;

    local procedure BarCodeCRAreMappedToDifferentItems(var ItemReference: Record "Item Reference"): Boolean
    var
        ItemReferenceToCheck: Record "Item Reference";
    begin
        ItemReferenceToCheck.CopyFilters(ItemReference);
        SetFiltersBlankTypeItemRef(ItemReferenceToCheck);
        ItemReferenceToCheck.FindFirst();
        ItemReferenceToCheck.SetFilter("Item No.", '<>%1', ItemReferenceToCheck."Item No.");
        exit(not ItemReferenceToCheck.IsEmpty);
    end;

    local procedure CustVendAndBarCodeCRAreMappedToDifferentItems(var ItemReference: Record "Item Reference"; ItemRefType: Enum "Item Reference Type"; ItemRefTypeNo: Code[30]): Boolean
    var
        ItemReferenceToCheck: Record "Item Reference";
    begin
        ItemReferenceToCheck.CopyFilters(ItemReference);
        SetFiltersTypeAndTypeNoItemRef(ItemReferenceToCheck, ItemRefType, ItemRefTypeNo);
        ItemReferenceToCheck.FindFirst();
        ItemReferenceToCheck.SetFilter("Item No.", '<>%1', ItemReferenceToCheck."Item No.");
        SetFiltersBlankTypeItemRef(ItemReferenceToCheck);
        exit(not ItemReferenceToCheck.IsEmpty);
    end;

    local procedure RunPageReferenceListOnRealOrTempRec(var ItemReference: Record "Item Reference"; RunOnTempRec: Boolean; ItemRefType: Enum "Item Reference Type"; ItemRefTypeNo: Code[30]): Boolean
    begin
        if RunOnTempRec then
            exit(RunPageReferenceListOnTempRecord(
                ItemReference, ItemRefType, ItemRefTypeNo));
        exit(RunPageReferenceList(ItemReference));
    end;

    local procedure RunPageReferenceListOnTempRecord(var ItemReference: Record "Item Reference"; ItemRefType: Enum "Item Reference Type"; ItemRefTypeNo: Code[30]): Boolean
    var
        TempItemReference: Record "Item Reference" temporary;
        ItemReferenceToCopy: Record "Item Reference";
    begin
        ItemReferenceToCopy.CopyFilters(ItemReference);
        SetFiltersTypeAndTypeNoItemRef(ItemReferenceToCopy, ItemRefType, ItemRefTypeNo);
        InsertTempRecords(TempItemReference, ItemReferenceToCopy);
        SetFiltersBlankTypeItemRef(ItemReferenceToCopy);
        InsertTempRecords(TempItemReference, ItemReferenceToCopy);
        if RunPageReferenceList(TempItemReference) then begin
            ItemReference := TempItemReference;
            exit(true);
        end;
        exit(false);
    end;

    local procedure RunPageReferenceList(var ItemReference: Record "Item Reference"): Boolean
    begin
        ItemReference.FindFirst();
        exit(PAGE.RunModal(PAGE::"Item Reference List", ItemReference) = ACTION::LookupOK);
    end;

    local procedure InsertTempRecords(var TempItemReference: Record "Item Reference" temporary; var ItemReferenceToCopy: Record "Item Reference")
    begin
        if ItemReferenceToCopy.FindSet() then
            repeat
                TempItemReference := ItemReferenceToCopy;
                TempItemReference.Insert();
            until ItemReferenceToCopy.Next() = 0;
    end;

    local procedure FindFirstCustVendItemReference(var ItemReference: Record "Item Reference"; ItemRefType: Enum "Item Reference Type"; ItemRefTypeNo: Code[30]): Boolean
    var
        ItemReferenceToCheck: Record "Item Reference";
    begin
        SetFiltersTypeAndTypeNoItemRef(ItemReference, ItemRefType, ItemRefTypeNo);
        ItemReferenceToCheck.CopyFilters(ItemReference);
        if ItemReferenceToCheck.FindFirst() then begin
            ItemReference.Copy(ItemReferenceToCheck);
            exit(true);
        end;
        exit(false);
    end;

    local procedure FindFirstBarCodeOrBlankTypeItemReference(var ItemReference: Record "Item Reference")
    var
        ItemReferenceToCheck: Record "Item Reference";
    begin
        SetFiltersBlankTypeItemRef(ItemReference);
        ItemReferenceToCheck.CopyFilters(ItemReference);
        ItemReferenceToCheck.FindFirst();
        ItemReference.Copy(ItemReferenceToCheck);
    end;

    local procedure SetFiltersTypeAndTypeNoItemRef(var ItemReference: Record "Item Reference"; ItemRefType: Enum "Item Reference Type"; ItemRefTypeNo: Code[30])
    begin
        ItemReference.SetRange("Reference Type", ItemRefType);
        ItemReference.SetRange("Reference Type No.", ItemRefTypeNo);

        OnAfterSetFiltersTypeAndTypeNoItemRef(ItemReference, ItemRefType, ItemRefTypeNo);
    end;

    local procedure SetFiltersBlankTypeItemRef(var ItemReference: Record "Item Reference")
    begin
        ItemReference.SetFilter("Reference Type", '%1|%2', ItemReference."Reference Type"::" ", ItemReference."Reference Type"::"Bar Code");
        ItemReference.SetRange("Reference Type No.");
    end;

    procedure SalesReferenceNoLookup(var SalesLine: Record "Sales Line")
    var
        SalesHeader: record "Sales Header";
    begin
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        SalesReferenceNoLookup(SalesLine, SalesHeader);
    end;

    procedure SalesReferenceNoLookup(var SalesLine: Record "Sales Line"; SalesHeader: record "Sales Header")
    var
        ItemReference2: Record "Item Reference";
        ICGLAcc: Record "IC G/L Account";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSalesReferenceNoLookup(SalesLine, SalesHeader, IsHandled);
        if IsHandled then
            exit;
        with SalesLine do
            case Type of
                Type::Item:
                    begin
                        GetSalesHeader();
                        ItemReference2.Reset();
                        ItemReference2.SetCurrentKey("Reference Type", "Reference Type No.");
                        ItemReference2.SetFilter("Reference Type", '%1|%2', ItemReference2."Reference Type"::Customer, ItemReference2."Reference Type"::" ");
                        ItemReference2.SetFilter("Reference Type No.", '%1|%2', SalesHeader."Sell-to Customer No.", '');
                        OnSalesReferenceNoLookupOnAfterSetFilters(ItemReference2, SalesLine);
                        if PAGE.RunModal(PAGE::"Item Reference List", ItemReference2) = ACTION::LookupOK then begin
                            SalesLine."Item Reference No." := ItemReference2."Reference No.";
                            ValidateSalesReferenceNo(SalesLine, SalesHeader, ItemReference2, false, 0);
                            SalesLine.UpdateReferencePriceAndDiscount();
                            SalesReferenceNoLookupValidateUnitPrice(SalesLine, SalesHeader);
                        end;
                    end;
                Type::"G/L Account", Type::Resource:
                    begin
                        GetSalesHeader();
                        SalesHeader.TestField("Sell-to IC Partner Code");
                        if PAGE.RunModal(PAGE::"IC G/L Account List", ICGLAcc) = ACTION::LookupOK then
                            SalesLine."Item Reference No." := ICGLAcc."No.";
                    end;
            end;
    end;

    local procedure SalesReferenceNoLookupValidateUnitPrice(var SalesLine: Record "Sales Line"; SalesHeader: record "Sales Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnSalesReferenceNoLookupOnBeforeValidateUnitPrice(SalesLine, SalesHeader, IsHandled);
        if IsHandled then
            exit;

        SalesLine.Validate("Unit Price");
    end;

    procedure ValidateSalesReferenceNo(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; SearchItem: Boolean; CurrentFieldNo: Integer)
    var
        DummyItemReference: Record "Item Reference";
    begin
        ValidateSalesReferenceNo(SalesLine, SalesHeader, DummyItemReference, SearchItem, CurrentFieldNo);
    end;

    procedure ValidateSalesReferenceNo(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ItemReference: Record "Item Reference"; SearchItem: Boolean; CurrentFieldNo: Integer)
    var
        ReturnedItemReference: Record "Item Reference";
    begin
        ReturnedItemReference.Init();
        if SalesLine."Item Reference No." <> '' then begin
            if SearchItem then
                ReferenceLookupSalesItem(SalesLine, ReturnedItemReference, CurrentFieldNo <> 0)
            else
                ReturnedItemReference := ItemReference;

            OnValidateSalesReferenceNoOnBeforeAssignNo(SalesLine, ReturnedItemReference);
            if SalesLine."No." <> ReturnedItemReference."Item No." then
                SalesLine.Validate("No.", ReturnedItemReference."Item No.");
            if ReturnedItemReference."Variant Code" <> '' then
                SalesLine.Validate("Variant Code", ReturnedItemReference."Variant Code");
            if ReturnedItemReference."Unit of Measure" <> '' then
                SalesLine.Validate("Unit of Measure Code", ReturnedItemReference."Unit of Measure");
            OnValidateSalesReferenceNoOnAfterAssignNo(SalesLine, ReturnedItemReference);
        end;

        SalesLine."Item Reference Unit of Measure" := ReturnedItemReference."Unit of Measure";
        SalesLine."Item Reference Type" := ReturnedItemReference."Reference Type";
        SalesLine."Item Reference Type No." := ReturnedItemReference."Reference Type No.";
        SalesLine."Item Reference No." := ReturnedItemReference."Reference No.";

        if (ReturnedItemReference.Description <> '') or (ReturnedItemReference."Description 2" <> '') then begin
            SalesLine.Description := ReturnedItemReference.Description;
            SalesLine."Description 2" := ReturnedItemReference."Description 2";
        end;

        SalesLine.UpdateUnitPrice(SalesLine.FieldNo("Item Reference No."));
        SalesLine.UpdateICPartner();

        OnAfterValidateSalesReferenceNo(SalesLine, ItemReference, ReturnedItemReference);
    end;

    procedure PurchaseReferenceNoLookup(var PurchaseLine: Record "Purchase Line")
    var
        PurchHeader: Record "Purchase Header";
    begin
        PurchHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseReferenceNoLookup(PurchaseLine, PurchHeader);
    end;

    procedure PurchaseReferenceNoLookup(var PurchaseLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header")
    var
        ItemReference2: Record "Item Reference";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchaseReferenceNoLookup(PurchaseLine, PurchHeader, IsHandled);
        if IsHandled then
            exit;

        if PurchaseLine.Type = PurchaseLine.Type::Item then begin
            ItemReference2.Reset();
            ItemReference2.SetCurrentKey("Reference Type", "Reference Type No.");
            ItemReference2.SetFilter("Reference Type", '%1|%2', ItemReference2."Reference Type"::Vendor, ItemReference2."Reference Type"::" ");
            ItemReference2.SetFilter("Reference Type No.", '%1|%2', PurchHeader."Buy-from Vendor No.", '');
            OnPurchaseReferenceNoLookUpOnAfterSetFilters(ItemReference2, PurchaseLine);
            if PAGE.RunModal(PAGE::"Item Reference List", ItemReference2) = ACTION::LookupOK then begin
                PurchaseLine."Item Reference No." := ItemReference2."Reference No.";
                ValidatePurchaseReferenceNo(PurchaseLine, PurchHeader, ItemReference2, false, 0);
                PurchaseLine.UpdateReferencePriceAndDiscount();
                OnPurchaseReferenceNoLookupOnBeforeValidateDirectUnitCost(PurchaseLine, PurchHeader);
                PurchaseLine.Validate("Direct Unit Cost");
            end;
        end;
    end;

    procedure ValidatePurchaseReferenceNo(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ItemReference: Record "Item Reference"; SearchItem: Boolean; CurrentFieldNo: Integer)
    var
        ReturnedItemReference: Record "Item Reference";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidatePurchaseReferenceNo(PurchaseLine, PurchaseHeader, ItemReference, SearchItem, CurrentFieldNo, IsHandled);
        if not IsHandled then begin
            ReturnedItemReference.Init();
            if PurchaseLine."Item Reference No." <> '' then begin
                if SearchItem then
                    ReferenceLookupPurchaseItem(PurchaseLine, ReturnedItemReference, CurrentFieldNo <> 0)
                else
                    ReturnedItemReference := ItemReference;

                OnValidatePurchaseReferenceNoOnBeforeAssignNo(PurchaseLine, ReturnedItemReference);

                PurchaseLine.Validate("No.", ReturnedItemReference."Item No.");
                PurchaseLine.SetVendorItemNo();
                if ReturnedItemReference."Variant Code" <> '' then
                    PurchaseLine.Validate("Variant Code", ReturnedItemReference."Variant Code");
                if ReturnedItemReference."Unit of Measure" <> '' then
                    PurchaseLine.Validate("Unit of Measure Code", ReturnedItemReference."Unit of Measure");
                OnValidatePurchaseReferenceNoOnBeforePurchaseLineUpdateDirectUnitCost(PurchaseLine, ReturnedItemReference);
                PurchaseLine.UpdateDirectUnitCost(PurchaseLine.FieldNo("Item Reference No."));
            end;

            PurchaseLine."Item Reference Unit of Measure" := ReturnedItemReference."Unit of Measure";
            PurchaseLine."Item Reference Type" := ReturnedItemReference."Reference Type";
            PurchaseLine."Item Reference Type No." := ReturnedItemReference."Reference Type No.";
            PurchaseLine."Item Reference No." := ReturnedItemReference."Reference No.";

            if (ReturnedItemReference.Description <> '') or (ReturnedItemReference."Description 2" <> '') then begin
                PurchaseLine.Description := ReturnedItemReference.Description;
                PurchaseLine."Description 2" := ReturnedItemReference."Description 2";
            end;

            PurchaseLine.UpdateDirectUnitCost(PurchaseLine.FieldNo("Item Reference No."));
            PurchaseLine.UpdateICPartner();
        end;
        OnAfterValidatePurchaseReferenceNo(PurchaseLine, ItemReference, ReturnedItemReference);
    end;

    procedure PhysicalInventoryOrderReferenceNoLookup(var PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    var
        ItemReference2: Record "Item Reference";
    begin
        ItemReference2.Reset();
        ItemReference2.SetCurrentKey("Reference Type", "Reference Type No.");
        ItemReference2.SetRange("Reference Type", ItemReference2."Reference Type"::" ");
        ItemReference2.SetRange("Reference Type No.", '');
        OnPhysicalInventoryOrderReferenceNoLookupOnAfterSetFilters(ItemReference2, PhysInvtOrderLine);
        if Page.RunModal(Page::"Item Reference List", ItemReference2) = Action::LookupOK then begin
            PhysInvtOrderLine."Item Reference No." := ItemReference2."Reference No.";
            ValidatePhysicalInventoryOrderReferenceNo(PhysInvtOrderLine, ItemReference2, false, 0);
        end;
    end;

    procedure ValidatePhysicalInventoryOrderReferenceNo(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; ItemReference: Record "Item Reference"; SearchItem: Boolean; CurrentFieldNo: Integer)
    var
        ReturnedItemReference: Record "Item Reference";
    begin
        ReturnedItemReference.Init();
        if PhysInvtOrderLine."Item Reference No." <> '' then begin
            if SearchItem then
                ReferenceLookupPhysicalInventoryOrderItem(PhysInvtOrderLine, ReturnedItemReference, CurrentFieldNo <> 0)
            else
                ReturnedItemReference := ItemReference;

            OnValidatePhysicalInventoryOrderReferenceNoOnBeforeAssignNo(PhysInvtOrderLine, ReturnedItemReference);

            TestEmptyOrBaseItemUnitOfMeasure(ReturnedItemReference);
            PhysInvtOrderLine.Validate("Item No.", ReturnedItemReference."Item No.");
            if ReturnedItemReference."Variant Code" <> '' then
                PhysInvtOrderLine.Validate("Variant Code", ReturnedItemReference."Variant Code");
        end;

        PhysInvtOrderLine."Item Reference Unit of Measure" := ReturnedItemReference."Unit of Measure";
        PhysInvtOrderLine."Item Reference Type" := ReturnedItemReference."Reference Type";
        PhysInvtOrderLine."Item Reference Type No." := ReturnedItemReference."Reference Type No.";
        PhysInvtOrderLine."Item Reference No." := ReturnedItemReference."Reference No.";

        if (ReturnedItemReference.Description <> '') or (ReturnedItemReference."Description 2" <> '') then begin
            PhysInvtOrderLine.Description := ReturnedItemReference.Description;
            PhysInvtOrderLine."Description 2" := ReturnedItemReference."Description 2";
        end;
        OnAfterValidatePhysicalInventoryOrderReferenceNo(PhysInvtOrderLine, ItemReference, ReturnedItemReference);
    end;

    procedure ReferenceLookupPhysicalInventoryOrderItem(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; var ReturnedItemReference: Record "Item Reference"; ShowDialog: Boolean)
    var
        PhysInvtOrderLine2: Record "Phys. Invt. Order Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReferenceLookupPhysicalInventoryOrderItem(PhysInvtOrderLine, ReturnedItemReference, ShowDialog, IsHandled);
        if IsHandled then
            exit;

        PhysInvtOrderLine2.Copy(PhysInvtOrderLine);
        FindOrSelectFromItemReferenceList(ReturnedItemReference, ShowDialog, PhysInvtOrderLine2."Item No.", PhysInvtOrderLine2."Item Reference No.", '', ReturnedItemReference."Reference Type"::" ");
    end;

    procedure ItemJournalReferenceNoLookup(var ItemJournalLine: Record "Item Journal Line")
    var
        ItemReference2: Record "Item Reference";
    begin
        ItemReference2.Reset();
        ItemReference2.SetCurrentKey("Reference Type", "Reference Type No.");
        ItemReference2.SetRange("Reference Type", ItemReference2."Reference Type"::" ");
        ItemReference2.SetRange("Reference Type No.", '');
        OnItemJournalReferenceNoLookupOnAfterSetFilters(ItemReference2, ItemJournalLine);
        if Page.RunModal(Page::"Item Reference List", ItemReference2) = Action::LookupOK then begin
            ItemJournalLine."Item Reference No." := ItemReference2."Reference No.";
            ValidateItemJournalReferenceNo(ItemJournalLine, ItemReference2, false, 0);
        end;
    end;

    procedure ValidateItemJournalReferenceNo(var ItemJournalLine: Record "Item Journal Line"; ItemReference: Record "Item Reference"; SearchItem: Boolean; CurrentFieldNo: Integer)
    var
        ReturnedItemReference: Record "Item Reference";
    begin
        ReturnedItemReference.Init();
        if ItemJournalLine."Item Reference No." <> '' then begin
            if SearchItem then
                ReferenceLookupItemJournalItem(ItemJournalLine, ReturnedItemReference, CurrentFieldNo <> 0)
            else
                ReturnedItemReference := ItemReference;

            OnValidateItemJournalReferenceNoOnBeforeAssignNo(ItemJournalLine, ReturnedItemReference);

            TestEmptyOrBaseItemUnitOfMeasure(ReturnedItemReference);
            ItemJournalLine.Validate("Item No.", ReturnedItemReference."Item No.");
            if ReturnedItemReference."Variant Code" <> '' then
                ItemJournalLine.Validate("Variant Code", ReturnedItemReference."Variant Code");
        end;

        ItemJournalLine."Item Reference Unit of Measure" := ReturnedItemReference."Unit of Measure";
        ItemJournalLine."Item Reference Type" := ReturnedItemReference."Reference Type";
        ItemJournalLine."Item Reference Type No." := ReturnedItemReference."Reference Type No.";
        ItemJournalLine."Item Reference No." := ReturnedItemReference."Reference No.";

        if ReturnedItemReference.Description <> '' then
            ItemJournalLine.Description := ReturnedItemReference.Description;
        OnAfterValidateItemJournalReferenceNo(ItemJournalLine, ItemReference, ReturnedItemReference);
    end;

    procedure ReferenceLookupItemJournalItem(var ItemJournalLine: Record "Item Journal Line"; var ReturnedItemReference: Record "Item Reference"; ShowDialog: Boolean)
    var
        ItemJournalLine2: Record "Item Journal Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReferenceLookupItemJournalItem(ItemJournalLine, ReturnedItemReference, ShowDialog, IsHandled);
        if IsHandled then
            exit;

        ItemJournalLine2.Copy(ItemJournalLine);
        FindOrSelectFromItemReferenceList(ReturnedItemReference, ShowDialog, ItemJournalLine2."Item No.", ItemJournalLine2."Item Reference No.", '', ReturnedItemReference."Reference Type"::" ");
    end;

    local procedure TestEmptyOrBaseItemUnitOfMeasure(ItemReference: Record "Item Reference")
    begin
        ItemReference.TestField("Item No.");
        Item.Get(ItemReference."Item No.");
        if not (ItemReference."Unit of Measure" in ['', Item."Base Unit of Measure"]) then
            ItemReference.FieldError("Unit of Measure");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesItemReferenceFound(var SalesLine: Record "Sales Line"; ItemReference: Record "Item Reference")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesItemItemRefNotFound(var SalesLine: Record "Sales Line"; var ItemVariant: Record "Item Variant")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetFiltersTypeAndTypeNoItemRef(var ItemReference: Record "Item Reference"; ItemRefType: Enum "Item Reference Type"; ItemRefTypeNo: Code[30])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchItemReferenceFound(var PurchLine: Record "Purchase Line"; ItemReference: Record "Item Reference")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchItemItemRefNotFound(var PurchaseLine: Record "Purchase Line"; var ItemVariant: Record "Item Variant")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateSalesReferenceNo(var SalesLine: Record "Sales Line"; ItemReference: Record "Item Reference"; ReturnedItemReference: Record "Item Reference")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidatePurchaseReferenceNo(var PurchaseLine: Record "Purchase Line"; ItemReference: Record "Item Reference"; ReturnedItemReference: Record "Item Reference")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCountItemReference(var ItemReference: Record "Item Reference"; var QtyCustOrVendCR: Integer; var QtyBarCodeAndBlankCR: Integer; ItemRefType: Enum "Item Reference Type"; ItemRefTypeNo: Code[30]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEnterSalesItemReference(var SalesLine: Record "Sales Line"; var ItemReference: Record "Item Reference"; var Found: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindItemReferenceForSalesLine(SalesLine: Record "Sales Line"; var ItemReference: Record "Item Reference"; var Found: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFillDescription(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFillItemReferenceFromItemVendor(var ItemReference: Record "Item Reference"; ItemVend: Record "Item Vendor"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEnterPurchaseItemReference(var PurchaseLine2: Record "Purchase Line"; var ItemReference: Record "Item Reference"; var Found: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchaseReferenceNoLookup(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessDecisionTree(var ItemReference: Record "Item Reference"; QtyCustOrVendCR: Integer; QtyBarCodeAndBlankCR: Integer; ItemRefNo: Code[50]; ItemRefType: Enum "Item Reference Type"; ItemRefTypeNo: Code[30]; var TempRecRequired: Boolean; var MultipleItemsToChoose: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReferenceLookupSalesItem(var SalesLine: Record "Sales Line"; var ItemReference: Record "Item Reference"; ShowDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReferenceLookupPurchaseItem(var PurchaseLine: Record "Purchase Line"; var ItemReference: Record "Item Reference"; ShowDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesReferenceNoLookup(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSelectOrFindReference(var ItemReference: Record "Item Reference"; ItemRefNo: Code[50]; ItemRefType: Enum "Item Reference Type"; ItemRefTypeNo: Code[30]; TempRecRequired: Boolean; MultipleItemsToChoose: Boolean; ShowDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePurchaseReferenceNo(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ItemReference: Record "Item Reference"; SearchItem: Boolean; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateItemReferenceOnBeforeInsert(var ItemReference: Record "Item Reference"; ItemVendor: Record "Item Vendor")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEnterPurchaseItemReferenceOnAfterCalcShouldAssignDescription(var PurchaseLine: Record "Purchase Line"; ItemReference: Record "Item Reference"; var ShouldAssignDescription: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitItemReferenceFiltersOnBeforeCheckIsEmpty(var ItemReference: Record "Item Reference"; ItemRefType: Enum "Item Reference Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSalesReferenceNoLookupOnAfterSetFilters(var ItemReference: Record "Item Reference"; SalesLine: Record "Sales Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSalesReferenceNoLookupOnBeforeValidateUnitPrice(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPurchaseReferenceNoLookUpOnAfterSetFilters(var ItemReference: Record "Item Reference"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPurchaseReferenceNoLookupOnBeforeValidateDirectUnitCost(var PurchaseLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateSalesReferenceNoOnAfterAssignNo(var SalesLine: Record "Sales Line"; ReturnedItemReference: Record "Item Reference");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateSalesReferenceNoOnBeforeAssignNo(var SalesLine: Record "Sales Line"; ReturnedItemReference: Record "Item Reference");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePurchaseReferenceNoOnBeforePurchaseLineUpdateDirectUnitCost(var PurchaseLine: Record "Purchase Line"; ItemReference: Record "Item Reference")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePurchaseReferenceNoOnBeforeAssignNo(var PurchaseLine: Record "Purchase Line"; ReturnedItemReference: Record "Item Reference")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPhysicalInventoryOrderReferenceNoLookupOnAfterSetFilters(var ItemReference: Record "Item Reference"; PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReferenceLookupPhysicalInventoryOrderItem(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; var ItemReference: Record "Item Reference"; ShowDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePhysicalInventoryOrderReferenceNoOnBeforeAssignNo(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; ReturnedItemReference: Record "Item Reference")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidatePhysicalInventoryOrderReferenceNo(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; ItemReference: Record "Item Reference"; ReturnedItemReference: Record "Item Reference")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemJournalReferenceNoLookupOnAfterSetFilters(var ItemReference: Record "Item Reference"; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReferenceLookupItemJournalItem(var ItemJournalLine: Record "Item Journal Line"; var ItemReference: Record "Item Reference"; ShowDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateItemJournalReferenceNoOnBeforeAssignNo(var ItemJournalLine: Record "Item Journal Line"; ReturnedItemReference: Record "Item Reference")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateItemJournalReferenceNo(var ItemJournalLine: Record "Item Journal Line"; ItemReference: Record "Item Reference"; ReturnedItemReference: Record "Item Reference")
    begin
    end;
}

