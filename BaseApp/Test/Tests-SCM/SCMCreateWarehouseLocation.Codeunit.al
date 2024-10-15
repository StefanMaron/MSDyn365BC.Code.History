codeunit 137220 "SCM CreateWarehouseLocation"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Warehouse] [Location] [SCM]
        IsInitialized := false;
    end;

    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        IsInitialized: Boolean;
        UnexpectedMessage: Label 'Unexpected : "%1". Expected: "%2"';
        ErrEnterLocationCode: Label 'Enter a location code.';
        ErrEnterAdjCode: Label 'Enter an adjustment bin code.';
        ErrNoActiveKey: Label 'The Item Ledger Entry table does not have an active key that starts with the following field or fields: Item No.,Location Code,Open,Variant Code,Unit of Measure Code,Lot No.,Serial No..';
        ErrNothingToConvert: Label 'There is nothing to convert for Location Code ''%1''';
        ErrBinDoesNotExist: Label 'The Bin does not exist';

    local procedure Initialize()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM CreateWarehouseLocation");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM CreateWarehouseLocation");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        ItemJournalSetup(ItemJournalTemplate, ItemJournalBatch);

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Stockout Warning", false);
        SalesReceivablesSetup.Modify(true);

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM CreateWarehouseLocation");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RP5756EmptyLocEmptyBin()
    begin
        Initialize();

        ConvertLocationWithErrorTest('', '', ErrEnterLocationCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RP5756EmptyLocNotExistBin()
    var
        Bin: Record Bin;
        NotExistingBinCode: Code[20];
    begin
        Initialize();
        NotExistingBinCode := CopyStr(LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin),
            1, LibraryUtility.GetFieldLength(DATABASE::Bin, Bin.FieldNo(Code)));

        ConvertLocationWithErrorTest('', NotExistingBinCode, ErrEnterLocationCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RP5756EmptyLocExistBin()
    var
        Bin: Record Bin;
        Location: Record Location;
    begin
        Initialize();
        CreateLocationAndBin(Location, Bin);

        ConvertLocationWithErrorTest('', Bin.Code, ErrEnterLocationCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RP5756ExistLocEmptyBin()
    var
        Bin: Record Bin;
        Location: Record Location;
    begin
        Initialize();
        CreateLocationAndBin(Location, Bin);

        ConvertLocationWithErrorTest(Location.Code, '', ErrEnterAdjCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RP5756ExistLocNotExistBin()
    var
        Bin: Record Bin;
        Location: Record Location;
        ItemLedgEntry: Record "Item Ledger Entry";
        NotExistingBinCode: Code[20];
    begin
        Initialize();
        NotExistingBinCode := CopyStr(LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin),
            1, LibraryUtility.GetFieldLength(DATABASE::Bin, Bin.FieldNo(Code)));
        CreateLocationAndBin(Location, Bin);

        ItemLedgEntry.FindFirst();
        if ItemLedgEntry.SetCurrentKey("Item No.", "Location Code", Open, "Variant Code", "Unit of Measure Code", "Lot No.", "Serial No.") then
            ConvertLocationWithErrorTest(Location.Code, NotExistingBinCode, ErrBinDoesNotExist)
        else
            ConvertLocationWithErrorTest(Location.Code, NotExistingBinCode, ErrNoActiveKey);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RP5756ExistLocExistBin()
    var
        Bin: Record Bin;
        Location: Record Location;
        ItemLedgEntry: Record "Item Ledger Entry";
        CreateWarehouseLocation: Report "Create Warehouse Location";
    begin
        Initialize();
        CreateLocationAndBin(Location, Bin);

        ItemLedgEntry.FindFirst();
        if ItemLedgEntry.SetCurrentKey("Item No.", "Location Code", Open, "Variant Code", "Unit of Measure Code", "Lot No.", "Serial No.") then begin
            Clear(CreateWarehouseLocation);
            CreateWarehouseLocation.SetHideValidationDialog(true);
            CreateWarehouseLocation.InitializeRequest(Location.Code, Bin.Code);

            CreateWarehouseLocation.UseRequestPage(false);
            CreateWarehouseLocation.RunModal();

            Commit();  // commit is required
            Location.Get(Location.Code);
            Assert.AreEqual(true, Location."Require Receive", 'Incorrect require receive flag');
            Assert.AreEqual(true, Location."Require Shipment", 'Incorrect require receive shipment flag');
            Assert.AreEqual(true, Location."Require Put-away", 'Incorrect require put-away flag');
            Assert.AreEqual(false, Location."Use Put-away Worksheet", 'Incorrect use put-away worksheet flag');
            Assert.AreEqual(true, Location."Require Pick", 'Incorrect require pick flag');
            Assert.AreEqual(true, Location."Bin Mandatory", 'Incorrect Bin Mandatory flag');
            Assert.AreEqual(true, Location."Directed Put-away and Pick", 'Incorrect Directed Put-away and Pick flag');
        end else
            ConvertLocationWithErrorTest(Location.Code, Bin.Code, ErrNoActiveKey);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RP5756NonExistLocEmptyBin()
    var
        Location: Record Location;
        NotExistingLocationCode: Code[10];
    begin
        Initialize();
        NotExistingLocationCode := CopyStr(LibraryUtility.GenerateRandomCode(Location.FieldNo(Code), DATABASE::Location),
            1, LibraryUtility.GetFieldLength(DATABASE::Location, Location.FieldNo(Code)));

        ConvertLocationWithErrorTest(NotExistingLocationCode, '', ErrEnterAdjCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RP5756NonExistLocNonExistBin()
    var
        Bin: Record Bin;
        Location: Record Location;
        NotExistingBinCode: Code[20];
        NotExistingLocationCode: Code[10];
    begin
        Initialize();
        NotExistingBinCode := CopyStr(LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin),
            1, LibraryUtility.GetFieldLength(DATABASE::Bin, Bin.FieldNo(Code)));

        NotExistingLocationCode := CopyStr(LibraryUtility.GenerateRandomCode(Location.FieldNo(Code), DATABASE::Location),
            1, LibraryUtility.GetFieldLength(DATABASE::Location, Location.FieldNo(Code)));

        ConvertLocationWithErrorTest(NotExistingLocationCode, NotExistingBinCode, StrSubstNo(ErrNothingToConvert, NotExistingLocationCode));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RP5756NonExistLocExistBin()
    var
        Bin: Record Bin;
        Location: Record Location;
        NotExistingLocationCode: Code[10];
    begin
        Initialize();
        NotExistingLocationCode := CopyStr(LibraryUtility.GenerateRandomCode(Location.FieldNo(Code), DATABASE::Location),
            1, LibraryUtility.GetFieldLength(DATABASE::Location, Location.FieldNo(Code)));

        CreateLocationAndBin(Location, Bin);

        ConvertLocationWithErrorTest(NotExistingLocationCode, Bin.Code, StrSubstNo(ErrNothingToConvert, NotExistingLocationCode));
    end;

    local procedure ConvertLocationWithErrorTest(LocationCode: Code[10]; BinCode: Code[20]; ExpectedErrorMessage: Text[1024])
    var
        CreateWarehouseLocation: Report "Create Warehouse Location";
    begin
        Clear(CreateWarehouseLocation);
        CreateWarehouseLocation.SetHideValidationDialog(true);
        CreateWarehouseLocation.InitializeRequest(LocationCode, BinCode);

        CreateWarehouseLocation.UseRequestPage(false);
        Commit();
        asserterror CreateWarehouseLocation.RunModal();
        if StrPos(GetLastErrorText, ExpectedErrorMessage) = 0 then
            Assert.Fail(StrSubstNo(UnexpectedMessage, GetLastErrorText, ExpectedErrorMessage));
        ClearLastError();
        Clear(CreateWarehouseLocation);
    end;

    local procedure CreateLocationAndBin(var Location: Record Location; var Bin: Record Bin)
    var
        Item: Record Item;
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        LibraryWarehouse.CreateBin
        (Bin,
          Location.Code,
          CopyStr
          (
            LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin)
            , 1, LibraryUtility.GetFieldLength(DATABASE::Bin, Bin.FieldNo(Code))),
          '', '');

        LibraryInventory.CreateItem(Item);
        AddInventoryNonDirectLocation(Item, Location.Code);
    end;

    [Normal]
    local procedure ItemJournalSetup(var ItemJournalTemplate: Record "Item Journal Template"; var ItemJournalBatch: Record "Item Journal Batch")
    begin
        Clear(ItemJournalTemplate);
        ItemJournalTemplate.Init();
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        ItemJournalTemplate.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalTemplate.Modify(true);

        Clear(ItemJournalBatch);
        ItemJournalBatch.Init();
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch.Modify(true);
    end;

    local procedure AddInventoryNonDirectLocation(Item: Record Item; LocationCode: Code[10])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LibraryRandom.RandInt(10));
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;
}

