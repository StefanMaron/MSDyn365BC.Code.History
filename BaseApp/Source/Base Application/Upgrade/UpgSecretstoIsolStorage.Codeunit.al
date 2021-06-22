codeunit 104020 "Upg Secrets to Isol. Storage"
{
    Subtype = Upgrade;

    trigger OnRun()
    begin
    end;

    trigger OnUpgradePerCompany()
    begin
        MoveServicePasswordToIsolatedStorage();
        MoveGraphMailRefreshCodeToIsolatedStorage();
    end;

    local procedure MoveServicePasswordToIsolatedStorage()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        IF UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetServicePasswordToIsolatedStorageTag()) THEN
            EXIT;

        // changed to only move secrets that are in use for known baseapp features.
        // if a secret cannot be decrypted with the current keys on the nst then upgrade should fail
        MoveOCRServiceSecrets();
        MoveDocExchServiceSecrets();
        MoveCRMConnectionSecrets();
        MoveCashFlowSetupSecrets();
        MoveO365SyncManagementSecrets();
        MoveOfficeAdminSecrets();
        MoveImageAnalysisSecrets();
        MoveSMTPMailSecrets();
        MoveMarketingSetupSecrets();
        MovePostCodeServiceSecrets();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetServicePasswordToIsolatedStorageTag());
    end;

    local procedure MoveGraphMailRefreshCodeToIsolatedStorage()
    var
        GraphMailSetup: Record "Graph Mail Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        InStr: InStream;
        RefreshCodeValue: Text;
    begin
        IF UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetGraphMailRefreshCodeToIsolatedStorageTag()) THEN
            EXIT;

        IF GraphMailSetup.GET THEN
            IF GraphMailSetup."Refresh Code".HASVALUE THEN BEGIN
                GraphMailSetup.CALCFIELDS("Refresh Code");
                GraphMailSetup."Refresh Code".CREATEINSTREAM(InStr);
                InStr.READTEXT(RefreshCodeValue);

                ISOLATEDSTORAGE.SET('RefreshTokenKey', RefreshCodeValue, DATASCOPE::Company)
            END;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetGraphMailRefreshCodeToIsolatedStorageTag());
    end;

    local procedure MoveToIsolatedStorage(KeyGuid: Guid)
    var
        ServicePassword: Record "Service Password";
        ServicePasswordValue: Text;
    begin
        if not ServicePassword.Get(KeyGuid) then
            exit;

        if not TryGetServicePasswordValue(ServicePassword, ServicePasswordValue) then
            exit;

        IF NOT ENCRYPTIONENABLED THEN
            ISOLATEDSTORAGE.SET(ServicePassword.Key, ServicePasswordValue, DATASCOPE::Company)
        ELSE
            ISOLATEDSTORAGE.SETENCRYPTED(ServicePassword.Key, ServicePasswordValue, DATASCOPE::Company);

        ServicePassword.Delete();
    end;

    [TryFunction]
    local procedure TryGetServicePasswordValue(ServicePassword: Record "Service Password"; var ServicePasswordValue: Text)
    begin
        ServicePasswordValue := ServicePassword.GetPassword;
    end;

    local procedure MoveOCRServiceSecrets()
    var
        OCRServiceSetup: Record "OCR Service Setup";
    begin
        if not OCRServiceSetup.Get() then
            exit;

        if not IsNullGuid(OCRServiceSetup."Authorization Key") then
            MoveToIsolatedStorage(OCRServiceSetup."Authorization Key");

        if not IsNullGuid(OCRServiceSetup."Password Key") then
            MoveToIsolatedStorage(OCRServiceSetup."Password Key");
    end;

    local procedure MoveDocExchServiceSecrets()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
    begin
        if not DocExchServiceSetup.Get() then
            exit;

        if not IsNullGuid(DocExchServiceSetup."Consumer Secret") then
            MoveToIsolatedStorage(DocExchServiceSetup."Consumer Secret");

        if not IsNullGuid(DocExchServiceSetup."Consumer Key") then
            MoveToIsolatedStorage(DocExchServiceSetup."Consumer Key");

        if not IsNullGuid(DocExchServiceSetup.Token) then
            MoveToIsolatedStorage(DocExchServiceSetup.Token);

        if not IsNullGuid(DocExchServiceSetup."Token Secret") then
            MoveToIsolatedStorage(DocExchServiceSetup."Token Secret");

        if not IsNullGuid(DocExchServiceSetup."Doc. Exch. Tenant ID") then
            MoveToIsolatedStorage(DocExchServiceSetup."Doc. Exch. Tenant ID");
    end;

    local procedure MoveCRMConnectionSecrets()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        if not CRMConnectionSetup.Get() then
            exit;

        if not IsNullGuid(CRMConnectionSetup."User Password Key") then
            MoveToIsolatedStorage(CRMConnectionSetup."User Password Key");
    end;

    local procedure MoveCashFlowSetupSecrets()
    var
        CashFlowSetup: Record "Cash Flow Setup";
    begin
        if not CashFlowSetup.Get() then
            exit;

        if not IsNullGuid(CashFlowSetup."Service Pass API Key ID") then
            MoveToIsolatedStorage(CashFlowSetup."Service Pass API Key ID");
    end;

    local procedure MoveO365SyncManagementSecrets()
    var
        ExchangeSync: Record "Exchange Sync";
    begin
        if not ExchangeSync.Get() then
            exit;

        if not IsNullGuid(ExchangeSync."Exchange Account Password Key") then
            MoveToIsolatedStorage(ExchangeSync."Exchange Account Password Key");
    end;

    local procedure MoveOfficeAdminSecrets()
    var
        OfficeAdminCredentials: Record "Office Admin. Credentials";
        PasswordGuid: Guid;
    begin
        if not OfficeAdminCredentials.Get() then
            exit;

        if Evaluate(PasswordGuid, OfficeAdminCredentials.Password) then
            if not IsNullGuid(PasswordGuid) then
                MoveToIsolatedStorage(PasswordGuid);
    end;

    local procedure MoveImageAnalysisSecrets()
    var
        ImageAnalysisSetup: Record "Image Analysis Setup";
    begin
        if not ImageAnalysisSetup.Get() then
            exit;

        if not IsNullGuid(ImageAnalysisSetup."Api Key Key") then
            MoveToIsolatedStorage(ImageAnalysisSetup."Api Key Key");
    end;

    local procedure MoveSMTPMailSecrets()
    var
        SMTPMailSetup: Record "SMTP Mail Setup";
    begin
        if not SMTPMailSetup.Get() then
            exit;

        if not IsNullGuid(SMTPMailSetup."Password Key") then
            MoveToIsolatedStorage(SMTPMailSetup."Password Key");
    end;

    local procedure MoveMarketingSetupSecrets()
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        if not MarketingSetup.Get() then
            exit;

        if not IsNullGuid(MarketingSetup."Exchange Account Password Key") then
            MoveToIsolatedStorage(MarketingSetup."Exchange Account Password Key");
    end;

    local procedure MovePostCodeServiceSecrets()
    var
        PostCodeServiceConfig: Record "Postcode Service Config";
        ServiceKeyGuid: Guid;
    begin
        if not PostCodeServiceConfig.Get() then
            exit;

        if Evaluate(ServiceKeyGuid, PostCodeServiceConfig.ServiceKey) then
            if not IsNullGuid(ServiceKeyGuid) then
                MoveToIsolatedStorage(ServiceKeyGuid);
    end;
}
