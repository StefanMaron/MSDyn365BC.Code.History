report 11106 "Intrastat - Disk Tax Auth AT"
{
    Caption = 'Intrastat - Disk Tax Auth AT';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Intrastat Jnl. Batch"; "Intrastat Jnl. Batch")
        {
            DataItemTableView = SORTING("Journal Template Name", Name);
            RequestFilterFields = "Journal Template Name", Name;
            dataitem("Intrastat Jnl. Line"; "Intrastat Jnl. Line")
            {
                DataItemLink = "Journal Template Name" = FIELD("Journal Template Name"), "Journal Batch Name" = FIELD(Name);
                DataItemTableView = SORTING(Type, "Country/Region Code", "Tariff No.", "Transaction Type", "Transport Method", Area, "Entry/Exit Point", "Transaction Specification", "Country/Region of Origin Code");

                trigger OnAfterGetRecord()
                begin
                    if ("Tariff No." = '') and
                       ("Country/Region Code" = '') and
                       ("Transaction Type" = '') and
                       ("Transport Method" = '') and
                       ("Total Weight" = 0)
                    then
                        CurrReport.Skip();

                    IntrastatJnlLineBuf := "Intrastat Jnl. Line";

                    // Check Period
                    LinePeriod := Format(Date, 4, Text005);
                    if LinePeriod <> Period then
                        Error(InvalideDateErr, Date, "Line No.", Period);

#if CLEAN19
                    IntraJnlManagement.ValidateReportWithAdvancedChecklist("Intrastat Jnl. Line", Report::"Intrastat - Disk Tax Auth AT", true);
#else
                    if IntrastatSetup."Use Advanced Checklist" then
                        IntraJnlManagement.ValidateReportWithAdvancedChecklist("Intrastat Jnl. Line", Report::"Intrastat - Disk Tax Auth AT", true)
                    else begin
                        TestField("Tariff No.");
                        TestField("Country/Region Code");
                        TestField("Transaction Type");
                        if CompanyInfo."Check Transport Method" then
                            TestField("Transport Method");
                        if CompanyInfo."Check Transaction Specific." then
                            TestField("Transaction Specification");
                        TestField("Total Weight");
                        if "Supplementary Units" then
                            TestField(Quantity);
                    end;
#endif

                    // Check Tariff
                    IntrastatJnlLineBuf."Tariff No." := DelChr("Tariff No.");
                    if StrLen(IntrastatJnlLineBuf."Tariff No.") <> 8 then
                        Error(Text008, IntrastatJnlLineBuf."Line No.");

                    if "Transport Method" <> '' then
                        if StrLen("Transport Method") <> 1 then
                            Error(Text009);
                    if StrLen("Transaction Type") <> 1 then
                        Error(Text010, FieldCaption("Transaction Type"), "Transaction Type");
                    if (StrLen("Transaction Specification") <> 5) and (StrLen("Transaction Specification") <> 0) then
                        Error(Text011, FieldCaption("Transaction Specification"), "Transaction Specification");

                    if (Type = Type::Receipt) and ("Country/Region of Origin Code" = '') then
                        IntrastatJnlLineBuf."Country/Region of Origin Code" := "Country/Region Code";

                    AddField :=
                      Format("Country/Region Code", 5) + Format("Tariff No.", 10) +
                      Format("Transaction Type", 10) + Format("Transport Method", 10) +
                      Format("Transaction Specification", 10) + Format("Country/Region of Origin Code", 5);

                    if (TempType <> Type) or (StrLen(TempAddField) = 0) then begin
                        TempType := Type;
                        TempAddField := AddField;
                        IntraRefNo := CopyStr(IntraRefNo, 1, 4) + '001001';
                    end else
                        if TempAddField <> AddField then begin
                            TempAddField := AddField;
                            if CopyStr(IntraRefNo, 8, 3) = '999' then
                                IntraRefNo := IncStr(CopyStr(IntraRefNo, 1, 7)) + '001'
                            else
                                IntraRefNo := IncStr(IntraRefNo);
                        end;

                    IntrastatJnlLineBuf."Internal Ref. No." := IntraRefNo;
                    IntrastatJnlLineBuf.Insert();
                end;

                trigger OnPostDataItem()
                begin
                    if IntrastatJnlLineBuf.FindSet then
                        repeat
                            IntraJnlLineTest.Get(
                              IntrastatJnlLineBuf."Journal Template Name",
                              IntrastatJnlLineBuf."Journal Batch Name",
                              IntrastatJnlLineBuf."Line No.");
                            IntraJnlLineTest."Tariff No." := IntrastatJnlLineBuf."Tariff No.";
                            IntraJnlLineTest."Country/Region of Origin Code" := IntrastatJnlLineBuf."Country/Region of Origin Code";
                            IntraJnlLineTest."Internal Ref. No." := IntrastatJnlLineBuf."Internal Ref. No.";
                            IntraJnlLineTest.Modify();
                        until IntrastatJnlLineBuf.Next = 0;
                end;

                trigger OnPreDataItem()
                begin
                    // General Inits
                    Apostroph := 39;
                    EndOfLine := Format(Apostroph, 1);
                    DateOfToday := Format(Today, 6, Text000);
                    Today4 := Format(Today, 8, Text001);
                    TimeOfNow := Format(Time, 4, Text002);
                    IntrastatJnlLineBuf.DeleteAll();

                    // UID Check
                    CompanyInfo."VAT Registration No." := RemoveSpecChar(CompanyInfo."VAT Registration No.");
                    CompanyInfo.TestField("VAT Registration No.");
                    if StrLen(CompanyInfo."VAT Registration No.") > 11 then
                        Error(Text003);
                    UIDNo := CompanyInfo."VAT Registration No.";

                    // Statisticperiod
                    "Intrastat Jnl. Batch".TestField("Statistics Period");
                    Period := "Intrastat Jnl. Batch"."Statistics Period";
                    if not Evaluate(PeriodYear, CopyStr(Period, 1, 2)) then
                        Error(Text004, Period);
                    Period4 := '20' + Period;

                    // Check of OEstatnumber
                    CompanyInfo.TestField("Statistic No.");

                    // Increment Controlnumber
                    CompanyInfo.TestField("Control No.");
                    CompanyInfo."Control No." := IncStr(CompanyInfo."Control No.");
                    CompanyInfo.Modify();
                    BKNR := CompanyInfo."Control No.";
                    TextZeroFormat(BKNR, 8);

                    // Check Adress
                    CompanyInfo.TestField(Name);
                    CompanyInfo.TestField(Address);
                    CompanyInfo.TestField("Post Code");
                    CompanyInfo.TestField(City);
                    CompanyInfo.TestField("Phone No.");
                    CompanyInfo.TestField("Fax No.");
                end;
            }
            dataitem(IntraJnlLineR; "Intrastat Jnl. Line")
            {
                DataItemLink = "Journal Template Name" = FIELD("Journal Template Name"), "Journal Batch Name" = FIELD(Name);
                DataItemTableView = SORTING(Type, "Internal Ref. No.") WHERE(Type = CONST(Receipt));

                trigger OnAfterGetRecord()
                begin
                    if not PrintReceipt then
                        CurrReport.Break();

                    if (IntrastatJnlLine."Internal Ref. No." <> '') and (IntrastatJnlLine."Internal Ref. No." <> "Internal Ref. No.") then begin
                        // only if Position is not empty
                        if (IntrastatJnlLine."Tariff No." <> '') and
                           (IntrastatJnlLine."Country/Region Code" <> '') and
                           (IntrastatJnlLine."Transaction Type" <> '') and
                           (IntrastatJnlLine."Transport Method" <> '') and
                           (IntrastatJnlLine."Total Weight" <> 0)
                        then begin
                            // fieldcheck for position
                            Country.Get(IntrastatJnlLine."Country/Region Code");
                            Country.TestField("Intrastat Code");
                            if StrLen(Country."Intrastat Code") <> 2 then
                                Error(Text043, "Country/Region Code");

                            CountryOfOrg.Get(IntrastatJnlLine."Country/Region of Origin Code");
                            CountryOfOrg.TestField("Intrastat Code");
                            if StrLen(CountryOfOrg."Intrastat Code") <> 2 then
                                Error(Text044, CountryOfOrg."Intrastat Code");

                            PosNo := PosNo + 1;

                            if IntrastatJnlLine."Transaction Specification" = '' then
                                IntraFile.Write(Text045 + DecimalZeroFormat(PosNo, 4) + '+' + IntrastatJnlLine."Tariff No." +
                                  Text046 + IntrastatJnlLine."Transaction Type" + ':112+' + '0' + ':177' + EndOfLine)
                            else
                                IntraFile.Write(Text045 + DecimalZeroFormat(PosNo, 4) + '+' + IntrastatJnlLine."Tariff No." +
                                  Text046 + IntrastatJnlLine."Transaction Type" + ':112+' +
                                  IntrastatJnlLine."Transaction Specification" + ':177' + EndOfLine);
                            LF;
                            IntraFile.Write(Text047 + CopyStr(RemoveSpecChar(IntrastatJnlLine."Item Description"), 1, 70) + EndOfLine);
                            LF;
                            IntraFile.Write(Text048 + Country."Intrastat Code" + EndOfLine);
                            LF;
                            IntraFile.Write(Text049 + CountryOfOrg."Intrastat Code" + EndOfLine);
                            LF;
                            IntraFile.Write(Text050 + DecimalZeroFormat(IntrastatJnlLine."Total Weight", 12) + EndOfLine);
                            LF;
                            if IntrastatJnlLine."Supplementary Units" then begin
                                IntraFile.Write(Text051 + DecimalZeroFormat(IntrastatJnlLine.Quantity, 12) + EndOfLine);
                                LF;
                                Segments := Segments + 9;
                            end else
                                Segments := Segments + 8;
                            IntraFile.Write(Text052 + IntrastatJnlLine."Transport Method" + EndOfLine);
                            LF;
                            IntraFile.Write(Text053 + DecimalZeroFormat(IntrastatJnlLine.Amount, 12) + EndOfLine);
                            LF;
                            IntraFile.Write(Text054 + DecimalZeroFormat(IntrastatJnlLine."Statistical Value", 12) + EndOfLine);
                            LF;
                        end;
                        Clear(IntrastatJnlLine);
                    end;

                    ValueTotal := ValueTotal + Amount;
                    StatValueTotal := StatValueTotal + "Statistical Value";
                    WeightTotal := WeightTotal + Abs("Total Weight");
                    QuantityTotal := QuantityTotal + Abs(Quantity);
                    SupplementaryUnitsQtyTotal += IncSupplementaryUnitsQtyTotal("Tariff No.", Quantity);
                    Amount := Amount + IntrastatJnlLine.Amount;
                    "Statistical Value" := "Statistical Value" + IntrastatJnlLine."Statistical Value";
                    "Total Weight" := "Total Weight" + IntrastatJnlLine."Total Weight";
                    Quantity := Quantity + IntrastatJnlLine.Quantity;
                    IntrastatJnlLine := IntraJnlLineR;
                end;

                trigger OnPostDataItem()
                begin
                    if (IntrastatJnlLine."Tariff No." <> '') and
                       (IntrastatJnlLine."Country/Region Code" <> '') and
                       (IntrastatJnlLine."Transaction Type" <> '') and
                       (IntrastatJnlLine."Transport Method" <> '') and
                       (IntrastatJnlLine."Total Weight" <> 0)
                    then begin
                        // fieldcheck for position
                        Country.Get(IntrastatJnlLine."Country/Region Code");
                        Country.TestField("Intrastat Code");
                        if StrLen(Country."Intrastat Code") <> 2 then
                            Error(Text043, "Country/Region Code");

                        CountryOfOrg.Get(IntrastatJnlLine."Country/Region of Origin Code");
                        CountryOfOrg.TestField("Intrastat Code");
                        if StrLen(CountryOfOrg."Intrastat Code") <> 2 then
                            Error(Text044, CountryOfOrg."Intrastat Code");

                        PosNo := PosNo + 1;

                        if IntrastatJnlLine."Transaction Specification" = '' then
                            IntraFile.Write(Text045 + DecimalZeroFormat(PosNo, 4) + '+' + IntrastatJnlLine."Tariff No." +
                              Text046 + IntrastatJnlLine."Transaction Type" + ':112+' + '0' + ':177' + EndOfLine)
                        else
                            IntraFile.Write(Text045 + DecimalZeroFormat(PosNo, 4) + '+' + IntrastatJnlLine."Tariff No." +
                              Text046 + IntrastatJnlLine."Transaction Type" + ':112+' +
                              IntrastatJnlLine."Transaction Specification" + ':177' + EndOfLine);
                        LF;
                        IntraFile.Write(Text047 + CopyStr(RemoveSpecChar(IntrastatJnlLine."Item Description"), 1, 70) + EndOfLine);
                        LF;
                        IntraFile.Write(Text048 + Country."Intrastat Code" + EndOfLine);
                        LF;
                        IntraFile.Write(Text049 + CountryOfOrg."Intrastat Code" + EndOfLine);
                        LF;
                        IntraFile.Write(Text050 + DecimalZeroFormat(IntrastatJnlLine."Total Weight", 12) + EndOfLine);
                        LF;
                        if IntrastatJnlLine."Supplementary Units" then begin
                            IntraFile.Write(Text051 + DecimalZeroFormat(IntrastatJnlLine.Quantity, 12) + EndOfLine);
                            LF;
                            Segments := Segments + 9;
                        end else
                            Segments := Segments + 8;
                        IntraFile.Write(Text052 + IntrastatJnlLine."Transport Method" + EndOfLine);
                        LF;
                        IntraFile.Write(Text053 + DecimalZeroFormat(IntrastatJnlLine.Amount, 12) + EndOfLine);
                        LF;
                        IntraFile.Write(Text054 + DecimalZeroFormat(IntrastatJnlLine."Statistical Value", 12) + EndOfLine);
                        LF;
                    end;
                    Clear(IntrastatJnlLine);

                    if not PrintReceipt then
                        CurrReport.Break();

                    Segments := Segments + 19;

                    IntraFile.Write(Text033 + EndOfLine);
                    LF;
                    IntraFile.Write(Text034 + DecimalZeroFormat(PosNo, 5) + EndOfLine);
                    LF;
                    IntraFile.Write(Text035 + DecimalZeroFormat(WeightTotal, 13) + EndOfLine);
                    LF;
                    if QuantityTotal <> 0 then begin
                        IntraFile.Write(
                          Text036 + DecimalZeroFormat(SupplementaryUnitsQtyTotal, 13) + EndOfLine);
                        LF;
                        Segments := Segments + 1;
                    end;
                    IntraFile.Write(Text037 + DecimalZeroFormat(ValueTotal, 13) + EndOfLine);
                    LF;
                    IntraFile.Write(Text038 + DecimalZeroFormat(StatValueTotal, 13) + EndOfLine);
                    LF;
                    IntraFile.Write(Text039 + RemoveSpecChar(CompanyInfo."Statistic No.") + EndOfLine);
                    LF;
                    IntraFile.Write(Text040 + Today4 + ':102' + EndOfLine);
                    LF;
                    IntraFile.Write(Text041 + DecimalZeroFormat(Segments, 5) + '+' + BKNR + EndOfLine);
                    LF;
                    IntraFile.Write(Text042 + BKNR + EndOfLine);
                    LF;
                    IntraFile.Close;

                    RecordsProcessed := RecordsProcessed + 1;
                    DiskStatus.Update(1, Round(RecordsProcessed / RecordsTotal * 10000, 1));
                end;

                trigger OnPreDataItem()
                begin
                    if not PrintReceipt then
                        CurrReport.Break();

                    FilenameForReceipts := CopyStr(CompanyInfo."Purch. Authorized No.", 1, 4) +
                      "Intrastat Jnl. Batch"."Statistics Period" + '.edi';

                    ServerTempFileReceipts := FileManagement.ServerTempFileName('tmp');
                    IntraFile.TextMode := false;
                    IntraFile.WriteMode := true;
                    IntraFile.Create(ServerTempFileReceipts);
                    CurrentType := CurrentType::Receipt;

                    DiskStatus.Open(Text015 +
                      '@1@@@@@@@@@@@@@@@@@@@@@@@@@@@');
                    RecordsTotal := Count;

                    WeightTotal := 0;
                    ValueTotal := 0;
                    StatValueTotal := 0;
                    QuantityTotal := 0;
                    Segments := 0;
                    SupplementaryUnitsQtyTotal := 0;

                    IntraFile.Write(Text016 + EndOfLine);
                    LF;
                    IntraFile.Write(Text017 + UIDNo + Text018 + DateOfToday + ':' + TimeOfNow + '+' + BKNR + EndOfLine);
                    LF;
                    IntraFile.Write(Text019 + BKNR + Text020 + EndOfLine);
                    LF;
                    IntraFile.Write(Text021 + UIDNo + '-' + Period + BKNR + EndOfLine);
                    LF;
                    IntraFile.Write(Text022 + Period4 + ':610' + EndOfLine);
                    LF;
                    IntraFile.Write(Text023 + Today4 + ':102' + EndOfLine);
                    LF;
                    IntraFile.Write(Text024 + EndOfLine);
                    LF;
                    IntraFile.Write(
                      Text025 + UIDNo + '-000+' + RemoveSpecChar(CompanyInfo.Name) + ':' +
                      RemoveSpecChar(CompanyInfo."Name 2") + ':' +
                      RemoveSpecChar(CompanyInfo.Address) + ':' +
                      RemoveSpecChar(CompanyInfo."Post Code") + ' ' +
                      RemoveSpecChar(CompanyInfo.City) + ':' +
                      RemoveSpecChar(Contactperson) + EndOfLine);
                    LF;
                    IntraFile.Write(Text026 + RemoveSpecChar(CompanyInfo."Phone No.") + Text027 + EndOfLine);
                    LF;
                    IntraFile.Write(Text026 + RemoveSpecChar(CompanyInfo."Fax No.") + Text028 + EndOfLine);
                    LF;
                    IntraFile.Write(Text029 + EndOfLine);
                    LF;
                    IntraFile.Write(Text030 + EndOfLine);
                    LF;
                    IntraFile.Write(Text032 + EndOfLine);
                    LF;
                    PosNo := 0;

                    Clear(IntrastatJnlLine);
                end;
            }
            dataitem(IntraJnlLineS; "Intrastat Jnl. Line")
            {
                DataItemLink = "Journal Template Name" = FIELD("Journal Template Name"), "Journal Batch Name" = FIELD(Name);
                DataItemTableView = SORTING(Type, "Internal Ref. No.") WHERE(Type = CONST(Shipment));

                trigger OnAfterGetRecord()
                begin
                    if not PrintShipment then
                        CurrReport.Break();

                    if (IntrastatJnlLine."Internal Ref. No." <> '') and (IntrastatJnlLine."Internal Ref. No." <> "Internal Ref. No.") then begin
                        // only if position is not empty
                        if (IntrastatJnlLine."Tariff No." <> '') and
                           (IntrastatJnlLine."Country/Region Code" <> '') and
                           (IntrastatJnlLine."Transaction Type" <> '') and
                           (IntrastatJnlLine."Transport Method" <> '') and
                           (IntrastatJnlLine."Total Weight" <> 0)
                        then begin
                            // fieldcheck for position
                            Country.Get(IntrastatJnlLine."Country/Region Code");
                            Country.TestField("Intrastat Code");
                            if StrLen(Country."Intrastat Code") <> 2 then
                                Error(Text058, "Country/Region Code");

                            PosNo := PosNo + 1;

                            if IntrastatJnlLine."Transaction Specification" = '' then
                                IntraFile.Write(Text045 + DecimalZeroFormat(PosNo, 4) + '+' + IntrastatJnlLine."Tariff No." +
                                  Text059 + IntrastatJnlLine."Transaction Type" + ':112+' + '0' + ':177' + EndOfLine)
                            else
                                IntraFile.Write(Text045 + DecimalZeroFormat(PosNo, 4) + '+' + IntrastatJnlLine."Tariff No." +
                                  Text059 + IntrastatJnlLine."Transaction Type" + ':112+' +
                                  IntrastatJnlLine."Transaction Specification" + ':177' + EndOfLine);
                            LF;
                            IntraFile.Write(Text047 + CopyStr(RemoveSpecChar(IntrastatJnlLine."Item Description"), 1, 70) + EndOfLine);
                            LF;
                            IntraFile.Write(Text060 + Country."Intrastat Code" + EndOfLine);
                            LF;
                            IntraFile.Write(Text050 + DecimalZeroFormat(IntrastatJnlLine."Total Weight", 12) + EndOfLine);
                            LF;
                            if IntrastatJnlLine."Supplementary Units" then begin
                                IntraFile.Write(Text051 + DecimalZeroFormat(IntrastatJnlLine.Quantity, 12) + EndOfLine);
                                LF;
                                Segments := Segments + 8;
                            end else
                                Segments := Segments + 7;
                            IntraFile.Write(Text052 + IntrastatJnlLine."Transport Method" + EndOfLine);
                            LF;
                            IntraFile.Write(Text053 + DecimalZeroFormat(IntrastatJnlLine.Amount, 12) + EndOfLine);
                            LF;
                            IntraFile.Write(Text054 + DecimalZeroFormat(IntrastatJnlLine."Statistical Value", 12) + EndOfLine);
                            LF;
                        end;
                        Clear(IntrastatJnlLine);
                    end;

                    ValueTotal := ValueTotal + Amount;
                    StatValueTotal := StatValueTotal + "Statistical Value";
                    WeightTotal := WeightTotal + Abs("Total Weight");
                    QuantityTotal := QuantityTotal + Abs(Quantity);
                    SupplementaryUnitsQtyTotal += IncSupplementaryUnitsQtyTotal("Tariff No.", Quantity);

                    Amount := Amount + IntrastatJnlLine.Amount;
                    "Statistical Value" := "Statistical Value" + IntrastatJnlLine."Statistical Value";
                    "Total Weight" := "Total Weight" + IntrastatJnlLine."Total Weight";
                    Quantity := Quantity + IntrastatJnlLine.Quantity;
                    IntrastatJnlLine := IntraJnlLineS;
                end;

                trigger OnPostDataItem()
                begin
                    if (IntrastatJnlLine."Tariff No." <> '') and
                       (IntrastatJnlLine."Country/Region Code" <> '') and
                       (IntrastatJnlLine."Transaction Type" <> '') and
                       (IntrastatJnlLine."Transport Method" <> '') and
                       (IntrastatJnlLine."Total Weight" <> 0)
                    then begin
                        // fieldcheck for position
                        Country.Get(IntrastatJnlLine."Country/Region Code");
                        Country.TestField("Intrastat Code");
                        if StrLen(Country."Intrastat Code") <> 2 then
                            Error(Text058, "Country/Region Code");

                        PosNo := PosNo + 1;

                        if IntrastatJnlLine."Transaction Specification" = '' then
                            IntraFile.Write(Text045 + DecimalZeroFormat(PosNo, 4) + '+' + IntrastatJnlLine."Tariff No." +
                              Text059 + IntrastatJnlLine."Transaction Type" + ':112+' + '0' + ':177' + EndOfLine)
                        else
                            IntraFile.Write(Text045 + DecimalZeroFormat(PosNo, 4) + '+' + IntrastatJnlLine."Tariff No." +
                              Text059 + IntrastatJnlLine."Transaction Type" + ':112+' +
                              IntrastatJnlLine."Transaction Specification" + ':177' + EndOfLine);
                        LF;
                        IntraFile.Write(Text047 + CopyStr(RemoveSpecChar(IntrastatJnlLine."Item Description"), 1, 70) + EndOfLine);
                        LF;
                        IntraFile.Write(Text060 + Country."Intrastat Code" + EndOfLine);
                        LF;
                        IntraFile.Write(Text050 + DecimalZeroFormat(IntrastatJnlLine."Total Weight", 12) + EndOfLine);
                        LF;
                        if IntrastatJnlLine."Supplementary Units" then begin
                            IntraFile.Write(Text051 + DecimalZeroFormat(IntrastatJnlLine.Quantity, 12) + EndOfLine);
                            LF;
                            Segments := Segments + 8;
                        end else
                            Segments := Segments + 7;
                        IntraFile.Write(Text052 + IntrastatJnlLine."Transport Method" + EndOfLine);
                        LF;
                        IntraFile.Write(Text053 + DecimalZeroFormat(IntrastatJnlLine.Amount, 12) + EndOfLine);
                        LF;
                        IntraFile.Write(Text054 + DecimalZeroFormat(IntrastatJnlLine."Statistical Value", 12) + EndOfLine);
                        LF;
                    end;
                    Clear(IntrastatJnlLine);

                    if PrintReceipt or PrintShipment then begin
                        "Intrastat Jnl. Batch".Reported := true;
                        "Intrastat Jnl. Batch".Modify();
                    end;

                    if not PrintShipment then
                        CurrReport.Break();

                    Segments := Segments + 19;

                    IntraFile.Write(Text033 + EndOfLine);
                    LF;
                    IntraFile.Write(Text034 + DecimalZeroFormat(PosNo, 5) + EndOfLine);
                    LF;
                    IntraFile.Write(Text035 + DecimalZeroFormat(WeightTotal, 13) + EndOfLine);
                    LF;
                    if QuantityTotal <> 0 then begin
                        IntraFile.Write(
                          Text036 + DecimalZeroFormat(SupplementaryUnitsQtyTotal, 13) + EndOfLine);
                        LF;
                        Segments := Segments + 1;
                    end;
                    IntraFile.Write(Text037 + DecimalZeroFormat(ValueTotal, 13) + EndOfLine);
                    LF;
                    IntraFile.Write(Text038 + DecimalZeroFormat(StatValueTotal, 13) + EndOfLine);
                    LF;
                    IntraFile.Write(Text039 + RemoveSpecChar(CompanyInfo."Statistic No.") + EndOfLine);
                    LF;
                    IntraFile.Write(Text040 + Today4 + ':102' + EndOfLine);
                    LF;
                    IntraFile.Write(Text041 + DecimalZeroFormat(Segments, 5) + '+' + BKNR + EndOfLine);
                    LF;
                    IntraFile.Write(Text042 + BKNR + EndOfLine);
                    LF;
                    IntraFile.Close;

                    RecordsProcessed := RecordsProcessed + 1;
                    DiskStatus.Update(1, Round(RecordsProcessed / RecordsTotal * 10000, 1));
                end;

                trigger OnPreDataItem()
                begin
                    if not PrintShipment then
                        CurrReport.Break();

                    FilenameForShipments := CopyStr(CompanyInfo."Sales Authorized No.", 1, 4) +
                      "Intrastat Jnl. Batch"."Statistics Period" + '.edi';

                    ServerTempFileShipments := FileManagement.ServerTempFileName('tmp');
                    IntraFile.TextMode := false;
                    IntraFile.WriteMode := true;
                    IntraFile.Create(ServerTempFileShipments);
                    CurrentType := CurrentType::Shipment;

                    DiskStatus.Open(Text057 +
                      '@1@@@@@@@@@@@@@@@@@@@@@@@@@@@');
                    RecordsTotal := Count;

                    WeightTotal := 0;
                    ValueTotal := 0;
                    StatValueTotal := 0;
                    QuantityTotal := 0;
                    Segments := 0;
                    SupplementaryUnitsQtyTotal := 0;

                    IntraFile.Write(Text016 + EndOfLine);
                    LF;
                    IntraFile.Write(Text017 + UIDNo + Text018 + DateOfToday + ':' + TimeOfNow + '+' + BKNR + EndOfLine);
                    LF;
                    IntraFile.Write(Text019 + BKNR + Text020 + EndOfLine);
                    LF;
                    IntraFile.Write(Text021 + UIDNo + '-' + Period + BKNR + EndOfLine);
                    LF;
                    IntraFile.Write(Text022 + Period4 + ':610' + EndOfLine);
                    LF;
                    IntraFile.Write(Text023 + Today4 + ':102' + EndOfLine);
                    LF;
                    IntraFile.Write(Text024 + EndOfLine);
                    LF;
                    IntraFile.Write(
                      Text025 + UIDNo + '-000+' + RemoveSpecChar(CompanyInfo.Name) + ':' +
                      RemoveSpecChar(CompanyInfo."Name 2") + ':' +
                      RemoveSpecChar(CompanyInfo.Address) + ':' +
                      RemoveSpecChar(CompanyInfo."Post Code") + ' ' +
                      RemoveSpecChar(CompanyInfo.City) + ':' +
                      RemoveSpecChar(Contactperson) + EndOfLine);
                    LF;
                    IntraFile.Write(Text026 + RemoveSpecChar(CompanyInfo."Phone No.") + Text027 + EndOfLine);
                    LF;
                    IntraFile.Write(Text026 + RemoveSpecChar(CompanyInfo."Fax No.") + Text028 + EndOfLine);
                    LF;
                    IntraFile.Write(Text029 + EndOfLine);
                    LF;
                    IntraFile.Write(Text030 + EndOfLine);
                    LF;
                    IntraFile.Write(Text032 + EndOfLine);
                    LF;
                    PosNo := 0;

                    Clear(IntrastatJnlLine);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                TestField(Reported, false);
                IntraRefNo := "Statistics Period" + '000000';
                IntraJnlManagement.ChecklistClearBatchErrors("Intrastat Jnl. Batch");
            end;

            trigger OnPreDataItem()
            begin
                // Testflags
                "Intrastat Jnl. Batch".CopyFilter("Journal Template Name", IntraJnlLineTest."Journal Template Name");
                "Intrastat Jnl. Batch".CopyFilter(Name, IntraJnlLineTest."Journal Batch Name");

                IntraJnlLineTest.SetRange(Type, 0);
                if IntraJnlLineTest.Find('<>=') then
                    PrintReceipt := true
                else
                    PrintReceipt := false;

                IntraJnlLineTest.SetRange(Type, 1);
                if IntraJnlLineTest.Find('<>=') then
                    PrintShipment := true
                else
                    PrintShipment := false;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    group(Control1140000)
                    {
                        ShowCaption = false;
                        label(Control4)
                        {
                            ApplicationArea = Basic, Suite;
                            CaptionClass = Text19031129;
                            ShowCaption = false;
                        }
                        label(Control5)
                        {
                            ApplicationArea = Basic, Suite;
                            CaptionClass = Text19070121;
                            ShowCaption = false;
                        }
                        label(Control3)
                        {
                            ApplicationArea = Basic, Suite;
                            CaptionClass = Text19015047;
                            MultiLine = true;
                            ShowCaption = false;
                        }
                    }
                    field(Contactperson; Contactperson)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Contactperson';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPostReport()
    var
        DataCompression: Codeunit "Data Compression";
        ServerShipmentsTempBlob: Codeunit "Temp Blob";
        ServerReceiptsTempBlob: Codeunit "Temp Blob";
        ZipTempBlob: Codeunit "Temp Blob";
        ServerShipmentsInStream: InStream;
        ServerReceiptsInStream: InStream;
        ZipInStream: InStream;
        ZipOutStream: OutStream;
        ToFile: Text;
    begin
        if ServerPath = '' then
            case true of
                PrintReceipt and PrintShipment:
                    begin
                        DataCompression.CreateZipArchive;
                        FileManagement.BLOBImportFromServerFile(ServerShipmentsTempBlob, ServerTempFileShipments);
                        ServerShipmentsTempBlob.CreateInStream(ServerShipmentsInStream);
                        FileManagement.BLOBImportFromServerFile(ServerReceiptsTempBlob, ServerTempFileReceipts);
                        ServerReceiptsTempBlob.CreateInStream(ServerReceiptsInStream);
                        DataCompression.AddEntry(ServerReceiptsInStream, FilenameForReceipts);
                        DataCompression.AddEntry(ServerShipmentsInStream, FilenameForShipments);
                        ZipTempBlob.CreateOutStream(ZipOutStream);
                        DataCompression.SaveZipArchive(ZipOutStream);
                        DataCompression.CloseZipArchive();
                        ZipTempBlob.CreateInStream(ZipInStream);
                        ToFile := IntrastatTxt + Period + '.zip';
                        DownloadFromStream(ZipInStream, '', '', '', ToFile);
                    end;
                PrintReceipt:
                    FileManagement.DownloadHandler(ServerTempFileReceipts, '', '', FileExtensionTxt, FilenameForReceipts);
                PrintShipment:
                    FileManagement.DownloadHandler(ServerTempFileShipments, '', '', FileExtensionTxt, FilenameForShipments);
            end
        else begin
            if PrintReceipt then
                FileManagement.CopyServerFile(ServerTempFileReceipts, ServerPath + '\' + FilenameForReceipts, true);
            if PrintShipment then
                FileManagement.CopyServerFile(ServerTempFileShipments, ServerPath + '\' + FilenameForShipments, true);
        end;
    end;

    trigger OnPreReport()
    begin
        if ("Intrastat Jnl. Batch".GetFilter("Journal Template Name") = '') or ("Intrastat Jnl. Batch".GetFilter(Name) = '') then
            Error(SpecifyIntrastatJournalBatchErr);
        CompanyInfo.Get();
        CompanyInfo.TestField("VAT Registration No.");
        CompanyInfo.TestField("Sales Authorized No.");
        CompanyInfo.TestField("Purch. Authorized No.");
#if not CLEAN19
        if IntrastatSetup.Get() then;
#endif
    end;

    var
        Text000: Label '<Year,2><Month,2><Day,2>', Locked = true;
        Text001: Label '<Year4,4><Month,2><Day,2>', Locked = true;
        Text002: Label '<Hours24,2><Minutes,2>', Locked = true;
        Text003: Label 'UID in Companyinfo must be 11 digits.';
        Text004: Label 'Statisticperiod %1 may only include digits.';
        Text005: Label '<year,2><month,2>', Locked = true;
        InvalideDateErr: Label 'Date %1 of intrastat journal line %2 doesn''t fit with period %3 of Intrastat batch.', Comment = 'Parameter 1 - date, 2 - line number, 3 - date';
        Text008: Label 'Tariffno. in Line %1 must be 8 digits.';
        Text009: Label 'Transport Method must be one digit.';
        Text010: Label 'Transaction Type must be one digit.';
        Text011: Label 'Transaction Specification must be 5 digits.';
        FileExtensionTxt: Label 'EDI Files (*.edi)|*.edi';
        Text015: Label 'Number of Records Receipt processed\';
        Text016: Label 'UNA:+,? ';
        Text017: Label 'UNB+UNOC:3+';
        Text018: Label '-000+OESTAT::INTRASTAT+';
        Text019: Label 'UNH+';
        Text020: Label '+CUSDEC:D:97B:UN:INSTAT';
        Text021: Label 'BGM+896+';
        Text022: Label 'DTM+320:';
        Text023: Label 'DTM+137:';
        Text024: Label 'RFF+ACD:NAVATT::3.60.D.97B';
        Text025: Label 'NAD+DT+';
        Text026: Label 'COM+';
        Text027: Label ':TE';
        Text028: Label ':FX';
        Text029: Label 'NAD+DO+OESTAT';
        Text030: Label 'MOA+ZZZ::EUR';
        Text032: Label 'UNS+D';
        Text033: Label 'UNS+S';
        Text034: Label 'CNT+2:';
        Text035: Label 'CNT+18:';
        Text036: Label 'CNT+19:';
        Text037: Label 'CNT+20:';
        Text038: Label 'CNT+22:';
        Text039: Label 'AUT+';
        Text040: Label 'DTM+187:';
        Text041: Label 'UNT+';
        Text042: Label 'UNZ+1+';
        Text043: Label 'Countrycode %1 must be 2 digits.';
        Text044: Label 'Intrastatcode %1 must be 2 digits.';
        Text045: Label 'CST+';
        Text046: Label ':122+A:176+';
        Text047: Label 'FTX+AAA+++';
        Text048: Label 'LOC+35+';
        Text049: Label 'LOC+27+';
        Text050: Label 'MEA+WT++KGM:';
        Text051: Label 'MEA+AAE++PCE:';
        Text052: Label 'TDT+2++';
        Text053: Label 'MOA+38:';
        Text054: Label 'MOA+123:';
        Text057: Label 'Number of Records Shipment processed\';
        Text058: Label 'Intrastat Code %1 must be 2 digits.';
        Text059: Label ':122+D:176+';
        Text060: Label 'LOC+36+';
        Text062: Label 'You cannot display %1 in a field of length %2.';
        CompanyInfo: Record "Company Information";
        Country: Record "Country/Region";
        CountryOfOrg: Record "Country/Region";
        IntraJnlLineTest: Record "Intrastat Jnl. Line";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntrastatJnlLineBuf: Record "Intrastat Jnl. Line" temporary;
#if not CLEAN19
        IntrastatSetup: Record "Intrastat Setup";
#endif
        IntraJnlManagement: Codeunit IntraJnlManagement;
        FileManagement: Codeunit "File Management";
        DiskStatus: Dialog;
        IntraFile: File;
        ServerTempFileShipments: Text;
        ServerTempFileReceipts: Text;
        IntraRefNo: Text[10];
        AddField: Text[70];
        TempAddField: Text[70];
        TempType: Integer;
        UIDNo: Code[11];
        PrintReceipt: Boolean;
        PrintShipment: Boolean;
        Apostroph: Char;
        EndOfLine: Text[1];
        DateOfToday: Text[6];
        Today4: Text[8];
        TimeOfNow: Text[4];
        BKNR: Text[8];
        Period: Text[4];
        Period4: Text[6];
        PeriodYear: Integer;
        PosNo: Decimal;
        Segments: Integer;
        WeightTotal: Decimal;
        ValueTotal: Decimal;
        StatValueTotal: Decimal;
        QuantityTotal: Decimal;
        SupplementaryUnitsQtyTotal: Decimal;
        LinePeriod: Text[4];
        RecordsTotal: Integer;
        RecordsProcessed: Integer;
        Contactperson: Text[30];
        FilenameForShipments: Text;
        FilenameForReceipts: Text;
        ServerPath: Text;
        CurrentType: Option Receipt,Shipment;
        Text19031129: Label 'The filenames are created as follows:';
        Text19070121: Label 'Purch. Authorized No. + Statisticperiod + .EDI for Receipts';
        Text19015047: Label 'Sales Authorized No. + Statisticperiod + .EDI for Shipments';
        IntrastatTxt: Label 'Intrastat', Locked = true;
        SpecifyIntrastatJournalBatchErr: Label 'You must specify a template name and batch name for the Intrastat journal.';

    [Scope('OnPrem')]
    procedure DecimalZeroFormat(DecimalNumber: Decimal; Lenght: Integer): Text[250]
    begin
        exit(TextZeroFormat(DelChr(Format(Round(Abs(DecimalNumber), 1), 0, 1)), Lenght));
    end;

    [Scope('OnPrem')]
    procedure TextZeroFormat(Text: Text[250]; Length: Integer): Text[250]
    begin
        if StrLen(Text) > Length then
            Error(Text062,
              Text, Length);
        exit(PadStr('', Length - StrLen(Text), '0') + Text);
    end;

    [Scope('OnPrem')]
    procedure RemoveSpecChar(Text: Text[200]): Text[200]
    var
        DeleteChar: Text[30];
    begin
        DeleteChar := '":+? ' + Format(Apostroph, 1);
        exit(ConvertStr(DelChr(Text, '=', DeleteChar), ',', ' '));
    end;

    [Scope('OnPrem')]
    procedure LF()
    begin
        // reset Filepointer to avoid
        // senseless spaces
        IntraFile.Close;
        if CurrentType = CurrentType::Receipt then
            IntraFile.Open(ServerTempFileReceipts)
        else
            IntraFile.Open(ServerTempFileShipments);
        IntraFile.Seek(IntraFile.Len - 1);
        IntraFile.Trunc;
    end;

    [Scope('OnPrem')]
    procedure InitializeRequest(NewServerPath: Text)
    begin
        ServerPath := NewServerPath;
    end;

    local procedure IncSupplementaryUnitsQtyTotal(TariffNo: Code[20]; Qty: Decimal): Decimal
    var
        TariffNumber: Record "Tariff Number";
    begin
        TariffNumber.SetRange("Supplementary Units", true);
        if TariffNumber.FindSet then
            repeat
                if DelChr(TariffNumber."No.") = TariffNo then
                    exit(Abs(Qty));
            until TariffNumber.Next = 0;
    end;
}

