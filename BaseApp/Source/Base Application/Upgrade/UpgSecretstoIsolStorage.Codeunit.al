codeunit 104020 "Upg Secrets to Isol. Storage"
{
    Subtype = Upgrade;

    trigger OnRun()
    begin
    end;

    trigger OnUpgradePerCompany()
    begin
        MoveServicePasswordToIsolatedStorage();
        MoveEncryptedKeyValueToIsolatedStorage();
        MoveGraphMailRefreshCodeToIsolatedStorage();
    end;

    local procedure MoveServicePasswordToIsolatedStorage()
    var
        ServicePassword: Record "Service Password";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        ServicePasswordValue: Text;
    begin
        IF UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetServicePasswordToIsolatedStorageTag()) THEN
            EXIT;

        IF ServicePassword.FINDSET THEN BEGIN
            REPEAT
                ServicePasswordValue := ServicePassword.GetPassword;
                IF NOT ENCRYPTIONENABLED THEN
                    ISOLATEDSTORAGE.SET(ServicePassword.Key, ServicePasswordValue, DATASCOPE::Company)
                ELSE
                    ISOLATEDSTORAGE.SETENCRYPTED(ServicePassword.Key, ServicePasswordValue, DATASCOPE::Company);
            UNTIL ServicePassword.NEXT = 0;
        END;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetServicePasswordToIsolatedStorageTag());
    end;

    local procedure MoveEncryptedKeyValueToIsolatedStorage()
    var
        EncryptedKeyValue: Record "Encrypted Key/Value";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        EncryptedValue: Text;
    begin
        IF UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetEncryptedKeyValueToIsolatedStorageTag()) THEN
            EXIT;

        IF EncryptedKeyValue.FINDSET THEN BEGIN
            REPEAT
                EncryptedValue := EncryptedKeyValue.GetValue;
                IF NOT ENCRYPTIONENABLED THEN
                    ISOLATEDSTORAGE.SET(EncryptedKeyValue.Key, EncryptedValue, DATASCOPE::Company)
                ELSE
                    ISOLATEDSTORAGE.SETENCRYPTED(EncryptedKeyValue.Key, EncryptedValue, DATASCOPE::Company);
            UNTIL EncryptedKeyValue.NEXT = 0;
        END;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetEncryptedKeyValueToIsolatedStorageTag());
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

                IF NOT ENCRYPTIONENABLED THEN
                    ISOLATEDSTORAGE.SET('RefreshTokenKey', RefreshCodeValue, DATASCOPE::Company)
                ELSE
                    ISOLATEDSTORAGE.SETENCRYPTED('RefreshTokenKey', RefreshCodeValue, DATASCOPE::Company);
            END;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetGraphMailRefreshCodeToIsolatedStorageTag());
    end;
}

