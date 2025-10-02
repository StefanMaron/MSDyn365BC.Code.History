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

report 10183 "Vendor 1099 Int 2022"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/VAT/Reporting/Vendor1099Int2022.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Vendor 1099 Interest 2022';
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
            column(CompanyInfoFederalIDNo; CompanyInfo."Federal ID No.")
            {
            }
            column(FederalIDNo_Vendor; "Federal ID No.")
            {
            }
            column(GetAmtINT01; GetAmt('INT-01'))
            {
            }
            column(Name_Vendor; Name)
            {
            }
            column(Name2_Vendor; "Name 2")
            {
            }
            column(GetAmtINT02; GetAmt('INT-02'))
            {
            }
            column(GetAmtINT03; GetAmt('INT-03'))
            {
            }
            column(Address_Vendor; Address)
            {
            }
            column(Address2_Vendor; "Address 2")
            {
            }
            column(GetAmtINT04; GetAmt('INT-04'))
            {
            }
            column(Address3_Vendor; "Address 3")
            {
            }
            column(No_Vendor; "No.")
            {
            }
            column(GetAmtINT06; GetAmt('INT-06'))
            {
            }
            column(GetAmtINT05; GetAmt('INT-05'))
            {
            }
            column(GetAmtINT08INT09; GetAmt('INT-08') + GetAmt('INT-09'))
            {
            }
            column(GetAmtINT09; GetAmt('INT-09'))
            {
            }
            column(GetAmtINT10; GetAmt('INT-10'))
            {
            }
            column(GetAmtINT11; GetAmt('INT-11'))
            {
            }
            column(GetAmtINT12; GetAmt('INT-12'))
            {
            }
            column(GetAmtINT13; GetAmt('INT-13'))
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
                    if FormCounter mod 2 = 0 then
                        FormCounter := 0;
                    FormCounter := FormCounter + 1;
                end;
            }

            trigger OnAfterGetRecord()
            var
                IRS1099Management: Codeunit "IRS 1099 Management";
            begin
                Clear(Amounts);
                Clear(Void);
                Clear(FATCA);

                // Special handling for Test Printing
                if TestPrintSwitch then begin
                    if FirstVendor then begin
                        Name := PadStr('x', MaxStrLen(Name), 'X');
                        Address := PadStr('x', MaxStrLen(Address), 'X');
                        "Address 3" := PadStr('x', MaxStrLen("Address 3"), 'X');
                        Void := 'X';
                        FATCA := 'X';
                        "No." := PadStr('x', MaxStrLen("No."), 'X');
                        "Federal ID No." := PadStr('x', MaxStrLen("Federal ID No."), 'X');
                    end else
                        CurrReport.Break();  // The End
                end else begin   // not Test Printing
                    PrintThis := false;
                    // Check through all payments during calendar year
                    IRS1099Management.ProcessVendorInvoices(Amounts, "No.", PeriodDate, Codes, LastLineNo, 'INT*');

                    // any printable amounts on this form?
                    for i := 1 to LastLineNo do
                        if FormBox.Get(Codes[i]) then begin
                            if FormBox."Minimum Reportable" < 0.0 then
                                if Amounts[i] <> 0.0 then begin
                                    Amounts[i] := -Amounts[i];
                                    PrintThis := true;
                                end;
                            if FormBox."Minimum Reportable" >= 0.0 then
                                if Amounts[i] >= FormBox."Minimum Reportable" then
                                    PrintThis := true;
                        end;
                    if not PrintThis then
                        CurrReport.Skip();

                    // Format City/State/ZIP address line
                    if StrLen(City + ', ' + County + '  ' + "Post Code") > MaxStrLen("Address 3") then
                        "Address 3" := City
                    else
                        if (City <> '') and (County <> '') then
                            "Address 3" := CopyStr(City + ', ' + County + '  ' + "Post Code", 1, MaxStrLen("Address 3"))
                        else
                            "Address 3" := CopyStr(DelChr(City + ' ' + County + ' ' + "Post Code", '<>'), 1, MaxStrLen("Address 3"));

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

                // Create date range which covers the entire calendar year
                UpdatePeriodDateArray();

                // Fill in the Codes used on this particular 1099 form
                Clear(Codes);
                Clear(LastLineNo);
                Codes[1] := 'INT-01';
                Codes[2] := 'INT-02';
                Codes[3] := 'INT-03';
                Codes[4] := 'INT-04';
                Codes[5] := 'INT-05';
                Codes[6] := 'INT-06';
                Codes[8] := 'INT-08';
                Codes[9] := 'INT-09';
                Codes[10] := 'INT-10';
                Codes[11] := 'INT-11';
                Codes[12] := 'INT-12';
                Codes[13] := 'INT-13';
                LastLineNo := 13;

                // Initialize Company Address. As side effect, will read CompanyInfo record
                FormatCompanyAddress();
                // Initialize flag used for Test Printing only
                FirstVendor := true;
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
                        ApplicationArea = BasicUS;
                        Caption = 'Calendar Year';
                        ToolTip = 'Specifies the tax year for the 1099 forms that you want to print. The default is the work date year. The taxes may apply to the previous calendar year so you may want to change this date if nothing prints.';

                        trigger OnValidate()
                        begin
                            if (YearValue < 1980) or (YearValue > 2060) then
                                Error('You must enter a valid year, eg 1993');
                            UpdatePeriodDateArray();
                        end;
                    }
                    field(TestPrint; TestPrintSwitch)
                    {
                        ApplicationArea = BasicUS;
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
    var
        IRS1099Management: Codeunit "IRS 1099 Management";
    begin
        IRS1099Management.ThrowUseNewIRSFormsFeatureMessage();
    end;

    var
        CompanyInfo: Record "Company Information";
        FormBox: Record "IRS 1099 Form-Box";
        TempAppliedEntry: Record "Vendor Ledger Entry" temporary;
        IRS1099Div: Report "Vendor 1099 Div";
        EntryAppMgt: Codeunit "Entry Application Management";
        PeriodDate: array[2] of Date;
        YearValue: Integer;
        TestPrintSwitch: Boolean;
        Void: Code[1];
        FATCA: Code[1];
        CompanyAddress: array[5] of Text[50];
        FirstVendor: Boolean;
        PrintThis: Boolean;
        "Address 3": Text[30];
        Codes: array[20] of Code[10];
        Amounts: array[20] of Decimal;
        LastLineNo: Integer;
        Invoice1099Amount: Decimal;
        i: Integer;
        FormCounter: Integer;
        PageGroupNo: Integer;
        VendorNo: Integer;
        YearDigits: Text;

    procedure ProcessVendorInvoices(VendorNo: Code[20]; PeriodDate: array[2] of Date)
    begin
        // search for invoices paid off by this payment
        EntryAppMgt.GetAppliedVendorEntries(TempAppliedEntry, VendorNo, PeriodDate, true);
        // search for invoices with 1099 amounts
        TempAppliedEntry.SetFilter("Document Type", '%1|%2', TempAppliedEntry."Document Type"::Invoice, TempAppliedEntry."Document Type"::"Credit Memo");
        TempAppliedEntry.SetFilter("IRS 1099 Amount", '<>0');
        TempAppliedEntry.SetRange("IRS 1099 Code", 'INT-', 'INT-99');
        if TempAppliedEntry.FindSet() then
            repeat
                Calculate1099Amount(TempAppliedEntry, TempAppliedEntry."Amount to Apply");
            until TempAppliedEntry.Next() = 0;
    end;

    procedure Calculate1099Amount(InvoiceEntry: Record "Vendor Ledger Entry"; AppliedAmount: Decimal)
    begin
        InvoiceEntry.CalcFields(Amount);
        Invoice1099Amount := -AppliedAmount * InvoiceEntry."IRS 1099 Amount" / InvoiceEntry.Amount;
        UpdateLines(InvoiceEntry."IRS 1099 Code", Invoice1099Amount);
    end;

    procedure UpdateLines("Code": Code[10]; Amount: Decimal): Integer
    begin
        i := 1;
        while (Codes[i] <> Code) and (i <= LastLineNo) do
            i := i + 1;

        if (Codes[i] = Code) and (i <= LastLineNo) then
            Amounts[i] := Amounts[i] + Amount
        else
            Error('Invoice %1 on vendor %2 has unknown 1099 interest code  %3',
              TempAppliedEntry."Entry No.", TempAppliedEntry."Vendor No.", Code);
        exit(i);   // returns code index found
    end;

    procedure GetAmt("Code": Code[10]): Decimal
    begin
        if TestPrintSwitch then
            exit(9999999.99); // test value

        i := 1;
        while (Codes[i] <> Code) and (i <= LastLineNo) do
            i := i + 1;

        if (Codes[i] = Code) and (i <= LastLineNo) then
            exit(Amounts[i]);

        Error('Interest code %1 has not been setup in the initialization', Code);
    end;

    procedure FormatCompanyAddress()
    begin
        IRS1099Div.FormatCompanyAddress(CompanyAddress, CompanyInfo, TestPrintSwitch);
    end;

    local procedure UpdatePeriodDateArray()
    begin
        PeriodDate[1] := DMY2Date(1, 1, YearValue);
        PeriodDate[2] := DMY2Date(31, 12, YearValue);
    end;
}

#endif
