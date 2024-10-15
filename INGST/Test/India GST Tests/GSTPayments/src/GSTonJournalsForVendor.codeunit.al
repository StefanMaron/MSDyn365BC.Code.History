codeunit 18272 "GST on Journals For Vendor"
{
    Subtype = Test;

    var
        VATPostingSetup: Record "VAT Posting Setup";
        LibraryRandom: Codeunit "Library - Random";
        LibraryGST: Codeunit "Library GST";
        ComponentPerArray: array[20] of Decimal;
        Storage: Dictionary of [Text, Text[20]];
        StorageEnum: Dictionary of [Text, Text];
        StorageBoolean: Dictionary of [Text, Boolean];

    //[Scenario 355324] Check If system is calculating GST when Invoice created from Purchase Journals for Registered Vendor.
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromPurchaseJournalWithITCForRegisetredVendor()
    var
        GenJournalLine: Record "Gen. Journal Line";
        LibraryERM: Codeunit "Library - ERM";
        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        TemplateType: enum "Gen. Journal Template Type";
        GenJnlDocType: Enum "Gen. Journal Document Type";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created GST Setup
        InitializeShareStep(true, false);
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Service, true, false);

        //[WHEN] Create and Post Purchase Journal
        CreateGenJnlLineFromVendorToGL(GenJnlDocType::Invoice, GenJournalLine, TemplateType::Purchases);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN] Verify GST ledger entries
        DocumentNo := LibraryGST.VerifyGLEntry(GenJournalLine."Journal Batch Name");
        LibraryGST.GSTLedgerEntryCount(DocumentNo, 2);
    end;

    //[Scenario 355325] Check If system is calculating GST when Invoice created from Purchase Journals for Unregistered Vendor.
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromPurchaseJournalWithITCForUnregisetredVendor()
    var
        GenJournalLine: Record "Gen. Journal Line";
        LibraryERM: Codeunit "Library - ERM";
        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        TemplateType: enum "Gen. Journal Template Type";
        GenJnlDocType: Enum "Gen. Journal Document Type";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created GST Setup
        InitializeShareStep(true, false);
        CreateGSTSetup(GSTVendorType::Unregistered, GSTGroupType::Service, true, true);

        //[WHEN] Create and Post Purchase Journal
        CreateGenJnlLineFromVendorToGL(GenJnlDocType::Invoice, GenJournalLine, TemplateType::Purchases);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN] Verify GST ledger entries
        DocumentNo := LibraryGST.VerifyGLEntry(GenJournalLine."Journal Batch Name");
        LibraryGST.GSTLedgerEntryCount(DocumentNo, 2);
    end;

    //[Scenario 355326] Check If system is calculating GST when Invoice created from Purchase Journals for Import Vendor.
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromPurchaseJournalWithITCForImportVendor()
    var
        GenJournalLine: Record "Gen. Journal Line";
        LibraryERM: Codeunit "Library - ERM";
        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        TemplateType: enum "Gen. Journal Template Type";
        GenJnlDocType: Enum "Gen. Journal Document Type";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created GST Setup
        InitializeShareStep(true, false);
        CreateGSTSetup(GSTVendorType::Import, GSTGroupType::Service, false, true);

        //[WHEN] Create and Post Purchase Journal
        CreateGenJnlLineFromVendorToGL(GenJnlDocType::Invoice, GenJournalLine, TemplateType::Purchases);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN] Verify GST ledger entries
        DocumentNo := LibraryGST.VerifyGLEntry(GenJournalLine."Journal Batch Name");
        LibraryGST.GSTLedgerEntryCount(DocumentNo, 1);
    end;

    //[Scenario 355327] Check If system is calculating GST when Invoice created from Purchase Journals for Associate Import Vendor.
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromPurchaseJournalWithITCForAssociateVendor()
    var
        GenJournalLine: Record "Gen. Journal Line";
        LibraryERM: Codeunit "Library - ERM";
        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        TemplateType: enum "Gen. Journal Template Type";
        GenJnlDocType: Enum "Gen. Journal Document Type";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created GST Setup
        InitializeShareStep(true, false);
        InitializeAssociateVendor(true);
        CreateGSTSetup(GSTVendorType::Import, GSTGroupType::Service, false, true);

        //[WHEN] Create and Post Purchase Journal
        CreateGenJnlLineFromVendorToGL(GenJnlDocType::Invoice, GenJournalLine, TemplateType::Purchases);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN] Verify GST ledger entries
        DocumentNo := LibraryGST.VerifyGLEntry(GenJournalLine."Journal Batch Name");
        LibraryGST.GSTLedgerEntryCount(DocumentNo, 1);
    end;

    //[Scenario 357299] Intra-State Purchase of Services from an Unregistered Vendor where Input Tax Credit is not available (Reverse Charge) through General Journal
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromGeneralJournalWithReverseChargeWithoutInputCreditAvailmentForUnregisetredVendor()
    var
        GenJournalLine: Record "Gen. Journal Line";
        LibraryERM: Codeunit "Library - ERM";
        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        TemplateType: enum "Gen. Journal Template Type";
        GenJnlDocType: Enum "Gen. Journal Document Type";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created GST Setup
        InitializeShareStep(false, false);
        CreateGSTSetup(GSTVendorType::Unregistered, GSTGroupType::Service, true, true);

        //[WHEN] Create and Post General Journal
        CreateGenJnlLineFromVendorToGL(GenJnlDocType::Invoice, GenJournalLine, TemplateType::General);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN] Verify GST ledger entries
        DocumentNo := LibraryGST.VerifyGLEntry(GenJournalLine."Journal Batch Name");
        LibraryGST.GSTLedgerEntryCount(DocumentNo, 2);
    end;

    //[Scenario 357303] Intra-State Purchase of Services from an Registered Vendor where Input Tax Credit is available (Reverse Charge) through Purchase Journal
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromPurchaseJournalWithReverseChargeWithAvailment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        LibraryERM: Codeunit "Library - ERM";
        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        TemplateType: enum "Gen. Journal Template Type";
        GenJnlDocType: Enum "Gen. Journal Document Type";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created GST Setup
        InitializeShareStep(true, false);
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Service, true, true);

        //[WHEN] Create and Post Purchase Journal
        CreateGenJnlLineFromVendorToGL(GenJnlDocType::Invoice, GenJournalLine, TemplateType::Purchases);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN] Verify GST ledger entries
        DocumentNo := LibraryGST.VerifyGLEntry(GenJournalLine."Journal Batch Name");
        LibraryGST.GSTLedgerEntryCount(DocumentNo, 2);
    end;

    //[Scenario 357444] Intra-State Purchase of Services from an Registered Vendor where Input Tax Credit is not available (Reverse Charge) through Purchase Journal
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromPurchaseJournalWithReverseChargeWithoutInputCreditAvailment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        LibraryERM: Codeunit "Library - ERM";
        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        TemplateType: enum "Gen. Journal Template Type";
        GenJnlDocType: Enum "Gen. Journal Document Type";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created GST Setup
        InitializeShareStep(false, false);
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Service, true, true);

        //[WHEN] Create and Post Purchase Journal
        CreateGenJnlLineFromVendorToGL(GenJnlDocType::Invoice, GenJournalLine, TemplateType::Purchases);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN] Verify GST ledger entries
        DocumentNo := LibraryGST.VerifyGLEntry(GenJournalLine."Journal Batch Name");
        LibraryGST.GSTLedgerEntryCount(DocumentNo, 2);
    end;

    //[Scenario 355329] Check If system is calculating GST when Invoice created from FA G/L Journals for Registered Vendor 
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromFAGLournalForRegisteredWithAvailmentForIntraState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        LibraryERM: Codeunit "Library - ERM";

        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        TemplateType: enum "Gen. Journal Template Type";
        GenJnlDocType: Enum "Gen. Journal Document Type";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created GST Setup
        InitializeShareStep(true, false);
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Service, true, false);

        //[WHEN] Create and Post FA G/L Journal
        CreateGenJnlLineFromVendorToGL(GenJnlDocType::Invoice, GenJournalLine, TemplateType::Assets);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN] Verify GST ledger entries
        DocumentNo := LibraryGST.VerifyGLEntry(GenJournalLine."Journal Batch Name");
        LibraryGST.GSTLedgerEntryCount(DocumentNo, 2);
    end;

    //[Scenario 355331] Check If system is calculating GST when Invoice created from FA G/L Journals for Import Vendor 
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromFAGLournalForImportWithAvailmentForInterState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        LibraryERM: Codeunit "Library - ERM";

        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        TemplateType: enum "Gen. Journal Template Type";
        GenJnlDocType: Enum "Gen. Journal Document Type";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created GST Setup
        InitializeShareStep(true, false);
        CreateGSTSetup(GSTVendorType::Import, GSTGroupType::Service, false, false);

        //[WHEN] Create and Post FA G/L Journal
        CreateGenJnlLineFromVendorToGL(GenJnlDocType::Invoice, GenJournalLine, TemplateType::Assets);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN] Verify GST ledger entries
        DocumentNo := LibraryGST.VerifyGLEntry(GenJournalLine."Journal Batch Name");
        LibraryGST.GSTLedgerEntryCount(DocumentNo, 1);
    end;

    //[Scenario 355374] Check If system is calculating GST when Credit Memo created from FA G/L Journals for Registered Vendor 
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromFAGLournalCreditMemoForRegisteredWithAvailmentForIntraState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        LibraryERM: Codeunit "Library - ERM";

        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        TemplateType: enum "Gen. Journal Template Type";
        GenJnlDocType: Enum "Gen. Journal Document Type";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created GST Setup
        InitializeShareStep(true, false);
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Service, true, false);

        //[WHEN] Create and Post FA G/L Journal
        CreateGenJnlLineFromVendorToGL(GenJnlDocType::"Credit Memo", GenJournalLine, TemplateType::Assets);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN] Verify GST ledger entries
        DocumentNo := LibraryGST.VerifyGLEntry(GenJournalLine."Journal Batch Name");
        LibraryGST.GSTLedgerEntryCount(DocumentNo, 2);
    end;

    //[Scenario 355376] Check If system is calculating GST when Credit Memo created from FA G/L Journals for Unregistered Vendor 
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromFAGLournalCreditMemoForUnregisteredWithAvailmentForIntraState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        LibraryERM: Codeunit "Library - ERM";
        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        TemplateType: enum "Gen. Journal Template Type";
        GenJnlDocType: Enum "Gen. Journal Document Type";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created GST Setup
        InitializeShareStep(true, false);
        CreateGSTSetup(GSTVendorType::UnRegistered, GSTGroupType::Service, true, false);

        //[WHEN] Create and Post FA G/L Journal
        CreateGenJnlLineFromVendorToGL(GenJnlDocType::"Credit Memo", GenJournalLine, TemplateType::Assets);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN] Verify GST ledger entries
        DocumentNo := LibraryGST.VerifyGLEntry(GenJournalLine."Journal Batch Name");
        LibraryGST.GSTLedgerEntryCount(DocumentNo, 2);
    end;

    //[Scenario 357249] Inter-State Purchase of Goods from Registered Vendor where Input Tax Credit is not available through Purchase Journal
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromPurchaseJournalForGoodsRegisteredWithoutAvailmentInterState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        LibraryERM: Codeunit "Library - ERM";
        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        TemplateType: enum "Gen. Journal Template Type";
        GenJnlDocType: Enum "Gen. Journal Document Type";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created GST Setup
        InitializeShareStep(false, false);
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, false, false);

        //[WHEN] Create and Post Purchase Journal
        CreateGenJnlLineFromVendorToGL(GenJnlDocType::Invoice, GenJournalLine, TemplateType::Purchases);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN] Verify GST ledger entries
        DocumentNo := LibraryGST.VerifyGLEntry(GenJournalLine."Journal Batch Name");
        LibraryGST.GSTLedgerEntryCount(DocumentNo, 1);
    end;

    //[Scenario 357253] Inter-State Purchase of Services from Registered Vendor where Input Tax Credit is available through General journal
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromGeneralJournalForServiceRegisteredWithAvailmentInterState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        LibraryERM: Codeunit "Library - ERM";
        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        TemplateType: enum "Gen. Journal Template Type";
        GenJnlDocType: Enum "Gen. Journal Document Type";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created GST Setup
        InitializeShareStep(true, false);
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Service, false, false);

        //[WHEN] Create and Post General Journal
        CreateGenJnlLineFromVendorToGL(GenJnlDocType::Invoice, GenJournalLine, TemplateType::General);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN] Verify GST ledger entries
        DocumentNo := LibraryGST.VerifyGLEntry(GenJournalLine."Journal Batch Name");
        LibraryGST.GSTLedgerEntryCount(DocumentNo, 1);
    end;

    //[Scenario 357263] Inter-State Purchase of Services from Registered Vendor where Input Tax Credit is not available through General journal
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromGeneralJournalForServiceRegisteredWithoutAvailmentInterState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        LibraryERM: Codeunit "Library - ERM";
        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        TemplateType: enum "Gen. Journal Template Type";
        GenJnlDocType: Enum "Gen. Journal Document Type";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created GST Setup
        InitializeShareStep(false, false);
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Service, false, false);

        //[WHEN] Create and Post General Journal
        CreateGenJnlLineFromVendorToGL(GenJnlDocType::Invoice, GenJournalLine, TemplateType::General);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN] Verify GST ledger entries
        DocumentNo := LibraryGST.VerifyGLEntry(GenJournalLine."Journal Batch Name");
        LibraryGST.GSTLedgerEntryCount(DocumentNo, 1);
    end;

    //[Scenario 358518] Inter-State Purchase of Services from an Registered Vendor where Input Tax Credit is not available (Reverse Charge) through Purchase Journal
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromPurchaseJournalForRegisteredReverseInterState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        LibraryERM: Codeunit "Library - ERM";
        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        TemplateType: enum "Gen. Journal Template Type";
        GenJnlDocType: Enum "Gen. Journal Document Type";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Service, false, true);
        InitializeShareStep(true, false);
        //[WHEN] Create and Post Sales Journal
        CreateGenJnlLineFromVendorToGL(GenJnlDocType::Invoice, GenJournalLine, TemplateType::Purchases);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN] Verify GST ledger entries
        DocumentNo := LibraryGST.VerifyGLEntry(GenJournalLine."Journal Batch Name");
        LibraryGST.GSTLedgerEntryCount(DocumentNo, 1);
    end;

    local procedure CreateGSTSetup(GSTVendorType: Enum "GST Vendor Type"; GSTGroupType: Enum "GST Group Type"; IntraState: Boolean; ReverseCharge: Boolean)
    var
        GSTGroup: Record "GST Group";
        HSNSAC: Record "HSN/SAC";
        GSTComponent: Record "Tax Component";
        CompanyInformation: Record "Company information";
        LocationStateCode: Code[10];
        VendorNo: Code[20];
        LocationCode: Code[10];
        VendorStateCode: Code[10];
        LocPan: Code[20];
        LocationGSTRegNo: Code[15];
        HsnSacType: Enum "GST Goods And Services Type";
        GSTcomponentcode: Text[30];
        GSTGroupCode: Code[20];
        HSNSACCode: Code[10];
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
            VendorNo := LibraryGST.CreateVendorSetup();
            UpdateVendorSetupWithGST(VendorNo, GSTVendorType, false, LocationStateCode, LocPan);
            InitializeTaxRateParameters(IntraState, LocationStateCode, LocationStateCode);
            CreateGSTComponentAndPostingSetup(IntraState, LocationStateCode, GSTComponent, GSTcomponentcode);
        end else begin
            VendorStateCode := LibraryGST.CreateGSTStateCode();
            VendorNo := LibraryGST.CreateVendorSetup();
            if StorageBoolean.ContainsKey('AssociateEnterprise') then begin
                UpdateVendorSetupWithGST(VendorNo, GSTVendorType, StorageBoolean.Get('AssociateEnterprise'), VendorStateCode, LocPan);
                StorageBoolean.Remove('AssociateEnterprise')
            end else
                UpdateVendorSetupWithGST(VendorNo, GSTVendorType, false, VendorStateCode, LocPan);
            Storage.Set('VendorStateCode', VendorStateCode);
            if GSTVendorType in [GSTVendorType::Import, GSTVendorType::SEZ] then
                InitializeTaxRateParameters(IntraState, LocationStateCode, '')
            else
                InitializeTaxRateParameters(IntraState, VendorStateCode, LocationStateCode);
        end;
        Storage.Set('VendorNo', VendorNo);
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


    local procedure InitializeShareStep(InputCreditAvailment: Boolean; Exempted: Boolean)
    begin
        StorageBoolean.Set('InputCreditAvailment', InputCreditAvailment);
        StorageBoolean.Set('Exempted', Exempted);
    end;

    local procedure InitializeAssociateVendor(AssociateEnterprise: Boolean)
    begin
        StorageBoolean.Set('AssociateEnterprise', AssociateEnterprise);
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
        TaxRate.AttributeValue1.SetValue(Storage.Get('HSNSACCode'));
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
        if StorageBoolean.ContainsKey('POSoutOfIndia') then
            TaxRate.AttributeValue13.SetValue(format(StorageBoolean.Get('POSoutOfIndia')))
        else
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

    procedure CreateGenJnlLineFromVendorToGL(GenJnlDocType: Enum "Gen. Journal Document Type"; var GenJournalLine: Record "Gen. Journal Line";
        TemplateType: Enum "Gen. Journal Template Type")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        LibraryJournals: Codeunit "Library - Journals";
        VendorNo: code[20];
        LocationCode: Code[10];
        POSoutOfIndia: Boolean;
    begin
        CreateGenJournalTemplateBatch(GenJournalTemplate, GenJournalBatch, TemplateType);
        VendorNo := Storage.Get('VendorNo');
        evaluate(LocationCode, Storage.Get('LocationCode'));
        LibraryJournals.CreateGenJournalLine(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name,
                                            GenJnlDocType,
                                            GenJournalLine."Account Type"::Vendor, VendorNo,
                                            GenJournalLine."Bal. Account Type"::"G/L Account",
                                            LibraryGST.CreateGLAccWithGSTDetails(VATPostingSetup, CopyStr(Storage.Get('GSTGroupCode'), 1, 20), CopyStr(Storage.Get('HSNSACCode'), 1, 10), StorageBoolean.Get('InputCreditAvailment'), StorageBoolean.Get('Exempted')),
                                            -LibraryRandom.RandIntInRange(1, 10000));
        GenJournalLine.Validate("Location Code", LocationCode);
        GenJournalLine.Validate("GST Group Code");
        GenJournalLine.validate("HSN/SAC Code");
        if StorageBoolean.ContainsKey('POSoutOfIndia') then begin
            Evaluate(POSoutOfIndia, format(StorageBoolean.Get('POSoutOfIndia')));
            GenJournalLine.Validate("POS Out Of India", POSoutOfIndia);
            POSoutOfIndia := false;
        end;
        if GenJournalLine."Document Type" in [GenJournalLine."Document Type"::"Credit Memo"] then
            GenJournalLine.Validate(Amount, -GenJournalLine.Amount)
        else
            GenJournalLine.Validate(Amount);
        CalculateTDS(GenJournalLine);
        GenJournalLine.Modify(true);
    end;

    procedure CreateGenJnlLineFromGLToBank(GenJnlDocType: Enum "Gen. Journal Document Type"; var GenJournalLine: Record "Gen. Journal Line";
            TemplateType: Enum "Gen. Journal Template Type")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        BankAccount: Record "Bank Account";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryERM: Codeunit "Library - ERM";
        LocationCode: Code[10];
    begin
        CreateGenJournalTemplateBatch(GenJournalTemplate, GenJournalBatch, TemplateType);
        LibraryERM.CreateBankAccount(BankAccount);
        evaluate(LocationCode, Storage.Get('LocationCode'));
        LibraryJournals.CreateGenJournalLine(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name,
                                            GenJnlDocType,
                                            GenJournalLine."Account Type"::"G/L Account",
                                            LibraryGST.CreateGLAccWithGSTDetails(VATPostingSetup, CopyStr(Storage.Get('GSTGroupCode'), 1, 20), Copystr(Storage.Get('HSNSACCode'), 1, 10), StorageBoolean.Get('InputCreditAvailment'), StorageBoolean.Get('Exempted')),
                                            GenJournalLine."Bal. Account Type"::"Bank Account",
                                            BankAccount."No.",
                                            -LibraryRandom.RandIntInRange(1, 100000));
        GenJournalLine.Validate("Location Code", LocationCode);
        if GenJournalLine."Document Type" in [GenJournalLine."Document Type"::"Credit Memo"] then
            GenJournalLine.Validate(Amount, -GenJournalLine.Amount)
        else
            GenJournalLine.Validate(Amount);
        GenJournalLine.Validate("Location Code", LocationCode);
        GenJournalLine.Modify(true);
    end;

    procedure CreateGenJnlLineFromGLToGL(GenJnlDocType: Enum "Gen. Journal Document Type"; var GenJournalLine: Record "Gen. Journal Line";
            TemplateType: Enum "Gen. Journal Template Type")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        BankAccount: Record "Bank Account";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryERM: Codeunit "Library - ERM";
        LocationCode: Code[10];
    begin
        CreateGenJournalTemplateBatch(GenJournalTemplate, GenJournalBatch, TemplateType);
        LibraryERM.CreateBankAccount(BankAccount);
        evaluate(LocationCode, Storage.Get('LocationCode'));
        LibraryJournals.CreateGenJournalLine(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name,
                                            GenJnlDocType,
                                            GenJournalLine."Account Type"::"G/L Account",
                                            LibraryGST.CreateGLAccWithGSTDetails(VATPostingSetup, CopyStr(Storage.Get('GSTGroupCode'), 1, 20), Storage.Get('HSNSACCode'), StorageBoolean.Get('InputCreditAvailment'), StorageBoolean.Get('Exempted')),
                                            GenJournalLine."Bal. Account Type"::"G/L Account",
                                            LibraryGST.CreateGLAccWithGSTDetails(VATPostingSetup, '', '', true, false),
                                            -LibraryRandom.RandDecInRange(10000, 20000, 2));
        GenJournalLine.Validate("Location Code", LocationCode);
        if GenJournalLine."Document Type" in [GenJournalLine."Document Type"::"Credit Memo"] then
            GenJournalLine.Validate(Amount, -GenJournalLine.Amount)
        else
            GenJournalLine.Validate(Amount);
        GenJournalLine.Validate("Location Code", LocationCode);
        GenJournalLine.Modify(true);
        GenJournalLine.Validate(Amount);
        GenJournalLine.Modify(true);
    end;

    procedure UpdateVendorSetupWithGST(VendorNo: Code[20]; GSTVendorType: Enum "GST Vendor Type"; AssociateEnterprise: boolean; StateCode1: Code[10]; Pan: Code[20]);
    var
        Vendor: Record Vendor;
        State: Record State;
    begin
        Vendor.Get(VendorNo);
        if (GSTVendorType <> GSTVendorType::Import) then begin
            State.Get(StateCode1);
            Vendor.Validate("State Code", StateCode1);
            Vendor.Validate("P.A.N. No.", Pan);
            if not ((GSTVendorType = GSTVendorType::" ") OR (GSTVendorType = GSTVendorType::Unregistered)) then
                Vendor.Validate("GST Registration No.", LibraryGST.GenerateGSTRegistrationNo(State."State Code (GST Reg. No.)", Pan));
        end;
        Vendor.Validate("GST Vendor Type", GSTVendorType);
        if Vendor."GST Vendor Type" = Vendor."GST Vendor Type"::Import then
            Vendor.Validate("Associated Enterprises", AssociateEnterprise);
        Vendor.Modify(true);
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
        AccountNo: Variant;
        AccountType: Enum "Gen. Journal Account Type";
    begin
        Evaluate(AccountType, StorageEnum.Get('AccountType'));
        Evaluate(AccountNo, Storage.Get('AccountNo'));
        VoucherDrAccount.Type.SetValue(AccountType);
        VoucherDrAccount."Account No.".SetValue(AccountNo);
        VoucherDrAccount.OK().Invoke();
    end;

    procedure CalculateTDS(GenJnlLine: Record "Gen. Journal Line")
    var
        CalculateTax: Codeunit "Calculate Tax";
    begin
        CalculateTax.CallTaxEngineOnGenJnlLine(GenJnlLine, GenJnlLine)
    end;
}