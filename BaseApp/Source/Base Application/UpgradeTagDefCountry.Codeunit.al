codeunit 9997 "Upgrade Tag Def - Country"
{

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        // Country
        PerCompanyUpgradeTags.Add(GetUpdateCountyNameTag);

    end;

    procedure GetUpdateCountyNameTag(): Code[250]
    begin
        exit('MS-BE-299774-UpdateCountyName-20190211');
    end;

}

