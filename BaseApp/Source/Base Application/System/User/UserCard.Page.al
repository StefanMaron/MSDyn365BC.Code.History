﻿namespace System.Security.User;

using System;
using System.Azure.Identity;
using System.Email;
using System.Environment;
#if not CLEAN23
using System.Environment.Configuration;
#endif
using System.Security.AccessControl;
using System.Utilities;

page 9807 "User Card"
{
    Caption = 'User Card';
    DataCaptionExpression = Rec."Full Name";
    DelayedInsert = true;
    PageType = Card;
    SourceTable = User;
    Permissions = tabledata "User Property" = m;
    AboutTitle = 'About user account details';
    AboutText = 'Here, you manage an individual user''s account information. You choose the permissions that a user has by assigning permission sets. You can view the user''s license information, but you cannot change it.';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("User Security ID"; Rec."User Security ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'User Security ID';
                    ToolTip = 'Specifies an ID that uniquely identifies the user. This value is generated automatically and should not be changed.';
                    Visible = false;
                }
                field("User Name"; Rec."User Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'User Name';
                    Importance = Promoted;
                    ToolTip = 'Specifies the user''s name. If the user is required to present credentials when starting the client, this is the name that the user must present.';

                    trigger OnValidate()
                    begin
                        if xRec."User Name" <> Rec."User Name" then
                            ValidateUserName();
                    end;
                }
                field("Full Name"; Rec."Full Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Full Name';
                    Editable = not IsSaaS;
                    ToolTip = 'Specifies the full name of the user.';
                }
                field("License Type"; Rec."License Type")
                {
                    ApplicationArea = All;
                    Caption = 'License Type';
                    ToolTip = 'Specifies the type of license that applies to the user.';
                    Visible = not IsSaaS;

                    trigger OnValidate()
                    begin
                        if Rec."License Type" = Rec."License Type"::"Windows Group" then
                            Error(CannotCreateWindowsGroupErr);

                        if Rec."License Type" = Rec."License Type"::"AAD Group" then
                            Error(CannotCreateAadGroupErr);
                    end;
                }
                field(State; Rec.State)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Status';
                    OptionCaption = 'Active, Inactive';
                    Importance = Promoted;
                    ToolTip = 'Specifies whether the user can access companies in the current environment. This field does not reflect any changes in Microsoft 365 Accounts.';
                    AboutTitle = 'Control the user''s access';
                    AboutText = 'You can temporarily prevent a user from signing in by disabling their user account. This does not remove the license from the user.';

                    trigger OnValidate()
                    begin
                        ValidateState();
                    end;
                }
                field("Expiry Date"; Rec."Expiry Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Expiry Date';
                    ToolTip = 'Specifies a date past which the user will no longer be authorized to log on to the Windows client.';
                    Visible = not IsSaaS;
                }
                field("Contact Email"; Rec."Contact Email")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Contact Email';
                    ToolTip = 'Specifies the user''s email address.';
                }
                field("User Telemetry ID"; TelemetryUserID)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Telemetry ID';
                    ToolTip = 'Specifies a telemetry ID which can be used for troubleshooting purposes.';
                    Editable = false;
                    Importance = Additional;
                    AssistEdit = true;

                    trigger OnAssistEdit()
                    begin
                        EditUserTelemetryId();
                    end;
                }
                group("Office 365 Authentication")
                {
                    Caption = 'Microsoft 365', Comment = '{Locked="Microsoft 365"}';

                    field("Authentication Email"; Rec."Authentication Email")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Authentication Email';
                        Importance = Promoted;
                        Editable = not IsSaaS;
                        AboutTitle = 'Microsoft 365 accounts';
                        AboutText = 'For Microsoft 365 accounts, go to the Microsoft 365 Admin center when you want to manage settings.';
                        ToolTip = 'Specifies the account that this user signs into Microsoft 365 or SharePoint with.';

                        trigger OnValidate()
                        begin
                            IdentityManagement.SetAuthenticationEmail(Rec."User Security ID", Rec."Authentication Email");
                            CurrPage.SaveRecord();
                            AuthenticationStatus := IdentityManagement.GetAuthenticationStatus(Rec."User Security ID");
                        end;
                    }
                    field(ApplicationID; ApplicationID)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Application ID';
                        ToolTip = 'Specifies the client ID of the Microsoft Microsoft Entra application when authenticating web-service calls. This field is only relevant when the Business Central user is used for web services.';
                        Visible = not IsSaaS;

                        trigger OnValidate()
                        var
                            ZeroGUID: Guid;
                        begin
                            if ApplicationID = '' then
                                Rec.Validate("Application ID", ZeroGUID)
                            else
                                Rec.Validate("Application ID", ApplicationID);
                        end;
                    }
                    field(MappedToExchangeIdentifier; HasExchangeIdentifier)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Mapped To Exchange Identifier';
                        Editable = false;
                        Importance = Additional;
                        ToolTip = 'Specifies whether the user is mapped to a Microsoft Exchange identifier, which enables the user to access Business Central from Exchange applications (such as Outlook) without having to sign-in.';
                    }
                    field(AuthenticationStatus; AuthenticationStatus)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Authentication Status';
                        Editable = false;
                        ToolTip = 'Specifies the user''s status for Microsoft 365 authentication. When you start to create a user, the status is Disabled. After you specify an authentication email address for the user, the status changes to Inactive. After the user logs on successfully, the status changes to Active.';
                    }
                    field(Microsoft365State; Microsoft365State)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Microsoft 365 User Account state';
                        OptionCaption = 'Inactive, Active';
                        Importance = Additional;
                        ToolTip = 'Specifies whether the user''s Microsoft 365 Account is enabled.';
                        Editable = false;
                    }
                }
                group("Web Service Access")
                {
                    Caption = 'Web Service';
                    Visible = IsWebServiceAccesskeyAllowed;
                    field(WebServiceID; WebServiceID)
                    {
                        ApplicationArea = Basic, Suite;
                        AssistEdit = true;
                        Caption = 'Web Service Access Key';
                        Editable = false;
                        ToolTip = 'Specifies a generated key that Dynamics 365 web service applications can use to authenticate to Dynamics 365 services. Choose the AssistEdit button to generate a key.';

                        trigger OnAssistEdit()
                        begin
                            if not AllowCreateWebServiceAccessKey then
                                Error(CannotCreateWebServiceAccessKeyErr);

                            EditWebServiceID();
                        end;
                    }
                    field(WebServiceExpiryDate; WebServiceExpiryDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Web Service Expiry Date';
                        Editable = false;
                        Importance = Additional;
                        ToolTip = 'Specifies an expiration date for the web services access key.';
                    }
                }
            }
            group("Windows Authentication")
            {
                Caption = 'Windows Authentication';
                Visible = (not DeployedToAzure) and (not IsSaaS);
                field("Windows Security ID"; Rec."Windows Security ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Windows Security ID';
                    ToolTip = 'Specifies the Windows Security ID of the user. This is only relevant for Windows authentication.';
                    Visible = false;
                    Editable = not IsSaas;
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
                        ValidateWindowsUserName();
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
                        EditACSStatus();
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
                        EditNavPassword();
                    end;
                }
                field("Change Password"; Rec."Change Password")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'User must change password at next login';
                    ToolTip = 'Specifies if the user will be prompted to change the password at next login.';
                }
            }
