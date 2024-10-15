codeunit 144220 "BE - SEPA.03 CT Unit Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        FieldBlankErr: Label 'The account must be a vendor, customer or employee account.';

    local procedure Initialize()
    var
        PaymentJournalLine: Record "Payment Journal Line";
    begin
        if not isInitialized then
            isInitialized := true;

        PaymentJournalLine.DeleteAll();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportWithErrors()
    var
        BankAccount: Record "Bank Account";
        BankExportImportSetup: Record "Bank Export/Import Setup";
        ExportProtocol: Record "Export Protocol";
        PaymentJournalLine: Record "Payment Journal Line";
    begin
        Initialize();

        // Setup.
        CreateBankExportImportSetup(BankExportImportSetup, CODEUNIT::"SEPA CT-Export File", XMLPORT::"SEPA CT pain.001.001.03",
          CODEUNIT::"SEPA CT-Check Line");
        CreateBankAccount(BankAccount, BankExportImportSetup.Code);
        CreateExportProtocol(ExportProtocol);
        CreateEBPaymentJournalLine(PaymentJournalLine, ExportProtocol.Code, BankAccount."No.", 4);

        PaymentJournalLine.Next(LibraryRandom.RandInt(PaymentJournalLine.Count));
        PaymentJournalLine."Account No." := '';
        PaymentJournalLine.Modify();

        // Exercise.
        asserterror ExportProtocol.ExportPaymentLines(PaymentJournalLine);

        // Verify.
        VerifyPaymentErrors(PaymentJournalLine."Applies-to Doc. No.", PaymentJournalLine."Line No.", FieldBlankErr, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentJournalLineErrorsAreDeleted()
    var
        BankAccount: Record "Bank Account";
        BankExportImportSetup: Record "Bank Export/Import Setup";
        ExportProtocol: Record "Export Protocol";
        PaymentJournalLine: Record "Payment Journal Line";
    begin
        Initialize();

        // Setup.
        CreateBankExportImportSetup(BankExportImportSetup, CODEUNIT::"SEPA CT-Export File", XMLPORT::"SEPA CT pain.001.001.03",
          CODEUNIT::"SEPA CT-Check Line");
        CreateBankAccount(BankAccount, BankExportImportSetup.Code);
        CreateExportProtocol(ExportProtocol);
        CreateEBPaymentJournalLine(PaymentJournalLine, ExportProtocol.Code, BankAccount."No.", 4);

        PaymentJournalLine.Next(LibraryRandom.RandInt(PaymentJournalLine.Count));
        PaymentJournalLine."Account No." := '';
        PaymentJournalLine.Modify();
        asserterror ExportProtocol.ExportPaymentLines(PaymentJournalLine);

        // Exercise.
        PaymentJournalLine.Delete(true);

        // Verify.
        VerifyPaymentErrors(PaymentJournalLine."Applies-to Doc. No.", PaymentJournalLine."Line No.", FieldBlankErr, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillBufferSunshine()
    var
        PaymentExportData: Record "Payment Export Data";
        BankAccount: Record "Bank Account";
        BankExportImportSetup: Record "Bank Export/Import Setup";
        ExportProtocol: Record "Export Protocol";
        PaymentJournalLine: Record "Payment Journal Line";
    begin
        Initialize();

        // Setup.
        CreateBankExportImportSetup(BankExportImportSetup, CODEUNIT::"SEPA CT-Export File", XMLPORT::"SEPA CT pain.001.001.03",
          CODEUNIT::"SEPA CT-Check Line");
        CreateBankAccount(BankAccount, BankExportImportSetup.Code);
        CreateExportProtocol(ExportProtocol);
        CreateEBPaymentJournalLine(PaymentJournalLine, ExportProtocol.Code, BankAccount."No.", 4);

        // Exercise.
        FillExportBuffer(PaymentJournalLine, PaymentExportData);

        // Verify.
        Assert.AreEqual(PaymentJournalLine.Count, PaymentExportData.Count, 'Incomplete data in buffer.');
        VerifyPaymentExportData(PaymentJournalLine, PaymentExportData);
    end;

    local procedure FillExportBuffer(PaymentJournalLine: Record "Payment Journal Line"; var PaymentExportData: Record "Payment Export Data")
    var
        GenJnlLine: Record "Gen. Journal Line";
        SEPACTFillExportBuffer: Codeunit "SEPA CT-Fill Export Buffer";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        PaymentExportData.DeleteAll();
        GenJnlLine.SetRange("Journal Batch Name", PaymentJournalLine."Journal Batch Name");
        GenJnlLine.SetRange("Journal Template Name", PaymentJournalLine."Journal Template Name");
        GenJnlLine.SetFilter("Line No.", SelectionFilterManagement.GetSelectionFilterForEBPaymentJournal(PaymentJournalLine));
        SEPACTFillExportBuffer.FillExportBuffer(GenJnlLine, PaymentExportData);
    end;

    local procedure CreateBankAccount(var BankAccount: Record "Bank Account"; BankExpImpFormat: Code[20])
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount."Payment Export Format" := BankExpImpFormat;
        BankAccount."Bank Account No." :=
          LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("Bank Account No."), DATABASE::"Bank Account");
        BankAccount.IBAN :=
          LibraryUtility.GenerateRandomCode(BankAccount.FieldNo(IBAN), DATABASE::"Bank Account");
        BankAccount."SWIFT Code" :=
          LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("SWIFT Code"), DATABASE::"Bank Account");
        BankAccount."Credit Transfer Msg. Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        BankAccount.Modify();
    end;

    local procedure CreateEBPaymentJournalLine(var PaymentJournalLine: Record "Payment Journal Line"; ExportProtocolCode: Code[20]; BankAccountNo: Code[20]; PaymentJournalLinesToCreate: Integer)
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        i: Integer;
    begin
        CreateGenJnlTemplate(GenJournalTemplate);
        CreateGenJnlBatch(GenJournalBatch, GenJournalTemplate.Name);
        CreateVendorWithBankAccount(Vendor, VendorBankAccount);

        with PaymentJournalLine do
            for i := 1 to PaymentJournalLinesToCreate do begin
                "Journal Template Name" := GenJournalTemplate.Name;
                "Journal Batch Name" := GenJournalBatch.Name;
                "Export Protocol Code" := ExportProtocolCode;
                "Bank Account" := BankAccountNo;
                "Line No." := i * 10000;
                "Applies-to Doc. No." := LibraryUtility.GenerateRandomCode(FieldNo("Applies-to Doc. No."), DATABASE::"Payment Journal Line");
                "Account Type" := "Account Type"::Vendor;
                "Account No." := Vendor."No.";
                "Beneficiary Bank Account" := VendorBankAccount.Code;
                "Beneficiary Bank Account No." := VendorBankAccount."Bank Account No.";
                "Applies-to Doc. Type" := "Applies-to Doc. Type"::Invoice;
                Amount := LibraryRandom.RandDec(100, 2);
                "Currency Code" := ''; // in BE LCY code is EUR so this needs to be blank!
                "Posting Date" := WorkDate();
                Insert();
            end;
    end;

    local procedure CreateExportProtocol(var ExportProtocol: Record "Export Protocol")
    begin
        with ExportProtocol do begin
            Code := LibraryUtility.GenerateRandomCode(FieldNo(Code), DATABASE::"Export Protocol");
            "Export Object Type" := "Export Object Type"::XMLPort;
            "Export Object ID" := XMLPORT::"SEPA CT pain.001.001.03";
            Insert();
        end;
    end;

    local procedure CreateVendorWithBankAccount(var Vendor: Record Vendor; var VendorBankAccount: Record "Vendor Bank Account")
    var
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
    end;

    local procedure CreateVendorBankAccount(var VendorBankAccount: Record "Vendor Bank Account"; VendorNo: Code[20])
    begin
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, VendorNo);
        VendorBankAccount.IBAN :=
          LibraryUtility.GenerateRandomCode(VendorBankAccount.FieldNo(IBAN), DATABASE::"Vendor Bank Account");
        VendorBankAccount."SWIFT Code" :=
          LibraryUtility.GenerateRandomCode(VendorBankAccount.FieldNo("SWIFT Code"), DATABASE::"Vendor Bank Account");
        VendorBankAccount.Modify();
    end;

    local procedure CreateBankExportImportSetup(var BankExportImportSetup: Record "Bank Export/Import Setup"; ProcessingCodeunit: Integer; ProcessingXmlPort: Integer; CheckCodeunit: Integer)
    begin
        BankExportImportSetup.Init();
        BankExportImportSetup.Code :=
          LibraryUtility.GenerateRandomCode(BankExportImportSetup.FieldNo(Code), DATABASE::"Bank Export/Import Setup");
        BankExportImportSetup."Preserve Non-Latin Characters" := true;
        BankExportImportSetup."Processing Codeunit ID" := ProcessingCodeunit;
        BankExportImportSetup."Processing XMLport ID" := ProcessingXmlPort;
        BankExportImportSetup."Check Export Codeunit" := CheckCodeunit;
        BankExportImportSetup.Insert();
    end;

    local procedure CreateGenJnlTemplate(var GenJournalTemplate: Record "Gen. Journal Template")
    begin
        GenJournalTemplate.Init();
        GenJournalTemplate.Name := LibraryUtility.GenerateRandomCode(GenJournalTemplate.FieldNo(Name), DATABASE::"Gen. Journal Template");
        GenJournalTemplate.Insert();
    end;

    local procedure CreateGenJnlBatch(var GenJournalBatch: Record "Gen. Journal Batch"; TemplateBatchName: Code[10])
    begin
        GenJournalBatch.Init();
        GenJournalBatch."Journal Template Name" := TemplateBatchName;
        GenJournalBatch.Name := LibraryUtility.GenerateRandomCode(GenJournalBatch.FieldNo(Name), DATABASE::"Gen. Journal Batch");
        GenJournalBatch."No. Series" :=
          LibraryUtility.GenerateRandomCode(GenJournalBatch.FieldNo("No. Series"), DATABASE::"Gen. Journal Batch");
        GenJournalBatch.Insert();
    end;

    local procedure VerifyPaymentExportData(var TempPaymentJournalLine: Record "Payment Journal Line" temporary; PaymentExportData: Record "Payment Export Data")
    begin
        TempPaymentJournalLine.FindSet();
        repeat
            VerifyPaymentLine(TempPaymentJournalLine, PaymentExportData);
        until TempPaymentJournalLine.Next() = 0;
    end;

    local procedure VerifyPaymentErrors(PaymentDocNo: Code[20]; LineNo: Integer; ExpErrorText: Text; ExpCount: Integer)
    var
        PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text";
    begin
        PaymentJnlExportErrorText.SetRange("Document No.", PaymentDocNo);
        PaymentJnlExportErrorText.SetRange("Journal Line No.", LineNo);
        PaymentJnlExportErrorText.SetRange("Error Text", ExpErrorText);
        Assert.AreEqual(ExpCount, PaymentJnlExportErrorText.Count, 'Error was encountered unexpectedly.');
    end;

    local procedure VerifyPaymentLine(PaymentJournalLine: Record "Payment Journal Line"; var PaymentExportData: Record "Payment Export Data")
    var
        VendorBankAccount: Record "Vendor Bank Account";
        BankAccount: Record "Bank Account";
    begin
        with PaymentJournalLine do begin
            PaymentExportData.SetRange("Document No.", "Applies-to Doc. No.");
            PaymentExportData.SetRange("Applies-to Ext. Doc. No.", "External Document No.");
            PaymentExportData.SetRange("Transfer Date", "Posting Date");
            PaymentExportData.SetRange("Currency Code", 'EUR');
            VendorBankAccount.Get("Account No.", "Beneficiary Bank Account");
            PaymentExportData.SetRange("Recipient Bank Acc. No.", VendorBankAccount.IBAN);
            PaymentExportData.SetRange("Recipient Bank BIC", VendorBankAccount."SWIFT Code");
            PaymentExportData.SetRange("Sender Bank Account Code", "Bank Account");
            BankAccount.Get("Bank Account");
            PaymentExportData.SetRange("Sender Bank Account No.", BankAccount.IBAN);
            PaymentExportData.SetRange("Sender Bank BIC", BankAccount."SWIFT Code");
            PaymentExportData.SetRange(Amount, Amount);
        end;

        Assert.AreEqual(1, PaymentExportData.Count, PaymentExportData.GetFilters);
    end;
}

