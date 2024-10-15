#if not CLEAN23
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;

codeunit 7207 "CDS Set Coupled Flags"
{
    SingleInstance = true;
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by flow fields Coupled to Dataverse';
    ObsoleteTag = '23.0';

    trigger OnRun()
    begin
        SetCoupledFlags();
    end;

    local procedure SetCoupledFlags()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        CommitCounter: Integer;
    begin
        if CRMIntegrationRecord.FindSet() then
            repeat
                if CRMIntegrationManagement.SetCoupledFlag(CRMIntegrationRecord, true, false) then
                    CommitCounter += 1;

                if CommitCounter = 1000 then begin
                    Commit();
                    CommitCounter := 0;
                end;
            until CRMIntegrationRecord.Next() = 0;
    end;
}
#endif