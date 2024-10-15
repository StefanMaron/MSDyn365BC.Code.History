namespace System.Security.User;

using Microsoft.AccountantPortal;
using Microsoft.CRM.Team;
using Microsoft.FixedAssets.Journal;
using Microsoft.Foundation.Task;
using Microsoft.HumanResources.Employee;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Warehouse.Setup;
#if not CLEAN23
using System;
#endif
using System.Azure.Identity;
using System.Device;
using System.Email;
using System.Environment;
using System.Environment.Configuration;
using System.Security.AccessControl;

page 9800 Users
{
    AdditionalSearchTerms = 'permission,office 365 admin center,microsoft 365 admin center';
    ApplicationArea = Basic, Suite;
    Caption = 'Users';
    CardPageID = "User Card";
    DelayedInsert = true;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = User;
    SourceTableView = sorting("User Name");
    UsageCategory = Administration;
    Editable = false;

    AboutTitle = 'About user accounts';
    AboutText = 'Here, you manage who has access, and who can do what. Assign specific permissions to individual users, and organize users in security groups with group-level permissions.';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("User Security ID"; Rec."User Security ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an ID that uniquely identifies the user. This value is generated automatically and should not be changed.';
                    Visible = false;
                }
                field("User Name"; Rec."User Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'User Name';
                    ToolTip = 'Specifies the user''s name. If the user is required to present credentials when starting the client, this is the name that the user must present.';

                    trigger OnValidate()
                    begin
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
                field(State; Rec.State)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Status';
                    ToolTip = 'Specifies whether the user can access companies in the current environment.';
                }
                field("Windows Security ID"; Rec."Windows Security ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Windows Security ID of the user. This is only relevant for Windows authentication.';
                    Visible = false;
                    Editable = not IsSaas;
                }
                field("Windows User Name"; WindowsUserName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Windows User Name';
                    ToolTip = 'Specifies the user''s name on Windows.';
                    Visible = not IsSaaS;

                    trigger OnValidate()
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
                            end else
                                Error(Text001Err, WindowsUserName);
                        end;
                    end;
                }
                field("License Type"; Rec."License Type")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'License Type';
                    Visible = not IsSaaS;
                    ToolTip = 'Specifies the type of license that applies to the user. For more information, see License Types.';
                }
                field("Authentication Email"; Rec."Authentication Email")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the Microsoft account that this user signs into Microsoft 365 or SharePoint Online with.';
                    Visible = IsSaaS;
                }
                field("User Telemetry ID"; TelemetryUserId)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Telemetry ID';
                    ToolTip = 'Specifies a telemetry ID which can be used for troubleshooting purposes.';
                    Editable = false;
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            part(Control18; "Permission Sets FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "User Security ID" = field("User Security ID");
                Visible = CanManageUsersOnTenant or IsOwnUser;
            }
            part("Inherited Permission Sets"; "Inherited Permission Sets Part")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "User Security ID" = field("User Security ID");
                Visible = CanManageUsersOnTenant or IsOwnUser;
            }
            part("User Security Groups"; "User Security Groups Part")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Security Group Memberships';
                SubPageLink = "User Security ID" = field("User Security ID");
                Visible = CanManageUsersOnTenant or IsOwnUser;
            }
            part(Plans; "User Plans FactBox")
            {
                Caption = 'Licenses';
                ApplicationArea = Basic, Suite;
                SubPageLink = "User Security ID" = field("User Security ID");
                Visible = IsSaaS and (CanManageUsersOnTenant or IsOwnUser);
            }
            part(Control20; "User Setup FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "User ID" = field("User Name");
            }
            part(Control33; "User Settings FactBox")
            {
                ApplicationArea = All;
                SubPageLink = "User Security ID" = field("User Security ID");
            }
            part(Control32; "Printer Selections FactBox")
            {
                ApplicationArea = Basic, Suite;
                ShowFilter = false;
                SubPageLink = "User ID" = field("User Name");
            }
            part(Control28; "My Customers")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ShowFilter = false;
                SubPageLink = "User ID" = field("User Name");
                Visible = false;
            }
            part(Control29; "My Vendors")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ShowFilter = false;
                SubPageLink = "User ID" = field("User Name");
                Visible = false;
            }
            part(Control30; "My Items")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ShowFilter = false;
                SubPageLink = "User ID" = field("User Name");
                Visible = false;
            }
            systempart(Control11; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
            systempart(Control12; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("User Groups")
            {
                Caption = 'Groups';
                action("User Details")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'User Identifier Overview';
                    RunObject = page "User Details";
                    Image = Users;
                    ToolTip = 'View the list of users with additional details.';
                }
                action("Security Groups")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Security Groups';
                    Image = Users;
                    RunObject = Page "Security Groups";
                    ToolTip = 'Specify security groups as a fast way of giving users access to the functionality that is relevant to their work.';
                }
                action("User Task Groups")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'User Task Groups';
                    Image = Users;
                    RunObject = Page "User Task Groups";
                    ToolTip = 'Add or modify groups of users that you can assign user tasks to in this company.';
                }
            }
            group(Permissions)
            {
                Caption = 'Permissions';
                action("Effective Permissions")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Effective Permissions';
                    Image = Permission;
                    Scope = Repeater;
                    ToolTip = 'View this user''s actual permissions for all objects per assigned permission set, and edit the user''s permissions in permission sets of type User-Defined.';

                    trigger OnAction()
                    var
                        EffectivePermissionsMgt: Codeunit "Effective Permissions Mgt.";
                    begin
                        EffectivePermissionsMgt.OpenPageForUser(Rec."User Security ID");
                    end;
                }
                action("Permission Sets")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Permission Sets';
                    Image = Permission;
                    RunObject = Page "Permission Sets";
                    ToolTip = 'View or edit which feature objects that users need to access and set up the related permissions in permission sets that you can assign to the users of the database.';
                }
                action("Permission Set by User")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Permission Set by User';
                    Image = Permission;
                    RunObject = Page "Permission Set by User";
                    ToolTip = 'View or edit the available permission sets and apply permission sets to existing users.';
                }
                action("Permission Set By Security Group")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Permission Set by Security Group';
                    Image = Permission;
                    RunObject = Page "Permission Set By Sec. Group";
                    ToolTip = 'View or edit the available permission sets and apply permission sets to existing security groups.';
                }
            }
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
            action("User Email Policies")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'User Email Policies';
                Image = Email;
                RunObject = Page "Email View Policy List";
                ToolTip = 'View or edit user email policies for the users of the database.';
            }
            action("User Settings")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'User Settings';
                Image = UserInterface;
                Scope = Repeater;
                ToolTip = 'Manage the user interface settings for the users.';
                trigger OnAction()
                var
                    UserPersonalization: Record "User Personalization";
                    UserPersonalizationPage: Page "User Personalization";
                    UserSettingsList: Page "User Settings List";
                begin
                    if UserPersonalization.Get(Rec."User Security ID") then begin
                        UserPersonalizationPage.SetRecord(UserPersonalization);
                        UserPersonalizationPage.Run();
                    end else begin
                        Message(MissingUserSettingsMsg, Rec."User Name");
                        UserSettingsList.Run();
                    end;
                end;
            }
            action("User Setup")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'User Setup';
                Image = UserSetup;
                RunObject = Page "User Setup";
                ToolTip = 'Make additional choices for certain users.';

                AboutTitle = 'Additional setup for users';
                AboutText = 'Here, you can define when certain users can post transactions. You can also designate time sheet roles or associate users with sales/purchaser codes.';
            }
            action("Printer Selections")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Printer Selections';
                Image = Print;
                RunObject = Page "Printer Selections";
                ToolTip = 'Assign printers to users and/or reports so that a user always uses a specific printer, or a specific report only prints on a specific printer.';
            }
            action("Warehouse Employees")
            {
                ApplicationArea = Warehouse;
                Caption = 'Warehouse Employees';
                Image = WarehouseSetup;
                RunObject = Page "Warehouse Employees";
                ToolTip = 'View the warehouse employees that exist in the system.';
            }

            action("Employees")
            {
                ApplicationArea = BasicHR;
                Caption = 'Employees';
                Image = Employee;
                RunObject = Page "Employee List";
                ToolTip = 'View the employees that exist in the system.';
            }
            action("Resources")
            {
                ApplicationArea = Jobs;
                Caption = 'Resources';
                Image = Resource;
                RunObject = Page "Resource List";
                ToolTip = 'View the resources that exist in the system.';
            }
            action("Salespersons/Purchasers")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Salespersons/Purchasers';
                Image = Users;
                RunObject = Page "Salespersons/Purchasers";
                ToolTip = 'View the salespersons/purchasers that exist in the system.';
            }
            action("FA Journal Setup")
            {
                ApplicationArea = FixedAssets;
                Caption = 'FA Journal Setup';
                Image = FixedAssets;
                RunObject = Page "FA Journal Setup";
                ToolTip = 'Set up journals, journal templates, and journal batches for fixed assets.';
            }
        }
        area(processing)
        {
            action(AddMeAsSuper)
            {
                ApplicationArea = All;
                Caption = 'Add me as Administrator';
                Image = User;
                ToolTip = 'Assign the Administrator status to your user account.';
                Visible = NoUserExists and (not IsSaaS);

                trigger OnAction()
                begin
                    if Confirm(CreateQst, false, UserId) then
                        Codeunit.Run(Codeunit::"Users - Create Super User");
                end;
            }
            action("Invite External Accountant")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Invite external accountant';
                Image = SalesPerson;
                ToolTip = 'Set up an external accountant with access to your Dynamics 365.';
                Visible = IsSaaS;

                trigger OnAction()
                begin
                    Page.Run(Page::"Invite External Accountant");
                    CurrPage.Update(false);
                end;
            }
            action("Restore User Default Permissions")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Restore User''s Default Permissions';
                Enabled = not NoUserExists;
                Image = UserInterface;
                ToolTip = 'Restore the default permissions based on changes to the related plan.';
                Visible = IsSaaS and CanManageUsersOnTenant;

                trigger OnAction()
                var
                    PermissionManager: Codeunit "Permission Manager";
                    AzureADPlan: Codeunit "Azure AD Plan";
                begin
                    if Confirm(RestoreUserGroupsToDefaultQst, false, Rec."User Name") then begin
                        AzureADPlan.RefreshUserPlanAssignments(Rec."User Security ID");
                        PermissionManager.ResetUserToDefaultPermissions(Rec."User Security ID");
                    end;
                end;
            }
            action("Update users from Office")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Update users from Microsoft 365';
                Image = Users;
                ToolTip = 'Update the names, authentication email addresses, contact email addresses, plans etc. from Microsoft 365 for all users. Having SUPER permission set for all companies is required to run this action.';
                Visible = IsSaaS and CanManageUsersOnTenant;
                Enabled = HasSuperForAllCompanies;
                AboutTitle = 'Keep in sync with Microsoft 365';
                AboutText = 'When licenses or user accounts change in the Microsoft 365 admin center, you must sync the changes back to this list.';

                trigger OnAction()
                begin
                    Page.RunModal(Page::"Azure AD User Update Wizard");
                end;
            }
            action(Email)
            {
                ApplicationArea = All;
                Caption = 'Send Email';
                Image = Email;
                ToolTip = 'Send an email to this user.';
                Enabled = CanSendEmail;

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
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("Effective Permissions_Promoted"; "Effective Permissions")
                {
                }
                actionref("Invite External Accountant_Promoted"; "Invite External Accountant")
                {
                }
                actionref(Email_Promoted; Email)
                {
                }
                actionref(AddMeAsSuper_Promoted; AddMeAsSuper)
                {
                }
                actionref("Update users from Office_Promoted"; "Update users from Office")
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Navigate', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref("User Details_Promoted"; "User Details")
                {
                }
                actionref("Security Groups_Promoted"; "Security Groups")
                {
                }
                actionref("User Task Groups_Promoted"; "User Task Groups")
                {
                }
                actionref("Permission Sets_Promoted"; "Permission Sets")
                {
                }
                actionref("User Email Policies_Promoted"; "User Email Policies")
                {
                }
                actionref("User Settings_Promoted"; "User Settings")
                {
                }
                actionref("User Setup_Promoted"; "User Setup")
                {
                }
                actionref("Printer Selections_Promoted"; "Printer Selections")
                {
                }
                actionref("Warehouse Employees_Promoted"; "Warehouse Employees")
                {
                }
                actionref("FA Journal Setup_Promoted"; "FA Journal Setup")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    views
    {
        view(OnlyEnabled)
        {
            Caption = 'Enabled';
            Filters = where(State = const(Enabled));
        }
    }

    var
        IdentityManagement: Codeunit "Identity Management";
        UserCard: Page "User Card";
#if not CLEAN23
        BasicAuthUsedNotification: Notification;
#endif
        WindowsUserName: Text[208];
        Text001Err: Label 'The account %1 is not a valid Windows account.', Comment = '%1=user name';
        Text002Err: Label 'The account %1 already exists.', Comment = '%1=user name';
        Text003Err: Label 'The account %1 is not allowed.', Comment = '%1=user name';
        Text004Err: Label '%1 cannot be empty.', Comment = '%1=user name';
        CreateUserInSaaSErr: Label 'Creating users is not allowed in the online environment.';
        DeleteUserInSaaSErr: Label 'Deleting users is not allowed in the online environment.';
        MissingUserSettingsMsg: Label 'Some user settings, such as language, region, or time zone, weren''t specified when %1 was created, so default values were assigned. You can change them if needed.', Comment = '%1=user name';
        NoUserExists: Boolean;
        CreateQst: Label 'Do you want to create %1 as super user?', Comment = '%1=user name, e.g. europe\myaccountname';
        CanSendEmail: Boolean;
#pragma warning disable AA0470
        RestoreUserGroupsToDefaultQst: Label 'Do you want to restore the default permissions for user %1?', Comment = 'Do you want to restore the default permissions for user Annie?';
#pragma warning restore AA0470
        CanManageUsersOnTenant: Boolean;
        HasSuperForAllCompanies: Boolean;
        IsSaaS: Boolean;
        IsOwnUser: Boolean;
        TelemetryUserId: Guid;

    trigger OnAfterGetCurrRecord()
    var
        User: Record User;
    begin
        CurrPage.SetSelectionFilter(User);
        CanSendEmail := User.Count() = 1;
        IsOwnUser := Rec."User Security ID" = UserSecurityId();
    end;

    trigger OnAfterGetRecord()
    var
        UserProperty: Record "User Property";
    begin
        WindowsUserName := IdentityManagement.UserName(Rec."Windows Security ID");
        NoUserExists := false;
        if UserProperty.Get(Rec."User Security ID") then
            TelemetryUserId := UserProperty."Telemetry User ID"
        else
            Clear(TelemetryUserId);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        if UserCard.DeleteUserIsAllowed(Rec) then
            exit(true);
        if not UserCard.ManageUsersIsAllowed() then
            Error(DeleteUserInSaaSErr);
    end;

    trigger OnInit()
    var
        EnvironmentInfo: Codeunit "Environment Information";
        UserPermissions: Codeunit "User Permissions";
    begin
        IsSaaS := EnvironmentInfo.IsSaaS();
        CanManageUsersOnTenant := UserPermissions.CanManageUsersOnTenant(UserSecurityId());
        HasSuperForAllCompanies := UserPermissions.IsSuper(UserSecurityId());
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if not UserCard.ManageUsersIsAllowed() then
            Error(CreateUserInSaaSErr);
        if Rec."User Name" = '' then
            Error(Text004Err, Rec.FieldCaption("User Name"));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."User Security ID" := CreateGuid();
        WindowsUserName := '';
    end;

    trigger OnOpenPage()
    var
#if not CLEAN23
        MyNotification: Record "My Notifications";
#endif
        UserSelection: Codeunit "User Selection";
#if not CLEAN23
        UserManagement: Codeunit "User Management";
        EnvironmentInfo: Codeunit "Environment Information";
#endif
#if not CLEAN23
        NavTenantSettingsHelper: DotNet NavTenantSettingsHelper;
#endif
    begin
        NoUserExists := Rec.IsEmpty();
        UserSelection.HideExternalUsers(Rec);

#if not CLEAN23
        if UserWithWebServiceKeyExist() then begin
            Usermanagement.BasicAuthDepricationNotificationDefault(false);
            if (not NavTenantSettingsHelper.IsWSKeyAllowed()) and EnvironmentInfo.IsSaaS() then
                MyNotification.SetStatus(UserManagement.BasicAuthDepricationNotificationId(), false);
            if MyNotification.IsEnabled(UserManagement.BasicAuthDepricationNotificationId()) then
                UserManagement.BasicAuthUsedNotificationShow(BasicAuthUsedNotification);
        end;
#endif
    end;

    local procedure ValidateSid()
    var
        User: Record User;
    begin
        if Rec."Windows Security ID" = '' then
            Error(Text001Err, Rec."User Name");

        if (Rec."Windows Security ID" = 'S-1-1-0') or (Rec."Windows Security ID" = 'S-1-5-7') then
            Error(Text003Err, Rec."User Name");

        User.SetFilter("Windows Security ID", Rec."Windows Security ID");
        User.SetFilter("User Security ID", '<>%1', Rec."User Security ID");
        if not User.IsEmpty() then
            Error(Text002Err, WindowsUserName);
    end;

    local procedure ValidateUserName()
    var
        UserMgt: Codeunit "User Management";
    begin
        UserMgt.ValidateUserName(Rec, xRec, WindowsUserName);
        CurrPage.Update();
    end;

    local procedure SetUserName()
    begin
        Rec."User Name" := WindowsUserName;
        ValidateUserName();
    end;

    procedure GetSelectionFilter(var User: Record User)
    begin
        CurrPage.SetSelectionFilter(User);
    end;

#if not CLEAN23
    [Obsolete('Basic Authentication deprecation warning should no longer be shown with from 23.0', '23.0')]
    local procedure UserWithWebServiceKeyExist(): Boolean
    var
        User: Record User;
        WebServiceKey: Text[80];
        UserWithWebServiceKeyFound: Boolean;
    begin
        if User.Count > MaxNumberOfUsersToScanWebServcieAccessKey() then
            exit(false);
        UserWithWebServiceKeyFound := false;
        if User.FindSet() then
            repeat
                WebServiceKey := IdentityManagement.GetWebServicesKey(USer."User Security ID");
                if WebServiceKey <> '' then
                    UserWithWebServiceKeyFound := true;
            until (User.Next() = 0) or UserWithWebServiceKeyFound;
        exit(UserWithWebServiceKeyFound);
    end;
#endif
#if not CLEAN23
    [Obsolete('Basic Authentication deprecation warning should no longer be shown with from 23.0', '23.0')]
    local procedure MaxNumberOfUsersToScanWebServcieAccessKey(): Integer
    begin
        exit(1000);
    end;
#endif

}

