codeunit 144067 "UT COD Source Code"
{
    // 1. Purpose of the test is to verify error OnRun trigger of Codeunit 11 - Gen. Jnl.-Check Line.
    // 
    // Covers Test Cases for WI - 345027.
    // ---------------------------------------------------
    // Test Function Name                    TFS ID
    // ---------------------------------------------------
    // OnRunGenJnlCheckLineError             151201,151202

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryUTUtility: Codeunit "Library UT Utility";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRunGenJnlCheckLineError()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to verify error OnRun trigger of Codeunit 11 - Gen. Jnl.-Check Line.

        // Setup.
        CreateGeneralJournalLine(GenJournalLine);

        // Exercise.
        asserterror CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Check Line", GenJournalLine);

        // Verify: Verify actual error Source Code must have a value in Gen. Journal Line: Journal Template Name=, Journal Batch Name=, Line No.=0. It cannot be zero or empty.
        Assert.ExpectedErrorCode('TestField');
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine."Posting Date" := WorkDate;
        GenJournalLine."Account No." := LibraryUTUtility.GetNewCode;
        GenJournalLine.Insert();
    end;
}

