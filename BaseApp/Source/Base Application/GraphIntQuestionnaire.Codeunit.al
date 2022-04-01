#if not CLEAN20
codeunit 5462 "Graph Int. - Questionnaire"
{
    ObsoleteReason = 'This codeunit will be deleted since the functionality that it was used for was discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '20.0';

    trigger OnRun()
    begin
    end;

#pragma warning disable AA0150
    procedure OnAfterTransferRecordFields(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var AdditionalFieldsWereModified: Boolean)
    begin
    end;

    procedure OnAfterInsertRecord(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef)
    begin
    end;

    procedure OnAfterModifyRecord(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    begin
    end;
#pragma warning restore AA0150

    procedure GetGraphSyncQuestionnaireCode(): Code[10]
    begin
        exit(UpperCase('GraphSync'));
    end;

    procedure CreateGraphSyncQuestionnaire()
    begin
    end;
}

#endif