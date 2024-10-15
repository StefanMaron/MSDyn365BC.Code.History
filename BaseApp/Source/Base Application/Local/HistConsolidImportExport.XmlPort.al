﻿// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft;

using Microsoft.Finance.Currency;
#if not CLEAN25
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Ledger;
#endif

xmlport 10700 "Hist. Consolid. Import/Export"
{
    Caption = 'Hist. Consolid. Import/Export';
    FormatEvaluate = Xml;

    schema
    {
        textelement(subFinReport)
        {
            MaxOccurs = Once;
            MinOccurs = Once;
            textattribute(product)
            {
            }
            textattribute(productVersion)
            {
            }
            textattribute(formatVersion)
            {

                trigger OnAfterAssignVariable()
                begin
                    // add code here to test format Version against CurrentFormatVersion.
                    // if different only behind the decimal point, than ok.
                    // if different before the decimal, then give error message.
                end;
            }
            textattribute(subCompanyName)
            {
            }
            textattribute(currencyLCY)
            {
                Occurrence = Optional;
            }
            textattribute(currencyACY)
            {
                Occurrence = Optional;
            }
            textattribute(currencyPCY)
            {
                Occurrence = Optional;
            }
            textattribute(checkSum)
            {
            }
            textattribute(startingDate)
            {
                Occurrence = Optional;
            }
            textattribute(endingDate)
            {
            }
            textattribute(reportingDate)
            {
            }
            textattribute(reportingUserID)
            {
            }
            textelement(exchRateTable)
            {
                MaxOccurs = Once;
                MinOccurs = Zero;
                tableelement("Currency Exchange Rate"; "Currency Exchange Rate")
                {
                    MinOccurs = Zero;
                    XmlName = 'exchRate';
                    SourceTableView = sorting("Currency Code", "Starting Date");
                    UseTemporary = true;
                    fieldattribute(currencyCode; "Currency Exchange Rate"."Currency Code")
                    {
                        Occurrence = Required;
                    }
                    fieldattribute(relCurrencyCode; "Currency Exchange Rate"."Relational Currency Code")
                    {
                        Occurrence = Optional;
                    }
                    fieldattribute(startingDate; "Currency Exchange Rate"."Starting Date")
                    {
                    }
                    fieldattribute(exchRateAmount; "Currency Exchange Rate"."Exchange Rate Amount")
                    {
                    }
                    fieldattribute(relExchRateAmount; "Currency Exchange Rate"."Relational Exch. Rate Amount")
                    {
                    }
                }
            }
#if not CLEAN25
            textelement(historicGLAccountTable)
            {
                MaxOccurs = Once;
                MinOccurs = Once;
                tableelement("historic g/l account"; "Historic G/L Account")
                {
                    XmlName = 'historicGLAccount';
                    SourceTableView = sorting("No.");
                    UseTemporary = true;
                    fieldattribute(no; "Historic G/L Account"."No.")
                    {
                    }
                    fieldattribute(accountDebit; "Historic G/L Account"."Consol. Debit Acc.")
                    {
                        Occurrence = Optional;
                    }
                    fieldattribute(accountCredit; "Historic G/L Account"."Consol. Credit Acc.")
                    {
                        Occurrence = Optional;
                    }
                    fieldattribute(translationMethod; "Historic G/L Account"."Consol. Translation Method")
                    {
                    }
                    tableelement("G/L Entry"; "G/L Entry")
                    {
                        LinkFields = "G/L Account No." = field("No.");
                        LinkTable = "Historic G/L Account";
                        MinOccurs = Zero;
                        XmlName = 'glEntry';
                        SourceTableView = sorting("G/L Account No.", "Posting Date");
                        UseTemporary = true;
                        fieldattribute(postingDate; "G/L Entry"."Posting Date")
                        {
                        }
                        fieldattribute(amountDebit; "G/L Entry"."Debit Amount")
                        {
                            Occurrence = Optional;
                        }
                        fieldattribute(amountCredit; "G/L Entry"."Credit Amount")
                        {
                            Occurrence = Optional;
                        }
                        fieldattribute(arcAmountDebit; "G/L Entry"."Add.-Currency Debit Amount")
                        {
                            Occurrence = Optional;
                        }
                        fieldattribute(arcAmountCredit; "G/L Entry"."Add.-Currency Credit Amount")
                        {
                            Occurrence = Optional;
                        }
                        tableelement("Dimension Set Entry"; "Dimension Set Entry")
                        {
                            LinkFields = "Dimension Set ID" = field("Dimension Set ID");
                            LinkTable = "G/L Entry";
                            MinOccurs = Zero;
                            XmlName = 'dimension';
                            SourceTableView = sorting("Dimension Set ID", "Dimension Code");
                            UseTemporary = true;
                            fieldattribute(code; "Dimension Set Entry"."Dimension Code")
                            {
                            }
                            fieldattribute(value; "Dimension Set Entry"."Dimension Value Code")
                            {
                            }

                            trigger OnBeforeInsertRecord()
                            begin
                                "Dimension Set Entry"."Dimension Set ID" := "G/L Entry"."Entry No.";
                            end;
                        }

                        trigger OnAfterInsertRecord()
                        begin
                            NextGLEntryNo := NextGLEntryNo + 1;
                        end;

                        trigger OnBeforeInsertRecord()
                        begin
                            "G/L Entry"."Entry No." := NextGLEntryNo;
                            "G/L Entry"."Dimension Set ID" := "G/L Entry"."Entry No."; // used as intermediate to point to Dimension Set
                            "G/L Entry"."G/L Account No." := "Historic G/L Account"."No.";
                        end;
                    }
                }
            }
#endif
            trigger OnAfterAssignVariable()
            begin
                NextGLEntryNo := 1;
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    var
        CurrentProduct: Label 'Microsoft Dynamics NAV';
        CurrentProductVersion: Label '4.00';
        CurrentFormatVersion: Label '1.00';
        NextGLEntryNo: Integer;

    [Scope('OnPrem')]
    procedure SetGlobals(NewCompanyName: Text[30]; NewCurrencyLCY: Code[10]; NewCurrencyACY: Code[10]; NewCurrencyPCY: Code[10]; NewCheckSum: Decimal; NewStartingDate: Date; NewEndingDate: Date)
    begin
        product := CurrentProduct;
        productVersion := CurrentProductVersion;
        formatVersion := CurrentFormatVersion;
        subCompanyName := NewCompanyName;
        currencyLCY := NewCurrencyLCY;
        currencyACY := NewCurrencyACY;
        currencyPCY := NewCurrencyPCY;
        checkSum := DecimalToXMLText(NewCheckSum);
        startingDate := DateToXMLText(NewStartingDate);
        endingDate := DateToXMLText(NewEndingDate);
        reportingDate := DateToXMLText(Today);
        reportingUserID := UserId;
    end;

    [Scope('OnPrem')]
    procedure GetGlobals(var ImpProductVersion: Code[10]; var ImpFormatVersion: Code[10]; var ImpCompanyName: Text[30]; var ImpCurrencyLCY: Code[10]; var ImpCurrencyACY: Code[10]; var ImpCurrencyPCY: Code[10]; var ImpCheckSum: Decimal; var ImpStartingDate: Date; var ImpEndingDate: Date)
    begin
        ImpProductVersion := productVersion;
        ImpFormatVersion := formatVersion;
        ImpCompanyName := subCompanyName;
        ImpCurrencyLCY := currencyLCY;
        ImpCurrencyACY := currencyACY;
        ImpCurrencyPCY := currencyPCY;
        ImpCheckSum := XMLTextToDecimal(checkSum);
        ImpStartingDate := XMLTextToDate(startingDate);
        ImpEndingDate := XMLTextToDate(endingDate);
    end;

#if not CLEAN25
    [Obsolete('The Table ''Historic G/L Account'' is obsoleted', '25.0')]
    [Scope('OnPrem')]
    procedure SetGLAccount(var TempHistoricGLAccount: Record "Historic G/L Account")
    begin
        "Historic G/L Account".Reset();
        "Historic G/L Account".DeleteAll();
        if TempHistoricGLAccount.Find('-') then
            repeat
                "Historic G/L Account" := TempHistoricGLAccount;
                "Historic G/L Account".Insert();
            until TempHistoricGLAccount.Next() = 0;
    end;

    [Obsolete('The Table ''Historic G/L Account'' is obsoleted', '25.0')]
    [Scope('OnPrem')]
    procedure GetGLAccount(var TempHistoricGLAccount: Record "Historic G/L Account")
    begin
        TempHistoricGLAccount.Reset();
        TempHistoricGLAccount.DeleteAll();
        "Historic G/L Account".Reset();
        if "Historic G/L Account".Find('-') then
            repeat
                TempHistoricGLAccount := "Historic G/L Account";
                TempHistoricGLAccount.Insert();
            until "Historic G/L Account".Next() = 0;
    end;

    [Obsolete('"G/L Entry" in this file is referencing the table "Historic G/L Account", which is obsoleted', '25.0')]
    [Scope('OnPrem')]
    procedure SetGLEntry(var TempGLEntry: Record "G/L Entry")
    begin
        "G/L Entry".Reset();
        "G/L Entry".DeleteAll();
        if TempGLEntry.Find('-') then
            repeat
                "G/L Entry" := TempGLEntry;
                "G/L Entry".Insert();
            until TempGLEntry.Next() = 0;
    end;

    [Obsolete('"G/L Entry" in this file is referencing the table "Historic G/L Account", which is obsoleted', '25.0')]
    [Scope('OnPrem')]
    procedure GetGLEntry(var TempGLEntry: Record "G/L Entry")
    begin
        TempGLEntry.Reset();
        TempGLEntry.DeleteAll();
        "G/L Entry".Reset();
        if "G/L Entry".Find('-') then
            repeat
                TempGLEntry := "G/L Entry";
                TempGLEntry.Insert();
            until "G/L Entry".Next() = 0;
    end;

    [Obsolete('"Dimension Set Entry" in this file is referencing the table "Historic G/L Account", which is obsoleted', '25.0')]
    [Scope('OnPrem')]
    procedure SetEntryDim(var DimSetEntry: Record "Dimension Set Entry")
    begin
        "Dimension Set Entry".Reset();
        "Dimension Set Entry".DeleteAll();
        if DimSetEntry.Find('-') then
            repeat
                "Dimension Set Entry" := DimSetEntry;
                "Dimension Set Entry".Insert();
            until DimSetEntry.Next() = 0;
    end;

    [Obsolete('"Dimension Set Entry" in this file is referencing the table "Historic G/L Account", which is obsoleted', '25.0')]
    [Scope('OnPrem')]
    procedure GetEntryDim(var TempDimSetEntry: Record "Dimension Set Entry")
    begin
        TempDimSetEntry.Reset();
        TempDimSetEntry.DeleteAll();
        "Dimension Set Entry".Reset();
        if "Dimension Set Entry".Find('-') then
            repeat
                TempDimSetEntry := "Dimension Set Entry";
                TempDimSetEntry.Insert();
            until "Dimension Set Entry".Next() = 0;
    end;
#endif

    [Scope('OnPrem')]
    procedure SetExchRate(var TempExchRate: Record "Currency Exchange Rate")
    begin
        "Currency Exchange Rate".Reset();
        "Currency Exchange Rate".DeleteAll();
        if TempExchRate.Find('-') then
            repeat
                "Currency Exchange Rate" := TempExchRate;
                "Currency Exchange Rate".Insert();
            until TempExchRate.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure GetExchRate(var TempExchRate: Record "Currency Exchange Rate")
    begin
        TempExchRate.Reset();
        TempExchRate.DeleteAll();
        "Currency Exchange Rate".Reset();
        if "Currency Exchange Rate".Find('-') then
            repeat
                TempExchRate := "Currency Exchange Rate";
                TempExchRate.Insert();
            until "Currency Exchange Rate".Next() = 0;
    end;

    local procedure DateToXMLText(Date: Date) XMLText: Text[30]
    begin
        XMLText := Format(Date, 10, '<Year4>-<Month,2>-<Day,2>');
    end;

    local procedure XMLTextToDate(XMLText: Text[30]) Date: Date
    var
        Month: Integer;
        Day: Integer;
        Year: Integer;
    begin
        Evaluate(Year, CopyStr(XMLText, 1, 4));
        Evaluate(Month, CopyStr(XMLText, 6, 2));
        Evaluate(Day, CopyStr(XMLText, 9, 2));
        Date := DMY2Date(Day, Month, Year);
    end;

    local procedure DecimalToXMLText(Amount: Decimal) XMLText: Text[30]
    var
        BeforePoint: Decimal;
        AfterPoint: Decimal;
        Places: Integer;
        Minus: Boolean;
    begin
        Minus := (Amount < 0);
        if Minus then
            Amount := -Amount;
        BeforePoint := Round(Amount, 1, '<');
        AfterPoint := Amount - BeforePoint;
        Places := 0;
        while Round(AfterPoint, 1) <> AfterPoint do begin
            AfterPoint := AfterPoint * 10;
            Places := Places + 1;
        end;
        XMLText :=
          Format(BeforePoint, 0, 1) + '.' + ConvertStr(Format(AfterPoint, Places, 1), ' ', '0');
        if Minus then
            XMLText := '-' + XMLText;
    end;

    local procedure XMLTextToDecimal(XMLText: Text[30]) Amount: Decimal
    var
        BeforePoint: Decimal;
        AfterPoint: Decimal;
        BeforeText: Text[30];
        AfterText: Text[30];
        Minus: Boolean;
        Places: Integer;
        Point: Integer;
    begin
        if StrLen(XMLText) = 0 then
            exit(0);
        Minus := (XMLText[1] = '-');
        if Minus then
            XMLText := DelStr(XMLText, 1, 1);
        Point := StrLen(XMLText);
        AfterText := '';
        while (XMLText[Point] in ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']) and
              (Point > 1)
        do begin
            Places := Places + 1;
            AfterText := ' ' + AfterText;
            AfterText[1] := XMLText[Point];
            Point := Point - 1;
        end;
        BeforeText := DelChr(CopyStr(XMLText, 1, Point), '=', '.,');
        Evaluate(BeforePoint, BeforeText);
        Evaluate(AfterPoint, AfterText);
        while Places > 0 do begin
            AfterPoint := AfterPoint / 10;
            Places := Places - 1;
        end;
        Amount := BeforePoint + AfterPoint;
        if Minus then
            Amount := -Amount;
    end;
}

