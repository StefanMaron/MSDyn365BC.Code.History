codeunit 10085 "A/P Magnetic Media Management"
{

    trigger OnRun()
    begin
        // Fill in the Codes used for 1099's
        Clear(Codes);

        Codes[1, 1] := 'MISC-01';
        Codes[1, 2] := 'MISC-02';
        Codes[1, 3] := 'MISC-03';
        Codes[1, 4] := 'MISC-04';
        Codes[1, 5] := 'MISC-05';
        Codes[1, 6] := 'MISC-06';
        Codes[1, 7] := 'MISC-07';
        Codes[1, 8] := 'MISC-08';
        Codes[1, 9] := 'MISC-09';
        Codes[1, 10] := 'MISC-10';
        Codes[1, 11] := 'MISC-11';
        Codes[1, 12] := 'MISC-12';
        Codes[1, 13] := 'MISC-13';
        Codes[1, 14] := 'MISC-14';
        Codes[1, 15] := 'MISC-15';

        Codes[2, 1] := 'DIV-01-A';
        Codes[2, 2] := 'DIV-01-B';
        Codes[2, 3] := 'DIV-02-A';
        Codes[2, 5] := 'DIV-05';
        Codes[2, 6] := 'DIV-02-B';
        Codes[2, 7] := 'DIV-02-C';
        Codes[2, 8] := 'DIV-02-D';
        Codes[2, 9] := 'DIV-03';
        Codes[2, 10] := 'DIV-04';
        Codes[2, 11] := 'DIV-06';
        Codes[2, 12] := 'DIV-07';
        Codes[2, 13] := 'DIV-09';
        Codes[2, 14] := 'DIV-10';
        Codes[2, 15] := 'DIV-11';
        Codes[2, 16] := 'DIV-12';
        Codes[2, 17] := 'DIV-02-E';
        Codes[2, 18] := 'DIV-02-F';

        Codes[3, 1] := 'INT-01';
        Codes[3, 2] := 'INT-02';
        Codes[3, 3] := 'INT-03';
        Codes[3, 4] := 'INT-04';
        Codes[3, 5] := 'INT-05';
        Codes[3, 6] := 'INT-06';
        Codes[3, 8] := 'INT-08';
        Codes[3, 9] := 'INT-09';
        Codes[3, 10] := 'INT-10';
        Codes[3, 11] := 'INT-11';
        Codes[3, 12] := 'INT-12';
        Codes[3, 13] := 'INT-13';

        Codes[4, 1] := 'NEC-01';
        Codes[4, 4] := 'NEC-04';
    end;

    var
        Codes: array[4, 30] of Code[10];
        Amounts: array[4, 30] of Decimal;
        FormatAddress: Codeunit "Format Address";
        Totals: array[4, 30] of Decimal;
        FormBox: Record "IRS 1099 Form-Box";
        CodeNotSetupErr: Label 'The 1099 code %1 has not been setup in the initialization.', Comment = '%1 = 1099 Code';
        Unknown1099CodeErr: Label 'Invoice %1 on vendor %2 has unknown 1099 code  %3.', Comment = '%1 = Invoice Entry No., %2 = Vendor No., %3 = 1099 Code';

    procedure GetAmt("Code": Code[10]; i: Integer; EndLine: Integer): Decimal
    var
        j: Integer;
    begin
        j := 1;
        while (Codes[i, j] <> Code) and (j <= EndLine) do
            j := j + 1;

        if (Codes[i, j] = Code) and (j <= EndLine) then
            exit(Amounts[i, j]);

        Error(CodeNotSetupErr, Code);
    end;

    procedure UpdateLines(InvoiceEntry: Record "Vendor Ledger Entry"; i: Integer; EndLine: Integer; "Code": Code[10]; Amount: Decimal): Integer
    var
        j: Integer;
    begin
        j := 1;
        while (Codes[i, j] <> Code) and (j <= EndLine) do
            j := j + 1;

        if (Codes[i, j] = Code) and (j <= EndLine) then begin
            Amounts[i, j] += Amount;
            Totals[i, j] += Amount;
        end else
            Error(Unknown1099CodeErr, InvoiceEntry."Entry No.", InvoiceEntry."Vendor No.", Code);
        exit(j); // returns code index found
    end;

    procedure AnyAmount(i: Integer; EndLine: Integer): Boolean
    var
        j: Integer;
    begin
        for j := 1 to EndLine do
            if FormBox.Get(Codes[i, j]) then begin
                if FormBox."Minimum Reportable" < 0.0 then
                    if Amounts[i, j] <> 0.0 then begin
                        Amounts[i, j] := -Amounts[i, j];
                        exit(true);
                    end;
                if FormBox."Minimum Reportable" >= 0.0 then
                    if Amounts[i, j] <> 0 then begin
                        if Amounts[i, j] >= FormBox."Minimum Reportable" then
                            exit(true);
                        Totals[i, j] := Totals[i, j] - Amounts[i, j];
                        Amounts[i, j] := 0;
                    end;
            end;
        exit(false);
    end;

    procedure FormatMoneyAmount(Amount: Decimal; Length: Integer): Text[250]
    var
        AmtStr: Text[32];
    begin
        AmtStr := StripNonNumerics(Format(Round(Abs(Amount) * 100, 1)));

        // left zero-padding
        if Length - StrLen(AmtStr) > 0 then
            AmtStr := '0000000000000000000' + AmtStr;
        AmtStr := DelStr(AmtStr, 1, StrLen(AmtStr) - Length);
        exit(AmtStr);
    end;

    procedure FormatAmount(Amount: Integer; Length: Integer): Text[250]
    var
        AmtStr: Text[30];
    begin
        AmtStr := Format(Amount);

        // left zero-padding
        if Length - StrLen(AmtStr) > 0 then
            AmtStr := '000000000000000000' + AmtStr;
        AmtStr := DelStr(AmtStr, 1, StrLen(AmtStr) - Length);
        exit(AmtStr);
    end;

    procedure StripNonNumerics(Text: Text[80]): Text[250]
    begin
        exit(DelChr(Text, '=', '-,. '));
    end;

    procedure EditCompanyInfo(var CompInfo: Record "Company Information")
    begin
        with CompInfo do
            "Federal ID No." := StripNonNumerics("Federal ID No.");
    end;

    procedure SwitchZipCodeParts(var ZIP: Code[20])
    begin
        if StrLen(ZIP) > 5 then
            ZIP := PadStr(CopyStr(ZIP, 6), 5) + CopyStr(ZIP, 1, 5)
        else
            ZIP := '     ' + ZIP;
    end;

    procedure FormatCompanyAddress(var CompanyInfo: Record "Company Information"; var CompanyAddress: array[8] of Text[30])
    begin
        with CompanyInfo do begin
            Get();
            FormatAddress.Company(CompanyAddress, CompanyInfo);
        end;
    end;

    procedure BuildAddressLine(CompanyInfo: Record "Company Information"): Text[40]
    var
        "Address 3": Text[40];
    begin
        with CompanyInfo do begin
            // Format City/State/Zip address line
            if StrLen(City + ', ' + County + '  ' + "Post Code") > MaxStrLen("Address 3") then
                "Address 3" := City
            else
                if (City <> '') and (County <> '') then
                    "Address 3" := City + ', ' + County + '  ' + "Post Code"
                else
                    "Address 3" := DelChr(City + ' ' + County + ' ' + "Post Code", '<>');
        end;
        exit("Address 3");
    end;

    procedure ClearAmts()
    begin
        Clear(Amounts);
    end;

    procedure AmtCodes(var CodeNos: Text[12]; i: Integer; EndLine: Integer)
    var
        ActualCodePos: array[30] of Integer;
        j: Integer;
    begin
        Clear(CodeNos);

        case i of
            1:   // MISC
                for j := 1 to EndLine do
                    if Amounts[i, j] <> 0.0 then
                        case j of
                            9:
                                IncrCodeNos(CodeNos, ActualCodePos, 'A', 10); // Crop Insurance Proceeds
                            10:
                                IncrCodeNos(CodeNos, ActualCodePos, 'C', 12); // gross legal proceeds
                            11:
                                IncrCodeNos(CodeNos, ActualCodePos, 'F', 15); // fish purchased for resale
                            12:
                                IncrCodeNos(CodeNos, ActualCodePos, 'D', 13); // 409A deferral
                            13:
                                IncrCodeNos(CodeNos, ActualCodePos, 'B', 11); // excess golden parachutes
                            15:
                                IncrCodeNos(CodeNos, ActualCodePos, 'E', 14); // 409A Income
                            else
                                IncrCodeNos(CodeNos, ActualCodePos, Format(j), j);
                        end;
            2: // DIV
                begin
                    if EndLine > 1 then begin
                        // special check for DIV complex amounts
                        if GetTotalOrdinaryDividendsAmt() <> 0 then
                            CodeNos := InsStr(CodeNos, Format(1), 1);
                    end;
                    AmtCodesDIV(CodeNos, i, 2, EndLine);
                end;
            3: // INT
                AmtCodesINT(CodeNos, i, 1, EndLine);
            4: // NEC
                CodeNos := '1';
        end;
    end;

    local procedure AmtCodesDIV(var CodeNos: Text[12]; FormType: Integer; StartLine: Integer; EndLine: Integer)
    var
        j: Integer;
    begin
        for j := StartLine to EndLine do
            if Amounts[FormType, j] <> 0.0 then
                case j of
                    10:
                        CodeNos := InsStr(CodeNos, 'A', j); // FIT withheld
                    11:
                        CodeNos := InsStr(CodeNos, 'B', j); // Investment expenses
                    12:
                        CodeNos := InsStr(CodeNos, 'C', j); // Foreign tax paid
                    13:
                        CodeNos := InsStr(CodeNos, 'D', j); // Cash liquidation distributions
                    14:
                        CodeNos := InsStr(CodeNos, 'E', j); // Noncash liquidation distributions
                    15:
                        CodeNos := InsStr(CodeNos, 'F', j); // Exempt-interest dividends
                    16:
                        CodeNos := InsStr(CodeNos, 'G', j); // Specified private activity bond interest dividends
                    17:
                        CodeNos := CopyStr(InsStr(CodeNos, 'H', j), 1, MaxStrLen(CodeNos)); // Section 897 ordinary dividends
                    18:
                        CodeNos := CopyStr(InsStr(CodeNos, 'J', j), 1, MaxStrLen(CodeNos));  // Section 897 capital gain
                    else
                        CodeNos := InsStr(CodeNos, Format(j), j);
                end;
    end;

    local procedure AmtCodesINT(var CodeNos: Text[12]; FormType: Integer; StartLine: Integer; EndLine: Integer)
    var
        j: Integer;
    begin
        for j := StartLine to EndLine do
            if Amounts[FormType, j] <> 0.0 then
                case j of
                    10:
                        CodeNos := InsStr(CodeNos, 'A', j); // Market discount
                    11:
                        CodeNos := InsStr(CodeNos, 'B', j); // Bond premium
                    12:
                        CodeNos := InsStr(CodeNos, 'E', j); // Bond premium on Treasury obligation
                    13:
                        CodeNos := InsStr(CodeNos, 'D', j); // Bond premium on tax exempt bond
                    else
                        CodeNos := InsStr(CodeNos, Format(j), j);
                end;
    end;

    procedure GetTotal("Code": Code[10]; i: Integer; EndLine: Integer): Decimal
    var
        j: Integer;
    begin
        j := 1;
        while (Codes[i, j] <> Code) and (j <= EndLine) do
            j := j + 1;

        if (Codes[i, j] = Code) and (j <= EndLine) then
            exit(Totals[i, j]);

        Error(CodeNotSetupErr, Code);
    end;

    procedure ClearTotals()
    begin
        Clear(Totals);
    end;

    procedure DirectSalesCheck(j: Integer): Boolean
    begin
        if FormBox.Get(Codes[1, j]) then
            if Amounts[1, j] >= FormBox."Minimum Reportable" then
                exit(true)
            else
                exit(false);
    end;

    local procedure GetTotalOrdinaryDividendsAmt(): Decimal
    begin
        exit(Amounts[2, 1] + Amounts[2, 2] + Amounts[2, 11] + Amounts[2, 5]);
    end;

    local procedure IncrCodeNos(var CodeNos: Text[12]; var ActualCodePosArray: array[30] of Integer; AmountCode: Text[1]; ExpectedCodePos: Integer)
    var
        i: Integer;
        ActualCodePos: Integer;
    begin
        if ExpectedCodePos > 2 then begin
            i := ExpectedCodePos;
            while (i > 2) and (ActualCodePos = 0) do begin
                ActualCodePos := ActualCodePosArray[i - 1];
                i -= 1;
            end;
            if ActualCodePos <> 0 then
                for i := (ExpectedCodePos + 1) to ArrayLen(ActualCodePosArray) do
                    if ActualCodePosArray[i] <> 0 then
                        ActualCodePosArray[i] += 1;
        end;
        if ActualCodePos = 0 then
            ActualCodePos := StrLen(CodeNos) + 1;
        CodeNos := InsStr(CodeNos, AmountCode, ActualCodePos);
        ActualCodePosArray[ExpectedCodePos] := ActualCodePos + 1;
    end;
}

