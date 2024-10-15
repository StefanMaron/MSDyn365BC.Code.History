#if not CLEAN17
codeunit 144001 "Bank Account Format UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryBank: Codeunit "Library - Bank";
        InvalidCharactersErr: Label 'Bank account no. contains invalid characters "%1".', Comment = '%1 = invalid characters';
        BankAccountNoTooLongErr: Label 'Bank account no. is too long.';
        BankAccountNoTooShortErr: Label 'Bank account no. is too short.';
        BankCodeSlashMissingErr: Label 'Bank code must be separated by a slash.';
        BankCodeTooLongErr: Label 'Bank code is too long.';
        BankCodeTooShortErr: Label 'Bank code is too short.';
        PrefixTooLongErr: Label 'Bank account prefix is too long.';
        PrefixIncorrectChecksumErr: Label 'Bank account prefix has incorrect checksum.';
        IdentificationTooLongErr: Label 'Bank account identification is too long.';
        IdentificationTooShortErr: Label 'Bank account identification is too short.';
        IdentificationNonZeroDigitsErr: Label 'Bank account identification must contain at least two non-zero digits.';
        IdentificationIncorrectChecksumErr: Label 'Bank account identification has incorrect checksum.';
        FirstHyphenErr: Label 'Bank account no. must not start with character "-".';

    [Test]
    [Scope('OnPrem')]
    procedure ValidFormatBankAccountNo()
    var
        BankAcc: Record "Bank Account";
    begin
        // Positive test of valid bank account no.

        // SETUP : Setup Company Information
        SetupCompanyInformation;

        // SETUP : Bank Account Initialization
        BankAcc.Init();
        BankAcc."Country/Region Code" := '';

        // EXERCISE & VERIFY :
        BankAcc.Validate("Bank Account No.", LibraryBank.GetBankAccountNo);

        // TEARDOWN:
        TearDownCompanyInformation;
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ErrorMessagesHandler')]
    [Scope('OnPrem')]
    procedure BankAccountNoWithInvalidCharacters()
    begin
        // Negative test of invalid bank account no. with invalid characters
        BankAccountNoWithInvalidFormat(StrSubstNo(InvalidCharactersErr, '*'));
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ErrorMessagesHandler')]
    [Scope('OnPrem')]
    procedure BankAccountNoWithTooLongNumber()
    begin
        // Negative test of invalid bank account no. with number greater than 22
        BankAccountNoWithInvalidFormat(BankAccountNoTooLongErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ErrorMessagesHandler')]
    [Scope('OnPrem')]
    procedure BankAccountNoWithTooShortNumber()
    begin
        // Negative test of invalid bank account no. with number less than 7
        BankAccountNoWithInvalidFormat(BankAccountNoTooShortErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ErrorMessagesHandler')]
    [Scope('OnPrem')]
    procedure BankAccountNoWithMissingSlash()
    begin
        // Negative test of invalid bank account no. with missing slash
        BankAccountNoWithInvalidFormat(BankCodeSlashMissingErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ErrorMessagesHandler')]
    [Scope('OnPrem')]
    procedure BankAccountNoWithTooLongBankCode()
    begin
        // Negative test of invalid bank account no. with too long bank code
        BankAccountNoWithInvalidFormat(BankCodeTooLongErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ErrorMessagesHandler')]
    [Scope('OnPrem')]
    procedure BankAccountNoWithTooShortBankCode()
    begin
        // Negative test of invalid bank account no. with too short bank code
        BankAccountNoWithInvalidFormat(BankCodeTooShortErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ErrorMessagesHandler')]
    [Scope('OnPrem')]
    procedure BankAccountNoWithTooLongPrefix()
    begin
        // Negative test of invalid bank account no. with too long prefix
        BankAccountNoWithInvalidFormat(PrefixTooLongErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ErrorMessagesHandler')]
    [Scope('OnPrem')]
    procedure BankAccountNoWithIncorrectCheckSumOfPrefix()
    begin
        // Negative test of invalid bank account no. with incorrect check sum of prefix
        BankAccountNoWithInvalidFormat(PrefixIncorrectChecksumErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ErrorMessagesHandler')]
    [Scope('OnPrem')]
    procedure BankAccountNoWithTooLongIdentification()
    begin
        // Negative test of invalid bank account no. with too long identification
        BankAccountNoWithInvalidFormat(IdentificationTooLongErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ErrorMessagesHandler')]
    [Scope('OnPrem')]
    procedure BankAccountNoWithTooShortIdentification()
    begin
        // Negative test of invalid bank account no. with too short identification
        BankAccountNoWithInvalidFormat(IdentificationTooShortErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ErrorMessagesHandler')]
    [Scope('OnPrem')]
    procedure BankAccountNoWithoutNonZeroDigits()
    begin
        // Negative test of invalid bank account no. without non zero digits
        BankAccountNoWithInvalidFormat(IdentificationNonZeroDigitsErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ErrorMessagesHandler')]
    [Scope('OnPrem')]
    procedure BankAccountNoWithIncorrectCheckSumOfIdentification()
    begin
        // Negative test of invalid bank account no. without non zero digits
        BankAccountNoWithInvalidFormat(IdentificationIncorrectChecksumErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ErrorMessagesHandler')]
    [Scope('OnPrem')]
    procedure BankAccountNoWithFirstHyphen()
    begin
        // Negative test of invalid bank account no. with first minus
        BankAccountNoWithInvalidFormat(FirstHyphenErr);
    end;

    local procedure BankAccountNoWithInvalidFormat(Error: Text)
    var
        BankAcc: Record "Bank Account";
    begin
        // SETUP : Setup Company Information
        SetupCompanyInformation;

        // SETUP : Bank Account Initialization
        BankAcc.Init();
        BankAcc."Country/Region Code" := '';

        // EXERCISE :
        asserterror BankAcc.Validate("Bank Account No.", LibraryBank.GetBankAccountNoCausingError(Error));

        // VERIFY :
        Assert.ExpectedError(Error);

        // TEARDOWN:
        TearDownCompanyInformation;
    end;

    local procedure SetupCompanyInformation()
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        CompanyInfo."Bank Account Format Check" := true;
        CompanyInfo.Modify();
    end;

    local procedure TearDownCompanyInformation()
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        CompanyInfo."Bank Account Format Check" := false;
        CompanyInfo.Modify();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ErrorMessagesHandler(var ErrorMessages: TestPage "Error Messages")
    begin
        Error(ErrorMessages.Description.Value);
    end;
}

#endif