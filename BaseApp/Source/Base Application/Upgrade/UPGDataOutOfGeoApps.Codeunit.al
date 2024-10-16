#if not CLEAN25
codeunit 14060 "UPG Data Out Of Geo. Apps"
{
    Subtype = Upgrade;
    ObsoleteState = Pending;
    ObsoleteReason = 'This codeunit will be deprecated as the procedure AddDataOutOfGeoApps has been obsoleted.';
    ObsoleteTag = '25.0';

    trigger OnUpgradePerDatabase()
    var
        HybridDeployment: Codeunit "Hybrid Deployment";
    begin
        if not HybridDeployment.VerifyCanStartUpgrade('') then
            exit;
    end;
}
#endif