codeunit 142500 "Export Payments File Handling"
{
    // 1. Verify that no error of Input Qualifier while doing export payement.
    // 
    // BUG ID 50988
    // ---------------------------------------------------------------------------
    // CheckExportPayment
    // ---------------------------------------------------------------------------

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Export Payments]
    end;

    var
        LibraryJournals: Codeunit "Library - Journals";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryTextFileValidation: Codeunit "Library - Text File Validation";
        FieldsAreNotEqualMsg: Label 'Actual value %2 is not equal to the expected value, which is %1.';
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;
        ExportedCVNameErr: Label 'Wrong Customer/Vendor Name in exported payment file.';

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TransmitExportedFileACH()
    var
        BankAccount: Record "Bank Account";
        ExportPaymentsACH: Codeunit "Export Payments (ACH)";
        FileName: Text[30];
        TempPath: Text;
    begin
        TempPath := CreateBankAccountWithExportPaths(BankAccount, BankAccount."Export Format"::US);
        FileName := CreateClientExportFile(BankAccount."E-Pay Export File Path");

        ExportPaymentsACH.TransmitExportedFile(BankAccount."No.", FileName);

        VerifyMovedFile(BankAccount, FileName);

        DeleteDirectory(TempPath);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TransmitExportedFileRB()
    var
        BankAccount: Record "Bank Account";
        ExportPaymentsRB: Codeunit "Export Payments (RB)";
        FileName: Text[30];
        TempPath: Text;
    begin
        TempPath := CreateBankAccountWithExportPaths(BankAccount, BankAccount."Export Format"::US);
        FileName := CreateClientExportFile(BankAccount."E-Pay Export File Path");

        ExportPaymentsRB.TransmitExportedFile(BankAccount."No.", FileName);

        VerifyMovedFile(BankAccount, FileName);

        DeleteDirectory(TempPath);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TransmitExportedFileCecoban()
    var
        BankAccount: Record "Bank Account";
        ExportPaymentsCecoban: Codeunit "Export Payments (Cecoban)";
        FileName: Text[30];
        TempPath: Text;
    begin
        TempPath := CreateBankAccountWithExportPaths(BankAccount, BankAccount."Export Format"::US);
        FileName := CreateClientExportFile(BankAccount."E-Pay Export File Path");

        ExportPaymentsCecoban.TransmitExportedFile(BankAccount."No.", FileName);

        VerifyMovedFile(BankAccount, FileName);

        DeleteDirectory(TempPath);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckExportPayment()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        ExportPaymentsRB: Codeunit "Export Payments (RB)";
        VendorNo: Code[20];
    begin
        // Verify that no error of Input Qualifier while doing export payment.
        Initialize;

        // Setup: Create Gen journal line and create Vendor bank account.
        UpdateCompanyInfo;
        VendorNo := CreateVendorWithBankAccount(BankAccount."Export Format"::US);
        CreateBankAccountWithExportPaths(BankAccount, BankAccount."Export Format"::US);
        ModifyBankAccount(BankAccount);
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Account Type"::Vendor, VendorNo, BankAccount."No.");

        // Exercise: Export Payment.
        ExportPaymentsRB.StartExportFile(BankAccount."No.", GenJournalLine);
        ExportPaymentsRB.ExportElectronicPayment(GenJournalLine, GenJournalLine.Amount, WorkDate);

        // Verify: File export successfully without Input Qualifier.
        ExportPaymentsRB.EndExportFile;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyRBExportedFileData()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        ExportPaymentsRB: Codeunit "Export Payments (RB)";
        VendorNo: Code[20];
    begin
        // Verify data of the RB exported file (only related to HF 363117)
        // this test should be used for future changes of RB electronic payment format
        Initialize;

        // Setup: Create Gen journal line and create Vendor bank account.
        UpdateCompanyInfo;
        VendorNo := CreateVendorWithBankAccount(BankAccount."Export Format"::US);
        CreateBankAccountWithExportPaths(BankAccount, BankAccount."Export Format"::US);
        ModifyBankAccount(BankAccount);
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Account Type"::Vendor, VendorNo, BankAccount."No.");

        // Exercise: Export Payment.
        ExportPaymentsRB.StartExportFile(BankAccount."No.", GenJournalLine);
        ExportPaymentsRB.ExportElectronicPayment(GenJournalLine, GenJournalLine.Amount, WorkDate);

        // Verify: Verify exported file
        ExportPaymentsRB.EndExportFile;
        VerifyRBFileData(BankAccount, VendorNo, GenJournalLine.Amount, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportPayments_ACH_VendorName()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
        TempPath: Text;
    begin
        // [FEATURE] [Export Payments (ACH)] [Payables]
        // [SCENARIO 364614] Exported Payment File (ACH) has 16-chars length Vendor.Name
        Initialize;
        UpdateCompanyInfo;

        // [GIVEN] Vendor with Name = "XY", where "X" = 16-chars length string, "Y" = 34-chars length string
        TempPath := CreateBankAccountWithExportPaths(BankAccount, BankAccount."Export Format"::US);
        VendorNo := CreateVendorWithBankAccount(BankAccount."Export Format"::US);

        // [GIVEN] Vendor general journal payment line
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Account Type"::Vendor, VendorNo, BankAccount."No.");

        // [WHEN] Export Payments (ACH)
        ExportPayments_ACH(GenJournalLine);

        // [THEN] Exported File (ACH) has Vendor name value = "X"
        VerifyExportedFileACHVendorName(VendorNo, BankAccount."No.");

        DeleteDirectory(TempPath);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportPayments_ACH_CustomerName()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        CustomerNo: Code[20];
        TempPath: Text;
    begin
        // [FEATURE] [Export Payments (ACH)] [Receivables]
        // [SCENARIO 364614] Exported Payment File (ACH) has 16-chars length Customer.Name
        Initialize;
        UpdateCompanyInfo;

        // [GIVEN] Customer with Name = "XY", where "X" = 16-chars length string, "Y" = 34-chars length string
        TempPath := CreateBankAccountWithExportPaths(BankAccount, BankAccount."Export Format"::US);
        CustomerNo := CreateCustomerWithBankAccount(BankAccount."Export Format"::US);

        // [GIVEN] Customer general journal payment line
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Account Type"::Customer, CustomerNo, BankAccount."No.");

        // [WHEN] Export Payments (ACH)
        ExportPayments_ACH(GenJournalLine);

        // [THEN] Exported File (ACH) has Customer name value = "X"
        VerifyExportedFileACHCustomerName(CustomerNo, BankAccount."No.");

        DeleteDirectory(TempPath);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportPayments_Cecoban_VendorName()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
        TempPath: Text;
    begin
        // [FEATURE] [Export Payments (Cecoban)] [Payables]
        // [SCENARIO 364614] Exported Payment File (Cecoban) has 40-chars length Vendor.Name
        Initialize;
        UpdateCompanyInfo;

        // [GIVEN] Vendor with Name = "XY", where "X" = 40-chars length string, "Y" = 10-chars length string
        TempPath := CreateBankAccountWithExportPaths(BankAccount, BankAccount."Export Format"::MX);
        VendorNo := CreateVendorWithBankAccount(BankAccount."Export Format"::MX);

        // [GIVEN] Vendor general journal payment line
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Account Type"::Vendor, VendorNo, BankAccount."No.");

        // [WHEN] Export Payments (Cecoban)
        ExportPayments_Cecoban(GenJournalLine);

        // [THEN] Exported File (Cecoban) has Vendor name value = "X"
        VerifyExportedFileCecobanVendorName(VendorNo, BankAccount."No.");

        DeleteDirectory(TempPath);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportPayments_Cecoban_CustomerName()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        CustomerNo: Code[20];
        TempPath: Text;
    begin
        // [FEATURE] [Export Payments (Cecoban)] [Receivables]
        // [SCENARIO 364614] Exported Payment File (Cecoban) has 40-chars length Customer.Name
        Initialize;
        UpdateCompanyInfo;

        // [GIVEN] Customer with Name = "XY", where "X" = 40-chars length string, "Y" = 10-chars length string
        TempPath := CreateBankAccountWithExportPaths(BankAccount, BankAccount."Export Format"::MX);
        CustomerNo := CreateCustomerWithBankAccount(BankAccount."Export Format"::MX);

        // [GIVEN] Customer general journal payment line
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Account Type"::Customer, CustomerNo, BankAccount."No.");

        // [WHEN] Export Payments (Cecoban)
        ExportPayments_Cecoban(GenJournalLine);

        // [THEN] Exported File (Cecoban) has Customer name value = "X"
        VerifyExportedFileCecobanCustomerName(CustomerNo, BankAccount."No.");

        DeleteDirectory(TempPath);
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore;

        if IsInitialized then
            exit;

        LibrarySetupStorage.Save(DATABASE::"Company Information");
        IsInitialized := true;
    end;

    local procedure ExportPayments_ACH(GenJournalLine: Record "Gen. Journal Line")
    var
        ExportPaymentsACH: Codeunit "Export Payments (ACH)";
        ServiceClassCode: Code[10];
    begin
        ServiceClassCode := CopyStr(LibraryUtility.GenerateRandomText(10), 1, MaxStrLen(ServiceClassCode));
        ExportPaymentsACH.StartExportFile(GenJournalLine."Bal. Account No.", CopyStr(LibraryUtility.GenerateRandomText(10), 1, 10));
        ExportPaymentsACH.StartExportBatch(
          ServiceClassCode, CopyStr(LibraryUtility.GenerateRandomText(10), 1, 10),
          CopyStr(LibraryUtility.GenerateRandomText(10), 1, 10), WorkDate);
        ExportPaymentsACH.ExportElectronicPayment(GenJournalLine, GenJournalLine.Amount);
        ExportPaymentsACH.EndExportBatch(ServiceClassCode);
        ExportPaymentsACH.EndExportFile;
    end;

    local procedure ExportPayments_Cecoban(GenJournalLine: Record "Gen. Journal Line")
    var
        ExportPaymentsCecoban: Codeunit "Export Payments (Cecoban)";
    begin
        ExportPaymentsCecoban.StartExportFile(
          GenJournalLine."Bal. Account No.", CopyStr(LibraryUtility.GenerateRandomText(10), 1, 10));
        ExportPaymentsCecoban.StartExportBatch(0, CopyStr(LibraryUtility.GenerateRandomText(10), 1, 10), WorkDate);
        ExportPaymentsCecoban.ExportElectronicPayment(GenJournalLine, GenJournalLine.Amount, WorkDate);
        ExportPaymentsCecoban.EndExportBatch;
        ExportPaymentsCecoban.EndExportFile;
    end;

    local procedure CreateBankAccountWithExportPaths(var BankAccount: Record "Bank Account"; ExportFormat: Option) TempPath: Text
    begin
        TempPath := GetTempPath;
        LibraryERM.CreateBankAccount(BankAccount);
        with BankAccount do begin
            "E-Pay Export File Path" := CopyStr(CreateDirectory(TempPath + 'Misc\'), 1, MaxStrLen("E-Pay Export File Path"));
            "E-Pay Trans. Program Path" := CopyStr(CreateDirectory(TempPath + 'Trans\'), 1, MaxStrLen("E-Pay Trans. Program Path"));
            "Last E-Pay Export File Name" := 'ExportPayments000.txt';
            "Export Format" := ExportFormat;
            "Transit No." := GetTransitNo(ExportFormat);
            Modify;
        end;
    end;

    local procedure CreateClientExportFile(ExportFolderName: Text): Text[30]
    var
        FileName: Text[30];
    begin
        FileName := LibraryUtility.GenerateGUID + '.txt';
        CreateFile(ExportFolderName + FileName);
        exit(FileName);
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Option; AccountNo: Code[20]; BankAccountNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        LibraryUTUtility: Codeunit "Library UT Utility";
    begin
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        with GenJournalLine do begin
            LibraryERM.CreateGeneralJnlLine(
              GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
              "Document Type"::Payment, AccountType, AccountNo, LibraryRandom.RandDec(100, 2));
            if "Account Type" = "Account Type"::Vendor then
                Amount := -Amount;
            Validate("Bal. Account Type", "Bal. Account Type"::"Bank Account");
            Validate("Bal. Account No.", BankAccountNo);
            Validate("Bank Payment Type", "Bank Payment Type"::"Electronic Payment");
            Validate("Transaction Code", CopyStr(LibraryUTUtility.GetNewCode10, 1, MaxStrLen("Transaction Code")));
            Validate("Company Entry Description", CopyStr(AccountNo, 1, 10));
            Modify(true);
        end;
    end;

    local procedure CreateVendorWithBankAccount(ExportFormat: Option ,US,CA,MX): Code[20]
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, CreateLongNameVendorNo);
        with VendorBankAccount do begin
            Validate("Bank Account No.", "Vendor No.");
            Validate("Use for Electronic Payments", true);
            Validate("Transit No.", GetTransitNo(ExportFormat));
            Modify;
            exit("Vendor No.");
        end;
    end;

    local procedure CreateCustomerWithBankAccount(ExportFormat: Option ,US,CA,MX): Code[20]
    var
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, CreateLongNameCustomerNo);
        with CustomerBankAccount do begin
            Validate("Bank Account No.", "Customer No.");
            Validate("Use for Electronic Payments", true);
            Validate("Transit No.", GetTransitNo(ExportFormat));
            Modify;
            exit("Customer No.");
        end;
    end;

    local procedure CreateLongNameVendorNo(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        with Vendor do begin
            Validate(Name, LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(Name), 0));
            Modify;
            exit("No.");
        end;
    end;

    local procedure CreateLongNameCustomerNo(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        with Customer do begin
            Validate(Name, LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(Name), 0));
            Modify;
            exit("No.");
        end;
    end;

    local procedure GetTempPath(): Text
    begin
        exit(TemporaryPath + Format(CreateGuid) + '\');
    end;

    local procedure GetTransitNo(ExportFormat: Option ,US,CA,MX): Text[20]
    begin
        // Special values for Checksum
        case ExportFormat of
            ExportFormat::US:
                exit('123456780');
            ExportFormat::MX:
                exit('123456789012345678');
            else
                exit('');
        end;
    end;

    local procedure GetBankExportFileName(BankAccountNo: Code[20]): Text
    var
        BankAccount: Record "Bank Account";
    begin
        with BankAccount do begin
            Get(BankAccountNo);
            exit("E-Pay Export File Path" + "Last E-Pay Export File Name");
        end;
    end;

    local procedure CreateDirectory(FilePathName: Text): Text
    var
        FileManagement: Codeunit "File Management";
    begin
        FileManagement.CreateClientDirectory(FilePathName);
        exit(FilePathName);
    end;

    local procedure DeleteDirectory(FilePathName: Text)
    var
        FileManagement: Codeunit "File Management";
    begin
        FileManagement.DeleteClientDirectory(FilePathName);
    end;

    local procedure CreateFile(FilePathName: Text)
    var
        FileManagement: Codeunit "File Management";
    begin
        FileManagement.CreateClientFile(FilePathName);
    end;

    local procedure DeleteFile(FilePathName: Text)
    var
        FileManagement: Codeunit "File Management";
    begin
        FileManagement.DeleteClientFile(FilePathName);
    end;

    local procedure ModifyBankAccount(var BankAccount: Record "Bank Account")
    var
        BankAccountPostingGroup: Record "Bank Account Posting Group";
    begin
        with BankAccount do begin
            LibraryERM.FindBankAccountPostingGroup(BankAccountPostingGroup);
            Validate("Export Format", "Export Format"::CA);
            Validate("Transit No.", "No.");
            Validate("Client No.", "No.");
            Validate("Client Name", "Client No.");
            Validate("Last E-Pay Export File Name", "No.");
            Validate("Bank Acc. Posting Group", BankAccountPostingGroup.Code);
            Validate("E-Pay Export File Path", TemporaryPath);
            Validate("Last E-Pay Export File Name", Format(LibraryRandom.RandInt(10)));
            Modify(true);
        end;
    end;

    local procedure UpdateCompanyInfo()
    var
        CompanyInformation: Record "Company Information";
    begin
        with CompanyInformation do begin
            Get;
            Validate("Federal ID No.", LibraryUtility.GenerateGUID);
            Modify;
        end;
    end;

    local procedure VerifyMovedFile(BankAccount: Record "Bank Account"; FileName: Text)
    var
        [RunOnClient]
        ClientFileHelper: DotNet File;
    begin
        Assert.IsTrue(
          ClientFileHelper.Exists(BankAccount."E-Pay Trans. Program Path" + FileName),
          StrSubstNo('File is expected to be in folder %1', BankAccount."E-Pay Trans. Program Path"));
        Assert.IsFalse(
          ClientFileHelper.Exists(BankAccount."E-Pay Export File Path" + FileName),
          StrSubstNo('File is not expected to be in folder %1', BankAccount."E-Pay Export File Path"));
    end;

    local procedure FormatNumToPrnString(Number: Integer): Text[250]
    var
        TmpString: Text[250];
    begin
        TmpString := DelChr(Format(Number), '=', '.,-');
        exit(TmpString)
    end;

    local procedure FormatAmtToPrnString(Amount: Decimal): Text[250]
    var
        TmpString: Text[250];
        I: Integer;
    begin
        TmpString := Format(Amount);
        I := StrPos(TmpString, '.');
        case true of
            I = 0:
                TmpString := TmpString + '.00';
            I = StrLen(TmpString) - 1:
                TmpString := TmpString + '0';
        end;
        TmpString := DelChr(TmpString, '=', '.,-');
        exit(TmpString)
    end;

    local procedure ReadExportedFile_ACH_NameValue(FileName: Text): Text
    begin
        exit(LibraryTextFileValidation.ReadValueFromLine(CopyStr(FileName, 1, 1024), 3, 59, 16));
    end;

    local procedure ReadExportedFile_Cecoban_NameValue(FileName: Text): Text
    begin
        exit(LibraryTextFileValidation.ReadValueFromLine(CopyStr(FileName, 1, 1024), 2, 91, 40));
    end;

    local procedure VerifyRBFileData(BankAccount: Record "Bank Account"; VendorNo: Code[20]; TotalOfCreditPaymentTrans: Decimal; NumberOfCreditPaymentTrans: Integer)
    var
        FileName: Text[250];
    begin
        FileName := BankAccount."E-Pay Export File Path" + IncStr(BankAccount."Last E-Pay Export File Name");

        // trailer record
        VerifyField(FileName, FormatAmtToPrnString(TotalOfCreditPaymentTrans), 7, 'ZTRL', 27, 14, true); // ZTRL marks trailer record
        VerifyField(FileName, FormatNumToPrnString(NumberOfCreditPaymentTrans), 7, 'ZTRL', 21, 6, true); // ZTRL marks trailer record

        // basic payment record
        VerifyField(FileName, 'C', 22, VendorNo, 7, 1, false); // 'C' marks payment rec
    end;

    local procedure VerifyField(FileName: Text[250]; ExpectedValue: Text[1024]; IdentifierStartingPosition: Integer; IdentifierString: Text[1024]; StartingPosition: Integer; FieldSize: Integer; IsZeroFill: Boolean)
    var
        FieldValue: Text[1024];
        Filler: Text[1];
        FillerString: Text;
    begin
        if IsZeroFill then
            Filler := '0'
        else
            Filler := ' ';

        FillerString := PadStr('', FieldSize - StrLen(ExpectedValue), Filler);

        FieldValue :=
          LibraryTextFileValidation.ReadValue(LibraryTextFileValidation.FindLineWithValue(FileName, IdentifierStartingPosition,
              StrLen(IdentifierString), IdentifierString), StartingPosition, FieldSize);
        Assert.AreEqual(FillerString + ExpectedValue, FieldValue,
          StrSubstNo(FieldsAreNotEqualMsg, PadStr(ExpectedValue, FieldSize, '0'), FieldValue));
    end;

    local procedure VerifyExportedFileACHVendorName(VendorNo: Code[20]; BankAccountNo: Code[20])
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        Assert.AreEqual(
          CopyStr(Vendor.Name, 1, 16), ReadExportedFile_ACH_NameValue(GetBankExportFileName(BankAccountNo)), ExportedCVNameErr);
    end;

    local procedure VerifyExportedFileACHCustomerName(CustomerNo: Code[20]; BankAccountNo: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        Assert.AreEqual(
          CopyStr(Customer.Name, 1, 16), ReadExportedFile_ACH_NameValue(GetBankExportFileName(BankAccountNo)), ExportedCVNameErr);
    end;

    local procedure VerifyExportedFileCecobanVendorName(VendorNo: Code[20]; BankAccountNo: Code[20])
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        Assert.AreEqual(
          CopyStr(Vendor.Name, 1, 40), ReadExportedFile_Cecoban_NameValue(GetBankExportFileName(BankAccountNo)), ExportedCVNameErr);
    end;

    local procedure VerifyExportedFileCecobanCustomerName(CustomerNo: Code[20]; BankAccountNo: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        Assert.AreEqual(
          CopyStr(Customer.Name, 1, 40), ReadExportedFile_Cecoban_NameValue(GetBankExportFileName(BankAccountNo)), ExportedCVNameErr);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

