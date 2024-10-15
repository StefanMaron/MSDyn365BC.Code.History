codeunit 18273 "Jnl Bank Charges Tests"
{
    Subtype = Test;

    [Test]
    [HandlerFunctions('TaxRatesPage,VoucherAccountCredit')]
    procedure PostFromBankPaymentVoucherWithIntrastateBankChargesAvailment()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        VoucherType: Enum "Gen. Journal Template Type";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[Scenario 355954][Check if the system is calculating GST in case of Intra-State Bank Payment with Bank Charges with GST where Input Tax Credit is available]
        Initialize();
        //[GIVEN] Created GST Setup and Bank Charges Setup
        CreateGSTSetup(GSTVendorType::Registered, true, true);
        CreateBankChargeSetup(BankAccount, VoucherType::"Bank Payment Voucher", false);

        //[WHEN] Create and Post Bank Payment Voucher with Bank Charges
        CreateGenJournalLineForVendorToBank(GenJournalLine, BankAccount."No.");
        DocumentNo := CreateJournalBankCharge(GenJournalLine, LibraryRandom.RandDecInRange(1, 500, 0));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(GenJournalLine."Document Type"::Payment, DocumentNo, 5);
    end;

    [Test]
    [HandlerFunctions('TaxRatesPage,VoucherAccountCredit')]
    procedure PostFromBankPaymentVoucherWithInterstateBankChargesAvailment()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        VoucherType: Enum "Gen. Journal Template Type";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[Scenario 355955][Check if the system is calculating GST in case of Inter-State Bank Payment with Bank Charges with GST where Input Tax Credit is available]
        Initialize();
        //[GIVEN] Created GST Setup and Bank Charges Setup 
        CreateGSTSetup(GSTVendorType::Registered, false, true);
        CreateBankChargeSetup(BankAccount, VoucherType::"Bank Payment Voucher", false);

        //[WHEN] Create and Post Bank Payment Voucher with Bank Charges
        CreateGenJournalLineForVendorToBank(GenJournalLine, BankAccount."No.");
        DocumentNo := CreateJournalBankCharge(GenJournalLine, LibraryRandom.RandDecInRange(1, 500, 0));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(GenJournalLine."Document Type"::Payment, DocumentNo, 4);
    end;

    [Test]
    [HandlerFunctions('TaxRatesPage,VoucherAccountCredit')]
    procedure PostFromBankPaymentVoucherWithInterstateBankChargesNonAvailment()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        VoucherType: Enum "Gen. Journal Template Type";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[Scenario 355956][Check if the system is calculating GST in case of Inter-State Bank Payment with Bank Charges with GST where Input Tax Credit is not available]
        Initialize();
        //[GIVEN] Created GST Setup and Bank Charges Setup 
        CreateGSTSetup(GSTVendorType::Registered, false, false);
        CreateBankChargeSetup(BankAccount, VoucherType::"Bank Payment Voucher", false);

        //[WHEN] Create and Post Bank Payment Voucher with Bank Charges
        CreateGenJournalLineForVendorToBank(GenJournalLine, BankAccount."No.");
        DocumentNo := CreateJournalBankCharge(GenJournalLine, LibraryRandom.RandDecInRange(1, 500, 0));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(GenJournalLine."Document Type"::Payment, DocumentNo, 3);
    end;

    [Test]
    [HandlerFunctions('TaxRatesPage,VoucherAccountCredit')]
    procedure PostFromBankPaymentVoucherWithIntrastateBankChargesNonAvailment()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        VoucherType: Enum "Gen. Journal Template Type";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[Scenario 355956][Check if the system is calculating GST in case of Inter-State Bank Payment with Bank Charges with GST where Input Tax Credit is not available]
        Initialize();
        //[GIVEN] Created GST Setup and Bank Charges Setup 
        CreateGSTSetup(GSTVendorType::Registered, true, false);
        CreateBankChargeSetup(BankAccount, VoucherType::"Bank Payment Voucher", false);

        //[WHEN] Create and Post Bank Payment Voucher with Bank Charges
        CreateGenJournalLineForVendorToBank(GenJournalLine, BankAccount."No.");
        DocumentNo := CreateJournalBankCharge(GenJournalLine, LibraryRandom.RandDecInRange(1, 500, 0));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(GenJournalLine."Document Type"::Payment, DocumentNo, 4);
    end;

    [Test]
    [HandlerFunctions('TaxRatesPage,VoucherAccountDebit')]
    procedure PostFromBankReceiptVoucherWithInterstateBankChargesAvailment()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        VoucherType: Enum "Gen. Journal Template Type";
        GSTCustomerType: Enum "GST Customer Type";
    begin
        //[Scenario 355976][Check if the system is calculating GST in case of Inter-state bank charges with GST where Input Tax Credit is available on Bank receipts]
        Initialize();
        //[GIVEN] Created GST Setup and Bank Charges Setup 
        CreateGSTSetup(GSTCustomerType::Registered, false);
        CreateBankChargeSetup(BankAccount, VoucherType::"Bank Receipt Voucher", false);

        //[WHEN] Create and Post Bank Receipt Voucher with Bank Charges
        CreateGenJournalLineForCustomerToBank(GenJournalLine, BankAccount."No.");
        DocumentNo := CreateJournalBankCharge(GenJournalLine, LibraryRandom.RandDecInRange(1, 500, 0));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(GenJournalLine."Document Type"::Payment, DocumentNo, 4);
    end;

    [Test]
    [HandlerFunctions('TaxRatesPage,VoucherAccountDebit')]
    procedure PostFromBankReceiptVoucherWithIntrastateBankChargesAvailment()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        VoucherType: Enum "Gen. Journal Template Type";
        GSTCustomerType: Enum "GST Customer Type";
    begin
        //[Scenario 355975][Check if the system is calculating GST in case of Intra-state bank charges with GST where Input Tax Credit is available on Bank receipts]
        Initialize();
        //[GIVEN] Created GST Setup and Bank Charges Setup 
        CreateGSTSetup(GSTCustomerType::Registered, true);
        CreateBankChargeSetup(BankAccount, VoucherType::"Bank Receipt Voucher", false);

        //[WHEN] Create and Post Bank Receipt Voucher with Bank Charges
        CreateGenJournalLineForCustomerToBank(GenJournalLine, BankAccount."No.");
        DocumentNo := CreateJournalBankCharge(GenJournalLine, LibraryRandom.RandDecInRange(1, 500, 0));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(GenJournalLine."Document Type"::Payment, DocumentNo, 5);
    end;

    [Test]
    [HandlerFunctions('TaxRatesPage,VoucherAccountDebit')]
    procedure PostFromBankReceiptVoucherWithIntrastateBankChargesNonAvailment()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        VoucherType: Enum "Gen. Journal Template Type";
        GSTCustomerType: Enum "GST Customer Type";
    begin
        //[Scenario 355980][Check if the system is calculating GST in case of Intra-state bank charges with GST where Input Tax Credit is not available on Bank receipts]
        Initialize();
        //[GIVEN] Created GST Setup and Bank Charges Setup 
        CreateGSTSetup(GSTCustomerType::Registered, true);
        CreateBankChargeSetup(BankAccount, VoucherType::"Bank Receipt Voucher", false);

        //[WHEN] Create and Post Bank Receipt Voucher with Bank Charges
        CreateGenJournalLineForCustomerToBank(GenJournalLine, BankAccount."No.");
        DocumentNo := CreateJournalBankCharge(GenJournalLine, LibraryRandom.RandDecInRange(1, 500, 0));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(GenJournalLine."Document Type"::Payment, DocumentNo, 3);
    end;

    [Test]
    [HandlerFunctions('TaxRatesPage,VoucherAccountDebit')]
    procedure PostFromBankReceiptVoucherWithInterstateBankChargesNonAvailment()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        VoucherType: Enum "Gen. Journal Template Type";
        GSTCustomerType: Enum "GST Customer Type";
    begin
        //[Scenario 355981][Check if the system is calculating GST in case of Inter-state bank charges with GST where Input Tax Credit is not available on Bank receipts]
        Initialize();
        //[GIVEN] Created GST Setup and Bank Charges Setup 
        CreateGSTSetup(GSTCustomerType::Registered, false);
        CreateBankChargeSetup(BankAccount, VoucherType::"Bank Receipt Voucher", false);

        //[WHEN] Create and Post Bank Receipt Voucher with Bank Charges
        CreateGenJournalLineForCustomerToBank(GenJournalLine, BankAccount."No.");
        DocumentNo := CreateJournalBankCharge(GenJournalLine, LibraryRandom.RandDecInRange(1, 500, 0));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(GenJournalLine."Document Type"::Payment, DocumentNo, 3);
    end;

    [Test]
    [HandlerFunctions('TaxRatesPage,VoucherAccountCredit')]
    procedure PostFromBankPaymentWithIntrastateBankChargesAvailment()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        VoucherType: Enum "Gen. Journal Template Type";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[Scenario 355982][Check if the system is calculating GST in case of Intra-state bank charges with GST where Input Tax Credit is available on Bank payments]
        Initialize();
        //[GIVEN] Created GST Setup and Bank Charges Setup 
        CreateGSTSetup(GSTVendorType::Registered, true, true);
        CreateBankChargeSetup(BankAccount, VoucherType::"Bank Payment Voucher", false);

        //[WHEN] Create and Post Bank Payment Voucher with Bank Charges
        CreateGenJournalLineForVendorToBank(GenJournalLine, BankAccount."No.");
        DocumentNo := CreateJournalBankCharge(GenJournalLine, LibraryRandom.RandDecInRange(1, 500, 0));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(GenJournalLine."Document Type"::Payment, DocumentNo, 5);
    end;

    [Test]
    [HandlerFunctions('TaxRatesPage,VoucherAccountCredit')]
    procedure PostFromBankPaymentsWithInterstateBankChargesAvailment()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        VoucherType: Enum "Gen. Journal Template Type";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[Scenario 355987][Check if the system is calculating GST in case of Inter-state bank charges with GST where Input Tax Credit is available on Bank payments]
        Initialize();
        //[GIVEN] Created GST Setup and Bank Charges Setup 
        CreateGSTSetup(GSTVendorType::Registered, false, true);
        CreateBankChargeSetup(BankAccount, VoucherType::"Bank Payment Voucher", false);

        //[WHEN] Create and Post Bank Payment Voucher with Bank Charges.
        CreateGenJournalLineForVendorToBank(GenJournalLine, BankAccount."No.");
        DocumentNo := CreateJournalBankCharge(GenJournalLine, LibraryRandom.RandDecInRange(1, 500, 0));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(GenJournalLine."Document Type"::Payment, DocumentNo, 4);
    end;

    [Test]
    [HandlerFunctions('TaxRatesPage,VoucherAccountCredit')]
    procedure PostFromBankPaymentsWithInterstateBankChargesNonAvailment()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        VoucherType: Enum "Gen. Journal Template Type";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[Scenario 355988][Check if the system is calculating GST in case of Inter-state bank charges with GST where Input Tax Credit is not available on Bank payments]
        Initialize();
        //[GIVEN] Created GST Setup and Bank Charges Setup 
        CreateGSTSetup(GSTVendorType::Registered, false, false);
        CreateBankChargeSetup(BankAccount, VoucherType::"Bank Payment Voucher", false);

        //[WHEN] Create and Post Bank Payment Voucher with Bank Charges
        CreateGenJournalLineForVendorToBank(GenJournalLine, BankAccount."No.");
        DocumentNo := CreateJournalBankCharge(GenJournalLine, LibraryRandom.RandDecInRange(1, 500, 0));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(GenJournalLine."Document Type"::Payment, DocumentNo, 3);
    end;

    [Test]
    [HandlerFunctions('TaxRatesPage,VoucherAccountCredit')]
    procedure PostFromBankPaymentsWithIntrastateBankChargesNonAvailment()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        VoucherType: Enum "Gen. Journal Template Type";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[Scenario 355989][Check if the system is calculating GST in case of Intra-state bank charges with GST where Input Tax Credit is not available on Bank payments]
        Initialize();
        //[GIVEN] Created GST Setup and Bank Charges Setup 
        CreateGSTSetup(GSTVendorType::Registered, true, false);
        CreateBankChargeSetup(BankAccount, VoucherType::"Bank Payment Voucher", false);

        //[WHEN] Create and Post Bank Payment Voucher with Bank Charges
        CreateGenJournalLineForVendorToBank(GenJournalLine, BankAccount."No.");
        DocumentNo := CreateJournalBankCharge(GenJournalLine, LibraryRandom.RandDecInRange(1, 500, 0));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(GenJournalLine."Document Type"::Payment, DocumentNo, 4);
    end;

    local procedure Initialize()
    var
    begin
        FillCompanyInformation();
        Clear(LibraryStorage);
    end;

    local procedure CreateGSTSetup(GSTVendorType: Enum "GST Vendor Type"; IntraState: Boolean; InputCreditAvailment: Boolean)
    var
        GSTGroup: Record "GST Group";
        HSNSAC: Record "HSN/SAC";
        GSTComponent: Record "Tax Component";
        CompanyInformation: Record "Company information";
        GSTGroupType: Enum "GST Group Type";
        LocationStateCode: Code[10];
        VendorNo: Code[20];
        LocationCode: Code[10];
        VendorStateCode: Code[10];
        LocPan: Code[20];
        HSNSACCode: Code[10];
        GSTGroupCode: Code[20];
        LocationGSTRegNo: Code[15];
        HsnSacType: Enum "GST Goods And Services Type";
        GSTcomponentcode: Text[30];
    begin
        CompanyInformation.Get();

        LocPan := CompanyInformation."P.A.N. No.";
        LocationStateCode := LibraryGST.CreateInitialSetup();
        LibraryStorage.Set('LocationStateCode', LocationStateCode);

        LocationGSTRegNo := LibraryGST.CreateGSTRegistrationNos(LocationStateCode, LocPan);
        if CompanyInformation."GST Registration No." = '' then begin
            CompanyInformation."GST Registration No." := LocationGSTRegNo;
            CompanyInformation.MODIFY(TRUE);
        end;

        LocationCode := LibraryGST.CreateLocationSetup(LocationStateCode, LocationGSTRegNo, false);
        LibraryStorage.Set('LocationCode', LocationCode);

        GSTGroupCode := LibraryGST.CreateGSTGroup(GSTGroup, GSTGroupType::Service, GSTGroup."GST Place Of Supply"::" ", false);
        LibraryStorage.Set('GSTGroupCode', GSTGroupCode);

        HSNSACCode := LibraryGST.CreateHSNSACCode(HSNSAC, GSTGroupCode, HsnSacType::SAC);
        LibraryStorage.Set('HSNSACCode', HSNSACCode);
        LibraryStorage.Set('InputCreditAvailment', Format(InputCreditAvailment));
        if IntraState then begin
            VendorNo := LibraryGST.CreateVendorSetup();
            UpdateVendorSetupWithGST(VendorNo, GSTVendorType, false, LocationStateCode, LocPan);
            InitializeTaxRateParameters(IntraState, LocationStateCode, LocationStateCode);
            CreateGSTComponentAndPostingSetup(IntraState, LocationStateCode, GSTComponent, GSTcomponentcode);
        end else begin
            VendorStateCode := LibraryGST.CreateGSTStateCode();
            VendorNo := LibraryGST.CreateVendorSetup();
            UpdateVendorSetupWithGST(VendorNo, GSTVendorType, false, VendorStateCode, LocPan);
            LibraryStorage.Set('VendorStateCode', VendorStateCode);
            if GSTVendorType in [GSTVendorType::Import, GSTVendorType::SEZ] then
                InitializeTaxRateParameters(IntraState, LocationStateCode, '')
            else begin
                InitializeTaxRateParameters(IntraState, VendorStateCode, LocationStateCode);
                CreateGSTComponentAndPostingSetup(IntraState, VendorStateCode, GSTComponent, GSTcomponentcode);
            end;
        end;
        LibraryStorage.Set('VendorNo', VendorNo);

        CreateTaxRate(false);
    end;

    local procedure CreateGSTSetup(GSTCustomerType: Enum "GST Customer Type"; IntraState: Boolean)
    var
        GSTGroup: Record "GST Group";
        HSNSAC: Record "HSN/SAC";
        GSTComponent: Record "Tax Component";
        CompanyInformation: Record "Company information";
        GSTGroupType: Enum "GST Group Type";
        LocationStateCode: Code[10];
        CustomerNo: Code[20];
        LocationCode: Code[10];
        CustomerStateCode: Code[10];
        LocPan: Code[20];
        HSNSACCode: Code[10];
        GSTGroupCode: Code[20];
        LocationGSTRegNo: Code[15];
        HsnSacType: Enum "GST Goods And Services Type";
        GSTcomponentcode: Text[30];
        isInitialized: Boolean;
    begin
        if isInitialized then
            exit;
        FillCompanyInformation();
        CompanyInformation.Get();

        LocPan := CompanyInformation."P.A.N. No.";
        LocationStateCode := LibraryGST.CreateInitialSetup();
        LibraryStorage.Set('LocationStateCode', LocationStateCode);

        LocationGSTRegNo := LibraryGST.CreateGSTRegistrationNos(LocationStateCode, LocPan);
        if CompanyInformation."GST Registration No." = '' then begin
            CompanyInformation."GST Registration No." := LocationGSTRegNo;
            CompanyInformation.MODIFY(TRUE);
        end;

        LocationCode := LibraryGST.CreateLocationSetup(LocationStateCode, LocationGSTRegNo, false);
        LibraryStorage.Set('LocationCode', LocationCode);

        GSTGroupCode := LibraryGST.CreateGSTGroup(GSTGroup, GSTGroupType::Service, GSTGroup."GST Place Of Supply"::" ", false);
        LibraryStorage.Set('GSTGroupCode', GSTGroupCode);

        HSNSACCode := LibraryGST.CreateHSNSACCode(HSNSAC, GSTGroupCode, HsnSacType::SAC);
        LibraryStorage.Set('HSNSACCode', HSNSACCode);
        LibraryStorage.Set('InputCreditAvailment', format(false));

        if IntraState then begin
            CustomerNo := LibraryGST.CreateCustomerSetup();
            UpdateCustomerSetupWithGST(CustomerNo, GSTCustomerType, LocationStateCode, LocPan);
            InitializeTaxRateParameters(IntraState, LocationStateCode, LocationStateCode);
            CreateGSTComponentAndPostingSetup(IntraState, LocationStateCode, GSTComponent, GSTcomponentcode);
        end else begin
            CustomerStateCode := LibraryGST.CreateGSTStateCode();
            CustomerNo := LibraryGST.CreateCustomerSetup();
            UpdateCustomerSetupWithGST(CustomerNo, GSTCustomerType, CustomerStateCode, LocPan);
            LibraryStorage.Set('CustomerStateCode', CustomerStateCode);
            if GSTCustomerType in [GSTCustomerType::Export, GSTCustomerType::"SEZ Unit", GSTCustomerType::"SEZ Development"] then
                InitializeTaxRateParameters(IntraState, '', LocationStateCode)
            else begin
                InitializeTaxRateParameters(IntraState, CustomerStateCode, LocationStateCode);
                CreateGSTComponentAndPostingSetup(IntraState, CustomerStateCode, GSTComponent, GSTcomponentcode);
            end;
        end;
        LibraryStorage.Set('CustomerNo', CustomerNo);

        CreateTaxRate(false);
        isInitialized := TRUE;
    end;

    local procedure InitializeTaxRateParameters(IntraState: Boolean; FromState: Code[10]; ToState: Code[10])
    var
        GSTTaxPercent: Decimal;
    begin
        LibraryStorage.Set('FromStateCode', FromState);
        LibraryStorage.Set('ToStateCode', ToState);

        GSTTaxPercent := LibraryRandom.RandIntInRange(1, 10);
        if IntraState then begin
            componentPerArray[1] := (GSTTaxPercent);
            componentPerArray[2] := (GSTTaxPercent);
            componentPerArray[3] := 0;
        end else
            componentPerArray[4] := GSTTaxPercent;
    end;

    local procedure CreateGSTComponentAndPostingSetup(IntraState: Boolean; LocationStateCode: Code[10]; GSTComponent: Record "Tax Component"; GSTcomponentcode: Text[30]);
    begin
        IF IntraState THEN begin
            GSTcomponentcode := 'CGST';
            LibraryGST.CreateGSTComponent(GSTComponent, GSTcomponentcode);
            LibraryGST.CreateGSTPostingSetup(GSTComponent, LocationStateCode);

            GSTcomponentcode := 'UTGST';
            LibraryGST.CreateGSTComponent(GSTComponent, GSTcomponentcode);
            LibraryGST.CreateGSTPostingSetup(GSTComponent, LocationStateCode);

            GSTcomponentcode := 'SGST';
            LibraryGST.CreateGSTComponent(GSTComponent, GSTcomponentcode);
            LibraryGST.CreateGSTPostingSetup(GSTComponent, LocationStateCode);
        end else begin
            GSTcomponentcode := 'IGST';
            LibraryGST.CreateGSTComponent(GSTComponent, GSTcomponentcode);
            LibraryGST.CreateGSTPostingSetup(GSTComponent, LocationStateCode);
        end;
    end;

    procedure CreateTaxRate(POS: boolean)
    var
        TaxtypeSetup: Record "Tax Type Setup";
        PageTaxtype: TestPage "Tax Types";
    begin
        if not TaxtypeSetup.GET() then
            exit;
        PageTaxtype.OpenEdit();
        PageTaxtype.Filter.SetFilter(Code, TaxtypeSetup.Code);
        PageTaxtype.TaxRates.Invoke();
    end;

    [PageHandler]
    procedure TaxRatesPage(var TaxRate: TestPage "Tax Rates")
    begin
        TaxRate.AttributeValue1.SetValue(LibraryStorage.Get('HSNSACCode'));
        TaxRate.AttributeValue2.SetValue(LibraryStorage.Get('GSTGroupCode'));
        TaxRate.AttributeValue3.SetValue(LibraryStorage.Get('FromStateCode'));
        TaxRate.AttributeValue4.SetValue(LibraryStorage.Get('ToStateCode'));
        TaxRate.AttributeValue5.SetValue(Today);
        TaxRate.AttributeValue6.SetValue(CALCDATE('<10Y>', Today));
        TaxRate.AttributeValue7.SetValue(componentPerArray[1]);
        TaxRate.AttributeValue8.SetValue(componentPerArray[2]);
        TaxRate.AttributeValue9.SetValue(componentPerArray[4]);
        TaxRate.AttributeValue10.SetValue(componentPerArray[3]);
        TaxRate.AttributeValue11.SetValue(componentPerArray[5]);
        TaxRate.AttributeValue12.SetValue(componentPerArray[6]);
        TaxRate.OK().Invoke();
    end;

    procedure UpdateVendorSetupWithGST(VendorNo: Code[20]; GSTVendorType: Enum "GST Vendor Type"; AssociateEnterprise: boolean; StateCode: Code[10]; Pan: Code[20]);
    var
        Vendor: Record Vendor;
        State: Record State;
    begin
        Vendor.Get(VendorNo);
        if (GSTVendorType <> GSTVendorType::Import) then begin
            State.Get(StateCode);
            Vendor.Validate("State Code", StateCode);
            Vendor.Validate("P.A.N. No.", Pan);
            if not ((GSTVendorType = GSTVendorType::" ") OR (GSTVendorType = GSTVendorType::Unregistered)) then
                Vendor.Validate("GST Registration No.", LibraryGST.GenerateGSTRegistrationNo(State."State Code (GST Reg. No.)", Pan));
        end;
        Vendor.Validate("GST Vendor Type", GSTVendorType);
        if Vendor."GST Vendor Type" = vendor."GST Vendor Type"::Import then
            Vendor.Validate("Associated Enterprises", AssociateEnterprise);
        Vendor.Modify(true);
    end;

    procedure UpdateCustomerSetupWithGST(CustomerNo: Code[20]; GSTCustomerType: Enum "GST Customer Type"; StateCode: Code[10]; Pan: Code[20]);
    var
        Customer: Record Customer;
        State: Record State;
    begin
        CustomerNo := LibrarySales.CreateCustomerNo();
        Customer.Get(CustomerNo);
        if GSTCustomerType <> GSTCustomerType::Export then begin
            State.Get(StateCode);
            Customer.Validate("State Code", StateCode);
            Customer.Validate("P.A.N. No.", Pan);
            if not ((GSTCustomerType = GSTCustomerType::" ") OR (GSTCustomerType = GSTCustomerType::Unregistered)) then
                Customer.Validate("GST Registration No.", LibraryGST.GenerateGSTRegistrationNo(State."State Code (GST Reg. No.)", Pan));
        end;

        Customer.Validate(Address, CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(Customer.Address)));
        Customer.Validate("GST Customer Type", GSTCustomerType);
        Customer.Modify(true);
    end;

    local procedure CreateJournalBankCharge(var GenJournalLine: Record "Gen. Journal Line"; ChargeAmount: Decimal): Code[20]
    var
        JnlBankCharges: Record "Journal Bank Charges";
    begin
        JnlBankCharges.Init();
        JnlBankCharges.Validate("Journal Template Name", GenJournalLine."Journal Template Name");
        JnlBankCharges.Validate("Journal Batch Name", GenJournalLine."Journal Batch Name");
        JnlBankCharges.Validate("Line No.", GenJournalLine."Line No.");
        JnlBankCharges.Validate("Bank Charge", LibraryStorage.Get('BankCharge'));
        JnlBankCharges.Validate("GST Document Type", JnlBankCharges."GST Document Type"::Invoice);
        JnlBankCharges.Validate("External Document No.", GenJournalLine."Document No.");
        JnlBankCharges.Insert(true);
        JnlBankCharges.Validate(Amount, ChargeAmount);
        JnlBankCharges.Modify(true);
        exit(GenJournalLine."Document No.");
    end;

    procedure CreateGenJournalLineForVendorToBank(var GenJournalLine: Record "Gen. Journal Line"; BankAccNo: code[20])
    var
        Vendor: Record Vendor;
        LibraryJournals: Codeunit "Library - Journals";
    begin
        LibraryJournals.CreateGenJournalLine(GenJournalLine,
                                LibraryStorage.Get('TemplateName'), LibraryStorage.Get('BatchName'),
                                GenJournalLine."Document Type"::Payment,
                                GenJournalLine."Account Type"::Vendor, LibraryStorage.Get('VendorNo'),
                                GenJournalLine."Bal. Account Type"::"Bank Account", BankAccNo,
                                LibraryRandom.RandDecInRange(1000, 10000, 0));
        GenJournalLine.Validate("Location Code", LibraryStorage.Get('LocationCode'));
        GenJournalLine.Modify(true);
    end;

    procedure CreateGenJournalLineForCustomerToBank(var GenJournalLine: Record "Gen. Journal Line"; BankAccNo: code[20])
    var
        LibraryJournals: Codeunit "Library - Journals";
    begin
        LibraryJournals.CreateGenJournalLine(GenJournalLine,
                                LibraryStorage.Get('TemplateName'), LibraryStorage.Get('BatchName'),
                                GenJournalLine."Document Type"::Payment,
                                GenJournalLine."Account Type"::Customer, LibraryStorage.Get('CustomerNo'),
                                GenJournalLine."Bal. Account Type"::"Bank Account", BankAccNo,
                                -LibraryRandom.RandDecInRange(1000, 10000, 0));
        GenJournalLine.Validate("Location Code", LibraryStorage.Get('LocationCode'));
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
        VoucherSetupPage."Posting No. Series".SetValue(libraryStorage.Get('Noseries'));
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

    procedure CreateNoSeries(): Code[20]
    var
        Noseries: Code[20];
    begin
        Noseries := LibraryERM.CreateNoSeriesCode();
        libraryStorage.Set('Noseries', Noseries);
        exit(Noseries);
    end;


    [PageHandler]
    procedure VoucherAccountCredit(var VoucherCrAccount: TestPage "Voucher Posting Credit Account");
    var
        AccountNo: Code[20];
        AccountType: Enum "Gen. Journal Account Type";
    begin
        VoucherCrAccount.Type.SetValue(AccountType::"Bank Account");
        VoucherCrAccount."Account No.".SetValue(LibraryStorage.Get('BankAccount'));
    end;

    [PageHandler]
    procedure VoucherAccountDebit(var VoucherDrAccount: TestPage "Voucher Posting Debit Accounts");
    var
        AccountNo: Variant;
        AccountType: Enum "Gen. Journal Account Type";
    begin
        VoucherDrAccount.Type.SetValue(AccountType::"Bank Account");
        VoucherDrAccount."Account No.".SetValue(LibraryStorage.Get('BankAccount'));
    end;

    local procedure CreateGenJnlTemplateAndBatch(var GenJournalTemplate: Record "Gen. Journal Template"; var GenJournalBatch: Record "Gen. Journal Batch"; LocationCode: code[20]; VoucherType: enum "Gen. Journal Template Type");
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, VoucherType);
        GenJournalTemplate.Modify(true);
        LibraryStorage.Set('TemplateName', GenJournalTemplate.Name);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("Location Code", LocationCode);
        GenJournalBatch.Validate("Posting No. Series", LibraryStorage.Get('Noseries'));
        GenJournalBatch.Modify(true);
        LibraryStorage.Set('BatchName', GenJournalBatch.Name);
    end;

    procedure CreateBankChargeSetup(var BankAccount: Record "Bank Account"; VoucherType: Enum "Gen. Journal Template Type"; ForeignExchange: Boolean)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        CompanyInformation: Record "Company Information";
        State: Record State;
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        State.Get(LibraryStorage.Get('ToStateCode'));
        BankAccount.Validate("State Code", LibraryStorage.Get('ToStateCode'));
        BankAccount.Validate("GST Registration No.",
         LibraryGST.GenerateGSTRegistrationNo(CopyStr(State."State Code (GST Reg. No.)", 1, 2),
          LibraryGST.CreatePANNos()));
        BankAccount.Validate("GST Registration Status", BankAccount."GST Registration Status"::Registered);
        BankAccount.Modify(true);
        LibraryStorage.Set('BankAccount', BankAccount."No.");
        CreateNoSeries();
        CreateVoucherAccountSetup(VoucherType, LibraryStorage.Get('LocationCode'));
        CreateGenJnlTemplateAndBatch(GenJournalTemplate, GenJournalBatch, LibraryStorage.Get('LocationCode'), VoucherType);
        CreateBankCharge(ForeignExchange);
    end;

    local procedure CreateBankCharge(ForeignExchange: Boolean)
    var
        BankCharge: Record "Bank Charge";
        GLAccount: Record "G/L Account";
        InputCreditAvailment, Exempted : Boolean;
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        BankCharge.Init();
        BankCharge.Validate(Code, LibraryUtility.GenerateRandomCode(BankCharge.FieldNo(Code), Database::"Bank Charge"));
        BankCharge.Validate(Description, BankCharge.Code);
        BankCharge.Validate(Account, GLAccount."No.");
        BankCharge.Validate("Foreign Exchange", ForeignExchange);
        BankCharge.Validate("GST Group Code", LibraryStorage.Get('GSTGroupCode'));
        BankCharge.Validate("HSN/SAC Code", LibraryStorage.Get('HSNSACCode'));
        Evaluate(InputCreditAvailment, LibraryStorage.Get('InputCreditAvailment'));
        if InputCreditAvailment then
            BankCharge.Validate("GST Credit", BankCharge."GST Credit"::Availment)
        else
            BankCharge.Validate("GST Credit", BankCharge."GST Credit"::"Non-Availment");
        BankCharge.Insert();
        LibraryStorage.Set('BankCharge', BankCharge.Code);
        if ForeignExchange then
            CreateBankDeemedValueSetup();
    end;

    local procedure CreateBankDeemedValueSetup()
    var
        BankChargeDeemedValueSetup: Record "Bank Charge Deemed Value Setup";
    begin
        BankChargeDeemedValueSetup.Init();
        BankChargeDeemedValueSetup.Validate("Bank Charge Code", LibraryStorage.Get('BankCharge'));
        BankChargeDeemedValueSetup.Validate("Lower Limit", LibraryRandom.RandDecInRange(0, 500, 0));
        BankChargeDeemedValueSetup.Validate("Upper Limit", LibraryRandom.RandDecInRange(500, 1000, 0));
        BankChargeDeemedValueSetup.Validate(Formula, BankChargeDeemedValueSetup.Formula::Comparative);
        BankChargeDeemedValueSetup.Validate("Min. Deemed Value", LibraryRandom.RandDecInRange(500, 1000, 0));
        BankChargeDeemedValueSetup.Validate("Max. Deemed Value", LibraryRandom.RandDecInRange(500, 1000, 0));
        BankChargeDeemedValueSetup.Validate("Deemed %", LibraryRandom.RandDecInRange(500, 1000, 0));
        BankChargeDeemedValueSetup.Validate("Fixed Amount", LibraryRandom.RandDecInRange(100, 500, 0));
        BankChargeDeemedValueSetup.Insert();
    end;


    local procedure FillCompanyInformation()
    var
        CompanyInformation: Record "Company Information";
        GSTRegistrationNos: Record "GST Registration Nos.";
    begin
        CompanyInformation.Get();
        if CompanyInformation."GST Registration No." = '' then begin
            if GSTRegistrationNos.FindFirst() then
                CompanyInformation.Validate("P.A.N. No.", CopyStr(GSTRegistrationNos.Code, 3, 10))
            else
                CompanyInformation.Validate("P.A.N. No.", LibraryGST.CreatePANNos());
        end else
            CompanyInformation.Validate("P.A.N. No.", CopyStr(CompanyInformation."GST Registration No.", 3, 10));
        CompanyInformation.Modify(true);
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryGST: Codeunit "Library GST";
        LibrarySales: Codeunit "Library - Sales";
        LibraryStorage: Dictionary of [Text, Text];
        ComponentPerArray: array[20] of Decimal;
}
