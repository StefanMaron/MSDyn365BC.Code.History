codeunit 9997 "Upgrade Tag Def - Country"
{

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(Get1099DIV2018UpgradeTag());
        PerCompanyUpgradeTags.Add(GetCFDIPurposeRelationFieldsDocUpdateTag());
        PerCompanyUpgradeTags.Add(GetLastUpdateInvoiceEntryNoUpgradeTagUS());
        PerCompanyUpgradeTags.Add(GetGenJnlLineEFTExportSequenceNoUpgradeTag());
        PerCompanyUpgradeTags.Add(GetSalesTaxDiffPositiveFieldUpgradeTag());
        PerCompanyUpgradeTags.Add(GetCFDIEnableOptionUpgradeTag());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerDatabaseUpgradeTags', '', false, false)]
    local procedure RegisterPerDatabaseTags(var PerDatabaseUpgradeTags: List of [Code[250]])
    begin
        PerDatabaseUpgradeTags.Add(GetSATPaymentCatalogsSwapTag());
    end;

    procedure Get1099DIV2018UpgradeTag(): Code[250]
    begin
        exit('283821-1099DIV2018Changes-20181018');
    end;

    procedure GetSATPaymentCatalogsSwapTag(): Code[250]
    begin
        exit('MS-304691-SATPaymentCatalogsSwap-20190520');
    end;

    procedure GetCFDIPurposeRelationFieldsDocUpdateTag(): Code[250]
    begin
        exit('MS-304691-CFDIPurposeRelationFieldsDocUpdate-20190520');
    end;

    procedure GetLastUpdateInvoiceEntryNoUpgradeTagUS(): Code[250]
    begin
        exit('MS-310795-LastUpdateInvoiceEntryNo-20190611');
    end;

    procedure GetDataExchDefinitionTypeTag(): Code[250]
    begin
        exit('MS-297272-DataExchDefinitionType-20191030');
    end;

    procedure GetGenJnlLineEFTExportSequenceNoUpgradeTag(): Code[250];
    begin
        exit('MS-360400-EFTUpdatePart2-20200615');
    end;

    procedure GetSalesTaxDiffPositiveFieldUpgradeTag(): Code[250]
    begin
        exit('MS-377669-SalesTaxDiffNegAndPosLines-20201228');
    end;

    procedure GetCFDIEnableOptionUpgradeTag(): Code[250]
    begin
        exit('MS-407179-CFDIEnableOption-20200806');
    end;
}

