#if not CLEAN18
report 31057 "Posted Credit"
{
    DefaultLayout = RDLC;
    RDLCLayout = './PostedCredit.rdlc';
    Caption = 'Posted Credit (Obsolete)';
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Compensation Localization Pack for Czech.';
    ObsoleteTag = '18.0';

    dataset
    {
        dataitem("Posted Credit Header"; "Posted Credit Header")
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.", "Company No.";
            column(Posted_Credit_Header_No_; "No.")
            {
            }
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = SORTING(Number);
                dataitem(PageLopp; "Integer")
                {
                    DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                    column(gteAddress; Addr)
                    {
                    }
                    column(gteName; Name)
                    {
                    }
                    column(greCompanyInfo__Registration_No__; CompanyInfo."Registration No.")
                    {
                    }
                    column(greCompanyInfo__Bank_Account_No__; CompanyInfo."Bank Account No.")
                    {
                    }
                    column(greCompanyInfo_Address__________greCompanyInfo__Post_Code___________greCompanyInfo_City; CompanyInfo.Address + ', ' + CompanyInfo."Post Code" + '  ' + CompanyInfo.City)
                    {
                    }
                    column(greCompanyInfo_Name; CompanyInfo.Name)
                    {
                    }
                    column(STRSUBSTNO_gtcText001__Posted_Credit_Header___Posting_Date__; StrSubstNo(ToDateLbl, "Posted Credit Header"."Posting Date"))
                    {
                    }
                    column(STRSUBSTNO_gtcText000__Posted_Credit_Header___No___; StrSubstNo(AgreementLbl, "Posted Credit Header"."No."))
                    {
                    }
                    column(gteRegNo; RegNo)
                    {
                    }
                    column(gteBank; Bank)
                    {
                    }
                    column(gteAddressCaption; gteAddressCaptionLbl)
                    {
                    }
                    column(gteNameCaption; gteNameCaptionLbl)
                    {
                    }
                    column(greCompanyInfo__Registration_No__Caption; greCompanyInfo__Registration_No__CaptionLbl)
                    {
                    }
                    column(greCompanyInfo__Bank_Account_No__Caption; greCompanyInfo__Bank_Account_No__CaptionLbl)
                    {
                    }
                    column(greCompanyInfo_Address__________greCompanyInfo__Post_Code___________greCompanyInfo_CityCaption; greCompanyInfo_Address__________greCompanyInfo__Post_Code___________greCompanyInfo_CityCaptionLbl)
                    {
                    }
                    column(greCompanyInfo_NameCaption; greCompanyInfo_NameCaptionLbl)
                    {
                    }
                    column(by_reciprocally_credit_receibables_by_364_Business_LawCaption; by_reciprocally_credit_receibables_by_par364_Business_LawCaptionLbl)
                    {
                    }
                    column(gteRegNoCaption; gteRegNoCaptionLbl)
                    {
                    }
                    column(gteBankCaption; gteBankCaptionLbl)
                    {
                    }
                    column(ginOutputNo; OutputNo)
                    {
                    }
                    column(PageLopp_Number; Number)
                    {
                    }
                    dataitem("Posted Credit Line"; "Posted Credit Line")
                    {
                        DataItemLink = "Credit No." = FIELD("No.");
                        DataItemLinkReference = "Posted Credit Header";
                        DataItemTableView = SORTING("Credit No.", "Line No.") WHERE("Source Type" = CONST(Customer));
                        column(STRSUBSTNO_gtcText002_greCompanyInfo_Name_; StrSubstNo(ReceivablesAndPayablesLbl, CompanyInfo.Name))
                        {
                        }
                        column(Posted_Credit_Line__Remaining_Amount_; "Remaining Amount")
                        {
                        }
                        column(Posted_Credit_Line_Amount; Amount)
                        {
                        }
                        column(Posted_Credit_Line__Ledg__Entry_Remaining_Amount_; "Ledg. Entry Remaining Amount")
                        {
                        }
                        column(Posted_Credit_Line__Ledg__Entry_Original_Amount_; "Ledg. Entry Original Amount")
                        {
                        }
                        column(gdaDueDate; Format(DueDate))
                        {
                        }
                        column(Posted_Credit_Line__Currency_Code_; "Currency Code")
                        {
                        }
                        column(Posted_Credit_Line__Variable_Symbol_; "Variable Symbol")
                        {
                        }
                        column(Posted_Credit_Line__Document_No__; "Document No.")
                        {
                        }
                        column(Posted_Credit_Line__Document_Type_; "Document Type")
                        {
                        }
                        column(Posted_Credit_Line__Posting_Date_; Format("Posting Date"))
                        {
                        }
                        column(Posted_Credit_Line__Remaining_Amount_Caption; Posted_Credit_Line__Remaining_Amount_CaptionLbl)
                        {
                        }
                        column(Posted_Credit_Line_AmountCaption; Posted_Credit_Line_AmountCaptionLbl)
                        {
                        }
                        column(Posted_Credit_Line__Ledg__Entry_Remaining_Amount_Caption; Posted_Credit_Line__Ledg__Entry_Remaining_Amount_CaptionLbl)
                        {
                        }
                        column(Posted_Credit_Line__Ledg__Entry_Original_Amount_Caption; Posted_Credit_Line__Ledg__Entry_Original_Amount_CaptionLbl)
                        {
                        }
                        column(gdaDueDateCaption; gdaDueDateCaptionLbl)
                        {
                        }
                        column(Posted_Credit_Line__Currency_Code_Caption; FieldCaption("Currency Code"))
                        {
                        }
                        column(Posted_Credit_Line__Variable_Symbol_Caption; FieldCaption("Variable Symbol"))
                        {
                        }
                        column(Posted_Credit_Line__Document_No__Caption; FieldCaption("Document No."))
                        {
                        }
                        column(Posted_Credit_Line__Document_Type_Caption; FieldCaption("Document Type"))
                        {
                        }
                        column(Posted_Credit_Line__Posting_Date_Caption; FieldCaption("Posting Date"))
                        {
                        }
                        column(Posted_Credit_Line_Credit_No_; "Credit No.")
                        {
                        }
                        column(Posted_Credit_Line_Line_No_; "Line No.")
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            case "Source Type" of
                                "Source Type"::Vendor:
                                    with VendLedgEntry do begin
                                        Get("Source Entry No.");
                                        DueDate := "Due Date";
                                    end;
                                "Source Type"::Customer:
                                    with CustLedgEntry do begin
                                        Get("Source Entry No.");
                                        DueDate := "Due Date";
                                    end;
                            end;

                            if "Remaining Amount" <> 0 then begin
                                TempPstdLineBuffer := "Posted Credit Line";
                                TempPstdLineBuffer.Insert();
                            end;

                            if "Currency Code" = '' then begin
                                GLSetup.TestField("LCY Code");
                                "Currency Code" := GLSetup."LCY Code";
                            end;
                        end;
                    }
                    dataitem(CreditLine2; "Posted Credit Line")
                    {
                        DataItemLink = "Credit No." = FIELD("No.");
                        DataItemLinkReference = "Posted Credit Header";
                        DataItemTableView = SORTING("Credit No.", "Line No.") WHERE("Source Type" = CONST(Vendor));
                        column(STRSUBSTNO_gtcText002_gteName_; StrSubstNo(ReceivablesAndPayablesLbl, Name))
                        {
                        }
                        column(Remaining_Amount_; -"Remaining Amount")
                        {
                        }
                        column(Amount; -Amount)
                        {
                        }
                        column(Ledg__Entry_Remaining_Amount_; -"Ledg. Entry Remaining Amount")
                        {
                        }
                        column(Ledg__Entry_Original_Amount_; -"Ledg. Entry Original Amount")
                        {
                        }
                        column(gdaDueDate2; Format(DueDate2))
                        {
                        }
                        column(CreditLine2__Currency_Code_; "Currency Code")
                        {
                        }
                        column(CreditLine2__Variable_Symbol_; "Variable Symbol")
                        {
                        }
                        column(CreditLine2__Document_No__; "Document No.")
                        {
                        }
                        column(CreditLine2__Document_Type_; "Document Type")
                        {
                        }
                        column(CreditLine2__Posting_Date_; Format("Posting Date"))
                        {
                        }
                        column(Remaining_Amount_Caption; Remaining_Amount_CaptionLbl)
                        {
                        }
                        column(AmountCaption; AmountCaptionLbl)
                        {
                        }
                        column(Ledg__Entry_Remaining_Amount_Caption; Ledg__Entry_Remaining_Amount_CaptionLbl)
                        {
                        }
                        column(Ledg__Entry_Original_Amount_Caption; Ledg__Entry_Original_Amount_CaptionLbl)
                        {
                        }
                        column(gdaDueDate2Caption; gdaDueDate2CaptionLbl)
                        {
                        }
                        column(CreditLine2__Currency_Code_Caption; FieldCaption("Currency Code"))
                        {
                        }
                        column(CreditLine2__Variable_Symbol_Caption; FieldCaption("Variable Symbol"))
                        {
                        }
                        column(CreditLine2__Document_No__Caption; FieldCaption("Document No."))
                        {
                        }
                        column(CreditLine2__Document_Type_Caption; FieldCaption("Document Type"))
                        {
                        }
                        column(CreditLine2__Posting_Date_Caption; FieldCaption("Posting Date"))
                        {
                        }
                        column(CreditLine2_Credit_No_; "Credit No.")
                        {
                        }
                        column(CreditLine2_Line_No_; "Line No.")
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            case "Source Type" of
                                "Source Type"::Vendor:
                                    with VendLedgEntry do begin
                                        Get("Source Entry No.");
                                        DueDate2 := "Due Date";
                                    end;
                                "Source Type"::Customer:
                                    with CustLedgEntry do begin
                                        Get("Source Entry No.");
                                        DueDate2 := "Due Date";
                                    end;
                            end;

                            if "Remaining Amount" <> 0 then begin
                                TempPstdLineBuffer2 := CreditLine2;
                                TempPstdLineBuffer2.Insert();
                            end;

                            if "Currency Code" = '' then begin
                                GLSetup.TestField("LCY Code");
                                "Currency Code" := GLSetup."LCY Code";
                            end;
                        end;
                    }
                    dataitem("Integer"; "Integer")
                    {
                        DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                        column(STRSUBSTNO_gtcText003_gteRemName_; StrSubstNo(RemainingReceivablesAndPayablesLbl, RemName))
                        {
                        }
                        column(STRSUBSTNO_gtcText004_greTRemLineBuffer__Variable_Symbol_Control1100162065; StrSubstNo(AmountAfterCreditLbl, TempPstdLineBuffer."Variable Symbol", Format(Abs(TempPstdLineBuffer."Remaining Amount"), 0, AmtFormatTxt), TempPstdLineBuffer."Currency Code"))
                        {
                        }
                        column(Integer_Number; Number)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if Number = 1 then begin
                                if not TempPstdLineBuffer.FindSet() then
                                    CurrReport.Break();
                            end else
                                if TempPstdLineBuffer.Next() = 0 then
                                    CurrReport.Break();

                            if TempPstdLineBuffer."Credit No." <> '' then
                                if TempPstdLineBuffer."Currency Code" = '' then begin
                                    GLSetup.TestField("LCY Code");
                                    TempPstdLineBuffer."Currency Code" := GLSetup."LCY Code";
                                end;
                        end;

                        trigger OnPreDataItem()
                        begin
                            TempPstdLineBuffer.SetRange("Source Type", TempPstdLineBuffer."Source Type"::Customer);
                            RemName := CompanyInfo.Name
                        end;
                    }
                    dataitem(Integer2; "Integer")
                    {
                        DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                        column(STRSUBSTNO_gtcText003_gteRemName__Control1100171014; StrSubstNo(RemainingReceivablesAndPayablesLbl, RemName))
                        {
                        }
                        column(STRSUBSTNO_gtcText004_greTRemLineBuffer2__Variable_Symbol_Control1100171015; StrSubstNo(AmountAfterCreditLbl, TempPstdLineBuffer2."Variable Symbol", Format(Abs(TempPstdLineBuffer2."Remaining Amount"), 0, AmtFormatTxt), TempPstdLineBuffer2."Currency Code"))
                        {
                        }
                        column(Integer2_Number; Number)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if Number = 1 then begin
                                if not TempPstdLineBuffer2.FindSet() then
                                    CurrReport.Break();
                            end else
                                if TempPstdLineBuffer2.Next() = 0 then
                                    CurrReport.Break();

                            if TempPstdLineBuffer2."Credit No." <> '' then
                                if TempPstdLineBuffer2."Currency Code" = '' then begin
                                    GLSetup.TestField("LCY Code");
                                    TempPstdLineBuffer2."Currency Code" := GLSetup."LCY Code";
                                end;
                        end;

                        trigger OnPreDataItem()
                        begin
                            TempPstdLineBuffer2.SetRange("Source Type", TempPstdLineBuffer2."Source Type"::Vendor);
                            RemName := Name;
                        end;
                    }
                    dataitem(xFoot; "Integer")
                    {
                        DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                        MaxIteration = 1;
                        column(gteName_Control1100171002; Name)
                        {
                        }
                        column(WORKDATE; Format(WorkDate))
                        {
                        }
                        column(greCompanyInfo_Name_Control1100171009; CompanyInfo.Name)
                        {
                        }
                        column(EmptyStringCaption; EmptyStringCaptionLbl)
                        {
                        }
                        column(Name_and_SignatureCaption; Name_and_SignatureCaptionLbl)
                        {
                        }
                        column(EmptyStringCaption_Control1100171003; EmptyStringCaption_Control1100171003Lbl)
                        {
                        }
                        column(In_____________date_____Caption; In_____________date_____CaptionLbl)
                        {
                        }
                        column(EmptyStringCaption_Control1100171005; EmptyStringCaption_Control1100171005Lbl)
                        {
                        }
                        column(gteName_Control1100171002Caption; gteName_Control1100171002CaptionLbl)
                        {
                        }
                        column(Name_and_SignatureCaption_Control1100171008; Name_and_SignatureCaption_Control1100171008Lbl)
                        {
                        }
                        column(EmptyStringCaption_Control1100171010; EmptyStringCaption_Control1100171010Lbl)
                        {
                        }
                        column(In______________date_____Caption; In______________date_____CaptionLbl)
                        {
                        }
                        column(WORKDATECaption; WORKDATECaptionLbl)
                        {
                        }
                        column(greCompanyInfo_Name_Control1100171009Caption; greCompanyInfo_Name_Control1100171009CaptionLbl)
                        {
                        }
                        column(xFoot_Number; Number)
                        {
                        }
                    }
                }

                trigger OnAfterGetRecord()
                begin
                    if Number > 1 then
                        OutputNo += 1;

                    TempPstdLineBuffer.Reset();
                    TempPstdLineBuffer.DeleteAll();
                    Clear(TempPstdLineBuffer);

                    TempPstdLineBuffer2.Reset();
                    TempPstdLineBuffer2.DeleteAll();
                    Clear(TempPstdLineBuffer2);
                end;

                trigger OnPreDataItem()
                begin
                    NoOfLoops := Abs(NoOfCopies) + 1;
                    if NoOfLoops <= 0 then
                        NoOfLoops := 1;
                    SetRange(Number, 1, NoOfLoops);
                    OutputNo := 1;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                Clear(Name);
                Clear(Addr);
                Clear(Bank);
                Clear(RegNo);

                Name := "Company Name";
                if "Company Name 2" <> '' then
                    Name := Name + ' ' + "Company Name 2";

                Addr := "Company Address";
                if "Company Address 2" <> '' then
                    Addr := Addr + ' ' + "Company Address 2";
                if ("Company Post Code" <> '') or ("Company City" <> '') then
                    Addr := Addr + ', ' + "Company Post Code" + ' ' + "Company City";
            end;

            trigger OnPreDataItem()
            begin
                CompanyInfo.Get();
                GLSetup.Get();

                AmtFormatTxt := '<Precision,2:2><Sign><Integer><1000Character, ><Decimals>';
            end;
        }
    }

    requestpage
    {

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
        AgreementLbl: Label 'AGREEMENT %1', Comment = '%1 = number of credit document';
        ToDateLbl: Label 'To date %1', Comment = '%1 = date';
        ReceivablesAndPayablesLbl: Label 'Receivables and Payables %1', Comment = '%1 = company name';
        RemainingReceivablesAndPayablesLbl: Label 'Remaining Receivable and Payables of %1 to pay after realize Credit.', Comment = '%1=Company Name';
        AmountAfterCreditLbl: Label 'for the variable symbol %1 are %2 %3 after the credit.', Comment = '%1=variable symbol;%2=remaining amount;%3=currency code';
        gteAddressCaptionLbl: Label 'Domicile:';
        gteNameCaptionLbl: Label 'Business Name:';
        greCompanyInfo__Registration_No__CaptionLbl: Label 'Reg. No.:';
        greCompanyInfo__Bank_Account_No__CaptionLbl: Label 'Bank connection:';
        greCompanyInfo_Address__________greCompanyInfo__Post_Code___________greCompanyInfo_CityCaptionLbl: Label 'Domicile:';
        greCompanyInfo_NameCaptionLbl: Label 'Business Name:';
        by_reciprocally_credit_receibables_by_par364_Business_LawCaptionLbl: Label 'by reciprocally credit receibables by PAR. 1982-1991 of Civil Code No. 89/2012';
        gteRegNoCaptionLbl: Label 'Reg. No.:';
        gteBankCaptionLbl: Label 'Bank connection:';
        Posted_Credit_Line__Remaining_Amount_CaptionLbl: Label 'Remaining Amount';
        Posted_Credit_Line_AmountCaptionLbl: Label 'Amount';
        Posted_Credit_Line__Ledg__Entry_Remaining_Amount_CaptionLbl: Label 'Ledg. Entry Remaining Amount';
        Posted_Credit_Line__Ledg__Entry_Original_Amount_CaptionLbl: Label 'Ledg. Entry Original Amount';
        gdaDueDateCaptionLbl: Label 'Due Date';
        Remaining_Amount_CaptionLbl: Label 'Remaining Amount';
        AmountCaptionLbl: Label 'Amount';
        Ledg__Entry_Remaining_Amount_CaptionLbl: Label 'Ledg. Entry Remaining Amount';
        Ledg__Entry_Original_Amount_CaptionLbl: Label 'Ledg. Entry Original Amount';
        gdaDueDate2CaptionLbl: Label 'Due Date';
        EmptyStringCaptionLbl: Label 'This Agreement shall enter into force upon signature by both Parties.';
        Name_and_SignatureCaptionLbl: Label 'Name and Signature';
        EmptyStringCaption_Control1100171003Lbl: Label '......................................................................';
        In_____________date_____CaptionLbl: Label 'In __________, date __________';
        EmptyStringCaption_Control1100171005Lbl: Label 'In case you agree, send one confirmed agreement back to our address.';
        gteName_Control1100171002CaptionLbl: Label 'For';
        Name_and_SignatureCaption_Control1100171008Lbl: Label 'Name and Signature';
        EmptyStringCaption_Control1100171010Lbl: Label '......................................................................';
        In______________date_____CaptionLbl: Label 'In __________, date __________';
        WORKDATECaptionLbl: Label 'Make Date';
        greCompanyInfo_Name_Control1100171009CaptionLbl: Label 'For';
        CompanyInfo: Record "Company Information";
        VendLedgEntry: Record "Vendor Ledger Entry";
        CustLedgEntry: Record "Cust. Ledger Entry";
        GLSetup: Record "General Ledger Setup";
        TempPstdLineBuffer: Record "Posted Credit Line" temporary;
        TempPstdLineBuffer2: Record "Posted Credit Line" temporary;
        Name: Text[250];
        Addr: Text[250];
        Bank: Text[250];
        RegNo: Text[250];
        RemName: Text[250];
        DueDate: Date;
        DueDate2: Date;
        NoOfCopies: Integer;
        NoOfLoops: Integer;
        OutputNo: Integer;
        AmtFormatTxt: Text;
}


#endif