codeunit 132807 "Removed Tables Data Setup"
{
    Subtype = Upgrade;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Test Data Setup Mgt.", 'OnSetupDataPerCompany', '', false, false)]
    local procedure SetupReferencesToRemovedTables()
    begin
        InsertChangeLogSetupReferences();
    end;

    local procedure InsertChangeLogSetupReferences()
    var
        ChangeLogSetupTable: Record "Change Log Setup (Table)";
    begin
        // Insert references to removed tables
        ChangeLogSetupTable."Table No." := 53; // "Batch Processing Parameter Map"
        ChangeLogSetupTable.Insert();

        ChangeLogSetupTable."Table No." := 897; // "What's New Notified"
        ChangeLogSetupTable.Insert();

        ChangeLogSetupTable."Table No." := 1442; // "Headline RC Accountant"
        ChangeLogSetupTable.Insert();

        ChangeLogSetupTable."Table No." := 2000000101; // "Debugger Call Stack"
        ChangeLogSetupTable.Insert();

        // Insert references to non-removed tables
        ChangeLogSetupTable."Table No." := Database::Customer;
        ChangeLogSetupTable.Insert();

        ChangeLogSetupTable."Table No." := Database::Item;
        ChangeLogSetupTable.Insert();
    end;
}