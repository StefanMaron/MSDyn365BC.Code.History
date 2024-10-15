// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Upgrade;

using Microsoft.CashFlow.Setup;
using Microsoft.CRM.Outlook;
using Microsoft.CRM.Setup;
using Microsoft.EServices.EDocument;
using Microsoft.Foundation.Address;
using Microsoft.Integration.D365Sales;
using System.AI;
using System.Azure.Identity;
using System.EMail;
using System.Environment;
using System.Upgrade;

codeunit 104020 "Upg Secrets to Isol. Storage"
{
    Subtype = Upgrade;

    trigger OnRun()
    begin
    end;

    trigger OnUpgradePerCompany()
    var
        HybridDeployment: Codeunit "Hybrid Deployment";
    begin
        if not HybridDeployment.VerifyCanStartUpgrade(CompanyName()) then
            exit;

        MoveServicePasswordToIsolatedStorage();
        MoveAzureADAppSetupSecretToIsolatedStorage();
        FixAzureADAppSetup();
    end;

    local procedure MoveServicePasswordToIsolatedStorage()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetServicePasswordToIsolatedStorageTag()) then
            exit;

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

    local procedure FixAzureADAppSetup()
    var
        AzureADAppSetup: Record "Azure AD App Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        IsolatedValue: Text;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetAzureADSetupFixTag()) then
            exit;

        if AzureADAppSetup.FindFirst() then
            if not IsNullGuid(AzureADAppSetup."Isolated Storage Secret Key") then

                // if we have moved a value already to datascope::module then don't try to do it again.
                // ignore the values from other isolated storage with datascope::company.
                if not IsolatedStorage.Contains(AzureADAppSetup."Isolated Storage Secret Key", DataScope::Module) then
                    if IsolatedStorage.Get(AzureADAppSetup."Isolated Storage Secret Key", DataScope::Company, IsolatedValue) then begin
                        IsolatedStorage.Delete(AzureADAppSetup."Isolated Storage Secret Key", DataScope::Company);
                        AzureADAppSetup.SetSecretKeyToIsolatedStorage(IsolatedValue);
                        AzureADAppSetup.Modify();
                    end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetAzureADSetupFixTag());
    end;

    local procedure MoveAzureADAppSetupSecretToIsolatedStorage()
    var
        AzureADAppSetup: Record "Azure AD App Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        InStream: InStream;
        SecretKey, DecryptedSecretKey : Text;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetMoveAzureADAppSetupSecretToIsolatedStorageTag()) then
            exit;
        if not AzureADAppSetup.FindFirst() then
            exit;

        AzureADAppSetup.CalcFields("Secret Key");

        if not AzureADAppSetup."Secret Key".HasValue() then
            exit;

        AzureADAppSetup."Secret Key".CreateInStream(InStream);
        InStream.Read(SecretKey);

        if not TryDecrypt(SecretKey, DecryptedSecretKey) then
            DecryptedSecretKey := SecretKey;

        AzureADAppSetup.SetSecretKeyToIsolatedStorage(DecryptedSecretKey);
        Clear(AzureADAppSetup."Secret Key");
        AzureADAppSetup.Modify();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetMoveAzureADAppSetupSecretToIsolatedStorageTag());
    end;

    [TryFunction]
    local procedure TryDecrypt(SecretKey: text; DecryptedSecretKey: Text)
    begin
        if EncryptionEnabled() then
            DecryptedSecretKey := Decrypt(SecretKey);
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

        if not ENCRYPTIONENABLED() then
            ISOLATEDSTORAGE.SET(ServicePassword.Key, ServicePasswordValue, DATASCOPE::Company)
        else
            ISOLATEDSTORAGE.SETENCRYPTED(ServicePassword.Key, ServicePasswordValue, DATASCOPE::Company);

        ServicePassword.Delete();
    end;

    [TryFunction]
    local procedure TryGetServicePasswordValue(ServicePassword: Record "Service Password"; var ServicePasswordValue: Text)
    begin
        ServicePasswordValue := ServicePassword.GetPassword();
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
