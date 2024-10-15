codeunit 18136 "GST Purchase Reverse Charge"
{
    Subtype = Test;
    //Scenario-354131 Check if the system is calculating GST in case of Intra-State Purchase of Services from an Registered Vendor where Input Tax Credit is available (Reverse Charge) through Purchase Quote
    // [FEATURE] [Service Purchase Quote] [Intra-State Reverse Charge,Registered Vendor]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure PostFormGSTPurchaseServiceQuoteReverseChargeWithInputTaxCredit()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GSTVendorType: Enum "GST Vendor Type";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        OrderNo: Code[20];
    begin
        // [GIVEN] Created GST Setup 
        Initialize(GSTVendorType::Registered, GSTGroupType::Service, true);
        InitializeShareStep(true, false, false);
        LibraryGST.UpdateGSTGroupCodeWithReversCharge((Storage.Get('GSTGroupCode')), true);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Services for Intrastate Transactions.
        CreatePurchaseDocument(
            PurchaseHeader,
            PurchaseLine,
            LineType::"G/L Account",
            PurchaseHeader."Document Type"::Quote);

        //[THEN] Create Purchase Quote To Purchase Order
        LibraryPurchase.QuoteMakeOrder(PurchaseHeader);
    end;

    //Scenario-354132 Check if the system is calculating GST in case of Intra-State Purchase of Services from an Registered Vendor where Input Tax Credit is available (Reverse Charge) through Purchase Orders
    // [FEATURE] [Service Purchase Orders] // [FEATURE] [Service Purchase Quote] [Intra-State Reverse Charge , Registered Vendor]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure PostFormGSTPurchaseServiceOrdersReverseChargeWithInputTaxCredit()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GSTVendorType: Enum "GST Vendor Type";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
    begin
        NoOfLine := 1;

        // [GIVEN] Created GST Setup 
        Initialize(GSTVendorType::Registered, GSTGroupType::Service, true);
        InitializeShareStep(true, false, false);
        LibraryGST.UpdateGSTGroupCodeWithReversCharge((Storage.Get('GSTGroupCode')), true);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and PostEd Purchase Order with GST and Line Type as Services for Intrastate Transactions.
        CreatePurchaseDocument(
            PurchaseHeader,
            PurchaseLine,
            LineType::"G/L Account",
            PurchaseHeader."Document Type"::Order);

        //[THEN] G/L Entries Verified
        LibraryGST.GSTLedgerEntryCount(PostedDocumentNo, 2);
    end;

    //Scenario-354133 Check if the system is calculating GST in case of Intra-State Purchase of Services from an Registered Vendor where Input Tax Credit is available (Reverse Charge) through Purchase Invoice
    // [FEATURE] [Service Purchase Invoice] [FEATURE] [Service Purchase Quote] [Intra-State Reverse Charge , Registered Vendor]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure PostFormGSTPurchaseServiceInvoiceReverseChargeWithInputTaxCredit()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GSTVendorType: Enum "GST Vendor Type";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
    begin
        // [GIVEN] Created GST Setup 
        Initialize(GSTVendorType::Registered, GSTGroupType::Service, true);
        InitializeShareStep(true, false, false);
        LibraryGST.UpdateGSTGroupCodeWithReversCharge((Storage.Get('GSTGroupCode')), true);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and PostEd Purchase Invoice with GST and Line Type as Services for Intrastate Transactions.
        CreatePurchaseDocument(
            PurchaseHeader,
            PurchaseLine,
            LineType::"G/L Account",
            PurchaseHeader."Document Type"::Invoice);

        //[THEN] G/L Entries Verified
        LibraryGST.GSTLedgerEntryCount(PostedDocumentNo, 2);
    end;
    //
    //Scenario-354136 Check if the system is calculating GST in case of Intra-State Purchase of Services from an Registered Vendor where Input Tax Credit is available (Reverse Charge) through Purchase Quote
    // [FEATURE] [Service Purchase Quote] [Intra-State Reverse Charge Without ITC ,Registered Vendor]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure PostFormGSTPurchaseServiceQuoteReverseChargeWithoutInputTaxCredit()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GSTVendorType: Enum "GST Vendor Type";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        OrderNo: Code[20];
    begin
        // [GIVEN] Created GST Setup 
        Initialize(GSTVendorType::Registered, GSTGroupType::Service, true);
        InitializeShareStep(false, false, false);
        LibraryGST.UpdateGSTGroupCodeWithReversCharge((Storage.Get('GSTGroupCode')), true);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and Posted Purchase Quote with GST and Line Type as Services for Intrastate Transactions.
        CreatePurchaseDocument(
            PurchaseHeader,
            PurchaseLine,
            LineType::"G/L Account",
            PurchaseHeader."Document Type"::Quote);

        //[THEN] G/L Entries Verified
        LibraryPurchase.QuoteMakeOrder(PurchaseHeader);
    end;

    //Scenario-354141 Check if the system is calculating GST in case of Inter-State Purchase of Services from an Registered Vendor where Input Tax Credit is available (Reverse Charge) through Purchase Quotes
    // [FEATURE] [Service Purchase Quotes] [Inter-State Reverse Charge With ITC Registered Vendor]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure PostFormInterStateGSTPurchaseServiceQuoteReverseChargeWithInputTaxCredit()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GSTVendorType: Enum "GST Vendor Type";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        InputCreditAvailment: Boolean;
        IntraState: Boolean;
        Exempted: Boolean;
        LineDiscount: Boolean;
        ReverseCharge: Boolean;
    begin
        GSTVendorType := GSTVendorType::Registered;
        IntraState := false;
        LineType := LineType::"G/L Account";
        GSTGroupType := GSTGroupType::Service;
        InputCreditAvailment := true;
        ReverseCharge := true;
        LineDiscount := false;
        NoOfLine := 1;
        Exempted := false;

        // [GIVEN] Created GST Setup 
        Initialize(GSTVendorType::Registered, GSTGroupType::Service, IntraState);
        InitializeShareStep(InputCreditAvailment, Exempted, LineDiscount);
        LibraryGST.UpdateGSTGroupCodeWithReversCharge((Storage.Get('GSTGroupCode')), ReverseCharge);

        //[WHEN] Created and PostED Purchase Order with GST and Line Type as Services for Intrastate Transactions.
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, LineType::"G/L Account", PurchaseHeader."Document Type"::Quote);

        //[THEN] Create Purchase Quote To Purchase Order
        LibraryPurchase.QuoteMakeOrder(PurchaseHeader);
    end;

    //Scenario-354142 Check if the system is calculating GST in case of Inter-State Purchase of Services from an Registered Vendor where Input Tax Credit is available (Reverse Charge) through Purchase Orders
    // [FEATURE] [Service Purchase Order] [Inter-State Reverse Charge With ITC Registered Vendor]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure PostFormInterStateGSTPurchaseServiceOrderReverseChargeWithInputTaxCredit()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GSTVendorType: Enum "GST Vendor Type";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        InputCreditAvailment: Boolean;
        IntraState: Boolean;
        Exempted: Boolean;
        LineDiscount: Boolean;
        ReverseCharge: Boolean;
    begin
        GSTVendorType := GSTVendorType::Registered;
        IntraState := FALSE;
        LineType := LineType::"G/L Account";
        GSTGroupType := GSTGroupType::Service;
        InputCreditAvailment := true;
        ReverseCharge := true;
        LineDiscount := false;
        NoOfLine := 1;
        Exempted := FALSE;

        // [GIVEN] Created GST Setup
        Initialize(GSTVendorType::Registered, GSTGroupType::Service, IntraState);
        InitializeShareStep(InputCreditAvailment, Exempted, LineDiscount);
        LibraryGST.UpdateGSTGroupCodeWithReversCharge((Storage.Get('GSTGroupCode')), ReverseCharge);

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as GLAccount for Interstate Transactions.
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, LineType::"G/L Account", PurchaseHeader."Document Type"::Order);

        //[THEN] G/L Entries Verified
        LibraryGST.GSTLedgerEntryCount(PostedDocumentNo, 1);
    end;

    //Scenario-354150 Check if the system is calculating GST in case of Inter-State Purchase of Services from an Registered Vendor where Input Tax Credit is available (Reverse Charge) through purchase Invoices
    // [FEATURE] [Service Purchase Invoice] [Inter-State Reverse Charge With ITC Registered Vendor] 
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure PostFormInterStateGSTPurchaseServiceInvoiceReverseChargeWithInputTaxCredit()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GSTVendorType: Enum "GST Vendor Type";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        InputCreditAvailment: Boolean;
        IntraState: Boolean;
        Exempted: Boolean;
        LineDiscount: Boolean;
        ReverseCharge: Boolean;
    begin
        GSTVendorType := GSTVendorType::Registered;
        IntraState := FALSE;
        LineType := LineType::"G/L Account";
        GSTGroupType := GSTGroupType::Service;
        InputCreditAvailment := true;
        ReverseCharge := true;
        LineDiscount := false;
        NoOfLine := 1;
        Exempted := FALSE;

        // [GIVEN] Created GST Setup 
        Initialize(GSTVendorType::Registered, GSTGroupType::Service, IntraState);
        InitializeShareStep(InputCreditAvailment, Exempted, LineDiscount);
        LibraryGST.UpdateGSTGroupCodeWithReversCharge((Storage.Get('GSTGroupCode')), ReverseCharge);

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Services for Intrastate Transactions.
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, LineType::"G/L Account", PurchaseHeader."Document Type"::Invoice);

        //[THEN] G/L Entries Verified
        LibraryGST.GSTLedgerEntryCount(PostedDocumentNo, 1);
    end;

    //Scenario-354154 Check if the system is calculating GST in case of Inter-State Purchase of Services from an Registered Vendor where Input Tax Credit is not available (Reverse Charge) through Purchase Quotes
    // [FEATURE] [Service Purchase Quotes] [Inter-State Reverse Charge Without ITC Registered Vendor]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure PostFormInterStateGSTPurchaseServiceQuoteReverseChargeWithoutInputTaxCredit()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GSTVendorType: Enum "GST Vendor Type";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        InputCreditAvailment: Boolean;
        IntraState: Boolean;
        Exempted: Boolean;
        LineDiscount: Boolean;
        ReverseCharge: Boolean;
    begin
        GSTVendorType := GSTVendorType::Registered;
        IntraState := FALSE;
        LineType := LineType::"G/L Account";
        GSTGroupType := GSTGroupType::Service;
        InputCreditAvailment := false;
        ReverseCharge := true;
        LineDiscount := false;
        NoOfLine := 1;
        Exempted := false;

        // [GIVEN] Created GST Setup 
        Initialize(GSTVendorType::Registered, GSTGroupType::Service, IntraState);
        InitializeShareStep(InputCreditAvailment, Exempted, LineDiscount);
        LibraryGST.UpdateGSTGroupCodeWithReversCharge((Storage.Get('GSTGroupCode')), ReverseCharge);

        //[WHEN] Created and PostED Purchase Order with GST and Line Type as Services for Intrastate Transactions.
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, LineType::"G/L Account", PurchaseHeader."Document Type"::Quote);

        //[THEN] Create Purchase Quote To Purchase Order
        LibraryPurchase.QuoteMakeOrder(PurchaseHeader);
    end;

    //Scenario-354155 Check if the system is calculating GST in case of Inter-State Purchase of Services from an Registered Vendor where Input Tax Credit is not available (Reverse Charge) through Purchase Orders
    //Input Tax Credit is not available 
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure PostFormInterStateGSTPurchaseServiceOrderReverseChargeWithoutInputTaxCredit()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GSTVendorType: Enum "GST Vendor Type";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        InputCreditAvailment: Boolean;
        IntraState: Boolean;
        Exempted: Boolean;
        LineDiscount: Boolean;
        ReverseCharge: Boolean;
    begin
        GSTVendorType := GSTVendorType::Registered;
        IntraState := FALSE;
        LineType := LineType::"G/L Account";
        GSTGroupType := GSTGroupType::Service;
        InputCreditAvailment := FALSE;
        ReverseCharge := true;
        LineDiscount := false;
        NoOfLine := 1;
        Exempted := FALSE;

        // [GIVEN] Created GST Setup 
        Initialize(GSTVendorType::Registered, GSTGroupType::Service, IntraState);
        InitializeShareStep(InputCreditAvailment, Exempted, LineDiscount);
        LibraryGST.UpdateGSTGroupCodeWithReversCharge((Storage.Get('GSTGroupCode')), ReverseCharge);

        //[WHEN] Created and PostED Purchase Order with GST and Line Type as Services for Intrastate Transactions.
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, LineType::"G/L Account", PurchaseHeader."Document Type"::Order);

        //[THEN] G/L Entries Verified
        LibraryGST.GSTLedgerEntryCount(PostedDocumentNo, 1);
    end;

    //Scenario-354156 Check if the system is calculating GST in case of Inter-State Purchase of Services from an Registered Vendor where Input Tax Credit is not available (Reverse Charge) through Purchase Invoices
    //Input Tax Credit is not available 
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure PostFormInterStateGSTPurchaseServiceInvoiceReverseChargeWithoutInputTaxCredit()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GSTVendorType: Enum "GST Vendor Type";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        InputCreditAvailment: Boolean;
        IntraState: Boolean;
        Exempted: Boolean;
        LineDiscount: Boolean;
        ReverseCharge: Boolean;
    begin
        GSTVendorType := GSTVendorType::Registered;
        IntraState := FALSE;
        LineType := LineType::"G/L Account";
        GSTGroupType := GSTGroupType::Service;
        InputCreditAvailment := FALSE;
        ReverseCharge := true;
        LineDiscount := false;
        NoOfLine := 1;
        Exempted := FALSE;

        // [GIVEN] Created GST Setup 
        Initialize(GSTVendorType::Registered, GSTGroupType::Service, IntraState);
        InitializeShareStep(InputCreditAvailment, Exempted, LineDiscount);
        LibraryGST.UpdateGSTGroupCodeWithReversCharge((Storage.Get('GSTGroupCode')), ReverseCharge);

        //[WHEN] Created and PostED Purchase Order with GST and Line Type as Services for Intrastate Transactions.
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, LineType::"G/L Account", PurchaseHeader."Document Type"::Invoice);

        //[THEN] G/L Entries Verified
        LibraryGST.GSTLedgerEntryCount(PostedDocumentNo, 1);
    end;

    local procedure CreatePurchaseHeaderWithGST(VAR PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; DocumentType: Enum "Purchase Document Type"; LocationCode: Code[10])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Posting Date", WorkDate());
        PurchaseHeader.VALIDATE("Location Code", LocationCode);

        PurchaseHeader."Vendor Invoice No." := LibraryUtility.GenerateRandomCode(PurchaseHeader.fieldno("Vendor Invoice No."), Database::"Purchase Header");
        if PurchaseHeader."GST Vendor Type" = PurchaseHeader."GST Vendor Type"::SEZ then begin
            PurchaseHeader."Bill of Entry No." := LibraryUtility.GenerateRandomCode(PurchaseHeader.fieldno("Bill of Entry No."), Database::"Purchase Header");
            PurchaseHeader."Bill of Entry Date" := WorkDate();
            PurchaseHeader."Bill of Entry Value" := 1001;
        end;
        PurchaseHeader.MODIFY(TRUE);
    end;

    local procedure CreatePurchaseDocument(VAR PurchaseHeader: Record "Purchase Header"; VAR PurchaseLine: Record "Purchase Line"; LineType: Enum "Purchase Line Type"; DocumentType: Enum "Purchase Document Type")
    var
        VendorNo2: Code[20];
        LocationCode2: Code[10];
        Exempted: Boolean;
    begin
        VendorNo2 := Storage.Get('VendorNo');
        evaluate(LocationCode2, Storage.Get('LocationCode'));
        Exempted := FALSE;

        CreatePurchaseHeaderWithGST(PurchaseHeader, VendorNo2, DocumentType, LocationCode2);
        CreatePurchaseLineWithGST(PurchaseHeader, PurchaseLine, LineType, LibraryRandom.RandDecInRange(2, 10, 0), StorageBoolean.Get('InputCreditAvailment'), Exempted, StorageBoolean.Get('LineDiscount'));
        if not (PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Quote) then
            PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, TRUE, TRUE);
    end;

    local procedure CreatePurchaseLineWithGST(VAR PurchaseHeader: Record "Purchase Header"; VAR PurchaseLine: Record "Purchase Line"; LineType: Enum "Purchase Line Type"; Quantity: Decimal; InputCreditAvailment: Boolean; Exempted: Boolean; LineDiscount: Boolean);
    var
        VATPostingSetup: Record "VAT Posting Setup";
        LineTypeNo: Code[20];
        LineNo: Integer;
    begin
        for LineNo := 1 to NoOfLine do begin
            case LineType of
                LineType::Item:
                    LineTypeNo := LibraryGST.CreateItemWithGSTDetails(VATPostingSetup, (Storage.Get('GSTGroupCode')), (Storage.Get('HSNSACCode')), InputCreditAvailment, Exempted);
                LineType::"G/L Account":
                    LineTypeNo := LibraryGST.CreateGLAccWithGSTDetails(VATPostingSetup, (Storage.Get('GSTGroupCode')), (Storage.Get('HSNSACCode')), InputCreditAvailment, FALSE);
                LineType::"Fixed Asset":
                    LineTypeNo := LibraryGST.CreateFixedAssetWithGSTDetails(VATPostingSetup, (Storage.Get('GSTGroupCode')), (Storage.Get('HSNSACCode')), InputCreditAvailment, Exempted);
            end;

            LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, LineType, LineTypeno, Quantity);

            PurchaseLine.VALIDATE("VAT Prod. Posting Group", VATPostingsetup."VAT Prod. Posting Group");
            PurchaseLine.VALIDATE("Direct Unit Cost", LibraryRandom.RandInt(1000));
            if InputCreditAvailment then
                PurchaseLine."GST Credit" := PurchaseLine."GST Credit"::Availment
            else
                PurchaseLine."GST Credit" := PurchaseLine."GST Credit"::"Non-Availment";

            if LineDiscount then begin
                PurchaseLine.Validate("Line Discount %", LibraryRandom.RandDecInRange(10, 20, 2));
                LibraryGST.UpdateLineDiscAccInGeneralPostingSetup(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
            end;

            if (PurchaseHeader."GST Vendor Type" in [PurchaseHeader."GST Vendor Type"::Import, PurchaseHeader."GST Vendor Type"::SEZ]) and (PurchaseLine.Type = PurchaseLine.Type::Item) then begin
                PurchaseLine.Validate("GST Assessable Value", PurchaseLine."Line Amount");
                PurchaseLine.Validate("Custom Duty Amount", PurchaseLine."Line Amount");
            end;
            PurchaseLine.MODIFY(TRUE);
        end;
    end;

    local procedure Initialize(GSTVendorType: Enum "GST Vendor Type"; GSTGroupType: Enum "GST Group Type"; IntraState: Boolean)
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
        HSNSACCode: Code[10];
        GSTGroupCode: Code[20];
        LocationGSTRegNo: Code[15];
        HsnSacType: Enum "GST Goods And Services Type";
        GSTcomponentcode: Text[30];
        isInitialized: Boolean;
    begin
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;
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

        GSTGroupCode := LibraryGST.CreateGSTGroup(GSTGroup, GSTGroupType, GSTGroup."GST Place Of Supply"::" ", false);
        Storage.Set('GSTGroupCode', GSTGroupCode);

        HSNSACCode := LibraryGST.CreateHSNSACCode(HSNSAC, GSTGroupCode, HsnSacType::HSN);
        Storage.Set('HSNSACCode', HSNSACCode);

        if IntraState then begin
            VendorNo := LibraryGST.CreateVendorSetup();
            UpdateVendorSetupWithGST(VendorNo, GSTVendorType, false, LocationStateCode, LocPan);
            InitializeTaxRateParameters(IntraState, LocationStateCode, LocationStateCode);
            CreateGSTComponentAndPostingSetup(IntraState, LocationStateCode, GSTComponent, GSTcomponentcode);
        end else begin
            VendorStateCode := LibraryGST.CreateGSTStateCode(); //
            VendorNo := LibraryGST.CreateVendorSetup();
            UpdateVendorSetupWithGST(VendorNo, GSTVendorType, false, VendorStateCode, LocPan);
            Storage.Set('VendorStateCode', VendorStateCode);
            if GSTVendorType in [GSTVendorType::Import, GSTVendorType::SEZ] then
                InitializeTaxRateParameters(IntraState, LocationStateCode, '')
            else begin
                InitializeTaxRateParameters(IntraState, VendorStateCode, LocationStateCode);
                CreateGSTComponentAndPostingSetup(IntraState, LocationStateCode, GSTComponent, GSTcomponentcode);
            end;
        end;
        Storage.Set('VendorNo', VendorNo);

        CreateTaxRate(false);
        isInitialized := TRUE;
    end;

    local procedure InitializeShareStep(InputCreditAvailment: Boolean; Exempted: Boolean; LineDiscount: Boolean)
    begin
        StorageBoolean.Set('InputCreditAvailment', InputCreditAvailment);
        StorageBoolean.Set('Exempted', Exempted);
        StorageBoolean.Set('LineDiscount', LineDiscount);
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
        if Vendor."GST Vendor Type" = vendor."GST Vendor Type"::Import then
            vendor.Validate("Associated Enterprises", AssociateEnterprise);
        Vendor.Modify(true);
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

    local procedure InitializeTaxRateParameters(IntraState: Boolean; FromState: Code[10]; ToState: Code[10])
    var
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

    procedure CreateTaxRate(POS: boolean)
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
    procedure TaxRatesPage(var TaxRate: TestPage "Tax Rates")
    begin
        TaxRate.AttributeValue1.SetValue(Storage.Get('HSNSACCode'));
        TaxRate.AttributeValue2.SetValue(Storage.Get('GSTGroupCode'));
        TaxRate.AttributeValue3.SetValue(Storage.Get('FromStateCode'));
        TaxRate.AttributeValue4.SetValue(Storage.Get('ToStateCode'));
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

    var
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryGST: Codeunit "Library GST";
        ComponentPerArray: array[20] of Decimal;
        PostedDocumentNo: code[20];
        NoOfLine: Integer;
        Storage: Dictionary of [Text, Text[20]];
        StorageBoolean: Dictionary of [Text, Boolean];
}