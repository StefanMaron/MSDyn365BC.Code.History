codeunit 147593 "UT - Spain Tables"
{
    // // [FEATURE] [UT]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        UnexpectedValueErr: Label 'Unexpected value in Usage field';
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure PAutoInvoiceIndexInUsageOption()
    begin
        // [SCENARIO 380252] "P.AutoInvoice" should have 58 index in "Usage" option in Custom Report Selection table
        Assert.AreEqual('P.AutoInvoice', GetValueByIndexFromUsageOption(58), UnexpectedValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PAutoCrMemoIndexInUsageOption()
    begin
        // [SCENARIO 380252] "P.AutoCr.Memo" should have 59 index in "Usage" option in Custom Report Selection table
        Assert.AreEqual('P.AutoCr.Memo', GetValueByIndexFromUsageOption(59), UnexpectedValueErr);
    end;

    local procedure GetValueByIndexFromUsageOption(Index: Integer): Text
    var
        DummyCustomReportSelection: Record "Custom Report Selection";
    begin
        DummyCustomReportSelection.Usage := Index;
        exit(Format(DummyCustomReportSelection.Usage));
    end;
}

