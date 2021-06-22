report 1095 "Update Job Item Cost"
{
    ApplicationArea = Jobs;
    Caption = 'Update Job Item Cost';
    Permissions = TableData "Job Ledger Entry" = rm,
                  TableData "Value Entry" = rm;
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem(Job; Job)
        {
            DataItemTableView = SORTING("No.") WHERE(Status = FILTER(<> Completed));
            RequestFilterFields = "No.";
            dataitem("Job Ledger Entry"; "Job Ledger Entry")
            {
                DataItemLink = "Job No." = FIELD("No.");
                DataItemTableView = SORTING(Type, "Entry Type", "Country/Region Code", "Source Code", "Posting Date") WHERE(Type = FILTER(= Item), "Entry Type" = FILTER(= Usage));
                RequestFilterFields = "Posting Date";
                dataitem("Item Ledger Entry"; "Item Ledger Entry")
                {
                    DataItemLink = "Entry No." = FIELD("Ledger Entry No.");
                    DataItemTableView = SORTING("Entry No.");
                    dataitem("Job Planning Line"; "Job Planning Line")
                    {
                        DataItemLink = "Job No." = FIELD("Job No."), "Job Task No." = FIELD("Job Task No."), "Ledger Entry No." = FIELD("Entry No.");
                        DataItemTableView = SORTING("Job No.", "Job Task No.", "Line No.");

                        trigger OnAfterGetRecord()
                        begin
                            CalcFields("Qty. Transferred to Invoice");
                            if ("Qty. Transferred to Invoice" <> 0) or not "System-Created Entry" or ("Ledger Entry Type" <> "Ledger Entry Type"::Item) then
                                CurrReport.Skip;

                            Validate("Unit Cost (LCY)", "Job Ledger Entry"."Unit Cost (LCY)");
                            Validate("Line Discount Amount (LCY)", "Job Ledger Entry"."Line Discount Amount (LCY)");
                            Modify;
                            "Job Ledger Entry".Validate("Unit Price", "Unit Price");
                            "Job Ledger Entry".Validate("Unit Price (LCY)", "Unit Price (LCY)");
                            "Job Ledger Entry".Validate("Total Price", "Total Price");
                            "Job Ledger Entry".Validate("Total Price (LCY)", "Total Price (LCY)");
                            "Job Ledger Entry".Validate("Line Amount (LCY)", "Line Amount (LCY)");
                            "Job Ledger Entry".Validate("Line Amount", "Line Amount");
                            "Job Ledger Entry".Modify;
                        end;

                        trigger OnPreDataItem()
                        begin
                            if NoOfJobLedgEntry = 0 then
                                CurrReport.Break;
                            LockTable;
                        end;
                    }

                    trigger OnAfterGetRecord()
                    var
                        ValueEntry: Record "Value Entry";
                        ValueEntry2: Record "Value Entry";
                        Item: Record Item;
                        JobLedgerEntryCostValue: Decimal;
                        JobLedgerEntryCostValueACY: Decimal;
                    begin
                        ValueEntry.SetRange("Job No.", "Job Ledger Entry"."Job No.");
                        ValueEntry.SetRange("Job Task No.", "Job Ledger Entry"."Job Task No.");
                        ValueEntry.SetRange("Job Ledger Entry No.", "Job Ledger Entry"."Entry No.");
                        ValueEntry.SetRange("Item Ledger Entry No.", "Entry No.");
                        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::"Negative Adjmt.");
                        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Purchase Invoice");

                        if ValueEntry.IsEmpty then begin
                            Item.Get("Item No.");
                            if Item.Type = Item.Type::Inventory then begin
                                CalcFields("Cost Amount (Expected)", "Cost Amount (Expected) (ACY)", "Cost Amount (Actual)", "Cost Amount (Actual) (ACY)");
                                JobLedgerEntryCostValue := "Cost Amount (Expected)" + "Cost Amount (Actual)";
                                JobLedgerEntryCostValueACY := "Cost Amount (Expected) (ACY)" + "Cost Amount (Actual) (ACY)";
                            end else begin
                                CalcFields("Cost Amount (Non-Invtbl.)", "Cost Amount (Non-Invtbl.)(ACY)");
                                JobLedgerEntryCostValue := "Cost Amount (Non-Invtbl.)";
                                JobLedgerEntryCostValueACY := "Cost Amount (Non-Invtbl.)(ACY)";
                            end;
                        end else begin
                            ValueEntry.SetRange(Adjustment, false);
                            if ValueEntry.FindFirst then begin
                                AddJobCostValue(JobLedgerEntryCostValue, JobLedgerEntryCostValueACY, ValueEntry, ValueEntry.Inventoriable);

                                ValueEntry2.SetRange("Item Ledger Entry No.", "Entry No.");
                                ValueEntry2.SetRange("Document No.", ValueEntry."Document No.");
                                ValueEntry2.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::"Negative Adjmt.");
                                ValueEntry2.SetRange("Document Type", ValueEntry."Document Type"::"Purchase Invoice");
                                ValueEntry2.SetRange(Adjustment, true);

                                if ValueEntry.Inventoriable then
                                    ValueEntry2.CalcSums("Cost Amount (Actual)", "Cost Amount (Actual) (ACY)")
                                else
                                    ValueEntry2.CalcSums("Cost Amount (Non-Invtbl.)", "Cost Amount (Non-Invtbl.)(ACY)");

                                AddJobCostValue(JobLedgerEntryCostValue, JobLedgerEntryCostValueACY, ValueEntry2, ValueEntry.Inventoriable);

                                ValueEntry2.SetRange("Job Ledger Entry No.", 0);
                                ValueEntry2.ModifyAll("Job No.", ValueEntry."Job No.");
                                ValueEntry2.ModifyAll("Job Task No.", ValueEntry."Job Task No.");
                                ValueEntry2.ModifyAll("Job Ledger Entry No.", ValueEntry."Job Ledger Entry No.");
                            end;
                        end;
                        PostTotalCostAdjustment("Job Ledger Entry", JobLedgerEntryCostValue, JobLedgerEntryCostValueACY);
                    end;

                    trigger OnPreDataItem()
                    begin
                        LockTable;
                    end;
                }

                trigger OnPreDataItem()
                begin
                    LockTable;
                end;
            }

            trigger OnPostDataItem()
            begin
                if not HideResult then begin
                    if NoOfJobLedgEntry <> 0 then
                        Message(StrSubstNo(Text001, NoOfJobLedgEntry))
                    else
                        Message(Text003);
                end;
            end;

            trigger OnPreDataItem()
            begin
                NoOfJobLedgEntry := 0;
                LockTable;
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        Text001: Label 'The job ledger entry item costs have now been updated to equal the related item ledger entry actual costs.\\The number of job ledger entries modified = %1.', Comment = 'The Job Ledger Entry item costs have now been updated to equal the related item ledger entry actual costs.\\Number of Job Ledger Entries modified = 2.';
        NoOfJobLedgEntry: Integer;
        Text003: Label 'There were no job ledger entries that needed to be updated.';
        HideResult: Boolean;

    procedure SetProperties(SuppressSummary: Boolean)
    begin
        HideResult := SuppressSummary;
    end;

    local procedure UpdatePostedTotalCost(var JobLedgerEntry: Record "Job Ledger Entry"; AdjustJobCost: Decimal; AdjustJobCostLCY: Decimal)
    var
        JobUsageLink: Record "Job Usage Link";
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobUsageLink.SetRange("Entry No.", JobLedgerEntry."Entry No.");
        if JobUsageLink.FindSet then
            repeat
                JobPlanningLine.Get(JobUsageLink."Job No.", JobUsageLink."Job Task No.", JobUsageLink."Line No.");
                JobPlanningLine.UpdatePostedTotalCost(AdjustJobCost, AdjustJobCostLCY);
                JobPlanningLine.Modify;
            until JobUsageLink.Next = 0;
    end;

    local procedure PostTotalCostAdjustment(var JobLedgEntry: Record "Job Ledger Entry"; JobLedgerEntryCostValue: Decimal; JobLedgerEntryCostValueACY: Decimal)
    var
        AdjustJobCost: Decimal;
        AdjustJobCostLCY: Decimal;
    begin
        if JobLedgEntry."Total Cost (LCY)" <> -JobLedgerEntryCostValue then begin
            // Update Total Costs
            AdjustJobCostLCY := -JobLedgerEntryCostValue - JobLedgEntry."Total Cost (LCY)";
            JobLedgEntry."Total Cost (LCY)" := -JobLedgerEntryCostValue;
            if JobLedgEntry."Currency Code" = '' then begin
                AdjustJobCost := -JobLedgerEntryCostValue - JobLedgEntry."Total Cost";
                JobLedgEntry."Total Cost" := -JobLedgerEntryCostValue
            end else begin
                AdjustJobCost := -JobLedgerEntryCostValue * JobLedgEntry."Currency Factor" - JobLedgEntry."Total Cost";
                JobLedgEntry."Total Cost" := -JobLedgerEntryCostValue * JobLedgEntry."Currency Factor";
            end;
            if JobLedgerEntryCostValueACY <> 0 then
                JobLedgEntry."Additional-Currency Total Cost" := -JobLedgerEntryCostValueACY;

            // Update Unit Costs
            if JobLedgEntry.Quantity = 0 then begin
                JobLedgEntry."Unit Cost (LCY)" := JobLedgEntry."Total Cost (LCY)";
                JobLedgEntry."Unit Cost" := JobLedgEntry."Total Cost";
            end else begin
                JobLedgEntry."Unit Cost (LCY)" := JobLedgEntry."Total Cost (LCY)" / JobLedgEntry.Quantity;
                JobLedgEntry."Unit Cost" := JobLedgEntry."Total Cost" / JobLedgEntry.Quantity;
            end;

            JobLedgEntry.Adjusted := true;
            JobLedgEntry."DateTime Adjusted" := CurrentDateTime;
            JobLedgEntry.Modify;

            UpdatePostedTotalCost(JobLedgEntry, AdjustJobCost, AdjustJobCostLCY);

            NoOfJobLedgEntry += 1;
        end;
    end;

    local procedure AddJobCostValue(var JobLedgerEntryCostValue: Decimal; var JobLedgerEntryCostValueACY: Decimal; ValueEntry: Record "Value Entry"; IsInventoriableItem: Boolean)
    begin
        if IsInventoriableItem then begin
            JobLedgerEntryCostValue += ValueEntry."Cost Amount (Actual)";
            JobLedgerEntryCostValueACY += ValueEntry."Cost Amount (Actual) (ACY)";
        end else begin
            JobLedgerEntryCostValue += ValueEntry."Cost Amount (Non-Invtbl.)";
            JobLedgerEntryCostValueACY += ValueEntry."Cost Amount (Non-Invtbl.)(ACY)";
        end;
    end;
}

