codeunit 139165 "Integration Table Synch. Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [CRM Integration] [Integration Table Synch.]
    end;

    var
        Assert: Codeunit Assert;
        LibraryCRMIntegration: Codeunit "Library - CRM Integration";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        IntTableSynchSubscriber: Codeunit "Int. Table Synch. Subscriber";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        SourceRecordRef: RecordRef;
        DestinationRecordRef: RecordRef;
        IsInitialized: Boolean;
        SyncStartedMsg: Label 'The synchronization has been scheduled.';
        MapIsNotConfiguredErr: Label 'The Integration Table Mapping %1 is not configured for %2 synchronization.';
        TablesDoNotMatchMappingErr: Label 'Source table %1 and destination table %2 do not match integration table mapping %3.', Comment = '%1,%2 - tables Ids; %2 - name of the mapping.';
        NoFieldMappingErr: Label 'There are no field mapping rows';

    [Test]
    [Scope('OnPrem')]
    procedure IntegrationSynchJobEntryIsCreated()
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
    begin
        // [FEATURE] [Integration Synch. Job]
        // [SCENARIO] BeginIntegrationSynchJob() should fail if integration parameters are not defined
        Initialize;
        // [GIVEN] Integration services are not enabled
        // [GIVEN] No Integration Table Mapping have been defined
        // [GIVEN] Source and Destination records have not been opened
        IntegrationTableMapping.Init();
        Clear(IntegrationTableMapping);

        // [WHEN] Starting the Table Sync
        Assert.IsTrue(
          IsNullGuid(IntegrationTableSynch.BeginIntegrationSynchJob(TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, 0)),
          'Expected the begin integration synch job task to fail');

        // [THEN] An Integration Synch. Job record is created
        Assert.AreNotEqual(0, IntegrationSynchJob.Count, 'Expected an Integration Synch Job to be created despite of fatal error');
        IntegrationSynchJob.FindFirst;
        // [THEN] Job Info finish time is set
        Assert.AreNotEqual(0DT, IntegrationSynchJob."Finish Date/Time", 'Expected finish time to be set');
        // [THEN] Finish time is >= Start time
        Assert.IsTrue(IntegrationSynchJob."Finish Date/Time" - IntegrationSynchJob."Start Date/Time" >= 0,
          'Expected finish time to be later than start time');
        // [THEN] Message is set (error)
        Assert.AreNotEqual('', IntegrationSynchJob.Message, 'Expected message to be set');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProcessFailsIfNavTableIsNotRegisteredAsIntegrationTable()
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
    begin
        // [FEATURE] [Integration Synch. Job]
        // [SCENARIO] BeginIntegrationSynchJob() should fail if a table is not registered as a Integration Table
        Initialize;

        ResetDefaultCRMSetupConfiguration;
        // [GIVEN] The normal table is not registered as a Integration Table (integration records will not be created)
        IntegrationTableMapping.Get('CUSTOMER');
        IntegrationTableMapping."Table ID" := DATABASE::"License Agreement";

        // [WHEN] Starting the Table Sync with Source NOT participating in integration records
        Assert.IsTrue(
          IsNullGuid(
            IntegrationTableSynch.BeginIntegrationSynchJob(
              TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, IntegrationTableMapping."Table ID")),
          'Expected the begin integration synch job task to fail when Table ID is not registered and participating in integration records');

        // [THEN] The process should fail with a message
        IntegrationSynchJob.FindFirst;
        Assert.AreNotEqual('', IntegrationSynchJob.Message, 'Expected sync process to fail with message');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MissingFieldMappingFailsHard()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
    begin
        // [SCENARIO] Synchronize() should fail if mapping is not defined

        // [GIVEN] The Field Mapping has no fields
        InitializeTestForFromIntegrationTableSynch(IntegrationTableMapping);
        IntegrationFieldMapping.DeleteAll();

        IntegrationTableSynch.BeginIntegrationSynchJob(
          TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, SourceRecordRef.Number);
        // [WHEN] Starting the Table Sync
        asserterror IntegrationTableSynch.Synchronize(SourceRecordRef, DestinationRecordRef, false, false);
        // [THEN] Error message "There are no field mapping rows..."
        Assert.ExpectedError(NoFieldMappingErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProcessingZeroRows()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
    begin
        // [SCENARIO] Synchronize() should not call item callback handlers for an empty table

        // [GIVEN] Source table has no rows
        InitializeTestForFromIntegrationTableSynch(IntegrationTableMapping);
        LibraryCRMIntegration.CreateIntegrationTableData(0, 0);

        IntegrationTableSynch.BeginIntegrationSynchJob(
          TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, IntegrationTableMapping."Table ID");
        // [WHEN] Running the Table Sync
        IntegrationTableSynch.Synchronize(SourceRecordRef, DestinationRecordRef, false, false);

        // [THEN] The process should succeed
        // [THEN] None of the item callback handlers should be called.
        IntTableSynchSubscriber.VerifyCallbackCounters(0, 0, 0, 0, 0, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertModifyRowsFromIntegrationTable()
    var
        UnitOfMeasure: Record "Unit of Measure";
        IntegrationRecord: Record "Integration Record";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
    begin
        // [FEATURE] [Integration Synch. Job]
        // [SCENARIO] Synchronize() should sync a modified record

        InitializeTestForToIntegrationTableSynch(IntegrationTableMapping);
        // [GIVEN] Source table has 1 row
        LibraryCRMIntegration.CreateIntegrationTableData(1, 0);
        SourceRecordRef.FindFirst;

        // [GIVEN] Destination rows have already been synchronized and integration records exists.
        IntegrationTableSynch.BeginIntegrationSynchJob(
          TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, IntegrationTableMapping."Table ID");
        IntegrationTableSynch.Synchronize(SourceRecordRef, DestinationRecordRef, false, true);
        IntegrationTableSynch.EndIntegrationSynchJob;
        IntTableSynchSubscriber.VerifyCallbackCounters(1, 1, 1, 1, 0, 0);
        IntegrationSynchJob.FindFirst;
        Assert.AreEqual(1, IntegrationSynchJob.Inserted, 'Expected the Job Info to record 1 inserted item');

        IntTableSynchSubscriber.Reset();
        IntegrationSynchJob.DeleteAll();

        // [GIVEN] Destination row is modified and has last modified field set > last sync.
        UnitOfMeasure.FindFirst;
        UnitOfMeasure.Description := 'MODIFIED';
        UnitOfMeasure.Modify(true);
        IntegrationRecord.FindByRecordId(UnitOfMeasure.RecordId);
        IntegrationRecord."Modified On" :=
          CreateDateTime(CalcDate('<+1D>', DT2Date(IntegrationRecord."Modified On")), DT2Time(IntegrationRecord."Modified On"));
        IntegrationRecord.Modify(); // We need to update the modified on in tests because to date comparison is rounded to seconds)

        SourceRecordRef.Reset();

        // [WHEN] Running the Table Sync
        IntegrationTableSynch.BeginIntegrationSynchJob(
          TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, IntegrationTableMapping."Table ID");
        IntegrationTableSynch.Synchronize(SourceRecordRef, DestinationRecordRef, true, false);
        IntegrationTableSynch.EndIntegrationSynchJob;

        // [THEN] The process should succeed
        // [THEN] The item callback handlers should be called 1 times for each item on before/after field transfer
        // [THEN] The item callback handlers should be called 0 times for each item on before/after insert
        // [THEN] The item callback handlers should be called 1 times for each item on before/after modify
        IntTableSynchSubscriber.VerifyCallbackCounters(1, 1, 0, 0, 1, 1);

        // [THEN] The job should record 1 item was modified
        IntegrationSynchJob.FindFirst;
        Assert.AreEqual(1, IntegrationSynchJob.Modified, 'Expected the Job Info to record 1 modified item');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertRowsFromIntegrationTable()
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
    begin
        // [SCENARIO] Synchronize() should sync records inserted into an integration table

        InitializeTestForFromIntegrationTableSynch(IntegrationTableMapping);
        // [GIVEN] Source Integration table has 1 row
        LibraryCRMIntegration.CreateIntegrationTableData(0, 1);
        // [GIVEN] Destination table has no rows and no integration records exists

        // [WHEN] Running the Table Sync
        IntegrationTableSynch.BeginIntegrationSynchJob(
          TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, SourceRecordRef.Number);
        if SourceRecordRef.FindFirst then
            repeat
                IntegrationTableSynch.Synchronize(SourceRecordRef, DestinationRecordRef, false, true);
            until SourceRecordRef.Next = 0;
        IntegrationTableSynch.EndIntegrationSynchJob;

        // [THEN] The process should succeed
        // [THEN] The item callback handlers should be called 1 times for each item on before/after field transfer
        // [THEN] The item callback handlers should be called 1 times for each item on before/after insert
        // [THEN] The item callback handlers should be called 0 times for each item on before/after modify
        // [THEN] The job should record 1 inserted item for each item inserted.
        IntTableSynchSubscriber.VerifyCallbackCounters(1, 1, 1, 1, 0, 0);

        // [GIVEN] Source Integration table has 2 rows
        LibraryCRMIntegration.CreateIntegrationTableData(0, 2);
        IntTableSynchSubscriber.Reset();
        IntegrationSynchJob.DeleteAll();

        // [WHEN] Running the Table Sync
        IntegrationTableSynch.BeginIntegrationSynchJob(
          TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, SourceRecordRef.Number);
        if SourceRecordRef.FindFirst then
            repeat
                IntegrationTableSynch.Synchronize(SourceRecordRef, DestinationRecordRef, false, true);
            until SourceRecordRef.Next = 0;
        IntegrationTableSynch.EndIntegrationSynchJob;

        // [THEN] The process should succeed
        // [THEN] The item callback handlers should be called 2 times for each item on before/after field transfer
        // [THEN] The item callback handlers should be called 2 times for each item on before/after insert
        // [THEN] The item callback handlers should be called 0 times for each item on before/after modify
        IntTableSynchSubscriber.VerifyCallbackCounters(2, 2, 2, 2, 0, 0);
        IntegrationSynchJob.FindFirst;
        // [THEN] The job should record 2 inserted item for each item inserted.
        Assert.AreEqual(2, IntegrationSynchJob.Inserted, 'Expected the Job Info to record 2 inserted items');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ModifyRowFromIntegrationTable()
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
        TestIntegrationTable: Record "Test Integration Table";
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
    begin
        // [FEATURE] [Integration Synch. Job]
        // [SCENARIO] Synchronize() should sync records modified in an integration table

        InitializeTestForFromIntegrationTableSynch(IntegrationTableMapping);
        // [GIVEN] Source Integration table has 1 row
        LibraryCRMIntegration.CreateIntegrationTableData(0, 1);
        // [GIVEN] Rows have already been synchronized and integration records exists.
        IntegrationTableSynch.BeginIntegrationSynchJob(
          TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, SourceRecordRef.Number);
        if SourceRecordRef.FindFirst then
            repeat
                IntegrationTableSynch.Synchronize(SourceRecordRef, DestinationRecordRef, false, true);
            until SourceRecordRef.Next = 0;
        IntegrationTableSynch.EndIntegrationSynchJob;

        IntTableSynchSubscriber.VerifyCallbackCounters(1, 1, 1, 1, 0, 0);

        IntTableSynchSubscriber.Reset();
        IntegrationSynchJob.DeleteAll();

        // [GIVEN] Source row is modified and has last modified field set > last sync.
        TestIntegrationTable.FindFirst;
        TestIntegrationTable."Integration Field Value" := 'MODIFIED';
        TestIntegrationTable."Integration Modified Field" :=
          CreateDateTime(CalcDate('<+1D>', DT2Date(TestIntegrationTable."Integration Modified Field")), Time);
        TestIntegrationTable.Modify(true);

        SourceRecordRef.Reset();

        // [WHEN] Running the Table Sync
        IntegrationTableSynch.BeginIntegrationSynchJob(
          TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, SourceRecordRef.Number);
        if SourceRecordRef.FindFirst then
            repeat
                IntegrationTableSynch.Synchronize(SourceRecordRef, DestinationRecordRef, false, false);
            until SourceRecordRef.Next = 0;
        IntegrationTableSynch.EndIntegrationSynchJob;

        // [THEN] The process should succeed
        // [THEN] The item callback handlers should be called 1 times for each item on before/after field transfer
        // [THEN] The item callback handlers should be called 0 times for each item on before/after insert
        // [THEN] The item callback handlers should be called 1 times for each item on before/after modify
        IntTableSynchSubscriber.VerifyCallbackCounters(1, 1, 0, 0, 1, 1);

        // [THEN] The job should record 1 item was modified
        IntegrationSynchJob.FindFirst;
        Assert.AreEqual(1, IntegrationSynchJob.Modified, 'Expected the Job Info to record 1 modified item');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnchangedRowFromIntegrationTable()
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
    begin
        // [FEATURE] [Integration Synch. Job]
        // [SCENARIO] Synchronize() should sync records not modified in an integration table

        InitializeTestForFromIntegrationTableSynch(IntegrationTableMapping);
        // [GIVEN] Source table has 1 row
        LibraryCRMIntegration.CreateIntegrationTableData(0, 1);
        // [GIVEN] Destination rows have already been synchronized and integration records exists.
        IntegrationTableSynch.BeginIntegrationSynchJob(
          TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, SourceRecordRef.Number);
        if SourceRecordRef.FindFirst then
            repeat
                IntegrationTableSynch.Synchronize(SourceRecordRef, DestinationRecordRef, false, true);
            until SourceRecordRef.Next = 0;
        IntegrationTableSynch.EndIntegrationSynchJob;
        // [GIVEN] Destination row has not been modified

        // [GIVEN] Callback handler sets the modified flag
        IntTableSynchSubscriber.VerifyCallbackCounters(1, 1, 1, 1, 0, 0);

        IntTableSynchSubscriber.Reset();
        IntegrationSynchJob.DeleteAll();

        // [WHEN] Running the Table Sync
        IntegrationTableSynch.BeginIntegrationSynchJob(
          TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, SourceRecordRef.Number);
        if SourceRecordRef.FindFirst then
            repeat
                IntegrationTableSynch.Synchronize(SourceRecordRef, DestinationRecordRef, false, false);
            until SourceRecordRef.Next = 0;
        IntegrationTableSynch.EndIntegrationSynchJob;

        // [THEN] The process should succeed
        // [THEN] The item callback handlers should be called 0 times for each item on before/after field transfer
        // [THEN] The item callback handlers should be called 0 times for each item on before/after insert
        // [THEN] The item callback handlers should be called 0 times for each item on before/after modify
        IntTableSynchSubscriber.VerifyCallbackCounters(0, 0, 0, 0, 0, 0);

        // [THEN] The job should record 1 item was Unchanged
        IntegrationSynchJob.FindFirst;
        Assert.AreEqual(1, IntegrationSynchJob.Unchanged, 'Expected the Job Info to record 1 unchanged item');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnchangedButModifiedByCallbackRowFromIntegrationTable()
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
    begin
        // [FEATURE] [Integration Synch. Job]
        // [SCENARIO] Synchronize() should sync records not modified in an integration table, but marked as modified

        InitializeTestForFromIntegrationTableSynch(IntegrationTableMapping);
        // [GIVEN] Source table has 1 row
        LibraryCRMIntegration.CreateIntegrationTableData(0, 1);

        // [GIVEN] Destination rows have already been synchronized and integration records exists.
        IntegrationTableSynch.BeginIntegrationSynchJob(
          TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, IntegrationTableMapping."Integration Table ID");
        if SourceRecordRef.FindFirst then
            repeat
                IntegrationTableSynch.Synchronize(SourceRecordRef, DestinationRecordRef, false, true);
            until SourceRecordRef.Next = 0;
        IntegrationTableSynch.EndIntegrationSynchJob;

        IntTableSynchSubscriber.Reset();
        IntegrationSynchJob.DeleteAll();

        // [GIVEN] Destination row has not been modified
        // [GIVEN] Callback handler for fieldtransfer sets the modified flag
        IntTableSynchSubscriber.SetFlags(true);

        // [WHEN] Running the Table Sync
        IntegrationTableSynch.BeginIntegrationSynchJob(
          TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, IntegrationTableMapping."Integration Table ID");
        if SourceRecordRef.FindFirst then
            repeat
                IntegrationTableSynch.Synchronize(SourceRecordRef, DestinationRecordRef, false, false);
            until SourceRecordRef.Next = 0;

        IntegrationTableSynch.EndIntegrationSynchJob;
        // [THEN] Row is not modified and job info records 0 modified item
        IntTableSynchSubscriber.VerifyCallbackCounters(0, 0, 0, 0, 0, 0);
        IntegrationSynchJob.FindFirst;
        Assert.AreEqual(1, IntegrationSynchJob.Unchanged, 'Expected the Job Info to record 1 unchanged item');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FailedRecordedOnDeletedRecord()
    var
        CRMAccount: Record "CRM Account";
        CRMIntegrationRecord: Record "CRM Integration Record";
        Customer: Record Customer;
        IntegrationRecord: Record "Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
    begin
        // [FEATURE] [Integration Synch. Job]
        // [SCENARIO] Synchronize() should create a failed sync job if the source record is deleted
        Initialize;
        IntegrationSynchJob.DeleteAll();

        SourceRecordRef.Open(DATABASE::"CRM Account");
        SourceRecordRef.DeleteAll();
        DestinationRecordRef.Open(DATABASE::Customer);
        // [GIVEN] A Customer is coupled with a CRM Account
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        if not IntegrationRecord.FindByRecordId(Customer.RecordId) then
            Assert.Fail('An Integration record was not found for the test customer');

        // [GIVEN] A Customer is deleted, coupling is corrupted
        CRMIntegrationRecord.FindByCRMID(CRMAccount.AccountId);
        CRMIntegrationRecord.Delete();
        Customer.Delete(true);
        CRMIntegrationRecord.Insert();
        if not (IntegrationRecord."Deleted On" > 0DT) then begin
            IntegrationRecord."Deleted On" := CurrentDateTime;
            IntegrationRecord.Modify();
        end;

        SourceRecordRef.GetTable(CRMAccount);

        ResetDefaultCRMSetupConfiguration;
        IntegrationTableMapping.SetRange("Table ID", DATABASE::Customer);
        IntegrationTableMapping.FindFirst;

        // [WHEN] Running the Table Sync
        IntegrationTableSynch.BeginIntegrationSynchJob(
          TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, SourceRecordRef.Number);
        IntegrationTableSynch.Synchronize(SourceRecordRef, DestinationRecordRef, false, false);

        // [THEN] 1 record is skipped in a sync job
        IntegrationSynchJob.FindFirst;
        Assert.AreEqual(1, IntegrationSynchJob.Skipped, 'Expected 1 record to skip');

        IntTableSynchSubscriber.VerifyCallbackCounters(0, 0, 0, 0, 0, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConfigTemplateIsAppliedIfPresent()
    var
        CRMAccount: Record "CRM Account";
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        CRMIntegrationRecord: Record "CRM Integration Record";
        Customer: Record Customer;
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplateLine: Record "Config. Template Line";
        IntegrationSynchJob: Record "Integration Synch. Job";
        Location: Record Location;
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
        RecordID: RecordID;
        CustomerRecordRef: RecordRef;
        CRMAccountRecordRef: RecordRef;
    begin
        // [FEATURE] [Config. Template]
        // [SCENARIO] Synchronize() should apply config. template values if it exists and defined in the mapping
        Initialize;
        ResetDefaultCRMSetupConfiguration;

        // [GIVEN] Customer config template, where "Location Code" =  'SOMELOCATION'
        LibraryWarehouse.CreateLocation(Location);

        ConfigTemplateHeader.Init();
        ConfigTemplateHeader.Code := CopyStr(
            LibraryUtility.GenerateRandomCode(ConfigTemplateHeader.FieldNo(Code), DATABASE::"Config. Template Header"),
            1,
            MaxStrLen(ConfigTemplateHeader.Code));
        ConfigTemplateHeader."Table ID" := DATABASE::Customer;
        ConfigTemplateHeader.Insert();

        // Create lines
        ConfigTemplateLine.Init();
        ConfigTemplateLine."Data Template Code" := ConfigTemplateHeader.Code;
        ConfigTemplateLine."Line No." := 1;
        ConfigTemplateLine."Field ID" := Customer.FieldNo("Location Code");
        ConfigTemplateLine."Default Value" := Location.Code;
        ConfigTemplateLine.Insert();

        // [GIVEN] Integration Table Mapping for Customer, where config template is defined
        IntegrationTableMapping.SetRange("Table ID", DATABASE::Customer);
        IntegrationTableMapping.FindFirst;
        IntegrationTableMapping."Table Config Template Code" := ConfigTemplateHeader.Code;

        // [GIVEN] Field "Location Code" is not mapped
        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", IntegrationTableMapping.Name);
        IntegrationFieldMapping.SetRange("Field No.", Customer.FieldNo("Location Code"));
        Assert.IsFalse(IntegrationFieldMapping.FindFirst, 'Test should only run on umapped field');

        // Prepare source and Destination references
        CustomerRecordRef.Open(DATABASE::Customer);
        CRMAccount.DeleteAll();
        CRMAccountRecordRef.Open(DATABASE::"CRM Account");
        LibraryCRMIntegration.CreateCRMAccountWithCoupledOwner(CRMAccount);
        CRMAccountRecordRef.GetTable(CRMAccount);
        IntegrationSynchJob.DeleteAll();

        // [WHEN] Running the Table Sync
        IntegrationTableSynch.BeginIntegrationSynchJob(
          TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, CRMAccountRecordRef.Number);
        IntegrationTableSynch.Synchronize(CRMAccountRecordRef, CustomerRecordRef, false, true);

        // [THEN] Row is inserted
        IntTableSynchSubscriber.VerifyCallbackCounters(1, 1, 1, 1, 0, 0);
        IntegrationSynchJob.SetRange("Integration Table Mapping Name", IntegrationTableMapping.Name);
        IntegrationSynchJob.FindFirst;
        Assert.AreEqual(1, IntegrationSynchJob.Inserted, 'Expected the Job Info to record 1 inserted item');

        // [THEN] Customer, where "Location Code" = 'SOMELOCATION'
        CRMIntegrationRecord.FindRecordIDFromID(
          CRMAccount.AccountId, DATABASE::Customer, RecordID);
        Customer.Get(RecordID);
        Assert.AreEqual(ConfigTemplateLine."Default Value", Customer."Location Code", 'Location Code to be taken from the template');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MissingConfigTemplateThrowsError()
    var
        CRMAccount: Record "CRM Account";
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        Customer: Record Customer;
        ConfigTemplateHeader: Record "Config. Template Header";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
        CustomerRecordRef: RecordRef;
        CRMAccountRecordRef: RecordRef;
        ConfigTemplateName: Text[10];
    begin
        // [FEATURE] [Config. Template]
        // [SCENARIO] Synchronize() should fail if config. template doesn't exist, but defined in the mapping
        Initialize;
        ResetDefaultCRMSetupConfiguration;

        ConfigTemplateName := LibraryUtility.GenerateRandomCode(ConfigTemplateHeader.FieldNo(Code), DATABASE::"Config. Template Header");

        // [GIVEN] Integration Table Mapping for Customer, where non-existing config template is defined
        IntegrationTableMapping.SetRange("Table ID", DATABASE::Customer);
        IntegrationTableMapping.FindFirst;
        IntegrationTableMapping."Table Config Template Code" := ConfigTemplateName;

        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", IntegrationTableMapping.Name);
        IntegrationFieldMapping.SetRange("Field No.", Customer.FieldNo("Location Code"));
        Assert.IsFalse(IntegrationFieldMapping.FindFirst, 'Test should only run on umapped field');

        // Prepare source and Destination references
        CustomerRecordRef.Open(DATABASE::Customer);
        CRMAccount.DeleteAll();
        CRMAccountRecordRef.Open(DATABASE::"CRM Account");
        LibraryCRMIntegration.CreateCRMAccountWithCoupledOwner(CRMAccount);
        CRMAccountRecordRef.GetTable(CRMAccount);

        // [WHEN] Running the Table Sync
        IntegrationTableSynch.BeginIntegrationSynchJob(
          TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, CRMAccountRecordRef.Number);
        IntegrationTableSynch.Synchronize(CRMAccountRecordRef, DestinationRecordRef, false, true);

        // [THEN] After Insert handler will not be called.
        IntTableSynchSubscriber.VerifyCallbackCounters(1, 1, 1, 0, 0, 0);
        // [THEN] 1 record sync will be failed
        IntegrationSynchJob.SetRange("Integration Table Mapping Name", IntegrationTableMapping.Name);
        IntegrationSynchJob.FindFirst;
        Assert.AreEqual(1, IntegrationSynchJob.Failed, 'Expected the Job Info to record 1 failed item');
        // [THEN] CRMAccount is not coupled
        Assert.IsFalse(CRMIntegrationRecord.FindByCRMID(CRMAccount.AccountId), 'CRM Account should not be coupled.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SynchRecordsMustBeToOrFromIntegrationTable()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
        EmptyRecordRef: RecordRef;
    begin
        // [FEATURE] [Direction]
        Initialize;

        IntegrationSynchJob.Reset();

        // [GIVEN] Source table is closed.
        IntegrationSynchJob.DeleteAll();
        IntegrationTableMapping.Init();
        IntegrationTableMapping.Name := 'SALESPEOPLE';
        IntegrationTableMapping."Table ID" := DATABASE::"Salesperson/Purchaser";
        IntegrationTableMapping."Integration Table ID" := DATABASE::"CRM Systemuser";
        IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::Bidirectional;

        // [WHEN] Running Synch.
        Assert.IsFalse(
          IsNullGuid(
            IntegrationTableSynch.BeginIntegrationSynchJob(
              TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, SourceRecordRef.Number)),
          'Test requires begin integration synch job to succeed');
        Assert.IsFalse(IntegrationTableSynch.Synchronize(EmptyRecordRef, EmptyRecordRef, false, false), 'Synchronize should fail');
        IntegrationTableSynch.EndIntegrationSynchJob;
        // [THEN] Fatal error is written to the Message field on the IntegrationSynchJob.
        Assert.IsTrue(IntegrationSynchJob.FindFirst, 'Expected to find a job entry');
        Assert.AreEqual(
          StrSubstNo(TablesDoNotMatchMappingErr, 0, 0, IntegrationTableMapping.Name),
          IntegrationSynchJob.Message, 'Close Source RecordRef is a fatal error and a message is expected.');

        // [GIVEN] Direction is ToIntegrationTable
        IntegrationSynchJob.DeleteAll();
        IntegrationTableMapping.Init();
        IntegrationTableMapping.Name := 'CUSTOMER';
        IntegrationTableMapping."Table ID" := DATABASE::Customer;
        IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::ToIntegrationTable;

        // [GIVEN] Source table is open but different from expected Source table No.
        SourceRecordRef.Close;
        SourceRecordRef.Open(DATABASE::"CRM Account");
        // [WHEN] Running Synch.
        Assert.IsFalse(
          IsNullGuid(
            IntegrationTableSynch.BeginIntegrationSynchJob(
              TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, SourceRecordRef.Number)),
          'Test requires begin integration synch job to succeed');
        Assert.IsFalse(IntegrationTableSynch.Synchronize(SourceRecordRef, EmptyRecordRef, false, false), 'Synchronize should fail');
        IntegrationTableSynch.EndIntegrationSynchJob;
        // [THEN] Fatal error is written to the Message field on the IntegrationSynchJob.
        Assert.IsTrue(IntegrationSynchJob.FindFirst, 'Expected to find a job entry');
        Assert.AreEqual(
          StrSubstNo(TablesDoNotMatchMappingErr, 5341, 0, IntegrationTableMapping.Name),
          IntegrationSynchJob.Message,
          'Source RecordRef pointing to a different record than expected is a fatal error and a message is expected.');

        // [GIVEN] Direction is FromIntegrationTable
        IntegrationSynchJob.DeleteAll();
        IntegrationTableMapping.Init();
        IntegrationTableMapping.Name := 'CUSTOMER';
        IntegrationTableMapping."Table ID" := DATABASE::Customer;
        IntegrationTableMapping."Integration Table ID" := DATABASE::"CRM Account";
        IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::FromIntegrationTable;
        // [GIVEN] Source table is open but different from expected Source table No.
        SourceRecordRef.Close;
        SourceRecordRef.Open(DATABASE::Customer);
        // [WHEN] Running Synch.
        Assert.IsFalse(
          IsNullGuid(
            IntegrationTableSynch.BeginIntegrationSynchJob(
              TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, SourceRecordRef.Number)),
          'Test requires begin integration synch job to succeed');
        Assert.IsFalse(IntegrationTableSynch.Synchronize(SourceRecordRef, EmptyRecordRef, false, false), 'Synchronize should fail');
        IntegrationTableSynch.EndIntegrationSynchJob;
        // [THEN] Fatal error is written to the Message field on the IntegrationSynchJob.
        Assert.IsTrue(IntegrationSynchJob.FindFirst, 'Expected to find a job entry');
        Assert.AreEqual(
          StrSubstNo(TablesDoNotMatchMappingErr, 18, 0, IntegrationTableMapping.Name),
          IntegrationSynchJob.Message,
          'Source RecordRef pointing to a different record than expected is a fatal error and a message is expected.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UncoupledRecordFoundInFindRecord()
    var
        CRMAccount: Record "CRM Account";
        Customer: Record Customer;
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
        SourceRecordRef: RecordRef;
        DestinationRecordRef: RecordRef;
        CoupledRecordID: RecordID;
    begin
        Initialize;

        ResetDefaultCRMSetupConfiguration;
        IntegrationTableMapping.Get('CUSTOMER');

        // [GIVEN] Source table has uncoupled row
        LibraryCRMIntegration.CreateCRMAccount(CRMAccount);
        LibrarySales.CreateCustomer(Customer);
        Assert.AreNotEqual(Customer.Name, CRMAccount.Name, 'Did not expect the two new records to have same name');
        IntegrationSynchJob.DeleteAll();

        // [GIVEN] Subscriber of FindDestinationRecord event finds valid record (not based on coupling but ex. Customer phone number/Account phone number)
        IntTableSynchSubscriber.SetFindRecordResults(Customer.RecordId, true, false);

        // [WHEN] Running the Table Sync
        SourceRecordRef.GetTable(CRMAccount);
        IntegrationTableSynch.BeginIntegrationSynchJob(
          TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, SourceRecordRef.Number);
        IntegrationTableSynch.Synchronize(SourceRecordRef, DestinationRecordRef, true, false);

        Assert.IsTrue(IntegrationSynchJob.FindFirst, 'Expected to find a job entry');
        Assert.AreEqual('', IntegrationSynchJob.Message, 'Did not expected an error message to be set');

        Assert.IsTrue(
          CRMIntegrationRecord.FindRecordIDFromID(
            CRMAccount.AccountId, DATABASE::Customer, CoupledRecordID),
          'Expected the CRM record to be coupled after synch.');
        // [THEN] The source row gets coupled to the found row by the custom subscriber.
        Assert.AreEqual(Customer.RecordId, CoupledRecordID, 'Expected the custom Destination mapping to find the customer record');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotSynchAgainstMappingDirection()
    var
        CRMAccount: Record "CRM Account";
        Customer: Record Customer;
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
        SourceRecordRef: RecordRef;
    begin
        // [FEATURE] [Direction]
        Initialize;
        ResetDefaultCRMSetupConfiguration;
        IntegrationTableMapping.Get('CUSTOMER');

        // [GIVEN] Customer Integration Mapping with direction ToIntegrationTable
        IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::ToIntegrationTable;
        // [GIVEN] Valid CRMAccount
        LibraryCRMIntegration.CreateCRMAccount(CRMAccount);
        SourceRecordRef.GetTable(CRMAccount);
        IntegrationSynchJob.DeleteAll();
        IntegrationSynchJobErrors.DeleteAll();

        // [WHEN] Begin Integration Synch Job, seeting CRM table as the source
        IntegrationSynchJob.Get(
          IntegrationTableSynch.BeginIntegrationSynchJob(
            TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, SourceRecordRef.Number));

        // [THEN] Synchronization job is finished, Message = 'The Integration Table Mapping is not configured for FromIntegrationTable synchronization.'
        IntegrationSynchJob.TestField("Finish Date/Time");
        IntegrationSynchJob.TestField(Skipped, 0);
        IntegrationSynchJob.TestField(Failed, 0);
        IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::FromIntegrationTable;
        Assert.ExpectedMessage(
          StrSubstNo(MapIsNotConfiguredErr, IntegrationTableMapping.Name, IntegrationTableMapping.Direction), IntegrationSynchJob.Message);

        // [GIVEN] Customer Integration Mapping with direction FromIntegrationTable
        IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::FromIntegrationTable;
        // [GIVEN] Valid Customer
        LibrarySales.CreateCustomer(Customer);
        SourceRecordRef.GetTable(Customer);
        IntegrationSynchJob.DeleteAll();
        IntegrationSynchJobErrors.DeleteAll();

        // [WHEN] Begin Integration Synch Job, seeting NAV table as the source
        Clear(IntegrationTableSynch);
        IntegrationSynchJob.Get(
          IntegrationTableSynch.BeginIntegrationSynchJob(
            TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, SourceRecordRef.Number));

        // [THEN] Synchronization job is finished, Message = 'The Integration Table Mapping is not configured for ToIntegrationTable synchronization.'
        IntegrationSynchJob.TestField("Finish Date/Time");
        IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::ToIntegrationTable;
        Assert.ExpectedMessage(
          StrSubstNo(MapIsNotConfiguredErr, IntegrationTableMapping.Name, IntegrationTableMapping.Direction), IntegrationSynchJob.Message);
        IntegrationSynchJob.TestField(Skipped, 0);
        IntegrationSynchJob.TestField(Failed, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OneWaySynchIgnoresDestinationChanges()
    var
        CRMAccount: Record "CRM Account";
        Customer: Record Customer;
        IntegrationRecord: Record "Integration Record";
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
    begin
        // [FEATURE] [Integration Synch. Job]
        Initialize;
        ResetDefaultCRMSetupConfiguration;
        IntegrationTableMapping.Get('CUSTOMER');

        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        IntegrationRecord.FindByRecordId(Customer.RecordId);

        // Verify both sides are considered newer.
        Assert.IsTrue(
          CRMIntegrationRecord.IsModifiedAfterLastSynchonizedCRMRecord(
            CRMAccount.AccountId, DATABASE::Customer, CRMAccount.ModifiedOn),
          'Expected the CRMAccount to be newer then last synched');
        Assert.IsTrue(
          CRMIntegrationRecord.IsModifiedAfterLastSynchronizedRecord(
            Customer.RecordId, CRMAccount.ModifiedOn),
          'Expected the customer to be newer then last synched');

        // [GIVEN] Integration mapping direction is ToIntegrationRecord
        // [WHEN] Performing synch.
        // [THEN] Destination changes are ignored and overwritten.
        IntegrationSynchJob.DeleteAll();
        IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::ToIntegrationTable;
        IntegrationTableMapping.Modify();
        SourceRecordRef.GetTable(Customer);

        IntegrationTableSynch.BeginIntegrationSynchJob(
          TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, IntegrationTableMapping."Table ID");
        IntegrationTableSynch.Synchronize(SourceRecordRef, DestinationRecordRef, false, false);
        IntegrationTableSynch.EndIntegrationSynchJob;

        IntegrationSynchJob.SetFilter("Integration Table Mapping Name", IntegrationTableMapping.Name);
        IntegrationSynchJob.FindFirst;
        Assert.AreEqual(1, IntegrationSynchJob.Modified, 'Expected the destination to be modified');

        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        IntegrationRecord.FindByRecordId(Customer.RecordId);
        // Verify both sides are considered newer.
        Assert.IsTrue(
          CRMIntegrationRecord.IsModifiedAfterLastSynchonizedCRMRecord(
            CRMAccount.AccountId, DATABASE::Customer, CRMAccount.ModifiedOn),
          'Expected the CRMAccount to be newer then last synched');
        Assert.IsTrue(
          CRMIntegrationRecord.IsModifiedAfterLastSynchronizedRecord(
            Customer.RecordId, CRMAccount.ModifiedOn),
          'Expected the customer to be newer then last synched');

        // [GIVEN] Integration mapping direction is ToIntegrationRecord
        // [WHEN] Performing synch.
        // [THEN] Destination changes are ignored and overwritten.
        IntegrationSynchJob.DeleteAll();
        IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::FromIntegrationTable;
        IntegrationTableMapping.Modify();
        SourceRecordRef.GetTable(CRMAccount);
        IntegrationTableSynch.BeginIntegrationSynchJob(
          TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, IntegrationTableMapping."Integration Table ID");
        IntegrationTableSynch.Synchronize(SourceRecordRef, DestinationRecordRef, false, false);
        IntegrationSynchJob.FindFirst;
        Assert.AreEqual(1, IntegrationSynchJob.Modified, 'Expected the destination to be modified');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SynchNewIntegrationTableRecord()
    var
        CRMAccount: Record "CRM Account";
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
        SourceRecordRef: RecordRef;
    begin
        Initialize;
        ResetDefaultCRMSetupConfiguration;
        IntegrationTableMapping.Get('CUSTOMER');

        // [GIVEN] Integration Table record is new
        // [GIVEN] Integration Table record is not coupled
        // [WHEN] Running synch.
        // [THEN] The Destination record is created
        IntegrationTableSynch.BeginIntegrationSynchJob(
          TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, IntegrationTableMapping."Integration Table ID");
        LibraryCRMIntegration.CreateCRMAccountWithCoupledOwner(CRMAccount);
        SourceRecordRef.GetTable(CRMAccount);

        IntegrationTableSynch.Synchronize(SourceRecordRef, DestinationRecordRef, false, true);

        // Verify
        IntTableSynchSubscriber.VerifyCallbackCounters(1, 1, 1, 1, 0, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SynchNewRecord()
    var
        Customer: Record Customer;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CRMSystemuser: Record "CRM Systemuser";
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
        SourceRecordRef: RecordRef;
    begin
        Initialize;
        ResetDefaultCRMSetupConfiguration;
        IntegrationTableMapping.Get('CUSTOMER');

        // [GIVEN] Record is new
        // [GIVEN] Record is not coupled
        // [WHEN] Running synch.
        // [THEN] The Destination record is created
        LibraryCRMIntegration.CreateCoupledSalespersonAndSystemUser(SalespersonPurchaser, CRMSystemuser);
        LibrarySales.CreateCustomer(Customer);
        Customer."Salesperson Code" := SalespersonPurchaser.Code;
        Customer.Modify();
        SourceRecordRef.GetTable(Customer);

        IntegrationTableSynch.BeginIntegrationSynchJob(
          TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, IntegrationTableMapping."Table ID");
        IntegrationTableSynch.Synchronize(SourceRecordRef, DestinationRecordRef, false, true);

        // Verify
        IntTableSynchSubscriber.VerifyCallbackCounters(1, 1, 1, 1, 0, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SynchCoupledIntegrationTableRecord()
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        IntegrationRecord: Record "Integration Record";
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
        SourceRecordRef: RecordRef;
    begin
        // [FEATURE] [Modified On]
        Initialize;
        ResetDefaultCRMSetupConfiguration;
        IntegrationTableMapping.Get('CUSTOMER');

        // [GIVEN] CRMAccount record is coupled to Customer
        // [GIVEN] CRMAccount record is modified later than Customer
        // [WHEN] Running synch.
        // [THEN] The Destination record is modified
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        IntegrationRecord.FindByRecordId(Customer.RecordId);
        CRMIntegrationRecord.SetLastSynchModifiedOns(
          CRMAccount.AccountId, DATABASE::Customer, CRMAccount.ModifiedOn, IntegrationRecord."Modified On", CreateGuid, 2);
        // Updating the CRMAccount to be modified 1 day after the Customer Record
        CRMAccount.ModifiedOn := CreateDateTime(CalcDate('<+1D>', DT2Date(IntegrationRecord."Modified On")), Time);
        CRMAccount.Modify();
        SourceRecordRef.GetTable(CRMAccount);

        IntegrationTableSynch.BeginIntegrationSynchJob(
          TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, IntegrationTableMapping."Integration Table ID");
        IntegrationTableSynch.Synchronize(SourceRecordRef, DestinationRecordRef, false, false);

        // Verify
        IntTableSynchSubscriber.VerifyCallbackCounters(1, 1, 0, 0, 1, 1);

        Assert.AreEqual(Customer.RecordId, DestinationRecordRef.RecordId, 'Expected the Destination to be the coupled Customer');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SynchCoupledRecord()
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        IntegrationRecord: Record "Integration Record";
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
        SourceRecordRef: RecordRef;
    begin
        // [FEATURE] [Modified On]
        Initialize;
        ResetDefaultCRMSetupConfiguration;
        IntegrationTableMapping.Get('CUSTOMER');

        // [GIVEN] Customer record is coupled to CRMAccount
        // [GIVEN] Records have been synched once.
        // [GIVEN] Customer has been updated since last sync.
        // [WHEN] Running synch.
        // [THEN] The Destination record is modified
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        IntegrationRecord.FindByRecordId(Customer.RecordId);
        CRMIntegrationRecord.SetLastSynchModifiedOns(
          CRMAccount.AccountId, DATABASE::Customer, CRMAccount.ModifiedOn,
          CreateDateTime(CalcDate('<-1D>', DT2Date(IntegrationRecord."Modified On")), Time), CreateGuid, 1);
        SourceRecordRef.GetTable(Customer);

        IntegrationTableSynch.BeginIntegrationSynchJob(
          TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, IntegrationTableMapping."Table ID");
        IntegrationTableSynch.Synchronize(SourceRecordRef, DestinationRecordRef, false, false);

        // Verify
        IntTableSynchSubscriber.VerifyCallbackCounters(1, 1, 0, 0, 1, 1);

        Assert.AreEqual(CRMAccount.RecordId, DestinationRecordRef.RecordId, 'Expected the Destination to be the coupled CRMAccount');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ForceSynchCoupledIntegrationTableRecord()
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        IntegrationRecord: Record "Integration Record";
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
        SourceRecordRef: RecordRef;
    begin
        // [FEATURE] [Modified On]
        Initialize;
        ResetDefaultCRMSetupConfiguration;
        IntegrationTableMapping.Get('CUSTOMER');

        // [GIVEN] CRMAccount record is coupled to Customer
        // [GIVEN] CRMAccount was modified since last synch.
        // [GIVEN] Destination Customer record has been modified since last synch.
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        IntegrationRecord.FindByRecordId(Customer.RecordId);
        CRMIntegrationRecord.SetLastSynchModifiedOns(
          CRMAccount.AccountId, DATABASE::Customer, CRMAccount.ModifiedOn, IntegrationRecord."Modified On", CreateGuid, 2);

        if not IntegrationRecord.FindByRecordId(Customer.RecordId) then
            Assert.Fail('Could not find Integration Record');

        IntegrationRecord."Modified On" := CreateDateTime(CalcDate('<+1D>', DT2Date(IntegrationRecord."Modified On")), Time);
        IntegrationRecord.Modify();

        CRMAccount.Address1_Line1 := CRMAccount.Address1_Line1 + '1';
        CRMAccount.ModifiedOn := CreateDateTime(CalcDate('<+1D>', DT2Date(CRMAccount.ModifiedOn)), Time);
        CRMAccount.Modify();
        SourceRecordRef.GetTable(CRMAccount);

        IntegrationTableSynch.BeginIntegrationSynchJob(
          TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, IntegrationTableMapping."Integration Table ID");
        // [WHEN] Running synch.
        // [THEN] The Destination record is not modified modified
        IntegrationTableSynch.Synchronize(SourceRecordRef, DestinationRecordRef, false, false);
        IntegrationTableSynch.EndIntegrationSynchJob;

        // Verify
        IntTableSynchSubscriber.VerifyCallbackCounters(1, 0, 0, 0, 0, 0);

        // [WHEN] Running synch. with FORCE
        // [THEN] The Destination record modified modified
        IntegrationTableSynch.BeginIntegrationSynchJob(
          TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, IntegrationTableMapping."Integration Table ID");
        IntegrationTableSynch.Synchronize(SourceRecordRef, DestinationRecordRef, true, false);
        IntegrationTableSynch.EndIntegrationSynchJob;

        IntTableSynchSubscriber.VerifyCallbackCounters(2, 1, 0, 0, 1, 1);
        Assert.AreEqual(Customer.RecordId, DestinationRecordRef.RecordId, 'Expected the Destination to be the coupled Customer');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ForceSynchCoupledRecord()
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        IntegrationRecord: Record "Integration Record";
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
        SourceRecordRef: RecordRef;
    begin
        // [FEATURE] [Modified On]
        Initialize;
        ResetDefaultCRMSetupConfiguration;
        IntegrationTableMapping.Get('CUSTOMER');

        // [GIVEN] Customer record is coupled to CRMAccount
        // [GIVEN] CRMAccount was modified after last synch.
        // [GIVEN] Customer was modified after last synch.
        // [WHEN] Running synch.
        // [THEN] The Destination record is modified
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        IntegrationRecord.FindByRecordId(Customer.RecordId);
        CRMIntegrationRecord.SetLastSynchModifiedOns(
          CRMAccount.AccountId, DATABASE::Customer, CRMAccount.ModifiedOn, IntegrationRecord."Modified On", CreateGuid, 1);

        if not IntegrationRecord.FindByRecordId(Customer.RecordId) then
            Assert.Fail('Could not find Integration Record');

        Customer.Address := Customer.Address + '1';
        Customer.Modify();
        // Also modifying integration to ensure current Modified On > 1 sec. than previous Modified On.
        IntegrationRecord."Modified On" := CreateDateTime(CalcDate('<+1D>', DT2Date(IntegrationRecord."Modified On")), Time);
        IntegrationRecord.Modify();

        CRMAccount.ModifiedOn := CreateDateTime(CalcDate('<+1D>', DT2Date(CRMAccount.ModifiedOn)), Time);
        CRMAccount.Modify();

        SourceRecordRef.GetTable(Customer);

        IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::ToIntegrationTable;
        IntegrationTableSynch.BeginIntegrationSynchJob(
          TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, IntegrationTableMapping."Table ID");
        IntegrationTableSynch.Synchronize(SourceRecordRef, DestinationRecordRef, false, false);
        // Verify
        IntTableSynchSubscriber.VerifyCallbackCounters(1, 0, 0, 0, 0, 0);

        IntegrationTableSynch.Synchronize(SourceRecordRef, DestinationRecordRef, true, false);
        IntTableSynchSubscriber.VerifyCallbackCounters(2, 1, 0, 0, 1, 1);

        Assert.AreEqual(CRMAccount.RecordId, DestinationRecordRef.RecordId, 'Expected the Destination to be the coupled CRMAccount');
    end;

    [Test]
    [HandlerFunctions('HandleConfirmYes,HandleMessageOk')]
    [Scope('OnPrem')]
    procedure MappingPageInvokeSynchonizeAllClearsModifiedOnDateTimes()
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        IntegrationRecord: Record "Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationTableMappingList: TestPage "Integration Table Mapping List";
        LatestModifiedOnBefore: DateTime;
        LatestModifiedOnAfter: DateTime;
    begin
        // [FEATURE] [Modified On] [UI]
        // [SCENARIO] From the mapping table list page select a mapping and choose "Synchronize All"
        Initialize;
        // [GIVEN] A coupled Customer and Account modified a year ago
        LatestModifiedOnBefore := CreateDateTime(CalcDate('<+1Y>', Today), Time);
        LatestModifiedOnAfter := CreateDateTime(CalcDate('<-1Y>', Today), Time);
        Assert.IsTrue(LatestModifiedOnAfter < LatestModifiedOnBefore, 'Expected the after date to be before the before date.');
        // [GIVEN] CRMAccount has been changed two minutes before Customer modification
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        CRMAccount.ModifiedOn := LatestModifiedOnAfter - 120000;
        CRMAccount.Modify();
        IntegrationRecord.FindByRecordId(Customer.RecordId);
        IntegrationRecord."Modified On" := LatestModifiedOnAfter;
        IntegrationRecord.Modify();

        // [GIVEN] Table mapping Synch. Modified On filter is set to a date next year.
        ResetDefaultCRMSetupConfiguration;
        IntegrationTableMapping.Get('CUSTOMER');
        IntegrationTableMapping."Synch. Int. Tbl. Mod. On Fltr." := LatestModifiedOnBefore;
        IntegrationTableMapping."Synch. Modified On Filter" := LatestModifiedOnBefore;
        IntegrationTableMapping.Modify();

        // [WHEN] Invoking the Synchronize All action
        IntegrationTableMappingList.OpenEdit;
        IntegrationTableMappingList.GotoRecord(IntegrationTableMapping);
        IntegrationTableMappingList.SynchronizeAll.Invoke;

        // [THEN] The Synch modified on filter for both NAV and CRM is updated with the latest Modified On date
        IntegrationTableMapping.Get('CUSTOMER');
        Assert.AreEqual(
          LatestModifiedOnAfter - 120000, IntegrationTableMapping."Synch. Modified On Filter",
          'Expected the synch. modified on filter to be updated');
        Assert.AreEqual(
          LatestModifiedOnAfter, IntegrationTableMapping."Synch. Int. Tbl. Mod. On Fltr.",
          'Expected the int. tbl. synch. modified on filter to be updated');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SynchronizeNewRecordFromCRMShouldOnlyInsertOnceAndUpdateOnNextSynch()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMAccount: Record "CRM Account";
        Customer: Record Customer;
        IntegrationSynchJob: Record "Integration Synch. Job";
    begin
        // [FEATURE] [Integration Synch. Job]
        Initialize;
        LibraryCRMIntegration.GetGLSetupCRMTransactionCurrencyID;
        ResetDefaultCRMSetupConfiguration;

        // [GIVEN] Mapping with insert allowed
        IntegrationTableMapping.Get('CUSTOMER');
        IntegrationTableMapping."Synch. Only Coupled Records" := false;
        IntegrationTableMapping.Modify();

        // [GIVEN] A new record in CRM
        Assert.AreEqual(0, CRMAccount.Count, 'Expected the test to start with no data');
        LibraryCRMIntegration.CreateCRMAccountWithCoupledOwner(CRMAccount);
        Assert.AreNotEqual(0T, CRMAccount.ModifiedOn, 'Expected the modified on to have a value');

        // [GIVEN] No records in NAV
        Customer.DeleteAll();

        // [WHEN] Synchronizing
        Commit();
        CODEUNIT.Run(CODEUNIT::"CRM Integration Table Synch.", IntegrationTableMapping);

        // [THEN] One new customer is created in NAV
        Assert.AreEqual(1, Customer.Count, 'Expected one new customer to be created');
        IntegrationSynchJob.SetRange("Integration Table Mapping Name", IntegrationTableMapping.Name);
        IntegrationSynchJob.SetRange("Synch. Direction", IntegrationSynchJob."Synch. Direction"::FromIntegrationTable);
        IntegrationSynchJob.FindFirst;
        Assert.AreEqual(1, IntegrationSynchJob.Inserted,
          StrSubstNo(
            'Expected one row to be inserted. Modified: %1, Unchanged: %2, Failed: %3\', IntegrationSynchJob.Modified,
            IntegrationSynchJob.Unchanged, IntegrationSynchJob.Failed, ConstructAllFailuresMessage));

        // [WHEN] Running the synchronization again
        IntegrationSynchJob.Reset();
        IntegrationSynchJob.DeleteAll();
        Commit();
        Sleep(200);
        CODEUNIT.Run(CODEUNIT::"CRM Integration Table Synch.", IntegrationTableMapping);

        // [THEN] Nothing gets inserted or modified;
        IntegrationSynchJob.Reset();
        IntegrationSynchJob.SetCurrentKey("Start Date/Time");
        IntegrationSynchJob.FindSet;
        VerifySyncJobTotals(IntegrationSynchJob, 0, 0, 0, 2);

        // [WHEN] Running the synchronization a third time
        IntegrationSynchJob.Reset();
        IntegrationSynchJob.DeleteAll();
        Commit();
        CODEUNIT.Run(CODEUNIT::"CRM Integration Table Synch.", IntegrationTableMapping);

        // [THEN] Nothing gets inserted or modified;
        IntegrationSynchJob.Reset();
        IntegrationSynchJob.FindSet;
        VerifySyncJobTotals(IntegrationSynchJob, 0, 0, 0, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SynchronizeSucceedsWithLoggedErrorWhenFindCoupledRecordEventFails()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CRMSystemuser: Record "CRM Systemuser";
        Customer: Record Customer;
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
    begin
        // [FEATURE] [Integration Synch. Job]
        Initialize;

        ResetDefaultCRMSetupConfiguration;
        IntegrationTableMapping.Get('CUSTOMER');

        // [GIVEN] New Customer
        // [GIVEN] Customer is not coupled
        LibraryCRMIntegration.CreateCoupledSalespersonAndSystemUser(SalespersonPurchaser, CRMSystemuser);
        LibrarySales.CreateCustomer(Customer);
        Customer."Salesperson Code" := SalespersonPurchaser.Code;
        Customer.Modify();
        SourceRecordRef.GetTable(Customer);
        // [GIVEN] A subscriber of find coupled destination record fails.
        IntTableSynchSubscriber.SetFindRecordResultsShouldError;

        // [WHEN] Running synch.
        IntegrationTableSynch.BeginIntegrationSynchJob(
          TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, IntegrationTableMapping."Table ID");
        IntegrationTableSynch.Synchronize(SourceRecordRef, DestinationRecordRef, false, true);

        // [THEN] The log should reflect and error
        IntegrationSynchJob.Get(IntegrationTableSynch.EndIntegrationSynchJob);
        Assert.AreEqual(0, IntegrationSynchJob.Inserted, 'Did not expect any inserted rows');
        Assert.AreEqual(0, IntegrationSynchJob.Modified, 'Did not expect any modified rows');
        Assert.AreEqual(0, IntegrationSynchJob.Unchanged, 'Did not expect any unchanged rows');
        Assert.AreEqual(0, IntegrationSynchJob.Skipped, 'Did not expect any skipped rows');
        Assert.AreEqual(1, IntegrationSynchJob.Failed, 'Expected 1 failed row');
    end;

    [Test]
    [HandlerFunctions('SelectDirection2,SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestSynchronizeContactAfterSyncCustomer()
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        IntegrationRecord: Record "Integration Record";
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        SourceRecordRef: RecordRef;
        StrLenName: Integer;
    begin
        // [SCENARIO 379611] Update Contact when synchronize Customer with CRM.

        // [GIVEN] Customer "C1" with Name = "A" is coupled with "CRM Account"
        Initialize;
        ResetDefaultCRMSetupConfiguration;
        IntegrationTableMapping.Get(Customer.TableCaption);
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);

        // [GIVEN] Synchronize customer "C1" with "CRM Account"
        SourceRecordRef.GetTable(Customer);
        IntegrationRecord.FindByRecordId(Customer.RecordId);
        CRMIntegrationRecord.SetLastSynchModifiedOns(
          CRMAccount.AccountId, DATABASE::Customer, CRMAccount.ModifiedOn,
          CreateDateTime(CalcDate('<-1D>', DT2Date(IntegrationRecord."Modified On")), Time), CreateGuid, 1);

        IntegrationTableSynch.BeginIntegrationSynchJob(
          TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, IntegrationTableMapping."Table ID");
        IntegrationTableSynch.Synchronize(SourceRecordRef, DestinationRecordRef, false, false);
        IntegrationTableSynch.EndIntegrationSynchJob;

        // [WHEN] Change "C1".Name to "X"
        Sleep(2000);
        StrLenName := StrLen(Customer.Name);
        Customer.Validate(Name, LibraryUtility.GenerateRandomText(StrLenName));
        Customer.Modify(true);

        // [WHEN] Synchronize customer "C1" with "CRM Account" again
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask;
        CRMIntegrationManagement.UpdateOneNow(Customer.RecordId);
        // execute the job
        CRMAccount.SetRecFilter;
        LibraryCRMIntegration.RunJobQueueEntry(
          DATABASE::"CRM Account", CRMAccount.GetView, IntegrationTableMapping);

        // [THEN] Notification: "Synchronization has been scheduled"
        // verified by SyncStartedNotificationHandler
        // [THEN] "Cont1".Name = "X"
        Customer.Find;
        VerifyBusRelationContactName(Customer."No.", Customer.Name);
    end;

    [Scope('OnPrem')]
    procedure ConstructAllFailuresMessage() Message: Text
    var
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
    begin
        if not IntegrationSynchJobErrors.FindSet then
            exit('');

        repeat
            Message := Message + IntegrationSynchJobErrors.Message + '\';
        until IntegrationSynchJobErrors.Next = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LogSynchErrorForBothExistingRecords()
    var
        CRMAccount: Record "CRM Account";
        Customer: Record Customer;
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
        SourceRecRef: RecordRef;
        DestinationRecRef: RecordRef;
    begin
        // [FEATURE] [UT]
        Initialize;
        IntegrationTableSynch.BeginIntegrationSynchJob(
          TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, DATABASE::Customer);

        // [GIVEN] the coupled Customer and CRM Account both exist.
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        SourceRecRef.GetTable(Customer);
        DestinationRecRef.GetTable(CRMAccount);

        // [WHEN] run LogSynchError()
        IntegrationSynchJob.Get(IntegrationTableSynch.LogSynchError(SourceRecRef, DestinationRecRef, ''));

        // [THEN] IntegrationSynchJob, where "Failed" = 1
        IntegrationSynchJob.TestField(Failed, 1);
        // [THEN] IntegrationSynchJobErrors, where "Source Record ID" and "Destination Record ID" are set
        VerifySyncJobErrorRecIDs(IntegrationSynchJob.ID, SourceRecRef.RecordId, DestinationRecRef.RecordId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LogSynchErrorForBothNotExistingRecords()
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
        DummyRecRef: RecordRef;
        DummyRecID: RecordID;
    begin
        // [FEATURE] [UT]
        Initialize;
        IntegrationTableSynch.BeginIntegrationSynchJob(
          TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, DATABASE::Customer);
        // [GIVEN] the coupled Customer and CRM Account both do not exist.
        // [WHEN] run LogSynchError()
        IntegrationSynchJob.Get(IntegrationTableSynch.LogSynchError(DummyRecRef, DummyRecRef, ''));

        // [THEN] IntegrationSynchJob, where "Failed" = 1
        IntegrationSynchJob.TestField(Failed, 1);
        // [THEN] IntegrationSynchJobErrors, where "Source Record ID" and "Destination Record ID" are empty
        VerifySyncJobErrorRecIDs(IntegrationSynchJob.ID, DummyRecID, DummyRecID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LogSynchErrorForNorExistingSource()
    var
        CRMAccount: Record "CRM Account";
        Customer: Record Customer;
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
        DummyRecRef: RecordRef;
        DestinationRecRef: RecordRef;
        DummyRecID: RecordID;
    begin
        // [FEATURE] [UT]
        Initialize;
        IntegrationTableSynch.BeginIntegrationSynchJob(
          TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, DATABASE::Customer);

        // [GIVEN] the coupled Customer and CRM Account, but Customer does not exist.
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        DestinationRecRef.GetTable(CRMAccount);

        // [WHEN] run LogSynchError()
        IntegrationSynchJob.Get(IntegrationTableSynch.LogSynchError(DummyRecRef, DestinationRecRef, ''));

        // [THEN] IntegrationSynchJob, where "Failed" = 1
        IntegrationSynchJob.TestField(Failed, 1);
        // [THEN] IntegrationSynchJobErrors, where "Source Record ID" is empty, "Destination Record ID" is set
        VerifySyncJobErrorRecIDs(IntegrationSynchJob.ID, DummyRecID, DestinationRecRef.RecordId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LogSynchErrorForNorExistingDestination()
    var
        CRMAccount: Record "CRM Account";
        Customer: Record Customer;
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
        DummyRecRef: RecordRef;
        SourceRecRef: RecordRef;
        DummyRecID: RecordID;
    begin
        // [FEATURE] [UT]
        Initialize;
        IntegrationTableSynch.BeginIntegrationSynchJob(
          TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, DATABASE::Customer);

        // [GIVEN] the coupled Customer and CRM Account, but CRM Account does not exist.
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        SourceRecRef.GetTable(Customer);

        // [WHEN] run LogSynchError()
        IntegrationSynchJob.Get(IntegrationTableSynch.LogSynchError(SourceRecRef, DummyRecRef, ''));

        // [THEN] IntegrationSynchJob, where "Failed" = 1
        IntegrationSynchJob.TestField(Failed, 1);
        // [THEN] IntegrationSynchJobErrors, where "Source Record ID" is set, "Destination Record ID" is empty
        VerifySyncJobErrorRecIDs(IntegrationSynchJob.ID, SourceRecRef.RecordId, DummyRecID);
    end;

    local procedure Initialize()
    begin
        LibraryCRMIntegration.ResetEnvironment;
        LibraryCRMIntegration.ConfigureCRM;
        LibraryCRMIntegration.GetGLSetupCRMTransactionCurrencyID;
        IntTableSynchSubscriber.Reset();

        if not (SourceRecordRef.Number = 0) then
            SourceRecordRef.Close;
        if not (DestinationRecordRef.Number = 0) then
            DestinationRecordRef.Close;

        if IsInitialized then
            exit;
        IsInitialized := true;
        if BindSubscription(IntTableSynchSubscriber) then;
    end;

    local procedure InitializeTestForToIntegrationTableSynch(var IntegrationTableMapping: Record "Integration Table Mapping")
    begin
        Initialize;
        LibraryCRMIntegration.CreateIntegrationTableMapping(IntegrationTableMapping);

        // Prepare Source
        SourceRecordRef.Close;
        SourceRecordRef.Open(DATABASE::"Unit of Measure");
        SourceRecordRef.DeleteAll();

        // Prepare Destination
        DestinationRecordRef.Close;
        DestinationRecordRef.Open(DATABASE::"Test Integration Table");
        DestinationRecordRef.DeleteAll();
    end;

    local procedure InitializeTestForFromIntegrationTableSynch(var IntegrationTableMapping: Record "Integration Table Mapping")
    begin
        Initialize;
        LibraryCRMIntegration.CreateIntegrationTableMapping(IntegrationTableMapping);

        // Prepare Source
        SourceRecordRef.Close;
        SourceRecordRef.Open(DATABASE::"Test Integration Table");
        SourceRecordRef.DeleteAll();
        // Prepare Destination
        DestinationRecordRef.Close;
        DestinationRecordRef.Open(DATABASE::"Unit of Measure");
        DestinationRecordRef.DeleteAll();
    end;

    local procedure VerifyBusRelationContactName(CustomerNo: Code[20]; CustomerName: Text[100])
    var
        ContactBusinessRelation: Record "Contact Business Relation";
        Contact: Record Contact;
    begin
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        ContactBusinessRelation.SetRange("No.", CustomerNo);
        ContactBusinessRelation.FindFirst;
        Contact.Get(ContactBusinessRelation."Contact No.");
        Contact.TestField(Name, CustomerName);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure HandleConfirmYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure HandleMessageOk(Message: Text[1024])
    begin
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure SelectDirection2(Options: Text; var Choice: Integer; Instructions: Text)
    begin
        Choice := 2;
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
        CDSConnectionSetup.Validate("Client Id", 'ClientId');
        CDSConnectionSetup.SetClientSecret('ClientSecret');
        CDSConnectionSetup.Validate("Redirect URL", 'RedirectURL');
        CDSConnectionSetup.Modify();
        CDSSetupDefaults.ResetConfiguration(CDSConnectionSetup);
        CRMSetupDefaults.ResetConfiguration(CRMConnectionSetup);
    end;

    local procedure VerifySyncJobErrorRecIDs(JobID: Guid; SourceRecID: RecordID; DestinationRecID: RecordID)
    var
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
    begin
        IntegrationSynchJobErrors.SetRange("Integration Synch. Job ID", JobID);
        IntegrationSynchJobErrors.FindFirst;
        IntegrationSynchJobErrors.TestField("Source Record ID", SourceRecID);
        IntegrationSynchJobErrors.TestField("Destination Record ID", DestinationRecID);
    end;

    local procedure VerifySyncJobTotals(IntegrationSynchJob: Record "Integration Synch. Job"; ExpectedInserted: Integer; ExpectedModified: Integer; ExpectedFailed: Integer; ExpectedUnchanged: Integer)
    var
        TotalInserted: Integer;
        TotalModified: Integer;
        TotalFailed: Integer;
        TotalUnchanged: Integer;
    begin
        repeat
            TotalInserted += IntegrationSynchJob.Inserted;
            TotalModified += IntegrationSynchJob.Modified;
            TotalFailed += IntegrationSynchJob.Failed;
            TotalUnchanged += IntegrationSynchJob.Unchanged;
        until IntegrationSynchJob.Next() = 0;

        Assert.AreEqual(ExpectedInserted, TotalInserted, 'Unexpected inserted rows.');
        Assert.AreEqual(ExpectedModified, TotalModified, 'Unexpected modified row');
        Assert.AreEqual(ExpectedFailed, TotalFailed, 'Unexpected failed rows.\' + ConstructAllFailuresMessage);
        Assert.AreEqual(ExpectedUnchanged, TotalUnchanged, 'Unexpected unchanged row.');
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SyncStartedNotificationHandler(var SyncCompleteNotification: Notification): Boolean
    begin
        Assert.AreEqual(SyncStartedMsg, SyncCompleteNotification.Message, 'Unexpected notification.');
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;
}

