// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Sales.Receivables;

codeunit 1409 "Sales Inv. Header - Edit"
{
    Permissions = TableData "Sales Invoice Header" = rm;
    TableNo = "Sales Invoice Header";

    trigger OnRun()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Copy(Rec);
        SalesInvoiceHeader.ReadIsolation(IsolationLevel::UpdLock);
        SalesInvoiceHeader.Find();
        OnRunOnBeforeAssignValues(SalesInvoiceHeader, Rec);
        SalesInvoiceHeader."Payment Method Code" := Rec."Payment Method Code";
        SalesInvoiceHeader."Payment Reference" := Rec."Payment Reference";
        SalesInvoiceHeader."Company Bank Account Code" := Rec."Company Bank Account Code";
        SalesInvoiceHeader."Posting Description" := Rec."Posting Description";
        SalesInvoiceHeader."Fiscal Invoice Number PAC" := Rec."Fiscal Invoice Number PAC";
        OnOnRunOnBeforeTestFieldNo(SalesInvoiceHeader, Rec);
        SalesInvoiceHeader.TestField("No.", Rec."No.");
        SalesInvoiceHeader.Modify();
        Rec.Copy(SalesInvoiceHeader);

        UpdateCustLedgerEntry(Rec);

        OnRunOnAfterSalesInvoiceHeaderEdit(Rec);
    end;

    local procedure UpdateCustLedgerEntry(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        if not GetCustLedgerEntry(CustLedgerEntry, SalesInvoiceHeader) then
            exit;
        CustLedgerEntry."Payment Method Code" := SalesInvoiceHeader."Payment Method Code";
        CustLedgerEntry."Payment Reference" := SalesInvoiceHeader."Payment Reference";
        CustLedgerEntry.Description := SalesInvoiceHeader."Posting Description";
        OnBeforeUpdateCustLedgerEntryAfterSetValues(CustLedgerEntry, SalesInvoiceHeader);
        Codeunit.Run(Codeunit::"Cust. Entry-Edit", CustLedgerEntry);
    end;

    local procedure GetCustLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; SalesInvoiceHeader: Record "Sales Invoice Header"): Boolean
    begin
        if SalesInvoiceHeader."Cust. Ledger Entry No." = 0 then
            exit(false);
        CustLedgerEntry.ReadIsolation(IsolationLevel::UpdLock);
        exit(CustLedgerEntry.Get(SalesInvoiceHeader."Cust. Ledger Entry No."));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOnRunOnBeforeTestFieldNo(var SalesInvoiceHeader: Record "Sales Invoice Header"; SalesInvoiceHeaderRec: Record "Sales Invoice Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeAssignValues(var SalesInvoiceHeader: Record "Sales Invoice Header"; SalesInvoiceHeaderRec: Record "Sales Invoice Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateCustLedgerEntryAfterSetValues(var CustLedgerEntry: Record "Cust. Ledger Entry"; SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterSalesInvoiceHeaderEdit(var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
    end;
}

