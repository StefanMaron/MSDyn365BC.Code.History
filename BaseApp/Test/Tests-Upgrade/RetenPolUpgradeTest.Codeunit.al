codeunit 135952 "Reten. Pol. Upgrade Test"
{
    Subtype = Test;

    var
        LibraryAssert: Codeunit "Library Assert";
        IsInitialized: Boolean;

    [Test]
    procedure TestChangeLogRetentionPolicyUpdated()
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
        RetentionPolicySetupLine: Record "Retention Policy Setup Line";
        ChangeLogEntry: Record "Change Log Entry";
    begin
        // Init
        Initialize();

        // Setup
        RetentionPolicySetup.SetRange("Table Id", Database::"Change Log Entry");
        RetentionPolicySetup.DeleteAll();

        // Exercise
        RetentionPolicySetup."Table Id" := Database::"Change Log Entry";
        RetentionPolicySetup.Insert(true);

        // Verify
        RetentionPolicySetupLine.Get(Database::"Change Log Entry", 10000);
        LibraryAssert.IsTrue(RetentionPolicySetupLine.IsLocked(), 'Retention Policy Line should be locked');
        ChangeLogEntry.SetView(RetentionPolicySetupLine.GetTableFilterView());
        LibraryAssert.AreEqual(Format(true), ChangeLogEntry.GetFilter(Protected), 'The Filter View on the retention policy line is incorrect.');
        LibraryAssert.AreEqual(UpperCase(Format("Retention Period Enum"::"1 Year")), RetentionPolicySetupLine."Retention Period", 'Incorrect period for retention policy setup line');

        RetentionPolicySetupLine.Get(Database::"Change Log Entry", 20000);
        LibraryAssert.IsTrue(RetentionPolicySetupLine.IsLocked(), 'Retention Policy Line should be locked');
        ChangeLogEntry.SetView(RetentionPolicySetupLine.GetTableFilterView());
        LibraryAssert.AreEqual(StrSubstNo('%1|%2', "Field Log Entry Feature"::"Monitor Sensitive Fields", "Field Log Entry Feature"::All), ChangeLogEntry.GetFilter("Field Log Entry Feature"), 'The Filter View on the retention policy line is incorrect.');
        LibraryAssert.AreEqual(UpperCase(Format("Retention Period Enum"::"28 Days")), RetentionPolicySetupLine."Retention Period", 'Incorrect period for retention policy setup line');

        RetentionPolicySetupLine.Get(Database::"Change Log Entry", 30000);
        LibraryAssert.IsFalse(RetentionPolicySetupLine.IsLocked(), 'Retention Policy Line should be locked');
        ChangeLogEntry.SetView(RetentionPolicySetupLine.GetTableFilterView());
        LibraryAssert.AreEqual(Format(false), ChangeLogEntry.GetFilter(Protected), 'The Filter View on the retention policy line is incorrect.');
        LibraryAssert.AreEqual(UpperCase(Format("Retention Period Enum"::"1 Year")), RetentionPolicySetupLine."Retention Period", 'Incorrect period for retention policy setup line');
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        Commit();
        IsInitialized := true;
    end;
}