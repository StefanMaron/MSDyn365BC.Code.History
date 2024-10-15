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

                trigger OnAfterGetRecord()
                begin
                    TestField("Transaction Type");
                    if IntraJnlLineType = 0 then
                        "Intrastat Jnl. Batch".TestField("Reported Receipt", false)
                    else
                        if IntraJnlLineType = 1 then
                            "Intrastat Jnl. Batch".TestField("Reported Shipment", false);

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

                trigger OnPreDataItem()
                begin
                    "Intrastat Jnl. Line".SetRange(Type, IntraJnlLineType);
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
                    QuantityAmt += "Quantity 2";
                    StatisticalValueAmt += "Statistical Value";
                    GrTotalAmt += Amount;

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
                        GrTotalAmt := 0;
                    end;
                end;

                trigger OnPostDataItem()
                begin
                    IntraFile.Write(
                      Format(
                      'SUM' + TextZeroFormat(CopyStr("Internal Ref. No.", 8, 3), 18) +
                      DecimalNumeralZeroFormat(Round(TotalAmount, 1, '>'), 18), 39));

                    IntraFile.Close;

                    if IntraJnlLineType = 0 then begin
                        "Intrastat Jnl. Batch"."Reported Receipt" := true;
                        "Intrastat Jnl. Batch".Modify();
                        IntraSetup.Modify();
                    end
                    else
                        if IntraJnlLineType = 1 then begin
                            "Intrastat Jnl. Batch"."Reported Shipment" := true;
                            "Intrastat Jnl. Batch".Modify();
                            IntraSetup.Modify();
                        end;

                    if ServerFileName = '' then
                        FileMgt.DownloadHandler(FileName, '', '', FileMgt.GetToFilterText('', DefaultFilenameTxt), DefaultFilenameTxt)
                    else
                        FileMgt.CopyServerFile(FileName, ServerFileName, true);
                end;

                trigger OnPreDataItem()
                begin
                    IntrastatJnlLine2.SetRange(Type, IntraJnlLineType);
                    CompanyInfo.Get();
                    if not IntraSetup.Get then
                        Error(MissingFileSetupConfigErr);

                    BusinessIdCode := CompanyInfo."Business Identity Code";
                    CompanyCode := IntraSetup."Company Serial No.";
                    FileNo := IntraSetup."File No.";
                    StatPeriod := "Intrastat Jnl. Batch"."Statistics Period";
                    StatCustChamber := IntraSetup."Custom Code";
                    LinePos := StrPos(BusinessIdCode, '-');
                    LineNo := '00000';

                    if "Intrastat Jnl. Line".Type = 0 then
                        FileType := 'A'
                    else
                        FileType := 'D';

                    if LinePos <> 0 then
                        BusinessIdCode := DelStr(BusinessIdCode, LinePos, 1);

                    if IntraSetup."Last Transfer Date" = Today then
                        IntraSetup."File No." := IncStr(IntraSetup."File No.")
                    else begin
                        IntraSetup."Last Transfer Date" := Today;
                        IntraSetup."File No." := '001';
                    end;

                    IntraFile.Write(Format('KON0037' + Format(BusinessIdCode, 8), 20));

                    Evaluate(TmpDate, '0101' + Format(Today, 0, '<Year,2>'));
                    IntraFile.Write(Format('OTS' + Format(Today, 0, '<Year,2>') + StatCustChamber +
                                    TextZeroFormat(Format(Today - TmpDate + 1), 3) + CompanyCode +
                                    IntraSetup."File No." + FileType + StatPeriod + 'T  ' + '             ' +
                                    'FI' + BusinessIdCode + '       ' + '                           ' + StatCustChamber +
                                    '               ' + 'EUR', 101));

                    SetRange("Internal Ref. No.", CopyStr(IntraReferenceNo, 1, 4), CopyStr(IntraReferenceNo, 1, 4) + '9');

                    IntrastatJnlLine3.SetCurrentKey("Internal Ref. No.");
                end;
            }

            trigger OnAfterGetRecord()
            begin
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
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(IntrastatJnlLineType; IntraJnlLineType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Intrastat Journal Line Type';
                        OptionCaption = 'Receipt,Shipment';
                    }
                }
            }
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
        IntraSetup: Record "Intrastat - File Setup";
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
        BusinessIdCode: Code[20];
        ImportExport: Code[1];
        OK: Boolean;
        DefaultFilenameTxt: Label 'Default.txt', Locked = true;
        GroupTotal: Boolean;
        LinePos: Integer;
        TmpDate: Date;
        CompanyCode: Code[3];
        FileNo: Code[3];
        StatPeriod: Code[4];
        StatCustChamber: Text[17];
        CountryFormat: Text[6];
        Quantity2Code: Text[3];
        TotalAmount: Decimal;
        GrTotalAmt: Decimal;
        FileType: Text[1];
        Text1090000: Label 'must be either Receipt or Shipment';
        IntraJnlLineType: Option Receipt,Shipment;
        LineNo: Text[5];
        InternalReference: Text[15];
        MissingFileSetupConfigErr: Label 'You have not set up any Intrastat transfer files. To set up a transfer file, go to the Transfer File window.';

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

    procedure InitializeRequest(newServerFileName: Text; newIntraJnlLineType: Option)
    begin
        ServerFileName := newServerFileName;
        IntraJnlLineType := newIntraJnlLineType;
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

            if "Quantity 2" <> 0 then begin
                Quantity2Code := 'AAE';
                TestField("Unit of Measure");
            end
            else begin
                Quantity2Code := '';
                "Unit of Measure" := '';
            end;
            if Type = Type::Receipt then begin
                Receipt := true;
                CountryFormat := Format("Country/Region of Origin Code", 2) + Format("Country/Region Code", 2) + '  ';
            end
            else begin
                Shipment := true;
                CountryFormat := '    ' + Format("Country/Region Code", 2)
            end;
            LineNo := IncStr(LineNo);
            InternalReference := Format("Internal Ref. No.", 15);
            IntraFile.Write(
              Format('NIM' + LineNo +
              PadStr("Tariff No.", 8, '0') + Format("Transaction Type", 2) +
              CountryFormat + Format("Transport Method", 1) +
              DecimalNumeralZeroFormat(Round(StatisticalValueAmt, 1, '>'), 10) +
              InternalReference + 'WT ' + 'KGM' +
              DecimalNumeralZeroFormat(Round(TotalWeightAmt, 1, '>'), 10) +
              Format(Quantity2Code, 3) + Format("Unit of Measure", 3) +
              DecimalNumeralZeroFormat(Round(QuantityAmt, 1, '>'), 10) +
              DecimalNumeralZeroFormat(Round(GrTotalAmt, 1, '>'), 10), 92));

            TotalAmount := TotalAmount + GrTotalAmt;
        end;
    end;
}

