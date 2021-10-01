codeunit 135963 "PowerBI Upgrade Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [PowerBI] 
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatePowerBIOptinImage()
    var
        MediaRepository: Record "Media Repository";
        UpgradeStatus: Codeunit "Upgrade Status";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        Assert: Codeunit "Library Assert";
        RecordVariant: Variant;
    begin
        if not UpgradeStatus.UpgradeTriggered() then
            exit;

        if UpgradeStatus.UpgradeTagPresentBeforeUpgrade(UpgradeTagDefinitions.GetUpgradePowerBIOptinImageUpgradeTag()) then
            exit;

        MediaRepository.SetRange("File Name", 'PowerBi-OptIn-480px.png');

        MediaRepository.SetRange("Display Target", Format(ClientType::Web));
        RecordVariant := MediaRepository;
        Assert.RecordIsNotEmpty(RecordVariant);

        MediaRepository.SetRange("Display Target", Format(ClientType::Tablet));
        RecordVariant := MediaRepository;
        Assert.RecordIsNotEmpty(RecordVariant);

        MediaRepository.SetRange("Display Target", Format(ClientType::Phone));
        RecordVariant := MediaRepository;
        Assert.RecordIsNotEmpty(RecordVariant);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatePowerBIWorkspaces()
    var
        PowerBIReportConfiguration: Record "Power BI Report Configuration";
        UpgradeStatus: Codeunit "Upgrade Status";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        Assert: Codeunit "Library Assert";
        RecordVariant: Variant;
        NullGuid: Guid;
    begin
        if not UpgradeStatus.UpgradeTriggered() then
            exit;

        if UpgradeStatus.UpgradeTagPresentBeforeUpgrade(UpgradeTagDefinitions.GetPowerBIWorkspacesUpgradeTag()) then
            exit;

        RecordVariant := PowerBIReportConfiguration;
        Assert.RecordIsNotEmpty(RecordVariant);

        PowerBIReportConfiguration.Reset();
        PowerBIReportConfiguration.SetFilter("Workspace Name", '<>%1', 'My Workspace');
        RecordVariant := PowerBIReportConfiguration;
        Assert.RecordIsEmpty(RecordVariant);

        PowerBIReportConfiguration.Reset();
        PowerBIReportConfiguration.SetFilter("Workspace ID", '<>%1', NullGuid);
        RecordVariant := PowerBIReportConfiguration;
        Assert.RecordIsEmpty(RecordVariant);
    end;

}