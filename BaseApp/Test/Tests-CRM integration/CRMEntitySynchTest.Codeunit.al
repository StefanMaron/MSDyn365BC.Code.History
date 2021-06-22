codeunit 139180 "CRM Entity Synch Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [CRM Integration]
    end;

    var
        Assert: Codeunit Assert;
        LibraryCRMIntegration: Codeunit "Library - CRM Integration";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
        CRMProductName: Codeunit "CRM Product Name";
        SynchDirection: Option Cancel,ToCRM,ToNAV;
        ConfirmReply: Boolean;
        FieldNotUpdatedErr: Label '%1 is not updated', Comment = '%1 = Field No.';
        SyncStartedMsg: Label 'The synchronization has been scheduled.';
        MultipleSyncStartedMsg: Label 'The synchronization has been scheduled for 2 of 4 records. 0 records failed. 2 records were skipped.';
        SalesPriceCoupledToDeletedRecErr: Label 'The Sales Price record cannot be updated because it is coupled to a deleted record.';
        ItemMustBeCoupledErr: Label 'Item No. %1 must be coupled to a record in %2.';
        SalesCodeMustBeCoupledErr: Label 'Sales Code %1 must be coupled to a record in %2.';
        SalespersonMustBeCoupledErr: Label 'Salesperson Code %1 must be coupled to a record in Dynamics 365 Sales.';

    [Test]
    [HandlerFunctions('SyncStartedNotificationHandler,StrMenuHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure SyncResourceFromResourceListPage()
    var
        Resource: Record Resource;
        CRM_Product: Record "CRM Product";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        ResourceList: TestPage "Resource List";
        JobQueueEntryID: Guid;
    begin
        // [FEATURE] [UI] [Resource]
        // [SCENARIO] Sync a coupled NAV resource to a CRM product
        Init;

        // [GIVEN] CRM is enabled
        LibraryCRMIntegration.ResetEnvironment;
        LibraryCRMIntegration.ConfigureCRM;
        LibraryCRMIntegration.CreateIntegrationTableMappingResourceProduct;

        // [GIVEN] A NAV Resource is coupled to a CRM product
        LibraryCRMIntegration.CreateCRMOrganization;
        LibraryCRMIntegration.CreateCoupledResourceAndProduct(Resource, CRM_Product);

        // [WHEN] The user clicks on the Synchronize Now action on the Resource List
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask;
        ResourceList.OpenView;
        ResourceList.FILTER.SetFilter("No.", Format(Resource."No."));
        ResourceList.CRMSynchronizeNow.Invoke;

        // [THEN] Notification "Syncronization has been scheduled." is shown.
        // Handled by SyncStartedNotificationHandler
        // execute scheduled job
        Resource.SetRecFilter;
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(DATABASE::Resource, Resource.GetView, IntegrationTableMapping);
        // [THEN] Job resulted in one modified record
        IntegrationSynchJob.Modified := 1;
        LibraryCRMIntegration.VerifySyncJob(JobQueueEntryID, IntegrationTableMapping, IntegrationSynchJob);
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 1;
    end;

    [Test]
    [HandlerFunctions('TestSyncMultipleCustomersStrMenuHandler,MultipleSyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure SyncMultipleCustomers()
    var
        Customer: Record Customer;
        ScheduledCustomer: array[2] of Record Customer;
        CRMAccount: Record "CRM Account";
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationTableMappingForJob: array[2] of Record "Integration Table Mapping";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        IntegrationSynchJob: Record "Integration Synch. Job";
        CustomerRecordRef: RecordRef;
        NameFieldRef: FieldRef;
        JobQueueEntryID: array[2] of Guid;
        SyncJobID: Guid;
    begin
        // [FEATURE] [Customer]
        // [SCENARIO] Synchronizing multiple customers
        Init;
        GetIntegrationTableMapping(DATABASE::Customer, IntegrationTableMapping);
        // [GIVEN] A customer previously synced with a CRM account and neither updated since
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        Customer.Name := 'TestCust1';
        Customer.Modify();
        ScheduledCustomer[1] := Customer;
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Customer.RecordId, true, false);

        // [GIVEN] An uncoupled customer
        LibrarySales.CreateCustomer(Customer);
        Customer.Name := 'TestCust2';
        Customer.Modify();

        // [GIVEN] A customer coupled to a CRM account with newer data (never synced)
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        Customer.Name := 'TestCust3';
        Customer.Modify();

        // [GIVEN] A customer with an uncoupled salesperson
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Customer.RecordId, true, false);
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        Customer."Salesperson Code" := SalespersonPurchaser.Code;
        Customer.Name := 'TestCust4';
        Customer.Modify();
        MockCRMIntegrationRecordsLastSync(Customer.RecordId, 0DT);
        ScheduledCustomer[2] := Customer;

        // [WHEN] Synchronizing the customers to CRM
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask;
        CustomerRecordRef := Customer.RecordId.GetRecord;
        NameFieldRef := CustomerRecordRef.Field(Customer.FieldNo(Name));
        NameFieldRef.SetFilter('TestCust*');
        SynchDirection := SynchDirection::ToCRM;
        CustomerRecordRef.FindFirst;
        CRMIntegrationManagement.UpdateMultipleNow(CustomerRecordRef);
        // Direction selected in TestSyncMultipleCustomersStrMenuHandler

        // [THEN] Notification "The synchronization has been scheduled for 2 of 4 records. 0 records failed. 2 records were skipped." is shown.
        // Handled by MultipleSyncStartedNotificationHandler

        // execute scheduled jobs
        IntegrationSynchJob.DeleteAll();
        ScheduledCustomer[2].SetRecFilter;
        JobQueueEntryID[2] :=
          LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::Customer, ScheduledCustomer[2].GetView, IntegrationTableMappingForJob[2]);
        Sleep(10); // to ensure order of synch jobs by start datetime
        ScheduledCustomer[1].SetRecFilter;
        JobQueueEntryID[1] :=
          LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::Customer, ScheduledCustomer[1].GetView, IntegrationTableMappingForJob[1]);

        // [THEN] Job for the 1st customer resulted in one modified record
        IntegrationSynchJob.Modified := 1;
        SyncJobID :=
          LibraryCRMIntegration.VerifySyncJob(JobQueueEntryID[1], IntegrationTableMappingForJob[1], IntegrationSynchJob);
        IntegrationSynchJob.Get(SyncJobID);
        IntegrationSynchJob.Delete();
        // [THEN] Job for the 4th customer resulted in failure due to a not coupled salesperson
        LibraryCRMIntegration.VerifySyncJobFailedOneRecord(
          JobQueueEntryID[2], IntegrationTableMappingForJob[2], StrSubstNo(SalespersonMustBeCoupledErr, SalespersonPurchaser.Code));
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure TestSyncMultipleCustomersStrMenuHandler(Options: Text; var Choice: Integer; Instruction: Text)
    begin
        Assert.ExpectedMessage('Synchronize data for the selected records', Instruction);
        Choice := SynchDirection;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncSingleCustomerCRMOptionFieldMapped()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
    begin
        // [FEATURE] [Customer] [Shipping Agent]
        // [SCENARIO] Sync should update the CRM Option field if the chosen record is mapped to an option value.
        Init;

        // [GIVEN] The customer, where "Shipping Agent" is 'DHL', is synced with the CRM account
        CreateCoupledCustomerWithShippingAgent(IntegrationTableMapping, Customer, CRMAccount, CRMAccount.Address1_ShippingMethodCodeEnum::DHL);

        // [GIVEN] "Shipping Agent" is changed from 'DHL' to 'WILLCALL' (a record mapped to the CRM option)
        Customer.Validate("Shipping Agent Code", 'WILLCALL');
        Customer.Modify();

        // [WHEN] Synchronizing the customer
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Customer.RecordId, true, false);

        // [THEN] CRM Account, where "Address1_ShippingMethodCodeEnum" = 'WILL CALL'
        CRMAccount.Find;
        CRMAccount.TestField(Address1_ShippingMethodCodeEnum, CRMAccount.Address1_ShippingMethodCodeEnum::WillCall);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncSingleCustomerCRMOptionFieldNotMapped()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
    begin
        // [FEATURE] [Customer] [Shipping Agent]
        // [SCENARIO] Sync should blank the CRM Option field if the chosen record is NOT mapped to any CRM option value.
        Init;

        // [GIVEN] The customer, where "Shipping Agent" is 'DHL', is synced with the CRM account
        CreateCoupledCustomerWithShippingAgent(IntegrationTableMapping, Customer, CRMAccount, CRMAccount.Address1_ShippingMethodCodeEnum::DHL);

        // [GIVEN] "Shipping Agent" is changed from 'DHL' to 'OWN LOG.' (a record is not mapped to the CRM option)
        Customer.Validate("Shipping Agent Code", 'OWN LOG.');
        Customer.Modify();

        // [WHEN] Synchronizing the customer
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Customer.RecordId, true, false);

        // [THEN] CRM Account, where "Address1_ShippingMethodCodeEnum" = ''
        CRMAccount.Find;
        CRMAccount.TestField(Address1_ShippingMethodCodeEnum, CRMAccount.Address1_ShippingMethodCodeEnum::" ");
    end;

    [Test]
    [HandlerFunctions('TestSyncSingleRecordStrMenuHandler,SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure SyncSingleCustomerUnmodified()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        JobQueueEntryID: Guid;
    begin
        // [FEATURE] [Customer]
        // [SCENARIO] Synchronizing a single unmodified customer
        Init;
        GetIntegrationTableMapping(DATABASE::Customer, IntegrationTableMapping);

        // [GIVEN] A customer previously synced with a CRM account and neither updated since
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Customer.RecordId, true, false);

        // [WHEN] Synchronizing the customer
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask;
        SynchDirection := SynchDirection::ToCRM;
        CRMIntegrationManagement.UpdateOneNow(Customer.RecordId);

        // [THEN] The user is asked to select the synchronization direction
        // [WHEN] The user selects synchronization to CRM
        // Happens in TestSyncSingleRecordStrMenuHandler
        Customer.SetRecFilter;
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::Customer, Customer.GetView, IntegrationTableMapping);

        // [THEN] Notification "Syncronization has been scheduled." is shown.
        // Handled by SyncStartedNotificationHandler
    end;

    [Test]
    [HandlerFunctions('TestSyncSingleRecordStrMenuHandler,SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure SyncSingleCustomerNAVModified()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        JobQueueEntryID: Guid;
        OriginalCustomerName: Text;
    begin
        // [FEATURE] [Customer]
        // [SCENARIO] Synchronizing a single customer modified in NAV
        Init;
        GetIntegrationTableMapping(DATABASE::Customer, IntegrationTableMapping);

        // [GIVEN] A customer previously synced with a CRM account and since modified in NAV
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        SetModifiedDateBackOneDayNAV(Customer.RecordId);
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Customer.RecordId, true, false);
        Customer.Name := 'Noon Ame';
        Customer.Modify();
        OriginalCustomerName := Customer.Name;

        // [WHEN] Synchronizing the customer
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask;
        SynchDirection := SynchDirection::ToCRM;
        CRMIntegrationManagement.UpdateOneNow(Customer.RecordId);

        // [THEN] The user is asked to select the synchronization direction
        // [WHEN] The user selects synchronization to CRM
        // Happens in TestSyncSingleRecordStrMenuHandler
        Customer.SetRecFilter;
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::Customer, Customer.GetView, IntegrationTableMapping);

        // [THEN] Notification "Syncronization has been scheduled." is shown.
        // Handled by SyncStartedNotificationHandler
        // [THEN] The data in CRM is overwritten with the data from NAV
        CRMAccount.Get(CRMAccount.AccountId);
        Assert.AreEqual(OriginalCustomerName, CRMAccount.Name,
          'The CRM account should have the name the customer had before');
    end;

    [Test]
    [HandlerFunctions('TestSyncSingleRecordStrMenuHandler,SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure SyncSingleCustomerCRMModified()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        OriginalCustomerName: Text;
        JobQueueEntryID: Guid;
    begin
        // [FEATURE] [Customer]
        // [SCENARIO] Synchronizing a single customer modified in CRM
        Init;
        GetIntegrationTableMapping(DATABASE::Customer, IntegrationTableMapping);

        // [GIVEN] A customer previously synced with a CRM account and since modified in CRM
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        CRMAccount.ModifiedOn := CreateDateTime(
            CalcDate('<-1D>', DT2Date(CRMAccount.ModifiedOn)), DT2Time(CRMAccount.ModifiedOn));
        CRMAccount.Modify();
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Customer.RecordId, true, false);
        CRMAccount.Name := 'Noon Ame';
        CRMAccount.ModifiedOn := CurrentDateTime;
        CRMAccount.Modify();
        OriginalCustomerName := Customer.Name;

        // [WHEN] Synchronizing the customer
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask;
        SynchDirection := SynchDirection::ToCRM;
        CRMIntegrationManagement.UpdateOneNow(Customer.RecordId);

        // [THEN] The user is asked to select the synchronization direction
        // [WHEN] The user selects synchronization to CRM
        // Happens in TestSyncSingleRecordStrMenuHandler
        Customer.SetRecFilter;
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::Customer, Customer.GetView, IntegrationTableMapping);

        // [THEN] Notification "Syncronization has been scheduled." is shown.
        // Handled by SyncStartedNotificationHandler
        // [THEN] The data in CRM is overwritten with the data from NAV
        CRMAccount.Get(CRMAccount.AccountId);
        Assert.AreEqual(OriginalCustomerName, CRMAccount.Name,
          'The CRM account should have the name the customer had before');
    end;

    [Test]
    [HandlerFunctions('TestSyncSingleCustomerBothModifiedMessageHandler,TestSyncSingleRecordStrMenuHandler,SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure SyncSingleCustomerBothModified()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        JobQueueEntryID: Guid;
        OriginalCustomerName: Text;
    begin
        // [FEATURE] [Customer]
        // [SCENARIO] Synchronizing a single customer modified in CRM and NAV, leads to forced modify of the destination
        Init;
        GetIntegrationTableMapping(DATABASE::Customer, IntegrationTableMapping);

        // [GIVEN] A coupled unsynced customer
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        CRMAccount.Name := StrSubstNo('Not%1', Customer.Name);
        CRMAccount.Modify();
        OriginalCustomerName := Customer.Name;

        // [WHEN] Synchronizing the customer
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask;
        SynchDirection := SynchDirection::ToCRM;
        CRMIntegrationManagement.UpdateOneNow(Customer.RecordId);

        // [THEN] The user is asked to select the synchronization direction
        // [WHEN] The user selects synchronization to CRM
        // Happens in TestSyncSingleRecordStrMenuHandler
        Customer.SetRecFilter;
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::Customer, Customer.GetView, IntegrationTableMapping);

        // [THEN] Notification "Syncronization has been scheduled." is shown.
        // Handled by SyncStartedNotificationHandler
        // [THEN] The data in CRM is overwritten with the data from NAV
        CRMAccount.Get(CRMAccount.AccountId);
        Assert.AreEqual(OriginalCustomerName, CRMAccount.Name,
          'The CRM account should have the name the customer had before');
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure TestSyncSingleCustomerBothModifiedMessageHandler(Message: Text)
    begin
        if StrPos(Message, 'data on one of the records will be lost') <> 0 then
            exit;
        if StrPos(Message, 'Synchronization completed') <> 0 then
            exit;
        Assert.Fail(StrSubstNo('Unexpected message:\%1', Message));
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure TestSyncSingleRecordStrMenuHandler(Options: Text; var Choice: Integer; Instruction: Text)
    begin
        Choice := SynchDirection;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure SyncSalespersonsSequently()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        SalespersonPurchaser: array[2] of Record "Salesperson/Purchaser";
        CRMSystemuser: array[2] of Record "CRM Systemuser";
        ExpectedParentName: Text;
    begin
        // [FEATURE] [Salesperson]
        // [SCENARIO 215216] Synchronizing a two salespersons modified in CRM/NAV sequently, so temporary mappings should not conflict
        Init;
        GetIntegrationTableMapping(DATABASE::"Salesperson/Purchaser", IntegrationTableMapping);
        ExpectedParentName := IntegrationTableMapping.Name;

        // [GIVEN] A salesperson previously synced with a CRM user and since updated in CRM
        LibraryCRMIntegration.CreateCoupledSalespersonAndSystemUser(SalespersonPurchaser[1], CRMSystemuser[1]);
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, CRMSystemuser[1].SystemUserId, true, false);
        CRMSystemuser[1].Find;
        CRMSystemuser[1].FullName := LibraryUtility.GenerateGUID;
        CRMSystemuser[1].Modify();
        // Mock CRM user Modified On changed
        MockCRMIntegrationRecordsLastSync(SalespersonPurchaser[1].RecordId, CRMSystemuser[1].ModifiedOn + 100);

        // [GIVEN] A salesperson previously synced with a CRM user and since updated in NAV
        LibraryCRMIntegration.CreateCoupledSalespersonAndSystemUser(SalespersonPurchaser[2], CRMSystemuser[2]);
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, CRMSystemuser[2].SystemUserId, true, false);
        Sleep(50);
        SalespersonPurchaser[2].Find;
        SalespersonPurchaser[2].Name := LibraryUtility.GenerateGUID;
        SalespersonPurchaser[2].Modify();

        // [GIVEN] Synchronizing the first salesperson
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask;
        CRMIntegrationManagement.UpdateOneNow(SalespersonPurchaser[1].RecordId);

        // [WHEN] Synchronizing the second salesperson
        CRMIntegrationManagement.UpdateOneNow(SalespersonPurchaser[2].RecordId);

        // [THEN] Before the actual sync, there are 3 mappings for table "Salesperson/Purchaser":
        IntegrationTableMapping.SetRange("Table ID", DATABASE::"Salesperson/Purchaser");
        Assert.RecordCount(IntegrationTableMapping, 3);
        // [THEN] two mappings are temporary, created as copies of the original 'SALESPEOPLE' one,
        // [THEN] where "Parent Name" = 'SALESPEOPLE', "Delete After Synchronization" = Yes
        IntegrationTableMapping.SetRange("Parent Name", ExpectedParentName);
        IntegrationTableMapping.SetRange("Delete After Synchronization", true);
        Assert.RecordCount(IntegrationTableMapping, 2);
    end;

    [Test]
    [HandlerFunctions('TestSyncSingleSalespersonCRMModifiedConfirmHandler,SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure SyncSingleSalespersonCRMModified()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CRMSystemuser: Record "CRM Systemuser";
        JobQueueEntryID: Guid;
    begin
        // [FEATURE] [Salesperson]
        Init;
        GetIntegrationTableMapping(DATABASE::"Salesperson/Purchaser", IntegrationTableMapping);

        // [SCENARIO] Synchronizing a single salesperson modified in CRM
        // [GIVEN] A salesperson previously synced with a CRM user and since updated in CRM
        LibraryCRMIntegration.CreateCoupledSalespersonAndSystemUser(SalespersonPurchaser, CRMSystemuser);
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, CRMSystemuser.SystemUserId, true, false);
        CRMSystemuser.FullName := 'Noon Ame';
        CRMSystemuser.Modify();

        // [WHEN] Synchronizing the salesperson
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask;
        CRMIntegrationManagement.UpdateOneNow(SalespersonPurchaser.RecordId);

        // [THEN] The user is asked to confirm synch
        // [WHEN] The user confirms
        // Happens in TestSyncSingleSalespersonCRMModifiedConfirmHandler
        CRMSystemuser.SetRecFilter;
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::"CRM Systemuser", CRMSystemuser.GetView, IntegrationTableMapping);

        // [THEN] Notification "Syncronization has been scheduled." is shown.
        // Handled by SyncStartedNotificationHandler
        // [THEN] The data in NAV is overwritten with the data from CRM
        SalespersonPurchaser.Get(SalespersonPurchaser.Code);
        Assert.AreEqual('Noon Ame', SalespersonPurchaser.Name,
          'The salesperson should have the name the CRM systemuser had before');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure TestSyncSingleSalespersonCRMModifiedConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(StrSubstNo('Get data update from %1 for', CRMProductName.SHORT), Question);
        Reply := true;
    end;

    [Test]
    [HandlerFunctions('TestSyncSingleSalespersonNAVModifiedConfirmHandler,SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure SyncSingleSalespersonNAVModified()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CRMSystemuser: Record "CRM Systemuser";
        JobQueueEntryID: Guid;
        OriginalCRMSystemuserName: Text;
    begin
        // [FEATURE] [Salesperson]
        Init;
        GetIntegrationTableMapping(DATABASE::"Salesperson/Purchaser", IntegrationTableMapping);

        // [SCENARIO] Synchronizing a single salesperson modified in NAV
        // [GIVEN] A salesperson previously synced with a CRM user and since updated in NAV
        LibraryCRMIntegration.CreateCoupledSalespersonAndSystemUser(SalespersonPurchaser, CRMSystemuser);
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, CRMSystemuser.SystemUserId, true, false);
        SetLastSyncDateBackOneDayCRM(CRMSystemuser.SystemUserId);
        SalespersonPurchaser.Get(SalespersonPurchaser.Code);
        SalespersonPurchaser.Name := 'Noon Ame';
        SalespersonPurchaser.Modify();
        OriginalCRMSystemuserName := CRMSystemuser.FullName;

        // [WHEN] Synchronizing the salesperson
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask;
        CRMIntegrationManagement.UpdateOneNow(SalespersonPurchaser.RecordId);

        // [THEN] The user is asked to confirm data replacement
        // [WHEN] The user confirms
        // Happens in TestSyncSingleSalespersonNAVModifiedConfirmHandler
        CRMSystemuser.SetRecFilter;
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::"CRM Systemuser", CRMSystemuser.GetView, IntegrationTableMapping);

        // [THEN] Notification "Syncronization has been scheduled." is shown.
        // Handled by SyncStartedNotificationHandler
        // [THEN] The data in NAV is overwritten with the data from CRM
        SalespersonPurchaser.Get(SalespersonPurchaser.Code);
        Assert.AreEqual(OriginalCRMSystemuserName, SalespersonPurchaser.Name,
          'The salesperson should have the name the CRM systemuser had before');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure TestSyncSingleSalespersonNAVModifiedConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(StrSubstNo('contains newer data than the %1 record. Get data', CRMProductName.SHORT), Question);
        Reply := true;
    end;

    [Test]
    [HandlerFunctions('TestSyncSingleSalespersonBothModifiedConfirmHandler,SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure SyncSingleSalespersonBothModified()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CRMSystemuser: Record "CRM Systemuser";
        JobQueueEntryID: Guid;
        OriginalCRMSystemuserName: Text;
        OriginalSalespersonName: Text;
    begin
        // [FEATURE] [Salesperson]
        Init;
        GetIntegrationTableMapping(DATABASE::"Salesperson/Purchaser", IntegrationTableMapping);

        // [SCENARIO] Synchronizing a single salesperson modified in both NAV and CRM
        // [GIVEN] A salesperson coupled to a CRM user but never synced
        LibraryCRMIntegration.CreateCoupledSalespersonAndSystemUser(SalespersonPurchaser, CRMSystemuser);
        OriginalCRMSystemuserName := CRMSystemuser.FullName;
        OriginalSalespersonName := SalespersonPurchaser.Name;

        // [WHEN] Synchronizing the salesperson
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask;
        ConfirmReply := false;
        CRMIntegrationManagement.UpdateOneNow(SalespersonPurchaser.RecordId);

        // [THEN] The user is warned sync has never taken place and asked to confirm data replacement
        // [WHEN] The user cancels
        // Happens in TestSyncSingleSalespersonBothModifiedConfirmHandler

        // [THEN] The data in NAV is not changed
        SalespersonPurchaser.Get(SalespersonPurchaser.Code);
        Assert.AreEqual(OriginalSalespersonName, SalespersonPurchaser.Name,
          'The salesperson should have the same name it had before');

        // [WHEN] The user tries again and this time does not cancel
        ConfirmReply := true;
        CRMIntegrationManagement.UpdateOneNow(SalespersonPurchaser.RecordId);

        // [THEN] The user is asked to confirm data replacement
        // [WHEN] The user confirms
        // Happens in TestSyncSingleSalespersonBothModifiedConfirmHandler
        CRMSystemuser.SetRecFilter;
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::"CRM Systemuser", CRMSystemuser.GetView, IntegrationTableMapping);

        // [THEN] Notification "Syncronization has been scheduled." is shown.
        // Handled by SyncStartedNotificationHandler
        // [THEN] The data in NAV is overwritten with the data from CRM
        SalespersonPurchaser.Get(SalespersonPurchaser.Code);
        Assert.AreEqual(OriginalCRMSystemuserName, SalespersonPurchaser.Name,
          'The salesperson should have the name the CRM systemuser had before');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure TestSyncSingleSalespersonBothModifiedConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Assert.ExpectedMessage('synchronization has never been performed', Question);
        Reply := ConfirmReply;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncOptionToPaymentTerms()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        PaymentTerms: Record "Payment Terms";
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
    begin
        // [FEATURE] [Payment Terms]
        Init;
        // [GIVEN] "Payment Terms" is empty
        PaymentTerms.DeleteAll();
        // [GIVEN] A default Table Mapping for "Payment Terms"
        IntegrationTableMapping.SetRange("Table ID", DATABASE::"Payment Terms");
        IntegrationTableMapping.FindFirst;
        // [WHEN] Sync the table
        CRMIntegrationTableSynch.SynchOption(IntegrationTableMapping);

        // [THEN] "Payment Terms" contains records according to CRM option PaymentTermsCode
        FillCodeBufferFromOption(IntegrationTableMapping, TempNameValueBuffer);
        TempNameValueBuffer.FindSet;
        repeat
            PaymentTerms.Get(TempNameValueBuffer.Name);
        until TempNameValueBuffer.Next = 0;
        Assert.AreEqual(TempNameValueBuffer.Count, PaymentTerms.Count, 'Wrong Payment Terms count.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncOptionToShipmentMethod()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        ShipmentMethod: Record "Shipment Method";
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
    begin
        // [FEATURE] [Shipment Method]
        Init;
        // [GIVEN] "Shipment Method" is empty
        ShipmentMethod.DeleteAll();
        // [GIVEN] A default Table Mapping for "Shipment Method"
        IntegrationTableMapping.SetRange("Table ID", DATABASE::"Shipment Method");
        IntegrationTableMapping.FindFirst;
        // [WHEN] Sync the table
        CRMIntegrationTableSynch.SynchOption(IntegrationTableMapping);

        // [THEN] "Shipment Method" contains records according to CRM option FreightTermsCode
        FillCodeBufferFromOption(IntegrationTableMapping, TempNameValueBuffer);
        TempNameValueBuffer.FindSet;
        repeat
            ShipmentMethod.Get(TempNameValueBuffer.Name);
        until TempNameValueBuffer.Next = 0;
        Assert.AreEqual(TempNameValueBuffer.Count, ShipmentMethod.Count, 'Wrong Shipment Method count.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncOptionToShippingAgent()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        ShippingAgent: Record "Shipping Agent";
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
    begin
        // [FEATURE] [Shipping Agent]
        Init;
        // [GIVEN] "Shipping Agent" is empty
        ShippingAgent.DeleteAll();
        // [GIVEN] A default Table Mapping for "Shipping Agent"
        IntegrationTableMapping.SetRange("Table ID", DATABASE::"Shipping Agent");
        IntegrationTableMapping.FindFirst;
        // [WHEN] Sync the table
        CRMIntegrationTableSynch.SynchOption(IntegrationTableMapping);

        // [THEN] "Shipping Agent" contains records according to CRM option ShippingMethodCode
        FillCodeBufferFromOption(IntegrationTableMapping, TempNameValueBuffer);
        TempNameValueBuffer.FindSet;
        repeat
            ShippingAgent.Get(TempNameValueBuffer.Name);
        until TempNameValueBuffer.Next = 0;
        Assert.AreEqual(TempNameValueBuffer.Count, ShippingAgent.Count, 'Wrong Shipping Agent count.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SynchModifiedRecordWithNonMappedFieldToCRM()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationSynchJob: Record "Integration Synch. Job";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
        LastSynchModifiedOn: DateTime;
    begin
        // [SCENARIO 380128] The timestamp of Integration Record should be updated when synch modified record with field which does not exist in Table Mapping

        Init;

        // [GIVEN] Customer "X" synced with CRM Account
        SetupCoupledCustomer(IntegrationTableMapping, Customer, CRMAccount);

        // Modify "Last Synch. Modified On" with one day back to make sure that new value is more than latest
        LastSynchModifiedOn := SetCRMIntegrationSyncOneDayBack(CRMIntegrationRecord, CRMAccount, Customer.RecordId);

        // [GIVEN] Modified field "Name 2" in NAV which is not mapped with CRM Account
        Customer.Validate("Name 2", CopyStr(Customer.Name, 1, MaxStrLen(Customer."Name 2")));
        Customer.Modify(true);
        IntegrationSynchJob.DeleteAll(); // make sure that after next synch there will be only one integration synch job

        // [WHEN] Sync Customer "X" to CRM
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Customer.RecordId, false, false);

        // [THEN] Integration Sync. Job tracked as "Unchanged"
        VerifyIntegrationSynchJob(IntegrationTableMapping.Name, 0, 1);

        // [THEN] "Last Synch. Modified On" of CRM Integration Record connected to Customer "X" is updated
        CRMIntegrationRecord.Find;
        Assert.IsTrue(
          CRMIntegrationRecord."Last Synch. Modified On" > LastSynchModifiedOn,
          StrSubstNo(FieldNotUpdatedErr, CRMIntegrationRecord.FieldNo("Last Synch. Modified On")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncModifiedCustomerWithAdditionalNonMappedFieldToCRM()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CRMSystemuser: Record "CRM Systemuser";
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationSynchJob: Record "Integration Synch. Job";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
        LastSynchModifiedOn: DateTime;
    begin
        // [SCENARIO 380128] The timestamp of Integration Record should be updated when synch Customer with updated Currency (not mapped but handled by specific method)

        Init;

        // [GIVEN] Coupled Salesperson "Y" to CRM User
        LibraryCRMIntegration.CreateCoupledSalespersonAndSystemUser(SalespersonPurchaser, CRMSystemuser);

        // [GIVEN] Customer "X" synced with CRM Account
        GetIntegrationTableMapping(DATABASE::Customer, IntegrationTableMapping);
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Customer.RecordId, true, false);

        // Modify "Last Synch. Modified On" with one day back to make sure that new value is more than latest
        LastSynchModifiedOn := SetCRMIntegrationSyncOneDayBack(CRMIntegrationRecord, CRMAccount, Customer.RecordId);

        // [GIVEN] Modified "Salesperson Code" with "Y" in NAV
        Customer.Validate("Salesperson Code", SalespersonPurchaser.Code);
        Customer.Modify(true);
        IntegrationSynchJob.DeleteAll();

        // [WHEN] Sync Customer "X" to CRM
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Customer.RecordId, false, false);

        // [THEN] Integration Sync. Job tracked as "Modified"
        VerifyIntegrationSynchJob(IntegrationTableMapping.Name, 1, 0);

        // [THEN] "Last Synch. Modified On" of CRM Integration Record connected to Customer "X" is updated
        CRMIntegrationRecord.Find;
        Assert.IsTrue(
          CRMIntegrationRecord."Last Synch. Modified On" > LastSynchModifiedOn,
          StrSubstNo(FieldNotUpdatedErr, CRMIntegrationRecord.FieldNo("Last Synch. Modified On")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IgnoreUnchangedWhenNoFieldsWereModifiedButSourceAndDestinationInConflict()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationSynchJob: Record "Integration Synch. Job";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
    begin
        // [SCENARIO 380985] Synchronization is finished successfully with result "Ignore unchanged" when no fields were modified but both source and destination are in conflict

        Init;

        // [GIVEN] Customer "X" synced with CRM Account
        SetupCoupledCustomer(IntegrationTableMapping, Customer, CRMAccount);

        // [GIVEN] Modified field "Name 2" in NAV which is not mapped with CRM Account
        Customer.Validate("Name 2", CopyStr(Customer.Name, 1, MaxStrLen(Customer."Name 2")));
        Customer.Modify(true);

        // [GIVEN] Modified field "E-mail address 3" in CRM which is not mapped with NAV Account
        CRMAccount.Find;
        CRMAccount.Validate(EMailAddress3, LibraryUtility.GenerateGUID);
        CRMAccount.Modify(true);

        // Modify "Last Synch. CRM Modified On" and "Modified One" with one day back to make sure that both Source and Destination are changed and in conflict
        SetCRMIntegrationSyncInConflict(CRMIntegrationRecord, CRMAccount, Customer.RecordId);

        IntegrationSynchJob.DeleteAll(); // make sure that after next synch there will be only one integration synch job

        // [WHEN] Sync Customer "X" to CRM
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Customer.RecordId, false, false);

        // [THEN] Integration Sync. Job tracked as "Unchanged"
        VerifyIntegrationSynchJob(IntegrationTableMapping.Name, 0, 1);
    end;

    [Test]
    [HandlerFunctions('SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure SyncNewCustPriceGrWithTwoSalesPrices()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMPricelevel: Record "CRM Pricelevel";
        CRMProductpricelevel: Record "CRM Productpricelevel";
        Item: array[2] of Record Item;
        CustomerPriceGroup: Record "Customer Price Group";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: array[2] of Record "Integration Table Mapping";
        SalesPrice: array[2] of Record "Sales Price";
        CRMProduct: array[2] of Record "CRM Product";
        JobQueueEntryID: Guid;
        I: Integer;
    begin
        // [FEATURE] [Price List]
        // [SCENARIO] New "Customer Price Group" with two "Sales Price" lines should be synched to CRM as an inserted Pricelist with 2 lines.
        Init;
        // [GIVEN] The Customer Price Group 'A' with two Sales Price lines
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        for I := 1 to 2 do begin
            LibraryCRMIntegration.CreateCoupledItemAndProduct(Item[I], CRMProduct[I]);
            LibrarySales.CreateSalesPrice(
              SalesPrice[I], Item[I]."No.", SalesPrice[I]."Sales Type"::"Customer Price Group", CustomerPriceGroup.Code,
              0D, '', '', '', 0, LibraryRandom.RandDecInRange(10, 100, 2));
        end;

        // [WHEN] Customer Price Group 'A' is coupled and synched with teh new CRM Price List
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask;
        CRMIntegrationManagement.CreateNewRecordsInCRM(CustomerPriceGroup.RecordId);
        CustomerPriceGroup.SetRecFilter;
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::"Customer Price Group", CustomerPriceGroup.GetView, IntegrationTableMapping[1]);

        // [THEN] CRM Price List is added, where Name = 'A'
        CRMIntegrationRecord.FindByRecordID(CustomerPriceGroup.RecordId);
        CRMPricelevel.Get(CRMIntegrationRecord."CRM ID");
        CRMPricelevel.TestField(Name, CustomerPriceGroup.Code);
        // [THEN] Two CRM Price list lines are inserted, where
        CRMProductpricelevel.SetRange(PriceLevelId, CRMPricelevel.PriceLevelId);
        Assert.RecordCount(CRMProductpricelevel, 2);
        IntegrationTableMapping[2].SetRange("Integration Table ID", DATABASE::"CRM Productpricelevel");
        IntegrationTableMapping[2].FindFirst;
        IntegrationSynchJob.SetRange("Integration Table Mapping Name", IntegrationTableMapping[2].Name);
        IntegrationSynchJob.FindLast;
        IntegrationSynchJob.TestField(Inserted, 2);
        // [THEN] "Product ID" and "Amount" are synched
        CRMProductpricelevel.SetRange(PriceLevelId, CRMPricelevel.PriceLevelId);
        CRMProductpricelevel.SetRange(ProductId, CRMProduct[1].ProductId);
        Assert.IsTrue(CRMProductpricelevel.FindFirst, 'Missing first price list line.');
        CRMProductpricelevel.TestField(Amount, SalesPrice[1]."Unit Price");
        CRMProductpricelevel.SetRange(ProductId, CRMProduct[2].ProductId);
        Assert.IsTrue(CRMProductpricelevel.FindFirst, 'Missing second price list line.');
        CRMProductpricelevel.TestField(Amount, SalesPrice[2]."Unit Price");
    end;

    [Test]
    [HandlerFunctions('SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure SyncNewSalesPriceIfCustPriceGroupIsNotModified()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMPricelevel: Record "CRM Pricelevel";
        CRMProductpricelevel: Record "CRM Productpricelevel";
        Item: array[2] of Record Item;
        CustomerPriceGroup: Record "Customer Price Group";
        ExpectedIntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        SalesPrice: array[2] of Record "Sales Price";
        CRMProduct: array[2] of Record "CRM Product";
        JobQueueEntryID: Guid;
    begin
        // [FEATURE] [Price List]
        // [SCENARIO] Added "Sales Price" should be synched to CRM even if the parent "Customer Price Group" is not changed
        Init;
        // [GIVEN] The Customer Price Group 'A', with one Sales Price line, is coupled and synched with CRM
        LibraryCRMIntegration.CreateCoupledItemAndProduct(Item[1], CRMProduct[1]);
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        LibrarySales.CreateSalesPrice(
          SalesPrice[1], Item[1]."No.", SalesPrice[1]."Sales Type"::"Customer Price Group", CustomerPriceGroup.Code,
          0D, '', '', '', 0, LibraryRandom.RandDecInRange(10, 100, 2));

        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask;
        CRMIntegrationManagement.CreateNewRecordsInCRM(CustomerPriceGroup.RecordId);
        CustomerPriceGroup.SetRecFilter;
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::"Customer Price Group", CustomerPriceGroup.GetView, IntegrationTableMapping);
        CRMIntegrationRecord.FindByRecordID(CustomerPriceGroup.RecordId);
        CRMPricelevel.Get(CRMIntegrationRecord."CRM ID");

        // [GIVEN] Add new price line for Customer Price Group 'A', Item '1001', where "Unit Price" is "X"
        LibraryCRMIntegration.CreateCoupledItemAndProduct(Item[2], CRMProduct[2]);
        LibrarySales.CreateSalesPrice(
          SalesPrice[2], Item[2]."No.", SalesPrice[2]."Sales Type"::"Customer Price Group", CustomerPriceGroup.Code,
          0D, '', '', '', 0, LibraryRandom.RandDecInRange(10, 100, 2));

        // [WHEN] "Synchronize Modified Recrods" on "Customer Price Group" mapping
        LibraryCRMIntegration.SynchronizeNowForTable(DATABASE::"Customer Price Group");

        // [THEN] CRM Price list line added, where Item is '1001', "Amount" is "X"
        CRMProductpricelevel.SetRange(PriceLevelId, CRMPricelevel.PriceLevelId);
        CRMProductpricelevel.SetRange(ProductId, CRMProduct[2].ProductId);
        Assert.IsTrue(CRMProductpricelevel.FindFirst, 'Missing price list line.');
        CRMProductpricelevel.TestField(Amount, SalesPrice[2]."Unit Price");
        // [THEN] One Integration Synch. Job for "CRM Productpricelevel", where "Inserted" = 1, "Unchnaged" = 1
        IntegrationSynchJob.SetRange("Integration Table Mapping Name", 'SALESPRC-PRODPRICE');
        Assert.RecordCount(IntegrationSynchJob, 2);
        IntegrationSynchJob.SetCurrentKey("Start Date/Time", ID);
        IntegrationSynchJob.FindLast;
        ExpectedIntegrationSynchJob.Inserted := 1;
        ExpectedIntegrationSynchJob.Unchanged := 1;
        LibraryCRMIntegration.VerifySyncRecCount(ExpectedIntegrationSynchJob, IntegrationSynchJob);
    end;

    [Test]
    [HandlerFunctions('SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure SyncModifiedSalesPriceIfCustPriceGroupIsNotModified()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMPricelevel: Record "CRM Pricelevel";
        CRMProductpricelevel: Record "CRM Productpricelevel";
        IntegrationTableMapping: Record "Integration Table Mapping";
        Item: Record Item;
        CustomerPriceGroup: Record "Customer Price Group";
        ExpectedIntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationSynchJob: Record "Integration Synch. Job";
        SalesPrice: Record "Sales Price";
        CRMProduct: Record "CRM Product";
        JobQueueEntryID: Guid;
        IntegrationTableMappingName: Code[20];
    begin
        // [FEATURE] [Price List]
        // [SCENARIO] Modified "Sales Price" should be synched to CRM even if the parent "Customer Price Group" is not changed
        Init;
        // [GIVEN] The Customer Price Group 'A' is coupled and synched with CRM
        LibraryCRMIntegration.CreateCoupledItemAndProduct(Item, CRMProduct);
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        // [GIVEN] one Sales Price line, where Item is '1001', Amount = 50.00
        LibrarySales.CreateSalesPrice(
          SalesPrice, Item."No.", SalesPrice."Sales Type"::"Customer Price Group", CustomerPriceGroup.Code,
          0D, '', '', '', 0, LibraryRandom.RandDecInRange(10, 100, 2));
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask;
        CRMIntegrationManagement.CreateNewRecordsInCRM(CustomerPriceGroup.RecordId);
        CustomerPriceGroup.SetRecFilter;
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::"Customer Price Group", CustomerPriceGroup.GetView, IntegrationTableMapping);
        // [GIVEN] Sales Price is modified, Amount = 100.00.
        SalesPrice."Unit Price" := SalesPrice."Unit Price" * 2;
        SalesPrice.Modify();
        MockCRMIntegrationRecordsLastSync(SalesPrice.RecordId, 0DT);

        // [WHEN] "Synchronize Modified Recrods" on "SALESPRC-PRODPRICE" mapping
        IntegrationTableMappingName := LibraryCRMIntegration.SynchronizeNowForTable(DATABASE::"Sales Price");

        // [THEN] CRM Price list line is modified, where Item is '1001', "Amount" is 100.00
        CRMIntegrationRecord.FindByRecordID(CustomerPriceGroup.RecordId);
        CRMPricelevel.Get(CRMIntegrationRecord."CRM ID");
        CRMProductpricelevel.SetRange(PriceLevelId, CRMPricelevel.PriceLevelId);
        CRMProductpricelevel.SetRange(ProductId, CRMProduct.ProductId);
        Assert.RecordCount(CRMProductpricelevel, 1);
        Assert.IsTrue(CRMProductpricelevel.FindFirst, 'Missing price list line.');
        CRMProductpricelevel.TestField(Amount, SalesPrice."Unit Price");
        // [THEN] One Integration Synch. Job for "CRM Productpricelevel", where "Modified" = 1
        IntegrationSynchJob.SetRange("Integration Table Mapping Name", IntegrationTableMappingName);
        Assert.RecordCount(IntegrationSynchJob, 2);
        IntegrationSynchJob.SetCurrentKey("Start Date/Time", ID);
        IntegrationSynchJob.FindLast;
        ExpectedIntegrationSynchJob.Modified := 1;
        LibraryCRMIntegration.VerifySyncRecCount(ExpectedIntegrationSynchJob, IntegrationSynchJob);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncModifiedSalesPriceIfCustPriceGroupIsNotCoupled()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMPricelevel: Record "CRM Pricelevel";
        Item: Record Item;
        CustomerPriceGroup: Record "Customer Price Group";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
        SalesPrice: Record "Sales Price";
        CRMProduct: Record "CRM Product";
        IntegrationTableMappingName: Code[20];
    begin
        // [FEATURE] [Price List]
        // [SCENARIO] Synchronization of "Sales Price" should fail if the parent "Customer Price Group" is not coupled
        Init;
        // [GIVEN] The Customer Price Group 'A' is coupled and synched with CRM
        LibraryCRMIntegration.CreateCoupledPriceGroupAndPricelevel(CustomerPriceGroup, CRMPricelevel);
        // [GIVEN] Added one Sales Price line to 'A'
        LibraryCRMIntegration.CreateCoupledItemAndProduct(Item, CRMProduct);
        LibrarySales.CreateSalesPrice(
          SalesPrice, Item."No.", SalesPrice."Sales Type"::"Customer Price Group", CustomerPriceGroup.Code,
          0D, '', '', '', 0, LibraryRandom.RandDecInRange(10, 100, 2));
        // [GIVEN] The Customer Price Group 'A' is decoupled
        CRMIntegrationRecord.FindByRecordID(CustomerPriceGroup.RecordId);
        CRMIntegrationRecord.Delete();

        // [WHEN] "Synchronize Modified Recrods" on "SALESPRC-PRODPRICE" mapping
        IntegrationTableMappingName := LibraryCRMIntegration.SynchronizeNowForTable(DATABASE::"Sales Price");

        // [THEN] Synchronization has failed with the error message: "Cannot find the coupled price list."
        IntegrationSynchJob.SetCurrentKey("Start Date/Time", ID);
        IntegrationSynchJob.SetRange("Integration Table Mapping Name", IntegrationTableMappingName);
        Assert.IsTrue(IntegrationSynchJob.FindLast, 'No IntegrationSynchJob for ' + IntegrationTableMappingName);
        IntegrationSynchJob.TestField(Failed, 1);
        IntegrationSynchJobErrors.SetRange("Integration Synch. Job ID", IntegrationSynchJob.ID);
        IntegrationSynchJobErrors.FindFirst;
        Assert.ExpectedMessage(
          StrSubstNo(SalesCodeMustBeCoupledErr, CustomerPriceGroup.Code, CRMProductName.SHORT), IntegrationSynchJobErrors.Message);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncDuplicateSalesPriceShouldCoupleRecords()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMPricelevel: Record "CRM Pricelevel";
        CRMProductpricelevel: Record "CRM Productpricelevel";
        Item: Record Item;
        CustomerPriceGroup: Record "Customer Price Group";
        IntegrationSynchJob: Record "Integration Synch. Job";
        SalesPrice: Record "Sales Price";
        CRMProduct: Record "CRM Product";
        IntegrationTableMappingName: Code[20];
    begin
        // [FEATURE] [Price List]
        // [SCENARIO] Synchronization of "Sales Price" that has a duplicate CRM Price List line should couple them.
        Init;
        // [GIVEN] The Customer Price Group 'A' is coupled and synched with CRM
        LibraryCRMIntegration.CreateCoupledPriceGroupAndPricelevel(CustomerPriceGroup, CRMPricelevel);
        // [GIVEN] CRMPricelevel has a line 'B', where 'Item No.' = '1001', "Unit Of Measure" = 'PCS', Amount = 100.00
        LibraryCRMIntegration.CreateCoupledItemAndProduct(Item, CRMProduct);
        LibraryCRMIntegration.CreateCRMPricelistLine(CRMProductpricelevel, CRMPricelevel, CRMProduct);
        // [GIVEN] Added Sales Price line 'C' for 'A', where 'Item No.' = '1001', "Unit Of Measure" = 'PCS', "Unit Price" = 150.00
        LibrarySales.CreateSalesPrice(
          SalesPrice, Item."No.", SalesPrice."Sales Type"::"Customer Price Group", CustomerPriceGroup.Code,
          0D, '', '', Item."Base Unit of Measure", 0, LibraryRandom.RandDecInRange(10, 100, 2));

        // [WHEN] "Synchronize Modified Recrods" on "SALESPRC-PRODPRICE" mapping
        IntegrationTableMappingName := LibraryCRMIntegration.SynchronizeNowForTable(DATABASE::"Sales Price");

        // [THEN] Sales Price "C" is coupled to CRMPricelevel line "B"
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(SalesPrice.RecordId), 'the new sales price is not coupled');
        Assert.AreEqual(
          CRMProductpricelevel.ProductPriceLevelId, CRMIntegrationRecord."CRM ID", 'the sales price is coupled to a wrong line');
        // [THEN] Synchronization has completed, where "Modified" = 1
        IntegrationSynchJob.SetCurrentKey("Start Date/Time", ID);
        IntegrationSynchJob.SetRange("Integration Table Mapping Name", IntegrationTableMappingName);
        Assert.IsTrue(IntegrationSynchJob.FindLast, 'No IntegrationSynchJob for ' + IntegrationTableMappingName);
        IntegrationSynchJob.TestField(Modified, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncPriceListForDecoupledItemShouldFail()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMPricelevel: Record "CRM Pricelevel";
        CRMProductpricelevel: array[2] of Record "CRM Productpricelevel";
        Item: array[2] of Record Item;
        CustomerPriceGroup: Record "Customer Price Group";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
        SalesPrice: array[2] of Record "Sales Price";
        IntegrationTableMappingName: Code[20];
    begin
        // [FEATURE] [Price List]
        // [SCENARIO] Synchronization of "Sales Price", where Item is decoupled, should fail.
        Init;

        // [GIVEN] The Customer Price Group 'A' is coupled and synched with CRM
        LibraryCRMIntegration.CreateCoupledPriceGroupAndPricelevel(CustomerPriceGroup, CRMPricelevel);
        // [GIVEN] One price line is coupled, but CRMProductpricelevel has been deleted
        LibraryCRMIntegration.CreateCoupledSalesPriceAndPricelistLine(CustomerPriceGroup, SalesPrice[1], CRMProductpricelevel[1]);
        CRMProductpricelevel[1].Delete();
        // [GIVEN] Second price line is not coupled and
        LibraryCRMIntegration.CreateCoupledSalesPriceAndPricelistLine(CustomerPriceGroup, SalesPrice[2], CRMProductpricelevel[2]);
        CRMIntegrationRecord.FindByRecordID(SalesPrice[2].RecordId);
        CRMIntegrationRecord.Delete();
        CRMProductpricelevel[2].Delete();
        // [GIVEN] Item '2' is also decoupled
        Item[2].Get(SalesPrice[2]."Item No.");
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(Item[2].RecordId), 'Item is not coupled.');
        CRMIntegrationRecord.Delete();

        // [WHEN] "Synchronize Modified Records" on "SALESPRC-PRODPRICE" mapping
        IntegrationTableMappingName := LibraryCRMIntegration.SynchronizeNowForTable(DATABASE::"Sales Price");

        // [THEN] Synchronization has completed, where "Failed" = 2
        IntegrationSynchJob.SetCurrentKey("Start Date/Time", ID);
        IntegrationSynchJob.SetRange("Integration Table Mapping Name", IntegrationTableMappingName);
        Assert.IsTrue(IntegrationSynchJob.FindLast, 'No IntegrationSynchJob for ' + IntegrationTableMappingName);
        IntegrationSynchJob.TestField(Failed, 2);
        // [THEN] Fist line failed with error "Sales Price coupled to a deleted record"
        IntegrationSynchJobErrors.SetRange("Integration Synch. Job ID", IntegrationSynchJob.ID);
        IntegrationSynchJobErrors.SetRange("Source Record ID", SalesPrice[1].RecordId);
        IntegrationSynchJobErrors.FindFirst;
        IntegrationSynchJobErrors.TestField(Message, SalesPriceCoupledToDeletedRecErr);
        // [THEN] Second line failed with error "Item '2' is not coupled."
        IntegrationSynchJobErrors.SetRange("Source Record ID", SalesPrice[2].RecordId);
        IntegrationSynchJobErrors.FindFirst;
        Assert.ExpectedMessage(
          StrSubstNo(ItemMustBeCoupledErr, SalesPrice[2]."Item No.", CRMProductName.SHORT), IntegrationSynchJobErrors.Message);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMSetupDefaultMakesCustomerCountryCodeMappingDirectionBidirectional()
    var
        RefCustomer: Record Customer;
        IntegrationFieldMapping: Record "Integration Field Mapping";
    begin
        // [FEATURE] [Customer]
        // [SCENARIO 223988] CRM Setup Defaults makes direction=Bidirectional for Customer.Country\Region Code field mapping
        Init;

        // [WHEN] CRM Setup Defaults is being run
        ResetDefaultCRMSetupConfiguration;

        // [THEN] Customer.Country\Region Code field mapping direction=Bidirectional
        FindIntegrationFieldMapping(DATABASE::Customer, RefCustomer.FieldNo("Country/Region Code"), IntegrationFieldMapping);
        IntegrationFieldMapping.TestField(Direction, IntegrationFieldMapping.Direction::Bidirectional);
    end;

    [Test]
    [HandlerFunctions('TestSyncSingleRecordStrMenuHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SyncItemUnitPriceIfCustPriceGroupExists()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMPricelevel: Record "CRM Pricelevel";
        Item: Record Item;
        CustomerPriceGroup: Record "Customer Price Group";
        SalesPrice: Record "Sales Price";
        CRMProduct: Record "CRM Product";
        IntegrationTableMapping: array[2] of Record "Integration Table Mapping";
    begin
        // [FEATURE] [Price List]
        // [SCENARIO] Changed "Unit Price" on the Item with defined Customer Price Group should not update the coupled Product Price Level.
        Init;
        SynchDirection := SynchDirection::ToCRM;

        GetIntegrationTableMapping(DATABASE::"Customer Price Group", IntegrationTableMapping[1]);
        GetIntegrationTableMapping(DATABASE::Item, IntegrationTableMapping[2]);

        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask;

        // [GIVEN] Customer Price Group.
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);

        // [GIVEN] Item coupled with CRM Product.
        LibraryCRMIntegration.CreateCoupledItemAndProduct(Item, CRMProduct);

        // [GIVEN] Sales Price for the Item and the Customer Price Group.
        LibrarySales.CreateSalesPrice(
          SalesPrice, Item."No.", SalesPrice."Sales Type"::"Customer Price Group", CustomerPriceGroup.Code,
          0D, '', '', '', 0, LibraryRandom.RandDec(100, 2));

        // [GIVEN] Customer Price Group is coupled with CRM Price Level and synched.
        LibraryCRMIntegration.CreatePricelevelAndCoupleWithPriceGroup(CustomerPriceGroup, CRMPricelevel, SalesPrice."Currency Code");
        CRMIntegrationManagement.UpdateOneNow(CustomerPriceGroup.RecordId);

        CustomerPriceGroup.SetRecFilter;
        LibraryCRMIntegration.RunJobQueueEntry(
          DATABASE::"Customer Price Group", CustomerPriceGroup.GetView, IntegrationTableMapping[1]);

        // [GIVEN] Item Unit Price is set.
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);

        // [WHEN] Item is synched with CRM.
        CRMIntegrationManagement.UpdateOneNow(Item.RecordId);

        Item.SetRecFilter;
        LibraryCRMIntegration.RunJobQueueEntry(
          DATABASE::Item, Item.GetView, IntegrationTableMapping[2]);

        // [THEN] Product Price Level for the Customer Price Group exist and its Amount is unchanged.
        CRMIntegrationRecord.FindByRecordID(CustomerPriceGroup.RecordId);
        CRMPricelevel.Get(CRMIntegrationRecord."CRM ID");
        VerifyCRMProductPriceLevelAmount(CRMProduct.ProductId, CRMPricelevel.PriceLevelId, SalesPrice."Unit Price");
    end;

    local procedure Init()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        MyNotifications: Record "My Notifications";
        UpdateCurrencyExchangeRates: Codeunit "Update Currency Exchange Rates";
    begin
        LibraryCRMIntegration.ResetEnvironment;
        LibraryCRMIntegration.ConfigureCRM;
        LibraryCRMIntegration.CreateCRMOrganization;
        CRMConnectionSetup.Get();
        CRMConnectionSetup.RefreshDataFromCRM;
        CRMConnectionSetup.Modify();
        ResetDefaultCRMSetupConfiguration;

        MyNotifications.InsertDefault(UpdateCurrencyExchangeRates.GetMissingExchangeRatesNotificationID, '', '', false);
    end;

    local procedure CreateCoupledCustomerWithShippingAgent(var IntegrationTableMapping: Record "Integration Table Mapping"; var Customer: Record Customer; var CRMAccount: Record "CRM Account"; AgentCodeOption: Integer)
    var
        DummyCRMAccount: Record "CRM Account";
    begin
        GetIntegrationTableMapping(DATABASE::Customer, IntegrationTableMapping);
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        DummyCRMAccount.Address1_ShippingMethodCodeEnum := AgentCodeOption;
        Customer.Validate("Shipping Agent Code", Format(DummyCRMAccount.Address1_ShippingMethodCodeEnum));
        Customer.Modify();

        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Customer.RecordId, true, false);
        // Verify the value is synched
        CRMAccount.Find;
        CRMAccount.TestField(Address1_ShippingMethodCodeEnum, AgentCodeOption);
    end;

    local procedure FillCodeBufferFromOption(IntegrationTableMapping: Record "Integration Table Mapping"; var TempNameValueBuffer: Record "Name/Value Buffer" temporary)
    var
        FieldRef: FieldRef;
        RecordRef: RecordRef;
        CommaPos: Integer;
        OptionString: Text;
        OptionValue: Text;
    begin
        TempNameValueBuffer.DeleteAll();
        RecordRef.Open(IntegrationTableMapping."Integration Table ID");
        FieldRef := RecordRef.Field(IntegrationTableMapping."Integration Table UID Fld. No.");
        RecordRef.Close;
        OptionString := FieldRef.OptionMembers;
        while StrLen(OptionString) > 0 do begin
            CommaPos := StrPos(OptionString, ',');
            if CommaPos = 0 then begin
                OptionValue := OptionString;
                OptionString := '';
            end else begin
                OptionValue := CopyStr(OptionString, 1, CommaPos - 1);
                OptionString := CopyStr(OptionString, CommaPos + 1);
            end;
            if DelChr(OptionValue, '=', ' ') <> '' then begin
                TempNameValueBuffer.Init();
                TempNameValueBuffer.ID += 1;
                TempNameValueBuffer.Name := CopyStr(OptionValue, 1, MaxStrLen(TempNameValueBuffer.Name));
                TempNameValueBuffer.Insert
            end;
        end;
    end;

    local procedure FindIntegrationFieldMapping(TableID: Integer; FieldID: Integer; var IntegrationFieldMapping: Record "Integration Field Mapping")
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        IntegrationTableMapping.SetRange("Table ID", TableID);
        IntegrationTableMapping.FindFirst;
        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", IntegrationTableMapping.Name);
        IntegrationFieldMapping.SetRange("Field No.", FieldID);
        IntegrationFieldMapping.FindFirst;
    end;

    local procedure GetIntegrationTableMapping(TableNo: Integer; var IntegrationTableMapping: Record "Integration Table Mapping")
    begin
        IntegrationTableMapping.SetRange("Table ID", TableNo);
        IntegrationTableMapping.FindFirst;
    end;

    local procedure MockCRMIntegrationRecordsLastSync(RecID: RecordID; NewDateTime: DateTime)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(RecID), 'Source record is not coupled.');
        CRMIntegrationRecord."Last Synch. Modified On" := NewDateTime;
        CRMIntegrationRecord.Modify();
    end;

    local procedure SetModifiedDateBackOneDayNAV(RecordID: RecordID)
    var
        IntegrationRecord: Record "Integration Record";
    begin
        IntegrationRecord.FindByRecordId(RecordID);
        IntegrationRecord."Modified On" := OneDayBefore(IntegrationRecord."Modified On");
        IntegrationRecord.Modify();
    end;

    local procedure SetLastSyncDateBackOneDayCRM(CRMID: Guid)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        CRMIntegrationRecord.SetRange("CRM ID", CRMID);
        CRMIntegrationRecord.FindFirst;
        CRMIntegrationRecord."Last Synch. Modified On" := OneDayBefore(CRMIntegrationRecord."Last Synch. Modified On");
        CRMIntegrationRecord.Modify();
    end;

    local procedure SetupCoupledCustomer(var IntegrationTableMapping: Record "Integration Table Mapping"; var Customer: Record Customer; var CRMAccount: Record "CRM Account")
    var
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
    begin
        LibraryCRMIntegration.CreateIntegrationTableMappingCustomer(IntegrationTableMapping);
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Customer.RecordId, true, false);
    end;

    local procedure SetCRMIntegrationSyncOneDayBack(var CRMIntegrationRecord: Record "CRM Integration Record"; var CRMAccount: Record "CRM Account"; CustomerID: RecordID): DateTime
    var
        IntegrationRecord: Record "Integration Record";
    begin
        IntegrationRecord.FindByRecordId(CustomerID);
        CRMIntegrationRecord.Get(CRMAccount.AccountId, IntegrationRecord."Integration ID");
        CRMAccount.Find; // get latest version after sync

        CRMIntegrationRecord."Last Synch. Modified On" := OneDayBefore(CRMIntegrationRecord."Last Synch. Modified On");
        CRMIntegrationRecord.Modify();
        CRMAccount.ModifiedOn := OneDayBefore(CRMAccount.ModifiedOn);
        CRMAccount.Modify();
        exit(CRMIntegrationRecord."Last Synch. Modified On");
    end;

    local procedure SetCRMIntegrationSyncInConflict(var CRMIntegrationRecord: Record "CRM Integration Record"; var CRMAccount: Record "CRM Account"; CustomerID: RecordID)
    var
        IntegrationRecord: Record "Integration Record";
    begin
        IntegrationRecord.FindByRecordId(CustomerID);
        CRMIntegrationRecord.Get(CRMAccount.AccountId, IntegrationRecord."Integration ID");
        CRMAccount.Find;

        CRMAccount.ModifiedOn := OneDayBefore(CRMAccount.ModifiedOn);
        CRMAccount.Modify();
        CRMIntegrationRecord."Last Synch. CRM Modified On" := OneDayBefore(CRMAccount.ModifiedOn);
        CRMIntegrationRecord.Modify();
    end;

    local procedure VerifyCRMProductPriceLevelAmount(CRMProductId: Guid; CRMPriceLevelId: Guid; ExpectedAmount: Decimal)
    var
        CRMProductpricelevel: Record "CRM Productpricelevel";
    begin
        with CRMProductpricelevel do begin
            SetRange(ProductId, CRMProductId);
            SetRange(PriceLevelId, CRMPriceLevelId);
            FindFirst;
            TestField(Amount, ExpectedAmount);
        end;
    end;

    local procedure OneDayBefore(DateTime: DateTime): DateTime
    begin
        exit(CreateDateTime(CalcDate('<-1D>', DT2Date(DateTime)), DT2Time(DateTime)));
    end;

    local procedure ResetDefaultCRMSetupConfiguration()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CDSConnectionSetup: Record "CDS Connection Setup";
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
        CDSSetupDefaults: Codeunit "CDS Setup Defaults";
    begin
        CRMConnectionSetup.Get();
        CDSConnectionSetup.LoadConnectionStringElementsFromCRMConnectionSetup();
        CDSConnectionSetup."Ownership Model" := CDSConnectionSetup."Ownership Model"::Person;
        CDSConnectionSetup.Modify();
        CDSSetupDefaults.ResetConfiguration(CDSConnectionSetup);
        CRMSetupDefaults.ResetConfiguration(CRMConnectionSetup);
    end;

    local procedure VerifyIntegrationSynchJob(IntegrationTableMappingName: Code[20]; Modified: Integer; Unchanged: Integer)
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
    begin
        IntegrationSynchJob.SetRange("Integration Table Mapping Name", IntegrationTableMappingName);
        IntegrationSynchJob.FindFirst;
        IntegrationSynchJob.TestField(Modified, Modified);
        IntegrationSynchJob.TestField(Unchanged, Unchanged);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SyncStartedNotificationHandler(var SyncCompleteNotification: Notification): Boolean
    begin
        Assert.AreEqual(SyncStartedMsg, SyncCompleteNotification.Message, 'Unexpected notification.');
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure MultipleSyncStartedNotificationHandler(var SyncCompleteNotification: Notification): Boolean
    begin
        Assert.AreEqual(MultipleSyncStartedMsg, SyncCompleteNotification.Message, 'Unexpected notification.');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

