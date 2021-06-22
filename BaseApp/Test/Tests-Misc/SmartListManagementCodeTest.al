codeunit 138891 "SmartList Management Code Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SmartList Designer]
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBulkAssignGroup()
    var
        testHelper: DotNet DesignedQueryTestHelper;
        managementCodeunit: Codeunit "SmartList Mgmt";
        queryManagement: Record "Designed Query Management";
    begin
        // [SCENARIO] Assigning one or more queries to a group
        testHelper := testHelper.DesignedQueryTestHelper();
        testHelper.Save(CreateGuid(), 'Q1', 'D1');
        testHelper.Save(CreateGuid(), 'Q2', 'D2');
        testHelper.Save(CreateGuid(), 'Q3', 'D3');

        // Make sure setting group operates only on the specified (filtered) records
        queryManagement.Init();
        queryManagement.SetFilter("Object Name", '%1|%2', 'Q1', 'Q3');
        managementCodeunit.BulkAssignGroup(queryManagement, 'G1');

        queryManagement.Reset();
        queryManagement.FindSet();
        Assert.AreEqual('G1', queryManagement.Group, 'New group');

        queryManagement.Next();
        Assert.AreEqual('', queryManagement.Group, 'Empty group');

        queryManagement.Next();
        Assert.AreEqual('G1', queryManagement.Group, 'New group');

        // Make sure overwriting works as expected
        queryManagement.SetFilter("Object Name", '%1|%2', 'Q1', 'Q2');
        managementCodeunit.BulkAssignGroup(queryManagement, 'G2');

        queryManagement.Reset();
        queryManagement.FindSet();
        Assert.AreEqual('G2', queryManagement.Group, 'Overwritten group');

        queryManagement.Next();
        Assert.AreEqual('G2', queryManagement.Group, 'New group');

        queryManagement.Next();
        Assert.AreEqual('G1', queryManagement.Group, 'Old group');

        testHelper.DeleteAll();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBulkAddPermissions()
    var
        count: Integer;
        testHelper: DotNet DesignedQueryTestHelper;
        managementCodeunit: Codeunit "SmartList Mgmt";
        queryManagement: Record "Designed Query Management";
        permissionSet: Record "Tenant Permission Set";
        permissionSetBuffer: Record "Permission Set Buffer" temporary;
        permissions: Record "Designed Query Permission";
    begin
        // [SCENARIO] Adding one or more queries to one or more permission sets
        testHelper := testHelper.DesignedQueryTestHelper();
        testHelper.Save(CreateGuid(), 'Q1', 'D1');
        testHelper.Save(CreateGuid(), 'Q2', 'D2');
        testHelper.Save(CreateGuid(), 'Q3', 'D3');

        permissionSet.Init();
        queryManagement.Init();
        permissionSetBuffer.Init();
        permissions.Init();

        EnsurePermissionSetExists('PS1');
        EnsurePermissionSetExists('PS2');
        EnsurePermissionSetExists('PS3');

        permissionSetBuffer.FillRecordBuffer();

        queryManagement.SetFilter("Object Name", '%1|%2', 'Q1', 'Q3');
        permissionSetBuffer.SetFilter("Role ID", '%1|%2', 'PS1', 'PS3');
        managementCodeunit.BulkAddQueryPermissions(queryManagement, permissionSetBuffer);

        // Safe no-op if already defined
        managementCodeunit.BulkAddQueryPermissions(queryManagement, permissionSetBuffer);

        Assert.RecordCount(permissions, 4);

        permissions.SetFilter("Role ID", '%1', 'PS1');
        Assert.RecordCount(permissions, 2);

        permissions.SetFilter("Role ID", '%1', 'PS2');
        Assert.RecordCount(permissions, 0);

        permissions.SetFilter("Role ID", '%1', 'PS3');
        Assert.RecordCount(permissions, 2);

        permissions.DeleteAll();
        testHelper.DeleteAll();
        DeletePermissionSet('PS1');
        DeletePermissionSet('PS2');
        DeletePermissionSet('PS3');
    end;

    local procedure EnsurePermissionSetExists(RoleId: Text)
    var
        permissionSet: Record "Tenant Permission Set";
    begin
        permissionSet.Init();
        if not permissionSet.Get('00000000-0000-0000-0000-000000000000', RoleId) then begin
            permissionSet."Role ID" := RoleId;
            permissionSet.Name := RoleId;
            permissionSet.Insert();
        end;
    end;

    local procedure DeletePermissionSet(RoleId: Text)
    var
        permissionSet: Record "Tenant Permission Set";
    begin
        permissionSet.Init();
        permissionSet.Get('00000000-0000-0000-0000-000000000000', RoleId);
        permissionSet.Delete();
    end;

    var
        Assert: Codeunit Assert;
}