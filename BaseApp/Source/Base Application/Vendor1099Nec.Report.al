report 10117 "Vendor 1099 Nec"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Vendor1099Nec.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Vendor 1099 Nec';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.";
            RequestFilterHeading = 'Vendor Filter';
            column(VoidBox; VoidBox)
            {
            }
            column(CompanyAddress1; CompanyAddress[1])
            {
            }
            column(GetAmtNEC01; IRS1099Management.GetAmtByCode(Codes, Amounts, LastLineNo, 'NEC-01', RunTestPrint))
            {
            }
            column(GetAmtNEC04; IRS1099Management.GetAmtByCode(Codes, Amounts, LastLineNo, 'NEC-04', RunTestPrint))
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
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = SORTING(Number);
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
                Clear(VoidBox);
                Clear(FATCA);

                // Special handling for Test Printing
                if RunTestPrint then begin
                    if FirstVendor then begin
                        Name := PadStr('x', MaxStrLen(Name), 'X');
                        Address := PadStr('x', MaxStrLen(Address), 'X');
                        VendorAddress := PadStr('x', MaxStrLen(VendorAddress), 'X');
                        VoidBox := 'X';
                        FATCA := 'X';
                        "No." := PadStr('x', MaxStrLen("No."), 'X');
                        "Federal ID No." := PadStr('x', MaxStrLen("Federal ID No."), 'X');
                    end else
                        CurrReport.Break();  // The End
                end else begin   // not Test Printing
                    PrintThis := false;
                    // Check through all payments during calendar year
                    IRS1099Management.ProcessVendorInvoices(Amounts, "No.", PeriodDate, Codes, LastLineNo, 'NEC*');

                    PrintThis := IRS1099Management.AnyCodeHasAmountExceedMinimum(Codes, Amounts, LastLineNo);
                    if not PrintThis then
                        CurrReport.Skip();

                    VendorAddress := IRS1099Management.GetFormattedVendorAddress(Vendor);

                    if "FATCA filing requirement" then
                        FATCA := 'X';
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
                Codes[1] := 'NEC-01';
                Codes[4] := 'NEC-04';
                LastLineNo := 4;

                // Initialize Company Address. As side effect, will read CompanyInfo record
                IRS1099Management.FormatCompanyAddress(CompanyAddress, CompanyInfo, RunTestPrint);
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
                    field(Year; CurrYear)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Calendar Year';
                        ToolTip = 'Specifies the tax year for the 1099 forms that you want to print. The default is the work date year. The taxes may apply to the previous calendar year so you may want to change this date if nothing prints.';

                        trigger OnValidate()
                        begin
                            if (CurrYear < 1980) or (CurrYear > 2060) then
                                Error(ValidYearErr);
                            UpdatePeriodDateArray();
                        end;
                    }
                    field(TestPrint; RunTestPrint)
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
            RunTestPrint := false;
            CurrYear := Date2DMY(WorkDate(), 3);
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        IRS1099Management.ThrowErrorfUpgrade2020FebruaryNeeded();
    end;

    var
        CompanyInfo: Record "Company Information";
        IRS1099Management: Codeunit "IRS 1099 Management";
        PeriodDate: array[2] of Date;
        CurrYear: Integer;
        RunTestPrint: Boolean;
        VoidBox: Code[1];
        FATCA: Code[1];
        CompanyAddress: array[5] of Text[50];
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

    procedure ProcessVendorInvoices(VendorNo: Code[20]; PeriodDate: array[2] of Date)
    var
        TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary;
        EntryApplicationManagement: Codeunit "Entry Application Management";
        Invoice1099Amount: Decimal;
    begin
        EntryApplicationManagement.GetAppliedVendorEntries(
          TempVendorLedgerEntry, VendorNo, PeriodDate, true);
        with TempVendorLedgerEntry do begin
            SetFilter("Document Type", '%1|%2', "Document Type"::Invoice, "Document Type"::"Credit Memo");
            SetFilter("IRS 1099 Amount", '<>0');
            SetFilter("IRS 1099 Code", 'NEC*');
            if FindSet() then
                repeat
                    IRS1099Management.Calculate1099Amount(
                      Invoice1099Amount, Amounts, Codes, LastLineNo, TempVendorLedgerEntry, "Amount to Apply");
                until Next() = 0;
        end;
    end;

    local procedure UpdatePeriodDateArray()
    begin
        PeriodDate[1] := DMY2Date(1, 1, CurrYear);
        PeriodDate[2] := DMY2Date(31, 12, CurrYear);
    end;
}

