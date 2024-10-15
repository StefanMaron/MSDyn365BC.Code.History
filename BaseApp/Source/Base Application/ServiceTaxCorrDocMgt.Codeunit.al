codeunit 11765 "Service Tax Corr. Doc Mgt."
{
    Permissions = TableData "Service Invoice Header" = im,
                  TableData "Service Invoice Line" = im,
                  TableData "Service Cr.Memo Header" = im,
                  TableData "Service Cr.Memo Line" = im;
    ObsoleteState = Pending;
    ObsoleteReason = 'The functionality of Tax corrective documents for VAT will be removed and this codeunit should not be used. (Obsolete::Removed in release 01.2021)';
    ObsoleteTag = '15.3';

    trigger OnRun()
    begin
    end;

    var
        TempServiceCrMemoLine: Record "Service Cr.Memo Line" temporary;
        TaxCorrDocumentMgt: Codeunit "Tax Corr. Document Mgt.";
        LastInsertedCrMemoNo: Code[20];
        AmountTotal: Decimal;
        RoundingDocumentTxt: Label 'Document Rounding';

    [Scope('OnPrem')]
    procedure ServiceLedgEntryExists(DocumentNo: Code[20]): Boolean
    var
        ServiceLedgEntry: Record "Service Ledger Entry";
    begin
        with ServiceLedgEntry do begin
            SetCurrentKey("Document No.", "Posting Date");
            SetRange("Document No.", DocumentNo);
            exit(not IsEmpty);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateCrMemoHeader(DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; SourceCVLedgEntryBuf: Record "CV Ledger Entry Buffer")
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        with ServiceCrMemoHeader do begin
            if not FillCrMemoHeader(SourceCVLedgEntryBuf, ServiceCrMemoHeader) then begin
                "Customer No." := DtldCVLedgEntryBuf."CV No.";
                "Bill-to Customer No." := DtldCVLedgEntryBuf."CV No.";
            end;
            "Pre-Assigned No." := DtldCVLedgEntryBuf."Document No.";
            "Applies-to Doc. Type" := SourceCVLedgEntryBuf."Document Type";
            "Applies-to Doc. No." := SourceCVLedgEntryBuf."Document No.";
            "Reason Code" := GetReasonCodeForPaymentDisc;
            "Currency Code" := '';
            "Currency Factor" := 0;
            InsertCrMemoHeader(ServiceCrMemoHeader, DtldCVLedgEntryBuf."Posting Date");

            InsertCrMemoLines("No.");
        end;
    end;

    local procedure FillCrMemoHeader(SourceCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var ServiceCrMemoHeader: Record "Service Cr.Memo Header"): Boolean
    var
        SourceServiceInvHeader: Record "Service Invoice Header";
        SourceServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        ServiceCrMemoHeader.Init();
        case SourceCVLedgEntryBuf."Document Type" of
            SourceCVLedgEntryBuf."Document Type"::Invoice:
                if SourceServiceInvHeader.Get(SourceCVLedgEntryBuf."Document No.") then begin
                    SourceServiceInvHeader."Bank Account Code" := '';
                    ServiceCrMemoHeader.TransferFields(SourceServiceInvHeader);
                end;
            SourceCVLedgEntryBuf."Document Type"::"Credit Memo":
                if SourceServiceCrMemoHeader.Get(SourceCVLedgEntryBuf."Document No.") then
                    ServiceCrMemoHeader.TransferFields(SourceServiceCrMemoHeader);
        end;
        exit(ServiceCrMemoHeader."Customer No." <> '');
    end;

    local procedure InsertCrMemoHeader(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; PostingDate: Date)
    begin
        with ServiceCrMemoHeader do begin
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
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
    begin
        TempServiceCrMemoLine.Reset();
        if TempServiceCrMemoLine.FindSet then
            repeat
                ServiceCrMemoLine := TempServiceCrMemoLine;
                ServiceCrMemoLine."Document No." := DocumentNo;
                ServiceCrMemoLine.Insert();
            until TempServiceCrMemoLine.Next = 0;
        TempServiceCrMemoLine.DeleteAll();
    end;

    local procedure InsertInvHeader(var ServiceInvHeader: Record "Service Invoice Header"; PostingDate: Date)
    begin
        with ServiceInvHeader do begin
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
        ServiceSetup: Record "Service Mgt. Setup";
        NoSeriesMgt: Codeunit NoSeriesManagement;
    begin
        ServiceSetup.Get();
        exit(NoSeriesMgt.GetNextNo(ServiceSetup."Posted Serv. Credit Memo Nos.", PostingDate, true));
    end;

    [Scope('OnPrem')]
    procedure CreateCrMemoLine(VATEntry: Record "VAT Entry"; OriginalInvoiceNo: Code[20])
    var
        NextLineNo: Integer;
    begin
        with TempServiceCrMemoLine do begin
            if FindLast then
                NextLineNo := "Line No."
            else
                TaxCorrDocumentMgt.AddTaxCorrDocDescToServCrMemo(
                  TempServiceCrMemoLine,
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
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        Cust: Record Customer;
        CustPostGroup: Record "Customer Posting Group";
        GLAccount: Record "G/L Account";
        NextLineNo: Integer;
    begin
        if not ServiceCrMemoHeader.Get(DocumentNo) then
            exit;

        ServiceCrMemoLine.SetRange("Document No.", ServiceCrMemoHeader."No.");
        if ServiceCrMemoLine.FindLast then
            NextLineNo := ServiceCrMemoLine."Line No.";

        NextLineNo += 10000;

        ServiceCrMemoHeader.TestField("Customer No.");
        Cust.Get(ServiceCrMemoHeader."Customer No.");

        Cust.TestField("Customer Posting Group");
        CustPostGroup.Get(Cust."Customer Posting Group");

        CustPostGroup.TestField("Invoice Rounding Account");
        GLAccount.Get(CustPostGroup."Invoice Rounding Account");

        with TempServiceCrMemoLine do begin
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
            "Shortcut Dimension 1 Code" := ServiceCrMemoHeader."Shortcut Dimension 1 Code";
            "Shortcut Dimension 2 Code" := ServiceCrMemoHeader."Shortcut Dimension 2 Code";
            "Dimension Set ID" := ServiceCrMemoHeader."Dimension Set ID";

            Insert;
        end;

        InsertCrMemoLines(DocumentNo);
    end;

    [Scope('OnPrem')]
    procedure CopyCrMemoToInvoice(DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; AppliedPmtDocNo: Code[20]): Boolean
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceInvHeader: Record "Service Invoice Header";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        ServiceInvLine: Record "Service Invoice Line";
    begin
        if not FindCrMemos(AppliedPmtDocNo, ServiceCrMemoHeader, true) then
            exit(false);

        ServiceCrMemoHeader.FindLast;
        repeat
            if CheckIfCrMemoWasUnapplBefore(ServiceCrMemoHeader."No.") then
                exit(true);

            ServiceInvHeader.TransferFields(ServiceCrMemoHeader);
            ServiceInvHeader."Applies-to Doc. No." := ServiceCrMemoHeader."No.";
            InsertInvHeader(ServiceInvHeader, DtldCustLedgEntry."Posting Date");

            ServiceCrMemoLine.SetRange("Document No.", ServiceCrMemoHeader."No.");
            if ServiceCrMemoLine.FindSet then
                repeat
                    ServiceInvLine.TransferFields(ServiceCrMemoLine);
                    ServiceInvLine."Document No." := ServiceInvHeader."No.";
                    ServiceInvLine.Insert();
                until ServiceCrMemoLine.Next = 0;
        until ServiceCrMemoHeader.Next(-1) = 0;

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
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        with CustLedgEntry do begin
            FindCrMemos(
              "Document No.",
              ServiceCrMemoHeader, "Document Type" in ["Document Type"::Payment, "Document Type"::Refund]);
            PAGE.Run(0, ServiceCrMemoHeader);
        end;
    end;

    local procedure FindCrMemos(DocumentNo: Code[20]; var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; FindFromPayment: Boolean): Boolean
    begin
        if FindFromPayment then
            ServiceCrMemoHeader.SetRange("Pre-Assigned No.", DocumentNo)
        else
            ServiceCrMemoHeader.SetRange("Applies-to Doc. No.", DocumentNo);
        exit(not ServiceCrMemoHeader.IsEmpty);
    end;

    [Scope('OnPrem')]
    procedure ShowPmtDiscInvoices(CustLedgEntry: Record "Cust. Ledger Entry")
    var
        ServiceInvHeader: Record "Service Invoice Header";
    begin
        with CustLedgEntry do begin
            FindInvoices(
              "Document No.",
              ServiceInvHeader, "Document Type" in ["Document Type"::Payment, "Document Type"::Refund]);
            PAGE.Run(0, ServiceInvHeader);
        end;
    end;

    local procedure FindInvoices(DocumentNo: Code[20]; var ServiceInvHeader: Record "Service Invoice Header"; FindFromPayment: Boolean): Boolean
    begin
        if FindFromPayment then
            ServiceInvHeader.SetRange("Pre-Assigned No.", DocumentNo)
        else
            ServiceInvHeader.SetRange("Applies-to Doc. No.", DocumentNo);
        exit(not ServiceInvHeader.IsEmpty);
    end;

    local procedure GetReasonCodeForPaymentDisc(): Code[10]
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        ServiceMgtSetup.Get();
        ServiceMgtSetup.TestField("Reason Code For Payment Disc.");
        exit(ServiceMgtSetup."Reason Code For Payment Disc.");
    end;

    local procedure CheckIfCrMemoWasUnapplBefore(CrMemoNo: Code[20]): Boolean
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        ServiceInvoiceHeader.SetRange("Applies-to Doc. No.", CrMemoNo);
        if ServiceInvoiceHeader.Count > 0 then
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

