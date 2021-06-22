codeunit 137120 "Non-inventory Item Costing"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Item] [Non-Inventory]
        isInitialized := false;
    end;

    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
        Assert: Codeunit Assert;
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPatterns: Codeunit "Library - Patterns";
        LibraryService: Codeunit "Library - Service";
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure TestAssemblyOrderWithNonInventoryItem()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        AssemblyLineNonInventory: Record "Assembly Line";
        Item: Record Item;
        ItemNonInventory: Record Item;
    begin
        Initialize;

        // Use False for Update Unit Cost and blank for Variant Code.
        LibraryAssembly.SetupAssemblyItem(
          Item, Item."Costing Method"::Standard, Item."Costing Method"::Standard, Item."Replenishment System"::Assembly, '', false,
          LibraryRandom.RandInt(5), LibraryRandom.RandInt(5),
          LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));

        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, CalcDate('<+14D>', WorkDate), Item."No.", '', LibraryRandom.RandInt(10), '');

        LibraryInventory.CreateNonInventoryTypeItem(ItemNonInventory);
        ItemNonInventory.Validate("Unit Cost", 15);
        ItemNonInventory.Modify(true);

        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Validate("Standard Cost", 10);
        Item.Validate(Inventory, 10000);
        Item.Modify(true);

        LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine, AssemblyLine.Type::Item, Item."No.",
          LibraryAssembly.GetUnitOfMeasureCode(AssemblyLine.Type::Item, Item."No.", true),
          1, 1, '');
        AssemblyLine.Validate(Quantity, 1);
        AssemblyLine.Modify;

        LibraryAssembly.CreateAssemblyLine(
          AssemblyHeader, AssemblyLineNonInventory, AssemblyLineNonInventory.Type::Item, ItemNonInventory."No.",
          LibraryAssembly.GetUnitOfMeasureCode(AssemblyLineNonInventory.Type::Item, ItemNonInventory."No.", true),
          1, 1, '');
        AssemblyLineNonInventory.Validate(Quantity, 1);
        AssemblyLineNonInventory.Modify;

        LibraryAssembly.AddCompInventory(AssemblyHeader, WorkDate, 1);

        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        VerifyEntries(Item, ItemNonInventory, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestProductionOrderWithNonInventoryItem()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionItem: Record Item;
        Item: Record Item;
        ItemNonInventory: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemLedgerEntry: Record "Item Ledger Entry";
        LocationBlue: Record Location;
    begin
        Initialize;
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationBlue);
        LibraryInventory.CreateItem(ProductionItem);

        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ProductionItem."No.", 2);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst;
        LibraryManufacturing.CreateProductionOrderComponent(
          ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.", ProdOrderLine."Line No.");
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Validate("Standard Cost", 10);
        Item.Validate(Inventory, 10000);
        Item.Modify(true);
        LibraryPatterns.POSTItemJournalLineWithApplication(
          ItemJournalBatch."Template Type"::Item, ItemLedgerEntry."Entry Type"::"Positive Adjmt.", Item, '', '',
          10, WorkDate, 0, ItemLedgerEntry."Entry No.");

        ProdOrderComponent.Validate("Item No.", Item."No.");
        ProdOrderComponent.Validate("Quantity per", 1);
        ProdOrderComponent.Modify(true);

        LibraryManufacturing.CreateProductionOrderComponent(
          ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.", ProdOrderLine."Line No.");
        LibraryInventory.CreateNonInventoryTypeItem(ItemNonInventory);
        ItemNonInventory.Validate("Unit Cost", 15);
        ItemNonInventory.Modify(true);
        ProdOrderComponent.Validate("Item No.", ItemNonInventory."No.");
        ProdOrderComponent.Validate("Quantity per", 1);
        ProdOrderComponent.Modify(true);

        LibraryPatterns.POSTConsumption(ProdOrderLine, Item, '', '', 1, WorkDate, Item."Standard Cost");
        LibraryPatterns.POSTConsumption(ProdOrderLine, ItemNonInventory, '', '', 1, WorkDate, ItemNonInventory."Unit Cost");

        VerifyEntries(Item, ItemNonInventory, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestServiceOrderWithNonInventoryItem()
    var
        Item: Record Item;
        ItemNonInventory: Record Item;
        ServiceItem: Record "Service Item";
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        Initialize;
        CreateItemWithAmounts(Item);
        Item.Validate("Service Item Group", CreateServiceItemGroup);
        Item.Modify(true);

        CreateNonInventoryItemWithAmounts(ItemNonInventory);
        ItemNonInventory.Validate("Service Item Group", CreateServiceItemGroup);
        ItemNonInventory.Modify(true);

        LibrarySales.CreateCustomer(Customer);

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        LibraryService.CreateServiceLineWithQuantity(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.", 1);
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate("Qty. to Consume", 1);
        ServiceLine.Modify;

        LibraryService.CreateServiceLineWithQuantity(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNonInventory."No.", 1);
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate("Qty. to Consume", 1);
        ServiceLine.Modify;

        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        VerifyEntries(Item, ItemNonInventory, 2);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Non-inventory Item Costing");
        LibrarySetupStorage.Restore;

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Non-inventory Item Costing");

        UpdateStockOutWarningOnAssemblySetup(false);
        LibraryERMCountryData.CreateVATData;
        LibraryERMCountryData.CreateGeneralPostingSetupData;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        LibraryERMCountryData.UpdateSalesReceivablesSetup;
        Setup;
        LibraryAssembly.SetupItemJournal(ItemJournalTemplate, ItemJournalBatch);
        ItemJournalTemplate.Type := ItemJournalTemplate.Type::Consumption;
        ItemJournalTemplate.Recurring := false;
        ItemJournalTemplate.Modify;

        LibraryService.SetupServiceMgtNoSeries;

        isInitialized := true;
        Commit;

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");
        LibrarySetupStorage.Save(DATABASE::"Assembly Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Non-inventory Item Costing");
    end;

    local procedure UpdateStockOutWarningOnAssemblySetup(NewStockOutWarning: Boolean)
    var
        AssemblySetup: Record "Assembly Setup";
    begin
        AssemblySetup.Get;
        AssemblySetup.Validate("Stockout Warning", NewStockOutWarning);
        AssemblySetup.Modify(true);
    end;

    local procedure Setup()
    var
        AssemblySetup: Record "Assembly Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        AssemblySetup.Get;
        AssemblySetup.Validate("Assembly Order Nos.", LibraryUtility.GetGlobalNoSeriesCode);
        AssemblySetup.Validate("Posted Assembly Order Nos.", LibraryUtility.GetGlobalNoSeriesCode);
        AssemblySetup.Modify(true);

        SalesSetup.Get;
        SalesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode);
        SalesSetup.Modify(true);

        ManufacturingSetup.Get;
        ManufacturingSetup.Validate("Released Order Nos.", LibraryUtility.GetGlobalNoSeriesCode);
        ManufacturingSetup.Validate("Normal Starting Time", 080000T);
        ManufacturingSetup.Validate("Normal Ending Time", 160000T);
        ManufacturingSetup.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateItemWithAmounts(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Validate("Standard Cost", 10);
        Item.Validate(Inventory, 10000);
        Item.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateNonInventoryItemWithAmounts(var ItemNonInventory: Record Item)
    begin
        LibraryInventory.CreateNonInventoryTypeItem(ItemNonInventory);
        ItemNonInventory.Validate("Unit Cost", 15);
        ItemNonInventory.Modify(true);
    end;

    local procedure CreateServiceItemGroup() ServiceItemGroupCode: Code[10]
    var
        ServiceItemGroup: Record "Service Item Group";
        ServiceItemGroups: TestPage "Service Item Groups";
    begin
        ServiceItemGroups.OpenEdit;
        ServiceItemGroups.New;
        ServiceItemGroupCode :=
          LibraryUtility.GenerateRandomCodeWithLength(
            ServiceItemGroup.FieldNo(Code), DATABASE::"Service Item Group", MaxStrLen(ServiceItemGroup.Code));
        ServiceItemGroups.Code.SetValue(ServiceItemGroupCode);
        ServiceItemGroups."Default Response Time (Hours)".SetValue(LibraryRandom.RandInt(10));
        ServiceItemGroups."Create Service Item".SetValue(true);
        ServiceItemGroups.OK.Invoke;
        Commit;
    end;

    [Scope('OnPrem')]
    procedure VerifyEntries(Item: Record Item; ItemNonInventory: Record Item; Type: Option Assembly,Production,Service)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        case Type of
            Type::Assembly:
                ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Assembly Consumption");
            Type::Production:
                ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Consumption);
            Type::Service:
                ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Negative Adjmt.");
        end;
        ItemLedgerEntry.FindFirst;
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        Assert.AreEqual(-Item."Standard Cost", ItemLedgerEntry."Cost Amount (Actual)", '');

        ItemLedgerEntry.SetRange("Item No.", ItemNonInventory."No.");
        ItemLedgerEntry.FindFirst;
        ItemLedgerEntry.CalcFields("Cost Amount (Non-Invtbl.)");
        Assert.AreEqual(-ItemNonInventory."Unit Cost", ItemLedgerEntry."Cost Amount (Non-Invtbl.)", '');

        ValueEntry.SetRange("Item No.", Item."No.");
        case Type of
            Type::Assembly:
                ValueEntry.SetRange("Item Ledger Entry Type", ItemLedgerEntry."Entry Type"::"Assembly Consumption");
            Type::Production:
                ValueEntry.SetRange("Item Ledger Entry Type", ItemLedgerEntry."Entry Type"::Consumption);
            Type::Service:
                ValueEntry.SetRange("Item Ledger Entry Type", ItemLedgerEntry."Entry Type"::"Negative Adjmt.");
        end;
        ValueEntry.FindFirst;
        Assert.AreEqual(-Item."Standard Cost", ValueEntry."Cost Amount (Actual)", '');

        ValueEntry.SetRange("Item No.", ItemNonInventory."No.");
        ValueEntry.FindFirst;
        Assert.AreEqual(-ItemNonInventory."Unit Cost", ItemLedgerEntry."Cost Amount (Non-Invtbl.)", '');
    end;
}

