codeunit 133784 "Test Booking Invoicing"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Bookings] [Create Invoice]
    end;

    var
        LibraryBookingManager: Codeunit "Library - Booking Manager";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure BookingInvoicePageHasCorrectNumberOfRecords()
    var
        BookingItem: Record "Booking Item";
        BookingManager: Codeunit "Booking Manager";
        BookingItems: TestPage "Booking Items";
        "Count": Integer;
    begin
        // [SCENARIO] [176542] User sees all Booking items that have not been invoiced when they open the Booking Invoices page.
        Initialize;

        // [GIVEN] Several Booking items are out there - both invoiced and uninvoiced.
        CreateBookingItems(BookingItem, LibraryRandom.RandInt(10) + 3);

        // [WHEN] User chooses to invoice Booking items
        BookingItems.Trap;
        BookingManager.InvoiceBookingItems;

        // [THEN] Number of records shown on page is the same as the number of uninvoiced booking items
        Assert.IsFalse(BookingItems.Editable, 'Booking items should not be editable');

        Count := GetBookingItemCount(BookingItems);
        BookingItem.SetRange("Invoice Status", BookingItem."Invoice Status"::draft);
        BookingItem.SetFilter("Invoice No.", '=''''');
        Assert.AreEqual(BookingItem.Count, Count, 'Unexpected number of Booking items on page.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BookingInvoicePageShowsNAVCustomer()
    var
        BookingItem: Record "Booking Item";
        Customer: Record Customer;
        BookingManager: Codeunit "Booking Manager";
        BookingItems: TestPage "Booking Items";
    begin
        // [SCENARIO] [176542] User sees NAV customer on Booking Items page.
        Initialize;

        // [GIVEN] A Booking item exists for a Booking customer.
        Customer.FindFirst;
        CreateBookingItemFromCustomer(BookingItem, Customer, false, true);

        // [WHEN] User chooses to invoice booking items
        BookingItems.Trap;
        BookingManager.InvoiceBookingItems;

        // [THEN] The record shown has the same name displayed as the customer record in NAV.
        BookingItems.First;
        BookingItems.Customer.AssertEquals(Customer.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BookingInvoicePageFiltersFutureBookingsFromView()
    var
        BookingItem: Record "Booking Item";
        BookingManager: Codeunit "Booking Manager";
        BookingItems: TestPage "Booking Items";
        "Count": Integer;
    begin
        // [SCENARIO] [176542] User does not see Bookings that have not yet occurred.
        Initialize;

        // [GIVEN] A Booking is out there that takes place in the future.
        CreateBookingItems(BookingItem, 1);
        BookingItem.SetStartDate(CurrentDateTime + 36000);
        BookingItem.SetStartDate(CurrentDateTime + 72000);
        BookingItem.Modify();

        // [WHEN] User chooses to invoice Booking items
        BookingItems.Trap;
        BookingManager.InvoiceBookingItems;

        // [THEN] Bookings that have not yet occurred are not shown on the page
        Count := GetBookingItemCount(BookingItems);
        BookingItem.SetRange("Invoice Status", BookingItem."Invoice Status"::draft);
        Assert.AreEqual(0, Count, 'Unexpected number of Booking items on page.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure BookingInvoicePageShowsMessageForEmptyCustomers()
    var
        BookingItem: Record "Booking Item";
        Customer: Record Customer;
        BookingManager: Codeunit "Booking Manager";
        BookingItems: TestPage "Booking Items";
    begin
        // [SCENARIO] [216330] User sees nice message when the Booking appointment has no customer selected
        Initialize;

        // [GIVEN] A Booking is out there that has no customer set.
        CreateBookingItemFromCustomer(BookingItem, Customer, false, true);
        BookingItem."Customer Name" := '';
        BookingItem.Modify();

        // [WHEN] User chooses to invoice Booking items
        BookingItems.Trap;
        BookingManager.InvoiceBookingItems;

        // [THEN] Bookings that have no customer are shown as "<No customer selected>"
        BookingItems.First;
        BookingItems.Customer.AssertEquals('<No customer selected>');

        // [THEN] User sees message when they try to perform action on that appointment.
        BookingItems.Invoice.Invoke;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure InvoiceFromBookingItemsOpensSalesInvoice()
    var
        BookingItem: Record "Booking Item";
        Customer: Record Customer;
        BookingItems: TestPage "Booking Items";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [SCENARIO] [176543] When the user invoices a booking item, the invoice page has the correct values defaulted
        Initialize;

        // [GIVEN] A Booking item exists for a Booking customer.
        CreateBookingItemFromCustomer(BookingItem, Customer, false, true);

        // [WHEN] User chooses to invoice booking items and clicks the Invoice action for the Booking item
        LaunchBookingItemsAndInvoiceFirst(BookingItems, SalesInvoice);

        // [THEN] Sales invoice page is opened with the customer and line item populated
        SalesInvoice."Sell-to Customer Name".AssertEquals(Customer.Name);
        VerifySalesLineWithBookingItem(BookingItem, SalesInvoice);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure InvoiceFromBookingItemsRemovesLine()
    var
        BookingItem: Record "Booking Item";
        Customer: Record Customer;
        BookingItems: TestPage "Booking Items";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [SCENARIO] [176543] When the user invoices a booking item, the appointment is removed from the list.
        Initialize;

        // [GIVEN] A Booking item exists for a Booking customer.
        CreateBookingItemFromCustomer(BookingItem, Customer, false, true);

        // [WHEN] User chooses to invoice booking items and clicks the Invoice action for the Booking item
        LaunchBookingItemsAndInvoiceFirst(BookingItems, SalesInvoice);

        // [THEN] Sales invoice page is opened with the customer and line item populated
        SalesInvoice."Sell-to Customer Name".AssertEquals(Customer.Name);
        VerifySalesLineWithBookingItem(BookingItem, SalesInvoice);

        // [THEN] Appointment disappears from list
        BookingItems.Service.AssertEquals('');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure InvoiceCustomerFromBookingItemsShowsAllSalesLines()
    var
        BookingItem: Record "Booking Item";
        Customer: Record Customer;
        BookingManager: Codeunit "Booking Manager";
        BookingItems: TestPage "Booking Items";
        SalesInvoice: TestPage "Sales Invoice";
        BookingItemCount: Integer;
        i: Integer;
    begin
        // [SCENARIO] [176543] When the user invoices customer for a booking item, each booking item is invoiced
        Initialize;

        // [GIVEN] Multiple Booking item exists for a Booking customer.
        BookingItemCount := LibraryRandom.RandInt(5) + 1;
        for i := 1 to BookingItemCount do
            CreateBookingItemFromCustomer(BookingItem, Customer, false, true);

        // [WHEN] User chooses to invoice booking items
        BookingItems.Trap;
        BookingManager.InvoiceBookingItems;

        // [WHEN] User clicks the Invoice Customer action for the Booking item
        BookingItems.First;
        SalesInvoice.Trap;
        BookingItems."Invoice Customer".Invoke;

        // [THEN] Sales invoice page is opened with the customer and all line items populated
        SalesInvoice."Sell-to Customer Name".AssertEquals(Customer.Name);
        BookingItem.FindFirst;
        SalesInvoice.SalesLines.First;
        for i := 1 to BookingItemCount do begin
            VerifySalesLineWithBookingItem(BookingItem, SalesInvoice);
            BookingItem.Next;
            SalesInvoice.SalesLines.Next;
        end;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure InvoiceCustomerFromBookingItemsIgnoresInvoicedItems()
    var
        BookingItem: Record "Booking Item";
        Customer: Record Customer;
        BookingManager: Codeunit "Booking Manager";
        BookingItems: TestPage "Booking Items";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [SCENARIO] [176543] When the user invoices customer for a booking item, only uninvoiced items are selected.
        Initialize;

        // [GIVEN] Multiple Booking item exists for a Booking customer - both invoiced and uninvoiced.
        CreateBookingItemFromCustomer(BookingItem, Customer, true, true);
        CreateBookingItemFromCustomer(BookingItem, Customer, false, true);
        CreateBookingItemFromCustomer(BookingItem, Customer, true, true);

        // [WHEN] User chooses to invoice booking items
        BookingItems.Trap;
        BookingManager.InvoiceBookingItems;

        // [WHEN] User clicks the Invoice Customer action for the Booking item
        BookingItems.First;
        SalesInvoice.Trap;
        BookingItems."Invoice Customer".Invoke;

        // [THEN] Sales invoice page is opened and only has sales lines for those booking items that have not been invoiced.
        SalesInvoice."Sell-to Customer Name".AssertEquals(Customer.Name);
        BookingItem.SetRange("Invoice Status", BookingItem."Invoice Status"::draft);
        BookingItem.FindFirst;
        SalesInvoice.SalesLines.First;
        VerifySalesLineWithBookingItem(BookingItem, SalesInvoice);
        SalesInvoice.SalesLines.Last;
        VerifySalesLineWithBookingItem(BookingItem, SalesInvoice);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostInvoiceFromBookingItemsSetsInvoicedFieldToTrue()
    var
        BookingItem: Record "Booking Item";
        Customer: Record Customer;
        BookingItems: TestPage "Booking Items";
        SalesInvoice: TestPage "Sales Invoice";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        // [SCENARIO] [176543] When a Booking item is invoiced and posted, the booking item gets marked as invoiced.
        Initialize;

        // [GIVEN] A Booking item exists for a Booking customer.
        CreateBookingItemFromCustomer(BookingItem, Customer, false, true);

        // [WHEN] User chooses to invoice booking items and clicks invoice for the first item
        LaunchBookingItemsAndInvoiceFirst(BookingItems, SalesInvoice);

        // [WHEN] User clicks post
        PostedSalesInvoice.Trap;
        SalesInvoice.Post.Invoke;

        // [THEN] Booking item is marked as invoiced
        BookingItem.Find;
        BookingItem.TestField("Invoice Status", BookingItem."Invoice Status"::open);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure InvoiceCustomerAndPostSetsEachItemAsInvoiced()
    var
        BookingItem: Record "Booking Item";
        Customer: Record Customer;
        BookingManager: Codeunit "Booking Manager";
        BookingItems: TestPage "Booking Items";
        SalesInvoice: TestPage "Sales Invoice";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        // [SCENARIO] [176543] When multiple booking items are invoiced and posted, each item gets marked as invoiced.
        Initialize;

        // [GIVEN] Several booking items exist for a Booking customer.
        CreateBookingItemFromCustomer(BookingItem, Customer, false, true);
        CreateBookingItemFromCustomer(BookingItem, Customer, false, true);
        CreateBookingItemFromCustomer(BookingItem, Customer, false, true);

        // [WHEN] User chooses to invoice booking items
        BookingItems.Trap;
        BookingManager.InvoiceBookingItems;
        BookingItems.First;

        // [WHEN] User clicks the Invoice Customer action for the Booking item
        SalesInvoice.Trap;
        BookingItems."Invoice Customer".Invoke;
        SalesInvoice.SalesLines.First;

        // [WHEN] User clicks post
        PostedSalesInvoice.Trap;
        SalesInvoice.Post.Invoke;

        // [THEN] Booking item is marked as invoiced
        BookingItem.SetRange("Invoice Status", BookingItem."Invoice Status"::open);
        Assert.AreEqual(3, BookingItem.Count, 'Booking items should be marked as invoiced.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BookingSyncIsSetupReturnsCorrectValue()
    var
        BookingSync: Record "Booking Sync";
    begin
        // [SCENARIO] [176542] Bookings Sync table returns false when checking if IsSetup

        // [GIVEN] Bookings sync has never been setup
        BookingSync.DeleteAll();

        // [THEN] BookingsSync.IsSetup returns false
        Assert.IsFalse(BookingSync.IsSetup, 'IsSetup should return false.');

        // [GIVEN] Bookings sync has been set up but never synced
        BookingSync.Init();
        BookingSync.Insert();
        Assert.IsFalse(BookingSync.IsSetup, 'IsSetup should return false.');

        BookingSync."Last Customer Sync" := CurrentDateTime;
        BookingSync.Modify();
        Assert.IsFalse(BookingSync.IsSetup, 'IsSetup should return false.');

        BookingSync."Last Service Sync" := CurrentDateTime;
        BookingSync.Modify();
        Assert.IsTrue(BookingSync.IsSetup, 'IsSetup should return true.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure InvoiceBookingAutomaticallyCreatesServiceItem()
    var
        Customer: Record Customer;
        BookingItem: Record "Booking Item";
        BookingItems: TestPage "Booking Items";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [SCENARIO] [176543] If a matching NAV item doesn't exist for a Booking, it is automatically created when generating the invoice.
        Initialize;

        // [GIVEN] A Booking item exists for a customer, but a matching service item does not exist in the NAV system
        CreateBookingItemFromCustomer(BookingItem, Customer, false, false);

        // [WHEN] User chooses to invoice booking items and clicks the Invoice action for the Booking item
        LaunchBookingItemsAndInvoiceFirst(BookingItems, SalesInvoice);

        // [THEN] The item is automatically created and shows in the sales line.
        with SalesInvoice.SalesLines.Description do
            AssertEquals(StrSubstNo('%1 - %2', BookingItem."Service Name", DT2Date(BookingItem.GetStartDate)));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure InvoiceBookingAutomaticallyCreatesCustomer()
    var
        Customer: Record Customer;
        BookingItem: Record "Booking Item";
        BookingItems: TestPage "Booking Items";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [SCENARIO] [176543] If a matching NAV customer doesn't exist for a Booking, the customer is automatically created.
        Initialize;

        // [GIVEN] A Booking item exists for a Booking customer that does not exist in NAV.
        Customer.Init();
        Customer.Validate(Name, CreateGuid);
        Customer.Validate("E-Mail", StrSubstNo('%1@example.com', CreateGuid));
        CreateBookingItemFromCustomer(BookingItem, Customer, false, true);

        // [WHEN] User chooses to invoice booking items and clicks the invoice action for the Booking item
        LaunchBookingItemsAndInvoiceFirst(BookingItems, SalesInvoice);

        // [THEN] A customer is created and shows up on the invoice
        SalesInvoice."Sell-to Customer Name".AssertEquals(Customer.Name);
        SalesInvoice.Control1900316107."E-Mail".AssertEquals(Customer."E-Mail");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure MarkBookingsAsInvoicedOnlyMarksSingleSelectedRecord()
    var
        Customer: Record Customer;
        BookingItem: Record "Booking Item";
        BookingItems: TestPage "Booking Items";
    begin
        // [SCENARIO] [176543] User can mark a single record as invoiced
        Initialize;

        // [GIVEN] A booking item exists for a booking customer
        CreateBookingItemFromCustomer(BookingItem, Customer, false, true);

        // [WHEN] User selects the booking item on the page
        BookingItem.Mark(true);
        BookingItem.MarkedOnly(true);

        // [WHEN] User clicks "Mark as Invoiced"
        BookingItems.Trap;
        LaunchBookingItemsPage(BookingItem);
        BookingItems.MarkInvoiced.Invoke;

        // [THEN] The selected record is set to invoiced and the record disappears from the Booking Items page
        BookingItem.FindFirst;
        BookingItem.TestField("Invoice Status", BookingItem."Invoice Status"::open);
        BookingItems.First;
        BookingItems.Service.AssertEquals('');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure MarkBookingsAsInvoicedOnlyMarksAllSelectedRecords()
    var
        Customer: Record Customer;
        BookingItem: Record "Booking Item";
        BookingItems: TestPage "Booking Items";
        BookingIds: array[20] of Text[250];
        Marked: array[20] of Boolean;
        "Count": Integer;
        i: Integer;
    begin
        // [SCENARIO] [176543] User can mark multiple records as invoiced
        Initialize;

        // [GIVEN] Multiple booking items exist for a booking customer
        Count := LibraryRandom.RandInt(15) + 5;
        for i := 1 to Count do begin
            CreateBookingItemFromCustomer(BookingItem, Customer, false, true);
            BookingIds[i] := BookingItem.Id;
            if i mod 3 = 1 then begin
                BookingItem.Mark(true);
                Marked[i] := true;
            end;
        end;
        BookingItem.MarkedOnly(true);

        // [WHEN] User opens the booking items page, selects several bookings, and chooses "Mark as Invoiced"
        BookingItems.Trap;
        LaunchBookingItemsPage(BookingItem);
        BookingItems.MarkInvoiced.Invoke;

        // [THEN] Only the selected items are marked as invoiced
        for i := 1 to Count do begin
            BookingItem.Get(BookingIds[i]);
            if Marked[i] then
                BookingItem.TestField("Invoice Status", BookingItem."Invoice Status"::open)
            else
                BookingItem.TestField("Invoice Status", BookingItem."Invoice Status"::draft);
        end;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure InvoiceBookingsForAll()
    var
        Customer: array[10] of Record Customer;
        BookingItem: Record "Booking Item";
        BookingManager: Codeunit "Booking Manager";
        BookingItems: TestPage "Booking Items";
        SalesInvoiceList: TestPage "Sales Invoice List";
        CustCount: Integer;
        LineCount: Integer;
        SalesLineCount: array[10] of Integer;
        i: Integer;
        j: Integer;
    begin
        // [SCENARIO] [176545] User can invoice all uninvoiced booking items
        Initialize;

        // [GIVEN] There are booking items for multiple customers
        CustCount := LibraryRandom.RandInt(5) + 5;
        for i := 1 to CustCount do begin
            ;
            LineCount := LibraryRandom.RandInt(5) + 3;
            for j := 1 to LineCount do
                CreateBookingItemFromCustomer(BookingItem, Customer[i], false, true);
            SalesLineCount[i] := LineCount;
        end;

        // [WHEN] User clicks the invoice all action
        BookingItems.Trap;
        BookingManager.InvoiceBookingItems;
        SalesInvoiceList.Trap;
        BookingItems.InvoiceAll.Invoke;

        // [THEN] Invoices are created for uninvoiced booking items grouped by customer.
        for i := 1 to CustCount do
            CheckSalesLine(Customer[i], SalesLineCount[i]);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure InvoiceBookingsForSelectedCustomerForSingleItem()
    var
        Customer: array[10] of Record Customer;
        BookingItem: Record "Booking Item";
        CustCount: Integer;
        i: Integer;
    begin
        // [SCENARIO] [176545] User can invoice selected customers with a single booking item
        Initialize;

        // [WHEN] User selects multiple customer
        CustCount := LibraryRandom.RandInt(5) + 5;
        for i := 1 to CustCount do begin
            ;
            CreateBookingItemFromCustomer(BookingItem, Customer[i], false, true);
            if i mod 2 = 0 then
                BookingItem.Mark(true);
        end;

        // [WHEN] User clicks Create Invoice
        InvokeCreateInvoice(BookingItem);

        // [THEN] Invoices are created for every selected individual
        for i := 1 to CustCount do begin
            if i mod 2 = 0 then
                CheckSalesLine(Customer[i], 1)
            else
                asserterror CheckSalesLine(Customer[i], 1);
        end;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure InvoiceBookingsForSelectedCustomerWithMultipleItems()
    var
        Customer1: Record Customer;
        Customer3: Record Customer;
        BookingItem: Record "Booking Item";
        i: Integer;
    begin
        // [SCENARIO] [176545] User can invoice selected customers with a multiple booking items
        Initialize;

        // [WHEN] User selects multiple booking items for a single customer
        CreateBookingItemFromCustomer(BookingItem, Customer1, false, true);

        for i := 1 to 3 do begin
            CreateBookingItemFromCustomer(BookingItem, Customer3, false, true);
            BookingItem.Mark(true);
        end;

        // [WHEN] User clicks Create invoice
        InvokeCreateInvoice(BookingItem);

        // [THEN] Single invoice is created for the customer with multiple salesline
        asserterror CheckSalesLine(Customer1, 1);
        CheckSalesLine(Customer3, 3);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure InvoiceBookingsForMultipleCustomerWithMultipleItems()
    var
        Customer: array[10] of Record Customer;
        BookingItem: Record "Booking Item";
        CustCount: Integer;
        SalesLineCount: Integer;
        SalesLineArray: array[10] of Integer;
        i: Integer;
        j: Integer;
    begin
        // [SCENARIO] [176545] User can invoice multiple booking items for multiple customer
        Initialize;

        // [WHEN] User selects multiple booking items for multiple customer
        CustCount := LibraryRandom.RandInt(5) + 5;
        for i := 1 to CustCount do begin
            ;
            SalesLineCount := LibraryRandom.RandInt(5) + 3;
            for j := 1 to SalesLineCount do begin
                CreateBookingItemFromCustomer(BookingItem, Customer[i], false, true);
                if i mod 2 = 0 then
                    BookingItem.Mark(true);
            end;
            SalesLineArray[i] := SalesLineCount;
        end;

        // [WHEN] User clicks Create Invoice
        InvokeCreateInvoice(BookingItem);

        // [THEN] Individual invoices are created for each selected customer with multiple Sales Line
        for i := 1 to CustCount do begin
            if i mod 2 = 0 then
                CheckSalesLine(Customer[i], SalesLineArray[i])
            else
                asserterror CheckSalesLine(Customer[i], SalesLineArray[i]);
        end;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure InvoiceBookingsForSingleCustomerWithMultipleItemsButFewSelected()
    var
        Customer: array[10] of Record Customer;
        BookingItem: Record "Booking Item";
        CustCount: Integer;
        LineCount: Integer;
        MarkCount: Integer;
        SalesLineCount: array[10] of Integer;
        i: Integer;
        j: Integer;
    begin
        // [SCENARIO] [176545] User can invoice only few selected booking items for a customer
        Initialize;

        // [WHEN] There are multiple booking items for a customer and user only selects a few of them
        CustCount := LibraryRandom.RandInt(5) + 5;
        for i := 1 to CustCount do begin
            ;
            LineCount := LibraryRandom.RandInt(5) + 3;
            MarkCount := 0;
            for j := 1 to LineCount do begin
                CreateBookingItemFromCustomer(BookingItem, Customer[i], false, true);
                if j mod 3 = 0 then begin
                    BookingItem.Mark(true);
                    MarkCount += 1;
                end;
            end;
            SalesLineCount[i] := MarkCount;
        end;

        // [WHEN] User clicks Create Invoice
        InvokeCreateInvoice(BookingItem);

        // [THEN] Single invoice is created for the customer for only selected items
        for i := 1 to CustCount do
            CheckSalesLine(Customer[i], SalesLineCount[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetBookingDateStringAddsAdditionalPrecision()
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        NewDateTime: DateTime;
        JsonString: Text;
        ExpectedDateTimeString: Text;
    begin
        // Setup
        NewDateTime := CurrentDateTime;
        ExpectedDateTimeString := Format(NewDateTime, 0, '<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>.0000001Z');

        // Execute
        GraphMgtComplexTypes.GetBookingsDateJSON(NewDateTime, JsonString);

        // Verify
        Assert.IsTrue(StrPos(JsonString, ExpectedDateTimeString) > 0, 'Incorrect formatting of date in json object.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetBookingDateStringAddsAdditionalPrecisionWhenTimeLessPrecise()
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        NewDateTime: DateTime;
        JsonString: Text;
        ExpectedDateTimeString: Text;
    begin
        // Setup
        NewDateTime := CreateDateTime(Today, 0T);
        ExpectedDateTimeString := Format(NewDateTime, 0, '<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>.0000001Z');

        // Execute
        GraphMgtComplexTypes.GetBookingsDateJSON(NewDateTime, JsonString);

        // Verify
        Assert.IsTrue(StrPos(JsonString, ExpectedDateTimeString) > 0, 'Incorrect formatting of date in json object.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteSalesInvoiceAlsoClearsLinkedBookingItemInvoiceFields()
    var
        BookingItem: Record "Booking Item";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        InvoicedBookingItem: Record "Invoiced Booking Item";
        BookingManager: Codeunit "Booking Manager";
        BookingItems: TestPage "Booking Items";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [SCENARIO 176545] Deleting an unposted sales invoice will clear the invoice fields on the linked Booking appointment.
        Initialize;

        // [GIVEN] User has invoiced a Booking appointment
        CreateBookingItemFromCustomer(BookingItem, Customer, false, true);
        LaunchBookingItemsAndInvoiceFirst(BookingItems, SalesInvoice);

        // [WHEN] User deletes the unposted sales invoice.
        SalesHeader.Get(SalesHeader."Document Type"::Invoice, SalesInvoice."No.".Value);
        SalesHeader.Delete(true);
        InvoicedBookingItem.Get(BookingItem.Id);
        BookingManager.SetBookingItemInvoiced(InvoicedBookingItem);

        // [THEN] The invoice fields of the booking appointments are cleared.
        BookingItem.Find;
        BookingItem.TestField("Invoice Amount", 0);
        BookingItem.TestField("Invoice No.", '');
        Assert.IsFalse(InvoicedBookingItem.Get(BookingItem.Id), 'Invoiced booking item record was not deleted.');
    end;

    local procedure Initialize()
    var
        InvoicedBookingItem: Record "Invoiced Booking Item";
        MarketingSetup: Record "Marketing Setup";
        BookingSync: Record "Booking Sync";
        BookingManager: Codeunit "Booking Manager";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        if HasTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, BookingManager.GetAppointmentConnectionName) then
            UnregisterTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, BookingManager.GetAppointmentConnectionName);

        Clear(LibraryBookingManager);
        BindSubscription(LibraryBookingManager);
        SetBookingManager(CODEUNIT::"Library - Booking Manager");
        BookingManager.RegisterAppointmentConnection;
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        MarketingSetup."Sync with Microsoft Graph" := false;
        MarketingSetup.Modify();

        if not BookingSync.Get then begin
            BookingSync.Init();
            BookingSync.Insert();
        end;

        BookingSync."Last Service Sync" := CurrentDateTime;
        BookingSync.Modify();

        InvoicedBookingItem.DeleteAll();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        Assert.AreNotEqual('', Message, 'Message should not be blank.');
    end;

    local procedure SetBookingManager(BookingManagerCodeunit: Integer)
    var
        BookingMgrSetup: Record "Booking Mgr. Setup";
    begin
        if not BookingMgrSetup.Get then
            BookingMgrSetup.Insert();

        BookingMgrSetup."Booking Mgr. Codeunit" := BookingManagerCodeunit;
        BookingMgrSetup.Modify();
    end;

    [Scope('OnPrem')]
    procedure CreateBookingItems(var BookingItem: Record "Booking Item"; "Count": Integer)
    var
        Customer: Record Customer;
        IsInvoiced: Boolean;
        i: Integer;
    begin
        Customer.FindSet;
        for i := 1 to Count do begin
            IsInvoiced := LibraryRandom.RandInt(2) = 1;
            CreateBookingItemFromCustomer(BookingItem, Customer, IsInvoiced, true);
            if i mod 2 = 0 then
                Customer.Next;
        end;
    end;

    local procedure CreateBookingItemFromCustomer(var BookingItem: Record "Booking Item"; var Customer: Record Customer; IsInvoiced: Boolean; CreateItem: Boolean)
    begin
        if Customer.Name = '' then begin
            LibrarySales.CreateCustomer(Customer);
            Customer.Validate("E-Mail", StrSubstNo('%1@example.com', Customer."No."));
            Customer.Modify();
        end;

        with BookingItem do begin
            Init;
            Id := CreateGuid;
            "Customer Email" := Customer."E-Mail";
            "Customer Name" := Customer.Name;
            Price := LibraryRandom.RandDec(50, 2) + 10;
            SetStartDate(CurrentDateTime - 3600000);
            SetEndDate(CurrentDateTime + ((LibraryRandom.RandInt(5) - 1) * 3600000));
            if IsInvoiced then begin
                "Invoice Status" := "Invoice Status"::open;
                "Invoice No." := LibraryUtility.GenerateGUID;
            end else
                "Invoice Status" := "Invoice Status"::draft;
            "Service Name" := CreateGuid;
            "Service ID" := CreateGuid;
            Insert;
        end;

        if CreateItem then
            CreateItemFromBookingItem(BookingItem);
    end;

    local procedure CreateItemFromBookingItem(var BookingItem: Record "Booking Item")
    var
        Item: Record Item;
        BookingServiceMapping: Record "Booking Service Mapping";
    begin
        Item.SetRange(Description, BookingItem."Service Name");
        Item.SetRange(Type, Item.Type::Service);
        if Item.FindFirst then
            exit;

        Clear(Item);
        LibraryInventory.CreateItem(Item);
        Item.Validate(Type, Item.Type::Service);
        Item.Validate(Description, CopyStr(BookingItem."Service Name", 1, 50));
        Item.Modify();

        BookingServiceMapping.Map(Item."No.", BookingItem."Service ID", 'Default');
    end;

    local procedure GetBookingItemCount(BookingItems: TestPage "Booking Items") "Count": Integer
    begin
        if BookingItems.First then begin
            repeat
                if BookingItems.Customer.Value <> '' then
                    Count += 1;
            until not BookingItems.Next;
        end;
    end;

    local procedure LaunchBookingItemsAndInvoiceFirst(var BookingItems: TestPage "Booking Items"; var SalesInvoice: TestPage "Sales Invoice")
    var
        BookingManager: Codeunit "Booking Manager";
    begin
        BookingItems.Trap;
        BookingManager.InvoiceBookingItems;
        BookingItems.First;

        SalesInvoice.Trap;
        BookingItems.Invoice.Invoke;
        SalesInvoice.SalesLines.First;
    end;

    local procedure VerifySalesLineWithBookingItem(var BookingItem: Record "Booking Item"; SalesInvoice: TestPage "Sales Invoice")
    var
        InvoicedBookingItem: Record "Invoiced Booking Item";
        ExpectedDate: DateTime;
    begin
        BookingItem.Find;
        with SalesInvoice.SalesLines do begin
            Description.AssertEquals(StrSubstNo('%1 - %2', BookingItem."Service Name", DT2Date(BookingItem.GetStartDate)));
            Quantity.AssertEquals((BookingItem.GetEndDate - BookingItem.GetStartDate) / 3600000);
            "Unit Price".AssertEquals(BookingItem.Price);
        end;

        InvoicedBookingItem.Get(BookingItem.Id);
        SalesInvoice."No.".AssertEquals(InvoicedBookingItem."Document No.");
        BookingItem.TestField("Invoice No.", SalesInvoice."No.".Value);
        BookingItem.TestField("Invoice Status", BookingItem."Invoice Status"::draft);
        ExpectedDate := CreateDateTime(SalesInvoice."Document Date".AsDate, 0T);
        Assert.AreEqual(ExpectedDate, BookingItem.GetInvoiceDate, 'Invoice date not set correctly.');
        BookingItem.TestField("Invoice Amount", SalesInvoice.SalesLines."Total Amount Incl. VAT".AsDEcimal);
    end;

    local procedure CheckSalesLine(var Customer: Record Customer; SalesLineCount: Integer)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        SalesHeader.SetRange("Sell-to Customer No.", Customer."No.");
        SalesHeader.FindFirst;
        Assert.AreEqual(1, SalesHeader.Count, StrSubstNo('Sales Header count has not matched for %1', Customer.Name));

        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst;
        Assert.AreEqual(SalesLineCount, SalesLine.Count, StrSubstNo('Sales Line count has not match for Customer %1', Customer.Name));
    end;

    local procedure InvokeCreateInvoice(var BookingItem: Record "Booking Item")
    var
        BookingItems: TestPage "Booking Items";
        SalesInvoiceList: TestPage "Sales Invoice List";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        BookingItems.Trap;
        BookingItem.MarkedOnly(true);
        LaunchBookingItemsPage(BookingItem);
        SalesInvoiceList.Trap;
        SalesInvoice.Trap;
        BookingItems.Invoice.Invoke;
        Commit();
    end;

    local procedure CopyBookingItemsToTemp(var BookingItem: Record "Booking Item"; var TempBookingItem: Record "Booking Item" temporary)
    begin
        BookingItem.FindSet;
        repeat
            TempBookingItem.Init();
            BookingItem.CalcFields("Start Date", "End Date");
            TempBookingItem.TransferFields(BookingItem);
            TempBookingItem.Insert();
            TempBookingItem.Mark(BookingItem.Mark);
        until BookingItem.Next = 0;

        TempBookingItem.MarkedOnly(BookingItem.MarkedOnly);
    end;

    local procedure LaunchBookingItemsPage(var BookingItem: Record "Booking Item")
    var
        TempBookingItem: Record "Booking Item" temporary;
    begin
        CopyBookingItemsToTemp(BookingItem, TempBookingItem);
        PAGE.Run(PAGE::"Booking Items", TempBookingItem);
    end;
}

