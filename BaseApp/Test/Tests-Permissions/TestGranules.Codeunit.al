codeunit 132532 "Test Granules"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Permissions]
    end;

    var
        Assert: Codeunit Assert;
        TableDataNotInAnyPermissionSetTxt: Label 'Table %1 %2 does not exist in any permission set (read test for resolution). Please add it to a permission set.', Comment = '%1=Table No.,%2=Table Name';
        TableDataNotInLocalPermissionSetTxt: Label 'Table %1 %2 does not exist in the local permission set. Please add it (COD101982).', Comment = '%1=Table No.,%2=Table Name';
        TableDataNotInFullPermissionSetTxt: Label 'Table %1 %2 does not exist in the O365 Full Access permission set. Please add it (COD101982).', Comment = '%1=Table No.,%2=Table Name';
        TableDataOnlyInFullPermissionSetTxt: Label 'Table %1 %2 exists in the O365 Full Access permission set, but not in any other O365 permission set. Each object has to be added to at least one non-O365 FULL ACCESS PS. Please add it (COD101981).', Comment = '%1=Table No.,%2=Table Name';
        PermissionDoesNotExistsTxt: Label 'Table Data with ID %1 exists in permission set %2 but not as an application table (read test for resolution).';
        PermissionNotInPSWithSufficientPermissionsErr: Label 'Insufficient permissions (read test for resolution). Permission %1 "%2" (%3) Role ID %4 and Permissions: Read %5, Insert %6, Modify %7, Delete %8, Execute %9 does not exist with sufficient permissions in Permission Set Role ID %10.';
        PermissionInPSWithSufficientPermissionsErr: Label 'Insufficient permissions (read test for resolution). Permission %1 "%2" (%3) Role ID %4 and Permissions: Read %5, Insert %6, Modify %7, Delete %8, Execute %9 already exists with sufficient permissions in Permission Set Role ID %10.';
        XO365FULLTxt: Label 'D365 FULL ACCESS';
        XO365BUSFULLTxt: Label 'D365 BUS FULL ACCESS';
        XO365EXTENSIONMGTTxt: Label 'D365 EXTENSION MGT';
        XO365PREMIUMBUSTxt: Label 'D365 BUS PREMIUM';
        XCUSTOMERVIEWTxt: Label 'D365 CUSTOMER, VIEW';
        XCUSTOMEREDITTxt: Label 'D365 CUSTOMER, EDIT';
        XO365BACKUPRESTORETxt: Label 'D365 BACKUP/RESTORE';
        XITEMEDITTxt: Label 'D365 ITEM, EDIT';
        XSALESDOCCREATETxt: Label 'D365 SALES DOC, EDIT';
        XSALESDOCPOSTTxt: Label 'D365 SALES DOC, POST';
        XBASICTxt: Label 'D365 BASIC';
        XSETUPTxt: Label 'D365 SETUP';
        XACCOUNTSRECEIVABLETxt: Label 'D365 ACC. RECEIVABLE';
        XJOURNALSEDITTxt: Label 'D365 JOURNALS, EDIT';
        XJOURNALSPOSTTxt: Label 'D365 JOURNALS, POST';
        XACCOUNTSPAYABLETxt: Label 'D365 ACC. PAYABLE';
        XVENDORVIEWTxt: Label 'D365 VENDOR, VIEW';
        XVENDOREDITTxt: Label 'D365 VENDOR, EDIT';
        XSECURITYTxt: Label 'SECURITY', Locked = true;
        XPURCHDOCCREATETxt: Label 'D365 PURCH DOC, EDIT';
        XPURCHDOCPOSTTxt: Label 'D365 PURCH DOC, POST';
        ProfileManagementTok: Label 'D365 PROFILE MGT', Locked = true;
        XLOCALTxt: Label 'LOCAL';
        XFIXEDASSETSVIEWTxt: Label 'D365 FA, VIEW';
        XFIXEDASSETSEDITTxt: Label 'D365 FA, EDIT';
        XTEAMMEMBERTxt: Label 'D365 TEAM MEMBER';
        D365AccountantsTxt: Label 'D365 ACCOUNTANTS';
        UserGroupMissingLocalErr: Label '%1 User Group doesn''t contain %2 permission set.';
        D365PermissionSetPrefixFilterTok: Label 'D365*';
        ReadTok: Label 'D365 READ', Locked = true;
        D365EssentialPermissionSetFilterTok: Label '<>D365PREM*&D365*';
        BasicISVTok: Label 'D365 BASIC ISV', Locked = true;

    [Test]
    [Scope('OnPrem')]
    procedure AllAppObjectsAreInPermissionSet()
    var
        TempTableDataAllObj: Record AllObj temporary;
        TempPermission: Record Permission temporary;
    begin
        // If this test fails, it means that you added a Table but forgot to add it to a permission set
        // To do this, open COD101981 (SaaS W1),COD101982 (SaaS Local) or COD101991 (OnPrem) and add the Object here.
        CopyAllAppTableObjectsToTempBuffer(TempTableDataAllObj);
        CopyAllTablePermissionsToTempBuffer(TempPermission);

        // The AllObj table includes system tables which must be excluded from this check
        TempTableDataAllObj.SetFilter("Object ID", '<2000000000');
        with TempTableDataAllObj do begin
            if FindSet then
                repeat
                    TempPermission.SetRange("Object Type", "Object Type");
                    TempPermission.SetRange("Object ID", "Object ID");
                    Assert.IsFalse(TempPermission.IsEmpty, StrSubstNo(TableDataNotInAnyPermissionSetTxt, "Object ID", "Object Name"));
                until Next = 0;
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllLocalAppObjectsAreInLocalPermissionSet()
    var
        TempTableDataAllObj: Record AllObj temporary;
        TempAllLocalPermission: Record Permission temporary;
    begin
        // If this test fails, it means that you added a local Table but forgot to add it to the local permission set
        // To do this, open COD101982 and add the Object here.
        CopyAllAppTableObjectsToTempBuffer(TempTableDataAllObj);
        RemoveNonLocalObjectsFromObjects(TempTableDataAllObj);
        CopyPSToTemp(TempAllLocalPermission, XLOCALTxt);
        with TempTableDataAllObj do begin
            if FindSet then
                repeat
                    TempAllLocalPermission.SetRange("Object Type", "Object Type");
                    TempAllLocalPermission.SetRange("Object ID", "Object ID");
                    Assert.IsFalse(TempAllLocalPermission.IsEmpty, StrSubstNo(TableDataNotInLocalPermissionSetTxt, "Object ID", "Object Name"));
                until Next = 0;
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllLocalAppObjectsAreInO365FullPermissionSet()
    var
        TempTableDataAllObj: Record AllObj temporary;
        TempAllLocalPermission: Record Permission temporary;
    begin
        // If this test fails, it means that you added a local Table but forgot to add it to the O365 Full Access permission set
        // To do this, open COD101982 and add the Object here.
        CopyAllAppTableObjectsToTempBuffer(TempTableDataAllObj);
        RemoveNonLocalObjectsFromObjects(TempTableDataAllObj);
        CopyPSToTemp(TempAllLocalPermission, XO365FULLTxt);
        with TempTableDataAllObj do begin
            if FindSet then
                repeat
                    TempAllLocalPermission.SetRange("Object Type", "Object Type");
                    TempAllLocalPermission.SetRange("Object ID", "Object ID");
                    Assert.IsFalse(TempAllLocalPermission.IsEmpty, StrSubstNo(TableDataNotInFullPermissionSetTxt, "Object ID", "Object Name"));
                until Next = 0;
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllLocalAppObjectsAreInO365BusFullPermissionSet()
    var
        TempTableDataAllObj: Record AllObj temporary;
        TempAllLocalPermission: Record Permission temporary;
    begin
        // If this test fails, it means that you added a local Table but forgot to add it to the O365 Bus Full Access permission set
        // To do this, open COD101982 and add the Object here.
        CopyAllAppTableObjectsToTempBuffer(TempTableDataAllObj);
        RemoveNonLocalObjectsFromObjects(TempTableDataAllObj);
        CopyPSToTemp(TempAllLocalPermission, XO365BUSFULLTxt);
        with TempTableDataAllObj do begin
            if FindSet then
                repeat
                    TempAllLocalPermission.SetRange("Object Type", "Object Type");
                    TempAllLocalPermission.SetRange("Object ID", "Object ID");
                    Assert.IsFalse(TempAllLocalPermission.IsEmpty, StrSubstNo(TableDataNotInFullPermissionSetTxt, "Object ID", "Object Name"));
                until Next = 0;
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllPermissionsAreObjects()
    var
        TempTableDataAllObj: Record AllObj temporary;
        TempPermission: Record Permission temporary;
    begin
        // If this test fails, it means one of four things:
        // 1. You removed an object: Solution, remove the permission from COD101991 as well
        // 2. You added a permission to an object that does not exist: Solution, fix it in COD101991
        // 3. You added a permission to Demo Tool, Tests or something that we do not ship: Solution, remove it again from COD101991
        // 4. The object referenced should actually be shipped, in that case, modify functions
        // CopyAllAppTableObjectsToTempBuffer and CopyAllTablePermissionsToTempBuffer to contain correct ranges
        CopyAllAppTableObjectsToTempBuffer(TempTableDataAllObj);
        CopyAllTablePermissionsToTempBuffer(TempPermission);
        with TempPermission do begin
            FindSet;
            repeat
                TempTableDataAllObj.SetRange("Object Type", "Object Type");
                TempTableDataAllObj.SetRange("Object ID", "Object ID");
                Assert.IsFalse(TempTableDataAllObj.IsEmpty, StrSubstNo(PermissionDoesNotExistsTxt, "Object ID", "Role ID"));
            until Next = 0;
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllAppObjectsAreInAtLeastOneNonO365FullPermissionSet()
    var
        TempTableDataAllObj: Record AllObj temporary;
        TempPermission: Record Permission temporary;
        O365PermissionSetsList: DotNet GenericList1;
        IsO365PermissionSet: Boolean;
    begin
        // If this test fails, it means that Table is added to O365 FULL ACCESS permission
        // but the table is not added to at least one (non-O365 FULL) Permission Set
        // To fix this, open COD101981 (SaaS W1),COD101982 (SaaS Local)
        // and add the Object to at least one (non-O365 FULL) Permission Set
        O365PermissionSetsList := O365PermissionSetsList.List;
        GetO365PermissionSets(O365PermissionSetsList, false);
        CopyAllAppTableObjectsToTempBuffer(TempTableDataAllObj);
        CopyAllTablePermissionsToTempBuffer(TempPermission);
        with TempTableDataAllObj do begin
            if FindSet then
                repeat
                    TempPermission.SetRange("Object Type", "Object Type");
                    TempPermission.SetRange("Object ID", "Object ID");
                    TempPermission.SetRange("Role ID", XO365FULLTxt);
                    if TempPermission.FindFirst then begin
                        TempPermission.SetRange("Role ID");
                        IsO365PermissionSet := false;
                        if TempPermission.FindSet then
                            repeat
                                if O365PermissionSetsList.Contains(TempPermission."Role ID") then
                                    IsO365PermissionSet := true;
                            until IsO365PermissionSet or (TempPermission.Next = 0);
                        Assert.IsTrue(IsO365PermissionSet, StrSubstNo(TableDataOnlyInFullPermissionSetTxt,
                            "Object ID", "Object Name"));
                    end;
                until Next = 0;
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllD365PermissionsAreInD365PremiumBus()
    var
        TempAllO365Permission: Record Permission temporary;
        PermissionSet: Record "Permission Set";
    begin
        // This test verifies that all Permissions in the O365 Permission sets are also added to the 'D365 BUS PREMIUM' Permission Set with
        // at least the same amount of permissions (read, modify, insert, delete, execute), excluding security and extension management.
        // If this test fails, it means you added a new permission to one of the permission sets prefixed with D365.
        // Solution: Add the new permission to the O365 Premium Permission set as well (if you just updated a permission, make the same update in 'D365 BUS PREMIUM').

        PermissionSet.SetFilter("Role ID", D365PermissionSetPrefixFilterTok);
        PermissionSet.FindSet;
        repeat
            if not (PermissionSet."Role ID" in [XO365FULLTxt, D365AccountantsTxt, XO365EXTENSIONMGTTxt, XO365BACKUPRESTORETxt, ProfileManagementTok]) then
                CopyPSToTemp(TempAllO365Permission, PermissionSet."Role ID");
        until PermissionSet.Next = 0;

        CopyPSToTemp(TempAllO365Permission, XLOCALTxt);

        VerifyTempPSinPS(TempAllO365Permission, XO365PREMIUMBUSTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllO365PermissionsAreInO365BusFull()
    var
        TempAllO365Permission: Record Permission temporary;
        PermissionSet: Record "Permission Set";
    begin
        // This test verifies that all Permissions in the O365 Permission sets are also added to the 'D365 BUS FULL ACCESS' Permission Set with
        // at least the same amount of permissions (read, modify, insert, delete, execute), excluding security and extension management.
        // If this test fails, it means you added a new permission to one of the permission sets prefixed with D365.
        // Solution: Add the new permission to the O365 Full Access Permission set as well (if you just updated a permission, make the same update in 'D365 BUS FULL ACCESS').

        PermissionSet.SetFilter("Role ID", D365EssentialPermissionSetFilterTok);
        PermissionSet.FindSet;
        repeat
            if not (PermissionSet."Role ID" in [XO365FULLTxt, D365AccountantsTxt, XO365EXTENSIONMGTTxt, XO365PREMIUMBUSTxt, ReadTok, XO365BACKUPRESTORETxt, ProfileManagementTok]) then
                CopyPSToTemp(TempAllO365Permission, PermissionSet."Role ID");
        until PermissionSet.Next = 0;

        CopyPSToTemp(TempAllO365Permission, XLOCALTxt);

        VerifyTempPSinPS(TempAllO365Permission, XO365BUSFULLTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllO365PermissionsAreInO365Full()
    var
        TempAllO365Permission: Record Permission temporary;
        PermissionSet: Record "Permission Set";
    begin
        // This test verifies that all Permissions in the O365 Permission sets are also added to the 'D365 FULL ACCESS' Permission Set with
        // at least the same amount of permissions (read, modify, insert, delete, execute). This permission set reflects all permissions in O365.
        // If this test fails, it means you added a new permission to one of the permission sets prefixed with D365.
        // Solution: Add the new permission to the O365 Full Access Permission set as well (if you just updated a permission, make the same update in 'D365 FULL ACCESS').

        PermissionSet.SetFilter("Role ID", D365PermissionSetPrefixFilterTok);
        PermissionSet.FindSet;

        repeat
            if not (PermissionSet."Role ID" in [XO365BACKUPRESTORETxt]) then
                CopyPSToTemp(TempAllO365Permission, PermissionSet."Role ID");
        until PermissionSet.Next = 0;

        CopyPSToTemp(TempAllO365Permission, XSECURITYTxt);
        CopyPSToTemp(TempAllO365Permission, XLOCALTxt);

        VerifyTempPSinPS(TempAllO365Permission, XO365FULLTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure O365PermissionSetHierarchy()
    begin
        // This test verifies the O365 hierarchy. Which is as follows:
        // If this test fails, it means you added a new permission to an O365 permission set.
        // Solution: Update permissions in regard to the permission hierarchy below:
        // "O365 Sales Doc, Edit" (part of) "O365 Sales Doc, Post" (part of) "O365 Acc. Receivable"
        VerifyPSPartOfPS(XSALESDOCCREATETxt, XSALESDOCPOSTTxt);
        VerifyPSPartOfPS(XSALESDOCPOSTTxt, XACCOUNTSRECEIVABLETxt);

        // "O365 Purch Doc, Edit" (part of) "O365 Purch Doc, Post" (part of) "O365 Acc. Payable"
        VerifyPSPartOfPS(XPURCHDOCCREATETxt, XPURCHDOCPOSTTxt);
        VerifyPSPartOfPS(XPURCHDOCPOSTTxt, XACCOUNTSPAYABLETxt);

        // "O365 Vendor, Edit", "O365 Customer, Edit" and "O365 Item" (part of) "O365 Setup"
        VerifyPSPartOfPS(XVENDOREDITTxt, XSETUPTxt);
        VerifyPSPartOfPS(XCUSTOMEREDITTxt, XSETUPTxt);
        VerifyPSPartOfPS(XITEMEDITTxt, XSETUPTxt);

        // "O365 Journals, Edit" (part of) "O365 Journals, Post" (part of) (O365 Acc. Receivable and O365 Acc. Payable)
        VerifyPSPartOfPS(XJOURNALSEDITTxt, XJOURNALSPOSTTxt);
        VerifyPSPartOfPS(XJOURNALSPOSTTxt, XACCOUNTSRECEIVABLETxt);
        VerifyPSPartOfPS(XJOURNALSPOSTTxt, XACCOUNTSPAYABLETxt);

        // "O365 Vendor, View" (part of) "O365 Vendor, Edit"
        VerifyPSPartOfPS(XVENDORVIEWTxt, XVENDOREDITTxt);

        // "O365 Customer, View" (part of) "O365 Customer, Edit"
        VerifyPSPartOfPS(XCUSTOMERVIEWTxt, XCUSTOMEREDITTxt);

        // "O365 Fixed Assets, View" (part of) "O365 Fixed Assets, Edit"
        VerifyPSPartOfPS(XFIXEDASSETSVIEWTxt, XFIXEDASSETSEDITTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure O365PermissionSetIsNotInBasic()
    var
        PermissionSet: Record "Permission Set";
    begin
        // O365 Basic Permissionset is designed to be present in all User Groups except O365 Full Access and O365 Full Bus Access
        // This test verifies that permission added to PS is not already present in O365 Basic PS
        // Solution: Compare newly added permission to the existing O365 Basic permission for the same object
        // In case that permissionset is present delete it

        PermissionSet.SetFilter("Role ID", D365PermissionSetPrefixFilterTok);
        PermissionSet.FindSet;

        repeat
            if not IsComposedPermissionSet(PermissionSet."Role ID") then
                VerifyPSNotPartOfPS(PermissionSet."Role ID", XBASICTxt);
        until PermissionSet.Next = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUserGroupContainLocal()
    var
        UserGroup: Record "User Group";
        UserGroupPermissionSet: Record "User Group Permission Set";
        PermissionSet: Record "Permission Set";
    begin
        // [SCENARIO] All user groups should contain LOCAL permissionsets
        // [GIVEN] Local Permissionset exists(in W1 it doesn't)
        PermissionSet.SetRange("Role ID", XLOCALTxt);
        if not PermissionSet.FindFirst then
            exit;

        // [THEN] All the User groups should contain LOCAL permission set
        UserGroup.FindSet;
        repeat
            UserGroupPermissionSet.SetRange("User Group Code", UserGroup.Code);
            UserGroupPermissionSet.SetRange("Role ID", XLOCALTxt);
            Assert.IsTrue(UserGroupPermissionSet.FindFirst, StrSubstNo(UserGroupMissingLocalErr,
                UserGroup.Code, XLOCALTxt));
        until UserGroup.Next = 0;
    end;

    local procedure CopyAllAppTableObjectsToTempBuffer(var TempTableDataAllObj: Record AllObj temporary)
    var
        AllObj: Record AllObj;
        TableMetadata: Record "Table Metadata";
    begin
        // Add all tabledata into the TempTableDataAllObj
        AllObj.SetRange("Object Type", AllObj."Object Type"::TableData);
        AllObj.FindSet;
        repeat
            TableMetadata.Get(AllObj."Object ID");
            // Do not validate removed tables
            if TableMetadata.ObsoleteState <> TableMetadata.ObsoleteState::Removed then begin
                TempTableDataAllObj := AllObj;
                TempTableDataAllObj.Insert();
            end;
        until AllObj.Next = 0;

        with TempTableDataAllObj do begin
            // Do not validate demo tool, upgrade script, and tests, except CAL Test Tool objects in 130400..130499
            SetRange("Object ID", 101000, 130399);
            DeleteAll();
            SetRange("Object ID", 130500, 199999);
            DeleteAll();
            Reset;
        end;
    end;

    local procedure CopyAllTablePermissionsToTempBuffer(var TempPermission: Record Permission temporary)
    var
        Permission: Record Permission;
        AllObj: Record AllObj;
    begin
        Permission.SetRange("Object Type", Permission."Object Type"::"Table Data");
        Permission.FindSet;
        repeat
            TempPermission := Permission;
            TempPermission.Insert();
        until Permission.Next = 0;

        with TempPermission do begin
            // Do not validate system tables that are not visible to the user
            SetRange("Object ID", 2000000000, 2100000000);
            FindSet;
            repeat
                AllObj.SetRange("Object Type", AllObj."Object Type"::TableData);
                AllObj.SetRange("Object ID", "Object ID");
                if AllObj.IsEmpty then
                    Delete;
            until Next = 0;

            Reset;
            SetRange("Role ID", 'SUPER');
            DeleteAll();
            SetRange("Role ID", 'SUPER (DATA)');
            DeleteAll();
            SetRange("Role ID", 'TEST TABLES');
            DeleteAll();

            Reset;
        end;
    end;

    local procedure VerifyTempPSNotinPS(var BasePermissions: Record Permission; ContainingPSRoleID: Code[20])
    var
        AllObj: Record AllObj;
        ContainingPermission: Record Permission;
    begin
        BasePermissions.FindSet;

        repeat
            ContainingPermission.SetRange("Role ID", ContainingPSRoleID);
            ContainingPermission.SetRange("Object Type", BasePermissions."Object Type");
            ContainingPermission.SetRange("Object ID", BasePermissions."Object ID");
            ContainingPermission.SetRange("Read Permission",
              GetMinAllowedPermission(BasePermissions."Read Permission"),
              GetMaxAllowedPermission(BasePermissions."Read Permission"));
            ContainingPermission.SetRange("Insert Permission",
              GetMinAllowedPermission(BasePermissions."Insert Permission"),
              GetMaxAllowedPermission(BasePermissions."Insert Permission"));
            ContainingPermission.SetRange("Modify Permission",
              GetMinAllowedPermission(BasePermissions."Modify Permission"),
              GetMaxAllowedPermission(BasePermissions."Modify Permission"));
            ContainingPermission.SetRange("Delete Permission",
              GetMinAllowedPermission(BasePermissions."Delete Permission"),
              GetMaxAllowedPermission(BasePermissions."Delete Permission"));
            ContainingPermission.SetRange("Execute Permission",
              GetMinAllowedPermission(BasePermissions."Execute Permission"),
              GetMaxAllowedPermission(BasePermissions."Execute Permission"));
            if not ContainingPermission.IsEmpty then begin
                AllObj.Get(BasePermissions."Object Type", BasePermissions."Object ID");
                Error(PermissionInPSWithSufficientPermissionsErr,
                  BasePermissions."Object Type",
                  AllObj."Object Name",
                  BasePermissions."Object ID",
                  BasePermissions."Role ID",
                  BasePermissions."Read Permission",
                  BasePermissions."Insert Permission",
                  BasePermissions."Modify Permission",
                  BasePermissions."Delete Permission",
                  BasePermissions."Execute Permission",
                  ContainingPSRoleID);
            end;
        until BasePermissions.Next = 0;
    end;

    local procedure VerifyTempPSinPS(var BasePermissions: Record Permission; ContainingPSRoleIDFilter: Code[255])
    var
        AllObj: Record AllObj;
        ContainingPermission: Record Permission;
    begin
        BasePermissions.FindSet;
        repeat
            ContainingPermission.SetFilter("Role ID", ContainingPSRoleIDFilter);
            ContainingPermission.SetRange("Object Type", BasePermissions."Object Type");
            ContainingPermission.SetRange("Object ID", BasePermissions."Object ID");
            ContainingPermission.SetRange("Read Permission",
              GetMinAllowedPermission(BasePermissions."Read Permission"),
              GetMaxAllowedPermission(BasePermissions."Read Permission"));
            ContainingPermission.SetRange("Insert Permission",
              GetMinAllowedPermission(BasePermissions."Insert Permission"),
              GetMaxAllowedPermission(BasePermissions."Insert Permission"));
            ContainingPermission.SetRange("Modify Permission",
              GetMinAllowedPermission(BasePermissions."Modify Permission"),
              GetMaxAllowedPermission(BasePermissions."Modify Permission"));
            ContainingPermission.SetRange("Delete Permission",
              GetMinAllowedPermission(BasePermissions."Delete Permission"),
              GetMaxAllowedPermission(BasePermissions."Delete Permission"));
            ContainingPermission.SetRange("Execute Permission",
              GetMinAllowedPermission(BasePermissions."Execute Permission"),
              GetMaxAllowedPermission(BasePermissions."Execute Permission"));
            if ContainingPermission.IsEmpty then begin
                AllObj.Get(BasePermissions."Object Type", BasePermissions."Object ID");
                Error(PermissionNotInPSWithSufficientPermissionsErr,
                  BasePermissions."Object Type",
                  AllObj."Object Name",
                  BasePermissions."Object ID",
                  BasePermissions."Role ID",
                  BasePermissions."Read Permission",
                  BasePermissions."Insert Permission",
                  BasePermissions."Modify Permission",
                  BasePermissions."Delete Permission",
                  BasePermissions."Execute Permission",
                  ContainingPSRoleIDFilter);
            end;
        until BasePermissions.Next = 0;
    end;

    local procedure VerifyPSPartOfPS(BasePermissionSetRoleID: Code[20]; ContainingPermissionSetRoleID: Code[20])
    var
        TempPermission: Record Permission temporary;
    begin
        CopyPSToTemp(TempPermission, BasePermissionSetRoleID);
        VerifyTempPSinPS(TempPermission, ContainingPermissionSetRoleID);
    end;

    local procedure VerifyPSNotPartOfPS(BasePermissionSetRoleID: Code[20]; ContainingPermissionSetRoleID: Code[20])
    var
        TempPermission: Record Permission temporary;
    begin
        if BasePermissionSetRoleID = ContainingPermissionSetRoleID then
            exit;

        CopyPSToTemp(TempPermission, BasePermissionSetRoleID);
        VerifyTempPSNotinPS(TempPermission, ContainingPermissionSetRoleID);
    end;

    local procedure GetMinAllowedPermission(PermissionOption: Option): Integer
    var
        Permission: Record Permission;
    begin
        if PermissionOption = Permission."Read Permission"::Indirect then
            exit(Permission."Read Permission"::Yes);
        exit(PermissionOption)
    end;

    local procedure GetMaxAllowedPermission(PermissionOption: Option): Integer
    var
        Permission: Record Permission;
    begin
        if PermissionOption = Permission."Read Permission"::Yes then
            exit(Permission."Read Permission"::Yes);
        exit(Permission."Read Permission"::Indirect);
    end;

    local procedure CopyPSToTemp(var TempPermission: Record Permission temporary; FromRoleID: Code[20])
    var
        Permission: Record Permission;
    begin
        Permission.SetRange("Role ID", FromRoleID);
        if Permission.FindSet then
            repeat
                TempPermission := Permission;
                TempPermission.Insert();
            until Permission.Next = 0;
        TempPermission.Reset();
    end;

    local procedure RemoveNonLocalObjectsFromObjects(var TempLocalTableDataAllObj: Record AllObj temporary)
    begin
        // Remove W1 app range
        TempLocalTableDataAllObj.SetRange("Object ID", 1, 9999);
        TempLocalTableDataAllObj.DeleteAll();

        TempLocalTableDataAllObj.SetFilter("Object ID", '>%1', 99000000);
        TempLocalTableDataAllObj.DeleteAll();

        // Semi automated tests and shipped test tool are excluded
        TempLocalTableDataAllObj.SetRange("Object ID", 130400, 130499);
        TempLocalTableDataAllObj.DeleteAll();

        TempLocalTableDataAllObj.Reset();
    end;

    local procedure GetO365PermissionSets(var O365PermissionSetsList: DotNet GenericList1; IncludeComposedPermissionSets: Boolean)
    var
        PermissionSet: Record "Permission Set";
    begin
        PermissionSet.SetFilter("Role ID", D365PermissionSetPrefixFilterTok);
        PermissionSet.FindSet;
        repeat
            if IncludeComposedPermissionSets or not IsComposedPermissionSet(PermissionSet."Role ID") or
               (PermissionSet."Role ID" = XO365BUSFULLTxt)
            then
                O365PermissionSetsList.Add(PermissionSet."Role ID");
        until PermissionSet.Next = 0;

        O365PermissionSetsList.Add(XSECURITYTxt);
        O365PermissionSetsList.Add(XLOCALTxt);
    end;

    local procedure IsComposedPermissionSet(RoleID: Code[20]): Boolean
    begin
        exit(RoleID in [XO365FULLTxt, XO365BUSFULLTxt, XO365PREMIUMBUSTxt, D365AccountantsTxt, ReadTok, XTEAMMEMBERTxt, BasicISVTok])
    end;
}

