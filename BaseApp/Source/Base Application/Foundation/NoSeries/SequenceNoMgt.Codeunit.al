namespace Microsoft.Foundation.NoSeries;

using Microsoft.CRM.Interaction;

codeunit 9500 "Sequence No. Mgt."
{
    SingleInstance = true;
    InherentPermissions = X;
    Permissions = TableData "Interaction Log Entry" = r, Tabledata Attachment = r;

    var
        SeqNameLbl: Label 'TableSeq%1', Comment = '%1 - Table No.', Locked = true;

    procedure GetNextSeqNo(TableNo: Integer): Integer
    var
        NewSeqNo: Integer;
    begin
        if TryGetNextNo(TableNo, NewSeqNo) then
            exit(NewSeqNo);
        ClearLastError();
        CreateNewTableSequence(TableNo);
        TryGetNextNo(TableNo, NewSeqNo);
        exit(NewSeqNo);
    end;

    procedure RebaseSeqNo(TableNo: Integer)
    begin
        CreateNewTableSequence(TableNo);
    end;

    local procedure CreateNewTableSequence(TableNo: Integer)
    var
        LastSeqNo: BigInteger;
    begin
        LastSeqNo := GetLastEntryNoFromTable(TableNo);
        if NumberSequence.Exists(GetTableSequenceName(TableNo)) then
            NumberSequence.Delete(GetTableSequenceName(TableNo));
        NumberSequence.Insert(GetTableSequenceName(TableNo), LastSeqNo + 1, 1, true);
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

    [TryFunction]
    local procedure TryGetNextNo(TableNo: Integer; var NewSeqNo: Integer)
    begin
        NewSeqNo := NumberSequence.Next(GetTableSequenceName(TableNo));
    end;

    procedure GetTableSequenceName(TableNo: Integer): Text
    begin
        exit(StrSubstNo(SeqNameLbl, TableNo));
    end;
}