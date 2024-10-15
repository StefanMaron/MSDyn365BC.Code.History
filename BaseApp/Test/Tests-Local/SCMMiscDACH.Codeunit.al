codeunit 142083 "SCM Misc. DACH"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        WarehouseEmployee: Record "Warehouse Employee";
        LocationGreen: Record Location;
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('CalculateInventoryItemsNotOnInventoryHandler')]
    [Scope('OnPrem')]
    procedure ItemWithNoTransactionInCalcInventoryReport()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        PhysInvJournal: TestPage "Phys. Inventory Journal";
    begin
        // [FEATURE] [Phys. Inventory Journal] [Calculate Inventory]
        // [SCENARIO 272317] Calculate Inventory report must omit items with no entries in Item Ledger Entry when "Include Item without Transactions" flag is down even if "Items Not on Inventory" flag is up

        Initialize;

        // [GIVEN] Create a new item
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Clear up Phys. Inventory Journal
        ItemJournalLine.DeleteAll();

        // [WHEN] Invoke Calculate Inventory button on Phys. Inventory Journal page ("Items Not on Inventory" flag is up while "Include Item without Transactions" flag is down)
        Commit();
        LibraryVariableStorage.Enqueue(Item."No.");
        PhysInvJournal.OpenEdit;
        PhysInvJournal.CalculateInventory.Invoke;

        // [THEN] Report dataset doesn't contain Item with no transactions
        Assert.RecordIsEmpty(ItemJournalLine);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear;
        LibrarySetupStorage.Restore;

        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup;
        LocationGreen.Get(CreateLocation(true, true, true, true));
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationGreen.Code, true);

        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");

        IsInitialized := true;
        Commit();
    end;

    local procedure CreateLocation(SetRequireReceive: Boolean; SetRequirePutAway: Boolean; SetRequireShipment: Boolean; SetRequirePick: Boolean): Code[10]
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        with Location do begin
            Validate("Require Receive", SetRequireReceive);
            Validate("Require Put-away", SetRequirePutAway);
            Validate("Require Shipment", SetRequireShipment);
            Validate("Require Pick", SetRequirePick);
            Modify(true);
            exit(Code);
        end;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalculateInventoryItemsNotOnInventoryHandler(var CalculateInventory: TestRequestPage "Calculate Inventory")
    begin
        CalculateInventory.Item.SetFilter("No.", LibraryVariableStorage.DequeueText);
        CalculateInventory.ItemsNotOnInventory.SetValue(true);
        CalculateInventory.IncludeItemWithNoTransaction.SetValue(false);
        CalculateInventory.OK.Invoke;
    end;
}

