codeunit 3995 "Base Application Logs Delete"
{
    Access = Internal;
    Permissions = tabledata "Change Log Entry" = rd,
                tabledata "Job Queue Log Entry" = rd,
                tabledata "Workflow Step Instance Archive" = rd,
                tabledata "Integration Synch. Job" = rd,
                tabledata "Integration Synch. Job Errors" = rd,
                tabledata "Report Inbox" = rd,
                tabledata "Sales Header Archive" = rd,
                tabledata "Purchase Header Archive" = rd,
                tabledata "Dataverse Entity Change" = rd,
                tabledata "Activity Log" = rd;

    var
        NoFiltersErr: Label 'No filters were set on table %1, %2. Please contact your Microsoft Partner for assistance.', Comment = '%1 = a id of a table (integer), %2 = the caption of the table.';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Apply Retention Policy", 'OnApplyRetentionPolicyIndirectPermissionRequired', '', true, true)]
    local procedure DeleteRecordsWithIndirectPermissionsOnApplyRetentionPolicyIndirectPermissionRequired(var RecRef: RecordRef; var Handled: Boolean)
    var
        RetentionPolicyLog: Codeunit "Retention Policy Log";
    begin
        // if someone else took it, exit
        if Handled then
            exit;

        // check if we can handle the table
        if not (RecRef.Number in [Database::"Change Log Entry",
            Database::"Job Queue Log Entry",
            Database::"Workflow Step Instance Archive",
            Database::"Integration Synch. Job",
            Database::"Integration Synch. Job Errors",
            Database::"Report Inbox",
            Database::"Sales Header Archive",
            Database::"Purchase Header Archive",
            Database::"Dataverse Entity Change",
            Database::"Activity Log"])
        then
            exit;

        // if no filters have been set, something is wrong.
        if (RecRef.GetFilters() = '') or (not RecRef.MarkedOnly()) then
            RetentionPolicyLog.LogError(LogCategory(), StrSubstNo(NoFiltersErr, RecRef.Number, RecRef.Name));

        // delete all remaining records
        RecRef.DeleteAll(true);

        // set handled
        Handled := true;
    end;

    local procedure LogCategory(): Enum "Retention Policy Log Category"
    var
        RetentionPolicyLogCategory: Enum "Retention Policy Log Category";
    begin
        exit(RetentionPolicyLogCategory::"Retention Policy - Apply");
    end;
}