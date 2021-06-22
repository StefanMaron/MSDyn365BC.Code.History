codeunit 1280 "Map Currency Exchange Rate"
{
    TableNo = "Data Exch.";

    trigger OnRun()
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        MapCurrencyExchangeRates(Rec, CurrencyExchangeRate);
    end;

    var
        FieldNotMappedErr: Label 'Mandatory field %1 is not mapped. Map the field by choosing Field Mapping in the Currency Exchange Rate Sync. Setup window.', Comment = '%1 - Field Caption';

    [Scope('OnPrem')]
    procedure MapCurrencyExchangeRates(DataExch: Record "Data Exch."; var CurrencyExchangeRate: Record "Currency Exchange Rate")
    var
        DataExchField: Record "Data Exch. Field";
        CurrentLineNo: Integer;
    begin
        CheckMandatoryFieldsMapped(DataExch);
        DataExchField.SetAutoCalcFields("Data Exch. Def Code");

        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        if DataExchField.IsEmpty then
            exit;

        Commit();

        CurrentLineNo := -1;
        if DataExchField.FindSet then
            repeat
                if CurrentLineNo <> DataExchField."Line No." then begin
                    CurrentLineNo := DataExchField."Line No.";
                    if UpdateCurrencyExchangeRate(CurrencyExchangeRate, DataExchField) then;
                end;
            until DataExchField.Next = 0;
    end;

    local procedure UpdateCurrencyExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate"; DefinitionDataExchField: Record "Data Exch. Field"): Boolean
    var
        RecordRef: RecordRef;
    begin
        Clear(CurrencyExchangeRate);

        RecordRef.GetTable(CurrencyExchangeRate);
        if not SetFields(RecordRef, DefinitionDataExchField) then
            exit(false);
        RecordRef.SetTable(CurrencyExchangeRate);

        Commit();
        exit(true);
    end;

    local procedure SetFields(var RecordRef: RecordRef; DefinitionDataExchField: Record "Data Exch. Field"): Boolean
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        if not AssignValue(RecordRef, CurrencyExchangeRate.FieldNo("Starting Date"), DefinitionDataExchField, Today) then
            exit(false);
        if not AssignValue(RecordRef, CurrencyExchangeRate.FieldNo("Currency Code"), DefinitionDataExchField, '') then
            exit(false);
        if not AssignValue(RecordRef, CurrencyExchangeRate.FieldNo("Relational Currency Code"), DefinitionDataExchField, '') then
            exit(false);
        if not AssignValue(RecordRef, CurrencyExchangeRate.FieldNo("Exchange Rate Amount"), DefinitionDataExchField, 1) then
            exit(false);
        if not AssignValue(RecordRef, CurrencyExchangeRate.FieldNo("Relational Exch. Rate Amount"), DefinitionDataExchField, 0) then
            exit(false);

        RecordRef.SetTable(CurrencyExchangeRate);
        if not AssignValue(
             RecordRef, CurrencyExchangeRate.FieldNo("Adjustment Exch. Rate Amount"), DefinitionDataExchField,
             CurrencyExchangeRate."Exchange Rate Amount")
        then
            exit(false);
        if not AssignValue(
             RecordRef, CurrencyExchangeRate.FieldNo("Relational Adjmt Exch Rate Amt"), DefinitionDataExchField,
             CurrencyExchangeRate."Relational Exch. Rate Amount")
        then
            exit(false);
        if not AssignValue(
             RecordRef, CurrencyExchangeRate.FieldNo("Fix Exchange Rate Amount"), DefinitionDataExchField,
             CurrencyExchangeRate."Fix Exchange Rate Amount"::Currency)
        then
            exit(false);

        if not RecordRef.Insert(true) then
            exit(RecordRef.Modify(true));
        exit(true);
    end;

    [TryFunction]
    local procedure AssignValue(var RecordRef: RecordRef; FieldNo: Integer; DefinitionDataExchField: Record "Data Exch. Field"; DefaultValue: Variant)
    var
        DataExchField: Record "Data Exch. Field";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        TempFieldIdsToNegate: Record "Integer" temporary;
        ProcessDataExch: Codeunit "Process Data Exch.";
        FieldRef: FieldRef;
    begin
        if GetFieldValue(DefinitionDataExchField, FieldNo, DataExchField) and
           DataExchFieldMapping.Get(
             DataExchField."Data Exch. Def Code",
             DataExchField."Data Exch. Line Def Code",
             RecordRef.Number,
             DataExchField."Column No.",
             FieldNo)
        then begin
            ProcessDataExch.SetField(RecordRef, DataExchFieldMapping, DataExchField, TempFieldIdsToNegate);
            ProcessDataExch.NegateAmounts(RecordRef, TempFieldIdsToNegate);
        end else begin
            FieldRef := RecordRef.Field(FieldNo);
            FieldRef.Validate(DefaultValue);
        end;
    end;

    local procedure GetFieldValue(DefinitionDataExchField: Record "Data Exch. Field"; FieldNo: Integer; var DataExchField: Record "Data Exch. Field"): Boolean
    var
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        ColumnNo: Integer;
    begin
        if not GetColumnNo(FieldNo, DefinitionDataExchField, ColumnNo) then
            exit;

        DataExchField.SetRange("Data Exch. No.", DefinitionDataExchField."Data Exch. No.");
        DataExchField.SetRange("Data Exch. Line Def Code", DefinitionDataExchField."Data Exch. Line Def Code");
        DataExchField.SetRange("Line No.", DefinitionDataExchField."Line No.");
        DataExchField.SetRange("Column No.", ColumnNo);
        DataExchField.SetAutoCalcFields("Data Exch. Def Code");

        if DataExchField.FindFirst then
            exit(true);

        DataExchFieldMapping.SetRange("Data Exch. Def Code", DefinitionDataExchField."Data Exch. Def Code");
        DataExchFieldMapping.SetRange("Data Exch. Line Def Code", DefinitionDataExchField."Data Exch. Line Def Code");
        DataExchFieldMapping.SetRange("Column No.", ColumnNo);
        DataExchFieldMapping.SetRange("Use Default Value", true);
        DataExchFieldMapping.SetFilter("Default Value", '<>%1', '');

        if DataExchFieldMapping.FindFirst then begin
            DataExchField.Copy(DefinitionDataExchField);
            DataExchField."Column No." := ColumnNo;
            DataExchField.Value := DataExchFieldMapping."Default Value";
            exit(true);
        end;

        exit(false);
    end;

    local procedure GetColumnNo(FieldNo: Integer; DataExchField: Record "Data Exch. Field"; var ColumnNo: Integer): Boolean
    var
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        DataExchField.CalcFields("Data Exch. Def Code");
        DataExchFieldMapping.SetRange("Data Exch. Line Def Code", DataExchField."Data Exch. Line Def Code");
        DataExchFieldMapping.SetRange("Data Exch. Def Code", DataExchField."Data Exch. Def Code");
        DataExchFieldMapping.SetRange("Table ID", DATABASE::"Currency Exchange Rate");
        DataExchFieldMapping.SetRange("Field ID", FieldNo);

        if not DataExchFieldMapping.FindFirst then
            exit(false);

        ColumnNo := DataExchFieldMapping."Column No.";
        exit(true);
    end;

    local procedure CheckMandatoryFieldsMapped(DataExch: Record "Data Exch.")
    var
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        TempField: Record "Field" temporary;
    begin
        GetMandatoryFields(TempField);
        TempField.FindSet;

        repeat
            DataExchFieldMapping.SetRange("Data Exch. Def Code", DataExch."Data Exch. Def Code");
            DataExchFieldMapping.SetRange("Field ID", TempField."No.");
            if DataExchFieldMapping.IsEmpty then
                Error(FieldNotMappedErr, TempField.FieldName);
        until TempField.Next = 0;
    end;

    procedure GetSuggestedFields(var TempField: Record "Field" temporary)
    begin
        GetMandatoryFields(TempField);
        GetCommonlyUsedFields(TempField);
    end;

    procedure GetMandatoryFields(var TempField: Record "Field" temporary)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        InsertMandatoryField(TempField, CurrencyExchangeRate.FieldNo("Currency Code"), DATABASE::"Currency Exchange Rate");
        InsertMandatoryField(TempField, CurrencyExchangeRate.FieldNo("Relational Exch. Rate Amount"), DATABASE::"Currency Exchange Rate");
    end;

    local procedure GetCommonlyUsedFields(var TempField: Record "Field" temporary)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        InsertMandatoryField(TempField, CurrencyExchangeRate.FieldNo("Starting Date"), DATABASE::"Currency Exchange Rate");
        InsertMandatoryField(TempField, CurrencyExchangeRate.FieldNo("Exchange Rate Amount"), DATABASE::"Currency Exchange Rate");
    end;

    local procedure InsertMandatoryField(var TempField: Record "Field" temporary; FieldID: Integer; TableID: Integer)
    var
        "Field": Record "Field";
    begin
        Field.Get(TableID, FieldID);
        TempField.Copy(Field);
        TempField.Insert();
    end;

    [EventSubscriber(ObjectType::Table, 1400, 'OnRegisterServiceConnection', '', false, false)]
    [Scope('OnPrem')]
    procedure HandleCurrencyExchangeRateRegisterServiceConnection(var ServiceConnection: Record "Service Connection")
    var
        CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup";
        RecRef: RecordRef;
        InStream: InStream;
        ServiceURL: Text;
    begin
        CurrExchRateUpdateSetup.SetupService;

        if CurrExchRateUpdateSetup.FindSet then
            repeat
                RecRef.GetTable(CurrExchRateUpdateSetup);
                ServiceConnection.Status := ServiceConnection.Status::Disabled;
                if CurrExchRateUpdateSetup.Enabled then
                    ServiceConnection.Status := ServiceConnection.Status::Enabled;
                CurrExchRateUpdateSetup.CalcFields("Web Service URL");
                if CurrExchRateUpdateSetup."Web Service URL".HasValue then begin
                    CurrExchRateUpdateSetup."Web Service URL".CreateInStream(InStream);
                    InStream.Read(ServiceURL);
                end;

                with CurrExchRateUpdateSetup do
                    ServiceConnection.InsertServiceConnection(
                      ServiceConnection, RecRef.RecordId, Description, ServiceURL, PAGE::"Curr. Exch. Rate Service Card");
            until CurrExchRateUpdateSetup.Next = 0;
    end;
}

