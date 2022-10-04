report 1090 "Job Calc. Remaining Usage"
{
    Caption = 'Job Calc. Remaining Usage';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Job Task"; "Job Task")
        {
            DataItemTableView = SORTING("Job No.", "Job Task No.");
            RequestFilterFields = "Job No.", "Job Task No.";
            dataitem("Job Planning Line"; "Job Planning Line")
            {
                DataItemLink = "Job No." = FIELD("Job No."), "Job Task No." = FIELD("Job Task No.");
                DataItemTableView = SORTING("Job No.", "Job Task No.", "Line No.");
                RequestFilterFields = Type, "No.", "Planning Date", "Currency Date", "Location Code", "Variant Code", "Work Type Code";

                trigger OnAfterGetRecord()
                begin
                    if ("Job No." <> '') and ("Job Task No." <> '') then
                        JobCalcBatches.CreateJT("Job Planning Line");
                end;
            }
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(DocumentNo; DocNo)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Document No.';
                        ToolTip = 'Specifies the number of a document that the calculation will apply to.';
                    }
                    field(PostingDate; PostingDate)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the posting date for the document.';
                    }
                    field(TemplateName; TemplateName)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Template Name';
                        Editable = false;
                        Lookup = false;
                        TableRelation = "Gen. Journal Template";
                        ToolTip = 'Specifies the template name of the job journal where the remaining usage is inserted as lines.';

                        trigger OnValidate()
                        begin
                            if TemplateName = '' then begin
                                BatchName := '';
                                exit;
                            end;
                            GenJnlTemplate.Get(TemplateName);
                            if GenJnlTemplate.Type <> GenJnlTemplate.Type::Jobs then begin
                                GenJnlTemplate.Type := GenJnlTemplate.Type::Jobs;
                                Error(Text001,
                                  GenJnlTemplate.TableCaption(), GenJnlTemplate.FieldCaption(Type), GenJnlTemplate.Type);
                            end;
                        end;
                    }
                    field(BatchName; BatchName)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Batch Name';
                        Editable = false;
                        Lookup = false;
                        ToolTip = 'Specifies the name of the journal batch, a personalized journal layout, that the journal is based on.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            if TemplateName = '' then
                                Error(Text000, JobJnlLine.FieldCaption("Journal Template Name"));
                            JobJnlLine."Journal Template Name" := TemplateName;
                            JobJnlLine.FilterGroup := 2;
                            JobJnlLine.SetRange("Journal Template Name", TemplateName);
                            JobJnlLine.SetRange("Journal Batch Name", BatchName);
                            JobJnlManagement.LookupName(BatchName, JobJnlLine);
                            JobJnlManagement.CheckName(BatchName, JobJnlLine);
                        end;

                        trigger OnValidate()
                        begin
                            JobJnlManagement.CheckName(BatchName, JobJnlLine);
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            TemplateName := TemplateName3;
            BatchName := BatchName3;
            DocNo := DocNo2;
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        JobCalcBatches.PostDiffBuffer(DocNo, PostingDate, TemplateName, BatchName);
    end;

    trigger OnPreReport()
    begin
        JobCalcBatches.BatchError(PostingDate, DocNo);
        JobCalcBatches.InitDiffBuffer();
    end;

    var
        GenJnlTemplate: Record "Gen. Journal Template";
        JobJnlLine: Record "Job Journal Line";
        JobCalcBatches: Codeunit "Job Calculate Batches";
        JobJnlManagement: Codeunit JobJnlManagement;
        DocNo: Code[20];
        DocNo2: Code[20];
        PostingDate: Date;
        TemplateName: Code[10];
        BatchName: Code[10];
        TemplateName3: Code[10];
        BatchName3: Code[10];
        Text000: Label 'You must specify %1.';
        Text001: Label '%1 %2 must be %3.';

    procedure SetBatch(TemplateName2: Code[10]; BatchName2: Code[10])
    begin
        TemplateName3 := TemplateName2;
        BatchName3 := BatchName2;
    end;

    procedure SetDocNo(InputDocNo: Code[20])
    begin
        DocNo2 := InputDocNo;
    end;
}

