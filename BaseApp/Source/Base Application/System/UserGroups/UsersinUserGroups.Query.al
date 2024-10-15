#if not CLEAN22
namespace System.Security.AccessControl;

query 773 "Users in User Groups"
{
    Caption = 'Users in User Groups';
    ObsoleteState = Pending;
    ObsoleteReason = '[220_UserGroups] The user groups functionality is deprecated. Use security groups (Security Group codeunit) or permission sets directly instead. To learn more, go to https://go.microsoft.com/fwlink/?linkid=2245709.';
    ObsoleteTag = '22.0';

    elements
    {
        dataitem(User_Group_Member; "User Group Member")
        {
            column(UserGroupCode; "User Group Code")
            {
            }
            column(NumberOfUsers)
            {
                Method = Count;
            }
        }
    }
}

#endif