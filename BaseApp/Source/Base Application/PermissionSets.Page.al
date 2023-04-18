page 9802 "Permission Sets"
{
    AdditionalSearchTerms = 'access rights privilege';
    ApplicationArea = Basic, Suite;
    Caption = 'Permission Sets';
    DelayedInsert = true;
    PageType = List;
    Permissions = TableData "Permission Set Link" = rd,
                  TableData "Aggregate Permission Set" = rimd;
    SourceTable = "Permission Set Buffer";
    SourceTableTemporary = true;
    UsageCategory = Lists;

    AboutTitle = 'About permissions';
    AboutText = 'You manage permissions by assigning permission sets to individual users and to security groups. You can only modify permission sets that you created, not the predefined ones.';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                Caption = 'Permission Set';
                field(PermissionSet; "Role ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Permission Set';
                    Editable = IsPermissionSetEditable;
                    ToolTip = 'Specifies the name of the permission set.';

                    trigger OnValidate()
                    var
                        PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
                    begin
                        PermissionPagesMgt.DisallowEditingPermissionSetsForNonAdminUsers();
                        PermissionPagesMgt.VerifyPermissionSetRoleID(Rec."Role ID");
                        RenameTenantPermissionSet();
                    end;

                    trigger OnDrillDown()
                    var
                        PermisssionSetRelation: Codeunit "Permission Set Relation";
                    begin
                        PermisssionSetRelation.OpenPermissionSetPage(Rec.Name, Rec."Role ID", Rec."App ID", Rec.Scope);
                    end;
                }
                field(Name; Rec.Name)
                {
                    Caption = 'Name';
                    ApplicationArea = Basic, Suite;
                    Editable = IsPermissionSetEditable;
                    ToolTip = 'Specifies the description of the record.';

                    trigger OnValidate()
                    var
                        PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
                    begin
                        PermissionPagesMgt.DisallowEditingPermissionSetsForNonAdminUsers();
                    end;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Enabled = false;
                    ToolTip = 'Specifies if the permission set is defined by your organization, the base application, or an extension. You can only edit or delete permission sets that you have created.';
                    AboutTitle = 'The source of the permission set';
                    AboutText = 'You can modify or delete permission sets that your organization created but not those that are built-in (System). Extensions can define permission sets that are also not editable and that will be removed if the extension is uninstalled.';
                }
                field("App Name"; Rec."App Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Extension Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the extension.';
                }
            }
        }
        area(factboxes)
        {
#if not CLEAN22
            part("System Permissions"; "Permissions FactBox")
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'Replaced with Expanded Permissions factbox';
                ObsoleteTag = '22.0';
                ApplicationArea = Basic, Suite;
                Caption = 'System Permissions';
                Editable = false;
                SubPageLink = "Role ID" = FIELD("Role ID");
                Visible = false;
            }
            part("Tenant Permissions"; "Tenant Permissions FactBox")
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'Replaced with Expanded Permissions factbox';
                ObsoleteTag = '22.0';
                ApplicationArea = Basic, Suite;
                Caption = 'Custom Permissions';
                Editable = false;
                Visible = false;
            }
