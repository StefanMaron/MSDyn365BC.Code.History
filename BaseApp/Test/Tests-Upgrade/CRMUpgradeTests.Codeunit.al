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
}