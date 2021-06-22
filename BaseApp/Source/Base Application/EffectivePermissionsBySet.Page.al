page 9853 "Effective Permissions By Set"
{
    Caption = 'By Permission Set';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPart;
    SourceTable = "Permission Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control5)
            {
                ShowCaption = false;
                field("Permission Set"; "Permission Set")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the permission set that gives the user permissions to the object chosen in the Permissions section.';

                    trigger OnDrillDown()
                    var
                        TenantPermission: Record "Tenant Permission";
                    begin
                        if Source = Source::Entitlement then
                            exit;
                        OpenPermissionsPage(true);
                        if Type = Type::"User-Defined" then begin
                            TenantPermission.Get(GetAppID, "Permission Set", CurrObjectType, CurrObjectID);
                            "Read Permission" := TenantPermission."Read Permission";
                            "Insert Permission" := TenantPermission."Insert Permission";
                            "Modify Permission" := TenantPermission."Modify Permission";
                            "Delete Permission" := TenantPermission."Delete Permission";
                            "Execute Permission" := TenantPermission."Execute Permission";
                            Modify;
                            RefreshDisplayTexts;
                        end;
                    end;
                }
                field(Source; Source)
                {
                    ApplicationArea = All;
                    Enabled = false;
                    Style = Strong;
                    StyleExpr = Source = Source::Entitlement;
                    ToolTip = 'Specifies the origin of the permission set that gives the user permissions for the object chosen in the Permissions section. Note that rows with the type Entitlement originate from the subscription plan. The permission values of the entitlement overrule values that give increased permissions in other permission sets. In those cases, the permission level is Conflict.';
                    Visible = IsSaaS;
                }
                field(Type; Type)
                {
                    ApplicationArea = All;
                    Enabled = false;
                    ToolTip = 'Specifies the type of the permission set that gives the user permissions for the object chosen in the Permissions section. Note that you can only edit permission sets of type User-Defined.';
                }
                field(ReadTxt; ReadPermissionsTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Read Permission';
                    Editable = false;
                    ToolTip = 'Specifies whether the permission set gives the user the Read permission.';

                    trigger OnDrillDown()
                    begin
                        EffectivePermissionsMgt.ShowPermissionConflict(ReadPermissions, ReadEntitlementPermissions, Source = Source::Entitlement, Type = Type::"User-Defined");
                    end;
                }
                field(InsertTxt; InsertPermissionsTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Insert Permission';
                    Editable = false;
                    ToolTip = 'Specifies whether the permission set gives the user the Insert permission.';

                    trigger OnDrillDown()
                    begin
                        EffectivePermissionsMgt.ShowPermissionConflict(InsertPermissions, InsertEntitlementPermissions, Source = Source::Entitlement, Type = Type::"User-Defined");
                    end;
                }
                field(ModifyTxt; ModifyPermissionsTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Modify Permission';
                    Editable = false;
                    ToolTip = 'Specifies whether the permission set gives the user the Modify permission.';

                    trigger OnDrillDown()
                    begin
                        EffectivePermissionsMgt.ShowPermissionConflict(ModifyPermissions, ModifyEntitlementPermissions, Source = Source::Entitlement, Type = Type::"User-Defined");
                    end;
                }
                field(DeleteTxt; DeletePermissionsTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Delete Permission';
                    Editable = false;
                    ToolTip = 'Specifies whether the permission set gives the user the Delete permission.';

                    trigger OnDrillDown()
                    begin
                        EffectivePermissionsMgt.ShowPermissionConflict(DeletePermissions, DeleteEntitlementPermissions, Source = Source::Entitlement, Type = Type::"User-Defined");
                    end;
                }
                field(ExecuteTxt; ExecutePermissionsTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Execute Permission';
                    Editable = false;
                    ToolTip = 'Specifies whether the permission set gives the user the Execute permission.';

                    trigger OnDrillDown()
                    var
                    begin
                        EffectivePermissionsMgt.ShowPermissionConflict(ExecutePermissions, ExecuteEntitlementPermissions, Source = Source::Entitlement, Type = Type::"User-Defined");
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
        }
    }

    trigger OnAfterGetRecord()
    begin
        RefreshDisplayTexts;
    end;

    trigger OnInit()
    var
        UserPermissions: Codeunit "User Permissions";
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        CurrentUserCanManageUser := UserPermissions.CanManageUsersOnTenant(UserSecurityId);
        IsSaaS := EnvironmentInfo.IsSaaS;
    end;

    trigger OnOpenPage()
    begin
        SetCurrentKey(Source, Type);
    end;

    var
        EntitlementPermissionBuffer: Record "Permission Buffer";
        EffectivePermissionsMgt: Codeunit "Effective Permissions Mgt.";
        ReadPermissionsTxt: Text;
        InsertPermissionsTxt: Text;
        ModifyPermissionsTxt: Text;
        DeletePermissionsTxt: Text;
        ExecutePermissionsTxt: Text;
        CurrentUserCanManageUser: Boolean;
        IsSaaS: Boolean;
        IsTableData: Boolean;
        CurrObjectType: Option;
        CurrObjectID: Integer;
        BadlyFormattedTextErr: Label '''%1'' is not a valid value for the ''%2'' permission.', Comment = '%1 = The entered value for the permission field;%2 = the caption of the permission field';
        CurrUserID: Guid;
        [InDataSet]
        ReadPermissions: Enum Permission;
        [InDataSet]
        InsertPermissions: Enum Permission;
        [InDataSet]
        ModifyPermissions: Enum Permission;
        [InDataSet]
        DeletePermissions: Enum Permission;
        [InDataSet]
        ExecutePermissions: Enum Permission;
        [InDataSet]
        ReadEntitlementPermissions: Enum Permission;
        [InDataSet]
        InsertEntitlementPermissions: Enum Permission;
        [InDataSet]
        ModifyEntitlementPermissions: Enum Permission;
        [InDataSet]
        DeleteEntitlementPermissions: Enum Permission;
        [InDataSet]
        ExecuteEntitlementPermissions: Enum Permission;

    local procedure RefreshDisplayTexts()
    var
        PermissionManager: Codeunit "Permission Manager";
        IsSourceEntitlement: Boolean;
    begin
        ReadPermissions := EffectivePermissionsMgt.ConvertToPermission("Read Permission");
        InsertPermissions := EffectivePermissionsMgt.ConvertToPermission("Insert Permission");
        ModifyPermissions := EffectivePermissionsMgt.ConvertToPermission("Modify Permission");
        DeletePermissions := EffectivePermissionsMgt.ConvertToPermission("Delete Permission");
        ExecutePermissions := EffectivePermissionsMgt.ConvertToPermission("Execute Permission");

        ReadEntitlementPermissions := EffectivePermissionsMgt.ConvertToPermission(EntitlementPermissionBuffer."Read Permission");
        InsertEntitlementPermissions := EffectivePermissionsMgt.ConvertToPermission(EntitlementPermissionBuffer."Insert Permission");
        ModifyEntitlementPermissions := EffectivePermissionsMgt.ConvertToPermission(EntitlementPermissionBuffer."Modify Permission");
        DeleteEntitlementPermissions := EffectivePermissionsMgt.ConvertToPermission(EntitlementPermissionBuffer."Delete Permission");
        ExecuteEntitlementPermissions := EffectivePermissionsMgt.ConvertToPermission(EntitlementPermissionBuffer."Execute Permission");

        IsSourceEntitlement := (Source = Source::Entitlement);

        ReadPermissionsTxt := EffectivePermissionsMgt.GetPermissionStatus(ReadPermissions, ReadEntitlementPermissions, IsSourceEntitlement);
        InsertPermissionsTxt := EffectivePermissionsMgt.GetPermissionStatus(InsertPermissions, InsertEntitlementPermissions, IsSourceEntitlement);
        ModifyPermissionsTxt := EffectivePermissionsMgt.GetPermissionStatus(ModifyPermissions, ModifyEntitlementPermissions, IsSourceEntitlement);
        DeletePermissionsTxt := EffectivePermissionsMgt.GetPermissionStatus(DeletePermissions, DeleteEntitlementPermissions, IsSourceEntitlement);
        ExecutePermissionsTxt := EffectivePermissionsMgt.GetPermissionStatus(ExecutePermissions, ExecuteEntitlementPermissions, IsSourceEntitlement);

        CurrPage.Update(false);
    end;

    procedure SetRecordAndRefresh(PassedUserID: Guid; PassedCompanyName: Text[50]; CurrentObjectType: Option; CurrentObjectID: Integer)
    var
        TempPermissionBuffer: Record "Permission Buffer" temporary;
        Permission: Record Permission;
        EffectivePermissionsMgt: Codeunit "Effective Permissions Mgt.";
    begin
        EffectivePermissionsMgt.PopulatePermissionBuffer(TempPermissionBuffer, PassedUserID, PassedCompanyName,
          CurrentObjectType, CurrentObjectID);

        DeleteAll();

        if TempPermissionBuffer.FindSet then
            repeat
                Rec := TempPermissionBuffer;
                Insert;
                if TempPermissionBuffer.Source = TempPermissionBuffer.Source::Entitlement then
                    EntitlementPermissionBuffer := TempPermissionBuffer;
            until TempPermissionBuffer.Next = 0;

        CurrObjectType := CurrentObjectType;
        CurrObjectID := CurrentObjectID;
        CurrUserID := PassedUserID;
        IsTableData := CurrObjectType = Permission."Object Type"::"Table Data";

        CurrPage.Update(false);
    end;
}

