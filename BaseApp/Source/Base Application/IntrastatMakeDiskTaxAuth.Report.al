report 593 "Intrastat - Make Disk Tax Auth"
{
    Caption = 'Intrastat - Make Disk Tax Auth';
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
                DataItemTableView = SORTING(Type, "Country/Region Code", "Tariff No.", "Transaction Type", "Transport Method");
                RequestFilterFields = Type;

                trigger OnAfterGetRecord()
                begin
                    if ("Tariff No." = '') and
                       ("Country/Region Code" = '') and
                       ("Transaction Type" = '') and
                       ("Transport Method" = '') and
                       ("Total Weight" = 0)
                    then
                        CurrReport.Skip();

                    TestField("Tariff No.");
                    TestField("Country/Region Code");
                    TestField("Transaction Type");
                    TestField("Total Weight");
                    if "Supplementary Units" then
                        TestField(Quantity);
                    CompoundField :=
                      Format("Country/Region Code", 10) + Format(DelChr("Tariff No."), 10) +
                      Format("Transaction Type", 10) + Format("Transport Method", 10);

                    if (TempType <> Type) or (StrLen(TempCompoundField) = 0) then begin
                        TempType := Type;
                        TempCompoundField := CompoundField;
                        IntraReferenceNo := CopyStr(IntraReferenceNo, 1, 4) + Format(Type, 1, 2) + '01001';
                    end else
                        if TempCompoundField <> CompoundField then begin
                            TempCompoundField := CompoundField;
                            if CopyStr(IntraReferenceNo, 8, 3) = '999' then
                                IntraReferenceNo := IncStr(CopyStr(IntraReferenceNo, 1, 7)) + '001'
                            else
                                IntraReferenceNo := IncStr(IntraReferenceNo);
                        end;

                    "Internal Ref. No." := IntraReferenceNo;
                    Modify;
                end;
            }
            dataitem(IntrastatJnlLine2; "Intrastat Jnl. Line")
            {
                DataItemTableView = SORTING("Internal Ref. No.");

                trigger OnAfterGetRecord()
                begin
                    if ("Tariff No." = '') and
                       ("Country/Region Code" = '') and
                       ("Transaction Type" = '') and
                       ("Transport Method" = '') and
                       ("Total Weight" = 0)
                    then
                        CurrReport.Skip();
                    "Tariff No." := DelChr("Tariff No.");

                    TotalWeightAmt += "Total Weight";
                    QuantityAmt += Quantity;
                    StatisticalValueAmt += "Statistical Value";

                    IntrastatJnlLine5.Copy(IntrastatJnlLine2);
                    if IntrastatJnlLine5.Next = 1 then begin
                        if (DelChr(IntrastatJnlLine5."Tariff No.") = "Tariff No.") and
                           (IntrastatJnlLine5."Country/Region Code" = "Country/Region Code") and
                           (IntrastatJnlLine5."Transaction Type" = "Transaction Type") and
                           (IntrastatJnlLine5."Transport Method" = "Transport Method")
                        then
                            GroupTotal := false
                        else
                            GroupTotal := true;
                    end else
                        GroupTotal := true;

                    if GroupTotal then begin
                        WriteGrTotalsToFile(TotalWeightAmt, QuantityAmt, StatisticalValueAmt);
                        StatisticalValueTotalAmt += StatisticalValueAmt;
                        TotalWeightAmt := 0;
                        QuantityAmt := 0;
                        StatisticalValueAmt := 0;
                    end;
                end;

                trigger OnPostDataItem()
                begin
                    if not Receipt then
                        IntraFile.Write(
                          Format(
                            '02000' + Format(IntraReferenceNo, 4) + '100000' +
                            Format(VATRegNo, 8) + '1' + Format(IntraReferenceNo, 4),
                            80));
                    if not Shipment then
                        IntraFile.Write(
                          Format(
                            '02000' + Format(IntraReferenceNo, 4) + '200000' +
                            Format(VATRegNo, 8) + '2' + Format(IntraReferenceNo, 4),
                            80));
                    IntraFile.Write(Format('10' + DecimalNumeralZeroFormat(StatisticalValueTotalAmt, 16), 80));
                    IntraFile.Close;

                    "Intrastat Jnl. Batch".Reported := true;
                    "Intrastat Jnl. Batch".Modify();

                    if ServerFileName = '' then
                        FileMgt.DownloadHandler(FileName, '', '', FileMgt.GetToFilterText('', DefaultFilenameTxt), DefaultFilenameTxt)
                    else
                        FileMgt.CopyServerFile(FileName, ServerFileName, true);
                end;

                trigger OnPreDataItem()
                begin
                    CompanyInfo.Get();
                    VATRegNo := ConvertStr(CompanyInfo."VAT Registration No.", Text001, '    ');
                    IntraFile.Write(Format('00' + Format(VATRegNo, 8) + Text002, 80));
                    IntraFile.Write(Format('0100004', 80));

                    SetRange("Internal Ref. No.", CopyStr(IntraReferenceNo, 1, 4), CopyStr(IntraReferenceNo, 1, 4) + '9');

                    IntrastatJnlLine3.SetCurrentKey("Internal Ref. No.");
                end;
            }

            trigger OnAfterGetRecord()
            begin
                TestField(Reported, false);
                IntraReferenceNo := "Statistics Period" + '000000';
            end;

            trigger OnPreDataItem()
            begin
                IntrastatJnlLine4.CopyFilter("Journal Template Name", "Journal Template Name");
                IntrastatJnlLine4.CopyFilter("Journal Batch Name", Name);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
        }

        actions
        {
        }

        trigger OnOpenPage()
        var
            IntrastatSetup: Record "Intrastat Setup";
        begin
            if not IntrastatSetup.Get then
                exit;

            if IntrastatSetup."Report Receipts" and IntrastatSetup."Report Shipments" then
                exit;

            if IntrastatSetup."Report Receipts" then
                "Intrastat Jnl. Line".SetRange(Type, "Intrastat Jnl. Line".Type::Receipt)
            else
                if IntrastatSetup."Report Shipments" then
                    "Intrastat Jnl. Line".SetRange(Type, "Intrastat Jnl. Line".Type::Shipment)
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        FileName := FileMgt.ServerTempFileName('');

        IntrastatJnlLine4.CopyFilters("Intrastat Jnl. Line");
        if FileName = '' then
            Error(Text000);
        IntraFile.TextMode := true;
        IntraFile.WriteMode := true;
        IntraFile.Create(FileName);
    end;

    var
        Text000: Label 'Enter the file name.';
        Text001: Label 'WwWw';
        Text002: Label 'INTRASTAT';
        Text003: Label 'It is not possible to display %1 in a field with a length of %2.';
        IntrastatJnlLine3: Record "Intrastat Jnl. Line";
        IntrastatJnlLine4: Record "Intrastat Jnl. Line";
        IntrastatJnlLine5: Record "Intrastat Jnl. Line";
        CompanyInfo: Record "Company Information";
        Country: Record "Country/Region";
        FileMgt: Codeunit "File Management";
        IntraFile: File;
        QuantityAmt: Decimal;
        StatisticalValueAmt: Decimal;
        StatisticalValueTotalAmt: Decimal;
        TotalWeightAmt: Decimal;
        FileName: Text;
        IntraReferenceNo: Text[10];
        CompoundField: Text[40];
        TempCompoundField: Text[40];
        ServerFileName: Text;
        TempType: Integer;
        NoOfEntries: Text[3];
        Receipt: Boolean;
        Shipment: Boolean;
        VATRegNo: Code[20];
        ImportExport: Code[1];
        OK: Boolean;
        DefaultFilenameTxt: Label 'Default.txt', Locked = true;
        GroupTotal: Boolean;

    local procedure DecimalNumeralZeroFormat(DecimalNumeral: Decimal; Length: Integer): Text[250]
    begin
        exit(TextZeroFormat(DelChr(Format(Round(Abs(DecimalNumeral), 1, '<'), 0, 1)), Length));
    end;

    local procedure TextZeroFormat(Text: Text[250]; Length: Integer): Text[250]
    begin
        if StrLen(Text) > Length then
            Error(
              Text003,
              Text, Length);
        exit(PadStr('', Length - StrLen(Text), '0') + Text);
    end;

    procedure InitializeRequest(newServerFileName: Text)
    begin
        ServerFileName := newServerFileName;
    end;

    [Scope('OnPrem')]
    procedure WriteGrTotalsToFile(TotalWeightAmt: Decimal; QuantityAmt: Decimal; StatisticalValueAmt: Decimal)
    begin
        with IntrastatJnlLine2 do begin
            OK := CopyStr("Internal Ref. No.", 8, 3) = '001';
            if OK then begin
                IntrastatJnlLine3.SetRange(
                  "Internal Ref. No.",
                  CopyStr("Internal Ref. No.", 1, 7) + '000',
                  CopyStr("Internal Ref. No.", 1, 7) + '999');
                IntrastatJnlLine3.FindLast;
                NoOfEntries := CopyStr(IntrastatJnlLine3."Internal Ref. No.", 8, 3);
            end;
            ImportExport := IncStr(Format(Type, 1, 2));

            if Type = Type::Receipt then
                Receipt := true
            else
                Shipment := true;
            Country.Get("Country/Region Code");
            Country.TestField("Intrastat Code");

            if OK then
                IntraFile.Write(
                  Format(
                    '02' +
                    TextZeroFormat(DelChr(NoOfEntries), 3) +
                    Format(CopyStr(IntrastatJnlLine3."Internal Ref. No.", 1, 7) + '000', 10) +
                    Format(VATRegNo, 8) + Format(ImportExport, 1) + Format(IntraReferenceNo, 4),
                    80));

            IntraFile.Write(
              Format(
                '03' +
                TextZeroFormat(CopyStr("Internal Ref. No.", 8, 3), 3) +
                Format("Internal Ref. No.", 10) + Format(Country."Intrastat Code", 3) + Format("Transaction Type", 2) +
                '0' + Format("Transport Method", 1) + PadStr("Tariff No.", 9, '0') +
                DecimalNumeralZeroFormat(Round(TotalWeightAmt, 1, '>'), 15) +
                DecimalNumeralZeroFormat(QuantityAmt, 10) +
                DecimalNumeralZeroFormat(StatisticalValueAmt, 15),
                80));
        end;
    end;
}

