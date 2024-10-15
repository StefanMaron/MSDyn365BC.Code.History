report 11730 "Receipt Cash Document"
{
    DefaultLayout = RDLC;
    RDLCLayout = './ReceiptCashDocument.rdlc';
    Caption = 'Receipt Cash Document';

    dataset
    {
        dataitem("Company Information"; "Company Information")
        {
            DataItemTableView = SORTING("Primary Key");
            column(CompanyAddr1; CompanyAddr[1])
            {
            }
            column(CompanyAddr2; CompanyAddr[2])
            {
            }
            column(CompanyAddr3; CompanyAddr[3])
            {
            }
            column(CompanyAddr4; CompanyAddr[4])
            {
            }
            column(CompanyAddr5; CompanyAddr[5])
            {
            }
            column(CompanyAddr6; CompanyAddr[6])
            {
            }
            column(RegistrationNo_CompanyInformation; "Company Information"."Registration No.")
            {
            }
            column(VATRegistrationNo_CompanyInformation; "Company Information"."VAT Registration No.")
            {
            }
            column(HomePage_CompanyInformation; "Company Information"."Home Page")
            {
            }
            column(Picture_CompanyInformation; "Company Information".Picture)
            {
            }
            dataitem("Sales & Receivables Setup"; "Sales & Receivables Setup")
            {
                DataItemTableView = SORTING("Primary Key");
                column(LogoPositiononDocuments_SalesReceivablesSetup; Format("Logo Position on Documents", 0, 2))
                {
                }
                dataitem("General Ledger Setup"; "General Ledger Setup")
                {
                    DataItemTableView = SORTING("Primary Key");
                    column(LCYCode_GeneralLedgerSetup; "LCY Code")
                    {
                    }
                }
            }

            trigger OnAfterGetRecord()
            begin
                FormatAddr.Company(CompanyAddr, "Company Information");
            end;

            trigger OnPreDataItem()
            begin
                CalcFields(Picture);
            end;
        }
        dataitem("Cash Document Header"; "Cash Document Header")
        {
            CalcFields = "Amount Including VAT";
            column(CashDeskNo_CashDocumentHeader; "Cash Desk No.")
            {
            }
            column(No_CashDocumentHeader; "No.")
            {
            }
            column(Status_CashDocumentHeader; Format(Status, 0, 2))
            {
            }
            column(CurrencyCode_CashDocumentHeader; "Currency Code")
            {
            }
            column(VATDate_CashDocumentHeader; "VAT Date")
            {
                IncludeCaption = true;
            }
            column(DocumentDate_CashDocumentHeader; "Document Date")
            {
                IncludeCaption = true;
            }
            column(PaymentPurpose_CashDocumentHeader; "Payment Purpose")
            {
                IncludeCaption = true;
            }
            column(RegistrationNo_CashDocumentHeader; "Registration No.")
            {
                IncludeCaption = true;
            }
            column(VATRegistrationNo_CashDocumentHeader; "VAT Registration No.")
            {
                IncludeCaption = true;
            }
            column(ReceivedFrom_CashDocumentHeader; "Received From")
            {
                IncludeCaption = true;
            }
            column(IdentificationCardNo_CashDocumentHeader; "Identification Card No.")
            {
                IncludeCaption = true;
            }
            column(ReceivedBy_CashDocumentHeader; "Received By")
            {
                IncludeCaption = true;
            }
            column(CalculatedExchRate; CalculatedExchRate)
            {
            }
            column(ExchRateText; ExchRateText)
            {
            }
            column(FromAmountToDescription_CashDocumentHeader; CashDeskMgt.FromAmountToDescription("Amount Including VAT"))
            {
            }
            dataitem("Cash Document Line"; "Cash Document Line")
            {
                DataItemLink = "Cash Desk No." = FIELD("Cash Desk No."), "Cash Document No." = FIELD("No.");
                DataItemTableView = SORTING("Cash Desk No.", "Cash Document No.", "Line No.");
                column(LineNo_CashDocumentLine; "Line No.")
                {
                }
                column(Description_CashDocumentLine; Description)
                {
                    IncludeCaption = true;
                }
                column(AmountIncludingVAT_CashDocumentLine; "Amount Including VAT")
                {
                    IncludeCaption = true;
                }
                column(VAT_CashDocumentLine; "VAT %")
                {
                    IncludeCaption = true;
                }
                column(VATAmount_CashDocumentLine; "VAT Amount")
                {
                    IncludeCaption = true;
                }
                column(VATBaseAmount_CashDocumentLine; "VAT Base Amount")
                {
                    IncludeCaption = true;
                }

                trigger OnAfterGetRecord()
                begin
                    VATAmountLine.Init();
                    VATAmountLine."VAT Identifier" := "VAT Identifier";
                    VATAmountLine."VAT Calculation Type" := "VAT Calculation Type";
                    VATAmountLine."VAT %" := "VAT %";
                    VATAmountLine."VAT Base" := "VAT Base Amount";
                    VATAmountLine."VAT Amount" := "VAT Amount";
                    VATAmountLine."Amount Including VAT" := "Amount Including VAT";
                    VATAmountLine."VAT Base (LCY)" := "VAT Base Amount (LCY)";
                    VATAmountLine."VAT Amount (LCY)" := "VAT Amount (LCY)";
                    VATAmountLine."Amount Including VAT (LCY)" := "Amount Including VAT (LCY)";
                    VATAmountLine.InsertLine;
                end;

                trigger OnPreDataItem()
                begin
                    VATAmountLine.DeleteAll();
                end;
            }
            dataitem(VATCounter; "Integer")
            {
                DataItemTableView = SORTING(Number);
                column(VATAmtLineVATIdentifier; VATAmountLine."VAT Identifier")
                {
                }
                column(VATAmtLineVATPer; VATAmountLine."VAT %")
                {
                    DecimalPlaces = 0 : 5;
                    IncludeCaption = true;
                }
                column(VATAmtLineVATBase; VATAmountLine."VAT Base")
                {
                    AutoFormatExpression = "Cash Document Header"."Currency Code";
                    AutoFormatType = 1;
                }
                column(VATAmtLineVATAmt; VATAmountLine."VAT Amount")
                {
                    AutoFormatExpression = "Cash Document Header"."Currency Code";
                    AutoFormatType = 1;
                }
                column(VATAmtLineVATBaseLCY; VATAmountLine."VAT Base (LCY)")
                {
                    AutoFormatExpression = "Cash Document Header"."Currency Code";
                    AutoFormatType = 1;
                }
                column(VATAmtLineVATAmtLCY; VATAmountLine."VAT Amount (LCY)")
                {
                    AutoFormatExpression = "Cash Document Header"."Currency Code";
                    AutoFormatType = 1;
                }
                dataitem("User Setup"; "User Setup")
                {
                    DataItemLinkReference = "Cash Document Header";
                    DataItemTableView = SORTING("User ID");
                    dataitem(Employee; Employee)
                    {
                        DataItemLink = "No." = FIELD("Employee No.");
                        DataItemTableView = SORTING("No.");
                        column(FullName_Employee; Employee.FullName)
                        {
                        }
                        column(PhoneNo_Employee; Employee."Phone No.")
                        {
                        }
                        column(CompanyEMail_Employee; Employee."Company E-Mail")
                        {
                        }
                    }

                    trigger OnPreDataItem()
                    begin
                        case "Cash Document Header".Status of
                            "Cash Document Header".Status::Open:
                                SetRange("User ID", "Cash Document Header"."Created ID");
                            "Cash Document Header".Status::Released:
                                SetRange("User ID", "Cash Document Header"."Released ID");
                        end;
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    VATAmountLine.GetLine(Number);
                end;

                trigger OnPreDataItem()
                begin
                    SetRange(Number, 1, VATAmountLine.Count);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if Status = Status::Released then
                    TestField("Amount Including VAT", "Released Amount");

                if "Currency Code" = '' then
                    "Currency Code" := "General Ledger Setup"."LCY Code"
                else
                    if ("Currency Factor" <> 0) and ("Currency Factor" <> 1) then begin
                        CurrExchRate.FindCurrency("Posting Date", "Currency Code", 1);
                        CalculatedExchRate := Round(1 / "Currency Factor" * CurrExchRate."Exchange Rate Amount", 0.00001);
                        ExchRateText :=
                          StrSubstNo(
                            ExchangeRateTxt, CalculatedExchRate, "General Ledger Setup"."LCY Code",
                            CurrExchRate."Exchange Rate Amount", "Currency Code");
                    end else
                        CalculatedExchRate := 1;
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
        DocumentLbl = 'Reciept Cash Document';
        PageLbl = 'Page';
        CompanyLbl = 'Company';
        TotalLbl = 'Total';
        TotalTextLbl = 'Total Text';
        TestLbl = 'Test';
        VATIdentLbl = 'VAT Recapitulation';
        VATPercentLbl = 'VAT %';
        VATBaseLbl = 'VAT Base';
        VATAmtLbl = 'VAT Amount';
        VATLbl = 'VAT';
        CreatedLbl = 'Created by';
        ReleasedLbl = 'Released by';
    }

    var
        ExchangeRateTxt: Label 'Exchange Rate %1 %2 / %3 %4', Comment = '%1 = Calculated Exchange Rate Amount; %2 = LCY Code; %3 = Exchange Rate Amount; %4 = Currency Code';
        VATAmountLine: Record "VAT Amount Line" temporary;
        CurrExchRate: Record "Currency Exchange Rate";
        FormatAddr: Codeunit "Format Address";
        CashDeskMgt: Codeunit CashDeskManagement;
        ExchRateText: Text[50];
        CompanyAddr: array[8] of Text[100];
        CalculatedExchRate: Decimal;
}

