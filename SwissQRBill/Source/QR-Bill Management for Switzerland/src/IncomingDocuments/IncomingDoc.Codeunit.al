codeunit 11516 "Swiss QR-Bill Incoming Doc"
{
    var
        QRBillMgt: Codeunit "Swiss QR-Bill Mgt.";
        ErrorLogContextRecordId: RecordId;
        IsAnyWarningLogged: Boolean;
        BlankedImportErr: Label 'There is no data to import.';
        ReplaceMainAttachmentQst: Label 'Are you sure you want to replace the attached file?';
        DocAlreadyCreatedErr: Label 'The document has already been created.';
        ConfirmNavigateDocAlreadyCreatedQst: Label 'The document has already been created. Do you want to open it?';
        ImportCompletedTxt: Label 'QR-Bill import has been successfully completed.';
        ImportCompletedWithWarningsTxt: Label 'QR-Bill import has been successfully completed with warnings.';
        ImportFailedTxt: Label 'QR-Bill import has been completed, but data parsing has been failed.';
        ImportFailedWithErrorsTxt: Label 'QR-Bill import has been completed, but data parsing has been failed. See error section for more details.';
        CreditorDetailsNotFoundTxt: Label 'Creditor''s detailed information is not found.';
        MatchWarningCreditorNameTxt: Label 'Creditor''s name %1 does not correspond to %2 from the vendor information.', Comment = '%1, %2 - actual\expected names';
        MatchWarningCreditorCityTxt: Label 'Creditor''s city %1 does not correspond to %2 from the vendor information.', Comment = '%1, %2 - actual\expected city value';
        MatchWarningCreditorPostCodeTxt: Label 'Creditor''s post code %1 does not correspond to %2 from the vendor information.', Comment = '%1, %2 - actual\expected post code value';
        MatchWarningCreditorCountryTxt: Label 'Creditor''s country %1 does not correspond to %2 from the vendor information.', Comment = '%1, %2 - actual\expected country value';
        DebitorDetailsNotFoundTxt: Label 'Debitor''s detailed information is not found.';
        MatchWarningDebitorNameTxt: Label 'Debitor''s name %1 does not correspond to %2 from the company information.', Comment = '%1, %2 - actual\expected names';
        MatchWarningDebitorCityTxt: Label 'Debitor''s city %1 does not correspond to %2 from the company information.', Comment = '%1, %2 - actual\expected city value';
        MatchWarningDebitorPostCodeTxt: Label 'Debitor''s post code %1 does not correspond to %2 from the company information.', Comment = '%1, %2 - actual\expected post code value';
        MatchWarningDebitorCountryTxt: Label 'Debitor''s country %1 does not correspond to %2 from the company information.', Comment = '%1, %2 - actual\expected country value';
        MatchCurrencyTxt: Label 'Currency %1 is assigned, but is not found in the system.', Comment = '%1 - currency code';
        QRReferenceDigitsTxt: Label 'QR refernce %1 must contain only digits.', Comment = '%1 - payment reference number\code';
        QRReferenceCheckDigitsTxt: Label 'QR reference %1 check digit is wrong.', Comment = '%1 - payment reference number\code';
        CreditorReferenceCheckDigitsTxt: Label 'Creditor reference %1 check digit is wrong.', Comment = '%1 - payment reference number\code';
        VendorNotFoundTxt: Label 'Vendor is not found with bank account IBAN = %1.', Comment = '%1 - IBAN value';

    internal procedure CreateNewIncomingDocFromQRBill(FromFile: Boolean)
    var
        IncomingDocument: Record "Incoming Document";
        QRCodeText: Text;
        FileName: Text;
    begin
        if QRBillImport(QRCodeText, FileName, FromFile) then begin
            IncomingDocument.CreateIncomingDocument(FileName, '');
            DecodeQRCodeToIncomingDocument(IncomingDocument, QRCodeText, FileName);
            if IncomingDocument.Find() then
                Page.Run(PAGE::"Incoming Document", IncomingDocument);
        end;
    end;

    internal procedure ImportQRBillToIncomingDoc(var IncomingDocument: Record "Incoming Document"; FromFile: Boolean)
    var
        QRCodeText: Text;
        FileName: Text;
    begin
        if IncomingDocRelatedRecNotExists(IncomingDocument, false) then
            if QRBillImport(QRCodeText, FileName, FromFile) then
                if ConfirmNewAttachment(IncomingDocument) then
                    DecodeQRCodeToIncomingDocument(IncomingDocument, QRCodeText, FileName);
    end;

    internal procedure CreateJournalAction(var IncomingDocument: Record "Incoming Document")
    begin
        IncomingDocument.TestField("Vendor No.");
        IncomingDocument.TestField("Vendor Bank Account No.");
        if IncomingDocRelatedRecNotExists(IncomingDocument, true) then
            IncomingDocument.CreateGenJnlLine();
    end;

    internal procedure CreatePurchaseInvoiceAction(var IncomingDocument: Record "Incoming Document")
    begin
        IncomingDocument.TestField("Vendor No.");
        if IncomingDocRelatedRecNotExists(IncomingDocument, true) then
            IncomingDocument.CreatePurchInvoice();
    end;

    local procedure CreateJournalFromIncDoc(var IncomingDocument: Record "Incoming Document"): Boolean
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
        RecordVariant: Variant;
        Sign: Decimal;
    begin
        if not IncomingDocument.GetRecord(RecordVariant) then
            exit(false);

        with GenJournalLine do begin
            GenJournalLine := RecordVariant;
            GenJournalTemplate.Get("Journal Template Name");

            if GenJournalTemplate.Type = GenJournalTemplate.Type::Purchases then begin
                Validate("Document Type", "Document Type"::Invoice);
                Sign := -1;
            end else begin
                Validate("Document Type", "Document Type"::Payment);
                Sign := 1;
            end;

            Validate("Account Type", "Account Type"::Vendor);
            if IncomingDocument."Vendor No." <> '' then begin
                Validate("Account No.", IncomingDocument."Vendor No.");
                if IncomingDocument."Vendor Bank Account No." <> '' then
                    Validate("Recipient Bank Account", IncomingDocument."Vendor Bank Account No.");
            end;

            Validate("Currency Code", GetCurrency(IncomingDocument."Currency Code"));
            Validate(Amount, Sign * IncomingDocument."Amount Incl. VAT");
            Validate("Transaction Information", CopyStr(IncomingDocument."Swiss QR-Bill Bill Info", 1, MaxStrLen("Transaction Information")));
            Validate("Message to Recipient", IncomingDocument."Swiss QR-Bill Unstr. Message");
            Validate(Description, QRBillMgt.GetQRBillCaption());
            Validate("Payment Reference", DelChr(IncomingDocument."Swiss QR-Bill Reference No."));
            Validate("External Document No.", IncomingDocument."Vendor Invoice No.");

            Modify(true);
        end;

        exit(true);
    end;

    local procedure CreatePurchaseInvoiceFromIncDoc(var IncomingDocument: Record "Incoming Document"; var PurchHeader: Record "Purchase Header"): Boolean
    begin
        if not PurchHeader.Find() then
            exit(false);

        with PurchHeader do begin
            if IncomingDocument."Vendor No." <> '' then
                Validate("Buy-from Vendor No.", IncomingDocument."Vendor No.");
            Validate("Posting Description", IncomingDocument."Swiss QR-Bill Unstr. Message");
            Validate("Currency Code", GetCurrency(IncomingDocument."Currency Code"));
            Validate("Payment Reference", DelChr(IncomingDocument."Swiss QR-Bill Reference No."));
            Validate("Vendor Invoice No.", IncomingDocument."Vendor Invoice No.");

            Modify(true);
        end;

        exit(true);
    end;

    local procedure ConfirmNewAttachment(IncomingDocument: Record "Incoming Document"): Boolean
    var
        MainIncomingDocumentAttachment: Record "Incoming Document Attachment";
    begin
        if not IncomingDocument.GetMainAttachment(MainIncomingDocumentAttachment) then
            exit(true);
        exit(Confirm(ReplaceMainAttachmentQst));
    end;

    local procedure QRBillImport(var QRCodeText: Text; var FileName: Text; FromFile: Boolean) Result: Boolean
    var
        QRBillScanPage: Page "Swiss QR-Bill Scan";
    begin
        if FromFile then
            Result := QRBillImportFromFile(QRCodeText, FileName)
        else begin
            QRBillScanPage.LookupMode(true);
            Result := QRBillScanPage.RunModal() = Action::LookupOK;
            if Result then
                QRCodeText := QRBillScanPage.GetQRBillText();
            FileName := QRBillMgt.GetQRBillCaption();
        end;

        if Result and (QRCodeText = '') then
            Error(BlankedImportErr);
    end;

    local procedure QRBillImportFromFile(var QRCodeText: Text; var FileName: Text): boolean
    var
        FileMgt: Codeunit "File Management";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
    begin
        FileName := FileMgt.BLOBImport(TempBlob, 'Import QR-Bill Text File');
        if TempBlob.HasValue() then begin
            TempBlob.CreateInStream(InStream);
            InStream.Read(QRCodeText);
        end;

        exit(FileName <> '');
    end;

    local procedure DecodeQRCodeToIncomingDocument(var IncomingDocument: Record "Incoming Document"; QRCodeText: Text; FileName: Text)
    var
        QRBillBuffer: Record "Swiss QR-Bill Buffer" temporary;
        QRBillDecode: Codeunit "Swiss QR-Bill Decode";
        Result: Boolean;
    begin
        UpdateIncomingDocumentMainAttachment(IncomingDocument, QRCodeText, FileName);
        ClearIncomingDocument(IncomingDocument);

        QRBillDecode.SetContextRecordId(IncomingDocument.RecordId());
        Result := QRBillDecode.DecodeQRCodeText(QRBillBuffer, QRCodeText);
        if Result then
            BusinessValidation(QRBillBuffer, IncomingDocument);

        IncomingDocument."Swiss QR-Bill" := true;
        IncomingDocument.Modify(true);
        Commit();

        if Result then begin
            if IsAnyWarningLogged then
                Message(ImportCompletedWithWarningsTxt)
            else
                Message(ImportCompletedTxt);
        end else
            if QRBillDecode.AnyErrorLogged() then
                Message(ImportFailedWithErrorsTxt)
            else
                Message(ImportFailedTxt);
    end;

    local procedure UpdateIncomingDocumentMainAttachment(var IncomingDocument: Record "Incoming Document"; QRCodeText: Text; FileName: Text)
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        FileMgt: Codeunit "File Management";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OutStream: OutStream;
    begin
        TempBlob.CreateOutStream(OutStream);
        TempBlob.CreateInStream(InStream);
        OutStream.Write(QRCodeText);
        if IncomingDocument.GetMainAttachment(IncomingDocumentAttachment) then
            IncomingDocumentAttachment.Delete();

        if FileName = '' then
            FileName := QRBillMgt.GetQRBillCaption();

        with IncomingDocumentAttachment do begin
            "Incoming Document Entry No." := IncomingDocument."Entry No.";
            Name := CopyStr(FileMgt.GetFileNameWithoutExtension(FileName), 1, MaxStrLen(Name));
            Validate("File Extension", 'txt');
            SetContentFromBlob(TempBlob);
            Insert(true);
        end;
    end;

    local procedure ClearIncomingDocument(var IncomingDocument: Record "Incoming Document")
    var
        ErrorMessage: Record "Error Message";
    begin
        ErrorMessage.SetContext(IncomingDocument.RecordId());
        ErrorMessage.ClearLog();

        with IncomingDocument do begin
            Clear("Vendor IBAN");
            Clear("Vendor VAT Registration No.");
            Clear("Amount Incl. VAT");
            Clear("Currency Code");
            Clear("Vendor Invoice No.");
            Clear("Swiss QR-Bill Reference Type");
            Clear("Swiss QR-Bill Reference No.");
            Clear("Swiss QR-Bill Unstr. Message");
            Clear("Swiss QR-Bill Bill Info");

            Clear("Vendor No.");
            Clear("Vendor Name");
            Clear("Vendor Bank Account No.");
            Clear("Swiss QR-Bill Vendor Address 1");
            Clear("Swiss QR-Bill Vendor Address 2");
            Clear("Swiss QR-Bill Vendor Post Code");
            Clear("Swiss QR-Bill Vendor City");
            Clear("Swiss QR-Bill Vendor Country");

            Clear("Swiss QR-Bill Debitor Name");
            Clear("Swiss QR-Bill Debitor Address1");
            Clear("Swiss QR-Bill Debitor Address2");
            Clear("Swiss QR-Bill Debitor PostCode");
            Clear("Swiss QR-Bill Debitor City");
            Clear("Swiss QR-Bill Debitor Country");
        end;
    end;

    local procedure BusinessValidation(var QRBillBuffer: Record "Swiss QR-Bill Buffer" temporary; var IncomingDocument: Record "Incoming Document")
    begin
        IsAnyWarningLogged := false;
        ErrorLogContextRecordId := IncomingDocument.RecordId();

        BusinessValidationVendorNo(QRBillBuffer, IncomingDocument);
        BusinessValidationCurrency(QRBillBuffer);
        BusinessValidationReferenceNo(QRBillBuffer);

        IncomingDocument."Vendor IBAN" := QRBillMgt.FormatIBAN(QRBillBuffer.IBAN);
        IncomingDocument."Amount Incl. VAT" := QRBillBuffer.Amount;
        IncomingDocument."Currency Code" := QRBillBuffer.Currency;
        IncomingDocument."Swiss QR-Bill Reference Type" := QRBillBuffer."Payment Reference Type";
        IncomingDocument."Swiss QR-Bill Reference No." :=
            QRBillMgt.FormatPaymentReference(QRBillBuffer."Payment Reference Type", QRBillBuffer."Payment Reference");
        IncomingDocument."Swiss QR-Bill Unstr. Message" := QRBillBuffer."Unstructured Message";
        IncomingDocument."Swiss QR-Bill Bill Info" := QRBillBuffer."Billing Information";

        BusinessValidationCreditor(QRBillBuffer, IncomingDocument);
        BusinessValidationDebitor(QRBillBuffer, IncomingDocument);
        BusinessValidationBillingInfo(QRBillBuffer, IncomingDocument);
    end;

    local procedure BusinessValidationCreditor(var QRBillBuffer: Record "Swiss QR-Bill Buffer" temporary; var IncomingDocument: Record "Incoming Document")
    var
        CreditorCustomer: Record Customer temporary;
        Vendor: Record Vendor;
    begin
        if QRBillBuffer.GetCreditorInfo(CreditorCustomer) then begin
            IncomingDocument."Vendor Name" := CreditorCustomer.Name;
            IncomingDocument."Swiss QR-Bill Vendor Address 1" := CreditorCustomer.Address;
            IncomingDocument."Swiss QR-Bill Vendor Address 2" := CreditorCustomer."Address 2";
            IncomingDocument."Swiss QR-Bill Vendor Post Code" := CreditorCustomer."Post Code";
            IncomingDocument."Swiss QR-Bill Vendor City" := CreditorCustomer.City;
            IncomingDocument."Swiss QR-Bill Vendor Country" := CreditorCustomer."Country/Region Code";

            if IncomingDocument."Vendor No." <> '' then
                if Vendor.Get(IncomingDocument."Vendor No.") then begin
                    if (Vendor."Country/Region Code" <> '') and (CreditorCustomer."Country/Region Code" <> '') and
                        (Vendor."Country/Region Code" <> CreditorCustomer."Country/Region Code")
                    then
                        LogWarning(StrSubstNo(MatchWarningCreditorCountryTxt, CreditorCustomer."Country/Region Code", Vendor."Country/Region Code"));

                    if (Vendor."Post Code" <> '') and (CreditorCustomer."Post Code" <> '') and
                        (Vendor."Post Code" <> CreditorCustomer."Post Code")
                    then
                        LogWarning(StrSubstNo(MatchWarningCreditorPostCodeTxt, CreditorCustomer."Post Code", Vendor."Post Code"));

                    if (Vendor.City <> '') and (CreditorCustomer.City <> '') then
                        if NotSimilarStrings(CreditorCustomer.City, Vendor.City) then
                            LogWarning(StrSubstNo(MatchWarningCreditorCityTxt, CreditorCustomer.City, Vendor.City));

                    if (Vendor.Name <> '') and (CreditorCustomer.Name <> '') then
                        if NotSimilarStrings(CreditorCustomer.Name, Vendor.Name) then
                            LogWarning(StrSubstNo(MatchWarningCreditorNameTxt, CreditorCustomer.Name, Vendor.Name));
                end;
        end else
            LogWarning(CreditorDetailsNotFoundTxt);
    end;

    local procedure BusinessValidationDebitor(var QRBillBuffer: Record "Swiss QR-Bill Buffer" temporary; var IncomingDocument: Record "Incoming Document")
    var
        DebitorCustomer: Record Customer temporary;
        CompanyInfo: Record "Company Information";
    begin
        if QRBillBuffer.GetUltimateDebitorInfo(DebitorCustomer) then begin
            IncomingDocument."Swiss QR-Bill Debitor Name" := DebitorCustomer.Name;
            IncomingDocument."Swiss QR-Bill Debitor Address1" := DebitorCustomer.Address;
            IncomingDocument."Swiss QR-Bill Debitor Address2" := DebitorCustomer."Address 2";
            IncomingDocument."Swiss QR-Bill Debitor PostCode" := DebitorCustomer."Post Code";
            IncomingDocument."Swiss QR-Bill Debitor City" := DebitorCustomer.City;
            IncomingDocument."Swiss QR-Bill Debitor Country" := DebitorCustomer."Country/Region Code";

            CompanyInfo.Get();
            if (CompanyInfo."Country/Region Code" <> '') and (DebitorCustomer."Country/Region Code" <> '') and
                (CompanyInfo."Country/Region Code" <> DebitorCustomer."Country/Region Code")
            then
                LogWarning(StrSubstNo(MatchWarningDebitorCountryTxt, DebitorCustomer."Country/Region Code", CompanyInfo."Country/Region Code"));

            if (CompanyInfo."Post Code" <> '') and (DebitorCustomer."Post Code" <> '') and
                (CompanyInfo."Post Code" <> DebitorCustomer."Post Code")
            then
                LogWarning(StrSubstNo(MatchWarningDebitorPostCodeTxt, DebitorCustomer."Post Code", CompanyInfo."Post Code"));

            if (CompanyInfo.City <> '') and (DebitorCustomer.City <> '') then
                if NotSimilarStrings(DebitorCustomer.City, CompanyInfo.City) then
                    LogWarning(StrSubstNo(MatchWarningDebitorCityTxt, DebitorCustomer.City, CompanyInfo.City));

            if (CompanyInfo.Name <> '') and (DebitorCustomer.Name <> '') then
                if NotSimilarStrings(DebitorCustomer.Name, CompanyInfo.Name) then
                    LogWarning(StrSubstNo(MatchWarningDebitorNameTxt, DebitorCustomer.Name, CompanyInfo.Name));
        end else
            LogWarning(DebitorDetailsNotFoundTxt);
    end;

    local procedure BusinessValidationBillingInfo(var QRBillBuffer: Record "Swiss QR-Bill Buffer" temporary; var IncomingDocument: Record "Incoming Document")
    var
        BillingDetail: Record "Swiss QR-Bill Billing Detail" temporary;
        BillingInfo: Codeunit "Swiss QR-Bill Billing Info";
    begin
        if BillingInfo.ParseBillingInfo(BillingDetail, QRBillBuffer."Billing Information") then
            with BillingDetail do begin
                SetRange("Tag Type", "Tag Type"::"VAT Registration No.");
                if FindFirst() then
                    IncomingDocument."Vendor VAT Registration No." := CopyStr(BillingDetail."Tag Value", 1, MaxStrLen(IncomingDocument."Vendor VAT Registration No."));

                Reset();
                SetRange("Tag Type", "Tag Type"::"Document No.");
                if FindFirst() then
                    IncomingDocument."Vendor Invoice No." := CopyStr(BillingDetail."Tag Value", 1, MaxStrLen(IncomingDocument."Vendor Invoice No."));
            end;
    end;

    local procedure NotSimilarStrings(Actual: Text; Expected: Text): Boolean
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        exit(TypeHelper.TextDistance(Actual, Expected) > (StrLen(Actual) / 3));
    end;

    local procedure BusinessValidationCurrency(var QRBillBuffer: Record "Swiss QR-Bill Buffer" temporary)
    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
    begin
        GLSetup.Get();
        if GLSetup."LCY Code" <> QRBillBuffer.Currency then
            if not Currency.Get(QRBillBuffer.Currency) then
                LogWarning(StrSubstNo(MatchCurrencyTxt, QRBillBuffer.Currency));
    end;

    local procedure BusinessValidationReferenceNo(var QRBillBuffer: Record "Swiss QR-Bill Buffer" temporary): Boolean
    var
        i: Integer;
    begin
        with QRBillBuffer do begin
            case "Payment Reference Type" of
                "Payment Reference Type"::"QR Reference":
                    begin
                        for i := 1 to StrLen("Payment Reference") do
                            if ("Payment Reference"[i] < '0') and ("Payment Reference"[i] > '9') then
                                exit(LogWarning(StrSubstNo(QRReferenceDigitsTxt, "Payment Reference")));
                        if not QRBillMgt.CheckDigitForQRReference("Payment Reference") then
                            LogWarning(StrSubstNo(QRReferenceCheckDigitsTxt, "Payment Reference"));
                    end;
                "Payment Reference Type"::"Creditor Reference (ISO 11649)":
                    if not QRBillMgt.CheckDigitForCreditorReference("Payment Reference") then
                        LogWarning(StrSubstNo(CreditorReferenceCheckDigitsTxt, "Payment Reference"));
            end;
            "Payment Reference" := QRBillMgt.FormatPaymentReference("Payment Reference Type", "Payment Reference");
        end;
    end;

    local procedure BusinessValidationVendorNo(var QRBillBuffer: Record "Swiss QR-Bill Buffer" temporary; var IncomingDocument: Record "Incoming Document")
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        QRBillBuffer.TestField(IBAN);
        if FindVendorBankAccount(VendorBankAccount, QRBillBuffer.IBAN) then begin
            IncomingDocument."Vendor No." := VendorBankAccount."Vendor No.";
            IncomingDocument."Vendor Bank Account No." := VendorBankAccount.Code;
            exit;
        end;

        LogWarning(StrSubstNo(VendorNotFoundTxt, QRBillBuffer.IBAN));
    end;

    local procedure FindVendorBankAccount(var VendorBankAccount: Record "Vendor Bank Account"; IBAN: Code[50]): Boolean
    begin
        if FindVendorBankAccountWithGivenIBAN(VendorBankAccount, CopyStr(DelChr(IBAN), 1, MaxStrLen(IBAN))) then
            exit(true);

        exit(FindVendorBankAccountWithGivenIBAN(VendorBankAccount, QRBillMgt.FormatIBAN(IBAN)));
    end;

    local procedure FindVendorBankAccountWithGivenIBAN(var VendorBankAccount: Record "Vendor Bank Account"; SearchIBAN: Code[50]): Boolean
    begin
        with VendorBankAccount do begin
            Reset();
            SetRange(IBAN, SearchIBAN);
            if FindFirst() then
                exit(true);
        end;

        exit(false);
    end;

    local procedure LogWarning(WarningDescription: Text): Boolean
    var
        ErrorMessage: Record "Error Message";
    begin
        IsAnyWarningLogged := true;
        ErrorMessage.SetContext(ErrorLogContextRecordId);
        ErrorMessage.LogSimpleMessage(ErrorMessage."Message Type"::Information, WarningDescription);
        exit(true);
    end;

    local procedure IncomingDocRelatedRecNotExists(IncomingDocument: Record "Incoming Document"; NavigateIfCreated: Boolean) Result: Boolean
    var
        RelatedRecord: Variant;
    begin
        Result := not IncomingDocument.GetRecord(RelatedRecord);
        if not Result then
            if not NavigateIfCreated then
                Error(DocAlreadyCreatedErr)
            else
                if Confirm(ConfirmNavigateDocAlreadyCreatedQst) then
                    IncomingDocument.ShowRecord();
    end;

    local procedure GetCurrency(CurrencyCode: Code[10]): Code[10]
    var
        GLSetup: Record "General Ledger Setup";
    begin
        if CurrencyCode <> '' then
            if GLSetup.Get() then
                if GLSetup."LCY Code" = CurrencyCode then
                    CurrencyCode := '';
        exit(CurrencyCode);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Incoming Document", 'OnBeforeGetJournalTemplateAndBatch', '', false, false)]
    local procedure OnBeforeGetJournalTemplateAndBatch(sender: Record "Incoming Document"; var JournalBatch: Code[10]; var JournalTemplate: Code[10]; var IsHandled: Boolean)
    var
        SwissQRBillSetup: Record "Swiss QR-Bill Setup";
    begin
        if not sender."Swiss QR-Bill" or IsHandled then
            exit;

        with SwissQRBillSetup do
            if Get() then begin
                TestField("Journal Template");
                TestField("Journal Batch");
                JournalTemplate := "Journal Template";
                JournalBatch := "Journal Batch";
                IsHandled := true;
            end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Incoming Document", 'OnAfterCreateGenJnlLineFromIncomingDocFail', '', false, false)]
    local procedure OnAfterCreateGenJnlLineFromIncomingDocFail(var IncomingDocument: Record "Incoming Document")
    begin
        if not IncomingDocument."Swiss QR-Bill" then
            exit;

        IncomingDocument.Status := IncomingDocument.Status::Failed;
        IncomingDocument.Modify();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Incoming Document", 'OnAfterCreateGenJnlLineFromIncomingDocSuccess', '', false, false)]
    local procedure OnAfterCreateGenJnlLineFromIncomingDocSuccess(var IncomingDocument: Record "Incoming Document")
    begin
        if not IncomingDocument."Swiss QR-Bill" then
            exit;

        if CreateJournalFromIncDoc(IncomingDocument) then
            IncomingDocument.Status := IncomingDocument.Status::Created
        else
            IncomingDocument.Status := IncomingDocument.Status::Failed;
        IncomingDocument.Modify();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Incoming Document", 'OnAfterCreatePurchHeaderFromIncomingDoc', '', false, false)]
    local procedure OnAfterCreatePurchHeaderFromIncomingDoc(var sender: Record "Incoming Document"; var PurchHeader: Record "Purchase Header")
    begin
        if not sender."Swiss QR-Bill" then
            exit;

        if CreatePurchaseInvoiceFromIncDoc(sender, PurchHeader) then
            sender.Status := sender.Status::Created
        else
            sender.Status := sender.Status::Failed;
        sender.Modify();
    end;
}
