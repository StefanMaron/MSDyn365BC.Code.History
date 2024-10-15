codeunit 27030 "SAT Utilities"
{
    // This codeunit will house various utility functions used by the CFDI Mexican Reg F functionality.


    trigger OnRun()
    begin
    end;

    [Scope('OnPrem')]
    procedure GetSATUnitofMeasure(UofM: Code[10]): Code[10]
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        if UnitOfMeasure.Get(UofM) then
            exit(UnitOfMeasure."SAT UofM Classification");
        exit(UofM);
    end;

    [Scope('OnPrem')]
    procedure GetSATCountryCode(CountryCode: Code[10]): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        if CountryRegion.Get(CountryCode) then
            exit(CountryRegion."SAT Country Code");
        exit(CountryCode);
    end;

    [Scope('OnPrem')]
    procedure GetSATPaymentMethod(PaymentMeth: Code[10]): Code[10]
    var
        PaymentMethod: Record "Payment Method";
    begin
        if PaymentMethod.Get(PaymentMeth) then
            exit(PaymentMethod."SAT Method of Payment");
        exit(PaymentMeth);
    end;

    [Scope('OnPrem')]
    procedure GetSATPaymentMethodDescription(PaymentMeth: Code[10]): Text[50]
    var
        PaymentMethod: Record "Payment Method";
        SATPaymentMethod: Record "SAT Payment Method";
    begin
        if PaymentMethod.Get(PaymentMeth) then begin
            if SATPaymentMethod.Get(PaymentMethod."SAT Method of Payment") then
                exit(SATPaymentMethod.Description);
        end;
        exit(PaymentMeth);
    end;

    [Scope('OnPrem')]
    procedure GetSATItemClassification(Type: Option " ","G/L Account",Item,Resource,"Fixed Asset","Charge (Item)"; ItemNumber: Code[20]): Code[10]
    var
        Item: Record Item;
    begin
        case Type of
            Type::Item:
                if Item.Get(ItemNumber) then
                    exit(Item."SAT Item Classification");
            Type::Resource, Type::"Fixed Asset":
                exit('01010101'); // Does not exist in the catalog
        end;
        exit('');
    end;

    [Scope('OnPrem')]
    procedure GetSATPaymentTerm(PaymentTerm: Code[10]): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        if PaymentTerms.Get(PaymentTerm) then
            exit(PaymentTerms."SAT Payment Term");
        exit(PaymentTerm);
    end;

    [Scope('OnPrem')]
    procedure GetSATPaymentTermDescription(PaymentTerm: Code[10]): Text[50]
    var
        PaymentTerms: Record "Payment Terms";
        SATPaymentTerm: Record "SAT Payment Term";
    begin
        if PaymentTerms.Get(PaymentTerm) then begin
            if SATPaymentTerm.Get(PaymentTerms."SAT Payment Term") then
                exit(SATPaymentTerm.Description);
        end;
        exit(PaymentTerm);
    end;

    [Scope('OnPrem')]
    procedure GetSATTaxSchemeDescription(TaxScheme: Code[10]): Text[100]
    var
        SATTaxScheme: Record "SAT Tax Scheme";
    begin
        if SATTaxScheme.Get(TaxScheme) then
            exit(SATTaxScheme.Description);
        exit(TaxScheme);
    end;

    [Scope('OnPrem')]
    procedure GetSATUnitOfMeasureFixedAsset(): Code[10]
    begin
        exit('H87');
    end;

    [Scope('OnPrem')]
    procedure MapCountryCodes()
    var
        CountryRegion: Record "Country/Region";
    begin
        if CountryRegion.FindSet then
            repeat
                case CountryRegion.Code of
                    'AE':
                        CountryRegion."SAT Country Code" := 'ARE';
                    'AT':
                        CountryRegion."SAT Country Code" := 'AUT';
                    'AU':
                        CountryRegion."SAT Country Code" := 'AUS';
                    'BE':
                        CountryRegion."SAT Country Code" := 'BEL';
                    'BG':
                        CountryRegion."SAT Country Code" := 'BGR';
                    'BN':
                        CountryRegion."SAT Country Code" := 'BRN';
                    'BR':
                        CountryRegion."SAT Country Code" := 'BRA';
                    'CA':
                        CountryRegion."SAT Country Code" := 'CAN';
                    'CH':
                        CountryRegion."SAT Country Code" := 'CHE';
                    'CN':
                        CountryRegion."SAT Country Code" := 'CHN';
                    'CY':
                        CountryRegion."SAT Country Code" := 'CYP';
                    'CZ':
                        CountryRegion."SAT Country Code" := 'CZE';
                    'DE':
                        CountryRegion."SAT Country Code" := 'DEU';
                    'DK':
                        CountryRegion."SAT Country Code" := 'DNK';
                    'DZ':
                        CountryRegion."SAT Country Code" := 'DZA';
                    'EE':
                        CountryRegion."SAT Country Code" := 'EST';
                    'EL':
                        CountryRegion."SAT Country Code" := 'GRC';
                    'ES':
                        CountryRegion."SAT Country Code" := 'ESP';
                    'FI':
                        CountryRegion."SAT Country Code" := 'FIN';
                    'FJ':
                        CountryRegion."SAT Country Code" := 'FJI';
                    'FR':
                        CountryRegion."SAT Country Code" := 'FRA';
                    'GB':
                        CountryRegion."SAT Country Code" := 'GBR';
                    'HR':
                        CountryRegion."SAT Country Code" := 'HRV';
                    'HU':
                        CountryRegion."SAT Country Code" := 'HUN';
                    'ID':
                        CountryRegion."SAT Country Code" := 'IDN';
                    'IE':
                        CountryRegion."SAT Country Code" := 'IRL';
                    'IN':
                        CountryRegion."SAT Country Code" := 'IND';
                    'IS':
                        CountryRegion."SAT Country Code" := 'ISL';
                    'IT':
                        CountryRegion."SAT Country Code" := 'ITA';
                    'JP':
                        CountryRegion."SAT Country Code" := 'JPN';
                    'KE':
                        CountryRegion."SAT Country Code" := 'KEN';
                    'LT':
                        CountryRegion."SAT Country Code" := 'LTU';
                    'LU':
                        CountryRegion."SAT Country Code" := 'LUX';
                    'LV':
                        CountryRegion."SAT Country Code" := 'LVA';
                    'MA':
                        CountryRegion."SAT Country Code" := 'MAR';
                    'ME':
                        CountryRegion."SAT Country Code" := 'MNE';
                    'MT':
                        CountryRegion."SAT Country Code" := 'MLT';
                    'MX':
                        CountryRegion."SAT Country Code" := 'MEX';
                    'MY':
                        CountryRegion."SAT Country Code" := 'MYS';
                    'MZ':
                        CountryRegion."SAT Country Code" := 'MOZ';
                    'NG':
                        CountryRegion."SAT Country Code" := 'NGA';
                    'NL':
                        CountryRegion."SAT Country Code" := 'NLD';
                    'NO':
                        CountryRegion."SAT Country Code" := 'NOR';
                    'NZ':
                        CountryRegion."SAT Country Code" := 'NZL';
                    'PH':
                        CountryRegion."SAT Country Code" := 'PHL';
                    'PL':
                        CountryRegion."SAT Country Code" := 'POL';
                    'PT':
                        CountryRegion."SAT Country Code" := 'PRT';
                    'RO':
                        CountryRegion."SAT Country Code" := 'ROU';
                    'RS':
                        CountryRegion."SAT Country Code" := 'SRB';
                    'RU':
                        CountryRegion."SAT Country Code" := 'RUS';
                    'SA':
                        CountryRegion."SAT Country Code" := 'SAU';
                    'SB':
                        CountryRegion."SAT Country Code" := 'SLB';
                    'SE':
                        CountryRegion."SAT Country Code" := 'SWE';
                    'SG':
                        CountryRegion."SAT Country Code" := 'SGP';
                    'SI':
                        CountryRegion."SAT Country Code" := 'SVN';
                    'SK':
                        CountryRegion."SAT Country Code" := 'SVK';
                    'SZ':
                        CountryRegion."SAT Country Code" := 'SWZ';
                    'TH':
                        CountryRegion."SAT Country Code" := 'THA';
                    'TN':
                        CountryRegion."SAT Country Code" := 'TUN';
                    'TR':
                        CountryRegion."SAT Country Code" := 'TUR';
                    'TZ':
                        CountryRegion."SAT Country Code" := 'TZA';
                    'UG':
                        CountryRegion."SAT Country Code" := 'UGA';
                    'US':
                        CountryRegion."SAT Country Code" := 'USA';
                    'VU':
                        CountryRegion."SAT Country Code" := 'VUT';
                    'WS':
                        CountryRegion."SAT Country Code" := 'WSM';
                    'ZA':
                        CountryRegion."SAT Country Code" := 'ZAF';
                    else
                        CountryRegion."SAT Country Code" := 'ZZZ';
                end;
                CountryRegion.Modify();
            until CountryRegion.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure MapUnitsofMeasure()
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        if UnitOfMeasure.FindSet then
            repeat
                case UnitOfMeasure.Code of
                    'DAY':
                        UnitOfMeasure."SAT UofM Classification" := 'DAY';
                    'GR':
                        UnitOfMeasure."SAT UofM Classification" := 'GRM';
                    'HOUR':
                        UnitOfMeasure."SAT UofM Classification" := 'HUR';
                    'KG':
                        UnitOfMeasure."SAT UofM Classification" := 'KGM';
                    'KM':
                        UnitOfMeasure."SAT UofM Classification" := 'KMT';
                    'L':
                        UnitOfMeasure."SAT UofM Classification" := 'LTR';
                    'PCS':
                        UnitOfMeasure."SAT UofM Classification" := 'EA';
                end;
                UnitOfMeasure.Modify();
            until UnitOfMeasure.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure PopulateSATInformation()
    var
        SATPaymentMethod: Record "SAT Payment Method";
        SATClassification: Record "SAT Classification";
        SATRelationshipType: Record "SAT Relationship Type";
        SATUseCode: Record "SAT Use Code";
        SATUnitOfMeasure: Record "SAT Unit of Measure";
        SATCountryCode: Record "SAT Country Code";
        SATTaxScheme: Record "SAT Tax Scheme";
        SATPaymentTerm: Record "SAT Payment Term";
        MediaResources: Record "Media Resources";
        SATFederalMotorTransport: Record "SAT Federal Motor Transport";
        SATTrailerType: Record "SAT Trailer Type";
        SATPermissionType: Record "SAT Permission Type";
        SATHazardousMaterial: Record "SAT Hazardous Material";
        SATPackagingType: Record "SAT Packaging Type";
        SATState: Record "SAT State";
        SATMunicipality: Record "SAT Municipality";
        SATLocality: Record "SAT Locality";
        SATSuburb: Record "SAT Suburb";
        SATClassificationPort: XMLport "SAT Classification";
        SATRelationshipTypePort: XMLport "SAT Relationship Type";
        SATUseCodePort: XMLport "SAT Use Code";
        SATUnitOfMeasurePort: XMLport "SAT Unit of Measure";
        SATCountryCodePort: XMLport "SAT Country Code";
        SATPaymentMethodPort: XMLport "SAT Payment Method";
        SATTaxSchemePort: XMLport "SAT Tax Scheme";
        SATPaymentTermPort: XMLport "SAT Payment Term";
        SATFederalMotorTransportPort: XMLport "SAT Federal Motor Transport";
        SATTrailerTypePort: XMLport "SAT Trailer Type";
        SATPermissionTypePort: XMLport "SAT Permission Type";
        SATHazardousMaterialPort: XMLport "SAT Hazardous Material";
        SATPackagingTypePort: XMLport "SAT Packaging Type";
        SATStatePort: XMLport "SAT State";
        SATMunicipalityPort: XMLport "SAT Municipality";
        SATLocalityPort: XMLport "SAT Locality";
        SATSuburbPort: XMLport "SAT Suburb";
        IStr: InStream;
    begin
        if not SATClassification.FindFirst then begin
            MediaResources.Get('SATClassifications.xml');
            MediaResources.CalcFields(Blob);
            MediaResources.Blob.CreateInStream(IStr, TEXTENCODING::UTF16);
            SATClassificationPort.SetSource(IStr);
            SATClassificationPort.Import;
        end;

        if not SATCountryCode.FindFirst then begin
            MediaResources.Get('SATCountry_Codes.xml');
            MediaResources.CalcFields(Blob);
            MediaResources.Blob.CreateInStream(IStr, TEXTENCODING::UTF16);
            SATCountryCodePort.SetSource(IStr);
            SATCountryCodePort.Import;
        end;

        if not SATPaymentTerm.FindFirst then begin
            MediaResources.Get('SATPayment_Terms.xml');
            MediaResources.CalcFields(Blob);
            MediaResources.Blob.CreateInStream(IStr, TEXTENCODING::UTF16);
            SATPaymentTermPort.SetSource(IStr);
            SATPaymentTermPort.Import;
        end;

        if not SATRelationshipType.FindFirst then begin
            MediaResources.Get('SATRelationship_Types.xml');
            MediaResources.CalcFields(Blob);
            MediaResources.Blob.CreateInStream(IStr, TEXTENCODING::UTF16);
            SATRelationshipTypePort.SetSource(IStr);
            SATRelationshipTypePort.Import;
        end;

        if not SATTaxScheme.FindFirst then begin
            MediaResources.Get('SATTax_Schemes.xml');
            MediaResources.CalcFields(Blob);
            MediaResources.Blob.CreateInStream(IStr, TEXTENCODING::UTF16);
            SATTaxSchemePort.SetSource(IStr);
            SATTaxSchemePort.Import;
        end;

        if not SATUnitOfMeasure.FindFirst then begin
            MediaResources.Get('SATU_of_M.xml');
            MediaResources.CalcFields(Blob);
            MediaResources.Blob.CreateInStream(IStr, TEXTENCODING::UTF16);
            SATUnitOfMeasurePort.SetSource(IStr);
            SATUnitOfMeasurePort.Import;
        end;

        if not SATUseCode.FindFirst then begin
            MediaResources.Get('SATUse_Codes.xml');
            MediaResources.CalcFields(Blob);
            MediaResources.Blob.CreateInStream(IStr, TEXTENCODING::UTF16);
            SATUseCodePort.SetSource(IStr);
            SATUseCodePort.Import;
        end;

        if not SATPaymentMethod.FindFirst then begin
            MediaResources.Get('SATPayment_Methods.xml');
            MediaResources.CalcFields(Blob);
            MediaResources.Blob.CreateInStream(IStr, TEXTENCODING::UTF16);
            SATPaymentMethodPort.SetSource(IStr);
            SATPaymentMethodPort.Import;
        end;

        if SATFederalMotorTransport.IsEmpty() then begin
            MediaResources.Get('SATFederalMotorTransport.xml');
            MediaResources.CalcFields(Blob);
            MediaResources.Blob.CreateInStream(IStr, TEXTENCODING::UTF16);
            SATFederalMotorTransportPort.SetSource(IStr);
            SATFederalMotorTransportPort.Import();
        end;

        if SATTrailerType.IsEmpty() then begin
            MediaResources.Get('SATTrailerTypes.xml');
            MediaResources.CalcFields(Blob);
            MediaResources.Blob.CreateInStream(IStr, TEXTENCODING::UTF16);
            SATTrailerTypePort.SetSource(IStr);
            SATTrailerTypePort.Import();
        end;

        if SATPermissionType.IsEmpty() then begin
            MediaResources.Get('SATPermissionTypes.xml');
            MediaResources.CalcFields(Blob);
            MediaResources.Blob.CreateInStream(IStr, TEXTENCODING::UTF16);
            SATPermissionTypePort.SetSource(IStr);
            SATPermissionTypePort.Import();
        end;

        if SATHazardousMaterial.IsEmpty() then begin
            MediaResources.Get('SATHazardousMaterials.xml');
            MediaResources.CalcFields(Blob);
            MediaResources.Blob.CreateInStream(IStr, TEXTENCODING::UTF16);
            SATHazardousMaterialPort.SetSource(IStr);
            SATHazardousMaterialPort.Import();
        end;

        if SATPackagingType.IsEmpty() then begin
            MediaResources.Get('SATPackagingTypes.xml');
            MediaResources.CalcFields(Blob);
            MediaResources.Blob.CreateInStream(IStr, TEXTENCODING::UTF16);
            SATPackagingTypePort.SetSource(IStr);
            SATPackagingTypePort.Import();
        end;

        if SATState.IsEmpty() then begin
            MediaResources.Get('SATStates.xml');
            MediaResources.CalcFields(Blob);
            MediaResources.Blob.CreateInStream(IStr, TEXTENCODING::UTF16);
            SATStatePort.SetSource(IStr);
            SATStatePort.Import();
        end;

        if SATMunicipality.IsEmpty() then begin
            MediaResources.Get('SATMunicipalities.xml');
            MediaResources.CalcFields(Blob);
            MediaResources.Blob.CreateInStream(IStr, TEXTENCODING::UTF16);
            SATMunicipalityPort.SetSource(IStr);
            SATMunicipalityPort.Import();
        end;

        if SATLocality.IsEmpty() then begin
            MediaResources.Get('SATLocalities.xml');
            MediaResources.CalcFields(Blob);
            MediaResources.Blob.CreateInStream(IStr, TEXTENCODING::UTF16);
            SATLocalityPort.SetSource(IStr);
            SATLocalityPort.Import();
        end;

        if SATSuburb.IsEmpty() then begin
            MediaResources.Get('SATSuburb1.xml');
            MediaResources.CalcFields(Blob);
            MediaResources.Blob.CreateInStream(IStr, TEXTENCODING::UTF16);
            SATSuburbPort.SetSource(IStr);
            SATSuburbPort.Import();
            MediaResources.Get('SATSuburb2.xml');
            MediaResources.CalcFields(Blob);
            MediaResources.Blob.CreateInStream(IStr, TEXTENCODING::UTF16);
            SATSuburbPort.SetSource(IStr);
            SATSuburbPort.Import();
            MediaResources.Get('SATSuburb3.xml');
            MediaResources.CalcFields(Blob);
            MediaResources.Blob.CreateInStream(IStr, TEXTENCODING::UTF16);
            SATSuburbPort.SetSource(IStr);
            SATSuburbPort.Import();
            MediaResources.Get('SATSuburb4.xml');
            MediaResources.CalcFields(Blob);
            MediaResources.Blob.CreateInStream(IStr, TEXTENCODING::UTF16);
            SATSuburbPort.SetSource(IStr);
            SATSuburbPort.Import();
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateSATXMLFiles()
    var
        SATPaymentMethodCode: Record "SAT Payment Method Code";
        SATClassification: Record "SAT Classification";
        SATRelationshipType: Record "SAT Relationship Type";
        SATUseCode: Record "SAT Use Code";
        SATUnitOfMeasure: Record "SAT Unit of Measure";
        SATCountryCode: Record "SAT Country Code";
        SATTaxScheme: Record "SAT Tax Scheme";
        SATPaymentTerm: Record "SAT Payment Term";
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        OutStr: OutStream;
    begin
        TempBlob.CreateOutStream(OutStr);
        XMLPORT.Export(XMLPORT::"SAT Classification", OutStr, SATClassification);
        FileManagement.BLOBExport(TempBlob, 'SATClassifications.xml', true);

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStr);
        XMLPORT.Export(XMLPORT::"SAT Country Code", OutStr, SATCountryCode);
        FileManagement.BLOBExport(TempBlob, 'SATCountry_Codes.xml', true);

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStr);
        XMLPORT.Export(XMLPORT::"SAT Payment Term", OutStr, SATPaymentTerm);
        FileManagement.BLOBExport(TempBlob, 'SATPayment_Forms.xml', true);

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStr);
        XMLPORT.Export(XMLPORT::"SAT Payment Method", OutStr, SATPaymentMethodCode);
        FileManagement.BLOBExport(TempBlob, 'SATPayment_Methods.xml', true);

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStr);
        XMLPORT.Export(XMLPORT::"SAT Relationship Type", OutStr, SATRelationshipType);
        FileManagement.BLOBExport(TempBlob, 'SATRelationship_Types.xml', true);

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStr);
        XMLPORT.Export(XMLPORT::"SAT Tax Scheme", OutStr, SATTaxScheme);
        FileManagement.BLOBExport(TempBlob, 'SATTax_Schemes.xml', true);

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStr);
        XMLPORT.Export(XMLPORT::"SAT Unit of Measure", OutStr, SATUnitOfMeasure);
        FileManagement.BLOBExport(TempBlob, 'SATU_of_M.xml', true);

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStr);
        XMLPORT.Export(XMLPORT::"SAT Use Code", OutStr, SATUseCode);
        FileManagement.BLOBExport(TempBlob, 'SATUse_Codes.xml', true);
    end;
}

