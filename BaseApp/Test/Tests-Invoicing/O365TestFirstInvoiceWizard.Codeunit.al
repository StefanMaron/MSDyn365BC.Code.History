codeunit 138902 "O365 Test First Invoice Wizard"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Invoicing] [First Invoice Wizard]
    end;

    var
        Assert: Codeunit Assert;
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        O365TemplateManagement: Codeunit "O365 Template Management";

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,FirstInvoiceWizardHandler')]
    [Scope('OnPrem')]
    procedure TestStartFromRoleCenter()
    var
        Customer: Record Customer;
        Item: Record Item;
        O365SalesActivities: TestPage "O365 Sales Activities";
    begin
        // [HAVING] There are no customers and no items, and only one template per table.
        Customer.DeleteAll();
        Item.DeleteAll();
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] The user opens the O365 Sales rolecenter
        O365SalesActivities.OpenEdit;

        // [THEN] The First Invoice Wizard runs
        // FirstInvoiceWizardHandler will click on "Not now" and close the page
        O365SalesActivities.Close;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure Test1CustAndItemSalesTax()
    var
        Customer: Record Customer;
        Item: Record Item;
        ConfigTemplateHeader: Record "Config. Template Header";
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
        O365FirstInvoiceWizard: TestPage "O365 First Invoice Wizard";
    begin
        // [GIVEN] There are no customers and no items
        // [GIVEN] Tax Type is Sales Tax (US,CA)
        SetTaxType(O365SalesInitialSetup."Tax Type"::"Sales Tax");

        Customer.DeleteAll();
        Item.DeleteAll();
        DisableJobQueue;
        ConfigTemplateHeader.SetRange("Table ID", DATABASE::Customer);
        if ConfigTemplateHeader.FindFirst then begin
            ConfigTemplateHeader.SetFilter(Code, '>%1', ConfigTemplateHeader.Code);
            ConfigTemplateHeader.DeleteAll();
        end;
        ConfigTemplateHeader.Reset();
        ConfigTemplateHeader.SetRange("Table ID", DATABASE::Item);
        if ConfigTemplateHeader.FindFirst then begin
            ConfigTemplateHeader.SetFilter(Code, '>%1', ConfigTemplateHeader.Code);
            ConfigTemplateHeader.DeleteAll();
        end;

        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] The user runs the First Invoice Wizard
        O365FirstInvoiceWizard.OpenEdit;
        O365FirstInvoiceWizard.ActionCreateInvoice.Invoke;
        O365FirstInvoiceWizard.CustomerName.SetValue('Customer Name 1');
        O365FirstInvoiceWizard.ActionNext.Invoke;

        O365FirstInvoiceWizard.ItemDescription.SetValue('Hard Work');
        O365FirstInvoiceWizard.ItemPrice.SetValue(0.12345);
        O365FirstInvoiceWizard.ActionNext.Invoke;

        O365FirstInvoiceWizard.CityTax.SetValue(3.123);
        O365FirstInvoiceWizard.StateTax.SetValue(3.321);
        O365FirstInvoiceWizard.ActionNext.Invoke;

        // [THEN] a customer and an item and an invoice are created
        Assert.AreEqual(1, Customer.Count, 'Wrong number of customers were created.');
        Assert.AreEqual(1, Item.Count, 'Wrong number of items were created.');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,VatProductPostingGroupLookup')]
    [Scope('OnPrem')]
    procedure Test1CustAndItemVAT()
    var
        Customer: Record Customer;
        Item: Record Item;
        ConfigTemplateHeader: Record "Config. Template Header";
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        O365FirstInvoiceWizard: TestPage "O365 First Invoice Wizard";
        ItemPrice: Decimal;
    begin
        // [GIVEN] There are no customers and no items
        // [GIVEN] Tax Type is VAT
        Customer.DeleteAll();
        Item.DeleteAll();
        DisableJobQueue;

        SetTaxType(O365SalesInitialSetup."Tax Type"::VAT);

        ConfigTemplateHeader.SetRange("Table ID", DATABASE::Customer);
        if ConfigTemplateHeader.FindFirst then begin
            ConfigTemplateHeader.SetFilter(Code, '>%1', ConfigTemplateHeader.Code);
            ConfigTemplateHeader.DeleteAll();
        end;
        ConfigTemplateHeader.Reset();
        ConfigTemplateHeader.SetRange("Table ID", DATABASE::Item);
        if ConfigTemplateHeader.FindFirst then begin
            ConfigTemplateHeader.SetFilter(Code, '>%1', ConfigTemplateHeader.Code);
            ConfigTemplateHeader.DeleteAll();
        end;

        // create VAT Posting Setup
        VATBusinessPostingGroup.Get(O365TemplateManagement.GetDefaultVATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandDec(99, 2));
        VATPostingSetup.Modify(true);
        Commit();

        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] The user runs the First Invoice Wizard
        O365FirstInvoiceWizard.OpenEdit;
        O365FirstInvoiceWizard.ActionCreateInvoice.Invoke;
        O365FirstInvoiceWizard.CustomerName.SetValue('Customer Name 1');
        O365FirstInvoiceWizard.ActionNext.Invoke;

        O365FirstInvoiceWizard.ItemDescription.SetValue('Hard Work');
        ItemPrice := LibraryRandom.RandDec(100, 2);
        O365FirstInvoiceWizard.ItemPrice.SetValue(ItemPrice);
        O365FirstInvoiceWizard.ActionNext.Invoke;

        LibraryVariableStorage.Enqueue(VATProductPostingGroup.Code);
        O365FirstInvoiceWizard."VAT Group".Lookup;
        Commit();
        O365FirstInvoiceWizard.ActionNext.Invoke;

        // [THEN] a customer and an item and an invoice are created
        Assert.AreEqual(1, Customer.Count, 'Wrong number of customers were created.');
        Assert.AreEqual(1, Item.Count, 'Wrong number of items were created.');
    end;

    local procedure SetTaxType(TaxType: Option)
    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
    begin
        if not O365SalesInitialSetup.Get then
            O365SalesInitialSetup.Insert();
        O365SalesInitialSetup.Validate("Tax Type", TaxType);
        O365SalesInitialSetup.Modify();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure FirstInvoiceWizardHandler(var O365FirstInvoiceWizard: TestPage "O365 First Invoice Wizard")
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VatProductPostingGroupLookup(var O365VATProductPostingGr: TestPage "O365 VAT Product Posting Gr.")
    begin
        O365VATProductPostingGr.GotoKey(LibraryVariableStorage.DequeueText);
        O365VATProductPostingGr.OK.Invoke;
    end;

    local procedure DisableJobQueue()
    var
        O365C2GraphEventSettings: Record "O365 C2Graph Event Settings";
    begin
        if not O365C2GraphEventSettings.Get then
            O365C2GraphEventSettings.Insert(true);

        O365C2GraphEventSettings.SetEventsEnabled(false);
        O365C2GraphEventSettings.Modify();
    end;

    [SendNotificationHandler(true)]
    [Scope('OnPrem')]
    procedure VerifyNoNotificationsAreSend(var TheNotification: Notification): Boolean
    begin
        Assert.Fail('No notification should be thrown.');
    end;
}

