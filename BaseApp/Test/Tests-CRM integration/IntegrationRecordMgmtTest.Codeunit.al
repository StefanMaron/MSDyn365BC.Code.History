codeunit 139167 "Integration Record Mgmt. Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [CRM Integration] [Integration Record]
    end;

    var
        Assert: Codeunit Assert;
        IntegrationRecordManagement: Codeunit "Integration Record Management";
        LibraryCRMIntegration: Codeunit "Library - CRM Integration";

    [Test]
    [Scope('OnPrem')]
    procedure CanFindRecordIdByIntegrationTableUid()
    var
        Customer: Record Customer;
        IntegrationRecord: Record "Integration Record";
        CustomerRecordId: RecordID;
        IntegrationTableUid: Guid;
    begin
        Initialize;

        // Setup customer, integration record and crm integration record
        IntegrationTableUid := CreateGuid;
        LibraryCRMIntegration.CreateCustomerAndEnsureIntegrationRecord(Customer, IntegrationRecord);
        LibraryCRMIntegration.CreateCRMIntegrationRecord(IntegrationTableUid, IntegrationRecord);

        // Execute
        Assert.IsTrue(IntegrationRecordManagement.FindRecordIdByIntegrationTableUid(TABLECONNECTIONTYPE::CRM,
            IntegrationTableUid, DATABASE::Customer, CustomerRecordId),
          'Expected to find RecordID from Integration Table UID');

        // Validate recordid matches
        Assert.IsTrue(Customer.RecordId = CustomerRecordId, 'Expected the Record ID to match the customer record');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotFindRecordIdByIntegrationTableUid()
    var
        Customer: Record Customer;
        IntegrationRecord: Record "Integration Record";
        CustomerRecordId: RecordID;
        IntegrationTableUid: Guid;
    begin
        Initialize;

        // Setup customer, integration record but no crm integration record
        IntegrationTableUid := CreateGuid;
        LibraryCRMIntegration.CreateCustomerAndEnsureIntegrationRecord(Customer, IntegrationRecord);

        // Execute
        IntegrationRecordManagement.FindRecordIdByIntegrationTableUid(
          TABLECONNECTIONTYPE::CRM,
          IntegrationTableUid, DATABASE::Customer, CustomerRecordId);

        // Validate recordid does not match
        Assert.IsFalse(Customer.RecordId = CustomerRecordId, 'Expected the Record ID to match the customer record');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CanFindIntegrationTableUidByRecordId()
    var
        Customer: Record Customer;
        IntegrationRecord: Record "Integration Record";
        CustomerIntegrationTableUidVariant: Variant;
        IntegrationTableUid: Guid;
        CustomerIntegrationTableUid: Guid;
    begin
        Initialize;

        // Setup customer, integration record and crm integration record
        IntegrationTableUid := CreateGuid;
        LibraryCRMIntegration.CreateCustomerAndEnsureIntegrationRecord(Customer, IntegrationRecord);
        LibraryCRMIntegration.CreateCRMIntegrationRecord(IntegrationTableUid, IntegrationRecord);

        // Execute
        IntegrationRecordManagement.FindIntegrationTableUIdByRecordId(TABLECONNECTIONTYPE::CRM,
          Customer.RecordId, CustomerIntegrationTableUidVariant);
        CustomerIntegrationTableUid := CustomerIntegrationTableUidVariant;

        // Validate recordid matches
        Assert.IsTrue(IntegrationTableUid = CustomerIntegrationTableUid,
          'Expected the integration table uid to match the inserted integration table uid');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotFindIntegrationTableUidByRecordId()
    var
        Customer: Record Customer;
        IntegrationRecord: Record "Integration Record";
        CustomerIntegrationTableUidVariant: Variant;
        IntegrationTableUid: Guid;
        CustomerIntegrationTableUid: Guid;
    begin
        Initialize;

        // Setup customer, integration record but no crm integration record
        IntegrationTableUid := CreateGuid;
        LibraryCRMIntegration.CreateCustomerAndEnsureIntegrationRecord(Customer, IntegrationRecord);

        // Execute
        IntegrationRecordManagement.FindIntegrationTableUIdByRecordId(TABLECONNECTIONTYPE::CRM,
          Customer.RecordId, CustomerIntegrationTableUidVariant);

        // Validate integration table uid is not found - variant cannot be assigned to guid
        Assert.IsFalse(CustomerIntegrationTableUidVariant.IsGuid, 'Did not expect to find a integration table uid');
        asserterror CustomerIntegrationTableUid := CustomerIntegrationTableUidVariant;
    end;

    local procedure Initialize()
    begin
        LibraryCRMIntegration.ResetEnvironment;
        LibraryCRMIntegration.ConfigureCRM;
    end;
}