#if not CLEAN22
            part(UserGroups; "User Groups User SubPage")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'User Group Memberships';
                SubPageLink = "User Security ID" = field("User Security ID");
                UpdatePropagation = Both;
                AboutTitle = 'Assigning group memberships';
                AboutText = 'You add or remove memberships by updating the lines here. The user inherits permission sets from all the assigned user groups. Note: User groups will be replaced by security groups and composable permission sets in a future release.';
                Visible = LegacyUserGroupsVisible;
                ObsoleteState = Pending;
                ObsoleteReason = 'Replaced by the User Security Groups part.';
                ObsoleteTag = '22.0';
            }
#endif
            part(Permissions; "User Subform")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'User Permission Sets';
                SubPageLink = "User Security ID" = field("User Security ID");
                AboutTitle = 'Assigning permissions';
                AboutText = 'You add or remove permissions by updating the lines here. If you leave the **Company** field blank on a line, the assignment applies to all companies.';
            }
            part(Plans; "User Plans FactBox")
            {
                Caption = 'Licenses';
                ApplicationArea = Basic, Suite;
                SubPageLink = "User Security ID" = field("User Security ID");
                Visible = IsSaaS;
            }
        }
        area(factboxes)
        {
            part("Inherited Permission Sets"; "Inherited Permission Sets Part")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "User Security ID" = field("User Security ID");
                AboutTitle = 'Viewing security group permissions';
                AboutText = 'You can see permissions sets coming from security group memberships here.';
            }
            part("User Security Groups"; "User Security Groups Part")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Security Group Memberships';
                SubPageLink = "User Security ID" = field("User Security ID");
                AboutTitle = 'View security group memberships';
                AboutText = 'The user inherits permission sets from all the assigned security groups.';
            }
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
                    ToolTip = 'Set up Access Control Service authentication, such as generating an authentication key that the user can use to connect to Azure.';
                    Visible = not IsSaaS;

                    trigger OnAction()
                    begin
                        EditACSStatus();
                    end;
                }
                action(ChangePassword)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Change &Password';
                    Image = EncryptionKeys;
                    ToolTip = 'Change the user''s password if the user connects using password authentication.';
                    Visible = not IsSaaS;

                    trigger OnAction()
                    begin
                        EditNavPassword();
                    end;
                }
                action(ChangeWebServiceAccessKey)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Change &Web Service Key';
                    Enabled = AllowChangeWebServiceAccessKey;
                    Image = ServiceCode;
                    ToolTip = 'Set up the key that web services use to access your data, and then specify the key on the user card for the relevant user accounts.';

                    trigger OnAction()
                    begin
                        EditWebServiceID();
                    end;
                }
                Action(RemoveWSAccessKey)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Clear Web Service Access Key';
                    Enabled = AllowChangeWebServiceAccessKey;
                    Image = ServiceCode;
                    ToolTip = 'By clearing the Web Service Access Key field on the User Card page, you can ensure that access keys cannot be used to authenticate from another service.';

                    trigger OnAction()
                    begin
                        if WebServiceID <> '' then
                            RemoveWebServiceAccessKey(Rec."User Security ID");
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

                        Clear(Rec."Exchange Identifier");
                        Rec.Modify(true);
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
                    ToolTip = 'View this user''s actual permissions for all objects per assigned permission set, and edit the user''s permissions in permission sets of type User-Defined.';

                    trigger OnAction()
                    var
                        EffectivePermissionsMgt: Codeunit "Effective Permissions Mgt.";
                    begin
                        EffectivePermissionsMgt.OpenPageForUser(Rec."User Security ID");
                    end;
                }
            }
            action(Email)
            {
                ApplicationArea = All;
                Caption = 'Send Email';
                Image = Email;
                ToolTip = 'Send an email to this user.';

                trigger OnAction()
                var
                    TempEmailItem: Record "Email Item" temporary;
                    EmailScenario: Enum "Email Scenario";
                begin
                    TempEmailItem.AddSourceDocument(Database::User, Rec.SystemId);
                    TempEmailitem."Send to" := Rec."Contact Email";
                    TempEmailItem.Send(false, EmailScenario::Default);
                end;
            }
        }
        area(navigation)
        {
            group(History)
            {
                Caption = 'History';
                Image = History;
                action("Sent Emails")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sent Emails';
                    Image = ShowList;
                    ToolTip = 'View a list of emails that you have sent to this user.';

                    trigger OnAction()
                    var
                        Email: Codeunit Email;
                    begin
                        Email.OpenSentEmails(Database::User, Rec.SystemId);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("Effective Permissions_Promoted"; "Effective Permissions")
                {
                }
                actionref(AcsSetup_Promoted; AcsSetup)
                {
                }
                actionref(ChangePassword_Promoted; ChangePassword)
                {
                }
                actionref(Email_Promoted; Email)
                {
                }
                actionref("Sent Emails_Promoted"; "Sent Emails")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        UserProperty: Record "User Property";
        UserPermissions: Codeunit "User Permissions";
        EnvironmentInformation: Codeunit "Environment Information";
        AzureADGraph: Codeunit "Azure AD Graph";
        IsGraphUserAccountEnabled: Boolean;
    begin
        WindowsUserName := IdentityManagement.UserName(Rec."Windows Security ID");

        Rec.TestField("User Name");

        if IdentityManagement.IsUserPasswordSet(Rec."User Security ID") then
            Password := '********';
        ACSStatus := IdentityManagement.GetACSStatus(Rec."User Security ID");
        WebServiceExpiryDate := IdentityManagement.GetWebServiceExpiryDate(Rec."User Security ID");
        AuthenticationStatus := IdentityManagement.GetAuthenticationStatus(Rec."User Security ID");
        HasExchangeIdentifier := Rec."Exchange Identifier" <> '';
        InitialState := Rec.State;

        if not IsNullGuid(Rec."Application ID") then
            ApplicationID := Rec."Application ID";

        if UserSecurityId() <> Rec."User Security ID" then
            WebServiceID := '*************************************'
        else begin
            WebServiceID := IdentityManagement.GetWebServicesKey(Rec."User Security ID");
            Session.LogSecurityAudit(ReadWebServiceKeyTxt, SecurityOperationResult::Success, StrSubstNo(ReadWebServiceKeyForUserTxt, Rec."User Name"), AuditCategory::KeyManagement);
        end;
        if IsWebServiceAccesskeyAllowed then begin
            AllowChangeWebServiceAccessKey := (UserSecurityId() = Rec."User Security ID") or UserPermissions.CanManageUsersOnTenant(UserSecurityId());
            AllowCreateWebServiceAccessKey := (not EnvironmentInformation.IsSaaS()) or (not IsUserDelegated(Rec."User Security ID"));
        end else begin
            AllowChangeWebServiceAccessKey := false;
            AllowCreateWebServiceAccessKey := false;
        end;
        if UserProperty.Get(Rec."User Security ID") then
            TelemetryUserID := UserProperty."Telemetry User ID"
        else
            Clear(TelemetryUserID);

        Microsoft365State := Microsoft365State::Inactive;
        if Rec."Authentication Email" <> '' then
            if AzureADGraph.IsGraphUserAccountEnabled(Rec."Authentication Email", IsGraphUserAccountEnabled) and IsGraphUserAccountEnabled then
                Microsoft365State := Microsoft365State::Active
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        if DeleteUserIsAllowed(Rec) then
            exit(true);
        if not ManageUsersIsAllowed() then
            Error(DeleteUserInSaaSErr);
    end;

    trigger OnInit()
    begin
        DeployedToAzure := IdentityManagement.IsAzure();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Rec."User Security ID" := CreateGuid();
        Rec.TestField("User Name");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if not ManageUsersIsAllowed() then
            Error(CreateUserInSaaSErr);

        WindowsUserName := '';
        Password := '';
        Rec."Change Password" := false;
        WebServiceID := '';
        Clear(WebServiceExpiryDate);
        Clear(TelemetryUserID);
    end;

    trigger OnOpenPage()
    var
#if not CLEAN23
        MyNotification: Record "My Notifications";
#endif
        SecurityGroupMemberBuffer: Record "Security Group Member Buffer";
        EnvironmentInfo: Codeunit "Environment Information";
#if not CLEAN23
        UserManagement: Codeunit "User Management";
#endif        
#if not CLEAN22
        LegacyUserGroups: Codeunit "Legacy User Groups";
#endif
    begin
#if not CLEAN22
        LegacyUserGroupsVisible := LegacyUserGroups.UiElementsVisible();
#endif
        IsSaaS := EnvironmentInfo.IsSaaS();
        if not IsSaaS then
            IsWebServiceAccesskeyAllowed := true
        else
            IsWebServiceAccesskeyAllowed := SetWebServiceAccressKey();

        HideExternalUsers();

        OnPremAskFirstUserToCreateSuper();

        // Set "User Security Groups" to refresh as part of "Inherited Permission Sets" refresh (to avoid fetching security group memberships twice).
        CurrPage."User Security Groups".Page.GetSourceRecord(SecurityGroupMemberBuffer);
        CurrPage."Inherited Permission Sets".Page.SetRecordToRefresh(SecurityGroupMemberBuffer);
#if not CLEAN23
        Usermanagement.BasicAuthDepricationNotificationDefault(false);
        if MyNotification.IsEnabled(UserManagement.BasicAuthDepricationNotificationId()) then
            UserManagement.BasicAuthDepricationNotificationShow(BasicAuthDepricationNotification);
#endif
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if Rec."User Name" <> '' then
            exit(ValidateAuthentication());
    end;

    var
        UserSecID: Record User;
        IdentityManagement: Codeunit "Identity Management";
#if not CLEAN23
        BasicAuthDepricationNotification: Notification;
#endif
        WindowsUserName: Text[208];
        Text001Err: Label 'The account %1 is not a valid Windows account.', Comment = 'USERID';
        Text002Err: Label 'The account %1 already exists.', Comment = 'USERID';
        Text003Err: Label 'The account %1 is not allowed.', Comment = 'USERID';
        CreateUserInSaaSErr: Label 'Creating users is not allowed in the online environment.';
        DeleteUserInSaaSErr: Label 'Deleting users is not allowed in the online environment.';
        Password: Text[80];
        ACSStatus: Option Disabled,Pending,Registered,Unknown;
        WebServiceID: Text[80];
        TelemetryUserID: Guid;
        Confirm001Qst: Label 'The current Web Service Access Key will not be valid after editing. All clients that use it have to be updated. Do you want to continue?';
        WebServiceExpiryDate: DateTime;
        Confirm002Qst: Label 'You have not completed all necessary fields for the Credential Type that this client is currently using. The user will not be able to log in unless you provide a value in the %1 field. Are you sure that you want to close the window?', Comment = 'USERID';
        DeployedToAzure: Boolean;
        Confirm003Qst: Label 'The user will not be able to sign in unless you change the state to Enabled. Are you sure that you want to close the page?';
        HasExchangeIdentifier: Boolean;
        AuthenticationStatus: Option Disabled,Inactive,Active;
        Microsoft365State: Option Inactive,Active;
        Confirm004Qst: Label 'The user will not be able to sign in because no authentication data was provided. Are you sure that you want to close the page?';
        ConfirmRemoveExchangeIdentifierQst: Label 'If you delete the Exchange Identifier Mapping, the user will no longer automatically be signed in when they use Exchange applications.\Do you want to continue?';
        IsSaaS: Boolean;
        IsWebServiceAccesskeyAllowed: Boolean;
        ApplicationID: Text;
        CannotManageUsersQst: Label 'You cannot add or delete users on this page. Administrators can manage users in the Microsoft 365 admin center.\\Do you want to go there now?';
        AllowChangeWebServiceAccessKey: Boolean;
        AllowCreateWebServiceAccessKey: Boolean;
        InitialState: Option;
        CannotCreateWindowsGroupErr: Label 'User accounts of type ''Windows Group'' can only be created by creating a security group.';
        CannotCreateAadGroupErr: Label 'User accounts of type ''Microsoft Entra group'' are only available in SaaS.';
        CreateFirstUserQst: Label 'You will be locked out after creating first user. Would you first like to create a SUPER user for %1?', Comment = 'USERID';
        CannotEditForOtherUsersErr: Label 'You can only change your own web service access keys.';
        CannotCreateWebServiceAccessKeyErr: Label 'You cannot create a web service access key for this user because they have delegated administration privileges.';
        ReadWebServiceKeyTxt: Label 'Read web service key', Locked = true;
        ReadWebServiceKeyForUserTxt: Label 'Read web service key for user %1', Locked = true;
        NewWebSeriveKeyTxt: label 'New web service key', Locked = true;
        NewWebSeriveKeyForUserTxt: Label 'New web service key was created for user %1', Locked = true;
#if not CLEAN22
        LegacyUserGroupsVisible: Boolean;
#endif

    local procedure ValidateSid()
    var
        User: Record User;
    begin
        if Rec."Windows Security ID" = '' then
            Error(Text001Err, Rec."User Name");

        if (Rec."Windows Security ID" = 'S-1-1-0') or (Rec."Windows Security ID" = 'S-1-5-7') or (Rec."Windows Security ID" = 'S-1-5-32-544') then
            Error(Text003Err, IdentityManagement.UserName(Rec."Windows Security ID"));

        User.SetFilter("Windows Security ID", Rec."Windows Security ID");
        User.SetFilter("User Security ID", '<>%1', Rec."User Security ID");
        if not User.IsEmpty() then
            Error(Text002Err, User."User Name");
    end;

    procedure RemoveWebServiceAccessKey(UserSecurityId: Guid): Boolean
    var
        UserProperty: Record "User Property";
    begin
        if UserProperty.Get(UserSecurityId) then begin
            UserProperty."WebServices Key" := '';
            UserProperty."WebServices Key Expiry Date" := CreateDateTime(20220901D, 020000T);
            UserProperty.Modify();
            exit(true);
        end;
        exit(false);
    end;

    local procedure ValidateAuthentication(): Boolean
    var
        ValidationField: Text;
        ShowConfirmDisableUser: Boolean;
    begin
        UserSecID.Reset();
        if (UserSecID.Count = 1) or (UserSecurityId() = Rec."User Security ID") then begin
            if IdentityManagement.IsWindowsAuthentication() and (Rec."Windows Security ID" = '') then
                ValidationField := 'Windows User Name';

            if IdentityManagement.IsUserNamePasswordAuthentication() and (Password = '') then
                ValidationField := 'Password';

            if IdentityManagement.IsAccessControlServiceAuthentication() and (ACSStatus = 0) and (AuthenticationStatus = 0) then
                ValidationField := 'ACSStatus / AuthenticationStatus';

            if ValidationField <> '' then
                exit(Confirm(Confirm002Qst, false, ValidationField));
        end else
            if (Rec."Windows Security ID" = '') and (Password = '') and (ACSStatus = 0) and (AuthenticationStatus = 0) then
                exit(Confirm(Confirm004Qst, false));

        ShowConfirmDisableUser := (InitialState = Rec.State::Enabled) and (Rec.State = Rec.State::Disabled);
        OnValidateAuthenticationOnAfterCalcShowConfirmDisableUser(InitialState, Rec, ShowConfirmDisableUser);
        if ShowConfirmDisableUser then
            exit(Confirm(Confirm003Qst, false));

        exit(true);
    end;

    local procedure ValidateUserName()
    var
        UserMgt: Codeunit "User Management";
    begin
        UserMgt.ValidateUserName(Rec, xRec, WindowsUserName);
        CurrPage.Update();
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
        Rec.TestField("User Name");

        if not AllowChangeWebServiceAccessKey then
            Error(CannotEditForOtherUsersErr);

        if Confirm(Confirm001Qst) then begin
            UserSecID.SetCurrentKey("User Security ID");
            UserSecID.SetRange("User Security ID", Rec."User Security ID");
            UserSecID.FindFirst();

            SetWebServiceAccessKey.SetRecord(UserSecID);
            SetWebServiceAccessKey.SetTableView(UserSecID);

            if SetWebServiceAccessKey.RunModal() = Action::OK then begin
                CurrPage.Update();
                Session.LogSecurityAudit(NewWebSeriveKeyTxt, SecurityOperationResult::Success, StrSubstNo(NewWebSeriveKeyForUserTxt, Rec."User Name"), AuditCategory::KeyManagement);
            end;
        end;
    end;

    local procedure EditNavPassword()
    var
        PasswordDialogManagement: Codeunit "Password Dialog Management";
        Password: Text;
    begin
        Rec.TestField("User Name");

        CurrPage.SaveRecord();
        Commit();

        Password := PasswordDialogManagement.OpenPasswordDialog();

        if Password = '' then
            exit;

        SetUserPassword(Rec."User Security ID", Password);
        CurrPage.Update(false);
    end;

    local procedure EditACSStatus()
    var
        UserACSSetup: Page "User ACS Setup";
    begin
        Rec.TestField("User Name");

        UserSecID.SetCurrentKey("User Security ID");
        UserSecID.SetRange("User Security ID", Rec."User Security ID", Rec."User Security ID");
        UserACSSetup.SetRecord(UserSecID);
        UserACSSetup.SetTableView(UserSecID);
        if UserACSSetup.RunModal() = Action::OK then
            CurrPage.Update();
    end;

    local procedure SetUserTelemetryId(newGuid: guid)
    var
        UserProperty: Record "User Property";
    begin
        UserProperty.Get(Rec."User Security ID");
        UserProperty."Telemetry User ID" := newGuid;
        UserProperty.Modify();
        CurrPage.Update();
    end;

    local procedure EditUserTelemetryId()
    var
        ZeroGUID: Guid;
        MenuTextMsg: Label 'Set field to null GUID, Set field to random GUID';
        SelectionTextMsg: Label 'Choose one of the following options:';
    begin
        case StrMenu(MenuTextMsg, 2, SelectionTextMsg) of
            1:
                SetUserTelemetryId(ZeroGUID);
            2:
                SetUserTelemetryId(CreateGUID());
        end;
    end;

    procedure DeleteUserIsAllowed(User: Record User): Boolean
    var
        UserLoginTimeTracker: Codeunit "User Login Time Tracker";
    begin
        // check if the user ever has logged in. If the user hasn't, it's ok to delete the user.
        exit(not UserLoginTimeTracker.UserLoggedInEnvironment(user."User Security ID"));
    end;

    procedure ManageUsersIsAllowed(): Boolean
    var
        UrlHelper: Codeunit "Url Helper";
    begin
        if not IsSaaS then
            exit(true);

        if Confirm(CannotManageUsersQst, true) then
            HyperLink(UrlHelper.GetOfficePortalUrl());

        exit(false);
    end;

    local procedure SetUserName()
    begin
        Rec."User Name" := WindowsUserName;
        ValidateUserName();
    end;

    local procedure HideExternalUsers()
    var
        OriginalFilterGroup: Integer;
    begin
        if not IsSaaS then
            exit;

        OriginalFilterGroup := Rec.FilterGroup;
        Rec.FilterGroup := 2;
        Rec.SetFilter("License Type", '<>%1&<>%2&<>%3', Rec."License Type"::"External User", Rec."License Type"::Application, Rec."License Type"::"AAD Group");
        Rec.FilterGroup := OriginalFilterGroup;
    end;

    local procedure ValidateWindowsUserName()
    var
        UserSID: Text;
    begin
        if WindowsUserName = '' then
            Rec."Windows Security ID" := ''
        else begin
            UserSID := Sid(WindowsUserName);
            WindowsUserName := IdentityManagement.UserName(UserSID);
            if WindowsUserName <> '' then begin
                Rec."Windows Security ID" := UserSID;
                ValidateSid();
                SetUserName();
                CurrPage."Inherited Permission Sets".Page.Refresh(); // "User Security Groups" part is updated as part of this refresh as well
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
        if not User.IsEmpty() then
            exit;

        if Confirm(CreateFirstUserQst, true, UserId) then
            Codeunit.Run(Codeunit::"Users - Create Super User");
    end;

    procedure SetWebServiceAccressKey(): Boolean;
    var
        NavTenantSettingsHelper: DotNet NavTenantSettingsHelper;
    begin
        exit(NavTenantSettingsHelper.IsWSKeyAllowed())
    end;

    [NonDebuggable]
    local procedure IsUserDelegated(UserSecID: Guid): Boolean
    var
        PlanIds: Codeunit "Plan Ids";
        AzureADPlan: Codeunit "Azure AD Plan";
    begin
        exit(AzureADPlan.IsPlanAssignedToUser(PlanIds.GetDelegatedAdminPlanId(), UserSecID) or
                    AzureADPlan.IsPlanAssignedToUser(PlanIds.GetHelpDeskPlanId(), UserSecID));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateAuthenticationOnAfterCalcShowConfirmDisableUser(InitialState: Option; User: Record User; var ShowConfirmDisableUser: Boolean)
    begin
    end;
}

