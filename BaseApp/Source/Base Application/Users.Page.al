page 9800 Users
{
    AdditionalSearchTerms = 'permission,office 365 admin center';
    ApplicationArea = Basic, Suite;
    Caption = 'Users';
    CardPageID = "User Card";
    DelayedInsert = true;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Navigate';
    RefreshOnActivate = true;
    SourceTable = User;
    SourceTableView = sorting("User Name");
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("User Security ID"; "User Security ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an ID that uniquely identifies the user. This value is generated automatically and should not be changed.';
                    Visible = false;
                }
                field("User Name"; "User Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'User Name';
                    ToolTip = 'Specifies the user''s name. If the user is required to present credentials when starting the client, this is the name that the user must present.';

                    trigger OnValidate()
                    begin
                        ValidateUserName;
                    end;
                }
                field("Full Name"; "Full Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Full Name';
                    Editable = not IsSaaS;
                    ToolTip = 'Specifies the full name of the user.';
                }
                field(State; State)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the user''s login is enabled.';
                    Visible = not IsSaaS;
                }
                field("Windows Security ID"; "Windows Security ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Windows Security ID of the user. This is only relevant for Windows authentication.';
                    Visible = false;
                }
                field("Windows User Name"; WindowsUserName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Windows User Name';
                    ToolTip = 'Specifies the user''s name on Windows.';
                    Visible = not IsSaaS;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Desktop client is not supported in versions 15 and higher.';
                    ObsoleteTag = '15.3';

                    trigger OnValidate()
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
                }
                field("License Type"; "License Type")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'License Type';
                    Editable = NOT IsSaaS;
                    ToolTip = 'Specifies the type of license that applies to the user. For more information, see License Types.';
                }
                field("Authentication Email"; "Authentication Email")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the Microsoft account that this user signs into Office 365 or SharePoint Online with.';
                    Visible = IsSaaS;
                }
            }
        }
        area(factboxes)
        {
            part(Plans; "User Plans FactBox")
            {
                Caption = 'Licenses';
                ApplicationArea = Basic, Suite;
                SubPageLink = "User Security ID" = field("User Security ID");
                Visible = IsSaaS;
            }
            part(Control18; "Permission Sets FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "User Security ID" = field("User Security ID");
            }
            part("User Group Memberships"; "User Group Memberships FactBox")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'User Group Memberships';
                SubPageLink = "User Security ID" = field("User Security ID");
            }
            part(Control20; "User Setup FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "User ID" = field("User Name");
            }
            part(Control33; "User Personalization FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "User SID" = field("User Security ID");
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
                Caption = 'User Groups';
                action(Action15)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'User Groups';
                    Image = Users;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    RunObject = Page "User Groups";
                    ToolTip = 'Set up or modify user groups as a fast way of giving users access to the functionality that is relevant to their work.';
                }
                action("User Task Groups")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'User Task Groups';
                    Image = Users;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
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
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'View this user''s actual permissions for all objects per assigned permission set, and edit the user''s permissions in permission sets of type User-Defined.';

                    trigger OnAction()
                    var
                        EffectivePermissionsMgt: Codeunit "Effective Permissions Mgt.";
                    begin
                        EffectivePermissionsMgt.OpenPageForUser("User Security ID");
                    end;
                }
                action("Permission Sets")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Permission Sets';
                    Image = Permission;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Permission Sets";
                    ToolTip = 'View or edit which feature objects that users need to access and set up the related permissions in permission sets that you can assign to the users of the database.';
                }
                action("Permission Set by User")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Permission Set by User';
                    Image = Permission;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Permission Set by User";
                    ToolTip = 'View or edit the available permission sets and apply permission sets to existing users.';
                }
                action("Permission Set by User Group")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Permission Set by User Group';
                    Image = Permission;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Permission Set by User Group";
                    ToolTip = 'View or edit the available permission sets and apply permission sets to existing user groups.';
                }
            }
            action("User Setup")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'User Setup';
                Image = UserSetup;
                Promoted = true;
                PromotedCategory = Category4;
                RunObject = Page "User Setup";
                ToolTip = 'Set up users and define their permissions..';
            }
            action("Printer Selections")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Printer Selections';
                Image = Print;
                Promoted = true;
                PromotedCategory = Category4;
                RunObject = Page "Printer Selections";
                ToolTip = 'Assign printers to users and/or reports so that a user always uses a specific printer, or a specific report only prints on a specific printer.';
            }
            action("Warehouse Employees")
            {
                ApplicationArea = Warehouse;
                Caption = 'Warehouse Employees';
                Image = WarehouseSetup;
                Promoted = true;
                PromotedCategory = Category4;
                RunObject = Page "Warehouse Employees";
                ToolTip = 'View the warehouse employees that exist in the system.';
            }
            action("FA Journal Setup")
            {
                ApplicationArea = FixedAssets;
                Caption = 'FA Journal Setup';
                Image = FixedAssets;
                Promoted = true;
                PromotedCategory = Category4;
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
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Assign the Administrator status to your user account.';
                Visible = NoUserExists and (not IsSaaS);

                trigger OnAction()
                var
                    FormatedMessage: Text;
                begin
                    if Confirm(CreateQst, false, UserId) then
                        Codeunit.Run(Codeunit::"Users - Create Super User");
                end;
            }
            action("Get Users from Office 365")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Get New Users from Office 365';
                Image = Users;
                ToolTip = 'Retrieve new users or new user information from the Office 365 portal. Note that existing, unchanged users will not be updated.';
                Visible = IsSaaS;
                ObsoleteState = Pending;
                ObsoleteReason = 'Use the ''Update users from Office'' action instead.';
                ObsoleteTag = '16.0';

                trigger OnAction()
                var
                    AzureADUserManagement: Codeunit "Azure AD User Management";
                begin
                    AzureADUserManagement.CreateNewUsersFromAzureAD;
                    CurrPage.Update;
                end;
            }
            action("Invite External Accountant")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Invite External Accountant';
                Image = SalesPerson;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Set up an external accountant with access to your Dynamics 365.';
                Visible = IsSaaS;

                trigger OnAction()
                begin
                    Page.Run(Page::"Invite External Accountant");
                    CurrPage.Update(false);
                end;
            }
            action(UpdateUserFromAzureGraph)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Update users from Office 365';
                Image = Users;
                ToolTip = 'Update the names, authentication email addresses, and contact email addresses from Office 365 for the selected users.';
                Visible = IsSaaS;
                ObsoleteState = Pending;
                ObsoleteReason = 'Use the ''Update users from Office'' action instead.';
                ObsoleteTag = '16.0';

                trigger OnAction()
                var
                    User: Record User;
                    AzureADUserManagement: Codeunit "Azure AD User Management";
                begin
                    CurrPage.SetSelectionFilter(User);

                    if User.FindSet() then
                        if Confirm(UpdateAllSelectedUsersQst) then
                            repeat
                                AzureADUserManagement.UpdateUserFromGraph(User);
                            until User.Next() = 0;
                end;
            }
            action("Restore User Default User Groups")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Restore User''s Default User Groups';
                Enabled = CurrentUserIsSuper and RestoreUserGroupsForAnotherUser and (not NoUserExists) and (not IsIntelligentCloud);
                Image = UserInterface;
                ToolTip = 'Restore the default user groups based on changes to the related plan.';
                Visible = IsSaaS;
                ObsoleteState = Pending;
                ObsoleteReason = 'Use the ''Update users from Office'' action instead.';
                ObsoleteTag = '16.0';

                trigger OnAction()
                var
                    PermissionManager: Codeunit "Permission Manager";
                    AzureADPlan: Codeunit "Azure AD Plan";
                begin
                    if Confirm(RestoreUserGroupsToDefaultQst, false, "User Name") then begin
                        AzureADPlan.RefreshUserPlanAssignments("User Security ID");
                        PermissionManager.ResetUserToDefaultUserGroups("User Security ID");
                    end;
                end;
            }
            action("Update users from Office")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Get user updates from Office 365';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Image = Users;
                ToolTip = 'Update the names, authentication email addresses, contact email addresses, plans etc. from Office 365 for all users.';
                Visible = IsSaaS and CanManageUsersOnTenant;
                RunObject = page "Azure AD User Update Wizard";
            }
            action("Refresh User Groups")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Refresh User Groups';
                Enabled = CanManageUsers and (not NoUserExists);
                Image = SKU;
                ToolTip = 'Refresh selected users'' user groups with changes to the related plan.';
                Visible = IsSaaS;
                ObsoleteState = Pending;
                ObsoleteReason = 'Use the ''Update users from Office'' action instead.';
                ObsoleteTag = '16.0';

                trigger OnAction()
                var
                    User: Record User;
                    AzureADPlan: Codeunit "Azure AD Plan";
                    PlanIds: Codeunit "Plan Ids";
                begin
                    CurrPage.SetSelectionFilter(User);
                    User.SetFilter("License Type", '<>%1', User."License Type"::"External User");
                    User.SetFilter("Windows Security ID", '%1', '');

                    if Confirm(RefreshAllSelectedUserPlansQst) then begin
                        if User.FindSet() then
                            repeat
                                AzureADPlan.UpdateUserPlans(User."User Security ID");
                            until User.Next() = 0;
                        if AzureADPlan.MixedPlansExist then begin
                            if AzureADPlan.DoesPlanExist(PlanIds.GetBasicPlanId) then
                                Error(MixedSKUsWithBasicErr);
                            Error(MixedSKUsWithoutBasicErr);
                        end;
                    end;
                end;
            }
        }
    }

    views
    {
        view(OnlyEnabled)
        {
            Caption = 'Enabled';
            Filters = where(State = Const(Enabled));
        }
    }

    trigger OnAfterGetRecord()
    begin
        WindowsUserName := IdentityManagement.UserName("Windows Security ID");
        NoUserExists := false;
        RestoreUserGroupsForAnotherUser := "User Security ID" <> UserSecurityId;
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        if not UserCard.ManageUsersIsAllowed then
            Error('');
    end;

    trigger OnInit()
    var
        EnvironmentInfo: Codeunit "Environment Information";
        PermissionManager: Codeunit "Permission Manager";
        UserPermissions: Codeunit "User Permissions";
    begin
        IsSaaS := EnvironmentInfo.IsSaaS;
        CurrentUserIsSuper := UserPermissions.IsSuper(UserSecurityId);
        CanManageUsers := PermissionManager.CanCurrentUserManagePlansAndGroups;
        CanManageUsersOnTenant := UserPermissions.CanManageUsersOnTenant(UserSecurityId());
        IsIntelligentCloud := PermissionManager.IsIntelligentCloud;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if not UserCard.ManageUsersIsAllowed then
            Error('');
        if "User Name" = '' then
            Error(Text004Err, FieldCaption("User Name"));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        "User Security ID" := CreateGuid;
        WindowsUserName := '';
    end;

    trigger OnOpenPage()
    begin
        NoUserExists := IsEmpty;
        HideExternalUsers;
    end;

    var
        IdentityManagement: Codeunit "Identity Management";
        UserCard: Page "User Card";
        WindowsUserName: Text[208];
        Text001Err: Label 'The account %1 is not a valid Windows account.', Comment = '%1=user name';
        Text002Err: Label 'The account %1 already exists.', Comment = '%1=user name';
        Text003Err: Label 'The account %1 is not allowed.', Comment = '%1=user name';
        Text004Err: Label '%1 cannot be empty.', Comment = '%1=user name';
        NoUserExists: Boolean;
        CreateQst: Label 'Do you want to create %1 as super user?', Comment = '%1=user name, e.g. europe\myaccountname';
        CreateFirstUserYesMsg: Label 'Yes';
        CreateFirstUserNoMsg: Label 'No';
        RestoreUserGroupsToDefaultQst: Label 'Do you want to restore the default user groups to for user %1?', Comment = 'Do you want to restore the default user groups to for user Annie?';
        CurrentUserIsSuper: Boolean;
        RestoreUserGroupsForAnotherUser: Boolean;
        RefreshAllUserPlansQst: Label 'Do you want to refresh plans for all users?';
        UpdateAllSelectedUsersQst: Label 'Do you want to update details about the selected users with information from Office 365?';
        RefreshAllSelectedUserPlansQst: Label 'Do you want to refresh plans for all selected users?';
        MixedSKUsWithoutBasicErr: Label 'You cannot mix plans of type Essential and Premium. Make sure all users are on the same plan.';
        CanManageUsers: Boolean;
        CanManageUsersOnTenant: Boolean;
        MixedSKUsWithBasicErr: Label 'You cannot mix plans of type Basic, Essential, and Premium. Make sure all users are on the same plan.';
        IsIntelligentCloud: Boolean;
        IsSaaS: Boolean;

    local procedure ValidateSid()
    var
        User: Record User;
    begin
        if "Windows Security ID" = '' then
            Error(Text001Err, "User Name");

        if ("Windows Security ID" = 'S-1-1-0') or ("Windows Security ID" = 'S-1-5-7') then
            Error(Text003Err, "User Name");

        User.SetFilter("Windows Security ID", "Windows Security ID");
        User.SetFilter("User Security ID", '<>%1', "User Security ID");
        if not User.IsEmpty then
            Error(Text002Err, WindowsUserName);
    end;

    local procedure ValidateUserName()
    var
        UserMgt: Codeunit "User Management";
    begin
        UserMgt.ValidateUserName(Rec, xRec, WindowsUserName);
        CurrPage.Update;
    end;

    local procedure SetUserName()
    begin
        "User Name" := WindowsUserName;
        ValidateUserName;
    end;

    procedure GetSelectionFilter(var User: Record User)
    begin
        CurrPage.SetSelectionFilter(User);
    end;

    local procedure HideExternalUsers()
    var
        EnvironmentInfo: Codeunit "Environment Information";
        OriginalFilterGroup: Integer;
    begin
        if not EnvironmentInfo.IsSaaS then
            exit;

        OriginalFilterGroup := FilterGroup;
        FilterGroup := 2;
        SetFilter("License Type", '<>%1', "License Type"::"External User");
        FilterGroup := OriginalFilterGroup;
    end;
}

