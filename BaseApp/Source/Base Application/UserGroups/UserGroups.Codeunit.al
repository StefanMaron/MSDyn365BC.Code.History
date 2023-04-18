#if not CLEAN22
Codeunit 9019 "User Groups"
{
    Permissions = TableData "User Group Member" = d;
    ObsoleteState = Pending;
    ObsoleteReason = 'The user groups functionality is deprecated.';
    ObsoleteTag = '22.0';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Azure AD Plan", 'OnRemoveUserGroupsForUserAndPlan', '', false, false)]
    local procedure OnRemoveUserGroupForUserAndPlan(PlanID: Guid; UserSecurityID: Guid);
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
}

#endif