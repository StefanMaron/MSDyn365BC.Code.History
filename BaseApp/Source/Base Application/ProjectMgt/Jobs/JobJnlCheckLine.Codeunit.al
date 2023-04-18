codeunit 1011 "Job Jnl.-Check Line"
{
    TableNo = "Job Journal Line";

    trigger OnRun()
    begin
        RunCheck(Rec);
    end;

    var
        Location: Record Location;
        DimMgt: Codeunit DimensionManagement;
        TimeSheetMgt: Codeunit "Time Sheet Management";
        CalledFromInvtPutawayPick: Boolean;

        Text000: Label 'cannot be a closing date.';
        Text001: Label 'is not within your range of allowed posting dates.';
        CombinationBlockedErr: Label 'The combination of dimensions used in %1 %2, %3, %4 is blocked. %5.', Comment = '%1 = table name, %2 = template name, %3 = batch name, %4 = line no., %5 - error text';
        DimensionCausedErr: Label 'A dimension used in %1 %2, %3, %4 has caused an error. %5.', Comment = '%1 = table name, %2 = template name, %3 = batch name, %4 = line no., %5 - error text';
        Text004: Label 'You must post more usage of %1 %2 in %3 %4 before you can post job journal %5 %6 = %7.', Comment = '%1=Item;%2=JobJnlline."No.";%3=Job;%4=JobJnlline."Job No.";%5=JobJnlline."Journal Batch Name";%6="Line No";%7=JobJnlline."Line No."';
        WhseRemainQtyPickedErr: Label 'You cannot post usage for job number %1 with job planning line %2 because a quantity of %3 remains to be picked.', Comment = '%1 = 12345, %2 = 1000, %3 = 5';

    procedure RunCheck(var JobJnlLine: Record "Job Journal Line")
    begin
        OnBeforeRunCheck(JobJnlLine);

        with JobJnlLine do begin
            if EmptyLine() then
                exit;

            TestJobJnlLine(JobJnlLine);

            TestJobStatusOpen(JobJnlLine);

            CheckPostingDate(JobJnlLine);

            CheckDocumentDate(JobJnlLine);

            if "Time Sheet No." <> '' then
                TimeSheetMgt.CheckJobJnlLine(JobJnlLine);

            CheckDim(JobJnlLine);

            CheckItemQuantityAndBinCode(JobJnlLine);

            TestJobJnlLineChargeable(JobJnlLine);

            CheckWhseQtyPicked(JobJnlLine);
        end;

        OnAfterRunCheck(JobJnlLine);
    end;

    internal procedure SetCalledFromInvtPutawayPick(NewCalledFromInvtPutawayPick: Boolean)
    begin
        CalledFromInvtPutawayPick := NewCalledFromInvtPutawayPick;
    end;

    local procedure CheckItemQuantityAndBinCode(var JobJournalLine: Record "Job Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckItemQuantityAndBinCode(JobJournalLine, IsHandled);
        if IsHandled then
            exit;

        if JobJournalLine.Type <> JobJournalLine.Type::Item then
            exit;

        if (JobJournalLine."Quantity (Base)" < 0) and (JobJournalLine."Entry Type" = JobJournalLine."Entry Type"::Usage) then
            CheckItemQuantityJobJnl(JobJournalLine);
        GetLocation(JobJournalLine."Location Code");
        if Location."Directed Put-away and Pick" then
            JobJournalLine.TestField("Bin Code", '', ErrorInfo.Create())
        else
            if Location."Bin Mandatory" and JobJournalLine.IsInventoriableItem() then
                JobJournalLine.TestField("Bin Code", ErrorInfo.Create());
    end;

    local procedure TestJobStatusOpen(var JobJnlLine: Record "Job Journal Line")
    var
        Job: Record Job;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnRunCheckOnBeforeTestFieldJobStatus(IsHandled, JobJnlLine);
        if IsHandled then
            exit;

        Job.Get(JobJnlLine."Job No.");
        Job.TestField(Status, Job.Status::Open, ErrorInfo.Create());
    end;

    local procedure TestJobJnlLineChargeable(JobJnlLine: Record "Job Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestChargeable(JobJnlLine, IsHandled);
        if IsHandled then
            exit;

        with JobJnlLine do
            if "Line Type" in ["Line Type"::Billable, "Line Type"::"Both Budget and Billable"] then
                TestField(Chargeable, true, ErrorInfo.Create());
    end;

    local procedure CheckDocumentDate(JobJnlLine: Record "Job Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckDocumentDate(JobJnlLine, IsHandled);
        if IsHandled then
            exit;

        with JobJnlLine do
            if ("Document Date" <> 0D) and ("Document Date" <> NormalDate("Document Date")) then
                FieldError("Document Date", ErrorInfo.Create(Text000, true));
    end;

    local procedure CheckPostingDate(JobJnlLine: Record "Job Journal Line")
    var
        UserSetupManagement: Codeunit "User Setup Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPostingDate(JobJnlLine, IsHandled);
        if IsHandled then
            exit;

        with JobJnlLine do begin
            if NormalDate("Posting Date") <> "Posting Date" then
                FieldError("Posting Date", ErrorInfo.Create(Text000, true));
            if not UserSetupManagement.IsPostingDateValid("Posting Date") then
                FieldError("Posting Date", ErrorInfo.Create(Text001, true));
        end;
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    local procedure CheckDim(JobJnlLine: Record "Job Journal Line")
    var
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckDim(JobJnlLine, IsHandled);
        if IsHandled then
            exit;

        with JobJnlLine do begin
            if not DimMgt.CheckDimIDComb("Dimension Set ID") then
                Error(
                  CombinationBlockedErr,
                  TableCaption, "Journal Template Name", "Journal Batch Name", "Line No.",
                  DimMgt.GetDimCombErr());

            TableID[1] := DATABASE::Job;
            No[1] := "Job No.";
            TableID[2] := DimMgt.TypeToTableID2(Type.AsInteger());
            No[2] := "No.";
            TableID[3] := DATABASE::"Resource Group";
            No[3] := "Resource Group No.";
            TableID[4] := Database::Location;
            No[4] := "Location Code";
            OnCheckDimOnAfterCreateDimTableID(JobJnlLine, TableID, No);

            if not DimMgt.CheckDimValuePosting(TableID, No, "Dimension Set ID") then begin
                if "Line No." <> 0 then
                    Error(
                        ErrorInfo.Create(
                            StrSubstNo(
                                DimensionCausedErr,
                                TableCaption, "Journal Template Name", "Journal Batch Name", "Line No.",
                                DimMgt.GetDimValuePostingErr()),
                            true));
                Error(ErrorInfo.Create(DimMgt.GetDimValuePostingErr(), true));
            end;
        end;
    end;

    local procedure CheckItemQuantityJobJnl(var JobJnlline: Record "Job Journal Line")
    var
        Item: Record Item;
        Job: Record Job;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckItemQuantityJobJnl(JobJnlline, IsHandled);
        if IsHandled then
            exit;

        if JobJnlline.IsNonInventoriableItem() then
            exit;

        Job.Get(JobJnlline."Job No.");
        if (Job.GetQuantityAvailable(JobJnlline."No.", JobJnlline."Location Code", JobJnlline."Variant Code", 0, 2) +
            JobJnlline."Quantity (Base)") < 0
        then
            Error(
                ErrorInfo.Create(
                    StrSubstNo(
                        Text004, Item.TableCaption(), JobJnlline."No.", Job.TableCaption(),
                        JobJnlline."Job No.", JobJnlline."Journal Batch Name",
                        JobJnlline.FieldCaption("Line No."), JobJnlline."Line No."),
                    true));
    end;

    local procedure CheckWhseQtyPicked(var JobJournalLine: Record "Job Journal Line")
    var
        JobPlanningLine: Record "Job Planning Line";
        WhseValidateSourceLine: Codeunit "Whse. Validate Source Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckWhseQtyPicked(JobJournalLine, IsHandled);
        if IsHandled then
            exit;

        if WhseValidateSourceLine.IsWhsePickRequiredForJobJnlLine(JobJournalLine) or WhseValidateSourceLine.IsInventoryPickRequiredForJobJnlLine(JobJournalLine) then
            if not CalledFromInvtPutawayPick then
                if JobPlanningLine.Get(JobJournalLine."Job No.", JobJournalLine."Job Task No.", JobJournalLine."Job Planning Line No.") and (JobPlanningLine."Qty. Picked" - JobPlanningLine."Qty. Posted" < JobJournalLine.Quantity) then
                    JobPlanningLine.FieldError("Qty. Picked", ErrorInfo.Create(StrSubstNo(WhseRemainQtyPickedErr, JobPlanningLine."Job No.", JobPlanningLine."Line No.", JobJournalLine.Quantity + JobPlanningLine."Qty. Posted" - JobPlanningLine."Qty. Picked"), true));
    end;

    local procedure TestJobJnlLine(JobJournalLine: Record "Job Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestJobJnlLine(JobJournalLine, IsHandled);
        if IsHandled then
            exit;

        with JobJournalLine do begin
            TestField("Job No.", ErrorInfo.Create());
            TestField("Job Task No.", ErrorInfo.Create());
            TestField("No.", ErrorInfo.Create());
            TestField("Posting Date", ErrorInfo.Create());
            TestField(Quantity, ErrorInfo.Create());
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRunCheck(var JobJnlLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDocumentDate(var JobJnlLine: Record "Job Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPostingDate(var JobJnlLine: Record "Job Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWhseQtyPicked(var JobJournalLine: Record "Job Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunCheck(var JobJnlLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDim(var JobJnlLine: Record "Job Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemQuantityAndBinCode(JobJournalLine: Record "Job Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemQuantityJobJnl(var JobJnlLine: Record "Job Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestJobJnlLine(JobJournalLine: Record "Job Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestChargeable(JobJournalLine: Record "Job Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckDimOnAfterCreateDimTableID(JobJournalLine: Record "Job Journal Line"; var TableID: array[10] of Integer; var No: array[10] of Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunCheckOnBeforeTestFieldJobStatus(var IsHandled: Boolean; var JobJnlLine: Record "Job Journal Line")
    begin
    end;
}

