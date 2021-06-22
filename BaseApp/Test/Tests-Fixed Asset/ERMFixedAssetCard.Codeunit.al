codeunit 134456 "ERM Fixed Asset Card"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Fixed Asset] [UI]
    end;

    var
        Assert: Codeunit Assert;
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [Scope('OnPrem')]
    procedure TestFACardSaveSimpleBookOnClose()
    var
        FixedAsset: Record "Fixed Asset";
        FAClass: Record "FA Class";
        FASubclass: Record "FA Subclass";
        FAPostingGroup: Record "FA Posting Group";
        FASetup: Record "FA Setup";
        FixedAssetCard: TestPage "Fixed Asset Card";
        Description: Text[100];
    begin
        // [GIVEN] FA Setup is in place
        FixedAsset.DeleteAll;
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        LibraryFixedAsset.CreateFAClass(FAClass);
        LibraryFixedAsset.CreateFASubclassDetailed(FASubclass, FAClass.Code, FAPostingGroup.Code);
        Description := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(FixedAsset.Description)), 1, MaxStrLen(FixedAsset.Description));

        // [WHEN] Fixed Asset Card filed out and closed
        FixedAssetCard.OpenNew;
        FixedAssetCard.Description.SetValue(Description);
        FixedAssetCard."FA Subclass Code".SetValue(FASubclass.Code);
        FixedAssetCard.Close;

        // [THEN] The Fixed Asset Can be read again
        FixedAssetCard.OpenView;
        FixedAssetCard.Description.AssertEquals(Description);
        FixedAssetCard."FA Subclass Code".SetValue(FASubclass.Code);
        FASetup.Get;
        FixedAssetCard.DepreciationBookCode.AssertEquals(FASetup."Default Depr. Book");
        FixedAssetCard.FAPostingGroup.AssertEquals(FAPostingGroup.Code);
        FixedAssetCard.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFACardSaveSimpleBookOnValidate()
    var
        FixedAsset: Record "Fixed Asset";
        FAClass: Record "FA Class";
        FASubclass: Record "FA Subclass";
        FAPostingGroup: Record "FA Posting Group";
        FAPostingGroup2: Record "FA Posting Group";
        FASetup: Record "FA Setup";
        FADepreciationBook: Record "FA Depreciation Book";
        FixedAssetCard: TestPage "Fixed Asset Card";
        StartingDate: Date;
        EndingDate: Date;
        NoDepreciationYears: Integer;
    begin
        // [GIVEN] FA Setup in place, and a fixed asset with a default depreciation book
        FixedAsset.DeleteAll;
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup2);
        LibraryFixedAsset.CreateFAClass(FAClass);
        LibraryFixedAsset.CreateFASubclassDetailed(FASubclass, FAClass.Code, FAPostingGroup.Code);
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        FASetup.Get;
        CreateFADepreciationBookEmpty(FADepreciationBook, FixedAsset."No.", FASetup."Default Depr. Book", FAPostingGroup.Code);

        FADepreciationBook.Reset;
        FADepreciationBook.Get(FixedAsset."No.", FASetup."Default Depr. Book");

        // [WHEN] Fixed Asset Card is loaded and the Depreciation Book fields are modified
        FixedAssetCard.OpenEdit;
        FixedAssetCard.GotoRecord(FixedAsset);
        FixedAssetCard.DepreciationBookCode.AssertEquals(FASetup."Default Depr. Book");

        // [THEN] The Depreciation Book retains the modified values after the Fixed Asset is reloaded
        FixedAssetCard.FAPostingGroup.SetValue(FAPostingGroup2.Code);
        FADepreciationBook.Get(FixedAsset."No.", FASetup."Default Depr. Book");
        FADepreciationBook.TestField("FA Posting Group", FAPostingGroup2.Code);

        FixedAssetCard.DepreciationMethod.SetValue(FADepreciationBook."Depreciation Method"::"Straight-Line");
        FADepreciationBook.Get(FixedAsset."No.", FASetup."Default Depr. Book");
        FADepreciationBook.TestField("Depreciation Method", FADepreciationBook."Depreciation Method"::"Straight-Line");

        StartingDate := WorkDate - 1;
        FixedAssetCard.DepreciationStartingDate.SetValue(StartingDate);
        FADepreciationBook.Get(FixedAsset."No.", FASetup."Default Depr. Book");
        FADepreciationBook.TestField("Depreciation Starting Date", StartingDate);

        NoDepreciationYears := LibraryRandom.RandIntInRange(1, 20);
        FixedAssetCard.NumberOfDepreciationYears.SetValue(NoDepreciationYears);
        FADepreciationBook.Get(FixedAsset."No.", FASetup."Default Depr. Book");
        FADepreciationBook.TestField("No. of Depreciation Years", NoDepreciationYears);

        EndingDate := WorkDate + 1;
        FixedAssetCard.DepreciationEndingDate.SetValue(EndingDate);
        FADepreciationBook.Get(FixedAsset."No.", FASetup."Default Depr. Book");
        FADepreciationBook.TestField("Depreciation Ending Date", EndingDate);

        FixedAssetCard.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFACardSaveSimpleBookOnNextPrev()
    var
        FixedAsset: Record "Fixed Asset";
        FAClass: Record "FA Class";
        FASubclass: Record "FA Subclass";
        FAPostingGroup: Record "FA Posting Group";
        FAPostingGroup2: Record "FA Posting Group";
        FixedAssetCard: TestPage "Fixed Asset Card";
        Description: Text[100];
    begin
        // [GIVEN] FA Setup is in place
        FixedAsset.DeleteAll;
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup2);
        LibraryFixedAsset.CreateFAClass(FAClass);
        LibraryFixedAsset.CreateFASubclassDetailed(FASubclass, FAClass.Code, FAPostingGroup.Code);
        Description := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(FixedAsset.Description)), 1, MaxStrLen(FixedAsset.Description));

        // [WHEN] Fixed Asset Card filed out and closed
        FixedAssetCard.OpenNew;
        FixedAssetCard.Description.SetValue(Description);
        FixedAssetCard."FA Subclass Code".SetValue(FASubclass.Code);
        FixedAssetCard.Close;

        // [WHEN] Fixed Asset Card filed out with asset 2 and record is moved to first asset
        FixedAssetCard.OpenNew;
        FixedAssetCard.Description.SetValue(Description);
        FixedAssetCard."FA Subclass Code".SetValue(FASubclass.Code);
        FixedAssetCard.FAPostingGroup.SetValue(FAPostingGroup2.Code);
        FixedAssetCard.Previous;

        // [THEN] Fixed asset is saved as expected
        FixedAssetCard.FAPostingGroup.AssertEquals(FAPostingGroup.Code);
        FixedAssetCard.Next;
        FixedAssetCard.FAPostingGroup.AssertEquals(FAPostingGroup2.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFACardSaveSimpleBookOnChangetoMultibook()
    var
        FASetup: Record "FA Setup";
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FAClass: Record "FA Class";
        FASubclass: Record "FA Subclass";
        FAPostingGroup: Record "FA Posting Group";
        FixedAssetCard: TestPage "Fixed Asset Card";
        Description: Text[100];
    begin
        // [GIVEN] FA Setup is in place
        FixedAsset.DeleteAll;
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        LibraryFixedAsset.CreateFAClass(FAClass);
        LibraryFixedAsset.CreateFASubclassDetailed(FASubclass, FAClass.Code, FAPostingGroup.Code);
        Description := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(FixedAsset.Description)), 1, MaxStrLen(FixedAsset.Description));

        // [WHEN] Fixed Asset create with 2 books
        FixedAssetCard.OpenNew;
        FixedAssetCard.Description.SetValue(Description);
        FixedAssetCard."FA Subclass Code".SetValue(FASubclass.Code);
        FixedAssetCard.AddMoreDeprBooks.DrillDown;
        FASetup.Get;
        FixedAssetCard.DepreciationBook."Depreciation Book Code".AssertEquals(FASetup."Default Depr. Book");
        FixedAssetCard.DepreciationBook."FA Posting Group".AssertEquals(FAPostingGroup.Code);
        FixedAssetCard.DepreciationBook.New;
        FixedAssetCard.DepreciationBook."Depreciation Book Code".SetValue(DepreciationBook.Code);
        FixedAssetCard.DepreciationBook."FA Posting Group".SetValue(FAPostingGroup.Code);
        FixedAssetCard.Close;

        // [THEN] both books can be viewd in the card
        FixedAssetCard.OpenView;
        FixedAssetCard.DepreciationBook.GotoKey(FixedAssetCard."No.".Value, FASetup."Default Depr. Book");
        FixedAssetCard.DepreciationBook."FA Posting Group".AssertEquals(FAPostingGroup.Code);
        FixedAssetCard.DepreciationBook.GotoKey(FixedAssetCard."No.".Value, DepreciationBook.Code);
        FixedAssetCard.DepreciationBook."FA Posting Group".AssertEquals(FAPostingGroup.Code);
        FixedAssetCard.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFACardMultibookIsOnlyAccessibleAfterFirstBookCreation()
    var
        FixedAsset: Record "Fixed Asset";
        FASubclass: Record "FA Subclass";
        FixedAssetCard: TestPage "Fixed Asset Card";
        Description: Text[100];
    begin
        // [GIVEN] FA Setup is in place
        FixedAssetAndDeprecationBookSetup(FASubclass);
        Description := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(FixedAsset.Description)), 1, MaxStrLen(FixedAsset.Description));

        // [WHEN] Fixed Asset is created
        FixedAssetCard.OpenNew;
        FixedAssetCard.Description.SetValue(Description);

        // [THEN] AddMoreDeprBooks is not visible until at least one book is created
        Assert.IsFalse(FixedAssetCard.AddMoreDeprBooks.Visible, 'AddMoreDeprBooks has to be invisible.');
        FixedAssetCard."FA Subclass Code".SetValue(FASubclass.Code);
        Assert.IsTrue(FixedAssetCard.AddMoreDeprBooks.Visible, 'AddMoreDeprBooks has to be visible');
        FixedAssetCard.Close;

        FixedAssetCard.OpenView;
        Assert.IsTrue(FixedAssetCard.AddMoreDeprBooks.Visible, 'AddMoreDeprBooks has to be visible');
        FixedAssetCard.Close;
    end;

    [Test]
    [HandlerFunctions('FASubclassValidationHandler')]
    [Scope('OnPrem')]
    procedure TestFACardSubclassRestrictedByClass()
    var
        FASubclassWithNoClass: Record "FA Subclass";
        FAClass1: Record "FA Class";
        FASubclassWithFAClass1Parrent: Record "FA Subclass";
        FAClass2: Record "FA Class";
        FASubclassWithFAClass2Parrent: Record "FA Subclass";
        FixedAssetCard: TestPage "Fixed Asset Card";
    begin
        // [GIVEN] FA Setup is in place
        LibraryFixedAsset.CreateFASubclass(FASubclassWithNoClass);
        LibraryFixedAsset.CreateFAClass(FAClass1);
        LibraryFixedAsset.CreateFASubclassDetailed(FASubclassWithFAClass1Parrent, FAClass1.Code, '');
        LibraryFixedAsset.CreateFAClass(FAClass2);
        LibraryFixedAsset.CreateFASubclassDetailed(FASubclassWithFAClass2Parrent, FAClass2.Code, '');

        // [GIVEN] FAClass1.Code set
        FixedAssetCard.OpenNew;
        FixedAssetCard."FA Class Code".Value := FAClass1.Code;
        LibraryVariableStorage.Enqueue(FASubclassWithNoClass.Code);
        LibraryVariableStorage.Enqueue(FASubclassWithFAClass1Parrent.Code);
        LibraryVariableStorage.Enqueue(FASubclassWithFAClass2Parrent.Code);
        // Validation handler in FASubclassValidationHandler
        // [WHEN] SubClass lookup is invoked
        // [THEN] All but Subclass2 can be found in the lookup
        FixedAssetCard."FA Subclass Code".Lookup;
        FixedAssetCard.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFACardSimpleBookDisposedValue()
    var
        FixedAsset: Record "Fixed Asset";
        FAClass: Record "FA Class";
        FASubclass: Record "FA Subclass";
        FAPostingGroup: Record "FA Posting Group";
        FASetup: Record "FA Setup";
        FADepreciationBook: Record "FA Depreciation Book";
        FixedAssetCard: TestPage "Fixed Asset Card";
        FALedgerEntriesList: TestPage "FA Ledger Entries";
        BookValue: Decimal;
    begin
        // [GIVEN] FA Setup in place, and a disposed fixed asset with a default depreciation book with Amount "A"
        FixedAsset.DeleteAll;
        CreateFAWithClassPostingGroupAndSubclass(FAPostingGroup, FAClass, FASubclass, FixedAsset);
        FASetup.Get;
        BookValue := LibraryRandom.RandDecInRange(10, 1000, 0);
        CreateFADepreciationBookWithValue(
          FADepreciationBook, FixedAsset."No.", FASetup."Default Depr. Book", FAPostingGroup.Code, BookValue);
        DisposeFADepreciationBook(FADepreciationBook, BookValue);

        // [WHEN] Fixed Asset Card is loaded
        FixedAssetCard.OpenEdit;
        FixedAssetCard.GotoRecord(FixedAsset);

        // [THEN] The Depreciation Book value equals 0
        FixedAssetCard.DepreciationBookCode.AssertEquals(FASetup."Default Depr. Book");
        FixedAssetCard.BookValue.AssertEquals(0);

        // [WHEN] Drill Down on "Book Value"
        FALedgerEntriesList.Trap;
        FixedAssetCard.BookValue.DrillDown;
        // [THEN] Page "FA Ledger Entries" showing 1 entries, where total "Amount" is equal to "A"
        FALedgerEntriesList.First;
        FALedgerEntriesList.Amount.AssertEquals(BookValue);
        FALedgerEntriesList.Close;
        FixedAssetCard.Close;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure EnableSaaSNotificationPreferenceSetupOnInitializingNotificationWithDefaultState()
    var
        FixedAsset: Record "Fixed Asset";
        MyNotifications: Record "My Notifications";
        LibraryPermissions: Codeunit "Library - Permissions";
        MyNotificationsPage: TestPage "My Notifications";
    begin
        // [GIVEN] A user
        LibraryPermissions.CreateWindowsUserSecurityID(UserId);

        // [WHEN] My Notifications Page is opened
        MyNotificationsPage.OpenView;

        // [THEN] A notification entry is added to MyNotification for the current user
        MyNotifications.Get(UserId, FixedAsset.GetNotificationID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPictureFactboxExist()
    var
        FixedAsset: Record "Fixed Asset";
        FixedAssetCard: TestPage "Fixed Asset Card";
    begin
        // [Feature] [Fixed Asset]
        // [SCENARIO 210139] Picture Factbox exists on a Fixed Asset Card.

        // [GIVEN] Fixed Asset "FA".
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);

        // [WHEN] Fixed Asset Card page is opened for "FA"
        FixedAssetCard.OpenEdit;
        FixedAssetCard.GotoRecord(FixedAsset);

        // [THEN] Picture Factbox is existing on a Fixed Asset Card page.
        Assert.IsTrue(
          FixedAssetCard.FixedAssetPicture.ImportPicture.Visible,
          'Picture Factbox with Import Picture button is expected');

        Assert.IsTrue(
          FixedAssetCard.FixedAssetPicture.Image.Visible,
          'Picture Factbox with image area is expected');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFACardMultibookDecliningBalancePercentIsVisible()
    var
        FixedAsset: Record "Fixed Asset";
        FASubclass: Record "FA Subclass";
        FixedAssetCard: TestPage "Fixed Asset Card";
        Description: Text[100];
    begin
        // [Feature] [UT]
        // [SCENARIO 234906] Declining Balance % is visible on a Fixed Asset Card.

        // [GIVEN] FA Setup is in place
        FixedAssetAndDeprecationBookSetup(FASubclass);
        Description := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(FixedAsset.Description)), 1, MaxStrLen(FixedAsset.Description));

        // [GIVEN] Fixed Asset is created from Card
        FixedAssetCard.OpenNew;
        FixedAssetCard.Description.SetValue(Description);
        FixedAssetCard."FA Subclass Code".SetValue(FASubclass.Code);

        // [WHEN] Open FA Depreciation Books Subform
        FixedAssetCard.AddMoreDeprBooks.DrillDown;

        // [THEN] "Declining-Balance %" is visible and editable
        Assert.IsTrue(FixedAssetCard.DepreciationBook."Declining-Balance %".Visible, 'Declining-Balance % has to be visible');
        Assert.IsTrue(FixedAssetCard.DepreciationBook."Declining-Balance %".Editable, 'Declining-Balance % has to be editable');

        FixedAssetCard.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FACardSimpleBookValueUndisposed()
    var
        FixedAsset: Record "Fixed Asset";
        FAClass: Record "FA Class";
        FASubclass: Record "FA Subclass";
        FAPostingGroup: Record "FA Posting Group";
        FASetup: Record "FA Setup";
        FADepreciationBook: Record "FA Depreciation Book";
        FixedAssetCard: TestPage "Fixed Asset Card";
        FALedgerEntriesList: TestPage "FA Ledger Entries";
        BookValue: Decimal;
    begin
        // [SCENARIO 281772] Book Value of an undisposed Fixed Asset is shown on "Fixed Asset Card" Simple View

        // [GIVEN] FA Setup with Fixed Asset
        FixedAsset.DeleteAll;
        CreateFAWithClassPostingGroupAndSubclass(FAPostingGroup, FAClass, FASubclass, FixedAsset);
        FASetup.Get;

        // [GIVEN] Default Depreciation Book created for Fixed Asset with Book Value = 500
        BookValue := LibraryRandom.RandDecInRange(10, 1000, 0);
        CreateFADepreciationBookWithValue(
          FADepreciationBook,
          FixedAsset."No.",
          FASetup."Default Depr. Book",
          FAPostingGroup.Code,
          BookValue);

        // [WHEN] Fixed Asset Card is loaded
        FixedAssetCard.OpenEdit;
        FixedAssetCard.FILTER.SetFilter("No.", FixedAsset."No.");

        // [THEN] The Depreciation Book value equals 500
        ValidateBookValueSimple(FixedAssetCard, FASetup."Default Depr. Book", BookValue);

        // [WHEN] Drill Down on "Book Value"
        FALedgerEntriesList.Trap;
        FixedAssetCard.BookValue.DrillDown;
        // [THEN] Page "FA Ledger Entries" showing entry, where "Amount" is 500
        FALedgerEntriesList.First;
        FALedgerEntriesList.Amount.AssertEquals(BookValue);
        FALedgerEntriesList.Close;
        FixedAssetCard.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FACardMultibookDisposedValue()
    var
        FixedAsset: Record "Fixed Asset";
        FASetup: Record "FA Setup";
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
        FASubclass: Record "FA Subclass";
        FAClass: Record "FA Class";
        FixedAssetCard: TestPage "Fixed Asset Card";
    begin
        // [SCENARIO 281772] Book Value of a disposed Fixed Asset is 0 on FA Depreciation Books Subform

        // [GIVEN] FA Setup with Fixed Asset
        FixedAsset.DeleteAll;
        CreateFAWithClassPostingGroupAndSubclass(FAPostingGroup, FAClass, FASubclass, FixedAsset);
        FASetup.Get;

        // [GIVEN] Default Depreciation Book created for Fixed Asset
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FASetup."Default Depr. Book", FAPostingGroup.Code);

        // [GIVEN] Fixed Asset Disposed
        FADepreciationBook."Disposal Date" := WorkDate;
        FADepreciationBook.Modify(true);

        // [GIVEN] Fixed Asset Card is loaded
        FixedAssetCard.OpenEdit;
        FixedAssetCard.FILTER.SetFilter("No.", FixedAsset."No.");

        // [WHEN] FA Depreciation Books Subform is opened
        FixedAssetCard.AddMoreDeprBooks.DrillDown;

        // [THEN] Book Value of the disposed Fixed Asset equals 0
        FixedAssetCard.DepreciationBook."Depreciation Book Code".AssertEquals(FASetup."Default Depr. Book");
        FixedAssetCard.DepreciationBook.BookValue.AssertEquals(0);

        FixedAssetCard.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FACardMultibookBookValueUndisposed()
    var
        FixedAsset: Record "Fixed Asset";
        FASetup: Record "FA Setup";
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
        FASubclass: Record "FA Subclass";
        FAClass: Record "FA Class";
        FixedAssetCard: TestPage "Fixed Asset Card";
        BookValue: Decimal;
    begin
        // [SCENARIO 281772] Book Value of an undisposed Fixed Asset is shown on FA Depreciation Books Subform

        // [GIVEN] FA Setup with Fixed Asset
        FixedAsset.DeleteAll;
        CreateFAWithClassPostingGroupAndSubclass(FAPostingGroup, FAClass, FASubclass, FixedAsset);
        FASetup.Get;

        // [GIVEN] Default Depreciation Book created for Fixed Asset with Book Value = 500
        BookValue := LibraryRandom.RandDecInRange(10, 1000, 0);
        CreateFADepreciationBookWithValue(
          FADepreciationBook,
          FixedAsset."No.",
          FASetup."Default Depr. Book",
          FAPostingGroup.Code,
          BookValue);

        // [GIVEN] Fixed Asset Card is loaded
        FixedAssetCard.OpenEdit;
        FixedAssetCard.FILTER.SetFilter("No.", FixedAsset."No.");

        // [WHEN] FA Depreciation Books Subform is opened
        FixedAssetCard.AddMoreDeprBooks.DrillDown;

        // [THEN] Book Value of the Fixed Asset equals 500
        ValidateBookValueMultibook(FixedAssetCard, FASetup."Default Depr. Book", BookValue);

        FixedAssetCard.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FACardDepreciationTableCode()
    var
        FixedAsset: Record "Fixed Asset";
        FASetup: Record "FA Setup";
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
        FASubclass: Record "FA Subclass";
        FAClass: Record "FA Class";
        DepreciationTableHeader: Record "Depreciation Table Header";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        FixedAssetCard: TestPage "Fixed Asset Card";
    begin
        // [SCENARIO 283323] User is able to setup Depreciation Table Code on the FA Card page

        // [GIVEN] Activate application area #FixedAsset
        LibraryApplicationArea.EnableFixedAssetsSetup;

        // [GIVEN] FA Setup with Fixed Asset
        FixedAsset.DeleteAll;
        CreateFAWithClassPostingGroupAndSubclass(FAPostingGroup, FAClass, FASubclass, FixedAsset);
        FASetup.Get;
        CreateFADepreciationBookEmpty(FADepreciationBook, FixedAsset."No.", FASetup."Default Depr. Book", FAPostingGroup.Code);
        FADepreciationBook.Validate("Depreciation Method", FADepreciationBook."Depreciation Method"::"User-Defined");
        FADepreciationBook.Modify(true);

        // [GIVEN] Create new Depreciation Table Code "DTC"
        LibraryFixedAsset.CreateDepreciationTableHeader(DepreciationTableHeader);

        // [GIVEN] Open FA Card page
        FixedAssetCard.OpenEdit;
        FixedAssetCard.FILTER.SetFilter("No.", FixedAsset."No.");

        // [WHEN] Depreciation Table Code control is being set to "DTC"
        FixedAssetCard.DepreciationTableCode.SetValue(DepreciationTableHeader.Code);
        FixedAssetCard.OK.Invoke;

        // [THEN] FADepreciationBook."Depreciation Table Code" = "DTC"
        FADepreciationBook.Find;
        FADepreciationBook.TestField("Depreciation Table Code", DepreciationTableHeader.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FACardUseHalfYearConvention()
    var
        FixedAsset: Record "Fixed Asset";
        FASetup: Record "FA Setup";
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
        FASubclass: Record "FA Subclass";
        FAClass: Record "FA Class";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        FixedAssetCard: TestPage "Fixed Asset Card";
    begin
        // [SCENARIO 283323] User is able to setup Use Half-Year Convention on the FA Card page

        // [GIVEN] Activate application area #FixedAsset
        LibraryApplicationArea.EnableFixedAssetsSetup;

        // [GIVEN] FA Setup with Fixed Asset
        FixedAsset.DeleteAll;
        CreateFAWithClassPostingGroupAndSubclass(FAPostingGroup, FAClass, FASubclass, FixedAsset);
        FASetup.Get;
        CreateFADepreciationBookEmpty(FADepreciationBook, FixedAsset."No.", FASetup."Default Depr. Book", FAPostingGroup.Code);

        // [GIVEN] Open FA Card page
        FixedAssetCard.OpenEdit;
        FixedAssetCard.FILTER.SetFilter("No.", FixedAsset."No.");

        // [WHEN] Use Half-Year Convention control is being set to TRUE
        FixedAssetCard.UseHalfYearConvention.SetValue(true);
        FixedAssetCard.OK.Invoke;

        // [THEN] FADepreciationBook."Use Half-Year Convention" = TRUE
        FADepreciationBook.Find;
        FADepreciationBook.TestField("Use Half-Year Convention", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFACardBookValueDrillDown()
    var
        FixedAsset: Record "Fixed Asset";
        FAClass: Record "FA Class";
        FASubclass: Record "FA Subclass";
        FAPostingGroup: Record "FA Posting Group";
        FASetup: Record "FA Setup";
        FADepreciationBook: Record "FA Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
        FixedAssetCard: TestPage "Fixed Asset Card";
        FALedgerEntriesList: TestPage "FA Ledger Entries";
        BookValue: Decimal;
    begin
        // [FEATURE] [Disposal] [Book Value]
        // [SCENARIO 283324] Create FA document and disposed it. As a result should be 2 FA Ledger Entries Line.
        // [GIVEN] FA Setup in place, and a disposed fixed asset with a default depreciation book and Amount = "A"
        CreateFAWithClassPostingGroupAndSubclass(FAPostingGroup, FAClass, FASubclass, FixedAsset);
        FASetup.Get;
        BookValue := LibraryRandom.RandDecInRange(10, 1000, 2);
        CreateFADepreciationBookWithValue(
          FADepreciationBook,
          FixedAsset."No.",
          FASetup."Default Depr. Book",
          FAPostingGroup.Code,
          BookValue);
        DisposeFADepreciationBook(FADepreciationBook, BookValue);

        // [WHEN] Fixed Asset Card is loaded and Drill Down on "Book Value"
        FixedAssetCard.OpenEdit;
        FixedAssetCard.FILTER.SetFilter("No.", FixedAsset."No.");
        FALedgerEntriesList.Trap;
        FixedAssetCard.BookValue.DrillDown;

        // [THEN] Page "FA Ledger Entries" have 1 line.
        // [THEN] Page "FA Ledger Entries" showing 1 entries, where total "Amount" is "A",
        // [THEN] First line's amount = "A" ,
        // [THEN] "FA Posting Type" = "Book Value on Disposal" and "FA Posting Category" = 'Disposal'
        FALedgerEntriesList.First;
        Assert.AreEqual(FALedgerEntriesList.Amount.Value, Format(BookValue), 'FA doc.');
        Assert.AreEqual(
          FALedgerEntriesList."FA Posting Type".Value,
          Format(FALedgerEntry."FA Posting Type"::"Book Value on Disposal"),
          FALedgerEntry.FieldCaption("FA Posting Type"));
        Assert.AreEqual(
          FALedgerEntriesList."FA Posting Category".Value,
          Format(FALedgerEntry."FA Posting Category"::Disposal),
          FALedgerEntry.FieldCaption("FA Posting Category"));

        // [THEN] There are no more "FA Ledger Entries" lines.
        Assert.IsFalse(FALedgerEntriesList.Next, 'No more records expected');

        FALedgerEntriesList.Close;
        FixedAssetCard.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFACardBookDisposalValue()
    var
        FixedAsset: Record "Fixed Asset";
        FAClass: Record "FA Class";
        FASubclass: Record "FA Subclass";
        FAPostingGroup: Record "FA Posting Group";
        FASetup: Record "FA Setup";
        FADepreciationBook: Record "FA Depreciation Book";
        DummyFALedgerEntry: Record "FA Ledger Entry";
        FixedAssetStatistics: TestPage "Fixed Asset Statistics";
        FixedAssetCard: TestPage "Fixed Asset Card";
        DisposalValue: Decimal;
    begin
        // [FEATURE] [Disposal] [Disposal Value]
        // [SCENARIO 319366] Create FA document and disposed it. As a result Disposal Value in FA Statistics page must be calculated.
        // [GIVEN] FA Setup in place, and a disposed fixed asset with
        // [GIVEN] FA Posting Type = Book Value on Disposal and "Book Value on Disposal" = "X"
        CreateFAWithClassPostingGroupAndSubclass(FAPostingGroup, FAClass, FASubclass, FixedAsset);
        FASetup.Get;
        DisposalValue := LibraryRandom.RandDecInRange(10, 1000, 2);
        CreateFADepreciationBookWithValue(
          FADepreciationBook, FixedAsset."No.", FASetup."Default Depr. Book", FAPostingGroup.Code, DisposalValue);
        MockFALedgerEntryDisposal(
          FADepreciationBook."FA No.",
          FADepreciationBook."Depreciation Book Code",
          WorkDate, -DisposalValue,
          DummyFALedgerEntry."FA Posting Type"::"Book Value on Disposal");

        // [WHEN] Fixed Asset Statistics."Book Value on Disposal" is calculated. Page FixedAssetStatistics is opened.
        FADepreciationBook.CalcFields("Book Value on Disposal");
        FixedAssetCard.OpenEdit;
        FixedAssetCard.FILTER.SetFilter("No.", FixedAsset."No.");
        FixedAssetStatistics.Trap;
        FixedAssetCard.Statistics.Invoke;

        // [THEN] "Book Value after Disposal" = "X" on FA Statistics Page
        FixedAssetStatistics.DisposalValue.AssertEquals(DisposalValue);
        FixedAssetCard.Close;
        FixedAssetStatistics.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFACardChangeFASubclassWithAllowChangesInDeprField()
    var
        FixedAsset: Record "Fixed Asset";
        FAClass: Record "FA Class";
        FASubclass: array[2] of Record "FA Subclass";
        FAPostingGroup: array[2] of Record "FA Posting Group";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FASetup: Record "FA Setup";
        FixedAssetCard: TestPage "Fixed Asset Card";
    begin
        // [FEATURE] [Posting Group]
        // [SCENARIO 329116] Create FA document and edit FA Subclass in it. The FA Posting Group shouldn't changed.

        // [GIVEN] 3 different FAPostingGroup were created, 3 different FASubclass were created, FAClass and DepreciationBook were created
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup[1]);
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup[2]);
        LibraryFixedAsset.CreateFAClass(FAClass);
        LibraryFixedAsset.CreateFASubclassDetailed(FASubclass[1], FAClass.Code, FAPostingGroup[1].Code);
        LibraryFixedAsset.CreateFASubclassDetailed(FASubclass[2], FAClass.Code, FAPostingGroup[2].Code);

        // [GIVEN] FixedAsset was created with "FA Subclass Code" and "FA Posting Group" equal first's variants.
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        FixedAsset.Validate("FA Class Code", FAClass.Code);
        FixedAsset.Validate("FA Subclass Code", FASubclass[1].Code);
        FixedAsset.Modify(true);

        // [GIVEN] FA Depreciation Book was created with first variant of FA Posting Group.
        FASetup.Get;
        CreateFADepreciationBookEmpty(FADepreciationBook, FixedAsset."No.", FASetup."Default Depr. Book", FAPostingGroup[1].Code);

        // [GIVEN] Field "Allow Changes in Depr. Fields" in  table DepreciationBook =TRUE
        CreateDepreciationBookWithAllowChangesInDeprField(DepreciationBook, true);

        // [WHEN] FA Subclass change in FixedAssetCard to second variant
        FixedAssetCard.OpenEdit;
        FixedAssetCard.FILTER.SetFilter("No.", FixedAsset."No.");
        FixedAssetCard."FA Subclass Code".SetValue(FASubclass[2].Code);
        FixedAssetCard.OK.Invoke;

        // [THEN] The FA Subclass Code was changed, FADepreciationBook."FA Posting Group" was not changed
        FixedAsset.Find;
        FADepreciationBook.Find;
        FixedAsset.TestField("FA Subclass Code", FASubclass[2].Code);
        FADepreciationBook.TestField("FA Posting Group", FAPostingGroup[1].Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFACardChangeFASubclassWithoutAllowChangesInDeprField()
    var
        FixedAsset: Record "Fixed Asset";
        FAClass: Record "FA Class";
        FASubclass: array[2] of Record "FA Subclass";
        FAPostingGroup: array[2] of Record "FA Posting Group";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FASetup: Record "FA Setup";
        FixedAssetCard: TestPage "Fixed Asset Card";
    begin
        // [FEATURE] [Posting Group]
        // [SCENARIO 329116] Create FA document and edit FA Subclass in it. The FA Posting Group shouldn't changed.

        // [GIVEN] 3 different FAPostingGroup were created, 3 different FASubclass were created, FAClass and DepreciationBook were created
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup[1]);
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup[2]);
        LibraryFixedAsset.CreateFAClass(FAClass);
        LibraryFixedAsset.CreateFASubclassDetailed(FASubclass[1], FAClass.Code, FAPostingGroup[1].Code);
        LibraryFixedAsset.CreateFASubclassDetailed(FASubclass[2], FAClass.Code, FAPostingGroup[2].Code);

        // [GIVEN] FixedAsset was created with "FA Subclass Code" and "FA Posting Group" equal first's variants.
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        FixedAsset.Validate("FA Class Code", FAClass.Code);
        FixedAsset.Validate("FA Subclass Code", FASubclass[1].Code);
        FixedAsset.Modify(true);

        // [GIVEN] FA Depreciation Book was created with first variant of FA Posting Group.
        FASetup.Get;
        CreateFADepreciationBookEmpty(FADepreciationBook, FixedAsset."No.", FASetup."Default Depr. Book", FAPostingGroup[1].Code);

        // [GIVEN] Field "Allow Changes in Depr. Fields" in  table DepreciationBook = FALSE
        CreateDepreciationBookWithAllowChangesInDeprField(DepreciationBook, false);

        // [WHEN] FA Subclass change in FixedAssetCard to second variant
        FixedAssetCard.OpenEdit;
        FixedAssetCard.FILTER.SetFilter("No.", FixedAsset."No.");
        FixedAssetCard."FA Subclass Code".SetValue(FASubclass[2].Code);
        FixedAssetCard.OK.Invoke;

        // [THEN] The FA Subclass Code was changed, FADepreciationBook."FA Posting Group" was not changed
        FixedAsset.Find;
        FADepreciationBook.Find;
        FixedAsset.TestField("FA Subclass Code", FASubclass[2].Code);
        FADepreciationBook.TestField("FA Posting Group", FAPostingGroup[1].Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFACardBookDisposalValueOnDrillDown()
    var
        FixedAsset: Record "Fixed Asset";
        FAClass: Record "FA Class";
        FASubclass: Record "FA Subclass";
        FAPostingGroup: Record "FA Posting Group";
        FASetup: Record "FA Setup";
        FADepreciationBook: Record "FA Depreciation Book";
        DummyFALedgerEntry: Record "FA Ledger Entry";
        FixedAssetStatistics: TestPage "Fixed Asset Statistics";
        FixedAssetCard: TestPage "Fixed Asset Card";
        FALedgerEntries: TestPage "FA Ledger Entries";
        DisposalValue: Decimal;
    begin
        // [FEATURE] [Disposal] [Disposal Value]
        // [SCENARIO 330253] It should be no lines in FA Ledger Entries when drilldown Disposal Value from FA Statistics page for FA Document that was not disposed.
        // [GIVEN] FA Setup in place, and a disposed fixed asset with
        // [GIVEN] FA Posting Type = Book Value on Disposal
        // [GIVEN] Disposal Amount = "D"
        FASetup.Get;
        CreateFAWithClassPostingGroupAndSubclass(FAPostingGroup, FAClass, FASubclass, FixedAsset);
        DisposalValue := LibraryRandom.RandDecInRange(10, 1000, 2);
        CreateFADepreciationBookWithValue(
          FADepreciationBook, FixedAsset."No.", FASetup."Default Depr. Book", FAPostingGroup.Code, DisposalValue);

        // [GIVEN] Page FixedAssetStatistics is opened.
        FixedAssetCard.OpenEdit;
        FixedAssetCard.FILTER.SetFilter("No.", FixedAsset."No.");
        FixedAssetStatistics.Trap;
        FixedAssetCard.Statistics.Invoke;
        FALedgerEntries.OpenView;
        FALedgerEntries.Trap;

        // [WHEN] User press DrillDown on the DisposalValue field.
        FixedAssetStatistics.DisposalValue.DrillDown;

        // [THEN] There are no lines in opened page FALedgerEntries.
        Assert.IsTrue(FALedgerEntries.First, 'FA Ledger Entry does not exist after drilldown DispovalValue');

        // [THEN] Line have next parametrs: Amount = "D", FA Posting Type = "Acquisition Cost", FA Posting Category =' '
        Assert.AreEqual(FALedgerEntries.Amount.Value, Format(DisposalValue), 'FA doc.');
        Assert.AreEqual(
          FALedgerEntries."FA Posting Type".Value,
          Format(DummyFALedgerEntry."FA Posting Type"::"Acquisition Cost"),
          DummyFALedgerEntry.FieldCaption("FA Posting Type"));
        Assert.AreEqual(
          FALedgerEntries."FA Posting Category".Value,
          Format(DummyFALedgerEntry."FA Posting Category"::" "),
          DummyFALedgerEntry.FieldCaption("FA Posting Category"));

        // [THEN] There are no more "FA Ledger Entries" lines.
        Assert.IsFalse(FALedgerEntries.Next, 'No more records expected');

        FALedgerEntries.Close;
        FixedAssetCard.Close;
        FixedAssetStatistics.Close;
    end;

    local procedure FixedAssetAndDeprecationBookSetup(var FASubclass: Record "FA Subclass")
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FAClass: Record "FA Class";
        FAPostingGroup: Record "FA Posting Group";
    begin
        FixedAsset.DeleteAll;
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        LibraryFixedAsset.CreateFAClass(FAClass);
        LibraryFixedAsset.CreateFASubclassDetailed(FASubclass, FAClass.Code, FAPostingGroup.Code);
    end;

    [Scope('OnPrem')]
    procedure CreateFADepreciationBook(var FADepreciationBook: Record "FA Depreciation Book"; FANo: Code[20]; DepreciationBookCode: Code[10]; PostingGroupCode: Code[20])
    begin
        CreateFADepreciationBookWithValue(
          FADepreciationBook,
          FANo,
          DepreciationBookCode,
          PostingGroupCode,
          LibraryRandom.RandDecInRange(10, 1000, 0));
    end;

    [Scope('OnPrem')]
    procedure CreateFADepreciationBookEmpty(var FADepreciationBook: Record "FA Depreciation Book"; FANo: Code[20]; DepreciationBookCode: Code[10]; PostingGroupCode: Code[20])
    begin
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FANo, DepreciationBookCode);
        FADepreciationBook."FA Posting Group" := PostingGroupCode;
        FADepreciationBook."Depreciation Method" := FADepreciationBook."Depreciation Method"::"Declining-Balance 1";
        FADepreciationBook."Depreciation Starting Date" := 0D;
        FADepreciationBook."Depreciation Ending Date" := 0D;
        FADepreciationBook.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateFADepreciationBookWithValue(var FADepreciationBook: Record "FA Depreciation Book"; FANo: Code[20]; DepreciationBookCode: Code[10]; PostingGroupCode: Code[20]; BookValue: Decimal)
    begin
        CreateFADepreciationBookEmpty(FADepreciationBook, FANo, DepreciationBookCode, PostingGroupCode);
        MockFALedgerEntryBookValue(FANo, DepreciationBookCode, WorkDate, BookValue);
    end;

    local procedure DisposeFADepreciationBook(var FADepreciationBook: Record "FA Depreciation Book"; BookValue: Decimal)
    var
        DummyFALedgerEntry: Record "FA Ledger Entry";
    begin
        MockFALedgerEntryDisposal(
          FADepreciationBook."FA No.",
          FADepreciationBook."Depreciation Book Code",
          WorkDate, BookValue,
          DummyFALedgerEntry."FA Posting Type"::"Acquisition Cost");
        MockFALedgerEntryDisposal(
          FADepreciationBook."FA No.",
          FADepreciationBook."Depreciation Book Code",
          WorkDate, -BookValue,
          DummyFALedgerEntry."FA Posting Type"::"Book Value on Disposal");
        FADepreciationBook."Disposal Date" := WorkDate;
        FADepreciationBook.Modify(true);
    end;

    local procedure MockFALedgerEntryBookValue(FANo: Code[20]; DepreciationBookCode: Code[10]; FAPostingDate: Date; BookValueAmount: Decimal)
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        with FALedgerEntry do begin
            Init;
            "Entry No." := LibraryUtility.GetNewRecNo(FALedgerEntry, FieldNo("Entry No."));
            "FA No." := FANo;
            "Depreciation Book Code" := DepreciationBookCode;
            "Part of Book Value" := true;
            "FA Posting Date" := FAPostingDate;
            Amount := BookValueAmount;
            Insert;
        end;
    end;

    local procedure MockFALedgerEntryDisposal(FANo: Code[20]; DepreciationBookCode: Code[10]; FAPostingDate: Date; BookValueAmount: Decimal; FAPostingType: Option)
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        with FALedgerEntry do begin
            Init;
            "Entry No." := LibraryUtility.GetNewRecNo(FALedgerEntry, FieldNo("Entry No."));
            "FA No." := FANo;
            "Depreciation Book Code" := DepreciationBookCode;
            "FA Posting Category" := "FA Posting Category"::Disposal;
            "FA Posting Type" := FAPostingType;
            "FA Posting Date" := FAPostingDate;
            Amount := -BookValueAmount;
            Insert;
        end;
    end;

    local procedure ValidateBookValueMultibook(FixedAssetCard: TestPage "Fixed Asset Card"; DepreciationBookCode: Code[10]; BookValue: Decimal)
    begin
        FixedAssetCard.DepreciationBook."Depreciation Book Code".AssertEquals(DepreciationBookCode);
        FixedAssetCard.DepreciationBook.BookValue.AssertEquals(BookValue);
    end;

    local procedure ValidateBookValueSimple(FixedAssetCard: TestPage "Fixed Asset Card"; DepreciationBookCode: Code[10]; BookValue: Decimal)
    begin
        FixedAssetCard.DepreciationBookCode.AssertEquals(DepreciationBookCode);
        FixedAssetCard.BookValue.AssertEquals(BookValue);
    end;

    local procedure CreateFAWithClassPostingGroupAndSubclass(var FAPostingGroup: Record "FA Posting Group"; var FAClass: Record "FA Class"; var FASubclass: Record "FA Subclass"; var FixedAsset: Record "Fixed Asset")
    begin
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        LibraryFixedAsset.CreateFAClass(FAClass);
        LibraryFixedAsset.CreateFASubclassDetailed(FASubclass, FAClass.Code, FAPostingGroup.Code);
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
    end;

    [Scope('OnPrem')]
    procedure CreateDepreciationBookWithAllowChangesInDeprField(var DepreciationBook: Record "Depreciation Book"; AllowChangesInDeprFields: Boolean)
    begin
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        DepreciationBook.Validate("Allow Changes in Depr. Fields", AllowChangesInDeprFields);
        DepreciationBook.Modify(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure FASubclassValidationHandler(var FASubclasses: TestPage "FA Subclasses")
    var
        SubclassCode: Code[10];
    begin
        SubclassCode := CopyStr(LibraryVariableStorage.DequeueText, 1, MaxStrLen(SubclassCode));
        Assert.IsTrue(FASubclasses.FindFirstField(Code, SubclassCode), SubclassCode + ' should be include in lookup');

        SubclassCode := CopyStr(LibraryVariableStorage.DequeueText, 1, MaxStrLen(SubclassCode));
        Assert.IsTrue(FASubclasses.FindFirstField(Code, SubclassCode), SubclassCode + ' should be include in lookup');

        SubclassCode := CopyStr(LibraryVariableStorage.DequeueText, 1, MaxStrLen(SubclassCode));
        Assert.IsFalse(FASubclasses.FindFirstField(Code, SubclassCode), SubclassCode + ' should not be include in lookup');
    end;
}

