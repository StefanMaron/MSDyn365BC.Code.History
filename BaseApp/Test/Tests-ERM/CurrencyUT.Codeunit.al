codeunit 134275 "Currency UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Currency]
    end;

    var
        Assert: Codeunit Assert;
        ASCIILetterErr: Label 'must contain ASCII letters only';
        NumericErr: Label 'must contain numbers only';
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [Scope('OnPrem')]
    procedure T100_ISOCodeIs3ASCIIChars()
    var
        Currency: Record Currency;
    begin
        // [FEATURE] [ISO Code]
        // [SCENARIO] Allowed "ISO Code" can be blank or must contain 3 ASCII letters
        asserterror Currency.Validate("ISO Code", CopyStr('EUEU', 1, 4));
        Assert.ExpectedError('is 4, but it must be less than or equal to 3 characters');

        asserterror Currency.Validate("ISO Code", 'EU');
        Assert.ExpectedError('is 2, but it must be equal to 3 characters');

        asserterror Currency.Validate("ISO Code", 'EU1');
        Assert.ExpectedError(ASCIILetterErr);

        asserterror Currency.Validate("ISO Code", 'E U');
        Assert.ExpectedError(ASCIILetterErr);

        Currency.Validate("ISO Code", 'eUr');
        Currency.TestField("ISO Code", 'EUR');

        Currency.Validate("ISO Code", '');
        Currency.TestField("ISO Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T110_ISONumericCodeIs3Numbers()
    var
        Currency: Record Currency;
    begin
        // [FEATURE] [ISO Code]
        // [SCENARIO] Allowed "ISO Numeric Code" can be blank or must contain 3 numbers
        asserterror Currency.Validate("ISO Numeric Code", CopyStr('1234', 1, 4));
        Assert.ExpectedError('is 4, but it must be less than or equal to 3 characters');

        asserterror Currency.Validate("ISO Numeric Code", '12');
        Assert.ExpectedError('is 2, but it must be equal to 3 characters');

        asserterror Currency.Validate("ISO Numeric Code", '1 3');
        Assert.ExpectedError(NumericErr);

        asserterror Currency.Validate("ISO Numeric Code", 'EU0');
        Assert.ExpectedError(NumericErr);

        Currency.Validate("ISO Numeric Code", '001');
        Currency.TestField("ISO Numeric Code", '001');

        Currency.Validate("ISO Numeric Code", '');
        Currency.TestField("ISO Numeric Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T120_ISOCodesEditableInCurrencyList()
    var
        Currency: Record Currency;
        Currencies: TestPage Currencies;
    begin
        // [FEATURE] [ISO Code] [UI]
        // [SCENARIO] "ISO Code" and "ISO Numeric Code" are editable on the Currencies page
        LibraryApplicationArea.EnableFoundationSetup();
        // [GIVEN] Country 'A', where "ISO Code" is 'YYY', "ISO Numeric Code" is '001'
        Currency.Init();
        Currency.Code := 'A';
        Currency."ISO Code" := 'YYY';
        Currency."ISO Numeric Code" := '001';
        Currency.Insert();

        // [GIVEN] Open Country/Region list page, where both "ISO Code" and "ISO Numeric Code" are editable
        Currencies.OpenEdit();
        Currencies.FILTER.SetFilter(Code, 'A');
        Assert.IsTrue(Currencies."ISO Code".Editable(), 'ISO Code.EDITABLE');
        Assert.IsTrue(Currencies."ISO Numeric Code".Editable(), 'ISO Numeric Code.EDITABLE');
        // [WHEN] set "ISO Code" is 'ZZ', "ISO Numeric Code" is '999' on the page
        Currencies."ISO Code".SetValue('ZZZ');
        Currencies."ISO Numeric Code".SetValue('999');
        Currencies.Close();

        // [THEN] Country 'A', where "ISO Code" is 'ZZZ', "ISO Numeric Code" is '999'
        Currency.Find();
        Currency.TestField("ISO Code", 'ZZZ');
        Currency.TestField("ISO Numeric Code", '999');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T121_ISOCodesEditableInCurrencyCard()
    var
        Currency: Record Currency;
        CurrencyCard: TestPage "Currency Card";
    begin
        // [FEATURE] [ISO Code] [UI]
        // [SCENARIO] "ISO Code" and "ISO Numeric Code" are editable on the Currency Card page
        LibraryApplicationArea.EnableFoundationSetup();
        // [GIVEN] Country 'B', where "ISO Code" is 'YYY', "ISO Numeric Code" is '001'
        Currency.Init();
        Currency.Code := 'B';
        Currency."ISO Code" := 'YYY';
        Currency."ISO Numeric Code" := '001';
        Currency.Insert();

        // [GIVEN] Open Country/Region list page, where both "ISO Code" and "ISO Numeric Code" are editable
        CurrencyCard.OpenEdit();
        CurrencyCard.FILTER.SetFilter(Code, 'B');
        Assert.IsTrue(CurrencyCard."ISO Code".Editable(), 'ISO Code.EDITABLE');
        Assert.IsTrue(CurrencyCard."ISO Numeric Code".Editable(), 'ISO Numeric Code.EDITABLE');
        // [WHEN] set "ISO Code" is 'ZZ', "ISO Numeric Code" is '999' on the page
        CurrencyCard."ISO Code".SetValue('ZZZ');
        CurrencyCard."ISO Numeric Code".SetValue('999');
        CurrencyCard.Close();

        // [THEN] Country 'B', where "ISO Code" is 'ZZZ', "ISO Numeric Code" is '999'
        Currency.Find();
        Currency.TestField("ISO Code", 'ZZZ');
        Currency.TestField("ISO Numeric Code", '999');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckFailedInsetWithBlankCode()
    var
        Currency: Record Currency;
    begin
        // [SCENARIO] Insert Currency with blank Code
        LibraryApplicationArea.EnableFoundationSetup();

        // [GIVEN] Create Currency with blank Code
        Currency.Init();
        Currency.Description := LibraryRandom.RandText(MaxStrLen(Currency.Description));

        // [WHEN] Insert record
        asserterror Currency.Insert(true);

        // [THEN] The TestField Error was shown
        Assert.ExpectedErrorCode('TestField');
    end;
}

