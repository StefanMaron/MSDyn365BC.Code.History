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

report 10112 "Vendor 1099 Misc"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/VAT/Reporting/Vendor1099Misc.rdlc';
    ApplicationArea = BasicUS;
    Caption = 'Vendor 1099 Miscellaneous 2019';
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
            column(GetAmtMISC01; GetAmt('MISC-01'))
            {
            }
            column(CompanyAddress2; CompanyAddress[2])
            {
            }
            column(CompanyAddress3; CompanyAddress[3])
            {
            }
            column(GetAmtMISC02; GetAmt('MISC-02'))
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
            column(GetAmtMISC03; GetAmt('MISC-03'))
            {
            }
            column(CompanyInfoFederalIDNo; CompanyInfo."Federal ID No.")
            {
            }
            column(FederalIDNo_Vendor; "Federal ID No.")
            {
            }
            column(GetAmtMISC04; GetAmt('MISC-04'))
            {
            }
            column(GetAmtMISC05; GetAmt('MISC-05'))
            {
            }
            column(Name_Vendor; Name)
            {
            }
            column(GetAmtMISC06; GetAmt('MISC-06'))
            {
            }
            column(GetAmtMISC07MISC15B; GetAmt('MISC-07') + GetAmt('MISC-15-B'))
            {
            }
            column(Name2_Vendor; "Name 2")
            {
            }
            column(Address_Vendor; Address)
            {
            }
            column(GetAmtMISC08; GetAmt('MISC-08'))
            {
            }
            column(Box9; Box9)
            {
            }
            column(Address3_Vendor; VendorAddress)
            {
            }
            column(GetAmtMISC10; GetAmt('MISC-10'))
            {
            }
            column(GetAmtMISC13; GetAmt('MISC-13'))
            {
            }
            column(No_Vendor; "No.")
            {
            }
            column(GetAmtMISC14; GetAmt('MISC-14'))
            {
            }
            column(GetAmtMISC16; GetAmt('MISC-16'))
            {
            }
            column(Address2_Vendor; "Address 2")
            {
            }
            column(GetAmtMISC15A; GetAmt('MISC-15-A'))
            {
            }
            column(GetAmtMISC15B; GetAmt('MISC-15-B'))
            {
            }
            column(PageGroupNo; PageGroupNo)
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
                CodeIndex: Integer;
            begin
                Clear(Amounts);
                Clear(VoidBox);
                Clear(Box9);
                Clear(FATCA);

                // Special handling for Test Printing
                if TestPrint then begin
                    if FirstVendor then begin
                        Name := PadStr('x', MaxStrLen(Name), 'X');
                        Address := PadStr('x', MaxStrLen(Address), 'X');
                        VendorAddress := PadStr('x', MaxStrLen(VendorAddress), 'X');
                        VoidBox := 'X';
                        Box9 := 'X';
                        FATCA := 'X';
                        "No." := PadStr('x', MaxStrLen("No."), 'X');
                        "Federal ID No." := PadStr('x', MaxStrLen("Federal ID No."), 'X');
                    end else
                        CurrReport.Break();  // The End
                end else begin   // not Test Printing
                    PrintThis := false;
                    // Check through all payments during calendar year
                    IRS1099Management.ProcessVendorInvoices(Amounts, "No.", PeriodDate, Codes, LastLineNo, 'MISC*');

                    PrintThis := IRS1099Management.AnyCodeWithUpdatedAmountExceedMinimum(Codes, Amounts, LastLineNo);
                    if not PrintThis then
                        CurrReport.Skip();

                    VendorAddress := IRS1099Management.GetFormattedVendorAddress(Vendor);

                    // following is special case for 1099-MISC only
                    Line9 := UpdateLines('MISC-09', 0.0);
                    if FormBox.Get(Codes[Line9]) then
                        if Amounts[Line9] >= FormBox."Minimum Reportable" then
                            Box9 := 'X';

                    if "FATCA filing requirement" then begin
                        FATCA := 'X';
                        CodeIndex := UpdateLines('MISC-03', 0.0);
                        Amounts[CodeIndex] := 0;
                    end;
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
                PeriodDate[1] := DMY2Date(1, 1, Year);
                PeriodDate[2] := DMY2Date(31, 12, Year);

                // Fill in the Codes used on this particular 1099 form
                Clear(Codes);
                Clear(LastLineNo);
                Codes[1] := 'MISC-01';
                Codes[2] := 'MISC-02';
                Codes[3] := 'MISC-03';
                Codes[4] := 'MISC-04';
                Codes[5] := 'MISC-05';
                Codes[6] := 'MISC-06';
                Codes[7] := 'MISC-07';
                Codes[8] := 'MISC-08';
                Codes[9] := 'MISC-09';
                Codes[10] := 'MISC-10';
                Codes[13] := 'MISC-13';
                Codes[14] := 'MISC-14';
                Codes[15] := 'MISC-15-A';
                Codes[16] := 'MISC-15-B';
                Codes[17] := 'MISC-16';
                LastLineNo := 17;

                // Initialize Company Address. As side effect, will read CompanyInfo record
                IRS1099Management.FormatCompanyAddress(CompanyAddress, CompanyInfo, TestPrint);
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
                    field(Year; Year)
                    {
                        ApplicationArea = BasicUS;
                        Caption = 'Calendar Year';
                        ToolTip = 'Specifies the tax year for the 1099 forms that you want to print. The default is the work date year. The taxes may apply to the previous calendar year so you may want to change this date if nothing prints.';

                        trigger OnValidate()
                        begin
                            if (Year < 1980) or (Year > 2060) then
                                Error('You must enter a valid year, eg 1998');
                        end;
                    }
                    field(TestPrint; TestPrint)
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

        trigger OnOpenPage()
        begin
            TestPrint := false;   /*always default to false*/
            Year := Date2DMY(WorkDate(), 3);   /*default to current working year*/

        end;
    }

    labels
    {
    }

    var
        CompanyInfo: Record "Company Information";
        FormBox: Record "IRS 1099 Form-Box";
        TempAppliedEntry: Record "Vendor Ledger Entry" temporary;
        EntryAppMgt: Codeunit "Entry Application Management";
        IRS1099Management: Codeunit "IRS 1099 Management";
        PeriodDate: array[2] of Date;
        Year: Integer;
        TestPrint: Boolean;
        VoidBox: Code[1];
        FATCA: Code[1];
        Box9: Code[1];
        CompanyAddress: array[5] of Text[50];
        FirstVendor: Boolean;
        PrintThis: Boolean;
        VendorAddress: Text[30];
        Codes: array[20] of Code[10];
        Amounts: array[20] of Decimal;
        LastLineNo: Integer;
        Invoice1099Amount: Decimal;
        i: Integer;
        Line9: Integer;
        FormCounter: Integer;
        IRS1099Div: Report "Vendor 1099 Div";
        PageGroupNo: Integer;
        VendorNo: Integer;

    procedure ProcessVendorInvoices(VendorNo: Code[20]; PeriodDate: array[2] of Date)
    begin
        // search for invoices paid off by this payment
        EntryAppMgt.GetAppliedVendorEntries(TempAppliedEntry, VendorNo, PeriodDate, true);
        // search for invoices with 1099 amounts
        TempAppliedEntry.SetFilter("Document Type", '%1|%2', TempAppliedEntry."Document Type"::Invoice, TempAppliedEntry."Document Type"::"Credit Memo");
        TempAppliedEntry.SetFilter("IRS 1099 Amount", '<>0');
        TempAppliedEntry.SetRange("IRS 1099 Code", 'MISC-', 'MISC-99');
        if TempAppliedEntry.FindSet() then
            repeat
                IRS1099Management.Calculate1099Amount(
                  Invoice1099Amount, Amounts, Codes, LastLineNo, TempAppliedEntry, TempAppliedEntry."Amount to Apply");
            until TempAppliedEntry.Next() = 0;
    end;

    [Obsolete('Moved to IRS 1099 Management codeunit', '18.0')]
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
            Error('Invoice %1 on vendor %2 has unknown 1099 miscellaneous code  %3',
              TempAppliedEntry."Entry No.", TempAppliedEntry."Vendor No.", Code);
        exit(i);   // returns code index found
    end;

    procedure GetAmt("Code": Code[10]): Decimal
    begin
        if TestPrint then
            exit(9999999.99); // test value

        i := 1;
        while (Codes[i] <> Code) and (i <= LastLineNo) do
            i := i + 1;

        if (Codes[i] = Code) and (i <= LastLineNo) then
            exit(Amounts[i]);

        Error('Misc. code %1 has not been setup in the initialization', Code);
    end;

    [Obsolete('Moved to IRS 1099 Management codeunit', '18.0')]
    procedure FormatCompanyAddress()
    begin
        IRS1099Div.FormatCompanyAddress(CompanyAddress, CompanyInfo, TestPrint);
    end;
}

#endif
