report 10110 "Vendor 1099 Information"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Vendor1099Information.rdlc';
    Caption = 'Vendor 1099 Information';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.", "Date Filter";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyInfoName; CompanyInformation.Name)
            {
            }
            column(FilterString; FilterString)
            {
            }
            column(No_Vendor; "No.")
            {
            }
            column(Name_Vendor; Name)
            {
            }
            column(IRS1099Code_Vendor; "IRS 1099 Code")
            {
            }
            column(Vendor1099InformationCaption; Vendor1099InformationCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(VendorCaption; VendorCaptionLbl)
            {
            }
            column(IRS1099CodeCaption; IRS1099CodeCaptionLbl)
            {
            }
            column(DescriptionsCaption; DescriptionsCaptionLbl)
            {
            }
            column(IRS1099AmountCaption; IRS1099AmountCaptionLbl)
            {
            }
            dataitem("1099Loop"; "Integer")
            {
                DataItemTableView = SORTING(Number);
                column(Codes; Codes[i])
                {
                }
                column(Descriptions; Descriptions[i])
                {
                }
                column(Amounts; Amounts[i])
                {
                }

                trigger OnAfterGetRecord()
                begin
                    i := i + 1;
                    if i > LastLineNo then
                        CurrReport.Break;
                end;

                trigger OnPreDataItem()
                begin
                    i := 0;
                end;
            }
            dataitem(VendorTotal; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                column(VendorNo; Vendor."No.")
                {
                }
                column(Total; Total)
                {
                }
                column(TotalForVendorCaption; TotalForVendorCaptionLbl)
                {
                }
            }

            trigger OnAfterGetRecord()
            begin
                Clear(Codes);
                Clear(Descriptions);
                Clear(Amounts);
                Clear(LastLineNo);
                ThisVendorCounted := false;
                ProcessVendorInvoices("No.", PeriodDate);

                Clear(Total);
                for i := 1 to LastLineNo do
                    Total := Total + Amounts[i];

                if LastLineNo = 0 then
                    CurrReport.Skip;
            end;

            trigger OnPreDataItem()
            begin
                PeriodDate[1] := GetRangeMin("Date Filter");
                PeriodDate[2] := GetRangeMax("Date Filter");

                FormTypes[1] := 'B';
                FormTypes[2] := 'DIV';
                FormTypes[3] := 'INT';
                FormTypes[4] := 'MISC';
                FormTypes[5] := 'R';
                FormTypes[6] := 'S';
                FormTypes[7] := 'NEC';
                LastFormType := 7;
            end;
        }
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = SORTING(Number);
            column(FormTypeCount; FormTypeCount)
            {
            }
            column(FormTypeAmount; FormTypeAmount)
            {
            }
            column(FormTypeCode; FormTypeCode)
            {
            }
            column(AmountCaption; AmountCaptionLbl)
            {
            }
            column(VendorsCaption; VendorsCaptionLbl)
            {
            }
            column(FormTypeCaption; FormTypeCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                i := i + 1;
                if i > LastFormType then
                    CurrReport.Break;
                if FormTypeTotal[i, 1] = 0 then
                    CurrReport.Skip;
                FormTypeCode := FormTypes[i];
                FormTypeAmount := FormTypeTotal[i, 2];
                FormTypeCount := FormTypeTotal[i, 1];
            end;

            trigger OnPreDataItem()
            begin
                i := 0;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        CompanyInformation.Get('');
        FilterString := CopyStr(Vendor.GetFilters, 1, MaxStrLen(FilterString));
    end;

    var
        CompanyInformation: Record "Company Information";
        IRS1099FormBox: Record "IRS 1099 Form-Box";
        TempAppliedEntry: Record "Vendor Ledger Entry" temporary;
        EntryAppMgt: Codeunit "Entry Application Management";
        FilterString: Text[76];
        Codes: array[100] of Code[10];
        FormTypes: array[100] of Code[10];
        Descriptions: array[100] of Text[50];
        PeriodDate: array[2] of Date;
        Amounts: array[100] of Decimal;
        Total: Decimal;
        FormTypeTotal: array[100, 2] of Decimal;
        LastLineNo: Integer;
        LastFormType: Integer;
        Invoice1099Amount: Decimal;
        i: Integer;
        j: Integer;
        FormTypeCount: Integer;
        FormTypeCode: Code[10];
        FormTypeAmount: Decimal;
        ThisVendorCounted: Boolean;
        Vendor1099InformationCaptionLbl: Label 'Vendor 1099 Information';
        PageCaptionLbl: Label 'Page';
        VendorCaptionLbl: Label 'Vendor';
        IRS1099CodeCaptionLbl: Label 'IRS 1099 Code';
        DescriptionsCaptionLbl: Label 'Description';
        IRS1099AmountCaptionLbl: Label 'IRS 1099 Amount';
        TotalForVendorCaptionLbl: Label 'Total for Vendor';
        AmountCaptionLbl: Label 'Amount';
        VendorsCaptionLbl: Label 'Vendors';
        FormTypeCaptionLbl: Label 'Form Type';

    procedure ProcessVendorInvoices(VendorNo: Code[20]; PeriodDate: array[2] of Date)
    begin
        EntryAppMgt.GetAppliedVendorEntries(TempAppliedEntry, VendorNo, PeriodDate, true);
        with TempAppliedEntry do begin
            SetFilter("Document Type", '%1|%2', "Document Type"::Invoice, "Document Type"::"Credit Memo");
            SetFilter("IRS 1099 Amount", '<>0');
            if FindSet then
                repeat
                    Calculate1099Amount(TempAppliedEntry, "Amount to Apply");
                until Next = 0;
        end;
    end;

    procedure Calculate1099Amount(InvoiceEntry: Record "Vendor Ledger Entry"; AppliedAmount: Decimal)
    begin
        InvoiceEntry.CalcFields(Amount);
        Invoice1099Amount := -AppliedAmount * InvoiceEntry."IRS 1099 Amount" / InvoiceEntry.Amount;
        UpdateLines(InvoiceEntry."IRS 1099 Code", Invoice1099Amount);
    end;

    procedure UpdateLines("Code": Code[10]; Amount: Decimal)
    begin
        i := 1;
        while (Codes[i] < Code) and (i <= LastLineNo) do
            i := i + 1;

        if (Codes[i] = Code) and (i <= LastLineNo) then
            Amounts[i] := Amounts[i] + Amount
        else begin
            for j := LastLineNo downto i do begin
                Codes[j + 1] := Codes[j];
                Descriptions[j + 1] := Descriptions[j];
                Amounts[j + 1] := Amounts[j];
            end;
            Codes[i] := Code;
            if IRS1099FormBox.Get(Code) then
                Descriptions[i] := PadStr(IRS1099FormBox.Description, MaxStrLen(Descriptions[1]))
            else
                Descriptions[i] := '(Unknown Box)';
            Clear(Amounts[i]);
            Amounts[i] := Amount;
            LastLineNo := LastLineNo + 1;

            for j := 1 to LastFormType do
                if FormTypes[j] = CopyStr(Code, 1, StrLen(FormTypes[j])) then begin
                    if not ThisVendorCounted then
                        FormTypeTotal[j, 1] := FormTypeTotal[j, 1] + 1;
                    ThisVendorCounted := true;
                end;
            if LastLineNo = ArrayLen(Codes) then begin
                Codes[LastLineNo - 1] := '';
                Descriptions[LastLineNo - 1] := '...';
                Amounts[LastLineNo - 1] := Amounts[LastLineNo - 1] + Amounts[LastLineNo];
                LastLineNo := LastLineNo - 1;
            end;
        end;

        for j := 1 to LastFormType do begin
            if FormTypes[j] = CopyStr(Code, 1, StrLen(FormTypes[j])) then
                FormTypeTotal[j, 2] := FormTypeTotal[j, 2] + Amount;
        end;
    end;
}

