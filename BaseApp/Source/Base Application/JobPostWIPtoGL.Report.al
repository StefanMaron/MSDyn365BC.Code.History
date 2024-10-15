report 1085 "Job Post WIP to G/L"
{
    AdditionalSearchTerms = 'posted work in process to general ledger,posted work in progress to general ledger';
    ApplicationArea = Jobs;
    Caption = 'Job Post WIP to G/L';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem(Job; Job)
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.";

            trigger OnAfterGetRecord()
            begin
                JobCalculateWIP.CalcGLWIP("No.", JustReverse, DocNo, PostingDate, ReplacePostDate,
                  GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name");
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
                    field(ReversalPostingDate; PostingDate)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Reversal Posting Date';
                        ToolTip = 'Specifies the posting date for the general ledger entries that are posted by this function.';
                    }
                    field(ReversalDocumentNo; DocNo)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Reversal Document No.';
                        ToolTip = 'Specifies a document number for the general ledger entries that are posted by this function.';
                    }
                    field(ReverseOnly; JustReverse)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Reverse Only';
                        ToolTip = 'Specifies that you want to reverse previously posted WIP, but not to post new WIP to the general ledger. This is useful, for example, when you have calculated and posted WIP for a job with an incorrect date and want to reverse the incorrect postings without posting new WIP entries.';
                    }
                    field(UseReversalDate; ReplacePostDate)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Use Reversal Date';
                        ToolTip = 'Specifies if you want to use the reversal date as the posting date for both the reversal of the previous WIP calculation and the posting date for the new WIP calculation. This is useful when you want to calculate and post the historical WIP for a period that is already closed. You can reverse the old postings and post the new calculation in an open period by choosing a reversal date in the open period.';
                    }
                    field(JnlTemplateName; GenJnlLine."Journal Template Name")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Journal Template Name';
                        TableRelation = "Gen. Journal Template";
                        ToolTip = 'Specifies the name of the journal template that is used for the posting.';

                        trigger OnValidate()
                        begin
                            GenJnlLine."Journal Batch Name" := '';
                        end;
                    }
                    field(JnlBatchName; GenJnlLine."Journal Batch Name")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Journal Batch Name';
                        ToolTip = 'Specifies the name of the journal batch that is used for the posting.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            GenJnlLine.TestField("Journal Template Name");
                            GenJnlTemplate.Get(GenJnlLine."Journal Template Name");
                            GenJnlBatch.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
                            GenJnlBatch."Journal Template Name" := GenJnlLine."Journal Template Name";
                            GenJnlBatch.Name := GenJnlLine."Journal Batch Name";
                            if PAGE.RunModal(0, GenJnlBatch) = ACTION::LookupOK then
                                GenJnlLine."Journal Batch Name" := GenJnlBatch.Name;
                        end;

                        trigger OnValidate()
                        begin
                            if GenJnlLine."Journal Batch Name" <> '' then begin
                                GenJnlLine.TestField("Journal Template Name");
                                GenJnlBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name");
                            end;
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        var
            NewNoSeriesCode: Code[20];
        begin
            if PostingDate = 0D then
                PostingDate := WorkDate;
            DocNo := '';

            JobsSetup.Get();

            JobsSetup.TestField("Job Nos.");
            NoSeriesMgt.InitSeries(JobsSetup."Job WIP Nos.", JobsSetup."Job WIP Nos.", 0D, DocNo, NewNoSeriesCode);

            ReplacePostDate := false;
            JustReverse := false;
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        Commit();
        Message(WIPSuccessfullyPostedMsg);
    end;

    trigger OnPreReport()
    var
        NewNoSeriesCode: Code[20];
    begin
        JobsSetup.Get();

        if DocNo = '' then begin
            JobsSetup.TestField("Job Nos.");
            NoSeriesMgt.InitSeries(JobsSetup."Job WIP Nos.", JobsSetup."Job WIP Nos.", 0D, DocNo, NewNoSeriesCode);
        end;

        if PostingDate = 0D then
            PostingDate := WorkDate;

        if GenJnlLine."Journal Template Name" = '' then
            Error(Text11300, GenJnlLine.FieldCaption("Journal Template Name"));
        if GenJnlLine."Journal Batch Name" = '' then
            Error(Text11300, GenJnlLine.FieldCaption("Journal Batch Name"));
        GenJnlBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name");
        GenJnlBatch.TestField("No. Series");
        DocNo := NoSeriesMgt.GetNextNo(GenJnlBatch."No. Series", PostingDate, true);
        JobCalculateBatches.BatchError(PostingDate, DocNo);
    end;

    var
        JobsSetup: Record "Jobs Setup";
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        JobCalculateWIP: Codeunit "Job Calculate WIP";
        JobCalculateBatches: Codeunit "Job Calculate Batches";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        PostingDate: Date;
        DocNo: Code[20];
        JustReverse: Boolean;
        WIPSuccessfullyPostedMsg: Label 'WIP was successfully posted to G/L.';
        ReplacePostDate: Boolean;
        Text11300: Label 'You must specify %1.';

    procedure InitializeRequest(NewDocNo: Code[20])
    begin
        DocNo := NewDocNo;
        PostingDate := WorkDate
    end;
}

