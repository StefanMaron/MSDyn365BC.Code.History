#if not CLEAN25
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Foundation.Company;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Utilities;
using System.Utilities;

report 10182 "Vendor 1099 Nec 2022"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/VAT/Reporting/Vendor1099Nec2022.rdlc';
    ApplicationArea = Basic, Suite;
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
            column(VoidBox; VoidBox)
            {
            }
            column(CompanyAddress1; CompanyAddress[1])
            {
            }
            column(GetAmtNEC01; IRS1099Management.GetAmtByCode(Codes, Amounts, LastLineNo, 'NEC-01', TestPrintSwitch))
            {
            }
            column(GetAmtNEC02; IRS1099Management.GetAmtByCode(Codes, Amounts, LastLineNo, 'NEC-02', TestPrintSwitch))
            {
            }
            column(GetAmtNEC04; IRS1099Management.GetAmtByCode(Codes, Amounts, LastLineNo, 'NEC-04', TestPrintSwitch))
            {
            }
            column(CompanyAddress2; CompanyAddress[2])
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
            column(Box2; Box2)
            {
            }
            column(CompanyInfoFederalIDNo; CompanyInfo."Federal ID No.")
            {
            }
            column(FederalIDNo_Vendor; "Federal ID No.")
            {
            }
            column(Name_Vendor; Name)
            {
            }
            column(Name2_Vendor; "Name 2")
            {
            }
            column(Address_Vendor; Address)
            {
            }
            column(Address3_Vendor; VendorAddress)
            {
            }
            column(No_Vendor; "No.")
            {
            }
            column(Address2_Vendor; "Address 2")
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
            var
                IRS1099FormBox: Record "IRS 1099 Form-Box";
            begin
                Clear(Amounts);
                Clear(VoidBox);
                Clear(FATCA);
                Clear(Box2);

                // Special handling for Test Printing
                if TestPrintSwitch then begin
                    if FirstVendor then begin
                        Name := PadStr('x', MaxStrLen(Name), 'X');
                        Address := PadStr('x', MaxStrLen(Address), 'X');
                        VendorAddress := PadStr('x', MaxStrLen(VendorAddress), 'X');
                        VoidBox := 'X';
                        FATCA := 'X';
                        Box2 := 'X';
                        "No." := PadStr('x', MaxStrLen("No."), 'X');
                        "Federal ID No." := PadStr('x', MaxStrLen("Federal ID No."), 'X');
                    end else
                        CurrReport.Break();
                end else begin   // not Test Printing
                    PrintThis := false;
                    // Check through all payments during calendar year
                    IRS1099Management.ProcessVendorInvoices(Amounts, "No.", PeriodDate, Codes, LastLineNo, 'NEC*');

                    PrintThis := IRS1099Management.AnyCodeWithUpdatedAmountExceedMinimum(Codes, Amounts, LastLineNo);
                    if not PrintThis then
                        CurrReport.Skip();

                    VendorAddress := IRS1099Management.GetFormattedVendorAddress(Vendor);
                    if IRS1099FormBox.Get(Codes[2]) then
                        if Amounts[2] >= IRS1099FormBox."Minimum Reportable" then
                            Box2 := 'X';
                    if "FATCA filing requirement" then
                        FATCA := 'X';
                end;

                if VendorNo = 3 then begin
                    PageGroupNo += 1;
                    VendorNo := 0;
                end;
                VendorNo += 1;
            end;

            trigger OnPreDataItem()
            begin
                VendorNo := 0;
                PageGroupNo := 0;

                // Create date range which covers the entire calendar year
                UpdatePeriodDateArray();

                // Fill in the Codes used on this particular 1099 form
                Clear(Codes);
                Clear(LastLineNo);
                Codes[1] := 'NEC-01';
                Codes[2] := 'NEC-02';
                Codes[4] := 'NEC-04';
                LastLineNo := 4;

                // Initialize Company Address. As side effect, will read CompanyInfo record
                IRS1099Management.FormatCompanyAddress(CompanyAddress, CompanyInfo, TestPrintSwitch);
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
                                Error(ValidYearErr);
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
        VoidBox: Code[1];
        FATCA: Code[1];
        CompanyAddress: array[5] of Text[50];
        Box2: Text[50];
        FirstVendor: Boolean;
        PrintThis: Boolean;
        VendorAddress: Text[30];
        Codes: array[20] of Code[10];
        Amounts: array[20] of Decimal;
        LastLineNo: Integer;
        FormCounter: Integer;
        PageGroupNo: Integer;
        VendorNo: Integer;
        ValidYearErr: Label 'You must enter a valid year, eg 1998.';
        YearDigits: Text;

    procedure ProcessVendorInvoices(VendorNo: Code[20]; PeriodDate: array[2] of Date)
    var
        TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary;
        EntryApplicationManagement: Codeunit "Entry Application Management";
        Invoice1099Amount: Decimal;
    begin
        EntryApplicationManagement.GetAppliedVendorEntries(
          TempVendorLedgerEntry, VendorNo, PeriodDate, true);
        TempVendorLedgerEntry.SetFilter("Document Type", '%1|%2', TempVendorLedgerEntry."Document Type"::Invoice, TempVendorLedgerEntry."Document Type"::"Credit Memo");
        TempVendorLedgerEntry.SetFilter("IRS 1099 Amount", '<>0');
        TempVendorLedgerEntry.SetFilter("IRS 1099 Code", 'NEC*');
        if TempVendorLedgerEntry.FindSet() then
            repeat
                IRS1099Management.Calculate1099Amount(
                  Invoice1099Amount, Amounts, Codes, LastLineNo, TempVendorLedgerEntry, TempVendorLedgerEntry."Amount to Apply");
            until TempVendorLedgerEntry.Next() = 0;
    end;

    local procedure UpdatePeriodDateArray()
    begin
        PeriodDate[1] := DMY2Date(1, 1, YearValue);
        PeriodDate[2] := DMY2Date(31, 12, YearValue);
    end;
}

#endif
