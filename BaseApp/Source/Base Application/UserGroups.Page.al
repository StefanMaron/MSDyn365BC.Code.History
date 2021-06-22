page 9830 "User Groups"
{
    AdditionalSearchTerms = 'users,permissions,access right';
    ApplicationArea = Basic, Suite;
    Caption = 'User Groups';
    DataCaptionFields = "Code", Name;
    PageType = List;
    SourceTable = "User Group";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the record.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the record.';
                }
                field(YourProfileID; YourProfileID)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Default Profile';
                    Editable = false;
                    ToolTip = 'Specifies the default profile for members in this user group. The profile determines the layout of the home page, navigation and many other settings that help define the user''s role.​';

                    trigger OnAssistEdit()
                    var
                        AllProfileTable: Record "All Profile";
                        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
                    begin
                        if PAGE.RunModal(PAGE::"Available Roles", AllProfileTable) = ACTION::LookupOK then begin
                            YourProfileID := AllProfileTable."Profile ID";
                            "Default Profile ID" := AllProfileTable."Profile ID";
                            "Default Profile App ID" := AllProfileTable."App ID";
                            "Default Profile Scope" := AllProfileTable.Scope;
                            if ("Default Profile ID" <> xRec."Default Profile ID") or
                               ("Default Profile App ID" <> xRec."Default Profile App ID") or
                               ("Default Profile Scope" <> xRec."Default Profile Scope")
                            then
                                ConfPersonalizationMgt.ChangePersonalizationForUserGroupMembers(Code, xRec."Default Profile ID", YourProfileID);
                        end
                    end;
                }
            }
        }
        area(factboxes)
        {
            part(Control12; "User Group Permissions FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "User Group Code" = FIELD(Code);
            }
            part(Control11; "User Group Members FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "User Group Code" = FIELD(Code);
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
                Caption = 'User Group Members';
                Image = Users;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                RunObject = Page "User Group Members";
                RunPageLink = "User Group Code" = FIELD(Code);
                Scope = Repeater;
                ToolTip = 'View or edit the members of the user group.';
            }
            action(UserGroupPermissionSets)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'User Group Permission Sets';
                Image = Permission;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                RunObject = Page "User Group Permission Sets";
                RunPageLink = "User Group Code" = FIELD(Code);
                Scope = Repeater;
                ToolTip = 'View or edit the permission sets that are assigned to the user group.';
            }
            action(PageUserbyUserGroup)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'User by User Group';
                Image = User;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "User by User Group";
                ToolTip = 'View and assign user groups to users.';
            }
            action(PagePermissionSetbyUserGroup)
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
                    UserGroup.SetRange(Code, Code);
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
                    ExportUserGroups('');
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
                    ImportUserGroups('');
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        YourProfileID := "Default Profile ID";
    end;

    trigger OnAfterGetRecord()
    begin
        if Code = '' then
            YourProfileID := ''
        else
            YourProfileID := "Default Profile ID";
    end;

    trigger OnOpenPage()
    var
        PermissionManager: Codeunit "Permission Manager";
    begin
        if PermissionManager.IsIntelligentCloud then
            SetRange(Code, IntelligentCloudTok);
    end;

    var
        YourProfileID: Code[30];
        IntelligentCloudTok: Label 'INTELLIGENT CLOUD', Locked = true;
}

