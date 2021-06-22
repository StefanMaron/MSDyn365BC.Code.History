codeunit 134444 "ERM Test Account Categories"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [G/L Account] [Account Category] [Account Schedule]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        ExpectedAccSchedName: Code[10];

    [Test]
    [HandlerFunctions('AccSchedReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestBalanceSheet()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
    begin
        // Init
        GLAccountCategoryMgt.GetGLSetup(GeneralLedgerSetup);
        ExpectedAccSchedName := GeneralLedgerSetup."Acc. Sched. for Balance Sheet";

        // Execution
        REPORT.Run(REPORT::"Balance Sheet");

        // Validation is done in the request page handler.
    end;

    [Test]
    [HandlerFunctions('AccSchedReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestIncomeStatement()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
    begin
        // Init
        GLAccountCategoryMgt.GetGLSetup(GeneralLedgerSetup);
        ExpectedAccSchedName := GeneralLedgerSetup."Acc. Sched. for Income Stmt.";

        // Execution
        REPORT.Run(REPORT::"Income Statement");

        // Validation is done in the request page handler.
    end;

    [Test]
    [HandlerFunctions('AccSchedReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestCashFlowStatement()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
    begin
        // Init
        GLAccountCategoryMgt.GetGLSetup(GeneralLedgerSetup);
        ExpectedAccSchedName := GeneralLedgerSetup."Acc. Sched. for Cash Flow Stmt";

        // Execution
        REPORT.Run(REPORT::"Statement of Cashflows");

        // Validation is done in the request page handler.
    end;

    [Test]
    [HandlerFunctions('AccSchedReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestRetainedEarningsStatement()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
    begin
        // Init
        GLAccountCategoryMgt.GetGLSetup(GeneralLedgerSetup);
        ExpectedAccSchedName := GeneralLedgerSetup."Acc. Sched. for Retained Earn.";

        // Execution
        REPORT.Run(REPORT::"Retained Earnings Statement");

        // Validation is done in the request page handler.
    end;

    [Test]
    [HandlerFunctions('GLAccountCategoriesLookupHandler')]
    [Scope('OnPrem')]
    procedure AccountSubcategoryLookupDoesntInsertTheGLAccount()
    var
        GLAccount: Record "G/L Account";
        GLAccountCardPage: TestPage "G/L Account Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 284151] Account Subcategory Lookup on G/L Account Card page doesn't insert current record

        // [GIVEN] G/L Account Card page was open
        GLAccountCardPage.OpenNew;

        // [WHEN] Lookup is invoked for Account Subcategory
        GLAccountCardPage.SubCategoryDescription.Lookup;
        // Handled by GLAccountCategoriesLookupHandler

        // [THEN] G/L Account with blank "No." wasn't inserted
        GLAccount.SetRange("No.", '');
        Assert.RecordIsEmpty(GLAccount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccountSubcategoryValidateDoesntInsertTheGLAccount()
    var
        GLAccount: Record "G/L Account";
        GLAccountCategory: Record "G/L Account Category";
        GLAccountCardPage: TestPage "G/L Account Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 284151] Account Subcategory Validate on G/L Account Card page doesn't insert current record

        // [GIVEN] G/L Account Card page was open
        GLAccountCardPage.OpenNew;

        // [GIVEN] A G/L Account Category
        CreateGLAccountCategory(GLAccountCategory);

        // [GIVEN] "Account Category" was set
        GLAccountCardPage."Account Category".SetValue(GLAccountCategory."Account Category");

        // [WHEN] Validating Account Subcategory
        GLAccountCardPage.SubCategoryDescription.SetValue(GLAccountCategory.Description);

        // [THEN] G/L Account with blank "No." wasn't inserted
        GLAccount.SetRange("No.", '');
        Assert.RecordIsEmpty(GLAccount);
    end;

    local procedure CreateGLAccountCategory(var GLAccountCategory: Record "G/L Account Category")
    begin
        LibraryERM.CreateGLAccountCategory(GLAccountCategory);
        GLAccountCategory.Validate(Description, LibraryUtility.GenerateGUID);
        GLAccountCategory.Modify();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GLAccountCategoriesLookupHandler(var GLAccountCategoriesPage: TestPage "G/L Account Categories")
    begin
        GLAccountCategoriesPage.First;
        GLAccountCategoriesPage.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AccSchedReportRequestPageHandler(var AccountSchedule: TestRequestPage "Account Schedule")
    begin
        Assert.AreEqual(ExpectedAccSchedName, AccountSchedule.AccSchedNam.Value, '');
    end;
}

