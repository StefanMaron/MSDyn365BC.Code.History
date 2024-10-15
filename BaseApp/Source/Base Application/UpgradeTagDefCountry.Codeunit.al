codeunit 9997 "Upgrade Tag Def - Country"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetVATCodeUpgradeTag());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerDatabaseUpgradeTags', '', false, false)]
    local procedure RegisterPerDatabaseTags(var PerDatabaseUpgradeTags: List of [Code[250]])
    begin
        PerDatabaseUpgradeTags.Add(GetDataOutOfGeoAppTagNo());
    end;

    [Obsolete('Function will be removed', '19.0')]
    procedure GetDataOutOfGeoAppTagNo(): Code[250]
    begin
        exit('MS-390169-DataOutOfGeoAppTagNo-20210525');
    end;

    internal procedure GetVATCodeUpgradeTag(): Code[250]
    begin
        exit('MS-459977-VATCodeUpgradeTag-20230713');
    end;
}
