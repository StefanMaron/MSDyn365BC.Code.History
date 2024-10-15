namespace System.Integration.PowerBI;

codeunit 6320 "Power BI Filter Helper"
{
    Access = Internal;

    var
        PowerBiServiceMgt: Codeunit "Power BI Service Mgt.";
        BasicFilterSchemaTok: Label 'http://powerbi.com/product/schema#basic', Locked = true;
        // Telemetry labels
        UnsupportedFilterTypeTelemetryMsg: Label 'Cannot filter Power BI report: the filter type is not supported.', Locked = true;
        SelectionTooLargeTelemetryMsg: Label 'Power BI filter skipped. %1 records selected, but up to %2 are supported.', Locked = true;
        NoFilterDefinedTelemetryMsg: Label 'There is no filter defined in the Power BI report.', Locked = true;

#if not CLEAN24
    [Obsolete('Use the other overload of MergeValuesIntoFirstFilter instead, which uses JsonArray data types.', '24.0')]
    procedure MergeValuesIntoFirstFilter(ReportFiltersInfo: Text; FilterValuesJsonArray: JsonArray) ReportFiltersToSet: Text
    var
        ReportFilterInfoJsonArray: JsonArray;
        OutputReportFilters: JsonArray;
    begin
        ReportFilterInfoJsonArray.ReadFrom(ReportFiltersInfo);

        OutputReportFilters := MergeValuesIntoFirstFilter(ReportFilterInfoJsonArray, FilterValuesJsonArray);

        ReportFilterInfoJsonArray.WriteTo(ReportFiltersToSet);
    end;
#endif

    procedure MergeValuesIntoFirstFilter(ReportFiltersInfo: JsonArray; FilterValuesJsonArray: JsonArray) ReportFiltersWithValues: JsonArray
    var
        FilterPath: Text;
    begin
        FilterPath := FindFirstFilter(ReportFiltersInfo);

        if (FilterPath = '') or (ReportFiltersInfo.Count() = 0) then
            exit(ReportFiltersInfo);

        ReportFiltersWithValues := ReportFiltersInfo.Clone().AsArray();

        MergeValuesIntoFilterByPath(ReportFiltersWithValues, FilterPath, FilterValuesJsonArray);

        exit(ReportFiltersWithValues);
    end;

    procedure VariantToFilter(InputSelectionVariant: Variant): JsonArray
    var
        ValuesJArray: JsonArray;
    begin
        AddToJsonArray(ValuesJArray, InputSelectionVariant);

        exit(ValuesJArray);
    end;

    local procedure MergeValuesIntoFilterByPath(var FiltersJsonArray: JsonArray; FilterPath: Text; FilterValuesJsonArray: JsonArray)
    var
        FilterStructure: JsonObject;
        FilterStuctureToken: JsonToken;
        EmptyFilterValuesJsonArray: JsonArray;
    begin
        FiltersJsonArray.SelectToken(FilterPath, FilterStuctureToken);
        FilterStructure := FilterStuctureToken.AsObject();

        FilterStructure.Remove('operator');
        FilterStructure.Remove('values');

        if FilterValuesJsonArray.Count() = 0 then begin
            FilterStructure.Add('operator', 'All');
            FilterStructure.Add('values', EmptyFilterValuesJsonArray);
        end else begin
            FilterStructure.Add('operator', 'In');
            FilterStructure.Add('values', FilterValuesJsonArray);
        end;
    end;

    local procedure FindFirstFilter(JArrayFilters: JsonArray): Text
    var
        JTokenFilter: JsonToken;
        JTokenSchema: JsonToken;
    begin
        foreach JTokenFilter in JArrayFilters do
            if JTokenFilter.IsObject() then
                if JTokenFilter.AsObject().Get('$schema', JTokenSchema) then
                    if JTokenSchema.IsValue() then
                        if JTokenSchema.AsValue().AsText() = BasicFilterSchemaTok then
                            exit(JTokenFilter.Path());

        Session.LogMessage('0000KQT', NoFilterDefinedTelemetryMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiServiceMgt.GetPowerBiTelemetryCategory());
        exit('');
    end;

    procedure RecordRefToFilter(FilteringRecordRef: RecordRef; FieldNumber: Integer) ValuesJArray: JsonArray
    var
        FilteringFieldRef: FieldRef;
    begin
        if FilteringRecordRef.GetFilters() = '' then
            exit;

        if FilteringRecordRef.Count() > 100 then begin
            Session.LogMessage('0000LMO', StrSubstNo(SelectionTooLargeTelemetryMsg, FilteringRecordRef.Count(), 100), Verbosity::Normal,
                DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiServiceMgt.GetPowerBiTelemetryCategory());
            exit;
        end;

        FilteringRecordRef.SetLoadFields(FieldNumber);
        if FilteringRecordRef.FindSet() then
            repeat
                FilteringFieldRef := FilteringRecordRef.Field(FieldNumber);
                AddToJsonArray(ValuesJArray, FilteringFieldRef.Value);
            until FilteringRecordRef.Next() = 0;
    end;

    local procedure AddToJsonArray(var JsonArray: JsonArray; InputSelectionVariant: Variant)
    var
        TextVariable: Text;
        DateVariable: Date;
        TimeVariable: Time;
        DateTimeVariable: DateTime;
        DecimalVariable: Decimal;
        BooleanVariable: Boolean;
        IntegerVariable: Integer;
    begin
        case true of
            InputSelectionVariant.IsText,
            InputSelectionVariant.IsGuid,
            InputSelectionVariant.IsCode:
                begin
                    TextVariable := InputSelectionVariant;
                    JsonArray.Add(TextVariable);
                end;
            InputSelectionVariant.IsDate:
                begin
                    DateVariable := InputSelectionVariant;
                    JsonArray.Add(DateVariable);
                end;
            InputSelectionVariant.IsTime:
                begin
                    TimeVariable := InputSelectionVariant;
                    JsonArray.Add(TimeVariable);
                end;
            InputSelectionVariant.IsDateTime:
                begin
                    DateTimeVariable := InputSelectionVariant;
                    JsonArray.Add(DateTimeVariable);
                end;
            InputSelectionVariant.IsInteger:
                begin
                    IntegerVariable := InputSelectionVariant;
                    JsonArray.Add(IntegerVariable);
                end;
            InputSelectionVariant.IsBoolean:
                begin
                    BooleanVariable := InputSelectionVariant;
                    JsonArray.Add(BooleanVariable);
                end;
            InputSelectionVariant.IsDecimal:
                begin
                    DecimalVariable := InputSelectionVariant;
                    JsonArray.Add(DecimalVariable);
                end;
            else begin
                Session.LogMessage('0000GJU', UnsupportedFilterTypeTelemetryMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiServiceMgt.GetPowerBiTelemetryCategory());
                TextVariable := Format(InputSelectionVariant, 0, 9);
                JsonArray.Add(TextVariable);
            end;
        end;
    end;
}