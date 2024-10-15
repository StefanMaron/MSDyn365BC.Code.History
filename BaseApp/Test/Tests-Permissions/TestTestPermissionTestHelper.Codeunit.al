codeunit 132511 TestTestPermissionTestHelper
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Test Framework] [Permissions] [permissionTestHelper]
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInsertAsSuper()
    var
        TestTableA: Record TestTableA;
        TestTableB: Record TestTableB;
    begin
        TestTableA.Insert();
        TestTableB.Insert();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInsertAsEffectiveUserShouldSucceed()
    var
        TestTableA: Record TestTableA;
        PermissionTestHelper: DotNet PermissionTestHelper;
    begin
        PermissionTestHelper := PermissionTestHelper.PermissionTestHelper();
        PermissionTestHelper.AddEffectivePermissionSet('ENFORCED SET');

        TestTableA.Insert();

        PermissionTestHelper.Clear();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIndirectAsEffectiveUser()
    var
        PermissionTestHelper: DotNet PermissionTestHelper;
    begin
        PermissionTestHelper := PermissionTestHelper.PermissionTestHelper();
        PermissionTestHelper.AddEffectivePermissionSet('ENFORCED SET');

        CODEUNIT.Run(CODEUNIT::TestCodeUnitC);

        PermissionTestHelper.Clear();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInsertAsEffectiveUserShouldFail()
    var
        TestTableB: Record TestTableB;
        PermissionTestHelper: DotNet PermissionTestHelper;
    begin
        PermissionTestHelper := PermissionTestHelper.PermissionTestHelper();
        PermissionTestHelper.AddEffectivePermissionSet('ENFORCED SET');

        asserterror TestTableB.Insert();

        PermissionTestHelper.Clear();
    end;
}

