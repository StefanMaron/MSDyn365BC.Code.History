// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

codeunit 28065 "Sales Cr.Memo Header - Edit"
{
    Permissions = TableData "Sales Cr.Memo Header" = rm;
    TableNo = "Sales Cr.Memo Header";
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced with codeunit 1408 Sales Credit Memo Hdr. - Edit';
    ObsoleteTag = '17.0';

    trigger OnRun()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        SalesCrMemoHeader := Rec;
        SalesCrMemoHeader.LockTable();
        SalesCrMemoHeader.Find();
        SalesCrMemoHeader."Adjustment Applies-to" := Rec."Adjustment Applies-to";
        SalesCrMemoHeader."Reason Code" := Rec."Reason Code";
        SalesCrMemoHeader.TestField("No.", Rec."No.");
        SalesCrMemoHeader.Modify();
        Rec := SalesCrMemoHeader;
    end;
}

