codeunit 1002 "Job Create-Invoice"
{

    trigger OnRun()
    begin
    end;

    var
        Currency: Record Currency;
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempJobPlanningLine: Record "Job Planning Line" temporary;
        Text000: Label 'The lines were successfully transferred to an invoice.';
        Text001: Label 'The lines were not transferred to an invoice.';
        Text002: Label 'There was no %1 with a %2 larger than 0. No lines were transferred.';
        Text003: Label '%1 may not be lower than %2 and may not exceed %3.';
        Text004: Label 'You must specify Invoice No. or New Invoice.';
        Text005: Label 'You must specify Credit Memo No. or New Invoice.';
        Text007: Label 'You must specify %1.';
        TransferExtendedText: Codeunit "Transfer Extended Text";
        JobInvCurrency: Boolean;
        UpdateExchangeRates: Boolean;
        Text008: Label 'The lines were successfully transferred to a credit memo.';
        Text009: Label 'The selected planning lines must have the same %1.';
        Text010: Label 'The currency dates on all planning lines will be updated based on the invoice posting date because there is a difference in currency exchange rates. Recalculations will be based on the Exch. Calculation setup for the Cost and Price values for the job. Do you want to continue?';
        Text011: Label 'The currency exchange rate on all planning lines will be updated based on the exchange rate on the sales invoice. Do you want to continue?';
        Text012: Label 'The %1 %2 does not exist anymore. A printed copy of the document was created before the document was deleted.', Comment = 'The Sales Invoice Header 103001 does not exist in the system anymore. A printed copy of the document was created before deletion.';
        NoOfSalesLinesCreated: Integer;

    procedure CreateSalesInvoice(var JobPlanningLine: Record "Job Planning Line"; CrMemo: Boolean)
    var
        SalesHeader: Record "Sales Header";
        GetSalesInvoiceNo: Report "Job Transfer to Sales Invoice";
        GetSalesCrMemoNo: Report "Job Transfer to Credit Memo";
        Done: Boolean;
        NewInvoice: Boolean;
        PostingDate: Date;
        InvoiceNo: Code[20];
        IsHandled: Boolean;
    begin
        if not CrMemo then begin
            GetSalesInvoiceNo.SetCustomer(JobPlanningLine."Job No.");
            GetSalesInvoiceNo.RunModal;
            IsHandled := false;
            OnBeforeGetInvoiceNo(JobPlanningLine, Done, NewInvoice, PostingDate, InvoiceNo, IsHandled);
            if not IsHandled then
                GetSalesInvoiceNo.GetInvoiceNo(Done, NewInvoice, PostingDate, InvoiceNo);
        end else begin
            GetSalesCrMemoNo.SetCustomer(JobPlanningLine."Job No.");
            GetSalesCrMemoNo.RunModal;
            IsHandled := false;
            OnBeforeGetCrMemoNo(JobPlanningLine, Done, NewInvoice, PostingDate, InvoiceNo, IsHandled);
            if not IsHandled then
                GetSalesCrMemoNo.GetCreditMemoNo(Done, NewInvoice, PostingDate, InvoiceNo);
        end;

        if Done then begin
            if (PostingDate = 0D) and NewInvoice then
                Error(Text007, SalesHeader.FieldCaption("Posting Date"));
            if (InvoiceNo = '') and not NewInvoice then begin
                if CrMemo then
                    Error(Text005);
                Error(Text004);
            end;
            CreateSalesInvoiceLines(
              JobPlanningLine."Job No.", JobPlanningLine, InvoiceNo, NewInvoice, PostingDate, CrMemo);

            Commit();

            if CrMemo then
                Message(Text008)
            else
                Message(Text000);
        end;
    end;

    procedure CreateSalesInvoiceLines(JobNo: Code[20]; var JobPlanningLineSource: Record "Job Planning Line"; InvoiceNo: Code[20]; NewInvoice: Boolean; PostingDate: Date; CreditMemo: Boolean)
    var
        Cust: Record Customer;
        Job: Record Job;
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
        LineCounter: Integer;
        IsHandled: Boolean;
    begin
        OnBeforeCreateSalesInvoiceLines(JobPlanningLineSource, InvoiceNo, NewInvoice, PostingDate, CreditMemo);

        ClearAll;
        Job.Get(JobNo);
        OnCreateSalesInvoiceLinesOnBeforeTestJob(Job);
        if Job.Blocked = Job.Blocked::All then
            Job.TestBlocked;
        if Job."Currency Code" = '' then
            JobInvCurrency := Job."Invoice Currency Code" <> '';
        Job.TestField("Bill-to Customer No.");

        IsHandled := false;
        OnCreateSalesInvoiceLinesOnBeforeGetCustomer(JobPlanningLineSource, Cust, IsHandled);
        if not IsHandled then
            Cust.Get(Job."Bill-to Customer No.");
        if CreditMemo then
            SalesHeader2."Document Type" := SalesHeader2."Document Type"::"Credit Memo"
        else
            SalesHeader2."Document Type" := SalesHeader2."Document Type"::Invoice;

        if not NewInvoice then
            SalesHeader.Get(SalesHeader2."Document Type", InvoiceNo);

        JobPlanningLine.Copy(JobPlanningLineSource);
        JobPlanningLine.SetCurrentKey("Job No.", "Job Task No.", "Line No.");

        if JobPlanningLine.FindSet then
            repeat
                if TransferLine(JobPlanningLine) then begin
                    LineCounter := LineCounter + 1;
                    if JobPlanningLine."Job No." <> JobNo then
                        Error(Text009, JobPlanningLine.FieldCaption("Job No."));
                    if NewInvoice then
                        TestExchangeRate(JobPlanningLine, PostingDate)
                    else
                        TestExchangeRate(JobPlanningLine, SalesHeader."Posting Date");
                end;
            until JobPlanningLine.Next = 0;

        if LineCounter = 0 then
            Error(Text002,
              JobPlanningLine.TableCaption,
              JobPlanningLine.FieldCaption("Qty. to Transfer to Invoice"));

        if NewInvoice then
            CreateSalesHeader(Job, PostingDate)
        else
            TestSalesHeader(SalesHeader, Job);
        if JobPlanningLine.Find('-') then
            repeat
                if TransferLine(JobPlanningLine) then begin
                    if JobPlanningLine.Type in [JobPlanningLine.Type::Resource,
                                                JobPlanningLine.Type::Item,
                                                JobPlanningLine.Type::"G/L Account"]
                    then
                        JobPlanningLine.TestField("No.");

                    OnCreateSalesInvoiceLinesOnBeforeCreateSalesLine(
                      JobPlanningLine, SalesHeader, SalesHeader2, NewInvoice, NoOfSalesLinesCreated);
                    CreateSalesLine(JobPlanningLine);

                    JobPlanningLineInvoice.InitFromJobPlanningLine(JobPlanningLine);
                    if NewInvoice then
                        JobPlanningLineInvoice.InitFromSales(SalesHeader, PostingDate, SalesLine."Line No.")
                    else
                        JobPlanningLineInvoice.InitFromSales(SalesHeader, SalesHeader."Posting Date", SalesLine."Line No.");
                    JobPlanningLineInvoice.Insert();

                    JobPlanningLine.UpdateQtyToTransfer;
                    JobPlanningLine.Modify();
                end;
            until JobPlanningLine.Next = 0;

        JobPlanningLineSource.FindFirst;
        JobPlanningLineSource.CalcFields("Qty. Transferred to Invoice");

        if NoOfSalesLinesCreated = 0 then
            Error(Text002, JobPlanningLine.TableCaption, JobPlanningLine.FieldCaption("Qty. to Transfer to Invoice"));

        OnAfterCreateSalesInvoiceLines(SalesHeader, NewInvoice);
    end;

    procedure DeleteSalesInvoiceBuffer()
    begin
        ClearAll;
        TempJobPlanningLine.DeleteAll();
    end;

    procedure CreateSalesInvoiceJobTask(var JobTask2: Record "Job Task"; PostingDate: Date; InvoicePerTask: Boolean; var NoOfInvoices: Integer; var OldJobNo: Code[20]; var OldJobTaskNo: Code[20]; LastJobTask: Boolean)
    var
        Cust: Record Customer;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateSalesInvoiceJobTask(
          JobTask2, PostingDate, InvoicePerTask, NoOfInvoices, OldJobNo, OldJobTaskNo, LastJobTask, IsHandled);
        if IsHandled then
            exit;

        ClearAll;
        if not LastJobTask then begin
            JobTask := JobTask2;
            if JobTask."Job No." = '' then
                exit;
            if JobTask."Job Task No." = '' then
                exit;
            JobTask.Find;
            if JobTask."Job Task Type" <> JobTask."Job Task Type"::Posting then
                exit;
            Job.Get(JobTask."Job No.");
        end;
        if LastJobTask then begin
            if not TempJobPlanningLine.Find('-') then
                exit;
            Job.Get(TempJobPlanningLine."Job No.");
            JobTask.Get(TempJobPlanningLine."Job No.", TempJobPlanningLine."Job Task No.");
        end;

        OnCreateSalesInvoiceJobTaskTestJob(Job);
        Job.TestField("Bill-to Customer No.");
        if Job.Blocked = Job.Blocked::All then
            Job.TestBlocked;
        if Job."Currency Code" = '' then
            JobInvCurrency := Job."Invoice Currency Code" <> '';
        Cust.Get(Job."Bill-to Customer No.");

        if CreateNewInvoice(JobTask, InvoicePerTask, OldJobNo, OldJobTaskNo, LastJobTask) then begin
            Job.Get(TempJobPlanningLine."Job No.");
            Cust.Get(Job."Bill-to Customer No.");
            NoOfInvoices := NoOfInvoices + 1;
            SalesHeader2."Document Type" := SalesHeader2."Document Type"::Invoice;
            CreateSalesHeader(Job, PostingDate);
            if TempJobPlanningLine.Find('-') then
                repeat
                    Job.Get(TempJobPlanningLine."Job No.");
                    JobInvCurrency := (Job."Currency Code" = '') and (Job."Invoice Currency Code" <> '');
                    JobPlanningLine := TempJobPlanningLine;
                    JobPlanningLine.Find;
                    if JobPlanningLine.Type in [JobPlanningLine.Type::Resource,
                                                JobPlanningLine.Type::Item,
                                                JobPlanningLine.Type::"G/L Account"]
                    then
                        JobPlanningLine.TestField("No.");
                    TestExchangeRate(JobPlanningLine, PostingDate);

                    OnCreateSalesInvoiceJobTaskOnBeforeCreateSalesLine(JobPlanningLine, SalesHeader, SalesHeader2, NoOfSalesLinesCreated);
                    CreateSalesLine(JobPlanningLine);

                    JobPlanningLineInvoice."Job No." := JobPlanningLine."Job No.";
                    JobPlanningLineInvoice."Job Task No." := JobPlanningLine."Job Task No.";
                    JobPlanningLineInvoice."Job Planning Line No." := JobPlanningLine."Line No.";
                    if SalesHeader."Document Type" = SalesHeader."Document Type"::Invoice then
                        JobPlanningLineInvoice."Document Type" := JobPlanningLineInvoice."Document Type"::Invoice;
                    if SalesHeader."Document Type" = SalesHeader."Document Type"::"Credit Memo" then
                        JobPlanningLineInvoice."Document Type" := JobPlanningLineInvoice."Document Type"::"Credit Memo";
                    JobPlanningLineInvoice."Document No." := SalesHeader."No.";
                    JobPlanningLineInvoice."Line No." := SalesLine."Line No.";
                    JobPlanningLineInvoice."Quantity Transferred" := JobPlanningLine."Qty. to Transfer to Invoice";
                    JobPlanningLineInvoice."Transferred Date" := PostingDate;
                    JobPlanningLineInvoice.Insert();

                    JobPlanningLine.UpdateQtyToTransfer;
                    JobPlanningLine.Modify();
                until TempJobPlanningLine.Next = 0;
            TempJobPlanningLine.DeleteAll();
        end;

        OnCreateSalesInvoiceJobTaskOnAfterLinesCreated(SalesHeader, Job);

        if LastJobTask then begin
            if NoOfSalesLinesCreated = 0 then
                Error(Text002, JobPlanningLine.TableCaption, JobPlanningLine.FieldCaption("Qty. to Transfer to Invoice"));
            exit;
        end;

        JobPlanningLine.Reset();
        JobPlanningLine.SetCurrentKey("Job No.", "Job Task No.");
        JobPlanningLine.SetRange("Job No.", JobTask2."Job No.");
        JobPlanningLine.SetRange("Job Task No.", JobTask2."Job Task No.");
        JobPlanningLine.SetFilter("Planning Date", JobTask2.GetFilter("Planning Date Filter"));
        if JobPlanningLine.Find('-') then
            repeat
                if TransferLine(JobPlanningLine) then begin
                    TempJobPlanningLine := JobPlanningLine;
                    TempJobPlanningLine.Insert();
                end;
            until JobPlanningLine.Next = 0;
    end;

    local procedure CreateNewInvoice(var JobTask: Record "Job Task"; InvoicePerTask: Boolean; var OldJobNo: Code[20]; var OldJobTaskNo: Code[20]; LastJobTask: Boolean): Boolean
    var
        NewInvoice: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateNewInvoice(JobTask, InvoicePerTask, OldJobNo, OldJobTaskNo, LastJobTask, NewInvoice, IsHandled);
        if IsHandled then
            exit(NewInvoice);

        if LastJobTask then
            NewInvoice := true
        else begin
            if OldJobNo <> '' then begin
                if InvoicePerTask then
                    if (OldJobNo <> JobTask."Job No.") or (OldJobTaskNo <> JobTask."Job Task No.") then
                        NewInvoice := true;
                if not InvoicePerTask then
                    if OldJobNo <> JobTask."Job No." then
                        NewInvoice := true;
            end;
            OldJobNo := JobTask."Job No.";
            OldJobTaskNo := JobTask."Job Task No.";
        end;
        if not TempJobPlanningLine.Find('-') then
            NewInvoice := false;
        exit(NewInvoice);
    end;

    local procedure CreateSalesHeader(Job: Record Job; PostingDate: Date)
    var
        SalesSetup: Record "Sales & Receivables Setup";
        Cust: Record Customer;
        IsHandled: Boolean;
    begin
        SalesSetup.Get();
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader2."Document Type";
        if SalesHeader."Document Type" = SalesHeader."Document Type"::Invoice then
            SalesSetup.TestField("Invoice Nos.");
        if SalesHeader."Document Type" = SalesHeader."Document Type"::"Credit Memo" then
            SalesSetup.TestField("Credit Memo Nos.");
        SalesHeader."Posting Date" := PostingDate;
        OnBeforeInsertSalesHeader(SalesHeader, Job);
        SalesHeader.Insert(true);
        Cust.Get(Job."Bill-to Customer No.");
        Cust.TestField("Bill-to Customer No.", '');
        SalesHeader.Validate("Sell-to Customer No.", Job."Bill-to Customer No.");
        if Job."Currency Code" <> '' then
            SalesHeader.Validate("Currency Code", Job."Currency Code")
        else
            SalesHeader.Validate("Currency Code", Job."Invoice Currency Code");
        if PostingDate <> 0D then
            SalesHeader.Validate("Posting Date", PostingDate);

        IsHandled := false;
        OnCreateSalesHeaderOnBeforeUpdateSalesHeader(SalesHeader, Job, IsHandled);
        if not IsHandled then
            UpdateSalesHeader(SalesHeader, Job);
        OnBeforeModifySalesHeader(SalesHeader, Job);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesLine(var JobPlanningLine: Record "Job Planning Line")
    var
        Job: Record Job;
        SourceCodeSetup: Record "Source Code Setup";
        DimMgt: Codeunit DimensionManagement;
        Factor: Integer;
        DimSetIDArr: array[10] of Integer;
    begin
        Factor := 1;
        if SalesHeader2."Document Type" = SalesHeader2."Document Type"::"Credit Memo" then
            Factor := -1;
        TestTransferred(JobPlanningLine);
        JobPlanningLine.TestField("Planning Date");
        Job.Get(JobPlanningLine."Job No.");
        Clear(SalesLine);
        SalesLine."Document Type" := SalesHeader2."Document Type";
        SalesLine."Document No." := SalesHeader."No.";

        if (not JobInvCurrency) and (JobPlanningLine.Type <> JobPlanningLine.Type::Text) then begin
            SalesHeader.TestField("Currency Code", JobPlanningLine."Currency Code");
            if (Job."Currency Code" <> '') and (JobPlanningLine."Currency Factor" <> SalesHeader."Currency Factor") then begin
                if Confirm(Text011) then begin
                    JobPlanningLine.Validate("Currency Factor", SalesHeader."Currency Factor");
                    JobPlanningLine.Modify();
                end else
                    Error(Text001);
            end;
            SalesHeader.TestField("Currency Code", Job."Currency Code");
        end;
        if JobPlanningLine.Type = JobPlanningLine.Type::Text then
            SalesLine.Validate(Type, SalesLine.Type::" ");
        if JobPlanningLine.Type = JobPlanningLine.Type::"G/L Account" then
            SalesLine.Validate(Type, SalesLine.Type::"G/L Account");
        if JobPlanningLine.Type = JobPlanningLine.Type::Item then
            SalesLine.Validate(Type, SalesLine.Type::Item);
        if JobPlanningLine.Type = JobPlanningLine.Type::Resource then
            SalesLine.Validate(Type, SalesLine.Type::Resource);

        SalesLine.Validate("No.", JobPlanningLine."No.");
        SalesLine.Validate("Gen. Prod. Posting Group", JobPlanningLine."Gen. Prod. Posting Group");
        SalesLine.Validate("Location Code", JobPlanningLine."Location Code");
        SalesLine.Validate("Work Type Code", JobPlanningLine."Work Type Code");
        SalesLine.Validate("Variant Code", JobPlanningLine."Variant Code");

        if SalesLine.Type <> SalesLine.Type::" " then begin
            SalesLine.Validate("Unit of Measure Code", JobPlanningLine."Unit of Measure Code");
            SalesLine.Validate(Quantity, Factor * JobPlanningLine."Qty. to Transfer to Invoice");
            if JobInvCurrency then begin
                Currency.Get(SalesLine."Currency Code");
                SalesLine.Validate("Unit Price",
                  Round(JobPlanningLine."Unit Price" * SalesHeader."Currency Factor",
                    Currency."Unit-Amount Rounding Precision"));
            end else
                SalesLine.Validate("Unit Price", JobPlanningLine."Unit Price");
            SalesLine.Validate("Unit Cost (LCY)", JobPlanningLine."Unit Cost (LCY)");
            SalesLine.Validate("Line Discount %", JobPlanningLine."Line Discount %");
            SalesLine."Inv. Discount Amount" := 0;
            SalesLine."Inv. Disc. Amount to Invoice" := 0;
            SalesLine.UpdateAmounts;
        end;
        if not SalesHeader."Prices Including VAT" then
            SalesLine.Validate("Job Contract Entry No.", JobPlanningLine."Job Contract Entry No.");
        SalesLine."Job No." := JobPlanningLine."Job No.";
        SalesLine."Job Task No." := JobPlanningLine."Job Task No.";
        if SalesLine."Job Task No." <> '' then begin
            SourceCodeSetup.Get();
            DimSetIDArr[1] := SalesLine."Dimension Set ID";
            DimSetIDArr[2] :=
              DimMgt.CreateDimSetFromJobTaskDim(
                SalesLine."Job No.", SalesLine."Job Task No.", SalesLine."Shortcut Dimension 1 Code", SalesLine."Shortcut Dimension 2 Code");
            DimSetIDArr[3] := GetLedgEntryDimSetID(JobPlanningLine);
            DimSetIDArr[4] := GetJobLedgEntryDimSetID(JobPlanningLine);
            DimMgt.CreateDimForSalesLineWithHigherPriorities(
              SalesLine,
              0,
              DimSetIDArr[5],
              SalesLine."Shortcut Dimension 1 Code",
              SalesLine."Shortcut Dimension 2 Code",
              SourceCodeSetup.Sales,
              DATABASE::Job);
            SalesLine."Dimension Set ID" :=
              DimMgt.GetCombinedDimensionSetID(
                DimSetIDArr, SalesLine."Shortcut Dimension 1 Code", SalesLine."Shortcut Dimension 2 Code");
        end;
        SalesLine.Description := JobPlanningLine.Description;
        SalesLine."Description 2" := JobPlanningLine."Description 2";
        SalesLine."Line No." := GetNextLineNo(SalesLine);
        OnBeforeInsertSalesLine(SalesLine, SalesHeader, Job, JobPlanningLine);
        SalesLine.Insert(true);

        if SalesLine.Type <> SalesLine.Type::" " then begin
            NoOfSalesLinesCreated += 1;
            CalculateInvoiceDiscount(SalesLine, SalesHeader);
        end;

        if SalesHeader."Prices Including VAT" and (SalesLine.Type <> SalesLine.Type::" ") then begin
            Currency.Initialize(SalesLine."Currency Code");
            SalesLine."Unit Price" :=
              Round(
                SalesLine."Unit Price" * (1 + (SalesLine."VAT %" / 100)),
                Currency."Unit-Amount Rounding Precision");
            if SalesLine.Quantity <> 0 then begin
                SalesLine."Line Discount Amount" :=
                  Round(
                    SalesLine.Quantity * SalesLine."Unit Price" * SalesLine."Line Discount %" / 100,
                    Currency."Amount Rounding Precision");
                SalesLine.Validate("Inv. Discount Amount",
                  Round(
                    SalesLine."Inv. Discount Amount" * (1 + (SalesLine."VAT %" / 100)),
                    Currency."Amount Rounding Precision"));
            end;
            SalesLine.Validate("Job Contract Entry No.", JobPlanningLine."Job Contract Entry No.");
            OnBeforeModifySalesLine(SalesLine, SalesHeader, Job, JobPlanningLine);
            SalesLine.Modify();
            JobPlanningLine."VAT Unit Price" := SalesLine."Unit Price";
            JobPlanningLine."VAT Line Discount Amount" := SalesLine."Line Discount Amount";
            JobPlanningLine."VAT Line Amount" := SalesLine."Line Amount";
            JobPlanningLine."VAT %" := SalesLine."VAT %";
        end;
        if TransferExtendedText.SalesCheckIfAnyExtText(SalesLine, false) then
            TransferExtendedText.InsertSalesExtText(SalesLine);

        OnAfterCreateSalesLine(SalesLine, SalesHeader, Job, JobPlanningLine);
    end;

    local procedure CalculateInvoiceDiscount(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    var
        TotalSalesHeader: Record "Sales Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        TotalSalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        TotalSalesHeader.CalcFields("Recalculate Invoice Disc.");

        SalesReceivablesSetup.Get();
        if SalesReceivablesSetup."Calc. Inv. Discount" and
           (SalesLine."Document No." <> '') and
           (TotalSalesHeader."Customer Posting Group" <> '') and
           TotalSalesHeader."Recalculate Invoice Disc."
        then
            CODEUNIT.Run(CODEUNIT::"Sales-Calc. Discount", SalesLine);
    end;

    local procedure TransferLine(var JobPlanningLine: Record "Job Planning Line"): Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransferLine(JobPlanningLine, IsHandled);
        if IsHandled then
            exit;

        with JobPlanningLine do begin
            if not "Contract Line" then
                exit(false);
            if Type = Type::Text then
                exit(true);
            exit("Qty. to Transfer to Invoice" <> 0);
        end;
    end;

    local procedure GetNextLineNo(SalesLine: Record "Sales Line"): Integer
    var
        NextLineNo: Integer;
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type");
        SalesLine.SetRange("Document No.", SalesLine."Document No.");
        NextLineNo := 10000;
        if SalesLine.FindLast then
            NextLineNo := SalesLine."Line No." + 10000;
        exit(NextLineNo);
    end;

    local procedure TestTransferred(JobPlanningLine: Record "Job Planning Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestTransferred(JobPlanningLine, SalesHeader2, IsHandled);
        if IsHandled then
            exit;

        with JobPlanningLine do begin
            CalcFields("Qty. Transferred to Invoice");
            if Quantity > 0 then begin
                if ("Qty. to Transfer to Invoice" > 0) and ("Qty. to Transfer to Invoice" > (Quantity - "Qty. Transferred to Invoice")) or
                   ("Qty. to Transfer to Invoice" < 0)
                then
                    Error(Text003, FieldCaption("Qty. to Transfer to Invoice"), 0, Quantity - "Qty. Transferred to Invoice");
            end else begin
                if ("Qty. to Transfer to Invoice" > 0) or
                   ("Qty. to Transfer to Invoice" < 0) and ("Qty. to Transfer to Invoice" < (Quantity - "Qty. Transferred to Invoice"))
                then
                    Error(Text003, FieldCaption("Qty. to Transfer to Invoice"), Quantity - "Qty. Transferred to Invoice", 0);
            end;
        end;
    end;

    procedure DeleteSalesLine(SalesLine: Record "Sales Line")
    var
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
        JobPlanningLine: Record "Job Planning Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteSalesLine(SalesLine, IsHandled);
        if IsHandled then
            exit;

        with JobPlanningLineInvoice do begin
            case SalesLine."Document Type" of
                SalesLine."Document Type"::Invoice:
                    SetRange("Document Type", "Document Type"::Invoice);
                SalesLine."Document Type"::"Credit Memo":
                    SetRange("Document Type", "Document Type"::"Credit Memo");
            end;
            SetRange("Document No.", SalesLine."Document No.");
            SetRange("Line No.", SalesLine."Line No.");
            if FindSet then
                repeat
                    JobPlanningLine.Get("Job No.", "Job Task No.", "Job Planning Line No.");
                    Delete;
                    JobPlanningLine.UpdateQtyToTransfer;
                    OnDeleteSalesLineOnBeforeJobPlanningLineModify(JobPlanningLine);
                    JobPlanningLine.Modify();
                until Next = 0;
        end;
    end;

    procedure FindInvoices(var TempJobPlanningLineInvoice: Record "Job Planning Line Invoice" temporary; JobNo: Code[20]; JobTaskNo: Code[20]; JobPlanningLineNo: Integer; DetailLevel: Option All,"Per Job","Per Job Task","Per Job Planning Line")
    var
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
        RecordFound: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeFindInvoices(TempJobPlanningLineInvoice, JobNo, JobTaskNo, JobPlanningLineNo, DetailLevel, IsHandled);
        if IsHandled then
            exit;

        case DetailLevel of
            DetailLevel::All:
                begin
                    if JobPlanningLineInvoice.FindSet then
                        TempJobPlanningLineInvoice := JobPlanningLineInvoice;
                    exit;
                end;
            DetailLevel::"Per Job":
                JobPlanningLineInvoice.SetRange("Job No.", JobNo);
            DetailLevel::"Per Job Task":
                begin
                    JobPlanningLineInvoice.SetRange("Job No.", JobNo);
                    JobPlanningLineInvoice.SetRange("Job Task No.", JobTaskNo);
                end;
            DetailLevel::"Per Job Planning Line":
                begin
                    JobPlanningLineInvoice.SetRange("Job No.", JobNo);
                    JobPlanningLineInvoice.SetRange("Job Task No.", JobTaskNo);
                    JobPlanningLineInvoice.SetRange("Job Planning Line No.", JobPlanningLineNo);
                end;
        end;

        TempJobPlanningLineInvoice.DeleteAll();
        if JobPlanningLineInvoice.FindSet then begin
            repeat
                RecordFound := false;
                case DetailLevel of
                    DetailLevel::"Per Job":
                        if TempJobPlanningLineInvoice.Get(
                             JobNo, '', 0, JobPlanningLineInvoice."Document Type", JobPlanningLineInvoice."Document No.", 0)
                        then
                            RecordFound := true;
                    DetailLevel::"Per Job Task":
                        if TempJobPlanningLineInvoice.Get(
                             JobNo, JobTaskNo, 0, JobPlanningLineInvoice."Document Type", JobPlanningLineInvoice."Document No.", 0)
                        then
                            RecordFound := true;
                    DetailLevel::"Per Job Planning Line":
                        if TempJobPlanningLineInvoice.Get(
                             JobNo, JobTaskNo, JobPlanningLineNo, JobPlanningLineInvoice."Document Type", JobPlanningLineInvoice."Document No.", 0)
                        then
                            RecordFound := true;
                end;

                if RecordFound then begin
                    TempJobPlanningLineInvoice."Quantity Transferred" += JobPlanningLineInvoice."Quantity Transferred";
                    TempJobPlanningLineInvoice."Invoiced Amount (LCY)" += JobPlanningLineInvoice."Invoiced Amount (LCY)";
                    TempJobPlanningLineInvoice."Invoiced Cost Amount (LCY)" += JobPlanningLineInvoice."Invoiced Cost Amount (LCY)";
                    TempJobPlanningLineInvoice.Modify();
                end else begin
                    case DetailLevel of
                        DetailLevel::"Per Job":
                            TempJobPlanningLineInvoice."Job No." := JobNo;
                        DetailLevel::"Per Job Task":
                            begin
                                TempJobPlanningLineInvoice."Job No." := JobNo;
                                TempJobPlanningLineInvoice."Job Task No." := JobTaskNo;
                            end;
                        DetailLevel::"Per Job Planning Line":
                            begin
                                TempJobPlanningLineInvoice."Job No." := JobNo;
                                TempJobPlanningLineInvoice."Job Task No." := JobTaskNo;
                                TempJobPlanningLineInvoice."Job Planning Line No." := JobPlanningLineNo;
                            end;
                    end;
                    TempJobPlanningLineInvoice."Document Type" := JobPlanningLineInvoice."Document Type";
                    TempJobPlanningLineInvoice."Document No." := JobPlanningLineInvoice."Document No.";
                    TempJobPlanningLineInvoice."Quantity Transferred" := JobPlanningLineInvoice."Quantity Transferred";
                    TempJobPlanningLineInvoice."Invoiced Amount (LCY)" := JobPlanningLineInvoice."Invoiced Amount (LCY)";
                    TempJobPlanningLineInvoice."Invoiced Cost Amount (LCY)" := JobPlanningLineInvoice."Invoiced Cost Amount (LCY)";
                    TempJobPlanningLineInvoice."Invoiced Date" := JobPlanningLineInvoice."Invoiced Date";
                    TempJobPlanningLineInvoice."Transferred Date" := JobPlanningLineInvoice."Transferred Date";
                    TempJobPlanningLineInvoice.Insert();
                end;
            until JobPlanningLineInvoice.Next = 0;
        end;
    end;

    procedure GetJobPlanningLineInvoices(JobPlanningLine: Record "Job Planning Line")
    var
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
    begin
        ClearAll;
        with JobPlanningLine do begin
            if "Line No." = 0 then
                exit;
            TestField("Job No.");
            TestField("Job Task No.");

            JobPlanningLineInvoice.SetRange("Job No.", "Job No.");
            JobPlanningLineInvoice.SetRange("Job Task No.", "Job Task No.");
            JobPlanningLineInvoice.SetRange("Job Planning Line No.", "Line No.");
            if JobPlanningLineInvoice.Count = 1 then begin
                JobPlanningLineInvoice.FindFirst;
                OpenSalesInvoice(JobPlanningLineInvoice);
            end else
                PAGE.RunModal(PAGE::"Job Invoices", JobPlanningLineInvoice);
        end;
    end;

    procedure OpenSalesInvoice(JobPlanningLineInvoice: Record "Job Planning Line Invoice")
    var
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOpenSalesInvoice(JobPlanningLineInvoice, IsHandled);
        if IsHandled then
            exit;

        with JobPlanningLineInvoice do
            case "Document Type" of
                "Document Type"::Invoice:
                    begin
                        SalesHeader.Get(SalesHeader."Document Type"::Invoice, "Document No.");
                        PAGE.RunModal(PAGE::"Sales Invoice", SalesHeader);
                    end;
                "Document Type"::"Credit Memo":
                    begin
                        SalesHeader.Get(SalesHeader."Document Type"::"Credit Memo", "Document No.");
                        PAGE.RunModal(PAGE::"Sales Credit Memo", SalesHeader);
                    end;
                "Document Type"::"Posted Invoice":
                    begin
                        if not SalesInvHeader.Get("Document No.") then
                            Error(Text012, SalesInvHeader.TableCaption, "Document No.");
                        PAGE.RunModal(PAGE::"Posted Sales Invoice", SalesInvHeader);
                    end;
                "Document Type"::"Posted Credit Memo":
                    begin
                        if not SalesCrMemoHeader.Get("Document No.") then
                            Error(Text012, SalesCrMemoHeader.TableCaption, "Document No.");
                        PAGE.RunModal(PAGE::"Posted Sales Credit Memo", SalesCrMemoHeader);
                    end;
            end;

        OnAfterOpenSalesInvoice(JobPlanningLineInvoice);
    end;

    local procedure UpdateSalesHeader(var SalesHeader: Record "Sales Header"; Job: Record Job)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateSalesHeader(SalesHeader, Job, IsHandled);
        if IsHandled then
            exit;

        SalesHeader."Bill-to Contact No." := Job."Bill-to Contact No.";
        SalesHeader."Bill-to Contact" := Job."Bill-to Contact";
        SalesHeader."Bill-to Name" := Job."Bill-to Name";
        SalesHeader."Bill-to Address" := Job."Bill-to Address";
        SalesHeader."Bill-to Address 2" := Job."Bill-to Address 2";
        SalesHeader."Bill-to City" := Job."Bill-to City";
        SalesHeader."Bill-to Post Code" := Job."Bill-to Post Code";

        SalesHeader."Sell-to Contact No." := Job."Bill-to Contact No.";
        SalesHeader."Sell-to Contact" := Job."Bill-to Contact";
        SalesHeader."Sell-to Customer Name" := Job."Bill-to Name";
        SalesHeader."Sell-to Address" := Job."Bill-to Address";
        SalesHeader."Sell-to Address 2" := Job."Bill-to Address 2";
        SalesHeader."Sell-to City" := Job."Bill-to City";
        SalesHeader."Sell-to Post Code" := Job."Bill-to Post Code";

        SalesHeader."Ship-to Contact" := Job."Bill-to Contact";
        SalesHeader."Ship-to Name" := Job."Bill-to Name";
        SalesHeader."Ship-to Address" := Job."Bill-to Address";
        SalesHeader."Ship-to Address 2" := Job."Bill-to Address 2";
        SalesHeader."Ship-to City" := Job."Bill-to City";
        SalesHeader."Ship-to Post Code" := Job."Bill-to Post Code";
    end;

    local procedure TestSalesHeader(var SalesHeader: Record "Sales Header"; var Job: Record Job)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestSalesHeader(SalesHeader, Job, IsHandled);
        if IsHandled then
            exit;

        SalesHeader.TestField("Bill-to Customer No.", Job."Bill-to Customer No.");
        SalesHeader.TestField("Sell-to Customer No.", Job."Bill-to Customer No.");

        if Job."Currency Code" <> '' then
            SalesHeader.TestField("Currency Code", Job."Currency Code")
        else
            SalesHeader.TestField("Currency Code", Job."Invoice Currency Code");
        OnAfterTestSalesHeader(SalesHeader, Job);
    end;

    local procedure TestExchangeRate(var JobPlanningLine: Record "Job Planning Line"; PostingDate: Date)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        if JobPlanningLine."Currency Code" <> '' then
            if (CurrencyExchangeRate.ExchangeRate(PostingDate, JobPlanningLine."Currency Code") <> JobPlanningLine."Currency Factor")
            then begin
                if not UpdateExchangeRates then
                    UpdateExchangeRates := Confirm(Text010, true);

                if UpdateExchangeRates then begin
                    JobPlanningLine."Currency Date" := PostingDate;
                    JobPlanningLine."Document Date" := PostingDate;
                    JobPlanningLine.Validate("Currency Date");
                    JobPlanningLine."Last Date Modified" := Today;
                    JobPlanningLine."User ID" := UserId;
                    JobPlanningLine.Modify(true);
                end else
                    Error('');
            end;
    end;

    local procedure GetLedgEntryDimSetID(JobPlanningLine: Record "Job Planning Line"): Integer
    var
        ResLedgEntry: Record "Res. Ledger Entry";
        ItemLedgEntry: Record "Item Ledger Entry";
        GLEntry: Record "G/L Entry";
    begin
        if JobPlanningLine."Ledger Entry No." = 0 then
            exit(0);

        case JobPlanningLine."Ledger Entry Type" of
            JobPlanningLine."Ledger Entry Type"::Resource:
                begin
                    ResLedgEntry.Get(JobPlanningLine."Ledger Entry No.");
                    exit(ResLedgEntry."Dimension Set ID");
                end;
            JobPlanningLine."Ledger Entry Type"::Item:
                begin
                    ItemLedgEntry.Get(JobPlanningLine."Ledger Entry No.");
                    exit(ItemLedgEntry."Dimension Set ID");
                end;
            JobPlanningLine."Ledger Entry Type"::"G/L Account":
                begin
                    GLEntry.Get(JobPlanningLine."Ledger Entry No.");
                    exit(GLEntry."Dimension Set ID");
                end;
            else
                exit(0);
        end;
    end;

    local procedure GetJobLedgEntryDimSetID(JobPlanningLine: Record "Job Planning Line"): Integer
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        if JobPlanningLine."Job Ledger Entry No." = 0 then
            exit(0);

        if JobLedgerEntry.Get(JobPlanningLine."Job Ledger Entry No.") then
            exit(JobLedgerEntry."Dimension Set ID");

        exit(0);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateSalesInvoiceLines(SalesHeader: Record "Sales Header"; NewInvoice: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Job: Record Job; var JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateNewInvoice(var JobTask: Record "Job Task"; InvoicePerTask: Boolean; var OldJobNo: Code[20]; var OldJobTaskNo: Code[20]; LastJobTask: Boolean; var NewInvoice: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateSalesInvoiceLines(var JobPlanningLine: Record "Job Planning Line"; InvoiceNo: Code[20]; NewInvoice: Boolean; PostingDate: Date; CreditMemo: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateSalesInvoiceJobTask(var JobTask2: Record "Job Task"; PostingDate: Date; InvoicePerTask: Boolean; var NoOfInvoices: Integer; var OldJobNo: Code[20]; var OldJobTaskNo: Code[20]; LastJobTask: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteSalesLine(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetInvoiceNo(var JobPlanningLine: Record "Job Planning Line"; Done: Boolean; NewInvoice: Boolean; PostingDate: Date; var InvoiceNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCrMemoNo(var JobPlanningLine: Record "Job Planning Line"; Done: Boolean; NewInvoice: Boolean; PostingDate: Date; var InvoiceNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertSalesHeader(var SalesHeader: Record "Sales Header"; Job: Record Job)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifySalesHeader(var SalesHeader: Record "Sales Header"; Job: Record Job)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertSalesLine(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header"; Job: Record Job; JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifySalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Job: Record Job; JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenSalesInvoice(var JobPlanningLineInvoice: Record "Job Planning Line Invoice"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestSalesHeader(var SalesHeader: Record "Sales Header"; Job: Record Job; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferLine(var JobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSalesHeader(var SalesHeader: Record "Sales Header"; Job: Record Job; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOpenSalesInvoice(var JobPlanningLineInvoice: Record "Job Planning Line Invoice")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestSalesHeader(var SalesHeader: Record "Sales Header"; Job: Record Job)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindInvoices(var TempJobPlanningLineInvoice: Record "Job Planning Line Invoice" temporary; JobNo: Code[20]; JobTaskNo: Code[20]; JobPlanningLineNo: Integer; DetailLevel: Option; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestTransferred(var JobPlanningLine: Record "Job Planning Line"; SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesHeaderOnBeforeUpdateSalesHeader(var SalesHeader: Record "Sales Header"; var Job: Record Job; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesInvoiceLinesOnBeforeCreateSalesLine(var JobPlanningLine: Record "Job Planning Line"; SalesHeader: Record "Sales Header"; SalesHeader2: Record "Sales Header"; NewInvoice: Boolean; var NoOfSalesLinesCreated: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesInvoiceLinesOnBeforeGetCustomer(JobPlanningLine: Record "Job Planning Line"; var Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesInvoiceLinesOnBeforeTestJob(var Job: Record Job)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesInvoiceJobTaskOnAfterLinesCreated(var SalesHeader: Record "Sales Header"; var Job: Record Job)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesInvoiceJobTaskOnBeforeCreateSalesLine(var JobPlanningLine: Record "Job Planning Line"; SalesHeader: Record "Sales Header"; SalesHeader2: Record "Sales Header"; var NoOfSalesLinesCreated: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesInvoiceJobTaskTestJob(var Job: Record Job)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteSalesLineOnBeforeJobPlanningLineModify(var JobPlanningLine: Record "Job Planning Line")
    begin
    end;
}

