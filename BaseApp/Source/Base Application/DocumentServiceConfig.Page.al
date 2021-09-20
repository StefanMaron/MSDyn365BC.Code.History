page 9551 "Document Service Config"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Microsoft SharePoint Connection Setup';
    DelayedInsert = true;
    InsertAllowed = false;
    PageType = Card;
    Permissions = TableData "Document Service" = rimd;
    SourceTable = "Document Service";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Service ID"; "Service ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Service ID';
                    ToolTip = 'Specifies a unique code for the service that you use for document storage and usage.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description';
                    ToolTip = 'Specifies a description for the document service.';
                }
                field(Location; Location)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Location';
                    ToolTip = 'Specifies the URI for where your documents are stored, such as your site on SharePoint Online.';
                }
                field(Folder; Folder)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Folder';
                    ToolTip = 'Specifies the folder in the document repository for this document service that you want documents to be stored in.';
                }
            }
            group("Shared documents")
            {
                Caption = 'Shared Documents';
                field("Document Repository"; "Document Repository")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document Repository';
                    ToolTip = 'Specifies the location where your document service provider stores your documents, if you want to store documents in a shared document repository.';
                }
                field("User Name"; "User Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'User Name';
                    ToolTip = 'Specifies the account that Business Central Server must use to log on to the document service, if you want to use a shared document repository.';
                    trigger OnAssistEdit()
                    var
                        User: Record User;
                    begin
                        if "Authentication Type" = "Authentication Type"::OAuth2 then
                            if User.Get(UserSecurityId()) then
                                "User Name" := CopyStr(User."Authentication Email", 1, MaxStrLen("User Name"));
                    end;

                    trigger OnValidate()
                    var
                        User: Record User;
                    begin
                        if "User Name" <> '' then
                            if not IsLegacyAuthentication then
                                if User.Get(UserSecurityId()) then
                                    if "User Name" <> User."Authentication Email" then
                                        Error(ChangeToCurrentUserErr);
                    end;
                }
                field("Authentication Type"; "Authentication Type")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Authentication Type';
                    ToolTip = 'Specifies the authentication type that will be used to connect to the SharePoint environment', Comment = 'SharePong is the name of a Microsoft service and should not be translated.';
                    trigger OnValidate()
                    var
                        User: Record User;
                    begin
                        if "Authentication Type" = "Authentication Type"::Legacy then
                            IsLegacyAuthentication := true
                        else begin
                            IsLegacyAuthentication := false;
                            if User.Get(UserSecurityId()) then
                                if User."Authentication Email" <> "User Name" then begin
                                    "User Name" := '';
                                    Modify(false);
                                    CurrPage.Update(false);
                                end;
                        end;
                    end;
                }
            }
            group("Authentication")
            {
                Caption = 'Authentication';
                Visible = not SoftwareAsAService and not IsLegacyAuthentication;
                field("Client Id"; "Client Id")
                {
                    ApplicationArea = Suite;
                    Caption = 'Client Id';
                    ToolTip = 'Specifies the id of the Azure Active Directory application that will be used to connect to the SharePoint environment.', Comment = 'SharePoint and Azure Active Directory are names of a Microsoft service and a Microsoft Azure resource and should not be translated.';
                }
                field("Client Secret"; ClientSecret)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Client Secret';
                    ExtendedDatatype = Masked;
                    ToolTip = 'Specifies the secret of the Azure Active Directory application that will be used to connect to the SharePoint environment.', Comment = 'SharePoint and Azure Active Directory are names of a Microsoft service and a Microsoft Azure resource and should not be translated.';

                    trigger OnValidate()
                    var
                        DocumentServiceManagement: Codeunit "Document Service Management";
                    begin
                        if not IsTemporary() then
                            if (ClientSecret <> '') and (not EncryptionEnabled()) then
                                if Confirm(EncryptionIsNotActivatedQst) then
                                    Page.RunModal(Page::"Data Encryption Management");
                        DocumentServiceManagement.SetClientSecret(ClientSecret);
                    end;
                }
                field("Redirect URL"; "Redirect URL")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Redirect URL of the Azure Active Directory application that will be used to connect to the SharePoint environment.', Comment = 'SharePoint and Azure Active Directory are names of a Microsoft service and a Microsoft Azure resource and should not be translated.';
                }
            }
        }
    }
    actions
    {
        area(processing)
        {
            action("Test Connection")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Test Connection';
                Image = ValidateEmailLoggingSetup;
                Visible = IsLegacyAuthentication;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Test the configuration settings against the online document storage service.';

                trigger OnAction()
                begin
                    TestConnection();
                end;

            }
            action("Set Password")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Set Password';
                Visible = IsLegacyAuthentication;
                Enabled = DynamicEditable;
                Image = EncryptionKeys;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Set the password for the current User Name';

                trigger OnAction()
                var
                    DocumentServiceAccPwd: Page "Document Service Acc. Pwd.";
                begin
                    if DocumentServiceAccPwd.RunModal = ACTION::OK then begin
                        if Confirm(ChangePwdQst) then
                            Password := DocumentServiceAccPwd.GetData();
                    end;
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        DynamicEditable := CurrPage.Editable;
    end;

    trigger OnInit()
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        DynamicEditable := false;
        SoftwareAsAService := EnvironmentInformation.IsSaaSInfrastructure();
    end;

    trigger OnOpenPage()
    begin
        if not FindFirst() then begin
            Init();
            "Service ID" := 'Service 1';
            "Authentication Type" := "Authentication Type"::OAuth2;
            InitializeDefaultRedirectUrl();
            Insert(false);
            IsLegacyAuthentication := false;
        end else begin
            IsLegacyAuthentication := Rec."Authentication Type" = Rec."Authentication Type"::Legacy;
            if not IsLegacyAuthentication then begin
                ClientSecret := GetClientSecret();
                if "Redirect URL" = '' then
                    InitializeDefaultRedirectUrl();
            end;
            Modify(false);
        end;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if (not ConnectionTested) and IsLegacyAuthentication then
            if not Confirm(StrSubstNo(TestServiceQst, CurrPage.Caption()), true) then
                exit(false);
    end;

    var
        ChangePwdQst: Label 'Are you sure that you want to change your password?';
        ValidateSuccessMsg: Label 'The connection settings validated correctly, and the current configuration can connect to the document storage service.';
        EncryptionIsNotActivatedQst: Label 'Data encryption is currently not enabled. We recommend that you encrypt data. \Do you want to open the Data Encryption Management window?';
        TestServiceQst: Label 'The %1 is not tested. Are you sure you want to exit?', Comment = '%1 = This Page Caption (Microsoft SharePoint Connection Setup)';
        ChangeToCurrentUserErr: Label 'The user name you are trying to set does not correspond to the current logged in user and it is not allowed. Please use the currently logged in user instead.';
        [NonDebuggable]
        ClientSecret: Text;
        DynamicEditable: Boolean;
        IsLegacyAuthentication: Boolean;
        SoftwareAsAService: Boolean;
        ConnectionTested: Boolean;

    [NonDebuggable]
    local procedure InitializeDefaultRedirectUrl()
    var
        OAuth2: Codeunit OAuth2;
        RedirectUrl: Text;
    begin
        OAuth2.GetDefaultRedirectUrl(RedirectUrl);
        "Redirect URL" := CopyStr(RedirectUrl, 1, MaxStrLen("Redirect URL"));
    end;

    [NonDebuggable]
    local procedure GetClientSecret(): Text
    var
        DocumentServiceManagement: Codeunit "Document Service Management";
        ClientSecretTxt: Text;
    begin
        if DocumentServiceManagement.TryGetClientSecretFromIsolatedStorage(ClientSecretTxt) then
            exit(ClientSecretTxt);

        exit('');
    end;

    [NonDebuggable]
    local procedure TestConnection()
    var
        DocumentServiceManagement: Codeunit "Document Service Management";
    begin
        // Save record to make sure the credentials are reset.
        Modify();
        Commit();
        DocumentServiceManagement.TestConnection();
        ConnectionTested := true;
        Message(ValidateSuccessMsg);
    end;
}

