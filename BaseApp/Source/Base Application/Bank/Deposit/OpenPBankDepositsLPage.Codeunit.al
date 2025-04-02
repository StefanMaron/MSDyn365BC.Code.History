// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Deposit;

codeunit 1515 "Open P. Bank Deposits L. Page"
{
    trigger OnRun()
    begin
        OnOpenPostedBankDepositsListPage();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenPostedBankDepositsListPage()
    begin
    end;
}
