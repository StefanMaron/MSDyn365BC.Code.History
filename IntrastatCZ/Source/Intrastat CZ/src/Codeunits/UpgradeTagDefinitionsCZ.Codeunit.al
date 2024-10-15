codeunit 31304 "Upgrade Tag Definitions CZ"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetIntrastatExcludeUpgradeTag());
        PerCompanyUpgradeTags.Add(GetIntrastatDeliveryGroupUpgradeTag());
    end;

    procedure GetIntrastatExcludeUpgradeTag(): Code[250]
    begin
        exit('CZ-483543-IntrastatExclude-20230907');
    end;

    procedure GetIntrastatDeliveryGroupUpgradeTag(): Code[250]
    begin
        exit('CZ-485242-IntrastatDeliveryGroup-20230919');
    end;
}
