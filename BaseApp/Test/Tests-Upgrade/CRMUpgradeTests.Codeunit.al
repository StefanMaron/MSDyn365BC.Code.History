codeunit 135959 "CRM Upgrade Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Backup/Restore Permissions]
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateCRMSynchStatus()
    var
        UPGCRMConnectionSetup: Record "UPG - CRM Connection Setup";
        CRMSynchStaus: Record "CRM Synch Status";
        UprgradeStatus: Codeunit "Upgrade Status";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        Assert: Codeunit "Library Assert";
    begin
        if not UprgradeStatus.UpgradeTriggered() then
            exit;

        if UprgradeStatus.UpgradeTagPresentBeforeUpgrade(
            UpgradeTagDefinitions.GetLastUpdateInvoiceEntryNoUpgradeTag()) then
            exit;

        Assert.IsTrue(CRMSynchStaus.Get(), 'Could not get the CRM Sync Status');
        Assert.IsTrue(UPGCRMConnectionSetup.Get(), 'Could not get the CRM Connection Setup');
        Assert.AreEqual(UPGCRMConnectionSetup."Last Update Invoice Entry No.", CRMSynchStaus."Last Update Invoice Entry No.", 'Expected Last Update Invoice Entry No. to be transfered from CRM Connection Setup table');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateUpgradeIntegrationFieldMappingForContacts()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        TempContact: Record Contact temporary;
        UprgradeStatus: Codeunit "Upgrade Status";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        Assert: Codeunit "Library Assert";
    begin
        if not UprgradeStatus.UpgradeTriggered() then
            exit;

        if UprgradeStatus.UpgradeTagPresentBeforeUpgrade(
            UpgradeTagDefinitions.GetIntegrationFieldMappingForContactsUpgradeTag()) then
            exit;

        IntegrationTableMapping.SetRange(Name, 'CONTACT');
        IntegrationTableMapping.SetRange("Table ID", Database::Contact);
        IntegrationTableMapping.SetRange("Integration Table ID", Database::"CRM Contact");
        if IntegrationTableMapping.FindFirst() then begin
            IntegrationFieldMapping.SetRange("Integration Table Mapping Name", IntegrationTableMapping.Name);
            IntegrationFieldMapping.SetRange("Field No.", TempContact.FieldNo(Type));
            IntegrationFieldMapping.SetRange("Integration Table Field No.", 0);
            IntegrationFieldMapping.SetRange(Direction, IntegrationFieldMapping.Direction::FromIntegrationTable);
            IntegrationFieldMapping.SetRange("Transformation Direction", IntegrationFieldMapping."Transformation Direction"::FromIntegrationTable);
            if IntegrationFieldMapping.FindFirst() then
                Assert.AreEqual('Person', IntegrationFieldMapping."Constant Value", 'Constant Value for CONTACT.Type mapping is incorrect');
        end;
    end;
}