#endif
            part(ExpandedPermissions; "Expanded Permissions FactBox")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Permissions';
                Editable = false;
                SubPageLink = "Role ID" = FIELD("Role ID"),
                              "App ID" = FIELD("App ID");
            }
            part("Included Permission Sets"; "Included PermissionSet FactBox")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Included Permission Sets';
                Editable = false;
            }
            part("Permission Set Assignments"; "Perm. Set Assignments Part")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Users';
                SubPageLink = "Role ID" = field("Role ID"), "App ID" = field("App ID"), Scope = field(Scope);
                AboutTitle = 'Permission set assignments';
                AboutText = 'View or edit the list of users who are assigned a permission set.';
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group(ShowPermissions)
            {
                Caption = 'Permissions';
                Image = Permission;
#if not CLEAN21
                action(Permissions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Permissions (legacy)';
                    Image = Permission;
                    Scope = Repeater;
                    ToolTip = 'View or edit which feature objects users need to access, and set up the related permissions in permission sets that you can assign to the users of the database.';
                    ObsoleteReason = 'Replaced by the PermissionSetContent action.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '21.0';

                    trigger OnAction()
                    var
                        AggregatePermissionSet: Record "Aggregate Permission Set";
                        PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
                    begin
                        GetSelectionFilter(AggregatePermissionSet);
                        PermissionPagesMgt.ShowPermissions(AggregatePermissionSet, false)
                    end;
                }
#endif
                action(PermissionSetContent)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Permissions';
                    Image = Permission;
                    Scope = Repeater;
                    ToolTip = 'View or edit which feature objects users need to access, and set up the related permissions in permission sets that you can assign to the users.';
                    AboutTitle = 'View permission set details';
                    AboutText = 'Go here to see which permissions the selected permission set defines for which objects.';

                    trigger OnAction()
                    var
                        PermissionSetRelation: Codeunit "Permission Set Relation";
                    begin
                        PermissionSetRelation.OpenPermissionSetPage(Rec.Name, Rec."Role ID", Rec."App ID", Rec.Scope);
                    end;
                }
                action("Permission Set by User")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Permission Set by User';
                    Image = Permission;
                    RunObject = Page "Permission Set by User";
                    ToolTip = 'View or edit the available permission sets and apply permission sets to existing users.';
                }
#if not CLEAN22
                action("Permission Set by User Group")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Permission Set by User Group';
                    Image = Permission;
                    RunObject = Page "Permission Set by User Group";
                    ToolTip = 'View or edit the available permission sets and apply permission sets to existing user groups.';
                    Visible = LegacyUserGroupsVisible;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Replaced by the Permission Set By Security Group action.';
                    ObsoleteTag = '22.0';
                }
#endif
                action("Permission Set By Security Group")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Permission Set by Security Group';
                    Image = Permission;
                    RunObject = Page "Permission Set By Sec. Group";
                    ToolTip = 'View or edit the available permission sets and apply permission sets to existing security groups.';
                }
                action("Show Permission Conflicts Overview")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Permission Conflicts Overview';
                    Image = Permission;
                    RunObject = Page "Permission Conflicts Overview";
                    ToolTip = 'View the permission sets that provide more permissions than product licenses allow.';
                    Visible = IsSaaS;
                }
                action("Show Permission Conflicts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Permission Conflicts';
                    Image = Permission;
                    ToolTip = 'View details about the permission set that provides more permissions than the license allows.';
                    Visible = IsSaas;

                    trigger OnAction()
                    var
                        PermissionConflict: Page "Permission Conflicts";
                    begin
                        PermissionConflict.SetPermissionSetId("Role ID");
                        PermissionConflict.Run();
                    end;
                }
            }
            group("User Groups")
            {
                Caption = 'Security Groups';
                Image = Users;
#if not CLEAN22
                action("User by User Group")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'User by User Group';
                    Image = User;
                    RunObject = Page "User by User Group";
                    ToolTip = 'View and assign user groups to users.';
                    Visible = LegacyUserGroupsVisible;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Adding users to user groups is done in M365 admin center in the new user group system.';
                    ObsoleteTag = '22.0';
                }
                action(UserGroups)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'User Groups';
                    Image = Users;
                    RunObject = Page "User Groups";
                    ToolTip = 'Set up or modify user groups as a fast way of giving users access to the functionality that is relevant to their work.';
                    Visible = LegacyUserGroupsVisible;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Replaced by the SecurityGroups action.';
                    ObsoleteTag = '22.0';
                }
