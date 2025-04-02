// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Deposit;

codeunit 1505 "Open Deposit Page"
{
    trigger OnRun()
    begin
        OnOpenDepositPage();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenDepositPage()
    begin
    end;
}
