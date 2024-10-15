codeunit 18792 "TDS On Purchase Order"
{
    Subtype = Test;
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    //Scenario 353920- Check if the program is allowing the posting of Invoice with Item using the Purchase Order/Invoice with TDS information where T.A.N No. has not been defined.
    procedure PostFromPurchaseOrderwithItemWithoutTANNo()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithOutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        //[WHEN] Create and Post Purchase Order with Item
        LibraryTDS.RemoveTANOnCompInfo();
        asserterror CreateAndPostPurchaseDocument(PurchaseHeader,
              PurchaseHeader."Document Type"::Order,
              Vendor."No.",
              WorkDate(),
              PurchaseLine.Type::Item, false);

        // [THEN] Assert Error Verified
        Assert.ExpectedError(TANNoErr);
    end;

    [Test]

    [HandlerFunctions('TaxRatePageHandler')]
    //Scenario 353919- Check if the program is allowing the posting of Invoice with Item using the Purchase Order/Invoice with TDS information where Accounting Period has not been specified.
    procedure PostFromPurchaseOrderwithItemWithoutAccountingPeriod()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithOutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        //[WHEN] Created and Posted Purchase Order with G/L Account
        asserterror CreateAndPostPurchaseDocument(PurchaseHeader,
             PurchaseHeader."Document Type"::Order,
             Vendor."No.",
             CalcDate('<-1Y>', LibraryTDS.FindStartDateOnAccountingPeriod()),
             PurchaseLine.Type::Item,
             false);

        //[THEN] Assert Error Verified
        Assert.ExpectedError(IncomeTaxAccountingErr);
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    //Scenario 353754- Check if the program is calculating TDS in case an invoice is raised to the Vendor using Purchase Order.
    //Scenario 353923-Check if the program is calculating TDS on Lower rate/zero rate in case an invoice is raised to the Vendor is having a certificate using Purchase Order with Item & Fixed Assets
    procedure PostFromPurchaseOrderWithItemWithPANWithConCode()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", ConcessionalCode.Code, WorkDate());

        //[WHEN] Craeted and Post Purchase Order with Item
        DocumentNo := CreateAndPostPurchaseDocument(
              PurchaseHeader,
              PurchaseHeader."Document Type"::Order,
              Vendor."No.",
              WorkDate(),
              PurchaseLine.Type::Item,
              false);

        //[THEN] G/L Entries and TDS Entries Verified
        LibraryTDS.VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        VerifyTDSEntry(DocumentNo, true, true, true);
    end;

    [Test]

    [HandlerFunctions('TaxRatePageHandler')]
    //Scenario 353995- Check if the program is calculating TDS while creating Invoice with Item using the Purchase Order/Invoice in case of different rates for same NOD with different effective dates.    
    procedure PostFromPurchaseOrderWithItemWithPANWithoutConCodeWithDifferentEffectiveDates()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode without Threshold and Surcharge Overllok.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithoutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', CalcDate('<1M>', WorkDate()));
        LibraryTDS.CreateTDSPostingSetupWithDifferentEffectiveDate(TDSPostingSetup."TDS Section", CalcDate('<1M>', WorkDate()), TDSPostingSetup."TDS Account");

        //[WHEN] Created and Posted Purchase Order with Item 
        CreatePurchaseDocument(PurchaseHeader,
               PurchaseHeader."Document Type"::Order,
               Vendor."No.",
               CalcDate('<1M>', WorkDate()),
               PurchaseLine.Type::Item,
               false);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        //[THEN] G/L Entries and TDS Entries Verified
        LibraryTDS.VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        VerifyTDSEntry(DocumentNo, true, true, true);
    end;

    [Test]

    [HandlerFunctions('TaxRatePageHandler')]
    //Scenario 353994- Check if the program is calculating TDS while creating Invoice with G/L Account using the Purchase Order/Invoice in case of different rates for same NOD with different effective dates.    
    procedure PostFromPurchaseOrderWithGLAccountWithPANWithoutConCodeWithDifferentEffectiveDates()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode without Threshold and Surcharge Overllok.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithoutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', CalcDate('<1M>', WorkDate()));
        LibraryTDS.CreateTDSPostingSetupWithDifferentEffectiveDate(TDSPostingSetup."TDS Section", CalcDate('<1M>', WorkDate()), TDSPostingSetup."TDS Account");

        //[WHEN] Created and Posted Purchase Order with G/L Account
        CreatePurchaseDocument(PurchaseHeader,
               PurchaseHeader."Document Type"::Order,
               Vendor."No.",
               CalcDate('<1M>', WorkDate()),
               PurchaseLine.Type::"G/L Account",
               false);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        //[THEN] G/L Entries and TDS Entries Verified
        LibraryTDS.VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        VerifyTDSEntry(DocumentNo, true, true, true);
    end;

    [Test]

    [HandlerFunctions('TaxRatePageHandler')]
    //Scenario 353996- Check if the program is calculating TDS while creating Invoice with Fixed Asset using the Purchase Order/Invoice in case of different rates for same NOD with different effective dates.    
    procedure PostFromPurchaseOrderWithFixedAssetWithPANWithoutConCodeWithDifferentEffectiveDates()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode without Threshold and Surcharge Overllok.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithoutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', CalcDate('<1M>', WorkDate()));
        LibraryTDS.CreateTDSPostingSetupWithDifferentEffectiveDate(TDSPostingSetup."TDS Section", CalcDate('<1M>', WorkDate()), TDSPostingSetup."TDS Account");

        //[WHEN] Created and Posted Purchase Order with Fixed Asset
        CreatePurchaseDocument(PurchaseHeader,
               PurchaseHeader."Document Type"::Order,
               Vendor."No.",
               CalcDate('<1M>', WorkDate()),
               PurchaseLine.Type::"Fixed Asset",
               false);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        //[THEN] G/L Entries and TDS Entries Verified
        LibraryTDS.VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        VerifyTDSEntry(DocumentNo, true, true, true);
    end;

    [Test]

    [HandlerFunctions('TaxRatePageHandler')]
    //Scenario 353997- Check if the program is calculating TDS while creating Invoice with Charge(Item) using the Purchase Order/Invoice in case of different rates for same NOD with different effective dates.    
    procedure PostFromPurchaseOrderWithChargeItemWithPANWithoutConCodeWithDifferentEffectiveDates()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode without Threshold and Surcharge Overllok.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", ConcessionalCode.Code, WorkDate());
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", ConcessionalCode.Code, CalcDate('<1M>', WorkDate()));
        LibraryTDS.CreateTDSPostingSetupWithDifferentEffectiveDate(TDSPostingSetup."TDS Section", CalcDate('<1M>', WorkDate()), TDSPostingSetup."TDS Account");

        // [WHEN] Create and and Post Purchase Invoice
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, Purchaseline.Type::"Charge (Item)", false);
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Expected Error: Charge Item not Assigned
        Assert.ExpectedError(StrSubstNo(ChargeItemErr, PurchaseLine."No."));
    end;

    [Test]

    [HandlerFunctions('TaxRatePageHandler')]
    //Scenario 353995- Check if the program is calculating TDS while creating Invoice with Item using the Purchase Order/Invoice in case of different rates for same NOD with different effective dates.
    procedure PostFromPurchaseOrderWithItemWithPANWithConCodeWithDifferentEffectiveDates()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode without Threshold and Surcharge Overllok.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", ConcessionalCode.Code, WorkDate());

        //[WHEN] Craeted and Posted Purchase Order
        DocumentNo := CreateAndPostPurchaseDocument(
                         PurchaseHeader,
                         PurchaseHeader."Document Type"::Order,
                         Vendor."No.",
                         WorkDate(),
                         PurchaseLine.Type::Item,
                         false);

        //[THEN] //[THEN] G/L Entries and TDS Entries Verified
        LibraryTDS.VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    //Scenario 353754- Check if the program is calculating TDS in case an invoice is raised to the Vendor using Purchase Order.
    procedure PostFromPurchaseOrderwithGLAccountWithPANWithoutConCode()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode without Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithoutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        //[THEN] Created and Posted purchase Order
        DocumentNo := CreateAndPostPurchaseDocument(
                          PurchaseHeader,
                          PurchaseHeader."Document Type"::Order,
                          Vendor."No.",
                          WorkDate(),
                          PurchaseLine.Type::"G/L Account", false);

        //[THEN] //[THEN] G/L Entries and TDS Entries Verified
        LibraryTDS.VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        VerifyTDSEntry(DocumentNo, true, true, true);
    end;

    [Test]

    [HandlerFunctions('TaxRatePageHandler')]
    //Scenario 353964- Check if the program is calculating TDS in case an invoice is raised to the foreign Vendor using Purchase Order/Invoice and Threshold and Surcharge Overlook is selected with G/L Account.
    procedure PostFromPurchaseOrderofForeignVendorwithGLAccountWithPANWithoutConCode()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithoutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        //[WHEN] Created and Posted Purchase Order
        DocumentNo := CreateAndPostPurchaseDocument(
                         PurchaseHeader,
                         PurchaseHeader."Document Type"::Order,
                         Vendor."No.",
                         WorkDate(),
                         PurchaseLine.Type::"G/L Account", false);

        //[THEN] //[THEN] G/L Entries and TDS Entries Verified
        LibraryTDS.VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        VerifyTDSEntry(DocumentNo, true, true, true);
    end;

    [Test]

    [HandlerFunctions('TaxRatePageHandler')]
    //Scenario 353962- Check if the program is calculating TDS in case an invoice is raised to the foreign Vendor using Purchase Order/Invoice and Threshold and Surcharge Overlook is selected with Item.
    procedure PostFromPurchaseOrderofForeignVendorWithItemIncludingSurchargeandThresholdOverlook()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithoutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        //[WHEN] Created and Posted Purchase Order.
        DocumentNo := CreateAndPostPurchaseDocument(
                         PurchaseHeader,
                         PurchaseHeader."Document Type"::Order,
                         Vendor."No.",
                         WorkDate(),
                         PurchaseLine.Type::Item, false);

        //[THEN] //[THEN] G/L Entries and TDS Entries Verified.
        LibraryTDS.VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        VerifyTDSEntry(DocumentNo, true, true, true);
    end;

    [Test]

    [HandlerFunctions('TaxRatePageHandler')]
    //Scenario 353965- Check if the program is calculating TDS in case an invoice is raised to the foreign Vendor using Purchase Order/Invoice and Threshold and Surcharge Overlook is not selected with G/L Account.
    procedure PostFromPurchaseOrderWithGLAccountWithoutThresholdandSurchargeOverlook()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithoutConcessional(Vendor, false, false);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        //[WHEN] Created and Posted Purchase Order.
        DocumentNo := CreateAndPostPurchaseDocument(
                        PurchaseHeader,
                        PurchaseHeader."Document Type"::Order,
                        Vendor."No.",
                        WorkDate(),
                        PurchaseLine.Type::"G/L Account", false);

        //[THEN] //[THEN] G/L Entries and TDS Entries Verified.
        LibraryTDS.VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        VerifyTDSEntry(DocumentNo, true, false, false);
    end;

    [Test]

    [HandlerFunctions('TaxRatePageHandler')]
    //Scenario 353911-Check if the program is calculating TDS on higher rate in case an invoice is raised to the Vendor which is not having PAN No. using Purchase Order with G/L Account.
    procedure PostFromPurchaseOrderwithGLAccountWithoutPANWithoutConCode()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithoutPANWithoutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        //[WHEN] Created and Posted Purchase Order.
        DocumentNo := CreateAndPostPurchaseDocument(
                         PurchaseHeader,
                         PurchaseHeader."Document Type"::Order,
                         Vendor."No.",
                         WorkDate(),
                         PurchaseLine.Type::"G/L Account", false);

        //[THEN] //[THEN] G/L Entries and TDS Entries Verified.
        LibraryTDS.VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        VerifyTDSEntry(DocumentNo, false, true, true);
    end;

    [Test]

    [HandlerFunctions('TaxRatePageHandler')]
    //Scenario 353911- Check if the program is calculating TDS on higher rate in case an invoice is raised to the Vendor which is not having PAN No. using Purchase Order with G/L Account
    //Scenario 353912- Check if the program is calculating TDS on Lower rate/zero rate in case an invoice is raised to the Vendor is having a certificate using Purchase Order with G/L Account.
    procedure PostFromPurchaseOrderwithGLAccountWithoutPANWithConCode()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithoutPANWithConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", ConcessionalCode.Code, WorkDate());

        //[WHEN] Created and Posted Purchase Order
        DocumentNo := CreateAndPostPurchaseDocument(
                        PurchaseHeader,
                        PurchaseHeader."Document Type"::Order,
                        Vendor."No.",
                        WorkDate(),
                        PurchaseLine.Type::"G/L Account", false);

        //[THEN] //[THEN] G/L Entries and TDS Entries Verified
        LibraryTDS.VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        VerifyTDSEntry(DocumentNo, false, true, true);
    end;

    [Test]

    [HandlerFunctions('TaxRatePageHandler')]
    //Scenario 353912-Check if the program is calculating TDS on Lower rate/zero rate in case an invoice is raised to the Vendor is having a certificate using Purchase Order with G/L Account.
    procedure PostFromPurchaseOrderwithGLAccountWithPANWithConCode()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", ConcessionalCode.Code, WorkDate());

        //[WHEN] Created and Posted Purchase Order.
        DocumentNo := CreateAndPostPurchaseDocument(
                        PurchaseHeader,
                        PurchaseHeader."Document Type"::Order,
                        Vendor."No.",
                        WorkDate(),
                        PurchaseLine.Type::"G/L Account", false);

        //[THEN] G/L Entries and TDS Entries Verified
        LibraryTDS.VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        VerifyTDSEntry(DocumentNo, true, true, true);
    end;

    [Test]

    [HandlerFunctions('TaxRatePageHandler')]
    //Scenario 353902- Check if the program is allowing the posting of Invoice with G/L Account using the Purchase Order/Invoice with TDS information where T.A.N No. has not been defined.
    procedure PostFromPurchaseOrderwithGLAccountWithoutTANNo()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithoutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        //[WHEN] Validated T.A.N. No. Verified
        LibraryTDS.RemoveTANOnCompInfo();

        //[THEN] Assert Error Verified
        asserterror CreateAndPostPurchaseDocument(PurchaseHeader,
                            PurchaseHeader."Document Type"::Order,
                            Vendor."No.",
                            WorkDate(),
                            PurchaseLine.Type::"G/L Account", false);
        Assert.ExpectedError(TANNoErr);
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    //Scenario 353901- Check if the program is allowing the posting of Invoice with G/L Account using the Purchase Order/Invoice with TDS information where Accounting Period has not been specified.
    procedure PostFromPurchaseOrderwithGLAccountWithoutAccountingPeriod()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithoutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        //[WHEN] Created and posted Purchase Invoice with G/L Account
        asserterror CreateAndPostPurchaseDocument(PurchaseHeader,
                            PurchaseHeader."Document Type"::Order,
                            Vendor."No.",
                            CalcDate('<-1Y>', LibraryTDS.FindStartDateOnAccountingPeriod()),
                            PurchaseLine.Type::"G/L Account",
                            false);

        //[WHEN] Assert Error Verified
        Assert.ExpectedError(IncomeTaxAccountingErr);
    end;

    [Test]

    [HandlerFunctions('TaxRatePageHandler')]
    //Scenario 353796- Check if the program is calculating TDS in case an invoice is raised to the Vendor using Purchase Order with Item.
    procedure PostFromPurchaseOrderwithItemWithPANWithoutConCode()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithoutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        //[WHEN] Created and Posted Purchase Order.
        DocumentNo := CreateAndPostPurchaseDocument(
                         PurchaseHeader,
                         PurchaseHeader."Document Type"::Order,
                         Vendor."No.",
                         WorkDate(),
                         PurchaseLine.Type::Item, false);

        //[THEN] //[THEN] G/L Entries and TDS Entries Verified
        LibraryTDS.VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        VerifyTDSEntry(DocumentNo, true, true, true);
    end;

    [Test]

    [HandlerFunctions('TaxRatePageHandler')]
    //Scenario 353793- Check if the program is calculating TDS in case an invoice is raised to the Vendor using Purchase Order with Fixed Assets.
    procedure PostFromPurchaseOrderwithFixedAssetWithPANWithoutConCode()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithoutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        //[WHEN] Created and Posted Purchase Order
        DocumentNo := CreateAndPostPurchaseDocument(
                         PurchaseHeader,
                         PurchaseHeader."Document Type"::Order,
                         Vendor."No.",
                         WorkDate(),
                         PurchaseLine.Type::"Fixed Asset", false);

        //[THEN] //[THEN] G/L Entries and TDS Entries Verified
        LibraryTDS.VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        VerifyTDSEntry(DocumentNo, true, true, true);
    end;

    [Test]

    [HandlerFunctions('TaxRatePageHandler')]
    //Scenario 353931- Check if the program is calculating TDS on higher rate in case an invoice with Fixed Asset is raised to the Vendor which is not having PAN No. using Purchase Order.
    procedure PostFromPurchaseOrderwithFixedAssetithoutPANWithoutConCode()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithoutPANWithoutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        //[WHEN] Created and Posted Purchase Order
        DocumentNo := CreateAndPostPurchaseDocument(
                         PurchaseHeader,
                         PurchaseHeader."Document Type"::Order,
                         Vendor."No.",
                         WorkDate(),
                         PurchaseLine.Type::"Fixed Asset", false);

        //[THEN] //[THEN] G/L Entries and TDS Entries Verified
        LibraryTDS.VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        VerifyTDSEntry(DocumentNo, false, true, true);
    end;

    [Test]

    [HandlerFunctions('TaxRatePageHandler')]
    //Scenario 353931- Check if the program is calculating TDS on higher rate in case an invoice with Fixed Asset is raised to the Vendor which is not having PAN No. using Purchase Order.
    procedure PostFromPurchaseOrderwithFixedAssetWithoutPANWithConCode()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithoutPANWithConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", ConcessionalCode.Code, WorkDate());

        //[WHEN] Created and Posted Purchase
        DocumentNo := CreateAndPostPurchaseDocument(
                         PurchaseHeader,
                         PurchaseHeader."Document Type"::Order,
                         Vendor."No.",
                         WorkDate(),
                         PurchaseLine.Type::"Fixed Asset", false);

        //[THEN] //[THEN] G/L Entries and TDS Entries Verified
        LibraryTDS.VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        VerifyTDSEntry(DocumentNo, false, true, true);
    end;

    [Test]

    [HandlerFunctions('TaxRatePageHandler')]
    //Scenario 353923- Check if the program is calculating TDS on Lower rate/zero rate in case an invoice is raised to the Vendor is having a certificate using Purchase Order with Item & Fixed Assets.
    procedure PostFromPurchaseOrderwithFixedAssetWithPANWithConCode()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", ConcessionalCode.Code, WorkDate());

        //[WHEN]Created and Posted Purchase Order
        DocumentNo := CreateAndPostPurchaseDocument(
                        PurchaseHeader,
                        PurchaseHeader."Document Type"::Order,
                        Vendor."No.",
                        WorkDate(),
                        PurchaseLine.Type::"Fixed Asset", false);

        //[THEN] //[THEN] G/L Entries and TDS Entries Verified
        LibraryTDS.VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        VerifyTDSEntry(DocumentNo, true, true, true);
    end;

    [Test]

    [HandlerFunctions('TaxRatePageHandler')]
    //Scenario 353928- Check if the program is allowing the posting of Invoice with Fixed Assets using the Purchase Order/Invoice with TDS information where T.A.N No. has not been defined.
    procedure PostFromPurchaseOrderwithFixedAssetWithoutTANNo()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithoutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", ConcessionalCode.Code, WorkDate());

        //[WHEN] Validated T.A.N. No. Verified
        LibraryTDS.RemoveTANOnCompInfo();

        //[THEN] Assert Error Verified
        asserterror CreateAndPostPurchaseDocument(PurchaseHeader,
            PurchaseHeader."Document Type"::Order,
            Vendor."No.",
            WorkDate(),
            PurchaseLine.Type::"Fixed Asset", false);
        Assert.ExpectedError(TANNoErr);
    end;

    [Test]

    [HandlerFunctions('TaxRatePageHandler')]
    //Scenario 353927- Check if the program is allowing the posting of Invoice with Fixed Assets using the Purchase Order/Invoice with TDS information where Accounting Period has not been specified.
    procedure PostFromPurchaseOrderwithFixedAssetWithoutAccountingPeriod()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithoutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", ConcessionalCode.Code, WorkDate());

        //[WHEN] Created and posted Purchase Invoice with G/L Account
        asserterror CreateAndPostPurchaseDocument(PurchaseHeader,
             PurchaseHeader."Document Type"::Order,
             Vendor."No.",
             CalcDate('<-1Y>', LibraryTDS.FindStartDateOnAccountingPeriod()),
             PurchaseLine.Type::"Fixed Asset",
             false);

        //[WHEN] Assert Error Verified
        Assert.ExpectedError(IncomeTaxAccountingErr);
    end;

    [Test]

    [HandlerFunctions('TaxRatePageHandler')]
    //Scenario 353922- Check if the program is calculating TDS on higher rate in case an invoice is raised to the Vendor which is not having PAN No. using Purchase Order with Item.
    procedure PostFromPurchaseOrderwithItemWithoutPANWithoutConCode()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithoutPANWithoutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        //[WHEN] Created and Posted Purchase Order
        DocumentNo := CreateAndPostPurchaseDocument(
                         PurchaseHeader,
                         PurchaseHeader."Document Type"::Order,
                         Vendor."No.",
                         WorkDate(),
                         PurchaseLine.Type::Item, false);

        //[THEN]//[THEN] G/L Entries and TDS Entries Verified
        LibraryTDS.VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        VerifyTDSEntry(DocumentNo, false, true, true);
    end;

    [Test]

    [HandlerFunctions('TaxRatePageHandler')]
    //Scenario 353938- Check if the program is calculating TDS on higher rate in case an invoice is raised to the Vendor which is not having PAN No. using Purchase Order with Charge (Item)
    procedure PostFromPurchaseOrderwithChargeItemWithoutPANWithConCode()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        // [GIVEN] Created Setup for Section, Assessee Code, Vendor, TDS Setup, Tax Accounting Period and TDS Rates.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithoutPANWithConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", ConcessionalCode.Code, WorkDate());

        // [WHEN] Create and and Post Purchase Order with Charge Item
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, Purchaseline.Type::"Charge (Item)", false);
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Expected Error: Charge Item not Assigned
        Assert.ExpectedError(StrSubstNo(ChargeItemErr, PurchaseLine."No."));
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    //Scenario 353939- Check if the program is calculating TDS on Lower rate/zero rate in case an invoice is raised to the Vendor is having a certificate using Purchase Order/Invoice with Charge (Item).
    procedure PostFromPurchaseOrderwithChargeItemWithPANWithConCode()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        // [GIVEN] Created Setup for Section, Assessee Code, Vendor, TDS Setup, Tax Accounting Period and TDS Rates.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", ConcessionalCode.Code, WorkDate());

        // [WHEN] Create and and Post Purchase Order with Charge Item
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, Purchaseline.Type::"Charge (Item)", false);
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Expected Error: Charge Item not Assigned
        Assert.ExpectedError(StrSubstNo(ChargeItemErr, PurchaseLine."No."));
    end;

    [Test]

    [HandlerFunctions('TaxRatePageHandler')]
    //Scenario 353935- Check if the program is allowing the posting of Invoice with Charge (Item) using the Purchase Order/Invoice with TDS information where T.A.N No. has not been defined.
    procedure PostFromPurchaseOrderwithChargeItemWithoutTANNo()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", ConcessionalCode.Code, WorkDate());

        ///[WHEN] Validated T.A.N. No. Verified
        LibraryTDS.RemoveTANOnCompInfo();

        //[THEN] Assert Error Verified
        asserterror CreateAndPostPurchaseDocument(PurchaseHeader,
            PurchaseHeader."Document Type"::Order,
            Vendor."No.",
            WorkDate(),
            PurchaseLine.Type::"Charge (Item)", false);
        Assert.ExpectedError(TANNoErr);
    end;

    [Test]

    [HandlerFunctions('TaxRatePageHandler')]
    //Scenario 353934- //Scenario 88- Check if the program is allowing the posting of Order with Charge (Item) using the Purchase Order/Invoice with TDS information where Accounting Period has been specified but Quarter for the period is not specified.
    procedure PostFromPurchaseOrderwithChargeItemWithoutAccountingPeriod()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithoutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        // [WHEN] Create and and Post Purchase Invoice with Multi Line
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, Purchaseline.Type::"Charge (Item)", false);
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Expected Error Verified
        Assert.ExpectedError(StrSubstNo(ChargeItemErr, PurchaseLine."No."));
        ;
    end;

    [Test]

    [HandlerFunctions('TaxRatePageHandler,PurchaseOrderStatsHandler')]
    procedure VerifyPurchaseOrderStatisticsWithItem()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        //[Scenario] 354032 - Check if the program is showing TDS amount should be shown in Statistics while creating Purchase Order.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithoutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        //[WHEN] Created and Posted Purchase Order
        CreatePurchaseDocument(
            PurchaseHeader,
            PurchaseHeader."Document Type"::Order,
            Vendor."No.",
            WorkDate(),
            PurchaseLine.Type::Item,
            false);

        //[THEN] Statistics Verified
        VerifyStatisticsForTDS(PurchaseHeader);
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler,PurchaseOrderStatsHandler')]
    procedure VerifyPurchaseOrderStatisticsWithGLAccount()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        //[Scenario] 354032 - Check if the program is showing TDS amount should be shown in Statistics while creating Purchase Order.
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithoutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        //[WHEN] Created and Posted Purchase Order
        CreatePurchaseDocument(
            PurchaseHeader,
            PurchaseHeader."Document Type"::Order,
            Vendor."No.",
            WorkDate(),
            PurchaseLine.Type::"G/L Account",
            false);

        //[THEN] Statistics Verified
        VerifyStatisticsForTDS(PurchaseHeader);
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler,PurchaseOrderStatsHandler')]
    procedure VerifyPurchaseOrderStatisticsWithFixedAsset()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        //[Scenario] 354032 - Check if the program is showing TDS amount should be shown in Statistics while creating Purchase Order.
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithoutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        //[WHEN] Created  Purchase Order
        CreatePurchaseDocument(
            PurchaseHeader,
            PurchaseHeader."Document Type"::Order,
            Vendor."No.",
            WorkDate(),
            PurchaseLine.Type::"Fixed Asset",
            false);

        //[THEN] StatistiCS Verified
        VerifyStatisticsForTDS(PurchaseHeader);
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler,PurchaseOrderStatsHandler')]
    procedure VerifyPurchaseOrderStatisticsWithChargeItem()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        //[Scenario] 354032 - Check if the program is showing TDS amount should be shown in Statistics while creating Purchase Order.
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithoutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        //[WHEN] Purchase Order Created
        CreatePurchaseDocument(
            PurchaseHeader,
            PurchaseHeader."Document Type"::Order,
            Vendor."No.",
            WorkDate(),
            PurchaseLine.Type::"Charge (Item)",
            false);

        //[THEN] Statistics Verified
        VerifyStatisticsForTDS(PurchaseHeader);
    end;

    [Test]
    //Scenario 354242-Check if the program is calculating TDS in case an invoice is raised to the foreign Vendor using Purchase Order/Invoice and Surcharge Overlook is selected with Item.
    //Scenario 353962-Check if the program is calculating TDS in case an invoice is raised to the foreign Vendor using Purchase Order/Invoice and Threshold and Surcharge Overlook is selected with Item.
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromForeignVendorPurchaseOrderwithItemWithPANWithoutConCode()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        TDSNatureOfRemittance: Record "TDS Nature of Remittance";
        TDSActApplicable: Record "Act Applicable";
        DocumentNo: Code[20];
    begin
        IsForeignVendor := true;
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithoutConcessional(Vendor, true, true);
        LibraryTDS.CreateForeignVendorWithPANNoandWithoutConcessional(Vendor);
        LibraryTDS.CreateNatureOfRemittance(TDSNatureOfRemittance);
        LibraryTDS.CreateActApplicable(TDSActApplicable);
        LibraryTDS.AttachSectionWithForeignVendor(TDSPostingSetup."TDS Section", Vendor."No.", true, true, true, true, TDSNatureOfRemittance.Code, TDSActApplicable.Code);
        Storage.Set('NatureOfRemittance', TDSNatureOfRemittance.Code);
        Storage.Set('ActApplicable', TDSActApplicable.Code);
        Storage.Set('CountryCode', Vendor."Country/Region Code");

        //[WHEN] Created and Posted Foreign Vendor Purchase Invoice
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());
        DocumentNo := CreateAndPostPurchaseDocument(
                         PurchaseHeader,
                         PurchaseHeader."Document Type"::Order,
                         Vendor."No.",
                         WorkDate(),
                         PurchaseLine.Type::Item, false);

        //[THEN] //[THEN] G/L Entries and TDS Entries Verified
        LibraryTDS.VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        VerifyTDSEntry(DocumentNo, true, true, true);
        IsForeignVendor := false;
        ;
    end;

    [Test]
    //Scenario 354240-Check if the program is calculating TDS in case an invoice with Fixed Asset is raised to the foreign Vendor using Purchase Order and Surcharge Overlook is selected.

    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromForeignVendorPurchaseOrderwithFixedAssetWithPANWithoutConCode()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        TDSNatureOfRemittance: Record "TDS Nature of Remittance";
        TDSActApplicable: Record "Act Applicable";
        DocumentNo: Code[20];
    begin
        IsForeignVendor := true;
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithoutConcessional(Vendor, true, true);
        LibraryTDS.CreateForeignVendorWithPANNoandWithoutConcessional(Vendor);
        LibraryTDS.CreateNatureOfRemittance(TDSNatureOfRemittance);
        LibraryTDS.CreateActApplicable(TDSActApplicable);
        LibraryTDS.AttachSectionWithForeignVendor(TDSPostingSetup."TDS Section", Vendor."No.", true, true, true, true, TDSNatureOfRemittance.Code, TDSActApplicable.Code);
        Storage.Set('NatureOfRemittance', TDSNatureOfRemittance.Code);
        Storage.Set('ActApplicable', TDSActApplicable.Code);
        Storage.Set('CountryCode', Vendor."Country/Region Code");

        //[WHEN] Created and Posted Foreign Vendor Purchase Invoice
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());
        DocumentNo := CreateAndPostPurchaseDocument(
                           PurchaseHeader,
                           PurchaseHeader."Document Type"::Order,
                           Vendor."No.",
                           WorkDate(),
                           PurchaseLine.Type::"Fixed Asset", false);

        //[THEN] //[THEN] G/L Entries and TDS Entries Verified
        LibraryTDS.VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        VerifyTDSEntry(DocumentNo, true, true, true);
        IsForeignVendor := false;
    end;

    [Test]
    //Scenario 353950- Check if the program is calculating TDS while creating Invoice with G/L Account using the Purchase Order in case of Foreign Vendor.

    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromForeignVendorPurchaseOrderwithGLAccountWithPANWithoutConCode()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        TDSNatureOfRemittance: Record "TDS Nature of Remittance";
        TDSActApplicable: Record "Act Applicable";
        DocumentNo: Code[20];
    begin
        IsForeignVendor := true;
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithoutConcessional(Vendor, true, true);
        LibraryTDS.CreateForeignVendorWithPANNoandWithoutConcessional(Vendor);
        LibraryTDS.CreateNatureOfRemittance(TDSNatureOfRemittance);
        LibraryTDS.CreateActApplicable(TDSActApplicable);
        LibraryTDS.AttachSectionWithForeignVendor(TDSPostingSetup."TDS Section", Vendor."No.", true, true, true, true, TDSNatureOfRemittance.Code, TDSActApplicable.Code);
        Storage.Set('NatureOfRemittance', TDSNatureOfRemittance.Code);
        Storage.Set('ActApplicable', TDSActApplicable.Code);
        Storage.Set('CountryCode', Vendor."Country/Region Code");

        //[WHEN] Created and Posted Foreign Vendor Purchase Order
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());
        DocumentNo := CreateAndPostPurchaseDocument(
                         PurchaseHeader,
                         PurchaseHeader."Document Type"::Order,
                         Vendor."No.",
                         WorkDate(),
                         PurchaseLine.Type::"G/L Account", false);

        //[THEN] G/L Entries and TDS Entries Verified
        LibraryTDS.VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        VerifyTDSEntry(DocumentNo, true, true, true);
        IsForeignVendor := false;
    end;

    [Test]

    [HandlerFunctions('TaxRatePageHandler')]
    //[Scenario 354030 - Check if the program is calculating TDS using Purchase Order where TDS is applicable only on selected lines.
    procedure PostFromPurchaseOrderWithTDSApplicableOnSelectedLines()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        TDSSection2: Record "TDS Section";
        TDSPostingSetup2: Record "TDS Posting Setup";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.CreateTDSPostingSetupForMultipleSection(TDSPostingSetup2, TDSSection2);
        LibraryTDS.UpdateVendorWithPANWithoutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());
        CreateTaxRateSetup(TDSPostingSetup2."TDS Section", Vendor."Assessee Code", '', WorkDate());

        //[WHEN] Created and Posted Purchase Invoice with Multple Line
        CreatePurchaseDocument(PurchaseHeader,
                    PurchaseHeader."Document Type"::Order,
                    Vendor."No.",
                    WorkDate(),
                    PurchaseLine.Type::"G/L Account",
                    false);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, PurchaseLine.Type::Item, false);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        //[THEN] //[THEN] G/L Entries and TDS Entries Verified
        LibraryTDS.VerifyGLEntryCount(DocumentNo, 5);
    end;

    [Test]
    //[Scenario 353906 -Check if the program is calculating TDS while creating Invoice with G/L Account using the Purchase Order/Invoice with multiple NOD.

    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromPurchaseOrderWithGLAccountWithMultipleline()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithoutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        //[WHEN] Created and Posted Purchase Invoice with Multple Line
        CreatePurchaseDocument(PurchaseHeader,
             PurchaseHeader."Document Type"::Order,
             Vendor."No.",
             WorkDate(),
             PurchaseLine.Type::"G/L Account",
             false);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, PurchaseLine.Type::"G/L Account", false);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        //[THEN] //[THEN] G/L Entries and TDS Entries Verified
        LibraryTDS.VerifyGLEntryCount(DocumentNo, 4);
    end;

    [Test]
    //Scenario 354040 - Check if the program is calculating TDS while creating Invoice with Item using the Purchase Order/Invoice with multiple NOD.
    //Scenario 353940 - Check if the program is calculating TDS while creating Invoice with Item using the Purchase Invoice with multiple NOD..
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromPurchaseOrderWithItemWithMultipleline()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithoutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        //[WHEN] Created and Posted Purchase Invoice with Multple Line
        CreatePurchaseDocument(PurchaseHeader,
                    PurchaseHeader."Document Type"::Order,
                    Vendor."No.",
                    WorkDate(),
                    PurchaseLine.Type::Item,
                    false);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, PurchaseLine.Type::Item, false);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        //[THEN] //[THEN] G/L Entries and TDS Entries Verified
        LibraryTDS.VerifyGLEntryCount(DocumentNo, 3);
    end;

    [Test]

    [HandlerFunctions('TaxRatePageHandler')]
    //[Scenario] 353937 - Check if the program is calculating TDS while creating Invoice with Charge(Item) using the Purchase Order/Invoice with multiple NOD.
    procedure PostFromPurchaseOrderWithChargeItemWithMultipleline()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithoutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        // [WHEN] Create and and Post Purchase Invoice with Multi Line
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, Purchaseline.Type::"Charge (Item)", false);
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Expected Error: Charge Item not Assigned
        Assert.ExpectedError(StrSubstNo(ChargeItemErr, PurchaseLine."No."));
    end;

    [Test]
    //[Scenario] 353941 - Check if the program is calculating TDS while creating Invoice with Fixed Asset using the Purchase Order/Invoice with multiple NOD.

    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromPurchaseOrderWithFixedAssetWithMultipleline()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithoutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        //[WHEN] Created and Posted Purchase Invoice with Multple Line
        CreatePurchaseDocument(PurchaseHeader,
                PurchaseHeader."Document Type"::Order,
                Vendor."No.",
                WorkDate(),
                PurchaseLine.Type::"Fixed Asset",
                false);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, PurchaseLine.Type::"Fixed Asset", false);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        //[THEN] //[THEN] G/L Entries and TDS Entries Verified
        LibraryTDS.VerifyGLEntryCount(DocumentNo, 4);
    end;

    [Test]

    [HandlerFunctions('TaxRatePageHandler')]
    //Scenario 354021- Check if the program is calculating TDS using Purchase Order in case of Line Discount.
    procedure PostFromPurchaseOrderWithGLandLineDiscount()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode without Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithoutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        //[THEN] Created and Posted purchase Invoice
        DocumentNo := CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseHeader."Document Type"::Order,
                            Vendor."No.",
                            WorkDate(),
                            PurchaseLine.Type::"G/L Account",
                            true);

        //[THEN] //[THEN] G/L Entries and TDS Entries Verified
        LibraryTDS.VerifyGLEntryCount(DocumentNo, 4);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        VerifyTDSEntry(DocumentNo, true, true, true);
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorInvoiceDiscountPageHandler')]
    //Scenario 354024- Check if the program is calculating TDS using Purchase Order in case of Invoice Discount.
    procedure PostFromPurchaseOrderWithGLandInvoiceDiscount()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode without Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithoutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());
        CreateVendorInvoiceDiscount(Vendor."No.");

        //[THEN] Created and Posted Purchase Invoice with Invoice Discount
        CreatePurchaseDocument(PurchaseHeader,
                    PurchaseHeader."Document Type"::Order,
                    Vendor."No.",
                    WorkDate(),
                    PurchaseLine.Type::"G/L Account",
                    false);
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        if PurchaseLine.FindFirst() then begin
            PurchaseLine.Validate("Allow Invoice Disc.", true);
            PurchaseLine.Modify(true);
            PurchaseCalcDiscount.Run(PurchaseLine);
            PurchaseLine.Validate("Direct Unit Cost");
        end;
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        //[THEN] G/L Entries and TDS Entries Verified
        LibraryTDS.VerifyGLEntryCount(DocumentNo, 4);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
    end;

    [Test]

    [HandlerFunctions('TaxRatePageHandler,VendorInvoiceDiscountPageHandler')]
    //Scenario 354024- Check if the program is calculating TDS using Purchase Order in case of Invoice Discount.
    procedure PostFromPurchaseOrderWithItemAndInvoiceDiscount()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode without Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithoutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());
        CreateVendorInvoiceDiscount(Vendor."No.");

        //[THEN] Created and Posted Purchase Invoice with Invoice Discount
        CreatePurchaseDocument(PurchaseHeader,
                    PurchaseHeader."Document Type"::Order,
                    Vendor."No.",
                    WorkDate(),
                    PurchaseLine.Type::Item,
                    false);
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        if PurchaseLine.FindFirst() then begin
            PurchaseLine.Validate("Allow Invoice Disc.", true);
            PurchaseLine.Modify(true);
            PurchaseCalcDiscount.Run(PurchaseLine);
            PurchaseLine.Validate("Direct Unit Cost");
        end;
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        //[THEN] G/L Entries and TDS Entries Verified
        LibraryTDS.VerifyGLEntryCount(DocumentNo, 4);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
    end;

    [Test]

    [HandlerFunctions('TaxRatePageHandler,VendorInvoiceDiscountPageHandler')]
    //Scenario 354024- Check if the program is calculating TDS using Purchase Order in case of Invoice Discount.
    procedure PostFromPurchaseOrderWithFixedAssetAndInvoiceDiscount()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode without Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithoutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());
        CreateVendorInvoiceDiscount(Vendor."No.");

        //[THEN] Created and Posted Purchase Invoice with Invoice Discount
        CreatePurchaseDocument(PurchaseHeader,
                    PurchaseHeader."Document Type"::Order,
                    Vendor."No.",
                    WorkDate(),
                    PurchaseLine.Type::"Fixed Asset",
                    false);
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        if PurchaseLine.FindFirst() then begin
            PurchaseLine.Validate("Allow Invoice Disc.", true);
            PurchaseLine.Modify(true);
            PurchaseCalcDiscount.Run(PurchaseLine);
            PurchaseLine.Validate("Direct Unit Cost");
        end;
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        //[THEN] G/L Entries and TDS Entries Verified
        LibraryTDS.VerifyGLEntryCount(DocumentNo, 4);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
    end;

    [Test]

    [HandlerFunctions('TaxRatePageHandler,VendorInvoiceDiscountPageHandler')]
    //Scenario 354024- Check if the program is calculating TDS using Purchase Order in case of Invoice Discount.
    procedure PostFromPurchaseOrderWithChargeItemAndInvoiceDiscount()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode without Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithoutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());
        CreateVendorInvoiceDiscount(Vendor."No.");

        //[THEN] Created and Purchase Invoice with Invoice Discount
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, Purchaseline.Type::"Charge (Item)", false);

        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        if PurchaseLine.FindFirst() then begin
            PurchaseLine.Validate("Allow Invoice Disc.", true);
            PurchaseLine.Modify(true);
            PurchaseCalcDiscount.Run(PurchaseLine);
            PurchaseLine.Validate("Direct Unit Cost");
        end;
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        //[THEN] Expected Error Verified
        Assert.ExpectedError(StrSubstNo(ChargeItemErr, PurchaseLine."No."));
    end;

    [Test]

    [HandlerFunctions('TaxRatePageHandler')]
    //Scenario 353953- Check if the program is calculating TDS in Purchase Order/Invoice with no threshold and surcharge overlook for NOD lines of a particular Vendor with G/L Account.
    procedure PostFromPurchaseOrderWithGLWithoutThresholdandSurchargeOverlook()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithOutConcessional(Vendor, false, false);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        //[WHEN] Created and Posted Purchase Order with G/L Account
        DocumentNo := CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseHeader."Document Type"::Order,
                            Vendor."No.",
                            WorkDate(),
                            PurchaseLine.Type::"G/L Account",
                            false);

        //[THEN] //[THEN] G/L Entries and TDS Entries Verified
        LibraryTDS.VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        VerifyTDSEntry(DocumentNo, true, false, false);
    end;

    [Test]

    [HandlerFunctions('TaxRatePageHandler')]
    //Scenario 353966- Check if the program is calculating TDS while creating Invoice with Item using the Purchase Order/Invoice with no threshold and surcharge overlook for NOD lines of a particular Vendor.
    procedure PostFromPurchaseOrderWithItemWithoutThresholdandandSurchargeOverlook()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithOutConcessional(Vendor, false, false);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        //[WHEN] Created and Posted Purchase Order with Item
        DocumentNo := CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseHeader."Document Type"::Order,
                            Vendor."No.",
                            WorkDate(),
                            PurchaseLine.Type::Item,
                            false);

        //[THEN] //[THEN] G/L Entries and TDS Entries Verified
        LibraryTDS.VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        VerifyTDSEntry(DocumentNo, true, false, false);
    end;

    [Test]

    [HandlerFunctions('TaxRatePageHandler')]
    //Scenario 353953- Check if the program is calculating TDS in Purchase Order/Invoice with no threshold and surcharge overlook for NOD lines of a particular Vendor with G/L Account.
    procedure PostFromPurchaseOrderWithFixedAssetWithoutThresholdandSurchargeOverlook()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithOutConcessional(Vendor, false, false);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        //[WHEN] Created and Posted Purchase Order with Fixed Asset
        DocumentNo := CreateAndPostPurchaseDocument(
                       PurchaseHeader,
                       PurchaseHeader."Document Type"::Order,
                       Vendor."No.",
                       WorkDate(),
                       PurchaseLine.Type::"Fixed Asset",
                       false);

        //[THEN] //[THEN] G/L Entries and TDS Entries Verified
        LibraryTDS.VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        VerifyTDSEntry(DocumentNo, true, false, false);
    end;

    [Test]

    [HandlerFunctions('TaxRatePageHandler')]
    //Scenario 353956- Check if the program is calculating TDS while creating Invoice with Charge (Item) using the Purchase Order/Invoice with no threshold and surcharge overlook for NOD lines of a particular Vendor.
    procedure PostFromPurchaseOrderwithChargeItemWithoutSurchargeandThresholdOverlook()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        // [GIVEN] Created Setup for Section, Assessee Code, Vendor, TDS Setup, Tax Accounting Period and TDS Rates.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithoutPANWithoutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        // [WHEN] Create and and Post Purchase Order with Charge Item
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, Purchaseline.Type::"Charge (Item)", false);
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Expected Error: Charge Item not Assigned
        Assert.ExpectedError(StrSubstNo(ChargeItemErr, PurchaseLine."No."));
    end;

    local procedure CreateVendorInvoiceDiscount(VendorNo: Code[20])
    var
        VendorTestPage: TestPage "Vendor Card";
    begin
        VendorTestPage.OpenEdit();
        VendorTestPage.Filter.SetFilter("No.", VendorNo);
        VendorTestPage."Invoice &Discounts".Invoke();
    end;

    [PageHandler]
    procedure VendorInvoiceDiscountPageHandler(var VendInvDisc: TestPage "Vend. Invoice Discounts");
    begin
        VendInvDisc."Discount %".SetValue(LibraryRandom.RandIntInRange(1, 4));
        VendInvDisc.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text; VAR Reply: Boolean)
    begin
        Reply := TRUE;
    end;

    local procedure CreateTaxRateSetup(TDSSection: Code[10]; AssesseeCode: Code[10]; ConcessionlCode: Code[10]; EffectiveDate: Date)
    var
        Section: Code[10];
        TDSAssesseeCode: Code[10];
        TDSConcessionlCode: Code[10];
    begin
        Section := TDSSection;
        Storage.Set('SectionCode', Section);
        TDSAssesseeCode := AssesseeCode;
        Storage.Set('TDSAssesseeCode', TDSAssesseeCode);
        TDSConcessionlCode := ConcessionlCode;
        Storage.Set('TDSConcessionalCode', TDSConcessionlCode);
        Storage.Set('EffectiveDate', Format(EffectiveDate));
        CreateTaxRate();
    end;

    local procedure GenerateTaxComponentsPercentage()
    begin
        Storage.Set('TDSPercentage', Format(LibraryRandom.RandIntInRange(2, 4)));
        Storage.Set('NonPANTDSPercentage', Format(LibraryRandom.RandIntInRange(2, 4)));
        Storage.Set('SurchargePercentage', Format(LibraryRandom.RandIntInRange(2, 4)));
        Storage.Set('eCessPercentage', Format(LibraryRandom.RandIntInRange(2, 4)));
        Storage.Set('SHECessPercentage', Format(LibraryRandom.RandIntInRange(2, 4)));
        Storage.Set('TDSThresholdAmount', Format(LibraryRandom.RandIntInRange(2, 4)));
        Storage.Set('SurchargeThresholdAmount', Format(LibraryRandom.RandIntInRange(2, 4)));
    end;

    Local procedure CreateTaxRate()
    var
        TDSSetup: Record "TDS Setup";
        PageTaxtype: TestPage "Tax Types";
    begin
        if not TDSSetup.Get() then
            exit;
        PageTaxtype.OpenEdit();
        PageTaxtype.Filter.SetFilter(Code, TDSSetup."Tax Type");
        PageTaxtype.TaxRates.Invoke();
    end;

    [PageHandler]
    procedure TaxRatePageHandler(var TaxRate: TestPage "Tax Rates");
    var
        EffectiveDate: Date;
        TDSPercentage: Decimal;
        NonPANTDSPercentage: Decimal;
        SurchargePercentage: Decimal;
        eCessPercentage: Decimal;
        SHECessPercentage: Decimal;
        TDSThresholdAmount: Decimal;
        SurchargeThresholdAmount: Decimal;
    begin
        GenerateTaxComponentsPercentage();
        Evaluate(EffectiveDate, Storage.Get('EffectiveDate'));
        Evaluate(TDSPercentage, Storage.Get('TDSPercentage'));
        Evaluate(NonPANTDSPercentage, Storage.Get('NonPANTDSPercentage'));
        Evaluate(SurchargePercentage, Storage.Get('SurchargePercentage'));
        Evaluate(eCessPercentage, Storage.Get('eCessPercentage'));
        Evaluate(SHECessPercentage, Storage.Get('SHECessPercentage'));
        Evaluate(TDSThresholdAmount, Storage.Get('TDSThresholdAmount'));
        Evaluate(SurchargeThresholdAmount, Storage.Get('SurchargeThresholdAmount'));

        TaxRate.AttributeValue1.SetValue(Storage.Get('SectionCode'));
        TaxRate.AttributeValue2.SetValue(Storage.Get('TDSAssesseeCode'));
        TaxRate.AttributeValue3.SetValue(EffectiveDate);
        TaxRate.AttributeValue4.SetValue(Storage.Get('TDSConcessionalCode'));
        if IsForeignVendor then begin
            TaxRate.AttributeValue5.SetValue(Storage.Get('NatureOfRemittance'));
            TaxRate.AttributeValue6.SetValue(Storage.Get('ActApplicable'));
            TaxRate.AttributeValue7.SetValue(Storage.Get('CountryCode'))
        end else begin
            TaxRate.AttributeValue5.SetValue('');
            TaxRate.AttributeValue6.SetValue('');
            TaxRate.AttributeValue7.SetValue('');
        end;
        TaxRate.AttributeValue8.SetValue(TDSPercentage);
        TaxRate.AttributeValue9.SetValue(NonPANTDSPercentage);
        TaxRate.AttributeValue10.SetValue(SurchargePercentage);
        TaxRate.AttributeValue11.SetValue(eCessPercentage);
        TaxRate.AttributeValue12.SetValue(SHECessPercentage);
        TaxRate.AttributeValue13.SetValue(TDSThresholdAmount);
        TaxRate.AttributeValue14.SetValue(SurchargeThresholdAmount);
        TaxRate.AttributeValue15.SetValue('');
        TaxRate.AttributeValue16.SetValue('');
        TaxRate.AttributeValue17.SetValue(0.00);
        TaxRate.OK().Invoke();
    end;

    local procedure VerifyStatisticsForTDS(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        TaxTransactionValue: Record "Tax Transaction Value";
        TDSSetup: Record "TDS Setup";
        PurchaseOrderStatistics: TestPage "Purchase Order Statistics";
        PurchaseOrder: TestPage "Purchase Order List";
        RecordIDList: List of [RecordID];
        i: Integer;
        ActualAmount: Decimal;
    begin
        Clear(ExpectedTDSAmount);
        if not TDSSetup.Get() then
            exit;
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document no.", PurchaseHeader."No.");
        if PurchaseLine.FindSet() then
            repeat
                RecordIDList.Add(PurchaseLine.RecordId());
            until PurchaseLine.Next() = 0;

        for i := 1 to RecordIDList.Count() do begin
            TaxTransactionValue.SetRange("Tax Record ID", RecordIDList.Get(i));
            TaxTransactionValue.SetRange("Value Type", TaxTransactionValue."Value Type"::COMPONENT);
            TaxTransactionValue.SetRange("Tax Type", TDSSetup."Tax Type");
            TaxTransactionValue.SetFilter(Percent, '<>%1', 0);
            if not TaxTransactionValue.IsEmpty() then
                TaxTransactionValue.CalcSums(Amount);
            ExpectedTDSAmount += TaxTransactionValue.Amount;
        end;
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GoToRecord(PurchaseHeader);
        PurchaseOrderStatistics.OpenEdit();
        PurchaseOrder.Statistics.Invoke();
        PurchaseOrder.Statistics.Invoke();
        Evaluate(ActualAmount, Storage.Get('TDSAmount'));
        Assert.AreNearlyEqual(Round(ExpectedTDSAmount, 0.01, '='), ActualAmount, LibraryTDS.GetTDSRoundingPrecision(),
        STRSUBSTNO(AmountErr, ActualAmount, PurchaseOrderStatistics."TDS Amount".Caption()));
    end;

    [ModalPageHandler]
    procedure PurchaseOrderStatsHandler(var PurchaseOrderStatistics: TestPage "Purchase Order Statistics")
    var
        Amt: Text;
    begin
        Amt := PurchaseOrderStatistics."TDS Amount".Value;
        Storage.Set('TDSAmount', Amt);
    end;

    local procedure CreatePurchaseDocument(
                var PurchaseHeader: Record "Purchase Header";
                DocumentType: enum "Purchase Document Type";
                                  VendorNo: Code[20];
                                  PostingDate: Date;
                                  LineType: enum "Purchase Line Type";
                                  LineDiscount: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Modify(true);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, LineType, LineDiscount);
    end;

    procedure CreateAndPostPurchaseDocument(var PurchaseHeader: Record "Purchase Header";
          DocumentType: enum "Purchase Document Type";
          VendorNo: Code[20];
          PostingDate: Date;
          LineType: enum "Purchase Line Type"; LineDiscount: Boolean): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Modify(true);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, LineType, LineDiscount);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, TRUE, true))
    end;

    local procedure CreatePurchaseLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line";
    Type: enum "Purchase Line Type"; LineDiscount: Boolean)
    var
        TDSSectionCode: Code[10];
    begin
        InsertPurchaseLine(PurchaseLine, PurchaseHeader, Type);
        if LineDiscount then
            PurchaseLine.VALIDATE("Line Discount %", LibraryRandom.RandDecInRange(10, 20, 2));

        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInDecimalRange(1000, 1001, 0));
        PurchaseLine.MODIFY(TRUE);
    end;

    local procedure InsertPurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: record "Purchase Header"; LineType: enum "Purchase Line Type")
    var
        RecRef: RecordRef;
        TDSSectionCode: Code[10];
    begin
        PurchaseLine.Init();
        PurchaseLine.Validate("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.Validate("Document No.", PurchaseHeader."No.");
        RecRef.GetTable(PurchaseLine);
        PurchaseLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, PurchaseLine.FieldNo("Line No.")));
        PurchaseLine.Validate(Type, LineType);
        PurchaseLine.Validate("No.", GetLineTypeNo(LineType));
        PurchaseLine.Validate(Quantity, LibraryRandom.RandIntInRange(1, 10));
        TDSSectionCode := CopyStr(Storage.Get('SectionCode'), 1, 10);
        PurchaseLine.Validate("TDS Section Code", TDSSectionCode);
        if IsForeignVendor then begin
            PurchaseLine.Validate("Nature of Remittance", Storage.Get('NatureOfRemittance'));
            PurchaseLine.Validate("Act Applicable", Storage.Get('ActApplicable'));
        end;
        PurchaseLine.Insert(true);
    end;

    local procedure GetLineTypeNo(Type: enum "Purchase Line Type"): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
    begin
        case Type of
            PurchaseLine.Type::"G/L Account":
                exit(CreateGLAccountWithDirectPostingNoVAT());
            PurchaseLine.Type::Item:
                exit(CreateItemNoWithoutVAT());
            PurchaseLine.Type::"Fixed Asset":
                exit(CreateFixedAsset());
            PurchaseLine.Type::"Charge (Item)":
                exit(CreateChargeItemWithNoVAT());
        end;
    end;

    local procedure CreateItemNoWithoutVAT(): Code[20]
    var
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryTDS.CreateZeroVATPostingSetup(VATPostingSetup);
        item.GET(LibraryInventory.CreateItemNoWithoutVAT());
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateGLAccountWithDirectPostingNoVAT(): Code[20]
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryTDS.CreateZeroVATPostingSetup(VATPostingSetup);
        GLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify();
        exit(GLAccount."No.");
    end;

    local procedure CreateChargeItemWithNoVAT(): Code[20]
    var
        ItemCharge: Record "Item Charge";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryTDS.CreateZeroVATPostingSetup(VATPostingSetup);
        LibraryInventory.CreateItemCharge(ItemCharge);
        ItemCharge.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        ItemCharge.Modify(true);
        exit(ItemCharge."No.");
    end;

    local procedure CreateFixedAsset(): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FASetup: Record "FA Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        DepreciationBook.Validate("G/L Integration - Disposal", true);
        DepreciationBook.Validate("G/L Integration - Acq. Cost", true);
        DepreciationBook.Modify(true);
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DepreciationBook.Code);
        FADepreciationBook.Validate("FA Posting Group", FixedAsset."FA Posting Group");
        UpdateFAPostingGroupGLAccounts(FixedAsset."FA Posting Group");
        FADepreciationBook.Modify(true);
        FASetup.Get();
        FASetup.Validate("Default Depr. Book", DepreciationBook.Code);
        FASetup.Modify(true);
        exit(FixedAsset."No.")
    end;

    procedure UpdateFAPostingGroupGLAccounts(FAPostingGroupCode: Code[20])
    var
        FAPostingGroup: Record "FA Posting Group";
    begin
        if FAPostingGroup.Get(FAPostingGroupCode) then begin
            FAPostingGroup.Validate("Acquisition Cost Account", CreateGLAccountWithDirectPostingNoVAT());
            FAPostingGroup.Validate("Acq. Cost Acc. on Disposal", CreateGLAccountWithDirectPostingNoVAT());
            FAPostingGroup.Validate("Accum. Depreciation Account", CreateGLAccountWithDirectPostingNoVAT());
            FAPostingGroup.Validate("Accum. Depr. Acc. on Disposal", CreateGLAccountWithDirectPostingNoVAT());
            FAPostingGroup.Validate("Depreciation Expense Acc.", CreateGLAccountWithDirectPostingNoVAT());
            FAPostingGroup.Validate("Gains Acc. on Disposal", CreateGLAccountWithDirectPostingNoVAT());
            FAPostingGroup.Validate("Losses Acc. on Disposal", CreateGLAccountWithDirectPostingNoVAT());
            FAPostingGroup.Validate("Sales Bal. Acc.", CreateGLAccountWithDirectPostingNoVAT());
            FAPostingGroup.Modify(true);
        end;
    end;

    local procedure GetBaseAmountForPurchase(DocumentNo: Code[20]): Decimal
    var
        PurchaseInvoiceLine: Record "Purch. Inv. Line";
    begin
        PurchaseInvoiceLine.SetRange("Document No.", DocumentNo);
        PurchaseInvoiceLine.CalcSums(Amount);
        exit(PurchaseInvoiceLine.Amount);
    end;

    local procedure GetCurrencyFactorForPurchase(DocumentNo: Code[20]): Decimal
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.SetRange("No.", DocumentNo);
        if PurchInvHeader.FindFirst() then
            exit(PurchInvHeader."Currency Factor");
    end;

    local procedure VerifyTDSEntry(DocumentNo: Code[20]; WithPAN: Boolean; SurchargeOverlook: Boolean; TDSThresholdOverlook: Boolean)
    var
        TDSEntry: Record "TDS Entry";
        ExpectdTDSAmount: Decimal;
        ExpectedSurchargeAmount: Decimal;
        ExpectedEcessAmount: Decimal;
        ExpectedSHEcessAmount: Decimal;
        TDSPercentage: Decimal;
        NonPANTDSPercentage: Decimal;
        SurchargePercentage: Decimal;
        eCessPercentage: Decimal;
        SHECessPercentage: Decimal;
        TDSThresholdAmount: Decimal;
        CurrencyFactor: Decimal;
        TDSBaseAmount: Decimal;
        SurchargeThresholdAmount: Decimal;
    begin
        Evaluate(TDSPercentage, Storage.Get('TDSPercentage'));
        Evaluate(NonPANTDSPercentage, Storage.Get('NonPANTDSPercentage'));
        Evaluate(SurchargePercentage, Storage.Get('SurchargePercentage'));
        Evaluate(eCessPercentage, Storage.Get('eCessPercentage'));
        Evaluate(SHECessPercentage, Storage.Get('SHECessPercentage'));
        Evaluate(TDSThresholdAmount, Storage.Get('TDSThresholdAmount'));
        Evaluate(SurchargeThresholdAmount, Storage.Get('SurchargeThresholdAmount'));

        TDSBaseAmount := GetBaseAmountForPurchase(DocumentNo);
        CurrencyFactor := GetCurrencyFactorForPurchase(DocumentNo);

        if CurrencyFactor = 0 then
            CurrencyFactor := 1;
        if (TDSBaseAmount < TDSThresholdAmount) and (TDSThresholdOverlook = false) then
            ExpectdTDSAmount := 0
        else
            if WithPAN then
                ExpectdTDSAmount := TDSBaseAmount * TDSPercentage / 100 / CurrencyFactor
            else
                ExpectdTDSAmount := TDSBaseAmount * NonPANTDSPercentage / 100 / CurrencyFactor;

        if (TDSBaseAmount < SurchargeThresholdAmount) and (SurchargeOverlook = false) then
            ExpectedSurchargeAmount := 0
        else
            ExpectedSurchargeAmount := ExpectdTDSAmount * SurchargePercentage / 100;
        ExpectedEcessAmount := (ExpectdTDSAmount + ExpectedSurchargeAmount) * eCessPercentage / 100;
        ExpectedSHEcessAmount := (ExpectdTDSAmount + ExpectedSurchargeAmount) * SHECessPercentage / 100;
        TDSEntry.SETRANGE("Document No.", DocumentNo);
        TDSEntry.FINDFIRST();
        Assert.AreNearlyEqual(
         TDSBaseAmount / CurrencyFactor, TDSEntry."TDS Base Amount", LibraryTDS.GetTDSRoundingPrecision(),
          STRSUBSTNO(AmountErr, TDSEntry.FIELDNAME("TDS Base Amount"), TDSEntry.TABLECAPTION()));
        if WithPAN then
            Assert.AreEqual(
              TDSPercentage, TDSEntry."TDS %",
              STRSUBSTNO(AmountErr, TDSEntry.FIELDNAME("TDS %"), TDSEntry.TABLECAPTION()))
        else
            Assert.AreEqual(
            NonPANTDSPercentage, TDSEntry."TDS %",
            STRSUBSTNO(AmountErr, TDSEntry.FIELDNAME("TDS %"), TDSEntry.TABLECAPTION()));
        Assert.AreNearlyEqual(
          ExpectdTDSAmount, TDSEntry."TdS Amount", LibraryTdS.GetTDSRoundingPrecision(),
          STRSUBSTNO(AmountErr, TDSEntry.FIELDNAME("TDS Amount"), TDSEntry.TABLECAPTION()));
        Assert.AreEqual(
          SurchargePercentage, TDSEntry."Surcharge %",
          STRSUBSTNO(AmountErr, TDSEntry.FIELDNAME("Surcharge %"), TDSEntry.TABLECAPTION()));
        Assert.AreNearlyEqual(
          ExpectedSurchargeAmount, TDSEntry."Surcharge Amount", LibraryTDS.GetTDSRoundingPrecision(),
          STRSUBSTNO(AmountErr, TDSEntry.FIELDNAME("Surcharge Amount"), TDSEntry.TABLECAPTION()));
        Assert.AreEqual(
          eCessPercentage, TDSEntry."eCESS %",
          STRSUBSTNO(AmountErr, TDSEntry.FIELDNAME("eCESS %"), TDSEntry.TABLECAPTION()));
        Assert.AreNearlyEqual(
          ExpectedEcessAmount, TDSEntry."eCESS Amount", LibraryTDS.GetTDSRoundingPrecision(),
          STRSUBSTNO(AmountErr, TDSEntry.FIELDNAME("eCESS Amount"), TDSEntry.TABLECAPTION()));
        Assert.AreEqual(
          SHECessPercentage, TDSEntry."SHE Cess %",
          STRSUBSTNO(AmountErr, TDSEntry.FIELDNAME("SHE Cess %"), TDSEntry.TABLECAPTION()));
        Assert.AreNearlyEqual(
          ExpectedSHEcessAmount, TDSEntry."SHE Cess Amount", LibraryTDS.GetTDSRoundingPrecision(),
          STRSUBSTNO(AmountErr, TDSEntry.FIELDNAME("SHE Cess Amount"), TDSEntry.TABLECAPTION()));
    end;

    var
        LibraryERM: codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTDS: Codeunit "Library-TDS";
        Assert: Codeunit Assert;
        LibraryPurchase: Codeunit "Library - Purchase";
        PurchaseCalcDiscount: Codeunit "Purch.-Calc.Discount";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        Storage: Dictionary of [Text, Text];
        ExpectedTDSAmount: Decimal;
        IsForeignVendor: Boolean;
        TANNoErr: Label 'T.A.N. No. must have a value in Company Information', locked = true;
        IncomeTaxAccountingErr: Label 'The Posting Date doesn''t lie in Tax Accounting Period', Locked = true;
        ChargeItemErr: Label 'You must assign item charge %1 if you want to invoice it.', Comment = '%1= No.';
        AmountErr: Label '%1 is incorrect in %2.', Comment = '%1 and %2 = TCS Amount and TCS field Caption';
}