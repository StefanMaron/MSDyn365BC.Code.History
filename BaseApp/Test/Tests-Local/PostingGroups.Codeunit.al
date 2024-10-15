codeunit 145004 "Posting Groups"
{
    Subtype = Test;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        isInitialized: Boolean;
        ChangeCustPostGrErr: Label 'Customer Posting Group  cannot be changed in Customer No.=''%1''.', Comment = '%1=Customer No.';
        ChangeVendPostGrErr: Label 'Vendor Posting Group  cannot be changed in Vendor No.=''%1''.', Comment = '%1=Vendor No.';
        ChangeRecAccountQst: Label 'Do you really want to change %1 although open entries exist?', Comment = '%1=FIELDCAPTION';
        UnexpectedDialogErr: Label 'Unexpected dialog.';

    local procedure Initialize()
    begin
        LibraryRandom.SetSeed(1);  // Use Random Number Generator to generate the seed for RANDOM function.
        LibraryVariableStorage.Clear;

        if isInitialized then
            exit;

        isInitialized := true;
        Commit;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangePostingGroupOnCustomerWithoutEntries()
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        // 1. Setup
        Initialize;

        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);

        // 2. Exercise
        Customer.Validate("Customer Posting Group", CustomerPostingGroup.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangePostingGroupOnCustomerWithOpenEntries()
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        // 1. Setup
        Initialize;

        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);
        CreateCustomerLedgerEnty(Customer);

        // 2. Exercise
        asserterror Customer.Validate("Customer Posting Group", CustomerPostingGroup.Code);

        // 3. Verify
        Assert.ExpectedError(StrSubstNo(ChangeCustPostGrErr, Customer."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangePostingGroupOnVendorWithoutEntries()
    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        // 1. Setup
        Initialize;

        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroup);

        // 2. Exercise
        Vendor.Validate("Vendor Posting Group", VendorPostingGroup.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangePostingGroupOnVendorWithOpenEntries()
    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        // 1. Setup
        Initialize;

        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroup);
        CreateVendorLedgerEnty(Vendor);

        // 2. Exercise
        asserterror Vendor.Validate("Vendor Posting Group", VendorPostingGroup.Code);

        // 3. Verify
        Assert.ExpectedError(StrSubstNo(ChangeVendPostGrErr, Vendor."No."));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ChangeReceivablesAccountOnCustomerPostingGroup()
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        // 1. Setup
        Initialize;

        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Customer Posting Group", CustomerPostingGroup.Code);
        Customer.Modify;
        CreateCustomerLedgerEnty(Customer);

        // 2. Exercise
        LibraryVariableStorage.Enqueue(ChangeRecAccountQst);
        CustomerPostingGroup.Validate("Receivables Account", LibraryERM.CreateGLAccountNo);

        // 3. Verify in Confirm Handler
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ChangeReceivablesAccountOnVendorPostingGroup()
    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        // 1. Setup
        Initialize;

        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroup);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Vendor Posting Group", VendorPostingGroup.Code);
        Vendor.Modify;
        CreateVendorLedgerEnty(Vendor);

        // 2. Exercise
        LibraryVariableStorage.Enqueue(ChangeRecAccountQst);
        VendorPostingGroup.Validate("Payables Account", LibraryERM.CreateGLAccountNo);

        // 3. Verify in Confirm Handler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddingDefGenBusPostGroupsForTransferOrder()
    var
        TransferHeader: Record "Transfer Header";
        TransferRoute: Record "Transfer Route";
    begin
        // 1. Setup
        Initialize;

        CreateAndModifyTransferRoute(TransferRoute);

        // 2. Exercise
        LibraryWarehouse.CreateTransferHeader(TransferHeader, TransferRoute."Transfer-from Code", TransferRoute."Transfer-to Code", '');

        // 3. Verify
        TransferHeader.TestField("Gen. Bus. Post. Group Receive", TransferRoute."Gen. Bus. Post. Group Receive");
        TransferHeader.TestField("Gen. Bus. Post. Group Ship", TransferRoute."Gen. Bus. Post. Group Ship");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddingDefGenBusPostGroupsForItemJnlTemplate()
    var
        ItemJnlLine: Record "Item Journal Line";
        WhseNetChangeTemplate: Record "Whse. Net Change Template";
    begin
        // 1. Setup
        Initialize;

        CreateWhseNetChangeTemplate(WhseNetChangeTemplate);
        CreateItemJnlLine(ItemJnlLine);

        // 2. Exercise
        ItemJnlLine.Validate("Whse. Net Change Template", WhseNetChangeTemplate.Name);

        // 3. Verify
        ItemJnlLine.TestField("Entry Type", WhseNetChangeTemplate."Entry Type");
        ItemJnlLine.TestField("Gen. Bus. Posting Group", WhseNetChangeTemplate."Gen. Bus. Posting Group");
    end;

    local procedure CreateAndModifyTransferRoute(var TransferRoute: Record "Transfer Route")
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        Location: Record Location;
        InTransitLocation: Record Location;
        ShippingAgent: Record "Shipping Agent";
        ShippingAgentServices: Record "Shipping Agent Services";
        ShippingTime: DateFormula;
    begin
        LibraryWarehouse.CreateLocation(Location);
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        LibraryInventory.CreateShippingAgent(ShippingAgent);
        Evaluate(ShippingTime, '<' + Format(LibraryRandom.RandInt(5)) + 'D>');  // Use Random value for Shipping Time.
        LibraryInventory.CreateShippingAgentService(ShippingAgentServices, ShippingAgent.Code, ShippingTime);
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        LibraryWarehouse.CreateAndUpdateTransferRoute(
          TransferRoute, Location.Code, GetFirstLocation(false), InTransitLocation.Code, ShippingAgent.Code, ShippingAgentServices.Code);
        TransferRoute.Validate("Gen. Bus. Post. Group Receive", GenBusinessPostingGroup.Code);
        TransferRoute.Validate("Gen. Bus. Post. Group Ship", GenBusinessPostingGroup.Code);
        TransferRoute.Modify;
    end;

    local procedure CreateCustomerLedgerEnty(Customer: Record Customer)
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLn: Record "Gen. Journal Line";
    begin
        LibraryERM.SelectGenJnlBatch(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJnlLn, GenJnlBatch."Journal Template Name", GenJnlBatch.Name, 0,
          GenJnlLn."Account Type"::Customer, Customer."No.",
          LibraryRandom.RandDec(1000, 2));
        LibraryERM.PostGeneralJnlLine(GenJnlLn);
    end;

    local procedure CreateItemJnlLine(var ItemJnlLine: Record "Item Journal Line")
    var
        Item: Record Item;
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.CreateItemJournalTemplate(ItemJnlTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJnlBatch, ItemJnlTemplate.Name);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemJournalLine(
          ItemJnlLine, ItemJnlBatch."Journal Template Name", ItemJnlBatch.Name, 0, Item."No.", 1);
    end;

    local procedure CreateVendorLedgerEnty(Vendor: Record Vendor)
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLn: Record "Gen. Journal Line";
    begin
        LibraryERM.SelectGenJnlBatch(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJnlLn, GenJnlBatch."Journal Template Name", GenJnlBatch.Name, 0,
          GenJnlLn."Account Type"::Vendor, Vendor."No.",
          LibraryRandom.RandDec(1000, 2));
        LibraryERM.PostGeneralJnlLine(GenJnlLn);
    end;

    local procedure CreateWhseNetChangeTemplate(var WhseNetChangeTemplate: Record "Whse. Net Change Template")
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
    begin
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        LibraryWarehouse.CreateWhseNetChangeTemplate(WhseNetChangeTemplate, GenBusinessPostingGroup.Code);
        WhseNetChangeTemplate.Validate("Entry Type", WhseNetChangeTemplate."Entry Type"::"Negative Adjmt.");
        WhseNetChangeTemplate.Modify;
    end;

    local procedure GetFirstLocation(UseAsInTransit: Boolean): Code[10]
    var
        Location: Record Location;
    begin
        if not Location.Get('A') then begin
            Location.Init;
            Location.Validate(Code, 'A');
            Location.Validate(Name, 'A');
            Location.Insert(true);
            LibraryInventory.UpdateInventoryPostingSetup(Location);
        end;

        Location.Validate("Use As In-Transit", UseAsInTransit);
        Location.Modify(true);

        exit(Location.Code);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    var
        ExpectedQuestion: Text;
    begin
        ExpectedQuestion := LibraryVariableStorage.DequeueText;
        Assert.AreEqual(ExpectedQuestion, Question, UnexpectedDialogErr);
        Reply := true;
    end;
}

