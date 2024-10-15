codeunit 9997 "Upgrade Tag Def - Country"
{

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetReportSelectionForGLVATReconciliationTag);
        PerCompanyUpgradeTags.Add(GetPhysInvntOrdersUpgradeTag);
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

#if not CLEAN19
    procedure GetCheckPartnerVATIDTag(): Code[250]
    begin
        exit('MS-392540-CheckPartnerVATID-20210317');
    end;
#endif

    procedure GetVendorRegistrationNoTag(): Code[250]
    begin
        exit('MS-359959-GetVendorRegistrationNo-20230208');
    end;
}

