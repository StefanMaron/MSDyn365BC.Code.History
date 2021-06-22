codeunit 1650 "Office Add-in Web Service"
{

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
            until OfficeAddIn.Next = 0;
    end;
}