#endif
                action(SecurityGroups)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Security Groups';
                    Image = Users;
                    RunObject = Page "Security Groups";
                    ToolTip = 'Set up or modify security groups as a fast way of giving users access to the functionality that is relevant to their work.';
                }
            }
        }
        area(processing)
        {
            group("<Functions>")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(CopyPermissionSet)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Copy Permission Set';
                    Ellipsis = true;
                    Enabled = CanManageUsersOnTenant;
                    Image = Copy;
                    ToolTip = 'Create a copy of the selected permission set with a name that you specify.';

                    trigger OnAction()
                    var
                        AggregatePermissionSet: Record "Aggregate Permission Set";
                        CopyPermissionSet: Report "Copy Permission Set";
                        ZeroGuid: Guid;
                    begin
                        AggregatePermissionSet.SetRange(Scope, Scope);
                        AggregatePermissionSet.SetRange("App ID", "App ID");
                        AggregatePermissionSet.SetRange("Role ID", "Role ID");

                        CopyPermissionSet.SetTableView(AggregatePermissionSet);
                        CopyPermissionSet.RunModal();

                        if AggregatePermissionSet.Get(AggregatePermissionSet.Scope::Tenant, ZeroGuid, CopyPermissionSet.GetNewRoleID()) then begin
                            Rec.Init();
                            Rec.TransferFields(AggregatePermissionSet);
                            Rec.SetType();
                            Rec.Insert();
                            Rec.Get(Rec.Type, Rec."Role ID");
                        end;
                    end;
                }
                action(ImportPermissionSets)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Import Permission Sets';
                    Enabled = CanManageUsersOnTenant;
                    Image = Import;
                    ToolTip = 'Import a file with permissions.';

                    trigger OnAction()
                    var
                        PermissionSetBuffer: Record "Permission Set Buffer";
                        TempBlob: Codeunit "Temp Blob";
                        ImportPermissionSets: XmlPort "Import Permission Sets";
#if not CLEAN21
                        ImportTenantPermissionSets: XmlPort "Import Tenant Permission Sets";
#endif
                        FileName: Text;
                        InStream: InStream;
                        OutStream: OutStream;
                        UpdateExistingPermissions: Boolean;
                    begin
                        UploadIntoStream('Import', '', '', FileName, InStream);
                        TempBlob.CreateOutStream(OutStream);
                        CopyStream(OutStream, InStream);

                        TempBlob.CreateInStream(InStream);
                        UpdateExistingPermissions := Confirm(UpdateExistingPermissionsLbl, true);
#if not CLEAN21
                        if IsImportNewVersion(InStream) then begin
                            ImportPermissionSets.SetSource(InStream);
                            ImportPermissionSets.SetUpdatePermissions(UpdateExistingPermissions);
                            ImportPermissionSets.Import();
                        end else begin
                            ImportTenantPermissionSets.SetSource(InStream);
                            ImportTenantPermissionSets.SetUpdatePermissions(UpdateExistingPermissions);
                            ImportTenantPermissionSets.Import();
                        end;
#else
                            ImportPermissionSets.SetSource(InStream);
                            ImportPermissionSets.SetUpdatePermissions(UpdateExistingPermissions);
                            ImportPermissionSets.Import();
