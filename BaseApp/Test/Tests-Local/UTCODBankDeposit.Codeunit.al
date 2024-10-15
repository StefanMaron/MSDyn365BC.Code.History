#if not CLEAN20
codeunit 141007 "UT COD Bank Deposit"
{
    Subtype = Test;
    TestPermissions = Disabled;
    ObsoleteState = Pending;
    ObsoleteReason = 'Deposits is deprecated in favor of the Bank Deposits extension. The corresponding tests are now in that extension.';
    ObsoleteTag = '20.0';

    trigger OnRun()
    begin
        // [FEATURE] [Deposit]
    end;

    var
        Assert: Codeunit Assert;
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [HandlerFunctions('DepositReportHandler,ConfirmHandlerTRUE')]
    [Scope('OnPrem')]
    procedure OnRunDepositPostPrint()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DepositHeader: Record "Deposit Header";
        PostedDepositHeader: Record "Posted Deposit Header";
    begin
        // Purpose of the test is to validate OnRun trigger of the Codeunit ID: 10142, Deposit-Post + Print. Transaction model is AutoCommit for explicit commit used in Codeunit ID: 10140, Deposit-Post.
        // Setup.
        CreateDepositHeader(DepositHeader);
        CreateGenJournalLine(DepositHeader);

        // Exercise.
        CODEUNIT.Run(CODEUNIT::"Deposit-Post + Print", DepositHeader);

        // Verify: Verify the Posted Deposit exist after Post and Print of the Deposit.
        Assert.IsTrue(PostedDepositHeader.Get(DepositHeader."No."), 'Value must exist');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnRunDepositPrinted()
    var
        PostedDepositHeader: Record "Posted Deposit Header";
        OldNoPrinted: Integer;
    begin
        // Purpose of the test is to validate OnRun trigger of the Codeunit ID: 10143, Deposit-Printed. Transaction model is AutoCommit for explicit commit used in Codeunit ID: 10143, Deposit-Printed.
        // Setup.
        CreatePostedDeposit(PostedDepositHeader);
        OldNoPrinted := PostedDepositHeader."No. Printed";

        // Exercise.
        CODEUNIT.Run(CODEUNIT::"Deposit-Printed", PostedDepositHeader);

        // Verify: Verify the Posted Deposit - No Printed incremented to 1 after running Deposit-Printed Codeunit.
        PostedDepositHeader.Get(PostedDepositHeader."No.");
        PostedDepositHeader.TestField("No. Printed", OldNoPrinted + 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRunPostedDepositDelete()
    var
        PostedDepositHeader: Record "Posted Deposit Header";
    begin
        // Purpose of the test is to validate OnRun trigger of the Codeunit ID: 10144, Posted Deposit-Delete.
        // Setup.
        CreatePostedDeposit(PostedDepositHeader);

        // Exercise.
        CODEUNIT.Run(CODEUNIT::"Posted Deposit-Delete", PostedDepositHeader);

        // Verify: Verify the Posted Deposit do not exist after running Posted Deposit-Delete Codeunit.
        Assert.IsFalse(PostedDepositHeader.Get(PostedDepositHeader."No."), 'Value must not exist');
    end;

    local procedure CreateGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.Name := LibraryUTUtility.GetNewCode10;
        GenJournalTemplate.Type := GenJournalTemplate.Type::Deposits;
        GenJournalTemplate."Page ID" := PAGE::Deposit;
        GenJournalTemplate.Insert();

        GenJournalBatch."Journal Template Name" := GenJournalTemplate.Name;
        GenJournalBatch.Name := LibraryUTUtility.GetNewCode10;
        GenJournalBatch.Insert();
    end;

    local procedure CreateGenJournalLine(DepositHeader: Record "Deposit Header")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine."Journal Template Name" := DepositHeader."Journal Template Name";
        GenJournalLine."Journal Batch Name" := DepositHeader."Journal Batch Name";
        GenJournalLine."Line No." := LibraryRandom.RandInt(10);
        GenJournalLine."Posting Date" := WorkDate();
        GenJournalLine."Document Type" := GenJournalLine."Document Type"::Payment;
        GenJournalLine."Document No." := LibraryUTUtility.GetNewCode;
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::"G/L Account";
        GenJournalLine."Account No." := CreateGLAccount;
        GenJournalLine.Amount := -DepositHeader."Total Deposit Amount";
        GenJournalLine.Insert();
    end;

    local procedure CreateBankAccount(): Code[20]
    var
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        BankAccount: Record "Bank Account";
    begin
        BankAccountPostingGroup.FindFirst();
        BankAccount."No." := LibraryUTUtility.GetNewCode;
        BankAccount."Bank Acc. Posting Group" := BankAccountPostingGroup.Code;
        BankAccount.Insert();
        exit(BankAccount."No.");
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount."No." := LibraryUTUtility.GetNewCode;
        GLAccount.Insert();
        exit(GLAccount."No.");
    end;

    local procedure CreateDepositHeader(var DepositHeader: Record "Deposit Header")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJournalBatch(GenJournalBatch);
        DepositHeader."No." := LibraryUTUtility.GetNewCode;
        DepositHeader."Journal Template Name" := GenJournalBatch."Journal Template Name";
        DepositHeader."Journal Batch Name" := GenJournalBatch.Name;
        DepositHeader."Posting Date" := WorkDate();
        DepositHeader."Document Date" := WorkDate();
        DepositHeader."Bank Account No." := CreateBankAccount;
        DepositHeader."Total Deposit Amount" := LibraryRandom.RandDec(10, 2);
        DepositHeader.Insert();
    end;

    local procedure CreatePostedDeposit(var PostedDepositHeader: Record "Posted Deposit Header")
    var
        PostedDepositLine: Record "Posted Deposit Line";
    begin
        PostedDepositHeader."No." := LibraryUTUtility.GetNewCode;
        PostedDepositHeader.Insert();

        PostedDepositLine."Deposit No." := PostedDepositHeader."No.";
        PostedDepositLine."Line No." := LibraryRandom.RandInt(10);
        PostedDepositLine."Account Type" := PostedDepositLine."Account Type"::"G/L Account";
        PostedDepositLine."Document Type" := PostedDepositLine."Document Type"::Payment;
        PostedDepositLine."Account No." := CreateGLAccount;
        PostedDepositLine.Insert();
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure DepositReportHandler(var Deposit: Report Deposit)
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTRUE(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

#endif