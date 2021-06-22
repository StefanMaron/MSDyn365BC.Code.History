codeunit 137908 "SCM Assembly Order"
{
    Permissions = TableData "Posted Assembly Header" = rimd,
                  TableData "Warehouse Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    var
        MfgSetup: Record "Manufacturing Setup";
    begin
        // [FEATURE] [Assembly] [SCM]
        MfgSetup.Get;
        WorkDate2 := CalcDate(MfgSetup."Default Safety Lead Time", WorkDate); // to avoid Due Date Before Work Date message.
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryAssembly: Codeunit "Library - Assembly";
        CnfmRefreshLines: Label 'This assembly order may have customized lines. Are you sure that you want to reset the lines according to the assembly BOM?';
        MSGAssertLineCount: Label 'Bad Line count of Order: %1 expected %2, got %3';
        LibraryKitting: Codeunit "Library - Kitting";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        WorkDate2: Date;
        Initialized: Boolean;
        TXTQtyPerNoChange: Label 'You cannot change Quantity per when Type is '' ''.';

    [Normal]
    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Assembly Order");
        if Initialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Assembly Order");

        LibraryERMCountryData.CreateVATData;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        Initialized := true;
        Commit;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Assembly Order");
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure BUG232108TwoUOM()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        BOMComp: Record "BOM Component";
        Item: Record Item;
        childItem: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        parent: Code[20];
        BOMQtyPer: Decimal;
        HeaderQty: Decimal;
        ParentQtyPerUOM: Decimal;
    begin
        Initialize;
        BOMQtyPer := 3;
        HeaderQty := 2;
        ParentQtyPerUOM := 15;

        parent := MakeItemWithLot;
        Item.Get(parent);
        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, ParentQtyPerUOM);
        childItem.Get(MakeItem);
        LibraryManufacturing.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Item, childItem."No.", BOMQtyPer, childItem."Base Unit of Measure");

        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parent, HeaderQty));
        AssemblyHeader.Validate("Unit of Measure Code", NonBaseUOM.Code);

        validateQuantityonLines(AssemblyHeader."No.", HeaderQty * ParentQtyPerUOM * BOMQtyPer);
        ValidateTotalQuantityToConsume(AssemblyHeader, HeaderQty * ParentQtyPerUOM * BOMQtyPer);

        AsmLineFindFirst(AssemblyHeader, AssemblyLine);
        ValidateQuantityPer(AssemblyLine, ParentQtyPerUOM * BOMQtyPer);

        asserterror Error('') // roll back
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure BUG232108TwoUOMUOMbeforeQty()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        BOMComp: Record "BOM Component";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        childItem: Record Item;
        parent: Code[20];
        BOMQtyPer: Decimal;
        HeaderQty: Decimal;
        ParentQtyPerUOM: Decimal;
    begin
        Initialize;
        BOMQtyPer := 3;
        HeaderQty := 2;
        ParentQtyPerUOM := 15;

        parent := MakeItemWithLot;
        Item.Get(parent);
        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, ParentQtyPerUOM);
        childItem.Get(MakeItem);
        LibraryManufacturing.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Item, childItem."No.", BOMQtyPer, childItem."Base Unit of Measure");

        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parent, 0)); // No asm lines
        AssemblyHeader.Validate("Unit of Measure Code", NonBaseUOM.Code);
        AssemblyHeader.Validate(Quantity, HeaderQty);

        validateQuantityonLines(AssemblyHeader."No.", HeaderQty * ParentQtyPerUOM * BOMQtyPer);
        ValidateTotalQuantityToConsume(AssemblyHeader, HeaderQty * ParentQtyPerUOM * BOMQtyPer);

        AsmLineFindFirst(AssemblyHeader, AssemblyLine);
        ValidateQuantityPer(AssemblyLine, ParentQtyPerUOM * BOMQtyPer);

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OneOrderNoLine()
    var
        AssemblyHeader: Record "Assembly Header";
        Parent: Code[20];
    begin
        Initialize;
        Parent := MakeItemWithLot;
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, Parent, 1));

        AssemblyHeader.RefreshBOM;
        validateCount(AssemblyHeader."No.", 0);

        asserterror Error('') // roll back
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure OneOrderAddOneLine()
    var
        AssemblyHeader: Record "Assembly Header";
        BOMComp: Record "BOM Component";
        childItem: Record Item;
        parent: Code[20];
    begin
        Initialize;
        parent := MakeItemWithLot;
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parent, 1));
        childItem.Get(MakeItem);
        LibraryManufacturing.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Item, childItem."No.", 1, childItem."Base Unit of Measure");

        AssemblyHeader.RefreshBOM;
        validateCount(AssemblyHeader."No.", 1);

        asserterror Error('') // roll back
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure OneOrderOneLine()
    var
        AssemblyHeader: Record "Assembly Header";
        BOMComp: Record "BOM Component";
        childItem: Record Item;
        parent: Code[20];
    begin
        Initialize;
        parent := MakeItemWithLot;
        childItem.Get(MakeItem);
        LibraryManufacturing.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Item, childItem."No.", 1, childItem."Base Unit of Measure");

        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parent, 1));
        validateCount(AssemblyHeader."No.", 1);

        asserterror Error('') // roll back
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure OneOrderTwoLine()
    var
        AssemblyHeader: Record "Assembly Header";
        BOMComp: Record "BOM Component";
        childItem: Record Item;
        parent: Code[20];
    begin
        Initialize;
        parent := MakeItemWithLot;
        childItem.Get(MakeItem);
        LibraryManufacturing.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Item, childItem."No.", 1, childItem."Base Unit of Measure");
        childItem.Get(MakeItem);
        LibraryManufacturing.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Item, childItem."No.", 1, childItem."Base Unit of Measure");

        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parent, 1));
        validateCount(AssemblyHeader."No.", 2);

        asserterror Error('') // roll back
    end;

    [Test]
    [HandlerFunctions('ConfirmItemChange,AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure OneOrderTwoLineChangeItem()
    var
        AssemblyHeader: Record "Assembly Header";
        BOMComp: Record "BOM Component";
        childItem: Record Item;
        parent: Code[20];
        SecondParent: Code[20];
    begin
        Initialize;
        parent := MakeItemWithLot;
        childItem.Get(MakeItem);
        LibraryManufacturing.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Item, childItem."No.", 1, childItem."Base Unit of Measure");
        childItem.Get(MakeItem);
        LibraryManufacturing.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Item, childItem."No.", 1, childItem."Base Unit of Measure");

        SecondParent := MakeItemWithLot;
        childItem.Get(MakeItem);
        LibraryManufacturing.CreateBOMComponent(
          BOMComp, SecondParent, BOMComp.Type::Item, childItem."No.", 1, childItem."Base Unit of Measure");
        childItem.Get(MakeItem);
        LibraryManufacturing.CreateBOMComponent(
          BOMComp, SecondParent, BOMComp.Type::Item, childItem."No.", 1, childItem."Base Unit of Measure");
        childItem.Get(MakeItem);
        LibraryManufacturing.CreateBOMComponent(
          BOMComp, SecondParent, BOMComp.Type::Item, childItem."No.", 1, childItem."Base Unit of Measure");
        childItem.Get(MakeItem);
        LibraryManufacturing.CreateBOMComponent(
          BOMComp, SecondParent, BOMComp.Type::Item, childItem."No.", 1, childItem."Base Unit of Measure");

        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parent, 1));
        validateCount(AssemblyHeader."No.", 2);

        AssemblyHeader.Validate("Item No.", SecondParent);
        validateCount(AssemblyHeader."No.", 4);

        asserterror Error('') // roll back
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure OneOrderOneItemOneResource()
    var
        AssemblyHeader: Record "Assembly Header";
        BOMComp: Record "BOM Component";
        childItem: Record Item;
        resource: Record Resource;
        parent: Code[20];
    begin
        Initialize;
        parent := MakeItemWithLot;
        childItem.Get(MakeItem);
        LibraryManufacturing.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Item, childItem."No.", 1, childItem."Base Unit of Measure");
        resource.Get(LibraryKitting.CreateResourceWithNewUOM(500, 700));
        LibraryManufacturing.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Resource, resource."No.", 1, resource."Base Unit of Measure");

        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parent, 1));
        validateCount(AssemblyHeader."No.", 2);

        asserterror Error('') // roll back
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure OneOrderOneItemandResourceandT()
    var
        AssemblyHeader: Record "Assembly Header";
        BOMComp: Record "BOM Component";
        childItem: Record Item;
        resource: Record Resource;
        parent: Code[20];
    begin
        Initialize;
        parent := MakeItemWithLot;
        childItem.Get(MakeItem);
        LibraryManufacturing.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Item, childItem."No.", 1, childItem."Base Unit of Measure");
        resource.Get(LibraryKitting.CreateResourceWithNewUOM(500, 700));
        LibraryManufacturing.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Resource, resource."No.", 1, resource."Base Unit of Measure");
        LibraryManufacturing.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::" ", '', 0, '');
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parent, 1));
        validateCount(AssemblyHeader."No.", 3);

        asserterror Error('') // roll back
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,ConfirmRefreshLines')]
    [Scope('OnPrem')]
    procedure OneOrderTwoLineRefreshOneLine()
    var
        AssemblyHeader: Record "Assembly Header";
        BOMComp: Record "BOM Component";
        childItem: Record Item;
        resource: Record Resource;
        parent: Code[20];
    begin
        Initialize;
        parent := MakeItemWithLot;
        childItem.Get(MakeItem);
        LibraryManufacturing.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Item, childItem."No.", 1, childItem."Base Unit of Measure");
        resource.Get(LibraryKitting.CreateResourceWithNewUOM(500, 700));
        LibraryManufacturing.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Resource, resource."No.", 1, resource."Base Unit of Measure");
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parent, 1));
        validateCount(AssemblyHeader."No.", 2);
        childItem.Get(MakeItem);
        LibraryManufacturing.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Item, childItem."No.", 1, childItem."Base Unit of Measure");
        AssemblyHeader.RefreshBOM;
        validateCount(AssemblyHeader."No.", 3);

        asserterror Error('') // roll back
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmRefreshLines(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, CnfmRefreshLines) > 0, Question);
        Reply := true;
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure OneOrderTwoLineDelete()
    var
        AssemblyHeader: Record "Assembly Header";
        BOMComp: Record "BOM Component";
        childItem: Record Item;
        parent: Code[20];
    begin
        Initialize;
        parent := MakeItemWithLot;
        childItem.Get(MakeItem);
        LibraryManufacturing.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Item, childItem."No.", 1, childItem."Base Unit of Measure");
        childItem.Get(MakeItem);
        LibraryManufacturing.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Item, childItem."No.", 1, childItem."Base Unit of Measure");

        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parent, 1));
        validateCount(AssemblyHeader."No.", 2);
        AssemblyHeader.Delete(true);
        validateDeleted(AssemblyHeader, 0);

        asserterror Error('') // roll back
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure OneCompAverage()
    var
        AssemblyHeader: Record "Assembly Header";
        BOMComp: Record "BOM Component";
        Item: Record Item;
        childItem: Record Item;
        parent: Code[20];
    begin
        Initialize;
        parent := MakeItemWithLot;
        Item.Get(parent);
        Item.Validate("Costing Method", Item."Costing Method"::Average);
        childItem.Get(LibraryKitting.CreateItemWithNewUOM(10, 700));
        LibraryManufacturing.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Item, childItem."No.", 10, childItem."Base Unit of Measure");
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parent, 1));
        AssemblyHeader.UpdateUnitCost;
        ValidateOrderUnitCost(AssemblyHeader, 100);

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BomWithResourceUsageType()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        BOMComp: Record "BOM Component";
        resource: Record Resource;
        parent: Code[20];
    begin
        Initialize;
        parent := MakeItemWithLot;
        resource.Get(LibraryKitting.CreateResourceWithNewUOM(500, 700));
        LibraryManufacturing.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Resource, resource."No.", 1, resource."Base Unit of Measure");
        resource.Get(LibraryKitting.CreateResourceWithNewUOM(500, 700));
        LibraryManufacturing.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Resource, resource."No.", 1, resource."Base Unit of Measure");
        BOMComp.Validate("Resource Usage Type", BOMComp."Resource Usage Type"::Fixed);
        BOMComp.Modify(true);

        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parent, 1));
        validateCount(AssemblyHeader."No.", 2);
        AsmLineFindFirst(AssemblyHeader, AssemblyLine);
        ValidateLineResourceTypeUsage(AssemblyLine, AssemblyLine."Resource Usage Type"::Direct);
        AssemblyLine.Next;
        ValidateLineResourceTypeUsage(AssemblyLine, AssemblyLine."Resource Usage Type"::Fixed);

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BomWithResourceUsageTypeFixed()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        BOMComp: Record "BOM Component";
        resource: Record Resource;
        parent: Code[20];
        ParentQty: Decimal;
        BomQty: Decimal;
    begin
        Initialize;
        ParentQty := 5;
        BomQty := 2;

        parent := MakeItemWithLot;
        resource.Get(LibraryKitting.CreateResourceWithNewUOM(500, 700));
        LibraryManufacturing.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Resource, resource."No.", BomQty, resource."Base Unit of Measure");
        resource.Get(LibraryKitting.CreateResourceWithNewUOM(500, 700));
        LibraryManufacturing.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Resource, resource."No.", BomQty, resource."Base Unit of Measure");
        BOMComp.Validate("Resource Usage Type", BOMComp."Resource Usage Type"::Fixed);
        BOMComp.Modify(true);

        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parent, ParentQty));
        validateCount(AssemblyHeader."No.", 2);
        AsmLineFindFirst(AssemblyHeader, AssemblyLine);
        ValidateLineResourceTypeUsage(AssemblyLine, AssemblyLine."Resource Usage Type"::Direct);
        ValidateQuantity(AssemblyLine, BomQty * ParentQty);
        AssemblyLine.Validate("Resource Usage Type", AssemblyLine."Resource Usage Type"::Fixed);
        ValidateQuantity(AssemblyLine, BomQty);

        AssemblyLine.Next;
        ValidateLineResourceTypeUsage(AssemblyLine, AssemblyLine."Resource Usage Type"::Fixed);
        ValidateQuantity(AssemblyLine, BomQty);
        AssemblyLine.Validate("Resource Usage Type", AssemblyLine."Resource Usage Type"::Direct);
        ValidateQuantity(AssemblyLine, BomQty * ParentQty);

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OneResourceFixedChange()
    var
        BOMComp: Record "BOM Component";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        resource: Record Resource;
        Parent: Code[20];
        ParentQty: Decimal;
        BomQty: Decimal;
    begin
        Initialize;
        Parent := LibraryKitting.CreateItemWithLotAndNewUOM(500, 700, 10);
        resource.Get(LibraryKitting.CreateResourceWithNewUOM(100, 0));
        LibraryManufacturing.CreateBOMComponent(
          BOMComp, Parent, BOMComp.Type::Resource, resource."No.", 5, resource."Base Unit of Measure");
        BOMComp.Validate("Resource Usage Type", BOMComp."Resource Usage Type"::Fixed);
        BOMComp.Modify(true);

        ParentQty := 5;
        BomQty := 5;

        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, Parent, ParentQty));
        AsmLineFindFirst(AssemblyHeader, AssemblyLine);
        ValidateQuantity(AssemblyLine, BomQty);

        AssemblyHeader.Validate(Quantity, 10);
        AssemblyLine.FindFirst;
        ValidateQuantity(AssemblyLine, BomQty);

        asserterror Error('') // roll back
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure ChangeUnitCost()
    var
        AssemblyHeader: Record "Assembly Header";
        BOMComp: Record "BOM Component";
        childItem: Record Item;
        AssemblyLine: Record "Assembly Line";
        parent: Code[20];
        Costprice: Decimal;
    begin
        Initialize;
        parent := LibraryKitting.CreateStdCostItemWithNewUOM(500, 700, 1);
        Costprice := 500;
        childItem.Get(LibraryKitting.CreateItemWithNewUOM(Costprice, 700));
        LibraryManufacturing.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Item, childItem."No.", 1, childItem."Base Unit of Measure");
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parent, 1));
        validateCount(AssemblyHeader."No.", 1);
        AsmLineFindFirst(AssemblyHeader, AssemblyLine);
        ValidateLineUnitCost(AssemblyLine, Costprice);

        asserterror AssemblyLine.Validate("Unit Cost", 100);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuantityPerline()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        item: Record Item;
        parent: Code[20];
    begin
        Initialize;
        parent := LibraryKitting.CreateStdCostItemWithNewUOM(500, 700, 1);
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parent, 10));
        item.Get(LibraryKitting.CreateItemWithNewUOM(100, 700));
        LibraryAssembly.CreateAssemblyLine(
          AssemblyHeader, AssemblyLine, AssemblyLine.Type::Item, item."No.", item."Base Unit of Measure", 20, 1, 'Test QuantityPer ');

        AsmLineFindFirst(AssemblyHeader, AssemblyLine);
        ValidateQuantityPer(AssemblyLine, 1);

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuantityPerlineChange()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        item: Record Item;
        parent: Code[20];
    begin
        Initialize;
        parent := LibraryKitting.CreateStdCostItemWithNewUOM(500, 700, 1);
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parent, 5));
        item.Get(LibraryKitting.CreateItemWithNewUOM(100, 700));
        LibraryKitting.AddLine(AssemblyHeader, AssemblyLine.Type::Item, item."No.", item."Base Unit of Measure", 20, 0, 'Test QuantityPer');

        AsmLineFindFirst(AssemblyHeader, AssemblyLine);
        AssemblyLine.Validate("Quantity per", 0);
        ValidateQuantityPer(AssemblyLine, 0); // BUG252757 Change to 0 allowed
        AssemblyLine.Validate("Quantity per", 10);
        ValidateQuantityPer(AssemblyLine, 10);
        ValidateQuantity(AssemblyLine, 5 * 10);

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BUG252757QtyPerInitValue()
    var
        AssemblyLine: Record "Assembly Line";
        ItemNo: Code[20];
    begin
        Initialize;
        // BUG252757 Qty per on the Assembly Line cannot be set to 0
        ItemNo := LibraryKitting.CreateItemWithNewUOM(100, 700);
        AssemblyLine.Init;
        AssemblyLine.Type := AssemblyLine.Type::Item;
        AssemblyLine.Validate("No.", ItemNo);

        ValidateQuantityPer(AssemblyLine, 0);

        asserterror Error('') // roll back
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure ChangeUOMHeader()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        Item: Record Item;
        childItem: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        Costprice: Decimal;
        parent: Code[20];
    begin
        Initialize;
        Costprice := 400;
        parent := LibraryKitting.CreateStdCostItemWithNewUOM(Costprice, 700, 1);
        Item.Get(parent);
        Item.Validate("Costing Method", Item."Costing Method"::Average);

        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parent, 5));
        childItem.Get(LibraryKitting.CreateItemWithNewUOM(100, 700));
        LibraryKitting.AddLine(
          AssemblyHeader, AssemblyLine.Type::Item, childItem."No.", childItem."Base Unit of Measure", 20, 4, 'Test UOM Header');

        AssemblyHeader.UpdateUnitCost;
        ValidateOrderUnitCost(AssemblyHeader, 400);
        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, 6);
        AssemblyHeader.Validate("Unit of Measure Code", NonBaseUOM.Code);
        AssemblyHeader.UpdateUnitCost;
        ValidateOrderUnitCost(AssemblyHeader, 2400);

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Bug233632ChangeUOMConsume()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        Costprice: Decimal;
        parent: Code[20];
    begin
        Initialize;
        Costprice := 400;
        parent := LibraryKitting.CreateStdCostItemWithNewUOM(Costprice, 700, 1);
        Item.Get(parent);
        Item.Validate("Costing Method", Item."Costing Method"::Average);
        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, 2);

        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parent, 10));
        Item.Get(LibraryKitting.CreateItemWithNewUOM(100, 700));

        AssemblyHeader.Validate("Quantity to Assemble", 3);
        AssemblyHeader.Validate("Unit of Measure Code", NonBaseUOM.Code);

        LibraryKitting.AddLine(AssemblyHeader, AssemblyLine.Type::Item, Item."No.", Item."Base Unit of Measure", 10, 1, 'Test UOM consume');

        LibraryAssembly.SetLinkToLines(AssemblyHeader, AssemblyLine);
        AssemblyLine.FindFirst;
        ValidateQuantityPer(AssemblyLine, 1);
        ValidateQuantityToConsume(AssemblyLine, 10);

        AssemblyHeader.Validate("Quantity to Assemble", 3);

        LibraryAssembly.SetLinkToLines(AssemblyHeader, AssemblyLine);
        AssemblyLine.FindFirst;
        ValidateQuantityPer(AssemblyLine, 1);
        ValidateQuantity(AssemblyLine, 10);
        ValidateQuantityToConsume(AssemblyLine, 3);

        asserterror Error('') // roll back
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure ValidateQuantityPerOrder()
    var
        BOMComp: Record "BOM Component";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        childItem: Record Item;
        parent: Code[20];
        OrderQuantity: Decimal;
        BomQuantity: Decimal;
    begin
        Initialize;
        OrderQuantity := 5;
        BomQuantity := 1;

        parent := LibraryKitting.CreateStdCostItemWithNewUOM(500, 700, 1);
        childItem.Get(LibraryKitting.CreateItemWithNewUOM(100, 700));
        LibraryManufacturing.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Item, childItem."No.", BomQuantity, childItem."Base Unit of Measure");
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parent, OrderQuantity));

        validateCount(AssemblyHeader."No.", 1);
        AsmLineFindFirst(AssemblyHeader, AssemblyLine);
        ValidateQuantityPer(AssemblyLine, BomQuantity);
        validateQuantityonLines(AssemblyHeader."No.", OrderQuantity * BomQuantity);

        asserterror Error('') // roll back
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure PartiallypostedRefresh()
    var
        AssemblyHeader: Record "Assembly Header";
        BOMComp: Record "BOM Component";
        childItem: Record Item;
        parent: Code[20];
    begin
        Initialize;
        parent := LibraryKitting.CreateStdCostItemWithNewUOM(500, 700, 1);
        childItem.Get(MakeItem);
        LibraryManufacturing.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Item, childItem."No.", 1, childItem."Base Unit of Measure");
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parent, 4));
        validateCount(AssemblyHeader."No.", 1);
        AssemblyHeader."Remaining Quantity (Base)" := 3;
        AssemblyHeader.Validate(Quantity, 2);

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuantityToAssemble()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        Initialize;
        AssemblyHeader.Init;
        AssemblyHeader.Quantity := 10;
        AssemblyHeader."Remaining Quantity" := 2;
        AssemblyHeader."Qty. per Unit of Measure" := 1;
        AssemblyHeader.Validate("Quantity to Assemble", 2);

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuantityToAssembleFail()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        Initialize;
        AssemblyHeader.Init;
        AssemblyHeader.Quantity := 10;
        AssemblyHeader."Remaining Quantity" := 2;
        asserterror AssemblyHeader.Validate("Quantity to Assemble", 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuantityToConsume()
    var
        AssemblyLine: Record "Assembly Line";
    begin
        Initialize;
        AssemblyLine.Init;
        AssemblyLine."Remaining Quantity" := 2;
        AssemblyLine."Qty. per Unit of Measure" := 1;
        AssemblyLine.Validate("Quantity to Consume", 2);

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuantityToConsumeFail()
    var
        AssemblyLine: Record "Assembly Line";
    begin
        Initialize;
        AssemblyLine.Init;
        AssemblyLine."Remaining Quantity" := 2;
        asserterror AssemblyLine.Validate("Quantity to Consume", 3);
    end;

    local procedure CreatePostedAssemblyHeader(var PostedAsmHeader: Record "Posted Assembly Header"; AssemblyHeader: Record "Assembly Header")
    var
        AssemblySetup: Record "Assembly Setup";
        NoSeriesManagement: Codeunit NoSeriesManagement;
        PostedAssemblyNos: Code[20];
    begin
        PostedAssemblyNos := LibraryUtility.GetGlobalNoSeriesCode;
        AssemblySetup.Get;
        if AssemblySetup."Posted Assembly Order Nos." <> PostedAssemblyNos then begin
            AssemblySetup."Posted Assembly Order Nos." := PostedAssemblyNos;
            AssemblySetup.Modify;
        end;

        Clear(PostedAsmHeader);
        PostedAsmHeader."No." := NoSeriesManagement.GetNextNo(PostedAssemblyNos, 0D, true);
        PostedAsmHeader.TransferFields(AssemblyHeader);
        PostedAsmHeader."Order No." := AssemblyHeader."No.";
        PostedAsmHeader.Insert;
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure ChangeQuantity()
    var
        AssemblyHeader: Record "Assembly Header";
        BOMComp: Record "BOM Component";
        childItem: Record Item;
        parent: Code[20];
    begin
        Initialize;
        parent := LibraryKitting.CreateStdCostItemWithNewUOM(500, 700, 1);
        childItem.Get(MakeItem);
        LibraryManufacturing.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Item, childItem."No.", 1, childItem."Base Unit of Measure");
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parent, 1));
        validateCount(AssemblyHeader."No.", 1);
        AssemblyHeader.Validate(Quantity, 2);
        validateCount(AssemblyHeader."No.", 1);
        validateQuantityonLines(AssemblyHeader."No.", 2);

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ZeroQuantity()
    var
        AssemblyHeader: Record "Assembly Header";
        BOMComp: Record "BOM Component";
        childItem: Record Item;
        parent: Code[20];
    begin
        Initialize;
        parent := LibraryKitting.CreateStdCostItemWithNewUOM(500, 700, 1);
        childItem.Get(MakeItem);
        LibraryManufacturing.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Item, childItem."No.", 1, childItem."Base Unit of Measure");
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parent, 0));
        validateCount(AssemblyHeader."No.", 0);

        asserterror Error('') // roll back
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailabilityWindowHandler(var AsmAvailability: Page "Assembly Availability"; var Response: Action)
    begin
        Response := ACTION::Yes; // always confirm
    end;

    local procedure ValidateLineUnitCost(AssemblyLine: Record "Assembly Line"; ExpectedCost: Decimal)
    begin
        Assert.AreEqual(AssemblyLine."Unit Cost", ExpectedCost,
          StrSubstNo('Bad Unit Cost of Assembly Line %1 Expected %2, got %3',
            AssemblyLine."Document No.",
            ExpectedCost,
            AssemblyLine."Unit Cost"));
    end;

    local procedure ValidateOrderUnitCost(AssemblyHeader: Record "Assembly Header"; ExpectedCost: Decimal)
    begin
        Assert.AreEqual(AssemblyHeader."Unit Cost", ExpectedCost,
          StrSubstNo('Bad Unit Cost of Assembly Order %1 Expected %2, got %3',
            AssemblyHeader."No.",
            ExpectedCost,
            AssemblyHeader."Unit Cost"));
    end;

    local procedure ValidateLineResourceTypeUsage(AssemblyLine: Record "Assembly Line"; ExpectedUsageType: Integer)
    var
        Value: Integer;
    begin
        Value := AssemblyLine."Resource Usage Type";
        Assert.AreEqual(Value, ExpectedUsageType,
          StrSubstNo('Bad Resource Usage Type in Assembly line %1 Expected %2 got %3',
            AssemblyLine."Document No.",
            ExpectedUsageType,
            Value));
    end;

    [Normal]
    local procedure validateCount(OrderNo: Code[20]; "Count": Integer)
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, OrderNo);
        Assert.AreEqual(Count, LibraryAssembly.LineCount(AssemblyHeader),
          StrSubstNo(MSGAssertLineCount, OrderNo, Count, LibraryAssembly.LineCount(AssemblyHeader)));
    end;

    [Normal]
    local procedure validateDeleted(AsmHeader: Record "Assembly Header"; "Count": Integer)
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        Assert.IsFalse(AssemblyHeader.Get(AsmHeader."Document Type"::Order, AsmHeader."No."),
          StrSubstNo('Order %1 Existed', AsmHeader."No."));

        Assert.AreEqual(LibraryAssembly.LineCount(AssemblyHeader), Count,
          StrSubstNo(MSGAssertLineCount, AsmHeader."No.", Count, LibraryAssembly.LineCount(AssemblyHeader)))
    end;

    [Normal]
    local procedure validateQuantityonLines(OrderNo: Code[20]; "Count": Integer)
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, OrderNo);
        Assert.AreEqual(Count, LibraryKitting.TotalQuantity(AssemblyHeader),
          StrSubstNo('Bad Line Quantity of Order: %1 expected %2, got %3', OrderNo, Count, LibraryKitting.TotalQuantity(AssemblyHeader)));
    end;

    local procedure ValidateQuantityPer(AsmLine: Record "Assembly Line"; ValidQuantity: Decimal)
    begin
        Assert.AreEqual(ValidQuantity, AsmLine."Quantity per", 'Bad Quantity Per');
    end;

    local procedure ValidateQuantity(AsmLine: Record "Assembly Line"; ValidQuantity: Decimal)
    begin
        Assert.AreEqual(AsmLine.Quantity, ValidQuantity,
          StrSubstNo('Bad Quantity : expected %1 got %2', ValidQuantity, AsmLine.Quantity))
    end;

    local procedure ValidateQuantityToConsume(AsmLine: Record "Assembly Line"; Expected: Decimal)
    begin
        Assert.AreEqual(AsmLine."Quantity to Consume", Expected,
          StrSubstNo('Bad Quantity to Consume: expected %1 got %2', Expected, AsmLine."Quantity to Consume"))
    end;

    local procedure ValidateTotalQuantityToConsume(AsmHeader: Record "Assembly Header"; Expected: Decimal)
    var
        Actual: Decimal;
    begin
        Actual := TotalToConsume(AsmHeader);
        Assert.AreEqual(Expected, Actual,
          StrSubstNo('Bad Total Quantity to Consume: expected %1 got %2', Expected, Actual))
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmItemChange(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    local procedure TotalToConsume(AsmHeader: Record "Assembly Header"): Decimal
    var
        AsmLine: Record "Assembly Line";
        TempCount: Decimal;
    begin
        LibraryAssembly.SetLinkToLines(AsmHeader, AsmLine);
        TempCount := 0;
        if AsmLine.FindSet then
            repeat
                TempCount += AsmLine."Quantity to Consume";
            until AsmLine.Next <= 0;
        exit(TempCount);
    end;

    local procedure MakeItem(): Code[20]
    begin
        exit(LibraryKitting.CreateItemWithLotAndNewUOM(500, 700, 1));
    end;

    local procedure MakeItemWithLot(): Code[20]
    begin
        exit(LibraryKitting.CreateItemWithLotAndNewUOM(500, 700, 1));
    end;

    local procedure AsmLineFindFirst(AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line")
    begin
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.FindFirst;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSTF289825()
    var
        Item: Record Item;
        AsmLine: Record "Assembly Line";
    begin
        // SETUP
        Initialize;
        LibraryInventory.CreateItem(Item);

        // Create a blank asm line with Type blank to trigger the code
        AsmLine.Init;
        AsmLine.Type := AsmLine.Type::" ";

        // EXERCISE
        asserterror AsmLine.Validate("Quantity per", 1);

        // VERIFY
        Assert.IsTrue(StrPos(GetLastErrorText, TXTQtyPerNoChange) > 0, GetLastErrorText);
        ClearLastError;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSTF294294()
    var
        Item: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        AsmHeader: Record "Assembly Header";
        WhseEntry: Record "Warehouse Entry";
        WhseEntry2: Record "Warehouse Entry";
        PostedAsmHeader: Record "Posted Assembly Header";
        UndoPostingManagement: Codeunit "Undo Posting Management";
    begin
        // SETUP
        Initialize;
        LibraryInventory.CreateItem(Item);

        LibraryWarehouse.CreateLocation(Location);
        Location."Bin Mandatory" := true;
        Location.Modify;

        LibraryWarehouse.CreateBin(Bin, Location.Code, '', '', '');
        Bin.Validate(Dedicated, true);
        Bin.Modify;

        LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', Bin.Code, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Dedicated := Bin.Dedicated;
        BinContent.Modify;

        // Simulate posting
        LibraryAssembly.CreateAssemblyHeader(AsmHeader, WorkDate, Item."No.", Location.Code, LibraryRandom.RandInt(10), '');
        AsmHeader."Bin Code" := Bin.Code;

        WhseEntry2.FindLast;
        WhseEntry.Init;
        WhseEntry."Entry No." := WhseEntry2."Entry No." + 1;
        WhseEntry."Source Type" := DATABASE::"Assembly Header";
        WhseEntry."Source Subtype" := AsmHeader."Document Type";
        WhseEntry."Source No." := AsmHeader."No.";
        WhseEntry."Source Line No." := 0;
        WhseEntry."Location Code" := AsmHeader."Location Code";
        WhseEntry."Item No." := AsmHeader."Item No.";
        WhseEntry."Unit of Measure Code" := AsmHeader."Unit of Measure Code";
        WhseEntry."Bin Code" := AsmHeader."Bin Code";
        WhseEntry."Qty. (Base)" := AsmHeader."Quantity (Base)";
        WhseEntry.Insert;

        CreatePostedAssemblyHeader(PostedAsmHeader, AsmHeader);

        // EXERCISE
        UndoPostingManagement.TestAsmHeader(PostedAsmHeader);

        // VERIFY
        // no error has occured

        asserterror Error('') // roll back
    end;
}

