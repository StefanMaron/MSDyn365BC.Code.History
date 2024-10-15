report 117 Reminder
{
    DefaultLayout = RDLC;
    RDLCLayout = './Reminder.rdlc';
    Caption = 'Reminder';

    dataset
    {
        dataitem("Issued Reminder Header"; "Issued Reminder Header")
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.";
            RequestFilterHeading = 'Reminder';
            column(No_IssuedReminderHeader; "No.")
            {
            }
            column(DueDateCaption; DueDateCaptionLbl)
            {
            }
            column(RemLineDocumentDateCaption; RemLineDocumentDateCaptionLbl)
            {
            }
            column(VatAmtCaption; VatAmtCaptionLbl)
            {
            }
            column(VatBaseCaption; VatBaseCaptionLbl)
            {
            }
            column(Vatpercentcaption; VatpercentcaptionLbl)
            {
            }
            column(CompanyInfoHomePageCaption; CompanyInfoHomePageCaptionLbl)
            {
            }
            column(CompanyInfoEmailIdCaption; CompanyInfoEmailIdCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(ShowMIRLines; ShowMIRLines)
            {
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                column(DueDate_IssuedRemHdr; Format("Issued Reminder Header"."Due Date"))
                {
                }
                column(PostingDate_IssuedRemHdr; Format("Issued Reminder Header"."Posting Date"))
                {
                }
                column(No1_IssuedReminderHeader; "Issued Reminder Header"."No.")
                {
                }
                column(YourRef_IssuedRemHdr; "Issued Reminder Header"."Your Reference")
                {
                }
                column(Contact_IssuedReminderHdr; "Issued Reminder Header".Contact)
                {
                }
                column(ReferenceText; ReferenceText)
                {
                }
                column(VATRegsNo_IssuedRemHdr; "Issued Reminder Header".GetCustomerVATRegistrationNumber)
                {
                }
                column(VATNoText; VATNoText)
                {
                }
                column(DocumentDate_IssuedRemHrd; Format("Issued Reminder Header"."Document Date"))
                {
                }
                column(CustomerNo_IssuedRemHrd; "Issued Reminder Header"."Customer No.")
                {
                }
                column(CustomerNo_IssuedRemHrdCaption; "Issued Reminder Header".FieldCaption("Customer No."))
                {
                }
                column(CompanyInfoAccountNo; CompanyInfo."Bank Account No.")
                {
                }
                column(CompanyInfoBankName; CompanyInfo."Bank Name")
                {
                }
                column(CompanyInfoGiroNo; CompanyInfo."Giro No.")
                {
                }
                column(CompanyInfoEmail; CompanyInfo."E-Mail")
                {
                }
                column(CompanyInfoHomePage; CompanyInfo."Home Page")
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
                column(CompanyInfoVATRegsNo; CompanyInfo.GetVATRegistrationNumber)
                {
                }
                column(CustAddr8; CustAddr[8])
                {
                }
                column(CompanyInfoPhoneNo; CompanyInfo."Phone No.")
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
                column(TextPage; TextPageLbl)
                {
                }
                column(PostingDateCaption; PostingDateCaptionLbl)
                {
                }
                column(ReminderNoCaption; ReminderNoCaptionLbl)
                {
                }
                column(BankAccountNoCaption; BankAccountNoCaptionLbl)
                {
                }
                column(BankNameCaption; BankNameCaptionLbl)
                {
                }
                column(GiroNoCaption; GiroNoCaptionLbl)
                {
                }
                column(VATRegNoCaption; "Issued Reminder Header".GetCustomerVATRegistrationNumberLbl)
                {
                }
                column(PhoneNoCaption; PhoneNoCaptionLbl)
                {
                }
                column(ReminderCaption; ReminderCaptionLbl)
                {
                }
                column(CompanyVATRegistrationNoCaption; CompanyInfo.GetVATRegistrationNumberLbl)
                {
                }
                dataitem(DimensionLoop; "Integer")
                {
                    DataItemLinkReference = "Issued Reminder Header";
                    DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                    column(DimText; DimText)
                    {
                    }
                    column(Number; DimensionLoop.Number)
                    {
                    }
                    column(HeaderDimCaption; HeaderDimCaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if Number = 1 then begin
                            if not DimSetEntry.FindSet then
                                CurrReport.Break();
                        end else
                            if not Continue then
                                CurrReport.Break();

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
                            CurrReport.Break();
                    end;
                }
                dataitem("Issued Reminder Line"; "Issued Reminder Line")
                {
                    DataItemLink = "Reminder No." = FIELD("No.");
                    DataItemLinkReference = "Issued Reminder Header";
                    DataItemTableView = SORTING("Reminder No.", "Line No.");
                    column(RemAmt_IssuedReminderLine; "Remaining Amount")
                    {
                        AutoFormatExpression = "Issued Reminder Line".GetCurrencyCodeFromHeader;
                        AutoFormatType = 1;
                    }
                    column(RemAmt_IssuedReminderLineCaption; FieldCaption("Remaining Amount"))
                    {
                    }
                    column(Desc_IssuedReminderLine; Description)
                    {
                    }
                    column(Type_IssuedReminderLine; Format(Type, 0, 2))
                    {
                    }
                    column(DocDate_IssuedRemLine; Format("Document Date"))
                    {
                    }
                    column(DocNo_IssuedReminderLine; "Document No.")
                    {
                    }
                    column(DocNo_IssuedReminderLineCaption; FieldCaption("Document No."))
                    {
                    }
                    column(DueDate_IssuedReminderLine; Format("Due Date"))
                    {
                    }
                    column(OriginalAmt_IssuedRemLine; "Original Amount")
                    {
                        AutoFormatExpression = "Issued Reminder Line".GetCurrencyCodeFromHeader;
                        AutoFormatType = 1;
                    }
                    column(OriginalAmt_IssuedRemLineCaption; FieldCaption("Original Amount"))
                    {
                    }
                    column(DocType_IssuedReminderLine; "Document Type")
                    {
                    }
                    column(DocType_IssuedReminderLineCaption; FieldCaption("Document Type"))
                    {
                    }
                    column(No_IssuedReminderLine; "No.")
                    {
                    }
                    column(ShowInterInfo_IssuRemLine; ShowInternalInfo)
                    {
                    }
                    column(InterestAmt_IssuRemLine; NNC_InterestAmount)
                    {
                    }
                    column(TotText_IssuedRemLine; TotalText)
                    {
                    }
                    column(MIREntry_IssuedReminderLine; "Detailed Interest Rates Entry")
                    {
                    }
                    column(NNCTotal_IssuedRemLine; NNC_Total)
                    {
                    }
                    column(InclVATText_IssuedRemLine; TotalInclVATText)
                    {
                    }
                    column(VATAmt_IssuedRemLine; NNC_VATAmount)
                    {
                    }
                    column(TotInclVAT_IssuedRemLine; NNC_TotalInclVAT)
                    {
                    }
                    column(TotalVATAmt; TotalVATAmount)
                    {
                    }
                    column(RemNo_IssuedReminderLine; "Reminder No.")
                    {
                    }
                    column(ContinuedCaption; ContinuedCaptionLbl)
                    {
                    }
                    column(InterestAmountcaption; InterestAmountcaptionLbl)
                    {
                    }
                    column(Interest; Interest)
                    {
                    }
                    column(RemainingAmountText; RemainingAmt)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if not "Detailed Interest Rates Entry" then begin
                            VATAmountLine.Init();
                            VATAmountLine."VAT Identifier" := "VAT Identifier";
                            VATAmountLine."VAT Calculation Type" := "VAT Calculation Type";
                            VATAmountLine."Tax Group Code" := "Tax Group Code";
                            VATAmountLine."VAT %" := "VAT %";
                            VATAmountLine."VAT Base" := Amount;
                            VATAmountLine."VAT Amount" := "VAT Amount";
                            VATAmountLine."Amount Including VAT" := Amount + "VAT Amount";
                            VATAmountLine.InsertLine;

                            ReminderInterestAmount := 0;

                            case Type of
                                Type::"G/L Account":
                                    "Remaining Amount" := Amount;
                                Type::"Line Fee":
                                    "Remaining Amount" := Amount;
                                Type::"Customer Ledger Entry":
                                    ReminderInterestAmount := Amount;
                            end;

                            NNC_InterestAmountTotal += ReminderInterestAmount;
                            NNC_RemainingAmountTotal += "Remaining Amount";
                            NNC_VATAmountTotal += "VAT Amount";

                            NNC_InterestAmount := (NNC_InterestAmountTotal + NNC_VATAmountTotal + "Issued Reminder Header"."Additional Fee" -
                                                   AddFeeInclVAT + "Issued Reminder Header"."Add. Fee per Line" - AddFeePerLineInclVAT) /
                              (VATInterest / 100 + 1);
                            NNC_Total := NNC_RemainingAmountTotal + NNC_InterestAmountTotal;
                            NNC_VATAmount := NNC_VATAmountTotal;
                            NNC_TotalInclVAT := NNC_RemainingAmountTotal + NNC_InterestAmountTotal + NNC_VATAmountTotal;

                            TotalRemAmt += "Remaining Amount";
                        end;

                        RemainingAmt := '';

                        if ("Remaining Amount" = 0) and ("Due Date" = 0D) then
                            RemainingAmt := ''
                        else
                            RemainingAmt := Format("Remaining Amount");
                    end;

                    trigger OnPreDataItem()
                    begin
                        Clear(CompanyInfo.Picture);
                        Clear(CompanyInfo1.Picture);
                        Clear(CompanyInfo2.Picture);
                        Clear(CompanyInfo3.Picture);

                        if FindLast then begin
                            EndLineNo := "Line No." + 1;
                            repeat
                                Continue :=
                                  not ShowNotDueAmounts and
                                  ("No. of Reminders" = 0) and
                                  (((Type = Type::"Customer Ledger Entry") or (Type = Type::"Line Fee")) or (Type = Type::" ")) or
                                  "Detailed Interest Rates Entry" and not ShowMIRLines;
                                if Continue then
                                    EndLineNo := "Line No.";
                            until (Next(-1) = 0) or not Continue;
                        end;

                        VATAmountLine.DeleteAll();
                        SetFilter("Line No.", '<%1', EndLineNo);
                    end;
                }
                dataitem(IssuedReminderLine2; "Issued Reminder Line")
                {
                    DataItemLink = "Reminder No." = FIELD("No.");
                    DataItemLinkReference = "Issued Reminder Header";
                    DataItemTableView = SORTING("Reminder No.", "Line No.");
                    column(Desc2_IssuedReminderLine; Description)
                    {
                    }
                    column(LineNo_IssuedReminderLine; "Line No.")
                    {
                    }

                    trigger OnPreDataItem()
                    begin
                        SetFilter("Line No.", '>=%1', EndLineNo);
                        if not ShowNotDueAmounts then begin
                            SetFilter(Type, '<>%1', Type::" ");
                            if FindFirst then
                                if "Line No." > EndLineNo then begin
                                    SetRange(Type);
                                    SetRange("Line No.", EndLineNo, "Line No." - 1); // find "Open Entries Not Due" line
                                    if FindLast then
                                        SetRange("Line No.", EndLineNo, "Line No." - 1);
                                end;
                            SetRange(Type);
                        end;
                    end;
                }
                dataitem(VATCounter; "Integer")
                {
                    DataItemTableView = SORTING(Number);
                    column(AmtIncludVAT_VATAmtLine; VATAmountLine."Amount Including VAT")
                    {
                        AutoFormatExpression = "Issued Reminder Line".GetCurrencyCodeFromHeader;
                        AutoFormatType = 1;
                    }
                    column(VALVATAmt; VALVATAmount)
                    {
                        AutoFormatExpression = "Issued Reminder Line".GetCurrencyCodeFromHeader;
                        AutoFormatType = 1;
                    }
                    column(VALVATBase; VALVATBase)
                    {
                        AutoFormatExpression = "Issued Reminder Line".GetCurrencyCodeFromHeader;
                        AutoFormatType = 1;
                    }
                    column(VALVATBaseVALVATAmt; VALVATBase + VALVATAmount)
                    {
                        AutoFormatExpression = "Issued Reminder Line".GetCurrencyCodeFromHeader;
                        AutoFormatType = 1;
                    }
                    column(VATAmtLineVAT; VATAmountLine."VAT %")
                    {
                    }
                    column(AmountInclVATCaption; AmountInclVATCaptionLbl)
                    {
                    }
                    column(VATAmountSpecificationCaption; VATAmountSpecificationCaptionLbl)
                    {
                    }
                    column(TotalCaption; TotalCaptionLbl)
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
                        if VATAmountLine.GetTotalVATAmount = 0 then
                            CurrReport.Break();

                        SetRange(Number, 1, VATAmountLine.Count);

                        VALVATBase := 0;
                        VALVATAmount := 0;
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
                    column(VATAmtLineVATCounter; VATAmountLine."VAT %")
                    {
                        DecimalPlaces = 0 : 5;
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
                           ("Issued Reminder Header"."Currency Code" = '') or
                           (VATAmountLine.GetTotalVATAmount = 0)
                        then
                            CurrReport.Break();

                        SetRange(Number, 1, VATAmountLine.Count);

                        VALVATBaseLCY := 0;
                        VALVATAmountLCY := 0;

                        if GLSetup."LCY Code" = '' then
                            VALSpecLCYHeader := Text011 + Text012
                        else
                            VALSpecLCYHeader := Text011 + Format(GLSetup."LCY Code");

                        CurrExchRate.FindCurrency("Issued Reminder Header"."Posting Date", "Issued Reminder Header"."Currency Code", 1);
                        CustEntry.SetRange("Customer No.", "Issued Reminder Header"."Customer No.");
                        CustEntry.SetRange("Document Type", CustEntry."Document Type"::Reminder);
                        CustEntry.SetRange("Document No.", "Issued Reminder Header"."No.");
                        if CustEntry.FindFirst then begin
                            CustEntry.CalcFields("Amount (LCY)", Amount);
                            CurrFactor := 1 / (CustEntry."Amount (LCY)" / CustEntry.Amount);
                            VALExchRate := StrSubstNo(Text013, Round(1 / CurrFactor * 100, 0.000001), CurrExchRate."Exchange Rate Amount");
                        end else begin
                            CurrFactor := CurrExchRate.ExchangeRate("Issued Reminder Header"."Posting Date", "Issued Reminder Header"."Currency Code");
                            VALExchRate := StrSubstNo(Text013, CurrExchRate."Relational Exch. Rate Amount", CurrExchRate."Exchange Rate Amount");
                        end;
                    end;
                }
                dataitem(LetterText; "Integer")
                {
                    DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                    column(GreetingText; GreetingLbl)
                    {
                    }
                    column(AmtDueText; AmtDueTxt)
                    {
                    }
                    column(BodyText; BodyLbl)
                    {
                    }
                    column(ClosingText; ClosingLbl)
                    {
                    }
                    column(DescriptionText; DescriptionLbl)
                    {
                    }
                    column(TotalRemAmt_IssuedReminderLine; TotalRemAmt)
                    {
                    }

                    trigger OnPreDataItem()
                    begin
                        AmtDueTxt := '';
                        if Format("Issued Reminder Header"."Due Date") <> '' then
                            AmtDueTxt := StrSubstNo(AmtDueLbl, "Issued Reminder Header"."Due Date");
                    end;
                }
            }

            trigger OnAfterGetRecord()
            var
                GLAcc: Record "G/L Account";
                CustPostingGroup: Record "Customer Posting Group";
                VATPostingSetup: Record "VAT Posting Setup";
            begin
                CurrReport.Language := Language.GetLanguageIdOrDefault("Language Code");

                DimSetEntry.SetRange("Dimension Set ID", "Dimension Set ID");

                FormatAddr.IssuedReminder(CustAddr, "Issued Reminder Header");
                if "Your Reference" = '' then
                    ReferenceText := ''
                else
                    ReferenceText := FieldCaption("Your Reference");
                if "Issued Reminder Header".GetCustomerVATRegistrationNumber = '' then
                    VATNoText := ''
                else
                    VATNoText := "Issued Reminder Header".GetCustomerVATRegistrationNumberLbl();
                if "Currency Code" = '' then begin
                    GLSetup.TestField("LCY Code");
                    TotalText := StrSubstNo(Text000, GLSetup."LCY Code");
                    TotalInclVATText := StrSubstNo(Text001, GLSetup."LCY Code");
                end else begin
                    TotalText := StrSubstNo(Text000, "Currency Code");
                    TotalInclVATText := StrSubstNo(Text001, "Currency Code");
                end;
                if not IsReportInPreviewMode then
                    IncrNoPrinted;

                CalcFields("Additional Fee");
                CustPostingGroup.Get("Customer Posting Group");
                if GLAcc.Get(CustPostingGroup."Additional Fee Account") then begin
                    VATPostingSetup.Get("VAT Bus. Posting Group", GLAcc."VAT Prod. Posting Group");
                    AddFeeInclVAT := "Additional Fee" * (1 + VATPostingSetup."VAT %" / 100);
                end else
                    AddFeeInclVAT := "Additional Fee";

                CalcFields("Add. Fee per Line");
                AddFeePerLineInclVAT := "Add. Fee per Line" + CalculateLineFeeVATAmount;

                CalcFields("Interest Amount", "VAT Amount");
                if ("Interest Amount" <> 0) and ("VAT Amount" <> 0) then begin
                    GLAcc.Get(CustPostingGroup."Interest Account");
                    VATPostingSetup.Get("VAT Bus. Posting Group", GLAcc."VAT Prod. Posting Group");
                    VATInterest := VATPostingSetup."VAT %";
                    Interest :=
                      ("Interest Amount" +
                       "VAT Amount" + "Additional Fee" - AddFeeInclVAT + "Add. Fee per Line" - AddFeePerLineInclVAT) / (VATInterest / 100 + 1);
                end else begin
                    Interest := "Interest Amount";
                    VATInterest := 0;
                end;

                TotalVATAmount := "VAT Amount";
                NNC_InterestAmountTotal := 0;
                NNC_RemainingAmountTotal := 0;
                NNC_VATAmountTotal := 0;
                NNC_InterestAmount := 0;
                NNC_Total := 0;
                NNC_VATAmount := 0;
                NNC_TotalInclVAT := 0;
                TotalRemAmt := 0;
            end;

            trigger OnPreDataItem()
            begin
                CompanyInfo.Get();
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
                    field(ShowInternalInfo; ShowInternalInfo)
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
                        ToolTip = 'Specifies if you want the reminder that you print to be recorded as interaction, and to be added to the Interaction Log Entry table.';
                    }
                    field(ShowNotDueAmounts; ShowNotDueAmounts)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Not Due Amounts';
                        ToolTip = 'Specifies if you want to show amounts that are not due from customers.';
                    }
                    field(ShowMIR; ShowMIRLines)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show MIR Detail';
                        ToolTip = 'Specifies if you want multiple interest rate details for the journal lines to be included in the report.';
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
            LogInteraction := SegManagement.FindInteractTmplCode(8) <> '';
            LogInteractionEnable := LogInteraction;
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        GLSetup.Get();
        CompanyInfo.Get();
        SalesSetup.Get();

        case SalesSetup."Logo Position on Documents" of
            SalesSetup."Logo Position on Documents"::"No Logo":
                ;
            SalesSetup."Logo Position on Documents"::Left:
                begin
                    CompanyInfo3.Get();
                    CompanyInfo3.CalcFields(Picture);
                end;
            SalesSetup."Logo Position on Documents"::Center:
                begin
                    CompanyInfo1.Get();
                    CompanyInfo1.CalcFields(Picture);
                end;
            SalesSetup."Logo Position on Documents"::Right:
                begin
                    CompanyInfo2.Get();
                    CompanyInfo2.CalcFields(Picture);
                end;
        end;
    end;

    trigger OnPostReport()
    begin
        if LogInteraction and not IsReportInPreviewMode then
            if "Issued Reminder Header".FindSet then
                repeat
                    SegManagement.LogDocument(
                      8, "Issued Reminder Header"."No.", 0, 0, DATABASE::Customer, "Issued Reminder Header"."Customer No.",
                      '', '', "Issued Reminder Header"."Posting Description", '');
                until "Issued Reminder Header".Next = 0;
    end;

    var
        Text000: Label 'Total %1';
        Text001: Label 'Total %1 Incl. VAT';
        CustEntry: Record "Cust. Ledger Entry";
        GLSetup: Record "General Ledger Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        CompanyInfo: Record "Company Information";
        CompanyInfo1: Record "Company Information";
        CompanyInfo2: Record "Company Information";
        CompanyInfo3: Record "Company Information";
        VATAmountLine: Record "VAT Amount Line" temporary;
        DimSetEntry: Record "Dimension Set Entry";
        CurrExchRate: Record "Currency Exchange Rate";
        Language: Codeunit Language;
        FormatAddr: Codeunit "Format Address";
        SegManagement: Codeunit SegManagement;
        CustAddr: array[8] of Text[100];
        CompanyAddr: array[8] of Text[100];
        VATNoText: Text[30];
        ReferenceText: Text[35];
        TotalText: Text[50];
        TotalInclVATText: Text[50];
        ReminderInterestAmount: Decimal;
        EndLineNo: Integer;
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
        Text011: Label 'VAT Amount Specification in ';
        Text012: Label 'Local Currency';
        Text013: Label 'Exchange rate: %1/%2';
        AddFeeInclVAT: Decimal;
        AddFeePerLineInclVAT: Decimal;
        TotalVATAmount: Decimal;
        VATInterest: Decimal;
        VALVATBase: Decimal;
        VALVATAmount: Decimal;
        Interest: Decimal;
        NNC_InterestAmount: Decimal;
        NNC_Total: Decimal;
        NNC_VATAmount: Decimal;
        NNC_TotalInclVAT: Decimal;
        NNC_InterestAmountTotal: Decimal;
        NNC_RemainingAmountTotal: Decimal;
        NNC_VATAmountTotal: Decimal;
        [InDataSet]
        LogInteractionEnable: Boolean;
        ShowNotDueAmounts: Boolean;
        DueDateCaptionLbl: Label 'Due Date';
        RemLineDocumentDateCaptionLbl: Label 'Document Date';
        TextPageLbl: Label 'Page';
        PostingDateCaptionLbl: Label 'Posting Date';
        ReminderNoCaptionLbl: Label 'Reminder No.';
        BankAccountNoCaptionLbl: Label 'Account No.';
        BankNameCaptionLbl: Label 'Bank';
        GiroNoCaptionLbl: Label 'Giro No.';
        PhoneNoCaptionLbl: Label 'Phone No.';
        ReminderCaptionLbl: Label 'Reminder';
        HeaderDimCaptionLbl: Label 'Header Dimensions';
        ContinuedCaptionLbl: Label 'Continued';
        InterestAmountcaptionLbl: Label 'Interest Amount';
        AmountInclVATCaptionLbl: Label 'Amount Including VAT';
        VATAmountSpecificationCaptionLbl: Label 'VAT Amount Specification';
        TotalCaptionLbl: Label 'Total';
        VatAmtCaptionLbl: Label 'VAT Amount';
        VatBaseCaptionLbl: Label 'VAT Base';
        VatpercentcaptionLbl: Label 'VAT %';
        CompanyInfoHomePageCaptionLbl: Label 'Home Page';
        CompanyInfoEmailIdCaptionLbl: Label 'E-Mail';
        PageCaptionLbl: Label 'Page';
        GreetingLbl: Label 'Hello';
        AmtDueLbl: Label 'You are receiving this email to formally notify you that payment owed by you is past due. The payment was due on %1. Enclosed is a copy of invoice with the details of remaining amount.', Comment = '%1 = A due date';
        BodyLbl: Label 'If you have already made the payment, please disregard this email. Thank you for your business.';
        ClosingLbl: Label 'Sincerely';
        DescriptionLbl: Label 'Description';
        AmtDueTxt: Text;
        RemainingAmt: Text;
        TotalRemAmt: Decimal;
        ShowMIRLines: Boolean;

    local procedure IsReportInPreviewMode(): Boolean
    var
        MailManagement: Codeunit "Mail Management";
    begin
        exit(CurrReport.Preview or MailManagement.IsHandlingGetEmailBody);
    end;
}

