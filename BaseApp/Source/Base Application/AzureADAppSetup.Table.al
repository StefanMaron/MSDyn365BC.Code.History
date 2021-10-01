table 6300 "Azure AD App Setup"
{
    Caption = 'Azure AD App Setup';
    DataPerCompany = false;
    ReplicateData = false;

    fields
    {
        field(1; "App ID"; Guid)
        {
            Caption = 'App ID';
            NotBlank = true;
        }
        field(2; "Secret Key"; BLOB)
        {
            Caption = 'Secret Key';
            ObsoleteState = Pending;
            ObsoleteReason = 'The Secret Key has been moved to Isolated Storage. Use GetSecretKeyFromIsolatedStorage/SetSecretKeyToIsolatedStorage to retrieve or set the Secret Key.';
            ObsoleteTag = '17.0';
        }
        field(3; "Primary Key"; Integer)
        {
            AutoIncrement = true;
            Caption = 'Primary Key';
        }
        field(4; "Redirect URL"; Text[150])
        {
            Caption = 'Redirect URL';
        }
        field(5; "Isolated Storage Secret Key"; Guid)
        {
            Caption = 'Isolated Storage Secret Key';
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

    trigger OnInsert()
    begin
        if Count > 1 then
            Error(OnlyOneRecordErr);
    end;

    var
        OnlyOneRecordErr: Label 'There should be only one record for Azure AD App Setup.';

    [NonDebuggable]
    [Scope('OnPrem')]
    procedure GetSecretKeyFromIsolatedStorage() SecretKey: Text
    begin
        if not IsNullGuid("Isolated Storage Secret Key") then
            if not IsolatedStorage.Get("Isolated Storage Secret Key", DataScope::Module, SecretKey) then;

        exit(SecretKey);
    end;

    [NonDebuggable]
    [Scope('OnPrem')]
    procedure SetSecretKeyToIsolatedStorage(SecretKey: Text)
    var
        NewSecretGuid: Guid;
    begin
        if not IsNullGuid("Isolated Storage Secret Key") then
            if not IsolatedStorage.Delete("Isolated Storage Secret Key", DataScope::Module) then;

        NewSecretGuid := CreateGuid();

        if (not EncryptionEnabled() or (StrLen(SecretKey) > 215)) then
            IsolatedStorage.Set(NewSecretGuid, SecretKey, DataScope::Module)
        else
            IsolatedStorage.SetEncrypted(NewSecretGuid, SecretKey, DataScope::Module);

        Rec."Isolated Storage Secret Key" := NewSecretGuid;
    end;
}

