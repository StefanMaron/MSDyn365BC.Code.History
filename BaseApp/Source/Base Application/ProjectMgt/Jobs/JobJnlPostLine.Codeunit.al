codeunit 1012 "Job Jnl.-Post Line"
{
    Permissions = TableData "Job Ledger Entry" = rimd,
                  TableData "Job Register" = rimd,
                  TableData "Value Entry" = rimd;
    TableNo = "Job Journal Line";

    trigger OnRun()
    begin
        GetGLSetup();
        RunWithCheck(Rec);
    end;

    var
        Cust: Record Customer;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobJnlLine: Record "Job Journal Line";
        JobJnlLine2: Record "Job Journal Line";
        ItemJnlLine: Record "Item Journal Line";
        JobReg: Record "Job Register";
        GLSetup: Record "General Ledger Setup";
        CurrExchRate: Record "Currency Exchange Rate";
        Currency: Record Currency;
        Location: Record Location;
        Item: Record Item;
        JobJnlCheckLine: Codeunit "Job Jnl.-Check Line";
        ResJnlPostLine: Codeunit "Res. Jnl.-Post Line";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        JobPostLine: Codeunit "Job Post-Line";
        WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line";
        UOMMgt: Codeunit "Unit of Measure Management";
        GLSetupRead: Boolean;
        CalledFromInvtPutawayPick: Boolean;
        NextEntryNo: Integer;
        GLEntryNo: Integer;

    procedure RunWithCheck(var JobJnlLine2: Record "Job Journal Line"): Integer
    var
        JobLedgEntryNo: Integer;
    begin
        OnBeforeRunWithCheck(JobJnlLine2);

        JobJnlLine.Copy(JobJnlLine2);
        JobLedgEntryNo := Code(true);
        JobJnlLine2 := JobJnlLine;
        exit(JobLedgEntryNo);
    end;

    local procedure "Code"(CheckLine: Boolean): Integer
    var
        JobLedgEntry: Record "Job Ledger Entry";
        JobLedgEntryNo: Integer;
        ShouldPostUsage: Boolean;
    begin
        OnBeforeCode(JobJnlLine);

        GetGLSetup();

        with JobJnlLine do begin
            if EmptyLine() then
                exit;

            if CheckLine then begin
                JobJnlCheckLine.SetCalledFromInvtPutawayPick(CalledFromInvtPutawayPick);
                JobJnlCheckLine.RunCheck(JobJnlLine);
            end;

            if JobLedgEntry."Entry No." = 0 then begin
                JobLedgEntry.LockTable();
                NextEntryNo := JobLedgEntry.GetLastEntryNo() + 1;
            end;

            if "Document Date" = 0D then
                "Document Date" := "Posting Date";

            OnBeforeCreateJobRegister(JobJnlLine);
            if JobReg."No." = 0 then begin
                JobReg.LockTable();
                if (not JobReg.FindLast()) or (JobReg."To Entry No." <> 0) then begin
                    JobReg.Init();
                    JobReg."No." := JobReg."No." + 1;
                    JobReg."From Entry No." := NextEntryNo;
                    JobReg."To Entry No." := NextEntryNo;
                    JobReg."Creation Date" := Today;
                    JobReg."Creation Time" := Time;
                    JobReg."Source Code" := "Source Code";
                    JobReg."Journal Batch Name" := "Journal Batch Name";
                    JobReg."User ID" := CopyStr(UserId(), 1, MaxStrLen(JobReg."User ID"));
                    JobReg.Insert();
                end;
            end;

            GetAndCheckJob();

            JobJnlLine2 := JobJnlLine;

            OnAfterCopyJobJnlLine(JobJnlLine, JobJnlLine2);

            JobJnlLine2."Source Currency Total Cost" := 0;
            JobJnlLine2."Source Currency Total Price" := 0;
            JobJnlLine2."Source Currency Line Amount" := 0;

            GetGLSetup();
            if (GLSetup."Additional Reporting Currency" <> '') and
               (JobJnlLine2."Source Currency Code" <> GLSetup."Additional Reporting Currency")
            then
                UpdateJobJnlLineSourceCurrencyAmounts(JobJnlLine2);

            ShouldPostUsage := JobJnlLine2."Entry Type" = JobJnlLine2."Entry Type"::Usage;
            OnCodeOnAfterCalcShouldPostUsage(JobJnlLine2, ShouldPostUsage, JobLedgEntryNo);
            if ShouldPostUsage then
                case Type of
                    Type::Resource:
                        JobLedgEntryNo := PostResource(JobJnlLine2);
                    Type::Item:
                        JobLedgEntryNo := PostItem(JobJnlLine);
                    Type::"G/L Account":
                        JobLedgEntryNo := CreateJobLedgEntry(JobJnlLine2);
                end
            else
                JobLedgEntryNo := CreateJobLedgEntry(JobJnlLine2);
        end;

        OnAfterRunCode(JobJnlLine2, JobLedgEntryNo, JobReg, NextEntryNo);

        exit(JobLedgEntryNo);
    end;

    local procedure GetAndCheckJob()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetAndCheckJob(JobJnlLine, IsHandled);
        if IsHandled then
            exit;

        Job.Get(JobJnlLine."Job No.");
        CheckJob(JobJnlLine, Job);
    end;

    internal procedure SetCalledFromInvtPutawayPick(NewCalledFromInvtPutawayPick: Boolean)
    begin
        CalledFromInvtPutawayPick := NewCalledFromInvtPutawayPick;
    end;

    local procedure CheckJob(var JobJnlLine: Record "Job Journal Line"; Job: Record Job)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckJob(JobJnlLine, Job, IsHandled, JobReg, NextEntryNo);
        if IsHandled then
            exit;

        with JobJnlLine do begin
            Job.TestBlocked();
            Job.TestField("Bill-to Customer No.");
            Cust.Get(Job."Bill-to Customer No.");
            TestField("Currency Code", Job."Currency Code");
            IsHandled := false;
            OnCheckJobOnBeforeTestJobTaskType(JobJnlLine, IsHandled);
            if not IsHandled then begin
                JobTask.Get("Job No.", "Job Task No.");
                JobTask.TestField("Job Task Type", JobTask."Job Task Type"::Posting);
            end;
        end;
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetupRead then
            GLSetup.Get();
        GLSetupRead := true;
    end;

    procedure CreateJobLedgEntry(JobJnlLine2: Record "Job Journal Line"): Integer
    var
        ResLedgEntry: Record "Res. Ledger Entry";
        JobLedgEntry: Record "Job Ledger Entry";
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
        JobTransferLine: Codeunit "Job Transfer Line";
        JobLinkUsage: Codeunit "Job Link Usage";
        JobLedgEntryNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateJobLedgEntry(JobJnlLine2, IsHandled, JobLedgEntryNo);
        if IsHandled then
            exit(JobLedgEntryNo);

        SetCurrency(JobJnlLine2);

        JobLedgEntry.Init();
        JobTransferLine.FromJnlLineToLedgEntry(JobJnlLine2, JobLedgEntry);

        IsHandled := false;
        OnCreateJobLedgEntryOnBeforeAssignQtyCostPrice(JobLedgEntry, JobJnlLine2, IsHandled);
        if not IsHandled then
            if JobLedgEntry."Entry Type" = JobLedgEntry."Entry Type"::Sale then begin
                JobLedgEntry.Quantity := -JobJnlLine2.Quantity;
                JobLedgEntry."Quantity (Base)" := -JobJnlLine2."Quantity (Base)";
                JobLedgEntry."Total Cost (LCY)" := -JobJnlLine2."Total Cost (LCY)";
                JobLedgEntry."Total Cost" := -JobJnlLine2."Total Cost";
                JobLedgEntry."Total Price (LCY)" := -JobJnlLine2."Total Price (LCY)";
                JobLedgEntry."Total Price" := -JobJnlLine2."Total Price";
                JobLedgEntry."Line Amount (LCY)" := -JobJnlLine2."Line Amount (LCY)";
                JobLedgEntry."Line Amount" := -JobJnlLine2."Line Amount";
                JobLedgEntry."Line Discount Amount (LCY)" := -JobJnlLine2."Line Discount Amount (LCY)";
                JobLedgEntry."Line Discount Amount" := -JobJnlLine2."Line Discount Amount";
            end else begin
                JobLedgEntry.Quantity := JobJnlLine2.Quantity;
                JobLedgEntry."Quantity (Base)" := JobJnlLine2."Quantity (Base)";
                JobLedgEntry."Total Cost (LCY)" := JobJnlLine2."Total Cost (LCY)";
                JobLedgEntry."Total Cost" := JobJnlLine2."Total Cost";
                JobLedgEntry."Total Price (LCY)" := JobJnlLine2."Total Price (LCY)";
                JobLedgEntry."Total Price" := JobJnlLine2."Total Price";
                JobLedgEntry."Line Amount (LCY)" := JobJnlLine2."Line Amount (LCY)";
                JobLedgEntry."Line Amount" := JobJnlLine2."Line Amount";
                JobLedgEntry."Line Discount Amount (LCY)" := JobJnlLine2."Line Discount Amount (LCY)";
                JobLedgEntry."Line Discount Amount" := JobJnlLine2."Line Discount Amount";
            end;

        JobLedgEntry."Additional-Currency Total Cost" := -JobLedgEntry."Additional-Currency Total Cost";
        JobLedgEntry."Add.-Currency Total Price" := -JobLedgEntry."Add.-Currency Total Price";
        JobLedgEntry."Add.-Currency Line Amount" := -JobLedgEntry."Add.-Currency Line Amount";

        JobLedgEntry."Entry No." := NextEntryNo;
        JobLedgEntry."No. Series" := JobJnlLine2."Posting No. Series";
        JobLedgEntry."Original Unit Cost (LCY)" := JobLedgEntry."Unit Cost (LCY)";
        JobLedgEntry."Original Total Cost (LCY)" := JobLedgEntry."Total Cost (LCY)";
        JobLedgEntry."Original Unit Cost" := JobLedgEntry."Unit Cost";
        JobLedgEntry."Original Total Cost" := JobLedgEntry."Total Cost";
        JobLedgEntry."Original Total Cost (ACY)" := JobLedgEntry."Additional-Currency Total Cost";
        JobLedgEntry."Dimension Set ID" := JobJnlLine2."Dimension Set ID";

        with JobJnlLine2 do
            case Type of
                Type::Resource:
                    if "Entry Type" = "Entry Type"::Usage then
                        if ResLedgEntry.FindLast() then begin
                            JobLedgEntry."Ledger Entry Type" := JobLedgEntry."Ledger Entry Type"::Resource;
                            JobLedgEntry."Ledger Entry No." := ResLedgEntry."Entry No.";
                        end;
                Type::Item:
                    begin
                        JobLedgEntry."Ledger Entry Type" := "Ledger Entry Type"::Item;
                        JobLedgEntry."Ledger Entry No." := "Ledger Entry No.";
                        JobLedgEntry.CopyTrackingFromJobJnlLine(JobJnlLine2);
                    end;
                Type::"G/L Account":
                    begin
                        JobLedgEntry."Ledger Entry Type" := JobLedgEntry."Ledger Entry Type"::" ";
                        if GLEntryNo > 0 then begin
                            JobLedgEntry."Ledger Entry Type" := JobLedgEntry."Ledger Entry Type"::"G/L Account";
                            JobLedgEntry."Ledger Entry No." := GLEntryNo;
                            GLEntryNo := 0;
                        end;
                    end;
            end;

        OnCreateJobLedgerEntryOnAfterAssignLedgerEntryTypeAndNo(JobLedgEntry, JobJnlLine2, GLEntryNo);

        if JobLedgEntry."Entry Type" = JobLedgEntry."Entry Type"::Sale then
            JobLedgEntry.CopyTrackingFromJobJnlLine(JobJnlLine2);

        OnBeforeJobLedgEntryInsert(JobLedgEntry, JobJnlLine2);
        JobLedgEntry.Insert(true);
        OnAfterJobLedgEntryInsert(JobLedgEntry, JobJnlLine2);

        JobReg."To Entry No." := NextEntryNo;
        JobReg.Modify();

        JobLedgEntryNo := JobLedgEntry."Entry No.";
        IsHandled := false;
        OnBeforeApplyUsageLink(JobLedgEntry, JobJnlLine2, IsHandled);
        if not IsHandled then
            if JobLedgEntry."Entry Type" = JobLedgEntry."Entry Type"::Usage then begin
                // Usage Link should be applied if it is enabled for the job,
                // if a Job Planning Line number is defined or if it is enabled for a Job Planning Line.
                Job.Get(JobLedgEntry."Job No.");
                if Job."Apply Usage Link" or
                   (JobJnlLine2."Job Planning Line No." <> 0) or
                   JobLinkUsage.FindMatchingJobPlanningLine(JobPlanningLine, JobLedgEntry)
                then
                    JobLinkUsage.ApplyUsage(JobLedgEntry, JobJnlLine2, CalledFromInvtPutawayPick)
                else
                    JobPostLine.InsertPlLineFromLedgEntry(JobLedgEntry)
            end;

        NextEntryNo := NextEntryNo + 1;
        OnAfterApplyUsageLink(JobLedgEntry);

        exit(JobLedgEntryNo);
    end;

    local procedure CreateJobLedgEntryFromPostItem(JobJournalLine: Record "Job Journal Line"; ValueEntry: Record "Value Entry"): Integer
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateJobLedgEntryFromPostItem(JobJournalLine, ValueEntry, IsHandled);
        if IsHandled then
            exit(0);

        exit(CreateJobLedgEntry(JobJournalLine))
    end;

    local procedure SetCurrency(JobJnlLine: Record "Job Journal Line")
    begin
        if JobJnlLine."Currency Code" = '' then begin
            Clear(Currency);
            Currency.InitRoundingPrecision()
        end else begin
            Currency.Get(JobJnlLine."Currency Code");
            Currency.TestField("Amount Rounding Precision");
            Currency.TestField("Unit-Amount Rounding Precision");
        end;
    end;

    local procedure PostItem(var JobJnlLine: Record "Job Journal Line") JobLedgEntryNo: Integer
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        JobLedgEntry2: Record "Job Ledger Entry";
        JobPlanningLine: Record "Job Planning Line";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        ItemJnlLine2: Record "Item Journal Line";
        JobJnlLineReserve: Codeunit "Job Jnl. Line-Reserve";
        SkipJobLedgerEntry: Boolean;
        ApplyToJobContractEntryNo: Boolean;
        TempRemainingQty: Decimal;
        RemainingAmount: Decimal;
        RemainingAmountLCY: Decimal;
        RemainingQtyToTrack: Decimal;
        IsHandled: Boolean;
    begin
        with JobJnlLine do begin
            if not "Job Posting Only" then begin
                IsHandled := false;
                OnBeforeItemPosting(JobJnlLine2, NextEntryNo, IsHandled);
                if not IsHandled then begin
                    InitItemJnlLine();

                    //Do not transfer remaining quantity when posting from Inventory Pick as the entry is created during posting process of Item through Item Jnl Line.
                    JobJnlLineReserve.TransJobJnlLineToItemJnlLine(JobJnlLine2, ItemJnlLine, ItemJnlLine."Quantity (Base)", CalledFromInvtPutawayPick);

                    ApplyToJobContractEntryNo := false;
                    if JobPlanningLine.Get("Job No.", "Job Task No.", "Job Planning Line No.") then
                        ApplyToJobContractEntryNo := true
                    else
                        if JobPlanningReservationExists(JobJnlLine2."No.", JobJnlLine2."Job No.") then
                            if ApplyToMatchingJobPlanningLine(JobJnlLine2, JobPlanningLine) then
                                ApplyToJobContractEntryNo := true;

                    if ApplyToJobContractEntryNo then
                        ItemJnlLine."Job Contract Entry No." := JobPlanningLine."Job Contract Entry No.";

                    OnPostItemOnBeforeAssignItemJnlLine(JobJnlLine, JobJnlLine2, ItemJnlLine, JobPlanningLine);

                    ItemLedgEntry.LockTable();
                    ItemJnlLine2 := ItemJnlLine;
                    ItemJnlPostLine.RunWithCheck(ItemJnlLine);
                    ItemJnlPostLine.CollectTrackingSpecification(TempTrackingSpecification);

                    if JobJnlLine.IsInventoriableItem() then
                        PostWhseJnlLine(ItemJnlLine2, ItemJnlLine2.Quantity, ItemJnlLine2."Quantity (Base)", TempTrackingSpecification);
                end;
            end;

            OnPostItemOnBeforeGetJobConsumptionValueEntry(JobJnlLine);
            if GetJobConsumptionValueEntry(ValueEntry, JobJnlLine) then begin
                RemainingAmount := JobJnlLine2."Line Amount";
                RemainingAmountLCY := JobJnlLine2."Line Amount (LCY)";
                RemainingQtyToTrack := JobJnlLine2.Quantity;
                repeat
                    SkipJobLedgerEntry := false;
                    if ItemLedgEntry.Get(ValueEntry."Item Ledger Entry No.") then begin
                        JobLedgEntry2.SetRange("Ledger Entry Type", JobLedgEntry2."Ledger Entry Type"::Item);
                        JobLedgEntry2.SetRange("Ledger Entry No.", ItemLedgEntry."Entry No.");
                        // The following code is only to secure that JLEs created at receipt in version 6.0 or earlier,
                        // are not created again at point of invoice (6.0 SP1 and newer).
                        if JobLedgEntry2.FindFirst() and (JobLedgEntry2.Quantity = -ItemLedgEntry.Quantity) then
                            SkipJobLedgerEntry := true
                        else begin
                            JobJnlLine2.CopyTrackingFromItemLedgEntry(ItemLedgEntry);
                            OnPostItemOnAfterApplyItemTracking(JobJnlLine2, ItemLedgEntry, JobLedgEntry2, SkipJobLedgerEntry);
                        end;
                    end;
                    OnPostItemOnAfterSetSkipJobLedgerEntry(JobJnlLine2, ItemLedgEntry, SkipJobLedgerEntry);
                    if not SkipJobLedgerEntry then begin
                        TempRemainingQty := JobJnlLine2."Remaining Qty.";
                        JobJnlLine2.Quantity := -ValueEntry."Invoiced Quantity" / "Qty. per Unit of Measure";
                        JobJnlLine2."Quantity (Base)" :=
                          Round(JobJnlLine2.Quantity * "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
                        Currency.Initialize("Currency Code");

                        OnPostItemOnBeforeUpdateTotalAmounts(JobJnlLine2, ItemLedgEntry, ValueEntry);

                        UpdateJobJnlLineTotalAmounts(JobJnlLine2, Currency."Amount Rounding Precision");
                        UpdateJobJnlLineAmount(
                          JobJnlLine2, RemainingAmount, RemainingAmountLCY, RemainingQtyToTrack, Currency."Amount Rounding Precision");

                        JobJnlLine2.Validate("Remaining Qty.", TempRemainingQty);
                        JobJnlLine2."Ledger Entry Type" := "Ledger Entry Type"::Item;
                        JobJnlLine2."Ledger Entry No." := ValueEntry."Item Ledger Entry No.";
                        JobLedgEntryNo := CreateJobLedgEntryFromPostItem(JobJnlLine2, ValueEntry);
                        ValueEntry."Job Ledger Entry No." := JobLedgEntryNo;
                        ModifyValueEntry(ValueEntry);
                    end;
                until ValueEntry.Next() = 0;
            end;
        end;
        OnAfterPostItem(JobJnlLine2, ItemJnlPostLine);
    end;

    local procedure ModifyValueEntry(var ValueEntry: Record "Value Entry")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeModifyValueEntry(ValueEntry, JobJnlLine2, IsHandled);
        if IsHandled then
            exit;

        ValueEntry.Modify(true);
    end;

    local procedure PostResource(var JobJnlLine2: Record "Job Journal Line") EntryNo: Integer
    var
        ResJnlLine: Record "Res. Journal Line";
        ResLedgEntry: Record "Res. Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostResource(JobJnlLine, JobJnlLine2, EntryNo, IsHandled);
        if IsHandled then
            exit(EntryNo);

        with ResJnlLine do begin
            Init();
            CopyFromJobJnlLine(JobJnlLine2);
            ResLedgEntry.LockTable();
            ResJnlPostLine.RunWithCheck(ResJnlLine);
            UpdateJobJnlLineResourceGroupNo(JobJnlLine2, ResJnlLine);
            exit(CreateJobLedgEntry(JobJnlLine2));
        end;
    end;

    local procedure UpdateJobJnlLineResourceGroupNo(var JobJnlLine2: Record "Job Journal Line"; ResJnlLine: Record "Res. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateJobJnlLineResourceGroupNo(JobJnlLine2, ResJnlLine, IsHandled);
        if IsHandled then
            exit;

        JobJnlLine2."Resource Group No." := ResJnlLine."Resource Group No.";
    end;

    local procedure PostWhseJnlLine(ItemJnlLine: Record "Item Journal Line"; OriginalQuantity: Decimal; OriginalQuantityBase: Decimal; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
        TempWarehouseJournalLine: Record "Warehouse Journal Line" temporary;
        ItemTrackingManagement: Codeunit "Item Tracking Management";
        WMSManagement: Codeunit "WMS Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostWhseJnlLine(ItemJnlLine, OriginalQuantity, OriginalQuantityBase, TempTrackingSpecification, IsHandled);
        if IsHandled then
            exit;

        with ItemJnlLine do begin
            if "Entry Type" in ["Entry Type"::Consumption, "Entry Type"::Output] then
                exit;

            Quantity := OriginalQuantity;
            "Quantity (Base)" := OriginalQuantityBase;
            GetLocation("Location Code");
            if Location."Bin Mandatory" then
                if WMSManagement.CreateWhseJnlLine(ItemJnlLine, 0, WarehouseJournalLine, false) then begin
                    SetWhseDocForPicks(WarehouseJournalLine, Location.Code);
                    TempTrackingSpecification.ModifyAll("Source Type", DATABASE::"Job Journal Line");
                    ItemTrackingManagement.SplitWhseJnlLine(WarehouseJournalLine, TempWarehouseJournalLine, TempTrackingSpecification, false);
                    if TempWarehouseJournalLine.Find('-') then
                        repeat
                            WMSManagement.CheckWhseJnlLine(TempWarehouseJournalLine, 1, 0, false);
                            WhseJnlRegisterLine.RegisterWhseJnlLine(TempWarehouseJournalLine);
                        until TempWarehouseJournalLine.Next() = 0;
                end;
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

    procedure SetGLEntryNo(GLEntryNo2: Integer)
    begin
        GLEntryNo := GLEntryNo2;
    end;

    local procedure InitItemJnlLine()
    begin
        with ItemJnlLine do begin
            Init();
            CopyFromJobJnlLine(JobJnlLine2);

            "Source Type" := "Source Type"::Customer;
            "Source No." := Job."Bill-to Customer No.";

            Item.Get(JobJnlLine2."No.");
            "Inventory Posting Group" := Item."Inventory Posting Group";
            "Item Category Code" := Item."Item Category Code";
        end;
    end;

    local procedure UpdateJobJnlLineTotalAmounts(var JobJnlLineToUpdate: Record "Job Journal Line"; AmtRoundingPrecision: Decimal)
    begin
        with JobJnlLineToUpdate do begin
            "Total Cost" := Round("Unit Cost" * Quantity, AmtRoundingPrecision);
            "Total Cost (LCY)" := Round("Unit Cost (LCY)" * Quantity, GLSetup."Amount Rounding Precision");
            "Total Price" := Round("Unit Price" * Quantity, AmtRoundingPrecision);
            "Total Price (LCY)" := Round("Unit Price (LCY)" * Quantity, GLSetup."Amount Rounding Precision");
        end;
    end;

    local procedure UpdateJobJnlLineAmount(var JobJnlLineToUpdate: Record "Job Journal Line"; var RemainingAmount: Decimal; var RemainingAmountLCY: Decimal; var RemainingQtyToTrack: Decimal; AmtRoundingPrecision: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateJobJnlLineAmount(JobJnlLineToUpdate, RemainingAmount, RemainingAmountLCY, RemainingQtyToTrack, AmtRoundingPrecision, IsHandled);
        if IsHandled then
            exit;

        with JobJnlLineToUpdate do begin
            "Line Amount" := Round(RemainingAmount * Quantity / RemainingQtyToTrack, AmtRoundingPrecision);
            "Line Amount (LCY)" := Round(RemainingAmountLCY * Quantity / RemainingQtyToTrack, AmtRoundingPrecision);

            RemainingAmount -= "Line Amount";
            RemainingAmountLCY -= "Line Amount (LCY)";
            RemainingQtyToTrack -= Quantity;
        end;
    end;

    local procedure UpdateJobJnlLineSourceCurrencyAmounts(var JobJnlLine: Record "Job Journal Line")
    begin
        with JobJnlLine do begin
            Currency.Get(GLSetup."Additional Reporting Currency");
            Currency.TestField("Amount Rounding Precision");
            "Source Currency Total Cost" :=
              Round(
                CurrExchRate.ExchangeAmtLCYToFCY(
                  "Posting Date",
                  GLSetup."Additional Reporting Currency", "Total Cost (LCY)",
                  CurrExchRate.ExchangeRate(
                    "Posting Date", GLSetup."Additional Reporting Currency")),
                Currency."Amount Rounding Precision");
            "Source Currency Total Price" :=
              Round(
                CurrExchRate.ExchangeAmtLCYToFCY(
                  "Posting Date",
                  GLSetup."Additional Reporting Currency", "Total Price (LCY)",
                  CurrExchRate.ExchangeRate(
                    "Posting Date", GLSetup."Additional Reporting Currency")),
                Currency."Amount Rounding Precision");
            "Source Currency Line Amount" :=
              Round(
                CurrExchRate.ExchangeAmtLCYToFCY(
                  "Posting Date",
                  GLSetup."Additional Reporting Currency", "Line Amount (LCY)",
                  CurrExchRate.ExchangeRate(
                    "Posting Date", GLSetup."Additional Reporting Currency")),
                Currency."Amount Rounding Precision");
        end;
    end;

    local procedure JobPlanningReservationExists(ItemNo: Code[20]; JobNo: Code[20]) Result: Boolean
    var
        ReservationEntry: Record "Reservation Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeJobPlanningReservationExists(ItemNo, JobNo, Result, IsHandled);
        if IsHandled then
            exit(Result);

        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Source Type", DATABASE::"Job Planning Line");
        ReservationEntry.SetRange("Source Subtype", Job.Status::Open);
        ReservationEntry.SetRange("Source ID", JobNo);
        Result := not ReservationEntry.IsEmpty();
    end;

    local procedure GetJobConsumptionValueEntry(var ValueEntry: Record "Value Entry"; JobJournalLine: Record "Job Journal Line") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetJobConsumptionValueEntry(JobJournalLine, Result, IsHandled, ValueEntry);
        if IsHandled then
            exit(Result);

        with JobJournalLine do begin
            ValueEntry.SetCurrentKey("Job No.", "Job Task No.", "Document No.");
            ValueEntry.SetRange("Item No.", "No.");
            ValueEntry.SetRange("Job No.", "Job No.");
            ValueEntry.SetRange("Job Task No.", "Job Task No.");
            ValueEntry.SetRange("Document No.", "Document No.");
            ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::"Negative Adjmt.");
            ValueEntry.SetRange("Job Ledger Entry No.", 0);
            OnGetJobConsumptionValueEntryFilter(ValueEntry, JobJnlLine, JobJournalLine);
        end;
        exit(ValueEntry.FindSet());
    end;

    local procedure ApplyToMatchingJobPlanningLine(var JobJnlLine: Record "Job Journal Line"; var JobPlanningLine: Record "Job Planning Line"): Boolean
    var
        Job: Record Job;
        JobLedgEntry: Record "Job Ledger Entry";
        JobTransferLine: Codeunit "Job Transfer Line";
        JobLinkUsage: Codeunit "Job Link Usage";
    begin
        if JobLedgEntry."Entry Type" <> JobLedgEntry."Entry Type"::Usage then
            exit(false);

        Job.Get(JobJnlLine."Job No.");
        JobLedgEntry.Init();
        JobTransferLine.FromJnlLineToLedgEntry(JobJnlLine, JobLedgEntry);
        JobLedgEntry.Quantity := JobJnlLine.Quantity;
        JobLedgEntry."Quantity (Base)" := JobJnlLine."Quantity (Base)";

        if JobLinkUsage.FindMatchingJobPlanningLine(JobPlanningLine, JobLedgEntry) then begin
            JobJnlLine.Validate("Job Planning Line No.", JobPlanningLine."Line No.");
            JobJnlLine.Modify(true);
            exit(true);
        end;
        exit(false);
    end;

    local procedure SetWhseDocForPicks(var WarehouseJournalLine: Record "Warehouse Journal Line"; LocationCode: Code[10])
    var
        WhseLocation: Record Location;
    begin
        if WhseLocation.RequirePicking(LocationCode) then
            WarehouseJournalLine.SetWhseDocument(WarehouseJournalLine."Whse. Document Type"::Job, ItemJnlLine."Job No.", ItemJnlLine."Job Contract Entry No.");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterApplyUsageLink(var JobLedgerEntry: Record "Job Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyJobJnlLine(var JobJournalLine: Record "Job Journal Line"; var JobJournalLine2: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterJobLedgEntryInsert(var JobLedgerEntry: Record "Job Ledger Entry"; JobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostItem(var JobJournalLine2: Record "Job Journal Line"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterRunCode(var JobJournalLine: Record "Job Journal Line"; var JobLedgEntryNo: Integer; var JobRegister: Record "Job Register"; var NextEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckJob(var JobJournalLine: Record "Job Journal Line"; Job: Record Job; var IsHandled: Boolean; var JobRegister: Record "Job Register"; var NextEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetAndCheckJob(var JobJournalLine: Record "Job Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCode(var JobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeApplyUsageLink(var JobLedgerEntry: Record "Job Ledger Entry"; var JobJournalLine: Record "Job Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateJobLedgEntry(var JobJournalLine: Record "Job Journal Line"; var IsHandled: Boolean; var JobLedgEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateJobRegister(var JobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetJobConsumptionValueEntry(var JobJournalLine: Record "Job Journal Line"; var Result: Boolean; var IsHandled: Boolean; var ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeJobLedgEntryInsert(var JobLedgerEntry: Record "Job Ledger Entry"; JobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeJobPlanningReservationExists(ItemNo: Code[20]; JobNo: Code[20]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeItemPosting(var JobJournalLine: Record "Job Journal Line"; var NextEntryNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyValueEntry(var ValueEntry: Record "Value Entry"; JobJournalLine: Record "Job Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostResource(var JobJournalLine: Record "Job Journal Line"; var JobJnlLine2: Record "Job Journal Line"; var EntryNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostWhseJnlLine(ItemJnlLine: Record "Item Journal Line"; OriginalQuantity: Decimal; OriginalQuantityBase: Decimal; var TempTrackingSpecification: Record "Tracking Specification" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunWithCheck(var JobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateJobJnlLineAmount(var JobJnlLineToUpdate: Record "Job Journal Line"; var RemainingAmount: Decimal; var RemainingAmountLCY: Decimal; var RemainingQtyToTrack: Decimal; AmtRoundingPrecision: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateJobJnlLineResourceGroupNo(var JobJnlLine2: Record "Job Journal Line"; ResJnlLine: Record "Res. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckJobOnBeforeTestJobTaskType(var JobJournalLine: Record "Job Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterCalcShouldPostUsage(var JobJournalLine2: Record "Job Journal Line"; var ShouldPostUsage: Boolean; var JobLedgEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateJobLedgEntryOnBeforeAssignQtyCostPrice(var JobLedgEntry: Record "Job Ledger Entry"; JobJournalLine: Record "Job Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateJobLedgerEntryOnAfterAssignLedgerEntryTypeAndNo(var JobLedgEntry: Record "Job Ledger Entry"; JobJournalLine: Record "Job Journal Line"; GLEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetJobConsumptionValueEntryFilter(var ValueEntry: Record "Value Entry"; JobJournalLine: Record "Job Journal Line"; LocalJobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemOnAfterApplyItemTracking(var JobJournalLine: Record "Job Journal Line"; ItemLedgerEntry: Record "Item Ledger Entry"; var JobLedgerEntry: Record "Job Ledger Entry"; var SkipJobLedgerEntry: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemOnAfterSetSkipJobLedgerEntry(var JobJnlLine2: Record "Job Journal Line"; ItemLedgEntry: Record "Item Ledger Entry"; var SkipJobLedgerEntry: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemOnBeforeGetJobConsumptionValueEntry(var JobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemOnBeforeUpdateTotalAmounts(var JobJournalLine: Record "Job Journal Line"; ItemLedgerEntry: Record "Item Ledger Entry"; ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemOnBeforeAssignItemJnlLine(var JobJournalLine: Record "Job Journal Line"; var JobJournalLine2: Record "Job Journal Line"; var ItemJnlLine: Record "Item Journal Line"; JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateJobLedgEntryFromPostItem(var JobJournalLine: Record "Job Journal Line"; var ValueEntry: Record "Value Entry"; var IsHandled: Boolean)
    begin
    end;
}

