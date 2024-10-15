codeunit 9997 "Upgrade Tag Def - Country"
{

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetFixRemainingAmountCLEUpgradeTag);
        PerCompanyUpgradeTags.Add(GetFixRemainingAmountVLEUpgradeTag);
    end;

    procedure GetFixRemainingAmountCLEUpgradeTag(): Code[250]
    begin
        exit('MS-314721-FixRemainingAmountsCLE-20190927');
    end;

    procedure GetFixRemainingAmountVLEUpgradeTag(): Code[250]
    begin
        exit('MS-314721-FixRemainingAmountsVLE-20190927');
    end;
}

