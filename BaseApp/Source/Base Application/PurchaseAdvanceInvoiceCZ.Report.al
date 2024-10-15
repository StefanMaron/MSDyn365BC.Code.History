report 31021 "Purchase - Advance Invoice CZ"
{
    DefaultLayout = RDLC;
    RDLCLayout = './PurchaseAdvanceInvoiceCZ.rdlc';
    Caption = 'Purchase - Advance Invoice CZ';
    PreviewMode = PrintLayout;

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
            column(RegistrationNo_CompanyInformation; "Registration No.")
            {
            }
            column(VATRegistrationNo_CompanyInformation; "VAT Registration No.")
            {
            }
            column(HomePage_CompanyInformation; "Home Page")
            {
            }
            column(Picture_CompanyInformation; Picture)
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
        dataitem("Purch. Inv. Header"; "Purch. Inv. Header")
        {
            DataItemTableView = SORTING("Letter No.") WHERE("Letter No." = FILTER(<> ''));
            column(DocumentLbl; DocumentLbl)
            {
            }
            column(PageLbl; PageLbl)
            {
            }
            column(CopyLbl; CopyLbl)
            {
            }
            column(VendorLbl; VendLbl)
            {
            }
            column(CustomerLbl; CustLbl)
            {
            }
            column(PurchaserLbl; PurchaserLbl)
            {
            }
            column(CreatorLbl; CreatorLbl)
            {
            }
            column(VATIdentLbl; VATIdentLbl)
            {
            }
            column(VATPercentLbl; VATPercentLbl)
            {
            }
            column(VATBaseLbl; VATBaseLbl)
            {
            }
            column(VATAmtLbl; VATAmtLbl)
            {
            }
            column(TotalLbl; TotalLbl)
            {
            }
            column(VATLbl; VATLbl)
            {
            }
            column(AdvanceLetterLbl; AdvanceLetterLbl)
            {
            }
            column(No_PurchInvHeader; "No.")
            {
            }
            column(VATRegistrationNo_PurchInvHeaderCaption; FieldCaption("VAT Registration No."))
            {
            }
            column(VATRegistrationNo_PurchInvHeader; "VAT Registration No.")
            {
            }
            column(RegistrationNo_PurchInvHeaderCaption; FieldCaption("Registration No."))
            {
            }
            column(RegistrationNo_PurchInvHeader; "Registration No.")
            {
            }
            column(BankAccountNo_PurchInvHeaderCaption; FieldCaption("Bank Account No."))
            {
            }
            column(BankAccountNo_PurchInvHeader; "Bank Account No.")
            {
            }
            column(IBAN_PurchInvHeaderCaption; FieldCaption(IBAN))
            {
            }
            column(IBAN_PurchInvHeader; IBAN)
            {
            }
            column(BIC_PurchInvHeaderCaption; FieldCaption("SWIFT Code"))
            {
            }
            column(BIC_PurchInvHeader; "SWIFT Code")
            {
            }
            column(DocumentDate_PurchInvHeaderCaption; FieldCaption("Document Date"))
            {
            }
            column(DocumentDate_PurchInvHeader; "Document Date")
            {
            }
            column(VATDate_PurchInvHeaderCaption; FieldCaption("VAT Date"))
            {
            }
            column(VATDate_PurchInvHeader; "VAT Date")
            {
            }
            column(PaymentTerms; PaymentTerms.Description)
            {
            }
            column(PaymentMethod; PaymentMethod.Description)
            {
            }
            column(CurrencyCode_PurchInvHeader; "Currency Code")
            {
            }
            column(CalculatedExchRate; CalculatedExchRate)
            {
            }
            column(ExchRateText; ExchRateText)
            {
            }
            column(DocFooterText; DocFooterText)
            {
            }
            column(LetterNo_PurchInvHeader; "Letter No.")
            {
            }
            column(VendAddr1; VendAddr[1])
            {
            }
            column(VendAddr2; VendAddr[2])
            {
            }
            column(VendAddr3; VendAddr[3])
            {
            }
            column(VendAddr4; VendAddr[4])
            {
            }
            column(VendAddr5; VendAddr[5])
            {
            }
            column(VendAddr6; VendAddr[6])
            {
            }
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = SORTING(Number);
                column(CopyNo; CopyNo)
                {
                }
                dataitem("Salesperson/Purchaser"; "Salesperson/Purchaser")
                {
                    DataItemLink = Code = FIELD("Purchaser Code");
                    DataItemLinkReference = "Purch. Inv. Header";
                    DataItemTableView = SORTING(Code);
                    column(Name_SalespersonPurchaser; Name)
                    {
                    }
                    column(EMail_SalespersonPurchaser; "E-Mail")
                    {
                    }
                    column(PhoneNo_SalespersonPurchaser; "Phone No.")
                    {
                    }
                }
                dataitem("VAT Entry"; "VAT Entry")
                {
                    DataItemLink = "Document No." = FIELD("No."), "Posting Date" = FIELD("Posting Date");
                    DataItemLinkReference = "Purch. Inv. Header";
                    DataItemTableView = SORTING("Document No.", "Posting Date");

                    trigger OnAfterGetRecord()
                    begin
                        if not VATPostingSetup.Get("VAT Bus. Posting Group", "VAT Prod. Posting Group") then
                            VATPostingSetup.Init();

                        TempVATAmountLine.Init();
                        TempVATAmountLine."VAT Identifier" := "VAT Identifier";
                        TempVATAmountLine."VAT Calculation Type" := "VAT Calculation Type";
                        TempVATAmountLine."Tax Group Code" := "Tax Group Code";
                        TempVATAmountLine."VAT %" := VATPostingSetup."VAT %";
                        TempVATAmountLine."VAT Base" := "Advance Base";
                        TempVATAmountLine."Amount Including VAT" := "Advance Base" + Amount;
                        TempVATAmountLine.InsertLine;
                    end;

                    trigger OnPreDataItem()
                    begin
                        TempVATAmountLine.DeleteAll();
                    end;
                }
                dataitem(VATCounter; "Integer")
                {
                    DataItemTableView = SORTING(Number);
                    column(VATAmtLineVATIdentifier; TempVATAmountLine."VAT Identifier")
                    {
                    }
                    column(VATAmtLineVATPer; TempVATAmountLine."VAT %")
                    {
                        DecimalPlaces = 0 : 5;
                    }
                    column(VATAmtLineVATBase; TempVATAmountLine."VAT Base")
                    {
                        AutoFormatExpression = "Purch. Inv. Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(VATAmtLineVATAmt; TempVATAmountLine."VAT Amount")
                    {
                        AutoFormatExpression = "Purch. Inv. Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(VATAmtLineVATBaseLCY; TempVATAmountLine."VAT Base (LCY)")
                    {
                        AutoFormatExpression = "Purch. Inv. Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(VATAmtLineVATAmtLCY; TempVATAmountLine."VAT Amount (LCY)")
                    {
                        AutoFormatExpression = "Purch. Inv. Header"."Currency Code";
                        AutoFormatType = 1;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        TempVATAmountLine.GetLine(Number);

                        if CalculatedExchRate <> 1 then begin
                            TempVATAmountLine."VAT Base (LCY)" := TempVATAmountLine."VAT Base";
                            TempVATAmountLine."VAT Amount (LCY)" := TempVATAmountLine."VAT Amount";
                            TempVATAmountLine."VAT Base" :=
                              Round(TempVATAmountLine."VAT Base (LCY)" / CalculatedExchRate * CurrExchRate."Exchange Rate Amount");
                            TempVATAmountLine."VAT Amount" :=
                              Round(TempVATAmountLine."VAT Amount (LCY)" / CalculatedExchRate * CurrExchRate."Exchange Rate Amount");
                        end;
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange(Number, 1, TempVATAmountLine.Count);
                    end;
                }
                dataitem("User Setup"; "User Setup")
                {
                    DataItemLink = "User ID" = FIELD("User ID");
                    DataItemLinkReference = "Purch. Inv. Header";
                    DataItemTableView = SORTING("User ID");
                    dataitem(Employee; Employee)
                    {
#if not CLEAN18
                        DataItemLink = "No." = FIELD("Employee No.");
#endif
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
                }

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then
                        CopyNo := 1
                    else
                        CopyNo += 1;
                end;

                trigger OnPostDataItem()
                begin
                    if not IsReportInPreviewMode then
                        CODEUNIT.Run(CODEUNIT::"Purch. Inv.-Printed", "Purch. Inv. Header");
                end;

                trigger OnPreDataItem()
                begin
                    NoOfLoops := Abs(NoOfCopies) + 1;
                    if NoOfLoops <= 0 then
                        NoOfLoops := 1;

                    SetRange(Number, 1, NoOfLoops);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                CurrReport.Language := Language.GetLanguageIdOrDefault("Language Code");

                DocFooter.SetFilter("Language Code", '%1|%2', '', "Language Code");
                if DocFooter.FindLast then
                    DocFooterText := DocFooter."Footer Text"
                else
                    DocFooterText := '';

                if "Currency Code" = '' then
                    "Currency Code" := "General Ledger Setup"."LCY Code";

                if ("Currency Factor" <> 0) and ("Currency Factor" <> 1) then begin
                    CurrExchRate.FindCurrency("Posting Date", "Currency Code", 1);
                    CalculatedExchRate := Round(1 / "Currency Factor" * CurrExchRate."Exchange Rate Amount", 0.00001);
                    ExchRateText :=
                      StrSubstNo(Text009Txt, CalculatedExchRate, "General Ledger Setup"."LCY Code",
                        CurrExchRate."Exchange Rate Amount", "Currency Code");
                end else
                    CalculatedExchRate := 1;

                FormatAddr.PurchInvPayTo(VendAddr, "Purch. Inv. Header");
                if "Payment Terms Code" = '' then
                    PaymentTerms.Init
                else begin
                    PaymentTerms.Get("Payment Terms Code");
                    PaymentTerms.TranslateDescription(PaymentTerms, "Language Code");
                end;
                if "Payment Method Code" = '' then
                    PaymentMethod.Init
                else
                    PaymentMethod.Get("Payment Method Code");
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
                    field(NoOfCopies; NoOfCopies)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'No. of Copies';
                        ToolTip = 'Specifies the number of copies to print.';
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

    var
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        PaymentTerms: Record "Payment Terms";
        PaymentMethod: Record "Payment Method";
        CurrExchRate: Record "Currency Exchange Rate";
        DocFooter: Record "Document Footer";
        VATPostingSetup: Record "VAT Posting Setup";
        Language: Codeunit Language;
        FormatAddr: Codeunit "Format Address";
        ExchRateText: Text[50];
        CompanyAddr: array[8] of Text[100];
        VendAddr: array[8] of Text[100];
        DocFooterText: Text[250];
        CalculatedExchRate: Decimal;
        NoOfCopies: Integer;
        CopyNo: Integer;
        NoOfLoops: Integer;
        Text009Txt: Label 'Exchange Rate %1 %2 / %3 %4', Comment = '%1=calculatedexchrate;%2=general ledger setup.LCY Code;%3=currexchrate.exchange rate amount;%4=currency code';
        DocumentLbl: Label 'VAT Document to Paid Payment';
        PageLbl: Label 'Page';
        CopyLbl: Label 'Copy';
        VendLbl: Label 'Vendor';
        CustLbl: Label 'Customer';
        PurchaserLbl: Label 'Purchaser';
        CreatorLbl: Label 'Posted by';
        VATIdentLbl: Label 'VAT Recapitulation';
        VATPercentLbl: Label 'VAT %';
        VATBaseLbl: Label 'VAT Base';
        VATAmtLbl: Label 'VAT Amount';
        TotalLbl: Label 'total';
        VATLbl: Label 'VAT';
        AdvanceLetterLbl: Label 'VAT Document to Advance Letter';

    local procedure IsReportInPreviewMode(): Boolean
    var
        MailManagement: Codeunit "Mail Management";
    begin
        exit(CurrReport.Preview or MailManagement.IsHandlingGetEmailBody);
    end;
}

