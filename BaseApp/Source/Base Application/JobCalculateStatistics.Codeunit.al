codeunit 1008 "Job Calculate Statistics"
{

    trigger OnRun()
    begin
    end;

    var
        JobLedgEntry: Record "Job Ledger Entry";
        JobLedgEntry2: Record "Job Ledger Entry";
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningLine2: Record "Job Planning Line";
        AmountType: Option TotalCostLCY,LineAmountLCY,TotalCost,LineAmount;
        PlanLineType: Option Schedule,Contract;
        JobLedgAmounts: array[10, 4, 4] of Decimal;
        JobPlanAmounts: array[10, 4, 4] of Decimal;
        Text000: Label 'Budget Price,Usage Price,Billable Price,Inv. Price,Budget Cost,Usage Cost,Billable Cost,Inv. Cost,Budget Profit,Usage Profit,Billable Profit,Inv. Profit';

    procedure ReportAnalysis(var Job2: Record Job; var JT: Record "Job Task"; var Amt: array[8] of Decimal; AmountField: array[8] of Option " ",SchPrice,UsagePrice,ContractPrice,InvoicedPrice,SchCost,UsageCost,ContractCost,InvoicedCost,SchProfit,UsageProfit,ContractProfit,InvoicedProfit; CurrencyField: array[8] of Option LCY,FCY; JobLevel: Boolean)
    var
        PL: array[16] of Decimal;
        CL: array[16] of Decimal;
        P: array[16] of Decimal;
        C: array[16] of Decimal;
        I: Integer;
    begin
        if JobLevel then
            JobCalculateCommonFilters(Job2)
        else
            JTCalculateCommonFilters(JT, Job2, true);
        CalculateAmounts;
        GetLCYCostAmounts(CL);
        GetCostAmounts(C);
        GetLCYPriceAmounts(PL);
        GetPriceAmounts(P);
        Clear(Amt);
        for I := 1 to 8 do begin
            if AmountField[I] = AmountField[I] ::SchPrice then
                if CurrencyField[I] = CurrencyField[I] ::LCY then
                    Amt[I] := PL[4]
                else
                    Amt[I] := P[4];
            if AmountField[I] = AmountField[I] ::UsagePrice then
                if CurrencyField[I] = CurrencyField[I] ::LCY then
                    Amt[I] := PL[8]
                else
                    Amt[I] := P[8];
            if AmountField[I] = AmountField[I] ::ContractPrice then
                if CurrencyField[I] = CurrencyField[I] ::LCY then
                    Amt[I] := PL[12]
                else
                    Amt[I] := P[12];
            if AmountField[I] = AmountField[I] ::InvoicedPrice then
                if CurrencyField[I] = CurrencyField[I] ::LCY then
                    Amt[I] := PL[16]
                else
                    Amt[I] := P[16];

            if AmountField[I] = AmountField[I] ::SchCost then
                if CurrencyField[I] = CurrencyField[I] ::LCY then
                    Amt[I] := CL[4]
                else
                    Amt[I] := C[4];
            if AmountField[I] = AmountField[I] ::UsageCost then
                if CurrencyField[I] = CurrencyField[I] ::LCY then
                    Amt[I] := CL[8]
                else
                    Amt[I] := C[8];
            if AmountField[I] = AmountField[I] ::ContractCost then
                if CurrencyField[I] = CurrencyField[I] ::LCY then
                    Amt[I] := CL[12]
                else
                    Amt[I] := C[12];
            if AmountField[I] = AmountField[I] ::InvoicedCost then
                if CurrencyField[I] = CurrencyField[I] ::LCY then
                    Amt[I] := CL[16]
                else
                    Amt[I] := C[16];

            if AmountField[I] = AmountField[I] ::SchProfit then
                if CurrencyField[I] = CurrencyField[I] ::LCY then
                    Amt[I] := PL[4] - CL[4]
                else
                    Amt[I] := P[4] - C[4];
            if AmountField[I] = AmountField[I] ::UsageProfit then
                if CurrencyField[I] = CurrencyField[I] ::LCY then
                    Amt[I] := PL[8] - CL[8]
                else
                    Amt[I] := P[8] - C[8];
            if AmountField[I] = AmountField[I] ::ContractProfit then
                if CurrencyField[I] = CurrencyField[I] ::LCY then
                    Amt[I] := PL[12] - CL[12]
                else
                    Amt[I] := P[12] - C[12];
            if AmountField[I] = AmountField[I] ::InvoicedProfit then
                if CurrencyField[I] = CurrencyField[I] ::LCY then
                    Amt[I] := PL[16] - CL[16]
                else
                    Amt[I] := P[16] - C[16];
        end;
    end;

    procedure ReportSuggBilling(var Job2: Record Job; var JT: Record "Job Task"; var Amt: array[8] of Decimal; CurrencyField: array[8] of Option LCY,FCY)
    var
        AmountField: array[8] of Option " ",SchPrice,UsagePrice,ContractPrice,InvoicedPrice,SchCost,UsageCost,ContractCost,InvoicedCost,SchProfit,UsageProfit,ContractProfit,InvoicedProfit;
    begin
        AmountField[1] := AmountField[1] ::ContractCost;
        AmountField[2] := AmountField[2] ::ContractPrice;
        AmountField[3] := AmountField[3] ::InvoicedCost;
        AmountField[4] := AmountField[4] ::InvoicedPrice;
        ReportAnalysis(Job2, JT, Amt, AmountField, CurrencyField, false);
        Amt[5] := Amt[1] - Amt[3];
        Amt[6] := Amt[2] - Amt[4];
    end;

    procedure RepJobCustomer(var Job2: Record Job; var Amt: array[8] of Decimal)
    var
        JT: Record "Job Task";
        AmountField: array[8] of Option " ",SchPrice,UsagePrice,ContractPrice,InvoicedPrice,SchCost,UsageCost,ContractCost,InvoicedCost,SchProfit,UsageProfit,ContractProfit,InvoicedProfit;
        CurrencyField: array[8] of Option LCY,FCY;
    begin
        Clear(Amt);
        if Job2."No." = '' then
            exit;
        AmountField[1] := AmountField[1] ::SchPrice;
        AmountField[2] := AmountField[2] ::UsagePrice;
        AmountField[3] := AmountField[3] ::InvoicedPrice;
        AmountField[4] := AmountField[4] ::ContractPrice;
        ReportAnalysis(Job2, JT, Amt, AmountField, CurrencyField, true);
        Amt[5] := 0;
        Amt[6] := 0;
        if Amt[1] <> 0 then
            Amt[5] := Round(Amt[2] / Amt[1] * 100);
        if Amt[4] <> 0 then
            Amt[6] := Round(Amt[3] / Amt[4] * 100);
    end;

    procedure JobCalculateCommonFilters(var Job: Record Job)
    begin
        ClearAll;
        JobPlanningLine.SetCurrentKey("Job No.", "Job Task No.");
        JobLedgEntry.SetCurrentKey("Job No.", "Job Task No.", "Entry Type");
        JobPlanningLine.FilterGroup(2);
        JobLedgEntry.SetRange("Job No.", Job."No.");
        JobPlanningLine.SetRange("Job No.", Job."No.");
        JobPlanningLine.FilterGroup(0);
        JobLedgEntry.SetFilter("Posting Date", Job.GetFilter("Posting Date Filter"));
        JobPlanningLine.SetFilter("Planning Date", Job.GetFilter("Planning Date Filter"));
    end;

    procedure JTCalculateCommonFilters(var JT2: Record "Job Task"; var Job2: Record Job; UseJobFilter: Boolean)
    var
        JT: Record "Job Task";
    begin
        ClearAll;
        JT := JT2;
        JobPlanningLine.FilterGroup(2);
        JobPlanningLine.SetCurrentKey("Job No.", "Job Task No.");
        JobLedgEntry.SetCurrentKey("Job No.", "Job Task No.", "Entry Type");
        JobLedgEntry.SetRange("Job No.", JT."Job No.");
        JobPlanningLine.SetRange("Job No.", JT."Job No.");
        JobPlanningLine.FilterGroup(0);
        if JT."Job Task No." <> '' then
            if JT.Totaling <> '' then begin
                JobLedgEntry.SetFilter("Job Task No.", JT.Totaling);
                JobPlanningLine.SetFilter("Job Task No.", JT.Totaling);
            end else begin
                JobLedgEntry.SetRange("Job Task No.", JT."Job Task No.");
                JobPlanningLine.SetRange("Job Task No.", JT."Job Task No.");
            end;

        if not UseJobFilter then begin
            JobLedgEntry.SetFilter("Posting Date", JT2.GetFilter("Posting Date Filter"));
            JobPlanningLine.SetFilter("Planning Date", JT2.GetFilter("Planning Date Filter"));
        end else begin
            JobLedgEntry.SetFilter("Posting Date", Job2.GetFilter("Posting Date Filter"));
            JobPlanningLine.SetFilter("Planning Date", Job2.GetFilter("Planning Date Filter"));
        end;
    end;

    procedure CalculateAmounts()
    begin
        CalcJobLedgAmounts(JobLedgEntry."Entry Type"::Usage, JobLedgEntry.Type::Resource);
        CalcJobLedgAmounts(JobLedgEntry."Entry Type"::Usage, JobLedgEntry.Type::Item);
        CalcJobLedgAmounts(JobLedgEntry."Entry Type"::Usage, JobLedgEntry.Type::"G/L Account");
        CalcJobLedgAmounts(JobLedgEntry."Entry Type"::Sale, JobLedgEntry.Type::Resource);
        CalcJobLedgAmounts(JobLedgEntry."Entry Type"::Sale, JobLedgEntry.Type::Item);
        CalcJobLedgAmounts(JobLedgEntry."Entry Type"::Sale, JobLedgEntry.Type::"G/L Account");

        CalcJobPlanAmounts(PlanLineType::Contract, JobPlanningLine.Type::Resource);
        CalcJobPlanAmounts(PlanLineType::Contract, JobPlanningLine.Type::Item);
        CalcJobPlanAmounts(PlanLineType::Contract, JobPlanningLine.Type::"G/L Account");
        CalcJobPlanAmounts(PlanLineType::Schedule, JobPlanningLine.Type::Resource);
        CalcJobPlanAmounts(PlanLineType::Schedule, JobPlanningLine.Type::Item);
        CalcJobPlanAmounts(PlanLineType::Schedule, JobPlanningLine.Type::"G/L Account");
    end;

    local procedure CalcJobLedgAmounts(EntryTypeParm: Option; TypeParm: Option)
    begin
        JobLedgEntry2.Copy(JobLedgEntry);
        with JobLedgEntry2 do begin
            SetRange("Entry Type", EntryTypeParm);
            SetRange(Type, TypeParm);
            CalcSums("Total Cost (LCY)", "Line Amount (LCY)", "Total Cost", "Line Amount");
            JobLedgAmounts[1 + EntryTypeParm, 1 + TypeParm, 1 + AmountType::TotalCostLCY] := "Total Cost (LCY)";
            JobLedgAmounts[1 + EntryTypeParm, 1 + TypeParm, 1 + AmountType::LineAmountLCY] := "Line Amount (LCY)";
            JobLedgAmounts[1 + EntryTypeParm, 1 + TypeParm, 1 + AmountType::TotalCost] := "Total Cost";
            JobLedgAmounts[1 + EntryTypeParm, 1 + TypeParm, 1 + AmountType::LineAmount] := "Line Amount";
        end;
    end;

    local procedure CalcJobPlanAmounts(PlanLineTypeParm: Option; TypeParm: Option)
    begin
        JobPlanningLine2.Copy(JobPlanningLine);
        with JobPlanningLine2 do begin
            SetRange("Schedule Line");
            SetRange("Contract Line");
            if PlanLineTypeParm = PlanLineType::Schedule then
                SetRange("Schedule Line", true)
            else
                SetRange("Contract Line", true);
            SetRange(Type, TypeParm);
            CalcSums("Total Cost (LCY)", "Line Amount (LCY)", "Total Cost", "Line Amount");
            JobPlanAmounts[1 + PlanLineTypeParm, 1 + TypeParm, 1 + AmountType::TotalCostLCY] := "Total Cost (LCY)";
            JobPlanAmounts[1 + PlanLineTypeParm, 1 + TypeParm, 1 + AmountType::LineAmountLCY] := "Line Amount (LCY)";
            JobPlanAmounts[1 + PlanLineTypeParm, 1 + TypeParm, 1 + AmountType::TotalCost] := "Total Cost";
            JobPlanAmounts[1 + PlanLineTypeParm, 1 + TypeParm, 1 + AmountType::LineAmount] := "Line Amount";
        end;
    end;

    procedure GetLCYCostAmounts(var Amt: array[16] of Decimal)
    begin
        GetArrayAmounts(Amt, AmountType::TotalCostLCY);
    end;

    procedure GetCostAmounts(var Amt: array[16] of Decimal)
    begin
        GetArrayAmounts(Amt, AmountType::TotalCost);
    end;

    procedure GetLCYPriceAmounts(var Amt: array[16] of Decimal)
    begin
        GetArrayAmounts(Amt, AmountType::LineAmountLCY);
    end;

    procedure GetPriceAmounts(var Amt: array[16] of Decimal)
    begin
        GetArrayAmounts(Amt, AmountType::LineAmount);
    end;

    local procedure GetArrayAmounts(var Amt: array[16] of Decimal; AmountTypeParm: Option)
    begin
        Amt[1] := JobPlanAmounts[1 + PlanLineType::Schedule, 1 + JobPlanningLine.Type::Resource, 1 + AmountTypeParm];
        Amt[2] := JobPlanAmounts[1 + PlanLineType::Schedule, 1 + JobPlanningLine.Type::Item, 1 + AmountTypeParm];
        Amt[3] := JobPlanAmounts[1 + PlanLineType::Schedule, 1 + JobPlanningLine.Type::"G/L Account", 1 + AmountTypeParm];
        Amt[4] := Amt[1] + Amt[2] + Amt[3];
        Amt[5] := JobLedgAmounts[1 + JobLedgEntry."Entry Type"::Usage, 1 + JobLedgEntry.Type::Resource, 1 + AmountTypeParm];
        Amt[6] := JobLedgAmounts[1 + JobLedgEntry."Entry Type"::Usage, 1 + JobLedgEntry.Type::Item, 1 + AmountTypeParm];
        Amt[7] := JobLedgAmounts[1 + JobLedgEntry."Entry Type"::Usage, 1 + JobLedgEntry.Type::"G/L Account", 1 + AmountTypeParm];
        Amt[8] := Amt[5] + Amt[6] + Amt[7];
        Amt[9] := JobPlanAmounts[1 + PlanLineType::Contract, 1 + JobPlanningLine.Type::Resource, 1 + AmountTypeParm];
        Amt[10] := JobPlanAmounts[1 + PlanLineType::Contract, 1 + JobPlanningLine.Type::Item, 1 + AmountTypeParm];
        Amt[11] := JobPlanAmounts[1 + PlanLineType::Contract, 1 + JobPlanningLine.Type::"G/L Account", 1 + AmountTypeParm];
        Amt[12] := Amt[9] + Amt[10] + Amt[11];
        Amt[13] := -JobLedgAmounts[1 + JobLedgEntry."Entry Type"::Sale, 1 + JobLedgEntry.Type::Resource, 1 + AmountTypeParm];
        Amt[14] := -JobLedgAmounts[1 + JobLedgEntry."Entry Type"::Sale, 1 + JobLedgEntry.Type::Item, 1 + AmountTypeParm];
        Amt[15] := -JobLedgAmounts[1 + JobLedgEntry."Entry Type"::Sale, 1 + JobLedgEntry.Type::"G/L Account", 1 + AmountTypeParm];
        Amt[16] := Amt[13] + Amt[14] + Amt[15];
    end;

    procedure ShowPlanningLine(JobType: Option " ",Resource,Item,GL; Schedule: Boolean)
    begin
        with JobPlanningLine do begin
            FilterGroup(2);
            SetRange("Contract Line");
            SetRange("Schedule Line");
            SetRange(Type);
            if JobType > 0 then
                SetRange(Type, JobType - 1);
            if Schedule then
                SetRange("Schedule Line", true)
            else
                SetRange("Contract Line", true);
            FilterGroup(0);
            PAGE.Run(PAGE::"Job Planning Lines", JobPlanningLine);
        end;
    end;

    procedure ShowLedgEntry(JobType: Option " ",Resource,Item,GL; Usage: Boolean)
    begin
        JobLedgEntry.SetRange(Type);
        if Usage then
            JobLedgEntry.SetRange("Entry Type", JobLedgEntry."Entry Type"::Usage)
        else
            JobLedgEntry.SetRange("Entry Type", JobLedgEntry."Entry Type"::Sale);
        if JobType > 0 then
            JobLedgEntry.SetRange(Type, JobType - 1);
        PAGE.Run(PAGE::"Job Ledger Entries", JobLedgEntry);
    end;

    procedure GetHeadLineText(AmountField: array[8] of Option " ",SchPrice,UsagePrice,BillablePrice,InvoicedPrice,SchCost,UsageCost,BillableCost,InvoicedCost,SchProfit,UsageProfit,BillableProfit,InvoicedProfit; CurrencyField: array[8] of Option LCY,FCY; var HeadLineText: array[8] of Text[50]; Job: Record Job)
    var
        GLSetup: Record "General Ledger Setup";
        I: Integer;
        Txt: Text[30];
    begin
        Clear(HeadLineText);
        GLSetup.Get();

        for I := 1 to 8 do begin
            Txt := '';
            if CurrencyField[I] > 0 then
                Txt := Job."Currency Code";
            if Txt = '' then
                Txt := GLSetup."LCY Code";
            if AmountField[I] > 0 then
                HeadLineText[I] := SelectStr(AmountField[I], Text000) + '\' + Txt;
        end;
    end;
}

