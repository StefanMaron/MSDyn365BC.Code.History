page 5515 "Integration Management Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Integration Management Setup';
    DelayedInsert = true;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Integration Management Setup";
    UsageCategory = Administration;
    ObsoleteState = Pending;
    ObsoleteReason = 'The page will be removed with Integration Management. Refactor to use systemID, systemLastModifiedAt and other system fields.';
    ObsoleteTag = '17.0';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Table No."; Rec."Table ID")
                {
                    ApplicationArea = All;
                    Caption = 'Table ID';
                    Editable = false;
                    Tooltip = 'Specifies the ID of the table.';
                }
                field("Table Caption"; Rec."Table Caption")
                {
                    ApplicationArea = All;
                    Caption = 'Table Caption';
                    Editable = false;
                    Tooltip = 'Specifies the caption of the table.';
                }
                field("Enabled"; Rec."Enabled")
                {
                    ApplicationArea = All;
                    Caption = 'Enabled';
                    Tooltip = 'Specifies if the records should be generated for this table.';
                }
                field("Completed"; Rec."Completed")
                {
                    ApplicationArea = All;
                    Caption = 'Completed';
                    Editable = false;
                    Tooltip = 'Specifies if the setup is complete for this table.';
                }

                field("Last DateTime Modified"; Rec."Last DateTime Modified")
                {
                    ApplicationArea = All;
                    Caption = 'Last DateTime Modified';
                    Editable = false;
                    Tooltip = 'Specifies the last date and time that the record was modified. The setup will use this date as the first date for other records.';
                }

                field("Batch Size"; Rec."Batch Size")
                {
                    ApplicationArea = All;
                    Caption = 'Number of records in batch';
                    Editable = false;
                    Tooltip = 'Specifies the number of records to include in each commit to the database. We recommend that you use the default value if possible.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(SetupIntegrationManagement)
            {
                ApplicationArea = All;
                Caption = 'Schedule Job';
                Image = Setup;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'Schedules generation of Integration Records.';

                trigger OnAction()
                var
                    JobQueueEntry: Record "Job Queue Entry";
                    IntegrationManagementSetup: Codeunit "Integration Management Setup";
                begin
                    IntegrationManagementSetup.ScheduleJob(JobQueueEntry);
                    if Confirm(JobQEntriesCreatedQst) then begin
                        PAGE.Run(PAGE::"Job Queue Entry Card", JobQueueEntry);
                        exit;
                    end;

                    if Confirm(StartJobQueueNowQst) then begin
                        CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry);
                        Message(JobQueueHasBeenStartedMsg);
                        exit;
                    end;

                    Message(JobQueueNotScheudledMsg);
                end;
            }

            action(ResetIntegrationTables)
            {
                ApplicationArea = All;
                Caption = 'Reset Setup';
                Image = Restore;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                ToolTip = 'Resets the data on this page to default.';

                trigger OnAction()
                var
                    IntegrationManagementSetup: Codeunit "Integration Management Setup";
                begin
                    if not Rec.IsEmpty() then
                        if not Confirm(ResetIntegrationTablesQst) then
                            exit;

                    Rec.DeleteAll();
                    IntegrationManagementSetup.InsertIntegrationTables(Rec);
                end;
            }

            action(EnableAll)
            {
                ApplicationArea = All;
                Caption = 'Enable all';
                Image = EnableAllBreakpoints;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                ToolTip = 'Enables all tables.';

                trigger OnAction()
                begin
                    Rec.ModifyAll(Enabled, true);
                end;
            }

            action(DisableAll)
            {
                ApplicationArea = All;
                Caption = 'Disable all';
                Image = DisableAllBreakpoints;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                ToolTip = 'Disables all tables.';

                trigger OnAction()
                begin
                    Rec.ModifyAll(Enabled, false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        UpdatePopulateIntegrationTablesNotification();
    end;

    local procedure UpdatePopulateIntegrationTablesNotification()
    var
        IntegrationManagementSetup: Codeunit "Integration Management Setup";
        LinesForReviewNotification: Notification;
    begin
        LinesForReviewNotification.Id := IntegrationManagementSetup.GetPopulateIntegrationTablesNotificationId();
        LinesForReviewNotification.Recall();

        if (not Rec.IsEmpty()) then
            exit;

        LinesForReviewNotification.Message := ResetIntegrationTablesMsg;
        LinesForReviewNotification.Scope := NotificationScope::LocalScope;
        LinesForReviewNotification.AddAction(InsertRecordsMsg, CODEUNIT::"Integration Management Setup", 'InsertIntegrationTables');
        LinesForReviewNotification.Send();
    end;

    var
        JobQEntriesCreatedQst: Label 'A job queue entry for generating integraiton records has been created.\\ The process may take several hours to complete. We recommend that you schedule the job for a time slot outside your organization''s working hours. \\Do you want to open the Job Queue Entries and configure the Job Queue?';
        StartJobQueueNowQst: Label 'Would you like to run the job to generate the integration records now?';
        JobQueueHasBeenStartedMsg: Label 'The job queue entry will start executing shortly.';
        JobQueueNotScheudledMsg: Label 'The job is created and set to on hold.';
        ResetIntegrationTablesQst: Label 'Are you sure that you want to reset the setup?';
        ResetIntegrationTablesMsg: Label 'There are not records specifed.';
        InsertRecordsMsg: Label 'Insert default';
}