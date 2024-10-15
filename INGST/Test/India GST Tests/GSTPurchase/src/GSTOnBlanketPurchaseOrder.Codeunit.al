codeunit 18131 "GST On Blanket Purchase Order"
{
    Subtype = Test;

    var
        LibraryGST: Codeunit "Library GST";
        ComponentPerArray: array[20] of Decimal;
        Storage: Dictionary of [Text, Text[20]];
        StorageBoolean: Dictionary of [Text, Boolean];

    //[Scenario 354691] Check if the system is handling tax value calculation of GST in case of intrastate purchase of goods through Blanket purchase order for registered vendor
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure CreatePurchaseOrderFromBlanketOrderForRegisteredWithGoodsIntraState()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        DocumentType: Enum "Purchase Document Type";
        LineType: Enum "Sales Line Type";
        PONo: Code[20];
    begin
        // [GIVEN] Create GST Setup
        InitializeShareStep(true, false, false);
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, true, false);

        // [WHEN] Create Blanket Purchase Order
        Storage.Set('NoOfLine', Format((1)));
        PONo := CreatePOFromBlanketOrder(
            PurchaseHeader,
            PurchaseLine,
            LineType::Item,
            DocumentType::"Blanket Order");

        // [THEN] Verify GST ledger entries
        LibraryGST.VerifyTaxTransactionForPurchase(PONo, DocumentType::Order);
    end;

    //[Scenario 354695] Check if the system is handling tax value calculation of GST in case of Interstate purchase of goods through Blanket purchase order for registered vendor
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure CreatePurchaseOrderFromBlanketOrderForRegisteredWithGoodsInterState()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        DocumentType: Enum "Purchase Document Type";
        LineType: Enum "Sales Line Type";
        PONo: Code[20];
    begin
        // [GIVEN] Create GST Setup
        InitializeShareStep(true, false, false);
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, false, false);

        // [WHEN] Create Blanket Purchase Order
        Storage.Set('NoOfLine', Format((1)));
        PONo := CreatePOFromBlanketOrder(
            PurchaseHeader,
            PurchaseLine,
            LineType::Item,
            DocumentType::"Blanket Order");

        // [THEN] Verify GST ledger entries
        LibraryGST.VerifyTaxTransactionForPurchase(PONo, PurchaseLine."Document Type"::Order);
    end;

    //[Scenario 355319] Check if the system is handling tax value calculation of GST in case of intrastate purchase of goods with Services through Blanket purchase order for Import vendor
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure CreatePurchaseOrderFromBlanketOrderForImportWithGoodsInterState()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        DocumentType: Enum "Purchase Document Type";
        LineType: Enum "Sales Line Type";
        PONo: Code[20];
    begin
        // [GIVEN] Create GST Setup
        InitializeShareStep(true, false, false);
        CreateGSTSetup(GSTVendorType::Import, GSTGroupType::Service, false, false);

        // [WHEN] Create Blanket Purchase Order
        Storage.Set('NoOfLine', Format((1)));
        PONo := CreatePOFromBlanketOrder(
                     PurchaseHeader,
                     PurchaseLine,
                     LineType::"G/L Account",
                     DocumentType::"Blanket Order");

        // [THEN] Verify GST ledger entries
        LibraryGST.VerifyTaxTransactionForPurchase(PONo, DocumentType::Order)
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
        GSTGroupCode: Code[20];
        HSNSACCode: Code[10];
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

        if IntraState then begin
            VendorNo := LibraryGST.CreateVendorSetup();
            if GSTVendorType <> GSTVendorType::Import then begin
                UpdateVendorSetupWithGST(VendorNo, GSTVendorType, false, LocationStateCode, LocPan);
                InitializeTaxRateParameters(IntraState, LocationStateCode, LocationStateCode);
            end else begin
                UpdateVendorSetupWithGST(VendorNo, GSTVendorType, true, '', LocPan);
                InitializeTaxRateParameters(IntraState, '', LocationStateCode);
            end;
        end else begin
            VendorStateCode := LibraryGST.CreateGSTStateCode();
            VendorNo := LibraryGST.CreateVendorSetup();
            if GSTVendorType <> GSTVendorType::Import then
                UpdateVendorSetupWithGST(VendorNo, GSTVendorType, false, VendorStateCode, LocPan)
            else
                UpdateVendorSetupWithGST(VendorNo, GSTVendorType, true, '', LocPan);
            if GSTVendorType in [GSTVendorType::Import, GSTVendorType::SEZ] then
                InitializeTaxRateParameters(IntraState, '', LocationStateCode)
            else
                InitializeTaxRateParameters(IntraState, VendorStateCode, LocationStateCode);
        end;
        Storage.Set('VendorNo', VendorNo);

        CreateTaxRate(false);
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

    local procedure InitializeShareStep(InputCreditAvailment: Boolean; Exempted: Boolean; LineDiscount: Boolean)
    begin
        StorageBoolean.Set('InputCreditAvailment', InputCreditAvailment);
        StorageBoolean.Set('Exempted', Exempted);
        StorageBoolean.Set('LineDiscount', LineDiscount);
    end;

    local procedure InitializeTaxRateParameters(IntraState: Boolean; FromState: Code[10]; ToState: Code[10])
    begin
        Storage.Set('FromStateCode', FromState);
        Storage.Set('ToStateCode', ToState);
        IF IntraState then begin
            componentPerArray[1] := 9;
            componentPerArray[2] := 9;
            componentPerArray[3] := 0;
        end else
            componentPerArray[4] := 18;
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
    procedure TaxRatePageHandler(var TaxRate: TestPage "Tax Rates")
    begin
        TaxRate.AttributeValue1.SetValue(Storage.Get('HSNSACCode'));
        TaxRate.AttributeValue2.SetValue(Storage.Get('GSTGroupCode'));
        TaxRate.AttributeValue3.SetValue(Storage.get('FromStateCode'));
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

    procedure UpdateVendorSetupWithGST(VendorNo: Code[20]; GSTVendorType: Enum "GST Vendor Type"; AssociateEnterprise: boolean;
                                                                          StateCode1: Code[10];
                                                                          Pan: Code[20]);
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
        if Vendor."GST Vendor Type" = vendor."GST Vendor Type"::Import then begin
            vendor.Validate("Associated Enterprises", AssociateEnterprise);
            Vendor.Validate("Currency Code", LibraryGST.CreateCurrencyCode());
        end;
        Vendor.Modify(true);
    end;

    local procedure CreatePOFromBlanketOrder(VAR PurchaseHeader: Record "Purchase Header";
                                          VAR PurchaseLine: Record "Purchase Line";
                                          LineType: Enum "Purchase Line Type";
                                          DocumentType: Enum "Purchase Document Type"): Code[20]
    var
        PurchOrderHeader: Record "Purchase Header";
        LibraryRandom: Codeunit "Library - Random";
        BlanketPurchOrderToOrder: Codeunit "Blanket Purch. Order to Order";
        VendorNo: Code[20];
        LocationCode: Code[10];
        PurchaseInvoiceType: Enum "GST Invoice Type";
    begin
        VendorNo := Storage.Get('VendorNo');
        evaluate(LocationCode, Storage.Get('LocationCode'));
        CreatePurchaseHeaderWithGST(PurchaseHeader, VendorNo, DocumentType, LocationCode, PurchaseInvoiceType::" ");
        CreatePurchaseLineWithGST(PurchaseHeader, PurchaseLine, LineType, LibraryRandom.RandDecInRange(2, 10, 0), StorageBoolean.Get('InputCreditAvailment'), StorageBoolean.Get('Exempted'), StorageBoolean.Get('LineDiscount'));
        BlanketPurchOrderToOrder.Run(PurchaseHeader);
        BlanketPurchOrderToOrder.GetPurchOrderHeader(PurchOrderHeader);
        exit(PurchOrderHeader."No.");
    end;

    local procedure CreatePurchaseHeaderWithGST(VAR PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; DocumentType: Enum "Purchase Document Type"; LocationCode: Code[10];
                                                                                                                                    PurchaseInvoiceType: Enum "GST Invoice Type")
    var
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        BillofEntry: Boolean;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Posting Date", WorkDate());
        PurchaseHeader.VALIDATE("Location Code", LocationCode);
        if PurchaseInvoiceType in [PurchaseInvoiceType::"Debit Note", PurchaseInvoiceType::Supplementary] then
            PurchaseHeader.validate("Vendor Invoice No.", LibraryUtility.GenerateRandomCode(PurchaseHeader.fieldno("Vendor Invoice No."), Database::"Purchase Header"))
        else
            PurchaseHeader.validate("Vendor Cr. Memo No.", LibraryUtility.GenerateRandomCode(PurchaseHeader.fieldno("Vendor Cr. Memo No."), Database::"Purchase Header"));
        if BillofEntry and (PurchaseHeader."GST Vendor Type" = PurchaseHeader."GST Vendor Type"::SEZ) then begin
            PurchaseHeader."Bill of Entry No." := LibraryUtility.GenerateRandomCode(PurchaseHeader.fieldno("Bill of Entry No."), Database::"Purchase Header");
            PurchaseHeader."Bill of Entry Date" := WorkDate();
            PurchaseHeader."Bill of Entry Value" := 1001;
        end;
        PurchaseHeader.MODIFY(TRUE);
    end;

    local procedure CreatePurchaseLineWithGST(VAR PurchaseHeader: Record "Purchase Header"; VAR PurchaseLine: Record "Purchase Line"; LineType: Enum "Purchase Line Type"; Quantity: Decimal;
                                                                                                                                                    InputCreditAvailment: Boolean;
                                                                                                                                                    Exempted: Boolean;
                                                                                                                                                    LineDiscount: Boolean);
    var
        VATPostingSetup: Record "VAT Posting Setup";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LineTypeNo: Code[20];
        LineNo: Integer;
        NoOfLine: Integer;
    begin
        if Storage.ContainsKey('NoOfLine') then
            Evaluate(NoOfLine, Storage.Get('NoOfLine'));
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
            if (PurchaseHeader."GST Vendor Type" in [PurchaseHeader."GST Vendor Type"::Import, PurchaseHeader."GST Vendor Type"::SEZ]) and (PurchaseLine.Type = PurchaseLine.Type::Item) then begin
                PurchaseLine.Validate("GST Assessable Value", PurchaseLine."Line Amount");
                PurchaseLine.Validate("Custom Duty Amount", PurchaseLine."Line Amount");
            end;
            PurchaseLine.VALIDATE("Direct Unit Cost", LibraryRandom.RandInt(1000));
            PurchaseLine.MODIFY(TRUE);
        end;
    end;
}