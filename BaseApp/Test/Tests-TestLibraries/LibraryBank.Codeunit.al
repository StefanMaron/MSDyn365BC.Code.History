#if not CLEAN19
codeunit 143000 "Library - Bank"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Banking Localization Pack for Czech Test';
    ObsoleteTag = '19.0';

    trigger OnRun()
    begin
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        BankOperationsFunctions: Codeunit "Bank Operations Functions";
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

    [Scope('OnPrem')]
    procedure CreateAccountMappingCode(var TextToAccMappingCode: Record "Text-to-Account Mapping Code")
    begin
        with TextToAccMappingCode do begin
            Init;
            Validate(Code,
              LibraryUtility.GenerateRandomCode(FieldNo(Code), DATABASE::"Text-to-Account Mapping Code"));
            Validate(Description, Code);
            Insert(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateBankStatementHeader(var BankStmtHdr: Record "Bank Statement Header")
    var
        BankAcc: Record "Bank Account";
    begin
        FindBankAccount(BankAcc);

        BankStmtHdr.Init();
        BankStmtHdr.Validate("Bank Account No.", BankAcc."No.");
        BankStmtHdr.Validate("Document Date", WorkDate);
        BankStmtHdr.Insert(true);

        BankStmtHdr.Validate("External Document No.", BankStmtHdr."No.");
        BankStmtHdr.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateBankStatementLine(var BankStmtLn: Record "Bank Statement Line"; BankStmtHdr: Record "Bank Statement Header"; Type: Option; No: Code[20]; Amount: Decimal)
    var
        RecRef: RecordRef;
    begin
        BankStmtLn.Init();
        BankStmtLn.Validate("Bank Statement No.", BankStmtHdr."No.");
        RecRef.GetTable(BankStmtLn);
        BankStmtLn.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, BankStmtLn.FieldNo("Line No.")));
        BankStmtLn.Insert(true);

        BankStmtLn.Validate(Type, Type);
        BankStmtLn.Validate("No.", No);
        BankStmtLn.Validate(Amount, Amount);
        BankStmtLn.Validate("Variable Symbol", GenerateVariableSymbol);
        BankStmtLn.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateBankPmtApplRuleCode(var BankPmtApplRuleCode: Record "Bank Pmt. Appl. Rule Code")
    begin
        BankPmtApplRuleCode.Init();
        BankPmtApplRuleCode.Validate(Code,
          LibraryUtility.GenerateRandomCode(BankPmtApplRuleCode.FieldNo(Code), DATABASE::"Bank Pmt. Appl. Rule Code"));
        BankPmtApplRuleCode.Validate(Description, BankPmtApplRuleCode.Code);
        BankPmtApplRuleCode.Insert(true);

        InsertDefaultMatchingRules(BankPmtApplRuleCode.Code);
    end;

    [Scope('OnPrem')]
    procedure CreateConstantSymbol(var ConstantSymbol: Record "Constant Symbol")
    begin
        ConstantSymbol.Init();
        ConstantSymbol.Validate(Code, LibraryUtility.GenerateRandomCode(ConstantSymbol.FieldNo(Code), DATABASE::"Constant Symbol"));
        ConstantSymbol.Validate(Description, ConstantSymbol.Code);
        ConstantSymbol.Insert(true)
    end;

    [Scope('OnPrem')]
    procedure CreatePaymentOrderHeader(var PmtOrdHdr: Record "Payment Order Header")
    var
        BankAcc: Record "Bank Account";
    begin
        LibraryERM.FindBankAccount(BankAcc);

        PmtOrdHdr.Init();
        PmtOrdHdr.Validate("Bank Account No.", BankAcc."No.");
        PmtOrdHdr.Validate("Document Date", WorkDate);
        PmtOrdHdr.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreatePaymentOrderLine(var PmtOrdLn: Record "Payment Order Line"; PmtOrdHdr: Record "Payment Order Header"; Type: Option; No: Code[20]; Amount: Decimal)
    var
        RecRef: RecordRef;
    begin
        PmtOrdLn.Init();
        PmtOrdLn.Validate("Payment Order No.", PmtOrdHdr."No.");
        RecRef.GetTable(PmtOrdLn);
        PmtOrdLn.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, PmtOrdLn.FieldNo("Line No.")));
        PmtOrdLn.Insert(true);

        PmtOrdLn.Validate(Type, Type);
        PmtOrdLn.Validate("No.", No);
        PmtOrdLn.Validate("Amount to Pay", Amount);
        PmtOrdLn.Validate("Variable Symbol", GenerateVariableSymbol);
        PmtOrdLn.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure SuggestPayments(var PmtOrdHdr: Record "Payment Order Header")
    var
        SuggestPayments: Report "Suggest Payments";
    begin
        Commit();
        SuggestPayments.SetPaymentOrder(PmtOrdHdr);
        SuggestPayments.RunModal;
    end;

    [Scope('OnPrem')]
    procedure CopyPaymentOrder(var BankStmtHdr: Record "Bank Statement Header")
    var
        CopyPaymentOrder: Report "Copy Payment Order";
    begin
        Commit();
        CopyPaymentOrder.SetBankStmtHdr(BankStmtHdr);
        CopyPaymentOrder.RunModal;
    end;

    [Scope('OnPrem')]
    procedure PrintPaymentOrderDomestic(var IssuedPmtOrdHdr: Record "Issued Payment Order Header"; ShowReqForm: Boolean)
    begin
        IssuedPmtOrdHdr.PrintDomesticPmtOrd(ShowReqForm);
    end;

    [Scope('OnPrem')]
    procedure IssuePaymentOrder(var PmtOrdHdr: Record "Payment Order Header")
    begin
        CODEUNIT.Run(CODEUNIT::"Issue Payment Order", PmtOrdHdr);
    end;

    [Scope('OnPrem')]
    procedure IssueBankStatementAndPrint(var BankStmtHdr: Record "Bank Statement Header")
    begin
        CODEUNIT.Run(CODEUNIT::"Issue Bank Statement + Print", BankStmtHdr);
    end;

    [Scope('OnPrem')]
    procedure GetBankAccountNo(): Text[30]
    begin
        exit('1111111111/0100');
    end;

    [Scope('OnPrem')]
    procedure GetBankAccountNoCausingError(Error: Text): Text[30]
    begin
        case Error of
            StrSubstNo(InvalidCharactersErr, '*'):
                exit('*'); // star is invalid char
            BankAccountNoTooLongErr:
                exit('123456789012345678/0123'); // bank account no. is greater than 22
            BankAccountNoTooShortErr:
                exit('/2345'); // bank account no. is less than 7
            BankCodeSlashMissingErr:
                exit('1234567'); // slash is missing
            BankCodeTooLongErr:
                exit('1234567890/12345'); // bank code is greater than 4
            BankCodeTooShortErr:
                exit('1234567890/123'); // bank code is less than 4
            PrefixTooLongErr:
                exit('1234567-51/1234'); // prefix is greater than 6
            PrefixIncorrectChecksumErr:
                exit('123456-51/1234'); // check sum of prefix is not valid
            IdentificationTooLongErr:
                exit('12345678901/1234'); // identification is greater than 10
            IdentificationTooShortErr:
                exit('123456-1/1234'); // identification is less than 2
            IdentificationNonZeroDigitsErr:
                exit('0000000000/1234'); // identification does not contains non zero characters
            IdentificationIncorrectChecksumErr:
                exit('1234567890/1234'); // check sum of identification is not valid
            FirstHyphenErr:
                exit('-51/1234'); // hyphen is first character
        end;
    end;

    [Scope('OnPrem')]
    procedure GetInvalidBankAccountNo(): Text[30]
    begin
        exit(GetBankAccountNoCausingError(IdentificationIncorrectChecksumErr));
    end;

    [Scope('OnPrem')]
    procedure GenerateVariableSymbol(): Code[10]
    begin
        exit(BankOperationsFunctions.CreateVariableSymbol(IncStr(LibraryUtility.GenerateGUID)));
    end;

    [Scope('OnPrem')]
    procedure FindBankAccount(var BankAcc: Record "Bank Account")
    begin
        LibraryERM.FindBankAccount(BankAcc);
    end;

    [Scope('OnPrem')]
    procedure FindBaseCalendar(var BaseCalendar: Record "Base Calendar")
    begin
        BaseCalendar.FindFirst;
    end;

    [Scope('OnPrem')]
    procedure InsertDefaultMatchingRules(BankAccApplRuleCode: Code[10])
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
    begin
        BankPmtApplRule."Bank Pmt. Appl. Rule Code" := BankAccApplRuleCode;
        BankPmtApplRule.InsertDefaultMatchingRules;
    end;
}
#endif
