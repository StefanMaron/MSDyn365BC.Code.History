// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Foundation.NoSeries;
using Microsoft.Purchases.Payables;

codeunit 12171 "Vend. Bill List-Change Status"
{
    Permissions = TableData "Vendor Ledger Entry" = rimd;
    TableNo = "Vendor Bill Header";

    trigger OnRun()
    begin
        if not Confirm(Text000) then
            exit;

        FromOpenToSent(Rec);
    end;

    var
        Text000: Label 'Do you want to send the bill?';
        Text001: Label 'There are not lines to send.';
        Text002: Label '%1 or %2 for this %3 has not yet inserted. Please specify it in table %4 before running this function.';
        Text003: Label '%1 is not specified in %2 %3. Please specify it before running this function.';
        Text004: Label 'This operation will cause a gap in the numbering of %1. Continue anyway?';
        VendLedgEntry: Record "Vendor Ledger Entry";
        PaymentMethod: Record "Payment Method";
        BillCode: Record Bill;
        VendorBillLine: Record "Vendor Bill Line";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        NextVendBillNo: Code[20];

    [Scope('OnPrem')]
    procedure FromOpenToSent(var VendorBillHeader: Record "Vendor Bill Header")
    begin
        OnBeforeFromOpenToSent(VendorBillHeader);

        with VendorBillHeader do begin
            TestField("Posting Date");

            VendorBillLine.Reset();
            VendorBillLine.SetRange("Vendor Bill List No.", "No.");
            VendorBillLine.SetCurrentKey("Vendor No.", "External Document No.", "Document Date");
            if not VendorBillLine.Find('-') then
                Error(Text001);

            PaymentMethod.Get("Payment Method Code");
            BillCode.LockTable();
            BillCode.Get(PaymentMethod."Bill Code");
            if (BillCode."Vendor Bill List" = '') or
               (BillCode."Vendor Bill No." = '')
            then
                Error(Text002,
                  BillCode.FieldCaption("Vendor Bill List"),
                  BillCode.FieldCaption("Vendor Bill No."),
                  FieldCaption("Payment Method Code"),
                  BillCode.TableCaption());
            "Vendor Bill List No." := NoSeriesMgt.GetNextNo(BillCode."Vendor Bill List",
                "Posting Date", true);
            "List Status" := "List Status"::Sent;
            "User ID" := UserId;
            Modify();

            repeat
                if VendorBillLine."Due Date" = 0D then
                    Error(Text003,
                      VendorBillLine.FieldCaption("Due Date"),
                      VendorBillLine.FieldCaption("Line No."),
                      VendorBillLine."Line No.");
                if not VendorBillLine."Manual Line" then begin
                    NextVendBillNo := NoSeriesMgt.GetNextNo(BillCode."Vendor Bill No.",
                        "Posting Date", true);
                    VendLedgEntry.Get(VendorBillLine."Vendor Entry No.");
                    VendLedgEntry."Vendor Bill List" := "Vendor Bill List No.";
                    VendLedgEntry."Vendor Bill No." := NextVendBillNo;
                    VendLedgEntry.Modify();
                end;
                VendorBillLine."Vendor Bill No." := NextVendBillNo;
                OnFromOpenToSentOnBeforeVendorBillLineModify(VendorBillLine);
                VendorBillLine.Modify();
            until VendorBillLine.Next() = 0;
        end;

        OnAfterFromOpenToSent(VendorBillHeader);
    end;

    [Scope('OnPrem')]
    procedure FromSentToOpen(var VendorBillHeader: Record "Vendor Bill Header")
    begin
        OnBeforeFromSentToOpen(VendorBillHeader);

        with VendorBillHeader do begin
            if not Confirm(Text004, false, FieldCaption("Vendor Bill List No.")) then
                exit;

            "Vendor Bill List No." := '';
            "List Status" := "List Status"::Open;
            "User ID" := UserId;
            Modify();

            VendorBillLine.Reset();
            VendorBillLine.SetRange("Vendor Bill List No.", "No.");
            VendorBillLine.SetCurrentKey("Vendor No.", "External Document No.", "Document Date");
            if VendorBillLine.FindSet() then
                repeat
                    if not VendorBillLine."Manual Line" then begin
                        VendLedgEntry.Get(VendorBillLine."Vendor Entry No.");
                        VendLedgEntry."Vendor Bill List" := '';
                        VendLedgEntry."Vendor Bill No." := '';
                        VendLedgEntry.Modify();
                    end;
                    VendorBillLine."Vendor Bill No." := '';
                    VendorBillLine.Modify();
                until VendorBillLine.Next() = 0;
        end;

        OnAfterFromSentToOpen(VendorBillHeader);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFromOpenToSent(var VendorBillHeader: Record "Vendor Bill Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFromSentToOpen(var VendorBillHeader: Record "Vendor Bill Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFromOpenToSent(var VendorBillHeader: Record "Vendor Bill Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFromSentToOpen(var VendorBillHeader: Record "Vendor Bill Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFromOpenToSentOnBeforeVendorBillLineModify(var VendorBillLine: Record "Vendor Bill Line")
    begin
    end;
}

