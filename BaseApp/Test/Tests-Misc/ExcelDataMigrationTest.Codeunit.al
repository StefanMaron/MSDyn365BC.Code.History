codeunit 139312 "Excel Data Migration Test"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Data Migration for Excel]
    end;

    var
        LibraryRapidStart: Codeunit "Library - Rapid Start";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        ExcelDataMigrator: Codeunit "Excel Data Migrator";
        Assert: Codeunit Assert;
        ConfigPackageManagement: Codeunit "Config. Package Management";
        FieldValueErr: Label 'Field %1 in table %2 has a different value than expected.';
        ApplySummaryTxt: Label '%1 tables are processed.\%2 errors found.\%3 records inserted.\%4 records modified.';
        ValidateErrorsBeforeApplyQst: Label 'Some of the fields will not be applied because errors were found in the imported data.\\Do you want to continue?';

    [Test]
    [Scope('OnPrem')]
    procedure TestPackageCreated()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageField: Record "Config. Package Field";
        ConfigPackageRecord: Record "Config. Package Record";
        ConfigPackageData: Record "Config. Package Data";
        TempConfigPackageTable: Record "Config. Package Table" temporary;
        Customer: Record Customer;
    begin
        // [GIVEN] A newly provisioned database, initialized with no Excel Config. Package
        Initialize();

        // [WHEN] Excel file is imported
        ExcelDataMigrator.ImportExcelDataByFileName(LibraryUtility.GetInetRoot() + GetExcelFileName());

        // [THEN] A Config. Package was created
        ConfigPackage.SetRange(Code, ExcelDataMigrator.GetPackageCode());
        ConfigPackage.FindFirst();
        Assert.RecordIsNotEmpty(ConfigPackage);

        // [THEN] The Config. Package contains a Customer, Item Package Table
        ConfigPackageTable.SetRange("Package Code", ExcelDataMigrator.GetPackageCode());
        ConfigPackageTable.SetRange("Table ID", DATABASE::Customer);
        ConfigPackageTable.FindFirst();
        Assert.RecordIsNotEmpty(ConfigPackageTable);

        ConfigPackageTable.Reset();
        ConfigPackageTable.SetRange("Package Code", ExcelDataMigrator.GetPackageCode());
        ConfigPackageTable.SetRange("Table ID", DATABASE::Item);
        ConfigPackageTable.FindFirst();
        Assert.RecordIsNotEmpty(ConfigPackageTable);

        // [THEN] The Customer Package Table does not contain all fields
        ConfigPackageTable.Reset();
        ConfigPackageTable.SetRange("Package Code", ExcelDataMigrator.GetPackageCode());
        ConfigPackageTable.SetRange("Table ID", DATABASE::Customer);
        ConfigPackageTable.FindFirst();
        ConfigPackageTable.CalcFields("No. of Fields Available", "No. of Fields Included");
        Assert.AreEqual(15, ConfigPackageTable."No. of Fields Included",
          'Package should only contain a subset of fields');

        // [THEN] The Customer Package Table contains a Name field
        ConfigPackageField.SetRange("Package Code", ExcelDataMigrator.GetPackageCode());
        ConfigPackageField.SetRange("Table ID", DATABASE::Customer);
        ConfigPackageField.SetRange("Field ID", Customer.FieldNo(Name));
        ConfigPackageField.FindFirst();
        Assert.RecordIsNotEmpty(ConfigPackageField);
        Assert.IsTrue(ConfigPackageField."Include Field", 'Name field not included in customer package');

        // [THEN] There is a Customer, Item record in the package
        ConfigPackageRecord.SetRange("Package Code", ExcelDataMigrator.GetPackageCode());
        ConfigPackageRecord.SetRange("Table ID", DATABASE::Customer);
        ConfigPackageRecord.FindFirst();
        Assert.RecordIsNotEmpty(ConfigPackageRecord);

        ConfigPackageRecord.Reset();
        ConfigPackageRecord.SetRange("Package Code", ExcelDataMigrator.GetPackageCode());
        ConfigPackageRecord.SetRange("Table ID", DATABASE::Item);
        ConfigPackageRecord.FindFirst();
        Assert.RecordIsNotEmpty(ConfigPackageRecord);

        // [THEN] There is data in the Customer Record for the Country/Region Code field
        ConfigPackageData.SetRange("Package Code", ExcelDataMigrator.GetPackageCode());
        ConfigPackageData.SetRange("Table ID", DATABASE::Customer);
        ConfigPackageData.SetRange("Field ID", Customer.FieldNo("Country/Region Code"));
        ConfigPackageData.FindFirst();
        Assert.IsTrue(ConfigPackageData.Count = 5, 'Wrong number of element in package');

        // [THEN] The package validates
        ConfigPackageManagement.SetHideDialog(true);
        ConfigPackageManagement.ValidatePackageRelations(ConfigPackageTable,
          TempConfigPackageTable, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCustomersImported()
    var
        Customer: Record Customer;
    begin
        // [GIVEN] A newly provisioned database, initialized with no Excel Config. Package, Customers
        Initialize();

        // [WHEN] An Excel file is imported and applied
        ImportAndApplyPackage();

        // [THEN] Customers are created
        Assert.IsTrue(Customer.Count = 5,
          StrSubstNo('Incorrect number of Customers imported (%1)', Customer.Count));

        // [THEN] Each new customer contains data from Excel
        VerifyImportedData(LibraryUtility.GetInetRoot() + GetExcelFileName(), DATABASE::Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVendorsImported()
    var
        Vendor: Record Vendor;
    begin
        // [GIVEN] A newly provisioned database, initialized with no Excel Config. Package, Vendors
        Initialize();

        // [WHEN] An Excel file is imported and applied
        ImportAndApplyPackage();

        // [THEN] Vendor are created
        Assert.IsTrue(Vendor.Count = 5,
          StrSubstNo('Incorrect number of Vendors imported (%1)', Vendor.Count));

        // [THEN] Each new vendor contains data from Excel
        VerifyImportedData(LibraryUtility.GetInetRoot() + GetExcelFileName(), DATABASE::Vendor);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItemsImported()
    var
        Item: Record Item;
    begin
        // [GIVEN] A newly provisioned database, initialized with no Excel Config. Package, Items
        Initialize();

        // [WHEN] An Excel file is imported and applied
        ImportAndApplyPackage();

        // [THEN] Items are created
        Assert.IsTrue(Item.Count = 15,
          StrSubstNo('Incorrect number of Items imported (%1)', Item.Count));

        // [THEN] Each new item contains data from Excel
        VerifyImportedData(LibraryUtility.GetInetRoot() + GetExcelFileName(), DATABASE::Item);
    end;

    [Test]
    [HandlerFunctions('DataMigratorsPageHandler,MessageHandler,ConfigPackageErrorspageHandler')]
    [Scope('OnPrem')]
    procedure TestWizardIntegration()
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Item: Record Item;
        ExcelDataMigrationTest: Codeunit "Excel Data Migration Test";
        DataMigrationWizard: TestPage "Data Migration Wizard";
    begin
        // [GIVEN] A newly setup company
        Initialize();
        BindSubscription(ExcelDataMigrationTest);

        // [WHEN] The data migration wizard executed to the end
        RunWizardToCompletion(DataMigrationWizard);

        // [THEN] Customers are created
        Assert.AreEqual(5, Customer.Count, 'Incorrect number of Customers imported');

        // [THEN] Vendors are created
        Assert.AreEqual(5, Vendor.Count, 'Incorrect number of Vendors imported');

        // [THEN] Items are created
        Assert.AreEqual(15, Item.Count, 'Incorrect number of Items imported');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostProcessing()
    var
        Item: Record Item;
    begin
        // [GIVEN] A newly setup company
        Initialize();

        // [WHEN] An Excel file is imported and applied
        ImportAndApplyPackage();

        // [THEN] Post processing of items has occured (inventory was updated)
        Assert.AreEqual(15, Item.Count, 'Incorrect number of Items imported');
        Item.Get(1); // Item No. 1 has an inventory of 5 in the test file
        Item.CalcFields(Inventory);
        Assert.AreEqual(5, Item.Inventory, 'Wrong inventory was posted');
    end;

    [Test]
    [HandlerFunctions('DataMigratorsPageHandler,ConfirmBeforeApplyHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure WizardApplyInvalidCustomer_ConfirmYes()
    var
        ExcelDataMigrationTest: Codeunit "Excel Data Migration Test";
        DataMigrationWizard: TestPage "Data Migration Wizard";
    begin
        // [SCENARIO 251670] Confirmation message is shown when perform Apply step via data migration wizard in case of
        // [SCENARIO 251670] excel file contains invalid Customer row, valid Vendor row, select only Customer table to apply (confirm Yes)
        Initialize();
        BindSubscription(ExcelDataMigrationTest);

        // [GIVEN] Import excel file including Customer (with invalid Payment Terms Code) and Vendor via data migration wizard
        // [GIVEN] Select only Customer table to apply in the wizard
        // [GIVEN] Perform Next wizard step to start Apply. Confirmation has been shown.
        // [WHEN] Confirm Yes
        LibraryVariableStorage.Enqueue(true); // Confirm Yes
        RunWizardToApplyAndFinish(DataMigrationWizard, true, false);

        // [THEN] Apply summary message has been shown: "1 tables are processed.\1 errors found.\1 records inserted.\0 records modified."
        // [THEN] The data has been applied and there is a new Customer
        Assert.ExpectedMessage(StrSubstNo(ApplySummaryTxt, 1, 1, 1, 0), LibraryVariableStorage.DequeueText());
        VerifyCustomerAndVendorAfterWizardApply(1, 0);
    end;

    [Test]
    [HandlerFunctions('DataMigratorsPageHandler,ConfirmBeforeApplyHandler')]
    [Scope('OnPrem')]
    procedure WizardApplyInvalidCustomer_ConfirmNo()
    var
        ExcelDataMigrationTest: Codeunit "Excel Data Migration Test";
        DataMigrationWizard: TestPage "Data Migration Wizard";
    begin
        // [SCENARIO 251670] Confirmation message is shown when perform Apply step via data migration wizard in case of
        // [SCENARIO 251670] excel file contains invalid Customer row, valid Vendor row, select only Customer table to apply (confirm No)
        Initialize();
        BindSubscription(ExcelDataMigrationTest);

        // [GIVEN] Import excel file including Customer (with invalid Payment Terms Code) and Vendor via data migration wizard
        // [GIVEN] Select only Customer table to apply in the wizard
        // [GIVEN] Perform Next wizard step to start Apply. Confirmation has been shown.
        // [WHEN] Confirm No
        LibraryVariableStorage.Enqueue(false); // Confirm No
        RunWizardToApplyAndFinish(DataMigrationWizard, true, false);

        // [THEN] The data has not been applied and there is no Customer and Vendor
        VerifyCustomerAndVendorAfterWizardApply(0, 0);
    end;

    [Test]
    [HandlerFunctions('DataMigratorsPageHandler,ConfirmBeforeApplyHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure WizardApplyInvalidCustomer_ConfirmNo_AgainCustomer_ConfirmYes()
    var
        ExcelDataMigrationTest: Codeunit "Excel Data Migration Test";
        DataMigrationWizard: TestPage "Data Migration Wizard";
    begin
        // [SCENARIO 251670] Confirmation message is shown when perform Apply step via data migration wizard in case of
        // [SCENARIO 251670] excel file contains invalid Customer row, valid Vendor row, select only Customer table to apply (confirm No, Apply only Customer again, confirm Yes)
        Initialize();
        BindSubscription(ExcelDataMigrationTest);

        // [GIVEN] Import excel file including Customer (with invalid Payment Terms Code) and Vendor via data migration wizard
        // [GIVEN] Select only Customer table to apply in the wizard
        // [GIVEN] Perform Next wizard step to start Apply. Confirmation has been shown. Choose No.
        // [GIVEN] Select only Customer table to apply in the wizard
        // [GIVEN] Perform Next wizard step to start Apply. Confirmation has been shown.
        // [WHEN] Confirm Yes
        LibraryVariableStorage.Enqueue(false); // Confirm No
        LibraryVariableStorage.Enqueue(true); // Confirm Yes
        RunWizardToApplyContinueApplyAgainAndFinish(DataMigrationWizard, true, false, true, false);

        // [THEN] Apply summary message has been shown: "1 tables are processed.\1 errors found.\1 records inserted.\0 records modified."
        // [THEN] The data has been applied and there is a new Customer
        Assert.ExpectedMessage(StrSubstNo(ApplySummaryTxt, 1, 1, 1, 0), LibraryVariableStorage.DequeueText());
        VerifyCustomerAndVendorAfterWizardApply(1, 0);
    end;

    [Test]
    [HandlerFunctions('DataMigratorsPageHandler,ConfirmBeforeApplyHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure WizardApplyInvalidCustomer_ConfirmNo_AgainVendor()
    var
        ExcelDataMigrationTest: Codeunit "Excel Data Migration Test";
        DataMigrationWizard: TestPage "Data Migration Wizard";
    begin
        // [SCENARIO 251670] Confirmation message is shown when perform Apply step via data migration wizard in case of
        // [SCENARIO 251670] excel file contains invalid Customer row, valid Vendor row, select only Customer table to apply (confirm No, Apply only Vendor again)
        Initialize();
        BindSubscription(ExcelDataMigrationTest);

        // [GIVEN] Import excel file including Customer (with invalid Payment Terms Code) and Vendor via data migration wizard
        // [GIVEN] Select only Customer table to apply in the wizard
        // [GIVEN] Perform Next wizard step to start Apply. Confirmation has been shown. Choose No.
        // [GIVEN] Select only Vendor table to apply in the wizard
        // [WHEN] Perform Next wizard step to start Apply
        LibraryVariableStorage.Enqueue(false); // Confirm No
        RunWizardToApplyContinueApplyAgainAndFinish(DataMigrationWizard, true, false, false, true);

        // [THEN] Apply summary message has been shown: "1 tables are processed.\0 errors found.\1 records inserted.\0 records modified."
        Assert.ExpectedMessage(StrSubstNo(ApplySummaryTxt, 1, 0, 1, 0), LibraryVariableStorage.DequeueText());
        // [THEN] The data has been applied and there is a new Vendor
        VerifyCustomerAndVendorAfterWizardApply(0, 1);
    end;

    [Test]
    [HandlerFunctions('DataMigratorsPageHandler,ConfirmBeforeApplyHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure WizardApplyInvalidCustomer_ConfirmNo_AgainBoth_ConfirmYes()
    var
        ExcelDataMigrationTest: Codeunit "Excel Data Migration Test";
        DataMigrationWizard: TestPage "Data Migration Wizard";
    begin
        // [SCENARIO 251670] Confirmation message is shown when perform Apply step via data migration wizard in case of
        // [SCENARIO 251670] excel file contains invalid Customer row, valid Vendor row, select only Customer table to apply (confirm No, Apply both Customer and Vendor again, confirm Yes)
        Initialize();
        BindSubscription(ExcelDataMigrationTest);

        // [GIVEN] Import excel file including Customer (with invalid Payment Terms Code) and Vendor via data migration wizard
        // [GIVEN] Select only Customer table to apply in the wizard
        // [GIVEN] Perform Next wizard step to start Apply. Confirmation has been shown. Choose No.
        // [GIVEN] Select both Customer, Vendor tables to apply in the wizard
        // [GIVEN] Perform Next wizard step to start Apply. Confirmation has been shown.
        // [WHEN] Confirm Yes
        LibraryVariableStorage.Enqueue(false); // Confirm No
        LibraryVariableStorage.Enqueue(true); // Confirm Yes
        RunWizardToApplyContinueApplyAgainAndFinish(DataMigrationWizard, true, false, true, true);

        // [THEN] Apply summary message has been shown: "2 tables are processed.\1 errors found.\2 records inserted.\0 records modified."
        Assert.ExpectedMessage(StrSubstNo(ApplySummaryTxt, 2, 1, 2, 0), LibraryVariableStorage.DequeueText());
        // [THEN] The data has been applied and there is a new Customer and Vendor
        VerifyCustomerAndVendorAfterWizardApply(1, 1);
    end;

    [Test]
    [HandlerFunctions('DataMigratorsPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure WizardApplyValidVendor()
    var
        ExcelDataMigrationTest: Codeunit "Excel Data Migration Test";
        DataMigrationWizard: TestPage "Data Migration Wizard";
    begin
        // [SCENARIO 251670] There is no confirmation message when perform Apply step via data migration wizard in case of
        // [SCENARIO 251670] excel file contains invalid Customer row, valid Vendor row, select only Vendor table to apply
        Initialize();
        BindSubscription(ExcelDataMigrationTest);

        // [GIVEN] Import excel file including Customer (with invalid Payment Terms Code) and Vendor via data migration wizard
        // [GIVEN] Select only Vendor table to apply in the wizard
        // [WHEN] Perform Next wizard step to start Apply
        RunWizardToApplyAndFinish(DataMigrationWizard, false, true);

        // [THEN] Apply summary message has been shown: "1 tables are processed.\0 errors found.\1 records inserted.\0 records modified."
        Assert.ExpectedMessage(StrSubstNo(ApplySummaryTxt, 1, 0, 1, 0), LibraryVariableStorage.DequeueText());
        // [THEN] The data has been applied and there is a new Vendor
        VerifyCustomerAndVendorAfterWizardApply(0, 1);
    end;

    [Test]
    [HandlerFunctions('DataMigratorsPageHandler,ConfirmBeforeApplyHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure WizardApplyInvalidCustomerAndValidVendor_ConfirmYes()
    var
        ExcelDataMigrationTest: Codeunit "Excel Data Migration Test";
        DataMigrationWizard: TestPage "Data Migration Wizard";
    begin
        // [SCENARIO 251670] Confirmation message is shown when perform Apply step via data migration wizard in case of
        // [SCENARIO 251670] excel file contains invalid Customer row, valid Vendor row, select both tables to apply (confirm Yes)
        Initialize();
        BindSubscription(ExcelDataMigrationTest);

        // [GIVEN] Import excel file including Customer (with invalid Payment Terms Code) and Vendor via data migration wizard
        // [GIVEN] Select both Customer, Vendor tables to apply in the wizard
        // [GIVEN] Perform Next wizard step to start Apply. Confirmation has been shown.
        // [WHEN] Confirm Yes
        LibraryVariableStorage.Enqueue(true); // Confirm Yes
        RunWizardToApplyAndFinish(DataMigrationWizard, true, true);

        // [THEN] Apply summary message has been shown: "2 tables are processed.\1 errors found.\2 records inserted.\0 records modified."
        Assert.ExpectedMessage(StrSubstNo(ApplySummaryTxt, 2, 1, 2, 0), LibraryVariableStorage.DequeueText());
        // [THEN] The data has been applied and there is a new Customer and Vendor
        VerifyCustomerAndVendorAfterWizardApply(1, 1);
    end;

    [Test]
    [HandlerFunctions('DataMigratorsPageHandler,ConfirmBeforeApplyHandler')]
    [Scope('OnPrem')]
    procedure WizardApplyInvalidCustomerAndValidVendor_ConfirmNo()
    var
        ExcelDataMigrationTest: Codeunit "Excel Data Migration Test";
        DataMigrationWizard: TestPage "Data Migration Wizard";
    begin
        // [SCENARIO 251670] Confirmation message is shown when perform Apply step via data migration wizard in case of
        // [SCENARIO 251670] excel file contains invalid Customer row, valid Vendor row, select both tables to apply (confirm No)
        Initialize();
        BindSubscription(ExcelDataMigrationTest);

        // [GIVEN] Import excel file including Customer (with invalid Payment Terms Code) and Vendor via data migration wizard
        // [GIVEN] Select both Customer, Vendor tables to apply in the wizard
        // [GIVEN] Perform Next wizard step to start Apply. Confirmation has been shown.
        // [WHEN] Confirm No
        LibraryVariableStorage.Enqueue(false); // Confirm No
        RunWizardToApplyAndFinish(DataMigrationWizard, true, true);

        // [THEN] The data has not been applied and there is no Customer and Vendor
        VerifyCustomerAndVendorAfterWizardApply(0, 0);
    end;

    [Test]
    [HandlerFunctions('DataMigratorsPageHandler,ConfirmBeforeApplyHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure WizardApplyInvalidCustomerAndValidVendor_ConfirmNo_AgainCustomer_ConfirmYes()
    var
        ExcelDataMigrationTest: Codeunit "Excel Data Migration Test";
        DataMigrationWizard: TestPage "Data Migration Wizard";
    begin
        // [SCENARIO 251670] Confirmation message is shown when perform Apply step via data migration wizard in case of
        // [SCENARIO 251670] excel file contains invalid Customer row, valid Vendor row, select both tables to apply (confirm No, Apply only Customer again, confirm Yes)
        Initialize();
        BindSubscription(ExcelDataMigrationTest);

        // [GIVEN] Import excel file including Customer (with invalid Payment Terms Code) and Vendor via data migration wizard
        // [GIVEN] Select both Customer, Vendor tables to apply in the wizard
        // [GIVEN] Perform Next wizard step to start Apply. Confirmation has been shown. Choose No.
        // [GIVEN] Select only Customer table to apply in the wizard
        // [GIVEN] Perform Next wizard step to start Apply. Confirmation has been shown.
        // [WHEN] Confirm Yes
        LibraryVariableStorage.Enqueue(false); // Confirm No
        LibraryVariableStorage.Enqueue(true); // Confirm Yes
        RunWizardToApplyContinueApplyAgainAndFinish(DataMigrationWizard, true, true, true, false);

        // [THEN] Apply summary message has been shown: "1 tables are processed.\1 errors found.\1 records inserted.\0 records modified."
        // [THEN] The data has been applied and there is a new Customer
        Assert.ExpectedMessage(StrSubstNo(ApplySummaryTxt, 1, 1, 1, 0), LibraryVariableStorage.DequeueText());
        VerifyCustomerAndVendorAfterWizardApply(1, 0);
    end;

    [Test]
    [HandlerFunctions('DataMigratorsPageHandler,ConfirmBeforeApplyHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure WizardApplyInvalidCustomerAndValidVendor_ConfirmNo_AgainVendor()
    var
        ExcelDataMigrationTest: Codeunit "Excel Data Migration Test";
        DataMigrationWizard: TestPage "Data Migration Wizard";
    begin
        // [SCENARIO 251670] Confirmation message is shown when perform Apply step via data migration wizard in case of
        // [SCENARIO 251670] excel file contains invalid Customer row, valid Vendor row, select both tables to apply (confirm No, Apply only Vendor again)
        Initialize();
        BindSubscription(ExcelDataMigrationTest);

        // [GIVEN] Import excel file including Customer (with invalid Payment Terms Code) and Vendor via data migration wizard
        // [GIVEN] Select both Customer, Vendor tables to apply in the wizard
        // [GIVEN] Perform Next wizard step to start Apply. Confirmation has been shown. Choose No.
        // [GIVEN] Select only Vendor table to apply in the wizard
        // [WHEN] Perform Next wizard step to start Apply
        LibraryVariableStorage.Enqueue(false); // Confirm No
        RunWizardToApplyContinueApplyAgainAndFinish(DataMigrationWizard, true, true, false, true);

        // [THEN] Apply summary message has been shown: "1 tables are processed.\0 errors found.\1 records inserted.\0 records modified."
        Assert.ExpectedMessage(StrSubstNo(ApplySummaryTxt, 1, 0, 1, 0), LibraryVariableStorage.DequeueText());
        // [THEN] The data has been applied and there is a new Vendor
        VerifyCustomerAndVendorAfterWizardApply(0, 1);
    end;

    [Test]
    [HandlerFunctions('DataMigratorsPageHandler,ConfirmBeforeApplyHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure WizardApplyInvalidCustomerAndValidVendor_ConfirmNo_AgainBoth_ConfirmYes()
    var
        ExcelDataMigrationTest: Codeunit "Excel Data Migration Test";
        DataMigrationWizard: TestPage "Data Migration Wizard";
    begin
        // [SCENARIO 251670] Confirmation message is shown when perform Apply step via data migration wizard in case of
        // [SCENARIO 251670] excel file contains invalid Customer row, valid Vendor row, select both tables to apply (confirm No, Apply both Customer and Vendor again, confirm Yes)
        Initialize();
        BindSubscription(ExcelDataMigrationTest);

        // [GIVEN] Import excel file including Customer (with invalid Payment Terms Code) and Vendor via data migration wizard
        // [GIVEN] Select both Customer, Vendor tables to apply in the wizard
        // [GIVEN] Perform Next wizard step to start Apply. Confirmation has been shown. Choose No.
        // [GIVEN] Select only Customer table to apply in the wizard
        // [GIVEN] Perform Next wizard step to start Apply. Confirmation has been shown.
        // [WHEN] Confirm Yes
        LibraryVariableStorage.Enqueue(false); // Confirm No
        LibraryVariableStorage.Enqueue(true); // Confirm Yes
        RunWizardToApplyContinueApplyAgainAndFinish(DataMigrationWizard, true, true, true, true);

        // [THEN] Apply summary message has been shown: "2 tables are processed.\1 errors found.\2 records inserted.\0 records modified."
        Assert.ExpectedMessage(StrSubstNo(ApplySummaryTxt, 2, 1, 2, 0), LibraryVariableStorage.DequeueText());
        // [THEN] The data has been applied and there is a new Customer and Vendor
        VerifyCustomerAndVendorAfterWizardApply(1, 1);
    end;

    [Test]
    [HandlerFunctions('DataMigratorsPageHandler')]
    [Scope('OnPrem')]
    procedure WizardApplyInvalidCustomerAndValidVendor_UnmarkBoth()
    var
        ExcelDataMigrationTest: Codeunit "Excel Data Migration Test";
        DataMigrationWizard: TestPage "Data Migration Wizard";
    begin
        // [SCENARIO 251670] There is no confirmation message when perform Apply step via data migration wizard in case of
        // [SCENARIO 251670] excel file contains invalid Customer row, valid Vendor row, select no tables to apply
        Initialize();
        BindSubscription(ExcelDataMigrationTest);

        // [GIVEN] Import excel file including Customer (with invalid Payment Terms Code) and Vendor via data migration wizard
        // [GIVEN] Select both Customer, Vendor tables to apply in the wizard
        // [WHEN] Perform Next wizard step to start Apply
        RunWizardToApplyAndFinish(DataMigrationWizard, false, false);

        // [THEN] The data has been not applied and there is no Customer and Vendor
        VerifyCustomerAndVendorAfterWizardApply(0, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGLAccountsClearedFromVATPostingSetup()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        CODEUNIT.Run(CODEUNIT::"Data Migration Del G/L Account");
        VATPostingSetup.Reset();
        VATPostingSetup.SetRange("Sales VAT Account", '<>''''');
        Assert.IsTrue(VATPostingSetup.IsEmpty, 'Sales accounts should be cleared from VAT posting setup');
        VATPostingSetup.Reset();
        VATPostingSetup.SetRange("Purchase VAT Account", '<>''''');
        Assert.IsTrue(VATPostingSetup.IsEmpty, 'Purchase accounts should be cleared from VAT posting setup');
        VATPostingSetup.Reset();
        VATPostingSetup.SetRange("Reverse Chrg. VAT Acc.", '<>''''');
        Assert.IsTrue(VATPostingSetup.IsEmpty, 'Reverse accounts should be cleared from VAT posting group');
    end;

    local procedure Initialize()
    var
        ConfigPackage: Record "Config. Package";
        Customer: Record Customer;
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
        Item: Record Item;
        Vendor: Record Vendor;
        ItemLedgerEntry: Record "Item Ledger Entry";
        AssistedSetupTestLibrary: Codeunit "Assisted Setup Test Library";
        GLEntry: Record "G/L Entry";
        GenJournalLine: Record "Gen. Journal Line";
        ItemJournalLine: Record "Item Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        LibraryAzureKVMockMgmt: Codeunit "Library - Azure KV Mock Mgmt.";
    begin
        LibraryVariableStorage.Clear();
        LibraryRapidStart.SetAPIServicesEnabled(false);
        LibraryAzureKVMockMgmt.InitMockAzureKeyvaultSecretProvider();
        LibraryAzureKVMockMgmt.EnsureSecretNameIsAllowed('SmtpSetup');

        ConfigPackage.Init();
        ConfigPackage.SetRange(Code, ExcelDataMigrator.GetPackageCode());
        ConfigPackage.DeleteAll(true);

        AssistedSetupTestLibrary.DeleteAll();
        AssistedSetupTestLibrary.CallOnRegister();

        ContactBusinessRelation.DeleteAll();
        Contact.DeleteAll();
        Customer.DeleteAll();
        Item.DeleteAll();
        ItemLedgerEntry.DeleteAll();
        Vendor.DeleteAll();

        GLEntry.DeleteAll();
        GenJournalLine.DeleteAll();
        CustLedgerEntry.DeleteAll();
        VendLedgerEntry.DeleteAll();
        ItemJournalLine.DeleteAll();
    end;

    local procedure CreateAttachmentWithFileName(FileName: Text)
    var
        Attachment: Record Attachment;
    begin
        Attachment.Init();
        Attachment."No." := LibraryUtility.GetNewRecNo(Attachment, Attachment.FieldNo("No."));
        Attachment."Storage Pointer" := CopyStr(FileName, 1, MaxStrLen(Attachment."Storage Pointer"));
        Attachment.Insert();
    end;

    local procedure GetExcelFileName(): Text[80]
    begin
        exit('\App\Test\Files\QuickBooks\SampleExcelDataMigration.xlsx');
    end;

    local procedure GetBrokenExcelFileName(): Text[80]
    begin
        exit('\App\Test\Files\QuickBooks\SampleExcelDataMigrationWithBrokenRecords.xlsx');
    end;

    local procedure VerifyImportedData(FileName: Text; TableId: Integer)
    var
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageField: Record "Config. Package Field";
        TempExcelBuffer: Record "Excel Buffer" temporary;
        ExcelDataMigrator: Codeunit "Excel Data Migrator";
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        ColumnHeaderRow: Integer;
        FieldID: array[250] of Integer;
    begin
        ConfigPackageField.SetRange("Package Code", ExcelDataMigrator.GetPackageCode());
        ConfigPackageField.SetRange("Table ID", TableId);
        ConfigPackageField.SetRange("Include Field", true);

        ConfigPackageTable.SetRange("Package Code", ExcelDataMigrator.GetPackageCode());
        ConfigPackageTable.SetRange("Table ID", TableId);
        ConfigPackageTable.FindFirst();
        ConfigPackageTable.CalcFields("Table Name");

        ColumnHeaderRow := 3;

        TempExcelBuffer.Reset();
        TempExcelBuffer.DeleteAll();
        TempExcelBuffer.OpenBook(FileName, ConfigPackageTable."Table Name");
        TempExcelBuffer.ReadSheet();
        TempExcelBuffer.SetRange("Row No.", ColumnHeaderRow);

        RecordRef.Open(TableId);
        while true do begin
            if TempExcelBuffer.FindSet() then
                repeat
                    if TempExcelBuffer."Row No." = ColumnHeaderRow then begin
                        ConfigPackageField.SetRange("Field Caption", TempExcelBuffer."Cell Value as Text");
                        ConfigPackageField.FindFirst();
                        FieldID[TempExcelBuffer."Column No."] := ConfigPackageField."Field ID";
                    end else
                        if TempExcelBuffer."Column No." = 1 then
                            GetRecord(RecordRef, TableId, TempExcelBuffer."Cell Value as Text")
                        else begin
                            FieldRef := RecordRef.Field(FieldID[TempExcelBuffer."Column No."]);
                            // We can't verify Inventory field here since it's a flowfield.
                            if FieldRef.Name <> 'Inventory' then
                                Assert.AreEqual(
                                  TempExcelBuffer."Cell Value as Text",
                                  Format(FieldRef.Value),
                                  StrSubstNo(FieldValueErr, FieldRef.Name, ConfigPackageTable."Table Name"));
                        end;
                until TempExcelBuffer.Next() = 0
            else
                exit;

            // Moving to the next row
            TempExcelBuffer.SetRange("Row No.", TempExcelBuffer."Row No." + 1);
        end;
    end;

    local procedure GetRecord(var RecordRef: RecordRef; TableId: Integer; KeyValue: Text)
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Item: Record Item;
    begin
        case TableId of
            DATABASE::Customer:
                begin
                    Customer.Get(KeyValue);
                    RecordRef.Get(Customer.RecordId);
                end;
            DATABASE::Vendor:
                begin
                    Vendor.Get(KeyValue);
                    RecordRef.Get(Vendor.RecordId);
                end;
            DATABASE::Item:
                begin
                    Item.Get(KeyValue);
                    RecordRef.Get(Item.RecordId);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Excel Data Migrator", 'OnUploadFile', '', false, false)]
    local procedure SetExcelFile(var ServerFileName: Text)
    var
        Attachment: Record Attachment;
    begin
        Attachment.FindLast();
        ServerFileName := LibraryUtility.GetInetRoot() + Attachment."Storage Pointer";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Excel Data Migrator", 'OnDownloadTemplate', '', false, false)]
    local procedure HideDialog(var HideDialog: Boolean)
    begin
        HideDialog := true;
    end;

    local procedure ImportExcelFile()
    begin
        ExcelDataMigrator.ImportExcelDataByFileName(LibraryUtility.GetInetRoot() + GetExcelFileName());
    end;

    local procedure ImportAndApplyPackage()
    var
        ConfigPackage: Record "Config. Package";
    begin
        ImportExcelFile();
        ConfigPackage.Init();
        ConfigPackage.Code := ExcelDataMigrator.GetPackageCode();
        LibraryRapidStart.ApplyPackage(ConfigPackage, false);
    end;

    local procedure RunWizardToCompletion(var DataMigrationWizard: TestPage "Data Migration Wizard")
    begin
        CreateAttachmentWithFileName(GetExcelFileName());
        DataMigrationWizard.Trap();
        PAGE.Run(PAGE::"Data Migration Wizard");

        DataMigrationWizard.ActionNext.Invoke();
        // Choose Data Source page
        DataMigrationWizard.Description.Lookup();
        DataMigrationWizard.ActionDownloadTemplate.Invoke();
        // Download the Excel template silently
        DataMigrationWizard.ActionNext.Invoke();
        // Upload Data File page
        DataMigrationWizard.ActionNext.Invoke();
        // Apply Imported Data page
        DataMigrationWizard.ActionShowErrors.Invoke();
        DataMigrationWizard.ActionApply.Invoke();
        // That's it page
        DataMigrationWizard.ActionFinish.Invoke();
    end;

    local procedure RunWizardToApply(var DataMigrationWizard: TestPage "Data Migration Wizard"; CustomerSelected: Boolean; VendorSelected: Boolean)
    begin
        CreateAttachmentWithFileName(GetBrokenExcelFileName());
        DataMigrationWizard.Trap();
        PAGE.Run(PAGE::"Data Migration Wizard");

        DataMigrationWizard.ActionNext.Invoke();
        DataMigrationWizard.Description.Lookup();
        DataMigrationWizard.ActionDownloadTemplate.Invoke(); // Download the Excel template silently
        DataMigrationWizard.ActionNext.Invoke();
        DataMigrationWizard.ActionNext.Invoke(); // Import

        ContinueWizardToApply(DataMigrationWizard, CustomerSelected, VendorSelected);
    end;

    local procedure RunWizardToApplyAndFinish(var DataMigrationWizard: TestPage "Data Migration Wizard"; CustomerSelected: Boolean; VendorSelected: Boolean)
    begin
        RunWizardToApply(DataMigrationWizard, CustomerSelected, VendorSelected);
        DataMigrationWizard.ActionFinish.Invoke();
    end;

    local procedure ContinueWizardToApply(var DataMigrationWizard: TestPage "Data Migration Wizard"; CustomerSelected: Boolean; VendorSelected: Boolean)
    begin
        // Select tables to Apply
        DataMigrationWizard.DataMigrationEntities.FILTER.SetFilter("Table Name", 'Customer');
        DataMigrationWizard.DataMigrationEntities.Selected.SetValue(CustomerSelected);
        DataMigrationWizard.DataMigrationEntities.FILTER.SetFilter("Table Name", 'Vendor');
        DataMigrationWizard.DataMigrationEntities.Selected.SetValue(VendorSelected);
        DataMigrationWizard.DataMigrationEntities.FILTER.SetFilter("Table Name", '');
        DataMigrationWizard.ActionApply.Invoke(); // Apply
    end;

    local procedure RunWizardToApplyContinueApplyAgainAndFinish(var DataMigrationWizard: TestPage "Data Migration Wizard"; CustomerSelected: Boolean; VendorSelected: Boolean; CustomerSelectedAgain: Boolean; VendorSelectedAgain: Boolean)
    begin
        RunWizardToApply(DataMigrationWizard, CustomerSelected, VendorSelected);
        ContinueWizardToApply(DataMigrationWizard, CustomerSelectedAgain, VendorSelectedAgain);
        DataMigrationWizard.ActionFinish.Invoke();
    end;

    local procedure VerifyCustomerAndVendorAfterWizardApply(ExpectedCustomerCount: Integer; ExpectedVendorCount: Integer)
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
    begin
        Assert.RecordCount(Customer, ExpectedCustomerCount);
        Assert.RecordCount(Vendor, ExpectedVendorCount);
        LibraryVariableStorage.AssertEmpty();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DataMigratorsPageHandler(var DataMigrators: TestPage "Data Migrators")
    begin
        DataMigrators.GotoKey(CODEUNIT::"Excel Data Migrator");
        DataMigrators.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ConfigPackageErrorspageHandler(var ConfigPackageErrors: TestPage "Config. Package Errors")
    begin
        ConfigPackageErrors.First();
        ConfigPackageErrors.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmBeforeApplyHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(ValidateErrorsBeforeApplyQst, Question);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;
}

