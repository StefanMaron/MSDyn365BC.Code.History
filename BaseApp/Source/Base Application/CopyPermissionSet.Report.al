report 9802 "Copy Permission Set"
{
    Caption = 'Copy Permission Set';
    Permissions = TableData "Permission Set Link" = i;
    ProcessingOnly = true;

    dataset
    {
        dataitem(SourceAggregatePermissionSet; "Aggregate Permission Set")
        {
            DataItemTableView = SORTING(Scope, "App ID", "Role ID");

            trigger OnAfterGetRecord()
            var
                SourcePermission: Record Permission;
                SourceTenantPermission: Record "Tenant Permission";
                PermissionSetLink: Record "Permission Set Link";
                SourcePermissionSet: Record "Permission Set";
            begin
                CreateNewTenantPermissionSet(InputRoleID, Name);

                case Scope of
                    Scope::System:
                        begin
                            SourcePermission.SetRange("Role ID", "Role ID");
                            if not SourcePermission.FindSet then
                                exit;
                            repeat
                                CopyPermissionToNewTenantPermission(InputRoleID, SourcePermission);
                            until SourcePermission.Next = 0;
                            if CreateLink then begin
                                PermissionSetLink.Init();
                                PermissionSetLink."Permission Set ID" := SourcePermission."Role ID";
                                PermissionSetLink."Linked Permission Set ID" := InputRoleID;
                                SourcePermissionSet.Get("Role ID");
                                PermissionSetLink."Source Hash" := SourcePermissionSet.Hash;
                                PermissionSetLink.Insert();
                            end;
                        end;
                    Scope::Tenant:
                        begin
                            SourceTenantPermission.SetRange("App ID", "App ID");
                            SourceTenantPermission.SetRange("Role ID", "Role ID");
                            if SourceTenantPermission.FindSet then
                                repeat
                                    CopyTenantPermissionToNewTenantPermission(InputRoleID, SourceTenantPermission);
                                until SourceTenantPermission.Next = 0;
                        end;
                end;
            end;

            trigger OnPreDataItem()
            begin
                AssertTargetPermissionSetRoleIDNotEmpty(InputRoleID);
                AssertTargetPermissionSetRoleIDNotExisting(InputRoleID);
                AssertSourcePermissionSetRoleIDExists(SourceAggregatePermissionSet);
                AssertSourcePermissionSetRoleIDOnlyOne(SourceAggregatePermissionSet);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(NewPermissionSet; InputRoleID)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Permission Set';
                        NotBlank = true;
                        ToolTip = 'Specifies the name of the new permission set after copying.';
                    }
                    field(CreateLink; CreateLink)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Notify on Changed Permission Set';
                        Enabled = IsCreateLinkEnabled;
                        ToolTip = 'Specifies if you want to be notified when the original System permission set is changed. Note: This option is only enabled if the related notification is enabled.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        var
            TypeHelper: Codeunit "Type Helper";
            PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
            RecordRef: RecordRef;
            FieldRef: FieldRef;
            IsScopeSystem: Boolean;
        begin
            RecordRef.GetTable(SourceAggregatePermissionSet);
            FieldRef := RecordRef.Field(SourceAggregatePermissionSet.FieldNo(Scope));
            IsScopeSystem :=
              TypeHelper.GetOptionNo(SourceAggregatePermissionSet.GetFilter(Scope), FieldRef.OptionMembers) =
              SourceAggregatePermissionSet.Scope::System;
            IsCreateLinkEnabled := IsScopeSystem and PermissionPagesMgt.AppDbPermissionChangedNotificationEnabled;
            // defaulting value of flag
            CreateLink := IsCreateLinkEnabled;
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        Message(CopySuccessMsg, InputRoleID);
    end;

    trigger OnPreReport()
    var
        PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
    begin
        PermissionPagesMgt.DisallowEditingPermissionSetsForNonAdminUsers;
    end;

    var
        InputRoleID: Code[20];
        CopySuccessMsg: Label 'New permission set, %1, has been created.', Comment = 'New permission set, D365 Basic Set, has been created.';
        MissingSourceErr: Label 'There is no permission set to copy from.';
        MultipleSourcesErr: Label 'You can only copy one permission set at a time.';
        TargetExistsErr: Label 'The new permission set already exists.';
        TargetNameMissingErr: Label 'You must specify a name for the new permission set.';
        [InDataSet]
        CreateLink: Boolean;
        [InDataSet]
        IsCreateLinkEnabled: Boolean;

    procedure GetNewRoleID(): Code[20]
    begin
        exit(InputRoleID);
    end;

    local procedure AssertTargetPermissionSetRoleIDNotEmpty(TargetPermissionSetRoleID: Code[20])
    begin
        if TargetPermissionSetRoleID = '' then
            Error(TargetNameMissingErr);
    end;

    local procedure AssertTargetPermissionSetRoleIDNotExisting(TargetPermissionSetRoleID: Code[20])
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
    begin
        AggregatePermissionSet.SetRange("Role ID", TargetPermissionSetRoleID);
        if not AggregatePermissionSet.IsEmpty then
            Error(TargetExistsErr);
    end;

    local procedure AssertSourcePermissionSetRoleIDExists(var FromAggregatePermissionSet: Record "Aggregate Permission Set")
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
    begin
        AggregatePermissionSet.CopyFilters(FromAggregatePermissionSet);
        if AggregatePermissionSet.IsEmpty then
            Error(MissingSourceErr);
    end;

    local procedure AssertSourcePermissionSetRoleIDOnlyOne(var FromAggregatePermissionSet: Record "Aggregate Permission Set")
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
    begin
        AggregatePermissionSet.CopyFilters(FromAggregatePermissionSet);
        if AggregatePermissionSet.Count > 1 then
            Error(MultipleSourcesErr);
    end;

    local procedure CreateNewTenantPermissionSet(NewRoleID: Code[20]; FromAggregatePermissionSetName: Text[30])
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        ZeroGUID: Guid;
    begin
        if TenantPermissionSet.Get(ZeroGUID, NewRoleID) then
            exit;

        TenantPermissionSet.Init();
        TenantPermissionSet."App ID" := ZeroGUID;
        TenantPermissionSet."Role ID" := NewRoleID;
        TenantPermissionSet.Name := FromAggregatePermissionSetName;
        TenantPermissionSet.Insert();
    end;

    local procedure CopyPermissionToNewTenantPermission(NewRoleID: Code[20]; FromPermission: Record Permission)
    var
        TenantPermission: Record "Tenant Permission";
        ZeroGUID: Guid;
    begin
        if TenantPermission.Get(ZeroGUID, NewRoleID, FromPermission."Object Type", FromPermission."Object ID") then
            exit;

        TenantPermission.Init();
        TenantPermission."App ID" := ZeroGUID;
        TenantPermission."Role ID" := NewRoleID;
        TenantPermission."Object Type" := FromPermission."Object Type";
        TenantPermission."Object ID" := FromPermission."Object ID";
        TenantPermission."Read Permission" := FromPermission."Read Permission";
        TenantPermission."Insert Permission" := FromPermission."Insert Permission";
        TenantPermission."Modify Permission" := FromPermission."Modify Permission";
        TenantPermission."Delete Permission" := FromPermission."Delete Permission";
        TenantPermission."Execute Permission" := FromPermission."Execute Permission";
        TenantPermission."Security Filter" := FromPermission."Security Filter";
        TenantPermission.Insert();
    end;

    local procedure CopyTenantPermissionToNewTenantPermission(NewRoleID: Code[20]; FromTenantPermission: Record "Tenant Permission")
    var
        TenantPermission: Record "Tenant Permission";
        ZeroGUID: Guid;
    begin
        if TenantPermission.Get(
             FromTenantPermission."App ID", NewRoleID, FromTenantPermission."Object Type", FromTenantPermission."Object ID")
        then
            exit;

        TenantPermission := FromTenantPermission;
        TenantPermission."App ID" := ZeroGUID;
        TenantPermission."Role ID" := NewRoleID;
        TenantPermission.Insert();
    end;
}

