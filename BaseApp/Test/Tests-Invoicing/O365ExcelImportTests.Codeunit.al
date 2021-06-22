codeunit 138912 "O365 Excel Import Tests"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Invoicing] [Excel Import]
    end;

    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        RefObjectType: Option Customer,Item;
        ActionMustBeDisabledErr: Label 'The action must be switched off';
        IsInitialized: Boolean;
        InvalidColumnCaptionErr: Label 'The column caption is not valid';
        CustomerNotFoundErr: Label 'The customer is not found';
        ItemNotFoundErr: Label 'The item is not found';
        IncorrectFieldValueErr: Label 'Incorrect field %1 value';
        NoDataOnTheExcelSheetTxt: Label 'There is no data in the Excel sheet %1.';
        ImportResultMsg: Label '%1 record(s) sucessfully imported.', Comment = '%1 - number';
        InvalidRecordsQtyErr: Label 'The number of imported records is not valid';
        ColumnNoOverLimitErr: Label 'The Excel column number cannot be greater than %1.', Comment = '%1 - number';
        StartRowNoOverLimitErr: Label 'The start row number cannot be greater than %1.', Comment = '%1 - number';
        ValueIsNotValidDecimalErr: Label '%1 is not a valid decimal.', Comment = '%1 - some value which should be converted to decimal.';

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure ImportCustomersDataSunshine()
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        TempO365FieldExcelMapping: Record "O365 Field Excel Mapping" temporary;
        TempExpectedCustomer: Record Customer temporary;
        O365ExcelImportMgt: Codeunit "O365 Excel Import Management";
        StartRowNo: Integer;
        i: Integer;
        CustomersQty: Integer;
        ImportedRecordsQty: Integer;
    begin
        // [SCENARIO 197382] Customers are created during the Excel data import
        Initialize;

        // [GIVEN] Mock Excel Buffer data with N customers, mock Excel fields mapping
        CustomersQty := LibraryRandom.RandIntInRange(5, 10);
        for i := 1 to CustomersQty do
            CreateCustomer(TempExpectedCustomer);
        MockExcelBufferWithCustomers(TempExcelBuffer, TempO365FieldExcelMapping, TempExpectedCustomer, CustomersQty);
        StartRowNo := 1;

        // [WHEN] Import customers is being run
        ImportedRecordsQty :=
          O365ExcelImportMgt.ImportData(TempExcelBuffer, TempO365FieldExcelMapping, StartRowNo, RefObjectType::Customer);

        // [THEN] Customers have been created
        VerifyImportedCustomers(TempExpectedCustomer);
        // [THEN] The number of imported customers = N
        Assert.AreEqual(CustomersQty, ImportedRecordsQty, InvalidRecordsQtyErr);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure ImportItemsDataSunshine()
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        TempO365FieldExcelMapping: Record "O365 Field Excel Mapping" temporary;
        TempExpectedItem: Record Item temporary;
        O365ExcelImportMgt: Codeunit "O365 Excel Import Management";
        StartRowNo: Integer;
        ItemsQty: Integer;
        i: Integer;
        ImportedRecordsQty: Integer;
    begin
        // [SCENARIO 197382] Items are created during the Excel data import
        Initialize;

        // [GIVEN] Mock Excel Buffer data with N items, mock Excel fields mapping
        ItemsQty := LibraryRandom.RandIntInRange(5, 10);
        for i := 1 to ItemsQty do
            CreateItem(TempExpectedItem);
        MockExcelBufferWithItems(TempExcelBuffer, TempO365FieldExcelMapping, TempExpectedItem, ItemsQty);
        StartRowNo := 1;

        // [WHEN] Import items is being run
        ImportedRecordsQty :=
          O365ExcelImportMgt.ImportData(TempExcelBuffer, TempO365FieldExcelMapping, StartRowNo, RefObjectType::Item);

        // [THEN] Items have been created
        VerifyImportedItems(TempExpectedItem);
        // [THEN] The number of imported items = N
        Assert.AreEqual(ItemsQty, ImportedRecordsQty, InvalidRecordsQtyErr);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure AutomapColumnsSunshine()
    var
        DummyCustomer: Record Customer;
        TempExcelBuffer: Record "Excel Buffer" temporary;
        TempO365FieldExcelMapping: Record "O365 Field Excel Mapping" temporary;
        O365ExcelImportMgt: Codeunit "O365 Excel Import Management";
    begin
        // [SCENARIO 197382] Automapping works if field name = column header name
        Initialize;

        // [GIVEN] Mock headers Excel row for customer table with header Name
        AddValueToExcelBuffer(TempExcelBuffer, 1, 1, 'Name');

        // [GIVEN] Excel mapping buffer for field Name
        AddFieldToMapping(TempO365FieldExcelMapping, DATABASE::Customer, DummyCustomer.FieldNo(Name), 0);

        // [WHEN] Automapping is being executed
        O365ExcelImportMgt.AutomapColumns(TempO365FieldExcelMapping, TempExcelBuffer);

        // [THEN] Excel column 1 mapped to field Name
        VerifyCustomerAutomappedColumn(TempO365FieldExcelMapping, 1);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure AutomapColumnsHeaderInLowerCase()
    var
        DummyCustomer: Record Customer;
        TempExcelBuffer: Record "Excel Buffer" temporary;
        TempO365FieldExcelMapping: Record "O365 Field Excel Mapping" temporary;
        O365ExcelImportMgt: Codeunit "O365 Excel Import Management";
    begin
        // [SCENARIO 197382] Automapping works when column header name in lowercase
        Initialize;

        // [GIVEN] Mock headers Excel row for customer table with header Name
        AddValueToExcelBuffer(TempExcelBuffer, 1, 1, 'name');

        // [GIVEN] Excel mapping buffer for field Name
        AddFieldToMapping(TempO365FieldExcelMapping, DATABASE::Customer, DummyCustomer.FieldNo(Name), 0);

        // [WHEN] Automapping is being executed
        O365ExcelImportMgt.AutomapColumns(TempO365FieldExcelMapping, TempExcelBuffer);

        // [THEN] Excel column 1 mapped to field Name
        VerifyCustomerAutomappedColumn(TempO365FieldExcelMapping, 1);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure AutomapColumnsHeaderInUpperCase()
    var
        DummyCustomer: Record Customer;
        TempExcelBuffer: Record "Excel Buffer" temporary;
        TempO365FieldExcelMapping: Record "O365 Field Excel Mapping" temporary;
        O365ExcelImportMgt: Codeunit "O365 Excel Import Management";
    begin
        // [SCENARIO 197382] Automapping works when column header name in uppercase
        Initialize;

        // [GIVEN] Mock headers Excel row for customer table with header Name
        AddValueToExcelBuffer(TempExcelBuffer, 1, 1, 'NAME');

        // [GIVEN] Excel mapping buffer for field Name
        AddFieldToMapping(TempO365FieldExcelMapping, DATABASE::Customer, DummyCustomer.FieldNo(Name), 0);

        // [WHEN] Automapping is being executed
        O365ExcelImportMgt.AutomapColumns(TempO365FieldExcelMapping, TempExcelBuffer);

        // [THEN] Excel column 1 mapped to field Name
        VerifyCustomerAutomappedColumn(TempO365FieldExcelMapping, 1);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure NextButtonDisabledWhenExcelFileNotLoaded()
    var
        TestPageO365ImportFromExcelWizard: TestPage "O365 Import from Excel Wizard";
    begin
        // [SCENARIO 197382] Buttons Next and Finish are disabled on the first step when Excel file is not loaded
        Initialize;

        // [GIVEN] Wizard page opened
        // [WHEN] Excel file is not loaded
        TestPageO365ImportFromExcelWizard.OpenView;

        // [THEN] Button Next is disabled
        Assert.IsFalse(TestPageO365ImportFromExcelWizard.ActionNext.Enabled, ActionMustBeDisabledErr);
        // [THEN] Button Finish is disabled
        Assert.IsFalse(TestPageO365ImportFromExcelWizard.ActionFinish.Enabled, ActionMustBeDisabledErr);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure NextButtonDisabledWhenStartRowNoZero()
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        O365ImportFromExcelWizard: Page "O365 Import from Excel Wizard";
        TestPageO365ImportFromExcelWizard: TestPage "O365 Import from Excel Wizard";
    begin
        // [SCENARIO 197382] Buttons Next and Finish are disabled on the second step when Start Row No. = 0
        Initialize;

        // [GIVEN] Mock Excel Buffer data
        AddValueToExcelBuffer(TempExcelBuffer, 1, 1, LibraryUtility.GenerateGUID);

        // [GIVEN] Wizard page opened
        // [GIVEN] Mock Excel file loaded
        TestPageO365ImportFromExcelWizard.Trap;
        O365ImportFromExcelWizard.SetParameters(TempExcelBuffer, LibraryUtility.GenerateGUID);
        O365ImportFromExcelWizard.Run;

        // [WHEN] Button Next is being pressed
        TestPageO365ImportFromExcelWizard.ActionNext.Invoke;

        // [GIVEN] Set Start Row No. = 0
        TestPageO365ImportFromExcelWizard.StartRowNo.SetValue(0);

        // [THEN] Next and Finish buttons are disabled
        Assert.IsFalse(TestPageO365ImportFromExcelWizard.ActionNext.Enabled, ActionMustBeDisabledErr);
        Assert.IsFalse(TestPageO365ImportFromExcelWizard.ActionFinish.Enabled, ActionMustBeDisabledErr);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure NextButtonDisabledWhenMappingIsNotSet()
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        TestPageO365ImportFromExcelWizard: TestPage "O365 Import from Excel Wizard";
    begin
        // [SCENARIO 197382] Buttons Next and Finish are disabled on the third step when mapping is not set
        Initialize;

        // [GIVEN] Mock Excel Buffer data
        AddValueToExcelBuffer(TempExcelBuffer, 1, 1, LibraryUtility.GenerateGUID);

        // [GIVEN] Wizard page opened
        // [GIVEN] Mock Excel file loaded
        RunImportCustomersWizardPage(TestPageO365ImportFromExcelWizard, TempExcelBuffer);

        // [GIVEN] Go to the step 2
        TestPageO365ImportFromExcelWizard.ActionNext.Invoke;
        // [GIVEN] Set Start Row No. = 1
        TestPageO365ImportFromExcelWizard.StartRowNo.SetValue(1);
        // [GIVEN] Mapping is not set
        // [WHEN] Button Next is being pressed
        TestPageO365ImportFromExcelWizard.ActionNext.Invoke;

        // [THEN] Next and Finish buttons are disabled
        Assert.IsFalse(TestPageO365ImportFromExcelWizard.ActionNext.Enabled, ActionMustBeDisabledErr);
        Assert.IsFalse(TestPageO365ImportFromExcelWizard.ActionFinish.Enabled, ActionMustBeDisabledErr);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,ExcelColumnsHandler')]
    [Scope('OnPrem')]
    procedure PreviewMappedColumn()
    var
        TempCustomer: Record Customer temporary;
        TempExcelBuffer: Record "Excel Buffer" temporary;
        TestPageO365ImportFromExcelWizard: TestPage "O365 Import from Excel Wizard";
    begin
        // [SCENARIO 197382] Mapped column on step 3 is displayed in the preview page on step 4
        Initialize;

        // [GIVEN] Mock Excel Buffer data with customer CUST
        CreateCustomer(TempCustomer);
        AddCustomerDataToExcelBuffer(TempCustomer, TempExcelBuffer, 1);

        // [GIVEN] Run import customers wizard
        RunImportCustomersWizardPage(TestPageO365ImportFromExcelWizard, TempExcelBuffer);

        // [GIVEN] Go to the step 2
        TestPageO365ImportFromExcelWizard.ActionNext.Invoke;
        // [GIVEN] Set Start Row No. = 1
        TestPageO365ImportFromExcelWizard.StartRowNo.SetValue(1);
        // [GIVEN] Go to the step 3
        TestPageO365ImportFromExcelWizard.ActionNext.Invoke;
        // [GIVEN] Set mapping for Name field
        TestPageO365ImportFromExcelWizard.GotoKey(DATABASE::Customer, TempCustomer.FieldNo(Name));
        // [GIVEN] Lookup column number and select first column
        TestPageO365ImportFromExcelWizard."Excel Column No.".Lookup;

        // [WHEN] Button Next is being pressed to go to the step 4
        TestPageO365ImportFromExcelWizard.ActionNext.Invoke;

        // [THEN] The caption of first column = Name
        Assert.AreEqual(
          TempCustomer.FieldCaption(Name),
          TestPageO365ImportFromExcelWizard.ExcelSheetDataSubPage3.Column1.Caption,
          InvalidColumnCaptionErr);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,ExcelColumnsHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ImportCustomersUsingPage()
    var
        Customer: Record Customer;
        TempCustomer: Record Customer temporary;
        TempExcelBuffer: Record "Excel Buffer" temporary;
        TestPageO365ImportFromExcelWizard: TestPage "O365 Import from Excel Wizard";
    begin
        // [SCENARIO 197382] E2E scenario: import customer using page actions
        Initialize;

        // [GIVEN] Mock Excel Buffer data for customer with name CUST
        CreateCustomer(TempCustomer);
        AddCustomerDataToExcelBuffer(TempCustomer, TempExcelBuffer, 1);

        // [GIVEN] Run import customers wizard
        RunImportCustomersWizardPage(TestPageO365ImportFromExcelWizard, TempExcelBuffer);

        // [GIVEN] Go to the step 2
        TestPageO365ImportFromExcelWizard.ActionNext.Invoke;

        // [GIVEN] Set Start Row No. = 1
        TestPageO365ImportFromExcelWizard.StartRowNo.SetValue(1);
        // [GIVEN] Go to the step 3
        TestPageO365ImportFromExcelWizard.ActionNext.Invoke;
        // [GIVEN] Set mapping for Name field
        TestPageO365ImportFromExcelWizard.GotoKey(DATABASE::Customer, TempCustomer.FieldNo(Name));
        // [GIVEN] Lookup column number and select first column
        TestPageO365ImportFromExcelWizard."Excel Column No.".Lookup;
        // [GIVEN] Go to the step 4
        TestPageO365ImportFromExcelWizard.ActionNext.Invoke;
        // [WHEN] Finish button is being pressed
        LibraryVariableStorage.Enqueue(StrSubstNo(ImportResultMsg, 1));
        TestPageO365ImportFromExcelWizard.ActionFinish.Invoke;

        // [THEN] Customer with name CUST is created
        Customer.SetRange(Name, TempCustomer.Name);
        Assert.IsTrue(Customer.FindFirst, CustomerNotFoundErr);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure DuplicateMapping()
    var
        TempCustomer: Record Customer temporary;
        TempExcelBuffer: Record "Excel Buffer" temporary;
        TestPageO365ImportFromExcelWizard: TestPage "O365 Import from Excel Wizard";
    begin
        // [SCENARIO 197382] When user maps field to the column which has been already mapped then prevous mapping cleared
        Initialize;

        // [GIVEN] Mock Excel Buffer data for customer with name CUST
        CreateCustomer(TempCustomer);
        AddCustomerDataToExcelBuffer(TempCustomer, TempExcelBuffer, 1);

        // [GIVEN] Run import customers wizard
        RunImportCustomersWizardPage(TestPageO365ImportFromExcelWizard, TempExcelBuffer);

        // [GIVEN] Go to the step 2
        TestPageO365ImportFromExcelWizard.ActionNext.Invoke;
        // [GIVEN] Set Start Row No. = 1
        TestPageO365ImportFromExcelWizard.StartRowNo.SetValue(1);
        // [GIVEN] Go to the step 3
        TestPageO365ImportFromExcelWizard.ActionNext.Invoke;
        // [GIVEN] Set mapping for Name field
        TestPageO365ImportFromExcelWizard.GotoKey(DATABASE::Customer, TempCustomer.FieldNo(Name));
        // [GIVEN] Lookup column number and select first column
        TestPageO365ImportFromExcelWizard."Excel Column No.".SetValue('1');

        // [GIVEN] Set mapping for Phone No. field
        TestPageO365ImportFromExcelWizard.GotoKey(DATABASE::Customer, TempCustomer.FieldNo("Phone No."));
        // [WHEN] Lookup column number and select first column again
        TestPageO365ImportFromExcelWizard."Excel Column No.".SetValue('1');

        // [THEN] Mapping is cleared for the field Name (Excel Column No. = 0)
        TestPageO365ImportFromExcelWizard.GotoKey(DATABASE::Customer, TempCustomer.FieldNo(Name));
        TestPageO365ImportFromExcelWizard."Excel Column No.".AssertEquals('0');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure ImportedCustomerCreatedFromTemplate()
    var
        TempExpectedCustomer: Record Customer temporary;
        TempExcelBuffer: Record "Excel Buffer" temporary;
        TempO365FieldExcelMapping: Record "O365 Field Excel Mapping" temporary;
        O365ExcelImportMgt: Codeunit "O365 Excel Import Management";
        StartRowNo: Integer;
    begin
        // [SCENARIO 197382] Import procedure uses customer's template for created customers
        Initialize;

        // [GIVEN] Mock Excel Buffer data with customers, mock Excel fields mapping
        CreateCustomer(TempExpectedCustomer);
        MockExcelBufferWithCustomers(TempExcelBuffer, TempO365FieldExcelMapping, TempExpectedCustomer, 1);
        StartRowNo := 1;

        // [WHEN] Import customer is being run
        O365ExcelImportMgt.ImportData(TempExcelBuffer, TempO365FieldExcelMapping, StartRowNo, RefObjectType::Customer);

        // [THEN] New customer created with template defined in O365SalesInitialSetup."Default Customer Template"
        VerifyCustomerTemplateFields(TempExpectedCustomer);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure ImportedItemCreatedFromTemplate()
    var
        TempExpectedItem: Record Item temporary;
        TempExcelBuffer: Record "Excel Buffer" temporary;
        TempO365FieldExcelMapping: Record "O365 Field Excel Mapping" temporary;
        O365ExcelImportMgt: Codeunit "O365 Excel Import Management";
        StartRowNo: Integer;
    begin
        // [SCENARIO 197382] Import procedure uses item's template for created Items
        Initialize;

        // [GIVEN] Mock Excel Buffer data with iems, mock Excel fields mapping
        CreateItem(TempExpectedItem);
        MockExcelBufferWithItems(TempExcelBuffer, TempO365FieldExcelMapping, TempExpectedItem, 1);
        StartRowNo := 1;

        // [WHEN] Import Item is being run
        O365ExcelImportMgt.ImportData(TempExcelBuffer, TempO365FieldExcelMapping, StartRowNo, RefObjectType::Item);

        // [THEN] New Item created with template defined in O365SalesInitialSetup."Default Item Template"
        VerifyItemTemplateFields(TempExpectedItem);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,MessageHandler')]
    [Scope('OnPrem')]
    procedure ImportEmptySheet()
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        TestPageO365ImportFromExcelWizard: TestPage "O365 Import from Excel Wizard";
        ExcelSheetName: Text[250];
    begin
        // [SCENARIO 197382] When user tries to import empty sheet wizard shows message "There is no data in the Excel sheet XXX"
        Initialize;

        // [GIVEN] Mock empty Excel Buffer data
        ExcelSheetName := LibraryUtility.GenerateGUID;
        // [GIVEN] Run import customers wizard
        RunImportCustomersWizardPageForSpecialSheet(TestPageO365ImportFromExcelWizard, TempExcelBuffer, ExcelSheetName);

        // [WHEN] Button next is being pressed
        // [THEN] Wizard shows message "There is no data in the Excel sheet XXX"
        LibraryVariableStorage.Enqueue(StrSubstNo(NoDataOnTheExcelSheetTxt, ExcelSheetName));
        TestPageO365ImportFromExcelWizard.ActionNext.Invoke;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure InvalidStartRowNumber()
    var
        TempCustomer: Record Customer temporary;
        TempExcelBuffer: Record "Excel Buffer" temporary;
        TestPageO365ImportFromExcelWizard: TestPage "O365 Import from Excel Wizard";
        MaxRowNo: Integer;
        i: Integer;
    begin
        // [SCENARIO 197382] Wizard shows error when user tries to specify the Start row number greater than max existing one
        Initialize;

        // [GIVEN] Mock Excel Buffer data for N customers
        MaxRowNo := LibraryRandom.RandIntInRange(5, 10);
        for i := 1 to MaxRowNo do begin
            CreateCustomer(TempCustomer);
            AddCustomerDataToExcelBuffer(TempCustomer, TempExcelBuffer, i);
        end;

        // [GIVEN] Run import customers wizard
        RunImportCustomersWizardPage(TestPageO365ImportFromExcelWizard, TempExcelBuffer);

        // [GIVEN] Go to the step 2
        TestPageO365ImportFromExcelWizard.ActionNext.Invoke;

        // [WHEN] User is trying to set Start Row No. = N + 1
        asserterror TestPageO365ImportFromExcelWizard.StartRowNo.SetValue(MaxRowNo + 1);

        // [THEN] Wizard shows error The start row number cannot be greater than N
        Assert.ExpectedError(StrSubstNo(StartRowNoOverLimitErr, MaxRowNo));
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure InvalidMappedColumnNumber()
    var
        TempCustomer: Record Customer temporary;
        TempExcelBuffer: Record "Excel Buffer" temporary;
        TestPageO365ImportFromExcelWizard: TestPage "O365 Import from Excel Wizard";
        MaxColumnNo: Integer;
        i: Integer;
    begin
        // [SCENARIO 197382] Wizard shows error when user tries to specify the Excel column number greater than max existing one
        Initialize;

        // [GIVEN] Mock Excel Buffer data for customers with maximum column number of Excel data = N
        for i := 1 to LibraryRandom.RandIntInRange(5, 10) do begin
            CreateCustomer(TempCustomer);
            AddCustomerDataToExcelBuffer(TempCustomer, TempExcelBuffer, i);
        end;
        MaxColumnNo := GetMaxExcelBufferColumnNo(TempExcelBuffer);

        // [GIVEN] Run import customers wizard
        RunImportCustomersWizardPage(TestPageO365ImportFromExcelWizard, TempExcelBuffer);

        // [GIVEN] Go to the step 2
        TestPageO365ImportFromExcelWizard.ActionNext.Invoke;
        // [GIVEN] Set Start Row No. = 1
        TestPageO365ImportFromExcelWizard.StartRowNo.SetValue(1);
        // [GIVEN] Go to the step 3
        TestPageO365ImportFromExcelWizard.ActionNext.Invoke;
        // [GIVEN] Set focus on mapping for Name field
        TestPageO365ImportFromExcelWizard.GotoKey(DATABASE::Customer, TempCustomer.FieldNo(Name));

        // [WHEN] User is trying to set Excel column No. = N + 1
        asserterror TestPageO365ImportFromExcelWizard."Excel Column No.".SetValue(MaxColumnNo + 1);

        // [THEN] Wizard shows error The Excel column number cannot be greater than N
        Assert.ExpectedError(StrSubstNo(ColumnNoOverLimitErr, MaxColumnNo));
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure InvalidUnitPriceValue()
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        TempO365FieldExcelMapping: Record "O365 Field Excel Mapping" temporary;
        TempItem: Record Item temporary;
        O365ExcelImportMgt: Codeunit "O365 Excel Import Management";
        StartRowNo: Integer;
    begin
        // [SCENARIO 199856] Wizard shows error "XXX is not a valid decimal" when user tries to import items with Unit Price which cannot be converted to decimal
        Initialize;

        // [GIVEN] Mock Excel Buffer data with one item, mock Excel fields mapping
        CreateItem(TempItem);
        MockExcelBufferWithItems(TempExcelBuffer, TempO365FieldExcelMapping, TempItem, 1);
        StartRowNo := 1;

        // [GIVEN] Mock Excel Buffer Unit Price with text value
        TempExcelBuffer.Get(1, 2);
        TempExcelBuffer."Cell Value as Text" := LibraryUtility.GenerateGUID;
        TempExcelBuffer.Modify();

        // [WHEN] Import items is being run
        asserterror O365ExcelImportMgt.ImportData(TempExcelBuffer, TempO365FieldExcelMapping, StartRowNo, RefObjectType::Item);

        // [THEN] Wizard shows error message: XXX is not a valid decimal
        Assert.ExpectedError(StrSubstNo(ValueIsNotValidDecimalErr, TempExcelBuffer."Cell Value as Text"));
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear;
        if IsInitialized then
            exit;

        CreateO365InitialSetup;
        EnableInvoicingAppArea;
        IsInitialized := true;
    end;

    local procedure MockExcelBufferWithCustomers(var ExcelBuffer: Record "Excel Buffer"; var O365FieldExcelMapping: Record "O365 Field Excel Mapping"; var Customer: Record Customer; CustomersQty: Integer)
    var
        i: Integer;
    begin
        MockCustomerFieldMappingSimple(O365FieldExcelMapping);
        for i := 1 to CustomersQty do begin
            if i = 1 then
                Customer.FindFirst
            else
                Customer.Next;

            AddCustomerDataToExcelBuffer(Customer, ExcelBuffer, i);
        end;
    end;

    local procedure MockExcelBufferWithItems(var ExcelBuffer: Record "Excel Buffer"; var O365FieldExcelMapping: Record "O365 Field Excel Mapping"; var Item: Record Item; ItemsQty: Integer)
    var
        i: Integer;
    begin
        MockItemFieldMappingSimple(O365FieldExcelMapping);
        for i := 1 to ItemsQty do begin
            if i = 1 then
                Item.FindFirst
            else
                Item.Next;
            AddValueToExcelBuffer(ExcelBuffer, i, 1, Item.Description);
            AddValueToExcelBuffer(ExcelBuffer, i, 2, Format(Item."Unit Price"));
        end;
    end;

    local procedure MockCustomerFieldMappingSimple(var O365FieldExcelMapping: Record "O365 Field Excel Mapping")
    var
        DummyCustomer: Record Customer;
    begin
        AddFieldToMapping(O365FieldExcelMapping, DATABASE::Customer, DummyCustomer.FieldNo(Name), 1);
        AddFieldToMapping(O365FieldExcelMapping, DATABASE::Customer, DummyCustomer.FieldNo("Phone No."), 2);
        AddFieldToMapping(O365FieldExcelMapping, DATABASE::Customer, DummyCustomer.FieldNo("E-Mail"), 3);
        AddFieldToMapping(O365FieldExcelMapping, DATABASE::Customer, DummyCustomer.FieldNo(Address), 4);
        AddFieldToMapping(O365FieldExcelMapping, DATABASE::Customer, DummyCustomer.FieldNo(City), 5);
        AddFieldToMapping(O365FieldExcelMapping, DATABASE::Customer, DummyCustomer.FieldNo("Post Code"), 6);
        AddFieldToMapping(O365FieldExcelMapping, DATABASE::Customer, DummyCustomer.FieldNo(County), 7);
    end;

    local procedure MockItemFieldMappingSimple(var O365FieldExcelMapping: Record "O365 Field Excel Mapping")
    var
        DummyItem: Record Item;
    begin
        AddFieldToMapping(O365FieldExcelMapping, DATABASE::Item, DummyItem.FieldNo(Description), 1);
        AddFieldToMapping(O365FieldExcelMapping, DATABASE::Item, DummyItem.FieldNo("Unit Price"), 2);
    end;

    local procedure AddFieldToMapping(var O365FieldExcelMapping: Record "O365 Field Excel Mapping"; TableID: Integer; FieldID: Integer; ExcelColumnNo: Integer)
    begin
        with O365FieldExcelMapping do begin
            Init;
            "Table ID" := TableID;
            "Field ID" := FieldID;
            "Excel Column No." := ExcelColumnNo;
            Insert;
        end;
    end;

    local procedure AddValueToExcelBuffer(var ExcelBuffer: Record "Excel Buffer"; RowNo: Integer; ColumnNo: Integer; CellValue: Text)
    begin
        ExcelBuffer.Init();
        ExcelBuffer."Row No." := RowNo;
        ExcelBuffer."Column No." := ColumnNo;
        ExcelBuffer."Cell Value as Text" := CopyStr(CellValue, 1, MaxStrLen(ExcelBuffer."Cell Value as Text"));
        ExcelBuffer.Insert();
    end;

    local procedure AddCustomerDataToExcelBuffer(Customer: Record Customer; var ExcelBuffer: Record "Excel Buffer"; RowNo: Integer)
    begin
        AddValueToExcelBuffer(ExcelBuffer, RowNo, 1, Customer.Name);
        AddValueToExcelBuffer(ExcelBuffer, RowNo, 2, Customer."Phone No.");
        AddValueToExcelBuffer(ExcelBuffer, RowNo, 3, Customer."E-Mail");
        AddValueToExcelBuffer(ExcelBuffer, RowNo, 4, Customer.Address);
        AddValueToExcelBuffer(ExcelBuffer, RowNo, 5, Customer.City);
        AddValueToExcelBuffer(ExcelBuffer, RowNo, 6, Customer."Post Code");
        AddValueToExcelBuffer(ExcelBuffer, RowNo, 7, Customer.County);
    end;

    local procedure CreateCustomer(var Customer: Record Customer)
    begin
        with Customer do begin
            Init;
            "No." := LibraryUtility.GenerateRandomCode(FieldNo("No."), DATABASE::Customer);
            Name := LibraryUtility.GenerateRandomCode(FieldNo(Name), DATABASE::Customer);
            "Phone No." := LibraryUtility.GenerateRandomCode(FieldNo("Phone No."), DATABASE::Customer);
            "E-Mail" := LibraryUtility.GenerateRandomEmail;
            Address := LibraryUtility.GenerateRandomCode(FieldNo(Address), DATABASE::Customer);
            City := LibraryUtility.GenerateRandomCode(FieldNo(City), DATABASE::Customer);
            "Post Code" := LibraryUtility.GenerateRandomCode(FieldNo("Post Code"), DATABASE::Customer);
            County := LibraryUtility.GenerateRandomCode(FieldNo(County), DATABASE::Customer);
            Insert;
        end;
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        with Item do begin
            Init;
            "No." := LibraryUtility.GenerateRandomCode(FieldNo("No."), DATABASE::Item);
            Description := LibraryUtility.GenerateRandomCode(FieldNo("No."), DATABASE::Item);
            "Unit Price" := LibraryRandom.RandDec(100, 2);
            Insert;
        end;
    end;

    local procedure CreateO365InitialSetup()
    begin
        DeleteAllConfigTemplatesForTableID(DATABASE::Customer);
        DeleteAllConfigTemplatesForTableID(DATABASE::Item);
        with O365SalesInitialSetup do begin
            if not Get then begin
                Init;
                Insert;
            end;
            Validate("Default Customer Template", CreateSimpleCustomerTemplate);
            Validate("Default Item Template", CreateSimpleItemTemplate);
            Modify;
        end;
    end;

    local procedure CreateSimpleCustomerTemplate(): Code[10]
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        CustomerPostingGroup: Record "Customer Posting Group";
        PaymentTerms: Record "Payment Terms";
        FinanceChargeTerms: Record "Finance Charge Terms";
        DummyCustomer: Record Customer;
    begin
        ConfigTemplateHeader.Code :=
          LibraryUtility.GenerateRandomCode(ConfigTemplateHeader.FieldNo(Code), DATABASE::"Config. Template Header");
        ConfigTemplateHeader."Table ID" := DATABASE::Customer;
        ConfigTemplateHeader.Insert();

        if CustomerPostingGroup.FindFirst then
            CreateTemplateLine(
              ConfigTemplateHeader,
              DummyCustomer.FieldNo("Customer Posting Group"),
              CustomerPostingGroup.Code);

        if PaymentTerms.FindFirst then
            CreateTemplateLine(
              ConfigTemplateHeader,
              DummyCustomer.FieldNo("Payment Terms Code"),
              PaymentTerms.Code);

        if FinanceChargeTerms.FindFirst then
            CreateTemplateLine(
              ConfigTemplateHeader,
              DummyCustomer.FieldNo("Fin. Charge Terms Code"),
              FinanceChargeTerms.Code);

        exit(ConfigTemplateHeader.Code);
    end;

    local procedure CreateSimpleItemTemplate(): Code[10]
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        DummyItem: Record Item;
        InventoryPostingGroup: Record "Inventory Posting Group";
    begin
        ConfigTemplateHeader.Code :=
          LibraryUtility.GenerateRandomCode(ConfigTemplateHeader.FieldNo(Code), DATABASE::"Config. Template Header");
        ConfigTemplateHeader."Table ID" := DATABASE::Item;
        ConfigTemplateHeader.Insert();

        if InventoryPostingGroup.FindFirst then
            CreateTemplateLine(
              ConfigTemplateHeader,
              DummyItem.FieldNo("Inventory Posting Group"),
              InventoryPostingGroup.Code);

        exit(ConfigTemplateHeader.Code);
    end;

    local procedure CreateTemplateLine(ConfigTemplateHeader: Record "Config. Template Header"; FieldID: Integer; FieldValue: Text)
    var
        ConfigTemplateLine: Record "Config. Template Line";
        NextLineNo: Integer;
    begin
        ConfigTemplateLine.SetRange("Data Template Code", ConfigTemplateHeader.Code);
        if ConfigTemplateLine.FindLast then;
        NextLineNo := ConfigTemplateLine."Line No." + 10000;

        ConfigTemplateLine.Init();
        ConfigTemplateLine.Validate("Data Template Code", ConfigTemplateHeader.Code);
        ConfigTemplateLine.Validate("Line No.", NextLineNo);
        ConfigTemplateLine.Validate(Type, ConfigTemplateLine.Type::Field);
        ConfigTemplateLine.Validate("Table ID", ConfigTemplateHeader."Table ID");
        ConfigTemplateLine.Validate("Field ID", FieldID);
        ConfigTemplateLine."Default Value" := CopyStr(FieldValue, 1, MaxStrLen(ConfigTemplateLine."Default Value"));
        ConfigTemplateLine.Insert(true);
    end;

    local procedure DeleteAllConfigTemplatesForTableID(TableID: Integer)
    var
        ConfigTemplateHeader: Record "Config. Template Header";
    begin
        ConfigTemplateHeader.SetRange("Table ID", TableID);
        ConfigTemplateHeader.DeleteAll();
    end;

    local procedure EnableInvoicingAppArea()
    var
        ApplicationAreaSetup: Record "Application Area Setup";
    begin
        ApplicationAreaSetup.DeleteAll();
        ApplicationAreaSetup.Invoicing := true;
        ApplicationAreaSetup.Insert();
    end;

    local procedure GetMaxExcelBufferColumnNo(var ExcelBuffer: Record "Excel Buffer"): Integer
    begin
        ExcelBuffer.SetRange("Row No.", 1);
        if ExcelBuffer.FindLast then;
        exit(ExcelBuffer."Column No.");
    end;

    local procedure RunImportCustomersWizardPage(var TestPageO365ImportFromExcelWizard: TestPage "O365 Import from Excel Wizard"; var ExcelBuffer: Record "Excel Buffer")
    begin
        RunImportCustomersWizardPageForSpecialSheet(TestPageO365ImportFromExcelWizard, ExcelBuffer, LibraryUtility.GenerateGUID);
    end;

    local procedure RunImportCustomersWizardPageForSpecialSheet(var TestPageO365ImportFromExcelWizard: TestPage "O365 Import from Excel Wizard"; var ExcelBuffer: Record "Excel Buffer"; ExcelSheetName: Text[250])
    var
        O365ImportFromExcelWizard: Page "O365 Import from Excel Wizard";
    begin
        TestPageO365ImportFromExcelWizard.Trap;
        O365ImportFromExcelWizard.PrepareCustomerImportData;
        O365ImportFromExcelWizard.SetParameters(ExcelBuffer, ExcelSheetName);
        O365ImportFromExcelWizard.Run;
    end;

    local procedure VerifyImportedCustomers(var ExpectedCustomer: Record Customer)
    begin
        if ExpectedCustomer.FindSet then
            repeat
                VerifyImportedCustomer(ExpectedCustomer);
            until ExpectedCustomer.Next = 0;
    end;

    local procedure VerifyImportedCustomer(var ExpectedCustomer: Record Customer)
    var
        Customer: Record Customer;
    begin
        Customer.SetRange(Name, ExpectedCustomer.Name);
        Assert.IsTrue(Customer.FindFirst, CustomerNotFoundErr);
        Assert.AreEqual(
          ExpectedCustomer.Name,
          Customer.Name,
          StrSubstNo(IncorrectFieldValueErr, Customer.FieldName(Name)));
        Assert.AreEqual(
          ExpectedCustomer."Phone No.",
          Customer."Phone No.",
          StrSubstNo(IncorrectFieldValueErr, Customer.FieldName("Phone No.")));
        Assert.AreEqual(
          ExpectedCustomer."E-Mail",
          Customer."E-Mail",
          StrSubstNo(IncorrectFieldValueErr, Customer.FieldName("E-Mail")));
        Assert.AreEqual(
          ExpectedCustomer.Address,
          Customer.Address,
          StrSubstNo(IncorrectFieldValueErr, Customer.FieldName(Address)));
    end;

    local procedure VerifyImportedItems(var ExpectedItem: Record Item)
    var
        Item: Record Item;
    begin
        if ExpectedItem.FindSet then
            repeat
                Item.SetRange(Description, ExpectedItem.Description);
                Assert.IsTrue(Item.FindFirst, ItemNotFoundErr);
                Assert.AreEqual(
                  ExpectedItem."Unit Price",
                  Item."Unit Price",
                  StrSubstNo(IncorrectFieldValueErr, Item.FieldName("Unit Price")));
            until ExpectedItem.Next = 0;
    end;

    local procedure VerifyCustomerAutomappedColumn(var O365FieldExcelMapping: Record "O365 Field Excel Mapping"; ExpectedColumnNo: Integer)
    begin
        O365FieldExcelMapping.TestField("Excel Column No.", ExpectedColumnNo);
    end;

    local procedure VerifyCustomerTemplateFields(var ExpectedCustomer: Record Customer)
    var
        Customer: Record Customer;
        ConfigTemplateLine: Record "Config. Template Line";
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        Customer.SetRange(Name, ExpectedCustomer.Name);
        Customer.FindFirst;
        RecRef.GetTable(Customer);

        ConfigTemplateLine.SetRange("Data Template Code", O365SalesInitialSetup."Default Customer Template");
        ConfigTemplateLine.FindSet;
        repeat
            FieldRef := RecRef.Field(ConfigTemplateLine."Field ID");
            Assert.AreEqual(
              Format(ConfigTemplateLine."Default Value"),
              Format(FieldRef.Value),
              StrSubstNo(IncorrectFieldValueErr, ConfigTemplateLine."Field Name"));
        until ConfigTemplateLine.Next = 0;
    end;

    local procedure VerifyItemTemplateFields(var ExpectedItem: Record Item)
    var
        Item: Record Item;
        ConfigTemplateLine: Record "Config. Template Line";
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        Item.SetRange(Description, ExpectedItem.Description);
        Item.FindFirst;
        RecRef.GetTable(Item);

        ConfigTemplateLine.SetRange("Data Template Code", O365SalesInitialSetup."Default Item Template");
        ConfigTemplateLine.FindSet;
        repeat
            FieldRef := RecRef.Field(ConfigTemplateLine."Field ID");
            Assert.AreEqual(
              Format(ConfigTemplateLine."Default Value"),
              Format(FieldRef.Value),
              StrSubstNo(IncorrectFieldValueErr, ConfigTemplateLine."Field Name"));
        until ConfigTemplateLine.Next = 0;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ExcelColumnsHandler(var O365ExcelColumns: TestPage "O365 Excel Columns")
    begin
        // Select first column and press OK
        O365ExcelColumns.First;
        O365ExcelColumns.OK.Invoke;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText, Message);
    end;

    [SendNotificationHandler(true)]
    [Scope('OnPrem')]
    procedure VerifyNoNotificationsAreSend(var TheNotification: Notification): Boolean
    begin
        Assert.Fail('No notification should be thrown.');
    end;
}

