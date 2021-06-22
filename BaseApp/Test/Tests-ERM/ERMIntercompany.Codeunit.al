codeunit 134151 "ERM Intercompany"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Intercompany]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        IsInitialized: Boolean;
        BlockedErr: Label 'You cannot create this type of document when %1 %2 is blocked with type %3', Locked = true;
        ICAccountErr: Label '%1 must have a value in %2: %3=%4, %5=%6, %7=%8. It cannot be zero or empty.', Locked = true;
        BlockedICPartnerErr: Label '%1 %2 is linked to a blocked IC Partner.', Locked = true;
        ValidationErr: Label '%1 must be %2 in %3.', Locked = true;
        AccountNo: Code[20];
        GLAccountNo: Code[20];
        AccountType: Text[30];
        Amount2: Decimal;
        ICPartnerBlockedErr: Label '%1 must be equal to ''%2''  in %3: %4=%5. Current value is ''%6''.', Locked = true;
        ValueMustExistErr: Label '%1 must have a value in %2: %3=%4. It cannot be zero or empty.', Locked = true;
        AccountValidationErr: Label 'You cannot enter G/L Account or Bank Account in both %1 and %2.', Locked = true;
        EntryMustExistErr: Label '%1 must exist.', Locked = true;
        SameICPartnerErr: Label 'The %1 %2 has been assigned to %3 %4.', Locked = true;
        BlankCodeErr: Label 'Validation error for Field: %1,  Message = ''%1 must be filled in. Enter a value.''', Locked = true;
        OpenEntryDeleteErr: Label 'You cannot delete IC Partner %1 because it has ledger entries in a fiscal year that has not been closed yet.', Locked = true;
        CustomerDeleteErr: Label 'You cannot delete IC Partner %1 because it is used for Customer %2', Locked = true;
        VendorDeleteErr: Label 'You cannot delete IC Partner %1 because it is used for Vendor %2', Locked = true;
        RemoveICPartnerErr: Label 'You cannot change the contents of the IC Partner Code field because this %1 has one or more open ledger entries.', Locked = true;
        AccountErr: Label '%1 must have a value in IC Partner: Code=%2. It cannot be zero or empty.', Locked = true;
        EntryMustNotExistErr: Label '%1 must not exist.', Locked = true;
        ICPartnerGLAccountNoErr: Label '%1 must be equal to ''%2''  in %3: %4=%5, %6=%7, %8=%9. Current value is ''%10''.', Locked = true;
        BlockedDimValueErr: Label '%1 %2 - %3 is blocked.', Locked = true;
        BlockedDimensionErr: Label '%1 %2 is blocked.', Locked = true;
        OutOfBalanceErr: Label '%1 %2 is out of balance by %3. Please check that %4, %5, %6 and %7 are correct for each line.', Locked = true;
        InsertDuplicateKeyPassedTxt: Label 'Inserting duplicate values into the IC Outbox Jnl. Line table should have failed.';
        RecordExistsErr: Label 'DB:RecordExists';
        TransAlreadyExistErr: Label 'Transaction %1 for %2 %3 already exists in the %4 table.', Locked = true;
        BlockedPrivacyBlockedErr: Label 'You cannot create this type of document when %1 %2 is blocked for privacy.', Locked = true;

    [Test]
    [Scope('OnPrem')]
    procedure BlockedAllForVendor()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
    begin
        // Check error while creating IC Journal Line for Blocked Vendor with All.

        // Setup.
        Initialize;
        VendorNo := CreateVendor(Vendor.Blocked::All, CreateICPartner);

        // Exercise: Create IC Journal Line with random values, take -1 for sign factor.
        LibraryLowerPermissions.SetIntercompanyPostingsEdit;
        LibraryLowerPermissions.AddJournalsEdit;
        asserterror CreateICJournalLine(
            GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, VendorNo, -1);

        // Verify: Verify error message.
        Assert.ExpectedError(StrSubstNo(BlockedErr, Vendor.TableCaption, VendorNo, Vendor.Blocked::All));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlockedPaymentForVendor()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        ICOutboxTransaction: Record "IC Outbox Transaction";
    begin
        // Check values on the IC Outbox Transaction for Blocked Vendor with Payment.

        // Setup: Taking -1 for sign factor.
        Initialize;
        CreateAndUpdateICJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor,
          CreateVendor(Vendor.Blocked::Payment, CreateICPartner), -1);

        // Exercise: Post the General Journal Line.
        LibraryLowerPermissions.SetJournalsPost;
        LibraryLowerPermissions.AddIntercompanyPostingsEdit;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify values on IC Outbox Transactions.
        Assert.IsTrue(
          FindICOutboxTransaction(
            ICOutboxTransaction, GenJournalLine."IC Partner Code", GenJournalLine."Document Type", GenJournalLine."Document No."),
          StrSubstNo(EntryMustExistErr, ICOutboxTransaction.TableCaption));

        // Tear Down.
        LibraryLowerPermissions.SetOutsideO365Scope;
        DeleteGeneralJournalBatch(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlockedAllForVendorWithBlockedICPartner()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
    begin
        // Check error while creating General Journal Line for Blocked IC Partner and Blocked Vendor with All.

        // Setup.
        Initialize;
        VendorNo := CreateVendor(Vendor.Blocked::All, CreateICPartner);

        // Exercise: Create General Journal Line with random values, take -1 for sign factor.
        LibraryLowerPermissions.SetIntercompanyPostingsEdit;
        LibraryLowerPermissions.AddIntercompanyPostingsSetup;
        LibraryLowerPermissions.AddO365Setup;
        asserterror CreateAndUpdateICJournalLine(
            GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, VendorNo, -1);

        // Verify: Verify error message.
        Assert.ExpectedError(StrSubstNo(BlockedErr, Vendor.TableCaption, VendorNo, Vendor.Blocked::All));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlockedPaymentForVendorWithBlockedICPartner()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        ICOutboxTransaction: Record "IC Outbox Transaction";
    begin
        // Check values on the IC Outbox Transaction for Blocked IC Partner and Blocked Vendor with Payment.

        // Setup: Taking -1 for sign factor.
        Initialize;
        CreateAndUpdateICJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor,
          CreateVendor(Vendor.Blocked::Payment, CreateICPartner), -1);

        // Exercise: Post the General Journal Line.
        LibraryLowerPermissions.SetJournalsPost;
        LibraryLowerPermissions.AddIntercompanyPostingsEdit;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify values on IC Outbox Transactions.
        Assert.IsTrue(
          FindICOutboxTransaction(
            ICOutboxTransaction, GenJournalLine."IC Partner Code", GenJournalLine."Document Type", GenJournalLine."Document No."),
          StrSubstNo(EntryMustExistErr, ICOutboxTransaction.TableCaption));

        // Tear Down: Setup default values.
        LibraryLowerPermissions.SetOutsideO365Scope;
        DeleteGeneralJournalBatch(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostICJournalLineWithGLAccountAndBalanceAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
        ICGLAccount: Record "IC G/L Account";
        DocumentNo: Code[20];
    begin
        // Check error while posting two General Journal Lines with G/L Account No. and Balance Account Number.

        // Setup: Create General Journal Batch and two General Journal Lines, take Random Amount.
        Initialize;
        CreateICJournalBatch(GenJournalBatch);
        CreateICGLAccount(ICGLAccount);
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::"IC Partner", CreateICPartner, LibraryRandom.RandDec(100, 2));
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", -GenJournalLine.Amount);
        UpdateICJournalLine(GenJournalLine, DocumentNo, ICGLAccount."Map-to G/L Acc. No.", ICGLAccount."No.");
        GenJournalLine.Validate("Document No.", DocumentNo);
        GenJournalLine.Modify(true);

        // Exercise: Post the General Journal Line.
        LibraryLowerPermissions.SetJournalsPost;
        LibraryLowerPermissions.AddIntercompanyPostingsEdit;
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify error message.
        Assert.ExpectedError(
          StrSubstNo(AccountValidationErr, GenJournalLine.FieldCaption("Account No."), GenJournalLine.FieldCaption("Bal. Account No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostICJournalLineWithBalanceAccountNoBlank()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        ICOutboxJnlLine: Record "IC Outbox Jnl. Line";
        ICGLAccount: Record "IC G/L Account";
        DocumentNo: Code[20];
        ICPartnerCode: Code[20];
        Amount: Decimal;
    begin
        // Check values on the IC Outbox Transaction after posting of two General Journal Lines with Balance Account No. blank.

        // Setup: Create General Journal Batch and General Journal Lines, take Random Amount.
        Initialize;
        CreateICJournalBatch(GenJournalBatch);
        CreateICGLAccount(ICGLAccount);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::"IC Partner", CreateICPartner, LibraryRandom.RandDec(100, 2));
        ICPartnerCode := GenJournalLine."Account No.";
        Amount := GenJournalLine.Amount;
        DocumentNo := GenJournalLine."Document No.";

        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::"G/L Account", ICGLAccount."Map-to G/L Acc. No.", -Amount);
        GenJournalLine.Validate("Document No.", DocumentNo);
        GenJournalLine.Validate("IC Partner Code", CreateICPartner);
        GenJournalLine.Validate("IC Partner G/L Acc. No.", ICGLAccount."No.");
        GenJournalLine.Modify(true);

        // Exercise: Post the General Journal Line.
        LibraryLowerPermissions.SetJournalsPost;
        LibraryLowerPermissions.AddIntercompanyPostingsEdit;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Account and IC Partner GL Account Entries in IC Outbox Journal Line.
        VerifyICOutboxJournalLine(
          ICPartnerCode, ICOutboxJnlLine."Account Type"::"IC Partner", ICPartnerCode, GenJournalLine."Document No.", Amount);
        VerifyICOutboxJournalLine(
          ICPartnerCode, ICOutboxJnlLine."Account Type"::"G/L Account", ICGLAccount."No.", GenJournalLine."Document No.",
          GenJournalLine.Amount);

        // Tear Down.
        DeleteGeneralJournalBatch(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostICJournalLineWithoutICPartnerAccountNo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
    begin
        // Check values on the IC Outbox Transaction after posting of two General Journal Lines.

        // Setup: Create General Journal Batch and General Journal Line, take Random Amount.
        Initialize;
        LibraryERM.CreateGLAccount(GLAccount);
        CreateICJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::"IC Partner", CreateICPartner, LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalLine.Modify(true);

        // Exercise: Post the General Journal Line.
        LibraryLowerPermissions.SetJournalsPost;
        LibraryLowerPermissions.AddIntercompanyPostingsEdit;
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify error message.
        Assert.ExpectedError(
          StrSubstNo(
            ICAccountErr, GenJournalLine.FieldCaption("IC Partner G/L Acc. No."), GenJournalLine.TableCaption,
            GenJournalLine.FieldCaption("Journal Template Name"), GenJournalLine."Journal Template Name",
            GenJournalLine.FieldCaption("Journal Batch Name"), GenJournalLine."Journal Batch Name",
            GenJournalLine.FieldCaption("Line No."), GenJournalLine."Line No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostICJournalLineWithoutBalanceAccountAndICPartner()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
        DocumentNo: Code[20];
    begin
        // Check error while posting two General Journal Lines without Balance Account No. and IC Partner Number.

        // Setup: Create General Journal Batch and two General Journal Lines, take Random Amount.
        Initialize;
        LibraryERM.CreateGLAccount(GLAccount);
        CreateICJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::"IC Partner", CreateICPartner, LibraryRandom.RandDec(100, 2));
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", -GenJournalLine.Amount);
        GenJournalLine.Validate("Document No.", DocumentNo);
        GenJournalLine.Modify(true);

        // Exercise: Post the General Journal Line.
        LibraryLowerPermissions.SetJournalsPost;
        LibraryLowerPermissions.AddIntercompanyPostingsEdit;
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify error message.
        Assert.ExpectedError(
          StrSubstNo(
            ICAccountErr, GenJournalLine.FieldCaption("IC Partner G/L Acc. No."), GenJournalLine.TableCaption,
            GenJournalLine.FieldCaption("Journal Template Name"), GenJournalLine."Journal Template Name",
            GenJournalLine.FieldCaption("Journal Batch Name"), GenJournalLine."Journal Batch Name",
            GenJournalLine.FieldCaption("Line No."), GenJournalLine."Line No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerBlockedAllError()
    var
        Customer: Record Customer;
    begin
        // Check Error Message while using a Customer with blocked All and unblocked IC Partner on IC Journal Line.
        Initialize;

        LibraryLowerPermissions.SetIntercompanyPostingsEdit;
        LibraryLowerPermissions.AddIntercompanyPostingsSetup;
        LibraryLowerPermissions.AddO365Setup;
        CreateICJournalLineWithCustomerAndICPartner(Customer.Blocked::All, CreateICPartner);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerBlockedInvoiceError()
    var
        Customer: Record Customer;
    begin
        // Check error message while using a Customer with blocked Invoice and unblocked IC Partner on IC Journal Line.
        Initialize;

        LibraryLowerPermissions.SetIntercompanyPostingsEdit;
        LibraryLowerPermissions.AddIntercompanyPostingsSetup;
        LibraryLowerPermissions.AddO365Setup;
        CreateICJournalLineWithCustomerAndICPartner(Customer.Blocked::Invoice, CreateICPartner);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerBlockedAllWithBlockedICPartnerError()
    var
        Customer: Record Customer;
    begin
        // Check error message while using a Customer with blocked All and blocked IC Partner on IC Journal Line.
        Initialize;

        LibraryLowerPermissions.SetIntercompanyPostingsEdit;
        LibraryLowerPermissions.AddIntercompanyPostingsSetup;
        LibraryLowerPermissions.AddO365Setup;
        CreateICJournalLineWithCustomerAndICPartner(Customer.Blocked::All, UpdateICPartnerBlocked(CreateICPartner, true));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerBlockedInvoiceWithBlockedICPartnerError()
    var
        Customer: Record Customer;
    begin
        // Check error message while using a Customer with blocked Invoice and blocked IC Partner on IC Journal Line.
        Initialize;

        LibraryLowerPermissions.SetIntercompanyPostingsEdit;
        LibraryLowerPermissions.AddIntercompanyPostingsSetup;
        LibraryLowerPermissions.AddO365Setup;
        CreateICJournalLineWithCustomerAndICPartner(Customer.Blocked::Invoice, UpdateICPartnerBlocked(CreateICPartner, true));
    end;

    local procedure CreateICJournalLineWithCustomerAndICPartner(CustomerBlocked: Option " ",Ship,Invoice,All; ICPartnerCode: Code[20])
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        CustomerNo: Code[20];
    begin
        // Setup: Create Customer with Blocked Options and IC Partner.
        CustomerNo := CreateCustomer(CustomerBlocked, ICPartnerCode);

        // Exercise: Create IC Journal Line. Taking 1 for sign factor.
        asserterror CreateICJournalLine(
            GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, CustomerNo, 1);

        // Verify: Verify Error Message.
        Assert.ExpectedError(StrSubstNo(BlockedErr, Customer.TableCaption, CustomerNo, CustomerBlocked));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerBlockedShipICGLAccountError()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        CustomerNo: Code[20];
    begin
        // Check IC GL Account error while creating IC Journal Lines for a Customer with blocked Ship and Unblocked IC Partner.

        // Setup: Create IC Journal Batch and Customer with IC Partner and Blocked Ship, Create IC Journal Line with Balance Account as GL Account.
        Initialize;
        CustomerNo := CreateCustomer(Customer.Blocked::Ship, CreateICPartner);
        LibraryERM.CreateGLAccount(GLAccount);
        CreateICJournalLine(GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, CustomerNo, 1);  // Taking 1 for sign factor.
        GenJournalLine.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalLine.Modify(true);

        // Exercise: Post IC Journal Line.
        LibraryLowerPermissions.SetJournalsPost;
        LibraryLowerPermissions.AddIntercompanyPostingsEdit;
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Error Message.
        Assert.ExpectedError(
          StrSubstNo(
            ICAccountErr, GenJournalLine.FieldCaption("IC Partner G/L Acc. No."), GenJournalLine.TableCaption,
            GenJournalLine.FieldCaption("Journal Template Name"), GenJournalLine."Journal Template Name",
            GenJournalLine.FieldCaption("Journal Batch Name"), GenJournalLine."Journal Batch Name",
            GenJournalLine.FieldCaption("Line No."), GenJournalLine."Line No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerBlockedShipPosting()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        ICOutboxJnlLine: Record "IC Outbox Jnl. Line";
    begin
        // Check IC Outbox Journal Entries after posting IC Journal Line with Customer blocked Ship and unblocked IC Partner.

        // Setup: Create Customer with blocked Ship and unblocked IC Partner, Create and update IC Journal Line, Taking 1 for sign factor.
        Initialize;
        CreateAndUpdateICJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer,
          CreateCustomer(Customer.Blocked::Ship, CreateICPartner), 1);

        // Exercise: Post IC Journal Line.
        LibraryLowerPermissions.SetJournalsPost;
        LibraryLowerPermissions.AddIntercompanyPostingsEdit;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Account and IC Partner GL Account Entries in IC Outbox Journal Line.
        VerifyICOutboxJournalLine(
          GenJournalLine."IC Partner Code", ICOutboxJnlLine."Account Type"::Customer, GenJournalLine."Account No.",
          GenJournalLine."Document No.", GenJournalLine.Amount);
        VerifyICOutboxJournalLine(
          GenJournalLine."IC Partner Code", ICOutboxJnlLine."Account Type"::"G/L Account", GenJournalLine."IC Partner G/L Acc. No.",
          GenJournalLine."Document No.", -GenJournalLine.Amount);

        // Tear Down: Delete newly created batch.
        DeleteGeneralJournalBatch(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerBlockedShipWithBlockedICPartnerError()
    var
        Customer: Record Customer;
    begin
        // Check Error Message while creating IC Journal Line with Customer blocked Ship and blocked IC Partner.
        Initialize;

        LibraryLowerPermissions.SetIntercompanyPostingsEdit;
        LibraryLowerPermissions.AddIntercompanyPostingsSetup;
        LibraryLowerPermissions.AddO365Setup;
        LibraryLowerPermissions.AddJournalsEdit;
        ICJournalLineWithCustomerAndICPartner(Customer.Blocked::Ship);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerWithBlockedICPartnerError()
    var
        Customer: Record Customer;
    begin
        // Check Error Message while creating IC Journal Line with Customer having blocked IC Partner.
        Initialize;

        LibraryLowerPermissions.SetIntercompanyPostingsEdit;
        LibraryLowerPermissions.AddIntercompanyPostingsSetup;
        LibraryLowerPermissions.AddO365Setup;
        ICJournalLineWithCustomerAndICPartner(Customer.Blocked::" ");
    end;

    local procedure ICJournalLineWithCustomerAndICPartner(Blocked: Option)
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        CustomerNo: Code[20];
    begin
        // Setup: Create Customer with blocked IC Partner.
        CustomerNo := CreateCustomer(Blocked, UpdateICPartnerBlocked(CreateICPartner, true));

        // Exercise: Create IC Journal Line, Taking 1 for sign factor.
        asserterror CreateICJournalLine(
            GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, CustomerNo, 1);

        // Verify: Verify Error Message.
        Assert.ExpectedError(StrSubstNo(BlockedICPartnerErr, Customer.TableCaption, CustomerNo));
    end;

    [Test]
    [HandlerFunctions('ICOutboxJnlLinesPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerWithUnblockedICPartner()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        CustomerNo: Code[20];
    begin
        // Check IC Outbox Journal Entries after posting IC Journal Line with Customer having unblocked IC Partner.
        Initialize;
        CustomerNo := CreateCustomer(Customer.Blocked::" ", CreateICPartner);

        LibraryLowerPermissions.SetIntercompanyPostingsEdit;
        LibraryLowerPermissions.AddJournalsPost;
        LibraryLowerPermissions.AddO365Setup;
        LibraryLowerPermissions.AddIntercompanyPostingsSetup;
        PostICPartnerLinkedWithCustomer(GenJournalLine."Account Type"::Customer, CustomerNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICJournalLinePostAfterBlockingICPartner()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        CustomerNo: Code[20];
    begin
        // Check Error Message while posting IC Journal Line and IC Partner Blocked after IC General Line creation.

        // Setup: Create Customer with unblocked IC Partner, Create and update IC Journal Line, taking 1 for sign factor.
        Initialize;
        CreateAndUpdateICJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer,
          CreateCustomer(Customer.Blocked::" ", CreateICPartner), 1);
        CustomerNo := GenJournalLine."Account No.";
        UpdateICPartnerBlocked(GenJournalLine."IC Partner Code", true);

        // Exercise: Post IC Journal Line.
        LibraryLowerPermissions.SetJournalsPost;
        LibraryLowerPermissions.AddIntercompanyPostingsEdit;
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Error Message.
        Assert.ExpectedError(StrSubstNo(BlockedICPartnerErr, Customer.TableCaption, CustomerNo));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlockICPartnerAfterCreatingICJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ICPartner: Record "IC Partner";
        ICPartnerCode: Code[20];
    begin
        // Verify Error Message when IC Partner is used in IC Journal Line and updated as Blocked before posting IC Journal Line.

        // Setup: Create IC Journal Line for IC Partner, Block IC Partner after creating IC Journal Line, taking 1 for sign factor.
        Initialize;
        CreateAndUpdateICJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"IC Partner", CreateICPartner, 1);
        ICPartnerCode := GenJournalLine."Account No.";
        UpdateICPartnerBlocked(ICPartnerCode, true);

        // Exercise: Post IC Journal Line.
        LibraryLowerPermissions.SetJournalsPost;
        LibraryLowerPermissions.AddIntercompanyPostingsEdit;
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Error Message.
        Assert.ExpectedError(
          StrSubstNo(
            ICPartnerBlockedErr, ICPartner.FieldCaption(Blocked), false, ICPartner.TableCaption, ICPartner.FieldCaption(Code),
            ICPartnerCode, true));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlockICPartnerBeforeCreatingICJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ICPartner: Record "IC Partner";
        ICPartnerCode: Code[20];
    begin
        // Verify Error Message while using blocked IC Partner in IC Journal Line.

        // Setup: Create blocked IC Partner.
        Initialize;
        ICPartnerCode := UpdateICPartnerBlocked(CreateICPartner, true);

        // Exercise: Create IC Journal Line for IC Partner, taking 1 for sign factor.
        LibraryLowerPermissions.SetJournalsPost;
        LibraryLowerPermissions.AddIntercompanyPostingsEdit;
        asserterror CreateICJournalLine(
            GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"IC Partner", ICPartnerCode, 1);

        // Verify: Verify Error Message.
        Assert.ExpectedError(
          StrSubstNo(
            ICPartnerBlockedErr, ICPartner.FieldCaption(Blocked), false, ICPartner.TableCaption, ICPartner.FieldCaption(Code),
            ICPartnerCode, true));
    end;

    [Test]
    [HandlerFunctions('ICOutboxJnlLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ICPartnerLinkedToNonBlockedCustomer()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        AccountNumber: Code[20];
    begin
        // Check IC Outbox Journal Entries after posting IC Journal Line with unblocked IC Partner linked with unblocked Customer.
        Initialize;
        AccountNumber := CreateICPartner;
        CreateCustomer(Customer.Blocked::" ", AccountNumber);

        LibraryLowerPermissions.SetIntercompanyPostingsEdit;
        LibraryLowerPermissions.AddJournalsPost;
        LibraryLowerPermissions.AddO365Setup;
        LibraryLowerPermissions.AddIntercompanyPostingsSetup;
        PostICPartnerLinkedWithCustomer(GenJournalLine."Account Type"::"IC Partner", AccountNumber);
    end;

    [Test]
    [HandlerFunctions('ICOutboxJnlLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ICPartnerLinkedToCustomerBlockedAsAll()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        AccountNumber: Code[20];
    begin
        // Check IC Outbox Journal Entries after posting IC Journal Line with unblocked IC Partner linked with Customer and Vendor Blocked as ALL.
        Initialize;
        AccountNumber := CreateICPartner;
        CreateCustomer(Customer.Blocked::All, AccountNumber);
        CreateVendor(Vendor.Blocked::All, AccountNumber);

        LibraryLowerPermissions.SetIntercompanyPostingsEdit;
        LibraryLowerPermissions.AddJournalsPost;
        LibraryLowerPermissions.AddO365Setup;
        LibraryLowerPermissions.AddIntercompanyPostingsSetup;
        PostICPartnerLinkedWithCustomer(GenJournalLine."Account Type"::"IC Partner", AccountNumber);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrivacyBlockedForVendor()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
    begin
        // Check error while creating IC Journal Line for Blocked Vendor with Privacy.

        // Setup.
        Initialize;
        VendorNo := CreateVendor(Vendor.Blocked::All, CreateICPartner);
        Vendor.Get(VendorNo);
        Vendor.Validate("Privacy Blocked", true);
        Vendor.Modify();

        // Exercise: Create IC Journal Line with random values, take -1 for sign factor.
        LibraryLowerPermissions.SetIntercompanyPostingsEdit;
        LibraryLowerPermissions.AddJournalsEdit;
        asserterror CreateICJournalLine(
            GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, VendorNo, -1);

        // Verify: Verify error message.
        Assert.ExpectedError(StrSubstNo(BlockedPrivacyBlockedErr, Vendor.TableCaption, VendorNo));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrivacyBlockedForVendorWithBlockedICPartner()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
    begin
        // Check error while creating General Journal Line for Blocked IC Partner and Blocked Vendor with Privacy.

        // Setup.
        Initialize;
        VendorNo := CreateVendor(Vendor.Blocked::All, CreateICPartner);
        Vendor.Get(VendorNo);
        Vendor.Validate("Privacy Blocked", true);
        Vendor.Modify();

        // Exercise: Create General Journal Line with random values, take -1 for sign factor.
        LibraryLowerPermissions.SetIntercompanyPostingsEdit;
        LibraryLowerPermissions.AddIntercompanyPostingsSetup;
        LibraryLowerPermissions.AddO365Setup;
        asserterror CreateAndUpdateICJournalLine(
            GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, VendorNo, -1);

        // Verify: Verify error message.
        Assert.ExpectedError(StrSubstNo(BlockedPrivacyBlockedErr, Vendor.TableCaption, VendorNo));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerPrivacyBlockedError()
    var
        Customer: Record Customer;
    begin
        // Check Error Message while using a Customer with blocked Privacy and unblocked IC Partner on IC Journal Line.
        Initialize;

        LibraryLowerPermissions.SetIntercompanyPostingsEdit;
        LibraryLowerPermissions.AddIntercompanyPostingsSetup;
        LibraryLowerPermissions.AddO365Setup;
        CreateICJournalLineWithCustomerAndICPartnerPrivacyBlocked(Customer.Blocked::All, CreateICPartner);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerPrivacyBlockedWithBlockedICPartnerError()
    var
        Customer: Record Customer;
    begin
        // Check error message while using a Customer with blocked Privacy and blocked IC Partner on IC Journal Line.
        Initialize;

        LibraryLowerPermissions.SetIntercompanyPostingsEdit;
        LibraryLowerPermissions.AddIntercompanyPostingsSetup;
        LibraryLowerPermissions.AddO365Setup;
        CreateICJournalLineWithCustomerAndICPartnerPrivacyBlocked(
          Customer.Blocked::All, UpdateICPartnerBlocked(CreateICPartner, true));
    end;

    local procedure CreateICJournalLineWithCustomerAndICPartnerPrivacyBlocked(CustomerBlocked: Option " ",Ship,Invoice,All; ICPartnerCode: Code[20])
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        CustomerNo: Code[20];
    begin
        // Setup: Create Customer with Blocked Options and IC Partner.
        CustomerNo := CreateCustomer(CustomerBlocked, ICPartnerCode);
        Customer.Get(CustomerNo);
        Customer.Validate("Privacy Blocked", true);
        Customer.Modify();

        // Exercise: Create IC Journal Line. Taking 1 for sign factor.
        asserterror CreateICJournalLine(
            GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, CustomerNo, 1);

        // Verify: Verify Error Message.
        Assert.ExpectedError(StrSubstNo(BlockedPrivacyBlockedErr, Customer.TableCaption, CustomerNo));
    end;

    local procedure PostICPartnerLinkedWithCustomer(JournalLineAccountType: Option; AccountNumber: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        ICOutboxTransaction: Record "IC Outbox Transaction";
    begin
        // Setup: Create Customer with unblocked IC Partner, Create and update IC Journal Line, taking 1 for sign factor.
        CreateAndUpdateICJournalLine(GenJournalLine, GenJournalLine."Document Type"::Invoice, JournalLineAccountType, AccountNumber, 1);
        AccountNo := AccountNumber;  // Assigning Value to Global Variable.
        GLAccountNo := GenJournalLine."IC Partner G/L Acc. No.";  // Assigning Value to Global Variable.
        AccountType := Format(JournalLineAccountType);  // Assigning Value to Global Variable.
        Amount2 := GenJournalLine.Amount;  // Assigning Value to Global Variable.

        // Exercise: Post IC Journal Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Account and IC Partner GL Account Entries in IC Outbox Journal Line. Verification Done in Page Handler.
        FindICOutboxTransaction(
          ICOutboxTransaction, GenJournalLine."IC Partner Code", GenJournalLine."Document Type", GenJournalLine."Document No.");
        ICOutboxTransaction.ShowDetails;

        // Tear Down: Delete newly created batch.
        DeleteGeneralJournalBatch(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICPartnerUpdationWhenNoOutboxLines()
    var
        CompanyInformation: Record "Company Information";
        OldICPartnerCode: Code[20];
        ICPartnerCode: Code[20];
    begin
        // Check that any IC Partner can be updated on Company Information when there is no IC Outbox Transaction is present.

        // Setup.
        Initialize;
        ICPartnerCode := CreateICPartner;

        // Exercise.
        LibraryLowerPermissions.SetO365Setup;
        OldICPartnerCode := UpdateICPartnerInCompanyInformation(ICPartnerCode);

        // Verify: Verify that correct IC Partner Code is updated on Company Information.
        CompanyInformation.Get();
        CompanyInformation.TestField("IC Partner Code", ICPartnerCode);

        // Tear Down: Roll back Company Information.
        UpdateICPartnerInCompanyInformation(OldICPartnerCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICPartnerUpdationWhenInboxDetailsNotFilled()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ICPartner: Record "IC Partner";
        ICPartnerCode: Code[20];
    begin
        // Check Error Message while completing Line Action when Inbox Details for IC Partner is not filled.

        // Setup.
        Initialize;
        ICPartnerCode := SetupCompanyInformationAndPostICJournalLine(GenJournalLine);

        // Exercise.
        LibraryLowerPermissions.SetIntercompanyPostingsEdit;
        asserterror CompleteLineActionFromICOutboxTransactionsPage(
            GenJournalLine."Account No.", GenJournalLine."Document Type", GenJournalLine."Document No.");

        // Verify: Verify Error Message.
        Assert.ExpectedError(
          StrSubstNo(
            ValueMustExistErr, ICPartner.FieldCaption("Inbox Details"), ICPartner.TableCaption, ICPartner.FieldCaption(Code),
            GenJournalLine."Account No."));

        // Tear Down: Rollback Partner Code updated in Company Information.
        LibraryLowerPermissions.SetO365Setup;
        UpdateICPartnerInCompanyInformation(ICPartnerCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICPartnerUpdationWhenOutboxLineExists()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CompanyInformation: Record "Company Information";
        ICPartnerCode: Code[20];
    begin
        // Check Error Message while completing Line Action when IC Partner Code on Company Information is Blank.

        // Setup.
        Initialize;
        ICPartnerCode := SetupCompanyInformationAndPostICJournalLine(GenJournalLine);
        UpdateICPartnerInboxDetails(GenJournalLine."Account No.");

        // Exercise.
        LibraryLowerPermissions.SetIntercompanyPostingsEdit;
        asserterror CompleteLineActionFromICOutboxTransactionsPage(
            GenJournalLine."Account No.", GenJournalLine."Document Type", GenJournalLine."Document No.");

        // Verify: Verify Error Message.
        Assert.ExpectedError(
          StrSubstNo(
            ValueMustExistErr, CompanyInformation.FieldCaption("IC Partner Code"), CompanyInformation.TableCaption,
            CompanyInformation.FieldCaption("Primary Key"), CompanyInformation."Primary Key"));

        // Tear Down: Rollback IC Partner Code updated in Company Information.
        LibraryLowerPermissions.SetO365Setup;
        UpdateICPartnerInCompanyInformation(ICPartnerCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICPartnerUsedByAnotherVendorError()
    var
        Vendor: Record Vendor;
        ICPartnerCode: Code[20];
        VendorNo: Code[20];
    begin
        // Check that error message appears while using same IC Partner Code on two different Vendors.

        // Setup.
        Initialize;
        ICPartnerCode := CreateICPartner;
        VendorNo := CreateVendor(Vendor.Blocked::" ", ICPartnerCode);

        // Exercise: Create another Vendor and assign same IC Partner Code to it.
        LibraryLowerPermissions.SetVendorEdit;
        LibraryLowerPermissions.AddIntercompanyPostingsView;
        asserterror CreateVendor(Vendor.Blocked::" ", ICPartnerCode);

        // Verify: Verify Error Message.
        Assert.ExpectedError(
          StrSubstNo(SameICPartnerErr, Vendor.FieldCaption("IC Partner Code"), ICPartnerCode, Vendor.TableCaption, VendorNo));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SameICPartnerUsedByVendorAndCustomer()
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        ICPartnerCode: Code[20];
        VendorNo: Code[20];
    begin
        // Check that Same IC Partner Code can be used by a Customer and Vendor.

        // Setup.
        Initialize;
        ICPartnerCode := CreateICPartner;
        CreateCustomer(Customer.Blocked::" ", ICPartnerCode);

        // Exercise: Create Vendor and update same IC Partner Code to it.
        LibraryLowerPermissions.SetVendorEdit;
        LibraryLowerPermissions.AddIntercompanyPostingsSetup;
        VendorNo := CreateVendor(Vendor.Blocked::" ", ICPartnerCode);

        // Verify: Verify that correct IC Partner updated on Vendor.
        Vendor.Get(VendorNo);
        Vendor.TestField("IC Partner Code", ICPartnerCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SameICPartnerUsedByVendorAndCustomerError()
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        ICPartnerCode: Code[20];
        VendorNo: Code[20];
    begin
        // Check error message while updating same IC Partner Code on Vendor that is already used for a Customer and Vendor.

        // Setup: Create Customer and Vendor with same IC Partner Code.
        Initialize;
        ICPartnerCode := CreateICPartner;
        CreateCustomer(Customer.Blocked::" ", ICPartnerCode);
        VendorNo := CreateVendor(Vendor.Blocked::" ", ICPartnerCode);

        // Exercise: Create another Vendor and assign same IC Partner Code to it.
        LibraryLowerPermissions.SetVendorEdit;
        LibraryLowerPermissions.AddIntercompanyPostingsView;
        asserterror CreateVendor(Vendor.Blocked::" ", ICPartnerCode);

        // Verify: Verify error message for Vendor.
        Assert.ExpectedError(
          StrSubstNo(SameICPartnerErr, Vendor.FieldCaption("IC Partner Code"), ICPartnerCode, Vendor.TableCaption, VendorNo));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreationOfICPartnerWithBlankCode()
    var
        ICPartnerCard: TestPage "IC Partner Card";
    begin
        // Check that an error message appears when a new IC Partner is created with a blank Code.

        // Setup: Create IC Partner with Blank code.
        Initialize;
        ICPartnerCard.OpenNew;

        // Exercise.
        LibraryLowerPermissions.SetIntercompanyPostingsEdit;
        asserterror ICPartnerCard.Code.SetValue('');

        // Verify: Verify error message.
        Assert.ExpectedError(StrSubstNo(BlankCodeErr, ICPartnerCard.Code.Caption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICPartnerUpdateReflectedInGLEntry()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ICPartner: Record "IC Partner";
    begin
        // Check that IC Partner Code is automatically modified in the General Ledger Entries after modifying the IC Partner Code.

        // Setup: Create IC Partner, create and post IC General Journal, taking 1 for positive sign factor.
        Initialize;
        CreateAndUpdateICJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::"IC Partner", CreateICPartner, 1);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        ICPartner.Get(GenJournalLine."Account No.");

        // Exercise: Rename IC Partner using Random Integer value.
        LibraryLowerPermissions.SetIntercompanyPostingsSetup;
        ICPartner.Rename(ICPartner.Code + Format(LibraryRandom.RandInt(10)));

        // Verify: Verify GL Entry for IC Partner Code.
        VerifyGLEntry(GenJournalLine."Document No.", ICPartner.Code);

        // Tear Down.
        LibraryLowerPermissions.SetO365Setup;
        DeleteGeneralJournalBatch(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteICPartnerWithOpenEntries()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ICPartner: Record "IC Partner";
    begin
        // Check that error appears if Delete an IC Partner Code with open Ledger Entries.

        // Setup: Create and post IC General Journal Line, taking 1 for positive sign factor.
        Initialize;
        CreateAndUpdateICJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::"IC Partner", CreateICPartner, 1);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        ICPartner.Get(GenJournalLine."Account No.");

        // Exercise.
        LibraryLowerPermissions.SetIntercompanyPostingsSetup;
        asserterror ICPartner.Delete(true);

        // Verify: Verify error message.
        Assert.ExpectedError(StrSubstNo(OpenEntryDeleteErr, ICPartner.Code));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteICPartnerCodeAttachedCustomer()
    var
        Customer: Record Customer;
        ICPartner: Record "IC Partner";
    begin
        // Check that error appears if Delete the IC Partner Code with is attached to a Customer.

        // Setup: Create Customer with IC Partner Code.
        Initialize;
        Customer.Get(CreateCustomer(Customer.Blocked::" ", CreateICPartner));
        ICPartner.Get(Customer."IC Partner Code");

        // Exercise.
        LibraryLowerPermissions.SetIntercompanyPostingsSetup;
        asserterror ICPartner.Delete(true);

        // Verify: Verify error message.
        Assert.ExpectedError(StrSubstNo(CustomerDeleteErr, ICPartner.Code, Customer."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteICPartnerWithOpenCustomerEntries()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check that error appears if an IC Partner is deleted when IC Partner Code is used by a Customer with open entries.

        // Setup: Create Customer with IC Partner Code, Create and post IC General Journal Line, taking 1 for positive sign factor.
        Initialize;
        Customer.Get(CreateCustomer(Customer.Blocked::" ", CreateICPartner));
        CreateAndUpdateICJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, Customer."No.", 1);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise: Remove IC Partner Code from Customer.
        LibraryLowerPermissions.SetCustomerEdit;
        asserterror Customer.Validate("IC Partner Code", '');

        // Verify: Verify error message.
        Assert.ExpectedError(StrSubstNo(RemoveICPartnerErr, Customer.TableCaption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteICPartnerWithOpenVendorEntries()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check that error appears if an IC Partner is deleted when IC Partner Code is used by a Vendor with open entries.

        // Setup: Create Vendor with IC Partner Code, Create and post IC General Journal Line, taking -1 for negative sign factor.
        Initialize;
        Vendor.Get(CreateVendor(Vendor.Blocked::" ", CreateICPartner));
        CreateAndUpdateICJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, Vendor."No.", -1);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise: Remove IC Partner Code from Vendor.
        LibraryLowerPermissions.SetVendorEdit;
        asserterror Vendor.Validate("IC Partner Code", '');

        // Verify: Verify error message.
        Assert.ExpectedError(StrSubstNo(RemoveICPartnerErr, Vendor.TableCaption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostICJournalLineWithBlankReceivableAccount()
    var
        ICPartner: Record "IC Partner";
    begin
        // Check that error appears when post an IC General Journal with blank Receivable account on the IC Partner.
        Initialize;

        LibraryLowerPermissions.SetIntercompanyPostingsSetup;
        LibraryLowerPermissions.AddIntercompanyPostingsEdit;
        LibraryLowerPermissions.AddJournalsPost;
        LibraryLowerPermissions.AddO365Setup;
        ReceivablePayableAccountErrorForICPartner(ICPartner, ICPartner.FieldCaption("Receivables Account"), 1);  // Take 1 as positive sign factor.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostICJournalLineWithBlankPayableAccount()
    var
        ICPartner: Record "IC Partner";
    begin
        // Check that error appears when post an IC General Journal with blank Payable account on the IC Partner.
        Initialize;

        LibraryLowerPermissions.SetIntercompanyPostingsSetup;
        LibraryLowerPermissions.AddIntercompanyPostingsEdit;
        LibraryLowerPermissions.AddJournalsPost;
        LibraryLowerPermissions.AddO365Setup;
        ReceivablePayableAccountErrorForICPartner(ICPartner, ICPartner.FieldCaption("Payables Account"), -1);  // Take -1 as negative sign factor.
    end;

    local procedure ReceivablePayableAccountErrorForICPartner(var ICPartner: Record "IC Partner"; FieldCaption: Text[50]; SignFactor: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Setup: Create IC Partner without Receivable and Payable Account and Create IC General Journal Line.
        LibraryERM.CreateICPartner(ICPartner);
        ICPartner."Receivables Account" := '';
        ICPartner."Payables Account" := '';
        ICPartner.Modify();

        CreateAndUpdateICJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::"IC Partner", ICPartner.Code, SignFactor);

        // Exercise.
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Error Message.
        Assert.ExpectedError(StrSubstNo(AccountErr, FieldCaption, ICPartner.Code));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostICJournalLineWithInboxTypeFileLocation()
    var
        ICPartner: Record "IC Partner";
    begin
        // Post IC General Journal Line for an IC Partner with blank Indox Details and Inbox Type 'File Location'.
        Initialize;

        LibraryLowerPermissions.SetIntercompanyPostingsSetup;
        LibraryLowerPermissions.AddIntercompanyPostingsEdit;
        LibraryLowerPermissions.AddJournalsPost;
        LibraryLowerPermissions.AddO365Setup;
        PostICJournalLineWithDifferentInboxType(ICPartner."Inbox Type"::"File Location");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostICJournalLineWithInboxTypeDatabase()
    var
        ICPartner: Record "IC Partner";
    begin
        // Post IC General Journal Line for an IC Partner with blank Indox Details and Inbox Type 'Database'.
        Initialize;

        LibraryLowerPermissions.SetIntercompanyPostingsSetup;
        LibraryLowerPermissions.AddIntercompanyPostingsEdit;
        LibraryLowerPermissions.AddJournalsPost;
        LibraryLowerPermissions.AddO365Setup;
        PostICJournalLineWithDifferentInboxType(ICPartner."Inbox Type"::Database);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostICJournalLineWithInboxTypeEmail()
    var
        ICPartner: Record "IC Partner";
    begin
        // Post IC General Journal Line for an IC Partner with blank Indox Details and Inbox Type 'E-mail'.
        Initialize;

        LibraryLowerPermissions.SetIntercompanyPostingsSetup;
        LibraryLowerPermissions.AddIntercompanyPostingsEdit;
        LibraryLowerPermissions.AddJournalsPost;
        LibraryLowerPermissions.AddO365Setup;
        PostICJournalLineWithDifferentInboxType(ICPartner."Inbox Type"::Email);
    end;

    local procedure PostICJournalLineWithDifferentInboxType(InboxType: Option)
    var
        GenJournalLine: Record "Gen. Journal Line";
        ICPartner: Record "IC Partner";
    begin
        // Setup: Create and modify IC Partner and Create IC General Journal Line. Take 1 for positive Sign Factor.
        ICPartner.Get(CreateICPartner);
        ICPartner.Validate("Inbox Type", InboxType);
        ICPartner.Modify(true);
        CreateAndUpdateICJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::"IC Partner", ICPartner.Code, 1);

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify GL Entry.
        VerifyGLEntry(GenJournalLine."Document No.", GenJournalLine."Account No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendTransactionToBlockedICPartner()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ICPartner: Record "IC Partner";
    begin
        // Check that an error appears when sending transaction to a blocked IC Partner.

        // Setup: Create Blocked IC Partner.
        Initialize;
        ICPartner.Get(UpdateICPartnerBlocked(CreateICPartner, true));

        // Exercise: Create IC General Journal Line with Blocked IC Partner, take 1 for positive sign factor.
        LibraryLowerPermissions.SetIntercompanyPostingsEdit;
        LibraryLowerPermissions.AddJournalsEdit;
        asserterror CreateICJournalLine(
            GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::"IC Partner", ICPartner.Code, 1);

        // Verify: Verify error message.
        Assert.ExpectedError(
          StrSubstNo(
            ICPartnerBlockedErr, ICPartner.FieldCaption(Blocked), false, ICPartner.TableCaption, ICPartner.FieldCaption(Code),
            ICPartner.Code, true));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostNonICJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ICOutboxTransaction: Record "IC Outbox Transaction";
    begin
        // Check no IC Outbox Transaction is created after posting a non-IC line from IC General Journals.

        // Setup: Create Non-IC General Journal Line without IC Partner G/L Account No.
        Initialize;
        CreateNonICJournalLine(GenJournalLine);

        // Exercise.
        LibraryLowerPermissions.SetJournalsPost;
        LibraryLowerPermissions.AddIntercompanyPostingsEdit;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify IC Outbox Transactions.
        Assert.IsFalse(
          FindICOutboxTransaction(
            ICOutboxTransaction, GenJournalLine."IC Partner Code", GenJournalLine."Document Type", GenJournalLine."Document No."),
          StrSubstNo(EntryMustNotExistErr, ICOutboxTransaction.TableCaption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostNonICJournalLineWithICPartnerCodeAccountNo()
    var
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check that an error appears when posting a non-IC line with IC Partner G/L Account No.

        // Setup: Create Non-IC General Journal Line with IC Partner G/L Account No., take 1 for positive sign factor.
        Initialize;
        LibraryERM.CreateGLAccount(GLAccount);
        CreateAndUpdateICJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", 1);

        // Exercise.
        LibraryLowerPermissions.SetJournalsPost;
        LibraryLowerPermissions.AddIntercompanyPostingsView;
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify error message.
        Assert.ExpectedError(
          StrSubstNo(
            ICPartnerGLAccountNoErr, GenJournalLine.FieldCaption("IC Partner G/L Acc. No."), '', GenJournalLine.TableCaption,
            GenJournalLine.FieldCaption("Journal Template Name"), GenJournalLine."Journal Template Name",
            GenJournalLine.FieldCaption("Journal Batch Name"), GenJournalLine."Journal Batch Name",
            GenJournalLine.FieldCaption("Line No."), GenJournalLine."Line No.", GenJournalLine."IC Partner G/L Acc. No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostNonICAndICJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ICGLAccount: Record "IC G/L Account";
        ICOutboxJnlLine: Record "IC Outbox Jnl. Line";
    begin
        // Check IC Outbox Journal Lines after posting a non-IC line and an IC line at the same time.

        // Setup: Create Non-IC and IC General Journal Lines with Random amount.
        Initialize;
        CreateICGLAccount(ICGLAccount);
        CreateNonICJournalLine(GenJournalLine);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Document Type",
          GenJournalLine."Account Type"::"IC Partner", CreateICPartner, LibraryRandom.RandDec(100, 2));
        UpdateICJournalLine(GenJournalLine, GenJournalLine."Document No.", ICGLAccount."Map-to G/L Acc. No.", ICGLAccount."No.");

        // Exercise.
        LibraryLowerPermissions.SetJournalsPost;
        LibraryLowerPermissions.AddIntercompanyPostingsEdit;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Account and IC Partner GL Account Entries in IC Outbox Journal Line.
        VerifyICOutboxJournalLine(
          GenJournalLine."IC Partner Code", ICOutboxJnlLine."Account Type"::"IC Partner", GenJournalLine."IC Partner Code",
          GenJournalLine."Document No.", GenJournalLine.Amount);
        VerifyICOutboxJournalLine(
          GenJournalLine."IC Partner Code", ICOutboxJnlLine."Account Type"::"G/L Account", GenJournalLine."IC Partner G/L Acc. No.",
          GenJournalLine."Document No.", -GenJournalLine.Amount);

        // Tear Down.
        LibraryLowerPermissions.SetO365Setup;
        DeleteGeneralJournalBatch(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletionOfICDimension()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        ICDimension: Record "IC Dimension";
        ICDimensionValue: Record "IC Dimension Value";
        LibraryDimension: Codeunit "Library - Dimension";
    begin
        // Check IC Dimension Value deletion after deleting IC Dimension.

        // Setup: Create new IC Dimension and IC Dimension Values, Map them with existing Dimension and its value.
        Initialize;
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateICDimension(ICDimension);
        ICDimension.Validate("Map-to Dimension Code", Dimension.Code);
        ICDimension.Modify(true);

        LibraryDimension.CreateICDimensionValue(ICDimensionValue, ICDimension.Code);
        ICDimensionValue.Validate("Map-to Dimension Value Code", DimensionValue.Code);
        ICDimensionValue.Modify(true);
        ICDimension.SetRange(Code, ICDimension.Code);

        // Exercise: Delete IC Dimension created earlier.
        LibraryLowerPermissions.SetIntercompanyPostingsSetup;
        ICDimension.Delete(true);

        // Verify: Verify that after deleting IC Dimension, IC Dimension Value deleted automatically.
        ICDimensionValue.SetRange("Dimension Code", ICDimension.Code);
        ICDimensionValue.SetRange(Code, ICDimensionValue.Code);
        Assert.IsFalse(ICDimensionValue.FindFirst, StrSubstNo(EntryMustNotExistErr, ICDimensionValue.TableCaption));
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure BlockedICDimensionValueError()
    var
        ICDimension: Record "IC Dimension";
        ICDimensionValue: Record "IC Dimension Value";
        GenJournalLine: Record "Gen. Journal Line";
        ICInboxOutboxJnlLineDim: Record "IC Inbox/Outbox Jnl. Line Dim.";
    begin
        // Check Error Message while updating blocked IC Dimension Value after posting IC General Journal Line.

        // Setup: Create and map IC Dimension with newly created Dimension, block newly created IC Dimension Value and Post IC Journal Line for the Customer using this Dimension.
        Initialize;
        MapDimensionWithSameICDimension(CreateAndRenameICDimensionAndICDimensionValue(ICDimension, ICDimensionValue));
        ICDimensionValue.Validate(Blocked, true);
        ICDimensionValue.Modify(true);

        CreateAndPostICJournalLineWithDimension(GenJournalLine, ICDimension.Code, ICDimensionValue.Code);
        FindICJournalLineDimension(ICInboxOutboxJnlLineDim, GenJournalLine."IC Partner Code", ICDimension.Code);

        // Exercise: Update Dimension Value Code in IC Inbox Outbox Journal Line Dimension with same name.
        LibraryLowerPermissions.SetIntercompanyPostingsEdit;
        asserterror ICInboxOutboxJnlLineDim.Validate("Dimension Value Code", ICDimensionValue.Code);

        // Verify: Verify Error Message.
        Assert.ExpectedError(
          StrSubstNo(BlockedDimValueErr, ICDimensionValue.TableCaption, ICDimensionValue."Dimension Code", ICDimensionValue.Code));

        // Tear Down: Rollback IC General Journal Batch created during test case.
        LibraryLowerPermissions.SetO365Setup;
        DeleteGeneralJournalBatch(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure BlockedICDimensionError()
    var
        ICDimension: Record "IC Dimension";
        ICDimensionValue: Record "IC Dimension Value";
        GenJournalLine: Record "Gen. Journal Line";
        ICInboxOutboxJnlLineDim: Record "IC Inbox/Outbox Jnl. Line Dim.";
    begin
        // Check Error Message while updating blocked IC Dimension after posting IC General Journal Line.

        // Setup: Create and map IC Dimension with newly created Dimension, block newly created IC Dimension and Post IC Journal Line for the Customer using this Dimension.
        Initialize;
        MapDimensionWithSameICDimension(CreateAndRenameICDimensionAndICDimensionValue(ICDimension, ICDimensionValue));
        ICDimension.Validate(Blocked, true);
        ICDimension.Modify(true);

        CreateAndPostICJournalLineWithDimension(GenJournalLine, ICDimension.Code, ICDimensionValue.Code);
        FindICJournalLineDimension(ICInboxOutboxJnlLineDim, GenJournalLine."IC Partner Code", ICDimension.Code);

        // Exercise: Update Dimension Code in IC Inbox Outbox Journal Line Dimension with same name.
        LibraryLowerPermissions.SetIntercompanyPostingsEdit;
        asserterror ICInboxOutboxJnlLineDim.Validate("Dimension Code", ICDimension.Code);

        // Verify: Verify Error Message.
        Assert.ExpectedError(StrSubstNo(BlockedDimensionErr, ICDimension.TableCaption, ICDimension.Code));

        // Tear Down: Rollback IC General Journal Batch created during test case.
        LibraryLowerPermissions.SetO365Setup;
        DeleteGeneralJournalBatch(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICPartnerWithICPartner()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICGLAccount: Record "IC G/L Account";
    begin
        // Check Out of Balance error while posting General Journal Lines for two IC Partner.

        // Setup.
        Initialize;
        CreateICJournalBatch(GenJournalBatch);
        CreateICGLAccount(ICGLAccount);

        // Using RANDOM value for Amount.
        CreateAndUpdateICJournalUsingSameBatch(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"IC Partner",
          CreateICPartner, LibraryRandom.RandDec(100, 2), ICGLAccount."Map-to G/L Acc. No.", ICGLAccount."No.");
        CreateAndUpdateICJournalUsingSameBatch(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"IC Partner",
          GenJournalLine."Account No.", GenJournalLine.Amount, ICGLAccount."Map-to G/L Acc. No.", ICGLAccount."No.");

        // Exercise.
        LibraryLowerPermissions.SetJournalsPost;
        LibraryLowerPermissions.AddIntercompanyPostingsEdit;
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify.
        ICOutboxTransaction.FindLast;
        Assert.VerifyFailure(RecordExistsErr, InsertDuplicateKeyPassedTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICPartnerWithICCustomer()
    var
        Customer: Record Customer;
        ICPartner: Record "IC Partner";
    begin
        // Check Out of Balance error while posting General Journal Lines for IC Partner with IC Customer.

        // Setup.
        Initialize;
        LibraryERM.CreateICPartner(ICPartner);

        LibraryLowerPermissions.SetIntercompanyPostingsSetup;
        LibraryLowerPermissions.AddO365Setup;
        ICPartnerWithCustomer(CreateCustomer(Customer.Blocked::" ", ICPartner.Code), ICPartner.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICPartnerWithNonICCustomer()
    var
        Customer: Record Customer;
        ICPartner: Record "IC Partner";
    begin
        // Check Out of Balance error while posting General Journal Lines for IC Partner with Non IC Customer.

        // Setup.
        Initialize;
        LibraryERM.CreateICPartner(ICPartner);
        LibrarySales.CreateCustomer(Customer);

        LibraryLowerPermissions.SetIntercompanyPostingsSetup;
        LibraryLowerPermissions.AddO365Setup;
        ICPartnerWithCustomer(Customer."No.", ICPartner.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICCustomerWithICVendor()
    var
        Customer: Record Customer;
        ICPartner: Record "IC Partner";
        Vendor: Record Vendor;
    begin
        // Check Out of Balance error while posting General Journal Lines for IC Partner with IC Vendor.

        // Setup.
        Initialize;
        LibraryERM.CreateICPartner(ICPartner);

        LibraryLowerPermissions.SetIntercompanyPostingsSetup;
        LibraryLowerPermissions.AddO365Setup;
        ICCustomerWithVendor(CreateCustomer(Customer.Blocked::" ", ICPartner.Code), CreateVendor(Vendor.Blocked::" ", ICPartner.Code));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICCustomerWithNonICVendor()
    var
        Customer: Record Customer;
        ICPartner: Record "IC Partner";
        Vendor: Record Vendor;
    begin
        // Check Out of Balance error while posting General Journal Lines for IC Partner with Non IC Vendor.

        // Setup.
        Initialize;
        LibraryERM.CreateICPartner(ICPartner);
        LibraryPurchase.CreateVendor(Vendor);

        LibraryLowerPermissions.SetIntercompanyPostingsSetup;
        LibraryLowerPermissions.AddO365Setup;
        ICCustomerWithVendor(CreateCustomer(Customer.Blocked::" ", ICPartner.Code), Vendor."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICCustomerWithDiscountSetup()
    var
        Customer: Record Customer;
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        ICGLAccount: Record "IC G/L Account";
        ICPartner: Record "IC Partner";
        PaymentTerms: Record "Payment Terms";
        CustomerNo: Code[20];
    begin
        // Setup discount: Post an Invoice to IC Customer and Verify IC Outbox Journal Line.

        // Setup.
        Initialize;
        CreateICJournalBatch(GenJournalBatch);
        LibraryERM.CreateICPartner(ICPartner);
        CustomerNo := CreateCustomer(Customer.Blocked::" ", ICPartner.Code);
        UpdatePaymentTermOnCustomer(PaymentTerms, CustomerNo);
        CreateICGLAccount(ICGLAccount);

        // Using RANDOM value for Amount.
        CreateAndUpdateICJournalUsingSameBatch(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, CustomerNo,
          LibraryRandom.RandDec(100, 2), ICGLAccount."Map-to G/L Acc. No.", ICGLAccount."No.");

        // Exercise.
        LibraryLowerPermissions.SetJournalsPost;
        LibraryLowerPermissions.AddIntercompanyPostingsEdit;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Amount, VAT Amount, Due Date, Payment Discount Date and Payment Discount % in IC Outbox Journal Line, Using 0 for Payment Discount % and 0D for Due Date and Discount Date.
        VerifyICOutboxJournalLineForDiscountEntry(
          ICPartner.Code, GenJournalLine."Account Type"::Customer, CustomerNo, CustomerNo, 0, GenJournalLine.Amount,
          PaymentTerms."Discount %", CalcDate(PaymentTerms."Discount Date Calculation", WorkDate),
          CalcDate(PaymentTerms."Due Date Calculation", WorkDate));
        VerifyICOutboxJournalLineForDiscountEntry(
          ICPartner.Code, GenJournalLine."Account Type"::"G/L Account", ICGLAccount."No.", CustomerNo, 0, -GenJournalLine.Amount, 0, 0D, 0D);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICVendorWithoutDiscountSetup()
    var
        Vendor: Record Vendor;
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        ICGLAccount: Record "IC G/L Account";
        ICPartner: Record "IC Partner";
        VendorNo: Code[20];
    begin
        // Post an Invoice to IC Vendor and Verify IC Outbox Journal Line.

        // Setup.
        Initialize;
        CreateICJournalBatch(GenJournalBatch);
        LibraryERM.CreateICPartner(ICPartner);
        VendorNo := CreateVendor(Vendor.Blocked::" ", ICPartner.Code);
        CreateICGLAccount(ICGLAccount);

        // Using RANDOM value for Amount.
        CreateAndUpdateICJournalUsingSameBatch(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, VendorNo,
          -LibraryRandom.RandDec(100, 2), ICGLAccount."Map-to G/L Acc. No.", ICGLAccount."No.");

        // Exercise.
        LibraryLowerPermissions.SetJournalsPost;
        LibraryLowerPermissions.AddIntercompanyPostingsEdit;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Amount, VAT Amount, Due Date, Payment Discount Date and Payment Discount % in IC Outbox Journal Line, Using 0 for Payment Discount % and 0D for Due Date and Discount Date.
        VerifyICOutboxJournalLineForDiscountEntry(
          ICPartner.Code, GenJournalLine."Account Type"::Vendor, VendorNo, VendorNo, 0, GenJournalLine.Amount, 0, WorkDate, WorkDate);
        VerifyICOutboxJournalLineForDiscountEntry(
          ICPartner.Code, GenJournalLine."Account Type"::"G/L Account", ICGLAccount."No.", VendorNo, 0, -GenJournalLine.Amount, 0, 0D, 0D);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICCustomerWithDiscountAndVATSetup()
    var
        Customer: Record Customer;
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        ICGLAccount: Record "IC G/L Account";
        ICPartner: Record "IC Partner";
        PaymentTerms: Record "Payment Terms";
        VATPostingSetup: Record "VAT Posting Setup";
        VATAmount: Decimal;
        CustomerNo: Code[20];
    begin
        // Post an IC Invoice with both VAT and Payment discount. Verify IC Outbox Journal Line.

        // Setup.
        Initialize;
        CreateICJournalBatch(GenJournalBatch);
        LibraryERM.CreateICPartner(ICPartner);
        CustomerNo := CreateCustomer(Customer.Blocked::" ", ICPartner.Code);
        UpdatePaymentTermOnCustomer(PaymentTerms, CustomerNo);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateICGLAccountWithVATSetup(ICGLAccount, VATPostingSetup);

        // Using RANDOM value for Amount.
        CreateAndUpdateICJournalUsingSameBatch(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, CustomerNo,
          LibraryRandom.RandDec(100, 2), ICGLAccount."Map-to G/L Acc. No.", ICGLAccount."No.");
        VATAmount := GenJournalLine.Amount * VATPostingSetup."VAT %" / (100 + VATPostingSetup."VAT %");

        // Exercise.
        LibraryLowerPermissions.SetJournalsPost;
        LibraryLowerPermissions.AddIntercompanyPostingsEdit;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Amount, VAT Amount, Due Date, Payment Discount Date and Payment Discount % in IC Outbox Journal Line, Using 0 for Payment Discount % and 0D for Due Date and Discount Date.
        VerifyICOutboxJournalLineForDiscountEntry(
          ICPartner.Code, GenJournalLine."Account Type"::Customer, CustomerNo, CustomerNo, 0, GenJournalLine.Amount,
          PaymentTerms."Discount %", CalcDate(PaymentTerms."Discount Date Calculation", WorkDate),
          CalcDate(PaymentTerms."Due Date Calculation", WorkDate));
        VerifyICOutboxJournalLineForDiscountEntry(
          ICPartner.Code, GenJournalLine."Account Type"::"G/L Account", ICGLAccount."No.", CustomerNo, -VATAmount, -GenJournalLine.Amount, 0,
          0D, 0D);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OutboxTransToInbox_UT_Positive()
    var
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 378528] COD 427 ICInboxOutboxMgt.OutboxTransToInbox() creates ICInboxTrans for a new transaction
        Initialize;
        MockICOutboxTrans(ICOutboxTransaction);

        LibraryLowerPermissions.SetIntercompanyPostingsEdit;
        ICInboxOutboxMgt.OutboxTransToInbox(ICOutboxTransaction, ICInboxTransaction, ICOutboxTransaction."IC Partner Code");

        VerifyICInboxTrans(ICInboxTransaction, ICOutboxTransaction);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OutboxTransToInbox_UT_Negative_Inbox()
    var
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 378528] COD 427 ICInboxOutboxMgt.OutboxTransToInbox() throws an error in case when transaction is already in partner's Inbox
        Initialize;

        MockICOutboxTrans(ICOutboxTransaction);
        MockICInboxTrans(ICOutboxTransaction);

        LibraryLowerPermissions.SetIntercompanyPostingsEdit;
        asserterror ICInboxOutboxMgt.OutboxTransToInbox(ICOutboxTransaction, ICInboxTransaction, ICOutboxTransaction."IC Partner Code");
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(
          StrSubstNo(
            TransAlreadyExistErr, ICOutboxTransaction."Transaction No.", ICOutboxTransaction.FieldCaption("IC Partner Code"),
            ICOutboxTransaction."IC Partner Code", ICInboxTransaction.TableCaption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OutboxTransToInbox_UT_Negative_HandledInbox()
    var
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICInboxTransaction: Record "IC Inbox Transaction";
        HandledICInboxTrans: Record "Handled IC Inbox Trans.";
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 378528] COD 427 ICInboxOutboxMgt.OutboxTransToInbox() throws an error in case when transaction is already in partner's HandledInbox
        Initialize;

        MockICOutboxTrans(ICOutboxTransaction);
        MockHandledICInboxTrans(ICOutboxTransaction);

        LibraryLowerPermissions.SetIntercompanyPostingsEdit;
        asserterror ICInboxOutboxMgt.OutboxTransToInbox(ICOutboxTransaction, ICInboxTransaction, ICOutboxTransaction."IC Partner Code");

        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(
          StrSubstNo(
            TransAlreadyExistErr, ICOutboxTransaction."Transaction No.", HandledICInboxTrans.FieldCaption("IC Partner Code"),
            ICOutboxTransaction."IC Partner Code", HandledICInboxTrans.TableCaption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteICPartnerWithCustomerDeleted()
    var
        ICPartner: Record "IC Partner";
        Customer: Record Customer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 230162] Stan delete IC Partner if "Customer No." field filled with nonexistent Customer number
        Initialize;

        // [GIVEN] Create IC Partner, fill "Customer No." field
        ICPartner.Init();
        ICPartner.Code := LibraryUtility.GenerateRandomCode(ICPartner.FieldNo(Code), DATABASE::"IC Partner");
        LibrarySales.CreateCustomer(Customer);
        ICPartner."Customer No." := Customer."No.";
        ICPartner.Insert();

        // [GIVEN] Delete Customer
        Customer.Delete();
        LibraryLowerPermissions.SetIntercompanyPostingsEdit;
        LibraryLowerPermissions.SetIntercompanyPostingsSetup;

        // [WHEN] Delete IC Partner
        ICPartner.Delete(true);

        // [THEN] IC Partner is deleted
        ICPartner.SetRecFilter;
        Assert.RecordIsEmpty(ICPartner);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotDeleteICPartnerWithVendorNo()
    var
        ICPartner: Record "IC Partner";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 230162] Stan can't delete IC Partner if "Vendor No." field filled with existing Vendor number
        Initialize;

        // [GIVEN] Create IC Partner, fill "Vendor No." field
        ICPartner.Init();
        ICPartner.Code := LibraryUtility.GenerateRandomCode(ICPartner.FieldNo(Code), DATABASE::"IC Partner");
        ICPartner."Vendor No." := LibraryPurchase.CreateVendorNo;
        ICPartner.Insert();
        LibraryLowerPermissions.SetIntercompanyPostingsEdit;

        // [WHEN] Delete IC Partner
        asserterror ICPartner.Delete(true);

        // [THEN] An error "You can't delete IC Partner because it is used for Vendor" occured
        Assert.ExpectedError(StrSubstNo(VendorDeleteErr, ICPartner.Code, ICPartner."Vendor No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteICPartnerWithVendorDeleted()
    var
        ICPartner: Record "IC Partner";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 230162] Stan delete IC Partner if "Vendor No." filled with nonexistent Vendor number
        Initialize;

        // [GIVEN] Create IC Partner, fill "Vendor No." field
        ICPartner.Init();
        ICPartner.Code := LibraryUtility.GenerateRandomCode(ICPartner.FieldNo(Code), DATABASE::"IC Partner");
        LibraryPurchase.CreateVendor(Vendor);
        ICPartner."Vendor No." := Vendor."No.";
        ICPartner.Insert();

        // [GIVEN] Delete Vendor
        Vendor.Delete();
        LibraryLowerPermissions.SetIntercompanyPostingsEdit;
        LibraryLowerPermissions.SetIntercompanyPostingsSetup;

        // [WHEN] Delete IC Partner
        ICPartner.Delete(true);

        // [THEN] IC Partner is deleted
        ICPartner.SetRecFilter;
        Assert.RecordIsEmpty(ICPartner);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoicePostCorrectlyWithFullSizeYourReference()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 355257] Post Purchase order with "IC Direction" = Incoming and "Your Reference" length = 35 
        // [SCENARIO 355257] and "Your Reference" with max length greater than length of Order No
        Initialize();

        // [GIVEN] Create Purchase Invoice with "IC Direction" = Incoming, "Vendor Order No."
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        PurchaseHeader."IC Direction" := PurchaseHeader."IC Direction"::Incoming;
        PurchaseHeader."Vendor Order No." :=
          CopyStr(LibraryRandom.RandText(MaxStrLen(PurchaseHeader."Vendor Order No.")), 1, MaxStrLen(PurchaseHeader."Vendor Order No."));

        // [GIVEN] Set "Your Reference" to max length
        PurchaseHeader."Your Reference" :=
          CopyStr(LibraryRandom.RandText(MaxStrLen(PurchaseHeader."Your Reference")), 1, MaxStrLen(PurchaseHeader."Your Reference"));
        LibraryLowerPermissions.SetOutsideO365Scope();

        // [WHEN] Post Purchase Document
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] The Document posted correctly
        PurchInvHeader.Get(DocumentNo);

        LibraryLowerPermissions.SetIntercompanyPostingsEdit();
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Intercompany");
        ClearGlobalVariables;
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Intercompany");
        LibraryERMCountryData.CreateVATData;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        LibraryERMCountryData.UpdatePurchasesPayablesSetup;
        LibraryERMCountryData.UpdateSalesReceivablesSetup;

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Intercompany");
    end;

    local procedure ClearGlobalVariables()
    begin
        Clear(AccountNo);
        Clear(GLAccountNo);
        Clear(AccountType);
        Amount2 := 0;
    end;

    local procedure CompleteLineActionFromICOutboxTransactionsPage(ICPartnerCode: Code[20]; DocumentType: Option; DocumentNo: Code[20])
    var
        ICOutboxTransactions: TestPage "IC Outbox Transactions";
    begin
        ICOutboxTransactions.OpenEdit;
        ICOutboxTransactions.FILTER.SetFilter("IC Partner Code", ICPartnerCode);
        ICOutboxTransactions.FILTER.SetFilter("Document Type", Format(DocumentType));
        ICOutboxTransactions.FILTER.SetFilter("Document No.", DocumentNo);
        ICOutboxTransactions.SendToICPartner.Invoke;
        ICOutboxTransactions."Complete Line Actions".Invoke;
    end;

    local procedure CreateAndPostICJournalLineWithDimension(var GenJournalLine: Record "Gen. Journal Line"; ICDimensionCode: Code[20]; ICDimensionValueCode: Code[20])
    var
        Customer: Record Customer;
        DefaultDimension: Record "Default Dimension";
        LibraryDimension: Codeunit "Library - Dimension";
    begin
        LibraryDimension.CreateDefaultDimensionCustomer(
          DefaultDimension, CreateCustomer(Customer.Blocked::" ", CreateICPartner), ICDimensionCode, ICDimensionValueCode);
        CreateAndUpdateICJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, DefaultDimension."No.", 1);  // Taking 1 for positive sign factor.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndRenameICDimensionAndICDimensionValue(var ICDimension: Record "IC Dimension"; var ICDimensionValue: Record "IC Dimension Value"): Code[20]
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        LibraryDimension: Codeunit "Library - Dimension";
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateICDimension(ICDimension);
        ICDimension.Rename(Dimension.Code);  // Renaming IC Dimension Code with Dimension Code to create similar Code. Value important for test.
        LibraryDimension.CreateICDimensionValue(ICDimensionValue, ICDimension.Code);
        ICDimensionValue.Rename(ICDimension.Code, DimensionValue.Code);  // Renaming IC Dimension Value Code with Dimension Value Code to create similar code. Value important for test.
        exit(Dimension.Code);
    end;

    local procedure CreateAndUpdateICJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Option; AccountType: Option; AccountNo: Code[20]; SignFactor: Decimal)
    var
        ICGLAccount: Record "IC G/L Account";
    begin
        CreateICGLAccount(ICGLAccount);
        CreateICJournalLine(GenJournalLine, DocumentType, AccountType, AccountNo, SignFactor);
        UpdateICJournalLine(GenJournalLine, GenJournalLine."Document No.", ICGLAccount."Map-to G/L Acc. No.", ICGLAccount."No.");
    end;

    local procedure CreateAndUpdateICJournalUsingSameBatch(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; DocumentType: Option; AccountType: Option; AccountNo: Code[20]; Amount: Decimal; BalAccountNo: Code[20]; ICPartnerGLAccNo: Code[20])
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo, Amount);
        UpdateICJournalLine(GenJournalLine, AccountNo, BalAccountNo, ICPartnerGLAccNo);
    end;

    local procedure CreateCustomer(Blocked: Option; ICPartnerCode: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("IC Partner Code", ICPartnerCode);
        Customer.Validate(Blocked, Blocked);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateICGLAccount(var ICGLAccount: Record "IC G/L Account")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateICGLAccount(ICGLAccount);
        ICGLAccount.Validate("Map-to G/L Acc. No.", GLAccount."No.");
        ICGLAccount.Modify(true);
    end;

    local procedure CreateICGLAccountWithVATSetup(var ICGLAccount: Record "IC G/L Account"; VATPostingSetup: Record "VAT Posting Setup")
    var
        GLAccount: Record "G/L Account";
    begin
        // TFS ID: 307158
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup);
        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::Sale);
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);

        LibraryERM.CreateICGLAccount(ICGLAccount);
        ICGLAccount.Validate("Map-to G/L Acc. No.", GLAccount."No.");
        ICGLAccount.Modify(true);
    end;

    local procedure CreateICJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Intercompany);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateICJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Option; AccountType: Option; AccountNo: Code[20]; SignFactor: Integer)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Take Random Amount.
        CreateICJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo,
          SignFactor * LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreateNonICJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        CreateICJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", 1);  // Create 1 for positive sign factor.
        GenJournalLine.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalLine.Modify(true);
    end;

    local procedure CreateICPartner(): Code[20]
    var
        GLAccount: Record "G/L Account";
        ICPartner: Record "IC Partner";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateICPartner(ICPartner);
        ICPartner.Validate("Receivables Account", GLAccount."No.");
        LibraryERM.CreateGLAccount(GLAccount);
        ICPartner.Validate("Payables Account", GLAccount."No.");
        ICPartner.Modify(true);
        exit(ICPartner.Code);
    end;

    local procedure CreateVendor(Blocked: Option; ICPartnerCode: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate(Blocked, Blocked);
        Vendor.Validate("IC Partner Code", ICPartnerCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure MockICOutboxTrans(var ICOutboxTransaction: Record "IC Outbox Transaction")
    begin
        with ICOutboxTransaction do begin
            Init;
            "Transaction No." := LibraryUtility.GetNewRecNo(ICOutboxTransaction, FieldNo("Transaction No."));
            "IC Partner Code" := CreateICPartner;
            "Transaction Source" := "Transaction Source"::"Created by Current Company";
            "Document Type" := "Document Type"::Invoice;
            "Source Type" := "Source Type"::"Journal Line";
            "Document No." := LibraryUtility.GenerateGUID;
            "Posting Date" := LibraryRandom.RandDate(10);
            "Document Date" := LibraryRandom.RandDate(10);
            "IC Partner G/L Acc. No." := LibraryUtility.GenerateGUID;
            "Source Line No." := LibraryRandom.RandInt(100);
            Insert;
        end;
    end;

    local procedure MockICInboxTrans(ICOutboxTransaction: Record "IC Outbox Transaction")
    var
        ICInboxTransaction: Record "IC Inbox Transaction";
    begin
        with ICInboxTransaction do begin
            Init;
            "Transaction No." := ICOutboxTransaction."Transaction No.";
            "IC Partner Code" := ICOutboxTransaction."IC Partner Code";
            "Transaction Source" := ICOutboxTransaction."Transaction Source";
            "Document Type" := ICOutboxTransaction."Document Type";
            Insert;
        end;
    end;

    local procedure MockHandledICInboxTrans(ICOutboxTransaction: Record "IC Outbox Transaction")
    var
        HandledICInboxTrans: Record "Handled IC Inbox Trans.";
    begin
        with HandledICInboxTrans do begin
            Init;
            "Transaction No." := ICOutboxTransaction."Transaction No.";
            "IC Partner Code" := ICOutboxTransaction."IC Partner Code";
            "Transaction Source" := ICOutboxTransaction."Transaction Source";
            "Document Type" := ICOutboxTransaction."Document Type";
            Insert;
        end;
    end;

    local procedure DeleteGeneralJournalBatch(JournalTemplateName: Code[10]; Description: Text[50])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GenJournalBatch.SetRange("Journal Template Name", JournalTemplateName);
        GenJournalBatch.SetRange(Description, Description);
        GenJournalBatch.FindFirst;
        GenJournalBatch.Delete(true);
    end;

    local procedure FindICJournalLineDimension(var ICInboxOutboxJnlLineDim: Record "IC Inbox/Outbox Jnl. Line Dim."; ICPartnerCode: Code[20]; DimensionCode: Code[20])
    begin
        ICInboxOutboxJnlLineDim.SetRange("IC Partner Code", ICPartnerCode);
        ICInboxOutboxJnlLineDim.SetRange("Dimension Code", DimensionCode);
        ICInboxOutboxJnlLineDim.FindFirst;
    end;

    local procedure FindICOutboxTransaction(var ICOutboxTransaction: Record "IC Outbox Transaction"; ICPartnerCode: Code[20]; DocumentType: Option; DocumentNo: Code[20]): Boolean
    begin
        ICOutboxTransaction.SetRange("IC Partner Code", ICPartnerCode);
        ICOutboxTransaction.SetRange("Document Type", DocumentType);
        ICOutboxTransaction.SetRange("Document No.", DocumentNo);
        exit(ICOutboxTransaction.FindFirst);
    end;

    local procedure FindICOutboxJounralLine(var ICOutboxJnlLine: Record "IC Outbox Jnl. Line"; ICPartnerCode: Code[20]; AccountType: Option; AccountNo: Code[20]; DocumentNo: Code[20])
    begin
        ICOutboxJnlLine.SetRange("Account Type", AccountType);
        ICOutboxJnlLine.SetRange("IC Partner Code", ICPartnerCode);
        ICOutboxJnlLine.SetRange("Account No.", AccountNo);
        ICOutboxJnlLine.SetRange("Document No.", DocumentNo);
        ICOutboxJnlLine.FindFirst;
    end;

    local procedure ICPartnerWithCustomer(CustomerNo: Code[20]; ICPartnerCode: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        ICGLAccount: Record "IC G/L Account";
        Amount: Decimal;
    begin
        // Using blank value for Balancing Account No. and IC Partner G/L Account No.
        CreateICJournalBatch(GenJournalBatch);
        CreateICGLAccount(ICGLAccount);
        Amount := LibraryRandom.RandDec(100, 2); // Using RANDOM value for Amount.
        CreateAndUpdateICJournalUsingSameBatch(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"IC Partner", ICPartnerCode,
          Amount, '', '');
        CreateAndUpdateICJournalUsingSameBatch(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Customer, CustomerNo, Amount,
          '', '');
        CreateAndUpdateICJournalUsingSameBatch(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account",
          ICGLAccount."Map-to G/L Acc. No.", -(Amount * 2), '', '');

        // Exercise.
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verifying Out of Balance Error.
        Assert.ExpectedError(
          StrSubstNo(
            OutOfBalanceErr, GenJournalLine.FieldCaption("Document No."), GenJournalLine."Document No.", GenJournalLine.Amount,
            GenJournalLine.FieldCaption("Posting Date"),
            GenJournalLine.FieldCaption("Document Type"), GenJournalLine.FieldCaption("Document No."), GenJournalLine.FieldCaption(Amount)));
    end;

    local procedure ICCustomerWithVendor(CustomerNo: Code[20]; VendorNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        ICGLAccount: Record "IC G/L Account";
        Amount: Decimal;
    begin
        // Using blank value for Balancing Account No. and IC Partner G/L Account No.
        CreateICJournalBatch(GenJournalBatch);
        CreateICGLAccount(ICGLAccount);
        Amount := LibraryRandom.RandDec(100, 2);  // Using RANDOM value for Amount.
        CreateAndUpdateICJournalUsingSameBatch(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Customer, CustomerNo, Amount,
          '', '');
        CreateAndUpdateICJournalUsingSameBatch(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Vendor, VendorNo, Amount, '',
          '');
        CreateAndUpdateICJournalUsingSameBatch(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account",
          ICGLAccount."Map-to G/L Acc. No.", -(Amount * 2), '', '');

        // Exercise.
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verifying Out of Balance Error.
        Assert.ExpectedError(
          StrSubstNo(
            OutOfBalanceErr, GenJournalLine.FieldCaption("Document No."), GenJournalLine."Document No.", GenJournalLine.Amount,
            GenJournalLine.FieldCaption("Posting Date"),
            GenJournalLine.FieldCaption("Document Type"), GenJournalLine.FieldCaption("Document No."), GenJournalLine.FieldCaption(Amount)));
    end;

    local procedure MapDimensionWithSameICDimension("Code": Code[20])
    var
        Dimensions: TestPage Dimensions;
    begin
        Dimensions.OpenEdit;
        Dimensions.FILTER.SetFilter(Code, Code);
        Dimensions.MapToICDimWithSameCode.Invoke;
    end;

    local procedure SetupCompanyInformationAndPostICJournalLine(var GenJournalLine: Record "Gen. Journal Line") ICPartnerCode: Code[20]
    begin
        ICPartnerCode := UpdateICPartnerInCompanyInformation('');
        CreateAndUpdateICJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::"IC Partner", CreateICPartner, 1);  // Taking 1 for sign factor.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure UpdateICJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentNo: Code[20]; BalAccountNo: Code[20]; ICPartnerGLAccNo: Code[20])
    begin
        GenJournalLine.Validate("Document No.", DocumentNo);
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Validate("IC Partner G/L Acc. No.", ICPartnerGLAccNo);
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateICPartnerBlocked("Code": Code[20]; Blocked: Boolean): Code[20]
    var
        ICPartner: Record "IC Partner";
    begin
        ICPartner.Get(Code);
        ICPartner.Validate(Blocked, Blocked);
        ICPartner.Modify(true);
        exit(ICPartner.Code);
    end;

    local procedure UpdateICPartnerInboxDetails("Code": Code[20])
    var
        ICPartner: Record "IC Partner";
    begin
        ICPartner.Get(Code);
        ICPartner.Validate("Inbox Type", ICPartner."Inbox Type"::Email);
        ICPartner.Validate("Inbox Details", TemporaryPath);
        ICPartner.Modify(true);
    end;

    local procedure UpdateICPartnerInCompanyInformation(ICPartnerCode: Code[20]) OldICPartnerCode: Code[20]
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        OldICPartnerCode := CompanyInformation."IC Partner Code";
        CompanyInformation.Validate("IC Partner Code", ICPartnerCode);
        CompanyInformation.Modify(true);
    end;

    local procedure UpdatePaymentTermOnCustomer(var PaymentTerms: Record "Payment Terms"; No: Code[20])
    var
        Customer: Record Customer;
    begin
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        Customer.Get(No);
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Modify(true);
    end;

    local procedure VerifyICOutboxJournalLine(ICPartnerCode: Code[20]; AccountType: Option; AccountNo: Code[20]; DocumentNo: Code[20]; Amount: Decimal)
    var
        ICOutboxJnlLine: Record "IC Outbox Jnl. Line";
    begin
        FindICOutboxJounralLine(ICOutboxJnlLine, ICPartnerCode, AccountType, AccountNo, DocumentNo);
        Assert.AreEqual(
          AccountNo, ICOutboxJnlLine."Account No.",
          StrSubstNo(
            ValidationErr, ICOutboxJnlLine.FieldCaption("Account No."), ICOutboxJnlLine."Account No.", ICOutboxJnlLine.TableCaption));
        Assert.AreNearlyEqual(
          Amount, ICOutboxJnlLine.Amount, LibraryERM.GetAmountRoundingPrecision,
          StrSubstNo(ValidationErr, ICOutboxJnlLine.FieldCaption(Amount), ICOutboxJnlLine.Amount, ICOutboxJnlLine.TableCaption));
    end;

    local procedure VerifyICOutboxJournalLineForDiscountEntry(ICPartnerCode: Code[20]; AccountType: Option; AccountNo: Code[20]; DocumentNo: Code[20]; VATAmount: Decimal; Amount: Decimal; PaymentDiscountPct: Decimal; PaymentDiscountDate: Date; DueDate: Date)
    var
        ICOutboxJnlLine: Record "IC Outbox Jnl. Line";
    begin
        FindICOutboxJounralLine(ICOutboxJnlLine, ICPartnerCode, AccountType, AccountNo, DocumentNo);
        Assert.AreEqual(
          PaymentDiscountPct, ICOutboxJnlLine."Payment Discount %",
          StrSubstNo(ValidationErr, ICOutboxJnlLine.FieldCaption("Payment Discount %"), PaymentDiscountPct, ICOutboxJnlLine.TableCaption));
        Assert.AreEqual(
          PaymentDiscountDate, ICOutboxJnlLine."Payment Discount Date",
          StrSubstNo(
            ValidationErr, ICOutboxJnlLine.FieldCaption("Payment Discount Date"), PaymentDiscountDate, ICOutboxJnlLine.TableCaption));
        Assert.AreEqual(
          DueDate, ICOutboxJnlLine."Due Date",
          StrSubstNo(ValidationErr, ICOutboxJnlLine.FieldCaption("Due Date"), DueDate, ICOutboxJnlLine.TableCaption));
        Assert.AreEqual(
          0, ICOutboxJnlLine.Quantity, StrSubstNo(ValidationErr, ICOutboxJnlLine.FieldCaption(Quantity), 0, ICOutboxJnlLine.TableCaption));
        Assert.AreNearlyEqual(
          VATAmount, ICOutboxJnlLine."VAT Amount", LibraryERM.GetAmountRoundingPrecision,
          StrSubstNo(ValidationErr, ICOutboxJnlLine.FieldCaption("VAT Amount"), VATAmount, ICOutboxJnlLine.TableCaption));
        Assert.AreNearlyEqual(
          Amount, ICOutboxJnlLine.Amount, LibraryERM.GetAmountRoundingPrecision,
          StrSubstNo(ValidationErr, ICOutboxJnlLine.FieldCaption(Amount), ICOutboxJnlLine.Amount, ICOutboxJnlLine.TableCaption));
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; ICPartnerCode: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindFirst;
        GLEntry.TestField("IC Partner Code", ICPartnerCode);
    end;

    local procedure VerifyICInboxTrans(ICInboxTransaction: Record "IC Inbox Transaction"; ICOutboxTransaction: Record "IC Outbox Transaction")
    begin
        with ICInboxTransaction do begin
            Assert.AreEqual(ICOutboxTransaction."Transaction No.", "Transaction No.", FieldCaption("Transaction No."));
            Assert.AreEqual("IC Partner Code", "IC Partner Code", FieldCaption("IC Partner Code"));
            Assert.AreEqual(ICOutboxTransaction."Transaction Source", "Transaction Source", FieldCaption("Transaction Source"));
            Assert.AreEqual(ICOutboxTransaction."Document Type", "Document Type", FieldCaption("Document Type"));
            Assert.AreEqual("Source Type"::Journal, "Source Type", FieldCaption("Source Type"));
            Assert.AreEqual(ICOutboxTransaction."Document No.", "Document No.", FieldCaption("Document No."));
            Assert.AreEqual(ICOutboxTransaction."Document No.", "Original Document No.", FieldCaption("Original Document No."));
            Assert.AreEqual(ICOutboxTransaction."Posting Date", "Posting Date", FieldCaption("Posting Date"));
            Assert.AreEqual(ICOutboxTransaction."Document Date", "Document Date", FieldCaption("Document Date"));
            Assert.AreEqual("Line Action"::"No Action", "Line Action", FieldCaption("Line Action"));
            Assert.AreEqual(
              ICOutboxTransaction."IC Partner G/L Acc. No.", "IC Partner G/L Acc. No.", FieldCaption("IC Partner G/L Acc. No."));
            Assert.AreEqual(ICOutboxTransaction."Source Line No.", "Source Line No.", FieldCaption("Source Line No."));
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ICOutboxJnlLinesPageHandler(var ICOutboxJnlLines: TestPage "IC Outbox Jnl. Lines")
    var
        ICOutboxJnlLine: Record "IC Outbox Jnl. Line";
    begin
        ICOutboxJnlLines.FILTER.SetFilter("Account Type", AccountType);
        ICOutboxJnlLines."Account No.".AssertEquals(AccountNo);
        ICOutboxJnlLines.Amount.AssertEquals(Amount2);
        ICOutboxJnlLines.FILTER.SetFilter("Account Type", Format(ICOutboxJnlLine."Account Type"::"G/L Account"));
        ICOutboxJnlLines."Account No.".AssertEquals(GLAccountNo);
        ICOutboxJnlLines.Amount.AssertEquals(-Amount2);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure YesConfirmHandler(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

