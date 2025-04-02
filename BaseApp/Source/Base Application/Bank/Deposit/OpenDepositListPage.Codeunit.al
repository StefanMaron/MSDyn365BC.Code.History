// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Deposit;

codeunit 1506 "Open Deposit List Page"
{
    trigger OnRun()
    begin
        OnOpenDepositListPage();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenDepositListPage()
    begin
    end;
}
