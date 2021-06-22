page 1920 "Container Sandbox Environment"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Container Sandbox Environment (Preview)';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = NavigatePage;
    ShowFilter = false;
    UsageCategory = Lists;
    ObsoleteState = Pending;
    ObsoleteReason = 'This functionality is now available from the Business Central Admin Center.';
    ObsoleteTag = '16.0';

    layout
    {
        area(content)
        {
            group(Control2)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible;
                field("MediaResourcesStandard.""Media Reference"""; MediaResourcesStandard."Media Reference")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Control4)
            {
                InstructionalText = 'If your development requirements go beyond what the sandbox environment offers, you can create a container-based environment with the full product and use that for development and testing. You can host the container either locally or on an Azure VM.';
                ShowCaption = false;
            }
            group(Control5)
            {
                InstructionalText = 'If you decide to use Azure VM you will be asked to log into the Azure Portal and fill out an Azure Resource Management Template, and then press Purchase. The Virtual Machine will be running a container with the same version of the product as your production environment and will run in your own subscription incurring costs as determined by the selected VM size.';
                ShowCaption = false;
            }
            group(Control6)
            {
                InstructionalText = 'If you decide to run locally we will provide a PowerShell script that must be run on a Windows machine with PowerShell and the appropriate container hosting software installed. The PowerShell script will install and use the NavContainerHelper to run a container with the same version of the product as your production environment.';
                ShowCaption = false;
            }
            group(Control10)
            {
                InstructionalText = 'This Sandbox environment feature is provided as a free preview solely for testing, development and evaluation. You will not use the Sandbox in a live operating environment. Microsoft may, in its sole discretion, change the Sandbox environment or subject it to a fee for a final, commercial version, if any, or may elect not to release one.';
                ShowCaption = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(AzureVM)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Host in Azure';
                InFooterBar = true;
                ToolTip = 'Create a container sandbox environment hosted on an Azure VM';

                trigger OnAction()
                begin
                    HyperLink(GetFunctionUrl('BCSandboxAzure'));
                end;
            }
            action(HostLocally)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Host locally';
                InFooterBar = true;
                ToolTip = 'Create a container sandbox environment hosted on your local machine';

                trigger OnAction()
                begin
                    HyperLink(GetFunctionUrl('BCSandboxLocal'));
                end;
            }
        }
    }

    trigger OnInit()
    begin
        LoadTopBanners;
    end;

    trigger OnOpenPage()
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        if not EnvironmentInfo.IsSaaS or EnvironmentInfo.IsSandbox then
            Error(EnvironmentErr);
    end;

    var
        MediaRepositoryDone: Record "Media Repository";
        MediaRepositoryStandard: Record "Media Repository";
        MediaResourcesDone: Record "Media Resources";
        MediaResourcesStandard: Record "Media Resources";
        ClientTypeManagement: Codeunit "Client Type Management";
        EnvironmentErr: Label 'This feature is only available in the online production version of the product.';
        Uri: DotNet Uri;
        NavTenantSettingsHelper: DotNet NavTenantSettingsHelper;
        TopBannerVisible: Boolean;

    local procedure LoadTopBanners()
    begin
        if MediaRepositoryStandard.Get('AssistedSetup-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType)) and
           MediaRepositoryDone.Get('AssistedSetupDone-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType))
        then
            if MediaResourcesStandard.Get(MediaRepositoryStandard."Media Resources Ref") and
               MediaResourcesDone.Get(MediaRepositoryDone."Media Resources Ref")
            then
                TopBannerVisible := MediaResourcesDone."Media Reference".HasValue;
    end;

    local procedure GetFunctionUrl(FunctionName: Text): Text
    var
        UrlHelper: Codeunit "Url Helper";
        EnvironmentInformation: Codeunit "Environment Information";
        UrlParameters: Text;
        FunctionUrl: Text;
        EnvironmentSuffix: Text;
    begin
        UrlParameters := '?platform=' + Uri.EscapeDataString(GetPlatformVersion) +
          '&application=' + Uri.EscapeDataString(GetApplicationVersion) +
          '&family=' + Uri.EscapeDataString(EnvironmentInformation.GetApplicationFamily);

        if UrlHelper.IsPROD then
            EnvironmentSuffix := ''
        else
            EnvironmentSuffix := '-Tie';

        FunctionUrl := 'https://aka.ms/' + FunctionName + EnvironmentSuffix + UrlParameters;
        exit(FunctionUrl)
    end;

    local procedure GetApplicationVersion(): Text
    begin
        exit(NavTenantSettingsHelper.GetApplicationVersion())
    end;

    local procedure GetPlatformVersion(): Text
    begin
        exit(NavTenantSettingsHelper.GetPlatformVersion().ToString())
    end;
}

