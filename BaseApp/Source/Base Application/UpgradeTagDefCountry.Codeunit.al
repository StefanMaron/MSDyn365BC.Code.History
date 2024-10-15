codeunit 9997 "Upgrade Tag Def - Country"
{

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerDatabaseUpgradeTags', '', false, false)]
    local procedure RegisterPerDatabaseTags(var PerDatabaseUpgradeTags: List of [Code[250]])
    begin
        PerDatabaseUpgradeTags.Add(GetDataOutOfGeoAppTagCh());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetReportSelectionForGLVATReconciliationTag());
        PerCompanyUpgradeTags.Add(GetPhysInvntOrdersUpgradeTag());
        PerCompanyUpgradeTags.Add(GetCleanupPhysOrders());
#if not CLEAN19
        PerCompanyUpgradeTags.Add(GetCheckPartnerVATIDTag());
#endif
    end;

    procedure GetPhysInvntOrdersUpgradeTag(): Code[250]
    begin
        exit('302317-PhysInvntOrders-20192702');
    end;

    procedure GetReportSelectionForGLVATReconciliationTag(): Code[250]
    begin
        exit('MS-306584-GLVATReconciliation-20190403');
    end;

    procedure GetCleanupPhysOrders(): Code[250]
    begin
        exit('MS-327839-CleanupPhysOrders-20191007');
    end;

#if not CLEAN20
    [Obsolete('Function will be removed', '20.0')]
    procedure GetCheckPartnerVATIDTag(): Code[250]
    begin
        exit('MS-392540-CheckPartnerVATID-20210317');
    end;
#endif
    procedure GetDataOutOfGeoAppTagCh(): Code[250]
    begin
        exit('MS-390169-DataOutOfGeoAppTagCh-20210525');
    end;

    procedure GetVendorRegistrationNoTag(): Code[250]
    begin
        exit('MS-359959-GetVendorRegistrationNo-20230208');
    end;
}
