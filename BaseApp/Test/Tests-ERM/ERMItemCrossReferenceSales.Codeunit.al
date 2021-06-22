codeunit 134460 "ERM Item Cross Reference Sales"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Item Cross Reference] [Cross-Reference No] [Sales]
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        CrossRefNotExistsErr: Label 'There are no items with cross reference %1.';
        DialogCodeErr: Label 'Dialog';
        DistIntegration: Codeunit "Dist. Integration";

    [Test]
    [HandlerFunctions('CrossReferenceListModalPageHandler')]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenSameCustomersForSameItemsAndBarCodeShowDialogTrue()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        SalesLine: Record "Sales Line";
        CustNo: array[2] of Code[20];
        CrossRefNo: Code[20];
        Index: Integer;
        ItemIndex: Integer;
        ItemNo: array[2] of Code[20];
    begin
        // [FEATURE] [UI] [Bar Code]
        // [SCENARIO 289240] Customers: A,B, Items: X,Y,Z, Customer Cross References: AX, AY, BX, BY and Bar Code Cross Reference PZ
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is Yes
        // [SCENARIO 289240] Page Cross Reference List shows only Cross References for Customer A and Bar Code (AX, AY and PZ)
        Initialize;
        for ItemIndex := 1 to ArrayLen(ItemNo) do begin
            ItemNo[ItemIndex] := LibraryInventory.CreateItemNo;
            CustNo[ItemIndex] := LibrarySales.CreateCustomerNo;
        end;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");
        LibraryVariableStorage.Enqueue(CrossRefNo);

        // [GIVEN] Two Item Cross References for Item 1000 with No = 1234, Type = Customer and Type No = 10000 and 20000
        // [GIVEN] Two similar Item Cross References for Item 1001
        for ItemIndex := 1 to ArrayLen(ItemNo) do begin
            for Index := 1 to ArrayLen(ItemCrossReference) do
                LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[Index], CrossRefNo, ItemNo[ItemIndex],
                  ItemCrossReference[Index]."Cross-Reference Type"::Customer, CustNo[Index]);
            EnqueueItemCrossReferenceFields(ItemCrossReference[1]);
        end;

        // [GIVEN] Item Cross Reference for Item 1100 with No = 1234, Type = Bar Code
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[2], CrossRefNo, LibraryInventory.CreateItemNo,
          ItemCrossReference[2]."Cross-Reference Type"::"Bar Code", LibraryUtility.GenerateGUID);
        EnqueueItemCrossReferenceFields(ItemCrossReference[2]);

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Cross-Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, CustNo[1], CrossRefNo);

        // [GIVEN] Ran ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = TRUE
        DistIntegration.ICRLookupSalesItem(SalesLine, ItemCrossReference[1], true);

        // [GIVEN] Page Cross Reference List opened showing three Cross References:
        // [GIVEN] Two with Type Customer and Type No = 10000 and last one with Type Bar Code, Stan selected the last one
        // Done in CrossReferenceListModalPageHandler

        // [WHEN] Push OK on page Cross Reference List
        // Done in CrossReferenceListModalPageHandler

        // [THEN] ICRLookupSalesItem returns Item Cross Reference with Item No = 1100
        ItemCrossReference[1].TestField("Item No.", ItemCrossReference[2]."Item No.");
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('CrossReferenceListModalPageHandler')]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenSameCustomersForSameItemsShowDialogTrue()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        SalesLine: Record "Sales Line";
        CustNo: array[2] of Code[20];
        CrossRefNo: Code[20];
        Index: Integer;
        ItemIndex: Integer;
        ItemNo: array[2] of Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 289240] Customers: A,B, Items: X,Y, Cross References: AX, AY, BX, BY
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is Yes
        // [SCENARIO 289240] Page Cross Reference List shows only Cross References for Customer A (AX and AY)
        Initialize;
        for ItemIndex := 1 to ArrayLen(ItemNo) do begin
            ItemNo[ItemIndex] := LibraryInventory.CreateItemNo;
            CustNo[ItemIndex] := LibrarySales.CreateCustomerNo;
        end;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");
        LibraryVariableStorage.Enqueue(CrossRefNo);

        // [GIVEN] Two Item Cross References for Item 1000 with No = 1234, Type = Customer and Type No = 10000 and 20000
        // [GIVEN] Two similar Item Cross References for Item 1001
        for ItemIndex := 1 to ArrayLen(ItemNo) do begin
            for Index := 1 to ArrayLen(ItemCrossReference) do
                LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[Index], CrossRefNo, ItemNo[ItemIndex],
                  ItemCrossReference[Index]."Cross-Reference Type"::Customer, CustNo[Index]);
            EnqueueItemCrossReferenceFields(ItemCrossReference[1]);
        end;

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Cross-Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, CustNo[1], CrossRefNo);

        // [GIVEN] Ran ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = TRUE
        DistIntegration.ICRLookupSalesItem(SalesLine, ItemCrossReference[1], true);

        // [GIVEN] Page Cross Reference List opened showing two Cross References with Type No = 10000: first for Item 1000, second for Item 1001
        // [GIVEN] Stan selected the second one
        // Done in CrossReferenceListModalPageHandler

        // [WHEN] Push OK on page Cross Reference List
        // Done in CrossReferenceListModalPageHandler

        // [THEN] ICRLookupSalesItem returns Item Cross Reference with Item No = 1001
        ItemCrossReference[1].TestField("Item No.", ItemCrossReference[2]."Item No.");
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('CrossReferenceListModalPageHandler')]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenCustomerAndBarCodeDifferentItemsShowDialogTrue()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        SalesLine: Record "Sales Line";
        CustNo: Code[20];
        CrossRefNo: Code[20];
    begin
        // [FEATURE] [UI] [Bar Code]
        // [SCENARIO 289240] Customer A, Items: X,Y Customer Cross Reference AX and Bar Code Cross Reference PY
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is Yes
        // [SCENARIO 289240] Page Cross Reference List shows both Cross References (AX and PY)
        Initialize;
        CustNo := LibrarySales.CreateCustomerNo;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");
        LibraryVariableStorage.Enqueue(CrossRefNo);

        // [GIVEN] Item Cross References for Item 1000 with No = 1234, Type = Customer and Type No = 10000
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[1], CrossRefNo, LibraryInventory.CreateItemNo,
          ItemCrossReference[1]."Cross-Reference Type"::Customer, CustNo);
        EnqueueItemCrossReferenceFields(ItemCrossReference[1]);

        // [GIVEN] Item Cross References for Item 1001 with same No and Type = Bar Code
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[2], CrossRefNo, LibraryInventory.CreateItemNo,
          ItemCrossReference[2]."Cross-Reference Type"::"Bar Code", LibraryUtility.GenerateGUID);
        EnqueueItemCrossReferenceFields(ItemCrossReference[2]);

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Cross-Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, CustNo, CrossRefNo);

        // [GIVEN] Ran ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = TRUE
        DistIntegration.ICRLookupSalesItem(SalesLine, ItemCrossReference[1], true);

        // [GIVEN] Page Cross Reference List opened showing both Cross References: first for Item 1000, second for Item 1001
        // [GIVEN] Stan selected the second one
        // Done in CrossReferenceListModalPageHandler

        // [WHEN] Push OK on page Cross Reference List
        // Done in CrossReferenceListModalPageHandler

        // [THEN] ICRLookupSalesItem returns Item Cross Reference with Item No = 1001
        ItemCrossReference[1].TestField("Item No.", ItemCrossReference[2]."Item No.");
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('CrossReferenceListModalPageHandler')]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenCustomerAndBlankTypeDifferentItemsShowDialogTrue()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        SalesLine: Record "Sales Line";
        CustNo: Code[20];
        CrossRefNo: Code[20];
    begin
        // [FEATURE] [UI] [Bar Code]
        // [SCENARIO 289240] Customer A, Items: X,Y Customer Cross Reference AX and <blank> Type Cross Reference TY
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is Yes
        // [SCENARIO 289240] Page Cross Reference List shows both Cross References (AX and TY)
        Initialize;
        CustNo := LibrarySales.CreateCustomerNo;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");
        LibraryVariableStorage.Enqueue(CrossRefNo);

        // [GIVEN] Item Cross References for Item 1000 with No = 1234, Type = Customer and Type No = 10000
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[1], CrossRefNo, LibraryInventory.CreateItemNo,
          ItemCrossReference[1]."Cross-Reference Type"::Customer, CustNo);

        // [GIVEN] Item Cross References for Item 1001 with No = 1234 and Type = <blank>
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[2], CrossRefNo, LibraryInventory.CreateItemNo,
          ItemCrossReference[2]."Cross-Reference Type"::" ", '');
        EnqueueItemCrossReferenceFields(ItemCrossReference[2]); // <blank> type record is to be displayed first
        EnqueueItemCrossReferenceFields(ItemCrossReference[1]);

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Cross-Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, CustNo, CrossRefNo);

        // [GIVEN] Ran ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = TRUE
        DistIntegration.ICRLookupSalesItem(SalesLine, ItemCrossReference[2], true);

        // [GIVEN] Page Cross Reference List opened showing both Cross References: first with <blank> Type, second with Type Customer
        // [GIVEN] Stan selected the second one
        // Done in CrossReferenceListModalPageHandler

        // [WHEN] Push OK on page Cross Reference List
        // Done in CrossReferenceListModalPageHandler

        // [THEN] ICRLookupSalesItem returns Item Cross Reference with Item No = 1000
        ItemCrossReference[2].TestField("Item No.", ItemCrossReference[1]."Item No.");
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('CrossReferenceListModalPageHandler')]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenSameCustomerDifferentItemsShowDialogTrue()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        SalesLine: Record "Sales Line";
        CustNo: Code[20];
        CrossRefNo: Code[20];
        Index: Integer;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 289240] Customer A, Items: X,Y Cross References AX and AY
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is Yes
        // [SCENARIO 289240] Page Cross Reference List shows both Cross References (AX and AY)
        Initialize;
        CustNo := LibrarySales.CreateCustomerNo;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");
        LibraryVariableStorage.Enqueue(CrossRefNo);

        // [GIVEN] Item Cross References for Items 1000 and 1001 with same No = 1234, Type = Customer and Type No = 10000
        for Index := 1 to ArrayLen(ItemCrossReference) do begin
            LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[Index], CrossRefNo, LibraryInventory.CreateItemNo,
              ItemCrossReference[Index]."Cross-Reference Type"::Customer, CustNo);
            EnqueueItemCrossReferenceFields(ItemCrossReference[Index]);
        end;

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Cross-Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, CustNo, CrossRefNo);

        // [GIVEN] Ran ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = TRUE
        DistIntegration.ICRLookupSalesItem(SalesLine, ItemCrossReference[1], true);

        // [GIVEN] Page Cross Reference List opened showing both Cross References, first for Item 1000, second for Item 1001
        // [GIVEN] Stan selected the second one
        // Done in CrossReferenceListModalPageHandler

        // [WHEN] Push OK on page Cross Reference List
        // Done in CrossReferenceListModalPageHandler

        // [THEN] ICRLookupSalesItem returns Item Cross Reference with Item No = 1001
        ItemCrossReference[1].TestField("Item No.", ItemCrossReference[2]."Item No.");
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('CrossReferenceListModalPageHandler')]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenBarCodesDifferentItemsShowDialogTrue()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        SalesLine: Record "Sales Line";
        CrossRefNo: Code[20];
        Index: Integer;
    begin
        // [FEATURE] [UI] [Bar Code]
        // [SCENARIO 289240] Items: X,Y, Bar Code Cross References: PX,PY
        // [SCENARIO 289240] ICRLookupSalesItem for Customer and ShowDialog is Yes
        // [SCENARIO 289240] Page Cross Reference List shows both Cross References (PX and PY)
        Initialize;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");
        LibraryVariableStorage.Enqueue(CrossRefNo);

        // [GIVEN] Item Cross References for Items 1000 and 1001, both with No = 1234 and Type = Bar Code
        for Index := 1 to ArrayLen(ItemCrossReference) do begin
            LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[Index], CrossRefNo, LibraryInventory.CreateItemNo,
              ItemCrossReference[Index]."Cross-Reference Type"::"Bar Code", LibraryUtility.GenerateGUID);
            EnqueueItemCrossReferenceFields(ItemCrossReference[Index]);
        end;

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Cross-Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, LibrarySales.CreateCustomerNo, CrossRefNo);

        // [GIVEN] Ran ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = TRUE
        DistIntegration.ICRLookupSalesItem(SalesLine, ItemCrossReference[1], true);

        // [GIVEN] Page Cross Reference List opened showing both Cross References, first for Item 1000, second for Item 1001
        // [GIVEN] Stan selected the second one
        // Done in CrossReferenceListModalPageHandler

        // [WHEN] Push OK on page Cross Reference List
        // Done in CrossReferenceListModalPageHandler

        // [THEN] ICRLookupSalesItem returns Item Cross Reference with Item No = 1001
        ItemCrossReference[1].TestField("Item No.", ItemCrossReference[2]."Item No.");
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenCustomerAndBarCodeSameItemShowDialogTrue()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        SalesLine: Record "Sales Line";
        CustNo: Code[20];
        CrossRefNo: Code[20];
    begin
        // [FEATURE] [Bar Code]
        // [SCENARIO 289240] Customer A, Item X, Customer Cross Reference AX, Bar Code Cross Reference PX
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is Yes
        // [SCENARIO 289240] Page Cross Reference List is not shown, ICRLookupSalesItem returns Cross Reference for Customer A (AX)
        Initialize;
        CustNo := LibrarySales.CreateCustomerNo;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Item Cross References for Item 1000 with No = 1234, Type = Customer and Type No = 10000
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[1], CrossRefNo, LibraryInventory.CreateItemNo,
          ItemCrossReference[1]."Cross-Reference Type"::Customer, CustNo);

        // [GIVEN] Item Cross References for same Item with same No and Type = Bar Code
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[2], CrossRefNo, ItemCrossReference[1]."Item No.",
          ItemCrossReference[2]."Cross-Reference Type"::"Bar Code", LibraryUtility.GenerateGUID);

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Cross-Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, CustNo, CrossRefNo);

        // [WHEN] Ran ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = TRUE
        DistIntegration.ICRLookupSalesItem(SalesLine, ItemCrossReference[2], true);

        // [THEN] ICRLookupSalesItem returns Item Cross Reference with Item No = 1000
        ItemCrossReference[2].TestField("Item No.", ItemCrossReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenCustomerAndBlankTypeSameItemShowDialogTrue()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        SalesLine: Record "Sales Line";
        CustNo: Code[20];
        CrossRefNo: Code[20];
    begin
        // [FEATURE] [Bar Code]
        // [SCENARIO 289240] Customer A, Item X, Customer Cross Reference AX, <blank> Type Cross Reference TX
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is Yes
        // [SCENARIO 289240] Page Cross Reference List is not shown, ICRLookupSalesItem returns Cross Reference for Customer A (AX)
        Initialize;
        CustNo := LibrarySales.CreateCustomerNo;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Item Cross References for Item 1000 with No = 1234, Type = Customer and Type No = 10000
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[1], CrossRefNo, LibraryInventory.CreateItemNo,
          ItemCrossReference[1]."Cross-Reference Type"::Customer, CustNo);

        // [GIVEN] Item Cross References for same Item with same No and Type = <blank>
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[2], CrossRefNo, ItemCrossReference[1]."Item No.",
          ItemCrossReference[2]."Cross-Reference Type"::" ", '');

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Cross-Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, CustNo, CrossRefNo);

        // [WHEN] Ran ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = TRUE
        DistIntegration.ICRLookupSalesItem(SalesLine, ItemCrossReference[2], true);

        // [THEN] ICRLookupSalesItem returns Item Cross Reference with Item No = 1000
        ItemCrossReference[2].TestField("Item No.", ItemCrossReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenBarCodesSameItemShowDialogTrue()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        SalesLine: Record "Sales Line";
        CrossRefNo: Code[20];
        ItemNo: Code[20];
        Index: Integer;
    begin
        // [FEATURE] [Bar Code]
        // [SCENARIO 289240] Item X, Bar Code Cross References: PX,TX
        // [SCENARIO 289240] ICRLookupSalesItem for Customer and ShowDialog is Yes
        // [SCENARIO 289240] Page Cross Reference List is not shown, ICRLookupSalesItem returns Cross Reference PX
        Initialize;
        ItemNo := LibraryInventory.CreateItemNo;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Item Cross References both for same Item, No = 1234 and Type = Bar Code, Type No are "P" and "T"
        for Index := 1 to ArrayLen(ItemCrossReference) do
            LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[Index], CrossRefNo, ItemNo,
              ItemCrossReference[Index]."Cross-Reference Type"::"Bar Code", LibraryUtility.GenerateGUID);

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Cross-Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, LibrarySales.CreateCustomerNo, CrossRefNo);

        // [WHEN] Run ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = TRUE
        DistIntegration.ICRLookupSalesItem(SalesLine, ItemCrossReference[2], true);

        // [THEN] ICRLookupSalesItem returns Item Cross Reference with Type No = "P"
        ItemCrossReference[2].TestField("Cross-Reference Type No.", ItemCrossReference[1]."Cross-Reference Type No.");
        ItemCrossReference[2].TestField("Item No.", ItemCrossReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenDifferentCustomersSameItemShowDialogTrue()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        SalesLine: Record "Sales Line";
        CrossRefNo: Code[20];
        ItemNo: Code[20];
        Index: Integer;
    begin
        // [SCENARIO 289240] Customers: A,B, Item X, Cross References AX and BX
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is Yes
        // [SCENARIO 289240] Page Cross Reference List is not shown, ICRLookupSalesItem returns Cross Reference for Customer A (AX)
        Initialize;
        ItemNo := LibraryInventory.CreateItemNo;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Two Item Cross References for Item 1000 with same No = 1234, Type = Customer, first has Type No = 10000, second has Type No = 20000
        for Index := 1 to ArrayLen(ItemCrossReference) do
            LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[Index], CrossRefNo, ItemNo,
              ItemCrossReference[Index]."Cross-Reference Type"::Customer, LibrarySales.CreateCustomerNo);

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Cross-Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(
          SalesLine, CopyStr(ItemCrossReference[1]."Cross-Reference Type No.", 1, MaxStrLen(SalesLine."Sell-to Customer No.")), CrossRefNo);

        // [WHEN] Run ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = TRUE
        DistIntegration.ICRLookupSalesItem(SalesLine, ItemCrossReference[2], true);

        // [THEN] ICRLookupSalesItem returns Item Cross Reference with Item No = 1000
        ItemCrossReference[2].TestField("Item No.", ItemCrossReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenDifferentCustomersDifferentItemsShowDialogTrue()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        SalesLine: Record "Sales Line";
        CrossRefNo: Code[20];
        Index: Integer;
    begin
        // [SCENARIO 289240] Customers: A,B, Items X,Y, Cross References AX and BY
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is Yes
        // [SCENARIO 289240] Page Cross Reference List is not shown, ICRLookupSalesItem returns Cross Reference for Customer A (AX)
        Initialize;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Item Cross Reference for Item 1000 with No = 1234, Type = Customer, Type No = 10000
        // [GIVEN] Item Cross Reference for Item 1001 with No = 1234, Type = Customer, Type No = 20000
        for Index := 1 to ArrayLen(ItemCrossReference) do
            LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[Index], CrossRefNo, LibraryInventory.CreateItemNo,
              ItemCrossReference[Index]."Cross-Reference Type"::Customer, LibrarySales.CreateCustomerNo);

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Cross-Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(
          SalesLine, CopyStr(ItemCrossReference[1]."Cross-Reference Type No.", 1, MaxStrLen(SalesLine."Sell-to Customer No.")), CrossRefNo);

        // [WHEN] Run ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = TRUE
        DistIntegration.ICRLookupSalesItem(SalesLine, ItemCrossReference[2], true);

        // [THEN] ICRLookupSalesItem returns Item Cross Reference with Item No = 1000
        ItemCrossReference[2].TestField("Item No.", ItemCrossReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenOtherCustomerAndBarCodeShowDialogTrue()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        SalesLine: Record "Sales Line";
        CrossRefNo: Code[20];
    begin
        // [FEATURE] [Bar Code]
        // [SCENARIO 289240] Customer B, Items X,Y Customer Cross Reference BX, Bar Code Cross Reference PY
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is Yes
        // [SCENARIO 289240] Page Cross Reference List is not shown, ICRLookupSalesItem returns Cross Reference PY
        Initialize;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Item Cross Reference for Item 1000 with No = 1234, Type = Customer and Type No = 20000
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[1], CrossRefNo, LibraryInventory.CreateItemNo,
          ItemCrossReference[1]."Cross-Reference Type"::Customer, LibrarySales.CreateCustomerNo);

        // [GIVEN] Item Cross References for Item 1001 with same No and Type = Bar Code
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[2], CrossRefNo, ItemCrossReference[1]."Item No.",
          ItemCrossReference[2]."Cross-Reference Type"::"Bar Code", LibraryUtility.GenerateGUID);

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Cross-Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, LibrarySales.CreateCustomerNo, CrossRefNo);

        // [WHEN] Ran ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = TRUE
        DistIntegration.ICRLookupSalesItem(SalesLine, ItemCrossReference[1], true);

        // [THEN] ICRLookupSalesItem returns Item Cross Reference with Item No = 1001
        ItemCrossReference[1].TestField("Item No.", ItemCrossReference[2]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenOtherCustomerShowDialogTrue()
    var
        ItemCrossReference: Record "Item Cross Reference";
        SalesLine: Record "Sales Line";
        CrossRefNo: Code[20];
    begin
        // [SCENARIO 289240] Customer B, Cross Reference BX
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is Yes
        // [SCENARIO 289240] ICRLookupSalesItem throws error
        Initialize;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference.FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Item Cross Reference for Item with No = 1234, Type = Customer and Type No = 20000
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference, CrossRefNo, LibraryInventory.CreateItemNo,
          ItemCrossReference."Cross-Reference Type"::Customer, LibrarySales.CreateCustomerNo);

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Cross-Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, LibrarySales.CreateCustomerNo, CrossRefNo);

        // [WHEN] Run ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = TRUE
        asserterror DistIntegration.ICRLookupSalesItem(SalesLine, ItemCrossReference, true);

        // [THEN] Error "There are no items with cross reference: 1234"
        Assert.ExpectedError(StrSubstNo(CrossRefNotExistsErr, CrossRefNo));
        Assert.ExpectedErrorCode(DialogCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenOtherMultipleCustomersShowDialogTrue()
    var
        ItemCrossReference: Record "Item Cross Reference";
        SalesLine: Record "Sales Line";
        CrossRefNo: Code[20];
    begin
        // [SCENARIO 289240] Customers: B,C Cross References BX,CY
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is Yes
        // [SCENARIO 289240] ICRLookupSalesItem throws error
        Initialize;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference.FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Two Item Cross References with same No = 1234, same Type = Customer and Type No 20000 and 30000
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference, CrossRefNo, LibraryInventory.CreateItemNo,
          ItemCrossReference."Cross-Reference Type"::Customer, LibrarySales.CreateCustomerNo);
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference, CrossRefNo, LibraryInventory.CreateItemNo,
          ItemCrossReference."Cross-Reference Type"::Customer, LibrarySales.CreateCustomerNo);

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Cross-Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, LibrarySales.CreateCustomerNo, CrossRefNo);

        // [WHEN] Run ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = TRUE
        asserterror DistIntegration.ICRLookupSalesItem(SalesLine, ItemCrossReference, true);

        // [THEN] Error "There are no items with cross reference: 1234"
        Assert.ExpectedError(StrSubstNo(CrossRefNotExistsErr, CrossRefNo));
        Assert.ExpectedErrorCode(DialogCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenOneCustomerShowDialogTrue()
    var
        ItemCrossReference: Record "Item Cross Reference";
        SalesLine: Record "Sales Line";
        CrossRefNo: Code[20];
        ItemNo: Code[20];
    begin
        // [SCENARIO 289240] Customer A, Cross Reference AX
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is Yes
        // [SCENARIO 289240] ICRLookupSalesItem Returns Cross Reference AX
        Initialize;
        ItemNo := LibraryInventory.CreateItemNo;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference.FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Item Cross Reference for Item 1000 with No = 1234, Type = Customer and Type No = 10000
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference, CrossRefNo, ItemNo,
          ItemCrossReference."Cross-Reference Type"::Customer, LibrarySales.CreateCustomerNo);

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Cross-Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(
          SalesLine, CopyStr(ItemCrossReference."Cross-Reference Type No.", 1, MaxStrLen(SalesLine."Sell-to Customer No.")), CrossRefNo);

        // [WHEN] Run ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = TRUE
        DistIntegration.ICRLookupSalesItem(SalesLine, ItemCrossReference, true);

        // [THEN] ICRLookupSalesItem returns Item Cross Reference with Item No = 1000
        ItemCrossReference.TestField("Item No.", ItemNo)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenNoCrossRefShowDialogTrue()
    var
        DummyItemCrossReference: Record "Item Cross Reference";
        SalesLine: Record "Sales Line";
        CrossRefNo: Code[20];
    begin
        // [SCENARIO 289240] No Cross References with No = 1234
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A with Cross Reference No = 1234 and ShowDialog is Yes
        // [SCENARIO 289240] ICRLookupSalesItem Returns Cross Reference AX
        Initialize;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(DummyItemCrossReference.FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Cross-Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, LibrarySales.CreateCustomerNo, CrossRefNo);

        // [WHEN] Run ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = TRUE
        asserterror DistIntegration.ICRLookupSalesItem(SalesLine, DummyItemCrossReference, true);

        // [THEN] Error "There are no items with cross reference: 1234"
        Assert.ExpectedError(StrSubstNo(CrossRefNotExistsErr, CrossRefNo));
        Assert.ExpectedErrorCode(DialogCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenSameCustomersForSameItemsAndBarCodeShowDialogFalse()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        SalesLine: Record "Sales Line";
        CustNo: array[2] of Code[20];
        CrossRefNo: Code[20];
        Index: Integer;
        ItemIndex: Integer;
        ItemNo: array[2] of Code[20];
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO 289240] Customers: A,B, Items: X,Y,Z, Customer Cross References: AX, AY, BX, BY and Bar Code Cross Reference PZ
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is No
        // [SCENARIO 289240] ICRLookupSalesItem returns Cross Reference for Customer A and Item X (AX)
        Initialize;
        for ItemIndex := 1 to ArrayLen(ItemNo) do begin
            ItemNo[ItemIndex] := LibraryInventory.CreateItemNo;
            CustNo[ItemIndex] := LibrarySales.CreateCustomerNo;
        end;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Two Item Cross References for Item 1000 with No = 1234, Type = Customer and Type No = 10000 and 20000
        // [GIVEN] Two similar Item Cross References for Item 1001
        for ItemIndex := 1 to ArrayLen(ItemNo) do
            for Index := 1 to ArrayLen(ItemCrossReference) do
                LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[Index], CrossRefNo, ItemNo[ItemIndex],
                  ItemCrossReference[Index]."Cross-Reference Type"::Customer, CustNo[Index]);

        // [GIVEN] Item Cross Reference for Item 1100 with No = 1234, Type = Bar Code
        LibraryInventory.CreateItemCrossReferenceWithNo(
          ItemCrossReference[2], CrossRefNo, LibraryInventory.CreateItemNo, ItemCrossReference[2]."Cross-Reference Type"::"Bar Code",
          LibraryUtility.GenerateGUID);

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Cross-Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, CustNo[1], CrossRefNo);

        // [WHEN] Run ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = FALSE
        DistIntegration.ICRLookupSalesItem(SalesLine, ItemCrossReference[2], false);

        // [THEN] ICRLookupSalesItem returns Item Cross Reference with Item No = 1000 and Type No = 10000
        ItemCrossReference[2].TestField("Item No.", ItemNo[1]);
        ItemCrossReference[2].TestField("Cross-Reference Type No.", CustNo[1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenSameCustomersForSameItemsShowDialogFalse()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        SalesLine: Record "Sales Line";
        CustNo: array[2] of Code[20];
        CrossRefNo: Code[20];
        Index: Integer;
        ItemIndex: Integer;
        ItemNo: array[2] of Code[20];
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO 289240] Customers: A,B, Items: X,Y, Cross References: AX, AY, BX, BY
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is No
        // [SCENARIO 289240] ICRLookupSalesItem returns Cross Reference for Customer A and Item X (AX)
        Initialize;
        for ItemIndex := 1 to ArrayLen(ItemNo) do begin
            ItemNo[ItemIndex] := LibraryInventory.CreateItemNo;
            CustNo[ItemIndex] := LibrarySales.CreateCustomerNo;
        end;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Two Item Cross References for Item 1000 with No = 1234, Type = Customer and Type No = 10000 and 20000
        // [GIVEN] Two similar Item Cross References for Item 1001
        for ItemIndex := 1 to ArrayLen(ItemNo) do
            for Index := 1 to ArrayLen(ItemCrossReference) do
                LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[Index], CrossRefNo, ItemNo[ItemIndex],
                  ItemCrossReference[Index]."Cross-Reference Type"::Customer, CustNo[Index]);

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Cross-Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, CustNo[1], CrossRefNo);

        // [When] Run ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = FALSE
        DistIntegration.ICRLookupSalesItem(SalesLine, ItemCrossReference[2], false);

        // [THEN] ICRLookupSalesItem returns Item Cross Reference with Item No = 1000 and Type No = 10000
        ItemCrossReference[2].TestField("Item No.", ItemNo[1]);
        ItemCrossReference[2].TestField("Cross-Reference Type No.", CustNo[1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenCustomerAndBarCodeDifferentItemsShowDialogFalse()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        SalesLine: Record "Sales Line";
        CustNo: Code[20];
        CrossRefNo: Code[20];
    begin
        // [FEATURE] [Intercompany] [Bar Code]
        // [SCENARIO 289240] Customer A, Items: X,Y Customer Cross Reference AX and Bar Code Cross Reference PY
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is No
        // [SCENARIO 289240] ICRLookupSalesItem returns Cross Reference for Customer A and Item X (AX)
        Initialize;
        CustNo := LibrarySales.CreateCustomerNo;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Item Cross References for Item 1000 with No = 1234, Type = Customer and Type No = 10000
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[1], CrossRefNo, LibraryInventory.CreateItemNo,
          ItemCrossReference[1]."Cross-Reference Type"::Customer, CustNo);

        // [GIVEN] Item Cross References for Item 1001 with same No and Type = Bar Code
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[2], CrossRefNo, LibraryInventory.CreateItemNo,
          ItemCrossReference[2]."Cross-Reference Type"::"Bar Code", LibraryUtility.GenerateGUID);

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Cross-Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, CustNo, CrossRefNo);

        // [WHEN] Ran ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = FALSE
        DistIntegration.ICRLookupSalesItem(SalesLine, ItemCrossReference[2], false);

        // [THEN] ICRLookupSalesItem returns Item Cross Reference with Item No = 1000
        ItemCrossReference[2].TestField("Item No.", ItemCrossReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenCustomerAndBlankTypeDifferentItemsShowDialogFalse()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        SalesLine: Record "Sales Line";
        CustNo: Code[20];
        CrossRefNo: Code[20];
    begin
        // [FEATURE] [Intercompany] [Bar Code]
        // [SCENARIO 289240] Customer A, Items: X,Y Customer Cross Reference AX and <blank> Type Cross Reference TY
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is No
        // [SCENARIO 289240] ICRLookupSalesItem returns Cross Reference for Customer A and Item X (AX)
        Initialize;
        CustNo := LibrarySales.CreateCustomerNo;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Item Cross References for Item 1000 with No = 1234, Type = Customer and Type No = 10000
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[1], CrossRefNo, LibraryInventory.CreateItemNo,
          ItemCrossReference[1]."Cross-Reference Type"::Customer, CustNo);

        // [GIVEN] Item Cross References for Item 1001 with No = 1234 and Type = <blank>
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[2], CrossRefNo, LibraryInventory.CreateItemNo,
          ItemCrossReference[2]."Cross-Reference Type"::" ", '');

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Cross-Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, CustNo, CrossRefNo);

        // [WHEN] Run ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = FALSE
        DistIntegration.ICRLookupSalesItem(SalesLine, ItemCrossReference[2], false);

        // [THEN] ICRLookupSalesItem returns Item Cross Reference with Item No = 1000
        ItemCrossReference[2].TestField("Item No.", ItemCrossReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenSameCustomerDifferentItemsShowDialogFalse()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        SalesLine: Record "Sales Line";
        CustNo: Code[20];
        CrossRefNo: Code[20];
        Index: Integer;
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO 289240] Customer A, Items: X,Y Cross References AX and AY
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is No
        // [SCENARIO 289240] ICRLookupSalesItem returns Cross Reference for Customer A and Item X (AX)
        Initialize;
        CustNo := LibrarySales.CreateCustomerNo;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Item Cross References for Items 1000 and 1001 with same No = 1234, Type = Customer and Type No = 10000
        for Index := 1 to ArrayLen(ItemCrossReference) do
            LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[Index], CrossRefNo, LibraryInventory.CreateItemNo,
              ItemCrossReference[Index]."Cross-Reference Type"::Customer, CustNo);

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Cross-Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, CustNo, CrossRefNo);

        // [WHEN] Run ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = FALSE
        DistIntegration.ICRLookupSalesItem(SalesLine, ItemCrossReference[2], false);

        // [THEN] ICRLookupSalesItem returns Item Cross Reference with Item No = 1000
        ItemCrossReference[2].TestField("Item No.", ItemCrossReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenBarCodesDifferentItemsShowDialogFalse()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        SalesLine: Record "Sales Line";
        CrossRefNo: Code[20];
        Index: Integer;
    begin
        // [FEATURE] [Intercompany] [Bar Code]
        // [SCENARIO 289240] Items: X,Y, Bar Code Cross References: PX,PY
        // [SCENARIO 289240] ICRLookupSalesItem for Customer and ShowDialog is No
        // [SCENARIO 289240] ICRLookupSalesItem returns Cross Reference PX
        Initialize;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Item Cross References for Items 1000 and 1001, both with No = 1234 and Type = Bar Code
        for Index := 1 to ArrayLen(ItemCrossReference) do
            LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[Index], CrossRefNo, LibraryInventory.CreateItemNo,
              ItemCrossReference[Index]."Cross-Reference Type"::"Bar Code", LibraryUtility.GenerateGUID);

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Cross-Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, LibrarySales.CreateCustomerNo, CrossRefNo);

        // [WHEN] Run ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = FALSE
        DistIntegration.ICRLookupSalesItem(SalesLine, ItemCrossReference[2], false);

        // [THEN] ICRLookupSalesItem returns Item Cross Reference with Item No = 1001
        ItemCrossReference[2].TestField("Item No.", ItemCrossReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenCustomerAndBarCodeSameItemShowDialogFalse()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        SalesLine: Record "Sales Line";
        CustNo: Code[20];
        CrossRefNo: Code[20];
    begin
        // [FEATURE] [Intercompany] [Bar Code]
        // [SCENARIO 289240] Customer A, Item X, Customer Cross Reference AX, Bar Code Cross Reference PX
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is No
        // [SCENARIO 289240] ICRLookupSalesItem returns Cross Reference for Customer A (AX)
        Initialize;
        CustNo := LibrarySales.CreateCustomerNo;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Item Cross References for Item 1000 with No = 1234, Type = Customer and Type No = 10000
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[1], CrossRefNo, LibraryInventory.CreateItemNo,
          ItemCrossReference[1]."Cross-Reference Type"::Customer, CustNo);

        // [GIVEN] Item Cross References for same Item with same No and Type = Bar Code
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[2], CrossRefNo, ItemCrossReference[1]."Item No.",
          ItemCrossReference[2]."Cross-Reference Type"::"Bar Code", LibraryUtility.GenerateGUID);

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Cross-Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, CustNo, CrossRefNo);

        // [WHEN] Ran ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = FALSE
        DistIntegration.ICRLookupSalesItem(SalesLine, ItemCrossReference[2], false);

        // [THEN] ICRLookupSalesItem returns Item Cross Reference with Item No = 1000
        ItemCrossReference[2].TestField("Item No.", ItemCrossReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenCustomerAndBlankTypeSameItemShowDialogFalse()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        SalesLine: Record "Sales Line";
        CustNo: Code[20];
        CrossRefNo: Code[20];
    begin
        // [FEATURE] [Intercompany] [Bar Code]
        // [SCENARIO 289240] Customer A, Item X, Customer Cross Reference AX, <blank> Type Cross Reference TX
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is No
        // [SCENARIO 289240] Page Cross Reference List is not shown, ICRLookupSalesItem returns Cross Reference for Customer A (AX)
        Initialize;
        CustNo := LibrarySales.CreateCustomerNo;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Item Cross References for Item 1000 with No = 1234, Type = Customer and Type No = 10000
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[1], CrossRefNo, LibraryInventory.CreateItemNo,
          ItemCrossReference[1]."Cross-Reference Type"::Customer, CustNo);

        // [GIVEN] Item Cross References for same Item with same No and Type = <blank>
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[2], CrossRefNo, ItemCrossReference[1]."Item No.",
          ItemCrossReference[2]."Cross-Reference Type"::" ", '');

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Cross-Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, CustNo, CrossRefNo);

        // [WHEN] Ran ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = FALSE
        DistIntegration.ICRLookupSalesItem(SalesLine, ItemCrossReference[2], false);

        // [THEN] ICRLookupSalesItem returns Item Cross Reference with Item No = 1000
        ItemCrossReference[2].TestField("Item No.", ItemCrossReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenBarCodesSameItemShowDialogFalse()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        SalesLine: Record "Sales Line";
        CrossRefNo: Code[20];
        ItemNo: Code[20];
        Index: Integer;
    begin
        // [FEATURE] [Intercompany] [Bar Code]
        // [SCENARIO 289240] Item X, Bar Code Cross References: PX,TX
        // [SCENARIO 289240] ICRLookupSalesItem for Customer and ShowDialog is No
        // [SCENARIO 289240] ICRLookupSalesItem returns Cross Reference PX
        Initialize;
        ItemNo := LibraryInventory.CreateItemNo;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Item Cross References both for same Item, No = 1234 and Type = Bar Code, Type No are "P" and "T"
        for Index := 1 to ArrayLen(ItemCrossReference) do
            LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[Index], CrossRefNo, ItemNo,
              ItemCrossReference[Index]."Cross-Reference Type"::"Bar Code", LibraryUtility.GenerateGUID);

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Cross-Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, LibrarySales.CreateCustomerNo, CrossRefNo);

        // [WHEN] Run ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = FALSE
        DistIntegration.ICRLookupSalesItem(SalesLine, ItemCrossReference[2], false);

        // [THEN] ICRLookupSalesItem returns Item Cross Reference with Type No = "P"
        ItemCrossReference[2].TestField("Cross-Reference Type No.", ItemCrossReference[1]."Cross-Reference Type No.");
        ItemCrossReference[2].TestField("Item No.", ItemCrossReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenDifferentCustomersSameItemShowDialogFalse()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        SalesLine: Record "Sales Line";
        CrossRefNo: Code[20];
        ItemNo: Code[20];
        Index: Integer;
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO 289240] Customers: A,B, Item X, Cross References AX and BX
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is No
        // [SCENARIO 289240] ICRLookupSalesItem returns Cross Reference for Customer A (AX)
        Initialize;
        ItemNo := LibraryInventory.CreateItemNo;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Two Item Cross References for Item 1000 with same No = 1234, Type = Customer, first has Type No = 10000, second has Type No = 20000
        for Index := 1 to ArrayLen(ItemCrossReference) do
            LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[Index], CrossRefNo, ItemNo,
              ItemCrossReference[Index]."Cross-Reference Type"::Customer, LibrarySales.CreateCustomerNo);

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Cross-Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(
          SalesLine, CopyStr(ItemCrossReference[1]."Cross-Reference Type No.", 1, MaxStrLen(SalesLine."Sell-to Customer No.")), CrossRefNo);

        // [WHEN] Run ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = FALSE
        DistIntegration.ICRLookupSalesItem(SalesLine, ItemCrossReference[2], false);

        // [THEN] ICRLookupSalesItem returns Item Cross Reference with Item No = 1000
        ItemCrossReference[2].TestField("Item No.", ItemCrossReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenDifferentCustomersSameItemShowDialogFalseSecond()
    var
        ItemCrossReference: array [2] of Record "Item Cross Reference";
        SalesLine: Record "Sales Line";
        CrossRefNo: Code[20];
        ItemNo: Code[20];
        Index: Integer;
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO 315787] Customers: A,B, Item X, Cross References AX and BX
        // [SCENARIO 315787] ICRLookupSalesItem for Customer B and ShowDialog is No
        // [SCENARIO 315787] ICRLookupSalesItem returns Cross Reference for Customer B (BX)
        Initialize;
        ItemNo := LibraryInventory.CreateItemNo;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Two Item Cross References for Item 1000 with same No = 1234, Type = Customer, first has Type No = 10000, second has Type No = 20000
        for Index := 1 to ArrayLen(ItemCrossReference) do
            LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[Index], CrossRefNo, ItemNo,
              ItemCrossReference[Index]."Cross-Reference Type"::Customer, LibrarySales.CreateCustomerNo);

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 20000 and Cross-Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(
          SalesLine, CopyStr(ItemCrossReference[2]."Cross-Reference Type No.", 1, MaxStrLen(SalesLine."Sell-to Customer No.")), CrossRefNo);

        // [WHEN] Run ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = FALSE
        DistIntegration.ICRLookupSalesItem(SalesLine, ItemCrossReference[1], false);

        // [THEN] ICRLookupSalesItem returns Item Cross Reference with Item No = 2000
        ItemCrossReference[1].TestField("Item No.", ItemCrossReference[2]."Item No.");
        ItemCrossReference[1].TestField("Cross-Reference Type No.", ItemCrossReference[2]."Cross-Reference Type No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenDifferentCustomersDifferentItemsShowDialogFalse()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        SalesLine: Record "Sales Line";
        CrossRefNo: Code[20];
        Index: Integer;
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO 289240] Customers: A,B, Items X,Y, Cross References AX and BY
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is No
        // [SCENARIO 289240] ICRLookupSalesItem returns Cross Reference for Customer A (AX)
        Initialize;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Item Cross Reference for Item 1000 with No = 1234, Type = Customer, Type No = 10000
        // [GIVEN] Item Cross Reference for Item 1001 with No = 1234, Type = Customer, Type No = 20000
        for Index := 1 to ArrayLen(ItemCrossReference) do
            LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[Index], CrossRefNo, LibraryInventory.CreateItemNo,
              ItemCrossReference[Index]."Cross-Reference Type"::Customer, LibrarySales.CreateCustomerNo);

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Cross-Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(
          SalesLine, CopyStr(ItemCrossReference[1]."Cross-Reference Type No.", 1, MaxStrLen(SalesLine."Sell-to Customer No.")), CrossRefNo);

        // [WHEN] Run ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = FALSE
        DistIntegration.ICRLookupSalesItem(SalesLine, ItemCrossReference[2], false);

        // [THEN] ICRLookupSalesItem returns Item Cross Reference with Item No = 1000
        ItemCrossReference[2].TestField("Item No.", ItemCrossReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenOtherCustomerAndBarCodeShowDialogFalse()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        SalesLine: Record "Sales Line";
        CrossRefNo: Code[20];
    begin
        // [FEATURE] [Intercompany] [Bar Code]
        // [SCENARIO 289240] Customer B, Items X,Y Customer Cross Reference BX, Bar Code Cross Reference PY
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is No
        // [SCENARIO 289240] ICRLookupSalesItem returns Cross Reference PY
        Initialize;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Item Cross Reference for Item 1000 with No = 1234, Type = Customer and Type No = 20000
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[1], CrossRefNo, LibraryInventory.CreateItemNo,
          ItemCrossReference[1]."Cross-Reference Type"::Customer, LibrarySales.CreateCustomerNo);

        // [GIVEN] Item Cross References for Item 1001 with same No and Type = Bar Code
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[2], CrossRefNo, ItemCrossReference[1]."Item No.",
          ItemCrossReference[2]."Cross-Reference Type"::"Bar Code", LibraryUtility.GenerateGUID);

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Cross-Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, LibrarySales.CreateCustomerNo, CrossRefNo);

        // [WHEN] Ran ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = FALSE
        DistIntegration.ICRLookupSalesItem(SalesLine, ItemCrossReference[1], false);

        // [THEN] ICRLookupSalesItem returns Item Cross Reference with Item No = 1001
        ItemCrossReference[1].TestField("Item No.", ItemCrossReference[2]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenOtherCustomerShowDialogFalse()
    var
        ItemCrossReference: Record "Item Cross Reference";
        SalesLine: Record "Sales Line";
        CrossRefNo: Code[20];
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO 289240] Customer B, Cross Reference BX
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is No
        // [SCENARIO 289240] ICRLookupSalesItem throws error
        Initialize;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference.FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Item Cross Reference for Item with No = 1234, Type = Customer and Type No = 20000
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference, CrossRefNo, LibraryInventory.CreateItemNo,
          ItemCrossReference."Cross-Reference Type"::Customer, LibrarySales.CreateCustomerNo);

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Cross-Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, LibrarySales.CreateCustomerNo, CrossRefNo);

        // [WHEN] Run ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = FALSE
        asserterror DistIntegration.ICRLookupSalesItem(SalesLine, ItemCrossReference, false);

        // [THEN] Error "There are no items with cross reference: 1234"
        Assert.ExpectedError(StrSubstNo(CrossRefNotExistsErr, CrossRefNo));
        Assert.ExpectedErrorCode(DialogCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenOtherMultipleCustomersShowDialogFalse()
    var
        ItemCrossReference: Record "Item Cross Reference";
        SalesLine: Record "Sales Line";
        CrossRefNo: Code[20];
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO 289240] Customers: B,C Cross References BX,CY
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is No
        // [SCENARIO 289240] ICRLookupSalesItem throws error
        Initialize;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference.FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Two Item Cross References with same No = 1234, same Type = Customer and Type No 20000 and 30000
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference, CrossRefNo, LibraryInventory.CreateItemNo,
          ItemCrossReference."Cross-Reference Type"::Customer, LibrarySales.CreateCustomerNo);
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference, CrossRefNo, LibraryInventory.CreateItemNo,
          ItemCrossReference."Cross-Reference Type"::Customer, LibrarySales.CreateCustomerNo);

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Cross-Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, LibrarySales.CreateCustomerNo, CrossRefNo);

        // [WHEN] Run ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = FALSE
        asserterror DistIntegration.ICRLookupSalesItem(SalesLine, ItemCrossReference, false);

        // [THEN] Error "There are no items with cross reference: 1234"
        Assert.ExpectedError(StrSubstNo(CrossRefNotExistsErr, CrossRefNo));
        Assert.ExpectedErrorCode(DialogCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenOneCustomerShowDialogFalse()
    var
        ItemCrossReference: Record "Item Cross Reference";
        SalesLine: Record "Sales Line";
        CrossRefNo: Code[20];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO 289240] Customer A, Cross Reference AX
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is No
        // [SCENARIO 289240] ICRLookupSalesItem Returns Cross Reference AX
        Initialize;
        ItemNo := LibraryInventory.CreateItemNo;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference.FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Item Cross Reference for Item 1000 with No = 1234, Type = Customer and Type No = 10000
        LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference, CrossRefNo, ItemNo,
          ItemCrossReference."Cross-Reference Type"::Customer, LibrarySales.CreateCustomerNo);

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Cross-Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(
          SalesLine, CopyStr(ItemCrossReference."Cross-Reference Type No.", 1, MaxStrLen(SalesLine."Sell-to Customer No.")), CrossRefNo);

        // [WHEN] Run ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = FALSE
        DistIntegration.ICRLookupSalesItem(SalesLine, ItemCrossReference, false);

        // [THEN] ICRLookupSalesItem returns Item Cross Reference with Item No = 1000
        ItemCrossReference.TestField("Item No.", ItemNo)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenNoCrossRefShowDialogFalse()
    var
        DummyItemCrossReference: Record "Item Cross Reference";
        SalesLine: Record "Sales Line";
        CrossRefNo: Code[20];
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO 289240] No Cross References with No = 1234
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A with Cross Reference No = 1234 and ShowDialog is No
        // [SCENARIO 289240] ICRLookupSalesItem Returns Cross Reference AX
        Initialize;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(DummyItemCrossReference.FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Cross-Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(
          SalesLine, LibrarySales.CreateCustomerNo, CrossRefNo);

        // [WHEN] Run ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = FALSE
        asserterror DistIntegration.ICRLookupSalesItem(SalesLine, DummyItemCrossReference, false);

        // [THEN] Error "There are no items with cross reference: 1234"
        Assert.ExpectedError(StrSubstNo(CrossRefNotExistsErr, CrossRefNo));
        Assert.ExpectedErrorCode(DialogCodeErr);
    end;

    [Test]
    [HandlerFunctions('CrossReferenceListCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenStanCancelsCrossReferenceList()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        SalesLine: Record "Sales Line";
        CustNo: array[2] of Code[20];
        CrossRefNo: Code[20];
        Index: Integer;
        ItemIndex: Integer;
        ItemNo: array[2] of Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is Yes
        // [SCENARIO 289240] Page Cross Reference List opened with Cross References
        // [SCENARIO 289240] When Stan pushes cancel on page, then error
        Initialize;
        for ItemIndex := 1 to ArrayLen(ItemNo) do begin
            ItemNo[ItemIndex] := LibraryInventory.CreateItemNo;
            CustNo[ItemIndex] := LibrarySales.CreateCustomerNo;
        end;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");

        // [GIVEN] Two Item Cross References for Item 1000 with No = 1234, Type = Customer and Type No = 10000 and 20000
        // [GIVEN] Two similar Item Cross References for Item 1001
        for ItemIndex := 1 to ArrayLen(ItemNo) do
            for Index := 1 to ArrayLen(ItemCrossReference) do
                LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[Index], CrossRefNo, ItemNo[ItemIndex],
                  ItemCrossReference[Index]."Cross-Reference Type"::Customer, CustNo[Index]);

        // [GIVEN] Item Cross Reference for Item 1100 with No = 1234, Type = Bar Code
        LibraryInventory.CreateItemCrossReferenceWithNo(
          ItemCrossReference[2], CrossRefNo, LibraryInventory.CreateItemNo, ItemCrossReference[2]."Cross-Reference Type"::"Bar Code",
          LibraryUtility.GenerateGUID);

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Cross-Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, CustNo[1], CrossRefNo);

        // [GIVEN] Ran ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = TRUE
        asserterror DistIntegration.ICRLookupSalesItem(SalesLine, ItemCrossReference[1], true);

        // [GIVEN] Page Cross Reference List opened

        // [WHEN] Stan pushes Cancel on page Cross Reference List
        // Done in CrossReferenceListCancelModalPageHandler

        // [THEN] Error "There are no items with cross reference: 1234"
        Assert.ExpectedError(StrSubstNo(CrossRefNotExistsErr, CrossRefNo));
        Assert.ExpectedErrorCode(DialogCodeErr);
    end;

    [Test]
    [HandlerFunctions('CrossReferenceListModalPageHandler')]
    [Scope('OnPrem')]
    procedure SalesLineLookupCrossRefNoWhenSameCustomerDifferentItems()
    var
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        SalesLine: Record "Sales Line";
        CustNo: Code[20];
        CrossRefNo: Code[20];
        Index: Integer;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 289240] Customer A, Items: X,Y Cross References AX and AY
        // [SCENARIO 289240] Stan looks up Cross-Reference No in Sales Line and selects Cross Reference AY
        // [SCENARIO 289240] Sales Line has Item Y
        Initialize;
        CustNo := LibrarySales.CreateCustomerNo;
        CrossRefNo :=
          LibraryUtility.GenerateRandomCode(ItemCrossReference[1].FieldNo("Cross-Reference No."), DATABASE::"Item Cross Reference");
        LibraryVariableStorage.Enqueue(CrossRefNo);

        // [GIVEN] Item Cross References for Items 1000 and 1001 with same No = 1234, Type = Customer and Type No = 10000
        for Index := 1 to ArrayLen(ItemCrossReference) do begin
            LibraryInventory.CreateItemCrossReferenceWithNo(ItemCrossReference[Index], CrossRefNo, LibraryInventory.CreateItemNo,
              ItemCrossReference[Index]."Cross-Reference Type"::Customer, CustNo);
            EnqueueItemCrossReferenceFields(ItemCrossReference[Index]);
        end;

        // [GIVEN] Sales Invoice with "Sell-to Customer No." = 10000 and Sales Line had Type = Item
        CreateSalesInvoiceOneLineWithLineTypeItem(SalesLine, CustNo);

        // [GIVEN] Stan Looked up Cross Reference No in Sales Line
        SalesLine.CrossReferenceNoLookUp;

        // [GIVEN] Page Cross Reference List opened showing both Cross References, first for Item 1000, second for Item 1001
        // [GIVEN] Stan selected the second one
        // Done in CrossReferenceListModalPageHandler

        // [WHEN] Push OK on page Cross Reference List
        // Done in CrossReferenceListModalPageHandler

        // [THEN] Sales Line has No = 1001
        SalesLine.TestField("No.", ItemCrossReference[2]."Item No.");
        LibraryVariableStorage.AssertEmpty;
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear;
    end;

    local procedure MockSalesLineForICRLookupSalesItem(var SalesLine: Record "Sales Line"; CustNo: Code[20]; CrossRefNo: Code[20])
    begin
        SalesLine.Init;
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."Sell-to Customer No." := CustNo;
        SalesLine."Cross-Reference No." := CrossRefNo;
    end;

    local procedure CreateSalesInvoiceOneLineWithLineTypeItem(var SalesLine: Record "Sales Line"; CustNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustNo);
        LibrarySales.CreateSalesLineSimple(SalesLine, SalesHeader);
        SalesLine.Validate(Type, SalesLine.Type::Item);
        SalesLine.Modify(true);
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

