codeunit 9004 "User Grp. Perm. Subscribers"
{
    var
        NullAppIDErr: Label 'Records in the User Group Permission Set table must have a non-empty App ID.';

    [EventSubscriber(ObjectType::Table, Database::"User Group", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure DeleteUserGroupPermissionSetsOnDeleteUserGroup(var Rec: Record "User Group"; RunTrigger: Boolean)
    var
        UserGroupPermissionSet: Record "User Group Permission Set";
    begin
        UserGroupPermissionSet.SetRange("User Group Code", Rec.Code);
        UserGroupPermissionSet.DeleteAll(true);
        Rec.Find;
    end;

    [EventSubscriber(ObjectType::Table, Database::"User Group Permission Set", 'OnBeforeInsertEvent', '', false, false)]
    local procedure AddUserGroupAccessControlOnInsertUserGroupPermissionSet(var Rec: Record "User Group Permission Set"; RunTrigger: Boolean)
    var
        UserGroupAccessControl: Record "User Group Access Control";
        AggregatePermissionSet: Record "Aggregate Permission Set";
    begin
        if IsNullGuid(Rec."App ID") then
            if not (Rec."Role ID" in ['SUPER', 'SECURITY']) then begin
                AggregatePermissionSet.SetRange("Role ID", Rec."Role ID");
                if AggregatePermissionSet.FindFirst() then
                    Rec."App ID" := AggregatePermissionSet."App ID"
                else
                    Error(NullAppIDErr);
            end;

        UserGroupAccessControl.AddUserGroupPermissionSet(Rec."User Group Code", Rec."Role ID", Rec."App ID", Rec.Scope);
    end;

    [EventSubscriber(ObjectType::Table, Database::"User Group Permission Set", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure RemoveUserGroupAccessControlOnDeleteUserGroupPermissionSet(var Rec: Record "User Group Permission Set"; RunTrigger: Boolean)
    var
        UserGroupAccessControl: Record "User Group Access Control";
    begin
        UserGroupAccessControl.RemoveUserGroupPermissionSet(Rec."User Group Code", Rec."Role ID", Rec."App ID", Rec.Scope);
    end;

    [EventSubscriber(ObjectType::Table, Database::"User Group Permission Set", 'OnBeforeRenameEvent', '', false, false)]
    local procedure ReAddUserGroupAccessControlOnRenameUserGroupPermissionSet(var Rec: Record "User Group Permission Set"; var xRec: Record "User Group Permission Set"; RunTrigger: Boolean)
    var
        UserGroupAccessControl: Record "User Group Access Control";
    begin
        UserGroupAccessControl.RemoveUserGroupPermissionSet(xRec."User Group Code", xRec."Role ID", xRec."App ID", xRec.Scope);
        UserGroupAccessControl.AddUserGroupPermissionSet(Rec."User Group Code", Rec."Role ID", Rec."App ID", Rec.Scope);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tenant Permission Set", 'OnAfterRenameEvent', '', false, false)]
    local procedure OnAfterPermissionSetRename(var Rec: Record "Tenant Permission Set"; var xRec: Record "Tenant Permission Set"; RunTrigger: Boolean)
    var
        UserGroupPermissionSet: Record "User Group Permission Set";
    begin
        UserGroupPermissionSet.SetRange("Role ID", xRec."Role ID");
        if not UserGroupPermissionSet.FindSet() then
            exit;

        repeat
            UserGroupPermissionSet.Rename(UserGroupPermissionSet."User Group Code", Rec."Role ID", UserGroupPermissionSet.Scope, UserGroupPermissionSet."App ID");
        until UserGroupPermissionSet.Next() = 0;
    end;
}

