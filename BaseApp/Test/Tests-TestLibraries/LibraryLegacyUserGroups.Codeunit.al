#if not CLEAN22
codeunit 130441 "Library - Legacy User Groups"
{
    Subtype = Install;
    Access = Internal;

    var
        UserGroupFeatureKeyTxt: Label 'HideLegacyUserGroups', Locked = true;

    trigger OnInstallAppPerDatabase()
    var
        FeatureKey: Record "Feature Key";
    begin
        // Allow the tests to interact with user groups
        if FeatureKey.Get(UserGroupFeatureKeyTxt) then
            if FeatureKey.Enabled = FeatureKey.Enabled::"All Users" then begin
                FeatureKey.Enabled := FeatureKey.Enabled::None;
                FeatureKey.Modify();
            end;
    end;
}
#endif