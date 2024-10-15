#if not CLEAN22
namespace System.Security.AccessControl;

using System.Environment.Configuration;
using System.Reflection;

page 9830 "User Groups"
{
    ApplicationArea = Basic, Suite;
    Caption = 'User Groups';
    DataCaptionFields = "Code", Name;
    PageType = List;
    SourceTable = "User Group";
    UsageCategory = Lists;
    AboutTitle = 'About user groups';
    AboutText = 'User groups help you manage permissions. When you assign permissions to a group, every member of the group inherits these permissions. Note: User groups will be replaced by security groups and composable permission sets in a future release.';
    ObsoleteState = Pending;
    ObsoleteReason = '[220_UserGroups] Replaced by the Security Groups page in the security groups system; by Permission Sets page in the permission sets system. To learn more, go to https://go.microsoft.com/fwlink/?linkid=2245709.';
    ObsoleteTag = '22.0';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the record.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the record.';
                }
                field(YourProfileID; Rec."Default Profile ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Default Profile';
                    ToolTip = 'Specifies the default profile for members in this user group. The profile determines the layout of the home page, navigation and many other settings that help define the user''s role.​';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        AllProfileTable: Record "All Profile";
                        Roles: Page Roles;
                    begin
                        Roles.Initialize();
                        Roles.LookupMode(true);
                        if Roles.RunModal() = Action::LookupOK then begin
                            Roles.GetRecord(AllProfileTable);
                            UpdateProfile(AllProfileTable);
                        end
                    end;

                    trigger OnValidate()
                    var
                        AllProfileTable: Record "All Profile";
                    begin
                        if Rec."Default Profile ID" <> '' then begin
                            AllProfileTable.SetFilter("Profile ID", Rec."Default Profile ID");
                            if not AllProfileTable.FindFirst() then
                                Error(InvalidProfileCodeErr);
                        end;

                        UpdateProfile(AllProfileTable)
                    end;
                }
            }
        }
        area(factboxes)
        {
            part(Control12; "User Group Permissions FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "User Group Code" = field(Code);
            }
            part(Control11; "User Group Members FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "User Group Code" = field(Code);
            }
            systempart(Control6; Notes)
            {
                ApplicationArea = Notes;
            }
            systempart(Control7; MyNotes)
            {
                ApplicationArea = Basic, Suite;
            }
            systempart(Control8; Links)
            {
                ApplicationArea = RecordLinks;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action(UserGroupMembers)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Members';
                Image = Users;
                RunObject = Page "User Group Members";
                RunPageLink = "User Group Code" = field(Code);
                Scope = Repeater;
                ToolTip = 'View or edit the members of the user group.';
                AboutTitle = 'Members of the group';
                AboutText = 'Manage the people who are in the selected user group. A user can be a member of multiple user groups at the same time.';
            }
            action(UserGroupPermissionSets)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Permissions';
                Image = Permission;
                RunObject = Page "User Group Permission Sets";
                RunPageLink = "User Group Code" = field(Code);
                Scope = Repeater;
                ToolTip = 'View or edit the permission sets that are assigned to the user group.';
                AboutTitle = 'Define permissions for the group';
                AboutText = 'Manage which permissions the members of the selected group get with their membership.';
            }
            action(PageUserbyUserGroup)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'User by User Group';
                Image = User;
                RunObject = Page "User by User Group";
                ToolTip = 'View and assign user groups to users.';
            }
            action(PagePermissionSetbyUserGroup)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Permission Set by User Group';
                Image = Permission;
                RunObject = Page "Permission Set by User Group";
                ToolTip = 'View or edit the available permission sets and apply permission sets to existing user groups.';
            }
        }
        area(processing)
        {
            action(CopyUserGroup)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Copy User Group';
                Ellipsis = true;
                Image = Copy;
                ToolTip = 'Create a copy of the current user group with a name that you specify.';

                trigger OnAction()
                var
                    UserGroup: Record "User Group";
                begin
                    UserGroup.SetRange(Code, Rec.Code);
                    REPORT.RunModal(REPORT::"Copy User Group", true, false, UserGroup);
                end;
            }
            action(ExportUserGroups)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Export User Groups';
                Image = ExportFile;
                ToolTip = 'Export the existing user groups to an XML file.';

                trigger OnAction()
                begin
                    Rec.ExportUserGroups('');
                end;
            }
            action(ImportUserGroups)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Import User Groups';
                Image = Import;
                ToolTip = 'Import user groups from an XML file.';

                trigger OnAction()
                begin
                    Rec.ImportUserGroups('');
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(UserGroupMembers_Promoted; UserGroupMembers)
                {
                }
                actionref(UserGroupPermissionSets_Promoted; UserGroupPermissionSets)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        PermissionManager: Codeunit "Permission Manager";
    begin
        LegacyUserGroups.SendUserGroupsNotification();
        if PermissionManager.IsIntelligentCloud() then
            Rec.SetRange(Code, IntelligentCloudTok);
    end;

    local procedure UpdateProfile(AllProfileTable: Record "All Profile")
    var
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
    begin
        Rec."Default Profile ID" := AllProfileTable."Profile ID";
        Rec."Default Profile App ID" := AllProfileTable."App ID";
        Rec."Default Profile Scope" := AllProfileTable.Scope;
        if (Rec."Default Profile ID" <> xRec."Default Profile ID") or
           (Rec."Default Profile App ID" <> xRec."Default Profile App ID") or
           (Rec."Default Profile Scope" <> xRec."Default Profile Scope")
        then
            ConfPersonalizationMgt.ChangePersonalizationForUserGroupMembers(xRec, Rec);
        CurrPage.Update();
    end;

    var
        LegacyUserGroups: Codeunit "Legacy User Groups";
        IntelligentCloudTok: Label 'INTELLIGENT CLOUD', Locked = true;
        InvalidProfileCodeErr: Label 'The provided profile code does not match any existing profiles.';
}

#endif