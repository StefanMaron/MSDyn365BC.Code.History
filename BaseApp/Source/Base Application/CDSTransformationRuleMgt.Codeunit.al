codeunit 5397 "CDS Transformation Rule Mgt."
{
    var
        IncorrectFormatOrTypeErr: Label 'The value that you are trying to convert is in incorrect format.';

    [EventSubscriber(ObjectType::Table, Database::"Transformation Rule", 'OnBeforeDeleteEvent', '', false, false)]
    procedure OnDeleteTransformationRule(var Rec: Record "Transformation Rule"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        if IsTransformationRuleInUse(Rec) then
            Error(StrSubstNo('%1 cannot be deleted because it is in use.', Rec.Code));
    end;

    local procedure IsTransformationRuleInUse(Rec: Record "Transformation Rule"): Boolean
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
    begin
        IntegrationFieldMapping.SetFilter("Transformation Rule", Rec.Code);
        repeat
            if IntegrationFieldMapping.FindFirst() then
                if IntegrationFieldMapping.SystemId <> Rec.SystemId then
                    exit(true);
        until IntegrationFieldMapping.Next() <= 0;
    end;

    procedure ApplyTransformations(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        TransformationRule: Record "Transformation Rule";
    begin
        IntegrationFieldMapping.SetFilter("Integration Table Mapping Name", '%1|%2|%3|%4', GetIntegrationTableMappingName(SourceRecordRef), GetIntegrationTableMappingName(DestinationRecordRef), GetSourceDestCode(SourceRecordRef, DestinationRecordRef), GetSourceDestCode(DestinationRecordRef, SourceRecordRef));
        IntegrationFieldMapping.SetFilter("Transformation Rule", '<>%1', ' ');

        if IntegrationFieldMapping.FindFirst() then begin
            IntegrationTableMapping.Get(IntegrationFieldMapping."Integration Table Mapping Name");
            repeat
                if TransformationRule.Get(IntegrationFieldMapping."Transformation Rule") then
                    case IntegrationFieldMapping."Transformation Direction" of
                        IntegrationFieldMapping."Transformation Direction"::FromIntegrationTable:
                            if IntegrationTableMapping."Integration Table ID" = SourceRecordRef.Number() then
                                TransformValue(SourceRecordRef, DestinationRecordRef, TransformationRule, IntegrationFieldMapping."Integration Table Field No.", IntegrationFieldMapping."Field No.");
                        IntegrationFieldMapping."Transformation Direction"::ToIntegrationTable:
                            if IntegrationTableMapping."Table ID" = SourceRecordRef.Number() then
                                TransformValue(SourceRecordRef, DestinationRecordRef, TransformationRule, IntegrationFieldMapping."Field No.", IntegrationFieldMapping."Integration Table Field No.");
                    end;
            until IntegrationFieldMapping.Next() <= 0;
        end;
    end;

    local procedure TransformValue(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef; TransformationRule: Record "Transformation Rule"; SourceFieldNo: Integer; DestinationFieldNo: Integer)
    var
        SourceFieldRef: FieldRef;
        DestinationFieldRef: FieldRef;
        TransformedValue: Text;
    begin
        SourceFieldRef := SourceRecordRef.Field(SourceFieldNo);
        DestinationFieldRef := DestinationRecordRef.Field(DestinationFieldNo);
        TransformedValue := TransformationRule.TransformText(SourceFieldRef.Value());

        case DestinationFieldRef.Type() of
            FieldType::Date, FieldType::DateTime:
                SetDateField(TransformedValue, SourceFieldRef, DestinationFieldRef, TransformationRule);
            else
                SourceFieldRef.Value := TransformedValue;
        end;
    end;

    local procedure SetDateField(ValueText: Text; var SourceFieldRef: FieldRef; DestinationFieldRef: FieldRef; TransformationRule: Record "Transformation Rule")
    var
        TypeHelper: Codeunit "Type Helper";
        Value: Variant;
    begin
        Value := DestinationFieldRef.Value();

        if not TypeHelper.Evaluate(Value, ValueText, '', '')
        then
            Error(IncorrectFormatOrTypeErr);

        SourceFieldRef.Value := Value;
    end;

    procedure GetIntegrationTableMappingName(RecRef: RecordRef): Text
    begin
        if RecRef.Number() <> 0 then
            exit(CopyStr(UpperCase(RecRef.Name()), 1, 20));
        exit('');
    end;

    local procedure GetSourceDestCode(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef): Text
    begin
        if (SourceRecordRef.Number() <> 0) and (DestinationRecordRef.Number() <> 0) then
            exit(CopyStr(StrSubstNo('%1-%2', UpperCase(SourceRecordRef.Name().Replace('CRM', '')), UpperCase(DestinationRecordRef.Name().Replace('CRM ', ''))), 1, 20));
        exit('');
    end;
}
