codeunit 1720 "Deferral Utilities"
{

    trigger OnRun()
    begin
    end;

    var
        DeferralHeader: Record "Deferral Header";
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
        AmountRoundingPrecision: Decimal;
        InvalidPostingDateErr: Label '%1 is not within the range of posting dates for your company.', Comment = '%1=The date passed in for the posting date.';
        DeferSchedOutOfBoundsErr: Label 'The deferral schedule falls outside the accounting periods that have been set up for the company.';
        SelectDeferralCodeMsg: Label 'A deferral code must be selected for the line to view the deferral schedule.';

    procedure CreateRecurringDescription(PostingDate: Date; Description: Text[100]) FinalDescription: Text[100]
    var
        AccountingPeriod: Record "Accounting Period";
        Day: Integer;
        Week: Integer;
        Month: Integer;
        Year: Integer;
        MonthText: Text[30];
    begin
        Day := Date2DMY(PostingDate, 1);
        Week := Date2DWY(PostingDate, 2);
        Month := Date2DMY(PostingDate, 2);
        MonthText := Format(PostingDate, 0, '<Month Text>');
        Year := Date2DMY(PostingDate, 3);
        if IsAccountingPeriodExist(AccountingPeriod, PostingDate) then begin
            AccountingPeriod.SetRange("Starting Date", 0D, PostingDate);
            if not AccountingPeriod.FindLast then
                AccountingPeriod.Name := '';
        end;
        FinalDescription :=
          CopyStr(StrSubstNo(Description, Day, Week, Month, MonthText, AccountingPeriod.Name, Year), 1, MaxStrLen(Description));
    end;

    procedure CreateDeferralSchedule(DeferralCode: Code[10]; DeferralDocType: Integer; GenJnlTemplateName: Code[10]; GenJnlBatchName: Code[10]; DocumentType: Integer; DocumentNo: Code[20]; LineNo: Integer; AmountToDefer: Decimal; CalcMethod: Enum "Deferral Calculation Method"; StartDate: Date; NoOfPeriods: Integer; ApplyDeferralPercentage: Boolean; DeferralDescription: Text[100]; AdjustStartDate: Boolean; CurrencyCode: Code[10])
    var
        DeferralTemplate: Record "Deferral Template";
        DeferralHeader: Record "Deferral Header";
        DeferralLine: Record "Deferral Line";
        AdjustedStartDate: Date;
        AdjustedDeferralAmount: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateDeferralSchedule(
            DeferralCode, DeferralDocType, GenJnlTemplateName, GenJnlBatchName, DocumentType, DocumentNo, LineNo, AmountToDefer, CalcMethod,
            StartDate, NoOfPeriods, ApplyDeferralPercentage, DeferralDescription, AdjustStartDate, CurrencyCode, IsHandled);
        if IsHandled then
            exit;

        InitCurrency(CurrencyCode);
        DeferralTemplate.Get(DeferralCode);
        // "Start Date" passed in needs to be adjusted based on the Deferral Code's Start Date setting
        if AdjustStartDate then
            AdjustedStartDate := SetStartDate(DeferralTemplate, StartDate)
        else
            AdjustedStartDate := StartDate;

        AdjustedDeferralAmount := AmountToDefer;
        if ApplyDeferralPercentage then
            AdjustedDeferralAmount := Round(AdjustedDeferralAmount * (DeferralTemplate."Deferral %" / 100), AmountRoundingPrecision);

        SetDeferralRecords(
            DeferralHeader, DeferralDocType, GenJnlTemplateName, GenJnlBatchName, DocumentType, DocumentNo, LineNo,
            CalcMethod, NoOfPeriods, AdjustedDeferralAmount, AdjustedStartDate,
            DeferralCode, DeferralDescription, AmountToDefer, AdjustStartDate, CurrencyCode);

        case CalcMethod of
            CalcMethod::"Straight-Line":
                CalculateStraightline(DeferralHeader, DeferralLine, DeferralTemplate);
            CalcMethod::"Equal per Period":
                CalculateEqualPerPeriod(DeferralHeader, DeferralLine, DeferralTemplate);
            CalcMethod::"Days per Period":
                CalculateDaysPerPeriod(DeferralHeader, DeferralLine, DeferralTemplate);
            CalcMethod::"User-Defined":
                CalculateUserDefined(DeferralHeader, DeferralLine, DeferralTemplate);
        end;

        OnAfterCreateDeferralSchedule(DeferralHeader, DeferralLine, DeferralTemplate);
    end;

    procedure CalcDeferralNoOfPeriods(CalcMethod: Enum "Deferral Calculation Method"; NoOfPeriods: Integer; StartDate: Date): Integer
    var
        DeferralTemplate: Record "Deferral Template";
        AccountingPeriod: Record "Accounting Period";
    begin
        case CalcMethod of
            DeferralTemplate."Calc. Method"::"Equal per Period",
          DeferralTemplate."Calc. Method"::"User-Defined":
                exit(NoOfPeriods);
            DeferralTemplate."Calc. Method"::"Straight-Line",
            DeferralTemplate."Calc. Method"::"Days per Period":
                begin
                    if IsAccountingPeriodExist(AccountingPeriod, StartDate) then begin
                        AccountingPeriod.SetFilter("Starting Date", '>=%1', StartDate);
                        AccountingPeriod.FindFirst;
                    end;
                    if AccountingPeriod."Starting Date" = StartDate then
                        exit(NoOfPeriods);

                    exit(NoOfPeriods + 1);
                end;
        end;

        DeferralTemplate."Calc. Method" := CalcMethod;
        DeferralTemplate.FieldError("Calc. Method");
    end;

    local procedure CalculateStraightline(DeferralHeader: Record "Deferral Header"; var DeferralLine: Record "Deferral Line"; DeferralTemplate: Record "Deferral Template")
    var
        AccountingPeriod: Record "Accounting Period";
        AmountToDefer: Decimal;
        AmountToDeferFirstPeriod: Decimal;
        FractionOfPeriod: Decimal;
        PeriodicDeferralAmount: Decimal;
        RunningDeferralTotal: Decimal;
        PeriodicCount: Integer;
        HowManyDaysLeftInPeriod: Integer;
        NumberOfDaysInPeriod: Integer;
        PostDate: Date;
        FirstPeriodDate: Date;
        SecondPeriodDate: Date;
        PerDiffSum: Decimal;
    begin
        // If the Start Date passed in matches the first date of a financial period, this is essentially the same
        // as the "Equal Per Period" deferral method, so call that function.
        OnBeforeCalculateStraightline(DeferralHeader, DeferralLine, DeferralTemplate);

        if IsAccountingPeriodExist(AccountingPeriod, DeferralHeader."Start Date") then begin
            AccountingPeriod.SetFilter("Starting Date", '>=%1', DeferralHeader."Start Date");
            if not AccountingPeriod.FindFirst then
                Error(DeferSchedOutOfBoundsErr);
        end;
        if AccountingPeriod."Starting Date" = DeferralHeader."Start Date" then begin
            CalculateEqualPerPeriod(DeferralHeader, DeferralLine, DeferralTemplate);
            exit;
        end;

        PeriodicDeferralAmount := Round(DeferralHeader."Amount to Defer" / DeferralHeader."No. of Periods", AmountRoundingPrecision);

        for PeriodicCount := 1 to (DeferralHeader."No. of Periods" + 1) do begin
            InitializeDeferralHeaderAndSetPostDate(DeferralLine, DeferralHeader, PeriodicCount, PostDate);

            if (PeriodicCount = 1) or (PeriodicCount = (DeferralHeader."No. of Periods" + 1)) then begin
                if PeriodicCount = 1 then begin
                    Clear(RunningDeferralTotal);

                    // Get the starting date of the accounting period of the posting date is in
                    FirstPeriodDate := GetPeriodStartingDate(PostDate);

                    // Get the starting date of the next accounting period
                    SecondPeriodDate := GetNextPeriodStartingDate(PostDate);

                    HowManyDaysLeftInPeriod := (SecondPeriodDate - DeferralHeader."Start Date");
                    NumberOfDaysInPeriod := (SecondPeriodDate - FirstPeriodDate);
                    FractionOfPeriod := (HowManyDaysLeftInPeriod / NumberOfDaysInPeriod);

                    AmountToDeferFirstPeriod := (PeriodicDeferralAmount * FractionOfPeriod);
                    AmountToDefer := Round(AmountToDeferFirstPeriod, AmountRoundingPrecision);
                    RunningDeferralTotal := RunningDeferralTotal + AmountToDefer;
                end else
                    // Last period
                    AmountToDefer := (DeferralHeader."Amount to Defer" - RunningDeferralTotal);
            end else begin
                AmountToDefer := Round(PeriodicDeferralAmount, AmountRoundingPrecision);
                RunningDeferralTotal := RunningDeferralTotal + AmountToDefer;
            end;

            DeferralLine."Posting Date" := PostDate;
            DeferralLine.Description := CreateRecurringDescription(PostDate, DeferralTemplate."Period Description");

            if GenJnlCheckLine.DateNotAllowed(PostDate) then
                Error(InvalidPostingDateErr, PostDate);

            PerDiffSum := PerDiffSum + Round(AmountToDefer / DeferralHeader."No. of Periods", AmountRoundingPrecision);

            DeferralLine.Amount := AmountToDefer;

            DeferralLine.Insert();
        end;

        OnAfterCalculateStraightline(DeferralHeader, DeferralLine, DeferralTemplate);
    end;

    local procedure CalculateEqualPerPeriod(DeferralHeader: Record "Deferral Header"; var DeferralLine: Record "Deferral Line"; DeferralTemplate: Record "Deferral Template")
    var
        PeriodicCount: Integer;
        PostDate: Date;
        AmountToDefer: Decimal;
        RunningDeferralTotal: Decimal;
    begin
        OnBeforeCalculateEqualPerPeriod(DeferralHeader, DeferralLine, DeferralTemplate);

        for PeriodicCount := 1 to DeferralHeader."No. of Periods" do begin
            InitializeDeferralHeaderAndSetPostDate(DeferralLine, DeferralHeader, PeriodicCount, PostDate);

            DeferralLine.Validate("Posting Date", PostDate);
            DeferralLine.Description := CreateRecurringDescription(PostDate, DeferralTemplate."Period Description");

            AmountToDefer := DeferralHeader."Amount to Defer";
            if PeriodicCount = 1 then
                Clear(RunningDeferralTotal);

            if PeriodicCount <> DeferralHeader."No. of Periods" then begin
                AmountToDefer := Round(AmountToDefer / DeferralHeader."No. of Periods", AmountRoundingPrecision);
                RunningDeferralTotal := RunningDeferralTotal + AmountToDefer;
            end else
                AmountToDefer := (DeferralHeader."Amount to Defer" - RunningDeferralTotal);

            DeferralLine.Amount := AmountToDefer;
            DeferralLine.Insert();
        end;

        OnAfterCalculateEqualPerPeriod(DeferralHeader, DeferralLine, DeferralTemplate);
    end;

    local procedure CalculateDaysPerPeriod(DeferralHeader: Record "Deferral Header"; var DeferralLine: Record "Deferral Line"; DeferralTemplate: Record "Deferral Template")
    var
        AccountingPeriod: Record "Accounting Period";
        AmountToDefer: Decimal;
        PeriodicCount: Integer;
        NumberOfDaysInPeriod: Integer;
        NumberOfDaysInSchedule: Integer;
        NumberOfDaysIntoCurrentPeriod: Integer;
        NumberOfPeriods: Integer;
        PostDate: Date;
        FirstPeriodDate: Date;
        SecondPeriodDate: Date;
        EndDate: Date;
        TempDate: Date;
        NoExtraPeriod: Boolean;
        DailyDeferralAmount: Decimal;
        RunningDeferralTotal: Decimal;
    begin
        OnBeforeCalculateDaysPerPeriod(DeferralHeader, DeferralLine, DeferralTemplate);

        if IsAccountingPeriodExist(AccountingPeriod, DeferralHeader."Start Date") then begin
            AccountingPeriod.SetFilter("Starting Date", '>=%1', DeferralHeader."Start Date");
            if not AccountingPeriod.FindFirst then
                Error(DeferSchedOutOfBoundsErr);
        end;
        if AccountingPeriod."Starting Date" = DeferralHeader."Start Date" then
            NoExtraPeriod := true
        else
            NoExtraPeriod := false;

        // If comparison used <=, it messes up the calculations
        if not NoExtraPeriod then begin
            if IsAccountingPeriodExist(AccountingPeriod, DeferralHeader."Start Date") then begin
                AccountingPeriod.SetFilter("Starting Date", '<%1', DeferralHeader."Start Date");
                AccountingPeriod.FindLast;
            end;
            NumberOfDaysIntoCurrentPeriod := (DeferralHeader."Start Date" - AccountingPeriod."Starting Date");
        end else
            NumberOfDaysIntoCurrentPeriod := 0;

        if NoExtraPeriod then
            NumberOfPeriods := DeferralHeader."No. of Periods"
        else
            NumberOfPeriods := (DeferralHeader."No. of Periods" + 1);

        for PeriodicCount := 1 to NumberOfPeriods do begin
            // Figure out the end date...
            if PeriodicCount = 1 then
                TempDate := DeferralHeader."Start Date";

            if PeriodicCount <> NumberOfPeriods then
                TempDate := GetNextPeriodStartingDate(TempDate)
            else
                // Last Period, special case here...
                if NoExtraPeriod then begin
                    TempDate := GetNextPeriodStartingDate(TempDate);
                    EndDate := TempDate;
                end else
                    EndDate := (TempDate + NumberOfDaysIntoCurrentPeriod);
        end;
        NumberOfDaysInSchedule := (EndDate - DeferralHeader."Start Date");
        DailyDeferralAmount := (DeferralHeader."Amount to Defer" / NumberOfDaysInSchedule);

        for PeriodicCount := 1 to NumberOfPeriods do begin
            InitializeDeferralHeaderAndSetPostDate(DeferralLine, DeferralHeader, PeriodicCount, PostDate);

            if PeriodicCount = 1 then begin
                Clear(RunningDeferralTotal);
                FirstPeriodDate := DeferralHeader."Start Date";

                // Get the starting date of the next accounting period
                SecondPeriodDate := GetNextPeriodStartingDate(PostDate);
                NumberOfDaysInPeriod := (SecondPeriodDate - FirstPeriodDate);

                AmountToDefer := Round(NumberOfDaysInPeriod * DailyDeferralAmount, AmountRoundingPrecision);
                RunningDeferralTotal := RunningDeferralTotal + AmountToDefer;
            end else begin
                // Get the starting date of the accounting period of the posting date is in
                FirstPeriodDate := GetCurPeriodStartingDate(PostDate);

                // Get the starting date of the next accounting period
                SecondPeriodDate := GetNextPeriodStartingDate(PostDate);

                NumberOfDaysInPeriod := (SecondPeriodDate - FirstPeriodDate);

                if PeriodicCount <> NumberOfPeriods then begin
                    // Not the last period
                    AmountToDefer := Round(NumberOfDaysInPeriod * DailyDeferralAmount, AmountRoundingPrecision);
                    RunningDeferralTotal := RunningDeferralTotal + AmountToDefer;
                end else
                    AmountToDefer := (DeferralHeader."Amount to Defer" - RunningDeferralTotal);
            end;

            DeferralLine."Posting Date" := PostDate;
            DeferralLine.Description := CreateRecurringDescription(PostDate, DeferralTemplate."Period Description");

            if GenJnlCheckLine.DateNotAllowed(PostDate) then
                Error(InvalidPostingDateErr, PostDate);

            DeferralLine.Amount := AmountToDefer;

            DeferralLine.Insert();
        end;

        OnAfterCalculateDaysPerPeriod(DeferralHeader, DeferralLine, DeferralTemplate);
    end;

    local procedure CalculateUserDefined(DeferralHeader: Record "Deferral Header"; var DeferralLine: Record "Deferral Line"; DeferralTemplate: Record "Deferral Template")
    var
        PeriodicCount: Integer;
        PostDate: Date;
    begin
        OnBeforeCalculateUserDefined(DeferralHeader, DeferralLine, DeferralTemplate);

        for PeriodicCount := 1 to DeferralHeader."No. of Periods" do begin
            InitializeDeferralHeaderAndSetPostDate(DeferralLine, DeferralHeader, PeriodicCount, PostDate);

            DeferralLine."Posting Date" := PostDate;
            DeferralLine.Description := CreateRecurringDescription(PostDate, DeferralTemplate."Period Description");

            if GenJnlCheckLine.DateNotAllowed(PostDate) then
                Error(InvalidPostingDateErr, PostDate);

            // For User-Defined, user must enter in deferral amounts
            DeferralLine.Insert();
        end;

        OnAfterCalculateUserDefined(DeferralHeader, DeferralLine, DeferralTemplate);
    end;

    procedure FilterDeferralLines(var DeferralLine: Record "Deferral Line"; DeferralDocType: Option; GenJnlTemplateName: Code[10]; GenJnlBatchName: Code[10]; DocumentType: Integer; DocumentNo: Code[20]; LineNo: Integer)
    begin
        DeferralLine.SetRange("Deferral Doc. Type", DeferralDocType);
        DeferralLine.SetRange("Gen. Jnl. Template Name", GenJnlTemplateName);
        DeferralLine.SetRange("Gen. Jnl. Batch Name", GenJnlBatchName);
        DeferralLine.SetRange("Document Type", DocumentType);
        DeferralLine.SetRange("Document No.", DocumentNo);
        DeferralLine.SetRange("Line No.", LineNo);
    end;

    local procedure SetStartDate(DeferralTemplate: Record "Deferral Template"; StartDate: Date) AdjustedStartDate: Date
    var
        AccountingPeriod: Record "Accounting Period";
        DeferralStartDate: Enum "Deferral Calculation Start Date";
    begin
        // "Start Date" passed in needs to be adjusted based on the Deferral Code's Start Date setting;
        case DeferralTemplate."Start Date" of
            DeferralStartDate::"Posting Date":
                AdjustedStartDate := StartDate;
            DeferralStartDate::"Beginning of Period":
                begin
                    if AccountingPeriod.IsEmpty then
                        exit(CalcDate('<-CM>', StartDate));
                    AccountingPeriod.SetRange("Starting Date", 0D, StartDate);
                    if AccountingPeriod.FindLast then
                        AdjustedStartDate := AccountingPeriod."Starting Date";
                end;
            DeferralStartDate::"End of Period":
                begin
                    if AccountingPeriod.IsEmpty then
                        exit(CalcDate('<CM>', StartDate));
                    AccountingPeriod.SetFilter("Starting Date", '>%1', StartDate);
                    if AccountingPeriod.FindFirst then
                        AdjustedStartDate := CalcDate('<-1D>', AccountingPeriod."Starting Date");
                end;
            DeferralStartDate::"Beginning of Next Period":
                begin
                    if AccountingPeriod.IsEmpty then
                        exit(CalcDate('<CM + 1D>', StartDate));
                    AccountingPeriod.SetFilter("Starting Date", '>%1', StartDate);
                    if AccountingPeriod.FindFirst then
                        AdjustedStartDate := AccountingPeriod."Starting Date";
                end;
        end;

        OnAfterSetStartDate(DeferralTemplate, StartDate);
    end;

    procedure SetDeferralRecords(var DeferralHeader: Record "Deferral Header"; DeferralDocType: Integer; GenJnlTemplateName: Code[10]; GenJnlBatchName: Code[10]; DocumentType: Integer; DocumentNo: Code[20]; LineNo: Integer; CalcMethod: Enum "Deferral Calculation Method"; NoOfPeriods: Integer; AdjustedDeferralAmount: Decimal; AdjustedStartDate: Date; DeferralCode: Code[10]; DeferralDescription: Text[100]; AmountToDefer: Decimal; AdjustStartDate: Boolean; CurrencyCode: Code[10])
    begin
        if not DeferralHeader.Get(DeferralDocType, GenJnlTemplateName, GenJnlBatchName, DocumentType, DocumentNo, LineNo) then begin
            // Need to create the header record.
            DeferralHeader."Deferral Doc. Type" := DeferralDocType;
            DeferralHeader."Gen. Jnl. Template Name" := GenJnlTemplateName;
            DeferralHeader."Gen. Jnl. Batch Name" := GenJnlBatchName;
            DeferralHeader."Document Type" := DocumentType;
            DeferralHeader."Document No." := DocumentNo;
            DeferralHeader."Line No." := LineNo;
            DeferralHeader.Insert();
        end;
        DeferralHeader."Amount to Defer" := AdjustedDeferralAmount;
        if AdjustStartDate then
            DeferralHeader."Initial Amount to Defer" := AmountToDefer;
        DeferralHeader."Calc. Method" := CalcMethod;
        DeferralHeader."Start Date" := AdjustedStartDate;
        DeferralHeader."No. of Periods" := NoOfPeriods;
        DeferralHeader."Schedule Description" := DeferralDescription;
        DeferralHeader."Deferral Code" := DeferralCode;
        DeferralHeader."Currency Code" := CurrencyCode;
        DeferralHeader.Modify();
        // Remove old lines as they will be recalculated/recreated
        RemoveDeferralLines(DeferralDocType, GenJnlTemplateName, GenJnlBatchName, DocumentType, DocumentNo, LineNo);
    end;

    procedure RemoveOrSetDeferralSchedule(DeferralCode: Code[10]; DeferralDocType: Integer; GenJnlTemplateName: Code[10]; GenJnlBatchName: Code[10]; DocumentType: Integer; DocumentNo: Code[20]; LineNo: Integer; Amount: Decimal; PostingDate: Date; Description: Text[100]; CurrencyCode: Code[10]; AdjustStartDate: Boolean)
    var
        DeferralHeader: Record "Deferral Header";
        DeferralTemplate: Record "Deferral Template";
    begin
        if DeferralCode = '' then
            // If the user cleared the deferral code, we should remove the saved schedule...
            if DeferralHeader.Get(DeferralDocType, GenJnlTemplateName, GenJnlBatchName, DocumentType, DocumentNo, LineNo) then begin
                DeferralHeader.Delete();
                RemoveDeferralLines(DeferralDocType, GenJnlTemplateName, GenJnlBatchName, DocumentType, DocumentNo, LineNo);
            end;
        if DeferralCode <> '' then
            if LineNo <> 0 then
                if DeferralTemplate.Get(DeferralCode) then begin
                    ValidateDeferralTemplate(DeferralTemplate);

                    CreateDeferralSchedule(DeferralCode, DeferralDocType,
                      GenJnlTemplateName, GenJnlBatchName, DocumentType, DocumentNo, LineNo, Amount,
                      DeferralTemplate."Calc. Method", PostingDate, DeferralTemplate."No. of Periods",
                      true, GetDeferralDescription(GenJnlBatchName, DocumentNo, Description),
                      AdjustStartDate, CurrencyCode);
                end;
    end;

    procedure CreateScheduleFromGL(GenJournalLine: Record "Gen. Journal Line"; FirstEntryNo: Integer)
    var
        DeferralHeader: Record "Deferral Header";
        DeferralLine: Record "Deferral Line";
        DeferralTemplate: Record "Deferral Template";
        PostedDeferralHeader: Record "Posted Deferral Header";
        PostedDeferralLine: Record "Posted Deferral Line";
        CustPostingGr: Record "Customer Posting Group";
        VendPostingGr: Record "Vendor Posting Group";
        BankAcc: Record "Bank Account";
        BankAccPostingGr: Record "Bank Account Posting Group";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        DeferralAccount: Code[20];
        Account: Code[20];
        GLAccount: Code[20];
        GLAccountType: Option "G/L Account",Customer,Vendor,"Bank Account","Fixed Asset","IC Partner";
    begin
        if DeferralHeader.Get(DeferralHeader."Deferral Doc. Type"::"G/L",
             GenJournalLine."Journal Template Name",
             GenJournalLine."Journal Batch Name", 0, '',
             GenJournalLine."Line No.")
        then begin
            if DeferralTemplate.Get(DeferralHeader."Deferral Code") then
                DeferralAccount := DeferralTemplate."Deferral Account";

            if (GenJournalLine."Account No." = '') and (GenJournalLine."Bal. Account No." <> '') then begin
                GLAccount := GenJournalLine."Bal. Account No.";
                GLAccountType := GenJournalLine."Bal. Account Type";
            end else begin
                GLAccount := GenJournalLine."Account No.";
                GLAccountType := GenJournalLine."Account Type";
            end;

            // Account types not G/L are not storing a GL account in the GenJnlLine's Account field, need to retrieve
            case GLAccountType of
                GenJournalLine."Account Type"::Customer:
                    begin
                        CustPostingGr.Get(GenJournalLine."Posting Group");
                        Account := CustPostingGr.GetReceivablesAccount;
                    end;
                GenJournalLine."Account Type"::Vendor:
                    begin
                        VendPostingGr.Get(GenJournalLine."Posting Group");
                        Account := VendPostingGr.GetPayablesAccount;
                    end;
                GenJournalLine."Account Type"::"Bank Account":
                    begin
                        BankAcc.Get(GLAccount);
                        BankAccPostingGr.Get(BankAcc."Bank Acc. Posting Group");
                        Account := BankAccPostingGr."G/L Account No.";
                    end;
                else
                    Account := GLAccount;
            end;

            // Create the Posted Deferral Schedule with the Document Number created from the posted GL Trx...
            PostedDeferralHeader.Init();
            PostedDeferralHeader.TransferFields(DeferralHeader);
            PostedDeferralHeader."Deferral Doc. Type" := DeferralHeader."Deferral Doc. Type"::"G/L";
            // Adding document number so we can connect the Ledger and Deferral Schedule details...
            PostedDeferralHeader."Gen. Jnl. Document No." := GenJournalLine."Document No.";
            PostedDeferralHeader."Account No." := Account;
            PostedDeferralHeader."Document Type" := 0;
            PostedDeferralHeader."Document No." := '';
            PostedDeferralHeader."Line No." := GenJournalLine."Line No.";
            PostedDeferralHeader."Currency Code" := GenJournalLine."Currency Code";
            PostedDeferralHeader."Deferral Account" := DeferralAccount;
            PostedDeferralHeader."Posting Date" := GenJournalLine."Posting Date";
            PostedDeferralHeader."Entry No." := FirstEntryNo;
            OnBeforePostedDeferralHeaderInsert(PostedDeferralHeader, GenJournalLine);
            PostedDeferralHeader.Insert(true);
            FilterDeferralLines(
              DeferralLine, DeferralHeader."Deferral Doc. Type"::"G/L",
              GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
              0, '', GenJournalLine."Line No.");
            if DeferralLine.FindSet then begin
                repeat
                    PostedDeferralLine.Init();
                    PostedDeferralLine.TransferFields(DeferralLine);
                    PostedDeferralLine."Deferral Doc. Type" := DeferralHeader."Deferral Doc. Type"::"G/L";
                    PostedDeferralLine."Gen. Jnl. Document No." := GenJournalLine."Document No.";
                    PostedDeferralLine."Account No." := Account;
                    PostedDeferralLine."Document Type" := 0;
                    PostedDeferralLine."Document No." := '';
                    PostedDeferralLine."Line No." := GenJournalLine."Line No.";
                    PostedDeferralLine."Currency Code" := GenJournalLine."Currency Code";
                    PostedDeferralLine."Deferral Account" := DeferralAccount;
                    OnBeforePostedDeferralLineInsert(PostedDeferralLine, GenJournalLine);
                    PostedDeferralLine.Insert(true);
                until DeferralLine.Next = 0;
            end;
        end;

        OnAfterCreateScheduleFromGL(GenJournalLine, PostedDeferralHeader);

        GenJnlPostLine.RemoveDeferralSchedule(GenJournalLine);
    end;

    procedure DeferralCodeOnValidate(DeferralCode: Code[10]; DeferralDocType: Integer; GenJnlTemplateName: Code[10]; GenJnlBatchName: Code[10]; DocumentType: Integer; DocumentNo: Code[20]; LineNo: Integer; Amount: Decimal; PostingDate: Date; Description: Text[100]; CurrencyCode: Code[10])
    var
        DeferralHeader: Record "Deferral Header";
        DeferralLine: Record "Deferral Line";
        DeferralTemplate: Record "Deferral Template";
    begin
        DeferralHeader.Init();
        DeferralLine.Init();
        if DeferralCode = '' then
            // If the user cleared the deferral code, we should remove the saved schedule...
            DeferralCodeOnDelete(DeferralDocType, GenJnlTemplateName, GenJnlBatchName, DocumentType, DocumentNo, LineNo)
        else
            if LineNo <> 0 then
                if DeferralTemplate.Get(DeferralCode) then begin
                    ValidateDeferralTemplate(DeferralTemplate);

                    CreateDeferralSchedule(DeferralCode, DeferralDocType,
                      GenJnlTemplateName, GenJnlBatchName, DocumentType, DocumentNo, LineNo, Amount,
                      DeferralTemplate."Calc. Method", PostingDate, DeferralTemplate."No. of Periods",
                      true, GetDeferralDescription(GenJnlBatchName, DocumentNo, Description), true, CurrencyCode);
                end;
    end;

    procedure DeferralCodeOnDelete(DeferralDocType: Integer; GenJnlTemplateName: Code[10]; GenJnlBatchName: Code[10]; DocumentType: Integer; DocumentNo: Code[20]; LineNo: Integer)
    var
        DeferralHeader: Record "Deferral Header";
    begin
        if LineNo <> 0 then
            // Deferral Additions
            if DeferralHeader.Get(DeferralDocType, GenJnlTemplateName, GenJnlBatchName, DocumentType, DocumentNo, LineNo) then begin
                DeferralHeader.Delete();
                RemoveDeferralLines(DeferralDocType, GenJnlTemplateName, GenJnlBatchName, DocumentType, DocumentNo, LineNo);
            end;
    end;

    procedure OpenLineScheduleEdit(DeferralCode: Code[10]; DeferralDocType: Integer; GenJnlTemplateName: Code[10]; GenJnlBatchName: Code[10]; DocumentType: Integer; DocumentNo: Code[20]; LineNo: Integer; Amount: Decimal; PostingDate: Date; Description: Text[100]; CurrencyCode: Code[10]): Boolean
    var
        DeferralTemplate: Record "Deferral Template";
        DeferralHeader: Record "Deferral Header";
        DeferralSchedule: Page "Deferral Schedule";
        Changed: Boolean;
    begin
        if DeferralCode = '' then
            Message(SelectDeferralCodeMsg)
        else
            if DeferralTemplate.Get(DeferralCode) then
                if DeferralHeader.Get(DeferralDocType, GenJnlTemplateName, GenJnlBatchName, DocumentType, DocumentNo, LineNo) then begin
                    DeferralSchedule.SetParameter(DeferralDocType, GenJnlTemplateName, GenJnlBatchName, DocumentType, DocumentNo, LineNo);
                    DeferralSchedule.RunModal;
                    Changed := DeferralSchedule.GetParameter;
                    Clear(DeferralSchedule);
                end else begin
                    CreateDeferralSchedule(DeferralCode, DeferralDocType,
                      GenJnlTemplateName, GenJnlBatchName, DocumentType, DocumentNo, LineNo, Amount,
                      DeferralTemplate."Calc. Method", PostingDate, DeferralTemplate."No. of Periods", true,
                      GetDeferralDescription(GenJnlBatchName, DocumentNo, Description), true, CurrencyCode);
                    Commit();
                    if DeferralHeader.Get(DeferralDocType, GenJnlTemplateName, GenJnlBatchName, DocumentType, DocumentNo, LineNo) then begin
                        DeferralSchedule.SetParameter(DeferralDocType, GenJnlTemplateName, GenJnlBatchName, DocumentType, DocumentNo, LineNo);
                        DeferralSchedule.RunModal;
                        Changed := DeferralSchedule.GetParameter;
                        Clear(DeferralSchedule);
                    end;
                end;
        exit(Changed);
    end;

    procedure OpenLineScheduleView(DeferralCode: Code[10]; DeferralDocType: Integer; GenJnlTemplateName: Code[10]; GenJnlBatchName: Code[10]; DocumentType: Integer; DocumentNo: Code[20]; LineNo: Integer)
    var
        DeferralTemplate: Record "Deferral Template";
        PostedDeferralHeader: Record "Posted Deferral Header";
    begin
        // On view nothing will happen if the record does not exist
        if DeferralCode <> '' then
            if DeferralTemplate.Get(DeferralCode) then begin
                if PostedDeferralHeader.Get(DeferralDocType, GenJnlTemplateName, GenJnlBatchName, DocumentType, DocumentNo, LineNo) then
                    PAGE.RunModal(PAGE::"Deferral Schedule View", PostedDeferralHeader);
            end;
    end;

    procedure OpenLineScheduleArchive(DeferralCode: Code[10]; DeferralDocType: Integer; DocumentType: Integer; DocumentNo: Code[20]; DocNoOccurence: Integer; VersionNo: Integer; LineNo: Integer)
    var
        DeferralHeaderArchive: Record "Deferral Header Archive";
    begin
        // On view nothing will happen if the record does not exist
        if DeferralCode <> '' then
            if DeferralHeaderArchive.Get(DeferralDocType, DocumentType, DocumentNo, DocNoOccurence, VersionNo, LineNo) then
                PAGE.RunModal(PAGE::"Deferral Schedule Archive", DeferralHeaderArchive);
    end;

    local procedure RemoveDeferralLines(DeferralDocType: Integer; GenJnlTemplateName: Code[10]; GenJnlBatchName: Code[10]; DocumentType: Integer; DocumentNo: Code[20]; LineNo: Integer)
    var
        DeferralLine: Record "Deferral Line";
    begin
        FilterDeferralLines(DeferralLine, DeferralDocType, GenJnlTemplateName, GenJnlBatchName, DocumentType, DocumentNo, LineNo);
        DeferralLine.DeleteAll();
    end;

    local procedure ValidateDeferralTemplate(DeferralTemplate: Record "Deferral Template")
    begin
        with DeferralTemplate do begin
            TestField("Deferral Account");
            TestField("Deferral %");
            TestField("No. of Periods");
        end;
    end;

    procedure RoundDeferralAmount(var DeferralHeader: Record "Deferral Header"; CurrencyCode: Code[10]; CurrencyFactor: Decimal; PostingDate: Date; var AmtToDefer: Decimal; var AmtToDeferLCY: Decimal)
    var
        DeferralLine: Record "Deferral Line";
        CurrExchRate: Record "Currency Exchange Rate";
        UseDate: Date;
        DeferralCount: Integer;
        TotalAmountLCY: Decimal;
        TotalDeferralCount: Integer;
    begin
        // Calculate the LCY amounts for posting
        if PostingDate = 0D then
            UseDate := WorkDate
        else
            UseDate := PostingDate;

        DeferralHeader."Amount to Defer (LCY)" :=
          Round(CurrExchRate.ExchangeAmtFCYToLCY(UseDate, CurrencyCode, DeferralHeader."Amount to Defer", CurrencyFactor));
        DeferralHeader.Modify();
        AmtToDefer := DeferralHeader."Amount to Defer";
        AmtToDeferLCY := DeferralHeader."Amount to Defer (LCY)";
        FilterDeferralLines(
          DeferralLine, DeferralHeader."Deferral Doc. Type",
          DeferralHeader."Gen. Jnl. Template Name", DeferralHeader."Gen. Jnl. Batch Name",
          DeferralHeader."Document Type", DeferralHeader."Document No.", DeferralHeader."Line No.");
        if DeferralLine.FindSet then begin
            TotalDeferralCount := DeferralLine.Count();
            repeat
                DeferralCount := DeferralCount + 1;
                if DeferralCount = TotalDeferralCount then begin
                    DeferralLine."Amount (LCY)" := DeferralHeader."Amount to Defer (LCY)" - TotalAmountLCY;
                    DeferralLine.Modify();
                end else begin
                    DeferralLine."Amount (LCY)" :=
                      Round(CurrExchRate.ExchangeAmtFCYToLCY(UseDate, CurrencyCode, DeferralLine.Amount, CurrencyFactor));
                    TotalAmountLCY := TotalAmountLCY + DeferralLine."Amount (LCY)";
                    DeferralLine.Modify();
                end;
            until DeferralLine.Next = 0;
        end;
    end;

    local procedure InitCurrency(CurrencyCode: Code[10])
    var
        Currency: Record Currency;
    begin
        if CurrencyCode = '' then
            Currency.InitRoundingPrecision
        else begin
            Currency.Get(CurrencyCode);
            Currency.TestField("Amount Rounding Precision");
        end;
        AmountRoundingPrecision := Currency."Amount Rounding Precision";
    end;

    procedure GetSalesDeferralDocType(): Integer
    begin
        exit(DeferralHeader."Deferral Doc. Type"::Sales)
    end;

    local procedure InitializeDeferralHeaderAndSetPostDate(var DeferralLine: Record "Deferral Line"; DeferralHeader: Record "Deferral Header"; PeriodicCount: Integer; var PostDate: Date)
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        DeferralLine.Init();
        DeferralLine."Deferral Doc. Type" := DeferralHeader."Deferral Doc. Type";
        DeferralLine."Gen. Jnl. Template Name" := DeferralHeader."Gen. Jnl. Template Name";
        DeferralLine."Gen. Jnl. Batch Name" := DeferralHeader."Gen. Jnl. Batch Name";
        DeferralLine."Document Type" := DeferralHeader."Document Type";
        DeferralLine."Document No." := DeferralHeader."Document No.";
        DeferralLine."Line No." := DeferralHeader."Line No.";
        DeferralLine."Currency Code" := DeferralHeader."Currency Code";

        if PeriodicCount = 1 then begin
            if not AccountingPeriod.IsEmpty then begin
                AccountingPeriod.SetFilter("Starting Date", '..%1', DeferralHeader."Start Date");
                if not AccountingPeriod.FindFirst then
                    Error(DeferSchedOutOfBoundsErr);
            end;
            PostDate := DeferralHeader."Start Date";
        end else begin
            if IsAccountingPeriodExist(AccountingPeriod, CalcDate('<CM>', PostDate) + 1) then begin
                AccountingPeriod.SetFilter("Starting Date", '>%1', PostDate);
                if not AccountingPeriod.FindFirst then
                    Error(DeferSchedOutOfBoundsErr);
            end;
            PostDate := AccountingPeriod."Starting Date";
        end;
    end;

    local procedure IsAccountingPeriodExist(var AccountingPeriod: Record "Accounting Period"; PostingDate: Date): Boolean
    var
        AccountingPeriodMgt: Codeunit "Accounting Period Mgt.";
    begin
        AccountingPeriod.Reset();
        if not AccountingPeriod.IsEmpty then
            exit(true);

        AccountingPeriodMgt.InitDefaultAccountingPeriod(AccountingPeriod, PostingDate);
        exit(false);
    end;

    procedure GetPurchDeferralDocType(): Integer
    begin
        exit(DeferralHeader."Deferral Doc. Type"::Purchase)
    end;

    procedure GetGLDeferralDocType(): Integer
    begin
        exit(DeferralHeader."Deferral Doc. Type"::"G/L")
    end;

    procedure GetDeferralStartDate(DeferralDocType: Integer; RecordDocumentType: Integer; RecordDocumentNo: Code[20]; RecordLineNo: Integer; DeferralCode: Code[10]; PostingDate: Date): Date
    var
        DeferralHeader: Record "Deferral Header";
        DeferralTemplate: Record "Deferral Template";
    begin
        if DeferralHeader.Get(DeferralDocType, '', '', RecordDocumentType, RecordDocumentNo, RecordLineNo) then
            exit(DeferralHeader."Start Date");

        if DeferralTemplate.Get(DeferralCode) then
            exit(SetStartDate(DeferralTemplate, PostingDate));

        exit(PostingDate);
    end;

    procedure AdjustTotalAmountForDeferrals(DeferralCode: Code[10]; var AmtToDefer: Decimal; var AmtToDeferACY: Decimal; var TotalAmount: Decimal; var TotalAmountACY: Decimal; var TotalVATBase: Decimal; var TotalVATBaseACY: Decimal)
    begin
        TotalVATBase := TotalAmount;
        TotalVATBaseACY := TotalAmountACY;
        if DeferralCode <> '' then
            if (AmtToDefer = TotalAmount) and (AmtToDeferACY = TotalAmountACY) then begin
                AmtToDefer := 0;
                AmtToDeferACY := 0;
            end else begin
                TotalAmount := TotalAmount - AmtToDefer;
                TotalAmountACY := TotalAmountACY - AmtToDeferACY;
            end;
    end;

    procedure AdjustTotalAmountForDeferralsNoBase(DeferralCode: Code[10]; var AmtToDefer: Decimal; var AmtToDeferACY: Decimal; var TotalAmount: Decimal; var TotalAmountACY: Decimal)
    begin
        if DeferralCode <> '' then
            if (AmtToDefer = TotalAmount) and (AmtToDeferACY = TotalAmountACY) then begin
                AmtToDefer := 0;
                AmtToDeferACY := 0;
            end else begin
                TotalAmount := TotalAmount - AmtToDefer;
                TotalAmountACY := TotalAmountACY - AmtToDeferACY;
            end;
    end;

    local procedure GetPeriodStartingDate(PostingDate: Date): Date
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        if AccountingPeriod.IsEmpty then
            exit(CalcDate('<-CM>', PostingDate));

        AccountingPeriod.SetFilter("Starting Date", '<%1', PostingDate);
        if AccountingPeriod.FindLast then
            exit(AccountingPeriod."Starting Date");

        Error(DeferSchedOutOfBoundsErr);
    end;

    local procedure GetNextPeriodStartingDate(PostingDate: Date): Date
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        if AccountingPeriod.IsEmpty then
            exit(CalcDate('<CM+1D>', PostingDate));

        AccountingPeriod.SetFilter("Starting Date", '>%1', PostingDate);
        if AccountingPeriod.FindFirst then
            exit(AccountingPeriod."Starting Date");

        Error(DeferSchedOutOfBoundsErr);
    end;

    local procedure GetCurPeriodStartingDate(PostingDate: Date): Date
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        if AccountingPeriod.IsEmpty then
            exit(CalcDate('<-CM>', PostingDate));

        AccountingPeriod.SetFilter("Starting Date", '<=%1', PostingDate);
        AccountingPeriod.FindLast;
        exit(AccountingPeriod."Starting Date");
    end;

    local procedure GetDeferralDescription(GenJnlBatchName: Code[10]; DocumentNo: Code[20]; Description: Text[100]): Text[100]
    begin
        if GenJnlBatchName <> '' then
            exit(CopyStr(StrSubstNo('%1-%2', GenJnlBatchName, Description), 1, 100));
        exit(CopyStr(StrSubstNo('%1-%2', DocumentNo, Description), 1, 100));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateDaysPerPeriod(DeferralHeader: Record "Deferral Header"; var DeferralLine: Record "Deferral Line"; DeferralTemplate: Record "Deferral Template")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateEqualPerPeriod(DeferralHeader: Record "Deferral Header"; var DeferralLine: Record "Deferral Line"; DeferralTemplate: Record "Deferral Template")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateStraightline(DeferralHeader: Record "Deferral Header"; var DeferralLine: Record "Deferral Line"; DeferralTemplate: Record "Deferral Template")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateUserDefined(DeferralHeader: Record "Deferral Header"; var DeferralLine: Record "Deferral Line"; DeferralTemplate: Record "Deferral Template")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDeferralSchedule(DeferralHeader: Record "Deferral Header"; var DeferralLine: Record "Deferral Line"; DeferralTemplate: Record "Deferral Template")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateScheduleFromGL(var GenJournalLine: Record "Gen. Journal Line"; var PostedDeferralHeader: Record "Posted Deferral Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetStartDate(DeferralTemplate: Record "Deferral Template"; var StartDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateDaysPerPeriod(DeferralHeader: Record "Deferral Header"; var DeferralLine: Record "Deferral Line"; DeferralTemplate: Record "Deferral Template")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateEqualPerPeriod(DeferralHeader: Record "Deferral Header"; var DeferralLine: Record "Deferral Line"; DeferralTemplate: Record "Deferral Template")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateStraightline(DeferralHeader: Record "Deferral Header"; var DeferralLine: Record "Deferral Line"; DeferralTemplate: Record "Deferral Template")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateUserDefined(DeferralHeader: Record "Deferral Header"; var DeferralLine: Record "Deferral Line"; DeferralTemplate: Record "Deferral Template")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateDeferralSchedule(DeferralCode: Code[10]; DeferralDocType: Integer; GenJnlTemplateName: Code[10]; GenJnlBatchName: Code[10]; DocumentType: Integer; DocumentNo: Code[20]; LineNo: Integer; AmountToDefer: Decimal; CalcMethod: Enum "Deferral Calculation Method"; StartDate: Date; NoOfPeriods: Integer; ApplyDeferralPercentage: Boolean; DeferralDescription: Text[100]; AdjustStartDate: Boolean; CurrencyCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostedDeferralHeaderInsert(var PostedDeferralHeader: Record "Posted Deferral Header"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostedDeferralLineInsert(var PostedDeferralLine: Record "Posted Deferral Line"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;
}

