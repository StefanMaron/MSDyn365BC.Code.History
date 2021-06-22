codeunit 133783 "Booking Sync UI Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Bookings]
    end;

    var
        BookingSync: Record "Booking Sync";
        ExchangeSync: Record "Exchange Sync";
        ExchangeContact: Record "Exchange Contact";
        BookingService: Record "Booking Service";
        O365SyncManagement: Codeunit "O365 Sync. Management";
        LibraryO365Sync: Codeunit "Library - O365 Sync";
        Assert: Codeunit Assert;
        CustomerFilterTxt: Label 'SORTING(No.) WHERE(Location Code=FILTER(GREEN))';
        ItemFilterTxt: Label 'SORTING(No.) WHERE(Gen. Prod. Posting Group=FILTER(SERVICES))';
        NavCustomerCount: Integer;
        NavItemCount: Integer;

    [Test]
    [HandlerFunctions('ConfirmHandler,BookingSyncHandler')]
    [Scope('OnPrem')]
    procedure TestBookingsSyncSetupOpens()
    var
        ExchangeSyncSetup: TestPage "Exchange Sync. Setup";
    begin
        // [SCENARIO] Bookings Sync Setup is click
        Initialize;

        // [GIVEN] ExhangeSyncSetup form
        ExchangeSyncSetup.Trap;
        PAGE.Run(PAGE::"Exchange Sync. Setup", ExchangeSync);

        // [WHEN] Bookings Sync Setup is clicked
        ExchangeSyncSetup.SetupBookingSync.Invoke;

        // [THEN] Bookings Sync Setup page is opened
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ContactSyncHandler')]
    [Scope('OnPrem')]
    procedure TestContactSyncSetupOpens()
    var
        ExchangeSyncSetup: TestPage "Exchange Sync. Setup";
    begin
        // [SCENARIO] Contact Sync Setup is click
        Initialize;

        // [GIVEN] ExhangeSyncSetup form
        ExchangeSyncSetup.Trap;
        PAGE.Run(PAGE::"Exchange Sync. Setup", ExchangeSync);

        // [WHEN] Contact Sync Setup is clicked
        ExchangeSyncSetup.SetupContactSync.Invoke;

        // [THEN] Contact Sync Setup page is opened
    end;

    [Test]
    [HandlerFunctions('ItemFilterHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestSaveServiceFilter()
    var
        BookingSyncSetup: TestPage "Booking Sync. Setup";
    begin
        // [SCENARIO] Set Service Filter is clicked
        Initialize;

        // [GIVEN] BookingSyncSetup form
        BookingSyncSetup.Trap;
        PAGE.Run(PAGE::"Booking Sync. Setup", BookingSync);

        // [WHEN] User clicks Set Service Sync Filter
        BookingSyncSetup.SetServiceSyncFilter.Invoke;

        Assert.AreEqual(ItemFilterTxt, BookingSync.GetItemFilter, 'Item Filter is not saved');
    end;

    [Test]
    [HandlerFunctions('CustomerFilterHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestSaveCustomerFilter()
    var
        BookingSyncSetup: TestPage "Booking Sync. Setup";
    begin
        // [SCENARIO] Set Customer Filter is clicked
        Initialize;

        // [GIVEN] BookingSyncSetup form
        BookingSyncSetup.Trap;
        PAGE.Run(PAGE::"Booking Sync. Setup", BookingSync);

        // [WHEN] User clicks Set Customer Sync Filter
        BookingSyncSetup.SetCustomerSyncFilter.Invoke;

        Assert.AreEqual(CustomerFilterTxt, BookingSync.GetCustomerFilter, 'Customer Filter is not saved');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestSaveTemplates()
    var
        BookingSyncSetup: TestPage "Booking Sync. Setup";
    begin
        // [SCENARIO] Selected Customer and Item Default templates are saved
        Initialize;

        // [GIVEN] BookingSyncSetup form
        BookingSyncSetup.Trap;
        PAGE.Run(PAGE::"Booking Sync. Setup", BookingSync);

        // [THEN] Customer template is blank
        Assert.AreEqual('', BookingSyncSetup."Customer Template Code".Value, 'Customer template is not blank');

        // [THEN] Item template is blank
        Assert.AreEqual('', BookingSyncSetup."Item Template Code".Value, 'Item template is not blank');

        // [GIVEN] User sets Customer template
        BookingSyncSetup."Customer Template Code".SetValue('DK-SMALL');

        // [GIVEN] User sets Item template
        BookingSyncSetup."Item Template Code".SetValue('ITEM000001');

        // [GIVEN] User closes and opens the Booking Sync. Setup form
        BookingSyncSetup.Close;
        BookingSyncSetup.Trap;
        PAGE.Run(PAGE::"Booking Sync. Setup", BookingSync);

        // [THEN] Customer template is set to previous value
        Assert.AreEqual('DK-SMALL', BookingSyncSetup."Customer Template Code".Value, 'Customer template is not set correctly');

        // [THEN] Item template is set to previous value
        Assert.AreEqual('ITEM000001', BookingSyncSetup."Item Template Code".Value, 'Item template is not set correctly');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestSyncCustomerOnly()
    var
        BookingSyncSetup: TestPage "Booking Sync. Setup";
    begin
        // [SCENARIO] Only select Customers should be sync
        Initialize;
        SetupForSyncing;

        // [GIVEN] BookingSyncSetup form
        BookingSyncSetup.Trap;
        PAGE.Run(PAGE::"Booking Sync. Setup", BookingSync);

        // [GIVEN] User select to only sync Customers
        BookingSyncSetup."Sync Customers".SetValue(true);
        BookingSyncSetup."Sync Services".SetValue(false);

        // [WHEN] User clicks Sync with Bookings
        BookingSyncSetup.SyncWithBookings.Invoke;

        // [THEN] Only the Customers in the filter should have been sync'd
        Assert.AreEqual(NavCustomerCount, ExchangeContact.Count, 'Exchange contacts count do not match');

        // [THEN] No Items should have sync
        Assert.AreEqual(0, BookingService.Count, 'Booking service items count do not match');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestSyncItemsOnly()
    var
        BookingSyncSetup: TestPage "Booking Sync. Setup";
    begin
        // [SCENARIO] Only selected Items should be sync
        Initialize;
        SetupForSyncing;

        // [GIVEN] BookingSyncSetup form
        BookingSyncSetup.Trap;
        PAGE.Run(PAGE::"Booking Sync. Setup", BookingSync);

        // [GIVEN] User select to only sync Items
        BookingSyncSetup."Sync Customers".SetValue(false);
        BookingSyncSetup."Sync Services".SetValue(true);

        // [WHEN] User clicks Sync with Bookings
        BookingSyncSetup.SyncWithBookings.Invoke;

        // [THEN] No Customers should have sync
        Assert.AreEqual(0, ExchangeContact.Count, 'Exchange contacts count do not match');

        // [THEN] Only Items should have been sync'd
        Assert.AreEqual(NavItemCount, BookingService.Count, 'Booking service items count do not match');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestMailbox()
    var
        BookingSyncSetup: TestPage "Booking Sync. Setup";
    begin
        // [SCENARIO] Only selected Items should be sync
        Initialize;

        BookingSync.Validate("Booking Mailbox Address", '');
        BookingSync.Validate("Booking Mailbox Name", '');
        BookingSync.Modify();

        // [GIVEN] BookingSyncSetup form
        BookingSyncSetup.Trap;
        PAGE.Run(PAGE::"Booking Sync. Setup", BookingSync);

        BookingSyncSetup."Bookings Company".Value('M365B');

        BookingSync.SetFilter("User ID", UserId);
        BookingSync.FindFirst;

        Assert.AreEqual('M365B409112bookings', BookingSyncSetup."Bookings Company".Value, 'Booking Company not set correctly');
        Assert.AreEqual('M365B409112bookings', BookingSync."Booking Mailbox Name", 'Booking Mailbox Name not set correctly');
        Assert.AreEqual('M365B409112bookings@M365B409112.onmicrosoft.com', BookingSync."Booking Mailbox Address",
          'Booking Mailbox Address not set correctly');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure InvoiceAppointmentsSaaSOnly()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        BookingSyncSetup: TestPage "Booking Sync. Setup";
    begin
        // [SCENARIO 227969] Invoice Appointments action should only appear in SaaS
        Initialize;

        // [WHEN] EnvironmentInfo.IsSaaS returns false
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        // [WHEN] Booking Sync Setup page is open
        BookingSyncSetup.Trap;
        PAGE.Run(PAGE::"Booking Sync. Setup", BookingSync);

        // [THEN] "Invoice Appointments" action is not visible
        Assert.IsFalse(BookingSyncSetup."Invoice Appointments".Visible, 'Invoice Appointments action should not be visible');
        BookingSyncSetup.Close;

        // [WHEN] EnvironmentInfo.IsSaaS returns true
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [WHEN] Booking Sync Setup page is open
        BookingSyncSetup.Trap;
        PAGE.Run(PAGE::"Booking Sync. Setup", BookingSync);

        // [THEN] "Invoice Appointments" action is not visible
        Assert.IsTrue(BookingSyncSetup."Invoice Appointments".Visible, 'Invoice Appointments action should be visible');
    end;

    local procedure Initialize()
    begin
        LibraryO365Sync.SetupNavUser;
        LibraryO365Sync.SetupExchangeSync(ExchangeSync);
        LibraryO365Sync.SetupBookingsSync(BookingSync);
    end;

    [Scope('OnPrem')]
    procedure SetupForSyncing()
    var
        Customer: Record Customer;
        Item: Record Item;
    begin
        CreateServiceItem('Test Sync Service', 20.0, 'SERVICES');
        CreateServiceItem('Test Non-Sync Service', 35.0, 'RETAIL');

        Customer.SetView(CustomerFilterTxt);
        NavCustomerCount := Customer.Count();

        Item.SetView(ItemFilterTxt);
        NavItemCount := Item.Count();

        BookingSync.SaveCustomerFilter(CustomerFilterTxt);
        BookingSync.SaveItemFilter(ItemFilterTxt);
        BookingSync.Modify();

        O365SyncManagement.RegisterBookingsConnection(BookingSync);
        ExchangeContact.DeleteAll();
        BookingService.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure CreateServiceItem(ItemDescription: Text[50]; Price: Decimal; PostingGroup: Code[20])
    var
        Item: Record Item;
    begin
        Item.SetFilter(Description, ItemDescription);
        if not Item.FindFirst then begin
            Item.Init();
            Item.Validate(Description, ItemDescription);
            Item.Validate(Type, Item.Type::Service);
            Item.Validate("Unit Price", Price);
            Item.Validate("Gen. Prod. Posting Group", PostingGroup);
            Item.Insert(true);
        end;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure BookingSyncHandler(var BookingSyncSetup: TestPage "Booking Sync. Setup")
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ContactSyncHandler(var ContactSyncSetup: TestPage "Contact Sync. Setup")
    begin
    end;

    [FilterPageHandler]
    [Scope('OnPrem')]
    procedure CustomerFilterHandler(var RecRef: RecordRef): Boolean
    var
        Customer: Record Customer;
    begin
        RecRef.GetTable(Customer);
        Customer.SetFilter("Location Code", 'GREEN');
        RecRef.SetView(Customer.GetView);
        exit(true);
    end;

    [FilterPageHandler]
    [Scope('OnPrem')]
    procedure ItemFilterHandler(var RecRef: RecordRef): Boolean
    var
        Item: Record Item;
    begin
        RecRef.GetTable(Item);
        Item.SetFilter("Gen. Prod. Posting Group", 'SERVICES');
        RecRef.SetView(Item.GetView);
        exit(true);
    end;
}

