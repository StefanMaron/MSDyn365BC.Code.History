codeunit 396 NoSeriesManagement
{
    Permissions = tabledata "No. Series Line" = rimd,
                  tabledata "No. Series" = r;

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
        UpdateLastUsedDate: Boolean;
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
                  NoSeries.FieldCaption("Manual Nos."), NoSeries.TableCaption(), NoSeries.Code);
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
        OnBeforeInitSeries(DefaultNoSeriesCode, OldNoSeriesCode, NewDate, NewNo, NewNoSeriesCode, NoSeries, IsHandled, NoSeriesCode);
        if IsHandled then
            exit;

        if NewNo = '' then begin
            NoSeries.Get(DefaultNoSeriesCode);
            if not NoSeries."Default Nos." then
                Error(
                  Text003,
                  NoSeries.FieldCaption("Default Nos."), NoSeries.TableCaption(), NoSeries.Code);
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
        FilterSeries();
        if NewNoSeriesCode = '' then begin
            if OldNoSeriesCode <> '' then
                NoSeries.Code := OldNoSeriesCode;
        end else
            NoSeries.Code := NewNoSeriesCode;
        OnSelectSeriesOnBeforePageRunModal(DefaultNoSeriesCode, NoSeries);
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
        FilterSeries();
        NoSeries.Code := NewNoSeriesCode;
        NoSeries.Find();
    end;

    procedure SetSeries(var NewNo: Code[20])
    var
        NoSeriesCode2: Code[20];
    begin
        NoSeriesCode2 := NoSeries.Code;
        FilterSeries();
        NoSeries.Code := NoSeriesCode2;
        NoSeries.Find();
        NewNo := GetNextNo(NoSeries.Code, 0D, true);
    end;

    procedure FilterSeries()
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
        OnBeforeGetNextNo(NoSeriesCode, SeriesDate, ModifySeries, Result, IsHandled, LastNoSeriesLine);
        if IsHandled then
            exit(Result);

        exit(DoGetNextNo(NoSeriesCode, SeriesDate, ModifySeries, false));
    end;

    [Obsolete('Use DoGetNextNo() instead', '21.0')]
    procedure GetNextNo3(NoSeriesCode: Code[20]; SeriesDate: Date; ModifySeries: Boolean; NoErrorsOrWarnings: Boolean): Code[20]
    begin
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
        CurrNoSeriesLine: Record "No. Series Line";
    begin
        OnBeforeDoGetNextNo(NoSeriesCode, SeriesDate, ModifySeries, NoErrorsOrWarnings);

        if SeriesDate = 0D then
            SeriesDate := WorkDate();

        SetNoSeriesLineFilter(CurrNoSeriesLine, NoSeriesCode, SeriesDate);
        if ModifySeries or (LastNoSeriesLine."Series Code" = '') or
        ((LastNoSeriesLine."Line No." <> CurrNoSeriesLine."Line No.") and (LastNoSeriesLine."Series Code" = NoSeriesCode))
        then begin
            NoSeries.Get(NoSeriesCode);
            SetNoSeriesLineFilter(NoSeriesLine, NoSeriesCode, SeriesDate);
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
            UpdateLastUsedDate := NoSeriesLine."Last Date Used" <> SeriesDate;
            if ModifySeries and (not NoSeriesLine."Allow Gaps in Nos." or UpdateLastUsedDate) then begin
                NoSeriesLine.LockTable();
                NoSeriesLine.Find();
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

        NoSeriesLine."Last Date Used" := SeriesDate;
        if NoSeriesLine."Allow Gaps in Nos." and (LastNoSeriesLine."Series Code" = '') then
            NoSeriesLine."Last No. Used" := NoSeriesLine.GetNextSequenceNo(ModifySeries)
        else
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

        if ModifySeries and NoSeriesLine.Open and (not NoSeriesLine."Allow Gaps in Nos." or UpdateLastUsedDate) then
            ModifyNoSeriesLine(NoSeriesLine);
        if Not ModifySeries then
            LastNoSeriesLine := NoSeriesLine;

        OnAfterGetNextNo3(NoSeriesLine, ModifySeries);

        exit(NoSeriesLine."Last No. Used");
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
        LastNoUsed: Code[20];
    begin
        IsHandled := false;
        OnBeforeModifyNoSeriesLine(NoSeriesLine, IsHandled);
        if IsHandled then
            exit;
        NoSeriesLine.Validate(Open);
        LastNoUsed := NoSeriesLine."Last No. Used";
        if NoSeriesLine."Allow Gaps in Nos." then
            NoSeriesLine."Last No. Used" := '';
        NoSeriesLine.Modify();
        NoSeriesLine."Last No. Used" := LastNoUsed;
    end;

    procedure TryGetNextNo(NoSeriesCode: Code[20]; SeriesDate: Date): Code[20]
    var
        NoSeriesMgt: Codeunit NoSeriesManagement;
    begin
        NoSeriesMgt.SetParametersBeforeRun(NoSeriesCode, SeriesDate);
        if NoSeriesMgt.Run() then
            exit(NoSeriesMgt.GetNextNoAfterRun());
    end;

    [Obsolete('Use SetParametersBeforeRun() instead', '21.0')]
    procedure GetNextNo1(NoSeriesCode: Code[20]; SeriesDate: Date)
    begin
        SetParametersBeforeRun(NoSeriesCode, SeriesDate);
    end;

    procedure SetParametersBeforeRun(NoSeriesCode: Code[20]; SeriesDate: Date)
    begin
        TryNoSeriesCode := NoSeriesCode;
        TrySeriesDate := SeriesDate;
        OnAfterSetParametersBeforeRun(TryNoSeriesCode, TrySeriesDate, WarningNoSeriesCode);
    end;


    [Obsolete('Use GetNextNoAfterRun() instead', '21.0')]
    procedure GetNextNo2(): Code[20]
    begin
        exit(GetNextNoAfterRun());
    end;

    procedure GetNextNoAfterRun(): Code[20]
    begin
        exit(TryNo);
    end;

    procedure SaveNoSeries()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSaveNoSeries(LastNoSeriesLine, IsHandled);
        if not IsHandled then
            if LastNoSeriesLine."Series Code" <> '' then begin
                if LastNoSeriesLine."Allow Gaps in Nos." then
                    if (LastNoSeriesLine."Last No. Used" <> '') and (LastNoSeriesLine."Last No. Used" > LastNoSeriesLine.GetLastNoUsed()) then begin
                        LastNoSeriesLine.TestField("Sequence Name");
                        if NumberSequence.Exists(LastNoSeriesLine."Sequence Name") then
                            NumberSequence.Delete(LastNoSeriesLine."Sequence Name");
                        LastNoSeriesLine."Starting Sequence No." := LastNoSeriesLine.ExtractNoFromCode(LastNoSeriesLine."Last No. Used");
                        LastNoSeriesLine.CreateNewSequence();
                    end;
                if not LastNoSeriesLine."Allow Gaps in Nos." or UpdateLastUsedDate then
                    ModifyNoSeriesLine(LastNoSeriesLine);
            end;
        OnAfterSaveNoSeries(LastNoSeriesLine);
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
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateNoSeriesLine(NoSeriesLine, NewNo, NewFieldName, IsHandled);
        if IsHandled then
            exit;

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
    local procedure OnAfterSetParametersBeforeRun(var TryNoSeriesCode: Code[20]; var TrySeriesDate: Date; var WarningNoSeriesCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestManual(DefaultNoSeriesCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetNextNo(var NoSeriesCode: Code[20]; var SeriesDate: Date; var ModifySeries: Boolean; var Result: Code[20]; var IsHandled: Boolean; var NoSeriesLine: Record "No. Series Line")
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

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateNoSeriesLine(var NoSeriesLine: Record "No. Series Line"; NewNo: Code[20]; NewFieldName: Text[100]; var IsHandled: Boolean)
    begin
    end;

    procedure ClearStateAndGetNextNo(NoSeriesCode: Code[20]): Code[20]
    begin
        Clear(LastNoSeriesLine);
        Clear(TryNoSeriesCode);
        Clear(NoSeries);

        exit(GetNextNo(NoSeriesCode, WorkDate(), false));
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
    local procedure OnBeforeInitSeries(DefaultNoSeriesCode: Code[20]; OldNoSeriesCode: Code[20]; NewDate: Date; var NewNo: Code[20]; var NewNoSeriesCode: Code[20]; var NoSeries: Record "No. Series"; var IsHandled: Boolean; var NoSeriesCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSelectSeries(DefaultNoSeriesCode: Code[20]; OldNoSeriesCode: Code[20]; var NewNoSeriesCode: Code[20]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSelectSeriesOnBeforePageRunModal(DefaultNoSeriesCode: Code[20]; var NoSeries: Record "No. Series")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSaveNoSeries(var NoSeriesLine: Record "No. Series Line"; var IsHandled: Boolean)
    begin
    end;
}

