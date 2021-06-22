codeunit 7200 "CDS Integration Mgt."
{
    Access = Public;
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";

    [Scope('Cloud')]
    procedure TestConnection(): Boolean
    begin
        exit(CDSIntegrationImpl.TestActiveConnection());
    end;

    [Scope('Cloud')]
    procedure ActivateConnection(): Boolean
    begin
        exit(CDSIntegrationImpl.ActivateConnection());
    end;

    [Scope('Cloud')]
    procedure RegisterConnection(): Boolean
    begin
        exit(CDSIntegrationImpl.RegisterConnection());
    end;

    [Scope('Cloud')]
    procedure IsIntegrationEnabled(): Boolean
    begin
        exit(CDSIntegrationImpl.IsIntegrationEnabled());
    end;

    [Scope('Cloud')]
    procedure IsConnectionActive(): Boolean
    var
    begin
        exit(CDSIntegrationImpl.IsConnectionActive());
    end;

    [Scope('Cloud')]
    procedure IsSolutionInstalled(): Boolean
    var
    begin
        exit(CDSIntegrationImpl.IsSolutionInstalled());
    end;

    [Scope('Cloud')]
    procedure IsSolutionInstalled(UniqueName: Text): Boolean
    var
    begin
        exit(CDSIntegrationImpl.IsSolutionInstalled(UniqueName));
    end;

    [Scope('Cloud')]
    procedure GetSolutionVersion(var Version: Text): Boolean
    var
    begin
        exit(CDSIntegrationImpl.GetSolutionVersion(Version));
    end;

    [Scope('Cloud')]
    procedure GetSolutionVersion(UniqueName: Text; var Version: Text): Boolean
    var
    begin
        exit(CDSIntegrationImpl.GetSolutionVersion(UniqueName, Version));
    end;

    [Scope('Cloud')]
    procedure CheckCompanyId(var RecRef: RecordRef): Boolean
    var
    begin
        exit(CDSIntegrationImpl.CheckCompanyId(RecRef));
    end;

    [Scope('Cloud')]
    procedure CheckOwningTeam(var RecRef: RecordRef): Boolean
    var
    begin
        exit(CDSIntegrationImpl.CheckOwningTeam(RecRef));
    end;

    [Scope('Cloud')]
    procedure CheckOwningUser(var RecRef: RecordRef; UserId: Guid): Boolean
    var
    begin
        exit(CDSIntegrationImpl.CheckOwningUser(RecRef, UserId));
    end;

    [Scope('Cloud')]
    procedure CheckOwningUser(var RecRef: RecordRef; UserId: Guid; SkipBusinessUnitCheck: Boolean): Boolean
    var
    begin
        exit(CDSIntegrationImpl.CheckOwningUser(RecRef, UserId, SkipBusinessUnitCheck));
    end;

    [Scope('Cloud')]
    procedure SetCompanyId(var RecRef: RecordRef): Boolean
    var
    begin
        exit(CDSIntegrationImpl.SetCompanyId(RecRef));
    end;

    [Scope('Cloud')]
    procedure SetOwningTeam(var RecRef: RecordRef): Boolean
    var
    begin
        exit(CDSIntegrationImpl.SetOwningTeam(RecRef));
    end;

    [Scope('Cloud')]
    procedure SetOwningUser(var RecRef: RecordRef; UserId: Guid): Boolean
    var
    begin
        exit(CDSIntegrationImpl.SetOwningUser(RecRef, UserId, false));
    end;

    [Scope('Cloud')]
    procedure SetOwningUser(var RecRef: RecordRef; UserId: Guid; SkipBusinessUnitCheck: Boolean): Boolean
    var
    begin
        exit(CDSIntegrationImpl.SetOwningUser(RecRef, UserId, SkipBusinessUnitCheck));
    end;

    [Scope('Cloud')]
    procedure GetCDSCompany(var CDSCompany: Record "CDS Company"): Boolean
    begin
        exit(CDSIntegrationImpl.TryGetCDSCompany(CDSCompany));
    end;

    [Scope('Cloud')]
    procedure GetCoupledBusinessUnitId(): Guid
    begin
        exit(CDSIntegrationImpl.GetCoupledBusinessUnitId());
    end;

    [Scope('Cloud')]
    procedure RegisterAssistedSetup()
    begin
        CDSIntegrationImpl.RegisterAssistedSetup();
    end;

    [Scope('Cloud')]
    procedure ResetCache()
    begin
        CDSIntegrationImpl.ResetCache();
    end;

    [Scope('Cloud')]
    [IntegrationEvent(false, false)]
    procedure OnBeforeRegisterConnection()
    begin
    end;

    [Scope('Cloud')]
    [IntegrationEvent(false, false)]
    procedure OnAfterRegisterConnection()
    begin
    end;

    [Scope('Cloud')]
    [IntegrationEvent(false, false)]
    procedure OnBeforeUnregisterConnection()
    begin
    end;

    [Scope('Cloud')]
    [IntegrationEvent(false, false)]
    procedure OnAfterUnregisterConnection()
    begin
    end;

    [Scope('Cloud')]
    [IntegrationEvent(false, false)]
    procedure OnBeforeActivateConnection()
    begin
    end;

    [Scope('Cloud')]
    [IntegrationEvent(false, false)]
    procedure OnAfterActivateConnection()
    begin
    end;

    [Scope('Cloud')]
    [IntegrationEvent(false, false)]
    procedure OnEnableIntegration()
    begin
    end;

    [Scope('Cloud')]
    [IntegrationEvent(false, false)]
    procedure OnDisableIntegration()
    begin
    end;

    [Scope('Cloud')]
    [IntegrationEvent(false, false)]
    procedure OnGetIntegrationRequiredRoles(var RequiredRoleIdList: List of [Guid])
    begin
    end;

    [Scope('Cloud')]
    [IntegrationEvent(false, false)]
    procedure OnGetIntegrationSolutions(var SolutionUniqueNameList: List of [Text])
    begin
    end;
}

