codeunit 11763 "Tax Corr. Document Mgt."
{
    ObsoleteState = Pending;
    ObsoleteReason = 'The functionality of Tax corrective documents for VAT will be removed and this codeunit should not be used. (Obsolete::Removed in release 01.2021)';
    ObsoleteTag = '15.3';

    trigger OnRun()
    begin
    end;

    var
        TextTaxDocTxt: Label 'Tax Document No. %1';
        TextVATBaseTxt: Label ' Base - %1';
        TextVATAmtTxt: Label ' Amount - %1';
        TextAmtIncVATTxt: Label ' Amount incl. VAT - %1';
        TextPayDiscTxt: Label 'A payment discount for Tax Document No.';
        GLSetup: Record "General Ledger Setup";
        TempVATEntry: Record "VAT Entry" temporary;
        SalesTaxCorrDocMgt: Codeunit "Sales Tax Corr. Doc Mgt.";
        ServiceTaxCorrDocMgt: Codeunit "Service Tax Corr. Doc Mgt.";
        SourceIsServiceDoc: Boolean;
        GLSetupRead: Boolean;
        FormatStrTxt: Label '<Precision,%1><Standard Format,0>', Locked = true;

    [Scope('OnPrem')]
    procedure Init(DocumentNo: Code[20])
    begin
        SourceIsServiceDoc := ServiceTaxCorrDocMgt.ServiceLedgEntryExists(DocumentNo);
        ClearVATEntryBuffer;
    end;

    [Scope('OnPrem')]
    procedure CreateDocHeader(DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; SourceCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; DocumentNo: Code[20])
    begin
        DtldCVLedgEntryBuf."Document No." := DocumentNo;

        if SourceIsServiceDoc then
            ServiceTaxCorrDocMgt.CreateCrMemoHeader(DtldCVLedgEntryBuf, SourceCVLedgEntryBuf)
        else
            SalesTaxCorrDocMgt.CreateCrMemoHeader(DtldCVLedgEntryBuf, SourceCVLedgEntryBuf);
    end;

    [Scope('OnPrem')]
    procedure CreateDocLine(var VATEntry: Record "VAT Entry" temporary; OriginalInvoiceNo: Code[20])
    begin
        VATEntry."VAT Date" := VATEntry."Posting Date";
        VATEntry.Modify;

        if SourceIsServiceDoc then
            ServiceTaxCorrDocMgt.CreateCrMemoLine(VATEntry, OriginalInvoiceNo)
        else
            SalesTaxCorrDocMgt.CreateCrMemoLine(VATEntry, OriginalInvoiceNo);

        InsertVATEntryBuffer(VATEntry);
    end;

    [Scope('OnPrem')]
    procedure CreateDocRounding(DocumentNo: Code[20]; RoundingAmt: Decimal)
    begin
        if SourceIsServiceDoc then
            ServiceTaxCorrDocMgt.CreateCrMemoRounding(DocumentNo, RoundingAmt)
        else
            SalesTaxCorrDocMgt.CreateCrMemoRounding(DocumentNo, RoundingAmt);
    end;

    [Scope('OnPrem')]
    procedure GetVATCalculationType(VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]): Integer
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Get(VATBusPostingGroup, VATProdPostingGroup);
        exit(VATPostingSetup."VAT Calculation Type");
    end;

    [Scope('OnPrem')]
    procedure GetLastInsertedCrMemoNo(): Code[20]
    begin
        if SourceIsServiceDoc then
            exit(ServiceTaxCorrDocMgt.GetLastInsertedCrMemoNo);
        exit(SalesTaxCorrDocMgt.GetLastInsertedCrMemoNo);
    end;

    [Scope('OnPrem')]
    procedure GetInsertedAmountTotal(): Decimal
    begin
        if SourceIsServiceDoc then
            exit(ServiceTaxCorrDocMgt.GetInsertedAmountTotal);
        exit(SalesTaxCorrDocMgt.GetInsertedAmountTotal);
    end;

    [Scope('OnPrem')]
    procedure CreateDocForUnapply(DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; AppliedPmtDocNo: Code[20]): Boolean
    begin
        if DtldCustLedgEntry."Document Type" = DtldCustLedgEntry."Document Type"::Payment then
            exit(CopyCrMemoToInvoice(DtldCustLedgEntry, AppliedPmtDocNo));

        exit(false);
    end;

    local procedure CopyCrMemoToInvoice(DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; AppliedPmtDocNo: Code[20]): Boolean
    begin
        if SourceIsServiceDoc then
            exit(ServiceTaxCorrDocMgt.CopyCrMemoToInvoice(DtldCustLedgEntry, AppliedPmtDocNo));
        exit(SalesTaxCorrDocMgt.CopyCrMemoToInvoice(DtldCustLedgEntry, AppliedPmtDocNo));
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetupRead then
            GLSetup.Get;
        GLSetupRead := true;
    end;

    [Scope('OnPrem')]
    procedure AddTaxCorrDocDescToSalesLine(ToSalesHeader: Record "Sales Header"; var NextLineNo: Integer; TaxDocumentNo: Code[20]; Amount: Decimal; AmountInclVAT: Decimal)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        VATAmount: Decimal;
        NormalFormatString: Text[50];
    begin
        GetGLSetup;

        InsertTaxCorrDesc_SalesLine(
          ToSalesHeader, NextLineNo,
          StrSubstNo(TextTaxDocTxt, TaxDocumentNo));

        SalesReceivablesSetup.Get;
        if not SalesReceivablesSetup."Copy As Tax Corr. Document" then
            exit;

        VATAmount := AmountInclVAT - Amount;
        NormalFormatString := StrSubstNo(FormatStrTxt, GLSetup."Amount Decimal Places");

        InsertTaxCorrDesc_SalesLine(
          ToSalesHeader, NextLineNo,
          StrSubstNo(TextVATBaseTxt, Format(Amount, 0, NormalFormatString)));

        InsertTaxCorrDesc_SalesLine(
          ToSalesHeader, NextLineNo,
          StrSubstNo(TextVATAmtTxt, Format(VATAmount, 0, NormalFormatString)));

        InsertTaxCorrDesc_SalesLine(
          ToSalesHeader, NextLineNo,
          StrSubstNo(TextAmtIncVATTxt, Format(AmountInclVAT, 0, NormalFormatString)));
    end;

    local procedure InsertTaxCorrDesc_SalesLine(ToSalesHeader: Record "Sales Header"; var NextLineNo: Integer; InfoDescription: Text[50])
    var
        ToSalesLine: Record "Sales Line";
    begin
        NextLineNo += 10000;
        with ToSalesLine do begin
            Init;
            "Line No." := NextLineNo;
            "Document Type" := ToSalesHeader."Document Type";
            "Document No." := ToSalesHeader."No.";
            Description := InfoDescription;
            Insert;
        end;
    end;

    [Scope('OnPrem')]
    procedure AddTaxCorrDocDescToSalesCrMemo(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; var NextLineNo: Integer)
    begin
        NextLineNo += 10000;
        with SalesCrMemoLine do begin
            Init;
            "Line No." := NextLineNo;
            Description := TextPayDiscTxt;
            Insert;
        end;
    end;

    [Scope('OnPrem')]
    procedure AddTaxCorrDocDescToServCrMemo(var ServiceCrMemoLine: Record "Service Cr.Memo Line"; var NextLineNo: Integer)
    begin
        NextLineNo += 10000;
        with ServiceCrMemoLine do begin
            Init;
            "Line No." := NextLineNo;
            Description := TextPayDiscTxt;
            Insert;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetVATIdentifier(VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Get(VATBusPostingGroup, VATProdPostingGroup);
        exit(VATPostingSetup."VAT Identifier");
    end;

    local procedure ClearVATEntryBuffer()
    begin
        TempVATEntry.Reset;
        TempVATEntry.DeleteAll;
        Clear(TempVATEntry);
    end;

    local procedure InsertVATEntryBuffer(TempVATEntry2: Record "VAT Entry" temporary)
    begin
        TempVATEntry := TempVATEntry2;
        TempVATEntry.Insert;
    end;

    [Scope('OnPrem')]
    procedure UpdateVATEntry(var TempVATEntry2: Record "VAT Entry" temporary)
    begin
        with TempVATEntry2 do
            if FindSet then
                repeat
                    if TempVATEntry.Get("Entry No.") then begin
                        "Pmt.Disc. Tax Corr.Doc. No." := GetLastInsertedCrMemoNo;
                        Modify;
                    end;
                until Next = 0;

        ClearVATEntryBuffer;
    end;
}

