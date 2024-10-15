codeunit 143040 "Library - Advance"
{

    trigger OnRun()
    begin
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";

    [Scope('OnPrem')]
    procedure CorrectVATByPurchDeductedVAT(var PurchHeader: Record "Purchase Header")
    var
        PurchPostAdvances: Codeunit "Purchase-Post Advances";
    begin
        PurchPostAdvances.CorrectVATbyDeductedVAT(PurchHeader);
    end;

    [Scope('OnPrem')]
    procedure CorrectVATBySalesDeductedVAT(var SalesHeader: Record "Sales Header")
    var
        SalesPostAdvances: Codeunit "Sales-Post Advances";
    begin
        SalesPostAdvances.CorrectVATbyDeductedVAT(SalesHeader);
    end;

    [Scope('OnPrem')]
    procedure CreateCustomerPostingGroup(var CustPostingGroup: Record "Customer Posting Group")
    begin
        CustPostingGroup.Init();
        CustPostingGroup.Validate(
          Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(CustPostingGroup.FieldNo(Code), DATABASE::"Customer Posting Group"),
            1, MaxStrLen(CustPostingGroup.Code)));
        CustPostingGroup.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreatePurchAdvLetterHeader(var PurchAdvLetterHeader: Record "Purch. Advance Letter Header"; PurchAdvPmntTempCode: Code[10]; VendorNo: Code[20])
    begin
        PurchAdvLetterHeader.Init();
        PurchAdvLetterHeader.Validate("Template Code", PurchAdvPmntTempCode);
        PurchAdvLetterHeader.Insert(true);

        PurchAdvLetterHeader.Validate("External Document No.", PurchAdvLetterHeader."No.");
        PurchAdvLetterHeader.Validate("Pay-to Vendor No.", VendorNo);
        PurchAdvLetterHeader.Validate("Posting Date", WorkDate);
        PurchAdvLetterHeader.Validate("Document Date", WorkDate);
        PurchAdvLetterHeader.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreatePurchAdvLetterLine(var PurchAdvLetterLine: Record "Purch. Advance Letter Line"; PurchAdvLetterHeader: Record "Purch. Advance Letter Header"; VATProdPostingGroupCode: Code[20]; AmountIncludingVAT: Decimal)
    var
        RecRef: RecordRef;
    begin
        PurchAdvLetterLine.Init();
        PurchAdvLetterLine.Validate("Letter No.", PurchAdvLetterHeader."No.");
        RecRef.GetTable(PurchAdvLetterLine);
        PurchAdvLetterLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, PurchAdvLetterLine.FieldNo("Line No.")));
        PurchAdvLetterLine.Insert(true);

        PurchAdvLetterLine.Validate("VAT Prod. Posting Group", VATProdPostingGroupCode);
        PurchAdvLetterLine.Validate("Amount Including VAT", AmountIncludingVAT);
        PurchAdvLetterLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreatePurchAdvLetterFromPurchDoc(var PurchAdvLetterHeader: Record "Purch. Advance Letter Header"; PurchHeader: Record "Purchase Header"; PurchAdvPmntTempCode: Code[10])
    var
        PurchPostAdvances: Codeunit "Purchase-Post Advances";
        AdvLetterNo: Code[20];
    begin
        PurchPostAdvances.Letter(PurchHeader, AdvLetterNo, PurchAdvPmntTempCode);
        PurchAdvLetterHeader.Get(AdvLetterNo);
    end;

    [Scope('OnPrem')]
    procedure CreatePurchAdvPmntTemplate(var PurchaseAdvPaymentTemplate: Record "Purchase Adv. Payment Template")
    begin
        PurchaseAdvPaymentTemplate.Init();
        PurchaseAdvPaymentTemplate.Validate(
          Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(PurchaseAdvPaymentTemplate.FieldNo(Code), DATABASE::"Purchase Adv. Payment Template"),
            1, MaxStrLen(PurchaseAdvPaymentTemplate.Code)));
        PurchaseAdvPaymentTemplate.Validate(Description, PurchaseAdvPaymentTemplate.Code);
        PurchaseAdvPaymentTemplate.Insert(true);

        PurchaseAdvPaymentTemplate.Validate("Advance Letter Nos.", LibraryUtility.GetGlobalNoSeriesCode);
        PurchaseAdvPaymentTemplate.Validate("Advance Invoice Nos.", LibraryUtility.GetGlobalNoSeriesCode);
        PurchaseAdvPaymentTemplate.Validate("Advance Credit Memo Nos.", LibraryUtility.GetGlobalNoSeriesCode);
        PurchaseAdvPaymentTemplate.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateSalesAdvLetterHeader(var SalesAdvLetterHeader: Record "Sales Advance Letter Header"; SalesAdvPmntTempCode: Code[10]; CustomerNo: Code[20])
    begin
        SalesAdvLetterHeader.Init();
        SalesAdvLetterHeader.Validate("Template Code", SalesAdvPmntTempCode);
        SalesAdvLetterHeader.Insert(true);

        SalesAdvLetterHeader.Validate("External Document No.", SalesAdvLetterHeader."No.");
        SalesAdvLetterHeader.Validate("Bill-to Customer No.", CustomerNo);
        SalesAdvLetterHeader.Validate("Posting Date", WorkDate);
        SalesAdvLetterHeader.Validate("Document Date", WorkDate);
        SalesAdvLetterHeader.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateSalesAdvLetterLine(var SalesAdvLetterLine: Record "Sales Advance Letter Line"; SalesAdvLetterHeader: Record "Sales Advance Letter Header"; VATProdPostingGroupCode: Code[20]; AmountIncludingVAT: Decimal)
    var
        RecRef: RecordRef;
    begin
        SalesAdvLetterLine.Init();
        SalesAdvLetterLine.Validate("Letter No.", SalesAdvLetterHeader."No.");
        RecRef.GetTable(SalesAdvLetterLine);
        SalesAdvLetterLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, SalesAdvLetterLine.FieldNo("Line No.")));
        SalesAdvLetterLine.Insert(true);

        SalesAdvLetterLine.Validate("VAT Prod. Posting Group", VATProdPostingGroupCode);
        SalesAdvLetterLine.Validate("Amount Including VAT", AmountIncludingVAT);
        SalesAdvLetterLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateSalesAdvLetterFromSalesDoc(var SalesAdvLetterHeader: Record "Sales Advance Letter Header"; SalesHeader: Record "Sales Header"; SalesAdvPmntTempCode: Code[10])
    var
        SalesPostAdvances: Codeunit "Sales-Post Advances";
        AdvLetterNo: Code[20];
    begin
        SalesPostAdvances.Letter(SalesHeader, AdvLetterNo, SalesAdvPmntTempCode);
        SalesAdvLetterHeader.Get(AdvLetterNo);
    end;

    [Scope('OnPrem')]
    procedure CreateSalesAdvPmntTemplate(var SalesAdvPaymentTemplate: Record "Sales Adv. Payment Template")
    begin
        SalesAdvPaymentTemplate.Init();
        SalesAdvPaymentTemplate.Validate(
          Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(SalesAdvPaymentTemplate.FieldNo(Code), DATABASE::"Sales Adv. Payment Template"),
            1, MaxStrLen(SalesAdvPaymentTemplate.Code)));
        SalesAdvPaymentTemplate.Validate(Description, SalesAdvPaymentTemplate.Code);
        SalesAdvPaymentTemplate.Insert(true);

        SalesAdvPaymentTemplate.Validate("Advance Letter Nos.", LibraryUtility.GetGlobalNoSeriesCode);
        SalesAdvPaymentTemplate.Validate("Advance Invoice Nos.", LibraryUtility.GetGlobalNoSeriesCode);
        SalesAdvPaymentTemplate.Validate("Advance Credit Memo Nos.", LibraryUtility.GetGlobalNoSeriesCode);
        SalesAdvPaymentTemplate.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateVendorPostingGroup(var VendorPostingGroup: Record "Vendor Posting Group")
    begin
        VendorPostingGroup.Init();
        VendorPostingGroup.Validate(
          Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(VendorPostingGroup.FieldNo(Code), DATABASE::"Vendor Posting Group"),
            1, MaxStrLen(VendorPostingGroup.Code)));
        VendorPostingGroup.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure ChangeExchangeRate(CurrencyCode: Code[20]; CurrencyFactor: Decimal; PostingDate: Date): Decimal
    var
        ChangeExchRate: Page "Change Exchange Rate";
    begin
        ChangeExchRate.SetParameter(CurrencyCode, CurrencyFactor, PostingDate);
        if ChangeExchRate.RunModal = ACTION::OK then
            exit(ChangeExchRate.GetParameter);
    end;

    [Scope('OnPrem')]
    procedure LinkWholeAdvanceLetterToGenJnlLine(var GenJnlLine: Record "Gen. Journal Line")
    begin
        GenJnlLine.LinkWholeLetter;
    end;

    [Scope('OnPrem')]
    procedure LinkAdvanceLettersToGenJnlLine(var GenJnlLine: Record "Gen. Journal Line")
    begin
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Link Letters", GenJnlLine);
    end;

    [Scope('OnPrem')]
    procedure LinkAdvanceLetterToPurchDocument(var PurchHeader: Record "Purchase Header")
    var
        AdvLetterLinkingCard: Page "Purch. Adv. Letter Link. Card";
    begin
        AdvLetterLinkingCard.SetPurchDoc(PurchHeader."Document Type", PurchHeader."No.");
        AdvLetterLinkingCard.LookupMode := true;
        if AdvLetterLinkingCard.RunModal = ACTION::LookupOK then
            AdvLetterLinkingCard.WriteChanges;
    end;

    [Scope('OnPrem')]
    procedure LinkAdvanceLetterToSalesDocument(var SalesHeader: Record "Sales Header")
    var
        AdvLetterLinkingCard: Page "Sales Adv. Letter Link. Card";
    begin
        AdvLetterLinkingCard.SetSalesDoc(SalesHeader."Document Type", SalesHeader."No.");
        AdvLetterLinkingCard.LookupMode := true;
        if AdvLetterLinkingCard.RunModal = ACTION::LookupOK then
            AdvLetterLinkingCard.WriteChanges;
    end;

    [Scope('OnPrem')]
    procedure PostPurchAdvInvoice(var PurchAdvLetterHeader: Record "Purch. Advance Letter Header")
    var
        PurchPostAdvances: Codeunit "Purchase-Post Advances";
        PurchHeader: Record "Purchase Header";
    begin
        if PurchAdvLetterHeader."Order No." <> '' then begin
            PurchHeader.SetRange("No.", PurchAdvLetterHeader."Order No.");
            PurchHeader.FindFirst();
            PurchPostAdvances.SetLetterNo(PurchAdvLetterHeader."No.");
            PurchPostAdvances.Invoice(PurchHeader);
        end else
            PurchPostAdvances.PostLetter(PurchAdvLetterHeader, 0);
    end;

    [Scope('OnPrem')]
    procedure PostPurchAdvCrMemo(var PurchAdvLetterHeader: Record "Purch. Advance Letter Header")
    var
        PurchPostAdvances: Codeunit "Purchase-Post Advances";
        PurchHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchSetup: Record "Purchases & Payables Setup";
        GLSetup: Record "General Ledger Setup";
        NoSeriesMgt: Codeunit NoSeriesManagement;
    begin
        PurchInvHeader.SetCurrentKey("Prepayment Order No.");
        PurchInvHeader.SetFilter("Reversed By Cr. Memo No.", '%1', '');
        PurchInvHeader.SetRange("Letter No.", PurchAdvLetterHeader."No.");
        PurchInvHeader.FindFirst();

        if PurchAdvLetterHeader."Order No." <> '' then begin
            if not PurchHeader.Get(PurchHeader."Document Type"::Invoice, PurchAdvLetterHeader."Order No.") then
                PurchHeader.Get(PurchHeader."Document Type"::Order, PurchAdvLetterHeader."Order No.");
        end else begin
            PurchHeader.TransferFields(PurchAdvLetterHeader, false);
            PurchHeader."Document Type" := PurchHeader."Document Type"::Order;
            PurchHeader."Buy-from Vendor No." := PurchHeader."Pay-to Vendor No.";
            PurchHeader."No." := '';
            PurchSetup.Get();
            GLSetup.Get();
            NoSeriesMgt.SetDefaultSeries(PurchHeader."Prepayment No. Series", PurchSetup."Posted Prepmt. Inv. Nos.");
            NoSeriesMgt.SetDefaultSeries(PurchHeader."Prepmt. Cr. Memo No. Series", PurchSetup."Posted Prepmt. Cr. Memo Nos.");
            PurchHeader."Prepayment Type" := GLSetup."Prepayment Type";
            PurchHeader.PrepmtValidation;
        end;
        PurchPostAdvances.CreditMemo(PurchHeader, PurchInvHeader);
    end;

    [Scope('OnPrem')]
    procedure PostRefundAndClosePurchAdvLetter(var PurchAdvLetterHeader: Record "Purch. Advance Letter Header")
    var
        PurchPostAdvances: Codeunit "Purchase-Post Advances";
    begin
        PurchPostAdvances.RefundAndCloseLetterYesNo(
          '', PurchAdvLetterHeader, PurchAdvLetterHeader."Posting Date", PurchAdvLetterHeader."VAT Date", false);
    end;

    [Scope('OnPrem')]
    procedure PostRefundAndCloseSalesAdvLetter(var SalesAdvLetterHeader: Record "Sales Advance Letter Header")
    var
        SalesPostAdvances: Codeunit "Sales-Post Advances";
    begin
        SalesPostAdvances.RefundAndCloseLetterYesNo(
          '', SalesAdvLetterHeader, SalesAdvLetterHeader."Posting Date", SalesAdvLetterHeader."VAT Date", false);
    end;

    [Scope('OnPrem')]
    procedure PostSalesAdvInvoice(var SalesAdvLetterHeader: Record "Sales Advance Letter Header")
    var
        SalesPostAdvances: Codeunit "Sales-Post Advances";
        SalesHeader: Record "Sales Header";
    begin
        if SalesAdvLetterHeader."Order No." <> '' then begin
            SalesHeader.SetRange("No.", SalesAdvLetterHeader."Order No.");
            SalesHeader.FindFirst();
            SalesPostAdvances.SetLetterNo(SalesAdvLetterHeader."No.");
            SalesPostAdvances.Invoice(SalesHeader);
        end else
            SalesPostAdvances.PostLetter(SalesAdvLetterHeader, 0);
    end;

    [Scope('OnPrem')]
    procedure PostSalesAdvCrMemo(var SalesAdvLetterHeader: Record "Sales Advance Letter Header")
    var
        SalesPostAdvances: Codeunit "Sales-Post Advances";
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesSetup: Record "Sales & Receivables Setup";
        GLSetup: Record "General Ledger Setup";
        NoSeriesMgt: Codeunit NoSeriesManagement;
    begin
        SalesInvHeader.SetCurrentKey("Prepayment Order No.");
        SalesInvHeader.SetFilter("Reversed By Cr. Memo No.", '%1', '');
        SalesInvHeader.SetRange("Letter No.", SalesAdvLetterHeader."No.");
        SalesInvHeader.FindFirst();

        if SalesAdvLetterHeader."Order No." <> '' then begin
            if not SalesHeader.Get(SalesHeader."Document Type"::Invoice, SalesAdvLetterHeader."Order No.") then
                SalesHeader.Get(SalesHeader."Document Type"::Order, SalesAdvLetterHeader."Order No.");
        end else begin
            SalesHeader.TransferFields(SalesAdvLetterHeader, false);
            SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
            SalesHeader."Sell-to Customer No." := SalesHeader."Bill-to Customer No.";
            SalesHeader."No." := '';
            SalesSetup.Get();
            GLSetup.Get();
            NoSeriesMgt.SetDefaultSeries(SalesHeader."Prepayment No. Series", SalesSetup."Posted Prepmt. Inv. Nos.");
            NoSeriesMgt.SetDefaultSeries(SalesHeader."Prepmt. Cr. Memo No. Series", SalesSetup."Posted Prepmt. Cr. Memo Nos.");
            SalesHeader."Prepayment Type" := GLSetup."Prepayment Type";
            SalesHeader.PrepmtValidation;
        end;

        SalesPostAdvances.CreditMemo(SalesHeader, SalesInvHeader);
    end;

    [Scope('OnPrem')]
    procedure ReleasePurchAdvLetter(var PurchAdvLetterHeader: Record "Purch. Advance Letter Header")
    begin
        PurchAdvLetterHeader.Release;
    end;

    [Scope('OnPrem')]
    procedure ReleaseSalesAdvLetter(var SalesAdvLetterHeader: Record "Sales Advance Letter Header")
    begin
        SalesAdvLetterHeader.Release;
    end;
}

