codeunit 144021 "Ref. Payment - Exported Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;

    local procedure CreatePurchaseDocument(var Vendor: Record Vendor; Type: Enum "Purchase Document Type"): Text
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        DocumentNumber: Code[20];
    begin
        with LibraryPurchase do begin
            LibraryInventory.CreateItem(Item);
            CreatePurchHeader(PurchaseHeader, Type, Vendor."No.");
            if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::"Credit Memo" then
                PurchaseHeader."Vendor Cr. Memo No." := Format(LibraryRandom.RandInt(1000));
            CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(1000));
            DocumentNumber := PostPurchaseDocument(PurchaseHeader, true, true);
        end;
        exit(DocumentNumber);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitTest()
    var
        RefPaymentExported: Record "Ref. Payment - Exported";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        with RefPaymentExported do begin
            LibraryPurchase.CreateVendor(Vendor);
            Validate("Payment Date", WorkDate);
            Validate("Document No.", '1');
            Validate("Vendor No.", Vendor."No.");

            // Check with no currency
            Validate(Amount, 1.0);
            Assert.AreEqual("Amount (LCY)", Amount, 'Currency convertion failed');
            Validate("Amount (LCY)", 1.0);
            Assert.AreEqual("Amount (LCY)", Amount, 'Currency convertion failed');

            // Check with currency
            Validate("Currency Code", LibraryERM.CreateCurrencyWithExchangeRate(WorkDate, 0.5, 0.5));
            Validate(Amount, 1.0);
            Assert.AreEqual("Amount (LCY)", 2.0, 'Currency convertion failed');
            Validate("Amount (LCY)", 2.0);
            Assert.AreEqual(Amount, 1.0, 'Currency convertion failed');
            Validate("Currency Factor", 2.0);

            // Check Vendor accoubt
            LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
            Validate("Vendor Account", VendorBankAccount.Code);

            // Get coverage on Message Type
            Validate("Message Type", "Message Type"::"Reference No.");
            Validate("Message Type", "Message Type"::"Invoice Information");
            Validate("Message Type", "Message Type"::Message);
            Validate("Message Type", "Message Type"::"Long Message");
            Validate("Message Type", "Message Type"::"Tax Message");

            // Check Ledger entry
            CreatePurchaseDocument(Vendor, VendorLedgerEntry."Document Type"::Invoice);
            VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
            VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
            VendorLedgerEntry.FindLast();
            VendorLedgerEntry.Open := true; // To make the relation work
            VendorLedgerEntry.Modify();
            Validate("Entry No.", VendorLedgerEntry."Entry No.");

            CreatePurchaseDocument(Vendor, VendorLedgerEntry."Document Type"::"Credit Memo");
            VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
            VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::"Credit Memo");
            VendorLedgerEntry.FindLast();
            VendorLedgerEntry.Open := true; // To make the relation work
            VendorLedgerEntry.Modify();
            Validate("Entry No.", VendorLedgerEntry."Entry No.");

            // Test global functions
            UpdateLines;
            Assert.IsFalse(ExistsNotTransferred, 'ExistsNotTransferred should return FALSE');
            SetUsePaymentDisc(true);
            Assert.AreEqual(GetLastLineNo, 0, 'No lines expected');
            MarkAffiliatedAsTransferred;
        end;
    end;
}

