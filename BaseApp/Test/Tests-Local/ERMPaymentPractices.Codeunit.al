codeunit 144566 "ERM Payment Practices"
{
    Permissions = TableData "Cust. Ledger Entry" = id,
                  TableData "Detailed Cust. Ledg. Entry" = i;
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Payment Practices]
    end;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        DaysFromLessThanDaysToErr: Label 'Days From must not be less than Days To.';

    [Test]
    [Scope('OnPrem')]
    procedure PaymentPeriodSetupDemodataExists()
    begin
        // [FEATURE] [DEMO] [UT]
        // [SCENARIO 257582] Payment Period Setup demodata exists

        LibraryLowerPermissions.SetO365Setup;
        CheckPaymentPeriodExists(1, 30);
        CheckPaymentPeriodExists(31, 60);
        CheckPaymentPeriodExists(61, 90);
        CheckPaymentPeriodExists(91, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotPossibleToCreatePmtPeriodSetupWithDaysFromAfterDaysTo()
    var
        PaymentPeriodSetup: Record "Payment Period Setup";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 257582] Stan cannot create "Payment Period Setup" where "Days From" after "Days To"

        Initialize;
        LibraryLowerPermissions.SetO365Setup;
        PaymentPeriodSetup.Init();
        PaymentPeriodSetup.Validate("Days From", 10);
        asserterror PaymentPeriodSetup.Validate("Days To", 9);

        Assert.ExpectedError(DaysFromLessThanDaysToErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotPossibleToCreatePmtPeriodSetupWithBlankDaysFrom()
    var
        PaymentPeriodSetup: TestPage "Payment Period Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 257582] Stan cannot create "Payment Period Setup" where "Days From" is blank

        Initialize;
        LibraryLowerPermissions.SetO365Setup;
        PaymentPeriodSetup.OpenNew;
        asserterror PaymentPeriodSetup."Days From".SetValue(0);

        Assert.ExpectedError('Days From must be filled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtPeriodSetupWithBlankDaysTo()
    var
        PaymentPeriodSetup: Record "Payment Period Setup";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 257582] Stan can create "Payment Period Setup" where "Days To" is blank

        Initialize;
        LibraryLowerPermissions.SetO365Setup;
        PaymentPeriodSetup.Init();
        PaymentPeriodSetup.Validate("Days From", 10);
        PaymentPeriodSetup.Validate("Days To", 0);
        PaymentPeriodSetup.Insert();
        PaymentPeriodSetup.TestField("Days To", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtPeriodSetupWithDaysToAfterDaysFrom()
    var
        PaymentPeriodSetup: Record "Payment Period Setup";
        DaysFrom: Integer;
        DaysTo: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 257582] Stan can create "Payment Period Setup" where "Days To" after "Days From"

        Initialize;
        LibraryLowerPermissions.SetO365Setup;
        DaysFrom := LibraryRandom.RandInt(100);
        DaysTo := DaysFrom + LibraryRandom.RandInt(100);
        PaymentPeriodSetup.Init();
        PaymentPeriodSetup.Validate("Days From", DaysFrom);
        PaymentPeriodSetup.Validate("Days To", DaysTo);
        PaymentPeriodSetup.Insert();
        PaymentPeriodSetup.TestField("Days To", DaysTo);
    end;

    local procedure Initialize()
    var
        PaymentPeriodSetup: Record "Payment Period Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Payment Practices");
        PaymentPeriodSetup.DeleteAll();
    end;

    local procedure CheckPaymentPeriodExists(DaysFrom: Integer; DaysTo: Integer)
    var
        PaymentPeriodSetup: Record "Payment Period Setup";
    begin
        PaymentPeriodSetup.SetRange("Days From", DaysFrom);
        PaymentPeriodSetup.SetRange("Days To", DaysTo);
        Assert.RecordCount(PaymentPeriodSetup, 1);
    end;
}

