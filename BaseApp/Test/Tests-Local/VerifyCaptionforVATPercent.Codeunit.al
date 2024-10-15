codeunit 144060 "Verify Caption for VAT Percent"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Customer: Record Customer;
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('InvoiceReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyVATCaptionBlankAndOneNormalVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
        ItemNo: Code[20];
        UnitPrice: Decimal;
        Quantity: Integer;
    begin
        // SETUP
        Initialize;

        // Create And Post Sales Invoice with 2 Lines: Blank + VAT
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        // Line 1 - Blank
        CreateEmptySalesLine(SalesHeader);

        // Line 2 - Normal VAT
        UnitPrice := LibraryRandom.RandDec(10000, 2);
        Quantity := LibraryRandom.RandInt(10);
        ItemNo := CreateItem;
        CreateSalesLine(SalesHeader, SalesLine.Type::Item, ItemNo, Quantity, UnitPrice, FindNonZeroVATProdPostingGroup1);

        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, false, false);
        Commit();

        // Run Report
        SalesInvoiceHeader.SetRange("No.", DocumentNo);
        SalesInvoiceHeader.FindFirst;
        REPORT.Run(REPORT::"Sales - Invoice", true, false, SalesInvoiceHeader);

        // Validate Report
        VerifySalesDocumentReportData(SalesInvoiceHeader);
    end;

    [Test]
    [HandlerFunctions('InvoiceReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyVATCaptionBothNoVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
        ItemNo: Code[20];
        UnitPrice: Decimal;
        Quantity: Integer;
    begin
        // SETUP
        Initialize;

        // Create And Post Sales Invoice with 2 Lines: Both with no VAT
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        // Line 1 - Zero VAT
        UnitPrice := LibraryRandom.RandDec(10000, 2);
        Quantity := LibraryRandom.RandInt(10);
        ItemNo := CreateItem;
        CreateSalesLine(SalesHeader, SalesLine.Type::Item, ItemNo, Quantity, UnitPrice, FindZeroVATProdPostingGroup);

        // Line 2 - Zero VAT
        UnitPrice := LibraryRandom.RandDec(10000, 2);
        Quantity := LibraryRandom.RandInt(10);
        ItemNo := CreateItem;
        CreateSalesLine(SalesHeader, SalesLine.Type::Item, ItemNo, Quantity, UnitPrice, FindZeroVATProdPostingGroup);

        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, false, false);
        Commit();

        // Run Report
        SalesInvoiceHeader.SetRange("No.", DocumentNo);
        SalesInvoiceHeader.FindFirst;
        REPORT.Run(REPORT::"Sales - Invoice", true, false, SalesInvoiceHeader);

        // Validate Report
        VerifySalesDocumentReportData(SalesInvoiceHeader);
    end;

    [Test]
    [HandlerFunctions('InvoiceReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyVATCaptionBothNormalVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
        ItemNo: Code[20];
        UnitPrice: Decimal;
        Quantity: Integer;
    begin
        // SETUP
        Initialize;

        // Create And Post Sales Invoice with 2 Lines: Both normal VAT
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        // Line 1 - Normal VAT
        UnitPrice := LibraryRandom.RandDec(10000, 2);
        Quantity := LibraryRandom.RandInt(10);
        ItemNo := CreateItem;
        CreateSalesLine(SalesHeader, SalesLine.Type::Item, ItemNo, Quantity, UnitPrice, FindNonZeroVATProdPostingGroup1);

        // Line 2 - Normal VAT
        UnitPrice := LibraryRandom.RandDec(10000, 2);
        Quantity := LibraryRandom.RandInt(10);
        ItemNo := CreateItem;
        CreateSalesLine(SalesHeader, SalesLine.Type::Item, ItemNo, Quantity, UnitPrice, FindNonZeroVATProdPostingGroup1);

        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, false, false);
        Commit();

        // Run Report
        SalesInvoiceHeader.SetRange("No.", DocumentNo);
        SalesInvoiceHeader.FindFirst;
        REPORT.Run(REPORT::"Sales - Invoice", true, false, SalesInvoiceHeader);

        // Validate Report
        VerifySalesDocumentReportData(SalesInvoiceHeader);
    end;

    [Test]
    [HandlerFunctions('InvoiceReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyVATCaptionBothNormalVATAndNoVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
        ItemNo: Code[20];
        UnitPrice: Decimal;
        Quantity: Integer;
    begin
        // SETUP
        Initialize;

        // Create And Post Sales Invoice with 2 Lines: Both with no VAT
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        // Line 1 - Zero VAT
        UnitPrice := LibraryRandom.RandDec(10000, 2);
        Quantity := LibraryRandom.RandInt(10);
        ItemNo := CreateItem;
        CreateSalesLine(SalesHeader, SalesLine.Type::Item, ItemNo, Quantity, UnitPrice, FindNonZeroVATProdPostingGroup1);

        // Line 2 - Zero VAT
        UnitPrice := LibraryRandom.RandDec(10000, 2);
        Quantity := LibraryRandom.RandInt(10);
        ItemNo := CreateItem;
        CreateSalesLine(SalesHeader, SalesLine.Type::Item, ItemNo, Quantity, UnitPrice, FindZeroVATProdPostingGroup);

        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, false, false);
        Commit();

        // Run Report
        SalesInvoiceHeader.SetRange("No.", DocumentNo);
        SalesInvoiceHeader.FindFirst;
        REPORT.Run(REPORT::"Sales - Invoice", true, false, SalesInvoiceHeader);

        // Validate Report
        VerifySalesDocumentReportData(SalesInvoiceHeader);
    end;

    [Test]
    [HandlerFunctions('InvoiceReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyVATCaptionBothNormalVATAndNormalVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
        ItemNo: Code[20];
        UnitPrice: Decimal;
        Quantity: Integer;
    begin
        // SETUP
        Initialize;

        // Create And Post Sales Invoice with 2 Lines: Both normal VAT
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        // Line 1 - Normal VAT
        UnitPrice := LibraryRandom.RandDec(10000, 2);
        Quantity := LibraryRandom.RandInt(10);
        ItemNo := CreateItem;
        CreateSalesLine(SalesHeader, SalesLine.Type::Item, ItemNo, Quantity, UnitPrice, FindNonZeroVATProdPostingGroup1);

        // Line 2 - Normal VAT
        UnitPrice := LibraryRandom.RandDec(10000, 2);
        Quantity := LibraryRandom.RandInt(10);
        ItemNo := CreateItem;
        CreateSalesLine(SalesHeader, SalesLine.Type::Item, ItemNo, Quantity, UnitPrice, FindNonZeroVATProdPostingGroup2);

        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, false, false);
        Commit();

        // Run Report
        SalesInvoiceHeader.SetRange("No.", DocumentNo);
        SalesInvoiceHeader.FindFirst;
        REPORT.Run(REPORT::"Sales - Invoice", true, false, SalesInvoiceHeader);

        // Validate Report
        VerifySalesDocumentReportData(SalesInvoiceHeader);
    end;

    local procedure Initialize()
    begin
        if IsInitialized = true then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup;
        LibrarySales.CreateCustomer(Customer);

        IsInitialized := true;
    end;

    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; SalesLineType: Option; ItemNo: Code[20]; Quantity: Decimal; UnitPrice: Decimal; VatPostingGroup: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLineType, ItemNo, Quantity);
        if SalesLineType <> SalesLine.Type::" " then begin
            SalesLine.Validate("Unit Price", UnitPrice);
            SalesLine.Validate("VAT Prod. Posting Group", VatPostingGroup);
            SalesLine.Modify();
        end;
    end;

    local procedure CreateEmptySalesLine(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        RecRef: RecordRef;
    begin
        SalesLine.Init();
        SalesLine.Validate("Document Type", SalesHeader."Document Type");
        SalesLine.Validate("Document No.", SalesHeader."No.");
        RecRef.GetTable(SalesLine);
        SalesLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, SalesLine.FieldNo("Line No.")));
        SalesLine.Insert(true);

        SalesLine.Validate(Type, SalesLine.Type::" ");
        SalesLine.Validate(Description, 'Test');
        SalesLine.Modify(true);
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        exit(Item."No.");
    end;

    local procedure VerifySalesDocumentReportData(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        ElementValue: Variant;
        TotalLineAmountExclVAT: Decimal;
        TotalAllAmountExclVAT: Decimal;
        TotalVATAmount: Decimal;
    begin
        // Verify the XML
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.GetNextRow;

        with SalesInvoiceLine do begin
            SetRange("Document No.", SalesInvoiceHeader."No.");

            TotalAllAmountExclVAT := 0;
            TotalVATAmount := 0;
            if FindSet then
                repeat
                    LibraryReportDataset.GetNextRow;
                    if Type <> Type::" " then begin
                        LibraryReportDataset.AssertCurrentRowValueEquals('UnitPrice_SalesInvLine', "Unit Price");
                        TotalLineAmountExclVAT := "Unit Price" * Quantity;
                        LibraryReportDataset.AssertCurrentRowValueEquals('Amount_SalesInvoiceLine', TotalLineAmountExclVAT);
                        LibraryReportDataset.AssertCurrentRowValueEquals('VAT_SalesInvLine', "VAT %");
                        TotalAllAmountExclVAT += TotalLineAmountExclVAT;
                        TotalVATAmount += ("VAT %" * TotalLineAmountExclVAT) / 100;
                    end;
                until Next = 0;

            LibraryReportDataset.MoveToRow(Count + 1);
        end;

        TotalAllAmountExclVAT := Round(TotalAllAmountExclVAT, 0.01);
        TotalVATAmount := Round(TotalVATAmount, 0.01);

        LibraryReportDataset.GetElementValueInCurrentRow('TotalSubTotal', ElementValue);
        Assert.AreNearlyEqual(ElementValue, TotalAllAmountExclVAT, 0.5, 'Wrong Total Amount Excl. VAT');

        LibraryReportDataset.GetElementValueInCurrentRow('TotalAmountVAT', ElementValue);
        Assert.AreNearlyEqual(ElementValue, TotalVATAmount, 0.5, 'Wrong Total VAT Amount');
    end;

    local procedure FindNonZeroVATProdPostingGroup1(): Code[10]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetFilter("Sales VAT Account", '<>''''');
        VATPostingSetup.SetRange("VAT %", 1, 100);
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.SetRange("VAT Bus. Posting Group", Customer."VAT Bus. Posting Group");
        VATPostingSetup.FindFirst;
        exit(VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure FindNonZeroVATProdPostingGroup2(): Code[10]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetFilter("Sales VAT Account", '<>''''');
        VATPostingSetup.SetRange("VAT %", 1, 100);
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.SetRange("VAT Bus. Posting Group", Customer."VAT Bus. Posting Group");
        VATPostingSetup.FindSet;
        VATPostingSetup.Next;
        exit(VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure FindZeroVATProdPostingGroup(): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetFilter("Sales VAT Account", '<>''''');
        VATPostingSetup.SetRange("VAT %", 0);
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.SetRange("VAT Bus. Posting Group", Customer."VAT Bus. Posting Group");
        VATPostingSetup.FindFirst;
        exit(VATPostingSetup."VAT Prod. Posting Group");
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InvoiceReportRequestPageHandler(var SalesInvoice: TestRequestPage "Sales - Invoice")
    begin
        SalesInvoice.NoOfCopies.SetValue(0);
        SalesInvoice.ShowInternalInfo.SetValue(false);
        SalesInvoice.LogInteraction.SetValue(true);
        SalesInvoice.DisplayAsmInformation.SetValue(false);

        SalesInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;
}

