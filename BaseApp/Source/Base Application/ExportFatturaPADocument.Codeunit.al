codeunit 12179 "Export FatturaPA Document"
{
    EventSubscriberInstance = Manual;
    TableNo = "Record Export Buffer";

    trigger OnRun()
    var
        RecordExportBuffer: Record "Record Export Buffer";
        TempFatturaHeader: Record "Fattura Header" temporary;
        TempFatturaLine: Record "Fattura Line" temporary;
        HeaderRecRef: RecordRef;
        XMLServerPath: Text[250];
    begin
        HeaderRecRef.Get(RecordID);
        FatturaDocHelper.InitializeErrorLog(Rec);
        FatturaDocHelper.CollectDocumentInformation(TempFatturaHeader, TempFatturaLine, HeaderRecRef);

        RecordExportBuffer.SetView(GetView);
        RecordExportBuffer.FindFirst;

        if TempFatturaHeader."Progressive No." <> '' then begin
            if RecordExportBuffer.ID = ID then begin
                ZipFileName := FatturaDocHelper.GetFileName(TempFatturaHeader."Progressive No.") + '.zip'
            end else
                ZipFileName := RecordExportBuffer.ZipFileName;
            ClientFileName := FatturaDocHelper.GetFileName(TempFatturaHeader."Progressive No.") + '.xml';
        end;
        if not FatturaDocHelper.HasErrors then
            XMLServerPath := GenerateXMLFile(TempFatturaLine, TempFatturaHeader, ClientFileName);

        ServerFilePath := XMLServerPath;
        Modify;
    end;

    var
        CompanyInformation: Record "Company Information";
        TempXMLBuffer: Record "XML Buffer" temporary;
        FatturaDocHelper: Codeunit "Fattura Doc. Helper";
        YesTok: Label 'SI', Locked = true;

    [Scope('OnPrem')]
    procedure GenerateXMLFile(var TempFatturaLine: Record "Fattura Line" temporary; TempFatturaHeader: Record "Fattura Header" temporary; ClientFileName: Text[250]): Text[250]
    var
        FileManagement: Codeunit "File Management";
        ExportFatturaPADocument: Codeunit "Export FatturaPA Document";
        DirectoryName: Text;
        ServerFileName: Text[250];
        FileName: Text;
    begin
        CompanyInformation.Get();
        BindSubscription(ExportFatturaPADocument);
        // prepare files
        ServerFileName := CopyStr(FileManagement.ServerTempFileName('xml'), 1, MaxStrLen(ServerFileName));
        DirectoryName := FileManagement.GetDirectoryName(ServerFileName);
        FileName := DirectoryName + '\' + ClientFileName;

        // create file
        CreateFatturaElettronicaHeader(TempFatturaHeader);
        CreateFatturaElettronicaBody(TempFatturaLine, TempFatturaHeader);

        // update Buffer
        TempXMLBuffer.FindFirst;
        TempXMLBuffer.Save(FileName);
        exit(CopyStr(FileName, 1, 250))
    end;

    local procedure CreateFatturaElettronicaHeader(TempFatturaHeader: Record "Fattura Header" temporary)
    var
        Customer: Record Customer;
    begin
        CreateXMLDefinition(TempFatturaHeader);
        if TempFatturaHeader."Customer No" = '' then
            GetCustomerAsCurrentCompany(Customer)
        else
            Customer.Get(TempFatturaHeader."Customer No");
        PopulateTransmissionData(TempFatturaHeader, Customer);
        PopulateCompanyInformation(Customer);
        PopulateTaxRepresentative(TempFatturaHeader);
        PopulateCustomerData(Customer);
    end;

    local procedure CreateFatturaElettronicaBody(var TempFatturaLine: Record "Fattura Line" temporary; TempFatturaHeader: Record "Fattura Header" temporary)
    begin
        PopulateDocGeneralData(TempFatturaHeader);
        PopulateDocDiscountData(TempFatturaHeader);

        with TempXMLBuffer do begin
            // fill in General, Order Data
            PopulateOrderData(TempFatturaLine, TempFatturaHeader);

            PopulateApplicationData(TempFatturaHeader);

            // 2.1.8 DatiDDT
            PopulateShipmentData(TempFatturaLine);

            // 2.2 DatiBeniServizi - Goods/Services data
            GetParent;
            AddGroupElement('DatiBeniServizi');
            TempFatturaLine.Reset();
            TempFatturaLine.SetRange("Line Type", TempFatturaLine."Line Type"::Document);
            if TempFatturaLine.FindSet then
                repeat
                    PopulateLineData(TempFatturaLine);
                until TempFatturaLine.Next = 0;

            // fill in LineVATData
            TempFatturaLine.Reset();
            TempFatturaLine.SetRange("Line Type", TempFatturaLine."Line Type"::VAT);
            if TempFatturaLine.FindSet then
                repeat
                    PopulateLineVATData(TempFatturaLine);
                until TempFatturaLine.Next = 0;
            GetParent;
            PopulatePaymentData(TempFatturaLine, TempFatturaHeader);
            GetParent;
            PopulateDocumentAttachments(TempFatturaHeader);
        end;
    end;

    local procedure CreateXMLDefinition(TempFatturaHeader: Record "Fattura Header" temporary)
    begin
        with TempXMLBuffer do begin
            CreateRootElement('p:FatturaElettronica');
            AddAttribute('versione', TempFatturaHeader."Transmission Type");
            AddNamespace('ds', 'http://www.w3.org/2000/09/xmldsig#');
            AddNamespace('p', 'http://ivaservizi.agenziaentrate.gov.it/docs/xsd/fatture/v1.2');
            AddNamespace('xsi', 'http://www.w3.org/2001/XMLSchema-instance');
        end;
    end;

    local procedure IsValidFatturaCharacter(InputChar: Char): Boolean
    var
        IsValid: Boolean;
    begin
        // Fattura expected standard is ISO 8859-1, that is 8-bit character code page
        // Special characters "'&<> are escaped later on xml file saving
        IsValid := InputChar in [1 .. 255];

        OnIsValidFatturaCharacter(InputChar, IsValid);

        exit(IsValid);
    end;

    local procedure GetFatturaValidSubstText(InputChar: Char) Result: Text
    var
        CharCode: Integer;
    begin
        CharCode := InputChar;
        if CharCode = 8364 then
            Result := 'EUR'
        else
            Result := '_';

        OnGetFatturaValidCharacter(InputChar, Result);
    end;

    local procedure GetCustomerAsCurrentCompany(var Customer: Record Customer)
    var
        FatturaSetup: Record "Fattura Setup";
    begin
        Customer.Init();
        Customer."Country/Region Code" := CompanyInformation."Country/Region Code";
        Customer."Fiscal Code" := CompanyInformation."Fiscal Code";
        Customer."VAT Registration No." := CompanyInformation."VAT Registration No.";
        Customer.Name := CompanyInformation.Name;
        Customer.Address := CompanyInformation.Address;
        Customer."Post Code" := CompanyInformation."Post Code";
        Customer.County := CompanyInformation.County;
        Customer.City := CompanyInformation.City;
        FatturaSetup.Get();
        FatturaSetup.TestField("Company PA Code");
        Customer."PA Code" := FatturaSetup."Company PA Code";
    end;

    local procedure FormatAmount(Amount: Decimal): Text[250]
    begin
        exit(Format(Amount, 0, '<Precision,2:2><Standard Format,9>'))
    end;

    local procedure FormatAmountEightDecimalPlaces(Amount: Decimal): Text[250]
    begin
        exit(Format(Amount, 0, '<Sign><Integer><Decimals,8><Comma,.>'))
    end;

    local procedure FormatQuantity(Amount: Decimal): Text[250]
    begin
        if Amount = 0 then
            exit('');
        exit(Format(Amount, 0, '<Precision,2:5><Standard Format,9>'))
    end;

    local procedure FormatDate(DateToFormat: Date): Text
    begin
        if DateToFormat = 0D then
            exit('');
        exit(Format(DateToFormat, 0, '<Standard Format,9>'));
    end;

    local procedure PopulateTransmissionData(TempFatturaHeader: Record "Fattura Header" temporary; Customer: Record Customer)
    var
        TransmissionIntermediaryVendor: Record Vendor;
    begin
        // Section 1.1 DatiTrasmissione
        if CompanyInformation."Transmission Intermediary No." <> '' then
            if TransmissionIntermediaryVendor.Get(CompanyInformation."Transmission Intermediary No.") then;

        with TempXMLBuffer do begin
            AddGroupElement('FatturaElettronicaHeader');
            AddGroupElement('DatiTrasmissione');

            AddGroupElement('IdTrasmittente');
            if TransmissionIntermediaryVendor."No." = '' then begin
                AddNonEmptyElement('IdPaese', CompanyInformation."Country/Region Code");
                if CompanyInformation."Fiscal Code" = '' then
                    AddNonEmptyLastElement('IdCodice', CompanyInformation."VAT Registration No.")
                else
                    AddNonEmptyLastElement('IdCodice', CompanyInformation."Fiscal Code");
            end else begin
                AddNonEmptyElement('IdPaese', TransmissionIntermediaryVendor."Country/Region Code");
                AddNonEmptyLastElement('IdCodice', TransmissionIntermediaryVendor."Fiscal Code");
            end;

            AddNonEmptyElement('ProgressivoInvio', TempFatturaHeader."Progressive No.");
            AddNonEmptyElement('FormatoTrasmissione', TempFatturaHeader."Transmission Type");
            AddNonEmptyElement('CodiceDestinatario', Customer."PA Code");
            if Customer."PA Code" = '0000000' then
                AddNonEmptyElement('PECDestinatario', Customer."PEC E-Mail Address");
            GetParent;
        end;
    end;

    local procedure PopulateCompanyInformation(Customer: Record Customer)
    begin
        with TempXMLBuffer do begin
            // 1.2 CedentePrestatore - Seller
            AddGroupElement('CedentePrestatore');
            AddGroupElement('DatiAnagrafici');
            AddGroupElement('IdFiscaleIVA');
            AddNonEmptyElement('IdPaese', CompanyInformation."Country/Region Code");
            AddNonEmptyLastElement('IdCodice', CompanyInformation."VAT Registration No.");
            AddNonEmptyElement('CodiceFiscale', CompanyInformation."Fiscal Code");

            AddGroupElement('Anagrafica');
            AddNonEmptyLastElement('Denominazione', CompanyInformation.Name);
            AddNonEmptyLastElement('RegimeFiscale', 'RF' + CompanyInformation."Company Type");

            // 1.2.2 Sede
            AddGroupElement('Sede');
            AddNonEmptyElement('Indirizzo', CompanyInformation.Address);
            AddNonEmptyElement('CAP', CompanyInformation."Post Code");
            AddNonEmptyElement('Comune', CompanyInformation.City);
            AddNonEmptyElement('Provincia', CompanyInformation.County);
            AddNonEmptyLastElement('Nazione', CompanyInformation."Country/Region Code");

            // 1.2.4 IscrizioneREA
            AddGroupElement('IscrizioneREA');
            AddNonEmptyElement('Ufficio', CompanyInformation."Registry Office Province");
            AddNonEmptyElement('NumeroREA', CompanyInformation."REA No.");
            AddNonEmptyElement('CapitaleSociale', FormatAmount(CompanyInformation."Paid-In Capital"));
            if CompanyInformation."Shareholder Status" = CompanyInformation."Shareholder Status"::"One Shareholder" then
                AddNonEmptyElement('SocioUnico', 'SU')
            else
                AddNonEmptyElement('SocioUnico', 'SM');

            if CompanyInformation."Liquidation Status" = CompanyInformation."Liquidation Status"::"Not in Liquidation" then
                AddNonEmptyLastElement('StatoLiquidazione', 'LN')
            else
                AddNonEmptyLastElement('StatoLiquidazione', 'LS');

            // 1.2.5 Contatti
            AddGroupElement('Contatti');
            AddNonEmptyElement('Telefono', DelChr(CompanyInformation."Phone No.", '=', '-'));
            AddNonEmptyElement('Fax', DelChr(CompanyInformation."Fax No.", '=', '-'));
            AddNonEmptyLastElement('Email', CompanyInformation."E-Mail");

            // 1.2.6. RiferimentoAmministrazione
            AddNonEmptyLastElement('RiferimentoAmministrazione', Customer."Our Account No.");
        end;
    end;

    local procedure PopulateTaxRepresentative(TempFatturaHeader: Record "Fattura Header" temporary)
    var
        TempVendor: Record Vendor temporary;
    begin
        // 1.3. RappresentanteFiscale - TAX REPRESENTATIVE

        if not TempFatturaHeader.GetTaxRepresentative(TempVendor) then
            exit;

        with TempXMLBuffer do begin
            AddGroupElement('RappresentanteFiscale');
            AddGroupElement('DatiAnagrafici');
            AddGroupElement('IdFiscaleIVA');
            AddNonEmptyElement('IdPaese', TempVendor."Country/Region Code");
            AddNonEmptyLastElement('IdCodice', TempVendor."VAT Registration No.");

            AddGroupElement('Anagrafica');
            if TempVendor."Individual Person" then begin
                AddNonEmptyElement('Nome', TempVendor."First Name");
                AddNonEmptyLastElement('Cognome', TempVendor."Last Name");
            end else
                AddNonEmptyLastElement('Denominazione', TempVendor.Name);

            GetParent;
            GetParent;
        end;
    end;

    local procedure PopulateCustomerData(Customer: Record Customer)
    begin
        // 1.4 CessionarioCommittente
        with TempXMLBuffer do begin
            AddGroupElement('CessionarioCommittente');
            AddGroupElement('DatiAnagrafici');
            AddGroupElement('IdFiscaleIVA');
            AddNonEmptyElement('IdPaese', Customer."Country/Region Code");
            if Customer."Individual Person" then
                AddNonEmptyElement('CodiceFiscale', Customer."Fiscal Code")
            else
                AddNonEmptyLastElement('IdCodice', Customer."VAT Registration No.");

            // 1.4.1.3 Anagrafica
            AddGroupElement('Anagrafica');
            if Customer."Individual Person" then begin
                AddNonEmptyElement('Nome', Customer."First Name");
                AddNonEmptyLastElement('Cognome', Customer."Last Name");
            end else
                AddNonEmptyLastElement('Denominazione', Customer.Name);
            GetParent;

            // 1.4.2. Sede
            AddGroupElement('Sede');
            AddNonEmptyElement('Indirizzo', Customer.Address);
            if Customer."Country/Region Code" <> CompanyInformation."Country/Region Code" then
                AddNonEmptyElement('CAP', '00000')
            else
                AddNonEmptyElement('CAP', Customer."Post Code");
            AddNonEmptyElement('Comune', Customer.City);
            AddNonEmptyElement('Provincia', Customer.County);
            AddNonEmptyLastElement('Nazione', Customer."Country/Region Code");
            GetParent;
            GetParent;
        end;
    end;

    local procedure PopulateDocGeneralData(TempFatturaHeader: Record "Fattura Header" temporary)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        with TempXMLBuffer do begin
            AddGroupElement('FatturaElettronicaBody');
            AddGroupElement('DatiGenerali');

            // 2.1.1   DatiGeneraliDocumento - general details
            AddGroupElement('DatiGeneraliDocumento');
            AddNonEmptyElement('TipoDocumento', TempFatturaHeader."Fattura Document Type");

            // 2.1.1.2 Divisa
            GeneralLedgerSetup.Get();
            AddNonEmptyElement('Divisa', GeneralLedgerSetup."LCY Code");

            // 2.1.1.3  Data
            AddNonEmptyElement('Data', FormatDate(TempFatturaHeader."Posting Date"));

            // 2.1.1.4   Numero
            AddNonEmptyElement('Numero', TempFatturaHeader."Document No.");

            // 2.1.1.6   DatiBollo
            if TempFatturaHeader."Fattura Stamp" then begin
                AddGroupElement('DatiBollo');
                AddNonEmptyElement('BolloVirtuale', YesTok);
                AddNonEmptyElement('ImportoBollo', FormatAmount(TempFatturaHeader."Fattura Stamp Amount"));
                GetParent;
            end;
        end;
    end;

    local procedure PopulateDocDiscountData(TempFatturaHeader: Record "Fattura Header" temporary)
    begin
        with TempXMLBuffer do begin
            // 2.1.1.8 - ScontoMaggiorazione - Discount - Extra charge
            if TempFatturaHeader."Total Inv. Discount" <> 0 then begin
                AddGroupElement('ScontoMaggiorazione');
                AddNonEmptyElement('Tipo', 'SC');
                AddNonEmptyLastElement(
                  'Importo', FormatAmountEightDecimalPlaces(TempFatturaHeader."Total Inv. Discount"));
            end;

            // 2.1.1.9   ImportoTotaleDocumento
            AddNonEmptyLastElement('ImportoTotaleDocumento', FormatAmount(TempFatturaHeader."Total Amount"));
        end;
    end;

    local procedure PopulateLineData(var TempFatturaLine: Record "Fattura Line" temporary)
    var
        Item: Record Item;
    begin
        with TempXMLBuffer do begin
            // 2.2.1 DettaglioLinee
            AddGroupElement('DettaglioLinee');
            AddNonEmptyElement('NumeroLinea', Format(TempFatturaLine."Line No."));

            if (TempFatturaLine.Type = 'Item') and
               Item.Get(TempFatturaLine."No.") and (Item.GTIN <> '')
            then begin
                AddGroupElement('CodiceArticolo');
                AddNonEmptyElement('CodiceTipo', 'GTIN');
                AddNonEmptyLastElement('CodiceValore', Item.GTIN);
            end;
            AddNonEmptyElement('Descrizione', TempFatturaLine.Description);
            AddNonEmptyElement('Quantita', FormatQuantity(TempFatturaLine.Quantity));
            AddNonEmptyElement('UnitaMisura', TempFatturaLine."Unit of Measure");
            AddNonEmptyElement('PrezzoUnitario', FormatAmount(TempFatturaLine."Unit Price"));
            if (TempFatturaLine."Discount Percent" <> 0) or (TempFatturaLine."Discount Amount" <> 0) then begin
                AddGroupElement('ScontoMaggiorazione');
                AddNonEmptyElement('Tipo', 'SC');
                AddNonEmptyElement('Percentuale', FormatAmount(TempFatturaLine."Discount Percent"));
                if TempFatturaLine."Discount Percent" = 0 then
                    AddNonEmptyElement('Importo', FormatAmountEightDecimalPlaces(TempFatturaLine."Discount Amount"));
                GetParent;
            end;

            AddNonEmptyElement('PrezzoTotale', FormatAmount(TempFatturaLine.Amount));
            AddNonEmptyElement('AliquotaIVA', FormatAmount(TempFatturaLine."VAT %"));
            AddNonEmptyElement('Natura', TempFatturaLine."VAT Transaction Nature");
            if TempFatturaLine.Type <> '' then
                PopulateAttachedToLinesExtText(TempFatturaLine);
            GetParent;
        end;
    end;

    local procedure PopulateLineVATData(var TempFatturaLine: Record "Fattura Line" temporary)
    begin
        // 2.2.2 DatiRiepilogo - summary data for every VAT rate
        with TempXMLBuffer do begin
            AddGroupElement('DatiRiepilogo');
            AddNonEmptyElement('AliquotaIVA', FormatAmount(TempFatturaLine."VAT %"));
            AddNonEmptyElement('Natura', TempFatturaLine."VAT Transaction Nature");
            AddNonEmptyElement(
              'ImponibileImporto', FormatAmount(TempFatturaLine."VAT Base"));
            AddNonEmptyElement('Imposta', FormatAmount(TempFatturaLine."VAT Amount"));
            AddNonEmptyElement('EsigibilitaIVA', TempFatturaLine.Description);
            AddNonEmptyElement('RiferimentoNormativo', TempFatturaLine."VAT Nature Description");
            GetParent;
        end;
    end;

    local procedure PopulateOrderData(var TempFatturaLine: Record "Fattura Line" temporary; TempFatturaHeader: Record "Fattura Header" temporary)
    var
        OrderNo: Code[20];
        Finished: Boolean;
    begin
        // 2.1.2  DatiOrdineAcquisto

        TempFatturaLine.Reset();
        TempFatturaLine.SetRange("Line Type", TempFatturaLine."Line Type"::Order);
        if not TempFatturaLine.FindSet then
            exit;

        with TempXMLBuffer do begin
            repeat
                AddGroupElement('DatiOrdineAcquisto');
                OrderNo := TempFatturaLine."Document No.";
                repeat
                    if TempFatturaLine."Related Line No." <> 0 then
                        AddNonEmptyElement('RiferimentoNumeroLinea', Format(TempFatturaLine."Related Line No."));
                    Finished := TempFatturaLine.Next = 0;
                until Finished or (OrderNo <> TempFatturaLine."Document No.");
                AddNonEmptyElement('IdDocumento', TempFatturaHeader."Customer Purchase Order No.");
                AddNonEmptyElement('CodiceCUP', TempFatturaHeader."Fattura Project Code");
                AddNonEmptyElement('CodiceCIG', TempFatturaHeader."Fattura Tender Code");
                GetParent;
            until Finished;
        end;
    end;

    local procedure PopulatePaymentData(var TempFatturaLine: Record "Fattura Line" temporary; TempFatturaHeader: Record "Fattura Header" temporary)
    begin
        // 2.4. DatiPagamento - Payment Data
        with TempXMLBuffer do begin
            TempFatturaLine.Reset();
            TempFatturaLine.SetRange("Line Type", TempFatturaLine."Line Type"::Payment);
            if TempFatturaLine.FindSet then begin
                AddGroupElement('DatiPagamento');
                AddNonEmptyElement('CondizioniPagamento', TempFatturaHeader."Fattura Payment Terms Code");
                repeat
                    AddGroupElement('DettaglioPagamento');
                    AddNonEmptyElement('ModalitaPagamento', TempFatturaHeader."Fattura PA Payment Method");
                    AddNonEmptyElement(
                      'DataScadenzaPagamento', FormatDate(TempFatturaLine."Due Date"));
                    AddNonEmptyElement('ImportoPagamento', FormatAmount(TempFatturaLine.Amount));
                    AddNonEmptyLastElement('IBAN', CompanyInformation.IBAN);
                until TempFatturaLine.Next = 0;
            end;
        end;
    end;

    local procedure PopulateShipmentData(var TempFatturaLine: Record "Fattura Line" temporary)
    begin
        TempFatturaLine.Reset();
        TempFatturaLine.SetRange("Line Type", TempFatturaLine."Line Type"::Shipment);
        if not TempFatturaLine.FindSet then
            exit;

        with TempXMLBuffer do begin
            repeat
                AddGroupElement('DatiDDT');
                AddNonEmptyElement('NumeroDDT', TempFatturaLine."Document No.");
                AddNonEmptyElement('DataDDT', FormatDate(TempFatturaLine."Posting Date"));
                if TempFatturaLine."Related Line No." <> 0 then
                    AddNonEmptyElement('RiferimentoNumeroLinea', Format(TempFatturaLine."Related Line No."));
                GetParent;
            until TempFatturaLine.Next = 0;
        end;
    end;

    local procedure PopulateExtendedTextData(FatturaLine: Record "Fattura Line")
    var
        ExtendedTextLength: Integer;
    begin
        ExtendedTextLength := 60;
        TempXMLBuffer.AddGroupElement('AltriDatiGestionali');
        TempXMLBuffer.AddNonEmptyElement('TipoDato', FatturaLine."Ext. Text Source No");
        TempXMLBuffer.AddNonEmptyElement('RiferimentoTesto', CopyStr(FatturaLine.Description, 1, ExtendedTextLength));
        if StrLen(FatturaLine.Description) > ExtendedTextLength then
            TempXMLBuffer.AddNonEmptyElement(
              'RiferimentoTesto', CopyStr(FatturaLine.Description, ExtendedTextLength + 1, ExtendedTextLength));
        TempXMLBuffer.GetParent;
    end;

    local procedure PopulateAttachedToLinesExtText(var TempFatturaLine: Record "Fattura Line" temporary)
    var
        TempExtFatturaLine: Record "Fattura Line" temporary;
    begin
        TempExtFatturaLine.Copy(TempFatturaLine, true);
        TempExtFatturaLine.SetRange("Line Type", TempExtFatturaLine."Line Type"::"Extended Text");
        TempExtFatturaLine.SetRange("Related Line No.", TempFatturaLine."Line No.");
        if TempExtFatturaLine.FindSet then
            repeat
                PopulateExtendedTextData(TempExtFatturaLine);
            until TempExtFatturaLine.Next = 0;
    end;

    local procedure PopulateDocumentAttachments(TempFatturaHeader: Record "Fattura Header" temporary)
    var
        DocumentAttachment: Record "Document Attachment";
        Base64Convert: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
    begin
        with DocumentAttachment do begin
            SetRange("Table ID", TempFatturaHeader.GetTableID);
            SetRange("No.", TempFatturaHeader."Document No.");
            if FindSet then
                repeat
                    if not "Document Reference ID".HasValue then
                        exit;

                    TempXMLBuffer.AddGroupElement('Allegati');
                    TempXMLBuffer.AddNonEmptyElement('NomeAttachment', "File Name");
                    TempXMLBuffer.AddNonEmptyElement('FormatoAttachment', "File Extension");
                    TempXMLBuffer.Get(TempXMLBuffer.AddElement('Attachment', ''));

                    TempBlob.CreateOutStream(OutStream);
                    "Document Reference ID".ExportStream(OutStream);
                    TempBlob.CreateInStream(InStream);
                    TempXMLBuffer.SetValue(Base64Convert.ToBase64(InStream));

                    TempXMLBuffer.GetParent;
                    TempXMLBuffer.GetParent;
                until Next = 0;
        end;
    end;

    local procedure PopulateApplicationData(TempFatturaHeader: Record "Fattura Header" temporary)
    begin
        if TempFatturaHeader."Applied Doc. No." = '' then
            exit;

        with TempXMLBuffer do begin
            AddGroupElement('DatiFattureCollegate');
            AddNonEmptyElement('IdDocumento', TempFatturaHeader."Applied Doc. No.");
            AddNonEmptyElement('Data', FormatDate(TempFatturaHeader."Applied Posting Date"));
            AddNonEmptyElement('CodiceCUP', TempFatturaHeader."Appl. Fattura Project Code");
            AddNonEmptyElement('CodiceCIG', TempFatturaHeader."Appl. Fattura Tender Code");
            GetParent;
        end;
    end;

    local procedure SubstituteInvalidCharacters(var InputValue: Text)
    var
        DotNet_StringBuilder: Codeunit DotNet_StringBuilder;
        Index: Integer;
        Length: Integer;
        InputChar: Char;
        SubstText: Text;
    begin
        if InputValue = '' then
            exit;

        DotNet_StringBuilder.InitStringBuilder('');
        Length := StrLen(InputValue);

        for Index := 1 to Length do begin
            InputChar := InputValue[Index];
            SubstText := Format(InputChar);
            if not IsValidFatturaCharacter(InputChar) then
                SubstText := GetFatturaValidSubstText(InputChar);
            DotNet_StringBuilder.Append(SubstText);
        end;

        InputValue := DotNet_StringBuilder.ToString;
    end;

    [EventSubscriber(ObjectType::Table, 1235, 'OnNormalizeElementValue', '', false, false)]
    local procedure SubstituteInvalidCharactersOnNormalizeElementValue(var ElementValue: Text)
    begin
        SubstituteInvalidCharacters(ElementValue);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsValidFatturaCharacter(InputChar: Char; var IsValid: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetFatturaValidCharacter(InputChar: Char; var ReplacementText: Text)
    begin
    end;
}

