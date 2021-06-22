page 9807 "User Card"
{
    Caption = 'User Card';
    DataCaptionExpression = "Full Name";
    DelayedInsert = true;
    PageType = Card;
    SourceTable = User;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("User Security ID"; "User Security ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'User Security ID';
                    ToolTip = 'Specifies an ID that uniquely identifies the user. This value is generated automatically and should not be changed.';
                    Visible = false;
                }
                field("User Name"; "User Name")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the user''s name. If the user is required to present credentials when starting the client, this is the name that the user must present.';

                    trigger OnValidate()
                    begin
                        if xRec."User Name" <> "User Name" then
                            ValidateUserName;
                    end;
                }
                field("Full Name"; "Full Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = not IsSaaS;
                    ToolTip = 'Specifies the full name of the user.';
                }
                field("License Type"; "License Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of license that applies to the user.';
                    Visible = not IsSaaS;
                }
                field(State; State)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies if the user''s login is enabled.';
                    trigger OnValidate()
                    begin
                        ValidateState();
                    end;
                }
                field("Expiry Date"; "Expiry Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a date past which the user will no longer be authorized to log on to the Windows client.';
                    Visible = not IsSaaS;
                }
                field("Contact Email"; "Contact Email")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the user''s email address.';
                }
            }
            group("Windows Authentication")
            {
                Caption = 'Windows Authentication';
                Visible = (not DeployedToAzure) and (not IsSaaS);
                field("Windows Security ID"; "Windows Security ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Windows Security ID of the user. This is only relevant for Windows authentication.';
                    Visible = false;
                }
                field("Windows User Name"; WindowsUserName)
                {
                    ApplicationArea = Basic, Suite;
                    AssistEdit = false;
                    Caption = 'Windows User Name';
                    Importance = Promoted;
                    ToolTip = 'Specifies the name of a valid Active Directory user, using the format domain\username.';

                    trigger OnValidate()
                    begin
                        ValidateWindowsUserName;
                    end;
                }
                field("Windows User Name Desktop"; WindowsUserName)
                {
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Windows Client only functionality. Will be removed. Use "Windows User Name" instead.';
                    ObsoleteTag = '15.3';
                    ApplicationArea = Basic, Suite;
                    AssistEdit = true;
                    Caption = 'Windows User Name';
                    Importance = Promoted;
                    ToolTip = 'Specifies the name of a valid Active Directory user, using the format domain\username.';
                    Visible = false;

                    trigger OnAssistEdit()
                    begin
                        error(''); // client side DLL not supported.
                    end;

                    trigger OnValidate()
                    begin
                        ValidateWindowsUserName;
                    end;
                }
            }
            group("ACS Authentication")
            {
                Caption = 'Access Control Service Authentication';
                Visible = not IsSaaS;
                field(ACSStatus; ACSStatus)
                {
                    ApplicationArea = Basic, Suite;
                    AssistEdit = true;
                    Caption = 'ACS Access Status';
                    DrillDown = false;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the user''s status for ACS authentication. When you start creating a user, the status is Disabled. After you create a user, the status changes to Pending. After the user logs on successfully, the status changes to Enabled.';
                    Visible = not IsSaaS;

                    trigger OnAssistEdit()
                    begin
                        EditACSStatus;
                    end;
                }
            }
            group("NAV Password Authentication")
            {
                Caption = 'Business Central Password Authentication';
                Visible = not IsSaaS;
                field(Password; Password)
                {
                    ApplicationArea = Basic, Suite;
                    AssistEdit = true;
                    Caption = 'Password';
                    Editable = false;
                    ExtendedDatatype = Masked;
                    Importance = Standard;
                    ToolTip = 'Specifies an initial password for the user. To sign in to the client, the user must provide the name that is specified in the User Name field and this password.';

                    trigger OnAssistEdit()
                    begin
                        EditNavPassword;
                    end;
                }
                field("Change Password"; "Change Password")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'User must change password at next login';
                    ToolTip = 'Specifies if the user will be prompted to change the password at next login.';
                }
            }
            group("Web Service Access")
            {
                Caption = 'Web Service Access';
                field(WebServiceID; WebServiceID)
                {
                    ApplicationArea = Basic, Suite;
                    AssistEdit = true;
                    Caption = 'Web Service Access Key';
                    Editable = false;
                    ToolTip = 'Specifies a generated key that Dynamics 365 web service applications can use to authenticate to Dynamics 365 services. Choose the AssistEdit button to generate a key.';

                    trigger OnAssistEdit()
                    begin
                        EditWebServiceID;
                    end;
                }
                field(WebServiceExpiryDate; WebServiceExpiryDate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Web Service Expiry Date';
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies an expiration date for the web services access key.';
                }
            }
            group("Office 365 Authentication")
            {
                Caption = 'Office 365 Authentication', Comment = '{Locked="Office 365"}';
                field("Authentication Email"; "Authentication Email")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = not IsSaaS;
                    ToolTip = 'Specifies the Microsoft account that this user signs into Office 365 or SharePoint Online with.';

                    trigger OnValidate()
                    begin
                        IdentityManagement.SetAuthenticationEmail("User Security ID", "Authentication Email");
                        CurrPage.SaveRecord;
                        AuthenticationStatus := IdentityManagement.GetAuthenticationStatus("User Security ID");
                    end;
                }
                field(ApplicationID; ApplicationID)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Application ID';
                    ToolTip = 'Specifies the client ID of the Microsoft Azure Active Directory application when authenticating web-service calls. This field is only relevant when the Business Central user is used for web services.';
                    Visible = not IsSaaS;

                    trigger OnValidate()
                    var
                        ZeroGUID: Guid;
                    begin
                        if ApplicationID = '' then
                            Validate("Application ID", ZeroGUID)
                        else
                            Validate("Application ID", ApplicationID);
                    end;
                }
                field(MappedToExchangeIdentifier; HasExchangeIdentifier)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Mapped To Exchange Identifier';
                    Editable = false;
                    Style = StandardAccent;
                    StyleExpr = TRUE;
                    ToolTip = 'Specifies whether the user is mapped to a Microsoft Exchange identifier, which enables the user to access Business Central from Exchange applications (such as Outlook) without having to sign-in.';
                }
                field(AuthenticationStatus; AuthenticationStatus)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Authentication Status';
                    Editable = false;
                    ToolTip = 'Specifies the user''s status for Office 365 authentication. When you start to create a user, the status is Disabled. After you specify an authentication email address for the user, the status changes to Inactive. After the user logs on successfully, the status changes to Active.';
                }
            }
            part(Plans; "User Plans FactBox")
            {
                Caption = 'Licenses';
                ApplicationArea = Basic, Suite;
                SubPageLink = "User Security ID" = field("User Security ID");
                Visible = IsSaaS;
            }

            part(UserGroups; "User Groups User SubPage")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'User Groups';
                SubPageLink = "User Security ID" = field("User Security ID");
                UpdatePropagation = Both;
            }
            part(Permissions; "User Subform")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'User Permission Sets';
                SubPageLink = "User Security ID" = field("User Security ID");
            }
        }
        area(factboxes)
        {
            systempart(Control17; Notes)
            {
                ApplicationArea = Notes;
            }
            systempart(Control18; Links)
            {
                ApplicationArea = RecordLinks;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(Authentication)
            {
                Caption = 'Authentication';
                action(AcsSetup)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&ACS Setup';
                    Image = ServiceSetup;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Set up Access Control Service authentication, such as generating an authentication key that the user can use to connect to Azure.';
                    Visible = not IsSaaS;

                    trigger OnAction()
                    begin
                        EditACSStatus;
                    end;
                }
                action(ChangePassword)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Change &Password';
                    Image = EncryptionKeys;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Change the user''s password if the user connects using password authentication.';
                    Visible = not IsSaaS;

                    trigger OnAction()
                    begin
                        EditNavPassword;
                    end;
                }
                action(UpdateUserFromAzureGraph)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Update user from Office 365';
                    ToolTip = 'Update user''s name, authentication email address, and contact email address from Office 365';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Use the ''Update users from Office'' action on the ''Users'' page instead.';
                    Visible = IsSaaS;
                    ObsoleteTag = '16.0';

                    trigger OnAction()
                    var
                        AzureADUserManagement: Codeunit "Azure AD User Management";
                    begin
                        AzureADUserManagement.UpdateUserFromGraph(Rec);
                        Message(InfoUpToDateMsg);
                    end;
                }
                action(ChangeWebServiceAccessKey)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Change &Web Service Key';
                    Enabled = AllowChangeWebServiceAccessKey;
                    Image = ServiceCode;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Set up the key that web services use to access your data, and then specify the key on the user card for the relevant user accounts.';

                    trigger OnAction()
                    begin
                        EditWebServiceID;
                    end;
                }
                action(DeleteExchangeIdentifier)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Delete Exchange Identifier Mapping';
                    Enabled = HasExchangeIdentifier;
                    Image = DeleteXML;
                    ToolTip = 'Delete the document exchange mapping for the current user.';

                    trigger OnAction()
                    begin
                        if not Confirm(ConfirmRemoveExchangeIdentifierQst) then
                            exit;

                        Clear("Exchange Identifier");
                        Modify(true);
                        HasExchangeIdentifier := false;
                    end;
                }
            }
            group(Action39)
            {
                Caption = 'Permissions';
                action("Effective Permissions")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Effective Permissions';
                    Image = Permission;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'View this user''s actual permissions for all objects per assigned permission set, and edit the user''s permissions in permission sets of type User-Defined.';

                    trigger OnAction()
                    var
                        EffectivePermissionsMgt: Codeunit "Effective Permissions Mgt.";
                    begin
                        EffectivePermissionsMgt.OpenPageForUser("User Security ID");
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        WindowsUserName := IdentityManagement.UserName("Windows Security ID");

        TestField("User Name");

        if IdentityManagement.IsUserPasswordSet("User Security ID") then
            Password := '********';
        ACSStatus := IdentityManagement.GetACSStatus("User Security ID");
        WebServiceExpiryDate := IdentityManagement.GetWebServiceExpiryDate("User Security ID");
        AuthenticationStatus := IdentityManagement.GetAuthenticationStatus("User Security ID");
        HasExchangeIdentifier := "Exchange Identifier" <> '';
        InitialState := State;

        if not IsNullGuid("Application ID") then
            ApplicationID := "Application ID";

        if IsSaaS and (UserId <> "User Name") then begin
            AllowChangeWebServiceAccessKey := false;
            WebServiceID := '*************************************';
        end else begin
            AllowChangeWebServiceAccessKey := true;
            WebServiceID := IdentityManagement.GetWebServicesKey("User Security ID");
        end;
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        if not ManageUsersIsAllowed then
            Error('');
    end;

    trigger OnInit()
    begin
        DeployedToAzure := IdentityManagement.IsAzure;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        "User Security ID" := CreateGuid;
        TestField("User Name");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if not ManageUsersIsAllowed then
            Error('');
        WindowsUserName := '';
        Password := '';
        "Change Password" := false;
        WebServiceID := '';
        Clear(WebServiceExpiryDate);
    end;

    trigger OnOpenPage()
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        IsSaaS := EnvironmentInfo.IsSaaS;

        HideExternalUsers;

        OnPremAskFirstUserToCreateSuper;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if "User Name" <> '' then
            exit(ValidateAuthentication);
    end;

    var
        UserSecID: Record User;
        IdentityManagement: Codeunit "Identity Management";
        ClientTypeManagement: Codeunit "Client Type Management";
        WindowsUserName: Text[208];
        Text001Err: Label 'The account %1 is not a valid Windows account.', Comment = 'USERID';
        Text002Err: Label 'The account %1 already exists.', Comment = 'USERID';
        Text003Err: Label 'The account %1 is not allowed.', Comment = 'USERID';
        Password: Text[80];
        ACSStatus: Option Disabled,Pending,Registered,Unknown;
        WebServiceID: Text[80];
        Confirm001Qst: Label 'The current Web Service Access Key will not be valid after editing. All clients that use it have to be updated. Do you want to continue?';
        WebServiceExpiryDate: DateTime;
        Confirm002Qst: Label 'You have not completed all necessary fields for the Credential Type that this client is currently using. The user will not be able to log in unless you provide a value in the %1 field. Are you sure that you want to close the window?', Comment = 'USERID';
        [InDataSet]
        DeployedToAzure: Boolean;
        Confirm003Qst: Label 'The user will not be able to sign in unless you change the state to Enabled. Are you sure that you want to close the page?';
        HasExchangeIdentifier: Boolean;
        AuthenticationStatus: Option Disabled,Inactive,Active;
        Confirm004Qst: Label 'The user will not be able to sign in because no authentication data was provided. Are you sure that you want to close the page?';
        ConfirmRemoveExchangeIdentifierQst: Label 'If you delete the Exchange Identifier Mapping, the user will no longer automatically be signed in when they use Exchange applications.\Do you want to continue?';
        IsSaaS: Boolean;
        ApplicationID: Text;
        CannotManageUsersQst: Label 'You cannot add or delete users on this page. Administrators can manage users in the Office 365 admin center.\\Do you want to go there now?';
        AllowChangeWebServiceAccessKey: Boolean;
        InitialState: Option;
        CreateFirstUserQst: Label 'You will be locked out after creating first user. Would you first like to create a SUPER user for %1?', Comment = 'USERID';
        InfoUpToDateMsg: Label 'The information about this user is up to date.';

    local procedure ValidateSid()
    var
        User: Record User;
    begin
        if "Windows Security ID" = '' then
            Error(Text001Err, "User Name");

        if ("Windows Security ID" = 'S-1-1-0') or ("Windows Security ID" = 'S-1-5-7') or ("Windows Security ID" = 'S-1-5-32-544') then
            Error(Text003Err, IdentityManagement.UserName("Windows Security ID"));

        User.SetFilter("Windows Security ID", "Windows Security ID");
        User.SetFilter("User Security ID", '<>%1', "User Security ID");
        if not User.IsEmpty then
            Error(Text002Err, User."User Name");
    end;

    local procedure ValidateAuthentication(): Boolean
    var
        ValidationField: Text;
    begin
        UserSecID.Reset();
        if (UserSecID.Count = 1) or (UserSecurityId = "User Security ID") then begin
            if IdentityManagement.IsWindowsAuthentication and ("Windows Security ID" = '') then
                ValidationField := 'Windows User Name';

            if IdentityManagement.IsUserNamePasswordAuthentication and (Password = '') then
                ValidationField := 'Password';

            if IdentityManagement.IsAccessControlServiceAuthentication and (ACSStatus = 0) and (AuthenticationStatus = 0) then
                ValidationField := 'ACSStatus / AuthenticationStatus';

            if ValidationField <> '' then
                exit(Confirm(Confirm002Qst, false, ValidationField));
        end else begin
            if ("Windows Security ID" = '') and (Password = '') and (ACSStatus = 0) and (AuthenticationStatus = 0) then
                exit(Confirm(Confirm004Qst, false));
        end;

        if (InitialState = State::Enabled) and (State = State::Disabled) then
            exit(Confirm(Confirm003Qst, false));

        exit(true);
    end;

    local procedure ValidateUserName()
    var
        UserMgt: Codeunit "User Management";
    begin
        UserMgt.ValidateUserName(Rec, xRec, WindowsUserName);
        CurrPage.Update;
    end;

    local procedure ValidateState()
    var
        UserManagement: Codeunit "User Management";
    begin
        UserManagement.ValidateState(Rec, xRec);
    end;

    local procedure EditWebServiceID()
    var
        SetWebServiceAccessKey: Page "Set Web Service Access Key";
    begin
        TestField("User Name");

        if Confirm(Confirm001Qst) then begin
            UserSecID.SetCurrentKey("User Security ID");
            UserSecID.SetRange("User Security ID", "User Security ID", "User Security ID");
            SetWebServiceAccessKey.SetRecord(UserSecID);
            SetWebServiceAccessKey.SetTableView(UserSecID);
            if SetWebServiceAccessKey.RunModal = Action::OK then
                CurrPage.Update;
        end;
    end;

    local procedure EditNavPassword()
    var
        PasswordDialogManagement: Codeunit "Password Dialog Management";
        Password: Text;
    begin
        TestField("User Name");

        CurrPage.SaveRecord;
        Commit();

        Password := PasswordDialogManagement.OpenPasswordDialog();

        if Password = '' then
            exit;

        SetUserPassword("User Security ID", Password);
        CurrPage.Update(false);
    end;

    local procedure EditACSStatus()
    var
        UserACSSetup: Page "User ACS Setup";
    begin
        TestField("User Name");

        UserSecID.SetCurrentKey("User Security ID");
        UserSecID.SetRange("User Security ID", "User Security ID", "User Security ID");
        UserACSSetup.SetRecord(UserSecID);
        UserACSSetup.SetTableView(UserSecID);
        if UserACSSetup.RunModal = Action::OK then
            CurrPage.Update;
    end;

    procedure ManageUsersIsAllowed(): Boolean
    var
        UrlHelper: Codeunit "Url Helper";
    begin
        if not IsSaaS then
            exit(true);

        if Confirm(CannotManageUsersQst, true) then
            HyperLink(UrlHelper.GetOfficePortalUrl);

        exit(false);
    end;

    local procedure SetUserName()
    begin
        "User Name" := WindowsUserName;
        ValidateUserName;
    end;

    local procedure HideExternalUsers()
    var
        OriginalFilterGroup: Integer;
    begin
        if not IsSaaS then
            exit;

        OriginalFilterGroup := FilterGroup;
        FilterGroup := 2;
        SetFilter("License Type", '<>%1', "License Type"::"External User");
        FilterGroup := OriginalFilterGroup;
    end;

    local procedure ValidateWindowsUserName()
    var
        UserSID: Text;
    begin
        if WindowsUserName = '' then
            "Windows Security ID" := ''
        else begin
            UserSID := Sid(WindowsUserName);
            WindowsUserName := IdentityManagement.UserName(UserSID);
            if WindowsUserName <> '' then begin
                "Windows Security ID" := UserSID;
                ValidateSid;
                SetUserName;
            end else
                Error(Text001Err, WindowsUserName);
        end;
    end;

    local procedure OnPremAskFirstUserToCreateSuper()
    var
        User: Record User;
    begin
        if IsSaaS then
            exit;

        // Users already exist
        if not User.IsEmpty then
            exit;

        if Confirm(CreateFirstUserQst, true, UserId) then
            Codeunit.Run(Codeunit::"Users - Create Super User");
    end;
}

