codeunit 1004 "Job Transfer Line"
{

    trigger OnRun()
    begin
    end;

    var
        CurrencyExchRate: Record "Currency Exchange Rate";
        Currency: Record Currency;
        LCYCurrency: Record Currency;
        CurrencyRoundingRead: Boolean;
        Text001: Label '%1 %2 does not exist.';

    procedure FromJnlLineToLedgEntry(JobJnlLine2: Record "Job Journal Line"; var JobLedgEntry: Record "Job Ledger Entry")
    begin
        JobLedgEntry."Job No." := JobJnlLine2."Job No.";
        JobLedgEntry."Job Task No." := JobJnlLine2."Job Task No.";
        JobLedgEntry."Job Posting Group" := JobJnlLine2."Posting Group";
        JobLedgEntry."Posting Date" := JobJnlLine2."Posting Date";
        JobLedgEntry."Document Date" := JobJnlLine2."Document Date";
        JobLedgEntry."Document No." := JobJnlLine2."Document No.";
        JobLedgEntry."External Document No." := JobJnlLine2."External Document No.";
        JobLedgEntry.Type := JobJnlLine2.Type;
        JobLedgEntry."No." := JobJnlLine2."No.";
        JobLedgEntry.Description := JobJnlLine2.Description;
        JobLedgEntry."Resource Group No." := JobJnlLine2."Resource Group No.";
        JobLedgEntry."Unit of Measure Code" := JobJnlLine2."Unit of Measure Code";
        JobLedgEntry."Location Code" := JobJnlLine2."Location Code";
        JobLedgEntry."Global Dimension 1 Code" := JobJnlLine2."Shortcut Dimension 1 Code";
        JobLedgEntry."Global Dimension 2 Code" := JobJnlLine2."Shortcut Dimension 2 Code";
        JobLedgEntry."Dimension Set ID" := JobJnlLine2."Dimension Set ID";
        JobLedgEntry."Work Type Code" := JobJnlLine2."Work Type Code";
        JobLedgEntry."Source Code" := JobJnlLine2."Source Code";
        JobLedgEntry."Entry Type" := JobJnlLine2."Entry Type";
        JobLedgEntry."Gen. Bus. Posting Group" := JobJnlLine2."Gen. Bus. Posting Group";
        JobLedgEntry."Gen. Prod. Posting Group" := JobJnlLine2."Gen. Prod. Posting Group";
        JobLedgEntry."Journal Batch Name" := JobJnlLine2."Journal Batch Name";
        JobLedgEntry."Reason Code" := JobJnlLine2."Reason Code";
        JobLedgEntry."Variant Code" := JobJnlLine2."Variant Code";
        JobLedgEntry."Bin Code" := JobJnlLine2."Bin Code";
        JobLedgEntry."Line Type" := JobJnlLine2."Line Type";
        JobLedgEntry."Currency Code" := JobJnlLine2."Currency Code";
        JobLedgEntry."Description 2" := JobJnlLine2."Description 2";
        if JobJnlLine2."Currency Code" = '' then
            JobLedgEntry."Currency Factor" := 1
        else
            JobLedgEntry."Currency Factor" := JobJnlLine2."Currency Factor";
        JobLedgEntry."User ID" := UserId;
        JobLedgEntry."Customer Price Group" := JobJnlLine2."Customer Price Group";

        JobLedgEntry."Transport Method" := JobJnlLine2."Transport Method";
        JobLedgEntry."Transaction Type" := JobJnlLine2."Transaction Type";
        JobLedgEntry."Transaction Specification" := JobJnlLine2."Transaction Specification";
        JobLedgEntry."Entry/Exit Point" := JobJnlLine2."Entry/Exit Point";
        JobLedgEntry.Area := JobJnlLine2.Area;
        JobLedgEntry."Country/Region Code" := JobJnlLine2."Country/Region Code";
        JobLedgEntry."Shpt. Method Code" := JobJnlLine2."Shpt. Method Code";

        JobLedgEntry."Unit Price (LCY)" := JobJnlLine2."Unit Price (LCY)";
        JobLedgEntry."Additional-Currency Total Cost" :=
          -JobJnlLine2."Source Currency Total Cost";
        JobLedgEntry."Add.-Currency Total Price" :=
          -JobJnlLine2."Source Currency Total Price";
        JobLedgEntry."Add.-Currency Line Amount" :=
          -JobJnlLine2."Source Currency Line Amount";

        JobLedgEntry."Service Order No." := JobJnlLine2."Service Order No.";
        JobLedgEntry."Posted Service Shipment No." := JobJnlLine2."Posted Service Shipment No.";

        // Amounts
        JobLedgEntry."Qty. per Unit of Measure" := JobJnlLine2."Qty. per Unit of Measure";

        JobLedgEntry."Direct Unit Cost (LCY)" := JobJnlLine2."Direct Unit Cost (LCY)";
        JobLedgEntry."Unit Cost (LCY)" := JobJnlLine2."Unit Cost (LCY)";
        JobLedgEntry."Unit Cost" := JobJnlLine2."Unit Cost";
        JobLedgEntry."Unit Price" := JobJnlLine2."Unit Price";

        JobLedgEntry."Line Discount %" := JobJnlLine2."Line Discount %";

        OnAfterFromJnlLineToLedgEntry(JobLedgEntry, JobJnlLine2);
    end;

    procedure FromJnlToPlanningLine(JobJnlLine: Record "Job Journal Line"; var JobPlanningLine: Record "Job Planning Line")
    begin
        JobPlanningLine."Job No." := JobJnlLine."Job No.";
        JobPlanningLine."Job Task No." := JobJnlLine."Job Task No.";
        JobPlanningLine."Planning Date" := JobJnlLine."Posting Date";
        JobPlanningLine."Currency Date" := JobJnlLine."Posting Date";
        JobPlanningLine.Type := JobJnlLine.Type;
        JobPlanningLine."No." := JobJnlLine."No.";
        JobPlanningLine."Document No." := JobJnlLine."Document No.";
        JobPlanningLine.Description := JobJnlLine.Description;
        JobPlanningLine."Description 2" := JobJnlLine."Description 2";
        JobPlanningLine."Unit of Measure Code" := JobJnlLine."Unit of Measure Code";
        JobPlanningLine.Validate("Line Type", JobJnlLine."Line Type" - 1);
        JobPlanningLine."Currency Code" := JobJnlLine."Currency Code";
        JobPlanningLine."Currency Factor" := JobJnlLine."Currency Factor";
        JobPlanningLine."Resource Group No." := JobJnlLine."Resource Group No.";
        JobPlanningLine."Location Code" := JobJnlLine."Location Code";
        JobPlanningLine."Work Type Code" := JobJnlLine."Work Type Code";
        JobPlanningLine."Customer Price Group" := JobJnlLine."Customer Price Group";
        JobPlanningLine."Country/Region Code" := JobJnlLine."Country/Region Code";
        JobPlanningLine."Gen. Bus. Posting Group" := JobJnlLine."Gen. Bus. Posting Group";
        JobPlanningLine."Gen. Prod. Posting Group" := JobJnlLine."Gen. Prod. Posting Group";
        JobPlanningLine."Document Date" := JobJnlLine."Document Date";
        JobPlanningLine."Variant Code" := JobJnlLine."Variant Code";
        JobPlanningLine."Bin Code" := JobJnlLine."Bin Code";
        JobPlanningLine."Serial No." := JobJnlLine."Serial No.";
        JobPlanningLine."Lot No." := JobJnlLine."Lot No.";
        JobPlanningLine."Service Order No." := JobJnlLine."Service Order No.";
        JobPlanningLine."Ledger Entry Type" := JobJnlLine."Ledger Entry Type";
        JobPlanningLine."Ledger Entry No." := JobJnlLine."Ledger Entry No.";
        JobPlanningLine."System-Created Entry" := true;

        // Amounts
        JobPlanningLine.Quantity := JobJnlLine.Quantity;
        JobPlanningLine."Quantity (Base)" := JobJnlLine."Quantity (Base)";
        if JobPlanningLine."Usage Link" then begin
            JobPlanningLine."Remaining Qty." := JobJnlLine.Quantity;
            JobPlanningLine."Remaining Qty. (Base)" := JobJnlLine."Quantity (Base)";
        end;
        JobPlanningLine."Qty. per Unit of Measure" := JobJnlLine."Qty. per Unit of Measure";

        JobPlanningLine."Direct Unit Cost (LCY)" := JobJnlLine."Direct Unit Cost (LCY)";
        JobPlanningLine."Unit Cost (LCY)" := JobJnlLine."Unit Cost (LCY)";
        JobPlanningLine."Unit Cost" := JobJnlLine."Unit Cost";

        JobPlanningLine."Total Cost (LCY)" := JobJnlLine."Total Cost (LCY)";
        JobPlanningLine."Total Cost" := JobJnlLine."Total Cost";

        JobPlanningLine."Unit Price (LCY)" := JobJnlLine."Unit Price (LCY)";
        JobPlanningLine."Unit Price" := JobJnlLine."Unit Price";

        JobPlanningLine."Total Price (LCY)" := JobJnlLine."Total Price (LCY)";
        JobPlanningLine."Total Price" := JobJnlLine."Total Price";

        JobPlanningLine."Line Amount (LCY)" := JobJnlLine."Line Amount (LCY)";
        JobPlanningLine."Line Amount" := JobJnlLine."Line Amount";

        JobPlanningLine."Line Discount %" := JobJnlLine."Line Discount %";

        JobPlanningLine."Line Discount Amount (LCY)" := JobJnlLine."Line Discount Amount (LCY)";
        JobPlanningLine."Line Discount Amount" := JobJnlLine."Line Discount Amount";

        OnAfterFromJnlToPlanningLine(JobPlanningLine, JobJnlLine);
    end;

    procedure FromPlanningSalesLineToJnlLine(JobPlanningLine: Record "Job Planning Line"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var JobJnlLine: Record "Job Journal Line"; EntryType: Option Usage,Sale)
    var
        SourceCodeSetup: Record "Source Code Setup";
        JobTask: Record "Job Task";
    begin
        OnBeforeFromPlanningSalesLineToJnlLine(JobPlanningLine, SalesHeader, SalesLine, JobJnlLine, EntryType);

        JobJnlLine."Job No." := JobPlanningLine."Job No.";
        JobJnlLine."Job Task No." := JobPlanningLine."Job Task No.";
        JobJnlLine.Type := JobPlanningLine.Type;
        JobTask.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");
        JobJnlLine."Posting Date" := SalesHeader."Posting Date";
        JobJnlLine."Document Date" := SalesHeader."Document Date";
        JobJnlLine."Document No." := SalesLine."Document No.";
        JobJnlLine."Entry Type" := EntryType;
        JobJnlLine."Posting Group" := SalesLine."Posting Group";
        JobJnlLine."Gen. Bus. Posting Group" := SalesLine."Gen. Bus. Posting Group";
        JobJnlLine."Gen. Prod. Posting Group" := SalesLine."Gen. Prod. Posting Group";
        JobJnlLine."Serial No." := JobPlanningLine."Serial No.";
        JobJnlLine."Lot No." := JobPlanningLine."Lot No.";
        JobJnlLine."No." := JobPlanningLine."No.";
        JobJnlLine.Description := SalesLine.Description;
        JobJnlLine."Description 2" := SalesLine."Description 2";
        JobJnlLine."Unit of Measure Code" := JobPlanningLine."Unit of Measure Code";
        JobJnlLine.Validate("Qty. per Unit of Measure", SalesLine."Qty. per Unit of Measure");
        JobJnlLine."Work Type Code" := JobPlanningLine."Work Type Code";
        JobJnlLine."Variant Code" := JobPlanningLine."Variant Code";
        JobJnlLine."Line Type" := JobPlanningLine."Line Type" + 1;
        JobJnlLine."Currency Code" := JobPlanningLine."Currency Code";
        JobJnlLine."Currency Factor" := JobPlanningLine."Currency Factor";
        JobJnlLine."Resource Group No." := JobPlanningLine."Resource Group No.";
        JobJnlLine."Customer Price Group" := JobPlanningLine."Customer Price Group";
        JobJnlLine."Location Code" := SalesLine."Location Code";
        JobJnlLine."Bin Code" := SalesLine."Bin Code";
        JobJnlLine."Service Order No." := JobPlanningLine."Service Order No.";
        SourceCodeSetup.Get;
        JobJnlLine."Source Code" := SourceCodeSetup.Sales;
        JobJnlLine."Reason Code" := SalesHeader."Reason Code";
        JobJnlLine."External Document No." := SalesHeader."External Document No.";

        JobJnlLine."Transport Method" := SalesLine."Transport Method";
        JobJnlLine."Transaction Type" := SalesLine."Transaction Type";
        JobJnlLine."Transaction Specification" := SalesLine."Transaction Specification";
        JobJnlLine."Entry/Exit Point" := SalesLine."Exit Point";
        JobJnlLine.Area := SalesLine.Area;
        JobJnlLine."Country/Region Code" := JobPlanningLine."Country/Region Code";

        JobJnlLine."Shortcut Dimension 1 Code" := SalesLine."Shortcut Dimension 1 Code";
        JobJnlLine."Shortcut Dimension 2 Code" := SalesLine."Shortcut Dimension 2 Code";
        JobJnlLine."Dimension Set ID" := SalesLine."Dimension Set ID";

        case SalesHeader."Document Type" of
            SalesHeader."Document Type"::Invoice:
                JobJnlLine.Validate(Quantity, SalesLine.Quantity);
            SalesHeader."Document Type"::"Credit Memo":
                JobJnlLine.Validate(Quantity, -SalesLine.Quantity);
        end;

        JobJnlLine."Direct Unit Cost (LCY)" := JobPlanningLine."Direct Unit Cost (LCY)";
        if (JobPlanningLine."Currency Code" = '') and (SalesHeader."Currency Factor" <> 0) then begin
            GetCurrencyRounding(SalesHeader."Currency Code");
            ValidateUnitCostAndPrice(
              JobJnlLine, SalesLine, SalesLine."Unit Cost (LCY)",
              JobPlanningLine."Unit Price");
        end else
            ValidateUnitCostAndPrice(JobJnlLine, SalesLine, SalesLine."Unit Cost", JobPlanningLine."Unit Price");
        JobJnlLine.Validate("Line Discount %", SalesLine."Line Discount %");

        OnAfterFromPlanningSalesLineToJnlLine(JobJnlLine, JobPlanningLine, SalesHeader, SalesLine, EntryType);
    end;

    procedure FromPlanningLineToJnlLine(JobPlanningLine: Record "Job Planning Line"; PostingDate: Date; JobJournalTemplateName: Code[10]; JobJournalBatchName: Code[10]; var JobJnlLine: Record "Job Journal Line")
    var
        JobTask: Record "Job Task";
        JobJnlLine2: Record "Job Journal Line";
        JobJournalTemplate: Record "Job Journal Template";
        JobJournalBatch: Record "Job Journal Batch";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        JobPlanningLine.TestField("Qty. to Transfer to Journal");

        if not JobJournalTemplate.Get(JobJournalTemplateName) then
            Error(Text001, JobJournalTemplate.TableCaption, JobJournalTemplateName);
        if not JobJournalBatch.Get(JobJournalTemplateName, JobJournalBatchName) then
            Error(Text001, JobJournalBatch.TableCaption, JobJournalBatchName);
        if PostingDate = 0D then
            PostingDate := WorkDate;

        JobJnlLine.Init;
        JobJnlLine.Validate("Journal Template Name", JobJournalTemplate.Name);
        JobJnlLine.Validate("Journal Batch Name", JobJournalBatch.Name);
        JobJnlLine2.SetRange("Journal Template Name", JobJournalTemplate.Name);
        JobJnlLine2.SetRange("Journal Batch Name", JobJournalBatch.Name);
        if JobJnlLine2.FindLast then
            JobJnlLine.Validate("Line No.", JobJnlLine2."Line No." + 10000)
        else
            JobJnlLine.Validate("Line No.", 10000);

        JobJnlLine."Job No." := JobPlanningLine."Job No.";
        JobJnlLine."Job Task No." := JobPlanningLine."Job Task No.";

        if JobPlanningLine."Usage Link" then begin
            JobJnlLine."Job Planning Line No." := JobPlanningLine."Line No.";
            JobJnlLine."Line Type" := JobPlanningLine."Line Type" + 1;
        end;

        JobTask.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");
        JobJnlLine."Posting Group" := JobTask."Job Posting Group";
        JobJnlLine."Posting Date" := PostingDate;
        JobJnlLine."Document Date" := PostingDate;
        if JobJournalBatch."No. Series" <> '' then
            JobJnlLine."Document No." := NoSeriesMgt.GetNextNo(JobJournalBatch."No. Series", PostingDate, false)
        else
            JobJnlLine."Document No." := JobPlanningLine."Document No.";

        JobJnlLine.Type := JobPlanningLine.Type;
        JobJnlLine."No." := JobPlanningLine."No.";
        JobJnlLine."Entry Type" := JobJnlLine."Entry Type"::Usage;
        JobJnlLine."Gen. Bus. Posting Group" := JobPlanningLine."Gen. Bus. Posting Group";
        JobJnlLine."Gen. Prod. Posting Group" := JobPlanningLine."Gen. Prod. Posting Group";
        JobJnlLine."Serial No." := JobPlanningLine."Serial No.";
        JobJnlLine."Lot No." := JobPlanningLine."Lot No.";
        JobJnlLine.Description := JobPlanningLine.Description;
        JobJnlLine."Description 2" := JobPlanningLine."Description 2";
        JobJnlLine.Validate("Unit of Measure Code", JobPlanningLine."Unit of Measure Code");
        JobJnlLine."Currency Code" := JobPlanningLine."Currency Code";
        JobJnlLine."Currency Factor" := JobPlanningLine."Currency Factor";
        JobJnlLine."Resource Group No." := JobPlanningLine."Resource Group No.";
        JobJnlLine."Location Code" := JobPlanningLine."Location Code";
        JobJnlLine."Work Type Code" := JobPlanningLine."Work Type Code";
        JobJnlLine."Customer Price Group" := JobPlanningLine."Customer Price Group";
        JobJnlLine."Variant Code" := JobPlanningLine."Variant Code";
        JobJnlLine."Bin Code" := JobPlanningLine."Bin Code";
        JobJnlLine."Service Order No." := JobPlanningLine."Service Order No.";
        JobJnlLine."Country/Region Code" := JobPlanningLine."Country/Region Code";
        JobJnlLine."Source Code" := JobJournalTemplate."Source Code";

        JobJnlLine.Validate(Quantity, JobPlanningLine."Qty. to Transfer to Journal");
        JobJnlLine.Validate("Qty. per Unit of Measure", JobPlanningLine."Qty. per Unit of Measure");
        JobJnlLine."Direct Unit Cost (LCY)" := JobPlanningLine."Direct Unit Cost (LCY)";
        JobJnlLine.Validate("Unit Cost", JobPlanningLine."Unit Cost");
        JobJnlLine.Validate("Unit Price", JobPlanningLine."Unit Price");
        JobJnlLine.Validate("Line Discount %", JobPlanningLine."Line Discount %");

        OnAfterFromPlanningLineToJnlLine(JobJnlLine, JobPlanningLine);

        JobJnlLine.UpdateDimensions;
        ItemTrackingMgt.CopyItemTracking(JobPlanningLine.RowID1, JobJnlLine.RowID1, false);

        JobJnlLine.Insert(true);
    end;

    procedure FromGenJnlLineToJnlLine(GenJnlLine: Record "Gen. Journal Line"; var JobJnlLine: Record "Job Journal Line")
    var
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        JobJnlLine."Job No." := GenJnlLine."Job No.";
        JobJnlLine."Job Task No." := GenJnlLine."Job Task No.";
        JobTask.Get(GenJnlLine."Job No.", GenJnlLine."Job Task No.");

        JobJnlLine."Posting Date" := GenJnlLine."Posting Date";
        JobJnlLine."Document Date" := GenJnlLine."Document Date";
        JobJnlLine."Document No." := GenJnlLine."Document No.";

        JobJnlLine."Currency Code" := GenJnlLine."Job Currency Code";
        JobJnlLine."Currency Factor" := GenJnlLine."Job Currency Factor";
        JobJnlLine."Entry Type" := JobJnlLine."Entry Type"::Usage;
        JobJnlLine."Line Type" := GenJnlLine."Job Line Type";
        JobJnlLine.Type := JobJnlLine.Type::"G/L Account";
        JobJnlLine."No." := GenJnlLine."Account No.";
        JobJnlLine.Description := GenJnlLine.Description;
        JobJnlLine."Unit of Measure Code" := GenJnlLine."Job Unit Of Measure Code";
        JobJnlLine."Gen. Bus. Posting Group" := GenJnlLine."Gen. Bus. Posting Group";
        JobJnlLine."Gen. Prod. Posting Group" := GenJnlLine."Gen. Prod. Posting Group";
        JobJnlLine."Source Code" := GenJnlLine."Source Code";
        JobJnlLine."Reason Code" := GenJnlLine."Reason Code";
        Job.Get(JobJnlLine."Job No.");
        JobJnlLine."Customer Price Group" := Job."Customer Price Group";
        JobJnlLine."External Document No." := GenJnlLine."External Document No.";
        JobJnlLine."Journal Batch Name" := GenJnlLine."Journal Batch Name";
        JobJnlLine."Shortcut Dimension 1 Code" := GenJnlLine."Shortcut Dimension 1 Code";
        JobJnlLine."Shortcut Dimension 2 Code" := GenJnlLine."Shortcut Dimension 2 Code";
        JobJnlLine."Dimension Set ID" := GenJnlLine."Dimension Set ID";

        JobJnlLine.Quantity := GenJnlLine."Job Quantity";
        JobJnlLine."Quantity (Base)" := GenJnlLine."Job Quantity";
        JobJnlLine."Qty. per Unit of Measure" := 1; // MP ??
        JobJnlLine."Job Planning Line No." := GenJnlLine."Job Planning Line No.";
        JobJnlLine."Remaining Qty." := GenJnlLine."Job Remaining Qty.";
        JobJnlLine."Remaining Qty. (Base)" := GenJnlLine."Job Remaining Qty.";

        JobJnlLine."Direct Unit Cost (LCY)" := GenJnlLine."Job Unit Cost (LCY)";
        JobJnlLine."Unit Cost (LCY)" := GenJnlLine."Job Unit Cost (LCY)";
        JobJnlLine."Unit Cost" := GenJnlLine."Job Unit Cost";

        JobJnlLine."Total Cost (LCY)" := GenJnlLine."Job Total Cost (LCY)";
        JobJnlLine."Total Cost" := GenJnlLine."Job Total Cost";

        JobJnlLine."Unit Price (LCY)" := GenJnlLine."Job Unit Price (LCY)";
        JobJnlLine."Unit Price" := GenJnlLine."Job Unit Price";

        JobJnlLine."Total Price (LCY)" := GenJnlLine."Job Total Price (LCY)";
        JobJnlLine."Total Price" := GenJnlLine."Job Total Price";

        JobJnlLine."Line Amount (LCY)" := GenJnlLine."Job Line Amount (LCY)";
        JobJnlLine."Line Amount" := GenJnlLine."Job Line Amount";

        JobJnlLine."Line Discount Amount (LCY)" := GenJnlLine."Job Line Disc. Amount (LCY)";
        JobJnlLine."Line Discount Amount" := GenJnlLine."Job Line Discount Amount";

        JobJnlLine."Line Discount %" := GenJnlLine."Job Line Discount %";

        OnAfterFromGenJnlLineToJnlLine(JobJnlLine, GenJnlLine);
    end;

    procedure FromJobLedgEntryToPlanningLine(JobLedgEntry: Record "Job Ledger Entry"; var JobPlanningLine: Record "Job Planning Line")
    var
        SalesPriceCalcMgt: Codeunit "Sales Price Calc. Mgt.";
    begin
        JobPlanningLine."Job No." := JobLedgEntry."Job No.";
        JobPlanningLine."Job Task No." := JobLedgEntry."Job Task No.";
        JobPlanningLine."Planning Date" := JobLedgEntry."Posting Date";
        JobPlanningLine."Currency Date" := JobLedgEntry."Posting Date";
        JobPlanningLine."Document Date" := JobLedgEntry."Document Date";
        JobPlanningLine."Document No." := JobLedgEntry."Document No.";
        JobPlanningLine.Description := JobLedgEntry.Description;
        JobPlanningLine.Type := JobLedgEntry.Type;
        JobPlanningLine."No." := JobLedgEntry."No.";
        JobPlanningLine."Unit of Measure Code" := JobLedgEntry."Unit of Measure Code";
        JobPlanningLine.Validate("Line Type", JobLedgEntry."Line Type" - 1);
        JobPlanningLine."Currency Code" := JobLedgEntry."Currency Code";
        if JobLedgEntry."Currency Code" = '' then
            JobPlanningLine."Currency Factor" := 0
        else
            JobPlanningLine."Currency Factor" := JobLedgEntry."Currency Factor";
        JobPlanningLine."Resource Group No." := JobLedgEntry."Resource Group No.";
        JobPlanningLine."Location Code" := JobLedgEntry."Location Code";
        JobPlanningLine."Work Type Code" := JobLedgEntry."Work Type Code";
        JobPlanningLine."Gen. Bus. Posting Group" := JobLedgEntry."Gen. Bus. Posting Group";
        JobPlanningLine."Gen. Prod. Posting Group" := JobLedgEntry."Gen. Prod. Posting Group";
        JobPlanningLine."Variant Code" := JobLedgEntry."Variant Code";
        JobPlanningLine."Bin Code" := JobLedgEntry."Bin Code";
        JobPlanningLine."Customer Price Group" := JobLedgEntry."Customer Price Group";
        JobPlanningLine."Country/Region Code" := JobLedgEntry."Country/Region Code";
        JobPlanningLine."Description 2" := JobLedgEntry."Description 2";
        JobPlanningLine."Serial No." := JobLedgEntry."Serial No.";
        JobPlanningLine."Lot No." := JobLedgEntry."Lot No.";
        JobPlanningLine."Service Order No." := JobLedgEntry."Service Order No.";
        JobPlanningLine."Job Ledger Entry No." := JobLedgEntry."Entry No.";
        JobPlanningLine."Ledger Entry Type" := JobLedgEntry."Ledger Entry Type";
        JobPlanningLine."Ledger Entry No." := JobLedgEntry."Ledger Entry No.";
        JobPlanningLine."System-Created Entry" := true;

        // Function call to retrieve cost factor. Prices will be overwritten.
        SalesPriceCalcMgt.JobPlanningLineFindJTPrice(JobPlanningLine);

        // Amounts
        JobPlanningLine.Quantity := JobLedgEntry.Quantity;
        JobPlanningLine."Quantity (Base)" := JobLedgEntry."Quantity (Base)";
        if JobPlanningLine."Usage Link" then begin
            JobPlanningLine."Remaining Qty." := JobLedgEntry.Quantity;
            JobPlanningLine."Remaining Qty. (Base)" := JobLedgEntry."Quantity (Base)";
        end;
        JobPlanningLine."Qty. per Unit of Measure" := JobLedgEntry."Qty. per Unit of Measure";

        JobPlanningLine."Direct Unit Cost (LCY)" := JobLedgEntry."Direct Unit Cost (LCY)";
        JobPlanningLine."Unit Cost (LCY)" := JobLedgEntry."Unit Cost (LCY)";
        JobPlanningLine."Unit Cost" := JobLedgEntry."Unit Cost";

        JobPlanningLine."Total Cost (LCY)" := JobLedgEntry."Total Cost (LCY)";
        JobPlanningLine."Total Cost" := JobLedgEntry."Total Cost";

        JobPlanningLine."Unit Price (LCY)" := JobLedgEntry."Unit Price (LCY)";
        JobPlanningLine."Unit Price" := JobLedgEntry."Unit Price";

        JobPlanningLine."Total Price (LCY)" := JobLedgEntry."Total Price (LCY)";
        JobPlanningLine."Total Price" := JobLedgEntry."Total Price";

        JobPlanningLine."Line Amount (LCY)" := JobLedgEntry."Line Amount (LCY)";
        JobPlanningLine."Line Amount" := JobLedgEntry."Line Amount";

        JobPlanningLine."Line Discount %" := JobLedgEntry."Line Discount %";

        JobPlanningLine."Line Discount Amount (LCY)" := JobLedgEntry."Line Discount Amount (LCY)";
        JobPlanningLine."Line Discount Amount" := JobLedgEntry."Line Discount Amount";

        OnAfterFromJobLedgEntryToPlanningLine(JobPlanningLine, JobLedgEntry);
    end;

    procedure FromPurchaseLineToJnlLine(PurchHeader: Record "Purchase Header"; PurchInvHeader: Record "Purch. Inv. Header"; PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr."; PurchLine: Record "Purchase Line"; SourceCode: Code[10]; var JobJnlLine: Record "Job Journal Line")
    var
        Item: Record Item;
        JobTask: Record "Job Task";
        UOMMgt: Codeunit "Unit of Measure Management";
        Factor: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFromPurchaseLineToJnlLine(PurchHeader, PurchInvHeader, PurchCrMemoHeader, PurchLine, SourceCode, JobJnlLine, IsHandled);
        if IsHandled then
            exit;

        with PurchLine do begin
            JobJnlLine.DontCheckStdCost;
            JobJnlLine.Validate("Job No.", "Job No.");
            JobJnlLine.Validate("Job Task No.", "Job Task No.");
            JobTask.Get("Job No.", "Job Task No.");
            JobJnlLine.Validate("Posting Date", PurchHeader."Posting Date");
            if Type = Type::"G/L Account" then
                JobJnlLine.Validate(Type, JobJnlLine.Type::"G/L Account")
            else
                JobJnlLine.Validate(Type, JobJnlLine.Type::Item);
            JobJnlLine.Validate("No.", "No.");
            JobJnlLine.Validate("Variant Code", "Variant Code");
            if UpdateBaseQtyForPurchLine(Item, PurchLine) then begin
                JobJnlLine.Validate("Unit of Measure Code", Item."Base Unit of Measure");
                JobJnlLine.Validate(
                  Quantity, UOMMgt.CalcBaseQty("Qty. to Invoice", "Qty. per Unit of Measure"));
            end else begin
                JobJnlLine.Validate("Unit of Measure Code", "Unit of Measure Code");
                JobJnlLine."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
                JobJnlLine.Validate(Quantity, "Qty. to Invoice");
            end;

            if PurchHeader."Document Type" in [PurchHeader."Document Type"::"Return Order",
                                               PurchHeader."Document Type"::"Credit Memo"]
            then begin
                JobJnlLine."Document No." := PurchCrMemoHeader."No.";
                JobJnlLine."External Document No." := PurchCrMemoHeader."Vendor Cr. Memo No.";
            end else begin
                JobJnlLine."Document No." := PurchInvHeader."No.";
                JobJnlLine."External Document No." := PurchHeader."Vendor Invoice No.";
            end;

            GetCurrencyRounding(JobJnlLine."Currency Code");

            JobJnlLine."Unit Cost (LCY)" := "Unit Cost (LCY)" / "Qty. per Unit of Measure";

            if Type = Type::Item then begin
                if Item."Inventory Value Zero" then
                    JobJnlLine."Unit Cost (LCY)" := 0
                else
                    if Item."Costing Method" = Item."Costing Method"::Standard then
                        JobJnlLine."Unit Cost (LCY)" := Item."Standard Cost";
            end;
            JobJnlLine."Unit Cost (LCY)" := Round(JobJnlLine."Unit Cost (LCY)", LCYCurrency."Unit-Amount Rounding Precision");

            if JobJnlLine."Currency Code" = '' then begin
                JobJnlLine."Unit Cost" := JobJnlLine."Unit Cost (LCY)";
                JobJnlLine."Total Cost" :=
                  Round(JobJnlLine."Unit Cost (LCY)" * JobJnlLine.Quantity, LCYCurrency."Amount Rounding Precision");
            end else
                if JobJnlLine."Currency Code" = "Currency Code" then begin
                    JobJnlLine."Unit Cost" := "Unit Cost";
                    JobJnlLine."Total Cost" :=
                      Round(JobJnlLine."Unit Cost" * JobJnlLine.Quantity, Currency."Amount Rounding Precision");
                end else begin
                    JobJnlLine."Unit Cost" :=
                      Round(
                        CurrencyExchRate.ExchangeAmtLCYToFCY(
                          PurchHeader."Posting Date",
                          JobJnlLine."Currency Code",
                          JobJnlLine."Unit Cost (LCY)",
                          JobJnlLine."Currency Factor"), Currency."Unit-Amount Rounding Precision");
                    JobJnlLine."Total Cost" := Round(JobJnlLine."Unit Cost" * JobJnlLine.Quantity, Currency."Amount Rounding Precision");
                end;

            if (Type = Type::Item) and Item."Inventory Value Zero" then
                JobJnlLine."Total Cost (LCY)" := 0
            else
                JobJnlLine."Total Cost (LCY)" :=
                  Round(JobJnlLine."Unit Cost (LCY)" * JobJnlLine.Quantity, LCYCurrency."Amount Rounding Precision");

            if "Currency Code" = '' then
                JobJnlLine."Direct Unit Cost (LCY)" := "Direct Unit Cost"
            else
                JobJnlLine."Direct Unit Cost (LCY)" :=
                  CurrencyExchRate.ExchangeAmtFCYToLCY(
                    PurchHeader."Posting Date",
                    "Currency Code",
                    "Direct Unit Cost",
                    PurchHeader."Currency Factor");

            JobJnlLine."Unit Price (LCY)" := "Job Unit Price (LCY)";
            JobJnlLine."Unit Price" := "Job Unit Price";
            JobJnlLine."Line Discount %" := "Job Line Discount %";

            if Quantity <> 0 then begin
                GetCurrencyRounding(PurchHeader."Currency Code");

                Factor := "Qty. to Invoice" / Quantity;
                JobJnlLine."Total Price (LCY)" :=
                  Round("Job Total Price (LCY)" * Factor, LCYCurrency."Amount Rounding Precision");
                JobJnlLine."Total Price" :=
                  Round("Job Total Price" * Factor, Currency."Amount Rounding Precision");
                JobJnlLine."Line Amount (LCY)" :=
                  Round("Job Line Amount (LCY)" * Factor, LCYCurrency."Amount Rounding Precision");
                JobJnlLine."Line Amount" :=
                  Round("Job Line Amount" * Factor, Currency."Amount Rounding Precision");
                JobJnlLine."Line Discount Amount (LCY)" :=
                  Round("Job Line Disc. Amount (LCY)" * Factor, LCYCurrency."Amount Rounding Precision");
                JobJnlLine."Line Discount Amount" :=
                  Round("Job Line Discount Amount" * Factor, Currency."Amount Rounding Precision");
            end;

            JobJnlLine."Job Planning Line No." := "Job Planning Line No.";
            JobJnlLine."Remaining Qty." := "Job Remaining Qty.";
            JobJnlLine."Remaining Qty. (Base)" := "Job Remaining Qty. (Base)";
            JobJnlLine."Location Code" := "Location Code";
            JobJnlLine."Bin Code" := "Bin Code";
            JobJnlLine."Line Type" := "Job Line Type";
            JobJnlLine."Entry Type" := JobJnlLine."Entry Type"::Usage;
            JobJnlLine.Description := Description;
            JobJnlLine."Description 2" := "Description 2";
            JobJnlLine."Gen. Bus. Posting Group" := "Gen. Bus. Posting Group";
            JobJnlLine."Gen. Prod. Posting Group" := "Gen. Prod. Posting Group";
            JobJnlLine."Source Code" := SourceCode;
            JobJnlLine."Reason Code" := PurchHeader."Reason Code";
            JobJnlLine."Document Date" := PurchHeader."Document Date";
            JobJnlLine."Shortcut Dimension 1 Code" := "Shortcut Dimension 1 Code";
            JobJnlLine."Shortcut Dimension 2 Code" := "Shortcut Dimension 2 Code";
            JobJnlLine."Dimension Set ID" := "Dimension Set ID";
        end;

        OnAfterFromPurchaseLineToJnlLine(JobJnlLine, PurchHeader, PurchInvHeader, PurchCrMemoHeader, PurchLine, SourceCode);
    end;

    procedure FromSalesHeaderToPlanningLine(SalesLine: Record "Sales Line"; CurrencyFactor: Decimal)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetCurrentKey("Job Contract Entry No.");
        JobPlanningLine.SetRange("Job Contract Entry No.", SalesLine."Job Contract Entry No.");
        if JobPlanningLine.FindFirst then begin
            // Update Prices
            if JobPlanningLine."Currency Code" <> '' then begin
                JobPlanningLine."Unit Price (LCY)" := SalesLine."Unit Price" / CurrencyFactor;
                JobPlanningLine."Total Price (LCY)" := JobPlanningLine."Unit Price (LCY)" * JobPlanningLine.Quantity;
                JobPlanningLine."Line Amount (LCY)" := JobPlanningLine."Total Price (LCY)";
                JobPlanningLine."Unit Price" := JobPlanningLine."Unit Price (LCY)";
                JobPlanningLine."Total Price" := JobPlanningLine."Total Price (LCY)";
                JobPlanningLine."Line Amount" := JobPlanningLine."Total Price (LCY)";
            end else begin
                JobPlanningLine."Unit Price (LCY)" := SalesLine."Unit Price" / CurrencyFactor;
                JobPlanningLine."Total Price (LCY)" := JobPlanningLine."Unit Price (LCY)" * JobPlanningLine.Quantity;
                JobPlanningLine."Line Amount (LCY)" := JobPlanningLine."Total Price (LCY)";
            end;
            OnAfterFromSalesHeaderToPlanningLine(JobPlanningLine, SalesLine, CurrencyFactor);
            JobPlanningLine.Modify;
        end;
    end;

    procedure GetCurrencyRounding(CurrencyCode: Code[10])
    begin
        if CurrencyRoundingRead then
            exit;
        CurrencyRoundingRead := true;
        if CurrencyCode = '' then
            Currency.InitRoundingPrecision
        else begin
            Currency.Get(CurrencyCode);
            Currency.TestField("Amount Rounding Precision");
        end;
        LCYCurrency.InitRoundingPrecision;
    end;

    local procedure DoUpdateUnitCost(SalesLine: Record "Sales Line"): Boolean
    var
        Item: Record Item;
    begin
        if SalesLine.Type = SalesLine.Type::Item then begin
            Item.Get(SalesLine."No.");
            if Item."Costing Method" = Item."Costing Method"::Standard then
                exit(false); // Do not update Unit Cost in Job Journal Line, it is correct.
        end;

        exit(true);
    end;

    procedure ValidateUnitCostAndPrice(var JobJournalLine: Record "Job Journal Line"; SalesLine: Record "Sales Line"; UnitCost: Decimal; UnitPrice: Decimal)
    begin
        if DoUpdateUnitCost(SalesLine) then
            JobJournalLine.Validate("Unit Cost", UnitCost);
        JobJournalLine.Validate("Unit Price", UnitPrice);
    end;

    local procedure UpdateBaseQtyForPurchLine(var Item: Record Item; PurchLine: Record "Purchase Line"): Boolean
    begin
        if PurchLine.Type = PurchLine.Type::Item then begin
            Item.Get(PurchLine."No.");
            Item.TestField("Base Unit of Measure");
            exit(PurchLine."Unit of Measure Code" <> Item."Base Unit of Measure");
        end;
        exit(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFromJnlLineToLedgEntry(var JobLedgerEntry: Record "Job Ledger Entry"; JobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFromJnlToPlanningLine(var JobPlanningLine: Record "Job Planning Line"; JobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFromPlanningSalesLineToJnlLine(var JobJnlLine: Record "Job Journal Line"; JobPlanningLine: Record "Job Planning Line"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; EntryType: Option Usage,Sale)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFromPlanningLineToJnlLine(var JobJournalLine: Record "Job Journal Line"; JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFromGenJnlLineToJnlLine(var JobJnlLine: Record "Job Journal Line"; GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFromJobLedgEntryToPlanningLine(var JobPlanningLine: Record "Job Planning Line"; JobLedgEntry: Record "Job Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFromPurchaseLineToJnlLine(var JobJnlLine: Record "Job Journal Line"; PurchHeader: Record "Purchase Header"; PurchInvHeader: Record "Purch. Inv. Header"; PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr."; PurchLine: Record "Purchase Line"; SourceCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFromSalesHeaderToPlanningLine(var JobPlanningLine: Record "Job Planning Line"; SalesLine: Record "Sales Line"; CurrencyFactor: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFromPlanningSalesLineToJnlLine(var JobPlanningLine: Record "Job Planning Line"; var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var JobJnlLine: Record "Job Journal Line"; var EntryType: Option Usage,Sale)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFromPurchaseLineToJnlLine(PurchHeader: Record "Purchase Header"; PurchInvHeader: Record "Purch. Inv. Header"; PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr."; PurchLine: Record "Purchase Line"; SourceCode: Code[10]; var JobJnlLine: Record "Job Journal Line"; var IsHandled: Boolean)
    begin
    end;
}

