codeunit 144350 "CH DTA/EZAG File Reports"
{
    // // [FEATURE] [DTA File] [EZAG File]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryDTA: Codeunit "Library - DTA";
        LibraryTextFileValidation: Codeunit "Library - Text File Validation";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        TestOption: Option "ESR5/15","ESR9/16","ESR9/27","ESR+5/15","ESR+9/16","ESR+9/27","Post Payment Domestic","Bank Payment Domestic","Cash Outpayment Order Domestic","Post Payment Abroad","Bank Payment Abroad","SWIFT Payment Abroad","Cash Outpayment Order Abroad";
        isInitialized: Boolean;
        FileLineValueIsWrongErr: Label 'Unexpected file value at position %1, length %2.';
        ExpectedValueErr: Label 'Expected value should not be empty.';

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestWriteTestFile()
    var
        DTASetup: Record "DTA Setup";
        DTASetupPage: TestPage "DTA Setup";
        File: Text;
    begin
        Initialize();

        LibraryDTA.CreateDTASetup(DTASetup, '', false);
        DTASetup.Validate("DTA File Folder", TemporaryPath);
        DTASetup.Modify(true);

        Commit();

        DTASetupPage.OpenEdit();
        DTASetupPage.GotoRecord(DTASetup);
        DTASetupPage."&Write Testfile".Invoke();

        File := DTASetup."DTA File Folder" + DTASetup."DTA Filename";

        Assert.IsTrue(Exists(File), 'No test file generated in ' + File);
        Erase(File);
    end;

    [Test]
    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler,MessageHandler,DTAFileRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestDTAFileWithoutCRLF()
    var
        DTASetup: Record "DTA Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLineArray: array[3] of Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        Vendor: Record Vendor;
        Dates: array[3] of Date;
        Amounts: array[3] of Decimal;
        File: Text;
        Line: Text[1024];
    begin
        Initialize();

        Dates[1] := WorkDate();
        Amounts[1] := -LibraryRandom.RandDecInRange(100, 1000, 2);

        LibraryDTA.CreateDTASetup(DTASetup, '', false);
        DTASetup.Validate("File Format", DTASetup."File Format"::"Without CR/LF");
        DTASetup.Modify(true);

        LibraryDTA.CreateTestGenJournalLines(Vendor, VendorBankAccount, GenJournalLineArray,
          GenJournalBatch, 1, Dates, Amounts, TestOption::"SWIFT Payment Abroad", '', '', false);
        RunDTASuggestVendorPayment(GenJournalBatch, GenJournalLineArray[1]."Account No.", Dates[1], Dates[1], false, DTASetup."Bank Code");

        Commit();

        LibraryVariableStorage.Enqueue(DTASetup."Bank Code");

        // 2. Exercise: Run Report DTA Payment Journal.
        REPORT.Run(REPORT::"DTA File");

        // Verify
        Line := CopyStr(LibraryTextFileValidation.ReadLine(CopyStr(File, 1, 1024), 1), 1, 1024);

        // Check the previous value on 3rd line would be on first line
        CheckColumnValue(VendorBankAccount.IBAN, Line, 330);
    end;

    [Test]
    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler,MessageHandler,DTAFileRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestDTAFile826()
    begin
        TestDTAFile(TestOption::"ESR5/15", false);
    end;

    [Test]
    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler,MessageHandler,DTAFileRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestDTAFile827()
    begin
        TestDTAFile(TestOption::"Bank Payment Domestic", true);
    end;

    [Test]
    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler,MessageHandler,DTAFileRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestDTAFile830()
    begin
        TestDTAFile(TestOption::"SWIFT Payment Abroad", false);
    end;

    [Test]
    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler,MessageHandler,DTAFileRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestDTAFile836()
    begin
        TestDTAFile(TestOption::"Bank Payment Abroad", true);
    end;

    [Test]
    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler,MessageHandler,EZAGFileRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestEZAGFile22()
    begin
        TestEZAGFile(TestOption::"Post Payment Domestic");
    end;

    [Test]
    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler,MessageHandler,EZAGFileRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestEZAGFile24()
    begin
        TestEZAGFile(TestOption::"Cash Outpayment Order Domestic");
    end;

    [Test]
    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler,MessageHandler,EZAGFileRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestEZAGFile27()
    begin
        TestEZAGFile(TestOption::"Bank Payment Domestic");
    end;

    [Test]
    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler,MessageHandler,EZAGFileRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestEZAGFile28()
    begin
        TestEZAGFile(TestOption::"ESR5/15");
    end;

    [Test]
    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler,MessageHandler,EZAGFileRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestEZAGFile32()
    begin
        TestEZAGFile(TestOption::"Post Payment Abroad");
    end;

    [Test]
    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler,MessageHandler,EZAGFileRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestEZAGFile34()
    begin
        TestEZAGFile(TestOption::"Cash Outpayment Order Abroad");
    end;

    [Test]
    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler,MessageHandler,EZAGFileRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestEZAGFile37()
    begin
        TestEZAGFile(TestOption::"SWIFT Payment Abroad");
    end;

    [Test]
    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler,MessageHandler,DTAFileRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestDTAFile830_Section4_BankAccNo()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        DTASetup: Record "DTA Setup";
        GenJournalLineArray: array[3] of Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        Vendor: Record Vendor;
        Dates: array[3] of Date;
        Amounts: array[3] of Decimal;
        File: Text;
        Line: Text[1024];
    begin
        // [SCENARIO 371966] "DTA File" -> Record 830 -> Section 4 -> Vendor Bank Account No. -> 21 chars length in position [6,26]
        Initialize();

        // [GIVEN] DTA Setup
        TestOption := TestOption::"Bank Payment Abroad";
        Dates[1] := WorkDate();
        Amounts[1] := -LibraryRandom.RandDecInRange(100, 1000, 2);
        LibraryDTA.CreateDTASetup(DTASetup, '', false);

        // [GIVEN] Foreign Vendor with Vendor Bank Account No. = '123456789012345678901' (21 chars length)
        LibraryDTA.CreateTestGenJournalLines(Vendor, VendorBankAccount, GenJournalLineArray,
          GenJournalBatch, 1, Dates, Amounts, TestOption, CreateCurrencyCode(), '', false);
        VendorBankAccount.Validate(IBAN, '');
        VendorBankAccount.Validate("Bank Account No.", LibraryUtility.GenerateRandomAlphabeticText(21, 0));
        VendorBankAccount.Modify();

        // [GIVEN] DTA Suggest Vendor Payments
        RunDTASuggestVendorPayment(GenJournalBatch, GenJournalLineArray[1]."Account No.", Dates[1], Dates[1], false, DTASetup."Bank Code");
        Commit();

        // [WHEN] Run "Generate DTA File"
        LibraryVariableStorage.Enqueue(DTASetup."Bank Code");
        REPORT.Run(REPORT::"DTA File");

        // [THEN] Generated DTA File has Vendor Bank Account No. with 21 chars length in Section 4 position [6,26] = '123456789012345678901'
        Line := CopyStr(LibraryTextFileValidation.ReadLine(CopyStr(File, 1, 1024), 4), 1, 1024);
        CheckColumnValue(VendorBankAccount."Bank Account No.", Line, 6);
    end;

    [Test]
    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler,MessageHandler,DTAFileRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestEncodingDTAFile()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        DTASetup: Record "DTA Setup";
        GenJournalLineArray: array[3] of Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        Vendor: Record Vendor;
        Dates: array[3] of Date;
        Amounts: array[3] of Decimal;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 166131] DTA File report exports country specific symbols with correct encoding
        Initialize();

        // [GIVEN] DTA Setup with DTA Sender Address contains country specific symbols
        LibraryDTA.CreateDTASetup(DTASetup, '', false);
        DTASetup."DTA Sender Address" := 'ÄäÜüöÖß';
        DTASetup.Modify();

        // [GIVEN] Payment posted
        Dates[1] := WorkDate();
        Amounts[1] := -LibraryRandom.RandDecInRange(100, 1000, 2);
        LibraryDTA.CreateTestGenJournalLines(Vendor, VendorBankAccount, GenJournalLineArray,
          GenJournalBatch, 1, Dates, Amounts, TestOption::"Bank Payment Abroad", '', '', false);
        RunDTASuggestVendorPayment(GenJournalBatch, GenJournalLineArray[1]."Account No.", Dates[1], Dates[1], false, DTASetup."Bank Code");

        // [WHEN] Run report DTA File
        Commit();
        LibraryVariableStorage.Enqueue(DTASetup."Bank Code");
        REPORT.Run(REPORT::"DTA File");

        // [THEN] Created file contains country specific symbols in correct encoding
        VerifyDTAFileSenderAddress(DTASetup);
    end;

    [Test]
    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler,MessageHandler,EZAGFileRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestEncodingEZAGFile()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        DTASetup: Record "DTA Setup";
        GenJournalLineArray: array[3] of Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        Vendor: Record Vendor;
        Dates: array[3] of Date;
        Amounts: array[3] of Decimal;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 166131] EZAG File report exports country specific symbols with correct encoding
        Initialize();

        // [GIVEN] Posted payment for vendor which has address with country specific symbols
        LibraryDTA.CreateEZAGSetup(DTASetup, '');
        Dates[1] := WorkDate();
        Amounts[1] := -LibraryRandom.RandDecInRange(100, 1000, 2);
        LibraryDTA.CreateTestGenJournalLines(Vendor, VendorBankAccount, GenJournalLineArray,
          GenJournalBatch, 1, Dates, Amounts, TestOption::"Bank Payment Domestic", '', '', false);
        RunDTASuggestVendorPayment(GenJournalBatch, GenJournalLineArray[1]."Account No.", Dates[1], Dates[1], false, DTASetup."Bank Code");
        SetVendorAddress(Vendor, 'ÄäÜüöÖß');

        // [WHEN] Run report EZAG File
        Commit();
        LibraryVariableStorage.Enqueue(DTASetup."Bank Code");
        REPORT.Run(REPORT::"EZAG File");

        // [THEN] Created file contains country specific symbols in correct encoding
        VerifyEZAGFileVendorAddress(Vendor);
    end;

    local procedure Initialize()
    var
        GenJournalLine: Record "Gen. Journal Line";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        // Lazy Setup.
        if not isInitialized then begin
            LibraryERMCountryData.CreateVATData();
            LibraryERMCountryData.UpdateAccountInVendorPostingGroups();
            LibraryERMCountryData.UpdateGeneralPostingSetup();
            LibraryERMCountryData.UpdatePurchasesPayablesSetup();
            LibraryERMCountryData.UpdateGenJournalTemplate();
            LibraryERMCountryData.UpdateGeneralLedgerSetup();
            isInitialized := true;
            Commit();
            exit;
        end;

        // Delete all Journal Lines
        GenJournalLine.Init();
        GenJournalLine.DeleteAll();
    end;

    local procedure RunDTASuggestVendorPayment(var GenJournalBatch: Record "Gen. Journal Batch"; VendorNo: Code[20]; FromDate: Date; ToDate: Date; EarlyPostingDate: Boolean; DebitToBank: Code[20])
    begin
        if EarlyPostingDate then
            DTASuggestVendorPayment(GenJournalBatch, VendorNo, CalcDate('<-1D>', ToDate), FromDate, ToDate, DebitToBank)
        else
            DTASuggestVendorPayment(GenJournalBatch, VendorNo, ToDate, FromDate, ToDate, DebitToBank);
    end;

    local procedure DTASuggestVendorPayment(GenJournalBatch: Record "Gen. Journal Batch"; VendorNo: Code[20]; PostingDate: Date; DueDateFrom: Date; DueDateTo: Date; DebitToBank: Code[20])
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        DTASuggestVendorPayments: Report "DTA Suggest Vendor Payments";
    begin
        GenJournalLine.Init();  // INIT is mandatory for Gen. Journal Line to Set the General Template and General Batch Name.
        GenJournalLine.Validate("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.Validate("Journal Batch Name", GenJournalBatch.Name);
        DTASuggestVendorPayments.DefineJournalName(GenJournalLine);

        LibraryVariableStorage.Enqueue(PostingDate);
        LibraryVariableStorage.Enqueue(DueDateFrom);
        LibraryVariableStorage.Enqueue(DueDateTo);
        LibraryVariableStorage.Enqueue(DebitToBank);
        LibraryVariableStorage.Enqueue(VendorNo);

        Vendor.SetRange("No.", VendorNo);
        DTASuggestVendorPayments.SetTableView(Vendor);
        DTASuggestVendorPayments.UseRequestPage(true);
        Commit();
        DTASuggestVendorPayments.RunModal();
    end;

    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler,MessageHandler,DTAFileRequestPageHandler')]
    local procedure TestDTAFile(TestOpt: Option; Backup: Boolean)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        DTASetup: Record "DTA Setup";
        GenJournalLineArray: array[3] of Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        Vendor: Record Vendor;
        Dates: array[3] of Date;
        Amounts: array[3] of Decimal;
    begin
        // Setup: Create and Post General Journal Line for Payment and Suggest Vendor Payment.
        Initialize();

        Dates[1] := WorkDate();
        Amounts[1] := -LibraryRandom.RandDecInRange(100, 1000, 2);
        LibraryDTA.CreateDTASetup(DTASetup, '', Backup);

        LibraryDTA.CreateTestGenJournalLines(Vendor, VendorBankAccount, GenJournalLineArray,
          GenJournalBatch, 1, Dates, Amounts, TestOpt, '', '', false);
        RunDTASuggestVendorPayment(GenJournalBatch, GenJournalLineArray[1]."Account No.", Dates[1], Dates[1], false, DTASetup."Bank Code");

        Commit();

        LibraryVariableStorage.Enqueue(DTASetup."Bank Code");

        // 2. Exercise: Run Report DTA Payment Journal.
        REPORT.Run(REPORT::"DTA File");

        // Verify
        VerifyDTAFile(TestOpt, DTASetup, VendorBankAccount, GenJournalLineArray[1]);
    end;

    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler,MessageHandler,EZAGFileRequestPageHandler')]
    local procedure TestEZAGFile(TestOpt: Option)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLineArray: array[3] of Record "Gen. Journal Line";
        DTASetup: Record "DTA Setup";
        VendorBankAccount: Record "Vendor Bank Account";
        Vendor: Record Vendor;
        Dates: array[3] of Date;
        Amounts: array[3] of Decimal;
    begin
        // Setup: Create and Post General Journal Line for Payment and Suggest Vendor Payment.
        Initialize();

        Dates[1] := WorkDate();
        Amounts[1] := -LibraryRandom.RandDecInRange(100, 1000, 2);
        LibraryDTA.CreateEZAGSetup(DTASetup, '');

        LibraryDTA.CreateTestGenJournalLines(Vendor, VendorBankAccount, GenJournalLineArray,
          GenJournalBatch, 1, Dates, Amounts, TestOpt, '', '', false);
        RunDTASuggestVendorPayment(GenJournalBatch, GenJournalLineArray[1]."Account No.", Dates[1], Dates[1], false, DTASetup."Bank Code");

        LibraryVariableStorage.Enqueue(DTASetup."Bank Code");

        // 2. Exercise: Run Report DTA Payment Journal.
        REPORT.Run(REPORT::"EZAG File");

        // Verify
        VerifyEZAGFile(TestOpt, DTASetup, VendorBankAccount, GenJournalLineArray[1], Vendor);
    end;

    local procedure CreateCurrencyCode(): Code[3]
    var
        Currency: Record Currency;
    begin
        Currency.Init();
        repeat
            Currency.Code := CopyStr(LibraryUtility.GenerateRandomText(3), 1, 3);
        until Currency.Insert();
        Currency."ISO Code" := CopyStr(Currency.Code, 1, 3);
        Currency.Modify();

        LibraryERM.CreateExchangeRate(
          Currency.Code, WorkDate(), LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2));
        exit(Currency.Code);
    end;

    [Scope('OnPrem')]
    procedure FindLineContainingValue(FileName: Text; StartingPosition: Integer; FieldLength: Integer; Value: Text) Line: Text
    var
        File: File;
        InStr: InStream;
        FieldValue: Text[1024];
    begin
        File.TextMode(true);
        File.Open(FileName, TEXTENCODING::Windows);
        File.Read(Line);
        File.CreateInStream(InStr);
        while (not InStr.EOS) and (StrPos(FieldValue, Value) = 0) do begin
            InStr.ReadText(Line);
            FieldValue := CopyStr(Line, StartingPosition, FieldLength);
        end;
        if StrPos(FieldValue, Value) = 0 then
            Line := '';  // If value is not found in the file, this will return an empty line.
    end;

    local procedure SetVendorAddress(var Vendor: Record Vendor; NewAdress: Text[50])
    begin
        Vendor.Address := NewAdress;
        Vendor.Modify(true);
    end;

    local procedure VerifyDTAFile(TestOpt: Option; DTASetup: Record "DTA Setup"; VendorBankAccount: Record "Vendor Bank Account"; GenJournalLine: Record "Gen. Journal Line")
    var
        File: Text;
        Line: Text[1024];
        BackupFile: Text;
    begin

        // Common Check: Sender Info
        Line := CopyStr(LibraryTextFileValidation.ReadLine(CopyStr(File, 1, 1024), 1), 1, 1024);
        CheckColumnValue(DTASetup."DTA Sender Clearing", Line, 32);
        CheckColumnValue(DTASetup."DTA Sender ID", Line, 39);
        CheckColumnValue(DTASetup."DTA Debit Acc. No.", Line, 70);

        // Amount With Comma:
        CheckColumnValue(ConvertStr(Format(-GenJournalLine."Amount (LCY)", 0, '<Integer><Decimals,3>'), '.', ','), Line, 103);

        Line := CopyStr(LibraryTextFileValidation.ReadLine(CopyStr(File, 1, 1024), 3), 1, 1024);

        // Vedor Account Check
        case TestOpt of
            TestOption::"ESR5/15": //826
                begin
                    CheckColumnValue(Format(VendorBankAccount."ESR Account No.", 0, '<Text,9><Filler Character,0>'), Line, 6);
                    CheckColumnValue(GenJournalLine."Reference No.", Line, 95);
                end;
            TestOption::"Bank Payment Domestic": //827
                CheckColumnValue(VendorBankAccount.IBAN, Line, 74);
            TestOption::"SWIFT Payment Abroad": //830
                begin
                    // A for SWIFT
                    CheckColumnValue('A', Line, 3);
                    // SWIFT Code & IBAN Value
                    CheckColumnValue(VendorBankAccount."SWIFT Code", Line, 4);
                    CheckColumnValue(VendorBankAccount.IBAN, Line, 74);
                end;
            TestOption::"Bank Payment Abroad": //836
                begin
                    // D for Other Account Type
                    CheckColumnValue('D', Line, 3);
                    CheckColumnValue(VendorBankAccount.IBAN, Line, 74);
                end;
        end;

        BackupFile := DTASetup."Backup Folder" + 'DTA' + IncStr(DTASetup."Last Backup No.") + '.BAK';
        if DTASetup."Backup Copy" then begin
            Assert.IsTrue(Exists(BackupFile), 'No backup was created in ' + BackupFile);
            Erase(BackupFile);
        end else
            Assert.IsFalse(Exists(BackupFile), 'Backup was created in ' + BackupFile);
    end;

    local procedure VerifyDTAFileSenderAddress(DTASetup: Record "DTA Setup")
    var
        FileName: Text;
        Line: Text;
    begin
        Line := FindLineContainingValue(FileName, 15, 24, DTASetup."DTA Sender Name");
        Assert.ExpectedMessage(DTASetup."DTA Sender Address", Line);
    end;

    local procedure VerifyEZAGFile(TestOpt: Option; DTASetup: Record "DTA Setup"; VendorBankAccount: Record "Vendor Bank Account"; GenJournalLine: Record "Gen. Journal Line"; Vendor: Record Vendor)
    var
        File: Text;
        Line: Text[1024];
    begin
        Line := CopyStr(LibraryTextFileValidation.ReadLine(CopyStr(File, 1, 1024), 1), 1, 1024);

        // Navision ID
        CheckColumnValue('543', Line, 1);

        // DTA Setup
        CheckColumnValue(DelChr(DTASetup."EZAG Debit Account No.", '=', '-'), Line, 16);
        CheckColumnValue(DelChr(DTASetup."EZAG Charges Account No.", '=', '-'), Line, 25);

        Line := CopyStr(LibraryTextFileValidation.ReadLine(CopyStr(File, 1, 1024), 2), 1, 1024);

        // Check Amount Fomrat
        CheckColumnValue(Format(100 * -GenJournalLine."Amount (LCY)", 0, '<Integer,13><Filler Character,0>'), Line, 54);

        // Check Vendor and Vendor Bank Account
        case TestOpt of
            TestOption::"Post Payment Domestic": //22
                begin
                    // Check Type
                    CheckColumnValue('22', Line, 36);
                    // Check Account
                    CheckColumnValue(DelChr(VendorBankAccount."Giro Account No.", '=', '-'), Line, 73);
                end;
            TestOption::"Cash Outpayment Order Domestic": //24
                begin
                    // Check Type
                    CheckColumnValue('24', Line, 36);

                    CheckColumnValue(Vendor.Name, Line, 123);
                    CheckColumnValue(Vendor.Address, Line, 193);
                    CheckColumnValue(Vendor."Post Code", Line, 228);
                    CheckColumnValue(Vendor.City, Line, 238);
                end;
            TestOption::"Bank Payment Domestic": //27
                begin
                    // Check Type
                    CheckColumnValue('27', Line, 36);
                    CheckColumnValue(VendorBankAccount.IBAN, Line, 88);

                    CheckColumnValue(Vendor.Name, Line, 263);
                    CheckColumnValue(Vendor.Address, Line, 333);
                    CheckColumnValue(Vendor."Post Code", Line, 368);
                    CheckColumnValue(Vendor.City, Line, 378);
                end;
            TestOption::"ESR5/15": //28
                begin
                    // Check Type
                    CheckColumnValue('28', Line, 36);

                    CheckColumnValue(VendorBankAccount."ESR Account No.", Line, 79);
                    CheckColumnValue(GenJournalLine."Reference No.", Line, 96);
                end;
            TestOption::"Post Payment Abroad": // 32
                begin
                    // Check Type
                    CheckColumnValue('32', Line, 36);

                    CheckColumnValue(VendorBankAccount."Country/Region Code", Line, 71);
                    CheckColumnValue(VendorBankAccount."Bank Account No.", Line, 88);

                    CheckColumnValue(Vendor.Name, Line, 123);
                    CheckColumnValue(Vendor.Address, Line, 193);
                    CheckColumnValue(Vendor."Post Code", Line, 228);
                    CheckColumnValue(Vendor.City, Line, 238);
                end;
            TestOption::"Cash Outpayment Order Abroad": // 34
                begin
                    // Check Type
                    CheckColumnValue('34', Line, 36);
                    CheckColumnValue(VendorBankAccount."Country/Region Code", Line, 71);

                    CheckColumnValue(Vendor.Name, Line, 123);
                    CheckColumnValue(Vendor.Address, Line, 193);
                    CheckColumnValue(Vendor."Post Code", Line, 228);
                    CheckColumnValue(Vendor.City, Line, 238);
                end;
            TestOption::"SWIFT Payment Abroad": // 37
                begin
                    // Check Type
                    CheckColumnValue('37', Line, 36);

                    CheckColumnValue(VendorBankAccount."Country/Region Code", Line, 71);
                    CheckColumnValue(VendorBankAccount.IBAN, Line, 88);

                    CheckColumnValue(Vendor.Name, Line, 263);
                    CheckColumnValue(Vendor.Address, Line, 333);
                    CheckColumnValue(Vendor."Post Code", Line, 368);
                    CheckColumnValue(Vendor.City, Line, 378);
                end;
        end;
    end;

    local procedure VerifyEZAGFileVendorAddress(Vendor: Record Vendor)
    var
        FileName: Text;
        Line: Text;
    begin
        Line := FindLineContainingValue(FileName, 263, 24, Vendor.Name);
        Assert.ExpectedMessage(Vendor.Address, Line);
    end;

    local procedure CheckColumnValue(Expected: Text; Line: Text[1024]; StartingPosition: Integer)
    var
        Actual: Text;
    begin
        if Expected = '' then
            Error(ExpectedValueErr);
        Actual := ReadFieldValue(Line, StartingPosition, StrLen(Expected));
        Assert.AreEqual(Expected, Actual, StrSubstNo(FileLineValueIsWrongErr, StartingPosition, StrLen(Expected)));
    end;

    local procedure ReadFieldValue(Line: Text[1024]; StartingPosition: Integer; Length: Integer): Text[1024]
    begin
        exit(LibraryTextFileValidation.ReadValue(Line, StartingPosition, Length));
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DTASuggestVendorPaymentsRequestPageHandler(var DTASuggestVendorPayments: TestRequestPage "DTA Suggest Vendor Payments")
    var
        VarPostingDate: Variant;
        VarDueDateFrom: Variant;
        VarDueDateTo: Variant;
        DebitToBank: Variant;
        VendorNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(VarPostingDate);
        LibraryVariableStorage.Dequeue(VarDueDateFrom);
        LibraryVariableStorage.Dequeue(VarDueDateTo);
        LibraryVariableStorage.Dequeue(DebitToBank);
        LibraryVariableStorage.Dequeue(VendorNo);

        DTASuggestVendorPayments."Posting Date".SetValue(VarPostingDate); // Posting Date
        DTASuggestVendorPayments."Due Date from".SetValue(VarDueDateFrom); // Due Date From
        DTASuggestVendorPayments."Due Date to".SetValue(VarDueDateTo); // Due Date To

        if Format(DebitToBank) <> '' then
            DTASuggestVendorPayments."ReqFormDebitBank.""Bank Code""".SetValue(DebitToBank);
        DTASuggestVendorPayments.Vendor.SetFilter("No.", VendorNo);

        DTASuggestVendorPayments.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DTAFileRequestPageHandler(var DTAFile: TestRequestPage "DTA File")
    var
        BankCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankCode);
        DTAFile."FileBank.""Bank Code""".SetValue(BankCode);
        DTAFile.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure EZAGFileRequestPageHandler(var EZAGFile: TestRequestPage "EZAG File")
    var
        BankCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankCode);
        EZAGFile."DtaSetup.""Bank Code""".SetValue(BankCode);
        EZAGFile.OK().Invoke();
    end;
}

