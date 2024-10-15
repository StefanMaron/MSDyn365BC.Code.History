codeunit 104150 "UPG. IRS 1099 Form Boxes"
{
    Subtype = Upgrade;

    trigger OnRun()
    begin
    end;

    trigger OnUpgradePerCompany()
    begin
        RunIRS1099DIV2018Changes;
    end;

    local procedure RunIRS1099DIV2018Changes()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
        UpgradeIRS1099FormBoxes: Codeunit "Upgrade IRS 1099 Form Boxes";
    begin
        IF UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.Get1099DIV2018UpgradeTag) THEN
            EXIT;

        UpgradeIRS1099FormBoxes.RUN;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.Get1099DIV2018UpgradeTag);
    end;
}

