codeunit 7201 "CDS Integration Impl."
{
    SingleInstance = true;

    var
        CDSIntegrationMgt: Codeunit "CDS Integration Mgt.";
        CachedCompanyIdFieldNo: Dictionary of [Integer, Integer];
        CachedOwnerIdFieldNo: Dictionary of [Integer, Integer];
        CachedOwnerTypeFieldNo: Dictionary of [Integer, Integer];
        CachedOwningTeamCheckWithoutBusinessUnit: Dictionary of [Guid, Boolean];
        CachedOwningTeamCheckWithBusinessUnit: Dictionary of [Guid, Boolean];
        CachedOwningUserCheckWithoutBusinessUnit: Dictionary of [Guid, Boolean];
        CachedOwningUserCheckWithBusinessUnit: Dictionary of [Guid, Boolean];
        CachedCompanyId: Guid;
        CachedDefaultOwningTeamId: Guid;
        CachedOwningBusinessUnitId: Guid;
        AreCompanyValuesCached: Boolean;
        CategoryTok: Label 'AL Common Data Service Integration', Locked = true;
        IntegrationNotConfiguredTxt: Label 'Integration is not configured.', Locked = true;
        IntegrationDisabledTxt: Label 'Integration is disabled.', Locked = true;
        ActivateConnectionTxt: Label 'Activate connection.', Locked = true;
        ConnectionActiveTxt: Label 'Connection is active.', Locked = true;
        ConnectionNotActiveTxt: Label 'Connection is not active.', Locked = true;
        NoConnectionTxt: Label 'Connection is not registered.', Locked = true;
        OnBeforeActivateConnectionTxt: Label 'On before activate connection.', Locked = true;
        OnAfterActivateConnectionTxt: Label 'On after activate connection.', Locked = true;
        ConnectionActivatedTxt: Label 'Connection has been actived.', Locked = true;
        HasConnectionTxt: Label 'Connection is registered.', Locked = true;
        OnBeforeRegisterConnectionTxt: Label 'On before register connection.', Locked = true;
        OnAfterRegisterConnectionTxt: Label 'On after register connection.', Locked = true;
        UnregisterConnectionTxt: Label 'Unregister connection.', Locked = true;
        OnBeforeUnregisterConnectionTxt: Label 'On before unregister connection.', Locked = true;
        OnAfterUnregisterConnectionTxt: Label 'On after unregister connection.', Locked = true;
        ConnectionUnregisteredTxt: Label 'Connection has been unregistered.', Locked = true;
        OnEnableIntegrationTxt: Label 'On enable integration.', Locked = true;
        OnDisableIntegrationTxt: Label 'On disable integration.', Locked = true;
        RegisterConnectionTxt: Label 'Register connection.', Locked = true;
        ConnectionRegisteredTxt: Label 'Connection has been registered.', Locked = true;
        IntegrationEnabledTxt: Label 'Integration is enabled.', Locked = true;
        DisableIntegrationTxt: Label 'Disable integration.', Locked = true;
        NoPermissionsTxt: Label 'No permissions.', Locked = true;
        UpdateSetupTxt: Label 'Update setup.', Locked = true;
        SetupUpdatedTxt: Label 'Setup has been updated.', Locked = true;
        ConnectionFailureTxt: Label 'Connection failure.', Locked = true;
        EntityHasNoOwnerIdFieldTxt: Label 'Entity has no OwnerId field.', Locked = true;
        EntityHasNoOwnerTypeFieldTxt: Label 'Entity has no OwnerIdType field.', Locked = true;
        OwnerSetTxt: Label 'Owner has been set.', Locked = true;
        UnsupportedOwnerTypeTxt: Label 'Unsupported owner type.', Locked = true;
        OwnerCheckedTxt: Label 'Owner check is succeed.', Locked = true;
        CheckOwnerTxt: Label 'Check owner.', Locked = true;
        SetOwnerTxt: Label 'Set owner.', Locked = true;
        EntityHasNoCompanyIdFieldTxt: Label 'Entity has no CompanyId field.', Locked = true;
        CompanyIdSetTxt: Label 'CompanyId has been set.', Locked = true;
        CompanyIdCheckedTxt: Label 'CompanyId check is succeed.', Locked = true;
        CheckCompanyIdTxt: Label 'Check CompanyId.', Locked = true;
        SetCompanyIdTxt: Label 'Set CompanyId.', Locked = true;
        InitializeCompanyCacheTxt: Label 'Initialize company cache.', Locked = true;
        SetCachedOwningTeamCheckTxt: Label 'Set cache for team check. Team: %1, skip business unit check: %2.', Locked = true;
        SetCachedOwningUserCheckTxt: Label 'Set cache for user check. User: %1, skip business unit check: %2.', Locked = true;
        ClearCacheTxt: Label 'Clear cache.', Locked = true;
        CannotFindCompanyIdFieldErr: Label 'There is no CompanyId field in table %1 %2.', Comment = '%1 = table ID, %2 = table name';
        CompanyIdDiffersFromExpectedTxt: Label 'CompanyId differs from the expected one.', Locked = true;
        SetDefaultOwningTeamTxt: Label 'Set default owning team.', Locked = true;
        TeamNotFoundTxt: Label 'Team has not been found.', Locked = true;
        UserNotFoundTxt: Label 'User has not been found.', Locked = true;
        BusinessUnitNotFoundTxt: Label 'Business unit has not been found.', Locked = true;
        BusinessUnitMismatchTxt: Label 'Business unit in BC does not match business unit in Common Data Service.', Locked = true;
        CompanyNotFoundTxt: Label 'Company has not been found.', Locked = true;
        OrganizationNotFoundTxt: Label 'Organization has not been found.', Locked = true;
        CurrencyNotFoundTxt: Label 'Organization has not been found.', Locked = true;
        GLSetupNotFoundTxt: Label 'GL setup has not been found.', Locked = true;
        IntegrationRoleNotFoundTxt: Label 'Integration role has not been found.', Locked = true;
        IntegrationRoleNotAssignedToTeamTxt: Label 'Integration role is not assigned to team.', Locked = true;
        RoleNotFoundForBusinessUnitTxt: Label 'Integration role is not found for business unit.', Locked = true;
        TeamBusinessUnitDiffersFromSelectedTxt: Label 'Team business unit differs from the selected one.', Locked = true;
        UserBusinessUnitDiffersFromSelectedTxt: Label 'User business unit differs from the selected one.', Locked = true;
        CannotAssignRoleToUserTxt: Label 'Cannot assign role to user.', Locked = true;
        CannotAssignRoleToTeamTxt: Label 'Cannot assign role to team.', Locked = true;
        ConnectionRequiredFieldsTxt: Label 'A URL, user name and password are required.', Locked = true;
        ConnectionRequiredFieldsMismatchTxt: Label 'The URL, user name, password, and authentication type must be the same on the Common Data Service Connection Setup and Microsoft Dynamics 365 Connection Setup pages.', Locked = true;
        IgnoredAdminCredentialsTxt: Label 'Ignored administrator credentials.', Locked = true;
        InvalidAdminCredentialsTxt: Label 'Invalid administrator credentials.', Locked = true;
        InvalidUserCredentialsTxt: Label 'Invalid user credentials.', Locked = true;
        ConfigureSolutionTxt: Label 'Import and configure integration solution.', Locked = true;
        SolutionConfiguredTxt: Label 'Integration solution has been imported and configured.', Locked = true;
        SolutionNotInstalledTxt: Label 'Integration solution is not installed.', Locked = true;
        SolutionInstalledTxt: Label 'Integration solution is installed.', Locked = true;
        ConnectionNotRegisteredTxt: Label 'Connection is not registered.', Locked = true;
        IntegrationRequirementsMetTxt: Label 'Integration requirements are met.', Locked = true;
        DefaultOwningTeamSetTxt: Label 'Default owning team has been set.', Locked = true;
        CannotSetDefaultOwningTeamTxt: Label 'Cannot set default owning team.', Locked = true;
        BusinessUnitFixedTxt: Label 'Business unit has been fixed.', Locked = true;
        ConnectionTestSucceedTxt: Label 'Connection test succeed.', Locked = true;
        ConnectionTestFailedTxt: Label 'Connection test failed.', Locked = true;
        IntegrationRequirementsNotMetTxt: Label 'Integration requirements are not met.', Locked = true;
        SolutionRequirementsNotMetTxt: Label 'Integration solution requirements are not met.', Locked = true;
        IntegrationUserRequirementsNotMetTxt: Label 'Integration user requirements are not met.', Locked = true;
        OwningTeamRequirementsNotMetTxt: Label 'Owning team requirements are not met.', Locked = true;
        InvalidSolutionVersionTxt: Label 'Solution version is invalid.', Locked = true;
        OwnerDiffersFromExpectedTxt: Label 'Owner differs from the expected one.', Locked = true;
        SynchronizeCompanyTxt: Label 'Synchronize company entity.', Locked = true;
        CompanySynchronizedTxt: Label 'Company has been synchronized.', Locked = true;
        RoleAssignedToTeamTxt: Label 'Role isassigned to team.', Locked = true;
        RoleAssignedToUserTxt: Label 'Role is assigned to user.', Locked = true;
        CannotCreateBusinessUnitTxt: Label 'Cannot create business unit.', Locked = true;
        BusinessUnitCreatedTxt: Label 'Business unit has been created.', Locked = true;
        CannotCreateTeamTxt: Label 'Cannot create team.', Locked = true;
        TeamCreatedTxt: Label 'Team has been created.', Locked = true;
        CannotCreateCompanyTxt: Label 'Cannot create company.', Locked = true;
        CompanyCreatedTxt: Label 'Company has been created.', Locked = true;
        SetUserAsIntegrationUserTxt: Label 'Set user as an integration user.', Locked = true;
        CannotSetUserAsIntegrationUserTxt: Label 'Cannot set user as an integration user.', Locked = true;
        UserAlreadySetAsIntegrationUserTxt: Label 'User has already been set as an integration user.', Locked = true;
        UserSetAsIntegrationUserTxt: Label 'User has been set as an integration user.', Locked = true;
        SetAccessModeToNonInteractiveTxt: Label 'Set the user''s access mode to Non-Interactive.', Locked = true;
        CannotSetAccessModeToNonInteractiveTxt: Label 'Cannot set the user''s access mode to Non-Interactive.', Locked = true;
        AccessModeAlreadySetToNonInteractiveTxt: Label 'The user''s access mode is already set to Non-Interactive.', Locked = true;
        AccessModeSetToNonInteractiveTxt: Label 'The access mode for the user specified for the integration is set to Non-Interactive.', Locked = true;
        AccessModeSetToNonInteractiveMsg: Label 'The access mode for the user specified for the integration is set to Non-Interactive.';
        CompanyAlreadyExistsTxt: Label 'Company already exists.', Locked = true;
        BusinessUnitAlreadyExistsTxt: Label 'Business unit already exists.', Locked = true;
        TeamAlreadyExistsTxt: Label 'Team already exists.', Locked = true;
        CheckBusinessUnitTxt: Label 'Check business unit.', Locked = true;
        CheckOwningTeamTxt: Label 'Check owning team.', Locked = true;
        CheckTeamRolesTxt: Label 'Check team roles.', Locked = true;
        CheckCompanyTxt: Label 'Check company.', Locked = true;
        CreateCompanyTxt: Label 'Create company.', Locked = true;
        BusinessUnitCoupledTxt: Label 'Busness unit is correctly coupled.', Locked = true;
        SolutionVersionReceivedTxt: Label 'Solution version has been received.', Locked = true;
        CannotGetSolutionVersionTxt: Label 'Cannot get solution version.', Locked = true;
        CurrencyMismatchTxt: Label 'LCY Code does not match ISO Currency Code of the Common Data Service base currency.', Locked = true;
        UserHasNoRolesTxt: Label 'User has no roles.', Locked = true;
        SystemAdminRoleTxt: Label 'The user is assigned to the system administrator role.', Locked = true;
        NoSystemAdminRoleTxt: Label 'The admin user is not assigned to the System Administrator role.', Locked = true;
        NoSystemCustomizerRoleTxt: Label 'The admin user is not assigned to the System Customizer role.', Locked = true;
        NoIntegrationRoleTxt: Label 'The user is not assigned to the integration role.', Locked = true;
        UserNotLicensedTxt: Label 'The user''s access mode is not Non-Interactive, but the user is not a licensed user.', Locked = true;
        UserNotActiveTxt: Label 'The user account is disabled.', Locked = true;
        NotIntegrationUserTxt: Label 'User is not an integration user.', Locked = true;
        NotNonInteractiveAccessModeTxt: Label 'The user''s access mode is not Non-Interactive.', Locked = true;
        InvalidAccessModeTxt: Label 'The user''s access mode is not Read-Write or Non-Interactive.', Locked = true;
        ClearDisabledReasonTxt: Label 'Clear disabled reason.', Locked = true;
        CannotCreateCompanyErr: Label 'Cannot create company %1.', Comment = '%1 = company name';
        CannotCreateBusinessUnitErr: Label 'Cannot create business unit %1.', Comment = '%1 = business unit name';
        CannotCreateTeamErr: Label 'Cannot create team %1 for business unit %2.', Comment = '%1 = team name, %2 = business unit name';
        CannotSetDefaultOwningTeamErr: Label 'Cannot set default owning team.';
        CannotFindOwnerIdFieldErr: Label 'There is no OwnerId field in table %1 %2.', Comment = '%1 = table ID, %2 = table name';
        CannotFindOwnerTypeFieldErr: Label 'There is no OwnerIdType field in table %1 %2.', Comment = '%1 = table ID, %2 = table name';
        CannotFindOrganizationErr: Label 'Cannot find organization in Common Data Service.';
        BaseCurrencyNotFoundErr: Label 'Cannot find base currency in Common Data Service.';
        GLSetupNotFoundErr: Label 'Cannot find GL setup.';
        CompanyNotFoundErr: Label 'There is no company with external ID %1 in Common Data Service.', Comment = '%1 = company external ID';
        TeamNotFoundErr: Label 'There is no team with ID %1 in Common Data Service.', Comment = '%1 = team ID';
        UserNotFoundErr: Label 'There is no user with ID %1 in Common Data Service.', Comment = '%1 = system user ID';
        RoleNotFoundErr: Label 'There is no role with ID %1 in Common Data Service.', Comment = '%1 = role ID';
        BusinessUnitNotFoundErr: Label 'There is no business unit with ID %1 in Common Data Service.', Comment = '%1 = business unit ID';
        BusinessUnitMismatchErr: Label 'Business unit in BC does not match the business unit in Common Data Service.';
        OwnerIdTypeErr: Label 'Owner type must be either team or systemuser.';
        OwnerDiffersFromExpectedErr: Label 'Entity owner differs from the expected one.';
        TeamBusinessUnitDiffersFromSelectedErr: Label 'Team business unit differs from the selected one.';
        UserBusinessUnitDiffersFromSelectedErr: Label 'User business unit differs from the selected one.';
        UserDoesNotExistErr: Label 'There is no user with email address %1 in Common Data Service. Enter a valid email address.', Comment = '%1 = User email address';
        IntegrationRoleNotFoundErr: Label 'There is no integration role %1 for business unit %2.', Comment = '%1 = role name, %2 = business unit name';
        SolutionFileNotFoundErr: Label 'A file for a Common Data Service solution could not be found.';
        IntegrationUserPasswordWrongErr: Label 'Enter valid integration user credentials.';
        AdminUserPasswordWrongErr: Label 'Enter valid administrator credentials.';
        GeneralFailureErr: Label 'The import of a Common Data Service solution failed. This may be because the solution file is broken or because the specified administrator does not have sufficient privileges.';
        OrganizationServiceFailureErr: Label 'The import of a Common Data Service solution failed. This may be because the solution file is broken or because the specified administrator does not have sufficient privileges.';
        InvalidUriErr: Label 'The value entered is not a valid URL.';
        MustUseHttpsErr: Label 'The application is set up to support secure connections (HTTPS) to the Common Data Service environment only. You cannot use HTTP.';
        ReplaceServerAddressQst: Label 'The URL is not valid. Do you want to replace it with the URL suggested below?\\Entered URL: "%1".\Suggested URL: "%2".', Comment = '%1 and %2 are URLs';
        CDSConnectionURLWrongErr: Label 'The URL is incorrect. Enter the URL for the Common Data Service environment.';
        TemporaryConnectionPrefixTok: Label 'TEMP-Common Data Service-', Locked = true;
        TestServerAddressTok: Label '@@test@@', Locked = true;
        NewBusinessUnitNameTemplateTok: Label '<New> %1', Comment = '%1 = Business unit name', Locked = true;
        BusinessUnitNameTemplateTok: Label '%1 (%2)', Comment = '%1 = Company name, %2 = Company ID', Locked = true;
        TeamNameTemplateTok: Label 'BCI - %1', Comment = '%1 = Business unit name', Locked = true;
        ConnectionStringFormatTok: Label 'Url=%1; UserName=%2; Password=%3; ProxyVersion=%4; %5', Locked = true;
        ConnectionBrokenMsg: Label 'The connection to Common Data Service is disabled due to the following error: %1.\\Please contact your system administrator.', Comment = '%1 = Error text received from Common Data Service';
        ConnectionDisabledNotificationMsg: Label 'Connection to Common Data Service is broken and that it has been disabled due to an error: %1', Comment = '%1 = Error text received from Common Data Service';
        SetupConnectionTxt: Label 'Set up Common Data Service Base Integration connection';
        BaseIntegrationSolutionNotInstalledErr: Label 'Base Common Data Service integration solution %1 is not installed.', Comment = '%1 = Common Data Service solution name';
        SolutionVersionErr: Label 'Version of the base Common Data Service integration solution %1 is not the last one.', Comment = '%1 = solution version';
        SystemAdminErr: Label 'User %1 has the %2 role on server %3.\\You must choose a user that does not have the %2 role.', Comment = '%1 = user name, %2 = security role name, %3 = server address';
        UserRolesErr: Label 'User %1 does not have the required roles on server %3.\\You must choose a user that has the role %2.', Comment = '%1 = user name, %2 = security role name, %3 = server address';
        TeamRolesErr: Label 'Team %1 for business unit %2 does not have the required role %3.', Comment = '%1 = team name, %2 = business unit name, %3 = security role name';
        CannotAssignRoleToTeamErr: Label 'Cannot assign role %3 to team %1 for business unit %2.', Comment = '%1 = team name, %2 = business unit name, %3 = security role name';
        CannotAssignRoleToIntegrationUserErr: Label 'Cannot assign the integration role to the integration user.';
        UserNotLicensedErr: Label 'User %1 with access mode %3 is not licensed on server %2.', Comment = '%1 = user name, %2 = server address, %3 = access mode';
        UserNotActiveErr: Label 'User %1 is disabled on server %2.', Comment = '%1 = user name, %2 = server address';
        NotIntegrationUserErr: Label 'User %1 is not an integration user on server %2.', Comment = '%1 = user name, %2 = server address';
        NotNonInteractiveAccessModeErr: Label 'User %1 has invalid access mode %3 on server %2. Valid access mode is Non-Interactive.', Comment = '%1 = user name, %2 = server address, %3 = actual access mode';
        InvalidAccessModeErr: Label 'User %1 has invalid access mode %3 on server %2. Valid access modes are Read-Write or Non-Interactive.', Comment = '%1 = user name, %2 = server address, %3 = actual access mode';
        UserHasNoRolesErr: Label 'User %1 has no user roles assigned on server %2.', Comment = '%1 = user name, %2 = server address';
        NoSystemAdminRoleErr: Label 'Admin user %1 is not assigned to the System Administrator role on server %2.', Comment = '%1 = user name, %2 = server address';
        NoSystemCustomizerRoleErr: Label 'Admin user %1 is not assigned to the System Customizer role on server %2.', Comment = '%1 = user name, %2 = server address';
        ConnectionRequiredFieldsErr: Label 'A URL, user name and password are required.';
        ConnectionRequiredFieldsMismatchErr: Label 'The values of the Server Address, User Name, User Password and Authentication Type fields must match the corresponding field values on the Microsoft Dynamics 365 Connection Setup page.';
        ConnectionStringPwdPlaceHolderMissingErr: Label 'The connection string must include the password placeholder {PASSWORD}.';
        UserNameMustIncludeDomainErr: Label 'The user name must include the domain when the authentication type is set to Active Directory.';
        UserNameMustBeEmailErr: Label 'The user name must be a valid email address when the authentication type is set to Office 365.';
        LCYMustMatchBaseCurrencyErr: Label 'LCY Code %1 does not match ISO Currency Code %2 of the Common Data Service base currency.', Comment = '%1,%2 - ISO currency codes';
        UserSetupTxt: Label 'User Common Data Service Setup';
        CannotResolveUserFromConnectionSetupErr: Label 'The user that is specified in the Common Data Service Connection Setup does not exist.';
        MissingUsernameTok: Label '{USER}', Locked = true;
        MissingPasswordTok: Label '{PASSWORD}', Locked = true;
        SystemAdminRoleTemplateIdTxt: Label '627090ff-40a3-4053-8790-584edc5be201', Locked = true;
        SystemCustomizerRoleTemplateIdTxt: Label '119f245c-3cc8-4b62-b31c-d1a046ced15d', Locked = true;
        IntegrationRoleIdTxt: Label 'a2b18661-9ff5-e911-a812-000d3a0b9028', Locked = true;
        ErrorNotificationIdTxt: Label '5e9ed8ec-dc7d-42b5-b7fc-da8c08cea60f', Locked = true;
        ConnectionDisabledNotificationIdTxt: Label 'db1b4430-99b7-48c4-94ba-0e4975353134', Locked = true;
        ConnectionDefaultNameTok: Label 'Common Data Service', Locked = true;
        BaseSolutionUniqueNameTxt: Label 'bcbi_CdsBaseIntegration', Locked = true;
        BaseSolutionDisplayNameTxt: Label 'Business Central Common Data Service Base Integration', Locked = true;
        TemporaryConnectionName: Text;

    [Scope('OnPrem')]
    procedure GetBaseSolutionUniqueName(): Text
    begin
        exit(BaseSolutionUniqueNameTxt);
    end;

    [Scope('OnPrem')]
    procedure GetBaseSolutionDisplayName(): Text
    begin
        exit(BaseSolutionDisplayNameTxt);
    end;

    [Scope('OnPrem')]
    procedure IsConnectionActive(): Boolean
    begin
        exit(IsConnectionActive(GetConnectionDefaultName()));
    end;

    [Scope('OnPrem')]
    procedure IsConnectionActive(ConnectionName: Text): Boolean
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        if not CDSConnectionSetup.Get() then begin
            SendTraceTag('0000AQP', CategoryTok, VERBOSITY::Normal, IntegrationNotConfiguredTxt, DataClassification::SystemMetadata);
            exit(false);
        end;

        exit(IsConnectionActive(CDSConnectionSetup, ConnectionName));
    end;

    local procedure IsConnectionActive(var CDSConnectionSetup: Record "CDS Connection Setup"; ConnectionName: Text): Boolean
    var
        ActiveConnectionName: Text;
    begin
        if not CDSConnectionSetup."Is Enabled" then begin
            SendTraceTag('0000AQQ', CategoryTok, VERBOSITY::Normal, IntegrationNotConfiguredTxt, DataClassification::SystemMetadata);
            exit(false);
        end;
        if not HasTableConnection(TABLECONNECTIONTYPE::CRM, ConnectionName) then begin
            SendTraceTag('0000AQR', CategoryTok, VERBOSITY::Normal, NoConnectionTxt, DataClassification::SystemMetadata);
            exit(false);
        end;
        ActiveConnectionName := GetDefaultTableConnection(TABLECONNECTIONTYPE::CRM);
        if ConnectionName = ActiveConnectionName then begin
            SendTraceTag('0000AQS', CategoryTok, VERBOSITY::Normal, ConnectionActiveTxt, DataClassification::SystemMetadata);
            exit(true);
        end;
        SendTraceTag('0000AQT', CategoryTok, VERBOSITY::Normal, ConnectionNotActiveTxt, DataClassification::SystemMetadata);
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure ActivateConnection(): Boolean
    begin
        exit(ActivateConnection(GetConnectionDefaultName()));
    end;

    [Scope('OnPrem')]
    procedure ActivateConnection(ConnectionName: Text): Boolean
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        if not CDSConnectionSetup.Get() then begin
            SendTraceTag('0000AQU', CategoryTok, VERBOSITY::Normal, IntegrationNotConfiguredTxt, DataClassification::SystemMetadata);
            exit(false);
        end;
        if not CDSConnectionSetup."Is Enabled" then begin
            SendTraceTag('0000BFQ', CategoryTok, VERBOSITY::Normal, IntegrationDisabledTxt, DataClassification::SystemMetadata);
            exit(false);
        end;
        exit(ActivateConnection(CDSConnectionSetup, ConnectionName));
    end;

    local procedure ActivateConnection(var CDSConnectionSetup: Record "CDS Connection Setup"; ConnectionName: Text): Boolean
    var
        ActiveConnectionName: Text;
    begin
        SendTraceTag('0000AQV', CategoryTok, VERBOSITY::Normal, ActivateConnectionTxt, DataClassification::SystemMetadata);

        if IsConnectionActive(CDSConnectionSetup, ConnectionName) then begin
            SendTraceTag('0000AQW', CategoryTok, VERBOSITY::Normal, ConnectionActiveTxt, DataClassification::SystemMetadata);
            exit(true);
        end;

        if not HasTableConnection(TABLECONNECTIONTYPE::CRM, ConnectionName) then begin
            SendTraceTag('0000AQX', CategoryTok, VERBOSITY::Normal, NoConnectionTxt, DataClassification::SystemMetadata);
            exit(false);
        end;

        ActiveConnectionName := GetDefaultTableConnection(TABLECONNECTIONTYPE::CRM);
        if ConnectionName = ActiveConnectionName then begin
            SendTraceTag('0000AQY', CategoryTok, VERBOSITY::Normal, ConnectionActiveTxt, DataClassification::SystemMetadata);
            exit(true);
        end;

        if not CDSConnectionSetup.IsTemporary() then begin
            SendTraceTag('0000AQZ', CategoryTok, VERBOSITY::Normal, OnBeforeActivateConnectionTxt, DataClassification::SystemMetadata);
            CDSIntegrationMgt.OnBeforeActivateConnection();
        end;

        SetDefaultTableConnection(TABLECONNECTIONTYPE::CRM, ConnectionName, false);

        if not CDSConnectionSetup.IsTemporary() then begin
            SendTraceTag('0000AR0', CategoryTok, VERBOSITY::Normal, OnAfterActivateConnectionTxt, DataClassification::SystemMetadata);
            CDSIntegrationMgt.OnAfterActivateConnection();
        end;

        SendTraceTag('0000AR1', CategoryTok, VERBOSITY::Normal, ConnectionActivatedTxt, DataClassification::SystemMetadata);
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure HasConnection(): Boolean
    begin
        exit(HasConnection(GetConnectionDefaultName()));
    end;

    local procedure HasConnection(ConnectionName: Text): Boolean
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        if not CDSConnectionSetup.Get() then begin
            SendTraceTag('0000AR2', CategoryTok, VERBOSITY::Normal, IntegrationNotConfiguredTxt, DataClassification::SystemMetadata);
            exit(false);
        end;

        exit(HasConnection(CDSConnectionSetup, ConnectionName));
    end;

    local procedure HasConnection(var CDSConnectionSetup: Record "CDS Connection Setup"; ConnectionName: Text): Boolean
    begin
        if not CDSConnectionSetup."Is Enabled" then begin
            SendTraceTag('0000AR3', CategoryTok, VERBOSITY::Normal, IntegrationDisabledTxt, DataClassification::SystemMetadata);
            exit(false);
        end;

        if HasTableConnection(TABLECONNECTIONTYPE::CRM, ConnectionName) then begin
            SendTraceTag('0000AR4', CategoryTok, VERBOSITY::Normal, HasConnectionTxt, DataClassification::SystemMetadata);
            exit(true);
        end;

        SendTraceTag('0000AR5', CategoryTok, VERBOSITY::Normal, NoConnectionTxt, DataClassification::SystemMetadata);
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure RegisterConnection(): Boolean
    begin
        exit(RegisterConnection(true));
    end;

    [Scope('OnPrem')]
    procedure RegisterConnection(KeepExisting: Boolean): Boolean
    var
        ConnectionName: Text;
    begin
        ConnectionName := GetConnectionDefaultName();
        exit(RegisterConnection(ConnectionName, KeepExisting));
    end;

    [Scope('OnPrem')]
    procedure RegisterConnection(ConnectionName: Text): Boolean
    begin
        exit(RegisterConnection(ConnectionName, false));
    end;

    [Scope('OnPrem')]
    procedure RegisterConnection(ConnectionName: Text; KeepExisting: Boolean): Boolean
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        if not CDSConnectionSetup.Get() then begin
            SendTraceTag('0000AR6', CategoryTok, VERBOSITY::Normal, IntegrationNotConfiguredTxt, DataClassification::SystemMetadata);
            exit(false);
        end;

        if not CDSConnectionSetup."Is Enabled" then begin
            SendTraceTag('0000AR7', CategoryTok, VERBOSITY::Normal, IntegrationDisabledTxt, DataClassification::SystemMetadata);
            exit(false);
        end;

        exit(RegisterConnection(CDSConnectionSetup, ConnectionName, KeepExisting));
    end;

    [Scope('OnPrem')]
    procedure RegisterConnection(var CDSConnectionSetup: Record "CDS Connection Setup"; KeepExisting: Boolean): Boolean
    var
        ConnectionName: Text;
    begin
        ConnectionName := GetConnectionDefaultName();
        exit(RegisterConnection(CDSConnectionSetup, ConnectionName, KeepExisting));
    end;

    [Scope('OnPrem')]
    procedure RegisterConnection(var CDSConnectionSetup: Record "CDS Connection Setup"; ConnectionName: Text): Boolean
    begin
        exit(RegisterConnection(CDSConnectionSetup, ConnectionName, false));
    end;

    [Scope('OnPrem')]
    procedure RegisterConnection(var CDSConnectionSetup: Record "CDS Connection Setup"; ConnectionName: Text; KeepExisting: Boolean): Boolean
    var
        ConnectionString: Text;
        IsTemporary: Boolean;
    begin
        SendTraceTag('0000AR8', CategoryTok, VERBOSITY::Normal, RegisterConnectionTxt, DataClassification::SystemMetadata);

        IsTemporary := CDSConnectionSetup.IsTemporary();
        if not IsTemporary then
            if KeepExisting then
                if HasTableConnection(TABLECONNECTIONTYPE::CRM, ConnectionName) then begin
                    SendTraceTag('0000AR9', CategoryTok, VERBOSITY::Normal, HasConnectionTxt, DataClassification::SystemMetadata);
                    exit(true);
                end;

        ConnectionString := GetConnectionStringWithPassword(CDSConnectionSetup);
        if ConnectionString = '' then
            exit(false);

        if not UnregisterConnection(ConnectionName) then
            ClearLastError();

        if not IsTemporary then begin
            SendTraceTag('0000ARA', CategoryTok, VERBOSITY::Normal, OnBeforeRegisterConnectionTxt, DataClassification::SystemMetadata);
            CDSIntegrationMgt.OnBeforeRegisterConnection();
        end;

        if not TryRegisterTableConnection(ConnectionName, ConnectionString) then
            exit(false);

        if not IsTemporary then begin
            SendTraceTag('0000ARB', CategoryTok, VERBOSITY::Normal, OnAfterRegisterConnectionTxt, DataClassification::SystemMetadata);
            CDSIntegrationMgt.OnAfterRegisterConnection();
        end;

        SendTraceTag('0000ARC', CategoryTok, VERBOSITY::Normal, ConnectionRegisteredTxt, DataClassification::SystemMetadata);
        exit(true);
    end;

    [TryFunction]
    local procedure TryRegisterTableConnection(ConnectionName: Text; ConnectionString: Text)
    begin
        RegisterTableConnection(TABLECONNECTIONTYPE::CRM, ConnectionName, ConnectionString);
    end;

    [Scope('OnPrem')]
    procedure UnregisterConnection(): Boolean
    begin
        exit(UnregisterConnection(GetConnectionDefaultName()));
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure UnregisterConnection(ConnectionName: Text)
    var
        IsTemporary: Boolean;
    begin
        SendTraceTag('0000ARD', CategoryTok, VERBOSITY::Normal, UnregisterConnectionTxt, DataClassification::SystemMetadata);

        if not HasTableConnection(TableConnectionType::CRM, ConnectionName) then begin
            SendTraceTag('0000ARE', CategoryTok, VERBOSITY::Normal, NoConnectionTxt, DataClassification::SystemMetadata);
            exit;
        end;

        IsTemporary := ConnectionName.StartsWith(TemporaryConnectionPrefixTok);
        if not IsTemporary then begin
            SendTraceTag('0000ARF', CategoryTok, VERBOSITY::Normal, OnBeforeUnregisterConnectionTxt, DataClassification::SystemMetadata);
            CDSIntegrationMgt.OnBeforeUnregisterConnection();
        end;
        UnregisterTableConnection(TABLECONNECTIONTYPE::CRM, ConnectionName);
        if not IsTemporary then begin
            SendTraceTag('0000ARG', CategoryTok, VERBOSITY::Normal, OnAfterUnregisterConnectionTxt, DataClassification::SystemMetadata);
            CDSIntegrationMgt.OnAfterUnregisterConnection();
        end;

        SendTraceTag('0000ARH', CategoryTok, VERBOSITY::Normal, ConnectionUnregisteredTxt, DataClassification::SystemMetadata);
    end;

    [Scope('OnPrem')]
    procedure IsIntegrationEnabled(): Boolean
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        if not CDSConnectionSetup.Get() then begin
            SendTraceTag('0000ARI', CategoryTok, VERBOSITY::Normal, IntegrationNotConfiguredTxt, DataClassification::SystemMetadata);
            exit(false);
        end;

        if not CDSConnectionSetup."Is Enabled" then begin
            SendTraceTag('0000ARJ', CategoryTok, VERBOSITY::Normal, IntegrationDisabledTxt, DataClassification::SystemMetadata);
            exit(false);
        end;

        SendTraceTag('0000ARK', CategoryTok, VERBOSITY::Normal, IntegrationEnabledTxt, DataClassification::SystemMetadata);
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure GetConnectionDefaultName(): Text
    begin
        exit(ConnectionDefaultNameTok);
    end;

    [Scope('OnPrem')]
    procedure IsSolutionInstalled(): Boolean
    begin
        exit(IsSolutionInstalled(GetBaseSolutionUniqueName()));
    end;

    [Scope('OnPrem')]
    procedure IsSolutionInstalled(var CDSConnectionSetup: Record "CDS Connection Setup"): Boolean
    begin
        exit(IsSolutionInstalled(CDSConnectionSetup, GetBaseSolutionUniqueName()));
    end;

    [Scope('OnPrem')]
    procedure IsSolutionInstalled(UniqueName: Text): Boolean
    var
        CDSSolution: Record "CDS Solution";
    begin
        CDSSolution.SetRange(UniqueName, UniqueName);
        if CDSSolution.FindFirst() then
            if CDSSolution.InstalledOn <> 0DT then begin
                SendTraceTag('0000ARM', CategoryTok, VERBOSITY::Normal, SolutionInstalledTxt, DataClassification::SystemMetadata);
                exit(true);
            end;
        SendTraceTag('0000ARN', CategoryTok, VERBOSITY::Normal, SolutionNotInstalledTxt, DataClassification::SystemMetadata);
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure IsSolutionInstalled(var CDSConnectionSetup: Record "CDS Connection Setup"; UniqueName: Text): Boolean
    var
        Installed: Boolean;
    begin
        if not CheckConnectionRequiredFields(CDSConnectionSetup, true) then begin
            SendTraceTag('0000AVQ', CategoryTok, VERBOSITY::Normal, InvalidUserCredentialsTxt, DataClassification::SystemMetadata);
            exit(false);
        end;
        if TryCheckSolutionInstalled(CDSConnectionSetup, UniqueName, Installed) then
            if Installed then begin
                SendTraceTag('0000ARO', CategoryTok, VERBOSITY::Normal, SolutionInstalledTxt, DataClassification::SystemMetadata);
                exit(true);
            end;
        SendTraceTag('0000ARP', CategoryTok, VERBOSITY::Normal, SolutionNotInstalledTxt, DataClassification::SystemMetadata);
        exit(false);
    end;

    [TryFunction]
    local procedure TryCheckSolutionInstalled(var CDSConnectionSetup: Record "CDS Connection Setup"; UniqueName: Text; var Installed: Boolean)
    var
        CDSSolution: Record "CDS Solution";
        TempConnectionName: Text;
    begin
        TempConnectionName := GetTempConnectionName();
        RegisterConnection(CDSConnectionSetup, TempConnectionName);
        SetDefaultTableConnection(TABLECONNECTIONTYPE::CRM, TempConnectionName, true);

        CDSSolution.SetRange(UniqueName, UniqueName);
        if CDSSolution.FindFirst() then
            Installed := CDSSolution.InstalledOn <> 0DT
        else
            Installed := false;

        UnregisterTableConnection(TABLECONNECTIONTYPE::CRM, TempConnectionName);
    end;

    [Scope('OnPrem')]
    procedure GetSolutionVersion(var Version: Text): Boolean
    begin
        exit(GetSolutionVersion(GetBaseSolutionUniqueName(), Version));
    end;

    [Scope('OnPrem')]
    procedure GetSolutionVersion(var CDSConnectionSetup: Record "CDS Connection Setup"; var Version: Text): Boolean
    begin
        exit(GetSolutionVersion(CDSConnectionSetup, GetBaseSolutionUniqueName(), Version));
    end;

    [Scope('OnPrem')]
    procedure GetSolutionVersion(UniqueName: Text; var Version: Text): Boolean
    var
        CDSSolution: Record "CDS Solution";
    begin
        CDSSolution.SetRange(UniqueName, UniqueName);
        if CDSSolution.FindFirst() then
            if CDSSolution.InstalledOn <> 0DT then begin
                Version := CDSSolution.Version;
                SendTraceTag('0000ARQ', CategoryTok, VERBOSITY::Normal, SolutionVersionReceivedTxt, DataClassification::SystemMetadata);
                exit(true);
            end;
        Version := '';
        SendTraceTag('0000ARL', CategoryTok, VERBOSITY::Normal, CannotGetSolutionVersionTxt, DataClassification::SystemMetadata);
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure GetSolutionVersion(var CDSConnectionSetup: Record "CDS Connection Setup"; UniqueName: Text; var Version: Text): Boolean
    begin
        if TryGetSolutionVersion(CDSConnectionSetup, UniqueName, Version) then begin
            SendTraceTag('0000ARR', CategoryTok, VERBOSITY::Normal, SolutionVersionReceivedTxt, DataClassification::SystemMetadata);
            if Version <> '' then
                exit(true);
        end;
        Version := '';
        SendTraceTag('0000ARS', CategoryTok, VERBOSITY::Normal, CannotGetSolutionVersionTxt, DataClassification::SystemMetadata);
        exit(false);
    end;

    [TryFunction]
    local procedure TryGetSolutionVersion(var CDSConnectionSetup: Record "CDS Connection Setup"; UniqueName: Text; var Version: Text)
    var
        CDSSolution: Record "CDS Solution";
        TempConnectionName: Text;
    begin
        TempConnectionName := GetTempConnectionName();
        RegisterConnection(CDSConnectionSetup, TempConnectionName);
        SetDefaultTableConnection(TABLECONNECTIONTYPE::CRM, TempConnectionName, true);

        Version := '';
        CDSSolution.SetRange(UniqueName, UniqueName);
        if CDSSolution.FindFirst() then
            if CDSSolution.InstalledOn <> 0DT then
                Version := CDSSolution.Version;
        if Version <> '' then
            SendTraceTag('0000AVR', CategoryTok, VERBOSITY::Normal, SolutionNotInstalledTxt, DataClassification::SystemMetadata)
        else
            SendTraceTag('0000ART', CategoryTok, VERBOSITY::Normal, SolutionNotInstalledTxt, DataClassification::SystemMetadata);

        UnregisterTableConnection(TABLECONNECTIONTYPE::CRM, TempConnectionName);
    end;

    local procedure SetUserAsIntegrationUser(var CDSConnectionSetup: Record "CDS Connection Setup"; AdminUser: Text; AdminPassword: Text)
    var
        CRMSystemuser: Record "CRM Systemuser";
        TempAdminCDSConnectionSetup: Record "CDS Connection Setup" temporary;
        TempConnectionName: Text;
    begin
        SendTraceTag('0000ARW', CategoryTok, VERBOSITY::Normal, SetUserAsIntegrationUserTxt, DataClassification::SystemMetadata);

        GetTempAdminConnectionSetup(TempAdminCDSConnectionSetup, CDSConnectionSetup, AdminUser, AdminPassword);
        TempConnectionName := GetTempConnectionName();
        RegisterConnection(TempAdminCDSConnectionSetup, TempConnectionName);
        SetDefaultTableConnection(TABLECONNECTIONTYPE::CRM, TempConnectionName, true);

        // Table connection is scoped, therefore all manipulations with CDS tables must be placed
        // in this procedure between SetDefaultTableConnection and UnregisterConnection

        FilterUser(CDSConnectionSetup, CRMSystemuser);
        if not CRMSystemuser.FindFirst() then begin
            SendTraceTag('0000ARX', CategoryTok, VERBOSITY::Normal, UserNotFoundTxt, DataClassification::SystemMetadata);
            Error(CannotResolveUserFromConnectionSetupErr);
        end;
        if (CRMSystemuser.InviteStatusCode <> CRMSystemuser.InviteStatusCode::InvitationAccepted) or
           (not CRMSystemuser.IsIntegrationUser)
        then begin
            SendTraceTag('0000ARY', CategoryTok, VERBOSITY::Normal, SetUserAsIntegrationUserTxt, DataClassification::SystemMetadata);
            CRMSystemuser.InviteStatusCode := CRMSystemuser.InviteStatusCode::InvitationAccepted;
            CRMSystemuser.IsIntegrationUser := true;
            if not CRMSystemuser.Modify() then
                SendTraceTag('0000ARZ', CategoryTok, VERBOSITY::Normal, CannotSetUserAsIntegrationUserTxt, DataClassification::SystemMetadata)
            else
                SendTraceTag('0000AS0', CategoryTok, VERBOSITY::Normal, UserSetAsIntegrationUserTxt, DataClassification::SystemMetadata);
        end else
            SendTraceTag('0000AS1', CategoryTok, VERBOSITY::Normal, UserAlreadySetAsIntegrationUserTxt, DataClassification::SystemMetadata);

        UnregisterTableConnection(TABLECONNECTIONTYPE::CRM, TempConnectionName);
    end;

    local procedure SetAccessModeToNonInteractive(var CDSConnectionSetup: Record "CDS Connection Setup"; AdminUser: Text; AdminPassword: Text): Boolean
    var
        CRMSystemuser: Record "CRM Systemuser";
        TempAdminCDSConnectionSetup: Record "CDS Connection Setup" temporary;
        TempConnectionName: Text;
        ChangedToNonInteractive: Boolean;
    begin
        SendTraceTag('0000B2I', CategoryTok, VERBOSITY::Normal, SetAccessModeToNonInteractiveTxt, DataClassification::SystemMetadata);

        GetTempAdminConnectionSetup(TempAdminCDSConnectionSetup, CDSConnectionSetup, AdminUser, AdminPassword);
        TempConnectionName := GetTempConnectionName();
        RegisterConnection(TempAdminCDSConnectionSetup, TempConnectionName);
        SetDefaultTableConnection(TABLECONNECTIONTYPE::CRM, TempConnectionName, true);

        // Table connection is scoped, therefore all manipulations with CDS tables must be placed
        // in this procedure between SetDefaultTableConnection and UnregisterConnection

        FilterUser(CDSConnectionSetup, CRMSystemuser);
        if not CRMSystemuser.FindFirst() then begin
            SendTraceTag('0000B2J', CategoryTok, VERBOSITY::Normal, UserNotFoundTxt, DataClassification::SystemMetadata);
            Error(CannotResolveUserFromConnectionSetupErr);
        end;

        if CRMSystemuser.AccessMode <> CRMSystemuser.AccessMode::"Non-interactive" then begin
            SendTraceTag('0000B2A', CategoryTok, VERBOSITY::Normal, SetAccessModeToNonInteractiveTxt, DataClassification::SystemMetadata);
            CRMSystemuser.AccessMode := CRMSystemuser.AccessMode::"Non-interactive";
            if not CRMSystemuser.Modify() then
                SendTraceTag('0000B2B', CategoryTok, VERBOSITY::Normal, CannotSetAccessModeToNonInteractiveTxt, DataClassification::SystemMetadata)
            else begin
                ChangedToNonInteractive := CRMSystemuser.AccessMode = CRMSystemuser.AccessMode::"Non-interactive";
                if ChangedToNonInteractive then
                    SendTraceTag('0000B2C', CategoryTok, VERBOSITY::Normal, AccessModeSetToNonInteractiveTxt, DataClassification::SystemMetadata)
                else
                    SendTraceTag('0000B2H', CategoryTok, VERBOSITY::Normal, CannotSetAccessModeToNonInteractiveTxt, DataClassification::SystemMetadata)
            end;
        end else
            SendTraceTag('0000B2D', CategoryTok, VERBOSITY::Normal, AccessModeAlreadySetToNonInteractiveTxt, DataClassification::SystemMetadata);

        UnregisterTableConnection(TABLECONNECTIONTYPE::CRM, TempConnectionName);

        exit(ChangedToNonInteractive);
    end;

    local procedure SyncCompany(var CDSConnectionSetup: Record "CDS Connection Setup"; AdminUser: Text; AdminPassword: Text)
    var
        TempAdminCDSConnectionSetup: Record "CDS Connection Setup" temporary;
        Company: Record Company;
        GeneralLedgerSetup: Record "General Ledger Setup";
        CDSCompany: Record "CDS Company";
        RootCRMBusinessunit: Record "CRM Businessunit";
        DefaultCRMBusinessunit: Record "CRM Businessunit";
        UpdatedCRMBusinessunit: Record "CRM Businessunit";
        CRMBusinessunit: Record "CRM Businessunit";
        DefaultCRMTeam: Record "CRM Team";
        InitialCRMTeam: Record "CRM Team";
        UpdatingCRMTeam: Record "CRM Team";
        UpdatedCRMTeam: Record "CRM Team";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        CRMOrganization: Record "CRM Organization";
        CRMRole: Record "CRM Role";
        CrmHelper: DotNet CrmHelper;
        TempConnectionName: Text;
        CompanyId: Text[36];
        CompanyName: Text[30];
        BusinessUnitName: Text[160];
        TeamName: Text[160];
        IntegrationRoleName: Text[100];
        EmptyGuid: Guid;
        UpdateOwningTeam: Boolean;
        OwningTeamUpdated: Boolean;
    begin
        SendTraceTag('0000AS2', CategoryTok, VERBOSITY::Normal, SynchronizeCompanyTxt, DataClassification::SystemMetadata);

        ResetCache();

        Company.Get(CompanyName());
        CompanyId := GetCompanyExternalId(Company);
        CompanyName := CopyStr(Company.Name, 1, MaxStrLen(CompanyName));
        BusinessUnitName := GetDefaultBusinessUnitName(CompanyName, CompanyId);

        GetTempAdminConnectionSetup(TempAdminCDSConnectionSetup, CDSConnectionSetup, AdminUser, AdminPassword);
        InitializeConnection(CrmHelper, TempAdminCDSConnectionSetup);
        TempConnectionName := GetTempConnectionName();
        RegisterConnection(TempAdminCDSConnectionSetup, TempConnectionName);
        SetDefaultTableConnection(TABLECONNECTIONTYPE::CRM, TempConnectionName, true);

        // Table connection is scoped, therefore all manipulations with CDS tables must be placed
        // in this procedure between SetDefaultTableConnection and UnregisterConnection

        SendTraceTag('0000AS3', CategoryTok, VERBOSITY::Normal, CheckBusinessUnitTxt, DataClassification::SystemMetadata);
        RootCRMBusinessunit.SetRange(ParentBusinessUnitId, EmptyGuid);
        RootCRMBusinessunit.FindFirst();
        DefaultCRMBusinessunit.SetRange(ParentBusinessUnitId, RootCRMBusinessunit.BusinessUnitId);
        DefaultCRMBusinessunit.SetRange(Name, BusinessUnitName);
        if not DefaultCRMBusinessunit.FindFirst() then begin
            DefaultCRMBusinessunit.Name := BusinessUnitName;
            DefaultCRMBusinessunit.TransactionCurrencyId := CRMTransactioncurrency.TransactionCurrencyId;
            DefaultCRMBusinessunit.ParentBusinessUnitId := RootCRMBusinessunit.BusinessUnitId;
            if not DefaultCRMBusinessunit.Insert() then begin
                SendTraceTag('0000AS4', CategoryTok, VERBOSITY::Normal, CannotCreateBusinessUnitTxt, DataClassification::SystemMetadata);
                Error(CannotCreateBusinessUnitErr, BusinessUnitName);
            end;
            SendTraceTag('0000AS5', CategoryTok, VERBOSITY::Normal, BusinessUnitCreatedTxt, DataClassification::SystemMetadata);
        end else
            SendTraceTag('0000AS6', CategoryTok, VERBOSITY::Normal, BusinessUnitAlreadyExistsTxt, DataClassification::SystemMetadata);

        SendTraceTag('0000AS7', CategoryTok, VERBOSITY::Normal, CheckOwningTeamTxt, DataClassification::SystemMetadata);
        TeamName := GetOwningTeamName(DefaultCRMBusinessunit.Name);
        FilterTeam(DefaultCRMBusinessunit.BusinessUnitId, TeamName, DefaultCRMTeam);
        if not DefaultCRMTeam.FindFirst() then begin
            DefaultCRMTeam.Name := TeamName;
            DefaultCRMTeam.BusinessUnitId := DefaultCRMBusinessunit.BusinessUnitId;
            DefaultCRMTeam.TeamType := DefaultCRMTeam.TeamType::Owner;
            if not DefaultCRMTeam.Insert() then begin
                SendTraceTag('0000AS8', CategoryTok, VERBOSITY::Normal, CannotCreateTeamTxt, DataClassification::SystemMetadata);
                Error(CannotCreateTeamErr, TeamName, BusinessUnitName);
            end;
            SendTraceTag('0000AS9', CategoryTok, VERBOSITY::Normal, TeamCreatedTxt, DataClassification::SystemMetadata);
        end else
            SendTraceTag('0000ASA', CategoryTok, VERBOSITY::Normal, TeamAlreadyExistsTxt, DataClassification::SystemMetadata);

        SendTraceTag('0000ASB', CategoryTok, VERBOSITY::Normal, CheckTeamRolesTxt, DataClassification::SystemMetadata);
        if not CRMRole.Get(GetIntegrationRoleId()) then begin
            SendTraceTag('0000ASC', CategoryTok, VERBOSITY::Warning, IntegrationRoleNotFoundTxt, DataClassification::SystemMetadata);
            Error(IntegrationRoleNotFoundErr, IntegrationRoleName, RootCRMBusinessunit.Name);
        end;
        IntegrationRoleName := CRMRole.Name;

        CRMRole.SetRange(ParentRoleId, GetIntegrationRoleId());
        CRMRole.SetRange(BusinessUnitId, DefaultCRMBusinessunit.BusinessUnitId);
        if not CRMRole.FindFirst() then begin
            SendTraceTag('0000ASD', CategoryTok, VERBOSITY::Normal, RoleNotFoundForBusinessUnitTxt, DataClassification::SystemMetadata);
            Error(IntegrationRoleNotFoundErr, IntegrationRoleName, DefaultCRMBusinessunit.Name);
        end;
        if not AssignTeamRole(CrmHelper, DefaultCRMTeam.TeamId, CRMRole.RoleId) then begin
            SendTraceTag('0000ASE', CategoryTok, VERBOSITY::Normal, CannotAssignRoleToTeamTxt, DataClassification::SystemMetadata);
            Error(CannotAssignRoleToTeamErr, DefaultCRMTeam.Name, DefaultCRMBusinessunit.Name, IntegrationRoleName);
        end;
        SendTraceTag('0000ASF', CategoryTok, VERBOSITY::Normal, RoleAssignedToTeamTxt, DataClassification::SystemMetadata);

        SendTraceTag('0000ASG', CategoryTok, VERBOSITY::Normal, CheckCompanyTxt, DataClassification::SystemMetadata);
        CDSCompany.SetRange(ExternalId, CompanyId);
        if not CDSCompany.FindFirst() then begin
            SendTraceTag('0000ASH', CategoryTok, VERBOSITY::Normal, CreateCompanyTxt, DataClassification::SystemMetadata);
            if not CRMOrganization.FindFirst() then begin
                SendTraceTag('0000ASI', CategoryTok, VERBOSITY::Normal, OrganizationNotFoundTxt, DataClassification::SystemMetadata);
                Error(CannotFindOrganizationErr);
            end;
            if not CRMTransactioncurrency.Get(CRMOrganization.BaseCurrencyId) then begin
                SendTraceTag('0000ASJ', CategoryTok, VERBOSITY::Normal, CurrencyNotFoundTxt, DataClassification::SystemMetadata);
                Error(BaseCurrencyNotFoundErr);
            end;
            if not GeneralLedgerSetup.Get() then begin
                SendTraceTag('0000ASK', CategoryTok, VERBOSITY::Normal, GLSetupNotFoundTxt, DataClassification::SystemMetadata);
                Error(GLSetupNotFoundErr);
            end;
            if DelChr(CRMTransactioncurrency.ISOCurrencyCode) <> DelChr(GeneralLedgerSetup."LCY Code") then begin
                SendTraceTag('0000ASL', CategoryTok, VERBOSITY::Normal, CurrencyMismatchTxt, DataClassification::SystemMetadata);
                Error(LCYMustMatchBaseCurrencyErr, GeneralLedgerSetup."LCY Code", CRMTransactioncurrency.ISOCurrencyCode);
            end;
            CDSCompany.ExternalId := CompanyId;
            CDSCompany.Name := CompanyName;
            CDSCompany.DefaultOwningTeam := DefaultCRMTeam.TeamId;
            CDSCompany.OwnerIdType := CDSCompany.OwnerIdType::team;
            CDSCompany.OwnerId := DefaultCRMTeam.TeamId;
            if not CDSCompany.Insert() then begin
                SendTraceTag('0000ASM', CategoryTok, VERBOSITY::Normal, CannotCreateCompanyTxt, DataClassification::SystemMetadata);
                Error(CannotCreateCompanyErr, CompanyName);
            end;
            SendTraceTag('0000ASN', CategoryTok, VERBOSITY::Normal, CompanyCreatedTxt, DataClassification::SystemMetadata);
        end else begin
            SendTraceTag('0000ASO', CategoryTok, VERBOSITY::Normal, CompanyAlreadyExistsTxt, DataClassification::SystemMetadata);
            if IsNullGuid(CDSCompany.DefaultOwningTeam) then begin
                CDSCompany.DefaultOwningTeam := DefaultCRMTeam.TeamId;
                if not CDSCompany.Modify() then begin
                    SendTraceTag('0000ASP', CategoryTok, VERBOSITY::Normal, CannotSetDefaultOwningTeamTxt, DataClassification::SystemMetadata);
                    Error(CannotSetDefaultOwningTeamErr);
                end;
                SendTraceTag('0000ASQ', CategoryTok, VERBOSITY::Normal, DefaultOwningTeamSetTxt, DataClassification::SystemMetadata);
            end;
        end;

        UpdateOwningTeam := true;
        if InitialCRMTeam.Get(CDSCompany.DefaultOwningTeam) then
            if CRMBusinessunit.Get(InitialCRMTeam.BusinessUnitId) then
                UpdateOwningTeam :=
                    (CDSConnectionSetup."Business Unit Id" <> CRMBusinessunit.BusinessUnitId) or
                    (CDSConnectionSetup."Business Unit Name" <> CRMBusinessunit.Name);

        if UpdateOwningTeam and not IsNullGuid(CDSConnectionSetup."Business Unit Id") then
            if UpdatedCRMBusinessunit.Get(CDSConnectionSetup."Business Unit Id") then begin
                // update default owning team field on CDS company
                SendTraceTag('0000ASR', CategoryTok, Verbosity::Normal, CheckOwningTeamTxt, DataClassification::SystemMetadata);
                TeamName := GetOwningTeamName(UpdatedCRMBusinessunit.Name);
                FilterTeam(UpdatedCRMBusinessunit.BusinessUnitId, TeamName, UpdatingCRMTeam);
                if not UpdatingCRMTeam.FindFirst() then begin
                    UpdatingCRMTeam.Name := TeamName;
                    UpdatingCRMTeam.BusinessUnitId := UpdatedCRMBusinessunit.BusinessUnitId;
                    UpdatingCRMTeam.TeamType := UpdatingCRMTeam.TeamType::Owner;
                    if not UpdatingCRMTeam.Insert() then begin
                        SendTraceTag('0000ASS', CategoryTok, VERBOSITY::Normal, CannotCreateTeamTxt, DataClassification::SystemMetadata);
                        Error(CannotCreateTeamErr, TeamName, UpdatedCRMBusinessunit.Name);
                    end;
                    SendTraceTag('0000AST', CategoryTok, VERBOSITY::Normal, TeamCreatedTxt, DataClassification::SystemMetadata);
                end else
                    SendTraceTag('0000ASU', CategoryTok, VERBOSITY::Normal, TeamAlreadyExistsTxt, DataClassification::SystemMetadata);

                CRMRole.SetRange(ParentRoleId, GetIntegrationRoleId());
                CRMRole.SetRange(BusinessUnitId, UpdatedCRMBusinessunit.BusinessUnitId);
                if not CRMRole.FindFirst() then begin
                    SendTraceTag('0000ASV', CategoryTok, VERBOSITY::Normal, RoleNotFoundForBusinessUnitTxt, DataClassification::SystemMetadata);
                    Error(IntegrationRoleNotFoundErr, IntegrationRoleName, UpdatedCRMBusinessunit.Name);
                end;
                if not AssignTeamRole(CrmHelper, UpdatingCRMTeam.TeamId, CRMRole.RoleId) then begin
                    SendTraceTag('0000ASW', CategoryTok, VERBOSITY::Normal, CannotAssignRoleToTeamTxt, DataClassification::SystemMetadata);
                    Error(CannotAssignRoleToTeamErr, UpdatingCRMTeam.Name, UpdatedCRMBusinessunit.Name, IntegrationRoleName);
                end;
                SendTraceTag('0000ASX', CategoryTok, VERBOSITY::Normal, RoleAssignedToTeamTxt, DataClassification::SystemMetadata);

                CDSCompany.DefaultOwningTeam := UpdatingCRMTeam.TeamId;
                if not CDSCompany.Modify() then begin
                    SendTraceTag('0000ASY', CategoryTok, VERBOSITY::Warning, CannotSetDefaultOwningTeamTxt, DataClassification::SystemMetadata);
                    Error(CannotSetDefaultOwningTeamErr);
                end;
                OwningTeamUpdated := true;
                SendTraceTag('0000ASZ', CategoryTok, VERBOSITY::Normal, DefaultOwningTeamSetTxt, DataClassification::SystemMetadata);
            end else
                SendTraceTag('0000AT0', CategoryTok, VERBOSITY::Normal, BusinessUnitNotFoundTxt, DataClassification::SystemMetadata);

        if not OwningTeamUpdated then begin
            UpdatedCRMTeam.Get(CDSCompany.DefaultOwningTeam);
            if not UpdatedCRMBusinessunit.Get(UpdatedCRMTeam.BusinessUnitId) then begin
                SendTraceTag('0000AT1', CategoryTok, VERBOSITY::Normal, BusinessUnitNotFoundTxt, DataClassification::SystemMetadata);
                Error(BusinessUnitNotFoundErr, UpdatedCRMTeam.BusinessUnitId);
            end;
            if (CDSConnectionSetup."Business Unit Id" <> UpdatedCRMBusinessunit.BusinessUnitId) or
                (CDSConnectionSetup."Business Unit Name" <> UpdatedCRMBusinessunit.Name) then begin
                // fix business unit related fields in the setup table
                SendTraceTag('0000AT2', CategoryTok, VERBOSITY::Normal, BusinessUnitFixedTxt, DataClassification::SystemMetadata);
                CDSConnectionSetup."Business Unit Id" := UpdatedCRMBusinessunit.BusinessUnitId;
                CDSConnectionSetup."Business Unit Name" := UpdatedCRMBusinessunit.Name;
                ModifyBusinessUnitCoupling(CDSConnectionSetup);
            end else
                SendTraceTag('0000AT3', CategoryTok, VERBOSITY::Normal, BusinessUnitCoupledTxt, DataClassification::SystemMetadata);
        end;

        UnregisterTableConnection(TABLECONNECTIONTYPE::CRM, TempConnectionName);

        SendTraceTag('0000AT4', CategoryTok, VERBOSITY::Normal, CompanySynchronizedTxt, DataClassification::SystemMetadata);
    end;

    local procedure GetTempAdminConnectionSetup(var TempAdminCDSConnectionSetup: Record "CDS Connection Setup" temporary; var CDSConnectionSetup: Record "CDS Connection Setup"; AdminUser: Text; AdminPassword: Text)
    begin
        TempAdminCDSConnectionSetup.Init();
        TempAdminCDSConnectionSetup."Proxy Version" := CDSConnectionSetup."Proxy Version";
        TempAdminCDSConnectionSetup."Server Address" := CDSConnectionSetup."Server Address";
        TempAdminCDSConnectionSetup."User Name" := CopyStr(AdminUser, 1, MaxStrLen(TempAdminCDSConnectionSetup."User Name"));
        TempAdminCDSConnectionSetup.SetPassword(AdminPassword);
        UpdateConnectionString(TempAdminCDSConnectionSetup);
    end;

    [Scope('OnPrem')]
    procedure TestActiveConnection(): Boolean
    begin
        if TryCheckEntitiesAvailability() then begin
            SendTraceTag('0000AT5', CategoryTok, VERBOSITY::Normal, ConnectionTestSucceedTxt, DataClassification::SystemMetadata);
            exit(true);
        end;
        SendTraceTag('0000AT6', CategoryTok, VERBOSITY::Normal, ConnectionTestFailedTxt, DataClassification::SystemMetadata);
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure TestSystemUsersAvailability()
    begin
        CheckSystemUsersAvailability();
    end;


    [Scope('OnPrem')]
    procedure CheckIntegrationRequirements(var CDSConnectionSetup: Record "CDS Connection Setup"; Silent: Boolean): Boolean
    begin
        if Silent then begin
            if not TryCheckIntegrationRequirements(CDSConnectionSetup) then begin
                SendTraceTag('0000AT7', CategoryTok, VERBOSITY::Normal, IntegrationRequirementsNotMetTxt, DataClassification::SystemMetadata);
                exit(false);
            end;

            SendTraceTag('0000AU0', CategoryTok, VERBOSITY::Normal, IntegrationRequirementsMetTxt, DataClassification::SystemMetadata);
            exit(true);
        end;

        CheckIntegrationRequirements(CDSConnectionSetup);
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure CheckIntegrationSolutionRequirements(var CDSConnectionSetup: Record "CDS Connection Setup"; Silent: Boolean): Boolean
    begin
        if Silent then begin
            if not TryCheckIntegrationSolutionRequirements(CDSConnectionSetup) then begin
                SendTraceTag('0000AT8', CategoryTok, VERBOSITY::Normal, SolutionRequirementsNotMetTxt, DataClassification::SystemMetadata);
                exit(false);
            end;
            exit(true);
        end;
        CheckIntegrationSolutionRequirements(CDSConnectionSetup);
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure CheckIntegrationUserRequirements(var CDSConnectionSetup: Record "CDS Connection Setup"; Silent: Boolean): Boolean
    begin
        if Silent then begin
            if not TryCheckIntegrationUserRequirements(CDSConnectionSetup) then begin
                SendTraceTag('0000AT9', CategoryTok, VERBOSITY::Normal, IntegrationUserRequirementsNotMetTxt, DataClassification::SystemMetadata);
                exit(false);
            end;
            exit(true);
        end;
        CheckIntegrationUserRequirements(CDSConnectionSetup);
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure CheckOwningTeamRequirements(var CDSConnectionSetup: Record "CDS Connection Setup"; Silent: Boolean): Boolean
    begin
        if Silent then begin
            if not TryCheckOwningTeamRequirements(CDSConnectionSetup) then begin
                SendTraceTag('0000ATA', CategoryTok, VERBOSITY::Normal, OwningTeamRequirementsNotMetTxt, DataClassification::SystemMetadata);
                exit(false);
            end;
            exit(true);
        end;
        CheckOwningTeamRequirements(CDSConnectionSetup);
        exit(true);
    end;

    [TryFunction]
    local procedure TryCheckIntegrationRequirements(var CDSConnectionSetup: Record "CDS Connection Setup")
    begin
        CheckIntegrationRequirements(CDSConnectionSetup);
    end;

    local procedure CheckIntegrationRequirements(var CDSConnectionSetup: Record "CDS Connection Setup")
    begin
        CheckIntegrationSolutionRequirements(CDSConnectionSetup);
        CheckIntegrationUserRequirements(CDSConnectionSetup);
        CheckOwningTeamRequirements(CDSConnectionSetup);
        CheckEntitiesAvailability(CDSConnectionSetup);
    end;

    [TryFunction]
    local procedure TryCheckIntegrationSolutionRequirements(var CDSConnectionSetup: Record "CDS Connection Setup")
    begin
        CheckIntegrationSolutionRequirements(CDSConnectionSetup);
    end;

    local procedure CheckIntegrationSolutionRequirements(var CDSConnectionSetup: Record "CDS Connection Setup")
    var
        Version: Text;
    begin
        if not GetSolutionVersion(CDSConnectionSetup, Version) then begin
            SendTraceTag('0000ATC', CategoryTok, VERBOSITY::Warning, SolutionNotInstalledTxt, DataClassification::SystemMetadata);
            Error(BaseIntegrationSolutionNotInstalledErr, GetBaseSolutionDisplayName());
        end;

        if not IsSolutionVersionValid(Version) then begin
            SendTraceTag('0000ATD', CategoryTok, VERBOSITY::Normal, InvalidSolutionVersionTxt, DataClassification::SystemMetadata);
            Error(SolutionVersionErr);
        end;
    end;

    [TryFunction]
    local procedure TryCheckIntegrationUserRequirements(var CDSConnectionSetup: Record "CDS Connection Setup")
    begin
        CheckIntegrationUserRequirements(CDSConnectionSetup);
    end;

    local procedure CheckIntegrationUserRequirements(var CDSConnectionSetup: Record "CDS Connection Setup")
    var
        CRMRole: Record "CRM Role";
        TempCRMRole: Record "CRM Role" temporary;
        CRMSystemuserroles: Record "CRM Systemuserroles";
        CRMSystemuser: Record "CRM Systemuser";
        IntegrationRoleName: Text;
        SystemAdminRoleName: Text;
        TempConnectionName: Text;
        IntegrationRoleDeployed: Boolean;
        ChosenUserHasSystemAdminRole: Boolean;
        ChosenUserHasIntegrationRole: Boolean;
    begin
        TempConnectionName := GetTempConnectionName();
        RegisterConnection(CDSConnectionSetup, TempConnectionName);
        SetDefaultTableConnection(TableConnectionType::CRM, TempConnectionName, true);

        if CRMRole.FindSet() then
            repeat
                TempCRMRole.TransferFields(CRMRole);
                TempCRMRole.Insert();
                if TempCRMRole.RoleId = GetIntegrationRoleId() then begin
                    IntegrationRoleDeployed := true;
                    IntegrationRoleName := TempCRMRole.Name;
                end;
            until CRMRole.Next() = 0;

        FilterUser(CDSConnectionSetup, CRMSystemuser);
        if CRMSystemuser.FindFirst() then begin
            if CRMSystemuser.IsDisabled then begin
                SendTraceTag('0000ATF', CategoryTok, Verbosity::Normal, UserNotActiveTxt, DataClassification::SystemMetadata);
                Error(UserNotActiveErr, CDSConnectionSetup."User Name", CDSConnectionSetup."Server Address");
            end;

            if not CRMSystemuser.IsIntegrationUser then begin
                SendTraceTag('0000B2E', CategoryTok, Verbosity::Normal, NotIntegrationUserTxt, DataClassification::SystemMetadata);
                Error(NotIntegrationUserErr, CDSConnectionSetup."User Name", CDSConnectionSetup."Server Address");
            end;

            if CRMSystemuser.AccessMode <> CRMSystemuser.AccessMode::"Non-interactive" then begin
                SendTraceTag('0000B2F', CategoryTok, Verbosity::Normal, NotNonInteractiveAccessModeTxt, DataClassification::SystemMetadata);
                Error(NotNonInteractiveAccessModeErr, CDSConnectionSetup."User Name", CDSConnectionSetup."Server Address", CRMSystemuser.AccessMode);
            end;

            CRMSystemuserroles.SetRange(SystemUserId, CRMSystemuser.SystemUserId);
            if CRMSystemuserroles.FindSet() then
                repeat
                    if TempCRMRole.Get(CRMSystemuserroles.RoleId) then begin
                        if TempCRMRole.RoleTemplateId = GetSystemAdminRoleTemplateId() then begin
                            ChosenUserHasSystemAdminRole := true;
                            SystemAdminRoleName := TempCRMRole.Name
                        end;
                        if TempCRMRole.RoleId = GetIntegrationRoleId() then
                            ChosenUserHasIntegrationRole := true;
                    end;
                until CRMSystemuserroles.Next() = 0
            else
                if (CDSConnectionSetup."Server Address" <> '') and (CDSConnectionSetup."Server Address" <> TestServerAddressTok) then begin
                    SendTraceTag('0000ATH', CategoryTok, Verbosity::Normal, UserHasNoRolesTxt, DataClassification::SystemMetadata);
                    Error(UserHasNoRolesErr, CDSConnectionSetup."User Name", CDSConnectionSetup."Server Address");
                end;

            if ChosenUserHasSystemAdminRole then begin
                SendTraceTag('0000ATI', CategoryTok, Verbosity::Normal, SystemAdminRoleTxt, DataClassification::SystemMetadata);
                Error(SystemAdminErr, CDSConnectionSetup."User Name", SystemAdminRoleName, CDSConnectionSetup."Server Address");
            end;

            if IntegrationRoleDeployed and (not ChosenUserHasIntegrationRole) then begin
                SendTraceTag('0000ATJ', CategoryTok, Verbosity::Normal, NoIntegrationRoleTxt, DataClassification::SystemMetadata);
                Error(UserRolesErr, CDSConnectionSetup."User Name", IntegrationRoleName, CDSConnectionSetup."Server Address");
            end;
        end;

        UnregisterTableConnection(TableConnectionType::CRM, TempConnectionName);
    end;

    [TryFunction]
    local procedure TryCheckIntegrationUserPrerequisites(var CDSConnectionSetup: Record "CDS Connection Setup")
    begin
        CheckIntegrationUserPrerequisites(CDSConnectionSetup, CDSConnectionSetup."User Name", CDSConnectionSetup.GetPassword());
    end;

    [Scope('OnPrem')]
    procedure CheckIntegrationUserPrerequisites(var CDSConnectionSetup: Record "CDS Connection Setup"; UserName: Text; UserPassword: Text)
    var
        TempCDSConnectionSetup: Record "CDS Connection Setup" temporary;
        CRMRole: Record "CRM Role";
        CRMSystemuserroles: Record "CRM Systemuserroles";
        CRMSystemuser: Record "CRM Systemuser";
        TempConnectionName: Text;
    begin
        GetTempAdminConnectionSetup(TempCDSConnectionSetup, CDSConnectionSetup, UserName, UserPassword);
        CheckConnectionRequiredFields(TempCDSConnectionSetup, false);
        TempConnectionName := GetTempConnectionName();
        RegisterConnection(TempCDSConnectionSetup, TempConnectionName);
        SetDefaultTableConnection(TableConnectionType::CRM, TempConnectionName, true);

        FilterUser(CDSConnectionSetup, CRMSystemuser);
        if not CRMSystemuser.FindFirst() then begin
            SendTraceTag('0000BNG', CategoryTok, Verbosity::Normal, UserNotFoundTxt, DataClassification::SystemMetadata);
            Error(UserDoesNotExistErr, CDSConnectionSetup."User Name");
        end;

        if CRMSystemuser.IsDisabled then begin
            SendTraceTag('0000BNH', CategoryTok, Verbosity::Normal, UserNotActiveTxt, DataClassification::SystemMetadata);
            Error(UserNotActiveErr, CDSConnectionSetup."User Name", CDSConnectionSetup."Server Address");
        end;

        if not (CRMSystemuser.AccessMode in [CRMSystemuser.AccessMode::"Read-Write", CRMSystemuser.AccessMode::"Non-interactive"]) then begin
            SendTraceTag('0000B2G', CategoryTok, VERBOSITY::Normal, InvalidAccessModeTxt, DataClassification::SystemMetadata);
            Error(InvalidAccessModeErr, CDSConnectionSetup."User Name", CDSConnectionSetup."Server Address", CRMSystemuser.AccessMode);
        end;

        if (not CRMSystemuser.IsLicensed) and (CRMSystemuser.AccessMode <> CRMSystemuser.AccessMode::"Non-interactive") then begin
            SendTraceTag('0000ATG', CategoryTok, Verbosity::Normal, UserNotLicensedTxt, DataClassification::SystemMetadata);
            Error(UserNotLicensedErr, CDSConnectionSetup."User Name", CDSConnectionSetup."Server Address", CRMSystemuser.AccessMode);
        end;

        CRMSystemuserroles.SetRange(SystemUserId, CRMSystemuser.SystemUserId);
        if CRMSystemuserroles.FindSet() then
            repeat
                if CRMRole.Get(CRMSystemuserroles.RoleId) then
                    if CRMRole.RoleTemplateId = GetSystemAdminRoleTemplateId() then begin
                        SendTraceTag('0000BNJ', CategoryTok, Verbosity::Normal, SystemAdminRoleTxt, DataClassification::SystemMetadata);
                        Error(SystemAdminErr, CDSConnectionSetup."User Name", CRMRole.Name, CDSConnectionSetup."Server Address");
                    end;
            until CRMSystemuserroles.Next() = 0;

        UnregisterTableConnection(TableConnectionType::CRM, TempConnectionName);
    end;

    [Scope('OnPrem')]
    procedure CheckAdminUserPrerequisites(var CDSConnectionSetup: Record "CDS Connection Setup"; AdminUser: Text; AdminPassword: Text)
    var
        TempCDSConnectionSetup: Record "CDS Connection Setup" temporary;
        CRMRole: Record "CRM Role";
        CRMSystemuserroles: Record "CRM Systemuserroles";
        CRMSystemuser: Record "CRM Systemuser";
        TempConnectionName: Text;
        HasSystemAdminRole: Boolean;
        HasSystemCustomizerRole: Boolean;
    begin
        GetTempAdminConnectionSetup(TempCDSConnectionSetup, CDSConnectionSetup, AdminUser, AdminPassword);
        CheckConnectionRequiredFields(TempCDSConnectionSetup, false);
        TempConnectionName := GetTempConnectionName();
        RegisterConnection(TempCDSConnectionSetup, TempConnectionName);
        SetDefaultTableConnection(TableConnectionType::CRM, TempConnectionName, true);

        FilterUser(TempCDSConnectionSetup, CRMSystemuser);
        if not CRMSystemuser.FindFirst() then begin
            SendTraceTag('0000BNK', CategoryTok, Verbosity::Normal, UserNotFoundTxt, DataClassification::SystemMetadata);
            Error(UserDoesNotExistErr, TempCDSConnectionSetup."User Name");
        end;

        if CRMSystemuser.IsDisabled then begin
            SendTraceTag('0000BNL', CategoryTok, Verbosity::Normal, UserNotActiveTxt, DataClassification::SystemMetadata);
            Error(UserNotActiveErr, TempCDSConnectionSetup."User Name", TempCDSConnectionSetup."Server Address");
        end;

        if not CRMSystemuser.IsLicensed then begin
            SendTraceTag('0000BNM', CategoryTok, Verbosity::Normal, UserNotLicensedTxt, DataClassification::SystemMetadata);
            Error(UserNotLicensedErr, TempCDSConnectionSetup."User Name", TempCDSConnectionSetup."Server Address", CRMSystemuser.AccessMode);
        end;

        CRMSystemuserroles.SetRange(SystemUserId, CRMSystemuser.SystemUserId);
        if not CRMSystemuserroles.FindSet() then
            if (CDSConnectionSetup."Server Address" <> '') and (CDSConnectionSetup."Server Address" <> TestServerAddressTok) then begin
                SendTraceTag('0000BNN', CategoryTok, Verbosity::Normal, UserHasNoRolesTxt, DataClassification::SystemMetadata);
                Error(UserHasNoRolesErr, TempCDSConnectionSetup."User Name", TempCDSConnectionSetup."Server Address");
            end;

        repeat
            if CRMRole.Get(CRMSystemuserroles.RoleId) then begin
                if CRMRole.RoleTemplateId = GetSystemAdminRoleTemplateId() then
                    HasSystemAdminRole := true;
                if CRMRole.RoleTemplateId = GetSystemCustomizerRoleTemplateId() then
                    HasSystemCustomizerRole := true;
            end;
        until CRMSystemuserroles.Next() = 0;

        if not HasSystemAdminRole then begin
            SendTraceTag('0000BNO', CategoryTok, Verbosity::Normal, NoSystemAdminRoleTxt, DataClassification::SystemMetadata);
            Error(NoSystemAdminRoleErr, TempCDSConnectionSetup."User Name", TempCDSConnectionSetup."Server Address");
        end;

        if not HasSystemCustomizerRole then begin
            SendTraceTag('0000BNP', CategoryTok, Verbosity::Normal, NoSystemCustomizerRoleTxt, DataClassification::SystemMetadata);
            Error(NoSystemCustomizerRoleErr, TempCDSConnectionSetup."User Name", TempCDSConnectionSetup."Server Address");
        end;

        UnregisterTableConnection(TableConnectionType::CRM, TempConnectionName);
    end;

    [TryFunction]
    local procedure TryCheckOwningTeamRequirements(var CDSConnectionSetup: Record "CDS Connection Setup")
    begin
        CheckOwningTeamRequirements(CDSConnectionSetup);
    end;

    local procedure CheckOwningTeamRequirements(var CDSConnectionSetup: Record "CDS Connection Setup")
    var
        CRMRole: Record "CRM Role";
        CDSCompany: Record "CDS Company";
        CDSTeamroles: Record "CDS Teamroles";
        CRMTeam: Record "CRM Team";
        CRMBusinessunit: Record "CRM Businessunit";
        IntegrationRoleName: Text;
        TempConnectionName: Text;
    begin
        TempConnectionName := GetTempConnectionName();
        RegisterConnection(CDSConnectionSetup, TempConnectionName);
        SetDefaultTableConnection(TABLECONNECTIONTYPE::CRM, TempConnectionName, true);

        if not CRMRole.Get(GetIntegrationRoleId()) then begin
            SendTraceTag('0000ATK', CategoryTok, Verbosity::Normal, IntegrationRoleNotFoundTxt, DataClassification::SystemMetadata);
            Error(RoleNotFoundErr, GetIntegrationRoleId());
        end;
        IntegrationRoleName := CRMRole.Name;

        if not TryGetCDSCompany(CDSCompany) then begin
            SendTraceTag('0000ATL', CategoryTok, Verbosity::Normal, CompanyNotFoundTxt, DataClassification::SystemMetadata);
            Error(CompanyNotFoundErr, GetCompanyExternalId());
        end;

        if not CRMTeam.Get(CDSCompany.DefaultOwningTeam) then begin
            SendTraceTag('0000ATM', CategoryTok, Verbosity::Normal, TeamNotFoundTxt, DataClassification::SystemMetadata);
            Error(TeamNotFoundErr, CDSCompany.DefaultOwningTeam);
        end;

        if not CRMBusinessunit.Get(CRMTeam.BusinessUnitId) then begin
            SendTraceTag('0000ATN', CategoryTok, Verbosity::Normal, BusinessUnitNotFoundTxt, DataClassification::SystemMetadata);
            Error(BusinessUnitNotFoundErr, CRMTeam.BusinessUnitId);
        end;

        if (CRMBusinessunit.BusinessUnitId <> CDSConnectionSetup."Business Unit Id") or
           (CRMBusinessunit.Name <> CDSConnectionSetup."Business Unit Name") then begin
            SendTraceTag('0000B24', CategoryTok, Verbosity::Normal, BusinessUnitMismatchTxt, DataClassification::SystemMetadata);
            Error(BusinessUnitMismatchErr);
        end;

        CRMRole.Reset();
        CRMRole.SetRange(BusinessUnitId, CRMBusinessunit.BusinessUnitId);
        CRMRole.SetRange(ParentRoleId, GetIntegrationRoleId());
        if not CRMRole.FindFirst() then begin
            SendTraceTag('0000ATO', CategoryTok, Verbosity::Normal, RoleNotFoundForBusinessUnitTxt, DataClassification::SystemMetadata);
            Error(IntegrationRoleNotFoundErr, IntegrationRoleName, CRMBusinessunit.Name);
        end;

        CDSTeamroles.SetRange(TeamId, CRMTeam.TeamId);
        CDSTeamroles.SetRange(RoleId, CRMRole.RoleId);
        if CDSTeamroles.IsEmpty() then begin
            SendTraceTag('0000ATP', CategoryTok, Verbosity::Normal, IntegrationRoleNotAssignedToTeamTxt, DataClassification::SystemMetadata);
            Error(TeamRolesErr, CRMTeam.Name, CRMBusinessunit.Name, IntegrationRoleName);
        end;

        UnregisterTableConnection(TABLECONNECTIONTYPE::CRM, TempConnectionName);
    end;

    [Scope('OnPrem')]
    procedure CheckEntitiesAvailability(var CDSConnectionSetup: Record "CDS Connection Setup"; Silent: Boolean): Boolean
    begin
        if Silent then
            exit(TryCheckEntitiesAvailability(CDSConnectionSetup));
        CheckEntitiesAvailability(CDSConnectionSetup);
        exit(true);
    end;

    [TryFunction]
    local procedure TryCheckEntitiesAvailability(var CDSConnectionSetup: Record "CDS Connection Setup")
    begin
        CheckEntitiesAvailability(CDSConnectionSetup);
    end;

    local procedure CheckEntitiesAvailability(var CDSConnectionSetup: Record "CDS Connection Setup")
    var
        CRMSystemuser: Record "CRM Systemuser";
        CRMTeam: Record "CRM Team";
        CRMRole: Record "CRM Role";
        CRMSystemuserroles: Record "CRM Systemuserroles";
        CRMBusinessunit: Record "CRM Businessunit";
        CRMAccount: Record "CRM Account";
        CRMContact: Record "CRM Contact";
        CDSCompany: Record "CDS Company";
        Id: Guid;
        TempConnectionName: Text;
    begin
        TempConnectionName := GetTempConnectionName();
        RegisterConnection(CDSConnectionSetup, TempConnectionName);
        SetDefaultTableConnection(TABLECONNECTIONTYPE::CRM, TempConnectionName, true);

        if CRMTeam.FindFirst() then
            Id := CRMTeam.TeamId;

        if CRMRole.FindFirst() then
            Id := CRMRole.RoleId;

        if CRMSystemuser.FindFirst() then
            Id := CRMSystemuser.SystemUserId;

        if CRMSystemuserroles.FindFirst() then
            Id := CRMSystemuserroles.SystemUserId;

        if CRMBusinessunit.FindFirst() then
            Id := CRMBusinessunit.BusinessUnitId;

        if CDSCompany.FindFirst() then
            Id := CDSCompany.CompanyId;

        if CRMAccount.FindFirst() then
            Id := CRMAccount.CompanyId;

        if CRMContact.FindFirst() then
            Id := CRMContact.CompanyId;

        UnregisterTableConnection(TABLECONNECTIONTYPE::CRM, TempConnectionName);
    end;

    local procedure CheckSystemUsersAvailability()
    var
        CDSSystemuser: Record "CRM Systemuser";
        Id: Guid;
    begin
        if CDSSystemuser.FindFirst() then
            Id := CDSSystemuser.SystemUserId;
    end;

    [TryFunction]
    local procedure TryCheckEntitiesAvailability()
    var
        CRMSystemuser: Record "CRM Systemuser";
        CRMTeam: Record "CRM Team";
        CRMRole: Record "CRM Role";
        CRMSystemuserroles: Record "CRM Systemuserroles";
        CRMBusinessunit: Record "CRM Businessunit";
        CRMAccount: Record "CRM Account";
        CRMContact: Record "CRM Contact";
        CDSCompany: Record "CDS Company";
        Id: Guid;
    begin
        if CRMTeam.FindFirst() then
            Id := CRMTeam.TeamId;

        if CRMRole.FindFirst() then
            Id := CRMRole.RoleId;

        if CRMSystemuser.FindFirst() then
            Id := CRMSystemuser.SystemUserId;

        if CRMSystemuserroles.FindFirst() then
            Id := CRMSystemuserroles.SystemUserId;

        if CRMBusinessunit.FindFirst() then
            Id := CRMBusinessunit.BusinessUnitId;

        if CDSCompany.FindFirst() then
            Id := CDSCompany.CompanyId;

        if CRMAccount.FindFirst() then
            Id := CRMAccount.CompanyId;

        if CRMContact.FindFirst() then
            Id := CRMContact.CompanyId;
    end;

    [Scope('OnPrem')]
    procedure SelectSDKVersion(var CDSConnectionSetup: Record "CDS Connection Setup"): Boolean
    var
        TempStack: Record TempStack temporary;
    begin
        if PAGE.RunModal(PAGE::"SDK Version List", TempStack) = ACTION::LookupOK then begin
            CDSConnectionSetup.Validate("Proxy Version", TempStack.StackOrder);
            exit(true);
        end;
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure SelectBusinessUnit(var CDSConnectionSetup: Record "CDS Connection Setup"): Boolean
    var
        TempCRMBusinessUnit: Record "CRM Businessunit" temporary;
        EmptyGuid: Guid;
        PrevBusinessUnitId: Guid;
        DefaultBusinessUnitName: Text[160];
        Changed: Boolean;
        AddArtificialDefaultBusinessUnit: Boolean;
    begin
        PrevBusinessUnitId := CDSConnectionSetup."Business Unit Id";
        DefaultBusinessUnitName := GetDefaultBusinessUnitName();

        if not GetFirstLevelBusinessUnits(CDSConnectionSetup, TempCRMBusinessUnit) then begin
            Changed := not IsNullGuid(PrevBusinessUnitId);
            if Changed then begin
                CDSConnectionSetup."Business Unit Id" := EmptyGuid;
                CDSConnectionSetup."Business Unit Name" := DefaultBusinessUnitName;
                ModifyBusinessUnitCoupling(CDSConnectionSetup);
            end;
            exit(Changed);
        end;

        TempCRMBusinessUnit.SetRange(Name, DefaultBusinessUnitName);
        AddArtificialDefaultBusinessUnit := TempCRMBusinessUnit.IsEmpty();
        TempCRMBusinessUnit.SetRange(Name);
        if AddArtificialDefaultBusinessUnit then begin
            TempCRMBusinessUnit.Init();
            TempCRMBusinessUnit.BusinessUnitId := EmptyGuid;
            TempCRMBusinessUnit.Name := StrSubstNo(NewBusinessUnitNameTemplateTok, DefaultBusinessUnitName);
            TempCRMBusinessUnit.Insert();
        end;

        if PAGE.RunModal(PAGE::"CDS Business Units", TempCRMBusinessUnit) <> ACTION::LookupOK then
            exit(false);

        Changed := TempCRMBusinessUnit.BusinessUnitId <> PrevBusinessUnitId;
        if Changed then begin
            CDSConnectionSetup."Business Unit Id" := TempCRMBusinessUnit.BusinessUnitId;
            if IsNullGuid(CDSConnectionSetup."Business Unit Id") then
                CDSConnectionSetup."Business Unit Name" := DefaultBusinessUnitName
            else
                CDSConnectionSetup."Business Unit Name" := TempCRMBusinessUnit.Name;
            ModifyBusinessUnitCoupling(CDSConnectionSetup);
        end;
        exit(Changed);
    end;

    [TryFunction]
    local procedure GetFirstLevelBusinessUnits(var CDSConnectionSetup: Record "CDS Connection Setup"; var TempCRMBusinessunit: Record "CRM Businessunit" temporary)
    var
        CRMBusinessunit: Record "CRM Businessunit";
        TempConnectionName: Text;
        RootBusinessUnitId: Guid;
        EmptyGuid: Guid;
    begin
        CheckConnectionRequiredFields(CDSConnectionSetup, false);

        TempConnectionName := GetTempConnectionName();
        RegisterConnection(CDSConnectionSetup, TempConnectionName);
        SetDefaultTableConnection(TABLECONNECTIONTYPE::CRM, TempConnectionName, true);

        // Table connection is scoped, therefore all manipulations with CDS tables must be placed
        // in this procedure between SetDefaultTableConnection and UnregisterConnection

        CRMBusinessunit.SetRange(ParentBusinessUnitId, EmptyGuid);
        if CRMBusinessunit.FindFirst() then begin
            RootBusinessUnitId := CRMBusinessunit.BusinessUnitId;
            CRMBusinessunit.SetRange(ParentBusinessUnitId, RootBusinessUnitId);
            CRMBusinessunit.SetRange(IsDisabled, false);
            if CRMBusinessunit.FindSet() then
                repeat
                    TempCRMBusinessunit.Init();
                    TempCRMBusinessUnit.BusinessUnitId := CRMBusinessunit.BusinessUnitId;
                    TempCRMBusinessUnit.Name := CRMBusinessUnit.Name;
                    TempCRMBusinessunit.Insert();
                until CRMBusinessunit.Next() = 0;
            if TempCRMBusinessunit.FindFirst() then;
        end;

        UnregisterTableConnection(TABLECONNECTIONTYPE::CRM, TempConnectionName);
    end;

    [Scope('OnPrem')]
    procedure CheckConnectionRequiredFields(var CDSConnectionSetup: Record "CDS Connection Setup"; Silent: Boolean): Boolean
    var
        Success: Boolean;
    begin
        Success := true;
        if CDSConnectionSetup."Server Address" = '' then
            Success := false;
        if CDSConnectionSetup."User Name" = '' then
            Success := false;
        if not CDSConnectionSetup.HasPassword() then
            Success := false;
        if not Success then begin
            SendTraceTag('0000ATQ', CategoryTok, VERBOSITY::Normal, ConnectionRequiredFieldsTxt, DataClassification::SystemMetadata);
            if not Silent then
                Error(ConnectionRequiredFieldsErr);
        end;
        exit(Success);
    end;

    [Scope('OnPrem')]
    procedure CheckConnectionRequiredFieldsMatch(var CDSConnectionSetup: Record "CDS Connection Setup"; Silent: Boolean): Boolean
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        Success: Boolean;
    begin
        Success := true;

        if not CRMConnectionSetup.Get() then
            exit(true);

        if not CRMConnectionSetup."Is Enabled" then
            exit(true);

        if CDSConnectionSetup."Server Address" <> CRMConnectionSetup."Server Address" then
            Success := false;
        if CDSConnectionSetup."User Name" <> CRMConnectionSetup."User Name" then
            Success := false;
        if CDSConnectionSetup."User Password Key" <> CRMConnectionSetup."User Password Key" then
            Success := false;
        if CDSConnectionSetup."Authentication Type" <> CRMConnectionSetup."Authentication Type" then
            Success := false;
        if not Success then begin
            SendTraceTag('0000BCM', CategoryTok, VERBOSITY::Normal, ConnectionRequiredFieldsMismatchTxt, DataClassification::SystemMetadata);
            if not Silent then
                Error(ConnectionRequiredFieldsMismatchErr);
        end;
        exit(Success);
    end;

    local procedure FilterUser(var CDSConnectionSetup: Record "CDS Connection Setup"; var CRMSystemuser: Record "CRM Systemuser")
    begin
        case CDSConnectionSetup."Authentication Type" of
            CDSConnectionSetup."Authentication Type"::Office365, CDSConnectionSetup."Authentication Type"::OAuth:
                CRMSystemuser.SetFilter(InternalEMailAddress, StrSubstNo('@%1', CDSConnectionSetup."User Name"));
            CDSConnectionSetup."Authentication Type"::AD, CDSConnectionSetup."Authentication Type"::IFD:
                CRMSystemuser.SetFilter(DomainName, StrSubstNo('@%1', CDSConnectionSetup."User Name"));
        end;
    end;

    local procedure FilterTeam(BusinessUnitId: Guid; TeamName: Text; var CRMTeam: Record "CRM Team")
    begin
        CRMTeam.SetRange(Name, TeamName);
        CRMTeam.SetRange(BusinessUnitId, BusinessUnitId);
        CRMTeam.SetRange(IsDefault, false);
    end;

    local procedure GetUserName(var CDSConnectionSetup: Record "CDS Connection Setup") UserName: Text
    begin
        if CDSConnectionSetup."User Name" = '' then
            UserName := MissingUsernameTok
        else
            UserName := CopyStr(CDSConnectionSetup."User Name", StrPos(CDSConnectionSetup."User Name", '\') + 1);
    end;

    [Scope('OnPrem')]
    procedure RegisterAssistedSetup()
    var
        AssistedSetup: Codeunit "Assisted Setup";
        Info: ModuleInfo;
        AssistedSetupGroup: Enum "Assisted Setup Group";
    begin
        NavApp.GetCurrentModuleInfo(Info);
        if not AssistedSetup.Exists(PAGE::"CDS Connection Setup Wizard") then
            AssistedSetup.Add(Info.Id(), PAGE::"CDS Connection Setup Wizard", SetupConnectionTxt, AssistedSetupGroup::Customize);
    end;

    [Scope('OnPrem')]
    procedure GetConnectionStringWithPassword(var CDSConnectionSetup: Record "CDS Connection Setup"): Text
    var
        ConnectionStringWithPassword: Text;
        PasswordPlaceHolderPos: Integer;
    begin
        if CDSConnectionSetup."Connection String" = '' then
            exit('');
        if CDSConnectionSetup."User Name" = '' then
            exit(CDSConnectionSetup."Connection String");
        PasswordPlaceHolderPos := StrPos(CDSConnectionSetup."Connection String", MissingPasswordTok);
        ConnectionStringWithPassword :=
          CopyStr(CDSConnectionSetup."Connection String", 1, PasswordPlaceHolderPos - 1) + CDSConnectionSetup.GetPassword() +
          CopyStr(CDSConnectionSetup."Connection String", PasswordPlaceHolderPos + StrLen(MissingPasswordTok));

        exit(ConnectionStringWithPassword);
    end;

    [Scope('OnPrem')]
    procedure UpdateConnectionString(var CDSConnectionSetup: Record "CDS Connection Setup")
    var
        ConnectionString: Text;
    begin
        ConnectionString :=
          StrSubstNo(
            ConnectionStringFormatTok, CDSConnectionSetup."Server Address", GetUserName(CDSConnectionSetup), MissingPasswordTok, CDSConnectionSetup."Proxy Version", GetAuthenticationTypeToken(CDSConnectionSetup));
        SetConnectionString(CDSConnectionSetup, ConnectionString);
    end;

    [Scope('OnPrem')]
    procedure GetConnectionString(var CDSConnectionSetup: Record "CDS Connection Setup") ConnectionString: Text
    begin
        ConnectionString := CDSConnectionSetup."Connection String";
    end;

    [Scope('OnPrem')]
    procedure SetConnectionString(var CDSConnectionSetup: Record "CDS Connection Setup"; ConnectionString: Text)
    begin
        if ConnectionString = '' then
            Clear(CDSConnectionSetup."Connection String")
        else begin
            if StrPos(ConnectionString, MissingPasswordTok) = 0 then
                Error(ConnectionStringPwdPlaceHolderMissingErr);
            CDSConnectionSetup."Connection String" := CopyStr(ConnectionString, 1, MaxStrLen(CDSConnectionSetup."Connection String"));
        end;
        if not CDSConnectionSetup.Modify() then;
    end;

    [Scope('OnPrem')]
    [TryFunction]
    procedure TryGetCDSCompany(var CDSCompany: Record "CDS Company")
    begin
        GetCDSCompany(CDSCompany);
    end;

    [Scope('OnPrem')]
    procedure GetCDSCompany(var CDSCompany: Record "CDS Company")
    begin
        CDSCompany.SetRange(ExternalId, GetCompanyExternalId());
        CDSCompany.FindFirst();
    end;

    [Scope('OnPrem')]
    procedure GetCoupledBusinessUnitId(): Guid
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        EmptyGuid: Guid;
    begin
        if CDSConnectionSetup.Get() then
            exit(CDSConnectionSetup."Business Unit Id");
        exit(EmptyGuid);
    end;

    [Scope('OnPrem')]
    procedure GetIntegrationUserId(var CDSConnectionSetup: Record "CDS Connection Setup") IntegrationUserId: Guid
    var
        CRMSystemuser: Record "CRM Systemuser";
    begin
        CheckConnectionRequiredFields(CDSConnectionSetup, false);
        FilterUser(CDSConnectionSetup, CRMSystemuser);
        if CRMSystemuser.FindFirst() then
            IntegrationUserID := CRMSystemuser.SystemUserId;
        if IsNullGuid(IntegrationUserID) then
            ShowError(UserSetupTxt, CannotResolveUserFromConnectionSetupErr);
    end;

    [Scope('OnPrem')]
    procedure GetOwningTeamId(var CDSConnectionSetup: Record "CDS Connection Setup"): Guid
    var
        CRMBusinessUnit: Record "CRM Businessunit";
        CRMTeam: Record "CRM team";
        BusinessUnitId: Guid;
        TeamName: Text;
    begin
        CheckConnectionRequiredFields(CDSConnectionSetup, false);
        BusinessUnitId := CDSConnectionSetup."Business Unit Id";
        if not IsNullGuid(BusinessUnitId) then
            if CRMBusinessUnit.Get(BusinessUnitId) then begin
                TeamName := GetOwningTeamName(CRMBusinessUnit.Name);
                FilterTeam(BusinessUnitId, TeamName, CRMTeam);
                if CRMTeam.FindFirst() then
                    exit(CRMTeam.TeamId);
            end;
    end;

    local procedure AssignUserRole(var CrmHelper: DotNet CrmHelper; UserId: Guid; RoleId: Guid): Boolean
    begin
        if CrmHelper.CheckRoleAssignedToUser(UserId, RoleId) then
            exit(true);

        if not TryAssignUserRole(CrmHelper, UserId, RoleId) then begin
            SendTraceTag('0000ATR', CategoryTok, VERBOSITY::Warning, CannotAssignRoleToUserTxt, DataClassification::SystemMetadata);
            exit(false);
        end;

        if CrmHelper.CheckRoleAssignedToUser(UserId, RoleId) then
            exit(true);

        SendTraceTag('0000ATS', CategoryTok, VERBOSITY::Warning, CannotAssignRoleToUserTxt, DataClassification::SystemMetadata);
        exit(false);
    end;

    [TryFunction]
    local procedure TryAssignUserRole(var CrmHelper: DotNet CrmHelper; UserId: Guid; RoleId: Guid)
    begin
        CrmHelper.AssociateUserWithRole(UserId, RoleId);
    end;

    [TryFunction]
    local procedure TryGetUserId(var CrmHelper: DotNet CrmHelper; UserName: Text; var UserId: Guid)
    begin
        UserId := CrmHelper.GetUserId(UserName);
    end;

    [Scope('OnPrem')]
    procedure AssignIntegrationRole(var CrmHelper: DotNet CrmHelper; UserName: Text)
    var
        UserId: Guid;
        RoleId: Guid;
    begin
        if not TryGetUserId(CrmHelper, UserName, UserId) then begin
            SendTraceTag('0000ATT', CategoryTok, VERBOSITY::Normal, UserNotFoundTxt, DataClassification::SystemMetadata);
            Error(UserDoesNotExistErr, UserName);
        end;
        if IsNullGuid(UserId) then begin
            SendTraceTag('0000ATU', CategoryTok, VERBOSITY::Normal, UserNotFoundTxt, DataClassification::SystemMetadata);
            Error(UserDoesNotExistErr, UserName);
        end;
        RoleId := GetIntegrationRoleId();
        if not AssignUserRole(CrmHelper, UserId, RoleId) then begin
            SendTraceTag('0000ATV', CategoryTok, VERBOSITY::Normal, CannotAssignRoleToUserTxt, DataClassification::SystemMetadata);
            Error(CannotAssignRoleToIntegrationUserErr);
        end;
        SendTraceTag('0000ATW', CategoryTok, VERBOSITY::Normal, RoleAssignedToUserTxt, DataClassification::SystemMetadata);
    end;

    procedure AssignTeamRole(var CrmHelper: DotNet CrmHelper; TeamId: Guid; RoleId: Guid): Boolean
    begin
        if CheckRoleAssignedToTeam(CrmHelper, TeamId, RoleId) then
            exit(true);

        if not TryAssignTeamRole(CrmHelper, TeamId, RoleId) then begin
            SendTraceTag('0000ATX', CategoryTok, VERBOSITY::Normal, CannotAssignRoleToTeamTxt, DataClassification::SystemMetadata);
            exit(false);
        end;

        if CheckRoleAssignedToTeam(CrmHelper, TeamId, RoleId) then
            exit(true);

        SendTraceTag('0000ATY', CategoryTok, VERBOSITY::Normal, CannotAssignRoleToTeamTxt, DataClassification::SystemMetadata);
        exit(false);
    end;

    [TryFunction]
    local procedure TryAssignTeamRole(var CrmHelper: DotNet CrmHelper; TeamId: Guid; RoleId: Guid)
    begin
        CrmHelper.AssociateTeamWithRole(TeamId, RoleId);
    end;

    local procedure CheckRoleAssignedToTeam(var CrmHelper: DotNet CrmHelper; TeamId: Guid; RoleId: Guid): Boolean
    begin
        exit(CrmHelper.CheckRoleAssignedToTeam(TeamId, RoleId));
    end;

    [Scope('OnPrem')]
    procedure ImportAndConfigureIntegrationSolution(var CDSConnectionSetup: Record "CDS Connection Setup"; RenewSolution: Boolean): Boolean
    var
        CrmHelper: DotNet CrmHelper;
        AdminUser: Text;
        AdminPassword: Text;
        IntegrationUserChecked: Boolean;
    begin
        SendTraceTag('0000ATZ', CategoryTok, VERBOSITY::Normal, ConfigureSolutionTxt, DataClassification::SystemMetadata);
        CheckCredentials(CDSConnectionSetup);
        if not RenewSolution then
            if CheckIntegrationRequirements(CDSConnectionSetup, true) then begin
                SendTraceTag('0000AU0', CategoryTok, VERBOSITY::Normal, IntegrationRequirementsMetTxt, DataClassification::SystemMetadata);
                exit(false);
            end;
        IntegrationUserChecked := TryCheckIntegrationUserPrerequisites(CDSConnectionSetup);
        SignInCDSAdminUser(CDSConnectionSetup, CrmHelper, AdminUser, AdminPassword);
        if not IntegrationUserChecked then
            CheckIntegrationUserPrerequisites(CDSConnectionSetup, AdminUser, AdminPassword);
        ImportIntegrationSolution(CDSConnectionSetup, CrmHelper, AdminUser, AdminPassword, false);
        ConfigureIntegrationSolution(CDSConnectionSetup, CrmHelper, AdminUser, AdminPassword, false);
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure SignInCDSAdminUser(var CDSConnectionSetup: Record "CDS Connection Setup"; var CrmHelper: DotNet CrmHelper; var AdminUser: Text; var AdminPassword: Text)
    var
        TempConnectionString: Text;
    begin
        if not PromptForAdminCredentials(CDSConnectionSetup, AdminUser, AdminPassword) then begin
            SendTraceTag('0000AU1', CategoryTok, VERBOSITY::Normal, InvalidAdminCredentialsTxt, DataClassification::SystemMetadata);
            Error(AdminUserPasswordWrongErr);
        end;

        TempConnectionString := StrSubstNo(ConnectionStringFormatTok, CDSConnectionSetup."Server Address", AdminUser, AdminPassword, CDSConnectionSetup."Proxy Version", 'AuthType=Office365;');

        if not InitializeConnection(CrmHelper, TempConnectionString) then begin
            SendTraceTag('0000AU2', CategoryTok, VERBOSITY::Normal, ConnectionNotRegisteredTxt, DataClassification::SystemMetadata);
            ProcessConnectionFailures();
        end;
        if not CheckCredentials(CrmHelper) then begin
            SendTraceTag('0000AU3', CategoryTok, VERBOSITY::Normal, InvalidAdminCredentialsTxt, DataClassification::SystemMetadata);
            ProcessConnectionFailures();
        end;
    end;

    [Scope('OnPrem')]
    procedure ImportIntegrationSolution(var CDSConnectionSetup: Record "CDS Connection Setup"; var CrmHelper: DotNet CrmHelper; var AdminUser: Text; var AdminPassword: Text; RenewSolution: Boolean)
    var
        TempAdminCDSConnectionSetup: Record "CDS Connection Setup" temporary;
        ImportSolution: Boolean;
    begin
        GetTempAdminConnectionSetup(TempAdminCDSConnectionSetup, CDSConnectionSetup, AdminUser, AdminPassword);
        if RenewSolution then
            ImportSolution := true
        else
            ImportSolution := not IsSolutionInstalled(TempAdminCDSConnectionSetup);
        if ImportSolution then begin
            SendTraceTag('0000AU4', CategoryTok, VERBOSITY::Normal, SolutionNotInstalledTxt, DataClassification::SystemMetadata);
            CrmHelper.ImportDefaultCdsSolution();
        end;
    end;

    [Scope('OnPrem')]
    procedure ConfigureIntegrationSolution(var CDSConnectionSetup: Record "CDS Connection Setup"; var CrmHelper: DotNet CrmHelper; var AdminUser: Text; var AdminPassword: Text; IsSilent: Boolean)
    begin
        AssignIntegrationRole(CrmHelper, CDSConnectionSetup."User Name");
        SetUserAsIntegrationUser(CDSConnectionSetup, AdminUser, AdminPassword);
        if SetAccessModeToNonInteractive(CDSConnectionSetup, AdminUser, AdminPassword) then
            if not IsSilent then
                Message(AccessModeSetToNonInteractiveMsg);
        SyncCompany(CDSConnectionSetup, AdminUser, AdminPassword);

        SendTraceTag('0000AU5', CategoryTok, VERBOSITY::Normal, SolutionConfiguredTxt, DataClassification::SystemMetadata);
    end;

    [Scope('OnPrem')]
    procedure CheckCompanyId(var RecRef: RecordRef): Boolean
    begin
        exit(TrySetAndCheckCompany(RecRef, true));
    end;

    [Scope('OnPrem')]
    procedure SetCompanyId(var RecRef: RecordRef): Boolean
    begin
        exit(TrySetAndCheckCompany(RecRef, false));
    end;

    [TryFunction]
    local procedure TrySetAndCheckCompany(var RecRef: RecordRef; CheckOnly: Boolean)
    var
        CompanyIdFldRef: FieldRef;
        ActualCompanyId: Guid;
        SavedCompanyId: Guid;
        IsCorrectCompany: Boolean;
    begin
        if CheckOnly then
            SendTraceTag('0000AVL', CategoryTok, VERBOSITY::Normal, CheckCompanyIdTxt, DataClassification::SystemMetadata)
        else
            SendTraceTag('0000AVM', CategoryTok, VERBOSITY::Normal, SetCompanyIdTxt, DataClassification::SystemMetadata);

        if not FindCompanyIdField(RecRef, CompanyIdFldRef) then begin
            SendTraceTag('0000AVN', CategoryTok, VERBOSITY::Normal, EntityHasNoCompanyIdFieldTxt, DataClassification::SystemMetadata);
            Error(CannotFindCompanyIdFieldErr, RecRef.Number(), RecRef.Name());
        end;

        ActualCompanyId := GetCachedCompanyId();
        SavedCompanyId := CompanyIdFldRef.Value();
        IsCorrectCompany := SavedCompanyId = ActualCompanyId;

        if CheckOnly then begin
            if not IsCorrectCompany then begin
                SendTraceTag('0000AVO', CategoryTok, VERBOSITY::Normal, CompanyIdDiffersFromExpectedTxt, DataClassification::SystemMetadata);
                Error(OwnerDiffersFromExpectedErr);
            end;
            SendTraceTag('0000AVP', CategoryTok, VERBOSITY::Normal, CompanyIdCheckedTxt, DataClassification::SystemMetadata);
            exit;
        end;

        if not IsCorrectCompany then
            CompanyIdFldRef.Value := ActualCompanyId;

        SendTraceTag('0000AVT', CategoryTok, VERBOSITY::Normal, CompanyIdSetTxt, DataClassification::SystemMetadata);
    end;

    [Scope('OnPrem')]
    procedure CheckOwningTeam(var RecRef: RecordRef): Boolean
    begin
        exit(CheckOwningTeam(RecRef, false));
    end;

    [Scope('OnPrem')]
    procedure CheckOwningTeam(var RecRef: RecordRef; SkipBusinessUnitCheck: Boolean): Boolean
    var
        EmptyGuid: Guid;
    begin
        exit(CheckOwningTeam(RecRef, EmptyGuid, SkipBusinessUnitCheck));
    end;

    [Scope('OnPrem')]
    procedure CheckOwningTeam(var RecRef: RecordRef; TeamId: Guid; SkipBusinessUnitCheck: Boolean): Boolean
    var
        TempCDSCompany: Record "CDS Company" temporary;
    begin
        exit(SetAndCheckOwner(RecRef, TempCDSCompany.OwnerIdType::team, TeamId, true, SkipBusinessUnitCheck));
    end;

    [Scope('OnPrem')]
    procedure CheckOwningUser(var RecRef: RecordRef; UserId: Guid): Boolean
    begin
        exit(CheckOwningUser(RecRef, UserId, false));
    end;

    [Scope('OnPrem')]
    procedure CheckOwningUser(var RecRef: RecordRef; UserId: Guid; SkipBusinessUnitCheck: Boolean): Boolean
    var
        TempCDSCompany: Record "CDS Company" temporary;
    begin
        exit(SetAndCheckOwner(RecRef, TempCDSCompany.OwnerIdType::systemuser, UserId, true, SkipBusinessUnitCheck));
    end;

    [Scope('OnPrem')]
    procedure SetOwningTeam(var RecRef: RecordRef): Boolean
    var
        EmptyGuid: Guid;
    begin
        exit(SetOwningTeam(RecRef, EmptyGuid, false));
    end;

    [Scope('OnPrem')]
    procedure SetOwningTeam(var RecRef: RecordRef; TeamId: Guid; SkipBusinessUnitCheck: Boolean): Boolean
    var
        TempCDSCompany: Record "CDS Company" temporary;
    begin
        exit(SetAndCheckOwner(RecRef, TempCDSCompany.OwnerIdType::team, TeamId, false, SkipBusinessUnitCheck));
    end;

    [Scope('OnPrem')]
    procedure SetOwningUser(var RecRef: RecordRef; UserId: Guid; SkipBusinessUnitCheck: Boolean): Boolean
    var
        TempCDSCompany: Record "CDS Company" temporary;
    begin
        exit(SetAndCheckOwner(RecRef, TempCDSCompany.OwnerIdType::systemuser, UserId, false, SkipBusinessUnitCheck));
    end;

    local procedure SetAndCheckOwner(var RecRef: RecordRef; OwnerIdType: Option; OwnerId: Guid; CheckOnly: Boolean; SkipBusinessUnitCheck: Boolean): Boolean
    begin
        exit(TrySetAndCheckOwner(RecRef, OwnerIdType, OwnerId, CheckOnly, SkipBusinessUnitCheck));
    end;

    [TryFunction]
    local procedure TrySetAndCheckOwner(var RecRef: RecordRef; OwnerIdType: Option; OwnerId: Guid; CheckOnly: Boolean; SkipBusinessUnitCheck: Boolean)
    var
        TempCDSCompany: Record "CDS Company" temporary;
        OwnerIdTypeFldRef: FieldRef;
        OwnerIdFldRef: FieldRef;
        SavedOwnerIdType: Option;
        SavedOwnerId: Guid;
        IsCorrectOwner: Boolean;
    begin
        if CheckOnly then
            SendTraceTag('0000AU6', CategoryTok, VERBOSITY::Normal, CheckOwnerTxt, DataClassification::SystemMetadata)
        else
            SendTraceTag('0000AU7', CategoryTok, VERBOSITY::Normal, SetOwnerTxt, DataClassification::SystemMetadata);

        if IsNullGuid(OwnerId) and (OwnerIdType = TempCDSCompany.OwnerIdType::team) then begin
            SendTraceTag('0000AU8', CategoryTok, VERBOSITY::Normal, SetDefaultOwningTeamTxt, DataClassification::SystemMetadata);
            OwnerId := GetCachedDefaultOwningTeamId();
        end;

        if not FindOwnerIdField(RecRef, OwnerIdFldRef) then begin
            SendTraceTag('0000AU9', CategoryTok, VERBOSITY::Warning, EntityHasNoOwnerIdFieldTxt, DataClassification::SystemMetadata);
            Error(CannotFindOwnerIdFieldErr, RecRef.Number(), RecRef.Name());
        end;

        if not FindOwnerTypeField(RecRef, OwnerIdTypeFldRef) then begin
            SendTraceTag('0000B2L', CategoryTok, VERBOSITY::Warning, EntityHasNoOwnerTypeFieldTxt, DataClassification::SystemMetadata);
            Error(CannotFindOwnerTypeFieldErr, RecRef.Number(), RecRef.Name());
        end;

        SavedOwnerIdType := OwnerIdTypeFldRef.Value();
        SavedOwnerId := OwnerIdFldRef.Value();
        IsCorrectOwner := (SavedOwnerIdType = OwnerIdType) and (SavedOwnerId = OwnerId);

        if CheckOnly then
            if not IsCorrectOwner then begin
                SendTraceTag('0000AUA', CategoryTok, VERBOSITY::Warning, OwnerDiffersFromExpectedTxt, DataClassification::SystemMetadata);
                Error(OwnerDiffersFromExpectedErr);
            end;

        case OwnerIdType of
            TempCDSCompany.OwnerIdType::team:
                CheckOwningTeam(OwnerId, SkipBusinessUnitCheck);
            TempCDSCompany.OwnerIdType::systemuser:
                CheckOwningUser(OwnerId, SkipBusinessUnitCheck);
            else begin
                    SendTraceTag('0000AUC', CategoryTok, VERBOSITY::Warning, UnsupportedOwnerTypeTxt, DataClassification::SystemMetadata);
                    Error(OwnerIdTypeErr);
                end;
        end;

        if CheckOnly then begin
            SendTraceTag('0000AUB', CategoryTok, VERBOSITY::Normal, OwnerCheckedTxt, DataClassification::SystemMetadata);
            exit;
        end;

        if not IsCorrectOwner then begin
            OwnerIdTypeFldRef.Value := OwnerIdType;
            OwnerIdFldRef.Value := OwnerId;
        end;

        SendTraceTag('0000AUG', CategoryTok, VERBOSITY::Normal, OwnerSetTxt, DataClassification::SystemMetadata);
    end;

    local procedure CheckOwningTeam(TeamId: Guid; SkipBusinessUnitCheck: Boolean)
    var
        OwningCRMTeam: Record "CRM Team";
    begin
        if TeamId = GetCachedDefaultOwningTeamId() then
            exit;
        if GetCachedOwningTeamCheck(TeamId, SkipBusinessUnitCheck) then
            exit;
        if not OwningCRMTeam.Get(TeamId) then begin
            SendTraceTag('0000AUH', CategoryTok, VERBOSITY::Warning, TeamNotFoundTxt, DataClassification::SystemMetadata);
            Error(TeamNotFoundErr, TeamId);
        end;
        CheckTeamHasIntegrationRole(OwningCRMTeam);
        if not SkipBusinessUnitCheck then
            If OwningCRMTeam.BusinessUnitId <> GetCachedOwningBusinessUnitId() then begin
                SendTraceTag('0000AUI', CategoryTok, VERBOSITY::Warning, TeamBusinessUnitDiffersFromSelectedTxt, DataClassification::SystemMetadata);
                Error(TeamBusinessUnitDiffersFromSelectedErr);
            end;
        SetCachedOwningTeamCheck(TeamId, SkipBusinessUnitCheck);
    end;

    local procedure CheckOwningUser(UserId: Guid; SkipBusinessUnitCheck: Boolean)
    var
        CRMSystemuser: Record "CRM Systemuser";
    begin
        if GetCachedOwningUserCheck(UserId, SkipBusinessUnitCheck) then
            exit;
        if not CRMSystemuser.Get(UserId) then begin
            SendTraceTag('0000AUJ', CategoryTok, VERBOSITY::Warning, UserNotFoundTxt, DataClassification::SystemMetadata);
            Error(UserNotFoundErr, UserId);
        end;
        if not SkipBusinessUnitCheck then
            If CRMSystemuser.BusinessUnitId <> GetCachedOwningBusinessUnitId() then begin
                SendTraceTag('0000AUL', CategoryTok, VERBOSITY::Warning, UserBusinessUnitDiffersFromSelectedTxt, DataClassification::SystemMetadata);
                Error(UserBusinessUnitDiffersFromSelectedErr);
            end;
        SetCachedOwningUserCheck(UserId, SkipBusinessUnitCheck);
    end;

    local procedure CheckTeamHasIntegrationRole(var CRMTeam: Record "CRM Team")
    var
        CRMRole: Record "CRM Role";
        CDSTeamroles: Record "CDS Teamroles";
    begin
        CRMRole.SetRange(BusinessUnitId, CRMTeam.BusinessUnitId);
        CRMRole.SetRange(ParentRoleId, GetIntegrationRoleId());
        if not CRMRole.FindFirst() then begin
            SendTraceTag('0000AUM', CategoryTok, Verbosity::Normal, RoleNotFoundForBusinessUnitTxt, DataClassification::SystemMetadata);
            Error(IntegrationRoleNotFoundErr, GetIntegrationRoleName(), GetBusinessUnitName(CRMTeam.BusinessUnitId));
        end;
        CDSTeamroles.SetRange(TeamId, CRMTeam.TeamId);
        CDSTeamroles.SetRange(RoleId, CRMRole.RoleId);
        if CDSTeamroles.IsEmpty() then begin
            SendTraceTag('0000AUN', CategoryTok, Verbosity::Normal, IntegrationRoleNotAssignedToTeamTxt, DataClassification::SystemMetadata);
            Error(TeamRolesErr, CRMTeam.Name, GetBusinessUnitName(CRMTeam.BusinessUnitId), GetIntegrationRoleName());
        end;
    end;

    local procedure GetBusinessUnitName(BusinesUnitId: Guid) BusinessunitName: Text
    var
        CRMBusinessUnit: Record "CRM Businessunit";
    begin
        if CRMBusinessunit.Get(BusinesUnitId) then
            BusinessunitName := CRMBusinessunit.Name
        else
            BusinessunitName := Format(BusinesUnitId);
    end;

    local procedure GetIntegrationRoleName() IntegrationRoleName: Text
    var
        CRMRole: Record "CRM Role";
    begin
        if CRMRole.Get(GetIntegrationRoleId()) then
            IntegrationRoleName := CRMRole.Name
        else
            IntegrationRoleName := Format(GetIntegrationRoleId());
    end;

    local procedure FindCompanyIdField(var RecRef: RecordRef; var CompanyIdFldRef: FieldRef): Boolean
    var
        Field: Record "Field";
        TableNo: Integer;
        FieldNo: Integer;
    begin
        TableNo := RecRef.Number();
        if CachedCompanyIdFieldNo.ContainsKey(TableNo) then
            FieldNo := CachedCompanyIdFieldNo.Get(TableNo)
        else begin
            Field.SetRange(TableNo, TableNo);
            Field.SetRange(Type, Field.Type::GUID);
            Field.SetRange(FieldName, 'CompanyId');
            if Field.FindFirst() then
                FieldNo := Field."No."
            else
                FieldNo := 0;
            CachedCompanyIdFieldNo.Add(TableNo, FieldNo);
        end;
        if FieldNo = 0 then
            exit(false);
        CompanyIdFldRef := RecRef.Field(FieldNo);
        exit(true);
    end;

    local procedure FindOwnerIdField(var RecRef: RecordRef; var OwnerIdFldRef: FieldRef): Boolean
    var
        Field: Record "Field";
        TableNo: Integer;
        FieldNo: Integer;
    begin
        TableNo := RecRef.Number();
        if CachedOwnerIdFieldNo.ContainsKey(TableNo) then
            FieldNo := CachedOwnerIdFieldNo.Get(TableNo)
        else begin
            Field.SetRange(TableNo, TableNo);
            Field.SetRange(Type, Field.Type::GUID);
            Field.SetRange(FieldName, 'OwnerId');
            if Field.FindFirst() then
                FieldNo := Field."No."
            else
                FieldNo := 0;
            CachedOwnerIdFieldNo.Add(TableNo, FieldNo);
        end;
        if FieldNo = 0 then
            exit(false);
        OwnerIdFldRef := RecRef.Field(FieldNo);
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure FindOwnerTypeField(var RecRef: RecordRef; var OwnerIdTypeFldRef: FieldRef): Boolean
    var
        Field: Record "Field";
        TableNo: Integer;
        FieldNo: Integer;
    begin
        TableNo := RecRef.Number();

        if CachedOwnerTypeFieldNo.ContainsKey(TableNo) then
            FieldNo := CachedOwnerTypeFieldNo.Get(TableNo)
        else begin
            Field.SetRange(TableNo, TableNo);
            Field.SetRange(Type, Field.Type::Option);
            Field.SetRange(FieldName, 'OwnerIdType');
            Field.SetRange(OptionString, ' ,systemuser,team');
            if Field.FindFirst() then
                FieldNo := Field."No."
            else
                FieldNo := 0;
            CachedOwnerTypeFieldNo.Add(TableNo, FieldNo);
        end;
        if FieldNo = 0 then
            exit(false);
        OwnerIdTypeFldRef := RecRef.Field(FieldNo);
        exit(true);
    end;

    local procedure GetCachedOwningTeamCheck(TeamId: Guid; SkipBusinessUnitCheck: Boolean): Boolean
    begin
        if SkipBusinessUnitCheck then begin
            if CachedOwningTeamCheckWithoutBusinessUnit.ContainsKey(TeamId) then
                exit(true);
        end else
            if CachedOwningTeamCheckWithBusinessUnit.ContainsKey(TeamId) then
                exit(true);
        exit(false);
    end;

    local procedure SetCachedOwningTeamCheck(TeamId: Guid; SkipBusinessUnitCheck: Boolean)
    begin
        SendTraceTag('0000B2M', CategoryTok, VERBOSITY::Normal, StrSubstNo(SetCachedOwningTeamCheckTxt, TeamId, SkipBusinessUnitCheck), DataClassification::SystemMetadata);
        if SkipBusinessUnitCheck then begin
            if not CachedOwningTeamCheckWithoutBusinessUnit.ContainsKey(TeamId) then
                CachedOwningTeamCheckWithoutBusinessUnit.Add(TeamId, true);
        end else
            if not CachedOwningTeamCheckWithBusinessUnit.ContainsKey(TeamId) then
                CachedOwningTeamCheckWithBusinessUnit.Add(TeamId, true);
    end;

    local procedure GetCachedOwningUserCheck(UserId: Guid; SkipBusinessUnitCheck: Boolean): Boolean
    begin
        if SkipBusinessUnitCheck then begin
            if CachedOwningUserCheckWithoutBusinessUnit.ContainsKey(UserId) then
                exit(true);
        end else
            if CachedOwningUserCheckWithBusinessUnit.ContainsKey(UserId) then
                exit(true);
        exit(false);
    end;

    local procedure SetCachedOwningUserCheck(UserId: Guid; SkipBusinessUnitCheck: Boolean)
    begin
        SendTraceTag('0000B2N', CategoryTok, VERBOSITY::Normal, StrSubstNo(SetCachedOwningUserCheckTxt, UserId, SkipBusinessUnitCheck), DataClassification::SystemMetadata);
        if SkipBusinessUnitCheck then begin
            if not CachedOwningUserCheckWithoutBusinessUnit.ContainsKey(UserId) then
                CachedOwningUserCheckWithoutBusinessUnit.Add(UserId, true);
        end else
            if not CachedOwningUserCheckWithBusinessUnit.ContainsKey(UserId) then
                CachedOwningUserCheckWithBusinessUnit.Add(UserId, true);
    end;

    local procedure GetCachedCompanyId(): Guid
    begin
        InitializeCompanyCache();
        exit(CachedCompanyId);
    end;

    local procedure GetCachedDefaultOwningTeamId(): Guid
    begin
        InitializeCompanyCache();
        exit(CachedDefaultOwningTeamId);
    end;

    local procedure GetCachedOwningBusinessUnitId(): Guid
    begin
        InitializeCompanyCache();
        exit(CachedOwningBusinessUnitId);
    end;

    local procedure InitializeCompanyCache()
    var
        CDSCompany: Record "CDS Company";
        CRMTeam: Record "CRM Team";
    begin
        if AreCompanyValuesCached then
            exit;

        SendTraceTag('0000B2O', CategoryTok, VERBOSITY::Normal, InitializeCompanyCacheTxt, DataClassification::SystemMetadata);

        if not TryGetCDSCompany(CDSCompany) then begin
            SendTraceTag('0000B2P', CategoryTok, VERBOSITY::Warning, CompanyNotFoundTxt, DataClassification::SystemMetadata);
            Error(CompanyNotFoundErr);
        end;

        if not CRMTeam.Get(CDSCompany.DefaultOwningTeam) then begin
            SendTraceTag('0000B2Q', CategoryTok, VERBOSITY::Warning, TeamNotFoundTxt, DataClassification::SystemMetadata);
            Error(TeamNotFoundErr);
        end;

        CachedCompanyId := CDSCompany.CompanyId;
        CachedDefaultOwningTeamId := CDSCompany.DefaultOwningTeam;
        CachedOwningBusinessUnitId := CRMTeam.BusinessUnitId;
        AreCompanyValuesCached := true;
    end;

    [Scope('OnPrem')]
    procedure ResetCache()
    begin
        SendTraceTag('0000B2R', CategoryTok, VERBOSITY::Normal, ClearCacheTxt, DataClassification::SystemMetadata);
        Clear(AreCompanyValuesCached);
        Clear(CachedCompanyId);
        Clear(CachedDefaultOwningTeamId);
        Clear(CachedOwningBusinessUnitId);
        Clear(CachedOwningTeamCheckWithoutBusinessUnit);
        Clear(CachedOwningTeamCheckWithBusinessUnit);
        Clear(CachedOwningUserCheckWithoutBusinessUnit);
        Clear(CachedOwningUserCheckWithBusinessUnit);
    end;

    [Scope('OnPrem')]
    procedure GetIntegrationSolutions(var SolutionUniqueNameList: List of [Text])
    begin
        CDSIntegrationMgt.OnGetIntegrationSolutions(SolutionUniqueNameList);
        SolutionUniqueNameList.Insert(1, GetBaseSolutionUniqueName())
    end;

    [Scope('OnPrem')]
    procedure GetIntegrationRequiredRoles(var RequiredRoleIdList: List of [Guid])
    begin
        CDSIntegrationMgt.OnGetIntegrationRequiredRoles(RequiredRoleIdList);
        RequiredRoleIdList.Insert(1, GetIntegrationRoleId());
    end;

    [Scope('OnPrem')]
    procedure CheckModifyConnectionURL(var ServerAddress: Text[250])
    var
        UriHelper: DotNet Uri;
        UriHelper2: DotNet Uri;
        UriKindHelper: DotNet UriKind;
        UriPartialHelper: DotNet UriPartial;
        ProposedUri: Text[250];
    begin
        if (ServerAddress = '') or (ServerAddress = TestServerAddressTok) then
            exit;

        ServerAddress := DelChr(ServerAddress, '<>');

        if not UriHelper.TryCreate(ServerAddress, UriKindHelper.Absolute, UriHelper2) then
            if not UriHelper.TryCreate('https://' + ServerAddress, UriKindHelper.Absolute, UriHelper2) then
                Error(InvalidUriErr);

        if UriHelper2.Scheme() <> 'https' then
            Error(MustUseHttpsErr);

        ProposedUri := UriHelper2.GetLeftPart(UriPartialHelper.Authority);

        // Test that a specific port number is given
        if ((UriHelper2.Port() = 443) or (UriHelper2.Port() = 80)) and (LowerCase(ServerAddress) <> LowerCase(ProposedUri)) then
            if Confirm(StrSubstNo(ReplaceServerAddressQst, ServerAddress, ProposedUri)) then
                ServerAddress := ProposedUri;
    end;

    [Scope('OnPrem')]
    procedure InitializeConnection(var CrmHelper: DotNet CrmHelper): Boolean
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        if not CDSConnectionSetup.Get() then begin
            SendTraceTag('0000AUO', CategoryTok, VERBOSITY::Normal, IntegrationNotConfiguredTxt, DataClassification::SystemMetadata);
            exit(false);
        end;
        exit(InitializeConnection(CrmHelper, CDSConnectionSetup));
    end;

    [Scope('OnPrem')]
    procedure InitializeConnection(var CrmHelper: DotNet CrmHelper;

    var
        CDSConnectionSetup: Record "CDS Connection Setup"): Boolean
    begin
        exit(InitializeConnection(CrmHelper, GetConnectionStringWithPassword(CDSConnectionSetup)));
    end;

    [TryFunction]
    local procedure InitializeConnection(var CrmHelper: DotNet CrmHelper; ConnectionString: Text)
    begin
        CrmHelper := CrmHelper.CrmHelper(ConnectionString);
    end;

    local procedure ProcessConnectionFailures()
    var
        DotNetExceptionHandler: Codeunit "DotNet Exception Handler";
        FaultException: DotNet FaultException;
        FileNotFoundException: DotNet FileNotFoundException;
        ArgumentNullException: DotNet ArgumentNullException;
        CrmHelper: DotNet CrmHelper;
    begin
        DotNetExceptionHandler.Collect();

        if DotNetExceptionHandler.TryCastToType(GetDotNetType(FaultException)) then begin
            SendTraceTag('0000AUP', CategoryTok, VERBOSITY::Normal, ConnectionFailureTxt, DataClassification::SystemMetadata);
            Error(GeneralFailureErr);
        end;
        if DotNetExceptionHandler.TryCastToType(GetDotNetType(FileNotFoundException)) then begin
            SendTraceTag('0000AUQ', CategoryTok, VERBOSITY::Normal, ConnectionFailureTxt, DataClassification::SystemMetadata);
            Error(SolutionFileNotFoundErr);
        end;
        if DotNetExceptionHandler.TryCastToType(CrmHelper.OrganizationServiceFaultExceptionType()) then begin
            SendTraceTag('0000AUR', CategoryTok, VERBOSITY::Normal, ConnectionFailureTxt, DataClassification::SystemMetadata);
            Error(OrganizationServiceFailureErr);
        end;
        if DotNetExceptionHandler.TryCastToType(CrmHelper.SystemNetWebException()) then begin
            SendTraceTag('0000AUS', CategoryTok, VERBOSITY::Normal, ConnectionFailureTxt, DataClassification::SystemMetadata);
            Error(CDSConnectionURLWrongErr);
        end;
        if DotNetExceptionHandler.CastToType(ArgumentNullException, GetDotNetType(ArgumentNullException)) then
            case ArgumentNullException.ParamName() of
                'cred':
                    begin
                        SendTraceTag('0000AUT', CategoryTok, VERBOSITY::Normal, ConnectionFailureTxt, DataClassification::SystemMetadata);
                        Error(AdminUserPasswordWrongErr);
                    end;
                'Organization Name':
                    begin
                        SendTraceTag('0000AUU', CategoryTok, VERBOSITY::Normal, ConnectionFailureTxt, DataClassification::SystemMetadata);
                        Error(CDSConnectionURLWrongErr);
                    end;
            end;
        DotNetExceptionHandler.Rethrow();
    end;

    local procedure GetSystemAdminRoleTemplateId(): Guid
    begin
        exit(TextToGuid(SystemAdminRoleTemplateIdTxt));
    end;

    local procedure GetSystemCustomizerRoleTemplateId(): Guid
    begin
        exit(TextToGuid(SystemCustomizerRoleTemplateIdTxt));
    end;

    local procedure GetIntegrationRoleId(): Guid
    begin
        exit(TextToGuid(IntegrationRoleIdTxt));
    end;

    local procedure GetErrorNotificationId(): Guid
    begin
        exit(TextToGuid(ErrorNotificationIdTxt));
    end;

    local procedure GetConnectionDisabledNotificationId(): Guid
    begin
        exit(TextToGuid(ConnectionDisabledNotificationIdTxt));
    end;

    local procedure TextToGuid(TextVar: Text): Guid
    var
        GuidVar: Guid;
    begin
        if not Evaluate(GuidVar, TextVar) then;
        exit(GuidVar);
    end;

    [Scope('OnPrem')]
    procedure SendConnectionDisabledNotification(DisableReason: Text[250])
    var
        Notification: Notification;
    begin
        Notification.Id := GetConnectionDisabledNotificationId();
        Notification.Message := StrSubstNo(ConnectionDisabledNotificationMsg, DisableReason);
        Notification.Scope := NOTIFICATIONSCOPE::LocalScope;
        Notification.Send();
    end;

    local procedure ShowError(ActivityDescription: Text[128]; ErrorMessage: Text)
    var
        MyNotifications: Record "My Notifications";
        SystemInitialization: Codeunit "System Initialization";
    begin
        if (not SystemInitialization.IsInProgress()) and (GetExecutionContext() = ExecutionContext::Normal) then
            Error(ErrorMessage);

        MyNotifications.InsertDefault(GetErrorNotificationId(), ActivityDescription, ErrorMessage, true);
    end;

    [Scope('OnPrem')]
    procedure InsertBusinessUnitCoupling(var CDSConnectionSetup: Record "CDS Connection Setup")
    var
        Company: Record Company;
        CDSCoupledBusinessUnit: Record "CDS Coupled Business Unit";
    begin
        if IsNullGuid(CDSConnectionSetup."Business Unit Id") then
            exit;

        if not Company.Get(CompanyName()) then
            exit;

        CDSCoupledBusinessUnit.Validate("Company Id", Company.SystemId);
        CDSCoupledBusinessUnit.Validate("Business Unit Id", CDSConnectionSetup."Business Unit Id");
        CDSCoupledBusinessUnit.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure ModifyBusinessUnitCoupling(var CDSConnectionSetup: Record "CDS Connection Setup")
    var
        Company: Record Company;
        CDSCoupledBusinessUnit: Record "CDS Coupled Business Unit";
    begin
        if not Company.Get(CompanyName()) then
            exit;

        CDSCoupledBusinessUnit.SetRange("Company Id", Company.SystemId);
        CDSCoupledBusinessUnit.DeleteAll(true);

        CDSCoupledBusinessUnit.Init();
        CDSCoupledBusinessUnit.Validate("Company Id", Company.SystemId);
        CDSCoupledBusinessUnit.Validate("Business Unit Id", CDSConnectionSetup."Business Unit Id");
        CDSCoupledBusinessUnit.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure DeleteBusinessUnitCoupling(var CDSConnectionSetup: Record "CDS Connection Setup")
    var
        Company: Record Company;
        CDSCoupledBusinessUnit: Record "CDS Coupled Business Unit";
    begin
        if not Company.Get(CompanyName()) then
            exit;

        CDSCoupledBusinessUnit.SetRange("Company Id", Company.SystemId);
        CDSCoupledBusinessUnit.SetRange("Business Unit Id", CDSConnectionSetup."Business Unit Id");
        CDSCoupledBusinessUnit.DeleteAll(true);
    end;

    [Scope('OnPrem')]
    procedure TestConnection(var CDSConnectionSetup: Record "CDS Connection Setup"): Boolean
    begin
        if TryTestConnection(CDSConnectionSetup) then
            exit(true);

        exit(TryCheckCredentials(CDSConnectionSetup));
    end;

    [TryFunction]
    local procedure TryTestConnection(var CDSConnectionSetup: Record "CDS Connection Setup")
    var
        CRMSystemuser: Record "CRM Systemuser";
        TempConnectionName: Text;
        Id: Guid;
    begin
        CheckConnectionRequiredFields(CDSConnectionSetup, false);

        TempConnectionName := GetTempConnectionName();
        RegisterConnection(CDSConnectionSetup, TempConnectionName);
        SetDefaultTableConnection(TABLECONNECTIONTYPE::CRM, TempConnectionName, true);

        if CRMSystemuser.FindFirst() then
            Id := CRMSystemuser.SystemUserId;

        UnregisterTableConnection(TABLECONNECTIONTYPE::CRM, TempConnectionName);
    end;

    [Scope('OnPrem')]
    [TryFunction]
    procedure TryCheckCredentials(var CDSConnectionSetup: Record "CDS Connection Setup")
    begin
        CheckCredentials(CDSConnectionSetup);
    end;

    [Scope('OnPrem')]
    procedure CheckCredentials(var CDSConnectionSetup: Record "CDS Connection Setup")
    var
        CrmHelper: DotNet CrmHelper;
    begin
        CheckConnectionRequiredFields(CDSConnectionSetup, false);
        if not InitializeConnection(CrmHelper, CDSConnectionSetup) then begin
            SendTraceTag('0000BO2', CategoryTok, VERBOSITY::Normal, ConnectionNotRegisteredTxt, DataClassification::SystemMetadata);
            ProcessConnectionFailures();
        end;
        if not CheckCredentials(CrmHelper) then begin
            SendTraceTag('0000BO3', CategoryTok, VERBOSITY::Normal, InvalidUserCredentialsTxt, DataClassification::SystemMetadata);
            Error(IntegrationUserPasswordWrongErr);
        end;
    end;

    [TryFunction]
    local procedure CheckCredentials(var CrmHelper: DotNet CrmHelper)
    begin
        CrmHelper.CheckCredentials();
    end;

    [Scope('OnPrem')]
    [TryFunction]
    procedure GetCDSVersion(var CDSConnectionSetup: Record "CDS Connection Setup"; var CDSVersion: Text)
    var
        CrmHelper: DotNet CrmHelper;
    begin
        if InitializeConnection(CrmHelper, CDSConnectionSetup) then
            CDSVersion := CrmHelper.GetConnectedCrmVersion()
    end;

    [Scope('OnPrem')]
    procedure InitializeProxyVersionList(var TempStack: Record TempStack temporary)
    var
        CrmHelper: DotNet CrmHelper;
        IList: DotNet GenericList1;
        i: Integer;
        ProxyCount: Integer;
    begin
        IList := CrmHelper.GetProxyIdList();
        ProxyCount := IList.Count();
        for i := 0 to ProxyCount - 1 do begin
            TempStack.StackOrder := IList.Item(i);
            TempStack.Insert();
        end;
    end;

    [Scope('OnPrem')]
    procedure GetLastProxyVersionItem(): Integer
    var
        TempStack: Record TempStack temporary;
    begin
        InitializeProxyVersionList(TempStack);
        TempStack.FindLast();
        exit(TempStack.StackOrder);
    end;

    [Scope('OnPrem')]
    procedure ClearConnectionDisableReason(var CDSConnectionSetup: Record "CDS Connection Setup")
    var
        Notification: Notification;
    begin
        if CDSConnectionSetup."Disable Reason" = '' then
            exit;
        SendTraceTag('0000AUV', CategoryTok, VERBOSITY::Normal, ClearDisabledReasonTxt, DataClassification::SystemMetadata);
        Notification.Id := GetConnectionDisabledNotificationId();
        Notification.Recall();
        Clear(CDSConnectionSetup."Disable Reason");
        CDSConnectionSetup.Modify();
    end;

    local procedure DisableConnection()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        LastError: Text;
    begin
        SendTraceTag('0000AUW', CategoryTok, VERBOSITY::Normal, DisableIntegrationTxt, DataClassification::SystemMetadata);

        LastError := GetLastErrorText();
        LastError := CopyStr(LastError, StrPos(Format(LastError), ':') + 1, StrLen(LastError));
        Message(StrSubstNo(ConnectionBrokenMsg, LastError));
        if not CDSConnectionSetup.Get() then begin
            SendTraceTag('0000AUX', CategoryTok, VERBOSITY::Normal, IntegrationNotConfiguredTxt, DataClassification::SystemMetadata);
            exit;
        end;
        CDSConnectionSetup.Validate("Is Enabled", false);
        CDSConnectionSetup.Validate(
          "Disable Reason",
          CopyStr(LastError, 1, MaxStrLen(CDSConnectionSetup."Disable Reason")));
        CDSConnectionSetup.Modify();

        SendTraceTag('0000AUY', CategoryTok, VERBOSITY::Normal, IntegrationDisabledTxt, DataClassification::SystemMetadata);
    end;

    [Scope('OnPrem')]
    procedure UpdateDomainName(var CDSConnectionSetup: Record "CDS Connection Setup")
    var
        UserName: Text;
    begin
        UserName := CDSConnectionSetup."User Name";
        if UserName <> '' then
            if StrPos(UserName, '\') > 0 then
                CDSConnectionSetup.Validate(Domain, CopyStr(UserName, 1, StrPos(UserName, '\') - 1))
            else
                CDSConnectionSetup.Domain := '';
    end;

    [Scope('OnPrem')]
    procedure CheckUserName(var CDSConnectionSetup: Record "CDS Connection Setup")
    var
        UserName: Text;
    begin
        UserName := CDSConnectionSetup."User Name";
        if UserName <> '' then
            case CDSConnectionSetup."Authentication Type" of
                CDSConnectionSetup."Authentication Type"::AD:
                    if StrPos(UserName, '\') = 0 then
                        Error(UserNameMustIncludeDomainErr);
                CDSConnectionSetup."Authentication Type"::Office365:
                    if StrPos(UserName, '@') = 0 then
                        Error(UserNameMustBeEmailErr);
            end;
    end;

    local procedure GetDomainToken(var CDSConnectionSetup: Record "CDS Connection Setup"): Text
    begin
        if CDSConnectionSetup.Domain <> '' then
            exit(StrSubstNo('Domain=%1;', CDSConnectionSetup.Domain));
    end;

    local procedure GetAuthenticationTypeToken(var CDSConnectionSetup: Record "CDS Connection Setup"): Text
    begin
        case CDSConnectionSetup."Authentication Type" of
            CDSConnectionSetup."Authentication Type"::Office365:
                exit('AuthType=Office365;');
            CDSConnectionSetup."Authentication Type"::AD:
                exit('AuthType=AD;' + GetDomainToken(CDSConnectionSetup));
            CDSConnectionSetup."Authentication Type"::IFD:
                exit('AuthType=IFD;' + GetDomainToken(CDSConnectionSetup) + 'HomeRealmUri= ;');
            CDSConnectionSetup."Authentication Type"::OAuth:
                exit('AuthType=OAuth;' + 'AppId= ;' + 'RedirectUri= ;' + 'TokenCacheStorePath= ;' + 'LoginPrompt=Auto;');
        end;
    end;

    [Scope('OnPrem')]
    procedure IsCDSVersionValid(CDSVersion: Text): Boolean
    var
        Version: DotNet Version;
    begin
        if CDSVersion <> '' then
            if Version.TryParse(CDSVersion, Version) then
                exit((Version.Major() > 6) and not ((Version.Major() = 7) and (Version.Minor() = 1)));
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure IsSolutionVersionValid(SolutionVersion: Text): Boolean
    var
        Version: DotNet Version;
    begin
        if SolutionVersion <> '' then
            if Version.TryParse(SolutionVersion, Version) then
                exit(Version.Major() >= 1);
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure UpdateConnectionSetupFromWizard(var SourceCDSConnectionSetup: Record "CDS Connection Setup"; PasswordText: Text)
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        SendTraceTag('0000AUZ', CategoryTok, VERBOSITY::Normal, UpdateSetupTxt, DataClassification::SystemMetadata);

        if not CDSConnectionSetup.Get() then begin
            CDSConnectionSetup.Init();
            CDSConnectionSetup.Insert();
        end;
        CDSConnectionSetup.Validate("Server Address", SourceCDSConnectionSetup."Server Address");
        CDSConnectionSetup.Validate("Authentication Type", CDSConnectionSetup."Authentication Type"::Office365);
        CDSConnectionSetup.Validate("User Name", SourceCDSConnectionSetup."User Name");
        CDSConnectionSetup.SetPassword(PasswordText);
        CDSConnectionSetup.Validate("Proxy Version", SourceCDSConnectionSetup."Proxy Version");
        CDSConnectionSetup.Validate("Business Unit Id", SourceCDSConnectionSetup."Business Unit Id");
        CDSConnectionSetup.Validate("Business Unit Name", SourceCDSConnectionSetup."Business Unit Name");
        CDSConnectionSetup.Validate("Is Enabled", SourceCDSConnectionSetup."Is Enabled");
        if SourceCDSConnectionSetup."Ownership Model" in [CDSConnectionSetup."Ownership Model"::Person, CDSConnectionSetup."Ownership Model"::Team] then
            CDSConnectionSetup.Validate("Ownership Model", SourceCDSConnectionSetup."Ownership Model")
        else
            CDSConnectionSetup.Validate("Ownership Model", CDSConnectionSetup."Ownership Model"::Team);

        CDSConnectionSetup.Modify(true);

        SendTraceTag('0000AV0', CategoryTok, VERBOSITY::Normal, SetupUpdatedTxt, DataClassification::SystemMetadata);
    end;

    local procedure PromptForAdminCredentials(var CDSConnectionSetup: Record "CDS Connection Setup"; var AdminUser: Text; var AdminPassword: Text): Boolean
    var
        TempOfficeAdminCredentials: Record "Office Admin. Credentials" temporary;
    begin
        TempOfficeAdminCredentials.Endpoint := CDSConnectionSetup."Server Address";
        TempOfficeAdminCredentials.Insert();
        Commit();
        if Page.RunModal(Page::"CDS Admin Credentials", TempOfficeAdminCredentials) <> Action::LookupOK then begin
            SendTraceTag('0000AV1', CategoryTok, Verbosity::Normal, IgnoredAdminCredentialsTxt, DataClassification::SystemMetadata);
            exit(false);
        end;
        if (TempOfficeAdminCredentials.Email = '') or (TempOfficeAdminCredentials.Password = '') then begin
            SendTraceTag('0000AV2', CategoryTok, Verbosity::Normal, InvalidAdminCredentialsTxt, DataClassification::SystemMetadata);
            exit(false);
        end;

        AdminUser := TempOfficeAdminCredentials.Email;
        AdminPassword := TempOfficeAdminCredentials.Password;
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure GetTempConnectionName(): Text
    begin
        if TemporaryConnectionName = '' then
            TemporaryConnectionName := StrSubstNo('%1%2', TemporaryConnectionPrefixTok, CreateGuid());
        exit(TemporaryConnectionName);
    end;

    [Scope('OnPrem')]
    procedure GetDefaultBusinessUnitName(): Text[160]
    var
        Company: Record Company;
    begin
        Company.Get(CompanyName());
        exit(GetDefaultBusinessUnitName(Company.Name, GetCompanyExternalId(Company)));
    end;

    local procedure GetDefaultBusinessUnitName(CompanyName: Text; CompanyId: Text) BusinessUnitName: Text[160]
    begin
        BusinessUnitName := CopyStr(StrSubstNo(BusinessUnitNameTemplateTok, CompanyName, CompanyId), 1, MaxStrLen(BusinessUnitName));
    end;

    local procedure GetOwningTeamName(BusinessUnitName: Text) TeamName: Text[160]
    begin
        TeamName := CopyStr(StrSubstNo(TeamNameTemplateTok, BusinessUnitName), 1, MaxStrLen(TeamName));
    end;

    local procedure GetCompanyExternalId() ExternalId: Text[36]
    var
        Company: Record Company;
    begin
        Company.Get(CompanyName());
        ExternalId := GetCompanyExternalId(Company);
    end;

    local procedure GetCompanyExternalId(Company: Record Company) ExternalId: Text[36]
    begin
        ExternalId := CopyStr(Format(Company.SystemId).ToLower().Replace('{', '').Replace('}', ''), 1, MaxStrLen(ExternalId));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Connection", 'OnRegisterServiceConnection', '', false, false)]
    local procedure HandleOnRegisterServiceConnection(var ServiceConnection: Record "Service Connection")
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        RecRef: RecordRef;
    begin
        if not CDSConnectionSetup.Get() then begin
            if not CDSConnectionSetup.WritePermission() then begin
                SendTraceTag('0000AV4', CategoryTok, VERBOSITY::Normal, NoPermissionsTxt, DataClassification::SystemMetadata);
                exit;
            end;
            CDSConnectionSetup.Init();
            CDSConnectionSetup.Insert();
        end;

        RecRef.GetTable(CDSConnectionSetup);
        ServiceConnection.Status := ServiceConnection.Status::Enabled;
        if not CDSConnectionSetup."Is Enabled" then
            ServiceConnection.Status := ServiceConnection.Status::Disabled
        else
            if TryCheckEntitiesAvailability(CDSConnectionSetup) then
                ServiceConnection.Status := ServiceConnection.Status::Connected
            else
                ServiceConnection.Status := ServiceConnection.Status::Error;
        ServiceConnection.InsertServiceConnectionExtended(
          ServiceConnection, RecRef.RecordId(),
          CDSConnectionSetup.TableCaption(), CDSConnectionSetup."Server Address",
          PAGE::"CDS Connection Setup", PAGE::"CDS Connection Setup Wizard");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Assisted Setup", 'OnRegister', '', true, true)]
    local procedure HandleAssistedSetupOnRegister()
    begin
        RegisterAssistedSetup();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CDS Integration Mgt.", 'OnEnableIntegration', '', true, true)]
    local procedure HandleOnEnableIntegration()
    begin
        SendTraceTag('0000AV5', CategoryTok, VERBOSITY::Normal, OnEnableIntegrationTxt, DataClassification::SystemMetadata);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CDS Integration Mgt.", 'OnDisableIntegration', '', true, true)]
    local procedure HandleOnDisableIntegration()
    begin
        SendTraceTag('0000AV6', CategoryTok, VERBOSITY::Normal, OnDisableIntegrationTxt, DataClassification::SystemMetadata);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Integration Synch. Job Errors", 'OnIsDataIntegrationEnabled', '', false, false)]
    local procedure IsDataIntegrationEnabled(var IsIntegrationEnabled: Boolean)
    begin
        if not IsIntegrationEnabled then
            IsIntegrationEnabled := CDSIntegrationMgt.IsIntegrationEnabled();
    end;
}