page 6301 "Azure AD App Setup Part"
{
    Caption = '<Azure AD Application Setup Part>';
    PageType = CardPart;
    SourceTable = "Azure AD App Setup";

    layout
    {
        area(content)
        {
            field(HomePageUrl; HomePageUrl)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Home page URL';
                Editable = false;
                ToolTip = 'Specifies the home page URL to enter when registering an Azure application.';
            }
            field(RedirectUrl; RedirectUrl)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Reply URL';
                ToolTip = 'Specifies the reply URL to enter when registering an Azure application.';
            }
            field(AppId; AppId)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Application ID';
                ShowMandatory = true;
                ToolTip = 'Specifies the ID that is assigned to the application when it is registered in Azure AD.  The ID is used for authenticating with Azure AD. This is also referred to as the client ID.';
            }
            field(SecretKey; SecretKey)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Key';
                NotBlank = true;
                ShowMandatory = true;
                ToolTip = 'Specifies the secret key (or client secret) that is used along with the Application ID for authenticating with Azure AD.';
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        AzureADMgt: Codeunit "Azure AD Mgt.";
    begin
        if not FindFirst() then
            Init();

        HomePageUrl := GetUrl(CLIENTTYPE::Web);
        RedirectUrl := AzureADMgt.GetRedirectUrl();
        AppId := "App ID";
        SecretKey := GetSecretKeyFromIsolatedStorage();
    end;

    var
        HomePageUrl: Text;
        RedirectUrl: Text[150];
        [NonDebuggable]
        SecretKey: Text;
        AppId: Guid;
        InvalidAppIdErr: Label 'Enter valid GUID for Application ID.';
        InvalidClientSecretErr: Label 'Key is required.';

    [NonDebuggable]
    procedure Save()
    begin
        "Redirect URL" := RedirectUrl;
        "App ID" := AppId;
        SetSecretKeyToIsolatedStorage(SecretKey);

        if not Modify(true) then
            Insert(true);
    end;

    procedure ValidateFields()
    begin
        if IsNullGuid(AppId) then
            Error(InvalidAppIdErr);

        if SecretKey = '' then
            Error(InvalidClientSecretErr);
    end;

    [Scope('OnPrem')]
    procedure SetReplyURLWithDefault()
    var
        AzureADMgt: Codeunit "Azure AD Mgt.";
    begin
        RedirectUrl := AzureADMgt.GetDefaultRedirectUrl();
    end;

    [NonDebuggable]
    procedure SetAppDetails(ApplicationId: Guid; "Key": Text)
    begin
        AppId := ApplicationId;
        SecretKey := Key;
    end;

    procedure GetRedirectUrl(): Text
    begin
        exit(RedirectUrl);
    end;
}

