page 9171 "Profile List"
{
    AdditionalSearchTerms = 'users,roles,role centers,personalization,customization';
    ApplicationArea = Basic, Suite;
    Caption = 'Profiles (Roles)';
    CardPageID = "Profile Card";
    Editable = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "All Profile";
    UsageCategory = Lists;
    DeleteAllowed = false;
    InsertAllowed = false;
    SourceTableView = sorting(Caption);

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(ProfileIdField; "Profile ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Profile ID';
                    ToolTip = 'Specifies an ID that is used to identify the profile (role). There can be more than one profile with the same ID if they come from different extensions. Avoid using spaces in the profile ID to make it easier to create URLs linking to a specific profile.';
                }
                field(CaptionField; Caption)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Display Name';
                    ToolTip = 'Specifies the name of the organizational role as displayed in the user interface.';
                }
                field(AppNameField; "App Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Source';
                    ToolTip = 'Specifies the origin of this profile, which can be either an extension, shown by its name, or a custom profile created by a user.';
                }
                field(RoleCenterIdField; "Role Center ID")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Caption = 'Role Center ID';
                    Lookup = false;
                    ToolTip = 'Specifies the ID of the Role Center associated with the profile.';
                }
                field(EnabledField; Enabled)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Enabled';
                    ToolTip = 'Specifies whether the profile is available in the list of roles that users can select from. Note: Users that are assigned this profile can continue to sign in even when the profile is not enabled.';
                }
                field(DefaultRoleCenterField; "Default Role Center")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Use as default profile';
                    ToolTip = 'Specifies if this profile is used for all users that are not assigned a role. Only one profile can be set as the default.';
                }
                field(PromotedField; Promoted)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show in Role Explorer';
                    ToolTip = 'Specifies whether the display name and available business features of this profile are shown in the Role Explorer. The profile must also be enabled.';
                }
            }
        }
        area(factboxes)
        {
            systempart(LinksFactbox; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(NotesFactbox; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action(ShowUserList)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'User List';
                Image = "List";
                ToolTip = 'Open the list of users for the system.';
                RunObject = page "Users";
            }
            action(ShowUserPersonalizationList)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'User Personalization List';
                Image = "List";
                ToolTip = 'Specify the list of user personalizations for users of the system.';
                RunObject = page "User Personalization List";

            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";

                action(SetDefaultRoleCenterAction)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Use as default profile';
                    Image = Default;
                    Scope = "Repeater";
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedOnly = true;
                    ToolTip = 'Set the selected profile as the one that is used for all users that are not assigned a role. Only one profile can be set as the default.​';
                    Enabled = Enabled;
                    AccessByPermission = tabledata "Tenant Profile Setting" = M;

                    trigger OnAction()
                    begin
                        TestField("Profile ID");
                        TestField("Role Center ID");
                        Validate("Default Role Center", true);
                        Modify;
                        ConfPersonalizationMgt.ChangeDefaultRoleCenter(Rec);
                    end;
                }
                action(CopyProfileAction)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Copy profile';
                    Ellipsis = true;
                    Image = Copy;
                    Scope = "Repeater";
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedOnly = true;
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
                    Scope = "Repeater";
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedOnly = true;
                    Visible = IsWebClient;
                    ToolTip = 'Change the user interface for this profile to fit the unique needs of the role (opens in a new tab). The changes that you make only apply to users that are assigned this profile.';
                    AccessByPermission = tabledata "Tenant Profile" = M;

                    trigger OnAction()
                    begin
                        ConfPersonalizationMgt.OpenProfileCustomizationUrl(Rec);
                    end;
                }
                action(ExportProfiles)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export Profiles';
                    Image = Export;
                    Scope = Page;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedOnly = true;
                    Visible = IsWebClient;
                    ToolTip = 'Export to a profile package all changes done by users to this list. This may include new profiles, modified profiles and page customizations.';

                    trigger OnAction()
                    begin
                        ConfPersonalizationMgt.DownloadProfileConfigurationPackage();
                    end;
                }
                action(ImportProfiles)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Import Profiles';
                    Image = Import;
                    Scope = Page;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedOnly = true;
                    Visible = IsWebClient;
                    ToolTip = 'Import a profile package that adds or replaces profiles in this list. This may include new profiles, modified profiles and page customizations.';
                    RunPageMode = Edit;
                    RunObject = page "Profile Import Wizard";
                }
            }
        }
    }

    views
    {
        view(OnlyEnabled)
        {
            Caption = 'Enabled';
            Filters = where(Enabled = Const(true));
        }
        view(OnlyPromotedAndEnabled)
        {
            Caption = 'Shown in Role Explorer';
            Filters = where(Enabled = const(true), Promoted = const(true));
        }
    }

    trigger OnInit()
    begin
        IsWebClient := ClientTypeManagement.GetCurrentClientType() = ClientType::Web;
    end;

    trigger OnAfterGetRecord()
    begin
        // Solves the case where the profile is user-created; not using a local variable allows to keep the sorting capabilities
        if "App Name" = '' then
            "App Name" := ConfPersonalizationMgt.ResolveAppNameFromAppId("App ID");
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        EmptyGuid: Guid;
    begin
        // Since this value is set in OnAfterGetRecord, sorting by this field causes confusion in server that looks for the next record with a wrong string 
        if "App ID" = EmptyGuid then
            "App Name" := '';
        exit(Next(Steps));
    end;

    var
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        ClientTypeManagement: Codeunit "Client Type Management";
        IsWebClient: Boolean;
}
