#if not CLEAN22
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Finance.AuditFileExport;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.NoSeries;
using System.IO;
using System.Telemetry;
using System.Utilities;
using System.Environment.Configuration;

report 11208 "SIE Import"
{
    ApplicationArea = Basic, Suite;
    Caption = 'SIE Import';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;
    ObsoleteReason = 'Replaced by Import SIE report of Standard Import Export (SIE) extension';
    ObsoleteState = Pending;
    ObsoleteTag = '22.0';

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number);

            trigger OnAfterGetRecord()
            begin
                DialogWindow.Update(1, Round(ImportFile.Pos / ImportFile.Len * 10000, 1.0));

                if ImportFile.Len = ImportFile.Pos then
                    CurrReport.Break();

                ImportFile.Read(FileText);
                FileText := ReplaceTab(FileText);
                FileText := Ansi2Ascii(FileText);

                TempSieBuffer.Init();
                TempSieBuffer."Entry No." := NextEntryNo;
                FileText := DelChr(FileText, '<', ' ');
                Pos1 := GetPos1(FileText);
                if Pos1 > 0 then
                    TempSieBuffer."Import Field 1" := ClChr(CopyStr(FileText, 1, Pos1))
                else
                    TempSieBuffer."Import Field 1" := ClChr(CopyStr(FileText, 1, StrLen(FileText)));

                Pos1 := StrLen(TempSieBuffer."Import Field 1");
                Pos1 += 2;
                TempSieBuffer."Import Field 2" := ClChr(GetNextField(CopyStr(FileText, Pos1, StrLen(FileText))));

                Pos1 += i2;
                Pos1 += i;

                if Pos1 < StrLen(FileText) then
                    TempSieBuffer."Import Field 3" := ClChr(GetNextField(CopyStr(FileText, Pos1, StrLen(FileText))));

                Pos1 += i2;
                Pos1 += i;

                if Pos1 < StrLen(FileText) then
                    TempSieBuffer."Import Field 4" := ClChr(GetNextField(CopyStr(FileText, Pos1, StrLen(FileText))));

                Pos1 += i2;
                Pos1 += i;

                if Pos1 < StrLen(FileText) then
                    TempSieBuffer."Import Field 5" := ClChr(GetNextField(CopyStr(FileText, Pos1, StrLen(FileText))));

                Pos1 += i2;
                Pos1 += i;

                if Pos1 < StrLen(FileText) then
                    TempSieBuffer."Import Field 6" := ClChr(GetNextField(CopyStr(FileText, Pos1, StrLen(FileText))));

                Pos1 += i2;
                Pos1 += i;

                if Pos1 < StrLen(FileText) then
                    TempSieBuffer."Import Field 7" := ClChr(GetNextField(CopyStr(FileText, Pos1, StrLen(FileText))));

                Pos1 += i2;
                Pos1 += i;

                if Pos1 < StrLen(FileText) then
                    TempSieBuffer."Import Field 8" := ClChr(GetNextField(CopyStr(FileText, Pos1, StrLen(FileText))));

                TempSieBuffer.Insert();
                NextEntryNo += 1;
            end;

            trigger OnPreDataItem()
            begin
                NextEntryNo := 1;
                ValidateJnl();
            end;
        }
        dataitem("SIE Import Buffer"; "SIE Import Buffer")
        {
            DataItemTableView = sorting("Entry No.");

            trigger OnAfterGetRecord()
            var
                GLAccountNo: Code[20];
            begin
                DialogWindow.Update(2, Round("Entry No." / Count * 10000, 1.0));

                case "Import Field 1" of
                    'FLAGGA':
                        TestField("Import Field 2", '0');
                    'TRANS':
                        CreateGenJnlLine();
                    'KONTO':
                        if InsertNewAccount then begin
                            GLAccountNo := CopyStr(DelChr("Import Field 2", '=', ' '), 1, MaxStrLen(GLAccount."No."));
                            if GLAccountNo <> '' then begin
                                GLAccount.Init();
                                GLAccount.Validate("No.", GLAccountNo);
                                GLAccount.Validate(Name, CopyStr(DelChr("Import Field 3", '=', '"'), 1, 30));
                                if (CopyStr(GLAccount."No.", 1, 1) = '1') or (CopyStr(GLAccount."No.", 1, 1) = '2') then
                                    GLAccount."Income/Balance" := GLAccount."Income/Balance"::"Balance Sheet"
                                else
                                    GLAccount."Income/Balance" := GLAccount."Income/Balance"::"Income Statement";
                                GLAccount."Direct Posting" := true;
                                OK := GLAccount.Insert();
                            end;
                        end;
                    'VER':
                        begin
                            if UseSerie then
                                DocNo := DelChr("Import Field 2", '=', '"') + DelChr("Import Field 3", '=', '"')
                            else
                                DocNo := DelChr("Import Field 3", '=', '"');
                            if StrLen(DocNo) = 0 then
                                DocNo := NoSeriesBatch.GetNextNo(GenJnlBatch."No. Series");

                            "Import Field 4" := DelChr("Import Field 4", '=<>', DelChr("Import Field 4", '=<>', '0123456789'));
                            // File format YYYYMMDD according to swedish standard
                            Evaluate(DD, CopyStr("Import Field 4", 7, 2));
                            Evaluate(MM, CopyStr("Import Field 4", 5, 2));
                            Evaluate(YYYY, CopyStr("Import Field 4", 1, 4));
                            PostingDate := DMY2Date(DD, MM, YYYY);
                            Description := CopyStr("Import Field 5", 1, 50);
                        end;
                    else
                        exit;
                end;
            end;

            trigger OnPostDataItem()
            begin
                DialogWindow.Close();
                DeleteAll();
            end;

            trigger OnPreDataItem()
            begin
                NextLineNo := 10000;
                GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
                GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
                if GenJnlLine.Find('+') then
                    NextLineNo := GenJnlLine."Line No." + 10000;
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
                    field("GenJnlLine.""Journal Template Name"""; GenJnlLine."Journal Template Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Gen. Journal Template';
                        TableRelation = "Gen. Journal Template";
                        ToolTip = 'Specifies the name of the general journal to use during the import process.';

                        trigger OnValidate()
                        begin
                            GenJnlLine."Journal Batch Name" := '';
                        end;
                    }
                    field("GenJnlLine.""Journal Batch Name"""; GenJnlLine."Journal Batch Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Gen. Journal Batch';
                        Lookup = true;
                        ToolTip = 'Specifies the name of the general journal batch to use during the import process.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            GenJnlLine.TestField("Journal Template Name");
                            GenJnlTemplate.Get(GenJnlLine."Journal Template Name");
                            GenJnlBatch.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
                            GenJnlBatch."Journal Template Name" := GenJnlLine."Journal Template Name";
                            GenJnlBatch.Name := GenJnlLine."Journal Batch Name";
                            if PAGE.RunModal(0, GenJnlBatch) = ACTION::LookupOK then begin
                                GenJnlLine."Journal Batch Name" := GenJnlBatch.Name;
                                ValidateJnl();
                            end;
                        end;

                        trigger OnValidate()
                        begin
                            if GenJnlLine."Journal Batch Name" <> '' then begin
                                GenJnlLine.TestField("Journal Template Name");
                                GenJnlBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name");
                            end;
                            ValidateJnl();
                        end;
                    }
                    field(ColumnDim; ColumnDim)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Dimensions';
                        Editable = false;
                        ToolTip = 'Specifies the dimensions covered by the import process.';

                        trigger OnAssistEdit()
                        begin
                            Clear(SieDimensionPage);
                            SieDimensionPage.LookupMode(true);
                            SieDimensionPage.Run();
                            ColumnDim := SieDimension.GetDimSelectionText();
                        end;
                    }
                    field(InsertNewAccount; InsertNewAccount)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Insert G/L Account';
                        ToolTip = 'Specifies whether the general ledger account in the import file is missing in the chart of accounts, and must be set up during the import process.';
                    }
                    field(UseSerie; UseSerie)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Use Number Series for Doc. No.';
                        ToolTip = 'Specifies whether to use the number series functionality if document numbers are not provided in the import file.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        var
            FeatureKeyManagement: Codeunit "Feature Key Management";
        begin
            if FeatureKeyManagement.IsSIEAuditFileExportEnabled() then begin
                Report.Run(5314); // report 5314 "Import SIE"
                Error('');
            end;

            FeatureTelemetry.LogUptake('0001P9B', SieeTok, Enum::"Feature Uptake Status"::Discovered);
            OnActivateForm();
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        FeatureTelemetry.LogUptake('0001P9C', SieeTok, Enum::"Feature Uptake Status"::"Set up");
        ImportFile.Close();
        Erase(ServerFileName);
        Message(Text005);
    end;

    trigger OnPreReport()
    var
        FileMgt: Codeunit "File Management";
    begin
        ImportFile.TextMode := true;
        if ServerFileName = '' then begin
            ServerFileName := FileMgt.ServerTempFileName('se');
            if not Upload(Text002, '', Text001, '', ServerFileName) then
                Error('');
        end;
        ImportFile.Open(ServerFileName);
        DialogWindow.Open(Text003 + Text004);
    end;

    var
        SieDimension: Record "SIE Dimension";
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        TempSieBuffer: Record "SIE Import Buffer";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        SieDimensionPage: Page "SIE Dimensions";
        DialogWindow: Dialog;
        ImportFile: File;
        ServerFileName: Text;
        ColumnDim: Text;
        Description: Text[100];
        i: Integer;
        i2: Integer;
        NextEntryNo: Integer;
        Pos: Integer;
        Pos1: Integer;
        NextLineNo: Integer;
        DocNo: Code[20];
        Text001: Label 'SIE files(*.se)|*.se|All files|*.*';
        Text002: Label 'Import SIE File';
        SieeTok: Label 'SE SIEE Data', Locked = true;
        FileText: Text[250];
        Text003: Label 'Reading SIE file           @1@@@@@@@@@@\';
        InsertNewAccount: Boolean;
        PostingDate: Date;
        Text004: Label 'Create journal             @2@@@@@@@@@@\';
        OK: Boolean;
        UseSerie: Boolean;
        DD: Integer;
        MM: Integer;
        YYYY: Integer;
        Text005: Label 'The file was  imported successfully.';

    local procedure ValidateJnl()
    begin
        GenJnlBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name");
    end;

    [Scope('OnPrem')]
    procedure Ansi2Ascii(AnsiText: Text[250]): Text[250]
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

        exit(ConvertStr(AnsiText, AnsiStr, AsciiStr));
    end;

    [Scope('OnPrem')]
    procedure ClChr(String: Text[250]): Text[250]
    begin
        String := DelChr(String, '=', '#{}');
        exit(String);
    end;

    [Scope('OnPrem')]
    procedure GetPos1(String: Text[250]): Integer
    begin
        exit(StrPos(CopyStr(String, 1, StrLen(String)), ' ') - 1);
    end;

    [Scope('OnPrem')]
    procedure GetNextField(String: Text[250]): Text[250]
    begin
        for i := 1 to StrLen(String) do begin
            if CopyStr(String, i, 1) <> ' ' then begin
                if CopyStr(String, i, 1) = '"' then begin
                    for i2 := 1 to StrLen(String) do begin
                        if CopyStr(String, i2 + i, 1) = '"' then
                            exit(DelChr(CopyStr(String, i, i2 + 1), '<', ' '));
                    end;
                end
                else begin
                    if CopyStr(String, i, 1) = '{' then begin
                        for i2 := 1 to StrLen(String) do begin
                            if CopyStr(String, i2 + i, 1) = '}' then
                                exit(DelChr(CopyStr(String, i, i2 + 1), '<', ' '));
                        end;
                    end
                    else
                        for i2 := 1 to StrLen(String) do begin
                            if CopyStr(String, i2 + i, 1) = ' ' then
                                exit(DelChr(CopyStr(String, i, i2 + 1), '<', ' '));
                            if CopyStr(String, i2 + i, 1) = '{' then begin
                                i := i - 1;
                                exit(DelChr(CopyStr(String, i, i2 + 1), '<', ' '));
                            end;
                        end;
                end;
            end;
        end;
        exit(DelChr(CopyStr(String, 1, StrLen(String)), '<', ' '));
    end;

    [Scope('OnPrem')]
    procedure CreateGenJnlLine()
    begin
        if DocNo = '' then
            DocNo := NoSeriesBatch.GetNextNo(GenJnlBatch."No. Series");
        GenJnlLine.Init();
        GenJnlLine."Journal Template Name" := GenJnlBatch."Journal Template Name";
        GenJnlLine."Journal Batch Name" := GenJnlBatch.Name;
        GenJnlLine."Line No." := NextLineNo;
        GenJnlLine.Insert();
        GenJnlLine.SetUpNewLine(GenJnlLine, GenJnlLine."Balance (LCY)", true);
        GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"G/L Account");
        GenJnlLine."Posting Date" := PostingDate;
        GenJnlLine."Document Date" := PostingDate;
        GenJnlLine."VAT Reporting Date" := PostingDate;
        GenJnlLine."Document No." := DocNo;
        GenJnlLine."Posting No. Series" := GenJnlBatch."Posting No. Series";
        GenJnlLine.Description := Description;
        GenJnlLine.Validate("Account No.", "SIE Import Buffer"."Import Field 2");
        Evaluate(GenJnlLine.Amount, ConvertStr("SIE Import Buffer"."Import Field 4", '.', ','));
        GenJnlLine.Validate(Amount);

        if StrLen("SIE Import Buffer"."Import Field 3") > 2 then
            GetDimValue(GenJnlLine);

        GenJnlLine.Modify();
        NextLineNo += 10000;
    end;

    [Scope('OnPrem')]
    procedure GetDimValue(var DimGenJnl: Record "Gen. Journal Line")
    var
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimensionValue: Record "Dimension Value";
        DimensionManagement: Codeunit DimensionManagement;
        Dim1: Code[20];
        Dim2: Code[20];
        SieNumber: Integer;
    begin
        Pos := 1;
        while Pos < StrLen("SIE Import Buffer"."Import Field 3") do begin
            Dim1 := GetDimValue1("SIE Import Buffer"."Import Field 3", Pos);
            if Dim1 <> '' then
                Evaluate(SieNumber, Dim1)
            else
                exit;

            Pos += 1;
            Dim2 := GetDimValue1("SIE Import Buffer"."Import Field 3", Pos);
            SieDimension.SetRange(Selected, true);
            SieDimension.SetRange("SIE Dimension", SieNumber);
            if SieDimension.Find('-') then
                case SieDimension.ShortCutDimNo of
                    1:
                        GenJnlLine.Validate("Shortcut Dimension 1 Code", Dim2);
                    2:
                        GenJnlLine.Validate("Shortcut Dimension 2 Code", Dim2);
                    3:
                        GenJnlLine.ValidateShortcutDimCode(3, Dim2);
                    4:
                        GenJnlLine.ValidateShortcutDimCode(4, Dim2);
                    5:
                        GenJnlLine.ValidateShortcutDimCode(5, Dim2);
                    6:
                        GenJnlLine.ValidateShortcutDimCode(6, Dim2);
                    7:
                        GenJnlLine.ValidateShortcutDimCode(7, Dim2);
                    8:
                        GenJnlLine.ValidateShortcutDimCode(8, Dim2)
                    else begin
                        DimensionManagement.GetDimensionSet(TempDimSetEntry, GenJnlLine."Dimension Set ID");
                        TempDimSetEntry.Init();
                        TempDimSetEntry."Dimension Code" := SieDimension."Dimension Code";
                        TempDimSetEntry."Dimension Value Code" := Dim2;
                        DimensionValue.Get(SieDimension."Dimension Code", Dim2);
                        TempDimSetEntry."Dimension Value ID" := DimensionValue."Dimension Value ID";
                        TempDimSetEntry.Insert();
                        GenJnlLine."Dimension Set ID" := DimensionManagement.GetDimensionSetID(TempDimSetEntry);
                    end;
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetDimValue1(String: Text[250]; nPos: Integer): Text[20]
    begin
        for i := nPos to StrLen(String) do begin
            if CopyStr(String, i, 1) <> ' ' then begin
                if CopyStr(String, i, 1) = '"' then begin
                    for i2 := 1 to StrLen(String) do begin
                        if CopyStr(String, i2 + i, 1) = '"' then begin
                            Pos := i2 + 1 + i;
                            exit(CopyStr(String, i + 1, i2 - 1));
                        end;
                    end;
                end
                else begin
                    for i2 := i to StrLen(String) do begin
                        if (CopyStr(String, i2, 1) = ' ') or
                           (CopyStr(String, i2, 1) = '"')
                        then begin
                            Pos := i2;
                            exit(CopyStr(String, i, i2 - i));
                        end;
                    end;
                    Pos := i2;
                    exit(CopyStr(String, i - 1, i2));
                end;
            end;
        end;
        exit(' ');
    end;

    local procedure OnActivateForm()
    begin
        ColumnDim := SieDimension.GetDimSelectionText();
    end;

    local procedure ReplaceTab(FileText: Text[250]): Text[250]
    var
        OldChar: Char;
    begin
        OldChar := 9;
        exit(ConvertStr(FileText, Format(OldChar), ' '));
    end;

    [Scope('OnPrem')]
    procedure InitializeRequest(NewServerFileName: Text)
    begin
        ServerFileName := NewServerFileName;
    end;
}

#endif
