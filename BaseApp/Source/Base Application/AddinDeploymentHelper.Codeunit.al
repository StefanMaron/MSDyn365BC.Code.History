codeunit 1640 "Add-in Deployment Helper"
{

    trigger OnRun()
    begin
    end;

    var
        ExchangePowerShellRunner: Codeunit "Exchange PowerShell Runner";
        AddinManifestMgt: Codeunit "Add-in Manifest Management";
        AppNotInstalledErr: Label 'The application %1 did not install as expected. This might be caused by problems with the manifest file, problems connecting to the Exchange PowerShell server, or a version number that is not equal to or higher than the already installed application. You can download the manifest locally and then upload it to the Exchange Administration Center to determine the cause.', Comment = '%1: A GUID identifying the office add-in.';

    [Scope('OnPrem')]
    procedure DeployManifest(var NewOfficeAddin: Record "Office Add-in")
    var
        UserPreference: Record "User Preference";
        InstructionMgt: Codeunit "Instruction Mgt.";
        ManifestText: Text;
        ErrorText: Text;
    begin
        InitializeExchangePSRunner;
        AddinManifestMgt.GenerateManifest(NewOfficeAddin, ManifestText);

        // Clear the credentials if the action fails and reset the PS object.
        if not RunManifestDeployer(ManifestText, NewOfficeAddin."Application ID") then begin
            ExchangePowerShellRunner.ResetInitialization;
            ErrorText := GetLastErrorText;
            if ErrorText <> '' then
                Error(ErrorText);

            Error(StrSubstNo(AppNotInstalledErr, NewOfficeAddin.Name));
        end;

        NewOfficeAddin."Deployment Date" := Today;
        NewOfficeAddin.Modify();

        UserPreference.SetRange("Instruction Code", InstructionMgt.OfficeUpdateNotificationCode);
        UserPreference.DeleteAll();
    end;

    [TryFunction]
    local procedure RunManifestDeployer(ManifestText: Text; AppID: Guid)
    var
        PSObj: DotNet PSObjectAdapter;
        Encoding: DotNet UTF8Encoding;
        ManifestBytes: DotNet Array;
        ProvisionMode: Text;
        DefaultUserEnableState: Text;
        EnabledState: Text;
    begin
        InitializeExchangePSRunner;

        ExchangePowerShellRunner.GetApp(AppID, PSObj);

        if IsNull(PSObj) then begin
            DefaultUserEnableState := 'Enabled';
            EnabledState := 'TRUE';
            ProvisionMode := 'Everyone';
        end;

        Encoding := Encoding.UTF8Encoding;
        ManifestBytes := Encoding.GetBytes(ManifestText);

        // Add the add-in
        if not ExchangePowerShellRunner.NewApp(ManifestBytes, DefaultUserEnableState, EnabledState, ProvisionMode) then
            Error(AppNotInstalledErr, Format(AppID));
    end;

    procedure SetManifestDeploymentCredentials(Username: Text[80]; Password: Text[30])
    begin
        ExchangePowerShellRunner.SetCredentials(Username, Password);
    end;

    procedure SetManifestDeploymentCustomEndpoint(Endpoint: Text[250])
    begin
        ExchangePowerShellRunner.SetEndpoint(Endpoint);
    end;

    [Scope('OnPrem')]
    procedure RemoveApp(var OfficeAddin: Record "Office Add-in")
    var
        AppID: Guid;
    begin
        InitializeExchangePSRunner;
        AppID := AddinManifestMgt.GetAppID(OfficeAddin.GetDefaultManifestText);
        ExchangePowerShellRunner.RemoveApp(AppID);
    end;

    local procedure InitializeExchangePSRunner()
    begin
        ExchangePowerShellRunner.PromptForCredentials;
        ExchangePowerShellRunner.InitializePSRunner;
        ExchangePowerShellRunner.ValidateCredentials;
    end;

    [Scope('OnPrem')]
    procedure InitializeAndValidate()
    begin
        InitializeExchangePSRunner;
    end;

    procedure CheckVersion(HostType: Text; UserVersion: Text) CanContinue: Boolean
    var
        OfficeAddin: Record "Office Add-in";
        InstructionMgt: Codeunit "Instruction Mgt.";
        LatestAddinVersion: Text;
    begin
        AddinManifestMgt.GetAddinByHostType(OfficeAddin, HostType);
        AddinManifestMgt.GetAddinVersion(LatestAddinVersion, OfficeAddin."Manifest Codeunit");

        // Make sure that the version of the add-in in the table is up to date
        if OfficeAddin.Version <> LatestAddinVersion then begin
            AddinManifestMgt.CreateDefaultAddins(OfficeAddin);
            Commit();
            AddinManifestMgt.GetAddinByHostType(OfficeAddin, HostType);
        end;

        CanContinue := true;
        if UserVersion <> OfficeAddin.Version then begin
            OfficeAddin.Breaking := OfficeAddin.IsBreakingChange(UserVersion);
            if OfficeAddin.Breaking then
                PAGE.RunModal(PAGE::"Office Update Available Dlg", OfficeAddin)
            else
                if InstructionMgt.IsEnabled(InstructionMgt.OfficeUpdateNotificationCode) then
                    PAGE.RunModal(PAGE::"Office Update Available Dlg", OfficeAddin);

            CanContinue := not OfficeAddin.Breaking;
        end;
    end;
}

