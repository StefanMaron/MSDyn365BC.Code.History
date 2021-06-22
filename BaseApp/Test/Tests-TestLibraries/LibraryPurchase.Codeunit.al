codeunit 130512 "Library - Purchase"
{
    // Contains all utility functions related to Purchase.

    Permissions = TableData "Purchase Header" = rimd,
                  TableData "Purchase Line" = rimd;

    trigger OnRun()
    begin
    end;

    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryRandom: Codeunit "Library - Random";

    procedure BlanketPurchaseOrderMakeOrder(var PurchaseHeader: Record "Purchase Header"): Code[20]
    var
        PurchOrderHeader: Record "Purchase Header";
        BlanketPurchOrderToOrder: Codeunit "Blanket Purch. Order to Order";
    begin
        Clear(BlanketPurchOrderToOrder);
        BlanketPurchOrderToOrder.Run(PurchaseHeader);
        BlanketPurchOrderToOrder.GetPurchOrderHeader(PurchOrderHeader);
        exit(PurchOrderHeader."No.");
    end;

    procedure CopyPurchaseDocument(PurchaseHeader: Record "Purchase Header"; NewDocType: Option; NewDocNo: Code[20]; NewIncludeHeader: Boolean; NewRecalcLines: Boolean)
    var
        CopyPurchaseDocument: Report "Copy Purchase Document";
    begin
        CopyPurchaseDocument.SetPurchHeader(PurchaseHeader);
        CopyPurchaseDocument.InitializeRequest(NewDocType, NewDocNo, NewIncludeHeader, NewRecalcLines);
        CopyPurchaseDocument.UseRequestPage(false);
        CopyPurchaseDocument.Run;
    end;

    procedure CreateItemChargeAssignment(var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; PurchaseLine: Record "Purchase Line"; ItemCharge: Record "Item Charge"; DocType: Option; DocNo: Code[20]; DocLineNo: Integer; ItemNo: Code[20]; Qty: Decimal; UnitCost: Decimal)
    var
        RecRef: RecordRef;
    begin
        Clear(ItemChargeAssignmentPurch);

        with ItemChargeAssignmentPurch do begin
            "Document Type" := PurchaseLine."Document Type";
            "Document No." := PurchaseLine."Document No.";
            "Document Line No." := PurchaseLine."Line No.";
            "Item Charge No." := PurchaseLine."No.";
            "Unit Cost" := PurchaseLine."Unit Cost";
            RecRef.GetTable(ItemChargeAssignmentPurch);
            "Line No." := LibraryUtility.GetNewLineNo(RecRef, FieldNo("Line No."));
            "Item Charge No." := ItemCharge."No.";
            "Applies-to Doc. Type" := DocType;
            "Applies-to Doc. No." := DocNo;
            "Applies-to Doc. Line No." := DocLineNo;
            "Item No." := ItemNo;
            "Unit Cost" := UnitCost;
            Validate("Qty. to Assign", Qty);
        end;
    end;

    procedure CreateOrderAddress(var OrderAddress: Record "Order Address"; VendorNo: Code[20])
    var
        PostCode: Record "Post Code";
    begin
        LibraryERM.CreatePostCode(PostCode);
        OrderAddress.Init;
        OrderAddress.Validate("Vendor No.", VendorNo);
        OrderAddress.Validate(
          Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(OrderAddress.FieldNo(Code), DATABASE::"Order Address"),
            1,
            LibraryUtility.GetFieldLength(DATABASE::"Order Address", OrderAddress.FieldNo(Code))));
        OrderAddress.Validate(Name, LibraryUtility.GenerateRandomText(MaxStrLen(OrderAddress.Name)));
        OrderAddress.Validate(Address, LibraryUtility.GenerateRandomText(MaxStrLen(OrderAddress.Address)));
        OrderAddress.Validate("Post Code", PostCode.Code);
        OrderAddress.Insert(true);
    end;

    procedure CreatePrepaymentVATSetup(var LineGLAccount: Record "G/L Account"; VATCalculationType: Option): Code[20]
    var
        PrepmtGLAccount: Record "G/L Account";
    begin
        LibraryERM.CreatePrepaymentVATSetup(
          LineGLAccount, PrepmtGLAccount, LineGLAccount."Gen. Posting Type"::Purchase, VATCalculationType, VATCalculationType);
        exit(PrepmtGLAccount."No.");
    end;

    procedure CreatePurchasingCode(var Purchasing: Record Purchasing)
    begin
        Purchasing.Init;
        Purchasing.Validate(
          Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(Purchasing.FieldNo(Code), DATABASE::Purchasing),
            1,
            LibraryUtility.GetFieldLength(DATABASE::Purchasing, Purchasing.FieldNo(Code))));
        Purchasing.Insert(true);
    end;

    procedure CreateDropShipmentPurchasingCode(var Purchasing: Record Purchasing)
    begin
        CreatePurchasingCode(Purchasing);
        Purchasing.Validate("Drop Shipment", true);
        Purchasing.Modify(true);
    end;

    procedure CreateSpecialOrderPurchasingCode(var Purchasing: Record Purchasing)
    begin
        CreatePurchasingCode(Purchasing);
        Purchasing.Validate("Special Order", true);
        Purchasing.Modify(true);
    end;

    procedure CreatePurchHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Option; BuyfromVendorNo: Code[20])
    begin
        DisableWarningOnCloseUnpostedDoc;
        DisableWarningOnCloseUnreleasedDoc;
        DisableConfirmOnPostingDoc;
        Clear(PurchaseHeader);
        PurchaseHeader.Validate("Document Type", DocumentType);
        PurchaseHeader.Insert(true);
        if BuyfromVendorNo = '' then
            BuyfromVendorNo := CreateVendorNo;
        PurchaseHeader.Validate("Buy-from Vendor No.", BuyfromVendorNo);
        if PurchaseHeader."Document Type" in [PurchaseHeader."Document Type"::"Credit Memo",
                                              PurchaseHeader."Document Type"::"Return Order"]
        then
            PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID)
        else
            PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID);
        SetCorrDocNoPurchase(PurchaseHeader);
        PurchaseHeader.Modify(true);
    end;

    procedure CreatePurchHeaderWithDocNo(var PurchaseHeader: Record "Purchase Header"; DocumentType: Option; BuyfromVendorNo: Code[20]; DocNo: Code[20])
    begin
        Clear(PurchaseHeader);
        PurchaseHeader.Validate("Document Type", DocumentType);
        PurchaseHeader."No." := DocNo;
        PurchaseHeader.Insert(true);
        if BuyfromVendorNo = '' then
            BuyfromVendorNo := CreateVendorNo;
        PurchaseHeader.Validate("Buy-from Vendor No.", BuyfromVendorNo);
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID);
        SetCorrDocNoPurchase(PurchaseHeader);
        PurchaseHeader.Modify(true);
    end;

    procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Type: Option; No: Code[20]; Quantity: Decimal)
    begin
        CreatePurchaseLineSimple(PurchaseLine, PurchaseHeader);

        PurchaseLine.Validate(Type, Type);
        case Type of
            PurchaseLine.Type::Item:
                if No = '' then
                    No := LibraryInventory.CreateItemNo;
            PurchaseLine.Type::"Charge (Item)":
                if No = '' then
                    No := LibraryInventory.CreateItemChargeNo;
        end;
        PurchaseLine.Validate("No.", No);
        if Type <> PurchaseLine.Type::" " then
            PurchaseLine.Validate(Quantity, Quantity);
        PurchaseLine.Modify(true);

        OnAfterCreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, Quantity);
    end;

    procedure CreatePurchaseLineSimple(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    var
        RecRef: RecordRef;
    begin
        PurchaseLine.Init;
        PurchaseLine.Validate("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.Validate("Document No.", PurchaseHeader."No.");
        RecRef.GetTable(PurchaseLine);
        PurchaseLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, PurchaseLine.FieldNo("Line No.")));
        PurchaseLine.Insert(true);
    end;

    procedure CreatePurchaseQuote(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
    begin
        CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Quote, CreateVendorNo);
        CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo, LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1, 99, 2));
        PurchaseLine.Modify(true);
    end;

    procedure CreatePurchaseInvoice(var PurchaseHeader: Record "Purchase Header")
    begin
        CreatePurchaseInvoiceForVendorNo(PurchaseHeader, CreateVendorNo);
    end;

    procedure CreatePurchaseInvoiceForVendorNo(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo, LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1, 100, 2));
        PurchaseLine.Modify(true);
    end;

    procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendorNo);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo, LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1, 100, 2));
        PurchaseLine.Modify(true);
    end;

    procedure CreatePurchaseCreditMemo(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", CreateVendorNo);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo, LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1, 100, 2));
        PurchaseLine.Modify(true);
    end;

    procedure CreatePurchaseReturnOrder(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", CreateVendorNo);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo, LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1, 100, 2));
        PurchaseLine.Modify(true);
    end;

    procedure CreatePurchCommentLine(var PurchCommentLine: Record "Purch. Comment Line"; DocumentType: Option; No: Code[20]; DocumentLineNo: Integer)
    var
        RecRef: RecordRef;
    begin
        PurchCommentLine.Init;
        PurchCommentLine.Validate("Document Type", DocumentType);
        PurchCommentLine.Validate("No.", No);
        PurchCommentLine.Validate("Document Line No.", DocumentLineNo);
        RecRef.GetTable(PurchCommentLine);
        PurchCommentLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, PurchCommentLine.FieldNo("Line No.")));
        PurchCommentLine.Insert(true);
        // Validate Comment as primary key to enable user to distinguish between comments because value is not important.
        PurchCommentLine.Validate(
          Comment, Format(PurchCommentLine."Document Type") + PurchCommentLine."No." +
          Format(PurchCommentLine."Document Line No.") + Format(PurchCommentLine."Line No."));
        PurchCommentLine.Modify(true);
    end;

    procedure CreatePurchaseDocumentWithItem(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Option; VendorNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; ExpectedReceiptDate: Date)
    begin
        CreateFCYPurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, DocumentType, VendorNo, ItemNo, Quantity, LocationCode, ExpectedReceiptDate, '');
    end;

    procedure CreateFCYPurchaseDocumentWithItem(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Option; VendorNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; ExpectedReceiptDate: Date; CurrencyCode: Code[10])
    begin
        CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        if LocationCode <> '' then
            PurchaseHeader.Validate("Location Code", LocationCode);
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);
        if ItemNo = '' then
            ItemNo := LibraryInventory.CreateItemNo;
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        if LocationCode <> '' then
            PurchaseLine.Validate("Location Code", LocationCode);
        if ExpectedReceiptDate <> 0D then
            PurchaseLine.Validate("Expected Receipt Date", ExpectedReceiptDate);
        PurchaseLine.Modify(true);
    end;

    procedure CreatePurchasePrepaymentPct(var PurchasePrepaymentPct: Record "Purchase Prepayment %"; ItemNo: Code[20]; VendorNo: Code[20]; StartingDate: Date)
    begin
        PurchasePrepaymentPct.Init;
        PurchasePrepaymentPct.Validate("Item No.", ItemNo);
        PurchasePrepaymentPct.Validate("Vendor No.", VendorNo);
        PurchasePrepaymentPct.Validate("Starting Date", StartingDate);
        PurchasePrepaymentPct.Insert(true);
    end;

    procedure CreateStandardPurchaseCode(var StandardPurchaseCode: Record "Standard Purchase Code")
    begin
        StandardPurchaseCode.Init;
        StandardPurchaseCode.Validate(
          Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(StandardPurchaseCode.FieldNo(Code), DATABASE::"Standard Purchase Code"),
            1,
            LibraryUtility.GetFieldLength(DATABASE::"Standard Purchase Code", StandardPurchaseCode.FieldNo(Code))));
        // Validating Description as Code because value is not important.
        StandardPurchaseCode.Validate(Description, StandardPurchaseCode.Code);
        StandardPurchaseCode.Insert(true);
    end;

    procedure CreateStandardPurchaseLine(var StandardPurchaseLine: Record "Standard Purchase Line"; StandardPurchaseCode: Code[10])
    var
        RecRef: RecordRef;
    begin
        StandardPurchaseLine.Init;
        StandardPurchaseLine.Validate("Standard Purchase Code", StandardPurchaseCode);
        RecRef.GetTable(StandardPurchaseLine);
        StandardPurchaseLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, StandardPurchaseLine.FieldNo("Line No.")));
        StandardPurchaseLine.Insert(true);
    end;

    procedure CreateSubcontractor(var Vendor: Record Vendor)
    begin
        CreateVendor(Vendor);
    end;

    procedure CreateVendor(var Vendor: Record Vendor): Code[20]
    var
        PaymentMethod: Record "Payment Method";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        VendContUpdate: Codeunit "VendCont-Update";
    begin
        LibraryERM.FindPaymentMethod(PaymentMethod);
        LibraryERM.SetSearchGenPostingTypePurch;
        LibraryERM.FindGeneralPostingSetupInvtFull(GeneralPostingSetup);
        LibraryERM.FindVATPostingSetupInvt(VATPostingSetup);
        LibraryUtility.UpdateSetupNoSeriesCode(
          DATABASE::"Purchases & Payables Setup", PurchasesPayablesSetup.FieldNo("Vendor Nos."));

        Clear(Vendor);
        Vendor.Insert(true);
        Vendor.Validate(Name, Vendor."No."); // Validating Name as No. because value is not important.
        Vendor.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Validate("Vendor Posting Group", FindVendorPostingGroup);
        Vendor.Validate("Payment Terms Code", LibraryERM.FindPaymentTermsCode);
        Vendor.Validate("Payment Method Code", PaymentMethod.Code);
        Vendor.Modify(true);
        VendContUpdate.OnModify(Vendor);

        OnAfterCreateVendor(Vendor);
        exit(Vendor."No.");
    end;

    procedure CreateVendorNo(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        CreateVendor(Vendor);
        exit(Vendor."No.");
    end;

    procedure CreateVendorPostingGroup(var VendorPostingGroup: Record "Vendor Posting Group")
    begin
        VendorPostingGroup.Init;
        VendorPostingGroup.Validate(Code,
          LibraryUtility.GenerateRandomCode(VendorPostingGroup.FieldNo(Code), DATABASE::"Vendor Posting Group"));
        VendorPostingGroup.Validate("Payables Account", LibraryERM.CreateGLAccountNo);
        VendorPostingGroup.Validate("Service Charge Acc.", LibraryERM.CreateGLAccountWithPurchSetup);
        VendorPostingGroup.Validate("Invoice Rounding Account", LibraryERM.CreateGLAccountWithPurchSetup);
        VendorPostingGroup.Validate("Debit Rounding Account", LibraryERM.CreateGLAccountNo);
        VendorPostingGroup.Validate("Credit Rounding Account", LibraryERM.CreateGLAccountNo);
        VendorPostingGroup.Validate("Payment Disc. Debit Acc.", LibraryERM.CreateGLAccountNo);
        VendorPostingGroup.Validate("Payment Disc. Credit Acc.", LibraryERM.CreateGLAccountNo);
        VendorPostingGroup.Validate("Payment Tolerance Debit Acc.", LibraryERM.CreateGLAccountNo);
        VendorPostingGroup.Validate("Payment Tolerance Credit Acc.", LibraryERM.CreateGLAccountNo);
        VendorPostingGroup.Validate("Debit Curr. Appln. Rndg. Acc.", LibraryERM.CreateGLAccountNo);
        VendorPostingGroup.Validate("Credit Curr. Appln. Rndg. Acc.", LibraryERM.CreateGLAccountNo);
        VendorPostingGroup.Insert(true);
    end;

    procedure CreateVendorWithLocationCode(var Vendor: Record Vendor; LocationCode: Code[10]): Code[20]
    begin
        with Vendor do begin
            CreateVendor(Vendor);
            Validate("Location Code", LocationCode);
            Modify(true);
            exit("No.");
        end;
    end;

    procedure CreateVendorWithBusPostingGroups(GenBusPostGroupCode: Code[20]; VATBusPostGroupCode: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        with Vendor do begin
            CreateVendor(Vendor);
            Validate("Gen. Bus. Posting Group", GenBusPostGroupCode);
            Validate("VAT Bus. Posting Group", VATBusPostGroupCode);
            Modify(true);
            exit("No.");
        end;
    end;

    procedure CreateVendorWithVATBusPostingGroup(VATBusPostGroupCode: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        with Vendor do begin
            CreateVendor(Vendor);
            Validate("VAT Bus. Posting Group", VATBusPostGroupCode);
            Modify(true);
            exit("No.");
        end;
    end;

    procedure CreateVendorWithVATRegNo(var Vendor: Record Vendor): Code[20]
    var
        CountryRegion: Record "Country/Region";
    begin
        CreateVendor(Vendor);
        LibraryERM.CreateCountryRegion(CountryRegion);
        Vendor.Validate("Country/Region Code", CountryRegion.Code);
        Vendor."VAT Registration No." := LibraryERM.GenerateVATRegistrationNo(CountryRegion.Code);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    procedure CreateVendorWithAddress(var Vendor: Record Vendor)
    var
        PostCode: Record "Post Code";
    begin
        LibraryERM.CreatePostCode(PostCode);
        CreateVendor(Vendor);
        Vendor.Validate(Name, LibraryUtility.GenerateRandomText(MaxStrLen(Vendor.Name)));
        Vendor.Validate(Address, LibraryUtility.GenerateRandomText(MaxStrLen(Vendor.Address)));
        Vendor.Validate("Post Code", PostCode.Code);
        Vendor.Contact := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Vendor.Contact)), 1, MaxStrLen(Vendor.Contact));
        Vendor.Modify(true);
    end;

    procedure CreateVendorBankAccount(var VendorBankAccount: Record "Vendor Bank Account"; VendorNo: Code[20])
    begin
        VendorBankAccount.Init;
        VendorBankAccount.Validate("Vendor No.", VendorNo);
        VendorBankAccount.Validate(
          Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(VendorBankAccount.FieldNo(Code), DATABASE::"Vendor Bank Account"),
            1,
            LibraryUtility.GetFieldLength(DATABASE::"Vendor Bank Account", VendorBankAccount.FieldNo(Code))));
        VendorBankAccount.Insert(true);
    end;

    procedure CreateVendorPurchaseCode(var StandardVendorPurchaseCode: Record "Standard Vendor Purchase Code"; VendorNo: Code[20]; "Code": Code[10])
    begin
        StandardVendorPurchaseCode.Init;
        StandardVendorPurchaseCode.Validate("Vendor No.", VendorNo);
        StandardVendorPurchaseCode.Validate(Code, Code);
        StandardVendorPurchaseCode.Insert(true);
    end;

    procedure CreatePurchaseHeaderPostingJobQueueEntry(var JobQueueEntry: Record "Job Queue Entry"; PurchaseHeader: Record "Purchase Header")
    begin
        JobQueueEntry.Init;
        JobQueueEntry.ID := CreateGuid;
        JobQueueEntry."Earliest Start Date/Time" := CreateDateTime(Today, 0T);
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CODEUNIT::"Purchase Post via Job Queue";
        JobQueueEntry."Record ID to Process" := PurchaseHeader.RecordId;
        JobQueueEntry."Run in User Session" := true;
        JobQueueEntry.Insert(true);
    end;

    procedure CreateIntrastatContact(CountryRegionCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        CreateVendor(Vendor);
        Vendor.Validate(Name, LibraryUtility.GenerateGUID);
        Vendor.Validate(Address, LibraryUtility.GenerateGUID);
        Vendor.Validate("Country/Region Code", CountryRegionCode);
        Vendor.Validate("Post Code", LibraryUtility.GenerateGUID);
        Vendor.Validate(City, LibraryUtility.GenerateGUID);
        Vendor.Validate("Phone No.", Format(LibraryRandom.RandIntInRange(100000000, 999999999)));
        Vendor.Validate("Fax No.", LibraryUtility.GenerateGUID);
        Vendor.Validate("E-Mail", LibraryUtility.GenerateGUID + '@' + LibraryUtility.GenerateGUID);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    procedure DeleteInvoicedPurchOrders(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseHeader2: Record "Purchase Header";
        DeleteInvoicedPurchOrders: Report "Delete Invoiced Purch. Orders";
    begin
        if PurchaseHeader.HasFilter then
            PurchaseHeader2.CopyFilters(PurchaseHeader)
        else begin
            PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
            PurchaseHeader2.SetRange("Document Type", PurchaseHeader."Document Type");
            PurchaseHeader2.SetRange("No.", PurchaseHeader."No.");
        end;
        Clear(DeleteInvoicedPurchOrders);
        DeleteInvoicedPurchOrders.SetTableView(PurchaseHeader2);
        DeleteInvoicedPurchOrders.UseRequestPage(false);
        DeleteInvoicedPurchOrders.RunModal;
    end;

    procedure ExplodeBOM(var PurchaseLine: Record "Purchase Line")
    var
        PurchExplodeBOM: Codeunit "Purch.-Explode BOM";
    begin
        Clear(PurchExplodeBOM);
        PurchExplodeBOM.Run(PurchaseLine);
    end;

    procedure FilterPurchaseHeaderArchive(var PurchaseHeaderArchive: Record "Purchase Header Archive"; DocumentType: Option; DocumentNo: Code[20]; DocNoOccurance: Integer; Version: Integer)
    begin
        PurchaseHeaderArchive.SetRange("Document Type", DocumentType);
        PurchaseHeaderArchive.SetRange("No.", DocumentNo);
        PurchaseHeaderArchive.SetRange("Doc. No. Occurrence", DocNoOccurance);
        PurchaseHeaderArchive.SetRange("Version No.", Version);
    end;

    procedure FilterPurchaseLineArchive(var PurchaseLineArchive: Record "Purchase Line Archive"; DocumentType: Option; DocumentNo: Code[20]; DocNoOccurance: Integer; Version: Integer)
    begin
        PurchaseLineArchive.SetRange("Document Type", DocumentType);
        PurchaseLineArchive.SetRange("Document No.", DocumentNo);
        PurchaseLineArchive.SetRange("Doc. No. Occurrence", DocNoOccurance);
        PurchaseLineArchive.SetRange("Version No.", Version);
    end;

    procedure FindVendorPostingGroup(): Code[20]
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        if not VendorPostingGroup.FindFirst then
            CreateVendorPostingGroup(VendorPostingGroup);
        exit(VendorPostingGroup.Code);
    end;

    procedure FindFirstPurchLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst;
    end;

    procedure FindReturnShipmentHeader(var ReturnShipmentHeader: Record "Return Shipment Header"; ReturnOrderNo: Code[20])
    begin
        ReturnShipmentHeader.SetRange("Return Order No.", ReturnOrderNo);
        ReturnShipmentHeader.FindFirst;
    end;

    procedure GetDropShipment(var PurchaseHeader: Record "Purchase Header")
    var
        PurchGetDropShpt: Codeunit "Purch.-Get Drop Shpt.";
    begin
        Clear(PurchGetDropShpt);
        PurchGetDropShpt.Run(PurchaseHeader);
    end;

    procedure GetInvRoundingAccountOfVendPostGroup(VendorPostingGroupCode: Code[20]): Code[20]
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        VendorPostingGroup.Get(VendorPostingGroupCode);
        exit(VendorPostingGroup."Invoice Rounding Account");
    end;

    procedure GetPurchaseReceiptLine(var PurchaseLine: Record "Purchase Line")
    var
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
    begin
        Clear(PurchGetReceipt);
        PurchGetReceipt.Run(PurchaseLine);
    end;

    procedure GetSpecialOrder(var PurchaseHeader: Record "Purchase Header")
    var
        DistIntegration: Codeunit "Dist. Integration";
    begin
        Clear(DistIntegration);
        DistIntegration.GetSpecialOrders(PurchaseHeader);
    end;

    procedure GegVendorLedgerEntryUniqueExternalDocNo(): Code[10]
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        exit(
          LibraryUtility.GenerateRandomCodeWithLength(
            VendorLedgerEntry.FieldNo("External Document No."),
            DATABASE::"Vendor Ledger Entry",
            10));
    end;

    procedure PostPurchasePrepaymentCrMemo(var PurchaseHeader: Record "Purchase Header")
    var
        PurchPostPrepayments: Codeunit "Purchase-Post Prepayments";
    begin
        PurchPostPrepayments.CreditMemo(PurchaseHeader);
    end;

    procedure PostPurchasePrepaymentCreditMemo(var PurchaseHeader: Record "Purchase Header") DocumentNo: Code[20]
    var
        PurchPostPrepayments: Codeunit "Purchase-Post Prepayments";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        NoSeriesCode: Code[20];
    begin
        NoSeriesCode := PurchaseHeader."Prepmt. Cr. Memo No. Series";
        if PurchaseHeader."Prepmt. Cr. Memo No." = '' then
            DocumentNo := NoSeriesMgt.GetNextNo(NoSeriesCode, LibraryUtility.GetNextNoSeriesPurchaseDate(NoSeriesCode), false)
        else
            DocumentNo := PurchaseHeader."Prepmt. Cr. Memo No.";
        PurchPostPrepayments.CreditMemo(PurchaseHeader);
    end;

    procedure PostPurchasePrepaymentInvoice(var PurchaseHeader: Record "Purchase Header") DocumentNo: Code[20]
    var
        PurchasePostPrepayments: Codeunit "Purchase-Post Prepayments";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        NoSeriesCode: Code[20];
    begin
        NoSeriesCode := PurchaseHeader."Prepayment No. Series";
        if PurchaseHeader."Prepayment No." = '' then
            DocumentNo := NoSeriesMgt.GetNextNo(NoSeriesCode, LibraryUtility.GetNextNoSeriesPurchaseDate(NoSeriesCode), false)
        else
            DocumentNo := PurchaseHeader."Prepayment No.";
        PurchasePostPrepayments.Invoice(PurchaseHeader);
    end;

    procedure PostPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; ToShipReceive: Boolean; ToInvoice: Boolean) DocumentNo: Code[20]
    var
        NoSeriesManagement: Codeunit NoSeriesManagement;
        NoSeriesCode: Code[20];
    begin
        // Post the purchase document.
        // Depending on the document type and posting type return the number of the:
        // - purchase receipt,
        // - posted purchase invoice,
        // - purchase return shipment, or
        // - posted credit memo
        SetCorrDocNoPurchase(PurchaseHeader);
        with PurchaseHeader do begin
            Validate(Receive, ToShipReceive);
            Validate(Ship, ToShipReceive);
            Validate(Invoice, ToInvoice);

            case "Document Type" of
                "Document Type"::Invoice:
                    NoSeriesCode := "Posting No. Series"; // posted purchase invoice
                "Document Type"::Order:
                    if ToShipReceive and not ToInvoice then
                        NoSeriesCode := "Receiving No. Series" // posted purchase receipt
                    else
                        NoSeriesCode := "Posting No. Series"; // posted purchase invoice
                "Document Type"::"Credit Memo":
                    NoSeriesCode := "Posting No. Series"; // posted purchase credit memo
                "Document Type"::"Return Order":
                    if ToShipReceive and not ToInvoice then
                        NoSeriesCode := "Return Shipment No. Series" // posted purchase return shipment
                    else
                        NoSeriesCode := "Posting No. Series"; // posted purchase credit memo
                else
                    Assert.Fail(StrSubstNo('Document type not supported: %1', "Document Type"))
            end
        end;

        if NoSeriesCode = '' then
            DocumentNo := PurchaseHeader."No."
        else
            DocumentNo :=
              NoSeriesManagement.GetNextNo(NoSeriesCode, LibraryUtility.GetNextNoSeriesPurchaseDate(NoSeriesCode), false);
        CODEUNIT.Run(CODEUNIT::"Purch.-Post", PurchaseHeader);
    end;

    procedure QuoteMakeOrder(var PurchaseHeader: Record "Purchase Header"): Code[20]
    var
        PurchaseOrderHeader: Record "Purchase Header";
        PurchQuoteToOrder: Codeunit "Purch.-Quote to Order";
    begin
        Clear(PurchQuoteToOrder);
        PurchQuoteToOrder.Run(PurchaseHeader);
        PurchQuoteToOrder.GetPurchOrderHeader(PurchaseOrderHeader);
        exit(PurchaseOrderHeader."No.");
    end;

    procedure ReleasePurchaseDocument(var PurchaseHeader: Record "Purchase Header")
    var
        ReleasePurchDoc: Codeunit "Release Purchase Document";
    begin
        ReleasePurchDoc.PerformManualRelease(PurchaseHeader);
    end;

    procedure ReopenPurchaseDocument(var PurchaseHeader: Record "Purchase Header")
    var
        ReleasePurchDoc: Codeunit "Release Purchase Document";
    begin
        ReleasePurchDoc.PerformManualReopen(PurchaseHeader);
    end;

    procedure CalcPurchaseDiscount(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine."Document Type" := PurchaseHeader."Document Type";
        PurchaseLine."Document No." := PurchaseHeader."No.";
        CODEUNIT.Run(CODEUNIT::"Purch.-Calc.Discount", PurchaseLine);
    end;

    procedure RunBatchPostPurchaseReturnOrdersReport(var PurchaseHeader: Record "Purchase Header")
    var
        BatchPostPurchRetOrders: Report "Batch Post Purch. Ret. Orders";
    begin
        Clear(BatchPostPurchRetOrders);
        BatchPostPurchRetOrders.SetTableView(PurchaseHeader);
        Commit;  // COMMIT is required to run this report.
        BatchPostPurchRetOrders.UseRequestPage(true);
        BatchPostPurchRetOrders.Run;
    end;

    procedure RunDeleteInvoicedPurchaseReturnOrdersReport(var PurchaseHeader: Record "Purchase Header")
    var
        DeleteInvdPurchRetOrders: Report "Delete Invd Purch. Ret. Orders";
    begin
        Clear(DeleteInvdPurchRetOrders);
        DeleteInvdPurchRetOrders.SetTableView(PurchaseHeader);
        DeleteInvdPurchRetOrders.UseRequestPage(false);
        DeleteInvdPurchRetOrders.Run;
    end;

    procedure RunMoveNegativePurchaseLinesReport(var PurchaseHeader: Record "Purchase Header"; FromDocType: Option; ToDocType: Option; ToDocType2: Option)
    var
        MoveNegativePurchaseLines: Report "Move Negative Purchase Lines";
    begin
        Clear(MoveNegativePurchaseLines);
        MoveNegativePurchaseLines.SetPurchHeader(PurchaseHeader);
        MoveNegativePurchaseLines.InitializeRequest(FromDocType, ToDocType, ToDocType2);
        MoveNegativePurchaseLines.UseRequestPage(false);
        MoveNegativePurchaseLines.Run;
    end;

    procedure SetAllowVATDifference(AllowVATDifference: Boolean)
    begin
        PurchasesPayablesSetup.Get;
        PurchasesPayablesSetup.Validate("Allow VAT Difference", AllowVATDifference);
        PurchasesPayablesSetup.Modify(true);
    end;

    procedure SetAllowDocumentDeletionBeforeDate(Date: Date)
    begin
        PurchasesPayablesSetup.Get;
        PurchasesPayablesSetup.Validate("Allow Document Deletion Before", Date);
        PurchasesPayablesSetup.Modify(true);
    end;

    procedure SetArchiveQuotesAlways()
    begin
        PurchasesPayablesSetup.Get;
        PurchasesPayablesSetup.Validate("Archive Quotes", PurchasesPayablesSetup."Archive Quotes"::Always);
        PurchasesPayablesSetup.Modify(true);
    end;

    procedure SetArchiveOrders(ArchiveOrders: Boolean)
    begin
        PurchasesPayablesSetup.Get;
        PurchasesPayablesSetup.Validate("Archive Orders", ArchiveOrders);
        PurchasesPayablesSetup.Modify(true);
    end;

    procedure SetArchiveBlanketOrders(ArchiveBlanketOrders: Boolean)
    begin
        PurchasesPayablesSetup.Get;
        PurchasesPayablesSetup.Validate("Archive Blanket Orders", ArchiveBlanketOrders);
        PurchasesPayablesSetup.Modify(true);
    end;

    procedure SetArchiveReturnOrders(ArchiveReturnOrders: Boolean)
    begin
        PurchasesPayablesSetup.Get;
        PurchasesPayablesSetup.Validate("Archive Return Orders", ArchiveReturnOrders);
        PurchasesPayablesSetup.Modify(true);
    end;

    procedure SetCreateItemFromItemNo(NewValue: Boolean)
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Create Item from Item No.", NewValue);
        PurchasesPayablesSetup.Modify(true);
    end;

    procedure SetDefaultPostingDateWorkDate()
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Default Posting Date", PurchasesPayablesSetup."Default Posting Date"::"Work Date");
        PurchasesPayablesSetup.Modify(true);
    end;

    procedure SetDefaultPostingDateNoDate()
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Default Posting Date", PurchasesPayablesSetup."Default Posting Date"::"No Date");
        PurchasesPayablesSetup.Modify(true);
    end;

    procedure SetDiscountPosting(DiscountPosting: Option)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get;
        PurchasesPayablesSetup.Validate("Discount Posting", DiscountPosting);
        PurchasesPayablesSetup.Modify(true);
    end;

    procedure SetDiscountPostingSilent(DiscountPosting: Option)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get;
        PurchasesPayablesSetup."Discount Posting" := DiscountPosting;
        PurchasesPayablesSetup.Modify;
    end;

    procedure SetCalcInvDiscount(CalcInvDiscount: Boolean)
    begin
        PurchasesPayablesSetup.Get;
        PurchasesPayablesSetup.Validate("Calc. Inv. Discount", CalcInvDiscount);
        PurchasesPayablesSetup.Modify(true);
    end;

    procedure SetCorrDocNoPurchase(var PurchHeader: Record "Purchase Header")
    begin
        with PurchHeader do
            if "Document Type" in ["Document Type"::"Credit Memo", "Document Type"::"Return Order"] then;
    end;

    procedure SetInvoiceRounding(InvoiceRounding: Boolean)
    begin
        PurchasesPayablesSetup.Get;
        PurchasesPayablesSetup.Validate("Invoice Rounding", InvoiceRounding);
        PurchasesPayablesSetup.Modify(true);
    end;

    procedure SetExactCostReversingMandatory(ExactCostReversingMandatory: Boolean)
    begin
        PurchasesPayablesSetup.Get;
        PurchasesPayablesSetup.Validate("Exact Cost Reversing Mandatory", ExactCostReversingMandatory);
        PurchasesPayablesSetup.Modify(true);
    end;

    procedure SetExtDocNo(ExtDocNoMandatory: Boolean)
    begin
        PurchasesPayablesSetup.Get;
        PurchasesPayablesSetup.Validate("Ext. Doc. No. Mandatory", ExtDocNoMandatory);
        PurchasesPayablesSetup.Modify(true);
    end;

    procedure SetPostWithJobQueue(PostWithJobQueue: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get;
        PurchasesPayablesSetup.Validate("Post with Job Queue", PostWithJobQueue);
        PurchasesPayablesSetup.Modify(true);
    end;

    procedure SetPostAndPrintWithJobQueue(PostAndPrintWithJobQueue: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get;
        PurchasesPayablesSetup.Validate("Post & Print with Job Queue", PostAndPrintWithJobQueue);
        PurchasesPayablesSetup.Modify(true);
    end;

    procedure SetOrderNoSeriesInSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        with PurchasesPayablesSetup do begin
            Get;
            Validate("Order Nos.", LibraryERM.CreateNoSeriesCode);
            Modify(true);
        end;
    end;

    procedure SetPostedNoSeriesInSetup()
    begin
        with PurchasesPayablesSetup do begin
            Get;
            Validate("Posted Invoice Nos.", LibraryERM.CreateNoSeriesCode);
            Validate("Posted Receipt Nos.", LibraryERM.CreateNoSeriesCode);
            Validate("Posted Credit Memo Nos.", LibraryERM.CreateNoSeriesCode);
            Modify(true);
        end;
    end;

    procedure SetQuoteNoSeriesInSetup()
    begin
        with PurchasesPayablesSetup do begin
            Get;
            Validate("Quote Nos.", LibraryERM.CreateNoSeriesCode);
            Modify(true);
        end;
    end;

    procedure SetReturnOrderNoSeriesInSetup()
    begin
        with PurchasesPayablesSetup do begin
            Get;
            Validate("Return Order Nos.", LibraryERM.CreateNoSeriesCode);
            Validate("Posted Return Shpt. Nos.", LibraryERM.CreateNoSeriesCode);
            Modify(true);
        end;
    end;

    procedure SetCopyCommentsOrderToInvoiceInSetup(CopyCommentsOrderToInvoice: Boolean)
    begin
        with PurchasesPayablesSetup do begin
            Get;
            Validate("Copy Comments Order to Invoice", CopyCommentsOrderToInvoice);
            Modify(true);
        end;
    end;

    procedure SelectPmtJnlBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryJournals.SelectGenJournalBatch(GenJournalBatch, SelectPmtJnlTemplate);
    end;

    procedure SelectPmtJnlTemplate(): Code[10]
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        exit(LibraryJournals.SelectGenJournalTemplate(GenJournalTemplate.Type::Payments, PAGE::"Payment Journal"));
    end;

    procedure UndoPurchaseReceiptLine(var PurchRcptLine: Record "Purch. Rcpt. Line")
    begin
        CODEUNIT.Run(CODEUNIT::"Undo Purchase Receipt Line", PurchRcptLine);
    end;

    procedure UndoReturnShipmentLine(var ReturnShipmentLine: Record "Return Shipment Line")
    begin
        CODEUNIT.Run(CODEUNIT::"Undo Return Shipment Line", ReturnShipmentLine);
    end;

    procedure DisableConfirmOnPostingDoc()
    var
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        InstructionMgt.DisableMessageForCurrentUser(InstructionMgt.ShowPostedConfirmationMessageCode);
    end;

    procedure DisableWarningOnCloseUnreleasedDoc()
    begin
        LibraryERM.DisableClosingUnreleasedOrdersMsg;
    end;

    procedure DisableWarningOnCloseUnpostedDoc()
    var
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        InstructionMgt.DisableMessageForCurrentUser(InstructionMgt.QueryPostOnCloseCode);
    end;

    procedure EnablePurchSetupIgnoreUpdatedAddresses()
    var
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        PurchSetup.Get;
        PurchSetup."Ignore Updated Addresses" := true;
        PurchSetup.Modify;
    end;

    procedure DisablePurchSetupIgnoreUpdatedAddresses()
    var
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        PurchSetup.Get;
        PurchSetup."Ignore Updated Addresses" := false;
        PurchSetup.Modify;
    end;

    procedure PreviewPostPurchaseDocument(var PurchaseHeader: Record "Purchase Header")
    var
        PurchPostYesNo: Codeunit "Purch.-Post (Yes/No)";
    begin
        PurchPostYesNo.Preview(PurchaseHeader);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Type: Option; No: Code[20]; Quantity: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateVendor(var Vendor: Record Vendor)
    begin
    end;
}

