table 10523 "GovTalk Setup"
{
    Caption = 'GovTalk Setup';

    fields
    {
        field(1; Id; Code[10])
        {
            Caption = 'Id';
        }
        field(2; Username; Text[250])
        {
            Caption = 'Username';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(3; Password; Guid)
        {
            Caption = 'Password';
        }
        field(4; Endpoint; Text[250])
        {
            Caption = 'Endpoint';
        }
        field(5; "Vendor ID"; Guid)
        {
            Caption = 'Vendor ID';
        }
        field(6; "Test Mode"; Boolean)
        {
            Caption = 'Test Mode';
        }
    }

    keys
    {
        key(Key1; Id)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        AzureKeyVaultErr: Label 'Error while retrieving key from Azure Key Vault: %1.', Comment = '%1 = Error string retrieved from the system.';
        AzureKeyVaultGovTalkVendorIdTok: Label 'govtalk-vendorid', Locked = true;
        IsolatedStorageManagement: Codeunit "Isolated Storage Management";

    [Scope('OnPrem')]
    procedure SavePassword(PasswordValue: Text[250])
    begin
        Password := SaveEncryptedValue(Password, PasswordValue);
    end;

    procedure GetPassword(): Text
    begin
        exit(GetEncryptedValue(Password));
    end;

    procedure SaveVendorID(NewVendorId: Text[250])
    begin
        "Vendor ID" := SaveEncryptedValue("Vendor ID", NewVendorId);
    end;

    procedure GetVendorID(): Text
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        if EnvironmentInfo.IsSaaS then
            exit(GetAzureSecret(AzureKeyVaultGovTalkVendorIdTok));

        exit(GetEncryptedValue("Vendor ID"));
    end;

    local procedure GetEncryptedValue(Value: Guid): Text
    var
        RetrievedValue: Text;
    begin
        IsolatedStorageManagement.Get(Value, DATASCOPE::CompanyAndUser, RetrievedValue);
        exit(RetrievedValue);
    end;

    local procedure SaveEncryptedValue(PasswordGuid: Guid; Value: Text[250]): Guid
    begin
        if not IsNullGuid(PasswordGuid) and (Value = '') then
            IsolatedStorageManagement.Delete(PasswordGuid, DATASCOPE::CompanyAndUser)
        else begin
            if IsNullGuid(PasswordGuid) then
                PasswordGuid := CreateGuid;
            IsolatedStorageManagement.Set(PasswordGuid, Value, DATASCOPE::CompanyAndUser);
        end;
        exit(PasswordGuid);
    end;

    local procedure GetAzureSecret("Key": Text): Text
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        Value: Text;
    begin
        if not AzureKeyVault.GetAzureKeyVaultSecret(Key, Value) then
            Error(AzureKeyVaultErr, GetLastErrorText);

        exit(Value);
    end;

    procedure IsConfigured(): Boolean
    begin
        Get;
        exit((Username <> '') and (not IsNullGuid(Password)));
    end;
}

