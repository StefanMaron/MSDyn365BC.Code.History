codeunit 134899 "Test Sequence No. Mgt."
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    var
        Assert: Codeunit "Assert";

    [Test]
    procedure VerifyInitSequence()
    var
        GLEntry: Record "G/L Entry";
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
        SequenceName: Text;
        NextNo: Integer;
    begin
        // First time we use GetNextSequenceNo the sequence should be created automatically
        SequenceName := SequenceNoMgt.GetTableSequenceName(Database::"G/L Entry");
        if NumberSequence.Exists(SequenceName) then
            NumberSequence.Delete(SequenceName);
        if GLEntry.FindLast() then;
        NextNo := SequenceNoMgt.GetNextSeqNo(Database::"G/L Entry");
        Assert.IsTrue(NumberSequence.Exists(SequenceName), 'Sequence not created');
        Assert.AreEqual(GLEntry."Entry No." + 1, NextNo, 'Wrong number generated');
        Assert.AreEqual('', GetLastErrorText(), 'Error not cleared after TryFunction');
    end;

    [Test]
    procedure VerifyRebase()
    var
        InteractionLogEntry: Record "Interaction Log Entry";
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
        NextNo: Integer;
        LastNo: Integer;
    begin
        // For resiliency, some tables will have a special InsertRec function that handles out-of-sync sequences
        if InteractionLogEntry.FindLast() then;
        LastNo := InteractionLogEntry."Entry No.";
        NextNo := SequenceNoMgt.GetNextSeqNo(Database::"Interaction Log Entry");
        Assert.IsTrue(NumberSequence.Exists(SequenceNoMgt.GetTableSequenceName(Database::"Interaction Log Entry")), 'Sequence not created');
        InteractionLogEntry."Entry No." := NextNo;
        InteractionLogEntry.Insert();
        InteractionLogEntry."Entry No." += 1;
        InteractionLogEntry.Insert(); // now the sequence is out of sync
        LastNo := InteractionLogEntry."Entry No.";
        InteractionLogEntry.InsertRecord(); // should trigger rebase and renewed Entry No.
        Assert.IsTrue(InteractionLogEntry."Entry No." > LastNo, 'Wrong number generated');
    end;

}