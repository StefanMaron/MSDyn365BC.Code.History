report 11770 "Accounting Sheets"
{
    DefaultLayout = RDLC;
    RDLCLayout = './AccountingSheets.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Accounting Sheets';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(CommonLabels; "Integer")
        {
            DataItemTableView = SORTING(Number);
            MaxIteration = 1;
            column(NameDescCaption; NameDescCaption)
            {
            }
            column(PostingDateCaption; "Sales Invoice Header".FieldCaption("Posting Date"))
            {
            }
            column(VATDateCaption; "Sales Invoice Header".FieldCaption("VAT Date"))
            {
            }
            column(DocumentDateCaption; "Sales Invoice Header".FieldCaption("Document Date"))
            {
            }
            column(LastDataItem; LastDataItem)
            {
            }
            column(SalesInvHdrExists; SalesInvHdrExists)
            {
            }
            column(SalesCrMemoHdrExists; SalesCrMemoHdrExists)
            {
            }
            column(PurchInvHdrExists; PurchInvHdrExists)
            {
            }
            column(PurchCrMemoHdrExists; PurchCrMemoHdrExists)
            {
            }
            column(GeneralDocExists; GeneralDocExists)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if Suma then
                    NameDescCaption := G_L_Account_NameCaptionLbl
                else
                    NameDescCaption := DescriptionLbl;
            end;
        }
        dataitem("Sales Invoice Header"; "Sales Invoice Header")
        {
            CalcFields = Amount, "Amount Including VAT";
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.", "Posting Date";
            column(greCompanyInfo_Name; CompanyInfo.Name)
            {
            }
            column("Úƒetn__doklad_"; "No.")
            {
            }
            column(Sales_Invoice_Header__Sell_to_Customer_Name_; "Sell-to Customer Name")
            {
            }
            column(Sales_Invoice_Header__Due_Date_; Format("Due Date"))
            {
            }
            column(Sales_Invoice_Header_Amount; Amount)
            {
            }
            column(Amount_Including_VAT__Amount; "Amount Including VAT" - Amount)
            {
            }
            column(gdeFCYRate; FCYRate)
            {
                DecimalPlaces = 5 : 5;
            }
            column(Sales_Invoice_Header__Currency_Code_; "Currency Code")
            {
            }
            column("Úƒetn__doklad_Caption"; FieldCaption("No."))
            {
            }
            column(Sales_Invoice_Caption; Sales_Invoice_CaptionLbl)
            {
            }
            column(Sales_Invoice_Header__Sell_to_Customer_Name_Caption; Sales_Invoice_Header__Sell_to_Customer_Name_CaptionLbl)
            {
            }
            column(Sales_Invoice_Header__Due_Date_Caption; Sales_Invoice_Header__Due_Date_CaptionLbl)
            {
            }
            column(Sales_Invoice_Header_AmountCaption; FieldCaption(Amount))
            {
            }
            column(Amount_Including_VAT__AmountCaption; Amount_Including_VAT__AmountCaptionLbl)
            {
            }
            column(gdeFCYRateCaption; FCYRateCaptionLbl)
            {
            }
            column(Sales_Invoice_Header__Currency_Code_Caption; FieldCaption("Currency Code"))
            {
            }
            column(SalesInvoiceHeader_PostingDate; "Posting Date")
            {
            }
            column(SalesInvoiceHeader_VATDate; "VAT Date")
            {
            }
            column(SalesInvoiceHeader_DocumentDate; "Document Date")
            {
            }
            dataitem(GLEntry1; "G/L Entry")
            {
                DataItemLink = "Document No." = FIELD("No.");
                DataItemTableView = SORTING("Document No.", "Posting Date");

                trigger OnAfterGetRecord()
                begin
                    if UserSetup."User ID" <> "User ID" then
                        if not UserSetup.Get("User ID") then
                            UserSetup.Init;

                    BufferGLEntry(GLEntry1);
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Entry No.", 1, LastGLEntry);
                end;
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                column(CurrReport_PAGENO; CurrReport.PageNo)
                {
                }
                column("Úƒetn__doklad__Control285"; "Sales Invoice Header"."No.")
                {
                }
                column("Úƒetn__doklad__Control1100170003"; "Sales Invoice Header"."No.")
                {
                }
                column(greTGLEntry__Credit_Amount_; TempGLEntry."Credit Amount")
                {
                }
                column(greTGLEntry__Debit_Amount_; TempGLEntry."Debit Amount")
                {
                }
                column(greTGLEntry__Global_Dimension_2_Code_; TempGLEntry."Global Dimension 2 Code")
                {
                }
                column(greTGLEntry__Global_Dimension_1_Code_; TempGLEntry."Global Dimension 1 Code")
                {
                }
                column(NameDescText1; NameDescText)
                {
                }
                column(greTGLEntry__G_L_Account_No__; TempGLEntry."G/L Account No.")
                {
                }
                column(Sales_Invoice_Header___Posting_Date_; Format("Sales Invoice Header"."Posting Date"))
                {
                }
                column(greUserSetup__User_Name_; UserSetup."User Name")
                {
                }
                column(Credit_AmountCaption; Credit_AmountCaptionLbl)
                {
                }
                column(Debit_AmountCaption; Debit_AmountCaptionLbl)
                {
                }
                column(greTGLEntry__Global_Dimension_2_Code_Caption; CaptionClassTranslate('1,1,2'))
                {
                }
                column(greTGLEntry__Global_Dimension_1_Code_Caption; CaptionClassTranslate('1,1,1'))
                {
                }
                column(G_L_AccountCaption; G_L_AccountCaptionLbl)
                {
                }
                column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
                {
                }
                column("Úƒetn__doklad__Control285Caption"; "Sales Invoice Header".FieldCaption("No."))
                {
                }
                column("Úƒetn__doklad__Control1100170003Caption"; "Sales Invoice Header".FieldCaption("No."))
                {
                }
                column(ContinuedCaption; ContinuedCaptionLbl)
                {
                }
                column(ContinuedCaption_Control288; ContinuedCaption_Control288Lbl)
                {
                }
                column(Date_Caption; Date_CaptionLbl)
                {
                }
                column(Date_Caption_Control292; Date_Caption_Control292Lbl)
                {
                }
                column(Date_Caption_Control297; Date_Caption_Control297Lbl)
                {
                }
                column(Date_Caption_Control302; Date_Caption_Control302Lbl)
                {
                }
                column(EmptyStringCaption; FactualCorrectnessVerifiedByLbl)
                {
                }
                column(EmptyStringCaption_Control304; PostedByLbl)
                {
                }
                column(EmptyStringCaption_Control305; ApprovedByLbl)
                {
                }
                column(EmptyStringCaption_Control306; FormalCorrectnessVerifiedByLbl)
                {
                }
                column(Integer_Number; Number)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then
                        TempGLEntry.FindSet
                    else
                        TempGLEntry.Next;

                    GLAcc.Get(TempGLEntry."G/L Account No.");
                    if Suma then
                        NameDescText := GLAcc.Name
                    else
                        NameDescText := TempGLEntry.Description;
                end;

                trigger OnPreDataItem()
                begin
                    TempGLEntry.Reset;
                    SetRange(Number, 1, TempGLEntry.Count);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if NewPage then
                    CurrReport.PageNo(1);
                TempGLEntry.DeleteAll;

                FCYRate := 0;
                if ("Currency Code" <> '') and ("Currency Factor" <> 0) then
                    FCYRate := 1 / "Currency Factor";
            end;

            trigger OnPreDataItem()
            begin
                if not "Sales Invoice Header".HasFilter then
                    CurrReport.Break;
            end;
        }
        dataitem("Sales Cr.Memo Header"; "Sales Cr.Memo Header")
        {
            CalcFields = Amount, "Amount Including VAT";
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.", "Posting Date";
            column("Úƒetn__doklad__Control3"; "No.")
            {
            }
            column(greCompanyInfo_Name_Control4; CompanyInfo.Name)
            {
            }
            column(Sales_Cr_Memo_Header__Due_Date_; Format("Due Date"))
            {
            }
            column(Sales_Cr_Memo_Header__Sell_to_Customer_Name_; "Sell-to Customer Name")
            {
            }
            column(Amount_Including_VAT__Amount_Control235; "Amount Including VAT" - Amount)
            {
            }
            column(Sales_Cr_Memo_Header_Amount; Amount)
            {
            }
            column(Sales_Cr_Memo_Header__Currency_Code_; "Currency Code")
            {
            }
            column(gdeFCYRate_Control1100162004; FCYRate)
            {
                DecimalPlaces = 5 : 5;
            }
            column("Úƒetn__doklad__Control3Caption"; FieldCaption("No."))
            {
            }
            column(Sales_Credit_Memo_Caption; Sales_Credit_Memo_CaptionLbl)
            {
            }
            column(Sales_Cr_Memo_Header__Due_Date_Caption; Sales_Cr_Memo_Header__Due_Date_CaptionLbl)
            {
            }
            column(Sales_Cr_Memo_Header__Sell_to_Customer_Name_Caption; Sales_Cr_Memo_Header__Sell_to_Customer_Name_CaptionLbl)
            {
            }
            column(Amount_Including_VAT__Amount_Control235Caption; Amount_Including_VAT__Amount_Control235CaptionLbl)
            {
            }
            column(Sales_Cr_Memo_Header_AmountCaption; FieldCaption(Amount))
            {
            }
            column(Sales_Cr_Memo_Header__Currency_Code_Caption; FieldCaption("Currency Code"))
            {
            }
            column(gdeFCYRate_Control1100162004Caption; FCYRate_Control1100162004CaptionLbl)
            {
            }
            column(SalesCrMemoHeader_PostingDate; "Posting Date")
            {
            }
            column(SalesCrMemoHeader_VATDate; "VAT Date")
            {
            }
            column(SalesCrMemoHeader_DocumentDate; "Document Date")
            {
            }
            dataitem(GLEntry2; "G/L Entry")
            {
                DataItemLink = "Document No." = FIELD("No.");
                DataItemTableView = SORTING("Document No.", "Posting Date");

                trigger OnAfterGetRecord()
                begin
                    if UserSetup."User ID" <> "User ID" then
                        if not UserSetup.Get("User ID") then
                            UserSetup.Init;

                    BufferGLEntry(GLEntry2);
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Entry No.", 1, LastGLEntry);
                end;
            }
            dataitem(Integer2; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                column(CurrReport_PAGENO_Control41; CurrReport.PageNo)
                {
                }
                column("Úƒetn__doklad__Control43"; "Sales Cr.Memo Header"."No.")
                {
                }
                column("Úƒetn__doklad__Control1100170007"; "Sales Cr.Memo Header"."No.")
                {
                }
                column(greTGLEntry__Credit_Amount__Control90; TempGLEntry."Credit Amount")
                {
                }
                column(greTGLEntry__Debit_Amount__Control91; TempGLEntry."Debit Amount")
                {
                }
                column(greTGLEntry__Global_Dimension_2_Code__Control106; TempGLEntry."Global Dimension 2 Code")
                {
                }
                column(greTGLEntry__Global_Dimension_1_Code__Control112; TempGLEntry."Global Dimension 1 Code")
                {
                }
                column(NameDescText2; NameDescText)
                {
                }
                column(greTGLEntry__G_L_Account_No___Control115; TempGLEntry."G/L Account No.")
                {
                }
                column(Sales_Cr_Memo_Header___Posting_Date_; Format("Sales Cr.Memo Header"."Posting Date"))
                {
                }
                column(greUserSetup__User_Name__Control310; UserSetup."User Name")
                {
                }
                column(Credit_AmountCaption_Control20; Credit_AmountCaption_Control20Lbl)
                {
                }
                column(Debit_AmountCaption_Control24; Debit_AmountCaption_Control24Lbl)
                {
                }
                column(greTGLEntry__Global_Dimension_2_Code__Control106Caption; CaptionClassTranslate('1,1,2'))
                {
                }
                column(greTGLEntry__Global_Dimension_1_Code__Control112Caption; CaptionClassTranslate('1,1,1'))
                {
                }
                column(G_L_AccountCaption_Control29; G_L_AccountCaption_Control29Lbl)
                {
                }
                column(CurrReport_PAGENO_Control41Caption; CurrReport_PAGENO_Control41CaptionLbl)
                {
                }
                column("Úƒetn__doklad__Control43Caption"; "Sales Cr.Memo Header".FieldCaption("No."))
                {
                }
                column("Úƒetn__doklad__Control1100170007Caption"; "Sales Cr.Memo Header".FieldCaption("No."))
                {
                }
                column(ContinuedCaption_Control1100170024; ContinuedCaption_Control1100170024Lbl)
                {
                }
                column(ContinuedCaption_Control118; ContinuedCaption_Control118Lbl)
                {
                }
                column(Date_Caption_Control121; Date_Caption_Control121Lbl)
                {
                }
                column(Date_Caption_Control122; Date_Caption_Control122Lbl)
                {
                }
                column(Date_Caption_Control247; Date_Caption_Control247Lbl)
                {
                }
                column(Date_Caption_Control313; Date_Caption_Control313Lbl)
                {
                }
                column(EmptyStringCaption_Control314; FactualCorrectnessVerifiedByLbl)
                {
                }
                column(EmptyStringCaption_Control315; PostedByLbl)
                {
                }
                column(EmptyStringCaption_Control316; ApprovedByLbl)
                {
                }
                column(EmptyStringCaption_Control317; FormalCorrectnessVerifiedByLbl)
                {
                }
                column(Integer2_Number; Number)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then
                        TempGLEntry.FindSet
                    else
                        TempGLEntry.Next;

                    GLAcc.Get(TempGLEntry."G/L Account No.");
                    if Suma then
                        NameDescText := GLAcc.Name
                    else
                        NameDescText := TempGLEntry.Description;
                end;

                trigger OnPreDataItem()
                begin
                    TempGLEntry.Reset;
                    SetRange(Number, 1, TempGLEntry.Count);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if NewPage then
                    CurrReport.PageNo(1);
                TempGLEntry.DeleteAll;

                FCYRate := 0;
                if ("Currency Code" <> '') and ("Currency Factor" <> 0) then
                    FCYRate := 1 / "Currency Factor";
            end;

            trigger OnPreDataItem()
            begin
                if not "Sales Cr.Memo Header".HasFilter then
                    CurrReport.Break;
            end;
        }
        dataitem("Purch. Inv. Header"; "Purch. Inv. Header")
        {
            CalcFields = Amount, "Amount Including VAT";
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.", "Posting Date";
            column("Úƒetn__doklad__Control6"; "No.")
            {
            }
            column(greCompanyInfo_Name_Control32; CompanyInfo.Name)
            {
            }
            column(Purch__Inv__Header__Due_Date_; Format("Due Date"))
            {
            }
            column(Purch__Inv__Header__Buy_from_Vendor_Name_; "Buy-from Vendor Name")
            {
            }
            column(Purch__Inv__Header__Vendor_Invoice_No__; "Vendor Invoice No.")
            {
            }
            column(Purch__Inv__Header_Amount; Amount)
            {
            }
            column(Amount_Including_VAT__Amount_Control241; "Amount Including VAT" - Amount)
            {
            }
            column(Purch__Inv__Header__Currency_Code_; "Currency Code")
            {
            }
            column(gdeFCYRate_Control1100162009; FCYRate)
            {
                DecimalPlaces = 5 : 5;
            }
            column("Úƒetn__doklad__Control6Caption"; FieldCaption("No."))
            {
            }
            column(Purchase_Invoice_Caption; Purchase_Invoice_CaptionLbl)
            {
            }
            column(Purch__Inv__Header__Due_Date_Caption; Purch__Inv__Header__Due_Date_CaptionLbl)
            {
            }
            column(Purch__Inv__Header__Buy_from_Vendor_Name_Caption; Purch__Inv__Header__Buy_from_Vendor_Name_CaptionLbl)
            {
            }
            column(Purch__Inv__Header__Vendor_Invoice_No__Caption; Purch__Inv__Header__Vendor_Invoice_No__CaptionLbl)
            {
            }
            column(Amount_Including_VAT__Amount_Control241Caption; Amount_Including_VAT__Amount_Control241CaptionLbl)
            {
            }
            column(Purch__Inv__Header_AmountCaption; FieldCaption(Amount))
            {
            }
            column(Purch__Inv__Header__Currency_Code_Caption; FieldCaption("Currency Code"))
            {
            }
            column(gdeFCYRate_Control1100162009Caption; FCYRate_Control1100162009CaptionLbl)
            {
            }
            column(PurchInvoiceHeader_PostingDate; "Posting Date")
            {
            }
            column(PurchInvoiceHeader_VATDate; "VAT Date")
            {
            }
            column(PurchInvoiceHeader_DocumentDate; "Document Date")
            {
            }
            dataitem(GLEntry3; "G/L Entry")
            {
                DataItemLink = "Document No." = FIELD("No.");
                DataItemTableView = SORTING("Document No.", "Posting Date");

                trigger OnAfterGetRecord()
                begin
                    if UserSetup."User ID" <> "User ID" then
                        if not UserSetup.Get("User ID") then
                            UserSetup.Init;

                    BufferGLEntry(GLEntry3);
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Entry No.", 1, LastGLEntry);
                end;
            }
            dataitem(Integer3; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                column(CurrReport_PAGENO_Control326; CurrReport.PageNo)
                {
                }
                column("Úƒetn__doklad__Control328"; "Purch. Inv. Header"."No.")
                {
                }
                column("Úƒetn__doklad__Control1100170012"; "Purch. Inv. Header"."No.")
                {
                }
                column(greTGLEntry__Credit_Amount__Control331; TempGLEntry."Credit Amount")
                {
                }
                column(greTGLEntry__Debit_Amount__Control332; TempGLEntry."Debit Amount")
                {
                }
                column(greTGLEntry__Global_Dimension_2_Code__Control334; TempGLEntry."Global Dimension 2 Code")
                {
                }
                column(greTGLEntry__Global_Dimension_1_Code__Control335; TempGLEntry."Global Dimension 1 Code")
                {
                }
                column(NameDescText3; NameDescText)
                {
                }
                column(greTGLEntry__G_L_Account_No___Control338; TempGLEntry."G/L Account No.")
                {
                }
                column(Purch__Inv__Header___Posting_Date_; Format("Purch. Inv. Header"."Posting Date"))
                {
                }
                column(greUserSetup__User_Name__Control352; UserSetup."User Name")
                {
                }
                column(Credit_AmountCaption_Control319; Credit_AmountCaption_Control319Lbl)
                {
                }
                column(Debit_AmountCaption_Control320; Debit_AmountCaption_Control320Lbl)
                {
                }
                column(greTGLEntry__Global_Dimension_2_Code__Control334Caption; CaptionClassTranslate('1,1,2'))
                {
                }
                column(greTGLEntry__Global_Dimension_1_Code__Control335Caption; CaptionClassTranslate('1,1,1'))
                {
                }
                column(G_L_AccountCaption_Control324; G_L_AccountCaption_Control324Lbl)
                {
                }
                column(CurrReport_PAGENO_Control326Caption; CurrReport_PAGENO_Control326CaptionLbl)
                {
                }
                column("Úƒetn__doklad__Control328Caption"; "Purch. Inv. Header".FieldCaption("No."))
                {
                }
                column("Úƒetn__doklad__Control1100170012Caption"; "Purch. Inv. Header".FieldCaption("No."))
                {
                }
                column(ContinuedCaption_Control1100170025; ContinuedCaption_Control1100170025Lbl)
                {
                }
                column(ContinuedCaption_Control341; ContinuedCaption_Control341Lbl)
                {
                }
                column(Date_Caption_Control343; Date_Caption_Control343Lbl)
                {
                }
                column(Date_Caption_Control347; Date_Caption_Control347Lbl)
                {
                }
                column(Date_Caption_Control350; Date_Caption_Control350Lbl)
                {
                }
                column(EmptyStringCaption_Control353; PostedByLbl)
                {
                }
                column(EmptyStringCaption_Control354; ApprovedByLbl)
                {
                }
                column(EmptyStringCaption_Control355; FormalCorrectnessVerifiedByLbl)
                {
                }
                column(EmptyStringCaption_Control357; FactualCorrectnessVerifiedByLbl)
                {
                }
                column(Date_Caption_Control359; Date_Caption_Control359Lbl)
                {
                }
                column(Integer3_Number; Number)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then
                        TempGLEntry.FindSet
                    else
                        TempGLEntry.Next;

                    GLAcc.Get(TempGLEntry."G/L Account No.");
                    if Suma then
                        NameDescText := GLAcc.Name
                    else
                        NameDescText := TempGLEntry.Description;
                end;

                trigger OnPreDataItem()
                begin
                    TempGLEntry.Reset;
                    SetRange(Number, 1, TempGLEntry.Count);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if NewPage then
                    CurrReport.PageNo(1);
                TempGLEntry.DeleteAll;

                FCYRate := 0;
                if ("Currency Code" <> '') and ("Currency Factor" <> 0) then
                    FCYRate := 1 / "Currency Factor";
            end;

            trigger OnPreDataItem()
            begin
                if not "Purch. Inv. Header".HasFilter then
                    CurrReport.Break;
            end;
        }
        dataitem("Purch. Cr. Memo Hdr."; "Purch. Cr. Memo Hdr.")
        {
            CalcFields = Amount, "Amount Including VAT";
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.", "Posting Date";
            column("Úƒetn__doklad__Control34"; "No.")
            {
            }
            column(greCompanyInfo_Name_Control35; CompanyInfo.Name)
            {
            }
            column(Purch__Cr__Memo_Hdr___Due_Date_; Format("Due Date"))
            {
            }
            column(Purch__Cr__Memo_Hdr___Buy_from_Vendor_Name_; "Buy-from Vendor Name")
            {
            }
            column(Purch__Cr__Memo_Hdr___Vendor_Cr__Memo_No__; "Vendor Cr. Memo No.")
            {
            }
            column(Purch__Cr__Memo_Hdr__Amount; Amount)
            {
            }
            column(Amount_Including_VAT__Amount_Control245; "Amount Including VAT" - Amount)
            {
            }
            column(gdeFCYRate_Control1100162011; FCYRate)
            {
                DecimalPlaces = 5 : 5;
            }
            column(Purch__Cr__Memo_Hdr___Currency_Code_; "Currency Code")
            {
            }
            column("Úƒetn__doklad__Control34Caption"; FieldCaption("No."))
            {
            }
            column(Purchase_Credit_Memo_Caption; Purchase_Credit_Memo_CaptionLbl)
            {
            }
            column(Purch__Cr__Memo_Hdr___Due_Date_Caption; Purch__Cr__Memo_Hdr___Due_Date_CaptionLbl)
            {
            }
            column(Purch__Cr__Memo_Hdr___Buy_from_Vendor_Name_Caption; Purch__Cr__Memo_Hdr___Buy_from_Vendor_Name_CaptionLbl)
            {
            }
            column(Purch__Cr__Memo_Hdr___Vendor_Cr__Memo_No__Caption; Purch__Cr__Memo_Hdr___Vendor_Cr__Memo_No__CaptionLbl)
            {
            }
            column(Amount_Including_VAT__Amount_Control245Caption; Amount_Including_VAT__Amount_Control245CaptionLbl)
            {
            }
            column(Purch__Cr__Memo_Hdr__AmountCaption; FieldCaption(Amount))
            {
            }
            column(Purch__Cr__Memo_Hdr___Currency_Code_Caption; FieldCaption("Currency Code"))
            {
            }
            column(gdeFCYRate_Control1100162011Caption; FCYRate_Control1100162011CaptionLbl)
            {
            }
            column(PurchCrMemoHeader_PostingDate; "Posting Date")
            {
            }
            column(PurchCrMemoHeader_VATDate; "VAT Date")
            {
            }
            column(PurchCrMemoHeader_DocumentDate; "Document Date")
            {
            }
            dataitem(GLEntry4; "G/L Entry")
            {
                DataItemLink = "Document No." = FIELD("No.");
                DataItemTableView = SORTING("Document No.", "Posting Date");

                trigger OnAfterGetRecord()
                begin
                    if UserSetup."User ID" <> "User ID" then
                        if not UserSetup.Get("User ID") then
                            UserSetup.Init;

                    BufferGLEntry(GLEntry4);
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Entry No.", 1, LastGLEntry);
                end;
            }
            dataitem(Integer4; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                column(CurrReport_PAGENO_Control368; CurrReport.PageNo)
                {
                }
                column("Úƒetn__doklad__Control370"; "Purch. Cr. Memo Hdr."."No.")
                {
                }
                column("Úƒetn__doklad__Control1100170017"; "Purch. Cr. Memo Hdr."."No.")
                {
                }
                column(greTGLEntry__Credit_Amount__Control373; TempGLEntry."Credit Amount")
                {
                }
                column(greTGLEntry__Debit_Amount__Control374; TempGLEntry."Debit Amount")
                {
                }
                column(greTGLEntry__Global_Dimension_2_Code__Control376; TempGLEntry."Global Dimension 2 Code")
                {
                }
                column(greTGLEntry__Global_Dimension_1_Code__Control377; TempGLEntry."Global Dimension 1 Code")
                {
                }
                column(NameDescText4; NameDescText)
                {
                }
                column(greTGLEntry__G_L_Account_No___Control380; TempGLEntry."G/L Account No.")
                {
                }
                column(Purch__Cr__Memo_Hdr____Posting_Date_; Format("Purch. Cr. Memo Hdr."."Posting Date"))
                {
                }
                column(greUserSetup__User_Name__Control394; UserSetup."User Name")
                {
                }
                column(Credit_AmountCaption_Control360; Credit_AmountCaption_Control360Lbl)
                {
                }
                column(Debit_AmountCaption_Control362; Debit_AmountCaption_Control362Lbl)
                {
                }
                column(greTGLEntry__Global_Dimension_2_Code__Control376Caption; CaptionClassTranslate('1,1,2'))
                {
                }
                column(greTGLEntry__Global_Dimension_1_Code__Control377Caption; CaptionClassTranslate('1,1,1'))
                {
                }
                column(G_L_AccountCaption_Control366; G_L_AccountCaption_Control366Lbl)
                {
                }
                column(CurrReport_PAGENO_Control368Caption; CurrReport_PAGENO_Control368CaptionLbl)
                {
                }
                column("Úƒetn__doklad__Control370Caption"; "Purch. Cr. Memo Hdr.".FieldCaption("No."))
                {
                }
                column("Úƒetn__doklad__Control1100170017Caption"; "Purch. Cr. Memo Hdr.".FieldCaption("No."))
                {
                }
                column(ContinuedCaption_Control1100170026; ContinuedCaption_Control1100170026Lbl)
                {
                }
                column(ContinuedCaption_Control383; ContinuedCaption_Control383Lbl)
                {
                }
                column(Date_Caption_Control385; Date_Caption_Control385Lbl)
                {
                }
                column(Date_Caption_Control387; Date_Caption_Control387Lbl)
                {
                }
                column(Date_Caption_Control392; Date_Caption_Control392Lbl)
                {
                }
                column(Date_Caption_Control397; Date_Caption_Control397Lbl)
                {
                }
                column(EmptyStringCaption_Control398; FactualCorrectnessVerifiedByLbl)
                {
                }
                column(EmptyStringCaption_Control399; PostedByLbl)
                {
                }
                column(EmptyStringCaption_Control400; ApprovedByLbl)
                {
                }
                column(EmptyStringCaption_Control401; FormalCorrectnessVerifiedByLbl)
                {
                }
                column(Integer4_Number; Number)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then
                        TempGLEntry.FindSet
                    else
                        TempGLEntry.Next;

                    GLAcc.Get(TempGLEntry."G/L Account No.");
                    if Suma then
                        NameDescText := GLAcc.Name
                    else
                        NameDescText := TempGLEntry.Description;
                end;

                trigger OnPreDataItem()
                begin
                    TempGLEntry.Reset;
                    SetRange(Number, 1, TempGLEntry.Count);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if NewPage then
                    CurrReport.PageNo(1);
                TempGLEntry.DeleteAll;

                FCYRate := 0;
                if ("Currency Code" <> '') and ("Currency Factor" <> 0) then
                    FCYRate := 1 / "Currency Factor";
            end;

            trigger OnPreDataItem()
            begin
                if not "Purch. Cr. Memo Hdr.".HasFilter then
                    CurrReport.Break;
            end;
        }
        dataitem(GeneralDoc; "G/L Entry")
        {
            DataItemTableView = SORTING("Document No.", "Posting Date");
            RequestFilterFields = "Document No.", "Posting Date";
            RequestFilterHeading = 'General Document';
            column(greCompanyInfo_Name_Control14; CompanyInfo.Name)
            {
            }
            column("Úƒetn__doklad__Control22"; "Document No.")
            {
            }
            column(Credit_AmountCaption_Control13; Credit_AmountCaption_Control13Lbl)
            {
            }
            column(Debit_AmountCaption_Control15; Debit_AmountCaption_Control15Lbl)
            {
            }
            column(greTGLEntry__Global_Dimension_2_Code__Control104Caption; CaptionClassTranslate('1,1,2'))
            {
            }
            column(General_Document_Caption; General_Document_CaptionLbl)
            {
            }
            column(greTGLEntry__Global_Dimension_1_Code__Control107Caption; CaptionClassTranslate('1,1,1'))
            {
            }
            column(EmptyStringCaption_Control19; DescriptionLbl)
            {
            }
            column(G_L_Account_NameCaption_Control21; G_L_Account_NameCaption_Control21Lbl)
            {
            }
            column("Úƒetn__doklad__Control22Caption"; FieldCaption("Document No."))
            {
            }
            column(G_L_AccountCaption_Control28; G_L_AccountCaption_Control28Lbl)
            {
            }
            column(GeneralDoc_Entry_No_; "Entry No.")
            {
            }
            dataitem(GLEntry5; "G/L Entry")
            {
                DataItemLink = "Document No." = FIELD("Document No.");
                DataItemTableView = SORTING("Document No.", "Posting Date");

                trigger OnAfterGetRecord()
                begin
                    if UserSetup."User ID" <> "User ID" then
                        if not UserSetup.Get("User ID") then
                            UserSetup.Init;

                    BufferGLEntry(GLEntry5);
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Entry No.", 1, LastGLEntry);
                end;
            }
            dataitem(Integer5; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                column(CurrReport_PAGENO_Control142; CurrReport.PageNo)
                {
                }
                column("Úƒetn__doklad__Control144"; GeneralDoc."Document No.")
                {
                }
                column("Úƒetn__doklad__Control1100170022"; GeneralDoc."Document No.")
                {
                }
                column(greTGLEntry__Credit_Amount__Control98; TempGLEntry."Credit Amount")
                {
                }
                column(greTGLEntry__Debit_Amount__Control99; TempGLEntry."Debit Amount")
                {
                }
                column(greTGLEntry__Global_Dimension_2_Code__Control104; TempGLEntry."Global Dimension 2 Code")
                {
                }
                column(greTGLEntry__Global_Dimension_1_Code__Control107; TempGLEntry."Global Dimension 1 Code")
                {
                }
                column(greTGLEntry_Description; TempGLEntry.Description)
                {
                }
                column(NameDescText5; NameDescText)
                {
                }
                column(greTGLEntry__G_L_Account_No___Control127; TempGLEntry."G/L Account No.")
                {
                }
                column(greTGLEntry__Posting_Date_; Format(TempGLEntry."Posting Date"))
                {
                }
                column(greUserSetup__User_Name__Control55; UserSetup."User Name")
                {
                }
                column(CurrReport_PAGENO_Control142Caption; CurrReport_PAGENO_Control142CaptionLbl)
                {
                }
                column("Úƒetn__doklad__Control144Caption"; GeneralDoc.FieldCaption("Document No."))
                {
                }
                column("Úƒetn__doklad__Control1100170022Caption"; GeneralDoc.FieldCaption("Document No."))
                {
                }
                column(ContinuedCaption_Control1100170027; ContinuedCaption_Control1100170027Lbl)
                {
                }
                column(ContinuedCaption_Control61; ContinuedCaption_Control61Lbl)
                {
                }
                column(Date_Caption_Control44; Date_Caption_Control44Lbl)
                {
                }
                column(Date_Caption_Control45; Date_Caption_Control45Lbl)
                {
                }
                column(EmptyStringCaption_Control48; PostedByLbl)
                {
                }
                column(EmptyStringCaption_Control49; ApprovedByLbl)
                {
                }
                column(EmptyStringCaption_Control51; FormalCorrectnessVerifiedByLbl)
                {
                }
                column(Date_Caption_Control53; Date_Caption_Control53Lbl)
                {
                }
                column(EmptyStringCaption_Control57; FactualCorrectnessVerifiedByLbl)
                {
                }
                column(Date_Caption_Control59; Date_Caption_Control59Lbl)
                {
                }
                column(Integer5_Number; Number)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then
                        TempGLEntry.FindSet
                    else
                        TempGLEntry.Next;

                    GLAcc.Get(TempGLEntry."G/L Account No.");
                    if Suma then
                        NameDescText := GLAcc.Name
                    else
                        NameDescText := TempGLEntry.Description;
                end;

                trigger OnPreDataItem()
                begin
                    TempGLEntry.Reset;
                    SetRange(Number, 1, TempGLEntry.Count);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if LastDocNo <> "Document No." then begin
                    LastDocNo := "Document No.";
                    TempGLEntry.DeleteAll;
                    if NewPage then
                        CurrReport.PageNo(1);
                end else
                    CurrReport.Skip;
            end;

            trigger OnPreDataItem()
            begin
                if not HasFilter then
                    CurrReport.Break;
                if NewPage then
                    CurrReport.PageNo(1);
                LastDocNo := '';
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
                    field(Suma; Suma)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Group same G/L accounts';
                        ToolTip = 'Specifies if the same G/L accounts have to be group.';
                    }
                    field(NewPage; NewPage)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document on new page';
                        ToolTip = 'Specifies if the each document has to be printed on new page.';
                        Visible = false;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            NewPage := true;
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        Suma := true;
    end;

    trigger OnPreReport()
    begin
        CompanyInfo.Get;

        GLEntry.Reset;
        if GLEntry.FindLast then
            LastGLEntry := GLEntry."Entry No.";

        LastDataItem := GetLastDataItem;
        SalesInvHdrExists := not "Sales Invoice Header".IsEmpty and "Sales Invoice Header".HasFilter;
        SalesCrMemoHdrExists := not "Sales Cr.Memo Header".IsEmpty and "Sales Cr.Memo Header".HasFilter;
        PurchInvHdrExists := not "Purch. Inv. Header".IsEmpty and "Purch. Inv. Header".HasFilter;
        PurchCrMemoHdrExists := not "Purch. Cr. Memo Hdr.".IsEmpty and "Purch. Cr. Memo Hdr.".HasFilter;
        GeneralDocExists := not GeneralDoc.IsEmpty and GeneralDoc.HasFilter;
    end;

    var
        CompanyInfo: Record "Company Information";
        GLAcc: Record "G/L Account";
        UserSetup: Record "User Setup";
        TempGLEntry: Record "G/L Entry" temporary;
        GLEntry: Record "G/L Entry";
        LastDocNo: Code[20];
        FCYRate: Decimal;
        LastGLEntry: Integer;
        LastDataItem: Integer;
        Suma: Boolean;
        NewPage: Boolean;
        SalesInvHdrExists: Boolean;
        SalesCrMemoHdrExists: Boolean;
        PurchInvHdrExists: Boolean;
        PurchCrMemoHdrExists: Boolean;
        GeneralDocExists: Boolean;
        NameDescCaption: Text;
        NameDescText: Text;
        Sales_Invoice_CaptionLbl: Label '(Sales Invoice)';
        Sales_Invoice_Header__Sell_to_Customer_Name_CaptionLbl: Label 'Customer';
        Sales_Invoice_Header__Due_Date_CaptionLbl: Label 'Due Date';
        Amount_Including_VAT__AmountCaptionLbl: Label 'VAT Amount';
        FCYRateCaptionLbl: Label 'Rate';
        Credit_AmountCaptionLbl: Label 'Credit Amount';
        Debit_AmountCaptionLbl: Label 'Debit Amount';
        G_L_Account_NameCaptionLbl: Label 'G/L Account Name';
        G_L_AccountCaptionLbl: Label 'G/L Account';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        ContinuedCaptionLbl: Label 'Continued';
        ContinuedCaption_Control288Lbl: Label 'Continued';
        Date_CaptionLbl: Label 'Date:';
        Date_Caption_Control292Lbl: Label 'Date:';
        Date_Caption_Control297Lbl: Label 'Date:';
        Date_Caption_Control302Lbl: Label 'Date:';
        FactualCorrectnessVerifiedByLbl: Label 'Factual Correctness Verified by :';
        PostedByLbl: Label 'Posted by :';
        ApprovedByLbl: Label 'Approved by :';
        FormalCorrectnessVerifiedByLbl: Label 'Formal Correctness Verified by:';
        Sales_Credit_Memo_CaptionLbl: Label '(Sales Credit Memo)';
        Sales_Cr_Memo_Header__Due_Date_CaptionLbl: Label 'Due Date';
        Sales_Cr_Memo_Header__Sell_to_Customer_Name_CaptionLbl: Label 'Customer';
        Amount_Including_VAT__Amount_Control235CaptionLbl: Label 'VAT Amount';
        FCYRate_Control1100162004CaptionLbl: Label 'Rate';
        Credit_AmountCaption_Control20Lbl: Label 'Credit Amount';
        Debit_AmountCaption_Control24Lbl: Label 'Debit Amount';
        G_L_AccountCaption_Control29Lbl: Label 'G/L Account';
        CurrReport_PAGENO_Control41CaptionLbl: Label 'Page';
        ContinuedCaption_Control1100170024Lbl: Label 'Continued';
        ContinuedCaption_Control118Lbl: Label 'Continued';
        Date_Caption_Control121Lbl: Label 'Date:';
        Date_Caption_Control122Lbl: Label 'Date:';
        Date_Caption_Control247Lbl: Label 'Date:';
        Date_Caption_Control313Lbl: Label 'Date:';
        Purchase_Invoice_CaptionLbl: Label '(Purchase Invoice)';
        Purch__Inv__Header__Due_Date_CaptionLbl: Label 'Due Date';
        Purch__Inv__Header__Buy_from_Vendor_Name_CaptionLbl: Label 'Vendor';
        Purch__Inv__Header__Vendor_Invoice_No__CaptionLbl: Label 'External No.';
        Amount_Including_VAT__Amount_Control241CaptionLbl: Label 'VAT Amount';
        FCYRate_Control1100162009CaptionLbl: Label 'Rate';
        Credit_AmountCaption_Control319Lbl: Label 'Credit Amount';
        Debit_AmountCaption_Control320Lbl: Label 'Debit Amount';
        G_L_AccountCaption_Control324Lbl: Label 'G/L Account';
        CurrReport_PAGENO_Control326CaptionLbl: Label 'Page';
        ContinuedCaption_Control1100170025Lbl: Label 'Continued';
        ContinuedCaption_Control341Lbl: Label 'Continued';
        Date_Caption_Control343Lbl: Label 'Date:';
        Date_Caption_Control347Lbl: Label 'Date:';
        Date_Caption_Control350Lbl: Label 'Date:';
        Date_Caption_Control359Lbl: Label 'Date:';
        Purchase_Credit_Memo_CaptionLbl: Label '(Purchase Credit Memo)';
        Purch__Cr__Memo_Hdr___Due_Date_CaptionLbl: Label 'Due Date';
        Purch__Cr__Memo_Hdr___Buy_from_Vendor_Name_CaptionLbl: Label 'Vendor';
        Purch__Cr__Memo_Hdr___Vendor_Cr__Memo_No__CaptionLbl: Label 'External No.';
        Amount_Including_VAT__Amount_Control245CaptionLbl: Label 'VAT Amount';
        FCYRate_Control1100162011CaptionLbl: Label 'Rate';
        Credit_AmountCaption_Control360Lbl: Label 'Credit Amount';
        Debit_AmountCaption_Control362Lbl: Label 'Debit Amount';
        G_L_AccountCaption_Control366Lbl: Label 'G/L Account';
        CurrReport_PAGENO_Control368CaptionLbl: Label 'Page';
        ContinuedCaption_Control1100170026Lbl: Label 'Continued';
        ContinuedCaption_Control383Lbl: Label 'Continued';
        Date_Caption_Control385Lbl: Label 'Date:';
        Date_Caption_Control387Lbl: Label 'Date:';
        Date_Caption_Control392Lbl: Label 'Date:';
        Date_Caption_Control397Lbl: Label 'Date:';
        Credit_AmountCaption_Control13Lbl: Label 'Credit Amount';
        Debit_AmountCaption_Control15Lbl: Label 'Debit Amount';
        General_Document_CaptionLbl: Label '(General Document)';
        DescriptionLbl: Label 'Description';
        G_L_Account_NameCaption_Control21Lbl: Label 'G/L Account Name';
        G_L_AccountCaption_Control28Lbl: Label 'G/L Account';
        CurrReport_PAGENO_Control142CaptionLbl: Label 'Page';
        ContinuedCaption_Control1100170027Lbl: Label 'Continued';
        ContinuedCaption_Control61Lbl: Label 'Continued';
        Date_Caption_Control44Lbl: Label 'Date:';
        Date_Caption_Control45Lbl: Label 'Date:';
        Date_Caption_Control53Lbl: Label 'Date:';
        Date_Caption_Control59Lbl: Label 'Date:';

    [Scope('OnPrem')]
    procedure GetLastDataItem(): Integer
    begin
        case true of
            not GeneralDoc.IsEmpty and GeneralDoc.HasFilter:
                exit(5);
            not "Purch. Cr. Memo Hdr.".IsEmpty and "Purch. Cr. Memo Hdr.".HasFilter:
                exit(4);
            not "Purch. Inv. Header".IsEmpty and "Purch. Inv. Header".HasFilter:
                exit(3);
            not "Sales Cr.Memo Header".IsEmpty and "Sales Cr.Memo Header".HasFilter:
                exit(2);
            not "Sales Invoice Header".IsEmpty and "Sales Invoice Header".HasFilter:
                exit(1);
        end;
    end;

    local procedure BufferGLEntry(GLEntry: Record "G/L Entry")
    begin
        with GLEntry do begin
            if Amount = 0 then
                exit;
            TempGLEntry.SetRange("G/L Account No.", "G/L Account No.");
            TempGLEntry.SetRange("Global Dimension 1 Code", "Global Dimension 1 Code");
            TempGLEntry.SetRange("Global Dimension 2 Code", "Global Dimension 2 Code");
            TempGLEntry.SetRange("Job No.", "Job No.");
            if TempGLEntry.FindFirst and Suma then begin
                TempGLEntry."Debit Amount" += "Debit Amount";
                TempGLEntry."Credit Amount" += "Credit Amount";
                TempGLEntry.Modify;
            end else begin
                TempGLEntry.Init;
                TempGLEntry.TransferFields(GLEntry);
                TempGLEntry.Insert;
            end;
        end;
    end;
}

