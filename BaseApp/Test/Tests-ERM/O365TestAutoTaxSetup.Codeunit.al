codeunit 138051 "O365 Test Auto Tax Setup"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Sales Tax]
    end;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        EventSubscriberInvoicingApp: Codeunit "EventSubscriber Invoicing App";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateTaxArea()
    var
        TaxArea: Record "Tax Area";
        TaxAreaLine: Record "Tax Area Line";
        TaxJurisdiction: Record "Tax Jurisdiction";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] A new sales order for a new customer. None or few tax areas have been created.
        // [WHEN] The user enters a non-existent tax area in the sales header
        RunCreateTaxAreaScenario(Customer, SalesHeader);

        // [THEN] The system automatically creates the tax area and tax area lines and jurisdictions corresponding to city and state
        Assert.IsTrue(TaxArea.Get(SalesHeader."Tax Area Code"), 'Tax Area Code does not exists..?');
        TaxAreaLine.SetRange("Tax Area", SalesHeader."Tax Area Code");
        TaxAreaLine.FindSet;
        repeat
            TaxJurisdiction.Get(TaxAreaLine."Tax Jurisdiction Code");
        until TaxAreaLine.Next = 0;

        // [THEN] Customer's "Tax Area Code" updated
        Customer.Find;
        Customer.TestField("Tax Area Code", SalesHeader."Tax Area Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetSalesTaxRate()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        O365SalesInvoice: TestPage "O365 Sales Invoice";
        O365SalesInvoiceLineCard: TestPage "O365 Sales Invoice Line Card";
        TempTaxRate: Text;
    begin
        // [FEATURE] [O365] [Sales] [Invoice] [UI]
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] A new sales order for a new tax area and tax group shows 0% as tax.
        RunCreateTaxAreaScenario(Customer, SalesHeader);
        LibraryInventory.CreateItem(Item);
        Item.Validate(Type, Item.Type::Service);
        Item."Tax Group Code" := GetRandomCode10;
        Item.Modify;

        O365SalesInvoice.OpenEdit;
        O365SalesInvoice.GotoRecord(SalesHeader);

        LibrarySales.CreateSimpleItemSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item);

        O365SalesInvoiceLineCard.OpenEdit;
        O365SalesInvoiceLineCard.GotoRecord(SalesLine);
        O365SalesInvoiceLineCard.Description.Value(Item.Description);
        O365SalesInvoiceLineCard.LineQuantity.SetValue(1);
        TempTaxRate := O365SalesInvoiceLineCard.TaxRate.Value;
        TempTaxRate := CopyStr(TempTaxRate, 1, (StrLen(TempTaxRate) - 1));
        Assert.AreEqual('0', TempTaxRate, 'Initial Tax Rate not zero');
        O365SalesInvoiceLineCard.Close;
    end;

    local procedure Initialize()
    var
        O365C2GraphEventSettings: Record "O365 C2Graph Event Settings";
    begin
        EventSubscriberInvoicingApp.Clear;
        ApplicationArea('#Invoicing');

        if IsInitialized then
            exit;

        if not O365C2GraphEventSettings.Get then
            O365C2GraphEventSettings.Insert(true);

        O365C2GraphEventSettings.SetEventsEnabled(false);
        O365C2GraphEventSettings.Modify;

        EventSubscriberInvoicingApp.SetAppId('INV');
        BindSubscription(EventSubscriberInvoicingApp);

        IsInitialized := true;
    end;

    local procedure RunCreateTaxAreaScenario(var Customer: Record Customer; var SalesHeader: Record "Sales Header")
    var
        TaxArea: Record "Tax Area";
        NewAreaCode: Code[20];
    begin
        // [GIVEN] A new sales order for a new customer. None or few tax areas have been created.
        LibrarySales.CreateCustomer(Customer);
        Customer."Tax Area Code" := '';
        Customer.City := GetRandomCode20 + GetRandomCode10;
        Customer.County := GetRandomCode20;
        Customer."Tax Liable" := true;
        Customer.Modify;
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        NewAreaCode := GetRandomCode20;
        Assert.IsFalse(TaxArea.Get(NewAreaCode), 'Tax Area Code already exists..?');

        // [WHEN] The user enters a non-existent tax area in the sales header
        SalesHeader.Validate("Tax Area Code", NewAreaCode);
        SalesHeader.Modify;
    end;

    local procedure GetRandomCode10(): Code[10]
    begin
        exit(CopyStr(DelChr(Format(CreateGuid), '=', '{}- '), 1, 10));
    end;

    local procedure GetRandomCode20(): Code[20]
    begin
        exit(CopyStr(DelChr(Format(CreateGuid), '=', '{}- '), 1, 20));
    end;
}

