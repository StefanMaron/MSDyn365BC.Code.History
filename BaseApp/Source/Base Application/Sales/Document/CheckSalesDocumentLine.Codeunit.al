// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Sales.Posting;

codeunit 9069 "Check Sales Document Line"
{
    TableNo = "Sales Line";

    trigger OnRun()
    begin
        RunCheck(Rec);
    end;

    var
        SalesHeader: Record "Sales Header";

    procedure SetSalesHeader(NewSalesHeader: Record "Sales Header")
    begin
        SalesHeader := NewSalesHeader;
    end;

    local procedure RunCheck(var SalesLine: Record "Sales Line")
    var
        SalesPost: Codeunit "Sales-Post";
    begin
        SalesPost.TestSalesLine(SalesHeader, SalesLine);
    end;
}
