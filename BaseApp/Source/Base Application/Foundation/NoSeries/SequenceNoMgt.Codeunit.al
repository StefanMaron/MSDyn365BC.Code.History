// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.NoSeries;

codeunit 9500 "Sequence No. Mgt."
{
    SingleInstance = true;
    InherentPermissions = X;

    var
        GlobalPreviewMode: Boolean;
        GlobalPreviewModeTag: Text;
        LastSeqNoChecked: List of [Integer];
        SeqNameLbl: Label 'TableSeq%1', Comment = '%1 - Table No.', Locked = true;
        PreviewSeqNameLbl: Label 'PreviewTableSeq%1', Comment = '%1 - Table No.', Locked = true;

    /// <summary>
    /// Returns the next NumberSequence value for a given table ID.
    /// if the sequence does not exist, it will be created.
    /// </summary>
    /// <param name="TableNo">The ID of the table being checked</param>
    procedure GetNextSeqNo(TableNo: Integer): Integer
    var
        NewSeqNo: Integer;
        PreviewMode: Boolean;
    begin
        ValidateSeqNo(TableNo);
        PreviewMode := IsPreviewMode();  // Only call once to minimize sql calls during preview.
        if TryGetNextNo(PreviewMode, TableNo, NewSeqNo) then
            exit(NewSeqNo);
        ClearLastError();
        CreateNewTableSequence(PreviewMode, TableNo);
        TryGetNextNo(PreviewMode, TableNo, NewSeqNo);
        exit(NewSeqNo);
    end;

    /// <summary>
    /// Returns the current NumberSequence value for a given table ID.
    /// if the sequence does not exist, it will be created.
    /// </summary>
    /// <param name="TableNo">The ID of the table being checked</param>
    procedure GetCurrentSeqNo(TableNo: Integer): Integer
    var
        CurrSeqNo: Integer;
        PreviewMode: Boolean;
    begin
        PreviewMode := IsPreviewMode();  // Only call once to minimize sql calls during preview.
        if TryGetCurrentNo(PreviewMode, TableNo, CurrSeqNo) then
            exit(CurrSeqNo);
        ClearLastError();
        CreateNewTableSequence(PreviewMode, TableNo);
        TryGetCurrentNo(PreviewMode, TableNo, CurrSeqNo);
        exit(CurrSeqNo);
    end;

    /// <summary>
    /// Ensures that the NumberSequence is not behind the last entry in the table.
    /// if the sequence does not exist, it will be created.
    /// The result will be cached for the current transaction. The cache can be cleared by calling ClearSequenceNoCheck.
    /// </summary>
    /// <param name="TableNo">The ID of the table being checked</param>
    procedure ValidateSeqNo(TableNo: Integer)
    var
        LastEntryNo: Integer;
    begin
        if IsPreviewMode() then
            exit;
        if LastSeqNoChecked.Contains(TableNo) then
            exit;

        LastEntryNo := GetLastEntryNoFromTable(TableNo, false);
        if GetCurrentSeqNo(TableNo) < LastEntryNo then
            RebaseSeqNo(TableNo);

        LastSeqNoChecked.Add(TableNo);
    end;

    /// <summary>
    /// Clears the cache that is used by procedure ValidateSeqNo(TableNo).
    /// </summary>
    procedure ClearSequenceNoCheck()
    begin
        Clear(LastSeqNoChecked);
    end;

    [TryFunction]
    local procedure TryGetNextNo(PreviewMode: Boolean; TableNo: Integer; var NewSeqNo: Integer)
    begin
        NewSeqNo := NumberSequence.Next(GetTableSequenceName(PreviewMode, TableNo));
    end;

    [TryFunction]
    local procedure TryGetCurrentNo(PreviewMode: Boolean; TableNo: Integer; var CurrSeqNo: Integer)
    begin
        CurrSeqNo := NumberSequence.Current(GetTableSequenceName(PreviewMode, TableNo));
    end;

    /// <summary>
    /// Restarts or recreates the NumberSequence for the specified Table ID.
    /// </summary>
    /// <param name="TableNo">The ID of the table being checked</param>
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
            StartSeqNo := GetLastEntryNoFromTable(TableNo, true) + 1;

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

    local procedure GetLastEntryNoFromTable(TableNo: Integer; WithLock: Boolean): BigInteger
    var
        [SecurityFiltering(SecurityFilter::Ignored)]
        RecRef: RecordRef;
        FldRef: FieldRef;
        KeyRef: KeyRef;
        LastEntryNo: BigInteger;
    begin
        RecRef.Open(TableNo);
        if WithLock then
            RecRef.ReadIsolation(IsolationLevel::UpdLock)
        else
            RecRef.ReadIsolation(IsolationLevel::ReadUncommitted);
        KeyRef := RecRef.KeyIndex(1);
        RecRef.SetLoadFields(KeyRef.FieldIndex(KeyRef.FieldCount).Number);
        if RecRef.FindLast() then begin
            FldRef := KeyRef.FieldIndex(KeyRef.FieldCount);
            LastEntryNo := FldRef.Value
        end else
            LastEntryNo := 0;
        exit(LastEntryNo);
    end;

    /// <summary>
    /// Returns the name of the NumberSequence for the specified Table ID.
    /// </summary>
    /// <param name="TableNo">The ID of the table being checked</param>
    procedure GetTableSequenceName(TableNo: Integer): Text
    begin
        exit(GetTableSequenceName(IsPreviewMode(), TableNo));
    end;

    /// <summary>
    /// Returns the name of the NumberSequence for the specified Table ID. We have one sequence for preview and one for non-preview.
    /// </summary>
    /// <param name="PreviewMode">Is true for posting preview</param>
    /// <param name="TableNo">The ID of the table being checked</param>
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
        GlobalPreviewModeTag := 'Preview_' + Format(CreateGuid(), 20, 3);
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
