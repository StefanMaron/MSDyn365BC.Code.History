codeunit 11764 "Sales Tax Corr. Doc Mgt."
{
    Permissions = TableData "Sales Invoice Header" = im,
                  TableData "Sales Invoice Line" = im,
                  TableData "Sales Cr.Memo Header" = im,
                  TableData "Sales Cr.Memo Line" = im;
    ObsoleteState = Pending;
    ObsoleteReason = 'The functionality of Tax corrective documents for VAT will be removed and this codeunit should not be used. (Obsolete::Removed in release 01.2021)';
    ObsoleteTag = '15.3';

    trigger OnRun()
    begin
    end;

    var
        TempSalesCrMemoLine: Record "Sales Cr.Memo Line" temporary;
        TaxCorrDocumentMgt: Codeunit "Tax Corr. Document Mgt.";
        RoundingDocumentTxt: Label 'Document Rounding';
        LastInsertedCrMemoNo: Code[20];
        AmountTotal: Decimal;

    [Scope('OnPrem')]
    procedure CreateCrMemoHeader(DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; SourceCVLedgEntryBuf: Record "CV Ledger Entry Buffer")
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        with SalesCrMemoHeader do begin
            if not FillCrMemoHeader(SourceCVLedgEntryBuf, SalesCrMemoHeader) then begin
                "Sell-to Customer No." := DtldCVLedgEntryBuf."CV No.";
                "Bill-to Customer No." := DtldCVLedgEntryBuf."CV No.";
            end;
            "Pre-Assigned No." := DtldCVLedgEntryBuf."Document No.";
            "External Document No." := SourceCVLedgEntryBuf."Document No.";
            "Applies-to Doc. Type" := SourceCVLedgEntryBuf."Document Type";
            "Applies-to Doc. No." := SourceCVLedgEntryBuf."Document No.";
            "Reason Code" := GetReasonCodeForPaymentDisc;
            "Currency Code" := '';
            "Currency Factor" := 0;
            InsertCrMemoHeader(SalesCrMemoHeader, DtldCVLedgEntryBuf."Posting Date");

            InsertCrMemoLines("No.");
        end;
    end;

    local procedure FillCrMemoHeader(SourceCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"): Boolean
    var
        SourceSalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SourceSalesInvHeader: Record "Sales Invoice Header";
    begin
        SalesCrMemoHeader.Init;
        case SourceCVLedgEntryBuf."Document Type" of
            SourceCVLedgEntryBuf."Document Type"::Invoice:
                if SourceSalesInvHeader.Get(SourceCVLedgEntryBuf."Document No.") then begin
                    SourceSalesInvHeader."Bank Account Code" := '';
                    SalesCrMemoHeader.TransferFields(SourceSalesInvHeader);
                end;
            SourceCVLedgEntryBuf."Document Type"::"Credit Memo":
                if SourceSalesCrMemoHeader.Get(SourceCVLedgEntryBuf."Document No.") then
                    SalesCrMemoHeader.TransferFields(SourceSalesCrMemoHeader);
        end;
        exit(SalesCrMemoHeader."Sell-to Customer No." <> '');
    end;

    local procedure InsertCrMemoHeader(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; PostingDate: Date)
    begin
        with SalesCrMemoHeader do begin
            "No." := GetNextNo(PostingDate);
            "Posting Date" := PostingDate;
            "Document Date" := PostingDate;
            "VAT Date" := PostingDate;
            "User ID" := UserId;
            Insert;

            LastInsertedCrMemoNo := "No.";
        end;
    end;

    local procedure InsertCrMemoLines(DocumentNo: Code[20])
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        TempSalesCrMemoLine.Reset;
        if TempSalesCrMemoLine.FindSet then
            repeat
                SalesCrMemoLine := TempSalesCrMemoLine;
                SalesCrMemoLine."Document No." := DocumentNo;
                SalesCrMemoHeader.Get(DocumentNo);
                SalesCrMemoLine."Sell-to Customer No." := SalesCrMemoHeader."Sell-to Customer No.";
                SalesCrMemoLine."Bill-to Customer No." := SalesCrMemoHeader."Bill-to Customer No.";
                SalesCrMemoLine."Posting Date" := SalesCrMemoHeader."Posting Date";
                SalesCrMemoLine.Insert;
            until TempSalesCrMemoLine.Next = 0;
        TempSalesCrMemoLine.DeleteAll;
    end;

    local procedure InsertInvHeader(var SalesInvHeader: Record "Sales Invoice Header"; PostingDate: Date)
    begin
        with SalesInvHeader do begin
            "Tax Corrective Document" := true;
            "No." := GetNextNo(PostingDate);
            "Posting Date" := PostingDate;
            "Document Date" := PostingDate;
            "VAT Date" := PostingDate;
            "User ID" := UserId;
            Insert;
        end;
    end;

    local procedure GetNextNo(PostingDate: Date): Code[20]
    var
        SalesSetup: Record "Sales & Receivables Setup";
        NoSeriesMgt: Codeunit NoSeriesManagement;
    begin
        SalesSetup.Get;
        SalesSetup.TestField("Pmt.Disc.Tax Corr.Doc. Nos.");
        exit(NoSeriesMgt.GetNextNo(SalesSetup."Pmt.Disc.Tax Corr.Doc. Nos.", PostingDate, true));
    end;

    [Scope('OnPrem')]
    procedure CreateCrMemoLine(VATEntry: Record "VAT Entry"; OriginalInvoiceNo: Code[20])
    var
        NextLineNo: Integer;
    begin
        with TempSalesCrMemoLine do begin
            if FindLast then
                NextLineNo := "Line No."
            else
                TaxCorrDocumentMgt.AddTaxCorrDocDescToSalesCrMemo(
                  TempSalesCrMemoLine,
                  NextLineNo);

            NextLineNo := NextLineNo + 10000;

            Init;
            "Line No." := NextLineNo;
            "Gen. Bus. Posting Group" := VATEntry."Gen. Bus. Posting Group";
            "Gen. Prod. Posting Group" := VATEntry."Gen. Prod. Posting Group";
            Type := Type::"G/L Account";
            "No." := GetPmtDiscAccNo("Gen. Bus. Posting Group", "Gen. Prod. Posting Group", VATEntry.Base >= 0);
            Description := OriginalInvoiceNo;
            Quantity := 1;
            "Qty. per Unit of Measure" := 1;
            "Quantity (Base)" := Quantity;
            "Unit Price" := VATEntry.Base;
            "Line Amount" := VATEntry.Base;
            Amount := VATEntry.Base;
            "Amount Including VAT" := VATEntry.Base + VATEntry.Amount;
            "VAT Base Amount" := VATEntry.Base;
            "VAT Calculation Type" := VATEntry."VAT Calculation Type";
            "VAT Bus. Posting Group" := VATEntry."VAT Bus. Posting Group";
            "VAT Prod. Posting Group" := VATEntry."VAT Prod. Posting Group";
            "VAT %" := GetVATPct("VAT Bus. Posting Group", "VAT Prod. Posting Group");
            "VAT Identifier" := TaxCorrDocumentMgt.GetVATIdentifier(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group");
            "Shortcut Dimension 1 Code" := VATEntry."Global Dimension 1 Code";
            "Shortcut Dimension 2 Code" := VATEntry."Global Dimension 2 Code";
            "Dimension Set ID" := VATEntry."Dimension Set ID";

            Insert;

            AmountTotal += "Amount Including VAT";
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateCrMemoRounding(DocumentNo: Code[20]; RoundingAmt: Decimal)
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        Cust: Record Customer;
        CustPostGroup: Record "Customer Posting Group";
        GLAccount: Record "G/L Account";
        NextLineNo: Integer;
    begin
        if not SalesCrMemoHeader.Get(DocumentNo) then
            exit;

        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        if SalesCrMemoLine.FindLast then
            NextLineNo := SalesCrMemoLine."Line No.";

        NextLineNo += 10000;

        SalesCrMemoHeader.TestField("Sell-to Customer No.");
        Cust.Get(SalesCrMemoHeader."Sell-to Customer No.");

        Cust.TestField("Customer Posting Group");
        CustPostGroup.Get(Cust."Customer Posting Group");

        CustPostGroup.TestField("Invoice Rounding Account");
        GLAccount.Get(CustPostGroup."Invoice Rounding Account");

        with TempSalesCrMemoLine do begin
            Init;
            "Line No." := NextLineNo;
            "Gen. Bus. Posting Group" := Cust."Gen. Bus. Posting Group";
            "Gen. Prod. Posting Group" := GLAccount."Gen. Prod. Posting Group";
            Type := Type::"G/L Account";
            "No." := GLAccount."No.";
            Description := RoundingDocumentTxt;
            Quantity := 1;
            "Qty. per Unit of Measure" := 1;
            "Quantity (Base)" := Quantity;
            "Unit Price" := RoundingAmt;
            "Line Amount" := RoundingAmt;
            Amount := RoundingAmt;
            "Amount Including VAT" := RoundingAmt;
            "VAT Base Amount" := RoundingAmt;
            "VAT Bus. Posting Group" := Cust."VAT Bus. Posting Group";
            "VAT Prod. Posting Group" := GLAccount."VAT Prod. Posting Group";
            "VAT %" := GetVATPct("VAT Bus. Posting Group", "VAT Prod. Posting Group");
            "VAT Calculation Type" := TaxCorrDocumentMgt.GetVATCalculationType("VAT Bus. Posting Group", "VAT Prod. Posting Group");
            "VAT Identifier" := TaxCorrDocumentMgt.GetVATIdentifier("VAT Bus. Posting Group", "VAT Prod. Posting Group");
            "Shortcut Dimension 1 Code" := SalesCrMemoHeader."Shortcut Dimension 1 Code";
            "Shortcut Dimension 2 Code" := SalesCrMemoHeader."Shortcut Dimension 2 Code";
            "Dimension Set ID" := SalesCrMemoHeader."Dimension Set ID";

            Insert;
        end;

        InsertCrMemoLines(DocumentNo);
    end;

    [Scope('OnPrem')]
    procedure CopyCrMemoToInvoice(DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; AppliedPmtDocNo: Code[20]): Boolean
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        SalesInvLine: Record "Sales Invoice Line";
    begin
        if not FindCrMemos(DtldCustLedgEntry."Customer No.", AppliedPmtDocNo, SalesCrMemoHeader, true) then
            exit(false);

        SalesCrMemoHeader.FindLast;
        repeat
            if CheckIfCrMemoWasUnapplBefore(SalesCrMemoHeader."No.") then
                exit(true);

            SalesInvHeader.TransferFields(SalesCrMemoHeader);
            SalesInvHeader."Applies-to Doc. No." := SalesCrMemoHeader."No.";
            InsertInvHeader(SalesInvHeader, DtldCustLedgEntry."Posting Date");

            SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
            if SalesCrMemoLine.FindSet then
                repeat
                    SalesInvLine.TransferFields(SalesCrMemoLine);
                    SalesInvLine."Document No." := SalesInvHeader."No.";
                    SalesInvLine.Insert;
                until SalesCrMemoLine.Next = 0;
        until SalesCrMemoHeader.Next(-1) = 0;

        exit(true);
    end;

    local procedure GetPmtDiscAccNo(GenBusPostingGr: Code[20]; GenProdPostingGr: Code[20]; Debit: Boolean): Code[20]
    var
        GenPostingSetup: Record "General Posting Setup";
    begin
        GenPostingSetup.Get(GenBusPostingGr, GenProdPostingGr);
        if Debit then begin
            GenPostingSetup.TestField("Sales Pmt. Disc. Debit Acc.");
            exit(GenPostingSetup."Sales Pmt. Disc. Debit Acc.");
        end;
        GenPostingSetup.TestField("Sales Pmt. Disc. Credit Acc.");
        exit(GenPostingSetup."Sales Pmt. Disc. Credit Acc.");
    end;

    [Scope('OnPrem')]
    procedure GetVATPct(VATBusPostingGr: Code[20]; VATProdPostingGr: Code[20]): Decimal
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Get(VATBusPostingGr, VATProdPostingGr);
        exit(VATPostingSetup."VAT %");
    end;

    [Scope('OnPrem')]
    procedure ShowPmtDiscCrMemos(CustLedgEntry: Record "Cust. Ledger Entry")
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        with CustLedgEntry do begin
            FindCrMemos(
              "Customer No.", "Document No.", SalesCrMemoHeader,
              "Document Type" in ["Document Type"::Payment, "Document Type"::Refund]);
            PAGE.Run(0, SalesCrMemoHeader);
        end;
    end;

    local procedure FindCrMemos(CustomerNo: Code[20]; DocumentNo: Code[20]; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; FindFromPayment: Boolean): Boolean
    begin
        if FindFromPayment then begin
            SalesCrMemoHeader.SetCurrentKey("Pre-Assigned No.");
            SalesCrMemoHeader.SetRange("Pre-Assigned No.", DocumentNo);
        end else begin
            SalesCrMemoHeader.SetCurrentKey("Sell-to Customer No.", "External Document No.");
            SalesCrMemoHeader.SetRange("Sell-to Customer No.", CustomerNo);
            SalesCrMemoHeader.SetRange("External Document No.", DocumentNo)
        end;
        exit(not SalesCrMemoHeader.IsEmpty);
    end;

    [Scope('OnPrem')]
    procedure ShowPmtDiscInvoices(CustLedgEntry: Record "Cust. Ledger Entry")
    var
        SalesInvHeader: Record "Sales Invoice Header";
    begin
        with CustLedgEntry do begin
            FindInvoices(
              "Customer No.", "Document No.",
              SalesInvHeader, "Document Type" in ["Document Type"::Payment, "Document Type"::Refund]);
            PAGE.Run(0, SalesInvHeader);
        end;
    end;

    local procedure FindInvoices(CustomerNo: Code[20]; DocumentNo: Code[20]; var SalesInvHeader: Record "Sales Invoice Header"; FindFromPayment: Boolean): Boolean
    begin
        if FindFromPayment then begin
            SalesInvHeader.SetCurrentKey("Pre-Assigned No.");
            SalesInvHeader.SetRange("Pre-Assigned No.", DocumentNo);
        end else begin
            SalesInvHeader.SetCurrentKey("Sell-to Customer No.", "External Document No.");
            SalesInvHeader.SetRange("Sell-to Customer No.", CustomerNo);
            SalesInvHeader.SetRange("External Document No.", DocumentNo)
        end;
        exit(not SalesInvHeader.IsEmpty);
    end;

    local procedure GetReasonCodeForPaymentDisc(): Code[10]
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get;
        SalesReceivablesSetup.TestField("Reason Code For Payment Disc.");
        exit(SalesReceivablesSetup."Reason Code For Payment Disc.");
    end;

    local procedure CheckIfCrMemoWasUnapplBefore(CrMemoNo: Code[20]): Boolean
    var
        SalesInvHeader: Record "Sales Invoice Header";
    begin
        SalesInvHeader.SetRange("Applies-to Doc. No.", CrMemoNo);
        if SalesInvHeader.Count > 0 then
            exit(true);

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure GetLastInsertedCrMemoNo(): Code[20]
    begin
        exit(LastInsertedCrMemoNo);
    end;

    [Scope('OnPrem')]
    procedure GetInsertedAmountTotal(): Decimal
    begin
        exit(AmountTotal);
    end;
}

