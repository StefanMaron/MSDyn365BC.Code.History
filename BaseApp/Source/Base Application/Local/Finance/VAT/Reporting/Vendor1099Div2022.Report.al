#if not CLEAN25
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;
using System.Utilities;

report 10181 "Vendor 1099 Div 2022"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/VAT/Reporting/Vendor1099Div2022.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Vendor 1099 Div 2022';
    UsageCategory = ReportsAndAnalysis;
    ObsoleteReason = 'Moved to IRS Forms App.';
    ObsoleteState = Pending;
    ObsoleteTag = '25.0';

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";
            RequestFilterHeading = 'Vendor Filter';
            column(Void; Void)
            {
            }
            column(CompanyAddress1; CompanyAddress[1])
            {
            }
            column(CompanyAddress2; CompanyAddress[2])
            {
            }
            column(GetAmtCombinedDivCodeAB; GetAmt('DIV-01-A') + GetAmt('DIV-01-B') + GetAmt('DIV-05') + GetAmt('DIV-06'))
            {
            }
            column(GetAmtDIV01B; GetAmt('DIV-01-B'))
            {
            }
            column(CompanyAddress3; CompanyAddress[3])
            {
            }
            column(CompanyAddress4; CompanyAddress[4])
            {
            }
            column(CompanyAddress5; CompanyAddress[5])
            {
            }
            column(FATCA; FATCA)
            {
            }
            column(GetAmtCombinedDivCodeBC; GetAmt('DIV-02-A') + GetAmt('DIV-02-B') + GetAmt('DIV-02-C') + GetAmt('DIV-02-D'))
            {
            }
            column(CompanyInfoFederalIDNo; CompanyInfo."Federal ID No.")
            {
            }
            column(FederalIDNo_Vendor; "Federal ID No.")
            {
            }
            column(GetAmtDIV02B; GetAmt('DIV-02-B'))
            {
            }
            column(GetAmtDIV02C; GetAmt('DIV-02-C'))
            {
            }
            column(Name_Vendor; Name)
            {
            }
            column(Name2_Vendor; "Name 2")
            {
            }
            column(GetAmtDIV02D; GetAmt('DIV-02-D'))
            {
            }
            column(GetAmtDIV02E; GetAmt('DIV-02-E'))
            {
            }
            column(GetAmtDIV02F; GetAmt('DIV-02-F'))
            {
            }
            column(GetAmtDIV03; GetAmt('DIV-03'))
            {
            }
            column(Address_Vendor; Address)
            {
            }
            column(Address2_Vendor; "Address 2")
            {
            }
            column(GetAmtDIV04; GetAmt('DIV-04'))
            {
            }
            column(Address3_Vendor; VendorAddress)
            {
            }
            column(No_Vendor; "No.")
            {
            }
            column(GetAmtDIV07; GetAmt('DIV-07'))
            {
            }
            column(GetAmtDIV09; GetAmt('DIV-09'))
            {
            }
            column(GetAmtDIV06; GetAmt('DIV-06'))
            {
            }
            column(GetAmtDIV05; GetAmt('DIV-05'))
            {
            }
            column(GetAmtDIV10; GetAmt('DIV-10'))
            {
            }
            column(GetAmtDIV11; GetAmt('DIV-11'))
            {
            }
            column(GetAmtDIV12; GetAmt('DIV-12'))
            {
            }
            column(GetAmtDIV13; GetAmt('DIV-13'))
            {
            }
            column(PageGroupNo; PageGroupNo)
            {
            }
            column(YearDigits; YearDigits)
            {
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number);
                MaxIteration = 1;
                column(FormCounter; FormCounter)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    FormCounter := FormCounter + 1;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                Clear(Amounts);
                Clear(Void);
                Clear(FATCA);

                // Special handling for Test Printing
                if TestPrintSwitch then begin
                    if FirstVendor then begin
                        Name := PadStr('x', MaxStrLen(Name), 'X');
                        Address := PadStr('x', MaxStrLen(Address), 'X');
                        VendorAddress := PadStr('x', MaxStrLen(VendorAddress), 'X');
                        Void := 'X';
                        FATCA := 'X';
                        "No." := PadStr('x', MaxStrLen("No."), 'X');
                        "Federal ID No." := PadStr('x', MaxStrLen("Federal ID No."), 'X');
                    end else
                        CurrReport.Break();
                end else begin
                    PrintThis := false;
                    IRS1099Management.ProcessVendorInvoices(Amounts, "No.", PeriodDate, Codes, LastLineNo, 'DIV*');
                    PrintThis := IRS1099Management.AnyCodeWithUpdatedAmountExceedMinimum(Codes, Amounts, LastLineNo);
                    if not PrintThis then
                        CurrReport.Skip();

                    VendorAddress := IRS1099Management.GetFormattedVendorAddress(Vendor);
                    if "FATCA filing requirement" then
                        FATCA := 'X'
                end;

                if VendorNo = 2 then begin
                    PageGroupNo += 1;
                    VendorNo := 0;
                end;
                VendorNo += 1;
            end;

            trigger OnPreDataItem()
            begin
                VendorNo := 0;
                PageGroupNo := 0;

                UpdatePeriodDateArray();

                // Fill in the Codes used on this particular 1099 form
                Clear(Codes);
                Clear(LastLineNo);

                // 2004
                Codes[1] := 'DIV-01-A';
                Codes[2] := 'DIV-01-B';
                Codes[3] := 'DIV-02-A';
                Codes[4] := 'DIV-02-B';
                Codes[5] := 'DIV-02-C';
                Codes[6] := 'DIV-02-D';
                Codes[7] := 'DIV-02-E';
                Codes[8] := 'DIV-02-F';
                Codes[9] := 'DIV-03';
                Codes[10] := 'DIV-04';
                Codes[11] := 'DIV-05';
                Codes[12] := 'DIV-06';
                Codes[13] := 'DIV-07';
                Codes[14] := 'DIV-08';
                Codes[15] := 'DIV-09';
                Codes[16] := 'DIV-10';
                Codes[17] := 'DIV-11';
                Codes[18] := 'DIV-12';
                Codes[19] := 'DIV-13';

                LastLineNo := 19;

                // Initialize Company Address. As side effect, will read CompanyInfo record
                FormatCompanyAddress(CompanyAddress, CompanyInfo, TestPrintSwitch);
                // Initialize flag used for Test Printing only
                FirstVendor := true;
                YearDigits := Format(YearValue);
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
                    field(Year; YearValue)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Calendar Year';
                        ToolTip = 'Specifies the tax year for the 1099 forms that you want to print. The default is the work date year. The taxes may apply to the previous calendar year so you may want to change this date if nothing prints.';

                        trigger OnValidate()
                        begin
                            if (YearValue < 1980) or (YearValue > 2060) then
                                Error(YearNotCorrectErr);
                            UpdatePeriodDateArray();
                        end;
                    }
                    field(TestPrint; TestPrintSwitch)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Test Print';
                        ToolTip = 'Specifies if you want to print the 1099 form on blank paper before you print them on dedicated forms.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            TestPrintSwitch := false;
            YearValue := Date2DMY(WorkDate(), 3);
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        IRS1099Management.ThrowErrorfUpgrade2022Needed();
    end;

    var
        CompanyInfo: Record "Company Information";
        IRS1099Management: Codeunit "IRS 1099 Management";
        PeriodDate: array[2] of Date;
        YearValue: Integer;
        TestPrintSwitch: Boolean;
        Void: Code[1];
        FATCA: Code[1];
        CompanyAddress: array[5] of Text[50];
        FirstVendor: Boolean;
        PrintThis: Boolean;
        VendorAddress: Text[30];
        Codes: array[20] of Code[10];
        Amounts: array[20] of Decimal;
        LastLineNo: Integer;
        i: Integer;
        FormCounter: Integer;
        VendorNo: Integer;
        PageGroupNo: Integer;
        YearNotCorrectErr: Label 'You must enter a valid year, eg 1993.';
        YearDigits: Text;

    procedure GetAmt("Code": Code[10]): Decimal
    begin
        exit(IRS1099Management.GetAmtByCode(Codes, Amounts, LastLineNo, Code, TestPrintSwitch));
    end;

    procedure FormatCompanyAddress(var CompanyAddress: array[5] of Text; var CompanyInfo: Record "Company Information"; TestPrint: Boolean)
    begin
        if TestPrint then begin
            for i := 1 to ArrayLen(CompanyAddress) do
                CompanyAddress[i] := PadStr('x', MaxStrLen(CompanyAddress[i]), 'X');
            exit;
        end;
        CompanyInfo.Get();

        Clear(CompanyAddress);
        CompanyAddress[1] := CompanyInfo.Name;
        CompanyAddress[2] := CompanyInfo.Address;
        CompanyAddress[3] := CompanyInfo."Address 2";
        if StrLen(CompanyInfo.City + ', ' + CompanyInfo.County + '  ' + CompanyInfo."Post Code") > MaxStrLen(CompanyAddress[4]) then begin
            CompanyAddress[4] := CompanyInfo.City;
            CompanyAddress[5] := CompanyInfo.County + '  ' + CompanyInfo."Post Code";
            if CompressArray(CompanyAddress) = ArrayLen(CompanyAddress) then begin
                CompanyAddress[3] := CompanyAddress[4];
                // lose address 2 to add phone no.
                CompanyAddress[4] := CompanyAddress[5];
            end;
            CompanyAddress[5] := CompanyInfo."Phone No.";
        end else
            if (CompanyInfo.City <> '') and (CompanyInfo.County <> '') then begin
                CompanyAddress[4] := CompanyInfo.City + ', ' + CompanyInfo.County + '  ' + CompanyInfo."Post Code";
                CompanyAddress[5] := CompanyInfo."Phone No.";
            end else begin
                CompanyAddress[4] := DelChr(CompanyInfo.City + ' ' + CompanyInfo.County + ' ' + CompanyInfo."Post Code", '<>');
                CompanyAddress[5] := CompanyInfo."Phone No.";
            end;
        CompressArray(CompanyAddress);
    end;

    local procedure UpdatePeriodDateArray()
    begin
        PeriodDate[1] := DMY2Date(1, 1, YearValue);
        PeriodDate[2] := DMY2Date(31, 12, YearValue);
    end;
}

#endif
