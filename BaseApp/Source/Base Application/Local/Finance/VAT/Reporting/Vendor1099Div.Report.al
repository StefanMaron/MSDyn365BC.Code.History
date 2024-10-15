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

report 10109 "Vendor 1099 Div"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/VAT/Reporting/Vendor1099Div.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Vendor 1099 Dividend';
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
            column(Address3_Vendor; "Address 3")
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
            begin
                Clear(Amounts);
                Clear(Void);
                Clear(FATCA);

                // Special handling for Test Printing
                if TestPrint then begin
                    if FirstVendor then begin
                        Name := PadStr('x', MaxStrLen(Name), 'X');
                        Address := PadStr('x', MaxStrLen(Address), 'X');
                        "Address 3" := PadStr('x', MaxStrLen("Address 3"), 'X');
                        Void := 'X';
                        FATCA := 'X';
                        "No." := PadStr('x', MaxStrLen("No."), 'X');
                        "Federal ID No." := PadStr('x', MaxStrLen("Federal ID No."), 'X');
                    end else
                        CurrReport.Break();
                end else begin
                    PrintThis := false;
                    // Check through all payments during calendar year
                    IRS1099Management.ProcessVendorInvoices(Amounts, "No.", PeriodDate, Codes, LastLineNo, 'DIV*');

                    // Any printable amounts on this form?
                    for i := 1 to LastLineNo do
                        if FormBox.Get(Codes[i]) then
                            if FormBox."Minimum Reportable" < 0.0 then begin
                                if Amounts[i] <> 0.0 then begin
                                    Amounts[i] := -Amounts[i];
                                    PrintThis := true;
                                end;
                            end else begin   /* ie Minimum Reportable >= 0.0 */
                                if Amounts[i] >= FormBox."Minimum Reportable" then
                                    if Amounts[i] <> 0.0 then
                                        PrintThis := true;
                            end;

                    if not PrintThis then
                        CurrReport.Skip();

                    // Format City/State/ZIP address line
                    if StrLen(City + ', ' + County + '  ' + "Post Code") > MaxStrLen("Address 3") then
                        "Address 3" := City
                    else
                        if (City <> '') and (County <> '') then
                            "Address 3" := City + ', ' + County + '  ' + "Post Code"
                        else
                            "Address 3" := DelChr(City + ' ' + County + ' ' + "Post Code", '<>');

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

                LastLineNo := 18;

                // Initialize Company Address. As side effect, will read CompanyInfo record
                FormatCompanyAddress(CompanyAddress, CompanyInfo, TestPrint);
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
                                Error('You must enter a valid year, eg 1993');
                            UpdatePeriodDateArray();
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

        trigger OnInit()
        begin
            TestPrint := false;   /*always default to false*/
            Year := Date2DMY(WorkDate(), 3);   /*default to current working year*/

        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    var
        IRS1099Management: Codeunit "IRS 1099 Management";
    begin
        IRS1099Management.ThrowErrorfUpgrade2019Needed();
    end;

    var
        CompanyInfo: Record "Company Information";
        FormBox: Record "IRS 1099 Form-Box";
        TempAppliedEntry: Record "Vendor Ledger Entry" temporary;
        EntryAppMgt: Codeunit "Entry Application Management";
        IRS1099Management: Codeunit "IRS 1099 Management";
        PeriodDate: array[2] of Date;
        Year: Integer;
        TestPrint: Boolean;
        Void: Code[1];
        FATCA: Code[1];
        CompanyAddress: array[5] of Text[100];
        FirstVendor: Boolean;
        PrintThis: Boolean;
        "Address 3": Text[30];
        Codes: array[20] of Code[10];
        Amounts: array[20] of Decimal;
        LastLineNo: Integer;
        Invoice1099Amount: Decimal;
        i: Integer;
        FormCounter: Integer;
        VendorNo: Integer;
        PageGroupNo: Integer;

    procedure ProcessVendorInvoices(VendorNo: Code[20]; PeriodDate: array[2] of Date)
    begin
        // Search for invoices paid off by this payment
        EntryAppMgt.GetAppliedVendorEntries(TempAppliedEntry, VendorNo, PeriodDate, true);
        with TempAppliedEntry do begin
            // Search for invoices with 1099 amounts
            SetFilter("Document Type", '%1|%2', "Document Type"::Invoice, "Document Type"::"Credit Memo");
            SetFilter("IRS 1099 Amount", '<>0');
            SetRange("IRS 1099 Code", 'DIV-', 'DIV-99');
            if FindSet() then
                repeat
                    IRS1099Management.Calculate1099Amount(
                      Invoice1099Amount, Amounts, Codes, LastLineNo, TempAppliedEntry, "Amount to Apply");
                until Next() = 0;
        end;
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
            Error('Invoice %1 on vendor %2 has unknown 1099 dividend code  %3',
              TempAppliedEntry."Entry No.", TempAppliedEntry."Vendor No.", Code);
        exit(i);   /*returns code index found*/

    end;

    procedure GetAmt("Code": Code[10]): Decimal
    begin
        if TestPrint then
            exit(9999999.99);

        i := 1;
        while (Codes[i] <> Code) and (i <= LastLineNo) do
            i := i + 1;

        if (Codes[i] = Code) and (i <= LastLineNo) then
            exit(Amounts[i]);

        Error('Dividend code %1 has not been setup in the initialization', Code);
    end;

    procedure FormatCompanyAddress(var CompanyAddress: array[5] of Text[100]; var CompanyInfo: Record "Company Information"; TestPrint: Boolean)
    begin
        with CompanyInfo do
            if TestPrint then begin
                for i := 1 to ArrayLen(CompanyAddress) do
                    CompanyAddress[i] := PadStr('x', MaxStrLen(CompanyAddress[i]), 'X');
            end else begin
                Get();

                Clear(CompanyAddress);
                CompanyAddress[1] := Name;
                CompanyAddress[2] := Address;
                CompanyAddress[3] := "Address 2";
                if StrLen(City + ', ' + County + '  ' + "Post Code") > MaxStrLen(CompanyAddress[4]) then begin
                    CompanyAddress[4] := City;
                    CompanyAddress[5] := County + '  ' + "Post Code";
                    if CompressArray(CompanyAddress) = ArrayLen(CompanyAddress) then begin
                        CompanyAddress[3] := CompanyAddress[4];  // lose address 2 to add phone no.
                        CompanyAddress[4] := CompanyAddress[5];
                    end;
                    CompanyAddress[5] := "Phone No.";
                end else
                    if (City <> '') and (County <> '') then begin
                        CompanyAddress[4] := City + ', ' + County + '  ' + "Post Code";
                        CompanyAddress[5] := "Phone No.";
                    end else begin
                        CompanyAddress[4] := DelChr(City + ' ' + County + ' ' + "Post Code", '<>');
                        CompanyAddress[5] := "Phone No.";
                    end;
                CompressArray(CompanyAddress);
            end;
    end;

    local procedure UpdatePeriodDateArray()
    begin
        PeriodDate[1] := DMY2Date(1, 1, Year);
        PeriodDate[2] := DMY2Date(31, 12, Year);
    end;
}

#endif
