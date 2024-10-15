codeunit 396 NoSeriesManagement
{
    Permissions = TableData "No. Series Line" = rimd,
                  TableData "No. Series Line Sales" = rimd,
                  TableData "No. Series Line Purchase" = rimd;

    trigger OnRun()
    begin
        TryNo := GetNextNo(TryNoSeriesCode, TrySeriesDate, false);
    end;

    var
        Text000: Label 'You may not enter numbers manually. ';
        Text001: Label 'If you want to enter numbers manually, please activate %1 in %2 %3.';
        Text003: Label 'It is not possible to assign numbers automatically. If you want the program to assign numbers automatically, please activate %1 in %2 %3.', Comment = '%1=Default Nos. setting,%2=No. Series table caption,%3=No. Series Code';
        Text004: Label 'You cannot assign new numbers from the number series %1 on %2.';
        Text005: Label 'You cannot assign new numbers from the number series %1.';
        Text006: Label 'You cannot assign new numbers from the number series %1 on a date before %2.';
        Text007: Label 'You cannot assign numbers greater than %1 from the number series %2.';
        Text009: Label 'The number format in %1 must be the same as the number format in %2.';
        Text010: Label 'The number %1 cannot be extended to more than 20 characters.';
        NoSeries: Record "No. Series";
        LastNoSeriesLine: Record "No. Series Line";
        NoSeriesCode: Code[20];
        WarningNoSeriesCode: Code[20];
        TryNoSeriesCode: Code[20];
        TrySeriesDate: Date;
        TryNo: Code[20];
        LastNoSeriesLineSales: Record "No. Series Line Sales";
        LastNoSeriesLinePurchase: Record "No. Series Line Purchase";
        Text1130000: Label 'There are unposted sales documents with a reserved %5 (%6). Please post these before continuing.\\%1: %2\%3: %4.';
        Text1130001: Label 'There are unposted purchase documents with a reserved %5 (%6). Please post these before continuing.\\%1: %2\%3: %4.';
        PostErr: Label 'You have one or more documents that must be posted before you post document no. %1 according to your company''s No. Series setup.', Comment = '%1=Document No.';
        UnincrementableStringErr: Label 'The value in the %1 field must have a number so that we can assign the next number in the series.', Comment = '%1 = New Field Name';

    procedure TestManual(DefaultNoSeriesCode: Code[20])
    begin
        if DefaultNoSeriesCode <> '' then begin
            NoSeries.Get(DefaultNoSeriesCode);
            if not NoSeries."Manual Nos." then
                Error(
                  Text000 +
                  Text001,
                  NoSeries.FieldCaption("Manual Nos."), NoSeries.TableCaption, NoSeries.Code);
        end;
        OnAfterTestManual(DefaultNoSeriesCode);
    end;

    procedure ManualNoAllowed(DefaultNoSeriesCode: Code[20]): Boolean
    begin
        NoSeries.Get(DefaultNoSeriesCode);
        exit(NoSeries."Manual Nos.");
    end;

    procedure TestManualWithDocumentNo(DefaultNoSeriesCode: Code[20]; DocumentNo: Code[20])
    begin
        if DefaultNoSeriesCode <> '' then begin
            NoSeries.Get(DefaultNoSeriesCode);
            if not NoSeries."Manual Nos." then
                Error(PostErr, DocumentNo);
        end;
    end;

    procedure InitSeries(DefaultNoSeriesCode: Code[20]; OldNoSeriesCode: Code[20]; NewDate: Date; var NewNo: Code[20]; var NewNoSeriesCode: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitSeries(DefaultNoSeriesCode, OldNoSeriesCode, NewDate, NewNo, NewNoSeriesCode, NoSeries, IsHandled);
        if IsHandled then
            exit;

        if NewNo = '' then begin
            NoSeries.Get(DefaultNoSeriesCode);
            if not NoSeries."Default Nos." then
                Error(
                  Text003,
                  NoSeries.FieldCaption("Default Nos."), NoSeries.TableCaption, NoSeries.Code);
            if OldNoSeriesCode <> '' then begin
                NoSeriesCode := DefaultNoSeriesCode;
                FilterSeries();
                NoSeries.Code := OldNoSeriesCode;
                if not NoSeries.Find() then
                    NoSeries.Get(DefaultNoSeriesCode);
            end;
            NewNo := GetNextNo(NoSeries.Code, NewDate, true);
            NewNoSeriesCode := NoSeries.Code;
        end else
            TestManual(DefaultNoSeriesCode);

        OnAfterInitSeries(NoSeries, DefaultNoSeriesCode, NewDate, NewNo);
    end;

    procedure SetDefaultSeries(var NewNoSeriesCode: Code[20]; NoSeriesCode: Code[20])
    begin
        if NoSeriesCode <> '' then begin
            NoSeries.Get(NoSeriesCode);
            if NoSeries."Default Nos." then
                NewNoSeriesCode := NoSeries.Code;
        end;
    end;

    procedure SelectSeries(DefaultNoSeriesCode: Code[20]; OldNoSeriesCode: Code[20]; var NewNoSeriesCode: Code[20]): Boolean
    var
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforeSelectSeries(DefaultNoSeriesCode, OldNoSeriesCode, NewNoSeriesCode, Result, IsHandled);
        if IsHandled then
            exit(Result);

        NoSeriesCode := DefaultNoSeriesCode;
        FilterSeries;
        if NewNoSeriesCode = '' then begin
            if OldNoSeriesCode <> '' then
                NoSeries.Code := OldNoSeriesCode;
        end else
            NoSeries.Code := NewNoSeriesCode;
        if PAGE.RunModal(0, NoSeries) = ACTION::LookupOK then begin
            NewNoSeriesCode := NoSeries.Code;
            exit(true);
        end;
    end;

    procedure LookupSeries(DefaultNoSeriesCode: Code[20]; var NewNoSeriesCode: Code[20]): Boolean
    begin
        exit(SelectSeries(DefaultNoSeriesCode, NewNoSeriesCode, NewNoSeriesCode));
    end;

    procedure TestSeries(DefaultNoSeriesCode: Code[20]; NewNoSeriesCode: Code[20])
    begin
        NoSeriesCode := DefaultNoSeriesCode;
        FilterSeries;
        NoSeries.Code := NewNoSeriesCode;
        NoSeries.Find;
    end;

    procedure SetSeries(var NewNo: Code[20])
    var
        NoSeriesCode2: Code[20];
    begin
        NoSeriesCode2 := NoSeries.Code;
        FilterSeries;
        NoSeries.Code := NoSeriesCode2;
        NoSeries.Find;
        NewNo := GetNextNo(NoSeries.Code, 0D, true);
    end;

    local procedure FilterSeries()
    var
        NoSeriesRelationship: Record "No. Series Relationship";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFilterSeries(NoSeries, NoSeriesCode, IsHandled);
        if IsHandled then
            exit;

        NoSeries.Reset();
        NoSeriesRelationship.SetRange(Code, NoSeriesCode);
        if NoSeriesRelationship.FindSet() then
            repeat
                NoSeries.Code := NoSeriesRelationship."Series Code";
                NoSeries.Mark := true;
            until NoSeriesRelationship.Next() = 0;
        if NoSeries.Get(NoSeriesCode) then
            NoSeries.Mark := true;
        NoSeries.MarkedOnly := true;
    end;

    procedure GetNextNo(NoSeriesCode: Code[20]; SeriesDate: Date; ModifySeries: Boolean) Result: Code[20]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetNextNo(NoSeriesCode, SeriesDate, ModifySeries, Result, IsHandled);
        if IsHandled then
            exit(Result);

        exit(DoGetNextNo(NoSeriesCode, SeriesDate, ModifySeries, false));
    end;

    procedure GetNextNo3(NoSeriesCode: Code[20]; SeriesDate: Date; ModifySeries: Boolean; NoErrorsOrWarnings: Boolean): Code[20]
    begin
        // This function is deprecated. Use the function in the line below instead:
        exit(DoGetNextNo(NoSeriesCode, SeriesDate, ModifySeries, NoErrorsOrWarnings));
    end;

    /// <summary>
    /// Gets the next number in a number series.
    /// If ModifySeries is set to true, the number series is incremented when getting the next number.
    /// NOTE: If you set ModifySeries to false you should manually increment the number series to ensure consistency.
    /// </summary>
    /// <param name="NoSeriesCode">The identifier of the number series.</param>
    /// <param name="SeriesDate">The date of the number series. The default date is WorkDate.</param>
    /// <param name="ModifySeries">
    /// Set to true to increment the number series when getting the next number.
    /// Set to false if you want to manually increment the number series.
    /// </param>
    /// <param name="NoErrorsOrWarnings">Set to true to disable errors and warnings.</param>
    /// <returns>The next number in the number series.</returns>
    procedure DoGetNextNo(NoSeriesCode: Code[20]; SeriesDate: Date; ModifySeries: Boolean; NoErrorsOrWarnings: Boolean): Code[20]
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        OnBeforeDoGetNextNo(NoSeriesCode, SeriesDate, ModifySeries, NoErrorsOrWarnings);

        if SeriesDate = 0D then
            SeriesDate := WorkDate;
        NoSeries.Get(NoSeriesCode);
        case NoSeries."No. Series Type" of
            NoSeries."No. Series Type"::Normal:
                begin
                    if ModifySeries or (LastNoSeriesLine."Series Code" = '') then begin
                        SetNoSeriesLineFilter(NoSeriesLine, NoSeriesCode, SeriesDate);
                        if ModifySeries and not NoSeriesLine."Allow Gaps in Nos." then
                            NoSeriesLine.LockTable();
                        if not NoSeriesLine.FindFirst() then begin
                            if NoErrorsOrWarnings then
                                exit('');
                            NoSeriesLine.SetRange("Starting Date");
                            if not NoSeriesLine.IsEmpty() then
                                Error(
                                  Text004,
                                  NoSeriesCode, SeriesDate);
                            Error(
                              Text005,
                              NoSeriesCode);
                        end;
                    end else
                        NoSeriesLine := LastNoSeriesLine;

                    if NoSeries."Date Order" and (SeriesDate < NoSeriesLine."Last Date Used") then begin
                        if NoErrorsOrWarnings then
                            exit('');
                        Error(
                          Text006,
                          NoSeries.Code, NoSeriesLine."Last Date Used");
                    end;
                    if NoSeriesLine."Allow Gaps in Nos." and (LastNoSeriesLine."Series Code" = '') then
                        NoSeriesLine."Last No. Used" := NoSeriesLine.GetNextSequenceNo(ModifySeries)
                    else begin
                        NoSeriesLine."Last Date Used" := SeriesDate;
                        if NoSeriesLine."Last No. Used" = '' then begin
                            if NoErrorsOrWarnings and (NoSeriesLine."Starting No." = '') then
                                exit('');
                            NoSeriesLine.TestField("Starting No.");
                            NoSeriesLine."Last No. Used" := NoSeriesLine."Starting No.";
                        end else
                            if NoSeriesLine."Increment-by No." <= 1 then
                                NoSeriesLine."Last No. Used" := IncStr(NoSeriesLine."Last No. Used")
                            else
                                IncrementNoText(NoSeriesLine."Last No. Used", NoSeriesLine."Increment-by No.");
                    end;
                    if (NoSeriesLine."Ending No." <> '') and
                       (NoSeriesLine."Last No. Used" > NoSeriesLine."Ending No.")
                    then begin
                        if NoErrorsOrWarnings then
                            exit('');
                        Error(
                          Text007,
                          NoSeriesLine."Ending No.", NoSeriesCode);
                    end;
                    if (NoSeriesLine."Ending No." <> '') and
                       (NoSeriesLine."Warning No." <> '') and
                       (NoSeriesLine."Last No. Used" >= NoSeriesLine."Warning No.") and
                       (NoSeriesCode <> WarningNoSeriesCode) and
                       (TryNoSeriesCode = '')
                    then begin
                        if NoErrorsOrWarnings then
                            exit('');
                        WarningNoSeriesCode := NoSeriesCode;
                        Message(
                          Text007,
                          NoSeriesLine."Ending No.", NoSeriesCode);
                    end;


        if ModifySeries and NoSeriesLine.Open and not NoSeriesLine."Allow Gaps in Nos." then
            ModifyNoSeriesLine(NoSeriesLine);
        if Not ModifySeries then
            LastNoSeriesLine := NoSeriesLine;

                    OnAfterGetNextNo3(NoSeriesLine, ModifySeries);
                    exit(NoSeriesLine."Last No. Used");
                end;
            NoSeries."No. Series Type"::Sales:
                exit(DoGetNextNoSales(NoSeriesCode, SeriesDate, ModifySeries, NoErrorsOrWarnings));
            NoSeries."No. Series Type"::Purchase:
                exit(DoGetNextNoPurchases(NoSeriesCode, SeriesDate, ModifySeries, NoErrorsOrWarnings));
        end;
    end;

    local procedure DoGetNextNoSales(NoSeriesCode: Code[20]; SeriesDate: Date; ModifySeries: Boolean; NoErrorsOrWarnings: Boolean): Code[20]
    var
        NoSeriesLineSales: Record "No. Series Line Sales";
    begin
        if ModifySeries or (LastNoSeriesLineSales."Series Code" = '') then begin
            if ModifySeries then
                NoSeriesLineSales.LockTable();
            NoSeries.Get(NoSeriesCode);
            SetNoSeriesLineSalesFilter(NoSeriesLineSales, NoSeriesCode, SeriesDate);
            if not NoSeriesLineSales.Find('-') then begin
                if NoErrorsOrWarnings then
                    exit('');
                NoSeriesLineSales.SetRange("Starting Date");
                if NoSeriesLineSales.Find('-') then
                    Error(
                      Text004,
                      NoSeriesCode, SeriesDate);
                Error(
                  Text005,
                  NoSeriesCode);
            end;
        end else
            NoSeriesLineSales := LastNoSeriesLineSales;

        if NoSeries."Date Order" and (SeriesDate < NoSeriesLineSales."Last Date Used") then begin
            if NoErrorsOrWarnings then
                exit('');
            Error(
              Text006,
              NoSeries.Code, NoSeriesLineSales."Last Date Used");
        end;
        NoSeriesLineSales."Last Date Used" := SeriesDate;
        if NoSeriesLineSales."Last No. Used" = '' then begin
            if NoErrorsOrWarnings and (NoSeriesLineSales."Starting No." = '') then
                exit('');
            NoSeriesLineSales.TestField("Starting No.");
            NoSeriesLineSales."Last No. Used" := NoSeriesLineSales."Starting No.";
        end else
            if NoSeriesLineSales."Increment-by No." <= 1 then
                NoSeriesLineSales."Last No. Used" := IncStr(NoSeriesLineSales."Last No. Used")
            else
                IncrementNoText(NoSeriesLineSales."Last No. Used", NoSeriesLineSales."Increment-by No.");

        if (NoSeriesLineSales."Ending No." <> '') and
           (NoSeriesLineSales."Last No. Used" > NoSeriesLineSales."Ending No.")
        then begin
            if NoErrorsOrWarnings then
                exit('');
            Error(
              Text007,
              NoSeriesLineSales."Ending No.", NoSeriesCode);
        end;

        if (NoSeriesLineSales."Ending No." <> '') and
           (NoSeriesLineSales."Warning No." <> '') and
           (NoSeriesLineSales."Last No. Used" >= NoSeriesLineSales."Warning No.") and
           (NoSeriesCode <> WarningNoSeriesCode) and
           (TryNoSeriesCode = '')
        then begin
            if NoErrorsOrWarnings then
                exit('');
            WarningNoSeriesCode := NoSeriesCode;
            Message(
              Text007,
              NoSeriesLineSales."Ending No.", NoSeriesCode);
        end;
        NoSeriesLineSales.Validate(Open);

        if ModifySeries then
            NoSeriesLineSales.Modify
        else
            LastNoSeriesLineSales := NoSeriesLineSales;
        exit(NoSeriesLineSales."Last No. Used");
    end;

    local procedure DoGetNextNoPurchases(NoSeriesCode: Code[20]; SeriesDate: Date; ModifySeries: Boolean; NoErrorsOrWarnings: Boolean): Code[20]
    var
        NoSeriesLinePurchase: Record "No. Series Line Purchase";
    begin
        if ModifySeries or (LastNoSeriesLinePurchase."Series Code" = '') then begin
            if ModifySeries then
                NoSeriesLinePurchase.LockTable();
            NoSeries.Get(NoSeriesCode);
            SetNoSeriesLinePurchaseFilter(NoSeriesLinePurchase, NoSeriesCode, SeriesDate);
            if not NoSeriesLinePurchase.Find('-') then begin
                if NoErrorsOrWarnings then
                    exit('');
                NoSeriesLinePurchase.SetRange("Starting Date");
                if NoSeriesLinePurchase.Find('-') then
                    Error(
                      Text004,
                      NoSeriesCode, SeriesDate);
                Error(
                  Text005,
                  NoSeriesCode);
            end;
        end else
            NoSeriesLinePurchase := LastNoSeriesLinePurchase;

        if NoSeries."Date Order" and (SeriesDate < NoSeriesLinePurchase."Last Date Used") then begin
            if NoErrorsOrWarnings then
                exit('');
            Error(
              Text006,
              NoSeries.Code, NoSeriesLinePurchase."Last Date Used");
        end;
        NoSeriesLinePurchase."Last Date Used" := SeriesDate;
        if NoSeriesLinePurchase."Last No. Used" = '' then begin
            NoSeriesLinePurchase.TestField("Starting No.");
            NoSeriesLinePurchase."Last No. Used" := NoSeriesLinePurchase."Starting No.";
        end else
            if NoSeriesLinePurchase."Increment-by No." <= 1 then
                NoSeriesLinePurchase."Last No. Used" := IncStr(NoSeriesLinePurchase."Last No. Used")
            else
                IncrementNoText(NoSeriesLinePurchase."Last No. Used", NoSeriesLinePurchase."Increment-by No.");
        if (NoSeriesLinePurchase."Ending No." <> '') and
           (NoSeriesLinePurchase."Last No. Used" > NoSeriesLinePurchase."Ending No.")
        then begin
            if NoErrorsOrWarnings then
                exit('');
            Error(
              Text007,
              NoSeriesLinePurchase."Ending No.", NoSeriesCode);
        end;
        if (NoSeriesLinePurchase."Ending No." <> '') and
           (NoSeriesLinePurchase."Warning No." <> '') and
           (NoSeriesLinePurchase."Last No. Used" >= NoSeriesLinePurchase."Warning No.") and
           (NoSeriesCode <> WarningNoSeriesCode) and
           (TryNoSeriesCode = '')
        then begin
            if NoErrorsOrWarnings then
                exit('');
            WarningNoSeriesCode := NoSeriesCode;
            Message(
              Text007,
              NoSeriesLinePurchase."Ending No.", NoSeriesCode);
        end;
        NoSeriesLinePurchase.Validate(Open);

        if ModifySeries then
            NoSeriesLinePurchase.Modify
        else
            LastNoSeriesLinePurchase := NoSeriesLinePurchase;
        exit(NoSeriesLinePurchase."Last No. Used");
    end;

    procedure FindNoSeriesLine(var NoSeriesLineResult: Record "No. Series Line"; NoSeriesCode: Code[20]; SeriesDate: Date): Boolean
    begin
        SetNoSeriesLineFilter(NoSeriesLineResult, NoSeriesCode, SeriesDate);
        exit(NoSeriesLineResult.FindFirst());
    end;

    procedure IsCurrentNoSeriesLine(NoSeriesLineIn: Record "No. Series Line"): Boolean
    begin
        exit((NoSeriesLineIn."Series Code" = LastNoSeriesLine."Series Code") and (NoSeriesLineIn."Line No." = LastNoSeriesLine."Line No."));
    end;

    local procedure ModifyNoSeriesLine(var NoSeriesLine: Record "No. Series Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeModifyNoSeriesLine(NoSeriesLine, IsHandled);
        if IsHandled then
            exit;
        NoSeriesLine.Validate(Open);
        NoSeriesLine.Modify;
    end;

    procedure TryGetNextNo(NoSeriesCode: Code[20]; SeriesDate: Date): Code[20]
    var
        NoSeriesMgt: Codeunit NoSeriesManagement;
    begin
        NoSeriesMgt.SetParametersBeforeRun(NoSeriesCode, SeriesDate);
        if NoSeriesMgt.Run then
            exit(NoSeriesMgt.GetNextNoAfterRun);
    end;

    procedure GetNextNo1(NoSeriesCode: Code[20]; SeriesDate: Date)
    begin
        // This function is deprecated. Use the function in the line below instead:
        SetParametersBeforeRun(NoSeriesCode, SeriesDate);
    end;

    procedure SetParametersBeforeRun(NoSeriesCode: Code[20]; SeriesDate: Date)
    begin
        TryNoSeriesCode := NoSeriesCode;
        TrySeriesDate := SeriesDate;
        OnAfterSetParametersBeforeRun(TryNoSeriesCode, TrySeriesDate, WarningNoSeriesCode);
    end;

    procedure GetNextNo2(): Code[20]
    begin
        // This function is deprecated. Use the function in the line below instead:
        exit(GetNextNoAfterRun);
    end;

    procedure GetNextNoAfterRun(): Code[20]
    begin
        exit(TryNo);
    end;

    procedure SaveNoSeries()
    begin
        case NoSeries."No. Series Type" of
            NoSeries."No. Series Type"::Normal:
                begin
                    if LastNoSeriesLine."Allow Gaps in Nos." then begin
                        if (LastNoSeriesLine."Last No. Used" <> '') and (LastNoSeriesLine."Last No. Used" > LastNoSeriesLine.GetLastNoUsed()) then begin
                            LastNoSeriesLine.testfield("Sequence Name");
                            if NumberSequence.Exists(LastNoSeriesLine."Sequence Name") then
                                NumberSequence.Delete(LastNoSeriesLine."Sequence Name");
                            NumberSequence.Insert(LastNoSeriesLine."Sequence Name", LastNoSeriesLine.ExtractNoFromCode(LastNoSeriesLine."Last No. Used"), LastNoSeriesLine."Increment-by No.");
                            if NumberSequence.Next(LastNoSeriesLine."Sequence Name") > 0 then;
                        end;
                    end else
                        if LastNoSeriesLine."Series Code" <> '' then
                            LastNoSeriesLine.Modify();
                    OnAfterSaveNoSeries(LastNoSeriesLine);
                end;
            NoSeries."No. Series Type"::Sales:
                if LastNoSeriesLineSales."Series Code" <> '' then begin
                    LastNoSeriesLineSales.Modify();
                    OnAfterSaveNoSeriesSales(LastNoSeriesLineSales);
                end;
            NoSeries."No. Series Type"::Purchase:
                if LastNoSeriesLinePurchase."Series Code" <> '' then begin
                    LastNoSeriesLinePurchase.Modify();
                    OnAfterSaveNoSeriesPurchase(LastNoSeriesLinePurchase);
                end;
        end;
    end;

    procedure ClearNoSeriesLine()
    begin
        Clear(LastNoSeriesLine);
    end;

    procedure SetNoSeriesLineFilter(var NoSeriesLine: Record "No. Series Line"; NoSeriesCode: Code[20]; StartDate: Date)
    begin
        if StartDate = 0D then
            StartDate := WorkDate();

        NoSeriesLine.Reset();
        NoSeriesLine.SetCurrentKey("Series Code", "Starting Date");
        NoSeriesLine.SetRange("Series Code", NoSeriesCode);
        NoSeriesLine.SetRange("Starting Date", 0D, StartDate);
        OnNoSeriesLineFilterOnBeforeFindLast(NoSeriesLine);
        if NoSeriesLine.FindLast() then begin
            NoSeriesLine.SetRange("Starting Date", NoSeriesLine."Starting Date");
            NoSeriesLine.SetRange(Open, true);
        end;
    end;

    procedure IncrementNoText(var No: Code[20]; IncrementByNo: Decimal)
    var
        BigIntNo: BigInteger;
        BigIntIncByNo: BigInteger;
        StartPos: Integer;
        EndPos: Integer;
        NewNo: Text[30];
    begin
        GetIntegerPos(No, StartPos, EndPos);
        Evaluate(BigIntNo, CopyStr(No, StartPos, EndPos - StartPos + 1));
        BigIntIncByNo := IncrementByNo;
        NewNo := Format(BigIntNo + BigIntIncByNo, 0, 1);
        ReplaceNoText(No, NewNo, 0, StartPos, EndPos);
    end;

    procedure UpdateNoSeriesLine(var NoSeriesLine: Record "No. Series Line"; NewNo: Code[20]; NewFieldName: Text[100])
    var
        NoSeriesLine2: Record "No. Series Line";
        Length: Integer;
    begin
        if NewNo <> '' then begin
            if IncStr(NewNo) = '' then
                Error(StrSubstNo(UnincrementableStringErr, NewFieldName));
            NoSeriesLine2 := NoSeriesLine;
            if NewNo = GetNoText(NewNo) then
                Length := 0
            else begin
                Length := StrLen(GetNoText(NewNo));
                UpdateLength(NoSeriesLine."Starting No.", Length);
                UpdateLength(NoSeriesLine."Ending No.", Length);
                UpdateLength(NoSeriesLine."Last No. Used", Length);
                UpdateLength(NoSeriesLine."Warning No.", Length);
            end;
            UpdateNo(NoSeriesLine."Starting No.", NewNo, Length);
            UpdateNo(NoSeriesLine."Ending No.", NewNo, Length);
            UpdateNo(NoSeriesLine."Last No. Used", NewNo, Length);
            UpdateNo(NoSeriesLine."Warning No.", NewNo, Length);
            if (NewFieldName <> NoSeriesLine.FieldCaption("Last No. Used")) and
               (NoSeriesLine."Last No. Used" <> NoSeriesLine2."Last No. Used")
            then
                Error(
                  Text009,
                  NewFieldName, NoSeriesLine.FieldCaption("Last No. Used"));
        end;
    end;

    local procedure UpdateLength(No: Code[20]; var MaxLength: Integer)
    var
        Length: Integer;
    begin
        if No <> '' then begin
            Length := StrLen(DelChr(GetNoText(No), '<', '0'));
            if Length > MaxLength then
                MaxLength := Length;
        end;
    end;

    local procedure UpdateNo(var No: Code[20]; NewNo: Code[20]; Length: Integer)
    var
        StartPos: Integer;
        EndPos: Integer;
        TempNo: Code[20];
    begin
        if No <> '' then
            if Length <> 0 then begin
                No := DelChr(GetNoText(No), '<', '0');
                TempNo := No;
                No := NewNo;
                NewNo := TempNo;
                GetIntegerPos(No, StartPos, EndPos);
                ReplaceNoText(No, NewNo, Length, StartPos, EndPos);
            end;
    end;

    local procedure ReplaceNoText(var No: Code[20]; NewNo: Code[20]; FixedLength: Integer; StartPos: Integer; EndPos: Integer)
    var
        StartNo: Code[20];
        EndNo: Code[20];
        ZeroNo: Code[20];
        NewLength: Integer;
        OldLength: Integer;
    begin
        if StartPos > 1 then
            StartNo := CopyStr(No, 1, StartPos - 1);
        if EndPos < StrLen(No) then
            EndNo := CopyStr(No, EndPos + 1);
        NewLength := StrLen(NewNo);
        OldLength := EndPos - StartPos + 1;
        if FixedLength > OldLength then
            OldLength := FixedLength;
        if OldLength > NewLength then
            ZeroNo := PadStr('', OldLength - NewLength, '0');
        if StrLen(StartNo) + StrLen(ZeroNo) + StrLen(NewNo) + StrLen(EndNo) > 20 then
            Error(
              Text010,
              No);
        No := StartNo + ZeroNo + NewNo + EndNo;
    end;

    local procedure GetNoText(No: Code[20]): Code[20]
    var
        StartPos: Integer;
        EndPos: Integer;
    begin
        GetIntegerPos(No, StartPos, EndPos);
        if StartPos <> 0 then
            exit(CopyStr(No, StartPos, EndPos - StartPos + 1));
    end;

    local procedure GetIntegerPos(No: Code[20]; var StartPos: Integer; var EndPos: Integer)
    var
        IsDigit: Boolean;
        i: Integer;
    begin
        StartPos := 0;
        EndPos := 0;
        if No <> '' then begin
            i := StrLen(No);
            repeat
                IsDigit := No[i] in ['0' .. '9'];
                if IsDigit then begin
                    if EndPos = 0 then
                        EndPos := i;
                    StartPos := i;
                end;
                i := i - 1;
            until (i = 0) or (StartPos <> 0) and not IsDigit;
        end;
    end;

    [Scope('OnPrem')]
    procedure SetNoSeriesLineSalesFilter(var NoSeriesLineSales: Record "No. Series Line Sales"; NoSeriesCode: Code[20]; StartDate: Date)
    begin
        if StartDate = 0D then
            StartDate := WorkDate;
        NoSeriesLineSales.Reset();
        NoSeriesLineSales.SetCurrentKey("Series Code", "Starting Date");
        NoSeriesLineSales.SetRange("Series Code", NoSeriesCode);
        NoSeriesLineSales.SetRange("Starting Date", 0D, StartDate);
        if NoSeriesLineSales.Find('+') then begin
            NoSeriesLineSales.SetRange("Starting Date", NoSeriesLineSales."Starting Date");
            NoSeriesLineSales.SetRange(Open, true);
        end;
    end;

    [Scope('OnPrem')]
    procedure SetNoSeriesLinePurchaseFilter(var NoSeriesLinePurchase: Record "No. Series Line Purchase"; NoSeriesCode: Code[20]; StartDate: Date)
    begin
        if StartDate = 0D then
            StartDate := WorkDate;
        NoSeriesLinePurchase.Reset();
        NoSeriesLinePurchase.SetCurrentKey("Series Code", "Starting Date");
        NoSeriesLinePurchase.SetRange("Series Code", NoSeriesCode);
        NoSeriesLinePurchase.SetRange("Starting Date", 0D, StartDate);
        if NoSeriesLinePurchase.Find('+') then begin
            NoSeriesLinePurchase.SetRange("Starting Date", NoSeriesLinePurchase."Starting Date");
            NoSeriesLinePurchase.SetRange(Open, true);
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateNoSeriesLineSales(var NoSeriesLineSales: Record "No. Series Line Sales"; NewNo: Code[20]; NewFieldName: Text[30])
    var
        NoSeriesLineSales2: Record "No. Series Line Sales";
        Length: Integer;
    begin
        if NewNo <> '' then begin
            if IncStr(NewNo) = '' then
                Error(StrSubstNo(UnincrementableStringErr, NewFieldName));
            NoSeriesLineSales2 := NoSeriesLineSales;
            if NewNo = GetNoText(NewNo) then
                Length := 0
            else begin
                Length := StrLen(GetNoText(NewNo));
                UpdateLength(NoSeriesLineSales."Starting No.", Length);
                UpdateLength(NoSeriesLineSales."Ending No.", Length);
                UpdateLength(NoSeriesLineSales."Last No. Used", Length);
                UpdateLength(NoSeriesLineSales."Warning No.", Length);
            end;
            UpdateNo(NoSeriesLineSales."Starting No.", NewNo, Length);
            UpdateNo(NoSeriesLineSales."Ending No.", NewNo, Length);
            UpdateNo(NoSeriesLineSales."Last No. Used", NewNo, Length);
            UpdateNo(NoSeriesLineSales."Warning No.", NewNo, Length);
            if (NewFieldName <> NoSeriesLineSales.FieldCaption("Last No. Used")) and
               (NoSeriesLineSales."Last No. Used" <> NoSeriesLineSales2."Last No. Used")
            then
                Error(
                  Text009,
                  NewFieldName, NoSeriesLineSales.FieldCaption("Last No. Used"));
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateNoSeriesLinePurchase(var NoSeriesLinePurchase: Record "No. Series Line Purchase"; NewNo: Code[20]; NewFieldName: Text[30])
    var
        NoSeriesLinePurchase2: Record "No. Series Line Purchase";
        Length: Integer;
    begin
        if NewNo <> '' then begin
            if IncStr(NewNo) = '' then
                Error(StrSubstNo(UnincrementableStringErr, NewFieldName));
            NoSeriesLinePurchase2 := NoSeriesLinePurchase;
            if NewNo = GetNoText(NewNo) then
                Length := 0
            else begin
                Length := StrLen(GetNoText(NewNo));
                UpdateLength(NoSeriesLinePurchase."Starting No.", Length);
                UpdateLength(NoSeriesLinePurchase."Ending No.", Length);
                UpdateLength(NoSeriesLinePurchase."Last No. Used", Length);
                UpdateLength(NoSeriesLinePurchase."Warning No.", Length);
            end;
            UpdateNo(NoSeriesLinePurchase."Starting No.", NewNo, Length);
            UpdateNo(NoSeriesLinePurchase."Ending No.", NewNo, Length);
            UpdateNo(NoSeriesLinePurchase."Last No. Used", NewNo, Length);
            UpdateNo(NoSeriesLinePurchase."Warning No.", NewNo, Length);
            if (NewFieldName <> NoSeriesLinePurchase.FieldCaption("Last No. Used")) and
               (NoSeriesLinePurchase."Last No. Used" <> NoSeriesLinePurchase2."Last No. Used")
            then
                Error(
                  Text009,
                  NewFieldName, NoSeriesLinePurchase.FieldCaption("Last No. Used"));
        end;
    end;

    [Scope('OnPrem')]
    procedure TestDateOrder(NoSeriesCode: Code[20])
    begin
        NoSeries.Get(NoSeriesCode);
        NoSeries.TestField("Date Order");
    end;

    procedure CheckSalesDocNoGaps(MaxDate: Date)
    var
        SalesHeader: Record "Sales Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSalesDocNoGaps(MaxDate, IsHandled);
        if IsHandled then
            exit;

        SalesHeader.SetFilter("Posting No.", '<>%1', '');
        if MaxDate <> 0D then
            SalesHeader.SetFilter("Posting Date", '<=%1', MaxDate);
        if SalesHeader.FindFirst() then
            Error(Text1130000, SalesHeader.FieldCaption("Document Type"), SalesHeader."Document Type", SalesHeader.FieldCaption("No."),
              SalesHeader."No.", SalesHeader.FieldCaption("Posting No."), SalesHeader."Posting No.");
    end;

    procedure CheckPurchDocNoGaps(MaxDate: Date)
    var
        PurchHeader: Record "Purchase Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPurchDocNoGaps(MaxDate, IsHandled);
        if IsHandled then
            exit;

        PurchHeader.SetFilter("Posting No.", '<>%1', '');
        if MaxDate <> 0D then
            PurchHeader.SetFilter("Posting Date", '<=%1', MaxDate);
        if PurchHeader.FindFirst() then
            Error(Text1130001, PurchHeader.FieldCaption("Document Type"), PurchHeader."Document Type", PurchHeader.FieldCaption("No."),
              PurchHeader."No.", PurchHeader.FieldCaption("Posting No."), PurchHeader."Posting No.");
    end;

    procedure GetNoSeriesWithCheck(NewNoSeriesCode: Code[20]; SelectNoSeriesAllowed: Boolean; CurrentNoSeriesCode: Code[20]): Code[20]
    begin
        if not SelectNoSeriesAllowed then
            exit(NewNoSeriesCode);

        NoSeries.Get(NewNoSeriesCode);
        if NoSeries."Default Nos." then
            exit(NewNoSeriesCode);

        if SeriesHasRelations(NewNoSeriesCode) then
            if SelectSeries(NewNoSeriesCode, '', CurrentNoSeriesCode) then
                exit(CurrentNoSeriesCode);
        exit(NewNoSeriesCode);
    end;

    procedure SeriesHasRelations(DefaultNoSeriesCode: Code[20]): Boolean
    var
        NoSeriesRelationship: Record "No. Series Relationship";
    begin
        NoSeriesRelationship.Reset();
        NoSeriesRelationship.SetRange(Code, DefaultNoSeriesCode);
        exit(not NoSeriesRelationship.IsEmpty);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetNextNo3(var NoSeriesLine: Record "No. Series Line"; ModifySeries: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSaveNoSeries(var NoSeriesLine: Record "No. Series Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSaveNoSeriesSales(var NoSeriesLineSales: Record "No. Series Line Sales")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetParametersBeforeRun(var TryNoSeriesCode: Code[20]; var TrySeriesDate: Date; var WarningNoSeriesCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSaveNoSeriesPurchase(var NoSeriesLinePurchase: Record "No. Series Line Purchase")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestManual(DefaultNoSeriesCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPurchDocNoGaps(MaxDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSalesDocNoGaps(MaxDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetNextNo(var NoSeriesCode: Code[20]; var SeriesDate: Date; var ModifySeries: Boolean; var Result: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDoGetNextNo(var NoSeriesCode: Code[20]; var SeriesDate: Date; var ModifySeries: Boolean; var NoErrorsOrWarnings: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyNoSeriesLine(var NoSeriesLine: Record "No. Series Line"; var IsHandled: Boolean)
    begin
    end;

    procedure ClearStateAndGetNextNo(NoSeriesCode: Code[20]): Code[20]
    begin
        Clear(LastNoSeriesLine);
        Clear(TryNoSeriesCode);
        Clear(NoSeries);

        exit(GetNextNo(NoSeriesCode, WorkDate, false));
    end;

    [EventSubscriber(ObjectType::Table, Database::"No. Series Line", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnDeleteNoSeriesLine(var Rec: Record "No. Series Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        with Rec do
            if "Sequence Name" <> '' then
                if NUMBERSEQUENCE.Exists("Sequence Name") then
                    NUMBERSEQUENCE.Delete("Sequence Name");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnNoSeriesLineFilterOnBeforeFindLast(var NoSeriesLine: Record "No. Series Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitSeries(var NoSeries: Record "No. Series"; DefaultNoSeriesCode: Code[20]; NewDate: Date; var NewNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFilterSeries(var NoSeries: Record "No. Series"; NoSeriesCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitSeries(DefaultNoSeriesCode: Code[20]; OldNoSeriesCode: Code[20]; NewDate: Date; var NewNo: Code[20]; var NewNoSeriesCode: Code[20]; var NoSeries: Record "No. Series"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSelectSeries(DefaultNoSeriesCode: Code[20]; OldNoSeriesCode: Code[20]; var NewNoSeriesCode: Code[20]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}

