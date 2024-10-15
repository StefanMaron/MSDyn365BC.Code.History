codeunit 104041 "Upgrade User Callouts"
{
    // This codeunit runs upgrade from 17.x to 18.0 to populate the new table User Callouts

    Subtype = Upgrade;

    // Upgrade triggers

    trigger OnUpgradePerDatabase()
    begin
        PopulateUserCallouts();
    end;

    local procedure PopulateUserCallouts()
    var
        User: Record User;
        UserCallouts: Record "User Callouts";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetUserCalloutsUpgradeTag()) then
            exit;

        if User.FindSet() then
            repeat
                if not UserCallouts.get(User."User Security ID") then begin
                    UserCallouts."User Security ID" := User."User Security ID";
                    UserCallouts.Enabled := false;
                    UserCallouts.Insert();
                end;
            until (User.Next() = 0);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetUserCalloutsUpgradeTag());
    end;
}