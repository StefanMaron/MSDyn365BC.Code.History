#if not CLEAN16
codeunit 145101 "Sync. Dep. Fld - S&RSetup Test"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Initialized: Boolean;

    [Test]
    [Obsolete('This test should be removed when the obsolete fields in Sales & Receivables Setup is removed', '16.0')]
    procedure TestSyncDepFldToValidFieldSRSetupNoError()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        GLEntryAsDocLinesAccOldValue: Boolean;
    begin
        // [SCENARIO] validate obsolete field -> ensure it validates valid field with no endless loop 
        // [WHEN] The obsolete field is validated
        // [THEN] The valid field must have the same value as obsolete field and any error occur
        Initialize();

        SalesReceivablesSetup.Get();
        Assert.AreEqual(SalesReceivablesSetup."G/L Entry as Doc. Lines (Acc.)", SalesReceivablesSetup."Copy Line Descr. to G/L Entry", 'cannot sync fields due to diff value');
        GLEntryAsDocLinesAccOldValue := SalesReceivablesSetup."G/L Entry as Doc. Lines (Acc.)";
        SalesReceivablesSetup.Validate("G/L Entry as Doc. Lines (Acc.)", NOT GLEntryAsDocLinesAccOldValue);

        // verify
        Assert.AreEqual(SalesReceivablesSetup."Copy Line Descr. to G/L Entry", NOT GLEntryAsDocLinesAccOldValue, 'Sync Failed');
        Assert.AreEqual(SalesReceivablesSetup."G/L Entry as Doc. Lines (Acc.)", SalesReceivablesSetup."Copy Line Descr. to G/L Entry", 'Sync Failed');
    end;

    [Test]
    [Obsolete('This test should be removed when the obsolete fields in Sales & Receivables Setup is removed', '16.0')]
    procedure TestSyncValidFldToDepFieldSRSetupNoError()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        CopyLineDescrToGLEntryOldValue: Boolean;
    begin
        // [SCENARIO] validate valid field -> ensure it validates obsolete field with no endless loop 
        // [WHEN] The valid field is validated
        // [THEN] The obsolete field must have the same value as valid field and any error occur
        Initialize();

        SalesReceivablesSetup.Get();
        Assert.AreEqual(SalesReceivablesSetup."G/L Entry as Doc. Lines (Acc.)", SalesReceivablesSetup."Copy Line Descr. to G/L Entry", 'cannot sync fields due to diff value');
        CopyLineDescrToGLEntryOldValue := SalesReceivablesSetup."Copy Line Descr. to G/L Entry";
        SalesReceivablesSetup.Validate("Copy Line Descr. to G/L Entry", NOT CopyLineDescrToGLEntryOldValue);

        // verify
        Assert.AreEqual(SalesReceivablesSetup."G/L Entry as Doc. Lines (Acc.)", NOT CopyLineDescrToGLEntryOldValue, 'Sync Failed');
        Assert.AreEqual(SalesReceivablesSetup."Copy Line Descr. to G/L Entry", SalesReceivablesSetup."G/L Entry as Doc. Lines (Acc.)", 'Sync Failed');
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