// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Deposit;

codeunit 1500 "Open Deposits Page"
{
    trigger OnRun()
    begin
        OnOpenDepositsPage();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenDepositsPage()
    begin
    end;
}
