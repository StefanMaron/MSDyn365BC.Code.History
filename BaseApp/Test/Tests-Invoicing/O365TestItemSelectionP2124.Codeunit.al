codeunit 138901 "O365 Test Item Selection P2124"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Invoicing] [Item Basket] [UI]
    end;

    var
        Item1: Record Item;
        Item2: Record Item;
        Assert: Codeunit Assert;
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure AllItemsActionIsHidden()
    var
        SalesHeader: Record "Sales Header";
        O365SalesInvoice: TestPage "O365 Sales Invoice";
    begin
        // [SCENARIO 195957] Invoice Lines 'Add multiple' action is hidden, until the 'basket' UX is improved.
        // [GIVEN] An empty invoice
        Initialize;
        CreateInvoice(SalesHeader, 0);
        LibraryLowerPermissions.SetSalesDocsCreate;

        // [WHEN] Open Sales Invoice page
        O365SalesInvoice.OpenEdit;
        O365SalesInvoice.GotoRecord(SalesHeader);

        // [THEN] Action 'Add multiple' on invoice lines is not visible
        Assert.IsFalse(O365SalesInvoice.Lines.AllItems.Visible, 'AllItems action should be not visible.');
    end;

    local procedure CreateInvoice(var SalesHeader: Record "Sales Header"; NoOfLines: Integer)
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesLine: Record "Sales Line";
        i: Integer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        for i := 1 to NoOfLines do begin
            LibraryInventory.CreateItem(Item);
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        end;
    end;

    local procedure VerifySalesLines(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; ExpectedQty: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if ItemNo <> '' then begin
            SalesLine.SetRange("No.", ItemNo);
            if SalesLine.FindFirst then
                Assert.AreEqual(ExpectedQty, SalesLine.Quantity, 'Wrong quantity on sales line.')
            else
                Assert.AreEqual(ExpectedQty, 0, 'No sales line found.');
        end else
            Assert.AreEqual(ExpectedQty, SalesLine.Count, 'Wrong number of sales lines');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,BasketPageHandlerNoChange')]
    [Scope('OnPrem')]
    procedure TestEmptyInvoiceNoAddition()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [GIVEN] An empty invoice
        Initialize;
        CreateInvoice(SalesHeader, 0);
        LibraryLowerPermissions.SetSalesDocsCreate;

        // [WHEN] Opening the basket and closing it again
        OpenBasket(SalesHeader);

        // [THEN] There are still no sales lines
        VerifySalesLines(SalesHeader, '', 0);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,BasketPageHandlerAddItem,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestEmptyInvoiceAddItems()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [GIVEN] An empty invoice
        Initialize;
        CreateInvoice(SalesHeader, 0);
        LibraryInventory.CreateItem(Item1);
        LibraryInventory.CreateItem(Item2);
        LibraryLowerPermissions.SetSalesDocsCreate;

        // [WHEN] Opening the basket and closing it again
        OpenBasket(SalesHeader);

        // [THEN] There are 2 lines with qty. 1 and 2
        VerifySalesLines(SalesHeader, Item1."No.", 1);
        VerifySalesLines(SalesHeader, Item2."No.", 4);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,BasketPageHandlerAddItem,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestNonEmptyInvoice()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [GIVEN] An invoice with 2 lines
        Initialize;
        CreateInvoice(SalesHeader, 2);
        LibraryInventory.CreateItem(Item1);
        LibraryInventory.CreateItem(Item2);
        LibraryLowerPermissions.SetSalesDocsCreate;
        LibraryLowerPermissions.AddItemCreate;

        // [WHEN] Opening the basket and closing it again
        OpenBasket(SalesHeader);

        // [THEN] There are 4 lines
        VerifySalesLines(SalesHeader, '', 4);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,BasketPageHandlerAddItem,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestNonEmptyInvoiceChangeDescription()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [GIVEN] An invoice with 2 lines
        Initialize;
        CreateInvoice(SalesHeader, 2);
        LibraryInventory.CreateItem(Item1);
        SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", 10000);
        SalesLine.Description := 'abc';
        SalesLine.Validate(Quantity, 2); // To avoid it from being deleted when basket is reduced by 1.
        SalesLine.Modify;
        Item2.Get(SalesLine."No.");
        LibraryLowerPermissions.SetSalesDocsCreate;
        LibraryLowerPermissions.AddItemCreate;

        // [WHEN] Opening the basket and closing it again
        OpenBasket(SalesHeader);

        // [THEN] There are 3 lines
        VerifySalesLines(SalesHeader, '', 3);
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("No.", Item2."No.");
        SalesLine.FindFirst;
        Assert.AreEqual('abc', SalesLine.Description, 'Description has changed');
    end;

    local procedure OpenBasket(SalesHeader: Record "Sales Header")
    var
        O365SalesInvoice: TestPage "O365 Sales Invoice";
    begin
        O365SalesInvoice.OpenEdit;
        O365SalesInvoice.GotoRecord(SalesHeader);
        O365SalesInvoice.Lines.AllItems.Invoke; // opens pagehandler
        O365SalesInvoice.SaveForLater.Invoke;
    end;

    local procedure Initialize()
    var
        O365C2GraphEventSettings: Record "O365 C2Graph Event Settings";
    begin
        if not O365C2GraphEventSettings.Get then
            O365C2GraphEventSettings.Insert(true);

        O365C2GraphEventSettings.SetEventsEnabled(false);
        O365C2GraphEventSettings.Modify;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure BasketPageHandlerNoChange(var O365ItemBasketPart: TestPage "O365 Item Basket Part")
    begin
        O365ItemBasketPart.Close;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure BasketPageHandlerAddItem(var O365ItemBasketPart: TestPage "O365 Item Basket Part")
    var
        i: Integer;
    begin
        O365ItemBasketPart.First;
        while Item1."No." <> O365ItemBasketPart."Item No.".Value do
            O365ItemBasketPart.Next;
        O365ItemBasketPart.AddToBasket.Invoke;

        O365ItemBasketPart.First;
        while Item2."No." <> O365ItemBasketPart."Item No.".Value do
            O365ItemBasketPart.Next;
        // Create net quantity of 4
        O365ItemBasketPart.ReduceBasket.Invoke; // Already 0, so should stay at zero
        for i := 1 to 5 do
            O365ItemBasketPart.AddToBasket.Invoke;
        O365ItemBasketPart.ReduceBasket.Invoke;
        O365ItemBasketPart.Close;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Answer: Boolean)
    begin
        Answer := true;
    end;

    [SendNotificationHandler(true)]
    [Scope('OnPrem')]
    procedure VerifyNoNotificationsAreSend(var TheNotification: Notification): Boolean
    begin
        Assert.Fail('No notification should be thrown.');
    end;
}

