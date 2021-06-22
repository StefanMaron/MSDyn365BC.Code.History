page 5338 "Integration Synch. Job List"
{
    ApplicationArea = Suite;
    Caption = 'Integration Synchronization Jobs';
    DataCaptionExpression = "Integration Table Mapping Name";
    DeleteAllowed = true;
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Integration Synch. Job";
    SourceTableView = SORTING("Start Date/Time", ID)
                      ORDER(Descending);
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Start Date/Time"; "Start Date/Time")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the data and time that the integration synchronization job started.';
                }
                field("Finish Date/Time"; "Finish Date/Time")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date and time that the integration synchronization job completed.';
                }
                field(Duration; Duration)
                {
                    ApplicationArea = Suite;
                    Caption = 'Duration';
                    HideValue = DoHideDuration;
                    ToolTip = 'Specifies how long the data synchronization has taken.';
                }
                field("Integration Table Mapping Name"; "Integration Table Mapping Name")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the name of the table mapping that was used for the integration synchronization job.';
                    Visible = false;
                }
                field(Inserted; Inserted)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of new records that were created in the destination database table (such as the Dynamics 365 Sales Account entity or Business Central Customer table) by the integration synchronization job.';
                }
                field(Modified; Modified)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of records that were modified in the destination database table (such as the Dynamics 365 Sales Account entity or Dynamics 365 Customer table) by the integration synchronization job.';
                }
                field(Deleted; Deleted)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies entries that were deleted when synchronizing Dynamics 365 Sales data and Dynamics 365 data.';
                }
                field(Unchanged; Unchanged)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of records that were not changed in the destination database table (such as the Dynamics 365 Sales Account entity or Dynamics 365 Customer table) by the integration synchronization job.';
                }
                field(Failed; Failed)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of errors that occurred during the integration synchronization job.';

                    trigger OnDrillDown()
                    var
                        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
                    begin
                        IntegrationSynchJobErrors.SetCurrentKey("Date/Time", "Integration Synch. Job ID");
                        IntegrationSynchJobErrors.Ascending := false;

                        IntegrationSynchJobErrors.FilterGroup(2);
                        IntegrationSynchJobErrors.SetRange("Integration Synch. Job ID", ID);
                        IntegrationSynchJobErrors.FilterGroup(0);

                        IntegrationSynchJobErrors.FindFirst;
                        PAGE.Run(PAGE::"Integration Synch. Error List", IntegrationSynchJobErrors);
                    end;
                }
                field(Skipped; Skipped)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of records that were skipped during the integration synchronization job.';
                }
                field(Direction; SynchDirection)
                {
                    ApplicationArea = Suite;
                    Caption = 'Direction';
                    ToolTip = 'Specifies in which direction data is synchronized.';
                }
                field(Message; Message)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a message that occurred as a result of the integration synchronization job.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action(Delete7days)
            {
                ApplicationArea = Suite;
                Caption = 'Delete Entries Older Than 7 Days';
                Enabled = HasRecords;
                Image = ClearLog;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Delete log information for job queue entries that are older than seven days.';

                trigger OnAction()
                begin
                    DeleteEntries(7);
                end;
            }
            action(Delete0days)
            {
                ApplicationArea = Suite;
                Caption = 'Delete All Entries';
                Enabled = HasRecords;
                Image = Delete;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Delete all error log information for job queue entries.';

                trigger OnAction()
                begin
                    DeleteEntries(0);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        TableMetadata: Record "Table Metadata";
    begin
        if IntegrationTableMapping.Get("Integration Table Mapping Name") then begin
            TableMetadata.Get(IntegrationTableMapping."Table ID");
            if "Synch. Direction" = "Synch. Direction"::ToIntegrationTable then
                SynchDirection :=
                  StrSubstNo(SynchDirectionTxt, TableMetadata.Caption, IntegrationTableMapping.GetExtendedIntegrationTableCaption)
            else
                SynchDirection :=
                  StrSubstNo(SynchDirectionTxt, IntegrationTableMapping.GetExtendedIntegrationTableCaption, TableMetadata.Caption);
        end;
        DoHideDuration := "Finish Date/Time" < "Start Date/Time";
        if DoHideDuration then
            Clear(Duration)
        else
            Duration := "Finish Date/Time" - "Start Date/Time";

        HasRecords := not IsEmpty;
    end;

    var
        SynchDirectionTxt: Label '%1 to %2.', Comment = '%1 = Source table caption, %2 = Destination table caption';
        SynchDirection: Text;
        DoHideDuration: Boolean;
        Duration: Duration;
        HasRecords: Boolean;
}

