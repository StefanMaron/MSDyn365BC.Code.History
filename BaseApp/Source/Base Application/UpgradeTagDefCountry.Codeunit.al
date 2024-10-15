codeunit 9997 "Upgrade Tag Def - Country"
{

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetUpdateEmployeeNewNamesTag);
        PerCompanyUpgradeTags.Add(GetUpdateNoTaxableEntriesTag);
    end;

    procedure GetUpdateEmployeeNewNamesTag(): Code[250]
    begin
        exit('MS-292373-ES-UpdateEmployeeNewNames-20190201');
    end;

    procedure GetUpdateNoTaxableEntriesTag(): Code[250]
    begin
        exit('MS-293795-ES-GetUpdateNoTaxableEntriesTag-20190220');
    end;
}

