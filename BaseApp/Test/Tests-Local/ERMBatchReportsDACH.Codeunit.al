codeunit 142061 "ERM Batch Reports DACH"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    var
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntryVATEntryLinkForFASalesAccOnDispLoss()
    var
        GLEntry: Record "G/L Entry";
        FANo: Code[20];
        DocumentNo: Code[20];
        GLAccountNo: Code[20];
    begin
        // [FEATURE] [Fixed Asset] [VAT] [Sales] [G/L Entry - VAT Entry Link]
        // [SCENARIO 202344] VATEntry."G/L Account No." = FAPostingGroup."Sales Acc. on Disp. (Loss)" when post fixed asset sales invoice with "Depr. until FA Posting Date" = TRUE
        Initialize;

        // [GIVEN] Fixed Asset "FA" with "Sales Acc. on Disp. (Loss)" = "DispLossGLAcc", "Disposal Calculation Method" = "Gross", "VAT on Net Disposal Entries" = TRUE
        FANo := CreateFAWithBook;

        // [GIVEN] Posted purchase invoice fixed asset "FA" on "Posting Date" = 01-01-2019
        CreatePostFixedAssetPurchaseInvoice(WorkDate, FANo, LibraryRandom.RandDecInRange(10000, 20000, 2));

        // [WHEN] Post sales invoice "SI" fixed asset "FA" on "Posting Date" = 01-02-2019 with "Depr. until FA Posting Date" = TRUE
        DocumentNo := CreatePostFixedAssetSalesInvoice(CalcDate('<1M>', WorkDate), FANo, LibraryRandom.RandDecInRange(1000, 2000, 2));

        // [THEN] There is a GLEntry "X" with "Document Type" = "Invoice", "Document No." = "SI", "Gen. Posting Type" = "Sale", "G/L Account No." = "DispLossGLAcc"
        GLAccountNo := GetFASalesAccOnDispLoss(FANo);
        FindGLEntry(GLEntry, GLEntry."Document Type"::Invoice, DocumentNo, GLEntry."Gen. Posting Type"::Sale, GLAccountNo);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryVariableStorage.Clear;
        if IsInitialized then
            exit;

        IsInitialized := true;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        Commit;
    end;

    local procedure CreateFAWithBook(): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        DepreciationBook.Validate("Disposal Calculation Method", DepreciationBook."Disposal Calculation Method"::Gross);
        DepreciationBook.Validate("VAT on Net Disposal Entries", true);
        DepreciationBook.Validate("G/L Integration - Acq. Cost", true);
        DepreciationBook.Validate("G/L Integration - Depreciation", true);
        DepreciationBook.Validate("G/L Integration - Disposal", true);
        DepreciationBook.Modify(true);

        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DepreciationBook.Code);
        FADepreciationBook.Validate("FA Posting Group", FixedAsset."FA Posting Group");
        FADepreciationBook.Validate("Depreciation Starting Date", WorkDate);
        FADepreciationBook.Validate("No. of Depreciation Years", LibraryRandom.RandInt(5));
        FADepreciationBook.Modify(true);
        exit(FixedAsset."No.");
    end;

    local procedure CreatePostFixedAssetPurchaseInvoice(PostingDate: Date; FANo: Code[20]; DirectCost: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo);
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Fixed Asset", FANo, 1);
        PurchaseLine.Validate("Depreciation Book Code", GetFADeprBookCode(FANo));
        PurchaseLine.Validate("Direct Unit Cost", DirectCost);
        PurchaseLine.Modify(true);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreatePostFixedAssetSalesInvoice(PostingDate: Date; FANo: Code[20]; UnitPrice: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"Fixed Asset", FANo, 1);
        SalesLine.Validate("Depreciation Book Code", GetFADeprBookCode(FANo));
        SalesLine.Validate("Depr. until FA Posting Date", true);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);

        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure GetFASalesAccOnDispLoss(FANo: Code[20]): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
        FAPostingGroup: Record "FA Posting Group";
    begin
        FixedAsset.Get(FANo);
        FAPostingGroup.Get(FixedAsset."FA Posting Group");
        exit(FAPostingGroup."Sales Acc. on Disp. (Loss)");
    end;

    local procedure GetFADeprBookCode(FANo: Code[20]): Code[10]
    var
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        with FADepreciationBook do begin
            SetRange("FA No.", FANo);
            FindFirst;
            exit("Depreciation Book Code");
        end;
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocumentType: Option; DocumentNo: Code[20]; GenPostingType: Option; GLAccountNo: Code[20])
    begin
        with GLEntry do begin
            SetRange("Document Type", DocumentType);
            SetRange("Document No.", DocumentNo);
            SetRange("Gen. Posting Type", GenPostingType);
            SetRange("G/L Account No.", GLAccountNo);
            FindFirst;
        end;
    end;
}

