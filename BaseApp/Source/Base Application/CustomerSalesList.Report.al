report 119 "Customer - Sales List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './CustomerSalesList.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Customer - Sales List';
    PreviewMode = PrintLayout;
    UsageCategory = ReportsAndAnalysis;
    DataAccessIntent = ReadOnly;

    dataset
    {
        dataitem(Customer; Customer)
        {
            RequestFilterFields = "No.", "Date Filter";
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName)
            {
            }
            column(MinAmtLCY; MinAmtLCY)
            {
                AutoFormatType = 1;
            }
            column(TABLECAPTION__________CustFilter; TableCaption + ': ' + CustFilter)
            {
            }
            column(Customer__No__; "No.")
            {
            }
            column(Customer_Name; Name)
            {
            }
            column(Customer__VAT_Registration_No__; "VAT Registration No.")
            {
            }
            column(AmtSalesLCY; AmtSalesLCY)
            {
                AutoFormatType = 1;
            }
            column(CustAddr_2_; CustAddr[2])
            {
            }
            column(CustAddr_3_; CustAddr[3])
            {
            }
            column(CustAddr_4_; CustAddr[4])
            {
            }
            column(CustAddr_5_; CustAddr[5])
            {
            }
            column(CustAddr_6_; CustAddr[6])
            {
            }
            column(CustAddr_7_; CustAddr[7])
            {
            }
            column(CustAddr_8_; CustAddr[8])
            {
            }
            column(HideAddress; HideAddress)
            {
            }
            column(NoText; NoText)
            {
            }
            column(CustFilter; CustFilter)
            {
            }
            column(Customer___Sales_ListCaption; Customer___Sales_ListCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(MinAmtLCYCaption; MinAmtLCYCaptionLbl)
            {
            }
            column(Customer__No__Caption; FieldCaption("No."))
            {
            }
            column(Customer_NameCaption; FieldCaption(Name))
            {
            }
            column(AmtSalesLCYCaption; AmtSalesLCYCaptionLbl)
            {
            }
            column(Total_Reported_Amount_of_Sales__LCY_Caption; Total_Reported_Amount_of_Sales__LCY_CaptionLbl)
            {
            }
            column(NoTextCaption; NoTextCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            var
                FormatAddr: Codeunit "Format Address";
            begin
                AmtSalesLCY := CalculateAmtOfSaleLCY;
                if AmtSalesLCY < MinAmtLCY then
                    CurrReport.Skip();

                if not HideAddress then
                    FormatAddr.Customer(CustAddr, Customer);
                if not Country.DetermineCountry("Country/Region Code") then
                    NoText := "VAT Registration No."
                else
                    NoText := "Enterprise No.";
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
                    field(MinAmtLCY; MinAmtLCY)
                    {
                        ApplicationArea = Basic, Suite;
                        AutoFormatType = 1;
                        Caption = 'Amounts (LCY) Greater Than';
                        ToolTip = 'Specifies an amount so that the report will only include those customers to which you have sold more than this amount within the specified dates.';
                    }
                    field(HideAddress; HideAddress)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Hide Address Detail';
                        ToolTip = 'Specifies that you do not want the report to show address details for each customer.';
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

    trigger OnPreReport()
    var
        FormatDocument: Codeunit "Format Document";
    begin
        CustFilter := FormatDocument.GetRecordFiltersWithCaptions(Customer);
    end;

    var
        Country: Record "Country/Region";
        NoText: Text[50];
        MinAmtLCY: Decimal;
        HideAddress: Boolean;
        AmtSalesLCY: Decimal;
        CustAddr: array[8] of Text[100];
        CustFilter: Text;
        Customer___Sales_ListCaptionLbl: Label 'Customer - Sales List';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        MinAmtLCYCaptionLbl: Label 'Amounts (LCY) greater than';
        AmtSalesLCYCaptionLbl: Label 'Amount of Sales (LCY)';
        Total_Reported_Amount_of_Sales__LCY_CaptionLbl: Label 'Total Reported Amount of Sales (LCY)';
        NoTextCaptionLbl: Label 'Enterprise No./VAT Reg. No.';

    local procedure CalculateAmtOfSaleLCY(): Decimal
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        Amt: Decimal;
        i: Integer;
    begin
        with CustLedgEntry do begin
            SetCurrentKey("Document Type", "Customer No.", "Posting Date");
            SetRange("Customer No.", Customer."No.");
            SetFilter("Posting Date", Customer.GetFilter("Date Filter"));
            for i := 1 to 2 do begin
                case i of
                    1:
                        SetRange("Document Type", "Document Type"::Invoice);
                    2:
                        SetRange("Document Type", "Document Type"::"Credit Memo");
                end;
                CalcSums("Sales (LCY)");
                Amt := Amt + "Sales (LCY)";
            end;
            exit(Amt);
        end;
    end;

    procedure InitializeRequest(MinimumAmtLCY: Decimal; HideAddressDetails: Boolean)
    begin
        MinAmtLCY := MinimumAmtLCY;
        HideAddress := HideAddressDetails;
    end;
}

