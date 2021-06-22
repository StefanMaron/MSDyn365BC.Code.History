codeunit 5702 "Dist. Integration"
{

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'There are no items with cross reference %1.', Comment = '%1=Cross-Reference No.';
        ItemCrossReference: Record "Item Cross Reference";
        SalesLine: Record "Sales Line";
        PurchLine: Record "Purchase Line";
        ItemVariant: Record "Item Variant";
        Item: Record Item;
        Found: Boolean;
        Text001: Label 'The Quantity per Unit of Measure %1 has changed from %2 to %3 since the sales order was created. Adjust the quantity on the sales order or the unit of measure.', Comment = '%1=Unit of Measure Code,%2=Qty. per Unit of Measure in Sales Line,%3=Qty. per Unit of Measure in Item Unit of Measure';
        CrossRefWrongTypeErr: Label 'The cross reference type must be Customer or Vendor.';

    procedure EnterSalesItemCrossRef(var SalesLine2: Record "Sales Line")
    begin
        with SalesLine2 do
            if Type = Type::Item then begin
                ItemCrossReference.Reset();
                ItemCrossReference.SetRange("Item No.", "No.");
                ItemCrossReference.SetRange("Variant Code", "Variant Code");
                ItemCrossReference.SetRange("Unit of Measure", "Unit of Measure Code");
                ItemCrossReference.SetRange("Cross-Reference Type", "Cross-Reference Type"::Customer);
                ItemCrossReference.SetRange("Cross-Reference Type No.", "Sell-to Customer No.");
                ItemCrossReference.SetRange("Cross-Reference No.", "Cross-Reference No.");
                if ItemCrossReference.FindFirst then
                    Found := true
                else begin
                    ItemCrossReference.SetRange("Cross-Reference No.");
                    Found := ItemCrossReference.FindFirst;
                end;

                if Found then begin
                    "Cross-Reference No." := ItemCrossReference."Cross-Reference No.";
                    "Unit of Measure (Cross Ref.)" := ItemCrossReference."Unit of Measure";
                    "Cross-Reference Type" := ItemCrossReference."Cross-Reference Type";
                    if ItemCrossReference.Description <> '' then begin
                        Description := ItemCrossReference.Description;
                        "Description 2" := ItemCrossReference."Description 2";
                    end;
                    "Cross-Reference Type No." := ItemCrossReference."Cross-Reference Type No.";
                    OnAfterSalesItemCrossRefFound(SalesLine2, ItemCrossReference);
                end else begin
                    "Cross-Reference No." := '';
                    "Cross-Reference Type" := "Cross-Reference Type"::" ";
                    "Cross-Reference Type No." := '';
                    if "Variant Code" <> '' then begin
                        ItemVariant.Get("No.", "Variant Code");
                        Description := ItemVariant.Description;
                        "Description 2" := ItemVariant."Description 2";
                    end else begin
                        Item.Get("No.");
                        Description := Item.Description;
                        "Description 2" := Item."Description 2";
                    end;
                    GetItemTranslation;
                    OnAfterSalesItemCrossRefNotFound(SalesLine2, ItemVariant);
                end;
            end;
    end;

    procedure ICRLookupSalesItem(var SalesLine2: Record "Sales Line"; var ReturnedCrossRef: Record "Item Cross Reference"; ShowDialog: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeICRLookupSalesItem(SalesLine2, ReturnedCrossRef, ShowDialog, IsHandled);
        if IsHandled then
            exit;

        SalesLine.Copy(SalesLine2);
        if SalesLine.Type = SalesLine.Type::Item then
            FindOrSelectICROnCrossReferenceList(
              ReturnedCrossRef, ShowDialog, SalesLine."No.", SalesLine."Cross-Reference No.", SalesLine."Sell-to Customer No.",
              ReturnedCrossRef."Cross-Reference Type"::Customer);
    end;

    procedure EnterPurchaseItemCrossRef(var PurchLine2: Record "Purchase Line")
    begin
        with PurchLine2 do
            if Type = Type::Item then begin
                ItemCrossReference.Reset();
                ItemCrossReference.SetRange("Item No.", "No.");
                ItemCrossReference.SetRange("Variant Code", "Variant Code");
                ItemCrossReference.SetRange("Unit of Measure", "Unit of Measure Code");
                ItemCrossReference.SetRange("Cross-Reference Type", "Cross-Reference Type"::Vendor);
                ItemCrossReference.SetRange("Cross-Reference Type No.", "Buy-from Vendor No.");
                ItemCrossReference.SetRange("Cross-Reference No.", "Cross-Reference No.");
                if ItemCrossReference.FindFirst then
                    Found := true
                else begin
                    ItemCrossReference.SetRange("Cross-Reference No.");
                    Found := ItemCrossReference.FindFirst;
                end;

                if Found then begin
                    "Cross-Reference No." := ItemCrossReference."Cross-Reference No.";
                    "Unit of Measure (Cross Ref.)" := ItemCrossReference."Unit of Measure";
                    "Cross-Reference Type" := ItemCrossReference."Cross-Reference Type";
                    "Cross-Reference Type No." := ItemCrossReference."Cross-Reference Type No.";
                    if ItemCrossReference.Description <> '' then begin
                        Description := ItemCrossReference.Description;
                        "Description 2" := ItemCrossReference."Description 2";
                    end;
                    OnAfterPurchItemCrossRefFound(PurchLine2, ItemCrossReference);
                end else begin
                    "Cross-Reference No." := '';
                    "Cross-Reference Type" := "Cross-Reference Type"::" ";
                    "Cross-Reference Type No." := '';
                    if "Variant Code" <> '' then begin
                        ItemVariant.Get("No.", "Variant Code");
                        Description := ItemVariant.Description;
                        "Description 2" := ItemVariant."Description 2";
                    end else begin
                        Item.Get("No.");
                        Description := Item.Description;
                        "Description 2" := Item."Description 2";
                    end;
                    GetItemTranslation;
                    OnAfterPurchItemCrossRefNotFound(PurchLine2, ItemVariant);
                end;
            end;
    end;

    procedure ICRLookupPurchaseItem(var PurchLine2: Record "Purchase Line"; var ReturnedCrossRef: Record "Item Cross Reference"; ShowDialog: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeICRLookupPurchaseItem(PurchLine2, ReturnedCrossRef, ShowDialog, IsHandled);
        if IsHandled then
            exit;

        PurchLine.Copy(PurchLine2);
        if PurchLine.Type = PurchLine.Type::Item then
            FindOrSelectICROnCrossReferenceList(
              ReturnedCrossRef, ShowDialog, PurchLine."No.", PurchLine."Cross-Reference No.", PurchLine."Buy-from Vendor No.",
              ReturnedCrossRef."Cross-Reference Type"::Vendor);
    end;

    local procedure FilterItemCrossReferenceByItemVendor(var ItemCrossReference: Record "Item Cross Reference"; ItemVendor: Record "Item Vendor")
    begin
        ItemCrossReference.Reset();
        ItemCrossReference.SetRange("Item No.", ItemVendor."Item No.");
        ItemCrossReference.SetRange("Variant Code", ItemVendor."Variant Code");
        ItemCrossReference.SetRange("Cross-Reference Type", ItemCrossReference."Cross-Reference Type"::Vendor);
        ItemCrossReference.SetRange("Cross-Reference Type No.", ItemVendor."Vendor No.");
        ItemCrossReference.SetRange("Cross-Reference No.", ItemVendor."Vendor Item No.");
    end;

    local procedure FillItemCrossReferenceFromItemVendor(var ItemCrossReference: Record "Item Cross Reference"; ItemVend: Record "Item Vendor")
    begin
        ItemCrossReference.Init();
        ItemCrossReference.Validate("Item No.", ItemVend."Item No.");
        ItemCrossReference.Validate("Variant Code", ItemVend."Variant Code");
        ItemCrossReference.Validate("Cross-Reference Type", ItemCrossReference."Cross-Reference Type"::Vendor);
        ItemCrossReference.Validate("Cross-Reference Type No.", ItemVend."Vendor No.");
        ItemCrossReference."Cross-Reference No." := ItemVend."Vendor Item No.";
        if ItemCrossReference."Unit of Measure" = '' then begin
            Item.Get(ItemVend."Item No.");
            ItemCrossReference.Validate("Unit of Measure", Item."Base Unit of Measure");
        end;
    end;

    local procedure CreateItemCrossReference(ItemVend: Record "Item Vendor")
    var
        ItemCrossReference: Record "Item Cross Reference";
    begin
        FillItemCrossReferenceFromItemVendor(ItemCrossReference, ItemVend);
        ItemCrossReference.Insert();
    end;

    procedure InsertItemCrossReference(ItemVend: Record "Item Vendor")
    var
        ItemCrossReference: Record "Item Cross Reference";
    begin
        FilterItemCrossReferenceByItemVendor(ItemCrossReference, ItemVend);
        if ItemCrossReference.IsEmpty then
            CreateItemCrossReference(ItemVend);
    end;

    procedure DeleteItemCrossReference(ItemVend: Record "Item Vendor")
    var
        ItemCrossReference: Record "Item Cross Reference";
    begin
        FilterItemCrossReferenceByItemVendor(ItemCrossReference, ItemVend);
        ItemCrossReference.DeleteAll();
    end;

    procedure UpdateItemCrossReference(ItemVend: Record "Item Vendor"; xItemVend: Record "Item Vendor")
    begin
        // delete the item cross references
        DeleteItemCrossReference(xItemVend);

        // insert the updated item cross references - faster then RENAME
        CreateItemCrossReference(ItemVend);
    end;

    local procedure FindOrSelectICROnCrossReferenceList(var ItemCrossReferenceToReturn: Record "Item Cross Reference"; ShowDialog: Boolean; ItemNo: Code[20]; CrossRefNo: Code[20]; CrossRefTypeNo: Code[30]; CrossRefType: Integer)
    var
        TempRecRequired: Boolean;
        MultipleItemsToChoose: Boolean;
        QtyCustOrVendCR: Integer;
        QtyBarCodeAndBlankCR: Integer;
    begin
        InitItemCrossReferenceFilters(ItemCrossReference, ItemNo, CrossRefNo, CrossRefType);
        CountItemCrossReference(ItemCrossReference, QtyCustOrVendCR, QtyBarCodeAndBlankCR, CrossRefType, CrossRefTypeNo);
        MultipleItemsToChoose := true;

        case true of
            (QtyCustOrVendCR = 0) and (QtyBarCodeAndBlankCR = 0):
                Error(Text000, CrossRefNo);
            (QtyCustOrVendCR = 0) and (QtyBarCodeAndBlankCR = 1):
                MultipleItemsToChoose := false;
            (QtyCustOrVendCR = 0) and (QtyBarCodeAndBlankCR > 1):
                MultipleItemsToChoose := BarCodeCRAreMappedToDifferentItems(ItemCrossReference);
            (QtyCustOrVendCR = 1) and (QtyBarCodeAndBlankCR = 0):
                MultipleItemsToChoose := false;
            (QtyCustOrVendCR = 1) and (QtyBarCodeAndBlankCR > 0):
                MultipleItemsToChoose := CustVendAndBarCodeCRAreMappedToDifferentItems(ItemCrossReference, CrossRefType, CrossRefTypeNo);
            (QtyCustOrVendCR > 1) and (QtyBarCodeAndBlankCR = 0):
                SetFiltersTypeAndTypeNoItemCrossRef(ItemCrossReference, CrossRefType, CrossRefTypeNo);
            (QtyCustOrVendCR > 1) and (QtyBarCodeAndBlankCR > 0):
                TempRecRequired := true;
        end;

        if ShowDialog and MultipleItemsToChoose then begin
            if not RunPageCrossReferenceListOnRealOrTempRec(ItemCrossReference, TempRecRequired, CrossRefType, CrossRefTypeNo) then
                Error(Text000, CrossRefNo);
        end else
            if not FindFirstCustVendItemCrossReference(ItemCrossReference, CrossRefType, CrossRefTypeNo) then
                FindFirstBarCodeOrBlankTypeItemCrossReference(ItemCrossReference);

        ItemCrossReferenceToReturn.Copy(ItemCrossReference);
    end;

    local procedure InitItemCrossReferenceFilters(var ItemCrossReference: Record "Item Cross Reference"; ItemNo: Code[20]; CrossRefNo: Code[20]; CrossRefType: Integer)
    begin
        with ItemCrossReference do begin
            Reset;
            SetCurrentKey(
              "Cross-Reference No.", "Cross-Reference Type", "Cross-Reference Type No.", "Discontinue Bar Code");
            SetRange("Cross-Reference No.", CrossRefNo);
            SetRange("Item No.", ItemNo);
            SetFilter("Cross-Reference Type", '<>%1', GetCrossReferenceTypeToExclude(CrossRefType));
            SetRange("Discontinue Bar Code", false);
            if IsEmpty then
                SetRange("Item No.");
        end;
    end;

    local procedure GetCrossReferenceTypeToExclude(CrossRefType: Integer): Integer
    begin
        case CrossRefType of
            ItemCrossReference."Cross-Reference Type"::Vendor:
                exit(ItemCrossReference."Cross-Reference Type"::Customer);
            ItemCrossReference."Cross-Reference Type"::Customer:
                exit(ItemCrossReference."Cross-Reference Type"::Vendor);
            else
                Error(CrossRefWrongTypeErr);
        end;
    end;

    local procedure CountItemCrossReference(var ItemCrossReference: Record "Item Cross Reference"; var QtyCustOrVendCR: Integer; var QtyBarCodeAndBlankCR: Integer; CrossRefType: Integer; CrossRefTypeNo: Code[30])
    var
        ItemCrossReferenceToCheck: Record "Item Cross Reference";
    begin
        ItemCrossReferenceToCheck.CopyFilters(ItemCrossReference);
        SetFiltersTypeAndTypeNoItemCrossRef(ItemCrossReferenceToCheck, CrossRefType, CrossRefTypeNo);
        QtyCustOrVendCR := ItemCrossReferenceToCheck.Count();
        SetFiltersBarCodeOrBlankTypeItemCrossRef(ItemCrossReferenceToCheck);
        QtyBarCodeAndBlankCR := ItemCrossReferenceToCheck.Count();
    end;

    local procedure BarCodeCRAreMappedToDifferentItems(var ItemCrossReference: Record "Item Cross Reference"): Boolean
    var
        ItemCrossReferenceToCheck: Record "Item Cross Reference";
    begin
        ItemCrossReferenceToCheck.CopyFilters(ItemCrossReference);
        SetFiltersBarCodeOrBlankTypeItemCrossRef(ItemCrossReferenceToCheck);
        ItemCrossReferenceToCheck.FindFirst;
        ItemCrossReferenceToCheck.SetFilter("Item No.", '<>%1', ItemCrossReferenceToCheck."Item No.");
        exit(not ItemCrossReferenceToCheck.IsEmpty);
    end;

    local procedure CustVendAndBarCodeCRAreMappedToDifferentItems(var ItemCrossReference: Record "Item Cross Reference"; CrossRefType: Integer; CrossRefTypeNo: Code[30]): Boolean
    var
        ItemCrossReferenceToCheck: Record "Item Cross Reference";
    begin
        ItemCrossReferenceToCheck.CopyFilters(ItemCrossReference);
        SetFiltersTypeAndTypeNoItemCrossRef(ItemCrossReferenceToCheck, CrossRefType, CrossRefTypeNo);
        ItemCrossReferenceToCheck.FindFirst;
        ItemCrossReferenceToCheck.SetFilter("Item No.", '<>%1', ItemCrossReferenceToCheck."Item No.");
        SetFiltersBarCodeOrBlankTypeItemCrossRef(ItemCrossReferenceToCheck);
        exit(not ItemCrossReferenceToCheck.IsEmpty);
    end;

    local procedure RunPageCrossReferenceListOnRealOrTempRec(var ItemCrossReference: Record "Item Cross Reference"; RunOnTempRec: Boolean; CrossRefType: Integer; CrossRefTypeNo: Code[30]): Boolean
    begin
        if RunOnTempRec then
            exit(RunPageCrossReferenceListOnTempRecord(
                ItemCrossReference, CrossRefType, CrossRefTypeNo));
        exit(RunPageCrossReferenceList(ItemCrossReference));
    end;

    local procedure RunPageCrossReferenceListOnTempRecord(var ItemCrossReference: Record "Item Cross Reference"; CrossRefType: Integer; CrossRefTypeNo: Code[30]): Boolean
    var
        TempItemCrossReference: Record "Item Cross Reference" temporary;
        ItemCrossReferenceToCopy: Record "Item Cross Reference";
    begin
        ItemCrossReferenceToCopy.CopyFilters(ItemCrossReference);
        SetFiltersTypeAndTypeNoItemCrossRef(ItemCrossReferenceToCopy, CrossRefType, CrossRefTypeNo);
        InsertTempRecords(TempItemCrossReference, ItemCrossReferenceToCopy);
        SetFiltersBarCodeOrBlankTypeItemCrossRef(ItemCrossReferenceToCopy);
        InsertTempRecords(TempItemCrossReference, ItemCrossReferenceToCopy);
        if RunPageCrossReferenceList(TempItemCrossReference) then begin
            ItemCrossReference := TempItemCrossReference;
            exit(true);
        end;
        exit(false);
    end;

    local procedure RunPageCrossReferenceList(var ItemCrossReference: Record "Item Cross Reference"): Boolean
    begin
        ItemCrossReference.FindFirst;
        exit(PAGE.RunModal(PAGE::"Cross Reference List", ItemCrossReference) = ACTION::LookupOK);
    end;

    local procedure InsertTempRecords(var TempItemCrossReference: Record "Item Cross Reference" temporary; var ItemCrossReferenceToCopy: Record "Item Cross Reference")
    begin
        if ItemCrossReferenceToCopy.FindSet then
            repeat
                TempItemCrossReference := ItemCrossReferenceToCopy;
                TempItemCrossReference.Insert();
            until ItemCrossReferenceToCopy.Next = 0;
    end;

    local procedure FindFirstCustVendItemCrossReference(var ItemCrossReference: Record "Item Cross Reference"; CrossRefType: Integer; CrossRefTypeNo: Code[30]): Boolean
    var
        ItemCrossReferenceToCheck: Record "Item Cross Reference";
    begin
        SetFiltersTypeAndTypeNoItemCrossRef(ItemCrossReference, CrossRefType, CrossRefTypeNo);
        ItemCrossReferenceToCheck.CopyFilters(ItemCrossReference);
        if ItemCrossReferenceToCheck.FindFirst then begin
            ItemCrossReference.Copy(ItemCrossReferenceToCheck);
            exit(true);
        end;
        exit(false);
    end;

    local procedure FindFirstBarCodeOrBlankTypeItemCrossReference(var ItemCrossReference: Record "Item Cross Reference")
    var
        ItemCrossReferenceToCheck: Record "Item Cross Reference";
    begin
        SetFiltersBarCodeOrBlankTypeItemCrossRef(ItemCrossReference);
        ItemCrossReferenceToCheck.CopyFilters(ItemCrossReference);
        ItemCrossReferenceToCheck.FindFirst;
        ItemCrossReference.Copy(ItemCrossReferenceToCheck);
    end;

    local procedure SetFiltersTypeAndTypeNoItemCrossRef(var ItemCrossReference: Record "Item Cross Reference"; CrossRefType: Integer; CrossRefTypeNo: Code[30])
    begin
        ItemCrossReference.SetRange("Cross-Reference Type", CrossRefType);
        ItemCrossReference.SetRange("Cross-Reference Type No.", CrossRefTypeNo);
    end;

    local procedure SetFiltersBarCodeOrBlankTypeItemCrossRef(var ItemCrossReference: Record "Item Cross Reference")
    begin
        ItemCrossReference.SetFilter(
          "Cross-Reference Type", '%1|%2', ItemCrossReference."Cross-Reference Type"::" ",
          ItemCrossReference."Cross-Reference Type"::"Bar Code");
        ItemCrossReference.SetRange("Cross-Reference Type No.");
    end;

    procedure GetSpecialOrders(var PurchHeader: Record "Purchase Header")
    var
        SalesHeader: Record "Sales Header";
        PurchLine2: Record "Purchase Line";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Vendor: Record Vendor;
        TransferExtendedText: Codeunit "Transfer Extended Text";
        CopyDocMgt: Codeunit "Copy Document Mgt.";
        NextLineNo: Integer;
        IsHandled: Boolean;
    begin
        with PurchHeader do begin
            TestField("Document Type", "Document Type"::Order);

            IsHandled := false;
            OnGetSpecialOrdersOnBeforeSelectSalesHeader(PurchHeader, SalesHeader, IsHandled);
            if not IsHandled then begin
                SalesHeader.SetCurrentKey("Document Type", "Sell-to Customer No.");
                SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
                SalesHeader.SetRange("Sell-to Customer No.", "Sell-to Customer No.");
                if (PAGE.RunModal(PAGE::"Sales List", SalesHeader) <> ACTION::LookupOK) or
                   (SalesHeader."No." = '')
                then
                    exit;
            end;

            LockTable();

            OnGetSpecialOrdersOnBeforeTestSalesHeader(SalesHeader);

            SalesHeader.TestField("Document Type", SalesHeader."Document Type"::Order);
            TestField("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
            if "Ship-to Code" <> '' then
                TestField("Ship-to Code", SalesHeader."Ship-to Code");
            if SpecialOrderExists(SalesHeader) then begin
                Validate("Location Code", SalesHeader."Location Code");
                AddSpecialOrderToAddress(SalesHeader, true);
            end;

            if Vendor.Get("Buy-from Vendor No.") then
                Validate("Shipment Method Code", Vendor."Shipment Method Code");

            PurchLine.LockTable();
            SalesLine.LockTable();

            PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
            PurchLine.SetRange("Document No.", "No.");
            if PurchLine.FindLast then
                NextLineNo := PurchLine."Line No." + 10000
            else
                NextLineNo := 10000;

            SalesLine.Reset();
            SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
            SalesLine.SetRange("Document No.", SalesHeader."No.");
            SalesLine.SetRange("Special Order", true);
            SalesLine.SetFilter("Outstanding Quantity", '<>0');
            SalesLine.SetRange(Type, SalesLine.Type::Item);
            SalesLine.SetFilter("No.", '<>%1', '');
            SalesLine.SetRange("Special Order Purch. Line No.", 0);
            OnGetSpecialOrdersOnAfterSalesLineSetFilters(SalesLine, SalesHeader);
            if SalesLine.FindSet then
                repeat
                    IsHandled := false;
                    OnGetSpecialOrdersOnBeforeTestSalesLine(SalesLine, PurchHeader, IsHandled);
                    if not IsHandled then
                        if (SalesLine.Type = SalesLine.Type::Item) and
                           ItemUnitOfMeasure.Get(SalesLine."No.", SalesLine."Unit of Measure Code")
                        then
                            if SalesLine."Qty. per Unit of Measure" <> ItemUnitOfMeasure."Qty. per Unit of Measure" then
                                Error(Text001,
                                  SalesLine."Unit of Measure Code", SalesLine."Qty. per Unit of Measure",
                                  ItemUnitOfMeasure."Qty. per Unit of Measure");

                    PurchLine.Init();
                    PurchLine."Document Type" := PurchLine."Document Type"::Order;
                    PurchLine."Document No." := "No.";
                    PurchLine."Line No." := NextLineNo;
                    CopyDocMgt.TransfldsFromSalesToPurchLine(SalesLine, PurchLine);
                    PurchLine.GetItemTranslation;
                    PurchLine."Special Order" := true;
                    PurchLine."Purchasing Code" := SalesLine."Purchasing Code";
                    PurchLine."Special Order Sales No." := SalesLine."Document No.";
                    PurchLine."Special Order Sales Line No." := SalesLine."Line No.";
                    OnBeforeInsertPurchLine(PurchLine, SalesLine);
                    PurchLine.Insert();
                    OnAfterInsertPurchLine(PurchLine, SalesLine);

                    NextLineNo := NextLineNo + 10000;

                    SalesLine."Unit Cost (LCY)" := PurchLine."Unit Cost (LCY)";
                    SalesLine.Validate("Unit Cost (LCY)");
                    SalesLine."Special Order Purchase No." := PurchLine."Document No.";
                    SalesLine."Special Order Purch. Line No." := PurchLine."Line No.";
                    OnBeforeSalesLineModify(SalesLine, PurchLine);
                    SalesLine.Modify();
                    OnAfterSalesLineModify(SalesLine, PurchLine);
                    if TransferExtendedText.PurchCheckIfAnyExtText(PurchLine, true) then begin
                        TransferExtendedText.InsertPurchExtText(PurchLine);
                        PurchLine2.SetRange("Document Type", "Document Type");
                        PurchLine2.SetRange("Document No.", "No.");
                        if PurchLine2.FindLast then
                            NextLineNo := PurchLine2."Line No.";
                        NextLineNo := NextLineNo + 10000;
                    end;
                    OnGetSpecialOrdersOnAfterTransferExtendedText(SalesLine, PurchHeader, NextLineNo);
                until SalesLine.Next = 0
            else
                Error(
                  Text000,
                  SalesHeader."No.");

            Modify; // Only version check
            SalesHeader.Modify(); // Only version check
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertPurchLine(var PurchaseLine: Record "Purchase Line"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesLineModify(var SalesLine: Record "Sales Line"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertPurchLine(var PurchaseLine: Record "Purchase Line"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesLineModify(var SalesLine: Record "Sales Line"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesItemCrossRefFound(var SalesLine: Record "Sales Line"; ItemCrossReference: Record "Item Cross Reference")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesItemCrossRefNotFound(var SalesLine: Record "Sales Line"; var ItemVariant: Record "Item Variant")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchItemCrossRefFound(var PurchLine: Record "Purchase Line"; ItemCrossReference: Record "Item Cross Reference")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchItemCrossRefNotFound(var PurchaseLine: Record "Purchase Line"; var ItemVariant: Record "Item Variant")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeICRLookupSalesItem(var SalesLine: Record "Sales Line"; var ItemCrossReference: Record "Item Cross Reference"; ShowDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeICRLookupPurchaseItem(var PurchaseLine: Record "Purchase Line"; var ItemCrossReference: Record "Item Cross Reference"; ShowDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSpecialOrdersOnAfterSalesLineSetFilters(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSpecialOrdersOnAfterTransferExtendedText(SalesLine: Record "Sales Line"; PurchaseHeader: Record "Purchase Header"; var NextLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSpecialOrdersOnBeforeSelectSalesHeader(var PurchaseHeader: Record "Purchase Header"; var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSpecialOrdersOnBeforeTestSalesHeader(SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSpecialOrdersOnBeforeTestSalesLine(SalesLine: Record "Sales Line"; PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;
}

