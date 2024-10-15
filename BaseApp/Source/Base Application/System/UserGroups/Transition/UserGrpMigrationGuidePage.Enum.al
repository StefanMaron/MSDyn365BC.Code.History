#if not CLEAN22
namespace System.Security.AccessControl;

enum 9842 "User Grp. Migration Guide Page"
{
    Extensible = true;
    Access = Public;
    Caption = 'User Groups Migration Guide Page';
    ObsoleteState = Pending;
    ObsoleteReason = '[220_UserGroups] User groups functionality is deprecated. To learn more, go to https://go.microsoft.com/fwlink/?linkid=2245709.';
    ObsoleteTag = '22.0';

    value(0; Blank)
    {
        Caption = 'Blank';
    }

    value(1; Introduction)
    {
        Caption = 'Introduction';
    }

    value(2; "Group Migration Action Selection")
    {
        Caption = 'Group Migration Action Selection';
    }

    value(3; Conclusion)
    {
        Caption = 'Conclusion';
    }
}
#endif