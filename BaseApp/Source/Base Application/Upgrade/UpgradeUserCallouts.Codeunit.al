#if not CLEAN19
codeunit 104041 "Upgrade User Callouts"
{
    Subtype = Upgrade;

    trigger OnUpgradePerDatabase()
    begin
        UpgradeUserSettings();
    end;

    local procedure UpgradeUserSettings()
    var
        UserCallouts: Record "User Callouts";
        UserSettings: Codeunit "User Settings";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetUserSettingsUpgradeTag()) then
            exit;

        if UserCallouts.FindSet() then
            repeat
                if UserCallouts.Enabled then
                    UserSettings.EnableTeachingTips(UserCallouts."User Security ID")
                else
                    UserSettings.DisableTeachingTips(UserCallouts."User Security ID");
            until UserCallouts.Next() = 0;
        
        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetUserSettingsUpgradeTag());
    end;
}
#endif