codeunit 138050 "O365 Test Name Nearness"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Name Auto-correction] [UT]
    end;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesHeader()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        CorrectName: Text[50];
        WrongName: Text[50];
    begin
        // [GIVEN] We have customer named '<some guid>'
        LibrarySales.CreateCustomer(Customer);
        CreateNames(CorrectName, WrongName);
        Customer.Name := CorrectName;
        Customer.Modify();

        // [WHEN] User enters a slightly wrongly typed name
        SalesHeader.Init();
        SalesHeader.Validate("Sell-to Customer Name", WrongName);

        // [THEN] The system returns the correct customer no.
        Assert.AreEqual(Customer."No.", SalesHeader."Sell-to Customer No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesLine()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        O365TestNameNearness: Codeunit "O365 Test Name Nearness";
        CorrectName: Text[50];
        WrongName: Text[50];
    begin
        // [GIVEN] We have item named '<some guid>'
        LibrarySales.CreateCustomer(Customer);
        BindSubscription(O365TestNameNearness);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        UnbindSubscription(O365TestNameNearness);
        LibraryInventory.CreateItem(Item);
        CreateNames(CorrectName, WrongName);
        Item.Description := CorrectName;
        Item.Modify();

        // [WHEN] User enters a slightly wrongly typed name
        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := 10000;
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine.Insert();
        SalesLine.Validate(Description, WrongName);

        // [THEN] The system returns the correct item no.
        Assert.AreEqual(Item."No.", SalesLine."No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesLinePage2310NewLine()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        O365TestNameNearness: Codeunit "O365 Test Name Nearness";
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
        CorrectName: Text[50];
        WrongName: Text[50];
    begin
        // [GIVEN] We have item named '<some guid>'
        LibrarySales.CreateCustomer(Customer);
        BindSubscription(O365TestNameNearness);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibraryInventory.CreateItem(Item);
        CreateNames(CorrectName, WrongName);
        Item.Description := CorrectName;
        Item.Modify();

        // [WHEN] User enters a slightly wrongly typed name
        BCO365SalesInvoice.OpenEdit;
        BCO365SalesInvoice.GotoRecord(SalesHeader);
        BCO365SalesInvoice.Lines.Description.Value(WrongName);

        UnbindSubscription(O365TestNameNearness);

        // [THEN] The system returns the correct item no.
        ValidateSalesLine(SalesHeader, CorrectName, Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesLinePage2310Correctdescription()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        O365TestNameNearness: Codeunit "O365 Test Name Nearness";
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
        CorrectName: Text[50];
        WrongName: Text[50];
    begin
        // [GIVEN] We have item named '<some guid>'
        LibrarySales.CreateCustomer(Customer);
        BindSubscription(O365TestNameNearness);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibraryInventory.CreateItem(Item);
        CreateNames(CorrectName, WrongName);
        Item.Description := CorrectName;
        Item.Modify();

        // [WHEN] User enters a slightly wrongly typed name
        BCO365SalesInvoice.OpenEdit;
        BCO365SalesInvoice.GotoRecord(SalesHeader);
        BCO365SalesInvoice.Lines.Description.Value(CorrectName);
        ValidateSalesLine(SalesHeader, CorrectName, Item."No."); // just to make sure...

        BCO365SalesInvoice.Lines.Description.Value(WrongName);
        UnbindSubscription(O365TestNameNearness);

        // [THEN] The system returns the correct item no.
        ValidateSalesLine(SalesHeader, WrongName, Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseHeader()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        CorrectName: Text[50];
        WrongName: Text[50];
    begin
        // [GIVEN] We have vendor named '<some guid>'
        LibraryPurchase.CreateVendor(Vendor);
        CreateNames(CorrectName, WrongName);
        Vendor.Name := CorrectName;
        Vendor.Modify();

        // [WHEN] User enters a slightly wrongly typed name
        PurchaseHeader.Init();
        PurchaseHeader.Validate("Buy-from Vendor Name", WrongName);

        // [THEN] The system returns the correct vendor no.
        Assert.AreEqual(Vendor."No.", PurchaseHeader."Buy-from Vendor No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseLine()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        CorrectName: Text[50];
        WrongName: Text[50];
    begin
        // [GIVEN] We have item named '<some guid>'
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryInventory.CreateItem(Item);
        CreateNames(CorrectName, WrongName);
        Item.Description := CorrectName;
        Item.Modify();

        // [WHEN] User enters a slightly wrongly typed name
        PurchaseLine.Init();
        PurchaseLine."Document Type" := PurchaseHeader."Document Type";
        PurchaseLine."Document No." := PurchaseHeader."No.";
        PurchaseLine."Line No." := 10000;
        PurchaseLine.Type := PurchaseLine.Type::Item;
        PurchaseLine.Insert();
        PurchaseLine.Validate(Description, WrongName);

        // [THEN] The system returns the correct item no.
        Assert.AreEqual(Item."No.", PurchaseLine."No.", '');
    end;

    local procedure CreateNames(var CorrectName: Text[50]; var WrongName: Text[50])
    begin
        CorrectName := Format(CreateGuid);
        WrongName := CorrectName;
        WrongName[1] := 'X';
        WrongName[10] := ' ';
        WrongName[15] := '@';
    end;

    local procedure ValidateSalesLine(var SalesHeader: Record "Sales Header"; Description: Text[50]; ItemNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Init();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst;
        Assert.AreEqual(10000, SalesLine."Line No.", 'wrong line number');
        Assert.AreEqual(SalesLine.Type::Item, SalesLine.Type, 'wrong line type');
        Assert.AreEqual(ItemNo, SalesLine."No.", 'wrong item number');
        Assert.AreEqual(Description, SalesLine.Description, 'Wrong Description');
    end;

    [EventSubscriber(ObjectType::Codeunit, 453, 'OnBeforeJobQueueScheduleTask', '', false, false)]
    local procedure DoNotScheduleTasks(var JobQueueEntry: Record "Job Queue Entry"; var DoNotScheduleTask: Boolean)
    begin
        DoNotScheduleTask := true;
    end;
}

