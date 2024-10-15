codeunit 144017 "ERM VIP"
{
    // 1. Test to verify Suggest Vendor Payments report not create lines when Include Credit Memo is false.
    // 2. Test to verify Suggest Vendor Payments report create lines when Include Credit Memo is true.
    // 3. Test to verify Suggest Vendor Payments report not create lines when Include Credit Memo is false for Purchase Credit Memo.
    // 4. Test to verify Suggest Vendor Payments report create lines when Include Credit Memo is true for Purchase Credit Memo.
    // 
    // Covers Test Cases for WI - 350718.
    // --------------------------------------------------------------------
    // Test Function Name                                            TFS ID
    // --------------------------------------------------------------------
    // SuggestVendorPaymentWithIncludeCreditMemo              157073,157084
    // SuggestVendorPaymentWithoutIncludeCreditMemo           157073,157084
    // SuggestVendorPaymentPurchCrMemoWithIncludeCrMemo              157079
    // SuggestVendorPaymentPurchCrMemoWithoutIncludeCrMemo           157079

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        RecordExistsMsg: Label 'Payment Lines Created';

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentWithIncludeCreditMemo()
    begin
        // Test to verify Suggest Vendor Payments report not create lines when Include Credit Memo is false.
        SuggestVendorPaymentIncludeCreditMemo(false, false);  // False for Include Credit Memo and Record Created.
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentWithoutIncludeCreditMemo()
    begin
        // Test to verify Suggest Vendor Payments report create lines when Include Credit Memo is true.
        SuggestVendorPaymentIncludeCreditMemo(true, true);  // True for Include Credit Memo and Record Created.
    end;

    local procedure SuggestVendorPaymentIncludeCreditMemo(IncludeCreditMemo: Boolean; RecordExists: Boolean)
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
    begin
        // Setup: Create vendor and post General Journal with Document Type Invoice and Credit Memo.
        LibraryPurchase.CreateVendor(Vendor);
        CreateAndPostGenJournalLine(GenJournalLine, Vendor."No.");

        // Enqueue for SuggestVendorPaymentsRequestPageHandler.
        LibraryVariableStorage.Enqueue(IncludeCreditMemo);
        LibraryVariableStorage.Enqueue(Vendor."No.");

        // Exercise.
        SuggestVendorPayment(GenJournalLine);

        // Verify.
        VerifyJournalLinesSuggested(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", RecordExists);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentPurchCrMemoWithIncludeCrMemo()
    begin
        // Test to verify Suggest Vendor Payments report not create lines when Include Credit Memo is false for Purchase Credit Memo.
        SuggestVendorPaymentPurchCrMemoIncludeCreditMemo(false, false);  // False for Include Credit Memo and Record Created.
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentPurchCrMemoWithoutIncludeCrMemo()
    begin
        // Test to verify Suggest Vendor Payments report create lines when Include Credit Memo is true for Purchase Credit Memo.
        SuggestVendorPaymentPurchCrMemoIncludeCreditMemo(true, true);  // True for Include Credit Memo and Record Created.
    end;

    local procedure SuggestVendorPaymentPurchCrMemoIncludeCreditMemo(IncludeCreditMemo: Boolean; RecordExists: Boolean)
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
    begin
        // Setup: Create vendor and post Purchase Document Type Invoice and Credit Memo.
        LibraryPurchase.CreateVendor(Vendor);
        CreateAndPostPurchaseCreditMemoAfterInvoice(Vendor."No.");

        // Enqueue for SuggestVendorPaymentsRequestPageHandler.
        LibraryVariableStorage.Enqueue(IncludeCreditMemo);
        LibraryVariableStorage.Enqueue(Vendor."No.");

        // Exercise.
        SuggestVendorPayment(GenJournalLine);

        // Verify.
        VerifyJournalLinesSuggested(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", RecordExists);
    end;

    local procedure CreateAndPostGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Take Random Amount for Invoice and Amount greater than Invoice Amount for Credit Memo.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, VendorNo, -LibraryRandom.RandDec(100, 2));
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Account Type"::Vendor, VendorNo, -GenJournalLine.Amount + 1);  // Adding 1 to make amount larger than Invoice Amount.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostPurchaseCreditMemoAfterInvoice(VendorNo: Code[20])
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
    begin
        LibraryInventory.CreateItem(Item);
        CreateAndPostPurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Invoice, VendorNo, Item."No.",
          LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(100, 2));  // Using random for Quantity and Direct Unit Cost.
        CreateAndPostPurchaseDocument(
          PurchaseLine2, PurchaseLine2."Document Type"::"Credit Memo", VendorNo, Item."No.",
          PurchaseLine.Quantity, PurchaseLine."Direct Unit Cost");
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; DirectUnitCost: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", VendorNo);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // True for receive and invoice.
    end;

    local procedure SuggestVendorPayment(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        SuggestVendorPayments: Report "Suggest Vendor Payments";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        GenJournalLine.Validate("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.Validate("Journal Batch Name", GenJournalBatch.Name);
        Commit();  // Commit required to run report.
        SuggestVendorPayments.SetGenJnlLine(GenJournalLine);
        SuggestVendorPayments.Run;
    end;

    local procedure VerifyJournalLinesSuggested(JournalTemplateName: Code[10]; JournalBatchName: Code[10]; RecordExist: Boolean)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        GenJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        Assert.AreEqual(RecordExist, GenJournalLine.FindFirst, RecordExistsMsg);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentsRequestPageHandler(var SuggestVendorPayments: TestRequestPage "Suggest Vendor Payments")
    var
        AlwaysInclCreditMemo: Variant;
        VendorNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(AlwaysInclCreditMemo);
        LibraryVariableStorage.Dequeue(VendorNo);
        SuggestVendorPayments.Vendor.SetFilter("No.", VendorNo);
        SuggestVendorPayments.LastPaymentDate.SetValue(WorkDate);
        SuggestVendorPayments.AlwaysInclCreditMemo.SetValue(AlwaysInclCreditMemo);
        SuggestVendorPayments.StartingDocumentNo.SetValue(VendorNo);  // Value is not important.
        SuggestVendorPayments.OK.Invoke;
    end;
}

