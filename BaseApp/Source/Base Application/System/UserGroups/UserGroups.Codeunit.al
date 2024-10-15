#if not CLEAN22
namespace System.Security.AccessControl;

using System.Azure.Identity;

codeunit 9019 "User Groups"
{
    Permissions = TableData "User Group Member" = d;
    InherentEntitlements = X;
    InherentPermissions = X;
    ObsoleteState = Pending;
    ObsoleteReason = '[220_UserGroups] The user groups functionality is deprecated. To learn more, go to https://go.microsoft.com/fwlink/?linkid=2245709.';
    ObsoleteTag = '22.0';

    [InherentPermissions(PermissionObjectType::TableData, Database::"User Group Member", 'd')]
    local procedure RemoveUserGroupForUserAndPlan(PlanID: Guid; UserSecurityID: Guid)
    var
        UserGroupMember: Record "User Group Member";
        UserGroupPlan: Record "User Group Plan";
    begin
        // Remove related user groups from the user
        UserGroupPlan.SetRange("Plan ID", PlanID);
        if not UserGroupPlan.FindSet() then
            exit; // no user groups to remove from this user

        UserGroupMember.SetRange("User Security ID", UserSecurityID);
        repeat
            UserGroupMember.SetRange("User Group Code", UserGroupPlan."User Group Code");
            UserGroupMember.DeleteAll(true);
        until UserGroupPlan.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Azure AD Plan", 'OnRemoveUserGroupsForUserAndPlan', '', false, false)]
    local procedure OnRemoveUserGroupForUserAndPlan(PlanID: Guid; UserSecurityID: Guid);
    begin
        RemoveUserGroupForUserAndPlan(PlanID, UserSecurityID);
    end;
}

#endif