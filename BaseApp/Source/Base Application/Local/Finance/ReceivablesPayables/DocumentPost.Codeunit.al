﻿// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Bank.BankAccount;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using System.Security.User;

codeunit 7000006 "Document-Post"
{
    Permissions = TableData "Cust. Ledger Entry" = imd,
                  TableData "Vendor Ledger Entry" = imd,
                  TableData "Detailed Cust. Ledg. Entry" = imd,
                  TableData "Detailed Vendor Ledg. Entry" = imd,
                  TableData "Cartera Doc." = imd,
                  TableData "Posted Cartera Doc." = imd,
                  TableData "Closed Cartera Doc." = imd,
                  TableData "Posted Bill Group" = imd,
                  TableData "Closed Bill Group" = imd,
                  TableData "Posted Payment Order" = imd,
                  TableData "Closed Payment Order" = imd;

    trigger OnRun()
    begin
    end;

    var
        JournalErrorsMgt: Codeunit "Journal Errors Mgt.";
        Text1100000: Label 'must be of a type that creates bills';
        Text1100001: Label 'A customer or vendor must be specified when a bill is created.';
        Text1100004: Label 'Sales Bill %1/%2 already exists.';
        Text1100005: Label 'Purchase Document %1/%2 already exists.';
        Text1100006: Label 'Receivable %1 %2/%3 cannot be applied to, because it is included in a posted Bill Group.';
        Text1100007: Label 'Payable %1 %2/%3 cannot be applied to, because it is included in a posted Payment Order.';
        Text1100008: Label 'Date %1 is not within your range of allowed posting dates';
        Text1100009: Label '%1 must be entered.';
        Text1100010: Label '%1 must be of a type that creates bills.';
        Text1100011: Label 'A grouped document cannot be settled from a journal. Remove it from its group or payment order and try again.';
        Text1100012: Label 'cannot be filtered when posting recurring journals';
        Text1100013: Label 'Do you want to post the journal lines and print the posting report?';
        Text1100014: Label 'Do you want to post the journal lines?';
        Text1100016: Label 'The journal lines were successfully posted.';
        Text1100017: Label 'The journal lines were successfully posted. You are now in the %1 journal.';
        CarteraDocBillGroupErr: Label 'A grouped document cannot be settled from a journal.\Remove Document %1/%2 from Group/Pmt. Order %3 and try again.', Comment = '%1=Document Number,%2=Bill number,%3=Bill Group number.';

    procedure CheckGenJnlLine(var GenJnlLine: Record "Gen. Journal Line")
    var
        CarteraDoc: Record "Cartera Doc.";
        PaymentMethod: Record "Payment Method";
        SystemCreated: Boolean;
        CarteraDocType: Enum "Cartera Document Type";
    begin
        with GenJnlLine do begin
            if ("Document Type" = "Document Type"::Invoice) and
               ("Account Type" in ["Account Type"::Customer, "Account Type"::Vendor]) and
               (Amount <> 0)
            then begin
                TestField("Payment Method Code");
                TestField("Payment Terms Code");
            end;
            if ("Document Type" = "Document Type"::Bill) and
               (Amount <> 0)
            then begin
                TestField("Bill No.");
                TestField("Due Date");
                TestField("Payment Method Code");
                PaymentMethod.Get("Payment Method Code");
                if not PaymentMethod."Create Bills" then
                    FieldError("Payment Method Code", Text1100000);
                if not ("Account Type" in ["Account Type"::Customer, "Account Type"::Vendor]) then
                    Error(Text1100001)
            end;
            if "Document Type" = "Document Type"::"Credit Memo" then
                SystemCreated := false
            else
                SystemCreated := "System-Created Entry";

            if ("Account Type" in ["Account Type"::Customer, "Account Type"::Vendor]) and
               ("Applies-to Doc. Type" in ["Applies-to Doc. Type"::Bill, "Applies-to Doc. Type"::Invoice]) and
               not SystemCreated
            then begin
                if "Account Type" = "Account Type"::Customer then
                    CarteraDocType := CarteraDoc.Type::Receivable
                else
                    CarteraDocType := CarteraDoc.Type::Payable;
                CheckCarteraDocsForBillGroups(CarteraDocType, "Applies-to Doc. No.", "Applies-to Bill No.");
                CheckPostedCarteraDocsForBillGroups(CarteraDocType, "Applies-to Doc. No.", "Applies-to Bill No.");
            end;
        end;
        OnAfterCheckGenJnlLine(GenJnlLine);
    end;

    procedure CreateReceivableDoc(GenJnlLine: Record "Gen. Journal Line"; var CVLedgEntryBuf: Record "CV Ledger Entry Buffer"; IsFromJournal: Boolean)
    var
        CarteraDoc: Record "Cartera Doc.";
        CompanyInfo: Record "Company Information";
        OldCustLedgEntry: Record "Cust. Ledger Entry";
        CustBankAccCode: Record "Customer Bank Account";
    begin
        CarteraDoc.Init();
        GJLInfoToDoc(GenJnlLine, CarteraDoc);
        with CVLedgEntryBuf do begin
            CarteraDoc.Type := CarteraDoc.Type::Receivable;
            CarteraDoc."Entry No." := "Entry No.";
            CarteraDoc."Remaining Amount" := "Remaining Amount";
            CarteraDoc."Remaining Amt. (LCY)" := "Remaining Amt. (LCY)";
            CarteraDoc."Original Amount" := "Remaining Amount";
            CarteraDoc."Original Amount (LCY)" := "Remaining Amt. (LCY)";
            if CompanyInfo.Get() and CustBankAccCode.Get("CV No.", GenJnlLine."Recipient Bank Account") then
                CarteraDoc.Place := CopyStr(CompanyInfo."Post Code", 1, 2) = CopyStr(CustBankAccCode."Post Code", 1, 2);
            // Check the Doc no.
            OldCustLedgEntry.Reset();
            OldCustLedgEntry.SetCurrentKey("Document No.", "Document Type", "Customer No.");
            OldCustLedgEntry.SetRange("Document No.", "Document No.");
            if GenJnlLine."Document Type" = GenJnlLine."Document Type"::Bill then
                OldCustLedgEntry.SetRange("Document Type", OldCustLedgEntry."Document Type"::Bill)
            else
                if GenJnlLine."Document Type" = GenJnlLine."Document Type"::Invoice then
                    OldCustLedgEntry.SetRange("Document Type", OldCustLedgEntry."Document Type"::Invoice);
            OldCustLedgEntry.SetRange("Bill No.", "Bill No.");
            if OldCustLedgEntry.FindFirst() then
                Error(
                  Text1100004,
                  "Document No.", "Bill No.");
        end;

        if IsFromJournal then
            CarteraDoc."From Journal" := true;

        OnBeforeCreateReceivableDoc(CarteraDoc, GenJnlLine, CVLedgEntryBuf);
        CarteraDoc.Insert();
        OnAfterCreateReceivableDoc(CarteraDoc, GenJnlLine, CVLedgEntryBuf);
        CVLedgEntryBuf."Document Situation" := CVLedgEntryBuf."Document Situation"::Cartera;
        CVLedgEntryBuf."Document Status" := CVLedgEntryBuf."Document Status"::Open;
    end;

    procedure CreatePayableDoc(GenJnlLine: Record "Gen. Journal Line"; var CVLedgEntryBuf: Record "CV Ledger Entry Buffer"; IsFromJournal: Boolean)
    var
        CarteraDoc: Record "Cartera Doc.";
        OldVendLedgEntry: Record "Vendor Ledger Entry";
        ElectPmtMgmt: Codeunit "Elect. Pmts Management";
    begin
        CarteraDoc.Init();
        GJLInfoToDoc(GenJnlLine, CarteraDoc);
        with CVLedgEntryBuf do begin
            CarteraDoc.Type := CarteraDoc.Type::Payable;
            CarteraDoc."Entry No." := "Entry No.";
            CarteraDoc."Remaining Amount" := -"Remaining Amount";
            CarteraDoc."Remaining Amt. (LCY)" := -"Remaining Amt. (LCY)";
            CarteraDoc."Original Amount" := -"Remaining Amount";
            CarteraDoc."Original Amount (LCY)" := -"Remaining Amt. (LCY)";
            // Check the Doc no.
            OldVendLedgEntry.Reset();
            OldVendLedgEntry.SetCurrentKey("Document No.", "Document Type", "Vendor No.");
            OldVendLedgEntry.SetRange("Document No.", "Document No.");
            if GenJnlLine."Document Type" = GenJnlLine."Document Type"::Bill then
                OldVendLedgEntry.SetRange("Document Type", OldVendLedgEntry."Document Type"::Bill)
            else
                if GenJnlLine."Document Type" = GenJnlLine."Document Type"::Invoice then
                    OldVendLedgEntry.SetRange("Document Type", OldVendLedgEntry."Document Type"::Invoice);
            OldVendLedgEntry.SetRange("Bill No.", "Bill No.");
            if OldVendLedgEntry.FindFirst() then
                Error(
                  Text1100005,
                  "Document No.", "Bill No.");
        end;

        if IsFromJournal then
            CarteraDoc."From Journal" := true;

        ElectPmtMgmt.GetTransferType(CarteraDoc."Account No.", CarteraDoc."Remaining Amount", CarteraDoc."Transfer Type", true);

        OnBeforeCreatePayableDoc(CarteraDoc, GenJnlLine, CVLedgEntryBuf);
        CarteraDoc.Insert();
        OnAfterCreatePayableDoc(CarteraDoc, GenJnlLine, CVLedgEntryBuf);
        CVLedgEntryBuf."Document Situation" := CVLedgEntryBuf."Document Situation"::Cartera;
        CVLedgEntryBuf."Document Status" := CVLedgEntryBuf."Document Status"::Open;
    end;

    procedure GJLInfoToDoc(var GenJnlLine: Record "Gen. Journal Line"; var CarteraDoc: Record "Cartera Doc.")
    var
        PaymentMethod: Record "Payment Method";
        CompanyInfo: Record "Company Information";
        CustBankAcc: Record "Customer Bank Account";
#if not CLEAN22
        CustPmtAddress: Record "Customer Pmt. Address";
#endif
        Cust: Record Customer;
    begin
        with GenJnlLine do begin
            CarteraDoc."No." := "Bill No.";
            CarteraDoc."Posting Date" := "Posting Date";
            CarteraDoc."Document No." := "Document No.";
            CarteraDoc."Original Document No." := "Document No.";
            CarteraDoc.Description := Description;
            CarteraDoc."Due Date" := "Due Date";
            CarteraDoc."Payment Method Code" := "Payment Method Code";
            PaymentMethod.Get("Payment Method Code");
            if PaymentMethod."Submit for Acceptance" then
                CarteraDoc.Accepted := CarteraDoc.Accepted::No
            else
                CarteraDoc.Accepted := CarteraDoc.Accepted::"Not Required";
            CarteraDoc."Collection Agent" := PaymentMethod."Collection Agent";
            CarteraDoc."Account No." := "Account No.";
            CarteraDoc."Currency Code" := "Currency Code";
            CarteraDoc."Cust./Vendor Bank Acc. Code" :=
              CopyStr("Recipient Bank Account", 1, MaxStrLen(CarteraDoc."Cust./Vendor Bank Acc. Code"));
#if not CLEAN22
            CarteraDoc."Pmt. Address Code" := "Pmt. Address Code";
#endif
            CarteraDoc."Global Dimension 1 Code" := "Shortcut Dimension 1 Code";
            CarteraDoc."Global Dimension 2 Code" := "Shortcut Dimension 2 Code";
            CarteraDoc."Dimension Set ID" := "Dimension Set ID";
            CarteraDoc."Direct Debit Mandate ID" := "Direct Debit Mandate ID";
            case "Document Type" of
                "Document Type"::Bill:
                    CarteraDoc."Document Type" := CarteraDoc."Document Type"::Bill;
                "Document Type"::Invoice:
                    CarteraDoc."Document Type" := CarteraDoc."Document Type"::Invoice;
                "Document Type"::"Credit Memo":
                    CarteraDoc."Document Type" := 1;
            end;
            if "Account Type" = "Account Type"::Customer then begin
                CompanyInfo.Get();
                if "Recipient Bank Account" <> '' then begin
                    CustBankAcc.Get("Account No.", "Recipient Bank Account");
                    CarteraDoc.Place := CompanyInfo."Post Code" = CustBankAcc."Post Code";
                    exit;
                end;
#if not CLEAN22
                if "Pmt. Address Code" <> '' then begin
                    CustPmtAddress.Get("Account No.", "Pmt. Address Code");
                    CarteraDoc.Place := CompanyInfo."Post Code" = CustPmtAddress."Post Code";
                    exit;
                end;
#endif
                Cust.Get("Account No.");
                CarteraDoc.Place := CompanyInfo."Post Code" = Cust."Post Code";
            end;
        end;
    end;

    procedure UpdateReceivableDoc(var CustLedgEntry: Record "Cust. Ledger Entry"; var GenJnlLine: Record "Gen. Journal Line"; AppliedAmountLCY: Decimal; var DocAmountLCY: Decimal; var RejDocAmountLCY: Decimal; var DiscDocAmountLCY: Decimal; var CollDocAmountLCY: Decimal; var DiscRiskFactAmountLCY: Decimal; var DiscUnriskFactAmountLCY: Decimal; var CollFactAmountLCY: Decimal)
    var
        CarteraDoc: Record "Cartera Doc.";
        PostedCarteraDoc: Record "Posted Cartera Doc.";
        ClosedCarteraDoc: Record "Closed Cartera Doc.";
        CarteraDoc2: Record "Cartera Doc.";
        PostedCarteraDoc2: Record "Posted Cartera Doc.";
        ClosedCarteraDoc2: Record "Closed Cartera Doc.";
        PostedBillGroup: Record "Posted Bill Group";
        Currency: Record Currency;
        DocLock: Boolean;
    begin
        OnBeforeUpdateReceivableDoc(CustLedgEntry);
        with CustLedgEntry do begin
            if not DocLock then begin
                DocLock := true;
                CarteraDoc.LockTable();
                PostedCarteraDoc.LockTable();
                ClosedCarteraDoc.LockTable();
                if CarteraDoc2.FindLast() then;
                if PostedCarteraDoc2.FindLast() then;
                if ClosedCarteraDoc2.FindLast() then;
            end;
            if "Remaining Amount" = 0 then
                "Remaining Amt. (LCY)" := 0;
            if "Document Situation" <> "Document Situation"::Cartera then
                AppliedAmountLCY := Round(AppliedAmountLCY);
            case "Document Situation" of
                "Document Situation"::" ", "Document Situation"::Cartera:
                    begin
                        CarteraDoc.Get(CarteraDoc.Type::Receivable, "Entry No.");
                        if CarteraDoc."Currency Code" = '' then
                            CarteraDoc."Remaining Amount" := CarteraDoc."Remaining Amount" + AppliedAmountLCY
                        else begin
                            Currency.Get(CarteraDoc."Currency Code");
                            Currency.InitRoundingPrecision();
                            CarteraDoc."Remaining Amount" :=
                              CarteraDoc."Remaining Amount" +
                              Round(AppliedAmountLCY * "Original Currency Factor", Currency."Amount Rounding Precision");
                        end;
                        CarteraDoc."Remaining Amt. (LCY)" :=
                          Round(CarteraDoc."Remaining Amount" / "Original Currency Factor", Currency."Amount Rounding Precision");

                        AppliedAmountLCY := Round(AppliedAmountLCY);
                        if CarteraDoc."Document Type" = CarteraDoc."Document Type"::Bill then
                            DocAmountLCY := DocAmountLCY + AppliedAmountLCY;
                        CarteraDoc.ResetNoPrinted();
                        if Open then
                            CarteraDoc.Modify()
                        else begin
                            ClosedCarteraDoc.TransferFields(CarteraDoc);
                            ClosedCarteraDoc.Status := ClosedCarteraDoc.Status::Honored;
                            ClosedCarteraDoc."Honored/Rejtd. at Date" := GenJnlLine."Posting Date";
                            ClosedCarteraDoc."Bill Gr./Pmt. Order No." := '';
                            ClosedCarteraDoc."Remaining Amount" := 0;
                            ClosedCarteraDoc."Remaining Amt. (LCY)" := 0;
                            ClosedCarteraDoc."Amount for Collection" := 0;
                            ClosedCarteraDoc."Amt. for Collection (LCY)" := 0;
                            ClosedCarteraDoc.Insert();
                            CarteraDoc.Delete();
                            "Document Situation" := "Document Situation"::"Closed Documents";
                            "Document Status" := "Document Status"::Honored;
                            if "Document Type" <> "Document Type"::Invoice then
                                Modify();
                        end;
                    end;
                "Document Situation"::"Posted BG/PO":
                    begin
                        PostedCarteraDoc.Get(PostedCarteraDoc.Type::Receivable, "Entry No.");
                        PostedCarteraDoc."Remaining Amount" := "Remaining Amount";
                        PostedCarteraDoc."Remaining Amt. (LCY)" := "Remaining Amt. (LCY)";
                        if PostedCarteraDoc.Factoring = PostedCarteraDoc.Factoring::" " then begin
                            if PostedCarteraDoc.Status = PostedCarteraDoc.Status::Rejected then
                                RejDocAmountLCY := RejDocAmountLCY + AppliedAmountLCY
                            else
                                if PostedCarteraDoc."Dealing Type" = PostedCarteraDoc."Dealing Type"::Discount then
                                    DiscDocAmountLCY := DiscDocAmountLCY + AppliedAmountLCY
                                else
                                    CollDocAmountLCY := CollDocAmountLCY + AppliedAmountLCY;
                        end else
                            case true of
                                PostedCarteraDoc."Dealing Type" = PostedCarteraDoc."Dealing Type"::Discount:
                                    begin
                                        PostedBillGroup.Get(PostedCarteraDoc."Bill Gr./Pmt. Order No.");
                                        if PostedBillGroup.Factoring = PostedBillGroup.Factoring::Risked then
                                            DiscRiskFactAmountLCY := DiscRiskFactAmountLCY + AppliedAmountLCY
                                        else
                                            DiscUnriskFactAmountLCY := DiscUnriskFactAmountLCY + AppliedAmountLCY
                                    end;
                                else
                                    CollFactAmountLCY := CollFactAmountLCY + AppliedAmountLCY;
                            end;

                        UpdateReceivableCurrFact(
                          PostedCarteraDoc, AppliedAmountLCY, DocAmountLCY, RejDocAmountLCY, DiscDocAmountLCY, CollDocAmountLCY,
                          DiscRiskFactAmountLCY, DiscUnriskFactAmountLCY, CollFactAmountLCY);
                        if not Open then begin
                            if GenJnlLine."Document Type" <> GenJnlLine."Document Type"::Payment then
                                if PostedCarteraDoc.Status = ClosedCarteraDoc.Status::Rejected then
                                    PostedCarteraDoc.Redrawn := true;
                            PostedCarteraDoc.Status := PostedCarteraDoc.Status::Honored;
                            PostedCarteraDoc."Honored/Rejtd. at Date" := GenJnlLine."Posting Date";
                            PostedCarteraDoc."Remaining Amount" := 0;
                            PostedCarteraDoc."Remaining Amt. (LCY)" := 0;
                            "Document Status" := "Document Status"::Honored;
                            if PostedCarteraDoc.Redrawn then
                                "Document Status" := "Document Status"::Redrawn;
                            Modify();
                        end;
                        PostedCarteraDoc.Modify();
                    end;
                "Document Situation"::"Closed BG/PO", "Document Situation"::"Closed Documents":
                    begin
                        ClosedCarteraDoc.Get(ClosedCarteraDoc.Type::Receivable, "Entry No.");
                        ClosedCarteraDoc.TestField(Status, ClosedCarteraDoc.Status::Rejected);
                        ClosedCarteraDoc."Remaining Amount" := "Remaining Amount";
                        ClosedCarteraDoc."Remaining Amt. (LCY)" := "Remaining Amt. (LCY)";
                        if not Open then begin
                            if GenJnlLine."Document Type" <> GenJnlLine."Document Type"::Payment then begin
                                ClosedCarteraDoc.Redrawn := true;
                                ClosedCarteraDoc.Status := ClosedCarteraDoc.Status::Rejected;
                                "Document Status" := "Document Status"::Rejected;
                            end else
                                if "Remaining Amount" = 0 then begin
                                    ClosedCarteraDoc.Status := ClosedCarteraDoc.Status::Honored;
                                    "Document Status" := "Document Status"::Honored;
                                end;
                            ClosedCarteraDoc."Remaining Amount" := 0;
                            ClosedCarteraDoc."Remaining Amt. (LCY)" := 0;
                            ClosedCarteraDoc."Honored/Rejtd. at Date" := GenJnlLine."Posting Date";
                            if ClosedCarteraDoc.Redrawn then
                                "Document Status" := "Document Status"::Redrawn;
                            Modify();
                        end;
                        ClosedCarteraDoc.Modify();
                        Modify();
                        if (ClosedCarteraDoc."Document Type" = ClosedCarteraDoc."Document Type"::Bill) or
                           (ClosedCarteraDoc."Document Type" = ClosedCarteraDoc."Document Type"::Invoice)
                        then
                            RejDocAmountLCY := RejDocAmountLCY + AppliedAmountLCY;
                    end;
            end;
        end;
    end;

    procedure UpdatePayableDoc(var VendLedgEntry: Record "Vendor Ledger Entry"; var GenJnlLine: Record "Gen. Journal Line"; var DocAmountLCY: Decimal; AppliedAmountLCY: Decimal; var DocLock: Boolean; var CollDocAmountLCY: Decimal)
    var
        CarteraDoc: Record "Cartera Doc.";
        PostedCarteraDoc: Record "Posted Cartera Doc.";
        ClosedCarteraDoc: Record "Closed Cartera Doc.";
        CarteraDoc2: Record "Cartera Doc.";
        PostedCarteraDoc2: Record "Posted Cartera Doc.";
        ClosedCarteraDoc2: Record "Closed Cartera Doc.";
        Currency: Record Currency;
    begin
        with VendLedgEntry do begin
            if not DocLock then begin
                DocLock := true;
                CarteraDoc.LockTable();
                PostedCarteraDoc.LockTable();
                if CarteraDoc2.FindLast() then;
                if PostedCarteraDoc2.FindLast() then;
                if ClosedCarteraDoc2.FindLast() then;
                ClosedCarteraDoc.LockTable();
            end;
            if "Remaining Amount" = 0 then
                "Remaining Amt. (LCY)" := 0;
            if "Document Situation" <> "Document Situation"::Cartera then
                AppliedAmountLCY := Round(AppliedAmountLCY);
            case "Document Situation" of
                "Document Situation"::" ", "Document Situation"::Cartera:
                    begin
                        CarteraDoc.Get(CarteraDoc.Type::Payable, "Entry No.");
                        if CarteraDoc."Currency Code" = '' then
                            CarteraDoc."Remaining Amount" := CarteraDoc."Remaining Amount" - AppliedAmountLCY
                        else begin
                            Currency.Get(CarteraDoc."Currency Code");
                            Currency.InitRoundingPrecision();
                            CarteraDoc."Remaining Amount" :=
                              CarteraDoc."Remaining Amount" -
                              Round(AppliedAmountLCY * "Original Currency Factor", Currency."Amount Rounding Precision");
                        end;
                        CarteraDoc."Remaining Amt. (LCY)" :=
                          Round(CarteraDoc."Remaining Amount" / "Original Currency Factor", Currency."Amount Rounding Precision");

                        AppliedAmountLCY := Round(AppliedAmountLCY);
                        if CarteraDoc."Document Type" = CarteraDoc."Document Type"::Bill then
                            DocAmountLCY := DocAmountLCY + AppliedAmountLCY;
                        CarteraDoc.ResetNoPrinted();
                        if Open then begin
                            OnUpdatePayableDocBeforeCarteraDocModify(CarteraDoc, VendLedgEntry);
                            CarteraDoc.Modify();
                        end else begin
                            ClosedCarteraDoc.TransferFields(CarteraDoc);
                            ClosedCarteraDoc.Status := ClosedCarteraDoc.Status::Honored;
                            ClosedCarteraDoc."Honored/Rejtd. at Date" := GenJnlLine."Posting Date";
                            ClosedCarteraDoc."Bill Gr./Pmt. Order No." := '';
                            ClosedCarteraDoc."Remaining Amount" := 0;
                            ClosedCarteraDoc."Remaining Amt. (LCY)" := 0;
                            ClosedCarteraDoc."Amount for Collection" := 0;
                            ClosedCarteraDoc."Amt. for Collection (LCY)" := 0;
                            ClosedCarteraDoc.Insert();
                            CarteraDoc.Delete();
                            "Document Situation" := "Document Situation"::"Closed Documents";
                            "Document Status" := "Document Status"::Honored;
                            if "Document Type" <> "Document Type"::Invoice then
                                Modify();
                        end;
                    end;
                "Document Situation"::"Posted BG/PO":
                    begin
                        PostedCarteraDoc.Get(PostedCarteraDoc.Type::Payable, "Entry No.");
                        PostedCarteraDoc."Remaining Amount" := -"Remaining Amount";
                        PostedCarteraDoc."Remaining Amt. (LCY)" := -"Remaining Amt. (LCY)";
                        CollDocAmountLCY := CollDocAmountLCY + AppliedAmountLCY;
                        UpdatePayableCurrFact(PostedCarteraDoc, AppliedAmountLCY, DocAmountLCY, CollDocAmountLCY);
                        if not Open then begin
                            if PostedCarteraDoc.Status = ClosedCarteraDoc.Status::Rejected then
                                PostedCarteraDoc.Redrawn := true;
                            PostedCarteraDoc.Status := PostedCarteraDoc.Status::Honored;
                            PostedCarteraDoc."Honored/Rejtd. at Date" := GenJnlLine."Posting Date";
                            PostedCarteraDoc."Remaining Amount" := 0;
                            PostedCarteraDoc."Remaining Amt. (LCY)" := 0;
                            "Document Status" := "Document Status"::Honored;
                            Modify();
                        end;
                        PostedCarteraDoc.Modify();
                    end;
                "Document Situation"::"Closed BG/PO":
                    begin
                        ClosedCarteraDoc.Get(ClosedCarteraDoc.Type::Payable, "Entry No.");
                        ClosedCarteraDoc.TestField(Status, ClosedCarteraDoc.Status::Rejected);
                        ClosedCarteraDoc."Remaining Amount" := "Remaining Amount";
                        ClosedCarteraDoc."Remaining Amt. (LCY)" := "Remaining Amt. (LCY)";
                        if not Open then begin
                            if ClosedCarteraDoc.Status = PostedCarteraDoc.Status::Rejected then
                                ClosedCarteraDoc.Redrawn := true;
                            ClosedCarteraDoc.Status := ClosedCarteraDoc.Status::Honored;
                            ClosedCarteraDoc."Remaining Amount" := 0;
                            ClosedCarteraDoc."Remaining Amt. (LCY)" := 0;
                            ClosedCarteraDoc."Honored/Rejtd. at Date" := GenJnlLine."Posting Date";
                        end;
                        ClosedCarteraDoc.Modify();
                    end;
            end;
        end;
    end;

    procedure CheckAppliedReceivableDoc(var OldCustLedgEntry: Record "Cust. Ledger Entry"; SystemCreatedEntry: Boolean)
    begin
        if (OldCustLedgEntry."Document Situation" = OldCustLedgEntry."Document Situation"::"Posted BG/PO")
           and not SystemCreatedEntry
        then
            Error(
              Text1100006,
              OldCustLedgEntry."Document Type", OldCustLedgEntry."Document No.",
              OldCustLedgEntry."Bill No.");
    end;

    procedure CheckAppliedPayableDoc(var OldVendLedgEntry: Record "Vendor Ledger Entry"; SystemCreatedEntry: Boolean)
    begin
        if (OldVendLedgEntry."Document Situation" = OldVendLedgEntry."Document Situation"::"Posted BG/PO")
           and not SystemCreatedEntry
        then
            Error(
              Text1100007,
              OldVendLedgEntry."Document Type", OldVendLedgEntry."Document No.",
              OldVendLedgEntry."Bill No.");
    end;

    procedure CheckPostingDate(CheckDate: Date)
    var
        GLSetup: Record "General Ledger Setup";
        UserSetup: Record "User Setup";
        AllowPostingTo: Date;
        AllowPostingFrom: Date;
    begin
        GLSetup.Get();
        if UserId <> '' then
            if UserSetup.Get(UserId) then begin
                AllowPostingFrom := UserSetup."Allow Posting From";
                AllowPostingTo := UserSetup."Allow Posting To";
            end;
        if (AllowPostingFrom = 0D) and (AllowPostingTo = 0D) then begin
            AllowPostingFrom := GLSetup."Allow Posting From";
            AllowPostingTo := GLSetup."Allow Posting To";
        end;
        if AllowPostingTo = 0D then
            AllowPostingTo := 99991231D;
        if (CheckDate < AllowPostingFrom) or (CheckDate > AllowPostingTo) then
            Error(Text1100008,
              CheckDate);
    end;

    local procedure CheckCarteraDocsForBillGroups(CarteraDocType: Enum "Cartera Document Type"; DocumentNo: Code[20]; BillNo: Code[20])
    var
        CarteraDoc: Record "Cartera Doc.";
    begin
        CarteraDoc.Reset();
        CarteraDoc.SetCurrentKey(Type, "Document No.");
        CarteraDoc.SetRange(Type, CarteraDocType);
        CarteraDoc.SetRange("Document No.", DocumentNo);
        if BillNo <> '' then
            CarteraDoc.SetRange("No.", BillNo)
        else
            CarteraDoc.SetRange("Document Type", CarteraDoc."Document Type"::Invoice);
        CarteraDoc.SetFilter("Bill Gr./Pmt. Order No.", '<>%1', '');
        if CarteraDoc.FindFirst() then
            Error(
              CarteraDocBillGroupErr,
              CarteraDoc."Document No.", CarteraDoc."No.", CarteraDoc."Bill Gr./Pmt. Order No.");
    end;

    local procedure CheckPostedCarteraDocsForBillGroups(CarteraDocType: Enum "Cartera Document Type"; DocumentNo: Code[20]; BillNo: Code[20])
    var
        PostedCarteraDoc: Record "Posted Cartera Doc.";
    begin
        PostedCarteraDoc.Reset();
        PostedCarteraDoc.SetCurrentKey(Type, "Document No.");
        PostedCarteraDoc.SetRange(Type, CarteraDocType);
        PostedCarteraDoc.SetRange("Document No.", DocumentNo);
        if BillNo <> '' then
            PostedCarteraDoc.SetRange("No.", BillNo)
        else
            PostedCarteraDoc.SetRange("Document Type", PostedCarteraDoc."Document Type"::Invoice);
        PostedCarteraDoc.SetFilter("Bill Gr./Pmt. Order No.", '<>%1', '');
        if PostedCarteraDoc.FindFirst() then
            Error(
              CarteraDocBillGroupErr,
              PostedCarteraDoc."Document No.", PostedCarteraDoc."No.", PostedCarteraDoc."Bill Gr./Pmt. Order No.");
    end;

    procedure CloseBillGroupIfEmpty(PostedBillGroup: Record "Posted Bill Group"; PostingDate: Date)
    var
        PostedCarteraDoc: Record "Posted Cartera Doc.";
        ClosedCarteraDoc: Record "Closed Cartera Doc.";
        CustLedgEntry: Record "Cust. Ledger Entry";
        ClosedBillGroup: Record "Closed Bill Group";
    begin
        with PostedCarteraDoc do begin
            Reset();
            SetCurrentKey("Bill Gr./Pmt. Order No.", Status);
            SetRange("Bill Gr./Pmt. Order No.", PostedBillGroup."No.");
            SetRange(Type, Type::Receivable);
            SetRange(Status, Status::Open);
            OnCloseBillGroupIfEmptyOnAfterPostedCarteraDocSetFilter(PostedCarteraDoc);
            if not Find('-') then begin
                SetRange(Status);
                Find('-');
                repeat
                    ClosedCarteraDoc.TransferFields(PostedCarteraDoc);
                    ClosedCarteraDoc.Insert();
                    CustLedgEntry.Get(ClosedCarteraDoc."Entry No.");
                    CustLedgEntry."Document Situation" := CustLedgEntry."Document Situation"::"Closed BG/PO";
                    CustLedgEntry.Modify();
                until Next() = 0;
                DeleteAll();
                ClosedBillGroup.TransferFields(PostedBillGroup);
                ClosedBillGroup."Closing Date" := PostingDate;
                ClosedBillGroup.Insert();
                PostedBillGroup.Delete();
            end;
        end;
    end;

    procedure ClosePmtOrdIfEmpty(PostedPmtOrd: Record "Posted Payment Order"; PostingDate: Date)
    var
        PostedCarteraDoc: Record "Posted Cartera Doc.";
        ClosedCarteraDoc: Record "Closed Cartera Doc.";
        VendLedgEntry: Record "Vendor Ledger Entry";
        ClosedPmtOrd: Record "Closed Payment Order";
    begin
        with PostedCarteraDoc do begin
            Reset();
            SetCurrentKey("Bill Gr./Pmt. Order No.", Status);
            SetRange("Bill Gr./Pmt. Order No.", PostedPmtOrd."No.");
            SetRange(Type, Type::Payable);
            SetRange(Status, Status::Open);
            if not Find('-') then begin
                SetRange(Status);
                Find('-');
                repeat
                    ClosedCarteraDoc.TransferFields(PostedCarteraDoc);
                    ClosedCarteraDoc.Insert();
                    VendLedgEntry.Get(ClosedCarteraDoc."Entry No.");
                    VendLedgEntry."Document Situation" := VendLedgEntry."Document Situation"::"Closed BG/PO";
                    VendLedgEntry.Modify();
                until Next() = 0;
                DeleteAll();
                ClosedPmtOrd.TransferFields(PostedPmtOrd);
                ClosedPmtOrd."Closing Date" := PostingDate;
                ClosedPmtOrd.Insert();
                PostedPmtOrd.Delete();
            end;
        end;
    end;

    procedure CheckDocInfo(var GenJnlLine: Record "Gen. Journal Line"; var ErrorCounter: Integer; var ErrorText: array[50] of Text[250])
    var
        CarteraDoc: Record "Cartera Doc.";
        PaymentMethod: Record "Payment Method";
    begin
        with GenJnlLine do begin
            if ("Document Type" = "Document Type"::Bill) and
               (Amount <> 0)
            then begin
                if "Bill No." = '' then
                    AddError(
                      StrSubstNo(Text1100009, FieldCaption("Bill No.")),
                      ErrorCounter,
                      ErrorText);
                if "Due Date" = 0D then
                    AddError(
                      StrSubstNo(Text1100009, FieldCaption("Due Date")),
                      ErrorCounter,
                      ErrorText);
                if "Payment Method Code" = '' then
                    AddError(
                      StrSubstNo(Text1100009, FieldCaption("Payment Method Code")), ErrorCounter, ErrorText);
                PaymentMethod.Get("Payment Method Code");
                if not PaymentMethod."Create Bills" then
                    AddError(
                      StrSubstNo(Text1100010, FieldCaption("Payment Method Code")), ErrorCounter, ErrorText);
                if not ("Account Type" in ["Account Type"::Customer, "Account Type"::Vendor]) then
                    AddError(Text1100001, ErrorCounter, ErrorText);
            end;
            if ("Account Type" = "Account Type"::Customer) and
               ("Applies-to Doc. Type" = "Applies-to Doc. Type"::Bill) and
               not "System-Created Entry"
            then begin
                CarteraDoc.Reset();
                CarteraDoc.SetCurrentKey(Type, "Document No.");
                CarteraDoc.SetRange(Type, CarteraDoc.Type::Receivable);
                CarteraDoc.SetRange("Document No.", "Applies-to Doc. No.");
                CarteraDoc.SetRange("No.", "Applies-to Bill No.");
                if CarteraDoc.FindFirst() and (CarteraDoc."Bill Gr./Pmt. Order No." <> '') then
                    AddError(Text1100011, ErrorCounter, ErrorText);
            end;
        end;
    end;

    local procedure AddError(Text: Text[250]; var ErrorCounter: Integer; var ErrorText: array[50] of Text[250])
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := Text;
    end;

    procedure FindDisctdAmt(DocAmount: Decimal; CustomerNo: Code[20]; BankAccCode: Code[20]): Decimal
    var
        CustRating: Record "Customer Rating";
        BankAcc: Record "Bank Account";
    begin
        BankAcc.Get(BankAccCode);
        BankAcc.TestField("Customer Ratings Code");
        CustRating.Get(BankAcc."Customer Ratings Code", BankAcc."Currency Code", CustomerNo);
        CustRating.TestField("Risk Percentage");
        exit(DocAmount * CustRating."Risk Percentage" / 100);
    end;

    local procedure "Code"(var GenJnlLine: Record "Gen. Journal Line"; var PostOk: Boolean; Print: Boolean)
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlPostBatch: Codeunit "Gen. Jnl.-Post Batch";
        TempJnlBatchName: Code[10];
        GLReg: Record "G/L Register";
        IsHandled: Boolean;
    begin
        with GenJnlLine do begin
            GenJnlTemplate.Get("Journal Template Name");
            GenJnlTemplate.TestField("Force Posting Report", false);
            if GenJnlTemplate.Recurring and (GetFilter("Posting Date") <> '') then
                FieldError("Posting Date", Text1100012);

            if Print then begin
                if not Confirm(Text1100013, false) then
                    exit;
            end else begin
                if not Confirm(Text1100014, false) then
                    exit;
            end;

            TempJnlBatchName := "Journal Batch Name";

            if Print then begin
                GLReg.LockTable();
                if GLReg.FindLast() then;
            end;

            IsHandled := false;
            OnCodeOnBeforeGenJnlPostBatchRun(GenJnlLine, IsHandled);
            if not IsHandled then begin
                GenJnlPostBatch.Run(GenJnlLine);
                Clear(GenJnlPostBatch);

                if Print then begin
                    GLReg.SetRange("No.", GLReg."No." + 1, "Line No.");
                    if GLReg.Get("Line No.") then
                        REPORT.Run(GenJnlTemplate."Posting Report ID", false, false, GLReg);
                end;

                ShowPostResultMessage(GenJnlLine, PostOk, TempJnlBatchName);

                if not Find('=><') or (TempJnlBatchName <> "Journal Batch Name") then begin
                    Reset();
                    FilterGroup(2);
                    SetRange("Journal Template Name", "Journal Template Name");
                    SetRange("Journal Batch Name", "Journal Batch Name");
                    FilterGroup(0);
                    "Line No." := 1;
                end;
            end;
        end;
    end;

    local procedure ShowPostResultMessage(var GenJournalLine: Record "Gen. Journal Line"; var PostOk: Boolean; TempJnlBatchName: Code[10])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowPostResultMessage(GenJournalLine, PostOk, TempJnlBatchName, IsHandled);
        if IsHandled then
            exit;

        if GenJournalLine."Line No." = 0 then
            Message(JournalErrorsMgt.GetNothingToPostErrorMsg())
        else
            if TempJnlBatchName = GenJournalLine."Journal Batch Name" then begin
                Message(Text1100016);
                PostOk := true;
            end else
                Message(Text1100017, GenJournalLine."Journal Batch Name");
    end;

    procedure PostLines(var GenJnlLine2: Record "Gen. Journal Line"; var PostOk: Boolean; Print: Boolean)
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.Copy(GenJnlLine2);
        Code(GenJnlLine, PostOk, Print);
        GenJnlLine2.Copy(GenJnlLine);
    end;

    procedure PostSettlement(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalLineToPost: Record "Gen. Journal Line";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        UpdateAnalysisView: Codeunit "Update Analysis View";
    begin
        if GenJournalLine.FindSet() then
            repeat
                GenJournalLineToPost := GenJournalLine;
                GenJnlPostLine.SetFromSettlement(true);
                GenJnlPostLine.Run(GenJournalLineToPost);
            until GenJournalLine.Next() = 0;
        UpdateAnalysisView.UpdateAll(0, true);
    end;

    procedure PostSettlementForPostedPmtOrder(var GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date)
    var
        GenJournalLineToPost: Record "Gen. Journal Line";
        PostedPmtOrder: Record "Posted Payment Order";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        UpdateAnalysisView: Codeunit "Update Analysis View";
    begin
        if GenJournalLine.FindSet() then
            repeat
                GenJournalLineToPost := GenJournalLine;
                GenJnlPostLine.SetFromSettlement(true);
                GenJnlPostLine.Run(GenJournalLineToPost);
                if PostedPmtOrder.Get(GenJournalLine."Document No.") then
                    ClosePmtOrdIfEmpty(PostedPmtOrder, PostingDate);
            until GenJournalLine.Next() = 0;
        UpdateAnalysisView.UpdateAll(0, true);
    end;

    procedure PostSettlementForPostedBillGroup(var GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date)
    var
        GenJournalLineToPost: Record "Gen. Journal Line";
        PostedBillGroup: Record "Posted Bill Group";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        UpdateAnalysisView: Codeunit "Update Analysis View";
    begin
        if GenJournalLine.FindSet() then
            repeat
                GenJournalLineToPost := GenJournalLine;
                GenJnlPostLine.SetFromSettlement(true);
                GenJnlPostLine.Run(GenJournalLineToPost);
                if PostedBillGroup.Get(GenJournalLine."Document No.") then
                    CloseBillGroupIfEmpty(PostedBillGroup, PostingDate);
            until GenJournalLine.Next() = 0;
        UpdateAnalysisView.UpdateAll(0, true);
    end;

    procedure InsertDtldCustLedgEntry(CustLedgEntry2: Record "Cust. Ledger Entry"; Amount2: Decimal; Amount2LCY: Decimal; EntryType: Option " ","Initial Entry",Application,"Unrealized Loss","Unrealized Gain","Realized Loss","Realized Gain","Payment Discount","Payment Discount (VAT Excl.)","Payment Discount (VAT Adjustment)","Appln. Rounding","Correction of Remaining Amount",,,,,,,,,Settlement,Rejection,Redrawal,Expenses; PostingDate: Date)
    var
        DtldCVLedgEntryBuf: Record "Detailed Cust. Ledg. Entry";
        NextDtldBufferEntryNo: Integer;
    begin
        Clear(DtldCVLedgEntryBuf);
        DtldCVLedgEntryBuf.Reset();
        if DtldCVLedgEntryBuf.FindLast() then
            NextDtldBufferEntryNo := DtldCVLedgEntryBuf."Entry No." + 1
        else
            NextDtldBufferEntryNo := 1;

        CustLedgEntry2.CalcFields(Amount);
        DtldCVLedgEntryBuf.Init();
        DtldCVLedgEntryBuf."Entry No." := NextDtldBufferEntryNo;
        DtldCVLedgEntryBuf."Cust. Ledger Entry No." := CustLedgEntry2."Entry No.";
        DtldCVLedgEntryBuf."Entry Type" := "Detailed CV Ledger Entry Type".FromInteger(EntryType);
        case true of
            EntryType = EntryType::Rejection:
                DtldCVLedgEntryBuf."Excluded from calculation" := true;
            EntryType = EntryType::Redrawal:
                DtldCVLedgEntryBuf."Excluded from calculation" := true;
        end;
        DtldCVLedgEntryBuf."Posting Date" := PostingDate;
        DtldCVLedgEntryBuf."Initial Entry Due Date" := CustLedgEntry2."Due Date";
        DtldCVLedgEntryBuf."Document Type" := CustLedgEntry2."Document Type";
        DtldCVLedgEntryBuf."Document No." := CustLedgEntry2."Document No.";
        DtldCVLedgEntryBuf.Amount := Amount2;
        DtldCVLedgEntryBuf."Amount (LCY)" := Amount2LCY;
        DtldCVLedgEntryBuf."Customer No." := CustLedgEntry2."Customer No.";
        DtldCVLedgEntryBuf."Currency Code" := CustLedgEntry2."Currency Code";
        DtldCVLedgEntryBuf."User ID" := UserId;
        DtldCVLedgEntryBuf."Initial Entry Global Dim. 1" := CustLedgEntry2."Global Dimension 1 Code";
        DtldCVLedgEntryBuf."Initial Entry Global Dim. 2" := CustLedgEntry2."Global Dimension 2 Code";
        DtldCVLedgEntryBuf."Bill No." := CustLedgEntry2."Bill No.";
        DtldCVLedgEntryBuf.Insert(true);
    end;

    procedure InsertDtldVendLedgEntry(VendLedgEntry2: Record "Vendor Ledger Entry"; Amount2: Decimal; Amount2LCY: Decimal; EntryType: Option " ","Initial Entry",Application,"Unrealized Loss","Unrealized Gain","Realized Loss","Realized Gain","Payment Discount","Payment Discount (VAT Excl.)","Payment Discount (VAT Adjustment)","Appln. Rounding","Correction of Remaining Amount",,,,,,,,,Settlement,Rejection,Redrawal,Expenses; PostingDate: Date)
    var
        DtldCVLedgEntryBuf: Record "Detailed Vendor Ledg. Entry";
        NextDtldBufferEntryNo: Integer;
    begin
        Clear(DtldCVLedgEntryBuf);
        DtldCVLedgEntryBuf.Reset();
        if DtldCVLedgEntryBuf.FindLast() then
            NextDtldBufferEntryNo := DtldCVLedgEntryBuf."Entry No." + 1
        else
            NextDtldBufferEntryNo := 1;

        VendLedgEntry2.CalcFields(Amount);
        DtldCVLedgEntryBuf.Init();
        DtldCVLedgEntryBuf."Entry No." := NextDtldBufferEntryNo;
        DtldCVLedgEntryBuf."Vendor Ledger Entry No." := VendLedgEntry2."Entry No.";
        DtldCVLedgEntryBuf."Entry Type" := "Detailed CV Ledger Entry Type".FromInteger(EntryType);
        case true of
            EntryType = EntryType::Rejection:
                DtldCVLedgEntryBuf."Excluded from calculation" := true;
            EntryType = EntryType::Redrawal:
                DtldCVLedgEntryBuf."Excluded from calculation" := true;
        end;
        DtldCVLedgEntryBuf."Posting Date" := PostingDate;
        DtldCVLedgEntryBuf."Initial Entry Due Date" := VendLedgEntry2."Due Date";
        DtldCVLedgEntryBuf."Document Type" := VendLedgEntry2."Document Type";
        DtldCVLedgEntryBuf."Document No." := VendLedgEntry2."Document No.";
        DtldCVLedgEntryBuf.Amount := Amount2;
        DtldCVLedgEntryBuf."Amount (LCY)" := Amount2LCY;
        DtldCVLedgEntryBuf."Vendor No." := VendLedgEntry2."Vendor No.";
        DtldCVLedgEntryBuf."Currency Code" := VendLedgEntry2."Currency Code";
        DtldCVLedgEntryBuf."User ID" := UserId;
        DtldCVLedgEntryBuf."Initial Entry Global Dim. 1" := VendLedgEntry2."Global Dimension 1 Code";
        DtldCVLedgEntryBuf."Initial Entry Global Dim. 2" := VendLedgEntry2."Global Dimension 2 Code";
        DtldCVLedgEntryBuf."Bill No." := VendLedgEntry2."Bill No.";
        DtldCVLedgEntryBuf.Insert(true);
    end;

    procedure GetFCYAppliedAmt(AppliedAmountLCY: Decimal; CurrCode: Code[20]; PostingDate: Date): Decimal
    var
        CurrExchRate: Record "Currency Exchange Rate";
        GLSetup: Record "General Ledger Setup";
    begin
        if CurrCode <> '' then begin
            GLSetup.Get();
            exit(
              Round(
                CurrExchRate.ExchangeAmtLCYToFCY(
                  PostingDate,
                  CurrCode,
                  AppliedAmountLCY,
                  CurrExchRate.ExchangeRate(PostingDate, CurrCode)),
                GLSetup."Amount Rounding Precision"));
        end;
        exit(AppliedAmountLCY);
    end;

    procedure UpdateReceivableCurrFact(PostedCarteraDoc: Record "Posted Cartera Doc."; AppliedAmountLCY: Decimal; var DocAmountLCY: Decimal; var RejDocAmountLCY: Decimal; var DiscDocAmountLCY: Decimal; var CollDocAmountLCY: Decimal; var DiscRiskFactAmountLCY: Decimal; var DiscUnriskFactAmountLCY: Decimal; var CollFactAmountLCY: Decimal)
    var
        SalesInvHeader: Record "Sales Invoice Header";
        PostedBillGroup: Record "Posted Bill Group";
        CurrFact: Decimal;
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        if SalesInvHeader.Get(PostedCarteraDoc."Document No.") then
            if SalesInvHeader."Currency Factor" <> 0 then begin
                if PostedBillGroup.Get(PostedCarteraDoc."Bill Gr./Pmt. Order No.") then;
                CurrFact := CurrExchRate.ExchangeRate(PostedBillGroup."Posting Date", PostedCarteraDoc."Currency Code");
                if CurrFact <> SalesInvHeader."Currency Factor" then
                    if PostedCarteraDoc.Factoring = PostedCarteraDoc.Factoring::" " then begin
                        if PostedCarteraDoc.Status = PostedCarteraDoc.Status::Rejected then
                            DocAmountLCY :=
                              GetCorrectAmounts(RejDocAmountLCY, AppliedAmountLCY, CurrFact, SalesInvHeader."Currency Factor", PostedCarteraDoc)
                        else
                            if PostedCarteraDoc."Dealing Type" = PostedCarteraDoc."Dealing Type"::Discount then
                                DocAmountLCY :=
                                  GetCorrectAmounts(DiscDocAmountLCY, AppliedAmountLCY, CurrFact, SalesInvHeader."Currency Factor", PostedCarteraDoc)
                            else
                                DocAmountLCY :=
                                  GetCorrectAmounts(CollDocAmountLCY, AppliedAmountLCY, CurrFact, SalesInvHeader."Currency Factor", PostedCarteraDoc);
                    end else
                        case true of
                            PostedCarteraDoc."Dealing Type" = PostedCarteraDoc."Dealing Type"::Discount:
                                begin
                                    if PostedBillGroup.Get(PostedCarteraDoc."Bill Gr./Pmt. Order No.") then;
                                    if PostedBillGroup.Factoring = PostedBillGroup.Factoring::Risked then
                                        DocAmountLCY :=
                                          GetCorrectAmounts(
                                            DiscRiskFactAmountLCY, AppliedAmountLCY, CurrFact, SalesInvHeader."Currency Factor", PostedCarteraDoc)
                                    else
                                        DocAmountLCY :=
                                          GetCorrectAmounts(
                                            DiscUnriskFactAmountLCY, AppliedAmountLCY, CurrFact, SalesInvHeader."Currency Factor", PostedCarteraDoc)
                                end;
                            else
                                DocAmountLCY :=
                                  GetCorrectAmounts(CollFactAmountLCY, AppliedAmountLCY, CurrFact, SalesInvHeader."Currency Factor", PostedCarteraDoc)
                        end;
            end;
    end;

    procedure UpdatePayableCurrFact(PostedCarteraDoc: Record "Posted Cartera Doc."; AppliedAmountLCY: Decimal; var DocAmountLCY: Decimal; var CollDocAmountLCY: Decimal)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedPaymentOrder: Record "Posted Payment Order";
        CurrExchRate: Record "Currency Exchange Rate";
        CurrFact: Decimal;
    begin
        if PurchInvHeader.Get(PostedCarteraDoc."Document No.") then
            if PurchInvHeader."Currency Factor" <> 0 then begin
                if PostedPaymentOrder.Get(PostedCarteraDoc."Bill Gr./Pmt. Order No.") then;
                CurrFact := CurrExchRate.ExchangeRate(PostedPaymentOrder."Posting Date", PostedCarteraDoc."Currency Code");
                if CurrFact <> PurchInvHeader."Currency Factor" then
                    DocAmountLCY :=
                      GetCorrectAmounts(CollDocAmountLCY, AppliedAmountLCY, CurrFact, PurchInvHeader."Currency Factor", PostedCarteraDoc);
            end;
    end;

    procedure GetCorrectAmounts(var Amount: Decimal; AppliedAmountLCY: Decimal; CurrFact: Decimal; InvoiceCurrFact: Decimal; PostedCarteraDoc: Record "Posted Cartera Doc."): Decimal
    var
        AuxAmount: Decimal;
        AuxAmount2: Decimal;
    begin
        AuxAmount := Amount;
        Amount := Round(Round(AppliedAmountLCY * InvoiceCurrFact) / CurrFact);
        AuxAmount2 := AuxAmount - Amount;

        if PostedCarteraDoc.Adjusted xor PostedCarteraDoc.ReAdjusted then
            exit(0);
        if PostedCarteraDoc.ReAdjusted then begin
            Amount := Amount - PostedCarteraDoc."Adjusted Amount";
            exit(0);
        end;
        exit(AuxAmount2);
    end;

    procedure UpdateUnAppliedReceivableDoc(var CustLedgEntry: Record "Cust. Ledger Entry"; var GenJnlLine: Record "Gen. Journal Line")
    var
        CarteraDoc: Record "Cartera Doc.";
        PostedCarteraDoc: Record "Posted Cartera Doc.";
        ClosedCarteraDoc: Record "Closed Cartera Doc.";
        CarteraDoc2: Record "Cartera Doc.";
        ClosedCarteraDoc2: Record "Closed Cartera Doc.";
        DocLock: Boolean;
        Text1100101: Label ' Remove it from its bill group and try again.';
        Text1100102: Label '%1 cannot be unapplied, since it is included in a bill group.';
        InBillGroup: Boolean;
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        IsRejection: Boolean;
    begin
        with CustLedgEntry do begin
            InBillGroup := false;
            if CarteraDoc.Get(CarteraDoc.Type::Receivable, "Entry No.") then
                if CarteraDoc."Bill Gr./Pmt. Order No." <> '' then
                    InBillGroup := true;
            if PostedCarteraDoc.Get(PostedCarteraDoc.Type::Receivable, "Entry No.") then
                if PostedCarteraDoc."Bill Gr./Pmt. Order No." <> '' then
                    InBillGroup := true;
            if ClosedCarteraDoc.Get(ClosedCarteraDoc.Type::Receivable, "Entry No.") then
                if ClosedCarteraDoc."Bill Gr./Pmt. Order No." <> '' then
                    InBillGroup := true;
            if InBillGroup then
                Error(
                  Text1100102 +
                  Text1100101,
                  Description);
            CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
            if not DocLock then begin
                DocLock := true;
                CarteraDoc.LockTable();
                ClosedCarteraDoc.LockTable();
                if CarteraDoc2.FindLast() then;
                if ClosedCarteraDoc2.FindLast() then;
            end;
            if "Remaining Amount" = 0 then
                "Remaining Amt. (LCY)" := 0;
            case "Document Situation" of
                "Document Situation"::Cartera:
                    begin
                        CarteraDoc.Get(CarteraDoc.Type::Receivable, "Entry No.");
                        CarteraDoc."Remaining Amount" :=
                          CarteraDoc."Remaining Amount" + GetFCYAppliedAmt("Remaining Amt. (LCY)" - CarteraDoc."Remaining Amt. (LCY)",
                            CarteraDoc."Currency Code", GenJnlLine."Posting Date");
                        CarteraDoc."Remaining Amt. (LCY)" :=
                          CarteraDoc."Remaining Amt. (LCY)" + ("Remaining Amt. (LCY)" - CarteraDoc."Remaining Amt. (LCY)");
                        CarteraDoc.ResetNoPrinted();
                        if Open then begin
                            OnUpdateUnAppliedReceivableDocOnBeforeCarteraDocModify(CarteraDoc);
                            CarteraDoc.Modify();
                            OnUpdateUnAppliedReceivableDocOnAfterCarteraDocModify(CarteraDoc);
                        end;
                    end;
                "Document Situation"::"Closed Documents":
                    begin
                        ClosedCarteraDoc.Get(ClosedCarteraDoc.Type::Receivable, "Entry No.");
                        IsRejection := false;
                        DtldCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.", "Posting Date");
                        DtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", "Entry No.");
                        if DtldCustLedgEntry.Find('-') then
                            repeat
                                if DtldCustLedgEntry."Entry Type" = DtldCustLedgEntry."Entry Type"::Rejection then
                                    IsRejection := true;
                            until DtldCustLedgEntry.Next() = 0;

                        if Open then
                            if (IsRejection = true) and ("Remaining Amount" <> 0) then begin
                                ClosedCarteraDoc."Remaining Amount" :=
                                  ClosedCarteraDoc."Remaining Amount" + ("Remaining Amount" - ClosedCarteraDoc."Remaining Amount");
                                ClosedCarteraDoc."Remaining Amt. (LCY)" := ClosedCarteraDoc."Remaining Amt. (LCY)" +
                                  ("Remaining Amt. (LCY)" - ClosedCarteraDoc."Remaining Amt. (LCY)");
                                ClosedCarteraDoc.Status := ClosedCarteraDoc.Status::Rejected;
                                ClosedCarteraDoc.Modify();
                                "Document Situation" := "Document Situation"::"Closed Documents";
                                "Document Status" := "Document Status"::Rejected;
                                Modify();
                            end else begin
                                CarteraDoc.TransferFields(ClosedCarteraDoc);
                                CarteraDoc.Type := CarteraDoc.Type::Receivable;
                                CarteraDoc."Remaining Amount" := CarteraDoc."Remaining Amount" + "Remaining Amount";
                                CarteraDoc."Remaining Amt. (LCY)" := CarteraDoc."Remaining Amt. (LCY)" + "Remaining Amt. (LCY)";
                                OnUpdateUnAppliedReceivableDocOnBeforeCarteraDocInsert(CarteraDoc);
                                CarteraDoc.Insert();
                                OnUpdateUnAppliedReceivableDocOnAfterCarteraDocInsert(CarteraDoc);
                                ClosedCarteraDoc.Delete();
                                "Document Situation" := "Document Situation"::Cartera;
                                "Document Status" := "Document Status"::Open;
                                Modify();
                            end;
                        Modify();
                    end;
            end;
        end;
    end;

    procedure UpdateUnAppliedPayableDoc(var VendLedgEntry: Record "Vendor Ledger Entry"; var GenJnlLine: Record "Gen. Journal Line"; var DocLock: Boolean)
    var
        CarteraDoc: Record "Cartera Doc.";
        PostedCarteraDoc: Record "Posted Cartera Doc.";
        ClosedCarteraDoc: Record "Closed Cartera Doc.";
        CarteraDoc2: Record "Cartera Doc.";
        ClosedCarteraDoc2: Record "Closed Cartera Doc.";
        Text1100101: Label ' Remove it from its payment order and try again.';
        InBillGroup: Boolean;
        Text1100102: Label '%1 cannot be unapplied, since it is included in a payment order.';
    begin
        with VendLedgEntry do begin
            InBillGroup := false;
            if CarteraDoc.Get(CarteraDoc.Type::Payable, "Entry No.") then
                if CarteraDoc."Bill Gr./Pmt. Order No." <> '' then
                    InBillGroup := true;
            if PostedCarteraDoc.Get(PostedCarteraDoc.Type::Payable, "Entry No.") then
                if PostedCarteraDoc."Bill Gr./Pmt. Order No." <> '' then
                    InBillGroup := true;
            if ClosedCarteraDoc.Get(ClosedCarteraDoc.Type::Payable, "Entry No.") then
                if ClosedCarteraDoc."Bill Gr./Pmt. Order No." <> '' then
                    InBillGroup := true;
            if InBillGroup then
                Error(
                  Text1100102 +
                  Text1100101,
                  Description);
            CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
            if not DocLock then begin
                DocLock := true;
                CarteraDoc.LockTable();
                if CarteraDoc2.FindLast() then;
                if ClosedCarteraDoc2.FindLast() then;
                ClosedCarteraDoc.LockTable();
            end;
            if "Remaining Amount" = 0 then
                "Remaining Amt. (LCY)" := 0;
            case "Document Situation" of
                "Document Situation"::Cartera:
                    begin
                        CarteraDoc.Get(CarteraDoc.Type::Payable, "Entry No.");
                        CarteraDoc."Remaining Amount" :=
                          CarteraDoc."Remaining Amount" - GetFCYAppliedAmt("Remaining Amt. (LCY)" + CarteraDoc."Remaining Amt. (LCY)",
                            CarteraDoc."Currency Code", GenJnlLine."Posting Date");
                        CarteraDoc."Remaining Amt. (LCY)" :=
                          CarteraDoc."Remaining Amt. (LCY)" - ("Remaining Amt. (LCY)" + CarteraDoc."Remaining Amt. (LCY)");
                        CarteraDoc.ResetNoPrinted();
                        if Open then begin
                            OnUpdateUnAppliedPayableDocOnBeforeCarteraDocModify(CarteraDoc);
                            CarteraDoc.Modify();
                            OnUpdateUnAppliedPayableDocOnAfterCarteraDocModify(CarteraDoc);
                        end;
                    end;
                "Document Situation"::"Closed Documents":
                    begin
                        ClosedCarteraDoc.Get(ClosedCarteraDoc.Type::Payable, "Entry No.");
                        if Open then begin
                            CarteraDoc.TransferFields(ClosedCarteraDoc);
                            CarteraDoc.Type := CarteraDoc.Type::Payable;
                            CarteraDoc."Remaining Amount" := CarteraDoc."Remaining Amount" - "Remaining Amount";
                            CarteraDoc."Remaining Amt. (LCY)" := CarteraDoc."Remaining Amt. (LCY)" - "Remaining Amt. (LCY)";
                            OnUpdateUnAppliedPayableDocOnBeforeCarteraDocInsert(CarteraDoc);
                            CarteraDoc.Insert();
                            OnUpdateUnAppliedPayableDocOnAfterCarteraDocInsert(CarteraDoc);
                            ClosedCarteraDoc.Delete();
                            "Document Situation" := "Document Situation"::Cartera;
                            "Document Status" := "Document Status"::Open;
                            Modify();
                        end;
                        Modify();
                    end;
            end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckGenJnlLine(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateReceivableDoc(var CarteraDoc: Record "Cartera Doc."; GenJournalLine: Record "Gen. Journal Line"; var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreatePayableDoc(var CarteraDoc: Record "Cartera Doc."; GenJournalLine: Record "Gen. Journal Line"; var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateReceivableDoc(var CarteraDoc: Record "Cartera Doc."; GenJournalLine: Record "Gen. Journal Line"; var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePayableDoc(var CarteraDoc: Record "Cartera Doc."; GenJournalLine: Record "Gen. Journal Line"; var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowPostResultMessage(var GenJournalLine: Record "Gen. Journal Line"; var PostOk: Boolean; TempJnlBatchName: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCloseBillGroupIfEmptyOnAfterPostedCarteraDocSetFilter(var PostedCarteraDoc: Record "Posted Cartera Doc.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeGenJnlPostBatchRun(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateUnAppliedReceivableDocOnAfterCarteraDocModify(var CarteraDoc: Record "Cartera Doc.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateUnAppliedReceivableDocOnBeforeCarteraDocModify(var CarteraDoc: Record "Cartera Doc.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateUnAppliedReceivableDocOnAfterCarteraDocInsert(var CarteraDoc: Record "Cartera Doc.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateUnAppliedReceivableDocOnBeforeCarteraDocInsert(var CarteraDoc: Record "Cartera Doc.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateUnAppliedPayableDocOnAfterCarteraDocModify(var CarteraDoc: Record "Cartera Doc.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateUnAppliedPayableDocOnBeforeCarteraDocModify(var CarteraDoc: Record "Cartera Doc.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateUnAppliedPayableDocOnAfterCarteraDocInsert(var CarteraDoc: Record "Cartera Doc.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateUnAppliedPayableDocOnBeforeCarteraDocInsert(var CarteraDoc: Record "Cartera Doc.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdatePayableDocBeforeCarteraDocModify(var CarteraDoc: Record "Cartera Doc."; VendLedgEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateReceivableDoc(var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;
}

