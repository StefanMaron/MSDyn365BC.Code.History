codeunit 142054 SalesDocTotalsWithSalesTax
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Sales] [Document Totals]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OriginalSalesLine: Record "Sales Line";
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
        SalesInvoice: TestPage "Sales Invoice";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        InvDiscAmtPct: Decimal;
        TaxPercentage: Integer;
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
        FieldType: Option ,InvoiceDiscountAmount,TotalAmountExcTax,TaxAmount,TotalAmountIncTax,DiscountPercent;
        TotalTax: Decimal;
    begin
        // [SCENARIO 136984] For page Mini Sales Invoice Subform (1305) Entry
        // Setup
        Initialize;
        TaxPercentage := LibraryRandom.RandInt(9);
        InvDiscAmtPct := LibraryRandom.RandDecInDecimalRange(0.01, 0.09, 1);

        // [GIVEN] User has created a sales document with a sales line containing sales tax
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Invoice, TaxGroupCode, TaxPercentage, TaxAreaCode);

        // Store away the line created, to pull back in later
        OriginalSalesLine := SalesLine;
        RoundingPrecision := 0.01;

        LibraryLowerPermissions.SetSalesDocsCreate;
        SalesHeader.Get(OriginalSalesLine."Document Type", OriginalSalesLine."Document No.");
        OpenSalesInvoicePageEdit(SalesInvoice, SalesHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(SalesInvoice.SalesLines."Invoice Discount Amount".AsDEcimal,
          SalesInvoice.SalesLines."Total Amount Excl. VAT".AsDEcimal,
          SalesInvoice.SalesLines."Total VAT Amount".AsDEcimal,
          SalesInvoice.SalesLines."Total Amount Incl. VAT".AsDEcimal,
          0,
          PreAmounts);
        SalesInvoice.Close;

        SalesLine.Validate("Tax Group Code", TaxGroupCode);
        SalesLine.Modify(true);

        OpenSalesInvoicePageEdit(SalesInvoice, SalesHeader);
        SalesInvoice.SalesLines."Invoice Discount Amount".AssertEquals(0);

        // [WHEN] User sets the Invoice Discount Amount
        SalesInvoice.SalesLines."Invoice Discount Amount".SetValue(
          SalesInvoice.SalesLines."Total Amount Excl. VAT".AsDEcimal * InvDiscAmtPct);
        SalesInvoice.Close;

        // [THEN] Total amounts match Sales Header amounts
        // Reopen the window with the updated record
        OpenSalesInvoicePageView(SalesInvoice, SalesHeader);

        SetCompareAmounts(SalesInvoice.SalesLines."Invoice Discount Amount".AsDEcimal,
          SalesInvoice.SalesLines."Total Amount Excl. VAT".AsDEcimal,
          SalesInvoice.SalesLines."Total VAT Amount".AsDEcimal,
          SalesInvoice.SalesLines."Total Amount Incl. VAT".AsDEcimal,
          SalesInvoice.SalesLines."Invoice Disc. Pct.".AsDEcimal,
          PostAmounts);

        // Calculate the CustInvoiceDiscountPct, TotalTax, and flowfields
        SalesLine := OriginalSalesLine;
        SalesLine.Find;
        PreAmounts[FieldType::DiscountPercent] := SalesCalcDiscountByType.GetCustInvoiceDiscountPct(SalesLine);
        SalesHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := SalesHeader."Amount Including VAT" - SalesHeader.Amount;

        VerifyFieldValues(SalesHeader, PreAmounts, PostAmounts, TotalTax, RoundingPrecision);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoicePosting()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        OriginalSalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
        SalesHeaderAmounts: array[5] of Decimal;
        SalesPostedAmounts: array[5] of Decimal;
        InvDiscAmtPct: Decimal;
        TaxPercentage: Integer;
        PostedSalesDocNo: Code[20];
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [SCENARIO 136984] For page Sales Invoice Subform (43) Posting
        // Setup
        Initialize;
        TaxPercentage := LibraryRandom.RandInt(9);
        InvDiscAmtPct := LibraryRandom.RandDecInDecimalRange(0.01, 0.09, 1);

        // [GIVEN] User has created a sales document with a sales line containing sales tax
        LibraryLowerPermissions.SetSalesDocsCreate;
        LibraryLowerPermissions.AddO365Setup;
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Invoice, TaxGroupCode, TaxPercentage, TaxAreaCode);

        // Store away the line created, to pull back in later
        OriginalSalesLine := SalesLine;

        SalesLine.Validate("Tax Group Code", TaxGroupCode);
        SalesLine.Modify(true);

        SalesHeader.Get(OriginalSalesLine."Document Type", OriginalSalesLine."Document No.");
        OpenSalesInvoicePageEdit(SalesInvoice, SalesHeader);
        SalesInvoice.SalesLines."Invoice Discount Amount".SetValue(
          SalesInvoice.SalesLines."Total Amount Excl. VAT".AsDEcimal * InvDiscAmtPct);
        SalesInvoice.Close;

        // Reopen the window with the updated record
        OpenSalesInvoicePageView(SalesInvoice, SalesHeader);

        // Calculate the CustInvoiceDiscountPct, TotalTax, and flowfields
        SalesLine := OriginalSalesLine;
        SalesLine.Find;
        SalesHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");

        SetCompareAmounts(SalesHeader."Invoice Discount Amount",
          SalesHeader.Amount,
          SalesHeader."Amount Including VAT" - SalesHeader.Amount,
          SalesHeader."Amount Including VAT", 0, SalesHeaderAmounts);

        // [WHEN] User posts the Sales Invoice
        LibraryLowerPermissions.SetSalesDocsPost;
        PostedSalesDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Invoice.

        // [THEN] Posted amounts should match the pre-posted amounts
        SalesInvoiceHeader.Get(PostedSalesDocNo);
        SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT", "Invoice Discount Amount");
        SetCompareAmounts(SalesInvoiceHeader."Invoice Discount Amount",
          SalesInvoiceHeader.Amount,
          SalesInvoiceHeader."Amount Including VAT" - SalesInvoiceHeader.Amount,
          SalesInvoiceHeader."Amount Including VAT", 0, SalesPostedAmounts);

        VerifyPostedFieldValues(SalesHeaderAmounts, SalesPostedAmounts);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OriginalSalesLine: Record "Sales Line";
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        InvDiscAmtPct: Decimal;
        TaxPercentage: Integer;
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
        FieldType: Option ,InvoiceDiscountAmount,TotalAmountExcTax,TaxAmount,TotalAmountIncTax,DiscountPercent;
        TotalTax: Decimal;
    begin
        // [SCENARIO 136984] For page Mini Sales Credit Memo Subform (1320) Entry
        // Setup
        Initialize;
        TaxPercentage := LibraryRandom.RandInt(9);
        InvDiscAmtPct := LibraryRandom.RandDecInDecimalRange(0.01, 0.09, 1);

        // [GIVEN] User has created a sales document with a sales line containing sales tax
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::"Credit Memo", TaxGroupCode, TaxPercentage, TaxAreaCode);

        // Store away the line created, to pull back in later
        OriginalSalesLine := SalesLine;
        RoundingPrecision := 0.01;

        LibraryLowerPermissions.SetSalesDocsCreate;
        SalesHeader.Get(OriginalSalesLine."Document Type", OriginalSalesLine."Document No.");
        OpenSalesCrMemoPageEdit(SalesCreditMemo, SalesHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(SalesCreditMemo.SalesLines."Invoice Discount Amount".AsDEcimal,
          SalesCreditMemo.SalesLines."Total Amount Excl. VAT".AsDEcimal,
          SalesCreditMemo.SalesLines."Total VAT Amount".AsDEcimal,
          SalesCreditMemo.SalesLines."Total Amount Incl. VAT".AsDEcimal,
          0,
          PreAmounts);
        SalesCreditMemo.Close;

        SalesLine.Validate("Tax Group Code", TaxGroupCode);
        SalesLine.Modify(true);

        OpenSalesCrMemoPageEdit(SalesCreditMemo, SalesHeader);
        SalesCreditMemo.SalesLines."Invoice Discount Amount".AssertEquals(0);

        // [WHEN] User sets the Invoice Discount Amount and Tax Group Code
        SalesCreditMemo.SalesLines."Invoice Discount Amount".SetValue(
          SalesCreditMemo.SalesLines."Total Amount Excl. VAT".AsDEcimal * InvDiscAmtPct);
        SalesCreditMemo.Close;

        // [THEN] Total amounts match Sales Header amounts
        // Reopen the window with the updated record
        OpenSalesCrMemoPageView(SalesCreditMemo, SalesHeader);

        SetCompareAmounts(SalesCreditMemo.SalesLines."Invoice Discount Amount".AsDEcimal,
          SalesCreditMemo.SalesLines."Total Amount Excl. VAT".AsDEcimal,
          SalesCreditMemo.SalesLines."Total VAT Amount".AsDEcimal,
          SalesCreditMemo.SalesLines."Total Amount Incl. VAT".AsDEcimal,
          SalesCreditMemo.SalesLines."Invoice Disc. Pct.".AsDEcimal,
          PostAmounts);

        // Calculate the CustInvoiceDiscountPct, TotalTax, and flowfields
        SalesLine := OriginalSalesLine;
        SalesLine.Find;
        PreAmounts[FieldType::DiscountPercent] := SalesCalcDiscountByType.GetCustInvoiceDiscountPct(SalesLine);
        SalesHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := SalesHeader."Amount Including VAT" - SalesHeader.Amount;

        VerifyFieldValues(SalesHeader, PreAmounts, PostAmounts, TotalTax, RoundingPrecision);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoPosting()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OriginalSalesLine: Record "Sales Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        SalesHeaderAmounts: array[5] of Decimal;
        SalesPostedAmounts: array[5] of Decimal;
        InvDiscAmtPct: Decimal;
        TaxPercentage: Integer;
        PostedSalesDocNo: Code[20];
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [SCENARIO 136984] For page Mini Sales Credit Memo Subform (1320) Posting
        // Setup
        Initialize;
        TaxPercentage := LibraryRandom.RandInt(9);
        InvDiscAmtPct := LibraryRandom.RandDecInDecimalRange(0.01, 0.09, 1);

        // [GIVEN] User has created a sales document with a sales line containing sales tax
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::"Credit Memo", TaxGroupCode, TaxPercentage, TaxAreaCode);

        // Store away the line created, to pull back in later
        LibraryLowerPermissions.SetSalesDocsPost;
        OriginalSalesLine := SalesLine;

        SalesLine.Validate("Tax Group Code", TaxGroupCode);
        SalesLine.Modify(true);

        SalesHeader.Get(OriginalSalesLine."Document Type", OriginalSalesLine."Document No.");
        OpenSalesCrMemoPageEdit(SalesCreditMemo, SalesHeader);
        SalesCreditMemo.SalesLines."Invoice Discount Amount".SetValue(
          SalesCreditMemo.SalesLines."Total Amount Excl. VAT".AsDEcimal * InvDiscAmtPct);
        SalesCreditMemo.Close;

        // Reopen the window with the updated record
        OpenSalesCrMemoPageView(SalesCreditMemo, SalesHeader);

        // Calculate the CustInvoiceDiscountPct, TotalTax, and flowfields
        SalesLine := OriginalSalesLine;
        SalesLine.Find;
        SalesHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");

        SetCompareAmounts(SalesHeader."Invoice Discount Amount",
          SalesHeader.Amount,
          SalesHeader."Amount Including VAT" - SalesHeader.Amount,
          SalesHeader."Amount Including VAT", 0, SalesHeaderAmounts);

        // [WHEN] User posts the Sales Credit Memo
        PostedSalesDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] Posted amounts should match the pre-posted amounts
        SalesCrMemoHeader.Get(PostedSalesDocNo);
        SalesCrMemoHeader.CalcFields(Amount, "Amount Including VAT", "Invoice Discount Amount");
        SetCompareAmounts(SalesCrMemoHeader."Invoice Discount Amount",
          SalesCrMemoHeader.Amount,
          SalesCrMemoHeader."Amount Including VAT" - SalesCrMemoHeader.Amount,
          SalesCrMemoHeader."Amount Including VAT", 0, SalesPostedAmounts);

        VerifyPostedFieldValues(SalesHeaderAmounts, SalesPostedAmounts);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuote()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OriginalSalesLine: Record "Sales Line";
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
        SalesQuote: TestPage "Sales Quote";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        InvDiscAmtPct: Decimal;
        TaxPercentage: Integer;
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
        FieldType: Option ,InvoiceDiscountAmount,TotalAmountExcTax,TaxAmount,TotalAmountIncTax,DiscountPercent;
        TotalTax: Decimal;
    begin
        // [SCENARIO 136984] For page Mini Sales Quote Subform (1325) Entry
        // Setup
        Initialize;
        TaxPercentage := LibraryRandom.RandInt(9);
        InvDiscAmtPct := LibraryRandom.RandDecInDecimalRange(0.01, 0.09, 1);

        // [GIVEN] User has created a sales document with a sales line containing sales tax
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Quote, TaxGroupCode, TaxPercentage, TaxAreaCode);

        // Store away the line created, to pull back in later
        LibraryLowerPermissions.SetSalesDocsPost;
        OriginalSalesLine := SalesLine;
        RoundingPrecision := 0.01;

        SalesHeader.Get(OriginalSalesLine."Document Type", OriginalSalesLine."Document No.");
        OpenSalesQuotePageEdit(SalesQuote, SalesHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(SalesQuote.SalesLines."Invoice Discount Amount".AsDEcimal,
          SalesQuote.SalesLines."Total Amount Excl. VAT".AsDEcimal,
          SalesQuote.SalesLines."Total VAT Amount".AsDEcimal,
          SalesQuote.SalesLines."Total Amount Incl. VAT".AsDEcimal,
          0,
          PreAmounts);
        SalesQuote.Close;

        SalesLine.Validate("Tax Group Code", TaxGroupCode);
        SalesLine.Modify(true);

        OpenSalesQuotePageEdit(SalesQuote, SalesHeader);
        SalesQuote.SalesLines."Invoice Discount Amount".AssertEquals(0);

        // [WHEN] User sets the Invoice Discount Amount and Tax Group Code
        SalesQuote.SalesLines."Invoice Discount Amount".SetValue(
          SalesQuote.SalesLines."Total Amount Excl. VAT".AsDEcimal * InvDiscAmtPct);
        SalesQuote.Close;

        // [THEN] Total amounts match Sales Header amounts
        // Reopen the window with the updated record
        OpenSalesQuotePageView(SalesQuote, SalesHeader);

        SetCompareAmounts(SalesQuote.SalesLines."Invoice Discount Amount".AsDEcimal,
          SalesQuote.SalesLines."Total Amount Excl. VAT".AsDEcimal,
          SalesQuote.SalesLines."Total VAT Amount".AsDEcimal,
          SalesQuote.SalesLines."Total Amount Incl. VAT".AsDEcimal,
          SalesQuote.SalesLines."Invoice Disc. Pct.".AsDEcimal,
          PostAmounts);

        // Calculate the CustInvoiceDiscountPct, TotalTax, and flowfields
        SalesLine := OriginalSalesLine;
        SalesLine.Find;
        PreAmounts[FieldType::DiscountPercent] := SalesCalcDiscountByType.GetCustInvoiceDiscountPct(SalesLine);
        SalesHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := SalesHeader."Amount Including VAT" - SalesHeader.Amount;

        VerifyFieldValues(SalesHeader, PreAmounts, PostAmounts, TotalTax, RoundingPrecision);
    end;

    local procedure CreateCustomer(TaxAreaCode: Code[20]): Code[20]
    var
        Customer: Record Customer;
        PostCode: Record "Post Code";
    begin
        LibraryERM.CreatePostCode(PostCode);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", '');
        Customer.Validate("Tax Liable", true);
        Customer.Validate("Tax Area Code", TaxAreaCode);
        Customer.Validate("Tax Identification Type", Customer."Tax Identification Type"::"Legal Entity");
        Customer.Validate("RFC No.", GetRandomCode(LibraryUtility.GetFieldLength(DATABASE::Customer, Customer.FieldNo("RFC No.")) - 1));  // Taken Length less than RFC No. Length as Tax Identification Type is Legal Entity.
        Customer.Validate("CURP No.", GetRandomCode(LibraryUtility.GetFieldLength(DATABASE::Customer, Customer.FieldNo("CURP No."))));
        Customer.Validate("Post Code", PostCode.Code);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure Initialize()
    var
        InventorySetup: Record "Inventory Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        LibraryApplicationArea.EnableFoundationSetup;

        if isInitialized then
            exit;

        InstructionMgt.DisableMessageForCurrentUser(InstructionMgt.QueryPostOnCloseCode);

        LibraryERMCountryData.CreateVATData;
        Clear(VATPostingSetup);
        if not VATPostingSetup.Get('', '') then begin
            VATPostingSetup."VAT Bus. Posting Group" := '';
            VATPostingSetup."VAT Prod. Posting Group" := '';
            VATPostingSetup."VAT Calculation Type" := VATPostingSetup."VAT Calculation Type"::"Sales Tax";
            VATPostingSetup.Insert(true);
        end;
        LibraryInventory.NoSeriesSetup(InventorySetup);

        isInitialized := true;
        Commit;
    end;

    local procedure CreateItem(TaxGroupCode: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", '');
        Item.Validate("Unit Price", LibraryRandom.RandInt(10));  // Using RANDOM value for Unit Price.
        Item.Validate("Tax Group Code", TaxGroupCode);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Option; CustomerNo: Code[20]; TaxAreaCode: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader."Tax Area Code" := TaxAreaCode;
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesTaxDetail(var TaxDetail: Record "Tax Detail"; TaxPercentage: Integer)
    var
        TaxGroup: Record "Tax Group";
    begin
        LibraryERM.CreateTaxGroup(TaxGroup);
        LibraryERM.CreateTaxDetail(TaxDetail, CreateSalesTaxJurisdiction, TaxGroup.Code, TaxDetail."Tax Type"::"Sales Tax Only", WorkDate);
        TaxDetail.Validate("Tax Below Maximum", TaxPercentage);  // Using RANDOM value for Tax Below Maximum.
        TaxDetail.Modify(true);
    end;

    local procedure CreateSalesTaxJurisdiction(): Code[10]
    var
        GLAccount: Record "G/L Account";
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        LibraryERM.CreateTaxJurisdiction(TaxJurisdiction);
        LibraryERM.CreateGLAccount(GLAccount);
        TaxJurisdiction.Validate("Tax Account (Sales)", GLAccount."No.");
        TaxJurisdiction.Validate("Tax Account (Purchases)", GLAccount."No.");
        TaxJurisdiction.Validate("Reverse Charge (Purchases)", GLAccount."No.");
        TaxJurisdiction.Validate("Report-to Jurisdiction", TaxJurisdiction.Code);
        TaxJurisdiction.Modify(true);
        exit(TaxJurisdiction.Code);
    end;

    local procedure CreateTaxAreaLine(var TaxDetail: Record "Tax Detail"; TaxPercentage: Integer): Code[20]
    var
        TaxArea: Record "Tax Area";
        TaxAreaLine: Record "Tax Area Line";
    begin
        CreateSalesTaxDetail(TaxDetail, TaxPercentage);
        LibraryERM.CreateTaxArea(TaxArea);
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxArea.Code, TaxDetail."Tax Jurisdiction Code");
        exit(TaxArea.Code);
    end;

    local procedure CreateSalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Option; var TaxGroupCode: Code[20]; TaxPercentage: Integer; var TaxAreaCode: Code[20]): Decimal
    var
        TaxDetail: Record "Tax Detail";
    begin
        TaxAreaCode := CreateTaxAreaLine(TaxDetail, TaxPercentage);
        TaxGroupCode := TaxDetail."Tax Group Code";
        exit(CreateSalesDocumentWithCertainTax(SalesLine, DocumentType, TaxDetail, TaxAreaCode, TaxGroupCode));
    end;

    local procedure CreateSalesDocumentWithCertainTax(var SalesLine: Record "Sales Line"; DocumentType: Option; TaxDetail: Record "Tax Detail"; TaxAreaCode: Code[20]; TaxGroupCode: Code[20]): Decimal
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer(TaxAreaCode), TaxAreaCode);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item,
          CreateItem(TaxGroupCode),
          LibraryRandom.RandInt(10));  // Using RANDOM value for Quantity.
        exit(TaxDetail."Tax Below Maximum");
    end;

    local procedure GetRandomCode(FieldLength: Integer) RandomCode: Code[20]
    begin
        RandomCode := LibraryUtility.GenerateGUID;
        repeat
            RandomCode += Format(LibraryRandom.RandInt(9));  // Generating any Random integer value.
        until StrLen(RandomCode) = FieldLength;
    end;

    local procedure OpenSalesCrMemoPageEdit(var SalesCreditMemo: TestPage "Sales Credit Memo"; SalesHeader: Record "Sales Header")
    begin
        SalesCreditMemo.OpenEdit;
        SalesCreditMemo.GotoRecord(SalesHeader);
    end;

    local procedure OpenSalesInvoicePageEdit(var SalesInvoice: TestPage "Sales Invoice"; SalesHeader: Record "Sales Header")
    begin
        SalesInvoice.OpenEdit;
        SalesInvoice.GotoRecord(SalesHeader);
    end;

    local procedure OpenSalesQuotePageEdit(var SalesQuote: TestPage "Sales Quote"; SalesHeader: Record "Sales Header")
    begin
        SalesQuote.OpenEdit;
        SalesQuote.GotoRecord(SalesHeader);
    end;

    local procedure OpenSalesCrMemoPageView(var SalesCreditMemo: TestPage "Sales Credit Memo"; SalesHeader: Record "Sales Header")
    begin
        SalesCreditMemo.OpenView;
        SalesCreditMemo.GotoRecord(SalesHeader);
    end;

    local procedure OpenSalesInvoicePageView(var SalesInvoice: TestPage "Sales Invoice"; SalesHeader: Record "Sales Header")
    begin
        SalesInvoice.OpenView;
        SalesInvoice.GotoRecord(SalesHeader);
    end;

    local procedure OpenSalesQuotePageView(var SalesQuote: TestPage "Sales Quote"; SalesHeader: Record "Sales Header")
    begin
        SalesQuote.OpenView;
        SalesQuote.GotoRecord(SalesHeader);
    end;

    local procedure SetCompareAmounts(InvoiceDiscountAmount: Decimal; TotalAmountExcTax: Decimal; TaxAmount: Decimal; TotalAmountIncTax: Decimal; CustDiscountPercent: Decimal; var Amounts: array[5] of Decimal)
    var
        FieldType: Option ,InvoiceDiscountAmount,TotalAmountExcTax,TaxAmount,TotalAmountIncTax,DiscountPercent;
    begin
        Amounts[FieldType::InvoiceDiscountAmount] := InvoiceDiscountAmount;
        Amounts[FieldType::TotalAmountExcTax] := TotalAmountExcTax;
        Amounts[FieldType::TaxAmount] := TaxAmount;
        Amounts[FieldType::TotalAmountIncTax] := TotalAmountIncTax;
        Amounts[FieldType::DiscountPercent] := CustDiscountPercent;
    end;

    local procedure VerifyFieldValues(SalesHeader: Record "Sales Header"; PreAmounts: array[5] of Decimal; PostAmounts: array[5] of Decimal; TotalTax: Decimal; RoundingPrecision: Decimal)
    var
        Assert: Codeunit Assert;
        FieldType: Option ,InvoiceDiscountAmount,TotalAmountExcTax,TaxAmount,TotalAmountIncTax,DiscountPercent;
    begin
        Assert.AreNotEqual(
          PreAmounts[FieldType::TotalAmountExcTax],
          PostAmounts[FieldType::TotalAmountExcTax],
          'Before and after amounts for Total Amount Excluding Tax should not be equal');
        Assert.AreNotEqual(
          PreAmounts[FieldType::TotalAmountIncTax],
          PostAmounts[FieldType::TotalAmountIncTax],
          'Before and after amounts for Total Amount Including Tax should not be equal');
        Assert.AreEqual(
          PreAmounts[FieldType::TaxAmount],
          PostAmounts[FieldType::TaxAmount],
          'Before and after amounts for Tax Amount should not be equal');

        Assert.AreNearlyEqual(
          PostAmounts[FieldType::InvoiceDiscountAmount],
          SalesHeader."Invoice Discount Amount",
          RoundingPrecision,
          'An incorrect Invoice Discount Amount was saved');
        Assert.AreNearlyEqual(
          PostAmounts[FieldType::TotalAmountExcTax],
          SalesHeader.Amount,
          RoundingPrecision,
          'An incorrect Total Amount was saved');
        Assert.AreNearlyEqual(
          PostAmounts[FieldType::TotalAmountIncTax],
          SalesHeader."Amount Including VAT",
          RoundingPrecision,
          'An incorrect Total Amount Including Tax was saved');
        Assert.AreNearlyEqual(
          PostAmounts[FieldType::TaxAmount],
          TotalTax,
          RoundingPrecision,
          'An incorrect Tax Amount was saved');
        Assert.AreNearlyEqual(
          PostAmounts[FieldType::DiscountPercent],
          PreAmounts[FieldType::DiscountPercent],
          RoundingPrecision,
          'Customer Discount Percent value is incorrect');
    end;

    local procedure VerifyPostedFieldValues(SalesHeaderAmounts: array[5] of Decimal; SalesPostedAmounts: array[5] of Decimal)
    var
        Assert: Codeunit Assert;
        FieldType: Option ,InvoiceDiscountAmount,TotalAmountExcTax,TaxAmount,TotalAmountIncTax,DiscountPercent;
    begin
        Assert.AreEqual(SalesHeaderAmounts[FieldType::InvoiceDiscountAmount], SalesPostedAmounts[FieldType::InvoiceDiscountAmount],
          'Posted Invoice Discount Amount not equal to pre-posted value.');
        Assert.AreEqual(SalesHeaderAmounts[FieldType::TotalAmountExcTax], SalesPostedAmounts[FieldType::TotalAmountExcTax],
          'Posted Total Amount Excluding Tax not equal to pre-posted value.');
        Assert.AreEqual(SalesHeaderAmounts[FieldType::TaxAmount], SalesPostedAmounts[FieldType::TaxAmount],
          'Posted Tax Amount not equal to pre-posted value.');
        Assert.AreEqual(SalesHeaderAmounts[FieldType::TotalAmountIncTax], SalesPostedAmounts[FieldType::TotalAmountIncTax],
          'Posted Total Amount Including Tax not equal to pre-posted value.');
    end;
}

