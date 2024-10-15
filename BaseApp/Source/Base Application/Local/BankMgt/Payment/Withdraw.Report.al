﻿// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Reflection;
using System.IO;

report 10881 Withdraw
{
    Caption = 'Withdraw';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Payment Header"; "Payment Header")
        {
            DataItemTableView = sorting("No.");
            MaxIteration = 1;
            dataitem("Payment Line"; "Payment Line")
            {
                DataItemLink = "No." = field("No.");
                DataItemTableView = sorting("No.", "Line No.");

                trigger OnAfterGetRecord()
                var
                    GLAcct: Record "G/L Account";
                    Cust: Record Customer;
                    Vend: Record Vendor;
                    BankAcct: Record "Bank Account";
                    FixedAsset: Record "Fixed Asset";
                    PaymentClass: Record "Payment Class";
                    RecordCode: Text;
                    OperationCode: Text;
                    FromPaymentNo: Text;
                    CustName: Text;
                    CustBankName: Text;
                    BankBranchNo: Text;
                    AgencyCode: Text;
                    BankAccountNo: Text;
                    Designation: Text;
                    PrintAmount: Text;
                    ExportedText: Text;
                begin
                    TestField("Account No.");

                    if StrLen("Bank Branch No.") > 5 then
                        Error(Text008, "Bank Account Name");

                    if StrLen("Agency Code") > 5 then
                        Error(Text008, "Bank Account Name");

                    if StrLen("Bank Account No.") > 11 then
                        Error(Text008, "Bank Account Name");

                    if not "RIB Checked" then
                        Error(Text009, "Bank Account Name", "Account No.");

                    if "Currency Code" <> "Payment Header"."Currency Code" then
                        Error(Text010);

                    if "Due Date" <> DueDate then
                        Error(Text011);

                    PaymentClass.Get("Payment Header"."Payment Class");
                    if (PaymentClass."Line No. Series" <> '') and ("Document No." = '') then
                        Error(Text012);

                    RecordCode := '06';
                    OperationCode := '08';
                    FromPaymentNo := PadStr("Payment Header"."National Issuer No.", 6);

                    case "Account Type" of
                        "Account Type"::"G/L Account":
                            begin
                                GLAcct.Get("Account No.");
                                CustName := PadStr(GLAcct.Name, 24);
                            end;
                        "Account Type"::Customer:
                            begin
                                Cust.Get("Account No.");
                                CustName := PadStr(Cust.Name, 24);
                            end;
                        "Account Type"::Vendor:
                            begin
                                Vend.Get("Account No.");
                                CustName := PadStr(Vend.Name, 24);
                            end;
                        "Account Type"::"Bank Account":
                            begin
                                BankAcct.Get("Account No.");
                                CustName := PadStr(BankAcct.Name, 24);
                            end;
                        "Account Type"::"Fixed Asset":
                            begin
                                FixedAsset.Get("Account No.");
                                CustName := PadStr(FixedAsset.Description, 24);
                            end;
                    end;

                    "Payment Header".CalcFields("Status Name");

                    CustBankName := PadStr("Bank Account Name", 20);
                    BankBranchNo := PADSTR2("Bank Branch No.", 5, '0');
                    AgencyCode := PADSTR2("Agency Code", 5, '0');
                    BankAccountNo := PADSTR2("Bank Account No.", 11, '0');
                    Designation := PadStr("Payment Header"."Status Name", 31);
                    PrintAmount := FormatAmount(Amount, 16);
                    ExportedText :=
                      RecordCode +
                      OperationCode +
                      PadStr('', 8) +
                      FromPaymentNo +
                      PadStr('', 12) +
                      CustName +
                      CustBankName +
                      PadStr('', 12) +
                      AgencyCode +
                      BankAccountNo +
                      PrintAmount +
                      Designation +
                      BankBranchNo;

                    ExportFile.Write(PadStr(ExportedText, 160));
                end;

                trigger OnPostDataItem()
                var
                    PaymentHeader: Record "Payment Header";
                    RecordCode: Text;
                    OperationCode: Text;
                    FromPaymentNo: Text;
                    PrintAmount: Text;
                    ExportedText: Text;
                begin
                    RecordCode := '08';
                    OperationCode := '08';
                    FromPaymentNo := PadStr("Payment Header"."National Issuer No.", 6);
                    PrintAmount := FormatAmount("Payment Header".Amount, 16);
                    ExportedText :=
                      RecordCode +
                      OperationCode +
                      PadStr('', 8) +
                      FromPaymentNo +
                      PadStr('', 84) +
                      PrintAmount;

                    ExportFile.Write(PadStr(ExportedText, 160));

                    PaymentHeader := "Payment Header";
                    PaymentHeader."File Export Completed" := true;
                    PaymentHeader.Modify();
                end;
            }

            trigger OnAfterGetRecord()
            var
                RecordCode: Text;
                OperationCode: Text;
                FromPaymentNo: Text;
                ExecutionDate: Text;
                CompanyName: Text;
                CurrencyIdentifier: Code[1];
                BankBranchNo: Text;
                AgencyCode: Text;
                BankAccountNo: Text;
                ExportedText: Text;
            begin
                TestField("National Issuer No.");
                TestField("No.");

                if StrLen("Bank Branch No.") > 5 then
                    Error(Text003, "Bank Account No.");

                if StrLen("Agency Code") > 5 then
                    Error(Text003, "Bank Account No.");

                if StrLen("Bank Account No.") > 11 then
                    Error(Text003, "Bank Account No.");

                if not "RIB Checked" then
                    Error(Text004, "No.");

                if ("Currency Code" <> '') and ("Currency Code" <> GLSetup."LCY Code") then
                    Error(Text006, GLSetup."LCY Code");

                case "Currency Code" = '' of
                    true:
                        CurrencyIdentifier := 'E';
                    false:
                        CurrencyIdentifier := 'F';
                end;

                CalcFields(Amount);

                RecordCode := '03';
                OperationCode := '08';
                FromPaymentNo := PadStr("National Issuer No.", 6);
                ExecutionDate := Format(DueDate, 4, '<Day,2><Month,2>') + CopyStr(Format(DueDate, 2, '<Year,2>'), 2, 1);
                CompanyName := PadStr(CompanyInfo.Name, 24);
                BankBranchNo := PADSTR2("Bank Branch No.", 5, '0');
                AgencyCode := PADSTR2("Agency Code", 5, '0');
                BankAccountNo := PADSTR2("Bank Account No.", 11, '0');
                ExportedText :=
                  RecordCode +
                  OperationCode +
                  PadStr('', 8) +
                  FromPaymentNo +
                  PadStr('', 7) +
                  ExecutionDate +
                  CompanyName +
                  PadStr('', 26) +
                  CurrencyIdentifier +
                  PadStr('', 5) +
                  AgencyCode +
                  BankAccountNo +
                  PadStr('', 47) +
                  BankBranchNo;

                ExportFile.Write(PadStr(ExportedText, 160));
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
                    Caption = 'Options';
                    field(DueDate; DueDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Due Date';
                        ToolTip = 'Specifies the due date on the entry.';
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
    var
        ToFile: Text[260];
    begin
        ExportFile.Close();
        ToFile := Text013;
        Download(ExportFileName, GetCaption(), '', Text014, ToFile);
    end;

    trigger OnPreReport()
    var
        FileMgt: Codeunit "File Management";
    begin
        CompanyInfo.Get();
        CompanyInfo.TestField(Name);

        GLSetup.Get();
        ExportFileName := FileMgt.ServerTempFileName('');

        ExportFile.TextMode := true;
        ExportFile.WriteMode := true;
        ExportFile.Create(ExportFileName);
    end;

    var
        GLSetup: Record "General Ledger Setup";
        CompanyInfo: Record "Company Information";
        ExportFile: File;
        ExportFileName: Text;
        DueDate: Date;
        Text003: Label 'Bank Account No. %1 is too long. Please verify before continuing.';
        Text004: Label 'The RIB of the company''s bank account %1 is incorrect. Please verify before continuing.';
        Text006: Label 'You can only use currency code %1.';
        Text008: Label 'Bank Account No. %1 is too long. Please verify before continuing.';
        Text009: Label 'The RIB of bank account %1 of customer %2 is incorrect. Please verify before continuing.';
        Text010: Label 'All withdraws must refer to the same currency.';
        Text011: Label 'All withdraws must have the same due date.';
        Text012: Label 'All withdraws must have the same document number.';
        Text013: Label 'default.txt';
        Text014: Label 'Text Files|*.txt|All Files|*.*';

    local procedure GetCaption() Result: Text[50]
    var
        AllObjWithCaption: Record AllObjWithCaption;
        ID: Integer;
    begin
        Result := '';
        if not Evaluate(ID, DelChr(CurrReport.ObjectId(false), '=', DelChr(CurrReport.ObjectId(false), '=', '0123456789'))) then
            exit;

        if not AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Report, ID) then
            exit;

        exit(CopyStr(AllObjWithCaption."Object Caption", 1, MaxStrLen(Result)));
    end;

    local procedure FormatAmount(Amount: Decimal; Width: Integer): Text
    var
        FormatAmount: Text[50];
    begin
        FormatAmount := ConvertStr(Format(Amount, Width, '<Precision,2:2><Integer><Decimal><Comma,,>'), ' ', '0');
        FormatAmount := '0' + CopyStr(FormatAmount, 1, Width - 3) + CopyStr(FormatAmount, Width - 1, 2);
        exit(FormatAmount);
    end;

    local procedure PADSTR2(String: Text[1024]; Length: Integer; FillCharacter: Text[1]): Text[1024]
    var
        PaddingLength: Integer;
    begin
        PaddingLength := Length - StrLen(String);

        case true of
            PaddingLength <= 0:
                exit(PadStr(String, Length, FillCharacter));
            PaddingLength > 0:
                exit(PadStr('', PaddingLength, FillCharacter) + String);
        end;
    end;
}

