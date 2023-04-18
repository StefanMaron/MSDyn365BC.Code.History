page 9170 "Profile Card"
{
    Caption = 'Profile (Role)';
    DataCaptionExpression = Caption;
    PageType = Card;
    SourceTable = "All Profile";
    DelayedInsert = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                Editable = IsProfileEditable;

                field(ScopeField; Scope)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Scope';
                    Enabled = false;
                    Visible = false;
                    ToolTip = 'Specifies if the profile is specific to your tenant or generally available in the system.';
                }
                field(ProfileIdField; "Profile ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Profile ID';
                    Editable = IsUserCreatedProfile;
                    ToolTip = 'Specifies an ID that is used to identify the profile (role). There can be more than one profile with the same ID if they come from different extensions. Avoid using spaces in the profile ID to make it easier to create URLs linking to a specific profile.';
                    NotBlank = true;

                    trigger OnValidate()
                    var
                        AllProfile: Record "All Profile";
                    begin
                        AllProfile.SetRange("Profile ID", "Profile ID");

                        // Platform inserts the record before validation, hence this filter is needed to enable the desired behaviour
                        AllProfile.SetFilter("App ID", '<>%1', "App ID");

                        if not AllProfile.IsEmpty() then
                            Error(ProfileIdAlreadyExistErr, "Profile ID");

                        if xRec."Profile ID" <> '' then
                            if not Confirm(RenamingWillDisruptExistingSessionsQst) then
                                Error('');
                    end;
                }
                field(AppNameField; AppName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Source';
                    Enabled = false;
                    ToolTip = 'Specifies the origin of this profile, which can be either an extension, shown by its name, or a custom profile created by a user.';
                }
                field(CaptionField; Caption)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Display Name';
                    ToolTip = 'Specifies the name of the organizational role as displayed in the user interface.​';
                    NotBlank = true;
                    ShowMandatory = true;
                }
                field(DescriptionField; Description)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description';
                    ToolTip = 'Specifies additional information about the profile, such as its purpose. This information may be shown to users.';
                    MultiLine = true;
                }
                field(RoleCenterIdField; "Role Center ID")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Caption = 'Role Center ID';
                    ToolTip = 'Specifies the home page that users will see when they have signed in. This is the ID of a page object of type Role Center.';
                    NotBlank = true;
                    ShowMandatory = true;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        AllObjWithCaptionRec: Record AllObjWithCaption;
                        AllObjectsWithCaptionPage: Page "All Objects with Caption";
                    begin
                        AllObjWithCaptionRec.FilterGroup(2);
                        AllObjWithCaptionRec.SetRange("Object Type", AllObjWithCaptionRec."Object Type"::Page);
                        AllObjWithCaptionRec.SetRange("Object Subtype", RoleCenterSubtypeTxt);
                        AllObjWithCaptionRec.FilterGroup(0);

                        AllObjectsWithCaptionPage.Caption := AvailableRoleCentersPageCaption;
                        AllObjectsWithCaptionPage.IsObjectTypeVisible(false);
                        AllObjectsWithCaptionPage.SetTableView(AllObjWithCaptionRec);

                        if AllObjWithCaptionRec.Get(AllObjWithCaptionRec."Object Type"::Page, "Role Center ID") then
                            AllObjectsWithCaptionPage.SetRecord(AllObjWithCaptionRec);

                        AllObjectsWithCaptionPage.LookupMode := true;
                        if AllObjectsWithCaptionPage.RunModal() = ACTION::LookupOK then begin
                            AllObjectsWithCaptionPage.GetRecord(AllObjWithCaptionRec);
                            Validate("Role Center ID", AllObjWithCaptionRec."Object ID");
                        end;
                        ValidateRoleCenterIdExists();
                    end;

                    trigger OnValidate()
                    begin
                        ValidateRoleCenterIdExists();
                    end;
                }
                field(EnabledField; Enabled)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Enabled';
                    ToolTip = 'Specifies whether the profile is available in the list of roles that users can select from. Note: Users that are assigned this profile can continue to sign in even when the profile is not enabled.';

                    trigger OnValidate()
                    begin
                        if not Enabled then
                            ConfPersonalizationMgt.ValidateDisableProfile(Rec);
                    end;
                }
                field(PromotedField; Promoted)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show in Role Explorer';
                    ToolTip = 'Specifies whether the display name and available business features of this profile are shown in the Role Explorer. The profile must also be enabled.';
                }
            }
            group(ProfileSettings)
            {
                Caption = 'Additional Settings';
                Editable = IsProfileEditable;

                field(DefaultRoleCenterField; "Default Role Center")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Use as default profile';
                    ToolTip = 'Specifies if this profile is used for all users that are not assigned a role. Only one profile can be set as the default.';
                    AccessByPermission = tabledata "Tenant Profile" = M;

                    trigger OnValidate()
                    begin
                        TestField("Profile ID");
                        TestField("Role Center ID");

                        if not Enabled then
                            Error(ProfileMustBeEnabledInOrderToSetItAsDefaultErr);
                    end;
                }
                field(DisablePersonalizationField; "Disable Personalization")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Disable personalization';
                    ToolTip = 'Specifies whether personalization is disabled for users of the profile.';
                }
            }
        }
        area(factboxes)
        {
            systempart(LinksFactboxPart; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(NotesFactboxPart; Notes)
            {
                ApplicationArea = Notes;
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(ShowProfileExtensions)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Profile Extensions';
                Image = SetupList;
                ToolTip = 'View a list of profile extensions that extend this profile.';
                RunObject = page "Profile Extension List";
                RunPageLink = "Base Profile App ID" = field("App ID"), "Base Profile ID" = field("Profile ID");
            }
            action(ShowProfilePageCustomization)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Manage customized pages';
                Image = SetupList;
                ToolTip = 'View the list of pages have been customized for this profile.';
                RunObject = page "Profile Customization List";
                RunPageLink = "App ID" = field("App ID"), "Profile ID" = field("Profile ID");
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";

                action(CopyProfileAction)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Copy profile';
                    Ellipsis = true;
                    Image = Copy;
                    ToolTip = 'Create a copy of this profile including any page customizations made by users for this profile.';
                    AccessByPermission = tabledata "Tenant Profile" = I;

                    trigger OnAction()
                    var
                        AllProfile: Record "All Profile";
                    begin
                        ConfPersonalizationMgt.CopyProfileWithUserInput(Rec, AllProfile);
                        if Get(AllProfile.Scope, AllProfile."App ID", AllProfile."Profile ID") then;
                    end;
                }
                action(CustomizeRoleAction)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customize pages';
                    Image = SetupColumns;
                    Visible = IsWebClient;
                    Enabled = IsProfileEditable;
                    ToolTip = 'Change the user interface for this profile to fit the unique needs of the role (opens in a new tab). The changes that you make only apply to users that are assigned this profile.';
                    AccessByPermission = tabledata "Tenant Profile" = M;

                    trigger OnAction()
                    begin
                        Hyperlink(ConfPersonalizationMgt.GetProfileConfigurationUrlForWeb(Rec));
                    end;
                }
                action(ClearCustomizedPagesAction)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'C&lear customized pages';
                    Image = Cancel;
                    ToolTip = 'Delete all customizations that are made for the profile.';
                    AccessByPermission = tabledata "Tenant Profile Page Metadata" = D;
                    Enabled = HasCustomizedPages;

                    trigger OnAction()
                    begin
                        ConfPersonalizationMgt.ClearProfileConfiguration(Rec);
                        UpdateHasCustomizedPages();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(CustomizeRoleAction_Promoted; CustomizeRoleAction)
                {
                }
                actionref(CopyProfileAction_Promoted; CopyProfileAction)
                {
                }
                actionref(ClearCustomizedPagesAction_Promoted; ClearCustomizedPagesAction)
                {
                }
            }
        }
    }

    trigger OnInit()
    begin
        IsWebClient := ClientTypeManagement.GetCurrentClientType() = ClientType::Web;
    end;

    trigger OnAfterGetCurrRecord()
    var
        EmptyGuid: Guid;
    begin
        AppName := "App Name";
        if "App ID" = EmptyGuid then
            AppName := UserCreatedAppNameTxt;

        UpdateHasCustomizedPages();

        RefreshEditability();

        ShowOrRecallDuplicateProfileIDNotification();
    end;

    local procedure UpdateHasCustomizedPages()
    var
        TenantProfilePageMetadata: Record "Tenant Profile Page Metadata";
    begin
        TenantProfilePageMetadata.SetRange("Profile ID", "Profile ID");
        TenantProfilePageMetadata.SetRange("App ID", "App ID");
        TenantProfilePageMetadata.SetRange(Owner, TenantProfilePageMetadata.Owner::Tenant);
        HasCustomizedPages := not TenantProfilePageMetadata.IsEmpty();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Scope := Scope::Tenant;
        "Role Center ID" := ConfPersonalizationMgt.DefaultRoleCenterID();
        Enabled := true;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        TestField(Caption);
        TestField("Role Center ID");
        ValidateRoleCenterIdExists();

        if "Default Role Center" then
            ConfPersonalizationMgt.ChangeDefaultRoleCenter(Rec);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        TestField(Caption);
        TestField("Role Center ID");

        if "Default Role Center" then
            ConfPersonalizationMgt.ChangeDefaultRoleCenter(Rec);
    end;

    trigger OnDeleteRecord() Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnDeleteRecord(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        ConfPersonalizationMgt.ValidateDeleteProfile(Rec);

        if not ConfPersonalizationMgt.CanDeleteProfile(Rec) then begin
            if not Enabled then begin
                Message(CannotDeleteProfileAlreadyMarkedAsDisabledMsg, "Profile ID", "App Name");
                Error('');
            end;

            if Confirm(CannotDeleteProfileMarkAsDisabledQst, false, "Profile ID", "App Name") then begin
                Enabled := false;
                Modify(true);
                exit(false);
            end;
            Error('');
        end;

        exit(true);
    end;

    local procedure ValidateRoleCenterIdExists()
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        if "Default Role Center" then
            TestField("Role Center ID");

        AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Page, "Role Center ID");
        AllObjWithCaption.TestField("Object Subtype", RoleCenterSubtypeTxt);
    end;

    local procedure RefreshEditability()
    begin
        IsUserCreatedProfile := IsNullGuid("App ID");

        IsProfileEditable := not ConfPersonalizationMgt.IsProfileIdAmbiguous(Rec);
    end;

    local procedure ShowOrRecallDuplicateProfileIDNotification()
    var
        DummyAllProfile: Record "All Profile";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        NotificationToShow: Notification;
    begin
        NotificationToShow.Id := DuplicateIDNotificationID;
        NotificationToShow.Message := ThereAreProfilesWithDuplicateIdMsg;

        if ConfPersonalizationMgt.IsProfileIdAmbiguous(Rec) then
            // This will send a generic notification for the table and not for the record, and hence make the recall logic easier
            NotificationLifecycleMgt.SendNotification(NotificationToShow, DummyAllProfile.RecordId)
        else
            NotificationLifecycleMgt.RecallNotificationsForRecord(DummyAllProfile.RecordId, true);
    end;

    var
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        ClientTypeManagement: Codeunit "Client Type Management";
        RoleCenterSubtypeTxt: Label 'RoleCenter', Locked = true;
        DuplicateIDNotificationID: Label 'ffbf8d52-e612-4e2e-9adc-d15b863d94ff', Locked = true;
        RenamingWillDisruptExistingSessionsQst: Label 'If any user is logged in with this profile, they will need to log in again. Do you want to continue?';
        CannotDeleteProfileMarkAsDisabledQst: Label 'The profile "%1" is provided by the extension %2 . You cannot delete the profile, unless you uninstall the extension. Do you want to mark the profile as Disabled instead?', Comment = '%1 = the ID of the profile the user is trying to delete; %2 = the extension (app) that owns the profile.';
        CannotDeleteProfileAlreadyMarkedAsDisabledMsg: Label 'The profile "%1" is provided by the extension %2 . You cannot delete the profile, unless you uninstall the extension. The profile has already been marked as disabled.', Comment = '%1 = the ID of the profile the user is trying to delete; %2 = the extension (app) that owns the profile.';
        AvailableRoleCentersPageCaption: Label 'Available Role Centers', Comment = 'When the user triggers LookUp of the Role Center ID field, this will be the caption of the lookup page';
        ProfileIdAlreadyExistErr: Label 'A profile with Profile ID "%1" already exist, please provide another Profile ID.';
        ProfileMustBeEnabledInOrderToSetItAsDefaultErr: Label 'The profile must be enabled in order to set it as the default profile.';
        ThereAreProfilesWithDuplicateIdMsg: Label 'Another profile has the same ID as this one. This can cause ambiguity in the system. Give this or the other profile another ID before you customize them. Contact your Microsoft partner for further assistance.';
        UserCreatedAppNameTxt: Label '(User-created)';
        IsUserCreatedProfile: Boolean;
        IsProfileEditable: Boolean;
        IsWebClient: Boolean;
        HasCustomizedPages: Boolean;
        AppName: Text;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnDeleteRecord(var AllProfile: Record "All Profile"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}

