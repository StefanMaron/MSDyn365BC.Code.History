report 10115 "Vendor 1099 Magnetic Media"
{
    ApplicationArea = BasicUS;
    Caption = 'Vendor 1099 Magnetic Media';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("T Record"; "Integer")
        {
            DataItemTableView = SORTING(Number);
            MaxIteration = 1;

            trigger OnAfterGetRecord()
            begin
                WriteTRec;
            end;
        }
        dataitem("A Record"; "Integer")
        {
            DataItemTableView = SORTING(Number);
            MaxIteration = 4;
            dataitem(Vendor; Vendor)
            {
                DataItemTableView = SORTING("No.");
                RequestFilterFields = "No.";
                RequestFilterHeading = 'Vendor Filter';

                trigger OnAfterGetRecord()
                begin
                    MagMediaManagement.ClearAmts;
                    Clear(DirectSales);

                    // Check through all payments during calendar year
                    ProcessVendorInvoices("No.", PeriodDate);

                    WriteThis := MagMediaManagement.AnyAmount(FormType, EndLine);

                    if not WriteThis then
                        CurrReport.Skip;
                    PayeeNum := PayeeNum + 1;
                    PayeeTotal := PayeeTotal + 1;

                    "Post Code" := MagMediaManagement.StripNonNumerics("Post Code");

                    case FormType of
                        1:
                            begin // MISC
                                  // Following is a special case for 1099-MISC only
                                if IsDirectSales then
                                    DirectSales := '1'
                                else
                                    DirectSales := ' ';
                                WriteMiscBRec;
                            end;
                        2:
                            // DIV
                            WriteDivBRec;
                        3:
                            // INT
                            WriteIntBRec;
                        4:
                            WriteNecBRec();
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    MagMediaManagement.ClearTotals;
                end;
            }
            dataitem("C Record"; "Integer")
            {
                DataItemTableView = SORTING(Number);
                MaxIteration = 1;

                trigger OnAfterGetRecord()
                begin
                    if not AnyRecs[FormType] then
                        CurrReport.Skip;

                    case FormType of
                        1:
                            // MISC
                            WriteMISCCRec;
                        2:
                            // DIV
                            WriteDIVCRec;
                        3:
                            // INT
                            WriteINTCRec;
                        4:
                            WriteNECCRec();
                    end;
                end;
            }

            trigger OnAfterGetRecord()
            var
                VendorFiltered: Record Vendor;
            begin
                // 1 iteration per 1099 type

                Clear(PayeeNum);
                FormType := FormType + 1;
                InvoiceEntry.Reset;
                case FormType of
                    1:
                        begin // MISC
                            InvoiceEntry.SetRange("IRS 1099 Code", 'MISC-', 'MISC-99');
                            EndLine := LastMISCNo;
                            ReturnType := 'A ';
                        end;
                    2:
                        begin // DIV
                            InvoiceEntry.SetRange("IRS 1099 Code", 'DIV-', 'DIV-99');
                            EndLine := LastDIVNo;
                            ReturnType := '1 ';
                        end;
                    3:
                        begin // INT
                            InvoiceEntry.SetRange("IRS 1099 Code", 'INT-', 'INT-99');
                            EndLine := LastINTNo;
                            ReturnType := '6 ';
                        end;
                    4:
                        begin
                            InvoiceEntry.SetRange("IRS 1099 Code", 'NEC-', 'NEC-99');
                            EndLine := LastNECNo;
                            ReturnType := 'NE';
                        end;
                end;

                VendorFiltered.CopyFilters(Vendor);
                if VendorFiltered.FindSet then
                    repeat
                        ProcessVendorInvoices(VendorFiltered."No.", PeriodDate);
                    until VendorFiltered.Next = 0;

                AnyRecs[FormType] := MagMediaManagement.AnyAmount(FormType, EndLine);
                MagMediaManagement.AmtCodes(CodeNos, FormType, EndLine);
                // Following is a special case for 1099-MISC only
                if FormType = 1 then begin
                    IsDirectSales :=
                      MagMediaManagement.DirectSalesCheck(
                        MagMediaManagement.UpdateLines(InvoiceEntry, FormType, EndLine, GetFullMiscCode(7), 0.0));
                    if IsDirectSales then
                        CodeNos := '1';
                end;
                if AnyRecs[FormType] then begin
                    WriteARec;
                    ARecNum := ARecNum + 1;
                end else
                    CurrReport.Skip;
            end;
        }
        dataitem("F Record"; "Integer")
        {
            DataItemTableView = SORTING(Number);
            MaxIteration = 1;

            trigger OnAfterGetRecord()
            begin
                WriteFRec;
            end;

            trigger OnPostDataItem()
            begin
                IRSData.Seek(296);  // payee totals
                IRSData.TextMode := false;
                PayeeTotalStr := CopyStr(MagMediaManagement.FormatAmount(PayeeTotal, 7), 1, MaxStrLen(PayeeTotalStr));

                for i := 1 to StrLen(PayeeTotalStr) do begin
                    BinaryWriteChr := PayeeTotalStr[i];
                    IRSData.Write(BinaryWriteChr);
                end;
            end;

            trigger OnPreDataItem()
            begin
                if not AnyRecs[FormType] then
                    CurrReport.Skip;
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
                    field(Year; Year)
                    {
                        ApplicationArea = BasicUS;
                        Caption = 'Calendar Year';
                        ToolTip = 'Specifies the tax year for the 1099 forms that you want to print. The default is the work date year. The taxes may apply to the previous calendar year so you may want to change this date if nothing prints.';

                        trigger OnValidate()
                        begin
                            if (Year < 1980) or (Year > 2060) then
                                Error(Text007);
                        end;
                    }
                    field(TransCode; TransCode)
                    {
                        ApplicationArea = BasicUS;
                        Caption = 'Transmitter Control Code';
                        ToolTip = 'Specifies the control code of the transmitter that is used to electronically file 1099 forms.';

                        trigger OnValidate()
                        begin
                            if TransCode = '' then
                                Error(Text005);
                        end;
                    }
                    group("Transmitter Information")
                    {
                        Caption = 'Transmitter Information';
                        field("TransmitterInfo.Name"; TransmitterInfo.Name)
                        {
                            ApplicationArea = BasicUS;
                            Caption = 'Transmitter Name';
                            ToolTip = 'Specifies the name of the transmitter that is used to electronically file 1099 forms.';
                        }
                        field("TransmitterInfo.Address"; TransmitterInfo.Address)
                        {
                            ApplicationArea = BasicUS;
                            Caption = 'Street Address';
                            ToolTip = 'Specifies the address of the vendor.';
                        }
                        field("TransmitterInfo.City"; TransmitterInfo.City)
                        {
                            ApplicationArea = BasicUS;
                            Caption = 'City';
                            ToolTip = 'Specifies the city in the vendor''s address.';
                        }
                        field("TransmitterInfo.County"; TransmitterInfo.County)
                        {
                            ApplicationArea = BasicUS;
                            Caption = 'State';
                            ToolTip = 'Specifies the state as a part of the address.';
                        }
                        field("TransmitterInfo.""Post Code"""; TransmitterInfo."Post Code")
                        {
                            ApplicationArea = BasicUS;
                            Caption = 'ZIP Code';
                            ToolTip = 'Specifies the vendor''s ZIP code as a part of the address.';
                        }
                        field("TransmitterInfo.""Federal ID No."""; TransmitterInfo."Federal ID No.")
                        {
                            ApplicationArea = BasicUS;
                            Caption = 'Employer ID';
                            ToolTip = 'Specifies the employer at the vendor.';
                        }
                        field(ContactName; ContactName)
                        {
                            ApplicationArea = BasicUS;
                            Caption = 'Contact Name';
                            ToolTip = 'Specifies the name of the contact at the vendor.';

                            trigger OnValidate()
                            begin
                                if ContactName = '' then
                                    Error(Text002);
                            end;
                        }
                        field(ContactPhoneNo; ContactPhoneNo)
                        {
                            ApplicationArea = BasicUS;
                            Caption = 'Contact Phone No.';
                            ToolTip = 'Specifies the phone number of the contact at the vendor.';

                            trigger OnValidate()
                            begin
                                if ContactPhoneNo = '' then
                                    Error(Text001);
                            end;
                        }
                        field(ContactEmail; ContactEmail)
                        {
                            ApplicationArea = BasicUS;
                            Caption = 'Contact E-Mail';
                            ToolTip = 'Specifies the email address of the contact at the vendor.';
                        }
                    }
                    field(bTestFile; bTestFile)
                    {
                        ApplicationArea = BasicUS;
                        Caption = 'Test File';
                        ToolTip = 'Specifies you want to print a test file of the information that will be filed electronically.';

                        trigger OnValidate()
                        begin
                            bTestFileOnAfterValidate;
                        end;
                    }
                    group("Vendor Information")
                    {
                        Caption = 'Vendor Information';
                        field(VendIndicator; VendIndicator)
                        {
                            ApplicationArea = BasicUS;
                            Caption = 'Vendor Indicator';
                            OptionCaption = 'Vendor Software,In-House Software';
                            ToolTip = 'Specifies the type of vendor indicator that you want to use, including Vendor Software and In-House Software.';
                        }
                        field(VendorInfoName; VendorInfo.Name)
                        {
                            ApplicationArea = BasicUS;
                            Caption = 'Vendor Name';
                            ToolTip = 'Specifies the vendor''s name.';

                            trigger OnValidate()
                            begin
                                if VendorInfo.Name = '' then
                                    Error(Text006);
                            end;
                        }
                        field(VendorInfoAddress; VendorInfo.Address)
                        {
                            ApplicationArea = BasicUS;
                            Caption = 'Vendor Street Address';
                            ToolTip = 'Specifies the vendor''s address.';

                            trigger OnValidate()
                            begin
                                if VendorInfo.Address = '' then
                                    Error(Text006);
                            end;
                        }
                        field(VendorInfoCity; VendorInfo.City)
                        {
                            ApplicationArea = BasicUS;
                            Caption = 'Vendor City';
                            ToolTip = 'Specifies the vendors city as a part of the address.';

                            trigger OnValidate()
                            begin
                                if VendorInfo.City = '' then
                                    Error(Text006);
                            end;
                        }
                        field(VendorInfoCounty; VendorInfo.County)
                        {
                            ApplicationArea = BasicUS;
                            Caption = 'Vendor State';
                            ToolTip = 'Specifies the vendor''s state as a part of the address.';

                            trigger OnValidate()
                            begin
                                if VendorInfo.County = '' then
                                    Error(Text006);
                            end;
                        }
                        field(VendorInfoPostCode; VendorInfo."Post Code")
                        {
                            ApplicationArea = BasicUS;
                            Caption = 'Vendor ZIP Code';
                            ToolTip = 'Specifies the vendor''s ZIP code as a part of the address.';

                            trigger OnValidate()
                            begin
                                if VendorInfo."Post Code" = '' then
                                    Error(Text006);
                            end;
                        }
                        field(VendContactName; VendContactName)
                        {
                            ApplicationArea = BasicUS;
                            Caption = 'Vendor Contact Name';
                            ToolTip = 'Specifies the name of the contact at the vendor.';

                            trigger OnValidate()
                            begin
                                if VendContactName = '' then
                                    Error(Text004);
                            end;
                        }
                        field(VendContactPhoneNo; VendContactPhoneNo)
                        {
                            ApplicationArea = BasicUS;
                            Caption = 'Vendor Contact Phone No.';
                            ToolTip = 'Specifies the phone number of the contact at the vendor.';

                            trigger OnValidate()
                            begin
                                if VendContactPhoneNo = '' then
                                    Error(Text003);
                            end;
                        }
                        field(VendorInfoEMail; VendorInfo."E-Mail")
                        {
                            ApplicationArea = BasicUS;
                            Caption = 'Vendor E-Mail';
                            ToolTip = 'Specifies the vendor''s email address.';

                            trigger OnValidate()
                            begin
                                if VendorInfo."E-Mail" = '' then
                                    Error(Text006);
                            end;
                        }
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            Year := Date2DMY(WorkDate, 3);   /*default to current working year*/
            CompanyInfo.Get;
            MagMediaManagement.EditCompanyInfo(CompanyInfo);
            TransmitterInfo := CompanyInfo;
            MagMediaManagement.EditCompanyInfo(CompanyInfo);

        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    var
        IRS1099Management: Codeunit "IRS 1099 Management";
    begin
        IRS1099Management.ThrowErrorfUpgrade2020FebruaryNeeded();
        SendTraceTag('0000EBN', MagMediaTok, Verbosity::Normal, RunMagMediaReportMsg, DataClassification::SystemMetadata);
        TestFile := ' ';
        PriorYear := ' ';
        SequenceNo := 0;
    end;

    trigger OnPostReport()
    begin
        IRSData.Close;
        if FileName = '' then
            FileMgt.DownloadHandler(ServerTempFileName, '', '', FileMgt.GetToFilterText('', ServerTempFileName), ClientFileNameTxt)
        else
            FileMgt.CopyServerFile(ServerTempFileName, FileName, true);
        FileMgt.DeleteServerFile(ServerTempFileName);
    end;

    trigger OnPreReport()
    var
        FileMgt: Codeunit "File Management";
    begin
        if TransCode = '' then
            Error(Text005);
        if ContactPhoneNo = '' then
            Error(Text001);
        if ContactName = '' then
            Error(Text002);
        if VendContactName = '' then
            Error(Text004);
        if VendContactPhoneNo = '' then
            Error(Text003);
        if VendorInfo.Name = '' then
            Error(Text006);
        if VendorInfo.Address = '' then
            Error(Text006);
        if VendorInfo.City = '' then
            Error(Text006);
        if VendorInfo.County = '' then
            Error(Text006);
        if VendorInfo."Post Code" = '' then
            Error(Text006);
        if VendorInfo."E-Mail" = '' then
            Error(Text006);

        FormType := 0;

        // Create date range which covers the entire calendar year
        PeriodDate[1] := DMY2Date(1, 1, Year);
        PeriodDate[2] := DMY2Date(31, 12, Year);

        Clear(PayeeNum);
        Clear(ARecNum);

        LastMISCNo := 17;
        LastDIVNo := 16;
        LastINTNo := 13;
        LastNECNo := 4;
        MagMediaManagement.Run;

        Window.Open(
          'Exporting...\\' +
          'Table    #1####################');

        ServerTempFileName := FileMgt.ServerTempFileName('');
        Clear(IRSData);
        IRSData.TextMode := true;
        IRSData.WriteMode := true;
        IRSData.Create(ServerTempFileName);
        Window.Update(1, 'IRSTAX');
    end;

    var
        IRSData: File;
        CompanyInfo: Record "Company Information";
        TransmitterInfo: Record "Company Information";
        VendorInfo: Record "Company Information" temporary;
        TempAppliedEntry: Record "Vendor Ledger Entry" temporary;
        EntryAppMgt: Codeunit "Entry Application Management";
        FileMgt: Codeunit "File Management";
        PeriodDate: array[2] of Date;
        Year: Integer;
        DirectSales: Text[1];
        ReturnType: Text[2];
        CodeNos: Text[12];
        WriteThis: Boolean;
        AnyRecs: array[4] of Boolean;
        InvoiceEntry: Record "Vendor Ledger Entry";
        LastINTNo: Integer;
        LastMISCNo: Integer;
        LastDIVNo: Integer;
        LastNECNo: Integer;
        EndLine: Integer;
        Invoice1099Amount: Decimal;
        i: Integer;
        FormType: Integer;
        ServerTempFileName: Text;
        TestFile: Text[1];
        PriorYear: Text[1];
        TransCode: Code[5];
        ContactName: Text[40];
        ContactPhoneNo: Text[30];
        ContactEmail: Text[35];
        VendContactName: Text[40];
        VendContactPhoneNo: Text[30];
        MagMediaManagement: Codeunit "A/P Magnetic Media Management";
        PayeeNum: Integer;
        PayeeTotal: Integer;
        PayeeTotalStr: Text[8];
        ARecNum: Integer;
        bTestFile: Boolean;
        Window: Dialog;
        BinaryWriteChr: Char;
        VendIndicator: Option "Vendor Software","In-House Software";
        SequenceNo: Integer;
        Text001: Label 'You must enter the phone number of the person to be contacted if IRS/MCC encounters problems with the file or transmission.';
        Text002: Label 'You must enter the name of the person to be contacted if IRS/MCC encounters problems with the file or transmission.';
        Text003: Label 'You must enter the phone number of the person to be contacted if IRS/MCC has any software questions.';
        Text004: Label 'You must enter the name of the person to be contacted if IRS/MCC has any software questions.';
        Text005: Label 'You must enter the Transmitter Control Code assigned to you by the IRS.';
        Text006: Label 'You must enter all software vendor address information.';
        Text007: Label 'You must enter a valid year, eg 1993.';
        ClientFileNameTxt: Label 'IRSTAX.txt';
        MagMediaTok: Label 'MagMediaTelemetryCategoryTok', Locked = true;
        RunMagMediaReportMsg: Label 'Run magnetic media report', Locked = true;
        MiscCodeTok: Label 'MISC-', Locked = true;
        NecCodeTok: Label 'NEC-', Locked = true;
        HashTagTok: Label '#', Locked = true;
        FileName: Text;
        IsDirectSales: Boolean;

    procedure ProcessVendorInvoices(VendorNo: Code[20]; PeriodDate: array[2] of Date)
    var
        IRS1099Adjustment: Record "IRS 1099 Adjustment";
        TempIRS1099Adjustment: Record "IRS 1099 Adjustment" temporary;
        IRS1099Management: Codeunit "IRS 1099 Management";
    begin
        // search for invoices paid off by this payment
        EntryAppMgt.GetAppliedVendorEntries(TempAppliedEntry, VendorNo, PeriodDate, true);
        with TempAppliedEntry do begin
            // search for invoices with 1099 amounts
            SetFilter("Document Type", '%1|%2', "Document Type"::Invoice, "Document Type"::"Credit Memo");
            SetFilter("IRS 1099 Amount", '<>0');
            case FormType of
                1:
                    SetRange("IRS 1099 Code", 'MISC-', 'MISC-99');
                2:
                    SetRange("IRS 1099 Code", 'DIV-', 'DIV-99');
                3:
                    SetRange("IRS 1099 Code", 'INT-', 'INT-99');
                4:
                    SetRange("IRS 1099 Code", 'NEC-', 'NEC-99');
            end;
            if FindSet then
                repeat
                    Calculate1099Amount(TempAppliedEntry, "Amount to Apply");
                    if IRS1099Management.GetAdjustmentRec(IRS1099Adjustment, TempAppliedEntry) then begin
                        TempIRS1099Adjustment := IRS1099Adjustment;
                        if not TempIRS1099Adjustment.Find() then begin
                            MagMediaManagement.UpdateLines(
                              TempAppliedEntry, FormType, EndLine, "IRS 1099 Code", IRS1099Adjustment.Amount);
                            TempIRS1099Adjustment.Insert();
                        end;
                    end;
                until Next = 0;
        end;
    end;

    procedure Calculate1099Amount(InvoiceEntry: Record "Vendor Ledger Entry"; AppliedAmount: Decimal)
    begin
        InvoiceEntry.CalcFields(Amount);
        Invoice1099Amount := -AppliedAmount * InvoiceEntry."IRS 1099 Amount" / InvoiceEntry.Amount;
        MagMediaManagement.UpdateLines(InvoiceEntry, FormType, EndLine, InvoiceEntry."IRS 1099 Code", Invoice1099Amount);
    end;

    procedure WriteTRec()
    begin
        // T Record - 1 per transmission, 750 length
        IncrementSequenceNo;
        IRSData.Write(StrSubstNo('T') +
          StrSubstNo('#1##', CopyStr(Format(Year), 1, 4)) +
          StrSubstNo(PriorYear) + // Prior Year Indicator
          StrSubstNo('#1#######', MagMediaManagement.StripNonNumerics(TransmitterInfo."Federal ID No.")) +
          StrSubstNo('#1###', TransCode) + // Transmitter Control Code
          StrSubstNo('  ') + // replacement character
          StrSubstNo('     ') + // blank 5
          StrSubstNo(TestFile) +
          StrSubstNo(' ') + // Foreign Entity Code
          StrSubstNo('#1##############################################################################',
            TransmitterInfo.Name) +
          StrSubstNo('#1################################################', CompanyInfo.Name) +
          StrSubstNo('                              ') + // 2nd Payer Name
          StrSubstNo('#1######################################', CompanyInfo.Address) +
          StrSubstNo('#1######################################', CompanyInfo.City) +
          StrSubstNo('#1', CopyStr(CompanyInfo.County, 1, 2)) +
          StrSubstNo('#1#######', MagMediaManagement.StripNonNumerics(CompanyInfo."Post Code")) +
          StrSubstNo('               ') + // blank 15
          StrSubstNo('#1######', MagMediaManagement.FormatAmount(PayeeTotal, 8)) + // Payee total
          StrSubstNo('#1######################################', ContactName) +
          StrSubstNo('#1#############', ContactPhoneNo) +
          StrSubstNo('#1################################################', ContactEmail) + // 359-408
          StrSubstNo('  ') + // Tape file indicator
          StrSubstNo('#1####', '      ') + // place for media number (not required)
          StrSubstNo('                                                  ') +
          StrSubstNo('                                 ') +
          StrSubstNo('#1######', MagMediaManagement.FormatAmount(SequenceNo, 8)) + // sequence number for all rec types
          StrSubstNo('          ') +
          StrSubstNo('%1', CopyStr(Format(VendIndicator), 1, 1)) +
          StrSubstNo('#1######################################', VendorInfo.Name) +
          StrSubstNo('#1######################################', VendorInfo.Address) +
          StrSubstNo('#1######################################', VendorInfo.City) +
          StrSubstNo('#1', CopyStr(VendorInfo.County, 1, 2)) +
          StrSubstNo('#1#######', MagMediaManagement.StripNonNumerics(VendorInfo."Post Code")) +
          StrSubstNo('#1######################################', VendContactName) +
          StrSubstNo('#1#############', VendContactPhoneNo) +
          StrSubstNo('#1##################', VendorInfo."E-Mail") + // 20 chars
          StrSubstNo('                          '));
    end;

    procedure WriteARec()
    begin
        // A Record - 1 per Payer per 1099 type, 750 length
        IncrementSequenceNo;
        IRSData.Write(StrSubstNo('A') +
          StrSubstNo('#1##', CopyStr(Format(Year), 1, 4)) +
          StrSubstNo('      ') + // 6 blanks
          StrSubstNo('#1#######', MagMediaManagement.StripNonNumerics(CompanyInfo."Federal ID No.")) + // TIN
          StrSubstNo('#1##', '    ') + // Payer Name Control
          StrSubstNo(' ') +
          StrSubstNo(ReturnType) +
          StrSubstNo('#1##############', CodeNos) + // Amount Codes  16
          StrSubstNo('        ') + // 8 blanks
          StrSubstNo(' ') + // Foreign Entity Code
          StrSubstNo('#1######################################', CompanyInfo.Name) +
          StrSubstNo('                                        ') + // 2nd Payer Name
          StrSubstNo(' ') + // Transfer Agent Indicator
          StrSubstNo('#1######################################', CompanyInfo.Address) +
          StrSubstNo('#1######################################', CompanyInfo.City) +
          StrSubstNo('#1', CompanyInfo.County) +
          StrSubstNo('#1#######', MagMediaManagement.StripNonNumerics(CompanyInfo."Post Code")) +
          StrSubstNo('#1#############', CompanyInfo."Phone No.") +
          StrSubstNo('                                                  ') + // blank 50
          StrSubstNo('                                                  ') +
          StrSubstNo('                                                  ') +
          StrSubstNo('                                                  ') +
          StrSubstNo('                                                  ') +
          StrSubstNo('          ') +
          StrSubstNo('#1######', MagMediaManagement.FormatAmount(SequenceNo, 8)) + // sequence number for all rec types
          StrSubstNo('                                                  ') +
          StrSubstNo('                                                  ') +
          StrSubstNo('                                                  ') +
          StrSubstNo('                                                  ') +
          StrSubstNo('                                           '));
    end;

    procedure WriteMiscBRec()
    begin
        IncrementSequenceNo;

        IRSData.Write(StrSubstNo('B') +
          StrSubstNo('#1##', CopyStr(Format(Year), 1, 4)) +
          StrSubstNo(' ') + // correction indicator
          StrSubstNo('    ') + // name control
          StrSubstNo(' ') + // Type of TIN
          StrSubstNo('#1#######', MagMediaManagement.StripNonNumerics(Vendor."Federal ID No.")) + // TIN
          StrSubstNo('#1##################', Vendor."No.") + // Payer's Payee Account #
          StrSubstNo('              ') + // Blank 14
          StrSubstNo(GetHashTagStringWithLength(12), MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetAmt(GetFullMiscCode(1), FormType, EndLine), 12)) + // Payment 1
          StrSubstNo(GetHashTagStringWithLength(12), MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetAmt(GetFullMiscCode(2), FormType, EndLine), 12)) +
          StrSubstNo(GetHashTagStringWithLength(12), MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetAmt(GetFullMiscCode(3), FormType, EndLine), 12)) +
          StrSubstNo(GetHashTagStringWithLength(12), MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetAmt(GetFullMiscCode(4), FormType, EndLine), 12)) +
          StrSubstNo(GetHashTagStringWithLength(12), MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetAmt(GetFullMiscCode(5), FormType, EndLine), 12)) +
          StrSubstNo(GetHashTagStringWithLength(12), MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetAmt(GetFullMiscCode(6), FormType, EndLine), 12)) +
          StrSubstNo(GetHashTagStringWithLength(12), MagMediaManagement.FormatMoneyAmount(0, 12)) +
          StrSubstNo(GetHashTagStringWithLength(12), MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetAmt(GetFullMiscCode(8), FormType, EndLine), 12)) +
          StrSubstNo(GetHashTagStringWithLength(12), MagMediaManagement.FormatMoneyAmount(0, 12)) +
          StrSubstNo(GetHashTagStringWithLength(12), MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetAmt(GetFullMiscCode(9), FormType, EndLine), 12)) +
          StrSubstNo(GetHashTagStringWithLength(12), MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetAmt(GetFullMiscCode(13), FormType, EndLine), 12)) +
          StrSubstNo(GetHashTagStringWithLength(12), MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetAmt(GetFullMiscCode(10), FormType, EndLine), 12)) +
          StrSubstNo(GetHashTagStringWithLength(12), MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetAmt(GetFullMiscCode(12), FormType, EndLine), 12)) +
          StrSubstNo(GetHashTagStringWithLength(12), MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetAmt(GetFullMiscCode(14), FormType, EndLine), 12)) +
          StrSubstNo(GetHashTagStringWithLength(12), MagMediaManagement.FormatMoneyAmount(0, 12)) +
          StrSubstNo(GetHashTagStringWithLength(12), MagMediaManagement.FormatMoneyAmount(0, 12)) +
          StrSubstNo(' ') + // Foreign Country Indicator
          StrSubstNo('#1######################################', Vendor.Name) +
          StrSubstNo('#1######################################', Vendor."Name 2") +
          StrSubstNo('                                        ') + // blank 40
          StrSubstNo('#1######################################', Vendor.Address) +
          StrSubstNo('                                        ') + // blank 40
          StrSubstNo('#1######################################', Vendor.City) +
          StrSubstNo('#1', Vendor.County) +
          StrSubstNo('#1#######', Vendor."Post Code") +
          StrSubstNo(' ') +
          StrSubstNo('#1######', MagMediaManagement.FormatAmount(SequenceNo, 8)) + // sequence number for all rec types
          StrSubstNo('                                    ') +
          StrSubstNo(' ') + // Second TIN Notice (Optional) (544)
          StrSubstNo('  ') + // Blank (545-546)
          StrSubstNo(DirectSales) + // Direct Sales Indicator (547)
          StrSubstNo(Format(Vendor."FATCA filing requirement", 0, 2)) + // FATCA Filing Requirement Indicator (548)
          StrSubstNo('                                                  ') +
          StrSubstNo('                                                  ') +
          StrSubstNo('              ') + // Blank (549-662)
          StrSubstNo('                                                  ') +
          StrSubstNo('          ') + // Special Data Entries (663-722)
          StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetAmt(GetFullMiscCode(15), FormType, EndLine), 12)) + // State Income Tax Withheld (723-734)
          StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(0, 12)) + // Local Income Tax Withheld (735-746)
          StrSubstNo('  ') + // Combined Federal/State Code (747-748)
          StrSubstNo('  '));  // Blank (749-750)
    end;

    procedure WriteDivBRec()
    begin
        IncrementSequenceNo;
        IRSData.Write(StrSubstNo('B') + // Type (1)
          StrSubstNo('#1##', CopyStr(Format(Year), 1, 4)) + // Payment Year (2-5)
          StrSubstNo(' ') + // Corrected Return Indicator (6)
          StrSubstNo('    ') + // Name Control (7-10)
          StrSubstNo(' ') + // Type of TIN (11)
          StrSubstNo('#1#######', MagMediaManagement.StripNonNumerics(Vendor."Federal ID No.")) + // Payee's TIN (12-20)
          StrSubstNo('#1##################', Vendor."No.") + // Payer's Account Number for Payee (21-40)
          StrSubstNo('              ') + // Payer's Office Code (41-44) and Blank (45-54)
          StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetAmt('DIV-01-A', FormType, EndLine) +
              MagMediaManagement.GetAmt('DIV-01-B', FormType, EndLine) +
              MagMediaManagement.GetAmt('DIV-05', FormType, EndLine) +
              MagMediaManagement.GetAmt('DIV-06', FormType, EndLine), 12)) + // ordinary dividends 1 (55-66)
          StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetAmt('DIV-01-B', FormType, EndLine), 12)) + // 2 (67-78)
          StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetAmt('DIV-02-A', FormType, EndLine) +
              MagMediaManagement.GetAmt('DIV-02-B', FormType, EndLine) +
              MagMediaManagement.GetAmt('DIV-02-C', FormType, EndLine) +
              MagMediaManagement.GetAmt('DIV-02-D', FormType, EndLine), 12)) + // total capital gains 3 (79-90)
          StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(0, 12)) + // 4 (91-102)
          StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetAmt('DIV-05', FormType, EndLine), 12)) + // 5-Section 199A Dividends (103-114)
          StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetAmt('DIV-02-B', FormType, EndLine), 12)) + // 6-Unrecaptured Section 1250 gain (115-126)
          StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetAmt('DIV-02-C', FormType, EndLine), 12)) + // 7-Section 1202 gain (127-138)
          StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetAmt('DIV-02-D', FormType, EndLine), 12)) + // 8-Collectibles (28%) gain (139-150)
          StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetAmt('DIV-03', FormType, EndLine), 12)) + // 9-Nondividend distributions (151-162)
          StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetAmt('DIV-04', FormType, EndLine), 12)) + // fed W/H A (163-174)
          StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetAmt('DIV-06', FormType, EndLine), 12)) + // investment. expenses B (175-186)
          StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetAmt('DIV-07', FormType, EndLine), 12)) + // Foreign Taxc Paid C (187-198)
          StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetAmt('DIV-09', FormType, EndLine), 12)) + // cash liquidation D (199-210)
          StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetAmt('DIV-10', FormType, EndLine), 12)) + // non-cash liquidation E (211-222)
          StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetAmt('DIV-11', FormType, EndLine), 12)) + // Exempt-interest dividends F (223-234)
          StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetAmt('DIV-12', FormType, EndLine), 12)) + // Specified private activity bond... G (235-246)
          StrSubstNo(' ') + // Foreign Country Indicator (247)
          StrSubstNo('#1######################################', Vendor.Name) +
          StrSubstNo('#1######################################', Vendor."Name 2") +
          StrSubstNo('                                        ') + // blank 40
          StrSubstNo('#1######################################', Vendor.Address) +
          StrSubstNo('                                        ') + // blank 40
          StrSubstNo('#1######################################', Vendor.City) +
          StrSubstNo('#1', Vendor.County) +
          StrSubstNo('#1#######', Vendor."Post Code") +
          StrSubstNo(' ') +
          StrSubstNo('#1######', MagMediaManagement.FormatAmount(SequenceNo, 8)) + // sequence number for all rec types
          StrSubstNo('                                    ') +
          StrSubstNo(' ') + // Second TIN Notice (Optional) (544)
          StrSubstNo('  ') + // Blank (545-546)
          StrSubstNo('                                        ') + // Foreign Country or U.S. Possession (547-586)
          StrSubstNo(Format(Vendor."FATCA filing requirement", 0, 2)) + // FATCA Filing Requirement Indicator (587)
          StrSubstNo('                                                  ') +
          StrSubstNo('                         ') + // Blank (588-662)
          StrSubstNo('                                                  ') +
          StrSubstNo('          ') + // Special Data Entries (663-722)
          StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(0, 12)) + // State Income Tax Withheld (723-734)
          StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(0, 12)) + // Local Income Tax Withheld (735-746)
          StrSubstNo('  ') + // Combined Federal/State Code (747-748)
          StrSubstNo('  ')); // Blank (749-750)
    end;

    procedure WriteIntBRec()
    begin
        IncrementSequenceNo;
        IRSData.Write(StrSubstNo('B') +
          StrSubstNo('#1##', CopyStr(Format(Year), 1, 4)) +
          StrSubstNo(' ') + // correction indicator
          StrSubstNo('    ') + // name control
          StrSubstNo(' ') + // Type of TIN
          StrSubstNo('#1#######', MagMediaManagement.StripNonNumerics(Vendor."Federal ID No.")) + // TIN
          StrSubstNo('#1##################', Vendor."No.") + // Payer's Payee Account #
          StrSubstNo('              ') + // Blank 14
          StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetAmt('INT-01', FormType, EndLine), 12)) +
          StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetAmt('INT-02', FormType, EndLine), 12)) +
          StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetAmt('INT-03', FormType, EndLine), 12)) +
          StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetAmt('INT-04', FormType, EndLine), 12)) +
          StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetAmt('INT-05', FormType, EndLine), 12)) +
          StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetAmt('INT-06', FormType, EndLine), 12)) +
          StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(0, 12)) +
          StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetAmt('INT-08', FormType, EndLine) +
              MagMediaManagement.GetAmt('INT-09', FormType, EndLine), 12)) +
          StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetAmt('INT-09', FormType, EndLine), 12)) +
          StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetAmt('INT-10', FormType, EndLine), 12)) +
          StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetAmt('INT-11', FormType, EndLine), 12)) +
          StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(0, 12)) +
          StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetAmt('INT-13', FormType, EndLine), 12)) +
          StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetAmt('INT-12', FormType, EndLine), 12)) +
          StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(0, 12)) +
          StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(0, 12)) +
          StrSubstNo(' ') + // Foreign Country Indicator
          StrSubstNo('#1######################################', Vendor.Name) +
          StrSubstNo('#1######################################', Vendor."Name 2") +
          StrSubstNo('                                        ') + // blank 40
          StrSubstNo('#1######################################', Vendor.Address) +
          StrSubstNo('                                        ') + // blank 40
          StrSubstNo('#1######################################', Vendor.City) +
          StrSubstNo('#1', Vendor.County) +
          StrSubstNo('#1#######', Vendor."Post Code") +
          StrSubstNo(' ') +
          StrSubstNo('#1######', MagMediaManagement.FormatAmount(SequenceNo, 8)) + // sequence number for all rec types
          StrSubstNo('                                    ') +
          StrSubstNo(' ') + // Second TIN Notice (Optional) (544)
          StrSubstNo('  ') + // Blank (545-546)
          StrSubstNo('                                        ') + // Foreign Country or U.S. Possession (547-586)
          StrSubstNo('             ') + // CUSIP Number (587-599)
          StrSubstNo(Format(Vendor."FATCA filing requirement", 0, 2)) + // FATCA Filing Requirement Indicator (600)
          StrSubstNo('                                                  ') +
          StrSubstNo('            ') + // Blank (601-662)
          StrSubstNo('                                                  ') +
          StrSubstNo('          ') + // Special Data Entries (663-722)
          StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(0, 12)) + // State Income Tax Withheld (723-734)
          StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(0, 12)) + // Local Income Tax Withheld (735-746)
          StrSubstNo('  ') + // Combined Federal/State Code (747-748)
          StrSubstNo('  ')); // Blank (749-750)
    end;

    procedure WriteNecBRec()
    begin
        IncrementSequenceNo();
        IRSData.Write(StrSubstNo('B') +
          StrSubstNo('#1##', CopyStr(Format(Year), 1, 4)) +
          ' ' +
          '    ' +
          ' ' +
          StrSubstNo(GetHashTagStringWithLength(9), MagMediaManagement.StripNonNumerics(Vendor."Federal ID No.")) +
          StrSubstNo(GetHashTagStringWithLength(20), Vendor."No.") +
          '              ' +
          StrSubstNo(GetHashTagStringWithLength(12), MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetAmt(GetFullNecCode(1), FormType, EndLine), 12)) +
          StrSubstNo(GetHashTagStringWithLength(12), MagMediaManagement.FormatMoneyAmount(0, 12)) +
          StrSubstNo(GetHashTagStringWithLength(12), MagMediaManagement.FormatMoneyAmount(0, 12)) +
          StrSubstNo(GetHashTagStringWithLength(12), MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetAmt(GetFullNecCode(4), FormType, EndLine), 12)) +
          StrSubstNo(GetHashTagStringWithLength(12), MagMediaManagement.FormatMoneyAmount(0, 12)) +
          StrSubstNo(GetHashTagStringWithLength(12), MagMediaManagement.FormatMoneyAmount(0, 12)) +
          StrSubstNo(GetHashTagStringWithLength(12), MagMediaManagement.FormatMoneyAmount(0, 12)) +
          StrSubstNo(GetHashTagStringWithLength(12), MagMediaManagement.FormatMoneyAmount(0, 12)) +
          StrSubstNo(GetHashTagStringWithLength(12), MagMediaManagement.FormatMoneyAmount(0, 12)) +
          StrSubstNo(GetHashTagStringWithLength(12), MagMediaManagement.FormatMoneyAmount(0, 12)) +
          StrSubstNo(GetHashTagStringWithLength(12), MagMediaManagement.FormatMoneyAmount(0, 12)) +
          StrSubstNo(GetHashTagStringWithLength(12), MagMediaManagement.FormatMoneyAmount(0, 12)) +
          StrSubstNo(GetHashTagStringWithLength(12), MagMediaManagement.FormatMoneyAmount(0, 12)) +
          StrSubstNo(GetHashTagStringWithLength(12), MagMediaManagement.FormatMoneyAmount(0, 12)) +
          StrSubstNo(GetHashTagStringWithLength(12), MagMediaManagement.FormatMoneyAmount(0, 12)) +
          StrSubstNo(GetHashTagStringWithLength(12), MagMediaManagement.FormatMoneyAmount(0, 12)) +
          ' ' +
          StrSubstNo(GetHashTagStringWithLength(40), Vendor.Name) +
          StrSubstNo(GetHashTagStringWithLength(40), Vendor."Name 2") +
          '                                        ' +
          StrSubstNo(GetHashTagStringWithLength(40), Vendor.Address) +
          '                                        ' +
          StrSubstNo(GetHashTagStringWithLength(40), Vendor.City) +
          StrSubstNo(GetHashTagStringWithLength(0), Vendor.County) +
          StrSubstNo(GetHashTagStringWithLength(9), Vendor."Post Code") +
          ' ' +
          StrSubstNo(GetHashTagStringWithLength(8), MagMediaManagement.FormatAmount(SequenceNo, 8)) +
          '                                    ' +
          ' ' +
          '   ' +
          StrSubstNo(Format(Vendor."FATCA filing requirement", 0, 2)) +
          '                                                  ' +
          '                                                  ' +
          '              ' +
          '                                                  ' +
          '          ' +
          StrSubstNo(GetHashTagStringWithLength(12), MagMediaManagement.FormatMoneyAmount(0, 12)) +
          StrSubstNo(GetHashTagStringWithLength(12), MagMediaManagement.FormatMoneyAmount(0, 12)) +
          '  ' +
          '  ');
    end;

    procedure WriteMISCCRec()
    begin
        // C Record - 1 per Payer per 1099 type
        IncrementSequenceNo;
        IRSData.Write(StrSubstNo('C') +
          StrSubstNo('#1######', MagMediaManagement.FormatAmount(PayeeNum, 8)) +
          StrSubstNo('      ') + // Blank 6
          StrSubstNo(GetHashTagStringWithLength(18), MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal(GetFullMiscCode(1), FormType, EndLine), 18)) + // Payment 1
          StrSubstNo(GetHashTagStringWithLength(18), MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal(GetFullMiscCode(2), FormType, EndLine), 18)) +
          StrSubstNo(GetHashTagStringWithLength(18), MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal(GetFullMiscCode(3), FormType, EndLine), 18)) +
          StrSubstNo(GetHashTagStringWithLength(18), MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal(GetFullMiscCode(4), FormType, EndLine), 18)) +
          StrSubstNo(GetHashTagStringWithLength(18), MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal(GetFullMiscCode(5), FormType, EndLine), 18)) +
          StrSubstNo(GetHashTagStringWithLength(18), MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal(GetFullMiscCode(6), FormType, EndLine), 18)) +
          StrSubstNo(GetHashTagStringWithLength(18), MagMediaManagement.FormatMoneyAmount(0, 18)) +
          StrSubstNo(GetHashTagStringWithLength(18), MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal(GetFullMiscCode(8), FormType, EndLine), 18)) +
          StrSubstNo(GetHashTagStringWithLength(18), MagMediaManagement.FormatMoneyAmount(0, 18)) +
          StrSubstNo(GetHashTagStringWithLength(18), MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal(GetFullMiscCode(9), FormType, EndLine), 18)) +
          StrSubstNo(GetHashTagStringWithLength(18), MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal(GetFullMiscCode(13), FormType, EndLine), 18)) +
          StrSubstNo(GetHashTagStringWithLength(18), MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal(GetFullMiscCode(10), FormType, EndLine), 18)) +
          StrSubstNo(GetHashTagStringWithLength(18), MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal(GetFullMiscCode(12), FormType, EndLine), 18)) +
          StrSubstNo(GetHashTagStringWithLength(18), MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal(GetFullMiscCode(14), FormType, EndLine), 18)) +
          StrSubstNo(GetHashTagStringWithLength(18), MagMediaManagement.FormatMoneyAmount(0, 18)) +
          StrSubstNo(GetHashTagStringWithLength(18), MagMediaManagement.FormatMoneyAmount(0, 18)) +
          StrSubstNo('                                                  ') +
          StrSubstNo('                                                  ') +
          StrSubstNo('                                                  ') +
          StrSubstNo('                                              ') +
          StrSubstNo('#1######', MagMediaManagement.FormatAmount(SequenceNo, 8)) + // sequence number for all rec types
          StrSubstNo('                                                  ') +
          StrSubstNo('                                                  ') +
          StrSubstNo('                                                  ') +
          StrSubstNo('                                                  ') +
          StrSubstNo('                                           '));
    end;

    procedure WriteDIVCRec()
    begin
        // C Record - 1 per Payer per 1099 type
        IncrementSequenceNo;
        IRSData.Write(StrSubstNo('C') +
          StrSubstNo('#1######', MagMediaManagement.FormatAmount(PayeeNum, 8)) +
          StrSubstNo('      ') + // Blank 6
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(// ordinary dividends
              MagMediaManagement.GetTotal('DIV-01-A', FormType, EndLine) +
              MagMediaManagement.GetTotal('DIV-01-B', FormType, EndLine) +
              MagMediaManagement.GetTotal('DIV-05', FormType, EndLine) +
              MagMediaManagement.GetTotal('DIV-06', FormType, EndLine), 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal('DIV-01-B', FormType, EndLine), 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(// total capital gains
              MagMediaManagement.GetTotal('DIV-02-A', FormType, EndLine) +
              MagMediaManagement.GetTotal('DIV-02-B', FormType, EndLine) +
              MagMediaManagement.GetTotal('DIV-02-C', FormType, EndLine) +
              MagMediaManagement.GetTotal('DIV-02-D', FormType, EndLine), 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(0, 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal('DIV-05', FormType, EndLine), 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal('DIV-02-B', FormType, EndLine), 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal('DIV-02-C', FormType, EndLine), 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal('DIV-02-D', FormType, EndLine), 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(// Nondividend dist. 9
              MagMediaManagement.GetTotal('DIV-03', FormType, EndLine), 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(// fed income tax W/H A
              MagMediaManagement.GetTotal('DIV-04', FormType, EndLine), 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(// investment. expenses B
              MagMediaManagement.GetTotal('DIV-06', FormType, EndLine), 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal('DIV-07', FormType, EndLine), 18)) + // Foreign Taxc Paid C
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal('DIV-09', FormType, EndLine), 18)) + // cash liquidation D
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal('DIV-10', FormType, EndLine), 18)) + // non-cash liquidation E
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal('DIV-11', FormType, EndLine), 18)) + // Exempt-interest dividends F
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal('DIV-12', FormType, EndLine), 18)) + // Specified private activity bond interest dividends G
          StrSubstNo('                                                  ') +
          StrSubstNo('                                                  ') +
          StrSubstNo('                                                  ') +
          StrSubstNo('                                              ') +
          StrSubstNo('#1######', MagMediaManagement.FormatAmount(SequenceNo, 8)) + // sequence number for all rec types
          StrSubstNo('                                                  ') +
          StrSubstNo('                                                  ') +
          StrSubstNo('                                                  ') +
          StrSubstNo('                                                  ') +
          StrSubstNo('                                           '));
    end;

    procedure WriteINTCRec()
    begin
        // C Record - 1 per Payer per 1099 type
        IncrementSequenceNo;
        IRSData.Write(StrSubstNo('C') +
          StrSubstNo('#1######', MagMediaManagement.FormatAmount(PayeeNum, 8)) +
          StrSubstNo('      ') + // Blank 6
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal('INT-01', FormType, EndLine), 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal('INT-02', FormType, EndLine), 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal('INT-03', FormType, EndLine), 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal('INT-04', FormType, EndLine), 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal('INT-05', FormType, EndLine), 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal('INT-06', FormType, EndLine), 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(0, 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal('INT-08', FormType, EndLine) +
              MagMediaManagement.GetTotal('INT-09', FormType, EndLine), 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal('INT-09', FormType, EndLine), 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal('INT-10', FormType, EndLine), 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal('INT-11', FormType, EndLine), 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(0, 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal('INT-13', FormType, EndLine), 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal('INT-12', FormType, EndLine), 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(0, 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(0, 18)) +
          StrSubstNo('                                                  ') +
          StrSubstNo('                                                  ') +
          StrSubstNo('                                                  ') +
          StrSubstNo('                                              ') +
          StrSubstNo('#1######', MagMediaManagement.FormatAmount(SequenceNo, 8)) + // sequence number for all rec types
          StrSubstNo('                                                  ') +
          StrSubstNo('                                                  ') +
          StrSubstNo('                                                  ') +
          StrSubstNo('                                                  ') +
          StrSubstNo('                                           '));
    end;

    procedure WriteNECCRec()
    begin
        // C Record - 1 per Payer per 1099 type
        IncrementSequenceNo();
        IRSData.Write(StrSubstNo('C') +
          StrSubstNo(GetHashTagStringWithLength(8), MagMediaManagement.FormatAmount(PayeeNum, 8)) +
          '      ' +
          StrSubstNo(GetHashTagStringWithLength(18), MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal(GetFullNecCode(1), FormType, EndLine), 18)) +
          StrSubstNo(GetHashTagStringWithLength(18), MagMediaManagement.FormatMoneyAmount(0, 18)) +
          StrSubstNo(GetHashTagStringWithLength(18), MagMediaManagement.FormatMoneyAmount(0, 18)) +
          StrSubstNo(GetHashTagStringWithLength(18), MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal(GetFullNecCode(4), FormType, EndLine), 18)) +
          StrSubstNo(GetHashTagStringWithLength(18), MagMediaManagement.FormatMoneyAmount(0, 18)) +
          StrSubstNo(GetHashTagStringWithLength(18), MagMediaManagement.FormatMoneyAmount(0, 18)) +
          StrSubstNo(GetHashTagStringWithLength(18), MagMediaManagement.FormatMoneyAmount(0, 18)) +
          StrSubstNo(GetHashTagStringWithLength(18), MagMediaManagement.FormatMoneyAmount(0, 18)) +
          StrSubstNo(GetHashTagStringWithLength(18), MagMediaManagement.FormatMoneyAmount(0, 18)) +
          StrSubstNo(GetHashTagStringWithLength(18), MagMediaManagement.FormatMoneyAmount(0, 18)) +
          StrSubstNo(GetHashTagStringWithLength(18), MagMediaManagement.FormatMoneyAmount(0, 18)) +
          StrSubstNo(GetHashTagStringWithLength(18), MagMediaManagement.FormatMoneyAmount(0, 18)) +
          StrSubstNo(GetHashTagStringWithLength(18), MagMediaManagement.FormatMoneyAmount(0, 18)) +
          StrSubstNo(GetHashTagStringWithLength(18), MagMediaManagement.FormatMoneyAmount(0, 18)) +
          StrSubstNo(GetHashTagStringWithLength(18), MagMediaManagement.FormatMoneyAmount(0, 18)) +
          StrSubstNo(GetHashTagStringWithLength(18), MagMediaManagement.FormatMoneyAmount(0, 18)) +
          '                                                  ' +
          '                                                  ' +
          '                                                  ' +
          '                                              ' +
          StrSubstNo(GetHashTagStringWithLength(8), MagMediaManagement.FormatAmount(SequenceNo, 8)) +
          '                                                  ' +
          '                                                  ' +
          '                                                  ' +
          '                                                  ' +
          '                                           ');
    end;

    procedure WriteFRec()
    begin
        // F Record - 1
        IncrementSequenceNo;
        IRSData.Write(StrSubstNo('F') +
          StrSubstNo('#1######', MagMediaManagement.FormatAmount(ARecNum, 8)) + // number of A recs.
          StrSubstNo('#1########', MagMediaManagement.FormatAmount(0, 10)) + // 21 zeros
          StrSubstNo('#1#########', MagMediaManagement.FormatAmount(0, 11)) +
          StrSubstNo('                                                  ') +
          StrSubstNo('                                                  ') +
          StrSubstNo('                                                  ') +
          StrSubstNo('                                                  ') +
          StrSubstNo('                                                  ') +
          StrSubstNo('                                                  ') +
          StrSubstNo('                                                  ') +
          StrSubstNo('                                                  ') +
          StrSubstNo('                                                  ') +
          StrSubstNo('                   ') +
          StrSubstNo('#1######', MagMediaManagement.FormatAmount(SequenceNo, 8)) + // sequence number for all rec types
          StrSubstNo('                                                  ') +
          StrSubstNo('                                                  ') +
          StrSubstNo('                                                  ') +
          StrSubstNo('                                                  ') +
          StrSubstNo('                                           '));
    end;

    local procedure GetFullMiscCode(Number: Integer): Code[10]
    begin
        exit(GetFullCode(MiscCodeTok, Number));
    end;

    local procedure GetFullNecCode(Number: Integer): Code[10]
    begin
        exit(GetFullCode(NecCodeTok, Number));
    end;

    local procedure GetFullCode(Prefix: Text; Number: Integer) FullCode: Code[10]
    begin
        FullCode += Prefix;
        If Number < 10 then
            FullCode += Format(0);
        exit(FullCode + Format(Number));
    end;

    local procedure GetHashTagStringWithLength(Length: Integer) Result: Text
    var
        j: Integer;
    begin
        Result += HashTagTok + Format(1);
        for j := 1 to (Length - 2) do
            Result += HashTagTok;
        exit(Result);
    end;

    procedure IncrementSequenceNo()
    begin
        SequenceNo := SequenceNo + 1;
    end;

    local procedure bTestFileOnAfterValidate()
    begin
        if bTestFile then
            TestFile := 'T';
    end;

    procedure InitializeRequest(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;
}

