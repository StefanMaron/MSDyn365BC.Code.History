codeunit 12101 "Withholding - Contribution"
{

    trigger OnRun()
    begin
    end;

    var
        MustBePaymentOrRefundTxt: Label 'must be Payment or Refund', Comment = 'This text will be added after Document Type';
        WithholdCodeLinesNotSpecifiedErr: Label 'You have not specified any withhold code lines for withhold code %1.';
        ContributionCodeLinesNotSpecifiedErr: Label 'You have not specified any contribution code lines for code %1.';
        ContributionBracketLinesNotSpecifiedErr: Label 'You have not specified any contribution bracket lines for code %1.';
        MultiApplyErr: Label 'To calculate taxes correctly, the payment must be applied to only one document.';

    procedure PostPayments(var TempWithholdingSocSec: Record "Tmp Withholding Contribution"; GenJnlLine: Record "Gen. Journal Line"; CalledFromVendBillLine: Boolean)
    var
        WithholdCode: Record "Withhold Code";
        ComputedWithholdingTax: Record "Computed Withholding Tax";
        ComputedSocialSec: Record "Computed Contribution";
        WithholdingTax: Record "Withholding Tax";
        SocialSecurity: Record Contributions;
        CurrencyExchRate: Record "Currency Exchange Rate";
        EntryNo: Integer;
        InsertRec: Boolean;
    begin
        with TempWithholdingSocSec do begin
            if WithholdApplicable(TempWithholdingSocSec, CalledFromVendBillLine) then begin
                if ComputedWithholdingTax.Get("Vendor No.", "Document Date", "Invoice No.") then begin
                    ComputedWithholdingTax."External Document No." := "External Document No.";

                    if "Currency Code" = ComputedWithholdingTax."Currency Code" then begin
                        ComputedWithholdingTax."Remaining Amount" := ComputedWithholdingTax."Remaining Amount" - "Total Amount";
                        ComputedWithholdingTax."Remaining - Excluded Amount" := ComputedWithholdingTax."Remaining - Excluded Amount" -
                          "Base - Excluded Amount";
                        ComputedWithholdingTax."Non Taxable Remaining Amount" := ComputedWithholdingTax."Non Taxable Remaining Amount" -
                          "Non Taxable Amount By Treaty";
                    end else begin
                        ComputedWithholdingTax."Remaining Amount" := ComputedWithholdingTax."Remaining Amount" -
                          CurrencyExchRate.ExchangeAmtFCYToFCY(GenJnlLine."Document Date", "Currency Code",
                            ComputedWithholdingTax."Currency Code", "Total Amount");
                        ComputedWithholdingTax."Remaining - Excluded Amount" := ComputedWithholdingTax."Remaining - Excluded Amount" -
                          CurrencyExchRate.ExchangeAmtFCYToFCY(GenJnlLine."Document Date", "Currency Code",
                            ComputedWithholdingTax."Currency Code", "Base - Excluded Amount");
                        ComputedWithholdingTax."Non Taxable Remaining Amount" := ComputedWithholdingTax."Non Taxable Remaining Amount" -
                          CurrencyExchRate.ExchangeAmtFCYToFCY(GenJnlLine."Document Date", "Currency Code",
                            ComputedWithholdingTax."Currency Code", "Non Taxable Amount By Treaty");
                    end;
                    ComputedWithholdingTax."Withholding Tax Code" := "Withholding Tax Code";
                    ComputedWithholdingTax."Related Date" := "Related Date";
                    ComputedWithholdingTax."Payment Date" := "Payment Date";
                    ComputedWithholdingTax.Modify();
                end;

                WithholdingTax.LockTable();
                if WithholdingTax.FindLast then
                    EntryNo := WithholdingTax."Entry No." + 1
                else
                    EntryNo := 1;

                WithholdingTax.Init();
                WithholdingTax."Entry No." := EntryNo;
                WithholdingTax.Month := Date2DMY(GenJnlLine."Posting Date", 2);
                WithholdingTax.Year := Date2DMY(GenJnlLine."Posting Date", 3);
                WithholdingTax."Document Date" := "Document Date";
                WithholdingTax."Document No." := GenJnlLine."Document No.";
                WithholdingTax."External Document No." := "External Document No.";
                WithholdingTax."Vendor No." := "Vendor No.";
                WithholdingTax."Related Date" := "Related Date";
                WithholdingTax."Posting Date" := GenJnlLine."Posting Date";
                WithholdingTax."Payment Date" := GenJnlLine."Posting Date";
                WithholdingTax."Withholding Tax Code" := "Withholding Tax Code";
                WithholdingTax."Withholding Tax %" := "Withholding Tax %";
                WithholdingTax."Non Taxable Amount %" := "Non Taxable %";
                WithholdingTax.Reason := Reason;
                if "Currency Code" = '' then begin
                    WithholdingTax."Total Amount" := "Total Amount";
                    WithholdingTax."Base - Excluded Amount" := "Base - Excluded Amount";
                    WithholdingTax."Non Taxable Amount By Treaty" := "Non Taxable Amount By Treaty";
                    WithholdingTax."Non Taxable Amount" := "Non Taxable Amount";
                    WithholdingTax."Taxable Base" := "Taxable Base";
                    WithholdingTax."Withholding Tax Amount" := "Withholding Tax Amount";
                end else begin
                    WithholdingTax."Total Amount" := Round(CurrencyExchRate.ExchangeAmtFCYToLCY(
                          GenJnlLine."Document Date", "Currency Code", "Total Amount", GenJnlLine."Currency Factor"));

                    WithholdingTax."Base - Excluded Amount" := Round(CurrencyExchRate.ExchangeAmtFCYToLCY(
                          GenJnlLine."Document Date", "Currency Code", "Base - Excluded Amount", GenJnlLine."Currency Factor"));

                    WithholdingTax."Non Taxable Amount By Treaty" := Round(CurrencyExchRate.ExchangeAmtFCYToLCY(
                          GenJnlLine."Document Date", "Currency Code", "Non Taxable Amount By Treaty", GenJnlLine."Currency Factor"));

                    WithholdingTax."Non Taxable Amount" := Round(CurrencyExchRate.ExchangeAmtFCYToLCY(
                          GenJnlLine."Document Date", "Currency Code", "Non Taxable Amount", GenJnlLine."Currency Factor"));

                    WithholdingTax."Taxable Base" := Round(CurrencyExchRate.ExchangeAmtFCYToLCY(
                          GenJnlLine."Document Date", "Currency Code", "Taxable Base", GenJnlLine."Currency Factor"));
                    WithholdingTax."Withholding Tax Amount" := Round(CurrencyExchRate.ExchangeAmtFCYToLCY(
                          GenJnlLine."Document Date", "Currency Code", "Withholding Tax Amount", GenJnlLine."Currency Factor"));
                end;
                if GenJnlLine."Document Type" = GenJnlLine."Document Type"::Refund then begin
                    WithholdingTax."Total Amount" := -WithholdingTax."Total Amount";
                    WithholdingTax."Base - Excluded Amount" := -WithholdingTax."Base - Excluded Amount";
                    WithholdingTax."Non Taxable Amount By Treaty" := -WithholdingTax."Non Taxable Amount By Treaty";
                    WithholdingTax."Non Taxable Amount" := -WithholdingTax."Non Taxable Amount";
                    WithholdingTax."Taxable Base" := -WithholdingTax."Taxable Base";
                    WithholdingTax."Withholding Tax Amount" := -WithholdingTax."Withholding Tax Amount";
                end;
                if WithholdCode.Get("Withholding Tax Code") then begin
                    WithholdingTax."Source-Withholding Tax" := WithholdCode."Source-Withholding Tax";
                    WithholdingTax."Recipient May Report Income" := WithholdCode."Recipient May Report Income";
                    WithholdingTax."Tax Code" := WithholdCode."Tax Code";
                end;

                OnBeforeWithholdingTaxInsert(WithholdingTax, TempWithholdingSocSec, GenJnlLine);
                WithholdingTax.Insert();

                if SocialSecurityApplicable(TempWithholdingSocSec, CalledFromVendBillLine) then
                    if ComputedSocialSec.Get("Vendor No.", "Document Date", "Invoice No.") then begin
                        ComputedSocialSec."External Document No." := "External Document No.";
                        ComputedSocialSec."Social Security Code" := "Social Security Code";
                        if "Currency Code" = ComputedSocialSec."Currency Code" then begin
                            ComputedSocialSec."Remaining Gross Amount" :=
                              ComputedSocialSec."Remaining Gross Amount" - "Gross Amount";
                            ComputedSocialSec."Remaining Soc.Sec. Non Taxable" := ComputedSocialSec."Remaining Soc.Sec. Non Taxable" -
                              "Soc.Sec.Non Taxable Amount";
                            ComputedSocialSec."Remaining Free-Lance Amount" := ComputedSocialSec."Remaining Free-Lance Amount" -
                              "Free-Lance Amount";
                        end else begin
                            ComputedSocialSec."Remaining Gross Amount" :=
                              ComputedSocialSec."Remaining Gross Amount" -
                              CurrencyExchRate.ExchangeAmtFCYToFCY(GenJnlLine."Document Date", "Currency Code",
                                ComputedSocialSec."Currency Code", "Gross Amount");
                            ComputedSocialSec."Remaining Soc.Sec. Non Taxable" :=
                              ComputedSocialSec."Remaining Soc.Sec. Non Taxable" -
                              CurrencyExchRate.ExchangeAmtFCYToFCY(GenJnlLine."Document Date", "Currency Code",
                                ComputedSocialSec."Currency Code", "Soc.Sec.Non Taxable Amount");
                            ComputedSocialSec."Remaining Free-Lance Amount" :=
                              ComputedSocialSec."Remaining Free-Lance Amount" -
                              CurrencyExchRate.ExchangeAmtFCYToFCY(GenJnlLine."Document Date", "Currency Code",
                                ComputedSocialSec."Currency Code", "Free-Lance Amount");
                        end;
                        ComputedSocialSec.Modify();
                    end;

                if ("INAIL Code" <> '') and
                   (("INAIL Payment Line" <> 0) or ("INAIL Company Payment Line" <> 0))
                then
                    if ComputedSocialSec.Get("Vendor No.", "Document Date", "Invoice No.") then begin
                        ComputedSocialSec."External Document No." := "External Document No.";
                        ComputedSocialSec."INAIL Code" := "INAIL Code";
                        if "Currency Code" = ComputedSocialSec."Currency Code" then begin
                            ComputedSocialSec."INAIL Remaining Gross Amount" :=
                              ComputedSocialSec."INAIL Remaining Gross Amount" - "INAIL Gross Amount";

                            ComputedSocialSec."INAIL Rem. Non Tax. Amount" := ComputedSocialSec."INAIL Rem. Non Tax. Amount" -
                              "INAIL Non Taxable Amount";

                            ComputedSocialSec."INAIL Rem. Free-Lance Amount" := ComputedSocialSec."INAIL Rem. Free-Lance Amount" -
                              "INAIL Free-Lance Amount";
                        end else begin
                            ComputedSocialSec."INAIL Remaining Gross Amount" :=
                              ComputedSocialSec."INAIL Remaining Gross Amount" -
                              CurrencyExchRate.ExchangeAmtFCYToFCY(GenJnlLine."Document Date", "Currency Code",
                                ComputedSocialSec."Currency Code", "INAIL Gross Amount");

                            ComputedSocialSec."INAIL Rem. Non Tax. Amount" :=
                              ComputedSocialSec."INAIL Rem. Non Tax. Amount" -
                              CurrencyExchRate.ExchangeAmtFCYToFCY(GenJnlLine."Document Date", "Currency Code",
                                ComputedSocialSec."Currency Code", "INAIL Non Taxable Amount");

                            ComputedSocialSec."INAIL Rem. Free-Lance Amount" :=
                              ComputedSocialSec."INAIL Rem. Free-Lance Amount" -
                              CurrencyExchRate.ExchangeAmtFCYToFCY(GenJnlLine."Document Date", "Currency Code",
                                ComputedSocialSec."Currency Code", "INAIL Free-Lance Amount");
                        end;
                        ComputedSocialSec.Modify();
                    end;
                InsertRec := false;
                // Insert INPS/INAIL values
                SocialSecurity.LockTable();
                if SocialSecurity.FindLast then
                    EntryNo := SocialSecurity."Entry No." + 1
                else
                    EntryNo := 1;
                SocialSecurity.Init();
                SocialSecurity."Entry No." := EntryNo;

                SocialSecurity.Month := Date2DMY(GenJnlLine."Posting Date", 2);
                SocialSecurity.Year := Date2DMY(GenJnlLine."Posting Date", 3);
                SocialSecurity."Document Date" := "Document Date";
                SocialSecurity."Document No." := GenJnlLine."Document No.";
                SocialSecurity."External Document No." := "External Document No.";
                SocialSecurity."Vendor No." := "Vendor No.";
                SocialSecurity."Related Date" := "Related Date";
                SocialSecurity."Payment Date" := GenJnlLine."Posting Date";
                SocialSecurity."Posting Date" := GenJnlLine."Posting Date";
                SocialSecurity.Reported := false;

                if SocialSecurityApplicable(TempWithholdingSocSec, CalledFromVendBillLine) then begin
                    InsertRec := true;
                    SocialSecurity."Social Security Code" := "Social Security Code";
                    SocialSecurity."Social Security %" := "Social Security %";
                    SocialSecurity."Free-Lance Amount %" := "Free-Lance %";

                    if "Currency Code" = '' then begin
                        SocialSecurity."Gross Amount" := "Gross Amount";
                        SocialSecurity."Non Taxable Amount" := "Soc.Sec.Non Taxable Amount";
                        SocialSecurity."Contribution Base" := "Contribution Base";
                        SocialSecurity."Total Social Security Amount" := "Total Social Security Amount";
                        SocialSecurity."Free-Lance Amount" := "Free-Lance Amount";
                        SocialSecurity."Company Amount" := "Company Amount";
                    end else begin
                        SocialSecurity."Gross Amount" :=
                          Round(CurrencyExchRate.ExchangeAmtFCYToLCY(
                              GenJnlLine."Document Date", "Currency Code", "Gross Amount", GenJnlLine."Currency Factor"));

                        SocialSecurity."Non Taxable Amount" :=
                          Round(CurrencyExchRate.ExchangeAmtFCYToLCY(
                              GenJnlLine."Document Date", "Currency Code", "Soc.Sec.Non Taxable Amount", GenJnlLine."Currency Factor"));

                        SocialSecurity."Contribution Base" :=
                          Round(CurrencyExchRate.ExchangeAmtFCYToLCY(
                              GenJnlLine."Document Date", "Currency Code", "Contribution Base", GenJnlLine."Currency Factor"));

                        SocialSecurity."Total Social Security Amount" :=
                          Round(CurrencyExchRate.ExchangeAmtFCYToLCY(
                              GenJnlLine."Document Date", "Currency Code", "Total Social Security Amount", GenJnlLine."Currency Factor"));

                        SocialSecurity."Free-Lance Amount" :=
                          Round(CurrencyExchRate.ExchangeAmtFCYToLCY(
                              GenJnlLine."Document Date", "Currency Code", "Free-Lance Amount", GenJnlLine."Currency Factor"));

                        SocialSecurity."Company Amount" :=
                          Round(CurrencyExchRate.ExchangeAmtFCYToLCY(
                              GenJnlLine."Document Date", "Currency Code", "Company Amount", GenJnlLine."Currency Factor"));
                    end;
                end;

                if ("INAIL Code" <> '') and (("INAIL Payment Line" <> 0) or ("INAIL Company Payment Line" <> 0)) then begin
                    InsertRec := true;
                    SocialSecurity."INAIL Code" := "INAIL Code";
                    SocialSecurity."INAIL Per Mil" := "INAIL Per Mil";
                    SocialSecurity."INAIL Free-Lance %" := "INAIL Free-Lance %";

                    if "Currency Code" = '' then begin
                        SocialSecurity."INAIL Gross Amount" := "INAIL Gross Amount";
                        SocialSecurity."INAIL Non Taxable Amount" := "INAIL Non Taxable Amount";
                        SocialSecurity."INAIL Contribution Base" := "INAIL Contribution Base";
                        SocialSecurity."INAIL Total Amount" := "INAIL Total Amount";
                        SocialSecurity."INAIL Free-Lance Amount" := "INAIL Free-Lance Amount";
                        SocialSecurity."INAIL Company Amount" := "INAIL Company Amount";
                    end else begin
                        SocialSecurity."INAIL Gross Amount" :=
                          Round(CurrencyExchRate.ExchangeAmtFCYToLCY(
                              GenJnlLine."Document Date", "Currency Code", "INAIL Gross Amount", GenJnlLine."Currency Factor"));

                        SocialSecurity."INAIL Non Taxable Amount" :=
                          Round(CurrencyExchRate.ExchangeAmtFCYToLCY(
                              GenJnlLine."Document Date", "Currency Code", "INAIL Non Taxable Amount", GenJnlLine."Currency Factor"));

                        SocialSecurity."INAIL Contribution Base" :=
                          Round(CurrencyExchRate.ExchangeAmtFCYToLCY(
                              GenJnlLine."Document Date", "Currency Code", "INAIL Contribution Base", GenJnlLine."Currency Factor"));
                        SocialSecurity."INAIL Total Amount" :=
                          Round(CurrencyExchRate.ExchangeAmtFCYToLCY(
                              GenJnlLine."Document Date", "Currency Code", "INAIL Total Amount", GenJnlLine."Currency Factor"));

                        SocialSecurity."INAIL Free-Lance Amount" :=
                          Round(CurrencyExchRate.ExchangeAmtFCYToLCY(
                              GenJnlLine."Document Date", "Currency Code", "INAIL Free-Lance Amount", GenJnlLine."Currency Factor"));

                        SocialSecurity."INAIL Company Amount" :=
                          Round(CurrencyExchRate.ExchangeAmtFCYToLCY(
                              GenJnlLine."Document Date", "Currency Code", "INAIL Company Amount", GenJnlLine."Currency Factor"));
                    end;
                end;
                if InsertRec then
                    SocialSecurity.Insert();
            end;
            if not CalledFromVendBillLine then
                Delete;
        end
    end;

    procedure CalculateWithholdingTax(var PurchHeader: Record "Purchase Header"; Recalculate: Boolean)
    var
        PurchWithSoc: Record "Purch. Withh. Contribution";
        PurchLine: Record "Purchase Line";
        TotalAmount: Decimal;
    begin
        PurchLine.Reset();
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetRange(Type, PurchLine.Type::"G/L Account");
        OnCalculateWithholdingTaxOnAfterPurchLineSetFilters(PurchLine, PurchHeader);

        TotalAmount := 0;
        if PurchLine.FindSet then
            repeat
                TotalAmount := TotalAmount + PurchLine."VAT Base Amount";
            until PurchLine.Next() = 0;

        if PurchWithSoc.Get(PurchHeader."Document Type", PurchHeader."No.") then
            if (PurchWithSoc."Total Amount" = 0) or
               Recalculate
            then begin
                OnCalculateWithholdingTaxOnRecalculate(PurchWithSoc, PurchHeader, TotalAmount);
                PurchWithSoc."Currency Code" := PurchHeader."Currency Code";
                PurchWithSoc.Validate("Total Amount", TotalAmount);
                PurchWithSoc.Modify();
            end;
    end;

    procedure CreateTmpWithhSocSec(var GenJnlLine: Record "Gen. Journal Line")
    var
        Vend: Record Vendor;
        ComputedWithholdingTax: Record "Computed Withholding Tax";
        ComputedSocSec: Record "Computed Contribution";
        CurrencyExchRate: Record "Currency Exchange Rate";
        TmpWithholdingSocSec: Record "Tmp Withholding Contribution";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        with GenJnlLine do begin
            if ("Document Type" <> "Document Type"::Payment) and
               ("Document Type" <> "Document Type"::Refund)
            then
                FieldError("Document Type", MustBePaymentOrRefundTxt);

            TestField("Account Type", "Account Type"::Vendor);
            TestField("Account No.");
            TestField("System-Created Entry", false);

            TmpWithholdingSocSec.Reset();

            if not TmpWithholdingSocSec.Get("Journal Template Name", "Journal Batch Name", "Line No.") then begin
                TmpWithholdingSocSec.Init();
                TmpWithholdingSocSec."Journal Template Name" := "Journal Template Name";
                TmpWithholdingSocSec."Journal Batch Name" := "Journal Batch Name";
                TmpWithholdingSocSec."Line No." := "Line No.";
                TmpWithholdingSocSec."Document Date" := "Document Date";
                if GenJnlLine."Applies-to ID" <> '' then begin
                    VendorLedgerEntry.SetRange("Vendor No.", GenJnlLine."Account No.");
                    VendorLedgerEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID");
                    VendorLedgerEntry.SetRange(Open, true);
                    VendorLedgerEntry.SetFilter(
                        "Document Type", '%1|%2',
                        VendorLedgerEntry."Document Type"::"Credit Memo", VendorLedgerEntry."Document Type"::Invoice);
                    if VendorLedgerEntry.Count() > 1 then
                        Error(MultiApplyErr);

                    if VendorLedgerEntry.FindFirst() then begin
                        VendorLedgerEntry.Validate("Applies-to ID", '');
                        Codeunit.Run(Codeunit::"Vend. Entry-Edit", VendorLedgerEntry);

                        GenJnlLine.Validate("Applies-to ID", '');
                        GenJnlLine.Validate("Applies-to Doc. Type", VendorLedgerEntry."Document Type");
                        GenJnlLine.Validate("Applies-to Doc. No.", VendorLedgerEntry."Document No.");
                        GenJnlLine.Validate("Applies-to Occurrence No.", VendorLedgerEntry."Document Occurrence");
                        GenJnlLine.Modify(true);
                    end;
                end;
                TmpWithholdingSocSec."Invoice No." := "Applies-to Doc. No.";
                TmpWithholdingSocSec."Vendor No." := "Account No.";
                TmpWithholdingSocSec."Old Withholding Amount" := 0;
                TmpWithholdingSocSec."Old Free-Lance Amount" := 0;
                TmpWithholdingSocSec."Payment Date" := "Document Date";
                TmpWithholdingSocSec."Currency Code" := "Currency Code";

                ComputedWithholdingTax.SetCurrentKey("Vendor No.", "Document Date", "Document No.");
                ComputedWithholdingTax.SetRange("Vendor No.", "Account No.");
                ComputedWithholdingTax.SetRange("Document No.", "Applies-to Doc. No.");

                if ComputedWithholdingTax.FindFirst then begin
                    TmpWithholdingSocSec."External Document No." := ComputedWithholdingTax."External Document No.";
                    TmpWithholdingSocSec."Related Date" := ComputedWithholdingTax."Related Date";
                    if ComputedWithholdingTax."Payment Date" <> 0D then
                        TmpWithholdingSocSec."Payment Date" := ComputedWithholdingTax."Payment Date";
                    TmpWithholdingSocSec."Withholding Tax Code" := ComputedWithholdingTax."Withholding Tax Code";

                    ComputedSocSec.SetCurrentKey("Vendor No.", "Document Date", "Document No.");
                    ComputedSocSec.SetRange("Vendor No.", "Account No.");
                    ComputedSocSec.SetRange("Document No.", "Applies-to Doc. No.");

                    if ComputedSocSec.FindFirst then
                        TmpWithholdingSocSec."Social Security Code" := ComputedSocSec."Social Security Code";
                    if ComputedSocSec.FindFirst then
                        TmpWithholdingSocSec."INAIL Code" := ComputedSocSec."INAIL Code";
                    if ComputedWithholdingTax."Currency Code" = "Currency Code" then begin
                        TmpWithholdingSocSec."Total Amount" := GetRemainingWithhTaxAmount(ComputedWithholdingTax, "Applies-to Occurrence No.");
                        TmpWithholdingSocSec."Base - Excluded Amount" := ComputedWithholdingTax."Remaining - Excluded Amount";
                        TmpWithholdingSocSec.Validate("Non Taxable Amount By Treaty", ComputedWithholdingTax."Non Taxable Remaining Amount");

                        if ComputedSocSec.FindFirst then begin
                            TmpWithholdingSocSec.Validate("Gross Amount", ComputedSocSec."Remaining Gross Amount");
                            TmpWithholdingSocSec.Validate("Soc.Sec.Non Taxable Amount", ComputedSocSec."Remaining Soc.Sec. Non Taxable");
                            TmpWithholdingSocSec.Validate("Free-Lance Amount", ComputedSocSec."Remaining Free-Lance Amount");
                            TmpWithholdingSocSec.Validate("INAIL Gross Amount", ComputedSocSec."INAIL Remaining Gross Amount");
                            TmpWithholdingSocSec.Validate("INAIL Non Taxable Amount", ComputedSocSec."INAIL Rem. Non Tax. Amount");
                            TmpWithholdingSocSec.Validate("INAIL Free-Lance Amount", ComputedSocSec."INAIL Rem. Free-Lance Amount");
                        end;
                    end else begin
                        TmpWithholdingSocSec."Total Amount" := CurrencyExchRate.ExchangeAmtFCYToFCY(
                            "Document Date",
                            ComputedWithholdingTax."Currency Code",
                            "Currency Code",
                            GetRemainingWithhTaxAmount(ComputedWithholdingTax, "Applies-to Occurrence No."));

                        TmpWithholdingSocSec."Base - Excluded Amount" := CurrencyExchRate.ExchangeAmtFCYToFCY(
                            "Document Date",
                            ComputedWithholdingTax."Currency Code",
                            "Currency Code",
                            ComputedWithholdingTax."Remaining - Excluded Amount");

                        TmpWithholdingSocSec.Validate("Non Taxable Amount By Treaty", CurrencyExchRate.ExchangeAmtFCYToFCY(
                            "Document Date",
                            ComputedWithholdingTax."Currency Code",
                            "Currency Code",
                            ComputedWithholdingTax."Non Taxable Remaining Amount"));

                        if ComputedSocSec.FindFirst then begin
                            TmpWithholdingSocSec.Validate("Gross Amount", CurrencyExchRate.ExchangeAmtFCYToFCY(
                                "Document Date",
                                ComputedWithholdingTax."Currency Code",
                                "Currency Code",
                                ComputedSocSec."Remaining Gross Amount"));

                            TmpWithholdingSocSec.Validate("Soc.Sec.Non Taxable Amount", CurrencyExchRate.ExchangeAmtFCYToFCY(
                                "Document Date",
                                ComputedWithholdingTax."Currency Code",
                                "Currency Code",
                                ComputedSocSec."Remaining Soc.Sec. Non Taxable"));

                            TmpWithholdingSocSec.Validate("Free-Lance Amount", CurrencyExchRate.ExchangeAmtFCYToFCY(
                                "Document Date",
                                ComputedWithholdingTax."Currency Code",
                                "Currency Code",
                                ComputedSocSec."Remaining Free-Lance Amount"));

                            TmpWithholdingSocSec.Validate("INAIL Gross Amount", CurrencyExchRate.ExchangeAmtFCYToFCY(
                                "Document Date",
                                ComputedWithholdingTax."Currency Code",
                                "Currency Code",
                                ComputedSocSec."INAIL Remaining Gross Amount"));

                            TmpWithholdingSocSec.Validate("INAIL Non Taxable Amount", CurrencyExchRate.ExchangeAmtFCYToFCY(
                                "Document Date",
                                ComputedWithholdingTax."Currency Code",
                                "Currency Code",
                                ComputedSocSec."INAIL Rem. Non Tax. Amount"));

                            TmpWithholdingSocSec.Validate("INAIL Free-Lance Amount", CurrencyExchRate.ExchangeAmtFCYToFCY(
                                "Document Date",
                                ComputedWithholdingTax."Currency Code",
                                "Currency Code",
                                ComputedSocSec."INAIL Rem. Free-Lance Amount"));
                        end;
                    end;
                end else begin
                    Vend.Get("Account No.");
                    TmpWithholdingSocSec."Social Security Code" := Vend."Social Security Code";
                    TmpWithholdingSocSec.Validate("Withholding Tax Code", Vend."Withholding Tax Code");
                    TmpWithholdingSocSec."INAIL Code" := Vend."INAIL Code";
                end;

                if ComputedWithholdingTax."WHT Amount Manual" <> 0 then
                    TmpWithholdingSocSec.Validate("Withholding Tax Amount", ComputedWithholdingTax."WHT Amount Manual");

                OnBeforeTmpWithholdingSocSecInsert(TmpWithholdingSocSec, ComputedWithholdingTax, GenJnlLine);
                TmpWithholdingSocSec.Insert();
            end;
        end;

        Commit();
        PAGE.RunModal(PAGE::"Show Computed Withh. Contrib.", TmpWithholdingSocSec);
    end;

    procedure WithholdLineFilter(var WithholdCodeLine: Record "Withhold Code Line"; WithholdCode: Code[20]; ValidityDate: Date)
    begin
        if ValidityDate = 0D then
            ValidityDate := WorkDate;

        WithholdCodeLine.Reset();
        WithholdCodeLine.SetRange("Withhold Code", WithholdCode);
        WithholdCodeLine.SetRange("Starting Date", 0D, ValidityDate);

        if WithholdCodeLine.FindLast then
            WithholdCodeLine.SetRange("Starting Date", WithholdCodeLine."Starting Date")
        else
            Error(WithholdCodeLinesNotSpecifiedErr, WithholdCode);
    end;

    procedure SetSocSecLineFilters(var SocSecCodeLine: Record "Contribution Code Line"; SocialSecurityCode: Code[20]; StartingDate: Date; TipoContributo: Option INPS,INAIL)
    begin
        if StartingDate = 0D then
            StartingDate := WorkDate;

        SocSecCodeLine.Reset();
        SocSecCodeLine.SetFilter("Contribution Type", '%1', TipoContributo);
        SocSecCodeLine.SetRange(Code, SocialSecurityCode);
        SocSecCodeLine.SetRange("Starting Date", 0D, StartingDate);

        if SocSecCodeLine.FindLast then
            SocSecCodeLine.SetRange("Starting Date", SocSecCodeLine."Starting Date")
        else
            Error(ContributionCodeLinesNotSpecifiedErr, SocialSecurityCode);
    end;

    [Obsolete('Replaced by SetSocSecLineFilters().', '17.0')]
    [Scope('OnPrem')]
    procedure SocSecLineFilter(var SocSecCodeLine: Record "Contribution Code Line"; SocialSecurityCode: Code[20]; StartingDate: Date; ContributionType: Option INPS,INAIL)
    begin
        SetSocSecLineFilters(SocSecCodeLine, SocialSecurityCode, StartingDate, ContributionType);
    end;

    procedure SetSocSecBracketFilters(var SocSecBracketLine: Record "Contribution Bracket Line"; SocialSecurityBracketCode: Code[10]; TipoContributo: Option INPS,INAIL; "Code": Code[20])
    begin
        SocSecBracketLine.Reset();
        SocSecBracketLine.SetFilter("Contribution Type", '%1', TipoContributo);
        SocSecBracketLine.SetRange(Code, SocialSecurityBracketCode);
        if not SocSecBracketLine.FindLast then
            Error(ContributionBracketLinesNotSpecifiedErr, SocialSecurityBracketCode, Code);
    end;

    [Obsolete('Replaced by SetSocSecBracketFilters()', '17.0')]
    [Scope('OnPrem')]
    procedure SocSecBracketFilter(var SocSecBracketLine: Record "Contribution Bracket Line"; SocialSecurityBracketCode: Code[10]; ContributionType: Option INPS,INAIL; "Code": Code[20])
    begin
        SetSocSecBracketFilters(SocSecBracketLine, SocialSecurityBracketCode, ContributionType, Code);
    end;

    procedure GetRemainingWithhTaxAmount(ComputedWithholdingTax: Record "Computed Withholding Tax"; AppliestoOccurrenceNo: Integer): Decimal
    var
        CreateVendLedgEntry: Record "Vendor Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        DtldVendLedgEntry1: Record "Detailed Vendor Ledg. Entry";
        DtldVendLedgEntry2: Record "Detailed Vendor Ledg. Entry";
        ComputedWithholdingTax1: Record "Computed Withholding Tax";
        RemainingWithhTaxAmount: Decimal;
    begin
        if CheckForMultipleInstallment(ComputedWithholdingTax."Document No.") then
            exit(GetInstallmentAmount(ComputedWithholdingTax, AppliestoOccurrenceNo));
        with VendLedgEntry do begin
            // Get the Vendor Ledger Entry that generates the ComputedWithholdingTax line
            Reset;
            SetRange("Document No.", ComputedWithholdingTax."Document No.");
            if FindFirst then
                CreateVendLedgEntry := VendLedgEntry;
            SetRange("Document No.");

            // Find applied entries;
            DtldVendLedgEntry1.SetCurrentKey("Vendor Ledger Entry No.");
            DtldVendLedgEntry1.SetRange("Vendor Ledger Entry No.", CreateVendLedgEntry."Entry No.");
            DtldVendLedgEntry1.SetRange(Unapplied, false);
            if DtldVendLedgEntry1.FindSet then
                repeat
                    if DtldVendLedgEntry1."Vendor Ledger Entry No." =
                       DtldVendLedgEntry1."Applied Vend. Ledger Entry No."
                    then begin
                        DtldVendLedgEntry2.Init();
                        DtldVendLedgEntry2.SetCurrentKey("Applied Vend. Ledger Entry No.", "Entry Type");
                        DtldVendLedgEntry2.SetRange(
                          "Applied Vend. Ledger Entry No.", DtldVendLedgEntry1."Applied Vend. Ledger Entry No.");
                        DtldVendLedgEntry2.SetRange("Entry Type", DtldVendLedgEntry2."Entry Type"::Application);
                        DtldVendLedgEntry2.SetRange(Unapplied, false);
                        if DtldVendLedgEntry2.FindSet then
                            repeat
                                if DtldVendLedgEntry2."Vendor Ledger Entry No." <>
                                   DtldVendLedgEntry2."Applied Vend. Ledger Entry No."
                                then begin
                                    SetCurrentKey("Entry No.");
                                    SetRange("Entry No.", DtldVendLedgEntry2."Vendor Ledger Entry No.");
                                    if FindFirst then
                                        Mark(true);
                                end;
                            until DtldVendLedgEntry2.Next() = 0;
                    end else begin
                        SetCurrentKey("Entry No.");
                        SetRange("Entry No.", DtldVendLedgEntry1."Applied Vend. Ledger Entry No.");
                        if FindFirst then
                            Mark(true);
                    end;
                until DtldVendLedgEntry1.Next() = 0;

            SetCurrentKey("Entry No.");
            SetRange("Entry No.");

            if CreateVendLedgEntry."Closed by Entry No." <> 0 then begin
                "Entry No." := CreateVendLedgEntry."Closed by Entry No.";
                Mark(true);
            end;

            SetCurrentKey("Closed by Entry No.");
            SetRange("Closed by Entry No.", CreateVendLedgEntry."Entry No.");
            if FindSet then
                repeat
                    Mark(true);
                until Next() = 0;

            SetCurrentKey("Entry No.");
            SetRange("Closed by Entry No.");
            MarkedOnly(true);

            // Calculate the RemainingWithhTaxAmount by substracting amount from its applied amount
            RemainingWithhTaxAmount := ComputedWithholdingTax."Remaining Amount";
            if FindSet then begin
                repeat
                    ComputedWithholdingTax1.Reset();
                    ComputedWithholdingTax1.SetRange("Document No.", "Document No.");
                    if ComputedWithholdingTax1.FindFirst then
                        RemainingWithhTaxAmount -= ComputedWithholdingTax1."Remaining Amount";
                until Next() = 0
            end;

            exit(RemainingWithhTaxAmount);
        end;
    end;

    procedure WithholdApplicable(TempWithholdingSocSec: Record "Tmp Withholding Contribution"; CalledFromVendBillLine: Boolean): Boolean
    begin
        if TempWithholdingSocSec."Withholding Tax Code" = '' then
            exit(false);
        if TempWithholdingSocSec."Non Taxable %" = 100 then
            exit(true);
        if not CalledFromVendBillLine then
            exit(TempWithholdingSocSec."Payment Line-Withholding" <> 0);
        exit(TempWithholdingSocSec."Withholding Tax Amount" <> 0);
    end;

    procedure SocialSecurityApplicable(TempWithholdingSocSec: Record "Tmp Withholding Contribution"; CalledFromVendBillLine: Boolean): Boolean
    begin
        with TempWithholdingSocSec do begin
            if not CalledFromVendBillLine then begin
                if ("Social Security Code" <> '') and
                   (("Payment Line-Soc. Sec." <> 0) or
                    ("Payment Line-Company" <> 0))
                then
                    exit(true)
            end else
                if ("Social Security Code" <> '') and
                   ("Total Social Security Amount" <> 0)
                then
                    exit(true)
        end;
        exit(false)
    end;

    procedure GetCompContribRemGrossAmtForVendorInPeriod(VendorNo: Code[20]; StartDate: Date; EndDate: Date): Decimal
    var
        ComputedContribution: Record "Computed Contribution";
    begin
        ComputedContribution.SetRange("Vendor No.", VendorNo);
        ComputedContribution.SetRange("Posting Date", StartDate, EndDate);
        ComputedContribution.CalcSums("Remaining Gross Amount");
        exit(ComputedContribution."Remaining Gross Amount");
    end;

    local procedure GetInstallmentAmount(ComputedWithholdingTax: Record "Computed Withholding Tax"; AppliestoOccurrenceNo: Integer): Decimal
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        TotalPaymentAmt: Decimal;
    begin
        with VendLedgEntry do begin
            SetCurrentKey("Document No.");
            SetRange("Document No.", ComputedWithholdingTax."Document No.");
            if FindSet then
                repeat
                    CalcFields(Amount);
                    TotalPaymentAmt := TotalPaymentAmt + Abs(Amount);
                until Next() = 0;
            if TotalPaymentAmt = 0 then
                exit(0);
            SetRange("Document Occurrence", AppliestoOccurrenceNo);
            if FindFirst then begin
                CalcFields("Remaining Amount");
                if "Remaining Amount" <> 0 then
                    exit(Abs(ComputedWithholdingTax."Total Amount" / TotalPaymentAmt * "Remaining Amount"));
            end;
        end;
    end;

    local procedure CheckForMultipleInstallment(DocumentNo: Code[20]): Boolean
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        with VendLedgEntry do begin
            SetCurrentKey("Document No.");
            SetRange("Document No.", DocumentNo);
            SetFilter("Document Occurrence", '>%1', 1);
            exit(not IsEmpty);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTmpWithholdingSocSecInsert(var TmpWithholdingContribution: Record "Tmp Withholding Contribution"; ComputedWithholdingTax: Record "Computed Withholding Tax"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWithholdingTaxInsert(var WithholdingTax: Record "Withholding Tax"; TmpWithholdingContribution: Record "Tmp Withholding Contribution"; GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateWithholdingTaxOnRecalculate(var PurchWithhContribution: Record "Purch. Withh. Contribution"; PurchaseHeader: Record "Purchase Header"; var TotAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateWithholdingTaxOnAfterPurchLineSetFilters(var PurchLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
    end;
}

