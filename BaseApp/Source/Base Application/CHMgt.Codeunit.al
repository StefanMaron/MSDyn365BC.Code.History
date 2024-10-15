codeunit 11503 CHMgt
{

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'No valid ESR bank has been defined. You can define an ESR bank in three areas:\1. ESR bank from requestform\2. Payment type on customer or sales header\3. Main bank in ESR setup.';
        Text004: Label 'The reference number must have 27 characters. Please check the ESR setup.';
        CannotAssignReferenceNoMsg: Label 'The Reference No. field could not be filled automatically because more than one vendor ledger entry exist for the payment.';

    procedure PrepareEsr(_Head: Record "Sales Invoice Header"; var _EsrBank: Record "ESR Setup"; var _EsrType: Option Default,ESR,"ESR+"; var _Adr: array[8] of Text[100]; var _AmtTxt: Text[30]; var _CurrencyCode: Code[10]; var _DocType: Text[10]; var _RefNo: Text[35]; var _CodingLine: Text[100])
    var
        Amt: Decimal;
    begin
        // *** A D D R E S S
        _Adr[1] := _Head."Bill-to Name";
        _Adr[2] := _Head."Bill-to Contact";
        _Adr[3] := _Head."Bill-to Address";
        _Adr[4] := _Head."Bill-to Address 2";
        _Adr[5] := _Head."Bill-to Post Code" + ' ' + _Head."Bill-to City";
        CompressArray(_Adr);

        // *** P R E P A R E   A M O U N T  - i.e. 25.82
        _Head.CalcFields("Amount Including VAT");
        Amt := _Head."Amount Including VAT";

        PrepareEsrConsolidate(_EsrBank, _EsrType, _AmtTxt, _CurrencyCode, _DocType, _RefNo, _CodingLine, _Head."Currency Code",
          _Head."Payment Method Code", _Head."No.", Amt);
    end;

    procedure PrepareEsrService(_Head: Record "Service Invoice Header"; var _EsrBank: Record "ESR Setup"; var _EsrType: Option Default,ESR,"ESR+"; var _Adr: array[8] of Text[100]; var _AmtTxt: Text[30]; var _CurrencyCode: Code[10]; var _DocType: Text[10]; var _RefNo: Text[35]; var _CodingLine: Text[100])
    var
        ServiceInvoiceLine: Record "Service Invoice Line";
        Amt: Decimal;
    begin
        // *** A D D R E S S
        _Adr[1] := _Head."Bill-to Name";
        _Adr[2] := _Head."Bill-to Contact";
        _Adr[3] := _Head."Bill-to Address";
        _Adr[4] := _Head."Bill-to Address 2";
        _Adr[5] := _Head."Bill-to Post Code" + ' ' + _Head."Bill-to City";
        CompressArray(_Adr);

        // *** P R E P A R E   A M O U N T  - i.e. 25.82
        ServiceInvoiceLine.SetRange("Document No.", _Head."No.");
        ServiceInvoiceLine.CalcSums("Amount Including VAT");
        Amt := ServiceInvoiceLine."Amount Including VAT";

        PrepareEsrConsolidate(_EsrBank, _EsrType, _AmtTxt, _CurrencyCode, _DocType, _RefNo, _CodingLine, _Head."Currency Code",
          _Head."Payment Method Code", _Head."No.", Amt);
    end;

    local procedure PrepareEsrConsolidate(var _EsrBank: Record "ESR Setup"; var _EsrType: Option Default,ESR,"ESR+"; var _AmtTxt: Text[30]; var _CurrencyCode: Code[10]; var _DocType: Text[10]; var _RefNo: Text[35]; var _CodingLine: Text[100]; _CurrencyCode2: Code[10]; _PaymentMethodCode: Code[10]; _No: Code[20]; Amt: Decimal)
    var
        GlSetup: Record "General Ledger Setup";
        BankMgt: Codeunit BankMgt;
        InvoiceNo: Text[8];
        CheckDigit: Text[2];
        AmtUnits: Decimal;
        AmtDecimals: Decimal;
        AmtUnitsTxt: Text[10];
        AmtDecimalsTxt: Text[20];
        OcrAmt: Text[20];
        OcrRefNo: Text[50];
        OcrAccNo: Code[20];
        OcrTypeESR: Text[2];
        OcrTypeEsrPlus: Text[3];
        ReqESRBankCode: Code[20];
    begin
        _RefNo := '';
        _AmtTxt := '';
        _CodingLine := '';

        GlSetup.Get();

        if _EsrBank."Bank Code" <> '' then
            ReqESRBankCode := _EsrBank."Bank Code";
        Clear(_EsrBank);

        // *** D E F I N E   C U R R E N C Y
        _CurrencyCode := '';
        case _CurrencyCode2 of
            '', GlSetup."LCY Code":
                begin
                    _CurrencyCode := 'CHF';
                    _DocType := '609';
                    OcrTypeESR := '01';
                    OcrTypeEsrPlus := '042';
                end;

            'EUR':
                begin
                    _CurrencyCode := 'EUR';
                    _DocType := '701';
                    OcrTypeESR := '21';
                    OcrTypeEsrPlus := '319';
                end;
        end;

        // Exit if not CHF or EUR
        if _CurrencyCode = '' then
            exit;

        // *** G E T   E S R   B A N K  - 1. requestform, 2. pmt type of head, 3. main bank
        if not _EsrBank.Get(ReqESRBankCode) then
            if _PaymentMethodCode <> '' then begin
                _EsrBank.SetRange("ESR Payment Method Code", _PaymentMethodCode);
                if not _EsrBank.FindFirst then;
            end;


        if _EsrBank."Bank Code" = '' then begin
            _EsrBank.Reset();
            _EsrBank.SetRange("ESR Main Bank", true);
            if not _EsrBank.FindFirst then
                Error(Text000);  // ESR Bank not found
        end;

        // ESR Type according to bank
        if _EsrType = _EsrType::Default then
            _EsrType := _EsrBank."ESR System" + 1;

        // *** P R E P A R E   R E F   N O
        // 27 digits: 11 x BESR ID + 0000000 + 8 x InvNo + checkdigit
        InvoiceNo := CopyStr('00000000', 1, 8 - StrLen(_No)) + _No;
        _RefNo := _EsrBank."BESR Customer ID" + '0000000' + InvoiceNo;
        if StrLen(_RefNo) <> 26 then
            Error(Text004);

        CheckDigit := BankMgt.CalcCheckDigit(_RefNo);
        _RefNo := _RefNo + CheckDigit;
        OcrRefNo := _RefNo;

        // 5er blocks refno
        _RefNo := CopyStr(_RefNo, 1, 2) + ' ' + CopyStr(_RefNo, 3, 5) + ' ' + CopyStr(_RefNo, 8, 5) + ' ' +
          CopyStr(_RefNo, 13, 5) + ' ' + CopyStr(_RefNo, 18, 5) + ' ' + CopyStr(_RefNo, 23, 5);

        if _CurrencyCode = 'CHF' then
            Amt := Round(Amt, 0.05)
        else
            Amt := Round(Amt, 0.01);

        // Split units and decimals
        AmtUnits := Round(Amt, 1, '<');
        AmtDecimals := (Amt - AmtUnits) * 100;
        AmtUnitsTxt := Format(AmtUnits, 8, '<Integer>');
        AmtDecimalsTxt := ConvertStr(Format(AmtDecimals, 2, 2), ' ', '0');  // Trailing 0
        _AmtTxt := AmtUnitsTxt + AmtDecimalsTxt;

        // Prepare OCR amt 12 digits + checkdigit: 0100000025803
        OcrAmt := OcrTypeESR + ConvertStr(AmtUnitsTxt, ' ', '0') + AmtDecimalsTxt;
        CheckDigit := BankMgt.CalcCheckDigit(OcrAmt);
        OcrAmt := OcrAmt + CheckDigit;

        // *** E S R   A C C O U N T   N O  - Expand and remove dashes
        OcrAccNo := BankMgt.CheckPostAccountNo(_EsrBank."ESR Account No.");
        OcrAccNo := DelChr(OcrAccNo, '=', '-');

        // *** C O D I N G   L I N E - for ESR/ESR+
        if _EsrType = _EsrType::ESR then
            _CodingLine := OcrAmt + '>' + OcrRefNo + '+ ' + OcrAccNo + '>';

        if _EsrType = _EsrType::"ESR+" then begin
            _CodingLine := '          ' + OcrTypeEsrPlus + '>' + OcrRefNo + '+ ' + OcrAccNo + '>';
            _AmtTxt := '';
        end;
    end;

    [Scope('OnPrem')]
    procedure ReplaceXMLNamespaceCaption(var TempBlob: Codeunit "Temp Blob"; OldCaption: Text; NewCaption: Text)
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
        OutStream: OutStream;
        XMLText: Text;
        XMLNamespaceStringTemplate: Text;
        XMLNamespaceString: Text;
        Position: Integer;
    begin
        TempBlob.CreateInStream(InStream, TEXTENCODING::UTF8);
        XMLText := TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.CRLFSeparator);
        XMLNamespaceStringTemplate := '<Document xmlns="%1">';

        XMLNamespaceString := StrSubstNo(XMLNamespaceStringTemplate, OldCaption);
        Position := StrPos(XMLText, XMLNamespaceString);
        XMLText := DelStr(XMLText, Position, StrLen(XMLNamespaceString));

        XMLNamespaceString := StrSubstNo(XMLNamespaceStringTemplate, NewCaption);
        XMLText := InsStr(XMLText, XMLNamespaceString, Position);
        TempBlob.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.WriteText(XMLText);
    end;

    [Scope('OnPrem')]
    procedure IsSwissSEPACTExport(GenJournalLine: Record "Gen. Journal Line"): Boolean
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        BankAccount: Record "Bank Account";
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        if GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name") then
            if BankAccount.Get(GenJournalBatch."Bal. Account No.") then
                if BankExportImportSetup.Get(BankAccount."Payment Export Format") then
                    exit(BankExportImportSetup."Processing Codeunit ID" = CODEUNIT::"Swiss SEPA CT-Export File");
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure IsSwissSEPADDExport(DirectDebitCollectionNo: Integer): Boolean
    var
        DirectDebitCollection: Record "Direct Debit Collection";
        BankAccount: Record "Bank Account";
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        if DirectDebitCollection.Get(DirectDebitCollectionNo) then
            if BankAccount.Get(DirectDebitCollection."To Bank Account No.") then
                if BankExportImportSetup.Get(BankAccount."SEPA Direct Debit Exp. Format") then
                    exit(BankExportImportSetup."Processing Codeunit ID" = CODEUNIT::"Swiss SEPA DD-Export File");
    end;

    [Scope('OnPrem')]
    procedure IsSwissSEPACTImport(BankAccountNo: Code[20]): Boolean
    var
        BankAccount: Record "Bank Account";
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        if BankAccount.Get(BankAccountNo) then
            if BankExportImportSetup.Get(BankAccount."Bank Statement Import Format") then
                exit(
                  BankExportImportSetup."Processing Codeunit ID" in
                  [CODEUNIT::"SEPA CAMT 053 Bank Rec. Lines", CODEUNIT::"SEPA CAMT 054 Bank Rec. Lines"]);
    end;

    [Scope('OnPrem')]
    procedure IsDomesticIBAN(IBAN: Code[50]): Boolean
    var
        DtaMgt: Codeunit DtaMgt;
    begin
        exit(CopyStr(DtaMgt.IBANDELCHR(IBAN), 1, 2) in ['CH', 'LI']);
    end;

    [Scope('OnPrem')]
    procedure IsDomesticCurrency(CurrencyCode: Code[10]): Boolean
    var
        DtaMgt: Codeunit DtaMgt;
    begin
        exit(DtaMgt.GetIsoCurrencyCode(CurrencyCode) in ['CHF', 'EUR']);
    end;

    [Scope('OnPrem')]
    procedure IsSEPACountry(CountryCode: Code[10]): Boolean
    var
        CountryRegion: Record "Country/Region";
    begin
        if not CountryRegion.Get(CountryCode) then
            exit(false);

        exit(
          CountryCode in
          ['BE', 'BG', 'DK', 'DE', 'EE', 'FI', 'FR', 'GI', 'GR', 'GB', 'IE', 'IS', 'IT', 'HR', 'LV', 'LI', 'LT', 'LU',
           'MT', 'MC', 'NL', 'NO', 'AT', 'PL', 'PT', 'RO', 'SE', 'CH', 'SK', 'SI', 'ES', 'CZ', 'HU', 'CY']);
    end;

    [Scope('OnPrem')]
    procedure IsESRFormat(RefNo: Text): Boolean
    var
        BankMgt: Codeunit BankMgt;
        CheckDigit: Text[1];
    begin
        if DelChr(RefNo, '=', '1234567890') <> '' then
            exit(false);

        if StrLen(RefNo) <> 27 then
            exit(false);

        CheckDigit := CopyStr(Format(RefNo[StrLen(RefNo)]), 1, MaxStrLen(CheckDigit));
        if BankMgt.CalcCheckDigit(PadStr(RefNo, StrLen(RefNo) - 1)) <> CheckDigit then
            exit(false);

        exit(true);
    end;

    local procedure CopyReferenceFromVLEToGenJournalLine(VendorLedgerEntry: Record "Vendor Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line")
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        if VendorLedgerEntry."Reference No." = '' then
            exit;

        with VendorBankAccount do begin
            Get(VendorLedgerEntry."Vendor No.", VendorLedgerEntry."Recipient Bank Account");
            if ("Payment Form" = "Payment Form"::ESR) and ("ESR Type" = "ESR Type"::"5/15") then begin
                GenJournalLine."Reference No." := CopyStr(VendorLedgerEntry."Reference No.", 1, 15);
                if StrLen(GenJournalLine."Reference No.") > 15 then
                    GenJournalLine.Checksum := CopyStr(VendorLedgerEntry."Reference No.", 17, 2);
            end else
                GenJournalLine."Reference No." := VendorLedgerEntry."Reference No.";
        end;

        GenJournalLine."Recipient Bank Account" := VendorLedgerEntry."Recipient Bank Account";
    end;

    local procedure FindFirstVendLedgEntryWithAppliesToID(var VendorLedgerEntry: Record "Vendor Ledger Entry"; AccNo: Code[20]; AppliesToID: Code[50]): Boolean
    begin
        with VendorLedgerEntry do begin
            Reset;
            SetCurrentKey("Vendor No.", "Applies-to ID", Open);
            SetRange("Vendor No.", AccNo);
            SetRange("Applies-to ID", AppliesToID);
            SetRange(Open, true);
            exit(FindSet);
        end;
    end;

    local procedure FindFirstVendLedgEntryWithAppliesToDocNo(var VendorLedgerEntry: Record "Vendor Ledger Entry"; AccNo: Code[20]; AppliestoDocType: Enum "Gen. Journal Document Type"; AppliestoDocNo: Code[20]): Boolean
    begin
        with VendorLedgerEntry do begin
            Reset;
            SetCurrentKey("Document No.");
            SetRange("Document No.", AppliestoDocNo);
            SetRange("Document Type", AppliestoDocType);
            SetRange("Vendor No.", AccNo);
            SetRange(Open, true);
            exit(FindFirst);
        end;
    end;

    local procedure SendReferenceNoCollisionNotification()
    var
        ReferenceNoNotificaiton: Notification;
    begin
        ReferenceNoNotificaiton.Id := GetReferenceNoCollisionNotificationId;
        ReferenceNoNotificaiton.Recall;

        ReferenceNoNotificaiton.Message := CannotAssignReferenceNoMsg;
        ReferenceNoNotificaiton.Scope := NOTIFICATIONSCOPE::LocalScope;
        ReferenceNoNotificaiton.Send;
    end;

    local procedure GetReferenceNoCollisionNotificationId(): Guid
    begin
        exit('957D62D7-3D00-4C8F-A3B0-D14DBC9EC4FD');
    end;

    [Scope('OnPrem')]
    procedure NoOfPaymentsForBatchBooking(): Integer
    begin
        exit(50);
    end;

    [EventSubscriber(ObjectType::Report, 393, 'OnBeforeUpdateGnlJnlLineDimensionsFromTempBuffer', '', false, false)]
    local procedure SuggestVendorPaymentUpdatePaymentLine(var GenJournalLine: Record "Gen. Journal Line"; TempPaymentBuffer: Record "Payment Buffer" temporary)
    begin
        // NewDescription = Description + ', ' + ExternalDocNo, where Description is truncated to fit full ExternalDocNo value
        if TempPaymentBuffer."Applies-to Ext. Doc. No." <> '' then
            GenJournalLine.Description :=
              Format(
                CopyStr(
                  GenJournalLine.Description,
                  1, MaxStrLen(GenJournalLine.Description) - StrLen(TempPaymentBuffer."Applies-to Ext. Doc. No.") - 2) +
                ', ' + TempPaymentBuffer."Applies-to Ext. Doc. No.",
                -MaxStrLen(GenJournalLine.Description));
    end;

    [EventSubscriber(ObjectType::Table, 372, 'OnCopyFieldsFromVendorLedgerEntry', '', false, false)]
    local procedure HandleOnCopyFieldsFromVendorLedgerEntry(VendorLedgerEntrySource: Record "Vendor Ledger Entry"; var PaymentBufferTarget: Record "Payment Buffer")
    begin
        PaymentBufferTarget."Reference No." := VendorLedgerEntrySource."Reference No.";
    end;

    [EventSubscriber(ObjectType::Table, 372, 'OnCopyFieldsToGenJournalLine', '', false, false)]
    local procedure HandleOnCopyFieldsToGenJournalLine(PaymentBufferSource: Record "Payment Buffer"; var GenJournalLineTarget: Record "Gen. Journal Line")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        if PaymentBufferSource."Vendor Ledg. Entry No." <> 0 then begin
            GenJournalLineTarget."Reference No." := PaymentBufferSource."Reference No.";
            VendorLedgerEntry.Get(PaymentBufferSource."Vendor Ledg. Entry No.");
            if VendorLedgerEntry."Recipient Bank Account" <> '' then
                GenJournalLineTarget.Validate("Recipient Bank Account", VendorLedgerEntry."Recipient Bank Account");
        end;
    end;

    [EventSubscriber(ObjectType::Table, 81, 'OnAfterSetJournalLineFieldsFromApplication', '', false, false)]
    local procedure HandleOnAfterSetJournalLineFieldsFromApplication(var GenJournalLine: Record "Gen. Journal Line"; AccType: Option "G/L Account",Customer,Vendor,"Bank Account","Fixed Asset","IC Partner",Employee; AccNo: Code[20]; xGenJournalLine: Record "Gen. Journal Line")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        with GenJournalLine do
            if AccType = AccType::Vendor then begin
                "Reference No." := '';
                if "Applies-to ID" <> '' then begin
                    if FindFirstVendLedgEntryWithAppliesToID(VendorLedgerEntry, AccNo, "Applies-to ID") then
                        if VendorLedgerEntry.Next = 0 then
                            CopyReferenceFromVLEToGenJournalLine(VendorLedgerEntry, GenJournalLine)
                        else
                            SendReferenceNoCollisionNotification;
                end else
                    if "Applies-to Doc. No." <> '' then
                        if FindFirstVendLedgEntryWithAppliesToDocNo(VendorLedgerEntry, AccNo, "Applies-to Doc. Type", "Applies-to Doc. No.") then
                            CopyReferenceFromVLEToGenJournalLine(VendorLedgerEntry, GenJournalLine);
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, 57, 'OnAfterSalesLineSetFilters', '', false, false)]
    local procedure HandleOnAfterSalesLineSetFilters(var TotalSalesLine: Record "Sales Line"; SalesLine: Record "Sales Line")
    begin
        TotalSalesLine.SetFilter("Quote Variant", '<>%1', TotalSalesLine."Quote Variant"::Variant);
    end;

    [EventSubscriber(ObjectType::Codeunit, 57, 'OnAfterSalesCheckIfDocumentChanged', '', false, false)]
    local procedure HandleOnAfterSalesCheckIfDocumentChanged(SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; var TotalsUpToDate: Boolean)
    begin
        if SalesLine."Quote Variant" <> xSalesLine."Quote Variant" then
            TotalsUpToDate := false;
    end;

    [EventSubscriber(ObjectType::Codeunit, 57, 'OnCalculateSalesSubPageTotalsOnAfterSetFilters', '', false, false)]
    local procedure HandleOnCalculateSalesSubPageTotalsOnAfterSetFilters(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.SetFilter("Quote Variant", '<>%1', SalesLine."Quote Variant"::Variant);
    end;
}

