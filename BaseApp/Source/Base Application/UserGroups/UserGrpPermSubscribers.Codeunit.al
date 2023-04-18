#if not CLEAN22
codeunit 9004 "User Grp. Perm. Subscribers"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'The user groups functionality is deprecated.';
    ObsoleteTag = '22.0';

    var
        InvalidPermissionSetErr: Label 'User Group Permission Set table can only reference permission sets present in the system.';

    [EventSubscriber(ObjectType::Table, Database::"User Group", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure DeleteUserGroupPermissionSetsOnDeleteUserGroup(var Rec: Record "User Group"; RunTrigger: Boolean)
    var
        UserGroupPermissionSet: Record "User Group Permission Set";
    begin
        if Rec.IsTemporary() then
            exit;

        UserGroupPermissionSet.SetRange("User Group Code", Rec.Code);
        UserGroupPermissionSet.DeleteAll(true);
        Rec.Find();
    end;

    [EventSubscriber(ObjectType::Table, Database::"User Group Permission Set", 'OnBeforeInsertEvent', '', false, false)]
    local procedure AddUserGroupAccessControlOnInsertUserGroupPermissionSet(var Rec: Record "User Group Permission Set"; RunTrigger: Boolean)
    var
        UserGroupAccessControl: Record "User Group Access Control";
    begin
        if Rec.IsTemporary() then
            exit;

        Rec."App ID" := GetAppId(Rec);

        UserGroupAccessControl.AddUserGroupPermissionSet(Rec."User Group Code", Rec."Role ID", Rec."App ID", Rec.Scope);
    end;

    [EventSubscriber(ObjectType::Table, Database::"User Group Permission Set", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure RemoveUserGroupAccessControlOnDeleteUserGroupPermissionSet(var Rec: Record "User Group Permission Set"; RunTrigger: Boolean)
    var
        UserGroupAccessControl: Record "User Group Access Control";
    begin
        if Rec.IsTemporary() then
            exit;

        UserGroupAccessControl.RemoveUserGroupPermissionSet(Rec."User Group Code", Rec."Role ID", Rec."App ID", Rec.Scope);
    end;

    [EventSubscriber(ObjectType::Table, Database::"User Group Permission Set", 'OnBeforeRenameEvent', '', false, false)]
    local procedure ReAddUserGroupAccessControlOnRenameUserGroupPermissionSet(var Rec: Record "User Group Permission Set"; var xRec: Record "User Group Permission Set"; RunTrigger: Boolean)
    var
        UserGroupAccessControl: Record "User Group Access Control";
    begin
        if Rec.IsTemporary() then
            exit;

        Rec."App ID" := GetAppId(Rec);

        UserGroupAccessControl.RemoveUserGroupPermissionSet(xRec."User Group Code", xRec."Role ID", xRec."App ID", xRec.Scope);
        UserGroupAccessControl.AddUserGroupPermissionSet(Rec."User Group Code", Rec."Role ID", Rec."App ID", Rec.Scope);
    end;

    [EventSubscriber(ObjectType::Table, Database::"User Group Permission Set", 'OnBeforeModifyEvent', '', false, false)]
    local procedure ReAddUserGroupAccessControlOnModifyUserGroupPermissionSet(var Rec: Record "User Group Permission Set"; var xRec: Record "User Group Permission Set"; RunTrigger: Boolean)
    var
        UserGroupAccessControl: Record "User Group Access Control";
    begin
        if Rec.IsTemporary() then
            exit;

        Rec."App ID" := GetAppId(Rec);

        UserGroupAccessControl.RemoveUserGroupPermissionSet(xRec."User Group Code", xRec."Role ID", xRec."App ID", xRec.Scope);
        UserGroupAccessControl.AddUserGroupPermissionSet(Rec."User Group Code", Rec."Role ID", Rec."App ID", Rec.Scope);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tenant Permission Set", 'OnAfterRenameEvent', '', false, false)]
    local procedure OnAfterPermissionSetRename(var Rec: Record "Tenant Permission Set"; var xRec: Record "Tenant Permission Set"; RunTrigger: Boolean)
    var
        UserGroupPermissionSet: Record "User Group Permission Set";
    begin
        if Rec.IsTemporary() then
            exit;

        UserGroupPermissionSet.SetRange("Role ID", xRec."Role ID");
        if not UserGroupPermissionSet.FindSet() then
            exit;

        repeat
            UserGroupPermissionSet.Rename(UserGroupPermissionSet."User Group Code", Rec."Role ID", UserGroupPermissionSet.Scope, UserGroupPermissionSet."App ID");
        until UserGroupPermissionSet.Next() = 0;
    end;

    local procedure GetAppId(var UserGroupPermissionSet: Record "User Group Permission Set"): Guid
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        ServerSetting: Codeunit "Server Setting";
        NullGuid: Guid;
        Skip: Boolean;
    begin
        OnBeforeGetAppId(Skip); // for testing
        if Skip then
            exit;

        // Do not change the App ID is the UsePermissionSetsFromExtensions server setting is set to false
        if not ServerSetting.GetUsePermissionSetsFromExtensions() then
            exit(UserGroupPermissionSet."App ID");

        // If the permission set is a system permission set, it should never have a null guid.
        // As such, ignore any null guid permission set unless SUPER or SECURITY
        if (UserGroupPermissionSet.Scope = UserGroupPermissionSet.Scope::System) and not (UserGroupPermissionSet."Role ID" in ['SUPER', 'SECURITY']) then
            AggregatePermissionSet.SetFilter("App ID", '<>%1', NullGuid);
        AggregatePermissionSet.SetRange("Role ID", UserGroupPermissionSet."Role ID");

        if AggregatePermissionSet.FindFirst() then
            exit(AggregatePermissionSet."App ID")
        else
            Error(InvalidPermissionSetErr);
    end;

    [InternalEvent(false)]
    local procedure OnBeforeGetAppId(var Skip: Boolean)
    begin
    end;
}

#endif