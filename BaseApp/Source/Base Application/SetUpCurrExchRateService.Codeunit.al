codeunit 1242 "Set Up Curr Exch Rate Service"
{

    trigger OnRun()
    var
        Currency: Record Currency;
        CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup";
        GLSetup: Record "General Ledger Setup";
    begin
        if Currency.IsEmpty then
            exit;
        if not CurrExchRateUpdateSetup.IsEmpty then
            exit;
        if not CurrExchRateUpdateSetup.WritePermission then
            exit;
        GLSetup.Get;
        if GLSetup."LCY Code" = 'EUR' then
            SetupECBDataExchange(CurrExchRateUpdateSetup, GetECB_URI);
        // NAVCZ
        if GLSetup."LCY Code" = 'CZK' then
            SetupCNBDataExchange(CurrExchRateUpdateSetup, GetCNB_URI);
        // NAVCZ
        Commit;
    end;

    var
        DummyDataExchColumnDef: Record "Data Exch. Column Def";
        DummyCurrExchRate: Record "Currency Exchange Rate";
        ECB_EXCH_RATESTxt: Label 'ECB-EXCHANGE-RATES', Locked = true;
        CNB_EXCH_RATESTxt: Label 'CNB-EXCHANGE-RATES', Comment = 'Czech National Bank Currency Exchange Rate Code', Locked = true;
        ECB_EXCH_RATESDescTxt: Label 'European Central Bank Currency Exchange Rates Setup';
        CNB_EXCH_RATESDescTxt: Label 'Czech National Bank Currency Exchange Rates';
        ECB_URLTxt: Label 'http://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml', Locked = true;
        CNB_URLTxt: Label 'http://www.cnb.cz/cs/financni_trhy/devizovy_trh/kurzy_devizoveho_trhu/denni_kurz.xml', Locked = true;
        ECBServiceProviderTxt: Label 'European Central Bank';
        CNBServiceProviderTxt: Label 'Czech National Bank';

    [Scope('OnPrem')]
    procedure SetupECBDataExchange(var CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup"; PathToECBService: Text)
    var
        DataExchLineDef: Record "Data Exch. Line Def";
        SuggestColDefinitionXML: Codeunit "Suggest Col. Definition - XML";
    begin
        DataExchLineDef.SetRange("Data Exch. Def Code", ECB_EXCH_RATESTxt);
        if DataExchLineDef.FindFirst then;

        CreateCurrencyExchangeSetup(
          CurrExchRateUpdateSetup, ECB_EXCH_RATESTxt, ECB_EXCH_RATESDescTxt,
          DataExchLineDef."Data Exch. Def Code", ECBServiceProviderTxt, '');

        if StrPos(PathToECBService, 'http') = 1 then
            CurrExchRateUpdateSetup.SetWebServiceURL(PathToECBService);

        if DataExchLineDef."Data Exch. Def Code" = '' then begin
            CreateExchLineDef(DataExchLineDef, CurrExchRateUpdateSetup."Data Exch. Def Code", GetECBRepeaterPath);
            SuggestColDefinitionXML.GenerateDataExchColDef(PathToECBService, DataExchLineDef);

            MapECBDataExch(DataExchLineDef);
        end;
        Commit;
    end;

    [Scope('OnPrem')]
    procedure SetupCNBDataExchange(var CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup"; PathToCNBService: Text)
    var
        DataExchLineDef: Record "Data Exch. Line Def";
        SuggestColDefinitionXML: Codeunit "Suggest Col. Definition - XML";
        XMLBufferWriter: Codeunit "XML Buffer Writer";
    begin
        // NAVCZ
        DataExchLineDef.SetRange("Data Exch. Def Code", CNB_EXCH_RATESTxt);
        if DataExchLineDef.FindFirst then;

        CreateCurrencyExchangeSetup(
          CurrExchRateUpdateSetup, CNB_EXCH_RATESTxt, CNB_EXCH_RATESDescTxt,
          DataExchLineDef."Data Exch. Def Code", CNBServiceProviderTxt, '');

        if StrPos(PathToCNBService, 'http') = 1 then
            CurrExchRateUpdateSetup.SetWebServiceURL(PathToCNBService);

        if DataExchLineDef."Data Exch. Def Code" = '' then begin
            CreateExchLineDef(DataExchLineDef, CurrExchRateUpdateSetup."Data Exch. Def Code", GetCNBRepeaterPath);
            if XMLBufferWriter.IsValidSourcePath(PathToCNBService) then begin
                SuggestColDefinitionXML.GenerateDataExchColDef(PathToCNBService, DataExchLineDef);
                MapCNBDataExch(DataExchLineDef);
            end;
        end;
        Commit;
    end;

    local procedure CreateCurrencyExchangeSetup(var CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup"; NewCode: Code[20]; NewDesc: Text[250]; NewDataExchCode: Code[20]; NewServiceProvider: Text[30]; NewTermOfUse: Text[250])
    begin
        CurrExchRateUpdateSetup.Init;
        CurrExchRateUpdateSetup.Validate("Data Exch. Def Code", NewDataExchCode);
        CurrExchRateUpdateSetup.Validate(Code, NewCode);
        CurrExchRateUpdateSetup.Validate(Description, NewDesc);
        CurrExchRateUpdateSetup.Validate("Service Provider", NewServiceProvider);
        CurrExchRateUpdateSetup.Validate("Terms of Service", NewTermOfUse);
        CurrExchRateUpdateSetup.Insert(true);
    end;

    procedure GetECB_URI(): Text
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get;
        GLSetup.TestField("LCY Code", 'EUR');
        exit(ECB_URLTxt);
    end;

    [Scope('OnPrem')]
    procedure GetCNB_URI(): Text
    var
        GLSetup: Record "General Ledger Setup";
    begin
        // NAVCZ
        GLSetup.Get;
        GLSetup.TestField("LCY Code", 'CZK');
        exit(CNB_URLTxt);
    end;

    local procedure CreateExchLineDef(var DataExchLineDef: Record "Data Exch. Line Def"; DataExchDefCode: Code[20]; RepeaterPath: Text[250])
    begin
        DataExchLineDef.SetRange("Data Exch. Def Code", DataExchDefCode);
        DataExchLineDef.FindFirst;
        DataExchLineDef.Validate("Data Line Tag", RepeaterPath);
        DataExchLineDef.Modify(true);
    end;

    local procedure CreateExchMappingLine(DataExchMapping: Record "Data Exch. Mapping"; FromColumnName: Text[250]; ToFieldNo: Integer; DataType: Option; NewMultiplier: Decimal; NewDataFormat: Text[10]; NewTransformationRule: Code[20]; NewDefaultValue: Text[250])
    var
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        with DataExchColumnDef do begin
            SetRange("Data Exch. Def Code", DataExchMapping."Data Exch. Def Code");
            SetRange("Data Exch. Line Def Code", DataExchMapping."Data Exch. Line Def Code");
            if NewDefaultValue <> '' then begin
                if FindLast then begin
                    Init;
                    "Column No." += 10000;
                    Insert;
                end
            end else begin
                SetRange(Name, FromColumnName);
                FindFirst;
            end;
            Validate("Data Type", DataType);
            Validate("Data Format", NewDataFormat);
            Modify(true);
        end;

        with DataExchFieldMapping do begin
            Init;
            Validate("Data Exch. Def Code", DataExchMapping."Data Exch. Def Code");
            Validate("Data Exch. Line Def Code", DataExchMapping."Data Exch. Line Def Code");
            Validate("Table ID", DataExchMapping."Table ID");
            Validate("Column No.", DataExchColumnDef."Column No.");
            Validate("Field ID", ToFieldNo);
            Validate(Multiplier, NewMultiplier);
            Validate("Transformation Rule", NewTransformationRule);
            Validate("Default Value", NewDefaultValue);
            Insert(true);
        end;
    end;

    local procedure MapECBDataExch(var DataExchLineDef: Record "Data Exch. Line Def")
    var
        DataExchMapping: Record "Data Exch. Mapping";
    begin
        DataExchMapping.Get(DataExchLineDef."Data Exch. Def Code", DataExchLineDef.Code, GetMappingTable);

        CreateExchMappingLine(
          DataExchMapping, GetECBCurrencyCodeXMLElement, GetCurrencyCodeFieldNo,
          DummyDataExchColumnDef."Data Type"::Text, 1, '', '', '');
        CreateExchMappingLine(
          DataExchMapping, GetECBStartingDateXMLElement, GetStartingDateFieldNo,
          DummyDataExchColumnDef."Data Type"::Date, 1, '', '', '');

        CreateExchMappingLine(
          DataExchMapping, GetECBExchRateXMLElement, GetExchRateAmtFieldNo,
          DummyDataExchColumnDef."Data Type"::Decimal, 1, '', '', '');
        CreateExchMappingLine(
          DataExchMapping, '', GetRelationalExchRateFieldNo,
          DummyDataExchColumnDef."Data Type"::Decimal, 1, '', '', '1');
    end;

    local procedure MapCNBDataExch(var DataExchLineDef: Record "Data Exch. Line Def")
    var
        DataExchMapping: Record "Data Exch. Mapping";
        TransformationRule: Record "Transformation Rule";
    begin
        // NAVCZ
        DataExchMapping.Get(DataExchLineDef."Data Exch. Def Code", DataExchLineDef.Code, GetMappingTable);

        CreateExchMappingLine(
          DataExchMapping, GetCNBCurrencyCodeXMLElement, GetCurrencyCodeFieldNo,
          DummyDataExchColumnDef."Data Type"::Text, 1, '', '', '');
        CreateExchMappingLine(
          DataExchMapping, GetCNBStartingDateXMLElement, GetStartingDateFieldNo,
          DummyDataExchColumnDef."Data Type"::Date, 1, '', TransformationRule.GetCZDateFormatCode, '');

        CreateExchMappingLine(
          DataExchMapping, GetCNBExchRateXMLElement, GetExchRateAmtFieldNo,
          DummyDataExchColumnDef."Data Type"::Decimal, 1, '', '', '');
        CreateExchMappingLine(
          DataExchMapping, GetCNBRelationalExchRateXMLElement, GetRelationalExchRateFieldNo,
          DummyDataExchColumnDef."Data Type"::Decimal, 1, '', TransformationRule.GetCzechDecimalFormatCode, '');
    end;

    local procedure GetECBRepeaterPath(): Text[250]
    begin
        exit('/gesmes:Envelope/Cube/Cube/Cube');
    end;

    local procedure GetCNBRepeaterPath(): Text[250]
    begin
        exit('/kurzy/tabulka/radek'); // NAVCZ
    end;

    local procedure GetMappingTable(): Integer
    begin
        exit(DATABASE::"Currency Exchange Rate")
    end;

    local procedure GetECBCurrencyCodeXMLElement(): Text[250]
    begin
        exit('currency');
    end;

    local procedure GetECBExchRateXMLElement(): Text[250]
    begin
        exit('rate');
    end;

    local procedure GetECBStartingDateXMLElement(): Text[250]
    begin
        exit('time');
    end;

    local procedure GetCNBCurrencyCodeXMLElement(): Text[250]
    begin
        exit('kod'); // NAVCZ
    end;

    local procedure GetCNBExchRateXMLElement(): Text[250]
    begin
        exit('mnozstvi'); // NAVCZ
    end;

    local procedure GetCNBStartingDateXMLElement(): Text[250]
    begin
        exit('datum'); // NAVCZ
    end;

    local procedure GetCNBRelationalExchRateXMLElement(): Text[250]
    begin
        exit('kurz'); // NAVCZ
    end;

    local procedure GetCurrencyCodeFieldNo(): Integer
    begin
        exit(DummyCurrExchRate.FieldNo("Currency Code"));
    end;

    local procedure GetRelationalExchRateFieldNo(): Integer
    begin
        exit(DummyCurrExchRate.FieldNo("Relational Exch. Rate Amount"));
    end;

    local procedure GetExchRateAmtFieldNo(): Integer
    begin
        exit(DummyCurrExchRate.FieldNo("Exchange Rate Amount"));
    end;

    local procedure GetStartingDateFieldNo(): Integer
    begin
        exit(DummyCurrExchRate.FieldNo("Starting Date"));
    end;
}

