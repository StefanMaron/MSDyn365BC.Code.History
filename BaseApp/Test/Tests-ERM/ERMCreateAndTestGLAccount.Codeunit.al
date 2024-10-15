codeunit 134225 "ERM CreateAndTestGLAccount"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [G/L Account] [Indentation]
    end;

    var
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateGLAccount()
    var
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        LibraryERM: Codeunit "Library - ERM";
        GLAccountIndent: Codeunit "G/L Account-Indent";
        Assert: Codeunit Assert;
        DeltaAssert: Codeunit "Delta Assert";
        PreviousIndentation: Integer;
        Amount: Decimal;
    begin
        // Test Covers TFS_TS_ID: 111509: Test suite: Create new G/L Account.
        // 1. Create a new GL Account.
        // 2. Indent the newly created GL Account.
        // 3. Create General Journal Line for the newly created GL Account.
        // 4. Post the General Journal Line.
        // 5. Verify the Balance Amount in GL Account using DeltaAssert. Verify the Indentation Value for GL Account.

        // Setup: Create a new GL Account.
        PreviousIndentation := CreateGLAccount(GLAccount);

        // Exercise: Indent the GL Account. Create and Post the General Journal Lines using the newly created GL Account.
        GLAccountIndent.Indent;

        Amount := LibraryRandom.RandInt(100);  // Store Random Amount in a variable and use it in DeltaAssert.
        DeltaAssert.Init;
        DeltaAssert.AddWatch(DATABASE::"G/L Account", GLAccount.GetPosition, GLAccount.FieldNo(Balance), Amount);

        CreateGnlJnlLines(GenJournalLine, GLAccount."No.", Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify the Balance Amount in GL Account using DeltaAssert. Verify the Indentation Value for GL Account.
        DeltaAssert.Assert;

        GLAccount.Get(GLAccount."No.");
        Assert.AreEqual(PreviousIndentation + 1, GLAccount.Indentation, 'Account was not indented correctly.');
    end;

    [Normal]
    local procedure CreateGLAccount(var GLAccount2: Record "G/L Account"): Integer
    var
        GLAccount: Record "G/L Account";
        GLAccountNo1: Decimal;
        GLAccountNo2: Decimal;
    begin
        GLAccount.SetFilter(Totaling, '<>%1', '');
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::"End-Total");  // required for BE
        GLAccount.FindFirst;

        GLAccount2.SetFilter("No.", GLAccount.Totaling);
        GLAccount2.FindFirst;
        Evaluate(GLAccountNo1, CopyStr(GLAccount2."No.", 4, 4));

        GLAccount2.Next;
        Evaluate(GLAccountNo2, CopyStr(GLAccount2."No.", 4, 4));

        // Create a new GL Account. Find the Account No. by dividing sum of Begin-Total Account and next Account by two.
        GLAccount2.Init;
        GLAccount2.Validate("No.", CopyStr(GLAccount2."No.", 1, 3) + (DelChr(Format((GLAccountNo1 + GLAccountNo2) / 2, 20, 1))));
        // Using 20 for Length of No. field, 1 for seperator.
        GLAccount2.Insert(true);
        GLAccount2.Validate(Name, GLAccount2."No.");
        GLAccount2.Validate("Income/Balance", GLAccount."Income/Balance");
        GLAccount2.Validate("Account Type", GLAccount."Account Type"::Posting);
        GLAccount2.Modify(true);
        exit(GLAccount.Indentation);  // Return the indentation value.
    end;

    [Normal]
    local procedure CreateGnlJnlLines(var GenJournalLine: Record "Gen. Journal Line"; GLAccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        LibraryERM: Codeunit "Library - ERM";
    begin
        // Create General Journal Lines using newly created GL Account.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccountNo, Amount);
    end;
}

