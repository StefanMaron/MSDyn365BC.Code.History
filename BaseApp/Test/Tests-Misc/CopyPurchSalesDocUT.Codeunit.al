codeunit 134338 "Copy Purch/Sales Doc UT"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Copy Document] [Event]
    end;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        SalesDocType: Option Quote,"Blanket Order","Order",Invoice,"Return Order","Credit Memo","Posted Shipment","Posted Invoice","Posted Return Receipt","Posted Credit Memo";
        PurchDocType: Option Quote,"Blanket Order","Order",Invoice,"Return Order","Credit Memo","Posted Receipt","Posted Invoice","Posted Return Shipment","Posted Credit Memo";
        BeforeSalesTxt: Label 'BeforeSales';
        BeforePurchaseTxt: Label 'BeforePurchase';
        AfterSalesTxt: Label 'AfterSales';
        AfterPurchaseTxt: Label 'AfterPurchase';
        SwitchedToLanguageIsNotEqualToTargetTxt: Label 'Switched to language is not equal to target. Target language - %1, actual language - %2.', Comment = '%1 : target language ID, %2 : actual language ID.';
        RestoredLanguageIsNotEqualToTargetTxt: Label 'Restored language is not equal to target. To restore language - %1, actual language - %2.', Comment = '%1 : to restore language ID, %2 : actual language ID.';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure FireEventsOnCopySalesDocument()
    var
        FromSalesHeader: Record "Sales Header";
        ToSalesHeader: Record "Sales Header";
        CopyPurchSalesDocUT: Codeunit "Copy Purch/Sales Doc UT";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 170312] "Copy Document Mgt.".CopySalesDoc - fires OnBeforeCopySalesDocument and OnAfterCopySalesDocument events
        // [GIVEN] Source Sales Invoice with "No." = "X"
        // [GIVEN] Destination Sales Header "Y"
        BindSubscription(CopyPurchSalesDocUT);

        LibrarySales.CreateSalesInvoice(FromSalesHeader);
        CreateNewSalesHeader(FromSalesHeader."Sell-to Customer No.", ToSalesHeader);

        // [WHEN] When run "Copy Document Mgt.".CopySalesDoc
        RunCopySalesDoc(FromSalesHeader."No.", ToSalesHeader, SalesDocType::Invoice, false, false);

        // [THEN] Event OnBeforeCopySalesDocument fired with parameters FromDocType = "Invoice", FromDocNo = "X" and ToSalesHeader = "Y"
        VerifyEventArgs(SalesDocType::Invoice, FromSalesHeader."No.", ToSalesHeader.RecordId, BeforeSalesTxt);
        // [THEN] Event OnAfterCopySalesDocument fired with parameters FromDocType = "Invoice", FromDocNo = "X" and ToSalesHeader = "Y"
        VerifyEventArgs(SalesDocType::Invoice, FromSalesHeader."No.", ToSalesHeader.RecordId, AfterSalesTxt);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure FireEventsOnCopyPurchaseDocument()
    var
        FromPurchaseHeader: Record "Purchase Header";
        ToPurchaseHeader: Record "Purchase Header";
        CopyPurchSalesDocUT: Codeunit "Copy Purch/Sales Doc UT";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 170312] "Copy Document Mgt.".CopyPurchDoc - fires OnBeforeCopyPurchaseDocument and OnAfterCopyPurchaseDocument events
        // [GIVEN] Source Purchase Invoice with "No." = "X"
        // [GIVEN] Destination Purchase Header "Y"
        BindSubscription(CopyPurchSalesDocUT);

        LibraryPurchase.CreatePurchaseInvoice(FromPurchaseHeader);
        CreateNewPurchaseHeader(FromPurchaseHeader."Buy-from Vendor No.", ToPurchaseHeader);

        // [WHEN] When run "Copy Document Mgt.".CopyPurchDoc
        RunCopyPurchaseDoc(FromPurchaseHeader."No.", ToPurchaseHeader, PurchDocType::Invoice, false, false);

        // [THEN] Event OnBeforeCopyPurchaseDocument fired with parameters FromDocType = "Invoice", FromDocNo = "X" and ToPurchaseHeader = "Y"
        VerifyEventArgs(PurchDocType::Invoice, FromPurchaseHeader."No.", ToPurchaseHeader.RecordId, BeforePurchaseTxt);
        // [THEN] Event OnAfterCopyPurchaseDocument fired with parameters FromDocType = "Invoice", FromDocNo = "X" and ToPurchaseHeader = "Y"
        VerifyEventArgs(PurchDocType::Invoice, FromPurchaseHeader."No.", ToPurchaseHeader.RecordId, AfterPurchaseTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SwitchGlobalLanguageUT()
    var
        Language: Record Language;
        TranslationHelper: Codeunit "Translation Helper";
        DEU_ID: Integer;
        DAN_ID: Integer;
        SAVED_ID: Integer;
    begin
        // [FEATURE] [Language]
        // [SCENARIO 381564] Switch to target language by its code through Language Management, check current language ID to target ID, restore through Language Management and check again to saved language ID.

        // Save for tear Down.
        SAVED_ID := GlobalLanguage;

        // [GIVEN] Windows Language IDs of DEU and DAN from Language table.
        Language.Get('DEU');
        DEU_ID := Language."Windows Language ID";
        Language.Get('DAN');
        DAN_ID := Language."Windows Language ID";

        // [GIVEN] Set language to DEU by standard GLOBALLANGUAGE function.
        GlobalLanguage(DEU_ID);

        // [WHEN] Switch to DAN language through TranslationHelper.SetGlobalLanguageByCode('DAN') (code param) function
        TranslationHelper.SetGlobalLanguageByCode('DAN');

        // [THEN] Standard GLOBALLANGUAGE() returns ID of DAN.
        Assert.AreEqual(DAN_ID, GlobalLanguage, StrSubstNo(SwitchedToLanguageIsNotEqualToTargetTxt, DAN_ID, GlobalLanguage));

        // [WHEN] Switch back to DEU language through TranslationHelper.RestoreGlobalLanguage (no params) function
        TranslationHelper.RestoreGlobalLanguage;

        // [THEN] Standard GLOBALLANGUAGE() returns ID of DEU.
        Assert.AreEqual(DEU_ID, GlobalLanguage, StrSubstNo(RestoredLanguageIsNotEqualToTargetTxt, DAN_ID, GlobalLanguage));

        // Tear Down.
        GlobalLanguage(SAVED_ID);
    end;

    local procedure CreateNewSalesHeader(CustomerNo: Code[20]; var SalesHeader: Record "Sales Header")
    begin
        with SalesHeader do begin
            Init;
            Insert(true);
            Validate("Sell-to Customer No.", CustomerNo);
            Modify(true);
        end;
    end;

    local procedure CreateNewPurchaseHeader(VendorNo: Code[20]; var PurchaseHeader: Record "Purchase Header")
    begin
        with PurchaseHeader do begin
            Init;
            Insert(true);
            Validate("Buy-from Vendor No.", VendorNo);
            Modify(true);
        end;
    end;

    local procedure InsertBufferEntry(FromDocumentType: Option; FromDocumentNo: Code[20]; ToRecordID: RecordID; EventName: Text[250])
    var
        NameValueBuffer: Record "Name/Value Buffer";
    begin
        NameValueBuffer.Init;
        NameValueBuffer.Name := EventName;
        NameValueBuffer.Value := GetValueText(FromDocumentType, FromDocumentNo, ToRecordID);
        NameValueBuffer.Insert;
    end;

    local procedure GetValueText(FromDocumentType: Option; FromDocumentNo: Code[20]; ToRecordID: RecordID) Result: Text[250]
    begin
        Result :=
          CopyStr(
            StrSubstNo('%1 - %2 - %3', Format(FromDocumentType), FromDocumentNo, Format(ToRecordID)),
            1,
            MaxStrLen(Result));
        exit(Result);
    end;

    local procedure RunCopyPurchaseDoc(DocumentNo: Code[20]; NewPurchHeader: Record "Purchase Header"; DocType: Option; IncludeHeader: Boolean; RecalculateLines: Boolean)
    var
        CopyPurchDoc: Report "Copy Purchase Document";
    begin
        Clear(CopyPurchDoc);
        CopyPurchDoc.InitializeRequest(DocType, DocumentNo, IncludeHeader, RecalculateLines);
        CopyPurchDoc.SetPurchHeader(NewPurchHeader);
        CopyPurchDoc.UseRequestPage(false);
        CopyPurchDoc.RunModal;
    end;

    local procedure RunCopySalesDoc(DocumentNo: Code[20]; NewSalesHeader: Record "Sales Header"; DocType: Option; IncludeHeader: Boolean; RecalculateLines: Boolean)
    var
        CopySalesDoc: Report "Copy Sales Document";
    begin
        Clear(CopySalesDoc);
        CopySalesDoc.InitializeRequest(DocType, DocumentNo, IncludeHeader, RecalculateLines);
        CopySalesDoc.SetSalesHeader(NewSalesHeader);
        CopySalesDoc.UseRequestPage(false);
        CopySalesDoc.RunModal;
    end;

    local procedure VerifyEventArgs(FromDocumentType: Option; FromDocumentNo: Code[20]; ToRecordID: RecordID; ExpectedEventName: Text)
    var
        NameValueBuffer: Record "Name/Value Buffer";
    begin
        NameValueBuffer.SetRange(Name, ExpectedEventName);
        NameValueBuffer.FindFirst;
        Assert.AreEqual(
          GetValueText(FromDocumentType, FromDocumentNo, ToRecordID),
          NameValueBuffer.Value,
          'Wrong data passed in event');
    end;

    [EventSubscriber(ObjectType::Codeunit, 6620, 'OnBeforeCopySalesDocument', '', false, false)]
    local procedure DecreaseCounterOnBeforeCopySalesDocument(FromDocumentType: Option; FromDocumentNo: Code[20]; var ToSalesHeader: Record "Sales Header")
    begin
        InsertBufferEntry(FromDocumentType, FromDocumentNo, ToSalesHeader.RecordId, BeforeSalesTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, 6620, 'OnBeforeCopyPurchaseDocument', '', false, false)]
    local procedure DecreaseCounterOnBeforeCopyPurchaseDocument(FromDocumentType: Option; FromDocumentNo: Code[20]; var ToPurchaseHeader: Record "Purchase Header")
    begin
        InsertBufferEntry(FromDocumentType, FromDocumentNo, ToPurchaseHeader.RecordId, BeforePurchaseTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, 6620, 'OnAfterCopySalesDocument', '', false, false)]
    local procedure DecreaseCounterOnAfterCopySalesDocument(FromDocumentType: Option; FromDocumentNo: Code[20]; var ToSalesHeader: Record "Sales Header")
    begin
        InsertBufferEntry(FromDocumentType, FromDocumentNo, ToSalesHeader.RecordId, AfterSalesTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, 6620, 'OnAfterCopyPurchaseDocument', '', false, false)]
    local procedure DecreaseCounterOnAfterCopyPurchaseDocument(FromDocumentType: Option; FromDocumentNo: Code[20]; var ToPurchaseHeader: Record "Purchase Header")
    begin
        InsertBufferEntry(FromDocumentType, FromDocumentNo, ToPurchaseHeader.RecordId, AfterPurchaseTxt);
    end;
}

