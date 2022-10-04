#if not CLEAN21
xmlport 9174 "Import Tenant Permission Sets"
{
    Caption = 'Import Permission Sets';
    Direction = Import;
    Encoding = UTF8;
    PreserveWhiteSpace = true;
    UseRequestPage = true;
    ObsoleteTag = '21.0';
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced with "Import Permission Sets"';

    schema
    {
        textelement(PermissionSets)
        {
            tableelement(TempAggregatePermissionSet; "Aggregate Permission Set")
            {
                MinOccurs = Zero;
                XmlName = 'PermissionSet';
                SourceTableView = sorting(Scope, "App Id", "Role Id");
                UseTemporary = true;
                fieldattribute(AppID; TempAggregatePermissionSet."App ID")
                {
                    Occurrence = Optional;
                }
                fieldattribute(RoleID; TempAggregatePermissionSet."Role ID")
                {
                }
                fieldattribute(RoleName; TempAggregatePermissionSet.Name)
                {
                }
                fieldattribute(Scope; TempAggregatePermissionSet.Scope)
                {
                }
                tableelement(TempPermission; Permission)
                {
                    SourceTableView = sorting("Role Id", "Object Type", "Object Id");
                    LinkFields = "Role ID" = FIELD("Role ID");
                    LinkTable = TempAggregatePermissionSet;
                    MinOccurs = Zero;
                    XmlName = 'Permission';
                    UseTemporary = true;
                    fieldelement(ObjectType; TempPermission."Object Type")
                    {
                    }
                    fieldelement(ObjectID; TempPermission."Object ID")
                    {
                    }
                    fieldelement(ReadPermission; TempPermission."Read Permission")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(InsertPermission; TempPermission."Insert Permission")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(ModifyPermission; TempPermission."Modify Permission")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(DeletePermission; TempPermission."Delete Permission")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(ExecutePermission; TempPermission."Execute Permission")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(SecurityFilter; TempPermission."Security Filter")
                    {
                        MinOccurs = Zero;
                    }

                    trigger OnAfterInitRecord()
                    begin
                        TempPermission."Read Permission" := TempPermission."Read Permission"::" ";
                        TempPermission."Insert Permission" := TempPermission."Insert Permission"::" ";
                        TempPermission."Modify Permission" := TempPermission."Modify Permission"::" ";
                        TempPermission."Delete Permission" := TempPermission."Delete Permission"::" ";
                        TempPermission."Execute Permission" := TempPermission."Execute Permission"::" ";
                    end;

                    trigger OnBeforeInsertRecord()
                    begin
                        if TempAggregatePermissionSet.Scope <> TempAggregatePermissionSet.Scope::System then
                            currXMLport.Skip();
                        if TempPermission.Get(TempPermission."Role ID", TempPermission."Object Type", TempPermission."Object ID") then
                            currXMLport.Skip();

                        SystemPermissionsExist := true;
                    end;
                }

                tableelement(TempTenantPermission; "Tenant Permission")
                {
                    SourceTableView = sorting("App Id", "Role Id", "Object Type", "Object Id");
                    LinkFields = "App ID" = FIELD("App ID"), "Role ID" = FIELD("Role ID");
                    LinkTable = TempAggregatePermissionSet;
                    MinOccurs = Zero;
                    XmlName = 'TenantPermission';
                    UseTemporary = true;
                    fieldelement(ObjectType; TempTenantPermission."Object Type")
                    {
                    }
                    fieldelement(ObjectID; TempTenantPermission."Object ID")
                    {
                    }
                    fieldelement(Type; TempTenantPermission.Type)
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(ReadPermission; TempTenantPermission."Read Permission")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(InsertPermission; TempTenantPermission."Insert Permission")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(ModifyPermission; TempTenantPermission."Modify Permission")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(DeletePermission; TempTenantPermission."Delete Permission")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(ExecutePermission; TempTenantPermission."Execute Permission")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(SecurityFilter; TempTenantPermission."Security Filter")
                    {
                        MinOccurs = Zero;
                    }

                    trigger OnAfterInitRecord()
                    begin
                        TempTenantPermission."Read Permission" := TempTenantPermission."Read Permission"::" ";
                        TempTenantPermission."Insert Permission" := TempTenantPermission."Insert Permission"::" ";
                        TempTenantPermission."Modify Permission" := TempTenantPermission."Modify Permission"::" ";
                        TempTenantPermission."Delete Permission" := TempTenantPermission."Delete Permission"::" ";
                        TempTenantPermission."Execute Permission" := TempTenantPermission."Execute Permission"::" ";
                    end;

                    trigger OnBeforeInsertRecord()
                    begin
                        if TempAggregatePermissionSet.Scope <> TempAggregatePermissionSet.Scope::Tenant then
                            currXMLport.Skip();
                        if TempTenantPermission.Get(TempTenantPermission."App ID", TempTenantPermission."Role ID", TempTenantPermission."Object Type", TempTenantPermission."Object ID") then
                            currXMLport.Skip();
                    end;
                }

                trigger OnBeforeInsertRecord()
                var
                    PermissionSet: Record "Permission Set";
                    TenantPermissionSet: Record "Tenant Permission Set";
                    PermissionSetExists: Boolean;
                begin
                    if TempAggregatePermissionSet.Get(TempAggregatePermissionSet.Scope, TempAggregatePermissionSet."App ID", TempAggregatePermissionSet."Role ID") then
                        currXMLport.Skip();

                    case TempAggregatePermissionSet.Scope of
                        TempAggregatePermissionSet.Scope::System:
                            PermissionSetExists := PermissionSet.Get(TempAggregatePermissionSet."Role ID");
                        TempAggregatePermissionSet.Scope::Tenant:
                            PermissionSetExists := TenantPermissionSet.Get(TempAggregatePermissionSet."App ID", TempAggregatePermissionSet."Role ID");
                    end;
                    if PermissionSetExists then
                        if not UpdatePermissions then
                            Error(PermissionSetAlreadyExistsErr, TempAggregatePermissionSet."Role ID");
                end;
            }
        }
    }

    requestpage
    {

        layout
        {
            area(Content)
            {
                field(UpdatePermissions; UpdatePermissions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Update existing permissions';
                    ToolTip = 'Specifies if the existing permissions will be updated (merged) with the imported ones.';
                }
            }
        }

        actions
        {
        }
    }

    trigger OnPreXmlPort()
    var
        PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
    begin
        PermissionPagesMgt.DisallowEditingPermissionSetsForNonAdminUsers();
        OnAfterOnPreXmlPort(UpdatePermissions);
    end;

    trigger OnPostXmlPort()
    var
        EnvironmentInformation: Codeunit "Environment Information";
        ServerSettings: Codeunit "Server Setting";
        IsOnPrem: Boolean;
    begin
        IsOnPrem := EnvironmentInformation.IsOnPrem();
        if TempAggregatePermissionSet.FindSet() then
            repeat
                case TempAggregatePermissionSet.Scope of
                    TempAggregatePermissionSet.Scope::System:
                        if IsOnPrem then
                            ProcessSystemPermissionSet(TempAggregatePermissionSet);

                    TempAggregatePermissionSet.Scope::Tenant:
                        ProcessTenantPermissionSet(TempAggregatePermissionSet);
                end;
            until TempAggregatePermissionSet.Next() = 0;

        if SystemPermissionsExist and ServerSettings.GetUsePermissionSetsFromExtensions() then
            Message(SystemPermissionSetMsg);
    end;

    procedure SetUpdatePermissions(NewUpdatePermissions: Boolean)
    begin
        UpdatePermissions := NewUpdatePermissions;
    end;

    local procedure ProcessSystemPermissionSet(AggregatePermissionSet: Record "Aggregate Permission Set")
    begin
        TempPermission.SetRange("Role ID", AggregatePermissionSet."Role ID");
        if TempPermission.FindSet() then begin
            InsertSystemPermissionSet(AggregatePermissionSet);
            repeat
                InsertSystemPermission(TempPermission);
            until TempPermission.Next() = 0;
        end;
    end;

    local procedure InsertSystemPermissionSet(AggregatePermissionSet: Record "Aggregate Permission Set")
    var
        PermissionSet: Record "Permission Set";
    begin
        if PermissionSet.Get(AggregatePermissionSet."Role ID") then
            exit;

        PermissionSet.Init();
        PermissionSet."Role ID" := AggregatePermissionSet."Role ID";
        PermissionSet.Name := AggregatePermissionSet.Name;
        PermissionSet.Insert();
    end;

    local procedure InsertSystemPermission(SourcePermission: Record Permission)
    var
        Permission: Record Permission;
        PermissionManager: Codeunit "Permission Manager";
    begin
        if not Permission.Get(SourcePermission."Role ID", SourcePermission."Object Type", SourcePermission."Object ID") then begin
            Permission.Init();
            Permission.TransferFields(SourcePermission);
            Permission.Insert();
        end else begin
            if PermissionManager.IsFirstPermissionHigherThanSecond(SourcePermission."Read Permission", Permission."Read Permission") then
                Permission."Read Permission" := SourcePermission."Read Permission";
            if PermissionManager.IsFirstPermissionHigherThanSecond(SourcePermission."Insert Permission", Permission."Insert Permission") then
                Permission."Insert Permission" := SourcePermission."Insert Permission";
            if PermissionManager.IsFirstPermissionHigherThanSecond(SourcePermission."Modify Permission", Permission."Modify Permission") then
                Permission."Modify Permission" := SourcePermission."Modify Permission";
            if PermissionManager.IsFirstPermissionHigherThanSecond(SourcePermission."Delete Permission", Permission."Delete Permission") then
                Permission."Delete Permission" := SourcePermission."Delete Permission";
            if PermissionManager.IsFirstPermissionHigherThanSecond(SourcePermission."Execute Permission", Permission."Execute Permission") then
                Permission."Execute Permission" := SourcePermission."Execute Permission";
            Permission.Modify();
        end;
    end;

    local procedure ProcessTenantPermissionSet(AggregatePermissionSet: Record "Aggregate Permission Set")
    begin
        TempTenantPermission.SetRange("App ID", AggregatePermissionSet."App ID");
        TempTenantPermission.SetRange("Role ID", AggregatePermissionSet."Role ID");
        if TempTenantPermission.FindSet() then begin
            InsertTenantPermissionSet(AggregatePermissionSet);
            repeat
                InsertTenantPermission(TempTenantPermission);
            until TempTenantPermission.Next() = 0;
        end;
    end;

    local procedure InsertTenantPermissionSet(AggregatePermissionSet: Record "Aggregate Permission Set")
    var
        TenantPermissionSet: Record "Tenant Permission Set";
    begin
        if TenantPermissionSet.Get(AggregatePermissionSet."App ID", AggregatePermissionSet."Role ID") then
            exit;

        TenantPermissionSet.Init();
        TenantPermissionSet."App ID" := AggregatePermissionSet."App ID";
        TenantPermissionSet."Role ID" := AggregatePermissionSet."Role ID";
        TenantPermissionSet.Name := AggregatePermissionSet.Name;
        TenantPermissionSet.Insert();
    end;

    local procedure InsertTenantPermission(SourceTenantPermission: Record "Tenant Permission")
    var
        TenantPermission: Record "Tenant Permission";
        PermissionManager: Codeunit "Permission Manager";
    begin
        if not TenantPermission.Get(SourceTenantPermission."App ID", SourceTenantPermission."Role ID", SourceTenantPermission."Object Type", SourceTenantPermission."Object ID") then begin
            TenantPermission.Init();
            TenantPermission.TransferFields(SourceTenantPermission);
            TenantPermission.Insert();
        end else begin
            if PermissionManager.IsFirstPermissionHigherThanSecond(SourceTenantPermission."Read Permission", TenantPermission."Read Permission") then
                TenantPermission."Read Permission" := SourceTenantPermission."Read Permission";
            if PermissionManager.IsFirstPermissionHigherThanSecond(SourceTenantPermission."Insert Permission", TenantPermission."Insert Permission") then
                TenantPermission."Insert Permission" := SourceTenantPermission."Insert Permission";
            if PermissionManager.IsFirstPermissionHigherThanSecond(SourceTenantPermission."Modify Permission", TenantPermission."Modify Permission") then
                TenantPermission."Modify Permission" := SourceTenantPermission."Modify Permission";
            if PermissionManager.IsFirstPermissionHigherThanSecond(SourceTenantPermission."Delete Permission", TenantPermission."Delete Permission") then
                TenantPermission."Delete Permission" := SourceTenantPermission."Delete Permission";
            if PermissionManager.IsFirstPermissionHigherThanSecond(SourceTenantPermission."Execute Permission", TenantPermission."Execute Permission") then
                TenantPermission."Execute Permission" := SourceTenantPermission."Execute Permission";
            TenantPermission.Modify();
        end;
    end;

    var
        SystemPermissionSetMsg: Label 'You cannot modify system permission sets.';
        PermissionSetAlreadyExistsErr: Label 'Permission set %1 already exists.', Comment = '%1 = Role ID';
        UpdatePermissions: Boolean;
        SystemPermissionsExist: Boolean;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnPreXmlPort(var UpdatePermissions: boolean)
    begin
    end;
}
#endif