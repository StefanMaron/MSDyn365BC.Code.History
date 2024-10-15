#if not CLEAN22
report 593 "Intrastat - Make Disk Tax Auth"
{
    Caption = 'Intrastat - Make Diskette';
    ProcessingOnly = true;
    ObsoleteState = Pending;
    ObsoleteTag = '22.0';
    ObsoleteReason = 'Intrastat related functionalities are moved to Intrastat extensions.';

    dataset
    {
        dataitem("Intrastat Jnl. Batch"; "Intrastat Jnl. Batch")
        {
            DataItemTableView = SORTING("File Disk No.");
            RequestFilterFields = "Journal Template Name", Name;
            dataitem(IntrastatJnlLine; "Intrastat Jnl. Line")
            {
                DataItemLink = "Journal Template Name" = FIELD("Journal Template Name"), "Journal Batch Name" = FIELD(Name);
                DataItemLinkReference = "Intrastat Jnl. Batch";
                DataItemTableView = SORTING(Type, "Country/Region Code", "Partner VAT ID", "Transaction Type", "Tariff No.", "Group Code", "Transport Method", "Transaction Specification", "Country/Region of Origin Code", Area, "Corrective entry") ORDER(Ascending);
                trigger OnAfterGetRecord()
                var
                    EU3PartyTrade: Boolean;
                begin
                    TotalLines := TotalLines + 1;
                    CheckLine(IntrastatJnlLine);

                    if not "Intrastat Jnl. Batch"."Corrective Entry" then
                        TestField(Amount);

                    if "Intrastat Jnl. Batch"."EU Service" then begin
                        TestField("Document No.");
                        TestField(Date);
                        TestField("Service Tariff No.");
                        if not SkipTransportMethodVerification(IntrastatJnlLine) then
                            TestField("Transport Method");
                        if "Intrastat Jnl. Batch"."Corrective Entry" then begin
                            TestField("Custom Office No.");
                            TestField("Progressive No.");
                            CheckCorrectiveStatPeriod(IntrastatJnlLine, "Intrastat Jnl. Batch"."Statistics Period");
                        end;
                        "Intra - form Buffer".TransferFields(IntrastatJnlLine);
                        "Intra - form Buffer"."User ID" := UserId;
                        "Intra - form Buffer"."No." := "Intra - form Buffer"."No." + TotalLines;
                        "Intra - form Buffer"."Progressive No." := "Progressive No.";
                        "Intra - form Buffer"."VAT Registration No." :=
                            CopyStr("Partner VAT ID", 1, MaxStrLen("Intra - form Buffer"."VAT Registration No."));
                        "Intra - form Buffer".Insert();
                        TotalAmount += Round(Amount, 1);
                        TotalRecords += 1;
                    end else begin
                        TestField("Transaction Type");
                        TestField("Tariff No.");
                        TestField("Total Weight");
                        if not "Intrastat Jnl. Batch"."Corrective Entry" then begin
                            if ("Tariff No." = '') and
                               ("Country/Region Code" = '') and
                               ("Transaction Type" = '') and
                               ("Transport Method" = '') and
                               ("Total Weight" = 0)
                            then
                                CurrReport.Skip();
                            if "Intrastat Jnl. Batch".Periodicity = "Intrastat Jnl. Batch".Periodicity::Month then begin
                                TestField("Transaction Specification");
                                TestField(Area);
                                if "Intrastat Jnl. Batch".Type = "Intrastat Jnl. Batch".Type::Purchases then
                                    TestField("Country/Region of Origin Code");
                            end;
                            if "Supplementary Units" then
                                TestField(Quantity);
                            if not "Supplementary Units" then
                                SupplUnits := 0
                            else
                                SupplUnits := IntrastatJnlLine.Quantity;

                            EU3PartyTrade := IsEU3PartyTrade(IntrastatJnlLine);
                            "Intra - form Buffer".Reset();
                            if "Intra - form Buffer".Get("Partner VAT ID",
                                 IntrastatJnlLine."Transaction Type", IntrastatJnlLine."Tariff No.",
                                 IntrastatJnlLine."Group Code", IntrastatJnlLine."Transport Method",
                                 IntrastatJnlLine."Transaction Specification", "Country/Region of Origin Code",
                                 IntrastatJnlLine.Area, IntrastatJnlLine."Corrective entry", EU3PartyTrade)
                            then begin
                                TotalAmount -= Round("Intra - form Buffer".Amount, 1);
                                "Intra - form Buffer".Amount += Amount;
                                "Intra - form Buffer"."Source Currency Amount" := "Intra - form Buffer"."Source Currency Amount" +
                                    IntrastatJnlLine."Source Currency Amount";
                                "Intra - form Buffer"."Total Weight" := "Intra - form Buffer"."Total Weight" + IntrastatJnlLine."Total Weight";
                                "Intra - form Buffer"."Statistical Value" += "Statistical Value";
                                "Intra - form Buffer".Quantity := "Intra - form Buffer".Quantity + SupplUnits;
                                "Intra - form Buffer".Modify();
                                TotalAmount += Round("Intra - form Buffer".Amount, 1);
                            end else begin
                                "Intra - form Buffer".TransferFields(IntrastatJnlLine);
                                "Intra - form Buffer"."Country/Region of Origin Code" := "Country/Region of Origin Code";
                                "Intra - form Buffer".Quantity := SupplUnits;
                                "Intra - form Buffer"."User ID" := UserId;
                                "Intra - form Buffer"."No." := 0;
                                "Intra - form Buffer"."EU 3-Party Trade" := EU3PartyTrade;
                                "Intra - form Buffer"."VAT Registration No." :=
                                    CopyStr("Partner VAT ID", 1, MaxStrLen("Intra - form Buffer"."VAT Registration No."));
                                "Intra - form Buffer".Insert();
                                TotalAmount += Round(Amount, 1);
                                TotalRecords += 1;
                            end;
                        end else begin          // Corrective Entry
                            if StrLen("Reference Period") <> 4 then
                                Error(Text1130002, FieldCaption("Reference Period"));
                            Evaluate(MonthRP, CopyStr("Reference Period", 3, 2));
                            if (MonthRP < 1) or (MonthRP > 12) then
                                Error(Text1130003, FieldCaption("Reference Period"));
                            if "Reference Period" >= "Intrastat Jnl. Batch"."Statistics Period" then
                                Error(Text1130004, FieldCaption("Statistics Period"));
                            TestField("Reference Period");
                            TestField("Group Code");
                            TestField(Area);
                            TestField("Transport Method");
                            TestField("Transaction Specification");
                            CheckCorrectiveStatPeriod(IntrastatJnlLine, "Intrastat Jnl. Batch"."Statistics Period");
                            "Intra - form Buffer".TransferFields(IntrastatJnlLine);
                            "Intra - form Buffer"."User ID" := UserId;
                            "Intra - form Buffer".Insert();
                            TotalAmount += Round(Amount, 1);
                            TotalRecords += 1;
                            OldReferencePeriod := "Reference Period";
                        end
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    TotalAmount := 0;
                end;

                trigger OnPostDataItem()
                begin
                    IntraJnlManagement.CheckForJournalBatchError(IntrastatJnlLine, true);
                end;
            }
            dataitem("Intra - form Buffer"; "Intra - form Buffer")
            {
                DataItemLink = "Journal Template Name" = FIELD("Journal Template Name"), "Journal Batch Name" = FIELD(Name);
                DataItemLinkReference = "Intrastat Jnl. Batch";
                DataItemTableView = SORTING("VAT Registration No.", "Transaction Type", "Tariff No.", "Group Code", "Transport Method", "Transaction Specification", "Country/Region of Origin Code", Area, "Corrective entry") ORDER(Ascending);

                trigger OnAfterGetRecord()
                begin
                    NoOfRecords := NoOfRecords + 1;
                    LineNo := LineNo + 1;
                    RoundAmount := Format(Abs(Amount));
                    RoundStatValue := Format(Abs("Statistical Value"));
                    RoundCurrAmount := Format(Abs(Round("Source Currency Amount", 1)));
                    RoundTotalWeight := Format(Abs(IntraJnlManagement.RoundTotalWeight("Total Weight")));
                    if "Supplementary Units" then
                        RoundQty := Format(Abs(Round(Quantity, 1)))
                    else
                        RoundQty := Format('0');

                    if not (StrPos(RoundAmount, '.') = 0) then
                        RoundAmount := DelChr(RoundAmount, '=', '.');
                    if not (StrPos(RoundStatValue, '.') = 0) then
                        RoundStatValue := DelChr(RoundStatValue, '=', '.');
                    if not (StrPos(RoundCurrAmount, '.') = 0) then
                        RoundCurrAmount := DelChr(RoundCurrAmount, '=', '.');
                    if not (StrPos(RoundQty, '.') = 0) then
                        RoundQty := DelChr(RoundQty, '=', '.');
                    if not (StrPos(RoundTotalWeight, '.') = 0) then
                        RoundTotalWeight := DelChr(RoundTotalWeight, '=', '.');

                    IntrastatJnlLine.SetRange("Document No.", "Document No.");
                    IntrastatJnlLine.FindFirst();
                    WriteRecord();
                    IntrastatJnlLine.SetRange("Document No.");
                end;

                trigger OnPostDataItem()
                begin
                    IntrastatJnlLine.ModifyAll("Statistics Period", "Intrastat Jnl. Batch"."Statistics Period");
                    IntrastatFileWriter.AddCurrFileToResultFile();
                end;

                trigger OnPreDataItem()
                begin
                    IntrastatFileWriter.InitializeNextFile(DefaultFilenameTxt);
                    IntrastatFileWriter.WriteLine(GetRecordTypeZero());
                end;
            }

            trigger OnAfterGetRecord()
            begin
                TotalRecords := 0;
                LineNo := 0;
                TestField("Statistics Period");
                TestField("File Disk No.");
                IntraJnlManagement.ChecklistClearBatchErrors("Intrastat Jnl. Batch");
                SetBatchIsExported("Intrastat Jnl. Batch");
                IntrastatFileWriter.SetStatisticsPeriod("Statistics Period");
            end;

            trigger OnPostDataItem()
            begin
                Message(Text1130000 + Text1130001, NoOfRecords);
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
        begin
            FilterSourceLinesByIntrastatSetupExportTypes();
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        IntrastatFileWriter.Initialize(false, false, 0);

        CompanyInfo.Get();
        CompanyInfo."VAT Registration No." := ConvertStr(CompanyInfo."VAT Registration No.", Text001, '    ');
        CompanyInfo.TestField("VAT Registration No.");
        "Intra - form Buffer".Reset();
        "Intra - form Buffer".SetFilter("User ID", UserId);
        "Intra - form Buffer".DeleteAll();
    end;

    trigger OnPostReport()
    begin
        "Intra - form Buffer".Reset();
        "Intra - form Buffer".SetFilter("User ID", UserId);
        "Intra - form Buffer".DeleteAll();
        IntrastatFileWriter.CloseAndDownloadResultFile();
    end;

    var
        CompanyInfo: Record "Company Information";
        IntrastatSetup: Record "Intrastat Setup";
        IntraJnlManagement: Codeunit IntraJnlManagement;
        IntrastatFileWriter: Codeunit "Intrastat File Writer";
        SupplUnits: Decimal;
        RoundCurrAmount: Text[30];
        RoundTotalWeight: Text[30];
        RoundQty: Text[30];
        RoundStatValue: Text[30];
        RoundAmount: Text[30];
        OldReferencePeriod: Code[10];
        MonthRP: Integer;
        NoOfRecords: Integer;
        TotalAmount: Decimal;
        TotalRecords: Integer;
        LineNo: Integer;
        TotalLines: Integer;

        Text001: Label 'WwWw';
        DefaultFilenameTxt: Label 'scambi.cee', Locked = true;
        Text1130000: Label 'File was created successfully.\';
        Text1130001: Label 'Records created:  %1';
        Text1130002: Label '%1 must be 4 characters, for example, 9410 for October, 1994.';
        Text1130003: Label 'Please check the month number in field %1';
        Text1130004: Label 'Reference Period must be previous later %1';

    local procedure FilterSourceLinesByIntrastatSetupExportTypes()
    begin
        if not IntrastatSetup.Get() then
            exit;

        if IntrastatJnlLine.GetFilter(Type) <> '' then
            exit;

        if IntrastatSetup."Report Receipts" and IntrastatSetup."Report Shipments" then
            exit;

        if IntrastatSetup."Report Receipts" then
            IntrastatJnlLine.SetRange(Type, IntrastatJnlLine.Type::Receipt)
        else
            if IntrastatSetup."Report Shipments" then
                IntrastatJnlLine.SetRange(Type, IntrastatJnlLine.Type::Shipment)
    end;

    local procedure CheckLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line")
    begin
        IntraJnlManagement.ValidateReportWithAdvancedChecklist(IntrastatJnlLine, Report::"Intrastat - Make Disk Tax Auth", false);
    end;

    local procedure SetBatchIsExported(var IntrastatJnlBatch: Record "Intrastat Jnl. Batch")
    begin
        IntrastatJnlBatch.Validate(Reported, true);
        IntrastatJnlBatch.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure WriteRecord()
    begin
        if not "Intrastat Jnl. Batch"."EU Service" then begin
            if not "Intrastat Jnl. Batch"."Corrective Entry" then
                IntrastatFileWriter.WriteLine(GetRecordTypeOne())
            else
                IntrastatFileWriter.WriteLine(GetRecordTypeTwo());
        end else begin
            if not "Intrastat Jnl. Batch"."Corrective Entry" then
                IntrastatFileWriter.WriteLine(GetRecordTypeThree())
            else
                IntrastatFileWriter.WriteLine(GetRecordTypeFour());
        end;
    end;

    [Scope('OnPrem')]
    procedure GetFixedPart(RecordType: Option "0","1","2","3","4"): Text[28]
    var
        TotalRec: Integer;
        OutText: Text[28];
        Vendor: Record Vendor;
    begin
        if RecordType = 0 then
            TotalRec := 0
        else
            TotalRec := LineNo;
        OutText := Format('EUROX');
        CompanyInfo.Get();
        if (CompanyInfo."Tax Representative No." <> '') and Vendor.Get(CompanyInfo."Tax Representative No.") and
           (Vendor."VAT Registration No." <> '')
        then
            OutText += FormatNum(RemoveLeadingCountryCode(Vendor."VAT Registration No.", CompanyInfo."Country/Region Code"), 11)
        else
            OutText += FormatNum(RemoveLeadingCountryCode(CompanyInfo."VAT Registration No.", CompanyInfo."Country/Region Code"), 11);
        OutText += FormatNum(GetNumericVal("Intrastat Jnl. Batch"."File Disk No."), 6);
        OutText += Format(RecordType);
        OutText += FormatNum(Format(TotalRec), 5);
        exit(OutText);
    end;

    [Scope('OnPrem')]
    procedure FormatNum(CodeField: Code[54]; Len: Integer): Code[54]
    begin
        exit(Format(CodeField, Len, StrSubstNo('<Text,%1><Filler Character,0>', Len)))
    end;

    [Scope('OnPrem')]
    procedure FormatAlphaNum(CodeField: Code[20]; Len: Integer): Text[20]
    begin
        exit(PadStr(CodeField, Len, ' '))
    end;

    [Scope('OnPrem')]
    procedure GetNumericVal(FullText: Code[20]): Code[20]
    var
        Position: Integer;
        Character: Code[1];
        Number: Code[20];
    begin
        repeat
            Position := Position + 1;
            Character := CopyStr(FullText, Position, 1);
            if Character in ['0' .. '9'] then
                Number := Number + CopyStr(FullText, Position, 1)
        until Position >= StrLen(FullText);
        exit(Number)
    end;

    [Scope('OnPrem')]
    procedure GetRecordTypeZero(): Text
    var
        Vendor: Record Vendor;
        OutText: Text;
    begin
        OutText += GetFixedPart(0);
        if "Intrastat Jnl. Batch".Type = "Intrastat Jnl. Batch".Type::Sales then
            OutText += 'C'
        else
            OutText += 'A';
        OutText += FormatNum("Intrastat Jnl. Batch"."Statistics Period", 2);
        if "Intrastat Jnl. Batch".Periodicity = "Intrastat Jnl. Batch".Periodicity::Month then
            OutText += 'M'
        else
            if "Intrastat Jnl. Batch".Periodicity = "Intrastat Jnl. Batch".Periodicity::Quarter then
                OutText += 'T';
        OutText += FormatNum(CopyStr("Intrastat Jnl. Batch"."Statistics Period", 3, 4), 2);
        OutText += FormatNum(RemoveLeadingCountryCode(CompanyInfo."VAT Registration No.", CompanyInfo."Country/Region Code"), 11);
        OutText += '00';
        if Vendor.Get(CompanyInfo."Tax Representative No.") then;
        OutText += FormatNum(RemoveLeadingCountryCode(Vendor."VAT Registration No.", Vendor."Country/Region Code"), 11);
        OutText += GetTotals();
        exit(OutText);
    end;

    [Scope('OnPrem')]
    procedure GetRecordTypeOne(): Text
    var
        OutText: Text;
    begin
        OutText += GetFixedPart(1);
        OutText += GetCountryCodeVATRegNo();
        OutText += GetAmounts();
        OutText += GetTransTypeTariffNo();
        if "Intrastat Jnl. Batch".Periodicity = "Intrastat Jnl. Batch".Periodicity::Month then
            if not "Intra - form Buffer"."EU 3-Party Trade" then begin
                OutText += FormatNum(RoundTotalWeight, 10);
                OutText += FormatNum(RoundQty, 10);
                OutText += GetStatValue();
                OutText += FormatAlphaNum("Intra - form Buffer"."Group Code", 1);
                OutText += FormatNum(GetNumericVal("Intra - form Buffer"."Transport Method"), 1);
                OutText += FormatAlphaNum("Intra - form Buffer"."Transaction Specification", 2);
                if "Intrastat Jnl. Batch".Type = "Intrastat Jnl. Batch".Type::Purchases then
                    OutText += FormatAlphaNum("Intra - form Buffer"."Country/Region of Origin Code", 2);
                OutText += FormatAlphaNum("Intra - form Buffer".Area, 2);
                OutText += FormatAlphaNum(CopyStr("Intra - form Buffer"."Transaction Type", 2, 1), 1);
                if "Intrastat Jnl. Batch".Type = "Intrastat Jnl. Batch".Type::Sales then
                    OutText += FormatAlphaNum("Intra - form Buffer"."Country/Region of Origin Code", 2);
            end else begin
                OutText += FormatNum('', 10);
                OutText += FormatNum('', 10);
                OutText += FormatNum('', 13);
                OutText += FormatAlphaNum('', 1);
                OutText += FormatNum('', 1);
                OutText += FormatAlphaNum('', 2);
                if "Intrastat Jnl. Batch".Type = "Intrastat Jnl. Batch".Type::Purchases then
                    OutText += FormatAlphaNum('', 2);
                OutText += FormatAlphaNum('', 2);
                OutText += FormatAlphaNum('', 1);
                if "Intrastat Jnl. Batch".Type = "Intrastat Jnl. Batch".Type::Sales then
                    OutText += FormatAlphaNum('', 2);
            end;
        exit(OutText);
    end;

    [Scope('OnPrem')]
    procedure GetRecordTypeTwo(): Text[97]
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        OutText: Text[97];
    begin
        OutText += GetFixedPart(2);
        if IntrastatJnlBatch.Get(
             "Intra - form Buffer"."Journal Template Name",
             "Intra - form Buffer"."Corrected Intrastat Report No.")
        then begin
            if IntrastatJnlBatch.Periodicity = IntrastatJnlBatch.Periodicity::Month then begin
                OutText += FormatNum(CopyStr(IntrastatJnlBatch."Statistics Period", 3, 2), 2);
                OutText += FormatNum('0', 1);
            end else
                if IntrastatJnlBatch.Periodicity = IntrastatJnlBatch.Periodicity::Quarter then begin
                    OutText += FormatNum('0', 2);
                    OutText += FormatNum(CopyStr(IntrastatJnlBatch."Statistics Period", 3, 1), 1);
                end else
                    OutText += FormatNum('0', 3);
            OutText += FormatNum(IntrastatJnlBatch."Statistics Period", 2);
        end else
            OutText += FormatNum('0', 5);
        OutText += GetCountryCodeVATRegNo();
        OutText += GetAmountSign();
        OutText += GetAmounts();
        OutText += GetTransTypeTariffNo();
        if IntrastatJnlBatch.Periodicity = IntrastatJnlBatch.Periodicity::Month then
            OutText += GetStatValue();
        exit(OutText);
    end;

    [Scope('OnPrem')]
    procedure GetRecordTypeThree(): Text
    var
        OutText: Text;
    begin
        OutText += GetFixedPart(3);
        OutText += GetCountryCodeVATRegNo();
        OutText += GetAmounts();
        OutText += GetDocNoDocDateServTariffNo();
        OutText += GetTransportMethod();
        OutText += GetPmtMthdPmtCodeCountry();
        exit(OutText);
    end;

    [Scope('OnPrem')]
    procedure GetRecordTypeFour(): Text
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        OutText: Text;
    begin
        OutText += GetFixedPart(4);
        OutText += FormatNum("Intra - form Buffer"."Custom Office No.", 6);
        if IntrastatJnlBatch.Get(
             "Intra - form Buffer"."Journal Template Name",
             "Intra - form Buffer"."Corrected Intrastat Report No.")
        then
            ;
        OutText += FormatNum(IntrastatJnlBatch."Statistics Period", 2);
        OutText += FormatNum(GetNumericVal(IntrastatJnlBatch."File Disk No."), 6);
        OutText += FormatAlphaNum("Intra - form Buffer"."Progressive No.", 5);
        OutText += GetCountryCodeVATRegNo();
        OutText += GetAmounts();
        OutText += GetDocNoDocDateServTariffNo();
        OutText += GetTransportMethod();
        OutText += GetPmtMthdPmtCodeCountry();
        exit(OutText);
    end;

    [Scope('OnPrem')]
    procedure GetTotals(): Text
    var
        OutText: Text;
        Length: Integer;
    begin
        if "Intrastat Jnl. Batch"."EU Service" then begin
            if "Intrastat Jnl. Batch"."Corrective Entry" then begin
                OutText += FormatNum('0', 54);
                OutText += GetTotalRecTotalAmt();
            end else begin
                OutText += FormatNum('0', 36);
                OutText += GetTotalRecTotalAmt();
                if "Intrastat Jnl. Batch".Type = "Intrastat Jnl. Batch".Type::Purchases then
                    OutText += FormatNum('0', 13)
                else
                    OutText += FormatNum('0', 18);
            end;
        end else
            if "Intrastat Jnl. Batch"."Corrective Entry" then begin
                OutText += FormatNum('0', 18);
                if TotalAmount > 0 then
                    OutText += GetTotalRecTotalAmt()
                else begin
                    OutText += FormatNum(Format(TotalRecords), 5);
                    OutText += ConvertLastDigit(CopyStr(FormatNum(Format(Round(-TotalAmount, 1)), 13), 1, 13));
                end;
                OutText += FormatNum('0', 36);
            end else begin
                OutText += GetTotalRecTotalAmt();
                if "Intrastat Jnl. Batch".Type = "Intrastat Jnl. Batch".Type::Purchases then
                    Length := 49
                else
                    Length := 54;
                OutText += FormatNum('0', Length);
            end;
        OutText += FormatNum('0', 5);
        exit(OutText);
    end;

    [Scope('OnPrem')]
    procedure GetCountryCodeVATRegNo(): Text[14]
    var
        OutText: Text[14];
    begin
        OutText += FormatAlphaNum("Intra - form Buffer"."Country/Region Code", 2);
        OutText += FormatAlphaNum(RemoveLeadingCountryCode("Intra - form Buffer"."VAT Registration No.",
              "Intra - form Buffer"."Country/Region Code"), 12);
        exit(OutText);
    end;

    [Scope('OnPrem')]
    procedure GetAmountSign(): Text[1]
    var
        OutText: Text[1];
    begin
        if "Intrastat Jnl. Batch"."Corrective Entry" then
            if "Intra - form Buffer".Amount > 0 then
                OutText += '+'
            else
                OutText += '-';
        exit(OutText);
    end;

    [Scope('OnPrem')]
    procedure GetAmounts(): Text[26]
    var
        OutText: Text[26];
    begin
        OutText += Format(Round("Intra - form Buffer".Amount, 1), 13, GetIntegerFormating(13));
        if "Intrastat Jnl. Batch".Type = "Intrastat Jnl. Batch".Type::Purchases then
            OutText += FormatNum(RoundCurrAmount, 13);
        exit(OutText);
    end;

    [Scope('OnPrem')]
    procedure GetTransTypeTariffNo(): Text[9]
    var
        OutText: Text[9];
    begin
        OutText += FormatAlphaNum("Intra - form Buffer"."Transaction Type", 1);
        OutText += FormatNum("Intra - form Buffer"."Tariff No.", 8);
        exit(OutText);
    end;

    [Scope('OnPrem')]
    procedure GetStatValue(): Text[13]
    var
        OutText: Text[13];
    begin
        OutText += Format(Round("Intra - form Buffer"."Statistical Value", 1), 13, GetIntegerFormating(13));
        exit(OutText);
    end;

    local procedure GetIntegerFormating(Length: Integer): Text
    begin
        exit(StrSubstNo('<Integer,%1><Filler Character,0>', Length));
    end;

    [Scope('OnPrem')]
    procedure GetTransportMethod(): Text[30]
    var
        OutText: Text[30];
    begin
        OutText += FormatAlphaNum("Intra - form Buffer"."Transport Method", 1);
        exit(OutText);
    end;

    [Scope('OnPrem')]
    procedure GetDocNoDocDateServTariffNo() OutText: Text
    var
        DocumentNo: Code[20];
        DocumentDate: Date;
    begin
        GetDocNoDocDate(DocumentNo, DocumentDate);
        OutText += FormatAlphaNum(DocumentNo, 15);
        OutText += Format(DocumentDate, 0, '<Day,2><Month,2><Year,2>');
        OutText +=
          PadStr(CopyStr(GetNumericVal("Intra - form Buffer"."Service Tariff No."), 1, 5), 6, '0');
    end;

    local procedure GetDocNoDocDate(var DocumentNo: Code[20]; var DocumentDate: Date)
    var
        IntrastatJnlLine2: Record "Intrastat Jnl. Line";
        CorrDocNo: Code[20];
    begin
        CorrDocNo := FindCorrectiveDocNo();
        if CorrDocNo <> '' then begin
            DocumentNo := CorrDocNo;
            IntrastatJnlLine2.SetRange("Journal Template Name", "Intra - form Buffer"."Journal Template Name");
            IntrastatJnlLine2.SetRange("Journal Batch Name", "Intra - form Buffer"."Corrected Intrastat Report No.");
            IntrastatJnlLine2.SetRange("Document No.", CorrDocNo);
            if IntrastatJnlLine2.FindFirst() then
                DocumentDate := IntrastatJnlLine2.Date;
        end else begin
            if "Intra - form Buffer".Type = "Intra - form Buffer".Type::Shipment then
                DocumentNo := "Intra - form Buffer"."Document No."
            else
                DocumentNo := CopyStr("Intra - form Buffer"."External Document No.", 1, MaxStrLen(DocumentNo));
            DocumentDate := "Intra - form Buffer".Date;
        end;
    end;

    local procedure GetPmtMthdPmtCodeCountry(): Text[3]
    var
        PaymentMethod: Record "Payment Method";
        OutText: Text[3];
    begin
        if PaymentMethod.Get("Intra - form Buffer"."Payment Method") then;
        OutText += FormatAlphaNum(PaymentMethod."Intrastat Payment Method", 1);
        OutText += FormatAlphaNum(IntrastatJnlLine."Country/Region of Payment Code", 2);
        exit(OutText);
    end;

    [Scope('OnPrem')]
    procedure ConvertLastDigit(TotalAmount: Text[13]): Text[13]
    var
        OutText: Text[13];
        LastDigit: Text[1];
    begin
        LastDigit := CopyStr(TotalAmount, 13, 1);
        OutText := CopyStr(TotalAmount, 1, 12);
        case LastDigit of
            '0':
                OutText += 'p';
            '1':
                OutText += 'q';
            '2':
                OutText += 'r';
            '3':
                OutText += 's';
            '4':
                OutText += 't';
            '5':
                OutText += 'u';
            '6':
                OutText += 'v';
            '7':
                OutText += 'w';
            '8':
                OutText += 'x';
            '9':
                OutText += 'y';
        end;
        exit(OutText);
    end;

    [Scope('OnPrem')]
    procedure GetTotalRecTotalAmt(): Text[18]
    var
        OutText: Text[18];
        TotalAmount2: Integer;
    begin
        OutText += FormatNum(Format(TotalRecords), 5);
        TotalAmount2 := Abs(Round(TotalAmount, 1));
        OutText += FormatNum(Format(TotalAmount2), 13);
        exit(OutText);
    end;

    [Scope('OnPrem')]
    procedure CheckCorrectiveStatPeriod(IntrastatJnlLine: Record "Intrastat Jnl. Line"; StatisticsPeriod: Code[10])
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        if IntrastatJnlLine."Reference Period" <> StatisticsPeriod then
            IntrastatJnlLine.TestField("Corrected Intrastat Report No.");
        if IntrastatJnlBatch.Get(
             IntrastatJnlLine."Journal Template Name", IntrastatJnlLine."Corrected Intrastat Report No.")
        then
            IntrastatJnlBatch.TestField("Statistics Period");
    end;

    [Scope('OnPrem')]
    procedure RemoveLeadingCountryCode(CodeParameter: Text[20]; CountryCode: Code[10]): Text[20]
    begin
        if CopyStr(CodeParameter, 1, StrLen(DelChr(CountryCode, '<>'))) = DelChr(CountryCode, '<>') then
            exit(CopyStr(CodeParameter, StrLen(DelChr(CountryCode, '<>')) + 1));

        exit(CodeParameter);
    end;

    [Scope('OnPrem')]
    procedure FindCorrectiveDocNo(): Code[20]
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        with IntrastatJnlLine do begin
            SetRange("Journal Template Name", "Intra - form Buffer"."Journal Template Name");
            SetRange("Journal Batch Name", "Intra - form Buffer"."Journal Batch Name");
            SetRange("Document No.", "Intra - form Buffer"."Document No.");
            if FindFirst() then
                exit("Corrected Document No.");
        end;
    end;

    [Scope('OnPrem')]
    procedure IsEU3PartyTrade(IntrastatJnlLine: Record "Intrastat Jnl. Line"): Boolean
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        SalesShipmentHeader: Record "Sales Shipment Header";
        ServiceShipmentHeader: Record "Service Shipment Header";
    begin
        if (IntrastatJnlLine.Type <> IntrastatJnlLine.Type::Shipment) or
           (IntrastatJnlLine."Source Type" <> IntrastatJnlLine."Source Type"::"Item Entry")
        then
            exit(false);

        ItemLedgerEntry.Get(IntrastatJnlLine."Source Entry No.");
        case ItemLedgerEntry."Document Type" of
            ItemLedgerEntry."Document Type"::"Sales Shipment":
                begin
                    SalesShipmentHeader.SetRange("No.", ItemLedgerEntry."Document No.");
                    SalesShipmentHeader.SetRange("Posting Date", ItemLedgerEntry."Posting Date");
                    exit(SalesShipmentHeader.FindFirst() and SalesShipmentHeader."EU 3-Party Trade");
                end;
            ItemLedgerEntry."Document Type"::"Service Shipment":
                begin
                    ServiceShipmentHeader.SetRange("No.", ItemLedgerEntry."Document No.");
                    ServiceShipmentHeader.SetRange("Posting Date", ItemLedgerEntry."Posting Date");
                    exit(ServiceShipmentHeader.FindFirst() and ServiceShipmentHeader."EU 3-Party Trade");
                end;
        end;

        exit(false);
    end;

#if not CLEAN20
    [Obsolete('Replaced by new InitializeRequest(OutStream)', '20.0')]
    procedure InitializeRequest(newServerFileName: Text)
    begin
        IntrastatFileWriter.SetServerFileName(newServerFileName);
    end;
#endif

    procedure InitializeRequest(var newResultFileOutStream: OutStream)
    begin
        IntrastatFileWriter.SetResultFileOutStream(newResultFileOutStream);
    end;

    local procedure SkipTransportMethodVerification(IntrastatJnlLine: Record "Intrastat Jnl. Line"): Boolean
    var
        VATEntry: Record "VAT Entry";
        ValueEntry: Record "Value Entry";
    begin
        if IntrastatJnlLine."Source Type" <> IntrastatJnlLine."Source Type"::"VAT Entry" then
            exit(false);

        if not VATEntry.Get(IntrastatJnlLine."Source Entry No.") then
            exit(false);

        if not VATEntry."EU Service" then
            exit(false);

        ValueEntry.SetRange("Document No.", VATEntry."Document No.");
        ValueEntry.SetRange("Posting Date", VATEntry."Posting Date");
        ValueEntry.SetFilter("Item No.", '<>%1', '');
        if ValueEntry.FindSet() then begin
            repeat
                if IsInventoriableTypeItem(ValueEntry."Item No.") then
                    exit(false);
            until ValueEntry.Next() = 0;
            exit(true);
        end;
        exit(false);
    end;

    local procedure IsInventoriableTypeItem(ItemNo: Code[20]): Boolean
    var
        Item: Record Item;
    begin
        if not Item.Get(ItemNo) then
            exit(true);
        exit(Item.IsInventoriableType());
    end;
}
#endif