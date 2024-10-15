codeunit 9997 "Upgrade Tag Def - Country"
{

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetLocalSEPAInstrPrtyUpgradeTag());
    end;
   
    procedure GetLocalSEPAInstrPrtyUpgradeTag(): Code[250]
    begin
        exit('MS-381529-LocalSEPAInstrPrty-20201215');
    end;
}

