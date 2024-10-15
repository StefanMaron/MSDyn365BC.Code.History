#if not CLEAN19
codeunit 1295 "Get Bank Stmt. Line Candidates"
{
    TableNo = "Payment Application Proposal";

    trigger OnRun()
    var
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
    begin
        BankAccReconLine.Get("Statement Type", "Bank Account No.", "Statement No.", "Statement Line No.");

        TransferExistingAppliedPmtEntries(Rec, BankAccReconLine);

        TransferCandidatestoAppliedPmtEntries(Rec, BankAccReconLine);
    end;

    var
        WithSetup: Boolean;

    local procedure CreatePaymentApplicationProposalFromAppliedPmtEntry(var AppliedPmtEntry: Record "Applied Payment Entry"; var PaymentApplicationProposal: Record "Payment Application Proposal")
    begin
        if AppliedPmtEntry.FindSet() then
            repeat
                PaymentApplicationProposal.CreateFromAppliedPaymentEntry(AppliedPmtEntry);
            until AppliedPmtEntry.Next() = 0;
    end;

    local procedure GetCandidateRanking(BankAccReconLine: Record "Bank Acc. Reconciliation Line"; var TempBankStmtMatchingBuffer: Record "Bank Statement Matching Buffer" temporary)
    var
        BankPmtApplSettings: Record "Bank Pmt. Appl. Settings";
        BankAccount: Record "Bank Account";
        MatchBankPayments: Codeunit "Match Bank Payments";
    begin
        BankAccReconLine.SetRecFilter();
        MatchBankPayments.SetApplyEntries(false);
        SetAddParamToAddApply(BankAccReconLine, MatchBankPayments); // NAVCZ
        MatchBankPayments.Run(BankAccReconLine);
        MatchBankPayments.GetBankStatementMatchingBuffer(TempBankStmtMatchingBuffer);

        BankAccount.Get(BankAccReconLine."Bank Account No.");
        BankPmtApplSettings.GetOrInsert(BankAccount."Bank Pmt. Appl. Rule Code");
        if not BankPmtApplSettings."Cust. Ledger Entries Matching" then
            MatchBankPayments.GetCustomerLedgerEntriesAsMatchingBuffer(TempBankStmtMatchingBuffer, BankAccReconLine);

        if not BankPmtApplSettings."Vendor Ledger Entries Matching" then
            MatchBankPayments.GetVendorLedgerEntriesAsMatchingBuffer(TempBankStmtMatchingBuffer, BankAccReconLine);

        if not BankPmtApplSettings."Empl. Ledger Entries Matching" then
            MatchBankPayments.GetEmployeeLedgerEntriesAsMatchingBuffer(TempBankStmtMatchingBuffer, BankAccReconLine);

        if not BankPmtApplSettings."Bank Ledger Entries Matching" then
            MatchBankPayments.GetBankLedgerEntriesAsMatchingBuffer(TempBankStmtMatchingBuffer, BankAccReconLine);
    end;

    local procedure TransferExistingAppliedPmtEntries(var PaymentApplicationProposal: Record "Payment Application Proposal"; BankAccReconLine: Record "Bank Acc. Reconciliation Line")
    var
        ExistingAppliedPmtEntry: Record "Applied Payment Entry";
    begin
        ExistingAppliedPmtEntry.FilterAppliedPmtEntry(BankAccReconLine);
        CreatePaymentApplicationProposalFromAppliedPmtEntry(ExistingAppliedPmtEntry, PaymentApplicationProposal);
    end;

    local procedure TransferCandidatestoAppliedPmtEntries(var PaymentApplicationProposal: Record "Payment Application Proposal"; BankAccReconLine: Record "Bank Acc. Reconciliation Line")
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        TempBankStmtMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        BankAccount: Record "Bank Account";
        Handled: Boolean;
    begin
        OnBeforeTransferCandidatestoAppliedPmtEntries(BankAccReconLine, TempBankStmtMatchingBuffer, Handled);
        if not Handled then
            GetCandidateRanking(BankAccReconLine, TempBankStmtMatchingBuffer);
        BankAccount.Get(BankAccReconLine."Bank Account No.");

        PaymentApplicationProposal.Reset();
        TempBankStmtMatchingBuffer.Reset();
        TempBankStmtMatchingBuffer.SetRange("One to Many Match", false);

        if TempBankStmtMatchingBuffer.FindSet() then
            repeat
                PaymentApplicationProposal.CreateFromBankStmtMacthingBuffer(TempBankStmtMatchingBuffer, BankAccReconLine, BankAccount);
                if not PaymentApplicationProposal.Insert(true) then begin
                    PaymentApplicationProposal.Find();
                    PaymentApplicationProposal."Match Confidence" :=
                      BankPmtApplRule.GetMatchConfidence(PaymentApplicationProposal.Quality, TempBankStmtMatchingBuffer."Entry No." < 0); // NAVCZ
                    PaymentApplicationProposal.Modify(true);
                end;
            until TempBankStmtMatchingBuffer.Next() = 0;
    end;

    [Scope('OnPrem')]
    [Obsolete('Replaced by Banking Documents Localization for Czech.', '19.0')]
    procedure SetAddParamToAddApply(BankAccReconLine: Record "Bank Acc. Reconciliation Line"; var MatchBankPayments: Codeunit "Match Bank Payments")
    var
        BankAccount: Record "Bank Account";
        SpecificationApplParametrs: Page "Specification Appl. Parametrs";
        NotApplyCustLedgerEntries: Boolean;
        NotApplyVendLedgerEntries: Boolean;
        NotApplySalesAdvances: Boolean;
        NotApplyPurchaseAdvances: Boolean;
        NotApplyGenLedgerEntries: Boolean;
        NotAplBankAccLedgEntries: Boolean;
        UsePaymentAppRules: Boolean;
        UseTextToAccMappingCode: Boolean;
        BankPmtApplRuleCode: Code[10];
        TextToAccountMappingCode: Code[10];
        OnlyNotAppliedLines: Boolean;
    begin
        // NAVCZ
        if not WithSetup then
            exit;

        BankAccount.Get(BankAccReconLine."Bank Account No.");
        SpecificationApplParametrs.SetBankAccount(BankAccount);
        SpecificationApplParametrs.SetIsManual(true);
        if SpecificationApplParametrs.RunModal() <> ACTION::Yes then
            Error('');

        SpecificationApplParametrs.GetValuesForApp(
          NotApplyCustLedgerEntries, NotApplyVendLedgerEntries,
          NotApplySalesAdvances, NotApplyPurchaseAdvances,
          NotApplyGenLedgerEntries, NotAplBankAccLedgEntries,
          UsePaymentAppRules, UseTextToAccMappingCode, BankPmtApplRuleCode,
          TextToAccountMappingCode, OnlyNotAppliedLines);

        MatchBankPayments.SetValuesForApp(
          NotApplyCustLedgerEntries, NotApplyVendLedgerEntries,
          NotApplySalesAdvances, NotApplyPurchaseAdvances,
          NotApplyGenLedgerEntries, NotAplBankAccLedgEntries,
          UsePaymentAppRules, UseTextToAccMappingCode, BankPmtApplRuleCode,
          TextToAccountMappingCode, OnlyNotAppliedLines);
    end;

    [Scope('OnPrem')]
    [Obsolete('Replaced by Banking Documents Localization for Czech.', '19.0')]
    procedure SetWithSetup(WithSetupNew: Boolean)
    begin
        // NAVCZ
        WithSetup := WithSetupNew;
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnBeforeTransferCandidatestoAppliedPmtEntries(BankAccReconLine: Record "Bank Acc. Reconciliation Line"; var TempBankStmtMatchingBuffer: Record "Bank Statement Matching Buffer" temporary; var Handled: Boolean)
    begin
    end;
}

#endif