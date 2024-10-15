codeunit 11519 "Swiss QR-Bill Billing Info"
{
    var
        VATDetailsTotalTxt: Label '%1% for the total amount', Comment = '%1 - VAT percent (0..100)';
        VATDetailsTxt: Label '%1% on %2', Comment = '%1 - VAT percent (0..100), %2 - amount';
        DateRangeTxt: Label '%1 to %2', Comment = '%1 - start\from date, %2 - end\to date';
        PaymentTermsTxt: Label '%1% discount for %2 days', Comment = '%1 - percent value (0..100), %2 - number of days';
        UnsupportedFormatMsg: Label 'Unsupported billing format.';

    internal procedure CreateBillingInfoString(var BillingDetail: Record "Swiss QR-Bill Billing Detail"; FormatCode: Code[10]) Result: Text[140]
    var
        BillingDetail2: Record "Swiss QR-Bill Billing Detail" temporary;
        AddText: Text;
    begin
        // compress by Tag Codes: "tag-codeX/value/tag-codeX/value2" to "tag-codeX/value1;value2"
        BillingDetail.SetRange("Format Code", FormatCode);
        with BillingDetail do
            if FindSet() then
                repeat
                    BillingDetail2.SetRange("Tag Code", "Tag Code");
                    if BillingDetail2.FindFirst() then begin
                        BillingDetail2."Tag Value" += StrSubstNo(';%1', "Tag Value");
                        BillingDetail2.Modify();
                    end else begin
                        BillingDetail2.SetRange("Tag Code");
                        if BillingDetail2.FindLast() then;
                        BillingDetail2.AddBufferRecord(FormatCode, "Tag Code", "Tag Value");
                    end;
                until Next() = 0;

        // print in a following format: formatcode/tagcode1/value1/tagcode2/value2
        BillingDetail2.Reset();
        with BillingDetail2 do
            if FindSet() then begin
                Result := FormatCode;
                repeat
                    AddText := StrSubstNo('/%1/%2', "Tag Code", "Tag Value");
                    if StrLen(Result + AddText) < 140 then
                        Result += StrSubstNo('/%1/%2', "Tag Code", "Tag Value");
                until Next() = 0;
            end;
    end;

    internal procedure GetDocumentVATDetails(var SourceTempVATAmountLine: Record "VAT Amount Line") Result: Text
    var
        TargetTempVATAmountLine: Record "VAT Amount Line" temporary;
    begin
        // format P vat% on A amount as "P:A"
        // single should be printed only % "P" (but zero % goes as "0:A")
        SumUpVATAmountLinesByVATPct(TargetTempVATAmountLine, SourceTempVATAmountLine);
        with TargetTempVATAmountLine do
            if FindSet() then
                if (Count() > 1) or ("VAT %" = 0) then
                    repeat
                        if Result <> '' then
                            Result += ';';
                        Result += StrSubstNo('%1:%2', FormatAmount("VAT %"), FormatAmount("VAT Base"));
                    until Next() = 0
                else
                    exit(StrSubstNo('%1', FormatAmount("VAT %")));
    end;

    local procedure SumUpVATAmountLinesByVATPct(var TargetVATAmountLine: Record "VAT Amount Line"; var SourceVATAmountLine: Record "VAT Amount Line")
    begin
        // reason: rounding goes to a different lines with the same VAT %. need to sum-up
        with SourceVATAmountLine do
            if FindSet() then
                repeat
                    TargetVATAmountLine.SetRange("VAT %", "VAT %");
                    if TargetVATAmountLine.FindFirst() then begin
                        TargetVATAmountLine."VAT Base" += "VAT Base";
                        TargetVATAmountLine.Modify();
                    end else begin
                        TargetVATAmountLine.SetRange("VAT %");
                        TargetVATAmountLine := SourceVATAmountLine;
                        TargetVATAmountLine.Insert();
                    end;
                until Next() = 0;
        TargetVATAmountLine.Reset();
    end;

    internal procedure GetDocumentPaymentTerms(PmtTermsCode: Code[10]): Text
    var
        PaymentTerms: Record "Payment Terms";
        DummyDateFormula: DateFormula;
    begin
        // format P discount% on D days as "P:D"
        if PmtTermsCode <> '' then
            with PaymentTerms do
                if Get(PmtTermsCode) then
                    if ("Discount %" <> 0) and ("Discount Date Calculation" <> DummyDateFormula) then
                        exit(StrSubstNo('%1:%2', "Discount %", CalcDate("Discount Date Calculation", WorkDate()) - WorkDate()));
    end;

    internal procedure DrillDownBillingInfo(BillingInfoText: Text)
    var
        BillingDetail: Record "Swiss QR-Bill Billing Detail" temporary;
        BillingDetailsPage: Page "Swiss QR-Bill Billing Details";
    begin
        if BillingInfoText <> '' then
            if ParseBillingInfo(BillingDetail, BillingInfoText) then begin
                BillingDetailsPage.SetBuffer(BillingDetail);
                BillingDetailsPage.RunModal();
            end else
                Message(UnsupportedFormatMsg);
    end;

    internal procedure ParseBillingInfo(var BillingDetail: Record "Swiss QR-Bill Billing Detail"; BillingInfoText: Text): Boolean
    var
        TextList: List of [Text];
        TagValue: Text;
        FormatCode: Code[10];
        TagCode: Code[10];
        SlashString: Text;
        i: Integer;
    begin
        // source text = FormatCode/TagCode1/TagValue1/TagCode2/TagValue2
        if BillingInfoText <> '' then begin
            SlashString := '*SLASH*';
            BillingInfoText := BillingInfoText.Replace('\\', '\');
            BillingInfoText := BillingInfoText.Replace('\/', SlashString);
            TextList := BillingInfoText.Split('/');
            for i := 1 to TextList.Count() do
                TextList.Set(i, TextList.Get(i).Replace(SlashString, '/'));

            if TextList.Count() > 2 then begin
                FormatCode := CopyStr(TextList.Get(1), 1, MaxStrLen(FormatCode));
                TextList.RemoveAt(1);
                if FormatCode <> '' then
                    while TextList.Count() > 1 do begin
                        TagCode := CopyStr(TextList.Get(1), 1, MaxStrLen(TagCode));
                        TagValue := TextList.Get(2);
                        if (TagCode <> '') and (TagValue <> '') then
                            BillingDetail.AddBufferRecord(FormatCode, TagCode, TagValue);
                        TextList.RemoveRange(1, 2);
                    end;
            end;
            ParseDetailsDescriptions(BillingDetail, FormatCode);
        end;
        exit(not BillingDetail.IsEmpty())
    end;

    local procedure ParseDetailsDescriptions(var BillingDetail: Record "Swiss QR-Bill Billing Detail"; FormatCode: Code[10])
    var
        BillingDetail2: Record "Swiss QR-Bill Billing Detail" temporary;
    begin
        // try parse Swico "S1" format details
        // split multi values (e.g. VAT Details "P1:A1;P2:A2") into separate detail buffer records
        if FormatCode <> 'S1' then
            exit;

        // copy source into buffer2 splitting multi-values
        with BillingDetail do
            if FindSet(true) then
                repeat
                    case "Tag Type" of
                        "Tag Type"::"Document Date":
                            BillingDetail2.AddBufferRecord(FormatCode, "Tag Type", "Tag Value", ParseDate("Tag Value"));
                        "Tag Type"::"VAT Registration No.":
                            BillingDetail2.AddBufferRecord(FormatCode, "Tag Type", "Tag Value", FormatVATRegNo("Tag Value"));
                        "Tag Type"::"VAT Date":
                            BillingDetail2.AddBufferRecord(FormatCode, "Tag Type", "Tag Value", ParseDate("Tag Value"));
                        "Tag Type"::"VAT Purely On Import":
                            BillingDetail2.AddBufferRecord(FormatCode, "Tag Type", "Tag Value", ParseAmount("Tag Value"));
                        "Tag Type"::"VAT Details":
                            ParseVATDetails(BillingDetail2, "Tag Value");
                        "Tag Type"::"Payment Terms":
                            ParsePaymentTermsDetails(BillingDetail2, "Tag Value");
                        else
                            if "Tag Type" <> "Tag Type"::Unknown then
                                BillingDetail2.AddBufferRecord(FormatCode, "Tag Type", "Tag Value", "Tag Value");
                    end;
                until Next() = 0;

        // copy buffer2 back to source
        BillingDetail.DeleteAll();
        with BillingDetail2 do
            if FindSet(true) then
                repeat
                    BillingDetail := BillingDetail2;
                    BillingDetail.Insert();
                until Next() = 0;
    end;

    local procedure ParseVATDetails(var BillingDetail: Record "Swiss QR-Bill Billing Detail"; SourceText: Text)
    var
        PairsTextList: List of [Text];
        DetailsTextList: List of [Text];
        Percent: Decimal;
        Amount: Decimal;
    begin
        // source text = "P1:A1;P2:A2;P3"
        if SourceText <> '' then begin
            PairsTextList := SourceText.Split(';');
            while PairsTextList.Count() > 0 do begin
                DetailsTextList := PairsTextList.Get(1).Split(':');
                case DetailsTextList.Count() of
                    1:
                        if Evaluate(Percent, DetailsTextList.Get(1), 9) then
                            BillingDetail.AddBufferRecord(
                                'S1', BillingDetail."Tag Type"::"VAT Details",
                                PairsTextList.Get(1), StrSubstNo(VATDetailsTotalTxt, Percent));
                    2:
                        if Evaluate(Percent, DetailsTextList.Get(1), 9) and Evaluate(Amount, DetailsTextList.Get(2)) then
                            BillingDetail.AddBufferRecord(
                                'S1', BillingDetail."Tag Type"::"VAT Details",
                                PairsTextList.Get(1), StrSubstNo(VATDetailsTxt, Percent, Amount));
                end;
                PairsTextList.RemoveAt(1);
            end;
        end;
    end;

    local procedure ParsePaymentTermsDetails(var BillingDetail: Record "Swiss QR-Bill Billing Detail"; SourceText: Text)
    var
        PairsTextList: List of [Text];
        DetailsTextList: List of [Text];
        Percent: Decimal;
        Days: Integer;
    begin
        // source text = "P1:D1;P2:D2"
        if SourceText <> '' then begin
            PairsTextList := SourceText.Split(';');
            while PairsTextList.Count() > 0 do begin
                DetailsTextList := PairsTextList.Get(1).Split(':');
                if DetailsTextList.Count() = 2 then
                    if Evaluate(Percent, DetailsTextList.Get(1), 9) and Evaluate(Days, DetailsTextList.Get(2)) then
                        BillingDetail.AddBufferRecord(
                            'S1', BillingDetail."Tag Type"::"Payment Terms",
                            PairsTextList.Get(1), StrSubstNo(PaymentTermsTxt, Percent, Days));
                PairsTextList.RemoveAt(1);
            end;
        end;
    end;

    local procedure ParseDate(DateText: Text): Text
    var
        ParsedDate: array[2] of Date;
    begin
        // source text = "YYMMDD" or "YYMMDDYYMMDD" (date range)
        case StrLen(DateText) of
            6:
                if ParseSingleDate(ParsedDate[1], DateText) then
                    exit(Format(ParsedDate[1]));
            12:
                if ParseSingleDate(ParsedDate[1], CopyStr(DateText, 1, 6)) and
                    ParseSingleDate(ParsedDate[2], CopyStr(DateText, 7, 6))
                then
                    exit(StrSubstNo(DateRangeTxt, ParsedDate[1], ParsedDate[2]));
        end;
    end;

    local procedure ParseSingleDate(var ResultDate: Date; DateText: Text): Boolean
    var
        Year: Integer;
        Month: Integer;
        Day: Integer;
    begin
        // source text = "YYMMDD"
        if StrLen(DateText) = 6 then
            if Evaluate(Year, CopyStr(DateText, 1, 2)) and
                Evaluate(Month, CopyStr(DateText, 3, 2)) and
                Evaluate(Day, CopyStr(DateText, 5, 2))
            then begin
                ResultDate := DMY2Date(Day, Month, 2000 + Year);
                exit(true);
            end;
        exit(false);
    end;

    local procedure ParseAmount(SourceText: Text): Text
    var
        Amount: Decimal;
    begin
        // parse as XML amount
        if SourceText <> '' then
            if Evaluate(Amount, SourceText, 9) then
                exit(Format(Amount));
    end;

    internal procedure FormatDate(SourceDate: Date): Text
    begin
        // YYMMDD
        exit(Format(SourceDate, 0, '<Year,2><Month,2><Day,2>'));
    end;

    local procedure FormatAmount(Amount: Decimal): Text
    begin
        // XML amount format
        exit(Format(Round(Amount, 0.01), 0, '<Integer><Decimals><Comma,.>'));
    end;

    internal procedure FormatVATRegNo(VATNo: Text): Text
    begin
        // leave only digits
        exit(DelChr(VATNo, '=', DelChr(VATNo, '=', '0123456789')));
    end;
}
