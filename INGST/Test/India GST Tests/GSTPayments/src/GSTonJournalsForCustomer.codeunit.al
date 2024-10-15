codeunit 18271 "GST on Journals For Customer"
{
    Subtype = Test;

    var
        VATPostingSetup: Record "VAT Posting Setup";
        LibraryRandom: Codeunit "Library - Random";
        LibraryGST: Codeunit "Library GST";
        ComponentPerArray: array[20] of Decimal;
        Storage: Dictionary of [Text, Text];
        StorageEnum: Dictionary of [Text, Text];
        StorageBoolean: Dictionary of [Text, Boolean];

    //[Scenario 355678] -Check if system is not calculating GST on Advance Receipt for : - Customer - SEZ Development.
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VoucherAccountDebit')]
    procedure PostFromBankReceiptVoucherWithGSTOnAdvanceReceiptForSEZDevelopment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Assert: Codeunit Assert;
        GSTGroupType: Enum "GST Group Type";
        GSTCustomerType: Enum "GST Customer Type";
        TemplateType: Enum "Gen. Journal Template Type";
        GSTOnAdvanceReceiptErr: Label 'GST on Advance Payment must be equal to ''No'' in Gen. Journal Line: Journal Template Name= %1, Journal Batch Name= %2, Line No.= %3. Current value is ''Yes''', Comment = '%1 = Journal Template Name,%2 = Journal Batch Name,%3= Line No.';
    begin
        //[GIVEN] Created GST Setup
        InitializeShareStep(false);
        CreateGSTSetup(GSTCustomerType::"SEZ Development", GSTGroupType::Service, false, false);
        CreateLocationWithVoucherSetup(TemplateType::"Bank Receipt Voucher");

        //[WHEN] Create and Post Bank Rceipt Voucher
        CreateGenJnlLineForVoucherWithoutAdvancePayment(GenJournalLine, TemplateType::"Bank Receipt Voucher");

        //[THEN] Assert error Verified
        asserterror GenJournalLine.Validate("GST on Advance Payment", true);
        Assert.IsFalse(GenJournalLine."GST on Advance Payment", StrSubstNo(GSTOnAdvanceReceiptErr, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No."));
    end;

    //[Scenario 355662] -Check if system is not calculating GST on Advance Receipt for : - Customer - Export.
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VoucherAccountDebit')]
    procedure PostFromBankReceiptVoucherWithGSTOnAdvanceReceiptForExport()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Assert: Codeunit Assert;
        GSTGroupType: Enum "GST Group Type";
        GSTCustomerType: Enum "GST Customer Type";
        TemplateType: Enum "Gen. Journal Template Type";
        GSTOnAdvanceReceiptErr: Label 'GST on Advance Payment must be equal to ''No'' in Gen. Journal Line: Journal Template Name= %1, Journal Batch Name= %2, Line No.= %3. Current value is ''Yes''', Comment = '%1 = Journal Template Name,%2 = Journal Batch Name,%3= Line No.';
    begin
        //[GIVEN] Created GST Setup
        InitializeShareStep(false);
        CreateGSTSetup(GSTCustomerType::Export, GSTGroupType::Service, false, false);
        CreateLocationWithVoucherSetup(TemplateType::"Bank Receipt Voucher");

        //[WHEN] Create and Post Bank Receipt Voucher
        CreateGenJnlLineForVoucherWithoutAdvancePayment(GenJournalLine, TemplateType::"Bank Receipt Voucher");

        //[THEN] Assert error Verified
        asserterror GenJournalLine.Validate("GST on Advance Payment", true);
        Assert.IsFalse(GenJournalLine."GST on Advance Payment", StrSubstNo(GSTOnAdvanceReceiptErr, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No."));
    end;

    //[Scenario 355668] - Check if system is not calculating GST on Advance Receipt for : - Customer - Deemed Exports.
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VoucherAccountDebit')]
    procedure PostFromBankReceiptVoucherWithGSTOnAdvanceReceiptForDeemedExports()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Assert: Codeunit Assert;
        GSTGroupType: Enum "GST Group Type";
        GSTCustomerType: Enum "GST Customer Type";
        TemplateType: Enum "Gen. Journal Template Type";
        GSTOnAdvanceReceiptErr: Label 'GST on Advance Payment must be equal to ''No'' in Gen. Journal Line: Journal Template Name= %1, Journal Batch Name= %2, Line No.= %3. Current value is ''Yes''', Comment = '%1 = Journal Template Name,%2 = Journal Batch Name,%3= Line No.';
    begin
        //[GIVEN] Created GST Setup
        InitializeShareStep(false);
        CreateGSTSetup(GSTCustomerType::"Deemed Export", GSTGroupType::Service, false, false);
        CreateLocationWithVoucherSetup(TemplateType::"Bank Receipt Voucher");

        //[WHEN] Create and Post Bank Receipt Voucher
        CreateGenJnlLineForVoucherWithoutAdvancePayment(GenJournalLine, TemplateType::"Bank Receipt Voucher");

        //[THEN] Assert error Verified
        asserterror GenJournalLine.Validate("GST on Advance Payment", true);
        Assert.IsFalse(GenJournalLine."GST on Advance Payment", StrSubstNo(GSTOnAdvanceReceiptErr, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No."));
    end;

    //[Scenario 355674]- Check if system is not calculating GST on Advance Receipt for : - Customer - SEZ Unit.
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VoucherAccountDebit')]
    procedure PostFromBankReceiptVoucherWithGSTOnAdvanceReceiptForSEZUnit()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Assert: Codeunit Assert;
        GSTGroupType: Enum "GST Group Type";
        GSTCustomerType: Enum "GST Customer Type";
        TemplateType: Enum "Gen. Journal Template Type";
        GSTOnAdvanceReceiptErr: Label 'GST on Advance Payment must be equal to ''No'' in Gen. Journal Line: Journal Template Name= %1, Journal Batch Name= %2, Line No.= %3. Current value is ''Yes''', Comment = '%1 = Journal Template Name,%2 = Journal Batch Name,%3= Line No.';
    begin
        //[GIVEN] Created GST Setup
        InitializeShareStep(false);
        CreateGSTSetup(GSTCustomerType::"SEZ Unit", GSTGroupType::Service, false, false);
        CreateLocationWithVoucherSetup(TemplateType::"Bank Receipt Voucher");

        //[WHEN] Create and Post Bank Receipt Voucher
        CreateGenJnlLineForVoucherWithoutAdvancePayment(GenJournalLine, TemplateType::"Bank Receipt Voucher");

        //[THEN] Assert error Verified
        asserterror GenJournalLine.Validate("GST on Advance Payment", true);
        Assert.IsFalse(GenJournalLine."GST on Advance Payment", StrSubstNo(GSTOnAdvanceReceiptErr, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No."));
    end;

    //[Scenario 355677]- Check if system is not calculating GST on Advance Receipt for : - Customer - Exempted.
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VoucherAccountDebit')]
    procedure PostFromBankReceiptVoucherWithGSTOnAdvanceReceiptForExemptedCustomer()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Assert: Codeunit Assert;
        GSTGroupType: Enum "GST Group Type";
        GSTCustomerType: Enum "GST Customer Type";
        TemplateType: Enum "Gen. Journal Template Type";
        GSTOnAdvanceReceiptErr: Label 'GST on Advance Payment must be equal to ''No'' in Gen. Journal Line: Journal Template Name= %1, Journal Batch Name= %2, Line No.= %3. Current value is ''Yes''', Comment = '%1 = Journal Template Name,%2 = Journal Batch Name,%3= Line No.';
    begin
        //[GIVEN] Created GST Setup
        InitializeShareStep(true);
        CreateGSTSetup(GSTCustomerType::Exempted, GSTGroupType::Service, false, false);
        CreateLocationWithVoucherSetup(TemplateType::"Bank Receipt Voucher");

        //[WHEN] Create and Post Bank Receipt Voucher
        CreateGenJnlLineForVoucherWithoutAdvancePayment(GenJournalLine, TemplateType::"Bank Receipt Voucher");

        //[THEN] Assert error Verified
        asserterror GenJournalLine.Validate("GST on Advance Payment", true);
        Assert.IsFalse(GenJournalLine."GST on Advance Payment", StrSubstNo(GSTOnAdvanceReceiptErr, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No."));
    end;

    //[Scenario 358548] Inter-State Sales of Goods to Registered or Unregistered Customer through Sale Journal
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromSalesJournalForGoodsRegisteredInterState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        LibraryERM: Codeunit "Library - ERM";
        GSTGroupType: Enum "GST Group Type";
        GSTCustomerType: Enum "GST Customer Type";
        TemplateType: enum "Gen. Journal Template Type";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created GST Setup
        InitializeShareStep(false);
        CreateGSTSetup(GSTCustomerType::Registered, GSTGroupType::Goods, false, false);
        Storage.Set('GSTCustomerType', format(GSTCustomerType::Registered));

        //[WHEN] Create and Post Sales Journal
        CreateGenJnlLineFromCustomerToGLForInvoice(GenJournalLine, TemplateType::Sales);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN] Verify GST ledger entries
        DocumentNo := LibraryGST.VerifyGLEntry(GenJournalLine."Journal Batch Name");
        LibraryGST.GSTLedgerEntryCount(DocumentNo, 1);
    end;

    //[Scenario 358595] Inter-State Sales of Services to Registered or Unregistered Customer through Sale Journal
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromSalesJournalForServiceUnregisteredInterState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        LibraryERM: Codeunit "Library - ERM";
        GSTGroupType: Enum "GST Group Type";
        GSTCustomerType: Enum "GST Customer Type";
        TemplateType: enum "Gen. Journal Template Type";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created GST Setup
        InitializeShareStep(false);
        CreateGSTSetup(GSTCustomerType::UnRegistered, GSTGroupType::Service, false, false);
        Storage.Set('GSTCustomerType', format(GSTCustomerType::Registered));

        //[WHEN] Create and Post Sales Journal
        CreateGenJnlLineFromCustomerToGLForInvoice(GenJournalLine, TemplateType::Sales);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN] Verify GST ledger entries
        DocumentNo := LibraryGST.VerifyGLEntry(GenJournalLine."Journal Batch Name");
        LibraryGST.GSTLedgerEntryCount(DocumentNo, 1);
    end;

    //[Scenario 358595] Inter-State Sales of Services to Registered or Unregistered Customer through Sale Journal
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromGeneralJournalForServiceUnregisteredInterState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        LibraryERM: Codeunit "Library - ERM";
        GSTGroupType: Enum "GST Group Type";
        GSTCustomerType: Enum "GST Customer Type";
        TemplateType: enum "Gen. Journal Template Type";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created GST Setup
        InitializeShareStep(false);
        CreateGSTSetup(GSTCustomerType::UnRegistered, GSTGroupType::Service, false, false);
        Storage.Set('GSTCustomerType', format(GSTCustomerType::Registered));

        //[WHEN] Create and Post Sales Journal
        CreateGenJnlLineFromCustomerToGLForInvoice(GenJournalLine, TemplateType::Sales);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN] Verify GST ledger entries
        DocumentNo := LibraryGST.VerifyGLEntry(GenJournalLine."Journal Batch Name");
        LibraryGST.GSTLedgerEntryCount(DocumentNo, 1);
    end;

    //[Scenario 358595] Inter-State Sales of Services to Registered or Unregistered Customer through Sale Journal
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromGeneralJournalForServiceRegisteredIntraState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        LibraryERM: Codeunit "Library - ERM";
        GSTGroupType: Enum "GST Group Type";
        GSTCustomerType: Enum "GST Customer Type";
        TemplateType: enum "Gen. Journal Template Type";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created GST Setup
        InitializeShareStep(false);
        CreateGSTSetup(GSTCustomerType::Registered, GSTGroupType::Service, true, false);
        Storage.Set('GSTCustomerType', format(GSTCustomerType::Registered));

        //[WHEN] Create and Post Sales Journal
        CreateGenJnlLineFromCustomerToGLForInvoice(GenJournalLine, TemplateType::Sales);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN] Verify GST ledger entries
        DocumentNo := LibraryGST.VerifyGLEntry(GenJournalLine."Journal Batch Name");
        LibraryGST.GSTLedgerEntryCount(DocumentNo, 2);
    end;
    //[Scenario 355739] Check if system is calculating GST on Invoice created from Sales journals for Registered Customer.
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromSalesJournalForRegisteredIntraState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        LibraryERM: Codeunit "Library - ERM";
        GSTGroupType: Enum "GST Group Type";
        GSTCustomerType: Enum "GST Customer Type";
        TemplateType: enum "Gen. Journal Template Type";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created GST Setup
        InitializeShareStep(false);
        CreateGSTSetup(GSTCustomerType::Registered, GSTGroupType::Service, true, false);

        //[WHEN] Create and Post Sales Journal
        CreateGenJnlLineFromCustomerToGLForInvoice(GenJournalLine, TemplateType::Sales);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN] Verify GST ledger entries
        DocumentNo := LibraryGST.VerifyGLEntry(GenJournalLine."Journal Batch Name");
        LibraryGST.GSTLedgerEntryCount(DocumentNo, 2);
    end;

    //[Scenario 355740] Check if system is calculating GST on Invoice created from Sales journals for Unregistered Customer.
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromSalesJournalForUnregisteredIntraState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        LibraryERM: Codeunit "Library - ERM";
        GSTGroupType: Enum "GST Group Type";
        GSTCustomerType: Enum "GST Customer Type";
        TemplateType: enum "Gen. Journal Template Type";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created GST Setup
        InitializeShareStep(false);
        CreateGSTSetup(GSTCustomerType::Unregistered, GSTGroupType::Service, true, false);

        //[WHEN] Create and Post Sales Journal
        CreateGenJnlLineFromCustomerToGLForInvoice(GenJournalLine, TemplateType::Sales);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN] Verify GST ledger entries
        DocumentNo := LibraryGST.VerifyGLEntry(GenJournalLine."Journal Batch Name");
        LibraryGST.GSTLedgerEntryCount(DocumentNo, 2);
    end;


    //[Scenario 355745] Check if system is calculating GST on Invoice created from General journals for Registered Customer
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromGeneralJournalForRegisteredIntraState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        LibraryERM: Codeunit "Library - ERM";
        GSTGroupType: Enum "GST Group Type";
        GSTCustomerType: Enum "GST Customer Type";
        TemplateType: enum "Gen. Journal Template Type";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created GST Setup
        InitializeShareStep(false);
        CreateGSTSetup(GSTCustomerType::Registered, GSTGroupType::Service, true, false);

        //[WHEN] Create and Post Sales Journal
        CreateGenJnlLineFromCustomerToGLForInvoice(GenJournalLine, TemplateType::General);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN] Verify GST ledger entries
        DocumentNo := LibraryGST.VerifyGLEntry(GenJournalLine."Journal Batch Name");
        LibraryGST.GSTLedgerEntryCount(DocumentNo, 2);
    end;

    //[Scenario 355746] Check if system is calculating GST on Invoice created from General journals for Unregistered Customer
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromGeneralJournalForUnregisteredIntraState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        LibraryERM: Codeunit "Library - ERM";
        GSTGroupType: Enum "GST Group Type";
        GSTCustomerType: Enum "GST Customer Type";
        TemplateType: enum "Gen. Journal Template Type";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created GST Setup
        InitializeShareStep(false);
        CreateGSTSetup(GSTCustomerType::Unregistered, GSTGroupType::Service, true, false);

        //[WHEN] Create and Post Sales Journal
        CreateGenJnlLineFromCustomerToGLForInvoice(GenJournalLine, TemplateType::General);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN] Verify GST ledger entries
        DocumentNo := LibraryGST.VerifyGLEntry(GenJournalLine."Journal Batch Name");
        LibraryGST.GSTLedgerEntryCount(DocumentNo, 2);
    end;

    //[Scenario 355747] Check if system is calculating GST on Invoice created from General journals for Export Customer
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromGeneralJournalForExportIntraState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        LibraryERM: Codeunit "Library - ERM";
        GSTGroupType: Enum "GST Group Type";
        GSTCustomerType: Enum "GST Customer Type";
        TemplateType: enum "Gen. Journal Template Type";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created GST Setup
        InitializeShareStep(false);
        CreateGSTSetup(GSTCustomerType::Export, GSTGroupType::Service, false, false);

        //[WHEN] Create and Post Sales Journal
        CreateGenJnlLineFromCustomerToGLForInvoice(GenJournalLine, TemplateType::General);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN] Verify GST ledger entries
        DocumentNo := LibraryGST.VerifyGLEntry(GenJournalLine."Journal Batch Name");
        LibraryGST.GSTLedgerEntryCount(DocumentNo, 1);
    end;

    //[Scenario 355748] Check if system is calculating GST on Invoice created from General journals for SEZ Unit Customer
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromGeneralJournalForSezUnitIntraState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        LibraryERM: Codeunit "Library - ERM";
        GSTGroupType: Enum "GST Group Type";
        GSTCustomerType: Enum "GST Customer Type";
        TemplateType: enum "Gen. Journal Template Type";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created GST Setup
        InitializeShareStep(false);
        CreateGSTSetup(GSTCustomerType::"SEZ Unit", GSTGroupType::Service, false, false);

        //[WHEN] Create and Post Sales Journal
        CreateGenJnlLineFromCustomerToGLForInvoice(GenJournalLine, TemplateType::General);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN] Verify GST ledger entries
        DocumentNo := LibraryGST.VerifyGLEntry(GenJournalLine."Journal Batch Name");
        LibraryGST.GSTLedgerEntryCount(DocumentNo, 1);
    end;

    //[Scenario 355750] Check if system is calculating GST on Invoice created from General journals for SEZ Development Customer
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromGeneralJournalForSEZDevelopmentIntraState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        LibraryERM: Codeunit "Library - ERM";
        GSTGroupType: Enum "GST Group Type";
        GSTCustomerType: Enum "GST Customer Type";
        TemplateType: enum "Gen. Journal Template Type";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created GST Setup
        InitializeShareStep(false);
        CreateGSTSetup(GSTCustomerType::"SEZ Development", GSTGroupType::Service, false, false);

        //[WHEN] Create and Post General Journal
        CreateGenJnlLineFromCustomerToGLForInvoice(GenJournalLine, TemplateType::General);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN] Verify GST ledger entries
        DocumentNo := LibraryGST.VerifyGLEntry(GenJournalLine."Journal Batch Name");
        LibraryGST.GSTLedgerEntryCount(DocumentNo, 1);
    end;

    //[Scenario 358604] GST calculation  in Foreign currency transaction through Sale journal
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromSalesJournalForExportWithFCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        LibraryERM: Codeunit "Library - ERM";
        GSTGroupType: Enum "GST Group Type";
        GSTCustomerType: Enum "GST Customer Type";
        TemplateType: enum "Gen. Journal Template Type";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created GST Setup
        InitializeShareStep(false);
        CreateGSTSetup(GSTCustomerType::Export, GSTGroupType::Service, false, false);

        //[WHEN] Create and Post Sales Journal
        CreateGenJnlLineFromCustomerToGLForInvoice(GenJournalLine, TemplateType::Sales);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN] Verify GST ledger entries
        DocumentNo := LibraryGST.VerifyGLEntry(GenJournalLine."Journal Batch Name");
        LibraryGST.GSTLedgerEntryCount(DocumentNo, 1);
    end;

    local procedure CreateGSTSetup(GSTCustomerType: Enum "GST Customer Type"; GSTGroupType: Enum "GST Group Type"; IntraState: Boolean; ReverseCharge: Boolean)
    var
        GSTGroup: Record "GST Group";
        HSNSAC: Record "HSN/SAC";
        GSTComponent: Record "Tax Component";
        CompanyInformation: Record "Company information";
        LocationStateCode: Code[10];
        CustomerNo: Code[20];
        LocationCode: Code[10];
        CustomerStateCode: Code[10];
        LocPan: Code[20];
        LocationGSTRegNo: Code[15];
        GSTGroupCode: Code[20];
        HSNSACCode: Code[10];
        HsnSacType: Enum "GST Goods And Services Type";
        GSTcomponentcode: Text[30];
    begin
        CompanyInformation.Get();
        if CompanyInformation."P.A.N. No." = '' then begin
            CompanyInformation."P.A.N. No." := LibraryGST.CreatePANNos();
            CompanyInformation.Modify();
        end else
            LocPan := CompanyInformation."P.A.N. No.";

        LocPan := CompanyInformation."P.A.N. No.";
        LocationStateCode := LibraryGST.CreateInitialSetup();
        Storage.Set('LocationStateCode', LocationStateCode);

        LocationGSTRegNo := LibraryGST.CreateGSTRegistrationNos(LocationStateCode, LocPan);

        if CompanyInformation."GST Registration No." = '' then begin
            CompanyInformation."GST Registration No." := LocationGSTRegNo;
            CompanyInformation.MODIFY(TRUE);
        end;

        LocationCode := LibraryGST.CreateLocationSetup(LocationStateCode, LocationGSTRegNo, FALSE);
        Storage.Set('LocationCode', LocationCode);

        GSTGroupCode := LibraryGST.CreateGSTGroup(GSTGroup, GSTGroupType, GSTGroup."GST Place Of Supply"::"Bill-to Address", ReverseCharge);
        Storage.Set('GSTGroupCode', GSTGroupCode);

        HSNSACCode := LibraryGST.CreateHSNSACCode(HSNSAC, GSTGroupCode, HsnSacType::HSN);
        Storage.Set('HSNSACCode', HSNSACCode);

        if IntraState then begin
            CustomerNo := LibraryGST.CreateCustomerSetup();
            UpdateCustomerSetupWithGST(CustomerNo, GSTCustomerType, false, LocationStateCode, LocPan);
            InitializeTaxRateParameters(IntraState, LocationStateCode, LocationStateCode);
        end else begin
            CustomerStateCode := LibraryGST.CreateGSTStateCode();
            CustomerNo := LibraryGST.CreateCustomerSetup();
            UpdateCustomerSetupWithGST(CustomerNo, GSTCustomerType, false, CustomerStateCode, LocPan);
            Storage.Set('CustomerStateCode', CustomerStateCode);
            if GSTCustomerType in [GSTCustomerType::Export, GSTCustomerType::"SEZ Unit", GSTCustomerType::"SEZ Development"] then
                InitializeTaxRateParameters(IntraState, LocationStateCode, '')
            else
                InitializeTaxRateParameters(IntraState, CustomerStateCode, LocationStateCode);
        end;
        Storage.Set('CustomerNo', CustomerNo);
        CreateTaxRate();
        CreateGSTComponentAndPostingSetup(IntraState, LocationStateCode, GSTComponent, GSTcomponentcode);
    end;

    local procedure CreateGSTComponentAndPostingSetup(IntraState: Boolean; LocationStateCode: Code[10]; GSTComponent: Record "Tax Component"; GSTcomponentcode: Text[30]);
    begin
        IF not IntraState THEN begin
            GSTcomponentcode := 'IGST';
            LibraryGST.CreateGSTComponent(GSTComponent, GSTcomponentcode);
            LibraryGST.CreateGSTPostingSetup(GSTComponent, LocationStateCode);
        end else begin
            GSTcomponentcode := 'CGST';
            LibraryGST.CreateGSTComponent(GSTComponent, GSTcomponentcode);
            LibraryGST.CreateGSTPostingSetup(GSTComponent, LocationStateCode);

            GSTcomponentcode := 'UTGST';
            LibraryGST.CreateGSTComponent(GSTComponent, GSTcomponentcode);
            LibraryGST.CreateGSTPostingSetup(GSTComponent, LocationStateCode);

            GSTcomponentcode := 'SGST';
            LibraryGST.CreateGSTComponent(GSTComponent, GSTcomponentcode);
            LibraryGST.CreateGSTPostingSetup(GSTComponent, LocationStateCode);

        end;
    end;

    local procedure InitializeTaxRateParameters(IntraState: Boolean; FromState: Code[10]; ToState: Code[10])
     GSTTaxPercent: decimal;

    begin
        Storage.Set('FromStateCode', FromState);
        Storage.Set('ToStateCode', ToState);
        GSTTaxPercent := LibraryRandom.RandDecInRange(10, 18, 0);
        if IntraState then begin
            componentPerArray[1] := (GSTTaxPercent / 2);
            componentPerArray[2] := (GSTTaxPercent / 2);
            componentPerArray[3] := 0;
        end else
            componentPerArray[4] := GSTTaxPercent;
    end;

    procedure CreateTaxRate()
    var
        TaxtypeSetup: Record "Tax Type Setup";
        PageTaxtype: TestPage "Tax Types";
    begin
        TaxtypeSetup.GET();
        PageTaxtype.OpenEdit();
        PageTaxtype.Filter.SetFilter(Code, TaxtypeSetup.Code);
        PageTaxtype.TaxRates.Invoke();
    end;

    [PageHandler]
    procedure TaxRatePageHandler(var TaxRate: TestPage "Tax Rates")
    begin
        TaxRate.AttributeValue1.SetValue(CopyStr(Storage.Get('HSNSACCode'), 1, 10));
        TaxRate.AttributeValue2.SetValue(CopyStr(Storage.Get('GSTGroupCode'), 1, 20));
        TaxRate.AttributeValue3.SetValue(Storage.Get('FromStateCode'));
        TaxRate.AttributeValue4.SetValue(Storage.Get('ToStateCode'));
        TaxRate.AttributeValue5.SetValue(WorkDate());
        TaxRate.AttributeValue6.SetValue(CALCDATE('<10Y>', WorkDate()));
        TaxRate.AttributeValue7.SetValue(componentPerArray[1]); // SGST
        TaxRate.AttributeValue8.SetValue(componentPerArray[2]); // CGST
        TaxRate.AttributeValue9.SetValue(componentPerArray[4]); // IGST
        TaxRate.AttributeValue10.SetValue(componentPerArray[3]); // UTGST
        TaxRate.AttributeValue11.SetValue(componentPerArray[5]); // Cess
        TaxRate.AttributeValue12.SetValue(componentPerArray[6]); // KFC 
        TaxRate.AttributeValue13.SetValue(false);
        TaxRate.AttributeValue14.SetValue(false);
        TaxRate.OK().Invoke();
    end;

    procedure CreateGenJournalTemplateBatch(var GenJournalTemplate: Record "Gen. Journal Template";
                                                    var GenJournalBatch: Record "Gen. Journal Batch";
                                                    TemplateType: Enum "Gen. Journal Template Type")
    var
        LibraryERM: Codeunit "Library - ERM";
        LocationCode: Code[10];
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, TemplateType);
        GenJournalTemplate.Modify(true);

        evaluate(LocationCode, Storage.Get('LocationCode'));
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("Location Code", LocationCode);
        GenJournalBatch.Modify(true);
    end;

    procedure CreateGenJnlLineFromCustomerToGLForInvoice(var GenJournalLine: Record "Gen. Journal Line";
        TemplateType: Enum "Gen. Journal Template Type")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        LibraryJournals: Codeunit "Library - Journals";
        CustomerNo: code[20];
        LocationCode: Code[10];
    begin
        CreateGenJournalTemplateBatch(GenJournalTemplate, GenJournalBatch, TemplateType);
        CustomerNo := CopyStr(Storage.Get('CustomerNo'), 1, 20);
        evaluate(LocationCode, Storage.Get('LocationCode'));
        LibraryJournals.CreateGenJournalLine(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name,
                                            GenJournalLine."Document Type"::Invoice,
                                            GenJournalLine."Account Type"::Customer, CustomerNo,
                                            GenJournalLine."Bal. Account Type"::"G/L Account",
                                            LibraryGST.CreateGLAccWithGSTDetails(VATPostingSetup, CopyStr(Storage.Get('GSTGroupCode'), 1, 20), CopyStr(Storage.Get('HSNSACCode'), 1, 10), true, StorageBoolean.get('Exempted')),
                                            LibraryRandom.RandIntInRange(1, 100000));
        GenJournalLine.Validate("Location Code", LocationCode);
        GenJournalLine.Validate("Bal. Gen. Posting Type", GenJournalLine."Bal. Gen. Posting Type"::Sale);
        CalculateTCS(GenJournalLine);
        GenJournalLine.Modify(true);
    end;

    procedure CreateGenJnlLineFromCustomerToGLForInvoiceWithFCY(var GenJournalLine: Record "Gen. Journal Line";
            TemplateType: Enum "Gen. Journal Template Type")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        LibraryJournals: Codeunit "Library - Journals";
        CustomerNo: code[20];
        LocationCode: Code[10];
        GSTCustomerType: Enum "GST Customer Type";
    begin
        CreateGenJournalTemplateBatch(GenJournalTemplate, GenJournalBatch, TemplateType);
        CustomerNo := CopyStr(Storage.Get('CustomerNo'), 1, 20);
        evaluate(LocationCode, Storage.Get('LocationCode'));
        LibraryJournals.CreateGenJournalLine(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name,
                                            GenJournalLine."Document Type"::Invoice,
                                            GenJournalLine."Account Type"::Customer, CustomerNo,
                                            GenJournalLine."Bal. Account Type"::"G/L Account",
                                            LibraryGST.CreateGLAccWithGSTDetails(VATPostingSetup, CopyStr(Storage.Get('GSTGroupCode'), 1, 20), CopyStr(Storage.Get('HSNSACCode'), 1, 10), true, StorageBoolean.get('Exempted')),
                                            LibraryRandom.RandIntInRange(1, 10000));
        GenJournalLine.Validate("Location Code", LocationCode);
        GenJournalLine.Validate("Bal. Gen. Posting Type", GenJournalLine."Bal. Gen. Posting Type"::Sale);
        GenJournalLine.Validate("Currency Code", LibraryGST.CreateCurrencyCode());
        Evaluate(GSTCustomerType, Storage.Get('GSTCustomerType'));
        if GSTCustomerType = GSTCustomerType::"SEZ Development" then
            GenJournalLine.Validate("Sales Invoice Type", GenJournalLine."Sales Invoice Type"::Export);
        CalculateTCS(GenJournalLine);
        GenJournalLine.Modify(true);
    end;

    procedure UpdateCustomerSetupWithGST(CustomerNo: Code[20]; GSTCustomerType: Enum "GST Customer Type"; AssociateEnterprise: boolean; StateCode1: Code[10]; Pan: Code[20]);
    var
        Customer: Record Customer;
        State: Record State;
    begin
        Customer.Get(CustomerNo);
        if (GSTCustomerType <> GSTCustomerType::Export) then begin
            State.Get(StateCode1);
            Customer.Validate("State Code", StateCode1);
            Customer.Validate("P.A.N. No.", Pan);
            if not ((GSTCustomerType = GSTCustomerType::" ") OR (GSTCustomerType = GSTCustomerType::Unregistered)) then
                Customer.Validate("GST Registration No.", LibraryGST.GenerateGSTRegistrationNo(State."State Code (GST Reg. No.)", Pan));
        end
        else
            Customer.Validate("Currency Code", LibraryGST.CreateCurrencyCode());
        Customer.Validate("GST Customer Type", GSTCustomerType);
        Customer.Modify(true);
    end;

    local procedure CreateLocationWithVoucherSetup(Type: Enum "Gen. Journal Template Type"): Code[20]
    var
        BankAccount: Record "Bank Account";
        GLAccount: Record "G/L Account";
        Location: Record Location;
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryERM: Codeunit "Library - ERM";
        LocationCode: Code[10];
        AccountType: Enum "Gen. Journal Account Type";
    Begin
        LocationCode := LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        evaluate(LocationCode, Storage.Get('LocationCode'));
        case Type of
            Type::"Bank Payment Voucher", Type::"Bank Receipt Voucher":
                begin
                    LibraryERM.CreateBankAccount(BankAccount);
                    Storage.set('AccountNo', BankAccount."No.");
                    StorageEnum.Set('AccountType', Format(AccountType::"Bank Account"));
                    CreateVoucherAccountSetup(Type, LocationCode);
                end;
            type::"Contra Voucher", type::"Cash Receipt Voucher":
                begin
                    LibraryERM.CreateGLAccount(GLAccount);
                    Storage.set('AccountNo', GLAccount."No.");
                    StorageEnum.Set('AccountType', Format(AccountType::"G/L Account"));
                    CreateVoucherAccountSetup(Type, LocationCode);
                end;
        end;
    end;

    procedure CreateGenJnlLineForVoucher(var GenJournalLine: Record "Gen. Journal Line";
            TemplateType: Enum "Gen. Journal Template Type")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        LibraryJournals: Codeunit "Library - Journals";
        CustomerNo: Code[20];
        LocationCode: Code[10];
        AccountType: Enum "Gen. Journal Account Type";
    begin
        CreateGenJournalTemplateBatch(GenJournalTemplate, GenJournalBatch, TemplateType);
        CustomerNo := CopyStr(Storage.Get('CustomerNo'), 1, 20);
        Evaluate(LocationCode, Storage.Get('LocationCode'));
        Evaluate(AccountType, StorageEnum.Get('AccountType'));
        LibraryJournals.CreateGenJournalLine(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name,
                                            GenJournalLine."Document Type"::Payment,
                                            GenJournalLine."Account Type"::Customer, CustomerNo,
                                            AccountType,
                                            CopyStr(Storage.Get('AccountNo'), 1, 20),
                                            -LibraryRandom.RandIntInRange(1, 10000));
        GenJournalLine.Validate("Location Code", LocationCode);
        GenJournalLine.Validate("GST Group Code", CopyStr(Storage.Get('GSTGroupCode'), 1, 20));
        GenJournalLine.validate("HSN/SAC Code", CopyStr(Storage.Get('HSNSACCode'), 1, 10));
        GenJournalLine.Validate("GST on Advance Payment", true);
        CalculateTCS(GenJournalLine);
        GenJournalLine.Modify(true);
    End;

    procedure CreateGenJnlLineForVoucherWithoutAdvancePayment(var GenJournalLine: Record "Gen. Journal Line";
            TemplateType: Enum "Gen. Journal Template Type")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        LibraryJournals: Codeunit "Library - Journals";
        CustomerNo: Code[20];
        LocationCode: Code[10];
        AccountType: Enum "Gen. Journal Account Type";
    begin
        CreateGenJournalTemplateBatch(GenJournalTemplate, GenJournalBatch, TemplateType);
        CustomerNo := CopyStr(Storage.Get('CustomerNo'), 1, 20);
        Evaluate(LocationCode, Storage.Get('LocationCode'));
        Evaluate(AccountType, StorageEnum.Get('AccountType'));
        LibraryJournals.CreateGenJournalLine(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name,
                                            GenJournalLine."Document Type"::Payment,
                                            GenJournalLine."Account Type"::Customer, CustomerNo,
                                            AccountType,
                                            CopyStr(Storage.Get('AccountNo'), 1, 20),
                                            -LibraryRandom.RandIntInRange(1, 10000));
        GenJournalLine.Validate("Location Code", LocationCode);
        GenJournalLine.Validate("GST Group Code", CopyStr(Storage.Get('GSTGroupCode'), 1, 20));
        GenJournalLine.validate("HSN/SAC Code", CopyStr(Storage.Get('HSNSACCode'), 1, 10));
        CalculateTCS(GenJournalLine);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateVoucherAccountSetup(SubType: Enum "Gen. Journal Template Type"; LocationCode: Code[10])
    var
        VoucherSetupPage: TestPage "Journal Voucher Posting Setup";
        LocationCard: TestPage "Location Card";
    begin
        LocationCard.OpenEdit();
        LocationCard.GoToKey(LocationCode);
        VoucherSetupPage.Trap();
        LocationCard."Voucher Setup".Invoke();
        VoucherSetupPage.Filter.SetFilter(Type, Format(SubType));
        VoucherSetupPage.Filter.SetFilter("Location Code", LocationCode);
        case SubType of
            SubType::"Bank Payment Voucher", SubType::"Cash Payment Voucher", SubType::"Contra Voucher":
                begin
                    VoucherSetupPage."Transaction Direction".SetValue('Credit');
                    VoucherSetupPage."Credit Account".Invoke();
                end;
            SubType::"Cash Receipt Voucher", SubType::"Bank Receipt Voucher":
                begin
                    VoucherSetupPage."Transaction Direction".SetValue('Debit');
                    VoucherSetupPage."Debit Account".Invoke();
                end;
        end;
    end;

    [PageHandler]
    procedure VoucherAccountCredit(var VoucherCrAccount: TestPage "Voucher Posting Credit Account");
    var
        AccountNo: Code[20];
        AccountType: Enum "Gen. Journal Account Type";
    begin
        Evaluate(AccountType, StorageEnum.Get('AccountType'));
        Evaluate(AccountNo, Storage.Get('AccountNo'));
        VoucherCrAccount.Type.SetValue(AccountType);
        VoucherCrAccount."Account No.".SetValue(AccountNo);
        VoucherCrAccount.OK().Invoke();
    end;

    [PageHandler]
    procedure VoucherAccountDebit(var VoucherDrAccount: TestPage "Voucher Posting Debit Accounts");
    var
        AccountNo: Code[20];
        AccountType: Enum "Gen. Journal Account Type";
    begin
        Evaluate(AccountType, StorageEnum.Get('AccountType'));
        Evaluate(AccountNo, Storage.Get('AccountNo'));
        VoucherDrAccount.Type.SetValue(AccountType);
        VoucherDrAccount."Account No.".SetValue(AccountNo);
        VoucherDrAccount.OK().Invoke();
    end;

    local procedure InitializeShareStep(Exempted: Boolean)
    begin
        StorageBoolean.Set('Exempted', Exempted);
    end;

    procedure CalculateTCS(GenJnlLine: Record "Gen. Journal Line")
    var
        CalculateTax: Codeunit "Calculate Tax";
    begin
        CalculateTax.CallTaxEngineOnGenJnlLine(GenJnlLine, GenJnlLine)
    end;
}