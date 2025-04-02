// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Deposit;

codeunit 1513 "Open Deposit Test Report"
{
    trigger OnRun()
    begin
        OnOpenDepositTestReport();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenDepositTestReport()
    begin
    end;

}
