codeunit 139162 "CRM Integration Mgt Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [CRM Integration]
    end;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryCRMIntegration: Codeunit "Library - CRM Integration";
        LibraryPriceCalculation: Codeunit "Library - Price Calculation";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
        IdentityManagement: Codeunit "Identity Management";
        CDSIntegrationMgt: Codeunit "CDS Integration Mgt.";
        ConfirmStartCouplingReply: Boolean;
        CRMCouplingPageDoCancel: Boolean;
        IsInitialized: Boolean;
        StatusMustBeActiveErr: Label 'Status must be equal to ''Active''';
        BlockedMustBeNoErr: Label 'Blocked must be equal to ''No''';
        SyncNowScheduledMsg: Label 'The synchronization has been scheduled.';
        SyncNowSkippedMsg: Label 'The synchronization has been skipped. The Customer record is already coupled.';
        MultipleSyncStartedMsg: Label 'The synchronization has been scheduled for 2 of 2 records. 0 records failed. 0 records were skipped.';
        CurrencyPriceListNameTxt: Label 'Price List in %1', Comment = '%1 - currency code';
        RecordMustBeCoupledErr: Label '%1 %2 must be coupled to a %3 record.', Comment = '%1 = table caption, %2 = primary key value, %3 = CRM Table caption';

    [Test]
    [HandlerFunctions('ConfirmStartCoupling')]
    [Scope('OnPrem')]
    procedure ShowCoupleCRMEntityAsksIfNotCoupled()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [CRM Integration Management]
        // [SCENARIO] ShowCRMEntityFromRecordID() asks the user to create missing customer coupling
        // [GIVEN] A customer not coupled to a CRM account
        Initialize;
        LibrarySales.CreateCustomer(Customer);
        LibraryCRMIntegration.CreateIntegrationRecord(CreateGuid, DATABASE::Customer, Customer.RecordId);
        ConfirmStartCouplingReply := false;

        // [WHEN] Show CRM Entity is invoked
        CRMIntegrationManagement.ShowCRMEntityFromRecordID(Customer.RecordId);

        // [THEN] NAV asks Susan if she wants to create the missing NAVcustomer/CRMAccount coupling
        // handled by ConfirmStartCoupling
    end;

    [Test]
    [HandlerFunctions('ConfirmStartCoupling,CoupleCustomerPage')]
    [Scope('OnPrem')]
    procedure ShowCoupledCRMEntityStartsCouplingIfNotCoupled()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [CRM Integration Management]
        // [SCENARIO] ShowCRMEntityFromRecordID() starts coupling if not coupled
        Initialize;
        ResetDefaultCRMSetupConfiguration;
        LibraryCRMIntegration.RegisterTestTableConnection;

        LibrarySales.CreateCustomer(Customer);
        LibraryCRMIntegration.CreateIntegrationRecord(CreateGuid, DATABASE::Customer, Customer.RecordId);

        ConfirmStartCouplingReply := true;
        CRMCouplingPageDoCancel := false;
        CRMIntegrationManagement.ShowCRMEntityFromRecordID(Customer.RecordId);
    end;

    [Test]
    [HandlerFunctions('ConfirmStartCoupling,CoupleCustomerPage')]
    [Scope('OnPrem')]
    procedure ShowCoupledCRMEntityReturnsIfCouplingIsCancelled()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [CRM Integration Management]
        // [SCENARIO] ShowCRMEntityFromRecordID() exits if coupling is cancelled
        Initialize;
        ResetDefaultCRMSetupConfiguration;
        LibraryCRMIntegration.RegisterTestTableConnection;

        LibrarySales.CreateCustomer(Customer);
        LibraryCRMIntegration.CreateIntegrationRecord(CreateGuid, DATABASE::Customer, Customer.RecordId);

        ConfirmStartCouplingReply := true;
        CRMCouplingPageDoCancel := true;
        CRMIntegrationManagement.ShowCRMEntityFromRecordID(Customer.RecordId);
    end;

    [Test]
    [HandlerFunctions('CRMHyperlinkHandler')]
    [Scope('OnPrem')]
    procedure ShowCoupledCRMEntityOpensHyperlinkIfCoupled()
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
    begin
        // [FEATURE] [CRM Integration Management] [Customer]
        // [SCENARIO] ShowCRMEntityFromRecordID() opens a hyperlink if coupled
        Initialize;

        LibraryCRMIntegration.CreateCRMConnectionSetup('', 'host', true);

        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        CRMIntegrationManagement.ShowCRMEntityFromRecordID(Customer.RecordId);
    end;

    [Test]
    [HandlerFunctions('ConfirmStartCoupling')]
    [Scope('OnPrem')]
    procedure DontShowCoupledCRMEntityIfTableNotMapped()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [CRM Integration Management]
        // [SCENARIO] ShowCRMEntityFromRecordID() starts coupling but throws an error if a table is not mapped
        Initialize;
        LibraryCRMIntegration.RegisterTestTableConnection;

        LibrarySales.CreateCustomer(Customer);
        LibraryCRMIntegration.CreateIntegrationRecord(CreateGuid, DATABASE::Customer, Customer.RecordId);

        ConfirmStartCouplingReply := true;
        asserterror CRMIntegrationManagement.ShowCRMEntityFromRecordID(Customer.RecordId);
        Assert.ExpectedError('There is no Integration Table Mapping within the filter.');
    end;

    [Test]
    [HandlerFunctions('SyncStartedSkippedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CreateNewRecordInCRM()
    var
        Customer: Record Customer;
        FilteredCustomer: Record Customer;
        IntegrationTableMapping: Record "Integration Table Mapping";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CRMSystemuser: Record "CRM Systemuser";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMAccount: Record "CRM Account";
        CoupledCRMIDBefore: Guid;
        NumIntegrationRecordsBefore: Integer;
        NumAccountsBefore: Integer;
        JobQueueEntryID: Guid;
    begin
        // [FEATURE] [CRM Integration Management] [Customer]
        // [SCENARIO] CreateNewRecordsInCRM() creates a new record in CRM but skips the already coupled NAV record.
        Initialize;
        LibraryVariableStorage.Clear;
        SetupCRM;

        // [GIVEN] A valid CRM integration setup
        // [GIVEN] A Customer coupled to an Account
        LibraryCRMIntegration.CreateCoupledSalespersonAndSystemUser(SalespersonPurchaser, CRMSystemuser);
        LibrarySales.CreateCustomer(Customer);
        Customer."Salesperson Code" := SalespersonPurchaser.Code;
        Customer.Modify();
        NumIntegrationRecordsBefore := CRMIntegrationRecord.Count();
        NumAccountsBefore := CRMAccount.Count();

        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask;
        LibraryVariableStorage.Enqueue(SyncNowScheduledMsg);
        CRMIntegrationManagement.CreateNewRecordsInCRM(Customer.RecordId);
        // Executing the Sync Job
        FilteredCustomer.SetRange("No.", Customer."No.");
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::Customer, FilteredCustomer.GetView, IntegrationTableMapping);

        Assert.AreEqual(NumIntegrationRecordsBefore + 1, CRMIntegrationRecord.Count,
          'When creating a CRM Account using an uncoupled Customer, an integration record should be created.');
        Assert.AreEqual(NumAccountsBefore + 1, CRMAccount.Count,
          'When creating a CRM Account from an uncoupled Customer, a new CRM Account should be created');

        // [WHEN] The coupled Customer is used to create another new Account in CRM
        NumIntegrationRecordsBefore := CRMIntegrationRecord.Count();
        NumAccountsBefore := CRMAccount.Count();
        CRMIntegrationRecord.FindIDFromRecordID(Customer.RecordId, CoupledCRMIDBefore);
        LibraryVariableStorage.Enqueue(SyncNowSkippedMsg);
        CRMIntegrationManagement.CreateNewRecordsInCRM(Customer.RecordId);

        // [THEN] Notification: "Sync is skipped"
        // handled by SyncStartedSkippedNotificationHandler
        // [THEN] Scheduling did not happen, temporary mapping record is not created
        asserterror
          JobQueueEntryID :=
            LibraryCRMIntegration.RunJobQueueEntry(
              DATABASE::Customer, FilteredCustomer.GetView, IntegrationTableMapping);
        Assert.ExpectedError('Table Mapping is not found');
        // [THEN] A new Account should not be created
        Assert.AreEqual(NumAccountsBefore, CRMAccount.Count,
          'When creating a CRM Account using an already coupled Customer, a new CRM Account should not be created');
        // [THEN] The old coupling should not be changed
        Assert.AreEqual(NumIntegrationRecordsBefore, CRMIntegrationRecord.Count,
          'When creating a CRM Account using an already coupled Customer, the old integration record should not be changed.');
        Assert.IsTrue(
          CRMIntegrationRecord.FindIDFromRecordID(Customer.RecordId, CoupledCRMIDBefore),
          'When creating a CRM Account using an already coupled Customer, an integration record should not be chnaged.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetNoOfCRMCases()
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
    begin
        // [FEATURE] [CRM Integration Management] [Case]
        // [SCENARIO] GetNoOfCRMCases() returns a number of cases coupled to a CRM account
        // [GIVEN] A valid CRM integration setup
        // [GIVEN] A CRM customer having a number of related CRM cases
        Initialize;
        LibraryCRMIntegration.ConfigureCRM;
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        LibraryCRMIntegration.AddCRMCaseToCRMAccount(CRMAccount);
        LibraryCRMIntegration.AddCRMCaseToCRMAccount(CRMAccount);
        LibraryCRMIntegration.AddCRMCaseToCRMAccount(CRMAccount);
        LibraryCRMIntegration.AddCRMCaseToCRMAccount(CRMAccount);

        // [WHEN] GetNoOfCRMCases is invoked
        // [THEN] The correct number of associated CRM cases is returned
        Assert.AreEqual(4, CRMIntegrationManagement.GetNoOfCRMCases(Customer), 'Incorrect number of CRM cases');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetNoOfCRMOpportunities()
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
    begin
        // [FEATURE] [CRM Integration Management] [Opportunity]
        // [SCENARIO] GetNoOfCRMOpportunities() returns a number of opportunities coupled to a CRM account
        // [GIVEN] A valid CRM integration setup
        // [GIVEN] A CRM customer having a number of related CRM opportunities
        Initialize;
        LibraryCRMIntegration.ConfigureCRM;
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        LibraryCRMIntegration.AddCRMOpportunityToCRMAccount(CRMAccount);
        LibraryCRMIntegration.AddCRMOpportunityToCRMAccount(CRMAccount);

        // [WHEN] GetNoOfCRMOpportunities is invoked
        // [THEN] The correct number of associated CRM opportunities is returned
        Assert.AreEqual(2, CRMIntegrationManagement.GetNoOfCRMOpportunities(Customer), 'Incorrect number of CRM opportunities');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetNoOfCRMQuotes()
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
    begin
        // [FEATURE] [CRM Integration Management] [Quote]
        // [SCENARIO] GetNoOfCRMQuotes() return a number of quotes coupled to a CRM account
        // [GIVEN] A valid CRM integration setup
        // [GIVEN] A CRM customer having a number of related CRM quotes
        Initialize;
        LibraryCRMIntegration.ConfigureCRM;
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        LibraryCRMIntegration.AddCRMQuoteToCRMAccount(CRMAccount);
        LibraryCRMIntegration.AddCRMQuoteToCRMAccount(CRMAccount);
        LibraryCRMIntegration.AddCRMQuoteToCRMAccount(CRMAccount);

        // [WHEN] GetNoOfCRMQuotes is invoked
        // [THEN] The correct number of associated CRM quotes is returned
        Assert.AreEqual(3, CRMIntegrationManagement.GetNoOfCRMQuotes(Customer), 'Incorrect number of CRM quotes');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultTableMappingCurrency()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // [FEATURE] [Table Mapping] [Currency] [Direction]
        Initialize;
        ResetDefaultCRMSetupConfiguration;
        // [WHEN] Find Integration Table Mapping for "Currency"
        // [THEN] Mapped to "CRM Transactioncurrency", Direction is "To Integration Table",
        // [THEN] no "Table Filter", no "Integration Table Filter", "Synch. Only Coupled Records" is Yes
        VerifyTableMapping(
          DATABASE::Currency, DATABASE::"CRM Transactioncurrency", IntegrationTableMapping.Direction::ToIntegrationTable,
          '', '', true)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultTableMappingCustomer()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CDSCompany: Record "CDS Company";
        ExpectedIntTableFilter: Text;
    begin
        // [FEATURE] [Table Mapping] [Customer] [Direction]
        Initialize;
        ResetDefaultCRMSetupConfiguration;
        // [WHEN] Find Integration Table Mapping for "Customer"
        // [THEN] Mapped to "CRM Account", Direction is "Bidirectional",
        // [THEN] "Table Filter" is 'Blocked' is ' ', "Integration Table Filter" is 'Active Customer', "Synch. Only Coupled Records" is Yes
        CDSIntegrationMgt.GetCDSCompany(CDSCompany);
        ExpectedIntTableFilter := StrSubstNo('VERSION(1) SORTING(Field1) WHERE(Field6=1(3),Field54=1(0),Field202=1(%1|{00000000-0000-0000-0000-000000000000}))', Format(CDSCompany.CompanyId));
        VerifyTableMapping(
          DATABASE::Customer, DATABASE::"CRM Account", IntegrationTableMapping.Direction::Bidirectional,
          'VERSION(1) SORTING(Field1) WHERE(Field39=1(0))', ExpectedIntTableFilter, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultTableMappingContact()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CDSCompany: Record "CDS Company";
        ExpectedIntTableFilter: Text;
    begin
        // [FEATURE] [Table Mapping] [Contact] [Direction]
        Initialize;
        ResetDefaultCRMSetupConfiguration;
        // [WHEN] Find Integration Table Mapping for "Contact"
        // [THEN] Mapped to "CRM Contact", Direction is "Bidirectional",
        // [THEN] "Table Filter" is 'Type' is 'Person', "Integration Table Filter" is 'Active Contact', "Synch. Only Coupled Records" is Yes
        CDSIntegrationMgt.GetCDSCompany(CDSCompany);
        ExpectedIntTableFilter := StrSubstNo('VERSION(1) SORTING(Field1) WHERE(Field71=1(0),Field134=1(<>{00000000-0000-0000-0000-000000000000}),Field140=1(1),Field192=1(%1|{00000000-0000-0000-0000-000000000000}))', Format(CDSCompany.CompanyId));
        VerifyTableMapping(
          DATABASE::Contact, DATABASE::"CRM Contact", IntegrationTableMapping.Direction::Bidirectional,
          'VERSION(1) SORTING(Field1) WHERE(Field5050=1(1),Field5051=1(<>''''))', ExpectedIntTableFilter, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultTableMappingVendor()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CDSCompany: Record "CDS Company";
        ExpectedIntTableFilter: Text;
    begin
        // [FEATURE] [Table Mapping] [Customer] [Direction]
        Initialize;
        ResetDefaultCRMSetupConfiguration;
        // [WHEN] Find Integration Table Mapping for "Vendor"
        // [THEN] Mapped to "CRM Account", Direction is "Bidirectional",
        // [THEN] "Table Filter" is 'Blocked' is ' ', "Integration Table Filter" is 'Active Vendor', "Synch. Only Coupled Records" is Yes
        CDSIntegrationMgt.GetCDSCompany(CDSCompany);
        ExpectedIntTableFilter := StrSubstNo('VERSION(1) SORTING(Field1) WHERE(Field6=1(11),Field54=1(0),Field202=1(%1|{00000000-0000-0000-0000-000000000000}))', Format(CDSCompany.CompanyId));
        VerifyTableMapping(
          DATABASE::Vendor, DATABASE::"CRM Account", IntegrationTableMapping.Direction::Bidirectional,
          'VERSION(1) SORTING(Field1) WHERE(Field39=1(0))', ExpectedIntTableFilter, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultTableMappingItem()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CDSCompany: Record "CDS Company";
        ExpectedIntTableFilter: Text;
    begin
        // [FEATURE] [Table Mapping] [Customer] [Direction]
        Initialize;
        ResetDefaultCRMSetupConfiguration;
        // [WHEN] Find Integration Table Mapping for "Item"
        // [THEN] Mapped to "CRM Account", Direction is "Bidirectional",
        // [THEN] "Synch. Only Coupled Records" is Yes
        CDSIntegrationMgt.GetCDSCompany(CDSCompany);
        ExpectedIntTableFilter := StrSubstNo('VERSION(1) SORTING(Field1) WHERE(Field8=1(0),Field27=1(0),Field62=1(%1|{00000000-0000-0000-0000-000000000000}))', Format(CDSCompany.CompanyId));
        VerifyTableMapping(
          DATABASE::Item, DATABASE::"CRM Product", IntegrationTableMapping.Direction::Bidirectional,
          'VERSION(1) SORTING(Field1) WHERE(Field54=1(0))', ExpectedIntTableFilter, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultTableMappingResource()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CDSCompany: Record "CDS Company";
        ExpectedIntTableFilter: Text;
    begin
        // [FEATURE] [Table Mapping] [Customer] [Direction]
        Initialize;
        ResetDefaultCRMSetupConfiguration;
        // [WHEN] Find Integration Table Mapping for "Item"
        // [THEN] Mapped to "CRM Account", Direction is "Bidirectional",
        // [THEN] "Synch. Only Coupled Records" is Yes
        CDSIntegrationMgt.GetCDSCompany(CDSCompany);
        ExpectedIntTableFilter := StrSubstNo('VERSION(1) SORTING(Field1) WHERE(Field8=1(2),Field27=1(0),Field62=1(%1|{00000000-0000-0000-0000-000000000000}))', Format(CDSCompany.CompanyId));
        VerifyTableMapping(
          DATABASE::Resource, DATABASE::"CRM Product", IntegrationTableMapping.Direction::Bidirectional,
          'VERSION(1) SORTING(Field1) WHERE(Field38=1(0))', ExpectedIntTableFilter, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultTableMappingCustPriceGroup()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CDSCompany: Record "CDS Company";
        ExpectedIntTableFilter: Text;
    begin
        // [FEATURE] [Table Mapping] [Price List] [Direction]
        Initialize;
        ResetDefaultCRMSetupConfiguration;
        // [WHEN] Find Integration Table Mapping for "Customer Price Group"
        // [THEN] Mapped to "CRM Pricelevel", Direction is "To Integration Table",
        // [THEN] no "Table Filter", no "Integration Table Filter", "Synch. Only Coupled Records" is Yes
        CDSIntegrationMgt.GetCDSCompany(CDSCompany);
        ExpectedIntTableFilter := StrSubstNo('VERSION(1) SORTING(Field1) WHERE(Field31=1(%1|{00000000-0000-0000-0000-000000000000}))', Format(CDSCompany.CompanyId));
        VerifyTableMapping(
          DATABASE::"Customer Price Group", DATABASE::"CRM Pricelevel", IntegrationTableMapping.Direction::ToIntegrationTable,
          '', ExpectedIntTableFilter, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultTableMappingSalesPrice()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // [FEATURE] [Table Mapping] [Price List] [Direction]
        Initialize;
        ResetDefaultCRMSetupConfiguration;
        // [WHEN] Find Integration Table Mapping for "Sales Price"
        // [THEN] Mapped to "CRM Productpricelevel", Direction is "To Integration Table",
        // [THEN] "Table Filter" is ("Sales Type"=Customer Price Group,"Sales Code"<>''),
        // [THEN] no "Integration Table Filter", "Synch. Only Coupled Records" is 'No'
        VerifyTableMapping(
          DATABASE::"Sales Price", DATABASE::"CRM Productpricelevel", IntegrationTableMapping.Direction::ToIntegrationTable,
          'VERSION(1) SORTING(Field1,Field13,Field2,Field4,Field3,Field5700,Field5400,Field14) WHERE(Field13=1(1),Field2=1(<>''''))', '', false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultTableMappingPriceListHeader()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CDSCompany: Record "CDS Company";
        ExpectedIntTableFilter: Text;
    begin
        // [FEATURE] [Table Mapping] [Price List] [Direction]
        Initialize(true);
        ResetDefaultCRMSetupConfiguration;
        // [WHEN] Find Integration Table Mapping for "Price List Header"
        // [THEN] Mapped to "CRM Pricelevel", Direction is "To Integration Table",
        // [THEN] "Table Filter" is "Price Type" is 'Sale', "Amount Type" is 'Price', "Allow Editing Defaults" is 'No' 
        // [THEN] no "Integration Table Filter", "Synch. Only Coupled Records" is Yes
        CDSIntegrationMgt.GetCDSCompany(CDSCompany);
        ExpectedIntTableFilter := StrSubstNo('VERSION(1) SORTING(Field1) WHERE(Field31=1(%1|{00000000-0000-0000-0000-000000000000}))', Format(CDSCompany.CompanyId));
        VerifyTableMapping(
          DATABASE::"Price List Header", DATABASE::"CRM Pricelevel", IntegrationTableMapping.Direction::ToIntegrationTable,
          'VERSION(1) SORTING(Field1) WHERE(Field8=1(1),Field9=1(17),Field20=1(0))', ExpectedIntTableFilter, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultTableMappingPriceListLine()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // [FEATURE] [Table Mapping] [Price List] [Direction]
        Initialize(true);
        ResetDefaultCRMSetupConfiguration;
        // [WHEN] Find Integration Table Mapping for "Price List Line"
        // [THEN] Mapped to "CRM Productpricelevel", Direction is "To Integration Table",
        // [THEN] "Table Filter" is ("Price Type" is 'Sale', "Amount Type" is 'Price', "Asset Type" is 'Item'),
        // [THEN] no "Integration Table Filter", "Synch. Only Coupled Records" is 'No'
        VerifyTableMapping(
          DATABASE::"Price List Line", DATABASE::"CRM Productpricelevel", IntegrationTableMapping.Direction::ToIntegrationTable,
          'VERSION(1) SORTING(Field1,Field2) WHERE(Field7=1(10|30),Field14=1(0),Field16=1(17),Field28=1(1))', '', false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultTableMappingSalesInvoice()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CDSCompany: Record "CDS Company";
        ExpectedIntTableFilter: Text;
    begin
        // [FEATURE] [Table Mapping] [Invoice] [Direction]
        Initialize;
        ResetDefaultCRMSetupConfiguration;
        // [WHEN] Find Integration Table Mapping for "Sales Invoice Header"
        // [THEN] Mapped to "CRM Invoice", Direction is "To Integration Table",
        // [THEN] no "Table Filter", no "Integration Table Filter", "Synch. Only Coupled Records" is Yes
        CDSIntegrationMgt.GetCDSCompany(CDSCompany);
        ExpectedIntTableFilter := StrSubstNo('VERSION(1) SORTING(Field1) WHERE(Field95=1(%1|{00000000-0000-0000-0000-000000000000}))', Format(CDSCompany.CompanyId));
        VerifyTableMapping(
          DATABASE::"Sales Invoice Header", DATABASE::"CRM Invoice", IntegrationTableMapping.Direction::ToIntegrationTable,
          '', ExpectedIntTableFilter, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultTableMappingSalesInvoiceLine()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // [FEATURE] [Table Mapping] [Invoice] [Direction]
        Initialize;
        ResetDefaultCRMSetupConfiguration;
        // [WHEN] Find Integration Table Mapping for "Sales Invoice Line"
        // [THEN] Mapped to "CRM Invoicedetail", Direction is "To Integration Table",
        // [THEN] no "Table Filter", no "Integration Table Filter", "Synch. Only Coupled Records" is No
        VerifyTableMapping(
          DATABASE::"Sales Invoice Line", DATABASE::"CRM Invoicedetail", IntegrationTableMapping.Direction::ToIntegrationTable,
          '', '', false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultTableMappingSalesPerson()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // [FEATURE] [Table Mapping] [Salesperson] [Direction]
        Initialize;
        ResetDefaultCRMSetupConfiguration;
        // [WHEN] Find Integration Table Mapping for "Salesperson/Purchaser"
        // [THEN] Mapped to "CRM Systemuser", Direction is "From Integration Table",
        // [THEN] no "Table Filter", no "Integration Table Filter", not "Integration user mode", is "Lisenced User", "Synch. Only Coupled Records" is Yes
        VerifyTableMapping(
          DATABASE::"Salesperson/Purchaser", DATABASE::"CRM Systemuser", IntegrationTableMapping.Direction::FromIntegrationTable,
          '', 'VERSION(1) SORTING(Field1) WHERE(Field31=1(0),Field96=1(0),Field107=1(1))', true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultTableMappingUnitOfMeasure()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // [FEATURE] [Table Mapping] [Unit Of Measure] [Direction]
        Initialize;
        ResetDefaultCRMSetupConfiguration;
        // [WHEN] Find Integration Table Mapping for "Unit Of Measure"
        // [THEN] Mapped to "CRM Uomschedule", Direction is "To Integration Table",
        // [THEN] no "Table Filter", no "Integration Table Filter", "Synch. Only Coupled Records" is Yes
        VerifyTableMapping(
          DATABASE::"Unit of Measure", DATABASE::"CRM Uomschedule", IntegrationTableMapping.Direction::ToIntegrationTable,
          '', '', true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultTableMappingOpportunity()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CDSCompany: Record "CDS Company";
        ExpectedIntTableFilter: Text;
    begin
        // [FEATURE] [Table Mapping] [Opportunity] [Direction]
        Initialize;
        ResetDefaultCRMSetupConfiguration;
        // [WHEN] Find Integration Table Mapping for "Opportunity"
        // [THEN] Mapped to "CRM Opportunity", Direction is "Bidirectional",
        // [THEN] no "Table Filter", no "Integration Table Filter", "Synch. Only Coupled Records" is No
        CDSIntegrationMgt.GetCDSCompany(CDSCompany);
        ExpectedIntTableFilter := StrSubstNo('VERSION(1) SORTING(Field1) WHERE(Field111=1(%1|{00000000-0000-0000-0000-000000000000}))', Format(CDSCompany.CompanyId));
        VerifyTableMapping(
          DATABASE::Opportunity, DATABASE::"CRM Opportunity", IntegrationTableMapping.Direction::Bidirectional,
          '', ExpectedIntTableFilter, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HyperlinkForUnsupportedEntity()
    var
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        // [FEATURE] [CRM Integration Management]
        // [SCENARIO] IsRecordCoupledToCRM() fails if entity is not supported
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");
        LibraryCRMIntegration.CreateIntegrationRecord(CreateGuid, DATABASE::"Customer Bank Account", CustomerBankAccount.RecordId);
        asserterror RunHyperlinkTest(CustomerBankAccount.RecordId, DATABASE::"Customer Bank Account");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HyperlinkForCustomer()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [CRM Integration Management] [Customer]
        // [SCENARIO] IsRecordCoupledToCRM() returns TRUE if Customers are coupled
        LibrarySales.CreateCustomer(Customer);
        LibraryCRMIntegration.CreateIntegrationRecord(CreateGuid, DATABASE::Customer, Customer.RecordId);
        RunHyperlinkTest(Customer.RecordId, DATABASE::Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HyperlinkForSalesPerson()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        // [FEATURE] [CRM Integration Management] [Salesperson]
        // [SCENARIO] IsRecordCoupledToCRM() returns TRUE if Salespersons are coupled
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        LibraryCRMIntegration.CreateIntegrationRecord(CreateGuid, DATABASE::"Salesperson/Purchaser", SalespersonPurchaser.RecordId);
        RunHyperlinkTest(SalespersonPurchaser.RecordId, DATABASE::"Salesperson/Purchaser");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HyperlinkForContact()
    var
        Contact: Record Contact;
    begin
        // [FEATURE] [CRM Integration Management] [Contact]
        // [SCENARIO] IsRecordCoupledToCRM() returns TRUE if Contacts are coupled
        Contact.Init();
        Contact.Insert();
        LibraryCRMIntegration.CreateIntegrationRecord(CreateGuid, DATABASE::Contact, Contact.RecordId);
        RunHyperlinkTest(Contact.RecordId, DATABASE::Contact);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultDynamicsNAVODataURL()
    var
        CRMNAVConnection: Record "CRM NAV Connection";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        // [FEATURE] [Default CRM Setup Configuration]
        // [SCENARIO] "CRM NAV Connection"."Dynamics NAV OData URL" is set on reset CRM setup configuration.
        Initialize;

        // [GIVEN] CRM integration enabled
        // [WHEN] Reset CRM integration setup to default
        ResetDefaultCRMSetupConfiguration;

        // [THEN] CRM NAV Connection exists with "Dynamics NAV OData URL" equal to OData URL for current company
        CRMNAVConnection.FindFirst;
        CRMNAVConnection.TestField("Dynamics NAV URL", GetUrl(CLIENTTYPE::Web));
        CRMNAVConnection.TestField("Dynamics NAV OData URL", '');

        // [WHEN] Item Availability service is running and Reset CRM integration setup to default
        CRMIntegrationManagement.SetupItemAvailabilityService;
        ResetDefaultCRMSetupConfiguration;

        // [THEN] "Dynamics NAV OData URL" contains updated link to Item Availability Service
        CRMNAVConnection.FindFirst;
        Assert.ExpectedMessage('/ProductItemAvailability', CRMNAVConnection."Dynamics NAV OData URL");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DynamicsNAVODataCredentials()
    var
        CRMNAVConnection: Record "CRM NAV Connection";
        User: Record User;
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
        AccessKey: Text[80];
    begin
        // [FEATURE] [CRM NAV Connection]
        // [SCENARIO] For CRM Connection Setup after "Dynamics NAV OData Username" is set, "CRM NAV Connection"."Dynamics NAV OData Accesskey" is updated automatically.
        Initialize;

        // [GIVEN] CRM integration enabled, CRM integration setup reset to default
        ResetDefaultCRMSetupConfiguration;

        // [GIVEN] User with OData Accesskey
        AccessKey := CreateUserWithAccessKey(User);

        // [WHEN] Open "CRM Connection Setup" page, set "Dynamics NAV OData Username" to User."User Name".
        CRMConnectionSetupPage.OpenEdit;
        CRMConnectionSetupPage.NAVODataUsername.SetValue(User."User Name");
        CRMConnectionSetupPage.Close;

        // [THEN] CRM NAV Connection exists with "Dynamics NAV OData Accesskey" equal to OData accesskey of the User.
        CRMNAVConnection.FindFirst;
        CRMNAVConnection.TestField("Dynamics NAV OData Accesskey", AccessKey);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenContactCardPageForCoupledCRMContact()
    var
        Contact: Record Contact;
        CRMContact: Record "CRM Contact";
        ContactCard: TestPage "Contact Card";
    begin
        // [FEATURE] [CRM Integration Management] [Contact] [UI]
        Initialize;
        LibraryCRMIntegration.CreateCoupledContactAndContact(Contact, CRMContact);

        ContactCard.Trap;
        CRMIntegrationManagement.OpenCoupledNavRecordPage(CRMContact.ContactId, 'contact');

        Assert.AreEqual(Contact."No.", ContactCard."No.".Value, 'The contact card should open for the correct record');
        ContactCard.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenCurrencyCardPageForCoupledCRMCurrency()
    var
        Currency: Record Currency;
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        CurrencyCard: TestPage "Currency Card";
    begin
        // [FEATURE] [CRM Integration Management] [Currency] [UI]
        Initialize;
        LibraryCRMIntegration.CreateCoupledCurrencyAndTransactionCurrency(Currency, CRMTransactioncurrency);

        CurrencyCard.Trap;
        CRMIntegrationManagement.OpenCoupledNavRecordPage(CRMTransactioncurrency.TransactionCurrencyId, 'transactioncurrency');

        Assert.AreEqual(Currency.Code, CurrencyCard.Code.Value, 'The currency card should open for the correct record');
        CurrencyCard.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenCustomerCardPageForCoupledCRMAccount()
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        CustomerCard: TestPage "Customer Card";
    begin
        // [FEATURE] [CRM Integration Management] [Customer] [UI]
        Initialize;
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);

        CustomerCard.Trap;
        CRMIntegrationManagement.OpenCoupledNavRecordPage(CRMAccount.AccountId, 'account');

        Assert.AreEqual(Customer."No.", CustomerCard."No.".Value, 'The customer card should open for the correct record');
        CustomerCard.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenCustPriceGroupListPageForCoupledCRMPricelevel()
    var
        CRMPricelevel: Record "CRM Pricelevel";
        CustomerPriceGroup: Record "Customer Price Group";
        CustomerPriceGroups: TestPage "Customer Price Groups";
    begin
        // [FEATURE] [CRM Integration Management] [Price List] [UI]
        Initialize;
        LibraryCRMIntegration.CreateCoupledPriceGroupAndPricelevel(CustomerPriceGroup, CRMPricelevel);

        CustomerPriceGroups.Trap;
        CRMIntegrationManagement.OpenCoupledNavRecordPage(CRMPricelevel.PriceLevelId, 'pricelevel');

        Assert.AreEqual(
          CustomerPriceGroup.Code, CustomerPriceGroups.Code.Value,
          'The customer price group list should open for the correct record');
        CustomerPriceGroups.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenItemCardPageForCoupledCRMProduct()
    var
        CRMProduct: Record "CRM Product";
        Item: Record Item;
        ItemCard: TestPage "Item Card";
    begin
        // [FEATURE] [CRM Integration Management] [Item] [UI]
        Initialize;
        LibraryCRMIntegration.CreateCoupledItemAndProduct(Item, CRMProduct);

        ItemCard.Trap;
        CRMIntegrationManagement.OpenCoupledNavRecordPage(CRMProduct.ProductId, 'product');

        Assert.AreEqual(Item."No.", ItemCard."No.".Value, 'The item card should open for the correct record');
        ItemCard.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenResourceCardPageForCoupledCRMProduct()
    var
        CRMProduct: Record "CRM Product";
        Resource: Record Resource;
        ResourceCard: TestPage "Resource Card";
    begin
        // [FEATURE] [CRM Integration Management] [Resource] [UI]
        Initialize;
        LibraryCRMIntegration.CreateCoupledResourceAndProduct(Resource, CRMProduct);

        ResourceCard.Trap;
        CRMIntegrationManagement.OpenCoupledNavRecordPage(CRMProduct.ProductId, 'product');

        Assert.AreEqual(Resource."No.", ResourceCard."No.".Value, 'The resource card should open for the correct record');
        ResourceCard.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpeSalesPersonCardPageForCoupledCRMSysuser()
    var
        CRMSystemuser: Record "CRM Systemuser";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        SalespersonPurchaserCard: TestPage "Salesperson/Purchaser Card";
    begin
        // [FEATURE] [CRM Integration Management] [Salesperson] [UI]
        Initialize;
        LibraryCRMIntegration.CreateCoupledSalespersonAndSystemUser(SalespersonPurchaser, CRMSystemuser);

        SalespersonPurchaserCard.Trap;
        CRMIntegrationManagement.OpenCoupledNavRecordPage(CRMSystemuser.SystemUserId, 'sYsTeMuSeR');

        Assert.AreEqual(
          SalespersonPurchaser.Code, SalespersonPurchaserCard.Code.Value,
          'The salesperson card should open for the correct record');
        SalespersonPurchaserCard.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenUOMListPageForCoupledCRMUOM()
    var
        CRMUom: Record "CRM Uom";
        CRMUomschedule: Record "CRM Uomschedule";
        UnitOfMeasure: Record "Unit of Measure";
        UnitsOfMeasure: TestPage "Units of Measure";
    begin
        // [FEATURE] [CRM Integration Management] [Unit Of Measure] [UI]
        Initialize;
        CRMUom.Name := 'BOX';
        LibraryCRMIntegration.CreateCoupledUnitOfMeasureAndUomSchedule(UnitOfMeasure, CRMUom, CRMUomschedule);

        UnitsOfMeasure.Trap;
        CRMIntegrationManagement.OpenCoupledNavRecordPage(CRMUomschedule.UoMScheduleId, 'uomschedule');

        Assert.AreEqual(UnitOfMeasure.Code, UnitsOfMeasure.Code.Value, 'The units of measure list should open showing the correct record');
        UnitsOfMeasure.Close;
    end;

    [Test]
    [HandlerFunctions('SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure SendCoupledAndPostedFCYSalesOrderToCRM()
    var
        Customer: Record Customer;
        Currency: Record Currency;
        IntegrationSynchJob: Record "Integration Synch. Job";
        FilteredSalesInvHeader: Record "Sales Invoice Header";
        IntegrationTableMapping: Record "Integration Table Mapping";
        SalesInvHeader: Record "Sales Invoice Header";
        CRMAccount: Record "CRM Account";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        CRMSalesorder: Record "CRM Salesorder";
        CRMInvoice: Record "CRM Invoice";
        CRMInvoicedetail: Record "CRM Invoicedetail";
        JobQueueEntryID: Guid;
    begin
        // [FEATURE] [FCY]
        // [SCENARIO 380219] Posted Sales Invoice in FCY can be coupled to CRM Invoice if the CRM Order exists.
        Initialize;

        // [GIVEN] CRM integration setup
        SetupCRM;

        // [GIVEN] Coupled Customer "X"
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);

        // [GIVEN] Coupled Currency "USD"
        CreateCoupledAndTransactionCurrencies(Currency, CRMTransactioncurrency);

        // [GIVEN] Posted Sales Invoice generated in NAV with Customer "X" and Currency "USD"
        CreatePostSalesInvoiceWithGLAccount(SalesInvHeader, Customer."No.", Currency.Code);

        // [GIVEN] CRM Order, where OrderNumber = Invoice."Your Reference"
        LibraryCRMIntegration.CreateCRMSalesOrderWithCustomerFCY(
          CRMSalesorder, CRMAccount.AccountId, CRMTransactioncurrency.TransactionCurrencyId);
        CRMSalesorder.OrderNumber := SalesInvHeader."Your Reference";
        CRMSalesorder.Modify();

        // [WHEN] Couple Posted Sales Invoice to CRM
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask;
        CRMIntegrationManagement.CreateNewRecordsInCRM(SalesInvHeader.RecordId);
        // Executing the Sync Job
        FilteredSalesInvHeader.SetRange("No.", SalesInvHeader."No.");
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::"Sales Invoice Header", FilteredSalesInvHeader.GetView, IntegrationTableMapping);

        // [THEN] The notification: "Synchronization has been scheduled."
        // [THEN] Synch Job is created, where Inserted = 1
        IntegrationSynchJob.Inserted := 1;
        LibraryCRMIntegration.VerifySyncJob(JobQueueEntryID, IntegrationTableMapping, IntegrationSynchJob);
        // [THEN] CRM Invoice is created, where TransactionCurrencyId is "USD"
        CRMInvoice.SetRange(InvoiceNumber, SalesInvHeader."No.");
        CRMInvoice.FindFirst;
        CRMInvoice.TestField(TransactionCurrencyId, CRMTransactioncurrency.TransactionCurrencyId);
        // [THEN] CRM Invoice Line is created, where TransactionCurrencyId is "USD"
        CRMInvoicedetail.SetRange(InvoiceId, CRMInvoice.InvoiceId);
        CRMInvoicedetail.SetRange(TransactionCurrencyId, CRMTransactioncurrency.TransactionCurrencyId);
        // CRMInvoicedetail.SETRANGE(ExchangeRate,SalesInvHeader."Currency Factor");
        Assert.RecordIsNotEmpty(CRMInvoicedetail);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NotPossibleToCoupleCRMSalesOrderInFCYToNAV()
    var
        CRMSalesorder: Record "CRM Salesorder";
        SalesHeader: Record "Sales Header";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        CRMSalesOrderToSalesOrder: Codeunit "CRM Sales Order to Sales Order";
    begin
        // [FEATURE] [FCY]
        // [SCENARIO 380219] It is possible to couple CRM Sales Order in FCY to NAV
        Initialize;

        SetupCRM;

        // [GIVEN] CRM Sales Order with "Currency Code" = "USD"
        CreateCRMSalesOrderInFCY(CRMSalesorder);

        // [WHEN] Couple CRM Sales Order to NAV
        CRMSalesOrderToSalesOrder.CreateInNAV(CRMSalesorder, SalesHeader);

        // [THEN] Sales Order with "Currency Code" = "USD" created
        CRMTransactioncurrency.Get(CRMSalesorder.TransactionCurrencyId);
        SalesHeader.TestField("Currency Code", CRMTransactioncurrency.ISOCurrencyCode);
    end;

    [Test]
    [HandlerFunctions('SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure ExtendedAmountIsCopiedToCRMInvoiceLine()
    var
        Customer: Record Customer;
        FilteredSalesInvHeader: Record "Sales Invoice Header";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        CRMAccount: Record "CRM Account";
        CRMInvoice: Record "CRM Invoice";
        CRMInvoicedetail: Record "CRM Invoicedetail";
        JobQueueEntryID: Guid;
    begin
        // [FEATURE] [Invoice Line]
        // [SCENARIO 173456] Invoice Line's "Amount Incl. VAT" is copied to CRM Invoice Line's "Extended Amount"
        Initialize;
        SetupCRM;
        // [GIVEN] Posted Sales Invoice generated in NAV, with one line,
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        CreatePostSalesInvoiceWithGLAccount(SalesInvHeader, Customer."No.", '');
        // [GIVEN] where Quantity = 4, Amount = 1000, "Amount Including VAT" = 1050
        SalesInvoiceLine.SetRange("Document No.", SalesInvHeader."No.");
        SalesInvoiceLine.FindFirst;

        // [WHEN] Couple Posted Sales Invoice to CRM
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask;
        CRMIntegrationManagement.CreateNewRecordsInCRM(SalesInvHeader.RecordId);
        // Executing the Sync Job
        FilteredSalesInvHeader.SetRange("No.", SalesInvHeader."No.");
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::"Sales Invoice Header", FilteredSalesInvHeader.GetView, IntegrationTableMapping);

        // [THEN] The notification: "Synchronization has been scheduled."
        // [THEN] Synch Job is created, where Inserted = 1
        IntegrationSynchJob.Inserted := 1;
        LibraryCRMIntegration.VerifySyncJob(JobQueueEntryID, IntegrationTableMapping, IntegrationSynchJob);
        // [THEN] CRM Invoice Line is created,
        CRMInvoice.SetRange(InvoiceNumber, SalesInvHeader."No.");
        CRMInvoice.FindFirst;
        CRMInvoicedetail.SetRange(InvoiceId, CRMInvoice.InvoiceId);
        CRMInvoicedetail.SetRange(LineItemNumber, SalesInvoiceLine."Line No.");
        CRMInvoicedetail.FindFirst;
        // [THEN] where Quantity = 4, BaseAmount = 1000, ExtendedAmount = 1050, Tax = 50
        CRMInvoicedetail.TestField(Quantity, SalesInvoiceLine.Quantity);
        CRMInvoicedetail.TestField(BaseAmount, SalesInvoiceLine.Amount);
        CRMInvoicedetail.TestField(ExtendedAmount, SalesInvoiceLine."Amount Including VAT");
        CRMInvoicedetail.TestField(Tax, SalesInvoiceLine."Amount Including VAT" - SalesInvoiceLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlockingItemDeactivatesProductIfBlockedFilterIsRemoved()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Item: Record Item;
        CRMProduct: Record "CRM Product";
    begin
        // [FEATURE] [CRM Integration Management] [Item] [CRM Product]
        // [SCENARIO 175051] Blocking Item makes coupled CRM Product State 'Retired' if 'Blocked' filter is removed from integration table mapping
        Initialize;
        SetupCRM;

        // [GIVEN] Coupled Item and CRM Product
        CreateCoupledAndActiveItemAndProduct(Item, CRMProduct);

        // [GIVEN] Block Item
        BlockItem(Item);

        // [WHEN] Sync record
        IntegrationTableMapping.Get('ITEM-PRODUCT');
        Clear(IntegrationTableMapping."Table Filter");
        IntegrationTableMapping.Modify();
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Item.RecordId, true, false);

        // [THEN] Coupled CRM Product State is set to 'Retired'
        CRMProduct.Find;
        CRMProduct.TestField(StateCode, CRMProduct.StateCode::Retired);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlockingResourceDeactivatesProductIfBlockedFilterIsRemoved()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Resource: Record Resource;
        CRMProduct: Record "CRM Product";
    begin
        // [FEATURE] [CRM Integration Management] [Resource] [CRM Product]
        // [SCENARIO 175051] Blocking Resource makes coupled CRM Product State 'Retired' if 'Blocked' filter is removed from integration table mapping
        Initialize;
        SetupCRM;

        // [GIVEN] Coupled Resource and CRM Product
        CreateCoupledAndActiveResourceAndProduct(Resource, CRMProduct);

        // [GIVEN] Block Resource
        BlockResource(Resource);

        // [WHEN] Sync record
        IntegrationTableMapping.Get('RESOURCE-PRODUCT');
        Clear(IntegrationTableMapping."Table Filter");
        IntegrationTableMapping.Modify();
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Resource.RecordId, true, false);

        // [THEN] Coupled CRM Product State is set to 'Retired'
        CRMProduct.Find;
        CRMProduct.TestField(StateCode, CRMProduct.StateCode::Retired);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnblockingItemActivatesProduct()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Item: Record Item;
        CRMProduct: Record "CRM Product";
    begin
        // [FEATURE] [CRM Integration Management] [Item] [CRM Product]
        // [SCENARIO 175051] Unblocking Item makes coupled CRM Product State 'Active'
        Initialize;
        SetupCRM;

        // [GIVEN] Coupled Item and CRM Product, Item is blocked and Product State is 'Retired'
        CreateCoupledAndActiveItemAndProduct(Item, CRMProduct);
        BlockItem(Item);
        CRMSynchHelper.SetCRMProductStateToRetired(CRMProduct);
        CRMProduct.Modify(true);

        // [GIVEN]  Unblock Item
        Item.Validate(Blocked, false);
        Item.Modify(true);

        // [WHEN] Sync record
        IntegrationTableMapping.Get('ITEM-PRODUCT');
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Item.RecordId, true, false);

        // [THEN] Coupled CRM Product State is set to 'Active'
        CRMProduct.Find;
        CRMProduct.TestField(StateCode, CRMProduct.StateCode::Active);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnblockingResourceActivatesProduct()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Resource: Record Resource;
        CRMProduct: Record "CRM Product";
    begin
        // [FEATURE] [CRM Integration Management] [Resource] [CRM Product]
        // [SCENARIO 175051] Unblocking Resource makes coupled CRM Product State 'Active'
        Initialize;
        SetupCRM;

        // [GIVEN] Coupled Resource and CRM Product, Resource is blocked and Product State is 'Retired'
        CreateCoupledAndActiveResourceAndProduct(Resource, CRMProduct);
        BlockResource(Resource);
        CRMSynchHelper.SetCRMProductStateToRetired(CRMProduct);
        CRMProduct.Modify(true);

        // [GIVEN] Unblock Resource
        Resource.Validate(Blocked, false);
        Resource.Modify(true);

        // [WHEN] Sync record
        IntegrationTableMapping.Get('RESOURCE-PRODUCT');
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Resource.RecordId, true, false);

        // [THEN] Coupled CRM Product State is set to 'Active'
        CRMProduct.Find;
        CRMProduct.TestField(StateCode, CRMProduct.StateCode::Active);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeactivatingProductBlocksItemIfActiveFilterIsRemoved()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Item: Record Item;
        CRMProduct: Record "CRM Product";
        CDSCompany: Record "CDS Company";
    begin
        // [FEATURE] [CRM Integration Management] [Item] [CRM Product]
        // [SCENARIO 175051] Setting CRM Product State to 'Retired' makes coupled Item Blocked if 'Active' filter is removed from integration table mapping
        Initialize;
        SetupCRM;

        // [GIVEN] Coupled Item and CRM Product, Item is not blocked and Product State is 'Active'
        CreateCoupledAndActiveItemAndProduct(Item, CRMProduct);

        // [GIVEN] Set CRM Product State to 'Retired'
        CRMProduct.Validate(StateCode, CRMProduct.StateCode::Retired);
        CRMProduct.Modify(true);

        // [WHEN] Sync record
        IntegrationTableMapping.Get('ITEM-PRODUCT');
        CDSIntegrationMgt.GetCDSCompany(CDSCompany);
        IntegrationTableMapping.SetIntegrationTableFilter(StrSubstNo('VERSION(1) SORTING(Field1) WHERE(Field8=1(0),Field62=1(%1|{00000000-0000-0000-0000-000000000000}))', Format(CDSCompany.CompanyId)));
        IntegrationTableMapping.Modify();
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, CRMProduct.ProductId, true, false);

        // [THEN] Coupled Item is blocked
        Item.Find;
        Item.TestField(Blocked, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeactivatingProductBlocksResourceIfActiveFilterIsRemoved()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Resource: Record Resource;
        CRMProduct: Record "CRM Product";
        CDSCompany: Record "CDS Company";
    begin
        // [FEATURE] [CRM Integration Management] [Resource] [CRM Product]
        // [SCENARIO 175051] Setting CRM Product State to 'Retired' makes coupled Resource Blocked if 'Active' filter is removed from integration table mapping
        Initialize;
        SetupCRM;

        // [GIVEN] Coupled Resource and CRM Product, Resource is not blocked and Product State is 'Active'
        CreateCoupledAndActiveResourceAndProduct(Resource, CRMProduct);

        // [GIVEN] Set CRM Product State to 'Retired'
        CRMProduct.Validate(StateCode, CRMProduct.StateCode::Retired);
        CRMProduct.Modify(true);

        // [WHEN] Sync record
        IntegrationTableMapping.Get('RESOURCE-PRODUCT');
        CDSIntegrationMgt.GetCDSCompany(CDSCompany);
        IntegrationTableMapping.SetIntegrationTableFilter(StrSubstNo('VERSION(1) SORTING(Field1) WHERE(Field8=1(2),Field62=1(%1|{00000000-0000-0000-0000-000000000000}))', Format(CDSCompany.CompanyId)));
        IntegrationTableMapping.Modify();
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, CRMProduct.ProductId, true, false);

        // [THEN] Coupled Resource is blocked
        Resource.Find;
        Resource.TestField(Blocked, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ActivatingProductUnblocksItem()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Item: Record Item;
        CRMProduct: Record "CRM Product";
    begin
        // [FEATURE] [CRM Integration Management] [Item] [CRM Product]
        // [SCENARIO 175051] Setting CRM Product State to 'Active' unblocks coupled Item
        Initialize;
        SetupCRM;

        // [GIVEN] Coupled Item and CRM Product, Item is blocked and Product State is 'Retired'
        CreateCoupledAndActiveItemAndProduct(Item, CRMProduct);
        CRMProduct.Validate(StateCode, CRMProduct.StateCode::Retired);
        CRMProduct.Modify(true);
        BlockItem(Item);

        // [GIVEN] Set CRM Product State to 'Active'
        CRMProduct.Validate(StateCode, CRMProduct.StateCode::Active);
        CRMProduct.Modify(true);

        // [WHEN] Sync record
        IntegrationTableMapping.Get('ITEM-PRODUCT');
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, CRMProduct.ProductId, true, false);

        // [THEN] Coupled Item is unblocked
        Item.Find;
        Item.TestField(Blocked, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ActivatingProductUnblocksResource()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Resource: Record Resource;
        CRMProduct: Record "CRM Product";
    begin
        // [FEATURE] [CRM Integration Management] [Resource] [CRM Product]
        // [SCENARIO 175051] Setting CRM Product State to 'Active' unblocks coupled Resource
        Initialize;
        SetupCRM;

        // [GIVEN] Coupled Resource and CRM Product, Resource is blocked and Product State is 'Retired'
        CreateCoupledAndActiveResourceAndProduct(Resource, CRMProduct);
        CRMProduct.Validate(StateCode, CRMProduct.StateCode::Retired);
        CRMProduct.Modify(true);
        BlockResource(Resource);

        // [GIVEN] Set CRM Product State to 'Active'
        CRMProduct.Validate(StateCode, CRMProduct.StateCode::Active);
        CRMProduct.Modify(true);

        // [WHEN] Sync record
        IntegrationTableMapping.Get('RESOURCE-PRODUCT');
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, CRMProduct.ProductId, true, false);

        // [THEN] Coupled Resource is unblocked
        Resource.Find;
        Resource.TestField(Blocked, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncCRMSalesOrderWithInactiveCRMProduct()
    var
        CRMSalesorder: Record "CRM Salesorder";
        SalesHeader: Record "Sales Header";
        CRMProduct: Record "CRM Product";
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
        CRMSalesOrderToSalesOrder: Codeunit "CRM Sales Order to Sales Order";
    begin
        // [FEATURE] [CRM Integration Management] [Item] [CRM Product]
        // [SCENARIO 175051] Unable to sync CRM Salesorder to NAV if CRM Product is of 'Retired' state.
        Initialize;

        // [GIVEN] CRM integration setup
        SetupCRM;

        // [GIVEN] CRM Salesorder with a line of CRM Product
        PrepareCRMSalesOrder(CRMSalesorder);
        LibraryCRMIntegration.CreateCRMSalesOrderLine(CRMSalesorder, CRMSalesorderdetail);

        // [GIVEN] Set CRM Product State to 'Retired'
        CRMProduct.Get(CRMSalesorderdetail.ProductId);
        CRMProduct.Validate(StateCode, CRMProduct.StateCode::Retired);
        CRMProduct.Modify(true);

        // [WHEN] Couple CRM Salesorder to NAV Sales Order
        asserterror CRMSalesOrderToSalesOrder.CreateInNAV(CRMSalesorder, SalesHeader);

        // [THEN] Error message because CRM Product is is of state 'Retired'
        Assert.ExpectedError(StatusMustBeActiveErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncCRMSalesOrderWithInactiveCRMProductResource()
    var
        CRMSalesorder: Record "CRM Salesorder";
        SalesHeader: Record "Sales Header";
        CRMProduct: Record "CRM Product";
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
        CRMSalesOrderToSalesOrder: Codeunit "CRM Sales Order to Sales Order";
    begin
        // [FEATURE] [CRM Integration Management] [Resource] [CRM Product]
        // [SCENARIO 175051] Unable to sync CRM Salesorder to NAV if CRM Product (resource) is of 'Retired' state.
        Initialize;

        // [GIVEN] CRM integration setup
        SetupCRM;

        // [GIVEN] CRM Salesorder with a line of CRM Product (resource)
        PrepareCRMSalesOrder(CRMSalesorder);
        LibraryCRMIntegration.CreateCRMSalesOrderLineWithResource(CRMSalesorder, CRMSalesorderdetail);

        // [GIVEN] Set CRM Product State to 'Retired'
        CRMProduct.Get(CRMSalesorderdetail.ProductId);
        CRMProduct.Validate(StateCode, CRMProduct.StateCode::Retired);
        CRMProduct.Modify(true);

        // [WHEN] Couple CRM Salesorder to NAV Sales Order
        asserterror CRMSalesOrderToSalesOrder.CreateInNAV(CRMSalesorder, SalesHeader);

        // [THEN] Error message because CRM Product is of state 'Retired'
        Assert.ExpectedError(StatusMustBeActiveErr);
    end;

    [Test]
    [HandlerFunctions('SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure SyncNAVInvoiceWithBlockedItem()
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        FilteredSalesInvHeader: Record "Sales Invoice Header";
        IntegrationTableMapping: Record "Integration Table Mapping";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        CRMProduct: Record "CRM Product";
        JobQueueEntryID: Guid;
    begin
        // [FEATURE] [CRM Integration Management] [Item] [CRM Product]
        // [SCENARIO 175051] Unable to sync NAV Sales Invoice to CRM if it contains Item which is blocked.
        Initialize;

        // [GIVEN] CRM integration setup
        SetupCRM;

        // [GIVEN] Posted Sales Invoice
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        CreateCoupledAndActiveItemAndProduct(Item, CRMProduct);
        CreatePostSalesInvoiceLCY(SalesInvHeader, Customer."No.", SalesLine.Type::Item, Item."No.");

        // [GIVEN] Block Posted Sales Invoice Item
        Item.Find;
        BlockItem(Item);

        // [WHEN] Couple Posted Sales Invoice to CRM
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask;
        CRMIntegrationManagement.CreateNewRecordsInCRM(SalesInvHeader.RecordId);
        // Executing the Sync Job
        FilteredSalesInvHeader.SetRange("No.", SalesInvHeader."No.");
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::"Sales Invoice Header", FilteredSalesInvHeader.GetView, IntegrationTableMapping);

        // [THEN] Error message because Item is blocked
        LibraryCRMIntegration.VerifySyncJobFailedOneRecord(JobQueueEntryID, IntegrationTableMapping, BlockedMustBeNoErr);
    end;

    [Test]
    [HandlerFunctions('SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure SyncNAVInvoiceWithBlockedResource()
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        FilteredSalesInvHeader: Record "Sales Invoice Header";
        IntegrationTableMapping: Record "Integration Table Mapping";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        Resource: Record Resource;
        CRMProduct: Record "CRM Product";
        JobQueueEntryID: Guid;
    begin
        // [FEATURE] [CRM Integration Management] [Resource] [CRM Product]
        // [SCENARIO 175051] Unable to sync NAV Sales Invoice to CRM if it contains Resource which is blocked.
        Initialize;

        // [GIVEN] CRM integration setup
        SetupCRM;

        // [GIVEN] Posted Sales Invoice
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        CreateCoupledAndActiveResourceAndProduct(Resource, CRMProduct);
        CreatePostSalesInvoiceLCY(SalesInvHeader, Customer."No.", SalesLine.Type::Resource, Resource."No.");

        // [GIVEN] Block Posted Sales Invoice Resource
        Resource.Find;
        BlockResource(Resource);

        // [WHEN] Couple Posted Sales Invoice to CRM
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask;
        CRMIntegrationManagement.CreateNewRecordsInCRM(SalesInvHeader.RecordId);
        // Executing the Sync Job
        FilteredSalesInvHeader.SetRange("No.", SalesInvHeader."No.");
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::"Sales Invoice Header", FilteredSalesInvHeader.GetView, IntegrationTableMapping);

        // [THEN] Error message because Item is blocked
        LibraryCRMIntegration.VerifySyncJobFailedOneRecord(JobQueueEntryID, IntegrationTableMapping, BlockedMustBeNoErr);
    end;

    [Test]
    [HandlerFunctions('SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CouplePostedSalesInvoiceCreatedInNAVToCRM()
    var
        Customer: Record Customer;
        FilteredSalesInvHeader: Record "Sales Invoice Header";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        SalesInvHeader: Record "Sales Invoice Header";
        CRMAccount: Record "CRM Account";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        JobQueueEntryID: Guid;
    begin
        // [FEATURE] [UI]

        // [SCENARIO 380575] Posted Sales Invoice couples to CRM when press "Create Invoice in Dynamics CRM" on page "Posted Sales Invoice"
        Initialize;

        // [GIVEN] CRM integration setup
        SetupCRM;

        // [GIVEN] Coupled Customer
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);

        // [GIVEN] Posted Sales Invoice generated in NAV
        CreatePostSalesInvoiceWithGLAccount(SalesInvHeader, Customer."No.", '');

        // [GIVEN] Opened "Posted Sales Invoice" page
        PostedSalesInvoice.OpenView;
        PostedSalesInvoice.GotoRecord(SalesInvHeader);

        // [WHEN] Press "Create Invoice in Dynamics CRM" on page "Posted Sales Invoice"
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask;
        PostedSalesInvoice.CreateInCRM.Invoke;
        // Executing the Sync Job
        FilteredSalesInvHeader.SetRange("No.", SalesInvHeader."No.");
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::"Sales Invoice Header", FilteredSalesInvHeader.GetView, IntegrationTableMapping);

        // [THEN] Posted Sales invoice is coupled
        SalesInvHeader.Find;
        SalesInvHeader.TestField("Coupled to CRM", true);
        // [THEN] The notification: "Synchronization has been scheduled."
        // [THEN] Synch Job is created, where Inserted = 1
        IntegrationSynchJob.Inserted := 1;
        LibraryCRMIntegration.VerifySyncJob(JobQueueEntryID, IntegrationTableMapping, IntegrationSynchJob);
    end;

    [Test]
    [HandlerFunctions('MultipleSyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CoupleMultiplePostedSalesInvoicesToCRM()
    var
        Customer: Record Customer;
        IntegrationTableMapping: Record "Integration Table Mapping";
        SalesInvHeader: Record "Sales Invoice Header";
        CRMAccount: Record "CRM Account";
        FilteredSalesInvHeader: Record "Sales Invoice Header";
        JobQueueEntryID: Guid;
    begin
        // [SCENARIO 380575] Two Posted Sales Invoices coupled to CRM
        Initialize;

        // [GIVEN] CRM integration setup
        SetupCRM;

        // [GIVEN] Coupled Customer
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);

        // [GIVEN] Three Posted Sales Invoices generated in NAV
        CreatePostSalesInvoiceWithGLAccount(SalesInvHeader, Customer."No.", '');
        CreatePostSalesInvoiceWithGLAccount(SalesInvHeader, Customer."No.", '');
        CreatePostSalesInvoiceWithGLAccount(SalesInvHeader, Customer."No.", '');

        // [GIVEN] Marked the second and third invoice, while positioned on the first one
        SalesInvHeader.SetRange("Sell-to Customer No.", Customer."No.");
        SalesInvHeader.FindLast;
        SalesInvHeader.Mark(true); // mark the third invoice
        SalesInvHeader.Next(-1);
        SalesInvHeader.Mark(true); // mark the second invoice
        SalesInvHeader.FindFirst; // rec positioned on the first, that is out of marked invoices
        SalesInvHeader.SetRange("Sell-to Customer No.");
        SalesInvHeader.MarkedOnly(true);

        // [WHEN] "Create New Account In CRM" for two invoices: second and third.
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask;
        CRMIntegrationManagement.CreateNewRecordsInCRM(SalesInvHeader);

        // [THEN] Notification: '2 of 2 records are scheduled'
        // handled by MultipleSyncStartedNotificationHandler
        // Executing the Sync Jobs
        SalesInvHeader.FindSet;
        repeat
            FilteredSalesInvHeader.SetRange("No.", SalesInvHeader."No.");
            JobQueueEntryID :=
              LibraryCRMIntegration.RunJobQueueEntry(
                DATABASE::"Sales Invoice Header", FilteredSalesInvHeader.GetView, IntegrationTableMapping);
        until SalesInvHeader.Next = 0;

        // [THEN] 2nd and 3rd Posted Sales invoices are coupled, the 1st one is not.
        SalesInvHeader.Reset();
        SalesInvHeader.SetRange("Sell-to Customer No.", Customer."No.");
        SalesInvHeader.FindFirst;
        SalesInvHeader.TestField("Coupled to CRM", false);
        SalesInvHeader.Next;
        SalesInvHeader.TestField("Coupled to CRM", true);
        SalesInvHeader.Next;
        SalesInvHeader.TestField("Coupled to CRM", true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CheckOrEnableCRMConnectionNotEnabled()
    begin
        // [SCENARIO 204194] CRM Connection Setup Wizard page is shown if CRM setup is not enabled and user tries to access CRM items from NAV.
        Initialize;
        LibraryCRMIntegration.CreateCRMConnectionSetup('', 'host', false);
        asserterror CRMIntegrationManagement.CheckOrEnableCRMConnection;
    end;

    [Test]
    [HandlerFunctions('SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CouplePostedSalesInvoiceInFCYCreatedInNAVToCRM()
    var
        Customer: Record Customer;
        Currency: Record Currency;
        Item: Record Item;
        SalesLine: Record "Sales Line";
        FilteredSalesInvHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        IntegrationTableMapping: Record "Integration Table Mapping";
        SalesInvHeader: Record "Sales Invoice Header";
        CRMAccount: Record "CRM Account";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMProduct: Record "CRM Product";
        CRMPricelevel: Record "CRM Pricelevel";
        CRMProductpricelevel: Record "CRM Productpricelevel";
        CRMUom: Record "CRM Uom";
    begin
        // [FEATURE] [FCY]
        // [SCENARIO 186713] It is possible to couple Posted Sales Invoice in FCY that was created in NAV to CRM
        Initialize;

        // [GIVEN] CRM integration setup
        SetupCRM;
        LibraryCRMIntegration.CreateCRMOrganization;

        // [GIVEN] Coupled Customer "X"
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);

        // [GIVEN] Coupled Currency "USD"
        CreateCoupledAndTransactionCurrencies(Currency, CRMTransactioncurrency);

        // [GIVEN] Coupled Item "ITEM" with UoM "PCS"
        CreateCoupledAndActiveItemAndProduct(Item, CRMProduct);

        // [GIVEN] Posted Sales Invoice generated in NAV with Customer "X", Currency "USD" and Item "ITEM", unit price 100
        CreatePostSalesInvoiceFCY(SalesInvHeader, Customer."No.", SalesLine.Type::Item, Item."No.", Currency.Code);

        // [WHEN] Couple Posted Sales Invoice to CRM
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask;
        CRMIntegrationManagement.CreateNewRecordsInCRM(SalesInvHeader.RecordId);
        // Executing the Sync Job
        FilteredSalesInvHeader.SetRange("No.", SalesInvHeader."No.");
        LibraryCRMIntegration.RunJobQueueEntry(
          DATABASE::"Sales Invoice Header", FilteredSalesInvHeader.GetView, IntegrationTableMapping);

        // [THEN] Posted Sales Invoice is coupled to a CRM Invoice
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(SalesInvHeader.RecordId), 'Should be coupled.');

        // [THEN] New CRM Productpricelevel created for item "ITEM", currency "USD", UoM "PCS" and amount 100
        FindCRMProductpricelevelByItem(CRMProductpricelevel, Item);
        FindCRMPricelevelByCurrency(CRMPricelevel, Currency);
        FindCRMUoMBySalesInvoicLineItem(CRMUom, CRMIntegrationRecord."CRM ID", CRMProduct.ProductId);
        FindSalesInvoiceLine(SalesInvoiceLine, Item."No.");
        VerifyCRMProductpricelevel(
          CRMProductpricelevel, CRMPricelevel.PriceLevelId,
          CRMUom.UoMId, CRMUom.UoMScheduleId, SalesInvoiceLine."Unit Price");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateCRMPricelevelInCurrencySunshine()
    var
        Currency: Record Currency;
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        CRMPricelevel: Record "CRM Pricelevel";
    begin
        // [FEATURE] [FCY] [UT]
        // [SCENARIO 186713] New CRM pricelevel in currency could be created with CRMSynchHelper.CreateCRMPricelevelInCurrency
        Initialize;
        LibraryCRMIntegration.CreateCRMOrganization;

        // [GIVEN] Coupled Currency "USD"
        CreateCoupledAndTransactionCurrencies(Currency, CRMTransactioncurrency);

        // [WHEN] Function CRMSynchHelper.CreateCRMPricelevelInCurrency is being run
        CRMSynchHelper.CreateCRMPricelevelInCurrency(CRMPricelevel, Currency.Code, GetExchangeRate(Currency.Code, WorkDate));

        // [THEN] New CRM Pricelevel created for currency "USD" created
        FindCRMPricelevelByCurrency(CRMPricelevel, Currency);
        VerifyCRMPriceLevel(CRMPricelevel, Currency.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateCRMPricelevelInCurrencyWhenCurrencyNotCoupled()
    var
        Currency: Record Currency;
        CRMPricelevel: Record "CRM Pricelevel";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
    begin
        // [FEATURE] [FCY] [UT]
        // [SCENARIO 186713] If currency is not mapped then function CRMSynchHelper.CreateCRMPricelevelInCurrency causes error
        Initialize;
        LibraryCRMIntegration.CreateCRMOrganization;

        // [GIVEN] Currency "USD" which is not coupled with CRM Transactioncurrency
        LibraryERM.CreateCurrency(Currency);

        // [WHEN] Function CRMSynchHelper.CreateCRMPricelevelInCurrency is being run
        asserterror
          CRMSynchHelper.CreateCRMPricelevelInCurrency(CRMPricelevel, Currency.Code, LibraryRandom.RandDec(100, 2));

        // [THEN] Error message "The integration record for Currency: USD was not found."
        Assert.ExpectedError(
          StrSubstNo(
            RecordMustBeCoupledErr,
            Currency.TableCaption,
            Currency.Code,
            CRMTransactioncurrency.TableCaption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultInactivityTimeoutPeriod()
    begin
        // [FEATURE] [Inactivity Timeout Period]
        // [SCENARIO 266711] Inactivity Timeout Period has value on Reset Default CRM Setup Configuration
        Initialize;
        // [WHEN] Reset Default CRM Setup Configuration
        ResetDefaultCRMSetupConfiguration;

        // [THEN] Job queue entries with respective No. of Minutes between Runs & Inactivity Timeout Period
        VerifyJobQueueEntriesInactivityTimeoutPeriod(30, 720,
          ' CUSTOMER - Dataverse synchronization job.');
        VerifyJobQueueEntriesInactivityTimeoutPeriod(30, 720,
          ' VENDOR - Dataverse synchronization job.');
        VerifyJobQueueEntriesInactivityTimeoutPeriod(30, 720,
          ' CONTACT - Dataverse synchronization job.');
        VerifyJobQueueEntriesInactivityTimeoutPeriod(30, 720,
          ' CURRENCY - Dataverse synchronization job.');
        VerifyJobQueueEntriesInactivityTimeoutPeriod(30, 720,
          ' RESOURCE-PRODUCT - Dynamics 365 Sales synchronization job.');
        VerifyJobQueueEntriesInactivityTimeoutPeriod(30, 720,
          ' UNIT OF MEASURE - Dynamics 365 Sales synchronization job.');
        VerifyJobQueueEntriesInactivityTimeoutPeriod(30, 1440,
          ' SALESPEOPLE - Dataverse synchronization job.');
        VerifyJobQueueEntriesInactivityTimeoutPeriod(30, 1440,
          ' ITEM-PRODUCT - Dynamics 365 Sales synchronization job.');
        VerifyJobQueueEntriesInactivityTimeoutPeriod(30, 1440,
          ' CUSTPRCGRP-PRICE - Dynamics 365 Sales synchronization job.');
        VerifyJobQueueEntriesInactivityTimeoutPeriod(30, 1440,
          ' SALESPRC-PRODPRICE - Dynamics 365 Sales synchronization job.');
        VerifyJobQueueEntriesInactivityTimeoutPeriod(30, 1440,
          ' POSTEDSALESINV-INV - Dynamics 365 Sales synchronization job.');
    end;

    local procedure Initialize()
    begin
        Initialize(false);
    end;

    local procedure Initialize(EnableExtendedPrice: Boolean)
    var
        MyNotifications: Record "My Notifications";
        UpdateCurrencyExchangeRates: Codeunit "Update Currency Exchange Rates";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"CRM Integration Mgt Test");

        LibraryPriceCalculation.DisableExtendedPriceCalculation();
        if EnableExtendedPrice then
            LibraryPriceCalculation.EnableExtendedPriceCalculation();

        LibraryApplicationArea.EnableFoundationSetup;
        LibraryCRMIntegration.ResetEnvironment;
        LibraryCRMIntegration.ConfigureCRM;
        MyNotifications.InsertDefault(UpdateCurrencyExchangeRates.GetMissingExchangeRatesNotificationID, '', '', false);
        if IsInitialized then
            exit;

        LibraryERMCountryData.CreateVATData;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        LibraryERMCountryData.UpdateVATPostingSetup;
        LibraryERMCountryData.UpdateGeneralLedgerSetup;

        IsInitialized := true;
    end;

    local procedure SetupCRM()
    begin
        LibraryCRMIntegration.ResetEnvironment;
        LibraryCRMIntegration.ConfigureCRM;
        ResetDefaultCRMSetupConfiguration;
        LibraryCRMIntegration.CreateCRMConnectionSetup('', 'host', true);
        LibraryCRMIntegration.GetGLSetupCRMTransactionCurrencyID;
    end;

    local procedure CreateUserWithAccessKey(var User: Record User): Text[80]
    begin
        with User do begin
            Init;
            Validate("User Name", LibraryUtility.GenerateGUID);
            Validate("License Type", "License Type"::"Full User");
            Validate("User Security ID", CreateGuid);
            Insert(true);

            exit(IdentityManagement.CreateWebServicesKeyNoExpiry("User Security ID"));
        end;
    end;

    local procedure RunHyperlinkTest(RecordID: RecordID; TableNo: Integer)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
    begin
        // Getting URL for CRM entities
        // [GIVEN] An coupled SalesPerson/Purchaser
        // [WHEN] Getting CRM Entity Url From RecordId
        // [THEN] An url is returned
        CRMIntegrationRecord.CoupleRecordIdToCRMID(RecordID, CreateGuid);
        Assert.IsTrue(CRMCouplingManagement.IsRecordCoupledToCRM(RecordID), 'Expected the record to be coupled');
        Assert.AreNotEqual(
          '', CRMIntegrationManagement.GetCRMEntityUrlFromRecordID(RecordID),
          'Expected to get a valid url');

        // [GIVEN] An decoupled entity
        // [WHEN] Getting CRM Entity Url From RecordId
        // [THEN] An error is thrown
        CRMIntegrationRecord.FindByRecordID(RecordID);
        CRMIntegrationRecord.Delete();
        Assert.IsFalse(CRMCouplingManagement.IsRecordCoupledToCRM(RecordID), 'Did not expect the record to be coupled');
        asserterror CRMIntegrationManagement.GetCRMEntityUrlFromRecordID(RecordID);
    end;

    local procedure CreatePostSalesInvoiceWithGLAccount(var SalesInvoiceHeader: Record "Sales Invoice Header"; CustNo: Code[20]; CurrencyCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        CreatePostSalesInvoiceFCY(
          SalesInvoiceHeader, CustNo, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup, CurrencyCode);
    end;

    local procedure CreatePostSalesInvoiceLCY(var SalesInvoiceHeader: Record "Sales Invoice Header"; CustNo: Code[20]; Type: Enum "Sales Line Type"; No: Code[20])
    begin
        CreatePostSalesInvoiceFCY(SalesInvoiceHeader, CustNo, Type, No, '');
    end;

    local procedure CreatePostSalesInvoiceFCY(var SalesInvoiceHeader: Record "Sales Invoice Header"; CustNo: Code[20]; Type: eNUM "Sales Line Type"; No: Code[20]; CurrencyCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustNo);
        if CurrencyCode <> '' then
            SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Validate("Your Reference", LibraryUtility.GenerateGUID);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, Type, No, LibraryRandom.RandInt(100));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);

        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateCoupledAndActiveItemAndProduct(var Item: Record Item; var CRMProduct: Record "CRM Product")
    begin
        LibraryCRMIntegration.CreateCoupledItemAndProduct(Item, CRMProduct);
        CRMProduct.Validate(StateCode, CRMProduct.StateCode::Active);
        CRMProduct.Modify(true);
    end;

    local procedure CreateCoupledAndActiveResourceAndProduct(var Resource: Record Resource; var CRMProduct: Record "CRM Product")
    begin
        LibraryCRMIntegration.CreateCoupledResourceAndProduct(Resource, CRMProduct);
        CRMProduct.Validate(StateCode, CRMProduct.StateCode::Active);
        CRMProduct.Modify(true);
    end;

    local procedure CreateCoupledAndTransactionCurrencies(var Currency: Record Currency; var CRMTransactioncurrency: Record "CRM Transactioncurrency")
    var
        CurrExchRateAmount: Decimal;
    begin
        LibraryCRMIntegration.CreateCoupledCurrencyAndNotLCYTransactionCurrency(Currency, CRMTransactioncurrency);
        CurrExchRateAmount := LibraryRandom.RandDec(100, 2);
        LibraryERM.CreateExchangeRate(Currency.Code, WorkDate, CurrExchRateAmount, CurrExchRateAmount);
    end;

    local procedure FindCRMPricelevelByCurrency(var CRMPricelevel: Record "CRM Pricelevel"; Currency: Record Currency)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
    begin
        CRMIntegrationRecord.FindByRecordID(Currency.RecordId);
        CRMTransactioncurrency.Get(CRMIntegrationRecord."CRM ID");
        CRMPricelevel.SetRange(TransactionCurrencyId, CRMTransactioncurrency.TransactionCurrencyId);
        CRMPricelevel.FindFirst;
    end;

    local procedure FindCRMProductpricelevelByItem(var CRMProductpricelevel: Record "CRM Productpricelevel"; Item: Record Item)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMProduct: Record "CRM Product";
    begin
        CRMIntegrationRecord.FindByRecordID(Item.RecordId);
        CRMProduct.Get(CRMIntegrationRecord."CRM ID");
        CRMProductpricelevel.SetRange(ProductId, CRMProduct.ProductId);
        CRMProductpricelevel.FindFirst;
    end;

    local procedure FindCRMUoMBySalesInvoicLineItem(var CRMUom: Record "CRM Uom"; InvoiceId: Guid; ProductId: Guid)
    var
        CRMInvoicedetail: Record "CRM Invoicedetail";
    begin
        CRMInvoicedetail.SetRange(InvoiceId, InvoiceId);
        CRMInvoicedetail.SetRange(ProductId, ProductId);
        CRMInvoicedetail.FindFirst;
        CRMUom.Get(CRMInvoicedetail.UoMId);
    end;

    local procedure FindSalesInvoiceLine(var SalesInvoiceLine: Record "Sales Invoice Line"; ItemNo: Code[20])
    begin
        SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::Item);
        SalesInvoiceLine.SetRange("No.", ItemNo);
        SalesInvoiceLine.FindFirst;
    end;

    local procedure GetExchangeRate(CurrencyCode: Code[10]; ConversionDate: Date): Decimal
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        exit(CurrencyExchangeRate.ExchangeRate(ConversionDate, CurrencyCode));
    end;

    local procedure PrepareCRMSalesOrder(var CRMSalesorder: Record "CRM Salesorder")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
    begin
        GeneralLedgerSetup.Get();
        LibraryCRMIntegration.CreateCRMTransactionCurrency(
          CRMTransactioncurrency, CopyStr(GeneralLedgerSetup."LCY Code", 1, MaxStrLen(CRMTransactioncurrency.ISOCurrencyCode)));
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        LibraryCRMIntegration.CreateCRMSalesOrderWithCustomerFCY(
          CRMSalesorder, CRMAccount.AccountId, CRMTransactioncurrency.TransactionCurrencyId);
    end;

    local procedure CreateCRMSalesOrderInFCY(var CRMSalesorder: Record "CRM Salesorder")
    var
        CRMAccount: Record "CRM Account";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        Customer: Record Customer;
        Currency: Record Currency;
        IntegrationRecord: Record "Integration Record";
    begin
        LibraryCRMIntegration.CreateCurrencyAndEnsureIntegrationRecord(Currency, IntegrationRecord);
        LibraryERM.CreateExchangeRate(Currency.Code, WorkDate, 1, LibraryRandom.RandDec(100, 2));
        LibraryCRMIntegration.CreateCRMTransactionCurrency(
          CRMTransactioncurrency,
          CopyStr(Currency.Code, 1, MaxStrLen(CRMTransactioncurrency.ISOCurrencyCode)));
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        LibraryCRMIntegration.CreateCRMSalesOrderWithCustomerFCY(
          CRMSalesorder, CRMAccount.AccountId, CRMTransactioncurrency.TransactionCurrencyId);
    end;

    local procedure ResetDefaultCRMSetupConfiguration()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSCompany: Record "CDS Company";
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
        CDSSetupDefaults: Codeunit "CDS Setup Defaults";
    begin
        CRMConnectionSetup.Get();
        CDSConnectionSetup.LoadConnectionStringElementsFromCRMConnectionSetup();
        CDSConnectionSetup."Ownership Model" := CDSConnectionSetup."Ownership Model"::Person;
        CDSConnectionSetup.Validate("Client Id", 'ClientId');
        CDSConnectionSetup.SetClientSecret('ClientSecret');
        CDSConnectionSetup.Validate("Redirect URL", 'RedirectURL');
        CDSConnectionSetup.Modify();
        LibraryCRMIntegration.EnsureCDSCompany(CDSCompany);
        CDSSetupDefaults.ResetConfiguration(CDSConnectionSetup);
        CRMSetupDefaults.ResetConfiguration(CRMConnectionSetup);
    end;

    local procedure BlockItem(var Item: Record Item)
    begin
        Item.Validate(Blocked, true);
        Item.Modify(true);
    end;

    local procedure BlockResource(var Resource: Record Resource)
    begin
        Resource.Validate(Blocked, true);
        Resource.Modify(true);
    end;

    local procedure VerifyTableMapping(TableID: Integer; IntegrationTableID: Integer; IntegrationDirection: Option; TableFilter: Text; IntegrationTableFilter: Text; SynchOnlyCoupledRecords: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        with IntegrationTableMapping do begin
            SetRange("Table ID", TableID);
            FindFirst;
            Assert.AreEqual(IntegrationDirection, Direction, FieldName(Direction));
            Assert.AreEqual(IntegrationTableID, "Integration Table ID", FieldName("Integration Table ID"));
            Assert.AreEqual(TableFilter, GetTableFilter, FieldName("Table Filter"));
            Assert.AreEqual(IntegrationTableFilter, GetIntegrationTableFilter, FieldName("Integration Table Filter"));
            Assert.AreEqual(SynchOnlyCoupledRecords, "Synch. Only Coupled Records", FieldName("Synch. Only Coupled Records"));
        end;
    end;

    local procedure VerifyCRMPriceLevel(CRMPricelevel: Record "CRM Pricelevel"; CurrencyCode: Code[10])
    begin
        CRMPricelevel.TestField(ExchangeRate, GetExchangeRate(CurrencyCode, WorkDate));
        CRMPricelevel.TestField(Name, StrSubstNo(CurrencyPriceListNameTxt, CurrencyCode));
    end;

    local procedure VerifyCRMProductpricelevel(CRMProductpricelevel: Record "CRM Productpricelevel"; ExpectedPriceLevelId: Guid; ExpectedUoMId: Guid; ExpectedUoMScheduleId: Guid; ExpectedAmount: Decimal)
    begin
        CRMProductpricelevel.TestField(PriceLevelId, ExpectedPriceLevelId);
        CRMProductpricelevel.TestField(UoMId, ExpectedUoMId);
        CRMProductpricelevel.TestField(UoMScheduleId, ExpectedUoMScheduleId);
        CRMProductpricelevel.TestField(Amount, ExpectedAmount);
    end;

    local procedure VerifyJobQueueEntriesInactivityTimeoutPeriod(NoOfMinutesBetweenRuns: Integer; ExpectedInactivityTimeoutPeriod: Integer; JobDescription: Text[250])
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"Integration Synch. Job Runner");
        JobQueueEntry.SetRange("No. of Minutes between Runs", NoOfMinutesBetweenRuns);
        JobQueueEntry.SetRange(Description, JobDescription);
        JobQueueEntry.FindFirst;
        Assert.AreEqual(ExpectedInactivityTimeoutPeriod, JobQueueEntry."Inactivity Timeout Period",
          'Inactivity time out period different from default.');
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmStartCoupling(Question: Text; var Reply: Boolean)
    begin
        Reply := ConfirmStartCouplingReply;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CoupleCustomerPage(var CRMCouplingRecord: TestPage "CRM Coupling Record")
    begin
        if CRMCouplingPageDoCancel then begin
            CRMCouplingRecord.Cancel.Invoke;
            exit;
        end;

        CRMCouplingRecord.OK.Invoke;
    end;

    [HyperlinkHandler]
    [Scope('OnPrem')]
    procedure CRMHyperlinkHandler(LinkAddress: Text)
    begin
        Assert.AreNotEqual('', LinkAddress, 'Did not expect the hyperlink to be empty');
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SyncStartedNotificationHandler(var SyncCompleteNotification: Notification): Boolean
    begin
        Assert.AreEqual(SyncNowScheduledMsg, SyncCompleteNotification.Message, 'Unexpected notification.');
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SyncStartedSkippedNotificationHandler(var SyncCompleteNotification: Notification): Boolean
    var
        ExpectedMessage: Text;
    begin
        ExpectedMessage := LibraryVariableStorage.DequeueText;
        Assert.AreEqual(ExpectedMessage, SyncCompleteNotification.Message, 'Unexpected notification.');
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure MultipleSyncStartedNotificationHandler(var SyncCompleteNotification: Notification): Boolean
    begin
        Assert.AreEqual(MultipleSyncStartedMsg, SyncCompleteNotification.Message, 'Unexpected notification.');
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;
}

