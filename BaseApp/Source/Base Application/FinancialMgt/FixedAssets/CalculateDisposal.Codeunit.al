codeunit 5605 "Calculate Disposal"
{
    Permissions = TableData "FA Ledger Entry" = r,
                  TableData "Maintenance Ledger Entry" = r;

    trigger OnRun()
    begin
    end;

    var
        FA: Record "Fixed Asset";
        DeprBook: Record "Depreciation Book";
        FADeprBook: Record "FA Depreciation Book";
        DepreciationCalc: Codeunit "Depreciation Calculation";

    procedure CalcGainLoss(FANo: Code[20]; DeprBookCode: Code[10]; var EntryAmounts: array[14] of Decimal)
    var
        EntryAmounts2: array[4] of Decimal;
        GainLoss: Decimal;
        I: Integer;
        IsHandled: Boolean;
    begin
        OnBeforeCalcGainLoss(FANo, DeprBookCode, EntryAmounts);
        ClearAll();
        Clear(EntryAmounts);
        DeprBook.Get(DeprBookCode);
        FA.Get(FANo);
        DepreciationCalc.CalcEntryAmounts(FANo, DeprBookCode, 0D, 0D, EntryAmounts2);
        for I := 1 to 4 do
            EntryAmounts[I + 4] := -EntryAmounts2[I];
        with FADeprBook do begin
            Get(FANo, DeprBookCode);
            CalcFields(
              "Book Value", "Proceeds on Disposal", "Acquisition Cost", "Salvage Value", Depreciation);
            EntryAmounts[3] := -"Acquisition Cost";
            EntryAmounts[4] := -Depreciation;
            EntryAmounts[9] := -"Salvage Value";
            OnCalcGainLossOnAfterSetEntryAmounts(FANo, DeprBookCode, EntryAmounts);
            if DeprBook."Disposal Calculation Method" = DeprBook."Disposal Calculation Method"::Gross then
                EntryAmounts[10] := "Book Value";

            IsHandled := false;
            OnAfterSetEntryAmountsOnBeforeGainLoss(FANo, FADeprBook, DeprBookCode, EntryAmounts, GainLoss, IsHandled);
            if not IsHandled then
                GainLoss := "Book Value" + "Proceeds on Disposal";
        end;
        for I := 0 to 3 do
            if not DepreciationCalc.GetPartOfCalculation(1, I, DeprBookCode) then begin
                // 5..8 are disposal. 11..14 are bal. disposal
                GainLoss := GainLoss + EntryAmounts[I + 5];
                if DeprBook."Disposal Calculation Method" = DeprBook."Disposal Calculation Method"::Net then
                    EntryAmounts[I + 11] := -EntryAmounts[I + 5];
            end;
        if GainLoss <= 0 then
            EntryAmounts[1] := GainLoss
        else
            EntryAmounts[2] := GainLoss;
    end;

    procedure CalcSecondGainLoss(FANo: Code[20]; DeprBookCode: Code[10]; LastDisposalPrice: Decimal; var EntryAmounts: array[14] of Decimal)
    var
        NewGainLoss: Decimal;
    begin
        ClearAll();
        Clear(EntryAmounts);
        with FADeprBook do begin
            Get(FANo, DeprBookCode);
            CalcFields("Gain/Loss");
            NewGainLoss := LastDisposalPrice + "Gain/Loss";
            if IdenticalSign(NewGainLoss, "Gain/Loss") then begin
                if "Gain/Loss" <= 0 then
                    EntryAmounts[1] := LastDisposalPrice
                else
                    EntryAmounts[2] := LastDisposalPrice
            end else
                if "Gain/Loss" <= 0 then begin
                    EntryAmounts[1] := -"Gain/Loss";
                    EntryAmounts[2] := NewGainLoss;
                end else begin
                    EntryAmounts[2] := -"Gain/Loss";
                    EntryAmounts[1] := NewGainLoss;
                end;
        end;
    end;

    procedure CalcReverseAmounts(FANo: Code[20]; DeprBookCode: Code[10]; var EntryAmounts: array[4] of Decimal)
    var
        FAPostingTypeSetup: Record "FA Posting Type Setup";
        FADeprBook: Record "FA Depreciation Book";
        BookValueAmounts: array[4] of Decimal;
        i: Integer;
    begin
        Clear(EntryAmounts);
        FADeprBook.Get(FANo, DeprBookCode);
        DepreciationCalc.CalcEntryAmounts(FANo, DeprBookCode, 0D, 0D, BookValueAmounts);
        for i := 1 to 4 do begin
            FAPostingTypeSetup.Get(DeprBookCode, i - 1);
            if FAPostingTypeSetup."Part of Book Value" and
               FAPostingTypeSetup."Reverse before Disposal"
            then begin
                if i = 1 then begin
                    FADeprBook.CalcFields("Write-Down");
                    EntryAmounts[i] := -FADeprBook."Write-Down";
                end;
                if i = 2 then begin
                    FADeprBook.CalcFields(Appreciation);
                    EntryAmounts[i] := -FADeprBook.Appreciation;
                end;
                if i = 3 then begin
                    FADeprBook.CalcFields("Custom 1");
                    EntryAmounts[i] := -FADeprBook."Custom 1";
                end;
                if i = 4 then begin
                    FADeprBook.CalcFields("Custom 2");
                    EntryAmounts[i] := -FADeprBook."Custom 2";
                end;
                if EntryAmounts[i] + BookValueAmounts[i] <> 0 then
                    FAPostingTypeSetup.TestField("Reverse before Disposal", false);
            end;
        end;
    end;

    procedure GetDisposalType(FANo: Code[20]; DeprBookCode: Code[10]; ErrorNo: Integer; var DisposalType: Option FirstDisposal,SecondDisposal,ErrorDisposal,LastErrorDisposal; var DisposalMethod: Option " ",Net,Gross; var MaxDisposalNo: Integer; var SalesEntryNo: Integer)
    var
        FALedgEntry: Record "FA Ledger Entry";
        DeprBook: Record "Depreciation Book";
    begin
        ClearAll();
        MaxDisposalNo := 0;
        SalesEntryNo := 0;
        DisposalType := DisposalType::FirstDisposal;
        with FALedgEntry do begin
            DepreciationCalc.SetFAFilter(FALedgEntry, FANo, DeprBookCode, true);
            SetRange("FA Posting Type", "FA Posting Type"::"Proceeds on Disposal");
            if Find('-') then begin
                repeat
                    DisposalMethod := GetDisposalMethod(FALedgEntry);
                    if "Disposal Entry No." > MaxDisposalNo then begin
                        MaxDisposalNo := "Disposal Entry No.";
                        SalesEntryNo := "Entry No.";
                    end;
                until Next() = 0;
                if ErrorNo = 0 then begin
                    DeprBook.Get(DeprBookCode);
                    DeprBook.TestField("Allow Correction of Disposal");
                    DisposalType := DisposalType::SecondDisposal;
                end else
                    if MaxDisposalNo = 1 then
                        DisposalType := DisposalType::LastErrorDisposal
                    else
                        DisposalType := DisposalType::ErrorDisposal;
            end;
        end;
    end;

    local procedure GetDisposalMethod(FALedgEntry: Record "FA Ledger Entry") DisposalMethod: Option " ",Net,Gross
    begin
        DisposalMethod := FALedgEntry."Disposal Calculation Method";

        OnAfterGetDisposalMethod(DisposalMethod);
    end;

    procedure GetErrorDisposal(FANo: Code[20]; DeprBookCode: Code[10]; OnlyGainLoss: Boolean; MaxDisposalNo: Integer; var EntryAmounts: array[14] of Decimal; var EntryNumbers: array[14] of Integer)
    var
        FALedgEntry: Record "FA Ledger Entry";
        i: Integer;
    begin
        ClearAll();
        Clear(EntryNumbers);
        with FALedgEntry do begin
            DepreciationCalc.SetFAFilter(FALedgEntry, FANo, DeprBookCode, true);
            SetRange("FA Posting Type", "FA Posting Type"::"Gain/Loss");
            if Find('-') then
                repeat
                    if "Disposal Entry No." = MaxDisposalNo then begin
                        if "Result on Disposal" = "Result on Disposal"::Gain then begin
                            EntryAmounts[1] := -Amount;
                            EntryNumbers[1] := "Entry No.";
                        end;
                        if "Result on Disposal" = "Result on Disposal"::Loss then begin
                            EntryAmounts[2] := -Amount;
                            EntryNumbers[2] := "Entry No.";
                        end;
                    end;
                until Next() = 0;
            if not OnlyGainLoss then
                for i := 3 to 14 do begin
                    SetRange("FA Posting Category", SetFAPostingCategory(i));
                    SetRange("FA Posting Type", SetFAPostingType(i));
                    if Find('-') then begin
                        EntryNumbers[i] := "Entry No.";
                        EntryAmounts[i] := -Amount;
                    end;
                end;
        end;
    end;

    local procedure IdenticalSign(A: Decimal; B: Decimal): Boolean
    begin
        exit(((A <= 0) and (B <= 0)) or ((A >= 0) and (B >= 0)));
    end;

    procedure SetFAPostingType(i: Integer): Integer
    var
        FALedgEntry: Record "FA Ledger Entry";
    begin
        with FALedgEntry do begin
            case i of
                1, 2:
                    "FA Posting Type" := "FA Posting Type"::"Gain/Loss";
                3:
                    "FA Posting Type" := "FA Posting Type"::"Acquisition Cost";
                4:
                    "FA Posting Type" := "FA Posting Type"::Depreciation;
                5, 11:
                    "FA Posting Type" := "FA Posting Type"::"Write-Down";
                6, 12:
                    "FA Posting Type" := "FA Posting Type"::Appreciation;
                7, 13:
                    "FA Posting Type" := "FA Posting Type"::"Custom 1";
                8, 14:
                    "FA Posting Type" := "FA Posting Type"::"Custom 2";
                9:
                    "FA Posting Type" := "FA Posting Type"::"Salvage Value";
                10:
                    "FA Posting Type" := "FA Posting Type"::"Book Value on Disposal";
            end;
            exit("FA Posting Type".AsInteger());
        end;
    end;

    procedure SetFAPostingCategory(i: Integer): Integer
    var
        FALedgEntry: Record "FA Ledger Entry";
    begin
        with FALedgEntry do begin
            case i of
                1 .. 2:
                    "FA Posting Category" := "FA Posting Category"::" ";
                3 .. 10:
                    "FA Posting Category" := "FA Posting Category"::Disposal;
                11 .. 14:
                    "FA Posting Category" := "FA Posting Category"::"Bal. Disposal";
            end;
            exit("FA Posting Category");
        end;
    end;

    procedure SetReverseType(i: Integer): Integer
    var
        FALedgEntry: Record "FA Ledger Entry";
    begin
        with FALedgEntry do begin
            case i of
                1:
                    "FA Posting Type" := "FA Posting Type"::"Write-Down";
                2:
                    "FA Posting Type" := "FA Posting Type"::Appreciation;
                3:
                    "FA Posting Type" := "FA Posting Type"::"Custom 1";
                4:
                    "FA Posting Type" := "FA Posting Type"::"Custom 2";
            end;
            exit("FA Posting Type".AsInteger());
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcGainLossOnAfterSetEntryAmounts(FANo: Code[20]; DeprBookCode: Code[10]; var EntryAmounts: array[14] of Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetEntryAmountsOnBeforeGainLoss(
        FANo: Code[20];
        FADeprBook: Record "FA Depreciation Book";
        DeprBookCode: Code[10];
        var EntryAmounts: array[14] of Decimal;
        var GainLoss: Decimal;
        var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetDisposalMethod(var DisposalMethod: Option " ",Net,Gross)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcGainLoss(FANo: Code[20]; DeprBookCode: Code[10]; var EntryAmounts: array[14] of Decimal)
    begin
    end;
}

