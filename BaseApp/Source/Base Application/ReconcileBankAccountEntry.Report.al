#if not CLEAN17
report 11711 "Reconcile Bank Account Entry"
{
    DefaultLayout = RDLC;
    RDLCLayout = './ReconcileBankAccountEntry.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Reconcile Bank Account Entry (Obsolete)';
    UsageCategory = ReportsAndAnalysis;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.0';

    dataset
    {
        dataitem("Bank Account"; "Bank Account")
        {
            CalcFields = "Net Change (LCY)";
            RequestFilterFields = "No.", Name, "Date Filter";
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName)
            {
            }
            column(gteFilter; Filter)
            {
            }
            column(Bank_Account__No__; "No.")
            {
            }
            column(Bank_Account_Name; Name)
            {
            }
            column(Bank_Account__Net_Change__LCY__; "Net Change (LCY)")
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Reconcile_Bank_Account_EntryCaption; Reconcile_Bank_Account_EntryCaptionLbl)
            {
            }
            column(Bank_Account_Date_Filter; "Date Filter")
            {
            }
            column(gboShowDetail; ShowDetail)
            {
            }
            dataitem("Bank Account Ledger Entry"; "Bank Account Ledger Entry")
            {
                DataItemLink = "Bank Account No." = FIELD("No."), "Posting Date" = FIELD("Date Filter");
                DataItemTableView = SORTING("Bank Account No.", "Posting Date");
                column(Bank_Account_Ledger_Entry__Posting_Date_; "Posting Date")
                {
                }
                column(Bank_Account_Ledger_Entry__Document_Type_; "Document Type")
                {
                }
                column(Bank_Account_Ledger_Entry__Document_No__; "Document No.")
                {
                }
                column(Bank_Account_Ledger_Entry_Description; Description)
                {
                }
                column(Bank_Account_Ledger_Entry__Amount__LCY__; "Amount (LCY)")
                {
                }
                column(Bank_Account_Ledger_Entry__Posting_Date_Caption; FieldCaption("Posting Date"))
                {
                }
                column(Bank_Account_Ledger_Entry__Document_No__Caption; FieldCaption("Document No."))
                {
                }
                column(Bank_Account_Ledger_Entry__Document_Type_Caption; FieldCaption("Document Type"))
                {
                }
                column(Bank_Account_Ledger_Entry_DescriptionCaption; FieldCaption(Description))
                {
                }
                column(Bank_Account_Ledger_Entry__Amount__LCY__Caption; FieldCaption("Amount (LCY)"))
                {
                }
                column(Bank_Account_Ledger_Entry_Entry_No_; "Entry No.")
                {
                }
                column(Bank_Account_Ledger_Entry_Bank_Account_No_; "Bank Account No.")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    BankAccPost.TestField("G/L Account No.");

                    if TempBuffer.Get(GLAccNo) then begin
                        TempBuffer."Net Change in Jnl." += "Amount (LCY)";
                        TempBuffer.Modify();
                    end else begin
                        TempBuffer.Init();
                        TempBuffer."No." := GLAccNo;
                        TempBuffer."Net Change in Jnl." := "Amount (LCY)";
                        TempBuffer.Insert();
                    end;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if "Bank Acc. Posting Group" <> BankAccPost.Code then
                    if BankAccPost.Get("Bank Acc. Posting Group") then
                        GLAccNo := BankAccPost."G/L Account No."
                    else begin
                        Clear(BankAccPost);
                        Clear(GLAccNo);
                    end;
            end;
        }
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = SORTING(Number);
            column(greGLAcc_FIELDCAPTION__Balance_at_Date__; GLAcc.FieldCaption("Balance at Date"))
            {
            }
            column(greGLAcc_FIELDCAPTION_Name_; GLAcc.FieldCaption(Name))
            {
            }
            column(greGLAcc_FIELDCAPTION__No___; GLAcc.FieldCaption("No."))
            {
            }
            column(greTBuffer__No__; TempBuffer."No.")
            {
            }
            column(greTBuffer__Net_Change_in_Jnl__; TempBuffer."Net Change in Jnl.")
            {
            }
            column(greGLAcc_Name; GLAcc.Name)
            {
            }
            column(greTBuffer__Net_Change_in_Jnl_____greGLAcc__Net_Change_; TempBuffer."Net Change in Jnl." - GLAcc."Net Change")
            {
            }
            column(greGLAcc__Net_Change_; GLAcc."Net Change")
            {
            }
            column(greTBuffer__Net_Change_in_Jnl_____greGLAcc__Net_Change__Control1100170000; TempBuffer."Net Change in Jnl." - GLAcc."Net Change")
            {
            }
            column(greGLAcc__Net_Change__Control1100170001; GLAcc."Net Change")
            {
            }
            column(greTBuffer__Net_Change_in_Jnl___Control1100170002; TempBuffer."Net Change in Jnl.")
            {
            }
            column(General_Ledger_SpecificationCaption; General_Ledger_SpecificationCaptionLbl)
            {
            }
            column(greTBuffer__Net_Change_in_Jnl_____greGLAcc__Net_Change_Caption; TBuffer__Net_Change_in_Jnl_____greGLAcc__Net_Change_CaptionLbl)
            {
            }
            column(greGLAcc__Net_Change_Caption; GLAcc__Net_Change_CaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            column(Integer_Number; Number)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then
                    TempBuffer.FindSet
                else
                    TempBuffer.Next;

                GLAcc.Get(TempBuffer."No.");
                GLAcc.CalcFields("Net Change");
            end;

            trigger OnPreDataItem()
            begin
                TempBuffer.Reset();
                SetRange(Number, 1, TempBuffer.Count);

                GLAcc.SetFilter("Date Filter", "Bank Account".GetFilter("Date Filter"));
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
                    field(ShowDetail; ShowDetail)
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

    trigger OnPreReport()
    begin
        Filter := CopyStr("Bank Account".GetFilters, 1, MaxStrLen(Filter));
    end;

    var
        TempBuffer: Record "G/L Account Net Change" temporary;
        GLAcc: Record "G/L Account";
        "Filter": Text[1024];
        ShowDetail: Boolean;
        BankAccPost: Record "Bank Account Posting Group";
        GLAccNo: Code[20];
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Reconcile_Bank_Account_EntryCaptionLbl: Label 'Reconcile Bank Account Entry';
        General_Ledger_SpecificationCaptionLbl: Label 'General Ledger Specification';
        TBuffer__Net_Change_in_Jnl_____greGLAcc__Net_Change_CaptionLbl: Label 'Difference';
        GLAcc__Net_Change_CaptionLbl: Label 'Balance at Date by GL';
        TotalCaptionLbl: Label 'Total';
}


#endif