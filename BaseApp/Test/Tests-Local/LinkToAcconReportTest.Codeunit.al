codeunit 144047 LinkToAcconReportTest
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        WrongFormatErr: Label 'Leading whitespaces are not allowed in exported GL Account No.';

    [Test]
    [HandlerFunctions('VariableFilenameReuqestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportFileHasExpectedRowCount()
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        LinkToAccon: Report "Link to Accon";
        FileMgt: Codeunit "File Management";
        File: File;
        ServerFilename: Text;
        LineData: Text;
        LineCount: Integer;
        LineAmount: Decimal;
        FoundTestAccount: Boolean;
    begin
        // Setup: Create two GL Accounts where one has Account Type Posting.
        with GLAccount do begin
            LibraryERM.CreateGLAccount(GLAccount);
            "Account Type" := "Account Type"::Total;
            Modify(true);

            Reset();
            LibraryERM.CreateGLAccount(GLAccount);
            "Account Type" := "Account Type"::Posting;
            Modify(true);
        end;

        with GLEntry do begin
            Init();
            "Entry No." := 10000001;
            "G/L Account No." := GLAccount."No.";
            "Posting Date" := WorkDate();
            Amount := LibraryRandom.RandDec(1000, 2);
            Insert();
        end;

        Commit();

        // Run the report
        ServerFilename := FileMgt.ServerTempFileName('TXT');

        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(false);

        LinkToAccon.InitializeRequest(ServerFilename);
        LinkToAccon.Run();

        // Validate
        // * File is created
        // * File contains all the Posting accounts
        // * File contains value from en gl entry
        Assert.IsTrue(FileMgt.ServerFileExists(ServerFilename), 'Expected the report to produce a file');

        GLAccount.Reset();
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
        Assert.AreNotEqual(0, GLAccount.Count, 'Expected at least one GLAccount with Account Type Posting');

        File.Open(ServerFilename);
        File.TextMode := true;
        while File.Read(LineData) > 0 do begin
            LineCount := LineCount + 1;
            Assert.AreNotEqual(' ', CopyStr(LineData, 1, 1), WrongFormatErr);
            if StrPos(LineData, Format(GLAccount."No.", 20)) = 1 then begin
                FoundTestAccount := true;
                // Test that the amount matches the entry
                Evaluate(LineAmount, CopyStr(LineData, 21, 13));
                // Using nearly equal to avoid decimal point conversion (. vs ,)
                Assert.AreNearlyEqual(GLEntry.Amount, LineAmount, 1, 'Expected amount to be present in line');
            end;
        end;
        File.Close();

        Assert.AreEqual(LineCount, GLAccount.Count, 'Expected the expected row count to match data');
        Assert.IsTrue(FoundTestAccount, 'Expected to find the test account in the exported data');

        FileMgt.DeleteServerFile(ServerFilename);
    end;

    [Test]
    [HandlerFunctions('VariableFilenameReuqestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportFileWithAddReportCurrency()
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        LinkToAccon: Report "Link to Accon";
        FileMgt: Codeunit "File Management";
        File: File;
        ServerFilename: Text;
        LineData: Text;
        LineCount: Integer;
        LineAmount: Decimal;
        FoundTestAccount: Boolean;
    begin
        // Setup: Create two GL Accounts where one has Account Type Posting.
        with GLAccount do begin
            LibraryERM.CreateGLAccount(GLAccount);
            "Account Type" := "Account Type"::Total;
            Modify(true);

            Reset();
            LibraryERM.CreateGLAccount(GLAccount);
            "Account Type" := "Account Type"::Posting;
            Modify(true);
        end;

        with GLEntry do begin
            Init();
            "Entry No." := 10000002;
            "G/L Account No." := GLAccount."No.";
            "Posting Date" := WorkDate();
            Amount := LibraryRandom.RandDec(1000, 2);
            "Additional-Currency Amount" := Amount * 3;
            Insert();
        end;

        Commit();

        // Run the report
        ServerFilename := FileMgt.ServerTempFileName('TXT');

        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(true);

        LinkToAccon.InitializeRequest(ServerFilename);
        LinkToAccon.Run();

        // Validate
        // * File is created
        // * File contains all the Posting accounts
        // * File contains value from en gl entry
        Assert.IsTrue(FileMgt.ServerFileExists(ServerFilename), 'Expected the report to produce a file');

        GLAccount.Reset();
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
        Assert.AreNotEqual(0, GLAccount.Count, 'Expected at least one GLAccount with Account Type Posting');

        File.Open(ServerFilename);
        File.TextMode := true;
        while File.Read(LineData) > 0 do begin
            LineCount := LineCount + 1;
            Assert.AreNotEqual(' ', CopyStr(LineData, 1, 1), WrongFormatErr);
            if StrPos(LineData, Format(GLAccount."No.", 20)) = 1 then begin
                FoundTestAccount := true;
                // Test that the amount matches the entry
                Evaluate(LineAmount, CopyStr(LineData, 21, 13));
                // Using nearly equal to avoid decimal point conversion (. vs ,)
                Assert.AreNotNearlyEqual(GLEntry.Amount, LineAmount, 1, 'Expected amount to be addtional currency amout not amount');
                Assert.AreNearlyEqual(GLEntry."Additional-Currency Amount", LineAmount, 1, 'Expected amount to match');
            end;
        end;
        File.Close();

        Assert.AreEqual(LineCount, GLAccount.Count, 'Expected the expected row count to match data');
        Assert.IsTrue(FoundTestAccount, 'Expected to find the test account in the exported data');

        FileMgt.DeleteServerFile(ServerFilename);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VariableFilenameReuqestPageHandler(var LinkToAcconRequestPage: TestRequestPage "Link to Accon")
    var
        UseAddReportCurrency: Variant;
    begin
        LibraryVariableStorage.Dequeue(UseAddReportCurrency);
        LinkToAcconRequestPage.UseAmtsInAddCurr.SetValue(UseAddReportCurrency);
        LinkToAcconRequestPage.OK.Invoke;
    end;
}

