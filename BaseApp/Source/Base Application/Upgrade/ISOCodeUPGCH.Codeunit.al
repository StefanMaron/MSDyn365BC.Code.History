codeunit 104151 "ISO Code UPG.CH"
{
    Subtype = Upgrade;

    trigger OnRun()
    begin
    end;

    trigger OnUpgradePerCompany()
    begin
        MoveCurrencyISOCode;
    end;

    local procedure MoveCurrencyISOCode()
    var
        Currency: Record "Currency";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        IF UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetMoveCurrencyISOCodeTag) THEN
            EXIT;

        WITH Currency DO BEGIN
            SETFILTER("ISO Currency Code", '<>%1', '');
            IF FINDSET THEN
                REPEAT
                    "ISO Code" := "ISO Currency Code";
                    MODIFY;
                UNTIL NEXT = 0;
        END;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetMoveCurrencyISOCodeTag);
    end;
}

