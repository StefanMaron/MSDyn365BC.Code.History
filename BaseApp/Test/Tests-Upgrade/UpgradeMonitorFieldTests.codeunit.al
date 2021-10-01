codeunit 135976 "Upgrade Monitor Field Tests"
{
    Subtype = Test;

    [Test]
    procedure MonitorFieldNotificaiton()
    var
        FieldMonitoringSetup: Record "Field Monitoring Setup";
        UpgradeStatus: Codeunit "Upgrade Status";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        Assert: Codeunit "Library Assert";
    begin
        if not UpgradeStatus.UpgradeTriggered() then
            exit;

        if UpgradeStatus.UpgradeTagPresentBeforeUpgrade(UpgradeTagDefinitions.GetUpgradeMonitorNotificationUpgradeTag()) then
            exit;

        Assert.AreEqual(1, FieldMonitoringSetup."Notification Count", 'Monitor notification count after upgrade should equal same value in setup - 1');
    end;
}