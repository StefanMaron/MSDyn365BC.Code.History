#if not CLEAN22
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Finance.AuditFileExport;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Period;
using System.Environment;
using System.IO;
using System.Telemetry;

report 11207 "SIE Export"
{
    ApplicationArea = Basic, Suite;
    Caption = 'SIE Export';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;
    ObsoleteReason = 'Use Audit File Export Document with the SIE format selected in the Standard Import Export (SIE) extension';
    ObsoleteState = Pending;
    ObsoleteTag = '22.0';

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = where("Account Type" = const(Posting));
            RequestFilterFields = "No.", "Income/Balance", "Date Filter";
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
                    field(ExportType; ExportType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'File Type';
                        OptionCaption = '1. Year - End Balances,2. Periodic Balances,3. Object Balances,4. Transactions';
                        ToolTip = 'Specifies the type of SIE file to create.';
                    }
                    field(Contact; Contact)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Contact';
                        ToolTip = 'Specifies the name of the contact.';
                    }
                    field(Comment; Comment)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Comments';
                        ToolTip = 'Specifies comments about the content of the file.';
                    }
                    field(ColumnDim; ColumnDim)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Dimensions';
                        Editable = false;
                        ToolTip = 'Specifies the dimensions covered by the export process.';

                        trigger OnAssistEdit()
                        begin
                            Clear(SieDimensionPage);
                            SieDimensionPage.LookupMode(true);
                            SieDimensionPage.Run();
                            ColumnDim := SieDimension.GetDimSelectionText();
                        end;
                    }
                    field(FiscalYear; FiscalYear)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Fiscal Year';
                        Numeric = true;
                        ToolTip = 'Specifies the tax year that the export process refers to';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            ColumnDim := SieDimension.GetDimSelectionText();
            OnActivateForm();
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        SieeTok: Label 'SE SIEE Data', Locked = true;
    begin
        FeatureTelemetry.LogUptake('0001P9D', SieeTok, Enum::"Feature Uptake Status"::"Used");
        ExportFile.Close();
        if ServerFileName = '' then
            FileMgt.DownloadHandler(ServerTempFilename, '', '', Text001, SIEFileTxt)
        else
            FileMgt.CopyServerFile(ServerTempFilename, ServerFileName, true);
        FileMgt.DeleteServerFile(ServerTempFilename);
        FeatureTelemetry.LogUsage('0001P9E', SieeTok, 'SIEE reported');
    end;

    trigger OnPreReport()
    var
        AccountingPeriod: Record "Accounting Period";
        StartDate: Date;
    begin
        ExportFile.TextMode(true);
        ExportFile.WriteMode(true);
        ServerTempFilename := FileMgt.ServerTempFileName('');
        ExportFile.Create(ServerTempFilename);

        AccountFilter := "G/L Account".GetFilters();
        AccountDateFilter := "G/L Account".GetFilter("Date Filter");
        AccountBudgetFilter := "G/L Account".GetFilter("Budget Filter");

        StartDate := "G/L Account".GetRangeMin("Date Filter");
        AccPeriodStart := AccountingPeriod.GetFiscalYearStartDate(StartDate);
        AccPeriodEnd := AccountingPeriod.GetFiscalYearEndDate(StartDate);

        PrevAccPeriodStart := AccountingPeriod.GetFiscalYearStartDate(AccPeriodStart - 1);
        PrevAccPeriodEnd := AccountingPeriod.GetFiscalYearEndDate(AccPeriodStart - 1);

        GLSetup.Get();
        case ExportType of
            ExportType::"1. Year - End Balances":
                SIEType1();
            ExportType::"2. Periodic Balances":
                SIEType2();
            ExportType::"3. Object Balances":
                SIEType3();
            ExportType::"4. Transactions":
                SIEType4();
        end;
    end;

    var
        SieDimension: Record "SIE Dimension";
        DimensionValue: Record "Dimension Value";
        GLSetup: Record "General Ledger Setup";
        CompanyInfo: Record "Company Information";
        GLEntry: Record "G/L Entry";
        GLAccount: Record "G/L Account";
        GLAccountRec: Record "G/L Account";
        GLAccount2: Record "G/L Account";
        FileMgt: Codeunit "File Management";
        ApplicationSystemConstants: Codeunit "Application System Constants";
        SieDimensionPage: Page "SIE Dimensions";
        DialogWindow: Dialog;
        ExportFile: File;
        ExportType: Option "1. Year - End Balances","2. Periodic Balances","3. Object Balances","4. Transactions";
        Contact: Text[30];
        AccPeriodStart: Date;
        AccPeriodEnd: Date;
        PrevAccPeriodStart: Date;
        PrevAccPeriodEnd: Date;
        Counter: Integer;
        CounterTotal: Integer;
        ObjectExport: Boolean;
        PeriodExport: Boolean;
        Comment: Text[100];
        FiscalYear: Text[4];
        AccountFilter: Text[250];
        AccountDateFilter: Text[30];
        AccountBudgetFilter: Text[30];
        ColumnDim: Text;
        Header: Boolean;
        Text001: Label 'SIE files(*.se)|*.se|All files|*.*';
        Text003: Label 'Creates SIE file                   #1##################\';
        Text004: Label 'SIE type                           #2##################\';
        Text005: Label 'Processing G/L Account             #3#### @4@@@@@@@@@@@\';
        Text006: Label 'Processing periodic balance amount #5#### @6@@@@@@@@@@@\';
        Text007: Label 'Processing object balance amount   #7#### @8@@@@@@@@@@@\';
        Text008: Label 'Processing transactions            #5#### @6@@@@@@@@@@@\';
        ServerTempFilename: Text;
        SIEFileTxt: Label 'SIE.se', Locked = true;
        ServerFileName: Text;

    [Scope('OnPrem')]
    procedure WriteFileheader()
    begin
        DialogWindow.Update(1, '');
        DialogWindow.Update(2, ExportType);

        CompanyInfo.Get();
        ExportFile.Write(StrSubstNo('#FLAGGA  %1', 0));
        ExportFile.Write(StrSubstNo('#PROGRAM  "%1"  "%2"', 'Microsoft Dynamics NAV', ApplicationSystemConstants.ApplicationVersion()));
        ExportFile.Write(StrSubstNo('#FORMAT  %1', 'PC8'));
        ExportFile.Write(StrSubstNo('#GEN  %1  %2', FormatDate(Today), UserId));
        ExportFile.Write(StrSubstNo('#SIETYP  %1', Format(CopyStr(Format(ExportType), 1, 1))));
        if Comment <> '' then
            ExportFile.Write(StrSubstNo('#PROSA  "%1"', Ascii2Ansi(Comment)));
        ExportFile.Write(StrSubstNo('#ORGNR  "%1"', CompanyInfo."Registration No."));
        ExportFile.Write(
          StrSubstNo(
            '#ADRESS  "%1"  "%2"  "%3 %4"  "%5"', Ascii2Ansi(Contact), Ascii2Ansi(CompanyInfo.Address),
            Ascii2Ansi(CompanyInfo."Post Code"), Ascii2Ansi(CompanyInfo.City), CompanyInfo."Phone No."));

        ExportFile.Write(StrSubstNo('#FNAMN  "%1"', Ascii2Ansi(CompanyInfo.Name)));
        ExportFile.Write(StrSubstNo('#RAR  %1  %2  %3', 0, Format(FormatDate(AccPeriodStart), 10), Format(FormatDate(AccPeriodEnd), 10)));
        ExportFile.Write(
          StrSubstNo('#RAR  %1  %2  %3', -1, Format(FormatDate(PrevAccPeriodStart), 10), Format(FormatDate(PrevAccPeriodEnd), 10)));
        if FiscalYear <> '' then
            ExportFile.Write(StrSubstNo('#TAXAR  %1', FiscalYear));

        if PeriodExport or ObjectExport then
            ExportFile.Write(StrSubstNo('#OMFATTN  %1', Format(FormatDate("G/L Account".GetRangeMax("Date Filter")), 10)));
    end;

    [Scope('OnPrem')]
    procedure WriteTransaction()
    var
        DimensionSetEntry: Record "Dimension Set Entry";
        DocNo: Code[20];
        DimensionString: Text[250];
        PostingDate: Date;
    begin
        DocNo := '';
        GLEntry.SetCurrentKey("Document No.", "Posting Date");
        GLEntry.SetFilter("Posting Date", AccountDateFilter);
        CounterTotal := GLEntry.Count();
        if GLEntry.Find('-') then
            repeat
                DimensionString := '';
                Counter := Counter + 1;
                if (GLEntry."Document No." <> DocNo) or
                   (GLEntry."Posting Date" <> PostingDate)
                then
                    WriteTransactionHeader(GLEntry);

                DimensionSetEntry.SetRange("Dimension Set ID", GLEntry."Dimension Set ID");
                if DimensionSetEntry.FindSet() then begin
                    repeat
                        SieDimension.SetRange(Selected, true);
                        SieDimension.SetRange("Dimension Code", DimensionSetEntry."Dimension Code");
                        if SieDimension.FindFirst() then
                            DimensionString :=
                              DimensionString +
                              ' "' + Format(SieDimension."SIE Dimension") + '" "' + DimensionSetEntry."Dimension Value Code" + '"';
                    until DimensionSetEntry.Next() = 0;
                    ExportFile.Write(
                      StrSubstNo('  #TRANS  %1  {%2}  %3  %4',
                        GLEntry."G/L Account No.", Ascii2Ansi(DimensionString),
                        FormatAmount(GLEntry.Amount), FormatDate(GLEntry."Posting Date")));
                end else
                    ExportFile.Write(
                      StrSubstNo('  #TRANS  %1  {}  %2  %3',
                        GLEntry."G/L Account No.", FormatAmount(GLEntry.Amount), FormatDate(GLEntry."Posting Date")));

                DocNo := GLEntry."Document No.";
                PostingDate := GLEntry."Posting Date";
                DialogWindow.Update(5, Counter);
                DialogWindow.Update(6, Round(Counter / CounterTotal * 10000, 1));
            until GLEntry.Next() = 0;
        if DocNo <> '' then
            ExportFile.Write('}');
    end;

    [Scope('OnPrem')]
    procedure WriteTransactionHeader(GLEntry: Record "G/L Entry")
    begin
        DialogWindow.Update(5, GLEntry."Document No.");
        if Header then
            ExportFile.Write('}');
        ExportFile.Write(
          StrSubstNo(
            '#VER  %1  "%2"   %3  "%4"',
            'A', Ascii2Ansi(GLEntry."Document No."), FormatDate(GLEntry."Posting Date"), Ascii2Ansi(GLEntry.Description)));
        ExportFile.Write('{');
        Header := true;
    end;

    [Scope('OnPrem')]
    procedure WriteDimension()
    begin
        SieDimension.SetCurrentKey("SIE Dimension");
        SieDimension.SetRange(Selected, true);
        if SieDimension.Find('-') then
            repeat
                ExportFile.Write(StrSubstNo('#DIM  %1  "%2"', SieDimension."SIE Dimension", Ascii2Ansi(SieDimension."Dimension Code")));
            until SieDimension.Next() = 0;
        if SieDimension.Find('-') then
            repeat
                DimensionValue.SetRange("Dimension Code", SieDimension."Dimension Code");
                if DimensionValue.Find('-') then
                    repeat
                        ExportFile.Write(
                          StrSubstNo(
                            '#OBJEKT  %1  "%2"  "%3"', SieDimension."SIE Dimension", Ascii2Ansi(DimensionValue.Code),
                            Ascii2Ansi(DimensionValue.Name)));
                    until DimensionValue.Next() = 0;
            until SieDimension.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure GLPost()
    begin
        GLAccount.CopyFilters("G/L Account");
        if GLAccount.Find('-') then
            repeat
                ExportFile.Write(StrSubstNo('#KONTO  %1  "%2"', GLAccount."No.", Ascii2Ansi(GLAccount.Name)));
                if FiscalYear <> '' then
                    ExportFile.Write(StrSubstNo('#SRU  %1  %2', GLAccount."No.", GLAccount."SRU-code"));
            until GLAccount.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure GLAccountPost()
    begin
        GLAccount := "G/L Account";
        CounterTotal := GLAccount.Count();
        Counter := 0;
        GLAccount.CopyFilters("G/L Account");
        if GLAccount.Find('-') then
            repeat
                Counter := Counter + 1;
                SetGLFilterPrev(GLAccount2);
                GLAccount2.CalcFields("Balance at Date");

                GLAccount.SetFilter("Date Filter", AccountDateFilter);
                GLAccount.CalcFields("Balance at Date", "Net Change");

                if GLAccount."Income/Balance" = GLAccount."Income/Balance"::"Balance Sheet" then
                    YearBalance()
                else
                    ResultBalance();
                DialogWindow.Update(3, GLAccount."No.");
                DialogWindow.Update(4, Round(Counter / CounterTotal * 10000, 1));
            until GLAccount.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure YearBalance()
    begin
        if (GLAccount."Balance at Date" - GLAccount."Net Change") <> 0 then
            ExportFile.Write(StrSubstNo('#IB  %1  %2  %3', 0, GLAccount."No.", FormatAmount(
                  GLAccount."Balance at Date" - GLAccount."Net Change")));
        if GLAccount."Balance at Date" <> 0 then
            ExportFile.Write(StrSubstNo('#UB  %1  %2  %3', 0, GLAccount."No.", FormatAmount(GLAccount."Balance at Date")));
        if GLAccount2."Balance at Date" <> 0 then
            ExportFile.Write(StrSubstNo('#UB  %1  %2  %3', -1, GLAccount."No.", FormatAmount(GLAccount2."Balance at Date")));
    end;

    [Scope('OnPrem')]
    procedure ResultBalance()
    begin
        if GLAccount."Balance at Date" <> 0 then
            ExportFile.Write(StrSubstNo('#RES  %1  %2  %3', 0, GLAccount."No.", FormatAmount(GLAccount."Balance at Date")));
        if GLAccount2."Balance at Date" <> 0 then
            ExportFile.Write(StrSubstNo('#RES  %1  %2  %3', -1, GLAccount."No.", FormatAmount(GLAccount2."Balance at Date")));
    end;

    [Scope('OnPrem')]
    procedure PeriodicPost()
    begin
        Counter := 0;
        GLAccountRec.Reset();
        GLAccountRec.CopyFilters("G/L Account");
        GLAccountRec.SetRange("Account Type", GLAccountRec."Account Type"::Posting);
        CounterTotal := GLAccountRec.Count();
        if GLAccountRec.Find('-') then
            repeat
                Counter := Counter + 1;
                if not PeriodExport then begin
                    SieDimension.SetCurrentKey("SIE Dimension");
                    SieDimension.SetRange(Selected, true);
                    if SieDimension.Find('-') then
                        repeat
                            DimensionValue.SetRange("Dimension Code", SieDimension."Dimension Code");
                            if DimensionValue.Find('-') then
                                repeat
                                    GLAccount.Reset();
                                    if DimensionValue."Dimension Code" = GLSetup."Global Dimension 1 Code" then begin
                                        GLAccount.SetFilter("Global Dimension 1 Filter", DimensionValue.Code);
                                        GLAccount.SetFilter("Global Dimension 2 Filter", '');
                                    end;
                                    if DimensionValue."Dimension Code" = GLSetup."Global Dimension 2 Code" then begin
                                        GLAccount.SetFilter("Global Dimension 2 Filter", DimensionValue.Code);
                                        GLAccount.SetFilter("Global Dimension 1 Filter", '');
                                    end;
                                    SetGLFilterPrev(GLAccount2);
                                    GLAccount2.CalcFields("Net Change");
                                    GLAccount.SetFilter("Date Filter", AccountDateFilter);
                                    GLAccount.CalcFields("Net Change");
                                    if GLAccount."Net Change" <> 0 then
                                        ExportFile.Write(StrSubstNo('#PSALDO   %1  %2  %3  {%4 "%5"} %6', 0, Format(FormatDate(GLAccount.GetRangeMax
                                                ("Date Filter")), 6), GLAccount."No.", SieDimension."SIE Dimension",
                                            Ascii2Ansi(DimensionValue.Code), FormatAmount(GLAccount."Net Change")));
                                    if GLAccount2."Net Change" <> 0 then
                                        ExportFile.Write(StrSubstNo('#PSALDO  %1  %2  %3  {%4 "%5"} %6', -1, Format(FormatDate(GLAccount2.GetRangeMax
                                                ("Date Filter")), 6), GLAccount2."No.", SieDimension."SIE Dimension",
                                            Ascii2Ansi(DimensionValue.Code), FormatAmount(GLAccount2."Net Change")));
                                    if AccountBudgetFilter <> '' then begin
                                        GLAccount.SetFilter("Date Filter", AccountDateFilter);
                                        GLAccount.SetFilter("Budget Filter", AccountBudgetFilter);
                                        GLAccount.CalcFields("Budget at Date");
                                        if GLAccount."Budgeted Amount" <> 0 then
                                            ExportFile.Write(StrSubstNo('#PBUDGET   %1  %2  %3  {%4 "%5"} %6', 0, Format(FormatDate(GLAccount.GetRangeMax
                                                    ("Date Filter")), 6), GLAccount."No.", SieDimension."SIE Dimension", Ascii2Ansi(DimensionValue.Code),
                                                FormatAmount(GLAccount."Budget at Date")));
                                        GLAccount2.SetRange("Date Filter", PrevAccPeriodStart, PrevAccPeriodEnd);
                                        GLAccount2.SetFilter("Budget Filter", AccountBudgetFilter);
                                        GLAccount2.CalcFields("Budget at Date");
                                        if GLAccount2."Budgeted Amount" <> 0 then
                                            ExportFile.Write(StrSubstNo('#PBUDGET  %1  %2  %3  {%4 "%5"} %6', -1, Format(FormatDate(GLAccount2.GetRangeMax
                                                    ("Date Filter")), 6), GLAccount2."No.", SieDimension."SIE Dimension", Ascii2Ansi(DimensionValue.Code),
                                                FormatAmount(GLAccount2."Budget at Date")));
                                    end;
                                until DimensionValue.Next() = 0;
                        until SieDimension.Next() = 0;
                end;
                GLAccount.Reset();
                GLAccount := GLAccountRec;
                GLAccount.SetFilter("Global Dimension 1 Filter", '');
                GLAccount.SetFilter("Global Dimension 2 Filter", '');
                GLAccount.SetFilter("Date Filter", AccountDateFilter);
                GLAccount.CalcFields("Net Change");
                if GLAccount."Net Change" <> 0 then
                    ExportFile.Write(StrSubstNo('#PSALDO   %1  %2  %3  {} %4', 0, Format(FormatDate(GLAccount.GetRangeMax
                            ("Date Filter")), 6), GLAccount."No.", FormatAmount(GLAccount."Net Change")));

                SetGLFilterPrev(GLAccount2);
                GLAccount2.CalcFields("Net Change");
                if GLAccount2."Net Change" <> 0 then
                    ExportFile.Write(StrSubstNo('#PSALDO  %1  %2  %3  {} %4', -1, Format(FormatDate(GLAccount2.GetRangeMax
                            ("Date Filter")), 6), GLAccount2."No.", FormatAmount(GLAccount2."Net Change")));
                if AccountBudgetFilter <> '' then begin
                    GLAccount.Reset();
                    GLAccount.SetFilter("Global Dimension 1 Filter", '');
                    GLAccount.SetFilter("Global Dimension 2 Filter", '');
                    GLAccount.SetFilter("Date Filter", AccountDateFilter);
                    GLAccount.SetFilter("Budget Filter", AccountBudgetFilter);
                    GLAccount.CalcFields("Budgeted Amount");
                    if GLAccount."Budgeted Amount" <> 0 then
                        ExportFile.Write(StrSubstNo('#PBUDGET   %1  %2  %3  {} %4', 0, Format(FormatDate(GLAccount.GetRangeMax
                                ("Date Filter")), 6), GLAccount."No.", FormatAmount(GLAccount."Budgeted Amount")));
                    SetGLFilterPrev(GLAccount2);
                    GLAccount2.CalcFields("Budgeted Amount");
                    if GLAccount2."Budgeted Amount" <> 0 then
                        ExportFile.Write(StrSubstNo('#PBUDGET  %1  %2  %3  {} %4', -1, Format(FormatDate(GLAccount2.GetRangeMax
                                ("Date Filter")), 6), GLAccount2."No.", FormatAmount(GLAccount2."Budgeted Amount")));
                end;
                DialogWindow.Update(7, GLAccount."No.");
                DialogWindow.Update(8, Round(Counter / CounterTotal * 10000, 1));
            until GLAccountRec.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure ObjectBalance()
    begin
        CounterTotal := GLAccount.Count();
        GLAccount.CopyFilters("G/L Account");
        if GLAccount.Find('-') then
            repeat
                Counter := Counter + 1;
                SieDimension.SetCurrentKey("SIE Dimension");
                SieDimension.SetRange(Selected, true);
                if SieDimension.Find('-') then
                    repeat
                        DimensionValue.SetRange("Dimension Code", SieDimension."Dimension Code");
                        if DimensionValue.Find('-') then
                            repeat
                                GLAccount.Reset();
                                if DimensionValue."Dimension Code" = GLSetup."Global Dimension 1 Code" then
                                    GLAccount.SetFilter("Global Dimension 1 Filter", DimensionValue.Code);
                                if DimensionValue."Dimension Code" = GLSetup."Global Dimension 2 Code" then
                                    GLAccount.SetFilter("Global Dimension 2 Filter", DimensionValue.Code);
                                GLAccount.SetFilter("Date Filter", AccountDateFilter);
                                GLAccount.SetRange("Date Filter", 0D, ClosingDate(GLAccount.GetRangeMin("Date Filter") - 1));
                                GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
                                GLAccount.CalcFields("Balance at Date");

                                SetGLFilterPrev(GLAccount2);
                                GLAccount2.SetRange("Date Filter", 0D, ClosingDate(GLAccount2.GetRangeMax("Date Filter")));
                                GLAccount2.CalcFields("Balance at Date");
                                if GLAccount."Balance at Date" <> 0 then
                                    ExportFile.Write(StrSubstNo('#OIB  %1  %2  {%3 "%4"}  %5', 0, GLAccount."No.", SieDimension."SIE Dimension",
                                        Ascii2Ansi(DimensionValue.Code), FormatAmount(GLAccount."Balance at Date")));
                                if GLAccount2."Balance at Date" <> 0 then
                                    ExportFile.Write(StrSubstNo('#OUB  %1  %2  {%3 "%4"}  %5', 0, GLAccount."No.", SieDimension."SIE Dimension",
                                        Ascii2Ansi(DimensionValue.Code), FormatAmount(GLAccount2."Balance at Date")));

                                GLAccount.SetRange("Date Filter", PrevAccPeriodStart, PrevAccPeriodEnd);
                                GLAccount.SetRange("Date Filter", 0D, ClosingDate(GLAccount.GetRangeMin("Date Filter") - 1));
                                GLAccount.SetFilter("Global Dimension 1 Filter", DimensionValue.Code);
                                GLAccount.CalcFields("Balance at Date");
                                SetGLFilterPrev(GLAccount2);
                                GLAccount2.SetRange("Date Filter", 0D, ClosingDate(GLAccount2.GetRangeMax("Date Filter")));
                                GLAccount2.SetFilter("Global Dimension 1 Filter", DimensionValue.Code);
                                GLAccount2.CalcFields("Balance at Date");
                                if GLAccount."Balance at Date" <> 0 then
                                    ExportFile.Write(StrSubstNo('#OIB  %1  %2  {%3 "%4"}  %5', -1, GLAccount."No.", SieDimension."SIE Dimension",
                                        Ascii2Ansi(DimensionValue.Code), FormatAmount(GLAccount."Balance at Date")));
                                if GLAccount2."Balance at Date" <> 0 then
                                    ExportFile.Write(StrSubstNo('#OUB  %1  %2  {%3 "%4"}  %5', -1, GLAccount."No.", SieDimension."SIE Dimension",
                                        Ascii2Ansi(DimensionValue.Code), FormatAmount(GLAccount2."Balance at Date")));
                            until DimensionValue.Next() = 0;
                    until SieDimension.Next() = 0;

                DialogWindow.Update(5, GLAccount."No.");
                DialogWindow.Update(6, Round(Counter / CounterTotal * 10000, 1));
            until GLAccount.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure Ascii2Ansi(AsciText: Text[250]): Text[250]
    var
        AsciiStr: Text[30];
        AnsiStr: Text[30];
        AE: Char;
        UE: Char;
        Lilla: Char;
        Stora: Char;
    begin
        AsciiStr := 'åäöüÅÄÖÜéêèâàç';
        AE := 196;
        UE := 220;
        Lilla := 229;
        Stora := 197;
        AnsiStr := Format(Lilla) + 'õ÷³' + Format(Stora) + Format(AE) + 'Í' + Format(UE) + 'ÚÛÞÔÓþ';

        exit(ConvertStr(AsciText, AsciiStr, AnsiStr));
    end;

    [Scope('OnPrem')]
    procedure FormatAmount(Amount: Decimal): Text[30]
    begin
        exit(ConvertStr(Format(Amount, 0, '<Sign><Integer><decimal>'), ',', '.'));
    end;

    [Scope('OnPrem')]
    procedure FormatDate(Date: Date): Text[30]
    begin
        exit(Format(Date, 8, '<Year4><month,2><day,2>'));
    end;

    [Scope('OnPrem')]
    procedure SetGLFilterPrev(var GLAccountFiltered: Record "G/L Account")
    begin
        GLAccountFiltered.Reset();
        GLAccountFiltered := GLAccount;
        GLAccountFiltered.CopyFilters(GLAccount);
        GLAccountFiltered.SetRange("Date Filter", PrevAccPeriodStart, PrevAccPeriodEnd);
    end;

    [Scope('OnPrem')]
    procedure SIEType1()
    begin
        DialogWindow.Open(Text003 +
          Text004 +
          Text005);
        WriteFileheader();
        GLPost();
        GLAccountPost();
    end;

    [Scope('OnPrem')]
    procedure SIEType2()
    begin
        DialogWindow.Open(Text003 +
          Text004 +
          Text005 +
          Text007);
        PeriodExport := true;
        WriteFileheader();
        GLPost();
        WriteDimension();
        GLAccountPost();
        PeriodicPost();
    end;

    [Scope('OnPrem')]
    procedure SIEType3()
    begin
        DialogWindow.Open(Text003 +
          Text004 +
          Text005 +
          Text006 +
          Text007);
        ObjectExport := true;
        WriteFileheader();
        GLPost();
        WriteDimension();
        GLAccountPost();
        ObjectBalance();
        PeriodicPost();
    end;

    [Scope('OnPrem')]
    procedure SIEType4()
    begin
        DialogWindow.Open(Text003 +
          Text004 +
          Text005 +
          Text008);
        WriteFileheader();
        WriteDimension();
        GLPost();
        GLAccountPost();
        WriteTransaction();
    end;

    local procedure OnActivateForm()
    begin
        ColumnDim := SieDimension.GetDimSelectionText();
    end;

    [Scope('OnPrem')]
    procedure InitializeRequest(NewServerFileName: Text)
    begin
        ServerFileName := NewServerFileName;
    end;
}

#endif