#endif

                        PermissionSetBuffer := Rec;
                        Rec.FillRecordBuffer();
                        if Rec.Get(PermissionSetBuffer.Type, PermissionSetBuffer."Role ID") then;
                    end;
                }
                action(ExportPermissionSets)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export Permission Sets';
                    Image = Export;
                    ToolTip = 'Export one or more permission sets to a file.';

                    trigger OnAction()
                    var
                        TenantPermissionSet: Record "Tenant Permission Set";
                        MetadataPermissionSet: Record "Metadata Permission Set";
                        TempBlob: Codeunit "Temp Blob";
                        EnvironmentInfo: Codeunit "Environment Information";
                        FileManagement: Codeunit "File Management";
                        ExportPermissionSetsSystem: Xmlport "Export Permission Sets System";
                        ExportPermissionSetsTenant: XmlPort "Export Permission Sets Tenant";
                        OutStr: OutStream;
                    begin
                        if Rec.Type = Rec.Type::System then
                            GetSelectionFilter(MetadataPermissionSet)
                        else
                            GetSelectionFilter(TenantPermissionSet);

                        if EnvironmentInfo.IsSandbox() then
                            if Confirm(ExportExtensionSchemaQst) then begin
                                TempBlob.CreateOutStream(OutStr);

                                if Rec.Type = Rec.Type::System then begin
                                    ExportPermissionSetsSystem.SetExportToExtensionSchema(true);
                                    ExportPermissionSetsSystem.SetTableView(MetadataPermissionSet);
                                    ExportPermissionSetsSystem.SetDestination(OutStr);
                                    ExportPermissionSetsSystem.Export();
                                end else begin
                                    ExportPermissionSetsTenant.SetExportToExtensionSchema(true);
                                    ExportPermissionSetsTenant.SetTableView(TenantPermissionSet);
                                    ExportPermissionSetsTenant.SetDestination(OutStr);
                                    ExportPermissionSetsTenant.Export();
                                end;

                                FileManagement.BLOBExport(TempBlob, FileManagement.ServerTempFileName('xml'), true);
                                exit;
                            end;

                        if Rec.Type = Rec.Type::System then
                            XmlPort.Run(XmlPort::"Export Permission Sets System", false, false, MetadataPermissionSet)
                        else
                            XmlPort.Run(XmlPort::"Export Permission Sets Tenant", false, false, TenantPermissionSet);
                    end;
                }
                action(RemoveObsoletePermissions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Remove Obsolete Permissions';
                    Enabled = CanManageUsersOnTenant;
                    Image = Delete;
                    ToolTip = 'Remove all permissions related to the objects which are obsolete or removed.';

                    trigger OnAction()
                    var
                        TableMetadata: Record "Table Metadata";
                        Permission: Record Permission;
                        TenantPermission: Record "Tenant Permission";
                        AllObjWithCaption: Record AllObjWithCaption;
                        PermissionToDelete: Record Permission;
                        TenantPermissionToDelete: Record "Tenant Permission";
                        PermissionsCount: Integer;
                    begin
                        TableMetadata.SetRange(ObsoleteState, TableMetadata.ObsoleteState::Removed);
                        if TableMetadata.FindSet() then begin
                            Permission.SetRange("Object Type", Permission."Object Type"::"Table Data", Permission."Object Type"::Table);
                            TenantPermission.SetRange("Object Type", Permission."Object Type"::"Table Data", Permission."Object Type"::Table);
                            repeat
                                Permission.SetRange("Object ID", TableMetadata.ID);
                                TenantPermission.SetRange("Object ID", TableMetadata.ID);
                                PermissionsCount += Permission.Count + TenantPermission.Count();
                                Permission.DeleteAll();
                                TenantPermission.DeleteAll();
                            until TableMetadata.Next() = 0;
                        end;
                        Permission.SetFilter(
                            "Object Type", '%1|%2|%3|%4|%5',
                            Permission."Object Type"::Codeunit, Permission."Object Type"::Page, Permission."Object Type"::Query,
                            Permission."Object Type"::Report, Permission."Object Type"::XMLport);
                        Permission.SetFilter("Object ID", '<>0');
                        if Permission.FindSet() then
                            repeat
                                if not AllObjWithCaption.Get(Permission."Object Type", Permission."Object ID") then begin
                                    PermissionToDelete.Get(Permission."Role ID", Permission."Object Type", Permission."Object ID");
                                    PermissionToDelete.Delete();
                                    PermissionsCount += 1;
                                end;
                            until Permission.Next() = 0;
                        TenantPermission.SetFilter(
                            "Object Type", '%1|%2|%3|%4|%5',
                            TenantPermission."Object Type"::Codeunit, TenantPermission."Object Type"::Page, TenantPermission."Object Type"::Query,
                            TenantPermission."Object Type"::Report, TenantPermission."Object Type"::XMLport);
                        TenantPermission.SetFilter("Object ID", '<>0');
                        if TenantPermission.FindSet() then
                            repeat
                                if not AllObjWithCaption.Get(TenantPermission."Object Type", TenantPermission."Object ID") then begin
                                    TenantPermissionToDelete.Get(TenantPermission."App ID", TenantPermission."Role ID", TenantPermission."Object Type", TenantPermission."Object ID");
                                    TenantPermissionToDelete.Delete();
                                    PermissionsCount += 1;
                                end;
                            until TenantPermission.Next() = 0;

                        if PermissionsCount > 0 then
                            Message(StrSubstNo(ObsoletePermissionsMsg, PermissionsCount))
                        else
                            Message(NothingToRemoveMsg);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(Permissions_Promoted; PermissionSetContent)
                {
                }
                actionref(CopyPermissionSet_Promoted; CopyPermissionSet)
                {
                }
                actionref(ImportPermissionSets_Promoted; ImportPermissionSets)
                {
                }
                actionref(ExportPermissionSets_Promoted; ExportPermissionSets)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        IsPermissionSetEditable := Type = Type::"User-Defined";
        CurrPage."Included Permission Sets".Page.UpdateIncludedPermissionSets(Rec."Role ID");
    end;

    trigger OnAfterGetRecord()
    begin
        IsPermissionSetEditable := Type = Type::"User-Defined";
    end;

    trigger OnDeleteRecord(): Boolean
    var
        PermissionSetLink: Record "Permission Set Link";
        TenantPermissionSet: Record "Tenant Permission Set";
#if not CLEAN22
        UserGroupPermissionSet: Record "User Group Permission Set";
#endif
        PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
    begin
        PermissionPagesMgt.DisallowEditingPermissionSetsForNonAdminUsers();

        if Type <> Type::"User-Defined" then
            Error(CannotDeletePermissionSetErr);

        PermissionSetLink.SetRange("Linked Permission Set ID", "Role ID");
        PermissionSetLink.DeleteAll();

#if not CLEAN22
        UserGroupPermissionSet.SetRange("Role ID", "Role ID");
        UserGroupPermissionSet.DeleteAll();
#endif

        TenantPermissionSet.Get("App ID", "Role ID");
        TenantPermissionSet.Delete();

        CurrPage.Update();
        exit(true);
    end;

    trigger OnInit()
    var
        UserPermissions: Codeunit "User Permissions";
    begin
        CanManageUsersOnTenant := UserPermissions.CanManageUsersOnTenant(UserSecurityId());
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
        ZeroGUID: Guid;
    begin
        PermissionPagesMgt.DisallowEditingPermissionSetsForNonAdminUsers();
        PermissionPagesMgt.VerifyPermissionSetRoleID(Rec."Role ID");

        TenantPermissionSet.Init();
        TenantPermissionSet."App ID" := ZeroGUID;
        TenantPermissionSet."Role ID" := Rec."Role ID";
        TenantPermissionSet.Name := Rec.Name;
        TenantPermissionSet.Insert();

        Insert();
        Rec.Get(Type::"User-Defined", "Role ID");
        exit(false);
    end;

    trigger OnModifyRecord(): Boolean
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
    begin
        PermissionPagesMgt.DisallowEditingPermissionSetsForNonAdminUsers();

        if Type = Type::"User-Defined" then begin
            PermissionPagesMgt.VerifyPermissionSetRoleID(Rec."Role ID");
            TenantPermissionSet.Get(xRec."App ID", xRec."Role ID");
            if xRec."Role ID" <> Rec."Role ID" then begin
                TenantPermissionSet.Rename(xRec."App ID", Rec."Role ID");
                TenantPermissionSet.Get(xRec."App ID", Rec."Role ID");
            end;
            TenantPermissionSet.Name := Rec.Name;
            TenantPermissionSet.Modify();
            CurrPage.Update(false);
            exit(true);
        end;
        exit(false); // Causes UI to stop processing the action - we handled it manually
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Type := Type::"User-Defined";
        IsPermissionSetEditable := true;
        Scope := Scope::Tenant;
    end;

    trigger OnOpenPage()
    var
        PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
        EnvironmentInfo: Codeunit "Environment Information";
#if not CLEAN22
        LegacyUserGroups: Codeunit "Legacy User Groups";
#endif
    begin
#if not CLEAN22
        LegacyUserGroupsVisible := LegacyUserGroups.UiElementsVisible();
#endif
        IsSaas := EnvironmentInfo.IsSaaS();

        PermissionPagesMgt.CheckAndRaiseNotificationIfAppDBPermissionSetsChanged();
        FillRecordBuffer();

        if PermissionManager.IsIntelligentCloud() then
            SetRange("Role ID", IntelligentCloudTok);
    end;
#if not CLEAN21
    local procedure IsImportNewVersion(InStream: InStream): Boolean
    var
        XmlDoc: XmlDocument;
        XmlList: XmlNodeList;
        XmlRoot: XmlElement;
        XmlAttributes: XmlAttributeCollection;
        XmlAttribute: XmlAttribute;
        Counter: Integer;
    begin
        XmlDocument.ReadFrom(InStream, XmlDoc);
        XmlDoc.GetRoot(XmlRoot);
        XmlAttributes := XmlRoot.Attributes();
        for Counter := 1 to XmlAttributes.Count() do begin
            XmlAttributes.Get(Counter, XmlAttribute);
            if XmlAttribute.Name = 'Version' then
                exit(true);
        end;
        exit(false);
    end;
#endif

    local procedure GetSelectionFilter(var TenantPermissionSet: Record "Tenant Permission Set")
    var
        PermissionSetBuffer: Record "Permission Set Buffer";
    begin
        TenantPermissionSet.Reset();
        PermissionSetBuffer.CopyFilters(Rec);
        CurrPage.SetSelectionFilter(Rec);
        if Rec.FindSet() then
            repeat
                if TenantPermissionSet.Get("App ID", "Role ID") then
                    TenantPermissionSet.Mark(true);
            until Next() = 0;
        TenantPermissionSet.MarkedOnly(true);
        Reset();
        CopyFilters(PermissionSetBuffer);
    end;

    local procedure GetSelectionFilter(var MetadataPermissionSet: Record "Metadata Permission Set")
    var
        PermissionSetBuffer: Record "Permission Set Buffer";
    begin
        MetadataPermissionSet.Reset();
        PermissionSetBuffer.CopyFilters(Rec);
        CurrPage.SetSelectionFilter(Rec);
        if FindSet() then
            repeat
                if MetadataPermissionSet.Get("App ID", "Role ID") then
                    MetadataPermissionSet.Mark(true);
            until Next() = 0;
        MetadataPermissionSet.MarkedOnly(true);
        Reset();
        CopyFilters(PermissionSetBuffer);
    end;

#if not CLEAN21
    local procedure GetSelectionFilter(var AggregatePermissionSet: Record "Aggregate Permission Set")
    var
        PermissionSetBuffer: Record "Permission Set Buffer";
    begin
        AggregatePermissionSet.Reset();
        PermissionSetBuffer.CopyFilters(Rec);
        CurrPage.SetSelectionFilter(Rec);
        if FindSet() then
            repeat
                if AggregatePermissionSet.Get(Scope, "App ID", "Role ID") then
                    AggregatePermissionSet.Mark(true);
            until Next() = 0;
        AggregatePermissionSet.MarkedOnly(true);
        Reset();
        CopyFilters(PermissionSetBuffer);
    end;
#endif

    internal procedure GetSelectedRecords(var CurrSelectedRecords: Record "Permission Set Buffer")
    begin
        CurrPage.SetSelectionFilter(Rec);

        if Rec.FindSet() then
            repeat
                CurrSelectedRecords.Copy(Rec);
                CurrSelectedRecords.Insert();
            until Rec.Next() = 0;
    end;

    var
        PermissionManager: Codeunit "Permission Manager";
        CanManageUsersOnTenant: Boolean;
        [InDataSet]
        IsPermissionSetEditable: Boolean;
        IsSaas: Boolean;
        CannotDeletePermissionSetErr: Label 'You can only delete user-created or copied permission sets.';
        ExportExtensionSchemaQst: Label 'Do you want to export permission sets in a schema that is supported by the extension package?';
        IntelligentCloudTok: Label 'INTELLIGENT CLOUD', Locked = true;
        ObsoletePermissionsMsg: Label '%1 obsolete permissions were removed.', Comment = '%1 = number of deleted records.';
        NothingToRemoveMsg: Label 'There is nothing to remove.';
        UpdateExistingPermissionsLbl: Label 'Update existing permissions and permission sets';
#if not CLEAN22
        LegacyUserGroupsVisible: Boolean;
#endif
}

