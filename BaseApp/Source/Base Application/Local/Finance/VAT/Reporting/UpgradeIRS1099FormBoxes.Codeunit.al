// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;

codeunit 10501 "Upgrade IRS 1099 Form Boxes"
{
    Permissions = TableData Vendor = rim,
                  TableData "Vendor Ledger Entry" = rim,
                  TableData "Purchase Header" = rim,
                  TableData "Gen. Journal Line" = rim,
                  TableData "Purch. Inv. Header" = rim,
                  TableData "Purch. Cr. Memo Hdr." = rim;

    trigger OnRun()
    var
        IRS1099Management: Codeunit "IRS 1099 Management";
    begin
        if IRS1099Management.Upgrade2019Needed() then
            UpdateIRS1099FormBoxesTo2019();
        if IRS1099Management.Upgrade2020Needed() then
            UpdateIRS1099FormBoxesTo2020();
        if IRS1099Management.Upgrade2020FebruaryNeeded() then
            UpdateIRS1099FormBoxesTo2020February();
        if IRS1099Management.Upgrade2021Needed() then
            UpdateIRS1099FormBoxesTo2021();
        if IRS1099Management.Upgrade2022Needed() then
            UpdateIRS1099FormBoxesTo2022();
    end;

    var
        ConfirmIRS1099CodeUpdateQst: Label 'One or more entries have been posted with IRS 1099 code %1.\\Do you want to continue and update all the data associated with this vendor and the existing IRS 1099 code with the new code, %2?', Comment = '%1 - old code;%2 - new code';

    local procedure UpdateIRS1099FormBoxesTo2019()
    begin
        ShiftIRS1099('DIV-11');
        ShiftIRS1099('DIV-10');
        ShiftIRS1099('DIV-09');
        ShiftIRS1099('DIV-08');
        ShiftIRS1099('DIV-06');
        ShiftIRS1099('DIV-05');
        InsertIRS1099('DIV-05', 'Section 199A dividends', 10.0);
    end;

    local procedure UpdateIRS1099FormBoxesTo2020()
    begin
        MoveIRS1099('MISC-07', 'NEC-01');
        MoveIRS1099('MISC-09', 'MISC-07');
        MoveIRS1099('MISC-10', 'MISC-09');
        MoveIRS1099('MISC-14', 'MISC-10');
        MoveIRS1099('MISC-15-A', 'MISC-12');
        MoveIRS1099('MISC-16', 'MISC-15');
        InsertIRS1099('MISC-14', 'Nonqualified deferred compensation', 0);
    end;

    local procedure UpdateIRS1099FormBoxesTo2020February()
    begin
        InsertIRS1099('NEC-04', 'Federal income tax withheld', 0);
    end;

    local procedure UpdateIRS1099FormBoxesTo2021()
    begin
        InsertIRS1099('DIV-02-E', 'Section 897 ordinary dividends', 0);
        InsertIRS1099('DIV-02-F', 'Section 897 capital gain', 0);
        InsertIRS1099('MISC-11', 'Fish purchased for resale', 600);
        InsertIRS1099('NEC-02', 'Payer made direct sales totaling $5,000 or more of consumer products to recipient for resale', 5000);
    end;

    local procedure UpdateIRS1099FormBoxesTo2022()
    begin
        ShiftIRS1099('MISC-15');
        ShiftIRS1099('MISC-14');
        ShiftIRS1099('MISC-13');
        ShiftIRS1099('DIV-12');
        ShiftIRS1099('DIV-11');
    end;

    local procedure ShiftIRS1099(IRSCode: Code[10])
    var
        IRS1099FormBox: Record "IRS 1099 Form-Box";
    begin
        if not IRS1099FormBox.Get(IRSCode) then
            exit;

        IRS1099FormBox.Rename(IncStr(IRSCode));
    end;

    local procedure MoveIRS1099(FromIRSCode: Code[10]; ToIRSCode: Code[10])
    var
        IRS1099FormBox: Record "IRS 1099 Form-Box";
    begin
        if not IRS1099FormBox.Get(FromIRSCode) then
            exit;

        IRS1099FormBox.Rename(ToIRSCode);
    end;

    local procedure InsertIRS1099(NewCode: Code[10]; NewDescription: Text[100]; NewMinimum: Decimal)
    var
        IRS1099FormBox: Record "IRS 1099 Form-Box";
    begin
        IRS1099FormBox.Init();
        IRS1099FormBox.Code := NewCode;
        IRS1099FormBox.Description := NewDescription;
        IRS1099FormBox."Minimum Reportable" := NewMinimum;
        IRS1099FormBox.Insert();
    end;

    [Scope('OnPrem')]
    procedure UpdateIRSCodeInPostedData(VendNo: Code[20]; ExistingCode: Code[10]; NewCode: Code[10])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        GenJournalLineAccount: Record "Gen. Journal Line";
        GenJournalLineBalAccount: Record "Gen. Journal Line";
        Confirmed: Boolean;
    begin
        if ExistingCode = '' then
            exit;

        if ExistingCode <> NewCode then begin
            VendorLedgerEntry.SetRange("Vendor No.", VendNo);
            VendorLedgerEntry.SetRange("IRS 1099 Code", ExistingCode);
            PurchaseHeader.SetRange("Pay-to Vendor No.", VendNo);
            PurchaseHeader.SetRange("IRS 1099 Code", ExistingCode);
            PurchInvHeader.SetRange("Pay-to Vendor No.", VendNo);
            PurchInvHeader.SetRange("IRS 1099 Code", ExistingCode);
            PurchCrMemoHdr.SetRange("Pay-to Vendor No.", VendNo);
            PurchCrMemoHdr.SetRange("IRS 1099 Code", ExistingCode);
            GenJournalLineAccount.SetRange("Account Type", GenJournalLineAccount."Account Type"::Vendor);
            GenJournalLineAccount.SetRange("Account No.", VendNo);
            GenJournalLineAccount.SetRange("IRS 1099 Code", ExistingCode);
            GenJournalLineBalAccount.SetRange("Bal. Account Type", GenJournalLineAccount."Bal. Account Type"::Vendor);
            GenJournalLineBalAccount.SetRange("Bal. Account No.", VendNo);
            GenJournalLineBalAccount.SetRange("IRS 1099 Code", ExistingCode);
            if VendorLedgerEntry.IsEmpty() and PurchaseHeader.IsEmpty() and PurchInvHeader.IsEmpty() and
               PurchCrMemoHdr.IsEmpty() and GenJournalLineAccount.IsEmpty() and GenJournalLineBalAccount.IsEmpty
            then
                exit;
            if GuiAllowed then
                Confirmed := Confirm(StrSubstNo(ConfirmIRS1099CodeUpdateQst, ExistingCode, NewCode))
            else
                Confirmed := true;
            if not Confirmed then
                exit;
            VendorLedgerEntry.ModifyAll("IRS 1099 Code", NewCode);
            PurchaseHeader.ModifyAll("IRS 1099 Code", NewCode);
            PurchInvHeader.ModifyAll("IRS 1099 Code", NewCode);
            PurchCrMemoHdr.ModifyAll("IRS 1099 Code", NewCode);
            GenJournalLineAccount.ModifyAll("IRS 1099 Code", NewCode);
            GenJournalLineBalAccount.ModifyAll("IRS 1099 Code", NewCode);
        end;
    end;
}

