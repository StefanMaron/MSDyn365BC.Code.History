// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Finance.GeneralLedger.Setup;
using System.Utilities;

codeunit 5951 "Service-Disc. (Yes/No)"
{
    TableNo = "Service Line";

    trigger OnRun()
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        ServiceLine.Copy(Rec);
        GLSetup.Get();
        if GLSetup."Payment Discount Type" <> GLSetup."Payment Discount Type"::"Calc. Pmt. Disc. on Lines" then begin
            if ConfirmManagement.GetResponseOrDefault(Text000, true) then
                CODEUNIT.Run(CODEUNIT::"Service-Calc. Discount", ServiceLine);
        end else
            if Confirm(Text1100000, false) then
                CODEUNIT.Run(CODEUNIT::"Service-Calc. Discount", ServiceLine);

        Rec := ServiceLine;
    end;

    var
        GLSetup: Record "General Ledger Setup";
        ServiceLine: Record "Service Line";

#pragma warning disable AA0074
        Text000: Label 'Do you want to calculate the invoice discount?';
        Text1100000: Label 'Do you want to calculate the invoice discount and payment discount?';
#pragma warning restore AA0074
}

