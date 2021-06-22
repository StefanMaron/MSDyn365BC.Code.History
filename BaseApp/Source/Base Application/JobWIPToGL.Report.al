report 1010 "Job WIP To G/L"
{
    DefaultLayout = RDLC;
    RDLCLayout = './JobWIPToGL.rdlc';
    AdditionalSearchTerms = 'work in process to general ledger,work in progress to general ledger';
    ApplicationArea = Jobs;
    Caption = 'Job WIP To G/L';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Job; Job)
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.", "Posting Date Filter";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName)
            {
            }
            column(Job_TABLECAPTION__________JobFilter; TableCaption + ': ' + JobFilter)
            {
            }
            column(JobFilter; JobFilter)
            {
            }
            column(Job_WIP_To_G_LCaption; Job_WIP_To_G_LCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(G_L_Acc__No_Caption; G_L_Acc__No_CaptionLbl)
            {
            }
            column(DescriptionCaption; DescriptionCaptionLbl)
            {
            }
            column(Job_Posting_GroupCaption; Job_Posting_GroupCaptionLbl)
            {
            }
            column(AccountCaption; AccountCaptionLbl)
            {
            }
            column(WIP_AmountCaption; WIP_AmountCaptionLbl)
            {
            }
            column(G_L_BalanceCaption; G_L_BalanceCaptionLbl)
            {
            }
            column(DifferenceCaption; DifferenceCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                JobBuffer2.InsertWorkInProgress(Job);
            end;
        }
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
            column(GLAcc__No__; GLAcc."No.")
            {
            }
            column(JobBuffer__Amount_1_; JobBuffer."Amount 1")
            {
            }
            column(JobBuffer__Account_No__2_; JobBuffer."Account No. 2")
            {
            }
            column(GLAcc_Name; GLAcc.Name)
            {
            }
            column(WIPText; WIPText)
            {
            }
            column(WIPText1; WIPText1)
            {
            }
            column(JobBuffer__Amount_2_; JobBuffer."Amount 2")
            {
            }
            column(WIPText2; WIPText2)
            {
            }
            column(JobBuffer__Amount_4_; JobBuffer."Amount 4")
            {
            }
            column(WIPText3; WIPText3)
            {
            }
            column(JobBuffer__Amount_5_; JobBuffer."Amount 5")
            {
            }
            column(WIPText4; WIPText4)
            {
            }
            column(GLAccJobTotal; GLAccJobTotal)
            {
            }
            column(JobBuffer__Amount_3_; JobBuffer."Amount 3")
            {
            }
            column(GLAccJobTotal___JobBuffer__Amount_3_; GLAccJobTotal - JobBuffer."Amount 3")
            {
            }
            column(NewTotal; JobBuffer."New Total")
            {
            }
            column(GLJobTotal; GLJobTotal)
            {
            }
            column(GLTotal; GLTotal)
            {
            }
            column(GLJobTotal___GLTotal; GLJobTotal - GLTotal)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then begin
                    if not JobBuffer.Find('-') then
                        CurrReport.Break();
                end else
                    if JobBuffer.Next = 0 then
                        CurrReport.Break();
                GLAcc.Name := '';
                GLAcc."No." := '';

                if OldAccNo <> JobBuffer."Account No. 1" then begin
                    if GLAcc.Get(JobBuffer."Account No. 1") then;
                    GLAccJobTotal := 0;
                end;
                OldAccNo := JobBuffer."Account No. 1";
                GLAccJobTotal := GLAccJobTotal + JobBuffer."Amount 1" + JobBuffer."Amount 2" + JobBuffer."Amount 4" + JobBuffer."Amount 5";
                GLJobTotal := GLJobTotal + JobBuffer."Amount 1" + JobBuffer."Amount 2" + JobBuffer."Amount 4" + JobBuffer."Amount 5";
                if JobBuffer."New Total" then
                    GLTotal := GLTotal + JobBuffer."Amount 3";

                if JobBuffer."Amount 1" <> 0 then
                    WIPText1 := SelectStr(1, TEXT000);
                if JobBuffer."Amount 2" <> 0 then
                    WIPText2 := SelectStr(2, TEXT000);
                if JobBuffer."Amount 4" <> 0 then
                    WIPText3 := SelectStr(4, TEXT000);
                if JobBuffer."Amount 5" <> 0 then
                    WIPText4 := SelectStr(3, TEXT000);
            end;

            trigger OnPreDataItem()
            begin
                JobBuffer2.GetJobBuffer(Job, JobBuffer);
                OldAccNo := '';
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
    }

    trigger OnPreReport()
    begin
        JobBuffer2.InitJobBuffer;
        JobFilter := Job.GetFilters;
    end;

    var
        JobBuffer: Record "Job Buffer" temporary;
        JobBuffer2: Record "Job Buffer" temporary;
        GLAcc: Record "G/L Account";
        JobFilter: Text;
        WIPText: Text[50];
        TEXT000: Label 'WIP Cost Amount,WIP Accrued Costs Amount,WIP Accrued Sales Amount,WIP Invoiced Sales Amount';
        WIPText1: Text[50];
        WIPText2: Text[50];
        WIPText3: Text[50];
        WIPText4: Text[50];
        OldAccNo: Code[20];
        GLAccJobTotal: Decimal;
        GLJobTotal: Decimal;
        GLTotal: Decimal;
        Job_WIP_To_G_LCaptionLbl: Label 'Job WIP To G/L';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        G_L_Acc__No_CaptionLbl: Label 'G/L Acc. No.';
        DescriptionCaptionLbl: Label 'Description';
        Job_Posting_GroupCaptionLbl: Label 'Job Posting Group';
        AccountCaptionLbl: Label 'Account';
        WIP_AmountCaptionLbl: Label 'WIP Amount';
        G_L_BalanceCaptionLbl: Label 'G/L Balance';
        DifferenceCaptionLbl: Label 'Difference';
        TotalCaptionLbl: Label 'Total';
}

