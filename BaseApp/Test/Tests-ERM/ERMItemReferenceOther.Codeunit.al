codeunit 134466 "ERM Item Reference Other"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Item Reference] [Reference No]
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemReference: Codeunit "Library - Item Reference";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        ItemRefNotExistsErr: Label 'There are no items with reference %1.';
        ItemReferenceMgt: Codeunit "Item Reference Management";
        IsInitialized: Boolean;

    [Test]
    procedure IRLookupItemJournalWhenBarCodeAndExpiredBarCodeShowDialogTrue()
    var
        ItemReference: array[2] of Record "Item Reference";
        ReturnedItemReference: Record "Item Reference";
        ItemJournalLine: Record "Item Journal Line";
        ItemReferenceNo: Code[50];
    begin
        Initialize();

        // [GIVEN] Barcode for multiple item references
        ItemReferenceNo := LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), Database::"Item Reference");

        // [GIVEN] Item Journal with the item reference
        CreateItemJournalLine(ItemJournalLine);
        ItemJournalLine."Item Reference No." := ItemReferenceNo;
        ItemJournalLine.Modify();

        // [GIVEN] Item References for Item X and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNoAndDates(ItemReference[1], ItemReferenceNo, LibraryInventory.CreateItemNo(),
          ItemReference[1]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID(),
           CalcDate('<-1M>', ItemJournalLine.GetDateForCalculations()), CalcDate('<-1D>', ItemJournalLine.GetDateForCalculations()));

        // [GIVEN] Item References for Item Y and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[2], ItemReferenceNo, LibraryInventory.CreateItemNo(),
          ItemReference[2]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID());

        // [WHEN] Ran ReferenceLookupItemJournalItem from codeunit Dist. Integration for the Item Journal Line with ShowDialog = TRUE
        ItemReferenceMgt.ReferenceLookupItemJournalItem(ItemJournalLine, ReturnedItemReference, true);

        // [THEN] Item Reference with Item No = X is ignored
        // [THEN] ReferenceLookupItemJournalItem returns Item Reference with Item No = Y
        ReturnedItemReference.TestField("Item No.", ItemReference[2]."Item No.");
    end;

    [Test]
    [HandlerFunctions('ItemReferenceListModalPageHandler')]
    procedure IRLookupItemJournalWhenBarCodeAndBarCodeDateLimitedShowDialogTrue()
    var
        ItemReference: array[2] of Record "Item Reference";
        ReturnedItemReference: Record "Item Reference";
        ItemJournalLine: Record "Item Journal Line";
        ItemReferenceNo: Code[50];
    begin
        Initialize();

        // [GIVEN] Barcode for multiple item references
        ItemReferenceNo := LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), Database::"Item Reference");
        LibraryVariableStorage.Enqueue(ItemReferenceNo);

        // [GIVEN] Item Journal with the item reference
        CreateItemJournalLine(ItemJournalLine);
        ItemJournalLine."Item Reference No." := ItemReferenceNo;
        ItemJournalLine.Modify();

        // [GIVEN] Item References for Item X and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNoAndDates(ItemReference[1], ItemReferenceNo, LibraryInventory.CreateItemNo(),
          ItemReference[1]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID(),
           CalcDate('<-1M>', ItemJournalLine.GetDateForCalculations()), CalcDate('<+1M>', ItemJournalLine.GetDateForCalculations()));
        EnqueueItemReferenceFields(ItemReference[1]);

        // [GIVEN] Item References for Item Y and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[2], ItemReferenceNo, LibraryInventory.CreateItemNo(),
          ItemReference[2]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID());
        EnqueueItemReferenceFields(ItemReference[2]);

        // [WHEN] Ran ReferenceLookupItemJournalItem from codeunit Dist. Integration for the Item Journal Line with ShowDialog = TRUE
        ItemReferenceMgt.ReferenceLookupItemJournalItem(ItemJournalLine, ReturnedItemReference, true);

        // [GIVEN] Page Item Reference List opened showing both Item References
        // [GIVEN] User selected the second one
        // Done in ItemReferenceListModalPageHandler

        // [THEN] ReferenceLookupItemJournalItem returns Item Reference with Item No = Y
        ReturnedItemReference.TestField("Item No.", ItemReference[2]."Item No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure IRLookupItemJournalWhenTwoExpiredBarCodesShowDialogTrue()
    var
        ItemReference: array[2] of Record "Item Reference";
        ReturnedItemReference: Record "Item Reference";
        ItemJournalLine: Record "Item Journal Line";
        ItemReferenceNo: Code[50];
    begin
        Initialize();

        // [GIVEN] Barcode for multiple item references
        ItemReferenceNo := LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), Database::"Item Reference");

        // [GIVEN] Item Journal with the item reference
        CreateItemJournalLine(ItemJournalLine);
        ItemJournalLine."Item Reference No." := ItemReferenceNo;
        ItemJournalLine.Modify();

        // [GIVEN] Item References for Item X and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNoAndDates(ItemReference[1], ItemReferenceNo, LibraryInventory.CreateItemNo(),
          ItemReference[1]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID(),
           CalcDate('<-1M>', ItemJournalLine.GetDateForCalculations()), CalcDate('<-1D>', ItemJournalLine.GetDateForCalculations()));

        // [GIVEN] Item References for Item Y and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNoAndDates(ItemReference[2], ItemReferenceNo, LibraryInventory.CreateItemNo(),
          ItemReference[2]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID(),
           CalcDate('<+1D>', ItemJournalLine.GetDateForCalculations()), CalcDate('<+1M>', ItemJournalLine.GetDateForCalculations()));

        // [WHEN] Ran ReferenceLookupItemJournalItem from codeunit Dist. Integration for the Item Journal Line with ShowDialog = TRUE
        asserterror ItemReferenceMgt.ReferenceLookupItemJournalItem(ItemJournalLine, ReturnedItemReference, true);

        // [THEN] Error "There are no items with reference %1."
        Assert.ExpectedError(StrSubstNo(ItemRefNotExistsErr, ItemReferenceNo));
    end;

    [Test]
    procedure IRLookupPhysInvOrderWhenBarCodeAndExpiredBarCodeShowDialogTrue()
    var
        ItemReference: array[2] of Record "Item Reference";
        ReturnedItemReference: Record "Item Reference";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        ItemReferenceNo: Code[50];
    begin
        Initialize();

        // [GIVEN] Barcode for multiple item references
        ItemReferenceNo := LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), Database::"Item Reference");

        // [GIVEN] Phys. Invt. Order with the item reference
        CreatePhysInvtOrderLine(PhysInvtOrderLine);
        PhysInvtOrderLine."Item Reference No." := ItemReferenceNo;
        PhysInvtOrderLine.Modify();

        // [GIVEN] Item References for Item X and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNoAndDates(ItemReference[1], ItemReferenceNo, LibraryInventory.CreateItemNo(),
          ItemReference[1]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID(),
           CalcDate('<-1M>', PhysInvtOrderLine.GetDateForCalculations()), CalcDate('<-1D>', PhysInvtOrderLine.GetDateForCalculations()));

        // [GIVEN] Item References for Item Y and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[2], ItemReferenceNo, LibraryInventory.CreateItemNo(),
          ItemReference[2]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID());

        // [WHEN] Ran ReferenceLookupPhysicalInventoryOrderItem from codeunit Dist. Integration for the Phys. Invt. Order Line with ShowDialog = TRUE
        ItemReferenceMgt.ReferenceLookupPhysicalInventoryOrderItem(PhysInvtOrderLine, ReturnedItemReference, true);

        // [THEN] Item Reference with Item No = X is ignored
        // [THEN] ReferenceLookupPhysicalInventoryOrderItem returns Item Reference with Item No = Y
        ReturnedItemReference.TestField("Item No.", ItemReference[2]."Item No.");
    end;

    [Test]
    [HandlerFunctions('ItemReferenceListModalPageHandler')]
    procedure IRLookupPhysInvOrderWhenBarCodeAndBarCodeDateLimitedShowDialogTrue()
    var
        ItemReference: array[2] of Record "Item Reference";
        ReturnedItemReference: Record "Item Reference";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        ItemReferenceNo: Code[50];
    begin
        Initialize();

        // [GIVEN] Barcode for multiple item references
        ItemReferenceNo := LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), Database::"Item Reference");
        LibraryVariableStorage.Enqueue(ItemReferenceNo);

        // [GIVEN] Phys. Invt. Order with the item reference
        CreatePhysInvtOrderLine(PhysInvtOrderLine);
        PhysInvtOrderLine."Item Reference No." := ItemReferenceNo;
        PhysInvtOrderLine.Modify();

        // [GIVEN] Item References for Item X and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNoAndDates(ItemReference[1], ItemReferenceNo, LibraryInventory.CreateItemNo(),
          ItemReference[1]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID(),
           CalcDate('<-1M>', PhysInvtOrderLine.GetDateForCalculations()), CalcDate('<+1M>', PhysInvtOrderLine.GetDateForCalculations()));
        EnqueueItemReferenceFields(ItemReference[1]);

        // [GIVEN] Item References for Item Y and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[2], ItemReferenceNo, LibraryInventory.CreateItemNo(),
          ItemReference[2]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID());
        EnqueueItemReferenceFields(ItemReference[2]);

        // [WHEN] Ran ReferenceLookupPhysicalInventoryOrderItem from codeunit Dist. Integration for the Phys. Invt. Order Line with ShowDialog = TRUE
        ItemReferenceMgt.ReferenceLookupPhysicalInventoryOrderItem(PhysInvtOrderLine, ReturnedItemReference, true);

        // [GIVEN] Page Item Reference List opened showing both Item References
        // [GIVEN] User selected the second one
        // Done in ItemReferenceListModalPageHandler

        // [THEN] ReferenceLookupPhysicalInventoryOrderItem returns Item Reference with Item No = Y
        ReturnedItemReference.TestField("Item No.", ItemReference[2]."Item No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure IRLookupPhysInvOrderWhenTwoExpiredBarCodesShowDialogTrue()
    var
        ItemReference: array[2] of Record "Item Reference";
        ReturnedItemReference: Record "Item Reference";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        ItemReferenceNo: Code[50];
    begin
        Initialize();

        // [GIVEN] Barcode for multiple item references
        ItemReferenceNo := LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), Database::"Item Reference");

        // [GIVEN] Phys. Invt. Order with the item reference
        CreatePhysInvtOrderLine(PhysInvtOrderLine);
        PhysInvtOrderLine."Item Reference No." := ItemReferenceNo;
        PhysInvtOrderLine.Modify();

        // [GIVEN] Item References for Item X and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNoAndDates(ItemReference[1], ItemReferenceNo, LibraryInventory.CreateItemNo(),
          ItemReference[1]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID(),
           CalcDate('<-1M>', PhysInvtOrderLine.GetDateForCalculations()), CalcDate('<-1D>', PhysInvtOrderLine.GetDateForCalculations()));

        // [GIVEN] Item References for Item Y and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNoAndDates(ItemReference[2], ItemReferenceNo, LibraryInventory.CreateItemNo(),
          ItemReference[2]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID(),
           CalcDate('<+1D>', PhysInvtOrderLine.GetDateForCalculations()), CalcDate('<+1M>', PhysInvtOrderLine.GetDateForCalculations()));

        // [WHEN] Ran ReferenceLookupPhysicalInventoryOrderItem from codeunit Dist. Integration for the Phys. Invt. Order Line with ShowDialog = TRUE
        asserterror ItemReferenceMgt.ReferenceLookupPhysicalInventoryOrderItem(PhysInvtOrderLine, ReturnedItemReference, true);

        // [THEN] Error "There are no items with reference %1."
        Assert.ExpectedError(StrSubstNo(ItemRefNotExistsErr, ItemReferenceNo));
    end;


    [Test]
    procedure IRLookupPhysInvRecordWhenBarCodeAndExpiredBarCodeShowDialogTrue()
    var
        ItemReference: array[2] of Record "Item Reference";
        ReturnedItemReference: Record "Item Reference";
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
        ItemReferenceNo: Code[50];
    begin
        Initialize();

        // [GIVEN] Barcode for multiple item references
        ItemReferenceNo := LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), Database::"Item Reference");

        // [GIVEN] Phys. Invt. Record with the item reference
        CreatePhysInvtRecordLine(PhysInvtRecordLine);
        PhysInvtRecordLine."Item Reference No." := ItemReferenceNo;
        PhysInvtRecordLine.Modify();

        // [GIVEN] Item References for Item X and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNoAndDates(ItemReference[1], ItemReferenceNo, LibraryInventory.CreateItemNo(),
          ItemReference[1]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID(),
           CalcDate('<-1M>', PhysInvtRecordLine.GetDateForCalculations()), CalcDate('<-1D>', PhysInvtRecordLine.GetDateForCalculations()));

        // [GIVEN] Item References for Item Y and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[2], ItemReferenceNo, LibraryInventory.CreateItemNo(),
          ItemReference[2]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID());

        // [WHEN] Ran ReferenceLookupPhysicalInventoryRecordItem from codeunit Dist. Integration for the Phys. Invt. Record Line with ShowDialog = TRUE
        ItemReferenceMgt.ReferenceLookupPhysicalInventoryRecordItem(PhysInvtRecordLine, ReturnedItemReference, true);

        // [THEN] Item Reference with Item No = X is ignored
        // [THEN] ReferenceLookupPhysicalInventoryRecordItem returns Item Reference with Item No = Y
        ReturnedItemReference.TestField("Item No.", ItemReference[2]."Item No.");
    end;

    [Test]
    [HandlerFunctions('ItemReferenceListModalPageHandler')]
    procedure IRLookupPhysInvRecordWhenBarCodeAndBarCodeDateLimitedShowDialogTrue()
    var
        ItemReference: array[2] of Record "Item Reference";
        ReturnedItemReference: Record "Item Reference";
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
        ItemReferenceNo: Code[50];
    begin
        Initialize();

        // [GIVEN] Barcode for multiple item references
        ItemReferenceNo := LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), Database::"Item Reference");
        LibraryVariableStorage.Enqueue(ItemReferenceNo);

        // [GIVEN] Phys. Invt. Record with the item reference
        CreatePhysInvtRecordLine(PhysInvtRecordLine);
        PhysInvtRecordLine."Item Reference No." := ItemReferenceNo;
        PhysInvtRecordLine.Modify();

        // [GIVEN] Item References for Item X and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNoAndDates(ItemReference[1], ItemReferenceNo, LibraryInventory.CreateItemNo(),
          ItemReference[1]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID(),
           CalcDate('<-1M>', PhysInvtRecordLine.GetDateForCalculations()), CalcDate('<+1M>', PhysInvtRecordLine.GetDateForCalculations()));
        EnqueueItemReferenceFields(ItemReference[1]);

        // [GIVEN] Item References for Item Y and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[2], ItemReferenceNo, LibraryInventory.CreateItemNo(),
          ItemReference[2]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID());
        EnqueueItemReferenceFields(ItemReference[2]);

        // [WHEN] Ran ReferenceLookupPhysicalInventoryRecordItem from codeunit Dist. Integration for the Phys. Invt. Record Line with ShowDialog = TRUE
        ItemReferenceMgt.ReferenceLookupPhysicalInventoryRecordItem(PhysInvtRecordLine, ReturnedItemReference, true);

        // [GIVEN] Page Item Reference List opened showing both Item References
        // [GIVEN] User selected the second one
        // Done in ItemReferenceListModalPageHandler

        // [THEN] ReferenceLookupPhysicalInventoryRecordItem returns Item Reference with Item No = Y
        ReturnedItemReference.TestField("Item No.", ItemReference[2]."Item No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure IRLookupPhysInvRecordWhenTwoExpiredBarCodesShowDialogTrue()
    var
        ItemReference: array[2] of Record "Item Reference";
        ReturnedItemReference: Record "Item Reference";
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
        ItemReferenceNo: Code[50];
    begin
        Initialize();

        // [GIVEN] Barcode for multiple item references
        ItemReferenceNo := LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), Database::"Item Reference");

        // [GIVEN] Phys. Invt. Record with the item reference
        CreatePhysInvtRecordLine(PhysInvtRecordLine);
        PhysInvtRecordLine."Item Reference No." := ItemReferenceNo;
        PhysInvtRecordLine.Modify();

        // [GIVEN] Item References for Item X and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNoAndDates(ItemReference[1], ItemReferenceNo, LibraryInventory.CreateItemNo(),
          ItemReference[1]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID(),
           CalcDate('<-1M>', PhysInvtRecordLine.GetDateForCalculations()), CalcDate('<-1D>', PhysInvtRecordLine.GetDateForCalculations()));

        // [GIVEN] Item References for Item Y and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNoAndDates(ItemReference[2], ItemReferenceNo, LibraryInventory.CreateItemNo(),
          ItemReference[2]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID(),
           CalcDate('<+1D>', PhysInvtRecordLine.GetDateForCalculations()), CalcDate('<+1M>', PhysInvtRecordLine.GetDateForCalculations()));

        // [WHEN] Ran ReferenceLookupPhysicalInventoryRecordItem from codeunit Dist. Integration for the Phys. Invt. Record Line with ShowDialog = TRUE
        asserterror ItemReferenceMgt.ReferenceLookupPhysicalInventoryRecordItem(PhysInvtRecordLine, ReturnedItemReference, true);

        // [THEN] Error "There are no items with reference %1."
        Assert.ExpectedError(StrSubstNo(ItemRefNotExistsErr, ItemReferenceNo));
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ERM Item Reference Other");

        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ERM Item Reference Other");

        LibraryItemReference.EnableFeature(true);
        Commit();
        IsInitialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ERM Item Reference Other");
    end;

    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line")
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJnlLineWithNoItem(ItemJournalLine, ItemJournalBatch, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, Enum::"Item Ledger Entry Type"::"Positive Adjmt.");
    end;

    local procedure CreatePhysInvtOrderLine(var PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
    begin
        PhysInvtOrderHeader."No." := LibraryRandom.RandText(MaxStrLen(PhysInvtOrderHeader."No."));
        PhysInvtOrderHeader."Posting Date" := WorkDate();
        PhysInvtOrderHeader.Insert();

        PhysInvtOrderLine."Document No." := PhysInvtOrderHeader."No.";
        PhysInvtOrderLine."Line No." := 1;
        PhysInvtOrderLine.Insert();
    end;

    local procedure CreatePhysInvtRecordLine(var PhysInvtRecordLine: Record "Phys. Invt. Record Line")
    var
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
    begin
        CreatePhysInvtOrderLine(PhysInvtOrderLine);

        PhysInvtRecordHeader."Order No." := PhysInvtOrderLine."Document No.";
        PhysInvtRecordHeader."Recording No." := 1;
        PhysInvtRecordHeader.Insert();

        PhysInvtRecordLine."Order No." := PhysInvtOrderLine."Document No.";
        PhysInvtRecordLine.Insert();
    end;

    local procedure EnqueueItemReferenceFields(ItemReference: Record "Item Reference")
    begin
        LibraryVariableStorage.Enqueue(ItemReference."Reference Type");
        LibraryVariableStorage.Enqueue(ItemReference."Reference Type No.");
        LibraryVariableStorage.Enqueue(ItemReference."Item No.");
    end;

    [ModalPageHandler]
    procedure ItemReferenceListModalPageHandler(var ItemReferenceList: TestPage "Item Reference List")
    begin
        ItemReferenceList.FILTER.SetFilter("Reference No.", LibraryVariableStorage.DequeueText());
        repeat
            ItemReferenceList."Reference Type".AssertEquals(LibraryVariableStorage.DequeueInteger());
            ItemReferenceList."Reference Type No.".AssertEquals(LibraryVariableStorage.DequeueText());
            ItemReferenceList."Item No.".AssertEquals(LibraryVariableStorage.DequeueText());
        until ItemReferenceList.Next() = false;
        ItemReferenceList.OK().Invoke();
    end;
}

