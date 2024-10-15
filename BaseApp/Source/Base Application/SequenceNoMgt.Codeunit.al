codeunit 9500 "Sequence No. Mgt."
{
    SingleInstance = true;

    var
        SeqNameLbl: Label 'TableSeq%1', Comment = '%1 - Table No.', Locked = true;

    procedure GetNextSeqNo(TableNo: Integer): Integer
    var
        NewSeqNo: Integer;
    begin
        if TryGetNextNo(TableNo, NewSeqNo) then
            exit(NewSeqNo);
        CreateNewTableSequence(TableNo);
        TryGetNextNo(TableNo, NewSeqNo);
        exit(NewSeqNo);
    end;

    procedure RebaseSeqNo(TableNo: Integer)
    begin
        if NumberSequence.Exists(GetTableSequenceName(TableNo)) then
            NumberSequence.Delete(GetTableSequenceName(TableNo));
        CreateNewTableSequence(TableNo);
    end;

    local procedure CreateNewTableSequence(TableNo: Integer)
    var
        [SecurityFiltering(SecurityFilter::Ignored)]
        RecRef: RecordRef;
        FldRef: FieldRef;
        KeyRef: KeyRef;
        LastSeqNo: BigInteger;
    begin
        RecRef.Open(TableNo);
        RecRef.LockTable();
        if RecRef.FindLast() then;
        KeyRef := RecRef.KeyIndex(1);
        FldRef := KeyRef.FieldIndex(KeyRef.FieldCount);
        LastSeqNo := FldRef.Value;
        if NumberSequence.Exists(GetTableSequenceName(TableNo)) then
            NumberSequence.Delete(GetTableSequenceName(TableNo));
        NumberSequence.Insert(GetTableSequenceName(TableNo), LastSeqNo + 1, 1, true);
    end;

    [TryFunction]
    local procedure TryGetNextNo(TableNo: Integer; var NewSeqNo: Integer)
    begin
        NewSeqNo := NumberSequence.Next(GetTableSequenceName(TableNo));
    end;

    local procedure GetTableSequenceName(TableNo: Integer): Text
    begin
        exit(StrSubstNo(SeqNameLbl, TableNo));
    end;
}