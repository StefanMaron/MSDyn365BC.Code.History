report 11774 "Joining G/L Account Adjustment"
{
    DefaultLayout = RDLC;
    RDLCLayout = './JoiningGLAccountAdjustment.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Joining G/L Account Adjustment';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("G/L Entry"; "G/L Entry")
        {
            DataItemTableView = SORTING("G/L Account No.", "Posting Date");
            RequestFilterFields = "G/L Account No.", "Document No.", "External Document No.";

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
                    TBuffer.Amount := TBuffer.Amount + "G/L Entry".Amount;
                    TBuffer."Debit Amount" := TBuffer."Debit Amount" + "Debit Amount";
                    TBuffer."Credit Amount" := TBuffer."Credit Amount" + "Credit Amount";
                    if Date and (TBuffer."Posting Date" = 0D) and ("Posting Date" <> 0D) then
                        TBuffer."Posting Date" := "Posting Date";
                    if Descr and (TBuffer.Description = '') and (Description <> '') then
                        TBuffer.Description := Description;
                    TBuffer.Modify;
                end else begin
                    TBuffer.Init;
                    TBuffer."Document No." := lcoDocNo;
                    TBuffer.Amount := "G/L Entry".Amount;
                    TBuffer."Debit Amount" := "Debit Amount";
                    TBuffer."Credit Amount" := "Credit Amount";
                    if Date then
                        TBuffer."Posting Date" := "Posting Date";
                    if Descr then
                        TBuffer.Description := Description;
                    TBuffer.Insert;
                end;
            end;

            trigger OnPreDataItem()
            begin
                if GetFilter("G/L Account No.") = '' then
                    Error(EmptyAccountNoFilterErr);

                Filter := CopyStr("G/L Entry".GetFilters, 1, MaxStrLen(Filter));
                i := Count;
                j := 0;
                Window.Open(ProcessingEntriesMsg);
            end;
        }
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
            column(USERID; UserId)
            {
            }
            column(CurrReport_PAGENO; CurrReport.PageNo)
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName)
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
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Joining_G_L_Account_AdjustmentCaption; Joining_G_L_Account_AdjustmentCaptionLbl)
            {
            }
            column(greTBuffer__Document_No__Caption; TBuffer__Document_No__CaptionLbl)
            {
            }
            column(G_L_Entry2_AmountCaption; "G/L Entry2".FieldCaption(Amount))
            {
            }
            column(G_L_Entry2__Debit_Amount_Caption; "G/L Entry2".FieldCaption("Debit Amount"))
            {
            }
            column(G_L_Entry2__Credit_Amount_Caption; "G/L Entry2".FieldCaption("Credit Amount"))
            {
            }
            column(G_L_Entry2_DescriptionCaption; "G/L Entry2".FieldCaption(Description))
            {
            }
            column(G_L_Entry2__Posting_Date_Caption; "G/L Entry2".FieldCaption("Posting Date"))
            {
            }
            column(G_L_Entry2__Entry_No__Caption; "G/L Entry2".FieldCaption("Entry No."))
            {
            }
            column(G_L_Entry2_DescriptionCaption_Control34; "G/L Entry2".FieldCaption(Description))
            {
            }
            column(G_L_Entry2__Credit_Amount_Caption_Control35; "G/L Entry2".FieldCaption("Credit Amount"))
            {
            }
            column(G_L_Entry2__Debit_Amount_Caption_Control36; "G/L Entry2".FieldCaption("Debit Amount"))
            {
            }
            column(G_L_Entry2_AmountCaption_Control37; "G/L Entry2".FieldCaption(Amount))
            {
            }
            column(greTBuffer__Document_No__Caption_Control38; TBuffer__Document_No__Caption_Control38Lbl)
            {
            }
            column(G_L_Entry2__Posting_Date_Caption_Control40; "G/L Entry2".FieldCaption("Posting Date"))
            {
            }
            column(G_L_Entry2__Entry_No__Caption_Control1100162001; "G/L Entry2".FieldCaption("Entry No."))
            {
            }
            column(gdeTotalCaption; TotalCaptionLbl)
            {
            }
            column(Integer_Number; Number)
            {
            }
            dataitem("G/L Entry2"; "G/L Entry")
            {
                DataItemTableView = SORTING("Entry No.");
                column(G_L_Entry2_Amount; Amount)
                {
                }
                column(G_L_Entry2__Debit_Amount_; "Debit Amount")
                {
                }
                column(G_L_Entry2__Credit_Amount_; "Credit Amount")
                {
                }
                column(G_L_Entry2_Description; Description)
                {
                }
                column(G_L_Entry2__Posting_Date_; "Posting Date")
                {
                }
                column(G_L_Entry2__Entry_No__; "Entry No.")
                {
                }
                column(gboDetail; Detail)
                {
                }

                trigger OnPreDataItem()
                begin
                    if not Detail then
                        CurrReport.Break;

                    CopyFilters("G/L Entry");
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

                if TBuffer.Amount = 0 then
                    CurrReport.Skip;
            end;

            trigger OnPreDataItem()
            begin
                if not TBuffer.Find('-') then
                    CurrReport.Quit;
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
        TBuffer: Record "G/L Account Adjustment Buffer" temporary;
        Window: Dialog;
        "Filter": Text[250];
        DocumentType: Option DocumentNo,ExternalDocumentNo,Combination;
        i: Integer;
        j: Integer;
        Detail: Boolean;
        Descr: Boolean;
        Date: Boolean;
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Joining_G_L_Account_AdjustmentCaptionLbl: Label 'Joining G/L Account Adjustment';
        TBuffer__Document_No__CaptionLbl: Label 'Document No.';
        TBuffer__Document_No__Caption_Control38Lbl: Label 'Document No.';
        TotalCaptionLbl: Label 'Total';
        EmptyAccountNoFilterErr: Label 'Please enter a Filter to Account No..';
        ProcessingEntriesMsg: Label 'Processing Entries @1@@@@@@@@@@@@';
}

