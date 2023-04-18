/// <summary>
/// Upgrade code to add Privacy Notices
/// </summary>
codeunit 104044 "Upgrade Privacy Notices"
{
    Subtype = Upgrade;

    trigger OnUpgradePerDatabase()
    var
        PrivacyNotice: Codeunit "Privacy Notice";
        PrivacyNoticeRegistrations: Codeunit "Privacy Notice Registrations";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetUpdateInitialPrivacyNoticesTag()) then
            exit;
        
        PrivacyNotice.CreateDefaultPrivacyNotices();

        PrivacyNotice.SetApprovalState(PrivacyNoticeRegistrations.GetOneDrivePrivacyNoticeId(), "Privacy Notice Approval State"::Agreed);
        PrivacyNotice.SetApprovalState(PrivacyNoticeRegistrations.GetExchangePrivacyNoticeId(), "Privacy Notice Approval State"::Agreed);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetUpdateInitialPrivacyNoticesTag());
    end;
}
