page 1615 "Office Job Journal"
{
    Caption = 'Job Journal';
    DataCaptionExpression = CaptionTxt;
    SourceTable = "Office Job Journal";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            field(Description; JobPlanningLine.Description)
            {
                ApplicationArea = Jobs;
                Editable = false;
                ToolTip = 'Specifies the name of the resource, item, or general ledger account to which this entry applies. You can change the description.';
            }
            field("Document No."; JobPlanningLine."Document No.")
            {
                ApplicationArea = Jobs;
                Editable = false;
                ToolTip = 'Specifies a document number for the journal line.';
            }
            field("Job No."; Rec."Job No.")
            {
                ApplicationArea = Jobs;
                Editable = false;
                ToolTip = 'Specifies the number of the related job.';
            }
            field("Job Task No."; Rec."Job Task No.")
            {
                ApplicationArea = Jobs;
                Editable = false;
                ToolTip = 'Specifies the number of the related job task.';
            }
            field(JobJournalTemplate; "Job Journal Template Name")
            {
                ApplicationArea = Jobs;
                Caption = 'Job Journal Template';
                Editable = TemplateEditable AND IsEditable;
                ToolTip = 'Specifies the journal template that is used for the job journal.';

                trigger OnValidate()
                var
                    JobJournalTemplate: Record "Job Journal Template";
                    JobJournalBatch: Record "Job Journal Batch";
                begin
                    JobJournalTemplate.Get("Job Journal Template Name");
                    FindJobJournalBatch(JobJournalBatch);
                    "Job Journal Batch Name" := '';
                    BatchEditable := false;
                    case JobJournalBatch.Count of
                        0:
                            Error(NoBatchesErr);
                        1:
                            begin
                                JobJournalBatch.FindFirst();
                                "Job Journal Batch Name" := JobJournalBatch.Name;
                            end;
                        else
                            BatchEditable := true;
                    end;
                end;
            }
            field(JobJournalBatch; "Job Journal Batch Name")
            {
                ApplicationArea = Jobs;
                Caption = 'Job Journal Batch';
                Editable = BatchEditable AND IsEditable;
                ToolTip = 'Specifies the journal batch that is used for the job journal.';
            }
            field(Date; JobPlanningLine."Planning Date")
            {
                ApplicationArea = Jobs;
                Caption = 'Date';
                Editable = IsEditable;
                ToolTip = 'Specifies the date of the planning line.';
            }
            field(DisplayQuantity; DisplayQuantity)
            {
                ApplicationArea = Jobs;
                Caption = 'Quantity';
                Editable = IsEditable;
                ToolTip = 'Specifies the quantity you want to transfer to the job journal.';
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Submit)
            {
                ApplicationArea = Jobs;
                Caption = 'Submit';
                Image = CompleteLine;
                ToolTip = 'Submit the quantity for this completed planning line.';
                Visible = IsEditable;

                trigger OnAction()
                var
                    OfficeJobsHandler: Codeunit "Office Jobs Handler";
                begin
                    JobPlanningLine."Qty. to Transfer to Journal" := DisplayQuantity;
                    OfficeJobsHandler.SubmitJobPlanningLine(JobPlanningLine, "Job Journal Template Name", "Job Journal Batch Name");
                    CurrPage.Close();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Submit_Promoted; Submit)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        JobJournalLine: Record "Job Journal Line";
        JobUsageLink: Record "Job Usage Link";
        JobJournalTemplate: Record "Job Journal Template";
        JobJournalBatch: Record "Job Journal Batch";
        OfficeJobsHandler: Codeunit "Office Jobs Handler";
    begin
        TemplateEditable := true;

        JobUsageLink.SetRange("Job No.", "Job No.");
        JobUsageLink.SetRange("Job Task No.", "Job Task No.");
        JobUsageLink.SetRange("Line No.", "Job Planning Line No.");

        JobPlanningLine.Get("Job No.", "Job Task No.", "Job Planning Line No.");
        OfficeJobsHandler.SetJobJournalRange(JobJournalLine, JobPlanningLine);

        if JobJournalLine.IsEmpty() and JobUsageLink.IsEmpty() then begin
            IsEditable := true;
            CaptionTxt := EnterJobInfoTxt;
            DisplayQuantity := JobPlanningLine.Quantity;

            JobJournalTemplate.SetRange("Page ID", PAGE::"Job Journal");
            JobJournalTemplate.SetRange(Recurring, false);

            if JobJournalTemplate.Count = 1 then begin
                TemplateEditable := false;
                JobJournalTemplate.FindFirst();
                "Job Journal Template Name" := JobJournalTemplate.Name;
                FindJobJournalBatch(JobJournalBatch);
                if JobJournalBatch.Count = 1 then begin
                    JobJournalBatch.FindFirst();
                    "Job Journal Batch Name" := JobJournalBatch.Name;
                end else
                    BatchEditable := true;
            end;
        end else begin
            CaptionTxt := JobCompletedTxt;
            if not JobUsageLink.IsEmpty() then
                DisplayQuantity := JobPlanningLine."Qty. Posted"
            else begin
                JobJournalLine.FindFirst();
                DisplayQuantity := JobJournalLine.Quantity;
                "Job Journal Template Name" := JobJournalLine."Journal Template Name";
                "Job Journal Batch Name" := JobJournalLine."Journal Batch Name";
            end;
        end;

        CurrPage.Editable(IsEditable);
        CurrPage.Update(true);
    end;

    var
        JobPlanningLine: Record "Job Planning Line";
        DisplayQuantity: Decimal;
        IsEditable: Boolean;
        TemplateEditable: Boolean;
        BatchEditable: Boolean;
        CaptionTxt: Text;
        EnterJobInfoTxt: Label 'Enter Job Information';
        JobCompletedTxt: Label 'Job Completed';
        NoBatchesErr: Label 'There are no batches available for the selected template.';

    local procedure FindJobJournalBatch(var JobJournalBatch: Record "Job Journal Batch")
    begin
        JobJournalBatch.SetRange("Journal Template Name", "Job Journal Template Name");
    end;
}

