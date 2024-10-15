report 88 "VAT- VIES Declaration Disk"
{
    ApplicationArea = Basic, Suite;
    Caption = 'VAT- VIES Declaration (CSV)';
    Permissions = TableData "VAT Entry" = imd;
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("VAT Entry"; "VAT Entry")
        {
            DataItemTableView = SORTING(Type, "Country/Region Code", "VAT Registration No.", "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Posting Date") WHERE(Type = CONST(Sale));
            RequestFilterFields = "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Posting Date";

            trigger OnAfterGetRecord()
            var
                VATEntry: Record "VAT Entry";
                TotalValueOfItemSupplies: Decimal;
                TotalValueOfServiceSupplies: Decimal;
                GroupTotal: Boolean;
            begin
                if "EU Service" then begin
                    HasServiceSupplies := true;
                    if UseAmtsInAddCurr then
                        TotalValueOfServiceSupplies := "Additional-Currency Base"
                    else
                        TotalValueOfServiceSupplies := Base;
                end else begin
                    HasItemSupplies := true;
                    if UseAmtsInAddCurr then
                        TotalValueOfItemSupplies := "Additional-Currency Base"
                    else
                        TotalValueOfItemSupplies := Base;
                end;

                if "EU 3-Party Trade" then begin
                    HasEU3PartyTrade := true;
                    EU3PartyItemTradeAmt := EU3PartyItemTradeAmt + TotalValueOfItemSupplies;
                    EU3PartyServiceTradeAmt := EU3PartyServiceTradeAmt + TotalValueOfServiceSupplies;
                end else begin
                    TotalValueofItemSuppliesTotal += TotalValueOfItemSupplies;
                    TotalValueofServiceSuppliesTot += TotalValueOfServiceSupplies;
                end;

                VATEntry.Copy("VAT Entry");
                if VATEntry.Next = 1 then begin
                    if (VATEntry."Country/Region Code" <> "Country/Region Code") or
                       (VATEntry."VAT Registration No." <> "VAT Registration No.")
                    then
                        GroupTotal := true;
                end else
                    GroupTotal := true;

                if GroupTotal then begin
                    WriteGrTotalsToFile(TotalValueofServiceSuppliesTot, TotalValueofItemSuppliesTotal,
                      EU3PartyServiceTradeAmt, EU3PartyItemTradeAmt,
                      HasEU3PartyTrade, HasItemSupplies, HasServiceSupplies);
                    EU3PartyItemTradeTotalAmt += EU3PartyItemTradeAmt;
                    EU3PartyServiceTradeTotalAmt += EU3PartyServiceTradeAmt;

                    TotalValueofItemSuppliesTotal := 0;
                    TotalValueofServiceSuppliesTot := 0;

                    EU3PartyItemTradeAmt := 0;
                    EU3PartyServiceTradeAmt := 0;

                    HasEU3PartyTrade := false;
                    HasItemSupplies := false;
                    HasServiceSupplies := false;
                end;
            end;

            trigger OnPostDataItem()
            begin
                VATFile.Close;
            end;

            trigger OnPreDataItem()
            begin
                if FileVersion = '' then
                    Error(FileVersionNotDefinedErr);
                if FileVersion2 = '' then
                    Error(FileVersionElsterOnlineNotDefinedErr);
                Clear(VATFile);
                VATFile.TextMode := true;
                VATFile.WriteMode := true;
                VATFile.Create(FileName);

                CompanyInfo.Get();
                GeneralLedgerSetup.Get();
                VATRegNo := ConvertStr(CompanyInfo."VAT Registration No.", Text001, '    ');
                VATFile.Write('#v' + FileVersion);
                VATFile.Write('#ve' + FileVersion2);
                VATFile.Write('Laenderkennzeichen,USt-IdNr.,Betrag(Euro),Art der Leistung,Importmeldung');
                NoOfGrTotal := 0;
                Period := GetRangeMax("Posting Date");
                InternalReferenceNo := Format(Period, 4, 2) + '000000';
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
                    field(ShowAmtInAddRepCurr; UseAmtsInAddCurr)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Amounts in Add. Reporting Currency';
                        MultiLine = true;
                        ToolTip = 'Specifies if the reported amounts are shown in the additional reporting currency.';
                    }
                    field(SkipCustomerDataCheck; SkipCustomerDataCheck)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Skip Customer Data Check';
                        ToolTip = 'Specifies if the report should skip the check of the customer''s country/region and VAT registation number.';
                    }
                    field(FileVersion; FileVersion)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'File Version';
                        ToolTip = 'Specifies the file version. For more information, see https://www.elsteronline.de/hilfe/eop/private/formulare/leitfaden/zm_import.html';
                    }
                    field("FileVersion 2"; FileVersion2)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'File version 2 (Elster online)';
                        ToolTip = 'Specifies the version of ElsterOnline. For more information, see https://www.elsteronline.de/hilfe/eop/private/formulare/leitfaden/zm_import.html';
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
        if not HideFileDialog then begin
            FileManagement.DownloadHandler(FileName, '', '', FileManagement.GetToFilterText('', FileName), ToFileNameTxt);
            FileManagement.DeleteServerFile(FileName);
        end
    end;

    trigger OnPreReport()
    begin
        FileName := FileManagement.ServerTempFileName('txt');
    end;

    var
        Text001: Label 'WwWw';
        Text003: Label '%1 was not filled in for all VAT entries in which %2 = %3.';
        CompanyInfo: Record "Company Information";
        Country: Record "Country/Region";
        Cust: Record Customer;
        GeneralLedgerSetup: Record "General Ledger Setup";
        FileManagement: Codeunit "File Management";
        VATFile: File;
        TotalValueofServiceSuppliesTot: Decimal;
        TotalValueofItemSuppliesTotal: Decimal;
        EU3PartyServiceTradeAmt: Decimal;
        EU3PartyItemTradeAmt: Decimal;
        EU3PartyItemTradeTotalAmt: Decimal;
        EU3PartyServiceTradeTotalAmt: Decimal;
        NoOfGrTotal: Integer;
        FileName: Text;
        VATRegNo: Code[20];
        InternalReferenceNo: Text[10];
        Period: Date;
        UseAmtsInAddCurr: Boolean;
        ToFileNameTxt: Label 'Default.csv';
        SkipCustomerDataCheck: Boolean;
        HideFileDialog: Boolean;
        FileVersion: Text[30];
        FileVersion2: Text[30];
        HasEU3PartyTrade: Boolean;
        HasItemSupplies: Boolean;
        HasServiceSupplies: Boolean;
        FileVersionNotDefinedErr: Label 'You must specify file version.';
        FileVersionElsterOnlineNotDefinedErr: Label 'You must specify file version (Elster online).';

    local procedure WriteGrTotalsToFile(TotalValueofServiceSupplies: Decimal; TotalValueofItemSupplies: Decimal; EU3PartyServiceTradeAmt: Decimal; EU3PartyItemTradeAmt: Decimal; HasEU3Party: Boolean; HasItem: Boolean; HasService: Boolean)
    begin
        with "VAT Entry" do begin
            if "VAT Registration No." = '' then begin
                Type := Type::Sale;
                Error(
                  Text003,
                  FieldCaption("VAT Registration No."), FieldCaption(Type), Type);
            end;

            if not SkipCustomerDataCheck then begin
                Cust.Get(GetCustomerNoToCheck("VAT Entry"));
                Cust.TestField("Country/Region Code");
                Country.Get(Cust."Country/Region Code");
                Cust.TestField("VAT Registration No.");
            end;
            Country.Get("Country/Region Code");
            Country.TestField("EU Country/Region Code");
            NoOfGrTotal := NoOfGrTotal + 1;

            InternalReferenceNo := IncStr(InternalReferenceNo);
            ModifyVATEntryInternalRefNo("Country/Region Code", "Bill-to/Pay-to No.", InternalReferenceNo);

            if HasItem then
                WriteLineToFile(-TotalValueofItemSupplies, 'L');
            if HasService then
                WriteLineToFile(-TotalValueofServiceSupplies, 'S');
            if HasEU3Party then
                WriteLineToFile(-(EU3PartyItemTradeAmt + EU3PartyServiceTradeAmt), 'D');
        end;
    end;

    local procedure GetCustomerNoToCheck(VATEntry: Record "VAT Entry"): Code[20]
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        if GeneralLedgerSetup."Bill-to/Sell-to VAT Calc." = GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Bill-to/Pay-to No." then
            exit(VATEntry."Bill-to/Pay-to No.");

        with CustLedgerEntry do begin
            SetRange("Customer No.", VATEntry."Bill-to/Pay-to No.");
            SetRange("Document Type", VATEntry."Document Type");
            SetRange("Document No.", VATEntry."Document No.");
            SetRange("Posting Date", VATEntry."Posting Date");
            FindFirst;
            exit("Sell-to Customer No.");
        end;
    end;

    procedure GetFileName(): Text[1024]
    begin
        exit(FileName);
    end;

    procedure InitializeRequest(NewHideFileDialog: Boolean)
    begin
        HideFileDialog := NewHideFileDialog;
    end;

    [Scope('OnPrem')]
    procedure WriteLineToFile(ExportAmount: Decimal; DLS: Text[1])
    var
        VATRegNo: Text[20];
    begin
        with "VAT Entry" do begin
            VATRegNo := "VAT Registration No.";
            if CopyStr(VATRegNo, 1, StrLen(Country."EU Country/Region Code")) = Country."EU Country/Region Code" then
                VATRegNo := CopyStr(VATRegNo, StrLen(Country."EU Country/Region Code") + 1);
            VATFile.Write(
              Format(Country."EU Country/Region Code", 2) + ',' +
              Format(VATRegNo) + ',' +
              DelChr(Format(Round(ExportAmount, 1)), '=', '.,') + ',' +
              DLS);
        end;
    end;

    local procedure ModifyVATEntryInternalRefNo(CountryRegionCode: Code[10]; BillToPayToNo: Code[20]; InternalRefNo: Text[30])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Country/Region Code", CountryRegionCode);
        VATEntry.SetRange("Bill-to/Pay-to No.", BillToPayToNo);
        VATEntry.ModifyAll("Internal Ref. No.", InternalRefNo);
    end;
}

