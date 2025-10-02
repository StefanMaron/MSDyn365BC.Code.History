#if not CLEAN25
codeunit 142081 "UT PAG Vendor 1099"
{
    Subtype = Test;
    TestPermissions = Disabled;
    ObsoleteReason = 'Moved to IRS Forms App.';
    ObsoleteState = Pending;
    ObsoleteTag = '25.0';

    trigger OnRun()
    begin
    end;

    var
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        CodeDIV01B: Label 'DIV-01-B';
        AmtCodesErr: Label 'Wrong AmtCodes value';

    [Test]
    [Scope('OnPrem')]
    procedure OnRunAPMagneticMediaManagement()
    var
        APMagneticMediaManagement: Codeunit "A/P Magnetic Media Management";
        CodeNos: Text;
        i: Integer;
    begin
        // [FEATURE] [A/P Magnetic Media]
        // Purpose is to test Codeunit 10085 A/P Magnetic Media Management On Run trigger and AmtCodes function.

        // Setup.
        Initialize();
        i := LibraryRandom.RandIntInRange(2, 10);
        APMagneticMediaManagement.Run();

        // [WHEN] run AmtCodes()
        APMagneticMediaManagement.AmtCodes(CodeNos, i, i);  // Value is not required for CodeNos.

        // Verify: Purpose for exercise is to execute the Amt Codes function Sucessfully.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure "VerifyAmtCodes_DIV-01-B"()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        APMagneticMediaManagement: Codeunit "A/P Magnetic Media Management";
        CodeNos: Text[12];
        FormType: Integer;
        EndLine: Integer;
    begin
        // [FEATURE] [A/P Magnetic Media]
        // Verify AmtCodes returned by Codeunit 10085 A/P Magnetic Media Management
        // in case of 'DIV-01-B' non-zero amount
        Initialize();

        FormType := 2; // DIV type
        EndLine := 30; // AmtCodes array length

        APMagneticMediaManagement.Run();
        APMagneticMediaManagement.UpdateLines(VendorLedgerEntry, FormType, EndLine, CodeDIV01B, LibraryRandom.RandDec(1000, 2));
        // [WHEN] run AmtCodes()
        APMagneticMediaManagement.AmtCodes(CodeNos, FormType, EndLine);

        Assert.AreEqual('12', CodeNos, AmtCodesErr);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;
}
#endif
