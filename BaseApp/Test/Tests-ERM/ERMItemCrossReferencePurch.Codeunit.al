codeunit 134461 "ERM Item Cross Reference Purch"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Item Cross Reference] [Cross-Reference No] [Purchase]
    end;

    var
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        DistIntegration: Codeunit "Dist. Integration";
        CrossRefNotExistsErr: Label 'There are no items with cross reference %1.';
        DialogCodeErr: Label 'Dialog';
        isInitialized: Boolean;

    [Test]
    [HandlerFunctions('CrossReferenceListModalPageHandler')]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenSameVendorsForSameItemsAndBarCodeShowDialogTrue()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        PurchaseLine: Record "Purchase Line";
        VendorNo: array[2] of Code[20];
        CrossRefNo: Code[20];
        Index: Integer;
        ItemIndex: Integer;
        ItemNo: array[2] of Code[20];
    begin
        // [FEATURE] [UI] [Bar Code]
        // [SCENARIO 289240] Vendors: A,B, Items: X,Y,Z, Vendor Cross References: AX, AY, BX, BY and Bar Code Cross Reference PZ
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is Yes
        // [SCENARIO 289240] Page Cross Reference List shows only Cross References for Vendor A and Bar Code (AX, AY and PZ)
        Initialize();
        for ItemIndex := 1 to ArrayLen(ItemNo) do begin
            ItemNo[ItemIndex] := LibraryInventory.CreateItemNo;
            VendorNo[ItemIndex] := LibraryPurchase.CreateVendorNo;
        end;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");
        LibraryVariableStorage.Enqueue(CrossRefNo);

        // [GIVEN] Two Item Cross References for Item 1000 with No = 1234, Type = Vendor and Type No = 10000 and 20000
        // [GIVEN] Two similar Item Cross References for Item 1001
        for ItemIndex := 1 to ArrayLen(ItemNo) do begin
            for Index := 1 to ArrayLen(ItemCrossReference) do
                LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[Index], CrossRefNo, ItemNo[ItemIndex],
                  ItemCrossReference[Index]."Cross-Reference Type"::Vendor, VendorNo[Index]);
            EnqueueItemCrossReferenceFields(ItemCrossReference[1]);
        end;

        // [GIVEN] Item Cross Reference for Item 1100 with No = 1234, Type = Bar Code
        LibraryInventory.CreateItemCrossReferenceWithNo(
          ItemCrossReference[2], CrossRefNo, LibraryInventory.CreateItemNo, ItemCrossReference[2]."Cross-Reference Type"::"Bar Code",
          LibraryUtility.GenerateGUID);
        EnqueueItemCrossReferenceFields(ItemCrossReference[2]);

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Cross-Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, VendorNo[1], CrossRefNo);

        // [GIVEN] Ran ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = TRUE
        DistIntegration.ICRLookupPurchaseItem(PurchaseLine, ItemCrossReference[1], true);

        // [GIVEN] Page Cross Reference List opened showing three Cross References:
        // [GIVEN] Two with Type Vendor and Type No = 10000 and last one with Type Bar Code, Stan selected the last one
        // Done in CrossReferenceListModalPageHandler

        // [WHEN] Push OK on page Cross Reference List
        // Done in CrossReferenceListModalPageHandler

        // [THEN] ICRLookupPurchaseItem returns Item Cross Reference with Item No = 1100
        ItemCrossReference[1].TestField("Item No.", ItemCrossReference[2]."Item No.");
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('CrossReferenceListModalPageHandler')]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenSameVendorsForSameItemsShowDialogTrue()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        PurchaseLine: Record "Purchase Line";
        VendorNo: array[2] of Code[20];
        CrossRefNo: Code[20];
        Index: Integer;
        ItemIndex: Integer;
        ItemNo: array[2] of Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 289240] Vendors: A,B, Items: X,Y, Cross References: AX, AY, BX, BY
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is Yes
        // [SCENARIO 289240] Page Cross Reference List shows only Cross References for Vendor A (AX and AY)
        Initialize();
        for ItemIndex := 1 to ArrayLen(ItemNo) do begin
            ItemNo[ItemIndex] := LibraryInventory.CreateItemNo;
            VendorNo[ItemIndex] := LibraryPurchase.CreateVendorNo;
        end;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");
        LibraryVariableStorage.Enqueue(CrossRefNo);

        // [GIVEN] Two Item Cross References for Item 1000 with No = 1234, Type = Vendor and Type No = 10000 and 20000
        // [GIVEN] Two similar Item Cross References for Item 1001
        for ItemIndex := 1 to ArrayLen(ItemNo) do begin
            for Index := 1 to ArrayLen(ItemCrossReference) do
                LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[Index], CrossRefNo, ItemNo[ItemIndex],
                  ItemCrossReference[Index]."Cross-Reference Type"::Vendor, VendorNo[Index]);
            EnqueueItemCrossReferenceFields(ItemCrossReference[1]);
        end;

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Cross-Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, VendorNo[1], CrossRefNo);

        // [GIVEN] Ran ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = TRUE
        DistIntegration.ICRLookupPurchaseItem(PurchaseLine, ItemCrossReference[1], true);

        // [GIVEN] Page Cross Reference List opened showing two Cross References with Type No = 10000, first for Item 1000, second for Item 1001
        // [GIVEN] Stan selected the second one
        // Done in CrossReferenceListModalPageHandler

        // [WHEN] Push OK on page Cross Reference List
        // Done in CrossReferenceListModalPageHandler

        // [THEN] ICRLookupPurchaseItem returns Item Cross Reference with Item No = 1001
        ItemCrossReference[1].TestField("Item No.", ItemCrossReference[2]."Item No.");
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('CrossReferenceListModalPageHandler')]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenVendorAndBarCodeDifferentItemsShowDialogTrue()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
        CrossRefNo: Code[20];
    begin
        // [FEATURE] [UI] [Bar Code]
        // [SCENARIO 289240] Vendor A, Items: X,Y Vendor Cross Reference AX and Bar Code Cross Reference PY
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is Yes
        // [SCENARIO 289240] Page Cross Reference List shows both Cross References (AX and PY)
        Initialize();
        VendorNo := LibraryPurchase.CreateVendorNo;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");
        LibraryVariableStorage.Enqueue(CrossRefNo);

        // [GIVEN] Item Cross References for Item 1000 with No = 1234, Type = Vendor and Type No = 10000
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[1], CrossRefNo, LibraryInventory.CreateItemNo,
          ItemCrossReference[1]."Cross-Reference Type"::Vendor, VendorNo);
        EnqueueItemCrossReferenceFields(ItemCrossReference[1]);

        // [GIVEN] Item Cross References for Item 1001 with same No and Type = Bar Code
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[2], CrossRefNo, LibraryInventory.CreateItemNo,
          ItemCrossReference[2]."Cross-Reference Type"::"Bar Code", LibraryUtility.GenerateGUID);
        EnqueueItemCrossReferenceFields(ItemCrossReference[2]);

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Cross-Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, VendorNo, CrossRefNo);

        // [GIVEN] Ran ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = TRUE
        DistIntegration.ICRLookupPurchaseItem(PurchaseLine, ItemCrossReference[1], true);

        // [GIVEN] Page Cross Reference List opened showing both Cross References, first for Item 1000, second for Item 1001
        // [GIVEN] Stan selected the second one
        // Done in CrossReferenceListModalPageHandler

        // [WHEN] Push OK on page Cross Reference List
        // Done in CrossReferenceListModalPageHandler

        // [THEN] ICRLookupPurchaseItem returns Item Cross Reference with Item No = 1001
        ItemCrossReference[1].TestField("Item No.", ItemCrossReference[2]."Item No.");
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('CrossReferenceListModalPageHandler')]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenVendorAndBlankTypeDifferentItemsShowDialogTrue()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
        CrossRefNo: Code[20];
    begin
        // [FEATURE] [UI] [Bar Code]
        // [SCENARIO 289240] Vendor A, Items: X,Y Vendor Cross Reference AX and <blank> Type Cross Reference TY
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is Yes
        // [SCENARIO 289240] Page Cross Reference List shows both Cross References (AX and TY)
        Initialize();
        VendorNo := LibraryPurchase.CreateVendorNo;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");
        LibraryVariableStorage.Enqueue(CrossRefNo);

        // [GIVEN] Item Cross References for Item 1000 with No = 1234, Type = Vendor and Type No = 10000
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[1], CrossRefNo, LibraryInventory.CreateItemNo,
          ItemCrossReference[1]."Cross-Reference Type"::Vendor, VendorNo);

        // [GIVEN] Item Cross References for Item 1001 with No = 1234 and Type = <blank>
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[2], CrossRefNo, LibraryInventory.CreateItemNo,
          ItemCrossReference[2]."Cross-Reference Type"::" ", '');
        EnqueueItemCrossReferenceFields(ItemCrossReference[2]); // <blank> type record is to be displayed first
        EnqueueItemCrossReferenceFields(ItemCrossReference[1]);

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Cross-Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, VendorNo, CrossRefNo);

        // [GIVEN] Ran ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = TRUE
        DistIntegration.ICRLookupPurchaseItem(PurchaseLine, ItemCrossReference[2], true);

        // [GIVEN] Page Cross Reference List opened showing both Cross References, first with <blank> Type, second with Type Vendor
        // [GIVEN] Stan selected the second one
        // Done in CrossReferenceListModalPageHandler

        // [WHEN] Push OK on page Cross Reference List
        // Done in CrossReferenceListModalPageHandler

        // [THEN] ICRLookupPurchaseItem returns Item Cross Reference with Item No = 1000
        ItemCrossReference[2].TestField("Item No.", ItemCrossReference[1]."Item No.");
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('CrossReferenceListModalPageHandler')]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenSameVendorDifferentItemsShowDialogTrue()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
        CrossRefNo: Code[20];
        Index: Integer;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 289240] Vendor A, Items: X,Y Cross References AX and AY
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is Yes
        // [SCENARIO 289240] Page Cross Reference List shows both Cross References (AX and AY)
        Initialize();
        VendorNo := LibraryPurchase.CreateVendorNo;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");
        LibraryVariableStorage.Enqueue(CrossRefNo);

        // [GIVEN] Item Cross References for Items 1000 and 1001 with same No = 1234, Type = Vendor and Type No = 10000
        for Index := 1 to ArrayLen(ItemCrossReference) do begin
            LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[Index], CrossRefNo, LibraryInventory.CreateItemNo,
              ItemCrossReference[Index]."Cross-Reference Type"::Vendor, VendorNo);
            EnqueueItemCrossReferenceFields(ItemCrossReference[Index]);
        end;

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Cross-Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, VendorNo, CrossRefNo);

        // [GIVEN] Ran ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = TRUE
        DistIntegration.ICRLookupPurchaseItem(PurchaseLine, ItemCrossReference[1], true);

        // [GIVEN] Page Cross Reference List opened showing both Cross References: first for Item 1000, second for Item 1001
        // [GIVEN] Stan selected the second one
        // Done in CrossReferenceListModalPageHandler

        // [WHEN] Push OK on page Cross Reference List
        // Done in CrossReferenceListModalPageHandler

        // [THEN] ICRLookupPurchaseItem returns Item Cross Reference with Item No = 1001
        ItemCrossReference[1].TestField("Item No.", ItemCrossReference[2]."Item No.");
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('CrossReferenceListModalPageHandler')]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenBarCodesDifferentItemsShowDialogTrue()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        PurchaseLine: Record "Purchase Line";
        CrossRefNo: Code[20];
        Index: Integer;
    begin
        // [FEATURE] [UI] [Bar Code]
        // [SCENARIO 289240] Items: X,Y, Bar Code Cross References: PX,PY
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor and ShowDialog is Yes
        // [SCENARIO 289240] Page Cross Reference List shows both Cross References (PX and PY)
        Initialize();
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");
        LibraryVariableStorage.Enqueue(CrossRefNo);

        // [GIVEN] Item Cross References for Items 1000 and 1001, both with No = 1234 and Type = Bar Code
        for Index := 1 to ArrayLen(ItemCrossReference) do begin
            LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[Index], CrossRefNo, LibraryInventory.CreateItemNo,
              ItemCrossReference[Index]."Cross-Reference Type"::"Bar Code", LibraryUtility.GenerateGUID);
            EnqueueItemCrossReferenceFields(ItemCrossReference[Index]);
        end;

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Cross-Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, LibraryPurchase.CreateVendorNo, CrossRefNo);

        // [GIVEN] Ran ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = TRUE
        DistIntegration.ICRLookupPurchaseItem(PurchaseLine, ItemCrossReference[1], true);

        // [GIVEN] Page Cross Reference List opened showing both Cross References: first for Item 1000, second for Item 1001
        // [GIVEN] Stan selected the second one
        // Done in CrossReferenceListModalPageHandler

        // [WHEN] Push OK on page Cross Reference List
        // Done in CrossReferenceListModalPageHandler

        // [THEN] ICRLookupPurchaseItem returns Item Cross Reference with Item No = 1001
        ItemCrossReference[1].TestField("Item No.", ItemCrossReference[2]."Item No.");
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenVendorAndBarCodeSameItemShowDialogTrue()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
        CrossRefNo: Code[20];
    begin
        // [FEATURE] [Bar Code]
        // [SCENARIO 289240] Vendor A, Item X, Vendor Cross Reference AX, Bar Code Cross Reference PX
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is Yes
        // [SCENARIO 289240] Page Cross Reference List is not shown, ICRLookupPurchaseItem returns Cross Reference for Vendor A (AX)
        Initialize();
        VendorNo := LibraryPurchase.CreateVendorNo;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Item Cross References for Item 1000 with No = 1234, Type = Vendor and Type No = 10000
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[1], CrossRefNo, LibraryInventory.CreateItemNo,
          ItemCrossReference[1]."Cross-Reference Type"::Vendor, VendorNo);

        // [GIVEN] Item Cross References for same Item with same No and Type = Bar Code
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[2], CrossRefNo, ItemCrossReference[1]."Item No.",
          ItemCrossReference[2]."Cross-Reference Type"::"Bar Code", LibraryUtility.GenerateGUID);

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Cross-Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, VendorNo, CrossRefNo);

        // [WHEN] Ran ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = TRUE
        DistIntegration.ICRLookupPurchaseItem(PurchaseLine, ItemCrossReference[2], true);

        // [THEN] ICRLookupPurchaseItem returns Item Cross Reference with Item No = 1000
        ItemCrossReference[2].TestField("Item No.", ItemCrossReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenVendorAndBlankTypeSameItemShowDialogTrue()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
        CrossRefNo: Code[20];
    begin
        // [FEATURE] [Bar Code]
        // [SCENARIO 289240] Vendor A, Item X, Vendor Cross Reference AX, <blank> Type Cross Reference TX
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is Yes
        // [SCENARIO 289240] Page Cross Reference List is not shown, ICRLookupPurchaseItem returns Cross Reference for Vendor A (AX)
        Initialize();
        VendorNo := LibraryPurchase.CreateVendorNo;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Item Cross References for Item 1000 with No = 1234, Type = Vendor and Type No = 10000
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[1], CrossRefNo, LibraryInventory.CreateItemNo,
          ItemCrossReference[1]."Cross-Reference Type"::Vendor, VendorNo);

        // [GIVEN] Item Cross References for same Item with same No and Type = <blank>
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[2], CrossRefNo, ItemCrossReference[1]."Item No.",
          ItemCrossReference[2]."Cross-Reference Type"::" ", '');

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Cross-Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, VendorNo, CrossRefNo);

        // [WHEN] Ran ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = TRUE
        DistIntegration.ICRLookupPurchaseItem(PurchaseLine, ItemCrossReference[2], true);

        // [THEN] ICRLookupPurchaseItem returns Item Cross Reference with Item No = 1000
        ItemCrossReference[2].TestField("Item No.", ItemCrossReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenBarCodesSameItemShowDialogTrue()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        PurchaseLine: Record "Purchase Line";
        CrossRefNo: Code[20];
        ItemNo: Code[20];
        Index: Integer;
    begin
        // [FEATURE] [Bar Code]
        // [SCENARIO 289240] Item X, Bar Code Cross References: PX,TX
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor and ShowDialog is Yes
        // [SCENARIO 289240] Page Cross Reference List is not shown, ICRLookupPurchaseItem returns Cross Reference PX
        Initialize();
        ItemNo := LibraryInventory.CreateItemNo;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Item Cross References both for same Item, No = 1234 and Type = Bar Code, Type No are "P" and "T"
        for Index := 1 to ArrayLen(ItemCrossReference) do
            LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[Index], CrossRefNo, ItemNo,
              ItemCrossReference[Index]."Cross-Reference Type"::"Bar Code", LibraryUtility.GenerateGUID);

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Cross-Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, LibraryPurchase.CreateVendorNo, CrossRefNo);

        // [WHEN] Run ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = TRUE
        DistIntegration.ICRLookupPurchaseItem(PurchaseLine, ItemCrossReference[2], true);

        // [THEN] ICRLookupPurchaseItem returns Item Cross Reference with Type No = "P"
        ItemCrossReference[2].TestField("Cross-Reference Type No.", ItemCrossReference[1]."Cross-Reference Type No.");
        ItemCrossReference[2].TestField("Item No.", ItemCrossReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenDifferentVendorsSameItemShowDialogTrue()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        PurchaseLine: Record "Purchase Line";
        CrossRefNo: Code[20];
        ItemNo: Code[20];
        Index: Integer;
    begin
        // [SCENARIO 289240] Vendors: A,B, Item X, Cross References AX and BX
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is Yes
        // [SCENARIO 289240] Page Cross Reference List is not shown, ICRLookupPurchaseItem returns Cross Reference for Vendor A (AX)
        Initialize();
        ItemNo := LibraryInventory.CreateItemNo;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Two Item Cross References for Item 1000 with same No = 1234, Type = Vendor, first has Type No = 10000, second has Type No = 20000
        for Index := 1 to ArrayLen(ItemCrossReference) do
            LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[Index], CrossRefNo, ItemNo,
              ItemCrossReference[Index]."Cross-Reference Type"::Vendor, LibraryPurchase.CreateVendorNo);

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Cross-Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(
          PurchaseLine, CopyStr(ItemCrossReference[1]."Cross-Reference Type No.", 1, MaxStrLen(PurchaseLine."Buy-from Vendor No.")),
          CrossRefNo);

        // [WHEN] Run ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = TRUE
        DistIntegration.ICRLookupPurchaseItem(PurchaseLine, ItemCrossReference[2], true);

        // [THEN] ICRLookupPurchaseItem returns Item Cross Reference with Item No = 1000
        ItemCrossReference[2].TestField("Item No.", ItemCrossReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenDifferentVendorsDifferentItemsShowDialogTrue()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        PurchaseLine: Record "Purchase Line";
        CrossRefNo: Code[20];
        Index: Integer;
    begin
        // [SCENARIO 289240] Vendors: A,B, Items X,Y, Cross References AX and BY
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is Yes
        // [SCENARIO 289240] Page Cross Reference List is not shown, ICRLookupPurchaseItem returns Cross Reference for Vendor A (AX)
        Initialize();
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Item Cross Reference for Item 1000 with No = 1234, Type = Vendor, Type No = 10000
        // [GIVEN] Item Cross Reference for Item 1001 with No = 1234, Type = Vendor, Type No = 20000
        for Index := 1 to ArrayLen(ItemCrossReference) do
            LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[Index], CrossRefNo, LibraryInventory.CreateItemNo,
              ItemCrossReference[Index]."Cross-Reference Type"::Vendor, LibraryPurchase.CreateVendorNo);

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Cross-Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(
          PurchaseLine, CopyStr(ItemCrossReference[1]."Cross-Reference Type No.", 1, MaxStrLen(PurchaseLine."Buy-from Vendor No.")),
          CrossRefNo);

        // [WHEN] Run ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = TRUE
        DistIntegration.ICRLookupPurchaseItem(PurchaseLine, ItemCrossReference[2], true);

        // [THEN] ICRLookupPurchaseItem returns Item Cross Reference with Item No = 1000
        ItemCrossReference[2].TestField("Item No.", ItemCrossReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenOtherVendorAndBarCodeShowDialogTrue()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        PurchaseLine: Record "Purchase Line";
        CrossRefNo: Code[20];
    begin
        // [FEATURE] [Bar Code]
        // [SCENARIO 289240] Vendor B, Items X,Y Vendor Cross Reference BX, Bar Code Cross Reference PY
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is Yes
        // [SCENARIO 289240] Page Cross Reference List is not shown, ICRLookupPurchaseItem returns Cross Reference PY
        Initialize();
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Item Cross Reference for Item 1000 with No = 1234, Type = Vendor and Type No = 20000
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[1], CrossRefNo, LibraryInventory.CreateItemNo,
          ItemCrossReference[1]."Cross-Reference Type"::Vendor, LibraryPurchase.CreateVendorNo);

        // [GIVEN] Item Cross References for Item 1001 with same No and Type = Bar Code
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[2], CrossRefNo, ItemCrossReference[1]."Item No.",
          ItemCrossReference[2]."Cross-Reference Type"::"Bar Code", LibraryUtility.GenerateGUID);

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Cross-Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, LibraryPurchase.CreateVendorNo, CrossRefNo);

        // [WHEN] Ran ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = TRUE
        DistIntegration.ICRLookupPurchaseItem(PurchaseLine, ItemCrossReference[1], true);

        // [THEN] ICRLookupPurchaseItem returns Item Cross Reference with Item No = 1001
        ItemCrossReference[1].TestField("Item No.", ItemCrossReference[2]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenOtherVendorShowDialogTrue()
    var
        ItemCrossReference: Record "Item Cross Reference";
        PurchaseLine: Record "Purchase Line";
        CrossRefNo: Code[20];
    begin
        // [SCENARIO 289240] Vendor B, Cross Reference BX
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is Yes
        // [SCENARIO 289240] ICRLookupPurchaseItem throws error
        Initialize();
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference.FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Item Cross Reference for Item with No = 1234, Type = Vendor and Type No = 20000
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference, CrossRefNo, LibraryInventory.CreateItemNo,
          ItemCrossReference."Cross-Reference Type"::Vendor, LibraryPurchase.CreateVendorNo);

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Cross-Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, LibraryPurchase.CreateVendorNo, CrossRefNo);

        // [WHEN] Run ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = TRUE
        asserterror DistIntegration.ICRLookupPurchaseItem(PurchaseLine, ItemCrossReference, true);

        // [THEN] Error "There are no items with cross reference: 1234"
        Assert.ExpectedError(StrSubstNo(CrossRefNotExistsErr, CrossRefNo));
        Assert.ExpectedErrorCode(DialogCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenOtherMultipleVendorsShowDialogTrue()
    var
        ItemCrossReference: Record "Item Cross Reference";
        PurchaseLine: Record "Purchase Line";
        CrossRefNo: Code[20];
    begin
        // [SCENARIO 289240] Vendors: B,C Cross References BX,CY
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is Yes
        // [SCENARIO 289240] ICRLookupPurchaseItem throws error
        Initialize();
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference.FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Two Item Cross References with same No = 1234, same Type = Vendor and Type No 20000 and 30000
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference, CrossRefNo, LibraryInventory.CreateItemNo,
          ItemCrossReference."Cross-Reference Type"::Vendor, LibraryPurchase.CreateVendorNo);
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference, CrossRefNo, LibraryInventory.CreateItemNo,
          ItemCrossReference."Cross-Reference Type"::Vendor, LibraryPurchase.CreateVendorNo);

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Cross-Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, LibraryPurchase.CreateVendorNo, CrossRefNo);

        // [WHEN] Run ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = TRUE
        asserterror DistIntegration.ICRLookupPurchaseItem(PurchaseLine, ItemCrossReference, true);

        // [THEN] Error "There are no items with cross reference: 1234"
        Assert.ExpectedError(StrSubstNo(CrossRefNotExistsErr, CrossRefNo));
        Assert.ExpectedErrorCode(DialogCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenOneVendorShowDialogTrue()
    var
        ItemCrossReference: Record "Item Cross Reference";
        PurchaseLine: Record "Purchase Line";
        CrossRefNo: Code[20];
        ItemNo: Code[20];
    begin
        // [SCENARIO 289240] Vendor A, Cross Reference AX
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is Yes
        // [SCENARIO 289240] ICRLookupPurchaseItem Returns Cross Reference AX
        Initialize();
        ItemNo := LibraryInventory.CreateItemNo;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference.FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Item Cross Reference for Item 1000 with No = 1234, Type = Vendor and Type No = 10000
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference, CrossRefNo, ItemNo,
          ItemCrossReference."Cross-Reference Type"::Vendor, LibraryPurchase.CreateVendorNo);

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Cross-Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(
          PurchaseLine, CopyStr(ItemCrossReference."Cross-Reference Type No.", 1, MaxStrLen(PurchaseLine."Buy-from Vendor No.")),
          CrossRefNo);

        // [WHEN] Run ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = TRUE
        DistIntegration.ICRLookupPurchaseItem(PurchaseLine, ItemCrossReference, true);

        // [THEN] ICRLookupPurchaseItem returns Item Cross Reference with Item No = 1000
        ItemCrossReference.TestField("Item No.", ItemNo)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenNoCrossRefShowDialogTrue()
    var
        DummyItemCrossReference: Record "Item Cross Reference";
        PurchaseLine: Record "Purchase Line";
        CrossRefNo: Code[20];
    begin
        // [SCENARIO 289240] No Cross References with No = 1234
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A with Cross Reference No = 1234 and ShowDialog is Yes
        // [SCENARIO 289240] ICRLookupPurchaseItem Returns Cross Reference AX
        Initialize();
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(DummyItemCrossReference.FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Cross-Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, LibraryPurchase.CreateVendorNo, CrossRefNo);

        // [WHEN] Run ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = TRUE
        asserterror DistIntegration.ICRLookupPurchaseItem(PurchaseLine, DummyItemCrossReference, true);

        // [THEN] Error "There are no items with cross reference: 1234"
        Assert.ExpectedError(StrSubstNo(CrossRefNotExistsErr, CrossRefNo));
        Assert.ExpectedErrorCode(DialogCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenSameVendorsForSameItemsAndBarCodeShowDialogFalse()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        PurchaseLine: Record "Purchase Line";
        VendorNo: array[2] of Code[20];
        CrossRefNo: Code[20];
        Index: Integer;
        ItemIndex: Integer;
        ItemNo: array[2] of Code[20];
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO 289240] Vendors: A,B, Items: X,Y,Z, Vendor Cross References: AX, AY, BX, BY and Bar Code Cross Reference PZ
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is No
        // [SCENARIO 289240] ICRLookupPurchaseItem returns Cross Reference for Vendor A and Item X (AX)
        Initialize();
        for ItemIndex := 1 to ArrayLen(ItemNo) do begin
            ItemNo[ItemIndex] := LibraryInventory.CreateItemNo;
            VendorNo[ItemIndex] := LibraryPurchase.CreateVendorNo;
        end;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Two Item Cross References for Item 1000 with No = 1234, Type = Vendor and Type No = 10000 and 20000
        // [GIVEN] Two similar Item Cross References for Item 1001
        for ItemIndex := 1 to ArrayLen(ItemNo) do
            for Index := 1 to ArrayLen(ItemCrossReference) do
                LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[Index], CrossRefNo, ItemNo[ItemIndex],
                  ItemCrossReference[Index]."Cross-Reference Type"::Vendor, VendorNo[Index]);

        // [GIVEN] Item Cross Reference for Item 1100 with No = 1234, Type = Bar Code
        LibraryInventory.CreateItemCrossReferenceWithNo(
          ItemCrossReference[2], CrossRefNo, LibraryInventory.CreateItemNo, ItemCrossReference[2]."Cross-Reference Type"::"Bar Code",
          LibraryUtility.GenerateGUID);

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Cross-Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, VendorNo[1], CrossRefNo);

        // [WHEN] Run ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = FALSE
        DistIntegration.ICRLookupPurchaseItem(PurchaseLine, ItemCrossReference[2], false);

        // [THEN] ICRLookupPurchaseItem returns Item Cross Reference with Item No = 1000 and Type No = 10000
        ItemCrossReference[2].TestField("Item No.", ItemNo[1]);
        ItemCrossReference[2].TestField("Cross-Reference Type No.", VendorNo[1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenSameVendorsForSameItemsShowDialogFalse()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        PurchaseLine: Record "Purchase Line";
        VendorNo: array[2] of Code[20];
        CrossRefNo: Code[20];
        Index: Integer;
        ItemIndex: Integer;
        ItemNo: array[2] of Code[20];
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO 289240] Vendors: A,B, Items: X,Y, Cross References: AX, AY, BX, BY
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is No
        // [SCENARIO 289240] ICRLookupPurchaseItem returns Cross Reference for Vendor A and Item X (AX)
        Initialize();
        for ItemIndex := 1 to ArrayLen(ItemNo) do begin
            ItemNo[ItemIndex] := LibraryInventory.CreateItemNo;
            VendorNo[ItemIndex] := LibraryPurchase.CreateVendorNo;
        end;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Two Item Cross References for Item 1000 with No = 1234, Type = Vendor and Type No = 10000 and 20000
        // [GIVEN] Two similar Item Cross References for Item 1001
        for ItemIndex := 1 to ArrayLen(ItemNo) do
            for Index := 1 to ArrayLen(ItemCrossReference) do
                LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[Index], CrossRefNo, ItemNo[ItemIndex],
                  ItemCrossReference[Index]."Cross-Reference Type"::Vendor, VendorNo[Index]);

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Cross-Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, VendorNo[1], CrossRefNo);

        // [When] Run ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = FALSE
        DistIntegration.ICRLookupPurchaseItem(PurchaseLine, ItemCrossReference[2], false);

        // [THEN] ICRLookupPurchaseItem returns Item Cross Reference with Item No = 1000 and Type No = 10000
        ItemCrossReference[2].TestField("Item No.", ItemNo[1]);
        ItemCrossReference[2].TestField("Cross-Reference Type No.", VendorNo[1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenVendorAndBarCodeDifferentItemsShowDialogFalse()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
        CrossRefNo: Code[20];
    begin
        // [FEATURE] [Intercompany] [Bar Code]
        // [SCENARIO 289240] Vendor A, Items: X,Y Vendor Cross Reference AX and Bar Code Cross Reference PY
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is No
        // [SCENARIO 289240] ICRLookupPurchaseItem returns Cross Reference for Vendor A and Item X (AX)
        Initialize();
        VendorNo := LibraryPurchase.CreateVendorNo;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Item Cross References for Item 1000 with No = 1234, Type = Vendor and Type No = 10000
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[1], CrossRefNo, LibraryInventory.CreateItemNo,
          ItemCrossReference[1]."Cross-Reference Type"::Vendor, VendorNo);

        // [GIVEN] Item Cross References for Item 1001 with same No and Type = Bar Code
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[2], CrossRefNo, LibraryInventory.CreateItemNo,
          ItemCrossReference[2]."Cross-Reference Type"::"Bar Code", LibraryUtility.GenerateGUID);

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Cross-Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, VendorNo, CrossRefNo);

        // [WHEN] Ran ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = FALSE
        DistIntegration.ICRLookupPurchaseItem(PurchaseLine, ItemCrossReference[2], false);

        // [THEN] ICRLookupPurchaseItem returns Item Cross Reference with Item No = 1000
        ItemCrossReference[2].TestField("Item No.", ItemCrossReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenVendorAndBlankTypeDifferentItemsShowDialogFalse()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
        CrossRefNo: Code[20];
    begin
        // [FEATURE] [Intercompany] [Bar Code]
        // [SCENARIO 289240] Vendor A, Items: X,Y Vendor Cross Reference AX and <blank> Type Cross Reference TY
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is No
        // [SCENARIO 289240] ICRLookupPurchaseItem returns Cross Reference for Vendor A and Item X (AX)
        Initialize();
        VendorNo := LibraryPurchase.CreateVendorNo;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Item Cross References for Item 1000 with No = 1234, Type = Vendor and Type No = 10000
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[1], CrossRefNo, LibraryInventory.CreateItemNo,
          ItemCrossReference[1]."Cross-Reference Type"::Vendor, VendorNo);

        // [GIVEN] Item Cross References for Item 1001 with No = 1234 and Type = <blank>
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[2], CrossRefNo, LibraryInventory.CreateItemNo,
          ItemCrossReference[2]."Cross-Reference Type"::" ", '');

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Cross-Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, VendorNo, CrossRefNo);

        // [WHEN] Run ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = FALSE
        DistIntegration.ICRLookupPurchaseItem(PurchaseLine, ItemCrossReference[2], false);

        // [THEN] ICRLookupPurchaseItem returns Item Cross Reference with Item No = 1000
        ItemCrossReference[2].TestField("Item No.", ItemCrossReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenSameVendorDifferentItemsShowDialogFalse()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
        CrossRefNo: Code[20];
        Index: Integer;
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO 289240] Vendor A, Items: X,Y Cross References AX and AY
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is No
        // [SCENARIO 289240] ICRLookupPurchaseItem returns Cross Reference for Vendor A and Item X (AX)
        Initialize();
        VendorNo := LibraryPurchase.CreateVendorNo;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Item Cross References for Items 1000 and 1001 with same No = 1234, Type = Vendor and Type No = 10000
        for Index := 1 to ArrayLen(ItemCrossReference) do
            LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[Index], CrossRefNo, LibraryInventory.CreateItemNo,
              ItemCrossReference[Index]."Cross-Reference Type"::Vendor, VendorNo);

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Cross-Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, VendorNo, CrossRefNo);

        // [WHEN] Run ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = FALSE
        DistIntegration.ICRLookupPurchaseItem(PurchaseLine, ItemCrossReference[2], false);

        // [THEN] ICRLookupPurchaseItem returns Item Cross Reference with Item No = 1000
        ItemCrossReference[2].TestField("Item No.", ItemCrossReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenBarCodesDifferentItemsShowDialogFalse()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        PurchaseLine: Record "Purchase Line";
        CrossRefNo: Code[20];
        Index: Integer;
    begin
        // [FEATURE] [Intercompany] [Bar Code]
        // [SCENARIO 289240] Items: X,Y, Bar Code Cross References: PX,PY
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor and ShowDialog is No
        // [SCENARIO 289240] ICRLookupPurchaseItem returns Cross Reference PX
        Initialize();
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Item Cross References for Items 1000 and 1001, both with No = 1234 and Type = Bar Code
        for Index := 1 to ArrayLen(ItemCrossReference) do
            LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[Index], CrossRefNo, LibraryInventory.CreateItemNo,
              ItemCrossReference[Index]."Cross-Reference Type"::"Bar Code", LibraryUtility.GenerateGUID);

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Cross-Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, LibraryPurchase.CreateVendorNo, CrossRefNo);

        // [WHEN] Run ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = FALSE
        DistIntegration.ICRLookupPurchaseItem(PurchaseLine, ItemCrossReference[2], false);

        // [THEN] ICRLookupPurchaseItem returns Item Cross Reference with Item No = 1001
        ItemCrossReference[2].TestField("Item No.", ItemCrossReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenVendorAndBarCodeSameItemShowDialogFalse()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
        CrossRefNo: Code[20];
    begin
        // [FEATURE] [Intercompany] [Bar Code]
        // [SCENARIO 289240] Vendor A, Item X, Vendor Cross Reference AX, Bar Code Cross Reference PX
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is No
        // [SCENARIO 289240] ICRLookupPurchaseItem returns Cross Reference for Vendor A (AX)
        Initialize();
        VendorNo := LibraryPurchase.CreateVendorNo;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Item Cross References for Item 1000 with No = 1234, Type = Vendor and Type No = 10000
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[1], CrossRefNo, LibraryInventory.CreateItemNo,
          ItemCrossReference[1]."Cross-Reference Type"::Vendor, VendorNo);

        // [GIVEN] Item Cross References for same Item with same No and Type = Bar Code
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[2], CrossRefNo, ItemCrossReference[1]."Item No.",
          ItemCrossReference[2]."Cross-Reference Type"::"Bar Code", LibraryUtility.GenerateGUID);

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Cross-Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, VendorNo, CrossRefNo);

        // [WHEN] Ran ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = FALSE
        DistIntegration.ICRLookupPurchaseItem(PurchaseLine, ItemCrossReference[2], false);

        // [THEN] ICRLookupPurchaseItem returns Item Cross Reference with Item No = 1000
        ItemCrossReference[2].TestField("Item No.", ItemCrossReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenVendorAndBlankTypeSameItemShowDialogFalse()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
        CrossRefNo: Code[20];
    begin
        // [FEATURE] [Intercompany] [Bar Code]
        // [SCENARIO 289240] Vendor A, Item X, Vendor Cross Reference AX, <blank> Type Cross Reference TX
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is No
        // [SCENARIO 289240] Page Cross Reference List is not shown, ICRLookupPurchaseItem returns Cross Reference for Vendor A (AX)
        Initialize();
        VendorNo := LibraryPurchase.CreateVendorNo;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Item Cross References for Item 1000 with No = 1234, Type = Vendor and Type No = 10000
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[1], CrossRefNo, LibraryInventory.CreateItemNo,
          ItemCrossReference[1]."Cross-Reference Type"::Vendor, VendorNo);

        // [GIVEN] Item Cross References for same Item with same No and Type = <blank>
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[2], CrossRefNo, ItemCrossReference[1]."Item No.",
          ItemCrossReference[2]."Cross-Reference Type"::" ", '');

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Cross-Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, VendorNo, CrossRefNo);

        // [WHEN] Ran ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = FALSE
        DistIntegration.ICRLookupPurchaseItem(PurchaseLine, ItemCrossReference[2], false);

        // [THEN] ICRLookupPurchaseItem returns Item Cross Reference with Item No = 1000
        ItemCrossReference[2].TestField("Item No.", ItemCrossReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenBarCodesSameItemShowDialogFalse()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        PurchaseLine: Record "Purchase Line";
        CrossRefNo: Code[20];
        ItemNo: Code[20];
        Index: Integer;
    begin
        // [FEATURE] [Intercompany] [Bar Code]
        // [SCENARIO 289240] Item X, Bar Code Cross References: PX,TX
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor and ShowDialog is No
        // [SCENARIO 289240] ICRLookupPurchaseItem returns Cross Reference PX
        Initialize();
        ItemNo := LibraryInventory.CreateItemNo;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Item Cross References both for same Item, No = 1234 and Type = Bar Code, Type No are "P" and "T"
        for Index := 1 to ArrayLen(ItemCrossReference) do
            LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[Index], CrossRefNo, ItemNo,
              ItemCrossReference[Index]."Cross-Reference Type"::"Bar Code", LibraryUtility.GenerateGUID);

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Cross-Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, LibraryPurchase.CreateVendorNo, CrossRefNo);

        // [WHEN] Run ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = FALSE
        DistIntegration.ICRLookupPurchaseItem(PurchaseLine, ItemCrossReference[2], false);

        // [THEN] ICRLookupPurchaseItem returns Item Cross Reference with Type No = "P"
        ItemCrossReference[2].TestField("Cross-Reference Type No.", ItemCrossReference[1]."Cross-Reference Type No.");
        ItemCrossReference[2].TestField("Item No.", ItemCrossReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenDifferentVendorsSameItemShowDialogFalse()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        PurchaseLine: Record "Purchase Line";
        CrossRefNo: Code[20];
        ItemNo: Code[20];
        Index: Integer;
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO 289240] Vendors: A,B, Item X, Cross References AX and BX
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is No
        // [SCENARIO 289240] ICRLookupPurchaseItem returns Cross Reference for Vendor A (AX)
        Initialize();
        ItemNo := LibraryInventory.CreateItemNo;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Two Item Cross References for Item 1000 with same No = 1234, Type = Vendor, first has Type No = 10000, second has Type No = 20000
        for Index := 1 to ArrayLen(ItemCrossReference) do
            LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[Index], CrossRefNo, ItemNo,
              ItemCrossReference[Index]."Cross-Reference Type"::Vendor, LibraryPurchase.CreateVendorNo);

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Cross-Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(
          PurchaseLine, CopyStr(ItemCrossReference[1]."Cross-Reference Type No.", 1, MaxStrLen(PurchaseLine."Buy-from Vendor No.")),
          CrossRefNo);

        // [WHEN] Run ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = FALSE
        DistIntegration.ICRLookupPurchaseItem(PurchaseLine, ItemCrossReference[2], false);

        // [THEN] ICRLookupPurchaseItem returns Item Cross Reference with Item No = 1000
        ItemCrossReference[2].TestField("Item No.", ItemCrossReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenDifferentVendorsDifferentItemsShowDialogFalse()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        PurchaseLine: Record "Purchase Line";
        CrossRefNo: Code[20];
        Index: Integer;
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO 289240] Vendors: A,B, Items X,Y, Cross References AX and BY
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is No
        // [SCENARIO 289240] ICRLookupPurchaseItem returns Cross Reference for Vendor A (AX)
        Initialize();
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Item Cross Reference for Item 1000 with No = 1234, Type = Vendor, Type No = 10000
        // [GIVEN] Item Cross Reference for Item 1001 with No = 1234, Type = Vendor, Type No = 20000
        for Index := 1 to ArrayLen(ItemCrossReference) do
            LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[Index], CrossRefNo, LibraryInventory.CreateItemNo,
              ItemCrossReference[Index]."Cross-Reference Type"::Vendor, LibraryPurchase.CreateVendorNo);

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Cross-Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(
          PurchaseLine, CopyStr(ItemCrossReference[1]."Cross-Reference Type No.", 1, MaxStrLen(PurchaseLine."Buy-from Vendor No.")),
          CrossRefNo);

        // [WHEN] Run ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = FALSE
        DistIntegration.ICRLookupPurchaseItem(PurchaseLine, ItemCrossReference[2], false);

        // [THEN] ICRLookupPurchaseItem returns Item Cross Reference with Item No = 1000
        ItemCrossReference[2].TestField("Item No.", ItemCrossReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenOtherVendorAndBarCodeShowDialogFalse()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        PurchaseLine: Record "Purchase Line";
        CrossRefNo: Code[20];
    begin
        // [FEATURE] [Intercompany] [Bar Code]
        // [SCENARIO 289240] Vendor B, Items X,Y Vendor Cross Reference BX, Bar Code Cross Reference PY
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is No
        // [SCENARIO 289240] ICRLookupPurchaseItem returns Cross Reference PY
        Initialize();
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Item Cross Reference for Item 1000 with No = 1234, Type = Vendor and Type No = 20000
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[1], CrossRefNo, LibraryInventory.CreateItemNo,
          ItemCrossReference[1]."Cross-Reference Type"::Vendor, LibraryPurchase.CreateVendorNo);

        // [GIVEN] Item Cross References for Item 1001 with same No and Type = Bar Code
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[2], CrossRefNo, ItemCrossReference[1]."Item No.",
          ItemCrossReference[2]."Cross-Reference Type"::"Bar Code", LibraryUtility.GenerateGUID);

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Cross-Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, LibraryPurchase.CreateVendorNo, CrossRefNo);

        // [WHEN] Ran ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = FALSE
        DistIntegration.ICRLookupPurchaseItem(PurchaseLine, ItemCrossReference[1], false);

        // [THEN] ICRLookupPurchaseItem returns Item Cross Reference with Item No = 1001
        ItemCrossReference[1].TestField("Item No.", ItemCrossReference[2]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenOtherVendorShowDialogFalse()
    var
        ItemCrossReference: Record "Item Cross Reference";
        PurchaseLine: Record "Purchase Line";
        CrossRefNo: Code[20];
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO 289240] Vendor B, Cross Reference BX
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is No
        // [SCENARIO 289240] ICRLookupPurchaseItem throws error
        Initialize();
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference.FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Item Cross Reference for Item with No = 1234, Type = Vendor and Type No = 20000
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference, CrossRefNo, LibraryInventory.CreateItemNo,
          ItemCrossReference."Cross-Reference Type"::Vendor, LibraryPurchase.CreateVendorNo);

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Cross-Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, LibraryPurchase.CreateVendorNo, CrossRefNo);

        // [WHEN] Run ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = FALSE
        asserterror DistIntegration.ICRLookupPurchaseItem(PurchaseLine, ItemCrossReference, false);

        // [THEN] Error "There are no items with cross reference: 1234"
        Assert.ExpectedError(StrSubstNo(CrossRefNotExistsErr, CrossRefNo));
        Assert.ExpectedErrorCode(DialogCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenOtherMultipleVendorsShowDialogFalse()
    var
        ItemCrossReference: Record "Item Cross Reference";
        PurchaseLine: Record "Purchase Line";
        CrossRefNo: Code[20];
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO 289240] Vendors: B,C Cross References BX,CY
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is No
        // [SCENARIO 289240] ICRLookupPurchaseItem throws error
        Initialize();
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference.FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Two Item Cross References with same No = 1234, same Type = Vendor and Type No 20000 and 30000
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference, CrossRefNo, LibraryInventory.CreateItemNo,
          ItemCrossReference."Cross-Reference Type"::Vendor, LibraryPurchase.CreateVendorNo);
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference, CrossRefNo, LibraryInventory.CreateItemNo,
          ItemCrossReference."Cross-Reference Type"::Vendor, LibraryPurchase.CreateVendorNo);

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Cross-Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, LibraryPurchase.CreateVendorNo, CrossRefNo);

        // [WHEN] Run ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = FALSE
        asserterror DistIntegration.ICRLookupPurchaseItem(PurchaseLine, ItemCrossReference, false);

        // [THEN] Error "There are no items with cross reference: 1234"
        Assert.ExpectedError(StrSubstNo(CrossRefNotExistsErr, CrossRefNo));
        Assert.ExpectedErrorCode(DialogCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenOneVendorShowDialogFalse()
    var
        ItemCrossReference: Record "Item Cross Reference";
        PurchaseLine: Record "Purchase Line";
        CrossRefNo: Code[20];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO 289240] Vendor A, Cross Reference AX
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is No
        // [SCENARIO 289240] ICRLookupPurchaseItem Returns Cross Reference AX
        Initialize();
        ItemNo := LibraryInventory.CreateItemNo;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference.FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Item Cross Reference for Item 1000 with No = 1234, Type = Vendor and Type No = 10000
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference, CrossRefNo, ItemNo,
          ItemCrossReference."Cross-Reference Type"::Vendor, LibraryPurchase.CreateVendorNo);

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Cross-Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(
          PurchaseLine, CopyStr(ItemCrossReference."Cross-Reference Type No.", 1, MaxStrLen(PurchaseLine."Buy-from Vendor No.")),
          CrossRefNo);

        // [WHEN] Run ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = FALSE
        DistIntegration.ICRLookupPurchaseItem(PurchaseLine, ItemCrossReference, false);

        // [THEN] ICRLookupPurchaseItem returns Item Cross Reference with Item No = 1000
        ItemCrossReference.TestField("Item No.", ItemNo)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenNoCrossRefShowDialogFalse()
    var
        DummyItemCrossReference: Record "Item Cross Reference";
        PurchaseLine: Record "Purchase Line";
        CrossRefNo: Code[20];
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO 289240] No Cross References with No = 1234
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A with Cross Reference No = 1234 and ShowDialog is No
        // [SCENARIO 289240] ICRLookupPurchaseItem Returns Cross Reference AX
        Initialize();
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(DummyItemCrossReference.FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Cross-Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(
          PurchaseLine, LibraryPurchase.CreateVendorNo, CrossRefNo);

        // [WHEN] Run ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = FALSE
        asserterror DistIntegration.ICRLookupPurchaseItem(PurchaseLine, DummyItemCrossReference, false);

        // [THEN] Error "There are no items with cross reference: 1234"
        Assert.ExpectedError(StrSubstNo(CrossRefNotExistsErr, CrossRefNo));
        Assert.ExpectedErrorCode(DialogCodeErr);
    end;

    [Test]
    [HandlerFunctions('CrossReferenceListCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenStanCancelsCrossReferenceList()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        PurchaseLine: Record "Purchase Line";
        VendorNo: array[2] of Code[20];
        CrossRefNo: Code[20];
        Index: Integer;
        ItemIndex: Integer;
        ItemNo: array[2] of Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is Yes
        // [SCENARIO 289240] Page Cross Reference List opened with Cross References
        // [SCENARIO 289240] When Stan pushes cancel on page, then error
        Initialize();
        for ItemIndex := 1 to ArrayLen(ItemNo) do begin
            ItemNo[ItemIndex] := LibraryInventory.CreateItemNo;
            VendorNo[ItemIndex] := LibraryPurchase.CreateVendorNo;
        end;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Two Item Cross References for Item 1000 with No = 1234, Type = Vendor and Type No = 10000 and 20000
        // [GIVEN] Two similar Item Cross References for Item 1001
        for ItemIndex := 1 to ArrayLen(ItemNo) do
            for Index := 1 to ArrayLen(ItemCrossReference) do
                LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[Index], CrossRefNo, ItemNo[ItemIndex],
                  ItemCrossReference[Index]."Cross-Reference Type"::Vendor, VendorNo[Index]);

        // [GIVEN] Item Cross Reference for Item 1100 with No = 1234, Type = Bar Code
        LibraryInventory.CreateItemCrossReferenceWithNo(
          ItemCrossReference[2], CrossRefNo, LibraryInventory.CreateItemNo, ItemCrossReference[2]."Cross-Reference Type"::"Bar Code",
          LibraryUtility.GenerateGUID);

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Cross-Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, VendorNo[1], CrossRefNo);

        // [GIVEN] Ran ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = TRUE
        asserterror DistIntegration.ICRLookupPurchaseItem(PurchaseLine, ItemCrossReference[1], true);

        // [GIVEN] Page Cross Reference List opened

        // [WHEN] Stan pushes Cancel on page Cross Reference List
        // Done in CrossReferenceListCancelModalPageHandler

        // [THEN] Error "There are no items with cross reference: 1234"
        Assert.ExpectedError(StrSubstNo(CrossRefNotExistsErr, CrossRefNo));
        Assert.ExpectedErrorCode(DialogCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeItemVendorLeadCalcTime()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemVendor: Record "Item Vendor";
        ItemCrossReference: Record "Item Cross Reference";
        SavedItemCrossReferenceDescription: Text[100];
    begin
        // [SCENARIO 292774] Description should not be cleared in item cross refference when updating Lead Time Calculation of related Item Vendor record
        Initialize();

        // [GIVEN] Item Cross Reference of "Vendor" type with Item No. "ITEM", Vendor No. "VEND", Variant Code "VARIANT" and description "DESCR"
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        CreateItemCrossReference(
          ItemCrossReference, Item."No.", ItemVariant.Code,
          ItemCrossReference."Cross-Reference Type"::Vendor, LibraryPurchase.CreateVendorNo);
        SavedItemCrossReferenceDescription := ItemCrossReference.Description;

        // [WHEN] "Lead Time Calculation" field of Item Vendor record "VEND", "ITEM", "VARIANT" is being updated
        ItemVendor.Get(ItemCrossReference."Cross-Reference Type No.", Item."No.", ItemVariant.Code);
        Evaluate(ItemVendor."Lead Time Calculation", '<1D>');
        ItemVendor.Modify(true);

        // [THEN] Item Cross Reference description is not changed
        ItemCrossReference.Find;
        ItemCrossReference.TestField(Description, SavedItemCrossReferenceDescription);
    end;

    [Test]
    [HandlerFunctions('CrossReferenceListModalPageHandler')]
    [Scope('OnPrem')]
    procedure PurchLineLookupCrossRefNoWhenSameVendorDifferentItems()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
        CrossRefNo: Code[20];
        Index: Integer;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 289240] Vendor A, Items: X,Y Cross References AX and AY
        // [SCENARIO 289240] Stan looks up Cross-Reference No in Purchase Line and selects Cross Reference AY
        // [SCENARIO 289240] Purchase Line has Item Y
        Initialize();
        VendorNo := LibraryPurchase.CreateVendorNo;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");
        LibraryVariableStorage.Enqueue(CrossRefNo);

        // [GIVEN] Item Cross References for Items 1000 and 1001 with same No = 1234, Type = Vendor and Type No = 10000
        for Index := 1 to ArrayLen(ItemCrossReference) do begin
            LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[Index], CrossRefNo, LibraryInventory.CreateItemNo,
              ItemCrossReference[Index]."Cross-Reference Type"::Vendor, VendorNo);
            EnqueueItemCrossReferenceFields(ItemCrossReference[Index]);
        end;

        // [GIVEN] Purchase Invoice with "Buy-from Vendor No." = 10000 and Purchase Line had Type = Item
        CreatePurchaseInvoiceOneLineWithLineTypeItem(PurchaseLine, VendorNo);

        // [GIVEN] Stan Looked up Cross Reference No in Purchase Line
        PurchaseLine.CrossReferenceNoLookUp;

        // [GIVEN] Page Cross Reference List opened showing both Cross References, first for Item 1000, second for Item 1001
        // [GIVEN] Stan selected the second one
        // Done in CrossReferenceListModalPageHandler

        // [WHEN] Push OK on page Cross Reference List
        // Done in CrossReferenceListModalPageHandler

        // [THEN] Purchase Line has No = 1001
        PurchaseLine.TestField("No.", ItemCrossReference[2]."Item No.");
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemVendorUpdatesItemCrossRefEntryAfterModifyVendorItemNo()
    var
        ItemVendor: Record "Item Vendor";
        ItemCrossReference: Record "Item Cross Reference";
        ItemNo: Code[20];
        VendorNo: Code[20];
    begin
        // [SCENARIO 374879] "Item Cross Reference" must be updated after update "Item Vendor"."Vendor Item No."
        Initialize();

        // [GIVEN] Item = "I", Vendor = "V"
        ItemNo := LibraryInventory.CreateItemNo();
        VendorNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] "Item Vendor" - "Vendor No." = "V", "Item No." = "I"
        ItemVendor.Init();
        ItemVendor.Validate("Item No.", ItemNo);
        ItemVendor.Validate("Vendor No.", VendorNo);
        ItemVendor.Insert(true);

        // [WHEN] Validate "Item Vendor"."Vendor Item No." = "VI"
        ItemVendor.Validate("Vendor Item No.", LibraryUtility.GenerateGUID());

        // [THEN] "Item Cross Reference"."Cross-Reference No." = "VI"
        ItemCrossReference.SetRange("Item No.", ItemNo);
        ItemCrossReference.SetRange("Cross-Reference Type", ItemCrossReference."Cross-Reference Type"::Vendor);
        ItemCrossReference.SetRange("Cross-Reference Type No.", VendorNo);
        ItemCrossReference.FindFirst();
        ItemCrossReference.TestField("Cross-Reference No.", ItemVendor."Vendor Item No.");
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ERM Item Cross Reference Purch");

        LibraryVariableStorage.Clear;
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ERM Item Cross Reference Purch");

        Commit();
        IsInitialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ERM Item Cross Reference Purch");
    end;

    local procedure CreateItemCrossReference(var ItemCrossReference: Record "Item Cross Reference"; ItemNo: Code[20]; ItemVariantNo: Code[10]; CrossReferenceType: Option; CrossReferenceTypeNo: Code[30])
    begin
        with ItemCrossReference do begin
            Init;
            Validate("Item No.", ItemNo);
            Validate("Variant Code", ItemVariantNo);
            Validate("Cross-Reference Type", CrossReferenceType);
            Validate("Cross-Reference Type No.", CrossReferenceTypeNo);
            Validate(
              "Cross-Reference No.",
              LibraryUtility.GenerateRandomCode(FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference"));
            Validate(Description, CrossReferenceTypeNo);
            Insert(true);
        end;
    end;

    local procedure MockPurchaseLineForICRLookupPurchaseItem(var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20]; CrossRefNo: Code[20])
    begin
        PurchaseLine.Init();
        PurchaseLine.Type := PurchaseLine.Type::Item;
        PurchaseLine."Buy-from Vendor No." := VendorNo;
        PurchaseLine."Cross-Reference No." := CrossRefNo;
    end;

    local procedure CreatePurchaseInvoiceOneLineWithLineTypeItem(var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        LibraryPurchase.CreatePurchaseLineSimple(PurchaseLine, PurchaseHeader);
        PurchaseLine.Validate(Type, PurchaseLine.Type::Item);
        PurchaseLine.Modify(true);
    end;

    local procedure EnqueueItemCrossReferenceFields(ItemCrossReference: Record "Item Cross Reference")
    begin
        LibraryVariableStorage.Enqueue(ItemCrossReference."Cross-Reference Type");
        LibraryVariableStorage.Enqueue(ItemCrossReference."Cross-Reference Type No.");
        LibraryVariableStorage.Enqueue(ItemCrossReference."Item No.");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CrossReferenceListModalPageHandler(var CrossReferenceList: TestPage "Cross Reference List")
    begin
        CrossReferenceList.FILTER.SetFilter("Cross-Reference No.", LibraryVariableStorage.DequeueText);
        repeat
            CrossReferenceList."Cross-Reference Type".AssertEquals(LibraryVariableStorage.DequeueInteger);
            CrossReferenceList."Cross-Reference Type No.".AssertEquals(LibraryVariableStorage.DequeueText);
            CrossReferenceList."Item No.".AssertEquals(LibraryVariableStorage.DequeueText);
        until CrossReferenceList.Next = false;
        CrossReferenceList.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CrossReferenceListCancelModalPageHandler(var CrossReferenceList: TestPage "Cross Reference List")
    begin
        CrossReferenceList.Cancel.Invoke;
    end;
}

