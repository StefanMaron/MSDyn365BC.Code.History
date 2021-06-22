page 5371 "CRM Synch. Job Status Part"
{
    Caption = 'Microsoft Dynamics 365 Sales Synch. Job Status';
    PageType = CardPart;
    SourceTable = "CRM Synch. Job Status Cue";

    layout
    {
        area(content)
        {
            cuegroup(Control1)
            {
                ShowCaption = false;
                field("Failed Synch. Jobs"; "Failed Synch. Jobs")
                {
                    ApplicationArea = Suite;
                    DrillDownPageID = "CRM Synch. Job Queue";
                    Image = Checklist;
                    ToolTip = 'Specifies the number of failed Dynamics 365 Sales synchronization jobs in the job queue.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Edit Job Queue Entries")
            {
                ApplicationArea = Suite;
                Caption = 'Edit Job Queue Entries';
                Image = ViewDetails;
                RunObject = Page "Job Queue Entries";
                RunPageView = WHERE("Object ID to Run" = CONST(5339));
                ToolTip = 'Change the settings for the job queue entry.';
            }
            action("<Page CRM Connection Setup>")
            {
                ApplicationArea = Suite;
                Caption = 'Microsoft Dynamics 365 Connection Setup';
                Image = Setup;
                RunObject = Page "CRM Connection Setup";
                ToolTip = 'Specifies information related to the Dynamics 365 Sales connection. ';
            }
            action(Reset)
            {
                ApplicationArea = Suite;
                Caption = 'Reset';
                Image = Cancel;
                ToolTip = 'Reset the synchronization status.';

                trigger OnAction()
                begin
                    CRMSynchJobManagement.OnReset(Rec);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        CRMSynchJobManagement.SetInitialState(Rec);
    end;

    var
        CRMSynchJobManagement: Codeunit "CRM Synch. Job Management";
}

