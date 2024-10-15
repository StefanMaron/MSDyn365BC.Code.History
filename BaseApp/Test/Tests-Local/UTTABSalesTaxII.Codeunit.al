codeunit 142090 "UT TAB Sales Tax II"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Sales Tax]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryJournals: Codeunit "Library - Journals";
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryPermissions: Codeunit "Library - Permissions";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        ValueMustBeEqualMsg: Label 'Value Must Be Equal.';
        ExpectedTaxGroupCodeErr: Label 'Tax Group Code must have a value in G/L Account: No.=%1. It cannot be zero or empty.';
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        IsInitialized: Boolean;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure OnValidateCustomerNoServiceHeaderWithGLSetup()
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        // Purpose of the test is to validate Trigger OnValidate of Customer No. of Table - 5900 Service Header

        // Setup.
        Initialize();
        CreateCustomer(Customer);
        CreateServiceHeader(ServiceHeader, Customer."No.", '');
        RecRef.GetTable(ServiceHeader);
        FieldRef := RecRef.Field(ServiceHeader.FieldNo("Customer No."));

        // Exercise: Validate statement to call OnValidate Trigger of the respective fields.
        Commit();  // COMMIT is explicitly required as used in the Service Header.
        FieldRef.Validate();

        // Verify.
        RecRef.SetTable(ServiceHeader);
        ServiceHeader.TestField("Tax Exemption No.", Customer."Tax Exemption No.");
        ServiceHeader.TestField("Gen. Bus. Posting Group", Customer."Gen. Bus. Posting Group");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateTaxLiableServiceHeader()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        // Purpose of the test is to validate Trigger OnValidate of Tax Liable of Table - 5900 Service Header.

        // Setup.
        Initialize();
        CreateCustomer(Customer);
        CreateServiceOrder(ServiceLine, Customer."No.", ServiceLine.Type::Item, CreateItem, '');
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        RecRef.GetTable(ServiceHeader);
        FieldRef := RecRef.Field(ServiceHeader.FieldNo("Tax Liable"));

        // Exercise: Validate statement to call OnValidate Trigger of the respective fields.
        FieldRef.Validate();

        // Verify.
        RecRef.SetTable(ServiceHeader);
        ServiceLine.TestField("Tax Liable", false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure OnValidateCustomerNoWithShipmentServiceHeader()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Purpose of the test is to validate Trigger OnValidate of Customer No. of Table - 5902 Service Line when Shipment Header is posted.

        // Setup.
        Initialize();
        CreateCustomer(Customer);
        CreateServiceOrder(ServiceLine, Customer."No.", ServiceLine.Type::Item, CreateItem, '');
        ServiceLine."Quantity Shipped" := LibraryRandom.RandInt(100);
        ServiceLine.Modify();
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");

        // Exercise: Validate statement to call OnValidate Trigger of the respective fields.
        Commit();  // COMMIT is explicitly used on Trigger OnValidate of Customer No. of Service Header.
        ServiceHeader.Validate("Customer No.");

        // Verify.
        ServiceHeader.TestField("Gen. Bus. Posting Group", Customer."Gen. Bus. Posting Group");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnDeleteServiceHeader()
    var
        Customer: Record Customer;
        SalesTaxDifference: Record "Sales Tax Amount Difference";
        ServiceHeader: Record "Service Header";
        TaxArea: Record "Tax Area";
    begin
        // Purpose of the test is to validate OnDelete Trigger of Table ID - 5900 Service Header.

        // Setup.
        Initialize();
        CreateCustomer(Customer);
        CreateServiceHeader(ServiceHeader, Customer."No.", CreateTaxArea(TaxArea."Country/Region"::CA, false));
        CreateSalesTaxDifference(SalesTaxDifference, ServiceHeader);
        ServiceHeader.Get(SalesTaxDifference."Document Type", SalesTaxDifference."Document No.");

        // Exercise.
        ServiceHeader.Delete(true);

        // Verify: Verify Sales Tax Difference Amount is deleted.
        SalesTaxDifference.SetRange("Document Product Area", SalesTaxDifference."Document Product Area"::Sales);
        SalesTaxDifference.SetRange("Document Type", ServiceHeader."Document Type");
        SalesTaxDifference.SetRange("Document No.", ServiceHeader."No.");
        Assert.AreEqual(0, SalesTaxDifference.Count, ValueMustBeEqualMsg);  // Number of Records - 0.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateNoWithTypeAsBlankOnServiceLine()
    var
        Customer: Record Customer;
        ServiceLine: Record "Service Line";
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        // Purpose of the test is to validate Trigger OnValidate of No. of Table - 5902 Service Line when Type as blank.

        // Setup.
        Initialize();
        CreateCustomer(Customer);
        CreateServiceOrder(ServiceLine, Customer."No.", ServiceLine.Type::" ", '', '');
        RecRef.GetTable(ServiceLine);
        FieldRef := RecRef.Field(ServiceLine.FieldNo("No."));

        // Exercise: Validate statement to call OnValidate Trigger of the respective fields.
        FieldRef.Validate();

        // Verify.
        RecRef.SetTable(ServiceLine);
        ServiceLine.TestField("Tax Liable", false);
        ServiceLine.TestField("Tax Area Code", '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateNoWithTypeAsCostOnServiceLine()
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        ServiceCost: Record "Service Cost";
        ServiceLine: Record "Service Line";
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        // Purpose of the test is to validate Trigger OnValidate of No. of Table - 5902 Service Line when Type as Cost.

        // Setup.
        Initialize();
        CreateCustomer(Customer);
        CreateCost(ServiceCost);
        CreateServiceOrder(ServiceLine, Customer."No.", ServiceLine.Type::Cost, ServiceCost.Code, '');
        RecRef.GetTable(ServiceLine);
        FieldRef := RecRef.Field(ServiceLine.FieldNo("No."));

        // Exercise: Validate statement to call OnValidate Trigger of the respective fields.
        FieldRef.Validate();

        // Verify.
        RecRef.SetTable(ServiceLine);
        GLAccount.Get(ServiceCost."Account No.");
        ServiceLine.TestField("Gen. Prod. Posting Group", GLAccount."Gen. Prod. Posting Group");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateTaxAreaCodeWithCountryOnServiceLine()
    var
        TaxArea: Record "Tax Area";
    begin
        // Purpose of the test is to validate Trigger OnValidate of Tax Area Code with Tax Area Country for Table 5902 - Service Line.
        OnValidateTaxAreaCodeServiceLine(CreateTaxArea(TaxArea."Country/Region"::CA, false), CreateTaxArea(TaxArea."Country/Region"::US, false));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateTaxAreaCodeWithUseExtTaxEngOnServiceLine()
    var
        TaxArea: Record "Tax Area";
    begin
        // Purpose of the test is to validate Trigger OnValidate of Tax Area Code with Use External Tax Engine as true for Table 5902- Service Line.
        OnValidateTaxAreaCodeServiceLine(CreateTaxArea(TaxArea."Country/Region"::CA, true), CreateTaxArea(TaxArea."Country/Region"::CA, false));
    end;

    local procedure OnValidateTaxAreaCodeServiceLine(HeaderTaxAreaCode: Code[20]; LineTaxAreaCode: Code[20])
    var
        Customer: Record Customer;
        ServiceLine: Record "Service Line";
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        // Setup.
        Initialize();
        CreateCustomer(Customer);
        CreateServiceOrder(ServiceLine, Customer."No.", ServiceLine.Type::Item, CreateItem, HeaderTaxAreaCode);
        ServiceLine."Tax Area Code" := LineTaxAreaCode;
        ServiceLine.Modify();
        RecRef.GetTable(ServiceLine);
        FieldRef := RecRef.Field(ServiceLine.FieldNo("Tax Area Code"));

        // Exercise: Validate statement to call OnValidate Trigger of the respective fields.
        asserterror FieldRef.Validate();

        // Verify.
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAccountNoWithVendorGenJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
    begin
        // Purpose of the test is to validate Trigger OnValidate of Account No. when Account Type is Vendor of Table - 81 Gen. Journal Line.
        CreateVendor(Vendor);
        OnValidateAccountNoGenJournalLine(
          GenJournalLine."Account Type"::Vendor,
          Vendor."No.", GenJournalLine."Bal. Account Type", '', Vendor."IRS 1099 Code", GenJournalLine.FieldNo("Account No."));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAccountNoWithBankAccountGenJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate Trigger OnValidate of Account No. when Account Type is Vendor  of Table - 81 Gen. Journal Line.
        OnValidateAccountNoGenJournalLine(
          GenJournalLine."Account Type"::"Bank Account",
          '', GenJournalLine."Bal. Account Type"::"Bank Account", '', '', GenJournalLine.FieldNo("Account No."));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateBalAccountNoGenJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
    begin
        // Purpose of the test is to validate Trigger OnValidate Bal. Account No. of Table - 81 Gen. Journal Line.
        CreateVendor(Vendor);
        OnValidateAccountNoGenJournalLine(
          GenJournalLine."Account Type",
          '', GenJournalLine."Bal. Account Type"::Vendor, Vendor."No.", Vendor."IRS 1099 Code", GenJournalLine.FieldNo("Bal. Account No."));
    end;

    local procedure OnValidateAccountNoGenJournalLine(AccountType: Option; AccountNo: Code[20]; BalAccountType: Option; BalAccountNo: Code[20]; IRSCodeValue: Code[10]; FieldNo: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        // Setup.
        Initialize();
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::" ", AccountType, AccountNo, BalAccountType, BalAccountNo);
        RecRef.GetTable(GenJournalLine);
        FieldRef := RecRef.Field(FieldNo);

        // Exercise: Validate statement to call OnValidate Trigger of the respective fields.
        FieldRef.Validate();

        // Verify.
        RecRef.SetTable(GenJournalLine);
        GenJournalLine.TestField("IRS 1099 Code", IRSCodeValue);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateDocumentTypeAsBlankWithVendorGenJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate Trigger OnValidate Document Type as blank and Account Type as Vendor of Table - 81 Gen. Journal Line.
        OnValidateGenJournalLineWithAccountTypeAsVendor(GenJournalLine."Document Type"::" ", GenJournalLine.FieldNo("Document Type"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAmountDocumentTypeAsBlankWithVendorGenJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate Trigger OnValidate Amount with Document Type as blank and Account Type as Vendor of Table - 81 Gen. Journal Line.
        OnValidateGenJournalLineWithAccountTypeAsVendor(GenJournalLine."Document Type"::" ", GenJournalLine.FieldNo(Amount));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateDocumentTypeAsInvoiceWithVendorGenJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate Trigger OnValidate Document Type with Invoice and Account Type as Vendor of Table - 81 Gen. Journal Line.
        OnValidateGenJournalLineWithAccountTypeAsVendor(GenJournalLine."Document Type"::Invoice, GenJournalLine.FieldNo("Document Type"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAmountDocumentTypeAsInvoiceWithVendorGenJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate Trigger OnValidate Amount with Document Type as Invoice and Account Type as Vendor of Table - 81 Gen. Journal Line.
        OnValidateGenJournalLineWithAccountTypeAsVendor(GenJournalLine."Document Type"::Invoice, GenJournalLine.FieldNo(Amount));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateDocumentTypeAsCreditMemoWithVendorGenJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate Trigger OnValidate Document Type with Credit Memo and Account Type as Vendor of Table - 81 Gen. Journal Line.
        OnValidateGenJournalLineWithAccountTypeAsVendor(
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine.FieldNo("Document Type"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAmountDocumentTypeAsCreditMemoWithVendorGenJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate Trigger OnValidate Amount with Document Type as Credit Memo and Account Type as Vendor of Table - 81 Gen. Journal Line.
        OnValidateGenJournalLineWithAccountTypeAsVendor(GenJournalLine."Document Type"::"Credit Memo", GenJournalLine.FieldNo(Amount));
    end;

    local procedure OnValidateGenJournalLineWithAccountTypeAsVendor(DocumentType: Option; FieldNo: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        // Setup.
        CreateVendor(Vendor);
        CreateGenJournalLine(
          GenJournalLine, DocumentType, GenJournalLine."Account Type"::Vendor, Vendor."No.", GenJournalLine."Bal. Account Type", '');
        GenJournalLine."IRS 1099 Code" := CreateIRSCode;
        GenJournalLine.Amount := LibraryRandom.RandDec(100, 2);
        GenJournalLine.Modify();
        RecRef.GetTable(GenJournalLine);
        FieldRef := RecRef.Field(FieldNo);

        // Exercise: Validate statement to call OnValidate Trigger of the respective fields.
        FieldRef.Validate();

        // Verify.
        RecRef.SetTable(GenJournalLine);
        GenJournalLine.TestField("IRS 1099 Amount", GenJournalLine.Amount);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateDocumentTypeAsBlankWithCustomerGenJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate Trigger OnValidate Document Type as blank and Account Type as Customer of Table - 81 Gen. Journal Line.
        OnValidateGenJournalLineWithDocumentType(
          GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::Customer, LibraryRandom.RandDec(100, 2), GenJournalLine.FieldNo("Document Type"));  // Random value is used for Amount.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAmountDocumentTypeAsBlankWithCustomerGenJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate Trigger OnValidate Amount with Document Type as blank and Account Type as Customer of Table - 81 Gen. Journal Line.
        OnValidateGenJournalLineWithDocumentType(
          GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::Customer, LibraryRandom.RandDec(100, 2), GenJournalLine.FieldNo(Amount));  // Random value is used for Amount.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateDocumentTypeAsInvoiceWithCustomerGenJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate Trigger OnValidate Document Type with Invoice and Account Type as Customer of Table - 81 Gen. Journal Line.
        OnValidateGenJournalLineWithDocumentType(
          GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, LibraryRandom.RandDec(100, 2), GenJournalLine.FieldNo("Document Type"));  // Random value is used for Amount.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAmountDocumentTypeAsInvoiceWithCustomerGenJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate Trigger OnValidate Amount with Document Type as Invoice and Account Type as Customer of Table - 81 Gen. Journal Line.
        OnValidateGenJournalLineWithDocumentType(
          GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, LibraryRandom.RandDec(100, 2), GenJournalLine.FieldNo(Amount));  // Random value is used for Amount.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateDocumentTypeAsCreditMemoWithCustomerGenJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate Trigger OnValidate Document Type with Credit Memo and Account Type as Customer of Table - 81 Gen. Journal Line.
        OnValidateGenJournalLineWithDocumentType(
          GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Account Type"::Customer, LibraryRandom.RandDec(100, 2), GenJournalLine.FieldNo("Document Type"));  // Random value is used for Amount.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAmountDocumenTypeAsCreditMemoWithCustomerGenJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate Trigger OnValidate Amount with Document Type as Credit Memo and Account Type as Customer of Table - 81 Gen. Journal Line.
        OnValidateGenJournalLineWithDocumentType(
          GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Account Type"::Customer, LibraryRandom.RandDec(100, 2), GenJournalLine.FieldNo(Amount));  // Random value is used for Amount.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateDocumentTypeAsPaymentGenJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate Trigger OnValidate Document Type with Payment of Table - 81 Gen. Journal Line.
        OnValidateGenJournalLineWithDocumentType(
          GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type", 0, GenJournalLine.FieldNo("Document Type"));  // 0 is used for verifying Amount.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAmountWithDocumentTypeAsPaymentGenJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate Trigger OnValidate Document Type with Payment of Table - 81 Gen. Journal Line.
        OnValidateGenJournalLineWithDocumentType(
          GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type", 0, GenJournalLine.FieldNo(Amount));  // 0 is used for verifying Amount.
    end;

    local procedure OnValidateGenJournalLineWithDocumentType(DocumentType: Option; AccountType: Option; Amount: Decimal; FieldNo: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        // Setup.
        CreateVendor(Vendor);
        CreateGenJournalLine(GenJournalLine, DocumentType, AccountType, '', GenJournalLine."Bal. Account Type", '');
        GenJournalLine."IRS 1099 Code" := CreateIRSCode;
        GenJournalLine.Amount := Amount;
        GenJournalLine.Modify();
        RecRef.GetTable(GenJournalLine);
        FieldRef := RecRef.Field(FieldNo);

        // Exercise: Validate statement to call OnValidate Trigger of the respective fields.
        FieldRef.Validate();

        // Verify.
        RecRef.SetTable(GenJournalLine);
        GenJournalLine.TestField("IRS 1099 Amount", -Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyTaxAreaCodeIsSet()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 200318] Tax Area Code is updated in the General Journal Line after validate vendor
        Initialize();

        // [GIVEN] Create Vendor with a Tax Area Code
        CreateVendor(Vendor);
        Vendor."Tax Area Code" := LibraryUtility.GenerateRandomCode(82, 81);
        Vendor.Modify();

        // [WHEN] Create a General Journal line and assign the above vendor
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, Vendor."No.", -LibraryRandom.RandDec(100, 2));

        // [THEN] Verify that the Tax Area Code from the vendor matches the General Journal Line Tax Area Code.
        GenJournalLine.TestField("Tax Area Code", Vendor."Tax Area Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateGLAccountNonPrepaidServiceContractAccountGroupFails()
    var
        ServiceContractAccountGroup: Record "Service Contract Account Group";
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] [Service Contract Account Group] [UT]
        // [SCENARIO 289828] Service Contract Account Group "Non-Prepaid Contract Acc." can be validated only by GLAccount with Tax Group Code defined
        Initialize();
        // [GIVEN] GLAccount with Tax Group Code undefined - X
        GLAccount."No." := LibraryUTUtility.GetNewCode;
        GLAccount.Insert();
        // [GIVEN] Service Contract Account Group
        ServiceContractAccountGroup.Code := LibraryUTUtility.GetNewCode10;
        ServiceContractAccountGroup.Insert();

        // [WHEN] Validate "Non-Prepaid Contract Acc." Service Contract Account Group with X
        // [THEN] Error is shown
        asserterror ServiceContractAccountGroup.Validate("Non-Prepaid Contract Acc.", GLAccount."No.");
        Assert.ExpectedError(StrSubstNo(ExpectedTaxGroupCodeErr, GLAccount."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateGLAccountNonPrepaidServiceContractAccountGroup()
    var
        ServiceContractAccountGroup: Record "Service Contract Account Group";
        GLAccount: Record "G/L Account";
        TaxGroup: Record "Tax Group";
    begin
        // [FEATURE] [Service Contract Account Group] [UT]
        // [SCENARIO 289828] Service Contract Account Group "Non-Prepaid Contract Acc." can be validated only by GLAccount with Tax Group Code defined
        Initialize();
        // [GIVEN] GLAccount with Tax Group Code defined - X
        LibraryERM.CreateTaxGroup(TaxGroup);
        GLAccount."No." := LibraryUTUtility.GetNewCode;
        GLAccount."Tax Group Code" := TaxGroup.Code;
        GLAccount.Insert();
        // [GIVEN] Service Contract Account Group
        ServiceContractAccountGroup.Code := LibraryUTUtility.GetNewCode10;
        ServiceContractAccountGroup.Insert();
        // [WHEN] Validate "Non-Prepaid Contract Acc." Service Contract Account Group with X
        ServiceContractAccountGroup.Validate("Non-Prepaid Contract Acc.", GLAccount."No.");
        ServiceContractAccountGroup.Modify(true);
        // [THEN]
        ServiceContractAccountGroup.TestField("Non-Prepaid Contract Acc.", GLAccount."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateGLAccountPrepaidServiceContractAccountGroup()
    var
        ServiceContractAccountGroup: Record "Service Contract Account Group";
        GLAccount: Record "G/L Account";
        TaxGroup: Record "Tax Group";
    begin
        // [FEATURE] [Service Contract Account Group] [UT]
        // [SCENARIO 289828] Service Contract Account Group "Prepaid Contract Acc." can be validated only by GLAccount with Tax Group Code defined
        Initialize();
        // [GIVEN] GLAccount with Tax Group Code defined - X
        LibraryERM.CreateTaxGroup(TaxGroup);
        GLAccount."No." := LibraryUTUtility.GetNewCode;
        GLAccount."Tax Group Code" := TaxGroup.Code;
        GLAccount.Insert();
        // [GIVEN] Service Contract Account Group
        ServiceContractAccountGroup.Code := LibraryUTUtility.GetNewCode10;
        ServiceContractAccountGroup.Insert();
        // [WHEN] Validate "Prepaid Contract Acc." on Service Contract Account Group with X
        ServiceContractAccountGroup.Validate("Prepaid Contract Acc.", GLAccount."No.");
        ServiceContractAccountGroup.Modify(true);
        // [THEN]
        ServiceContractAccountGroup.TestField("Prepaid Contract Acc.", GLAccount."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateGLAccountPrepaidServiceContractAccountGroupFails()
    var
        ServiceContractAccountGroup: Record "Service Contract Account Group";
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] [Service Contract Account Group] [UT]
        // [SCENARIO 289828] Service Contract Account Group "Prepaid Contract Acc." can be validated only by GLAccount with Tax Group Code defined
        Initialize();
        // [GIVEN] GLAccount with Tax Group Code undefined - X
        GLAccount."No." := LibraryUTUtility.GetNewCode;
        GLAccount.Insert();
        // [GIVEN] Service Contract Account Group
        ServiceContractAccountGroup.Code := LibraryUTUtility.GetNewCode10;
        ServiceContractAccountGroup.Insert();

        // [WHEN] Validate "Prepaid Contract Acc." on Service Contract Account Group with X
        // [THEN] Error is shown
        asserterror ServiceContractAccountGroup.Validate("Prepaid Contract Acc.", GLAccount."No.");
        Assert.ExpectedError(StrSubstNo(ExpectedTaxGroupCodeErr, GLAccount."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATRegistrationNoVisibility()
    var
        CompanyInformationPage: TestPage "Company Information";
    begin
        // [FEATURE] [Application Area]
        // [SCENARIO 382787] "VAT Registration No." is visible/editable on Company Information page in SaaS
        Initialize();

        // [GIVEN] Enabled SaaS setup       
        LibraryPermissions.SetTestabilitySoftwareAsAService(true);

        // [WHEN] Vendor List page
        CompanyInformationPage.OpenEdit();

        // [THEN] Otstanding PO reports are available        
        Assert.IsTrue(CompanyInformationPage."VAT Registration No.".Visible, '');
        Assert.IsTrue(CompanyInformationPage."VAT Registration No.".Editable, '');
        CompanyInformationPage.Close();
        LibraryPermissions.SetTestabilitySoftwareAsAService(false);
    end;

    local procedure Initialize()
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.DeleteAll();
        LibrarySetupStorage.Restore();
        LibraryApplicationArea.EnableFoundationSetup();

        if IsInitialized then
            exit;

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibraryERMCountryData.CreateVATData();
        CreateVATPostingSetup;

        IsInitialized := true;
        Commit();
    end;

    local procedure CreateCustomer(var Customer: Record Customer)
    begin
        Customer."No." := LibraryUTUtility.GetNewCode;
        Customer."Tax Exemption No." := LibraryUTUtility.GetNewCode10;
        Customer."Customer Posting Group" := LibraryUTUtility.GetNewCode10;
        Customer."Gen. Bus. Posting Group" := LibraryUTUtility.GetNewCode10;
        Customer.Insert();
    end;

    local procedure CreateCost(var ServiceCost: Record "Service Cost")
    begin
        ServiceCost.Code := LibraryUTUtility.GetNewCode10;
        ServiceCost."Cost Type" := ServiceCost."Cost Type"::Travel;
        ServiceCost."Account No." := CreateGLAccount(LibraryUTUtility.GetNewCode10, '');
        ServiceCost.Insert();
    end;

    local procedure CreateGLAccount(GenProdPostingGroup: Code[20]; VATProdPostingGroup: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount."No." := LibraryUTUtility.GetNewCode;
        GLAccount."Gen. Prod. Posting Group" := GenProdPostingGroup;
        GLAccount."VAT Prod. Posting Group" := VATProdPostingGroup;
        GLAccount.Insert();
        exit(GLAccount."No.");
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Option; AccountType: Option; AccountNo: Code[20]; BalAccountType: Option; BalAccountNo: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GenJournalTemplate.Name := LibraryUTUtility.GetNewCode10;
        GenJournalTemplate.Insert();

        GenJournalBatch.Name := LibraryUTUtility.GetNewCode10;
        GenJournalBatch."Journal Template Name" := GenJournalTemplate.Name;
        GenJournalBatch.Insert();

        GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
        GenJournalLine."Document Type" := DocumentType;
        GenJournalLine."Account Type" := AccountType;
        GenJournalLine."Account No." := AccountNo;
        GenJournalLine."Bal. Account No." := BalAccountNo;
        GenJournalLine."Bal. Account Type" := BalAccountType;

        GenJournalLine.Insert();
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        Item."No." := LibraryUTUtility.GetNewCode;
        Item."Inventory Posting Group" := LibraryUTUtility.GetNewCode10;
        Item.Insert();
        exit(Item."No.");
    end;

    local procedure CreateIRSCode(): Code[10]
    var
        IRS1099FormBox: Record "IRS 1099 Form-Box";
    begin
        IRS1099FormBox.Code := LibraryUTUtility.GetNewCode10;
        IRS1099FormBox.Insert();
        exit(IRS1099FormBox.Code);
    end;

    local procedure CreateSalesTaxDifference(var SalesTaxDifference: Record "Sales Tax Amount Difference"; ServiceHeader: Record "Service Header")
    begin
        SalesTaxDifference."Document Product Area" := SalesTaxDifference."Document Product Area"::Sales;
        SalesTaxDifference."Document Type" := ServiceHeader."Document Type";
        SalesTaxDifference."Document No." := ServiceHeader."No.";
        SalesTaxDifference."Tax Area Code" := ServiceHeader."Tax Area Code";
        SalesTaxDifference.Insert();
    end;

    local procedure CreateServiceItem(CustomerNo: Code[20]; ItemNo: Code[20]): Code[20]
    var
        ServiceItem: Record "Service Item";
    begin
        ServiceItem."No." := LibraryUTUtility.GetNewCode;
        ServiceItem."Customer No." := CustomerNo;
        ServiceItem."Item No." := ItemNo;
        ServiceItem.Insert();
        exit(ServiceItem."No.");
    end;

    local procedure CreateServiceHeader(var ServiceHeader: Record "Service Header"; CustomerNo: Code[20]; TaxAreaCode: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        ServiceHeader."Document Type" := ServiceHeader."Document Type"::Order;
        ServiceHeader."No." := LibraryUTUtility.GetNewCode;
        ServiceHeader."Customer No." := CustomerNo;
        ServiceHeader."Bill-to Customer No." := CustomerNo;
        ServiceHeader."Tax Area Code" := TaxAreaCode;
        ServiceHeader."Gen. Bus. Posting Group" := Customer."Gen. Bus. Posting Group";
        ServiceHeader.Insert();
    end;

    local procedure CreateServiceOrder(var ServiceLine: Record "Service Line"; CustomerNo: Code[20]; Type: Option; No: Code[20]; TaxAreaCode: Code[20])
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLineNo: Integer;
    begin
        CreateServiceHeader(ServiceHeader, CustomerNo, TaxAreaCode);
        ServiceItemLineNo := CreateServiceItemLine(ServiceHeader, CreateServiceItem(CustomerNo, No), No);
        ServiceLine."Document Type" := ServiceHeader."Document Type";
        ServiceLine."Document No." := ServiceHeader."No.";
        ServiceLine."Line No." := LibraryRandom.RandInt(10);
        ServiceLine.Type := Type;
        ServiceLine."No." := No;
        ServiceLine."Service Item Line No." := ServiceItemLineNo;
        ServiceLine.Insert();
    end;

    local procedure CreateServiceItemLine(ServiceHeader: Record "Service Header"; ServiceItemNo: Code[20]; ItemNo: Code[20]): Integer
    var
        ServiceItemLine: Record "Service Item Line";
    begin
        ServiceItemLine."Document Type" := ServiceHeader."Document Type";
        ServiceItemLine."Document No." := ServiceHeader."No.";
        ServiceItemLine."Line No." := LibraryRandom.RandInt(10);
        ServiceItemLine."Service Item No." := ServiceItemNo;
        ServiceItemLine."Item No." := ItemNo;
        ServiceItemLine.Insert();
        exit(ServiceItemLine."Line No.");
    end;

    local procedure CreateTaxArea(Country: Option; UseExternalTaxEngine: Boolean): Code[20]
    var
        TaxArea: Record "Tax Area";
    begin
        TaxArea.Code := LibraryUTUtility.GetNewCode;
        TaxArea."Country/Region" := Country;
        TaxArea."Use External Tax Engine" := UseExternalTaxEngine;
        TaxArea.Insert();
        exit(TaxArea.Code);
    end;

    local procedure CreateVATPostingSetup()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Create Blank VAT Posting Setup with VAT Calculation Type - Sales Tax to fix CA, MX Country failure.
        if not VATPostingSetup.Get('', '') then
            LibraryERM.CreateVATPostingSetup(VATPostingSetup, '', '');
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Sales Tax");
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateVendor(var Vendor: Record Vendor)
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode;
        Vendor."IRS 1099 Code" := CreateIRSCode;
        Vendor.Insert();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

