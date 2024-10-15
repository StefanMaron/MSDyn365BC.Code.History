codeunit 9997 "Upgrade Tag Def - Country"
{
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
}
