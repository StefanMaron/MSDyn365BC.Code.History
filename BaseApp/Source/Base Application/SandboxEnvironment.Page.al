#if not CLEAN19
page 1881 "Sandbox Environment"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Sandbox Environment';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = NavigatePage;
    ShowFilter = false;
    UsageCategory = Administration;
    ObsoleteState = Pending;
    ObsoleteReason = 'This functionality is now available from the Business Central Admin Center.';
    ObsoleteTag = '16.0';

    layout
    {
        area(content)
        {
            group(Control6)
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
            group(Control7)
            {
                Caption = '';
                InstructionalText = 'In addition to your production environment, you can create an environment for sandbox activities, such as test, demonstration, or development.';
            }
            group(Control8)
            {
                Caption = '';
                InstructionalText = 'A new sandbox environment only contains the CRONUS demonstration company. Actions that you perform in the sandbox environment do not affect data or settings in your production environment.';
            }
            group(Control12)
            {
                Caption = '';
                InstructionalText = 'This Sandbox environment feature is provided solely for testing, development and evaluation. You will not use the Sandbox in a live operating environment. Microsoft may, in its sole discretion, change the Sandbox environment or subject it to a fee for a final, commercial version, if any, or may elect not to release one.';
            }
            group(Control9)
            {
                Caption = '';
                InstructionalText = 'Choose Create to start a new sandbox environment.';
            }
            group(Control10)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'This functionality is now available from the Business Central Admin Center.';
                ObsoleteTag = '17.0';
                Visible = false;
                Caption = '';
                InstructionalText = 'Choose Reset to clean and restart the sandbox environment.';
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Create)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Create';
                InFooterBar = true;
                ToolTip = 'Create a sandbox environment.';

                trigger OnAction()
                begin
                    HyperLink(GetFunctionUrl(CreateSandboxUrlTxt));
                end;
            }
            action(Reset)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'This functionality is now available from the Business Central Admin Center.';
                ObsoleteTag = '17.0';
                Visible = false;
                InFooterBar = true;
                trigger OnAction()
                begin
                    Message('The action was deprecated. This functionality is now available from the Business Central Admin Center.');
                end;
            }
            action(Open)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Open';
                InFooterBar = true;
                ToolTip = 'Open the sandbox environment.';

                trigger OnAction()
                begin
                    HyperLink(GetFunctionUrl(CreateSandboxUrlTxt));
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
        MediaRepositoryStandard: Record "Media Repository";
        MediaRepositoryDone: Record "Media Repository";
        MediaResourcesStandard: Record "Media Resources";
        MediaResourcesDone: Record "Media Resources";
        ClientTypeManagement: Codeunit "Client Type Management";
        TopBannerVisible: Boolean;
        EnvironmentErr: Label 'This feature is only available in the online production version of the product.';
        CreateSandboxUrlTxt: Label '/sandbox?redirectedFromSignup=false', Locked = true;

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

    local procedure GetFunctionUrl(SandboxFunctionUrl: Text): Text
    var
        UrlHelper: Codeunit "Url Helper";
        Prefix: Text;
    begin
        Prefix := UrlHelper.GetTenantUrl;
        if Prefix <> '' then
            exit(Prefix + SandboxFunctionUrl);

        exit('');
    end;
}
#endif