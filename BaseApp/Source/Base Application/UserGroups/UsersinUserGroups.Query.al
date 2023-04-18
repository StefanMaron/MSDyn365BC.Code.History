#if not CLEAN22
query 773 "Users in User Groups"
{
    Caption = 'Users in User Groups';
    ObsoleteState = Pending;
    ObsoleteReason = 'The user groups functionality is deprecated. Use security groups (Security Group codeunit) or permission sets directly instead.';
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