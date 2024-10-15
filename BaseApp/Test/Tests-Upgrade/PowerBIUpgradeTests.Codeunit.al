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

#if not CLEAN23
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

    [Test]
    [Scope('OnPrem')]
    procedure ValidatePowerBIDisplayedElements()
    var
        PowerBIContextSettings: Record "Power BI Context Settings";
        PowerBIDisplayedElement: Record "Power BI Displayed Element";
        UpgradeStatus: Codeunit "Upgrade Status";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        Assert: Codeunit "Library Assert";
        RecordVariant: Variant;
    begin
        if not UpgradeStatus.UpgradeTriggered() then
            exit;

        if UpgradeStatus.UpgradeTagPresentBeforeUpgrade(UpgradeTagDefinitions.GetPowerBIDisplayedElementUpgradeTag()) then
            exit;

        RecordVariant := PowerBIContextSettings;
        Assert.RecordIsNotEmpty(RecordVariant);

        RecordVariant := PowerBIDisplayedElement;
        Assert.RecordIsNotEmpty(RecordVariant);
    end;
#endif

    [Test]
    [Scope('OnPrem')]
    procedure ValidatePowerBIUploadStatus()
    var
        PowerBIReportUploads: Record "Power BI Report Uploads";
        Assert: Codeunit "Library Assert";
        UpgradeStatus: Codeunit "Upgrade Status";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if not UpgradeStatus.UpgradeTriggered() then
            exit;

        if UpgradeStatus.UpgradeTagPresentBeforeUpgrade(UpgradeTagDefinitions.GetPowerBIUploadsStatusUpgradeTag()) then
            exit;

        PowerBIReportUploads.SetRange("PBIX BLOB ID", '90757427-ed00-0000-0000-000000000001');
        Assert.RecordCount(PowerBIReportUploads, 1);
        PowerBIReportUploads.FindFirst();
        ValidateUploadStatus(PowerBIReportUploads, Enum::"Power BI Upload Status"::NotStarted);

        PowerBIReportUploads.SetRange("PBIX BLOB ID", '90757427-ed00-0000-0000-000000000002');
        Assert.RecordCount(PowerBIReportUploads, 1);
        PowerBIReportUploads.FindFirst();
        ValidateUploadStatus(PowerBIReportUploads, Enum::"Power BI Upload Status"::NotStarted);

        PowerBIReportUploads.SetRange("PBIX BLOB ID", '90757427-ed00-0000-0000-000000000003');
        Assert.RecordCount(PowerBIReportUploads, 1);
        PowerBIReportUploads.FindFirst();
        ValidateUploadStatus(PowerBIReportUploads, Enum::"Power BI Upload Status"::NotStarted);

        PowerBIReportUploads.SetRange("PBIX BLOB ID", 'fa17ed00-0000-0000-0000-000000000001');
        Assert.RecordCount(PowerBIReportUploads, 1);
        PowerBIReportUploads.FindFirst();
        ValidateUploadStatus(PowerBIReportUploads, Enum::"Power BI Upload Status"::Failed);

        PowerBIReportUploads.SetRange("PBIX BLOB ID", 'de7e7ed0-0000-0000-0000-000000000001');
        Assert.RecordCount(PowerBIReportUploads, 1);
        PowerBIReportUploads.FindFirst();
        ValidateUploadStatus(PowerBIReportUploads, Enum::"Power BI Upload Status"::PendingDeletion);

        PowerBIReportUploads.SetRange("PBIX BLOB ID", 'de7e7ed0-0000-0000-0000-000000000002');
        Assert.RecordCount(PowerBIReportUploads, 1);
        PowerBIReportUploads.FindFirst();
        ValidateUploadStatus(PowerBIReportUploads, Enum::"Power BI Upload Status"::PendingDeletion);

        PowerBIReportUploads.SetRange("PBIX BLOB ID", 'de7e7ed0-0000-0000-0000-000000000003');
        Assert.RecordCount(PowerBIReportUploads, 1);
        PowerBIReportUploads.FindFirst();
        ValidateUploadStatus(PowerBIReportUploads, Enum::"Power BI Upload Status"::PendingDeletion);

        PowerBIReportUploads.SetRange("PBIX BLOB ID", '5e7ec7ed-0000-0000-0000-000000000001');
        Assert.RecordCount(PowerBIReportUploads, 1);
        PowerBIReportUploads.FindFirst();
        ValidateUploadStatus(PowerBIReportUploads, Enum::"Power BI Upload Status"::Completed);

        PowerBIReportUploads.SetRange("PBIX BLOB ID", '5e7ec7ed-0000-0000-0000-000000000002');
        Assert.RecordCount(PowerBIReportUploads, 1);
        PowerBIReportUploads.FindFirst();
        ValidateUploadStatus(PowerBIReportUploads, Enum::"Power BI Upload Status"::DataRefreshed);
    end;

    local procedure ValidateUploadStatus(PowerBIReportUploads: Record "Power BI Report Uploads"; ExpectedUploadStatus: Enum "Power BI Upload Status")
    var
        Assert: Codeunit "Library Assert";
    begin
        Assert.AreEqual(PowerBIReportUploads."Report Upload Status", ExpectedUploadStatus, StrSubstNo('Unexpected upload status for upload %1. Found: %2. Expected: %3.', PowerBIReportUploads."PBIX BLOB ID", PowerBIReportUploads."Report Upload Status", ExpectedUploadStatus));
    end;

}