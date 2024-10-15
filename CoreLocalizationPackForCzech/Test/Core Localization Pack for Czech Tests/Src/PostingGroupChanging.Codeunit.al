codeunit 148055 "Posting Group Changing CZL"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        SalesSetup: Record "Sales & Receivables Setup";
        PurchaseSetup: Record "Purchases & Payables Setup";
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        CustomerPostingGroupOrigin: Record "Customer Posting Group";
        CustomerPostingGroupNew: Record "Customer Posting Group";
        VendorPostingGroupOrigin: Record "Vendor Posting Group";
        VendorPostingGroupNew: Record "Vendor Posting Group";
        Customer: Record Customer;
        Vendor: Record Vendor;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        BankAccountPostingGroupOrigin: Record "Bank Account Posting Group";
        BankAccountPostingGroupNew: Record "Bank Account Posting Group";
        BankAccount: Record "Bank Account";
        InventoryPostingGroupOrigin: Record "Inventory Posting Group";
        InventoryPostingGroupNew: Record "Inventory Posting Group";
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        SalesInvNo: Code[20];
        PurchInvNo: Code[20];
        DocumentType: Enum "Gen. Journal Document Type";
        AccountType: Enum "Gen. Journal Account Type";
        isInitialized: Boolean;

    local procedure Initialize();
    begin
        LibraryRandom.Init();
        if isInitialized then
            exit;

        SalesSetup.Get();
        SalesSetup."Default VAT Date CZL" := SalesSetup."Default VAT Date CZL"::"Posting Date";
        SalesSetup.Modify();

        PurchaseSetup.Get();
        PurchaseSetup."Default VAT Date CZL" := PurchaseSetup."Default VAT Date CZL"::"Posting Date";
        PurchaseSetup."Def. Orig. Doc. VAT Date CZL" := PurchaseSetup."Def. Orig. Doc. VAT Date CZL"::"Posting Date";
        PurchaseSetup.Modify();

        isInitialized := true;
        Commit();
    end;

    [Test]
    procedure CustomerPostingGroupChange()
    begin
        // [FEATURE] Change Posting Group
        Initialize();

        // [GIVEN] New Customer Posting Groups
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroupOrigin);
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroupNew);

        // [GIVEN] New Customer
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate(Customer."Customer Posting Group", CustomerPostingGroupOrigin.Code);
        Customer.Modify();

        // [GIVEN] New Sales Invoice
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, Customer."No.");
        SalesInvNo := LibrarySales.PostSalesDocument(SalesHeader, false, false);

        // [WHEN] Customer Posting Group Change 
        asserterror Customer.Validate("Customer Posting Group", CustomerPostingGroupNew.Code);

        // [THEN] Customer Posting Group not changed
        Assert.AreEqual(Customer."Customer Posting Group", CustomerPostingGroupOrigin.Code, Customer.FieldCaption(Customer."Customer Posting Group"));

        // [GIVEN] Create Payment and Apply to Invoice
        SalesInvoiceHeader.Get(SalesInvNo);
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        LibrarySales.CreatePaymentAndApplytoInvoice(GenJournalLine, Customer."No.", SalesInvNo, -SalesInvoiceHeader."Amount Including VAT");

        // [WHEN] Customer Posting Group Change 
        Customer.Validate("Customer Posting Group", CustomerPostingGroupNew.Code);

        // [THEN] Customer Posting Group succesfully Changed
        Assert.AreEqual(Customer."Customer Posting Group", CustomerPostingGroupNew.Code, Customer.FieldCaption(Customer."Customer Posting Group"));
    end;

    [Test]
    procedure VendorPostingGroupChange()
    begin
        // [FEATURE] Change Posting Group 
        Initialize();

        // [GIVEN] New Vendor Posting Groups
        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroupOrigin);
        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroupNew);

        // [GIVEN] New Vendor
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate(Vendor."Vendor Posting Group", VendorPostingGroupOrigin.Code);
        Vendor.Modify();

        // [GIVEN] New Purchase Invoice
        LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchaseHeader, Vendor."No.");
        PurchInvNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, false);

        // [WHEN] Vendor Posting Group Change 
        asserterror Vendor.Validate("Vendor Posting Group", VendorPostingGroupNew.Code);

        // [THEN] Vendor Posting Group not changed
        Assert.AreEqual(Vendor."Vendor Posting Group", VendorPostingGroupOrigin.Code, Vendor.FieldCaption(Vendor."Vendor Posting Group"));

        // [GIVEN] New Gen. Journal Template created
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);

        // [GIVEN] New Gen. Journal Batch created
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        // [GIVEN] Create Payment and Apply to Invoice
        PurchInvHeader.Get(PurchInvNo);
        PurchInvHeader.CalcFields("Amount Including VAT");
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name,
                        DocumentType::"Payment", AccountType::Vendor, Vendor."No.", PurchInvHeader."Amount Including VAT");
        GenJournalLine.Validate(GenJournalLine."Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate(GenJournalLine."Applies-to Doc. No.", PurchInvNo);
        GenJournalLine.Validate(GenJournalLine."Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJournalLine.Modify(true);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Vendor Posting Group Change 
        Vendor.Validate("Vendor Posting Group", VendorPostingGroupNew.Code);

        // [THEN] Vendor Posting Group succesfully Changed
        Assert.AreEqual(Vendor."Vendor Posting Group", VendorPostingGroupNew.Code, Vendor.FieldCaption(Vendor."Vendor Posting Group"));
    end;

    [Test]
    procedure BankAccPostingGroupChange()
    begin
        // [FEATURE] Change Posting Group 
        Initialize();

        // [GIVEN] New Bank Account Posting Groups
        LibraryERM.CreateBankAccountPostingGroup(BankAccountPostingGroupOrigin);
        LibraryERM.CreateBankAccountPostingGroup(BankAccountPostingGroupNew);
        BankAccountPostingGroupOrigin.Validate(BankAccountPostingGroupOrigin."G/L Account No.", LibraryERM.CreateGLAccountNo());
        BankAccountPostingGroupOrigin.Modify(true);
        BankAccountPostingGroupNew.Validate(BankAccountPostingGroupNew."G/L Account No.", LibraryERM.CreateGLAccountNo());
        BankAccountPostingGroupNew.Modify(true);

        // [GIVEN] New Bank Account
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate(BankAccount."Bank Acc. Posting Group", BankAccountPostingGroupOrigin.Code);
        BankAccount.Modify(true);

        // [GIVEN] New Gen. Journal Template created
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);

        // [GIVEN] New Gen. Journal Batch created
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        // [GIVEN] Create and Post Gen. Journal line
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name,
                        DocumentType::" ", AccountType::"Bank Account", BankAccount."No.", 100);
        GenJournalLine.Validate(GenJournalLine."Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate(GenJournalLine."Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Bank Account Posting Group Change 
        asserterror BankAccount.Validate("Bank Acc. Posting Group", BankAccountPostingGroupNew.Code);

        //[THEN] Bank Account Posting Group Not Changed
        Assert.AreEqual(BankAccount."Bank Acc. Posting Group", BankAccountPostingGroupOrigin.Code, BankAccount.FieldCaption(BankAccount."Bank Acc. Posting Group"));

        // [GIVEN] New Gen. Journal Template created
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);

        // [GIVEN] New Gen. Journal Batch created
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        // [GIVEN] Create Payment and Apply to Bank Account
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name,
                        DocumentType::"Payment", AccountType::"Bank Account", BankAccount."No.", -100);
        GenJournalLine.Validate(GenJournalLine."Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate(GenJournalLine."Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Bank Account Posting Group Change 
        BankAccount.Validate("Bank Acc. Posting Group", BankAccountPostingGroupNew.Code);

        // [THEN] Bank Account Posting Group succesfully Changed
        Assert.AreEqual(BankAccount."Bank Acc. Posting Group", BankAccountPostingGroupNew.Code, BankAccount.FieldCaption(BankAccount."Bank Acc. Posting Group"));
    end;

    [Test]
    procedure InventoryPostingGroupChange()
    begin
        // [FEATURE] Change Posting Group 
        Initialize();

        // [GIVEN] New Inventory Posting Groups
        LibraryInventory.CreateInventoryPostingGroup(InventoryPostingGroupOrigin);
        LibraryInventory.CreateInventoryPostingGroup(InventoryPostingGroupNew);

        // [GIVEN] New Item
        LibraryInventory.CreateItem(Item);
        Item.Validate(Item."Inventory Posting Group", InventoryPostingGroupOrigin.Code);
        Item.Modify(true);

        // [GIVEN] New Location
        Location.Init();
        Location.Code := CopyStr(LibraryRandom.RandText(10), 1, 10);
        Location.Insert(true);
        LibraryInventory.UpdateInventoryPostingSetup(Location);

        // [GIVEN] Create Item Journal Line Positive Adjmt.
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location.Code, '', 2);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [WHEN] Bank Account Posting Group Change 
        asserterror Item.Validate("Inventory Posting Group", InventoryPostingGroupNew.Code);

        // [THEN] Bank Account Posting Group not changed
        Assert.AreEqual(Item."Inventory Posting Group", InventoryPostingGroupOrigin.Code, Item.FieldCaption(Item."Inventory Posting Group"));

        // [GIVEN] Create Item Journal Line Negative Adjmt.
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Negative Adjmt.", Item."No.", 2);
        ItemJournalLine.Validate("Location Code", Location.Code);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [WHEN] Item Posting Group Change 
        Item.Validate("Inventory Posting Group", InventoryPostingGroupNew.Code);

        // [THEN] Item Posting Group succesfully Changed
        Assert.AreEqual(Item."Inventory Posting Group", InventoryPostingGroupNew.Code, Item.FieldCaption(Item."Inventory Posting Group"));
    end;
}