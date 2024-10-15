codeunit 5642 "FA Reclass. Transfer Line"
{

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'is a %1 and %2 is not a %1.';
        Text001: Label 'is not different than %1.';
        Text002: Label '%1 is disposed.';
        Text003: Label '%2 = 0 for %1.';
        Text004: Label '%2 is greater than %3 for %1.';
        FAJnlSetup: Record "FA Journal Setup";
        OldFA: Record "Fixed Asset";
        NewFA: Record "Fixed Asset";
        FADeprBook: Record "FA Depreciation Book";
        FADeprBook2: Record "FA Depreciation Book";
        GenJnlLine: Record "Gen. Journal Line";
        FAJnlLine: Record "FA Journal Line";
        DepreciationCalc: Codeunit "Depreciation Calculation";
        FAGetJnl: Codeunit "FA Get Journal";
        FAPostingType: Enum "FA Journal Line FA Posting Type";
        TransferToGenJnl: Boolean;
        TemplateName: Code[10];
        BatchName: Code[10];
        FANo: Code[20];
        TransferType: array[9] of Boolean;
        Amounts: array[9] of Decimal;
        FAJnlNextLineNo: Integer;
        GenJnlNextLineNo: Integer;
        i: Integer;
        j: Integer;
        OldNewFA: Integer;
        Sign: Integer;
        GenJnlUsedOnce: Boolean;
        FAJnlUsedOnce: Boolean;
        FAJnlDocumentNo: Code[20];
        GenJnlDocumentNo: Code[20];
        DeprBookCode: Code[10];
        FASetup: Record "FA Setup";
        FADeprBook3: Record "FA Depreciation Book";
        DeprBook: Record "Depreciation Book";
        TransferAmntToGenJnl: Boolean;
        GLSetup: Record "General Ledger Setup";
        Text12400: Label 'Nothing to reclassify.';
        PostToGenJnL: Boolean;
        Text005: Label 'It was not possible to find a %1 in %2.';
        Text006: Label '%1 must be %2 or %3 for %4.';
        Text007: Label '%1 must be %2 for %3.';
        Text008: Label 'must not be used together with %1 in %2 %3.';
        Text009: Label '%1 cannot be calculated for %2.';

    procedure FAReclassLine(var FAReclassJnlLine: Record "FA Reclass. Journal Line"; var Done: Boolean)
    var
        CurrFA: Record "Fixed Asset";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFAReclassLine(FAReclassJnlLine, Done, IsHandled);
        if IsHandled then
            exit;

        with FAReclassJnlLine do begin
            if ("FA No." = '') and ("New FA No." = '') then
                exit;
            OldFA.Get("FA No.");
            NewFA.Get("New FA No.");
            FADeprBook.Get("FA No.", "Depreciation Book Code");
            GetNewFADeprBook(FAReclassJnlLine);
            OldFA.TestField(Blocked, false);
            NewFA.TestField(Blocked, false);
            OldFA.TestField(Inactive, false);
            NewFA.TestField(Inactive, false);

            PostToGenJnL := ("FA No." <> "New FA No.") or ("Depreciation Book Code" <> "New Depreciation Book Code");

            if OldFA."Budgeted Asset" and not NewFA."Budgeted Asset" then
                FieldError(
                  "FA No.", StrSubstNo(Text000,
                    OldFA.FieldCaption("Budgeted Asset"), FieldCaption("New FA No.")));

            if NewFA."Budgeted Asset" and not OldFA."Budgeted Asset" then
                FieldError(
                  "New FA No.", StrSubstNo(Text000,
                    NewFA.FieldCaption("Budgeted Asset"), FieldCaption("FA No.")));

            if ("FA No." = "New FA No.") and ("Depreciation Book Code" = "New Depreciation Book Code") and
               ("FA Location Code" = OldFA."FA Location Code") and ("Employee No." = OldFA."Responsible Employee") then
                Error(Text12400);

            NewFA."FA Location Code" := "FA Location Code";
            NewFA."Responsible Employee" := "Employee No.";

            if FADeprBook."Disposal Date" > 0D then
                Error(Text002, FAName(OldFA, "Depreciation Book Code"));

            if not NewFA."Undepreciable FA" then
                if FADeprBook2."Disposal Date" > 0D then
                    Error(Text002, FAName(NewFA, "Depreciation Book Code"));

            SetFAReclassType(FAReclassJnlLine);
            CalcAmounts(FAReclassJnlLine);
            CalcDB1DeprAmount(FAReclassJnlLine);

            j := 0;
            while j < 9 do begin
                j := j + 1;
                if j = 7 then
                    j := 9;
                for OldNewFA := 0 to 1 do begin
                    Convert(OldNewFA, j, FAPostingType, Sign, CurrFA);
                    i := j;
                    FAPostingType := "FA Journal Line FA Posting Type".FromInteger(j - 1);
                    TemplateName := '';
                    BatchName := '';
                    if TransferType[i] and (Amounts[i] <> 0) then begin
                        FAGetJnl.JnlName(
                          "Depreciation Book Code", OldFA."Budgeted Asset", FAPostingType,
                          TransferToGenJnl, TemplateName, BatchName);
                        if TransferToGenJnl and (not PostToGenJnL) then
                            TransferToGenJnl := false;
                        SetJnlRange;
                        if TransferToGenJnl then
                            InsertGenJnlLine(FAReclassJnlLine, CurrFA, Sign * Amounts[i], "Insert Bal. Account")
                        else
                            InsertFAJnlLine(FAReclassJnlLine, CurrFA, Sign * Amounts[i]);
                        Done := true;
                    end;
                end;
            end;
            if NewFA."Undepreciable FA" then
                if TransferType[1] and (Amounts[1] <> 0) then begin
                    FAGetJnl.JnlName(
                      "Depreciation Book Code", OldFA."Budgeted Asset", FAPostingType::"Acquisition Cost",
                      TransferToGenJnl, TemplateName, BatchName);
                    SetJnlRange;
                    if TransferToGenJnl then begin
                        //CheckBatch;
                        InsertDisposalLine(FAReclassJnlLine, OldFA, -Amounts[1]);
                        DeprBookCode := FADeprBook3."Depreciation Book Code";
                        DeprBook.Get(DeprBookCode);
                        FAJnlSetup.FAJnlName(DeprBook, FAJnlLine, FAJnlNextLineNo);
                        FAPostingType := FAPostingType::"Acquisition Cost";
                        FAGetJnl.JnlName(
                          DeprBookCode, NewFA."Budgeted Asset", FAPostingType::"Acquisition Cost",
                          TransferAmntToGenJnl, TemplateName, BatchName);
                        if TransferAmntToGenJnl then
                            InsertGenJnlLine(FAReclassJnlLine, NewFA, Sign * Amounts[1], true)
                        else
                            InsertFAJnlLine(FAReclassJnlLine, NewFA, Amounts[1]);
                    end;
                end;
        end;
    end;

    local procedure CalcAmounts(var FAReclassJnlLine: Record "FA Reclass. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcAmounts(FAReclassJnlLine, Amounts, IsHandled);
        if IsHandled then
            exit;

        with FADeprBook do begin
            CalcFields("Acquisition Cost");
            if TransferType[2] then
                CalcFields(Depreciation);
            if TransferType[3] then
                CalcFields("Write-Down");
            if TransferType[4] then
                CalcFields(Appreciation);
            if TransferType[5] then
                CalcFields("Custom 1");
            if TransferType[6] then
                CalcFields("Custom 2");
            if TransferType[9] then
                CalcFields("Salvage Value");
            Amounts[1] := "Acquisition Cost";
            Amounts[2] := Depreciation;
            Amounts[3] := "Write-Down";
            Amounts[4] := Appreciation;
            Amounts[5] := "Custom 1";
            Amounts[6] := "Custom 2";
            Amounts[9] := "Salvage Value";
            OnCalcAmountsOnAfterSetAmounts(FADeprBook, Amounts, TransferType);
            if Amounts[1] = 0 then
                Error(Text003,
                  FAName(OldFA, "Depreciation Book Code"), FieldCaption("Acquisition Cost"));
        end;

        with FAReclassJnlLine do begin
            if "Reclassify Acq. Cost Amount" <> 0 then begin
                if "Reclassify Acq. Cost Amount" > Amounts[1] then
                    Error(Text004,
                      FAName(OldFA, "Depreciation Book Code"),
                      FieldCaption("Reclassify Acq. Cost Amount"),
                      FADeprBook.FieldCaption("Acquisition Cost"));
                "Reclassify Acq. Cost %" := "Reclassify Acq. Cost Amount" / Amounts[1] * 100;
            end;
            if "Reclassify Acq. Cost Amount" <> 0 then
                Amounts[1] := "Reclassify Acq. Cost Amount"
            else
                Amounts[1] := Round(Amounts[1] * "Reclassify Acq. Cost %" / 100);
            for i := 2 to 9 do
                Amounts[i] := Round(Amounts[i] * "Reclassify Acq. Cost %" / 100);
        end;
    end;

    local procedure SetFAReclassType(var FAReclassJnlLine: Record "FA Reclass. Journal Line")
    begin
        with FAReclassJnlLine do begin
            TransferType[1] := "Reclassify Acquisition Cost";
            TransferType[2] := "Reclassify Depreciation";
            TransferType[3] := "Reclassify Write-Down";
            TransferType[4] := "Reclassify Appreciation";
            TransferType[5] := "Reclassify Custom 1";
            TransferType[6] := "Reclassify Custom 2";
            TransferType[9] := "Reclassify Salvage Value";
        end;
    end;

    local procedure SetJnlRange()
    begin
        if (FAJnlNextLineNo = 0) and not TransferToGenJnl then begin
            FAJnlLine.LockTable();
            FAGetJnl.SetFAJnlRange(FAJnlLine, TemplateName, BatchName);
            FAJnlNextLineNo := FAJnlLine."Line No.";
        end;
        if (GenJnlNextLineNo = 0) and TransferToGenJnl then begin
            GenJnlLine.LockTable();
            FAGetJnl.SetGenJnlRange(GenJnlLine, TemplateName, BatchName);
            GenJnlNextLineNo := GenJnlLine."Line No.";
        end;
    end;

    local procedure Convert(OldNewFA: Option OldFA,NewFA; J: Integer; var FAPostingType: Enum "FA Journal Line FA Posting Type"; var Sign: Integer; var CurrFA: Record "Fixed Asset")
    begin
        if OldNewFA = OldNewFA::OldFA then begin
            Sign := -1;
            CurrFA := OldFA;
            DeprBookCode := FADeprBook."Depreciation Book Code";
        end else begin
            Sign := 1;
            CurrFA := NewFA;
            DeprBookCode := FADeprBook2."Depreciation Book Code";
        end;
        if OldNewFA = OldNewFA::OldFA then
            case J of
                1:
                    FAPostingType := FAPostingType::"Salvage Value";
                2:
                    FAPostingType := FAPostingType::Depreciation;
                3:
                    FAPostingType := FAPostingType::"Write-Down";
                4:
                    FAPostingType := FAPostingType::"Custom 1";
                5:
                    FAPostingType := FAPostingType::"Custom 2";
                6:
                    FAPostingType := FAPostingType::Appreciation;
                9:
                    FAPostingType := FAPostingType::"Acquisition Cost";
            end;
        if OldNewFA = OldNewFA::NewFA then
            case J of
                1:
                    FAPostingType := FAPostingType::"Acquisition Cost";
                2:
                    FAPostingType := FAPostingType::"Salvage Value";
                3:
                    FAPostingType := FAPostingType::Appreciation;
                4:
                    FAPostingType := FAPostingType::"Write-Down";
                5:
                    FAPostingType := FAPostingType::"Custom 1";
                6:
                    FAPostingType := FAPostingType::"Custom 2";
                9:
                    FAPostingType := FAPostingType::Depreciation;
            end;
    end;

    local procedure InsertFAJnlLine(var FAReclassJnlLine: Record "FA Reclass. Journal Line"; FA: Record "Fixed Asset"; EntryAmount: Decimal)
    begin
        if not FAJnlUsedOnce then begin
            ;
            FAJnlUsedOnce := true;
            FAJnlDocumentNo :=
              FAJnlSetup.GetFAJnlDocumentNo(FAJnlLine, FAReclassJnlLine."FA Posting Date", false);
        end;

        GLSetup.Get();
        with FAJnlLine do begin
            Init;
            "Line No." := 0;
            FAJnlSetup.SetFAJnlTrailCodes(FAJnlLine);
            "FA Posting Type" := FAPostingType;
            Validate("FA No.", FA."No.");
            "FA Posting Date" := FAReclassJnlLine."FA Posting Date";
            "Posting Date" := FAReclassJnlLine."Posting Date";
            if "Posting Date" = "FA Posting Date" then
                "Posting Date" := 0D;
            "Employee No." := FA."Responsible Employee";
            "Location Code" := FA."FA Location Code";
            if "FA Posting Type" = "FA Posting Type"::"Acquisition Cost" then
                Quantity := FAReclassJnlLine.Quantity;
            "Document No." := FAReclassJnlLine."Document No.";
            if "Document No." = '' then
                "Document No." := FAJnlDocumentNo;
            if "Document No." = '' then
                FAReclassJnlLine.TestField("Document No.");

            "Posting No. Series" := FAJnlSetup.GetFANoSeries(FAJnlLine);
            Validate("Depreciation Book Code", DeprBookCode);
            Validate(Amount, EntryAmount);
            Description := FAReclassJnlLine.Description;
            "FA Reclassification Entry" := true;
            FAJnlNextLineNo := FAJnlNextLineNo + 10000;
            "Line No." := FAJnlNextLineNo;
            OnBeforeFAJnlLineInsert(FAJnlLine, FAReclassJnlLine, Sign);
            Insert(true);
        end;
    end;

    local procedure InsertGenJnlLine(var FAReclassJnlLine: Record "FA Reclass. Journal Line"; FA: Record "Fixed Asset"; EntryAmount: Decimal; BalAccount: Boolean)
    var
        FAInsertGLAcc: Codeunit "FA Insert G/L Account";
        FADeprBook: Record "FA Depreciation Book";
    begin
        if (i = 7) and
          (DeprBookCode = FAReclassJnlLine."Depreciation Book Code") then
            exit;

        if not GenJnlUsedOnce then begin
            ;
            GenJnlUsedOnce := true;
            GenJnlDocumentNo :=
              FAJnlSetup.GetGenJnlDocumentNo(GenJnlLine, FAReclassJnlLine."FA Posting Date", false);
        end;

        GLSetup.Get();

        GenJnlLine.Init();
        GenJnlLine."Line No." := 0;
        FAJnlSetup.SetGenJnlTrailCodes(GenJnlLine);
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"Fixed Asset";
        GenJnlLine."FA Posting Type" := "Gen. Journal Line FA Posting Type".FromInteger(FAPostingType.AsInteger() + 1);
        GenJnlLine.Validate("Account No.", FA."No.");
        GenJnlLine."Object Type" := GenJnlLine."Account Type"::"Fixed Asset".AsInteger();
        GenJnlLine."Object No." := FA."No.";
        GenJnlLine.Validate("Depreciation Book Code", DeprBookCode);
        FADeprBook.Get(GenJnlLine."Account No.", GenJnlLine."Depreciation Book Code");
        GenJnlLine."Posting Group" := FADeprBook."FA Posting Group";
        GenJnlLine."FA Posting Date" := FAReclassJnlLine."FA Posting Date";
        GenJnlLine."Posting Date" := FAReclassJnlLine."Posting Date";
        if GenJnlLine."Posting Date" = 0D then
            GenJnlLine."Posting Date" := FAReclassJnlLine."FA Posting Date";
        if GenJnlLine."Posting Date" = GenJnlLine."FA Posting Date" then
            GenJnlLine."FA Posting Date" := 0D;

        GenJnlLine."Document No." := FAReclassJnlLine."Document No.";
        if GenJnlLine."Document No." = '' then
            GenJnlLine."Document No." := GenJnlDocumentNo;
        if GenJnlLine."Document No." = '' then
            FAReclassJnlLine.TestField("Document No.");

        GenJnlLine."Posting No. Series" := FAJnlSetup.GetGenNoSeries(GenJnlLine);
        GenJnlLine.Validate(Amount, EntryAmount);
        if GenJnlLine."FA Posting Type" = GenJnlLine."FA Posting Type"::"Acquisition Cost" then begin
            GenJnlLine.Quantity := FAReclassJnlLine.Quantity;
            if GenJnlLine.Quantity = 0 then
                GenJnlLine.Quantity := 1;
            GenJnlLine.Quantity := Sign * GenJnlLine.Quantity;
        end;
        GenJnlLine."Employee No." := FA."Responsible Employee";
        GenJnlLine."FA Location Code" := FA."FA Location Code";
        GenJnlLine.Description := FAReclassJnlLine.Description;
        GenJnlLine."FA Reclassification Entry" := true;
        GenJnlNextLineNo := GenJnlNextLineNo + 10000;
        GenJnlLine."Line No." := GenJnlNextLineNo;
        OnBeforeGenJnlLineInsert(GenJnlLine, FAReclassJnlLine, Sign);
        GenJnlLine.Insert(true);
        if BalAccount then begin
            FAInsertGLAcc.GetBalAcc(GenJnlLine);
            if GenJnlLine.Find('+') then;
            GenJnlNextLineNo := GenJnlLine."Line No.";
        end;
    end;

    local procedure FAName(var FA: Record "Fixed Asset"; DeprBookCode: Code[10]): Text[200]
    begin
        exit(DepreciationCalc.FAName(FA, DeprBookCode));
    end;

    local procedure CalcDB1DeprAmount(FAReclassJnlLine: Record "FA Reclass. Journal Line")
    var
        AccountingPeriod: Record "Accounting Period";
        DeprBook: Record "Depreciation Book";
        CalculateDepr: Codeunit "Calculate Depreciation";
        DeprAmount: Decimal;
        DeprAmount2: Decimal;
        Custom1Amount: Decimal;
        NumberOfDays: Integer;
        NumberOfDays2: Integer;
        Custom1NumberOfDays: Integer;
        DeprUntilDate: Date;
        DummyEntryAmounts: array[4] of Decimal;
        FixedAmount: Decimal;
        FixedAmount2: Decimal;
        DaysInFiscalYear: Integer;
    begin
        if not FAReclassJnlLine."Calc. DB1 Depr. Amount" then
            exit;
        DeprBook.Get(FAReclassJnlLine."Depreciation Book Code");
        DeprBook.TestField("Use Custom 1 Depreciation", false); // better
        if (FADeprBook."Depreciation Method" <> FADeprBook."Depreciation Method"::"DB1/SL") and
           (FADeprBook."Depreciation Method" <> FADeprBook."Depreciation Method"::"Declining-Balance 1")
        then begin
            FADeprBook."Depreciation Method" := FADeprBook."Depreciation Method"::"Declining-Balance 1";
            FADeprBook2."Depreciation Method" := FADeprBook."Depreciation Method"::"DB1/SL";
            Error(Text006,
              FADeprBook.FieldCaption("Depreciation Method"),
              FADeprBook."Depreciation Method",
              FADeprBook2."Depreciation Method",
              FAName(OldFA, FAReclassJnlLine."Depreciation Book Code"));
        end;
        if FADeprBook."Depreciation Method" <> FADeprBook2."Depreciation Method" then
            Error(Text007,
              FADeprBook.FieldCaption("Depreciation Method"),
              FADeprBook."Depreciation Method",
              FAName(NewFA, FAReclassJnlLine."Depreciation Book Code"));

        if DeprBook."Use Custom 1 Depreciation" then
            FAReclassJnlLine.FieldError("Calc. DB1 Depr. Amount",
              StrSubstNo(
                Text008,
                DeprBook.FieldCaption("Use Custom 1 Depreciation"),
                DeprBook.TableCaption,
                DeprBook.Code));

        FADeprBook.TestField("Temp. Ending Date", 0D);
        FADeprBook2.TestField("Temp. Ending Date", 0D);

        with AccountingPeriod do
            if IsEmpty() then
                DeprUntilDate := CalcDate('<-CY>', FAReclassJnlLine."FA Posting Date") - 1
            else begin
                SetRange("New Fiscal Year", true);
                SetRange("Starting Date", FAReclassJnlLine."FA Posting Date", DMY2Date(31, 12, 9999));
                if FindFirst() then begin
                    if "Starting Date" <= 00000101D then
                        Error(Text005, FieldCaption("Starting Date"), TableCaption);
                    DeprUntilDate := "Starting Date" - 1
                end else
                    Error(Text005, FieldCaption("Starting Date"), TableCaption);
            end;

        CalculateDepr.Calculate(
          DeprAmount, Custom1Amount, NumberOfDays, Custom1NumberOfDays,
          FAReclassJnlLine."FA No.", FAReclassJnlLine."Depreciation Book Code",
          DeprUntilDate, DummyEntryAmounts, 0D, 0);
        if (DeprAmount >= 0) or (NumberOfDays <= 0) then
            Error(Text009,
              FADeprBook.FieldCaption("Temp. Fixed Depr. Amount"),
              FAName(OldFA, FAReclassJnlLine."Depreciation Book Code"));
        CalculateDepr.Calculate(
          DeprAmount2, Custom1Amount, NumberOfDays2, Custom1NumberOfDays,
          FAReclassJnlLine."New FA No.", FAReclassJnlLine."Depreciation Book Code",
          DeprUntilDate, DummyEntryAmounts, 0D, 0);

        DaysInFiscalYear := DeprBook."No. of Days in Fiscal Year";
        if DaysInFiscalYear = 0 then
            DaysInFiscalYear := 360;

        if DeprBook."Fiscal Year 365 Days" then
            DaysInFiscalYear := 365;

        FixedAmount := Round(-DeprAmount / NumberOfDays * DaysInFiscalYear);
        if NumberOfDays2 > 0 then
            FixedAmount2 := Round(-DeprAmount2 / NumberOfDays2 * DaysInFiscalYear);

        FADeprBook."Temp. Fixed Depr. Amount" :=
          Round(FixedAmount * (100 - FAReclassJnlLine."Reclassify Acq. Cost %") / 100);
        FADeprBook."Temp. Ending Date" := DeprUntilDate;
        FADeprBook.Modify();

        FADeprBook2."Temp. Fixed Depr. Amount" :=
          Round(FixedAmount2 + FixedAmount - FADeprBook."Temp. Fixed Depr. Amount");
        FADeprBook2."Temp. Ending Date" := FADeprBook."Temp. Ending Date";
        FADeprBook2.Modify();
    end;

    [Scope('OnPrem')]
    procedure InsertDisposalLine(var FAReclassJnlLine: Record "FA Reclass. Journal Line"; FA: Record "Fixed Asset"; EntryAmount: Decimal)
    var
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
    begin
        if not GenJnlUsedOnce then begin
            ;
            GenJnlUsedOnce := true;
            GenJnlDocumentNo :=
              FAJnlSetup.GetGenJnlDocumentNo(GenJnlLine, FAReclassJnlLine."FA Posting Date", false);
        end;
        with GenJnlLine do begin
            Init;
            "Account Type" := "Account Type"::"Fixed Asset";
            "Account No." := FA."No.";
            "Object Type" := "Account Type"::"Fixed Asset".AsInteger();
            "Object No." := FA."No.";
            "FA Posting Type" := "FA Posting Type"::Disposal;
            "FA Posting Date" := FAReclassJnlLine."FA Posting Date";
            "Posting Date" := FAReclassJnlLine."Posting Date";
            if "Posting Date" = 0D then
                "Posting Date" := FAReclassJnlLine."FA Posting Date";
            "FA Location Code" := FA."FA Location Code";
            "Employee No." := FA."Responsible Employee";
            Quantity := -FAReclassJnlLine.Quantity;
            "Posting No. Series" := FAJnlSetup.GetGenNoSeries(GenJnlLine);
            "Document Date" := FAReclassJnlLine."Posting Date";
            "Document No." := FAReclassJnlLine."Document No.";
            if "Document No." = '' then
                "Document No." := GenJnlDocumentNo;
            if "Document No." = '' then
                FAReclassJnlLine.TestField(FAReclassJnlLine."Document No.");
            "Depreciation Book Code" := FAReclassJnlLine."New Depreciation Book Code";
            FADepreciationBook.Reset();
            FADepreciationBook.SetRange("FA No.", "Account No.");
            FADepreciationBook.SetRange("Depreciation Book Code", "Depreciation Book Code");
            if FADepreciationBook.Find('-') then begin
                FADepreciationBook.TestField("FA Posting Group");
                FAPostingGroup.Reset();
                FAPostingGroup.SetRange(Code, FADepreciationBook."FA Posting Group");
                if FAPostingGroup.Find('-') then begin
                    "Posting Group" := FAPostingGroup.Code;
                    FAPostingGroup.TestField("Disposal Expense Account");
                end;
            end;
            "Gen. Prod. Posting Group" := '';
            Description := FAReclassJnlLine.Description;
            GenJnlNextLineNo := GenJnlNextLineNo + 10000;
            "Line No." := GenJnlNextLineNo;
            Insert(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckBatch()
    var
        Template: Code[10];
        Batch: Code[10];
        DeprBook1: Record "Depreciation Book";
    begin
        if not FAJnlSetup.Get(FADeprBook."Depreciation Book Code", UserId) then
            FAJnlSetup.Get(FADeprBook."Depreciation Book Code", '');

        DeprBook1.Get(FADeprBook3."Depreciation Book Code");
        if DeprBook1."G/L Integration - Acq. Cost" then begin
            Template := FAJnlSetup."Gen. Jnl. Template Name";
            Batch := FAJnlSetup."Gen. Jnl. Batch Name";
        end else begin
            Template := FAJnlSetup."FA Jnl. Template Name";
            Batch := FAJnlSetup."FA Jnl. Batch Name";
        end;

        if not FAJnlSetup.Get(FADeprBook3."Depreciation Book Code", UserId) then
            FAJnlSetup.Get(FADeprBook3."Depreciation Book Code", '');

        if DeprBook1."G/L Integration - Acq. Cost" then begin
            FAJnlSetup.TestField("Gen. Jnl. Template Name", Template);
            FAJnlSetup.TestField("Gen. Jnl. Batch Name", Batch);
        end else begin
            FAJnlSetup.TestField("FA Jnl. Template Name", Template);
            FAJnlSetup.TestField("FA Jnl. Batch Name", Batch);
        end;
    end;

    local procedure GetNewFADeprBook(var FAReclassJnlLine: Record "FA Reclass. Journal Line")
    begin
        with FAReclassJnlLine do begin
            GLSetup.Get();
            if GLSetup."Enable Russian Accounting" then begin
                FADeprBook2.Get("New FA No.", "New Depreciation Book Code");
                if NewFA."Undepreciable FA" then begin
                    FASetup.Get();
                    FASetup.TestField("Quantitative Depr. Book");
                    FADeprBook3.SetRange("FA No.", "New FA No.");
                    FADeprBook3.SetRange("Depreciation Book Code", FASetup."Quantitative Depr. Book");
                    if not FADeprBook3.Find('-') then begin
                        FADeprBook3.Init();
                        FADeprBook3."FA No." := "New FA No.";
                        FADeprBook3."Depreciation Book Code" := FASetup."Quantitative Depr. Book";
                        FADeprBook3.Insert();
                    end;
                end;
            end else
                FADeprBook2.Get("New FA No.", "Depreciation Book Code");
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenJnlLineInsert(var GenJournalLine: Record "Gen. Journal Line"; var FAReclassJournalLine: Record "FA Reclass. Journal Line"; Sign: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFAJnlLineInsert(var FAJournalLine: Record "FA Journal Line"; var FAReclassJournalLine: Record "FA Reclass. Journal Line"; Sign: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcAmounts(FAReclassJnlLine: Record "FA Reclass. Journal Line"; var Amounts: array[9] of Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFAReclassLine(var FAReclassJnlLine: Record "FA Reclass. Journal Line"; var Done: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcAmountsOnAfterSetAmounts(FADepreciationBook: Record "FA Depreciation Book"; var Amounts: array[9] of Decimal; TransferType: array[9] of Boolean)
    begin
    end;
}

