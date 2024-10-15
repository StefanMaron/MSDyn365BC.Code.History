table 1260 "Bank Data Conv. Service Setup"
{
    Caption = 'Bank Data Conv. Service Setup';
    ObsoleteState = Removed;
    ObsoleteReason = 'Changed to AMC Banking 365 Fundamentals Extension';
    ObsoleteTag = '15.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "User Name"; Text[50])
        {
            Caption = 'User Name';
            DataClassification = EndUserIdentifiableInformation;
            Editable = true;
        }
        field(3; "Password Key"; Guid)
        {
            Caption = 'Password Key';
        }
        field(4; "Sign-up URL"; Text[250])
        {
            Caption = 'Sign-up URL';
            ExtendedDatatype = URL;
        }
        field(5; "Service URL"; Text[250])
        {
            Caption = 'Service URL';

            trigger OnValidate()
            var
                WebRequestHelper: Codeunit "Web Request Helper";
            begin
                if "Service URL" <> '' then
                    WebRequestHelper.IsSecureHttpUrl("Service URL");
            end;
        }
        field(6; "Support URL"; Text[250])
        {
            Caption = 'Support URL';
            ExtendedDatatype = URL;
        }
        field(7; "Namespace API Version"; Text[10])
        {
            Caption = 'Namespace API Version';
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        DeletePassword();
    end;

    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        EnvironmentInfo: Codeunit "Environment Information";
        CompanyInformationMgt: Codeunit "Company Information Mgt.";
        IsolatedStorageManagement: Codeunit "Isolated Storage Management";

        UserNameSecretTxt: Label 'amcname', Locked = true;
        PasswordSecretTxt: Label 'amcpassword', Locked = true;

    [NonDebuggable]
    [Scope('OnPrem')]
    procedure SavePassword(PasswordText: Text)
    begin
        if IsNullGuid("Password Key") then
            "Password Key" := CreateGuid();

        IsolatedStorageManagement.Set("Password Key", PasswordText, DATASCOPE::Company);
    end;

    [Scope('OnPrem')]
    procedure GetUserName(): Text[50]
    begin
        if DemoSaaSCompany() and ("User Name" = '') then
            exit(RetrieveSaaSUserName());

        exit("User Name");
    end;

    [NonDebuggable]
    [Scope('OnPrem')]
    procedure GetPassword(): Text
    var
        Value: Text;
    begin
        // if Demo Company and empty User Name retrieve from Azure Key Vault
        if DemoSaaSCompany() and ("User Name" = '') then
            exit(RetrieveSaaSPass());

        IsolatedStorageManagement.Get("Password Key", DATASCOPE::Company, Value);
        exit(Value);
    end;

    [Scope('OnPrem')]
    local procedure DeletePassword()
    begin
        IsolatedStorageManagement.Delete("Password Key", DATASCOPE::Company);
    end;

    procedure HasUserName(): Boolean
    begin
        // if Demo Company try to retrieve from Azure Key Vault
        if DemoSaaSCompany() then
            exit(true);

        exit("User Name" <> '');
    end;

    [Scope('OnPrem')]
    procedure HasPassword(): Boolean
    begin
        if DemoSaaSCompany() and ("User Name" = '') then
            exit(true);

        exit(IsolatedStorageManagement.Contains("Password Key", DATASCOPE::Company));
    end;

    local procedure RetrieveSaaSUserName(): Text[50]
    var
        UserNameValue: Text[50];
    begin
        if AzureKeyVault.GetAzureKeyVaultSecret(UserNameSecretTxt, UserNameValue) then
            exit(UserNameValue);
    end;

    local procedure RetrieveSaaSPass(): Text
    var
        PasswordValue: Text;
    begin
        if AzureKeyVault.GetAzureKeyVaultSecret(PasswordSecretTxt, PasswordValue) then
            exit(PasswordValue);
    end;

    local procedure DemoSaaSCompany(): Boolean
    begin
        exit(EnvironmentInfo.IsSaaS() and CompanyInformationMgt.IsDemoCompany());
    end;
}
