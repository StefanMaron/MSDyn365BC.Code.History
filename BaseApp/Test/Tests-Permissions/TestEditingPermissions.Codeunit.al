codeunit 134612 "Test Editing Permissions"
{
    Permissions = TableData "Permission Set Link" = r;
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Permissions]
    end;

    var
        Assert: Codeunit Assert;
        LibraryE2EPlanPermissions: Codeunit "Library - E2E Plan Permissions";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryPermissions: Codeunit "Library - Permissions";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        CopySuccessMsg: Label 'New permission set, %1, has been created.', Comment = 'New permission set, D365 Basic Set, has been created.';
        EditableControlErr: Label '%1 control is editable on %2 page.', Comment = 'Object Type control is editable on Permissions page.';
        EnabledActionErr: Label '%1 control is enabled on %2 page.', Comment = 'Object Type action is enabled on Permissions page.';
        DisabledActionErr: Label '%1 control is disabled on %2 page.', Comment = 'Object Type action is disabled on Permissions page.';
        FieldFilterErr: Label 'Security filter %1 does not have the field filter %2.', Comment = 'Security filter Customer: Chain Name=<>0 does not have the field filter <>100.';
        MissingSourceErr: Label 'There is no permission set to copy from.';
        MultipleSourcesErr: Label 'You can only copy one permission set at a time.';
        TargetExistsErr: Label 'The new permission set already exists.';
        TargetNameMissingErr: Label 'You must specify a name for the new permission set.';
        ZeroGuid: Guid;
        MSPermSetChangedMsg: Label 'One or more System permission sets that you have copied to create your own have changed. //You may want to review the changed permission set in case the changes are relevant for your user-defined permission sets.';
        SecurityFilterErr: Label 'Security filter %1 does not apply to the %2 table.', Comment = 'Security filter Customer: Chain Name=<>0 does not apply to the Vendor table.';
        SecurityFilterExistsErr: Label 'Security filter should not exit.';
        UnsupportedDataTypeErr: Label 'Cannot define a field filter for field %1 whose type is %2.', Comment = 'Cannot define a field filter for field App ID whose type is GUID.';
        CannotEditPermissionSetMsg: Label 'Permission sets of type System and Extension cannot be changed. Only permission sets of type User-Defined can be changed.';
        CannotRenameTenantPermissionSetHavingUsageErr: Label 'You cannot rename a tenant permission set until it is used elsewhere, for example, in permission settings for a user or user group.';

    [Test]
    [Scope('OnPrem')]
    procedure StanCanCreateNewTenantPermissionSets()
    var
        NewPermissionSetName: Text[30];
        NewPermissionSetRoleID: Code[20];
    begin
        Initialize;

        // Setup
        NewPermissionSetRoleID := GenerateRandomTenantPermissionSetRoleID;
        NewPermissionSetName := GenerateRandomTenantPermissionSetName;

        // Exercise
        LibraryE2EPlanPermissions.SetBusinessManagerPlan;
        CreateNewTenantPermissionSetFromPermissionSetsPage(NewPermissionSetRoleID, NewPermissionSetName);

        // Verify
        AssertTenantPermissionSetExists(NewPermissionSetRoleID);
    end;

    [Test]
    [HandlerFunctions('CopyPermissionSetWithNewNameRequestPageHandler,CopyPermissionSetSuccessMessageHandler')]
    [Scope('OnPrem')]
    procedure StanCanCopyPermissionSetsToNewTenantPermissionSets()
    var
        PermissionSetRoleID: Code[20];
        NewPermissionSetRoleID: Code[20];
    begin
        Initialize;

        // Setup
        PermissionSetRoleID := GenerateRandomPermissionSetRoleID;
        NewPermissionSetRoleID := GenerateRandomTenantPermissionSetRoleID;

        LibraryLowerPermissions.SetOutsideO365Scope;
        CreateNewPermissionSet(PermissionSetRoleID);

        // Exercise
        LibraryVariableStorage.Enqueue(NewPermissionSetRoleID); // 1st time is for the request page handler
        // enabled criteria for the option to notify depends on the source being a System permission set
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(NewPermissionSetRoleID); // 2nd time is for the message handler
        LibraryE2EPlanPermissions.SetBusinessManagerPlan;
        CopyPermissionSetToNewTenantPermissionSet(PermissionSetRoleID, ZeroGuid);

        // Verify
        AssertTenantPermissionSetEqualsPermissionSet(NewPermissionSetRoleID, PermissionSetRoleID);
        AssertTenantPermissionsEqualPermissions(NewPermissionSetRoleID, PermissionSetRoleID);
        LibraryVariableStorage.AssertEmpty;
        AssertPermissionSetLinkExistsWithCorrectHash(PermissionSetRoleID, NewPermissionSetRoleID);
    end;

    [Test]
    [HandlerFunctions('CopyPermissionSetWithNewNameRequestPageHandlerWithoutLink,CopyPermissionSetSuccessMessageHandler')]
    [Scope('OnPrem')]
    procedure StanCanCopyPermissionSetsToNewTenantPermissionSetsWithoutCopyingLink()
    var
        PermissionSetRoleID: Code[20];
        NewPermissionSetRoleID: Code[20];
    begin
        Initialize;

        // Setup
        PermissionSetRoleID := GenerateRandomPermissionSetRoleID;
        NewPermissionSetRoleID := GenerateRandomTenantPermissionSetRoleID;

        LibraryLowerPermissions.SetOutsideO365Scope;
        CreateNewPermissionSet(PermissionSetRoleID);

        // Exercise
        LibraryVariableStorage.Enqueue(NewPermissionSetRoleID);
        LibraryE2EPlanPermissions.SetBusinessManagerPlan;
        // enabled criteria for the option to notify depends on the source being a System permission set
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(NewPermissionSetRoleID); // for the message handler
        CopyPermissionSetToNewTenantPermissionSet(PermissionSetRoleID, ZeroGuid);

        // Verify
        AssertTenantPermissionSetEqualsPermissionSet(NewPermissionSetRoleID, PermissionSetRoleID);
        AssertTenantPermissionsEqualPermissions(NewPermissionSetRoleID, PermissionSetRoleID);
        LibraryVariableStorage.AssertEmpty;
        AssertPermissionSetLinkDoesNotExist(PermissionSetRoleID, NewPermissionSetRoleID);
    end;

    [Test]
    [HandlerFunctions('CopyPermissionSetWithNewNameRequestPageHandler,CopyPermissionSetSuccessMessageHandler')]
    [Scope('OnPrem')]
    procedure StanCanCopyExtensionPermissionSetsToNewTenantPermissionSets()
    var
        ExtensionPermissionSetAppID: Guid;
        ExtensionPermissionSetRoleID: Code[20];
        NewPermissionSetRoleID: Code[20];
    begin
        Initialize;

        // Setup
        ExtensionPermissionSetRoleID := GenerateRandomTenantPermissionSetRoleID;
        NewPermissionSetRoleID := GenerateRandomTenantPermissionSetRoleID;

        ExtensionPermissionSetAppID := CreateNewExtensionPermissionSet(ExtensionPermissionSetRoleID);

        // Exercise
        LibraryVariableStorage.Enqueue(NewPermissionSetRoleID); // 1st time is for the request page handler
        // disabled criteria for the option to notify depends on the source being a System permission set
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(NewPermissionSetRoleID); // 2nd time is for the message handler
        LibraryE2EPlanPermissions.SetBusinessManagerPlan;
        CopyPermissionSetToNewTenantPermissionSet(ExtensionPermissionSetRoleID, ExtensionPermissionSetAppID);

        // Verify
        AssertTenantPermissionSetEqualsTenantPermissionSet(
          NewPermissionSetRoleID, ExtensionPermissionSetRoleID, ExtensionPermissionSetAppID);
        AssertTenantPermissionsEqualTenantPermissions(
          NewPermissionSetRoleID, ExtensionPermissionSetRoleID, ExtensionPermissionSetAppID);
        LibraryVariableStorage.AssertEmpty;
        AssertPermissionSetLinkDoesNotExist(ExtensionPermissionSetRoleID, NewPermissionSetRoleID);
    end;

    [Test]
    [HandlerFunctions('AddItemPermissionToTenantPermissionSetPageHandler')]
    [Scope('OnPrem')]
    procedure StanCanEditNewlyCreatedTenantPermissionSets()
    var
        NewPermissionSetRoleID: Code[20];
        NewPermissionTableDataObjectID: Integer;
    begin
        Initialize;

        // Setup
        NewPermissionSetRoleID := GenerateRandomTenantPermissionSetRoleID;
        NewPermissionTableDataObjectID := DATABASE::Item;

        CreateNewTenantPermissionSet(NewPermissionSetRoleID);
        AssertTenantPermissionSetNotContainingTableDataTenantPermission(NewPermissionSetRoleID, NewPermissionTableDataObjectID);

        // Exercise
        LibraryVariableStorage.Enqueue(NewPermissionTableDataObjectID);
        LibraryE2EPlanPermissions.SetBusinessManagerPlan;
        DisplayPermissionsForPermissionSet(NewPermissionSetRoleID);

        // Verify
        AssertTenantPermissionSetContainsTableDataTenantPermission(NewPermissionSetRoleID, NewPermissionTableDataObjectID);
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('CopyPermissionSetWithNewNameRequestPageHandler,CopyPermissionSetSuccessMessageHandler,AddItemPermissionToTenantPermissionSetPageHandler')]
    [Scope('OnPrem')]
    procedure StanCanEditCopiedApplicationPermissionSets()
    var
        PermissionSetRoleID: Code[20];
        NewPermissionSetRoleID: Code[20];
        NewPermissionTableDataObjectID: Integer;
    begin
        Initialize;

        // Setup
        PermissionSetRoleID := GenerateRandomPermissionSetRoleID;
        NewPermissionSetRoleID := GenerateRandomTenantPermissionSetRoleID;
        NewPermissionTableDataObjectID := DATABASE::Item;

        LibraryLowerPermissions.SetOutsideO365Scope;
        CreateNewPermissionSet(PermissionSetRoleID);
        AssertTenantPermissionSetNotContainingTableDataTenantPermission(NewPermissionSetRoleID, NewPermissionTableDataObjectID);
        Commit();

        LibraryVariableStorage.Enqueue(NewPermissionSetRoleID); // 1st time is for the request page handler
        // enabled criteria for the option to notify depends on the source being a System permission set
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(NewPermissionSetRoleID); // 2nd time is for the message handler
        CopyPermissionSetToNewTenantPermissionSet(PermissionSetRoleID, ZeroGuid);

        // Exercise
        LibraryVariableStorage.Enqueue(NewPermissionTableDataObjectID);
        LibraryE2EPlanPermissions.SetBusinessManagerPlan;
        DisplayPermissionsForPermissionSet(NewPermissionSetRoleID);

        // Verify
        AssertTenantPermissionSetContainsTableDataTenantPermission(NewPermissionSetRoleID, NewPermissionTableDataObjectID);
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('CopyPermissionSetWithNewNameRequestPageHandler,CopyPermissionSetSuccessMessageHandler,AddItemPermissionToTenantPermissionSetPageHandler')]
    [Scope('OnPrem')]
    procedure StanCanEditCopiedExtensionPermissionSets()
    var
        ExtensionPermissionSetAppID: Guid;
        ExtensionPermissionSetRoleID: Code[20];
        NewPermissionSetRoleID: Code[20];
        NewPermissionTableDataObjectID: Integer;
    begin
        Initialize;

        // Setup
        ExtensionPermissionSetRoleID := GenerateRandomTenantPermissionSetRoleID;
        NewPermissionSetRoleID := GenerateRandomTenantPermissionSetRoleID;
        NewPermissionTableDataObjectID := DATABASE::Item;

        ExtensionPermissionSetAppID := CreateNewExtensionPermissionSet(ExtensionPermissionSetRoleID);
        AssertTenantPermissionSetNotContainingTableDataTenantPermission(NewPermissionSetRoleID, NewPermissionTableDataObjectID);
        Commit();

        LibraryVariableStorage.Enqueue(NewPermissionSetRoleID); // 1st time is for the request page handler
        // enabled criteria for the option to notify depends on the source being a System permission set
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(NewPermissionSetRoleID); // 2nd time is for the message handler
        CopyPermissionSetToNewTenantPermissionSet(ExtensionPermissionSetRoleID, ExtensionPermissionSetAppID);

        // Exercise
        LibraryVariableStorage.Enqueue(NewPermissionTableDataObjectID);
        LibraryE2EPlanPermissions.SetBusinessManagerPlan;
        DisplayPermissionsForPermissionSet(NewPermissionSetRoleID);

        // Verify
        AssertTenantPermissionSetContainsTableDataTenantPermission(NewPermissionSetRoleID, NewPermissionTableDataObjectID);
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('DisplaySecurityFiltersForTenantPermissionPageHandler,AddNewSecurityFilterToTenantPermissionModalPageHandler')]
    [Scope('OnPrem')]
    procedure StanCanEditNewlyCreatedTenantPermissionSecurityFilters()
    var
        TempTableFilter: Record "Table Filter" temporary;
        NewPermissionSetRoleID: Code[20];
    begin
        Initialize;

        // Setup
        NewPermissionSetRoleID := GenerateRandomTenantPermissionSetRoleID;

        CreateNewTenantPermissionSet(NewPermissionSetRoleID);
        DefineSecurityFilterForTenantPermission(TempTableFilter, NewPermissionSetRoleID);

        AssertTenantPermissionSetMissingSecurityFilterForTenantPermission(NewPermissionSetRoleID, TempTableFilter."Table Number");

        // Exercise
        LibraryVariableStorage.Enqueue(TempTableFilter."Table Number");
        LibraryVariableStorage.Enqueue(TempTableFilter."Field Filter");

        LibraryE2EPlanPermissions.SetBusinessManagerPlan;
        DisplayPermissionsForPermissionSet(NewPermissionSetRoleID);

        // Verify
        AssertTenantPermissionSetHasSecurityFilterForTenantPermission(NewPermissionSetRoleID, TempTableFilter);
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('CopyPermissionSetWithNewNameRequestPageHandler,CopyPermissionSetSuccessMessageHandler,DisplaySecurityFiltersForTenantPermissionPageHandler,AddNewSecurityFilterToTenantPermissionModalPageHandler')]
    [Scope('OnPrem')]
    procedure StanCanEditCopiedApplicationPermissionSecurityFilters()
    var
        TempTableFilter: Record "Table Filter" temporary;
        PermissionSetRoleID: Code[20];
        NewPermissionSetRoleID: Code[20];
    begin
        Initialize;

        // Setup
        PermissionSetRoleID := GenerateRandomPermissionSetRoleID;
        NewPermissionSetRoleID := GenerateRandomTenantPermissionSetRoleID;

        LibraryLowerPermissions.SetOutsideO365Scope;
        CreateNewPermissionSet(PermissionSetRoleID);
        Commit();

        LibraryVariableStorage.Enqueue(NewPermissionSetRoleID); // 1st time is for the request page handler
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(NewPermissionSetRoleID); // 2nd time is for the message handler
        CopyPermissionSetToNewTenantPermissionSet(PermissionSetRoleID, ZeroGuid);

        DefineSecurityFilterForTenantPermission(TempTableFilter, NewPermissionSetRoleID);
        AssertTenantPermissionSetMissingSecurityFilterForTenantPermission(NewPermissionSetRoleID, TempTableFilter."Table Number");

        // Exercise
        LibraryVariableStorage.Enqueue(TempTableFilter."Table Number");
        LibraryVariableStorage.Enqueue(TempTableFilter."Field Filter");

        LibraryE2EPlanPermissions.SetBusinessManagerPlan;
        DisplayPermissionsForPermissionSet(NewPermissionSetRoleID);

        // Verify
        AssertTenantPermissionSetHasSecurityFilterForTenantPermission(NewPermissionSetRoleID, TempTableFilter);
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('CopyPermissionSetWithNewNameRequestPageHandler,CopyPermissionSetSuccessMessageHandler,DisplaySecurityFiltersForTenantPermissionPageHandler,AddNewSecurityFilterToTenantPermissionModalPageHandler')]
    [Scope('OnPrem')]
    procedure StanCanEditCopiedExtensionPermissionSecurityFilters()
    var
        TempTableFilter: Record "Table Filter" temporary;
        ExtensionPermissionSetRoleID: Code[20];
        NewPermissionSetRoleID: Code[20];
        ExtensionPermissionSetAppID: Guid;
    begin
        Initialize;

        // Setup
        ExtensionPermissionSetRoleID := GenerateRandomTenantPermissionSetRoleID;
        NewPermissionSetRoleID := GenerateRandomTenantPermissionSetRoleID;

        ExtensionPermissionSetAppID := CreateNewExtensionPermissionSet(ExtensionPermissionSetRoleID);
        Commit();

        LibraryVariableStorage.Enqueue(NewPermissionSetRoleID); // 1st time is for the request page handler
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(NewPermissionSetRoleID); // 2nd time is for the message handler
        CopyPermissionSetToNewTenantPermissionSet(ExtensionPermissionSetRoleID, ExtensionPermissionSetAppID);

        DefineSecurityFilterForTenantPermission(TempTableFilter, NewPermissionSetRoleID);
        AssertTenantPermissionSetMissingSecurityFilterForTenantPermission(NewPermissionSetRoleID, TempTableFilter."Table Number");

        // Exercise
        LibraryVariableStorage.Enqueue(TempTableFilter."Table Number");
        LibraryVariableStorage.Enqueue(TempTableFilter."Field Filter");

        LibraryE2EPlanPermissions.SetBusinessManagerPlan;
        DisplayPermissionsForPermissionSet(NewPermissionSetRoleID);

        // Verify
        AssertTenantPermissionSetHasSecurityFilterForTenantPermission(NewPermissionSetRoleID, TempTableFilter);
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StanCanDeleteNewlyCreatedTenantPermissionSets()
    var
        NewPermissionSetRoleID: Code[20];
    begin
        Initialize;

        // Setup
        NewPermissionSetRoleID := GenerateRandomTenantPermissionSetRoleID;
        CreateNewTenantPermissionSet(NewPermissionSetRoleID);

        // Exercise
        LibraryE2EPlanPermissions.SetBusinessManagerPlan;
        DeleteExistingTenantPermissionSet(NewPermissionSetRoleID);

        // Verify
        AssertTenantPermissionSetNotExisting(NewPermissionSetRoleID);
    end;

    [Test]
    [HandlerFunctions('CopyPermissionSetWithNewNameRequestPageHandler,CopyPermissionSetSuccessMessageHandler')]
    [Scope('OnPrem')]
    procedure StanCanDeleteCopiedApplicationPermissionSets()
    var
        PermissionSetRoleID: Code[20];
        NewPermissionSetRoleID: Code[20];
    begin
        Initialize;

        // Setup
        PermissionSetRoleID := GenerateRandomPermissionSetRoleID;
        NewPermissionSetRoleID := GenerateRandomTenantPermissionSetRoleID;

        LibraryLowerPermissions.SetOutsideO365Scope;
        CreateNewPermissionSet(PermissionSetRoleID);
        Commit();

        LibraryVariableStorage.Enqueue(NewPermissionSetRoleID); // 1st time is for the request page handler
        // enabled criteria for the option to notify depends on the source being a System permission set
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(NewPermissionSetRoleID); // 2nd time is for the message handler
        CopyPermissionSetToNewTenantPermissionSet(PermissionSetRoleID, ZeroGuid);

        // Exercise
        LibraryE2EPlanPermissions.SetBusinessManagerPlan;
        DeleteExistingTenantPermissionSet(NewPermissionSetRoleID);

        // Verify
        AssertTenantPermissionSetNotExisting(NewPermissionSetRoleID);
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('CopyPermissionSetWithNewNameRequestPageHandler,CopyPermissionSetSuccessMessageHandler')]
    [Scope('OnPrem')]
    procedure StanCanDeleteCopiedExtensionPermissionSets()
    var
        ExtensionPermissionSetRoleID: Code[20];
        NewPermissionSetRoleID: Code[20];
        ExtensionPermissionSetAppID: Guid;
    begin
        Initialize;

        // Setup
        ExtensionPermissionSetRoleID := GenerateRandomTenantPermissionSetRoleID;
        NewPermissionSetRoleID := GenerateRandomTenantPermissionSetRoleID;

        ExtensionPermissionSetAppID := CreateNewExtensionPermissionSet(ExtensionPermissionSetRoleID);
        Commit();

        LibraryVariableStorage.Enqueue(NewPermissionSetRoleID); // 1st time is for the request page handler
        // enabled criteria for the option to notify depends on the source being a System permission set
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(NewPermissionSetRoleID); // 2nd time is for the message handler
        CopyPermissionSetToNewTenantPermissionSet(ExtensionPermissionSetRoleID, ExtensionPermissionSetAppID);

        // Exercise
        LibraryE2EPlanPermissions.SetBusinessManagerPlan;
        DeleteExistingTenantPermissionSet(NewPermissionSetRoleID);

        // Verify
        AssertTenantPermissionSetNotExisting(NewPermissionSetRoleID);
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('CannotAddItemPermissionToPermissionSetPageHandler')]
    [Scope('OnPrem')]
    procedure StanCannotEditApplicationPermissionSets()
    var
        PermissionSetRoleID: Code[20];
        NewPermissionTableDataObjectID: Integer;
    begin
        Initialize;

        // Setup
        PermissionSetRoleID := GenerateRandomPermissionSetRoleID;
        NewPermissionTableDataObjectID := DATABASE::Item;

        LibraryLowerPermissions.SetOutsideO365Scope;
        CreateNewPermissionSet(PermissionSetRoleID);

        // Exercise
        LibraryE2EPlanPermissions.SetBusinessManagerPlan;
        DisplayPermissionsForPermissionSet(PermissionSetRoleID);

        // Verify
        AssertPermissionSetNotContainingTableDataTenantPermission(PermissionSetRoleID, NewPermissionTableDataObjectID);
        AssertPermissionSetNotContainingTableDataPermission(PermissionSetRoleID, NewPermissionTableDataObjectID);
    end;

    [Test]
    [HandlerFunctions('CannotAddItemPermissionToExtensionPermissionSetPageHandler')]
    [Scope('OnPrem')]
    procedure StanCannotEditExtensionPermissionSets()
    var
        ExtensionPermissionSetRoleID: Code[20];
        NewPermissionTableDataObjectID: Integer;
    begin
        Initialize;

        // Setup
        ExtensionPermissionSetRoleID := GenerateRandomTenantPermissionSetRoleID;
        NewPermissionTableDataObjectID := DATABASE::Item;

        CreateNewExtensionPermissionSet(ExtensionPermissionSetRoleID);
        AssertTenantPermissionSetNotContainingTableDataTenantPermission(ExtensionPermissionSetRoleID, NewPermissionTableDataObjectID);

        // Exercise
        LibraryE2EPlanPermissions.SetBusinessManagerPlan;
        DisplayPermissionsForPermissionSet(ExtensionPermissionSetRoleID);

        // Verify
        AssertTenantPermissionSetNotContainingTableDataTenantPermission(ExtensionPermissionSetRoleID, NewPermissionTableDataObjectID);
    end;

    [Test]
    [HandlerFunctions('DisplaySecurityFiltersForPermissionPageHandler,HandleNotificationCannotEditPermissionSets')]
    [Scope('OnPrem')]
    procedure StanCannotEditApplicationPermissionSecurityFilters()
    var
        TempTableFilter: Record "Table Filter" temporary;
        PermissionSetRoleID: Code[20];
    begin
        Initialize;

        // Setup
        PermissionSetRoleID := GenerateRandomPermissionSetRoleID;

        LibraryLowerPermissions.SetOutsideO365Scope;
        CreateNewPermissionSet(PermissionSetRoleID);

        DefineSecurityFilterForPermission(TempTableFilter, PermissionSetRoleID);
        AssertPermissionSetMissingSecurityFilterForPermission(PermissionSetRoleID, TempTableFilter."Table Number");

        // Exercise
        LibraryE2EPlanPermissions.SetBusinessManagerPlan;
        DisplayPermissionsForPermissionSet(PermissionSetRoleID);

        // Verify
        AssertPermissionSetMissingSecurityFilterForPermission(PermissionSetRoleID, TempTableFilter."Table Number");
    end;

    [Test]
    [HandlerFunctions('DisplaySecurityFiltersForTenantPermissionPageHandler,HandleNotificationCannotEditPermissionSets')]
    [Scope('OnPrem')]
    procedure StanCannotEditExtensionPermissionSecurityFilters()
    var
        TempTableFilter: Record "Table Filter" temporary;
        ExtensionPermissionSetRoleID: Code[20];
    begin
        Initialize;

        // Setup
        ExtensionPermissionSetRoleID := GenerateRandomTenantPermissionSetRoleID;

        CreateNewExtensionPermissionSet(ExtensionPermissionSetRoleID);

        DefineSecurityFilterForTenantPermission(TempTableFilter, ExtensionPermissionSetRoleID);
        AssertTenantPermissionSetMissingSecurityFilterForTenantPermission(ExtensionPermissionSetRoleID, TempTableFilter."Table Number");

        // Exercise
        LibraryE2EPlanPermissions.SetBusinessManagerPlan;
        DisplayPermissionsForPermissionSet(ExtensionPermissionSetRoleID);

        // Verify
        AssertTenantPermissionSetMissingSecurityFilterForTenantPermission(ExtensionPermissionSetRoleID, TempTableFilter."Table Number");
    end;

    [Test]
    [HandlerFunctions('CopyPermissionSetMissingNewNameRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StanHasToSpecifyNewNameForCopiedPermissionSet()
    var
        PermissionSetRoleID: Code[20];
        NewPermissionSetRoleID: Code[20];
    begin
        Initialize;

        // Setup
        PermissionSetRoleID := GenerateRandomPermissionSetRoleID;
        NewPermissionSetRoleID := GenerateRandomTenantPermissionSetRoleID;

        LibraryLowerPermissions.SetOutsideO365Scope;
        CreateNewPermissionSet(PermissionSetRoleID);

        // Exercise
        LibraryVariableStorage.Enqueue(NewPermissionSetRoleID);
        LibraryE2EPlanPermissions.SetBusinessManagerPlan;
        asserterror CopyPermissionSetToNewTenantPermissionSet(PermissionSetRoleID, ZeroGuid);

        // Verify
        Assert.ExpectedError(TargetNameMissingErr);
    end;

    [Test]
    [HandlerFunctions('CopyPermissionSetWithNewNameRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StanHasToUseUniqueNameForCopiedPermissionSet()
    var
        PermissionSetRoleID: Code[20];
    begin
        Initialize;

        // Setup
        PermissionSetRoleID := GenerateRandomPermissionSetRoleID;

        LibraryLowerPermissions.SetOutsideO365Scope;
        CreateNewPermissionSet(PermissionSetRoleID);

        // Exercise
        LibraryVariableStorage.Enqueue(PermissionSetRoleID);
        LibraryVariableStorage.Enqueue(true); // as source is permission set
        LibraryE2EPlanPermissions.SetBusinessManagerPlan;
        asserterror CopyPermissionSetToNewTenantPermissionSet(PermissionSetRoleID, ZeroGuid);

        // Verify
        Assert.ExpectedError(TargetExistsErr);
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('CopyPermissionSetWithNewNameRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StanHasToSpecifyExistingPermissionSetToCopy()
    var
        PermissionSetRoleID: Code[20];
        NewPermissionSetRoleID: Code[20];
    begin
        Initialize;

        // Setup
        PermissionSetRoleID := GenerateRandomPermissionSetRoleID;
        NewPermissionSetRoleID := GenerateRandomTenantPermissionSetRoleID;

        // Exercise
        LibraryVariableStorage.Enqueue(NewPermissionSetRoleID);
        LibraryVariableStorage.Enqueue(false); // as source does not exist
        LibraryE2EPlanPermissions.SetBusinessManagerPlan;
        asserterror CopyPermissionSetToNewTenantPermissionSet(PermissionSetRoleID, ZeroGuid);

        // Verify
        Assert.ExpectedError(MissingSourceErr);
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('CopyPermissionSetWithNewNameRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StanCannotCopyMultiplePermissionSetsSimultaneously()
    var
        PermissionSetRoleIDOne: Code[20];
        PermissionSetRoleIDTwo: Code[20];
        NewPermissionSetRoleID: Code[20];
    begin
        Initialize;

        // Setup
        PermissionSetRoleIDOne := GenerateRandomPermissionSetRoleID;
        PermissionSetRoleIDTwo := GenerateRandomPermissionSetRoleID;
        NewPermissionSetRoleID := GenerateRandomTenantPermissionSetRoleID;

        LibraryLowerPermissions.SetOutsideO365Scope;
        CreateNewPermissionSet(PermissionSetRoleIDOne);
        CreateNewPermissionSet(PermissionSetRoleIDTwo);

        // Exercise
        LibraryVariableStorage.Enqueue(NewPermissionSetRoleID);
        LibraryVariableStorage.Enqueue(false);
        LibraryE2EPlanPermissions.SetBusinessManagerPlan;
        asserterror CopyTwoPermissionSetsToNewTenantPermissionSets(PermissionSetRoleIDOne, PermissionSetRoleIDTwo);

        // Verify
        Assert.ExpectedError(MultipleSourcesErr);
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IsaacIdentifiedPermissionSetsToBeNonEditable()
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
        ZeroGUID: Guid;
        PermissionSetRoleID: Code[20];
        CanEditPermissionSet: Boolean;
    begin
        Initialize;

        // Setup
        PermissionSetRoleID := GenerateRandomPermissionSetRoleID;

        LibraryLowerPermissions.SetOutsideO365Scope;
        CreateNewPermissionSet(PermissionSetRoleID);

        AggregatePermissionSet.Get(AggregatePermissionSet.Scope::System, ZeroGUID, PermissionSetRoleID);

        // Exercise
        LibraryE2EPlanPermissions.SetBusinessManagerPlan;
        CanEditPermissionSet := PermissionPagesMgt.IsPermissionSetEditable(AggregatePermissionSet);

        // Verify
        Assert.IsFalse(CanEditPermissionSet, StrSubstNo('Permission set %1 is editable.', PermissionSetRoleID));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IsaacIdentifiedExtensionPermissionSetsToBeNonEditable()
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
        ExtensionPermissionSetAppID: Guid;
        ExtensionPermissionSetRoleID: Code[20];
        CanEditPermissionSet: Boolean;
    begin
        Initialize;

        // Setup
        ExtensionPermissionSetRoleID := GenerateRandomTenantPermissionSetRoleID;
        ExtensionPermissionSetAppID := CreateNewExtensionPermissionSet(ExtensionPermissionSetRoleID);
        AggregatePermissionSet.Get(AggregatePermissionSet.Scope::Tenant, ExtensionPermissionSetAppID, ExtensionPermissionSetRoleID);

        // Exercise
        LibraryE2EPlanPermissions.SetBusinessManagerPlan;
        CanEditPermissionSet := PermissionPagesMgt.IsPermissionSetEditable(AggregatePermissionSet);

        // Verify
        Assert.IsFalse(CanEditPermissionSet, StrSubstNo('Extension permission set %1 is editable.', ExtensionPermissionSetRoleID));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IsaacIdentifiedUserCreatedTenantPermissionSetsToBeEditable()
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
        ZeroGUID: Guid;
        NewPermissionSetRoleID: Code[20];
        CanEditPermissionSet: Boolean;
    begin
        Initialize;

        // Setup
        NewPermissionSetRoleID := GenerateRandomTenantPermissionSetRoleID;
        CreateNewTenantPermissionSet(NewPermissionSetRoleID);
        AggregatePermissionSet.Get(AggregatePermissionSet.Scope::Tenant, ZeroGUID, NewPermissionSetRoleID);

        // Exercise
        LibraryE2EPlanPermissions.SetBusinessManagerPlan;
        CanEditPermissionSet := PermissionPagesMgt.IsPermissionSetEditable(AggregatePermissionSet);

        // Verify
        Assert.IsTrue(CanEditPermissionSet, StrSubstNo('User-created permission set %1 is not editable.', NewPermissionSetRoleID));
    end;

    [Test]
    [HandlerFunctions('CopyPermissionSetWithNewNameRequestPageHandler,CopyPermissionSetSuccessMessageHandler,HandleNotificationAppDbPermissionSetChanged,CopiedPermissionSetPageHandler')]
    [Scope('OnPrem')]
    procedure StanGetsNotifiedWhenHashOfPermissionSetChanges()
    var
        PermissionSet: Record "Permission Set";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        PermissionSets: TestPage "Permission Sets";
        PermissionSetRoleIDThatIsLaterChanged: Code[20];
        PermissionSetRoleIDThatIsLaterDeleted: Code[20];
        PermissionSetRoleIDThatIsNotLaterChanged: Code[20];
        NewPermissionSet1: Code[20];
        NewPermissionSet2: Code[20];
        NewPermissionSet3: Code[20];
    begin
        Initialize;

        // Setup: Create new permission sets
        PermissionSetRoleIDThatIsLaterChanged := GenerateRandomPermissionSetRoleID;
        PermissionSetRoleIDThatIsLaterDeleted := GenerateRandomPermissionSetRoleID;
        PermissionSetRoleIDThatIsNotLaterChanged := GenerateRandomPermissionSetRoleID;

        LibraryLowerPermissions.SetOutsideO365Scope;
        CreateNewPermissionSet(PermissionSetRoleIDThatIsLaterChanged);
        CreateNewPermissionSet(PermissionSetRoleIDThatIsLaterDeleted);
        CreateNewPermissionSet(PermissionSetRoleIDThatIsNotLaterChanged);

        // Setup: Copy permission sets
        LibraryE2EPlanPermissions.SetBusinessManagerPlan;
        NewPermissionSet1 := GenerateRandomTenantPermissionSetRoleID;
        LibraryVariableStorage.Enqueue(NewPermissionSet1);
        Commit();
        // enabled criteria for the option to notify depends on the source being a System permission set
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(NewPermissionSet1); // for the message handler
        CopyPermissionSetToNewTenantPermissionSet(PermissionSetRoleIDThatIsLaterChanged, ZeroGuid);

        NewPermissionSet2 := GenerateRandomTenantPermissionSetRoleID;
        LibraryVariableStorage.Enqueue(NewPermissionSet2);
        Commit();
        // enabled criteria for the option to notify depends on the source being a System permission set
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(NewPermissionSet2); // for the message handler
        CopyPermissionSetToNewTenantPermissionSet(PermissionSetRoleIDThatIsLaterDeleted, ZeroGuid);

        NewPermissionSet3 := GenerateRandomTenantPermissionSetRoleID;
        LibraryVariableStorage.Enqueue(NewPermissionSet3);
        Commit();
        // enabled criteria for the option to notify depends on the source being a System permission set
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(NewPermissionSet3); // for the message handler
        CopyPermissionSetToNewTenantPermissionSet(PermissionSetRoleIDThatIsNotLaterChanged, ZeroGuid);

        // Setup: Source Permission sets have changed
        LibraryLowerPermissions.SetOutsideO365Scope;
        PermissionSet.Get(PermissionSetRoleIDThatIsLaterChanged);
        PermissionSet.Hash := 'Some new hash';
        PermissionSet.Modify();
        PermissionSet.Get(PermissionSetRoleIDThatIsLaterDeleted);
        PermissionSet.Delete();

        // Exercise: Stan opens the permission set page and ensures that the only 2 records show up
        PermissionSets.Trap;
        LibraryVariableStorage.Enqueue(PermissionSetRoleIDThatIsLaterChanged);
        LibraryVariableStorage.Enqueue(NewPermissionSet1);
        LibraryVariableStorage.Enqueue(PermissionSetRoleIDThatIsLaterDeleted);
        LibraryVariableStorage.Enqueue(NewPermissionSet2);
        LibraryVariableStorage.Enqueue(PermissionSetRoleIDThatIsNotLaterChanged);
        PermissionSets.OpenEdit;

        // Verify: Source Hash changes for the permission set that is later changed
        AssertPermissionSetLinkExistsWithCorrectHash(PermissionSetRoleIDThatIsLaterChanged, NewPermissionSet1);
        AssertPermissionSetLinkExistsWithCorrectHash(PermissionSetRoleIDThatIsNotLaterChanged, NewPermissionSet3);

        // Verify: Permission set link gets deleted for the second permission set
        AssertPermissionSetLinkDoesNotExist(PermissionSetRoleIDThatIsLaterDeleted, NewPermissionSet2);

        // Verify: All variables have been dequeued
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StanBulkModifiesPermissionChangesTenantPermissionState()
    var
        TenantPermission: Record "Tenant Permission";
        TempTenantPermission: Record "Tenant Permission" temporary;
        TenantPermissions: TestPage "Tenant Permissions";
        TenantPermissionSetRoleID: Code[20];
    begin
        Initialize;

        // Setup - create two permissions
        TenantPermissionSetRoleID := GenerateRandomPermissionSetRoleID;
        CreateNewTenantPermissionSet(TenantPermissionSetRoleID);
        TenantPermission.SetRange("Role ID", TenantPermissionSetRoleID);
        TenantPermission.DeleteAll();
        LibraryPermissions.AddTenantPermission(
          ZeroGuid, TenantPermissionSetRoleID, TenantPermission."Object Type"::"Table Data", DATABASE::Customer);
        LibraryPermissions.AddTenantPermission(
          ZeroGuid, TenantPermissionSetRoleID, TenantPermission."Object Type"::"Table Data", DATABASE::"Sales Line");
        TenantPermission.Get(ZeroGuid, TenantPermissionSetRoleID, TenantPermission."Object Type"::"Table Data", DATABASE::"Sales Line");
        TenantPermission."Read Permission" := TenantPermission."Read Permission"::Indirect;
        TenantPermission.Modify();

        // Setup - open the permissions page
        LibraryE2EPlanPermissions.SetBusinessManagerPlan;
        TempTenantPermission.SetRange("App ID", ZeroGuid);
        TempTenantPermission.SetRange("Role ID", TenantPermissionSetRoleID);
        TenantPermissions.Trap;
        PAGE.Run(PAGE::"Tenant Permissions", TempTenantPermission);

        // Exercise - Set read to Indirect on Customer
        TenantPermissions."Object ID".AssertEquals(DATABASE::Customer);
        TenantPermissions.AllowReadIndirect.Invoke;

        // Verify
        TenantPermission.Get(ZeroGuid, TenantPermissionSetRoleID, TenantPermission."Object Type"::"Table Data", DATABASE::Customer);
        Assert.AreEqual(TenantPermission."Read Permission"::Indirect, TenantPermission."Read Permission",
          'Customer does not have Indirect permissions');

        // Exercise - Set read to Indirect on Sales Line
        TenantPermissions.Next;
        TenantPermissions."Object ID".AssertEquals(DATABASE::"Sales Line");
        TenantPermissions.AllowReadIndirect.Invoke;

        // Verify
        TenantPermission.Get(ZeroGuid, TenantPermissionSetRoleID, TenantPermission."Object Type"::"Table Data", DATABASE::"Sales Line");
        Assert.AreEqual(TenantPermission."Read Permission"::Indirect, TenantPermission."Read Permission",
          'Customer does not have Indirect permissions');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StanAddsRelatedTableWhenRelatedTableDoesNotExistInPermissionSet()
    var
        TenantPermission: Record "Tenant Permission";
        TempTenantPermission: Record "Tenant Permission" temporary;
        TenantPermissions: TestPage "Tenant Permissions";
        TenantPermissionSetRoleID: Code[20];
    begin
        Initialize;

        // Setup - Add permission for Sales header in a new permission set
        TenantPermissionSetRoleID := GenerateRandomPermissionSetRoleID;
        CreateNewTenantPermissionSet(TenantPermissionSetRoleID);
        TenantPermission.SetRange("Role ID", TenantPermissionSetRoleID);
        TenantPermission.DeleteAll();
        LibraryPermissions.AddTenantPermission(
          ZeroGuid, TenantPermissionSetRoleID, TenantPermission."Object Type"::"Table Data", DATABASE::"Sales Header");

        // Setup - open the permissions page
        LibraryE2EPlanPermissions.SetBusinessManagerPlan;
        TempTenantPermission.SetRange("App ID", ZeroGuid);
        TempTenantPermission.SetRange("Role ID", TenantPermissionSetRoleID);
        TenantPermissions.Trap;
        PAGE.Run(PAGE::"Tenant Permissions", TempTenantPermission);

        // Exercise - Add read permissions to tables related.
        TenantPermissions."Object ID".AssertEquals(DATABASE::"Sales Header");
        TenantPermissions.AddRelatedTablesAction.Invoke;

        // Verify
        Assert.IsTrue(TenantPermission.Get(ZeroGuid, TenantPermissionSetRoleID, TenantPermission."Object Type"::"Table Data",
            DATABASE::Customer),
          'Related table not added');
        Assert.AreEqual(TenantPermission."Read Permission"::Yes, TenantPermission."Read Permission",
          'Customer does not have read permissions');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StanAddsRelatedTableWhenRelatedTableExistAsNonReadInPermissionSet()
    var
        TenantPermission: Record "Tenant Permission";
        TempTenantPermission: Record "Tenant Permission" temporary;
        TenantPermissions: TestPage "Tenant Permissions";
        TenantPermissionSetRoleID: Code[20];
    begin
        Initialize;

        // Setup - Add permission for Sales header in a new permission set
        TenantPermissionSetRoleID := GenerateRandomPermissionSetRoleID;
        CreateNewTenantPermissionSet(TenantPermissionSetRoleID);
        TenantPermission.SetRange("Role ID", TenantPermissionSetRoleID);
        TenantPermission.DeleteAll();
        LibraryPermissions.AddTenantPermission(
          ZeroGuid, TenantPermissionSetRoleID, TenantPermission."Object Type"::"Table Data", DATABASE::"Sales Header");
        LibraryPermissions.AddTenantPermission(
          ZeroGuid, TenantPermissionSetRoleID, TenantPermission."Object Type"::"Table Data", DATABASE::Customer);
        TenantPermission.Get(ZeroGuid, TenantPermissionSetRoleID, TenantPermission."Object Type"::"Table Data", DATABASE::Customer);
        TenantPermission."Read Permission" := TenantPermission."Read Permission"::" ";
        TenantPermission."Insert Permission" := TenantPermission."Insert Permission"::Indirect;
        TenantPermission.Modify();

        // Setup - open the permissions page
        LibraryE2EPlanPermissions.SetBusinessManagerPlan;
        TempTenantPermission.SetRange("App ID", ZeroGuid);
        TempTenantPermission.SetRange("Role ID", TenantPermissionSetRoleID);
        TenantPermissions.Trap;
        PAGE.Run(PAGE::"Tenant Permissions", TempTenantPermission);

        // Exercise - Add read permissions to tables related.
        TenantPermissions.GotoRecord(TenantPermission);
        TenantPermissions."Object ID".AssertEquals(DATABASE::Customer);
        TenantPermissions.AddRelatedTablesAction.Invoke;

        // Verify
        Assert.IsTrue(TenantPermission.Get(ZeroGuid, TenantPermissionSetRoleID, TenantPermission."Object Type"::"Table Data",
            DATABASE::Customer),
          'Related table not added');
        Assert.AreEqual(TenantPermission."Read Permission"::" ", TenantPermission."Read Permission",
          'Customer is updated to have read permissions');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StanCanExportTenantPermissionSets()
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        Permission: Record Permission;
        TempBlob: Codeunit "Temp Blob";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        ExportPermissionSets: XMLport "Export Permission Sets";
        OutStr: OutStream;
        PermissionXmlNodeList: DotNet XmlNodeList;
        NewPermissionSetRoleID: Code[20];
        ZeroGuid: Guid;
    begin
        Initialize;

        // Setup
        NewPermissionSetRoleID := GenerateRandomTenantPermissionSetRoleID;

        CreateNewTenantPermissionSet(NewPermissionSetRoleID);

        // Exercise
        LibraryE2EPlanPermissions.SetBusinessManagerPlan;
        AggregatePermissionSet.SetRange("Role ID", NewPermissionSetRoleID);
        TempBlob.CreateOutStream(OutStr);
        ExportPermissionSets.SetTableView(AggregatePermissionSet);
        ExportPermissionSets.SetDestination(OutStr);
        ExportPermissionSets.Export;

        // Verify
        AggregatePermissionSet.Get(AggregatePermissionSet.Scope::Tenant, ZeroGuid, NewPermissionSetRoleID);
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, '');
        LibraryXPathXMLReader.VerifyNodeCountByXPath('/PermissionSets', 1);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('/PermissionSets/PermissionSet', 1);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('/PermissionSets/PermissionSet/Permission', 2);
        LibraryXPathXMLReader.VerifyAttributeValue('PermissionSet', 'AppID', AggregatePermissionSet."App ID");
        LibraryXPathXMLReader.VerifyAttributeValue('PermissionSet', 'RoleID', AggregatePermissionSet."Role ID");
        LibraryXPathXMLReader.VerifyAttributeValue('PermissionSet', 'RoleName', AggregatePermissionSet.Name);

        LibraryXPathXMLReader.GetNodeListByElementName('/PermissionSets/PermissionSet/Permission', PermissionXmlNodeList);
        LibraryXPathXMLReader.VerifyNodeValueFromParentNode(
          PermissionXmlNodeList.Item(0), 'ObjectType', Format(Permission."Object Type"::"Table Data"));
        LibraryXPathXMLReader.VerifyNodeValueFromParentNode(
          PermissionXmlNodeList.Item(0), 'ObjectID', Format(DATABASE::Customer));
        LibraryXPathXMLReader.VerifyNodeValueFromParentNode(
          PermissionXmlNodeList.Item(0), 'ReadPermission', Format(Permission."Read Permission"::Yes));
        asserterror LibraryXPathXMLReader.VerifyNodeValueFromParentNode(
            PermissionXmlNodeList.Item(0), 'InsertPermission', Format(Permission."Insert Permission"::Yes));
        Assert.ExpectedError('not found');
        asserterror LibraryXPathXMLReader.VerifyNodeValueFromParentNode(
            PermissionXmlNodeList.Item(0), 'ModifyPermission', Format(Permission."Modify Permission"::Yes));
        Assert.ExpectedError('not found');
        asserterror LibraryXPathXMLReader.VerifyNodeValueFromParentNode(
            PermissionXmlNodeList.Item(0), 'DeletePermission', Format(Permission."Delete Permission"::Yes));
        Assert.ExpectedError('not found');
        asserterror LibraryXPathXMLReader.VerifyNodeValueFromParentNode(
            PermissionXmlNodeList.Item(0), 'ExecutePermission', Format(Permission."Execute Permission"::Yes));
        Assert.ExpectedError('not found');

        LibraryXPathXMLReader.VerifyNodeValueFromParentNode(
          PermissionXmlNodeList.Item(1), 'ObjectType', Format(Permission."Object Type"::"Table Data"));
        LibraryXPathXMLReader.VerifyNodeValueFromParentNode(
          PermissionXmlNodeList.Item(1), 'ObjectID', Format(DATABASE::Vendor));
        LibraryXPathXMLReader.VerifyNodeValueFromParentNode(
          PermissionXmlNodeList.Item(1), 'ReadPermission', Format(Permission."Read Permission"::Yes));
        asserterror LibraryXPathXMLReader.VerifyNodeValueFromParentNode(
            PermissionXmlNodeList.Item(1), 'InsertPermission', Format(Permission."Insert Permission"::Yes));
        Assert.ExpectedError('not found');
        asserterror LibraryXPathXMLReader.VerifyNodeValueFromParentNode(
            PermissionXmlNodeList.Item(1), 'ModifyPermission', Format(Permission."Modify Permission"::Yes));
        Assert.ExpectedError('not found');
        asserterror LibraryXPathXMLReader.VerifyNodeValueFromParentNode(
            PermissionXmlNodeList.Item(1), 'DeletePermission', Format(Permission."Delete Permission"::Yes));
        Assert.ExpectedError('not found');
        asserterror LibraryXPathXMLReader.VerifyNodeValueFromParentNode(
            PermissionXmlNodeList.Item(1), 'ExecutePermission', Format(Permission."Execute Permission"::Yes));
        Assert.ExpectedError('not found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StanCanExportSystemPermissionSets()
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        Permission: Record Permission;
        TempBlob: Codeunit "Temp Blob";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        ExportPermissionSets: XMLport "Export Permission Sets";
        OutStr: OutStream;
        PermissionXmlNodeList: DotNet XmlNodeList;
        NewPermissionSetRoleID: Code[20];
        ZeroGuid: Guid;
    begin
        Initialize;

        // Setup
        NewPermissionSetRoleID := GenerateRandomPermissionSetRoleID;
        CreateNewPermissionSet(NewPermissionSetRoleID);

        // Exercise
        LibraryE2EPlanPermissions.SetBusinessManagerPlan;
        AggregatePermissionSet.SetRange("Role ID", NewPermissionSetRoleID);
        TempBlob.CreateOutStream(OutStr);
        ExportPermissionSets.SetTableView(AggregatePermissionSet);
        ExportPermissionSets.SetDestination(OutStr);
        ExportPermissionSets.Export;

        // Verify
        AggregatePermissionSet.Get(AggregatePermissionSet.Scope::System, ZeroGuid, NewPermissionSetRoleID);
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, '');
        LibraryXPathXMLReader.VerifyNodeCountByXPath('/PermissionSets', 1);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('/PermissionSets/PermissionSet', 1);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('/PermissionSets/PermissionSet/Permission', 2);
        LibraryXPathXMLReader.VerifyAttributeValue('PermissionSet', 'AppID', AggregatePermissionSet."App ID");
        LibraryXPathXMLReader.VerifyAttributeValue('PermissionSet', 'RoleID', AggregatePermissionSet."Role ID");
        LibraryXPathXMLReader.VerifyAttributeValue('PermissionSet', 'RoleName', AggregatePermissionSet.Name);

        LibraryXPathXMLReader.GetNodeListByElementName('/PermissionSets/PermissionSet/Permission', PermissionXmlNodeList);
        LibraryXPathXMLReader.VerifyNodeValueFromParentNode(
          PermissionXmlNodeList.Item(0), 'ObjectType', Format(Permission."Object Type"::"Table Data"));
        LibraryXPathXMLReader.VerifyNodeValueFromParentNode(
          PermissionXmlNodeList.Item(0), 'ObjectID', Format(DATABASE::Customer));
        LibraryXPathXMLReader.VerifyNodeValueFromParentNode(
          PermissionXmlNodeList.Item(0), 'ReadPermission', Format(Permission."Read Permission"::Yes));
        asserterror LibraryXPathXMLReader.VerifyNodeValueFromParentNode(
            PermissionXmlNodeList.Item(0), 'InsertPermission', Format(Permission."Insert Permission"::Yes));
        Assert.ExpectedError('not found');
        asserterror LibraryXPathXMLReader.VerifyNodeValueFromParentNode(
            PermissionXmlNodeList.Item(0), 'ModifyPermission', Format(Permission."Modify Permission"::Yes));
        Assert.ExpectedError('not found');
        asserterror LibraryXPathXMLReader.VerifyNodeValueFromParentNode(
            PermissionXmlNodeList.Item(0), 'DeletePermission', Format(Permission."Delete Permission"::Yes));
        Assert.ExpectedError('not found');
        asserterror LibraryXPathXMLReader.VerifyNodeValueFromParentNode(
            PermissionXmlNodeList.Item(0), 'ExecutePermission', Format(Permission."Execute Permission"::Yes));
        Assert.ExpectedError('not found');

        LibraryXPathXMLReader.VerifyNodeValueFromParentNode(
          PermissionXmlNodeList.Item(1), 'ObjectType', Format(Permission."Object Type"::"Table Data"));
        LibraryXPathXMLReader.VerifyNodeValueFromParentNode(
          PermissionXmlNodeList.Item(1), 'ObjectID', Format(DATABASE::Vendor));
        LibraryXPathXMLReader.VerifyNodeValueFromParentNode(
          PermissionXmlNodeList.Item(1), 'ReadPermission', Format(Permission."Read Permission"::Yes));
        asserterror LibraryXPathXMLReader.VerifyNodeValueFromParentNode(
            PermissionXmlNodeList.Item(1), 'InsertPermission', Format(Permission."Insert Permission"::Yes));
        Assert.ExpectedError('not found');
        asserterror LibraryXPathXMLReader.VerifyNodeValueFromParentNode(
            PermissionXmlNodeList.Item(1), 'ModifyPermission', Format(Permission."Modify Permission"::Yes));
        Assert.ExpectedError('not found');
        asserterror LibraryXPathXMLReader.VerifyNodeValueFromParentNode(
            PermissionXmlNodeList.Item(1), 'DeletePermission', Format(Permission."Delete Permission"::Yes));
        Assert.ExpectedError('not found');
        asserterror LibraryXPathXMLReader.VerifyNodeValueFromParentNode(
            PermissionXmlNodeList.Item(1), 'ExecutePermission', Format(Permission."Execute Permission"::Yes));
        Assert.ExpectedError('not found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StanCanExportMultipleCreatedSystemPermissionSets()
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        TempBlob: Codeunit "Temp Blob";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        ExportPermissionSets: XMLport "Export Permission Sets";
        OutStr: OutStream;
        NewPermissionSetRoleID: Code[20];
        NewTenantPermissionSetRoleID: Code[20];
    begin
        Initialize;

        // Setup
        NewPermissionSetRoleID := GenerateRandomPermissionSetRoleID;
        NewTenantPermissionSetRoleID := GenerateRandomPermissionSetRoleID;

        CreateNewPermissionSet(NewPermissionSetRoleID);
        CreateNewTenantPermissionSet(NewTenantPermissionSetRoleID);

        // Exercise
        LibraryE2EPlanPermissions.SetBusinessManagerPlan;
        AggregatePermissionSet.SetFilter("Role ID", '%1|%2', NewPermissionSetRoleID, NewTenantPermissionSetRoleID);
        TempBlob.CreateOutStream(OutStr);
        ExportPermissionSets.SetTableView(AggregatePermissionSet);
        ExportPermissionSets.SetDestination(OutStr);
        ExportPermissionSets.Export;

        // Verify
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, '');
        LibraryXPathXMLReader.VerifyNodeCountByXPath('/PermissionSets', 1);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('/PermissionSets/PermissionSet', 2);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('/PermissionSets/PermissionSet/Permission', 4);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StanCanExportTenantPermissionSetsInExtensionSchema()
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        TempBlob: Codeunit "Temp Blob";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        ExportPermissionSets: XMLport "Export Permission Sets";
        OutStr: OutStream;
        NewPermissionSetRoleID: Code[20];
        ZeroGuid: Guid;
    begin
        Initialize;

        // Setup
        NewPermissionSetRoleID := GenerateRandomTenantPermissionSetRoleID;

        CreateNewTenantPermissionSet(NewPermissionSetRoleID);

        // Exercise
        LibraryE2EPlanPermissions.SetBusinessManagerPlan;
        AggregatePermissionSet.SetRange("Role ID", NewPermissionSetRoleID);
        TempBlob.CreateOutStream(OutStr);
        ExportPermissionSets.SetExportToExtensionSchema(true);
        ExportPermissionSets.SetTableView(AggregatePermissionSet);
        ExportPermissionSets.SetDestination(OutStr);
        ExportPermissionSets.Export;

        // Verify
        AggregatePermissionSet.Get(AggregatePermissionSet.Scope::Tenant, ZeroGuid, NewPermissionSetRoleID);
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, '');
        LibraryXPathXMLReader.VerifyNodeCountByXPath('/PermissionSets', 1);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('/PermissionSets/PermissionSet', 1);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('/PermissionSets/PermissionSet/Permission', 2);
        asserterror LibraryXPathXMLReader.VerifyAttributeValue('PermissionSet', 'AppID', AggregatePermissionSet."App ID");
        Assert.ExpectedError('instantiated');
        LibraryXPathXMLReader.VerifyAttributeValue('PermissionSet', 'RoleID', AggregatePermissionSet."Role ID");
        LibraryXPathXMLReader.VerifyAttributeValue('PermissionSet', 'RoleName', AggregatePermissionSet.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StanCanImportToTenantPermissionSets()
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        TenantPermissionSet: Record "Tenant Permission Set";
        TenantPermission: Record "Tenant Permission";
        TempBlob: Codeunit "Temp Blob";
        ExportPermissionSets: XMLport "Export Permission Sets";
        Instr: InStream;
        OutStr: OutStream;
        NewPermissionSetRoleID: Code[20];
        ZeroGuid: Guid;
    begin
        Initialize;

        // Setup - Create a new Permission Set and export it to a stream
        NewPermissionSetRoleID := GenerateRandomTenantPermissionSetRoleID;
        CreateNewTenantPermissionSet(NewPermissionSetRoleID);
        AggregatePermissionSet.SetRange("Role ID", NewPermissionSetRoleID);
        TempBlob.CreateOutStream(OutStr);
        ExportPermissionSets.SetTableView(AggregatePermissionSet);
        ExportPermissionSets.SetDestination(OutStr);
        ExportPermissionSets.Export;

        // Delete the newly created Permission Set
        TenantPermission.SetRange("App ID", ZeroGuid);
        TenantPermission.SetRange("Role ID", NewPermissionSetRoleID);
        TenantPermission.DeleteAll();

        TenantPermissionSet.Get(ZeroGuid, NewPermissionSetRoleID);
        TenantPermissionSet.DeleteAll();

        // Exercise
        TempBlob.CreateInStream(Instr);
        LibraryE2EPlanPermissions.SetBusinessManagerPlan;
        XMLPORT.Import(XMLPORT::"Import Tenant Permission Sets", Instr);

        // Verify
        TenantPermissionSet.Get(ZeroGuid, NewPermissionSetRoleID);
        TenantPermission.Get(ZeroGuid, NewPermissionSetRoleID, TenantPermission."Object Type"::"Table Data", DATABASE::Customer);
        TenantPermission.TestField("Read Permission", TenantPermission."Read Permission"::Yes);
        TenantPermission.TestField("Insert Permission", TenantPermission."Insert Permission"::" ");
        TenantPermission.TestField("Modify Permission", TenantPermission."Modify Permission"::" ");
        TenantPermission.TestField("Delete Permission", TenantPermission."Delete Permission"::" ");
        TenantPermission.TestField("Execute Permission", TenantPermission."Execute Permission"::" ");

        TenantPermission.Get(ZeroGuid, NewPermissionSetRoleID, TenantPermission."Object Type"::"Table Data", DATABASE::Vendor);
        TenantPermission.TestField("Read Permission", TenantPermission."Read Permission"::Yes);
        TenantPermission.TestField("Insert Permission", TenantPermission."Insert Permission"::" ");
        TenantPermission.TestField("Modify Permission", TenantPermission."Modify Permission"::" ");
        TenantPermission.TestField("Delete Permission", TenantPermission."Delete Permission"::" ");
        TenantPermission.TestField("Execute Permission", TenantPermission."Execute Permission"::" ");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StanSetsFirstPermission()
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        TenantPermission: Record "Tenant Permission";
        PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
        TenantPermissions: TestPage "Tenant Permissions";
        NewPermissionSetRoleID: Code[20];
        ZeroGuid: Guid;
    begin
        Initialize;

        // GIVEN - Create a new Permission Set
        NewPermissionSetRoleID := GenerateRandomTenantPermissionSetRoleID;
        CreateNewTenantPermissionSet(NewPermissionSetRoleID);

        // GIVEN - No permissions for the permission set
        TenantPermission.SetRange("Role ID", NewPermissionSetRoleID);
        TenantPermission.DeleteAll();

        // WHEN - Open the permissions for this permission set
        LibraryE2EPlanPermissions.SetBusinessManagerPlan;
        TenantPermissions.Trap;
        PermissionPagesMgt.ShowPermissions(AggregatePermissionSet.Scope::Tenant, ZeroGuid, NewPermissionSetRoleID, false);

        // THEN - only relevant fields are filled for first line
        TenantPermissions."Object Type".AssertEquals(Format(TenantPermission."Object Type"::"Table Data"));
        TenantPermissions.Control8.AssertEquals(Format(TenantPermission."Read Permission"::Yes));
        TenantPermissions.Control7.AssertEquals(Format(TenantPermission."Insert Permission"::Yes));
        TenantPermissions.Control6.AssertEquals(Format(TenantPermission."Modify Permission"::Yes));
        TenantPermissions.Control5.AssertEquals(Format(TenantPermission."Delete Permission"::Yes));
        TenantPermissions.Control4.AssertEquals(Format(TenantPermission."Execute Permission"::" "));

        // WHEN - Object type is set to Codeunit
        TenantPermissions."Object Type".SetValue(TenantPermission."Object Type"::Codeunit);

        // THEN - only relevant fields are filled for Codeunit
        TenantPermissions."Object Type".AssertEquals(Format(TenantPermission."Object Type"::Codeunit));
        TenantPermissions.Control8.AssertEquals(Format(TenantPermission."Read Permission"::" "));
        TenantPermissions.Control7.AssertEquals(Format(TenantPermission."Insert Permission"::" "));
        TenantPermissions.Control6.AssertEquals(Format(TenantPermission."Modify Permission"::" "));
        TenantPermissions.Control5.AssertEquals(Format(TenantPermission."Delete Permission"::" "));
        TenantPermissions.Control4.AssertEquals(Format(TenantPermission."Execute Permission"::Yes));

        // WHEN - Object type is set back to TableData
        TenantPermissions."Object Type".SetValue(TenantPermission."Object Type"::"Table Data");

        // THEN - only relevant fields are filled for Table Data
        TenantPermissions."Object Type".AssertEquals(Format(TenantPermission."Object Type"::"Table Data"));
        TenantPermissions.Control8.AssertEquals(Format(TenantPermission."Read Permission"::Yes));
        TenantPermissions.Control7.AssertEquals(Format(TenantPermission."Insert Permission"::Yes));
        TenantPermissions.Control6.AssertEquals(Format(TenantPermission."Modify Permission"::Yes));
        TenantPermissions.Control5.AssertEquals(Format(TenantPermission."Delete Permission"::Yes));
        TenantPermissions.Control4.AssertEquals(Format(TenantPermission."Execute Permission"::" "));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RenameUserDefinedPermissionSet()
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        PermissionSetBuffer: Record "Permission Set Buffer";
        PermissionSets: TestPage "Permission Sets";
        OldRoleID: Code[20];
        NewRoleID: Code[20];
    begin
        // [FEATURE] [Tenant Perminsion Set]
        // [SCENARIO 298247] User can rename User defined permission sets on the page "Permission Sets"
        Initialize;

        // [GIVEN] User defined permission set with Role ID = 'PermSet1'
        OldRoleID := LibraryUtility.GenerateRandomCode20(TenantPermissionSet.FieldNo("Role ID"), DATABASE::"Tenant Permission Set");
        NewRoleID := LibraryUtility.GenerateRandomCode20(TenantPermissionSet.FieldNo("Role ID"), DATABASE::"Tenant Permission Set");
        CreateNewTenantPermissionSet(OldRoleID);
        LibraryE2EPlanPermissions.SetBusinessManagerPlan;

        // [GIVEN] Open page "Permission Sets"
        PermissionSets.OpenEdit;
        PermissionSets.FILTER.SetFilter("Role ID", OldRoleID);
        PermissionSets.FILTER.SetFilter(Type, Format(PermissionSetBuffer.Type::"User-Defined"));

        // [WHEN] Rename permission set 'PermSet1' to 'PermSet2' on the page "Permission Sets"
        PermissionSets.PermissionSet.SetValue(NewRoleID);

        // [THEN] Permission set has Role ID = 'PermSet2'
        TenantPermissionSet.SetRange("Role ID", OldRoleID);
        Assert.RecordIsEmpty(TenantPermissionSet);
        TenantPermissionSet.SetRange("Role ID", NewRoleID);
        Assert.RecordIsNotEmpty(TenantPermissionSet);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RenameUserDefinedPermissionSetUsedUsersSettings()
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        PermissionSetBuffer: Record "Permission Set Buffer";
        AccessControl: Record "Access Control";
        PermissionSets: TestPage "Permission Sets";
        OldRoleID: Code[20];
        NewRoleID: Code[20];
    begin
        // [FEATURE] [Tenant Perminsion Set]
        // [SCENARIO 364626] User cannot rename User defined permission sets on the page "Permission Sets" if it is used elsewhere (users or groups permission settings)
        Initialize();

        // [GIVEN] User defined permission set with Role ID = "A"
        OldRoleID := LibraryUtility.GenerateRandomCode20(TenantPermissionSet.FieldNo("Role ID"), DATABASE::"Tenant Permission Set");
        NewRoleID := LibraryUtility.GenerateRandomCode20(TenantPermissionSet.FieldNo("Role ID"), DATABASE::"Tenant Permission Set");
        CreateNewTenantPermissionSet(OldRoleID);
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();

        // [GIVEN] Permission set "A" is used by a user
        AccessControl."Role ID" := OldRoleID;
        AccessControl.Insert();

        // [GIVEN] Open page "Permission Sets"
        PermissionSets.OpenEdit();
        PermissionSets.FILTER.SetFilter("Role ID", OldRoleID);
        PermissionSets.FILTER.SetFilter(Type, Format(PermissionSetBuffer.Type::"User-Defined"));

        // [WHEN] Rename permission set "A" to "B" on the page "Permission Sets"
        asserterror PermissionSets.PermissionSet.SetValue(NewRoleID);

        // [THEN] Error has been thrown with message "You cannot rename a tenant permission set until it is used elsewhere, for example, in permission settings for a user or user group."
        Assert.ExpectedError(Format(CannotRenameTenantPermissionSetHavingUsageErr));
    end;


    [Test]
    [HandlerFunctions('StartStopRecorderConfirmHandler')]
    [Scope('OnPrem')]
    procedure StanStartsAndStopsRecorderOnEditablePermissionSet()
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        TenantPermission: Record "Tenant Permission";
        PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
        TenantPermissions: TestPage "Tenant Permissions";
        NewPermissionSetRoleID: Code[20];
        ZeroGuid: Guid;
    begin
        Initialize;

        // GIVEN - Create a new Permission Set
        NewPermissionSetRoleID := GenerateRandomTenantPermissionSetRoleID;
        CreateNewTenantPermissionSet(NewPermissionSetRoleID);

        // GIVEN - No permissions for the permission set
        TenantPermission.SetRange("Role ID", NewPermissionSetRoleID);
        TenantPermission.DeleteAll();

        // WHEN - Open the permissions for this permission set
        LibraryE2EPlanPermissions.SetBusinessManagerPlan;
        TenantPermissions.Trap;
        PermissionPagesMgt.ShowPermissions(AggregatePermissionSet.Scope::Tenant, ZeroGuid, NewPermissionSetRoleID, false);

        // THEN - Initial state is that Start is enabled and Stop is not
        Assert.IsTrue(TenantPermissions.Start.Enabled,
          StrSubstNo(DisabledActionErr, 'Start', TenantPermissions.Caption));
        Assert.IsFalse(TenantPermissions.Stop.Enabled,
          StrSubstNo(EnabledActionErr, 'Stop', TenantPermissions.Caption));

        // WHEN - Start is pressed
        TenantPermissions.Start.Invoke;

        // THEN - Stop is enabled and Start is not
        Assert.IsFalse(TenantPermissions.Start.Enabled,
          StrSubstNo(EnabledActionErr, 'Start', TenantPermissions.Caption));
        Assert.IsTrue(TenantPermissions.Stop.Enabled,
          StrSubstNo(DisabledActionErr, 'Stop', TenantPermissions.Caption));

        // When - Stop is pressed
        TenantPermissions.Stop.Invoke;

        // THEN - Start is enabled and Stop is not
        Assert.IsTrue(TenantPermissions.Start.Enabled,
          StrSubstNo(DisabledActionErr, 'Start', TenantPermissions.Caption));
        Assert.IsFalse(TenantPermissions.Stop.Enabled,
          StrSubstNo(EnabledActionErr, 'Stop', TenantPermissions.Caption));
    end;

    local procedure Initialize()
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
        PermissionSetLink: Record "Permission Set Link";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Test Editing Permissions");

        LibraryVariableStorage.Clear();
        ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Essential));
        PermissionSetLink.DeleteAll();
    end;

    local procedure GenerateRandomPermissionSetRoleID(): Code[20]
    var
        PermissionSet: Record "Permission Set";
    begin
        exit(LibraryUtility.GenerateRandomCode20(PermissionSet.FieldNo("Role ID"), DATABASE::"Permission Set"));
    end;

    local procedure GenerateRandomTenantPermissionSetRoleID(): Code[20]
    var
        TenantPermissionSet: Record "Tenant Permission Set";
    begin
        exit(LibraryUtility.GenerateRandomCode20(TenantPermissionSet.FieldNo("Role ID"), DATABASE::"Tenant Permission Set"));
    end;

    local procedure GenerateRandomTenantPermissionSetName(): Text[30]
    var
        TenantPermissionSet: Record "Tenant Permission Set";
    begin
        exit(CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(TenantPermissionSet.Name)), 1, MaxStrLen(TenantPermissionSet.Name)));
    end;

    local procedure CreateNewPermissionSet(PermissionSetRoleID: Code[20])
    var
        Permission: Record Permission;
        PermissionSet: Record "Permission Set";
    begin
        LibraryPermissions.CreatePermissionSet(PermissionSet, PermissionSetRoleID);

        LibraryPermissions.AddPermission(PermissionSetRoleID, Permission."Object Type"::"Table Data", DATABASE::Customer);
        LibraryPermissions.AddPermission(PermissionSetRoleID, Permission."Object Type"::"Table Data", DATABASE::Vendor);

        LibraryPermissions.UpdateHashOnPermissionSet(PermissionSetRoleID);
    end;

    local procedure CreateNewExtensionPermissionSet(TenantPermissionSetRoleID: Code[20]) TenantPermissionSetAppID: Guid
    begin
        TenantPermissionSetAppID := CreateGuid;
        CreateNewTenantPermissionSetWithSpecificGUID(TenantPermissionSetRoleID, TenantPermissionSetAppID);
    end;

    local procedure CreateNewTenantPermissionSet(TenantPermissionSetRoleID: Code[20])
    var
        ZeroGUID: Guid;
    begin
        CreateNewTenantPermissionSetWithSpecificGUID(TenantPermissionSetRoleID, ZeroGUID);
    end;

    local procedure CreateNewTenantPermissionSetWithSpecificGUID(TenantPermissionSetRoleID: Code[20]; TenantPermissionSetAppID: Guid)
    var
        TenantPermission: Record "Tenant Permission";
        TenantPermissionSet: Record "Tenant Permission Set";
    begin
        LibraryPermissions.CreateTenantPermissionSet(TenantPermissionSet, TenantPermissionSetRoleID, TenantPermissionSetAppID);

        LibraryPermissions.AddTenantPermission(
          TenantPermissionSetAppID, TenantPermissionSetRoleID, TenantPermission."Object Type"::"Table Data", DATABASE::Customer);
        LibraryPermissions.AddTenantPermission(
          TenantPermissionSetAppID, TenantPermissionSetRoleID, TenantPermission."Object Type"::"Table Data", DATABASE::Vendor);
    end;

    local procedure CreateNewTenantPermissionSetFromPermissionSetsPage(NewRoleID: Code[20]; NewName: Text[30])
    var
        PermissionSets: TestPage "Permission Sets";
    begin
        PermissionSets.OpenEdit();
        PermissionSets.New();
        PermissionSets.PermissionSet.SetValue(NewRoleID);
        PermissionSets.Name.SetValue(NewName);
        PermissionSets.Close();
    end;

    local procedure DefineSecurityFilterForPermission(var TempTableFilter: Record "Table Filter" temporary; PermissionSetRoleID: Code[20])
    var
        Permission: Record Permission;
    begin
        Permission.SetRange("Role ID", PermissionSetRoleID);
        Permission.FindFirst();

        BuildSecurityFilterForFieldValueNotEqualToZero(TempTableFilter, Permission."Object ID");
    end;

    local procedure DefineSecurityFilterForTenantPermission(var TempTableFilter: Record "Table Filter" temporary; TenantPermissionSetRoleID: Code[20])
    var
        TenantPermission: Record "Tenant Permission";
    begin
        TenantPermission.SetRange("Role ID", TenantPermissionSetRoleID);
        TenantPermission.FindFirst();

        BuildSecurityFilterForFieldValueNotEqualToZero(TempTableFilter, TenantPermission."Object ID");
    end;

    local procedure BuildSecurityFilterForFieldValueNotEqualToZero(var TempTableFilter: Record "Table Filter" temporary; TableNumber: Integer)
    var
        "Field": Record "Field";
    begin
        Field.SetRange(TableNo, TableNumber);
        Field.FindFirst;

        TempTableFilter."Table Number" := TableNumber;
        TempTableFilter."Field Number" := Field."No.";

        case Field.Type of
            Field.Type::Code, Field.Type::Text, Field.Type::Integer:
                TempTableFilter."Field Filter" := StrSubstNo('<>%1', 0);
            else
                Assert.Fail(StrSubstNo(UnsupportedDataTypeErr, Field.FieldName, Field."Type Name"));
        end;
    end;

    local procedure DeleteExistingTenantPermissionSet(ExistingRoleID: Code[20])
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        ZeroGUID: Guid;
    begin
        TenantPermissionSet.Get(ZeroGUID, ExistingRoleID);
        TenantPermissionSet.Delete();
    end;

    local procedure CopyPermissionSetToNewTenantPermissionSet(SourcePermissionSetRoleID: Code[20]; AppId: Guid)
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        PermissionSets: TestPage "Permission Sets";
    begin
        PermissionSets.OpenEdit;
        PermissionSets.FILTER.SetFilter("Role ID", SourcePermissionSetRoleID);
        PermissionSets.FILTER.SetFilter("App ID", AppId);
        AggregatePermissionSet.SetRange("Role ID", SourcePermissionSetRoleID);
        AggregatePermissionSet.SetRange("App ID", AppId);
        PermissionSets.CopyPermissionSet.Invoke;
        PermissionSets.Close;
    end;

    local procedure CopyTwoPermissionSetsToNewTenantPermissionSets(FirstSourcePermissionSetRoleID: Code[20]; SecondSourcePermissionSetRoleID: Code[20])
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
    begin
        AggregatePermissionSet.SetFilter("Role ID", '%1|%2', FirstSourcePermissionSetRoleID, SecondSourcePermissionSetRoleID);
        REPORT.Run(REPORT::"Copy Permission Set", true, true, AggregatePermissionSet);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CopyPermissionSetWithNewNameRequestPageHandler(var CopyPermissionSet: TestRequestPage "Copy Permission Set")
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        TargetTenantPermissionSetRoleID: Code[20];
        NotifyFlagEnabled: Boolean;
    begin
        TargetTenantPermissionSetRoleID := CopyStr(LibraryVariableStorage.DequeueText, 1, MaxStrLen(TenantPermissionSet."Role ID"));
        CopyPermissionSet.NewPermissionSet.SetValue(TargetTenantPermissionSetRoleID);
        NotifyFlagEnabled := LibraryVariableStorage.DequeueBoolean;
        Assert.AreEqual(NotifyFlagEnabled, CopyPermissionSet.CreateLink.Enabled, 'Enabled criteria not fulfilled');
        if NotifyFlagEnabled then
            CopyPermissionSet.CreateLink.SetValue(true);
        CopyPermissionSet.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CopyPermissionSetWithNewNameRequestPageHandlerWithoutLink(var CopyPermissionSet: TestRequestPage "Copy Permission Set")
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        TargetTenantPermissionSetRoleID: Code[20];
        NotifyFlagEnabled: Boolean;
    begin
        TargetTenantPermissionSetRoleID := CopyStr(LibraryVariableStorage.DequeueText, 1, MaxStrLen(TenantPermissionSet."Role ID"));
        CopyPermissionSet.NewPermissionSet.SetValue(TargetTenantPermissionSetRoleID);
        NotifyFlagEnabled := LibraryVariableStorage.DequeueBoolean;
        Assert.AreEqual(NotifyFlagEnabled, CopyPermissionSet.CreateLink.Enabled, 'Enabled criteria not fulfilled');
        if NotifyFlagEnabled then
            CopyPermissionSet.CreateLink.SetValue(false);
        CopyPermissionSet.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CopyPermissionSetMissingNewNameRequestPageHandler(var CopyPermissionSet: TestRequestPage "Copy Permission Set")
    begin
        CopyPermissionSet.OK.Invoke;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure CopyPermissionSetSuccessMessageHandler(Message: Text[1024])
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        CopiedRoleID: Code[20];
    begin
        CopiedRoleID := CopyStr(LibraryVariableStorage.DequeueText, 1, MaxStrLen(TenantPermissionSet."Role ID"));
        Assert.ExpectedMessage(StrSubstNo(CopySuccessMsg, CopiedRoleID), Message);
    end;

    local procedure DisplayPermissionsForPermissionSet(RoleID: Code[20])
    var
        PermissionSets: TestPage "Permission Sets";
    begin
        PermissionSets.OpenEdit;
        PermissionSets.FILTER.SetFilter("Role ID", RoleID);
        PermissionSets.Permissions.Invoke;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure AddItemPermissionToTenantPermissionSetPageHandler(var TenantPermissions: TestPage "Tenant Permissions")
    var
        TenantPermission: Record "Tenant Permission";
    begin
        TenantPermissions.New;
        TenantPermissions."Object Type".SetValue(TenantPermission."Object Type"::"Table Data");
        TenantPermissions."Object ID".SetValue(LibraryVariableStorage.DequeueInteger);
        TenantPermissions.Control8.SetValue(TenantPermission."Read Permission"::Yes);
        TenantPermissions.Close;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CannotAddItemPermissionToPermissionSetPageHandler(var Permissions: TestPage Permissions)
    begin
        asserterror Permissions.New;
        Assert.ExpectedErrorCode('DB:ClientInsertDenied');

        Assert.IsFalse(Permissions."Object Type".Editable,
          StrSubstNo(EditableControlErr, Permissions."Object Type".Caption, Permissions.Caption));
        Assert.IsFalse(Permissions."Object ID".Editable,
          StrSubstNo(EditableControlErr, Permissions."Object ID".Caption, Permissions.Caption));
        Assert.IsFalse(Permissions."Read Permission".Editable,
          StrSubstNo(EditableControlErr, Permissions."Read Permission".Caption, Permissions.Caption));
        Assert.IsFalse(Permissions."Insert Permission".Editable,
          StrSubstNo(EditableControlErr, Permissions."Insert Permission".Caption, Permissions.Caption));
        Assert.IsFalse(Permissions."Modify Permission".Editable,
          StrSubstNo(EditableControlErr, Permissions."Modify Permission".Caption, Permissions.Caption));
        Assert.IsFalse(Permissions."Delete Permission".Editable,
          StrSubstNo(EditableControlErr, Permissions."Delete Permission".Caption, Permissions.Caption));

        Permissions.Close;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CannotAddItemPermissionToExtensionPermissionSetPageHandler(var TenantPermissions: TestPage "Tenant Permissions")
    begin
        Assert.IsFalse(TenantPermissions."Object Type".Editable,
          StrSubstNo(EditableControlErr, TenantPermissions."Object Type".Caption, TenantPermissions.Caption));
        Assert.IsFalse(TenantPermissions."Object ID".Editable,
          StrSubstNo(EditableControlErr, TenantPermissions."Object ID".Caption, TenantPermissions.Caption));
        Assert.IsFalse(TenantPermissions.Control8.Editable,
          StrSubstNo(EditableControlErr, TenantPermissions.Control8.Caption, TenantPermissions.Caption));
        Assert.IsFalse(TenantPermissions.Control7.Editable,
          StrSubstNo(EditableControlErr, TenantPermissions.Control7.Caption, TenantPermissions.Caption));
        Assert.IsFalse(TenantPermissions.Control6.Editable,
          StrSubstNo(EditableControlErr, TenantPermissions.Control6.Caption, TenantPermissions.Caption));
        Assert.IsFalse(TenantPermissions.Control5.Editable,
          StrSubstNo(EditableControlErr, TenantPermissions.Control5.Caption, TenantPermissions.Caption));
        Assert.IsFalse(TenantPermissions.Start.Enabled,
          StrSubstNo(EnabledActionErr, 'Start', TenantPermissions.Caption));
        Assert.IsFalse(TenantPermissions.Stop.Enabled,
          StrSubstNo(EnabledActionErr, 'Stop', TenantPermissions.Caption));

        TenantPermissions.Close;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure DisplaySecurityFiltersForTenantPermissionPageHandler(var TenantPermissions: TestPage "Tenant Permissions")
    begin
        TenantPermissions."Security Filter".AssistEdit;
        TenantPermissions.Close;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AddNewSecurityFilterToTenantPermissionModalPageHandler(var TableFilterPage: TestPage "Table Filter")
    var
        TableFilter: Record "Table Filter";
        InputFieldFilter: Text[250];
        InputFieldNumber: Integer;
    begin
        InputFieldNumber := LibraryVariableStorage.DequeueInteger;
        InputFieldFilter := CopyStr(LibraryVariableStorage.DequeueText, 1, MaxStrLen(TableFilter."Field Filter"));

        TableFilterPage.New;
        TableFilterPage."Field Number".SetValue(InputFieldNumber);
        TableFilterPage."Field Filter".SetValue(InputFieldFilter);
        TableFilterPage.OK.Invoke;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure DisplaySecurityFiltersForPermissionPageHandler(var Permissions: TestPage Permissions)
    begin
        Permissions."Security Filter".AssistEdit;
        Permissions.Close;
    end;

    local procedure AssertTenantPermissionSetExists(ExpectedRoleID: Code[20])
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        ZeroGUID: Guid;
    begin
        TenantPermissionSet.SetRange("App ID", ZeroGUID);
        TenantPermissionSet.SetRange("Role ID", ExpectedRoleID);

        Assert.RecordIsNotEmpty(TenantPermissionSet);
    end;

    local procedure AssertTenantPermissionSetNotExisting(ExpectedRoleID: Code[20])
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        ZeroGUID: Guid;
    begin
        TenantPermissionSet.SetRange("App ID", ZeroGUID);
        TenantPermissionSet.SetRange("Role ID", ExpectedRoleID);

        Assert.RecordIsEmpty(TenantPermissionSet);
    end;

    local procedure AssertTenantPermissionSetEqualsPermissionSet(TenantPermissionSetRoleID: Code[20]; PermissionSetRoleID: Code[20])
    var
        FromPermissionSet: Record "Permission Set";
        ToTenantPermissionSet: Record "Tenant Permission Set";
        ZeroGUID: Guid;
    begin
        FromPermissionSet.Get(PermissionSetRoleID);
        ToTenantPermissionSet.Get(ZeroGUID, TenantPermissionSetRoleID);
        ToTenantPermissionSet.TestField(Name, FromPermissionSet.Name);
    end;

    local procedure AssertTenantPermissionsEqualPermissions(TenantPermissionSetRoleID: Code[20]; PermissionSetRoleID: Code[20])
    begin
        AssertTenantPermissionCountEqualsPermissionCount(TenantPermissionSetRoleID, PermissionSetRoleID);
        AssertTenantPermissionValuesEqualPermissionValues(TenantPermissionSetRoleID, PermissionSetRoleID);
    end;

    local procedure AssertTenantPermissionCountEqualsPermissionCount(TenantPermissionSetRoleID: Code[20]; PermissionSetRoleID: Code[20])
    var
        FromPermission: Record Permission;
        ToTenantPermission: Record "Tenant Permission";
        ZeroGUID: Guid;
    begin
        FromPermission.SetRange("Role ID", PermissionSetRoleID);
        Assert.RecordIsNotEmpty(FromPermission);

        ToTenantPermission.SetRange("App ID", ZeroGUID);
        ToTenantPermission.SetRange("Role ID", TenantPermissionSetRoleID);
        Assert.RecordIsNotEmpty(ToTenantPermission);

        Assert.RecordCount(ToTenantPermission, FromPermission.Count);
    end;

    local procedure AssertTenantPermissionValuesEqualPermissionValues(TenantPermissionSetRoleID: Code[20]; PermissionSetRoleID: Code[20])
    var
        FromPermission: Record Permission;
        ToTenantPermission: Record "Tenant Permission";
        ZeroGUID: Guid;
    begin
        FromPermission.SetRange("Role ID", PermissionSetRoleID);
        FromPermission.FindSet;

        ToTenantPermission.SetRange("App ID", ZeroGUID);
        ToTenantPermission.SetRange("Role ID", TenantPermissionSetRoleID);
        ToTenantPermission.FindSet;

        repeat
            AssertTenantPermissionSetupEqualsPermissionSetup(ToTenantPermission, FromPermission);
        until (ToTenantPermission.Next = 0) and (FromPermission.Next = 0);
    end;

    local procedure AssertTenantPermissionSetupEqualsPermissionSetup(var ToTenantPermission: Record "Tenant Permission"; var FromPermission: Record Permission)
    begin
        ToTenantPermission.TestField("Object Type", FromPermission."Object Type");
        ToTenantPermission.TestField("Object ID", FromPermission."Object ID");
        ToTenantPermission.TestField("Read Permission", FromPermission."Read Permission");
        ToTenantPermission.TestField("Insert Permission", FromPermission."Insert Permission");
        ToTenantPermission.TestField("Modify Permission", FromPermission."Modify Permission");
        ToTenantPermission.TestField("Delete Permission", FromPermission."Delete Permission");
        ToTenantPermission.TestField("Execute Permission", FromPermission."Execute Permission");
        ToTenantPermission.TestField("Security Filter", FromPermission."Security Filter");
    end;

    local procedure AssertTenantPermissionSetEqualsTenantPermissionSet(ToTenantPermissionSetRoleID: Code[20]; FromTenantPermissionSetRoleID: Code[20]; FromTenantPermissionSetAppID: Guid)
    var
        FromTenantPermissionSet: Record "Tenant Permission Set";
        ToTenantPermissionSet: Record "Tenant Permission Set";
        ZeroGUID: Guid;
    begin
        FromTenantPermissionSet.Get(FromTenantPermissionSetAppID, FromTenantPermissionSetRoleID);
        ToTenantPermissionSet.Get(ZeroGUID, ToTenantPermissionSetRoleID);
        ToTenantPermissionSet.TestField(Name, FromTenantPermissionSet.Name);
    end;

    local procedure AssertTenantPermissionsEqualTenantPermissions(ToTenantPermissionSetRoleID: Code[20]; FromTenantPermissionSetRoleID: Code[20]; FromTenantPermissionSetAppID: Guid)
    begin
        AssertTenantPermissionCountEqualsTenantPermissionCount(
          ToTenantPermissionSetRoleID, FromTenantPermissionSetRoleID, FromTenantPermissionSetAppID);
        AssertTenantPermissionValuesEqualTenantPermissionValues(
          ToTenantPermissionSetRoleID, FromTenantPermissionSetRoleID, FromTenantPermissionSetAppID);
    end;

    local procedure AssertTenantPermissionCountEqualsTenantPermissionCount(ToTenantPermissionSetRoleID: Code[20]; FromTenantPermissionSetRoleID: Code[20]; FromTenantPermissionSetAppID: Guid)
    var
        FromTenantPermission: Record "Tenant Permission";
        ToTenantPermission: Record "Tenant Permission";
        ZeroGUID: Guid;
    begin
        FromTenantPermission.SetRange("App ID", FromTenantPermissionSetAppID);
        FromTenantPermission.SetRange("Role ID", FromTenantPermissionSetRoleID);
        Assert.RecordIsNotEmpty(FromTenantPermission);

        ToTenantPermission.SetRange("App ID", ZeroGUID);
        ToTenantPermission.SetRange("Role ID", ToTenantPermissionSetRoleID);
        Assert.RecordIsNotEmpty(ToTenantPermission);

        Assert.RecordCount(ToTenantPermission, FromTenantPermission.Count);
    end;

    local procedure AssertTenantPermissionValuesEqualTenantPermissionValues(ToTenantPermissionSetRoleID: Code[20]; FromTenantPermissionSetRoleID: Code[20]; FromTenantPermissionSetAppID: Guid)
    var
        FromTenantPermission: Record "Tenant Permission";
        ToTenantPermission: Record "Tenant Permission";
        ZeroGUID: Guid;
    begin
        FromTenantPermission.SetRange("App ID", FromTenantPermissionSetAppID);
        FromTenantPermission.SetRange("Role ID", FromTenantPermissionSetRoleID);
        FromTenantPermission.FindSet;

        ToTenantPermission.SetRange("App ID", ZeroGUID);
        ToTenantPermission.SetRange("Role ID", ToTenantPermissionSetRoleID);
        ToTenantPermission.FindSet;

        repeat
            AssertTenantPermissionSetupEqualsTenantPermissionSetup(ToTenantPermission, FromTenantPermission);
        until (ToTenantPermission.Next = 0) and (FromTenantPermission.Next = 0);
    end;

    local procedure AssertTenantPermissionSetupEqualsTenantPermissionSetup(var ToTenantPermission: Record "Tenant Permission"; var FromTenantPermission: Record "Tenant Permission")
    begin
        ToTenantPermission.TestField("Object Type", FromTenantPermission."Object Type");
        ToTenantPermission.TestField("Object ID", FromTenantPermission."Object ID");
        ToTenantPermission.TestField("Read Permission", FromTenantPermission."Read Permission");
        ToTenantPermission.TestField("Insert Permission", FromTenantPermission."Insert Permission");
        ToTenantPermission.TestField("Modify Permission", FromTenantPermission."Modify Permission");
        ToTenantPermission.TestField("Delete Permission", FromTenantPermission."Delete Permission");
        ToTenantPermission.TestField("Execute Permission", FromTenantPermission."Execute Permission");
        ToTenantPermission.TestField("Security Filter", FromTenantPermission."Security Filter");
    end;

    local procedure AssertTenantPermissionSetContainsTableDataTenantPermission(TenantPermissionSetRoleID: Code[20]; TenantPermissionTableDataObjectID: Integer)
    var
        TenantPermission: Record "Tenant Permission";
        ZeroGUID: Guid;
    begin
        TenantPermission.SetRange("App ID", ZeroGUID);
        TenantPermission.SetRange("Role ID", TenantPermissionSetRoleID);
        TenantPermission.SetRange("Object Type", TenantPermission."Object Type"::"Table Data");
        TenantPermission.SetRange("Object ID", TenantPermissionTableDataObjectID);
        Assert.RecordIsNotEmpty(TenantPermission);
    end;

    local procedure AssertTenantPermissionSetNotContainingTableDataTenantPermission(TenantPermissionSetRoleID: Code[20]; TenantPermissionTableDataObjectID: Integer)
    var
        TenantPermission: Record "Tenant Permission";
        ZeroGUID: Guid;
    begin
        TenantPermission.SetRange("App ID", ZeroGUID);
        TenantPermission.SetRange("Role ID", TenantPermissionSetRoleID);
        TenantPermission.SetRange("Object Type", TenantPermission."Object Type"::"Table Data");
        TenantPermission.SetRange("Object ID", TenantPermissionTableDataObjectID);
        Assert.RecordIsEmpty(TenantPermission);
    end;

    local procedure AssertPermissionSetNotContainingTableDataTenantPermission(PermissionSetRoleID: Code[20]; TenantPermissionTableDataObjectID: Integer)
    var
        TenantPermission: Record "Tenant Permission";
    begin
        TenantPermission.SetRange("Role ID", PermissionSetRoleID);
        TenantPermission.SetRange("Object Type", TenantPermission."Object Type"::"Table Data");
        TenantPermission.SetRange("Object ID", TenantPermissionTableDataObjectID);
        Assert.RecordIsEmpty(TenantPermission);
    end;

    local procedure AssertPermissionSetNotContainingTableDataPermission(PermissionSetRoleID: Code[20]; PermissionTableDataObjectID: Integer)
    var
        Permission: Record Permission;
    begin
        Permission.SetRange("Role ID", PermissionSetRoleID);
        Permission.SetRange("Object Type", Permission."Object Type"::"Table Data");
        Permission.SetRange("Object ID", PermissionTableDataObjectID);
        Assert.RecordIsEmpty(Permission);
    end;

    local procedure AssertTenantPermissionSetHasSecurityFilterForTenantPermission(TenantPermissionSetRoleID: Code[20]; TempTableFilter: Record "Table Filter" temporary)
    var
        TenantPermission: Record "Tenant Permission";
        TenantPermissionSecurityFilter: Text;
    begin
        TenantPermission.SetRange("Role ID", TenantPermissionSetRoleID);
        TenantPermission.SetRange("Object Type", TenantPermission."Object Type"::"Table Data");
        TenantPermission.SetRange("Object ID", TempTableFilter."Table Number");
        TenantPermission.FindFirst;

        TenantPermissionSecurityFilter := Format(TenantPermission."Security Filter");

        Assert.AreEqual(0, StrPos(TenantPermissionSecurityFilter, TempTableFilter."Table Name"),
          StrSubstNo(SecurityFilterErr, TenantPermissionSecurityFilter, TempTableFilter."Table Name"));
        Assert.IsTrue(0 < StrPos(TenantPermissionSecurityFilter, TempTableFilter."Field Filter"),
          StrSubstNo(FieldFilterErr, TenantPermissionSecurityFilter, TempTableFilter."Field Filter"));
    end;

    local procedure AssertTenantPermissionSetMissingSecurityFilterForTenantPermission(TenantPermissionSetRoleID: Code[20]; InputTableNumber: Integer)
    var
        TenantPermission: Record "Tenant Permission";
    begin
        TenantPermission.SetRange("Role ID", TenantPermissionSetRoleID);
        TenantPermission.SetRange("Object Type", TenantPermission."Object Type"::"Table Data");
        TenantPermission.SetRange("Object ID", InputTableNumber);
        TenantPermission.FindFirst;

        Assert.AreEqual('', Format(TenantPermission."Security Filter"), SecurityFilterExistsErr);
    end;

    local procedure AssertPermissionSetMissingSecurityFilterForPermission(PermissionSetRoleID: Code[20]; InputTableNumber: Integer)
    var
        Permission: Record Permission;
    begin
        Permission.SetRange("Role ID", PermissionSetRoleID);
        Permission.SetRange("Object Type", Permission."Object Type"::"Table Data");
        Permission.SetRange("Object ID", InputTableNumber);
        Permission.FindFirst;

        Assert.AreEqual('', Format(Permission."Security Filter"), SecurityFilterExistsErr);
    end;

    local procedure AssertPermissionSetLinkExistsWithCorrectHash(SourcePermissionSet: Code[20]; TargetpermissionSet: Code[20])
    var
        PermissionSetLink: Record "Permission Set Link";
        PermissionSet: Record "Permission Set";
    begin
        Assert.IsTrue(PermissionSetLink.Get(SourcePermissionSet, TargetpermissionSet), 'Record does not exist');
        PermissionSet.Get(SourcePermissionSet);
        Assert.AreEqual(PermissionSet.Hash, PermissionSetLink."Source Hash", 'Hash mismatch');
    end;

    local procedure AssertPermissionSetLinkDoesNotExist(SourcePermissionSet: Code[20]; TargetpermissionSet: Code[20])
    var
        PermissionSetLink: Record "Permission Set Link";
    begin
        Assert.IsFalse(PermissionSetLink.Get(SourcePermissionSet, TargetpermissionSet), 'Record does not exist');
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure HandleNotificationAppDbPermissionSetChanged(var Notification: Notification): Boolean
    var
        PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
    begin
        Assert.AreEqual(MSPermSetChangedMsg, Notification.Message, 'Message mismatch');
        PermissionPagesMgt.AppDbPermissionSetChangedShowDetails(Notification);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CopiedPermissionSetPageHandler(var ChangedPermissionSetList: TestPage "Changed Permission Set List")
    begin
        ChangedPermissionSetList.First;
        ChangedPermissionSetList."Permission Set ID".AssertEquals(LibraryVariableStorage.DequeueText); // the permission set that changed
        ChangedPermissionSetList."Linked Permission Set ID".AssertEquals(LibraryVariableStorage.DequeueText);

        ChangedPermissionSetList.Last;
        ChangedPermissionSetList."Permission Set ID".AssertEquals(LibraryVariableStorage.DequeueText); // the permission set that was deleted
        ChangedPermissionSetList."Linked Permission Set ID".AssertEquals(LibraryVariableStorage.DequeueText);

        ChangedPermissionSetList.FILTER.SetFilter("Permission Set ID", LibraryVariableStorage.DequeueText); // the permission set that did not change
        ChangedPermissionSetList.First;
        ChangedPermissionSetList."Permission Set ID".AssertEquals('');
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure HandleNotificationCannotEditPermissionSets(var Notification: Notification): Boolean
    begin
        Assert.AreEqual(CannotEditPermissionSetMsg, Notification.Message, 'Message mismatch');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure StartStopRecorderConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

