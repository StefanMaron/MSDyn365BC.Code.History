codeunit 144202 "HRP Payments"
{
    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    var
        LibraryHRP: Codeunit "Library - HRP";
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        IsInitialized: Boolean;
        IncorrectPaymentAmountErr: Label 'Incorrect payment amount.';
        IncorrectAmountErr: Label 'Incorrect Amount for field %1.';

    [Test]
    [Scope('OnPrem')]
    procedure PaymentForMainSalarySunshine()
    var
        PayrollPeriod: Record "Payroll Period";
        GenJnlLine: Record "Gen. Journal Line";
        EmployeeNo: Code[20];
        PayrollAmount: Decimal;
    begin
        // simple scenario - create payment for main payroll document

        // SETUP - create/post main payroll document
        Initialize;
        LibraryHRP.FindPayrollPeriod(PayrollPeriod);
        EmployeeNo := LibraryHRP.CreateNewEmployee(PayrollPeriod."Starting Date", GetRandomSalaryAmount);
        PayrollAmount := CreatePostPayrollDoc(EmployeeNo, PayrollPeriod);

        // EXERCISE - run suggest payment function
        InitGenJnlLine(GenJnlLine);
        LibraryHRP.SuggestPersonPayments(GenJnlLine, EmployeeNo,
          PayrollPeriod."Starting Date", PayrollPeriod."Ending Date", PayrollPeriod."Ending Date", false, false);

        // VERIFY - Payment amount has to be equal to payroll amount
        Assert.AreEqual(PayrollAmount, GenJnlLine.Amount, IncorrectPaymentAmountErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentForAdvanceSunshine()
    var
        PayrollPeriod: Record "Payroll Period";
        GenJnlLine: Record "Gen. Journal Line";
        EmployeeNo: Code[20];
        PayrollAmount: Decimal;
    begin
        // simple scenario - create payment for advance payroll document

        // SETUP - create/post advance payroll document
        Initialize;
        LibraryHRP.FindPayrollPeriod(PayrollPeriod);
        EmployeeNo := LibraryHRP.CreateNewEmployee(PayrollPeriod."Starting Date", GetRandomSalaryAmount);
        PayrollAmount := CreatePostPayrollAdvance(EmployeeNo, PayrollPeriod);

        // EXERCISE - run suggest payment function
        InitGenJnlLine(GenJnlLine);
        LibraryHRP.SuggestPersonPayments(GenJnlLine, EmployeeNo,
          PayrollPeriod."Starting Date", PayrollPeriod."Ending Date", PayrollPeriod."Advance Date", true, false);

        // VERIFY - Payment amount has to be equal to payroll amount
        Assert.AreEqual(PayrollAmount, GenJnlLine.Amount, IncorrectPaymentAmountErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentForMainSalaryAfterAdvance()
    var
        PayrollPeriod: Record "Payroll Period";
        GenJnlLine: Record "Gen. Journal Line";
        EmployeeNo: Code[20];
        AdvanceAmount: Decimal;
        MainDocAmount: Decimal;
    begin
        // two payroll documents and two payments: advance and main document
        // second payment amount has to be equal main document amout - advance amount

        // SETUP
        Initialize;
        LibraryHRP.FindPayrollPeriod(PayrollPeriod);
        EmployeeNo := LibraryHRP.CreateNewEmployee(PayrollPeriod."Starting Date", GetRandomSalaryAmount);

        // create and post advance and its payment
        AdvanceAmount := CreatePostPayrollAdvance(EmployeeNo, PayrollPeriod);
        InitGenJnlLine(GenJnlLine);
        LibraryHRP.SuggestPersonPayments(GenJnlLine, EmployeeNo,
          PayrollPeriod."Starting Date", PayrollPeriod."Ending Date", PayrollPeriod."Advance Date", true, true);

        // create and post main salary
        MainDocAmount := CreatePostPayrollDoc(EmployeeNo, PayrollPeriod);

        // EXERCISE - run suggest payment function for main payroll document
        LibraryHRP.SuggestPersonPayments(GenJnlLine, EmployeeNo,
          PayrollPeriod."Starting Date", PayrollPeriod."Ending Date", PayrollPeriod."Ending Date", false, false);

        // VERIFY - Payment amount has to be equal to difference between amounts for main document and advance
        Assert.AreEqual(MainDocAmount - AdvanceAmount, GenJnlLine.Amount, IncorrectPaymentAmountErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnePaymentPerMonthForSeveralPeriodsAtOnce()
    var
        PayrollPeriod: Record "Payroll Period";
        GenJnlLine: Record "Gen. Journal Line";
        EmployeeNo: Code[20];
        StartingDate: Date;
        i: Integer;
        PayrollAmount: array[3] of Decimal;
    begin
        // case for NC 51962
        // one payment per month
        // calculate payments for several periods at once

        // SETUP
        Initialize;
        LibraryHRP.FindPayrollPeriod(PayrollPeriod);
        EmployeeNo := LibraryHRP.CreateNewEmployee(PayrollPeriod."Starting Date", GetRandomSalaryAmount);

        // calculate and post payroll documents for three months
        PayrollPeriod.Reset();
        StartingDate := PayrollPeriod."Starting Date";
        for i := 1 to 3 do begin
            PayrollAmount[i] := CreatePostPayrollDoc(EmployeeNo, PayrollPeriod);
            PayrollPeriod.Next;
        end;

        // EXERCISE - suggest payments for 3 months at once
        InitGenJnlLine(GenJnlLine);
        LibraryHRP.SuggestPersonPayments(GenJnlLine, EmployeeNo,
          StartingDate, PayrollPeriod."Ending Date", PayrollPeriod."Ending Date", false, false);

        // VERIFY - payment for each paymend document has to be equal to its payroll amount
        VeryfySeveralPeriodPayments(GenJnlLine, PayrollAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TwoPaymentsPerMonthForSeveralPeriodsAtOnce()
    var
        PayrollPeriod: Record "Payroll Period";
        GenJnlLine: Record "Gen. Journal Line";
        EmployeeNo: Code[20];
        StartingDate: Date;
        PayrollAmount: array[3] of Decimal;
        i: Integer;
    begin
        // case for NC 51962
        // two payments per month
        // calculate payments for several periods at once

        // SETUP
        Initialize;
        LibraryHRP.FindPayrollPeriod(PayrollPeriod);
        EmployeeNo := LibraryHRP.CreateNewEmployee(PayrollPeriod."Starting Date", GetRandomSalaryAmount);

        // calculate and post payroll documents for three months (advance and main salary per month)
        PayrollPeriod.Reset();
        StartingDate := PayrollPeriod."Starting Date";
        for i := 1 to 3 do begin
            CreatePostPayrollAdvance(EmployeeNo, PayrollPeriod);
            PayrollAmount[i] := CreatePostPayrollDoc(EmployeeNo, PayrollPeriod);
            PayrollPeriod.Next;
        end;

        // EXERCISE - suggest payments for 3 months at once
        InitGenJnlLine(GenJnlLine);
        LibraryHRP.SuggestPersonPayments(GenJnlLine, EmployeeNo,
          StartingDate, PayrollPeriod."Ending Date", PayrollPeriod."Ending Date", false, false);

        // VERIFY - payment for each paymend document has to be equal to its payroll amount
        VeryfySeveralPeriodPayments(GenJnlLine, PayrollAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TwoPaymentsPerMonthForSeveralPeriodsOneByOne()
    var
        PayrollPeriod: Record "Payroll Period";
        GenJnlLine: Record "Gen. Journal Line";
        EmployeeNo: Code[20];
        StartingDate: Date;
        PayrollAmount: array[3] of Decimal;
        i: Integer;
    begin
        // case for NC 51962
        // two payments per month
        // calculate payments for several periods one by one

        // SETUP
        Initialize;
        LibraryHRP.FindPayrollPeriod(PayrollPeriod);
        EmployeeNo := LibraryHRP.CreateNewEmployee(PayrollPeriod."Starting Date", GetRandomSalaryAmount);

        // calculate and post payroll documents for three months (advance and main salary per month)
        PayrollPeriod.Reset();
        StartingDate := PayrollPeriod."Starting Date";
        for i := 1 to 3 do begin
            CreatePostPayrollAdvance(EmployeeNo, PayrollPeriod);
            PayrollAmount[i] := CreatePostPayrollDoc(EmployeeNo, PayrollPeriod);
            PayrollPeriod.Next;
        end;

        // EXERCISE - suggest payments for 3 months one by one
        PayrollPeriod.SetRange("Starting Date", StartingDate, PayrollPeriod."Starting Date");
        PayrollPeriod.FindSet();
        InitGenJnlLine(GenJnlLine);
        repeat
            LibraryHRP.SuggestPersonPayments(GenJnlLine, EmployeeNo,
              PayrollPeriod."Starting Date", PayrollPeriod."Ending Date", PayrollPeriod."Ending Date", false, false);
        until PayrollPeriod.Next = 0;

        // VERIFY - payment for each paymend document has to be equal to its payroll amount
        VeryfySeveralPeriodPayments(GenJnlLine, PayrollAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyPaymentApplication()
    var
        PayrollPeriod: Record "Payroll Period";
        Employee: Record Employee;
        PayrollApplicationMgt: Codeunit "Payroll Application Management";
        EmployeeNo: Code[20];
        PayrollAmount: Decimal;
        PaymentAmount: Decimal;
    begin
        Initialize;
        LibraryHRP.FindPayrollPeriod(PayrollPeriod);
        EmployeeNo := LibraryHRP.CreateNewEmployee(PayrollPeriod."Starting Date", GetRandomSalaryAmount);
        PayrollAmount := CreatePostPayrollDoc(EmployeeNo, PayrollPeriod);

        PaymentAmount := CreatePostVendorPayment(EmployeeNo, PayrollAmount);

        Employee.Get(EmployeeNo);
        PayrollApplicationMgt.ApplyEmployee(Employee, PayrollPeriod, 0D);

        VerifyVendorLedgEntry(EmployeeNo, PaymentAmount);
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        IsInitialized := true;
        Commit();
    end;

    local procedure InitGenJnlLine(var GenJnlLine: Record "Gen. Journal Line")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.FindGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        GenJnlLine.Init();
        GenJnlLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJnlLine."Journal Batch Name" := GenJournalBatch.Name;
    end;

    local procedure CreatePostPayrollDoc(EmployeeNo: Code[20]; PayrollPeriod: Record "Payroll Period"): Decimal
    begin
        LibraryHRP.ReleaseTimeSheet(PayrollPeriod.Code, EmployeeNo);
        LibraryHRP.CreatePayrollDoc(EmployeeNo, PayrollPeriod.Code, '', PayrollPeriod."Ending Date");
        LibraryHRP.PostPayrollDoc(EmployeeNo, PayrollPeriod."Ending Date");
        exit(GetPostedPayrollDocPayrollAmount(EmployeeNo, PayrollPeriod.Code));
    end;

    local procedure CreatePostPayrollAdvance(EmployeeNo: Code[20]; PayrollPeriod: Record "Payroll Period"): Decimal
    begin
        LibraryHRP.ReleaseTimeSheet(PayrollPeriod.Code, EmployeeNo);
        LibraryHRP.CreatePayrollDoc(EmployeeNo, PayrollPeriod.Code,
          LibraryHRP.FindAdvancePayrollCalcGroupCode, PayrollPeriod."Ending Date");
        LibraryHRP.PostPayrollDoc(EmployeeNo, PayrollPeriod."Ending Date");
        exit(GetPostedPayrollDocPayrollAmount(EmployeeNo, PayrollPeriod.Code));
    end;

    local procedure VeryfySeveralPeriodPayments(var GenJnlLine: Record "Gen. Journal Line"; ExpectedAmount: array[3] of Decimal)
    var
        i: Integer;
    begin
        i := 1;
        GenJnlLine.FindSet();
        repeat
            Assert.AreEqual(ExpectedAmount[i], GenJnlLine.Amount, IncorrectPaymentAmountErr);
            i := i + 1;
        until GenJnlLine.Next = 0;
    end;

    local procedure GetPostedPayrollDocPayrollAmount(EmployeeNo: Code[20]; PeriodCode: Code[10]): Decimal
    var
        PostedPayrollDocument: Record "Posted Payroll Document";
    begin
        with PostedPayrollDocument do begin
            SetRange("Employee No.", EmployeeNo);
            SetRange("Period Code", PeriodCode);
            FindLast;
            exit(CalcPayrollAmount)
        end;
    end;

    local procedure GetRandomSalaryAmount(): Decimal
    begin
        exit(LibraryRandom.RandIntInRange(10000, 30000));
    end;

    local procedure GenVendorNo(EmployeeNo: Code[20]): Code[20]
    var
        Employee: Record Employee;
        Person: Record Person;
    begin
        Employee.Get(EmployeeNo);
        Person.Get(Employee."Person No.");
        exit(Person."Vendor No.");
    end;

    local procedure CreatePostVendorPayment(EmployeeNo: Code[20]; PayrollAmount: Decimal): Decimal
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGenJournalTemplate(GenJnlTemplate);
        LibraryERM.CreateGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJnlLine, GenJnlTemplate.Name, GenJnlBatch.Name, GenJnlLine."Document Type"::Payment,
          GenJnlLine."Account Type"::Vendor, GenVendorNo(EmployeeNo),
          GenJnlLine."Account Type"::"G/L Account", GLAccount."No.",
          LibraryRandom.RandDecInRange(PayrollAmount, PayrollAmount + 10000, 2));
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
        exit(GenJnlLine.Amount);
    end;

    local procedure VerifyVendorLedgEntry(EmployeeNo: Code[20]; PaymentAmount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        AmountToPay: Decimal;
    begin
        with VendorLedgerEntry do begin
            SetRange("Vendor No.", GenVendorNo(EmployeeNo));
            FindFirst;
            CalcFields(Amount);
            AmountToPay := -Amount;
            SetRange("Document Type", "Document Type"::Payment);
            FindFirst;
            CalcFields(Amount, "Remaining Amount");
            Assert.AreEqual(PaymentAmount, Amount, StrSubstNo(IncorrectAmountErr, FieldCaption(Amount)));
            Assert.AreEqual(
              PaymentAmount - AmountToPay, "Remaining Amount",
              StrSubstNo(IncorrectAmountErr, FieldCaption("Remaining Amount")));
        end;
    end;
}

