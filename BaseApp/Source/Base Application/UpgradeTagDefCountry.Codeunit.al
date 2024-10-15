codeunit 9997 "Upgrade Tag Def - Country"
{

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetAccountingPeriodGBTag());
        PerCompanyUpgradeTags.Add(GetUpdateIntrastatSetupTag());
    end;

    procedure GetAccountingPeriodGBTag(): Code[250]
    begin
        exit('MS-304162-GetAccountingPeriodGB-20190322');
    end;

    procedure GetUpdateIntrastatSetupTag(): Code[250]
    begin
        exit('MS-432461-GetUpdateIntrastatSetupTag-20220420');
    end;

    procedure GetUpgradePaymentPracticesTag(): Code[250]
    begin
        exit('MS-473083-GB-GetUpgradePaymentPracticesTag-20230713');
    end;
}

