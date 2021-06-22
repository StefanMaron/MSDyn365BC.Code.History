codeunit 9004 "User Grp. Perm. Subscribers"
{

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Table, 9000, 'OnBeforeDeleteEvent', '', false, false)]
    [Scope('OnPrem')]
    procedure DeleteUserGroupPermissionSetsOnDeleteUserGroup(var Rec: Record "User Group"; RunTrigger: Boolean)
    var
        UserGroupPermissionSet: Record "User Group Permission Set";
    begin
        UserGroupPermissionSet.SetRange("User Group Code", Rec.Code);
        UserGroupPermissionSet.DeleteAll(true);
        Rec.Find;
    end;

    [EventSubscriber(ObjectType::Table, 9003, 'OnBeforeInsertEvent', '', false, false)]
    [Scope('OnPrem')]
    procedure AddUserGroupAccessControlOnInsertUserGroupPermissionSet(var Rec: Record "User Group Permission Set"; RunTrigger: Boolean)
    var
        UserGroupAccessControl: Record "User Group Access Control";
    begin
        UserGroupAccessControl.AddUserGroupPermissionSet(Rec."User Group Code", Rec."Role ID", Rec."App ID", Rec.Scope);
    end;

    [EventSubscriber(ObjectType::Table, 9003, 'OnBeforeDeleteEvent', '', false, false)]
    [Scope('OnPrem')]
    procedure RemoveUserGroupAccessControlOnDeleteUserGroupPermissionSet(var Rec: Record "User Group Permission Set"; RunTrigger: Boolean)
    var
        UserGroupAccessControl: Record "User Group Access Control";
    begin
        UserGroupAccessControl.RemoveUserGroupPermissionSet(Rec."User Group Code", Rec."Role ID", Rec."App ID", Rec.Scope);
    end;

    [EventSubscriber(ObjectType::Table, 9003, 'OnBeforeRenameEvent', '', false, false)]
    [Scope('OnPrem')]
    procedure ReAddUserGroupAccessControlOnRenameUserGroupPermissionSet(var Rec: Record "User Group Permission Set"; var xRec: Record "User Group Permission Set"; RunTrigger: Boolean)
    var
        UserGroupAccessControl: Record "User Group Access Control";
    begin
        UserGroupAccessControl.RemoveUserGroupPermissionSet(xRec."User Group Code", xRec."Role ID", xRec."App ID", xRec.Scope);
        UserGroupAccessControl.AddUserGroupPermissionSet(Rec."User Group Code", Rec."Role ID", Rec."App ID", Rec.Scope);
    end;
}

