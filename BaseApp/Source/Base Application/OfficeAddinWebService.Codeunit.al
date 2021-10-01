#if not CLEAN19
codeunit 1650 "Office Add-in Web Service"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'End of support for Exchange PowerShell. Add-ins can be deployed manually.';
    ObsoleteTag = '19.0';

    trigger OnRun()
    begin
    end;

    [Scope('OnPrem')]
    procedure DeployManifests(Username: Text[80]; Password: Text[30]): Boolean
    var
        AddinDeploymentHelper: Codeunit "Add-in Deployment Helper";
    begin
        SetCredentialsAndDeploy(AddinDeploymentHelper, Username, Password);
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure DeployManifestsWithExchangeEndpoint(Username: Text[80]; Password: Text[30]; Endpoint: Text[250]): Boolean
    var
        AddinDeploymentHelper: Codeunit "Add-in Deployment Helper";
    begin
        AddinDeploymentHelper.SetManifestDeploymentCustomEndpoint(Endpoint);
        SetCredentialsAndDeploy(AddinDeploymentHelper, Username, Password);
        exit(true);
    end;

    local procedure SetCredentialsAndDeploy(AddinDeploymentHelper: Codeunit "Add-in Deployment Helper"; Username: Text[80]; Password: Text[30])
    var
        OfficeAddIn: Record "Office Add-in";
    begin
        AddinDeploymentHelper.SetManifestDeploymentCredentials(Username, Password);
        if OfficeAddIn.Find('-') then
            repeat
                AddinDeploymentHelper.DeployManifest(OfficeAddIn);
            until OfficeAddIn.Next() = 0;
    end;
}
#endif

