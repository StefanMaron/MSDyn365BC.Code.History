report 1093 "Job Create Sales Invoice"
{
    ApplicationArea = Jobs;
    Caption = 'Job Create Sales Invoice';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Job Task"; "Job Task")
        {
            DataItemTableView = SORTING("Job No.", "Job Task No.");
            RequestFilterFields = "Job No.", "Job Task No.", "Planning Date Filter";

            trigger OnAfterGetRecord()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeJobTaskOnAfterGetRecord("Job Task", IsHandled);
                if not IsHandled then
                    JobCreateInvoice.CreateSalesInvoiceJobTask(
                      "Job Task", PostingDate, InvoicePerTask, NoOfInvoices, OldJobNo, OldJTNo, false);
            end;

            trigger OnPostDataItem()
            begin
                JobCreateInvoice.CreateSalesInvoiceJobTask(
                  "Job Task", PostingDate, InvoicePerTask, NoOfInvoices, OldJobNo, OldJTNo, true);
            end;

            trigger OnPreDataItem()
            begin
                NoOfInvoices := 0;
                OldJobNo := '';
                OldJTNo := '';
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(PostingDate; PostingDate)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the posting date for the document.';
                    }
                    field(JobChoice; JobChoice)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Create Invoice per';
                        OptionCaption = 'Job,Job Task';
                        ToolTip = 'Specifies, if you select the Job Task option, that you want to create one invoice per job task rather than the one invoice per job that is created by default.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            PostingDate := WorkDate();
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        OnBeforeOnOnInitReport(JobChoice);
    end;

    trigger OnPostReport()
    begin
        OnBeforePostReport();

        JobCalcBatches.EndCreateInvoice(NoOfInvoices);

        OnAfterPostReport(NoOfInvoices);
    end;

    trigger OnPreReport()
    begin
        JobCalcBatches.BatchError(PostingDate, Text000);
        InvoicePerTask := JobChoice = JobChoice::"Job Task";
        JobCreateInvoice.DeleteSalesInvoiceBuffer();

        OnAfterPreReport();
    end;

    var
        JobCreateInvoice: Codeunit "Job Create-Invoice";
        JobCalcBatches: Codeunit "Job Calculate Batches";
        NoOfInvoices: Integer;
        InvoicePerTask: Boolean;
        OldJobNo: Code[20];
        OldJTNo: Code[20];
        Text000: Label 'A', Comment = 'A';

    protected var
        JobChoice: Option Job,"Job Task";
        PostingDate: Date;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostReport(NoOfInvoices: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPreReport()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnOnInitReport(var JobChoice: Option Job,"Job Task")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeJobTaskOnAfterGetRecord(JobTask: Record "Job Task"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostReport()
    begin
    end;
}

