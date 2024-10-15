codeunit 18681 "Library TDS On Customer"
{
    procedure CreateTDSonCustomerSetup(var Customer: Record Customer; var TDSPostingSetup: Record "TDS Posting Setup"; var ConcessionalCode: Record "Concessional Code")
    var
        AssesseeCode: Record "Assessee Code";
        TDSSection: Record "TDS Section";
    begin
        CreateCommonSetup(AssesseeCode, ConcessionalCode);
        CreateTDSPostingSetupWithSection(TDSPostingSetup, TDSSection);
        CreateTDSCustomer(Customer, AssesseeCode.Code, TDSSection.Code);
    end;

    local procedure CreateCommonSetup(var AssesseeCode: Record "Assessee Code"; var ConcessionalCode: Record "Concessional Code")
    begin
        CreateTDSAccountingPeriod();
        FillCompanyInformation();
        CreateAssesseeCode(AssesseeCode);
        CreateConcessionalCode(ConcessionalCode);
    end;

    local procedure CreateTDSCustomer(var Customer: Record Customer; AssesseeCode: Code[10]; TDSSection: Code[10])
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        CreateZeroVATPostingSetup(VATPostingSetup);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("P.A.N. No.", LibraryUtility.GenerateRandomCode(Customer.FieldNo("P.A.N. No."), Database::"Customer"));
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Validate("Assessee Code", AssesseeCode);
        AttachSectionWithCustomer(Customer."No.", TDSSection);
        Customer.Modify(true);
    end;

    Procedure CreateTDSAccountingPeriod();
    var
        TaxType: Record "Tax Type";
        TDSSetup: Record "TDS Setup";
        Date: Record Date;
        CreateTaxAccountingPeriod: Report "Create Tax Accounting Period";
        PeriodLength: DateFormula;
    begin
        if not TDSSetup.Get() then
            exit;
        TaxType.Get(TDSSetup."Tax Type");
        Date.SETRANGE("Period Type", Date."Period Type"::Year);
        Date.SETRANGE("Period No.", DATE2DMY(WORKDATE(), 3));
        Date.FINDFIRST();
        CLEAR(CreateTaxAccountingPeriod);
        EVALUATE(PeriodLength, '<1M>');
        CreateTaxAccountingPeriod.InitializeRequest(12, PeriodLength, Date."Period Start", TaxType."Accounting Period");
        CreateTaxAccountingPeriod.HideConfirmationDialog(true);
        CreateTaxAccountingPeriod.USEREQUESTPAGE(FALSE);
        CreateTaxAccountingPeriod.RUN();
    end;

    procedure FillCompanyInformation()
    var
        CompInfo: Record "Company Information";
        GSTRegistrationNos: Record "GST Registration Nos.";
        CompInfo2: Record "Company Information";
    begin
        CompInfo.get();
        CompInfo2.get();
        if CompInfo2."GST Registration No." = '' then begin
            if GSTRegistrationNos.FindFirst() then
                CompInfo.Validate("P.A.N. No.", CopyStr(GSTRegistrationNos.Code, 3, 10))
            else
                CompInfo.Validate("P.A.N. No.", LibraryUtility.GenerateRandomCode(CompInfo.FieldNo("P.A.N. No."), Database::"Company Information"));
        end else
            CompInfo.Validate("P.A.N. No.", CopyStr(CompInfo2."GST Registration No.", 3, 10));
        CompInfo.Validate("Deductor Category", CreateDeductorCategory());
        CompInfo.Validate("T.A.N. No.", CreateTANNo());
        CompInfo.Modify(true);
    end;

    procedure CreateTANNo(): Code[10]
    var
        TANNos: Record "TAN Nos.";
    begin
        TANNos.Init();
        TANNos.VALIDATE(Code, LibraryUtility.GenerateRandomCode(TANNos.FIELDNO(Code), DATABASE::"TAN Nos."));
        TANNos.VALIDATE(Description, TANNos.Code);
        TANNos.Insert(TRUE);
        exit(TANNos.Code);
    end;

    procedure CreateLocationWithTANNo(var Location: Record Location)
    var
    begin
        LibraryWarehouse.CreateLocation(Location);
        Location.Validate("T.A.N. No.", CreateTANNo());
        Location.Modify(true);
    end;

    local procedure CreateDeductorCategory(): Code[20]
    var
        DeductorCategory: Record "Deductor Category";
    begin
        DeductorCategory.SetRange("DDO Code Mandatory", false);
        DeductorCategory.SetRange("PAO Code Mandatory", false);
        DeductorCategory.SetRange("State Code Mandatory", false);
        DeductorCategory.SetRange("Ministry Details Mandatory", false);
        DeductorCategory.SetRange("Transfer Voucher No. Mandatory", false);
        if DeductorCategory.FindFirst() then
            exit(DeductorCategory.Code)
        else begin
            DeductorCategory.Init();
            DeductorCategory.Validate(Code, LibraryUtility.GenerateRandomText(1));
            DeductorCategory.Insert(true);
            exit(DeductorCategory.Code);
        end;
    end;

    procedure CreateTDSPostingSetupWithSection(var TDSPostingSetup: Record "TDS Posting Setup"; var TDSSection: Record "TDS Section")
    begin
        CreateTDSSection(TDSSection);
        CreateTDSPostingSetup(TDSPostingSetup, TDSSection.Code);
    end;

    procedure CreateTDSSection(var TDSSection: Record "TDS Section"): Code[10]
    begin
        TDSSection.Init();
        TDSSection.Validate(Code, LibraryUtility.GenerateRandomCode(TDSSection.FIELDNO(Code), DATABASE::"TDS Section"));
        TDSSection.Validate(Description, TDSSection.Code);
        TDSSection.Insert(true);
        exit(TDSSection.Code);
    end;

    procedure CreateTDSPostingSetup(var TDSPostingSetup: Record "TDS Posting Setup"; TDSSectionCode: Code[10])
    begin
        TDSPostingSetup.Init();
        TDSPostingSetup.Validate("TDS Section", TDSSectionCode);
        TDSPostingSetup.Validate("Effective Date", WorkDate());
        TDSPostingSetup.Validate("TDS Account", CreateGLACcountNo());
        TDSPostingSetup.Validate("TDS Receivable Account", CreateGLACcountNo());
        TDSPostingSetup.Insert(true);
    end;

    procedure CreateAssesseeCode(var AssesseeCode: Record "Assessee Code"): Code[10]
    begin
        AssesseeCode.Init();
        AssesseeCode.Validate(Code, LibraryUtility.GenerateRandomCode(AssesseeCode.FieldNo(Code), Database::"Assessee Code"));
        AssesseeCode.Validate(Description, AssesseeCode.Code);
        AssesseeCode.Insert(true);
        exit(AssesseeCode.Code)
    end;

    procedure CreateConcessionalCode(var ConcessionalCode: Record "Concessional Code"): Code[10]
    begin
        ConcessionalCode.Init();
        ConcessionalCode.Validate(Code, LibraryUtility.GenerateRandomCode(ConcessionalCode.FIELDNO(Code), DATABASE::"Concessional Code"));
        ConcessionalCode.Validate(Description, ConcessionalCode.Code);
        ConcessionalCode.Insert(true);
        exit(ConcessionalCode.Code);
    end;

    procedure CreateGLACcountNo(): Code[20]
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        CreateZeroVATPostingSetup(VATPostingSetup);
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify();
        exit(GLAccount."No.");
    end;

    procedure CreateZeroVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        LibraryERM.FindZeroVATPostingSetup(VATPostingSetup, 0);
    end;

    procedure AttachSectionWithCustomer(CustomerNo: Code[20]; TDSSection: Code[10])
    var
        CustomerAllowedSection: Record "Customer Allowed Sections";
    begin
        CustomerAllowedSection.Init();
        CustomerAllowedSection.Validate("Customer No", CustomerNo);
        CustomerAllowedSection.Validate("TDS Section", TDSSection);
        CustomerAllowedSection.Validate("Surcharge Overlook", true);
        CustomerAllowedSection.Validate("Threshold Overlook", true);
        CustomerAllowedSection.Insert(true);
    end;

    procedure VerifyGLEntryCount(JnlBatchName: Code[10]; ExpectedCount: Integer): code[20]
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SETRANGE("Journal Batch Name", JnlBatchName);
        GLEntry.FindFirst();
        Assert.RecordCount(GLEntry, ExpectedCount);
        exit(GLEntry."Document No.");
    end;

    procedure CreateAndPostSalesDocumentWithTDSCertificateReceivable(
                    var SalesHeader: Record "Sales Header";
                    DocumentType: Enum "Sales Document Type";
                    CustomerNo: Code[20]): Code[20];
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Posting Date", WorkDate());
        SalesHeader.Validate("TDS Certificate Receivable", true);
        SalesHeader.Modify(true);
        CreateSalesLine(SalesHeader, SalesLine);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    procedure CreateAndPostSalesDocumentWithoutTDSCertificateReceivable(
                    var SalesHeader: Record "Sales Header";
                    DocumentType: Enum "Sales Document Type";
                    CustomerNo: Code[20]): Code[20];
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Posting Date", WorkDate());
        SalesHeader.Modify(true);
        CreateSalesLine(SalesHeader, SalesLine);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    procedure CreateSalesDocumentWithTDSCertificateReceivable(
                        var SalesHeader: Record "Sales Header";
                        DocumentType: Enum "Sales Document Type";
                        CustomerNo: Code[20]): Code[20];
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Posting Date", WorkDate());
        SalesHeader.Validate("TDS Certificate Receivable", true);
        SalesHeader.Modify(true);
        CreateSalesLine(SalesHeader, SalesLine);
    end;

    procedure CreateSalesDocumentWithoutTDSCertificateReceivable(
                        var SalesHeader: Record "Sales Header";
                        DocumentType: Enum "Sales Document Type";
                        CustomerNo: Code[20]): Code[20];
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Posting Date", WorkDate());
        SalesHeader.Modify(true);
        CreateSalesLine(SalesHeader, SalesLine);
    end;

    procedure CreateSalesLine(
        var SalesHeader: Record "Sales Header";
        var SalesLine: Record "Sales Line")
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItemNoWithoutVAT(), LibraryRandom.RandDec(1, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100000, 200000, 2));
        SalesLine.Modify(true);
    end;

    procedure CreateItemNoWithoutVAT(): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Item: Record Item;
    begin
        CreateZeroVATPostingSetup(VATPostingSetup);
        item.GET(LibraryInventory.CreateItemNoWithoutVAT());
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);
        exit(Item."No.");
    end;

    procedure AttachConcessionalWithTDSCustomer(ConcessionalCode: Code[10]; CustomerNo: Code[20]; TDSSection: code[10])
    var
        TDSCustomerConcessionalCode: Record "TDS Customer Concessional Code";
    begin
        TDSCustomerConcessionalCode.init();
        TDSCustomerConcessionalCode.Validate("Customer No.", CustomerNo);
        TDSCustomerConcessionalCode.Validate("TDS Section Code", TDSSection);
        TDSCustomerConcessionalCode.Validate("Concessional Code", ConcessionalCode);
        TDSCustomerConcessionalCode.Validate("Start Date", WorkDate());
        TDSCustomerConcessionalCode.Validate("End Date", CalcDate('<1M>', WorkDate()));
        TDSCustomerConcessionalCode.Validate("Certificate No.", LibraryUtility.GenerateRandomCode(TDSCustomerConcessionalCode.FieldNo("Certificate No."),
        Database::"TDS Customer Concessional Code"));
        TDSCustomerConcessionalCode.Insert(true);
    end;

    procedure CreateGenJournalLineWithTDSCertificateReceivableForBank(var GenJournalLine: Record "Gen. Journal Line";
                            CustomerNo: Code[20];
                            BankAccNo: Code[20];
                            VoucherType: Enum "Gen. Journal Template Type";
                            TDSSection: code[10]; LocationCode: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJournalTemplateBatch(GenJournalTemplate, GenJournalBatch, VoucherType, LocationCode);
        LibraryJournals.CreateGenJournalLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
        GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, CustomerNo,
        GenJournalLine."Bal. Account Type"::"Bank Account",
        BankAccNo, 0);
        GenJournalLine.Validate("T.A.N. No.", CreateTANNo());
        GenJournalLine.Validate("TDS Certificate Receivable", true);
        GenJournalLine.Validate("TDS Section Code", TDSSection);
        GenJournalLine.Validate(Amount, -LibraryRandom.RandDec(100000, 2));
        GenJournalLine.Modify(true);
    end;

    procedure CreateGenJournalLineWithTDSCertificateReceivableForGL(var GenJournalLine: Record "Gen. Journal Line";
                            CustomerNo: Code[20];
                            GLAccNo: Code[20];
                            VoucherType: Enum "Gen. Journal Template Type";
                            TDSSection: code[10]; LocationCode: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJournalTemplateBatch(GenJournalTemplate, GenJournalBatch, VoucherType, LocationCode);
        LibraryJournals.CreateGenJournalLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
        GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, CustomerNo,
        GenJournalLine."Bal. Account Type"::"G/L Account",
        GLAccNo, 0);
        GenJournalLine.Validate("T.A.N. No.", CreateTANNo());
        GenJournalLine.Validate("TDS Certificate Receivable", true);
        GenJournalLine.Validate("TDS Section Code", TDSSection);
        GenJournalLine.Validate(Amount, -LibraryRandom.RandDec(100000, 2));
        GenJournalLine.Modify(true);
    end;

    procedure CreateGenJournalLineWithTDSCertificateReceivable(var GenJournalLine: Record "Gen. Journal Line";
                            CustomerNo: Code[20];
                            VoucherType: Enum "Gen. Journal Template Type";
                            TDSSection: code[10])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJournalTemplateBatch(GenJournalTemplate, GenJournalBatch, VoucherType, '');
        LibraryJournals.CreateGenJournalLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
        GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, CustomerNo,
        GenJournalLine."Bal. Account Type"::"Bank Account",
        LibraryERM.CreateBankAccountNo(), 0);
        GenJournalLine.Validate("T.A.N. No.", CreateTANNo());
        GenJournalLine.Validate("TDS Certificate Receivable", true);
        GenJournalLine.Validate("TDS Section Code", TDSSection);
        GenJournalLine.Validate(Amount, -LibraryRandom.RandDec(100000, 2));
        GenJournalLine.Modify(true);
    end;

    procedure CreateGenJournalLineWithoutTDSCertificateReceivable(var GenJournalLine: Record "Gen. Journal Line";
                            CustomerNo: Code[20];
                            VoucherType: Enum "Gen. Journal Template Type";
                            TDSSection: code[10])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJournalTemplateBatch(GenJournalTemplate, GenJournalBatch, VoucherType, '');
        LibraryJournals.CreateGenJournalLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
        GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, CustomerNo,
        GenJournalLine."Bal. Account Type"::"Bank Account",
        LibraryERM.CreateBankAccountNo(), 0);
        GenJournalLine.Validate("T.A.N. No.", CreateTANNo());
        GenJournalLine.Validate("TDS Section Code", TDSSection);
        GenJournalLine.Validate(Amount, -LibraryRandom.RandDec(100000, 2));
        GenJournalLine.Modify(true);
    end;

    procedure CreateGenJournalLineWithoutTDSCertificateReceivableForBank(var GenJournalLine: Record "Gen. Journal Line";
                            CustomerNo: Code[20];
                            BankAccNo: Code[20];
                            VoucherType: Enum "Gen. Journal Template Type";
                            TDSSection: code[10]; LocationCode: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJournalTemplateBatch(GenJournalTemplate, GenJournalBatch, VoucherType, LocationCode);
        LibraryJournals.CreateGenJournalLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
        GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, CustomerNo,
        GenJournalLine."Bal. Account Type"::"Bank Account",
        BankAccNo, 0);
        GenJournalLine.Validate("T.A.N. No.", CreateTANNo());
        GenJournalLine.Validate("TDS Section Code", TDSSection);
        GenJournalLine.Validate(Amount, -LibraryRandom.RandDec(100000, 2));
        GenJournalLine.Modify(true);
    end;

    procedure CreateGenJournalLineWithoutTDSCertificateReceivableForGL(var GenJournalLine: Record "Gen. Journal Line";
                            CustomerNo: Code[20];
                            GLAccNo: Code[20];
                            VoucherType: Enum "Gen. Journal Template Type";
                            TDSSection: code[10]; LocationCode: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJournalTemplateBatch(GenJournalTemplate, GenJournalBatch, VoucherType, LocationCode);
        LibraryJournals.CreateGenJournalLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
        GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, CustomerNo,
        GenJournalLine."Bal. Account Type"::"G/L Account",
        GLAccNo, 0);
        GenJournalLine.Validate("T.A.N. No.", CreateTANNo());
        GenJournalLine.Validate("TDS Section Code", TDSSection);
        GenJournalLine.Validate(Amount, -LibraryRandom.RandDec(100000, 2));
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGenJournalTemplateBatch(var GenJournalTemplate: Record "Gen. Journal Template";
                                                    var GenJournalBatch: Record "Gen. Journal Batch";
                                                    VoucherType: Enum "Gen. Journal Template Type";
                                                    LocationCode: Code[20]);
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, VoucherType);
        GenJournalTemplate.Modify(true);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("Location Code", LocationCode);
        GenJournalBatch.Modify(true);
    end;

    procedure GetEntryNo(DocumentNo: Code[20]): Integer
    var
        CustledgerEntry: Record "Cust. Ledger Entry";
    begin
        CustledgerEntry.SetRange("Document No.", DocumentNo);
        if CustledgerEntry.FindFirst() then
            exit(CustledgerEntry."Entry No.")
        else
            exit(0);
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryJournals: Codeunit "Library - Journals";
}