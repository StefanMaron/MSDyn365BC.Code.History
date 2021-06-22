codeunit 1651 "Exchange PowerShell Runner"
{

    trigger OnRun()
    begin
    end;

    var
        TempOfficeAdminCredentials: Record "Office Admin. Credentials" temporary;
        PSRunner: DotNet PowerShellRunner;
        PSInitialized: Boolean;
        AppNotRemovedErr: Label 'The application %1 was not removed as expected. Please remove the application manually from the Exchange Admin Center.', Comment = 'A GUID representing the Office add-in.';
        AppDoesntExistMsg: Label 'The application is not deployed to Exchange.';
        NotInitializedErr: Label 'The PowerShell Runner is not initialized.';
        ConnectionFailureErr: Label 'A connection could not be established to the Exchange endpoint at %1. Please verify connection details and try again.', Comment = 'A URL for an Exchange endpoint that Business Central is attempting to connect to.';
        UnableToDeployErr: Label 'The application was not able to be deployed to Exchange. \\ The error message from Exchange is: \\ %1', Comment = '%1 is another error message from a dotnet component.';

    [TryFunction]
    [Scope('OnPrem')]
    procedure InitializePSRunner()
    begin
        if not PSInitialized then begin
            // If there was an issue with credentials, send it up back to the calling function.
            if not PromptForCredentials then begin
                ResetInitialization;
                Error(GetLastErrorText);
            end;

            if UseKerberos then
                TempOfficeAdminCredentials.Email := ConvertEmailToDomainUsername(TempOfficeAdminCredentials.Email);

            if not CreateExchangePSRunner(PSRunner, TempOfficeAdminCredentials, UseKerberos) then
                Error(GetLastErrorText);
        end;
        PSInitialized := true;
    end;

    procedure SetCredentials(UserName: Text[80]; Password: Text[30])
    begin
        if TempOfficeAdminCredentials.IsEmpty then
            TempOfficeAdminCredentials.Init();

        TempOfficeAdminCredentials.Email := UserName;

        if not TempOfficeAdminCredentials.Modify then
            TempOfficeAdminCredentials.Insert(true);

        TempOfficeAdminCredentials.SavePassword(Password);

        Commit();
    end;

    procedure GetCredentials(var TempUserOfficeAdminCredentials: Record "Office Admin. Credentials" temporary)
    begin
        TempUserOfficeAdminCredentials.Copy(TempOfficeAdminCredentials);
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure ValidateCredentials()
    var
        ErrorMessage: Text;
    begin
        if not PSInitialized then
            Error(NotInitializedErr);

        if not RunNullCommand then
            if (TempOfficeAdminCredentials.Endpoint = O365PSEndpoint) and not ValidateO365CredentialsWithEWS then
                ErrorMessage := GetLastErrorText
            else
                ErrorMessage := StrSubstNo(ConnectionFailureErr, TempOfficeAdminCredentials.Endpoint);

        if ErrorMessage <> '' then begin
            ResetInitialization;
            Error(ErrorMessage);
        end
    end;

    procedure SetEndpoint(Endpoint: Text[250])
    begin
        if TempOfficeAdminCredentials.IsEmpty then
            TempOfficeAdminCredentials.Init();

        TempOfficeAdminCredentials.Endpoint := Endpoint;

        if not TempOfficeAdminCredentials.Modify(true) then
            TempOfficeAdminCredentials.Insert(true);
        Commit();
    end;

    [TryFunction]
    procedure PromptForCredentials()
    begin
        if TempOfficeAdminCredentials.IsEmpty then begin
            TempOfficeAdminCredentials.Init();
            TempOfficeAdminCredentials.Insert(true);
            PAGE.RunModal(PAGE::"Office Admin. Credentials", TempOfficeAdminCredentials);
        end;

        if (not TempOfficeAdminCredentials.FindFirst) or
           (TempOfficeAdminCredentials.Email = '') or (TempOfficeAdminCredentials.GetPassword = '')
        then begin
            TempOfficeAdminCredentials.DeleteAll(true);
            Error('');
        end;
    end;

    local procedure UseKerberos(): Boolean
    begin
        exit(TempOfficeAdminCredentials.Endpoint <> DefaultPSEndpoint)
    end;

    local procedure ConvertEmailToDomainUsername(User: Text[80]): Text[80]
    var
        Username: Text;
        Domain: Text;
        AtPos: Integer;
    begin
        AtPos := StrPos(User, '@');
        if AtPos = 0 then
            exit(User);

        Domain := CopyStr(User, AtPos + 1);
        Username := CopyStr(User, 1, AtPos - 1);
        exit(StrSubstNo('%1\%2', Domain, Username));
    end;

    procedure DefaultPSEndpoint(): Text[250]
    begin
        exit(TempOfficeAdminCredentials.DefaultEndpoint);
    end;

    procedure O365PSEndpoint(): Text[250]
    begin
        exit(TempOfficeAdminCredentials.DefaultEndpoint);
    end;

    [TryFunction]
    local procedure CreateExchangePSRunner(var PSRunnerObj: DotNet PowerShellRunner; var OfficeAdminCredentials: Record "Office Admin. Credentials"; UseKerberos: Boolean)
    var
        NetworkCredential: DotNet NetworkCredential;
        Uri: DotNet Uri;
        PSCred: DotNet PSCredential;
    begin
        PSRunnerObj := PSRunnerObj.CreateInSandbox;
        NetworkCredential :=
          NetworkCredential.NetworkCredential(OfficeAdminCredentials.Email, OfficeAdminCredentials.GetPassword);
        PSCred := PSCred.PSCredential(Format(NetworkCredential.UserName), NetworkCredential.SecurePassword);

        PSRunnerObj.SetExchangeRemoteConnectionInformation(
          PSCred, Uri.Uri(OfficeAdminCredentials.Endpoint), 'Microsoft.Exchange', UseKerberos);
    end;

    procedure ResetInitialization()
    begin
        TempOfficeAdminCredentials.DeleteAll();
        Clear(TempOfficeAdminCredentials);
        PSInitialized := false;
        Commit();
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure GetApp(AppID: Text; var ReturnObject: DotNet PSObjectAdapter)
    var
        Enum: DotNet IEnumerator;
    begin
        if not PSInitialized then
            Error(NotInitializedErr);

        AddCommand('Get-App', true);
        AddParameterFlag('OrganizationApp');
        AddParameter('Identity', Format(AppID));
        Invoke;
        GetResultEnumerator(Enum);

        if Enum.MoveNext then begin
            ReturnObject := ReturnObject.PSObjectAdapter;
            ReturnObject.PSObject := Enum.Current;
        end
    end;

    [Scope('OnPrem')]
    procedure RemoveApp(AppID: Text)
    begin
        if not PSInitialized then
            Error(NotInitializedErr);

        if not TryRemoveApp(AppID) then begin
            ResetInitialization;
            Error(GetLastErrorText);
        end;
    end;

    [TryFunction]
    local procedure TryRemoveApp(AppId: Text)
    var
        AppObject: DotNet PSObjectAdapter;
        ValidationAppObject: DotNet PSObjectAdapter;
    begin
        // If, for any reason, we cannot connect, re-throw the error
        if not GetApp(AppId, AppObject) then
            Error(GetLastErrorText);

        // If the add-in is not in Exchange, there's nothing to remove
        if IsNull(AppObject) then begin
            Message(AppDoesntExistMsg);
            exit;
        end;

        AddCommand('Remove-App', true);
        AddParameter('Identity', AppId);
        AddParameterFlag('OrganizationApp');
        AddParameter('Confirm', true);
        Invoke;

        // Force PSRunner's async call to complete
        AwaitCompletion;

        // Validate that the app was removed, if not, display an error to the user
        GetApp(AppId, ValidationAppObject);
        if not IsNull(ValidationAppObject) then
            Error(AppNotRemovedErr, AppId);
    end;

    [Scope('OnPrem')]
    procedure NewApp(var ManifestBytes: DotNet Array; DefaultEnabledState: Text; EnabledState: Text; ProvisionMode: Text): Boolean
    var
        Enum: DotNet IEnumerator;
        ErrorRecord: DotNet ErrorRecord;
    begin
        if not PSInitialized then
            Error(NotInitializedErr);

        AddCommand('New-App', true);
        AddParameter('FileData', ManifestBytes);

        // If these are set, set them in PS, otherwise omit them (and keep the existing values in the case of redeployment)
        if DefaultEnabledState <> '' then
            AddParameter('DefaultStateForUser', DefaultEnabledState);
        if ProvisionMode <> '' then
            AddParameter('ProvidedTo', ProvisionMode);
        EnabledState := UpperCase(EnabledState);
        if EnabledState <> '' then
            if EnabledState = 'TRUE' then
                AddParameter('Enabled', true)
            else
                if EnabledState = 'FALSE' then
                    AddParameter('Enabled', false);

        // Ensure this is an organization-wide app
        AddParameter('OrganizationApp', true);

        Invoke;

        // If we have an object coming back, the app was successfully installed
        GetResultEnumerator(Enum);
        if Enum.MoveNext then
            exit(true);

        // If we did not get an object back, the app was not successfully installed
        // Look for an error message and send that message if it exists.

        if PSRunner.HadErrors then begin
            GetErrorEnumerator(Enum);

            if IsNull(Enum) then
                exit(false);

            if Enum.MoveNext then begin
                ErrorRecord := Enum.Current;

                if IsNull(ErrorRecord) then
                    exit(false);

                Error(StrSubstNo(UnableToDeployErr, ErrorRecord.ToString));
            end;
        end;

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure AddCommand(Command: Text; LocalScope: Boolean)
    begin
        if not PSInitialized then
            Error(NotInitializedErr);

        PSRunner.AddCommand(Command, LocalScope);
    end;

    [Scope('OnPrem')]
    procedure AddParameter(Name: Text; Value: Variant)
    begin
        if not PSInitialized then
            Error(NotInitializedErr);

        PSRunner.AddParameter(Name, Value);
    end;

    [Scope('OnPrem')]
    procedure AddParameterFlag(Name: Text)
    begin
        if not PSInitialized then
            Error(NotInitializedErr);

        PSRunner.AddParameter(Name);
    end;

    [Scope('OnPrem')]
    procedure Invoke()
    begin
        if not PSInitialized then
            Error(NotInitializedErr);

        PSRunner.BeginInvoke;
    end;

    [Scope('OnPrem')]
    procedure AwaitCompletion()
    begin
        if not PSInitialized then
            Error(NotInitializedErr);

        if IsNull(PSRunner.Results) then;
    end;

    [Scope('OnPrem')]
    procedure GetResultEnumerator(var Enumerator: DotNet IEnumerator)
    begin
        if not PSInitialized then
            Error(NotInitializedErr);

        Enumerator := PSRunner.Results.GetEnumerator;
    end;

    [Scope('OnPrem')]
    procedure GetErrorEnumerator(var Enumerator: DotNet IEnumerator)
    begin
        if not PSInitialized then
            Error(NotInitializedErr);

        Enumerator := PSRunner.Errors.GetEnumerator;
    end;

    [Scope('OnPrem')]
    procedure RemoveRemoteConnectionInformation()
    begin
        if PSInitialized then
            PSRunner.RemoveRemoteConnectionInformation;
    end;

    [TryFunction]
    local procedure RunNullCommand()
    begin
        AddCommand(';', true);
        Invoke;
    end;

    [TryFunction]
    local procedure ValidateO365CredentialsWithEWS()
    var
        ExchangeAddinSetup: Codeunit "Exchange Add-in Setup";
    begin
        if not ExchangeAddinSetup.InitializeServiceWithCredentials(TempOfficeAdminCredentials.Email,
             TempOfficeAdminCredentials.GetPassword)
        then
            Error(GetLastErrorText);
    end;

    [Scope('OnPrem')]
    procedure ClearLog()
    begin
        PSRunner.ClearLog;
    end;
}

