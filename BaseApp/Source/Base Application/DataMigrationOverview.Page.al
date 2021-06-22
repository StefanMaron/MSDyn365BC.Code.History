page 1799 "Data Migration Overview"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Data Migration Overview';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "Data Migration Status";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field("Migration Type"; "Migration Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of data migration.';
                    Visible = false;
                }
                field(TableNameToMigrate; TableNameToMigrate)
                {
                    ApplicationArea = All;
                    Caption = 'Table Name';
                    ToolTip = 'Specifies the Table Name';
                }
                field("Migrated Number"; "Migrated Number")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of records that were migrated.';
                }
                field("Total Number"; "Total Number")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total number of records that were migrated.';

                    trigger OnDrillDown()
                    begin
                        DataMigrationFacade.OnSelectRowFromDashboard(Rec);
                    end;
                }
                field("Progress Percent"; "Progress Percent")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the progress of the data migration.';
                }
                field(Status; Status)
                {
                    ApplicationArea = All;
                    StyleExpr = StatusStyle;
                    ToolTip = 'Specifies the status of the data migration.';

                    trigger OnDrillDown()
                    var
                        JobQueueLogEntry: Record "Job Queue Log Entry";
                    begin
                        if Status = Status::Failed then begin
                            JobQueueLogEntry.SetRange("Object ID to Run", CODEUNIT::"Data Migration Mgt.");
                            JobQueueLogEntry.SetRange("Object Type to Run", JobQueueLogEntry."Object Type to Run"::Codeunit);
                            PAGE.Run(PAGE::"Job Queue Log Entries", JobQueueLogEntry);
                        end else
                            if Status = Status::"Completed with Errors" then
                                ShowErrors;
                    end;
                }
                field("Next Task"; NextTask)
                {
                    ApplicationArea = All;
                    Caption = 'Next Task';
                    ToolTip = 'Specifies the next task that is needed to complete the migration.';

                    trigger OnDrillDown()
                    begin
                        case NextTask of
                            NextTask::"Review and fix errors":
                                ShowErrors;
                            NextTask::"Review and post",
                          NextTask::"Review and Delete":
                                case "Destination Table ID" of
                                    DATABASE::Vendor:
                                        GoToGeneralJournalForVendors;
                                    DATABASE::Customer:
                                        GoToGeneralJournalForCustomers;
                                    DATABASE::Item:
                                        GoToItemJournal;
                                    else
                                        GoToGeneralJournalForAccounts;
                                end;
                        end;
                    end;
                }
                field("Error Count"; "Error Count")
                {
                    ApplicationArea = All;
                    StyleExpr = ErrorStyle;
                    ToolTip = 'Specifies how many records could not be migrated because of an error.';

                    trigger OnDrillDown()
                    begin
                        if "Error Count" = 0 then
                            exit;
                        ShowErrors;
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Refresh)
            {
                ApplicationArea = All;
                Caption = 'Refresh';
                Image = Refresh;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                //The property 'ToolTip' cannot be empty.
                //ToolTip = '';

                trigger OnAction()
                begin
                    CurrPage.Update;
                    ShowNotifications;
                end;
            }
            action("Stop Data Migration")
            {
                ApplicationArea = All;
                Caption = 'Stop All Migrations';
                Image = Stop;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Stop all data migrations that are in progress or pending.';

                trigger OnAction()
                var
                    DataMigrationStatus: Record "Data Migration Status";
                    DataMigrationMgt: Codeunit "Data Migration Mgt.";
                begin
                    OnRequestAbort;
                    DataMigrationStatus.SetFilter(
                      Status, '%1|%2', DataMigrationStatus.Status::"In Progress", DataMigrationStatus.Status::Pending);
                    if DataMigrationStatus.FindFirst then
                        DataMigrationMgt.SetAbortStatus(DataMigrationStatus);
                end;
            }
        }
        area(navigation)
        {
            action("Show Errors")
            {
                ApplicationArea = All;
                Caption = 'Show Errors';
                Image = ErrorLog;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Show the errors that occurred during migration.';

                trigger OnAction()
                begin
                    ShowErrors;
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        AllObjWithCaption: Record AllObjWithCaption;
        DataMigrationMgt: Codeunit "Data Migration Mgt.";
        DummyCode: Code[10];
    begin
        NextTask := NextTask::" ";
        ErrorStyle := 'Standard';

        DataMigrationMgt.UpdateMigrationStatus(Rec);

        case Status of
            Status::Completed:
                begin
                    StatusStyle := 'Favorable'; // bold green
                    if DataMigrationMgt.DestTableHasAnyTransactions(Rec, DummyCode) then
                        NextTask := NextTask::"Review and post";
                end;
            Status::"Completed with Errors":
                begin
                    NextTask := NextTask::"Review and fix errors";
                    StatusStyle := 'Attention';
                end;
            Status::Stopped,
            Status::Failed:
                begin
                    StatusStyle := 'Attention'; // red
                    if DataMigrationMgt.DestTableHasAnyTransactions(Rec, DummyCode) then
                        NextTask := NextTask::"Review and Delete";
                end;
            Status::"In Progress":
                StatusStyle := 'StandardAccent'; // blue
            Status::Pending:
                StatusStyle := 'Standard'; // black
        end;

        CalcFields("Error Count");
        if "Error Count" = 0 then
            ErrorStyle := 'Subordinate';

        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
        AllObjWithCaption.SetRange("Object ID", "Destination Table ID");
        if AllObjWithCaption.FindFirst then
            TableNameToMigrate := AllObjWithCaption."Object Caption";
    end;

    trigger OnOpenPage()
    begin
        ShowNotifications;
    end;

    var
        DataMigrationFacade: Codeunit "Data Migration Facade";
        RefreshNotification: Notification;
        [InDataSet]
        StatusStyle: Text;
        [InDataSet]
        TableNameToMigrate: Text[250];
        DashboardEmptyNotificationMsg: Label 'This page shows the status of a data migration. It''s empty because you have not migrated data.';
        StartDataMigrationMsg: Label 'Start data migration';
        RefreshNotificationMsg: Label 'Data migration is in progress. Refresh the page to update the migration status.';
        RefreshNotificationShown: Boolean;
        LearnMoreTxt: Label 'Learn more';
        NextTask: Option " ","Review and fix errors","Review and post","Review and Delete";
        ErrorStyle: Text;

    [IntegrationEvent(false, false)]
    local procedure OnRequestAbort()
    begin
    end;

    local procedure ShowErrors()
    var
        DataMigrationError: Record "Data Migration Error";
    begin
        DataMigrationError.SetRange("Migration Type", "Migration Type");
        DataMigrationError.SetRange("Destination Table ID", "Destination Table ID");
        if DataMigrationError.FindFirst then begin
            PAGE.RunModal(PAGE::"Data Migration Error", DataMigrationError);
            CurrPage.Update;
        end;
    end;

    local procedure ShowNotifications()
    begin
        if ShowDashboardEmptyNotification then
            exit;

        ShowRefreshNotification;
    end;

    local procedure ShowDashboardEmptyNotification() NotificationShown: Boolean
    var
        DataMigrationStatus: Record "Data Migration Status";
        DashboardEmptyNotification: Notification;
    begin
        if not DataMigrationStatus.IsEmpty then
            exit;

        DashboardEmptyNotification.Message(DashboardEmptyNotificationMsg);
        DashboardEmptyNotification.AddAction(
          StartDataMigrationMsg, CODEUNIT::"Data Migration Mgt.", 'StartDataMigrationWizardFromNotification');
        DashboardEmptyNotification.AddAction(LearnMoreTxt, CODEUNIT::"Data Migration Mgt.", 'ShowHelpTopicPage');
        DashboardEmptyNotification.Send;
        NotificationShown := true;
    end;

    local procedure ShowRefreshNotification() NotificationShown: Boolean
    var
        DataMigrationMgt: Codeunit "Data Migration Mgt.";
    begin
        if not DataMigrationMgt.IsMigrationInProgress then begin
            if RefreshNotificationShown then
                RefreshNotification.Recall;
            exit;
        end;

        if RefreshNotificationShown then
            exit;

        RefreshNotification.Message(RefreshNotificationMsg);
        RefreshNotification.Send;
        NotificationShown := true;
        RefreshNotificationShown := true;
    end;

    procedure GoToItemJournal()
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatchName: Code[10];
    begin
        DataMigrationFacade.OnFindBatchForItemTransactions("Migration Type", ItemJournalBatchName);
        if ItemJournalBatchName <> '' then begin
            ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatchName);
            if ItemJournalLine.FindFirst then begin
                ItemJournalLine.SetRange("Journal Template Name", ItemJournalLine."Journal Template Name");
                PAGE.Run(PAGE::"Item Journal", ItemJournalLine);
                exit;
            end;
        end;
        PAGE.Run(PAGE::"Item Journal");
    end;

    procedure GoToGeneralJournalForCustomers()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatchName: Code[10];
    begin
        DataMigrationFacade.OnFindBatchForCustomerTransactions("Migration Type", GenJournalBatchName);
        if GenJournalBatchName <> '' then begin
            GenJournalLine.SetRange("Journal Batch Name", GenJournalBatchName);
            if GenJournalLine.FindFirst then begin
                GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
                GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::Customer);
                PAGE.Run(PAGE::"General Journal", GenJournalLine);
                exit;
            end;
        end;
        PAGE.Run(PAGE::"General Journal");
    end;

    procedure GoToGeneralJournalForVendors()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatchName: Code[10];
    begin
        DataMigrationFacade.OnFindBatchForVendorTransactions("Migration Type", GenJournalBatchName);
        if GenJournalBatchName <> '' then begin
            GenJournalLine.SetRange("Journal Batch Name", GenJournalBatchName);
            if GenJournalLine.FindFirst then begin
                GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
                GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::Vendor);
                PAGE.Run(PAGE::"General Journal", GenJournalLine);
                exit;
            end;
        end;
        PAGE.Run(PAGE::"General Journal");
    end;

    local procedure GoToGeneralJournalForAccounts()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatchName: Code[10];
    begin
        DataMigrationFacade.OnFindBatchForAccountTransactions(Rec, GenJournalBatchName);
        if GenJournalBatchName <> '' then begin
            GenJournalLine.SetRange("Journal Batch Name", GenJournalBatchName);
            if GenJournalLine.FindFirst then begin
                GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
                GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::"G/L Account");
                PAGE.Run(PAGE::"General Journal", GenJournalLine);
                exit;
            end;
        end;
        PAGE.Run(PAGE::"General Journal");
    end;
}

