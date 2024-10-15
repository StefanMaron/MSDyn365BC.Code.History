#if not CLEAN16
codeunit 145100 "Sync. Dep. Fld - P&PSetup Test"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Initialized: Boolean;

    [Test]
    [Obsolete('This test should be removed when the obsolete fields in Purchases & Payables Setup is removed', '16.0')]
    procedure TestSyncDepFldToValidFieldPPSetupNoError()
    var
        PurchasesAndPayablesSetup: Record "Purchases & Payables Setup";
        GLEntryAsDocLinesAccOldValue: Boolean;
    begin
        // [SCENARIO] validate obsolete field -> ensure it validates valid field with no endless loop 
        // [WHEN] The obsolete field is validated
        // [THEN] The valid field must have the same value as obsolete field and any error occur
        Initialize();

        PurchasesAndPayablesSetup.Get();
        Assert.AreEqual(PurchasesAndPayablesSetup."G/L Entry as Doc. Lines (Acc.)", PurchasesAndPayablesSetup."Copy Line Descr. to G/L Entry", 'cannot sync fields due to diff value');
        GLEntryAsDocLinesAccOldValue := PurchasesAndPayablesSetup."G/L Entry as Doc. Lines (Acc.)";
        PurchasesAndPayablesSetup.Validate("G/L Entry as Doc. Lines (Acc.)", NOT GLEntryAsDocLinesAccOldValue);

        // verify
        Assert.AreEqual(PurchasesAndPayablesSetup."Copy Line Descr. to G/L Entry", NOT GLEntryAsDocLinesAccOldValue, 'Sync Failed');
        Assert.AreEqual(PurchasesAndPayablesSetup."G/L Entry as Doc. Lines (Acc.)", PurchasesAndPayablesSetup."Copy Line Descr. to G/L Entry", 'Sync Failed');
    end;

    [Test]
    [Obsolete('This test should be removed when the obsolete fields in Purchases & Payables Setup is removed', '16.0')]
    procedure TestSyncValidFldToDepFieldPPSetupNoError()
    var
        PurchasesAndPayablesSetup: Record "Purchases & Payables Setup";
        CopyLineDescrToGLEntryOldValue: Boolean;
    begin
        // [SCENARIO] validate valid field -> ensure it validates obsolete field with no endless loop 
        // [WHEN] The valid field is validated
        // [THEN] The obsolete field must have the same value as valid field and any error occur
        Initialize();

        PurchasesAndPayablesSetup.Get();
        Assert.AreEqual(PurchasesAndPayablesSetup."G/L Entry as Doc. Lines (Acc.)", PurchasesAndPayablesSetup."Copy Line Descr. to G/L Entry", 'cannot sync fields due to diff value');
        CopyLineDescrToGLEntryOldValue := PurchasesAndPayablesSetup."Copy Line Descr. to G/L Entry";
        PurchasesAndPayablesSetup.Validate("Copy Line Descr. to G/L Entry", NOT CopyLineDescrToGLEntryOldValue);

        // verify
        Assert.AreEqual(PurchasesAndPayablesSetup."G/L Entry as Doc. Lines (Acc.)", NOT CopyLineDescrToGLEntryOldValue, 'Sync Failed');
        Assert.AreEqual(PurchasesAndPayablesSetup."Copy Line Descr. to G/L Entry", PurchasesAndPayablesSetup."G/L Entry as Doc. Lines (Acc.)", 'Sync Failed');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Sync. Dep. Fld - P&PSetup Test");
        if Initialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Sync. Dep. Fld - P&PSetup Test");

        Initialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Sync. Dep. Fld - P&PSetup Test");
    end;
}
#endif