report 11773 "Joining Bank. Acc. Adjustment"
{
    DefaultLayout = RDLC;
    RDLCLayout = './JoiningBankAccAdjustment.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Joining Bank. Acc. Adjustment';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Bank Account Ledger Entry"; "Bank Account Ledger Entry")
        {
            DataItemTableView = SORTING("Bank Account No.", "Posting Date");
            RequestFilterFields = "Bank Account No.", "Document No.", "External Document No.";

            trigger OnAfterGetRecord()
            var
                lcoDocNo: Code[20];
            begin
                j := j + 1;
                Window.Update(1, Round((9999 / i) * j, 1));
                case DocumentType of
                    0:
                        lcoDocNo := "Document No.";
                    1:
                        lcoDocNo := "External Document No.";
                    2:
                        begin
                            if "External Document No." <> '' then
                                lcoDocNo := "External Document No."
                            else
                                lcoDocNo := "Document No.";
                        end;
                end;
                if TBuffer.Get(lcoDocNo) then begin
                    if TBuffer.Valid and (TBuffer."Currency Code" = "Currency Code") then begin
                        TBuffer.Amount := TBuffer.Amount + "Bank Account Ledger Entry".Amount;
                        TBuffer."Debit Amount" := TBuffer."Debit Amount" + "Debit Amount";
                        TBuffer."Credit Amount" := TBuffer."Credit Amount" + "Credit Amount";
                    end
                    else begin
                        TBuffer.Amount := 0;
                        TBuffer."Debit Amount" := 0;
                        TBuffer."Credit Amount" := 0;
                        TBuffer.Valid := false;
                    end;
                    TBuffer."Amount (LCY)" := TBuffer."Amount (LCY)" + "Amount (LCY)";
                    if Date and (TBuffer."Posting Date" = 0D) and ("Posting Date" <> 0D) then
                        TBuffer."Posting Date" := "Posting Date";
                    if Descr and (TBuffer.Description = '') and (Description <> '') then
                        TBuffer.Description := Description;
                    TBuffer.Modify;
                end else begin
                    TBuffer.Init;
                    TBuffer."Document No." := lcoDocNo;
                    TBuffer.Amount := "Bank Account Ledger Entry".Amount;
                    TBuffer."Debit Amount" := "Debit Amount";
                    TBuffer."Credit Amount" := "Credit Amount";
                    TBuffer."Amount (LCY)" := "Amount (LCY)";
                    TBuffer."Currency Code" := "Currency Code";
                    if Date then
                        TBuffer."Posting Date" := "Posting Date";
                    if Descr then
                        TBuffer.Description := Description;
                    TBuffer.Valid := true;
                    TBuffer.Insert;
                end;

                if TCurrBuffer.Get("Currency Code") then begin
                    TCurrBuffer."Total Amount" += Amount;
                    TCurrBuffer."Total Amount (LCY)" += "Amount (LCY)";
                    TCurrBuffer."Total Credit Amount" += "Credit Amount";
                    TCurrBuffer."Total Debit Amount" += "Debit Amount";
                    TCurrBuffer.Counter += 1;
                    TCurrBuffer.Modify;
                end else begin
                    TCurrBuffer."Currency Code" := "Currency Code";
                    TCurrBuffer."Total Amount" := Amount;
                    TCurrBuffer."Total Amount (LCY)" := "Amount (LCY)";
                    TCurrBuffer."Total Credit Amount" := "Credit Amount";
                    TCurrBuffer."Total Debit Amount" := "Debit Amount";
                    TCurrBuffer.Counter := 1;
                    TCurrBuffer.Insert;
                end;
            end;

            trigger OnPreDataItem()
            begin
                Filter := CopyStr("Bank Account Ledger Entry".GetFilters, 1, MaxStrLen(Filter));

                if GetFilter("Bank Account No.") = '' then
                    Error(Text002);

                i := Count;
                j := 0;
                Window.Open(Text001);
            end;
        }
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName)
            {
            }
            column(Joining_Bank_Account_AdjustmentCaption; Joining_Bank_Account_AdjustmentCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(gteFilter; Filter)
            {
            }
            column(greTBuffer__Document_No__; TBuffer."Document No.")
            {
            }
            column(greTBuffer_Amount; TBuffer.Amount)
            {
            }
            column(greTBuffer__Debit_Amount_; TBuffer."Debit Amount")
            {
            }
            column(greTBuffer__Credit_Amount_; TBuffer."Credit Amount")
            {
            }
            column(greTBuffer_Description; TBuffer.Description)
            {
            }
            column(greTBuffer__Posting_Date_; TBuffer."Posting Date")
            {
            }
            column(greTBuffer__Currency_Code_; TBuffer."Currency Code")
            {
            }
            column(greTBuffer__Amount__LCY__; TBuffer."Amount (LCY)")
            {
            }
            column(greTBuffer__Document_No__Caption; TBuffer__Document_No__CaptionLbl)
            {
            }
            column(Bank_Account_Ledger_Entry_2_AmountCaption; "Bank Account Ledger Entry 2".FieldCaption(Amount))
            {
            }
            column(Bank_Account_Ledger_Entry_2__Debit_Amount_Caption; "Bank Account Ledger Entry 2".FieldCaption("Debit Amount"))
            {
            }
            column(Bank_Account_Ledger_Entry_2__Credit_Amount_Caption; "Bank Account Ledger Entry 2".FieldCaption("Credit Amount"))
            {
            }
            column(Bank_Account_Ledger_Entry_2_DescriptionCaption; "Bank Account Ledger Entry 2".FieldCaption(Description))
            {
            }
            column(Bank_Account_Ledger_Entry_2__Posting_Date_Caption; "Bank Account Ledger Entry 2".FieldCaption("Posting Date"))
            {
            }
            column(Bank_Account_Ledger_Entry_2__Entry_No__Caption; "Bank Account Ledger Entry 2".FieldCaption("Entry No."))
            {
            }
            column(Bank_Account_Ledger_Entry_2__Amount__LCY__Caption; "Bank Account Ledger Entry 2".FieldCaption("Amount (LCY)"))
            {
            }
            column(Bank_Account_Ledger_Entry_2__Currency_Code_Caption; "Bank Account Ledger Entry 2".FieldCaption("Currency Code"))
            {
            }
            column(CurrReport_PAGENO_Control25Caption; CurrReport_PAGENO_Control25CaptionLbl)
            {
            }
            column(Joining_Bank_Account_AdjustmentCaption_Control33; Joining_Bank_Account_AdjustmentCaption_Control33Lbl)
            {
            }
            column(Bank_Account_Ledger_Entry_2_DescriptionCaption_Control34; "Bank Account Ledger Entry 2".FieldCaption(Description))
            {
            }
            column(Bank_Account_Ledger_Entry_2__Credit_Amount_Caption_Control35; "Bank Account Ledger Entry 2".FieldCaption("Credit Amount"))
            {
            }
            column(Bank_Account_Ledger_Entry_2__Debit_Amount_Caption_Control36; "Bank Account Ledger Entry 2".FieldCaption("Debit Amount"))
            {
            }
            column(Bank_Account_Ledger_Entry_2_AmountCaption_Control37; "Bank Account Ledger Entry 2".FieldCaption(Amount))
            {
            }
            column(greTBuffer__Document_No__Caption_Control38; TBuffer__Document_No__Caption_Control38Lbl)
            {
            }
            column(Bank_Account_Ledger_Entry_2__Posting_Date_Caption_Control40; "Bank Account Ledger Entry 2".FieldCaption("Posting Date"))
            {
            }
            column(Bank_Account_Ledger_Entry_2__Currency_Code_Caption_Control1100162003; "Bank Account Ledger Entry 2".FieldCaption("Currency Code"))
            {
            }
            column(Bank_Account_Ledger_Entry_2__Amount__LCY__Caption_Control1100162004; "Bank Account Ledger Entry 2".FieldCaption("Amount (LCY)"))
            {
            }
            column(Bank_Account_Ledger_Entry_2__Entry_No__Caption_Control1100162005; "Bank Account Ledger Entry 2".FieldCaption("Entry No."))
            {
            }
            column(Integer_Number; Number)
            {
            }
            dataitem("Bank Account Ledger Entry 2"; "Bank Account Ledger Entry")
            {
                DataItemTableView = SORTING("Entry No.");
                column(Bank_Account_Ledger_Entry_2_Amount; Amount)
                {
                }
                column(Bank_Account_Ledger_Entry_2__Debit_Amount_; "Debit Amount")
                {
                }
                column(Bank_Account_Ledger_Entry_2__Credit_Amount_; "Credit Amount")
                {
                }
                column(Bank_Account_Ledger_Entry_2_Description; Description)
                {
                }
                column(Bank_Account_Ledger_Entry_2__Posting_Date_; "Posting Date")
                {
                }
                column(Bank_Account_Ledger_Entry_2__Entry_No__; "Entry No.")
                {
                }
                column(Bank_Account_Ledger_Entry_2__Currency_Code_; "Currency Code")
                {
                }
                column(Bank_Account_Ledger_Entry_2__Amount__LCY__; "Amount (LCY)")
                {
                }

                trigger OnPreDataItem()
                begin
                    if not Detail then
                        CurrReport.Break;

                    CopyFilters("Bank Account Ledger Entry");
                    if DocumentType = 0 then begin
                        SetCurrentKey("Document No.");
                        SetRange("Document No.", TBuffer."Document No.");
                    end else
                        SetRange("External Document No.", TBuffer."Document No.");
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if Number <> 1 then
                    if TBuffer.Next = 0 then
                        CurrReport.Break;

                if TBuffer."Amount (LCY)" = 0 then
                    CurrReport.Skip;
            end;

            trigger OnPreDataItem()
            begin
                if not TBuffer.Find('-') then
                    CurrReport.Quit;
            end;
        }
        dataitem("Currency Summary"; "Integer")
        {
            DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
            column(greTCurrBuffer__Total_Amount__LCY__; TCurrBuffer."Total Amount (LCY)")
            {
            }
            column(greTCurrBuffer__Currency_Code_; TCurrBuffer."Currency Code")
            {
            }
            column(greTCurrBuffer__Total_Credit_Amount_; TCurrBuffer."Total Credit Amount")
            {
            }
            column(greTCurrBuffer__Total_Debit_Amount_; TCurrBuffer."Total Debit Amount")
            {
            }
            column(greTCurrBuffer__Total_Amount_; TCurrBuffer."Total Amount")
            {
            }
            column(greTCurrBuffer__Total_Amount_Caption; TCurrBuffer__Total_Amount_CaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            column(greTCurrBuffer__Currency_Code_Caption; TCurrBuffer__Currency_Code_CaptionLbl)
            {
            }
            column(greTCurrBuffer__Total_Amount__LCY__Caption; TCurrBuffer__Total_Amount__LCY__CaptionLbl)
            {
            }
            column(greTCurrBuffer__Total_Debit_Amount_Caption; TCurrBuffer__Total_Debit_Amount_CaptionLbl)
            {
            }
            column(greTCurrBuffer__Total_Credit_Amount_Caption; TCurrBuffer__Total_Credit_Amount_CaptionLbl)
            {
            }
            column(Currency_Summary_Number; Number)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then
                    TCurrBuffer.FindSet
                else
                    TCurrBuffer.Next;
            end;

            trigger OnPreDataItem()
            begin
                SetRange(Number, 1, TCurrBuffer.Count);
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
                    field(DocumentType; DocumentType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'By';
                        OptionCaption = 'Document No.,External Document No.,Combination';
                        ToolTip = 'Specifies type of sorting';
                    }
                    field(Descr; Descr)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Description';
                        ToolTip = 'Specifies when the currency is to be show';
                    }
                    field(Date; Date)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Posting Date';
                        ToolTip = 'Specifies when the posting date is to be show';
                    }
                    field(Detail; Detail)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Detail';
                        ToolTip = 'Specifies when the detail is to be show';
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
        TBuffer: Record "Bank Acc. Adjustment Buffer" temporary;
        TCurrBuffer: Record "Enhanced Currency Buffer" temporary;
        "Filter": Text[250];
        Window: Dialog;
        i: Integer;
        j: Integer;
        DocumentType: Option "Document No.","External Document No.",Combination;
        Detail: Boolean;
        Descr: Boolean;
        Date: Boolean;
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Joining_Bank_Account_AdjustmentCaptionLbl: Label 'Joining Bank Account Adjustment';
        TBuffer__Document_No__CaptionLbl: Label 'Document No.';
        CurrReport_PAGENO_Control25CaptionLbl: Label 'Page';
        Joining_Bank_Account_AdjustmentCaption_Control33Lbl: Label 'Joining Bank Account Adjustment';
        TBuffer__Document_No__Caption_Control38Lbl: Label 'Document No.';
        TCurrBuffer__Total_Amount_CaptionLbl: Label 'Amount';
        TotalCaptionLbl: Label 'Total';
        TCurrBuffer__Currency_Code_CaptionLbl: Label 'Currency Code';
        TCurrBuffer__Total_Amount__LCY__CaptionLbl: Label 'Amount (LCY)';
        TCurrBuffer__Total_Debit_Amount_CaptionLbl: Label 'Debit Amount';
        TCurrBuffer__Total_Credit_Amount_CaptionLbl: Label 'Credit Amount';
        Text001: Label 'Processing Entries @1@@@@@@@@@@@@';
        Text002: Label 'Please enter a Filter to Bank Account No..';
}

