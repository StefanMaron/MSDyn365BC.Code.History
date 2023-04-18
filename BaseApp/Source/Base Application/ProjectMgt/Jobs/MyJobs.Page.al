page 9154 "My Jobs"
{
    Caption = 'My Jobs';
    PageType = ListPart;
    SourceTable = "My Job";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the job numbers that are displayed in the My Job Cue on the Role Center.';

                    trigger OnValidate()
                    begin
                        GetJob();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Jobs;
                    Enabled = false;
                    ToolTip = 'Specifies a description of the job.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Jobs;
                    Editable = false;
                    ToolTip = 'Specifies the job''s status.';
                }
                field("Bill-to Name"; Rec."Bill-to Name")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the name of the customer that you send or sent the invoice or credit memo to.';
                }
                field("Percent Completed"; Rec."Percent Completed")
                {
                    ApplicationArea = Jobs;
                    Editable = false;
                    ToolTip = 'Specifies the completion rate of the job.';
                }
                field("Percent Invoiced"; Rec."Percent Invoiced")
                {
                    ApplicationArea = Jobs;
                    Editable = false;
                    ToolTip = 'Specifies how much of the job has been invoiced.';
                }
                field("Exclude from Business Chart"; Rec."Exclude from Business Chart")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies if this job should appear in the business charts for this role center.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Open)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Open';
                Image = ViewDetails;
                RunObject = Page "Job Card";
                RunPageLink = "No." = FIELD("Job No.");
                RunPageMode = View;
                ShortCutKey = 'Return';
                ToolTip = 'Open the card for the selected record.';
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        GetJob();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(Job);
    end;

    trigger OnOpenPage()
    begin
        SetRange("User ID", UserId);
    end;

    var
        Job: Record Job;

    local procedure GetJob()
    begin
        Clear(Job);

        if Job.Get("Job No.") then begin
            Description := Job.Description;
            Status := Job.Status;
            "Bill-to Name" := Job."Bill-to Name";
            "Percent Completed" := Job.PercentCompleted();
            "Percent Invoiced" := Job.PercentInvoiced();
        end;

        OnAfterGetJob(Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetJob(var MyJob: Record "My Job")
    begin
    end;
}

