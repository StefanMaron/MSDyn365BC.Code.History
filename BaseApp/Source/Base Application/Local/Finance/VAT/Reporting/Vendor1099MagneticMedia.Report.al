#if not CLEAN25
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Utilities;
using System.IO;
using System.Utilities;

report 10115 "Vendor 1099 Magnetic Media"
{
    ApplicationArea = BasicUS;
    Caption = 'Vendor 1099 Magnetic Media';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;
    ObsoleteReason = 'Moved to IRS Forms App.';
    ObsoleteState = Pending;
    ObsoleteTag = '25.0';

    dataset
    {
        dataitem("T Record"; "Integer")
        {
            DataItemTableView = sorting(Number);
            MaxIteration = 1;

            trigger OnAfterGetRecord()
            begin
                WriteTRec();
            end;
        }
        dataitem(InitialData; Integer)
        {
            DataItemTableView = sorting(Number);
            MaxIteration = 1;

            trigger OnPreDataItem()
            var
                VendorFiltered: Record Vendor;
                FormTypeIndex: Integer;
                IsDirectSales: Boolean;
            begin
                ProgressDialog.Open(ExportingTxt + ProcessTransactionsARecTxt);
                VendorsProcessed := 0;
                MagMediaManagement.ClearTotals();

                VendorFiltered.CopyFilters(VendorData);
                VendorTotalCount := VendorFiltered.Count();
                if VendorFiltered.FindSet() then
                    repeat
                        VendorsProcessed += 1;
                        UpdateProgressDialog(1, Format(Round(VendorsProcessed / VendorTotalCount * 100, 1)));

                        Calc1099AmountForVendorInvoices(VendorFiltered."No.", PeriodDate);
                    until VendorFiltered.Next() = 0;
                ProgressDialog.Close();

                for FormTypeIndex := 1 to FormTypeCount do begin
                    AnyRecs[FormTypeIndex] := MagMediaManagement.AnyAmount(FormTypeIndex, FormTypeLastNo[FormTypeIndex]);
                    MagMediaManagement.AmtCodes(CodeNos[FormTypeIndex], FormTypeIndex, FormTypeLastNo[FormTypeIndex]);
                    // special case for 1099-MISC only
                    if FormTypeIndex = MiscTypeIndex then begin
                        InvoiceEntry.Reset();
                        InvoiceEntry.SetFilter("IRS 1099 Code", IRS1099CodeFilter[MiscTypeIndex]);
                        IsDirectSales :=
                            MagMediaManagement.DirectSalesCheck(
                                MagMediaManagement.UpdateLines(InvoiceEntry, MiscTypeIndex, FormTypeLastNo[MiscTypeIndex], GetFullMiscCode(7), 0.0));
                        if IsDirectSales then begin
                            CodeNos[FormTypeIndex] := '1';
                            DirectSales := '1'
                        end else
                            DirectSales := ' ';
                    end;
                end;
            end;
        }
        dataitem(VendorData; Vendor)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";
            RequestFilterHeading = 'Vendor Filter';

            trigger OnAfterGetRecord()
            var
                FormTypeIndex: Integer;
            begin
                // write IRS text lines to array for each vendor for each 1099 type
                VendorsProcessed += 1;
                UpdateProgressDialog(1, Format(Round(VendorsProcessed / VendorTotalCount * 100, 1)));

                MagMediaManagement.ClearAmts();
                "Post Code" := CopyStr(MagMediaManagement.StripNonNumerics("Post Code"), 1, MaxStrLen("Post Code"));

                Calc1099AmountForVendorInvoices("No.", PeriodDate);

                for FormTypeIndex := 1 to FormTypeCount do begin
                    WriteThis := MagMediaManagement.AnyAmount(FormTypeIndex, FormTypeLastNo[FormTypeIndex]);
                    if WriteThis then begin
                        PayeeCount[FormTypeIndex] := PayeeCount[FormTypeIndex] + 1;
                        PayeeCountTotal := PayeeCountTotal + 1;
                        case FormTypeIndex of
                            MiscTypeIndex:
                                AddMiscBRecLine();
                            DivTypeIndex:
                                AddDivBRecLine();
                            IntTypeIndex:
                                AddIntBRecLine();
                            NecTypeIndex:
                                AddNecBRecLine();
                        end;
                    end;
                end;
            end;

            trigger OnPreDataItem()
            var
                EmptyList: List of [Text];
                FormTypeIndex: Integer;
            begin
                ProgressDialog.Open(ExportingTxt + ProcessTransactionsBRecTxt);
                VendorTotalCount := VendorData.Count();
                VendorsProcessed := 0;

                MagMediaManagement.ClearTotals();
                for FormTypeIndex := 1 to FormTypeCount do begin
                    Clear(EmptyList);
                    IRSVendorLines.Insert(FormTypeIndex, EmptyList);
                end;
            end;

            trigger OnPostDataItem()
            begin
                ProgressDialog.Close();
            end;
        }
        dataitem("A Record"; "Integer")
        {
            DataItemTableView = sorting(Number);
            MaxIteration = 4;
            dataitem(Vendor; Vendor)
            {
                DataItemTableView = sorting("No.");
            }
            dataitem("B Record"; Integer)
            {
                DataItemTableView = sorting(Number);
                MaxIteration = 1;

                trigger OnAfterGetRecord()
                var
                    VendorLinesGroup: List of [Text];
                    Line: Text;
                begin
                    if not AnyRecs[FormType] then
                        CurrReport.Skip();

                    VendorLinesGroup := IRSVendorLines.Get(FormType);
                    foreach Line in VendorLinesGroup do begin
                        IncrementSequenceNo();
                        UpdateSequenceNoInRecLine(Line);
                        IRSData.Write(Line);
                    end;
                end;
            }
            dataitem("C Record"; "Integer")
            {
                DataItemTableView = sorting(Number);
                MaxIteration = 1;

                trigger OnAfterGetRecord()
                begin
                    if not AnyRecs[FormType] then
                        CurrReport.Skip();

                    case FormType of
                        MiscTypeIndex:
                            WriteMISCCRec();
                        DivTypeIndex:
                            WriteDIVCRec();
                        IntTypeIndex:
                            WriteINTCRec();
                        NecTypeIndex:
                            WriteNECCRec();
                    end;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                // 1 iteration per 1099 type
                FormType := FormType + 1;
                EndLine := FormTypeLastNo[FormType];

                if AnyRecs[FormType] then begin
                    WriteARec();
                    ARecNum := ARecNum + 1;
                end else
                    CurrReport.Skip();
            end;
        }
        dataitem("F Record"; "Integer")
        {
            DataItemTableView = sorting(Number);
            MaxIteration = 1;

            trigger OnAfterGetRecord()
            begin
                WriteFRec();
            end;

            trigger OnPostDataItem()
            var
                i: Integer;
            begin
                IRSData.Seek(296);  // payee totals
                IRSData.TextMode := false;
                PayeeTotalStr := CopyStr(MagMediaManagement.FormatAmount(PayeeCountTotal, 7), 1, MaxStrLen(PayeeTotalStr));

                for i := 1 to StrLen(PayeeTotalStr) do begin
                    BinaryWriteChr := PayeeTotalStr[i];
                    IRSData.Write(BinaryWriteChr);
                end;
            end;

            trigger OnPreDataItem()
            begin
                if not AnyRecs[FormType] then
                    CurrReport.Skip();
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
                        field("TransmitterInfo.PostCode"; TransmitterInfo."Post Code")
                        {
                            ApplicationArea = BasicUS;
                            Caption = 'ZIP Code';
                            ToolTip = 'Specifies the vendor''s ZIP code as a part of the address.';
                        }
                        field("TransmitterInfo.FederalIDNo."; TransmitterInfo."Federal ID No.")
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
                            bTestFileOnAfterValidate();
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
                        field(VendorInfoName; TempVendorInfo.Name)
                        {
                            ApplicationArea = BasicUS;
                            Caption = 'Vendor Name';
                            ToolTip = 'Specifies the vendor''s name.';

                            trigger OnValidate()
                            begin
                                if TempVendorInfo.Name = '' then
                                    Error(Text006);
                            end;
                        }
                        field(VendorInfoAddress; TempVendorInfo.Address)
                        {
                            ApplicationArea = BasicUS;
                            Caption = 'Vendor Street Address';
                            ToolTip = 'Specifies the vendor''s address.';

                            trigger OnValidate()
                            begin
                                if TempVendorInfo.Address = '' then
                                    Error(Text006);
                            end;
                        }
                        field(VendorInfoCity; TempVendorInfo.City)
                        {
                            ApplicationArea = BasicUS;
                            Caption = 'Vendor City';
                            ToolTip = 'Specifies the vendors city as a part of the address.';

                            trigger OnValidate()
                            begin
                                if TempVendorInfo.City = '' then
                                    Error(Text006);
                            end;
                        }
                        field(VendorInfoCounty; TempVendorInfo.County)
                        {
                            ApplicationArea = BasicUS;
                            Caption = 'Vendor State';
                            ToolTip = 'Specifies the vendor''s state as a part of the address.';

                            trigger OnValidate()
                            begin
                                if TempVendorInfo.County = '' then
                                    Error(Text006);
                            end;
                        }
                        field(VendorInfoPostCode; TempVendorInfo."Post Code")
                        {
                            ApplicationArea = BasicUS;
                            Caption = 'Vendor ZIP Code';
                            ToolTip = 'Specifies the vendor''s ZIP code as a part of the address.';

                            trigger OnValidate()
                            begin
                                if TempVendorInfo."Post Code" = '' then
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
                        field(VendorInfoEMail; TempVendorInfo."E-Mail")
                        {
                            ApplicationArea = BasicUS;
                            Caption = 'Vendor E-Mail';
                            ToolTip = 'Specifies the vendor''s email address.';

                            trigger OnValidate()
                            begin
                                if TempVendorInfo."E-Mail" = '' then
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
            Year := Date2DMY(WorkDate(), 3);   /*default to current working year*/
            CompanyInfo.Get();
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
        Session.LogMessage('0000EBN', MagMediaTok, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', RunMagMediaReportMsg);
        TestFile := ' ';
        PriorYear := ' ';
        SequenceNo := 0;
    end;

    trigger OnPostReport()
    var
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OutStream: OutStream;
        ClientFileName: Text;
    begin
        IRSData.CreateInStream(InStream);
        TempBlob.CreateOutStream(OutStream);
        CopyStream(OutStream, InStream);
        IRSData.Close();
        FileMgt.DeleteServerFile(ServerTempFileName);

        OnBeforeDownloadFile(TempBlob);

        TempBlob.CreateInStream(InStream);
        if FileName = '' then begin
            ClientFileName := ClientFileNameTxt;
            DownloadFromStream(InStream, '', '', '*.txt', ClientFileName);
        end else begin
            IRSData.Create(ServerTempFileName);
            IRSData.CreateOutStream(OutStream);
            CopyStream(OutStream, InStream);
            IRSData.Close();
            FileMgt.CopyServerFile(ServerTempFileName, FileName, true);
            FileMgt.DeleteServerFile(ServerTempFileName);
        end;
    end;

    trigger OnPreReport()
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
        if TempVendorInfo.Name = '' then
            Error(Text006);
        if TempVendorInfo.Address = '' then
            Error(Text006);
        if TempVendorInfo.City = '' then
            Error(Text006);
        if TempVendorInfo.County = '' then
            Error(Text006);
        if TempVendorInfo."Post Code" = '' then
            Error(Text006);
        if TempVendorInfo."E-Mail" = '' then
            Error(Text006);

        FormType := 0;

        // Create date range which covers the entire calendar year
        PeriodDate[1] := DMY2Date(1, 1, Year);
        PeriodDate[2] := DMY2Date(31, 12, Year);

        Clear(PayeeCount);
        Clear(ARecNum);

        FormTypeCount := 4;
        MiscTypeIndex := 1;
        DivTypeIndex := 2;
        IntTypeIndex := 3;
        NecTypeIndex := 4;
        FormTypeLastNo[MiscTypeIndex] := 17;
        FormTypeLastNo[DivTypeIndex] := 18;
        FormTypeLastNo[IntTypeIndex] := 13;
        FormTypeLastNo[NecTypeIndex] := 4;
        IRS1099CodeFilter[MiscTypeIndex] := 'MISC-..MISC-99';
        IRS1099CodeFilter[DivTypeIndex] := 'DIV-..DIV-99';
        IRS1099CodeFilter[IntTypeIndex] := 'INT-..INT-99';
        IRS1099CodeFilter[NecTypeIndex] := 'NEC-..NEC-99';
        ReturnType[MiscTypeIndex] := 'A ';
        ReturnType[DivTypeIndex] := '1 ';
        ReturnType[IntTypeIndex] := '6 ';
        ReturnType[NecTypeIndex] := 'NE';
        MagMediaManagement.Run();

        ServerTempFileName := FileMgt.ServerTempFileName('');
        Clear(IRSData);
        IRSData.TextMode := true;
        IRSData.WriteMode := true;
        IRSData.Create(ServerTempFileName);
    end;

    var
        IRSData: File;
        CompanyInfo: Record "Company Information";
        TransmitterInfo: Record "Company Information";
        TempVendorInfo: Record "Company Information" temporary;
        TempAppliedEntry: Record "Vendor Ledger Entry" temporary;
        InvoiceEntry: Record "Vendor Ledger Entry";
        EntryAppMgt: Codeunit "Entry Application Management";
        FileMgt: Codeunit "File Management";
        MagMediaManagement: Codeunit "A/P Magnetic Media Management";
        PeriodDate: array[2] of Date;
        Year: Integer;
        DirectSales: Text[1];
        ReturnType: array[4] of Text[2];
        CodeNos: array[4] of Text[12];
        WriteThis: Boolean;
        AnyRecs: array[4] of Boolean;
        MiscTypeIndex: Integer;
        DivTypeIndex: Integer;
        IntTypeIndex: Integer;
        NecTypeIndex: Integer;
        FormTypeCount: Integer;
        VendorTotalCount: Integer;
        VendorsProcessed: Integer;
        FormTypeLastNo: array[4] of Integer;
        IRS1099CodeFilter: array[4] of Text;
        IRSVendorLines: List of [List of [Text]];
        EndLine: Integer;
        Invoice1099Amount: Decimal;
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
        PayeeCount: array[4] of Integer;
        PayeeCountTotal: Integer;
        PayeeTotalStr: Text[8];
        ARecNum: Integer;
        bTestFile: Boolean;
        ProgressDialog: Dialog;
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
        ExportingTxt: Label 'Exporting...\';
        ProcessTransactionsARecTxt: label 'Processing transactions for A records: #1###', Comment = '#1 - percent of processed vendors';
        ProcessTransactionsBRecTxt: label 'Processing transactions for B records: #1###', Comment = '#1 - percent of processed vendors';
        MagMediaTok: Label 'MagMediaTelemetryCategoryTok', Locked = true;
        RunMagMediaReportMsg: Label 'Run magnetic media report', Locked = true;
        MiscCodeTok: Label 'MISC-', Locked = true;
        NecCodeTok: Label 'NEC-', Locked = true;
        HashTagTok: Label '#', Locked = true;
        BlankTagTok: Label ' ', Locked = true;
        FileName: Text;

    procedure ProcessVendorInvoices(VendorNo: Code[20]; PeriodDate: array[2] of Date)
    var
        IRS1099Adjustment: Record "IRS 1099 Adjustment";
        TempIRS1099Adjustment: Record "IRS 1099 Adjustment" temporary;
        IRS1099Management: Codeunit "IRS 1099 Management";
    begin
        // search for invoices paid off by this payment
        EntryAppMgt.GetAppliedVendorEntries(TempAppliedEntry, VendorNo, PeriodDate, true);
        // search for invoices with 1099 amounts
        TempAppliedEntry.SetFilter("Document Type", '%1|%2', TempAppliedEntry."Document Type"::Invoice, TempAppliedEntry."Document Type"::"Credit Memo");
        TempAppliedEntry.SetFilter("IRS 1099 Amount", '<>0');
        case FormType of
            1:
                TempAppliedEntry.SetRange("IRS 1099 Code", 'MISC-', 'MISC-99');
            2:
                TempAppliedEntry.SetRange("IRS 1099 Code", 'DIV-', 'DIV-99');
            3:
                TempAppliedEntry.SetRange("IRS 1099 Code", 'INT-', 'INT-99');
            4:
                TempAppliedEntry.SetRange("IRS 1099 Code", 'NEC-', 'NEC-99');
        end;
        if TempAppliedEntry.FindSet() then
            repeat
                Calculate1099Amount(TempAppliedEntry, TempAppliedEntry."Amount to Apply");
                if IRS1099Management.GetAdjustmentRec(IRS1099Adjustment, TempAppliedEntry) then begin
                    TempIRS1099Adjustment := IRS1099Adjustment;
                    if not TempIRS1099Adjustment.Find() then begin
                        MagMediaManagement.UpdateLines(
                          TempAppliedEntry, FormType, EndLine, TempAppliedEntry."IRS 1099 Code", IRS1099Adjustment.Amount);
                        TempIRS1099Adjustment.Insert();
                    end;
                end;
            until TempAppliedEntry.Next() = 0;
    end;

    procedure Calculate1099Amount(InvoiceEntry: Record "Vendor Ledger Entry"; AppliedAmount: Decimal)
    begin
        InvoiceEntry.CalcFields(Amount);
        Invoice1099Amount := -AppliedAmount * InvoiceEntry."IRS 1099 Amount" / InvoiceEntry.Amount;
        MagMediaManagement.UpdateLines(InvoiceEntry, FormType, EndLine, InvoiceEntry."IRS 1099 Code", Invoice1099Amount);
    end;

    local procedure Calc1099AmountForVendorInvoices(VendorNo: Code[20]; StartEndDate: array[2] of Date)
    var
        TempApplVendorLedgerEntry: Record "Vendor Ledger Entry" temporary;
        TempIRS1099Adjustment: Record "IRS 1099 Adjustment" temporary;
        IRS1099Adjustment: Record "IRS 1099 Adjustment";
        IRS1099Management: Codeunit "IRS 1099 Management";
        FormTypeIndex: Integer;
    begin
        EntryAppMgt.GetAppliedVendorEntries(TempApplVendorLedgerEntry, VendorNo, StartEndDate, true);
        for FormTypeIndex := 1 to FormTypeCount do begin
            TempApplVendorLedgerEntry.SetFilter("Document Type", '%1|%2', Enum::"Gen. Journal Document Type"::Invoice, Enum::"Gen. Journal Document Type"::"Credit Memo");
            TempApplVendorLedgerEntry.SetFilter("IRS 1099 Amount", '<>0');
            TempApplVendorLedgerEntry.SetFilter("IRS 1099 Code", IRS1099CodeFilter[FormTypeIndex]);
            if TempApplVendorLedgerEntry.FindSet() then
                repeat
                    Calculate1099Amount(TempApplVendorLedgerEntry, FormTypeIndex);
                    if IRS1099Management.GetAdjustmentRec(IRS1099Adjustment, TempApplVendorLedgerEntry) then begin
                        TempIRS1099Adjustment := IRS1099Adjustment;
                        if not TempIRS1099Adjustment.Find() then begin
                            MagMediaManagement.UpdateLines(
                                TempApplVendorLedgerEntry, FormTypeIndex, FormTypeLastNo[FormTypeIndex], TempApplVendorLedgerEntry."IRS 1099 Code", IRS1099Adjustment.Amount);
                            TempIRS1099Adjustment.Insert();
                        end;
                    end;
                until TempApplVendorLedgerEntry.Next() = 0;
            AddAdjustments(TempIRS1099Adjustment, VendorNo, StartEndDate[1], FormTypeIndex, IRS1099CodeFilter[FormTypeIndex]);
        end;
    end;

    local procedure AddAdjustments(var TempIRS1099Adjustment: Record "IRS 1099 Adjustment" temporary; VendorNo: Code[20]; StartingDate: Date; FormTypeIndex: Integer; IRSCodeFilter: Text)
    var
        DummyVendorLedgerEntry: Record "Vendor Ledger Entry";
        IRS1099FormBox: Record "IRS 1099 Form-Box";
        IRS1099Adjustment: Record "IRS 1099 Adjustment";
        Year: Integer;
    begin
        if VendorNo = '' then
            exit;
        if IRSCodeFilter = '' then
            exit;
        IRS1099FormBox.SetFilter(Code, IRSCodeFilter);
        if not IRS1099FormBox.FindSet() then
            exit;
        Year := Date2DMY(StartingDate, 3);
        repeat
            if not TempIRS1099Adjustment.Get(VendorNo, IRS1099FormBox.Code, Year) then
                if IRS1099Adjustment.Get(VendorNo, IRS1099FormBox.Code, Year) then begin
                    MagMediaManagement.UpdateLines(
                        DummyVendorLedgerEntry, FormTypeIndex, FormTypeLastNo[FormTypeIndex], IRS1099Adjustment."IRS 1099 Code", IRS1099Adjustment.Amount);
                    TempIRS1099Adjustment := IRS1099Adjustment;
                    TempIRS1099Adjustment.Insert();
                end;
        until IRS1099FormBox.Next() = 0;
    end;

    local procedure Calculate1099Amount(AppliedVendorLedgerEntry: Record "Vendor Ledger Entry"; FormTypeIndex: Integer)
    begin
        AppliedVendorLedgerEntry.CalcFields(Amount);
        Invoice1099Amount := -AppliedVendorLedgerEntry."Amount to Apply" * AppliedVendorLedgerEntry."IRS 1099 Amount" / AppliedVendorLedgerEntry.Amount;
        MagMediaManagement.UpdateLines(AppliedVendorLedgerEntry, FormTypeIndex, FormTypeLastNo[FormTypeIndex], AppliedVendorLedgerEntry."IRS 1099 Code", Invoice1099Amount);
    end;

    local procedure GetForeignEntityIndicator(TempVendorInformation: Record "Company Information" temporary): Text[1]
    var
        PostCode: Record "Post Code";
    begin
        PostCode.SetRange(Code, TempVendorInformation."Post Code");
        PostCode.SetRange(City, TempVendorInformation.City);
        if PostCode.FindFirst() then
            if PostCode."Country/Region Code" in ['US', 'USA'] then
                exit(' ')
            else
                exit('1');
        exit(' ');
    end;

    procedure WriteTRec()
    begin
        // T Record - 1 per transmission, 750 length
        IncrementSequenceNo();
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
          StrSubstNo('#1######', MagMediaManagement.FormatAmount(PayeeCountTotal, 8)) + // Payee total
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
          StrSubstNo('#1######################################', TempVendorInfo.Name) +
          StrSubstNo('#1######################################', TempVendorInfo.Address) +
          StrSubstNo('#1######################################', TempVendorInfo.City) +
          StrSubstNo('#1', CopyStr(TempVendorInfo.County, 1, 2)) +
          StrSubstNo('#1#######', MagMediaManagement.StripNonNumerics(TempVendorInfo."Post Code")) +
          StrSubstNo('#1######################################', VendContactName) +
          StrSubstNo('#1#############', VendContactPhoneNo) +
          StrSubstNo('#1##################', TempVendorInfo."E-Mail") + // 20 chars
          StrSubstNo('               ') +
          StrSubstNo('%1', GetForeignEntityIndicator(TempVendorInfo)) + // position 740
          StrSubstNo('          '));

    end;

    procedure WriteARec()
    begin
        // A Record - 1 per Payer per 1099 type, 750 length
        IncrementSequenceNo();
        IRSData.Write(StrSubstNo('A') +
          StrSubstNo('#1##', CopyStr(Format(Year), 1, 4)) +
          StrSubstNo('      ') + // 6 blanks
          StrSubstNo('#1#######', MagMediaManagement.StripNonNumerics(CompanyInfo."Federal ID No.")) + // TIN
          StrSubstNo('#1##', '    ') + // Payer Name Control
          StrSubstNo(' ') +
          StrSubstNo(ReturnType[FormType]) +
          StrSubstNo('#1##############', CodeNos[FormType]) + // Amount Codes  16
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
        IncrementSequenceNo();
        IRSData.Write(GetMiscBRec());
    end;

    local procedure AddMiscBRecLine()
    begin
        IRSVendorLines.Get(MiscTypeIndex).Add(GetMiscBRec());
    end;

    local procedure GetMiscBRec(): Text
    var
        FormTypeIndex: Integer;
        LastNo: Integer;
    begin
        FormTypeIndex := MiscTypeIndex;
        LastNo := FormTypeLastNo[MiscTypeIndex];

        exit(
            StrSubstNo('B') +
            StrSubstNo('#1##', CopyStr(Format(Year), 1, 4)) +
            StrSubstNo(' ') + // correction indicator
            StrSubstNo('    ') + // name control
            StrSubstNo(' ') + // Type of TIN
            StrSubstNo('#1#######', MagMediaManagement.StripNonNumerics(VendorData."Federal ID No.")) + // TIN
            StrSubstNo('#1##################', VendorData."No.") + // Payer's Payee Account #
            StrSubstNo('              ') + // Blank 14
            StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
                MagMediaManagement.GetAmt(GetFullMiscCode(1), FormTypeIndex, LastNo), 12)) + // Payment 1
            StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
                MagMediaManagement.GetAmt(GetFullMiscCode(2), FormTypeIndex, LastNo), 12)) +
            StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
                MagMediaManagement.GetAmt(GetFullMiscCode(3), FormTypeIndex, LastNo), 12)) +
            StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
                MagMediaManagement.GetAmt(GetFullMiscCode(4), FormTypeIndex, LastNo), 12)) +
            StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
                MagMediaManagement.GetAmt(GetFullMiscCode(5), FormTypeIndex, LastNo), 12)) +
            StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
                MagMediaManagement.GetAmt(GetFullMiscCode(6), FormTypeIndex, LastNo), 12)) +
            StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(0, 12)) +
            StrSubstNo(GetHashTagStringWithLength(12), MagMediaManagement.FormatMoneyAmount(
                MagMediaManagement.GetAmt(GetFullMiscCode(8), FormTypeIndex, LastNo), 12)) +
            StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(0, 12)) +
            StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
                MagMediaManagement.GetAmt(GetFullMiscCode(9), FormTypeIndex, LastNo), 12)) +
            StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
                MagMediaManagement.GetAmt(GetFullMiscCode(14), FormTypeIndex, LastNo), 12)) +
            StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
                MagMediaManagement.GetAmt(GetFullMiscCode(10), FormTypeIndex, LastNo), 12)) +
            StrSubstNo(GetHashTagStringWithLength(12), MagMediaManagement.FormatMoneyAmount(
                MagMediaManagement.GetAmt(GetFullMiscCode(12), FormTypeIndex, LastNo), 12)) +
            StrSubstNo(GetHashTagStringWithLength(12), MagMediaManagement.FormatMoneyAmount(0, 12)) +
            StrSubstNo(GetHashTagStringWithLength(12), MagMediaManagement.FormatMoneyAmount(
                MagMediaManagement.GetAmt(GetFullMiscCode(11), FormTypeIndex, LastNo), 12)) + // Fish purchased for resale
            StrSubstNo(GetHashTagStringWithLength(12), MagMediaManagement.FormatMoneyAmount(0, 12)) +
            StrSubstNo(GetHashTagStringWithLength(12), MagMediaManagement.FormatMoneyAmount(0, 12)) +
            StrSubstNo(GetHashTagStringWithLength(12), MagMediaManagement.FormatMoneyAmount(0, 12)) +
            StrSubstNo('                ') + // blank 16
            StrSubstNo(' ') + // Foreign Country Indicator
            StrSubstNo('#1######################################', VendorData.Name) +
            StrSubstNo('#1######################################', VendorData."Name 2") +
            StrSubstNo('#1######################################', VendorData.Address) +
            StrSubstNo('                                        ') + // blank 40
            StrSubstNo('#1######################################', VendorData.City) +
            StrSubstNo('#1', VendorData.County) +
            StrSubstNo('#1#######', VendorData."Post Code") +
            StrSubstNo(' ') +
            StrSubstNo('#1######', MagMediaManagement.FormatAmount(SequenceNo, 8)) + // sequence number for all rec types
            StrSubstNo('                                    ') +
            StrSubstNo(' ') + // Second TIN Notice (Optional) (544)
            StrSubstNo('  ') + // Blank (545-546)
            StrSubstNo(DirectSales) + // Direct Sales Indicator (547)
            StrSubstNo(Format(VendorData."FATCA filing requirement", 0, 2)) + // FATCA Filing Requirement Indicator (548)
            StrSubstNo('                                                  ') +
            StrSubstNo('                                                  ') +
            StrSubstNo('              ') + // Blank (549-662)
            StrSubstNo('                                                  ') +
            StrSubstNo('          ') + // Special Data Entries (663-722)
            StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
                MagMediaManagement.GetAmt(GetFullMiscCode(15), FormTypeIndex, LastNo), 12)) + // State Income Tax Withheld (723-734)
            StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(0, 12)) + // Local Income Tax Withheld (735-746)
            StrSubstNo('  ') + // Combined Federal/State Code (747-748)
            StrSubstNo('  ')   // Blank (749-750)
        );
    end;

    procedure WriteDivBRec()
    begin
        IncrementSequenceNo();
        IRSData.Write(GetDivBRec());
    end;

    local procedure AddDivBRecLine()
    begin
        IRSVendorLines.Get(DivTypeIndex).Add(GetDivBRec());
    end;

    local procedure GetDivBRec(): Text
    var
        FormTypeIndex: Integer;
        LastNo: Integer;
    begin
        FormTypeIndex := DivTypeIndex;
        LastNo := FormTypeLastNo[DivTypeIndex];

        exit(
            StrSubstNo('B') + // Type (1)
            StrSubstNo('#1##', CopyStr(Format(Year), 1, 4)) + // Payment Year (2-5)
            StrSubstNo(' ') + // Corrected Return Indicator (6)
            StrSubstNo('    ') + // Name Control (7-10)
            StrSubstNo(' ') + // Type of TIN (11)
            StrSubstNo('#1#######', MagMediaManagement.StripNonNumerics(VendorData."Federal ID No.")) + // Payee's TIN (12-20)
            StrSubstNo('#1##################', VendorData."No.") + // Payer's Account Number for Payee (21-40)
            StrSubstNo('              ') + // Payer's Office Code (41-44) and Blank (45-54)
            StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
                MagMediaManagement.GetAmt('DIV-01-A', FormTypeIndex, LastNo) +
                MagMediaManagement.GetAmt('DIV-01-B', FormTypeIndex, LastNo) +
                MagMediaManagement.GetAmt('DIV-05', FormTypeIndex, LastNo) +
                MagMediaManagement.GetAmt('DIV-06', FormTypeIndex, LastNo), 12)) + // ordinary dividends 1 (55-66)
            StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
                MagMediaManagement.GetAmt('DIV-01-B', FormTypeIndex, LastNo), 12)) + // 2 (67-78)
            StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
                MagMediaManagement.GetAmt('DIV-02-A', FormTypeIndex, LastNo) +
                MagMediaManagement.GetAmt('DIV-02-B', FormTypeIndex, LastNo) +
                MagMediaManagement.GetAmt('DIV-02-C', FormTypeIndex, LastNo) +
                MagMediaManagement.GetAmt('DIV-02-D', FormTypeIndex, LastNo), 12)) + // total capital gains 3 (79-90)
            StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(0, 12)) + // 4 (91-102)
            StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
                MagMediaManagement.GetAmt('DIV-05', FormTypeIndex, LastNo), 12)) + // 5-Section 199A Dividends (103-114)
            StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
                MagMediaManagement.GetAmt('DIV-02-B', FormTypeIndex, LastNo), 12)) + // 6-Unrecaptured Section 1250 gain (115-126)
            StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
                MagMediaManagement.GetAmt('DIV-02-C', FormTypeIndex, LastNo), 12)) + // 7-Section 1202 gain (127-138)
            StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
                MagMediaManagement.GetAmt('DIV-02-D', FormTypeIndex, LastNo), 12)) + // 8-Collectibles (28%) gain (139-150)
            StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
                MagMediaManagement.GetAmt('DIV-03', FormTypeIndex, LastNo), 12)) + // 9-Nondividend distributions (151-162)
            StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
                MagMediaManagement.GetAmt('DIV-04', FormTypeIndex, LastNo), 12)) + // fed W/H A (163-174)
            StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
                MagMediaManagement.GetAmt('DIV-06', FormTypeIndex, LastNo), 12)) + // investment. expenses B (175-186)
            StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
                MagMediaManagement.GetAmt('DIV-07', FormTypeIndex, LastNo), 12)) + // Foreign Taxc Paid C (187-198)
            StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
                MagMediaManagement.GetAmt('DIV-09', FormTypeIndex, LastNo), 12)) + // cash liquidation D (199-210)
            StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
                MagMediaManagement.GetAmt('DIV-10', FormTypeIndex, LastNo), 12)) + // non-cash liquidation E (211-222)
            StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
                MagMediaManagement.GetAmt('DIV-12', FormTypeIndex, LastNo), 12)) + // Exempt-interest dividends F (223-234)
            StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
                MagMediaManagement.GetAmt('DIV-13', FormTypeIndex, LastNo), 12)) + // Specified private activity bond... G (235-246)
            StrSubstNo(GetHashTagStringWithLength(12), MagMediaManagement.FormatMoneyAmount(
                MagMediaManagement.GetAmt('DIV-02-E', FormTypeIndex, LastNo), 12)) + // Section 897 Ordinary Dividens (247-258)
            StrSubstNo(GetHashTagStringWithLength(12), MagMediaManagement.FormatMoneyAmount(
                MagMediaManagement.GetAmt('DIV-02-F', FormTypeIndex, LastNo), 12)) + // Section 897 Capital Gains (259-270)
            GetBlankedStringWithLength(16) + // blank 16 (271-286)
            GetBlankedStringWithLength(1) + // Foreign Country Indicator (287)
            StrSubstNo(GetHashTagStringWithLength(40), GetFullVendorName(VendorData)) +
            GetBlankedStringWithLength(40) + // blank 40
            StrSubstNo(GetHashTagStringWithLength(40), VendorData.Address) +
            GetBlankedStringWithLength(40) + // blank 40
            StrSubstNo(GetHashTagStringWithLength(40), VendorData.City) +
            StrSubstNo('#1', VendorData.County) +
            StrSubstNo('#1#######', VendorData."Post Code") +
            StrSubstNo(' ') +
            StrSubstNo('#1######', MagMediaManagement.FormatAmount(SequenceNo, 8)) + // sequence (500-507) number for all rec types
            StrSubstNo('                                    ') +
            StrSubstNo(' ') + // Second TIN Notice (Optional) (544)
            StrSubstNo('  ') + // Blank (545-546)
            StrSubstNo('                                        ') + // Foreign Country or U.S. Possession (547-586)
            StrSubstNo(Format(VendorData."FATCA filing requirement", 0, 2)) + // FATCA Filing Requirement Indicator (587)
            StrSubstNo('                                                  ') +
            StrSubstNo('                         ') + // Blank (588-662)
            StrSubstNo('                                                  ') +
            StrSubstNo('          ') + // Special Data Entries (663-722)
            StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(0, 12)) + // State Income Tax Withheld (723-734)
            StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(0, 12)) + // Local Income Tax Withheld (735-746)
            StrSubstNo('  ') + // Combined Federal/State Code (747-748)
            StrSubstNo('  ') // Blank (749-750)
        );
    end;

    procedure WriteIntBRec()
    begin
        IncrementSequenceNo();
        IRSData.Write(GetIntBRec());
    end;

    local procedure AddIntBRecLine()
    begin
        IRSVendorLines.Get(IntTypeIndex).Add(GetIntBRec());
    end;

    local procedure GetIntBRec(): Text
    var
        FormTypeIndex: Integer;
        LastNo: Integer;
    begin
        FormTypeIndex := IntTypeIndex;
        LastNo := FormTypeLastNo[IntTypeIndex];

        exit(
            StrSubstNo('B') +
            StrSubstNo('#1##', CopyStr(Format(Year), 1, 4)) +
            StrSubstNo(' ') + // correction indicator
            StrSubstNo('    ') + // name control
            StrSubstNo(' ') + // Type of TIN
            StrSubstNo('#1#######', MagMediaManagement.StripNonNumerics(VendorData."Federal ID No.")) + // TIN
            StrSubstNo('#1##################', VendorData."No.") + // Payer's Payee Account #
            StrSubstNo('              ') + // Blank 14
            StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
                MagMediaManagement.GetAmt('INT-01', FormTypeIndex, LastNo), 12)) +
            StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
                MagMediaManagement.GetAmt('INT-02', FormTypeIndex, LastNo), 12)) +
            StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
                MagMediaManagement.GetAmt('INT-03', FormTypeIndex, LastNo), 12)) +
            StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
                MagMediaManagement.GetAmt('INT-04', FormTypeIndex, LastNo), 12)) +
            StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
                MagMediaManagement.GetAmt('INT-05', FormTypeIndex, LastNo), 12)) +
            StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
                MagMediaManagement.GetAmt('INT-06', FormTypeIndex, LastNo), 12)) +
            StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(0, 12)) +
            StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
                MagMediaManagement.GetAmt('INT-08', FormTypeIndex, LastNo) +
                MagMediaManagement.GetAmt('INT-09', FormTypeIndex, LastNo), 12)) +
            StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
                MagMediaManagement.GetAmt('INT-09', FormTypeIndex, LastNo), 12)) +
            StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
                MagMediaManagement.GetAmt('INT-10', FormTypeIndex, LastNo), 12)) +
            StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
                MagMediaManagement.GetAmt('INT-11', FormTypeIndex, LastNo), 12)) +
            StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(0, 12)) +
            StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
                MagMediaManagement.GetAmt('INT-13', FormTypeIndex, LastNo), 12)) +
            StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(
                MagMediaManagement.GetAmt('INT-12', FormTypeIndex, LastNo), 12)) +
            StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(0, 12)) +
            StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(0, 12)) +
            StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(0, 12)) +
            StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(0, 12)) +
            StrSubstNo('                ') + // blank 16
            StrSubstNo(' ') + // Foreign Country Indicator
            StrSubstNo('#1######################################', VendorData.Name) +
            StrSubstNo('#1######################################', VendorData."Name 2") +
            StrSubstNo('#1######################################', VendorData.Address) +
            StrSubstNo('                                        ') + // blank 40
            StrSubstNo('#1######################################', VendorData.City) +
            StrSubstNo('#1', VendorData.County) +
            StrSubstNo('#1#######', VendorData."Post Code") +
            StrSubstNo(' ') +
            StrSubstNo('#1######', MagMediaManagement.FormatAmount(SequenceNo, 8)) + // sequence number for all rec types
            StrSubstNo('                                    ') +
            StrSubstNo(' ') + // Second TIN Notice (Optional) (544)
            StrSubstNo('  ') + // Blank (545-546)
            StrSubstNo('                                        ') + // Foreign Country or U.S. Possession (547-586)
            StrSubstNo('             ') + // CUSIP Number (587-599)
            StrSubstNo(Format(VendorData."FATCA filing requirement", 0, 2)) + // FATCA Filing Requirement Indicator (600)
            StrSubstNo('                                                  ') +
            StrSubstNo('            ') + // Blank (601-662)
            StrSubstNo('                                                  ') +
            StrSubstNo('          ') + // Special Data Entries (663-722)
            StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(0, 12)) + // State Income Tax Withheld (723-734)
            StrSubstNo('#1##########', MagMediaManagement.FormatMoneyAmount(0, 12)) + // Local Income Tax Withheld (735-746)
            StrSubstNo('  ') + // Combined Federal/State Code (747-748)
            StrSubstNo('  ') // Blank (749-750)
          );
    end;

    procedure WriteNecBRec()
    begin
        IncrementSequenceNo();
        IRSData.Write(GetNecBRec());
    end;

    local procedure AddNecBRecLine()
    begin
        IRSVendorLines.Get(NecTypeIndex).Add(GetNecBRec());
    end;

    local procedure GetNecBRec(): Text
    var
        FormTypeIndex: Integer;
        LastNo: Integer;
    begin
        FormTypeIndex := NecTypeIndex;
        LastNo := FormTypeLastNo[NecTypeIndex];

        exit(
            StrSubstNo('B') +
            StrSubstNo('#1##', CopyStr(Format(Year), 1, 4)) +
            ' ' +
            '    ' +
            ' ' +
            StrSubstNo(GetHashTagStringWithLength(9), MagMediaManagement.StripNonNumerics(VendorData."Federal ID No.")) +
            StrSubstNo(GetHashTagStringWithLength(20), VendorData."No.") +
            '              ' +
            StrSubstNo(GetHashTagStringWithLength(12), MagMediaManagement.FormatMoneyAmount(
                MagMediaManagement.GetAmt(GetFullNecCode(1), FormTypeIndex, LastNo), 12)) +
            StrSubstNo(GetHashTagStringWithLength(12), MagMediaManagement.FormatMoneyAmount(0, 12)) +
            StrSubstNo(GetHashTagStringWithLength(12), MagMediaManagement.FormatMoneyAmount(0, 12)) +
            StrSubstNo(GetHashTagStringWithLength(12), MagMediaManagement.FormatMoneyAmount(
                MagMediaManagement.GetAmt(GetFullNecCode(4), FormTypeIndex, LastNo), 12)) +
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
            StrSubstNo(GetHashTagStringWithLength(12), MagMediaManagement.FormatMoneyAmount(0, 12)) +
            StrSubstNo(GetHashTagStringWithLength(12), MagMediaManagement.FormatMoneyAmount(0, 12)) +
            '                ' + // blank 16
            ' ' +
            StrSubstNo(GetHashTagStringWithLength(40), VendorData.Name) +
            StrSubstNo(GetHashTagStringWithLength(40), VendorData."Name 2") +
            StrSubstNo(GetHashTagStringWithLength(40), VendorData.Address) +
            '                                        ' +
            StrSubstNo(GetHashTagStringWithLength(40), VendorData.City) +
            StrSubstNo(GetHashTagStringWithLength(0), VendorData.County) +
            StrSubstNo(GetHashTagStringWithLength(9), VendorData."Post Code") +
            ' ' +
            StrSubstNo(GetHashTagStringWithLength(8), MagMediaManagement.FormatAmount(SequenceNo, 8)) +
            '                                    ' +
            ' ' +
            '   ' +
            StrSubstNo(Format(VendorData."FATCA filing requirement", 0, 2)) +
            '                                                  ' +
            '                                                  ' +
            '              ' +
            '                                                  ' +
            '          ' +
            StrSubstNo(GetHashTagStringWithLength(12), MagMediaManagement.FormatMoneyAmount(0, 12)) +
            StrSubstNo(GetHashTagStringWithLength(12), MagMediaManagement.FormatMoneyAmount(0, 12)) +
            '  ' +
            '  '
        );
    end;

    procedure WriteMISCCRec()
    var
        FormTypeIndex: Integer;
        LastNo: Integer;
    begin
        FormTypeIndex := MiscTypeIndex;
        LastNo := FormTypeLastNo[MiscTypeIndex];

        // C Record - 1 per Payer per 1099 type
        IncrementSequenceNo();
        IRSData.Write(StrSubstNo('C') +
          StrSubstNo('#1######', MagMediaManagement.FormatAmount(PayeeCount[MiscTypeIndex], 8)) +
          StrSubstNo('      ') + // Blank 6
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal(GetFullMiscCode(1), FormTypeIndex, LastNo), 18)) + // Payment 1
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal(GetFullMiscCode(2), FormTypeIndex, LastNo), 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal(GetFullMiscCode(3), FormTypeIndex, LastNo), 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal(GetFullMiscCode(4), FormTypeIndex, LastNo), 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal(GetFullMiscCode(5), FormTypeIndex, LastNo), 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal(GetFullMiscCode(6), FormTypeIndex, LastNo), 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(0, 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal(GetFullMiscCode(8), FormTypeIndex, LastNo), 18)) +
          StrSubstNo(GetHashTagStringWithLength(18), MagMediaManagement.FormatMoneyAmount(0, 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal(GetFullMiscCode(9), FormTypeIndex, LastNo), 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal(GetFullMiscCode(14), FormTypeIndex, LastNo), 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal(GetFullMiscCode(10), FormTypeIndex, LastNo), 18)) +
          StrSubstNo(GetHashTagStringWithLength(18), MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal(GetFullMiscCode(12), FormTypeIndex, LastNo), 18)) +
          StrSubstNo(GetHashTagStringWithLength(18), MagMediaManagement.FormatMoneyAmount(0, 18)) +
          StrSubstNo(GetHashTagStringWithLength(18), MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal(GetFullMiscCode(11), FormTypeIndex, LastNo), 18)) +
          StrSubstNo(GetHashTagStringWithLength(18), MagMediaManagement.FormatMoneyAmount(0, 18)) +
          StrSubstNo(GetHashTagStringWithLength(18), MagMediaManagement.FormatMoneyAmount(0, 18)) +
          StrSubstNo(GetHashTagStringWithLength(18), MagMediaManagement.FormatMoneyAmount(0, 18)) +
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

    procedure WriteDIVCRec()
    var
        FormTypeIndex: Integer;
        LastNo: Integer;
    begin
        FormTypeIndex := DivTypeIndex;
        LastNo := FormTypeLastNo[DivTypeIndex];

        // C Record - 1 per Payer per 1099 type
        IncrementSequenceNo();
        IRSData.Write(StrSubstNo('C') +
          StrSubstNo('#1######', MagMediaManagement.FormatAmount(PayeeCount[DivTypeIndex], 8)) +
          StrSubstNo('      ') + // Blank 6
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(// ordinary dividends
              MagMediaManagement.GetTotal('DIV-01-A', FormTypeIndex, LastNo) +
              MagMediaManagement.GetTotal('DIV-01-B', FormTypeIndex, LastNo) +
              MagMediaManagement.GetTotal('DIV-05', FormTypeIndex, LastNo) +
              MagMediaManagement.GetTotal('DIV-06', FormTypeIndex, LastNo), 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal('DIV-01-B', FormTypeIndex, LastNo), 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(// total capital gains
              MagMediaManagement.GetTotal('DIV-02-A', FormTypeIndex, LastNo) +
              MagMediaManagement.GetTotal('DIV-02-B', FormTypeIndex, LastNo) +
              MagMediaManagement.GetTotal('DIV-02-C', FormTypeIndex, LastNo) +
              MagMediaManagement.GetTotal('DIV-02-D', FormTypeIndex, LastNo), 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(0, 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal('DIV-05', FormTypeIndex, LastNo), 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal('DIV-02-B', FormTypeIndex, LastNo), 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal('DIV-02-C', FormTypeIndex, LastNo), 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal('DIV-02-D', FormTypeIndex, LastNo), 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(// Nondividend dist. 9
              MagMediaManagement.GetTotal('DIV-03', FormTypeIndex, LastNo), 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(// fed income tax W/H A
              MagMediaManagement.GetTotal('DIV-04', FormTypeIndex, LastNo), 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(// investment. expenses B
              MagMediaManagement.GetTotal('DIV-06', FormTypeIndex, LastNo), 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal('DIV-07', FormTypeIndex, LastNo), 18)) + // Foreign Taxc Paid C
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal('DIV-09', FormTypeIndex, LastNo), 18)) + // cash liquidation D
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal('DIV-10', FormTypeIndex, LastNo), 18)) + // non-cash liquidation E
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal('DIV-12', FormTypeIndex, LastNo), 18)) + // Exempt-interest dividends F
          StrSubstNo(GetHashTagStringWithLength(18), MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal('DIV-13', FormTypeIndex, LastNo), 18)) + // Specified private activity bond interest dividends G
          StrSubstNo(GetHashTagStringWithLength(18), MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal('DIV-02-E', FormTypeIndex, LastNo), 18)) + // Specified 897 Ordinary Dividends
          StrSubstNo(GetHashTagStringWithLength(18), MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal('DIV-02-F', FormTypeIndex, LastNo), 18)) + // Specified 897 Capital Gains
          GetBlankedStringWithLength(160) +
          StrSubstNo('#1######', MagMediaManagement.FormatAmount(SequenceNo, 8)) + // sequence number for all rec types
          StrSubstNo('                                                  ') +
          StrSubstNo('                                                  ') +
          StrSubstNo('                                                  ') +
          StrSubstNo('                                                  ') +
          StrSubstNo('                                           '));
    end;

    procedure WriteINTCRec()
    var
        FormTypeIndex: Integer;
        LastNo: Integer;
    begin
        FormTypeIndex := IntTypeIndex;
        LastNo := FormTypeLastNo[IntTypeIndex];

        // C Record - 1 per Payer per 1099 type
        IncrementSequenceNo();
        IRSData.Write(StrSubstNo('C') +
          StrSubstNo('#1######', MagMediaManagement.FormatAmount(PayeeCount[IntTypeIndex], 8)) +
          StrSubstNo('      ') + // Blank 6
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal('INT-01', FormTypeIndex, LastNo), 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal('INT-02', FormTypeIndex, LastNo), 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal('INT-03', FormTypeIndex, LastNo), 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal('INT-04', FormTypeIndex, LastNo), 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal('INT-05', FormTypeIndex, LastNo), 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal('INT-06', FormTypeIndex, LastNo), 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(0, 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal('INT-08', FormTypeIndex, LastNo) +
              MagMediaManagement.GetTotal('INT-09', FormTypeIndex, LastNo), 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal('INT-09', FormTypeIndex, LastNo), 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal('INT-10', FormTypeIndex, LastNo), 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal('INT-11', FormTypeIndex, LastNo), 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(0, 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal('INT-13', FormTypeIndex, LastNo), 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal('INT-12', FormTypeIndex, LastNo), 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(0, 18)) +
          StrSubstNo('#1################', MagMediaManagement.FormatMoneyAmount(0, 18)) +
          StrSubstNo(GetHashTagStringWithLength(18), MagMediaManagement.FormatMoneyAmount(0, 18)) +
          StrSubstNo(GetHashTagStringWithLength(18), MagMediaManagement.FormatMoneyAmount(0, 18)) +
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

    procedure WriteNECCRec()
    var
        FormTypeIndex: Integer;
        LastNo: Integer;
    begin
        FormTypeIndex := NecTypeIndex;
        LastNo := FormTypeLastNo[NecTypeIndex];

        // C Record - 1 per Payer per 1099 type
        IncrementSequenceNo();
        IRSData.Write(StrSubstNo('C') +
          StrSubstNo(GetHashTagStringWithLength(8), MagMediaManagement.FormatAmount(PayeeCount[NecTypeIndex], 8)) +
          '      ' +
          StrSubstNo(GetHashTagStringWithLength(18), MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal(GetFullNecCode(1), FormTypeIndex, LastNo), 18)) +
          StrSubstNo(GetHashTagStringWithLength(18), MagMediaManagement.FormatMoneyAmount(0, 18)) +
          StrSubstNo(GetHashTagStringWithLength(18), MagMediaManagement.FormatMoneyAmount(0, 18)) +
          StrSubstNo(GetHashTagStringWithLength(18), MagMediaManagement.FormatMoneyAmount(
              MagMediaManagement.GetTotal(GetFullNecCode(4), FormTypeIndex, LastNo), 18)) +
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
          StrSubstNo(GetHashTagStringWithLength(18), MagMediaManagement.FormatMoneyAmount(0, 18)) +
          StrSubstNo(GetHashTagStringWithLength(18), MagMediaManagement.FormatMoneyAmount(0, 18)) +
          '                                                  ' +
          '                                                  ' +
          '                                                  ' +
          '          ' +
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
        IncrementSequenceNo();
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
        if Number < 10 then
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

    local procedure GetBlankedStringWithLength(Length: Integer) Result: Text
    var
        j: Integer;
    begin
        for j := 1 to Length do
            Result += BlankTagTok;
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

    local procedure GetFullVendorName(Vendor: Record Vendor): Text
    begin
        exit(Vendor.Name + Vendor."Name 2");
    end;

    local procedure UpdateSequenceNoInRecLine(var RecLine: Text)
    var
        StartString: Text;
        EndString: Text;
        SequenceText: Text;
        SeqNoStartPos: Integer;
        SeqNoEndPos: Integer;
    begin
        SeqNoStartPos := 500;
        SeqNoEndPos := 507;
        StartString := RecLine.Substring(1, SeqNoStartPos - 1); // before the sequence number
        EndString := RecLine.Substring(SeqNoEndPos + 1);        // after the sequence number
        SequenceText := MagMediaManagement.FormatAmount(SequenceNo, 8);
        RecLine := StartString + SequenceText + EndString;      // insert sequence number to 500-507 position
    end;

    local procedure UpdateProgressDialog(Number: Integer; NewText: Text)
    begin
        if GuiAllowed() then
            ProgressDialog.Update(Number, NewText + '%');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDownloadFile(var TempBlob: Codeunit "Temp Blob")
    begin
    end;
}

#endif