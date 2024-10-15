// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;

using Microsoft.Integration.D365Sales;

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
    procedure IsBusinessEventsEnabled(): Boolean
    begin
        exit(CDSIntegrationImpl.IsBusinessEventsEnabled());
    end;

    [Scope('Cloud')]
    procedure IsConnectionActive(): Boolean
    begin
        exit(CDSIntegrationImpl.IsConnectionActive());
    end;

    [Scope('Cloud')]
    procedure IsSolutionInstalled(): Boolean
    begin
        exit(CDSIntegrationImpl.IsSolutionInstalled());
    end;

    [Scope('Cloud')]
    procedure IsSolutionInstalled(UniqueName: Text): Boolean
    begin
        exit(CDSIntegrationImpl.IsSolutionInstalled(UniqueName));
    end;

    [Scope('Cloud')]
    procedure GetSolutionVersion(var Version: Text): Boolean
    begin
        exit(CDSIntegrationImpl.GetSolutionVersion(Version));
    end;

    [Scope('Cloud')]
    procedure GetSolutionVersion(UniqueName: Text; var Version: Text): Boolean
    begin
        exit(CDSIntegrationImpl.GetSolutionVersion(UniqueName, Version));
    end;

    [Scope('Cloud')]
    procedure CheckCompanyId(var RecRef: RecordRef): Boolean
    begin
        exit(CDSIntegrationImpl.CheckCompanyId(RecRef));
    end;

    [Scope('Cloud')]
    procedure CheckOwningTeam(var RecRef: RecordRef): Boolean
    begin
        exit(CDSIntegrationImpl.CheckOwningTeam(RecRef));
    end;

    [Scope('Cloud')]
    procedure CheckOwningUser(var RecRef: RecordRef; UserId: Guid): Boolean
    begin
        exit(CDSIntegrationImpl.CheckOwningUser(RecRef, UserId));
    end;

    [Scope('Cloud')]
    procedure CheckOwningUser(var RecRef: RecordRef; UserId: Guid; SkipBusinessUnitCheck: Boolean): Boolean
    begin
        exit(CDSIntegrationImpl.CheckOwningUser(RecRef, UserId, SkipBusinessUnitCheck));
    end;

    [Scope('Cloud')]
    procedure HasCompanyIdField(TableId: Integer): Boolean
    begin
        exit(CDSIntegrationImpl.HasCompanyIdField(TableId));
    end;

    [Scope('Cloud')]
    procedure ResetCompanyId(var RecRef: RecordRef): Boolean
    begin
        exit(CDSIntegrationImpl.ResetCompanyId(RecRef));
    end;

    [Scope('Cloud')]
    procedure SetCompanyId(var RecRef: RecordRef): Boolean
    begin
        exit(CDSIntegrationImpl.SetCompanyId(RecRef));
    end;

    [Scope('Cloud')]
    procedure SetOwningTeam(var RecRef: RecordRef): Boolean
    begin
        exit(CDSIntegrationImpl.SetOwningTeam(RecRef));
    end;

    [Scope('Cloud')]
    procedure SetOwningUser(var RecRef: RecordRef; UserId: Guid): Boolean
    begin
        exit(CDSIntegrationImpl.SetOwningUser(RecRef, UserId, false));
    end;

    [Scope('Cloud')]
    procedure SetOwningUser(var RecRef: RecordRef; UserId: Guid; SkipBusinessUnitCheck: Boolean): Boolean
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
    procedure IsTeamOwnershipModelSelected(): Boolean
    begin
        exit(CDSIntegrationImpl.IsTeamOwnershipModelSelected());
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
    procedure GetOptionSetMetadata(EntityName: Text; FieldName: Text): Dictionary of [Integer, Text]
    begin
        exit(CDSIntegrationImpl.GetOptionSetMetadata(EntityName, FieldName));
    end;

    [Scope('Cloud')]
    procedure InsertOptionSetMetadata(EntityName: Text; FieldName: Text; NewOptionLabel: Text): Integer
    begin
        exit(CDSIntegrationImpl.InsertOptionSetMetadata(EntityName, FieldName, NewOptionLabel));
    end;

    [Scope('Cloud')]
    procedure InsertOptionSetMetadataWithOptionValue(EntityName: Text; FieldName: Text; NewOptionLabel: Text; NewOptionValue: Integer): Integer
    begin
        exit(CDSIntegrationImpl.InsertOptionSetMetadataWithOptionValue(EntityName, FieldName, NewOptionLabel, NewOptionValue));
    end;

    [Scope('Cloud')]
    procedure UpdateOptionSetMetadata(EntityName: Text; FieldName: Text; OptionValue: Integer; NewOptionLabel: Text)
    begin
        CDSIntegrationImpl.UpdateOptionSetMetadata(EntityName, FieldName, OptionValue, NewOptionLabel);
    end;

    [Scope('Cloud')]
    procedure FindCompanyIdField(var RecRef: RecordRef; var CompanyIdFldRef: FieldRef): Boolean
    begin
        exit(CDSIntegrationImpl.FindCompanyIdField(RecRef, CompanyIdFldRef));
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

    [Scope('Cloud')]
    [IntegrationEvent(false, false)]
    procedure OnGetDetailedLoggingEnabled(var Enabled: Boolean)
    begin
    end;

    [Scope('Cloud')]
    [IntegrationEvent(false, false)]
    procedure OnHasCompanyIdField(TableId: Integer; var HasField: Boolean)
    begin
    end;
}

