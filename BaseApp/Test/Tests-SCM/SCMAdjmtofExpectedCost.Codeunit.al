codeunit 137018 "SCM Adjmt. of Expected Cost"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Automatic Cost Adjustment] [Expected Cost] [SCM]
        IsInitialized := false;
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryPatterns: Codeunit "Library - Patterns";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure VSTF324950()
    var
        Item: Record Item;
        OldInventorySetup: Record "Inventory Setup";
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        ValueEntry: Record "Value Entry";
        Qty: Decimal;
    begin
        Initialize();
        Qty := 100;
        // Inventory setup for test
        OldInventorySetup.Get();
        SetInventorySetup(
          OldInventorySetup, true, true, true,
          OldInventorySetup."Automatic Cost Adjustment"::Always);

        // make item
        LibraryPatterns.MAKEItemSimple(Item, Item."Costing Method"::FIFO, 0);

        // purchase
        LibraryPatterns.POSTPurchaseOrder(PurchaseHeader, Item, '', '', Qty, WorkDate(), 10, true, false);

        // Sales order - shipment only
        LibraryPatterns.POSTSalesOrder(SalesHeader, Item, '', '', Qty, WorkDate(), 0, true, false);

        // Now invoice of sales order
        PartialInvoiceOfSales(SalesHeader, Qty / 4);

        PurchaseOrderWithItemCharge(PurchaseHeader, 100);
        PurchaseOrderWithItemCharge(PurchaseHeader, 200);

        // Now invoice of sales order
        PartialInvoiceOfSales(SalesHeader, Qty / 4);

        // verify correct ValueEntries
        VerifyValueEntries(ValueEntry, 75);
        VerifyValueEntries(ValueEntry, 250);

        // restore Inventory Setup
        SetInventorySetup(
          OldInventorySetup, false,
          OldInventorySetup."Automatic Cost Posting",
          OldInventorySetup."Expected Cost Posting to G/L", OldInventorySetup."Automatic Cost Adjustment");
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Adjmt. of Expected Cost");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Adjmt. of Expected Cost");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Adjmt. of Expected Cost");
    end;

    local procedure SetInventorySetup(InventorySetup: Record "Inventory Setup"; NewSetup: Boolean; AutomaticCostPosting: Boolean; ExpectedCostPosting: Boolean; AutomaticCostAdjustment: Enum "Automatic Cost Adjustment Type")
    var
        SavedInventorySetup: Record "Inventory Setup";
    begin
        with InventorySetup do begin
            if NewSetup then begin
                "Automatic Cost Posting" := AutomaticCostPosting;
                "Expected Cost Posting to G/L" := ExpectedCostPosting;
                "Automatic Cost Adjustment" := AutomaticCostAdjustment;
                "Average Cost Calc. Type" := "Average Cost Calc. Type"::Item;
                "Average Cost Period" := "Average Cost Period"::Day;
            end else begin
                SavedInventorySetup.Get();
                SavedInventorySetup."Automatic Cost Posting" := AutomaticCostPosting;
                SavedInventorySetup."Expected Cost Posting to G/L" := ExpectedCostPosting;
                SavedInventorySetup."Automatic Cost Adjustment" := AutomaticCostAdjustment;
                SavedInventorySetup."Average Cost Calc. Type" := "Average Cost Calc. Type";
                SavedInventorySetup."Average Cost Period" := "Average Cost Period";
                InventorySetup := SavedInventorySetup;
            end;
            Modify();
        end;
        CODEUNIT.Run(CODEUNIT::"Change Average Cost Setting", InventorySetup);
    end;

    local procedure PartialInvoiceOfSales(var SalesHeader: Record "Sales Header"; QuantityToInv: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        with SalesLine do begin
            SetRange("Document Type", SalesHeader."Document Type");
            SetRange("Document No.", SalesHeader."No.");
            SetRange(Type, Type::Item);
            FindFirst();
            Validate("Qty. to Invoice", QuantityToInv);
            Modify();

            SalesHeader.Find('=');
            LibrarySales.PostSalesDocument(SalesHeader, false, true);
        end;
    end;

    local procedure PurchaseOrderWithItemCharge(var PurchaseHeader: Record "Purchase Header"; DirectUnitCost: Decimal)
    var
        PurchaseHeaderItemCharge: Record "Purchase Header";
        Vendor: Record Vendor;
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        Vendor.Get(PurchaseHeader."Buy-from Vendor No.");

        PurchRcptLine.SetCurrentKey("Buy-from Vendor No.");
        PurchRcptLine.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        PurchRcptLine.SetRange(Type, PurchRcptLine.Type::Item);
        PurchRcptLine.FindFirst();

        // Purchase Order for Item Charge
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderItemCharge, PurchaseHeader."Document Type", Vendor."No.");

        // Line for Item Charge
        LibraryPatterns.ASSIGNPurchChargeToPurchRcptLine(PurchaseHeaderItemCharge, PurchRcptLine, 1, DirectUnitCost);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderItemCharge, true, true);
    end;

    local procedure VerifyValueEntries(var ValueEntry: Record "Value Entry"; EntryCost: Decimal)
    begin
        // last value entry has to have Cost Amount Expected = 75, Cost Amount Actual has to equal -75
        // previous value entry has to have Cost Amount Expected = 250, Cost Amount Actual has to equal -250
        with ValueEntry do begin
            if "Entry No." = 0 then
                FindLast()
            else
                Get("Entry No." - 1);

            Assert.AreEqual(EntryCost, "Cost Amount (Expected)", '');
            Assert.AreEqual(-EntryCost, "Cost Amount (Actual)", '');
        end;
    end;
}

