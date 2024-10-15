report 11413 "Create Intrastat Decl. Disk"
{
    // // Note: Intrastat Jnl. Batch dataitem has MaxIteration = 1

    Caption = 'Create Intrastat Decl. Disk';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Intrastat Jnl. Batch"; "Intrastat Jnl. Batch")
        {
            DataItemTableView = SORTING("Journal Template Name", Name);
            MaxIteration = 1;
            dataitem("Intrastat Jnl. Line"; "Intrastat Jnl. Line")
            {
                DataItemLink = "Journal Template Name" = FIELD("Journal Template Name"), "Journal Batch Name" = FIELD(Name);
                DataItemTableView = SORTING("Journal Template Name", "Journal Batch Name", Type);

                trigger OnAfterGetRecord()
                var
                    Item: Record Item;
                    Country: Record "Country/Region";
                    SpecialUnit: Decimal;
                    RoundedWeight: Integer;
                    ItemDirection: Integer;
                    IsCorrection: Boolean;
                begin
                    TestField("Item No.");
                    TestField("Tariff No.");
                    TestField("Country/Region Code");
                    TestField("Transaction Type");
                    TestField("Transport Method");
                    TestField("Net Weight");
                    TestField("Total Weight");

                    LineNo := LineNo + 1;

                    Country.Get("Country/Region Code");
                    Country.TestField("Intrastat Code");

                    RoundedWeight := Round("Total Weight", 1);

                    if RoundedWeight = 0 then
                        case "Total Weight" >= 0 of
                            true:
                                RoundedWeight := 1;
                            false:
                                RoundedWeight := -1;
                        end;

                    if "Supplementary Units" then begin
                        Item.Get("Item No.");
                        Item.TestField("Base Unit of Measure");
                        SpecialUnit := Quantity;
                    end;

                    case Type of
                        Type::Receipt:
                            begin
                                ItemDirection := 6;
                                ZeroReceipt := false;
                            end;
                        Type::Shipment:
                            begin
                                ItemDirection := 7;
                                ZeroShipment := false;
                            end;
                    end;
                    IsCorrection := CheckCorrection("Source Entry No.", ItemDirection);

                    Write(Format(Date, 0, '<Year4><Month,2>'));
                    Write(Format(ItemDirection));
                    Write(PADSTR2(CompanyInfo."VAT Registration No.", 12, '0', 'L'));
                    Write(PADSTR2(Format(LineNo, 0, '<Integer>'), 5, '0', '<'));
                    if CounterpartyInfo and (Type = Type::Shipment) then
                        Write(PADSTR2("Country/Region of Origin Code", 3, ' ', '>'))
                    else
                        Write(PADSTR2('', 3, ' ', '>'));
                    case ContainsAlpha(Country."Intrastat Code") of
                        true:
                            Write(PADSTR2(Country."Intrastat Code", 3, ' ', '>'));
                        false:
                            Write(PADSTR2(Country."Intrastat Code", 3, '0', '<'));
                    end;

                    Write(PADSTR2("Transport Method", 1, '', '>'));
                    Write('0');
                    Write(PADSTR2("Entry/Exit Point", 2, '0', '<'));
                    Write('00'); // Statistical system
                    Write(PADSTR2("Transaction Type", 1, '', '>')); // Transaction code
                    Write(PADSTR2(DelChr("Tariff No."), 8, '0', '<'));
                    Write('00');
                    Write(Sign(RoundedWeight, IsCorrection));
                    Write(PADSTR2(Format(RoundedWeight, 0, '<Integer>'), 10, ' ', '<'));
                    Write(Sign(SpecialUnit, IsCorrection));
                    Write(PADSTR2(Format(SpecialUnit, 0, '<Integer>'), 10, ' ', '<'));
                    Write(Sign(Amount, IsCorrection));
                    Write(PADSTR2(Format(Amount, 0, '<Integer>'), 10, ' ', '<'));
                    if IsCorrection then
                        Write('-')
                    else
                        Write('+');
                    Write(PADSTR2('0', 10, ' ', '<'));
                    Write(PADSTR2("Document No.", 10, ' ', '<'));
                    Write(PADSTR2('', 3, ' ', '>'));
                    if IsCorrection then
                        Write('C')
                    else
                        Write(' ');
                    Write('000');
                    Write(PADSTR2("Intrastat Jnl. Batch"."Currency Identifier", 1, ' ', '>'));
                    Write(PADSTR2('', 6, ' ', '>'));
                    if CounterpartyInfo then
                        if Type = Type::Receipt then begin
                            Write('  ');
                            Write(PadStr('', 17, ' '));
                        end else begin
                            Write(PADSTR2("Transaction Specification", 2, ' ', '<'));
                            Write(PADSTR2(CopyStr("Partner VAT ID", 1, 17), 17, ' ', '<'));
                        end;

                    Write(CrLf);
                end;

                trigger OnPreDataItem()
                begin
                    LineNo := 0;
                    ZeroReceipt := true;
                    ZeroShipment := true;
                end;
            }
            dataitem(ZeroReport; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = FILTER(6 | 7));

                trigger OnAfterGetRecord()
                var
                    ItemDirection: Integer;
                begin
                    case Number of
                        6:
                            if not ZeroReceipt then
                                CurrReport.Skip();
                        7:
                            if not ZeroShipment then
                                CurrReport.Skip();
                    end;

                    ItemDirection := Number;
                    LineNo := LineNo + 1;

                    Write(PADSTR2(Format(ReportYear, 0, '<Integer>'), 4, ' ', '>'));
                    Write(PADSTR2(Format(ReportMonth, 0, '<Integer>'), 2, '0', '<'));
                    Write(PADSTR2(Format(ItemDirection, 0, '<Integer>'), 1, '0', '<'));
                    Write(PADSTR2(CompanyInfo."VAT Registration No.", 12, '0', 'L'));
                    Write(PADSTR2(Format(LineNo, 0, '<Integer>'), 5, '0', '<'));
                    Write(PADSTR2('', 3, ' ', '<'));
                    Write(PADSTR2('QV', 3, ' ', '>'));
                    Write(PADSTR2('', 1, '0', '<'));
                    Write(PADSTR2('', 1, '0', '<'));
                    Write(PADSTR2('', 2, '0', '<'));
                    Write(PADSTR2('', 2, '0', '<'));
                    Write(PADSTR2('', 1, ' ', '<'));
                    Write(PADSTR2('', 8, '0', '<'));
                    Write(PADSTR2('', 2, '0', '<'));
                    Write(PADSTR2('+', 1, '', '<'));
                    Write(PADSTR2('0', 10, ' ', '<'));
                    Write(PADSTR2('+', 1, '', '<'));
                    Write(PADSTR2('0', 10, ' ', '<'));
                    Write(PADSTR2('+', 1, '', '<'));
                    Write(PADSTR2('0', 10, ' ', '<'));
                    Write(PADSTR2('+', 1, '', '<'));
                    Write(PADSTR2('0', 10, ' ', '<'));
                    Write(PADSTR2('', 10, ' ', '<'));
                    Write(PADSTR2('', 2, ' ', '<'));
                    Write(PADSTR2('', 1, ' ', '<'));
                    Write(PADSTR2('', 1, ' ', '<'));
                    Write(PADSTR2('000', 3, ' ', '<'));
                    Write(PADSTR2("Intrastat Jnl. Batch"."Currency Identifier", 1, ' ', '<'));
                    Write(PADSTR2('', 6, ' ', '<'));
                    Write(CrLf);
                end;
            }

            trigger OnAfterGetRecord()
            var
                Year: Integer;
            begin
                TestField("Currency Identifier");
                TestField("Statistics Period");

                Evaluate(Year, CopyStr("Statistics Period", 1, 2));

                case Year of
                    2 .. 29: // 2002..2029: only Euros allowed
                        begin
                            if not ("Currency Identifier" in ['E', 'EUR']) then
                                FieldError("Currency Identifier", Text1000008);
                            "Currency Identifier" := CopyStr("Currency Identifier", 1, 1);
                        end;
                    0 .. 1, 30 .. 99: // 2000..2001 and 1930..1999: Euros and Guilders allowed
                        begin
                            if not ("Currency Identifier" in ['G', 'NLG', 'E', 'EUR']) then
                                FieldError("Currency Identifier", Text1000007);
                            if "Currency Identifier" = 'NLG' then
                                "Currency Identifier" := 'G'
                            else
                                "Currency Identifier" := CopyStr("Currency Identifier", 1, 1);
                        end;
                end;

                if Reported then begin
                    if not Confirm(StrSubstNo(Text1000010 + Text1000011, "Journal Template Name", Name), false) then
                        Error(Text1000012);
                end else begin
                    "Export Date" := Today;
                    "Export Time" := Time;
                    Reported := true;
                    Modify;
                end;

                if not CheckPeriod("Statistics Period", ReportYear, ReportMonth) then
                    FieldError("Statistics Period", Text1000013);

                Write('9801');
                Write(PADSTR2(CompanyInfo."VAT Registration No.", 12, '0', 'L'));
                Write(PADSTR2(Format(ReportYear), 4, '0', '<'));
                Write(PADSTR2(Format(ReportMonth), 2, '0', '<'));
                Write(PADSTR2(CompanyInfo.Name, 40, ' ', '>'));
                Write(PADSTR2(RegNoCBS, 6, ' ', '>'));
                Write(PADSTR2(VersionNo, 5, ' ', '>'));
                Write(PADSTR2(Format("Export Date", 0, '<Year4><Month,2><Day,2>'), 8, ' ', '>'));
                Write(PADSTR2(Format("Export Time", 0, '<Hours24,2><Minutes,2><Seconds,2>'), 6, ' ', '>'));
                Write(PADSTR2(PhoneNo, 15, ' ', '>'));
                Write(PADSTR2('', 13, ' ', '>'));
                Write(CrLf);
            end;

            trigger OnPreDataItem()
            var
                LocalFunctionalityMgt: Codeunit "Local Functionality Mgt.";
            begin
                CompanyInfo.Get();
                CompanyInfo.TestField("VAT Registration No.");
                CompanyInfo.TestField(Name);

                PhoneNo := CopyStr(LocalFunctionalityMgt.ConvertPhoneNumber(CompanyInfo."Phone No."), 1, 15);

                "Intrastat Jnl. Line".CopyFilter("Journal Template Name", "Journal Template Name");
                "Intrastat Jnl. Line".CopyFilter("Journal Batch Name", Name);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    field(Counterparty; CounterpartyInfo)
                    {
                        ApplicationArea = BasicEU;
                        Caption = 'Counter party info';
                        ToolTip = 'Specifies if counter party information and country of origin will be included.';
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
    begin
        // Write closing record
        Write('9899');
        Write(PADSTR2('', 111, ' ', '<'));

        ExportFile.Close;

        // Remove trailing null
        ExportFile.Open(ServerTempFileName);
        ExportFile.Seek(ExportFile.Len - 1);
        ExportFile.Trunc;
        ExportFile.Close;

        OnInitializeServerFileName(ServerFileName);

        if ServerFileName = '' then
            FileMgt.DownloadHandler(ServerTempFileName, '', '', FileMgt.GetToFilterText('', ServerTempFileName), DefaultFilenameTxt)
        else
            FileMgt.CopyServerFile(ServerTempFileName, ServerFileName, true);
        FileMgt.DeleteServerFile(ServerTempFileName);
    end;

    trigger OnPreReport()
    begin
        ServerTempFileName := FileMgt.ServerTempFileName('');

        ExportFile.TextMode := false;
        ExportFile.WriteMode := true;
        ExportFile.Create(ServerTempFileName);
    end;

    var
        CompanyInfo: Record "Company Information";
        ExportFile: File;
        PhoneNo: Text[15];
        ServerTempFileName: Text;
        DefaultFilenameTxt: Label 'inthandl.98', Locked = true;
        Text1000008: Label 'must be E or EUR for Euro';
        Text1000007: Label 'must be E or EUR for Euro or G or NLG for Guilders';
        Text1000010: Label 'Batch %1 %2 was exported before.\';
        Text1000011: Label 'Continue?';
        Text1000012: Label 'Export cancelled.';
        Text1000013: Label 'must be filled in according to format YYMM';
        FileMgt: Codeunit "File Management";
        LineNo: Integer;
        ReportYear: Integer;
        ReportMonth: Integer;
        ZeroReceipt: Boolean;
        ZeroShipment: Boolean;
        ServerFileName: Text;
        CounterpartyInfo: Boolean;

    local procedure RegNoCBS(): Text[10]
    begin
        exit('971635');
    end;

    local procedure VersionNo(): Text[10]
    begin
        exit('20004');
    end;

    local procedure CheckPeriod(Period: Code[10]; var Year: Integer; var Month: Integer): Boolean
    begin
        case true of
            StrLen(Period) <> 4:
                exit(false);
            not Evaluate(Month, Period):
                exit(false);
        end;

        Year := Month div 100;
        Year := Round(Date2DMY(Today, 3), 100, '<') + Year;

        if Year > Date2DMY(Today, 3) then
            Year := Year - 100;

        Month := Month mod 100;
        exit(Month in [1 .. 12]);
    end;

    local procedure ContainsAlpha(Text: Text[1024]): Boolean
    begin
        exit(DelChr(Text, '=', ' 0123456789') <> '');
    end;

    local procedure PADSTR2(String: Text[1024]; Length: Integer; FillCharacter: Text[1]; Where: Text[1]) Result: Text[1024]
    var
        PaddingLength: Integer;
    begin
        PaddingLength := Length - StrLen(String);

        case true of
            (PaddingLength < 0) and (Where <> 'L'):
                exit(CopyStr(String, 1, Length));
            (PaddingLength < 0) and (Where = 'L'):
                exit(CopyStr(String, 1 - PaddingLength, Length));
            (PaddingLength > 0) and (Where = '>'):
                exit(String + PadStr('', PaddingLength, FillCharacter));
            (PaddingLength > 0) and (Where = '<'):
                exit(PadStr('', PaddingLength, FillCharacter) + String);
            else
                exit(String);
        end;
    end;

    local procedure Write(Line: Text[1024])
    begin
        // Writes lines and removes trailing null
        ExportFile.Write(CopyStr(Line, 1, StrLen(Line)));
        ExportFile.Seek(ExportFile.Pos - 1);
    end;

    local procedure Sign(Number: Decimal; IsCorrection: Boolean): Text[1]
    begin
        case Number < 0 of
            true:
                if not IsCorrection then
                    exit('-')
                else
                    exit('+');
            false:
                if not IsCorrection then
                    exit('+')
                else
                    exit('-');
        end;
    end;

    local procedure CrLf() CrLf: Text[2]
    begin
        CrLf[1] := 13;
        CrLf[2] := 10;
    end;

    local procedure CheckCorrection(SourceEntryNo: Integer; var ItemDirection: Integer): Boolean
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        with ItemLedgerEntry do begin
            Get(SourceEntryNo);
            case "Document Type" of
                "Document Type"::"Purchase Return Shipment":
                    begin
                        ItemDirection := 6;
                        exit(true);
                    end;
                "Document Type"::"Sales Return Receipt":
                    begin
                        ItemDirection := 7;
                        exit(true);
                    end;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure InitializeRequest(NewServerFileName: Text)
    begin
        ServerFileName := NewServerFileName;
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnInitializeServerFileName(var Filename: Text)
    begin
    end;
}

