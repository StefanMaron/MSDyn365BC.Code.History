codeunit 18137 "GST Purchase SEZ"
{
    Subtype = Test;

    //TestCaseID-355068 Check if the system is calculating GST in case of Inter-State Purchase of Fixed Assets from SEZ Vendor where Input Tax Credit is not available with invoice discount/line discount multiple HSN code wise through Purchase Invoice
    //[FEATURE] [Fixed Assets Purchase Invoice] [invoice discount/line discount Not ITC,SEZ Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromGSTPurchaseInvoiceSEZVendorWithoutITCWithLineDiscountForFixedAsset()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::SEZ, GSTGroupType::Goods, false, false);
        InitializeShareStep(false, false, true);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Fixed Asset for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"Fixed Asset",
                                                    DocumentType::Invoice);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 7);
    end;

    //TestCaseID-355073 Check if the system is calculating GST in case of Intra-state Purchase of Fixed Assets from SEZ Vendor where Input Tax Credit is available with multiple HSN code wise. through Purchase order
    //[FEATURE] [Fixed Assets Purchase Order] [invoice discount/line discount ITC,SEZ Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostGSTPurchaseOrderSEZVendorWithITCWithLineDiscountForFixedAsset()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::SEZ, GSTGroupType::Goods, false, false);
        InitializeShareStep(true, false, true);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Fixed Asset for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"Fixed Asset",
                                                    DocumentType::Order);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 6);
    end;

    //TestCaseID-355074 Check if the system is calculating GST in case of Intra-state Purchase of Fixed Assets from SEZ Vendor where Input Tax Credit is available with multiple HSN code wise through Purchase Invoice
    //[FEATURE] [Fixed Assets Purchase Invoice] [invoice discount/line discount ITC,SEZ Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostGSTPurchaseInvoiceSEZVendorWithITCWithLineDiscountForFixedAsset()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::SEZ, GSTGroupType::Goods, false, false);
        InitializeShareStep(true, false, true);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Fixed Asset for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseLine, LineType::"Fixed Asset", DocumentType::Invoice);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 6);
    end;

    //TestCaseID-355077 Check if the system is calculating GST in case of Intra-state Purchase of Fixed Assets from SEZ Vendor where Input Tax Credit is not available with multiple HSN code wise. through Purchase order
    //[FEATURE] [Fixed Assets Purchase Order] [invoice discount/line discount ITC,SEZ Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostGSTPurchaseOrderSEZVendorWithoutITCWithLineDiscountForFixedAsset()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::SEZ, GSTGroupType::Goods, false, false);
        InitializeShareStep(false, false, true);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Fixed Asset for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"Fixed Asset",
                                                    DocumentType::Order);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 7);
    end;

    //TestCaseID-355078 Check if the system is calculating GST in case of Intra-state Purchase of Fixed Assets from SEZ Vendor where Input Tax Credit is not available with multiple HSN code wise through Purchase Invoice
    //[FEATURE] [Fixed Assets Purchase Invoice] [invoice discount/line discount ITC,SEZ Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostGSTPurchaseInvoiceSEZVendorWithoutITCWithLineDiscountForFixedAsset()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::SEZ, GSTGroupType::Goods, false, false);
        InitializeShareStep(false, false, true);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Fixed Asset for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"Fixed Asset",
                                                    DocumentType::Invoice);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 7);
    end;

    //TestCaseID-354234 Check if the system is calculating GST in case of Purchase of Goods from SEZ Vendor where Input Tax Credit is available with cover of Bill of Entry though Purchase order
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromPurchaseOrderWithInputTaxCreditGSTVendorTypeSEZWithBillofEntry()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::SEZ, GSTGroupType::Goods, false, false);
        InitializeShareStep(true, false, false);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Fixed Asset for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::Item,
                                                    DocumentType::Order);
        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Order, DocumentNo, 4);
    end;

    //TestCaseID-354235 Check if the system is calculating GST in case of Purchase of Goods from SEZ Vendor where Input Tax Credit is not available with cover of Bill of Entry though Purchase order
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromPurchaseOrderWithoutInputTaxCreditGSTVendorTypeSEZWithBillofEntry()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::SEZ, GSTGroupType::Goods, false, false);
        InitializeShareStep(true, false, false);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Fixed Asset for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::Item,
                                                    DocumentType::Order);
        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Order, DocumentNo, 4);
    end;

    //TestCaseID-354269 Check if the system is calculating GST in case of Purchase of Services from SEZ Vendor where Input Tax Credit is not available with cover of Bill of Entry though Purchase order
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromPurchaseServiceOrderWithInputTaxCreditGSTVendorTypeSEZWithBillofEntry()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::SEZ, GSTGroupType::Service, false, false);
        InitializeShareStep(false, false, false);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Fixed Asset for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::Item,
                                                    DocumentType::Order);
        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Order, DocumentNo, 4);
    end;

    //Test Case-355058 Check if the system is calculating GST in case of Inter-State Purchase of Fixed Assets from SEZ Vendor where Input Tax Credit is available with invoice discount/line discount multiple HSN code wise through Purchase Order.
    [Test]

    [HandlerFunctions('TaxRatePageHandler')]
    procedure InterstatePurchaseOrderWithAvailmentThroughPurchaseOrderMultipleLineForSEZVendor()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::SEZ, GSTGroupType::Goods, false, false);
        InitializeShareStep(true, false, false);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Fixed Asset for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"Fixed Asset",
                                                    DocumentType::Order);
        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Order, DocumentNo, 4);
    end;

    //Test Case-355059 Check if the system is calculating GST in case of Inter-State Purchase of Fixed Assets from SEZ Vendor where Input Tax Credit is available with invoice discount/line discount multiple HSN code wise through Purchase Invoice.
    [Test]

    [HandlerFunctions('TaxRatePageHandler')]
    procedure InterstatePurchaseInvoiceWithAvailmentThroughPurchaseInvoiceMultipleLineForSEZVendor()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::SEZ, GSTGroupType::Goods, false, false);
        InitializeShareStep(true, false, false);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Fixed Asset for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"Fixed Asset",
                                                    DocumentType::Invoice);
        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Order, DocumentNo, 4);
    end;

    local procedure CreateGSTSetup(GSTVendorType: Enum "GST Vendor Type"; GSTGroupType: Enum "GST Group Type"; IntraState: Boolean; ReverseCharge: Boolean)
    var
        GSTGroup: Record "GST Group";
        HSNSAC: Record "HSN/SAC";
        GSTComponent: Record "Tax Component";
        CompanyInformation: Record "Company information";
        LocationStateCode: Code[10];
        VendorNo: Code[20];
        GSTGroupCode: Code[20];
        LocationCode: Code[10];
        HSNSACCode: Code[10];
        VendorStateCode: Code[10];
        LocPan: Code[20];
        LocationGSTRegNo: Code[15];
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

        // if IntraState then begin
        //     VendorNo := LibraryGST.CreateVendorSetup();
        //     if GSTVendorType <> GSTVendorType::Import then begin
        //         UpdateVendorSetupWithGST(VendorNo, GSTVendorType, false, LocationStateCode, LocPan);
        //         InitializeTaxRateParameters(IntraState, LocationStateCode, LocationStateCode);
        //     end else begin
        //         UpdateVendorSetupWithGST(VendorNo, GSTVendorType, false, '', LocPan);
        //         InitializeTaxRateParameters(IntraState, '', LocationStateCode);
        //     end;
        // end else begin
        //     VendorStateCode := LibraryGST.CreateGSTStateCode();
        //     VendorNo := LibraryGST.CreateVendorSetup();
        //     if GSTVendorType <> GSTVendorType::Import then
        //         UpdateVendorSetupWithGST(VendorNo, GSTVendorType, false, VendorStateCode, LocPan)
        //     else
        //         UpdateVendorSetupWithGST(VendorNo, GSTVendorType, false, '', LocPan);
        //     if GSTVendorType in [GSTVendorType::Import, GSTVendorType::SEZ] then
        //         InitializeTaxRateParameters(IntraState, '', LocationStateCode)
        //     else
        //         InitializeTaxRateParameters(IntraState, VendorStateCode, LocationStateCode);
        // end;
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
                CreateGSTComponentAndPostingSetup(IntraState, VendorStateCode, GSTComponent, GSTcomponentcode);
            end;
        end;
        //
        Storage.Set('VendorNo', VendorNo);

        CreateTaxRate(false);
        CreateGSTComponentAndPostingSetup(IntraState, LocationStateCode, GSTComponent, GSTcomponentcode);
    end;

    local procedure InitializeShareStep(InputCreditAvailment: Boolean; Exempted: Boolean; LineDiscount: Boolean)
    begin
        StorageBoolean.Set('InputCreditAvailment', InputCreditAvailment);
        StorageBoolean.Set('Exempted', Exempted);
        StorageBoolean.Set('LineDiscount', LineDiscount);
    end;

    procedure UpdateVendorSetupWithGST(VendorNo: Code[20];
                        GSTVendorType: Enum "GST Vendor Type";
                        AssociateEnterprise: boolean;
                        StateCode: Code[10];
                        Pan: Code[20]);
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
            vendor.Validate("Associated Enterprises", AssociateEnterprise);
        Vendor.Modify(true);
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseHeader: Record "Purchase Header";
                           var PurchaseLine: Record "Purchase Line";
                           LineType: Enum "Purchase Line Type";
                           DocumentType: Enum "Purchase Document Type"): Code[20];
    var
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        VendorNo: Code[20];
        LocationCode: Code[10];
        DocumentNo: Code[20];
        PurchaseInvoiceType: Enum "GST Invoice Type";
    begin
        Evaluate(VendorNo, Storage.Get('VendorNo'));
        Evaluate(LocationCode, Storage.Get('LocationCode'));
        CreatePurchaseHeaderWithGST(PurchaseHeader, VendorNo, DocumentType, LocationCode, PurchaseInvoiceType::" ");
        CreatePurchaseLineWithGST(PurchaseHeader, PurchaseLine, LineType, LibraryRandom.RandDecInRange(2, 10, 0), StorageBoolean.Get('InputCreditAvailment'), StorageBoolean.Get('Exempted'), StorageBoolean.Get('LineDiscount'));
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, TRUE, TRUE);
        exit(DocumentNo);
    end;

    local procedure CreatePurchaseHeaderWithGST(VAR PurchaseHeader: Record "Purchase Header";
                           VendorNo: Code[20];
                           DocumentType: Enum "Purchase Document Type";
                           LocationCode: Code[10];
                           PurchaseInvoiceType: Enum "GST Invoice Type")
    var
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        Overseas: Boolean;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Posting Date", WorkDate());
        PurchaseHeader.VALIDATE("Location Code", LocationCode);
        if Overseas then
            PurchaseHeader.Validate("POS Out Of India", true);
        if PurchaseInvoiceType in [PurchaseInvoiceType::"Debit Note", PurchaseInvoiceType::Supplementary] then
            PurchaseHeader.validate("Vendor Invoice No.", LibraryUtility.GenerateRandomCode(PurchaseHeader.fieldno("Vendor Invoice No."), Database::"Purchase Header"))
        else
            PurchaseHeader.validate("Vendor Cr. Memo No.", LibraryUtility.GenerateRandomCode(PurchaseHeader.fieldno("Vendor Cr. Memo No."), Database::"Purchase Header"));
        if PurchaseHeader."GST Vendor Type" = PurchaseHeader."GST Vendor Type"::SEZ then begin
            PurchaseHeader."Bill of Entry No." := LibraryUtility.GenerateRandomCode(PurchaseHeader.fieldno("Bill of Entry No."), Database::"Purchase Header");
            PurchaseHeader."Bill of Entry Date" := WorkDate();
            PurchaseHeader."Bill of Entry Value" := LibraryRandom.RandInt(1000);
        end;
        PurchaseHeader.MODIFY(TRUE);
    end;

    local procedure CreatePurchaseLineWithGST(VAR PurchaseHeader: Record "Purchase Header"; VAR PurchaseLine: Record "Purchase Line"; LineType: Enum "Purchase Line Type"; Quantity: Decimal; InputCreditAvailment: Boolean; Exempted: Boolean; LineDiscount: Boolean);
    var
        //GLAcc: Record "G/L Account";
        //Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPurchase: Codeunit "Library - Purchase";
        LineTypeNo: Code[20];
        LineNo: Integer;
        NoOfLine: Integer;
    begin
        Exempted := StorageBoolean.Get('Exempted');
        Evaluate(NoOfLine, Storage.Get('NoOfLine'));
        InputCreditAvailment := StorageBoolean.Get('InputCreditAvailment');
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
            if InputCreditAvailment then
                PurchaseLine."GST Credit" := PurchaseLine."GST Credit"::Availment
            else
                PurchaseLine."GST Credit" := PurchaseLine."GST Credit"::"Non-Availment";

            if LineDiscount then begin
                PurchaseLine.Validate("Line Discount %", LibraryRandom.RandDecInRange(10, 20, 2));
                LibraryGST.UpdateLineDiscAccInGeneralPostingSetup(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
            end;

            if (PurchaseHeader."GST Vendor Type" in [PurchaseHeader."GST Vendor Type"::Import, PurchaseHeader."GST Vendor Type"::SEZ]) and
                        (not (PurchaseLine.Type in [PurchaseLine.Type::" ", PurchaseLine.Type::"Charge (Item)"])) then begin
                PurchaseLine.Validate("GST Assessable Value", LibraryRandom.RandInt(1000));
                if PurchaseLine.Type In [PurchaseLine.Type::Item, PurchaseLine.Type::"G/L Account"] then
                    PurchaseLine.Validate("Custom Duty Amount", LibraryRandom.RandInt(1000));
            end;
            PurchaseLine.VALIDATE("Direct Unit Cost", LibraryRandom.RandInt(1000));
            PurchaseLine.MODIFY(TRUE);
        end;
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

    Local procedure InitializeTaxRateParameters(IntraState: Boolean; FromState: Code[10]; ToState: Code[10])
    var
        LibraryRandom: Codeunit "Library - Random";
        GSTTaxPercent: Decimal;
    begin
        Storage.Set('FromStateCode', FromState);
        Storage.Set('ToStateCode', ToState);
        GSTTaxPercent := LibraryRandom.RandDecInRange(10, 18, 0);
        if IntraState then begin
            ComponentPerArray[1] := (GSTTaxPercent / 2);
            ComponentPerArray[2] := (GSTTaxPercent / 2);
            ComponentPerArray[3] := 0;
        end else
            ComponentPerArray[4] := GSTTaxPercent;
    end;

    procedure CreateTaxRate(POS: boolean)
    var
        TaxTypeSetup: Record "Tax Type Setup";
        PageTaxtype: TestPage "Tax Types";
    begin
        TaxTypeSetup.Get();
        PageTaxtype.OpenEdit();
        PageTaxtype.Filter.SetFilter(Code, TaxTypeSetup.Code);
        PageTaxtype.TaxRates.Invoke();
    end;

    [PageHandler]
    procedure TaxRatePageHandler(var TaxRate: TestPage "Tax Rates")
    begin
        TaxRate.AttributeValue1.SetValue(Storage.Get('HSNSACCode'));
        TaxRate.AttributeValue2.SetValue(Storage.Get('GSTGroupCode'));
        TaxRate.AttributeValue3.SetValue(Storage.Get('FromStateCode'));
        TaxRate.AttributeValue4.SetValue(Storage.Get('ToStateCode'));
        TaxRate.AttributeValue5.SetValue(WorkDate());
        TaxRate.AttributeValue6.SetValue(CALCDATE('<10Y>', WorkDate()));
        TaxRate.AttributeValue7.SetValue(componentPerArray[1]);
        TaxRate.AttributeValue8.SetValue(componentPerArray[2]);
        TaxRate.AttributeValue9.SetValue(componentPerArray[4]);
        TaxRate.AttributeValue10.SetValue(componentPerArray[3]);
        TaxRate.AttributeValue11.SetValue(componentPerArray[5]);
        TaxRate.AttributeValue12.SetValue(componentPerArray[6]);
        TaxRate.AttributeValue13.SetValue('');
        TaxRate.AttributeValue14.SetValue('');
        TaxRate.OK().Invoke();
    end;

    var
        LibraryGST: Codeunit "Library GST";
        Storage: Dictionary of [Text, Text];
        ComponentPerArray: array[20] of Decimal;
        StorageBoolean: Dictionary of [Text, Boolean];
}
