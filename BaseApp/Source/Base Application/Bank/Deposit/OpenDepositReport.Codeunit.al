// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Deposit;

codeunit 1507 "Open Deposit Report"
{
    trigger OnRun()
    begin
        OnOpenDepositReport();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenDepositReport()
    begin
    end;

}
