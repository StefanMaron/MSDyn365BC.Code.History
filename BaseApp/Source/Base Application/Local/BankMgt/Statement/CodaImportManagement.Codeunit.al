// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.CODA;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Payment;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Foundation.Company;

codeunit 2000040 "Coda Import Management"
{
    TableNo = "CODA Statement Source Line";

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'The enterprise number that is specified in the company information is not valid.';
        Text001: Label 'CODA statement source line %1 is not a %2 line.', Comment = 'Parameter 1 - integer number, 2 - type (Header,Old Balance,Movement,Information,Free Message,,,,New Balance,Trailer)';
        Text002: Label 'Enterprise number %1 does not match ID %2 of %3 record.';
        Text003: Label 'Protocol number %1 of bank account %2 does not match protocol number %3 of %4 record.';
        Text005: Label '%1 of %2 %3 does not match %1 of %4 record.';
        Text006: Label '%1 records read, %2 records expected.';
        Text007: Label 'Debet total is %1, expected %2.';
        Text008: Label 'Credit total is %1, expected %2.';
        Text009: Label 'CODA statement source line %1 is a %2 line.';
        Text010: Label '%1 in %2.';
        Text012: Label '%1 on line %2 cannot be %3.';
        Text013: Label '%1 records read\%2 total debit amount\%3 total credit amount\%4 lines skipped (before first or after last record).';
        Text017: Label 'You cannot import CODA files for foreign bank accounts.';
        CompanyInfo: Record "Company Information";
        BankAcc: Record "Bank Account";
        CodBankStmtSrcLine: Record "CODA Statement Source Line";
        PaymJnlManagement: Codeunit PmtJrnlManagement;
        EnterpriseNoCheck: Codeunit VATLogicalTests;
        LineCounter: array[2] of Integer;
        SkippedLines: Integer;
        TotalDebit: array[2] of Decimal;
        TotalCredit: array[2] of Decimal;
        VId: array[2] of Text[11];
        EnterpriseNo: Text[11];
        ProtocolNo: Text[3];
        VersionCode: Text[1];
        CODAStatementNo: Text[30];
        AccountType: Text[1];
        SWIFTCode: Text[11];
        OtherPartyAddrDetailsExist: Boolean;

    procedure InitCodaImport(BankAccNo: Code[20])
    var
        EnterpriseNoDec: Decimal;
    begin
        BankAcc.Get(BankAccNo);

        with CompanyInfo do begin
            EnterpriseNo := '';
            Get();
            // numbers in VAT No
            EnterpriseNo := PaymJnlManagement.ConvertToDigit("Enterprise No.", MaxStrLen(EnterpriseNo));
            if EnterpriseNo = '' then
                EnterpriseNo := '0';
            if Evaluate(EnterpriseNoDec, EnterpriseNo) then
                if EnterpriseNoDec = 0 then
                    EnterpriseNo := PadStr('', 11, '0')
                else begin
                    if not EnterpriseNoCheck.MOD97Check("Enterprise No.") then
                        Error(Text000);
                    EnterpriseNo := '0' + EnterpriseNo;
                end;
        end;
        Clear(LineCounter);
        Clear(TotalDebit);
        Clear(TotalCredit);
        OnAfterInitCodaImport(BankAcc, EnterpriseNo, LineCounter, TotalDebit, TotalCredit);
    end;

    procedure CheckCodaHeader(var CodedBankStmtSrcLine: Record "CODA Statement Source Line"): Boolean
    var
        EnterpriseNum: Decimal;
    begin
        CodBankStmtSrcLine := CodedBankStmtSrcLine;
        with CodBankStmtSrcLine do begin
            if ID <> ID::Header then begin
                ID := ID::Header;
                Error(Text001, "Line No.", ID);
            end;
            ParseHeaderRecord;
            if not Evaluate(EnterpriseNum, '0' + VId[2]) then
                EnterpriseNum := 0;
            if (EnterpriseNum <> 0) and (EnterpriseNo <> VId[2]) then
                Error(Text002,
                  EnterpriseNo,
                  VId[2],
                  ID);
            if ProtocolNo <> BankAcc."Protocol No." then
                Error(Text003,
                  BankAcc.FieldCaption("Protocol No."),
                  BankAcc."Protocol No.",
                  BankAcc.TableCaption(),
                  BankAcc."No.",
                  ProtocolNo,
                  ID);
            if VersionCode <> BankAcc."Version Code" then
                Error(Text003,
                  BankAcc.FieldCaption("Version Code"),
                  BankAcc."Version Code",
                  BankAcc.TableCaption(),
                  BankAcc."No.",
                  VersionCode,
                  ID);
            if (VersionCode = '2') and (SWIFTCode <> '') then
                if SWIFTCode <> BankAcc."SWIFT Code" then
                    Error(Text003,
                      BankAcc.FieldCaption("SWIFT Code"),
                      BankAcc."SWIFT Code",
                      BankAcc.TableCaption(),
                      BankAcc."No.",
                      SWIFTCode,
                      ID);
        end;
        CodedBankStmtSrcLine := CodBankStmtSrcLine;
        exit(true);
    end;

    local procedure ParseHeaderRecord()
    begin
        with CodBankStmtSrcLine do begin
            ProtocolNo := CopyStr(Data, 12, 3);
            VersionCode := CopyStr(Data, 128, 1);
            if VersionCode = '1' then
                VId[1] := DelChr(CopyStr(Data, 61, 11), '>', ' ')
            else
                SWIFTCode := DelChr(CopyStr(Data, 61, 11));
            VId[2] := DelChr(CopyStr(Data, 72, 11), '>', ' ');
            "Transaction Date" := DDMMYY2Date(CopyStr(Data, 6, 6), false);
        end;
    end;

    procedure CheckOldBalance(var CodedBankStmtSrcLine: Record "CODA Statement Source Line"): Boolean
    var
        BankAccountNo: Text[30];
        IBANNumber: Text[34];
    begin
        CodBankStmtSrcLine := CodedBankStmtSrcLine;
        with CodBankStmtSrcLine do begin
            Evaluate("Statement No.", CopyStr(Data, 3, 3));
            BankAccountNo :=
              PaymJnlManagement.ConvertToDigit(
                BankAcc."Bank Account No.",
                MaxStrLen(BankAcc."Bank Account No."));
            IBANNumber := DelChr(BankAcc.IBAN);
            AccountType := CopyStr(Data, 2, 1);
            case AccountType of
                ' ', '0':
                    if BankAccountNo <> CopyStr(Data, 6, 12) then
                        Error(Text003,
                          BankAcc.FieldCaption("Bank Account No."),
                          BankAcc."Bank Account No.",
                          BankAcc.TableCaption(),
                          BankAcc."No.",
                          CopyStr(Data, 6, 12),
                          ID);
                '2':
                    if IBANNumber <> CopyStr(Data, 6, 16) then
                        Error(Text003,
                          BankAcc.FieldCaption(IBAN),
                          BankAcc.IBAN,
                          BankAcc.TableCaption(),
                          BankAcc."No.",
                          CopyStr(Data, 6, 16),
                          ID);
                else
                    Error(Text017);
            end;
            if Data[43] = '0' then
                Evaluate(Amount, CopyStr(Data, 44, 15))
            else
                Evaluate(Amount, '-' + CopyStr(Data, 44, 15));
            Amount := Amount / 1000;
            "Transaction Date" := DDMMYY2Date(CopyStr(Data, 59, 6), false);
            Evaluate("CODA Statement No.", CopyStr(Data, 126, 3));
            Evaluate(CODAStatementNo, CopyStr(Data, 3, 3));
        end;
        CodedBankStmtSrcLine := CodBankStmtSrcLine;
        exit(true);
    end;

    procedure CheckNewBalance(var CodedBankStmtSrcLine: Record "CODA Statement Source Line"; AccountType2: Text[1]): Boolean
    var
        BankAccountNo: Text[30];
        IBANNumber: Text[34];
    begin
        CodBankStmtSrcLine := CodedBankStmtSrcLine;
        AccountType := AccountType2;
        with CodBankStmtSrcLine do begin
            Evaluate("Statement No.", Format(CODAStatementNo));
            BankAccountNo :=
              PaymJnlManagement.ConvertToDigit(
                BankAcc."Bank Account No.",
                MaxStrLen(BankAcc."Bank Account No."));
            IBANNumber := DelChr(BankAcc.IBAN);
            case AccountType of
                ' ', '0':
                    if BankAccountNo <> CopyStr(Data, 5, 12) then
                        Error(Text005,
                          BankAcc.FieldCaption("Bank Account No."),
                          BankAcc.TableCaption(),
                          BankAcc."No.",
                          ID);
                '2':
                    if IBANNumber <> CopyStr(Data, 5, 16) then
                        Error(Text005,
                          BankAcc.FieldCaption(IBAN),
                          BankAcc.TableCaption(),
                          BankAcc."No.",
                          ID);
                else
                    Error(Text017);
            end;
            if Data[42] = '0' then
                Evaluate(Amount, CopyStr(Data, 43, 15))
            else
                Evaluate(Amount, '-' + CopyStr(Data, 43, 15));
            Amount := Amount / 1000;
            "Transaction Date" := DDMMYY2Date(CopyStr(Data, 58, 6), false);
        end;
        CodedBankStmtSrcLine := CodBankStmtSrcLine;
        exit(true);
    end;

    procedure CheckCodaTrailer(var CodedBankStmtSrcLine: Record "CODA Statement Source Line"): Boolean
    begin
        CodBankStmtSrcLine := CodedBankStmtSrcLine;
        with CodBankStmtSrcLine do begin
            if ID <> ID::Trailer then begin
                ID := ID::Trailer;
                Error(Text001, "Line No.", ID);
            end;
            ParseTrailerRecord;
            if LineCounter[1] <> LineCounter[2] then
                Error(Text006,
                  LineCounter[1], LineCounter[2]);
            if TotalDebit[1] <> TotalDebit[2] then
                Error(Text007,
                  TotalDebit[1], TotalDebit[2]);
            if TotalCredit[1] <> TotalCredit[2] then
                Error(Text008,
                  TotalCredit[1], TotalCredit[2]);
        end;
        CodedBankStmtSrcLine := CodBankStmtSrcLine;
        exit(true);
    end;

    local procedure ParseTrailerRecord()
    begin
        with CodBankStmtSrcLine do begin
            Evaluate(LineCounter[2], CopyStr(Data, 17, 6));
            Evaluate(TotalDebit[2], CopyStr(Data, 23, 15));
            Evaluate(TotalCredit[2], CopyStr(Data, 38, 15));
            TotalDebit[2] := TotalDebit[2] / 1000;
            TotalCredit[2] := TotalCredit[2] / 1000;
        end;
    end;

    procedure CheckCodaRecord(var CodedBankStmtSrcLine: Record "CODA Statement Source Line"): Boolean
    begin
        CodBankStmtSrcLine := CodedBankStmtSrcLine;
        with CodBankStmtSrcLine do begin
            if ID in [ID::Movement, ID::Information, ID::"Free Message"] then
                ParseDataRecord
            else
                Error(Text009, "Line No.", ID);
        end;
        CodedBankStmtSrcLine := CodBankStmtSrcLine;
        exit(true);
    end;

    local procedure ParseDataRecord()
    begin
        with CodBankStmtSrcLine do begin
            // Common Stuff
            Evaluate("Item Code", CopyStr(Data, 2, 1));
            if not Evaluate("Sequence No.", CopyStr(Data, 3, 4)) then
                Error(Text010,
                  FieldCaption("Sequence No."), Data);
            if not Evaluate("Detail No.", CopyStr(Data, 7, 4)) then
                Error(Text010,
                  FieldCaption("Detail No."), Data);
            if not Evaluate("Binding Code", CopyStr(Data, 128, 1)) then
                Error(Text010,
                  FieldCaption("Binding Code"), Data);

            // Specific Stuff
            case ID of
                ID::Movement:
                    ParseMovementRecord;
                ID::Information:
                    ParseInformationRecord;
                ID::"Free Message":
                    ParseFreeMessageRecord;
            end;
        end
    end;

    local procedure ParseMovementRecord()
    begin
        with CodBankStmtSrcLine do begin
            if not Evaluate("Sequence Code", CopyStr(Data, 126, 1)) then
                Error(Text010,
                  FieldCaption("Sequence Code"), Data);
            case "Item Code" of
                '1':
                    begin
                        if BankAcc."Version Code" = '1' then begin
                            Evaluate("Bank Reference No.", CopyStr(Data, 11, 13));
                            Evaluate("Ext. Reference No.", CopyStr(Data, 24, 8));
                        end else
                            Evaluate("Bank Reference No.", CopyStr(Data, 11, 21));
                        if Data[32] = '0' then
                            Evaluate(Amount, CopyStr(Data, 33, 15))
                        else
                            Evaluate(Amount, '-' + CopyStr(Data, 33, 15));
                        Amount := Amount / 1000;
                        "Transaction Date" := DDMMYY2Date(CopyStr(Data, 48, 6), true);
                        Evaluate("Transaction Type", CopyStr(Data, 54, 1));
                        Evaluate("Transaction Family", CopyStr(Data, 55, 2));
                        Evaluate(Transaction, CopyStr(Data, 57, 2));
                        Evaluate("Transaction Category", CopyStr(Data, 59, 3));
                        Evaluate("Message Type", CopyStr(Data, 62, 1));
                        if "Message Type" = "Message Type"::"Standard format" then begin
                            Evaluate("Type Standard Format Message", CopyStr(Data, 63, 3));
                            Evaluate("Statement Message", CopyStr(Data, 66, 50));
                        end else begin
                            Evaluate("Statement Message", CopyStr(Data, 63, 53));
                            "Statement Message" := DelChr("Statement Message", '>', ' ');
                        end;
                        "Posting Date" := DDMMYY2Date(CopyStr(Data, 116, 6), true);
                        Evaluate("Statement No.", Format(CODAStatementNo));
                        Evaluate("Globalisation Code", CopyStr(Data, 125, 1));
                    end;
                '2':
                    begin
                        Evaluate("Statement Message", CopyStr(Data, 11, 53));
                        "Statement Message" := DelChr("Statement Message", '>', ' ');
                        if BankAcc."Version Code" = '1' then begin
                            Evaluate("Customer Reference", CopyStr(Data, 64, 26));
                            Evaluate("Original Transaction Currency", CopyStr(Data, 90, 3));
                            Evaluate("Original Transaction Amount", '0' + DelChr(CopyStr(Data, 93, 15), '=', ' '));
                        end else begin
                            Evaluate("Customer Reference", DelChr(CopyStr(Data, 64, 35), '<>', ' '));
                            Evaluate("SWIFT Address", DelChr(CopyStr(Data, 99, 11)));
                        end;
                    end;
                '3':
                    if BankAcc."Version Code" = '1' then begin
                        Evaluate("Bank Account No. Other Party", CopyStr(Data, 11, 12));
                        Evaluate("Internal Codes Other Party", CopyStr(Data, 23, 10));
                        Evaluate("Ext. Acc. No. Other Party", CopyStr(Data, 33, 15));
                        Evaluate("Name Other Party", CopyStr(Data, 48, 26));
                        Evaluate("Address Other Party", CopyStr(Data, 74, 26));
                        Evaluate("City Other Party", CopyStr(Data, 100, 26));
                    end else begin
                        Evaluate("Bank Account No. Other Party", DelChr(CopyStr(Data, 11, 34)));
                        Evaluate("Name Other Party", CopyStr(Data, 48, 35));
                        Evaluate("Statement Message", CopyStr(Data, 83, 43));
                    end;
                else
                    Error(Text012,
                      FieldCaption("Item Code"), "Line No.", "Item Code");
            end;

            // checksum
            if "Detail No." = 0 then
                UpdateTotalAmount;
        end;
    end;

    local procedure ParseInformationRecord()
    begin
        with CodBankStmtSrcLine do begin
            if not Evaluate("Sequence Code", CopyStr(Data, 126, 1)) then
                Error(Text010,
                  FieldCaption("Sequence Code"), Data);
            case "Item Code" of
                '1':
                    begin
                        if BankAcc."Version Code" = '1' then begin
                            Evaluate("Bank Reference No.", CopyStr(Data, 11, 13));
                            Evaluate("Ext. Reference No.", CopyStr(Data, 24, 8));
                        end else
                            Evaluate("Bank Reference No.", CopyStr(Data, 11, 21));
                        Evaluate("Transaction Type", CopyStr(Data, 32, 1));
                        Evaluate("Transaction Family", CopyStr(Data, 33, 2));
                        Evaluate(Transaction, CopyStr(Data, 35, 2));
                        Evaluate("Transaction Category", CopyStr(Data, 37, 3));
                        Evaluate("Message Type", CopyStr(Data, 40, 1));
                        if "Message Type" = "Message Type"::"Standard format" then begin
                            Evaluate("Type Standard Format Message", CopyStr(Data, 41, 3));
                            Evaluate("Statement Message", CopyStr(Data, 44, 70));
                        end else begin
                            Evaluate("Statement Message", CopyStr(Data, 41, 73));
                            "Statement Message" := DelChr("Statement Message", '<>', ' ');
                        end;
                        OtherPartyAddrDetailsExist := (BankAcc."Version Code" = '2') and ("Type Standard Format Message" = 1);
                        if OtherPartyAddrDetailsExist then begin
                            Evaluate("Name Other Party", CopyStr(Data, 44, 35));
                            "Name Other Party" := DelChr("Name Other Party", '<>', ' ');
                        end;
                    end;
                '2':
                    begin
                        Evaluate("Statement Message", CopyStr(Data, 11, 105));
                        "Statement Message" := DelChr("Statement Message", '<>', ' ');
                        if OtherPartyAddrDetailsExist then begin
                            Evaluate("Address Other Party", CopyStr(Data, 11, 35));
                            "Address Other Party" := DelChr("Address Other Party", '<>', ' ');
                            Evaluate("City Other Party", CopyStr(Data, 46, 35));
                            "City Other Party" := DelChr("City Other Party", '<>', ' ');
                        end;
                    end;
                '3':
                    begin
                        Evaluate("Statement Message", CopyStr(Data, 11, 90));
                        "Statement Message" := DelChr("Statement Message", '<>', ' ');
                    end;
                else
                    Error(Text012,
                      FieldCaption("Item Code"), "Line No.", "Item Code");
            end;
        end;
    end;

    local procedure ParseFreeMessageRecord()
    begin
        with CodBankStmtSrcLine do begin
            if BankAcc."Version Code" = '1' then begin
                Evaluate("Bank Reference No.", CopyStr(Data, 11, 13));
                Evaluate("Ext. Reference No.", CopyStr(Data, 24, 8));
                Evaluate("Message Type", CopyStr(Data, 32, 1));
                if "Message Type" = "Message Type"::"Standard format" then begin
                    Evaluate("Type Standard Format Message", CopyStr(Data, 33, 3));
                    Evaluate("Statement Message", CopyStr(Data, 36, 77));
                end else begin
                    Evaluate("Statement Message", CopyStr(Data, 33, 80));
                    "Statement Message" := DelChr("Statement Message", '>', ' ');
                end;
            end else begin
                Evaluate("Bank Reference No.", CopyStr(Data, 11, 21));
                Evaluate("Statement Message", CopyStr(Data, 33, 80));
                "Statement Message" := DelChr("Statement Message", '>', ' ');
            end;

            if Evaluate("Transaction Family", CopyStr(Data, 113, 2)) then;
            if Evaluate(Transaction, CopyStr(Data, 115, 2)) then;
        end
    end;

    procedure UpdateStatementNo(var CodedBankStmtSrcLine: Record "CODA Statement Source Line"; xStatementNo: Code[20]; StatementNo: Code[20]): Code[20]
    begin
        with CodBankStmtSrcLine do begin
            SetFilter("Bank Account No.", CodedBankStmtSrcLine."Bank Account No.");
            SetFilter("Statement No.", xStatementNo);
            if FindFirst() then
                repeat
                    Rename("Bank Account No.", StatementNo, "Line No.");
                until FindFirst = false;
        end;
        exit(StatementNo);
    end;

    procedure UpdateTotalAmount()
    begin
        with CodBankStmtSrcLine do begin
            if Amount > 0 then
                TotalCredit[1] := TotalCredit[1] + Amount
            else
                TotalDebit[1] := TotalDebit[1] - Amount
        end;
    end;

    procedure UpdateLineCounter(var CodedBankStmtSrcLine: Record "CODA Statement Source Line")
    begin
        with CodedBankStmtSrcLine do
            if (ID > ID::Header) and (ID < ID::Trailer) then
                LineCounter[1] := LineCounter[1] + 1;
    end;

    procedure Success()
    begin
        Message(Text013, LineCounter[1], TotalDebit[1], TotalCredit[1], SkippedLines);

        Clear(LineCounter);
        Clear(TotalDebit);
        Clear(TotalCredit);
    end;

    procedure SkipLine()
    begin
        SkippedLines := SkippedLines + 1
    end;

    procedure DDMMYY2Date(DDMMYY: Text; AllowInvalidDate: Boolean): Date
    var
        Day: Integer;
        Month: Integer;
        Year: Integer;
        YearTxt: Text;
    begin
        if AllowInvalidDate then begin
            DDMMYY := DelChr(DDMMYY, '=', DelChr(DDMMYY, '=', '0123456789'));
            if StrLen(DDMMYY) <> 6 then
                exit(0D);
            if not Evaluate(Day, CopyStr(DDMMYY, 1, 2)) then
                exit(0D);
            if not Evaluate(Month, CopyStr(DDMMYY, 3, 2)) then
                exit(0D);
            YearTxt := '20' + CopyStr(DDMMYY, 5, 2);
            if not Evaluate(Year, YearTxt) then
                exit(0D);
        end;
        Evaluate(Day, CopyStr(DDMMYY, 1, 2));
        Evaluate(Month, CopyStr(DDMMYY, 3, 2));
        YearTxt := '20' + CopyStr(DDMMYY, 5, 2);
        Evaluate(Year, YearTxt);
        exit(DMY2Date(Day, Month, Year));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitCodaImport(var BankAcc: record "Bank Account"; var EnterpriseNo: Text[11]; var LineCounter: array[2] of Integer; var TotalDebit: array[2] of Decimal; var TotalCredit: array[2] of Decimal)
    begin
    end;
}

