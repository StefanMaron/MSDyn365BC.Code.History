codeunit 142076 "UT COD Bank Rec"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Bank Reconciliation]
    end;

    var
        Assert: Codeunit Assert;
        LibraryUTUtility: Codeunit "Library UT Utility";

    [Test]
    [HandlerFunctions('ConfirmHandler,BankReconciliationHandler')]
    [Scope('OnPrem')]
    procedure OnRunDepositPostPrint()
    var
        BankRecHeader: Record "Bank Rec. Header";
        PostedBankRecHeader: Record "Posted Bank Rec. Header";
    begin
        // Purpose of the test is to validate OnRun trigger of the Codeunit 10122 Bank Rec.-Post + Print.
        // Setup.
        CreateBankRecHeader(BankRecHeader);

        // Pre-Exercise
        SetBankReconciliationReports;

        // Exercise.
        CODEUNIT.Run(CODEUNIT::"Bank Rec.-Post + Print", BankRecHeader);

        // Verify: Verify the Posted Bank Rec. Header exist after Post and Print of the Bank Rec. Header.
        PostedBankRecHeader.SetRange("Bank Account No.", BankRecHeader."Bank Account No.");
        PostedBankRecHeader.FindFirst();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnRUNPostedBankRecDelete()
    var
        PostedBankRecHeader: Record "Posted Bank Rec. Header";
    begin
        // Purpose of the test is to validate OnRun trigger of the Codeunit 10125 Posted Bank Rec.-Delete.
        // Setup.
        CreatePostedBankRecHeader(PostedBankRecHeader);

        // Exercise.
        CODEUNIT.Run(CODEUNIT::"Posted Bank Rec.-Delete", PostedBankRecHeader);

        // Verify: Verify the Posted Bank Rec. Header do not exist after running Posted Bank Rec.-Delete Codeunit.
        Assert.IsFalse(PostedBankRecHeader.Get(PostedBankRecHeader."Bank Account No."), 'Value must not exist');
    end;

    [Test]
    [HandlerFunctions('BankReconciliationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PrintBankRecStmtDocumentPrint()
    var
        PostedBankRecHeader: Record "Posted Bank Rec. Header";
        DocumentPrint: Codeunit "Document-Print";
    begin
        // Purpose of the test is to validate PrintBAnkRecStmt trigger of the Codeunit 229 Document-Print.
        // Setup.
        CreatePostedBankRecHeader(PostedBankRecHeader);

        // Pre-Exercise
        SetBankReconciliationReports;

        // Exercise.
        DocumentPrint.PrintBankRecStmt(PostedBankRecHeader);

        // Verify: Verify the Posted Bank Rec Header do not exist after running Document-Print Codeunit.
        Assert.IsFalse(PostedBankRecHeader.Get(PostedBankRecHeader."Bank Account No."), 'Value must not exist');
    end;

    local procedure CreateBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount."No." := LibraryUTUtility.GetNewCode;
        BankAccount.Insert();
        exit(BankAccount."No.");
    end;

    local procedure CreateBankRecHeader(var PostedBankRecHeader: Record "Bank Rec. Header")
    begin
        PostedBankRecHeader."Bank Account No." := CreateBankAccount;
        PostedBankRecHeader."Statement No." := LibraryUTUtility.GetNewCode;
        PostedBankRecHeader."Statement Date" := WorkDate();
        PostedBankRecHeader.Insert();
    end;

    local procedure CreatePostedBankRecHeader(var PostedBankRecHeader: Record "Posted Bank Rec. Header")
    var
        PostedBankRecLine: Record "Posted Bank Rec. Line";
        BankCommentLine: Record "Bank Comment Line";
    begin
        PostedBankRecHeader."Bank Account No." := CreateBankAccount;
        PostedBankRecHeader."Statement No." := LibraryUTUtility.GetNewCode;
        PostedBankRecHeader.Insert();
        PostedBankRecLine."Bank Account No." := PostedBankRecHeader."Bank Account No.";
        PostedBankRecLine."Statement No." := PostedBankRecHeader."Statement No.";
        PostedBankRecLine.Insert();
        BankCommentLine."Bank Account No." := PostedBankRecHeader."Bank Account No.";
        BankCommentLine.Insert();
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure BankReconciliationHandler(var BankReconciliation: Report "Bank Reconciliation")
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    local procedure SetBankReconciliationReports()
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"B.Stmt", ReportSelections.Usage::"B.Recon.Test");
        ReportSelections.DeleteAll();

        AddReconciliationReport(ReportSelections.Usage::"B.Stmt", 1, REPORT::"Bank Reconciliation");
        AddReconciliationReport(ReportSelections.Usage::"B.Recon.Test", 1, REPORT::"Bank Rec. Test Report");
    end;

    local procedure AddReconciliationReport(Usage: Option; Sequence: Integer; ReportID: Integer)
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.Usage := Usage;
        ReportSelections.Sequence := Format(Sequence);
        ReportSelections."Report ID" := ReportID;
        ReportSelections.Insert();
    end;
}

