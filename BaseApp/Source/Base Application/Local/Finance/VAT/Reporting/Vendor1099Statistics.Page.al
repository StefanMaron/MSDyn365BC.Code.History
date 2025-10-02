#if not CLEAN25
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Utilities;

page 10016 "Vendor 1099 Statistics"
{
    Caption = 'Vendor 1099 Statistics';
    Editable = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = Vendor;
    ObsoleteReason = 'Moved to IRS Forms App.';
    ObsoleteState = Pending;
    ObsoleteTag = '25.0';

    layout
    {
        area(content)
        {
            group(Control1170000001)
            {
                ShowCaption = false;
                fixed(Control1170000002)
                {
                    ShowCaption = false;
                    group("1099 Code")
                    {
                        Caption = '1099 Code';
                        field("Codes[1]"; Codes[1])
                        {
                            ApplicationArea = BasicUS;
                        }
                        field("Codes[2]"; Codes[2])
                        {
                            ApplicationArea = BasicUS;
                        }
                        field("Codes[3]"; Codes[3])
                        {
                            ApplicationArea = BasicUS;
                        }
                        field("Codes[4]"; Codes[4])
                        {
                            ApplicationArea = BasicUS;
                        }
                        field("Codes[5]"; Codes[5])
                        {
                            ApplicationArea = BasicUS;
                        }
                        field("Codes[6]"; Codes[6])
                        {
                            ApplicationArea = BasicUS;
                        }
                        field("Codes[7]"; Codes[7])
                        {
                            ApplicationArea = BasicUS;
                        }
                        field("Codes[8]"; Codes[8])
                        {
                            ApplicationArea = BasicUS;
                        }
                        field("Codes[9]"; Codes[9])
                        {
                            ApplicationArea = BasicUS;
                        }
                        field("Codes[10]"; Codes[10])
                        {
                            ApplicationArea = BasicUS;
                        }
                    }
                    group(Description)
                    {
                        Caption = 'Description';
                        field("Descriptions[1]"; Descriptions[1])
                        {
                            ApplicationArea = BasicUS;
                        }
                        field("Descriptions[2]"; Descriptions[2])
                        {
                            ApplicationArea = BasicUS;
                        }
                        field("Descriptions[3]"; Descriptions[3])
                        {
                            ApplicationArea = BasicUS;
                        }
                        field("Descriptions[4]"; Descriptions[4])
                        {
                            ApplicationArea = BasicUS;
                        }
                        field("Descriptions[5]"; Descriptions[5])
                        {
                            ApplicationArea = BasicUS;
                        }
                        field("Descriptions[6]"; Descriptions[6])
                        {
                            ApplicationArea = BasicUS;
                        }
                        field("Descriptions[7]"; Descriptions[7])
                        {
                            ApplicationArea = BasicUS;
                        }
                        field("Descriptions[8]"; Descriptions[8])
                        {
                            ApplicationArea = BasicUS;
                        }
                        field("Descriptions[9]"; Descriptions[9])
                        {
                            ApplicationArea = BasicUS;
                        }
                        field("Descriptions[10]"; Descriptions[10])
                        {
                            ApplicationArea = BasicUS;
                        }
                    }
                    group(Amount)
                    {
                        Caption = 'Amount';
                        field("Amounts[1]"; Amounts[1])
                        {
                            ApplicationArea = BasicUS;
                        }
                        field("Amounts[2]"; Amounts[2])
                        {
                            ApplicationArea = BasicUS;
                        }
                        field("Amounts[3]"; Amounts[3])
                        {
                            ApplicationArea = BasicUS;
                        }
                        field("Amounts[4]"; Amounts[4])
                        {
                            ApplicationArea = BasicUS;
                        }
                        field("Amounts[5]"; Amounts[5])
                        {
                            ApplicationArea = BasicUS;
                        }
                        field("Amounts[6]"; Amounts[6])
                        {
                            ApplicationArea = BasicUS;
                        }
                        field("Amounts[7]"; Amounts[7])
                        {
                            ApplicationArea = BasicUS;
                        }
                        field("Amounts[8]"; Amounts[8])
                        {
                            ApplicationArea = BasicUS;
                        }
                        field("Amounts[9]"; Amounts[9])
                        {
                            ApplicationArea = BasicUS;
                        }
                        field("Amounts[10]"; Amounts[10])
                        {
                            ApplicationArea = BasicUS;
                        }
                    }
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        IRS1099Management: Codeunit "IRS 1099 Management";
    begin
        IRS1099Management.ThrowUseNewIRSFormsFeatureError();
    end;

    trigger OnAfterGetRecord()
    begin
        ClearAll();
        HiLineOnScreen := 10;
        CalculateVendor1099();
    end;

    var
        PaymentEntry: Record "Vendor Ledger Entry";
        IRS1099FormBox: Record "IRS 1099 Form-Box";
        TempAppliedEntry: Record "Vendor Ledger Entry" temporary;
        EntryAppMgt: Codeunit "Entry Application Management";
        PeriodDate: array[2] of Date;
        Codes: array[100] of Code[10];
        Descriptions: array[100] of Text[50];
        Amounts: array[100] of Decimal;
        TempCode: Code[10];
        TempDesc: Text[50];
        TempAmt: Decimal;
        LastLineNo: Integer;
        HiLineOnScreen: Integer;
        Invoice1099Amount: Decimal;
        i: Integer;
        j: Integer;
        Year: Integer;
        PassComplete: Boolean;
        Text001: Label '(Unknown Box)';
        Text002: Label 'All other 1099 types';

    procedure CalculateVendor1099()
    var
        IsHandled: Boolean;
    begin
        Clear(Codes);
        Clear(Amounts);
        Clear(Descriptions);
        Clear(LastLineNo);

        IsHandled := false;
        OnBeforeCalculateVendor1099(Rec, Codes, Descriptions, Amounts, LastLineNo, IsHandled);
        if IsHandled then
            exit;

        Year := Date2DMY(WorkDate(), 3);
        PeriodDate[1] := DMY2Date(1, 1, Year);
        PeriodDate[2] := DMY2Date(31, 12, Year);
        PaymentEntry.SetCurrentKey("Document Type", "Vendor No.", "Posting Date");
        PaymentEntry.SetRange("Document Type", PaymentEntry."Document Type"::Payment);
        PaymentEntry.SetRange("Vendor No.", Rec."No.");
        PaymentEntry.SetRange("Posting Date", PeriodDate[1], PeriodDate[2]);
        OnCalculateVendor1099OnAfterSetFilters(PaymentEntry);
        if PaymentEntry.Find('-') then
            repeat
                ProcessInvoices();
            until PaymentEntry.Next() = 0;

        if LastLineNo > 1 then
            SortHiToLo();

        if LastLineNo > HiLineOnScreen then
            ConsolidateLast();
    end;

    procedure ProcessInvoices()
    begin
        EntryAppMgt.GetAppliedVendEntries(TempAppliedEntry, PaymentEntry, true);
        TempAppliedEntry.SetFilter("Document Type", '%1|%2', TempAppliedEntry."Document Type"::Invoice, TempAppliedEntry."Document Type"::"Credit Memo");
        TempAppliedEntry.SetFilter("IRS 1099 Amount", '<>0');
        OnProcessInvoicesOnAfterTempAppliedEntrySetFilters(TempAppliedEntry, PaymentEntry);
        if TempAppliedEntry.Find('-') then
            repeat
                Calculate1099Amount(TempAppliedEntry."Amount to Apply");
            until TempAppliedEntry.Next() = 0;
    end;

    procedure Calculate1099Amount(AppliedAmount: Decimal)
    begin
        TempAppliedEntry.CalcFields(Amount);
        Invoice1099Amount := -AppliedAmount * TempAppliedEntry."IRS 1099 Amount" / TempAppliedEntry.Amount;
        UpdateLines(TempAppliedEntry."IRS 1099 Code", Invoice1099Amount);
    end;

    procedure UpdateLines("Code": Code[10]; Amount: Decimal)
    begin
        i := 1;
        while (Codes[i] <> Code) and (i <= LastLineNo) do
            i := i + 1;

        if (Codes[i] = Code) and (i <= LastLineNo) then
            Amounts[i] := Amounts[i] + Amount
        else begin
            Codes[i] := Code;
            if IRS1099FormBox.Get(Code) then
                Descriptions[i] := PadStr(IRS1099FormBox.Description, MaxStrLen(Descriptions[1]))
            else
                Descriptions[i] := Text001;
            Amounts[i] := Amount;
            LastLineNo := LastLineNo + 1;
        end;

        if LastLineNo = ArrayLen(Codes) then begin
            Codes[LastLineNo - 1] := '';
            Descriptions[LastLineNo - 1] := '...';
            Amounts[LastLineNo - 1] := Amounts[LastLineNo - 1] + Amounts[LastLineNo];
            LastLineNo := LastLineNo - 1;
        end;
    end;

    procedure SortHiToLo()
    begin
        for i := 2 to LastLineNo do begin
            j := i;
            TempCode := Codes[i];
            TempDesc := Descriptions[i];
            TempAmt := Amounts[i];
            PassComplete := false;

            while not PassComplete do begin
                PassComplete := true;
                if j > 1 then
                    if Abs(Amounts[j - 1]) < Abs(TempAmt) then begin
                        Codes[j] := Codes[j - 1];
                        Descriptions[j] := Descriptions[j - 1];
                        Amounts[j] := Amounts[j - 1];
                        j := j - 1;
                        PassComplete := false;
                    end;
            end;

            if j < i then begin
                Codes[j] := TempCode;
                Descriptions[j] := TempDesc;
                Amounts[j] := TempAmt;
            end;
        end;
    end;

    procedure ConsolidateLast()
    begin
        for i := HiLineOnScreen + 1 to LastLineNo do begin
            Amounts[HiLineOnScreen] := Amounts[HiLineOnScreen] + Amounts[i];
            Clear(Codes[i]);
            Clear(Descriptions[i]);
            Clear(Amounts[i]);
        end;
        Clear(Codes[HiLineOnScreen]);
        Descriptions[HiLineOnScreen] := Text002;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateVendor1099OnAfterSetFilters(var PaymentEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessInvoicesOnAfterTempAppliedEntrySetFilters(var TempAppliedEntry: Record "Vendor Ledger Entry" temporary; var PaymentEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCalculateVendor1099(Vendor: Record Vendor; Codes: array[100] of Code[10]; Descriptions: array[100] of Text[50]; Amounts: array[100] of Decimal; LastLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    procedure OverloadedUpdateLines(Code: Code[10]; Amount: Decimal; InYear: Date);
    begin
        OnOverloadedUpdateLines(Code, Amount, InYear, Codes, LastLineNo, Amounts, IRS1099FormBox, Descriptions);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnOverloadedUpdateLines(var Code: Code[10]; var Amount: Decimal; var InYear: Date; var Codes: array[100] of Code[10]; var LastLineNo: Integer; var Amounts: array[100] of Decimal; var IRS1099FormBox: Record "IRS 1099 Form-Box"; var Descriptions: array[100] of Text[50])
    begin
    end;
}

#endif
