namespace Microsoft.Foundation.NoSeries;

using Microsoft.CRM.Interaction;

codeunit 9500 "Sequence No. Mgt."
{
    SingleInstance = true;
    InherentPermissions = X;
    Permissions = TableData "Interaction Log Entry" = r, Tabledata Attachment = r;

    var
        GlobalPreviewMode: Boolean;
        GlobalPreviewModeTag: Text;
        SeqNameLbl: Label 'TableSeq%1', Comment = '%1 - Table No.', Locked = true;
        PreviewSeqNameLbl: Label 'PreviewTableSeq%1', Comment = '%1 - Table No.', Locked = true;

    procedure GetNextSeqNo(TableNo: Integer): Integer
    var
        NewSeqNo: Integer;
        PreviewMode: Boolean;
    begin
        PreviewMode := IsPreviewMode();  // Only call once to minimize sql calls during preview.
        if TryGetNextNo(PreviewMode, TableNo, NewSeqNo) then
            exit(NewSeqNo);
        ClearLastError();
        CreateNewTableSequence(PreviewMode, TableNo);
        TryGetNextNo(PreviewMode, TableNo, NewSeqNo);
        exit(NewSeqNo);
    end;

    [TryFunction]
    local procedure TryGetNextNo(PreviewMode: Boolean; TableNo: Integer; var NewSeqNo: Integer)
    begin
        NewSeqNo := NumberSequence.Next(GetTableSequenceName(PreviewMode, TableNo));
    end;

    procedure RebaseSeqNo(TableNo: Integer)
    begin
        CreateNewTableSequence(IsPreviewMode(), TableNo);
    end;

    local procedure CreateNewTableSequence(PreviewMode: Boolean; TableNo: Integer)
    var
        StartSeqNo: BigInteger;
        IsPreviewable: Boolean;
    begin
        OnPreviewableLedgerEntry(TableNo, IsPreviewable);
        if PreviewMode and IsPreviewable then
            StartSeqNo := -2000000000
        else
            StartSeqNo := GetLastEntryNoFromTable(TableNo) + 1;

        CreateSequence(GetTableSequenceName(PreviewMode and IsPreviewable, TableNo), StartSeqNo);

        if PreviewMode or not IsPreviewable then
            exit;

        // Creating/deleting a number sequence is transactional, so we benefit from creating the preview sequence in a non-preview transaction
        CreateSequence(GetTableSequenceName(true, TableNo), -2000000000);
    end;

    local procedure CreateSequence(SequenceName: Text; StartSeqNo: BigInteger)
    begin
        if NumberSequence.Exists(SequenceName) then
            NumberSequence.Restart(SequenceName, StartSeqNo)
        else
            NumberSequence.Insert(SequenceName, StartSeqNo, 1, true);
    end;

    local procedure GetLastEntryNoFromTable(TableNo: Integer): BigInteger
    var
        [SecurityFiltering(SecurityFilter::Ignored)]
        RecRef: RecordRef;
        FldRef: FieldRef;
        KeyRef: KeyRef;
        LastEntryNo: BigInteger;
    begin
        RecRef.Open(TableNo);
        KeyRef := RecRef.KeyIndex(1);
        RecRef.SetLoadFields(KeyRef.FieldIndex(KeyRef.FieldCount).Number);
        RecRef.LockTable();
        if RecRef.FindLast() then begin
            FldRef := KeyRef.FieldIndex(KeyRef.FieldCount);
            LastEntryNo := FldRef.Value
        end else
            LastEntryNo := 0;
        exit(LastEntryNo);
    end;

    procedure GetTableSequenceName(TableNo: Integer): Text
    begin
        exit(GetTableSequenceName(IsPreviewMode(), TableNo));
    end;

    procedure GetTableSequenceName(PreviewMode: Boolean; TableNo: Integer): Text
    var
        IsPreviewable: Boolean;
    begin
        if PreviewMode then
            OnPreviewableLedgerEntry(TableNo, IsPreviewable);
        if IsPreviewable then
            exit(StrSubstNo(PreviewSeqNameLbl, TableNo));
        exit(StrSubstNo(SeqNameLbl, TableNo));
    end;

    // An error during preview may mean that the PreviewMode variable doesn't get reset after preview, so we need to rely on transactional consistency
    local procedure IsPreviewMode(): Boolean
    begin
        if not GlobalPreviewMode then
            exit(false);
        if GlobalPreviewModeTag <> '' then
            if NumberSequence.Exists(GlobalPreviewModeTag) then
                exit(true);
        GlobalPreviewMode := false;
        GlobalPreviewModeTag := '';
    end;

    internal procedure StartPreviewMode()
    begin
        if GlobalPreviewMode then // missing cleanup from previous preview?
            StopPreviewMode();
        GlobalPreviewMode := true;
        GlobalPreviewModeTag := 'Preview_' + DelChr(Format(CreateGuid()), '=', '{}-');
        CreateSequence(GlobalPreviewModeTag, 1); // Preview is in a transaction that does not allow commits and will be rolled back.
    end;

    internal procedure StopPreviewMode()
    begin
        GlobalPreviewMode := false;
        if GlobalPreviewModeTag <> '' then
            if NumberSequence.Exists(GlobalPreviewModeTag) then
                NumberSequence.Delete(GlobalPreviewModeTag);
        GlobalPreviewModeTag := '';
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPreviewableLedgerEntry(TableNo: Integer; var IsPreviewable: Boolean)
    begin
    end;
}