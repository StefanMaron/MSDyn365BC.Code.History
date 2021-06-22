codeunit 132511 TestTestPermissionTestHelper
{
    Permissions =;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Test Framework] [Permissions] [permissionTestHelper]
    end;

    var
        permissionTestHelper: DotNet PermissionTestHelper;

    [Test]
    [Scope('OnPrem')]
    procedure TestInsertAsSuper()
    var
        TestTableA: Record TestTableA;
        TestTableB: Record TestTableB;
    begin
        TestTableA.Init();

        Clear(TestTableA.IntegerField);

        TestTableA.Insert();

        TestTableB.Init();

        Clear(TestTableB.IntegerField);

        TestTableB.Insert();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInsertAsEffectiveUserShouldSucceed()
    var
        TestTableA: Record TestTableA;
    begin
        Init;
        permissionTestHelper.AddEffectivePermissionSet('ENFORCED SET');

        TestTableA.Init();

        Clear(TestTableA.IntegerField);

        TestTableA.Insert();

        permissionTestHelper.Clear;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIndirectAsEffectiveUser()
    begin
        Init;
        permissionTestHelper.AddEffectivePermissionSet('ENFORCED SET');

        CODEUNIT.Run(CODEUNIT::TestCodeUnitC);

        permissionTestHelper.Clear;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInsertAsEffectiveUserShouldFail()
    var
        TestTableB: Record TestTableB;
    begin
        Init;
        permissionTestHelper.AddEffectivePermissionSet('ENFORCED SET');

        TestTableB.Init();

        Clear(TestTableB.IntegerField);

        asserterror TestTableB.Insert();

        permissionTestHelper.Clear;
    end;

    local procedure Init()
    var
        PermissionSet: Record "Permission Set";
        Permission: Record Permission;
    begin
        if IsNull(permissionTestHelper) then
            permissionTestHelper := permissionTestHelper.PermissionTestHelper;

        permissionTestHelper.Clear;

        with PermissionSet do begin
            if Get('ENFORCED SET') then
                Delete;

            Init;
            "Role ID" := 'ENFORCED SET';
            Name := 'Test';
            Insert;
        end;

        with Permission do begin
            SetRange("Role ID", PermissionSet."Role ID");
            DeleteAll();
            Reset;

            Init;
            "Role ID" := PermissionSet."Role ID";
            "Object ID" := DATABASE::TestTableA;
            "Object Type" := "Object Type"::"Table Data";
            "Read Permission" := "Read Permission"::Yes;
            "Insert Permission" := "Insert Permission"::Yes;
            Insert;

            Init;
            "Role ID" := PermissionSet."Role ID";
            "Object ID" := DATABASE::TestTableC;
            "Object Type" := "Object Type"::"Table Data";
            "Read Permission" := "Read Permission"::Indirect;
            "Insert Permission" := "Insert Permission"::Indirect;
            Insert;

            Init;
            "Role ID" := PermissionSet."Role ID";
            "Object ID" := CODEUNIT::TestCodeUnitC;
            "Object Type" := "Object Type"::Codeunit;
            "Execute Permission" := "Execute Permission"::Yes;
            Insert;

            Init;
            "Role ID" := PermissionSet."Role ID";
            "Object ID" := 0;
            "Object Type" := "Object Type"::Codeunit;
            "Execute Permission" := "Execute Permission"::Yes;
            Insert;
        end;
    end;
}

