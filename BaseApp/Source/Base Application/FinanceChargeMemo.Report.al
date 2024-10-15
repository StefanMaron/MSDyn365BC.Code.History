report 118 "Finance Charge Memo"
{
    DefaultLayout = RDLC;
    RDLCLayout = './FinanceChargeMemo.rdlc';
    Caption = 'Finance Charge Memo';

    dataset
    {
        dataitem("Issued Fin. Charge Memo Header"; "Issued Fin. Charge Memo Header")
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.";
            RequestFilterHeading = 'Finance Charge Memo';
            column(No_IssuedFinChargeMemoHdr; "No.")
            {
            }
            column(VATAmtCaption; VATAmtCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                column(PostingDate_IssuedFinChargeMemoHdr; Format("Issued Fin. Charge Memo Header"."Posting Date"))
                {
                }
                column(DueDate_IssuedFinChargeMemoHdr; Format("Issued Fin. Charge Memo Header"."Due Date"))
                {
                }
                column(No1_IssuedFinChargeMemoHdr; "Issued Fin. Charge Memo Header"."No.")
                {
                }
                column(DocDate_IssuedFinChargeMemoHdr; Format("Issued Fin. Charge Memo Header"."Document Date"))
                {
                }
                column(YourRef_IssuedFinChargeMemoHdr; "Issued Fin. Charge Memo Header"."Your Reference")
                {
                }
                column(ReferenceText; ReferenceText)
                {
                }
                column(VATRegNo_IssuedFinChargeMemoHdr; "Issued Fin. Charge Memo Header".GetCustomerVATRegistrationNumber)
                {
                }
                column(VATNoText; VATNoText)
                {
                }
                column(CompanyInfoBankAccountNo; CompanyInfo."Bank Account No.")
                {
                }
                column(CompanyInfo1Picture; CompanyInfo1.Picture)
                {
                }
                column(CompanyInfo2Picture; CompanyInfo2.Picture)
                {
                }
                column(CompanyInfo3Picture; CompanyInfo3.Picture)
                {
                }
                column(CustNo_IssuedFinChargeMemoHdr; "Issued Fin. Charge Memo Header"."Customer No.")
                {
                }
                column(CompanyInfoBankName; CompanyInfo."Bank Name")
                {
                }
                column(CompanyInfoGiroNo; CompanyInfo."Giro No.")
                {
                }
                column(CompanyInfoVatRegNo; CompanyInfo.GetVATRegistrationNumber)
                {
                }
                column(CustAddr8; CustAddr[8])
                {
                }
                column(CompanyInfoPhoneNo; CompanyInfo."Phone No.")
                {
                }
                column(CompanyInfoEmail; CompanyInfo."E-Mail")
                {
                }
                column(CompanyInfoHomepage; CompanyInfo."Home Page")
                {
                }
                column(CustAddr7; CustAddr[7])
                {
                }
                column(CustAddr6; CustAddr[6])
                {
                }
                column(CompanyAddr6; CompanyAddr[6])
                {
                }
                column(CustAddr5; CustAddr[5])
                {
                }
                column(CompanyAddr5; CompanyAddr[5])
                {
                }
                column(CustAddr4; CustAddr[4])
                {
                }
                column(CompanyAddr4; CompanyAddr[4])
                {
                }
                column(CustAddr3; CustAddr[3])
                {
                }
                column(CompanyAddr3; CompanyAddr[3])
                {
                }
                column(CustAddr2; CustAddr[2])
                {
                }
                column(CompanyAddr2; CompanyAddr[2])
                {
                }
                column(CustAddr1; CustAddr[1])
                {
                }
                column(CompanyAddr1; CompanyAddr[1])
                {
                }
                column(PageCaption; StrSubstNo(Text002, ''))
                {
                }
                column(PostingDateCaption; PostingDateCaptionLbl)
                {
                }
                column(DueDateCaption; DueDateCaptionLbl)
                {
                }
                column(FinChargeMemoNoCaption; FinChargeMemoNoCaptionLbl)
                {
                }
                column(AccNoCaption; AccNoCaptionLbl)
                {
                }
                column(BankCaption; BankCaptionLbl)
                {
                }
                column(GiroNoCaption; GiroNoCaptionLbl)
                {
                }
                column(VATRegNoCaption; "Issued Fin. Charge Memo Header".GetCustomerVATRegistrationNumberLbl)
                {
                }
                column(PhoneNoCaption; PhoneNoCaptionLbl)
                {
                }
                column(FinChargeMemoCaption; FinChargeMemoCaptionLbl)
                {
                }
                column(CompanyVATRegistrationNoCaption; CompanyInfo.GetVATRegistrationNumberLbl)
                {
                }
                column(HomepageCaption; HomepageCaptionLbl)
                {
                }
                column(EmailCaption; EmailCaptionLbl)
                {
                }
                column(DocumentDateCaption; DocumentDateCaptionLbl)
                {
                }
                column(CustNo_IssuedFinChargeMemoHdrCaption; "Issued Fin. Charge Memo Header".FieldCaption("Customer No."))
                {
                }
                column(CACCaption; CACCaptionLbl)
                {
                }
                dataitem(DimensionLoop; "Integer")
                {
                    DataItemLinkReference = "Issued Fin. Charge Memo Header";
                    DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                    column(DimText; DimText)
                    {
                    }
                    column(Number_Integerline; Number)
                    {
                    }
                    column(HdrDimCaption; HdrDimCaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if Number = 1 then begin
                            if not DimSetEntry.FindSet then
                                CurrReport.Break;
                        end else
                            if not Continue then
                                CurrReport.Break;

                        Clear(DimText);
                        Continue := false;
                        repeat
                            OldDimText := DimText;
                            if DimText = '' then
                                DimText := StrSubstNo('%1 - %2', DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code")
                            else
                                DimText :=
                                  StrSubstNo(
                                    '%1; %2 - %3', DimText,
                                    DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code");
                            if StrLen(DimText) > MaxStrLen(OldDimText) then begin
                                DimText := OldDimText;
                                Continue := true;
                                exit;
                            end;
                        until DimSetEntry.Next = 0;
                    end;

                    trigger OnPreDataItem()
                    begin
                        if not ShowInternalInfo then
                            CurrReport.Break;
                    end;
                }
                dataitem("Issued Fin. Charge Memo Line"; "Issued Fin. Charge Memo Line")
                {
                    DataItemLink = "Finance Charge Memo No." = FIELD("No.");
                    DataItemLinkReference = "Issued Fin. Charge Memo Header";
                    DataItemTableView = SORTING("Finance Charge Memo No.", "Line No.");
                    column(LineNo_IssuFinChrgMemoLine; "Line No.")
                    {
                    }
                    column(StartLineNo; StartLineNo)
                    {
                    }
                    column(TypeInt; TypeInt)
                    {
                    }
                    column(ShowInternalInfo; ShowInternalInfo)
                    {
                    }
                    column(Amt_IssuedFinChargeMemoLine; Amount)
                    {
                        AutoFormatExpression = "Issued Fin. Charge Memo Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Desc_IssuedFinChargeMemoLine; Description)
                    {
                    }
                    column(DocDate_IssuedFinChargeMemoLine; Format("Document Date", 0, 4))
                    {
                    }
                    column(DocNo_IssuedFinChargeMemoLine; "Document No.")
                    {
                    }
                    column(DueDate_IssuedFinChargeMemoLine; Format("Due Date"))
                    {
                    }
                    column(DocType_IssuedFinChargeMemoLine; "Document Type")
                    {
                    }
                    column(LineNo1_IssuedFinChargeMemoLine; "No.")
                    {
                    }
                    column(TotalText; TotalText)
                    {
                    }
                    column(TotalInclVATText; TotalInclVATText)
                    {
                    }
                    column(Amt1_IssuedFinChargeMemoLine; "VAT Amount")
                    {
                        AutoFormatExpression = "Issued Fin. Charge Memo Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(DocDateCaption; DocDateCaptionLbl)
                    {
                    }
                    column(TotalVatAmount; TotalVatAmount)
                    {
                    }
                    column(TotalAmount; TotalAmount)
                    {
                    }
                    column(MultiIntRateEntry_IssuFinChrgMemoLine; "Detailed Interest Rates Entry")
                    {
                    }
                    column(ShowMIRLines; ShowMIRLines)
                    {
                    }
                    column(Amt_IssuedFinChargeMemoLineCaption; FieldCaption(Amount))
                    {
                    }
                    column(Desc_IssuedFinChargeMemoLineCaption; FieldCaption(Description))
                    {
                    }
                    column(DocNo_IssuedFinChargeMemoLineCaption; FieldCaption("Document No."))
                    {
                    }
                    column(DocType_IssuedFinChargeMemoLineCaption; FieldCaption("Document Type"))
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if not "Detailed Interest Rates Entry" then begin
                            Cust.Get("Issued Fin. Charge Memo Header"."Customer No.");
                            Cust.TestField("VAT Bus. Posting Group");
                            if VATPostingSetup.Get(Cust."VAT Bus. Posting Group", "VAT Prod. Posting Group") then
                                if VATPostingSetup."VAT %" <> 0 then begin
                                    VATAmountLine.Init;
                                    VATAmountLine."VAT Identifier" := "VAT Identifier";
                                    VATAmountLine."VAT Calculation Type" := "VAT Calculation Type";
                                    VATAmountLine."Tax Group Code" := "Tax Group Code";
                                    VATAmountLine."VAT %" := VATPostingSetup."VAT %";
                                    VATAmountLine."EC %" := VATPostingSetup."EC %";
                                    VATAmountLine."VAT Base" := Amount;
                                    VATAmountLine."VAT Amount" := "VAT Amount";
                                    VATAmountLine."Amount Including VAT" := Amount + "VAT Amount";
                                    VATAmountLine.SetCurrencyCode("Issued Fin. Charge Memo Header"."Currency Code");
                                    VATAmountLine."VAT Clause Code" := "VAT Clause Code";
                                    VATAmountLine.InsertLine;

                                    TotalAmount += Amount;
                                    TotalVatAmount += "VAT Amount";
                                end;
                        end;

                        TypeInt := Type;
                    end;

                    trigger OnPreDataItem()
                    begin
                        if Find('-') then begin
                            StartLineNo := 0;
                            repeat
                                Continue := Type = Type::" ";
                                if Continue and (Description = '') then
                                    StartLineNo := "Line No.";
                            until (Next = 0) or not Continue;
                        end;
                        if Find('+') then begin
                            EndLineNo := "Line No." + 1;
                            repeat
                                Continue := Type = Type::" ";
                                if Continue and (Description = '') then
                                    EndLineNo := "Line No.";
                            until (Next(-1) = 0) or not Continue;
                        end;

                        VATAmountLine.DeleteAll;
                        SetFilter("Line No.", '<%1', EndLineNo);
                        if not ShowMIRLines then
                            SetRange("Detailed Interest Rates Entry", false);

                        TotalAmount := 0;
                        TotalVatAmount := 0;
                    end;
                }
                dataitem(IssuedFinChrgMemoLine2; "Issued Fin. Charge Memo Line")
                {
                    DataItemLink = "Finance Charge Memo No." = FIELD("No.");
                    DataItemLinkReference = "Issued Fin. Charge Memo Header";
                    DataItemTableView = SORTING("Finance Charge Memo No.", "Line No.");
                    column(Desc1_IssuedFinChargeMemoLine; Description)
                    {
                    }
                    column(LineNo2_IssuedFinChargeMemoLine; "Line No.")
                    {
                    }

                    trigger OnPreDataItem()
                    begin
                        SetFilter("Line No.", '>=%1', EndLineNo);
                    end;
                }
                dataitem(VATCounter; "Integer")
                {
                    DataItemTableView = SORTING(Number);
                    column(VALVATBaseVALVATAmt; VALVATBase + VALVATAmount)
                    {
                        AutoFormatExpression = "Issued Fin. Charge Memo Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(VALVATAmt; VALVATAmount)
                    {
                        AutoFormatExpression = "Issued Fin. Charge Memo Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(VALVATBase; VALVATBase)
                    {
                        AutoFormatExpression = "Issued Fin. Charge Memo Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(VATAmtLineECAmt; VATAmountLine."EC Amount")
                    {
                        AutoFormatExpression = "Issued Fin. Charge Memo Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(VATAmtLineVAT; VATAmountLine."VAT %")
                    {
                    }
                    column(VATAmtLineEC; VATAmountLine."EC %")
                    {
                    }
                    column(AmtIncVATCaption; AmtIncVATCaptionLbl)
                    {
                    }
                    column(VATECBaseCaption; VATECBaseCaptionLbl)
                    {
                    }
                    column(VATPercentCaption; VATPercentCaptionLbl)
                    {
                    }
                    column(VATAmtSpECPercentCaption; VATAmtSpECPercentCaptionLbl)
                    {
                    }
                    column(ECPercentCaption; ECPercentCaptionLbl)
                    {
                    }
                    column(ECAmtCaption; ECAmtCaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        VATAmountLine.GetLine(Number);
                        VALVATBase := VATAmountLine."Amount Including VAT" / (1 + VATAmountLine."VAT %" / 100);
                        VALVATAmount := VATAmountLine."Amount Including VAT" - VALVATBase;
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange(Number, 1, VATAmountLine.Count);
                        Clear(VALVATBase);
                        Clear(VALVATAmount);
                    end;
                }
                dataitem(VATClauseEntryCounter; "Integer")
                {
                    DataItemTableView = SORTING(Number);
                    column(VATClauseVATIdentifier; VATAmountLine."VAT Identifier")
                    {
                    }
                    column(VATClauseCode; VATAmountLine."VAT Clause Code")
                    {
                    }
                    column(VATClauseDescription; VATClause.Description)
                    {
                    }
                    column(VATClauseDescription2; VATClause."Description 2")
                    {
                    }
                    column(VATClauseAmount; VATAmountLine."VAT Amount")
                    {
                        AutoFormatExpression = "Issued Fin. Charge Memo Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(VATClausesCaption; VATClausesCap)
                    {
                    }
                    column(VATClauseVATIdentifierCaption; VATIdentifierLbl)
                    {
                    }
                    column(VATClauseVATAmtCaption; VATAmtCaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        VATAmountLine.GetLine(Number);
                        if not VATClause.Get(VATAmountLine."VAT Clause Code") then
                            CurrReport.Skip;
                        VATClause.TranslateDescription("Issued Fin. Charge Memo Header"."Language Code");
                    end;

                    trigger OnPreDataItem()
                    begin
                        Clear(VATClause);
                        SetRange(Number, 1, VATAmountLine.Count);
                    end;
                }
                dataitem(VATCounterLCY; "Integer")
                {
                    DataItemTableView = SORTING(Number);
                    column(VALExchRate; VALExchRate)
                    {
                    }
                    column(VALSpecLCYHdr; VALSpecLCYHeader)
                    {
                    }
                    column(VALVATAmtLCY; VALVATAmountLCY)
                    {
                        AutoFormatType = 1;
                    }
                    column(VALVATBaseLCY; VALVATBaseLCY)
                    {
                        AutoFormatType = 1;
                    }
                    column(VATAmtLineVAT1; VATAmountLine."VAT %")
                    {
                        DecimalPlaces = 0 : 5;
                    }
                    column(VATBaseCaption; VATBaseCaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        VATAmountLine.GetLine(Number);

                        VALVATBaseLCY := Round(VATAmountLine."Amount Including VAT" / (1 + VATAmountLine."VAT %" / 100) / CurrFactor);
                        VALVATAmountLCY := Round(VATAmountLine."Amount Including VAT" / CurrFactor - VALVATBaseLCY);
                    end;

                    trigger OnPreDataItem()
                    begin
                        if (not GLSetup."Print VAT specification in LCY") or
                           ("Issued Fin. Charge Memo Header"."Currency Code" = '') or
                           (VATAmountLine.GetTotalVATAmount = 0)
                        then
                            CurrReport.Break;

                        SetRange(Number, 1, VATAmountLine.Count);
                        Clear(VALVATBaseLCY);
                        Clear(VALVATAmountLCY);

                        if GLSetup."LCY Code" = '' then
                            VALSpecLCYHeader := Text007 + Text008
                        else
                            VALSpecLCYHeader := Text007 + Format(GLSetup."LCY Code");

                        CurrExchRate.FindCurrency("Issued Fin. Charge Memo Header"."Posting Date", "Issued Fin. Charge Memo Header"."Currency Code", 1);
                        CustEntry.SetRange("Customer No.", "Issued Fin. Charge Memo Header"."Customer No.");
                        CustEntry.SetRange("Document Type", CustEntry."Document Type"::"Finance Charge Memo");
                        CustEntry.SetRange("Document No.", "Issued Fin. Charge Memo Header"."No.");
                        if CustEntry.FindFirst then begin
                            CustEntry.CalcFields("Amount (LCY)", Amount);
                            CurrFactor := 1 / (CustEntry."Amount (LCY)" / CustEntry.Amount);
                            VALExchRate := StrSubstNo(Text009, Round(1 / CurrFactor * 100, 0.00001), CurrExchRate."Exchange Rate Amount");
                        end else begin
                            CurrFactor := CurrExchRate.ExchangeRate("Issued Fin. Charge Memo Header"."Posting Date",
                                "Issued Fin. Charge Memo Header"."Currency Code");
                            VALExchRate := StrSubstNo(Text009, CurrExchRate."Relational Exch. Rate Amount", CurrExchRate."Exchange Rate Amount");
                        end;
                    end;
                }
            }

            trigger OnAfterGetRecord()
            begin
                CurrReport.Language := Language.GetLanguageIdOrDefault("Language Code");
                DimSetEntry.SetRange("Dimension Set ID", "Dimension Set ID");

                FormatAddr.IssuedFinanceChargeMemo(CustAddr, "Issued Fin. Charge Memo Header");
                if "Your Reference" = '' then
                    ReferenceText := ''
                else
                    ReferenceText := FieldCaption("Your Reference");
                if "Issued Fin. Charge Memo Header".GetCustomerVATRegistrationNumber() = '' then
                    VATNoText := ''
                else
                    VATNoText := "Issued Fin. Charge Memo Header".GetCustomerVATRegistrationNumberLbl();
                if "Currency Code" = '' then begin
                    GLSetup.TestField("LCY Code");
                    TotalText := StrSubstNo(Text000, GLSetup."LCY Code");
                    TotalInclVATText := StrSubstNo(Text1100000, GLSetup."LCY Code");
                end else begin
                    TotalText := StrSubstNo(Text000, "Currency Code");
                    TotalInclVATText := StrSubstNo(Text1100000, "Currency Code");
                end;
                if not IsReportInPreviewMode then
                    IncrNoPrinted;

                ShowCashAccountingCriteria("Issued Fin. Charge Memo Header");
            end;

            trigger OnPreDataItem()
            begin
                CompanyInfo.Get;
                FormatAddr.Company(CompanyAddr, CompanyInfo);
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
                    field(ShowInternalInformation; ShowInternalInfo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Internal Information';
                        ToolTip = 'Specifies if you want the printed report to show information that is only for internal use.';
                    }
                    field(LogInteraction; LogInteraction)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Log Interaction';
                        Enabled = LogInteractionEnable;
                        ToolTip = 'Specifies if you want the program to record the finance charge memos you print as interactions, and add them to the Interaction Log Entry table.';
                    }
                    field(ShowMIR; ShowMIRLines)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show MIR Detail';
                        ToolTip = 'Specifies if you want the printed report to show multiple interest rate detail.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            LogInteractionEnable := true;
        end;

        trigger OnOpenPage()
        begin
            InitLogInteraction;
            LogInteractionEnable := LogInteraction;
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        GLSetup.Get;
        CompanyInfo.Get;
        SalesSetup.Get;
        case SalesSetup."Logo Position on Documents" of
            SalesSetup."Logo Position on Documents"::"No Logo":
                ;
            SalesSetup."Logo Position on Documents"::Left:
                begin
                    CompanyInfo3.Get;
                    CompanyInfo3.CalcFields(Picture);
                end;
            SalesSetup."Logo Position on Documents"::Center:
                begin
                    CompanyInfo2.Get;
                    CompanyInfo2.CalcFields(Picture);
                end;
            SalesSetup."Logo Position on Documents"::Right:
                begin
                    CompanyInfo1.Get;
                    CompanyInfo1.CalcFields(Picture);
                end;
        end;
    end;

    trigger OnPostReport()
    begin
        if LogInteraction and not IsReportInPreviewMode then
            if "Issued Fin. Charge Memo Header".FindSet then
                repeat
                    SegManagement.LogDocument(
                      19, "Issued Fin. Charge Memo Header"."No.", 0, 0, DATABASE::Customer,
                      "Issued Fin. Charge Memo Header"."Customer No.", '', '', "Issued Fin. Charge Memo Header"."Posting Description", '');

                until "Issued Fin. Charge Memo Header".Next = 0;
    end;

    trigger OnPreReport()
    begin
        if not CurrReport.UseRequestPage then
            InitLogInteraction;
    end;

    var
        Text000: Label 'Total %1';
        Text002: Label 'Page %1';
        GLSetup: Record "General Ledger Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        CompanyInfo: Record "Company Information";
        CompanyInfo3: Record "Company Information";
        CompanyInfo2: Record "Company Information";
        CompanyInfo1: Record "Company Information";
        VATAmountLine: Record "VAT Amount Line" temporary;
        VATClause: Record "VAT Clause";
        DimSetEntry: Record "Dimension Set Entry";
        CurrExchRate: Record "Currency Exchange Rate";
        Language: Codeunit Language;
        SegManagement: Codeunit SegManagement;
        FormatAddr: Codeunit "Format Address";
        CustAddr: array[8] of Text[100];
        CompanyAddr: array[8] of Text[100];
        [InDataSet]
        VATNoText: Text[30];
        ReferenceText: Text[35];
        TotalText: Text[50];
        TotalInclVATText: Text[50];
        StartLineNo: Integer;
        EndLineNo: Integer;
        TypeInt: Integer;
        Continue: Boolean;
        DimText: Text[120];
        OldDimText: Text[75];
        ShowInternalInfo: Boolean;
        LogInteraction: Boolean;
        VALVATBaseLCY: Decimal;
        VALVATAmountLCY: Decimal;
        VALSpecLCYHeader: Text[80];
        VALExchRate: Text[50];
        CurrFactor: Decimal;
        Text007: Label 'VAT Amount Specification in ';
        Text008: Label 'Local Currency';
        Text009: Label 'Exchange rate: %1/%2';
        CustEntry: Record "Cust. Ledger Entry";
        VALVATBase: Decimal;
        VALVATAmount: Decimal;
        VATPostingSetup: Record "VAT Posting Setup";
        Cust: Record Customer;
        Text1100000: Label 'Total %1 Incl. VAT+EC';
        [InDataSet]
        LogInteractionEnable: Boolean;
        PostingDateCaptionLbl: Label 'Posting Date';
        DueDateCaptionLbl: Label 'Due Date';
        FinChargeMemoNoCaptionLbl: Label 'Fin. Chrg. Memo No.';
        AccNoCaptionLbl: Label 'Account No.';
        BankCaptionLbl: Label 'Bank';
        GiroNoCaptionLbl: Label 'Giro No.';
        PhoneNoCaptionLbl: Label 'Phone No.';
        FinChargeMemoCaptionLbl: Label 'Finance Charge Memo';
        HomepageCaptionLbl: Label 'Home Page';
        EmailCaptionLbl: Label 'E-Mail';
        DocumentDateCaptionLbl: Label 'Document Date';
        HdrDimCaptionLbl: Label 'Header Dimensions';
        DocDateCaptionLbl: Label 'Document Date';
        AmtIncVATCaptionLbl: Label 'Amount Including VAT';
        VATECBaseCaptionLbl: Label 'VAT+EC Base';
        VATPercentCaptionLbl: Label 'VAT %';
        VATAmtSpECPercentCaptionLbl: Label 'VAT Amount Specification';
        VATClausesCap: Label 'VAT Clause';
        VATIdentifierLbl: Label 'VAT Identifier';
        ECPercentCaptionLbl: Label 'EC %';
        ECAmtCaptionLbl: Label 'EC Amount';
        VATBaseCaptionLbl: Label 'VAT Base';
        VATAmtCaptionLbl: Label 'VAT Amount';
        TotalCaptionLbl: Label 'Total';
        TotalAmount: Decimal;
        TotalVatAmount: Decimal;
        ShowMIRLines: Boolean;
        CACCaptionLbl: Text;
        CACTxt: Label 'Régimen especial del criterio de caja', Locked = true;

    local procedure IsReportInPreviewMode(): Boolean
    var
        MailManagement: Codeunit "Mail Management";
    begin
        exit(CurrReport.Preview or MailManagement.IsHandlingGetEmailBody);
    end;

    procedure InitLogInteraction()
    begin
        LogInteraction := SegManagement.FindInteractTmplCode(19) <> '';
    end;

    procedure InitializeRequest(NewShowInternalInfo: Boolean; NewLogInteraction: Boolean)
    begin
        ShowInternalInfo := NewShowInternalInfo;
        LogInteraction := NewLogInteraction;
    end;

    [Scope('OnPrem')]
    procedure ShowCashAccountingCriteria(IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header"): Text
    var
        VATEntry: Record "VAT Entry";
    begin
        GLSetup.Get;
        if not GLSetup."Unrealized VAT" then
            exit;
        CACCaptionLbl := '';
        VATEntry.SetRange("Document No.", IssuedFinChargeMemoHeader."No.");
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::"Finance Charge Memo");
        if VATEntry.FindSet then
            repeat
                if VATEntry."VAT Cash Regime" then
                    CACCaptionLbl := CACTxt;
            until (VATEntry.Next = 0) or (CACCaptionLbl <> '');
        exit(CACCaptionLbl);
    end;
}

