codeunit 1000 "Job Calculate WIP"
{
    Permissions = TableData "Job Ledger Entry" = rm,
                  TableData "Job Task" = rimd,
                  TableData "Job Planning Line" = r,
                  TableData "Job WIP Entry" = rimd,
                  TableData "Job WIP G/L Entry" = rimd;

    trigger OnRun()
    begin
    end;

    var
        TempJobWIPBuffer: array[2] of Record "Job WIP Buffer" temporary;
        GLSetup: Record "General Ledger Setup";
        GenJnPostLine: Codeunit "Gen. Jnl.-Post Line";
        DimMgt: Codeunit DimensionManagement;
        WIPPostingDate: Date;
        DocNo: Code[20];
        Text001: Label 'WIP %1', Comment = 'WIP GUILDFORD, 10 CR';
        Text002: Label 'Recognition %1', Comment = 'Recognition GUILDFORD, 10 CR';
        Text003: Label 'Completion %1', Comment = 'Completion GUILDFORD, 10 CR';
        JobComplete: Boolean;
        Text004: Label 'WIP G/L entries posted for Job %1 cannot be reversed at an earlier date than %2.';
        Text005: Label '..%1';
        HasGotGLSetup: Boolean;
        JobWIPTotalChanged: Boolean;
        WIPAmount: Decimal;
        RecognizedAllocationPercentage: Decimal;
        CannotModifyAssociatedEntriesErr: Label 'The %1 cannot be modified because the job has associated job WIP entries.', Comment = '%1=The job task table name.';

    procedure JobCalcWIP(var Job: Record Job; WIPPostingDate2: Date; DocNo2: Code[20])
    var
        JobTask: Record "Job Task";
        JobLedgEntry: Record "Job Ledger Entry";
        JobPlanningLine: Record "Job Planning Line";
        JobWIPEntry: Record "Job WIP Entry";
        JobWIPGLEntry: Record "Job WIP G/L Entry";
        FromJobTask: Code[20];
        First: Boolean;
    begin
        ClearAll;
        TempJobWIPBuffer[1].DeleteAll();

        JobPlanningLine.LockTable();
        JobLedgEntry.LockTable();
        JobWIPEntry.LockTable();
        JobTask.LockTable();
        Job.LockTable();

        JobWIPGLEntry.SetCurrentKey("Job No.", Reversed, "Job Complete");
        JobWIPGLEntry.SetRange("Job No.", Job."No.");
        JobWIPGLEntry.SetRange("Job Complete", true);
        if JobWIPGLEntry.FindFirst then begin
            JobWIPEntry.DeleteEntriesForJob(Job);
            exit;
        end;

        if WIPPostingDate2 = 0D then
            WIPPostingDate := WorkDate
        else
            WIPPostingDate := WIPPostingDate2;
        DocNo := DocNo2;

        Job.TestBlocked;
        Job.TestField("WIP Method");
        Job."WIP Posting Date" := WIPPostingDate;
        if (Job."Ending Date" = 0D) and Job.Complete then
            Job.Validate("Ending Date", WIPPostingDate);
        JobComplete := Job.Complete and (WIPPostingDate >= Job."Ending Date");
        Job.Modify();

        DeleteWIP(Job);

        with JobTask do begin
            SetRange("Job No.", Job."No.");
            SetRange("WIP-Total", "WIP-Total"::Total);
            if not FindFirst then begin
                SetFilter("WIP-Total", '<> %1', "WIP-Total"::Excluded);
                if FindLast then begin
                    Validate("WIP-Total", "WIP-Total"::Total);
                    Modify;
                end;
            end;

            SetRange("WIP-Total", "WIP-Total"::Total);
            SetRange("WIP Method", '');
            if FindFirst then
                ModifyAll("WIP Method", Job."WIP Method");

            SetRange("WIP-Total");
            SetRange("WIP Method");
        end;

        First := true;
        if JobTask.Find('-') then
            repeat
                if First then
                    FromJobTask := JobTask."Job Task No.";
                First := false;
                if JobTask."WIP-Total" = JobTask."WIP-Total"::Total then begin
                    JobTaskCalcWIP(Job, FromJobTask, JobTask."Job Task No.");
                    First := true;
                end;
            until JobTask.Next = 0;
        CreateWIPEntries(Job."No.");
    end;

    procedure DeleteWIP(Job: Record Job)
    var
        JobTask: Record "Job Task";
        JobWIPEntry: Record "Job WIP Entry";
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        JobTask.SetRange("Job No.", Job."No.");
        if JobTask.Find('-') then
            repeat
                JobTask.InitWIPFields;
            until JobTask.Next = 0;

        JobWIPEntry.DeleteEntriesForJob(Job);

        JobLedgerEntry.SetRange("Job No.", Job."No.");
        JobLedgerEntry.ModifyAll("Amt. to Post to G/L", 0);
    end;

    local procedure JobTaskCalcWIP(var Job: Record Job; FromJobTask: Code[20]; ToJobTask: Code[20])
    var
        JobTask: Record "Job Task";
        JobWIPTotal: Record "Job WIP Total";
        JobWIPWarning: Record "Job WIP Warning";
    begin
        JobTask.SetRange("Job No.", Job."No.");
        JobTask.SetRange("Job Task No.", FromJobTask, ToJobTask);
        JobTask.SetFilter("WIP-Total", '<> %1', JobTask."WIP-Total"::Excluded);

        if Job.GetFilter("Posting Date Filter") <> '' then
            JobTask.SetFilter("Posting Date Filter", Job.GetFilter("Posting Date Filter"))
        else
            JobTask.SetFilter("Posting Date Filter", StrSubstNo(Text005, WIPPostingDate));

        JobTask.SetFilter("Planning Date Filter", Job.GetFilter("Planning Date Filter"));

        CreateJobWIPTotal(JobTask, JobWIPTotal);

        if JobTask.Find('-') then
            repeat
                if JobTask."Job Task Type" = JobTask."Job Task Type"::Posting then begin
                    JobTask.CalcFields(
                      "Schedule (Total Cost)",
                      "Schedule (Total Price)",
                      "Usage (Total Cost)",
                      "Usage (Total Price)",
                      "Contract (Total Cost)",
                      "Contract (Total Price)",
                      "Contract (Invoiced Price)",
                      "Contract (Invoiced Cost)");

                    CalcWIP(JobTask, JobWIPTotal);
                    JobTask.Modify();

                    JobWIPTotal."Calc. Recog. Costs Amount" += JobTask."Recognized Costs Amount";
                    JobWIPTotal."Calc. Recog. Sales Amount" += JobTask."Recognized Sales Amount";

                    CreateTempJobWIPBuffers(JobTask, JobWIPTotal);
                    JobWIPTotalChanged := false;
                    WIPAmount := 0;
                end;
            until JobTask.Next = 0;

        CalcCostInvoicePercentage(JobWIPTotal);
        JobWIPTotal.Modify();
        JobWIPWarning.CreateEntries(JobWIPTotal);
    end;

    local procedure CreateJobWIPTotal(var JobTask: Record "Job Task"; var JobWIPTotal: Record "Job WIP Total")
    begin
        JobWIPTotalChanged := true;
        WIPAmount := 0;
        RecognizedAllocationPercentage := 0;

        JobWIPTotal.Init();

        if JobTask.Find('-') then
            repeat
                if JobTask."Job Task Type" = JobTask."Job Task Type"::Posting then begin
                    JobTask.CalcFields(
                      "Schedule (Total Cost)",
                      "Schedule (Total Price)",
                      "Usage (Total Cost)",
                      "Usage (Total Price)",
                      "Contract (Total Cost)",
                      "Contract (Total Price)",
                      "Contract (Invoiced Price)",
                      "Contract (Invoiced Cost)");

                    JobWIPTotal."Schedule (Total Cost)" += JobTask."Schedule (Total Cost)";
                    JobWIPTotal."Schedule (Total Price)" += JobTask."Schedule (Total Price)";
                    JobWIPTotal."Usage (Total Cost)" += JobTask."Usage (Total Cost)";
                    JobWIPTotal."Usage (Total Price)" += JobTask."Usage (Total Price)";
                    JobWIPTotal."Contract (Total Cost)" += JobTask."Contract (Total Cost)";
                    JobWIPTotal."Contract (Total Price)" += JobTask."Contract (Total Price)";
                    JobWIPTotal."Contract (Invoiced Price)" += JobTask."Contract (Invoiced Price)";
                    JobWIPTotal."Contract (Invoiced Cost)" += JobTask."Contract (Invoiced Cost)";

                    OnCreateJobWIPTotalOnAfterUpdateJobWIPTotal(JobTask, JobWIPTotal);
                end;
            until JobTask.Next = 0;

        // Get values from the "WIP-Total"::Total Job Task, which always is the last entry in the range:
        JobWIPTotal."Job No." := JobTask."Job No.";
        JobWIPTotal."Job Task No." := JobTask."Job Task No.";
        JobWIPTotal."WIP Posting Date" := WIPPostingDate;
        JobWIPTotal."WIP Posting Date Filter" :=
          CopyStr(JobTask.GetFilter("Posting Date Filter"), 1, MaxStrLen(JobWIPTotal."WIP Posting Date Filter"));
        JobWIPTotal."WIP Planning Date Filter" :=
          CopyStr(JobTask.GetFilter("Planning Date Filter"), 1, MaxStrLen(JobWIPTotal."WIP Planning Date Filter"));
        JobWIPTotal."WIP Method" := JobTask."WIP Method";
        JobWIPTotal.Insert();
    end;

    local procedure CalcWIP(var JobTask: Record "Job Task"; JobWIPTotal: Record "Job WIP Total")
    var
        JobWIPMethod: Record "Job WIP Method";
    begin
        if JobComplete then begin
            JobTask."Recognized Sales Amount" := JobTask."Contract (Invoiced Price)";
            JobTask."Recognized Costs Amount" := JobTask."Usage (Total Cost)";
            exit;
        end;

        with JobWIPMethod do begin
            Get(JobWIPTotal."WIP Method");
            case "Recognized Costs" of
                "Recognized Costs"::"Cost of Sales":
                    CalcCostOfSales(JobTask, JobWIPTotal);
                "Recognized Costs"::"Cost Value":
                    CalcCostValue(JobTask, JobWIPTotal);
                "Recognized Costs"::"Contract (Invoiced Cost)":
                    CalcContractInvoicedCost(JobTask);
                "Recognized Costs"::"Usage (Total Cost)":
                    CalcUsageTotalCostCosts(JobTask);
            end;
            case "Recognized Sales" of
                "Recognized Sales"::"Contract (Invoiced Price)":
                    CalcContractInvoicedPrice(JobTask);
                "Recognized Sales"::"Usage (Total Cost)":
                    CalcUsageTotalCostSales(JobTask);
                "Recognized Sales"::"Usage (Total Price)":
                    CalcUsageTotalPrice(JobTask);
                "Recognized Sales"::"Percentage of Completion":
                    CalcPercentageofCompletion(JobTask, JobWIPTotal);
                "Recognized Sales"::"Sales Value":
                    CalcSalesValue(JobTask, JobWIPTotal);
            end;
        end;
    end;

    local procedure CalcCostOfSales(var JobTask: Record "Job Task"; JobWIPTotal: Record "Job WIP Total")
    begin
        if JobWIPTotal."Contract (Total Price)" = 0 then
            exit;

        if JobWIPTotalChanged then begin
            WIPAmount := JobWIPTotal."Usage (Total Cost)" -
              ((JobWIPTotal."Contract (Invoiced Price)" / JobWIPTotal."Contract (Total Price)") *
               JobWIPTotal."Schedule (Total Cost)");
            if JobWIPTotal."Usage (Total Cost)" <> 0 then
                RecognizedAllocationPercentage := WIPAmount / JobWIPTotal."Usage (Total Cost)";
        end;

        with JobTask do begin
            if RecognizedAllocationPercentage <> 0 then
                WIPAmount := Round("Usage (Total Cost)" * RecognizedAllocationPercentage);
            "Recognized Costs Amount" := "Usage (Total Cost)" - WIPAmount;
        end;
    end;

    local procedure CalcCostValue(var JobTask: Record "Job Task"; JobWIPTotal: Record "Job WIP Total")
    begin
        if JobWIPTotal."Schedule (Total Price)" = 0 then
            exit;

        if JobWIPTotalChanged then begin
            WIPAmount :=
              (JobWIPTotal."Usage (Total Cost)" *
               JobWIPTotal."Contract (Total Price)" /
               JobWIPTotal."Schedule (Total Price)") -
              JobWIPTotal."Schedule (Total Cost)" *
              JobWIPTotal."Contract (Invoiced Price)" /
              JobWIPTotal."Schedule (Total Price)";
            if JobWIPTotal."Usage (Total Cost)" <> 0 then
                RecognizedAllocationPercentage := WIPAmount / JobWIPTotal."Usage (Total Cost)";
        end;

        with JobTask do begin
            if RecognizedAllocationPercentage <> 0 then
                WIPAmount := Round("Usage (Total Cost)" * RecognizedAllocationPercentage);
            "Recognized Costs Amount" := "Usage (Total Cost)" - WIPAmount;
        end;
    end;

    local procedure CalcContractInvoicedCost(var JobTask: Record "Job Task")
    begin
        JobTask."Recognized Costs Amount" := JobTask."Contract (Invoiced Cost)";
    end;

    local procedure CalcUsageTotalCostCosts(var JobTask: Record "Job Task")
    begin
        JobTask."Recognized Costs Amount" := JobTask."Usage (Total Cost)";
        OnAfterCalcUsageTotalCostCosts(JobTask);
    end;

    local procedure CalcContractInvoicedPrice(var JobTask: Record "Job Task")
    begin
        JobTask."Recognized Sales Amount" := JobTask."Contract (Invoiced Price)";
    end;

    local procedure CalcUsageTotalCostSales(var JobTask: Record "Job Task")
    begin
        JobTask."Recognized Sales Amount" := JobTask."Usage (Total Cost)";
    end;

    local procedure CalcUsageTotalPrice(var JobTask: Record "Job Task")
    begin
        JobTask."Recognized Sales Amount" := JobTask."Usage (Total Price)";
    end;

    local procedure CalcPercentageofCompletion(var JobTask: Record "Job Task"; JobWIPTotal: Record "Job WIP Total")
    var
        IsHandled: Boolean;
    begin
        OnBeforeCalcPercentageOfCompletion(
          JobTask, JobWIPTotal, JobWIPTotalChanged, WIPAmount, RecognizedAllocationPercentage, IsHandled);
        if IsHandled then
            exit;

        if JobWIPTotal."Schedule (Total Cost)" = 0 then
            exit;

        if JobWIPTotalChanged then begin
            if JobWIPTotal."Usage (Total Cost)" <= JobWIPTotal."Schedule (Total Cost)" then
                WIPAmount :=
                  (JobWIPTotal."Usage (Total Cost)" / JobWIPTotal."Schedule (Total Cost)") *
                  JobWIPTotal."Contract (Total Price)"
            else
                WIPAmount := JobWIPTotal."Contract (Total Price)";
            if JobWIPTotal."Contract (Total Price)" <> 0 then
                RecognizedAllocationPercentage := WIPAmount / JobWIPTotal."Contract (Total Price)";
        end;

        with JobTask do begin
            if RecognizedAllocationPercentage <> 0 then
                WIPAmount := Round("Contract (Total Price)" * RecognizedAllocationPercentage);
            "Recognized Sales Amount" := WIPAmount;
        end;
    end;

    local procedure CalcSalesValue(var JobTask: Record "Job Task"; JobWIPTotal: Record "Job WIP Total")
    begin
        if JobWIPTotal."Schedule (Total Price)" = 0 then
            exit;

        if JobWIPTotalChanged then begin
            WIPAmount :=
              (JobWIPTotal."Usage (Total Price)" *
               JobWIPTotal."Contract (Total Price)" /
               JobWIPTotal."Schedule (Total Price)") -
              JobWIPTotal."Contract (Invoiced Price)";
            if JobWIPTotal."Usage (Total Price)" <> 0 then
                RecognizedAllocationPercentage := WIPAmount / JobWIPTotal."Usage (Total Price)";
        end;

        with JobTask do begin
            if RecognizedAllocationPercentage <> 0 then
                WIPAmount := Round("Usage (Total Price)" * RecognizedAllocationPercentage);
            "Recognized Sales Amount" := ("Contract (Invoiced Price)" + WIPAmount);
        end;
    end;

    local procedure CalcCostInvoicePercentage(var JobWIPTotal: Record "Job WIP Total")
    begin
        with JobWIPTotal do begin
            if "Schedule (Total Cost)" <> 0 then
                "Cost Completion %" := Round(100 * "Usage (Total Cost)" / "Schedule (Total Cost)", 0.00001)
            else
                "Cost Completion %" := 0;
            if "Contract (Total Price)" <> 0 then
                "Invoiced %" := Round(100 * "Contract (Invoiced Price)" / "Contract (Total Price)", 0.00001)
            else
                "Invoiced %" := 0;
        end;
    end;

    local procedure CreateTempJobWIPBuffers(var JobTask: Record "Job Task"; var JobWIPTotal: Record "Job WIP Total")
    var
        Job: Record Job;
        JobWIPMethod: Record "Job WIP Method";
        BufferType: Option "Applied Costs","Applied Sales","Recognized Costs","Recognized Sales","Accrued Costs","Accrued Sales";
    begin
        Job.Get(JobTask."Job No.");
        JobWIPMethod.Get(JobWIPTotal."WIP Method");
        with JobTask do
            if not JobComplete then begin
                if "Recognized Costs Amount" <> 0 then begin
                    CreateWIPBufferEntryFromTask(JobTask, JobWIPTotal, BufferType::"Recognized Costs", false);
                    if Job."WIP Posting Method" = Job."WIP Posting Method"::"Per Job" then
                        CreateWIPBufferEntryFromTask(JobTask, JobWIPTotal, BufferType::"Applied Costs", false)
                    else
                        FindJobLedgerEntriesByJobTask(JobTask, JobWIPTotal, BufferType::"Applied Costs");
                    if "Recognized Costs Amount" > "Usage (Total Cost)" then begin
                        CreateWIPBufferEntryFromTask(JobTask, JobWIPTotal, BufferType::"Accrued Costs", false);
                        if Job."WIP Posting Method" = Job."WIP Posting Method"::"Per Job Ledger Entry" then
                            CreateWIPBufferEntryFromTask(JobTask, JobWIPTotal, BufferType::"Applied Costs", true);
                    end;
                end;
                if "Recognized Sales Amount" <> 0 then begin
                    CreateWIPBufferEntryFromTask(JobTask, JobWIPTotal, BufferType::"Recognized Sales", false);
                    if (Job."WIP Posting Method" = Job."WIP Posting Method"::"Per Job") or
                       (JobWIPMethod."Recognized Sales" = JobWIPMethod."Recognized Sales"::"Percentage of Completion")
                    then
                        CreateWIPBufferEntryFromTask(
                          JobTask, JobWIPTotal, BufferType::"Applied Sales",
                          (("Contract (Invoiced Price)" > "Recognized Sales Amount") and
                           (JobWIPMethod."Recognized Sales" = JobWIPMethod."Recognized Sales"::"Percentage of Completion")))
                    else
                        FindJobLedgerEntriesByJobTask(JobTask, JobWIPTotal, BufferType::"Applied Sales");
                    if "Recognized Sales Amount" > "Contract (Invoiced Price)" then
                        CreateWIPBufferEntryFromTask(JobTask, JobWIPTotal, BufferType::"Accrued Sales", false);
                end;
                if ("Recognized Costs Amount" = 0) and ("Usage (Total Cost)" <> 0) then begin
                    if Job."WIP Posting Method" = Job."WIP Posting Method"::"Per Job" then
                        CreateWIPBufferEntryFromTask(JobTask, JobWIPTotal, BufferType::"Applied Costs", false)
                    else
                        FindJobLedgerEntriesByJobTask(JobTask, JobWIPTotal, BufferType::"Applied Costs");
                end;
                if ("Recognized Sales Amount" = 0) and ("Contract (Invoiced Price)" <> 0) then begin
                    if Job."WIP Posting Method" = Job."WIP Posting Method"::"Per Job" then
                        CreateWIPBufferEntryFromTask(JobTask, JobWIPTotal, BufferType::"Applied Sales", false)
                    else
                        FindJobLedgerEntriesByJobTask(JobTask, JobWIPTotal, BufferType::"Applied Sales");
                end;
            end else begin
                if Job."WIP Posting Method" = Job."WIP Posting Method"::"Per Job Ledger Entry" then begin
                    FindJobLedgerEntriesByJobTask(JobTask, JobWIPTotal, BufferType::"Applied Costs");
                    FindJobLedgerEntriesByJobTask(JobTask, JobWIPTotal, BufferType::"Applied Sales");
                end;

                if "Recognized Costs Amount" <> 0 then
                    CreateWIPBufferEntryFromTask(JobTask, JobWIPTotal, BufferType::"Recognized Costs", false);
                if "Recognized Sales Amount" <> 0 then
                    CreateWIPBufferEntryFromTask(JobTask, JobWIPTotal, BufferType::"Recognized Sales", false);
            end;
    end;

    local procedure CreateWIPBufferEntryFromTask(var JobTask: Record "Job Task"; var JobWIPTotal: Record "Job WIP Total"; BufferType: Option "Applied Costs","Applied Sales","Recognized Costs","Recognized Sales","Accrued Costs","Accrued Sales"; AppliedAccrued: Boolean)
    var
        JobTaskDimension: Record "Job Task Dimension";
        TempDimensionBuffer: Record "Dimension Buffer" temporary;
        Job: Record Job;
        JobPostingGroup: Record "Job Posting Group";
        JobWIPMethod: Record "Job WIP Method";
    begin
        Clear(TempJobWIPBuffer);
        TempDimensionBuffer.Reset();
        TempDimensionBuffer.DeleteAll();

        JobTaskDimension.SetRange("Job No.", JobTask."Job No.");
        JobTaskDimension.SetRange("Job Task No.", JobTask."Job Task No.");
        if JobTaskDimension.FindSet then
            repeat
                TempDimensionBuffer."Dimension Code" := JobTaskDimension."Dimension Code";
                TempDimensionBuffer."Dimension Value Code" := JobTaskDimension."Dimension Value Code";
                TempDimensionBuffer.Insert();
            until JobTaskDimension.Next = 0;
        if not DimMgt.CheckDimBuffer(TempDimensionBuffer) then
            Error(DimMgt.GetDimCombErr);
        TempJobWIPBuffer[1]."Dim Combination ID" := DimMgt.CreateDimSetIDFromDimBuf(TempDimensionBuffer);

        Job.Get(JobTask."Job No.");
        if JobTask."Job Posting Group" = '' then begin
            Job.TestField("Job Posting Group");
            JobTask."Job Posting Group" := Job."Job Posting Group";
        end;
        JobPostingGroup.Get(JobTask."Job Posting Group");
        JobWIPMethod.Get(JobWIPTotal."WIP Method");

        case BufferType of
            BufferType::"Applied Costs":
                begin
                    TempJobWIPBuffer[1].Type := TempJobWIPBuffer[1].Type::"Applied Costs";
                    TempJobWIPBuffer[1]."G/L Account No." := JobPostingGroup.GetJobCostsAppliedAccount;
                    TempJobWIPBuffer[1]."Bal. G/L Account No." := JobPostingGroup.GetWIPCostsAccount;
                    TempJobWIPBuffer[1]."WIP Entry Amount" := GetAppliedCostsWIPEntryAmount(JobTask, JobWIPMethod, AppliedAccrued);
                end;
            BufferType::"Applied Sales":
                begin
                    TempJobWIPBuffer[1].Type := TempJobWIPBuffer[1].Type::"Applied Sales";
                    TempJobWIPBuffer[1]."G/L Account No." := JobPostingGroup.GetJobSalesAppliedAccount;
                    TempJobWIPBuffer[1]."Bal. G/L Account No." := JobPostingGroup.GetWIPInvoicedSalesAccount;
                    TempJobWIPBuffer[1]."WIP Entry Amount" := GetAppliedSalesWIPEntryAmount(JobTask, JobWIPMethod, AppliedAccrued);
                end;
            BufferType::"Recognized Costs":
                begin
                    TempJobWIPBuffer[1].Type := TempJobWIPBuffer[1].Type::"Recognized Costs";
                    TempJobWIPBuffer[1]."G/L Account No." := JobPostingGroup.GetRecognizedCostsAccount;
                    TempJobWIPBuffer[1]."Bal. G/L Account No." := GetRecognizedCostsBalGLAccountNo(Job, JobPostingGroup);
                    TempJobWIPBuffer[1]."Job Complete" := JobComplete;
                    TempJobWIPBuffer[1]."WIP Entry Amount" := JobTask."Recognized Costs Amount";
                end;
            BufferType::"Recognized Sales":
                begin
                    TempJobWIPBuffer[1].Type := TempJobWIPBuffer[1].Type::"Recognized Sales";
                    TempJobWIPBuffer[1]."G/L Account No." := JobPostingGroup.GetRecognizedSalesAccount;
                    TempJobWIPBuffer[1]."Bal. G/L Account No." := GetRecognizedSalesBalGLAccountNo(Job, JobPostingGroup, JobWIPMethod);
                    TempJobWIPBuffer[1]."Job Complete" := JobComplete;
                    TempJobWIPBuffer[1]."WIP Entry Amount" := -JobTask."Recognized Sales Amount";
                end;
            BufferType::"Accrued Costs":
                begin
                    TempJobWIPBuffer[1].Type := TempJobWIPBuffer[1].Type::"Accrued Costs";
                    TempJobWIPBuffer[1]."G/L Account No." := JobPostingGroup.GetJobCostsAdjustmentAccount;
                    TempJobWIPBuffer[1]."Bal. G/L Account No." := JobPostingGroup.GetWIPAccruedCostsAccount;
                    TempJobWIPBuffer[1]."WIP Entry Amount" := GetAccruedCostsWIPEntryAmount(JobTask, JobWIPMethod);
                end;
            BufferType::"Accrued Sales":
                begin
                    TempJobWIPBuffer[1].Type := TempJobWIPBuffer[1].Type::"Accrued Sales";
                    TempJobWIPBuffer[1]."G/L Account No." := JobPostingGroup.GetJobSalesAdjustmentAccount;
                    TempJobWIPBuffer[1]."Bal. G/L Account No." := JobPostingGroup.GetWIPAccruedSalesAccount;
                    TempJobWIPBuffer[1]."WIP Entry Amount" := GetAccruedSalesWIPEntryAmount(JobTask, JobWIPMethod);
                end;
        end;

        if TempJobWIPBuffer[1]."WIP Entry Amount" <> 0 then begin
            TempJobWIPBuffer[1].Reverse := true;
            TransferJobTaskToTempJobWIPBuf(JobTask, JobWIPTotal);
            UpdateTempJobWIPBufferEntry;
        end;
    end;

    local procedure FindJobLedgerEntriesByJobTask(var JobTask: Record "Job Task"; var JobWIPTotal: Record "Job WIP Total"; BufferType: Option "Applied Costs","Applied Sales","Recognized Costs","Recognized Sales","Accrued Costs","Accrued Sales")
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        JobLedgerEntry.SetRange("Job No.", JobTask."Job No.");
        JobLedgerEntry.SetRange("Job Task No.", JobTask."Job Task No.");
        JobLedgerEntry.SetFilter("Posting Date", JobTask.GetFilter("Posting Date Filter"));
        if BufferType = BufferType::"Applied Costs" then
            JobLedgerEntry.SetRange("Entry Type", JobLedgerEntry."Entry Type"::Usage);
        if BufferType = BufferType::"Applied Sales" then
            JobLedgerEntry.SetRange("Entry Type", JobLedgerEntry."Entry Type"::Sale);

        if JobLedgerEntry.FindSet then
            repeat
                CreateWIPBufferEntryFromLedger(JobLedgerEntry, JobTask, JobWIPTotal, BufferType)
            until JobLedgerEntry.Next = 0;
    end;

    local procedure CreateWIPBufferEntryFromLedger(var JobLedgerEntry: Record "Job Ledger Entry"; var JobTask: Record "Job Task"; var JobWIPTotal: Record "Job WIP Total"; BufferType: Option "Applied Costs","Applied Sales","Recognized Costs","Recognized Sales","Accrued Costs","Accrued Sales")
    var
        Job: Record Job;
        JobPostingGroup: Record "Job Posting Group";
    begin
        Clear(TempJobWIPBuffer);
        TempJobWIPBuffer[1]."Dim Combination ID" := JobLedgerEntry."Dimension Set ID";
        TempJobWIPBuffer[1]."Job Complete" := JobComplete;
        if JobTask."Job Posting Group" = '' then begin
            Job.Get(JobTask."Job No.");
            Job.TestField("Job Posting Group");
            JobTask."Job Posting Group" := Job."Job Posting Group";
        end;
        JobPostingGroup.Get(JobTask."Job Posting Group");

        case BufferType of
            BufferType::"Applied Costs":
                begin
                    TempJobWIPBuffer[1].Type := TempJobWIPBuffer[1].Type::"Applied Costs";
                    case JobLedgerEntry.Type of
                        JobLedgerEntry.Type::Item:
                            TempJobWIPBuffer[1]."G/L Account No." := JobPostingGroup.GetItemCostsAppliedAccount;
                        JobLedgerEntry.Type::Resource:
                            TempJobWIPBuffer[1]."G/L Account No." := JobPostingGroup.GetResourceCostsAppliedAccount;
                        JobLedgerEntry.Type::"G/L Account":
                            TempJobWIPBuffer[1]."G/L Account No." := JobPostingGroup.GetGLCostsAppliedAccount;
                    end;
                    TempJobWIPBuffer[1]."Bal. G/L Account No." := JobPostingGroup.GetWIPCostsAccount;
                    TempJobWIPBuffer[1]."WIP Entry Amount" := -JobLedgerEntry."Total Cost (LCY)";
                    JobLedgerEntry."Amt. to Post to G/L" := JobLedgerEntry."Total Cost (LCY)" - JobLedgerEntry."Amt. Posted to G/L";
                end;
            BufferType::"Applied Sales":
                begin
                    TempJobWIPBuffer[1].Type := TempJobWIPBuffer[1].Type::"Applied Sales";
                    TempJobWIPBuffer[1]."G/L Account No." := JobPostingGroup.GetJobSalesAppliedAccount;
                    TempJobWIPBuffer[1]."Bal. G/L Account No." := JobPostingGroup.GetWIPInvoicedSalesAccount;
                    TempJobWIPBuffer[1]."WIP Entry Amount" := -JobLedgerEntry."Line Amount (LCY)";
                    JobLedgerEntry."Amt. to Post to G/L" := JobLedgerEntry."Line Amount (LCY)" - JobLedgerEntry."Amt. Posted to G/L";
                end;
        end;

        JobLedgerEntry.Modify();

        if TempJobWIPBuffer[1]."WIP Entry Amount" <> 0 then begin
            TempJobWIPBuffer[1].Reverse := true;
            TransferJobTaskToTempJobWIPBuf(JobTask, JobWIPTotal);
            UpdateTempJobWIPBufferEntry;
        end;
    end;

    local procedure TransferJobTaskToTempJobWIPBuf(JobTask: Record "Job Task"; JobWIPTotal: Record "Job WIP Total")
    var
        Job: Record Job;
    begin
        with Job do begin
            Get(JobTask."Job No.");
            TempJobWIPBuffer[1]."WIP Posting Method Used" := "WIP Posting Method";
        end;

        with JobTask do begin
            TempJobWIPBuffer[1]."Job No." := "Job No.";
            TempJobWIPBuffer[1]."Posting Group" := "Job Posting Group";
        end;

        with JobWIPTotal do begin
            TempJobWIPBuffer[1]."WIP Method" := "WIP Method";
            TempJobWIPBuffer[1]."Job WIP Total Entry No." := "Entry No.";
        end;
    end;

    local procedure UpdateTempJobWIPBufferEntry()
    begin
        TempJobWIPBuffer[2] := TempJobWIPBuffer[1];
        if TempJobWIPBuffer[2].Find then begin
            TempJobWIPBuffer[2]."WIP Entry Amount" += TempJobWIPBuffer[1]."WIP Entry Amount";
            TempJobWIPBuffer[2].Modify();
        end else
            TempJobWIPBuffer[1].Insert();
    end;

    local procedure CreateWIPEntries(JobNo: Code[20])
    var
        JobWIPEntry: Record "Job WIP Entry";
        JobWIPMethod: Record "Job WIP Method";
        NextEntryNo: Integer;
        CreateEntry: Boolean;
    begin
        NextEntryNo := JobWIPEntry.GetLastEntryNo() + 1;

        GetGLSetup;
        if TempJobWIPBuffer[1].Find('-') then
            repeat
                CreateEntry := true;

                JobWIPMethod.Get(TempJobWIPBuffer[1]."WIP Method");
                if not JobWIPMethod."WIP Cost" and
                   ((TempJobWIPBuffer[1].Type = TempJobWIPBuffer[1].Type::"Recognized Costs") or
                    (TempJobWIPBuffer[1].Type = TempJobWIPBuffer[1].Type::"Applied Costs"))
                then
                    CreateEntry := false;

                if not JobWIPMethod."WIP Sales" and
                   ((TempJobWIPBuffer[1].Type = TempJobWIPBuffer[1].Type::"Recognized Sales") or
                    (TempJobWIPBuffer[1].Type = TempJobWIPBuffer[1].Type::"Applied Sales"))
                then
                    CreateEntry := false;

                if TempJobWIPBuffer[1]."WIP Entry Amount" = 0 then
                    CreateEntry := false;

                if CreateEntry then begin
                    Clear(JobWIPEntry);
                    JobWIPEntry."Job No." := JobNo;
                    JobWIPEntry."WIP Posting Date" := WIPPostingDate;
                    JobWIPEntry."Document No." := DocNo;
                    JobWIPEntry.Type := TempJobWIPBuffer[1].Type;
                    JobWIPEntry."Job Posting Group" := TempJobWIPBuffer[1]."Posting Group";
                    JobWIPEntry."G/L Account No." := TempJobWIPBuffer[1]."G/L Account No.";
                    JobWIPEntry."G/L Bal. Account No." := TempJobWIPBuffer[1]."Bal. G/L Account No.";
                    JobWIPEntry."WIP Method Used" := TempJobWIPBuffer[1]."WIP Method";
                    JobWIPEntry."Job Complete" := TempJobWIPBuffer[1]."Job Complete";
                    JobWIPEntry."Job WIP Total Entry No." := TempJobWIPBuffer[1]."Job WIP Total Entry No.";
                    JobWIPEntry."WIP Entry Amount" := Round(TempJobWIPBuffer[1]."WIP Entry Amount");
                    JobWIPEntry.Reverse := TempJobWIPBuffer[1].Reverse;
                    JobWIPEntry."WIP Posting Method Used" := TempJobWIPBuffer[1]."WIP Posting Method Used";
                    JobWIPEntry."Entry No." := NextEntryNo;
                    JobWIPEntry."Dimension Set ID" := TempJobWIPBuffer[1]."Dim Combination ID";
                    DimMgt.UpdateGlobalDimFromDimSetID(JobWIPEntry."Dimension Set ID", JobWIPEntry."Global Dimension 1 Code",
                      JobWIPEntry."Global Dimension 2 Code");
                    JobWIPEntry.Insert(true);
                    NextEntryNo := NextEntryNo + 1;
                end;
            until TempJobWIPBuffer[1].Next = 0;
    end;

    procedure CalcGLWIP(JobNo: Code[20]; JustReverse: Boolean; DocNo: Code[20]; PostingDate: Date; NewPostDate: Boolean)
    var
        SourceCodeSetup: Record "Source Code Setup";
        GLEntry: Record "G/L Entry";
        Job: Record Job;
        JobWIPEntry: Record "Job WIP Entry";
        JobWIPGLEntry: Record "Job WIP G/L Entry";
        JobWIPTotal: Record "Job WIP Total";
        JobLedgerEntry: Record "Job Ledger Entry";
        JobTask: Record "Job Task";
        NextEntryNo: Integer;
        NextTransactionNo: Integer;
    begin
        JobWIPGLEntry.LockTable();
        JobWIPEntry.LockTable();
        Job.LockTable();

        JobWIPGLEntry.SetCurrentKey("Job No.", Reversed, "Job Complete");
        JobWIPGLEntry.SetRange("Job No.", JobNo);
        JobWIPGLEntry.SetRange("Job Complete", true);
        if not JobWIPGLEntry.IsEmpty then
            exit;
        JobWIPGLEntry.Reset();

        Job.Get(JobNo);
        Job.TestBlocked;
        if NewPostDate then
            Job."WIP G/L Posting Date" := PostingDate;
        if JustReverse then
            Job."WIP G/L Posting Date" := 0D;
        Job.Modify();

        NextEntryNo := JobWIPGLEntry.GetLastEntryNo() + 1;

        JobWIPGLEntry.SetCurrentKey("WIP Transaction No.");
        if JobWIPGLEntry.FindLast then
            NextTransactionNo := JobWIPGLEntry."WIP Transaction No." + 1
        else
            NextTransactionNo := 1;

        SourceCodeSetup.Get();

        // Reverse Entries
        JobWIPGLEntry.SetCurrentKey("Job No.", Reversed);
        JobWIPGLEntry.SetRange("Job No.", JobNo);
        JobWIPGLEntry.SetRange(Reverse, true);
        JobWIPGLEntry.SetRange(Reversed, false);
        if JobWIPGLEntry.Find('-') then
            repeat
                if JobWIPGLEntry."Posting Date" > PostingDate then
                    Error(Text004, JobWIPGLEntry."Job No.", JobWIPGLEntry."Posting Date");
            until JobWIPGLEntry.Next = 0;
        if JobWIPGLEntry.Find('-') then
            repeat
                PostWIPGL(JobWIPGLEntry, true, DocNo, SourceCodeSetup."Job G/L WIP", PostingDate);
            until JobWIPGLEntry.Next = 0;
        JobWIPGLEntry.ModifyAll("Reverse Date", PostingDate);
        JobWIPGLEntry.ModifyAll(Reversed, true);
        if JustReverse then
            exit;

        JobWIPEntry.SetRange("Job No.", JobNo);
        if JobWIPEntry.Find('-') then
            repeat
                Clear(JobWIPGLEntry);
                JobWIPGLEntry."Job No." := JobWIPEntry."Job No.";
                JobWIPGLEntry."Document No." := JobWIPEntry."Document No.";
                JobWIPGLEntry."G/L Account No." := JobWIPEntry."G/L Account No.";
                JobWIPGLEntry."G/L Bal. Account No." := JobWIPEntry."G/L Bal. Account No.";
                JobWIPGLEntry.Type := JobWIPEntry.Type;
                JobWIPGLEntry."WIP Posting Date" := JobWIPEntry."WIP Posting Date";
                if NewPostDate then
                    JobWIPGLEntry."Posting Date" := PostingDate
                else
                    JobWIPGLEntry."Posting Date" := JobWIPEntry."WIP Posting Date";
                JobWIPGLEntry."Job Posting Group" := JobWIPEntry."Job Posting Group";
                JobWIPGLEntry."WIP Method Used" := JobWIPEntry."WIP Method Used";
                if not NewPostDate then begin
                    Job."WIP G/L Posting Date" := JobWIPEntry."WIP Posting Date";
                    Job.Modify();
                end;
                JobWIPGLEntry.Reversed := false;
                JobWIPGLEntry."Job Complete" := JobWIPEntry."Job Complete";
                JobWIPGLEntry."WIP Transaction No." := NextTransactionNo;
                if JobWIPGLEntry.Type in [JobWIPGLEntry.Type::"Recognized Costs", JobWIPGLEntry.Type::"Recognized Sales"] then begin
                    if JobWIPGLEntry."Job Complete" then
                        JobWIPGLEntry.Description := StrSubstNo(Text003, JobNo)
                    else
                        JobWIPGLEntry.Description := StrSubstNo(Text002, JobNo);
                end else
                    JobWIPGLEntry.Description := StrSubstNo(Text001, JobNo);
                JobWIPGLEntry."WIP Entry Amount" := JobWIPEntry."WIP Entry Amount";
                JobWIPGLEntry.Reverse := JobWIPEntry.Reverse;
                JobWIPGLEntry."WIP Posting Method Used" := JobWIPEntry."WIP Posting Method Used";
                JobWIPGLEntry."Job WIP Total Entry No." := JobWIPEntry."Job WIP Total Entry No.";
                JobWIPGLEntry."Global Dimension 1 Code" := JobWIPEntry."Global Dimension 1 Code";
                JobWIPGLEntry."Global Dimension 2 Code" := JobWIPEntry."Global Dimension 2 Code";
                JobWIPGLEntry."Dimension Set ID" := JobWIPEntry."Dimension Set ID";
                JobWIPGLEntry."Entry No." := NextEntryNo;
                NextEntryNo := NextEntryNo + 1;
                PostWIPGL(JobWIPGLEntry,
                  false,
                  JobWIPGLEntry."Document No.",
                  SourceCodeSetup."Job G/L WIP",
                  JobWIPGLEntry."Posting Date");
                JobWIPGLEntry."G/L Entry No." := GLEntry.GetLastEntryNo();
                JobWIPGLEntry.Insert();
                JobWIPTotal.Get(JobWIPGLEntry."Job WIP Total Entry No.");
                JobWIPTotal."Posted to G/L" := true;
                JobWIPTotal.Modify();
            until JobWIPEntry.Next = 0;

        with JobTask do begin
            SetRange("Job No.", Job."No.");
            if FindSet then
                repeat
                    "Recognized Sales G/L Amount" := "Recognized Sales Amount";
                    "Recognized Costs G/L Amount" := "Recognized Costs Amount";
                    Modify;
                until Next = 0;
        end;

        with JobLedgerEntry do begin
            SetRange("Job No.", Job."No.");
            SetFilter("Amt. to Post to G/L", '<>%1', 0);
            if FindSet then
                repeat
                    "Amt. Posted to G/L" += "Amt. to Post to G/L";
                    Modify;
                until Next = 0;
        end;

        DeleteWIP(Job);
    end;

    local procedure PostWIPGL(JobWIPGLEntry: Record "Job WIP G/L Entry"; Reversed: Boolean; JnlDocNo: Code[20]; SourceCode: Code[10]; JnlPostingDate: Date)
    var
        GLAmount: Decimal;
    begin
        CheckJobGLAcc(JobWIPGLEntry."G/L Account No.");
        CheckJobGLAcc(JobWIPGLEntry."G/L Bal. Account No.");
        GLAmount := JobWIPGLEntry."WIP Entry Amount";
        if Reversed then
            GLAmount := -GLAmount;

        InsertWIPGL(JobWIPGLEntry."G/L Account No.", JobWIPGLEntry."G/L Bal. Account No.", JnlPostingDate, JnlDocNo, SourceCode,
          GLAmount, JobWIPGLEntry.Description, JobWIPGLEntry."Job No.", JobWIPGLEntry."Dimension Set ID");
    end;

    local procedure InsertWIPGL(AccNo: Code[20]; BalAccNo: Code[20]; JnlPostingDate: Date; JnlDocNo: Code[20]; SourceCode: Code[10]; GLAmount: Decimal; JnlDescription: Text[100]; JobNo: Code[20]; JobWIPGLEntryDimSetID: Integer)
    var
        GenJnlLine: Record "Gen. Journal Line";
        GLAcc: Record "G/L Account";
    begin
        GLAcc.Get(AccNo);
        with GenJnlLine do begin
            Init;
            "Posting Date" := JnlPostingDate;
            "Account No." := AccNo;
            "Bal. Account No." := BalAccNo;
            "Tax Area Code" := GLAcc."Tax Area Code";
            "Tax Liable" := GLAcc."Tax Liable";
            "Tax Group Code" := GLAcc."Tax Group Code";
            Amount := GLAmount;
            "Document No." := JnlDocNo;
            "Source Code" := SourceCode;
            Description := JnlDescription;
            "Job No." := JobNo;
            "System-Created Entry" := true;
            "Dimension Set ID" := JobWIPGLEntryDimSetID;
        end;
        Clear(DimMgt);
        DimMgt.UpdateGlobalDimFromDimSetID(GenJnlLine."Dimension Set ID", GenJnlLine."Shortcut Dimension 1 Code",
          GenJnlLine."Shortcut Dimension 2 Code");

        OnInsertWIPGLOnBeforeGenJnPostLine(GenJnlLine);
        GenJnPostLine.RunWithCheck(GenJnlLine);
    end;

    local procedure CheckJobGLAcc(AccNo: Code[20])
    var
        GLAcc: Record "G/L Account";
    begin
        GLAcc.Get(AccNo);
        GLAcc.CheckGLAcc;
        GLAcc.TestField("Gen. Posting Type", GLAcc."Gen. Posting Type"::" ");
        GLAcc.TestField("Gen. Bus. Posting Group", '');
        GLAcc.TestField("Gen. Prod. Posting Group", '');
        GLAcc.TestField("VAT Bus. Posting Group", '');
        GLAcc.TestField("VAT Prod. Posting Group", '');
    end;

    local procedure GetGLSetup()
    begin
        if not HasGotGLSetup then begin
            GLSetup.Get();
            HasGotGLSetup := true;
        end;
    end;

    procedure ReOpenJob(JobNo: Code[20])
    var
        Job: Record Job;
        JobWIPGLEntry: Record "Job WIP G/L Entry";
    begin
        Job.Get(JobNo);
        DeleteWIP(Job);
        JobWIPGLEntry.SetCurrentKey("Job No.", Reversed, "Job Complete");
        JobWIPGLEntry.SetRange("Job No.", JobNo);
        JobWIPGLEntry.ModifyAll("Job Complete", false);
    end;

    local procedure GetRecognizedCostsBalGLAccountNo(Job: Record Job; JobPostingGroup: Record "Job Posting Group"): Code[20]
    begin
        if not JobComplete or (Job."WIP Posting Method" = Job."WIP Posting Method"::"Per Job Ledger Entry") then
            exit(JobPostingGroup.GetWIPCostsAccount);

        exit(JobPostingGroup.GetJobCostsAppliedAccount);
    end;

    local procedure GetRecognizedSalesBalGLAccountNo(Job: Record Job; JobPostingGroup: Record "Job Posting Group"; JobWIPMethod: Record "Job WIP Method"): Code[20]
    begin
        case true of
            not JobComplete and
          (JobWIPMethod."Recognized Sales" = JobWIPMethod."Recognized Sales"::"Percentage of Completion"):
                exit(JobPostingGroup.GetWIPAccruedSalesAccount);
            not JobComplete or (Job."WIP Posting Method" = Job."WIP Posting Method"::"Per Job Ledger Entry"):
                exit(JobPostingGroup.GetWIPInvoicedSalesAccount);
            else
                exit(JobPostingGroup.GetJobSalesAppliedAccount);
        end;
    end;

    local procedure GetAppliedCostsWIPEntryAmount(JobTask: Record "Job Task"; JobWIPMethod: Record "Job WIP Method"; AppliedAccrued: Boolean): Decimal
    begin
        if AppliedAccrued then
            exit(JobTask."Usage (Total Cost)" - JobTask."Recognized Costs Amount");

        if IsAccruedCostsWIPMethod(JobWIPMethod) and (JobTask."Recognized Costs Amount" <> 0) then
            exit(-GetMAX(JobTask."Recognized Costs Amount", JobTask."Usage (Total Cost)"));

        exit(-JobTask."Usage (Total Cost)");
    end;

    local procedure GetAppliedSalesWIPEntryAmount(JobTask: Record "Job Task"; JobWIPMethod: Record "Job WIP Method"; AppliedAccrued: Boolean) SalesAmount: Decimal
    begin
        if AppliedAccrued then begin
            SalesAmount := JobTask."Recognized Sales Amount" - JobTask."Contract (Invoiced Price)";
            if SalesAmount < 0 then
                exit(JobTask."Contract (Invoiced Price)");
            exit(SalesAmount);
        end;

        if IsAccruedSalesWIPMethod(JobWIPMethod) then
            exit(GetMAX(JobTask."Recognized Sales Amount", JobTask."Contract (Invoiced Price)"));

        exit(JobTask."Contract (Invoiced Price)");
    end;

    local procedure GetAccruedCostsWIPEntryAmount(JobTask: Record "Job Task"; JobWIPMethod: Record "Job WIP Method"): Decimal
    begin
        if IsAccruedCostsWIPMethod(JobWIPMethod) then
            exit(JobTask."Recognized Costs Amount" - JobTask."Usage (Total Cost)");
        exit(0);
    end;

    local procedure GetAccruedSalesWIPEntryAmount(JobTask: Record "Job Task"; JobWIPMethod: Record "Job WIP Method"): Decimal
    begin
        if IsAccruedSalesWIPMethod(JobWIPMethod) then
            exit(-JobTask."Recognized Sales Amount" + JobTask."Contract (Invoiced Price)");
        exit(0);
    end;

    local procedure GetMAX(Value1: Decimal; Value2: Decimal): Decimal
    begin
        if Value1 > Value2 then
            exit(Value1);
        exit(Value2);
    end;

    local procedure IsAccruedCostsWIPMethod(JobWIPMethod: Record "Job WIP Method"): Boolean
    begin
        exit(
          JobWIPMethod."Recognized Costs" in
          [JobWIPMethod."Recognized Costs"::"Cost Value",
           JobWIPMethod."Recognized Costs"::"Cost of Sales",
           JobWIPMethod."Recognized Costs"::"Contract (Invoiced Cost)"]);
    end;

    local procedure IsAccruedSalesWIPMethod(JobWIPMethod: Record "Job WIP Method"): Boolean
    begin
        exit(
          JobWIPMethod."Recognized Sales" in
          [JobWIPMethod."Recognized Sales"::"Sales Value",
           JobWIPMethod."Recognized Sales"::"Usage (Total Price)"]);
    end;

    [EventSubscriber(ObjectType::Table, 1001, 'OnBeforeModifyEvent', '', false, false)]
    [Scope('OnPrem')]
    procedure VerifyJobWIPEntryOnBeforeModify(var Rec: Record "Job Task"; var xRec: Record "Job Task"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary then
            exit;

        if JobTaskWIPRelatedFieldsAreModified(Rec) then
            VerifyJobWIPEntryIsEmpty(Rec."Job No.");
    end;

    [EventSubscriber(ObjectType::Table, 1001, 'OnBeforeRenameEvent', '', false, false)]
    [Scope('OnPrem')]
    procedure VerifyJobWIPEntryOnBeforeRename(var Rec: Record "Job Task"; var xRec: Record "Job Task"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary then
            exit;

        VerifyJobWIPEntryIsEmpty(Rec."Job No.");
    end;

    local procedure JobTaskWIPRelatedFieldsAreModified(JobTask: Record "Job Task"): Boolean
    var
        OldJobTask: Record "Job Task";
    begin
        OldJobTask.Get(JobTask."Job No.", JobTask."Job Task No.");
        exit(
          (OldJobTask."Job Task Type" <> JobTask."Job Task Type") or
          (OldJobTask."WIP-Total" <> JobTask."WIP-Total") or
          (OldJobTask."Job Posting Group" <> JobTask."Job Posting Group") or
          (OldJobTask."WIP Method" <> JobTask."WIP Method") or
          (OldJobTask.Totaling <> JobTask.Totaling));
    end;

    local procedure VerifyJobWIPEntryIsEmpty(JobNo: Code[20])
    var
        JobWIPEntry: Record "Job WIP Entry";
        JobTask: Record "Job Task";
    begin
        JobWIPEntry.SetRange("Job No.", JobNo);
        if not JobWIPEntry.IsEmpty then
            Error(CannotModifyAssociatedEntriesErr, JobTask.TableCaption);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcUsageTotalCostCosts(var JobTask: Record "Job Task")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcPercentageOfCompletion(var JobTask: Record "Job Task"; JobWIPTotal: Record "Job WIP Total"; var JobWIPTotalChanged: Boolean; var WIPAmount: Decimal; var RecognizedAllocationPercentage: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateJobWIPTotalOnAfterUpdateJobWIPTotal(var JobTask: Record "Job Task"; var JobWIPTotal: Record "Job WIP Total")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertWIPGLOnBeforeGenJnPostLine(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;
}

